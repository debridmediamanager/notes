# Docker 部署 {#docker-setup}

本指南在 Docker 中运行 zurg，并把它的 FUSE 挂载暴露到 Linux 主机上。Docker 提供 zurg、rclone 和
ffprobe。内置的 `setup` 命令用于创建配置，`doctor` 用于检查安装。

本流程于 2026 年 9 月 4 日在 Docker Engine 29.1.1 上验证通过。请使用最新的带日期 nightly 版本，这样镜像才会包含下面的提供商选择器。

> **赞助者镜像：** `ghcr.io/debridmediamanager/zurg` 仅供赞助者使用。请在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助。赞助后，你的 GitHub 账户即可访问该镜像。

> **需要 Linux 主机：** 下面主机可见的挂载依赖 Linux 挂载传播（mount propagation）。Docker Desktop 在 macOS 和 Windows 上会把容器运行在虚拟机里：它无法把这个 FUSE 挂载传播到 Finder 或资源管理器中，rex 也无法访问其中的 zurg，因此那里无法播放任何内容。在这两种主机上，请改用 [macOS](https://notes.debridmediamanager.com/zh/zurg/setup/macos/) 或 [Windows](https://notes.debridmediamanager.com/zh/zurg/setup/windows/) 的二进制指南。如果 rex 运行在另一台 Linux 机器上，请为 zurg 容器设置 `network_mode: host`，具体见 [rex 与 zurg 配合使用](../../rex/with-zurg.md#d4-connect-zurg-to-rex)。

## 一行命令方式 {#one-line-option}

在全新的 Linux 主机上，可选的引导脚本可以在你同意后安装 Docker，配置持久的 FUSE 挂载传播（mount propagation），登录赞助者镜像仓库（sponsor registry），写入 Compose 项目，运行服务商选择器（provider chooser），并验证结果：

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

已有的 Compose 文件和配置会被保留。如果你更喜欢手动操作，下面的章节会逐步说明每一步。

## 安装程序在容器中做了什么 {#what-the-installer-does-in-a-container}

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` 会询问要配置哪些提供商，只提示输入它们的凭据，并把 `config.yml` 写入，权限为 `0600`。
- `--no-service` 把自动启动交给 Docker 的 `restart: unless-stopped` 策略处理，而不是尝试在 Alpine 里安装 systemd。
- `--skip-downloads` 直接使用镜像中已经安装的 rclone 和 ffprobe。
- `--mount-path` 记录哪个子目录的 FUSE 挂载会传播回主机。

再次运行 setup 是安全的。它会验证并更新安装，但不会替换已有的 `config.yml`。

## 1. 安装 Docker 并解锁镜像 {#1-install-docker-and-unlock-the-image}

在 Linux 主机上安装带 Compose 插件的 Docker Engine。继续之前,先检查这两条命令:

```bash
docker version
docker compose version
```

用你的 GitHub 用户名登录 GitHub Container Registry。提示输入密码时,粘贴一个同时带有 `read:packages` 和 `repo` 权限范围的经典个人访问令牌。这个镜像属于一个私有仓库,只有 `read:packages` 的令牌虽然能登录,拉取时仍会失败:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

把 `ZURG_TAG` 设置为最新的带日期赞助者版本。把它保存在 `.env` 里,你就有了一个明确的回滚目标,升级也会更清楚:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

继续之前,把占位符替换成实际的版本标签。

## 2. 准备 FUSE 挂载传播 {#2-prepare-fuse-mount-propagation}

FUSE 挂载必须创建在一个 shared 父挂载点下面。在第一个容器启动前运行一次以下命令：

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

检查设备和传播模式：

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

第二条命令应该在 `PROPAGATION` 下显示 `shared`。

## 3. 创建 Compose 项目 {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

创建 `docker-compose.yml`：

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

`privileged: true` 不是必需的。挂载实际需要的是较小的权限集合：FUSE 设备、`SYS_ADMIN` 能力，以及不受限的 AppArmor 配置文件。

不要直接绑定 `/zurg_mnt/zurg`。FUSE 挂载必须是 `rshared` 绑定的子挂载，它的挂载事件才能传到宿主机。

读取挂载的容器（尤其是 Sonarr 和 Radarr）从另一端遵循同样的规则：只绑定一次父目录（`/zurg_mnt`），使用 `rslave`，所有文件夹都通过这一个绑定访问。把 `__magic__/__all__` 和 `__magic__/tv` 作为两个卷挂载进 \*arr，会让每次导入都变成整个文件的一次复制。参见 [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。

## 4. 运行内置设置 {#4-run-the-built-in-setup}

From `~/zurg` run:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

按优先级选择一个或多个提供商。例如输入 `2,4`，即先选 TorBox，再选 Usenet。安装程序只会询问各提供商所需的凭据，在 `~/zurg` 中创建 `config.yml`，启用 rclone，并创建 `/zurg_mnt/zurg`。凭据不会保存在 compose 文件或 shell 历史记录中。

如果要自动化操作，可以重复使用 `--provider`，并传入对应提供商的 token-file 参数或 `--nntp-*` 参数。之后再次运行安装程序时，会保留已有的配置。

安装程序只会在创建 `config.yml` 的那次运行中写入账户。如果要给已有配置的安装添加提供商，请使用 Dashboard 中的 **Add provider**，或直接编辑配置文件，然后重启。每个服务都有自己的页面，里面介绍了凭据、配置块以及值得留意的限制：[服务提供商](../providers/index.md)。

## 5. 启动 zurg {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

按 `Ctrl+C` 即可退出日志视图,容器会继续运行。控制面板位于 `http://localhost:9999/config/`,它编辑的是与 compose 文件放在一起的同一个 `config.yml`。

库比较大时,加载可能要一段时间。在加载完成之前,挂载目录中的文件夹列表都会失败。它们会显示为空,或者报 `Input/output error`,但控制面板和 `version.txt` 仍然正常工作。这说明 zurg 还在加载,并不是挂载坏了。[启动完成与就绪](#up-versus-ready)说明了如何判断加载是否结束。

## 6. 用 doctor 验证 {#6-verify-with-doctor}

库准备好之后，运行和二进制安装时用的同一个诊断工具：

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` 会检查配置及其权限、ffprobe、rclone、FUSE、HTTP 端点，以及 zurg 报告的挂载情况。在 Docker 中出现 `WARN service zurg is not installed` 是正常的，因为自动启动由 Compose 管理。警告不会让命令失败，只有出现 `FAIL` 才会失败。

确认传播出来的挂载在容器外也能看到：

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. 让共享的父目录在重启后保持有效 {#7-make-the-shared-parent-survive-reboots}

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

下一次重启时，主机会先准备好共享的父目录，然后 Docker 再恢复 zurg 容器。

## Up 与 ready 的区别 {#up-versus-ready}

zurg 通过 HTTP 回答两个不同的问题。即使设置了 `username`，这两个地址也都不需要密码。

| 地址 | 返回 200 的条件 | 库加载期间 |
|---|---|---|
| `/http/version.txt` | zurg 正在运行 | 200 |
| `/ready` | 库已加载完成 | 503，并带 `Retry-After: 5` |

容器的健康检查使用第一个地址。zurg 一运行，`docker compose ps` 就会显示 `healthy`。库很大的话，之后还可能加载很久。如果需要完整的库，就请求 `/ready`。加载完成后，它会输出 `ready`。

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

脚本可以这样等待它。

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### 为什么健康检查不等待媒体库 {#why-the-health-check-does-not-wait-for-the-library}

Docker 对每个容器只保存一个健康状态。读取它的工具会把它理解为"zurg 还活着吗"。autoheal 和 Docker Swarm 会重启变为 unhealthy 的容器。`depends_on` 配合 `condition: service_healthy` 会让其他服务一直等到 zurg 变为健康为止。

大型资料库上有人报告过 15 到 90 分钟的冷启动时间。如果健康检查要等资料库加载完，那么所有依赖它的服务都得等这么久。zurg 前面的 rclone 容器在这段时间里挂载目录会一直是空的。对媒体服务器来说，空目录看起来就像资料库被删掉了。加载时间如果超过了健康检查的重试次数，容器也会被标记为 unhealthy。那些会重启 unhealthy 容器的工具就会让加载从头再来，结果永远也完不成。

### 在 Compose 中使用就绪检查 {#using-readiness-with-compose}

让挂载容器使用默认健康检查，这样只要 zurg 在运行，它的挂载就会尽快就绪。

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

在需要完整库的地方等待 `/ready`。这可能是扫描脚本，也可能是导入任务。

你也可以让 zurg 容器本身只在库加载完成后才报告健康。在 `docker-compose.yml` 中覆盖它的健康检查，并把 `start_period` 设得比最慢的加载时间更长。Docker 不会计入启动期内的失败。这样，所有依赖 zurg 的服务也都会等库加载完成。不要把这个方法和 autoheal 一起用。

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## 管理与更新 zurg {#managing-and-updating-zurg}

请在 `~/zurg` 目录下运行这些命令:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

Compose 项目会从 `.env` 中读取 `ZURG_TAG`。安装程序把它设为 `latest`,这样每次拉取都能获取最新的每夜构建版。要升级的话,先拉取镜像并重新创建容器,然后运行 doctor:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

这种情况下不要用 `zurg update`。它会拒绝在容器内运行:它写入的二进制文件保存在容器层中,容器一旦重新创建就会丢失,下一次 `up` 会悄悄退回到旧版本。请改为拉取镜像。如果你打算保留这个容器,可以用 `--force` 绕过这个拒绝。

要回滚的话,把 `.env` 中的 `ZURG_TAG` 设为某个特定的每夜构建标签,然后再运行这三条命令。绑定挂载的配置、库状态、日志和缓存不会随容器一起变化。

`docker compose down` 会删除容器和网络,但会保留 `~/zurg` 中的绑定挂载文件以及挂载父目录 `/zurg_mnt`。

## 各类文件存放位置 {#what-lives-where}

zurg 写入的所有内容都会解析到 `/config` 下，所以只要一个 `./:/config` 挂载，就能容纳整个安装：

| 路径 | 用途 |
|---|---|
| `config.yml` | 设置和服务商凭据；Dashboard 中的修改会写回这里 |
| `data/` | 库状态、本地文件、生成的密钥以及 rclone VFS 缓存 |
| `logs/` | zurg 和 rclone 日志 |
| `dump/` | 启用后的种子转储 |
| `strm/` | 启用 `save_strm_files` 后生成的 `.strm` 文件 |
| `nzbs/` | Usenet 后端的监视目录 |

拉取或重新创建镜像不会改变这些文件。

`data/rclone-cache` 是唯一会不断增长的目录。挂载会把它读取的每个文件完整下载下来，播放结束后也会保留，默认最多 **256G**。因此挂载目录需要在其他所有内容之外再留出缓存的空间。72 小时的过期时间限制实际上起不到限制作用：任何读取库的操作（包括媒体服务器的夜间扫描）都算作访问了该文件。

```bash
du -sh ./data/rclone-cache
```

如果主机磁盘放不下这么多，可以在 `config.yml` 里把上限调低：

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

修改 `/config` 背后的主机路径会使缓存目录被重命名，旧的副本就会被遗留。zurg 会在下次启动时回收这些遗留目录，并在日志中记录释放了什么。详见 [config.md](../reference/config.md#disk-the-mount-uses)。

### 无人值守安装的环境变量预置 {#environment-seeding-for-unattended-installs}

镜像仍然支持较早的首次运行方式。如果不存在 `config.yml`，`TOKEN` 或 `RD_TOKEN` 会用来初始化账号，`MOUNT_PATH` 则用来启用挂载。这些变量只在创建该文件时读取，之后每次启动都以该文件为准。

在运行中的容器里，只有 Real-Debrid 账号可以用这种方式初始化。`TORBOX_TOKEN`、`ALLDEBRID_TOKEN`、`PREMIUMIZE_TOKEN`、`DEBRIDLINK_TOKEN`、`OFFCLOUD_TOKEN` 和 `NNTP_HOST` 由 `zurg setup` 读取，所以它们在上面那个一次性的 setup 容器中生效。如果放在服务的 `environment:` 配置块里，则不会起任何作用。

对于在终端前手动操作的人来说，更推荐使用交互式的 `setup` 命令，因为这样 token 就不会写进 compose 文件。如果自动化流程已经有自己的密钥存储，通过环境变量初始化仍然很有用。

### 升级已挂载 `/app` 的安装 {#upgrading-an-install-that-mounted-app}

旧版 compose 项目会分别把 `/app/config.yml`、`/app/data` 和其他路径挂载到宿主机。只要入口脚本发现这种布局，它仍会选择 `/app`。因此拉取较新的镜像后，程序继续使用旧的配置和缓存。

要改用单目录布局，请先停止容器，然后把现有的 `config.yml`、`data/` 以及其他状态目录复制到宿主机上的同一个目录中，再把该目录挂载到 `/config`。

## 故障排除 {#troubleshooting}

先从诊断信息和当前日志开始：

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` 或 `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

这个容器早于内置安装程序。请使用 `2026.09.04.1449-nightly` 或更新的带日期 zurg 镜像，然后重新创建容器：

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

旧的 FUSE 挂载已经失效了:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### FUSE 设备不可用 {#fuse-device-is-unavailable}

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

然后确认 compose 服务中仍包含 `/dev/fuse`、`SYS_ADMIN` 以及 AppArmor 设置。

### 挂载点为空 {#mount-is-empty}

按顺序逐层检查：

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

宿主机路径必须是共享的 bind mount，compose 的 volume 必须把上层目录以 `/zurg_mnt:/zurg_mnt:rshared` 的形式挂载进去。

如果 `/ready` 返回错误 503，说明库还在加载，挂载本身没问题。在加载完成之前，它的文件夹会显示为空，或者显示 `Input/output error`。耐心等它加载完，不要重启 zurg。重启会让加载从头开始。

### `mount` 输出中挂载点出现两次 {#mount-appears-twice-in-mount-output}

这很正常。同一个 FUSE 挂载在容器和宿主机的挂载命名空间里都能看到，说明挂载传播（propagation）是正常工作的。

还是卡住了？可以到 [Discord](https://discord.com/invite/7u4YjMThXP) 的 **zurg-support** 论坛提问。[Getting help](../../guides/remote-help.md) 里写了提问时需要附上哪些信息。
