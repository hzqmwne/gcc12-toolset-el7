#!/usr/bin/env bash
set -euo pipefail

source /opt/gcc12-toolset/enable full
[[ $GCC12_TOOLSET_PROFILE == full ]]
[[ $CXX == /opt/gcc12-toolset/root/usr/bin/g++ ]]
[[ :$LD_LIBRARY_PATH: == *:/opt/gcc12-toolset/root/usr/lib64/binutils:* ]]
[[ :$LD_LIBRARY_PATH: == *:/opt/gcc12-toolset/root/usr/lib64:* ]]
[[ :$LD_LIBRARY_PATH: == *:/opt/gcc12-toolset/root/usr/lib:* ]]
"$CXX" --version | grep -F '12.2.1' >/dev/null
ld --version | grep -F '2.36.1' >/dev/null

source /opt/gcc12-toolset/enable compat
[[ $GCC12_TOOLSET_PROFILE == compat ]]
[[ $CXX == /opt/gcc12-toolset/profiles/compat/bin/g++ ]]
[[ $(command -v g++) == /opt/gcc12-toolset/profiles/compat/bin/g++ ]]
[[ :$LD_LIBRARY_PATH: == *:/opt/gcc12-toolset/root/usr/lib64/binutils:* ]]
[[ :$LD_LIBRARY_PATH: != *:/opt/gcc12-toolset/root/usr/lib64:* ]]
[[ :$LD_LIBRARY_PATH: != *:/opt/gcc12-toolset/root/usr/lib:* ]]
ld --version | grep -F '2.36.1' >/dev/null

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cat > "$work/probe.cc" <<'EOF'
#include <string>
#include <iostream>
int main() {
    std::string value("compat");
    std::cout << value << '\n';
    return 0;
}
EOF

g++ -std=c++11 "$work/probe.cc" -o "$work/compat"
"$work/compat"

readelf -d "$work/compat" | grep -F 'libstdc++.so.6' >/dev/null
if ldd "$work/compat" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib64/libstdc++.so.6' >/dev/null; then
    printf 'compat probe loaded the full private libstdc++ runtime\n' >&2
    exit 1
fi
bad_glibcxx=$(readelf --version-info "$work/compat" | grep -oE 'GLIBCXX_[0-9.]+' \
    | sort -Vu | while read -r symbol; do
        version=${symbol#GLIBCXX_}
        if [[ $(printf '3.4.19\n%s\n' "$version" | sort -V | tail -n1) != 3.4.19 ]]; then
            printf '%s\n' "$symbol"
        fi
      done)
if [[ -n "$bad_glibcxx" ]]; then
    printf 'compat probe requires symbols newer than GLIBCXX_3.4.19:\n%s\n' \
        "$bad_glibcxx" >&2
    exit 1
fi

if nm -C "$work/compat" | grep -F 'std::__cxx11' >/dev/null; then
    printf 'compat probe unexpectedly contains new C++11 ABI symbols\n' >&2
    exit 1
fi

source /opt/gcc12-toolset/enable full
[[ $(command -v g++) == /opt/gcc12-toolset/root/usr/bin/g++ ]]
printf 'Full/compat profile and in-place source activation tests passed.\n'
