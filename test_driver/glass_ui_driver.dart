import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Collects native window screenshots; never substitutes widget render output.
Future<void> main() async {
  final output = Directory(
    Platform.environment['YANJI_REFERENCE_OUTPUT'] ??
        'work/harmonyos/ui-reference',
  );
  await output.create(recursive: true);
  await integrationDriver(
    responseDataCallback: (data) async {
      final metrics = Map<String, dynamic>.of(data ?? {})
        ..remove('screenshots');
      await File(
        '${output.path}/metrics.json',
      ).writeAsString(jsonEncode(metrics));
    },
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
