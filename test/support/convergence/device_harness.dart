import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:yanji/core/clock/hlc.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/crypto/operation_crypto.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';
import 'package:yanji/core/ids/entity_ids.dart';
import 'package:yanji/sync/operation_pipeline.dart';
import 'package:yanji/sync/oplog/operation.dart';
import 'package:yanji/sync/oplog/operation_journal.dart';
import 'package:yanji/sync/protocol/deterministic_cbor.dart';

String uid(int n) =>
    '01991f82-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';
final workspace = uid(1), policyWorkspace = uid(2);
final baseSubject = uid(3), baseTask = uid(4);
final reviewId = 'daily_review/$workspace/2026-09-03';
String deviceId(int index) => uid(100 + index);

/// Public deterministic TEST secrets only. Never installed in app composition.
/// Reopening reloads a new storage/service/identity object from this fixture file.
class FixtureKeyStorage implements SecureKeyStorage {
  FixtureKeyStorage(this.file);
  final File file;
  @override
  Future<IdentitySecret?> readCurrent() async {
    final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return IdentitySecret(
      deviceId: map['id'] as String,
      keyReference: 'test.fixture',
      seed: List<int>.from(map['seed'] as List),
    );
  }

  @override
  Future<IdentitySecret> installIfAbsent(IdentitySecret candidate) =>
      throw UnsupportedError('Preprovisioned test keys only');
  @override
  Future<void> replaceCurrent(IdentitySecret replacement) =>
      throw UnsupportedError('Preprovisioned test keys only');
}

/// The transport envelope has no business concepts. Routing hints are untrusted.
class WirePacket {
  WirePacket(this.operation, this.workspaceId, this.origin, this.seq);
  factory WirePacket.fromOperation(Operation op) {
    final e = op.parse();
    return WirePacket(op, e.workspaceId, e.originDeviceId, e.originSeq);
  }
  final Operation operation;
  final String workspaceId, origin;
  final int seq;
  String get stream => '$workspaceId/$origin';
  String get key => '$stream/$seq';
  WirePacket copy() => WirePacket(
    Operation(
      envelopeBytes: operation.envelopeBytes,
      signature: operation.signature,
    ),
    workspaceId,
    origin,
    seq,
  );
}

