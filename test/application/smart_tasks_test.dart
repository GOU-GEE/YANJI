import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/application/task_input_parser.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';

import '../support/identities.dart';

void main() {
  test('natural text, aliases, ambiguous subjects and durations', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
    );
    try {
      await app.onboard(
        name: '考研',
        date: '2028-12-20',
        subjectNames: ['英语一', '数学一', '408'],
      );
      final math = app.subjects.firstWhere((s) => s.name == '数学一');
      await app.saveSubject(name: '高等数学', parentId: math.id);
      await app.saveSubject(name: '线性代数', parentId: math.id);
      final english = app.subjects.firstWhere((s) => s.name == '英语一');
      var result = TaskInputParser.parse('学习英语一个小时', app.subjects);
      expect(result.title, '学习英语');
      expect(result.subjectId, english.id);
      expect(result.minutes, 60);
      result = TaskInputParser.parse('学习高数线代一个半小时', app.subjects);
      expect(result.subjectId, math.id);
      expect(result.minutes, 90);
      for (final pair in [
        ('半小时', 30),
        ('两小时三十分钟', 150),
        ('1h30min', 90),
        ('一刻钟', 15),
        ('1.5小时', 90),
        ('九十分钟', 90),
      ]) {
        expect(
          TaskInputParser.parse('学习英语${pair.$1}', app.subjects).minutes,
          pair.$2,
        );
      }
      expect(TaskInputParser.parse('英语一到两个小时', app.subjects).minutes, isNull);
      expect(TaskInputParser.parse('学习408分钟', app.subjects).subjectId, isNull);
      await app.saveSubject(name: '英语二');
      expect(TaskInputParser.parse('学英语一小时', app.subjects).subjectId, isNull);
      expect(
        TaskInputParser.parse('学英语一，1小时', app.subjects).subjectId,
        english.id,
      );
      await app.archiveSubject(math);
      expect(TaskInputParser.parse('学习高数', app.subjects).subjectId, isNull);
    } finally {
      app.dispose();
      await db.close();
    }
  });

  test('linked sessions accumulate, pause and unrelated time excluded, completes once after reopen', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final identity = await testIdentity(
      '01991f82-0000-7000-8000-000000000101',
      1,
    );
    var now = DateTime.utc(2026, 9, 4);
    var app = await StudyAppController.open(db, identity, now: () => now);
    try {
      await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['英语一']);
      final subject = app.subjects.single.id;
      await app.saveTask(
        title: '学习英语',
        subjectId: subject,
        date: app.today,
        estimatedSeconds: 3600,
      );
      final task = app.tasks.single.id;
      await app.startStudy(subject);
      now = now.add(const Duration(hours: 2));
      await app.stopStudy();
      expect(app.taskDuration(task), 0);
      await app.startStudy(subject, taskId: task);
      now = now.add(const Duration(minutes: 20));
      await app.pauseStudy();
      now = now.add(const Duration(hours: 1));
      await app.tickTaskProgress();
      expect(app.taskDuration(task), 20 * 60000);
      await app.stopStudy();
      await app.startStudy(subject, taskId: task);
      now = now.add(const Duration(minutes: 39));
      await app.tickTaskProgress();
      expect(app.task(task)!.status, 'todo');
      app.dispose();
      now = now.add(const Duration(minutes: 1));
      app = await StudyAppController.open(db, identity, now: () => now);
      expect(app.task(task)!.status, 'completed');
      expect(app.taskDuration(task), 60 * 60000);
      expect(app.runningSession, isNotNull);
      final count = (await db.select(db.oplog).get()).length;
      await app.tickTaskProgress();
      expect((await db.select(db.oplog).get()).length, count);
      await app.stopStudy();
    } finally {
      app.dispose();
      await db.close();
    }
  });

  test(
    'v1 database upgrades without losing tasks or session history',
    () async {
      final dir = await Directory.systemTemp.createTemp('yanji-migrate-');
      final file = File('${dir.path}/app.sqlite');
      final identity = await testIdentity(
        '01991f82-0000-7000-8000-000000000101',
        1,
      );
      var db = AppDatabase(openDatabaseFile(file));
      var app = await StudyAppController.open(db, identity);
      await app.onboard(name: '旧目标', date: '2027-12-20', subjectNames: ['数学一']);
      await app.saveTask(title: '保留任务');
      await app.startStudy(app.subjects.single.id);
      await app.stopStudy();
      final session = app.sessions.single.id;
      app.dispose();
      await db.customStatement(
        'ALTER TABLE subjects DROP COLUMN parent_subject_id',
      );
      await db.customStatement('ALTER TABLE tasks DROP COLUMN repeat_daily');
      await db.customStatement('PRAGMA user_version = 1');
      await db.close();
      db = AppDatabase(openDatabaseFile(file));
      app = await StudyAppController.open(db, identity);
      try {
        expect(app.tasks.single.title, '保留任务');
        expect(app.sessions.single.id, session);
        expect(app.subjects.single.parentSubjectId, isNull);
        await app.saveSubject(name: '线性代数', parentId: app.subjects.single.id);
        expect(app.subjects, hasLength(2));
        app.dispose();
        await db.customStatement('ALTER TABLE tasks DROP COLUMN repeat_daily');
        await db.customStatement('PRAGMA user_version = 2');
        await db.close();
        db = AppDatabase(openDatabaseFile(file));
        app = await StudyAppController.open(db, identity);
        expect(app.subjects, hasLength(2));
        expect(
          app.subjects.where((s) => s.parentSubjectId != null),
          hasLength(1),
        );
        expect(app.tasks.single.repeatDaily, 0);
      } finally {
        app.dispose();
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
