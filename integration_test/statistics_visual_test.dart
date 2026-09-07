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

/// Isolated, synthetic preview records. Never opens or clears the user's database.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native data page: trend, touch, scopes, dark and accumulation', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    var now = DateTime.utc(2026, 8, 24, 2);
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      now: () => now,
    );
    await app.onboard(
      name: '考研',
      date: '2028-12-20',
      subjectNames: ['数学', '英语', '政治'],
    );
    for (final item in [
      (24, 0, 180),
      (25, 1, 90),
      (31, 0, 120),
      (32, 1, 75),
      (33, 0, 150),
      (34, 2, 90),
      (35, 1, 45),
    ]) {
      now = DateTime.utc(2026, 8, item.$1, 2);
      await app.startStudy(app.subjects[item.$2].id);
      now = now.add(Duration(minutes: item.$3));
      await app.stopStudy();
    }
    now = DateTime.utc(2026, 9, 4, 10);
    final output = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/statistics-preview',
    );
    await output.create(recursive: true);
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      final bytes = await binding.takeScreenshot(name);
      await File('${output.path}/$name.png').writeAsBytes(bytes);
    }

    Future<void> reveal(Finder finder, double delta) async {
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    try {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final tag = brightness.name;
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [appControllerProvider.overrideWith((ref) async => app)],
            child: MediaQuery(
              data: MediaQueryData.fromView(tester.view)
                  .copyWith(platformBrightness: brightness),
              child: const YanJiApp(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-/statistics')));
        await tester.pumpAndSettle();
        await shot('data-$tag-trend');
        final chart = tester.getRect(find.byKey(const Key('week-trend-touch')));
        await tester.tapAt(
          Offset(chart.left + 24 + (chart.width - 48) * 2 / 6, chart.center.dy),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const Key('week-tooltip'))).data,
          contains('2 小时 30 分 0 秒'),
        );
        await shot('data-$tag-tooltip');
        await reveal(find.text('查看累计'), 180);
        await shot('data-$tag-subjects');
        await tester.tap(find.text('查看累计').hitTestable());
        await tester.pumpAndSettle();
        await reveal(find.byKey(const Key('subject-donut')), 180);
        expect(
          tester.widget<Text>(find.byKey(const Key('donut-total'))).data,
          '12h 30m',
        );
        await reveal(find.byKey(const ValueKey('stat-学习天数')), 180);
        await shot('data-$tag-accumulation');
        await reveal(find.byKey(const Key('heatmap-group-0')), 180);
        await tester.tap(find.byKey(const Key('heatmap-day-2026-09-02')));
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const Key('heatmap-tooltip'))).data,
          contains('2 小时 30 分 0 秒'),
        );
        await shot('data-$tag-heatmap');
        await reveal(find.byKey(const Key('heatmap-view-all')), -180);
        await tester.tap(find.byKey(const Key('heatmap-view-all')));
        await tester.pumpAndSettle();
        await shot('data-$tag-heatmap-all');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    } finally {
      await tester.pumpWidget(const SizedBox());
      app.dispose();
      await db.close();
    }
  });
}
