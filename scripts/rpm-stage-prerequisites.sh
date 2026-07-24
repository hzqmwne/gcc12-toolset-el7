#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/rpm-build-common.sh"

prepare_rpmbuild
build_runtime
install_prerequisite gcc12-toolset-runtime
build_binutils
export_rpms

printf 'Prerequisite RPM build completed: %s/RPMS\n' "$OUT"
