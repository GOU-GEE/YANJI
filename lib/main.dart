import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/yanji_app.dart';
import 'core/logging/app_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  const AppLog().event(LogArea.app, 'app.start');
  runApp(const ProviderScope(child: YanJiApp()));
}