const businessTables = [
  'workspaces',
  'exam_profiles',
  'subjects',
  'tasks',
  'study_sessions',
  'study_session_segments',
  'daily_reviews',
];
const derivedTables = [
  'entity_field_clock',
  'tombstones',
  'text_field_versions',
  'materialization_state',
  'trusted_devices',
];
Object? normalized(Object? v) {
  if (v is Uint8List) {
    return v.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  if (v is Map) {
    final keys = v.keys.cast<String>().toList()..sort();
    return {for (final k in keys) k: normalized(v[k])};
  }
  if (v is List) return v.map(normalized).toList();
  return v;
}

String canonical(Object? v) => jsonEncode(normalized(v));

class TestDevice {
  TestDevice._(this.index, this.directory, this.db, this.identity);
  final int index;
  final Directory directory;
  final AppDatabase db;
  final DeviceIdentity identity;
  String get name => String.fromCharCode(65 + index);
  String get databasePath =>
      '${directory.path}/device_${name.toLowerCase()}.sqlite';
  late OperationApplier applier;
  late OperationWriter writer;
  late EntityIds ids;
  int wall = 2000000, nextIdSeq = 1;
  int applyMicros = 0, applyCount = 0;

  static Future<TestDevice> open(int index, Directory dir) async {
    final name = String.fromCharCode(97 + index);
    final identity = await IdentityService(
      FixtureKeyStorage(File('${dir.path}/$name.identity.json')),
    ).loadOrCreate();
    final db = AppDatabase(
      openDatabaseFile(File('${dir.path}/device_$name.sqlite')),
    );
    final d = TestDevice._(index, dir, db, identity);
    // These two tables are TEST policy input, not a production Genesis algorithm.
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS test_policy_base (origin TEXT PRIMARY KEY, public_key BLOB NOT NULL, authorized INTEGER NOT NULL)',
    );
    await db.customStatement(
      'CREATE TABLE IF NOT EXISTS test_policy_log (seq INTEGER PRIMARY KEY, envelope_bytes BLOB NOT NULL, signature BLOB NOT NULL)',
    );
    d.ids = EntityIds(
      generate: () => uid((index + 1) * 1000000000 + d.nextIdSeq),
    );
    d.applier = OperationApplier(
      db,
      identity,
      lookupOrigin: d.lookup,
      nowMs: () => d.wall,
      ids: d.ids,
    );
    d.writer = OperationWriter(d.applier);
    return d;
  }

  Future<OriginPolicy?> lookup(String w, String origin) async {
    if (w != workspace) return null;
    final base = (await rows('test_policy_base'))
        .where((r) => r['origin'] == origin)
        .toList();
    if (base.isEmpty) return null;
    var authorized = base.single['authorized'] == 1;
    int? cutoff;
    for (final row in await rows('test_policy_log')) {
      final e = OperationEnvelope.fromBytes(row['envelope_bytes'] as Uint8List);
      final p = e.payload! as Map<String, Object?>;
      if (p['origin'] != origin) continue;
      if (e.action == 'grant') authorized = true;
      if (e.action == 'revoke') {
        authorized = true;
        final c = p['cutoff']! as int;
        if (cutoff == null || c < cutoff) cutoff = c;
      }
    }
    return OriginPolicy(
      publicKey: SimplePublicKey(
        List<int>.from(base.single['public_key'] as List),
        type: KeyPairType.ed25519,
      ),
      authorized: authorized,
      cutoff: cutoff,
    );
  }

  Future<List<Map<String, dynamic>>> rows(String table) async =>
      (await db.customSelect('SELECT * FROM $table').get())
          .map((r) => r.data)
          .toList();
  Future<List<Map<String, dynamic>>> query(String sql) async =>
      (await db.customSelect(sql).get()).map((r) => r.data).toList();
  Future<int> nextSeq() async {
    final clocks = await rows('workspace_clock_state');
    return clocks.isEmpty ? 1 : clocks.single['next_origin_seq'] as int;
  }

  Future<Operation> execute(
    String type,
    String id,
    String action,
    Map<String, Object?> payload,
  ) async {
    nextIdSeq = await nextSeq();
    final sw = Stopwatch()..start();
    try {
      return await writer.execute(
        BusinessCommand(
          workspaceId: workspace,
          entityType: type,
          entityId: id,
          action: action,
          payload: payload,
        ),
      );
    } finally {
      applyMicros += sw.elapsedMicroseconds;
      applyCount++;
    }
  }

  /// Future payloads use the production journal's supported opaque-schema path.
  /// Known business commands always use OperationWriter.
  Future<Operation> futureOperation() async {
    nextIdSeq = await nextSeq();
    return db.transaction(() async {
      final op =
          await OperationJournal(
            db,
            identity,
            lookupOrigin: lookup,
            nowMs: () => wall,
            ids: ids,
          ).append(
            workspaceId: workspace,
            entityType: 'future_entity',
            entityId: uid(999),
            action: 'future',
            payload: {'opaque': nextIdSeq},
            payloadSchemaVersion: 99,
          );
      await applier.projections.rebuildWorkspace(workspace);
      return op;
    });
  }

  Future<List<WirePacket>> exportAvailableOperations() async => [
    for (final op in await applier.export(workspace))
      WirePacket.fromOperation(op),
    for (final r in await rows('test_policy_log'))
      WirePacket.fromOperation(
        Operation(
          envelopeBytes: r['envelope_bytes'] as Uint8List,
          signature: r['signature'] as Uint8List,
        ),
      ),
  ];
  Future<void> receive(WirePacket packet, {required String from}) async {
    final sw = Stopwatch()..start();
    try {
      if (packet.workspaceId == policyWorkspace) {
        await _receivePolicy(packet);
      } else {
        await applier.receive(
          packet.operation,
          workspaceId: packet.workspaceId,
          originDeviceId: packet.origin,
          receivedFrom: from,
        );
      }
    } finally {
      applyMicros += sw.elapsedMicroseconds;
      applyCount++;
    }
  }

  /// Signed membership-policy fixture: one explicitly trusted issuer A, terminal
  /// minimum cutoff. It feeds OriginLookup and tests delivery/retry/rebuild only.
  Future<WirePacket> policy(String origin, {int? cutoff}) async {
    if (index != 0) throw StateError('Fixture issuer is A');
    final seq = (await rows('test_policy_log')).length + 1;
    final e = OperationEnvelope(
      opId: uid(9000000000 + seq),
      workspaceId: policyWorkspace,
      originDeviceId: identity.deviceId,
      originSeq: seq,
      hlc: Hlc(wall, seq),
      causalContext: {identity.deviceId: seq - 1},
      entityType: 'test_membership_policy',
      entityId: origin,
      action: cutoff == null ? 'grant' : 'revoke',
      payloadSchemaVersion: 1,
      payload: {'origin': origin, 'cutoff': ?cutoff},
    );
    final packet = WirePacket.fromOperation(
      await OperationCrypto().sign(e, identity),
    );
    await _receivePolicy(packet);
    return packet;
  }

  Future<void> _receivePolicy(WirePacket packet) async {
    final issuer = await lookup(workspace, deviceId(0));
    if (packet.origin != deviceId(0) ||
        issuer == null ||
        !await OperationCrypto().verify(packet.operation, issuer.publicKey)) {
      throw StateError('Invalid test policy signature');
    }
    final e = packet.operation.parse();
    if (e.workspaceId != policyWorkspace ||
        e.originDeviceId != packet.origin ||
        e.originSeq != packet.seq ||
        e.entityType != 'test_membership_policy' ||
        !['grant', 'revoke'].contains(e.action)) {
      throw StateError('Invalid test policy');
    }
    await db.transaction(() async {
      final existing = (await rows('test_policy_log'))
          .where((r) => r['seq'] == e.originSeq);
      if (existing.isNotEmpty) {
        if (canonical(existing.single['envelope_bytes']) !=
            canonical(e.bytes)) {
          throw StateError('Policy collision');
        }
        return;
      }
      await db.customStatement('INSERT INTO test_policy_log VALUES (?, ?, ?)', [
        e.originSeq,
        packet.operation.envelopeBytes,
        packet.operation.signature,
      ]);
      await applier.refreshAuthorization(workspace);
    });
  }

  Future<String> digest() => applier.projectionDigest(workspace);
  Future<Map<String, int>> frontier() async {
    final result = <String, int>{};
    for (final r in await rows('origin_progress')) {
      result['$workspace/${r['origin_device_id']}'] =
          r['max_contiguous_seq'] as int;
    }
    final policy = (await rows('test_policy_log'))
        .map((r) => r['seq'] as int)
        .toSet();
    if (policy.isNotEmpty) {
      var n = 0;
      while (policy.contains(n + 1)) {
        n++;
      }
      result['$policyWorkspace/${deviceId(0)}'] = n;
    }
    return result;
  }

  Future<Object> pendingState() async => query(
    "SELECT op_id,apply_state FROM oplog WHERE apply_state <> 'applied' ORDER BY op_id",
  );
  Future<Map<String, Object?>> snapshot() async {
    final result = <String, Object?>{};
    for (final t in [...businessTables, ...derivedTables]) {
      final data = (await rows(t)).map((r) => normalized(r)).toList()
        ..sort((a, b) => canonical(a).compareTo(canonical(b)));
      result[t] = data;
    }
    // Invalid/revoked history may exist only on peers that saw it before cutoff.
    // Compare valid authorization state; check rejected history separately below.
    result['authorized_operations'] = await query(
      "SELECT op_id,apply_state,payload_schema_version FROM oplog WHERE apply_state NOT IN ('unauthorized_revoked','pending_authorization') ORDER BY op_id",
    );
    result['frontier'] = await frontier();
    result['policy_history'] =
        (await rows('test_policy_log')).map(normalized).toList()
          ..sort((a, b) => canonical(a).compareTo(canonical(b)));
    return result;
  }

  Future<void> invariantCheck() async {
    Future<void> empty(String label, String sql) async {
      final bad = await query(sql);
      if (bad.isNotEmpty) {
        throw StateError('$name invariant $label: ${canonical(bad)}');
      }
    }

    await empty('foreign_keys', 'PRAGMA foreign_key_check');
    await empty(
      'completed_open',
      "SELECT s.id FROM study_sessions s JOIN study_session_segments g ON s.id=g.session_id WHERE s.status='completed' AND g.ended_at_ms IS NULL",
    );
    await empty(
      'multiple_open',
      'SELECT session_id FROM study_session_segments WHERE ended_at_ms IS NULL GROUP BY session_id HAVING COUNT(*)>1',
    );
    await empty(
      'segment_interval',
      'SELECT id FROM study_session_segments WHERE ended_at_ms<started_at_ms',
    );
    await empty(
      'tombstone_materialized',
      "SELECT t.entity_id FROM tombstones t JOIN materialization_state m USING(workspace_id,entity_type,entity_id) WHERE m.state<>'deleted'",
    );
    for (final t in businessTables) {
      await empty(
        'tombstone_$t',
        "SELECT b.id FROM $t b JOIN tombstones t ON t.entity_id=b.id",
      );
    }
    for (final spec in [
      ('entity_field_clock', 'winner_op_id'),
      ('text_field_versions', 'op_id'),
      ('tombstones', 'delete_op_id'),
    ]) {
      await empty(
        'valid_${spec.$1}',
        "SELECT f.* FROM ${spec.$1} f LEFT JOIN oplog o ON f.${spec.$2}=o.op_id WHERE o.op_id IS NULL OR o.apply_state IN ('unauthorized_revoked','pending_authorization','pending_schema','invalid_domain') OR o.payload_schema_version<>1",
      );
    }
    await empty(
      'timer_owner',
      "SELECT s.id,f.field_name FROM study_sessions s JOIN entity_field_clock f ON f.entity_id=s.id AND f.entity_type='study_session' JOIN oplog o ON o.op_id=f.winner_op_id WHERE o.origin_device_id<>s.owner_device_id",
    );
    await empty(
      'segment_owner',
      "SELECT g.id FROM study_session_segments g JOIN study_sessions s ON s.id=g.session_id JOIN entity_field_clock f ON f.entity_id=g.id AND f.entity_type='study_session_segment' JOIN oplog o ON o.op_id=f.winner_op_id WHERE o.origin_device_id<>s.owner_device_id",
    );
    // Independently compare persisted field values against actual business rows;
    // a valid clock pointer alone would miss a stale or corrupt projection value.
    const typeTables = {
      'workspace': 'workspaces',
      'exam_profile': 'exam_profiles',
      'subject': 'subjects',
      'task': 'tasks',
      'daily_review': 'daily_reviews',
      'study_session': 'study_sessions',
      'study_session_segment': 'study_session_segments',
    };
    final materialized = <String, Map<String, dynamic>>{};
    for (final entry in typeTables.entries) {
      for (final row in await rows(entry.value)) {
        materialized['${entry.key}/${row['id']}'] = row;
      }
    }
    for (final field in await rows('entity_field_clock')) {
      final key = '${field['entity_type']}/${field['entity_id']}';
      final row = materialized[key];
      if (row == null) continue; // Pending entities deliberately retain clocks.
      final value = DeterministicCbor.decode(field['value_bytes'] as Uint8List);
      final sqlValue = value is bool ? (value ? 1 : 0) : value;
      if (canonical(row[field['field_name']]) != canonical(sqlValue)) {
        throw StateError(
          '$name field value mismatch $key.${field['field_name']}',
        );
      }
    }
    final log = await rows('oplog');
    final valid = <OperationEnvelope>[];
    for (final row in log) {
      final e = OperationEnvelope.fromBytes(row['envelope_bytes'] as Uint8List);
      final policy = await lookup(workspace, e.originDeviceId);
      if (policy != null &&
          !policy.permits(e.originSeq) &&
          row['apply_state'] != 'pending_authorization' &&
          row['apply_state'] != 'unauthorized_revoked') {
        throw StateError(
          '$name unauthorized op ${e.opId} is ${row['apply_state']}',
        );
      }
      if (![
        'unauthorized_revoked',
        'pending_authorization',
        'pending_schema',
        'invalid_domain',
      ].contains(row['apply_state'])) {
        valid.add(e);
      }
    }
    final versions = await rows('text_field_versions');
    final groups = valid
        .where(
          (e) =>
              e.entityType == 'daily_review' &&
              e.payload is Map &&
              (e.payload as Map).containsKey('content'),
        )
        .toList();
    for (final e in groups) {
      final superseded = groups.any(
        (other) => e.entityId == other.entityId && e.happensBefore(other),
      );
      final active = versions.any((v) => v['op_id'] == e.opId);
      if (active == superseded) {
        throw StateError(
          '$name MV causal maximum mismatch ${e.entityId}/${e.opId}',
        );
      }
    }
  }

  Future<void> close() => db.close();
}

