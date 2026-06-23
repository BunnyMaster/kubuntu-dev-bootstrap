#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=03
stage_init 03 system
pkg_install_system_extras
stage_done "fcitx5 --version 2>/dev/null || dpkg -l fcitx5 2>/dev/null | tail -1" "vlc --version 2>/dev/null | head -1"
