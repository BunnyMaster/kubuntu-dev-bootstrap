#!/usr/bin/env bash
# shellcheck shell=bash
# apt 系统包（共享包列表）

pkg_read_list_file() {
  local file="$1"
  local -n _pkgs=$2
  _pkgs=()
  [[ -f "$file" ]] || die "缺少包列表: $file"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]*}"}"
    [[ -z "$line" ]] && continue
    _pkgs+=("$line")
  done <"$file"
}

pkg_filter_fcitx5() {
  local -n _in=$1
  local -n _out=$2
  _out=()
  local pkg
  for pkg in "${_in[@]}"; do
    if [[ "$pkg" == fcitx5* || "$pkg" == kde-config-fcitx5 ]]; then
      continue
    fi
    _out+=("$pkg")
  done
}

pkg_install_from_list() {
  local label="$1"
  local file="$2"
  local pkgs=()
  pkg_read_list_file "$file" pkgs
  if ((${#pkgs[@]} == 0)); then
    warn "$label: 包列表为空，跳过"
    return 0
  fi
  log "$label (${#pkgs[@]} 个包) ..."
  apt_update
  if [[ "${APT_UPGRADE:-1}" == "1" ]]; then
    apt_upgrade
  fi
  apt_install "${pkgs[@]}"
  log "$label 完成"
}

pkg_install_base() {
  pkg_install_from_list "安装基础包" "$INSTALL_DIR/packages-base.txt"
}

pkg_install_system_extras() {
  local pkgs=()
  local filtered=()
  pkg_read_list_file "$INSTALL_DIR/packages-extras.txt" pkgs

  if [[ "${INSTALL_FCITX5:-1}" == "1" ]]; then
    filtered=("${pkgs[@]}")
    log "INSTALL_FCITX5=1，将安装 fcitx5 相关包"
  else
    pkg_filter_fcitx5 pkgs filtered
    warn "INSTALL_FCITX5=0，跳过 fcitx5 相关包"
  fi

  if ((${#filtered[@]} == 0)); then
    warn "系统包列表过滤后为空，跳过"
    return 0
  fi

  log "安装系统软件 (${#filtered[@]} 个包) ..."
  apt_update
  if [[ "${APT_UPGRADE:-1}" == "1" ]]; then
    apt_upgrade
  fi
  apt_install "${filtered[@]}"
  log "系统软件安装完成"

  if [[ "${INSTALL_FCITX5:-1}" == "1" ]]; then
    pkg_install_fcitx5_dict_optional
    warn "fcitx5: 运行 im-config 选择 Fcitx 5，注销后生效。"
  fi
  pkg_setup_libvirt_group
}

pkg_setup_libvirt_group() {
  if dpkg-query -W -f='${Status}' virt-manager 2>/dev/null | grep -q "install ok installed"; then
    sudo groupadd libvirt 2>/dev/null || true
    sudo usermod -aG libvirt "$USER" 2>/dev/null || true
    log "已将 $USER 加入 libvirt 组（注销后生效）"
  fi
}

pkg_install_fcitx5_dict_optional() {
  local dict_url="https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20220416.dict"
  local dest_dir="$HOME/.local/share/fcitx5/pinyin/dictionaries"
  local dest="$dest_dir/zhwiki-20220416.dict"

  if [[ -f "$dest" ]]; then
    log "fcitx5 词库已存在，跳过"
    return 0
  fi

  mkdir -p "$dest_dir"
  if wget -q --timeout=30 --tries=2 -O "$dest" "$dict_url" 2>/dev/null; then
    log "已下载 fcitx5 拼音词库"
  else
    warn "fcitx5 词库下载失败（可忽略，需外网）: $dict_url"
    rm -f "$dest"
  fi
}

pkg_install_nvidia_prereqs() {
  log "安装 NVIDIA 编译依赖 ..."
  apt_update
  apt_install linux-headers-"$(uname -r)" build-essential dkms 2>/dev/null \
    || apt_install linux-headers-generic build-essential dkms
}

pkg_run_ubuntu_drivers() {
  if ! command -v ubuntu-drivers >/dev/null 2>&1; then
    apt_install ubuntu-drivers-common
  fi
  log "检测推荐驱动（ubuntu-drivers devices）:"
  ubuntu-drivers devices | tee /tmp/dotfiles-ubuntu-drivers.txt || true

  if [[ "${YES:-0}" == "1" ]]; then
    log "非交互模式: 执行 ubuntu-drivers install"
    sudo ubuntu-drivers install
  elif confirm "执行 ubuntu-drivers install 安装推荐驱动？"; then
    sudo ubuntu-drivers install
  else
    warn "已跳过自动安装。可手动: sudo apt install <推荐包名>"
    warn "检测结果见: /tmp/dotfiles-ubuntu-drivers.txt"
    return 0
  fi
  warn "驱动安装后请重启，然后运行: nvidia-smi"
}
