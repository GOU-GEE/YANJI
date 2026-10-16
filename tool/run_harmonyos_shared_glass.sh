#!/usr/bin/env bash
# Run only on an explicitly selected disposable emulator, then restore main.dart.
set -euo pipefail
source "$(dirname "$0")/harmonyos_env.sh"
device="${1:?Usage: tool/run_harmonyos_shared_glass.sh <emulator-target>}"
hdc="$DEVECO_SDK_HOME/default/openharmony/toolchains/hdc"
cd "$project_root"
logs="$project_root/work/harmonyos/shared-glass"
mkdir -p "$logs"
tool/build_harmonyos_unsigned.sh integration_test/harmonyos_shared_glass_test.dart > "$logs/build.log" 2>&1
python3 - "$hdc" "$device" "$project_root" "$logs" <<'PY'
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
import sys
import time

hdc, device, root, logs = sys.argv[1:]
root, logs = Path(root), Path(logs)
prefix = [hdc, '-t', device]
def run(*args):
    return subprocess.check_output(prefix + list(args), text=True, stderr=subprocess.STDOUT)

install = run('install', '-r', str(root/'ohos/entry/build/default/outputs/default/entry-default-unsigned.hap'))
(logs/'install.log').write_text(install)
if 'install bundle successfully' not in install:
    raise SystemExit('Acceptance HAP installation failed.')
old_pid = run('shell', 'pidof', 'com.example.yanji').strip()
run('shell', 'aa', 'force-stop', 'com.example.yanji')
started = run('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', 'com.example.yanji')
if 'start ability successfully' not in started:
    raise SystemExit('Acceptance application did not start.')
deadline = time.monotonic() + 90
raw = ''
while time.monotonic() < deadline:
    pid = run('shell', 'pidof', 'com.example.yanji').strip()
    if pid.isdigit() and pid != old_pid:
        raw = run('shell', 'hilog', '-x', '-P', pid)
        (logs/'device.log').write_text(raw)
        if any(s in raw for s in ['Shader compilation error', 'Some tests failed.']):
            break
        if 'YANJI_HARMONY_SHARED_GLASS_PASS' in raw and 'All tests passed!' in raw:
            break
    time.sleep(1)
match = re.search(r'YANJI_HARMONY_SHARED_GLASS_PASS (\{[^\n]+\})', raw)
result = json.loads(match[1]) if match else {}
result.update({
    'executedAt': datetime.now().astimezone().isoformat(timespec='seconds'),
    'shaderCompilationErrors': raw.count('Shader compilation error'),
    'nativeAdvancedBlendErrors': raw.count("extension 'GL_KHR_blend_equation_advanced' is not supported"),
    'success': bool(match) and 'All tests passed!' in raw
        and 'Some tests failed.' not in raw and 'Shader compilation error' not in raw,
})
(logs/'result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
if not result['success']:
    raise SystemExit('Shared glass acceptance failed; inspect work/harmonyos/shared-glass/device.log.')
print('Shared glass acceptance passed; native shader compilation errors: 0.')
print('Runtime quality: '+result['quality']+'; full refraction verified: '+str(result['fullRefractionVerified']))
PY
