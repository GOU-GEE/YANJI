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
  testWidgets('ordered convex lens geometry, capture, direction and material', (
    tester,
  ) async {
    await binding.convertFlutterSurfaceToImage();
    const probe = Key('convex-probe');
    Future<(int, Uint8List)> frame(String name) async {
      final bytes = await captureNavigationFrame(binding, tester, name);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final image = (await codec.getNextFrame()).image;
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      final width = image.width;
      image.dispose();
      codec.dispose();
      return (width, rgba);
    }

    Future<void> show(
      Rect thumb, {
      Widget? capture,
      Widget? normal,
      bool optics = false,
      bool decor = false,
      bool compression = false,
      bool reduceBar = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xff183b90),
            body: Center(
              child: SizedBox(
                key: probe,
                width: 272,
                height: 56,
                child: CoolapkNavigationSurface(
                  thumb: thumb,
                  press: 1,
                  capability: NavigationGlassCapability.liquid,
                  decorations: decor,
                  optics: optics,
                  legacyCompression: compression,
                  reduceBarThroughLens: reduceBar,
                  accentChild: capture,
                  child: normal ?? const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await tester.pump();
      }
    }

    Rect lens(double x) => Rect.fromCenter(
      center: Offset(x, 28),
      width: 88 * CoolapkNavigationStyle.pressedHeightRatio,
      height:
          CoolapkNavigationStyle.selectionHeight *
          CoolapkNavigationStyle.pressedHeightRatio,
    );
    final geometry = <Map<String, num>>[];
    for (final x in [48.0, 136.0, 224.0]) {
      await show(lens(x), capture: CustomPaint(painter: InkPlane()));
      final data = await frame('stage1-geometry-${x.toInt()}');
      final r = tester.getRect(find.byKey(probe));
      final dpr = tester.view.devicePixelRatio;
      final hits = <int>[];
      for (
        var y = ((r.top - 32) * dpr).ceil();
        y < ((r.bottom + 32) * dpr).floor();
        y++
      ) {
        final i = (y * data.$1 + ((r.left + x) * dpr).floor()) * 4;
        if (data.$2[i] > 200 && data.$2[i + 1] < 80) hits.add(y);
      }
      expect(
        hits,
        isNotEmpty,
        reason: 'Capture input/output must cover protruding lens',
      );
      final height = hits.last - hits.first + 1;
      expect(height / dpr, closeTo(lens(x).height, 1));
      expect(hits.first, lessThan((r.top - 6) * dpr));
      expect(hits.last, greaterThan((r.bottom + 6) * dpr));
      geometry.add({
        'slot_center_dp': x,
        'rendered_height_px': height,
        'logical_height_dp': height / dpr,
      });
    }
    binding.reportData!.addAll({
      'geometry': geometry,
      'dpr': tester.view.devicePixelRatio,
    });

    // Only the non-interactive capture transforms, about each item's own centre.
    Widget glyphs(Color color, double scale) => Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Transform.scale(
              scale: scale,
              child: SizedBox.expand(
                child: CustomPaint(painter: GlyphBars(color)),
              ),
            ),
          ),
        ),
      ),
    );
    await show(
      lens(136),
      capture: glyphs(const Color(0xff00ba60), 1),
      normal: glyphs(Colors.black, 1),
    );
    final raw = await frame('stage2-capture-1');
    await show(
      lens(136),
      capture: glyphs(const Color(0xff00ba60), 1.2),
      normal: glyphs(Colors.black, 1),
    );
    final enlarged = await frame('stage2-capture-1_2');
    final r = tester.getRect(find.byKey(probe)),
        dpr = tester.view.devicePixelRatio;
    int inkWidth((int, Uint8List) data) {
      final xs = <int>[];
      final y = ((r.top + 20) * dpr).floor();
      for (
        var x = ((r.left + 115) * dpr).ceil();
        x < ((r.left + 157) * dpr).floor();
        x++
      ) {
        final i = (y * data.$1 + x) * 4;
        if (data.$2[i + 1] > data.$2[i] + 60 &&
            data.$2[i + 1] > data.$2[i + 2] + 40) {
          xs.add(x);
        }
      }
      expect(xs, isNotEmpty);
      return xs.last - xs.first + 1;
    }

    final ratio = inkWidth(enlarged) / inkWidth(raw);
    expect(ratio, inInclusiveRange(1.15, 1.26));
    binding.reportData!['capture_ink_width_ratio'] = ratio;

    final edgeX = lens(136).right - 4;
    await show(lens(136), capture: CustomPaint(painter: EdgeMarker(edgeX)));
    final straight = await frame('stage3-edge-unfiltered');
    await show(
      lens(136),
      optics: true,
      capture: CustomPaint(painter: EdgeMarker(edgeX)),
    );
    final refracted = await frame('stage3-edge-negative-amount');
    double markerX((int, Uint8List) data) {
      double sum = 0, weight = 0;
      final y = (r.center.dy * dpr).floor();
      for (
        var x = ((r.left + edgeX - 12) * dpr).ceil();
        x < ((r.left + edgeX + 8) * dpr).floor();
        x++
      ) {
        final i = (y * data.$1 + x) * 4;
        final red = (data.$2[i] - data.$2[i + 1] - 80).clamp(0, 255);
        sum += x * red;
        weight += red;
      }
      expect(weight, greaterThan(0));
      return sum / weight;
    }

    final displacement = (markerX(refracted) - markerX(straight)) / dpr;
    expect(
      displacement,
      greaterThan(.3),
      reason: 'Negative amount samples inward; the edge marker moves outward',
    );
    binding.reportData!['edge_displacement_dp'] = displacement;
    await show(
      lens(136),
      optics: true,
      compression: true,
      capture: glyphs(const Color(0xff00ba60), 1.2),
    );
    await frame('stage3-legacy-compression-control');

    // The bar shrinks in the lens while its isolated accent capture still
    // enlarges by 1.2. Use contrasting page ink, no decorations or foreground.
    final barReduction = <Map<String, num>>[];
    for (final x in [48.0, 136.0, 224.0]) {
      await show(lens(x), optics: true, reduceBar: false);
      final plain = await frame('stage3-bar-original-${x.toInt()}');
      await show(lens(x), optics: true);
      final reduced = await frame('stage3-bar-reduced-${x.toInt()}');
      List<int> span((int, Uint8List) data, {bool horizontal = false}) {
        final hits = <int>[];
        final from = horizontal ? r.left - 20 : r.top - 20;
        final to = horizontal ? r.right + 20 : r.bottom + 20;
        for (var pos = (from * dpr).ceil(); pos < (to * dpr).floor(); pos++) {
          final px = horizontal ? pos : ((r.left + x) * dpr).floor();
          final py = horizontal ? (r.center.dy * dpr).floor() : pos;
          if (data.$2[(py * data.$1 + px) * 4] > 130) hits.add(pos);
        }
        expect(hits, isNotEmpty);
        // Measure continuous bar material, excluding isolated dispersed rim ink.
        // GLES can produce a one-pixel red rim separated from the bar by 21px;
        // counting its extrema falsely reports asymmetric bar contraction.
        final runs = <List<int>>[];
        var start = hits.first, end = start;
        for (final hit in hits.skip(1)) {
          if (hit != end + 1) {
            runs.add([start, end]);
            start = hit;
          }
          end = hit;
        }
        runs.add([start, end]);
        runs.sort((a, b) => (b.last - b.first).compareTo(a.last - a.first));
        return runs.first;
      }

      final a = span(plain), b = span(reduced);
      final topInset = (b.first - a.first) / dpr;
      final bottomInset = (a.last - b.last) / dpr;
      expect(topInset, greaterThan(2));
      expect(bottomInset, greaterThan(2));
      expect(topInset, closeTo(bottomInset, 1 / dpr));
      final row = <String, num>{
        'slot_center_dp': x,
        'top_inset_dp': topInset,
        'bottom_inset_dp': bottomInset,
        'bar_height_ratio': (b.last - b.first + 1) / (a.last - a.first + 1),
      };
      if (x != 136) {
        final left = span(plain, horizontal: true);
        final right = span(reduced, horizontal: true);
        final cap = x < 136
            ? (right.first - left.first) / dpr
            : (left.last - right.last) / dpr;
        expect(cap, greaterThan(2));
        row['endpoint_inset_dp'] = cap;
      }
      barReduction.add(row);
    }
    binding.reportData!['bar_reduction'] = barReduction;

    for (final dark in [false, true]) {
      for (final capability in NavigationGlassCapability.values) {
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: YanJiColors.scheme(
                dark ? Brightness.dark : Brightness.light,
              ),
            ),
            home: Scaffold(
              backgroundColor: dark
                  ? const Color(0xff182126)
                  : const Color(0xffeef2f4),
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: PageGrid()),
                  ),
                  Center(
                    child: StatefulBuilder(
                      builder: (_, set) => LiquidNavigationDock(
                        selected: selected,
                        vertical: false,
                        capability: capability,
                        onSelected: (i) => set(() => selected = i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final g = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('nav-/'))),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        await frame(
          'stage4-${dark ? 'dark' : 'light'}-${capability.name}-held',
        );
        for (var i = 0; i < 9; i++) {
          await g.moveBy(const Offset(22, 0));
          await tester.pump(const Duration(milliseconds: 90));
        }
        await frame(
          'stage4-${dark ? 'dark' : 'light'}-${capability.name}-cross',
        );
        final before = tester
            .widget<CoolapkNavigationSurface>(
              find.byType(CoolapkNavigationSurface),
            )
            .thumb;
        await tester.pump(const Duration(seconds: 1));
        final after = tester
            .widget<CoolapkNavigationSurface>(
              find.byType(CoolapkNavigationSurface),
            )
            .thumb;
        expect((before.height - after.height).abs(), lessThan(.5));
        await g.up();
        await tester.pumpAndSettle();
        await frame(
          'stage5-${dark ? 'dark' : 'light'}-${capability.name}-released',
        );
        expect(
          tester
              .widget<CoolapkNavigationSurface>(
                find.byType(CoolapkNavigationSurface),
              )
              .press,
          lessThan(.001),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });
}

class InkPlane extends CustomPainter {
  @override
  void paint(Canvas c, Size s) => c.drawRect(
    (Offset.zero & s).inflate(32),
    Paint()..color = const Color(0xffee1020),
  );
  @override
  bool shouldRepaint(InkPlane p) => false;
}

class GlyphBars extends CustomPainter {
  const GlyphBars(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    c.drawRect(
      Rect.fromCenter(center: Offset(s.width / 2, 16), width: 16, height: 16),
      p,
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(s.width / 2, 36), width: 22, height: 5),
      p,
    );
  }

  @override
  bool shouldRepaint(GlyphBars p) => color != p.color;
}

class EdgeMarker extends CustomPainter {
  const EdgeMarker(this.x);
  final double x;
  @override
  void paint(Canvas c, Size s) => c.drawRect(
    Rect.fromLTWH(x - 1, 10, 2, 36),
    Paint()..color = const Color(0xffff1020),
  );
  @override
  bool shouldRepaint(EdgeMarker p) => x != p.x;
}

class PageGrid extends CustomPainter {
  const PageGrid();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0x50788890)
      ..strokeWidth = 1;
    for (double x = 0; x < s.width; x += 20) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (double y = 0; y < s.height; y += 20) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(PageGrid p) => false;
}
