import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../pairing/pairing_invite.dart';
import '../protocol/deterministic_cbor.dart';
import 'tls_identity.dart';

final class PinnedTlsTransport {
  static Future<SecureSocket> connect(PairingInvite invite) async {
    return connectEndpoint(
      addresses: invite.ipHints,
      port: invite.port,
      tlsCertificateSha256: invite.tlsCertificateSha256,
    );
  }

  static Future<SecureSocket> connectEndpoint({
    required List<String> addresses,
    required int port,
    required Uint8List tlsCertificateSha256,
  }) async {
    if (addresses.isEmpty) {
      throw const SocketException('邀请中没有可连接的局域网地址');
    }
    Object? lastError;
    for (final address in addresses) {
      try {
        final socket = await SecureSocket.connect(
          address,
          port,
          context: TlsIdentity.clientContext(),
          timeout: const Duration(seconds: 5),
          onBadCertificate: (certificate) {
            final der = TlsIdentity.certificateDerFromPem(certificate.pem);
            final actual = crypto.sha256.convert(der).bytes;
            return DeterministicCbor.compareBytes(
                  actual,
                  tlsCertificateSha256,
                ) ==
                0;
          },
        ).timeout(const Duration(seconds: 5));
        final certificate = socket.peerCertificate;
        if (certificate == null) {
          socket.destroy();
          throw const HandshakeException('服务端没有提供证书');
        }
        final actual = crypto.sha256
            .convert(TlsIdentity.certificateDerFromPem(certificate.pem))
            .bytes;
        if (DeterministicCbor.compareBytes(actual, tlsCertificateSha256) != 0) {
          socket.destroy();
          throw const HandshakeException('服务端证书指纹不匹配');
        }
        return socket;
      } catch (error) {
        lastError = error;
      }
    }
    throw SocketException('无法连接邀请设备：${lastError ?? '地址不可达'}');
  }
}

final class TlsPeerListener {
  TlsPeerListener._(this.server);
  final SecureServerSocket server;
  int get port => server.port;
  Stream<SecureSocket> get connections => server;

  static Future<TlsPeerListener> bind(
    TlsIdentity identity, {
    InternetAddress? address,
    int port = 0,
  }) async => TlsPeerListener._(
    await SecureServerSocket.bind(
      address ?? InternetAddress.anyIPv4,
      port,
      identity.serverContext(),
      shared: false,
    ),
  );

  Future<void> close() => server.close();
}

/// Length-prefixed deterministic CBOR messages. Frames are bounded before
/// allocation and never use JSON or line delimiters for protocol data.
final class YppChannel {
  YppChannel(this.socket);
  final SecureSocket socket;
  StreamIterator<Uint8List>? _iterator;
  final _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  Future<void> send(Map<String, Object?> message) async {
    final body = DeterministicCbor.encode(message);
    final length = body.length;
    socket.add([
      (length >> 24) & 0xff,
      (length >> 16) & 0xff,
      (length >> 8) & 0xff,
      length & 0xff,
      ...body,
    ]);
    await socket.flush();
  }

  Future<Map<String, Object?>> receive() async {
    _iterator ??= StreamIterator<Uint8List>(socket);
    await _fill(4);
    final length =
        (_pending[0] << 24) |
        (_pending[1] << 16) |
        (_pending[2] << 8) |
        _pending[3];
    _pending = Uint8List.fromList(_pending.sublist(4));
    if (length < 1 || length > DeterministicCbor.maxBytes) {
      throw const FormatException('Invalid YPP frame length');
    }
    await _fill(length);
    final body = Uint8List.fromList(_pending.sublist(0, length));
    _pending = Uint8List.fromList(_pending.sublist(length));
    final decoded = DeterministicCbor.decode(body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('YPP frame must be a map');
    }
    return decoded;
  }

  Future<void> _fill(int length) async {
    while (_pending.length < length) {
      if (!await _iterator!.moveNext()) {
        throw const SocketException('连接在报文完成前关闭');
      }
      _buffer
        ..clear()
        ..add(_pending)
        ..add(_iterator!.current);
      _pending = _buffer.takeBytes();
    }
  }

  Future<void> close() => socket.close();
}
