import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/navigation_backdrop_layer.dart';

void main() {
  test('backdrop key initializes before unconditional scene composition', () {
    final key = BackdropKey();
    final layer = NavigationBackdropLayer(
      () => ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      key,
    );
    final handle = LayerHandle<NavigationBackdropLayer>(layer);
    expect(layer.backdropKey, same(key));
    expect(layer.alwaysNeedsAddToScene, isTrue);
    handle.layer = null;
  });

  test('retained layer resolves the current filter on each composition', () {
    var current = ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2);
    final layer = NavigationBackdropLayer(() => current, BackdropKey());
    final handle = LayerHandle<NavigationBackdropLayer>(layer);
    expect(layer.filter, same(current));
    current = ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4);
    expect(layer.filter, same(current));
    handle.layer = null;
  });
}
