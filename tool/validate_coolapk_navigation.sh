#!/bin/bash
# Reproduce Android validation with a task-local, tested toolchain. Original
# project settings are restored on normal exit, failure and interruption.
set -euo pipefail
nav_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$nav_root"
nav_backup="$(mktemp -d "$nav_root/work/navigation-validation-backup.XXXXXX")"
nav_files=(android/settings.gradle.kts android/build.gradle.kts android/app/build.gradle.kts android/gradle/wrapper/gradle-wrapper.properties pubspec.yaml)
for nav_file in "${nav_files[@]}"; do
  mkdir -p "$nav_backup/$(dirname "$nav_file")"
  cp "$nav_file" "$nav_backup/$nav_file"
done
restore_navigation_settings() {
  for nav_file in "${nav_files[@]}"; do cp "$nav_backup/$nav_file" "$nav_file"; done
  rm -rf "$nav_backup"
}
trap restore_navigation_settings EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p work/navigation-gradle-home/init.d work/navigation-sqlite-input
cat > work/navigation-gradle-home/init.d/direct-network.gradle <<'GRADLE'
['http.proxyHost','http.proxyPort','https.proxyHost','https.proxyPort','socksProxyHost','socksProxyPort'].each { System.clearProperty(it) }
System.setProperty('http.nonProxyHosts','*')
System.setProperty('https.nonProxyHosts','*')
System.setProperty('java.net.useSystemProxies','false')
GRADLE
if [ ! -f work/navigation-gradle-8.14.3.zip ]; then
  curl --fail --location --retry 2 https://downloads.gradle.org/distributions/gradle-8.14.3-bin.zip -o work/navigation-gradle-8.14.3.zip
fi
if [ ! -f work/navigation-sqlite-input/sqlite3.c ]; then
  curl --fail --location --retry 2 https://sqlite.org/2026/sqlite-amalgamation-3530100.zip -o work/navigation-sqlite-source.zip
  unzip -p work/navigation-sqlite-source.zip sqlite-amalgamation-3530100/sqlite3.c > work/navigation-sqlite-input/sqlite3.c
fi
python3 - <<'PY'
from pathlib import Path
import re
import os
for name in ['android/settings.gradle.kts', 'android/build.gradle.kts']:
 p=Path(name); s=p.read_text()
 s='\n'.join(line for line in s.split('\n') if 'maven.aliyun.com' not in line)
 if name.endswith('settings.gradle.kts'):
  s=re.sub(r'(id\("com.android.application"\) version )"[^"]+"',r'\1"8.11.1"',s)
  s=re.sub(r'(id\("org.jetbrains.kotlin.android"\) version )"[^"]+"',r'\1"2.2.21"',s)
 p.write_text(s)
p=Path('android/app/build.gradle.kts'); s=p.read_text()
if 'id("org.jetbrains.kotlin.android")' not in s:
 s=s.replace('plugins {','plugins {\n    id("org.jetbrains.kotlin.android")',1)
p.write_text(s)
p=Path('android/gradle/wrapper/gradle-wrapper.properties'); s=p.read_text()
s=re.sub(r'^distributionUrl=.*$', 'distributionUrl='+Path('work/navigation-gradle-8.14.3.zip').resolve().as_uri(),s,flags=re.M)
p.write_text(s)
p=Path('pubspec.yaml'); s=p.read_text()
if os.environ.get('NAV_BUILD_NUMBER'):
 s=re.sub(r'^(version:\s*[^\n+]+)\+\d+', r'\g<1>+'+str(int(os.environ['NAV_BUILD_NUMBER'])), s, flags=re.M)
if re.search(r'^hooks:',s,re.M):
 raise SystemExit('Existing hooks configuration: do not overwrite it; configure sqlite3 source explicitly.')
s+='\nhooks:\n  user_defines:\n    sqlite3:\n      source: source\n      path: work/navigation-sqlite-input/sqlite3.c\n'
p.write_text(s)
PY
export GRADLE_USER_HOME="$nav_root/work/navigation-gradle-home"
nav_device="${NAV_DEVICE:-emulator-5554}"
export NAV_DEVICE="$nav_device"
if [[ "$nav_device" == emulator-* ]]; then
  nav_sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  export NAV_TEST_ADB="$nav_sdk/platform-tools/adb"
fi
nav_command="${1:-optics}"
shift || true
case "$nav_command" in
  optics|regression|app|benchmark|blur|lens|convex)
    case "$nav_command" in
      optics) nav_target=integration_test/coolapk_navigation_test.dart ;;
      regression) nav_target=integration_test/navigation_regression_suite_test.dart ;;
      app) nav_target=integration_test/navigation_app_runtime_test.dart ;;
      benchmark) nav_target=integration_test/navigation_motion_performance_test.dart ;;
      blur) nav_target=integration_test/navigation_blur_regression_test.dart ;;
      lens) nav_target=integration_test/navigation_lens_visual_test.dart ;;
      convex) nav_target=integration_test/navigation_convex_lens_test.dart ;;
    esac
    export NAV_RUN="${NAV_RUN:-android-$nav_command}"
    .tooling/flutter/bin/flutter drive -d "$nav_device" --dart-define=YANJI_PREVIEW=true --driver=test_driver/coolapk_navigation_driver.dart --target="$nav_target" "$@"
    ;;
  run)
    .tooling/flutter/bin/flutter run -d "$nav_device" --dart-define=YANJI_PREVIEW=true "$@"
    ;;
  build)
    # Normal application: never seed preview data when updating a real phone.
    .tooling/flutter/bin/flutter build apk --dart-define=YANJI_PREVIEW=false "$@"
    ;;
  preview-build)
    .tooling/flutter/bin/flutter build apk --dart-define=YANJI_PREVIEW=true "$@"
    ;;
  *) echo 'Usage: validate_coolapk_navigation.sh optics|regression|app|benchmark|blur|lens|convex|run|build|preview-build [Flutter options]' >&2; exit 2 ;;
esac
