import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// High requires shader backdrop filters (Impeller), and Android API 33+.
/// YANJI_GLASS_REDUCED is a build-time escape hatch for slower devices.
enum YanjiGlassQuality {
  high,
  reduced;

  static Future<YanjiGlassQuality>? _resolution;
  static Future<YanjiGlassQuality> resolve() => _resolution ??= _resolve();

  static Future<YanjiGlassQuality> _resolve() async {
    if (const bool.fromEnvironment('YANJI_GLASS_REDUCED') ||
        kIsWeb ||
        !ui.ImageFilter.isShaderFilterSupported) {
      return reduced;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final sdk = await const MethodChannel('yanji/glass')
            .invokeMethod<int>('androidSdk');
        return sdk != null && sdk >= 33 ? high : reduced;
      } on PlatformException {
        return reduced;
      } on MissingPluginException {
        return reduced;
      }
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => high,
      _ => reduced,
    };
  }
}
