#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEST=${1:-"$ROOT/cache"}
# shellcheck source=sources.lock.sh
source "$ROOT/sources.lock.sh"

mkdir -p "$DEST"

fetch_one() {
    local name=$1
    local sha1=$2
    shift 2
    local output="$DEST/$name"
    local temporary="$output.part"
    local url

    if [[ -f "$output" ]] && printf '%s  %s\n' "$sha1" "$output" | sha1sum -c - >/dev/null 2>&1; then
        printf 'Using cached %s\n' "$name"
        return
    fi

    rm -f "$temporary"
    for url in "$@"; do
        printf 'Downloading %s from %s\n' "$name" "$url"
        if curl --fail --location --retry 5 --retry-delay 3 --connect-timeout 30 \
            --proto '=https' --tlsv1.2 --output "$temporary" "$url"; then
            if printf '%s  %s\n' "$sha1" "$temporary" | sha1sum -c -; then
                mv -f "$temporary" "$output"
                return
            fi
            printf 'Checksum verification failed for %s from %s\n' \
                "$name" "$url" >&2
        else
            printf 'Download failed for %s from %s; trying next URL\n' \
                "$name" "$url" >&2
        fi
        rm -f "$temporary"
    done

    printf 'Unable to download a verified copy of %s\n' "$name" >&2
    return 1
}

fetch_sha256() {
    local name=$1
    local sha256=$2
    shift 2
    local output="$DEST/$name"
    local temporary="$output.part"
    local url

    if [[ -f "$output" ]] && printf '%s  %s\n' "$sha256" "$output" | sha256sum -c - >/dev/null 2>&1; then
        printf 'Using cached %s\n' "$name"
        return
    fi

    rm -f "$temporary"
    for url in "$@"; do
        printf 'Downloading %s from %s\n' "$name" "$url"
        if curl --fail --location --retry 5 --retry-delay 3 --connect-timeout 30 \
            --proto '=https' --tlsv1.2 --output "$temporary" "$url"; then
            if printf '%s  %s\n' "$sha256" "$temporary" | sha256sum -c -; then
                mv -f "$temporary" "$output"
                return
            fi
            printf 'Checksum verification failed for %s from %s\n' \
                "$name" "$url" >&2
        else
            printf 'Download failed for %s from %s; trying next URL\n' \
                "$name" "$url" >&2
        fi
        rm -f "$temporary"
    done

    printf 'Unable to download a verified copy of %s\n' "$name" >&2
    return 1
}

fetch_one "$GCC_SOURCE" "$GCC_SHA1" "$GCC_URL" "$GCC_FALLBACK_URL"
fetch_one "$BINUTILS_SOURCE" "$BINUTILS_SHA1" \
    "$BINUTILS_URL" "$BINUTILS_FALLBACK_URL"
fetch_sha256 "$LIBSTDCXX_COMPAT_PATCH" "$LIBSTDCXX_COMPAT_PATCH_SHA256" \
    "$LIBSTDCXX_COMPAT_PATCH_URL" "$LIBSTDCXX_COMPAT_PATCH_FALLBACK_URL"

(
    cd "$DEST"
    sha256sum "$GCC_SOURCE" "$BINUTILS_SOURCE" "$LIBSTDCXX_COMPAT_PATCH" \
        > SHA256SUMS.generated
)

printf 'Sources are ready in %s\n' "$DEST"
printf 'Generated local SHA-256 manifest: %s\n' "$DEST/SHA256SUMS.generated"
