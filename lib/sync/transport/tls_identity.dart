import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;

abstract interface class SecureTlsIdentityStorage {
  Future<TlsIdentity?> readCurrent();
  Future<TlsIdentity> installIfAbsent(TlsIdentity candidate);
}

final class TlsIdentityService {
  TlsIdentityService(this.storage);
  final SecureTlsIdentityStorage storage;

  Future<TlsIdentity> loadOrCreate(String deviceId) async {
    final stored = await storage.readCurrent();
    return stored ??
        await storage.installIfAbsent(
          await Isolate.run(
            () => TlsIdentity.create(deviceId: deviceId, now: DateTime.now()),
          ),
        );
  }
}

/// Per-installation TLS identity. The private key PEM must be persisted only in
/// platform secure storage; the certificate and SHA-256 fingerprint are public.
final class TlsIdentity {
  TlsIdentity._({
    required this.certificateDer,
    required this.certificatePem,
    required this.privateKeyPem,
    required this.fingerprintSha256,
  });

  final Uint8List certificateDer;
  final String certificatePem;
  final String privateKeyPem;
  final Uint8List fingerprintSha256;

  static Future<TlsIdentity> create({
    required String deviceId,
    required DateTime now,
    Random? random,
  }) async {
    if (deviceId.isEmpty || deviceId.length > 128) {
      throw ArgumentError('Invalid TLS identity input');
    }
    final secureRandom = random ?? Random.secure();
    final key = _RsaKey.generate(secureRandom);
    final serial = Uint8List.fromList(
      List<int>.generate(16, (_) => secureRandom.nextInt(256)),
    );
    final normalizedNow = now.toUtc();
    final tbs = _Der.sequence([
      _Der.explicit(0, _Der.integer(BigInt.two)),
      _Der.integerBytes(serial),
      _Der.sha256WithRsaAlgorithm,
      _Der.name(deviceId),
      _Der.sequence([
        _Der.generalizedTime(normalizedNow.subtract(const Duration(days: 1))),
        _Der.generalizedTime(
          DateTime.utc(
            normalizedNow.year + 10,
            normalizedNow.month,
            normalizedNow.day,
            normalizedNow.hour,
            normalizedNow.minute,
            normalizedNow.second,
          ),
        ),
      ]),
      _Der.name(deviceId),
      _Der.sequence([
        _Der.rsaAlgorithm,
        _Der.bitString(
          _Der.sequence([_Der.integer(key.n), _Der.integer(key.e)]),
        ),
      ]),
    ]);
    final digest = await Sha256().hash(tbs);
    final signature = key.signSha256(Uint8List.fromList(digest.bytes));
    final certificate = _Der.sequence([
      tbs,
      _Der.sha256WithRsaAlgorithm,
      _Der.bitString(signature),
    ]);
    final rsaPrivateKey = _Der.sequence([
      _Der.integer(BigInt.zero),
      _Der.integer(key.n),
      _Der.integer(key.e),
      _Der.integer(key.d),
      _Der.integer(key.p),
      _Der.integer(key.q),
      _Der.integer(key.d % (key.p - BigInt.one)),
      _Der.integer(key.d % (key.q - BigInt.one)),
      _Der.integer(key.q.modInverse(key.p)),
    ]);
    final privateKey = _Der.sequence([
      _Der.integer(BigInt.zero),
      _Der.rsaAlgorithm,
      _Der.octetString(rsaPrivateKey),
    ]);
    final fingerprint = await Sha256().hash(certificate);
    return TlsIdentity._(
      certificateDer: Uint8List.fromList(certificate).asUnmodifiableView(),
      certificatePem: _pem('CERTIFICATE', certificate),
      privateKeyPem: _pem('PRIVATE KEY', privateKey),
      fingerprintSha256: Uint8List.fromList(fingerprint.bytes)
          .asUnmodifiableView(),
    );
  }

  static TlsIdentity restoreWithFingerprint({
    required String certificatePem,
    required String privateKeyPem,
    required Uint8List fingerprintSha256,
  }) {
    final der = _decodePem('CERTIFICATE', certificatePem);
    final actual = crypto.sha256.convert(der).bytes;
    if (fingerprintSha256.length != 32 ||
        !_sameBytes(actual, fingerprintSha256)) {
      throw const FormatException('Stored TLS fingerprint is invalid');
    }
    return TlsIdentity._(
      certificateDer: der,
      certificatePem: certificatePem,
      privateKeyPem: privateKeyPem,
      fingerprintSha256: Uint8List.fromList(fingerprintSha256)
          .asUnmodifiableView(),
    );
  }

