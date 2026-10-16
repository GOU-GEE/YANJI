import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/design/glass/glass_notice.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/features/statistics_page.dart';

import '../test/support/identities.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('glass chart information in light and dark simulator', (
    tester,
  ) async {
    const channel = MethodChannel('com.example.yanji/study_live_activity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
    final db = AppDatabase(NativeDatabase.memory());
    var now = DateTime.utc(2026, 9, 28, 2);
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      now: () => now,
    );
    final appearance = ValueNotifier(Brightness.light);
    late BuildContext pageContext;
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      expect(tester.takeException(), isNull);
    }

    Future<void> reveal(Finder finder, {double scroll = 180}) async {
      await tester.scrollUntilVisible(
        finder,
        scroll,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(finder);
      await settle();
    }

    Future<void> shot(String name) async {
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(name);
    }

    try {
      await app.onboard(
        name: '考研',
        date: '2028-12-20',
        subjectNames: ['数学', '英语', '专业课'],
      );
      for (var i = 0; i < 3; i++) {
        now = DateTime.utc(2026, 9, 28 + i, 2);
        await app.startStudy(app.subjects[i].id);
        now = now.add(Duration(minutes: 35 + i * 20));
        await app.stopStudy();
      }
      await tester.pumpWidget(
        ValueListenableBuilder(
          valueListenable: appearance,
          builder: (_, brightness, _) => MaterialApp(
            theme: yanjiThemeFor(brightness),
            home: Builder(
              builder: (context) {
                pageContext = context;
                return StatisticsPage(app);
              },
            ),
          ),
        ),
      );
      await settle();
      for (final brightness in Brightness.values.reversed) {
        appearance.value = brightness;
        await settle();
        final suffix = brightness.name;
        final trend = find.byKey(const Key('week-trend-touch'));
        await reveal(trend, scroll: -180);
        final rect = tester.getRect(trend);
        final point = Offset(
          rect.left + 24 + (rect.width - 48) * 2 / 6,
          rect.center.dy,
        );
        await tester.tapAt(point);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        await shot('week-enter-$suffix');
        await settle();
        expect(find.byKey(const Key('week-tooltip')), findsOneWidget);
        GlassNotice.show(pageContext, '已完成同步');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await shot('week-and-notice-$suffix');
        await tester.pump(const Duration(seconds: 4));
        await settle();
        await tester.tapAt(point);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        await shot('week-exit-$suffix');
        await settle();
        expect(find.byKey(const Key('week-tooltip')), findsNothing);

        final label = find.byKey(
          ValueKey('donut-label-action-${app.subjects.last.id}'),
        );
        await reveal(label);
        await tester.tap(label);
        await settle();
        expect(find.byKey(const Key('subject-tooltip')), findsOneWidget);
        await shot('subject-$suffix');
        await tester.tap(label);
        await settle();
        expect(find.byKey(const Key('subject-tooltip')), findsNothing);

        final day = find.byKey(const Key('heatmap-day-2026-09-30'));
        await reveal(day);
        await tester.tap(day);
        await settle();
        expect(find.byKey(const Key('heatmap-tooltip')), findsOneWidget);
        await shot('heatmap-$suffix');
        await tester.tap(day);
        await settle();
        expect(find.byKey(const Key('heatmap-tooltip')), findsNothing);
      }
      await tester.tap(find.byKey(const Key('heatmap-view-all')));
      await settle();
      final day = find.byKey(const Key('heatmap-day-2026-09-30'));
      await reveal(day);
      await tester.tap(day);
      await settle();
      expect(find.byKey(const Key('heatmap-tooltip')), findsOneWidget);
      await shot('heatmap-history-dark');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      appearance.dispose();
      app.dispose();
      await db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });
}
