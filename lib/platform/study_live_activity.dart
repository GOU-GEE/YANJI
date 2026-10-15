import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Thin platform adapter. Study-session rules stay in Dart; each mobile system
/// only renders and controls a native, glanceable representation of that state.
class StudyLiveActivity {
  StudyLiveActivity._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.yanji/study_live_activity',
  );

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static Future<void> sync({
    required String? sessionId,
    required String subject,
    required String status,
    required int elapsedMilliseconds,
    required int todayTotalMilliseconds,
    required bool doNotDisturbEnabled,
    required int snapshotAtMilliseconds,
    required int statusUpdatedAtMilliseconds,
  }) async {
    if (!_isSupportedPlatform) return;
    try {
      await _channel.invokeMethod<void>('sync', <String, Object?>{
        'sessionId': sessionId,
        'subject': subject,
        'status': status,
        'elapsedSeconds': elapsedMilliseconds ~/ 1000,
        'todayTotalSeconds': todayTotalMilliseconds ~/ 1000,
        'snapshotAtMs': snapshotAtMilliseconds,
        'statusUpdatedAtMs': statusUpdatedAtMilliseconds,
        // The current product has no daily-duration preference yet. A zero
        // target makes the native goal module hide itself.
        'targetSeconds': 0,
        'doNotDisturbEnabled': doNotDisturbEnabled,
      });
    } on PlatformException catch (error) {
      debugPrint('Live Activity sync skipped: ${error.message}');
    } on MissingPluginException {
      // Unsupported devices intentionally have no implementation.
    } on StateError {
      // Pure Dart controller tests do not initialize a platform messenger.
    } on FlutterError {
      // Some Flutter test configurations report the same missing binding as a
      // framework error instead of a StateError.
    }
  }

  static Future<String?> consumePendingAction() async {
    if (!_isSupportedPlatform) return null;
    try {
      return await _channel.invokeMethod<String>('consumePendingAction');
    } on PlatformException catch (error) {
      debugPrint('Live Activity action unavailable: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }

  static Future<Map<Object?, Object?>?> currentActivityState() async {
    if (!_isSupportedPlatform) return null;
    try {
      return await _channel.invokeMethod<Map<Object?, Object?>>(
        'currentActivityState',
      );
    } on PlatformException catch (error) {
      debugPrint('Live Activity state unavailable: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }

  /// Runs OPPO's official Seedling and Fluid Cloud capability checks.
  static Future<Map<Object?, Object?>?> checkOppoFluidCloudSupport() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        'checkOppoFluidCloudSupport',
      );
    } on PlatformException catch (error) {
      debugPrint('OPPO Fluid Cloud capability unavailable: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }

  /// Sends debug-only synthetic states through the real OPPO adapter.
  static Future<Map<Object?, Object?>?> debugOppoFluidCloud(
    String action,
  ) async {
    if (!kDebugMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        'debugOppoFluidCloud',
        <String, Object?>{'action': action},
      );
    } on PlatformException catch (error) {
      debugPrint('OPPO Fluid Cloud debug action failed: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }

  /// Reads Xiaomi's focus protocol and both independent notification grants.
  /// The Android implementation performs canShowFocus on a worker thread.
  static Future<Map<Object?, Object?>?> checkXiaomiFocusSupport() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        'checkXiaomiFocusSupport',
      );
    } on PlatformException catch (error) {
      debugPrint('Xiaomi focus capability unavailable: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }

  /// Runs a synthetic lifecycle state through Xiaomi's approved-scene gate.
  static Future<Map<Object?, Object?>?> debugXiaomiSuperIsland(
    String action,
  ) async {
    if (!kDebugMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        'debugXiaomiSuperIsland',
        <String, Object?>{'action': action},
      );
    } on PlatformException catch (error) {
      debugPrint('Xiaomi focus debug action failed: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }

  /// Reads HONOR/MagicOS, Suggestions Kit and YOYO globalReach capability.
  static Future<Map<Object?, Object?>?> checkHonorMagicCapsuleSupport() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        'checkHonorMagicCapsuleSupport',
      );
    } on PlatformException catch (error) {
      debugPrint(
        'HONOR Magic Capsule capability unavailable: ${error.message}',
      );
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }

  /// Records the user's explicit consent for HONOR event-data feedback.
  /// Call only after the final privacy notice and consent flow are in place.
  static Future<void> setHonorSuggestionsDataConsent(bool granted) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<bool>(
        'setHonorSuggestionsConsent',
        <String, Object?>{'granted': granted},
      );
    } on PlatformException catch (error) {
      debugPrint(
        'HONOR Suggestions consent state was not saved: ${error.message}',
      );
    } on MissingPluginException {
      // Unsupported platforms intentionally have no implementation.
    } on StateError {
      // Pure Dart tests may not have a platform messenger.
    } on FlutterError {
      // Some Flutter test configurations report this as a framework error.
    }
  }

  /// Runs synthetic states through HONOR's scene/approval gates in debug only.
  static Future<Map<Object?, Object?>?> debugHonorMagicCapsule(
    String action,
  ) async {
    if (!kDebugMode ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(
        'debugHonorMagicCapsule',
        <String, Object?>{'action': action},
      );
    } on PlatformException catch (error) {
      debugPrint('HONOR Magic Capsule debug action failed: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    } on StateError {
      return null;
    } on FlutterError {
      return null;
    }
  }
}
