#!/usr/bin/env bash
set -euo pipefail

source /opt/gcc12-toolset/enable full

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat > "$work/pthread.c" <<'EOF'
#include <pthread.h>
static void *worker(void *value) {
    return value;
}
int main(void) {
    pthread_t thread;
    void *result = 0;
    int value = 42;
    if (pthread_create(&thread, 0, worker, &value) != 0) {
        return 1;
    }
    if (pthread_join(thread, &result) != 0) {
        return 1;
    }
    return result == &value ? 0 : 1;
}
EOF
gcc -O2 -Wall -Wextra -Werror -pthread \
    "$work/pthread.c" -o "$work/pthread"
"$work/pthread"

cat > "$work/openmp.c" <<'EOF'
#include <omp.h>
int main(void) {
    int threads = 0;
#pragma omp parallel reduction(+:threads)
    threads += 1;
    return threads > 0 ? 0 : 1;
}
EOF
gcc -O2 -Wall -Wextra -Werror -fopenmp \
    "$work/openmp.c" -o "$work/openmp"
ldd "$work/openmp" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib64/libgomp.so.1' >/dev/null
"$work/openmp"

cat > "$work/atomic.c" <<'EOF'
int main(void) {
    __int128 value = 0;
    __atomic_fetch_add(&value, 1, __ATOMIC_SEQ_CST);
    return value == 1 ? 0 : 1;
}
EOF
gcc -O2 -Wall -Wextra -Werror \
    "$work/atomic.c" -latomic -o "$work/atomic"
ldd "$work/atomic" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib64/libatomic.so.1' >/dev/null
"$work/atomic"

cat > "$work/graphite.c" <<'EOF'
void transpose(int size, double input[size][size], double output[size][size]) {
    for (int row = 0; row < size; ++row) {
        for (int column = 0; column < size; ++column) {
            output[column][row] = input[row][column];
        }
    }
}
EOF
gcc -O2 -Wall -Wextra -Werror \
    -fgraphite-identity -floop-nest-optimize \
    -c "$work/graphite.c" -o "$work/graphite.o"

cat > "$work/filesystem.cc" <<'EOF'
#include <filesystem>
int main() {
    return std::filesystem::path("/tmp").is_absolute() ? 0 : 1;
}
EOF
g++ -O2 -flto -std=c++17 -Wall -Wextra -Werror \
    "$work/filesystem.cc" -o "$work/filesystem"
readelf -S "$work/filesystem" | grep -F '.gnu.hash' >/dev/null
"$work/filesystem"

ld.gold --version | grep -F '2.36.1' >/dev/null
g++ -O2 -flto -fuse-ld=gold -std=c++17 -Wall -Wextra -Werror \
    "$work/filesystem.cc" -o "$work/filesystem-gold"
"$work/filesystem-gold"

cat > "$work/stacktrace.cc" <<'EOF'
#include <stacktrace>
int main() {
    const auto trace = std::stacktrace::current();
    return trace.size() <= trace.max_size() ? 0 : 1;
}
EOF
g++ -O2 -std=c++23 -Wall -Wextra -Werror \
    "$work/stacktrace.cc" -lstdc++_libbacktrace -o "$work/stacktrace"
"$work/stacktrace"

cat > "$work/sanitizer.c" <<'EOF'
#include <stdlib.h>
int main(void) {
    int *value = malloc(sizeof(*value));
    if (value == 0) {
        return 1;
    }
    *value = 42;
    int result = *value == 42 ? 0 : 1;
    free(value);
    return result;
}
EOF
gcc -O1 -g -Wall -Wextra -Werror \
    -fsanitize=address,undefined -fno-omit-frame-pointer \
    "$work/sanitizer.c" -o "$work/sanitizer"
ldd "$work/sanitizer" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib64/libasan.so.8' >/dev/null
ldd "$work/sanitizer" \
    | grep -F '/opt/gcc12-toolset/root/usr/lib64/libubsan.so.1' >/dev/null
ASAN_OPTIONS=detect_leaks=0 "$work/sanitizer"

printf 'Common GCC and C++ feature smoke tests passed.\n'
