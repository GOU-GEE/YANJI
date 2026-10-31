#!/usr/bin/env bash
# Build the real app from this checkout; never reuse a preview/test APK.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
flutter_sdk="${YANJI_FLUTTER_HOME:-$project_root/.tooling/flutter}"
build_number="${1:?Usage: bash tool/build_android_release.sh <increasing-build-number>}"
if [[ ! "$build_number" =~ ^[1-9][0-9]*$ ]]; then
  echo "Build number must be a positive integer." >&2
  exit 1
fi
cd "$project_root"
printf 'Checkout: %s\nRevision: %s\nBuild: %s\n' \
  "$project_root" "$(git rev-parse --short HEAD)" "$build_number"
git diff --quiet && git diff --cached --quiet || echo 'Includes local source changes.'
"$flutter_sdk/bin/flutter" pub get
"$flutter_sdk/bin/flutter" build apk --release --no-pub \
  --target=lib/main.dart --target-platform=android-arm64 \
  --build-number="$build_number" \
  --dart-define=YANJI_PREVIEW=false --dart-define=YANJI_GLASS_REDUCED=false
python3 - "$project_root" "$build_number" <<'PY'
import hashlib
import json
from pathlib import Path
import subprocess
import sys

root, number = Path(sys.argv[1]), int(sys.argv[2])
apk = root / 'build/app/outputs/flutter-apk/app-release.apk'
manifest = {
    'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
    'local_changes': bool(subprocess.check_output(['git', 'diff', 'HEAD', '--name-only'], text=True).strip()),
    'build_number': number,
    'target': 'lib/main.dart',
    'preview': False,
    'glass_reduced': False,
    'sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
}
apk.with_suffix('.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(apk)
print('SHA-256: ' + manifest['sha256'])
PY
