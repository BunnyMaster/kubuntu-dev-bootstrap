#!/usr/bin/env bash
# shellcheck shell=bash
# apt 操作与镜像源

APT_DPKG_OPTS=(
  -o "DPkg::Lock::Timeout=120"
  -o "Dpkg::Options::=--force-confdef"
  -o "Dpkg::Options::=--force-confold"
)

apt_update() {
  log "apt-get update ..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq "${APT_DPKG_OPTS[@]}"
}

apt_upgrade() {
  log "apt-get upgrade ..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq "${APT_DPKG_OPTS[@]}"
}

apt_install() {
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${APT_DPKG_OPTS[@]}" "$@"
}

mirror_sources_template() {
  echo "$INSTALL_DIR/apt/${RELEASE}.sources"
}

mirror_apply_uri_substitution() {
  local src_file="$1"
  local dest_file="$2"
  local mirror="${APT_MIRROR:-tuna}"

  cp "$src_file" "$dest_file"
  case "$mirror" in
    tuna)
      log "使用清华 APT 镜像（RELEASE=$RELEASE）"
      ;;
    official)
      log "使用 Ubuntu 官方 APT 源（RELEASE=$RELEASE）"
      sed -i 's|https://mirrors.tuna.tsinghua.edu.cn/ubuntu|http://archive.ubuntu.com/ubuntu|g' "$dest_file"
      ;;
    *)
      die "未知 APT_MIRROR=$mirror（可用: tuna, official）"
      ;;
  esac
}

mirror_apply() {
  local src dest="/etc/apt/sources.list.d/ubuntu.sources"
  src="$(mirror_sources_template)"
  [[ -f "$src" ]] || die "缺少镜像模板: $src"

  if [[ -f /etc/apt/sources.list ]]; then
    sudo cp -a /etc/apt/sources.list /etc/apt/sources.list.backup
    log "已备份 /etc/apt/sources.list → sources.list.backup"
  fi

  sudo mkdir -p /etc/apt/sources.list.d
  if [[ -f "$dest" ]]; then
    sudo cp -a "$dest" "${dest}.bak"
    log "已备份 $dest → ${dest}.bak"
  fi

  local tmp
  tmp="$(mktemp)"
  mirror_apply_uri_substitution "$src" "$tmp"
  sudo cp "$tmp" "$dest"
  rm -f "$tmp"
  log "已写入 APT 源: $dest"

  apt_update
  log "apt update 成功"
}
