import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

import '../support/convergence/random_scenario.dart';

void main() {
  final env = Platform.environment;
  final profile = env['YANJI_CONVERGENCE_PROFILE'] ?? 'pr';
  final defaults = switch (profile) {
    'pr' => (10, 200),
    'extended' => (100, 1000),
    'soak' => (100, 2000),
    _ => throw ArgumentError('Unknown profile $profile'),
  };
  final actions = int.parse(env['YANJI_ACTIONS'] ?? '${defaults.$2}');
  final count = int.parse(env['YANJI_SEEDS'] ?? '${defaults.$1}');
  final single = env['YANJI_SEED'];
  final seeds = <int>{
    if (single != null)
      int.parse(single)
    else
      ...List.generate(count, (i) => 202609030001 + i),
    if (single == null)
      ...File('test/fixtures/regression_seeds.txt')
          .readAsLinesSync()
          .map((l) => l.split('#').first.trim())
          .where((l) => l.isNotEmpty)
          .map(int.parse),
  };
  late bool warning;
  setUpAll(() {
    warning = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = warning;
  });
  for (final seed in seeds) {
    test('M3 $profile seed=$seed actions=$actions', () async {
      final result = await RandomScenario(seed, actions).run();
      final dir = Directory(
        '${env['YANJI_ARTIFACT_DIR'] ?? '.dart_tool/convergence'}/metrics',
      );
      await dir.create(recursive: true);
      await File('${dir.path}/seed_${seed}_actions_$actions.json')
          .writeAsString(
            const JsonEncoder.withIndent('  ').convert(result.metrics),
          );
      // ignore: avoid_print
      print('M3 metrics ${jsonEncode(result.metrics)}');
    }, timeout: const Timeout(Duration(minutes: 30)));
  }
  if (single == null && profile == 'pr') {
    test(
      'M3 seed replay reproduces complete trace, signed bytes and final state',
      () async {
        final first = await RandomScenario(202609039999, 40).run();
        final second = await RandomScenario(202609039999, 40).run();
        expect(first.trace, second.trace);
        expect(first.fingerprint, second.fingerprint);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
