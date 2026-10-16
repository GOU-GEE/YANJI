#!/usr/bin/env bash
# Run the pinned HarmonyOS SDK without changing global Flutter settings.
set -euo pipefail
source "$(dirname "$0")/harmonyos_env.sh"
cd "$project_root"
exec "$flutter_sdk/bin/flutter" "$@"
