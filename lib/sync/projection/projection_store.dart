import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../domain/business_schema.dart';
import '../oplog/operation.dart';
import '../oplog/operation_journal.dart';
import '../protocol/deterministic_cbor.dart';
import 'conflict_resolver.dart';

/// Production materialization. Full-workspace replacement is deliberately used
/// until M3: changes can invalidate descendants as well as the directly edited row.
/// Callers never clear Oplog or persistent clocks when rebuilding derived state.
final class ProjectionStore {
  ProjectionStore(this.database, this.lookupOrigin);
  final AppDatabase database;
  final OriginLookup lookupOrigin;
  final resolver = ConflictResolver();
  static const _deleteOrder = [
    'study_session_segments',
    'study_sessions',
    'daily_reviews',
    'tasks',
    'exam_profiles',
    'subjects',
    'workspaces',
    'entity_field_clock',
    'text_field_versions',
    'tombstones',
    'materialization_state',
    'trusted_devices',
    'origin_progress',
  ];
  static const _insertOrder = [
    'workspace',
    'subject',
    'task',
    'exam_profile',
    'daily_review',
    'study_session',
  ];

  Future<void> rebuildEntity(String workspace, String type, String id) {
    if (!BusinessSchema.tables.containsKey(type) &&
        type != 'study_session_segment') {
      throw ArgumentError('Unknown entity type');
    }
    if (id.isEmpty) throw ArgumentError('Empty entity ID');
    return rebuildWorkspace(workspace);
  }

  Future<void> rebuildWorkspace(
    String workspace,
  ) => database.transaction(() async {
    final rows = await database
        .customSelect(
          'SELECT * FROM oplog WHERE workspace_id=?',
          variables: [Variable(workspace)],
        )
        .get();
    final history = <OperationEnvelope>[];
    final systemOperations = <OperationEnvelope>[];
    final origins = <String>{};
    for (final row in rows) {
      origins.add(row.read<String>('origin_device_id'));
      if ([
        'pending_authorization',
        'unauthorized_revoked',
        'pending_schema',
      ].contains(row.read<String>('apply_state'))) {
        continue;
      }
      final e = OperationEnvelope.fromBytes(
        row.read<Uint8List>('envelope_bytes'),
      );
      if (e.payloadSchemaVersion == 1) {
        if (e.entityType == 'device') {
          systemOperations.add(e);
        } else {
          history.add(e);
        }
      }
    }
    final resolution = resolver.resolve(history);
    final aliases = _subjectAliases(resolution);
    for (final table in _deleteOrder) {
      await _delete(table, workspace);
    }
    // Membership is a materialized view of explicit verified trust decisions,
    // not an alternate source of authority or an implicit self-enrolment path.
    for (final origin in origins) {
      final policy = await lookupOrigin(workspace, origin);
      if (policy == null) continue;
      await _insert('trusted_devices', {
        'workspace_id': workspace,
        'device_id': origin,
        'identity_public_key': Uint8List.fromList(policy.publicKey.bytes),
        'trust_state': policy.cutoff != null
            ? 'revoked'
            : policy.authorized
            ? 'active'
            : 'pending',
        'max_allowed_origin_seq': policy.cutoff,
      });
    }
    for (final operation in systemOperations) {
      await database.customStatement(
        'UPDATE oplog SET apply_state=?, local_error=NULL WHERE op_id=?',
        ['applied', operation.opId],
      );
    }
    for (final entity in resolution.entities.values) {
      final base = {
        'workspace_id': workspace,
        'entity_type': entity.key.$1,
        'entity_id': entity.key.$2,
      };
      await _insert('materialization_state', {...base, 'state': entity.state});
      final deletion = entity.tombstone;
      if (deletion != null) {
        await _insert('tombstones', {
          ...base,
          'delete_op_id': deletion.opId,
          ..._clock(deletion),
        });
        continue;
      }
      for (final f in entity.clocks.entries) {
        await _field(base, f.key, entity.values[f.key], f.value);
      }
      for (final version in entity.textVersions) {
        await _insert('text_field_versions', {
          ...base,
          'field_name': 'content',
          'op_id': version.opId,
          'origin_device_id': version.originDeviceId,
          'origin_seq': version.originSeq,
          'value': (version.payload! as Map<String, Object?>)['content'],
          'is_active': 1,
        });
      }
    }
    for (final type in _insertOrder) {
      final entities =
          resolution.entities.values
              .where((e) => e.key.$1 == type && e.state == 'materialized')
              .toList()
            ..sort((a, b) => a.key.$2.compareTo(b.key.$2));
      for (final entity in entities) {
        if (type == 'subject' && aliases[entity.key.$2] != entity.key.$2) {
          continue;
        }
        final values = Map<String, Object?>.from(entity.values);
        for (final key in ['subject_id', 'parent_subject_id']) {
          if (values[key] != null) {
            values[key] = aliases[values[key]] ?? values[key];
          }
        }
        if (type == 'subject') {
          final members = entities
              .where((e) => aliases[e.key.$2] == entity.key.$2)
              .toList();
          values['name'] = (values['name'] as String).trim();
          values['archived'] = members.every(
            (e) => e.values['archived'] == true,
          );
          for (final field in [
            'category',
            'target_score_x100',
            'max_score_x100',
          ]) {
            values[field] ??= members
                .map((e) => e.values[field])
                .where((v) => v != null)
                .firstOrNull;
          }
        }
        await _insert(BusinessSchema.tables[type]!, {
          'id': entity.key.$2,
          if (type != 'workspace') 'workspace_id': workspace,
          ...values,
        });
        if (type == 'study_session') {
          for (final segment in entity.segments) {
            await _insert('study_session_segments', {
              'id': segment.id,
              'workspace_id': workspace,
              'session_id': entity.key.$2,
              'started_at_ms': segment.start,
              'ended_at_ms': segment.end,
            });
            final base = {
              'workspace_id': workspace,
              'entity_type': 'study_session_segment',
              'entity_id': segment.id,
            };
            await _field(base, 'started_at_ms', segment.start, segment.creator);
            await _field(base, 'session_id', entity.key.$2, segment.creator);
            if (segment.closer != null) {
              await _field(base, 'ended_at_ms', segment.end, segment.closer!);
            }
          }
        }
      }
    }
    for (final state in resolution.applyStates.entries) {
      await database.customStatement(
        'UPDATE oplog SET apply_state=?, local_error=? WHERE op_id=?',
        [
          state.value,
          state.value == 'invalid_domain' ? 'domain_invariant' : null,
          state.key,
        ],
      );
    }
    // Contiguous storage progress is independent from successful materialization.
    final sequences = <String, Set<int>>{};
    for (final row in rows) {
      if ([
        'pending_authorization',
        'unauthorized_revoked',
      ].contains(row.read<String>('apply_state'))) {
        continue;
      }
      sequences
          .putIfAbsent(row.read<String>('origin_device_id'), () => {})
          .add(row.read<int>('origin_seq'));
    }
    for (final entry in sequences.entries) {
      var n = 0;
      while (n < 0x7fffffffffffffff && entry.value.contains(n + 1)) {
        n++;
      }
      await _insert('origin_progress', {
        'workspace_id': workspace,
        'origin_device_id': entry.key,
        'max_contiguous_seq': n,
      });
    }
  });

