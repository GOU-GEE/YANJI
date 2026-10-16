// Disposable emulator only. First run waits for force-stop; second run asserts
// WAL and checkpoint recovery without closing the SQLite connection normally.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/core/storage/platform_key_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'HarmonyOS force-stop recovers only checkpointed study time',
    (_) async {
      expect(isHarmonyOS, isTrue);
      final folder = Directory(
        '${(await getAppSupportDirectory()).path}/harmonyos-crash-acceptance',
      );
      await folder.create(recursive: true);
      final marker = File('${folder.path}/armed.json');
      final previous = await marker.exists()
          ? jsonDecode(await marker.readAsString()) as Map<String, dynamic>
          : null;
      var now = DateTime.utc(2026, 10, 16, previous == null ? 1 : 3);
      final identity = await IdentityService(
        PlatformKeyStorage(),
      ).loadOrCreate();
      final db = AppDatabase(
        openDatabaseFile(File('${folder.path}/study.sqlite')),
      );
      final app = await StudyAppController.open(db, identity, now: () => now);
      if (previous != null) {
        expect(identity.deviceId, previous['deviceId']);
        expect(app.runningSession, isNull);
        expect(app.taskDuration(previous['taskId'] as String), 7000);
        expect(
          (await db.customSelect('PRAGMA integrity_check').getSingle())
              .data
              .values
              .single,
          'ok',
        );
        app.dispose();
        await db.close();
        debugPrint('YANJI_HARMONY_CRASH_RECOVERY_PASS');
        return;
      }
      await app.onboard(
        name: '终止恢复验收',
        date: '2028-12-20',
        subjectNames: ['数学'],
      );
      await app.saveTask(
        title: '终止恢复记录',
        subjectId: app.subjects.single.id,
        date: app.today,
      );
      final taskId = app.tasks.single.id;
      await app.startStudy(app.subjects.single.id, taskId: taskId);
      now = now.add(const Duration(seconds: 7));
      await app.checkpointStudyProgress();
      await marker.writeAsString(
        jsonEncode({'deviceId': identity.deviceId, 'taskId': taskId}),
        flush: true,
      );
      debugPrint('YANJI_HARMONY_READY_FOR_FORCE_STOP');
      await Completer<void>().future;
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
