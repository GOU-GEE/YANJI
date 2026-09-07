import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/main.dart' as application;
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('real device storage and single-device daily loop', (
    tester,
  ) async {
    await application.main();
    Future<void> settle() async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    Future<void> tap(Finder f) async {
      if (f.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          f,
          100,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(f);
      await tester.tap(f);
      await settle();
    }

    if (const bool.fromEnvironment('YANJI_VERIFY_REOPEN')) {
      for (
        var i = 0;
        i < 100 && find.byType(YanJiApp).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final container = ProviderScope.containerOf(
        tester.element(find.byType(YanJiApp)),
      );
      final app = await container.read(appControllerProvider.future);
      await settle();
      expect(app.isReady, isTrue);
      expect(app.subjects.map((s) => s.name), contains('原生验证科目'));
      expect(app.todayTasks.single.title, '完成一篇英语阅读');
      expect(app.todayTasks.single.status, 'completed');
      expect(app.runningSession, isNull);
      expect(app.sessions.single.ownerDeviceId, app.identity.deviceId);
      expect(app.totalDuration, greaterThanOrEqualTo(60000));
      await tap(find.byKey(const ValueKey('nav-/statistics')));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('stat-连续学习'))).data,
        '1 天',
      );
      // ignore: avoid_print
      print('YANJI_STAGE_REOPEN_VERIFIED');
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      return;
    }
    for (
      var i = 0;
      i < 100 && !find.text('欢迎使用研迹').evaluate().isNotEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text('欢迎使用研迹'),
      findsOneWidget,
      reason: 'Use only a fresh verification emulator installation. Never clear personal data.',
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(YanJiApp)),
    );
    final app = await container.read(appControllerProvider.future);
    await tap(find.byKey(const Key('exam-date')));
    await tap(find.text('确定'));
    await tap(find.byKey(const Key('onboarding-next')));
    await tester.enterText(find.byKey(const Key('custom-subject')), '原生验证科目');
    await tap(find.byTooltip('添加科目'));
    await tap(find.byKey(const Key('onboarding-next')));
    await tap(find.byKey(const Key('onboarding-next')));
    for (var i = 0; i < 100 && !app.isReady; i++) {
      await settle();
    }
    expect(app.isReady, isTrue, reason: app.error);
    await settle();
    await tester.scrollUntilVisible(
      find.text('添加任务'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(find.text('添加任务'));
    await tester.enterText(find.byKey(const Key('task-title')), '完成一篇英语阅读');
    await tester.enterText(find.byKey(const Key('task-minutes')), '30');
    await tap(find.byKey(const Key('save-task')));
    await tester.scrollUntilVisible(
      find.text('完成一篇英语阅读'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await settle();
    await tap(find.byTooltip('学习 完成一篇英语阅读'));
    await tap(find.byKey(const Key('confirm-start')));
    expect(app.runningSession?.status, 'active');
    // The host verification script performs actual HOME/screen-off/foreground.
    // ignore: avoid_print
    print('YANJI_STAGE_TIMER_RUNNING');
    final sessionId = app.runningSession!.id;
    final elapsed = Stopwatch()..start();
    while (elapsed.elapsed < const Duration(seconds: 65)) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await settle();
    expect(app.sessionDuration(sessionId), greaterThanOrEqualTo(60000));
    await tap(find.byKey(const Key('pause-resume')));
    final paused = app.sessionDuration(sessionId);
    await Future<void>.delayed(const Duration(seconds: 2));
    await settle();
    expect(app.sessionDuration(sessionId), paused);
    await tap(find.byKey(const Key('pause-resume')));
    await Future<void>.delayed(const Duration(seconds: 2));
    await settle();
    await tap(find.byKey(const Key('stop-study')));
    expect(app.runningSession, isNull);
    expect(app.todayTasks.single.status, 'todo');
    await tap(find.text('回到今天'));
    await tap(find.byKey(ValueKey('complete-${app.todayTasks.single.id}')));
    expect(app.todayTasks.single.status, 'completed');
    await tap(find.byKey(const ValueKey('nav-/statistics')));
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('stat-连续学习'))).data,
      '1 天',
    );
    // ignore: avoid_print
    print('YANJI_STAGE_CYCLE_SAVED');
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
