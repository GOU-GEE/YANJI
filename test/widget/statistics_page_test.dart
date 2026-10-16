import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/design/glass/glass_segmented_control.dart';
import 'package:yanji/features/statistics_page.dart';
import 'package:yanji/features/statistics_charts.dart';
import 'package:yanji/features/study_heatmap.dart';

import '../support/identities.dart';

void main() {
  for (final scenario in [
    (size: const Size(390, 844), scale: 1.0, brightness: Brightness.light),
    (size: const Size(320, 640), scale: 2.0, brightness: Brightness.dark),
  ]) {
    testWidgets(
      'data charts ${scenario.size.width} ${scenario.brightness}: points, scope, tooltip, heatmap',
      (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final db = AppDatabase(NativeDatabase.memory());
        var now = DateTime.utc(2026, 8, 24, 2);
        late StudyAppController app;
        await tester.runAsync(() async {
          app = await StudyAppController.open(
            db,
            await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
            now: () => now,
          );
          await app.onboard(
            name: '考研',
            date: '2028-12-20',
            subjectNames: ['数学', '英语阅读与长难句专项复习'],
          );
          await app.startStudy(app.subjects.first.id);
          now = now.add(const Duration(hours: 1));
          await app.stopStudy();
          now = DateTime.utc(2026, 8, 31, 2);
          await app.startStudy(app.subjects.first.id);
          now = now.add(const Duration(hours: 2));
          await app.stopStudy();
          now = DateTime.utc(2026, 9, 2, 2);
          await app.startStudy(app.subjects.last.id);
          now = now.add(const Duration(hours: 1, seconds: 17));
          await app.stopStudy();
          now = DateTime.utc(2026, 9, 4, 4);
        });
        final semantics = tester.ensureSemantics();
        Future<void> reveal(Finder finder, {bool upward = false}) async {
          await tester.scrollUntilVisible(
            finder,
            upward ? -180 : 180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: yanjiThemeFor(scenario.brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scenario.scale)),
                child: child!,
              ),
              home: StatisticsPage(app),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('平均每日'), findsOneWidget);
          expect(
            tester.widget<Text>(find.byKey(const ValueKey('stat-平均每日'))).data,
            '1h 20m',
          );
          expect(
            tester.widget<Text>(find.byKey(const ValueKey('stat-学习天数'))).data,
            '3 天',
          );
          expect(find.text('数据'), findsNothing);
          expect(find.byKey(const Key('week-tooltip')), findsNothing);
          await reveal(find.byKey(const Key('week-total')));
          expect(
            tester.widget<Text>(find.byKey(const Key('week-total'))).data,
            '3h 00m',
          );
          expect(find.byKey(const Key('week-change')), findsNothing);
          await reveal(find.byKey(const Key('week-trend-touch')));
          final rect = tester.getRect(
            find.byKey(const Key('week-trend-touch')),
          );
          // Wednesday point x is retained exactly regardless of smoothing.
          await tester.tapAt(
            Offset(rect.left + 24 + (rect.width - 48) * 2 / 6, rect.center.dy),
          );
          await tester.pumpAndSettle();
          await reveal(find.byKey(const Key('week-tooltip')));
          expect(
            tester.widget<Text>(find.byKey(const Key('week-tooltip'))).data,
            contains('1 小时 0 分 17 秒'),
          );
          await reveal(find.text('总'));
          final range = find.byKey(const Key('subject-range'));
          expect(find.text('2026-09-04'), findsOneWidget);
          await tester.tap(find.text('总').hitTestable());
          await tester.pumpAndSettle();
          expect(find.text('2026-08-24 至 2026-09-02'), findsOneWidget);
          await reveal(find.byKey(const Key('subject-donut')));
          expect(find.byType(SubjectDonut), findsOneWidget);
          expect(
            tester.widget<Text>(find.byKey(const Key('donut-total'))).data,
            '4h 00m',
          );
          await reveal(range, upward: true);
          await tester.tap(
            find.descendant(of: range, matching: find.text('月')),
          );
          await tester.pumpAndSettle();
          expect(find.text('2026-09-01 至 2026-09-04'), findsOneWidget);
          await reveal(find.byKey(const Key('donut-total')));
          expect(
            tester.widget<Text>(find.byKey(const Key('donut-total'))).data,
            '1h 00m',
          );
          await reveal(range, upward: true);
          await tester.tap(
            find.descendant(of: range, matching: find.text('总')),
          );
          await tester.pumpAndSettle();
          await reveal(range, upward: true);
          await tester.tap(
            find.descendant(of: range, matching: find.text('自定义')),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('custom-start-date')), findsOneWidget);
          expect(find.byKey(const Key('custom-end-date')), findsOneWidget);
          Navigator.of(
            tester.element(find.byKey(const Key('custom-start-date'))),
          ).pop();
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<GlassSegmentedControl>(
                  find.byType(GlassSegmentedControl),
                )
                .selected,
            3,
          );
          await reveal(find.byKey(const Key('subject-donut')));
          final ring = tester.getRect(find.byKey(const Key('subject-donut')));
          await tester.tapAt(Offset(ring.right - 12, ring.center.dy));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('subject-tooltip')), findsOneWidget);
          final tooltip = tester
              .widget<Text>(find.byKey(const Key('subject-tooltip')))
              .data!;
          expect(tooltip, contains('学习时间'));
          expect(tooltip, contains('占比'));
          await tester.tapAt(ring.center);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('subject-tooltip')), findsNothing);
          await reveal(find.text('周'), upward: true);
          await tester.tap(find.text('周').hitTestable());
          await tester.pumpAndSettle();
          expect(find.text('2026-08-31 至 2026-09-04'), findsOneWidget);
          await reveal(find.byKey(const Key('subject-donut')));
          expect(
            tester.widget<Text>(find.byKey(const Key('donut-total'))).data,
            '3h 00m',
          );
          await reveal(find.text('学习热力图'));
          expect(find.text('学习积累'), findsNothing);
          expect(find.byKey(const ValueKey('stat-学习天数')), findsNothing);
          expect(find.byKey(const ValueKey('stat-平均每日')), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          semantics.dispose();
          app.dispose();
          await tester.runAsync(db.close);
        }
      },
    );
  }
  testWidgets('empty charts have no fabricated comparison or learning days', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    late StudyAppController app;
    await tester.runAsync(() async {
      app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      );
      await app.onboard(name: '考研', date: '2028-12-20', subjectNames: ['数学']);
    });
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: yanjiThemeFor(Brightness.light),
          home: StatisticsPage(app),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('week-change')), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('stat-平均每日'))).data,
        '0h 00m',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('stat-学习天数'))).data,
        '0 天',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('subject-donut')),
        180,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('donut-empty'))).data,
        '今天无数据',
      );
      expect(find.byKey(const Key('donut-total')), findsNothing);
      final range = find.byKey(const Key('subject-range'));
      await tester.ensureVisible(range);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('subject-period-slot')), findsOneWidget);
      final ring = tester.getRect(find.byKey(const Key('subject-donut')));
      final control = tester.getRect(range);
      final periodSlot = tester.getRect(
        find.byKey(const Key('subject-period-slot')),
      );
      final nextHeading = tester.getRect(find.byType(StudyHeatmap));
      expect(periodSlot.top, greaterThanOrEqualTo(control.bottom));
      expect(periodSlot.bottom, lessThanOrEqualTo(ring.top));
      expect(
        ring.top - control.bottom,
        closeTo(nextHeading.top - ring.bottom, 1),
      );
      for (final (label, expected) in [('周', '本周无数据'), ('月', '本月无数据')]) {
        await tester.tap(
          find.descendant(of: range, matching: find.text(label)),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const Key('donut-empty'))).data,
          expected,
        );
      }
      await tester.tap(find.descendant(of: range, matching: find.text('总')));
      await tester.pumpAndSettle();
      expect(find.text('暂无学习记录'), findsOneWidget);
      await tester.tap(find.descendant(of: range, matching: find.text('自定义')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('donut-empty'))).data,
        '此区间无数据',
      );
      final customRing = tester.getRect(find.byKey(const Key('subject-donut')));
      final customControl = tester.getRect(range);
      final customPeriodSlot = tester.getRect(
        find.byKey(const Key('subject-period-slot')),
      );
      final customNextHeading = tester.getRect(find.byType(StudyHeatmap));
      expect(customPeriodSlot.height, periodSlot.height);
      expect(
        customRing.top - customControl.bottom,
        closeTo(customNextHeading.top - customRing.bottom, 1),
      );
      await tester.scrollUntilVisible(
        find.text('学习热力图'),
        180,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      app.dispose();
      await tester.runAsync(db.close);
    }
  });

  testWidgets(
    'details keep leaf-level parent records and use children when they exist',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      var now = DateTime.utc(2026, 9, 8, 2);
      late StudyAppController app;
      await tester.runAsync(() async {
        app = await StudyAppController.open(
          db,
          await testIdentity('01991f82-0000-7000-8000-000000000102', 2),
          now: () => now,
        );
        await app.onboard(
          name: '考研',
          date: '2028-12-20',
          subjectNames: ['数学', '英语'],
        );
        final math = app.subjects.firstWhere((s) => s.name == '数学');
        final english = app.subjects.firstWhere((s) => s.name == '英语');
        await app.saveSubject(name: '阅读', parentId: english.id);
        final reading = app.subjects.firstWhere((s) => s.name == '阅读');

        await app.startStudy(math.id);
        now = now.add(const Duration(minutes: 30));
        await app.stopStudy();
        await app.startStudy(reading.id);
        now = now.add(const Duration(minutes: 20));
        await app.stopStudy();
      });
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: yanjiThemeFor(Brightness.light),
            home: StatisticsPage(app),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('查看细分'), 180);
        await tester.tap(find.text('查看细分').hitTestable());
        await tester.pumpAndSettle();

        final donut = tester.widget<SubjectDonut>(find.byType(SubjectDonut));
        expect(
          donut.slices.map((slice) => slice.name),
          containsAll(<String>['数学', '阅读']),
        );
        expect(donut.slices.map((slice) => slice.name), isNot(contains('英语')));
        expect(donut.total, const Duration(minutes: 50).inMilliseconds);
      } finally {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
        await tester.runAsync(db.close);
      }
    },
  );
}