class DeviceCluster {
  DeviceCluster._(this.directory, this.devices);
  final Directory directory;
  final List<TestDevice> devices;
  TestDevice get a => devices[0];
  TestDevice get b => devices[1];
  TestDevice get c => devices[2];
  static Future<DeviceCluster> create({bool cKnowsBProof = true}) async {
    final dir = await Directory.systemTemp.createTemp('yanji-convergence-');
    final devices = <TestDevice>[];
    try {
      for (var i = 0; i < 3; i++) {
        await File('${dir.path}/${String.fromCharCode(97 + i)}.identity.json')
            .writeAsString(
              jsonEncode({'id': deviceId(i), 'seed': List.filled(32, i + 1)}),
            );
        devices.add(await TestDevice.open(i, dir));
      }
      for (final d in devices) {
        for (final peer in devices) {
          await d.db.customStatement(
            'INSERT INTO test_policy_base VALUES (?,?,?)',
            [
              peer.identity.deviceId,
              Uint8List.fromList(peer.identity.publicKey.bytes),
              d.index == 2 && peer.index == 1 && !cKnowsBProof ? 0 : 1,
            ],
          );
        }
      }
      return DeviceCluster._(dir, devices);
    } catch (_) {
      for (final d in devices) {
        await d.close();
      }
      await dir.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> restart(int index) async {
    final old = devices[index];
    final before = canonical({
      'digest': await old.digest(),
      'frontier': await old.frontier(),
      'clock': await old.rows('workspace_clock_state'),
      'context': await old.rows('observed_origins'),
      'pending': await old.pendingState(),
      'snapshot': await old.snapshot(),
    });
    final wall = old.wall,
        applyMicros = old.applyMicros,
        applyCount = old.applyCount;
    await old.close();
    final fresh = await TestDevice.open(index, directory);
    devices[index] = fresh;
    fresh.wall = wall;
    fresh.applyMicros = applyMicros;
    fresh.applyCount = applyCount;
    final after = canonical({
      'digest': await fresh.digest(),
      'frontier': await fresh.frontier(),
      'clock': await fresh.rows('workspace_clock_state'),
      'context': await fresh.rows('observed_origins'),
      'pending': await fresh.pendingState(),
      'snapshot': await fresh.snapshot(),
    });
    if (before != after ||
        identical(old.db, fresh.db) ||
        identical(old.identity, fresh.identity)) {
      throw StateError('restart ${fresh.name} changed persistent state');
    }
  }

  Future<void> assertConverged({bool rebuild = true}) async {
    final expected = await a.snapshot();
    final digest = await a.digest();
    for (final d in devices) {
      final actual = await d.snapshot();
      if (canonical(expected) != canonical(actual)) {
        throw StateError('A/${d.name} ${firstDifference(expected, actual)}');
      }
      if (await d.digest() != digest) {
        throw StateError('A/${d.name} digest mismatch');
      }
      await d.invariantCheck();
    }
    if (rebuild) {
      for (final d in devices) {
        await d.applier.rebuildWorkspace(workspace);
        if (await d.digest() != digest ||
            canonical(await d.snapshot()) != canonical(expected)) {
          throw StateError('${d.name} rebuild changed projection');
        }
        await d.invariantCheck();
      }
    }
  }

  Future<void> close() async {
    for (final d in devices) {
      await d.close();
    }
    await directory.delete(recursive: true);
  }
}

String firstDifference(Object? a, Object? b, [String path = 'tables']) {
  if (a is Map && b is Map) {
    for (final k in {...a.keys, ...b.keys}) {
      if (canonical(a[k]) != canonical(b[k])) {
        return firstDifference(a[k], b[k], '$path.$k');
      }
    }
  } else if (a is List && b is List) {
    if (a.length != b.length) {
      return '$path row count ${a.length} != ${b.length}; A=${canonical(a)} peer=${canonical(b)}';
    }
    for (var i = 0; i < a.length; i++) {
      if (canonical(a[i]) != canonical(b[i])) {
        final row = a[i];
        final entity = row is Map
            ? row['id'] ?? row['entity_id'] ?? row['op_id']
            : i;
        return firstDifference(a[i], b[i], '$path[entity=$entity]');
      }
    }
  }
  return '$path: ${canonical(a)} != ${canonical(b)}';
}
