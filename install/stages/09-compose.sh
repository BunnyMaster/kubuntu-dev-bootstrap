#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=09
stage_init 09 compose

COMPOSE_FILE="$CONFIG_DIR/docker-compose.yaml"
[[ -f "$COMPOSE_FILE" ]] || {
  warn "未找到 $COMPOSE_FILE"
  warn "可选: cp config/docker-compose.yaml.example config/docker-compose.yaml"
  exit 0
}

if ! command -v docker >/dev/null 2>&1; then
  die "未找到 docker 命令，请先运行阶段 05 并重新登录"
fi

log "在 $CONFIG_DIR 执行 docker compose up -d ..."
(
  cd "$CONFIG_DIR"
  docker compose up -d
)

stage_done "docker compose -f $COMPOSE_FILE ps"
