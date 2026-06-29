# Kubuntu 基础环境

> [!CAUTION]
>
> **NVIDIA 驱动（阶段 09）风险较高，安装前需注意**
>
> - 驱动版本与显卡/内核不匹配可能导致**黑屏**、桌面无法启动或登录循环。
> - **Secure Boot** 未关闭时专有驱动可能无法加载；缺少对应 **linux-headers** 时 DKMS 编译会失败。
> - 阶段 09 通过 `ubuntu-drivers devices` 检测推荐包，再执行 `ubuntu-drivers install` 安装。
> - 本脚本在 **4060 Ti** 上测试通过；其他型号、笔记本或双显卡机型行为可能不同，请自行核对推荐驱动后再继续。

面向国内用户的开源 dotfiles：APT 镜像、常用系统包、可选开发栈与本地安装包目录。

支持 **Ubuntu / Kubuntu 24.04** 与 **26.04**。

## 快速开始

> [!TIP]
>
> 执行时可以使用阶段命令：`bash setup.sh --stages 01,02,03,04,05,06,07,08`

```bash
git clone https://github.com/BunnyMaster/kubuntu-dev-bootstrap.git dotfiles && cd dotfiles

# 按需编辑 config/config.env（Git、镜像等）与 config/environment.env（可选）
cd install
chmod +x setup.sh stages/*.sh lib/*.sh

./setup.sh --preset base
./setup.sh --preset dev                 # 需外网（Maven/nvm/Docker）
./setup.sh --preset local               # 可选：本地 deb/AppImage/tar
./setup.sh --preset setup               # 可选：Git + 环境变量
./setup.sh --stages 08                  # fcitx5
./setup.sh --preset gpu                 # 最后，重启后
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

### config 文件夹

克隆后按需编辑 `config/` 中的配置文件：

- `config.env` — 安装器选项（镜像、Git、开发栈等）
- `environment.env`（可选）— 阶段 07 导出的 shell 环境变量
- `maven-settings.xml` — Maven 阿里云镜像，阶段 04 使用
- `docker-compose.yaml` — 本地开发栈示例，安装器不自动执行

```bash
# ── Git（阶段 06）──────────────────────────────────────
GIT_USER_NAME=example
GIT_USER_EMAIL=example@gmail.com
```

## 执行说明

### 阶段一览

| 阶段 | 内容                                                                             |
| ---- | -------------------------------------------------------------------------------- |
| 01   | APT 镜像（`APT_MIRROR=tuna\|official`）                                          |
| 02   | 基础包 `install/packages-base.txt`（仅 apt）                                     |
| 03   | 系统包 `install/packages-extras.txt`（仅 apt，不含 fcitx5）                      |
| 04   | APT Java、Apache Maven、nvm、nrm、pnpm、Docker CE（需外网）                     |
| 05   | `installers/deb/`、`installers/appimage/`、`installers/tar/`（空则跳过）         |
| 06   | `git config --global`（可选确认）                                                |
| 07   | 将 `environment.env` 中环境变量写入用户或系统 scope（`ENV_SCOPE` 在 config.env） |
| 08   | fcitx5 包 `install/packages-fcitx5.txt` + 词库（词库需外网确认）                 |
| 09   | NVIDIA（`ubuntu-drivers`，Timeshift 提示）                                       |

### 交互确认

默认情况下，以下阶段会暂停等待人工确认（输入 `y` 继续）：

| 阶段      | 确认时机                                  | 说明                                                                                                      |
| --------- | ----------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| 04 dev    | 阶段开始时 1 次                           | 「网络可访问外网（Maven/nvm/Docker 需下载），继续？」确认后 Java、Maven、nvm 等将自动安装，不再二次确认 |
| 06 git    | 写入前 1 次                               | 「确认写入 git config --global？」                                                                        |
| 08 fcitx5 | apt 安装完成后 1 次                       | 「下载 fcitx5 拼音词库？（需访问 GitHub 外网）」                                                          |
| 09 nvidia | 阶段开始时 1 次                           | 「已做好快照并了解风险，继续？」（含 Timeshift、Secure Boot、重启提示）                                   |
| 09 nvidia | 显示 `ubuntu-drivers devices` 输出后 1 次 | 「执行 ubuntu-drivers install 安装推荐驱动？」拒绝时可据 `/tmp/dotfiles-ubuntu-drivers.txt` 手动安装      |

使用 `./setup.sh --yes` 或 `-y` 可跳过**全部**确认（阶段 09 会直接执行 `ubuntu-drivers install`，请谨慎使用）。

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
java -version && mvn -v          # 阶段 04 后
node -v && pnpm -v
docker --version                 # 重登后
groups | grep -E 'docker|libvirt'
nvidia-smi                       # 阶段 09 重启后
```

### 首次清单

- fcitx5（阶段 08）：`im-config` 选择 Fcitx 5，注销
- `installers/`：按需放入安装包后运行阶段 05
- 注销重登（docker / libvirt 组）
- 可选：`cd config && docker compose up -d`

## 许可

开源使用；请遵守各软件官方许可，勿将受版权保护的安装包提交到本仓库。
