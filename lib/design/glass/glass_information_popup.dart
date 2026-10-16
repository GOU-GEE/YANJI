import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../yanji_motion.dart';

/// An information bubble that observes chart touches without taking gestures.
/// Hiding keeps the last snapshot only for its exit animation. Pointer motion
/// updates the anchor immediately without replaying the entrance animation.
class GlassInformationPopup extends StatefulWidget {
  const GlassInformationPopup({super.key, this.point, this.child});
  final Offset? point;
  final Widget? child;

  @override
  State<GlassInformationPopup> createState() => _GlassInformationPopupState();
}

class _GlassInformationPopupState extends State<GlassInformationPopup>
    with TickerProviderStateMixin {
  late final AnimationController _rebound = AnimationController.unbounded(
    vsync: this,
  );
  int? _pointer;
  Offset _origin = Offset.zero;
  Offset _pull = Offset.zero;
  double _touchX = 0;

  void _release(int pointer) {
    if (_pointer != pointer) return;
    _pointer = null;
    if (_pull == Offset.zero) {
      _rebound.stop();
      _rebound.value = 0;
      return;
    }
    _rebound.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 330, damping: 26),
        _rebound.value,
        0,
        _rebound.velocity,
      ),
    );
  }

  late final AnimationController _animation =
      AnimationController(
        vsync: this,
        duration: YanJiMotion.duration,
        reverseDuration: YanJiMotion.duration,
      )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed && !_visible && mounted) {
          setState(() {
            _content = null;
            _point = null;
          });
        }
      });
  Widget? _content;
  Offset? _point;
  bool get _visible => widget.point != null && widget.child != null;

  @override
  void initState() {
    super.initState();
    _capture();
  }

  void _capture() {
    if (!_visible) return;
    _content = widget.child;
    _point = widget.point;
  }

  void _animate() {
    if (YanJiMotion.reduced(context)) {
      _pointer = null;
      _pull = Offset.zero;
      _rebound.stop();
      _rebound.value = 0;
      _animation.stop();
      _animation.value = _visible ? 1 : 0;
      if (!_visible) {
        _content = null;
        _point = null;
      }
    } else if (_visible) {
      _animation.forward();
    } else {
      _animation.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate();
  }

  @override
  void didUpdateWidget(GlassInformationPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    _capture();
    _animate();
  }

  @override
  void dispose() {
    _rebound.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = YanJiMotion.reduced(context);
    final progress = _animation.drive(CurveTween(curve: YanJiMotion.curve));
    return Listener(
      // Translucent hit testing also lets the chart behind receive this pointer.
      // IgnorePointer only applies to the visual bubble, not this observer.
      behavior: HitTestBehavior.translucent,
      onPointerDown: reduced
          ? null
          : (event) {
              if (_pointer != null) return;
              _pointer = event.pointer;
              _origin = event.position;
              _pull = Offset.zero;
              _touchX =
                  (event.localPosition.dx / (context.size?.width ?? 1) * 2 - 1)
                      .clamp(-1, 1);
              _rebound.stop();
              _rebound.value = 1;
            },
      onPointerMove: reduced
          ? null
          : (event) {
              if (_pointer != event.pointer) return;
              final delta = event.position - _origin;
              setState(() {
                _pull = Offset(
                  delta.dx.clamp(-45.0, 45.0),
                  delta.dy.clamp(-45.0, 45.0),
                );
              });
            },
      onPointerUp: reduced ? null : (event) => _release(event.pointer),
      onPointerCancel: reduced ? null : (event) => _release(event.pointer),
      child: _content == null || _point == null
          ? const SizedBox.expand()
          : IgnorePointer(
              child: ExcludeSemantics(
                excluding: !_visible,
                child: CustomSingleChildLayout(
                  delegate: GlassInformationPopupLayout(_point!),
                  child: FadeTransition(
                    opacity: progress,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: .94,
                        end: 1,
                      ).animate(progress),
                      alignment: Alignment.bottomLeft,
                      child: AnimatedBuilder(
                        animation: _rebound,
                        child: _content,
                        builder: (context, child) {
                          // Match the notice's GlassElastic deformation in both axes.
                          final pull = reduced
                              ? Offset.zero
                              : _pull * _rebound.value;
                          final x = pull.dx / 45;
                          final y = pull.dy / 45;
                          return Transform(
                            key: const Key('information-popup-drag-transform'),
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setTranslationRaw(
                                pull.dx * .12,
                                pull.dy * .12,
                                0,
                              )
                              ..setEntry(
                                0,
                                0,
                                1 + x.abs() * .10 - y.abs() * .025,
                              )
                              ..setEntry(
                                1,
                                1,
                                1 + y.abs() * .10 - x.abs() * .025,
                              )
                              ..setEntry(0, 1, x * .025)
                              ..setEntry(1, 0, y * .05 * _touchX),
                            child: child,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class GlassInformationPopupLayout extends SingleChildLayoutDelegate {
  GlassInformationPopupLayout(this.point);
  final Offset point;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(0, constraints.maxWidth - 8),
        maxHeight: constraints.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => Offset(
    (point.dx + 10).clamp(4, math.max(4, size.width - childSize.width - 4)),
    (point.dy - childSize.height - 10).clamp(
      0,
      math.max(0, size.height - childSize.height),
    ),
  );

  @override
  bool shouldRelayout(covariant GlassInformationPopupLayout oldDelegate) =>
      point != oldDelegate.point;
}
