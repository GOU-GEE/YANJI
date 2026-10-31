import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/glass/navigation_dock_transition.dart';

void main() {
  for (final vertical in [false, true]) {
    testWidgets('glass stays live through motion and reversal: $vertical', (
      tester,
    ) async {
      final hidden = ValueNotifier(false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ValueListenableBuilder(
                valueListenable: hidden,
                builder: (_, value, _) => NavigationDockTransition(
                  hidden: value,
                  vertical: vertical,
                  edgeInset: 12,
                  child: LiquidNavigationDock(
                    selected: 0,
                    vertical: vertical,
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final dock = find.byType(LiquidNavigationDock);
      final original = tester.getRect(dock);
      void expectLive() {
        expect(
          tester.widget<LiquidNavigationDock>(dock).refractBackdrop,
          isTrue,
        );
        expect(
          find.ancestor(of: dock, matching: find.byType(Opacity)),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }

      hidden.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final moving = tester.getRect(dock);
      expectLive();
      expect(moving.width, lessThan(original.width));
      expect(
        vertical ? moving.left < original.left : moving.top > original.top,
        isTrue,
      );
      // Reverse while still moving, without recreating the optical surface.
      final element = tester.element(dock);
      hidden.value = false;
      await tester.pump();
      expect(tester.getRect(dock), moving);
      await tester.pump(const Duration(milliseconds: 50));
      expectLive();
      expect(tester.element(dock), same(element));
      await tester.pumpAndSettle();
      expect(tester.getRect(dock), original);
      hidden.value = true;
      await tester.pumpAndSettle();
      expect(dock, findsNothing);
      hidden.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expectLive();
      await tester.pumpAndSettle();
      expect(tester.getRect(dock), original);
      await tester.pumpWidget(const SizedBox());
      hidden.dispose();
    });
  }
}
