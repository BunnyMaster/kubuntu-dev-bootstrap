#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=04
stage_init 04 dev

if ! confirm "网络可访问外网（Maven/nvm/Docker 需下载），继续？"; then
  log "已取消开发环境安装。"
  exit 0
fi

dev_install_java_maven
dev_install_nvm_node

if [[ "${INSTALL_DOCKER:-1}" == "1" ]]; then
  docker_install_ce
fi

warn "请注销并重新登录，使 docker / libvirt 组与 Java/Maven/nvm 环境变量生效。"
print_timeshift_hint "04-dev-ready"
stage_done "java -version && mvn -v" "node -v && pnpm -v" "docker --version（重登后）"
