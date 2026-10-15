import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/sync/files/file_sync_engine.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'embedded transport starts, reconfigures, scans and restarts on device',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('同步引擎验证'))),
      );
      final directory = await Directory.systemTemp.createTemp(
        'yanji-native-test-',
      );
      final identity = await TlsIdentity.create(
        deviceId: '01991f82-0000-7000-8000-000000000299',
        now: DateTime.now(),
      );
      final engine = EmbeddedSyncthingEngine();
      final configuration = <String, Object?>{
        'directory': '${directory.path}/engine',
        'folder_path': '${directory.path}/records',
        'workspace': 'native-integration-test',
        'certificate': identity.certificatePem,
        'private_key': identity.privateKeyPem,
        'peers': <Object?>[],
        'local_only': true,
        'listen': ['tcp://127.0.0.1:0'],
      };
      try {
        await engine.start(configuration);
        await engine.configure(configuration);
        await engine.scan();
        expect(await engine.connected(), isEmpty);
        expect(
          await Directory('${directory.path}/records/.stfolder').exists(),
          isTrue,
        );
        await engine.close();
        await engine.start(configuration);
        await engine.scan();
        expect(await engine.connected(), isEmpty);
      } finally {
        await engine.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
