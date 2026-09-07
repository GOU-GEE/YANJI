import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

import '../../core/crypto/device_identity.dart';
import '../../core/crypto/operation_crypto.dart';
import '../../core/database/app_database.dart';
import '../oplog/operation.dart';
import '../oplog/operation_journal.dart';
import '../protocol/deterministic_cbor.dart';

final class TrustedPeer {
  TrustedPeer({
    required this.deviceId,
    required this.publicKey,
    required this.deviceName,
    required this.platform,
    required this.tlsCertificateSha256,
    required this.pairedAtMs,
    this.cutoff,
  });
  final String deviceId;
  final SimplePublicKey publicKey;
  final String deviceName;
  final String platform;
  final Uint8List tlsCertificateSha256;
  final int pairedAtMs;
  final int? cutoff;
  bool get active => cutoff == null;
}

/// Rebuilds the membership decision from signed workspace.genesis,
/// device.add, and device.revoke operations. SQLite rows are never treated as
/// authority by themselves.
final class TrustChain {
  TrustChain(this.database, this.localIdentity);
  final AppDatabase database;
  final DeviceIdentity localIdentity;
  final _crypto = OperationCrypto();
  final _policies = <String, Map<String, OriginPolicy>>{};
  final _peers = <String, Map<String, TrustedPeer>>{};

  Future<OriginPolicy?> lookup(String workspaceId, String deviceId) async {
    final cached = _policies[workspaceId]?[deviceId];
    if (cached != null) return cached;
    final exists = await database
        .customSelect(
          'SELECT created_by_device_id FROM workspaces WHERE id=?',
          variables: [Variable(workspaceId)],
        )
        .getSingleOrNull();
    if (deviceId == localIdentity.deviceId &&
        (exists == null ||
            exists.read<String>('created_by_device_id') ==
                localIdentity.deviceId)) {
      return OriginPolicy(publicKey: localIdentity.publicKey, authorized: true);
    }
    return null;
  }

  List<TrustedPeer> peers(String workspaceId) =>
      List.unmodifiable(_peers[workspaceId]?.values ?? const []);

  void anchorRoot(
    String workspaceId,
    String deviceId,
    SimplePublicKey publicKey,
  ) {
    _policies[workspaceId] = {
      deviceId: OriginPolicy(publicKey: publicKey, authorized: true),
    };
  }

  Future<void> reload(String workspaceId) async {
    final workspace = await database
        .customSelect(
          'SELECT created_by_device_id, created_at_ms FROM workspaces WHERE id=?',
          variables: [Variable(workspaceId)],
        )
        .getSingleOrNull();
    if (workspace == null) return;
    final creator = workspace.read<String>('created_by_device_id');
    final rows = await database
        .customSelect(
          "SELECT envelope_bytes, signature FROM oplog WHERE workspace_id=? AND entity_type='device' ORDER BY hlc_wall_ms, hlc_counter, origin_device_id, origin_seq",
          variables: [Variable(workspaceId)],
        )
        .get();
    final operations = [
      for (final row in rows)
        Operation(
          envelopeBytes: row.read<Uint8List>('envelope_bytes'),
          signature: row.read<Uint8List>('signature'),
        ),
    ];
    final policies = <String, OriginPolicy>{};
    final peers = <String, TrustedPeer>{};
    for (final packet in operations) {
      final envelope = packet.parse();
      final payload = envelope.payload! as Map<String, Object?>;
      if (payload['type'] != 'workspace.genesis') continue;
      final rootId = payload['root_device_id']! as String;
      final rootKey = SimplePublicKey(
        payload['root_device_public_key']! as Uint8List,
        type: KeyPairType.ed25519,
      );
      if (rootId != creator ||
          envelope.originDeviceId != rootId ||
          !await _crypto.verify(packet, rootKey)) {
        continue;
      }
      policies[rootId] = OriginPolicy(publicKey: rootKey, authorized: true);
      peers[rootId] = TrustedPeer(
        deviceId: rootId,
        publicKey: rootKey,
        deviceName: rootId == localIdentity.deviceId ? '本机' : '主设备',
        platform: '',
        tlsCertificateSha256: Uint8List(32),
        pairedAtMs: payload['created_at_ms']! as int,
      );
      break;
    }
    // Existing single-device databases predate the networking milestone. Only
    // their recorded creator may bootstrap the first signed genesis operation.
    if (policies.isEmpty && creator == localIdentity.deviceId) {
      policies[creator] = OriginPolicy(
        publicKey: localIdentity.publicKey,
        authorized: true,
      );
      peers[creator] = TrustedPeer(
        deviceId: creator,
        publicKey: localIdentity.publicKey,
        deviceName: '本机',
        platform: '',
        tlsCertificateSha256: Uint8List(32),
        pairedAtMs: workspace.read<int>('created_at_ms'),
      );
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (final packet in operations) {
        final envelope = packet.parse();
        final payload = envelope.payload! as Map<String, Object?>;
        if (payload['type'] != 'device.add') continue;
        final issuer = policies[envelope.originDeviceId];
        if (issuer == null || !issuer.permits(envelope.originSeq)) continue;
        if (!await _crypto.verify(packet, issuer.publicKey)) continue;
        final id = payload['device_id']! as String;
        final key = SimplePublicKey(
          payload['identity_public_key']! as Uint8List,
          type: KeyPairType.ed25519,
        );
        final existing = policies[id];
        if (existing != null) {
          if (DeterministicCbor.compareBytes(
                existing.publicKey.bytes,
                key.bytes,
              ) !=
              0) {
            continue;
          }
        } else {
          policies[id] = OriginPolicy(publicKey: key, authorized: true);
          changed = true;
        }
        peers[id] = TrustedPeer(
          deviceId: id,
          publicKey: key,
          deviceName: payload['device_name']! as String,
          platform: payload['platform']! as String,
          tlsCertificateSha256: payload['tls_cert_sha256']! as Uint8List,
          pairedAtMs: payload['paired_at_ms']! as int,
          cutoff: policies[id]!.cutoff,
        );
      }
    }
    for (final packet in operations) {
      final envelope = packet.parse();
      final payload = envelope.payload! as Map<String, Object?>;
      if (payload['type'] != 'device.revoke') continue;
      final issuer = policies[envelope.originDeviceId];
      if (issuer == null || !issuer.permits(envelope.originSeq)) continue;
      if (!await _crypto.verify(packet, issuer.publicKey)) continue;
      final id = payload['target_device_id']! as String;
      final existing = policies[id];
      if (existing == null) continue;
      final requested = payload['max_allowed_origin_seq']! as int;
      final cutoff = existing.cutoff == null
          ? requested
          : requested < existing.cutoff!
          ? requested
          : existing.cutoff!;
      policies[id] = OriginPolicy(
        publicKey: existing.publicKey,
        authorized: true,
        cutoff: cutoff,
      );
      final peer = peers[id]!;
      peers[id] = TrustedPeer(
        deviceId: peer.deviceId,
        publicKey: peer.publicKey,
        deviceName: peer.deviceName,
        platform: peer.platform,
        tlsCertificateSha256: peer.tlsCertificateSha256,
        pairedAtMs: peer.pairedAtMs,
        cutoff: cutoff,
      );
    }
    _policies[workspaceId] = policies;
    _peers[workspaceId] = peers;
  }
}
