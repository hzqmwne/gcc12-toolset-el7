#!/usr/bin/env bash
set -euo pipefail

binutils_package=gcc12-toolset-binutils
full_runtime_package=gcc12-toolset-libstdc++
binutils_libdir=/opt/gcc12-toolset/root/usr/lib64/binutils
private_binutils_soname='^lib(bfd|opcodes|ctf|ctf-nobfd)(-[0-9.]+)?\.so'
private_gcc_soname='^lib(asan|atomic|cc1|cc1plugin|cp1plugin|gcc_s|gomp|itm|lsan|quadmath|ssp|stdc\+\+|tsan|ubsan)\.so'

test -r "$binutils_libdir/libbfd-2.36.1.so"
test ! -e /opt/gcc12-toolset/root/usr/lib64/libbfd-2.36.1.so

if rpm -q --requires "$binutils_package" \
    | grep -E "$private_binutils_soname" >/dev/null; then
    printf '%s has an unresolved public dependency on a private binutils library\n' \
        "$binutils_package" >&2
    exit 1
fi

if rpm -q --provides "$binutils_package" \
    | grep -E "$private_binutils_soname" >/dev/null; then
    printf '%s exposes a private binutils library as a system RPM capability\n' \
        "$binutils_package" >&2
    exit 1
fi

if rpm -q --provides "$full_runtime_package" \
    | grep -E '^lib(stdc\+\+|gcc_s)\.so' >/dev/null; then
    printf '%s exposes a private GCC runtime as a system RPM capability\n' \
        "$full_runtime_package" >&2
    exit 1
fi

while IFS= read -r package; do
    if rpm -q --requires "$package" \
        | grep -E "$private_gcc_soname" >/dev/null; then
        printf '%s has an unresolved public dependency on a private GCC library\n' \
            "$package" >&2
        exit 1
    fi
    if rpm -q --provides "$package" \
        | grep -E "$private_gcc_soname" >/dev/null; then
        printf '%s exposes a private GCC runtime as a system RPM capability\n' \
            "$package" >&2
        exit 1
    fi
done < <(rpm -qa --qf '%{NAME}\n' 'gcc12-toolset-*')

printf 'Private RPM dependencies and capabilities remain isolated.\n'
