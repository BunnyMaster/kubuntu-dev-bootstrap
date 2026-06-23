# scripts/

辅助 shell 脚本，不参与 `setup.sh` 主流程。

## clean-proxy.sh

清理当前 shell、KDE/GNOME 系统代理，以及 `~/.bashrc`、`~/.profile` 中的 `http_proxy` / `https_proxy` 等 export。

```bash
./scripts/clean-proxy.sh
```

### 局限性

- 仅处理当前用户下的 KDE `kioslaverc`、GNOME `gsettings` 和上述两个 shell 启动文件
- **不会**修改 `/etc/environment`、`systemd` 用户/系统单元、Docker daemon 代理、浏览器或 IDE 内置代理
- 修改 `~/.bashrc` / `~/.profile` 后需新开终端或 `source`
- 部分桌面环境（非 KDE/GNOME）的系统代理需手动在设置中关闭

运行后若仍有应用走代理，请在对应应用设置中单独检查。
