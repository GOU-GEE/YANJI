import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/glass/navigation_dock_transition.dart';
import 'package:yanji/design/yanji_theme.dart';

import 'support/navigation_capture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('live backdrop throughout dock entry and exit on device', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
    final metrics = <Map<String, Object>>[];
    final dpr = tester.view.devicePixelRatio;
    Future<(int, Uint8List)> capture(String name) async {
      final png = await captureNavigationFrame(binding, tester, name);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
      final image = (await codec.getNextFrame()).image;
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final width = image.width;
      image.dispose();
      codec.dispose();
      return (width, data);
    }

    for (final dark in [false, true]) {
      for (final vertical in [false, true]) {
        Future<void> show(double visibility, bool sample) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: yanjiThemeFor(dark ? Brightness.dark : Brightness.light),
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _Grid(dark))),
                    Center(
                      child: NavigationDockFrame(
                        visibility: visibility,
                        vertical: vertical,
                        edgeInset: 12,
                        child: LiquidNavigationDock(
                          selected: 2,
                          vertical: vertical,
                          refractBackdrop: sample,
                          onSelected: (_) {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (sample) {
            for (var i = 0; i < 60; i++) {
              if (find
                  .byWidgetPredicate(
                    (w) => w is Semantics && w.properties.value == '液态玻璃',
                  )
                  .evaluate()
                  .isNotEmpty) {
                return;
              }
              await Future<void>.delayed(const Duration(milliseconds: 50));
              await tester.pump();
            }
            fail('Glass not ready');
          }
        }

        for (final progress in [.35, .7, 1.0]) {
          final name =
              '${dark ? 'dark' : 'light'}-'
              '${vertical ? 'side' : 'bottom'}-${(progress * 100).round()}';
          // Same geometry and background, with the old no-sampling material.
          await show(progress, false);
          final reference = await capture('$name-no-sampling');
          await show(progress, true);
          final actual = await capture('$name-live-glass');
          final rect = tester.getRect(find.byKey(const Key('navigation-dock')));
          var sum = 0.0, count = 0;
          // Exclude the glyphs/selection: compare only a narrow material strip.
          final strip = vertical
              ? Rect.fromLTWH(
                  rect.left + rect.width * .18,
                  rect.top + rect.height * .12,
                  3,
                  rect.height * .4,
                )
              : Rect.fromLTWH(
                  rect.left + rect.width * .12,
                  rect.top + rect.height * .18,
                  rect.width * .4,
                  3,
                );
          for (
            var y = (strip.top * dpr).ceil();
            y < (strip.bottom * dpr).floor();
            y++
          ) {
            for (
              var x = (strip.left * dpr).ceil();
              x < (strip.right * dpr).floor();
              x++
            ) {
              final offset = (y * actual.$1 + x) * 4;
              for (var c = 0; c < 3; c++) {
                sum += (actual.$2[offset + c] - reference.$2[offset + c]).abs();
                count++;
              }
            }
          }
          final delta = sum / count;
          metrics.add({'frame': name, 'backdropPixelDifference': delta});
          expect(
            delta,
            greaterThan(3),
            reason: 'Page sampling absent at intermediate frame $name',
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
    binding.reportData ??= {};
    binding.reportData!['visibilityFrames'] = metrics;
    await tester.pumpWidget(const SizedBox());
  });
}

class _Grid extends CustomPainter {
  const _Grid(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(
      dark ? const Color(0xff101820) : Colors.white,
      BlendMode.src,
    );
    final paint = Paint()..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 12) {
      paint.color = dark ? const Color(0xff77b5cf) : const Color(0xff163952);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 14) {
      paint.color = dark ? const Color(0xffcb9f86) : const Color(0xffaf4b34);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_Grid oldDelegate) => dark != oldDelegate.dark;
}
