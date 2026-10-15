import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../application/study_app_controller.dart';
import '../oplog/operation.dart';
import '../protocol/deterministic_cbor.dart';
import '../transport/pinned_tls_transport.dart';
import '../transport/lan_peer_discovery.dart';
import '../transport/tls_identity.dart';
import '../trust/trust_chain.dart';
import 'pairing_invite.dart';

final class SyncPeerEndpoint {
  SyncPeerEndpoint({
    required List<String> addresses,
    required this.port,
    this.confirmed = true,
    required Uint8List tlsCertificateSha256,
  }) : addresses = List.unmodifiable(addresses),
       tlsCertificateSha256 = Uint8List.fromList(tlsCertificateSha256);

  final List<String> addresses;
  final int port;
  final bool confirmed;
  final Uint8List tlsCertificateSha256;
}

final class IncomingPairRequest {
  IncomingPairRequest._({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.identityPublicKey,
    required this.tlsCertificateSha256,
    required this.safetyCode,
    required this._decision,
    required this._completion,
  });
  final String deviceId;
  final String deviceName;
  final String platform;
  final Uint8List identityPublicKey;
  final Uint8List tlsCertificateSha256;
  final String safetyCode;
  final Completer<bool> _decision;
  final Completer<bool> _completion;
  Future<bool> get completion => _completion.future;
  bool get decided => _decision.isCompleted;
  void approve() {
    if (!decided) _decision.complete(true);
  }

  void reject() {
    if (!decided) _decision.complete(false);
  }
}

final class OutgoingPairSession {
  OutgoingPairSession._(
    this.safetyCode,
    this._channel,
    this._app,
    this._invite,
    this._onPaired,
    this._mergeExisting,
  );
  final String safetyCode;
  final YppChannel _channel;
  final StudyAppController _app;
  final PairingInvite _invite;
  final void Function()? _onPaired;
  final bool _mergeExisting;
  bool _completed = false;

  Future<void> confirm() async {
    if (_completed) throw StateError('配对会话已经结束');
    _completed = true;
    try {
      await _channel.send({'type': 'code.confirmed'});
      final response = await _channel.receive().timeout(PairingInvite.lifetime);
      if (response['type'] != 'pair.approved' ||
          response['operation_count'] is! int ||
          (response['operation_count']! as int) < 0) {
        throw StateError(response['message'] as String? ?? '邀请设备拒绝了配对');
      }
      final operations = <Operation>[];
      while (true) {
        final message = await _channel.receive().timeout(
          PairingInvite.lifetime,
        );
        if (message['type'] == 'history.complete') break;
        if (message['type'] != 'history.batch' ||
            message['operations'] is! List<Object?> ||
            (message['operations']! as List<Object?>).length > 256) {
          throw const FormatException('配对历史批次损坏');
        }
        for (final raw in message['operations']! as List<Object?>) {
          if (raw is! Map<String, Object?> ||
              raw['envelope'] is! Uint8List ||
              raw['signature'] is! Uint8List) {
            throw const FormatException('配对历史报文损坏');
          }
          operations.add(
            Operation(
              envelopeBytes: raw['envelope']! as Uint8List,
              signature: raw['signature']! as Uint8List,
            ),
          );
        }
      }
      if (operations.length != response['operation_count']) {
        throw const FormatException('配对历史数量不一致');
      }
      await _app.importPairedHistory(
        _invite,
        operations,
        mergeExisting: _mergeExisting,
      );
      debugPrint('[研迹配对] 本机记录导入并保存完成');
      _onPaired?.call();
      await _channel.send({'type': 'pair.imported'});
      final completion = await _channel.receive().timeout(
        PairingInvite.lifetime,
      );
      if (completion['type'] != 'pair.complete') {
        throw StateError('记录已保存，请重新配对以确认另一端状态');
      }
      debugPrint('[研迹配对] 双端配对完成');
    } catch (error, stack) {
      debugPrint('[研迹配对] 导入或确认失败：$error\n$stack');
      try {
        await _channel.send({'type': 'pair.failed'});
      } catch (_) {}
      rethrow;
    } finally {
      await _channel.close();
    }
  }

