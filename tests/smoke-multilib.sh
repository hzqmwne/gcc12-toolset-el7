#!/usr/bin/env bash
set -euo pipefail

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat > "$work/probe.c" <<'EOF'
#include <stdio.h>
int main(void) {
    puts("32-bit C");
    return 0;
}
EOF

cat > "$work/probe.cc" <<'EOF'
#include <iostream>
#include <string>
int main() {
    std::string value("32-bit C++");
    std::cout << value << '\n';
    return 0;
}
EOF

cat > "$work/openmp.c" <<'EOF'
#include <omp.h>
int main(void) {
    int threads = 0;
#pragma omp parallel reduction(+:threads)
    threads += 1;
    return threads > 0 ? 0 : 1;
}
EOF

/usr/bin/gcc -m32 -Wall -Wextra -Werror \
    "$work/probe.c" -o "$work/c-system"
"$work/c-system"

source /opt/gcc12-toolset/enable full
gcc -print-multi-lib | grep -E '^32;.*@m32$' >/dev/null
gcc -m32 -print-file-name=crtbegin.o | grep -E '/32/crtbegin\.o$' >/dev/null

gcc -m32 -flto -Wall -Wextra -Werror \
    "$work/probe.c" -o "$work/c-full"
readelf -h "$work/c-full" | grep -E 'Class:[[:space:]]+ELF32' >/dev/null
readelf -l "$work/c-full" | grep -F '/lib/ld-linux.so.2' >/dev/null
"$work/c-full"

gcc -m32 -fopenmp -Wall -Wextra -Werror \
    "$work/openmp.c" -o "$work/openmp-full"
ldd "$work/openmp-full" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib/libgomp.so.1' >/dev/null
"$work/openmp-full"

gcc -m32 -O1 -g -Wall -Wextra -Werror \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    "$work/probe.c" -o "$work/sanitizer-full"
ldd "$work/sanitizer-full" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib/libasan.so.8' >/dev/null
ASAN_OPTIONS=detect_leaks=0 "$work/sanitizer-full"

g++ -m32 -std=c++11 -Wall -Wextra -Werror \
    "$work/probe.cc" -o "$work/cxx-full"
readelf -h "$work/cxx-full" | grep -E 'Class:[[:space:]]+ELF32' >/dev/null
ldd "$work/cxx-full" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib/libstdc++.so.6' >/dev/null
"$work/cxx-full"

g++ -m32 -std=c++11 -Wall -Wextra -Werror \
    -static-libstdc++ -static-libgcc \
    "$work/probe.cc" -o "$work/cxx-static"
if readelf -d "$work/cxx-static" | grep -F 'libstdc++.so.6' >/dev/null; then
    printf '32-bit static C++ probe still needs libstdc++.so.6\n' >&2
    exit 1
fi

source /opt/gcc12-toolset/enable compat
"$work/cxx-static"
g++ -m32 -std=c++11 -Wall -Wextra -Werror \
    "$work/probe.cc" -o "$work/cxx-compat"
readelf -h "$work/cxx-compat" | grep -E 'Class:[[:space:]]+ELF32' >/dev/null
ldd "$work/cxx-compat" \
    | grep -E '/(usr/)?lib/libstdc\+\+\.so\.6' >/dev/null
if ldd "$work/cxx-compat" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib/libstdc++.so.6' >/dev/null; then
    printf '32-bit compat probe loaded the private libstdc++ runtime\n' >&2
    exit 1
fi
"$work/cxx-compat"

bad_glibcxx=$(readelf --version-info "$work/cxx-compat" \
    | grep -oE 'GLIBCXX_[0-9.]+' | sort -Vu | while read -r symbol; do
        version=${symbol#GLIBCXX_}
        if [[ $(printf '3.4.19\n%s\n' "$version" | sort -V | tail -n1) != 3.4.19 ]]; then
            printf '%s\n' "$symbol"
        fi
      done)
if [[ -n "$bad_glibcxx" ]]; then
    printf '32-bit compat probe requires symbols newer than GLIBCXX_3.4.19:\n%s\n' \
        "$bad_glibcxx" >&2
    exit 1
fi

printf 'Full and compat 32-bit multilib smoke tests passed.\n'
