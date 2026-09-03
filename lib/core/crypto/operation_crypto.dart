import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../sync/oplog/operation.dart';
import 'device_identity.dart';

final class OperationCrypto {
  Future<Operation> sign(
    OperationEnvelope envelope,
    DeviceIdentity identity,
  ) async {
    if (identity.deviceId != envelope.originDeviceId) {
      throw ArgumentError('Signer does not own origin');
    }
    final signature = await identity.sign(envelope.bytes);
    return Operation(
      envelopeBytes: envelope.bytes,
      signature: Uint8List.fromList(signature.bytes),
    );
  }

  /// Verify the exact received bytes, even when they cannot be parsed locally.
  Future<bool> verify(Operation operation, SimplePublicKey publicKey) async {
    if (publicKey.type != KeyPairType.ed25519 || publicKey.bytes.length != 32) {
      return false;
    }
    return Ed25519().verify(
      operation.envelopeBytes,
      signature: Signature(operation.signature, publicKey: publicKey),
    );
  }
}
