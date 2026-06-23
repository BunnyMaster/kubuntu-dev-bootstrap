#!/usr/bin/env bash
# shellcheck shell=bash
# 阶段 04 本地安装：installers/deb + installers/appimage + installers/tar

GUI_FAILED=()
GUI_SKIPPED=()

gui_installers_deb_dir() {
  echo "$DOTFILES_DIR/installers/deb"
}

gui_installers_appimage_dir() {
  echo "$DOTFILES_DIR/installers/appimage"
}

gui_installers_tar_dir() {
  echo "$DOTFILES_DIR/installers/tar"
}

gui_record_failure() {
  GUI_FAILED+=("$1")
  warn "✗ $1"
}

gui_record_skip() {
  GUI_SKIPPED+=("$1")
  warn "○ 跳过: $1"
}

gui_record_ok() {
  log "✓ $1"
}

gui_write_desktop() {
  local path="$1"
  local body="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$body" >"$path"
  chmod +x "$path"
  log "桌面项: $path"
}

gui_deb_pkg_name() {
  dpkg-deb -f "$1" Package 2>/dev/null || true
}

gui_deb_installed() {
  local pkg="$1"
  [[ -n "$pkg" ]] && dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'
}

gui_install_one_deb() {
  local deb="$1"
  local label="${2:-$(basename "$deb")}"
  local pkg
  pkg=$(gui_deb_pkg_name "$deb")
  if gui_deb_installed "$pkg"; then
    log "deb 已安装，跳过: $label"
    return 0
  fi
  log "安装 deb: $label"
  if ! sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$deb" 2>/dev/null; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -f "${APT_DPKG_OPTS[@]}" || {
      gui_record_failure "deb: $label"
      return 1
    }
  fi
  gui_record_ok "deb: $label"
}

