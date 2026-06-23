# install/

分阶段安装脚本与共享资源。

## 入口

```bash
cd install
./setup.sh --help
./setup.sh --list-stages
./setup.sh --preset base
```

`DOTFILES_DIR` 自动检测：优先 `git -C install rev-parse --show-toplevel`，否则为 `install/` 的父目录。

## 发行版

- 用户面向：`--release 24.04` 或 `26.04`（默认从 `/etc/os-release` 的 `VERSION_ID` 检测）
- APT 源文件：`apt/24.04.sources`、`apt/26.04.sources`（内部 suite 名 noble / resolute）
- `APT_MIRROR=tuna`（清华）或 `official`（官方 archive）

## 包列表

- `packages-base.txt` — 阶段 02，各版本共享
- `packages-extras.txt` — 阶段 03；`INSTALL_FCITX5=0` 时跳过 fcitx5 相关行

## lib/

| 文件 | 用途 |
|------|------|
| `core.sh` | 配置、发行版、stage 生命周期 |
| `apt.sh` | 镜像与 apt 操作 |
| `packages.sh` | 包列表安装 |
| `gui.sh` | 阶段 04 deb/AppImage/tar |
| `dev.sh` | SDKMAN、nvm、npm |
| `docker.sh` | Docker CE（keyring） |
| `env.sh` | 阶段 07 环境变量 |
| `git.sh` | 阶段 08 Git |

## 阶段脚本

`stages/01-mirror.sh` … `08-git.sh`，由 `setup.sh` 按编号调用。

## 预设

- `base` → 01,02,03
- `dev` → 05
- `gpu` → 06
- `setup` → 07,08

重登后手动启动 compose（阶段 05 安装 Docker 后需重新登录使 docker 组生效）：

```bash
cd <repo>/config && docker compose up -d
```
