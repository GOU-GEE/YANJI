import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/features/device_tree_page.dart';
import 'package:yanji/sync/pairing/device_pairing_coordinator.dart';

import '../test/support/identities.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'simulator motion: navigation, forms, lists, timer, charts and reduced motion',
    (tester) async {
      // Historical fixture timestamps must not be reconciled with the OS clock.
      // This suite validates Flutter motion; native Live Activity has separate tests.
      const activityChannel = MethodChannel(
        'com.example.yanji/study_live_activity',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(activityChannel, (_) async => null);
      final db = AppDatabase(NativeDatabase.memory());
      var now = DateTime.utc(2026, 9, 30, 2);
      final app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
        now: () => now,
      );
      final appearance = ValueNotifier((dark: false, reduced: false));
      Future<void> settle() async {
        // Native SQLite writes can complete after a frame has already settled.
        for (var i = 0; i < 4; i++) {
          await tester.pumpAndSettle();
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> shot(String name, {bool middle = false}) async {
        if (middle) {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 60));
        } else {
          await settle();
        }
        expect(tester.takeException(), isNull);
        await binding.takeScreenshot(name);
      }

      Future<void> tap(
        Finder target, {
        bool finish = true,
        double scroll = 160,
      }) async {
        if (target.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            target,
            scroll,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(target);
        await tester.tap(target);
        if (finish) await settle();
      }

      Future<void> nav(String path, {bool finish = true}) =>
          tap(find.byKey(ValueKey('nav-$path')), finish: finish);
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appControllerProvider.overrideWith((ref) async => app)],
            child: ValueListenableBuilder(
              valueListenable: appearance,
              builder: (context, value, _) => MediaQuery(
                data: MediaQueryData.fromView(tester.view).copyWith(
                  platformBrightness: value.dark
                      ? Brightness.dark
                      : Brightness.light,
                  disableAnimations: value.reduced,
                ),
                child: const YanJiApp(),
              ),
            ),
          ),
        );
        await shot('01-onboarding-exam');
        await tap(find.byKey(const Key('onboarding-next')), finish: false);
        await shot('02-onboarding-forward-middle', middle: true);
        await settle();
        await tap(find.text('上一步'), finish: false);
        await shot('03-onboarding-back-middle', middle: true);
        await settle();
        expect(find.text('欢迎使用研迹'), findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tap(find.byKey(const Key('onboarding-next')));
        }
        expect(app.isReady, isTrue);
        for (var i = 0; i < 12; i++) {
          await app.saveTask(
            title: '复习 ${i + 1} · 整理长难句与错题',
            subjectId: app.subjects[i % 4].id,
            date: app.today,
            estimatedSeconds: 1800,
          );
        }
        for (var i = 0; i < 2; i++) {
          await app.startStudy(app.subjects[i].id);
          now = now.add(Duration(minutes: 35 + i * 20));
          await app.stopStudy();
        }
        await shot('04-today');
        await nav('/statistics', finish: false);
        await shot('05-navigation-middle', middle: true);
        await shot('06-statistics');
        await nav('/profile');
        await shot('07-profile');
        await nav('/');
        await tap(find.text('添加任务'));
        await tester.enterText(find.byKey(const Key('task-title')), '学习英语一个小时');
        await shot('08-recognition-middle', middle: true);
        await settle();
        expect(find.textContaining('识别到时长：60 分钟'), findsOneWidget);
        await shot('08b-recognition-settled');
        await tap(find.byKey(const Key('save-task')), finish: false);
        await shot('09-task-add-middle', middle: true);
        await settle();
        final task = app.todayTasks.first;
        await tap(find.byKey(ValueKey('complete-${task.id}')), finish: false);
        await shot('10-task-complete-middle', middle: true);
        await settle();
        expect(app.isTaskCompleted(app.task(task.id)!), isTrue);
        await tester.scrollUntilVisible(
          find.byKey(const Key('today-start')),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(find.byKey(const Key('today-start')));
        await tap(find.byKey(const Key('confirm-start')));
        await shot('11-timer-running');
        await tap(find.byKey(const Key('pause-resume')), finish: false);
        await shot('12-timer-paused-middle', middle: true);
        await settle();
        expect(find.text('已暂停 · 休息一下'), findsOneWidget);
        await shot('12b-timer-paused-settled');
        await tap(find.byKey(const Key('pause-resume')));
        expect(find.text('正在学习'), findsOneWidget);
        await tap(find.byKey(const Key('stop-study')), finish: false);
        await shot('13-timer-finish-middle', middle: true);
        await settle();
        expect(find.text('这段学习已完成'), findsOneWidget);
        await tap(find.text('回到今天'));
        await nav('/statistics');
        await tester.scrollUntilVisible(
          find.byKey(const Key('subject-range')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(find.text('周'), finish: false);
        await shot('14-donut-range-middle', middle: true);
        await settle();
        await tap(
          find.byKey(ValueKey('donut-label-action-${app.subjects.first.id}')),
          finish: false,
        );
        await shot('15-donut-highlight-middle', middle: true);
        await settle();
        expect(find.byKey(const Key('subject-tooltip')), findsOneWidget);
        appearance.value = (dark: true, reduced: false);
        await shot('16-statistics-dark');
        await tap(find.text('查看细分'), finish: false, scroll: -160);
        await shot('17-donut-detail-middle', middle: true);
        await settle();
        await nav('/profile');
        await tap(find.text('我的科目'));
        await app.saveSubject(name: '模拟器验证科目');
        await shot('18-subject-add-middle', middle: true);
        await settle();
        final subject = app.subjects.firstWhere((s) => s.name == '模拟器验证科目');
        await app.deleteSubject(subject);
        await shot('19-subject-remove-middle', middle: true);
        await settle();
        await app.restoreSubject(app.subject(subject.id)!);
        await shot('20-subject-restored');
        await tap(find.byTooltip('返回'));
        appearance.value = (dark: false, reduced: true);
        await settle();
        await nav('/statistics');
        await shot('21-reduced-motion-statistics');
        await nav('/');
        await shot('22-reduced-motion-today');
        // Deterministic failure exercises loading/error animation without pairing another device.
        final opening = Completer<DevicePairingCoordinator>();
        await tester.pumpWidget(
          MaterialApp(
            home: DevicePage(app, coordinatorFactory: () => opening.future),
          ),
        );
        await tester.pump();
        opening.completeError(StateError('simulator test failure'));
        await shot('23-device-error-middle', middle: true);
        await shot('24-device-error');
        expect(find.text('无法启动设备配对'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(activityChannel, null);
        appearance.dispose();
        app.dispose();
        await db.close();
      }
    },
  );
}
