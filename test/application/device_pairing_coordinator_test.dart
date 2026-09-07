import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/sync/pairing/device_pairing_coordinator.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

import '../support/identities.dart';

final class _MemoryTlsStorage implements SecureTlsIdentityStorage {
  TlsIdentity? value;
  @override
  Future<TlsIdentity?> readCurrent() async => value;
  @override
  Future<TlsIdentity> installIfAbsent(TlsIdentity candidate) async =>
      value ??= candidate;
}

void main() {
  test(
    'three devices can pair through a non-root peer and replay full history',
    () async {
      final aDb = AppDatabase(NativeDatabase.memory());
      final bDb = AppDatabase(NativeDatabase.memory());
      final cDb = AppDatabase(NativeDatabase.memory());
      final a = await StudyAppController.open(
        aDb,
        await testIdentity('01991f82-0000-7000-8000-000000000101', 1),
      );
      final b = await StudyAppController.open(
        bDb,
        await testIdentity('01991f82-0000-7000-8000-000000000102', 2),
      );
      final c = await StudyAppController.open(
        cDb,
        await testIdentity('01991f82-0000-7000-8000-000000000103', 3),
      );
      DevicePairingCoordinator? aPairing;
      DevicePairingCoordinator? bPairing;
      DevicePairingCoordinator? cPairing;
      try {
        await a.onboard(name: '考研', date: '2027-12-20', subjectNames: ['英语一']);
        await a.saveTask(title: '背单词', date: a.today);
        aPairing = await DevicePairingCoordinator.open(
          a,
          _MemoryTlsStorage(),
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: const ['127.0.0.1'],
        );
        bPairing = await DevicePairingCoordinator.open(
          b,
          _MemoryTlsStorage(),
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: const ['127.0.0.1'],
        );
        cPairing = await DevicePairingCoordinator.open(
          c,
          _MemoryTlsStorage(),
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: const ['127.0.0.1'],
        );
        final invite = await aPairing.createInvitation();
        final requestFuture = aPairing.incomingRequests.stream.first;
        final outgoing = await bPairing.beginJoin(
          invite,
          deviceName: 'iPad Pro',
          platform: 'ios',
        );
        final incoming = await requestFuture;
        expect(incoming.safetyCode, outgoing.safetyCode);
        incoming.approve();
        await outgoing.confirm();
        expect(b.isReady, isTrue);
        expect(b.workspace!.id, a.workspace!.id);
        expect(b.tasks.single.title, '背单词');
        expect(
          a.trustedPeers.map((peer) => peer.deviceId),
          contains(b.identity.deviceId),
        );
        expect(
          b.trustedPeers.map((peer) => peer.deviceId),
          containsAll([a.identity.deviceId, b.identity.deviceId]),
        );
        expect(
          await b.applier.projectionDigest(b.workspace!.id),
          await a.applier.projectionDigest(a.workspace!.id),
        );
        final relayedInvite = await bPairing.createInvitation();
        final relayedRequest = bPairing.incomingRequests.stream.first;
        final relayedOutgoing = await cPairing.beginJoin(
          relayedInvite,
          deviceName: 'MacBook Pro',
          platform: 'macos',
        );
        final relayedIncoming = await relayedRequest;
        expect(relayedIncoming.safetyCode, relayedOutgoing.safetyCode);
        relayedIncoming.approve();
        await relayedOutgoing.confirm();
        expect(c.tasks.single.title, '背单词');
        expect(
          c.trustedPeers.map((peer) => peer.deviceId),
          containsAll([
            a.identity.deviceId,
            b.identity.deviceId,
            c.identity.deviceId,
          ]),
        );
        expect(
          await c.applier.projectionDigest(c.workspace!.id),
          await b.applier.projectionDigest(b.workspace!.id),
        );
      } finally {
        await aPairing?.close();
        await bPairing?.close();
        await cPairing?.close();
        a.dispose();
        b.dispose();
        c.dispose();
        await aDb.close();
        await bDb.close();
        await cDb.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
