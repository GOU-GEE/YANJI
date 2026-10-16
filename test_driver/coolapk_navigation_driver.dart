import 'dart:io';
import 'dart:convert';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // The test target is paused until integrationDriver connects. Grant only on
  // the explicitly selected test emulator, before first-launch prompts can
  // cover FlutterView and steal IME focus. No physical-device permission change.
  final adb = Platform.environment['NAV_TEST_ADB'];
  final device = Platform.environment['NAV_DEVICE'];
  if (adb != null && device != null && device.startsWith('emulator-')) {
    final result = await Process.run(adb, [
      '-s',
      device,
      'shell',
      'pm',
      'grant',
      'com.example.yanji',
      'android.permission.POST_NOTIFICATIONS',
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        'Test emulator permission setup failed: ${result.stderr}',
      );
    }
  }
  await integrationDriver(
    responseDataCallback: (data) async {
      final dir = Directory(
        'docs/validation/coolapk-navigation-2026-10-11/${Platform.environment['NAV_RUN'] ?? 'android'}',
      );
      await dir.create(recursive: true);
      await File('${dir.path}/metrics.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(
          data == null
              ? null
              : Map.fromEntries(
                  data.entries.where((e) => e.key != 'screenshots'),
                ),
        ),
      );
    },
    onScreenshot: (name, bytes, [args]) async {
      final dir = Directory(
        'docs/validation/coolapk-navigation-2026-10-11/${Platform.environment['NAV_RUN'] ?? 'android'}',
      );
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
