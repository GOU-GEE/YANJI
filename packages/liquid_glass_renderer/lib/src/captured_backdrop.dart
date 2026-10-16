import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// OHOS ships Skia, whose runtime effects can sample images but cannot be
/// ImageFilters. Feed the same optical shaders an explicit, ordered backdrop.
bool get usesCapturedGlass =>
    !kIsWeb &&
    defaultTargetPlatform.name == 'ohos' &&
    !ui.ImageFilter.isShaderFilterSupported;

bool get supportsGlassShaders =>
    !kIsWeb && (ui.ImageFilter.isShaderFilterSupported || usesCapturedGlass);

/// Captures the scene prefix at composition time, after repaint boundaries have
/// reattached. Never captures this layer, later siblings, or last frame's ink.
/// The crop is in physical screen coordinates; shader equations stay unchanged.
class CapturedBackdropLayer extends ContainerLayer {
  CapturedBackdropLayer({
    required this.transform,
    required this.bounds,
    required this.viewport,
    required this.dpr,
    required this.shader,
    required this.bind,
    this.blur = 0,
  });
  final Matrix4 Function() transform;
  final Rect Function() bounds;
  final Size Function() viewport;
  final double dpr;
  final ui.FragmentShader shader;
  final void Function(ui.Image image, Rect crop) bind;
  final double blur;
  Offset paintOffset = Offset.zero;
  ui.Picture? _picture;
  ui.Image? _image;
  Duration? _frame;

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder) {
    final frame = SchedulerBinding.instance.currentFrameTimeStamp;
    if (_frame != frame || _picture == null) {
      final matrix = transform();
      final area = MatrixUtils.transformRect(matrix, bounds());
      final physicalArea = Rect.fromLTRB(
        area.left * dpr,
        area.top * dpr,
        area.right * dpr,
        area.bottom * dpr,
      );
      final screen = Offset.zero & viewport();
      final padded =
          physicalArea.inflate((64 + blur * 3) * dpr).intersect(screen);
      if (padded.isEmpty) return;
      final crop = Rect.fromLTRB(
          padded.left.floorToDouble(),
          padded.top.floorToDouble(),
          padded.right.ceilToDouble(),
          padded.bottom.ceilToDouble());
      final source = ui.SceneBuilder()..pushOffset(-crop.left, -crop.top);
      Layer root = this;
      while (root.parent != null) {
        root = root.parent!;
      }
      // RenderView normally owns the physical scaling TransformLayer. The
      // detached root case is useful for offscreen rendering and tests.
      final detached = root is! TransformLayer;
      if (detached) {
        source.pushTransform(Matrix4.diagonal3Values(dpr, dpr, 1).storage);
      }
      _prefix(root, this, source);
      if (detached) source.pop();
      source.pop();
      final scene = source.build();
      var image = scene.toImageSync(crop.width.toInt(), crop.height.toInt());
      scene.dispose();
      if (blur > .001) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImage(
            image,
            Offset.zero,
            Paint()
              ..imageFilter = ui.ImageFilter.blur(
                  sigmaX: blur * dpr,
                  sigmaY: blur * dpr,
                  tileMode: ui.TileMode.clamp));
        final pic = recorder.endRecording();
        final blurred = pic.toImageSync(image.width, image.height);
        pic.dispose();
        image.dispose();
        image = blurred;
      }
      bind(image, crop);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.translate(paintOffset.dx, paintOffset.dy);
      canvas.transform(Matrix4.inverted(matrix).storage);
      canvas.scale(1 / dpr);
      canvas.drawRect(physicalArea, Paint()..shader = shader);
      final picture = recorder.endRecording();
      _picture?.dispose();
      _image?.dispose();
      _picture = picture;
      _image = image;
      _frame = frame;
    }
    builder.addPicture(Offset.zero, _picture!);
    addChildrenToScene(builder);
  }

  static bool _prefix(Layer layer, Layer stop, ui.SceneBuilder builder) {
    if (identical(layer, stop)) return true;
    // Build an independent scene. Calling addToScene on live layers would
    // replace their engineLayer handles and reuse oldLayer across two builders.
    // That violates retained rendering when several lenses share a frame.
    if (layer is PictureLayer) {
      if (layer.picture != null) {
        builder.addPicture(Offset.zero, layer.picture!,
            isComplexHint: layer.isComplexHint,
            willChangeHint: layer.willChangeHint);
      }
      return false;
    }
    if (layer is TextureLayer) {
      builder.addTexture(layer.textureId,
          offset: layer.rect.topLeft,
          width: layer.rect.width,
          height: layer.rect.height,
          freeze: layer.freeze,
          filterQuality: layer.filterQuality);
      return false;
    }
    if (layer is PlatformViewLayer) {
      builder.addPlatformView(layer.viewId,
          offset: layer.rect.topLeft,
          width: layer.rect.width,
          height: layer.rect.height);
      return false;
    }
    if (layer is PerformanceOverlayLayer) {
      builder.addPerformanceOverlay(layer.optionsMask, layer.overlayRect);
      return false;
    }
    final container = layer as ContainerLayer;
    if (layer is CapturedBackdropLayer && layer._picture != null) {
      builder.addPicture(Offset.zero, layer._picture!);
    }
    var pushes = 0;
    if (layer is TransformLayer) {
      final m = Matrix4.translationValues(layer.offset.dx, layer.offset.dy, 0)
        ..multiply(layer.transform!);
      builder.pushTransform(m.storage);
      pushes++;
    } else if (layer is ImageFilterLayer) {
      builder.pushImageFilter(layer.imageFilter!, offset: layer.offset);
      pushes++;
    } else if (layer is OpacityLayer) {
      builder.pushOpacity(layer.alpha!, offset: layer.offset);
      pushes++;
    } else if (layer is OffsetLayer) {
      builder.pushOffset(layer.offset.dx, layer.offset.dy);
      pushes++;
    } else if (layer is ClipRectLayer) {
      builder.pushClipRect(layer.clipRect!, clipBehavior: layer.clipBehavior);
      pushes++;
    } else if (layer is ClipRRectLayer) {
      builder.pushClipRRect(layer.clipRRect!, clipBehavior: layer.clipBehavior);
      pushes++;
    } else if (layer is ClipRSuperellipseLayer) {
      builder.pushClipRSuperellipse(layer.clipRSuperellipse!,
          clipBehavior: layer.clipBehavior);
      pushes++;
    } else if (layer is ClipPathLayer) {
      builder.pushClipPath(layer.clipPath!, clipBehavior: layer.clipBehavior);
      pushes++;
    } else if (layer is ColorFilterLayer) {
      builder.pushColorFilter(layer.colorFilter!);
      pushes++;
    } else if (layer is BackdropFilterLayer) {
      builder.pushBackdropFilter(layer.filter!, blendMode: layer.blendMode);
      pushes++;
    } else if (layer is ShaderMaskLayer) {
      builder.pushShaderMask(layer.shader!, layer.maskRect!, layer.blendMode!);
      pushes++;
    } else if (layer is LeaderLayer) {
      builder.pushOffset(layer.offset.dx, layer.offset.dy);
      pushes++;
    } else if (layer is FollowerLayer) {
      final m = layer.getLastTransform() ??
          Matrix4.translationValues(
              layer.unlinkedOffset!.dx, layer.unlinkedOffset!.dy, 0);
      builder.pushTransform(m.storage);
      pushes++;
    } else if (layer.runtimeType != ContainerLayer &&
        layer is! AnnotatedRegionLayer &&
        layer is! CapturedBackdropLayer) {
      throw StateError(
          'Unsupported glass backdrop ancestor: ${layer.runtimeType}');
    }
    var found = false;
    Layer? child = container.firstChild;
    while (child != null) {
      if (_prefix(child, stop, builder)) {
        found = true;
        break;
      }
      child = child.nextSibling;
    }
    for (var i = 0; i < pushes; i++) {
      builder.pop();
    }
    return found;
  }

  @override
  void dispose() {
    _picture?.dispose();
    _image?.dispose();
    super.dispose();
  }
}
