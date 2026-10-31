Based on CPF-Flutter/fluttertpc_mobile_scanner commit f5a4ff52f003e1645db1d4de743a2db0313665a8.

The three OpenHarmony platform checks use TargetPlatform.name instead of the OHOS-only enum member. This preserves ScanKit selection on OpenHarmony and allows the same dependency to compile with upstream Flutter for iOS and Android. Native implementations and scanner behavior are unchanged.

The example app and repository CI files are omitted. The local package is not published. Analysis uses the app's available lint package and excludes upstream tests, whose mocktail dev dependency is not part of the app. Two unused imports are removed and eight inherited fields are annotated with @override; these do not change runtime behavior. Upstream source, platform implementations, tests and license are retained.

Trailing whitespace from the vendored source is normalized.
