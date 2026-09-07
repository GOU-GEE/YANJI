import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/sync/pairing/pairing_invite.dart';
import 'package:yanji/sync/transport/pinned_tls_transport.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

void main() {
  const workspace = '01991f82-0000-7000-8000-000000000101';
  const inviter = '01991f82-0000-7000-8000-000000000102';
  const inviteId = '01991f82-0000-7000-8000-000000000103';

  PairingInvite invite(TlsIdentity tls, int port, {Uint8List? fingerprint}) =>
      PairingInvite(
        workspaceId: workspace,
        workspaceGenesisHash: Uint8List(32),
        inviteId: inviteId,
        inviterDeviceId: inviter,
        identityPublicKey: Uint8List(32),
        tlsCertificateSha256: fingerprint ?? tls.fingerprintSha256,
        pairSecret: Uint8List.fromList(List<int>.filled(32, 7)),
        port: port,
        expiresAtMs: 120000,
        ipHints: const ['127.0.0.1'],
      );

  test('TLS 1.3 pin and framed deterministic CBOR exchange succeed', () async {
    final tls = await TlsIdentity.create(
      deviceId: inviter,
      now: DateTime.utc(2026, 9, 7),
    );
    final listener = await TlsPeerListener.bind(
      tls,
      address: InternetAddress.loopbackIPv4,
    );
    final server = listener.connections.first.then((socket) async {
      final channel = YppChannel(socket);
      expect(await channel.receive(), {'type': 'ping', 'value': 42});
      await channel.send({'type': 'pong'});
      await channel.close();
    });
    final socket = await PinnedTlsTransport.connect(invite(tls, listener.port));
    final channel = YppChannel(socket);
    await channel.send({'type': 'ping', 'value': 42});
    expect(await channel.receive(), {'type': 'pong'});
    await channel.close();
    await server;
    await listener.close();
  });

  test('certificate fingerprint mismatch terminates pairing', () async {
    final tls = await TlsIdentity.create(
      deviceId: inviter,
      now: DateTime.utc(2026, 9, 7),
    );
    final listener = await TlsPeerListener.bind(
      tls,
      address: InternetAddress.loopbackIPv4,
    );
    final rejected = PinnedTlsTransport.connect(
      invite(
        tls,
        listener.port,
        fingerprint: Uint8List.fromList(List.filled(32, 9)),
      ),
    );
    await expectLater(rejected, throwsA(isA<SocketException>()));
    await listener.close();
  });
}
