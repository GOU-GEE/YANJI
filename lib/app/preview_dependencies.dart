import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../core/platform/app_support_directory.dart';

import '../application/study_app_controller.dart';
import '../core/crypto/device_identity.dart';
import '../core/database/app_database.dart';
import '../core/database/connection.dart';
import '../core/storage/platform_key_storage.dart';
import 'dependencies.dart';

/// Opt-in simulator preview; persists separately from the user's database.
List<Override> previewOverrides() => [
  databaseProvider.overrideWith((ref) {
    final db = AppDatabase(
      LazyDatabase(() async {
        final directory = await getAppSupportDirectory();
        return openDatabaseFile(
          File(p.join(directory.path, 'yanji_preview.sqlite')),
        );
      }),
    );
    ref.onDispose(() => unawaited(db.close()));
    return db;
  }),
  appControllerProvider.overrideWith((ref) async {
    DateTime? seedTime;
    final app = await StudyAppController.open(
      ref.watch(databaseProvider),
      await IdentityService(PlatformKeyStorage()).loadOrCreate(),
      now: () => seedTime ?? DateTime.now(),
    );
    ref.onDispose(app.dispose);
    if (app.workspace != null) {
      // Keep the persistent simulator preview useful after the calendar day
      // changes, without altering or duplicating its existing records.
      if (!app.tasks.any((task) => task.scheduledDate == app.today)) {
        final children = app.subjects
            .where((subject) => subject.parentSubjectId != null)
            .toList();
        if (children.isNotEmpty) {
          for (var i = 0; i < 6; i++) {
            await app.saveTask(
              title: '${['复习知识点', '整理错题', '完成专项练习'][i % 3]} ${i + 1}',
              subjectId: children[i % children.length].id,
              date: app.today,
              estimatedSeconds: 1800,
              priority: i % 3,
            );
          }
        }
      }
      return app;
    }
    await app.onboard(
      name: '2028 考研',
      date: '2028-12-23',
      subjectNames: ['数学', '英语', '政治'],
    );
    final roots = List.of(app.subjects);
    for (var i = 0; i < roots.length; i++) {
      await app.saveSubject(
        name: ['高等数学', '阅读理解', '马克思主义原理'][i],
        parentId: roots[i].id,
      );
    }
    final children = app.subjects
        .where((s) => s.parentSubjectId != null)
        .toList();
    for (var i = 0; i < 18; i++) {
      await app.saveTask(
        title: '${['复习知识点', '整理错题', '完成专项练习'][i % 3]} ${i + 1}',
        subjectId: children[i % 3].id,
        date: app.today,
        estimatedSeconds: 1800,
        priority: i % 3,
        repeatDaily: i < 3,
      );
    }
    // Keep a mix of completed, daily and ordinary rows for motion previews.
    for (final index in [1, 7, 13]) {
      final task = app.tasks.firstWhere((task) => task.title == '复习知识点 $index');
      await app.setTaskStatus(task, 'completed');
    }
    final today = DateTime.now();
    for (var day = 13; day >= 0; day--) {
      for (var i = 0; i < 3; i++) {
        seedTime = DateTime(
          today.year,
          today.month,
          today.day - day,
          8 + i * 2,
        );
        await app.startStudy(children[i].id);
        seedTime = seedTime.add(
          Duration(minutes: 25 + (day * 7 + i * 13) % 55),
        );
        await app.stopStudy();
      }
    }
    seedTime = null;
    await app.refresh();
    return app;
  }),
];
