import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/core/platform/app_support_directory.dart';

import 'navigation_convex_lens_test.dart' as convex;
import 'harmonyos_glass_dispersion_test.dart' as dispersion;
import 'harmonyos_shared_glass_test.dart' as shared;
import 'navigation_edge_optics_test.dart' as edge;
import 'liquid_glass_backdrop_alignment_test.dart' as alignment;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final support = await getAppSupportDirectory();
    final output = Directory('${support.path}/full-glass-acceptance');
    if (output.existsSync()) await output.delete(recursive: true);
    await output.create(recursive: true);
  });
  convex.main();
  edge.main();
  alignment.main();
  dispersion.main();
  shared.main();
  tearDownAll(() async {
    final metrics = Map<String, dynamic>.of(binding.reportData ?? {})
      ..remove('screenshots')
      ..addAll({
        'platform': defaultTargetPlatform.name,
        'nativeShaderFilters': ui.ImageFilter.isShaderFilterSupported,
        'capturedShaderBackend': usesCapturedGlass,
      });
    final support = await getAppSupportDirectory();
    final output = Directory('${support.path}/full-glass-acceptance');
    await output.create(recursive: true);
    await File(
      '${output.path}/metrics.json',
    ).writeAsString(jsonEncode(metrics), flush: true);
    // Completion is not success; the host also requires All tests passed and
    // rejects native shader errors and any failed test.
    debugPrint('YANJI_FULL_GLASS_METRICS ${jsonEncode(metrics)}');
  });
}