  Future<void> cancel() async {
    if (_completed) return;
    _completed = true;
    await _channel.send({'type': 'code.rejected'});
    await _channel.close();
  }
}

final class DevicePairingCoordinator {
  DevicePairingCoordinator._(
    this.app,
    this.tlsIdentity,
    this.listener,
    this.ipHints,
    this.endpointStorage,
    this.discovery,
  ) {
    _subscription = listener.connections.listen(
      _accept,
      onError: (Object _) {
        // A failed TLS handshake must not terminate the device's listener.
      },
    );
  }

  final StudyAppController app;
  final TlsIdentity tlsIdentity;
  final TlsPeerListener listener;
  final List<String> ipHints;
  final PersistentSyncEndpointStorage? endpointStorage;
  final LanPeerDiscovery discovery;
  final incomingRequests = StreamController<IncomingPairRequest>.broadcast();
  final _endpoints = <String, SyncPeerEndpoint>{};
  StreamSubscription<SecureSocket>? _subscription;
  PairingInvitationSession? _invitation;

  static Future<DevicePairingCoordinator> open(
    StudyAppController app,
    SecureTlsIdentityStorage storage, {
    InternetAddress? bindAddress,
    List<String>? advertisedAddresses,
    LanPeerDiscovery? discovery,
  }) async {
    debugPrint('[研迹配对] 配对监听已启动');
    final tls = await TlsIdentityService(storage)
        .loadOrCreate(app.identity.deviceId);
    final listener = await TlsPeerListener.bind(tls, address: bindAddress);
    final hints = advertisedAddresses ?? await _localAddresses();
    final coordinator = DevicePairingCoordinator._(
      app,
      tls,
      listener,
      hints,
      storage is PersistentSyncEndpointStorage
          ? storage as PersistentSyncEndpointStorage
          : null,
      discovery ?? BonjourPeerDiscovery(),
    );
    await coordinator._loadEndpoints();
    await coordinator.refreshDiscovery();
    return coordinator;
  }

  Future<void> refreshDiscovery() async {
    try {
      await discovery.advertise(app.identity.deviceId, listener.port);
    } catch (_) {
      // Discovery may be unavailable or denied; cached endpoints still work.
    }
  }

  bool isPairConfirmed(String deviceId) =>
      _endpoints[deviceId]?.confirmed != false;

  /// Syncthing IDs are derived from the same certificate already anchored
  /// by pairing. Do not introduce an independently trusted transport identity.
  List<Map<String, Object?>> get transportPeers => [
    for (final peer in app.trustedPeers)
      if (peer.active &&
          peer.deviceId != app.identity.deviceId &&
          _endpoints[peer.deviceId]?.confirmed != false &&
          (_endpoints[peer.deviceId] != null ||
              peer.tlsCertificateSha256.any((b) => b != 0)))
        {
          'id': peer.deviceId,
          'fingerprint': base64Encode(
            _endpoints[peer.deviceId]?.tlsCertificateSha256 ??
                peer.tlsCertificateSha256,
          ),
        },
  ];

  Future<PairingInvite> createInvitation() async {
    final workspace = app.workspace ?? (throw StateError('请先创建学习空间'));
    final genesis = await app.ensureWorkspaceGenesis();
    final invite = PairingInvite.create(
      workspaceId: workspace.id,
      workspaceGenesisHash: genesis,
      inviterDeviceId: app.identity.deviceId,
      identityPublicKey: Uint8List.fromList(app.identity.publicKey.bytes),
      tlsCertificateSha256: tlsIdentity.fingerprintSha256,
      port: listener.port,
      nowMs: DateTime.now().millisecondsSinceEpoch,
      ipHints: ipHints,
    );
    _invitation = PairingInvitationSession(invite);
    return invite;
  }

