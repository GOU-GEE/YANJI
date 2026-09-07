import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../../core/ids/entity_ids.dart';
import '../protocol/deterministic_cbor.dart';

/// The authenticated bootstrap token defined by SYNC.md YPP/1.
///
/// IP addresses are only connection hints. Identity is anchored by the inviter
/// key, workspace genesis hash, and the TLS certificate fingerprint.
final class PairingInvite {
  PairingInvite({
    required this.workspaceId,
    required this.workspaceGenesisHash,
    required this.inviteId,
    required this.inviterDeviceId,
    required this.identityPublicKey,
    required this.tlsCertificateSha256,
    required this.pairSecret,
    required this.port,
    required this.expiresAtMs,
    this.ipHints = const [],
  }) {
    _validate();
  }

  static const protocolVersion = 2;
  static const service = '_yanji-sync._tcp';
  static const lifetime = Duration(minutes: 2);
  static const _prefix = 'yanji://pair-code?v=2&data=';
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final String workspaceId;
  final Uint8List workspaceGenesisHash;
  final String inviteId;
  final String inviterDeviceId;
  final Uint8List identityPublicKey;
  final Uint8List tlsCertificateSha256;
  final Uint8List pairSecret;
  final int port;
  final int expiresAtMs;
  final List<String> ipHints;

  PairingCard get card => PairingCard(
    workspaceId: workspaceId,
    workspaceGenesisHash: workspaceGenesisHash,
    inviterDeviceId: inviterDeviceId,
    identityPublicKey: identityPublicKey,
    tlsCertificateSha256: tlsCertificateSha256,
  );

  static PairingInvite create({
    required String workspaceId,
    required Uint8List workspaceGenesisHash,
    required String inviterDeviceId,
    required Uint8List identityPublicKey,
    required Uint8List tlsCertificateSha256,
    required int port,
    required int nowMs,
    List<String> ipHints = const [],
    EntityIds? ids,
    Random? random,
  }) {
    final secureRandom = random ?? Random.secure();
    return PairingInvite(
      workspaceId: workspaceId,
      workspaceGenesisHash: Uint8List.fromList(workspaceGenesisHash),
      inviteId: (ids ?? EntityIds()).next(),
      inviterDeviceId: inviterDeviceId,
      identityPublicKey: Uint8List.fromList(identityPublicKey),
      tlsCertificateSha256: Uint8List.fromList(tlsCertificateSha256),
      pairSecret: Uint8List.fromList(
        List<int>.generate(32, (_) => secureRandom.nextInt(256)),
      ),
      port: port,
      expiresAtMs: nowMs + lifetime.inMilliseconds,
      ipHints: List.unmodifiable(ipHints),
    );
  }

  bool isExpired(int nowMs) => nowMs >= expiresAtMs;

  String encode() {
    final bytes = DeterministicCbor.encode({
      'v': protocolVersion,
      'workspace_id': workspaceId,
      'workspace_genesis_hash': workspaceGenesisHash,
      'invite_id': inviteId,
      'inviter_device_id': inviterDeviceId,
      'identity_public_key': identityPublicKey,
      'tls_cert_sha256': tlsCertificateSha256,
      'pair_secret': pairSecret,
      'service': service,
      'port': port,
      'expires_at_ms': expiresAtMs,
      if (ipHints.isNotEmpty) 'ip_hints': ipHints,
    });
    return '$_prefix${base64Url.encode(bytes).replaceAll('=', '')}';
  }

