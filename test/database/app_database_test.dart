import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';

// Synthetic envelopes are only database fixtures, not verified operations.
Future<void> insertFixture(
  AppDatabase db, {
  String id = 'op-1',
  int seq = 1,
  int schema = 1,
  bool replace = false,
}) => db.customStatement(
  '''
  INSERT ${replace ? 'OR REPLACE' : ''} INTO oplog
  (op_id, workspace_id, origin_device_id, origin_seq, hlc_wall_ms,
   hlc_counter, entity_type, entity_id, action, envelope_bytes, payload_schema_version, signature, wire_version, apply_state)
  VALUES (?, 'workspace', 'device', ?, 1000, 0, 'task', 'task-1', 'create', ?, ?, ?, 1, ?)
''',
  [
    id,
    seq,
    Uint8List.fromList([1, 2, 3]),
    schema,
    Uint8List(64),
    schema > 1 ? 'pending_schema' : 'pending_entity_create',
  ],
);

void main() {
  group('in-memory database', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('fresh schema and FK settings are initialized', () async {
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle())
            .data
            .values
            .single,
        3,
      );
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle())
            .data
            .values
            .single,
        1,
      );
      final triggers = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger'")
          .get();
      expect(triggers.map((row) => row.read<String>('name')).toSet(), {
        'oplog_immutable',
        'oplog_no_delete',
        'oplog_no_replace',
      });
    });

    test(
      'signed columns, DELETE and REPLACE cannot mutate a stored operation',
      () async {
        await insertFixture(db);
        for (final sql in [
          "UPDATE oplog SET envelope_bytes = X'04'",
          "UPDATE oplog SET origin_seq = 2",
          "UPDATE oplog SET signature = zeroblob(64)",
          'DELETE FROM oplog',
        ]) {
          await expectLater(db.customStatement(sql), throwsA(isA<Exception>()));
        }
        await expectLater(
          insertFixture(db, replace: true),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          insertFixture(db, id: 'new-id', replace: true),
          throwsA(isA<Exception>()),
        );
        final row = await db.customSelect('SELECT * FROM oplog').getSingle();
        expect(row.read<String>('op_id'), 'op-1');
        expect(row.read<Uint8List>('envelope_bytes'), [1, 2, 3]);
      },
    );

    test(
      'delivery metadata can change without changing signed content',
      () async {
        await insertFixture(db);
        await db.customStatement(
          "UPDATE oplog SET apply_state = 'applied', received_from_device_id = 'peer', received_at_ms = 2000",
        );
        final row = await db.customSelect('SELECT * FROM oplog').getSingle();
        expect(row.read<String>('apply_state'), 'applied');
        expect(row.read<Uint8List>('envelope_bytes'), [1, 2, 3]);
      },
    );

    test('duplicate identities and invalid sequences are rejected', () async {
      await insertFixture(db);
      await expectLater(insertFixture(db), throwsA(isA<Exception>()));
      await expectLater(
        insertFixture(db, id: 'op-2'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        insertFixture(db, id: 'op-2', seq: 0),
        throwsA(isA<Exception>()),
      );
      expect(await db.customSelect('SELECT * FROM oplog').get(), hasLength(1));
    });

    test('transaction failure rolls back all inserted operations', () async {
      await expectLater(
        db.transaction(() async {
          await insertFixture(db);
          await insertFixture(db, id: 'op-2', seq: 2);
          throw StateError('simulated failure');
        }),
        throwsStateError,
      );
      expect(await db.customSelect('SELECT * FROM oplog').get(), isEmpty);
      await insertFixture(db); // No identity was consumed by the failed commit.
    });

    test('unknown schema envelope is retained and left unapplied', () async {
      await insertFixture(db, schema: 99);
      final row = await db.customSelect('SELECT * FROM oplog').getSingle();
      expect(row.read<int>('payload_schema_version'), 99);
      expect(row.read<String>('apply_state'), 'pending_schema');
    });
  });

  test(
    'file database uses WAL and retains committed bytes after reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp('yanji-db-test-');
      final file = File('${directory.path}/yanji.sqlite');
      var disk = AppDatabase(openDatabaseFile(file));
      try {
        await insertFixture(disk);
        expect(
          (await disk.customSelect('PRAGMA journal_mode').getSingle())
              .data
              .values
              .single,
          'wal',
        );
        expect(
          (await disk.customSelect('PRAGMA synchronous').getSingle())
              .data
              .values
              .single,
          2,
        );
        await disk.close();
        disk = AppDatabase(openDatabaseFile(file));
        expect(
          await disk.customSelect('SELECT * FROM oplog').get(),
          hasLength(1),
        );
        await expectLater(
          disk.customStatement('DELETE FROM oplog'),
          throwsA(isA<Exception>()),
        );
      } finally {
        await disk.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
