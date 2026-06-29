# config/

| 文件 | 说明 |
|------|------|
| `config.env` | 安装器选项（镜像、Git、开发栈等） |
| `environment.env` | 阶段 07 导出的 shell 环境变量 |
| `maven-settings.xml` | Maven 配置（阿里云镜像），阶段 04 可选 |
| `docker-compose.yaml` | 本地开发栈示例，安装器不自动执行 |

## config.env

安装器各阶段读取的选项，例如：

- `APT_MIRROR`、`APT_UPGRADE`、`INSTALL_FCITX5`
- `GIT_USER_NAME`、`GIT_USER_EMAIL`
- `NODE_VERSION`、`NRM_REGISTRY`、`NPM_GLOBAL_PACKAGES`
- `JAVA_INSTALL`（逗号分隔 OpenJDK 主版本，如 `17,21`）、`JAVA_DEFAULT`（默认 JDK，须在 `JAVA_INSTALL` 中）
- `MAVEN_VERSION`、`INSTALL_MAVEN`、`INSTALL_DOCKER`
- `ENV_SCOPE`（`user` 默认，或 `system`）— 控制阶段 07 写入位置

## environment.env

阶段 07 读取，将 `KEY=VALUE` 写入系统或用户环境：

- 每行一个变量；`#` 开头为注释；空行忽略
- 键名须匹配 `^[A-Z_][A-Z0-9_]*=`
- 示例：`MY_API_BASE=https://api.example.com`

## Docker Compose

安装器不自动执行 compose。重登使 docker 组生效后：

```bash
cd <repo>/config && docker compose up -d
```
