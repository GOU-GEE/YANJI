import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/clock/hlc.dart';
import 'package:yanji/core/crypto/operation_crypto.dart';
import 'package:yanji/sync/oplog/operation.dart';

import '../support/convergence/device_harness.dart';
import '../support/convergence/simulated_transport.dart';

void main() {
  late DeviceCluster c;
  late SimulatedTransport net;
  late bool warning;
  setUpAll(() {
    warning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = warning;
  });
  setUp(() async {
    c = await DeviceCluster.create();
    net = SimulatedTransport(
      c,
      Random(202609030001),
      ScenarioLog(202609030001),
    );
  });
  tearDown(() async => c.close());

  test('M2 independent file devices, byte-only A → B → C Gossip', () async {
    await c.a.execute('workspace', workspace, 'create', {
      'name': '研迹',
      'stats_timezone': 'Asia/Shanghai',
      'created_at_ms': 1,
      'created_by_device_id': deviceId(0),
    });
    await c.a.execute('subject', baseSubject, 'create', {'name': 'Math'});
    await c.a.execute('task', baseTask, 'create', {
      'title': 'Task',
      'subject_id': baseSubject,
    });
    await net.sync(0, 1);
    await net.deliverAll();
    await net.sync(1, 2);
    await net.deliverAll();
    expect(net.log.actions.where((s) => s.contains('deliver A → C')), isEmpty);
    expect(c.devices.map((d) => d.databasePath).toSet(), hasLength(3));
    expect(c.devices.map((d) => d.identity.deviceId).toSet(), hasLength(3));
    expect(
      c.devices.map((d) => canonical(d.identity.publicKey.bytes)).toSet(),
      hasLength(3),
    );
    await c.assertConverged();
  });
  test(
    'M2 offline edits on all devices survive partition and indirect Gossip',
    () async {
      await initializeCluster(c, net);
      net.fullPartition();
      for (final d in c.devices) {
        await d.execute('task', uid(20 + d.index), 'create', {'title': d.name});
      }
      net.healLink(0, 1);
      net.healLink(1, 2);
      await net.sync(0, 1);
      await net.sync(1, 0);
      await net.deliverAll();
      await net.sync(1, 2);
      await net.sync(2, 1);
      await net.deliverAll();
      await net.converge();
      expect(await c.a.rows('tasks'), hasLength(4));
      await c.assertConverged();
    },
  );
  test(
    'M2 identical operation delivered 1, 2, 10 and 100 times stays idempotent',
    () async {
      await initializeCluster(c, net);
      final op = await c.a.execute('task', baseTask, 'update', {
        'title': 'once',
      });
      await c.b.receive(WirePacket.fromOperation(op), from: 'A');
      final before = await c.b.digest();
      final clock = canonical(await c.b.rows('workspace_clock_state'));
      for (final n in [1, 2, 10, 100]) {
        for (var i = 0; i < n; i++) {
          await c.b.receive(WirePacket.fromOperation(op), from: 'A');
        }
        expect(await c.b.digest(), before);
        expect(canonical(await c.b.rows('workspace_clock_state')), clock);
        expect(
          (await c.b.rows('oplog')).where((r) => r['op_id'] == op.parse().opId),
          hasLength(1),
        );
      }
      await net.converge();
      await c.assertConverged();
    },
  );
  for (final order in [
    [0, 1, 2],
    [0, 2, 1],
    [1, 0, 2],
    [1, 2, 0],
    [2, 0, 1],
    [2, 1, 0],
  ]) {
    test('M2 all create/update permutations $order', () async {
      await initializeCluster(c, net);
      final id = uid(21);
      final ops = [
        await c.a.execute('task', id, 'create', {'title': 'base'}),
        await c.a.execute('task', id, 'update', {'title': 'one'}),
        await c.a.execute('task', id, 'update', {'title': 'two'}),
      ];
      for (final i in order) {
        net.enqueue(0, 1, WirePacket.fromOperation(ops[i]));
        await net.deliverNext(from: 0, to: 1);
        await c.b.invariantCheck();
      }
      for (final i in order.reversed) {
        net.enqueue(0, 2, WirePacket.fromOperation(ops[i]));
        await net.deliverNext(from: 0, to: 2);
      }
      expect(
        (await c.b.rows('tasks')).singleWhere((r) => r['id'] == id)['title'],
        'two',
      );
      await c.assertConverged();
    });
  }
  test(
    'M2 independent fields and concurrent same-field winners/FieldClocks',
    () async {
      await initializeCluster(c, net);
      final a = await c.a.execute('task', baseTask, 'update', {'title': 'A'});
      final b = await c.b.execute('task', baseTask, 'update', {
        'estimated_seconds': 120,
      });
      net.enqueue(0, 2, WirePacket.fromOperation(a));
      net.enqueue(1, 2, WirePacket.fromOperation(b));
      await net.converge();
      expect((await c.c.rows('tasks')).single['title'], 'A');
      expect((await c.c.rows('tasks')).single['estimated_seconds'], 120);
      final pa = await c.a.execute('task', baseTask, 'update', {
        'title': 'A concurrent',
      });
      final pb = await c.b.execute('task', baseTask, 'update', {
        'title': 'B concurrent',
      });
      expect(pa.parse().concurrentWith(pb.parse()), isTrue);
      await c.a.receive(WirePacket.fromOperation(pb), from: 'B');
      await c.b.receive(WirePacket.fromOperation(pa), from: 'A');
      await net.converge();
      await c.assertConverged();
      final expected = pa.parse().compareWinner(pb.parse()) > 0
          ? 'A concurrent'
          : 'B concurrent';
      expect((await c.c.rows('tasks')).single['title'], expected);
    },
  );
  test('M2 causal successor wins across wall-clock rollback; signed lower-HLC fixture', () async {
    await initializeCluster(c, net);
    c.a.wall = 9000000;
    final a = await c.a.execute('task', baseTask, 'update', {'title': 'A1'});
    await c.b.receive(WirePacket.fromOperation(a), from: 'A');
    c.b.wall = 1;
    final b = await c.b.execute('task', baseTask, 'update', {'title': 'B1'});
    expect(a.parse().happensBefore(b.parse()), isTrue);
    expect(b.parse().hlc.wallMs, greaterThanOrEqualTo(a.parse().hlc.wallMs));
    await net.converge();
    expect((await c.c.rows('tasks')).single['title'], 'B1');
    // Honest HLC.receive is monotonic. A signed protocol fixture separately
    // exercises causality precedence over an actually lower envelope HLC.
    final seq = await c.c.nextSeq();
    final e = OperationEnvelope(
      opId: uid(990001),
      workspaceId: workspace,
      originDeviceId: deviceId(2),
      originSeq: seq,
      hlc: Hlc(1, 0),
      causalContext: {deviceId(2): seq - 1, deviceId(1): b.parse().originSeq},
      entityType: 'task',
      entityId: baseTask,
      action: 'update',
      payloadSchemaVersion: 1,
      payload: {'title': 'C causal'},
    );
    final packet = WirePacket.fromOperation(
      await OperationCrypto().sign(e, c.c.identity),
    );
    for (final d in c.devices) {
      await d.receive(packet, from: 'C fixture');
    }
    expect((await c.a.rows('tasks')).single['title'], 'C causal');
    await c.assertConverged();
  });
  test('M2 concurrent MV versions persist over restart, C resolves after observing both', () async {
    await initializeCluster(c, net);
    await c.a.execute('daily_review', reviewId, 'update', {'content': 'A'});
    await c.b.execute('daily_review', reviewId, 'update', {'content': 'B'});
    await net.converge();
    for (final d in c.devices) {
      expect(
        (await d.rows('text_field_versions')).map((r) => r['value']).toSet(),
        {'A', 'B'},
      );
    }
    await c.restart(1);
    await c.assertConverged();
    await c.c.execute('daily_review', reviewId, 'update', {
      'content': 'MERGED',
    });
    await net.converge();
    for (final d in c.devices) {
      expect((await d.rows('text_field_versions')).single['value'], 'MERGED');
    }
    await c.assertConverged();
  });
  test('M2 delete arrives before create/update and deleted dependency closure stays FK-safe', () async {
    await initializeCluster(c, net);
    final id = uid(31), sid = uid(32), seg = uid(33);
    final create = await c.a.execute('task', id, 'create', {
      'title': 'late',
      'subject_id': baseSubject,
    });
    final update = await c.a.execute('task', id, 'update', {'title': 'old'});
    final deletion = await c.a.execute('task', id, 'delete', {});
    for (final op in [deletion, update, create]) {
      await c.b.receive(WirePacket.fromOperation(op), from: 'A');
      await c.b.invariantCheck();
    }
    expect((await c.b.rows('tasks')).where((r) => r['id'] == id), isEmpty);
    final start = await c.a.execute('study_session', sid, 'session.start', {
      'owner_device_id': deviceId(0),
      'subject_id': baseSubject,
      'task_id': baseTask,
      'segment_id': seg,
      'started_at_ms': 1000,
      'mode': 'stopwatch',
    });
    final stop = await c.a.execute('study_session', sid, 'session.stop', {
      'segment_id': seg,
      'ended_at_ms': 2000,
    });
    final taskUpdate = await c.a.execute('task', baseTask, 'update', {
      'title': 'before delete',
    });
    final removeSubject = await c.a.execute(
      'subject',
      baseSubject,
      'delete',
      {},
    );
    for (final op in [removeSubject, stop, taskUpdate, start]) {
      await c.c.receive(WirePacket.fromOperation(op), from: 'A');
      await c.c.invariantCheck();
    }
    await net.converge();
    expect(await c.c.rows('tasks'), isEmpty);
    expect(await c.c.rows('study_sessions'), isEmpty);
    expect(
      (await c.c.rows('materialization_state'))
          .singleWhere((r) => r['entity_id'] == sid)['state'],
      'pending_dependency',
    );
    await c.assertConverged();
  });
  test('M2 missing dependency persists across restart and automatically retries on arrival', () async {
    await initializeCluster(c, net);
    final subject = await c.a.execute('subject', uid(40), 'create', {
      'name': 'late',
    });
    final task = await c.a.execute('task', uid(41), 'create', {
      'title': 'dependent',
      'subject_id': uid(40),
    });
    await c.c.receive(WirePacket.fromOperation(task), from: 'A');
    expect(
      (await c.c.rows('oplog'))
          .singleWhere((r) => r['op_id'] == task.parse().opId)['apply_state'],
      'pending_dependency',
    );
    await c.restart(2);
    await c.c.receive(WirePacket.fromOperation(subject), from: 'A');
    expect(
      (await c.c.rows('tasks')).where((r) => r['id'] == uid(41)),
      hasLength(1),
    );
    await net.converge();
    await c.assertConverged();
  });
  test('M2 timer actions shuffled across three devices; non-owner writes rollback before publication', () async {
    await initializeCluster(c, net);
    final id = uid(50), s1 = uid(51), s2 = uid(52);
    final start = await c.a.execute('study_session', id, 'session.start', {
      'owner_device_id': deviceId(0),
      'subject_id': baseSubject,
      'segment_id': s1,
      'started_at_ms': 1000,
      'mode': 'pomodoro',
    });
    await c.b.receive(WirePacket.fromOperation(start), from: 'A');
    final before = canonical({
      'clock': await c.b.rows('workspace_clock_state'),
      'oplog': await c.b.rows('oplog'),
      'digest': await c.b.digest(),
    });
    for (final action in ['session.pause', 'session.stop']) {
      await expectLater(
        c.b.execute('study_session', id, action, {
          'segment_id': s1,
          'ended_at_ms': 1500,
        }),
        throwsStateError,
      );
      expect(
        canonical({
          'clock': await c.b.rows('workspace_clock_state'),
          'oplog': await c.b.rows('oplog'),
          'digest': await c.b.digest(),
        }),
        before,
      );
    }
    final pause = await c.a.execute('study_session', id, 'session.pause', {
      'segment_id': s1,
      'ended_at_ms': 2000,
    });
    final resume = await c.a.execute('study_session', id, 'session.resume', {
      'segment_id': s2,
      'started_at_ms': 3000,
    });
    final stop = await c.a.execute('study_session', id, 'session.stop', {
      'segment_id': s2,
      'ended_at_ms': 4500,
    });
    for (final target in [1, 2]) {
      final ops = [start, pause, resume, stop]..shuffle(net.random);
      for (final op in ops) {
        await c.devices[target].receive(
          WirePacket.fromOperation(op),
          from: 'A',
        );
        await c.devices[target].invariantCheck();
      }
    }
    await c.restart(0);
    await c.restart(2);
    expect((await c.c.rows('session_durations')).single['duration_ms'], 2500);
    expect((await c.c.rows('study_sessions')).single['status'], 'completed');
    await c.assertConverged();
  });
  test('M2 100-operation gap 41–60 holds frontier at 40 and diff repairs failed attempts', () async {
    await initializeCluster(c, net);
    while (await c.a.nextSeq() <= 100) {
      await c.a.execute('task', baseTask, 'update', {
        'title': 'seq ${await c.a.nextSeq()}',
      });
    }
    for (final p in await c.a.exportAvailableOperations()) {
      if (p.seq <= 40 || p.seq >= 61) net.enqueue(0, 1, p);
    }
    await net.deliverAll();
    expect((await c.b.frontier())['$workspace/${deviceId(0)}'], 40);
    expect(await net.sync(0, 1), 20);
    for (var i = 0; i < 5; i++) {
      net.dropDeliveryAttempt();
    }
    await net.deliverAll();
    await net.converge();
    expect((await c.b.frontier())['$workspace/${deviceId(0)}'], 100);
    expect(await c.a.rows('oplog'), hasLength(100));
    await c.assertConverged();
  });
  test('M2 pending authorization and signed policy Gossip A → B → C triggers automatic retry', () async {
    await c.close();
    c = await DeviceCluster.create(cKnowsBProof: false);
    net = SimulatedTransport(c, Random(31), ScenarioLog(31));
    await initializeCluster(c, net);
    final op = await c.b.execute('task', baseTask, 'update', {
      'title': 'B authorized later',
    });
    await c.c.receive(WirePacket.fromOperation(op), from: 'B');
    expect(
      (await c.c.rows('oplog'))
          .singleWhere((r) => r['op_id'] == op.parse().opId)['apply_state'],
      'pending_authorization',
    );
    expect((await c.c.rows('tasks')).single['title'], 'Initial');
    await c.restart(2);
    final proof = await c.a.policy(deviceId(1));
    net.enqueue(0, 1, proof);
    await net.deliverAll();
    await net.sync(1, 2);
    await net.deliverAll();
    expect((await c.c.rows('tasks')).single['title'], 'B authorized later');
    await net.converge();
    await c.assertConverged();
  });
  test('M2 cutoff 100 removes #101/#102; signed revoke travels via B to C and survives restart', () async {
    await initializeCluster(c, net);
    for (var i = 1; i <= 102; i++) {
      await c.b.execute('task', baseTask, 'update', {'title': 'B#$i'});
    }
    await net.converge();
    expect((await c.c.rows('tasks')).single['title'], 'B#102');
    final revoke = await c.a.policy(deviceId(1), cutoff: 100);
    net.enqueue(0, 1, revoke);
    await net.deliverAll();
    await net.sync(1, 2);
    await net.deliverAll();
    expect((await c.c.rows('tasks')).single['title'], 'B#100');
    for (final d in c.devices) {
      expect(
        (await d.rows('oplog'))
            .where((r) => r['apply_state'] == 'unauthorized_revoked'),
        hasLength(2),
      );
      expect(
        (await d.exportAvailableOperations()).where(
          (p) =>
              p.workspaceId == workspace &&
              p.origin == deviceId(1) &&
              p.seq > 100,
        ),
        isEmpty,
      );
    }
    await c.restart(1);
    await c.restart(2);
    await net.converge();
    await c.assertConverged();
  });
  test('M2 future schema gossips opaquely without changing business digest; tampering quarantined', () async {
    await initializeCluster(c, net);
    final before = await c.a.digest();
    final op = await c.a.futureOperation();
    expect(await c.a.digest(), before);
    await net.sync(0, 1);
    await net.deliverAll();
    await net.sync(1, 2);
    await net.deliverAll();
    for (final d in c.devices) {
      expect(
        (await d.rows('oplog'))
            .singleWhere((r) => r['op_id'] == op.parse().opId)['apply_state'],
        'pending_schema',
      );
      expect(await d.digest(), before);
    }
    // A previously silent origin also cannot change the business digest merely
    // by gaining storage progress and a membership materialization row.
    final futureC = await c.c.futureOperation();
    expect(await c.c.digest(), before);
    await net.converge();
    for (final d in c.devices) {
      expect(await d.digest(), before);
      expect(
        (await d.rows('oplog')).where(
          (r) =>
              r['op_id'] == futureC.parse().opId &&
              r['apply_state'] == 'pending_schema',
        ),
        hasLength(1),
      );
    }
    final bytes = Uint8List.fromList(op.envelopeBytes);
    bytes[bytes.length - 1] ^= 1;
    final bad = WirePacket(
      Operation(envelopeBytes: bytes, signature: op.signature),
      workspace,
      deviceId(0),
      op.parse().originSeq,
    );
    final frontier = canonical(await c.c.frontier()),
        count = (await c.c.rows('oplog')).length;
    await c.c.receive(bad, from: 'untrusted');
    expect(await c.c.rows('sync_quarantine'), hasLength(1));
    expect(await c.c.rows('oplog'), hasLength(count));
    expect(canonical(await c.c.frontier()), frontier);
    expect(await c.c.digest(), before);
    await c.assertConverged();
  });
}
