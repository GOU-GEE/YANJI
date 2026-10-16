import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/task_completion_motion.dart';
import 'package:yanji/features/tasks_pages.dart';

import '../support/identities.dart';

void main() {
  testWidgets('title fades continuously, wraps, and reverses when undone', (
    tester,
  ) async {
    var done = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Center(
              child: SizedBox(
                width: 160,
                child: TaskCompletionTitle(
                  title: '复习数学长标题以及所有错题',
                  completed: done,
                ),
              ),
            );
          },
        ),
      ),
    );
    Color? color() =>
        tester.widget<Text>(find.text('复习数学长标题以及所有错题')).style!.color;
    final initial = color();
    update(() => done = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final middle = color();
    expect(middle, isNot(initial));
    await tester.pumpAndSettle();
    expect(color(), isNot(middle));
    expect(tester.getSize(find.text('复习数学长标题以及所有错题')).height, greaterThan(30));
    update(() => done = false);
    await tester.pumpAndSettle();
    expect(color(), initial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion changes the title immediately', (tester) async {
    var done = false;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return TaskCompletionTitle(title: '减少动态效果', completed: done);
            },
          ),
        ),
      ),
    );
    final initial = tester.widget<Text>(find.text('减少动态效果')).style!.color;
    update(() => done = true);
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('减少动态效果')).style!.color,
      isNot(initial),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'today checkbox and count update on first frame while save is blocked',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      late StudyAppController app;
      await tester.runAsync(() async {
        app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
        );
        await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
        await app.saveTask(title: '即时勾选任务', date: app.today);
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ListenableBuilder(
            listenable: app,
            builder: (_, _) => TodayPage(app),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final checkbox = find.byKey(ValueKey('complete-${app.tasks.single.id}'));
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      late Completer<void> ready, release;
      late Future<void> lock;
      await tester.runAsync(() async {
        ready = Completer<void>();
        release = Completer<void>();
        lock = db.transaction(() async {
          ready.complete();
          await release.future;
        });
        await ready.future;
      });
      await tester.tap(checkbox);
      await tester.pump();
      expect(app.busy, isTrue);
      expect(tester.widget<Checkbox>(checkbox).value, isTrue);
      expect(find.text('1 / 1'), findsOneWidget);
      expect(
        tester
            .widget<TaskCompletionTitle>(find.byType(TaskCompletionTitle))
            .completed,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 60));
      final pulse = find
          .ancestor(of: checkbox, matching: find.byType(Transform))
          .first;
      expect(
        tester.widget<Transform>(pulse).transform.entry(0, 0),
        greaterThan(1),
      );
      await tester.runAsync(() async {
        release.complete();
        await lock;
      });
      for (var i = 0; i < 20 && app.busy; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
      }
      await tester.pumpAndSettle();
      expect(app.busy, isFalse);
      expect(app.tasks.single.status, 'completed');
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.runAsync(db.close);
    },
  );
}
