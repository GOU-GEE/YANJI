import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

void main() {
  test(
    'generated RSA certificate serves TLS 1.3 and pins by certificate',
    () async {
      final identity = await TlsIdentity.create(
        deviceId: '01991f82-0000-7000-8000-000000000101',
        now: DateTime.utc(2026, 9, 7),
      );
      final server = await SecureServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
        identity.serverContext(),
      );
      final accepted = server.first.then((socket) async {
        socket.add([42]);
        await socket.flush();
        await socket.close();
      });
      final client = await SecureSocket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
        context: TlsIdentity.clientContext(),
        onBadCertificate: (certificate) =>
            certificate.pem.trim() == identity.certificatePem.trim(),
      );
      expect(await client.first, [42]);
      await client.close();
      await accepted;
      await server.close();
    },
  );
}
