#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=06
stage_init 06 nvidia

warn "安装前请确认:"
warn "  1. 已用 Timeshift 创建快照（建议阶段 04 后快照）"
warn "  2. BIOS 中已关闭 Secure Boot（推荐）"
warn "  3. 安装完成后必须重启"

if ! confirm "已做好快照并了解风险，继续？"; then
  log "已取消 NVIDIA 安装"
  exit 0
fi

pkg_install_nvidia_prereqs
pkg_run_ubuntu_drivers

print_timeshift_hint "06-nvidia-installed-reboot"
stage_done "重启后: nvidia-smi" "然后: ./setup.sh --preset dev（若尚未执行）"
