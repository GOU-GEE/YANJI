import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/yanji_motion.dart';
import 'package:yanji/features/shared.dart';

void main() {
  Widget frame(Widget child, {bool reduced = false, bool accessible = false}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduced,
            accessibleNavigation: accessible,
          ),
          child: Scaffold(body: child),
        ),
      );

  testWidgets('outgoing text cannot be tapped or read by accessibility', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    Widget content(String value) => frame(
      MotionSwap(
        identity: value,
        child: TextButton(onPressed: () => taps++, child: Text(value)),
      ),
    );
    await tester.pumpWidget(content('旧状态'));
    await tester.pumpWidget(content('新状态'));
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.text('旧状态'), findsOneWidget);
    expect(find.bySemanticsLabel('旧状态'), findsNothing);
    expect(find.bySemanticsLabel('新状态'), findsOneWidget);
    await tester.tap(find.text('新状态'));
    expect(taps, 1);
    await tester.pumpAndSettle();
    expect(find.text('旧状态'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final accessible in [false, true]) {
    testWidgets('reduced motion changes text immediately: $accessible', (
      tester,
    ) async {
      Widget content(String value) => frame(
        MotionSwap(identity: value, child: Text(value)),
        reduced: !accessible,
        accessible: accessible,
      );
      await tester.pumpWidget(content('暂停'));
      await tester.pumpWidget(content('继续'));
      expect(find.text('暂停'), findsNothing);
      expect(find.text('继续'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  }

  testWidgets('same identity does not replay the text transition', (
    tester,
  ) async {
    Widget content() =>
        frame(const MotionSwap(identity: 'stable', child: Text('稳定文字')));
    await tester.pumpWidget(content());
    await tester.pumpWidget(content());
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('稳定文字'), findsOneWidget);
  });

  testWidgets('list handles rapid insertion removal and reorder', (
    tester,
  ) async {
    Widget content(List<String> ids) => frame(
      MotionList(
        children: [
          for (final id in ids)
            SizedBox(key: ValueKey(id), height: 48, child: Text(id)),
        ],
      ),
    );
    await tester.pumpWidget(content(['a', 'b']));
    await tester.pumpWidget(content(['b', 'c']));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(content(['c', 'a', 'b']));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(content(['b']));
    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(find.text('c'), findsNothing);
    expect(find.text('b'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(content([]));
    await tester.pumpAndSettle();
    expect(find.text('b'), findsNothing);
  });

  testWidgets('removed list rows are immediately excluded from semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    Widget content(bool present) => frame(
      MotionList(
        children: [
          if (present)
            const SizedBox(
              key: ValueKey('row'),
              height: 48,
              child: Text('已删除任务'),
            ),
        ],
      ),
    );
    await tester.pumpWidget(content(true));
    await tester.pumpWidget(content(false));
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.bySemanticsLabel('已删除任务'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('已删除任务'), findsNothing);
    semantics.dispose();
  });
  testWidgets('enabling reduced motion cancels a pending list insertion', (
    tester,
  ) async {
    Widget content(List<String> ids, bool reduced) => frame(
      MotionList(
        children: [
          for (final id in ids)
            SizedBox(key: ValueKey(id), height: 48, child: Text(id)),
        ],
      ),
      reduced: reduced,
    );
    await tester.pumpWidget(content(['a'], false));
    await tester.pumpWidget(content(['a', 'b'], false));
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(content(['a', 'b'], true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('b'), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('b'))).height, 48);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root pages restore their own scroll position after a switch', (
    tester,
  ) async {
    final bucket = PageStorageBucket();
    Widget page(String title) => frame(
      RootPageScrollMemory(
        bucket: bucket,
        child: PageBody(
          title: title,
          showTitle: false,
          children: List.generate(
            40,
            (i) => SizedBox(height: 60, child: Text('$title-$i')),
          ),
        ),
      ),
    );
    double offset() => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;
    await tester.pumpWidget(page('今天'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();
    final todayOffset = offset();
    expect(todayOffset, greaterThan(200));
    await tester.pumpWidget(page('数据'));
    expect(offset(), 0);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    final statisticsOffset = offset();
    await tester.pumpWidget(page('今天'));
    expect(offset(), closeTo(todayOffset, .1));
    await tester.pumpWidget(page('数据'));
    expect(offset(), closeTo(statisticsOffset, .1));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'rapid return to the original status exposes only one semantic action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      Widget content(String value) => frame(
        MotionSwap(
          identity: value,
          child: TextButton(onPressed: () {}, child: Text(value)),
        ),
      );
      await tester.pumpWidget(content('继续'));
      await tester.pumpWidget(content('暂停'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(content('继续'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.bySemanticsLabel('继续'), findsOneWidget);
      expect(find.bySemanticsLabel('暂停'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('继续'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
  testWidgets('a taller outgoing form keeps its natural height during exit', (
    tester,
  ) async {
    Widget content(int count) => frame(
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 320,
          child: MotionSwap(
            identity: count,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                count,
                (i) => SizedBox(height: 60, child: Text('字段 $i')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(content(8));
    await tester.pumpWidget(content(2));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('字段 7'), findsNothing);
  });
}
