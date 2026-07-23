#!/usr/bin/env bash
set -euo pipefail

command -v gcc12-toolset >/dev/null 2>&1 || {
    printf 'Install gcc12-toolset RPMs first.\n' >&2
    exit 1
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/probe.cc" <<'EOF'
#include <iostream>
#include <string>
int main() {
    std::string value("gcc12-toolset");
    std::cout << value << " size=" << value.size() << '\n';
    return 0;
}
EOF

gcc12-toolset-full g++ -std=c++11 "$tmp/probe.cc" -o "$tmp/dynamic-full"
gcc12-toolset-full "$tmp/dynamic-full"

gcc12-toolset-full g++ -std=c++11 \
    -D_GLIBCXX_USE_CXX11_ABI=1 -static-libstdc++ -static-libgcc \
    "$tmp/probe.cc" -o "$tmp/static-cxx"
gcc12-toolset-compat "$tmp/static-cxx"

if readelf -d "$tmp/static-cxx" | grep -F 'libstdc++.so.6' >/dev/null; then
    printf 'static C++ probe still needs libstdc++.so.6\n' >&2
    exit 1
fi

printf 'Runtime smoke tests passed.\n'
