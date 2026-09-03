import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/clock/hlc.dart';
import '../../core/crypto/device_identity.dart';
import '../../core/crypto/operation_crypto.dart';
import '../../core/database/app_database.dart';
import '../../core/ids/entity_ids.dart';
import '../protocol/deterministic_cbor.dart';
import 'operation.dart';

/// Result of a membership resolver, not of signature verification.
/// Full Genesis/authorization-chain construction belongs to the Trust milestone.
final class OriginPolicy {
  OriginPolicy({
    required this.publicKey,
    required this.authorized,
    this.cutoff,
  });
  final SimplePublicKey publicKey;
  final bool authorized;
  final int? cutoff;
  bool permits(int seq) => authorized && (cutoff == null || seq <= cutoff!);
}

typedef OriginLookup = Future<OriginPolicy?> Function(
  String workspaceId,
  String originId,
);

enum ReceiveResult { stored, duplicate, pendingAuthorization, rejected }

/// M1b transaction kernel ONLY: signed log + persistent clock/context.
/// M1c must extend the SAME transaction with business projection/field clocks.
/// There is no UI provider or permissive default trust policy for this class.
final class OperationJournal {
  OperationJournal(
    this.database,
    this.identity, {
    required this.lookupOrigin,
    int Function()? nowMs,
    EntityIds? ids,
    this.validateEnvelope,
  }) : _now = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch),
       _ids = ids ?? EntityIds();
  final AppDatabase database;
  final DeviceIdentity identity;
  final OriginLookup lookupOrigin;
  final void Function(OperationEnvelope)? validateEnvelope;
  final int Function() _now;
  final EntityIds _ids;
  final _crypto = OperationCrypto();

  Future<void> _ensureClock(String workspace) => database.customStatement(
    '''
    INSERT OR IGNORE INTO workspace_clock_state (workspace_id, device_id) VALUES (?, ?)
  ''',
    [workspace, identity.deviceId],
  );

  Future<Map<String, int>> context(String workspace) async {
    final rows = await database
        .customSelect(
          'SELECT origin_device_id, max_observed_seq FROM observed_origins WHERE workspace_id=? AND device_id=?',
          variables: [Variable(workspace), Variable(identity.deviceId)],
        )
        .get();
    return {
      for (final row in rows)
        row.read<String>('origin_device_id'): row.read<int>('max_observed_seq'),
    };
  }

  Future<void> _observeContext(OperationEnvelope e) async {
    final observed = {...e.causalContext, e.originDeviceId: e.originSeq};
    for (final entry in observed.entries) {
      await database.customStatement(
        '''
        INSERT INTO observed_origins VALUES (?, ?, ?, ?)
        ON CONFLICT(workspace_id, device_id, origin_device_id) DO UPDATE SET
        max_observed_seq = MAX(max_observed_seq, excluded.max_observed_seq)
      ''',
        [e.workspaceId, identity.deviceId, entry.key, entry.value],
      );
    }
  }

  Future<Operation> append({
    required String workspaceId,
    required String entityType,
    required String entityId,
    required String action,
    required Object? payload,
    int payloadSchemaVersion = 1,
  }) => database.transaction(() async {
    // A write before the read acquires SQLite's writer lock, including when
    // another connection attempts to allocate a sequence for the same origin.
    await _ensureClock(workspaceId);
    final row = await _clock(workspaceId);
    final seq = row.$1;
    if (seq == 0x7fffffffffffffff) {
      throw StateError('Origin sequence exhausted');
    }
    final policy = await lookupOrigin(workspaceId, identity.deviceId);
    if (policy == null ||
        !policy.authorized ||
        policy.cutoff != null ||
        DeterministicCbor.compareBytes(
              policy.publicKey.bytes,
              identity.publicKey.bytes,
            ) !=
            0) {
      throw StateError('Local origin is not an active authorized member');
    }
    final observed = await context(workspaceId);
    if ((observed[identity.deviceId] ?? 0) != seq - 1) {
      throw StateError('Origin clock/context mismatch');
    }
    final hlc = Hlc.tick(nowMs: _now(), previous: row.$2);
    final envelope = OperationEnvelope(
      opId: _ids.next(),
      workspaceId: workspaceId,
      originDeviceId: identity.deviceId,
      originSeq: seq,
      hlc: hlc,
      causalContext: observed,
      entityType: entityType,
      entityId: entityId,
      action: action,
      payloadSchemaVersion: payloadSchemaVersion,
      payload: payload,
    );
    validateEnvelope?.call(envelope);
    final signed = await _crypto.sign(envelope, identity);
    await _insert(
      signed,
      envelope,
      payloadSchemaVersion > 1 ? 'pending_schema' : 'pending_entity_create',
      null,
    );
    await _observeContext(envelope);
    await _saveClock(workspaceId, seq + 1, hlc);
    return signed;
  });

  Future<(int, Hlc)> _clock(String workspace) async {
    final row = await database
        .customSelect(
          'SELECT * FROM workspace_clock_state WHERE workspace_id=? AND device_id=?',
          variables: [Variable(workspace), Variable(identity.deviceId)],
        )
        .getSingle();
    return (
      row.read<int>('next_origin_seq'),
      Hlc(row.read<int>('last_hlc_wall_ms'), row.read<int>('last_hlc_counter')),
    );
  }

  Future<void> _saveClock(String workspace, int nextSeq, Hlc hlc) =>
      database.customStatement(
        '''
    UPDATE workspace_clock_state SET next_origin_seq=?, last_hlc_wall_ms=?, last_hlc_counter=?
    WHERE workspace_id=? AND device_id=?
  ''',
        [nextSeq, hlc.wallMs, hlc.counter, workspace, identity.deviceId],
      );

  Future<void> _insert(
    Operation packet,
    OperationEnvelope e,
    String state,
    String? from,
  ) => database.customStatement(
    '''
    INSERT INTO oplog (op_id, workspace_id, origin_device_id, origin_seq, wire_version,
    hlc_wall_ms, hlc_counter, entity_type, entity_id, action, payload_schema_version,
    envelope_bytes, signature, apply_state, received_from_device_id, received_at_ms)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''',
    [
      e.opId,
      e.workspaceId,
      e.originDeviceId,
      e.originSeq,
      e.wireVersion,
      e.hlc.wallMs,
      e.hlc.counter,
      e.entityType,
      e.entityId,
      e.action,
      e.payloadSchemaVersion,
      packet.envelopeBytes,
      packet.signature,
      state,
      from,
      _now(),
    ],
  );

  Future<ReceiveResult> _reject(String reason) async {
    await database.customStatement(
      'INSERT INTO sync_quarantine (reason, received_at_ms) VALUES (?, ?)',
      [reason, _now()],
    );
    return ReceiveResult.rejected;
  }

  /// Routing hints are untrusted and checked against the envelope AFTER verifying
  /// its original bytes with the resolver's key. Unknown key is not auto-trusted.
  Future<ReceiveResult> receive(
    Operation packet, {
    required String workspaceId,
    required String originDeviceId,
    String? receivedFrom,
  }) async {
    final policy = await lookupOrigin(workspaceId, originDeviceId);
    if (policy == null) return _reject('unknown_origin_key');
    if (!await _crypto.verify(packet, policy.publicKey)) {
      return _reject('invalid_signature');
    }
    final OperationEnvelope e;
    try {
      e = packet.parse();
    } on FormatException {
      return _reject('malformed');
    }
    if (e.workspaceId != workspaceId || e.originDeviceId != originDeviceId) {
      return _reject('routing_mismatch');
    }
    try {
      validateEnvelope?.call(e);
    } on FormatException {
      return _reject('invalid_payload');
    }
    return database.transaction(() async {
      await _ensureClock(workspaceId);
      final existing = await database
          .customSelect(
            'SELECT * FROM oplog WHERE op_id=? OR (workspace_id=? AND origin_device_id=? AND origin_seq=?)',
            variables: [
              Variable(e.opId),
              Variable(workspaceId),
              Variable(originDeviceId),
              Variable(e.originSeq),
            ],
          )
          .get();
      if (existing.isNotEmpty) {
        if (existing.length != 1 ||
            DeterministicCbor.compareBytes(
                  existing.single.read<Uint8List>('envelope_bytes'),
                  packet.envelopeBytes,
                ) !=
                0 ||
            DeterministicCbor.compareBytes(
                  existing.single.read<Uint8List>('signature'),
                  packet.signature,
                ) !=
                0) {
          return _reject('identity_collision');
        }
      }
      // Re-resolve under the transaction in case membership changed while signing.
      final current = await lookupOrigin(workspaceId, originDeviceId);
      if (current == null ||
          DeterministicCbor.compareBytes(
                current.publicKey.bytes,
                policy.publicKey.bytes,
              ) !=
              0) {
        return _reject('identity_key_changed');
      }
      final String state;
      if (!current.authorized) {
        state = 'pending_authorization';
      } else if (!current.permits(e.originSeq)) {
        state = 'unauthorized_revoked';
      } else {
        state = e.payloadSchemaVersion > 1
            ? 'pending_schema'
            : 'pending_entity_create';
      }
      if (existing.isNotEmpty &&
          existing.single.read<String>('apply_state') !=
              'pending_authorization') {
        if (state == 'pending_authorization' ||
            state == 'unauthorized_revoked') {
          await database.customStatement(
            'UPDATE oplog SET apply_state=? WHERE op_id=?',
            [state, e.opId],
          );
          return state == 'pending_authorization'
              ? ReceiveResult.pendingAuthorization
              : ReceiveResult.rejected;
        }
        // A permanently revoked dot cannot be restored by a later wider policy.
        if (existing.single.read<String>('apply_state') ==
            'unauthorized_revoked') {
          return ReceiveResult.rejected;
        }
        return ReceiveResult.duplicate;
      }
      if (existing.isEmpty) {
        await _insert(packet, e, state, receivedFrom);
      } else {
        await database.customStatement(
          'UPDATE oplog SET apply_state=? WHERE op_id=?',
          [state, e.opId],
        );
      }
      if (state == 'pending_authorization') {
        return ReceiveResult.pendingAuthorization;
      }
      if (state == 'unauthorized_revoked') return ReceiveResult.rejected;
      final clock = await _clock(workspaceId);
      await _saveClock(
        workspaceId,
        clock.$1,
        Hlc.receive(nowMs: _now(), local: clock.$2, remote: e.hlc),
      );
      await _observeContext(e);
      return ReceiveResult.stored;
    });
  }

  /// Call on membership changes: retry pending proofs and invalidate previously
  /// accepted history past cutoff. M1c must then reproject affected entities.
  /// HLC is monotonic and is never rolled back when history becomes invalid.
  Future<void> refreshAuthorization(String workspaceId) async {
    final packets = await _packets(workspaceId, replicableOnly: false);
    for (final packet in packets) {
      final e = packet.parse();
      await receive(
        packet,
        workspaceId: workspaceId,
        originDeviceId: e.originDeviceId,
      );
    }
  }

  /// Only authenticated, authorized history is a normal Gossip source.
  Future<List<Operation>> export(String workspaceId) =>
      _packets(workspaceId, replicableOnly: true);

  Future<List<Operation>> _packets(
    String workspaceId, {
    required bool replicableOnly,
  }) async {
    final rows = await database
        .customSelect(
          "SELECT * FROM oplog WHERE workspace_id=? ${replicableOnly ? "AND apply_state NOT IN ('pending_authorization', 'unauthorized_revoked')" : ''} ORDER BY origin_device_id, origin_seq",
          variables: [Variable(workspaceId)],
        )
        .get();
    return [
      for (final row in rows)
        Operation(
          envelopeBytes: row.read<Uint8List>('envelope_bytes'),
          signature: row.read<Uint8List>('signature'),
        ),
    ];
  }

  Future<Map<String, int>> frontier(String workspaceId) async {
    final seqs = <String, Set<int>>{};
    for (final packet in await export(workspaceId)) {
      final e = packet.parse();
      seqs.putIfAbsent(e.originDeviceId, () => {}).add(e.originSeq);
    }
    return {
      for (final entry in seqs.entries) entry.key: _contiguous(entry.value),
    };
  }

  int _contiguous(Set<int> values) {
    var n = 0;
    while (n < 0x7fffffffffffffff && values.contains(n + 1)) {
      n++;
    }
    return n;
  }
}
