import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Navigation-only constants: bn1 -> os8 copy mask 34567 -> ps8/pq8.
/// Lengths are Android dp == Flutter logical pixels; converted once at paint.
abstract final class CoolapkNavigationStyle {
  static const padding = 4.0;
  // C5164 -> jo8.CompactSpec -> qs8: container is 56, not 56+padding.
  static const height = 56.0;
  static const contentHeight = height - padding * 2;
  static const selectionHeight = contentHeight * 1.08;
  static const maxWidth = 480.0;
  static const preferredSlotWidth = 88.0;
  static double widthForItems(int count) =>
      math.min(maxWidth, padding * 2 + preferredSlotWidth * count);
  static Rect containerBounds(Size size, double scale) => Rect.fromCenter(
    center: (Offset.zero & size).center,
    width: size.width * scale,
    height: size.height * scale,
  );
  static const hostInset = 20.0;
  // ps8 -> bn1 copy mask retains this motion target on both axes.
  static const pressedHeightRatio = 1.3928572;
  // Reference-guided reduction of captured bar material only. Sampling farther
  // from the lens centre makes the bar's boundaries recede symmetrically.
  // These are Flutter mapping adjustments, not recovered Android constants.
  static const barLensAlongReduction = .08;
  static const barLensCrossReduction = .12;
  static const blur = 2.0;
  static const backgroundHeight = 16.0;
  static const backgroundAmount = 32.0;
  static const thumbHeight = 7.0;
  static const thumbAmount = 9.8;
  static const captureBleed = 32.0;
  static const innerShadowRadius = 8.0;
  static const outerShadowRadius = 24.0;
  static const outerShadowOffsetY = 4.0;
  static Color container(bool dark, {bool fallback = false}) =>
      Color(dark ? 0xff121212 : 0xfffafafa)
          .withValues(alpha: fallback ? .90 : .63);
  static Color selection(bool dark) =>
      (dark ? Colors.white : Colors.black).withValues(alpha: .10);
  // The Thumb samples the already rendered navigation material.
  static Color thumbContainer(
    bool dark,
    double press, {
    bool fallback = false,
  }) => Colors.transparent;
  // m=1; c=2*zeta*sqrt(k*m). Compose's ratio is not Flutter's damping.
  static SpringDescription spring(double ratio, double stiffness) =>
      SpringDescription(
        mass: 1,
        stiffness: stiffness,
        damping: 2 * ratio * math.sqrt(stiffness),
      );
  static final positionSpring = spring(1, 1000);
  static final effectSpring = spring(1, 1000);
  static final scaleXSpring = spring(.6, 250);
  static final scaleYSpring = spring(.7, 250);
  static final velocitySpring = spring(.5, 300);
}

/// Separate from shared surface quality so other glass components keep their
/// existing behavior. Full is gated by actual Flutter engine capability.
enum NavigationGlassCapability { liquid, blur, translucent }
