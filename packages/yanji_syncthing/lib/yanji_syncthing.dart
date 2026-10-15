import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Native calls run on serial worker queues, never the platform's UI thread.
class YanjiSyncthing {
  static const _channel = MethodChannel('yanji/syncthing');
  Process? _process;
  StreamIterator<String>? _responses;
  Future<void> _queue = Future.value();

  Future<Map<String, dynamic>> execute(Map<String, Object?> request) {
    if (!Platform.isWindows) return _invoke(request);
    final result = _queue.then((_) => _invoke(request));
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Map<String, dynamic>> _invoke(Map<String, Object?> request) async {
    String? result;
    if (Platform.isWindows) {
      if (_process == null) {
        if (request['command'] == 'stop') return {};
        final directory = Directory(request['directory']! as String);
        await directory.create(recursive: true);
        final executable = File('${directory.path}/yanji-sync.exe');
        final bytes = await rootBundle.load(
          'packages/yanji_syncthing/native/build/sync-harness-windows-amd64.exe',
        );
        await executable.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
        _process = await Process.start(executable.path, const []);
        // Native diagnostic output must not block its pipe or expose secrets.
        unawaited(_process!.stderr.drain<void>());
        _responses = StreamIterator(
          _process!.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter()),
        );
      }
      _process!.stdin.writeln(jsonEncode(request));
      await _process!.stdin.flush();
      if (!await _responses!.moveNext()) {
        await _discardProcess();
        throw StateError('同步引擎已退出，下次同步会重新连接');
      }
      result = _responses!.current;
      if (request['command'] == 'stop') await _discardProcess();
    } else {
      result = await _channel.invokeMethod<String>(
        'execute',
        jsonEncode(request),
      );
    }
    if (result == null) throw StateError('同步引擎没有返回结果');
    final decoded = jsonDecode(result) as Map<String, dynamic>;
    if (decoded['error'] != null) throw StateError(decoded['error'] as String);
    return decoded;
  }

  Future<void> _discardProcess() async {
    final process = _process;
    _process = null;
    await _responses?.cancel();
    _responses = null;
    await process?.stdin.close();
    if (process != null) {
      await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
    }
  }
}
