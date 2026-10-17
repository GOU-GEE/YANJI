import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/navigation_capture.dart';

import 'package:yanji/main.dart' as app;
import 'package:yanji/design/glass/liquid_navigation_dock.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('actual routes, scroll memory, keyboard and live glass', (
    tester,
  ) async {
    await app.main();
    final today = find.byKey(const ValueKey('nav-/'));
    for (var i = 0; i < 1500 && today.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(today, findsOneWidget);
    // Check the real IME while Android still serves the original FlutterView.
    await tester.tap(find.text('添加任务'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsWidgets);
    await tester.tap(fields.first);
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    // Real window IME insets. Scaffold clears the body child's MediaQuery inset
    // after resizing, while _AppShell reads the inset above that Scaffold.
    final dock = find.byType(LiquidNavigationDock);
    expect(
      tester.view.viewInsets.bottom / tester.view.devicePixelRatio,
      greaterThan(100),
    );
    final ignoring = find.ancestor(
      of: dock,
      matching: find.byType(IgnorePointer),
    );
    expect(
      ignoring.evaluate().any((e) => (e.widget as IgnorePointer).ignoring),
      isTrue,
    );
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    await captureNavigationFrame(binding, tester, 'app-keyboard-hidden-dock');
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    await captureNavigationFrame(binding, tester, 'app-keyboard-dismissed');
    Future<void> snap(String name) async {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await tester.pump();
      await captureNavigationFrame(binding, tester, name);
    }

    expect(today, findsOneWidget);
    await snap('app-today');
    await tester.tap(find.byKey(const ValueKey('nav-/statistics')));
    await tester.pumpAndSettle();
    await snap('app-statistics');
    await tester.tap(find.byKey(const ValueKey('nav-/profile')));
    await tester.pumpAndSettle();
    await snap('app-profile');
    await tester.tap(today);
    await tester.pumpAndSettle();
    bool dockIgnores() => find
        .ancestor(
          of: find.byType(LiquidNavigationDock),
          matching: find.byType(IgnorePointer),
        )
        .evaluate()
        .any((e) => (e.widget as IgnorePointer).ignoring);
    final scroll = find.byType(Scrollable).first;
    await tester.drag(scroll, const Offset(0, -160));
    await tester.pumpAndSettle();
    await snap('app-scroll-up-dock-visible');
    expect(dockIgnores(), isFalse);
    await tester.drag(scroll, const Offset(0, 100));
    await tester.pumpAndSettle();
    await snap('app-scroll-down-dock-visible');
    expect(dockIgnores(), isFalse);
    // Recover a partially scrolled position, then leave and return. The shell
    // retains its original PageStorageBucket rather than replacing page state.
    final state = tester.state<ScrollableState>(scroll);
    final remembered = state.position.pixels;
    await tester.tap(find.byKey(const ValueKey('nav-/profile')));
    await tester.pumpAndSettle();
    await tester.tap(today);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      closeTo(remembered, .5),
    );
    expect(tester.takeException(), isNull);
  });
}
