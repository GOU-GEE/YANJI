import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';

import '../test/support/identities.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('subject children, natural task dialog, automatic completion', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    var now = DateTime.utc(2026, 9, 4, 2);
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      now: () => now,
    );
    await app.onboard(
      name: '2028 考研',
      date: '2027-12-25',
      subjectNames: ['英语一', '数学一', '408'],
    );
    final math = app.subjects.firstWhere((s) => s.name == '数学一');
    await app.saveSubject(name: '线性代数', parentId: math.id);
    final brightness = ValueNotifier(Brightness.light);
    final output = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/smart-task-preview',
    );
    await output.create(recursive: true);
    Future<void> settle() async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await settle();
    }

    Future<void> shot(String name) async {
      await settle();
      await File('${output.path}/$name.png')
          .writeAsBytes(await binding.takeScreenshot(name));
    }

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appControllerProvider.overrideWith((ref) async => app)],
          child: ValueListenableBuilder<Brightness>(
            valueListenable: brightness,
            builder: (context, value, _) => MediaQuery(
              data: MediaQueryData.fromView(tester.view)
                  .copyWith(platformBrightness: value),
              child: const YanJiApp(),
            ),
          ),
        ),
      );
      await settle();
      await tap(find.byKey(const ValueKey('nav-/profile')));
      await tap(find.text('我的科目'));
      await tap(find.text('数学一'));
      await tap(find.byKey(ValueKey('add-child-${math.id}')));
      await tester.enterText(find.byKey(const Key('subject-name')), '高等数学');
      await tap(find.byKey(const Key('save-subject')));
      expect(
        app.subjects.firstWhere((s) => s.name == '高等数学').parentSubjectId,
        math.id,
      );
      await shot('subjects');
      await tap(find.byType(BackButton));
      await tap(find.byKey(const ValueKey('nav-/')));
      await tap(find.text('添加任务'));
      await tester.enterText(find.byKey(const Key('task-title')), '学习高数线代一个小时');
      await settle();
      expect(find.textContaining('识别到时长：60 分钟'), findsOneWidget);
      await shot('task-dialog-light');
      brightness.value = Brightness.dark;
      await shot('task-dialog-dark');
      brightness.value = Brightness.light;
      await tap(find.byKey(const Key('save-task')));
      expect(app.tasks.single.title, '学习高数线代');
      expect(app.tasks.single.subjectId, math.id);
      await tap(find.byTooltip('学习 学习高数线代'));
      await shot('study-cancel');
      await tap(find.byKey(const Key('cancel-study')));
      expect(app.runningSession, isNull);
      await tap(find.byTooltip('学习 学习高数线代'));
      await tap(find.byKey(const Key('confirm-start')));
      now = now.add(const Duration(minutes: 60));
      await app.tickTaskProgress();
      await settle();
      expect(app.tasks.single.status, 'completed');
      await shot('task-auto-completed');
      await tap(find.byKey(const Key('stop-study')));
      expect(find.byKey(const Key('finish-linked-task')), findsNothing);
      await tap(find.text('完成').hitTestable());
      expect(app.tasks.single.status, 'completed');
      await tap(find.text('添加任务'));
      await tap(find.byKey(const ValueKey('task-daily')));
      final dailyButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('task-daily')),
      );
      final onceButton = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('task-once')),
      );
      expect(
        dailyButton.style!.side!.resolve({})!.color,
        isNot(Colors.transparent),
      );
      expect(onceButton.style!.side!.resolve({})!.color, Colors.transparent);
      await tap(find.byKey(const ValueKey('task-subject-null')));
      await tap(find.text('英语一').last);
      await tester.enterText(find.byKey(const Key('task-minutes')), '30');
      await shot('daily-empty-title');
      await tap(find.byKey(const Key('save-task')));
      final daily = app.tasks.firstWhere((t) => t.repeatDaily == 1);
      expect(daily.title, '学习英语一30分钟');
      await tap(find.byKey(const ValueKey('nav-/profile')));
      await tap(find.text('我的科目'));
      await tap(find.byTooltip('科目操作：数学一'));
      await tap(find.text('删除').last);
      expect(app.statistics.total, 0);
      await tap(find.text('已删除的科目'));
      await shot('deleted-subjects');
      await tap(find.byTooltip('已删除科目操作：数学一'));
      await tap(find.text('恢复'));
      expect(app.statistics.total, 3600000);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      brightness.dispose();
      app.dispose();
      await db.close();
    }
  });
}
