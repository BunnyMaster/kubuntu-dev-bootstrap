#!/usr/bin/env bash
# shellcheck shell=bash
# apt 操作与镜像源

APT_DPKG_OPTS=(
  -o "DPkg::Lock::Timeout=120"
  -o "Dpkg::Options::=--force-confdef"
  -o "Dpkg::Options::=--force-confold"
)

_APT_UPDATERS_STOPPED=0

_apt_lock_files() {
  printf '%s\n' \
    /var/lib/dpkg/lock-frontend \
    /var/lib/dpkg/lock \
    /var/lib/apt/lists/lock
}

_apt_lock_busy() {
  local lock
  while IFS= read -r lock; do
    [[ -f "$lock" ]] || continue
    if ! sudo flock -n "$lock" true 2>/dev/null; then
      return 0
    fi
  done < <(_apt_lock_files)
  return 1
}

_apt_lock_holder_info() {
  local lock pid="" name="" locks
  locks="$(_apt_lock_files)"
  while IFS= read -r lock; do
    [[ -f "$lock" ]] || continue
    if ! sudo flock -n "$lock" true 2>/dev/null; then
      if command -v fuser >/dev/null 2>&1; then
        pid=$(sudo fuser "$lock" 2>/dev/null | tr -s ' ' '\n' | grep -E '^[0-9]+$' | head -1)
      elif command -v lsof >/dev/null 2>&1; then
        pid=$(sudo lsof -t "$lock" 2>/dev/null | head -1)
      fi
      [[ -n "$pid" ]] && break
    fi
  done <<<"$locks"

  if [[ -n "$pid" ]]; then
    name=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ')
  fi
  printf '%s %s\n' "${pid:-}" "${name:-}"
}

_apt_stop_background_updaters() {
  [[ "$_APT_UPDATERS_STOPPED" == "1" ]] && return 0
  _APT_UPDATERS_STOPPED=1

  local svc
  for svc in unattended-upgrades packagekit; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      warn "检测到 $svc 正在运行，临时停止以便安装继续（之后可: sudo systemctl start $svc）"
      sudo systemctl stop "$svc" 2>/dev/null || true
    fi
  done
}

apt_wait_for_lock() {
  local max_wait="${APT_LOCK_MAX_WAIT:-600}"
  local interval="${APT_LOCK_POLL_INTERVAL:-5}"
  local start=$SECONDS
  local warned=0
  local pid name elapsed

  while _apt_lock_busy; do
    elapsed=$((SECONDS - start))
    if ((elapsed >= max_wait)); then
      read -r pid name < <(_apt_lock_holder_info)
      die "等待 apt/dpkg 锁超时（${max_wait} 秒，占用进程: ${name:-未知} PID ${pid:-?}）。可尝试: sudo systemctl stop unattended-upgrades; sudo dpkg --configure -a"
    fi

    read -r pid name < <(_apt_lock_holder_info)
    if [[ "$warned" == "0" ]]; then
      case "$name" in
        unattended-upgr*|unattended-upgrades)
          log "检测到系统后台自动更新 (unattended-upgrades) 正在占用 apt，等待其完成..."
          warn "新机器首次安装时常见，通常 1-5 分钟；也可另开终端: sudo systemctl stop unattended-upgrades"
          ;;
        apt|apt-get|dpkg|packagekitd|PackageKit)
          log "检测到 ${name:-apt 相关进程} (PID ${pid:-?}) 正在占用 apt/dpkg 锁，等待其完成..."
          ;;
        "")
          log "检测到 apt/dpkg 锁被占用，等待释放..."
          warn "新机器首次安装时常见；也可另开终端: sudo systemctl stop unattended-upgrades"
          ;;
        *)
          log "检测到 ${name} (PID ${pid:-?}) 正在占用 apt/dpkg 锁，等待其完成..."
          ;;
      esac
      warned=1
    else
      log "仍在等待 apt 锁释放... 已等待 ${elapsed}s（进程: ${name:-未知} PID ${pid:-?}）"
    fi
    sleep "$interval"
  done
}

_apt_prepare() {
  _apt_stop_background_updaters
  apt_wait_for_lock
}

apt_update() {
  _apt_prepare
  log "apt-get update ..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get update "${APT_DPKG_OPTS[@]}"
}

apt_upgrade() {
  _apt_prepare
  log "apt-get upgrade ..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y  "${APT_DPKG_OPTS[@]}"
}

apt_install() {
  _apt_prepare
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
