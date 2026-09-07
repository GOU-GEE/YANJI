import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../application/study_app_controller.dart';
import '../core/crypto/device_identity.dart';
import '../core/storage/platform_key_storage.dart';
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

final appControllerProvider = FutureProvider<StudyAppController>((ref) async {
  final database = ref.watch(databaseProvider);
  final identity = await IdentityService(PlatformKeyStorage()).loadOrCreate();
  final controller = await StudyAppController.open(
    database,
    identity,
    ids: ref.watch(entityIdsProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
