#!/usr/bin/env bash
# Run the pinned HarmonyOS SDK without changing the user's global Flutter setup.
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_sdk="${YANJI_FLUTTER_OHOS_HOME:-$project_root/.tooling/flutter-ohos-3.41.9}"
tools_root="${YANJI_HARMONYOS_TOOLS:-$project_root/.tooling/harmonyos/command-line-tools}"

if [[ ! -x "$flutter_sdk/bin/flutter" ]]; then
  echo "Flutter OHOS SDK missing: $flutter_sdk" >&2
  echo "See docs/harmonyos/README.md, or set YANJI_FLUTTER_OHOS_HOME." >&2
  exit 1
fi

if [[ -d "$tools_root/Contents" ]]; then
  tools_root="$tools_root/Contents"
fi
if [[ -d "$tools_root/sdk" ]]; then
  export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$tools_root/sdk}"
fi
for tools_bin in \
  "$tools_root/tools/node/bin" "$tools_root/tool/node/bin" "$tools_root/node/bin" \
  "$tools_root/tools/ohpm/bin" "$tools_root/tool/ohpm/bin" "$tools_root/ohpm/bin" \
  "$tools_root/tools/hvigor/bin" "$tools_root/tool/hvigor/bin" "$tools_root/hvigor/bin"; do
  if [[ -d "$tools_bin" ]]; then
    export PATH="$tools_bin:$PATH"
  fi
done
if [[ -d "$tools_root/bin" ]]; then
  export PATH="$tools_root/bin:$PATH"
fi
export PATH="$flutter_sdk/bin:$PATH"

cd "$project_root"
exec "$flutter_sdk/bin/flutter" "$@"
