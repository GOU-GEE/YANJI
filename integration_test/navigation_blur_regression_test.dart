import 'dart:math' as math;
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
  testWidgets('thin background strokes blur once without detached ghost copies', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    final dpr = tester.view.devicePixelRatio;
    const probe = Key('blur-probe');
    Future<(int, Uint8List)> capture(String name) async {
      await tester.pumpAndSettle();
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

    Future<void> show({
      required bool reference,
      required bool thumb,
      required double press,
    }) async {
      final color = thumb
          ? Color.alphaBlend(
              CoolapkNavigationStyle.selection(false)
                  .withValues(alpha: .1 * (1 - press)),
              CoolapkNavigationStyle.container(false),
            )
          : CoolapkNavigationStyle.container(false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _StrokePage(dpr))),
                Center(
                  child: SizedBox(
                    key: probe,
                    width: 300,
                    height: 56,
                    child: reference
                        ? ClipRect(
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                              child: ColoredBox(color: color),
                            ),
                          )
                        : CoolapkNavigationSurface(
                            thumb: thumb
                                ? const Rect.fromLTWH(80, 2.08, 140, 51.84)
                                : const Rect.fromLTWH(-900, -900, 80, 56),
                            press: press,
                            capability: NavigationGlassCapability.liquid,
                            child: const SizedBox.expand(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (!reference) {
        for (var i = 0; i < 60; i++) {
          await tester.pump();
          if (find
              .byWidgetPredicate(
                (w) => w is Semantics && w.properties.value == '液态玻璃',
              )
              .evaluate()
              .isNotEmpty) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        fail('Liquid glass did not become ready');
      }
    }

    for (final (thumb, press) in [
      (false, 0.0),
      (true, 0.0),
      (false, .5),
      (true, .5),
      (false, 1.0),
      (true, 1.0),
    ]) {
      await show(reference: true, thumb: thumb, press: press);
      final reference = await capture(
        'gaussian-${thumb ? 'thumb' : 'bar'}-$press-reference',
      );
      await show(reference: false, thumb: thumb, press: press);
      final actual = await capture(
        'gaussian-${thumb ? 'thumb' : 'bar'}-$press-actual',
      );
      final center = tester.getRect(find.byKey(probe)).center * dpr;
      int pixel((int, Uint8List) frame, int dx) =>
          frame.$2[(center.dy.floor() * frame.$1 + center.dx.floor() + dx) * 4];
      var maximumError = 0;
      final actualProfile = <int>[];
      final expectedProfile = <int>[];
      for (var x = -20; x <= 20; x++) {
        final expected = pixel(reference, x), value = pixel(actual, x);
        maximumError = math.max(maximumError, (value - expected).abs());
        actualProfile.add(value);
        expectedProfile.add(expected);
      }
      binding.reportData = {
        ...?binding.reportData,
        '${thumb ? 'thumb' : 'bar'}_${press}_max_channel_error': maximumError,
        '${thumb ? 'thumb' : 'bar'}_${press}_actual_profile': actualProfile,
        '${thumb ? 'thumb' : 'bar'}_${press}_reference_profile':
            expectedProfile,
        'dpr': dpr,
      };
      debugPrint(
        'GAUSSIAN_GHOST_CHECK thumb=$thumb press=$press dpr=$dpr maxError=$maximumError',
      );
      expect(
        maximumError,
        lessThanOrEqualTo(3),
        reason:
            'A single thin stroke must match native Gaussian blur, '
            'rather than becoming separated offset copies',
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: YanJiColors.scheme(Brightness.light)),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _TextPage())),
              Positioned(
                left: 20,
                right: 20,
                bottom: 40,
                child: LiquidNavigationDock(
                  selected: 1,
                  vertical: false,
                  onSelected: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await capture('chinese-background-navigation');
    expect(tester.takeException(), isNull);
  });
}

class _StrokePage extends CustomPainter {
  _StrokePage(this.dpr);
  final double dpr;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(Colors.white, BlendMode.src);
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, 1 / dpr, size.height),
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(_StrokePage old) => dpr != old.dpr;
}

class _TextPage extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xfffafafa), BlendMode.src);
    void label(String text, double x, double y, double fontSize, Color color) {
      final p = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: fontSize, color: color),
        ),
      );
      p.layout();
      p.paint(canvas, Offset(x, y));
      p.dispose();
    }

    label('学习热力图', 14, size.height - 94, 28, Colors.black);
    label(
      '查看更多',
      size.width - 105,
      size.height - 91,
      19,
      const Color(0xff507464),
    );
    label(
      '7月        8月        9月        10月',
      20,
      size.height - 37,
      18,
      Colors.black,
    );
  }

  @override
  bool shouldRepaint(_TextPage old) => false;
}
