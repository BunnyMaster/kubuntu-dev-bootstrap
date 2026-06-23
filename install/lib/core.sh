#!/usr/bin/env bash
# shellcheck shell=bash
# 公共函数：日志、配置、发行版检测、stage 生命周期
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-}"
LIB_DIR="${LIB_DIR:-}"
DOTFILES_DIR="${DOTFILES_DIR:-}"
CONFIG_DIR="${CONFIG_DIR:-}"
RELEASE=""
OS_CODENAME=""

APPIMAGES_DIR="/opt/appimages"

declare -A PRESET_STAGES=(
  [base]="01,02,03"
  [dev]="05"
  [gpu]="06"
  [setup]="07,08"
)

log()  { printf '\033[1;32m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[dotfiles]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[dotfiles]\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

confirm() {
  local prompt="$1"
  if [[ "${YES:-0}" == "1" ]]; then
    return 0
  fi
  read -r -p "$prompt [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

detect_dotfiles_dir() {
  local install="${1:-$INSTALL_DIR}"
  if [[ -z "$install" ]]; then
    die "INSTALL_DIR 未设置"
  fi
  if git -C "$install" rev-parse --show-toplevel &>/dev/null; then
    DOTFILES_DIR="$(git -C "$install" rev-parse --show-toplevel)"
  else
    DOTFILES_DIR="$(cd "$install/.." && pwd)"
  fi
  CONFIG_DIR="$DOTFILES_DIR/config"
  export DOTFILES_DIR CONFIG_DIR
}

normalize_release() {
  local raw="${1,,}"
  case "$raw" in
    24|24.04) echo "24.04" ;;
    26|26.04) echo "26.04" ;;
    noble) echo "24.04" ;;
    resolute) echo "26.04" ;;
    "") echo "" ;;
    *) die "未知发行版: $1（可用: 24.04, 26.04）" ;;
  esac
}

release_to_codename() {
  case "$1" in
    24.04) echo "noble" ;;
    26.04) echo "resolute" ;;
    *) die "不支持的 RELEASE: $1" ;;
  esac
}

detect_os_release() {
  [[ -f /etc/os-release ]] || die "无法读取 /etc/os-release"
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in
    ubuntu|kubuntu) ;;
    *)
      die "仅支持 Ubuntu/Kubuntu（当前 ID=${ID:-未知}）"
      ;;
  esac
  OS_CODENAME="${VERSION_CODENAME:-}"
  [[ -n "$OS_CODENAME" ]] || die "无法从 /etc/os-release 读取 VERSION_CODENAME"

  case "${VERSION_ID:-}" in
    24.04|26.04) ;;
    *)
      die "不支持的 VERSION_ID=${VERSION_ID:-未知}（仅 24.04 / 26.04）"
      ;;
  esac
}

resolve_release() {
  local cli="${CLI_RELEASE:-}"
  local cfg
  cfg=$(normalize_release "${RELEASE:-}" 2>/dev/null || true)

  detect_os_release

  if [[ -n "$cli" ]]; then
    RELEASE="$cli"
    RELEASE_SPECIFIED=1
  elif [[ -n "$cfg" ]]; then
    RELEASE="$cfg"
    RELEASE_SPECIFIED=1
  else
    RELEASE="${VERSION_ID}"
    RELEASE_SPECIFIED=0
  fi

  case "$RELEASE" in
    24.04|26.04) ;;
    *) die "不支持的 RELEASE: $RELEASE" ;;
  esac

  if [[ "${RELEASE_SPECIFIED:-0}" == "1" && "$RELEASE" != "${VERSION_ID}" && "${ALLOW_MISMATCH:-0}" != "1" ]]; then
    die "RELEASE=$RELEASE 与系统 VERSION_ID=$VERSION_ID 不一致（可加 --allow-mismatch 强制）"
  fi

  export RELEASE OS_CODENAME
}

load_config() {
  local cfg="$CONFIG_DIR/config.env"
  if [[ -f "$cfg" ]]; then
    # shellcheck disable=SC1090
    source "$cfg"
  fi

  APT_MIRROR="${APT_MIRROR:-tuna}"
  APT_UPGRADE="${APT_UPGRADE:-1}"
  INSTALL_FCITX5="${INSTALL_FCITX5:-1}"
  ENV_SCOPE="${ENV_SCOPE:-user}"
  NODE_VERSION="${NODE_VERSION:-22}"
  NODE_VERSION_EXTRA="${NODE_VERSION_EXTRA:-18}"
  NRM_REGISTRY="${NRM_REGISTRY:-tencent}"
  NPM_GLOBAL_PACKAGES="${NPM_GLOBAL_PACKAGES:-}"
  JAVA_17_IDENTIFIER="${JAVA_17_IDENTIFIER:-17.0.14-tem}"
  JAVA_21_IDENTIFIER="${JAVA_21_IDENTIFIER:-21.0.6-tem}"
  INSTALL_MAVEN="${INSTALL_MAVEN:-1}"
  INSTALL_DOCKER="${INSTALL_DOCKER:-1}"
  GIT_USER_NAME="${GIT_USER_NAME:-}"
  GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"
}

