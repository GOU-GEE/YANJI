import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/crypto/device_identity.dart';
import 'package:yanji/core/platform/app_support_directory.dart';
import 'package:yanji/core/storage/platform_key_storage.dart';
import 'package:yanji/core/storage/secret_value_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> values;
  late List<String> writes;
  var unavailable = false;
  setUp(() {
    values = {};
    writes = [];
    unavailable = false;
    messenger.setMockMethodCallHandler(yanjiPlatformChannel, (call) async {
      if (unavailable) throw PlatformException(code: 'CREDENTIAL_UNAVAILABLE');
      final args = call.arguments as Map;
      final key = args['key'] as String;
      if (call.method == 'secretRead') return values[key];
      if (call.method == 'secretWrite') {
        writes.add(key);
        values[key] = args['value'] as String;
        return null;
      }
      throw MissingPluginException();
    });
  });
  tearDown(
    () => messenger.setMockMethodCallHandler(yanjiPlatformChannel, null),
  );
  PlatformKeyStorage storage() =>
      PlatformKeyStorage(values: const HarmonySecretValueStorage());

  test(
    'Harmony channel retains identity format and serializes initialization',
    () async {
      final candidates = List.generate(
        2,
        (i) => IdentitySecret(
          deviceId: 'device-$i',
          keyReference: 'candidate',
          seed: List.filled(32, i + 1),
        ),
      );
      final installed = await Future.wait([
        storage().installIfAbsent(candidates[0]),
        storage().installIfAbsent(candidates[1]),
      ]);
      expect(installed.map((s) => s.deviceId), ['device-0', 'device-0']);
      expect(writes, [PlatformKeyStorage.key]);
      final reloaded = await storage().readCurrent();
      expect(reloaded!.seed, candidates[0].seed);
      expect(jsonDecode(values[PlatformKeyStorage.key]!) as Map, {
        'deviceId': 'device-0',
        'seed': base64Encode(candidates[0].seed),
      });
    },
  );

  test('native failure cannot create or replace a device identity', () async {
    unavailable = true;
    await expectLater(
      IdentityService(storage()).loadOrCreate(),
      throwsA(isA<PlatformException>()),
    );
    expect(writes, isEmpty);
  });

  test('corrupt persisted identity is not replaced', () async {
    values[PlatformKeyStorage.key] = '{broken';
    await expectLater(
      IdentityService(storage()).loadOrCreate(),
      throwsFormatException,
    );
    expect(writes, isEmpty);
  });

  test(
    'endpoint storage uses its own stable key and propagates failures',
    () async {
      final tls = PlatformTlsIdentityStorage(
        values: const HarmonySecretValueStorage(),
      );
      await tls.writeSyncEndpoints('{"peer":["192.168.1.2"]}');
      expect(await tls.readSyncEndpoints(), '{"peer":["192.168.1.2"]}');
      expect(writes, [PlatformTlsIdentityStorage.syncEndpointsKey]);
      unavailable = true;
      await expectLater(tls.readCurrent(), throwsA(isA<PlatformException>()));
    },
  );
}