  static Uint8List certificateDerFromPem(String pem) =>
      _decodePem('CERTIFICATE', pem);

  SecurityContext serverContext() => SecurityContext(withTrustedRoots: false)
    ..minimumTlsProtocolVersion = TlsProtocolVersion.tls1_3
    ..useCertificateChainBytes(utf8.encode(certificatePem))
    ..usePrivateKeyBytes(utf8.encode(privateKeyPem));

  static SecurityContext clientContext() =>
      SecurityContext(withTrustedRoots: false)
        ..minimumTlsProtocolVersion = TlsProtocolVersion.tls1_3;

  static String _pem(String label, Uint8List bytes) {
    final encoded = base64Encode(bytes);
    final lines = <String>[];
    for (var offset = 0; offset < encoded.length; offset += 64) {
      lines.add(encoded.substring(offset, min(offset + 64, encoded.length)));
    }
    return '-----BEGIN $label-----\n${lines.join('\n')}\n-----END $label-----\n';
  }

  static Uint8List _decodePem(String label, String pem) {
    final header = '-----BEGIN $label-----';
    final footer = '-----END $label-----';
    if (!pem.contains(header) || !pem.contains(footer)) {
      throw const FormatException('Invalid PEM');
    }
    final encoded = pem
        .substring(pem.indexOf(header) + header.length, pem.indexOf(footer))
        .replaceAll(RegExp(r'\s'), '');
    return Uint8List.fromList(base64Decode(encoded));
  }

  static bool _sameBytes(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}

final class _RsaKey {
  _RsaKey(this.n, this.e, this.d, this.p, this.q);
  final BigInt n, e, d, p, q;

  static _RsaKey generate(Random random) {
    final e = BigInt.from(65537);
    while (true) {
      final p = _prime(1024, random);
      final q = _prime(1024, random);
      if (p == q) continue;
      final phi = (p - BigInt.one) * (q - BigInt.one);
      if (e.gcd(phi) != BigInt.one) continue;
      return _RsaKey(p * q, e, e.modInverse(phi), p, q);
    }
  }

  Uint8List signSha256(Uint8List digest) {
    const digestInfoPrefix = [
      0x30,
      0x31,
      0x30,
      0x0d,
      0x06,
      0x09,
      0x60,
      0x86,
      0x48,
      0x01,
      0x65,
      0x03,
      0x04,
      0x02,
      0x01,
      0x05,
      0x00,
      0x04,
      0x20,
    ];
    final size = (n.bitLength + 7) ~/ 8;
    final padding = size - digestInfoPrefix.length - digest.length - 3;
    if (padding < 8) throw StateError('RSA key is too short');
    final encoded = Uint8List.fromList([
      0,
      1,
      ...List<int>.filled(padding, 0xff),
      0,
      ...digestInfoPrefix,
      ...digest,
    ]);
    return _bigIntBytes(_bytesBigInt(encoded).modPow(d, n), size: size);
  }

  static BigInt _prime(int bits, Random random) {
    while (true) {
      final bytes = Uint8List.fromList(
        List<int>.generate(bits ~/ 8, (_) => random.nextInt(256)),
      );
      bytes[0] |= 0x80;
      bytes[bytes.length - 1] |= 1;
      final candidate = _bytesBigInt(bytes);
      if (_probablePrime(candidate, random)) return candidate;
    }
  }

  static bool _probablePrime(BigInt n, Random random) {
    const small = [3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47];
    for (final prime in small) {
      final p = BigInt.from(prime);
      if (n == p) return true;
      if (n % p == BigInt.zero) return false;
    }
    var d = n - BigInt.one;
    var s = 0;
    while (d.isEven) {
      d >>= 1;
      s++;
    }
    for (var round = 0; round < 16; round++) {
      final a = BigInt.two + _randomBelow(n - BigInt.from(3), random);
      var x = a.modPow(d, n);
      if (x == BigInt.one || x == n - BigInt.one) continue;
      var witnessedComposite = true;
      for (var r = 1; r < s; r++) {
        x = x.modPow(BigInt.two, n);
        if (x == n - BigInt.one) {
          witnessedComposite = false;
          break;
        }
      }
      if (witnessedComposite) return false;
    }
    return true;
  }

