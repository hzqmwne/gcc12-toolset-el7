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
        system_gcc=$(readlink -f /usr/bin/gcc)
        system_gxx=$(readlink -f /usr/bin/g++)
        system_gcc_owner=$(rpm -qf /usr/bin/gcc)
        system_gxx_owner=$(rpm -qf /usr/bin/g++)
        [[ $(gcc -dumpversion) == 4.8.5 ]]
        [[ $(g++ -dumpversion) == 4.8.5 ]]

        yum -y localinstall /out/RPMS/*.rpm

        [[ $(readlink -f /usr/bin/gcc) == "$system_gcc" ]]
        [[ $(readlink -f /usr/bin/g++) == "$system_gxx" ]]
        [[ $(rpm -qf /usr/bin/gcc) == "$system_gcc_owner" ]]
        [[ $(rpm -qf /usr/bin/g++) == "$system_gxx_owner" ]]
        [[ $(gcc -dumpversion) == 4.8.5 ]]
        [[ $(g++ -dumpversion) == 4.8.5 ]]
        rpm -V gcc gcc-c++

        gcc12-toolset-full gcc -dumpversion | grep -Fx 12
        gcc12-toolset-full g++ -dumpversion | grep -Fx 12
        [[ $(command -v gcc) == /usr/bin/gcc ]]
        [[ $(command -v g++) == /usr/bin/g++ ]]

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
        /usr/bin/gcc -Wall -Wextra -Werror \
            "$work/hello.c" -o "$work/hello-system"
        "$work/hello-system"

        source /opt/gcc12-toolset/enable full
        [[ $(command -v gcc) == /opt/gcc12-toolset/root/usr/bin/gcc ]]
        gcc -Wall -Wextra -Werror "$work/hello.c" -o "$work/hello-toolset"
        "$work/hello-toolset"

        [[ $(/usr/bin/gcc -dumpversion) == 4.8.5 ]]
        [[ $(/usr/bin/g++ -dumpversion) == 4.8.5 ]]

        rpm -qa "gcc12-toolset-*" | LC_ALL=C sort > /out/installed-packages.txt
    '
