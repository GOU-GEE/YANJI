import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/glass_floating_surface.dart';
import 'package:yanji/design/glass/glass_information_popup.dart';
import 'package:yanji/design/glass/glass_notice.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/features/statistics_charts.dart';

void main() {
  Widget popup({Offset? point, String? text, bool reduced = false}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: GlassInformationPopup(
                  point: point,
                  child: text == null ? null : ChartBubble(text: text),
                ),
              ),
            ),
          ),
        ),
      );

  for (final brightness in Brightness.values) {
    testWidgets('chart bubbles share notice opacity and blur: $brightness', (
      tester,
    ) async {
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: yanjiThemeFor(brightness),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pageContext = context;
                return const Center(child: ChartBubble(text: '周三 · 1 小时'));
              },
            ),
          ),
        ),
      );
      GlassNotice.show(pageContext, '已完成同步');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final surfaces = find.byType(GlassFloatingSurface);
      expect(surfaces, findsNWidgets(2));
      final colors = <Color?>[];
      final filters = <ImageFilter>[];
      for (final surface in surfaces.evaluate()) {
        final descendants = find.descendant(
          of: find.byWidget(surface.widget),
          matching: find.byType(DecoratedBox),
        );
        colors.add(
          (tester.widget<DecoratedBox>(descendants.first).decoration
                  as BoxDecoration)
              .color,
        );
        final blur = find.descendant(
          of: find.byWidget(surface.widget),
          matching: find.byType(BackdropFilter),
        );
        filters.add(tester.widget<BackdropFilter>(blur).filter!);
      }
      expect(colors[0], colors[1]);
      expect(colors[0]!.a, closeTo(.50, .001));
      expect(filters[0].toString(), filters[1].toString());
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'horizontal chart drag bends bubble in both directions and rebounds',
    (tester) async {
      var chartUpdates = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (_) => chartUpdates++,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const Positioned.fill(
                      child: GlassInformationPopup(
                        point: Offset(100, 100),
                        child: ChartBubble(text: '滑动详情'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Matrix4 matrix() => tester
          .widget<Transform>(
            find.byKey(const Key('information-popup-drag-transform')),
          )
          .transform;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('滑动详情')),
      );
      await gesture.moveBy(const Offset(35, 0));
      await tester.pump();
      expect(matrix().entry(0, 0), greaterThan(1));
      expect(matrix().entry(1, 1), lessThan(1));
      expect(matrix().entry(0, 1), greaterThan(0));
      expect(matrix().entry(0, 3), greaterThan(0));
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      expect(matrix().entry(0, 1), lessThan(0));
      expect(matrix().entry(0, 3), lessThan(0));
      expect(chartUpdates, greaterThan(0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(matrix().entry(0, 0), closeTo(1, .001));
      expect(matrix().entry(0, 3), closeTo(0, .001));
    },
  );

  testWidgets('vertical deformation clears immediately for reduced motion', (
    tester,
  ) async {
    final transform = find.byKey(const Key('information-popup-drag-transform'));
    await tester.pumpWidget(popup(point: const Offset(100, 100), text: '详情'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('详情')),
    );
    await gesture.moveBy(const Offset(2, 35));
    await tester.pump();
    expect(
      tester.widget<Transform>(transform).transform.entry(1, 1),
      greaterThan(1),
    );
    expect(
      tester.widget<Transform>(transform).transform.entry(1, 3),
      greaterThan(0),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(
      tester.widget<Transform>(transform).transform.entry(0, 0),
      greaterThan(1),
    );
    expect(
      tester.widget<Transform>(transform).transform.entry(1, 1),
      greaterThan(1),
    );
    await tester.pumpWidget(
      popup(point: const Offset(100, 100), text: '详情', reduced: true),
    );
    expect(tester.widget<Transform>(transform).transform, Matrix4.identity());
    await gesture.cancel();
    await tester.pumpAndSettle();
    final reducedGesture = await tester.startGesture(
      tester.getCenter(find.text('详情')),
    );
    await reducedGesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(tester.widget<Transform>(transform).transform, Matrix4.identity());
    await reducedGesture.up();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'vertical bubble drag scrolls page concurrently and rebounds on cancel',
    (tester) async {
      final controller = ScrollController(initialScrollOffset: 200);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  const SizedBox(height: 400),
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: ColoredBox(color: Colors.white),
                        ),
                        const Positioned.fill(
                          child: GlassInformationPopup(
                            point: Offset(100, 120),
                            child: ChartBubble(text: '垂直拖动'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Matrix4 matrix() => tester
          .widget<Transform>(
            find.byKey(const Key('information-popup-drag-transform')),
          )
          .transform;
      final before = controller.offset;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('垂直拖动')),
      );
      await gesture.moveBy(const Offset(0, -35));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -35));
      await tester.pump();
      expect(controller.offset, greaterThan(before));
      expect(matrix().entry(1, 1), greaterThan(1));
      expect(matrix().entry(0, 0), lessThan(1));
      expect(matrix().entry(1, 3), lessThan(0));
      final upwardOffset = controller.offset;
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      expect(controller.offset, lessThan(upwardOffset));
      expect(matrix().entry(1, 3), greaterThan(0));
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(matrix().entry(1, 1), closeTo(1, .001));
      expect(matrix().entry(1, 3), closeTo(0, .001));
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('exit fades last bubble but removes its semantics immediately', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(popup(point: const Offset(100, 100), text: '日详情'));
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('日详情'), findsOneWidget);
    await tester.pumpWidget(popup());
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('日详情'), findsOneWidget);
    expect(find.semantics.byLabel('日详情'), findsNothing);
    final opacity = tester
        .widget<FadeTransition>(find.byType(FadeTransition).last)
        .opacity
        .value;
    expect(opacity, greaterThan(0));
    expect(opacity, lessThan(1));
    await tester.pumpAndSettle();
    expect(find.text('日详情'), findsNothing);
    semantics.dispose();
  });

  testWidgets('drag updates position and text without replaying entrance', (
    tester,
  ) async {
    await tester.pumpWidget(popup(point: const Offset(80, 100), text: '周一'));
    await tester.pumpAndSettle();
    final oldPosition = tester.getTopLeft(find.text('周一'));
    await tester.pumpWidget(popup(point: const Offset(150, 140), text: '周二'));
    expect(find.text('周一'), findsNothing);
    expect(find.text('周二'), findsOneWidget);
    expect(tester.getTopLeft(find.text('周二')), isNot(oldPosition));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion has no retained exit or entrance animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      popup(point: const Offset(100, 100), text: '信息', reduced: true),
    );
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(popup(reduced: true));
    expect(find.text('信息'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('rapid exit and re-entry keeps only the current snapshot', (
    tester,
  ) async {
    await tester.pumpWidget(popup(point: const Offset(100, 100), text: '旧信息'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(popup());
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(popup(point: const Offset(160, 100), text: '新信息'));
    await tester.pumpAndSettle();
    expect(find.text('旧信息'), findsNothing);
    expect(find.text('新信息'), findsOneWidget);
    final rect = tester.getRect(find.byType(GlassFloatingSurface));
    final bounds = tester.getRect(find.byType(GlassInformationPopup));
    expect(rect.left, greaterThanOrEqualTo(bounds.left));
    expect(rect.right, lessThanOrEqualTo(bounds.right));
    expect(tester.takeException(), isNull);
  });
}