  Future<OutgoingPairSession> beginJoin(
    PairingInvite invite, {
    required String deviceName,
    required String platform,
    bool mergeExisting = false,
  }) async {
    debugPrint('[研迹配对] 开始连接邀请设备');
    if (app.workspace != null && app.workspace!.id != invite.workspaceId) {
      if (!mergeExisting) throw StateError('两台设备属于不同学习空间，请先确认合并记录');
      if (app.runningSession != null) throw StateError('请先结束本机正在进行的计时，再合并配对');
    }
    final socket = await PinnedTlsTransport.connect(invite);
    final channel = YppChannel(socket);
    await channel.send({
      'type': 'pair.request',
      'pairing_receipt': 1,
      'v': PairingInvite.protocolVersion,
      'workspace_id': invite.workspaceId,
      'invite_id': invite.inviteId,
      'pair_secret': invite.pairSecret,
      'device_id': app.identity.deviceId,
      'device_name': deviceName,
      'platform': platform,
      'identity_public_key': Uint8List.fromList(app.identity.publicKey.bytes),
      'tls_cert_sha256': tlsIdentity.fingerprintSha256,
      'sync_port': listener.port,
      'sync_addresses': ipHints,
    });
    final response = await channel.receive().timeout(
      const Duration(seconds: 10),
    );
    if (response['type'] == 'pair.challenge' &&
        response['pairing_receipt'] != 1) {
      await channel.close();
      throw StateError('请先将另一台设备的研迹更新至最新版，再重新配对');
    }
    if (response['type'] != 'pair.challenge' || response['code'] is! String) {
      await channel.close();
      throw StateError(response['message'] as String? ?? '邀请无效或已使用');
    }
    return OutgoingPairSession._(
      response['code']! as String,
      channel,
      app,
      invite,
      () => _rememberEndpoint(
        invite.inviterDeviceId,
        SyncPeerEndpoint(
          addresses: invite.ipHints,
          port: invite.port,
          tlsCertificateSha256: invite.tlsCertificateSha256,
        ),
      ),
      mergeExisting,
    );
  }

