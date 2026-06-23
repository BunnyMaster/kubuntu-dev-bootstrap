# Kubuntu 基础环境

面向国内用户的开源 dotfiles：APT 镜像、常用系统包、可选开发栈与本地安装包目录。

支持 **Ubuntu / Kubuntu 24.04** 与 **26.04**。

## 快速开始

> [!TIP]
>
> 执行时可以使用阶段命令：`bash setup.sh --stages 01,02,03,04,05,07,08,09`

```bash
git clone https://github.com/BunnyMaster/kubuntu-dev-bootstrap.git dotfiles && cd dotfiles

# 按需编辑 config/config.env（Git、镜像等）与 config/environment.env（可选）
cd install
chmod +x setup.sh stages/*.sh lib/*.sh

./setup.sh --preset base
```

## 配置说明

### config 文件夹

克隆后按需编辑 `config/` 中的配置文件：

- `config.env` — 安装器选项（镜像、Git、开发栈等）
- `environment.env`（可选）— 阶段 07 导出的 shell 环境变量
- `maven-settings.xml` — Maven 阿里云镜像，阶段 05 使用
- `docker-compose.yaml` — 本地开发栈示例，安装器不自动执行

```bash
# ── Git（阶段 08）──────────────────────────────────────
GIT_USER_NAME=example
GIT_USER_EMAIL=example@gmail.com
```

### 自定义安装包

如果需要安装自己的`.deb`、`AppImage`、`tar`放入`installers`文件夹下即可；安装包目录结构示例：

```bash
├── appimage
│   └── navicat17-premium-cs-x86_64.AppImage
├── deb
│   ├── apifox_2.8.31_amd64.deb
│   ├── code_1.121.0-1779186519_amd64.deb
│   ├── cursor_3.5.33_amd64.deb
│   ├── google-chrome-stable_current_amd64.deb
│   ├── obsidian_1.12.7_amd64.deb
│   ├── QQ_3.2.28_260429_amd64_01.deb
│   └── typora.deb
├── README.md
└── tar
 └── jetbrains-toolbox-3.4.3.81140.tar.gz
```

## 执行说明

### 推荐顺序

| 步骤 | 命令                                             | 说明                                       |
| ---- | ------------------------------------------------ | ------------------------------------------ |
| 1    | 编辑 `config/config.env`                         | 填写 Git、镜像等安装器选项                   |
| 1b   | 编辑 `config/environment.env`（可选）            | 自定义环境变量（阶段 07）                    |
| 2    | `./setup.sh --preset base`                       | 01→03 镜像与系统包                         |
| 3    | `./setup.sh --stages 04`                         | 可选：本地 deb/AppImage/tar                |
| 4    | Timeshift 快照                                   | 建议 `04-installers-ok` 或 `02-base-ready` |
| 5    | `./setup.sh --preset dev`                        | Java / Maven / nvm / Docker                |
| 6    | `./setup.sh --preset gpu`                        | NVIDIA，完成后**重启**                     |
| 7    | `./setup.sh --preset setup`                      | 环境变量、Git                              |

### 阶段一览

| 阶段 | 内容                                                                     |
| ---- | ------------------------------------------------------------------------ |
| 01   | APT 镜像（`APT_MIRROR=tuna\|official`）                                  |
| 02   | 基础包 `install/packages-base.txt`                                       |
| 03   | 系统包 `install/packages-extras.txt` + fcitx5（`INSTALL_FCITX5=1`）      |
| 04   | `installers/deb/`、`installers/appimage/`、`installers/tar/`（空则跳过） |
| 05   | SDKMAN Java、Maven、nvm、nrm、pnpm、Docker CE                            |
| 06   | NVIDIA（Timeshift 提示）                                                 |
| 07   | 将 `environment.env` 中环境变量写入用户或系统 scope（`ENV_SCOPE` 在 config.env） |
| 08   | `git config --global`                                                    |

## 目录结构

```
dotfiles/
├── config/           # 配置文件（随仓库提供，按需修改）
├── install/          # setup.sh、stages、lib、apt 源
├── installers/       # 用户自备 deb/AppImage/tar（不在 git）
├── scripts/          # 辅助脚本
└── README.md
```

## 验收示例

```bash
./setup.sh --dry-run --stages 01,02,03
java -version && mvn -v          # 阶段 05 后
node -v && pnpm -v
docker --version                 # 重登后
groups | grep -E 'docker|libvirt'
nvidia-smi                       # 阶段 06 重启后
```

### 首次清单

- fcitx5：`im-config` 选择 Fcitx 5，注销
- `installers/`：按需放入安装包后运行阶段 04
- 注销重登（docker / libvirt 组）
- 可选：`cd config && docker compose up -d`

## 许可

开源使用；请遵守各软件官方许可，勿将受版权保护的安装包提交到本仓库。
