import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import '../platform/app_support_directory.dart';

/// A single background database owner keeps SQLite work off the UI isolate.
/// Opening is lazy so startup and pure widget tests need no platform channel.
QueryExecutor openAppDatabase() => LazyDatabase(() async {
  final directory = await getAppSupportDirectory();
  await directory.create(recursive: true);
  return openDatabaseFile(File(p.join(directory.path, 'yanji.sqlite')));
});

QueryExecutor openDatabaseFile(File file) => NativeDatabase.createInBackground(
  file,
  setup: (database) {
    database.execute('PRAGMA journal_mode = WAL');
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('PRAGMA synchronous = FULL');
    database.execute('PRAGMA recursive_triggers = ON');
    database.execute('PRAGMA busy_timeout = 5000');
  },
);
