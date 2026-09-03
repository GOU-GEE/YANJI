import '../../domain/business_schema.dart';
import '../conflict/multi_value_register.dart';
import '../oplog/operation.dart';

typedef EntityKey = (String type, String id);

final class ResolvedEntity {
  ResolvedEntity(this.key, this.operations);
  final EntityKey key;
  final List<OperationEnvelope> operations;
  String state = 'pending_create';
  final values = <String, Object?>{};
  final clocks = <String, OperationEnvelope>{};
  final textVersions = <OperationEnvelope>[];
  final segments = <ResolvedSegment>[];
  OperationEnvelope? tombstone;
}

final class ResolvedSegment {
  ResolvedSegment(this.id, this.start, this.creator);
  final String id;
  final int start;
  int? end;
  final OperationEnvelope creator;
  OperationEnvelope? closer;
}

final class Resolution {
  final entities = <EntityKey, ResolvedEntity>{};
  final applyStates = <String, String>{};
}

/// Recompute from the current valid set rather than folding a non-transitive
/// causality/LWW comparator in arrival order. No SQL errors are used as control flow.
final class ConflictResolver {
  Resolution resolve(List<OperationEnvelope> history) {
    final result = Resolution();
    for (final e in history) {
      try {
        BusinessSchema.validate(e);
      } on FormatException {
        result.applyStates[e.opId] = 'invalid_domain';
        continue;
      }
      final key = (e.entityType, e.entityId);
      result.entities
          .putIfAbsent(key, () => ResolvedEntity(key, []))
          .operations
          .add(e);
    }
    for (final entity in result.entities.values) {
      if (entity.key.$1 == 'study_session') {
        _session(entity, result);
      } else {
        _scalar(entity);
      }
    }
    // Explicit dependency closure before any SQL materialization, including
    // parent deletion or a revoked create which removes a previously-present FK.
    var changed = true;
    while (changed) {
      changed = false;
      for (final entity in result.entities.values.where(
        (e) => e.state == 'materialized',
      )) {
        bool present(String type, Object? id) =>
            id == null || result.entities[(type, id)]?.state == 'materialized';
        final e = entity.operations.first;
        final ok =
            (entity.key.$1 == 'workspace' ||
                present('workspace', e.workspaceId)) &&
            present('subject', entity.values['subject_id']) &&
            present('task', entity.values['task_id']);
        if (!ok) {
          entity.state = 'pending_dependency';
          changed = true;
        }
      }
    }
    for (final entity in result.entities.values) {
      for (final op in entity.operations) {
        result.applyStates.putIfAbsent(
          op.opId,
          () => switch (entity.state) {
            'materialized' || 'deleted' => 'applied',
            'pending_create' => 'pending_entity_create',
            _ => 'pending_dependency',
          },
        );
        // Even successfully folded timer actions remain pending until their FK
        // dependencies exist. An invalid owner/action stays invalid_domain.
        if (entity.state == 'pending_dependency' &&
            result.applyStates[op.opId] == 'applied') {
          result.applyStates[op.opId] = 'pending_dependency';
        }
      }
    }
    return result;
  }

  static OperationEnvelope winner(List<OperationEnvelope> ops) {
    final active = ops
        .where((a) => !ops.any((b) => a.happensBefore(b)))
        .toList();
    if (active.isEmpty) throw const FormatException('Cyclic causal history');
    return active.reduce((a, b) => a.compareWinner(b) > 0 ? a : b);
  }

