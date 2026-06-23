#!/usr/bin/env bash
# shellcheck shell=bash
# Docker CE（阿里云源，signed-by keyring）

docker_install_ce() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker 已安装: $(docker --version)"
    return 0
  fi

  log "安装 Docker CE（阿里云镜像源 + keyring）..."
  sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
  apt_update
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq "${APT_DPKG_OPTS[@]}"
  apt_install ca-certificates curl gnupg lsb-release

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  apt_update
  apt_install xdg-utils docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo groupadd docker 2>/dev/null || true
  sudo usermod -aG docker "$USER" || true
  sudo systemctl enable --now docker
  sudo systemctl restart docker

  log "Docker 安装完成: $(docker --version 2>/dev/null || echo '请重新登录后验证')"
  warn "已将 $USER 加入 docker 组，请注销并重新登录后再执行 docker 命令。"
}
