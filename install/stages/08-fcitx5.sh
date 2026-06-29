#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=08
stage_init 08 fcitx5
pkg_install_fcitx5
print_timeshift_hint "08-fcitx5-ok"
stage_done "fcitx5 --version 2>/dev/null || dpkg -l fcitx5 2>/dev/null | tail -1" "im-config 选择 Fcitx 5 后注销"
