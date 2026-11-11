# Whisparr

Whisparr 是用于成人电影和场景的 Radarr。它把 zurg 当作自己的 qBittorrent 客户端使用。抓取的内容会发送到你的 debrid 账户。导入只是重命名 `__magic__` 里面的一个路径，不会下载或复制任何内容。

以下所有内容都是在 2026-10-23 测试的，使用的是 Whisparr `3.6.5.1886`（`ghcr.io/hotio/whisparr:v3` 镜像）、Prowlarr、当天 `main` 分支构建的 zurg，以及一个 Real-Debrid 账户。一部 17 GB 的电影被抓取、导入，并从挂载点成功播放。

## 开始之前 {#before-you-start}

请先为 Radarr 设置 zurg，参考 [用于种子的 Sonarr 和 Radarr](sonarr-radarr-torrents.md)：需要一个能接收种子的账户，开启 `__magic__`，并开启 qBittorrent 端点。Whisparr 会复用这些设置。

## 1. zurg 中 Whisparr 的分类 {#1-whisparrs-category-in-zurg}

Whisparr 会在分类 `whisparr` 下发送它的抓取请求。第 3 步中它的 **Test** 按钮会在 zurg 中创建该分类，所以无需再手动添加。如果你还是想把它列在 `config.yml` 里，就把它加在已有分类旁边：

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. 运行 Whisparr {#2-run-whisparr}

在 Linux 主机上，给 Whisparr 挂载和 Radarr 相同的卷，也就是 zurg 挂载点**上一级**的文件夹，并使用 `rslave`（[原因见这里](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)）：

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` 和 `PGID` 是 Whisparr 运行时所用的 Linux 用户。zurg 自己的 Docker 镜像允许任何用户读取它的挂载点。如果 zurg 是作为普通二进制文件安装的，只有在它以 root 运行或启用了 `user_allow_other` 时才行（[Linux 安装说明](../setup/linux.md#1-install-fuse-3)）。否则，请把 `PUID` 和 `PGID` 设为运行 zurg 的用户（`id -u` 和 `id -g` 会输出这些值），不然 Whisparr 看到的挂载点就是空的。

在 macOS 和 Windows 上，这个 compose 文件不适用，原因见 [Usenet 指南的第 8 步](sonarr-radarr.md#8-if-your-arr-is-in-docker)。在这些系统上，请把 Whisparr 当作普通应用安装，并注意该指南中[开始之前](sonarr-radarr.md#before-you-start)列出的几点：macOS 上要使用和 zurg 相同的用户；Windows 上要用托盘应用，而不是 Windows 服务。我们只测试过上面的 Docker 镜像。

打开 `http://<your server>:6969`。

## 3. 添加 zurg 作为下载客户端 {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**，各字段的填法与 Radarr 完全相同（[字段说明](sonarr-radarr-torrents.md#what-to-put-in-each-field)），只是 **Category** 要填 `whisparr`。**Remove Completed** 保持开启。先点 **Test**，再点 **Save**。

## 4. 添加根文件夹 {#4-add-the-root-folder}

在挂载点上创建文件夹，然后在 **Settings → Media Management → Root Folders** 中添加它：

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

它应该与 `__magic__/movies` 并列，而不是放在它里面。Whisparr 会按片商把每部影片放在对应的文件夹下，路径为 `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`。

## 5. 索引器 {#5-indexers}

DMM 的索引器没有成人分类，所以 Whisparr 需要其他索引器。在 Prowlarr 里，公共索引器 **Knaben** 和 **The Pirate Bay** 都能用。**XXXClub** 在 Cloudflare 后面，如果没有 Cloudflare 解算器，Prowlarr 无法添加它。

然后在 Prowlarr 的 **Settings → Apps → + → Whisparr** 里把 Prowlarr 连接到 Whisparr，填上 Whisparr 的地址和 API key（在 Whisparr 的 **Settings → General** 里可以找到）。Prowlarr 会把它的索引器直接添加到 Whisparr 里。

zurg 只接受你的账户已经持有的资源（`cached_only`，默认开启）。当它拒绝某个资源时，Whisparr 会自动取下一个结果。

## 6. 抓取一个 {#6-grab-one}

在 Whisparr 中添加一部电影，并勾选 **Start search for missing movie**。成功后，Whisparr 的历史记录会在几秒内先显示 **Grabbed**，然后显示 **Imported**，电影也会出现在挂载目录中：

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

在 macOS 上，路径以 `/Volumes/Zurg` 开头；在 Windows 上，请在资源管理器中打开 `Z:\__magic__\whisparr\movies`。zurg 的 `data/local` 文件夹里不会出现任何文件。文件是从你的账户串流过来的。

## 观看 {#watching-it}

点击 Plex 或 Jellyfin 的库，把它指向 `/mnt/zurg/__magic__/whisparr`（macOS 上是 `/Volumes/Zurg/__magic__/whisparr`，Windows 上是 `Z:\__magic__\whisparr`），这样这些影片就能单独放在一个库里。

在 rex 里，它们会和其他资源一样，出现在 zurg 文件夹归类到的那个库中。在大多数配置下，这个库就是电影库。
