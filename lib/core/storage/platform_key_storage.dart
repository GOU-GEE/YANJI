import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../crypto/device_identity.dart';
import 'secret_value_storage.dart';
import '../../sync/transport/tls_identity.dart';

/// One composition-root instance owns initialization. Secrets are stored as one
/// platform-protected value, never in SQLite, logs or a plaintext fallback.
final class PlatformKeyStorage implements SecureKeyStorage {
  PlatformKeyStorage({
    FlutterSecureStorage? storage,
    SecretValueStorage? values,
  }) : storage = values ?? platformSecretStorage(storage);
  final SecretValueStorage storage;
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

final class PlatformTlsIdentityStorage
    implements SecureTlsIdentityStorage, PersistentSyncEndpointStorage {
  PlatformTlsIdentityStorage({
    FlutterSecureStorage? storage,
    SecretValueStorage? values,
  }) : storage = values ?? platformSecretStorage(storage);
  final SecretValueStorage storage;
  static const key = 'yanji.tls.identity.v1';
  static const syncEndpointsKey = 'yanji.sync.endpoints.v1';
  static Future<void> _pending = Future.value();

  @override
  Future<TlsIdentity?> readCurrent() async {
    final text = await storage.read(key: key);
    if (text == null) return null;
    final data = jsonDecode(text) as Map<String, dynamic>;
    return TlsIdentity.restoreWithFingerprint(
      certificatePem: data['certificate'] as String,
      privateKeyPem: data['privateKey'] as String,
      fingerprintSha256: base64Decode(data['fingerprint'] as String),
    );
  }

  Future<T> _exclusive<T>(Future<T> Function() work) {
    final result = _pending.then((_) => work());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  Future<TlsIdentity> installIfAbsent(TlsIdentity candidate) =>
      _exclusive(() async {
        final existing = await readCurrent();
        if (existing != null) return existing;
        await storage.write(
          key: key,
          value: jsonEncode({
            'certificate': candidate.certificatePem,
            'privateKey': candidate.privateKeyPem,
            'fingerprint': base64Encode(candidate.fingerprintSha256),
          }),
        );
        return (await readCurrent())!;
      });

  @override
  Future<String?> readSyncEndpoints() => storage.read(key: syncEndpointsKey);

  @override
  Future<void> writeSyncEndpoints(String value) =>
      _exclusive(() => storage.write(key: syncEndpointsKey, value: value));
}
