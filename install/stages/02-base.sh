#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=02
stage_init 02 base
pkg_install_base
print_timeshift_hint "02-base-ready"
stage_done "timeshift --version" "git --version" "htop --version 2>/dev/null || true"
