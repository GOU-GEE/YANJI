import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/app/startup_reveal.dart';

void main() {
  Widget host({
    required bool ready,
    bool failed = false,
    bool reduced = false,
    VoidCallback? onTap,
  }) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: StartupReveal(
      ready: ready,
      failed: failed,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: onTap ?? () {},
              child: const Text('首页操作'),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'waits for readiness, blocks taps, then reveals the live child once',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(ready: false, onTap: () => taps++));
      await tester.pump(const Duration(seconds: 30));
      expect(find.byKey(StartupReveal.overlayKey), findsOneWidget);
      await tester.tap(find.text('首页操作'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pumpWidget(host(ready: true, onTap: () => taps++));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(StartupReveal.overlayKey), findsOneWidget);
      await tester.tap(find.text('首页操作'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pumpAndSettle();
      expect(find.byKey(StartupReveal.overlayKey), findsNothing);
      await tester.tap(find.text('首页操作'));
      expect(taps, 1);
      await tester.pumpWidget(host(ready: true, onTap: () => taps++));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(StartupReveal.overlayKey), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion waits for data then skips the zoom', (
    tester,
  ) async {
    await tester.pumpWidget(host(ready: false, reduced: true));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(StartupReveal.overlayKey), findsOneWidget);
    await tester.pumpWidget(host(ready: true, reduced: true));
    await tester.pump();
    expect(find.byKey(StartupReveal.overlayKey), findsNothing);
  });

  testWidgets('initialization failure exposes retry and retry can load again', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(host(ready: false));
    await tester.pumpWidget(
      host(ready: false, failed: true, onTap: () => taps++),
    );
    expect(find.byKey(StartupReveal.overlayKey), findsNothing);
    await tester.tap(find.text('首页操作'));
    expect(taps, 1);
    await tester.pumpWidget(host(ready: false));
    expect(find.byKey(StartupReveal.overlayKey), findsOneWidget);
    await tester.pumpWidget(host(ready: true));
    await tester.pumpAndSettle();
    expect(find.byKey(StartupReveal.overlayKey), findsNothing);
  });

  Future<ui.Image> frame(Size size, double progress) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff226699),
    );
    StartupClockPainter(
      progress: AlwaysStoppedAnimation(progress),
      devicePixelRatio: 1,
      harmonyOS: false,
    ).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    picture.dispose();
    return image;
  }

  test(
    'aperture exposes actual content while the outside stays opaque',
    () async {
      const size = Size(390, 844);
      for (final progress in [0.0, .22, .65]) {
        final image = await frame(size, progress);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        List<int> pixel(int x, int y) {
          final i = (y * size.width.toInt() + x) * 4;
          return [for (var c = 0; c < 3; c++) bytes.getUint8(i + c)];
        }

        expect(pixel(2, 2), [255, 255, 255]);
        expect(
          pixel(195, 395),
          progress == 0 ? [255, 255, 255] : [34, 102, 153],
        );
        if (progress == .22) expect(pixel(295, 422), [255, 255, 255]);
        if (progress == .65) expect(pixel(295, 422), [34, 102, 153]);
        image.dispose();
      }
    },
  );

  for (final size in [
    const Size(390, 844),
    const Size(900, 420),
    const Size(1024, 1366),
  ]) {
    test('final frame uncovers every pixel at $size', () async {
      final image = await frame(size, 1);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        if (bytes.getUint8(i) != 34 ||
            bytes.getUint8(i + 1) != 102 ||
            bytes.getUint8(i + 2) != 153) {
          fail('Unrevealed pixel at ${i ~/ 4}');
        }
      }
      image.dispose();
    });
  }
}
