import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const yanjiPlatformChannel = MethodChannel('yanji/platform.v1');
bool get isHarmonyOS => Platform.operatingSystem == 'ohos';

Future<Directory> getAppSupportDirectory() async {
  if (!isHarmonyOS) return getApplicationSupportDirectory();
  final path = await yanjiPlatformChannel.invokeMethod<String>(
    'supportDirectory',
  );
  if (path == null || path.isEmpty || !path.startsWith('/')) {
    throw StateError('HarmonyOS did not provide a persistent app directory.');
  }
  return Directory(path);
}
