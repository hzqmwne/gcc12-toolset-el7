#!/usr/bin/env bash
set -euo pipefail

binutils_package=gcc12-toolset-binutils
full_runtime_package=gcc12-toolset-libstdc++
binutils_libdir=/opt/gcc12-toolset/root/usr/lib64/binutils
private_binutils_soname='^lib(bfd|opcodes|ctf|ctf-nobfd)(-[0-9.]+)?\.so'
private_gcc_soname='^lib(asan|atomic|cc1|cc1plugin|cp1plugin|gcc_s|gomp|isl|itm|lsan|quadmath|ssp|stdc\+\+|tsan|ubsan)\.so'

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

check_gcc_requirement() {
    local package=$1 requirement providers

    while IFS= read -r requirement; do
        [[ $requirement =~ $private_gcc_soname ]] || continue

        # libgcc_s and libstdc++ are valid ABI dependencies when the base EL7
        # packages provide them. The private copies are excluded from RPM
        # provides, so only reject either capability if a toolset RPM provides it.
        case "$requirement" in
            libgcc_s.so.*|libstdc++.so.*)
                providers=$(rpm -q --whatprovides "$requirement" 2>/dev/null || :)
                if grep -q '^gcc12-toolset-' <<<"$providers"; then
                    printf '%s requires a private GCC runtime capability: %s\n' \
                        "$package" "$requirement" >&2
                    exit 1
                fi
                ;;
            *)
                printf '%s has an unresolved public dependency on a private GCC library: %s\n' \
                    "$package" "$requirement" >&2
                exit 1
                ;;
        esac
    done < <(rpm -q --requires "$package")
}

while IFS= read -r package; do
    check_gcc_requirement "$package"
    if rpm -q --provides "$package" \
        | grep -E "$private_gcc_soname" >/dev/null; then
        printf '%s exposes a private GCC runtime as a system RPM capability\n' \
            "$package" >&2
        exit 1
    fi
done < <(rpm -qa --qf '%{NAME}\n' 'gcc12-toolset-*')

printf 'Private RPM dependencies and capabilities remain isolated.\n'
