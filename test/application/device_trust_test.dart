import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';

import '../support/identities.dart';

void main() {
  test(
    'genesis, device.add and permanent cutoff rebuild after restart',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final root = await testIdentity(
        '01991f82-0000-7000-8000-000000000101',
        1,
      );
      final peer = await testIdentity(
        '01991f82-0000-7000-8000-000000000102',
        2,
      );
      var app = await StudyAppController.open(db, root);
      try {
        await app.onboard(
          name: '考研',
          date: '2027-12-20',
          subjectNames: ['英语一'],
        );
        final genesis = await app.ensureWorkspaceGenesis();
        expect(genesis, hasLength(32));
        await app.addTrustedPeer(
          deviceId: peer.deviceId,
          deviceName: 'iPad Pro',
          platform: 'ios',
          identityPublicKey: Uint8List.fromList(peer.publicKey.bytes),
          tlsCertificateSha256: Uint8List.fromList(List<int>.filled(32, 9)),
        );
        expect(
          app.trustedPeers.map((item) => item.deviceName),
          contains('iPad Pro'),
        );
        expect(
          (await app.trust.lookup(
            app.workspace!.id,
            peer.deviceId,
          ))!.authorized,
          isTrue,
        );
        app.dispose();
        app = await StudyAppController.open(db, root);
        final restored = app.trustedPeers.singleWhere(
          (item) => item.deviceId == peer.deviceId,
        );
        expect(restored.active, isTrue);
        await app.revokeTrustedPeer(restored);
        expect(
          app.trustedPeers
              .singleWhere((item) => item.deviceId == peer.deviceId)
              .active,
          isFalse,
        );
        app.dispose();
        app = await StudyAppController.open(db, root);
        expect(
          app.trustedPeers
              .singleWhere((item) => item.deviceId == peer.deviceId)
              .active,
          isFalse,
        );
      } finally {
        app.dispose();
        await db.close();
      }
    },
  );
}
