import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';
import 'package:yanji/sync/operation_pipeline.dart';

import '../support/identities.dart';

void main() {
  test('timezone midnight split, pause exclusion, persisted review and timer after reopen', () async {
    final dir = await Directory.systemTemp.createTemp('yanji-ui-');
    final identity = await testIdentity(
      '01991f82-0000-7000-8000-000000000101',
      1,
    );
    var now = DateTime.utc(2026, 9, 3, 15, 50);
    var db = AppDatabase(openDatabaseFile(File('${dir.path}/app.sqlite')));
    var app = await StudyAppController.open(db, identity, now: () => now);
    await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
    await app.startStudy(app.subjects.single.id);
    now = DateTime.utc(2026, 9, 3, 16, 10);
    await app.pauseStudy();
    now = DateTime.utc(2026, 9, 3, 16, 20);
    await app.resumeStudy();
    await app.saveReview('2026-09-04', '保留正文');
    final digest = await app.applier.projectionDigest(app.workspace!.id);
    app.dispose();
    await db.close();
    db = AppDatabase(openDatabaseFile(File('${dir.path}/app.sqlite')));
    app = await StudyAppController.open(db, identity, now: () => now);
    expect(await app.applier.projectionDigest(app.workspace!.id), digest);
    expect(app.runningSession?.status, 'active');
    expect(app.review('2026-09-04')?.content, '保留正文');
    now = DateTime.utc(2026, 9, 3, 16, 50);
    await app.stopStudy();
    expect(app.dayDuration(DateTime(2026, 9, 3)), 10 * 60000);
    expect(app.dayDuration(DateTime(2026, 9, 4)), 40 * 60000);
    expect(app.totalDuration, 50 * 60000);
    expect(app.streak, 2);
    await app.saveReview('2026-09-04', '');
    expect(app.review('2026-09-04')?.content, '');
    expect(await db.select(db.tombstones).get(), isEmpty);
    app.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });
  test(
    'statistics use timezone civil day across DST rather than fixed 24 hours',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      var now = DateTime.utc(2026, 3, 8, 4, 30);
      final app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
        now: () => now,
      );
      await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
      await app.writer.execute(
        BusinessCommand(
          workspaceId: app.workspace!.id,
          entityType: 'workspace',
          entityId: app.workspace!.id,
          action: 'update',
          payload: {'stats_timezone': 'America/New_York'},
        ),
      );
      await app.refresh();
      await app.startStudy(app.subjects.single.id);
      now = DateTime.utc(2026, 3, 9, 4, 30);
      await app.stopStudy();
      expect(app.dayDuration(DateTime(2026, 3, 7)), 30 * 60000);
      expect(app.dayDuration(DateTime(2026, 3, 8)), 23 * 3600000);
      expect(app.dayDuration(DateTime(2026, 3, 9)), 30 * 60000);
      app.dispose();
      await db.close();
    },
  );
  test(
    'onboarding failure rolls back the entire multi-command setup',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      );
      await db.customStatement(
        "CREATE TRIGGER fail_subject BEFORE INSERT ON subjects BEGIN SELECT RAISE(ABORT,'test'); END",
      );
      await expectLater(
        app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']),
        throwsA(isA<Exception>()),
      );
      expect(await db.select(db.workspaces).get(), isEmpty);
      expect(await db.select(db.oplog).get(), isEmpty);
      expect(app.isReady, isFalse);
      app.dispose();
      await db.close();
    },
  );
  test(
    'a replaced local identity cannot silently authorize an existing workspace',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      );
      await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
      final before = await db.select(db.oplog).get();
      app.dispose();
      await expectLater(
        StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000102', 2),
        ),
        throwsStateError,
      );
      expect(await db.select(db.oplog).get(), before);
      await db.close();
    },
  );
}
