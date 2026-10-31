import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'coolapk_navigation_style.dart';
import 'navigation_backdrop_layer.dart';

/// The bar samples the page. The Thumb then samples that navigation material;
/// only protruding parts see the page. Glyphs and shadows are drawn afterwards.
class CoolapkNavigationSurface extends StatefulWidget {
  const CoolapkNavigationSurface({
    super.key,
    required this.thumb,
    required this.press,
    required this.capability,
    required this.child,
    this.sampleBackdrop = true,
    this.barScale = 1,
    this.refractContent = true,
    this.contentAccent,
    this.accentChild,
    this.decorations = true,
    this.optics = true,
    this.reduceBarThroughLens = true,
    this.legacyCompression = false,
    this.onCapability,
    this.outsideShadow,
  });
  final Rect thumb;
  final double press;
  final NavigationGlassCapability capability;
  final Widget child;
  final bool sampleBackdrop;
  final double barScale;
  final bool refractContent;
  final Color? contentAccent;
  final Widget? accentChild;

  /// Reduce only the captured bar material, independently of accent glyphs.
  /// This is a reference-guided optical mapping, not a geometry transform.
  final bool reduceBarThroughLens;
  // Diagnostic switches are local to navigation, never shared glass settings.
  final bool decorations, optics, legacyCompression;
  final ValueChanged<NavigationGlassCapability>? onCapability;
  final CustomPainter? outsideShadow;
  @override
  State<CoolapkNavigationSurface> createState() => _SurfaceState();
}