  static PairingInvite decode(String value, {required int nowMs}) {
    if (!value.startsWith(_prefix) || value.length > 8192) {
      throw const FormatException('这不是研迹设备邀请');
    }
    final encoded = value.substring(_prefix.length);
    Uint8List bytes;
    try {
      bytes = base64Url.decode(base64Url.normalize(encoded));
    } on FormatException {
      throw const FormatException('邀请二维码已损坏');
    }
    final decoded = DeterministicCbor.decode(bytes);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('邀请内容格式错误');
    }
    const required = {
      'v',
      'workspace_id',
      'workspace_genesis_hash',
      'invite_id',
      'inviter_device_id',
      'identity_public_key',
      'tls_cert_sha256',
      'pair_secret',
      'service',
      'port',
      'expires_at_ms',
    };
    if (!decoded.keys.every({...required, 'ip_hints'}.contains) ||
        !required.every(decoded.containsKey) ||
        decoded['v'] != protocolVersion ||
        decoded['service'] != service) {
      throw const FormatException('不支持的邀请协议');
    }
    final rawHints = decoded['ip_hints'];
    if (rawHints != null &&
        (rawHints is! List<Object?> ||
            rawHints.any((item) => item is! String))) {
      throw const FormatException('邀请地址格式错误');
    }
    if (decoded['workspace_id'] is! String ||
        decoded['workspace_genesis_hash'] is! Uint8List ||
        decoded['invite_id'] is! String ||
        decoded['inviter_device_id'] is! String ||
        decoded['identity_public_key'] is! Uint8List ||
        decoded['tls_cert_sha256'] is! Uint8List ||
        decoded['pair_secret'] is! Uint8List ||
        decoded['port'] is! int ||
        decoded['expires_at_ms'] is! int) {
      throw const FormatException('邀请字段类型错误');
    }
    final invite = PairingInvite(
      workspaceId: decoded['workspace_id'] as String,
      workspaceGenesisHash: decoded['workspace_genesis_hash'] as Uint8List,
      inviteId: decoded['invite_id'] as String,
      inviterDeviceId: decoded['inviter_device_id'] as String,
      identityPublicKey: decoded['identity_public_key'] as Uint8List,
      tlsCertificateSha256: decoded['tls_cert_sha256'] as Uint8List,
      pairSecret: decoded['pair_secret'] as Uint8List,
      port: decoded['port'] as int,
      expiresAtMs: decoded['expires_at_ms'] as int,
      ipHints: rawHints == null
          ? const []
          : (rawHints as List<Object?>).cast<String>(),
    );
    if (invite.isExpired(nowMs)) {
      throw const FormatException('邀请已过期，请在另一台设备重新生成');
    }
    if (invite.expiresAtMs > nowMs + lifetime.inMilliseconds) {
      throw const FormatException('邀请有效期超过协议限制');
    }
    return invite;
  }

  Future<String> safetyCode(Uint8List joiningPublicKey) async {
    if (joiningPublicKey.length != 32) {
      throw ArgumentError('Invalid joining identity key');
    }
    final digest = await Sha256().hash([
      ...pairSecret,
      ...identityPublicKey,
      ...joiningPublicKey,
    ]);
    var value = 0;
    for (final byte in digest.bytes.take(4)) {
      value = (value << 8) | byte;
    }
    final digits = (value % 1000000).toString().padLeft(6, '0');
    return '${digits.substring(0, 3)} ${digits.substring(3)}';
  }

  void _validate() {
    if (!_uuid.hasMatch(workspaceId) ||
        !_uuid.hasMatch(inviteId) ||
        !_uuid.hasMatch(inviterDeviceId) ||
        workspaceGenesisHash.length != 32 ||
        identityPublicKey.length != 32 ||
        tlsCertificateSha256.length != 32 ||
        pairSecret.length != 32 ||
        port < 1 ||
        port > 65535 ||
        expiresAtMs < 1 ||
        ipHints.length > 8 ||
        ipHints.any((hint) => hint.isEmpty || hint.length > 64)) {
      throw const FormatException('临时配对口令字段不符合 YPP/2');
    }
  }
}

/// Stable YPP/2 device card. It contains no address, port, expiry, invitation
/// id, or secret, so it remains unchanged while the device identities do.
final class PairingCard {
  PairingCard({
    required this.workspaceId,
    required this.workspaceGenesisHash,
    required this.inviterDeviceId,
    required this.identityPublicKey,
    required this.tlsCertificateSha256,
  }) {
    if (!_uuid.hasMatch(workspaceId) ||
        !_uuid.hasMatch(inviterDeviceId) ||
        workspaceGenesisHash.length != 32 ||
        identityPublicKey.length != 32 ||
        tlsCertificateSha256.length != 32) {
      throw const FormatException('设备二维码字段不符合 YPP/2');
    }
  }

