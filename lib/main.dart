import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/yanji_app.dart';
import 'app/preview_dependencies.dart';
import 'core/logging/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  const AppLog().event(LogArea.app, 'app.start');
  const preview = bool.fromEnvironment('YANJI_PREVIEW');
  runApp(
    ProviderScope(
      overrides: preview ? previewOverrides() : const [],
      child: const YanJiApp(),
    ),
  );
}
