#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=08
stage_init 08 git

if git_apply_from_config; then
  stage_done "git config --global user.name" "git config --global user.email"
else
  warn "Git 配置未完成，请在 config/config.env 中填写 GIT_USER_NAME / GIT_USER_EMAIL 后重试"
fi
