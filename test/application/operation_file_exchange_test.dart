import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:yanji/sync/files/automatic_sync_controller.dart';
import 'package:yanji/sync/files/file_sync_engine.dart';
import 'package:yanji/sync/pairing/device_pairing_coordinator.dart';
import 'package:yanji/sync/transport/tls_identity.dart';
import 'package:yanji/sync/transport/lan_peer_discovery.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/sync/files/operation_file_exchange.dart';
import 'package:yanji/sync/pairing/pairing_invite.dart';
import 'package:yanji/sync/protocol/deterministic_cbor.dart';

import '../support/identities.dart';

Future<void> copyRecords(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final file in from.list()) {
    if (file is File && !file.path.endsWith('.partial')) {
      await file.copy('${to.path}/${file.uri.pathSegments.last}');
    }
  }
}

class _TlsStorage implements SecureTlsIdentityStorage {
  TlsIdentity? value;
  @override
  Future<TlsIdentity?> readCurrent() async => value;
  @override
  Future<TlsIdentity> installIfAbsent(TlsIdentity candidate) async =>
      value ??= candidate;
}

class _Discovery implements LanPeerDiscovery {
  @override
  Future<void> advertise(String deviceId, int port) async {}
  @override
  Future<List<DiscoveredPeer>> find(Set<String> deviceIds) async => [];
  @override
  Future<void> close() async {}
}

class _Engine implements FileSyncEngine {
  bool fail = false;
  int stops = 0;
  List<Map<String, Object?>> configurations = [];
  @override
  Future<void> start(Map<String, Object?> c) async {
    if (fail) throw const SocketException('offline');
  }

  @override
  Future<void> configure(Map<String, Object?> c) async {
    configurations.add(c);
  }

  @override
  Future<void> scan() async {}
  @override
  Future<Set<String>> connected() async => {};
  @override
  Future<void> close() async {
    stops++;
  }
}

