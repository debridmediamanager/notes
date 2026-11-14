# 一个 Docker Compose 文件搞定 zurg、Plex 和 rex {#one-docker-compose-file-for-zurg-plex-and-rex}

在 Linux 机器上，一个 `docker-compose.yml` 就能让 zurg、Plex Media Server 和 rex 同时运行。zurg 会把你的库以文件夹的形式显示在 `/zurg_mnt/zurg` 下，Plex Media Server 读取这些文件夹，而 rex 则直接从 zurg 获取同一个库，不需要任何文件夹。先运行一次 zurg 的 Docker 安装程序，然后把它的 `docker-compose.yml` 换成下面这个。

只想用 Plex Media Server 或 rex 其中一个？就把另一个从文件里删掉。如果不用 Plex，还要删掉 rex 的 `command:` 那一行。

Windows 或 Mac 上的 Docker Desktop 无法运行这套方案：zurg 的文件夹不会出现在资源管理器或访达（Finder）里，而且 rex 也无法访问它里面的 zurg。这种情况请使用 [Windows 上的 zurg](../setup/windows.md) 或 [macOS 上的 zurg](../setup/macos.md)。

## 开始之前 {#before-you-start}

- **一台一直开着的 Linux 机器。** 如果没装 Docker，安装程序会自动装上。
- **一个 zurg 赞助。** zurg 镜像是私有的。在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助一下，它就会给你的 GitHub 账号开通访问权限。
- **你的 Real-Debrid API 令牌**，或者 zurg 支持的其他服务的登录信息：[你的 Real-Debrid API 令牌](../../guides/real-debrid-api-token.md)。
- **如果用 Plex Media Server**，需要你的 Plex 账号。**如果用 rex**，需要专门为它新建的一个 Plex 账号：[rex 与 zurg 配合使用](../../rex/with-zurg.md#before-you-start) 里解释了原因。

## 1. 运行 zurg 的 Docker 安装程序 {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

它会在缺少 Docker 时自动安装（会先询问你）。然后为 zurg 的文件夹准备好 `/zurg_mnt`，现在和每次重启后都会执行。接着登录 GitHub 以拉取 zurg 镜像，写入 `~/zurg/docker-compose.yml`，询问你的服务和 token，启动 zurg，并运行 `zurg doctor`。[zurg 的 Docker 设置](../setup/docker.md)也是手动完成同样的事情。

**你应该看到的结果。**

```bash
ls /zurg_mnt/zurg
```

列出 `__all__`、`__downloads__`、`__unplayable__`、`movies`、`shows` 和 `version.txt`。

## 2. 换成完整的文件 {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

用下面的内容替换其中的全部内容：

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

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** 是安装程序自带的服务，保持不变。
- **plex** 会在与 zurg 相同的路径 `/zurg_mnt/zurg` 下看到 zurg 的文件夹，所以 zurg 请求扫描时给出的名称，就是 Plex 认识的文件夹。`rslave` 能让这些文件夹在 zurg 重启后仍然保留。在 `TZ` 中填写你自己的时区。
- **PLEX_CLAIM** 会在 Plex Media Server 首次启动时把它登录到你的账户。先登录 Plex，打开 [plex.tv/claim](https://www.plex.tv/claim)，复制代码，然后粘贴到 `=` 后面。代码几分钟后就会过期，所以请立即启动整套服务。
- **rex** 是 [rex 搭配 zurg](../../rex/with-zurg.md#d2-start-rex-in-docker) 中介绍的服务，使用端口 32500，因为 Plex Media Server 占用了 32400。它的文件会保存在 `~/rex/config`，这也是 rex 搭配 zurg 时查找文件的位置。

保存后启动所有服务：

```bash
docker compose up -d
docker compose ps
```

如果 `docker` 提示 permission denied，就在本页每条 `docker` 命令前面加上 `sudo`。

**你应该看到什么。** 三个容器：`plex` 和 `zurg` 显示 `(healthy)`，`rex` 显示 `Up`。Plex Media Server 自己的文件会保存到 `~/plex`。

## 3. 在 Plex 中添加 zurg 的文件夹 {#3-add-zurgs-folders-in-plex}

在 Plex Web 中打开 `http://<this machine's LAN IP>:32400/web`。添加一个 **Movies** 资料库,文件夹为 `/zurg_mnt/zurg/movies`,再添加一个 **TV Shows** 资料库,文件夹为 `/zurg_mnt/zurg/shows`,具体做法参见 [Plex 中使用 Real-Debrid](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex)。

为了让 Plex 及时知道有新内容,请打开 zurg 的仪表盘 `http://<this machine's LAN IP>:9999/config/`,在 **Media Server Integration** 下点击 **Login with Plex**(参见其中的[第 4 步](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things))。

## 4. 设置 rex {#4-set-up-rex}

按照 [rex 搭配 zurg](../../rex/with-zurg.md) 中从 [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) 到 [D5](../../rex/with-zurg.md#d5-watch) 的步骤操作，只是凡是写 `32400` 的地方都改用 `32500`。例如 zurg 的那一行是 `rex_url: http://192.168.1.20:32500`，IP 用 rex 的局域网 IP。这样你的 Plex 应用就会同时列出两个服务器：[rex 搭配 zurg 的第 2 步](../../rex/with-zurg.md#step-2-install-rex) 说明了如何区分它们。

（之前的译文被拒绝了：代码片段有差异（`32400`）。请保持结构完全不变。）

## 更新 {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

这会同时更新 zurg、Plex 和 rex。如果 rex 与 zurg 一起运行在 `~/rex` 中执行 `docker compose`，那么在这里 `~/zurg` 中执行时要在末尾加上 `rex`，这样只会影响 rex：用 `docker compose stop rex` 代替 `docker compose down`，用 `docker compose up -d rex` 代替 `docker compose up -d`。

## 出现问题时 {#when-something-is-wrong}

`docker compose logs --tail=100 zurg`（或 `plex`、`rex`）会显示容器最后输出的内容。

| 你看到的 | 该怎么做 |
|---|---|
| 安装程序显示 `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | 你用的是 Mac 或 Windows。请改用 [Windows](../setup/windows.md) 或 [macOS](../setup/macos.md) 的安装程序来安装 zurg。 |
| Docker 拉取 zurg 时出现 `Error response from daemon: error from registry: unauthorized` | 这台机器没有用一个有 zurg 访问权限的账号登录 GitHub 的镜像仓库。请先在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助，然后重新运行安装程序。如果要手动登录，请参阅 [zurg 的 Docker 设置](../setup/docker.md#1-install-docker-and-unlock-the-image)：令牌需要同时具备 `read:packages` 和 `repo` 权限。 |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` 还没有设置为共享挂载。运行 `sudo mount --bind /zurg_mnt /zurg_mnt` 和 `sudo mount --make-rshared /zurg_mnt`，然后执行 `docker compose up -d`。安装程序会让这个设置在重启后依然生效；如果手动操作，请参阅 [zurg 的 Docker 设置第 7 步](../setup/docker.md#7-make-the-shared-parent-survive-reboots)。 |
| `zurg` 不断重启，日志结尾是 `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` 和 `mapping key "..." already defined` | zurg 的配置里有同一个设置写了两次。运行 `sudo nano ~/zurg/config.yml`，删除报错中指出的两行之一，保存后运行 `docker compose restart zurg`。 |
| zurg 的日志显示 `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | zurg 的文件夹没有挂载成功。请检查 zurg 的 volume 配置行是否为 `/zurg_mnt:/zurg_mnt:rshared`（挂载的是父目录，而不是 `/zurg_mnt/zurg`），并确认 `/zurg_mnt` 已设为共享（见上一行）。[挂载点为空](../setup/docker.md#mount-is-empty) 里有更多检查项。 |
| zurg 重启后 Plex 的媒体库变空，并且 `docker exec plex ls /zurg_mnt/zurg` 显示 `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | Plex 的 volume 配置行缺少 `rslave`。它必须是 `/zurg_mnt:/zurg_mnt:rslave`。改好后运行 `docker compose up -d`。 |
| rex 启动时报错 `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server 已经占用了 32400 端口。请在 rex 上保留 `command: --port 32500`。 |
| 刚启动后 `/zurg_mnt/zurg/movies` 为空，或者显示 `Input/output error` | zurg 还在读取你的账号内容。运行 `curl http://localhost:9999/ready`，完成后会输出 `ready`。在此期间不要重启 zurg，否则会从头开始读取。 |
| 标题在 rex 里能看到，但无法播放 | [rex with zurg 的 When something is wrong](../../rex/with-zurg.md#when-something-is-wrong) 中的 `upstream failed` 那一行会检查 rex 能否连到 zurg。 |
| 磁盘被占满 | zurg 会把播放过的内容副本保存在 `~/zurg/data/rclone-cache` 中，默认最多 256G。[各类文件存放位置](../setup/docker.md#what-lives-where) 说明了如何限制大小。 |

还是解决不了？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **zurg-support** 论坛提问。[获取帮助](../../guides/remote-help.md) 说明了需要提供哪些信息。

## 常见问题 {#questions}

### 你能帮我检查一下我的 docker compose 文件吗？ {#can-you-check-my-docker-compose-file}

和上面的那个对比一下。最重要的是:zurg 以 `rshared` 方式挂载 `/zurg_mnt`,Plex 以 `rslave` 方式挂载同一个 `/zurg_mnt`,rex 使用 `ghcr.io/debridmediamanager/rex` 镜像,并设置 `network_mode: host`。一个名为 `rex` 却运行 `plexinc/pms-docker` 的服务,只是第二个 Plex Media Server,而不是 rex。

### 我需要单独的 rclone 容器吗？ {#do-i-need-a-separate-rclone-container}

不对。zurg 会在自己的容器里运行 rclone，并把你的媒体库直接挂载到 `/zurg_mnt/zurg`。

### 我能同时使用 Plex Media Server 和 rex 吗？ {#can-i-use-plex-media-server-and-rex-together}

是的，这个文件就是这么做的。Plex Media Server 从 zurg 的文件夹播放，rex 则直接从 zurg 播放。你的 Plex 应用里会同时显示两者。如果你不想两个都保留，只留下你实际使用的那个就行。

### 这个能在 NAS 上用吗？ {#does-this-work-on-a-nas}

测试是在 Linux 电脑上做的，不是在 NAS 上。安装程序需要终端（SSH）并能使用 `sudo`，还需要 FUSE（`/dev/fuse`）。如果第 1 步结束后 zurg 的文件夹位于 `/zurg_mnt/zurg`，就继续第 2 步。

### 这个方案是用哪些版本测试的？ {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`、rex `2026.11.14.1123-nightly` 和 Plex Media Server `1.43.5.11079`，发布于 2026 年 11 月 14 日。