  static BigInt _randomBelow(BigInt max, Random random) {
    final bytes = (max.bitLength + 7) ~/ 8;
    while (true) {
      final candidate = _bytesBigInt(
        List<int>.generate(bytes, (_) => random.nextInt(256)),
      );
      if (candidate <= max) return candidate;
    }
  }
}

final class _Der {
  static final rsaAlgorithm = sequence([
    Uint8List.fromList([
      0x06,
      0x09,
      0x2a,
      0x86,
      0x48,
      0x86,
      0xf7,
      0x0d,
      0x01,
      0x01,
      0x01,
    ]),
    Uint8List.fromList([0x05, 0x00]),
  ]);
  static final sha256WithRsaAlgorithm = sequence([
    Uint8List.fromList([
      0x06,
      0x09,
      0x2a,
      0x86,
      0x48,
      0x86,
      0xf7,
      0x0d,
      0x01,
      0x01,
      0x0b,
    ]),
    Uint8List.fromList([0x05, 0x00]),
  ]);

  static Uint8List sequence(List<Uint8List> children) =>
      value(0x30, _join(children));
  static Uint8List set(List<Uint8List> children) =>
      value(0x31, _join(children));
  static Uint8List explicit(int number, Uint8List child) =>
      value(0xa0 + number, child);
  static Uint8List octetString(Uint8List bytes) => value(0x04, bytes);
  static Uint8List utf8String(String text) =>
      value(0x0c, Uint8List.fromList(utf8.encode(text)));
  static Uint8List generalizedTime(DateTime time) {
    final utc = time.toUtc();
    String two(int value) => value.toString().padLeft(2, '0');
    final text =
        '${utc.year.toString().padLeft(4, '0')}${two(utc.month)}${two(utc.day)}${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
    return value(0x18, Uint8List.fromList(ascii.encode(text)));
  }

  static Uint8List bitString(Uint8List bytes) =>
      value(0x03, Uint8List.fromList([0, ...bytes]));
  static Uint8List integer(BigInt number) => integerBytes(_bigIntBytes(number));
  static Uint8List integerBytes(Uint8List input) {
    var start = 0;
    while (start < input.length - 1 && input[start] == 0) {
      start++;
    }
    var bytes = Uint8List.fromList(input.sublist(start));
    if (bytes.isEmpty) bytes = Uint8List.fromList([0]);
    if (bytes.first & 0x80 != 0) bytes = Uint8List.fromList([0, ...bytes]);
    return value(0x02, bytes);
  }

  static Uint8List name(String commonName) => sequence([
    set([
      sequence([
        Uint8List.fromList([0x06, 0x03, 0x55, 0x04, 0x03]),
        utf8String(commonName),
      ]),
    ]),
  ]);
  static Uint8List value(int tag, Uint8List body) =>
      Uint8List.fromList([tag, ..._length(body.length), ...body]);
  static List<int> _length(int length) {
    if (length < 128) return [length];
    final bytes = <int>[];
    var remaining = length;
    while (remaining > 0) {
      bytes.insert(0, remaining & 0xff);
      remaining >>= 8;
    }
    return [0x80 | bytes.length, ...bytes];
  }

  static Uint8List _join(List<Uint8List> values) {
    final builder = BytesBuilder(copy: false);
    for (final value in values) {
      builder.add(value);
    }
    return builder.takeBytes();
  }
}

BigInt _bytesBigInt(List<int> bytes) {
  var value = BigInt.zero;
  for (final byte in bytes) {
    value = (value << 8) | BigInt.from(byte);
  }
  return value;
}

Uint8List _bigIntBytes(BigInt value, {int? size}) {
  if (value.isNegative) throw ArgumentError('Negative integer');
  final result = <int>[];
  do {
    result.insert(0, (value & BigInt.from(0xff)).toInt());
    value >>= 8;
  } while (value > BigInt.zero);
  if (size != null) {
    if (result.length > size) throw ArgumentError('Integer overflow');
    result.insertAll(0, List<int>.filled(size - result.length, 0));
  }
  return Uint8List.fromList(result);
}
