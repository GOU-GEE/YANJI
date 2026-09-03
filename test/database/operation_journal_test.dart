import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/crypto/operation_crypto.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';
import 'package:yanji/sync/oplog/operation.dart';
import 'package:yanji/sync/oplog/operation_journal.dart';
import 'package:yanji/core/clock/hlc.dart';

import '../support/identities.dart';

Future<Operation> remote(
  DeviceIdentity id, {
  int seq = 1,
  int wall = 5000,
  String workspace = 'w',
  int schema = 1,
  String? opId,
}) => OperationCrypto().sign(
  OperationEnvelope(
    opId: opId ?? '${id.deviceId}-$seq',
    workspaceId: workspace,
    originDeviceId: id.deviceId,
    originSeq: seq,
    hlc: Hlc(wall, 0),
    causalContext: {if (seq > 1) id.deviceId: seq - 1},
    entityType: 'task',
    entityId: 't',
    action: 'create',
    payloadSchemaVersion: schema,
    payload: {'title': 'remote'},
  ),
  id,
);

void main() {
  late DeviceIdentity a, b;
  setUpAll(() async {
    a = await testIdentity('a', 1);
    b = await testIdentity('b', 2);
  });
  group('journal', () {
    late AppDatabase db;
    late OperationJournal journal;
    late Map<String, OriginPolicy> trust;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      trust = {
        for (final id in [a, b])
          id.deviceId: OriginPolicy(publicKey: id.publicKey, authorized: true),
      };
      journal = OperationJournal(
        db,
        a,
        lookupOrigin: (w, id) async => trust[id],
        nowMs: () => 1000,
      );
    });
    tearDown(() => db.close());
    Future<Operation> append(String w) => journal.append(
      workspaceId: w,
      entityType: 'task',
      entityId: 't',
      action: 'create',
      payload: {'title': 'local'},
    );

    test('interleaved workspaces and concurrent commands allocate independent continuous sequences', () async {
      final packets = await Future.wait([
        for (var i = 0; i < 10; i++) append(i.isEven ? 'w1' : 'w2'),
      ]);
      for (final w in ['w1', 'w2']) {
        expect(
          packets
              .map((p) => p.parse())
              .where((e) => e.workspaceId == w)
              .map((e) => e.originSeq)
              .toList()
            ..sort(),
          [1, 2, 3, 4, 5],
        );
        expect(await journal.frontier(w), {'a': 5});
      }
    });
    test(
      'outer rollback does not consume seq, log, clock or context',
      () async {
        await append('w');
        final before =
            (await db
                    .customSelect('SELECT * FROM workspace_clock_state')
                    .getSingle())
                .data;
        await expectLater(
          db.transaction(() async {
            await append('w');
            throw StateError('injected failure');
          }),
          throwsStateError,
        );
        expect(
          (await db
                  .customSelect('SELECT * FROM workspace_clock_state')
                  .getSingle())
              .data,
          before,
        );
        expect((await journal.export('w')).length, 1);
        expect(await journal.context('w'), {'a': 1});
        expect((await append('w')).parse().originSeq, 2);
      },
    );
    test(
      'remote observe persists and next local operation is causally later',
      () async {
        final packet = await remote(b, wall: 90000);
        expect(
          await journal.receive(packet, workspaceId: 'w', originDeviceId: 'b'),
          ReceiveResult.stored,
        );
        final local = (await append('w')).parse();
        expect(local.hlc.compareTo(packet.parse().hlc), greaterThan(0));
        expect(packet.parse().happensBefore(local), true);
        expect(local.originSeq, 1);
        expect(local.causalContext['b'], 1);
      },
    );
    test(
      'duplicate 100 deliveries are no-op; frontier never jumps over holes',
      () async {
        final one = await remote(b), three = await remote(b, seq: 3);
        await journal.receive(one, workspaceId: 'w', originDeviceId: 'b');
        await journal.receive(three, workspaceId: 'w', originDeviceId: 'b');
        final clock =
            (await db
                    .customSelect('SELECT * FROM workspace_clock_state')
                    .getSingle())
                .data;
        for (var i = 0; i < 100; i++) {
          expect(
            await journal.receive(three, workspaceId: 'w', originDeviceId: 'b'),
            ReceiveResult.duplicate,
          );
        }
        expect(
          (await db
                  .customSelect('SELECT * FROM workspace_clock_state')
                  .getSingle())
              .data,
          clock,
        );
        expect(await journal.frontier('w'), {'b': 1});
        await journal.receive(
          await remote(b, seq: 2),
          workspaceId: 'w',
          originDeviceId: 'b',
        );
        expect(await journal.frontier('w'), {'b': 3});
      },
    );
    test(
      'unknown schema retains signed bytes and can be forwarded without apply',
      () async {
        final packet = await remote(b, schema: 99);
        await journal.receive(packet, workspaceId: 'w', originDeviceId: 'b');
        final row = await db.customSelect('SELECT * FROM oplog').getSingle();
        expect(row.read<String>('apply_state'), 'pending_schema');
        final forwarded = (await journal.export('w')).single;
        expect(forwarded.envelopeBytes, packet.envelopeBytes);
        expect(forwarded.signature, packet.signature);
        expect(await OperationCrypto().verify(forwarded, b.publicKey), true);
      },
    );
    test('bad signature and signed malformed CBOR are quarantined without advancing clocks', () async {
      final good = await remote(b);
      final bad = Operation(
        envelopeBytes: Uint8List.fromList(good.envelopeBytes)..[0] ^= 1,
        signature: good.signature,
      );
      expect(
        await journal.receive(bad, workspaceId: 'w', originDeviceId: 'b'),
        ReceiveResult.rejected,
      );
      final malformed = Uint8List.fromList([0xff]);
      final signed = await b.sign(malformed);
      expect(
        await journal.receive(
          Operation(
            envelopeBytes: malformed,
            signature: Uint8List.fromList(signed.bytes),
          ),
          workspaceId: 'w',
          originDeviceId: 'b',
        ),
        ReceiveResult.rejected,
      );
      expect(await journal.export('w'), isEmpty);
      expect(
        await db.customSelect('SELECT * FROM workspace_clock_state').get(),
        isEmpty,
      );
      expect(
        await db.customSelect('SELECT * FROM sync_quarantine').get(),
        hasLength(2),
      );
    });
    test('same dot with different signed content is rejected', () async {
      await journal.receive(
        await remote(b),
        workspaceId: 'w',
        originDeviceId: 'b',
      );
      expect(
        await journal.receive(
          await remote(b, opId: 'collision'),
          workspaceId: 'w',
          originDeviceId: 'b',
        ),
        ReceiveResult.rejected,
      );
      expect(await journal.export('w'), hasLength(1));
    });
    test('late membership proof retries pending operation without premature observation', () async {
      trust['b'] = OriginPolicy(publicKey: b.publicKey, authorized: false);
      final packet = await remote(b);
      expect(
        await journal.receive(packet, workspaceId: 'w', originDeviceId: 'b'),
        ReceiveResult.pendingAuthorization,
      );
      expect(await journal.context('w'), isEmpty);
      trust['b'] = OriginPolicy(publicKey: b.publicKey, authorized: true);
      await journal.refreshAuthorization('w');
      expect(await journal.context('w'), {'b': 1});
      expect(
        (await db.customSelect('SELECT * FROM oplog').getSingle()).read<String>(
          'apply_state',
        ),
        'pending_entity_create',
      );
    });
    test('late cutoff invalidates stored history and stops gossip without clock rollback', () async {
      await journal.receive(
        await remote(b),
        workspaceId: 'w',
        originDeviceId: 'b',
      );
      await journal.receive(
        await remote(b, seq: 2, wall: 90000),
        workspaceId: 'w',
        originDeviceId: 'b',
      );
      final clock =
          (await db
                  .customSelect('SELECT * FROM workspace_clock_state')
                  .getSingle())
              .data;
      trust['b'] = OriginPolicy(
        publicKey: b.publicKey,
        authorized: true,
        cutoff: 1,
      );
      await journal.refreshAuthorization('w');
      final rows = await db
          .customSelect('SELECT * FROM oplog ORDER BY origin_seq')
          .get();
      expect(rows.last.read<String>('apply_state'), 'unauthorized_revoked');
      expect(rows, hasLength(2));
      expect(await journal.export('w'), hasLength(1));
      expect(
        (await db
                .customSelect('SELECT * FROM workspace_clock_state')
                .getSingle())
            .data,
        clock,
      );
      trust['b'] = OriginPolicy(
        publicKey: b.publicKey,
        authorized: true,
        cutoff: 20,
      );
      await journal.refreshAuthorization('w');
      expect(await journal.export('w'), hasLength(1));
    });

    test(
      'cutoff rejects later history and local writes from revoked origins',
      () async {
        trust['b'] = OriginPolicy(
          publicKey: b.publicKey,
          authorized: true,
          cutoff: 1,
        );
        expect(
          await journal.receive(
            await remote(b),
            workspaceId: 'w',
            originDeviceId: 'b',
          ),
          ReceiveResult.stored,
        );
        expect(
          await journal.receive(
            await remote(b, seq: 2),
            workspaceId: 'w',
            originDeviceId: 'b',
          ),
          ReceiveResult.rejected,
        );
        expect(await journal.context('w'), {'b': 1});
        trust['a'] = OriginPolicy(
          publicKey: a.publicKey,
          authorized: true,
          cutoff: 0,
        );
        await expectLater(append('w'), throwsStateError);
      },
    );
  });

  test(
    'reopening file database preserves HLC/seq through clock rollback',
    () async {
      final dir = await Directory.systemTemp.createTemp('yanji-journal-');
      final file = File('${dir.path}/yanji.sqlite');
      var db = AppDatabase(openDatabaseFile(file));
      Future<OriginPolicy?> lookup(String w, String id) async => OriginPolicy(
        publicKey: id == 'a' ? a.publicKey : b.publicKey,
        authorized: true,
      );
      try {
        var journal = OperationJournal(
          db,
          a,
          lookupOrigin: lookup,
          nowMs: () => 1000,
        );
        final first = await journal.append(
          workspaceId: 'w',
          entityType: 'task',
          entityId: 't',
          action: 'create',
          payload: {'title': 'first'},
        );
        await journal.receive(
          await remote(b, wall: 90000),
          workspaceId: 'w',
          originDeviceId: 'b',
        );
        await db.close();
        db = AppDatabase(openDatabaseFile(file));
        journal = OperationJournal(db, a, lookupOrigin: lookup, nowMs: () => 1);
        final second = await journal.append(
          workspaceId: 'w',
          entityType: 'task',
          entityId: 't',
          action: 'update',
          payload: {'title': 'second'},
        );
        expect(second.parse().originSeq, first.parse().originSeq + 1);
        expect(second.parse().hlc.wallMs, 90000);
        expect(second.parse().hlc.counter, greaterThan(0));
        expect(second.parse().causalContext, {'a': 1, 'b': 1});
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
