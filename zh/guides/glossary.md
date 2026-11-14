# 各部分的作用 {#what-each-piece-does}

名字本身看不出各自的用途，所以这里每个都用一句话说明。没有标注 **For sponsors** 的都是免费的。要找出你需要哪些，请看 [Choose your setup](choose-your-setup.md)。

## 三个项目 {#the-three-projects}

| 名称 | 功能 |
|---|---|
| [DMM](https://debridmediamanager.com)（Debrid Media Manager） | 一个用来查找资源并将其添加到你的 debrid 账户的网站。它也会搜索 Usenet 和 Easynews |
| [zurg](../zurg/index.md) | 将所有 debrid 账户和 Usenet 合并为一个媒体库。Plex、Jellyfin 和 Emby 以文件夹的方式读取它，Infuse 和 Kodi 通过 WebDAV 读取，rex 则直接获取。当前版本仅面向赞助者提供 |
| [rex](../rex/index.md) | 一个供 Plex 应用使用的媒体服务器，本身不存储任何文件。由 zurg 或插件告诉它有哪些内容。个人使用免费 |

## 直接从 DMM 观看 {#watching-straight-from-dmm}

不需要服务器也能用这些工具。

| 名称 | 功能 |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | 一个 Stremio 插件，可以播放你 debrid 或 Easynews 账户中的资源。在 Nuvio 中也能用 |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | 在 Kodi 中浏览、搜索并播放你 debrid 或 Easynews 账户中的内容 |
| DMM Watch | DMM 上的一个按钮，可以用你自己的播放器打开文件，比如 VLC 或 Infuse |

## 为 rex 提供内容 {#feeding-rex}

| 名称 | 功能说明 |
|---|---|
| [rex-stremio](../rex/stremio.md) | 把你的 Stremio 插件变成 rex 媒体库，让它们可以在 Plex 应用中播放 |
| [rex 插件](../rex/addons.md) | 为 rex 提供播放内容的小程序，例如 YouTube、Spotify、IPTV、家庭视频，或你自己编写的任何内容 |
| [rex-live-sports](../rex/live-tv.md) | 一个 rex 插件，把体育直播频道和节目指南加入 Plex 应用的 Live TV 中 |
| [rex-direct](../rex/any-source.md#rex-direct) | 为你的 rex 提供专属的安全地址，让 Plex 应用在外面也能访问它 |
| [rex for Android](../rex/android.md) | 在 Android 手机或电视盒子上运行 rex 及其插件，无需电脑 |
| [zurg+rex for Android](../zurg/guides/android.md) | 在手机上运行 Plex 服务器：在一台 Android 设备上同时运行 zurg 和 rex，并接入你的 debrid 网盘和 Usenet 库。仅限赞助者 |

## 在 Jellyfin 和 Emby 中使用 {#inside-jellyfin-and-emby}

| 名称 | 功能 |
|---|---|
| [Debrid 插件](https://debridmediamanager.com/jellyfin)（RD zurg、AD zurg、TB zurg、PM zurg、OC zurg、DL zurg） | 每个 debrid 服务商一个插件：Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud 和 Debrid-Link。无需 zurg 应用或挂载，你的 debrid 库就能直接显示在 Jellyfin 或 [Emby](https://debridmediamanager.com/emby) 里。仅限赞助者 |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | 一个 Jellyfin 插件，通过你自己的 Usenet 账户串流 NZB。仅限赞助者 |

## 为你自动添加影片 {#adding-titles-for-you}

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Drücke in DMM auf **Want**, und dein zurg holt es, auch neue Folgen. Für Sponsoren |
| [Seerr through DMM](../dmm/seerr.md) | Anfragen der Familie in Seerr landen auf deiner Wanted-Liste. Für Sponsoren |
| [Torznab](https://debridmediamanager.com/torznab) and [Newznab](https://debridmediamanager.com/newznab) | DMM als Indexer für Sonarr, Radarr und Prowlarr. Für Sponsoren |
| zurg as the download client | zurg antwortet Sonarr und Radarr als qBittorrent für [Torrents](../zurg/guides/sonarr-radarr-torrents.md) und als SABnzbd für [Usenet](../zurg/guides/sonarr-radarr.md), du brauchst also keines von beiden. Für Sponsoren |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Sucht auf Usenet, wenn du in Stremio auf Play drückst, und streamt es über zurg. Für Sponsoren |
| [`__magic__`](../zurg/guides/magic.md) | Ein zurg-Ordner, den du selbst einrichtest oder von Sonarr und Radarr einrichten lässt. Für Sponsoren |

## DMM 的其他功能 {#the-rest-of-dmm}

| 名称 | 功能 |
|---|---|
| Usenet tab | 无需 Usenet 账号，即可将 Usenet 资源发送到你的 Real-Debrid 库。赞助者优先，并且每日额度更多 |
| [Request board](https://debridmediamanager.com/requests) | 请求 Real-Debrid 库中没有的资源。其他 DMM 用户会将其移入你的库。满 10 个请求即可获得 7 天的 DMM 赞助者特权 |
| [Hash lists](https://debridmediamanager.com/hashlists) | 分享资源列表，方便其他人添加到他们自己的账号中 |
| Browser extension | 在电影和剧集网站上以及磁力链接旁添加 DMM 按钮。适用于 [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm)、[Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) 和 [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | 赞助网站。在这里赞助，关联你的 Patreon 或 GitHub Sponsors 赞助，即可获取你的 DMM API 密钥。[赞助能带来什么](sponsorship.md) |

## 指南中会看到的术语 {#words-youll-see-in-the-guides}

| 词语 | 含义 |
|---|---|
| 发布版本 | 某部电影、剧集或季由某人发布的一个副本。一个标题通常有许多不同画质的版本 |
| Debrid 服务商 | 一项付费服务，替你下载种子并让你串流播放：Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link |
| 已缓存 | 服务商已经有这个发布版本，所以能立即播放 |
| Usenet | 获取发布版本的另一个途径。你可以使用自己的 Usenet 账号，让 TorBox Pro 或 Easynews 来处理，或者让 DMM 把结果发送到 Real-Debrid |
| Easynews | 一项付费 Usenet 服务，有自己的搜索功能，可以直接通过网页播放文件 |
| NZB | 一个小文件，记录 Usenet 发布版本的位置，就像种子文件对于 BitTorrent 那样 |
| 索引站 | 用于搜索发布版本的网站。Sonarr 和 Radarr 用它来查找内容 |
| Sonarr、Radarr 和 Prowlarr | 替你获取影视内容的应用：Sonarr 管剧集，Radarr 管电影。Prowlarr 把它们的索引站集中在一处管理 |
| Seerr | 供家人和朋友提交求片请求的网站。Overseerr 和 Jellyseerr 的工作方式相同 |
| Stremio、Nuvio 和 Kodi | 媒体播放器应用。插件（Addon）为它们提供可播放的内容。Nuvio 支持 Stremio 插件 |
| DMM API 密钥 | 来自 gatekeeper 的赞助者密钥。在指南要求的地方粘贴进去，并像密码一样妥善保密 |
| 每夜构建版 | zurg 或 rex 的最新构建版，每晚生成。zurg 的每夜构建版仅供赞助者使用 |
| WebDAV | 一种通过网络共享文件的方式。Infuse、Kodi 和许多电视播放器都能打开它 |
| 挂载 | 让 zurg 的文件夹看起来像一个本地磁盘，这样 Plex、Jellyfin 或 Emby 就能扫描它 |
| rclone | zurg 用来创建挂载的工具。zurg 的安装程序会替你把它装好 |
| `.strm` | 一个小文件，里面存放的是链接而不是视频本身，供 Kodi 等播放器使用 |
| 数据源 | 任何告诉 rex 它有哪些内容并提供文件的东西：zurg、rex-stremio 或某个插件 |
| 认领 | 把 rex 认领到 Plex 账号上，这样它就能显示标题和海报，Plex 应用也能找到它 |
| Plex Media Server 与 Plex 应用 | 服务器保存你的媒体库，电视和手机上的应用负责播放。rex 替代的是服务器，不是应用 |
