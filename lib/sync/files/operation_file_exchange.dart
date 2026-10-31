import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

import '../../application/study_app_controller.dart';
import '../oplog/operation.dart';
import '../oplog/operation_journal.dart';
import '../protocol/deterministic_cbor.dart';

class PeerSyncProgress {
  const PeerSyncProgress({
    required this.deviceId,
    required this.name,
    required this.pending,
    required this.confirmed,
    this.connected = false,
    this.pendingKnown = true,
  });
  final String deviceId, name;
  final int pending;
  final bool confirmed, connected, pendingKnown;
}

/// Syncthing owns only the exchange directory. Its file deletions never delete
/// app records. Private receipt state and recovery backups live outside it.
class OperationFileExchange {
  OperationFileExchange(this.app, this.directory);
  final StudyAppController app;
  final Directory directory;
  Directory get records => Directory(p.join(directory.path, 'records'));
  File get _stateFile => File(p.join(directory.path, 'receipt-state.json'));
  final _receipts = <String, Map<String, int>>{};
  final _imported = <String>{};
  final _signedReceipts = <String, Uint8List>{};
  bool _loaded = false;
  int _exportRevision = -1;
  String? _exportWorkspace;
  List<Operation> _exported = [];
  List<(String, int)> _positions = [];
  Map<String, int> _frontier = {};
  final _fileStamps = <String, (int, int)>{};
  final _encoded = <String, Uint8List>{};

  Future<List<Operation>> _operations(String workspace) async {
    if (_exportRevision != app.applier.revision ||
        _exportWorkspace != workspace) {
      final revision = app.applier.revision;
      _exported = await app.applier.export(workspace);
      _exportRevision = revision;
      _exportWorkspace = workspace;
      _positions = [
        for (final op in _exported)
          (op.parse().originDeviceId, op.parse().originSeq),
      ];
      final sequences = <String, Set<int>>{};
      for (final position in _positions) {
        (sequences[position.$1] ??= {}).add(position.$2);
      }
      _frontier = {};
      for (final entry in sequences.entries) {
        var contiguous = 0;
        while (entry.value.contains(contiguous + 1)) {
          contiguous++;
        }
        _frontier[entry.key] = contiguous;
      }
    }
    return _exported;
  }

  static (int, int) _stamp(FileStat stat) =>
      (stat.size, stat.modified.microsecondsSinceEpoch);
  String? lastImportError;

  Future<void> _load() async {
    if (_loaded) return;
    await records.create(recursive: true);
    if (await _stateFile.exists()) {
      try {
        final state =
            jsonDecode(await _stateFile.readAsString()) as Map<String, dynamic>;
        final workspace = app.workspace;
        if (workspace != null) {
          for (final encoded in (state['receipts'] as List).cast<String>()) {
            await _readReceipt(base64Decode(encoded), workspace.id);
          }
        }
        // Imported-file hints are rebuilt from the actual committed database,
        // never loaded from a cache that could outlive a database restore.
      } catch (_) {
        _receipts.clear();
        _signedReceipts.clear();
      }
    }
    _loaded = true;
  }

  static Future<void> atomicWrite(File destination, List<int> bytes) async {
    final temporary = File('${destination.path}.partial');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(destination.path);
  }

