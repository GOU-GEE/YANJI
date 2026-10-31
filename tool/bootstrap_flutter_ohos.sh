#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_sdk="${YANJI_FLUTTER_OHOS_HOME:-$project_root/.tooling/flutter-ohos-3.41.9}"
expected_commit=62357a93d653bf844f730bb1f4b7cc9e2139d14e

if [[ ! -e "$flutter_sdk" ]]; then
  mkdir -p "$(dirname "$flutter_sdk")"
  git clone --depth 1 --filter=blob:none --sparse \
    --branch 3.41.9+ohos-1.0.2 \
    https://gitcode.com/CPF-Flutter/flutter_flutter.git "$flutter_sdk"
  # flutter analyze also enumerates SDK packages under dev/ and examples/.
  git -C "$flutter_sdk" sparse-checkout set bin packages dev examples
fi

actual_commit="$(git -C "$flutter_sdk" rev-parse HEAD)"
if [[ "$actual_commit" != "$expected_commit" ]]; then
  echo "Unexpected Flutter OHOS revision: $actual_commit" >&2
  echo "Expected $expected_commit; use a separate SDK directory." >&2
  exit 1
fi

"$flutter_sdk/bin/flutter" --version
exec "$flutter_sdk/bin/flutter" precache --ohos \
  --no-android --no-ios --no-web --no-linux --no-windows --no-fuchsia
