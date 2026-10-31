import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/sync/pairing/device_pairing_coordinator.dart';
import 'package:yanji/sync/files/automatic_sync_controller.dart';
import 'package:yanji/sync/files/file_sync_engine.dart';
import 'package:yanji/sync/protocol/deterministic_cbor.dart';
import 'package:yanji/sync/transport/lan_peer_discovery.dart';
import 'package:yanji/sync/transport/pinned_tls_transport.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

import '../support/identities.dart';

class _Storage
    implements SecureTlsIdentityStorage, PersistentSyncEndpointStorage {
  TlsIdentity? tls;
  String? endpoints;
  @override
  Future<TlsIdentity?> readCurrent() async => tls;
  @override
  Future<TlsIdentity> installIfAbsent(TlsIdentity candidate) async =>
      tls ??= candidate;
  @override
  Future<String?> readSyncEndpoints() async => endpoints;
  @override
  Future<void> writeSyncEndpoints(String value) async {
    endpoints = value;
  }
}

class _Discovery implements LanPeerDiscovery {
  _Discovery(this.network, this.address);
  final Map<String, DiscoveredPeer> network;
  final String address;
  String? id;
  bool unavailable = false;
  @override
  Future<void> advertise(String deviceId, int port) async {
    id = deviceId;
    network[deviceId] = DiscoveredPeer(deviceId, [address], port);
  }

  @override
  Future<List<DiscoveredPeer>> find(Set<String> deviceIds) async {
    if (unavailable) throw const SocketException('discovery blocked');
    // Include unknown records to exercise the coordinator's trust filter.
    return network.values.toList();
  }

  @override
  Future<void> close() async {
    network.remove(id);
  }
}

class _UnusedEngine implements FileSyncEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Dart sync must not invoke the native engine: ${invocation.memberName}',
  );
}

