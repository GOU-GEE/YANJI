#!/usr/bin/env bash
# Official Hvigor unsigned HAP build for emulator validation (no fake signing).
set -euo pipefail
source "$(dirname "$0")/harmonyos_env.sh"
target="${1:-lib/main.dart}"
cd "$project_root"
"$flutter_sdk/bin/flutter" pub get --enforce-lockfile
cd ohos
hvigorw assembleHap -p product=default -p buildMode=debug --no-daemon \
  -p "FLUTTER_TARGET=$target" -p TARGET_PLATFORM=ohos-arm64 \
  -p "DART_DEFINES=${YANJI_DART_DEFINES:-}"
artifact="$project_root/ohos/entry/build/default/outputs/default/entry-default-unsigned.hap"
[[ -f "$artifact" ]]
echo "Unsigned emulator HAP: $artifact"