  Future<void> _accept(SecureSocket socket) async {
    final channel = YppChannel(socket);
    IncomingPairRequest? incoming;
    try {
      final request = await channel.receive().timeout(
        const Duration(seconds: 10),
      );
      if (request['type'] == 'sync.auth') {
        await _acceptSync(channel, request);
        return;
      }
      if (request['pairing_receipt'] != 1) {
        await channel.send({
          'type': 'pair.rejected',
          'message': '请先将两台设备的研迹更新至最新版，再重新配对',
        });
        return;
      }
      final invitation = _invitation;
      if (!_validRequest(request) ||
          invitation == null ||
          !invitation.consume(
            inviteId: request['invite_id']! as String,
            pairSecret: request['pair_secret']! as Uint8List,
            nowMs: DateTime.now().millisecondsSinceEpoch,
          )) {
        await channel.send({'type': 'pair.rejected', 'message': '邀请无效、过期或已使用'});
        return;
      }
      final key = request['identity_public_key']! as Uint8List;
      final oldPeer = app.trustedPeers
          .where((peer) => peer.deviceId == request['device_id'])
          .firstOrNull;
      if (oldPeer != null && !oldPeer.active) {
        debugPrint('[研迹配对] 拒绝已撤销的设备身份重新加入');
        await channel.send({
          'type': 'pair.rejected',
          'message': '这台设备的旧授权已被撤销，不能直接重新加入该学习空间。请从未撤销的学习空间发起配对，已有记录保留。',
        });
        return;
      }
      debugPrint('[研迹配对] 收到配对申请，等待双端核对安全码');
      final decision = Completer<bool>();
      incoming = IncomingPairRequest._(
        deviceId: request['device_id']! as String,
        deviceName: request['device_name']! as String,
        platform: request['platform']! as String,
        identityPublicKey: key,
        tlsCertificateSha256: request['tls_cert_sha256']! as Uint8List,
        safetyCode: await invitation.invite.safetyCode(key),
        decision: decision,
        completion: Completer<bool>(),
      );
      incomingRequests.add(incoming);
      await channel.send({
        'type': 'pair.challenge',
        'pairing_receipt': 1,
        'code': incoming.safetyCode,
      });
      final confirmation = await channel.receive().timeout(
        PairingInvite.lifetime,
      );
      final approved =
          confirmation['type'] == 'code.confirmed' &&
          await decision.future.timeout(
            PairingInvite.lifetime,
            onTimeout: () => false,
          );
      if (!approved) {
        await channel.send({'type': 'pair.rejected', 'message': '配对已取消'});
        return;
      }
      final addresses = request['sync_addresses'];
      final port = request['sync_port'];
      if (addresses is List<Object?> &&
          addresses.every((item) => item is String) &&
          port is int &&
          port > 0 &&
          port <= 65535) {
        _rememberEndpoint(
          incoming.deviceId,
          SyncPeerEndpoint(
            addresses: addresses.cast<String>(),
            port: port,
            tlsCertificateSha256: incoming.tlsCertificateSha256,
            confirmed: false,
          ),
        );
      }
      await app.addTrustedPeer(
        deviceId: incoming.deviceId,
        deviceName: incoming.deviceName,
        platform: incoming.platform,
        identityPublicKey: incoming.identityPublicKey,
        tlsCertificateSha256: incoming.tlsCertificateSha256,
      );
      debugPrint('[研迹配对] 已写入授权，开始传送记录');
      final operations = await app.applier.export(app.workspace!.id);
      await channel.send({
        'type': 'pair.approved',
        'operation_count': operations.length,
      });
      for (var offset = 0; offset < operations.length; offset += 256) {
        final end = (offset + 256).clamp(0, operations.length);
        await channel.send({
          'type': 'history.batch',
          'operations': [
            for (final operation in operations.sublist(offset, end))
              {
                'envelope': operation.envelopeBytes,
                'signature': operation.signature,
              },
          ],
        });
      }
      await channel.send({'type': 'history.complete'});
      final imported = await channel.receive().timeout(PairingInvite.lifetime);
      if (imported['type'] != 'pair.imported') {
        debugPrint('[研迹配对] 另一端未完成记录导入');
        return;
      }
      final endpoint = _endpoints[incoming.deviceId];
      if (endpoint != null) {
        _rememberEndpoint(
          incoming.deviceId,
          SyncPeerEndpoint(
            addresses: endpoint.addresses,
            port: endpoint.port,
            tlsCertificateSha256: endpoint.tlsCertificateSha256,
          ),
        );
        await _persistEndpoints();
      }
      app.notifyPairingChanged();
      await channel.send({'type': 'pair.complete'});
      incoming._completion.complete(true);
      debugPrint('[研迹配对] 已收到保存回执，双端配对完成');
    } catch (error, stack) {
      debugPrint('[研迹配对] 会话未完成：$error\n$stack');
      // A malformed or disconnected peer is isolated to this connection.
    } finally {
      if (incoming != null && !incoming._completion.isCompleted) {
        incoming._completion.complete(false);
      }
      await channel.close();
    }
  }

