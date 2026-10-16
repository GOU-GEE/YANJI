#!/usr/bin/env bash
# Build/run native security tests on an explicitly selected disposable emulator.
set -euo pipefail
source "$(dirname "$0")/harmonyos_env.sh"
device="${1:?Usage: tool/run_harmonyos_native_tests.sh <emulator-target>}"
hdc="$DEVECO_SDK_HOME/default/openharmony/toolchains/hdc"
[[ -x "$hdc" ]] || { echo "Official hdc not found: $hdc" >&2; exit 1; }
cd "$project_root"
logs="$project_root/work/harmonyos/native-security"
mkdir -p "$logs"
"$project_root/tool/build_harmonyos_native_tests.sh" > "$logs/build.log" 2>&1
artifact="$project_root/work/harmonyos/native-security-project/entry/build/default/outputs/ohosTest/entry-ohosTest-unsigned.hap"
"$hdc" -t "$device" install -r "$artifact" > "$logs/install.log" 2>&1
python3 - "$logs/install.log" <<'PY'
from pathlib import Path
import sys
if 'install bundle successfully' not in Path(sys.argv[1]).read_text():
    raise SystemExit('Native test HAP installation failed; inspect install.log.')
PY
"$hdc" -t "$device" shell aa test -b com.example.yanji.securitytests -m entry_test \
  -s unittest /ets/testrunner/OpenHarmonyTestRunner -s timeout 60000 > "$logs/results.log" 2>&1
# hdc / aa can return zero even when all tests error. Require the actual report.
python3 - "$logs/results.log" "$logs/result.json" <<'PY'
from datetime import datetime
from pathlib import Path
import json
import re
import sys
raw = Path(sys.argv[1]).read_text()
summary = re.search(r'Tests run: (\d+), Failure: (\d+), Error: (\d+), Pass: (\d+), Ignore: (\d+)', raw)
if not summary:
    raise SystemExit('Native tests did not produce a complete summary; inspect results.log.')
count, failed, errors, passed, ignored = map(int, summary.groups())
result = {
    'suite': 'YanjiHuksSecretStore',
    'executedAt': datetime.now().astimezone().isoformat(timespec='seconds'),
    'tests': count, 'passed': passed, 'failures': failed, 'errors': errors, 'ignored': ignored,
    'cases': list(dict.fromkeys(re.findall(r'^OHOS_REPORT_STATUS: test=(.+)$', raw, re.MULTILINE))),
    'success': count == 8 and passed == count and failed == errors == ignored == 0
        and 'user test finished.' in raw,
}
Path(sys.argv[2]).write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
print(summary.group())
if not result['success']:
    raise SystemExit('Native security acceptance failed; inspect results.log and result.json.')
print('Native security acceptance passed. Evidence: ' + sys.argv[2])
PY
