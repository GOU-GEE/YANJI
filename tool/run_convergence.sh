#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
profile="${1:-pr}"
if [[ $# -gt 0 ]]; then shift; fi
case "$profile" in
  pr|extended|soak) ;;
  *) echo 'Usage: tool/run_convergence.sh [pr|extended|soak] [flutter test options]' >&2; exit 2 ;;
esac
export YANJI_CONVERGENCE_PROFILE="$profile"
exec .tooling/flutter/bin/flutter test test/convergence --reporter expanded "$@"
