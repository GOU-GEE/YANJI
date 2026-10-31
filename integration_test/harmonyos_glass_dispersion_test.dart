import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';
import 'package:yanji/design/glass/coolapk_navigation_style.dart';
import 'package:yanji/design/glass/glass_segmented_control.dart';
import 'package:yanji/design/yanji_theme.dart';

import 'support/navigation_capture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'navigation disperses neutral ink and captures fresh backgrounds',
    (tester) async {
      await binding.convertFlutterSurfaceToImage();
      const probe = Key('dispersion-probe');
      final phase = ValueNotifier(0.0);
      Future<void> show(bool optics) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: ValueListenableBuilder<double>(
                      valueListenable: phase,
                      builder: (_, value, _) => RepaintBoundary(
                        child: CustomPaint(painter: _NeutralGrid(value)),
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      key: probe,
                      width: 272,
                      height: 56,
                      child: CoolapkNavigationSurface(
                        thumb: const Rect.fromLTWH(76, -12, 120, 80),
                        press: 1,
                        capability: NavigationGlassCapability.liquid,
                        optics: optics,
                        decorations: false,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<(ui.Image, Uint8List)> frame(String name) async {
        final png = await captureNavigationFrame(binding, tester, name);
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        return (
          image,
          (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List(),
        );
      }

      await show(false);
      final flat = await frame('dispersion-disabled');
      await show(true);
      final optical = await frame('dispersion-enabled');
      final rect = tester.getRect(find.byKey(probe));
      final dpr = tester.view.devicePixelRatio;
      int dispersed((ui.Image, Uint8List) f) {
        var count = 0;
        for (
          var y = ((rect.top - 8) * dpr).ceil();
          y < (rect.bottom + 8) * dpr;
          y++
        ) {
          for (
            var x = ((rect.center.dx - 58) * dpr).ceil();
            x < (rect.center.dx + 58) * dpr;
            x++
          ) {
            final p = (y * f.$1.width + x) * 4;
            final c = [f.$2[p], f.$2[p + 1], f.$2[p + 2]]..sort();
            if (c.last - c.first > 15) count++;
          }
        }
        return count;
      }

      final neutral = dispersed(flat), colored = dispersed(optical);
      expect(neutral, lessThan(5));
      expect(colored, greaterThan(100));
      phase.value = 7;
      await tester.pumpAndSettle();
      final live = await frame('dispersion-live-backdrop');
      var changed = 0;
      for (
        var y = ((rect.center.dy - 15) * dpr).round();
        y < (rect.center.dy + 15) * dpr;
        y++
      ) {
        for (
          var x = ((rect.center.dx - 30) * dpr).round();
          x < (rect.center.dx + 30) * dpr;
          x++
        ) {
          final p = (y * live.$1.width + x) * 4;
          if ((live.$2[p] - optical.$2[p]).abs() > 12) changed++;
        }
      }
      expect(changed, greaterThan(100));
      binding.reportData!.addAll({
        'dispersion_baseline_pixels': neutral,
        'dispersion_pixels': colored,
        'live_backdrop_changed_pixels': changed,
      });
      for (final f in [flat, optical, live]) {
        f.$1.dispose();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      phase.dispose();
    },
  );

  testWidgets('day week month indicator uses full glass in both themes', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    for (final brightness in Brightness.values) {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: yanjiThemeFor(brightness),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 42,
                child: StatefulBuilder(
                  builder: (_, set) => GlassSegmentedControl(
                    labels: const ['日', '周', '月'],
                    selected: selected,
                    onSelected: (value) {
                      set(() => selected = value);
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
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('日')),
      );
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(105, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await captureNavigationFrame(
        binding,
        tester,
        '${brightness.name}-full-segment-held',
      );
      expect(find.byType(LiquidGlassLayer), findsWidgets);
      expect(find.byType(FakeGlass), findsNothing);
      for (final layer in tester.widgetList<LiquidGlassLayer>(
        find.byType(LiquidGlassLayer),
      )) {
        expect(layer.fake, isFalse);
        expect(layer.settings.chromaticAberration, greaterThan(0));
        expect(layer.settings.edgeMagnification, isTrue);
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected, 1);
      await tester.tap(find.text('月'));
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(tester.takeException(), isNull);
    }
    binding.reportData!['segmented_themes'] = ['dark', 'light'];
  });
}

class _NeutralGrid extends CustomPainter {
  const _NeutralGrid(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.white, BlendMode.src);
    final ink = Paint()..color = Colors.black;
    for (double x = -20 + phase; x < size.width; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 4, size.height), ink);
    }
    for (double y = -20 + phase; y < size.height; y += 16) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 3), ink);
    }
  }

  @override
  bool shouldRepaint(_NeutralGrid old) => old.phase != phase;
}
