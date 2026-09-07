#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter="${FLUTTER_BIN:-$PWD/.tooling/flutter/bin/flutter}"
lane="${1:-fast}"
if [[ $# -gt 0 ]]; then shift; fi
case "$lane" in
  fast) exec "$flutter" test test/core test/protocol "$@" ;;
  database) exec "$flutter" test test/database test/application "$@" ;;
  widget) exec "$flutter" test test/widget test/widget_test.dart "$@" ;;
  convergence) exec "$flutter" test test/convergence "$@" ;;
  all) exec "$flutter" test "$@" ;;
  *) echo 'Usage: tool/run_tests.sh fast|database|widget|convergence|all [flutter test arguments]' >&2; exit 2 ;;
esac