  Future<int> syncPairedDevices() async {
    final workspace = app.workspace ?? (throw StateError('工作区尚未初始化'));
    final peers = app.trustedPeers
        .where((peer) => peer.deviceId != app.identity.deviceId && peer.active)
        .toList();
    if (peers.isEmpty) throw StateError('暂无已绑定设备');
    final discovered = <String, SyncPeerEndpoint>{};
    try {
      for (final result in await discovery.find(
        peers.map((peer) => peer.deviceId).toSet(),
      )) {
        final peer = peers
            .where((p) => p.deviceId == result.deviceId)
            .firstOrNull;
        if (peer == null ||
            result.addresses.isEmpty ||
            result.port < 1 ||
            result.port > 65535) {
          continue;
        }
        discovered[peer.deviceId] = SyncPeerEndpoint(
          addresses: result.addresses,
          port: result.port,
          // Never accept a certificate or identity from discovery.
          // The root's legacy genesis has no TLS pin; its pin was anchored
          // by the pairing QR and persisted with the endpoint instead.
          tlsCertificateSha256:
              _endpoints[peer.deviceId]?.tlsCertificateSha256 ??
              peer.tlsCertificateSha256,
        );
      }
    } catch (_) {
      // Fall back to the last authenticated address when discovery is blocked.
    }
    var transferred = 0;
    Object? lastError;
    for (final peer in peers) {
      final candidates = [
        ?discovered[peer.deviceId],
        ?_endpoints[peer.deviceId],
      ];
      for (final endpoint in candidates) {
        try {
          transferred += await _syncPeer(workspace.id, peer, endpoint);
          _endpoints[peer.deviceId] = endpoint;
          await _persistEndpoints();
          break;
        } catch (error) {
          lastError = error;
        }
      }
    }
    if (transferred == 0 && lastError != null) {
      throw StateError('同步失败：$lastError');
    }
    if (transferred == 0) {
      throw StateError('暂未发现已绑定设备，请先在同一局域网打开另一台设备。');
    }
    return transferred;
  }

  Future<int> _syncPeer(
    String workspaceId,
    TrustedPeer peer,
    SyncPeerEndpoint endpoint,
  ) async {
    final socket = await PinnedTlsTransport.connectEndpoint(
      addresses: endpoint.addresses,
      port: endpoint.port,
      tlsCertificateSha256: endpoint.tlsCertificateSha256,
    );
    final channel = YppChannel(socket);
    try {
      final nonce = Uint8List.fromList(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)),
      );
      final auth = _authBytes(
        nonce,
        workspaceId,
        app.identity.deviceId,
        peer.deviceId,
      );
      final signature = await app.identity.sign(auth);
      await channel.send({
        'type': 'sync.auth',
        'protocol': 2,
        'workspace_id': workspaceId,
        'device_id': app.identity.deviceId,
        'nonce': nonce,
        'signature': signature.bytes,
      });
      final challenge = await channel.receive().timeout(
        const Duration(seconds: 10),
      );
      if (challenge['type'] != 'sync.challenge' ||
          challenge['device_id'] != peer.deviceId ||
          challenge['signature'] is! Uint8List ||
          challenge['responder_nonce'] is! Uint8List ||
          (challenge['responder_nonce'] as Uint8List).length != 32) {
        throw StateError('已绑定设备拒绝了同步认证');
      }
      final verified = await Ed25519().verify(
        auth,
        signature: Signature(
          challenge['signature']! as Uint8List,
          publicKey: peer.publicKey,
        ),
      );
      if (!verified) throw StateError('同步设备身份校验失败');

