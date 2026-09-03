import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/yanji_app.dart';
import 'core/logging/app_log.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const AppLog().event(LogArea.app, 'app.start');
  runApp(const ProviderScope(child: YanJiApp()));
}
