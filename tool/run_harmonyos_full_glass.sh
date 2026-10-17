#!/usr/bin/env bash
# Optical acceptance on an explicitly selected emulator. Replace HAP only;
# never uninstall modules or touch the installed preview/user databases.
set -euo pipefail
source "$(dirname "$0")/harmonyos_env.sh"
device="${1:?Usage: tool/run_harmonyos_full_glass.sh <emulator-target>}"
cd "$project_root"
logs="$project_root/work/harmonyos/${YANJI_GLASS_OUTPUT:-full-glass}"
test_target="${YANJI_GLASS_TEST_TARGET:-integration_test/harmonyos_full_glass_test.dart}"
mkdir -p "$logs"
tool/build_harmonyos_unsigned.sh "$test_target" > "$logs/build.log" 2>&1
python3 - "$DEVECO_SDK_HOME/default/openharmony/toolchains/hdc" "$device" "$project_root" "$logs" "$test_target" <<'PY'
from datetime import datetime
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
hdc, device, root, logs, test_target = sys.argv[1:]
root, logs = Path(root), Path(logs)
prefix = [hdc, '-t', device]
def run(*args):
    return subprocess.check_output(prefix + list(args), text=True, stderr=subprocess.STDOUT, timeout=30)
installed = run('install', '-r', str(root/'ohos/entry/build/default/outputs/default/entry-default-unsigned.hap'))
(logs/'install.log').write_text(installed)
if 'install bundle successfully' not in installed:
    raise SystemExit('Acceptance HAP installation failed.')
old_pid = run('shell', 'pidof', 'com.example.yanji').strip()
run('shell', 'aa', 'force-stop', 'com.example.yanji')
started = run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.example.yanji')
if 'start ability successfully' not in started:
    raise SystemExit('Acceptance application did not start.')
deadline = time.monotonic() + 360
lines, seen = [], set()
while time.monotonic() < deadline:
    pid = run('shell', 'pidof', 'com.example.yanji').strip()
    if pid.isdigit() and pid != old_pid:
        for line in run('shell', 'hilog', '-x', '-P', pid).splitlines():
            if line not in seen:
                seen.add(line); lines.append(line)
        raw = '\n'.join(lines)
        (logs/'device.log').write_text(raw)
        if 'Some tests failed.' in raw or 'All tests passed!' in raw:
            break
    time.sleep(2)
raw = '\n'.join(lines)
match = re.search(r'YANJI_FULL_GLASS_METRICS (\{[^\n]+\})', raw)
result = json.loads(match[1]) if match else {}
required = {'bar_reduction', 'edge_displacement_dp', 'edge_profile', 'backdrop_alignment',
            'dispersion_pixels', 'live_backdrop_changed_pixels', 'segmented_themes'}
if test_target.endswith('glass_ui_reacceptance_test.dart'):
    required.update({'preview_ui_themes', 'preview_ui_ranges', 'preview_ui_navigation_release_verified'})
result.update({
    'executedAt': datetime.now().astimezone().isoformat(timespec='seconds'),
    'shaderCompilationErrors': raw.count('Shader compilation error'),
    'skSlErrors': raw.count('SkSL Error:'),
    'success': bool(match) and required.issubset(result) and 'All tests passed!' in raw
        and 'Some tests failed.' not in raw and 'Shader compilation error' not in raw
        and 'SkSL Error:' not in raw,
})
result['fullRefractionVerified'] = result['success']
(logs/'result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
# Preserve screenshots even on failure to diagnose actual optical output.
capture_root = logs/'captures'
if capture_root.exists():
    shutil.rmtree(capture_root)
print(run('file', 'recv', '/data/app/el2/100/base/com.example.yanji/files/full-glass-acceptance', str(capture_root)))
if not result['success']:
    raise SystemExit(f'Full optical acceptance failed; inspect {logs/"device.log"}.')
print('Full optical acceptance passed; native shader compilation errors: 0.')
print(json.dumps(result, ensure_ascii=False, indent=2))
PY
