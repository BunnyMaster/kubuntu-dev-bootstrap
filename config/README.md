# config/

用户级配置集中目录。仓库中仅保留 `*.example`；复制后的实际文件由 `.gitignore` 忽略。

## 文件

| 文件 | 说明 |
|------|------|
| `config.env.example` | 复制为 `config.env`，安装器选项 + 可导出环境变量 |
| `docker-compose.yaml.example` | 复制为 `docker-compose.yaml`，阶段 09 使用 |
| `maven-settings.xml.example` | 复制为 `maven-settings.xml`（阿里云镜像），阶段 05 可选 |

## config.env 两类键

**安装器选项**（仅 `setup.sh` 读取，阶段 07 不写入系统）：

- `APT_MIRROR`、`APT_UPGRADE`、`INSTALL_FCITX5`
- `GIT_USER_NAME`、`GIT_USER_EMAIL`
- `NODE_VERSION`、`NRM_REGISTRY`、`NPM_GLOBAL_PACKAGES`
- `JAVA_*`、`INSTALL_MAVEN`、`INSTALL_DOCKER`
- `ENV_SCOPE`（`user` 默认，或 `system`）

**环境变量**（阶段 07 写入）：

- 匹配 `^[A-Z_][A-Z0-9_]*=` 且不在上述安装器列表中的键
- 示例：`MY_API_BASE=https://api.example.com`

## 用法

```bash
cp config.env.example config.env
# 编辑后运行 install/setup.sh 各阶段
```

`ENV_SCOPE=user` 时写入 `~/.config/environment.d/99-dotfiles.conf`；`system` 时写入 `/etc/environment.d/`（需 sudo）。