void main() {
  late Directory directory;
  late List<AppDatabase> databases;
  late List<StudyAppController> apps;
  late List<OperationFileExchange> exchanges;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('yanji-exchange-');
    databases = List.generate(3, (_) => AppDatabase(NativeDatabase.memory()));
    apps = [];
    for (var i = 0; i < 3; i++) {
      apps.add(
        await StudyAppController.open(
          databases[i],
          await testIdentity(
            '01991f82-0000-7000-8000-00000000020${i + 1}',
            i + 1,
          ),
        ),
      );
    }
    final root = apps.first;
    await root.onboard(name: '考研', date: '2027-12-20', subjectNames: ['英语']);
    final genesis = await root.ensureWorkspaceGenesis();
    for (final peer in apps.skip(1)) {
      await root.addTrustedPeer(
        deviceId: peer.identity.deviceId,
        deviceName: '设备',
        platform: 'test',
        identityPublicKey: Uint8List.fromList(peer.identity.publicKey.bytes),
        tlsCertificateSha256: Uint8List.fromList(List.filled(32, 1)),
      );
    }
    final invite = PairingInvite.create(
      workspaceId: root.workspace!.id,
      workspaceGenesisHash: genesis,
      inviterDeviceId: root.identity.deviceId,
      identityPublicKey: Uint8List.fromList(root.identity.publicKey.bytes),
      tlsCertificateSha256: Uint8List.fromList(List.filled(32, 1)),
      port: 20000,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    for (final peer in apps.skip(1)) {
      await peer.importPairedHistory(
        invite,
        await root.applier.export(root.workspace!.id),
      );
    }
    exchanges = [
      for (var i = 0; i < 3; i++)
        OperationFileExchange(apps[i], Directory('${directory.path}/$i')),
    ];
  });
  tearDown(() async {
    for (final app in apps) {
      app.dispose();
    }
    for (final db in databases) {
      await db.close();
    }
    await directory.delete(recursive: true);
  });

  test('delivery requires each recipient commit, supports offline concurrency and deduplicates retries', () async {
    await apps[0].saveTask(title: '家里新增', date: apps[0].today);
    await apps[1].saveTask(title: '图书馆新增', date: apps[1].today);
    await exchanges[0].publish();
    await exchanges[1].publish();
    await copyRecords(exchanges[0].records, exchanges[1].records);
    expect((await exchanges[0].progress()).every((p) => p.pending > 0), isTrue);
    // Copying files is insufficient: receiver has not committed or signed an ack.
    expect(apps[1].tasks.any((t) => t.title == '家里新增'), isFalse);
    await exchanges[1].receive();
    await exchanges[1].publish();
    await copyRecords(exchanges[1].records, exchanges[0].records);
    await exchanges[0].receive();
    await exchanges[0].publish();
    expect(apps[0].tasks.map((t) => t.title), containsAll(['家里新增', '图书馆新增']));
    final progress = await exchanges[0].progress();
    expect(
      progress
          .singleWhere((p) => p.deviceId == apps[1].identity.deviceId)
          .pending,
      0,
    );
    expect(
      progress
          .singleWhere((p) => p.deviceId == apps[2].identity.deviceId)
          .pending,
      greaterThan(0),
    );
    final before = (await apps[0].applier.export(apps[0].workspace!.id)).length;
    expect(await exchanges[0].receive(), 0);
    expect(
      (await apps[0].applier.export(apps[0].workspace!.id)).length,
      before,
    );
    // A new worker ignores volatile imported hints and revalidates signed receipts.
    final restarted = OperationFileExchange(apps[0], exchanges[0].directory);
    expect(
      (await restarted.progress())
          .singleWhere((p) => p.deviceId == apps[1].identity.deviceId)
          .pending,
      0,
    );
    await restarted.receive();
    expect(
      (await apps[0].applier.export(apps[0].workspace!.id)).length,
      before,
    );
    await copyRecords(exchanges[0].records, exchanges[2].records);
    await exchanges[2].receive();
    await exchanges[2].publish();
    await copyRecords(exchanges[2].records, exchanges[0].records);
    await exchanges[0].receive();
    expect(
      (await exchanges[0].progress()).every(
        (p) => p.confirmed && p.pending == 0,
      ),
      isTrue,
    );
  });

  test('deletion and damaged transport files preserve local data and regenerate committed history', () async {
    await apps[0].saveTask(title: '不可丢失', date: apps[0].today);
    await exchanges[0].publish();
    final original = await exchanges[0].records
        .list()
        .where((f) => f.path.endsWith('.op'))
        .cast<File>()
        .first;
    final bytes = await original.readAsBytes();
    await original.writeAsString('broken', flush: true);
    await exchanges[0].receive();
    expect(exchanges[0].lastImportError, isNotNull);
    expect(apps[0].tasks.map((t) => t.title), contains('不可丢失'));
    await exchanges[0].publish();
    expect(await original.readAsBytes(), bytes);
    await original.delete();
    await exchanges[0].publish();
    expect(await original.readAsBytes(), bytes);
    await File('${exchanges[1].directory.path}/receipt-state.json')
        .create(recursive: true);
    await File('${exchanges[1].directory.path}/receipt-state.json')
        .writeAsString('bad cache');
    final restart = OperationFileExchange(apps[1], exchanges[1].directory);
    await copyRecords(exchanges[0].records, restart.records);
    await File('${restart.records.path}/interrupted.partial')
        .writeAsString('partial transfer');
    await restart.receive();
    expect(apps[1].tasks.map((t) => t.title), contains('不可丢失'));
    expect(restart.lastImportError, isNull);
  });

  test('forged receipt cannot mark an offline device synchronized', () async {
    await exchanges[0].publish();
    final body = DeterministicCbor.encode({
      'type': 'yanji.receipt.v1',
      'workspace': apps[0].workspace!.id,
      'device': apps[1].identity.deviceId,
      'frontier': await apps[0].applier.frontier(apps[0].workspace!.id),
    });
    final signed = DeterministicCbor.encode({
      'body': body,
      'signature': (await apps[2].identity.sign(body)).bytes,
    });
    await File(
      '${exchanges[0].records.path}/${crypto.sha256.convert(signed)}.ack',
    ).writeAsBytes(signed);
    await exchanges[0].receive();
    expect(exchanges[0].lastImportError, contains('身份校验'));
    expect(
      (await exchanges[0].progress()).every(
        (p) => !p.confirmed && p.pending > 0,
      ),
      isTrue,
    );
  });

  test(
    'backup retains complete signed history outside the synchronized folder',
    () async {
      await apps[0].saveTask(title: '备份记录', date: apps[0].today);
      final backup = await exchanges[0].backup();
      final manifest = jsonDecode(
        await File('${backup.path}/manifest.json').readAsString(),
      ) as Map;
      expect(backup.path.startsWith(exchanges[0].records.path), isFalse);
      final operations = await apps[0].applier.export(apps[0].workspace!.id);
      expect(manifest['files'], hasLength(operations.length));
      expect(apps[1].tasks.any((task) => task.title == '备份记录'), isFalse);
      expect(await exchanges[1].restoreBackup(backup), greaterThan(0));
      expect(apps[1].tasks.map((task) => task.title), contains('备份记录'));
      for (final hash in (manifest['files'] as List).cast<String>()) {
        final bytes = await File('${backup.path}/$hash.op').readAsBytes();
        expect(crypto.sha256.convert(bytes).toString(), hash);
      }
    },
  );

  test('paired non-root identity can reopen its committed workspace', () async {
    final identity = apps[1].identity;
    apps[1].dispose();
    apps[1] = await StudyAppController.open(databases[1], identity);
    expect(apps[1].workspace!.id, apps[0].workspace!.id);
    await apps[1].saveTask(title: '重开后写入', date: apps[1].today);
    expect(apps[1].tasks.map((t) => t.title), contains('重开后写入'));
  });
  test('manual timeout and engine failure retain data, and revocation removes native sharing', () async {
    final pairing = await DevicePairingCoordinator.open(
      apps[0],
      _TlsStorage(),
      bindAddress: InternetAddress.loopbackIPv4,
      advertisedAddresses: ['127.0.0.1'],
      discovery: _Discovery(),
    );
    final engine = _Engine()..fail = true;
    final sync = AutomaticSyncController(
      app: apps[0],
      directory: exchanges[0].directory,
      pairing: pairing,
      engine: engine,
    );
    try {
      await apps[0].saveTask(title: '离线仍保存', date: apps[0].today);
      await sync.tick();
      expect(sync.error, isNotNull);
      expect(apps[0].tasks.map((task) => task.title), contains('离线仍保存'));
      engine.fail = false;
      await expectLater(sync.syncNow(timeout: Duration.zero), throwsStateError);
      expect(sync.complete, isFalse);
      expect(engine.configurations.last['peers'], hasLength(2));
      await apps[0].revokeTrustedPeer(
        apps[0].trustedPeers.singleWhere(
          (peer) => peer.deviceId == apps[2].identity.deviceId,
        ),
      );
      await sync.tick();
      expect(engine.configurations.last['peers'], hasLength(1));
      await apps[0].revokeTrustedPeer(
        apps[0].trustedPeers.singleWhere(
          (peer) => peer.deviceId == apps[1].identity.deviceId,
        ),
      );
      await sync.tick();
      expect(engine.stops, 1);
      expect(sync.peers, isEmpty);
      expect(apps[0].tasks.map((task) => task.title), contains('离线仍保存'));
    } finally {
      await sync.close();
      await pairing.close();
    }
  });
  test(
    'renaming retains peer identity and reaches the paired device',
    () async {
      final peer = apps[0].trustedPeers.singleWhere(
        (p) => p.deviceId == apps[1].identity.deviceId,
      );
      await apps[0].renameTrustedPeer(peer, '图书馆手机');
      final renamed = apps[0].trustedPeers.singleWhere(
        (p) => p.deviceId == peer.deviceId,
      );
      expect(renamed.deviceName, '图书馆手机');
      expect(renamed.publicKey.bytes, peer.publicKey.bytes);
      expect(renamed.tlsCertificateSha256, peer.tlsCertificateSha256);
      await exchanges[0].publish();
      await copyRecords(exchanges[0].records, exchanges[1].records);
      await exchanges[1].receive();
      expect(
        apps[1].trustedPeers
            .singleWhere((p) => p.deviceId == peer.deviceId)
            .deviceName,
        '图书馆手机',
      );
    },
  );

  test('idle synchronization without peers keeps one message and performs no native work', () async {
    await apps[0].revokeTrustedPeer(
      apps[0].trustedPeers.singleWhere(
        (p) => p.deviceId == apps[1].identity.deviceId,
      ),
    );
    await apps[0].revokeTrustedPeer(
      apps[0].trustedPeers.singleWhere(
        (p) => p.deviceId == apps[2].identity.deviceId,
      ),
    );
    final pairing = await DevicePairingCoordinator.open(
      apps[0],
      _TlsStorage(),
      bindAddress: InternetAddress.loopbackIPv4,
      advertisedAddresses: ['127.0.0.1'],
      discovery: _Discovery(),
    );
    final engine = _Engine();
    final sync = AutomaticSyncController(
      app: apps[0],
      directory: exchanges[0].directory,
      pairing: pairing,
      engine: engine,
    );
    final messages = <String>[];
    sync.addListener(() => messages.add(sync.message));
    try {
      await sync.tick();
      await sync.tick();
      await sync.tick();
      expect(messages, ['本机记录已保存，配对设备后可自动同步']);
      expect(engine.configurations, isEmpty);
    } finally {
      await sync.close();
      await pairing.close();
    }
  });
}
