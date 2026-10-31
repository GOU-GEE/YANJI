import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/platform/study_live_activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.yanji/study_live_activity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'consumePendingAction' ? 'open' : null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> sync(String status) => StudyLiveActivity.sync(
    sessionId: status == 'finished' ? null : 'session-1',
    subject: '数学',
    status: status,
    elapsedMilliseconds: 42099,
    todayTotalMilliseconds: 60001,
    doNotDisturbEnabled: true,
    snapshotAtMilliseconds: 100000,
    statusUpdatedAtMilliseconds: 58000,
  );

  for (final platform in TargetPlatform.values.where(
    (value) => ['android', 'iOS', 'ohos'].contains(value.name),
  )) {
    test(
      '${platform.name} forwards the same complete timer lifecycle',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        for (final status in ['active', 'paused', 'active', 'finished']) {
          await sync(status);
        }
        expect(calls.map((call) => call.method), everyElement('sync'));
        expect(calls.map((call) => (call.arguments as Map)['status']), [
          'active',
          'paused',
          'active',
          'finished',
        ]);
        final start = calls.first.arguments as Map;
        expect(start['elapsedSeconds'], 42);
        expect(start['todayTotalSeconds'], 60);
        expect(start['snapshotAtMs'], 100000);
        expect(start['statusUpdatedAtMs'], 58000);
        expect((calls.last.arguments as Map)['sessionId'], isNull);
        expect(await StudyLiveActivity.consumePendingAction(), 'open');
        expect(await StudyLiveActivity.currentActivityState(), isNull);
      },
    );
  }

  test(
    'notification denial never stops or fails the Dart timer command',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'NOTIFICATION_DISABLED',
          message: 'denied',
        );
      });
      await expectLater(sync('active'), completes);
      expect(await StudyLiveActivity.consumePendingAction(), isNull);
    },
  );

  test('desktop does not request mobile notification permissions', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await sync('active');
    expect(await StudyLiveActivity.consumePendingAction(), isNull);
    expect(calls, isEmpty);
  });
}
