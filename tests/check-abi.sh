#!/usr/bin/env bash
set -euo pipefail

GXX=${GXX:-/opt/gcc12-toolset/root/usr/bin/g++}
LIB=${LIBSTDCXX:-/opt/gcc12-toolset/root/usr/lib64/libstdc++.so.6}

test -x "$GXX"
test -r "$LIB"

macros=$(printf '#include <bits/c++config.h>\n' | "$GXX" -dM -E -x c++ -)
printf '%s\n' "$macros" | grep -q '^#define _GLIBCXX_USE_DUAL_ABI 1$'
printf '%s\n' "$macros" | grep -q '^#define _GLIBCXX_USE_CXX11_ABI 1$'

strings "$LIB" | grep -qx 'GLIBCXX_3.4.30'
strings "$LIB" | grep -qx 'CXXABI_1.3.13'

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cat > "$work/abi.cc" <<'EOF'
#include <string>
void abi_probe(const std::string&) {}
EOF

"$GXX" -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 -c "$work/abi.cc" -o "$work/abi0.o"
"$GXX" -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=1 -c "$work/abi.cc" -o "$work/abi1.o"

nm -C "$work/abi0.o" | grep -q 'abi_probe(std::string const&)'
nm -C "$work/abi1.o" | grep -q 'abi_probe(std::__cxx11::basic_string'

printf 'Dual ABI and default C++11 ABI checks passed.\n'
