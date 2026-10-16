import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/navigation_capture.dart';

import 'package:yanji/design/glass/liquid_glass_quality.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/yanji_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'appearing dock does not sample its own shadow over a blank page',
    (tester) async {
      await binding.convertFlutterSurfaceToImage();
      final visibility = ValueNotifier(0.0);
      await tester.pumpWidget(
        MaterialApp(
          theme: yanjiThemeFor(Brightness.light),
          home: Scaffold(
            body: Center(
              child: ValueListenableBuilder(
                valueListenable: visibility,
                builder: (_, value, _) => Opacity(
                  opacity: value,
                  child: LiquidNavigationDock(
                    selected: 2,
                    vertical: false,
                    refractBackdrop: value == 1,
                    quality: YanjiGlassQuality.high,
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (final alpha in [0.0, .15, .4, .7, 1.0]) {
        visibility.value = alpha;
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 180));
        await tester.pump();
        final png = await captureNavigationFrame(
          binding,
          tester,
          'appearance-${(alpha * 100).round()}',
        );
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
        final image = (await codec.getNextFrame()).image;
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final rect = tester.getRect(find.byKey(const Key('navigation-dock')));
        final dpr = tester.view.devicePixelRatio;
        final expected =
            rgba[((image.height ~/ 4) * image.width + image.width ~/ 2) * 4];
        for (var y = 22; y < 42; y++) {
          final gap = 4 + (rect.width - 8) / 3 * 1.75;
          for (var x = gap; x < gap + 10; x++) {
            final offset =
                (((rect.top + y) * dpr).round() * image.width +
                    ((rect.left + x) * dpr).round()) *
                4;
            expect(
              rgba[offset],
              greaterThanOrEqualTo(expected - 8),
              reason: 'Empty backdrop became dark during fade at $alpha',
            );
            if (alpha > 0 && alpha < 1) {
              final comparison =
                  (((rect.top + y) * dpr).round() * image.width +
                      ((rect.left + x - (rect.width - 8) / 3) * dpr).round()) *
                  4;
              expect(
                (rgba[offset] - rgba[comparison]).abs(),
                lessThanOrEqualTo(2),
                reason: 'A rectangular grey patch appeared at $alpha',
              );
            }
          }
        }
        image.dispose();
        codec.dispose();
      }
      await tester.pumpWidget(const SizedBox());
      visibility.dispose();
    },
  );
}