  Future<bool> publish() async {
    await _load();
    final workspace = app.workspace;
    if (workspace == null) return false;
    var changed = false;
    for (final op in await _operations(workspace.id)) {
      final body = _encoded.putIfAbsent(
        op.parse().opId,
        () => DeterministicCbor.encode({
          'type': 'yanji.operation.v1',
          'workspace': workspace.id,
          'envelope': op.envelopeBytes,
          'signature': op.signature,
        }),
      );
      final digest = crypto.sha256.convert(body).toString();
      final file = File(p.join(records.path, '$digest.op'));
      // Recheck changed transport files, without hashing unchanged history on
      // the UI isolate every time the synchronization worker wakes up.
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file ||
          (_fileStamps[file.path] != _stamp(stat) &&
              crypto.sha256.convert(await file.readAsBytes()).toString() !=
                  digest)) {
        await atomicWrite(file, body);
        changed = true;
      }
      _fileStamps[file.path] = _stamp(await file.stat());
      _imported.add(digest);
    }
    final body = DeterministicCbor.encode({
      'type': 'yanji.receipt.v1',
      'workspace': workspace.id,
      'device': app.identity.deviceId,
      'frontier': _frontier,
    });
    final signed = DeterministicCbor.encode({
      'body': body,
      'signature': (await app.identity.sign(body)).bytes,
    });
    final file = File(
      p.join(records.path, '${crypto.sha256.convert(signed)}.ack'),
    );
    if (!await file.exists()) {
      await atomicWrite(file, signed);
      changed = true;
    }
    await _saveState();
    return changed;
  }

  Future<int> receive() async {
    await _load();
    final workspace = app.workspace;
    if (workspace == null) return 0;
    lastImportError = null;
    var received = 0;
    var authorizationChanged = false;
    final files = await records
        .list(followLinks: false)
        .where(
          (entity) =>
              entity is File &&
              (entity.path.endsWith('.op') || entity.path.endsWith('.ack')),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      try {
        final hint = p.basenameWithoutExtension(file.path);
        final stat = await file.stat();
        if ((_imported.contains(hint) || _signedReceipts.containsKey(hint)) &&
            _fileStamps[file.path] == _stamp(stat)) {
          continue;
        }
        if (await file.length() > DeterministicCbor.maxBytes) {
          throw const FormatException('同步文件超过大小限制');
        }
        final bytes = await file.readAsBytes();
        final digest = crypto.sha256.convert(bytes).toString();
        if (p.basenameWithoutExtension(file.path) != digest) {
          throw const FormatException('同步文件完整性校验失败');
        }
        if (file.path.endsWith('.ack')) {
          await _readReceipt(bytes, workspace.id);
          if (_signedReceipts.containsKey(digest)) {
            _fileStamps[file.path] = _stamp(stat);
          }
          continue;
        }
        if (_imported.contains(digest)) {
          _fileStamps[file.path] = _stamp(stat);
          continue;
        }
        final raw = DeterministicCbor.decode(bytes);
        if (raw is! Map<String, Object?> ||
            raw['type'] != 'yanji.operation.v1' ||
            raw['workspace'] != workspace.id ||
            raw['envelope'] is! Uint8List ||
            raw['signature'] is! Uint8List) {
          throw const FormatException('同步记录格式无效');
        }
        final op = Operation(
          envelopeBytes: raw['envelope']! as Uint8List,
          signature: raw['signature']! as Uint8List,
        );
        final packet = op.parse();
        final result = await app.applier.receive(
          op,
          workspaceId: workspace.id,
          originDeviceId: packet.originDeviceId,
        );
        if (result == ReceiveResult.rejected) {
          throw const FormatException('同步记录未通过身份或内容校验');
        }
        // The applier resolves only after database COMMIT. A crash before this
        // cache is saved replays the same signed operation and deduplicates it.
        _imported.add(digest);
        _fileStamps[file.path] = _stamp(stat);
        if (result == ReceiveResult.stored) received++;
        if (result != ReceiveResult.duplicate) authorizationChanged = true;
        if (packet.entityType == 'device') {
          await app.trust.reload(workspace.id);
          await app.applier.refreshAuthorization(workspace.id);
        }
      } catch (error) {
        lastImportError = '部分同步记录尚未导入：$error';
        // Isolate malformed/incomplete files; valid records keep progressing.
      }
    }
    if (authorizationChanged) {
      await app.trust.reload(workspace.id);
      await app.applier.refreshAuthorization(workspace.id);
    }
    if (received > 0) await app.refresh();
    await _saveState();
    return received;
  }

  Future<void> _readReceipt(Uint8List bytes, String workspace) async {
    final digest = crypto.sha256.convert(bytes).toString();
    if (_signedReceipts.containsKey(digest)) return;
    final raw = DeterministicCbor.decode(bytes);
    if (raw is! Map<String, Object?> ||
        raw['body'] is! Uint8List ||
        raw['signature'] is! Uint8List) {
      throw const FormatException('同步确认无效');
    }
    final bodyBytes = raw['body']! as Uint8List;
    final body = DeterministicCbor.decode(bodyBytes);
    if (body is! Map<String, Object?> ||
        body['type'] != 'yanji.receipt.v1' ||
        body['workspace'] != workspace ||
        body['device'] is! String ||
        body['frontier'] is! Map<String, Object?>) {
      throw const FormatException('同步确认无效');
    }
    final id = body['device']! as String;
    final peer = app.trustedPeers
        .where((p) => p.deviceId == id && p.active)
        .firstOrNull;
    if (peer == null) {
      return; // Revoked/unknown receipts cannot confirm delivery.
    }
    if (!await Ed25519().verify(
      bodyBytes,
      signature: Signature(
        raw['signature']! as Uint8List,
        publicKey: peer.publicKey,
      ),
    )) {
      throw const FormatException('同步确认身份校验失败');
    }
    final frontier = body['frontier']! as Map<String, Object?>;
    if (frontier.values.any((v) => v is! int || v < 0)) {
      throw const FormatException('同步确认序号无效');
    }
    _signedReceipts[digest] = Uint8List.fromList(bytes);
    final previous = _receipts.putIfAbsent(id, () => {});
    for (final entry in frontier.entries) {
      final seq = entry.value! as int;
      if (seq > (previous[entry.key] ?? 0)) previous[entry.key] = seq;
    }
  }

  Future<List<PeerSyncProgress>> progress({
    Set<String> connected = const {},
  }) async {
    await _load();
    final workspace = app.workspace;
    if (workspace == null) return [];
    await _operations(workspace.id);
    return [
      for (final peer in app.trustedPeers)
        if (peer.active && peer.deviceId != app.identity.deviceId)
          PeerSyncProgress(
            deviceId: peer.deviceId,
            name: peer.deviceName,
            pending: _positions
                .where(
                  (position) =>
                      position.$2 >
                      (_receipts[peer.deviceId]?[position.$1] ?? 0),
                )
                .length,
            confirmed: _receipts.containsKey(peer.deviceId),
            connected: connected.contains(peer.deviceId),
          ),
    ];
  }

  Future<void> _saveState() => atomicWrite(
    _stateFile,
    utf8.encode(
      jsonEncode({
        'version': 1,
        'receipts': _signedReceipts.values.map(base64Encode).toList(),
      }),
    ),
  );

  /// A consistent, independent recovery archive; never replicated or deleted
  /// by Syncthing. It contains signed history, never installation private keys.
  Future<Directory> backup() async {
    final workspace = app.workspace ?? (throw StateError('尚未创建学习空间'));
    final root = Directory(p.join(directory.path, 'backups'));
    await root.create(recursive: true);
    final name = '${DateTime.now().microsecondsSinceEpoch}.yanji-backup';
    final temporary = Directory(p.join(root.path, '$name.partial'));
    await temporary.create();
    final ops = await app.applier.export(workspace.id);
    final hashes = <String>[];
    // Per-record files keep backups valid even when history exceeds the CBOR
    // per-message limit. The directory is published only after all files flush.
    for (final op in ops) {
      final body = DeterministicCbor.encode({
        'type': 'yanji.operation.v1',
        'workspace': workspace.id,
        'envelope': op.envelopeBytes,
        'signature': op.signature,
      });
      final hash = crypto.sha256.convert(body).toString();
      hashes.add(hash);
      await atomicWrite(File(p.join(temporary.path, '$hash.op')), body);
    }
    final manifest = utf8.encode(
      jsonEncode({
        'type': 'yanji.backup.v1',
        'workspace': workspace.id,
        'device': app.identity.deviceId,
        'files': hashes,
      }),
    );
    await atomicWrite(File(p.join(temporary.path, 'manifest.json')), manifest);
    return temporary.rename(p.join(root.path, name));
  }

  /// Restore history into an already authorized installation in this workspace.
  /// Identity recovery is intentionally separate: archives contain no secrets.
  Future<int> restoreBackup(Directory backup) async {
    await _load();
    final workspace = app.workspace ?? (throw StateError('请先恢复或配对学习空间'));
    final manifest = jsonDecode(
      await File(p.join(backup.path, 'manifest.json')).readAsString(),
    );
    if (manifest is! Map ||
        manifest['type'] != 'yanji.backup.v1' ||
        manifest['workspace'] != workspace.id ||
        manifest['files'] is! List) {
      throw const FormatException('备份不属于当前学习空间');
    }
    final hashes = (manifest['files'] as List).cast<String>();
    // Validate the complete archive before publishing any of its records.
    for (final hash in hashes) {
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
        throw const FormatException('备份文件名无效');
      }
      final file = File(p.join(backup.path, '$hash.op'));
      if (await file.length() > DeterministicCbor.maxBytes ||
          crypto.sha256.convert(await file.readAsBytes()).toString() != hash) {
        throw const FormatException('备份文件不完整');
      }
    }
    for (final hash in hashes) {
      await atomicWrite(
        File(p.join(records.path, '$hash.op')),
        await File(p.join(backup.path, '$hash.op')).readAsBytes(),
      );
    }
    final restored = await receive();
    await publish();
    if (lastImportError != null) throw StateError(lastImportError!);
    return restored;
  }
}
