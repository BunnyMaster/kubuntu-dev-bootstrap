#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=05
stage_init 05 installers

set +e
gui_install_all
gui_exit=$?
set -e

print_timeshift_hint "05-installers-ok"
stage_done \
  "ls $DOTFILES_DIR/installers/deb/*.deb 2>/dev/null || echo '无 deb'" \
  "ls $APPIMAGES_DIR 2>/dev/null || echo '无 AppImage'" \
  "ls /opt/jetbrains-toolbox-* 2>/dev/null || ls $DOTFILES_DIR/installers/tar/*.tar.gz 2>/dev/null || echo '无 tar'"

if [[ "$gui_exit" -ne 0 ]]; then
  warn "installers 返回非零 ($gui_exit)，请查看上方汇总"
fi
