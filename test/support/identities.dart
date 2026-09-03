import 'package:yanji/core/crypto/device_identity.dart';

/// Test-only fake: never registered by the app's dependency composition.
class MemorySecureStorage implements SecureKeyStorage {
  IdentitySecret? current;
  @override
  Future<IdentitySecret?> readCurrent() async => current;
  @override
  Future<IdentitySecret> installIfAbsent(IdentitySecret candidate) async =>
      current ??= candidate;
  @override
  Future<void> replaceCurrent(IdentitySecret replacement) async {
    current = replacement;
  }
}

Future<DeviceIdentity> testIdentity(String id, int seedByte) {
  final storage = MemorySecureStorage()
    ..current = IdentitySecret(
      deviceId: id,
      keyReference: 'test.$id',
      seed: List.filled(32, seedByte),
    );
  return IdentityService(storage).loadOrCreate();
}
