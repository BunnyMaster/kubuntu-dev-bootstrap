#!/usr/bin/env bash
# shellcheck shell=bash
# APT Java、Apache Maven、nvm(Node)、npm 全局工具

dev_jvm_home() {
  local version="$1"
  local arch
  arch="$(dpkg --print-architecture)"
  echo "/usr/lib/jvm/java-${version}-openjdk-${arch}"
}

dev_install_java() {
  local arch jvm_17 jvm_21 default_jvm pkgs=()

  arch="$(dpkg --print-architecture)"
  jvm_17="$(dev_jvm_home 17)"
  jvm_21="$(dev_jvm_home 21)"

  if [[ "${INSTALL_JAVA_17:-1}" == "1" ]]; then
    pkgs+=(openjdk-17-jdk)
  fi
  pkgs+=(openjdk-21-jdk)

  log "安装 Java（APT: ${pkgs[*]}）..."
  apt_install "${pkgs[@]}"

  if [[ "${INSTALL_JAVA_17:-1}" == "1" ]]; then
    [[ -d "$jvm_17" ]] || die "未找到 JDK 17: $jvm_17"
    sudo update-alternatives --install /usr/bin/java java "${jvm_17}/bin/java" 1717
    sudo update-alternatives --install /usr/bin/javac javac "${jvm_17}/bin/javac" 1717
  fi

  [[ -d "$jvm_21" ]] || die "未找到 JDK 21: $jvm_21"
  sudo update-alternatives --install /usr/bin/java java "${jvm_21}/bin/java" 2121
  sudo update-alternatives --install /usr/bin/javac javac "${jvm_21}/bin/javac" 2121

  case "${JAVA_DEFAULT_VERSION:-21}" in
    17)
      [[ "${INSTALL_JAVA_17:-1}" == "1" ]] || die "JAVA_DEFAULT_VERSION=17 但 INSTALL_JAVA_17=0"
      default_jvm="$jvm_17"
      ;;
    21) default_jvm="$jvm_21" ;;
    *) die "未知 JAVA_DEFAULT_VERSION=${JAVA_DEFAULT_VERSION}（可用: 17, 21）" ;;
  esac

  sudo update-alternatives --set java "${default_jvm}/bin/java"
  sudo update-alternatives --set javac "${default_jvm}/bin/javac"

  log "默认 Java: ${default_jvm} (JAVA_DEFAULT_VERSION=${JAVA_DEFAULT_VERSION})"

  sudo tee /etc/profile.d/java.sh >/dev/null <<EOF
# Managed by dotfiles install (stage 04)
export JAVA_HOME="${default_jvm}"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
  sudo chmod 644 /etc/profile.d/java.sh
  log "已写入 /etc/profile.d/java.sh"
}

dev_install_maven() {
  local version="${MAVEN_VERSION:-3.9.9}"
  local major="${version%%.*}"
  local artifact="apache-maven-${version}-bin"
  local install_dir="/opt/apache-maven-${version}"
  local link="/opt/maven"
  local tmpdir downloaded="" url

  if [[ -x "${link}/bin/mvn" ]]; then
    log "Maven 已安装: $("${link}/bin/mvn" -v 2>/dev/null | head -1)"
    return 0
  fi

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  local -a urls=(
    "https://mirrors.aliyun.com/apache/maven/maven-${major}/${version}/binaries/${artifact}.tar.gz"
    "https://dlcdn.apache.org/maven/maven-${major}/${version}/binaries/${artifact}.tar.gz"
    "https://archive.apache.org/dist/maven/maven-${major}/${version}/binaries/${artifact}.tar.gz"
  )

  for url in "${urls[@]}"; do
    log "下载 Maven ${version}: ${url} ..."
    if curl -fsSL "$url" -o "${tmpdir}/${artifact}.tar.gz"; then
      downloaded="${tmpdir}/${artifact}.tar.gz"
      break
    fi
    warn "下载失败: $url"
  done

  [[ -n "$downloaded" ]] || die "Maven 下载失败（请检查网络/版本 MAVEN_VERSION=$version）"

  log "解压 Maven 到 ${install_dir} ..."
  sudo tar -xzf "$downloaded" -C /opt
  [[ -d "$install_dir" ]] || die "解压后未找到: $install_dir"

  sudo ln -sfn "$install_dir" "$link"

  sudo tee /etc/profile.d/maven.sh >/dev/null <<EOF
# Managed by dotfiles install (stage 04)
export MAVEN_HOME="${link}"
export PATH="\$MAVEN_HOME/bin:\$PATH"
EOF
  sudo chmod 644 /etc/profile.d/maven.sh
  log "已写入 /etc/profile.d/maven.sh"
  log "Maven 安装完成: $("${link}/bin/mvn" -v 2>/dev/null | head -1)"
}

dev_install_java_maven() {
  dev_install_java
  if [[ "${INSTALL_MAVEN:-1}" == "1" ]]; then
    dev_install_maven
    dev_setup_maven_home
  fi
}

dev_setup_maven_home() {
  local m2="$HOME/.m2"
  local settings="$m2/settings.xml"
  local repo="$m2/repository"
  local src="$CONFIG_DIR/maven-settings.xml"

  mkdir -p "$repo"
  if [[ -f "$src" ]]; then
    install -m 644 "$src" "$settings"
    log "Maven 配置（用户）: $settings"
  else
    warn "未找到 config/maven-settings.xml，跳过 Maven settings 安装"
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
