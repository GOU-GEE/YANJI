// Run only on a disposable HarmonyOS emulator. Uses a separate acceptance DB.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/database/connection.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/core/storage/platform_key_storage.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('HarmonyOS identities, SQLite and local study lifecycle', (
    _,
  ) async {
    expect(isHarmonyOS, isTrue);
    final support = await getAppSupportDirectory();
    final folder = Directory('${support.path}/harmonyos-acceptance');
    await folder.create(recursive: true);
    final marker = File('${folder.path}/last-pass.json');
    final previous = await marker.exists()
        ? jsonDecode(await marker.readAsString()) as Map<String, dynamic>
        : null;
    final identity = await IdentityService(PlatformKeyStorage()).loadOrCreate();
    final tls = await TlsIdentityService(
      PlatformTlsIdentityStorage(),
    ).loadOrCreate(identity.deviceId);
    final fingerprint = base64Encode(tls.fingerprintSha256);
    final publicKey = base64Encode(identity.publicKey.bytes);
    if (previous != null) {
      expect(identity.deviceId, previous['deviceId']);
      expect(publicKey, previous['publicKey']);
      expect(fingerprint, previous['tlsFingerprint']);
    }
    final signature = await identity.sign(utf8.encode('harmonyos-acceptance'));
    expect(
      await Ed25519().verify(
        utf8.encode('harmonyos-acceptance'),
        signature: signature,
      ),
      isTrue,
    );
    final file = File('${folder.path}/study.sqlite');
    // Each process run advances the synthetic clock beyond the prior session.
    // Resetting to 01:00 would correctly clip statistics for future segments.
    var now = DateTime.utc(2026, 10, 16, 1)
        .add(Duration(hours: (previous?['runs'] as int? ?? 0) * 2));
    var db = AppDatabase(openDatabaseFile(file));
    var app = await StudyAppController.open(db, identity, now: () => now);
    if (previous != null) {
      expect(app.taskDuration(previous['taskId'] as String), 180000);
      expect(app.review(app.today)?.content, '鸿蒙本机验收：持久化成功');
    }
    if (app.workspace == null) {
      await app.onboard(name: '鸿蒙验收', date: '2028-12-20', subjectNames: ['数学']);
    }
    final subject = app.subjects.first.id;
    final title = '离线学习验收 ${(previous?['runs'] as int? ?? 0) + 1}';
    await app.saveTask(
      title: title,
      date: app.today,
      subjectId: subject,
      estimatedSeconds: 600,
    );
    final taskId = app.tasks.firstWhere((t) => t.title == title).id;
    await app.startStudy(subject, taskId: taskId);
    now = now.add(const Duration(minutes: 2));
    await app.pauseStudy();
    now = now.add(const Duration(minutes: 5));
    await app.resumeStudy();
    now = now.add(const Duration(minutes: 1));
    await app.checkpointStudyProgress();
    await app.saveReview(app.today, '鸿蒙本机验收：持久化成功');
    expect(app.taskDuration(taskId), 180000);
    expect(
      (await db.customSelect('PRAGMA journal_mode').getSingle())
          .data
          .values
          .single,
      'wal',
    );
    expect(
      (await db.customSelect('PRAGMA synchronous').getSingle())
          .data
          .values
          .single,
      2,
    );
    final count = (await db.select(db.oplog).get()).length;
    // Exercise the existing v4→v5 migration with real committed learning data.
    await db.customStatement('DROP TABLE local_workspace_selection');
    await db.customStatement('PRAGMA user_version = 4');
    app.dispose();
    await db.close();
    now = now.add(const Duration(hours: 1));
    db = AppDatabase(openDatabaseFile(file));
    app = await StudyAppController.open(db, identity, now: () => now);
    expect(app.runningSession, isNull);
    expect(app.taskDuration(taskId), 180000);
    expect(app.review(app.today)?.content, '鸿蒙本机验收：持久化成功');
    expect(
      (await db.select(db.oplog).get()).length,
      greaterThanOrEqualTo(count),
    );
    expect(
      (await db.customSelect('PRAGMA integrity_check').getSingle())
          .data
          .values
          .single,
      'ok',
    );
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .single,
      5,
    );
    final result = <String, Object>{
      'deviceId': identity.deviceId,
      'publicKey': publicKey,
      'tlsFingerprint': fingerprint,
      'taskId': taskId,
      'runs': (previous?['runs'] as int? ?? 0) + 1,
      'schema': 5,
      'durationMs': app.taskDuration(taskId),
    };
    app.dispose();
    await db.close();
    await marker.writeAsString(jsonEncode(result), flush: true);
    debugPrint('YANJI_HARMONY_SMOKE_PASS ${jsonEncode(result)}');
  });
}
