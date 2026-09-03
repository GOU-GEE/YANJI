import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/crypto/operation_crypto.dart';
import 'package:yanji/sync/oplog/operation.dart';
import 'package:yanji/sync/protocol/deterministic_cbor.dart';

import '../support/identities.dart';

Uint8List unhex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);
String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
void main() {
  final vector = jsonDecode(
    File('test/fixtures/operation_v1.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final wire = unhex(vector['canonical_cbor_hex'] as String);
  final signature = unhex(vector['signature_hex'] as String);
  final key = SimplePublicKey(
    unhex(vector['public_key_hex'] as String),
    type: KeyPairType.ed25519,
  );
  final crypto = OperationCrypto();

  test(
    'independent golden CBOR, public key and Ed25519 signature stay frozen',
    () async {
      expect(
        hex(DeterministicCbor.encode(vector['envelope'])),
        vector['canonical_cbor_hex'],
      );
      final e = OperationEnvelope.fromBytes(wire);
      final storage = MemorySecureStorage()
        ..current = IdentitySecret(
          deviceId: e.originDeviceId,
          keyReference: 'test.golden',
          seed: unhex(vector['seed_hex'] as String),
        );
      final identity = await IdentityService(storage).loadOrCreate();
      expect(hex(identity.publicKey.bytes), vector['public_key_hex']);
      final signed = await crypto.sign(e, identity);
      expect(hex(signed.signature), vector['signature_hex']);
      expect(await crypto.verify(signed, key), true);
    },
  );
  test('parse/serialize and changed map insertion order preserve bytes', () {
    final e = OperationEnvelope.fromBytes(wire);
    final reversed = Map<String, Object?>.fromEntries(
      e.toMap().entries.toList().reversed,
    );
    expect(DeterministicCbor.encode(reversed), wire);
    expect(DeterministicCbor.encode(e.toMap()), wire);
  });
  test(
    'changing each signed byte or signature byte fails verification',
    () async {
      for (var i = 0; i < wire.length; i++) {
        final changed = Uint8List.fromList(wire)..[i] ^= 1;
        expect(
          await crypto.verify(
            Operation(envelopeBytes: changed, signature: signature),
            key,
          ),
          false,
          reason: 'envelope byte $i',
        );
      }
      for (var i = 0; i < 64; i++) {
        final changed = Uint8List.fromList(signature)..[i] ^= 1;
        expect(
          await crypto.verify(
            Operation(envelopeBytes: wire, signature: changed),
            key,
          ),
          false,
          reason: 'signature byte $i',
        );
      }
      final wrong = await testIdentity('wrong', 9);
      expect(
        await crypto.verify(
          Operation(envelopeBytes: wire, signature: signature),
          wrong.publicKey,
        ),
        false,
      );
    },
  );
  test(
    'RFC integer encodings and full uint64 survive without precision loss',
    () {
      final examples = <Object, String>{
        0: '00',
        23: '17',
        24: '1818',
        255: '18ff',
        256: '190100',
        65535: '19ffff',
        65536: '1a00010000',
        -1: '20',
        -25: '3818',
        -0x8000000000000000: '3b7fffffffffffffff',
        BigInt.parse('18446744073709551615'): '1bffffffffffffffff',
      };
      for (final entry in examples.entries) {
        expect(hex(DeterministicCbor.encode(entry.key)), entry.value);
        expect(DeterministicCbor.decode(unhex(entry.value)), entry.key);
      }
      expect(
        () => DeterministicCbor.encode(BigInt.one << 64),
        throwsFormatException,
      );
    },
  );
  test('typed bytes/null/boolean/arrays/maps round trip', () {
    final v = {
      'z': [
        null,
        true,
        false,
        -3,
        {'text': '研迹'},
      ],
      'blob': Uint8List.fromList([0, 255]),
    };
    final encoded = DeterministicCbor.encode(v);
    expect(
      DeterministicCbor.encode(DeterministicCbor.decode(encoded)),
      encoded,
    );
    expect(hex(DeterministicCbor.encode({'b': 2, 'a': 1})), 'a2616101616202');
  });
  test(
    'floats, tags, duplicate keys, nonminimal and malformed CBOR are rejected',
    () {
      for (final bad in [
        '1800',
        '9f01ff',
        'a2616101616102',
        'a2616201616102',
        'c001',
        'f7',
        'f93c00',
        '61ff',
        '0000',
        '1b',
        '3bffffffffffffffff',
        'bf',
      ]) {
        expect(
          () => DeterministicCbor.decode(unhex(bad)),
          throwsFormatException,
          reason: bad,
        );
      }
      expect(() => DeterministicCbor.encode(1.0), throwsFormatException);
      expect(
        () => DeterministicCbor.encode({1: 'not a text key'}),
        throwsFormatException,
      );
      Object? deep;
      for (var i = 0; i < 70; i++) {
        deep = [deep];
      }
      expect(() => DeterministicCbor.encode(deep), throwsFormatException);
    },
  );
}
