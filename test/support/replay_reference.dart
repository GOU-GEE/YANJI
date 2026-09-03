import 'package:yanji/sync/conflict/multi_value_register.dart';
import 'package:yanji/sync/oplog/operation.dart';

typedef EntityKey = (String workspace, String type, String id);

/// Executable protocol reference for the PRE-M1c gate, not a production database
/// projector or membership resolver. Inputs are already-verified envelopes and
/// externally validated membership/cutoff decisions. Full trust comes later.
class ReplayReference {
  final history = <String, OperationEnvelope>{};
  final cutoff = <(String, String), int>{};
  final states = <String, String>{};
  final projection = <EntityKey, Map<String, Object?>>{};
  final textVersions = <EntityKey, List<OperationEnvelope>>{};
  final authorized = <(String, String)>{};

  void authorize(String workspace, String origin) {
    if (!cutoff.containsKey((workspace, origin))) {
      authorized.add((workspace, origin));
    }
    replay();
  }

  void receive(OperationEnvelope op) {
    history[op.opId] = op;
    replay();
  }

  void revoke(String workspace, String origin, int maxAllowed) {
    final key = (workspace, origin), prior = cutoff[(workspace, origin)];
    cutoff[key] = prior == null || maxAllowed < prior ? maxAllowed : prior;
    replay();
  }

  void replay() {
    states.clear();
    projection.clear();
    textVersions.clear();
    final groups = <EntityKey, List<OperationEnvelope>>{};
    for (final op in history.values) {
      final origin = (op.workspaceId, op.originDeviceId);
      if (!authorized.contains(origin)) {
        states[op.opId] = 'pending_authorization';
        continue;
      }
      if (cutoff.containsKey(origin) && op.originSeq > cutoff[origin]!) {
        states[op.opId] = 'unauthorized_revoked';
        continue;
      }
      if (op.payloadSchemaVersion > 1) {
        states[op.opId] = 'pending_schema';
        continue;
      }
      groups
          .putIfAbsent((op.workspaceId, op.entityType, op.entityId), () => [])
          .add(op);
    }
    for (final entry in groups.entries) {
      final ops = entry.value;
      if (entry.key.$2 != 'daily_review' &&
          ops.any((op) => op.action == 'delete')) {
        for (final op in ops) {
          states[op.opId] = 'applied';
        }
        continue;
      }
      if (!ops.any((op) => op.action == 'create')) {
        for (final op in ops) {
          states[op.opId] = 'pending_entity_create';
        }
        continue;
      }
      final values = <String, Object?>{},
          clocks = <String, OperationEnvelope>{};
      for (final op in ops) {
        final payload = op.payload;
        if (payload is! Map<String, Object?> || op.action == 'delete') continue;
        for (final field in payload.entries) {
          if (!clocks.containsKey(field.key) ||
              op.compareWinner(clocks[field.key]!) > 0) {
            clocks[field.key] = op;
            values[field.key] = field.value;
          }
        }
      }
      if (entry.key.$2 == 'daily_review') {
        final versions = MultiValueRegister.versions(
          ops.where((op) => op.action != 'delete'),
          'content',
        );
        textVersions[entry.key] = versions;
        if (versions.isNotEmpty) {
          values['content'] =
              (MultiValueRegister.winner(versions).payload!
                  as Map<String, Object?>)['content'];
        }
      }
      projection[entry.key] = values;
    }
    // Re-evaluate dependencies after all creates have been considered. This
    // fixed point also handles a dependent entity whose dependency is pending.
    var changed = true;
    while (changed) {
      changed = false;
      for (final key in projection.keys.toList()) {
        final subject = projection[key]!['subject_id'];
        if (subject is String &&
            !projection.containsKey((key.$1, 'subject', subject))) {
          projection.remove(key);
          changed = true;
        }
      }
    }
    for (final entry in groups.entries) {
      for (final op in entry.value) {
        states.putIfAbsent(
          op.opId,
          () => projection.containsKey(entry.key)
              ? 'applied'
              : 'pending_dependency',
        );
      }
    }
  }
}
