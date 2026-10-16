import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// The same material for banner notices and informational popovers.
class GlassFloatingSurface extends StatelessWidget {
  const GlassFloatingSurface({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
  });
  static const opacity = .50;
  static const blur = 12.0;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color:
                (theme.brightness == Brightness.dark
                        ? const Color(0xFF242426)
                        : Colors.white)
                    .withValues(alpha: opacity),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: .08),
              width: .7,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
