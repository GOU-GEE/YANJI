import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/navigation_capture.dart';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('rim magnifies immediately and tapers to a clear center', (
    tester,
  ) async {
    expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
    await binding.convertFlutterSurfaceToImage();
    final mode = ValueNotifier(0);
    const lensKey = Key('edge-optics-lens');
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
                    child: CustomPaint(painter: _CoordinateBackdrop()),
                  ),
                  Positioned(
                    left: 100,
                    top: 50,
                    width: 96,
                    height: 72,
                    child: ValueListenableBuilder(
                      valueListenable: mode,
                      builder: (_, value, _) => LiquidGlassLayer(
                        settings: LiquidGlassSettings(
                          thickness: 14,
                          refractiveIndex: value == 0 ? 1 : 1.62,
                          edgeMagnification: value == 2,
                          highQualitySampling: true,
                          blur: 0,
                          lightIntensity: 0,
                          ambientStrength: 0,
                          saturation: 1,
                          chromaticAberration: 0,
                        ),
                        child: const LiquidGlass(
                          shape: LiquidRoundedSuperellipse(borderRadius: 24),
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
    Future<(ui.Image, Uint8List)> capture(String name) async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 180));
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

    final baseline = await capture('coordinate-baseline');
    mode.value = 1;
    final old = await capture('coordinate-old-ramp');
    mode.value = 2;
    final next = await capture('coordinate-edge-magnification');
    final box = tester.getRect(find.byKey(lensKey));
    final dpr = tester.view.devicePixelRatio;
    double green((ui.Image, Uint8List) frame, double depth) {
      final y = ((box.top + depth) * dpr).round();
      var sum = 0;
      var count = 0;
      for (
        var x = ((box.center.dx - 8) * dpr).round();
        x < (box.center.dx + 8) * dpr;
        x++
      ) {
        sum += frame.$2[(y * frame.$1.width + x) * 4 + 1];
        count++;
      }
      return sum / count;
    }

    double shift((ui.Image, Uint8List) frame, double depth) =>
        green(frame, depth) - green(baseline, depth);
    final oldEdge = shift(old, 1.5);
    final newEdge = shift(next, 1.5);
    final inner = shift(next, 8);
    final center = shift(next, 24);
    debugPrint(
      'EDGE_PROFILE oldEdge=$oldEdge newEdge=$newEdge inner=$inner center=$center DPR=$dpr',
    );
    expect(newEdge, greaterThan(oldEdge + 3));
    expect(newEdge, greaterThan(inner + 2));
    expect(center.abs(), lessThan(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    mode.dispose();
    for (final frame in [baseline, old, next]) {
      frame.$1.dispose();
    }
  });
}

class _CoordinateBackdrop extends CustomPainter {
  const _CoordinateBackdrop();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xff402040), Color(0xff40e040)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _CoordinateBackdrop oldDelegate) => false;
}
