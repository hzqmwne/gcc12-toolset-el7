#!/usr/bin/env bash
set -euo pipefail

GXX=${GXX:-/opt/gcc12-toolset/root/usr/bin/g++}
LIB=${LIBSTDCXX:-/opt/gcc12-toolset/root/usr/lib64/libstdc++.so.6}

test -x "$GXX"
test -r "$LIB"

macros=$(printf '#include <bits/c++config.h>\n' | "$GXX" -dM -E -x c++ -)
printf '%s\n' "$macros" | grep -Fxc '#define _GLIBCXX_USE_DUAL_ABI 1' >/dev/null
printf '%s\n' "$macros" | grep -Fxc '#define _GLIBCXX_USE_CXX11_ABI 1' >/dev/null

strings "$LIB" | grep -Fxc 'GLIBCXX_3.4.30' >/dev/null
strings "$LIB" | grep -Fxc 'CXXABI_1.3.13' >/dev/null

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cat > "$work/abi.cc" <<'EOF'
#include <string>
void abi_probe(const std::string&) {}
EOF

"$GXX" -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 -c "$work/abi.cc" -o "$work/abi0.o"
"$GXX" -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=1 -c "$work/abi.cc" -o "$work/abi1.o"

nm -C "$work/abi0.o" | grep -F 'abi_probe(std::string const&)' >/dev/null
nm -C "$work/abi1.o" | grep -F 'abi_probe(std::__cxx11::basic_string' >/dev/null

printf 'Dual ABI and default C++11 ABI checks passed.\n'
