import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/navigation_capture.dart';

import 'package:yanji/design/glass/coolapk_navigation_style.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/yanji_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final timings = <ui.FrameTiming>[];
  void record(List<ui.FrameTiming> frames) => timings.addAll(frames);
  binding.addTimingsCallback(record);
  tearDownAll(() {
    binding.removeTimingsCallback(record);
    final build =
        timings.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
          ..sort();
    final raster =
        timings.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()
          ..sort();
    double percentile(List<double> values, double p) =>
        values.isEmpty ? 0 : values[((values.length - 1) * p).round()];
    binding.reportData = {
      ...?binding.reportData,
      'frame_count': timings.length,
      'build_ms_p50': percentile(build, .5),
      'build_ms_p95': percentile(build, .95),
      'raster_ms_p50': percentile(raster, .5),
      'raster_ms_p95': percentile(raster, .95),
      'dpr': binding.platformDispatcher.views.first.devicePixelRatio,
      'mode': const bool.fromEnvironment('dart.vm.product')
          ? 'release'
          : const bool.fromEnvironment('dart.vm.profile')
          ? 'profile'
          : 'debug',
      'note': 'Whole validation run includes screenshot readbacks; this is diagnostic data, not a steady-state FPS measurement.',
    };
  });
  Future<(int, Uint8List)> capture(String name, WidgetTester tester) async {
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    await tester.pump();
    final png = await captureNavigationFrame(binding, tester, name);
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
    final image = (await codec.getNextFrame()).image;
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final width = image.width;
    image.dispose();
    codec.dispose();
    return (width, bytes);
  }

  Future<void> waitForLiquid(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.pump();
      final ready = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value == '液态玻璃',
      );
      if (ready.evaluate().isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    fail('Requested liquid glass never became ready');
  }

  testWidgets(
    'independent page optics: center, edge direction, live coordinates and content',
    (tester) async {
      expect(ui.ImageFilter.isShaderFilterSupported, isTrue);
      await binding.convertFlutterSurfaceToImage();
      final mode = ValueNotifier(NavigationGlassCapability.blur);
      final scroll = ValueNotifier(0.0);
      const lens = Key('optics-probe');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: ValueListenableBuilder(
                    valueListenable: scroll,
                    builder: (_, v, _) =>
                        CustomPaint(painter: CoordinatePage(v)),
                  ),
                ),
                Positioned(
                  left: 40,
                  right: 40,
                  bottom: 90,
                  height: 64,
                  child: ValueListenableBuilder(
                    valueListenable: mode,
                    builder: (_, v, _) => CoolapkNavigationSurface(
                      key: lens,
                      thumb: const Rect.fromLTWH(-900, -900, 80, 56),
                      press: 0,
                      capability: v,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final baseline = await capture('probe-blur', tester);
      mode.value = NavigationGlassCapability.liquid;
      await waitForLiquid(tester);
      final full = await capture('probe-liquid', tester);
      final rect = tester.getRect(find.byKey(lens));
      final dpr = tester.view.devicePixelRatio;
      double green((int, Uint8List) frame, Offset point) {
        final p =
            (((point.dy * dpr).round()) * frame.$1 + (point.dx * dpr).round()) *
            4;
        return frame.$2[p + 1].toDouble();
      }

      final edge = Offset(rect.center.dx, rect.top + 2);
      final center = rect.center;
      final shift = green(full, edge) - green(baseline, edge);
      final stable = green(full, center) - green(baseline, center);
      debugPrint(
        'COOLAPK_OPTICS dpr=$dpr edgeGreenShift=$shift centerShift=$stable rect=$rect',
      );
      binding.reportData = {
        ...?binding.reportData,
        'edge_green_shift': shift,
        'center_green_shift': stable,
      };
      expect(
        shift,
        greaterThan(2),
        reason: 'Negative amount must sample inward at the top rim',
      );
      expect(stable.abs(), lessThan(2), reason: 'Center must bypass the lens');
      scroll.value = 90;
      final moved = await capture('probe-scrolled', tester);
      expect(
        (green(moved, center) - green(full, center)).abs(),
        greaterThan(8),
        reason: 'Live page changes must invalidate the backdrop',
      );
      await tester.pumpWidget(const SizedBox());
      mode.dispose();
      scroll.dispose();

      // A uniform page removes background optics from the comparison. Only the
      // isolated small-text/line texture can differ between these two captures.
      final pressed = ValueNotifier(0.0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: SizedBox(
                width: 300,
                height: 64,
                child: ValueListenableBuilder(
                  valueListenable: pressed,
                  builder: (_, v, _) => CoolapkNavigationSurface(
                    thumb: const Rect.fromLTWH(40, 4, 100, 56),
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
      await waitForLiquid(tester);
      final normal = await capture('content-normal', tester);
      pressed.value = 1;
      final content = await capture('content-pressed', tester);
      var different = 0;
      for (var i = 0; i < normal.$2.length; i += 4) {
        if ((normal.$2[i] < 120) != (content.$2[i] < 120)) different++;
      }
      debugPrint('COOLAPK_CONTENT changedInkPixels=$different');
      binding.reportData!['changed_ink_pixels'] = different;
      expect(
        different,
        greaterThan(30),
        reason: 'Press must filter the independent glyph layer',
      );
      await tester.pumpWidget(const SizedBox());
      pressed.dispose();

      // A generated bitmap is uploaded once; scrolling changes its placement,
      // exercising live image sampling rather than a rebuilt gradient painter.
      final recorder = ui.PictureRecorder();
      const ValidationPage().paint(Canvas(recorder), const Size(500, 1440));
      final picture = recorder.endRecording();
      final bitmap = await picture.toImage(500, 1440);
      picture.dispose();
      final imageScroll = ValueNotifier(0.0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                ValueListenableBuilder(
                  valueListenable: imageScroll,
                  builder: (_, v, _) => Positioned(
                    left: 0,
                    right: 0,
                    top: -v,
                    height: 1440,
                    child: RawImage(image: bitmap, fit: BoxFit.fill),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 50,
                  child: LiquidNavigationDock(
                    selected: 0,
                    vertical: false,
                    onSelected: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final imageBefore = await capture('image-before-scroll', tester);
      imageScroll.value = 60;
      final imageAfter = await capture('image-after-scroll', tester);
      final imageDock = tester.getRect(
        find.byKey(const Key('navigation-dock')),
      );
      var imageChanges = 0;
      for (
        var y = (imageDock.top * dpr).ceil();
        y < imageDock.bottom * dpr;
        y++
      ) {
        for (
          var x = (imageDock.left * dpr).ceil();
          x < imageDock.right * dpr;
          x++
        ) {
          final offset = (y * imageBefore.$1 + x) * 4;
          if ((imageBefore.$2[offset] - imageAfter.$2[offset]).abs() > 20) {
            imageChanges++;
          }
        }
      }
      debugPrint('COOLAPK_IMAGE changedDockPixels=$imageChanges');
      binding.reportData!['changed_image_dock_pixels'] = imageChanges;
      expect(imageChanges, greaterThan(500));
      await tester.pumpWidget(const SizedBox());
      imageScroll.dispose();
      bitmap.dispose();
    },
  );
  testWidgets(
    'light/dark, tiers, continuous/reversed/cancelled drag, RTL and landscape',
    (tester) async {
      await binding.convertFlutterSurfaceToImage();
      for (final brightness in Brightness.values) {
        var selected = 0, commits = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: yanjiThemeFor(brightness),
            home: Scaffold(
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: ValidationPage()),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 35,
                    child: StatefulBuilder(
                      builder: (_, set) => LiquidNavigationDock(
                        selected: selected,
                        vertical: false,
                        onSelected: (v) => set(() {
                          selected = v;
                          commits++;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await capture('${brightness.name}-rest', tester);
        final lens = find.byKey(const Key('liquid-indicator'));
        final start = tester.getCenter(lens);
        final gesture = await tester.startGesture(start);
        await tester.pump(const Duration(milliseconds: 500));
        await capture('${brightness.name}-held', tester);
        await gesture.moveBy(const Offset(25, 0));
        await tester.pump();
        for (var i = 0; i < 5; i++) {
          await gesture.moveBy(const Offset(32, 0));
          await tester.pump(const Duration(milliseconds: 80));
          await capture('${brightness.name}-drag-$i', tester);
        }
        expect(commits, 0);
        await gesture.moveBy(const Offset(-85, 0));
        await tester.pump(const Duration(milliseconds: 100));
        await capture('${brightness.name}-reverse', tester);
        await gesture.cancel();
        await tester.pumpAndSettle();
        expect(selected, 0);
        expect((tester.getCenter(lens) - start).distance, lessThan(.1));
        await tester.tap(find.byKey(const ValueKey('nav-/profile')));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(commits, 1);
        await capture('${brightness.name}-selected', tester);
        expect(tester.takeException(), isNull);
      }
      for (final mode in NavigationGlassCapability.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: ValidationPage()),
                  ),
                  Center(
                    child: SizedBox(
                      width: 230,
                      child: LiquidNavigationDock(
                        selected: 1,
                        vertical: false,
                        capability: mode,
                        onSelected: (_) {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await capture('tier-${mode.name}-narrow', tester);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: LiquidNavigationDock(
                  selected: 0,
                  vertical: false,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await capture('rtl', tester);
      expect(
        tester.getCenter(find.text('今日')).dx,
        greaterThan(tester.getCenter(find.text('我的')).dx),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: ValidationPage()),
                ),
                const Positioned(left: 20, top: 90, child: _VerticalDock()),
              ],
            ),
          ),
        ),
      );
      await capture('vertical', tester);
      expect(tester.takeException(), isNull);
    },
    skip: const bool.fromEnvironment('NAV_PIXEL_ONLY'),
  );
}

class _VerticalDock extends StatelessWidget {
  const _VerticalDock();
  @override
  Widget build(BuildContext c) =>
      LiquidNavigationDock(selected: 1, vertical: true, onSelected: (_) {});
}

class CoordinatePage extends CustomPainter {
  const CoordinatePage(this.scroll);
  final double scroll;
  @override
  void paint(Canvas canvas, Size size) {
    for (var y = 0; y < size.height.ceil(); y++) {
      final green = ((y + scroll) % 240 / 240 * 255).round();
      canvas.drawRect(
        Rect.fromLTWH(0, y.toDouble(), size.width, 1),
        Paint()..color = Color.fromARGB(255, 40, green, 170),
      );
    }
  }

  @override
  bool shouldRepaint(CoordinatePage old) => scroll != old.scroll;
}

class GlyphProbe extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    for (var y = 6.0; y < 64; y += 7) {
      c.drawLine(
        Offset(12, y),
        Offset(285, y),
        Paint()
          ..color = Colors.black
          ..strokeWidth = .8,
      );
    }
    final t = TextPainter(
      text: const TextSpan(
        text: 'ABCDEFG 123456789 研迹测试',
        style: TextStyle(color: Colors.black, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    t.paint(c, const Offset(15, 21));
  }

  @override
  bool shouldRepaint(GlyphProbe old) => false;
}

class ValidationPage extends CustomPainter {
  const ValidationPage();
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xffd8e4e9));
    for (var y = 0.0; y < s.height; y += 24) {
      for (var x = 0.0; x < s.width; x += 24) {
        c.drawRect(
          Rect.fromLTWH(x, y, 24, 24),
          Paint()
            ..color = Colors
                .primaries[((x / 24 + y / 24).round()) %
                    Colors.primaries.length]
                .withValues(alpha: .55),
        );
      }
      final t = TextPainter(
        text: TextSpan(
          text: '$y  小字号文字 ABCDEFG 0123456789',
          style: const TextStyle(color: Colors.black, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(c, Offset(2, y + 4));
      c.drawLine(
        Offset(0, y),
        Offset(s.width, y),
        Paint()
          ..color = Colors.white
          ..strokeWidth = .7,
      );
    }
  }

  @override
  bool shouldRepaint(ValidationPage old) => false;
}
