import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

/// Rebind navigation optics when retained ancestors move during composition.
class NavigationBackdropLayer extends BackdropFilterLayer {
  NavigationBackdropLayer(this.bindFilter, BackdropKey key) {
    // Base setters use markNeedsAddToScene. Initialize them before enabling
    // unconditional composition, which prohibits that dirty-tracking call.
    backdropKey = key;
    _live = true;
  }

  final ui.ImageFilter Function() bindFilter;
  bool _live = false;

  @override
  bool get alwaysNeedsAddToScene => _live;

  // Binding here also tracks transforms of retained parents without mutating
  // layer properties during addToScene.
  @override
  ui.ImageFilter get filter => bindFilter();
}
