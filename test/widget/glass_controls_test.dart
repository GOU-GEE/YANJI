import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:yanji/design/glass/glass_controls.dart';
import 'package:yanji/design/glass/glass_date_range_picker.dart';
import 'package:yanji/design/yanji_theme.dart';

void main() {
  for (final direction in [
    const Offset(-120, 0),
    const Offset(120, 0),
    const Offset(0, -120),
  ]) {
    testWidgets('glass dialog dismisses on $direction swipe', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const GlassAlertDialog(
                    title: Text('测试弹窗'),
                    content: Text('可以滑动关闭'),
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      final drag = await tester.startGesture(
        tester.getCenter(find.text('测试弹窗')),
      );
      await drag.moveBy(direction * .25);
      await tester.pump();
      await drag.moveBy(direction * .75);
      await drag.up();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('测试弹窗'), findsNothing);
    });
  }

  testWidgets('downward swipe leaves glass dialog open', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const GlassAlertDialog(title: Text('测试弹窗')),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    final drag = await tester.startGesture(tester.getCenter(find.text('测试弹窗')));
    await drag.moveBy(const Offset(0, 30));
    await drag.moveBy(const Offset(0, 90));
    await drag.up();
    await tester.pumpAndSettle();
    expect(find.text('测试弹窗'), findsOneWidget);
  });

  testWidgets('date wheel drag does not dismiss its dialog', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showGlassDateRangePicker(
                context: context,
                firstDate: DateTime(2026),
                lastDate: DateTime(2026, 1, 31),
                initialDateRange: DateTimeRange(
                  start: DateTime(2026, 1, 5),
                  end: DateTime(2026, 1, 10),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('custom-start-date')),
      const Offset(0, -110),
    );
    await tester.pumpAndSettle();
    expect(find.text('自定义日期'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog action buttons share a minimum size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              GlassTextButton(onPressed: () {}, child: const Text('取消')),
              GlassFilledButton(onPressed: () {}, child: const Text('确定')),
            ],
          ),
        ),
      ),
    );
    final cancel = tester.getSize(find.byType(GlassTextButton));
    final confirm = tester.getSize(find.byType(GlassFilledButton));
    expect(cancel, confirm);
    expect(cancel.width, greaterThanOrEqualTo(88));
    expect(cancel.height, greaterThanOrEqualTo(44));
  });

  testWidgets('flat glass buttons avoid a backdrop shader', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: yanjiThemeFor(Brightness.light),
        home: Scaffold(
          body: GlassFilledButton(onPressed: () {}, child: const Text('确定')),
        ),
      ),
    );
    expect(find.byType(LiquidGlassLayer), findsNothing);
    expect(find.byType(GlassElastic), findsOneWidget);
  });

  testWidgets('held edge bends toward the side being pulled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 60,
              child: GlassElastic(child: ColoredBox(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
    final area = tester.getRect(find.byType(GlassElastic));
    final left = await tester.startGesture(
      Offset(area.left + 20, area.center.dy),
    );
    await left.moveBy(const Offset(0, 32));
    await tester.pump();
    final transform = find.byKey(const Key('glass-elastic-transform'));
    expect(
      tester.widget<Transform>(transform).transform.entry(1, 0),
      lessThan(0),
    );
    await left.up();
    await tester.pumpAndSettle();
    final right = await tester.startGesture(
      Offset(area.right - 20, area.center.dy),
    );
    await right.moveBy(const Offset(0, 32));
    await tester.pump();
    expect(
      tester.widget<Transform>(transform).transform.entry(1, 0),
      greaterThan(0),
    );
    await right.up();
  });
  testWidgets('held glass button follows a drag and springs back', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: yanjiThemeFor(Brightness.light),
        home: Scaffold(
          body: Center(
            child: GlassOutlinedButton(
              onPressed: () => taps++,
              child: const Text('操作'),
            ),
          ),
        ),
      ),
    );
    final button = find.text('操作');
    final materialButton = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(
      materialButton.style!.side!.resolve({WidgetState.pressed}),
      BorderSide.none,
    );
    expect(
      materialButton.style!.overlayColor!.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
    final transform = find.byKey(const Key('glass-elastic-transform'));
    final drag = await tester.startGesture(tester.getCenter(button));
    await drag.moveBy(const Offset(36, -12));
    await tester.pump();
    final held = tester.widget<Transform>(transform).transform;
    expect(held.entry(0, 3), greaterThan(0));
    expect(held.entry(1, 3), lessThan(0));
    expect(held.entry(0, 0), greaterThan(1));
    expect(taps, 0);
    await drag.up();
    await tester.pumpAndSettle();
    final settled = tester.widget<Transform>(transform).transform;
    expect(settled.entry(0, 3), closeTo(0, .01));
    expect(settled.entry(1, 3), closeTo(0, .01));
    expect(settled.entry(0, 0), closeTo(1, .01));
    await tester.tap(button);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accessible reduced motion keeps glass controls stable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: GlassTextButton(onPressed: () {}, child: const Text('操作')),
            ),
          ),
        ),
      ),
    );
    final drag = await tester.startGesture(tester.getCenter(find.text('操作')));
    await drag.moveBy(const Offset(30, 0));
    await tester.pump();
    final matrix = tester
        .widget<Transform>(find.byKey(const Key('glass-elastic-transform')))
        .transform;
    expect(matrix.entry(0, 3), 0);
    expect(matrix.entry(0, 0), 1);
    await drag.up();
  });
}
