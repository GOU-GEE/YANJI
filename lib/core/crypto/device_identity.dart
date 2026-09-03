import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../ids/entity_ids.dart';

/// Implementations MUST use OS secure storage, with atomic initialization/replacement.
/// There is deliberately no plaintext/file/SQLite fallback implementation.
abstract interface class SecureKeyStorage {
  Future<IdentitySecret?> readCurrent();
  Future<IdentitySecret> installIfAbsent(IdentitySecret candidate);
  Future<void> replaceCurrent(IdentitySecret replacement);
}

/// Secure-storage boundary only. Never serialize this value into Oplog or backup.
final class IdentitySecret {
  IdentitySecret({
    required this.deviceId,
    required this.keyReference,
    required List<int> seed,
  }) : seed = Uint8List.fromList(seed).asUnmodifiableView() {
    if (deviceId.isEmpty || keyReference.isEmpty || seed.length != 32) {
      throw ArgumentError('Invalid identity secret');
    }
  }
  final String deviceId;
  final String keyReference;
  final Uint8List seed;
}

final class DeviceIdentity {
  DeviceIdentity._(
    this.deviceId,
    this.keyReference,
    this._keyPair,
    this.publicKey,
  );
  final String deviceId;
  final String keyReference;
  final SimpleKeyPair _keyPair;
  final SimplePublicKey publicKey;
  Future<Signature> sign(List<int> bytes) =>
      Ed25519().sign(bytes, keyPair: _keyPair);
}

final class IdentityService {
  IdentityService(this.storage, {EntityIds? ids}) : _ids = ids ?? EntityIds();
  final SecureKeyStorage storage;
  final EntityIds _ids;

  Future<IdentitySecret> _generate() async {
    final key = await Ed25519().newKeyPair();
    final id = _ids.next();
    return IdentitySecret(
      deviceId: id,
      keyReference: 'yanji.identity.$id',
      seed: await key.extractPrivateKeyBytes(),
    );
  }

  Future<DeviceIdentity> _open(IdentitySecret secret) async {
    final key = await Ed25519().newKeyPairFromSeed(secret.seed);
    return DeviceIdentity._(
      secret.deviceId,
      secret.keyReference,
      key,
      await key.extractPublicKey(),
    );
  }

  Future<DeviceIdentity> loadOrCreate() async {
    final stored = await storage.readCurrent();
    return _open(stored ?? await storage.installIfAbsent(await _generate()));
  }

  /// New installation restore never consumes identity material from a backup.
  /// Membership authorization of this new origin is a separate required step.
  Future<DeviceIdentity> createForRestoredInstallation() async {
    final fresh = await _generate();
    await storage.replaceCurrent(fresh);
    return _open(fresh);
  }
}