      final proof = await app.identity.sign(
        _proofBytes(auth, challenge['responder_nonce']! as Uint8List),
      );
      await channel.send({'type': 'sync.proof', 'signature': proof.bytes});
      final localFrontier = await app.applier.frontier(workspaceId);
      await channel.send({'type': 'sync.hello', 'frontier': localFrontier});
      final remoteHello = await channel.receive().timeout(
        const Duration(seconds: 10),
      );
      final remoteFrontier = _frontier(remoteHello['frontier']);
      var transferred = await _receiveBatches(
        channel,
        workspaceId,
        peer.deviceId,
      );
      transferred += await _sendMissing(channel, workspaceId, remoteFrontier);
      await channel.send({'type': 'sync.done'});
      final complete = await channel.receive().timeout(
        const Duration(seconds: 10),
      );
      if (complete['type'] != 'sync.complete') {
        throw StateError('同步未完成');
      }
      await app.refresh();
      // Count a successful peer even when both sides were already current.
      return max(1, transferred);
    } finally {
      await channel.close();
    }
  }

  Future<void> _acceptSync(
    YppChannel channel,
    Map<String, Object?> request,
  ) async {
    final workspaceId = request['workspace_id'];
    final deviceId = request['device_id'];
    final nonce = request['nonce'];
    final signature = request['signature'];
    final current = app.workspace;
    if (request['protocol'] != 2 ||
        current == null ||
        workspaceId != current.id ||
        deviceId is! String ||
        nonce is! Uint8List ||
        nonce.length != 32 ||
        signature is! Uint8List ||
        signature.length != 64) {
      await channel.send({'type': 'sync.rejected', 'message': '同步请求无效'});
      return;
    }
    final peer = app.trustedPeers
        .where((item) => item.deviceId == deviceId && item.active)
        .firstOrNull;
    if (peer == null) {
      await channel.send({'type': 'sync.rejected', 'message': '设备尚未授权'});
      return;
    }
    final auth = _authBytes(nonce, current.id, deviceId, app.identity.deviceId);
    final verified = await Ed25519().verify(
      auth,
      signature: Signature(signature, publicKey: peer.publicKey),
    );
    if (!verified) {
      await channel.send({'type': 'sync.rejected', 'message': '同步设备身份校验失败'});
      return;
    }
    final responderNonce = Uint8List.fromList(
      List<int>.generate(32, (_) => Random.secure().nextInt(256)),
    );
    final challenge = await app.identity.sign(auth);
    await channel.send({
      'type': 'sync.challenge',
      'device_id': app.identity.deviceId,
      'signature': challenge.bytes,
      'responder_nonce': responderNonce,
    });
    final proof = await channel.receive().timeout(const Duration(seconds: 10));
    if (proof['type'] != 'sync.proof' ||
        proof['signature'] is! Uint8List ||
        !await Ed25519().verify(
          _proofBytes(auth, responderNonce),
          signature: Signature(
            proof['signature']! as Uint8List,
            publicKey: peer.publicKey,
          ),
        )) {
      await channel.send({'type': 'sync.rejected', 'message': '同步设备身份校验失败'});
      return;
    }
    final hello = await channel.receive().timeout(const Duration(seconds: 10));
    final remoteFrontier = _frontier(hello['frontier']);
    final localFrontier = await app.applier.frontier(current.id);
    await channel.send({'type': 'sync.peer-hello', 'frontier': localFrontier});
    await _sendMissing(channel, current.id, remoteFrontier);
    await channel.send({'type': 'sync.done'});
    await _receiveBatches(channel, current.id, deviceId);
    await app.refresh();
    await channel.send({'type': 'sync.complete'});
  }

  Future<int> _sendMissing(
    YppChannel channel,
    String workspaceId,
    Map<String, int> remoteFrontier,
  ) async {
    final missing = [
      for (final operation in await app.applier.export(workspaceId))
        if (operation.parse().originSeq >
            (remoteFrontier[operation.parse().originDeviceId] ?? 0))
          operation,
    ];
    for (var offset = 0; offset < missing.length; offset += 256) {
      final end = min(offset + 256, missing.length);
      await channel.send({
        'type': 'sync.batch',
        'operations': [
          for (final operation in missing.sublist(offset, end))
            {
              'envelope': operation.envelopeBytes,
              'signature': operation.signature,
            },
        ],
      });
    }
    return missing.length;
  }

  Future<int> _receiveBatches(
    YppChannel channel,
    String workspaceId,
    String receivedFrom,
  ) async {
    var count = 0;
    while (true) {
      final message = await channel.receive().timeout(
        const Duration(seconds: 30),
      );
      if (message['type'] == 'sync.done') return count;
      if (message['type'] != 'sync.batch' ||
          message['operations'] is! List<Object?> ||
          (message['operations']! as List<Object?>).length > 256) {
        throw const FormatException('同步数据批次损坏');
      }
      for (final raw in message['operations']! as List<Object?>) {
        if (raw is! Map<String, Object?> ||
            raw['envelope'] is! Uint8List ||
            raw['signature'] is! Uint8List) {
          throw const FormatException('同步操作报文损坏');
        }
        final operation = Operation(
          envelopeBytes: raw['envelope']! as Uint8List,
          signature: raw['signature']! as Uint8List,
        );
        final envelope = operation.parse();
        await app.applier.receive(
          operation,
          workspaceId: workspaceId,
          originDeviceId: envelope.originDeviceId,
          receivedFrom: receivedFrom,
        );
        count++;
      }
    }
  }

  static Map<String, int> _frontier(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('同步 frontier 格式错误');
    }
    final result = <String, int>{};
    for (final entry in value.entries) {
      final number = entry.value;
      if (number is! int || number < 0) {
        throw const FormatException('同步 frontier 格式错误');
      }
      result[entry.key] = number;
    }
    return result;
  }

  static Uint8List _authBytes(
    Uint8List nonce,
    String workspaceId,
    String initiatorId,
    String responderId,
  ) => DeterministicCbor.encode({
    'nonce': nonce,
    'workspace_id': workspaceId,
    'initiator_device_id': initiatorId,
    'responder_device_id': responderId,
  });

  // TLS pins the responder; this fresh challenge proves the initiator's
  // trusted identity without assuming TLS client certificates are configured.
  // A captured sync.auth cannot authorize a later connection.
  static Uint8List _proofBytes(Uint8List auth, Uint8List responderNonce) =>
      DeterministicCbor.encode({
        'type': 'yanji.sync.proof.v2',
        'auth': auth,
        'responder_nonce': responderNonce,
      });

  void _rememberEndpoint(String deviceId, SyncPeerEndpoint endpoint) {
    if (endpoint.addresses.isNotEmpty) {
      _endpoints[deviceId] = endpoint;
      unawaited(_persistEndpoints());
    }
  }

  Future<void> _loadEndpoints() async {
    final raw = await endpointStorage?.readSyncEndpoints();
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic> ||
            value['addresses'] is! List ||
            value['port'] is! int ||
            value['certificate'] is! String) {
          continue;
        }
        final addresses = (value['addresses'] as List)
            .whereType<String>()
            .toList();
        final certificate = base64Decode(value['certificate'] as String);
        if (addresses.isNotEmpty &&
            (value['port'] as int) > 0 &&
            (value['port'] as int) <= 65535 &&
            certificate.length == 32) {
          _endpoints[entry.key] = SyncPeerEndpoint(
            addresses: addresses,
            port: value['port'] as int,
            confirmed: value['confirmed'] != false,
            tlsCertificateSha256: Uint8List.fromList(certificate),
          );
        }
      }
    } catch (_) {
      // Corrupt hints are disposable; trust records remain authoritative.
    }
  }

  Future<void> _persistEndpoints() async {
    final storage = endpointStorage;
    if (storage == null) return;
    await storage.writeSyncEndpoints(
      jsonEncode({
        for (final entry in _endpoints.entries)
          entry.key: {
            'addresses': entry.value.addresses,
            'port': entry.value.port,
            'confirmed': entry.value.confirmed,
            'certificate': base64Encode(entry.value.tlsCertificateSha256),
          },
      }),
    );
  }

  bool _validRequest(Map<String, Object?> request) =>
      request['type'] == 'pair.request' &&
      request['v'] == PairingInvite.protocolVersion &&
      request['workspace_id'] == _invitation?.invite.workspaceId &&
      request['invite_id'] is String &&
      request['pair_secret'] is Uint8List &&
      (request['pair_secret']! as Uint8List).length == 32 &&
      request['device_id'] is String &&
      request['device_name'] is String &&
      (request['device_name']! as String).trim().isNotEmpty &&
      (request['device_name']! as String).length <= 80 &&
      request['platform'] is String &&
      request['identity_public_key'] is Uint8List &&
      (request['identity_public_key']! as Uint8List).length == 32 &&
      request['tls_cert_sha256'] is Uint8List &&
      (request['tls_cert_sha256']! as Uint8List).length == 32;

  static Future<List<String>> _localAddresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
    );
    return [
      for (final interface in interfaces)
        for (final address in interface.addresses)
          if (address.type == InternetAddressType.IPv4 ||
              address.type == InternetAddressType.IPv6)
            address.address,
    ];
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await incomingRequests.close();
    await listener.close();
    await discovery.close();
  }
}
