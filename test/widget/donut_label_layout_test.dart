import 'package:flutter/material.dart';

import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/features/donut_label_layout.dart';
import 'package:yanji/features/statistics_charts.dart';

void main() {
  test('smart outside labels preserve sides, order, bounds and spacing', () {
    const bounds = Size(390, 310);
    const candidates = [
      DonutLabelCandidate(
        index: 0,
        anchor: Offset(230, 70),
        size: Size(72, 34),
        isLeft: false,
      ),
      DonutLabelCandidate(
        index: 1,
        anchor: Offset(260, 100),
        size: Size(76, 34),
        isLeft: false,
      ),
      DonutLabelCandidate(
        index: 2,
        anchor: Offset(280, 155),
        size: Size(70, 34),
        isLeft: false,
      ),
      DonutLabelCandidate(
        index: 3,
        anchor: Offset(108, 170),
        size: Size(64, 34),
        isLeft: true,
      ),
    ];
    const exclusion = Rect.fromLTRB(110, 70, 280, 240);
    final result = layoutDonutLabels(
      candidates: candidates,
      bounds: bounds,
      exclusionRect: exclusion,
    );
    expect(result, hasLength(4));
    for (final item in result) {
      expect(item.rect.left, greaterThanOrEqualTo(8));
      expect(item.rect.top, greaterThanOrEqualTo(8));
      expect(item.rect.right, lessThanOrEqualTo(bounds.width - 8));
      expect(item.rect.bottom, lessThanOrEqualTo(bounds.height - 8));
      expect(
        item.candidate.isLeft
            ? item.rect.center.dx < bounds.width / 2
            : item.rect.center.dx > bounds.width / 2,
        isTrue,
      );
      final closestX = exclusion.center.dx.clamp(
        item.rect.left,
        item.rect.right,
      );
      final closestY = exclusion.center.dy.clamp(
        item.rect.top,
        item.rect.bottom,
      );
      expect(
        (Offset(closestX, closestY) - exclusion.center).distance,
        greaterThanOrEqualTo(exclusion.width / 2),
      );
    }
    final right = result.where((p) => !p.candidate.isLeft).toList()
      ..sort((a, b) => a.candidate.anchor.dy.compareTo(b.candidate.anchor.dy));
    for (var i = 1; i < right.length; i++) {
      expect(
        right[i].rect.top,
        greaterThanOrEqualTo(right[i - 1].rect.bottom + 8),
      );
      expect(right[i].rect.center.dy, greaterThan(right[i - 1].rect.center.dy));
    }
    expect(right.first.rect.left, lessThan(right.last.rect.left));
  });

  test('isolated label stays close to its desired vertical position', () {
    const candidate = DonutLabelCandidate(
      index: 0,
      anchor: Offset(290, 140),
      size: Size(68, 34),
      isLeft: false,
    );
    final result = layoutDonutLabels(
      candidates: const [candidate],
      bounds: const Size(390, 310),
      exclusionRect: const Rect.fromLTRB(110, 70, 280, 240),
    ).single;
    expect((result.rect.center.dy - candidate.anchor.dy).abs(), lessThan(1));
  });

  testWidgets('dense scaled labels stay disjoint and outside the donut', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final slices = List.generate(
      20,
      (i) => SubjectSlice(
        'subject-$i',
        i.isEven ? '计算机操作系统${i + 1}' : '概率论与数理统计${i + 1}',
        (i + 1) * 60000,
        Colors.primaries[i % Colors.primaries.length],
      ),
    );
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.duration);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SubjectDonut(slices: slices, total: total),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final donut = tester.getRect(find.byKey(const Key('subject-donut')));
    final labels = [
      for (var i = 0; i < slices.length; i++)
        tester.getRect(find.byKey(ValueKey('donut-label-subject-$i'))),
    ];
    for (var i = 0; i < labels.length; i++) {
      final closestX = donut.center.dx.clamp(labels[i].left, labels[i].right);
      final closestY = donut.center.dy.clamp(labels[i].top, labels[i].bottom);
      expect(
        (Offset(closestX, closestY) - donut.center).distance,
        greaterThanOrEqualTo(donut.width / 2),
      );
      final text = tester.widget<Text>(
        find.byKey(ValueKey('donut-label-subject-$i')),
      );
      expect(text.textSpan!.toPlainText(), isNot(contains('…')));
      for (var j = i + 1; j < labels.length; j++) {
        expect(labels[i].overlaps(labels[j]), isFalse);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('mouse hover shows slice details and exit clears them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const slices = [
      SubjectSlice('math', '数学一', 3 * 3600000, Colors.green),
      SubjectSlice('english', '英语一', 3600000, Colors.blueGrey),
    ];
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SubjectDonut(slices: slices, total: 4 * 3600000),
        ),
      ),
    );
    final ring = tester.getRect(find.byKey(const Key('subject-donut')));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: ring.center);
    await mouse.moveTo(Offset(ring.right - 12, ring.center.dy));
    await tester.pump();
    expect(find.byKey(const Key('subject-tooltip')), findsOneWidget);
    final tooltip = tester
        .widget<Text>(find.byKey(const Key('subject-tooltip')))
        .data!;
    expect(tooltip, contains('数学一'));
    expect(tooltip, contains('3h 00m'));
    expect(tooltip, contains('75.0%'));

    await mouse.moveTo(ring.center);
    await tester.pump();
    expect(find.byKey(const Key('subject-tooltip')), findsNothing);
    await mouse.removePointer();

    final englishLabel = find.byKey(const ValueKey('donut-label-english'));
    await tester.tap(englishLabel);
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('subject-tooltip'))).data,
      contains('英语一'),
    );
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('donut-label-action-english')),
    );
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);

    await tester.tap(englishLabel);
    await tester.pump();
    expect(find.byKey(const Key('subject-tooltip')), findsNothing);
  });
}
