// Explicit manual target; not included in the app's normal unit test suite.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/sync/pairing/device_pairing_coordinator.dart';
import 'package:yanji/sync/transport/lan_peer_discovery.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

import '../../test/support/identities.dart';

class ProbeTlsStorage implements SecureTlsIdentityStorage {
  TlsIdentity? value;
  @override
  Future<TlsIdentity?> readCurrent() async => value;
  @override
  Future<TlsIdentity> installIfAbsent(TlsIdentity candidate) async =>
      value ??= candidate;
}

class ProbeDiscovery implements LanPeerDiscovery {
  @override
  Future<void> advertise(String deviceId, int port) async {}
  @override
  Future<List<DiscoveredPeer>> find(Set<String> deviceIds) async => [];
  @override
  Future<void> close() async {}
}

void main() {
  test(
    'macOS host authenticates and exchanges real operations with HarmonyOS',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final app = await StudyAppController.open(
        db,
        await testIdentity('01991f82-0000-7000-8000-000000000991', 91),
      );
      await app.onboard(
        name: '跨端同步验收',
        date: '2028-12-20',
        subjectNames: ['数学'],
      );
      await app.saveTask(title: '主机初始记录', date: app.today);
      final coordinator = await DevicePairingCoordinator.open(
        app,
        ProbeTlsStorage(),
        bindAddress: InternetAddress.anyIPv4,
        advertisedAddresses: ['10.0.2.2'],
        discovery: ProbeDiscovery(),
      );
      final subscription = coordinator.incomingRequests.stream.listen(
        (request) => request.approve(),
      );
      try {
        final invite = await coordinator.createInvitation();
        final output = File('work/harmonyos/cross-device-invite.txt');
        await output.parent.create(recursive: true);
        await output.writeAsString(invite.encode(), flush: true);
        debugPrint('YANJI_HOST_READY');
        final deadline = DateTime.now().add(const Duration(minutes: 4));
        var replied = false;
        while (DateTime.now().isBefore(deadline)) {
          if (!replied && app.tasks.any((t) => t.title == '鸿蒙跨端记录')) {
            await app.saveTask(title: '主机回传记录', date: app.today);
            replied = true;
          }
          if (app.tasks.any((t) => t.title == '设备已收到主机回传')) break;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect(replied, isTrue);
        expect(app.tasks.map((t) => t.title), contains('设备已收到主机回传'));
        debugPrint('YANJI_HOST_CROSS_SYNC_PASS');
      } finally {
        await subscription.cancel();
        await coordinator.close();
        app.dispose();
        await db.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
