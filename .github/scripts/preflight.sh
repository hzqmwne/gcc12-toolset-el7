#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

if command -v python3 >/dev/null 2>&1; then
    PYTHON=python3
elif command -v python >/dev/null 2>&1; then
    PYTHON=python
else
    printf 'python3 or python is required for preflight checks\n' >&2
    exit 1
fi

"$PYTHON" .github/scripts/check-repository.py

while IFS= read -r -d '' script; do
    bash -n "$script"
done < <(find . -path './.git' -prune -o -name '*.sh' -print0)

./build-rpms.sh --help >/dev/null

printf 'Preflight checks passed.\n'
