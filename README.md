# dotfiles — Ubuntu / Kubuntu 基础环境

面向国内用户的开源 dotfiles：APT 镜像、常用系统包、可选开发栈与本地安装包目录。**不包含**破解资源、预置 deb/AppImage/tar 包，也不捆绑个人业务配置。

支持 **Ubuntu / Kubuntu 24.04** 与 **26.04**。仓库路径由 `git rev-parse` 或 `install/` 上级目录自动检测，无需固定 `~/Documents/dotfiles`。

## 快速开始

```bash
git clone <your-fork> dotfiles && cd dotfiles

cp config/config.env.example config/config.env
# 编辑 GIT_USER_NAME、GIT_USER_EMAIL、APT_MIRROR 等

cd install
chmod +x setup.sh stages/*.sh lib/*.sh
./setup.sh --preset base
```

可选：将自行下载的 `.deb` 放入 `installers/deb/`，AppImage 放入 `installers/appimage/`，tar 包（如 JetBrains Toolbox）放入 `installers/tar/`，再执行 `./setup.sh --stages 04`。

## 推荐顺序

| 步骤 | 命令                                             | 说明                                       |
| ---- | ------------------------------------------------ | ------------------------------------------ |
| 1    | `cp config/config.env.example config/config.env` | 填写 Git、镜像等                           |
| 2    | `./setup.sh --preset base`                       | 01→03 镜像与系统包                         |
| 3    | `./setup.sh --stages 04`                         | 可选：本地 deb/AppImage/tar                |
| 4    | Timeshift 快照                                   | 建议 `04-installers-ok` 或 `02-base-ready` |
| 5    | `./setup.sh --preset dev`                        | Java / Maven / nvm / Docker                |
| 6    | `./setup.sh --preset gpu`                        | NVIDIA，完成后**重启**                     |
| 7    | `./setup.sh --preset setup`                      | 环境变量、Git                              |

## 阶段一览

| 阶段 | 内容                                                                     |
| ---- | ------------------------------------------------------------------------ |
| 01   | APT 镜像（`APT_MIRROR=tuna\|official`）                                  |
| 02   | 基础包 `install/packages-base.txt`                                       |
| 03   | 系统包 `install/packages-extras.txt` + fcitx5（`INSTALL_FCITX5=1`）      |
| 04   | `installers/deb/`、`installers/appimage/`、`installers/tar/`（空则跳过） |
| 05   | SDKMAN Java、Maven、nvm、nrm、pnpm、Docker CE                            |
| 06   | NVIDIA（Timeshift 提示）                                                 |
| 07   | 将 `config.env` 中环境变量写入用户或系统 scope                           |
| 08   | `git config --global`                                                    |

重登后（docker 组生效），若需启动 compose 服务：

```bash
cp config/docker-compose.yaml.example config/docker-compose.yaml   # 首次
cd <repo>/config && docker compose up -d
```

`docker-compose.yaml.example` 仅为模板，安装器不会自动执行 compose。

## setup.sh 常用选项

```bash
./setup.sh --list-stages
./setup.sh --dry-run --stages 01,02,03
./setup.sh --release 24.04 --preset base
./setup.sh --stages 05 --yes
./setup.sh --help
```

预设：`base`（01-03）、`dev`（05）、`gpu`（06）、`setup`（07-08）。

## 目录结构

```
dotfiles/
├── config/           # 用户配置（*.example 在 git 中）
├── install/          # setup.sh、stages、lib、apt 源
├── installers/       # 用户自备 deb/AppImage/tar（不在 git）
├── scripts/          # 辅助脚本
└── README.md
```

- [config/README.md](config/README.md) — `config.env`、Maven、docker-compose 模板
- [install/README.md](install/README.md) — 阶段与 lib 说明
- [installers/README.md](installers/README.md) — 离线包放置方式
- [scripts/README.md](scripts/README.md) — `clean-proxy.sh` 等

## 验收示例

```bash
./setup.sh --dry-run --stages 01,02,03
java -version && mvn -v          # 阶段 05 后
node -v && pnpm -v
docker --version                 # 重登后
groups | grep -E 'docker|libvirt'
nvidia-smi                       # 阶段 06 重启后
```

## 首次清单

- fcitx5：`im-config` 选择 Fcitx 5，注销
- `installers/`：按需放入安装包后运行阶段 04
- 注销重登（docker / libvirt 组）
- 可选：`cd config && docker compose up -d`（复制 `docker-compose.yaml.example` 后）

## 许可

开源使用；请遵守各软件官方许可，勿将受版权保护的安装包提交到本仓库。
