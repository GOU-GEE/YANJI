import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design/branding/yanji_mark_paths.dart';

/// Keeps the native launch mark on screen while local bootstrap runs, then
/// reveals the already-mounted destination through the clock's inner contour.
class StartupReveal extends StatefulWidget {
  const StartupReveal({
    super.key,
    required this.ready,
    required this.child,
    this.failed = false,
    this.rasterReady,
  });

  final bool ready;
  final bool failed;
  final Widget child;

  /// Automated widget tests do not receive engine timings. Device/app builds
  /// leave this unset and wait for the destination's real raster timing.
  @visibleForTesting
  final Future<void> Function()? rasterReady;

  static const duration = Duration(milliseconds: 950);
  static const overlayKey = ValueKey('startup-clock-overlay');

  @override
  State<StartupReveal> createState() => _StartupRevealState();
}

class _StartupRevealState extends State<StartupReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  bool _finished = false;
  bool _scheduled = false;
  bool _reduced = false;
  void Function(List<FrameTiming>)? _rasterCallback;
  Completer<void>? _rasterCompletion;
  int _attempt = 0;

  void _cancelRasterWait() {
    final callback = _rasterCallback;
    if (callback != null) {
      WidgetsBinding.instance.removeTimingsCallback(callback);
    }
    _rasterCallback = null;
    final completion = _rasterCompletion;
    _rasterCompletion = null;
    if (completion != null && !completion.isCompleted) completion.complete();
  }

  Future<void> _destinationRasterized() {
    if (widget.rasterReady != null) return widget.rasterReady!();
    final completion = Completer<void>();
    _rasterCompletion = completion;
    final targetVsync = WidgetsBinding.instance.currentSystemFrameTimeStamp;
    _rasterCallback = (timings) {
      if (timings.any(
        (timing) =>
            timing.timestampInMicroseconds(FramePhase.vsyncStart) >=
            targetVsync.inMicroseconds,
      )) {
        _cancelRasterWait();
      }
    };
    WidgetsBinding.instance.addTimingsCallback(_rasterCallback!);
    return completion.future;
  }

  @override
  void initState() {
    super.initState();
    _animation =
        AnimationController(vsync: this, duration: StartupReveal.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _finished = true);
            }
          });
  }

  @override
  void didUpdateWidget(StartupReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An explicit retry after an initialization error starts a fresh bootstrap.
    if (oldWidget.failed && !widget.failed && !widget.ready) {
      _animation.reset();
      _finished = false;
    }
    if (widget.failed) {
      _attempt++;
      _scheduled = false;
      _cancelRasterWait();
      _animation.stop();
      _finished = true;
    }
  }

  void _startAfterDestinationFrame() {
    if (_finished || _scheduled || !widget.ready || widget.failed) return;
    _scheduled = true;
    final attempt = _attempt;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !widget.ready || widget.failed || _finished) return;
      // A post-frame callback only means Dart submitted the scene. Starting the
      // clock here can consume the reveal while the cold destination rasterizes.
      if (!_reduced) await _destinationRasterized();
      if (attempt != _attempt) return;
      _scheduled = false;
      if (!mounted || !widget.ready || widget.failed || _finished) return;
      if (_reduced) {
        setState(() => _finished = true);
      } else if (!_animation.isAnimating && _animation.value == 0) {
        unawaited(_animation.forward());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media =
        MediaQuery.maybeOf(context) ??
        MediaQueryData.fromView(View.of(context));
    _reduced = media.disableAnimations || media.accessibleNavigation;
    if (_reduced && _animation.isAnimating) {
      _animation.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _finished = true);
      });
    }
    _startAfterDestinationFrame();
    final covered = !_finished && !widget.failed;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          excluding: covered,
          child: IgnorePointer(ignoring: covered, child: widget.child),
        ),
        if (covered)
          Positioned.fill(
            child: AbsorbPointer(
              child: Semantics(
                label: '研迹，正在加载',
                textDirection: TextDirection.ltr,
                image: true,
                child: RepaintBoundary(
                  key: StartupReveal.overlayKey,
                  child: CustomPaint(
                    painter: StartupClockPainter(
                      progress: _animation,
                      devicePixelRatio: media.devicePixelRatio,
                      harmonyOS: defaultTargetPlatform.name == 'ohos',
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _attempt++;
    _cancelRasterWait();
    _animation.dispose();
    super.dispose();
  }
}

/// Paints a white cover with a growing, transparent inner-clock window. No
/// screenshot, clear blend mode, raster logo or fragment shader is required.
class StartupClockPainter extends CustomPainter {
  StartupClockPainter({
    required this.progress,
    required this.devicePixelRatio,
    required this.harmonyOS,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final double devicePixelRatio;
  final bool harmonyOS;
  static final _mark = createYanjiMarkPaths();
  // The SVG's first path consists of the outside ring and its inner contour.
  static final Path _window = (() {
    final contour = _mark.first.computeMetrics().elementAt(1);
    return contour.extractPath(0, contour.length)..close();
  })();

  @override
  void paint(Canvas canvas, Size size) {
    // Android may briefly report an empty surface during lifecycle changes.
    // An empty extent would make the cover scale infinite (and 0 * infinity
    // produces an invalid path transform). There is no visible area to paint.
    if (size.isEmpty) return;
    final t = progress.value.clamp(0.0, 1.0);
    final opening = const Interval(
      0,
      .22,
      curve: Curves.easeOutCubic,
    ).transform(t);
    final expansion = const Interval(
      .18,
      1,
      curve: Curves.easeInCubic,
    ).transform(t);
    final ink =
        1 - const Interval(.32, .88, curve: Curves.easeInCubic).transform(t);
    final extent = math.min(
      harmonyOS ? 512 / devicePixelRatio : 192.0,
      size.shortestSide * .75,
    );
    final base = extent / yanjiMarkExtent;
    final center = size.center(Offset.zero);
    // Use an inscribed radius with margin so even wide/tall windows are fully
    // uncovered before the overlay is removed. Hand-drawn contours aren't circles.
    final radius = _window.getBounds().shortestSide * .46 * base;
    final cover =
        (math.sqrt(size.width * size.width + size.height * size.height) / 2 +
            8) /
        radius;
    final scale = base * (1 + (math.max(1.0, cover) - 1) * expansion);
    final matrix = Float64List.fromList([
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      center.dx - yanjiMarkExtent / 2 * scale,
      center.dy - yanjiMarkExtent / 2 * scale,
      0,
      1,
    ]);
    final window = _window.transform(matrix);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      window,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(outside, Paint()..color = Colors.white);
    if (opening < 1) {
      canvas.drawPath(
        window,
        Paint()..color = Colors.white.withValues(alpha: 1 - opening),
      );
    }
    if (ink > 0) {
      final paint = Paint()..color = yanjiMarkColor.withValues(alpha: ink);
      for (final path in _mark) {
        canvas.drawPath(path.transform(matrix), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(StartupClockPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.devicePixelRatio != devicePixelRatio ||
      oldDelegate.harmonyOS != harmonyOS;
}
