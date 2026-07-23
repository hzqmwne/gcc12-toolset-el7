#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE=${IMAGE:-gcc12-toolset-rpm-builder:centos7}
JOBS=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '8')}

usage() {
    cat <<'EOF'
Usage: ./build-rpms.sh [--jobs N] [--image NAME] [--rebuild-image]

Builds gcc12-toolset RPMs in a CentOS 7.9 Docker container.
Outputs are written to ./out and downloaded sources to ./cache.
EOF
}

REBUILD_IMAGE=0
while (($#)); do
    case "$1" in
        --jobs) JOBS=$2; shift 2 ;;
        --image) IMAGE=$2; shift 2 ;;
        --rebuild-image) REBUILD_IMAGE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

command -v docker >/dev/null 2>&1 || {
    printf 'docker is required\n' >&2
    exit 1
}

mkdir -p "$ROOT/cache" "$ROOT/out"

if [[ $REBUILD_IMAGE -eq 1 ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker build --build-arg "BUILD_JOBS=$JOBS" --tag "$IMAGE" "$ROOT"
fi

docker run --rm \
    --volume "$ROOT/cache:/cache" \
    --volume "$ROOT/out:/out" \
    --env "BUILD_JOBS=$JOBS" \
    "$IMAGE"

printf 'RPMs are available in %s/out\n' "$ROOT"
