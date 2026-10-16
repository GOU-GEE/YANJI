import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:yanji/design/glass/glass_notice.dart';
import 'package:yanji/design/glass/glass_segmented_control.dart';

void main() {
  for (final direction in [
    const Offset(-120, 0),
    const Offset(120, 0),
    const Offset(0, -120),
  ]) {
    testWidgets('top notice clears with $direction swipe', (tester) async {
      late BuildContext pageContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pageContext = context;
                return const Text('page');
              },
            ),
          ),
        ),
      );
      GlassNotice.show(pageContext, '滑动清除');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final drag = await tester.startGesture(
        tester.getCenter(find.text('滑动清除')),
      );
      await drag.moveBy(direction * .25);
      await tester.pump();
      await drag.moveBy(direction * .75);
      await drag.up();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('滑动清除'), findsNothing);
    });
  }

  testWidgets('range bubble stretches while held and settles on release', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              height: 42,
              child: StatefulBuilder(
                builder: (context, setState) => GlassSegmentedControl(
                  labels: const ['日', '周', '月', '总', '自定义'],
                  selected: selected,
                  onSelected: (index) {
                    setState(() => selected = index);
                    return true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassLayer), findsNothing);
    final transform = find.byKey(const Key('range-glass-transform'));
    final origin = tester.getCenter(find.text('日'));
    final drag = await tester.startGesture(origin);
    await drag.moveBy(const Offset(30, 0));
    await tester.pump();
    await drag.moveBy(const Offset(56, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LiquidGlassLayer), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    final held = tester.widget<Transform>(transform).transform;
    expect(held.entry(0, 0), greaterThan(1.1));
    expect(held.entry(1, 1), greaterThan(1.15));
    final outer = tester
        .widget<Transform>(find.byKey(const Key('glass-elastic-transform')))
        .transform;
    expect(outer.entry(0, 3), greaterThan(0));
    await drag.up();
    await tester.pumpAndSettle();
    expect(selected, 1);
    final settled = tester.widget<Transform>(transform).transform;
    expect(settled.entry(0, 0), closeTo(1, .01));
  });

  testWidgets('top glass notice allows drag and returns after idle', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const Text('page');
            },
          ),
        ),
      ),
    );
    GlassNotice.show(pageContext, '已完成同步');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('已完成同步'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    final notice = tester.getRect(find.text('已完成同步'));
    expect(notice.top, lessThan(150));
    final drag = await tester.startGesture(
      tester.getCenter(find.text('已完成同步')),
    );
    await drag.moveBy(const Offset(28, 0));
    await tester.pump();
    final matrix = tester
        .widget<Transform>(find.byKey(const Key('glass-elastic-transform')))
        .transform;
    expect(matrix.entry(0, 3), greaterThan(0));
    await drag.up();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('已完成同步'), findsNothing);
  });

  testWidgets('downward pull stays near the top and springs back', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const Text('page');
            },
          ),
        ),
      ),
    );
    GlassNotice.show(pageContext, '下拉通知');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final notice = find.text('下拉通知');
    final originalTop = tester.getTopLeft(notice).dy;
    final drag = await tester.startGesture(tester.getCenter(notice));
    await drag.moveBy(const Offset(0, 30));
    await tester.pump();
    await drag.moveBy(const Offset(0, 600));
    await tester.pump();
    expect(tester.getTopLeft(notice).dy - originalTop, lessThan(24));
    await drag.up();
    await tester.pumpAndSettle(const Duration(milliseconds: 180));
    expect(notice, findsOneWidget);
    expect(tester.getTopLeft(notice).dy, closeTo(originalTop, 1));
  });
}
