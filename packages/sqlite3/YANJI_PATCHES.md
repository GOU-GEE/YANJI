# SQLite HarmonyOS adapter

Vendored production code from pub.dev `sqlite3` **3.5.2** (MIT; LICENSE retained).
Dart bindings and runtime API are unchanged. The root app uses a path override so
all platforms use the same bindings. Upstream hook remains active on other targets.

Changes: remove upstream workspace/dev tooling metadata; add `hook/ohos.dart`
and dispatch to it only when the hook input supplies the official OHOS compiler.
Flutter OHOS 3.41.9 maps its hook target OS to Linux. Using upstream precompiled
Linux assets would bundle a glibc library rather than an OHOS library.

OHOS compiles SQLite **3.53.4**, matching sqlite3 3.5.2's macOS release binary,
with upstream compiler defines, an explicit OHOS triple, sysroot, and SONAME.
The output has a distinct library name and is emitted as the original native asset.
Drift schema and migration versions are unchanged.

Source: https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip
Archive SHA-256: `1e71ddf93849c6a6ecf58b827c0692073d2dd7ee40196158068f7b29f422e87d`
`src/sqlite3.c`: `b1dd5d74ec7f29055a6684fa06fb3c2f6821c87dd38f9a458dfd2e8a1db28189`
`src/sqlite3.h`: `919e7f2e8ed1d8f56ac17b412b8971c76aa5d1a879752cc6058f75e7d5910e1d`
SQLite is public domain; the source files retain its dedication.

On updates, compare this package with upstream, recheck the compiler-target shim,
update provenance/checksums and run database migrations, WAL recovery and HAP tests.
Never substitute the stock Linux or host macOS binary for the OHOS output.
