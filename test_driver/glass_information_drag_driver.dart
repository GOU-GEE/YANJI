import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final output = Directory('docs/validation/glass-vertical-drag-2026-10-01');
    await output.create(recursive: true);
    await File('${output.path}/$name.png').writeAsBytes(bytes);
    return true;
  },
);
