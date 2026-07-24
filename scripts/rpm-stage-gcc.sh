#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/rpm-build-common.sh"

prepare_rpmbuild
import_seed_rpms /seed
build_gcc
export_rpms

printf 'GCC RPM build completed: %s/RPMS\n' "$OUT"
