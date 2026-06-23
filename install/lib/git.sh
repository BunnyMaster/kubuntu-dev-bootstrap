#!/usr/bin/env bash
# shellcheck shell=bash
# Git 全局配置

git_apply_from_config() {
  local name="${GIT_USER_NAME:-}"
  local email="${GIT_USER_EMAIL:-}"

  if [[ -z "$name" || -z "$email" ]]; then
    warn "请在 config/config.env 中设置 GIT_USER_NAME 与 GIT_USER_EMAIL"
    return 1
  fi

  echo "将配置: $name <$email>"
  if ! confirm "确认写入 git config --global？"; then
    log "已跳过 Git 配置"
    return 0
  fi

  git config --global user.name "$name"
  git config --global user.email "$email"
  log "Git 已配置"
}