class _SurfaceState extends State<CoolapkNavigationSurface> {
  static Future<(ui.FragmentProgram, ui.FragmentProgram)>? _programs;
  ui.FragmentShader? _background, _thumbBackground, _content;
  final _backdropKey = BackdropKey();
  final _thumbBackdropKey = BackdropKey();
  Object? _failure;
  @override
  void initState() {
    super.initState();
    if (supportsGlassShaders) {
      (_programs ??= _load()).then(
        (programs) {
          if (!mounted) return;
          setState(() {
            _background = programs.$1.fragmentShader();
            _thumbBackground = programs.$1.fragmentShader();
            _content = programs.$2.fragmentShader();
          });
        },
        onError: (Object error, StackTrace stack) {
          if (!mounted) return;
          setState(() => _failure = error);
          widget.onCapability?.call(NavigationGlassCapability.blur);
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'navigation glass',
              context: ErrorDescription(
                'loading navigation shaders; using blur',
              ),
            ),
          );
        },
      );
    }
  }

  static Future<(ui.FragmentProgram, ui.FragmentProgram)> _load() async {
    final programs = await Future.wait([
      ui.FragmentProgram.fromAsset(
        usesCapturedGlass
            ? 'assets/shaders/coolapk_navigation_captured.frag'
            : 'assets/shaders/coolapk_navigation.frag',
      ),
      ui.FragmentProgram.fromAsset('assets/shaders/coolapk_content.frag'),
    ]);
    return (programs[0], programs[1]);
  }

  @override
  void dispose() {
    _background?.dispose();
    _thumbBackground?.dispose();
    _content?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final capable = supportsGlassShaders && _failure == null;
    final requested = widget.sampleBackdrop
        ? widget.capability
        : NavigationGlassCapability.translucent;
    final effective = requested == NavigationGlassCapability.liquid && !capable
        ? NavigationGlassCapability.blur
        : requested;
    final backgroundReady =
        _background != null &&
        (effective == NavigationGlassCapability.liquid ||
            (!usesCapturedGlass &&
                effective == NavigationGlassCapability.blur));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final press = widget.press.clamp(0.0, 1.0);
    return Semantics(
      container: true,
      value: effective == NavigationGlassCapability.liquid && !backgroundReady
          ? '背景模糊（材质加载中）'
          : switch (effective) {
              NavigationGlassCapability.liquid => '液态玻璃',
              NavigationGlassCapability.blur => '背景模糊',
              NavigationGlassCapability.translucent => '半透明',
            },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (backgroundReady) ...[
            // Paint the bar first. The Thumb's distinct backdrop key reads
            // navigation material inside it and the page outside its edges.
            for (final thumbLayer in [false, true])
              Positioned.fill(
                child: ClipPath(
                  clipper: _BackgroundClipper(
                    widget.thumb,
                    thumbLayer,
                    widget.barScale,
                  ),
                  child: _OpticalBackground(
                    shader: thumbLayer ? _thumbBackground! : _background!,
                    backdropKey: thumbLayer ? _thumbBackdropKey : _backdropKey,
                    thumbLayer: thumbLayer,
                    barScale: widget.barScale,
                    thumb: widget.thumb,
                    press: press,
                    full:
                        widget.optics &&
                        effective == NavigationGlassCapability.liquid,
                    decorations: widget.decorations,
                    reduceBarThroughLens: widget.reduceBarThroughLens,
                    legacyCompression: widget.legacyCompression,
                    dark: dark,
                    dpr: dpr,
                  ),
                ),
              ),
          ] else
            Positioned.fill(
              child: ClipPath(
                clipper: _OpticalClipper(widget.thumb, widget.barScale),
                child: _FallbackBackground(
                  thumb: widget.thumb,
                  dark: dark,
                  press: press,
                  barScale: widget.barScale,
                  blur: effective != NavigationGlassCapability.translucent,
                  decorations: widget.decorations,
                  optics: widget.optics,
                ),
              ),
            ),
          // Paint shadow after background sampling: it cannot enter the
          // backdrop input, including when the pressed Thumb protrudes.
          if (widget.outsideShadow != null && widget.decorations)
            Positioned.fill(
              child: CustomPaint(
                key: const Key('navigation-dock-shadow'),
                painter: widget.outsideShadow,
              ),
            ),
          if (widget.accentChild != null)
            Positioned.fill(
              child: _VisibleGlyphCutout(
                thumb: widget.thumb,
                child: widget.child,
              ),
            ),
          // The isolated capture contains only AccentCapture glyphs; the
          // ordinary tree is cut out inside the lens, preventing double ink.
          if (widget.refractContent &&
              press > .0001 &&
              _content != null &&
              effective == NavigationGlassCapability.liquid)
            Positioned.fill(
              child: _OpticalContent(
                shader: _content!,
                thumb: widget.thumb,
                press: press,
                dpr: dpr,
                accent: widget.contentAccent,
                captureOnly: widget.accentChild != null,
                optics: widget.optics,
                legacyCompression: widget.legacyCompression,
                child: widget.accentChild ?? widget.child,
              ),
            )
          else if (widget.accentChild != null)
            Positioned.fill(
              child: ClipPath(
                clipper: _GlyphClipper(widget.thumb),
                child: widget.accentChild,
              ),
            )
          else
            Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground({
    required this.thumb,
    required this.dark,
    required this.press,
    required this.barScale,
    required this.blur,
    required this.decorations,
    required this.optics,
  });
  final Rect thumb;
  final bool dark, blur, decorations, optics;
  final double press;
  final double barScale;
  @override
  Widget build(BuildContext context) {
    // Skia cannot use ImageFilter.shader. Keep two ordered backdrop samples:
    // the bar blurs the page, and the pressed lens magnifies the bar beneath it.
    // Both captures precede shadows and glyphs, just like the shader path.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: barScale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1000),
              child: BackdropFilter(
                enabled: blur,
                filter: ui.ImageFilter.blur(
                  sigmaX: CoolapkNavigationStyle.blur,
                  sigmaY: CoolapkNavigationStyle.blur,
                ),
                child: CustomPaint(
                  foregroundPainter: decorations
                      ? _CompatibilityGlassRim(dark: dark, activity: .45)
                      : null,
                  child: ColoredBox(
                    color: CoolapkNavigationStyle.container(
                      dark,
                      fallback: !blur,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: thumb,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1000),
            child: _CompatibilityLens(
              magnification: blur && optics ? 1 + .12 * press : 1,
              blur: blur ? CoolapkNavigationStyle.blur * (1 - press) : 0,
              sampleBackdrop: blur,
              child: CustomPaint(
                foregroundPainter: decorations
                    ? _CompatibilityGlassRim(dark: dark, activity: press)
                    : null,
                child: ColoredBox(
                  color: Color.alphaBlend(
                    CoolapkNavigationStyle.selection(
                      dark,
                    ).withValues(alpha: .1 * (1 - press)),
                    Colors.white.withValues(alpha: (dark ? .04 : .10) * press),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A live affine lens for engines without shader backdrop filters. This uses
/// the current canvas coordinates, so it also follows dock translations/scales
/// without capturing stale page images or applying the screen DPR twice.
class _CompatibilityLens extends SingleChildRenderObjectWidget {
  const _CompatibilityLens({
    required this.magnification,
    required this.blur,
    required this.sampleBackdrop,
    required super.child,
  });
  final double magnification, blur;
  final bool sampleBackdrop;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _CompatibilityLensRender(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _CompatibilityLensRender render,
  ) {
    render.config = this;
    render.markNeedsPaint();
  }
}

class _CompatibilityLensRender extends RenderProxyBox {
  _CompatibilityLensRender(this.config);
  _CompatibilityLens config;
  final _handle = LayerHandle<BackdropFilterLayer>();
  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!config.sampleBackdrop) {
      super.paint(context, offset);
      return;
    }
    final center = offset + size.center(Offset.zero);
    final transform = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(config.magnification, config.magnification, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    final lens = ui.ImageFilter.matrix(
      transform.storage,
      filterQuality: FilterQuality.medium,
    );
    final layer = (_handle.layer ??= BackdropFilterLayer())
      ..filter = config.blur < .001
          ? lens
          : ui.ImageFilter.compose(
              outer: lens,
              inner: ui.ImageFilter.blur(
                sigmaX: config.blur,
                sigmaY: config.blur,
              ),
            );
    context.pushLayer(layer, super.paint, offset);
  }

  @override
  void dispose() {
    _handle.layer = null;
    super.dispose();
  }
}

class _CompatibilityGlassRim extends CustomPainter {
  const _CompatibilityGlassRim({required this.dark, required this.activity});
  final bool dark;
  final double activity;
  @override
  void paint(Canvas canvas, Size size) {
    if (activity <= .0001) return;
    final rect = (Offset.zero & size).deflate(.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: (dark ? .45 : .85) * activity),
            Colors.white.withValues(alpha: .08 * activity),
            Colors.black.withValues(alpha: (dark ? .20 : .12) * activity),
            Colors.white.withValues(alpha: .48 * activity),
          ],
          stops: const [0, .42, .7, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_CompatibilityGlassRim old) =>
      old.dark != dark || old.activity != activity;
}

class _OpticalBackground extends LeafRenderObjectWidget {
  const _OpticalBackground({
    required this.shader,
    required this.backdropKey,
    required this.thumbLayer,
    required this.barScale,
    required this.thumb,
    required this.press,
    required this.full,
    required this.decorations,
    required this.reduceBarThroughLens,
    required this.legacyCompression,
    required this.dark,
    required this.dpr,
  });
  final ui.FragmentShader shader;
  final Rect thumb;
  final double press, dpr, barScale;
  final BackdropKey backdropKey;
  final bool full,
      dark,
      thumbLayer,
      decorations,
      reduceBarThroughLens,
      legacyCompression;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _BackgroundRender(this);
  @override
  void updateRenderObject(
    BuildContext context,
    _BackgroundRender renderObject,
  ) {
    renderObject.config = this;
    renderObject.markNeedsPaint();
  }
}

class _BackgroundRender extends RenderBox {
  _BackgroundRender(this.config);
  _OpticalBackground config;
  final _handle = LayerHandle<NavigationBackdropLayer>();
  final _captureHandle = LayerHandle<CapturedBackdropLayer>();
  @override
  bool get alwaysNeedsCompositing => true;
  @override
  void performLayout() => size = constraints.biggest;
  void _bind() {
    // A null target excludes RenderView.applyPaintTransform (the root DPR).
    // Explicitly targeting RenderView includes that transform on this SDK.
    final transform = getTransformTo(null);
    final bar = MatrixUtils.transformRect(
      transform,
      CoolapkNavigationStyle.containerBounds(size, config.barScale),
    );
    final thumb = MatrixUtils.transformRect(transform, config.thumb);
    final dpr = config.dpr;
    final shader = config.shader;
    final values = <double>[
      bar.left * dpr,
      bar.top * dpr,
      bar.width * dpr,
      bar.height * dpr,
      thumb.left * dpr,
      thumb.top * dpr,
      thumb.width * dpr,
      thumb.height * dpr,
      dpr,
      config.press,
      config.full ? 1 : 0,
      ..._rgba(
        config.thumbLayer
            ? CoolapkNavigationStyle.thumbContainer(config.dark, config.press)
            : CoolapkNavigationStyle.container(config.dark),
      ),
      ..._rgba(CoolapkNavigationStyle.selection(config.dark)),
      CoolapkNavigationStyle.backgroundHeight * dpr,
      CoolapkNavigationStyle.backgroundAmount * dpr,
      CoolapkNavigationStyle.thumbHeight * dpr,
      CoolapkNavigationStyle.thumbAmount * dpr,
      config.thumbLayer ? 1 : 0,
      config.decorations ? 1 : 0,
      config.reduceBarThroughLens || config.legacyCompression
          ? CoolapkNavigationStyle.barLensAlongReduction
          : 0,
      config.reduceBarThroughLens || config.legacyCompression
          ? CoolapkNavigationStyle.barLensCrossReduction
          : 0,
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i + 2, values[i]);
    }
  }

  ui.ImageFilter _filter() {
    _bind();
    final optics = ui.ImageFilter.shader(config.shader);
    // ImageFilter lengths are logical and the engine applies the scene DPR.
    // Shader lengths above are physical; do not multiply blur by DPR again.
    final sigma = config.thumbLayer
        ? CoolapkNavigationStyle.blur * (1 - config.press)
        : CoolapkNavigationStyle.blur;
    return sigma < .001
        ? optics
        : ui.ImageFilter.compose(
            outer: optics,
            inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (usesCapturedGlass) {
      final view = RendererBinding.instance.platformDispatcher.views.first;
      final layer = CapturedBackdropLayer(
        transform: () => getTransformTo(null),
        bounds: () => (Offset.zero & size).expandToInclude(config.thumb),
        viewport: () => view.physicalSize,
        dpr: config.dpr,
        shader: config.shader,
        blur: config.thumbLayer
            ? CoolapkNavigationStyle.blur * (1 - config.press)
            : CoolapkNavigationStyle.blur,
        bind: (image, crop) {
          _bind();
          config.shader.setFloat(0, view.physicalSize.width);
          config.shader.setFloat(1, view.physicalSize.height);
          final values = [crop.left, crop.top, crop.width, crop.height];
          for (var i = 0; i < values.length; i++) {
            config.shader.setFloat(29 + i, values[i]);
          }
          config.shader.setImageSampler(0, image);
        },
      )..paintOffset = offset;
      _captureHandle.layer = layer;
      context.pushLayer(layer, (context, offset) {}, offset);
      return;
    }
    final layer = (_handle.layer ??= NavigationBackdropLayer(
      _filter,
      config.backdropKey,
    ));
    context.pushLayer(layer, (context, offset) {}, offset);
  }

  @override
  void dispose() {
    _handle.layer = null;
    _captureHandle.layer = null;
    super.dispose();
  }
}

class _OpticalContent extends SingleChildRenderObjectWidget {
  const _OpticalContent({
    required this.shader,
    required this.thumb,
    required this.press,
    required this.dpr,
    this.accent,
    required this.captureOnly,
    required this.optics,
    required this.legacyCompression,
    required super.child,
  });
  final ui.FragmentShader shader;
  final Rect thumb;
  final double press, dpr;
  final Color? accent;
  final bool captureOnly, optics, legacyCompression;
  @override
  RenderObject createRenderObject(BuildContext context) => _ContentRender(this);
  @override
  void updateRenderObject(BuildContext context, _ContentRender renderObject) {
    final wasBoundary = renderObject.isRepaintBoundary;
    renderObject.config = this;
    if (wasBoundary != renderObject.isRepaintBoundary) {
      renderObject.markNeedsCompositingBitsUpdate();
    }
    renderObject.markNeedsPaint();
  }
}

class _ContentRender extends RenderProxyBox {
  ui.Image? _capturedGlyphs;
  OffsetLayer? _glyphLayer;
  _ContentRender(this.config);
  _OpticalContent config;
  @override
  bool get alwaysNeedsCompositing => isRepaintBoundary;
  @override
  bool get isRepaintBoundary => !usesCapturedGlass && config.press > .0001;
  @override
  Rect get paintBounds =>
      (Offset.zero & size).inflate(CoolapkNavigationStyle.captureBleed);

  void _bindContent() {
    // A repaint boundary paints its children at local zero. Passing an absolute
    // paint offset into a nested ImageFilterLayer would shift the capture twice.
    final values = <double>[
      (config.thumb.left + CoolapkNavigationStyle.captureBleed) * config.dpr,
      (config.thumb.top + CoolapkNavigationStyle.captureBleed) * config.dpr,
      config.thumb.width * config.dpr,
      config.thumb.height * config.dpr,
      config.press,
      config.optics ? CoolapkNavigationStyle.thumbHeight * config.dpr : 0.0,
      config.optics ? CoolapkNavigationStyle.thumbAmount * config.dpr : 0.0,
      ..._rgba(config.accent ?? Colors.transparent),
      config.captureOnly ? 1 : 0,
      config.legacyCompression ? .08 : 0,
      config.legacyCompression ? .12 : 0,
    ];
    for (var i = 0; i < values.length; i++) {
      config.shader.setFloat(i + 2, values[i]);
    }
  }

  @override
  OffsetLayer updateCompositedLayer({
    required covariant ImageFilterLayer? oldLayer,
  }) {
    _bindContent();
    return (oldLayer ?? ImageFilterLayer())
      ..imageFilter = ui.ImageFilter.shader(config.shader);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (usesCapturedGlass && config.press > .0001) {
      final layer = OffsetLayer();
      final capture = _IsolatedPaintingContext(layer, paintBounds);
      super.paint(capture, Offset.zero);
      capture.finish();
      final image = layer.toImageSync(paintBounds, pixelRatio: config.dpr);
      _bindContent();
      config.shader.setFloat(0, image.width.toDouble());
      config.shader.setFloat(1, image.height.toDouble());
      config.shader.setImageSampler(0, image);
      context.canvas.save();
      context.canvas.translate(
        offset.dx + paintBounds.left,
        offset.dy + paintBounds.top,
      );
      context.canvas.scale(1 / config.dpr);
      context.canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Paint()..shader = config.shader,
      );
      context.canvas.restore();
      // A scene image is rasterized lazily. Retain its input layers until the
      // next paint, so glyph textures survive the current GPU submission.
      _capturedGlyphs?.dispose();
      _glyphLayer?.dispose();
      _capturedGlyphs = image;
      _glyphLayer = layer;
      return;
    }
    if (isRepaintBoundary) {
      // The boundary isolates this src command from the backdrop. At rest,
      // paint glyphs normally without introducing an empty filter capture.
      context.canvas.drawRect(
        paintBounds.shift(offset),
        Paint()
          ..color = Colors.transparent
          ..blendMode = BlendMode.src,
      );
    }
    super.paint(context, offset);
  }

  @override
  void dispose() {
    _capturedGlyphs?.dispose();
    _glyphLayer?.dispose();
    super.dispose();
  }
}

List<double> _rgba(Color c) => [c.r, c.g, c.b, c.a];

/// Cut only paint; selected InkWells must still compete in the gesture arena.
class _VisibleGlyphCutout extends SingleChildRenderObjectWidget {
  const _VisibleGlyphCutout({required this.thumb, required super.child});
  final Rect thumb;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _VisibleGlyphRender(thumb);
  @override
  void updateRenderObject(BuildContext context, _VisibleGlyphRender render) {
    render.thumb = thumb;
    render.markNeedsPaint();
  }
}

class _VisibleGlyphRender extends RenderProxyBox {
  _VisibleGlyphRender(this.thumb);
  Rect thumb;
  final _clip = LayerHandle<ClipPathLayer>();
  @override
  void paint(PaintingContext context, Offset offset) {
    _clip.layer = context.pushClipPath(
      needsCompositing,
      offset,
      Offset.zero & size,
      _GlyphClipper(thumb, outside: true).getClip(size),
      (context, offset) => super.paint(context, offset),
      oldLayer: _clip.layer,
    );
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}

class _GlyphClipper extends CustomClipper<Path> {
  const _GlyphClipper(this.thumb, {this.outside = false});
  final Rect thumb;
  final bool outside;
  @override
  Path getClip(Size size) {
    final lens = Path()
      ..addRRect(
        RRect.fromRectAndRadius(thumb, Radius.circular(thumb.shortestSide / 2)),
      );
    return outside
        ? Path.combine(
            PathOperation.difference,
            Path()..addRect(Offset.zero & size),
            lens,
          )
        : lens;
  }

  @override
  bool shouldReclip(_GlyphClipper old) =>
      thumb != old.thumb || outside != old.outside;
}

class _OpticalClipper extends CustomClipper<Path> {
  const _OpticalClipper(this.thumb, this.barScale);
  final Rect thumb;
  final double barScale;
  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.union,
    Path()..addRRect(
      RRect.fromRectAndRadius(
        CoolapkNavigationStyle.containerBounds(size, barScale),
        Radius.circular(size.shortestSide * barScale / 2),
      ),
    ),
    Path()..addRRect(
      RRect.fromRectAndRadius(thumb, Radius.circular(thumb.shortestSide / 2)),
    ),
  );
  @override
  bool shouldReclip(_OpticalClipper old) =>
      thumb != old.thumb || barScale != old.barScale;
}

class _BackgroundClipper extends CustomClipper<Path> {
  const _BackgroundClipper(this.thumb, this.thumbLayer, this.barScale);
  final Rect thumb;
  final double barScale;
  final bool thumbLayer;
  @override
  Path getClip(Size size) {
    final lens = Path()
      ..addRRect(
        RRect.fromRectAndRadius(thumb, Radius.circular(thumb.shortestSide / 2)),
      );
    if (thumbLayer) return lens;
    final bar = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          CoolapkNavigationStyle.containerBounds(size, barScale),
          Radius.circular(size.shortestSide * barScale / 2),
        ),
      );
    return bar;
  }

  @override
  bool shouldReclip(_BackgroundClipper old) =>
      thumb != old.thumb ||
      thumbLayer != old.thumbLayer ||
      barScale != old.barScale;
}

class _IsolatedPaintingContext extends PaintingContext {
  _IsolatedPaintingContext(super.containerLayer, super.estimatedBounds);
  void finish() => stopRecordingIfNeeded();
}
