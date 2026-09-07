import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../crypto/device_identity.dart';

/// One composition-root instance owns initialization. Secrets are stored as one
/// platform-protected value, never in SQLite, logs or a plaintext fallback.
final class PlatformKeyStorage implements SecureKeyStorage {
  PlatformKeyStorage({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage storage;
  static const key = 'yanji.identity.v1';
  static Future<void> _pending = Future.value();
  @override
  Future<IdentitySecret?> readCurrent() async {
    final text = await storage.read(key: key);
    if (text == null) return null;
    final data = jsonDecode(text) as Map<String, dynamic>;
    return IdentitySecret(
      deviceId: data['deviceId'] as String,
      keyReference: key,
      seed: base64Decode(data['seed'] as String),
    );
  }

  Future<T> _exclusive<T>(Future<T> Function() work) {
    final result = _pending.then((_) => work());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<IdentitySecret> installIfAbsent(IdentitySecret candidate) =>
      _exclusive(() async {
        final existing = await readCurrent();
        if (existing != null) return existing;
        await _write(candidate);
        return (await readCurrent())!;
      });
  Future<void> _write(IdentitySecret value) => storage.write(
    key: key,
    value: jsonEncode({
      'deviceId': value.deviceId,
      'seed': base64Encode(value.seed),
    }),
  );
  @override
  Future<void> replaceCurrent(IdentitySecret replacement) =>
      _exclusive(() => _write(replacement));
}