void main() {
  test(
    'two initialized devices both complete pairing and exchange merged records',
    () async {
      final aDb = AppDatabase(NativeDatabase.memory());
      final bDb = AppDatabase(NativeDatabase.memory());
      final a = await StudyAppController.open(
        aDb,
        await testIdentity('01991f82-0000-7000-8000-000000000221', 21),
      );
      final b = await StudyAppController.open(
        bDb,
        await testIdentity('01991f82-0000-7000-8000-000000000222', 22),
      );
      final aStorage = _Storage();
      final bStorage = _Storage();
      final network = <String, DiscoveredPeer>{};
      DevicePairingCoordinator? root;
      DevicePairingCoordinator? joining;
      try {
        await a.onboard(name: '平板目标', date: '2027-12-20', subjectNames: ['数学']);
        await b.onboard(name: '手机目标', date: '2027-12-20', subjectNames: ['英语']);
        await a.saveTask(title: '平板记录', date: a.today);
        await b.saveTask(title: '手机记录', date: b.today);
        root = await DevicePairingCoordinator.open(
          a,
          aStorage,
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: ['127.0.0.1'],
          discovery: _Discovery(network, '127.0.0.1'),
          debugPeerAddresses: {b.identity.deviceId: '127.0.0.1:22000'},
        );
        joining = await DevicePairingCoordinator.open(
          b,
          bStorage,
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: ['127.0.0.1'],
          discovery: _Discovery(network, '127.0.0.1'),
        );
        final failedInvite = await root.createInvitation();
        final failedIncoming = root.incomingRequests.stream.first;
        final failedSession = await joining.beginJoin(
          failedInvite,
          deviceName: '手机',
          platform: 'android',
          mergeExisting: true,
        );
        final failedRequest = await failedIncoming;
        failedRequest.approve();
        final originalWorkspace = b.workspace!.id;
        b.busy = true;
        try {
          await expectLater(failedSession.confirm(), throwsStateError);
        } finally {
          b.busy = false;
        }
        expect(
          await failedRequest.completion.timeout(const Duration(seconds: 5)),
          isFalse,
        );
        expect(root.isPairConfirmed(b.identity.deviceId), isFalse);
        expect(root.transportPeers, isEmpty);
        expect(b.workspace!.id, originalWorkspace);
        expect(b.tasks.map((t) => t.title), contains('手机记录'));
        final invite = await root.createInvitation();
        await expectLater(
          joining.beginJoin(invite, deviceName: '手机', platform: 'android'),
          throwsStateError,
        );
        expect(root.isPairConfirmed(b.identity.deviceId), isFalse);
        final incoming = root.incomingRequests.stream.first;
        final outgoing = await joining.beginJoin(
          invite,
          deviceName: '手机',
          platform: 'android',
          mergeExisting: true,
        );
        final request = await incoming;
        request.approve();
        await outgoing.confirm();
        expect(await request.completion, isTrue);
        expect(b.workspace!.id, a.workspace!.id);
        expect(
          a.trustedPeers.any(
            (p) => p.active && p.deviceId == b.identity.deviceId,
          ),
          isTrue,
        );
        expect(
          b.trustedPeers.any(
            (p) => p.active && p.deviceId == a.identity.deviceId,
          ),
          isTrue,
        );
        expect(root.isPairConfirmed(b.identity.deviceId), isTrue);
        final transportPeer = root.transportPeers.singleWhere(
          (peer) => peer['id'] == b.identity.deviceId,
        );
        expect(transportPeer['addresses'], ['tcp://127.0.0.1:22000']);
        expect(
          jsonDecode(aStorage.endpoints!)[b.identity.deviceId]['confirmed'],
          isTrue,
        );
        expect(
          jsonDecode(bStorage.endpoints!)[a.identity.deviceId]['confirmed'],
          isTrue,
        );
        expect(b.tasks.map((t) => t.title), containsAll(['平板记录', '手机记录']));
        await joining.syncPairedDevices();
        expect(a.tasks.map((t) => t.title), containsAll(['平板记录', '手机记录']));
        await b.saveTask(title: '配对后的手机记录', date: b.today);
        await joining.syncPairedDevices();
        expect(a.tasks.map((t) => t.title), contains('配对后的手机记录'));
        final folder = await Directory.systemTemp.createTemp(
          'yanji-dart-sync-',
        );
        final sync = AutomaticSyncController(
          app: b,
          pairing: joining,
          directory: folder,
          backend: AutomaticSyncBackend.dartTls,
          engine: _UnusedEngine(),
        );
        try {
          await sync.tick();
          expect(sync.complete, isTrue);
          expect(sync.peers.single.pendingKnown, isTrue);
          expect(sync.peers.single.pending, 0);
          expect(sync.peers.single.connected, isTrue);
          await b.saveTask(title: 'Dart 自动同步记录', date: b.today);
          await sync.syncNow();
          expect(a.tasks.map((t) => t.title), contains('Dart 自动同步记录'));
          expect(sync.complete, isTrue);
          await root.close();
          // Retain the pairing endpoint but stop the remote listener.
          await b.saveTask(title: '离线未确认的记录', date: b.today);
          await sync.tick();
          expect(sync.complete, isFalse);
          expect(sync.peers.single.pending, greaterThan(0));
          expect(sync.peers.single.connected, isFalse);
          await expectLater(
            sync.syncNow(timeout: Duration.zero),
            throwsStateError,
          );
          root = await DevicePairingCoordinator.open(
            a,
            aStorage,
            bindAddress: InternetAddress.loopbackIPv4,
            advertisedAddresses: ['127.0.0.1'],
            discovery: _Discovery(network, '127.0.0.1'),
          );
          await sync.syncNow();
          expect(sync.complete, isTrue);
          expect(a.tasks.map((t) => t.title), contains('离线未确认的记录'));
        } finally {
          await sync.close();
          await folder.delete(recursive: true);
        }

        await a.revokeTrustedPeer(
          a.trustedPeers.singleWhere((p) => p.deviceId == b.identity.deviceId),
        );
        final historyCount = (await a.applier.export(a.workspace!.id)).length;
        final revokedInvite = await root.createInvitation();
        await expectLater(
          joining.beginJoin(
            revokedInvite,
            deviceName: '手机',
            platform: 'android',
          ),
          throwsA(
            isA<StateError>().having((e) => e.message, '说明', contains('已被撤销')),
          ),
        );
        expect((await a.applier.export(a.workspace!.id)).length, historyCount);
      } finally {
        await root?.close();
        await joining?.close();
        a.dispose();
        b.dispose();
        await aDb.close();
        await bDb.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'paired devices rediscover changed IP/port, authenticate, and persist only verified hints',
    () async {
      final aDb = AppDatabase(NativeDatabase.memory());
      final bDb = AppDatabase(NativeDatabase.memory());
      final a = await StudyAppController.open(
        aDb,
        await testIdentity('01991f82-0000-7000-8000-000000000201', 1),
      );
      final b = await StudyAppController.open(
        bDb,
        await testIdentity('01991f82-0000-7000-8000-000000000202', 2),
      );
      final aStorage = _Storage();
      final bStorage = _Storage();
      final network = <String, DiscoveredPeer>{};
      final aDiscovery = _Discovery(network, '127.0.0.1');
      final bDiscovery = _Discovery(network, '127.0.0.1');
      DevicePairingCoordinator? aCoordinator;
      DevicePairingCoordinator? bCoordinator;
      ServerSocket? oldPortBlocker;
      try {
        await a.onboard(name: '考研', date: '2027-12-20', subjectNames: ['英语']);
        aCoordinator = await DevicePairingCoordinator.open(
          a,
          aStorage,
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: ['127.0.0.1'],
          discovery: aDiscovery,
        );
        bCoordinator = await DevicePairingCoordinator.open(
          b,
          bStorage,
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: ['127.0.0.1'],
          discovery: bDiscovery,
        );
        final invite = await aCoordinator.createInvitation();
        final request = aCoordinator.incomingRequests.stream.first;
        final outgoing = await bCoordinator.beginJoin(
          invite,
          deviceName: 'B',
          platform: 'test',
        );
        (await request).approve();
        await outgoing.confirm();
        await a.saveTask(title: '首次配对之后新增', date: a.today);
        await b.saveTask(title: '另一台新增', date: b.today);
        await bCoordinator.syncPairedDevices();
        expect(a.tasks.map((task) => task.title), contains('另一台新增'));
        expect(b.tasks.map((task) => task.title), contains('首次配对之后新增'));
        // No new operations is still a successful sync.
        expect(await bCoordinator.syncPairedDevices(), greaterThan(0));

        final oldPort = aCoordinator.listener.port;
        await aCoordinator.close();
        aCoordinator = null;
        // Occupy the old port so restart definitely uses a different port.
        oldPortBlocker = await ServerSocket.bind(
          InternetAddress.loopbackIPv4,
          oldPort,
        );
        aCoordinator = await DevicePairingCoordinator.open(
          a,
          aStorage,
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: ['127.0.0.1'],
          discovery: _Discovery(network, '127.0.0.1'),
        );
        expect(aCoordinator.listener.port, isNot(oldPort));
        await a.saveTask(title: '重启且换地址之后新增', date: a.today);
        await bCoordinator.close();
        bCoordinator = null;
        final stale = jsonDecode(bStorage.endpoints!) as Map<String, dynamic>;
        stale[a.identity.deviceId]['addresses'] = ['192.0.2.1'];
        bStorage.endpoints = jsonEncode(stale);
        bCoordinator = await DevicePairingCoordinator.open(
          b,
          bStorage,
          bindAddress: InternetAddress.loopbackIPv4,
          advertisedAddresses: ['127.0.0.1'],
          discovery: bDiscovery,
        );
        network['unknown'] = const DiscoveredPeer('unknown', ['127.0.0.1'], 1);
        await bCoordinator.syncPairedDevices();
        expect(b.tasks.map((task) => task.title), contains('重启且换地址之后新增'));
        final persisted =
            jsonDecode(bStorage.endpoints!) as Map<String, dynamic>;
        expect(persisted[a.identity.deviceId]['addresses'], ['127.0.0.1']);
        expect(
          persisted[a.identity.deviceId]['port'],
          aCoordinator.listener.port,
        );
        expect(persisted.containsKey('unknown'), isFalse);

        // A spoofed discovery record must fail TLS pinning and must not replace
        // the authenticated endpoint. The known endpoint remains a fallback.
        network[a.identity.deviceId] = DiscoveredPeer(a.identity.deviceId, [
          '127.0.0.1',
        ], bCoordinator.listener.port);
        await bCoordinator.syncPairedDevices();
        expect(
          jsonDecode(bStorage.endpoints!)[a.identity.deviceId]['port'],
          aCoordinator.listener.port,
        );
        bDiscovery.unavailable = true;
        expect(await bCoordinator.syncPairedDevices(), greaterThan(0));

        // A captured initiating signature is insufficient: the responder's fresh
        // nonce requires a new proof before any history is sent.
        final nonce = Uint8List(32);
        final auth = DeterministicCbor.encode({
          'nonce': nonce,
          'workspace_id': a.workspace!.id,
          'initiator_device_id': b.identity.deviceId,
          'responder_device_id': a.identity.deviceId,
        });
        final channel = YppChannel(
          await PinnedTlsTransport.connectEndpoint(
            addresses: ['127.0.0.1'],
            port: aCoordinator.listener.port,
            tlsCertificateSha256: aStorage.tls!.fingerprintSha256,
          ),
        );
        try {
          await channel.send({
            'type': 'sync.auth',
            'protocol': 2,
            'workspace_id': a.workspace!.id,
            'device_id': b.identity.deviceId,
            'nonce': nonce,
            'signature': (await b.identity.sign(auth)).bytes,
          });
          expect((await channel.receive())['type'], 'sync.challenge');
          await channel.send({
            'type': 'sync.proof',
            'signature': Uint8List(64),
          });
          expect((await channel.receive())['type'], 'sync.rejected');
        } finally {
          await channel.close();
        }

        await a.revokeTrustedPeer(
          a.trustedPeers.firstWhere((p) => p.deviceId == b.identity.deviceId),
        );
        await expectLater(bCoordinator.syncPairedDevices(), throwsStateError);
        await aCoordinator.close();
        aCoordinator = null;
        await expectLater(bCoordinator.syncPairedDevices(), throwsStateError);
      } finally {
        await aCoordinator?.close();
        await bCoordinator?.close();
        await oldPortBlocker?.close();
        a.dispose();
        b.dispose();
        await aDb.close();
        await bDb.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
