import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/design/glass/coolapk_navigation_style.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/yanji_theme.dart';
import 'package:yanji/main.dart' as app;

import 'coolapk_navigation_test.dart' show GlyphProbe;
import 'support/navigation_capture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('lens contracts captured bar and refracts isolated glyphs', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    final press = ValueNotifier(0.0);
    Rect? endpointThumb;
    const key = Key('lens-bar-probe');
    Future<(int, Uint8List)> capture(String name) async {
      await tester.pumpAndSettle();
      final bytes = await captureNavigationFrame(binding, tester, name);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final image = (await codec.getNextFrame()).image;
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final width = image.width;
      image.dispose();
      codec.dispose();
      return (width, rgba);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xff0c3c96),
          body: Center(
            child: SizedBox(
              key: key,
              width: 300,
              height: 56,
              child: ValueListenableBuilder(
                valueListenable: press,
                builder: (_, v, _) => CoolapkNavigationSurface(
                  thumb:
                      endpointThumb ??
                      Rect.fromLTWH(
                        100,
                        v == 0 ? 2.08 : -2,
                        100,
                        v == 0 ? 51.84 : 60,
                      ),
                  press: v,
                  capability: NavigationGlassCapability.liquid,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.pump();
      if (find
          .byWidgetPredicate(
            (w) => w is Semantics && w.properties.value == '液态玻璃',
          )
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final normal = await capture('boundary-normal');
    press.value = 1;
    final held = await capture('boundary-held');
    final rect = tester.getRect(find.byKey(key)),
        dpr = tester.view.devicePixelRatio;
    int height((int, Uint8List) frame, double x) {
      var result = 0;
      for (
        var y = ((rect.top - 5) * dpr).ceil();
        y < ((rect.bottom + 5) * dpr).floor();
        y++
      ) {
        if (frame.$2[(y * frame.$1 + (x * dpr).floor()) * 4] > 130) result++;
      }
      return result;
    }

    final outside = height(held, rect.left + 40),
        inside = height(held, rect.center.dx);
    final unchanged = height(normal, rect.left + 40);
    expect((outside - unchanged).abs(), lessThanOrEqualTo(2));
    expect(
      inside,
      lessThan(outside - 4 * dpr),
      reason: 'Only the bar captured inside the lens must bow inward',
    );
    binding.reportData!.addAll({
      'bar_outside_height_px': outside,
      'bar_inside_height_px': inside,
      'dpr': dpr,
    });
    debugPrint('LENS_BOUNDARY outside=$outside inside=$inside dpr=$dpr');

    (int, int) verticalBounds((int, Uint8List) frame, double x) {
      final hits = <int>[];
      for (
        var y = ((rect.top - 8) * dpr).ceil();
        y < ((rect.bottom + 8) * dpr).floor();
        y++
      ) {
        if (frame.$2[(y * frame.$1 + (x * dpr).floor()) * 4] > 130) hits.add(y);
      }
      expect(hits, isNotEmpty);
      return (hits.first, hits.last);
    }

    final outerBounds = verticalBounds(held, rect.left + 40);
    final symmetry = <Map<String, num>>[];
    for (final dx in [-15.0, 0.0, 15.0]) {
      final innerBounds = verticalBounds(held, rect.center.dx + dx);
      final top = innerBounds.$1 - outerBounds.$1;
      final bottom = outerBounds.$2 - innerBounds.$2;
      expect(top, greaterThan(4));
      expect(bottom, greaterThan(4));
      expect(
        (top - bottom).abs(),
        lessThanOrEqualTo(1),
        reason: 'Top and bottom must contract equally at x=$dx',
      );
      symmetry.add({
        'x_dp': dx,
        'top_inset_px': top,
        'bottom_inset_px': bottom,
      });
    }
    binding.reportData!['vertical_symmetry'] = symmetry;

    int capBoundary((int, Uint8List) frame, bool left) {
      final y = (rect.center.dy * dpr).floor();
      final hits = <int>[];
      for (
        var x = ((rect.left - 15) * dpr).ceil();
        x < ((rect.right + 15) * dpr).floor();
        x++
      ) {
        if (frame.$2[(y * frame.$1 + x) * 4] > 130) hits.add(x);
      }
      expect(hits, isNotEmpty);
      return left ? hits.first : hits.last;
    }

    final caps = <Map<String, num>>[];
    for (final left in [true, false]) {
      press.value = 0;
      await tester.pump();
      endpointThumb = Rect.fromLTWH(left ? -10 : 190, -2, 120, 60);
      press.value = 1;
      final frame = await capture(left ? 'boundary-left' : 'boundary-right');
      final boundary = capBoundary(frame, left);
      final contraction = left
          ? boundary - rect.left * dpr
          : rect.right * dpr - boundary - 1;
      final lensGap = contraction + 10 * dpr;
      expect(contraction, greaterThan(2 * dpr));
      expect(
        lensGap,
        greaterThan(4 * dpr),
        reason: 'The captured end cap must be visible inside the lens',
      );
      caps.add({
        'side': left ? 0 : 1,
        'cap_inset_px': contraction,
        'lens_to_cap_gap_px': lensGap,
      });
    }
    expect(
      (caps.first['cap_inset_px']! - caps.last['cap_inset_px']!).abs(),
      lessThanOrEqualTo(2),
    );
    binding.reportData!['endpoint_caps'] = caps;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SizedBox(
              width: 300,
              height: 56,
              child: ValueListenableBuilder(
                valueListenable: press,
                builder: (_, v, _) => CoolapkNavigationSurface(
                  thumb: const Rect.fromLTWH(80, -2, 100, 60),
                  press: v,
                  capability: NavigationGlassCapability.liquid,
                  child: CustomPaint(painter: GlyphProbe()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    press.value = 0;
    final raw = await capture('glyphs-normal');
    press.value = 1;
    final filtered = await capture('glyphs-refracted');
    var ink = 0;
    for (var i = 0; i < raw.$2.length; i += 4) {
      if ((raw.$2[i] < 120) != (filtered.$2[i] < 120)) ink++;
    }
    expect(ink, greaterThan(30));
    binding.reportData!['refracted_ink_pixels'] = ink;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: YanJiColors.scheme(Brightness.light)),
        home: Scaffold(
          backgroundColor: const Color(0xfff1f2f5),
          body: Center(
            child: LiquidNavigationDock(
              selected: 0,
              vertical: false,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await capture('dock-rest');
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('liquid-indicator'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await capture('dock-held');
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(22, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await capture('dock-slide-$i');
    }
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    press.dispose();

    await app.main();
    final today = find.byKey(const ValueKey('nav-/'));
    for (var i = 0; i < 1500 && today.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(today, findsOneWidget);
    await capture('app-rest');
    final liveGesture = await tester.startGesture(tester.getCenter(today));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await capture('app-held');
    for (var i = 0; i < 8; i++) {
      await liveGesture.moveBy(const Offset(22, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await capture('app-slide-$i');
    }
    await liveGesture.up();
    await tester.pumpAndSettle();
    await capture('app-released');
    await tester.tap(find.byKey(const ValueKey('nav-/profile')));
    await tester.pumpAndSettle();
    final rightGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('nav-/profile'))),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await capture('app-right-held');
    await rightGesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