ensure_dotfiles_dir() {
  [[ -d "$DOTFILES_DIR" ]] || die "dotfiles 目录不存在: $DOTFILES_DIR"
  [[ -f "$INSTALL_DIR/setup.sh" ]] || die "未找到 setup.sh，请确认 DOTFILES_DIR=$DOTFILES_DIR"
}

stage_source_lib() {
  local name="$1"
  case "$name" in
    mirror)
      # shellcheck source=apt.sh
      source "$LIB_DIR/apt.sh"
      ;;
    base|system|nvidia)
      # shellcheck source=apt.sh
      source "$LIB_DIR/apt.sh"
      # shellcheck source=packages.sh
      source "$LIB_DIR/packages.sh"
      ;;
    installers)
      # shellcheck source=apt.sh
      source "$LIB_DIR/apt.sh"
      # shellcheck source=gui.sh
      source "$LIB_DIR/gui.sh"
      ;;
    dev)
      # shellcheck source=apt.sh
      source "$LIB_DIR/apt.sh"
      # shellcheck source=dev.sh
      source "$LIB_DIR/dev.sh"
      # shellcheck source=docker.sh
      source "$LIB_DIR/docker.sh"
      ;;
    env)
      # shellcheck source=env.sh
      source "$LIB_DIR/env.sh"
      ;;
    git)
      # shellcheck source=git.sh
      source "$LIB_DIR/git.sh"
      ;;
    *) die "未知 stage 类型: $name" ;;
  esac
}

stage_init() {
  local num="$1"
  local name="$2"

  if [[ -z "${INSTALL_DIR:-}" || ! -f "$INSTALL_DIR/lib/core.sh" ]]; then
    local caller_dir
    caller_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    if [[ -f "$caller_dir/../lib/core.sh" ]]; then
      INSTALL_DIR="$(cd "$caller_dir/.." && pwd)"
      LIB_DIR="$INSTALL_DIR/lib"
    fi
  fi

  detect_dotfiles_dir "$INSTALL_DIR"
  LIB_DIR="${LIB_DIR:-$INSTALL_DIR/lib}"
  export DOTFILES_DIR INSTALL_DIR LIB_DIR CONFIG_DIR

  load_config
  resolve_release
  ensure_dotfiles_dir
  stage_source_lib "$name"

  echo ""
  log "=== 阶段 ${num}：${name}（Ubuntu ${RELEASE}）==="
}

stage_done() {
  local num="${CURRENT_STAGE_NUM:-?}"
  echo ""
  log "阶段 ${num} 完成。"
  while (($#)); do
    echo "  验收: $1"
    shift
  done
  echo ""
}

print_timeshift_hint() {
  local name="$1"
  warn "建议 Timeshift 快照: $name"
  warn "  Timeshift → Create"
}

print_manual_checklist() {
  cat <<'EOF'

--- 首次使用清单 ---
[ ] fcitx5：im-config 选择 Fcitx 5，注销后生效
[ ] installers/：按需放入 deb / AppImage / tar 后运行阶段 04
[ ] 注销并重新登录（docker / libvirt 组生效）

EOF
}

gui_trust_desktop_file() {
  local desktop="$1"
  [[ -f "$desktop" ]] || return 1
  chmod +x "$desktop"
}

gui_refresh_desktop_database() {
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental 2>/dev/null || true
  elif command -v kbuildsycoca5 >/dev/null 2>&1; then
    kbuildsycoca5 --noincremental 2>/dev/null || true
  fi
}

list_stages_help() {
  cat <<'EOF'
阶段:
  01  mirror       APT 镜像（清华或官方）
  02  base         packages-base.txt
  03  system       packages-extras.txt + fcitx5 词库（可选）
  04  installers   installers/deb + installers/appimage + installers/tar
  05  dev          SDKMAN Java、Maven、nvm、nrm、pnpm、Docker
  06  nvidia       内核头 + ubuntu-drivers
  07  env          将 environment.env 中的环境变量写入用户或系统
  08  git          Git 全局身份

预设:
  base   01,02,03
  dev    05
  gpu    06
  setup  07,08
EOF
}
