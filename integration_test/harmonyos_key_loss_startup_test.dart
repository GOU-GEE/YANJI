// Only for an emulator with a deliberately unavailable existing wrapping key.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/core/storage/platform_key_storage.dart';

Future<Map<String, String>> databaseDigests() async {
  final support = await getAppSupportDirectory();
  return {
    for (final suffix in ['', '-wal', '-shm'])
      if (await File('${support.path}/yanji.sqlite$suffix').exists())
        suffix: sha256
            .convert(
              await File('${support.path}/yanji.sqlite$suffix').readAsBytes(),
            )
            .toString(),
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'production startup preserves data when the wrapping key is missing',
    (_) async {
      final before = await databaseDigests();
      expect(before.containsKey(''), isTrue);
      final missingKey = isA<PlatformException>().having(
        (error) => error.code,
        'code',
        'CREDENTIAL_KEY_MISSING',
      );
      final container = ProviderContainer();
      try {
        await expectLater(
          container.read(appControllerProvider.future),
          throwsA(missingKey),
        );
        await expectLater(
          IdentityService(PlatformKeyStorage()).loadOrCreate(),
          throwsA(missingKey),
        );
        expect(await databaseDigests(), before);
        debugPrint(
          'YANJI_HARMONY_KEY_LOSS_STARTUP_PASS database-files-unchanged',
        );
      } finally {
        container.dispose();
      }
    },
  );
}
