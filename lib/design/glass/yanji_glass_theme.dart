import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

enum YanjiGlassStrength { surface, indicator, control, modal }

/// Optical tokens stay here so navigation and future overlays share a material.
class YanjiGlassTheme {
  YanjiGlassTheme.of(BuildContext context)
    : colors = Theme.of(context).colorScheme,
      dark = Theme.of(context).brightness == Brightness.dark;

  final ColorScheme colors;
  final bool dark;

  LiquidGlassSettings settings(
    YanjiGlassStrength strength, {
    double opticalActivity = 1,
  }) {
    final indicator = strength == YanjiGlassStrength.indicator;
    final modal = strength == YanjiGlassStrength.modal;
    final control = strength == YanjiGlassStrength.control;
    final activity = indicator ? opticalActivity.clamp(0.0, 1.0) : 1.0;
    return LiquidGlassSettings(
      // Logical pixels, consistently converted by the patched renderer.
      thickness: indicator ? 14 * activity : (control ? 6 : (modal ? 14 : 12)),
      blur: indicator ? 0 : (control ? .8 : (modal ? 5 : .55)),
      refractiveIndex: indicator ? 1 + .62 * activity : (modal ? 1.42 : 1.45),
      saturation: indicator ? 1.10 : 1.18,
      chromaticAberration: indicator
          ? .075 * activity
          : (modal ? .025 : (control ? .04 : .06)),
      highQualitySampling: indicator,
      edgeMagnification: indicator,
      // Uniform controls should not acquire a left/right lighting seam over
      // a flat backdrop. The edge keeps a restrained highlight.
      lightIntensity: (control ? .055 : (dark ? .20 : .26)) * activity,
      ambientStrength: (control ? .025 : (dark ? .04 : .07)) * activity,
      // Keep the moving lens clear; opacity on text-heavy dialogs protects
      // reading contrast while their optical edges still sample the backdrop.
      glassColor: colors.surface.withValues(
        alpha: modal
            ? (dark ? .12 : .15)
            : (indicator
                  ? (dark ? .06 : .035)
                  : (control ? (dark ? .42 : .38) : (dark ? .14 : .09))),
      ),
    );
  }

  Color get edgeLight => colors.onSurface.withValues(alpha: dark ? .13 : .10);
  Color get shadow => colors.shadow.withValues(alpha: dark ? .12 : .07);
}

/// Only the scroll content needs clearance; the background keeps painting
/// underneath the floating controls.
class YanjiDockClearance extends InheritedWidget {
  const YanjiDockClearance({
    super.key,
    required this.bottom,
    required this.left,
    required super.child,
  });
  final double bottom;
  final double left;

  static EdgeInsets of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<YanjiDockClearance>();
    return EdgeInsets.only(bottom: scope?.bottom ?? 0, left: scope?.left ?? 0);
  }

  @override
  bool updateShouldNotify(YanjiDockClearance oldWidget) =>
      bottom != oldWidget.bottom || left != oldWidget.left;
}
