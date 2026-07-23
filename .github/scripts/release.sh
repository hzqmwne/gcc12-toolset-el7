#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
TAG=${GITHUB_REF_NAME:-}

[[ ${GITHUB_REF_TYPE:-} == tag && $TAG == "v$VERSION" ]] || {
    printf 'Release requires tag v%s; got %s\n' "$VERSION" "${TAG:-<none>}" >&2
    exit 1
}

mapfile -t assets < <(find "$ROOT/dist" -maxdepth 1 -type f \
    \( -name '*.tar.gz' -o -name 'SHA256SUMS' \) -print | LC_ALL=C sort)
(( ${#assets[@]} >= 2 )) || {
    printf 'Release assets are missing\n' >&2
    exit 1
}

if gh release view "$TAG" >/dev/null 2>&1; then
    printf 'Release %s already exists; refusing to mutate published assets.\n' "$TAG" >&2
    exit 1
fi

prerelease=()
if [[ $VERSION == 0.* ]]; then
    prerelease=(--prerelease)
fi

gh release create "$TAG" "${assets[@]}" \
    --verify-tag \
    --generate-notes \
    --title "gcc12-toolset-el7 $TAG" \
    "${prerelease[@]}"
