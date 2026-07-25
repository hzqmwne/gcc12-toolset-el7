#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=${ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}
TOPDIR=${TOPDIR:-/build/rpmbuild}
OUT=${OUT:-/out}
CACHE=${CACHE:-/cache}
JOBS=${BUILD_JOBS:-8}

prepare_rpmbuild() {
    mkdir -p "$TOPDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS} "$OUT"
    "$ROOT/fetch-sources.sh" "$CACHE"

    cp -a "$ROOT/rpm/SOURCES/." "$TOPDIR/SOURCES/"
    cp -a "$ROOT/rpm/SPECS/." "$TOPDIR/SPECS/"
    cp -a "$CACHE/gcc-12.2.1-20221121.tar.xz" "$TOPDIR/SOURCES/"
    cp -a "$CACHE/isl-0.24.tar.bz2" "$TOPDIR/SOURCES/"
    cp -a "$CACHE/binutils-2.36.1.tar.xz" "$TOPDIR/SOURCES/"
    cp -a "$CACHE/make-4.3.tar.gz" "$TOPDIR/SOURCES/"
    cp -a "$CACHE/gcc12-libstdc++-compat.patch" "$TOPDIR/SOURCES/"
}

build_runtime() {
    rpmbuild --define "_topdir $TOPDIR" -ba "$TOPDIR/SPECS/gcc12-toolset-runtime.spec"
}

build_binutils() {
    rpmbuild --define "_topdir $TOPDIR" --define "_smp_mflags -j$JOBS" \
        -ba "$TOPDIR/SPECS/gcc12-toolset-binutils.spec"
}

build_make() {
    rpmbuild --define "_topdir $TOPDIR" --define "_smp_mflags -j$JOBS" \
        -ba "$TOPDIR/SPECS/gcc12-toolset-make.spec"
}

build_gcc() {
    rpmbuild --define "_topdir $TOPDIR" --define "_smp_mflags -j$JOBS" \
        -ba "$TOPDIR/SPECS/gcc12-toolset-gcc.spec"
}

install_prerequisite() {
    local package=$1 rpm_path

    rpm_path=$(find "$TOPDIR/RPMS" -type f -name "$package-*.rpm" \
        ! -name '*.src.rpm' -print -quit)
    [[ -n $rpm_path ]] || {
        printf 'Missing prerequisite RPM: %s\n' "$package" >&2
        exit 1
    }
    rpm -Uvh "$rpm_path"
}

install_prerequisites() {
    install_prerequisite gcc12-toolset-runtime
    install_prerequisite gcc12-toolset-binutils
}

import_seed_rpms() {
    local seed_dir=$1 rpm_path imported=0

    [[ -d $seed_dir ]] || {
        printf 'Prerequisite RPM directory is unavailable: %s\n' "$seed_dir" >&2
        exit 1
    }
    while IFS= read -r -d '' rpm_path; do
        case "$rpm_path" in
            *.src.rpm) cp -a "$rpm_path" "$TOPDIR/SRPMS/" ;;
            *) cp -a "$rpm_path" "$TOPDIR/RPMS/" ;;
        esac
        imported=1
    done < <(find "$seed_dir" -type f -name '*.rpm' -print0)
    ((imported)) || {
        printf 'No prerequisite RPMs found in: %s\n' "$seed_dir" >&2
        exit 1
    }
    install_prerequisites
}

export_rpms() {
    rm -rf "$OUT"/RPMS "$OUT"/SRPMS
    mkdir -p "$OUT"/RPMS "$OUT"/SRPMS
    find "$TOPDIR/RPMS" -type f -name '*.rpm' -exec cp -a {} "$OUT/RPMS/" \;
    find "$TOPDIR/SRPMS" -type f -name '*.src.rpm' -exec cp -a {} "$OUT/SRPMS/" \;
    cp -a "$CACHE/SHA256SUMS.generated" "$OUT/"
    (
        cd "$OUT"
        find RPMS SRPMS -type f -name '*.rpm' -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.rpms
    )
}
