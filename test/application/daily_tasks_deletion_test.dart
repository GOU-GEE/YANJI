import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';

import '../support/identities.dart';

void main() {
  test('empty title generation and daily progress reset preserve history across reopen', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final identity = await testIdentity(
      '01991f82-0000-7000-8000-000000000101',
      1,
    );
    var now = DateTime.utc(2026, 9, 4, 15, 58);
    var app = await StudyAppController.open(db, identity, now: () => now);
    try {
      await app.onboard(name: '考研', date: '2027-12-20', subjectNames: ['英语一']);
      final subject = app.subjects.single.id;
      await app.saveTask(
        title: '',
        subjectId: subject,
        date: app.today,
        estimatedSeconds: 60,
        repeatDaily: true,
      );
      final daily = app.tasks.single.id;
      expect(app.task(daily)!.title, '学习英语一1分钟');
      await app.saveTask(title: '当天任务', date: app.today);
      await app.startStudy(subject, taskId: daily);
      now = now.add(const Duration(minutes: 1));
      await app.tickTaskProgress();
      expect(app.isTaskCompleted(app.task(daily)!), isTrue);
      await app.stopStudy();
      now = now.add(const Duration(minutes: 1));
      final before = (await db.select(db.oplog).get()).length;
      await app.tickTaskProgress();
      expect((await db.select(db.oplog).get()).length, before);
      expect(app.todayTasks.map((t) => t.id), [daily]);
      expect(app.taskDuration(daily), 0);
      expect(app.isTaskCompleted(app.task(daily)!), isFalse);
      expect(app.totalDuration, 60000);
      app.dispose();
      app = await StudyAppController.open(db, identity, now: () => now);
      expect(app.taskDuration(daily), 0);
      await app.startStudy(subject, taskId: daily);
      now = now.add(const Duration(minutes: 1));
      await app.stopStudy();
      expect(app.isTaskCompleted(app.task(daily)!), isTrue);
      expect(app.totalDuration, 120000);
      await app.saveTask(title: '每天背单词50个', date: app.today, repeatDaily: true);
      final reminder = app.tasks.firstWhere((t) => t.title == '每天背单词50个');
      await app.setTaskStatus(reminder, 'completed');
      expect(app.isTaskCompleted(app.task(reminder.id)!), isTrue);
      now = now.add(const Duration(days: 1));
      expect(app.isTaskCompleted(app.task(reminder.id)!), isFalse);
    } finally {
      app.dispose();
      await db.close();
    }
  });

  test('daily running segment clips at local midnight', () async {
    final db = AppDatabase(NativeDatabase.memory());
    var now = DateTime.utc(2026, 9, 4, 15, 59);
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      now: () => now,
    );
    try {
      await app.onboard(name: '考研', date: '2027-12-20', subjectNames: ['英语一']);
      await app.saveTask(
        title: '每日英语',
        repeatDaily: true,
        estimatedSeconds: 120,
        date: app.today,
      );
      final task = app.tasks.single.id;
      await app.startStudy(app.subjects.single.id, taskId: task);
      now = now.add(const Duration(minutes: 2));
      await app.tickTaskProgress();
      expect(app.taskDuration(task), 60000);
      expect(app.isTaskCompleted(app.task(task)!), isFalse);
    } finally {
      app.dispose();
      await db.close();
    }
  });

  test('delete hides stats, restore recovers time, permanent delete survives rebuild', () async {
    final db = AppDatabase(NativeDatabase.memory());
    var now = DateTime.utc(2026, 9, 4);
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      now: () => now,
    );
    try {
      await app.onboard(name: '考研', date: '2027-12-20', subjectNames: ['数学一']);
      final parent = app.subjects.single;
      await app.saveSubject(name: '高等数学', parentId: parent.id);
      final child = app.subjects.singleWhere(
        (subject) => subject.parentSubjectId == parent.id,
      );
      await app.saveTask(title: '高数', subjectId: child.id);
      await app.startStudy(child.id, taskId: app.tasks.single.id);
      now = now.add(const Duration(minutes: 10));
      await app.deleteSubject(parent);
      expect(app.runningSession, isNull);
      expect(app.statistics.total, 0);
      expect(app.todayDuration, 0);
      expect(app.statistics.learningDays, 0);
      expect(app.sessions, hasLength(1));
      expect(app.subjects.where(app.isSubjectVisible), isEmpty);
      await app.restoreSubject(app.subject(parent.id)!);
      expect(app.statistics.total, 600000);
      expect(app.totalDuration, 600000);
      expect(app.subjects.where(app.isSubjectVisible), hasLength(2));
      await app.deleteSubject(app.subject(parent.id)!);
      await app.permanentlyDeleteSubject(app.subject(parent.id)!);
      await app.applier.projectionDigest(app.workspace!.id);
      await app.refresh();
      expect(app.subjects, isEmpty);
      expect(app.tasks, isEmpty);
      expect(app.sessions, isEmpty);
      expect((await db.select(db.tombstones).get()).length, 2);
    } finally {
      app.dispose();
      await db.close();
    }
  });
}
