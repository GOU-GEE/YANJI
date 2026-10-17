import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/application/study_app_controller.dart';
import 'package:yanji/core/database/app_database.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/platform/study_live_activity.dart';

import '../test/support/identities.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.yanji/study_live_activity');
  testWidgets('native study notification lifecycle and return action', (
    tester,
  ) async {
    expect(isHarmonyOS, isTrue);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('计时通知验收 · 使用独立内存数据库'))),
      ),
    );
    await tester.pumpAndSettle();
    final output = Directory(
      '${(await getAppSupportDirectory()).path}/study-notification-acceptance',
    );
    if (output.existsSync()) await output.delete(recursive: true);
    await output.create(recursive: true);
    // Host hdc cannot write inside the app's sandbox. A test-only loopback
    // endpoint releases the gates after real system notification interaction.
    final gates = <String>{};
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 43171);
    server.listen((request) async {
      if (request.method == 'POST' &&
          const ['/background', '/paused'].contains(request.uri.path)) {
        gates.add(request.uri.path.substring(1));
        request.response.statusCode = HttpStatus.noContent;
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
    Future<Map<Object?, Object?>> state() async => (await channel
        .invokeMapMethod<Object?, Object?>('notificationStatus'))!;
    Future<Map<Object?, Object?>> notification() async =>
        ((await state())['notifications'] as List).single as Map;
    Future<void> waitFor(Future<bool> Function() check) async {
      for (var i = 0; i < 900; i++) {
        if (await check()) return;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
      fail('Timed out waiting for native notification/host acceptance gate');
    }

    Future<void> gate(String name) => waitFor(() async => gates.contains(name));
    final db = AppDatabase(NativeDatabase.memory());
    final app = await StudyAppController.open(
      db,
      await testIdentity('01991f82-0000-7000-8000-000000009901', 99),
    );
    try {
      await app.onboard(
        name: '通知验收',
        date: '2028-12-23',
        subjectNames: ['通知验收数学'],
      );
      debugPrint('YANJI_STUDY_NOTIFICATION_REQUESTING_PERMISSION');
      await app.startStudy(app.studySubjects.first.id);
      await waitFor(
        () async => ((await state())['notifications'] as List).length == 1,
      );
      final first = (await notification())['text'] as String;
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      final second = (await notification())['text'] as String;
      expect(first, startsWith('已学习'));
      expect(second.split(' · ').first, isNot(first.split(' · ').first));
      debugPrint('YANJI_STUDY_NOTIFICATION_ACTIVE');
      // Host backgrounds the app, inspects the notification shade and taps the
      // notification before releasing this gate. No real study database is used.
      await gate('background');
      expect(await StudyLiveActivity.consumePendingAction(), 'open');
      expect(await StudyLiveActivity.consumePendingAction(), isNull);
      await app.pauseStudy();
      await app.syncLiveActivity();
      await waitFor(
        () async =>
            ((await notification())['text'] as String).startsWith('已暂停'),
      );
      final paused = (await notification())['text'];
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect((await notification())['text'], paused);
      debugPrint('YANJI_STUDY_NOTIFICATION_PAUSED');
      await gate('paused');
      await app.resumeStudy();
      await app.syncLiveActivity();
      await waitFor(
        () async =>
            ((await notification())['text'] as String).startsWith('已学习'),
      );
      final resumed = (await notification())['text'] as String;
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(
        ((await notification())['text'] as String).split(' · ').first,
        isNot(resumed.split(' · ').first),
      );
      final oldSession = app.runningSession!.id;
      await app.stopStudy();
      await app.syncLiveActivity();
      await waitFor(
        () async => ((await state())['notifications'] as List).isEmpty,
      );
      await channel.invokeMethod<void>('sync', {
        'sessionId': oldSession,
        'subject': '过时快照',
        'status': 'active',
        'elapsedSeconds': 0,
        'snapshotAtMs': 1,
        'statusUpdatedAtMs': 1,
      });
      expect((await state())['notifications'], isEmpty);
      final metrics = {
        'foregroundCounterAdvanced': true,
        'pauseCounterFrozen': true,
        'resumeCounterAdvanced': true,
        'notificationTapReturnsOpen': true,
        'completionRemovesNotification': true,
        'staleSnapshotIgnored': true,
        'nativeStatus': await state(),
      };
      await File(
        '${output.path}/result.json',
      ).writeAsString(jsonEncode(metrics), flush: true);
      debugPrint('YANJI_STUDY_NOTIFICATION_PASS ${jsonEncode(metrics)}');
    } finally {
      await server.close(force: true);
      if (app.runningSession != null) await app.stopStudy();
      await app.syncLiveActivity();
      app.dispose();
      await db.close();
    }
  });
}
