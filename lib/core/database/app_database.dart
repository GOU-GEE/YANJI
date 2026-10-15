import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    // Never silently drop user data on an unsupported upgrade or downgrade.
    onUpgrade: (migrator, from, to) async {
      if (from < 1 || to != 5) {
        throw StateError('No migration registered from $from to $to');
      }
      if (from < 2) {
        await migrator.addColumn(subjects, subjects.parentSubjectId);
      }
      if (from < 3) await migrator.addColumn(tasks, tasks.repeatDaily);
      if (from < 4) await migrator.createTable(localStudyCheckpoints);
      if (from < 5) await migrator.createTable(localWorkspaceSelection);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA recursive_triggers = ON');
    },
  );
}
