#!/usr/bin/env bash
# shellcheck shell=bash
# 将 config.env 中的环境变量写入用户或系统 scope

env_config_file() {
  echo "$CONFIG_DIR/config.env"
}

env_collect_export_lines() {
  local cfg
  cfg="$(env_config_file)"
  [[ -f "$cfg" ]] || die "缺少 $cfg（请先 cp config/config.env.example config/config.env）"

  local line key
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]*}"}"
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[A-Z_][A-Z0-9_]*= ]] || continue
    key="${line%%=*}"
    is_installer_config_key "$key" && continue
    printf '%s\n' "$line"
  done <"$cfg"
}

env_write_user_scope() {
  local dest_dir="$HOME/.config/environment.d"
  local dest="$dest_dir/99-dotfiles.conf"
  local tmp count=0

  mkdir -p "$dest_dir"
  tmp="$(mktemp)"
  : >"$tmp"
  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '%s\n' "$line" >>"$tmp"
    count=$((count + 1))
  done < <(env_collect_export_lines)

  if [[ "$count" -eq 0 ]]; then
    warn "未找到可导出的环境变量，跳过写入"
    rm -f "$tmp"
    return 0
  fi

  install -m 644 "$tmp" "$dest"
  rm -f "$tmp"
  log "已写入用户环境变量 ($count 项): $dest"
  warn "注销并重新登录后生效（或重启 systemd user session）"
}

env_write_system_scope() {
  local env_d="/etc/environment.d/99-dotfiles.conf"
  local prof_d="/etc/profile.d/99-dotfiles.sh"
  local tmp_env tmp_prof count=0

  tmp_env="$(mktemp)"
  tmp_prof="$(mktemp)"
  : >"$tmp_env"
  : >"$tmp_prof"

  while IFS= read -r line || [[ -n "$line" ]]; do
    printf '%s\n' "$line" >>"$tmp_env"
    printf 'export %s\n' "$line" >>"$tmp_prof"
    count=$((count + 1))
  done < <(env_collect_export_lines)

  if [[ "$count" -eq 0 ]]; then
    warn "未找到可导出的环境变量，跳过写入"
    rm -f "$tmp_env" "$tmp_prof"
    return 0
  fi

  install -m 644 "$tmp_env" "$env_d"
  install -m 644 "$tmp_prof" "$prof_d"
  rm -f "$tmp_env" "$tmp_prof"
  log "已写入系统环境变量 ($count 项):"
  log "  $env_d"
  log "  $prof_d"
  warn "请注销并重新登录，或重启后生效。"
}

env_apply_from_config() {
  case "${ENV_SCOPE:-user}" in
    user)
      env_write_user_scope
      ;;
    system)
      if [[ "$EUID" -ne 0 ]]; then
        log "系统级环境变量需要 root，将使用 sudo ..."
        sudo env DOTFILES_DIR="$DOTFILES_DIR" INSTALL_DIR="$INSTALL_DIR" \
          bash "$INSTALL_DIR/lib/env-apply-system.sh"
      else
        env_write_system_scope
      fi
      ;;
    *)
      die "未知 ENV_SCOPE=${ENV_SCOPE}（可用: user, system）"
      ;;
  esac
}
