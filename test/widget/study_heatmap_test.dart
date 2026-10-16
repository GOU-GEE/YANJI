import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/features/study_heatmap.dart';

void main() {
  test('heatmap row width follows device class and orientation', () {
    expect(heatmapRowDaysForSize(const Size(390, 844)), 91);
    expect(heatmapRowDaysForSize(const Size(844, 390)), 182);
    expect(heatmapRowDaysForSize(const Size(834, 1194)), 182);
    expect(heatmapRowDaysForSize(const Size(1194, 834)), 182);
  });

  test('first record anchors contiguous rows across leap days and years', () {
    final first = DateTime.utc(2023, 12, 31);
    final days = [...heatmapDays(first, 0), ...heatmapDays(first, 1)];
    expect(days.first, first);
    expect(days.toSet().length, 182);
    expect(days, contains(DateTime.utc(2024, 2, 29)));
    for (var i = 1; i < days.length; i++) {
      expect(days[i].difference(days[i - 1]).inDays, 1);
    }
    expect(heatmapRows(first, first), 1);
    expect(heatmapRows(first, first.add(const Duration(days: 90))), 1);
    expect(heatmapRows(first, first.add(const Duration(days: 91))), 2);
    final today = DateTime.utc(2026, 9, 4);
    final windowStart = heatmapWindowStart(first, today);
    final trailingDays = heatmapDays(
      windowStart,
      heatmapRows(first, today) - 1,
    );
    expect(trailingDays.last, today);
    expect(
      heatmapStart({
        first: 1,
        first.subtract(const Duration(days: 1)): 0,
      }, DateTime.utc(2026)),
      first,
    );
    expect(
      [0, 3599999, 3600000, 7200000, 14400000, 21600000].map(heatmapLevel),
      [0, 0, 1, 2, 3, 4],
    );
  });
  for (final size in [
    const Size(288, 900),
    const Size(358, 900),
    const Size(700, 900),
    const Size(844, 390),
  ]) {
    testWidgets('continuous preview and full history $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudyHeatmap(
                today: DateTime.utc(2026, 9, 4),
                daily: {DateTime.utc(2023, 12, 31): 123000},
              ),
            ),
          ),
        ),
      );
      final rowDays = heatmapRowDaysForSize(size);
      final first = DateTime.utc(2023, 12, 31);
      final rows = heatmapRows(
        first,
        DateTime.utc(2026, 9, 4),
        rowDays: rowDays,
      );
      final previewStart = rows > 2 ? rows - 2 : 0;
      expect(
        find.byKey(ValueKey('heatmap-group-$previewStart')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('heatmap-group-${previewStart + 1}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('heatmap-day-2026-09-04')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('heatmap-day-2026-09-04')),
      );
      await tester.tap(find.byKey(const ValueKey('heatmap-day-2026-09-04')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('heatmap-tooltip'))).data,
        contains('2026-09-04'),
      );
      expect(find.text('≥4h'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('heatmap-view-all')));
      await tester.tap(find.byKey(const Key('heatmap-view-all')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('heatmap-day-2026-09-04')),
        400,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 30,
      );
      expect(find.byKey(const Key('heatmap-day-2026-09-04')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('heatmap-view-all')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
