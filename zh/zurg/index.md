# zurg

zurg 把你的 debrid 账号和 Usenet 库合并到一个虚拟文件夹里。它本身不存储任何本地视频。在播放器请求之前，不会下载任何内容。一个 60 GB 的 remux 并不会占用 60 GB 的本地磁盘。

同一个库提供四种访问方式：

| 端点 | 用途 |
|---|---|
| `/dav/` | WebDAV，rclone 挂载的就是它 |
| `/http/` | HTML 目录浏览器 |
| `/infuse/` | 针对 Infuse 特性做了兼容的 WebDAV 变体 |
| `/strm/` | `.strm` 文件中的签名 URL，适用于需要 URL 而不是挂载的播放器 |

## 设置 {#setup}

让 zurg 在你的机器上跑起来。

- [Linux](setup/linux.md) — 需要 FUSE 3，并使用 systemd 自动启动
- [Docker](setup/docker.md) — 需要一台 Linux 主机，并带有主机可见的挂载点
- [macOS](setup/macos.md) — 需要 macFUSE，并使用 launchd 自动启动
- [Windows](setup/windows.md) — 需要 WinFsp，并使用盘符任务

## 服务商 {#providers}

让 zurg 指向一个账户。每个页面都会介绍凭据和 `config.yml` 条目。
示例使用 Docker。二进制安装使用相同的配置条目。命令请参阅 [Setup](setup/index.md)。

| 页面 | 它的不同之处 |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | 按文件选择、`__downloads__`、CDN 主机选择，以及单独的 `.strm` 令牌 |
| [TorBox](providers/torbox.md) | 每次媒体库刷新只发一个请求，限制的是活动槽位上限，而不是带宽 |
| [AllDebrid](providers/alldebrid.md) | 文件列表来自单独的接口，所以首次扫描会逐步补全 |
| [Premiumize](providers/premiumize.md) | 已完成的传输，加上留在云端的文件，并保留其文件夹结构 |
| [Debrid-Link](providers/debridlink.md) | 种子盒列表包含所有文件，并且没有缓存检查 |
| [Offcloud](providers/offcloud.md) | 文件大小对照交付服务器检查，文件夹路径来自缓存的元数据 |
| [Usenet](providers/usenet.md) | 将 `nzb` 类型作为提供商条目。没有令牌，改用监视目录 |
| [TorBox limits](providers/torbox-limits.md) | TorBox 限速背后的实测数据，以及 zurg 如何据此控制请求节奏 |
| [TorBox news server](providers/torbox-news-server.md) · [ElfHosted news server](providers/elfhosted-news-server.md) | 内置 Usenet 账户在网络上的实际表现 |

[通用页面](providers/index.md)介绍了在 Docker 中添加账户的三种方式，以及配置加载器强制执行的规则。

## 指南 {#guides}

使用媒体库。

- [Usenet](guides/usenet.md) — `nzb` 后端的完整流程：新闻账户、NZB、挂载，以及 Plex
- [Sonarr 和 Radarr 的 Usenet 设置](guides/sonarr-radarr.md) — 让 \*arrs 搜索，并由 zurg 以 SABnzbd 的身份应答，因此导入只是重命名，而不是下载
- [Sonarr 和 Radarr 的种子设置](guides/sonarr-radarr-torrents.md) — 做法相同，只不过由 zurg 以 qBittorrent 的身份应答；Prowlarr 也一样
- [zurg 为 Sonarr 和 Radarr 搜索](guides/sonarr-radarr-fetch.md)。Radarr 和 Sonarr 保留列表，zurg 负责查找并放置资源。两者都不需要任何索引器或下载客户端。
- [`__magic__`](guides/magic.md) — 唯一一个布局会被保存的目录，因此由你自己安排；你的媒体库会按标题归档，供 Kodi 和 Plex 使用
- [重命名](guides/renaming.md) — 在媒体库的任何位置重命名资源或文件。移动操作会被拒绝，页面会说明原因
- [Plex](guides/plex.md) — zurg 会用 Plex token 做什么，以及它刻意不做什么
- [Jellyfin](guides/jellyfin.md) — 同上，适用于 Jellyfin
- [rex 与 zurg](../rex/with-zurg.md) — 一个为 Plex 应用提供服务的媒体服务器，它不拥有任何文件，文件由 zurg 从你的 debrid 账户中填充。更多内容见 [rex](../rex/index.md)
- [Stremio 插件](guides/stremio.md) — Stremio 搜索你自己的索引器，并直接从 Usenet 后端播放
- [观看列表与 Seerr](guides/acquisition.md) 通过你自己的索引器获取你请求的内容
- [Plex 观看列表](guides/plex-watchlist.md) 是该功能的 Plex 部分
- [DMM 想要列表](guides/dmm-wanted.md) 获取你在 DMM 上点击 Want 的内容，无需任何其他设置
- [本地媒体库](guides/local-libraries.md) 通过你自己的账户播放共享的资源列表
- [Android 和 Google TV](guides/android.md) 在手机或电视盒子上运行整个媒体库

## 迁移 {#migrating}

Will not translate link targets. Keep names: AltMount, decypharr, InfiniDysk, nzbdav, streamnzb are project names, keep English.

将现有媒体库迁移到 zurg，无需重新下载，也无需重新扫描。

- [从 AltMount 迁移](migrate/altmount.md)
- [从 decypharr 迁移](migrate/decypharr.md)
- [从 InfiniDysk 迁移](migrate/infinidysk.md)
- [从 nzbdav 迁移](migrate/nzbdav.md)
- [从 streamnzb 迁移](migrate/streamnzb.md)

## 参考 {#reference}

- [Configuration](reference/config.md) — every option in `config.yml`
- [命令行](reference/cli.md) 列出了 binary 接受的每个命令和参数
- [对外身份](reference/outbound-identity.md) 说明 zurg 在调用的服务面前如何介绍自己
- [MCP 服务器](reference/mcp.md) 让 AI 智能体通过 Model Context Protocol 操作 zurg
- [Tags](reference/tags.md) — 会给种子加上哪些标签，以及为什么
- [Changelog](reference/changelog.md) — 每次改了什么

## 内部机制 {#internals}

zurg 的构建方式、测试数据，以及那些棘手部分背后的设计说明。

- [架构](internals/architecture.md)：整体结构，以及很容易被破坏的不变量
- [Debrid 基准数据](internals/debrid-baseline.md)：zurg 在 RD、AD 和 TorBox 上的开销与响应速度
- [种子生命周期](internals/torrent-lifecycle.md)：抓取过程中每个账户实际报告的内容，实时测量
- [SABnzbd 客户端契约](internals/sabnzbd-client-contract.md)：Sonarr 和 Radarr 期望的确切数据格式
- [Plex 回收站清理](internals/plex-trash-sweep.md) · [流媒体超时回归](internals/stream-timeout-regression.md) · [目录配置 UI/UX](internals/uiux.md)
- [E2E 测试](internals/e2e-test.md) · [Real-Debrid API 说明](internals/realdebrid-behavior.md)
- [qBittorrent 客户端契约](internals/qbittorrent-client-contract.md) · [持久化缓存](internals/persistent-caches.md)
- [命名规则](internals/naming.md) · [rclone 移动拒绝](internals/rclone-move-refusal.md)

---

zurg 面向赞助者发布：[GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [赞助](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
