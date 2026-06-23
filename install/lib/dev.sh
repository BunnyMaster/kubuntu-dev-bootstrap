#!/usr/bin/env bash
# shellcheck shell=bash
# SDKMAN(Java/Maven)、nvm(Node)、npm 全局工具

dev_install_sdkman_java_maven() {
  local sdkman_init="$HOME/.sdkman/bin/sdkman-init.sh"

  if [[ -d "$HOME/.sdkman" ]] && [[ ! -s "$sdkman_init" ]]; then
    warn "检测到损坏的 SDKMAN（~/.sdkman 存在但缺少 sdkman-init.sh），清除后重装"
    rm -rf "$HOME/.sdkman"
  fi

  if [[ ! -s "$sdkman_init" ]]; then
    log "安装 SDKMAN ..."
    if ! curl -fsSL "https://get.sdkman.io" | bash; then
      die "SDKMAN 安装失败（请检查网络/代理）"
    fi
  fi

  if [[ ! -s "$sdkman_init" ]]; then
    die "SDKMAN 未就绪: $sdkman_init 不存在，可手动 rm -rf ~/.sdkman 后重试"
  fi

  set +u
  # shellcheck disable=SC1091
  source "$sdkman_init"

  log "安装 JDK 17 与 21 ..."
  sdk install java "$JAVA_17_IDENTIFIER" || sdk install java 17-tem
  sdk install java "$JAVA_21_IDENTIFIER" || sdk install java 21-tem
  sdk default java "$JAVA_21_IDENTIFIER" 2>/dev/null || sdk default java 21-tem

  if [[ "${INSTALL_MAVEN:-1}" == "1" ]]; then
    sdk install maven || true
    dev_setup_maven_home
  fi
  set -u
}

dev_setup_maven_home() {
  local m2="$HOME/.m2"
  local settings="$m2/settings.xml"
  local repo="$m2/repository"
  local src="$CONFIG_DIR/maven-settings.xml"
  local example="$CONFIG_DIR/maven-settings.xml.example"

  mkdir -p "$repo"
  if [[ -f "$src" ]]; then
    install -m 644 "$src" "$settings"
    log "Maven 配置（用户）: $settings"
  elif [[ -f "$example" ]]; then
    install -m 644 "$example" "$settings"
    log "Maven 配置（example）: $settings"
  else
    warn "未找到 maven-settings.xml，跳过 Maven settings 安装"
  fi
  log "本地仓库: $repo"
}

dev_install_nvm_node() {
  export NVM_DIR="$HOME/.nvm"
  if [[ -d "$NVM_DIR" ]] && [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    warn "检测到损坏的 nvm（$NVM_DIR 存在但缺少 nvm.sh），清除后重装"
    rm -rf "$NVM_DIR"
  fi
  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    log "安装 nvm ..."
    if ! curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; then
      die "nvm 安装失败（请检查网络/代理）"
    fi
  fi

  if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    die "nvm 未就绪: $NVM_DIR/nvm.sh 不存在，可手动 rm -rf ~/.nvm 后重试"
  fi

  set +u
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"

  log "安装 Node ${NODE_VERSION}（默认）与 ${NODE_VERSION_EXTRA} ..."
  nvm install "$NODE_VERSION"
  nvm install "$NODE_VERSION_EXTRA"
  nvm alias default "$NODE_VERSION"
  nvm use default

  if command -v corepack >/dev/null 2>&1; then
    corepack enable
    corepack prepare pnpm@latest --activate
    log "pnpm 已通过 corepack 启用"
  else
    warn "未找到 corepack，请检查 Node 安装"
  fi

  log "安装 npm 全局工具（nrm + NPM_GLOBAL_PACKAGES）..."
  npm install -g nrm
  if [[ -n "${NRM_REGISTRY:-}" ]]; then
    nrm use "$NRM_REGISTRY" || warn "nrm use $NRM_REGISTRY 失败，可稍后手动执行"
  fi

  if [[ -n "${NPM_GLOBAL_PACKAGES:-}" ]]; then
    local -a extra=()
    read -r -a extra <<<"$NPM_GLOBAL_PACKAGES"
    if ((${#extra[@]})); then
      npm install -g "${extra[@]}"
    fi
  fi
  set -u
}
