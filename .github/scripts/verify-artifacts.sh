#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
IMAGE=${1:?Usage: verify-artifacts.sh IMAGE}

find "$ROOT/out/RPMS" -type f -name '*.rpm' -print -quit | grep -q .

docker run --rm \
    --entrypoint /bin/bash \
    --volume "$ROOT/out:/out" \
    "$IMAGE" \
    -c '
        set -euo pipefail
        yum -y localinstall /out/RPMS/*.rpm
        /workspace/tests/check-abi.sh
        /workspace/tests/smoke-profiles.sh
        /workspace/tests/smoke-runtime.sh
        rpm -qa "gcc12-toolset-*" | LC_ALL=C sort > /out/installed-packages.txt
    '
