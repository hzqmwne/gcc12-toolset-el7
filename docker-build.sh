#!/usr/bin/env bash
set -euo pipefail

ROOT=/workspace
TOPDIR=/build/rpmbuild
OUT=/out
CACHE=/cache
JOBS=${BUILD_JOBS:-8}

mkdir -p "$TOPDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS} "$OUT"
"$ROOT/fetch-sources.sh" "$CACHE"

cp -a "$ROOT/rpm/SOURCES/." "$TOPDIR/SOURCES/"
cp -a "$ROOT/rpm/SPECS/." "$TOPDIR/SPECS/"
cp -a "$CACHE/gcc-12.2.1-20221121.tar.xz" "$TOPDIR/SOURCES/"
cp -a "$CACHE/binutils-2.36.1.tar.xz" "$TOPDIR/SOURCES/"
cp -a "$CACHE/gcc12-libstdc++-compat.patch" "$TOPDIR/SOURCES/"

rpmbuild --define "_topdir $TOPDIR" -ba "$TOPDIR/SPECS/gcc12-toolset-runtime.spec"
rpm -Uvh "$TOPDIR"/RPMS/noarch/gcc12-toolset-runtime-*.rpm

rpmbuild --define "_topdir $TOPDIR" --define "_smp_mflags -j$JOBS" \
    -ba "$TOPDIR/SPECS/gcc12-toolset-binutils.spec"
rpm -Uvh "$TOPDIR"/RPMS/x86_64/gcc12-toolset-binutils-*.rpm

rpmbuild --define "_topdir $TOPDIR" --define "_smp_mflags -j$JOBS" \
    -ba "$TOPDIR/SPECS/gcc12-toolset-gcc.spec"

rm -rf "$OUT"/RPMS "$OUT"/SRPMS
mkdir -p "$OUT"/RPMS "$OUT"/SRPMS
find "$TOPDIR/RPMS" -type f -name '*.rpm' -exec cp -a {} "$OUT/RPMS/" \;
find "$TOPDIR/SRPMS" -type f -name '*.src.rpm' -exec cp -a {} "$OUT/SRPMS/" \;
cp -a "$CACHE/SHA256SUMS.generated" "$OUT/"
(
    cd "$OUT"
    find RPMS SRPMS -type f -name '*.rpm' -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS.rpms
)

printf 'Build completed. Binary packages: %s/RPMS\n' "$OUT"
