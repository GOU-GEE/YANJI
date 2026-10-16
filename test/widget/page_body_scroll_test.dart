import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/features/shared.dart';

void main() {
  testWidgets('app bar height is counted once with status bar padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(padding: const EdgeInsets.only(top: 24)),
          child: child!,
        ),
        home: const PageBody(
          title: '页面',
          children: [SizedBox(key: Key('first-content'), height: 100)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const Key('first-content'))).dy,
      24 + kToolbarHeight + 12,
    );
    expect(tester.takeException(), isNull);
  });

  for (final hasFooter in [false, true]) {
    testWidgets(
      'wide page scrolls from both empty margins, footer=$hasFooter',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: PageBody(
              title: '边缘滑动测试',
              showTitle: false,
              maxWidth: 720,
              footer: hasFooter ? [const Text('底部说明')] : const [],
              children: [
                for (var i = 0; i < 20; i++)
                  SizedBox(
                    key: ValueKey('row-$i'),
                    height: 100,
                    child: Text('内容 $i'),
                  ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final firstRect = tester.getRect(find.byKey(const ValueKey('row-0')));
        expect(firstRect.left, 264);
        expect(firstRect.right, 936);
        final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
        await tester.dragFrom(const Offset(40, 600), const Offset(0, -250));
        await tester.pumpAndSettle();
        final afterLeft = scroll.position.pixels;
        expect(afterLeft, greaterThan(0));
        await tester.dragFrom(const Offset(1160, 600), const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, greaterThan(afterLeft));
        await tester.dragFrom(const Offset(1160, 300), const Offset(0, 250));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, lessThan(afterLeft + 250));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
