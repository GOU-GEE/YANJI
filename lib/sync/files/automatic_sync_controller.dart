import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../application/study_app_controller.dart';
import '../pairing/device_pairing_coordinator.dart';
import 'file_sync_engine.dart';
import 'operation_file_exchange.dart';

/// One serialized worker handles automatic and manual attempts. Its durable
/// source is the app's committed operation log, not timers or RAM queues.
class AutomaticSyncController extends ChangeNotifier {
  AutomaticSyncController({
    required this.app,
    required this.directory,
    required this.pairing,
    FileSyncEngine? engine,
  }) : engine = engine ?? EmbeddedSyncthingEngine() {
    exchange = OperationFileExchange(app, directory);
  }
  final StudyAppController app;
  final Directory directory;
  final DevicePairingCoordinator pairing;
  final FileSyncEngine engine;
  late OperationFileExchange exchange;
  List<PeerSyncProgress> peers = [];
  String? error;
  bool syncing = false;
  bool _closed = false, _started = false;
  Timer? _periodic, _debounce;
  Future<void>? _cycle;
  String? _configurationKey;
  String? _workspaceKey;
  DateTime? _backupAt;
  int _lastRevision = -1;
  int _manualRequests = 0;
  String? _visibleState;

  int get pending => peers.fold(0, (n, p) => n + p.pending);
  bool get complete =>
      peers.isNotEmpty && peers.every((p) => p.confirmed && p.pending == 0);
  String get message {
    if (peers.isEmpty) return '本机记录已保存，配对设备后可自动同步';
    if (_manualRequests > 0) return '正在同步，记录已保存在本机';
    if (error != null) return '本机记录已保存，同步暂未完成';
    if (complete) return '已同步到全部 ${peers.length} 台设备';
    final done = peers.where((p) => p.confirmed && p.pending == 0).length;
    return '已同步 $done/${peers.length} 台设备，仍有记录待同步';
  }

  void start() {
    if (_closed || _periodic != null) return;
    app.addListener(_onChanged);
    _periodic ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(tick()),
    );
    unawaited(tick());
  }

  void _onChanged() {
    if (_closed ||
        app.busy ||
        _debounce != null ||
        app.applier.revision == _lastRevision) {
      return;
    }
    _lastRevision = app.applier.revision;
    _debounce = Timer(const Duration(milliseconds: 700), () {
      _debounce = null;
      unawaited(tick());
    });
  }

  Future<void> tick() {
    if (_closed) return Future.value();
    return _cycle ??= _runCycle().whenComplete(() => _cycle = null);
  }

  Future<void> _runCycle() async {
    if (app.workspace == null || app.busy) return;
    syncing = true;
    try {
      final workspace = app.workspace!.id;
      if (_workspaceKey != workspace) {
        if (_started) {
          await engine.close();
          _started = false;
        }
        _configurationKey = null;
        _backupAt = null;
        _workspaceKey = workspace;
        exchange = OperationFileExchange(
          app,
          Directory(p.join(directory.path, 'workspaces', workspace)),
        );
      }
      final rawPeers = pairing.transportPeers;
      // Unpaired installations stay fully local. No public discovery traffic.
      if (rawPeers.isEmpty) {
        if (_started) {
          await engine.close();
          _started = false;
          _configurationKey = null;
        }
        peers = [];
        error = null;
        await _backupIfNeeded();
        return;
      }
      await app.ensureWorkspaceGenesis();
      peers = await exchange.progress();
      await exchange.publish();
      await _backupIfNeeded();
      final configuration = <String, Object?>{
        'directory': p.join(directory.path, 'engine', workspace),
        'folder_path': exchange.records.path,
        'workspace': app.workspace!.id,
        'peers': rawPeers,
      };
      if (!_started) {
        await engine.start({
          ...configuration,
          'certificate': pairing.tlsIdentity.certificatePem,
          'private_key': pairing.tlsIdentity.privateKeyPem,
        });
        _started = true;
      }
      final key = jsonEncode(configuration);
      if (_configurationKey != key) {
        await engine.configure(configuration);
        _configurationKey = key;
      }
      await exchange.receive();
      await exchange.publish();
      await engine.scan();
      peers = await exchange.progress(connected: await engine.connected());
      error = exchange.lastImportError;
    } catch (e) {
      error = '同步暂未完成：$e';
      peers = await exchange.progress();
    } finally {
      syncing = false;
      _lastRevision = app.applier.revision;
      _notifyIfChanged();
    }
  }

  Future<void> _backupIfNeeded() async {
    final marker = File(p.join(exchange.directory.path, 'last-backup.json'));
    if (_backupAt == null && await marker.exists()) {
      try {
        final raw = jsonDecode(await marker.readAsString()) as Map;
        _backupAt = DateTime.fromMillisecondsSinceEpoch(raw['at'] as int);
        if (!await Directory(raw['path'] as String).exists()) _backupAt = null;
      } catch (_) {
        _backupAt = null;
      }
    }
    if (_backupAt != null &&
        DateTime.now().difference(_backupAt!) < const Duration(hours: 24)) {
      return;
    }
    final backup = await exchange.backup();
    _backupAt = DateTime.now();
    await OperationFileExchange.atomicWrite(
      marker,
      utf8.encode(
        jsonEncode({
          'at': _backupAt!.millisecondsSinceEpoch,
          'path': backup.path,
        }),
      ),
    );
  }

  Future<void> syncNow({Duration timeout = const Duration(seconds: 30)}) async {
    _manualRequests++;
    _notifyIfChanged();
    try {
      await _syncNow(timeout);
    } finally {
      _manualRequests--;
      _notifyIfChanged();
    }
  }

  void _notifyIfChanged() {
    final state = jsonEncode([
      message,
      error,
      for (final peer in peers)
        [
          peer.deviceId,
          peer.name,
          peer.pending,
          peer.confirmed,
          peer.connected,
        ],
    ]);
    if (_closed || state == _visibleState) return;
    _visibleState = state;
    notifyListeners();
  }

  Future<void> _syncNow(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    await tick();
    if (peers.isEmpty) throw StateError('暂无已配对设备');
    while (!complete && DateTime.now().isBefore(deadline) && !_closed) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await tick();
    }
    if (!complete || error != null) {
      throw StateError('本机记录已保存，仍有设备未确认同步。请保持双端应用打开，再点击同步等待。');
    }
  }

  /// Called before the OS suspends the app. Pending history stays durable even
  /// when the OS gives no additional background execution time.
  Future<void> background() async {
    await tick();
  }

  Future<void> foreground() => tick();

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    app.removeListener(_onChanged);
    _periodic?.cancel();
    _debounce?.cancel();
    await _cycle;
    if (_started) await engine.close();
    dispose();
  }
}