  /// Retain every signed entity in history; only the derived subject rows and
  /// their references coalesce. Sorting makes this independent of arrival order.
  Map<String, String> _subjectAliases(Resolution resolution) {
    final subjects =
        resolution.entities.values
            .where((e) => e.key.$1 == 'subject' && e.state == 'materialized')
            .toList()
          ..sort((a, b) => a.key.$2.compareTo(b.key.$2));
    final aliases = <String, String>{};
    final byName = <(String?, String), String>{};
    for (final child in [false, true]) {
      for (final subject in subjects) {
        final parent = subject.values['parent_subject_id'] as String?;
        if ((parent != null) != child) continue;
        final key = (
          parent == null ? null : aliases[parent] ?? parent,
          (subject.values['name'] as String).trim(),
        );
        aliases[subject.key.$2] = byName.putIfAbsent(key, () => subject.key.$2);
      }
    }
    return aliases;
  }

  Future<Map<String, String>> subjectAliases(String workspace) async {
    final rows = await database
        .customSelect(
          "SELECT envelope_bytes FROM oplog WHERE workspace_id=? AND apply_state NOT IN ('pending_authorization','unauthorized_revoked','pending_schema')",
          variables: [Variable(workspace)],
        )
        .get();
    final history = rows
        .map(
          (row) => OperationEnvelope.fromBytes(
            row.read<Uint8List>('envelope_bytes'),
          ),
        )
        .where((e) => e.payloadSchemaVersion == 1 && e.entityType != 'device')
        .toList();
    return _subjectAliases(resolver.resolve(history));
  }

  Map<String, Object?> _clock(OperationEnvelope op) => {
    'hlc_wall_ms': op.hlc.wallMs,
    'hlc_counter': op.hlc.counter,
    'origin_device_id': op.originDeviceId,
    'origin_seq': op.originSeq,
  };
  Future<void> _field(
    Map<String, Object?> base,
    String field,
    Object? value,
    OperationEnvelope op,
  ) => _insert('entity_field_clock', {
    ...base,
    'field_name': field,
    'winner_op_id': op.opId,
    ..._clock(op),
    'value_bytes': DeterministicCbor.encode(value),
  });
  Variable _variable(Object? value) => switch (value) {
    int v => Variable<int>(v),
    bool v => Variable<int>(v ? 1 : 0),
    String v => Variable<String>(v),
    Uint8List v => Variable<Uint8List>(v),
    null => const Variable<String>(null),
    _ => throw ArgumentError('Unsupported SQL value'),
  };
  Future<void> _insert(String table, Map<String, Object?> row) async {
    final info = database.allTables.singleWhere(
      (t) => t.actualTableName == table,
    );
    await database.customInsert(
      'INSERT INTO $table (${row.keys.map((k) => '"$k"').join(',')}) VALUES (${List.filled(row.length, '?').join(',')})',
      variables: row.values.map(_variable).toList(),
      updates: {info},
    );
  }

  Future<void> _delete(String table, String workspace) async {
    final info = database.allTables.singleWhere(
      (t) => t.actualTableName == table,
    );
    await database.customUpdate(
      'DELETE FROM $table WHERE ${table == 'workspaces' ? 'id' : 'workspace_id'}=?',
      variables: [Variable(workspace)],
      updates: {info},
    );
  }

  Future<String> projectionDigest(
    String workspace,
  ) => database.transaction(() async {
    final snapshots = <String, Object?>{};
    for (final table in _deleteOrder) {
      // Storage progress and membership are compared separately during sync.
      // An opaque future-schema packet must not alter the business digest.
      if (table == 'origin_progress' || table == 'trusted_devices') continue;
      final rows = await database
          .customSelect(
            'SELECT * FROM $table WHERE ${table == 'workspaces' ? 'id' : 'workspace_id'}=?',
            variables: [Variable(workspace)],
          )
          .get();
      final canonical =
          rows
              .map(
                (r) =>
                    DeterministicCbor.encode(Map<String, Object?>.from(r.data)),
              )
              .toList()
            ..sort(DeterministicCbor.compareBytes);
      snapshots[table] = canonical;
    }
    final hash = await Sha256().hash(DeterministicCbor.encode(snapshots));
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  });
}
