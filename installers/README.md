# installers/

用户自行下载的安装包目录，**不纳入 git**（见根目录 `.gitignore`）。

## 结构

```
installers/
├── deb/          # *.deb
├── appimage/     # *.AppImage / *.appimage
└── tar/          # *.tar.gz / *.tar（如 JetBrains Toolbox）
```

将文件放入对应子目录后，运行：

```bash
cd install
./setup.sh --stages 05
```

目录为空时阶段 05 会跳过相应步骤，不会失败。

## 说明

- 请从软件官网或网盘自行下载，勿将受版权限制的包提交到仓库
- deb 安装使用 `dpkg -i`，依赖问题会尝试 `apt-get -f install`
- AppImage 复制到 `/opt/appimages/` 并生成 `~/.local/share/applications/*.desktop`
- tar 解压到 `/opt/<归档名去掉扩展名>/`（如 `jetbrains-toolbox-2.5.3.25485.tar.gz` → `/opt/jetbrains-toolbox-2.5.3.25485/`），主程序设为可执行；已知格式（JetBrains Toolbox）会自动生成桌面项，其余包仅解压并提示自行创建 `.desktop`

## JetBrains Toolbox 示例

1. 从 [JetBrains Toolbox 下载页](https://www.jetbrains.com/toolbox-app/) 获取 Linux `.tar.gz`
2. 放入 `installers/tar/`，例如 `jetbrains-toolbox-2.5.3.25485.tar.gz`
3. 运行 `./setup.sh --stages 05`

## .gitkeep

`deb/`、`appimage/` 与 `tar/` 下保留 `.gitkeep` 以维持目录结构；实际安装包被 git 忽略。
