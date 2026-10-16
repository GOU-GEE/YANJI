import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'glass_controls.dart';
import 'liquid_glass_surface.dart';
import 'yanji_glass_theme.dart';

/// A compact dock: one backdrop lens moves behind its labels when tapped or
/// dragged, then settles into a quiet selected tint.
class GlassSegmentedControl extends StatefulWidget {
  const GlassSegmentedControl({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final FutureOr<bool> Function(int index) onSelected;

  @override
  State<GlassSegmentedControl> createState() => _GlassSegmentedControlState();
}

class _GlassSegmentedControlState extends State<GlassSegmentedControl>
    with TickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 32,
  );
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selected.toDouble(),
  );
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );
  bool _dragging = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _position.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_dragging) _setLift(0);
    });
  }

  void _setLift(double target) {
    if (_reduceMotion) {
      _lift.value = 0;
      return;
    }
    _lift.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 340, damping: 25),
        _lift.value,
        target,
        _lift.velocity,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (_reduceMotion) {
      _position.value = widget.selected.toDouble();
      _lift.value = 0;
    }
  }

  @override
  void didUpdateWidget(GlassSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected && !_dragging) {
      _settle(widget.selected);
    }
  }

  void _settle(int target) {
    if (_reduceMotion) {
      _position.value = target.toDouble();
    } else {
      _position.animateWith(
        SpringSimulation(
          _spring,
          _position.value,
          target.toDouble(),
          _position.velocity,
        ),
      );
    }
  }

  Future<void> _choose(int index) async {
    if (!_dragging && index != widget.selected) {
      _setLift(1);
      _settle(index);
    }
    final accepted = await widget.onSelected(index);
    if (!mounted) return;
    if (!accepted) _settle(widget.selected);
  }

  @override
  void dispose() {
    _position.dispose();
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassElastic(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth / widget.labels.length;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) {
            if (_reduceMotion) return;
            _position.stop();
            _setLift(1);
            setState(() => _dragging = true);
          },
          onHorizontalDragUpdate: (details) {
            if (!_dragging) return;
            _position.value = (_position.value + details.delta.dx / cell).clamp(
              0.0,
              (widget.labels.length - 1).toDouble(),
            );
          },
          onHorizontalDragEnd: (_) {
            if (!_dragging) return;
            final target = _position.value.round();
            setState(() => _dragging = false);
            _settle(target);
            _setLift(0);
            _choose(target);
          },
          onHorizontalDragCancel: () {
            if (!_dragging) return;
            setState(() => _dragging = false);
            _settle(widget.selected);
            _setLift(0);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_position, _lift]),
            builder: (context, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(
                  child: YanjiGlassSurface(
                    radius: 22,
                    strength: YanjiGlassStrength.control,
                    // The bar sits on the opaque statistics page. Its
                    // elastic transform stays, while only the moving bubble
                    // needs to refract the labels behind it.
                    refractBackdrop: false,
                    child: SizedBox.expand(),
                  ),
                ),
                Row(
                  children: [
                    for (final (index, label) in widget.labels.indexed)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: widget.selected == index,
                          label: label,
                          child: InkWell(
                            onTap: () => _choose(index),
                            borderRadius: BorderRadius.circular(22),
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  left: cell * _position.value + 3,
                  top: 3,
                  width: cell - 6,
                  height: 36,
                  child: IgnorePointer(
                    child: Transform(
                      key: const Key('range-glass-transform'),
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(0, 0, 1 + .14 * _lift.value.clamp(0, 1))
                        ..setEntry(1, 1, 1 + .20 * _lift.value.clamp(0, 1)),
                      child: YanjiGlassSurface(
                        key: const Key('range-glass-indicator'),
                        radius: 18,
                        strength: YanjiGlassStrength.indicator,
                        opticalActivity: _reduceMotion
                            ? 0
                            : (_dragging
                                  ? 1
                                  : (_position.velocity.abs() / 3).clamp(0, 1)),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
