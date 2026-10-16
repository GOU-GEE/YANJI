import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final output = Directory(
      Platform.environment['YANJI_VISUAL_OUTPUT'] ??
          'docs/validation/liquid-glass-refraction-2026-09-27',
    );
    await output.create(recursive: true);
    await File('${output.path}/$name.png').writeAsBytes(bytes);
    return true;
  },
);
