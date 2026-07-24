#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IMAGE=${IMAGE:-gcc12-toolset-rpm-builder:centos7}
JOBS=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '8')}

usage() {
    cat <<'EOF'
Usage: ./build-rpms.sh [--stage all|prerequisites|gcc] [--seed-dir DIR]
                       [--jobs N] [--image NAME] [--rebuild-image]

Builds gcc12-toolset RPMs in a CentOS 7.9 Docker container.
Outputs are written to ./out and downloaded sources to ./cache.

Stages:
  all            Run the prerequisite and GCC containers in sequence (default).
  prerequisites  Build runtime and binutils only.
  gcc            Build GCC using prerequisite RPMs from --seed-dir.
EOF
}

REBUILD_IMAGE=0
STAGE=all
SEED_DIR=
while (($#)); do
    case "$1" in
        --stage) STAGE=$2; shift 2 ;;
        --seed-dir) SEED_DIR=$2; shift 2 ;;
        --jobs) JOBS=$2; shift 2 ;;
        --image) IMAGE=$2; shift 2 ;;
        --rebuild-image) REBUILD_IMAGE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$STAGE" in
    all|prerequisites|gcc) ;;
    *) printf 'Unknown build stage: %s\n' "$STAGE" >&2; exit 2 ;;
esac

if [[ $STAGE == gcc ]]; then
    [[ -n $SEED_DIR ]] || {
        printf '%s\n' '--seed-dir is required for the gcc stage' >&2
        exit 2
    }
    SEED_DIR=$(cd "$SEED_DIR" && pwd)
fi

command -v docker >/dev/null 2>&1 || {
    printf 'docker is required\n' >&2
    exit 1
}

mkdir -p "$ROOT/cache" "$ROOT/out"

if [[ $REBUILD_IMAGE -eq 1 ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker build --build-arg "BUILD_JOBS=$JOBS" --tag "$IMAGE" "$ROOT"
fi

run_stage() {
    local stage=$1 seed_dir=${2:-}
    local -a docker_args=(
        run --rm
        --volume "$ROOT/cache:/cache"
        --volume "$ROOT/out:/out"
        --env "BUILD_JOBS=$JOBS"
        --env "BUILD_STAGE=$stage"
    )

    if [[ -n $seed_dir ]]; then
        docker_args+=(--volume "$seed_dir:/seed:ro")
    fi
    docker "${docker_args[@]}" "$IMAGE"
}

case "$STAGE" in
    all)
        run_stage prerequisites
        run_stage gcc "$ROOT/out"
        ;;
    prerequisites)
        run_stage prerequisites
        ;;
    gcc)
        run_stage gcc "$SEED_DIR"
        ;;
esac

printf '%s stage RPMs are available in %s/out\n' "$STAGE" "$ROOT"
