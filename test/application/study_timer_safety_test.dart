import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';

import '../support/identities.dart';

void main() {
  test(
    'heartbeat saves every 30 seconds and lifecycle saves immediately',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      var now = DateTime.utc(2026, 10, 1);
      final app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
        now: () => now,
      );
      Future<int> checkpointTime() async =>
          (await db.select(db.localStudyCheckpoints).getSingle()).observedAtMs;
      try {
        await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
        await app.startStudy(app.subjects.single.id);
        final initialTime = await checkpointTime();
        for (var second = 1; second < 30; second++) {
          now = now.add(const Duration(seconds: 1));
          await app.tickTaskProgress();
          expect(await checkpointTime(), initialTime);
        }
        now = now.add(const Duration(seconds: 1));
        await app.tickTaskProgress();
        expect(await checkpointTime(), now.millisecondsSinceEpoch);
        now = now.add(const Duration(seconds: 5));
        await app.checkpointStudyProgress();
        expect(await checkpointTime(), now.millisecondsSinceEpoch);
        now = now.add(const Duration(seconds: 29));
        await app.tickTaskProgress();
        expect(
          await checkpointTime(),
          now.subtract(const Duration(seconds: 29)).millisecondsSinceEpoch,
        );
        await app.stopStudy();
        await app.tickTaskProgress();
        expect(await db.select(db.localStudyCheckpoints).get(), isEmpty);
      } finally {
        app.dispose();
        await db.close();
      }
    },
  );

  test(
    'process restart closes at persisted checkpoint, never counts downtime',
    () async {
      final directory = await Directory.systemTemp.createTemp('yanji-timer-');
      final file = File('${directory.path}/app.sqlite');
      final identity = await testIdentity(
        '01991f82-0000-7000-8000-000000000101',
        1,
      );
      var now = DateTime.utc(2026, 10, 1);
      var db = AppDatabase(openDatabaseFile(file));
      var app = await StudyAppController.open(db, identity, now: () => now);
      try {
        await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
        await app.saveTask(
          title: '数学复习',
          subjectId: app.subjects.single.id,
          date: app.today,
          estimatedSeconds: 3600,
        );
        final taskId = app.tasks.single.id;
        await app.startStudy(app.subjects.single.id, taskId: taskId);
        now = now.add(const Duration(minutes: 20));
        await app.checkpointStudyProgress();
        app.dispose();
        await db.close();
        now = now.add(const Duration(days: 2));
        db = AppDatabase(openDatabaseFile(file));
        app = await StudyAppController.open(db, identity, now: () => now);
        expect(app.runningSession, isNull);
        expect(app.totalDuration, const Duration(minutes: 20).inMilliseconds);
        expect(app.tasks.single.status, 'todo');
        expect(
          app.taskDuration(taskId),
          const Duration(minutes: 20).inMilliseconds,
        );
        final digest = await app.applier.projectionDigest(app.workspace!.id);
        app.dispose();
        app = await StudyAppController.open(db, identity, now: () => now);
        expect(await app.applier.projectionDigest(app.workspace!.id), digest);
      } finally {
        app.dispose();
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );

  for (final paused in [false, true]) {
    test(
      'eight hour limit with paused=$paused and delayed background tick',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        var now = DateTime.utc(2026, 10, 1);
        final app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
          now: () => now,
        );
        try {
          await app.onboard(
            name: '考研',
            date: '2028-12-20',
            subjectNames: ['数学'],
          );
          await app.startStudy(app.subjects.single.id);
          final id = app.runningSession!.id;
          now = now.add(const Duration(hours: 3));
          await app.tickTaskProgress();
          expect(app.runningSession, isNotNull);
          if (paused) {
            await app.pauseStudy();
            now = now.add(const Duration(hours: 10));
            await app.tickTaskProgress();
            expect(app.runningSession!.status, 'paused');
            expect(
              app.sessionDuration(id),
              const Duration(hours: 3).inMilliseconds,
            );
            await app.resumeStudy();
          }
          now = now.add(const Duration(hours: 6));
          expect(
            app.sessionDuration(id),
            const Duration(hours: 8).inMilliseconds,
          );
          expect(app.statistics.total, const Duration(hours: 8).inMilliseconds);
          await app.tickTaskProgress();
          expect(app.runningSession, isNull);
          expect(
            app.sessionDuration(id),
            const Duration(hours: 8).inMilliseconds,
          );
          expect(
            app.lastCompletedStudyDuration,
            const Duration(hours: 8).inMilliseconds,
          );
          final count = (await db.select(db.oplog).get()).length;
          await app.tickTaskProgress();
          expect((await db.select(db.oplog).get()).length, count);
        } finally {
          app.dispose();
          await db.close();
        }
      },
    );
  }

  test(
    'v3 upgrade preserves history and safely closes legacy open session',
    () async {
      final directory = await Directory.systemTemp.createTemp('yanji-upgrade-');
      final file = File('${directory.path}/app.sqlite');
      final identity = await testIdentity(
        '01991f82-0000-7000-8000-000000000101',
        1,
      );
      var now = DateTime.utc(2026, 10, 1);
      var db = AppDatabase(openDatabaseFile(file));
      var app = await StudyAppController.open(db, identity, now: () => now);
      try {
        await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
        await app.startStudy(app.subjects.single.id);
        now = now.add(const Duration(minutes: 15));
        await app.pauseStudy();
        await app.resumeStudy();
        await db.customStatement('DROP TABLE local_study_checkpoints');
        await db.customStatement('PRAGMA user_version = 3');
        app.dispose();
        await db.close();
        now = now.add(const Duration(days: 1));
        db = AppDatabase(openDatabaseFile(file));
        app = await StudyAppController.open(db, identity, now: () => now);
        expect(app.runningSession, isNull);
        expect(app.totalDuration, const Duration(minutes: 15).inMilliseconds);
        expect(app.subjects.single.name, '数学');
        expect(await db.select(db.localStudyCheckpoints).get(), isEmpty);
      } finally {
        app.dispose();
        await db.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
