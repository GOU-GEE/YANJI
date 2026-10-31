import 'package:flutter/material.dart';

import 'coolapk_navigation_style.dart';
import 'liquid_navigation_dock.dart';

/// Move the live glass out of view without an opacity saveLayer, which would
/// isolate its backdrop from the page while the dock is entering or leaving.
class NavigationDockTransition extends StatelessWidget {
  const NavigationDockTransition({
    super.key,
    required this.hidden,
    required this.vertical,
    required this.edgeInset,
    required this.child,
  });

  final bool hidden, vertical;
  final double edgeInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return IgnorePointer(
      ignoring: hidden,
      child: TweenAnimationBuilder<double>(
        duration: reduced
            ? Duration.zero
            : Duration(milliseconds: hidden ? 175 : 225),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(end: hidden ? 0 : 1),
        child: child,
        builder: (context, visibility, child) => NavigationDockFrame(
          visibility: visibility,
          vertical: vertical,
          edgeInset: edgeInset,
          child: child!,
        ),
      ),
    );
  }
}

/// One frame of the dock's motion; no intermediate offscreen paint target.
class NavigationDockFrame extends StatelessWidget {
  const NavigationDockFrame({
    super.key,
    required this.visibility,
    required this.vertical,
    required this.edgeInset,
    required this.child,
  });

  final double visibility, edgeInset;
  final bool vertical;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final travel =
        (vertical
            ? LiquidNavigationDock.verticalWidth
            : LiquidNavigationDock.height) +
        edgeInset +
        CoolapkNavigationStyle.captureBleed;
    final remaining = 1 - visibility;
    return Offstage(
      offstage: visibility == 0,
      child: Transform.translate(
        offset: vertical
            ? Offset(-travel * remaining, 0)
            : Offset(0, travel * remaining),
        child: Transform.scale(scale: 1 - .08 * remaining, child: child),
      ),
    );
  }
}