  static const _prefix = 'yanji://pair?v=2&data=';
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final String workspaceId;
  final Uint8List workspaceGenesisHash;
  final String inviterDeviceId;
  final Uint8List identityPublicKey;
  final Uint8List tlsCertificateSha256;

  String get deviceHint => crypto.sha256
      .convert([...utf8.encode(inviterDeviceId), ...identityPublicKey])
      .toString()
      .substring(0, 16);

  String encode() {
    final bytes = DeterministicCbor.encode({
      'v': PairingInvite.protocolVersion,
      'workspace_id': workspaceId,
      'workspace_genesis_hash': workspaceGenesisHash,
      'inviter_device_id': inviterDeviceId,
      'identity_public_key': identityPublicKey,
      'tls_cert_sha256': tlsCertificateSha256,
      'service': PairingInvite.service,
      'device_hint': deviceHint,
    });
    return '$_prefix${base64Url.encode(bytes).replaceAll('=', '')}';
  }

  static PairingCard decode(String value) {
    if (!value.startsWith(_prefix) || value.length > 4096) {
      throw const FormatException('这不是研迹 YPP/2 设备二维码');
    }
    Object? decoded;
    try {
      decoded = DeterministicCbor.decode(
        base64Url.decode(base64Url.normalize(value.substring(_prefix.length))),
      );
    } catch (_) {
      throw const FormatException('设备二维码已损坏');
    }
    if (decoded is! Map<String, Object?> ||
        decoded.length != 8 ||
        decoded['v'] != PairingInvite.protocolVersion ||
        decoded['service'] != PairingInvite.service ||
        decoded['workspace_id'] is! String ||
        decoded['workspace_genesis_hash'] is! Uint8List ||
        decoded['inviter_device_id'] is! String ||
        decoded['identity_public_key'] is! Uint8List ||
        decoded['tls_cert_sha256'] is! Uint8List ||
        decoded['device_hint'] is! String) {
      throw const FormatException('设备二维码格式错误');
    }
    final card = PairingCard(
      workspaceId: decoded['workspace_id']! as String,
      workspaceGenesisHash: decoded['workspace_genesis_hash']! as Uint8List,
      inviterDeviceId: decoded['inviter_device_id']! as String,
      identityPublicKey: decoded['identity_public_key']! as Uint8List,
      tlsCertificateSha256: decoded['tls_cert_sha256']! as Uint8List,
    );
    if (decoded['device_hint'] != card.deviceHint) {
      throw const FormatException('设备二维码身份摘要不一致');
    }
    return card;
  }

  bool matches(PairingInvite invite) =>
      workspaceId == invite.workspaceId &&
      inviterDeviceId == invite.inviterDeviceId &&
      _same(workspaceGenesisHash, invite.workspaceGenesisHash) &&
      _same(identityPublicKey, invite.identityPublicKey) &&
      _same(tlsCertificateSha256, invite.tlsCertificateSha256);

  static bool _same(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}

/// Owns the one-time nature of a locally generated invitation.
final class PairingInvitationSession {
  PairingInvitationSession(this.invite);
  final PairingInvite invite;
  bool _consumed = false;
  bool get consumed => _consumed;

  bool consume({
    required String inviteId,
    required Uint8List pairSecret,
    required int nowMs,
  }) {
    if (_consumed || invite.isExpired(nowMs) || invite.inviteId != inviteId) {
      return false;
    }
    var difference = pairSecret.length ^ invite.pairSecret.length;
    for (
      var i = 0;
      i < pairSecret.length && i < invite.pairSecret.length;
      i++
    ) {
      difference |= pairSecret[i] ^ invite.pairSecret[i];
    }
    if (difference != 0) return false;
    _consumed = true;
    return true;
  }
}
