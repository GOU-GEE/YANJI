import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';

import '../support/identities.dart';

void main() {
  for (final daily in [false, true]) {
    test(
      'completion is immediate before blocked persistence, including daily=$daily',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
          now: () => DateTime.utc(2026, 10, 1, 2),
        );
        await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
        await app.saveTask(title: '即时反馈', date: app.today, repeatDaily: daily);
        final task = app.tasks.single;
        final ready = Completer<void>(), release = Completer<void>();
        final lock = db.transaction(() async {
          ready.complete();
          await release.future;
        });
        await ready.future;
        final saving = app.setTaskStatus(task, 'completed');
        expect(app.busy, isTrue);
        expect(task.status, 'todo');
        expect(app.isTaskCompleted(task), isTrue);
        expect(app.todayTasks.where(app.isTaskCompleted).length, 1);
        release.complete();
        await lock;
        await saving;
        expect((await db.select(db.tasks).getSingle()).status, 'completed');
        final undoing = app.setTaskStatus(app.task(task.id)!, 'todo');
        expect(app.isTaskCompleted(app.task(task.id)!), isFalse);
        await undoing;
        expect((await db.select(db.tasks).getSingle()).status, 'todo');
        app.dispose();
        await db.close();
      },
    );
  }

  test('failed persistence rolls back optimistic completion and leaves data unchanged', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
    );
    await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
    await app.saveTask(title: '保存失败回退', date: app.today);
    await db.customStatement(
      "CREATE TRIGGER reject_task_status BEFORE INSERT ON tasks WHEN NEW.status = 'completed' BEGIN SELECT RAISE(ABORT, 'fixture failure'); END",
    );
    final task = app.tasks.single;
    final saving = app.setTaskStatus(task, 'completed');
    expect(app.isTaskCompleted(task), isTrue);
    await expectLater(saving, throwsA(anything));
    expect(app.isTaskCompleted(task), isFalse);
    expect(app.busy, isFalse);
    expect(app.error, isNotNull);
    expect((await db.select(db.tasks).getSingle()).status, 'todo');
    app.dispose();
    await db.close();
  });
}
