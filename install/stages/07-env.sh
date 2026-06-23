#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=07
stage_init 07 env

env_apply_from_config
stage_done "cat ~/.config/environment.d/99-dotfiles.conf 2>/dev/null || grep dotfiles /etc/environment.d/99-dotfiles.conf"
