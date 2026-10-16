import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/design/glass/coolapk_navigation_style.dart';
import 'package:yanji/design/glass/coolapk_navigation_surface.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';
import 'package:yanji/design/yanji_theme.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('compatibility glass has live magnification, rims and gestures', (
    tester,
  ) async {
    final support = await getAppSupportDirectory();
    final folder = Directory('${support.path}/navigation-glass-acceptance');
    await folder.create(recursive: true);
    debugPrint(
      'YANJI_NAV_SHADER_FILTER_SUPPORTED=${ui.ImageFilter.isShaderFilterSupported}',
    );
    Future<_Frame> capture(String name) async {
      await tester.pumpAndSettle();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
      // Acquire a fresh platform frame, then save the following frame.
      await binding.takeScreenshot('$name-sync');
      (binding.reportData!['screenshots'] as List<dynamic>).removeLast();
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 160));
      final png = await binding.takeScreenshot(name);
      await File('${folder.path}/$name.png').writeAsBytes(png, flush: true);
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(png));
      final image = (await codec.getNextFrame()).image;
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      final result = _Frame(image.width, bytes);
      image.dispose();
      codec.dispose();
      return result;
    }

    final dpr = tester.view.devicePixelRatio;
    const probe = Key('compatibility-optics-probe');
    for (final dark in [false, true]) {
      final tone = dark ? 'dark' : 'light';
      final marker = ValueNotifier(20.0);
      Future<void> show({
        required bool optics,
        bool decorations = false,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: yanjiThemeFor(dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: ValueListenableBuilder<double>(
                      valueListenable: marker,
                      builder: (_, x, _) =>
                          CustomPaint(painter: _MarkerPage(x, dark)),
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
                        capability: NavigationGlassCapability.blur,
                        optics: optics,
                        decorations: decorations,
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

      await show(optics: false);
      final plain = await capture('$tone-no-lens');
      final rect = tester.getRect(find.byKey(probe));
      double markerX(_Frame frame, double from, double to) {
        double weighted = 0, weight = 0;
        final y = (rect.center.dy * dpr).round();
        for (
          var x = ((rect.center.dx + from) * dpr).ceil();
          x < ((rect.center.dx + to) * dpr).floor();
          x++
        ) {
          final i = (y * frame.width + x) * 4;
          final red = (frame.rgba[i] - frame.rgba[i + 1] - 12).clamp(0, 255);
          weighted += x * red;
          weight += red;
        }
        expect(weight, greaterThan(20), reason: 'Backdrop marker disappeared');
        return weighted / weight / dpr;
      }

      await show(optics: true);
      final lens = await capture('$tone-lens');
      final displacement = markerX(lens, 8, 38) - markerX(plain, 8, 38);
      expect(displacement, greaterThan(1), reason: 'Pressed lens is flat');
      expect(displacement, lessThan(5), reason: 'Lens coordinates drifted');
      debugPrint('YANJI_NAV_LENS_$tone displacementDp=$displacement');

      await show(optics: true, decorations: true);
      final rim = await capture('$tone-rim');
      var edgeDifference = 0;
      // The upper lens rim protrudes above the bar; do not include glyphs.
      for (var dy = -12.0; dy < -9; dy += .25) {
        final x = (rect.center.dx * dpr).round();
        final y = ((rect.top + dy) * dpr).round();
        final i = (y * rim.width + x) * 4;
        final delta = (rim.rgba[i] - lens.rgba[i]).abs();
        if (delta > edgeDifference) edgeDifference = delta;
      }
      expect(edgeDifference, greaterThan(8), reason: 'Glass rim is missing');

      // Only the page repaints; the unchanged lens must sample the new frame.
      marker.value = -20;
      await tester.pump();
      final moved = await capture('$tone-live-backdrop');
      expect(markerX(moved, -38, -8), lessThan(rect.center.dx - 20));
      await tester.pumpWidget(const SizedBox());
      marker.dispose();

      var selected = 1;
      await tester.pumpWidget(
        MaterialApp(
          theme: yanjiThemeFor(dark ? Brightness.dark : Brightness.light),
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _DockPage(dark))),
                Center(
                  child: StatefulBuilder(
                    builder: (_, set) => LiquidNavigationDock(
                      selected: selected,
                      vertical: false,
                      capability: NavigationGlassCapability.blur,
                      onSelected: (i) => set(() => selected = i),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await capture('$tone-dock-rest');
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('nav-/statistics'))),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await capture('$tone-dock-held');
      // The first move enters the drag arena; subsequent events move the lens.
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.pump(const Duration(milliseconds: 500));
      await capture('$tone-dock-drag');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected, 2);
      await capture('$tone-dock-released');
      expect(tester.takeException(), isNull);
    }
    debugPrint('YANJI_HARMONY_NAVIGATION_GLASS_PASS');
  });
}

class _Frame {
  _Frame(this.width, this.rgba);
  final int width;
  final Uint8List rgba;
}

class _MarkerPage extends CustomPainter {
  _MarkerPage(this.x, this.dark);
  final double x;
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(
      dark ? const Color(0xff18344a) : const Color(0xffb6d6eb),
      BlendMode.src,
    );
    canvas.drawRect(
      Rect.fromCenter(center: size.center(Offset(x, 0)), width: 4, height: 200),
      Paint()..color = const Color(0xfff51020),
    );
  }

  @override
  bool shouldRepaint(_MarkerPage old) => old.x != x || old.dark != dark;
}

class _DockPage extends CustomPainter {
  _DockPage(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      85,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..color = (dark ? Colors.white : Colors.black).withValues(alpha: .10),
    );
    final text = TextPainter(
      text: TextSpan(
        text: '学习记录 · 今日计划',
        style: TextStyle(
          fontSize: 16,
          color: dark ? Colors.white54 : Colors.black38,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, size.center(Offset(-text.width / 2, -text.height / 2)));
  }

  @override
  bool shouldRepaint(_DockPage old) => old.dark != dark;
}
