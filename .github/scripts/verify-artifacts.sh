#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
IMAGE=${1:-gcc12-toolset-consumer-test:centos7}

find "$ROOT/out/RPMS" -type f -name '*.rpm' -print -quit | grep -q .

docker build \
    --file "$ROOT/.github/containers/centos7-consumer.Dockerfile" \
    --tag "$IMAGE" \
    "$ROOT/.github/containers"

docker run --rm \
    --volume "$ROOT/out:/out" \
    --volume "$ROOT/tests:/workspace/tests:ro" \
    "$IMAGE" \
    -c '
        set -euo pipefail
        for package in gcc gcc-c++; do
            if rpm -q "$package"; then
                printf "Consumer image unexpectedly contains %s\n" "$package" >&2
                exit 1
            fi
        done
        yum -y --disablerepo="*" localinstall /out/RPMS/*.rpm
        /workspace/tests/check-rpm-isolation.sh
        /workspace/tests/check-abi.sh
        /workspace/tests/smoke-profiles.sh
        /workspace/tests/smoke-runtime.sh

        work=$(mktemp -d)
        trap "rm -rf \"\$work\"" EXIT
        cat > "$work/hello.c" <<EOF
#include <stdio.h>
int main(void) {
    puts("clean CentOS 7 C compile passed");
    return 0;
}
EOF
        source /opt/gcc12-toolset/enable full
        [[ $(command -v gcc) == /opt/gcc12-toolset/root/usr/bin/gcc ]]
        gcc -Wall -Wextra -Werror "$work/hello.c" -o "$work/hello"
        "$work/hello"

        rpm -qa "gcc12-toolset-*" | LC_ALL=C sort > /out/installed-packages.txt
    '
