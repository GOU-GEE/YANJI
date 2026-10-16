import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/features/tasks_pages.dart';

import '../test/support/identities.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'today completion responds before blocked disk save and animates',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      );
      await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
      await app.saveTask(title: '完成数学复习并整理易错题', date: app.today);
      Future<void> settle() async {
        for (var i = 0; i < 4; i++) {
          await tester.pumpAndSettle();
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
        expect(tester.takeException(), isNull);
      }

      try {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: yanjiThemeFor(brightness),
              home: ListenableBuilder(
                listenable: app,
                builder: (_, _) => TodayPage(app),
              ),
            ),
          );
          await settle();
          final checkbox = find.byKey(
            ValueKey('complete-${app.tasks.single.id}'),
          );
          await tester.ensureVisible(checkbox);
          await settle();
          final ready = Completer<void>(), release = Completer<void>();
          final lock = db.transaction(() async {
            ready.complete();
            await release.future;
          });
          await ready.future;
          await tester.tap(checkbox);
          await tester.pump();
          expect(app.busy, isTrue);
          expect(tester.widget<Checkbox>(checkbox).value, isTrue);
          expect(find.text('1 / 1'), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 60));
          await binding.takeScreenshot('task-${brightness.name}-checking');
          release.complete();
          await lock;
          await settle();
          expect(app.tasks.single.status, 'completed');
          await binding.takeScreenshot('task-${brightness.name}-completed');
          await tester.tap(checkbox);
          await tester.pump();
          expect(tester.widget<Checkbox>(checkbox).value, isFalse);
          await settle();
          expect(app.tasks.single.status, 'todo');
          await binding.takeScreenshot('task-${brightness.name}-undone');
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        app.dispose();
        await db.close();
      }
    },
  );
}
