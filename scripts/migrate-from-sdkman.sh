#!/usr/bin/env bash
# 从 SDKMAN 迁移到 APT Java + /opt Maven（仅 Java/Maven，不含 nvm/Docker）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/../install" && pwd)"

# shellcheck source=../install/lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

stage_init 04 dev

log "安装原生 Java 与 Maven（读取 config/config.env）..."
dev_install_java_maven

echo ""
log "迁移安装完成。"
echo "  1. 从 ~/.bashrc、~/.zshrc 移除 SDKMAN 初始化块（若尚未移除）"
echo "  2. 新开终端（mvn 通过 /usr/local/bin 可用，无需 source profile.d）"
echo "  3. 验收: java -version && mvn -v"
echo "  4. 确认无误后: rm -rf ~/.sdkman"
echo ""
warn "~/.m2/repository 不会被修改；settings.xml 会与 config/maven-settings.xml 同步。"
