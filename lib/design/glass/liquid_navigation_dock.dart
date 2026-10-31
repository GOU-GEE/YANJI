import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:flutter/physics.dart';

import 'coolapk_navigation_style.dart';
import 'coolapk_navigation_surface.dart';
import 'liquid_glass_quality.dart';

class LiquidNavigationDock extends StatefulWidget {
  const LiquidNavigationDock({
    super.key,
    required this.selected,
    required this.vertical,
    required this.onSelected,
    this.quality,
    this.capability,
    this.refractBackdrop = true,
  });
  final int selected;
  final bool vertical;
  final ValueChanged<int> onSelected;
  final YanjiGlassQuality? quality;
  final NavigationGlassCapability? capability;
  final bool refractBackdrop;
  static const labels = ['今日', '数据', '我的'];
  static const icons = [
    Icons.today_outlined,
    Icons.bar_chart_rounded,
    Icons.person_outline,
  ];
  static double get width =>
      CoolapkNavigationStyle.widthForItems(labels.length);
  static const height = CoolapkNavigationStyle.height;
  static const verticalWidth = 64.0;
  static const verticalHeight = 232.0;
  static const inset = CoolapkNavigationStyle.padding;
  @override
  State<LiquidNavigationDock> createState() => _DockState();
}

class _DockState extends State<LiquidNavigationDock>
    with TickerProviderStateMixin {
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selected.toDouble(),
  );
  late final _press = AnimationController.unbounded(vsync: this);
  late final _scaleX = AnimationController.unbounded(vsync: this, value: 1);
  late final _scaleY = AnimationController.unbounded(vsync: this, value: 1);
  late final _velocity = AnimationController.unbounded(vsync: this);
  late final _animations = Listenable.merge([
    _position,
    _press,
    _scaleX,
    _scaleY,
    _velocity,
  ]);
  Timer? _brake;
  bool _dragging = false, _reduceMotion = false;
  int? _pendingCommit, _preview;
  double _rawPosition = 0, _slotVelocity = 0, _sign = 1;
  Duration? _lastSample;
  void _spring(
    AnimationController c,
    SpringDescription spring,
    double target, {
    double? velocity,
  }) {
    if (_reduceMotion) {
      c.value = target;
      return;
    }
    c.animateWith(
      SpringSimulation(
        spring,
        c.value,
        target,
        velocity ?? c.velocity,
        tolerance: const Tolerance(distance: .0001, velocity: .001),
      ),
    );
  }

  void _pressure(bool held) {
    _spring(_press, CoolapkNavigationStyle.effectSpring, held ? 1 : 0);
    // Mirror LiquidTabMotionState: geometry and AccentCapture have separate
    // transforms. Capture scaling is applied later to each glyph's centre.
    final scale = held && !_reduceMotion
        ? CoolapkNavigationStyle.pressedHeightRatio
        : 1.0;
    _spring(_scaleX, CoolapkNavigationStyle.scaleXSpring, scale);
    _spring(_scaleY, CoolapkNavigationStyle.scaleYSpring, scale);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _sign = !widget.vertical && Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    if (_reduceMotion) {
      _position.value = widget.selected.toDouble();
      _press.value = 0;
      _scaleX.value = 1;
      _scaleY.value = 1;
      _velocity.value = 0;
    }
  }

  @override
  void didUpdateWidget(LiquidNavigationDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vertical != widget.vertical) _finish(cancelled: true);
    if (oldWidget.selected != widget.selected && !_dragging) {
      if (_pendingCommit == widget.selected) {
        _pendingCommit = null;
        return;
      }
      _pendingCommit = null;
      _spring(
        _position,
        CoolapkNavigationStyle.positionSpring,
        widget.selected.toDouble(),
      );
    }
  }

  void _down(int i) {
    _brake?.cancel();
    _velocity.value = 0;
    setState(() {
      _preview = i;
    });
    _pressure(true);
    _spring(_position, CoolapkNavigationStyle.positionSpring, i.toDouble());
  }

  void _release({bool cancelled = false}) {
    if (_dragging) return;
    setState(() {
      _preview = null;
    });
    _pressure(false);
    if (cancelled) {
      _spring(
        _position,
        CoolapkNavigationStyle.positionSpring,
        widget.selected.toDouble(),
      );
    }
  }

  void _select(int i) {
    _pendingCommit = i;
    _spring(_position, CoolapkNavigationStyle.positionSpring, i.toDouble());
    if (i != widget.selected) {
      widget.onSelected(i);
    }
  }

  void _begin(DragStartDetails d) {
    _position.stop();
    _brake?.cancel();
    _rawPosition = _position.value;
    _slotVelocity = 0;
    _lastSample = d.sourceTimeStamp;
    setState(() {
      _dragging = true;
      _preview = _rawPosition.round().clamp(0, 2);
    });
    _pressure(true);
  }

  void _update(DragUpdateDetails d, double cell) {
    final delta = (widget.vertical ? d.delta.dy : d.delta.dx * _sign) / cell;
    final seconds = _lastSample != null && d.sourceTimeStamp != null
        ? (d.sourceTimeStamp! - _lastSample!).inMicroseconds / 1e6
        : 1 / 60;
    _lastSample = d.sourceTimeStamp;
    _slotVelocity = (delta / math.max(seconds, .001)).clamp(-20.0, 20.0);
    _rawPosition += delta;
    // Soft endpoint resistance retains finger continuity, including reversal.
    final edge = _rawPosition.clamp(0.0, 2.0);
    final overflow = _rawPosition - edge;
    _position.value = edge + overflow / (1 + overflow.abs() * 12) * .28;
    // Coolapk normalizes slot velocity by the range length before deformation.
    _spring(
      _velocity,
      CoolapkNavigationStyle.velocitySpring,
      _slotVelocity / 2,
    );
    _brake?.cancel();
    _brake = Timer(const Duration(milliseconds: 80), () {
      if (mounted) _spring(_velocity, CoolapkNavigationStyle.velocitySpring, 0);
    });
    final next = _position.value.round().clamp(0, 2);
    if (_preview != next) setState(() => _preview = next);
  }

  void _finish({bool cancelled = false, double? velocity, double? cell}) {
    if (!_dragging) return;
    _brake?.cancel();
    // Selection follows the nearest slot; fling velocity initializes its spring.
    final target = cancelled
        ? widget.selected
        : _position.value.round().clamp(0, 2);
    final v = velocity != null && cell != null
        ? (velocity * _sign / cell).clamp(-20.0, 20.0)
        : _slotVelocity;
    setState(() {
      _dragging = false;
      _preview = null;
    });
    _pressure(false);
    _spring(_velocity, CoolapkNavigationStyle.velocitySpring, 0);
    _spring(
      _position,
      CoolapkNavigationStyle.positionSpring,
      target.toDouble(),
      velocity: cancelled ? 0 : v,
    );
    if (!cancelled && target != widget.selected) {
      _pendingCommit = target;
      widget.onSelected(target);
    }
  }

  @override
  void dispose() {
    _brake?.cancel();
    for (final c in [_position, _press, _scaleX, _scaleY, _velocity]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleContent = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final capability =
        widget.capability ??
        (widget.quality == YanjiGlassQuality.reduced ||
                const bool.fromEnvironment('YANJI_GLASS_REDUCED') ||
                !supportsGlassShaders
            ? NavigationGlassCapability.blur
            : NavigationGlassCapability.liquid);
    final vertical = widget.vertical;
    return Transform(
      transform: Matrix4.identity(),
      key: const Key('liquid-dock-transform'),
      child: SizedBox(
        width: vertical
            ? LiquidNavigationDock.verticalWidth
            : LiquidNavigationDock.width,
        height: vertical
            ? LiquidNavigationDock.verticalHeight
            : LiquidNavigationDock.height,
        child: CustomPaint(
          child: Material(
            key: const Key('navigation-dock'),
            color: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell =
                    ((vertical ? constraints.maxHeight : constraints.maxWidth) -
                        8) /
                    3;
                return Listener(
                  onPointerDown: (event) {
                    final axis = vertical
                        ? event.localPosition.dy
                        : event.localPosition.dx;
                    var slot = ((axis - 4) / cell).floor().clamp(0, 2);
                    if (!vertical && _sign < 0) slot = 2 - slot;
                    _down(slot);
                  },
                  onPointerUp: (_) => _release(),
                  onPointerCancel: (_) {
                    if (_dragging) {
                      _finish(cancelled: true);
                    } else {
                      _release(cancelled: true);
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.start,
                    onHorizontalDragStart: vertical ? null : _begin,
                    onHorizontalDragUpdate: vertical
                        ? null
                        : (d) => _update(d, cell),
                    onHorizontalDragEnd: vertical
                        ? null
                        : (d) => _finish(
                            velocity: d.velocity.pixelsPerSecond.dx,
                            cell: cell,
                          ),
                    onHorizontalDragCancel: vertical
                        ? null
                        : () => _finish(cancelled: true),
                    onVerticalDragStart: vertical ? _begin : null,
                    onVerticalDragUpdate: vertical
                        ? (d) => _update(d, cell)
                        : null,
                    onVerticalDragEnd: vertical
                        ? (d) => _finish(
                            velocity: d.velocity.pixelsPerSecond.dy,
                            cell: cell,
                          )
                        : null,
                    onVerticalDragCancel: vertical
                        ? () => _finish(cancelled: true)
                        : null,
                    child: AnimatedBuilder(
                      animation: _animations,
                      builder: (context, _) {
                        final pressure = _press.value.clamp(0.0, 1.0);
                        // m32560 affects only the captured bar material.
                        final barScale = _reduceMotion
                            ? 1.0
                            : 1 +
                                  4 *
                                      CoolapkNavigationStyle.padding /
                                      constraints.maxWidth *
                                      pressure;
                        final velocity = _reduceMotion ? 0.0 : _velocity.value;
                        final sx =
                            _scaleX.value /
                            (1 - (velocity / 10 * .75).clamp(-.2, .2));
                        final sy =
                            _scaleY.value *
                            (1 - (velocity / 10 * .25).clamp(-.2, .2));
                        final slot = !vertical && _sign < 0
                            ? 2 - _position.value
                            : _position.value;
                        final cross = CoolapkNavigationStyle.selectionHeight;
                        final crossInset =
                            ((vertical
                                    ? constraints.maxWidth
                                    : constraints.maxHeight) -
                                cross) /
                            2;
                        final base = Rect.fromLTWH(
                          vertical ? crossInset : 4 + cell * slot,
                          vertical ? 4 + cell * slot : crossInset,
                          vertical ? cross : cell,
                          vertical ? cell : cross,
                        );
                        final thumb = Rect.fromCenter(
                          center: base.center,
                          width: base.width * (vertical ? sy : sx),
                          height: base.height * (vertical ? sx : sy),
                        );
                        final selected = _preview ?? widget.selected;
                        final controls = Padding(
                          padding: const EdgeInsets.all(4),
                          child: Flex(
                            direction: vertical
                                ? Axis.vertical
                                : Axis.horizontal,
                            children: List.generate(
                              3,
                              (i) => Expanded(
                                child: Semantics(
                                  label: LiquidNavigationDock.labels[i],
                                  selected: selected == i,
                                  button: true,
                                  child: Tooltip(
                                    triggerMode: TooltipTriggerMode.manual,
                                    message: LiquidNavigationDock.labels[i],
                                    excludeFromSemantics: true,
                                    child: InkWell(
                                      key: ValueKey(
                                        'nav-${const ['/', '/statistics', '/profile'][i]}',
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      splashFactory: NoSplash.splashFactory,
                                      highlightColor: Colors.transparent,

                                      onTapCancel: () =>
                                          _release(cancelled: true),
                                      onTapUp: (_) => _release(),
                                      onTap: () => _select(i),
                                      child: Center(
                                        child: ExcludeSemantics(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                LiquidNavigationDock.icons[i],
                                                size: 24,
                                                color: visibleContent,
                                              ),
                                              Text(
                                                LiquidNavigationDock.labels[i],
                                                maxLines: 1,
                                                textScaler:
                                                    MediaQuery.textScalerOf(
                                                      context,
                                                    ).clamp(
                                                      maxScaleFactor: 1.4,
                                                    ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontSize: 10,
                                                      height: 1.2,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: visibleContent,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                        // Keep the isolated capture at the authored glyph size.
                        // Only lens geometry grows; edge refraction is separate.
                        final capture = ExcludeSemantics(
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Flex(
                                direction: vertical
                                    ? Axis.vertical
                                    : Axis.horizontal,
                                children: List.generate(
                                  3,
                                  (i) => Expanded(
                                    child: Center(
                                      child: Column(
                                        key: ValueKey('nav-accent-$i'),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LiquidNavigationDock.icons[i],
                                            size: 24,
                                            color: colors.primary,
                                          ),
                                          Text(
                                            LiquidNavigationDock.labels[i],
                                            maxLines: 1,
                                            textScaler: MediaQuery.textScalerOf(
                                              context,
                                            ).clamp(maxScaleFactor: 1.4),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  fontSize: 10,
                                                  height: 1.2,
                                                  fontWeight: FontWeight.w700,
                                                  color: colors.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CoolapkNavigationSurface(
                                thumb: thumb,
                                press: pressure,
                                capability: capability,
                                sampleBackdrop: widget.refractBackdrop,
                                barScale: barScale,
                                refractContent: true,
                                contentAccent: colors.primary,
                                accentChild: capture,
                                outsideShadow: _OutsideDockShadow(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0x29000000)
                                      : const Color(0x18000000),
                                  thumb,
                                  barScale,
                                  pressure,
                                ),
                                child: controls,
                              ),
                            ),
                            // Geometry marker for tests and accessibility inspection;
                            // visual background and content are rendered independently.
                            Positioned.fromRect(
                              rect: base,
                              child: IgnorePointer(
                                child: Transform(
                                  key: const Key('liquid-indicator-transform'),
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(
                                    thumb.width / base.width,
                                    thumb.height / base.height,
                                    1,
                                  ),
                                  child: const SizedBox.expand(
                                    key: Key('liquid-indicator'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OutsideDockShadow extends CustomPainter {
  const _OutsideDockShadow(this.color, this.thumb, this.barScale, this.press);
  final Color color;
  final Rect thumb;
  final double barScale, press;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = CoolapkNavigationStyle.containerBounds(size, barScale);
    final shape = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(math.min(rect.width, rect.height) / 2),
        ),
      );
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(40)),
      Path.combine(
        PathOperation.union,
        shape,
        Path()..addRRect(
          RRect.fromRectAndRadius(
            thumb,
            Radius.circular(thumb.shortestSide / 2),
          ),
        ),
      ),
    );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawPath(
      shape.shift(const Offset(0, 4)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
    if (press > 0) {
      final lens = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            thumb,
            Radius.circular(thumb.shortestSide / 2),
          ),
        );
      canvas.save();
      // Shadow falls on the bar as well as the page, but never inside the lens.
      // This painter runs after both captures, so shadows cannot be refracted.
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(thumb.inflate(36)),
          lens,
        ),
      );
      canvas.drawPath(
        lens.shift(const Offset(0, CoolapkNavigationStyle.outerShadowOffsetY)),
        Paint()
          ..color = Colors.black.withValues(alpha: .1 * press)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            CoolapkNavigationStyle.outerShadowRadius / 2,
          ),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_OutsideDockShadow oldDelegate) =>
      color != oldDelegate.color ||
      thumb != oldDelegate.thumb ||
      barScale != oldDelegate.barScale ||
      press != oldDelegate.press;
}
