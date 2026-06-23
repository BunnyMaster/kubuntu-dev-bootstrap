#!/usr/bin/env bash
# 一键清理并重置系统与 shell 代理设置
set -euo pipefail

echo "正在清理并重置代理设置..."

unset http_proxy https_proxy ftp_proxy all_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY

if [[ -f ~/.config/kioslaverc ]]; then
  sed -i '/\[Proxy Settings\]/,/^$/d' ~/.config/kioslaverc
  printf '\n[Proxy Settings]\nProxyType=0\n' >> ~/.config/kioslaverc
  echo "✓ KDE 系统代理已重置为：直接连接"
fi

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.system.proxy mode 'none'
  echo "✓ GNOME/dconf 代理已关闭"
fi

for rc in ~/.bashrc ~/.profile; do
  if [[ -f "$rc" ]] && grep -qE '(^|[[:space:]])(export[[:space:]]+)?(http_proxy|https_proxy|HTTP_PROXY|HTTPS_PROXY)=' "$rc"; then
    sed -i -E '/(^|[[:space:]])(export[[:space:]]+)?(http_proxy|https_proxy|ftp_proxy|all_proxy|HTTP_PROXY|HTTPS_PROXY|FTP_PROXY|ALL_PROXY)=/d' "$rc"
    echo "✓ 已从 $rc 移除 proxy 相关 export"
  fi
done

echo "--------------------------------------------------"
echo "清理完成。请重启终端，或执行: source ~/.bashrc"
echo "部分应用（浏览器、IDE 等）可能仍保留独立代理设置，需手动检查。"
