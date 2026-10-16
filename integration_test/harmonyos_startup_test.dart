// Opt-in fixture creation is only for a fresh disposable emulator.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanji/app/dependencies.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/core/storage/platform_key_storage.dart';
import 'package:yanji/sync/transport/tls_identity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'HarmonyOS production composition opens the persisted workspace',
    (_) async {
      final container = ProviderContainer();
      try {
        final app = await container.read(appControllerProvider.future);
        if (const bool.fromEnvironment('YANJI_SEED_STARTUP') &&
            app.workspace == null) {
          await app.onboard(
            name: '鸿蒙本机验证',
            date: '2028-12-20',
            subjectNames: ['数学', '英语', '专业课'],
          );
        }
        expect(app.workspace, isNotNull);
        expect(app.subjects, isNotEmpty);
        final tls = await TlsIdentityService(
          PlatformTlsIdentityStorage(),
        ).loadOrCreate(app.identity.deviceId);
        final support = await getAppSupportDirectory();
        final marker = File('${support.path}/startup-acceptance.json');
        final previous = await marker.exists()
            ? jsonDecode(await marker.readAsString()) as Map<String, dynamic>
            : null;
        final current = {
          'deviceId': app.identity.deviceId,
          'publicKey': base64Encode(app.identity.publicKey.bytes),
          'tlsFingerprint': base64Encode(tls.fingerprintSha256),
          'workspaceId': app.workspace!.id,
        };
        if (previous != null) {
          for (final entry in current.entries) {
            expect(entry.value, previous[entry.key]);
          }
        }
        final result = {
          ...current,
          'runs': (previous?['runs'] as int? ?? 0) + 1,
        };
        await marker.writeAsString(jsonEncode(result), flush: true);
        debugPrint('YANJI_HARMONY_STARTUP_PASS ${jsonEncode(result)}');
      } catch (error, stack) {
        // Log types, codes and source locations, never serialized credentials.
        debugPrint(
          'YANJI_HARMONY_STARTUP_FAILURE ${error.runtimeType}'
          '${error is PlatformException ? ' code=${error.code}' : ''}',
        );
        debugPrintStack(stackTrace: stack);
        fail('Production startup failed: ${error.runtimeType}');
      } finally {
        container.dispose();
      }
    },
  );
}
