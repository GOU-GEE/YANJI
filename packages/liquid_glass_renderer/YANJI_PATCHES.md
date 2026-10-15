# YANJI optical patch

Source: liquid_glass_renderer 0.2.0-dev.4, https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer . Upstream MIT license and copyright retained. Only lib/, pubspec.yaml and LICENSE vendored; upstream examples and dev dependencies omitted.

- `liquid_glass_blend_group.dart` and `liquid_glass_render_object.dart`: convert logical thickness to physical pixels in both geometry encoding and final displacement decoding. Geometry positions were already physical pixels; upstream thickness was not scaled. The patch makes the optical rim consistent across DPRs.
- `liquid_glass_geometry_blended.frag`: reduce the extra optical path from 8 thicknesses to .75, fade displacement in over the outer 12% of the rim, and encode with a 2-thickness range instead of 10 for better precision.
- `liquid_glass_final_render.frag`: decode with the matching 2-thickness range. UV sampling and per-channel offsets remain live backdrop sampling.

The patched path is LiquidGlassLayer + LiquidGlass/BlendGroup used by YanjiGlassSurface. Legacy Glassify/arbitrary shaders are unchanged and should not be assumed to have these fixes. FakeGlass fallback is unchanged. Upgrade by comparing these four files explicitly; do not replace the local package without re-running optical validation.

## 2026-10-01 navigation edge magnification

`LiquidGlassSettings.edgeMagnification` opts the navigation indicator into an outer-rim magnification profile. Inward sampling displacement starts at the silhouette and falls quadratically to zero over one logical thickness; its derivative remains monotonic on a straight rim. Other strengths keep the existing profile. The geometry optical-properties Y slot now selects this profile (dispersion was unused in that pass); dispersion remains in the final render uniforms.

The new profile uses a .5-thickness displacement encoding range instead of 2, giving four times the precision for small moving glyphs. The final render adds a matching `uEdgeMagnification` flag; Dart uniform binding, settings equality/copying, and geometry cache invalidation include it. Default/legacy geometry continues using the original 2-thickness range. This opt-in is only supported by the precomputed Layer/BlendGroup path.

Validation: `integration_test/navigation_edge_optics_test.dart` compares an unfiltered coordinate backdrop, the original rim ramp, and the new edge profile on a real Impeller simulator, then exercises the actual dock in light/dark while dragging across glyphs. Recheck all touched geometry, final render, settings, binding and cache files on package upgrades.

## 2026-10-11 GLES opt-in edge direction

Android 16 / Flutter 3.47.2 / Impeller OpenGLES exposed an existing direction
error in the opt-in `edgeMagnification` branch: top-rim coordinate-page green
shift was -5 instead of inward +5. `FlutterFragCoord` is top-down but GLES
`dFdy` uses native framebuffer Y. Invert the opt-in outward normal's Y on GLES
before encoding displacement. The default optical profile, encoding range,
final decoder, other backends, upstream license and copyright are unchanged.
The Coolapk navigation uses separate shaders and does not use this profile.
Shared indicator-role segmented controls also opt into this profile and receive
the same GLES direction correction; default glass surfaces keep their profile.
Revalidated with the original edge thresholds, backdrop alignment and shared
glass controls; evidence is in the 2026-10-11 navigation validation directory.
