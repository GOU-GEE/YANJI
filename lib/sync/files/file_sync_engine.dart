import 'package:yanji_syncthing/yanji_syncthing.dart';

abstract interface class FileSyncEngine {
  Future<void> start(Map<String, Object?> configuration);
  Future<void> configure(Map<String, Object?> configuration);
  Future<void> scan();
  Future<Set<String>> connected();
  Future<void> close();
}

class EmbeddedSyncthingEngine implements FileSyncEngine {
  final _native = YanjiSyncthing();
  @override
  Future<void> start(Map<String, Object?> configuration) async {
    await _native.execute({...configuration, 'command': 'start'});
  }

  @override
  Future<void> configure(Map<String, Object?> configuration) async {
    await _native.execute({...configuration, 'command': 'configure'});
  }

  @override
  Future<void> scan() async {
    await _native.execute({'command': 'scan'});
  }

  @override
  Future<Set<String>> connected() async =>
      ((await _native.execute({'command': 'status'}))['connected'] as List)
          .cast<String>()
          .toSet();
  @override
  Future<void> close() async {
    await _native.execute({'command': 'stop'});
  }
}
