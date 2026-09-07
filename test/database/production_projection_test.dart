import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/clock/hlc.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/crypto/operation_crypto.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';
import 'package:yanji/sync/operation_pipeline.dart';
import 'package:yanji/sync/oplog/operation.dart';
import 'package:yanji/sync/oplog/operation_journal.dart';

import '../support/identities.dart';

String uid(int i) =>
    '01991f82-0000-7000-8000-${i.toRadixString(16).padLeft(12, '0')}';
final w = uid(1),
    subject = uid(2),
    task = uid(3),
    session = uid(4),
    seg1 = uid(5),
    seg2 = uid(6);
final review = 'daily_review/$w/2026-09-03';

class Rig {
  Rig(this.identity, this.trust, {AppDatabase? database})
    : db = database ?? AppDatabase(NativeDatabase.memory()) {
    apply = OperationApplier(
      db,
      identity,
      lookupOrigin: (w, id) async => trust[id],
      nowMs: () => 1000,
    );
    writer = OperationWriter(apply);
  }
  final DeviceIdentity identity;
  final Map<String, OriginPolicy> trust;
  final AppDatabase db;
  late final OperationApplier apply;
  late final OperationWriter writer;
  Future<Operation> write(
    String type,
    String id,
    String action,
    Map<String, Object?> payload, {
    String? workspace,
  }) => writer.execute(
    BusinessCommand(
      workspaceId: workspace ?? w,
      entityType: type,
      entityId: id,
      action: action,
      payload: payload,
    ),
  );
  Future<List<Map<String, dynamic>>> rows(String table) async =>
      (await db.customSelect('SELECT * FROM $table').get())
          .map((r) => r.data)
          .toList();
  Future<void> receive(Operation p) async {
    final e = p.parse();
    await apply.receive(
      p,
      workspaceId: e.workspaceId,
      originDeviceId: e.originDeviceId,
    );
  }

  Future<void> sendTo(Rig other) async {
    for (final p in await apply.export(w)) {
      await other.receive(p);
    }
  }

  Future<List<Operation>> base() async => [
    await write('workspace', w, 'create', {
      'name': '考研',
      'stats_timezone': 'Asia/Shanghai',
      'created_at_ms': 1,
      'created_by_device_id': identity.deviceId,
    }),
    await write('subject', subject, 'create', {'name': '数学'}),
    await write('task', task, 'create', {
      'title': '初始',
      'estimated_seconds': 90,
      'subject_id': subject,
    }),
  ];
  Future<String> digest() => apply.projectionDigest(w);
}

