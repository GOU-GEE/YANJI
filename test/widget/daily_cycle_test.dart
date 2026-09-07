import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';

import '../support/identities.dart';

void main() {
  testWidgets(
    'phone daily cycle: onboarding subject task timer and statistics',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = AppDatabase(NativeDatabase.memory());
      var now = DateTime.utc(2026, 9, 3, 8);
      late StudyAppController app;
      await tester.runAsync(() async {
        app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
          now: () => now,
        );
      });
      Future<void> settle() async {
        for (var i = 0; i < 4; i++) {
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
        }
        await tester.pumpAndSettle();
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await settle();
      }

      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appControllerProvider.overrideWith((ref) async => app)],
            child: const YanJiApp(),
          ),
        );
        await settle();
        expect(find.text('欢迎使用研迹'), findsOneWidget);
        await tap(find.byKey(const Key('exam-date')));
        await tap(find.text('确定'));
        await tap(find.byKey(const Key('onboarding-next')));
        await tap(find.byKey(const Key('onboarding-next')));
        await tap(find.byKey(const Key('onboarding-next')));
        expect(app.isReady, isTrue);
        expect(app.subjects, hasLength(4));
        expect(find.byKey(const Key('today-start')), findsOneWidget);
        await tap(find.byKey(const Key('choose-exam-year')));
        await tap(find.byKey(const Key('exam-year')));
        await tap(find.text('2028 考研').last);
        expect(find.text('预计初试：2027-12-25'), findsOneWidget);
        await tap(find.byKey(const Key('save-exam-year')));
        expect(app.examYear, 2028);
        expect(app.exam?.examDate, '2027-12-25');

        await tap(find.byKey(const ValueKey('nav-/profile')));
        await tap(find.text('我的科目'));
        await tap(find.byTooltip('新增科目'));
        await tester.enterText(find.byKey(const Key('subject-name')), '数据结构');
        await tap(find.byKey(const Key('save-subject')));
        expect(find.text('数据结构'), findsOneWidget);
        expect(app.subjects, hasLength(5));
        await tap(find.byTooltip('返回'));
        await tap(find.byKey(const ValueKey('nav-/')));
        await tap(find.text('添加任务'));
        await tester.enterText(find.byKey(const Key('task-title')), '学习英语一个小时');
        await tester.pumpAndSettle();
        expect(find.textContaining('识别到时长：60 分钟'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('task-minutes')))
              .controller!
              .text,
          '60',
        );
        await tester.enterText(find.byKey(const Key('task-minutes')), '30');
        await tap(find.byKey(const Key('save-task')));
        await tester.scrollUntilVisible(
          find.text('学习英语'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('学习英语'), findsOneWidget);
        expect(app.todayTasks, hasLength(1));
        expect(app.todayTasks.single.estimatedSeconds, 1800);
        expect(app.subject(app.todayTasks.single.subjectId)?.name, '英语一');
        await tap(find.byTooltip('学习 学习英语'));
        await tap(find.byKey(const Key('confirm-start')));
        expect(find.text('正在学习'), findsOneWidget);
        expect(app.runningSession?.status, 'active');
        now = now.add(const Duration(minutes: 5));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        now = now.add(const Duration(minutes: 5));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:10:00'), findsOneWidget);
        await tap(find.byKey(const Key('pause-resume')));
        expect(app.runningSession?.status, 'paused');
        now = now.add(const Duration(minutes: 20));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('00:10:00'), findsOneWidget);
        await tap(find.byKey(const Key('pause-resume')));
        expect(app.runningSession?.status, 'active');
        now = now.add(const Duration(minutes: 5));
        await tester.pump(const Duration(seconds: 1));
        await tap(find.byKey(const Key('stop-study')));
        expect(app.runningSession, isNull);
        expect(app.todayDuration, 15 * 60000);
        expect(app.todayTasks.single.status, 'todo');
        await tap(find.text('回到今天'));
        await tap(find.byKey(ValueKey('complete-${app.todayTasks.single.id}')));
        expect(app.todayTasks.single.status, 'completed');
        expect(find.text('写今日复盘'), findsNothing);
        await tap(find.byKey(const ValueKey('nav-/statistics')));
        expect(find.text('0h 15m'), findsWidgets);
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('stat-连续学习'))).data,
          '1 天',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
        await tester.runAsync(db.close);
      }
    },
  );
  testWidgets('bootstrap failure has a retry action', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(
            (ref) async => throw StateError('test failure'),
          ),
        ],
        child: const YanJiApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('暂时无法打开研迹'), findsOneWidget);
    expect(find.text('重新尝试'), findsOneWidget);
  });
}
