// HarmonyOS adapter for sqlite3 3.5.2. Other targets retain the upstream hook.
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';

import 'package:sqlite3/src/hook/compile/description.dart';
import 'package:sqlite3/src/hook/compile/used_symbols.dart';

Future<bool> buildOhosSqlite(
  BuildInput input,
  BuildOutputBuilder output,
) async {
  final config = input.config.code;
  final compiler = config.cCompiler?.compiler;
  if (compiler == null ||
      !compiler.path
          .replaceAll('\\', '/')
          .contains('/openharmony/native/llvm/bin/')) {
    return false;
  }
  // Flutter OHOS 3.41.9 currently reports Linux to third-party build hooks.
  // Identify the supplied toolchain, not the host OS or an environment variable.
  if (config.targetOS != OS.linux) {
    throw UnsupportedError(
      'Review the OHOS compatibility shim before upgrading Flutter.',
    );
  }
  final triple = switch (config.targetArchitecture) {
    Architecture.arm64 => 'aarch64-linux-ohos',
    Architecture.x64 => 'x86_64-linux-ohos',
    _ => throw UnsupportedError('Unsupported OHOS SQLite architecture.'),
  };
  final nativeRoot = compiler.resolve('../../');
  final sysroot = nativeRoot.resolve('sysroot/');
  if (!Directory.fromUri(sysroot).existsSync()) {
    throw StateError('HarmonyOS native sysroot is missing.');
  }
  final source = input.packageRoot.resolve('src/sqlite3.c');
  final header = input.packageRoot.resolve('src/sqlite3.h');
  final digest = sha256
      .convert(await File.fromUri(source).readAsBytes())
      .toString();
  if (digest !=
      'b1dd5d74ec7f29055a6684fa06fb3c2f6821c87dd38f9a458dfd2e8a1db28189') {
    throw StateError('Vendored SQLite 3.53.4 source checksum does not match.');
  }
  final exports = input.outputDirectory.resolve('sqlite.map');
  await File.fromUri(exports).writeAsString('''
{
  global:
${usedSqliteSymbols.map((s) => '    $s;').join('\n')}
  local: *;
};
''');
  final library = input.outputDirectory.resolve('libyanji_sqlite3.so');
  final flags = [
    '--target=$triple',
    '--sysroot=${sysroot.toFilePath()}',
    '-shared',
    '-fPIC',
    '-O2',
    '-DNDEBUG',
    '-Wl,-soname,libyanji_sqlite3.so',
    '-Wl,-z,relro,-z,now,-z,max-page-size=16384',
    '-Wl,-Bsymbolic',
    '-Wl,--version-script=${exports.toFilePath()}',
    for (final entry in CompilerDefines.defaults(false).entries)
      '-D${entry.key}${entry.value == null ? '' : '=${entry.value}'}',
    source.toFilePath(),
    '-lm',
    '-ldl',
    '-pthread',
    '-o',
    library.toFilePath(),
  ];
  final result = await Process.run(compiler.toFilePath(), flags);
  if (result.exitCode != 0) {
    throw ProcessException(
      compiler.toFilePath(),
      flags,
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
  output.dependencies.addAll([source, header, compiler]);
  output.assets.code.add(
    CodeAsset(
      package: 'sqlite3',
      name: 'src/ffi/libsqlite3.g.dart',
      linkMode: DynamicLoadingBundled(),
      file: library,
    ),
  );
  return true;
}
