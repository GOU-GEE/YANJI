import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../platform/app_support_directory.dart';

abstract interface class SecretValueStorage {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}

SecretValueStorage platformSecretStorage([FlutterSecureStorage? storage]) =>
    storage != null || !isHarmonyOS
    ? FlutterSecretValueStorage(storage ?? const FlutterSecureStorage())
    : const HarmonySecretValueStorage();

final class FlutterSecretValueStorage implements SecretValueStorage {
  const FlutterSecretValueStorage(this.storage);
  final FlutterSecureStorage storage;
  @override
  Future<String?> read({required String key}) => storage.read(key: key);
  @override
  Future<void> write({required String key, required String value}) =>
      storage.write(key: key, value: value);
}

/// Errors propagate to the caller. A missing/corrupt wrapping key is never
/// treated as a fresh installation, and secrets have no plaintext fallback.
final class HarmonySecretValueStorage implements SecretValueStorage {
  const HarmonySecretValueStorage();
  @override
  Future<String?> read({required String key}) =>
      yanjiPlatformChannel.invokeMethod<String>('secretRead', {'key': key});
  @override
  Future<void> write({required String key, required String value}) =>
      yanjiPlatformChannel.invokeMethod<void>('secretWrite', {
        'key': key,
        'value': value,
      });
}
