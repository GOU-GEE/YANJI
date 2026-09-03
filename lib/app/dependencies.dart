import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/database/connection.dart';
import '../core/ids/entity_ids.dart';

// Application composition root. Features will depend on repository providers,
// not access this database provider from presentation widgets.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(openAppDatabase());
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final entityIdsProvider = Provider<EntityIds>((ref) => EntityIds());
