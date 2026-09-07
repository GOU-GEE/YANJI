import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/app/yanji_app.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/features/onboarding_page.dart';
import 'package:yanji/features/tasks_pages.dart';
import 'package:yanji/features/timer_review_pages.dart';

import '../support/identities.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  test(
    'light and dark reading, actions, states and control boundaries contrast',
    () {
      for (final brightness in Brightness.values) {
        final colors = YanJiColors.scheme(brightness);
        for (final background in [
          YanJiColors.canvas(brightness),
          colors.surface,
          colors.surfaceContainerLow,
          colors.surfaceContainerHigh,
        ]) {
          for (final foreground in [
            colors.onSurface,
            colors.onSurfaceVariant,
            colors.primary,
            colors.error,
            YanJiColors.warning(brightness),
            YanJiColors.information(brightness),
          ]) {
            expect(
              contrast(foreground, background),
              greaterThanOrEqualTo(4.5),
              reason: '$brightness $foreground on $background',
            );
          }
        }
        expect(
          contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.onPrimaryContainer, colors.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.outline, colors.surface),
          greaterThanOrEqualTo(3),
        );
      }
    },
  );

  for (final scenario in [
    (
      name: 'small phone 200% dark',
      size: const Size(320, 640),
      scale: 2.0,
      brightness: Brightness.dark,
    ),
    (
      name: 'phone light',
      size: const Size(390, 844),
      scale: 1.0,
      brightness: Brightness.light,
    ),
    (
      name: 'short landscape light',
      size: const Size(740, 360),
      scale: 1.0,
      brightness: Brightness.light,
    ),
    (
      name: 'tablet dark',
      size: const Size(1024, 768),
      scale: 1.0,
      brightness: Brightness.dark,
    ),
  ]) {
    testWidgets('${scenario.name}: four samples, keyboard and system theme', (
      tester,
    ) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      tester.platformDispatcher.platformBrightnessTestValue =
          scenario.brightness;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final semantics = tester.ensureSemantics();
      final db = AppDatabase(NativeDatabase.memory());
      late StudyAppController app;
      await tester.runAsync(() async {
        app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
          now: () => DateTime.utc(2026, 9, 3, 8),
        );
        await app.onboard(
          name: '2028 考研 · 计算机专业硕士',
          date: '2028-12-23',
          subjectNames: ['计算机专业基础综合与数据结构'],
        );
        await app.saveTask(
          title: '完成阅读理解并整理本周需要反复复习的长难句和错题',
          subjectId: app.subjects.first.id,
          date: app.today,
          estimatedSeconds: 1800,
          priority: 2,
        );
      });
      Future<void> page(Widget child) async {
        await tester.pumpWidget(
          MaterialApp(
            key: UniqueKey(),
            theme: yanjiThemeFor(Brightness.light),
            darkTheme: yanjiThemeFor(Brightness.dark),
            locale: const Locale('zh', 'CN'),
            supportedLocales: const [Locale('zh', 'CN')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: child,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
          scenario.brightness,
        );
        expect(tester.takeException(), isNull);
      }

      Future<void> reveal(Finder target) async {
        await tester.scrollUntilVisible(
          target,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      try {
        await page(OnboardingPage(app));
        await reveal(find.byKey(const Key('onboarding-next')));
        expect(
          tester.getSize(find.byKey(const Key('onboarding-next'))).height,
          greaterThanOrEqualTo(48),
        );
        await page(TodayPage(app));
        await reveal(find.byKey(const Key('today-start')));
        await tester.tap(find.byKey(const Key('today-start')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('confirm-start')));
        expect(tester.takeException(), isNull);
        // Dismiss without starting a session; timer is seeded separately below.
        Navigator.of(tester.element(find.byKey(const Key('confirm-start'))))
            .pop();
        await tester.pumpAndSettle();
        await page(TasksPage(app));
        await reveal(find.byKey(ValueKey('complete-${app.tasks.single.id}')));
        expect(
          find.bySemanticsLabel('完成任务：${app.tasks.single.title}'),
          findsOneWidget,
        );
        await page(TaskEditorPage(app, taskId: app.tasks.single.id));
        final keyboardHeight = scenario.size.height < 480 ? 140.0 : 260.0;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        await tester.pumpAndSettle();
        await reveal(find.byKey(const Key('save-task')));
        expect(
          tester.getRect(find.byKey(const Key('save-task'))).bottom,
          lessThanOrEqualTo(scenario.size.height - keyboardHeight),
        );
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => app.startStudy(
            app.subjects.first.id,
            taskId: app.tasks.single.id,
          ),
        );
        await page(TimerPage(app));
        await reveal(find.byKey(const Key('stop-study')));
        expect(
          tester.getSize(find.byKey(const Key('stop-study'))).height,
          greaterThanOrEqualTo(48),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [appControllerProvider.overrideWith((ref) async => app)],
            child: const YanJiApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('快速记录'), findsNothing);
        expect(find.text('计划'), findsNothing);
        expect(
          find.byType(NavigationRail),
          scenario.size.width >= 720 && scenario.size.height >= 480
              ? findsOneWidget
              : findsNothing,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        semantics.dispose();
        app.dispose();
        await tester.runAsync(db.close);
      }
    });
  }
}