gui_install_debs() {
  local deb_dir
  deb_dir="$(gui_installers_deb_dir)"
  log "--- [1/3] 安装 deb 包 ← $deb_dir ---"

  if [[ ! -d "$deb_dir" ]]; then
    gui_record_skip "installers/deb/ 目录不存在"
    return 0
  fi

  shopt -s nullglob
  local -a debs=("$deb_dir"/*.deb)
  shopt -u nullglob
  if ((${#debs[@]} == 0)); then
    gui_record_skip "installers/deb/ 下无 .deb"
    return 0
  fi

  local deb
  for deb in "${debs[@]}"; do
    gui_install_one_deb "$deb" "$(basename "$deb")" || true
  done
}

gui_appimage_display_name() {
  local base="$1"
  printf '%s\n' "$base" | sed -E 's/[-_]+/ /g; s/([a-z])([A-Z])/\1 \2/g'
}

gui_install_appimages() {
  local appimage_dir
  appimage_dir="$(gui_installers_appimage_dir)"
  log "--- [2/3] 安装 AppImage ← $appimage_dir ---"

  if [[ ! -d "$appimage_dir" ]]; then
    gui_record_skip "installers/appimage/ 目录不存在"
    return 0
  fi

  shopt -s nullglob
  local -a images=("$appimage_dir"/*.AppImage "$appimage_dir"/*.appimage)
  shopt -u nullglob
  if ((${#images[@]} == 0)); then
    gui_record_skip "installers/appimage/ 下无 AppImage"
    return 0
  fi

  if ! sudo mkdir -p "$APPIMAGES_DIR"; then
    gui_record_failure "无法创建 $APPIMAGES_DIR"
    return 1
  fi
  apt_install libfuse2t64 2>/dev/null || apt_install libfuse2 2>/dev/null || true

  local appimage name dest base display desktop_id desktop_path
  for appimage in "${images[@]}"; do
    name=$(basename "$appimage")
    dest="${APPIMAGES_DIR}/${name}"
    if ! sudo install -m 755 "$appimage" "$dest"; then
      gui_record_failure "AppImage 复制: $name"
      continue
    fi
    base="${name%.AppImage}"
    base="${base%.appimage}"
    display=$(gui_appimage_display_name "$base")
    desktop_id="appimage-${base}.desktop"
    desktop_path="$HOME/.local/share/applications/$desktop_id"
    gui_write_desktop "$desktop_path" "[Desktop Entry]
Type=Application
Name=${display}
Comment=${display}
Exec=${dest}
TryExec=${dest}
Terminal=false
Categories=Development;Utility;
StartupNotify=true"
    gui_record_ok "AppImage → $dest"
    warn "首次使用请打开 $APPIMAGES_DIR 双击 $name"
  done
}

gui_tar_basename() {
  local name="$1"
  case "$name" in
    *.tar.gz) echo "${name%.tar.gz}" ;;
    *.tgz) echo "${name%.tgz}" ;;
    *.tar) echo "${name%.tar}" ;;
    *) basename "$name" ;;
  esac
}

gui_tar_install_dir() {
  local tarball="$1"
  local base
  base=$(gui_tar_basename "$(basename "$tarball")")
  echo "/opt/$base"
}

gui_tar_extract_to_tmp() {
  local tarball="$1"
  local tmp="$2"
  case "$tarball" in
    *.tar.gz|*.tgz) tar -xzf "$tarball" -C "$tmp" ;;
    *.tar) tar -xf "$tarball" -C "$tmp" ;;
    *)
      warn "不支持的归档格式: $(basename "$tarball")"
      return 1
      ;;
  esac
}

gui_tar_resolve_binary() {
  local dest="$1"
  local prefer="${2:-}"
  local candidate

  if [[ -n "$prefer" ]]; then
    for candidate in "$dest/$prefer" "$dest/bin/$prefer"; do
      if [[ -f "$candidate" ]]; then
        sudo chmod +x "$candidate"
        echo "$candidate"
        return 0
      fi
    done
  fi

  shopt -s nullglob
  local -a roots=("$dest"/*)
  shopt -u nullglob
  for candidate in "${roots[@]}"; do
    [[ -f "$candidate" ]] || continue
    sudo chmod +x "$candidate"
    echo "$candidate"
    return 0
  done
  return 1
}

gui_tar_is_jetbrains_toolbox() {
  local base="$1"
  [[ "$base" == jetbrains-toolbox-* ]]
}

gui_install_one_tar() {
  local tarball="$1"
  local name base dest tmp entries exec_path desktop_path
  name=$(basename "$tarball")
  base=$(gui_tar_basename "$name")
  dest=$(gui_tar_install_dir "$tarball")

  if [[ -d "$dest" ]] && compgen -G "$dest/*" >/dev/null; then
    log "tar 已存在，跳过: $name → $dest"
    return 0
  fi

  log "解压 tar: $name → $dest"
  tmp=$(mktemp -d)
  if ! gui_tar_extract_to_tmp "$tarball" "$tmp"; then
    rm -rf "$tmp"
    gui_record_failure "tar 解压: $name"
    return 1
  fi

  shopt -s nullglob
  entries=("$tmp"/*)
  shopt -u nullglob
  if ! sudo mkdir -p "$dest"; then
    rm -rf "$tmp"
    gui_record_failure "tar 目录: $dest"
    return 1
  fi
  if ((${#entries[@]} == 1)) && [[ -d "${entries[0]}" ]]; then
    if ! sudo cp -a "${entries[0]}/." "$dest/"; then
      rm -rf "$tmp"
      gui_record_failure "tar 复制: $name"
      return 1
    fi
  elif ! sudo cp -a "$tmp/." "$dest/"; then
    rm -rf "$tmp"
    gui_record_failure "tar 复制: $name"
    return 1
  fi
  rm -rf "$tmp"

  if gui_tar_is_jetbrains_toolbox "$base"; then
    exec_path=$(gui_tar_resolve_binary "$dest" "jetbrains-toolbox") || {
      gui_record_failure "tar 主程序: $name"
      return 1
    }
    desktop_path="$HOME/.local/share/applications/jetbrains-toolbox.desktop"
    gui_write_desktop "$desktop_path" "[Desktop Entry]
Type=Application
Name=JetBrains Toolbox
Comment=JetBrains Toolbox
Exec=${exec_path} %u
TryExec=${exec_path}
Icon=jetbrains-toolbox
Terminal=false
Categories=Development;
StartupNotify=true"
    gui_record_ok "tar → $dest (JetBrains Toolbox)"
    return 0
  fi

  if exec_path=$(gui_tar_resolve_binary "$dest" ""); then
    gui_record_ok "tar → $dest ($exec_path)"
  else
    gui_record_ok "tar → $dest"
  fi
  warn "未识别的 tar 包: $name — 已解压至 $dest，请自行创建 ~/.local/share/applications/*.desktop"
}

gui_install_tars() {
  local tar_dir
  tar_dir="$(gui_installers_tar_dir)"
  log "--- [3/3] 安装 tar 包 ← $tar_dir ---"

  if [[ ! -d "$tar_dir" ]]; then
    gui_record_skip "installers/tar/ 目录不存在"
    return 0
  fi

  shopt -s nullglob
  local -a archives=("$tar_dir"/*.tar.gz "$tar_dir"/*.tgz "$tar_dir"/*.tar)
  shopt -u nullglob
  if ((${#archives[@]} == 0)); then
    gui_record_skip "installers/tar/ 下无 .tar.gz / .tar"
    return 0
  fi

  local tarball
  for tarball in "${archives[@]}"; do
    gui_install_one_tar "$tarball" || true
  done
}

gui_install_all() {
  GUI_FAILED=()
  GUI_SKIPPED=()

  log "本地安装包（installers/deb + installers/appimage + installers/tar）"
  gui_install_debs || gui_record_failure "deb 步骤异常退出"
  gui_install_appimages || gui_record_failure "AppImage 步骤异常退出"
  gui_install_tars || gui_record_failure "tar 步骤异常退出"
  gui_refresh_desktop_database

  echo ""
  log "=== 阶段 04 installers 汇总 ==="
  if ((${#GUI_FAILED[@]})); then
    warn "失败 (${#GUI_FAILED[@]}): ${GUI_FAILED[*]}"
  else
    log "无失败项"
  fi
  if ((${#GUI_SKIPPED[@]})); then
    warn "跳过 (${#GUI_SKIPPED[@]}): ${GUI_SKIPPED[*]}"
  fi
}
