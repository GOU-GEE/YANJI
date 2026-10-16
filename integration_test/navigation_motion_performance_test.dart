import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/design/glass/liquid_navigation_dock.dart';

import 'coolapk_navigation_test.dart' show CoordinatePage;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('motion frame timings without screenshot readbacks', (
    tester,
  ) async {
    final scroll = ValueNotifier(0.0);
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ValueListenableBuilder(
                  valueListenable: scroll,
                  builder: (_, value, _) =>
                      CustomPaint(painter: CoordinatePage(value)),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 35,
                child: StatefulBuilder(
                  builder: (_, set) => LiquidNavigationDock(
                    selected: selected,
                    vertical: false,
                    onSelected: (value) => set(() => selected = value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      if (find
          .byWidgetPredicate(
            (w) => w is Semantics && w.properties.value == '液态玻璃',
          )
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value == '液态玻璃',
      ),
      findsOneWidget,
    );
    // Warm GPU programs and flush the engine's batched timing callbacks.
    for (var i = 0; i < 60; i++) {
      scroll.value = i.toDouble();
      await tester.pump(const Duration(milliseconds: 16));
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    final frames = <ui.FrameTiming>[];
    void record(List<ui.FrameTiming> values) => frames.addAll(values);
    binding.addTimingsCallback(record);
    final rect = tester.getRect(find.byKey(const Key('navigation-dock')));
    final gesture = await tester.startGesture(
      Offset(rect.left + rect.width / 6, rect.center.dy),
    );
    await gesture.moveBy(const Offset(25, 0));
    final elapsed = Stopwatch()..start();
    for (var i = 0; i < 180; i++) {
      scroll.value = 60 + i.toDouble();
      await gesture.moveTo(
        Offset(
          rect.center.dx + math.sin(i / 90 * math.pi * 2) * rect.width * .35,
          rect.center.dy,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    elapsed.stop();
    await Future<void>.delayed(const Duration(seconds: 1));
    binding.removeTimingsCallback(record);
    expect(frames.length, greaterThan(20));
    double percentile(List<double> values, double p) {
      values.sort();
      return values[((values.length - 1) * p).round()];
    }

    final build = frames
        .map((v) => v.buildDuration.inMicroseconds / 1000)
        .toList();
    final raster = frames
        .map((v) => v.rasterDuration.inMicroseconds / 1000)
        .toList();
    binding.reportData = {
      'frame_count': frames.length,
      'build_ms_p50': percentile(build, .5),
      'build_ms_p95': percentile(build, .95),
      'raster_ms_p50': percentile(raster, .5),
      'raster_ms_p95': percentile(raster, .95),
      'raster_ms_max': percentile(raster, 1),
      'wall_clock_ms': elapsed.elapsedMilliseconds,
      'dpr': tester.view.devicePixelRatio,
      'mode': const bool.fromEnvironment('dart.vm.profile')
          ? 'profile'
          : 'debug',
      'note': '180 scripted reversed drag updates over a changing coordinate page; GPU warmup excluded. No screenshot, ImageView conversion, PNG decode or CPU texture readback in this test. Emulator diagnostic, not a device FPS guarantee.',
    };
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
    expect(tester.takeException(), isNull);
  });
}
