import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/navigation_capture.dart';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'liquid_glass_visual_test.dart' as app_visual;

void main() {
  app_visual.main();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final inner in [false, true]) {
    testWidgets(
      inner
          ? 'independent indicator refracts the outer glass backdrop'
          : 'optical rim displaces backdrop pixels without blur or lighting',
      (tester) async {
        expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
        await binding.convertFlutterSurfaceToImage();
        final index = ValueNotifier(1.0);
        final lensKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 180,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _Backdrop()),
                      ),
                      if (inner)
                        Positioned(
                          left: 20,
                          top: 55,
                          width: 260,
                          height: 68,
                          child: LiquidGlassLayer(
                            settings: const LiquidGlassSettings(
                              thickness: 12,
                              refractiveIndex: 1.45,
                              blur: 1.2,
                              chromaticAberration: 0,
                              lightIntensity: 0,
                              ambientStrength: 0,
                              saturation: 1,
                              glassColor: Colors.transparent,
                            ),
                            child: const LiquidGlass(
                              shape: LiquidRoundedSuperellipse(
                                borderRadius: 32,
                              ),
                              child: SizedBox.expand(),
                            ),
                          ),
                        ),
                      Positioned(
                        left: inner ? 118 : 20,
                        top: inner ? 61 : 55,
                        width: inner ? 64 : 260,
                        height: inner ? 56 : 68,
                        child: ValueListenableBuilder<double>(
                          valueListenable: index,
                          builder: (context, n, _) => LiquidGlassLayer(
                            settings: LiquidGlassSettings(
                              thickness: inner ? 14 : 12,
                              refractiveIndex: n,
                              blur: 0,
                              chromaticAberration: 0,
                              lightIntensity: 0,
                              ambientStrength: 0,
                              saturation: 1,
                              glassColor: Colors.transparent,
                              highQualitySampling: inner,
                            ),
                            child: LiquidGlass(
                              shape: LiquidRoundedSuperellipse(
                                borderRadius: inner ? 24 : 32,
                              ),
                              child: SizedBox.expand(key: lensKey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<(ui.Image, Uint8List)> capture(String name) async {
          await tester.pumpAndSettle();
          await Future<void>.delayed(const Duration(milliseconds: 150));
          await tester.pump();
          final png = await captureNavigationFrame(binding, tester, name);
          final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
          final frame = await codec.getNextFrame();
          codec.dispose();
          final data = await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          return (frame.image, data!.buffer.asUint8List());
        }

        final baseline = await capture(
          '${inner ? 'indicator' : 'optical'}-index-1-no-blur',
        );
        index.value = inner ? 1.62 : 1.45;
        final refracted = await capture(
          '${inner ? 'indicator-index-1.62' : 'optical-index-1.45'}-no-blur',
        );
        final dpr = tester.view.devicePixelRatio;
        final box = tester.getRect(find.byKey(lensKey));
        // Straight upper rim excludes rounded corners. Center is outside the rim.
        final rim = Rect.fromLTRB(
          box.left + (inner ? 24 : 40),
          box.top + 2,
          box.right - (inner ? 24 : 40),
          box.top + 11,
        );
        final center = Rect.fromLTRB(
          box.left + (inner ? 24 : 40),
          box.top + (inner ? 18 : 22),
          box.right - (inner ? 24 : 40),
          box.bottom - (inner ? 18 : 22),
        );
        double changedFraction(Rect region) {
          var changed = 0, total = 0;
          for (
            var y = (region.top * dpr).ceil();
            y < region.bottom * dpr;
            y++
          ) {
            for (
              var x = (region.left * dpr).ceil();
              x < region.right * dpr;
              x++
            ) {
              final offset = (y * baseline.$1.width + x) * 4;
              var difference = 0;
              for (var c = 0; c < 3; c++) {
                difference +=
                    (baseline.$2[offset + c] - refracted.$2[offset + c]).abs();
              }
              if (difference > 50) changed++;
              total++;
            }
          }
          return changed / total;
        }

        final rimChange = changedFraction(rim);
        final centerChange = changedFraction(center);
        debugPrint(
          'OPTICAL_PIXEL_CHECK inner=$inner rim=$rimChange center=$centerChange DPR=$dpr',
        );
        // Tint, blur, illumination and dispersion are zero in both captures: this
        // difference can only come from the background sampling coordinates.
        expect(rimChange, greaterThan(.12));
        expect(centerChange, lessThan(.02));
        expect(tester.takeException(), isNull);
        baseline.$1.dispose();
        refracted.$1.dispose();
        await tester.pumpWidget(const SizedBox());
        index.dispose();
      },
    );
  }
}

class _Backdrop extends CustomPainter {
  const _Backdrop();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xfffafafa),
    );
    final line = Paint()..strokeWidth = 1.5;
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        line..color = const Color(0xff29473d),
      );
    }
    for (var x = 0.0; x < size.width; x += 12) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        line..color = const Color(0xff8f5353),
      );
    }
    final text = TextPainter(
      text: const TextSpan(
        text: '边缘折射  ABC 123  背景采样',
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    text.paint(canvas, const Offset(12, 58));
  }

  @override
  bool shouldRepaint(_Backdrop oldDelegate) => false;
}
