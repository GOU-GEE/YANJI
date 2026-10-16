import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Android's converted ImageView can still expose the previously acquired
/// frame immediately after pump. Acquire once, then save the following frame;
/// never accept a stale image as evidence of a zero optical displacement.
Future<List<int>> captureNavigationFrame(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 160));
  await tester.pump();
  await _snapshot(binding, tester, '$name-sync');
  (binding.reportData!['screenshots'] as List<dynamic>).removeLast();
  await tester.pump();
  await Future<void>.delayed(const Duration(milliseconds: 150));
  final bytes = await _snapshot(binding, tester, name);
  if (!kIsWeb &&
      ['ohos', 'android', 'iOS'].contains(defaultTargetPlatform.name)) {
    final support = await getAppSupportDirectory();
    final output = Directory('${support.path}/full-glass-acceptance');
    await output.create(recursive: true);
    await File('${output.path}/$name.png').writeAsBytes(bytes, flush: true);
  }
  return bytes;
}

// Window snapshot can briefly fail while the OHOS compositor is busy. Retry
// only that documented platform failure, never optical checks or app errors.
Future<List<int>> _snapshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await binding.takeScreenshot(name);
    } on PlatformException catch (error) {
      if (defaultTargetPlatform.name != 'ohos' ||
          error.code != 'Could not capture screenshot' ||
          !(error.message?.contains('1300002') ?? false) ||
          attempt >= 2) {
        rethrow;
      }
      final report = binding.reportData!;
      report['screenshot_retries'] =
          (report['screenshot_retries'] as int? ?? 0) + 1;
      debugPrint('OHOS snapshot busy; retry ${attempt + 1}/2 for $name');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    }
  }
}
