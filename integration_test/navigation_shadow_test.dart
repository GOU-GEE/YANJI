import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/design/glass/coolapk_navigation_style.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/yanji_theme.dart';

import 'support/navigation_capture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('lens refracts the bar shadow without shadow feedback', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
    const probe = Key('shadow-probe');
    final metrics = <Map<String, Object>>[];
    Future<(int, Uint8List)> capture(String name) async {
      final png = await captureNavigationFrame(binding, tester, name);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
      final image = (await codec.getNextFrame()).image;
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      final width = image.width;
      image.dispose();
      codec.dispose();
      return (width, bytes);
    }

    for (final vertical in [false, true]) {
      for (final dark in [false, true]) {
        final size = vertical ? const Size(64, 232) : const Size(272, 56);
        final scale = 1 + 16 / (vertical ? size.height : size.width);
        final cross = (size.shortestSide - 8) * 1.08;
        final thumb = Rect.fromCenter(
          center: size.center(Offset.zero),
          width:
              (vertical ? cross : (size.width - 8) / 3) *
              CoolapkNavigationStyle.pressedHeightRatio,
          height:
              (vertical ? (size.height - 8) / 3 : cross) *
              CoolapkNavigationStyle.pressedHeightRatio,
        );
        final name =
            '${vertical ? 'side' : 'bottom'}-${dark ? 'dark' : 'light'}';
        Future<void> show(bool shadow) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: yanjiThemeFor(dark ? Brightness.dark : Brightness.light),
              home: Scaffold(
                backgroundColor: dark ? const Color(0xff1d1d1d) : Colors.white,
                body: Center(
                  child: SizedBox.fromSize(
                    key: probe,
                    size: size,
                    child: CoolapkNavigationSurface(
                      thumb: thumb,
                      press: 1,
                      barScale: scale,
                      capability: NavigationGlassCapability.liquid,
                      barShadow: shadow
                          ? NavigationBarShadow(
                              Color(dark ? 0x29000000 : 0x18000000),
                              scale,
                            )
                          : null,
                      outsideShadow: NavigationLensShadow(thumb, 1),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await show(false);
        final before = await capture('$name-without-bar-shadow');
        await show(true);
        final after = await capture('$name-with-bar-shadow');
        final retained = await capture('$name-retained');
        final origin = tester.getTopLeft(find.byKey(probe));
        final dpr = tester.view.devicePixelRatio;
        final lens = RRect.fromRectAndRadius(
          thumb.deflate(1),
          Radius.circular(thumb.shortestSide / 2 - 1),
        );
        var shadowPixels = 0, repeatDifference = 0, samples = 0;
        for (var y = thumb.top.ceil(); y < thumb.bottom.floor(); y++) {
          for (var x = thumb.left.ceil(); x < thumb.right.floor(); x++) {
            if (!lens.contains(Offset(x.toDouble(), y.toDouble()))) continue;
            final i =
                (((origin.dy + y) * dpr).round() * before.$1 +
                    ((origin.dx + x) * dpr).round()) *
                4;
            if (before.$2[i] - after.$2[i] >= 1) shadowPixels++;
            repeatDifference += (after.$2[i] - retained.$2[i]).abs();
            samples++;
          }
        }
        expect(shadowPixels, greaterThan(20), reason: name);
        expect(repeatDifference / samples, lessThan(.25), reason: name);
        final point = vertical ? const Offset(32, 30) : const Offset(40, 28);
        final i =
            (((origin.dy + point.dy) * dpr).round() * before.$1 +
                ((origin.dx + point.dx) * dpr).round()) *
            4;
        expect(after.$2.sublist(i, i + 3), before.$2.sublist(i, i + 3));
        metrics.add({
          'scene': name,
          'refracted_shadow_pixels': shadowPixels,
          'retained_frame_mean_difference': repeatDifference / samples,
          'bar_body_unchanged': true,
        });
        expect(tester.takeException(), isNull);
      }
    }
    binding.reportData!['shadow_scenes'] = metrics;
  });
}
