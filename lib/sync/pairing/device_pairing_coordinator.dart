import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../application/study_app_controller.dart';
import '../oplog/operation.dart';
import '../transport/pinned_tls_transport.dart';
import '../transport/tls_identity.dart';
import 'pairing_invite.dart';

final class IncomingPairRequest {
  IncomingPairRequest._({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.identityPublicKey,
    required this.tlsCertificateSha256,
    required this.safetyCode,
    required this._decision,
  });
  final String deviceId;
  final String deviceName;
  final String platform;
  final Uint8List identityPublicKey;
  final Uint8List tlsCertificateSha256;
  final String safetyCode;
  final Completer<bool> _decision;
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
  );
  final String safetyCode;
  final YppChannel _channel;
  final StudyAppController _app;
  final PairingInvite _invite;
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
      await _app.importPairedHistory(_invite, operations);
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
  ) {
    _subscription = listener.connections.listen(_accept);
  }

  final StudyAppController app;
  final TlsIdentity tlsIdentity;
  final TlsPeerListener listener;
  final List<String> ipHints;
  final incomingRequests = StreamController<IncomingPairRequest>.broadcast();
  StreamSubscription<SecureSocket>? _subscription;
  PairingInvitationSession? _invitation;

  static Future<DevicePairingCoordinator> open(
    StudyAppController app,
    SecureTlsIdentityStorage storage, {
    InternetAddress? bindAddress,
    List<String>? advertisedAddresses,
  }) async {
    final tls = await TlsIdentityService(storage)
        .loadOrCreate(app.identity.deviceId);
    final listener = await TlsPeerListener.bind(tls, address: bindAddress);
    final hints = advertisedAddresses ?? await _localAddresses();
    return DevicePairingCoordinator._(app, tls, listener, hints);
  }

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
  }) async {
    final socket = await PinnedTlsTransport.connect(invite);
    final channel = YppChannel(socket);
    await channel.send({
      'type': 'pair.request',
      'v': PairingInvite.protocolVersion,
      'workspace_id': invite.workspaceId,
      'invite_id': invite.inviteId,
      'pair_secret': invite.pairSecret,
      'device_id': app.identity.deviceId,
      'device_name': deviceName,
      'platform': platform,
      'identity_public_key': Uint8List.fromList(app.identity.publicKey.bytes),
      'tls_cert_sha256': tlsIdentity.fingerprintSha256,
    });
    final response = await channel.receive().timeout(
      const Duration(seconds: 10),
    );
    if (response['type'] != 'pair.challenge' || response['code'] is! String) {
      await channel.close();
      throw StateError(response['message'] as String? ?? '邀请无效或已使用');
    }
    return OutgoingPairSession._(
      response['code']! as String,
      channel,
      app,
      invite,
    );
  }

  Future<void> _accept(SecureSocket socket) async {
    final channel = YppChannel(socket);
    try {
      final request = await channel.receive().timeout(
        const Duration(seconds: 10),
      );
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
      final decision = Completer<bool>();
      final incoming = IncomingPairRequest._(
        deviceId: request['device_id']! as String,
        deviceName: request['device_name']! as String,
        platform: request['platform']! as String,
        identityPublicKey: key,
        tlsCertificateSha256: request['tls_cert_sha256']! as Uint8List,
        safetyCode: await invitation.invite.safetyCode(key),
        decision: decision,
      );
      incomingRequests.add(incoming);
      await channel.send({
        'type': 'pair.challenge',
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
      await app.addTrustedPeer(
        deviceId: incoming.deviceId,
        deviceName: incoming.deviceName,
        platform: incoming.platform,
        identityPublicKey: incoming.identityPublicKey,
        tlsCertificateSha256: incoming.tlsCertificateSha256,
      );
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
    } catch (_) {
      // A malformed or disconnected peer is isolated to this connection.
    } finally {
      await channel.close();
    }
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
  }
}
