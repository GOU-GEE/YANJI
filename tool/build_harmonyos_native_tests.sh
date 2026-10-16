#!/usr/bin/env bash
# Unsigned native test module for a disposable emulator.
set -euo pipefail
source "$(dirname "$0")/harmonyos_env.sh"
cd "$project_root"
python3 tool/prepare_harmonyos_native_tests.py
cd "$project_root/work/harmonyos/native-security-project"
ohpm install
hvigorw --mode module -p product=default -p module=entry@ohosTest \
  -p buildMode=debug --no-daemon assembleHap
artifact="$project_root/work/harmonyos/native-security-project/entry/build/default/outputs/ohosTest/entry-ohosTest-unsigned.hap"
[[ -f "$artifact" ]]
echo "Unsigned native test HAP: $artifact"
