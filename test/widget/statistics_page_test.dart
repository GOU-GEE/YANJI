import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/features/statistics_page.dart';
import 'package:yanji/features/statistics_charts.dart';

import '../support/identities.dart';

void main() {
  for (final scenario in [
    (size: const Size(390, 844), scale: 1.0, brightness: Brightness.light),
    (size: const Size(320, 640), scale: 2.0, brightness: Brightness.dark),
  ]) {
    testWidgets(
      'data charts ${scenario.size.width} ${scenario.brightness}: points, scope, tooltip, accumulation',
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
          expect(find.text('今日学习'), findsOneWidget);
          expect(find.text('数据'), findsNothing);
          expect(find.byKey(const Key('week-tooltip')), findsNothing);
          await reveal(find.byKey(const Key('week-total')));
          expect(
            tester.widget<Text>(find.byKey(const Key('week-total'))).data,
            '3h 00m',
          );
          expect(
            tester.widget<Text>(find.byKey(const Key('week-change'))).data,
            '较上周 +200.5%',
          );
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
          await reveal(find.text('查看累计'));
          await tester.tap(find.text('查看累计').hitTestable());
          await tester.pumpAndSettle();
          await reveal(find.byKey(const Key('subject-donut')));
          expect(find.byType(SubjectDonut), findsOneWidget);
          expect(
            tester.widget<Text>(find.byKey(const Key('donut-total'))).data,
            '4h 00m',
          );
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
          await reveal(find.text('查看本周'), upward: true);
          await tester.tap(find.text('查看本周').hitTestable());
          await tester.pumpAndSettle();
          await reveal(find.byKey(const Key('subject-donut')));
          expect(
            tester.widget<Text>(find.byKey(const Key('donut-total'))).data,
            '3h 00m',
          );
          await reveal(find.byKey(const ValueKey('stat-学习天数')));
          expect(
            tester.widget<Text>(find.byKey(const ValueKey('stat-学习天数'))).data,
            '3 天',
          );
          await reveal(find.text('学习热力图'));
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
      await tester.scrollUntilVisible(
        find.byKey(const Key('subject-donut')),
        180,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('donut-total'))).data,
        '0h 00m',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('stat-学习天数')),
        180,
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('stat-学习天数'))).data,
        '0 天',
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      app.dispose();
      await tester.runAsync(db.close);
    }
  });
}
