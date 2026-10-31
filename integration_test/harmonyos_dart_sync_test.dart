import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/core/storage/platform_key_storage.dart';
import 'package:yanji/sync/files/automatic_sync_controller.dart';
import 'package:yanji/sync/pairing/device_pairing_coordinator.dart';
import 'package:yanji/sync/pairing/pairing_invite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'HarmonyOS and macOS host pair and synchronize bidirectionally',
    (_) async {
      const invitation = String.fromEnvironment('YANJI_PEER_INVITE');
      expect(invitation, isNotEmpty);
      final support = await getAppSupportDirectory();
      final folder = await Directory(
        '${support.path}/cross-sync-${DateTime.now().microsecondsSinceEpoch}',
      ).create();
      final identity = await IdentityService(
        PlatformKeyStorage(),
      ).loadOrCreate();
      final db = AppDatabase(
        openDatabaseFile(File('${folder.path}/study.sqlite')),
      );
      final app = await StudyAppController.open(db, identity);
      final pairing = await DevicePairingCoordinator.open(
        app,
        PlatformTlsIdentityStorage(),
      );
      final sync = AutomaticSyncController(
        app: app,
        pairing: pairing,
        directory: Directory('${folder.path}/sync'),
        backend: AutomaticSyncBackend.dartTls,
      );
      try {
        final outgoing = await pairing.beginJoin(
          PairingInvite.decode(
            invitation,
            nowMs: DateTime.now().millisecondsSinceEpoch,
          ),
          deviceName: '鸿蒙验收手机',
          platform: 'ohos',
        );
        await outgoing.confirm();
        expect(app.tasks.map((t) => t.title), contains('主机初始记录'));
        await app.saveTask(title: '鸿蒙跨端记录', date: app.today);
        for (var i = 0; i < 15; i++) {
          await sync.syncNow();
          if (app.tasks.any((t) => t.title == '主机回传记录')) break;
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        expect(app.tasks.map((t) => t.title), contains('主机回传记录'));
        await app.saveTask(title: '设备已收到主机回传', date: app.today);
        await sync.syncNow();
        expect(sync.complete, isTrue);
        expect(sync.peers.single.pendingKnown, isTrue);
        expect(sync.peers.single.pending, 0);
        debugPrint('YANJI_HARMONY_CROSS_SYNC_PASS');
      } finally {
        await sync.close();
        await pairing.close();
        app.dispose();
        await db.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
