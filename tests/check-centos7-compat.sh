#!/usr/bin/env bash
set -euo pipefail

if (($# != 1)); then
    printf 'Usage: %s BINARY\n' "$0" >&2
    exit 2
fi

binary=$1
test -r "$binary"

printf '%s\n' 'Dynamic dependencies:'
readelf -d "$binary" | grep NEEDED || true

versions=$(readelf --version-info "$binary" 2>/dev/null || true)
if printf '%s\n' "$versions" | grep -qE 'GLIBCXX_|CXXABI_'; then
    printf 'C++ runtime remains dynamically versioned:\n' >&2
    printf '%s\n' "$versions" | grep -oE 'GLIBCXX_[0-9.]+|CXXABI_[0-9.]+' | sort -Vu >&2
    exit 1
fi

bad_glibc=$(printf '%s\n' "$versions" | grep -oE 'GLIBC_[0-9.]+' | sort -Vu \
    | awk -F_ '$2 != "PRIVATE"' \
    | while read -r symbol; do
        version=${symbol#GLIBC_}
        if [[ $(printf '%s\n2.17\n' "$version" | sort -V | tail -n1) != 2.17 ]]; then
            printf '%s\n' "$symbol"
        fi
      done)

if [[ -n "$bad_glibc" ]]; then
    printf 'Requires symbols newer than CentOS 7 GLIBC_2.17:\n%s\n' "$bad_glibc" >&2
    exit 1
fi

printf 'No dynamic GLIBCXX/CXXABI requirements and no GLIBC requirement above 2.17.\n'
