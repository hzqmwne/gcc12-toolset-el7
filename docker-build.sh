#!/usr/bin/env bash
set -euo pipefail

ROOT=/workspace
STAGE=${BUILD_STAGE:-}

case "$STAGE" in
    prerequisites) exec "$ROOT/scripts/rpm-stage-prerequisites.sh" ;;
    gcc) exec "$ROOT/scripts/rpm-stage-gcc.sh" ;;
    *)
        printf 'BUILD_STAGE must be prerequisites or gcc, got: %s\n' "$STAGE" >&2
        exit 2
        ;;
esac
