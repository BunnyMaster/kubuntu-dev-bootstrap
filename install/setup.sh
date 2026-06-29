#!/usr/bin/env bash
#
# Ubuntu/Kubuntu dotfiles 分阶段安装（24.04 / 26.04）
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR"
STAGES_DIR="$INSTALL_DIR/stages"
LIB_DIR="$INSTALL_DIR/lib"

# shellcheck source=lib/core.sh
source "$LIB_DIR/core.sh"

detect_dotfiles_dir "$INSTALL_DIR"

YES=0
DRY_RUN=0
LIST_STAGES=0
CLI_RELEASE=""
STAGES_ARG=""
PRESET=""
ALLOW_MISMATCH=0

usage() {
  cat <<EOF
Ubuntu/Kubuntu dotfiles 分阶段安装

仓库: $DOTFILES_DIR

用法:
  ./setup.sh                              交互菜单
  ./setup.sh --preset base                01-03（镜像 + 基础包 + 系统包）
  ./setup.sh --preset dev                 04 开发栈
  ./setup.sh --preset local               05 本地 installers
  ./setup.sh --preset gpu                 09 NVIDIA
  ./setup.sh --preset setup               06-07 收尾（Git、环境变量）
  ./setup.sh --stages 01,02,03            指定阶段（--stage 为别名）
  ./setup.sh --release 24.04|26.04        指定发行版（默认自动检测）
  ./setup.sh --list-stages                列出阶段
  ./setup.sh --dry-run --stages 01,02,03  仅打印将执行的阶段
  ./setup.sh --yes                        非交互确认

推荐顺序:
  编辑 ../config/config.env（Git、镜像等）与 ../config/environment.env（可选）
  ./setup.sh --preset base
  ./setup.sh --preset dev                 # 需外网（Maven/nvm/Docker）
  ./setup.sh --preset local               # 可选：本地 deb/AppImage/tar
  ./setup.sh --preset setup               # 可选：Git + 环境变量
  ./setup.sh --stages 08                  # fcitx5（词库需外网确认）
  ./setup.sh --preset gpu                 # 最后，重启后

EOF
  list_stages_help
}

normalize_stage_id() {
  local raw="$1"
  local s="${raw// /}"
  if [[ "$s" =~ ^[0-9]$ ]]; then
    s="0$s"
  fi
  echo "$s"
}

find_stage_script() {
  local id="$1"
  local f
  f=$(compgen -G "$STAGES_DIR/${id}-*.sh" 2>/dev/null | head -1 || true)
  [[ -n "$f" && -f "$f" ]] || return 1
  printf '%s\n' "$f"
}

run_stage() {
  local id="$1"
  local f
  f=$(find_stage_script "$id") || {
    echo "未知阶段: $id" >&2
    return 1
  }
  echo ""
  echo "========================================"
  echo "执行阶段 $id: $(basename "$f")"
  echo "========================================"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "[dry-run] 将执行: bash $f"
    return 0
  fi
  bash "$f"
}

expand_stages() {
  local -a result=()
  local raw id
  for raw in "$@"; do
    id=$(normalize_stage_id "$raw")
    result+=("$id")
  done
  printf '%s\n' "${result[@]}"
}

while (($#)); do
  case "$1" in
    --yes|-y)
      YES=1
      export YES
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --list-stages)
      LIST_STAGES=1
      shift
      ;;
    --allow-mismatch)
      ALLOW_MISMATCH=1
      export ALLOW_MISMATCH
      shift
      ;;
    --release=*)
      CLI_RELEASE=$(normalize_release "${1#*=}")
      export CLI_RELEASE
      shift
      ;;
    --release)
      CLI_RELEASE=$(normalize_release "${2:-}")
      export CLI_RELEASE
      shift 2
      ;;
    --preset=*)
      PRESET="${1#*=}"
      shift
      ;;
    --preset)
      PRESET="${2:-}"
      shift 2
      ;;
    --stages=*|--stage=*)
      STAGES_ARG="${1#*=}"
      shift
      ;;
    --stages|--stage)
      STAGES_ARG="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$EUID" -eq 0 ]]; then
  echo "错误：请不要使用 sudo 运行 setup.sh" >&2
  exit 1
fi

chmod +x "$INSTALL_DIR/setup.sh" "$STAGES_DIR"/*.sh "$LIB_DIR"/*.sh 2>/dev/null || true

if [[ "$LIST_STAGES" == "1" ]]; then
  list_stages_help
  exit 0
fi

case "$PRESET" in
  base|dev|local|gpu|setup)
    STAGES_ARG="${PRESET_STAGES[$PRESET]}"
    ;;
  "")
    ;;
  *)
    die "未知 preset: $PRESET（可用: base, dev, local, gpu, setup）"
    ;;
esac

if [[ -z "$STAGES_ARG" ]]; then
  load_config
  resolve_release
  echo ""
  echo "dotfiles 安装 — $DOTFILES_DIR（Ubuntu $RELEASE）"
  echo "  1) 01 镜像源"
  echo "  2) 02 基础包"
  echo "  3) 03 系统包"
  echo "  4) 04 开发环境"
  echo "  5) 05 本地 installers"
  echo "  6) 06 Git"
  echo "  7) 07 环境变量"
  echo "  8) 08 fcitx5"
  echo "  9) 09 NVIDIA"
  echo "  a) preset base: 01-03"
  echo "  b) preset dev: 04"
  echo "  c) preset local: 05"
  echo "  d) preset setup: 06-07"
  echo "  e) preset gpu: 09"
  echo "  0) 退出"
  read -r -p "请选择: " choice
  case "$choice" in
    1) STAGES_ARG="01" ;;
    2) STAGES_ARG="02" ;;
    3) STAGES_ARG="03" ;;
    4) STAGES_ARG="04" ;;
    5) STAGES_ARG="05" ;;
    6) STAGES_ARG="06" ;;
    7) STAGES_ARG="07" ;;
    8) STAGES_ARG="08" ;;
    9) STAGES_ARG="09" ;;
    a|A) STAGES_ARG="${PRESET_STAGES[base]}" ;;
    b|B) STAGES_ARG="${PRESET_STAGES[dev]}" ;;
    c|C) STAGES_ARG="${PRESET_STAGES[local]}" ;;
    d|D) STAGES_ARG="${PRESET_STAGES[setup]}" ;;
    e|E) STAGES_ARG="${PRESET_STAGES[gpu]}" ;;
    *) exit 0 ;;
  esac
fi

if [[ -z "$STAGES_ARG" ]]; then
  usage
  exit 1
fi

IFS=',' read -r -a STAGES <<<"$STAGES_ARG"
mapfile -t STAGES < <(expand_stages "${STAGES[@]}")

if [[ "$DRY_RUN" == "1" ]]; then
  load_config
  resolve_release
  log "dry-run: RELEASE=$RELEASE preset=${PRESET:-<none>} stages=${STAGES[*]}"
fi

for id in "${STAGES[@]}"; do
  run_stage "$id" || exit 1
done

if [[ "$DRY_RUN" != "1" ]]; then
  echo ""
  echo "============================================================"
  echo " 选定阶段已执行完毕"
  print_manual_checklist
  echo "============================================================"
fi