Future<Operation> signed(
  DeviceIdentity who,
  int seq, {
  String type = 'task',
  String? id,
  String action = 'update',
  Map<String, Object?> payload = const {},
  Map<String, int> context = const {},
  int wall = 5000,
  int schema = 1,
}) => OperationCrypto().sign(
  OperationEnvelope(
    opId: uid(1000 + seq + (who.deviceId == uid(102) ? 10000 : 20000)),
    workspaceId: w,
    originDeviceId: who.deviceId,
    originSeq: seq,
    hlc: Hlc(wall, seq),
    causalContext: {if (seq > 1) who.deviceId: seq - 1, ...context},
    entityType: type,
    entityId: id ?? task,
    action: action,
    payloadSchemaVersion: schema,
    payload: payload,
  ),
  who,
);
void main() {
  late DeviceIdentity ia, ib;
  late Rig a, b;
  late Map<String, OriginPolicy> trust;
  late bool previousWarning;
  setUpAll(() async {
    ia = await testIdentity(uid(101), 1);
    ib = await testIdentity(uid(102), 2);
    // Each rig has its own real SQLite executor, deliberately simulating devices.
    previousWarning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(
    () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = previousWarning,
  );
  setUp(() {
    trust = {
      for (final id in [ia, ib])
        id.deviceId: OriginPolicy(publicKey: id.publicKey, authorized: true),
    };
    a = Rig(ia, trust);
    b = Rig(ib, trust);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test(
    'child subject waits for parent and converges after out-of-order delivery',
    () async {
      final base = await a.base();
      for (final packet in base) {
        await b.receive(packet);
      }
      final parentId = uid(20), childId = uid(21);
      final parent = await a.write('subject', parentId, 'create', {
        'name': '408',
      });
      final child = await a.write('subject', childId, 'create', {
        'name': '数据结构',
        'parent_subject_id': parentId,
      });
      await b.receive(child);
      expect(
        (await b.rows('subjects')).any((row) => row['id'] == childId),
        isFalse,
      );
      await b.receive(parent);
      expect(
        (await b.rows('subjects'))
            .singleWhere((row) => row['id'] == childId)['parent_subject_id'],
        parentId,
      );
      expect(await b.digest(), await a.digest());
      await a.write('subject', parentId, 'delete', {});
      await a.sendTo(b);
      expect(
        (await b.rows('subjects')).any((row) => row['id'] == childId),
        isFalse,
      );
      expect(await b.digest(), await a.digest());
    },
  );

  test('local command commits signed log, typed projection, field clocks and persistent sequence', () async {
    final packets = await a.base();
    expect((await a.rows('tasks')).single['title'], '初始');
    expect((await a.rows('oplog')).length, 3);
    expect(
      (await a.rows('workspace_clock_state')).single['next_origin_seq'],
      4,
    );
    expect(
      (await a.rows('entity_field_clock'))
          .where((r) => r['entity_id'] == task && r['field_name'] == 'title')
          .single['winner_op_id'],
      packets.last.parse().opId,
    );
    expect(await OperationCrypto().verify(packets.last, ia.publicKey), true);
    expect((await a.rows('origin_progress')).single['max_contiguous_seq'], 3);
    await a.write('exam_profile', 'exam_profile/$w/default', 'create', {
      'target_school': '目标院校',
      'exam_date': '2028-12-23',
    });
    expect((await a.rows('exam_profiles')).single['target_school'], '目标院校');
  });
  test('projection insert failure rolls back log, seq, HLC, context and previous rows', () async {
    await a.base();
    final before = await a.digest();
    final clock = await a.rows('workspace_clock_state');
    final context = await a.rows('observed_origins');
    await a.db.customStatement(
      "CREATE TRIGGER test_failure BEFORE INSERT ON tasks BEGIN SELECT RAISE(ABORT,'projection failure'); END",
    );
    await expectLater(
      a.write('task', task, 'update', {'title': 'must rollback'}),
      throwsA(isA<Exception>()),
    );
    expect(await a.digest(), before);
    expect(await a.rows('workspace_clock_state'), clock);
    expect(await a.rows('observed_origins'), context);
    expect(await a.rows('oplog'), hasLength(3));
    await a.db.customStatement('DROP TRIGGER test_failure');
    expect(
      (await a.write('task', task, 'update', {
        'title': 'committed',
      })).parse().originSeq,
      4,
    );
  });
  test(
    'local and remote use identical production resolver and digest',
    () async {
      await a.base();
      await a.sendTo(b);
      expect(await a.digest(), await b.digest());
      final patch = await a.write('task', task, 'update', {'title': '修改'});
      await b.receive(patch);
      expect(await a.digest(), await b.digest());
      expect((await b.rows('tasks')).single['estimated_seconds'], 90);
    },
  );
  test(
    'remote projection failure rolls back received operation and observe state',
    () async {
      final packets = await a.base();
      await b.receive(packets.first);
      final before = await b.digest();
      final clock = await b.rows('workspace_clock_state');
      await b.db.customStatement(
        "CREATE TRIGGER test_failure BEFORE INSERT ON subjects BEGIN SELECT RAISE(ABORT,'remote projection failure'); END",
      );
      await expectLater(b.receive(packets[1]), throwsA(isA<Exception>()));
      expect(await b.digest(), before);
      expect(await b.rows('oplog'), hasLength(1));
      expect(await b.rows('workspace_clock_state'), clock);
    },
  );
  test('update before create stores field state without a half row then materializes newer values', () async {
    final packets = await a.base();
    final update = await a.write('task', task, 'update', {'title': '更新'});
    await b.receive(packets[0]);
    await b.receive(packets[1]);
    await b.receive(update);
    expect(await b.rows('tasks'), isEmpty);
    expect(
      (await b.rows('materialization_state'))
          .where((r) => r['entity_id'] == task)
          .single['state'],
      'pending_create',
    );
    expect(
      (await b.rows('entity_field_clock')).where((r) => r['entity_id'] == task),
      isNotEmpty,
    );
    await b.receive(packets[2]);
    expect((await b.rows('tasks')).single['title'], '更新');
    expect(await a.digest(), await b.digest());
  });
  test('a late required field completes a partial remote create without weakening NOT NULL', () async {
    final base = await a.base();
    await b.receive(base.first);
    await b.receive(
      await signed(
        ia,
        10,
        type: 'subject',
        id: subject,
        action: 'create',
        payload: {'sort_order': 2},
      ),
    );
    expect(await b.rows('subjects'), isEmpty);
    await b.receive(
      await signed(
        ia,
        11,
        type: 'subject',
        id: subject,
        payload: {'name': '数学'},
      ),
    );
    expect((await b.rows('subjects')).single['name'], '数学');
    await expectLater(
      b.db.customStatement(
        'INSERT INTO subjects (id,workspace_id) VALUES (?,?)',
        [uid(700), w],
      ),
      throwsA(isA<Exception>()),
    );
  });
  test('session-before-subject automatically retries and cross-workspace FK is guarded', () async {
    final packets = await a.base();
    final start = await a.write('study_session', session, 'session.start', {
      'owner_device_id': ia.deviceId,
      'subject_id': subject,
      'started_at_ms': 1000,
      'segment_id': seg1,
      'mode': 'stopwatch',
    });
    await b.receive(packets[0]);
    await b.receive(start);
    expect(await b.rows('study_sessions'), isEmpty);
    expect(
      (await b.rows('materialization_state'))
          .where((r) => r['entity_id'] == session)
          .single['state'],
      'pending_dependency',
    );
    await b.receive(packets[1]);
    expect((await b.rows('study_sessions')).single['status'], 'active');
    final w2 = uid(9);
    await b.write('workspace', w2, 'create', {
      'name': '另一个',
      'stats_timezone': 'Asia/Tokyo',
      'created_at_ms': 1,
      'created_by_device_id': ib.deviceId,
    }, workspace: w2);
    await expectLater(
      b.write('task', uid(8), 'create', {
        'title': 'wrong workspace',
        'subject_id': subject,
      }, workspace: w2),
      throwsStateError,
    );
  });
  test('concurrent different fields merge and same field winner is order-independent', () async {
    await a.base();
    await a.sendTo(b);
    final pa = await a.write('task', task, 'update', {'title': 'A'}),
        pb = await b.write('task', task, 'update', {'estimated_seconds': 120});
    await a.receive(pb);
    await b.receive(pa);
    expect((await a.rows('tasks')).single['title'], 'A');
    expect((await a.rows('tasks')).single['estimated_seconds'], 120);
    expect(await a.digest(), await b.digest());
    final ca = await a.write('task', task, 'update', {'title': '并发A'}),
        cb = await b.write('task', task, 'update', {'title': '并发B'});
    await a.receive(cb);
    await b.receive(ca);
    expect(await a.digest(), await b.digest());
  });
  test('causally newer field wins even when its HLC is lower', () async {
    final packets = await a.base();
    await a.receive(
      await signed(
        ib,
        1,
        payload: {'title': 'causal'},
        context: {ia.deviceId: packets.last.parse().originSeq},
        wall: 1,
      ),
    );
    expect((await a.rows('tasks')).single['title'], 'causal');
  });
  test('MV register persists both concurrent versions then resolves through observed operation', () async {
    await a.base();
    await a.sendTo(b);
    final pa = await a.write('daily_review', review, 'create', {
          'review_date': '2026-09-03',
          'content': '版本A',
        }),
        pb = await b.write('daily_review', review, 'create', {
          'review_date': '2026-09-03',
          'content': '版本B',
        });
    await a.receive(pb);
    await b.receive(pa);
    expect(await a.rows('text_field_versions'), hasLength(2));
    expect(await a.digest(), await b.digest());
    final merged = await a.write('daily_review', review, 'update', {
      'content': '合并',
    });
    await b.receive(merged);
    expect(await a.rows('text_field_versions'), hasLength(1));
    expect(
      (await a.rows('text_field_versions')).single['op_id'],
      merged.parse().opId,
    );
    expect(await a.digest(), await b.digest());
    await a.write('daily_review', review, 'update', {'content': ''});
    await a.write('daily_review', review, 'update', {'content': '再次填写'});
    expect((await a.rows('daily_reviews')).single['content'], '再次填写');
    await expectLater(
      a.write('daily_review', review, 'delete', {}),
      throwsFormatException,
    );
    expect(await a.rows('tombstones'), isEmpty);
  });
  test('delete before create and late updates cannot resurrect; dependent rows become pending', () async {
    final packets = await a.base();
    final deletion = await a.write('task', task, 'delete', {});
    await b.receive(packets[0]);
    await b.receive(packets[1]);
    await b.receive(deletion);
    await b.receive(packets[2]);
    final stale = await signed(
      ib,
      1,
      payload: {'title': 'zombie'},
      wall: 90000,
    );
    await b.receive(stale);
    await a.receive(stale);
    expect(await b.rows('tasks'), isEmpty);
    expect(await b.rows('tombstones'), hasLength(1));
    expect(await a.digest(), await b.digest());
    final dep = uid(7);
    await a.write('task', dep, 'create', {
      'title': '依赖',
      'subject_id': subject,
    });
    await a.write('subject', subject, 'delete', {});
    expect(await a.rows('tasks'), isEmpty);
    expect(
      (await a.rows('materialization_state'))
          .where((r) => r['entity_id'] == dep)
          .single['state'],
      'pending_dependency',
    );
  });
  test('revocation cutoff recomputes real rows and field clocks, preserving signed history', () async {
    final packets = await a.base();
    final later = await signed(
      ib,
      101,
      payload: {'title': 'revoked'},
      context: {ia.deviceId: 3},
      wall: 90000,
    );
    await a.receive(later);
    expect((await a.rows('tasks')).single['title'], 'revoked');
    trust[ib.deviceId] = OriginPolicy(
      publicKey: ib.publicKey,
      authorized: true,
      cutoff: 100,
    );
    await a.apply.refreshAuthorization(w);
    expect((await a.rows('tasks')).single['title'], '初始');
    expect(
      (await a.rows('entity_field_clock'))
          .where((r) => r['entity_id'] == task && r['field_name'] == 'title')
          .single['winner_op_id'],
      packets.last.parse().opId,
    );
    expect(
      (await a.rows('oplog'))
          .where((r) => r['op_id'] == later.parse().opId)
          .single['apply_state'],
      'unauthorized_revoked',
    );
  });
  test('rebuild entity/workspace restores cleared derived state with identical digest', () async {
    await a.base();
    await a.write('daily_review', review, 'create', {
      'review_date': '2026-09-03',
      'content': '正文',
    });
    final before = await a.digest();
    final log = await a.rows('oplog');
    final clock = await a.rows('workspace_clock_state');
    await a.db.customStatement('DELETE FROM tasks');
    await a.db.customStatement('DELETE FROM entity_field_clock');
    await a.db.customStatement('DELETE FROM text_field_versions');
    await a.apply.rebuildEntity(w, 'task', task);
    expect(await a.digest(), before);
    await a.apply.rebuildWorkspace(w);
    expect(await a.digest(), before);
    expect(await a.rows('oplog'), log);
    expect(await a.rows('workspace_clock_state'), clock);
  });
  test('atomic timer owner actions and out-of-order delivery never produce completed with open segment', () async {
    final base = await a.base();
    final start = await a.write('study_session', session, 'session.start', {
      'owner_device_id': ia.deviceId,
      'subject_id': subject,
      'task_id': task,
      'started_at_ms': 1000,
      'segment_id': seg1,
      'mode': 'stopwatch',
    });
    final pause = await a.write('study_session', session, 'session.pause', {
      'segment_id': seg1,
      'ended_at_ms': 2000,
    });
    final resume = await a.write('study_session', session, 'session.resume', {
      'segment_id': seg2,
      'started_at_ms': 3000,
    });
    final stop = await a.write('study_session', session, 'session.stop', {
      'segment_id': seg2,
      'ended_at_ms': 4000,
    });
    for (final packet in [stop, resume, ...base.reversed, start, pause]) {
      await b.receive(packet);
      final invalid = await b.db
          .customSelect(
            "SELECT s.id FROM study_sessions s JOIN study_session_segments g ON g.session_id=s.id WHERE s.status='completed' AND g.ended_at_ms IS NULL",
          )
          .get();
      expect(invalid, isEmpty);
    }
    expect((await b.rows('study_sessions')).single['status'], 'completed');
    expect((await b.rows('session_durations')).single['duration_ms'], 2000);
    expect(await a.digest(), await b.digest());
    await expectLater(
      b.write('study_session', session, 'session.pause', {
        'segment_id': seg2,
        'ended_at_ms': 5000,
      }),
      throwsStateError,
    );
    await a.receive(
      await signed(
        ib,
        1,
        type: 'study_session',
        id: session,
        action: 'session.stop',
        payload: {'segment_id': seg2, 'ended_at_ms': 6000},
      ),
    );
    expect((await a.rows('study_sessions')).single['ended_at_ms'], 4000);
    expect(
      (await a.rows('oplog'))
          .where((r) => r['origin_device_id'] == ib.deviceId)
          .single['apply_state'],
      'invalid_domain',
    );
  });
  test('local writes cannot report success for a tombstoned target', () async {
    await a.base();
    await a.write('task', task, 'delete', {});
    final count = (await a.rows('oplog')).length;
    await expectLater(
      a.write('task', task, 'update', {'title': 'cannot revive'}),
      throwsStateError,
    );
    await expectLater(
      a.write('task', task, 'create', {'title': 'cannot recreate'}),
      throwsStateError,
    );
    expect(await a.rows('oplog'), hasLength(count));
    expect(await a.rows('tasks'), isEmpty);
  });
  test(
    'explicit null clears one nullable field without replacing the patch row',
    () async {
      await a.base();
      await a.write('task', task, 'update', {'subject_id': null});
      final row = (await a.rows('tasks')).single;
      expect(row['subject_id'], isNull);
      expect(row['title'], '初始');
      expect(row['estimated_seconds'], 90);
    },
  );
  test('paused stop completes the closed segment atomically', () async {
    await a.base();
    await a.write('study_session', session, 'session.start', {
      'owner_device_id': ia.deviceId,
      'subject_id': subject,
      'started_at_ms': 1000,
      'segment_id': seg1,
      'mode': 'pomodoro',
    });
    await a.write('study_session', session, 'session.pause', {
      'segment_id': seg1,
      'ended_at_ms': 2000,
    });
    await a.write('study_session', session, 'session.stop', {
      'segment_id': seg1,
      'ended_at_ms': 2000,
    });
    expect((await a.rows('study_sessions')).single['status'], 'completed');
    expect((await a.rows('session_durations')).single['duration_ms'], 1000);
  });
  test(
    'file reopen preserves production rows and deterministic rebuild',
    () async {
      final dir = await Directory.systemTemp.createTemp('yanji-production-');
      final file = File('${dir.path}/device.sqlite');
      var disk = Rig(ia, trust, database: AppDatabase(openDatabaseFile(file)));
      try {
        await disk.base();
        await disk.write('daily_review', review, 'create', {
          'review_date': '2026-09-03',
          'content': '持久正文',
        });
        final digest = await disk.digest();
        await disk.db.close();
        disk = Rig(ia, trust, database: AppDatabase(openDatabaseFile(file)));
        expect(await disk.digest(), digest);
        await disk.apply.rebuildWorkspace(w);
        expect(await disk.digest(), digest);
        expect(
          await disk.db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      } finally {
        await disk.db.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test('malformed domain payload is quarantined and unknown schema remains pending without apply', () async {
    await a.base();
    final before = await a.digest();
    await a.receive(await signed(ib, 1, payload: {'estimated_seconds': -2}));
    expect(await a.rows('oplog'), hasLength(3));
    expect(await a.rows('sync_quarantine'), hasLength(1));
    expect(await a.digest(), before);
    final future = await signed(
      ib,
      2,
      schema: 99,
      payload: {'new_field': true},
    );
    await a.receive(future);
    expect(
      (await a.rows('oplog'))
          .where((r) => r['op_id'] == future.parse().opId)
          .single['apply_state'],
      'pending_schema',
    );
    expect((await a.rows('tasks')).single['title'], '初始');
  });
}