  void _scalar(ResolvedEntity entity) {
    final ops = entity.operations;
    final deletes = ops.where((e) => e.action == 'delete').toList();
    if (deletes.isNotEmpty) {
      entity.tombstone = winner(deletes);
      entity.state = 'deleted';
      return;
    }
    final fields = <String>{
      for (final op in ops) ...(op.payload! as Map<String, Object?>).keys,
    };
    for (final field in fields) {
      final versions = MultiValueRegister.versions(ops, field);
      if (versions.isEmpty) continue;
      final selected = MultiValueRegister.winner(versions);
      entity.clocks[field] = selected;
      entity.values[field] = (selected.payload! as Map<String, Object?>)[field];
      if (entity.key.$1 == 'daily_review' && field == 'content') {
        entity.textVersions.addAll(versions);
      }
    }
    for (final d in (BusinessSchema.defaults[entity.key.$1] ?? {}).entries) {
      entity.values.putIfAbsent(d.key, () => d.value);
    }
    if (ops.any((e) => e.action == 'create') &&
        (BusinessSchema.requiredFields[entity.key.$1] ?? []).every(
          (f) => entity.values[f] != null,
        )) {
      entity.state = 'materialized';
    }
  }

  void _session(ResolvedEntity entity, Resolution result) {
    final starts = entity.operations
        .where((e) => e.action == 'session.start')
        .toList();
    if (starts.isEmpty) return;
    // First start from each origin, then deterministic selection among origins.
    final firstByOrigin = <String, OperationEnvelope>{};
    for (final op in starts) {
      final prev = firstByOrigin[op.originDeviceId];
      if (prev == null || op.originSeq < prev.originSeq) {
        firstByOrigin[op.originDeviceId] = op;
      }
    }
    final start = winner(firstByOrigin.values.toList());
    final initial = start.payload! as Map<String, Object?>;
    entity.values.addAll(initial);
    entity.values.remove('segment_id');
    entity.values['status'] = 'active';
    entity.values['ended_at_ms'] = null;
    for (final f in entity.values.keys) {
      entity.clocks[f] = start;
    }
    entity.segments.add(
      ResolvedSegment(
        initial['segment_id']! as String,
        initial['started_at_ms']! as int,
        start,
      ),
    );
    final owner = start.originDeviceId;
    final ordered = entity.operations.toList()
      ..sort((a, b) => a.originSeq.compareTo(b.originSeq));
    for (final op in ordered) {
      if (op.opId == start.opId) {
        result.applyStates[op.opId] = 'applied';
        continue;
      }
      if (op.originDeviceId != owner ||
          op.action == 'session.start' ||
          op.originSeq < start.originSeq) {
        result.applyStates[op.opId] = 'invalid_domain';
        continue;
      }
      if (op.action == 'delete') {
        final previous = entity.tombstone;
        entity.tombstone = previous == null ? op : winner([previous, op]);
        result.applyStates[op.opId] = 'applied';
        continue;
      }
      final p = op.payload! as Map<String, Object?>;
      final last = entity.segments.last;
      if (op.action == 'session.resume') {
        final at = p['started_at_ms']! as int;
        if (entity.values['status'] != 'paused') {
          result.applyStates[op.opId] = 'pending_dependency';
          continue;
        }
        if (at < last.end! ||
            entity.segments.any((s) => s.id == p['segment_id'])) {
          result.applyStates[op.opId] = 'invalid_domain';
          continue;
        }
        entity.segments.add(
          ResolvedSegment(p['segment_id']! as String, at, op),
        );
        entity.values['status'] = 'active';
      } else {
        final at = p['ended_at_ms']! as int;
        if (last.id != p['segment_id']) {
          result.applyStates[op.opId] = 'pending_dependency';
          continue;
        }
        if (at < last.start) {
          result.applyStates[op.opId] = 'invalid_domain';
          continue;
        }
        final pausedStop =
            op.action == 'session.stop' &&
            entity.values['status'] == 'paused' &&
            last.end == at;
        if (entity.values['status'] != 'active' && !pausedStop) {
          result.applyStates[op.opId] = 'pending_dependency';
          continue;
        }
        last.end = at;
        last.closer = op;
        entity.values['status'] = op.action == 'session.pause'
            ? 'paused'
            : 'completed';
        if (op.action == 'session.stop') {
          entity.values['ended_at_ms'] = at;
          entity.clocks['ended_at_ms'] = op;
        }
      }
      entity.clocks['status'] = op;
      result.applyStates[op.opId] = 'applied';
    }
    entity.state = entity.tombstone == null ? 'materialized' : 'deleted';
  }
}
