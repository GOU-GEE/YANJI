import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/navigation_capture.dart';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('glass at screen bottom samples the backdrop at screen bottom', (
    tester,
  ) async {
    expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
    final lensKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xffd42a2a)),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 500,
                child: ColoredBox(color: Color(0xff2468d4)),
              ),
              Positioned(
                left: 50,
                right: 50,
                bottom: 60,
                height: 72,
                child: LiquidGlassLayer(
                  settings: const LiquidGlassSettings(
                    refractiveIndex: 1,
                    thickness: 12,
                    blur: 0,
                    chromaticAberration: 0,
                    lightIntensity: 0,
                    ambientStrength: 0,
                    saturation: 1,
                    glassColor: Colors.transparent,
                  ),
                  child: LiquidGlass(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 32),
                    child: SizedBox.expand(key: lensKey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tester.pump();

    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    final png = await captureNavigationFrame(
      binding,
      tester,
      'backdrop-bottom-alignment',
    );
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
    final frame = await codec.getNextFrame();
    final bytes = (await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final center = tester.getRect(find.byKey(lensKey)).center;
    final dpr = tester.view.devicePixelRatio;
    final x = (center.dx * dpr).round();
    final y = (center.dy * dpr).round();
    final p = (y * frame.image.width + x) * 4;
    final red = bytes[p];
    final blue = bytes[p + 2];
    debugPrint('BACKDROP_ALIGNMENT center=($x,$y) red=$red blue=$blue');
    expect(blue, greaterThan(red + 80));
    frame.image.dispose();
    codec.dispose();
  });
}
