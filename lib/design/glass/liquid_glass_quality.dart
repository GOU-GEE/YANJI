import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// High uses native shader filters or the OHOS captured-shader backend.
/// Android keeps the existing Impeller and API 33+ requirements.
/// YANJI_GLASS_REDUCED is a build-time escape hatch for slower devices.
enum YanjiGlassQuality {
  high,
  reduced;

  static Future<YanjiGlassQuality>? _resolution;
  static Future<YanjiGlassQuality> resolve() => _resolution ??= _resolve();

  static Future<YanjiGlassQuality> _resolve() async {
    final platform = defaultTargetPlatform.name;
    final shaderFiltersSupported = ui.ImageFilter.isShaderFilterSupported;
    const forceReduced = bool.fromEnvironment('YANJI_GLASS_REDUCED');
    int? androidSdk;
    if (platform == 'android' &&
        shaderFiltersSupported &&
        !kIsWeb &&
        !forceReduced) {
      try {
        androidSdk = await const MethodChannel(
          'yanji/glass',
        ).invokeMethod<int>('androidSdk');
      } on PlatformException {
        androidSdk = null;
      } on MissingPluginException {
        androidSdk = null;
      }
    }
    return forRenderer(
      platform: platform,
      shaderFiltersSupported: shaderFiltersSupported,
      web: kIsWeb,
      forceReduced: forceReduced,
      androidSdk: androidSdk,
    );
  }

  /// Capability policy is independent of device I/O so every platform can be
  /// checked without overriding the process-wide cached runtime decision.
  /// Use the platform name to keep this source compatible with upstream Flutter
  /// SDKs whose TargetPlatform enum does not contain the OHOS extension.
  static YanjiGlassQuality forRenderer({
    required String platform,
    required bool shaderFiltersSupported,
    bool web = false,
    bool forceReduced = false,
    int? androidSdk,
  }) {
    if (web || forceReduced) return reduced;
    if (platform == 'ohos') return high;
    if (!shaderFiltersSupported) return reduced;
    return switch (platform) {
      'iOS' || 'macOS' => high,
      'android' when androidSdk != null && androidSdk >= 33 => high,
      _ => reduced,
    };
  }
}
