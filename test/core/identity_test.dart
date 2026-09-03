import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/crypto/device_identity.dart';

import '../support/identities.dart';

void main() {
  test(
    'identity survives service recreation and concurrent initialization',
    () async {
      final storage = MemorySecureStorage();
      final identities = await Future.wait(
        List.generate(5, (_) => IdentityService(storage).loadOrCreate()),
      );
      expect(identities.map((i) => i.deviceId).toSet(), hasLength(1));
      final reopened = await IdentityService(storage).loadOrCreate();
      expect(reopened.publicKey.bytes, identities.first.publicKey.bytes);
      expect(reopened.keyReference, identities.first.keyReference);
    },
  );
  test('new-installation restore replaces the origin and key pair', () async {
    final storage = MemorySecureStorage(),
        service = IdentityService(MemorySecureStorage());
    final old = await IdentityService(storage).loadOrCreate();
    final restored = await IdentityService(storage)
        .createForRestoredInstallation();
    expect(restored.deviceId, isNot(old.deviceId));
    expect(restored.publicKey.bytes, isNot(old.publicKey.bytes));
    expect(restored.keyReference, isNot(old.keyReference));
    expect(
      (await IdentityService(storage).loadOrCreate()).deviceId,
      restored.deviceId,
    );
    expect((await service.loadOrCreate()).deviceId, isNot(old.deviceId));
  });
}
