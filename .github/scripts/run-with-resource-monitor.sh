#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
LOG="$ROOT/out/ci/build.log"
SAMPLES="$ROOT/out/ci/resource-samples.log"
INTERVAL=${RESOURCE_SAMPLE_INTERVAL:-15}

(( $# > 0 )) || {
    printf 'Usage: %s COMMAND [ARG...]\n' "$0" >&2
    exit 2
}

mkdir -p "$ROOT/out/ci"
: > "$SAMPLES"

monitor() {
    local watched_pid=$1

    while kill -0 "$watched_pid" 2>/dev/null; do
        {
            printf 'timestamp=%s\n' "$(date --iso-8601=seconds)"
            free -b || true
            docker stats --no-stream \
                --format 'container={{.Name}} cpu={{.CPUPerc}} memory={{.MemUsage}} memory_percent={{.MemPerc}}' \
                2>/dev/null || true
            printf '\n'
        } >> "$SAMPLES"
        sleep "$INTERVAL"
    done
}

set +e
set -o pipefail
"$@" 2>&1 | tee "$LOG" &
command_pid=$!
monitor "$command_pid" &
monitor_pid=$!

wait "$command_pid"
status=$?
kill "$monitor_pid" 2>/dev/null || true
wait "$monitor_pid" 2>/dev/null || true
set -e

exit "$status"
