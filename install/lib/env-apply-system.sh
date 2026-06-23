#!/usr/bin/env bash
# 以 root 写入系统级环境变量（由 env.sh 通过 sudo 调用）
set -euo pipefail

INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=core.sh
source "$INSTALL_DIR/lib/core.sh"

detect_dotfiles_dir "$INSTALL_DIR"
load_config
# shellcheck source=env.sh
source "$INSTALL_DIR/lib/env.sh"

env_write_system_scope
