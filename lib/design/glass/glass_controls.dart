import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'liquid_glass_surface.dart';
import 'yanji_glass_theme.dart';

/// Regular controls sit on a flat surface and do not need backdrop sampling.
/// Keep the material and elastic gesture independent from the optical shader.
class YanjiGlassControl extends StatelessWidget {
  const YanjiGlassControl({
    super.key,
    required this.child,
    this.radius = 20,
    this.elastic = false,
    this.elasticity = 1,
    this.surfaceColor,
  });
  final Widget child;
  final double radius;
  final bool elastic;
  final double elasticity;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final glass = YanjiGlassSurface(
      radius: radius,
      strength: YanjiGlassStrength.control,
      refractBackdrop: false,
      overlayColor: surfaceColor,
      // Ink effects from ListTile/InkWell need their own clipped Material.
      // Otherwise they paint on the page's rectangular Material behind the
      // rounded glass surface.
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
    return elastic ? GlassElastic(strength: elasticity, child: glass) : glass;
  }
}

/// Follows a held pointer without taking the tap or drag gesture from a button.
class GlassElastic extends StatefulWidget {
  const GlassElastic({super.key, this.strength = 1, required this.child});
  final double strength;
  final Widget child;

  @override
  State<GlassElastic> createState() => _ElasticGlassState();
}

class _ElasticGlassState extends State<GlassElastic>
    with SingleTickerProviderStateMixin {
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
    _rebound.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 330, damping: 26),
        _rebound.value,
        0,
        _rebound.velocity,
      ),
    );
  }

  @override
  void dispose() {
    _rebound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Listener(
      onPointerDown: reduced
          ? null
          : (event) {
              if (_pointer != null) return;
              _pointer = event.pointer;
              _origin = event.localPosition;
              final width = context.size?.width ?? 1;
              _touchX = (event.localPosition.dx / width * 2 - 1).clamp(-1, 1);
              _pull = Offset.zero;
              _rebound.stop();
              _rebound.value = 1;
            },
      onPointerMove: reduced
          ? null
          : (event) {
              if (_pointer != event.pointer) return;
              setState(() {
                final delta = event.localPosition - _origin;
                _pull = Offset(
                  delta.dx.clamp(-45.0, 45.0),
                  delta.dy.clamp(-45.0, 45.0),
                );
              });
            },
      onPointerUp: reduced ? null : (event) => _release(event.pointer),
      onPointerCancel: reduced ? null : (event) => _release(event.pointer),
      child: AnimatedBuilder(
        animation: _rebound,
        child: widget.child,
        builder: (context, child) {
          final pull = _pull * _rebound.value * widget.strength;
          final x = pull.dx / 45;
          final y = pull.dy / 45;
          final matrix = Matrix4.identity()
            ..setTranslationRaw(pull.dx * .12, pull.dy * .12, 0)
            ..setEntry(0, 0, 1 + x.abs() * .10 - y.abs() * .025)
            ..setEntry(1, 1, 1 + y.abs() * .10 - x.abs() * .025)
            ..setEntry(0, 1, x * .025)
            // The held edge follows the finger: a left-side pull bends left,
            // while the same motion from the right bends right.
            ..setEntry(1, 0, y * .05 * _touchX);
          return Transform(
            key: const Key('glass-elastic-transform'),
            alignment: Alignment.center,
            transform: matrix,
            child: child,
          );
        },
      ),
    );
  }
}

enum _ButtonKind { filled, outlined, text }

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    super.key,
    required this.kind,
    required this.onPressed,
    required this.child,
    this.style,
    this.icon,
    this.surfaceColor,
  });
  final _ButtonKind kind;
  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final Color? surfaceColor;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effective = (style ?? const ButtonStyle()).copyWith(
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize:
          style?.minimumSize ?? const WidgetStatePropertyAll(Size(88, 44)),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      // Override both the theme default and any existing per-button outline.
      side: const WidgetStatePropertyAll(BorderSide.none),
      foregroundColor:
          style?.foregroundColor ??
          WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? colors.onSurface.withValues(alpha: .38)
                : colors.primary,
          ),
    );
    final button = switch ((kind, icon)) {
      (_ButtonKind.filled, null) => FilledButton(
        onPressed: onPressed,
        style: effective,
        child: child,
      ),
      (_ButtonKind.filled, final glyph?) => FilledButton.icon(
        onPressed: onPressed,
        style: effective,
        icon: glyph,
        label: child,
      ),
      (_ButtonKind.outlined, null) => OutlinedButton(
        onPressed: onPressed,
        style: effective,
        child: child,
      ),
      (_ButtonKind.outlined, final glyph?) => OutlinedButton.icon(
        onPressed: onPressed,
        style: effective,
        icon: glyph,
        label: child,
      ),
      (_ButtonKind.text, null) => TextButton(
        onPressed: onPressed,
        style: effective,
        child: child,
      ),
      (_ButtonKind.text, final glyph?) => TextButton.icon(
        onPressed: onPressed,
        style: effective,
        icon: glyph,
        label: child,
      ),
    };
    return YanjiGlassControl(
      radius: 12,
      elastic: onPressed != null,
      surfaceColor: surfaceColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor == null
              ? colors.surface.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? .48
                      : .62,
                )
              : Colors.transparent,
        ),
        child: button,
      ),
    );
  }
}

class GlassFilledButton extends _GlassButton {
  const GlassFilledButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.style,
  }) : super(kind: _ButtonKind.filled);
  const GlassFilledButton.icon({
    super.key,
    required super.onPressed,
    required Widget label,
    required Widget icon,
    super.style,
  }) : super(kind: _ButtonKind.filled, child: label, icon: icon);
}

