import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'liquid_glass_quality.dart';
import 'yanji_glass_theme.dart';

/// A bounded backdrop surface. Children paint above the refracted background.
/// A separate indicator layer intentionally samples the outer glass as well;
/// sharing overlapping shapes would flatten them into one optical surface.
class YanjiGlassSurface extends StatelessWidget {
  const YanjiGlassSurface({
    super.key,
    this.quality,
    required this.child,
    this.radius = 32,
    this.strength = YanjiGlassStrength.surface,
    this.opticalActivity = 1,
    this.overlayColor,
    this.refractBackdrop = true,
  });

  final YanjiGlassQuality? quality;
  final Widget child;
  final double radius;
  final YanjiGlassStrength strength;
  final Color? overlayColor;
  final bool refractBackdrop;

  /// The navigation lens fades its optics with speed and bypasses the shader
  /// at rest, keeping the underlying icon and label pixel positions intact.
  final double opticalActivity;

  @override
  Widget build(BuildContext context) {
    if (!refractBackdrop) {
      final tokens = YanjiGlassTheme.of(context);
      return DecoratedBox(
        decoration: ShapeDecoration(
          color:
              overlayColor ??
              tokens.colors.surface.withValues(alpha: tokens.dark ? .42 : .38),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: tokens.edgeLight, width: .6),
          ),
        ),
        child: child,
      );
    }
    if (quality == null) {
      return FutureBuilder<YanjiGlassQuality>(
        future: YanjiGlassQuality.resolve(),
        builder: (context, snapshot) => YanjiGlassSurface(
          quality: snapshot.data ?? YanjiGlassQuality.reduced,
          radius: radius,
          strength: strength,
          opticalActivity: opticalActivity,
          overlayColor: overlayColor,
          refractBackdrop: refractBackdrop,
          child: child,
        ),
      );
    }
    final tokens = YanjiGlassTheme.of(context);
    final shape = LiquidRoundedSuperellipse(borderRadius: radius);
    if (strength == YanjiGlassStrength.indicator && opticalActivity <= .0001) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          color: tokens.colors.surface.withValues(
            alpha: tokens.dark ? .06 : .035,
          ),
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: tokens.edgeLight, width: .6),
          ),
        ),
        child: child,
      );
    }
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: LiquidGlassLayer(
        fake: quality == YanjiGlassQuality.reduced,
        settings: tokens.settings(strength, opticalActivity: opticalActivity),
        child: LiquidGlass(
          shape: shape,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color:
                  overlayColor ??
                  (strength == YanjiGlassStrength.modal
                      ? tokens.colors.surface.withValues(
                          alpha: tokens.dark ? .78 : .62,
                        )
                      : null),
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(radius),
                side: BorderSide(color: tokens.edgeLight, width: .6),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
