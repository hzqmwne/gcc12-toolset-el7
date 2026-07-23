#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEST=${1:-"$ROOT/cache"}
# shellcheck source=sources.lock.sh
source "$ROOT/sources.lock.sh"

mkdir -p "$DEST"

fetch_one() {
    local name=$1
    local url=$2
    local sha1=$3
    local output="$DEST/$name"
    local temporary="$output.part"

    if [[ -f "$output" ]] && printf '%s  %s\n' "$sha1" "$output" | sha1sum -c - >/dev/null 2>&1; then
        printf 'Using cached %s\n' "$name"
        return
    fi

    rm -f "$temporary"
    curl --fail --location --retry 5 --retry-delay 3 --proto '=https' --tlsv1.2 \
        --output "$temporary" "$url"
    printf '%s  %s\n' "$sha1" "$temporary" | sha1sum -c -
    mv -f "$temporary" "$output"
}

fetch_sha256() {
    local name=$1
    local url=$2
    local sha256=$3
    local output="$DEST/$name"
    local temporary="$output.part"

    if [[ -f "$output" ]] && printf '%s  %s\n' "$sha256" "$output" | sha256sum -c - >/dev/null 2>&1; then
        printf 'Using cached %s\n' "$name"
        return
    fi

    rm -f "$temporary"
    curl --fail --location --retry 5 --retry-delay 3 --proto '=https' --tlsv1.2 \
        --output "$temporary" "$url"
    printf '%s  %s\n' "$sha256" "$temporary" | sha256sum -c -
    mv -f "$temporary" "$output"
}

fetch_one "$GCC_SOURCE" "$GCC_URL" "$GCC_SHA1"
fetch_one "$BINUTILS_SOURCE" "$BINUTILS_URL" "$BINUTILS_SHA1"
fetch_sha256 "$LIBSTDCXX_COMPAT_PATCH" "$LIBSTDCXX_COMPAT_PATCH_URL" \
    "$LIBSTDCXX_COMPAT_PATCH_SHA256"

(
    cd "$DEST"
    sha256sum "$GCC_SOURCE" "$BINUTILS_SOURCE" "$LIBSTDCXX_COMPAT_PATCH" \
        > SHA256SUMS.generated
)

printf 'Sources are ready in %s\n' "$DEST"
printf 'Generated local SHA-256 manifest: %s\n' "$DEST/SHA256SUMS.generated"
