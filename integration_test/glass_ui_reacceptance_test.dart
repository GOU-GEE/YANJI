import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:yanji/design/glass/coolapk_navigation_style.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';
import 'package:yanji/design/glass/glass_segmented_control.dart';
import 'package:yanji/features/statistics_page.dart';
import 'package:yanji/main.dart' as app;

import 'harmonyos_full_glass_test.dart' as optics;
import 'support/navigation_capture.dart';

/// Run with YANJI_PREVIEW=true so acceptance never writes the user's database.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  optics.main();
  testWidgets(
    'preview routes keep full glass while dragging and after release',
    (tester) async {
      expect(const bool.fromEnvironment('YANJI_PREVIEW'), isTrue);
      await app.main();
      final today = find.byKey(const ValueKey('nav-/'));
      for (var i = 0; i < 600 && today.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(today, findsOneWidget);
      await binding.convertFlutterSurfaceToImage();
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      Future<void> shot(String name) async {
        await captureNavigationFrame(binding, tester, name);
        expect(tester.takeException(), isNull);
      }

      for (final theme in Brightness.values) {
        tester.platformDispatcher.platformBrightnessTestValue = theme;
        await tester.tap(today);
        await tester.pumpAndSettle();
        await shot('app-${theme.name}-today');
        final data = find.byKey(const ValueKey('nav-/statistics'));
        final start = tester.getCenter(today);
        final end = tester.getCenter(data);
        final drag = await tester.startGesture(start);
        await drag.moveBy(const Offset(24, 0));
        await tester.pump();
        await drag.moveTo(end);
        await tester.pump(const Duration(milliseconds: 450));
        final held = tester.widget<CoolapkNavigationSurface>(
          find.byType(CoolapkNavigationSurface),
        );
        expect(held.capability, NavigationGlassCapability.liquid);
        expect(held.press, greaterThan(.9));
        await shot('app-${theme.name}-navigation-held');
        await drag.up();
        await tester.pumpAndSettle();
        expect(find.byType(StatisticsPage), findsOneWidget);
        final resting = tester.widget<CoolapkNavigationSurface>(
          find.byType(CoolapkNavigationSurface),
        );
        expect(resting.press, lessThan(.01));
        await shot('app-${theme.name}-navigation-released');

        final range = find.byType(GlassSegmentedControl);
        // The real shell restores this page's scroll position across routes.
        // Place the control inside the viewport before inspecting or dragging.
        await Scrollable.ensureVisible(tester.element(range), alignment: .35);
        await tester.pumpAndSettle();
        Finder label(String value) =>
            find.descendant(of: range, matching: find.text(value));
        await tester.tap(label('日'));
        await tester.pumpAndSettle();
        await shot('app-${theme.name}-day');
        final rangeDrag = await tester.startGesture(
          tester.getCenter(label('日')),
        );
        await rangeDrag.moveBy(const Offset(24, 0));
        await tester.pump();
        await rangeDrag.moveTo(tester.getCenter(label('周')));
        await tester.pump(const Duration(milliseconds: 450));
        final layers = find.descendant(
          of: range,
          matching: find.byType(LiquidGlassLayer),
        );
        expect(layers, findsWidgets);
        expect(
          tester.widgetList<LiquidGlassLayer>(layers).every((w) => !w.fake),
          isTrue,
        );
        await shot('app-${theme.name}-range-held');
        await rangeDrag.up();
        await tester.pumpAndSettle();
        expect(tester.widget<GlassSegmentedControl>(range).selected, 1);
        await shot('app-${theme.name}-week');
        await tester.tap(label('月'));
        await tester.pumpAndSettle();
        expect(tester.widget<GlassSegmentedControl>(range).selected, 2);
        await shot('app-${theme.name}-month');
        await tester.tap(find.byKey(const ValueKey('nav-/profile')));
        await tester.pumpAndSettle();
        await shot('app-${theme.name}-profile');
      }
      binding.reportData!['preview_ui_themes'] = ['dark', 'light'];
      binding.reportData!['preview_ui_ranges'] = ['day', 'week', 'month'];
      binding.reportData!['preview_ui_navigation_release_verified'] = true;
    },
  );
}
