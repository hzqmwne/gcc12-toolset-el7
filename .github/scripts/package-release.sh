#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
DIST="$ROOT/dist"
OUT="$ROOT/out"
ARCHIVE="gcc12-toolset-el7-${VERSION}-x86_64.tar.gz"

[[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
    printf 'Invalid VERSION: %s\n' "$VERSION" >&2
    exit 1
}

if [[ ${GITHUB_REF_TYPE:-} == tag && ${GITHUB_REF_NAME:-} != "v$VERSION" ]]; then
    printf 'Tag %s does not match VERSION v%s\n' "${GITHUB_REF_NAME:-}" "$VERSION" >&2
    exit 1
fi

test -s "$OUT/SHA256SUMS.rpms"
find "$OUT/RPMS" -type f -name '*.rpm' -print -quit | grep -q .
find "$OUT/SRPMS" -type f -name '*.src.rpm' -print -quit | grep -q .

rm -rf "$DIST"
mkdir -p "$DIST/package"
cp -a "$OUT/RPMS" "$OUT/SRPMS" "$DIST/package/"
cp -a "$OUT/SHA256SUMS.generated" "$OUT/SHA256SUMS.rpms" "$DIST/package/"
cp -a "$ROOT/README.md" "$ROOT/BUILD.md" "$ROOT/COMPATIBILITY.md" \
    "$ROOT/CHANGELOG.md" "$ROOT/VERSION" "$DIST/package/"

SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-$(git -C "$ROOT" show -s --format=%ct HEAD)}
export SOURCE_DATE_EPOCH
{
    printf 'toolset_version=%s\n' "$VERSION"
    printf 'git_commit=%s\n' "$(git -C "$ROOT" rev-parse HEAD)"
    printf 'source_date_epoch=%s\n' "$SOURCE_DATE_EPOCH"
    printf 'architecture=x86_64\n'
    printf 'build_environment=CentOS 7.9.2009\n'
} > "$DIST/package/BUILD-INFO.txt"

tar --sort=name \
    --mtime="@$SOURCE_DATE_EPOCH" \
    --owner=0 --group=0 --numeric-owner \
    -C "$DIST/package" -czf "$DIST/$ARCHIVE" .

cp -a "$OUT"/RPMS/*.rpm "$OUT"/SRPMS/*.src.rpm "$DIST/"

(
    cd "$DIST"
    LC_ALL=C sha256sum "$ARCHIVE" *.rpm > SHA256SUMS
)

printf 'Release archive: %s\n' "$DIST/$ARCHIVE"