class GlassOutlinedButton extends _GlassButton {
  const GlassOutlinedButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.style,
    super.surfaceColor,
  }) : super(kind: _ButtonKind.outlined);
  const GlassOutlinedButton.icon({
    super.key,
    required super.onPressed,
    required Widget label,
    required Widget icon,
    super.style,
    super.surfaceColor,
  }) : super(kind: _ButtonKind.outlined, child: label, icon: icon);
}

class GlassTextButton extends _GlassButton {
  const GlassTextButton({
    super.key,
    required super.onPressed,
    required super.child,
    super.style,
  }) : super(kind: _ButtonKind.text);
  const GlassTextButton.icon({
    super.key,
    required super.onPressed,
    required Widget label,
    required Widget icon,
    super.style,
  }) : super(kind: _ButtonKind.text, child: label, icon: icon);
}

/// Keep Dialog's keyboard avoidance, route behavior and constraints intact.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.child,
    this.alignment,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    this.constraints,
    this.dismissibleByDrag = true,
  });
  final bool dismissibleByDrag;
  final Widget child;
  final AlignmentGeometry? alignment;
  final EdgeInsets insetPadding;
  final BoxConstraints? constraints;
  @override
  Widget build(BuildContext context) => Dialog(
    alignment: alignment,
    insetPadding: insetPadding,
    constraints: constraints,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    child: dismissibleByDrag
        ? _SwipeDismissGlass(
            child: YanjiGlassSurface(
              radius: 24,
              strength: YanjiGlassStrength.modal,
              child: child,
            ),
          )
        : YanjiGlassSurface(
            radius: 24,
            strength: YanjiGlassStrength.modal,
            child: child,
          ),
  );
}

/// Dismisses a dialog with a deliberate left, right, or upward swipe.
/// Descendant scroll views and pickers keep their own drag gestures.
class _SwipeDismissGlass extends StatefulWidget {
  const _SwipeDismissGlass({required this.child});
  final Widget child;

  @override
  State<_SwipeDismissGlass> createState() => _SwipeDismissGlassState();
}

class _SwipeDismissGlassState extends State<_SwipeDismissGlass> {
  Offset _offset = Offset.zero;
  bool _dragging = false;
  bool _dismissing = false;

  void _start() {
    if (_dismissing) return;
    setState(() => _dragging = true);
  }

  void _move(Offset delta) {
    if (_dismissing) return;
    setState(() => _offset += delta);
  }

  void _finish({required bool horizontal, required double velocity}) {
    if (_dismissing) return;
    final distance = horizontal ? _offset.dx : -_offset.dy;
    final movingTowardDismiss = horizontal
        ? velocity.sign == _offset.dx.sign
        : velocity < 0;
    final shouldDismiss = horizontal
        ? _offset.dx.abs() >= 72 ||
              (_offset.dx.abs() >= 24 &&
                  movingTowardDismiss &&
                  velocity.abs() >= 700)
        : distance >= 72 ||
              (distance >= 24 && movingTowardDismiss && velocity.abs() >= 700);
    if (!shouldDismiss) {
      setState(() {
        _dragging = false;
        _offset = Offset.zero;
      });
      return;
    }
    setState(() {
      _dragging = false;
      _dismissing = true;
      final size = MediaQuery.sizeOf(context);
      _offset = horizontal
          ? Offset(_offset.dx.sign * size.width, 0)
          : Offset(0, -size.height);
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    });
  }

  void _cancel() {
    if (_dismissing) return;
    setState(() {
      _dragging = false;
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragStart: (_) => _start(),
    onHorizontalDragUpdate: (details) => _move(Offset(details.delta.dx, 0)),
    onHorizontalDragEnd: (details) =>
        _finish(horizontal: true, velocity: details.primaryVelocity ?? 0),
    onHorizontalDragCancel: _cancel,
    onVerticalDragStart: (_) => _start(),
    onVerticalDragUpdate: (details) => _move(Offset(0, details.delta.dy)),
    onVerticalDragEnd: (details) =>
        _finish(horizontal: false, velocity: details.primaryVelocity ?? 0),
    onVerticalDragCancel: _cancel,
    child: AnimatedContainer(
      key: const Key('glass-dialog-swipe'),
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(_offset.dx, _offset.dy, 0),
      child: widget.child,
    ),
  );
}

class GlassAlertDialog extends StatelessWidget {
  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.actionBar,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    this.scrollable = false,
    this.dismissibleByDrag = true,
  });
  final Widget? title, content;
  final List<Widget> actions;
  final Widget? actionBar;
  final EdgeInsets insetPadding;
  final bool scrollable;
  final bool dismissibleByDrag;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassDialog(
      dismissibleByDrag: dismissibleByDrag,
      insetPadding: insetPadding,
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        role: SemanticsRole.dialog,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null) ...[
                        Semantics(
                          namesRoute: true,
                          child: DefaultTextStyle(
                            style: theme.textTheme.headlineSmall!,
                            child: title!,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (content != null)
                        DefaultTextStyle(
                          style: theme.textTheme.bodyMedium!,
                          child: content!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (actions.isNotEmpty || actionBar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child:
                    actionBar ??
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      spacing: 8,
                      overflowSpacing: 8,
                      children: actions,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, this.title, this.actions, this.leading});
  final Widget? title, leading;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    leading: leading,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: const YanjiGlassSurface(
      radius: 0,
      strength: YanjiGlassStrength.modal,
      child: SizedBox.expand(),
    ),
    actions: [
      for (final action in actions ?? const <Widget>[])
        if (action is IconButton)
          Padding(
            padding: const EdgeInsets.all(4),
            child: YanjiGlassControl(radius: 24, elastic: true, child: action),
          )
        else
          action,
    ],
  );
}
