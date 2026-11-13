# 各部分的作用 {#what-each-piece-does}

这些名字本身看不出各自是做什么的，所以这里每个都给一句说明。要找出你需要哪些，请看 [Choose your setup](choose-your-setup.md)。

## 三个项目 {#the-three-projects}

| 名称 | 功能说明 |
|---|---|
| [DMM](https://debridmediamanager.com)（Debrid Media Manager） | 一个用来查找资源并将其添加到你的 debrid 账户的网站。它还会搜索 Usenet 和 Easynews。免费 |
| [zurg](../zurg/index.md) | 将所有 debrid 账户和 Usenet 合并到同一个文件夹中。Plex、Jellyfin、Emby、Infuse 和 rex 会像读取普通硬盘一样读取这个文件夹。面向赞助者 |
| [rex](../rex/index.md) | 一个不拥有任何文件的媒体服务器。它的来源会告诉它自己有哪些内容，所有 Plex 应用都能播放它。个人使用免费 |

## 直接从 DMM 观看 {#watching-straight-from-dmm}

无需服务器也能使用以下任何一项。

| 名称 | 功能 |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | 一个 Stremio 插件，可以播放你的 debrid 或 Easynews 账户中的资源 |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | 在 Kodi 中浏览、搜索并播放你的 debrid 或 Easynews 账户中的内容 |
| DMM Watch | DMM 上的一个按钮，可以用你自己的播放器（如 VLC 或 Infuse）打开文件 |
| [DMM Music](https://debridmediamanager.com/music/) | 在浏览器中播放并下载 Real-Debrid 上的音乐 |

## 为 rex 提供内容 {#feeding-rex}

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | 把你的 Stremio 插件变成 rex 媒体库，这样就能在 Plex 应用里播放。免费 |
| [rex addons](../rex/addons.md) | 给 rex 提供播放内容的小程序：YouTube、Spotify、IPTV、家庭视频，或者你自己写的任何东西 |
| [rex for Android](../rex/android.md) | 在 Android 手机或电视盒子上运行 rex 及其插件，不需要电脑。免费。若要播放你的 debrid 和 Usenet 媒体库，赞助者请使用 zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | 在手机上运行的 Plex 服务器：zurg 和 rex 一起跑在同一台 Android 设备上。面向赞助者 |

## 在 Jellyfin 和 Emby 中使用 {#inside-jellyfin-and-emby}

| 名称 | 功能 |
|---|---|
| [RD、AD、TB、PM、OC 和 DL zurg](https://debridmediamanager.com/jellyfin) | 每个网盘服务商对应一个插件。无需 zurg 应用或挂载，你的网盘库即可直接显示在 Jellyfin 或 [Emby](https://debridmediamanager.com/emby) 中。面向赞助者 |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | 一个 Jellyfin 插件，通过你自己的 Usenet 账户串流 NZB。面向赞助者 |

## 为你自动添加影片 {#adding-titles-for-you}

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Drücke bei DMM auf **Want**, und dein zurg holt es sich, einschließlich neuer Episoden. Für Sponsoren |
| [Seerr through DMM](../dmm/seerr.md) | Anfragen von der Familie in Seerr landen auf deiner Wanted-Liste. Für Sponsoren |
| [Torznab and Newznab](https://debridmediamanager.com/torznab) | DMM als Indexer für Sonarr, Radarr und Prowlarr, mit zurg als Download-Client. Für Sponsoren |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Sucht auf Usenet, wenn du in Stremio auf Abspielen drückst, und streamt es über zurg |
| [`__magic__`](../zurg/guides/magic.md) | Ein zurg-Ordner, den du selbst einrichtest, oder den Sonarr und Radarr für dich einrichten lassen |

## DMM 的其他功能 {#the-rest-of-dmm}

| Name | What it does |
|---|---|
| [Request board](https://debridmediamanager.com/requests) | Ask for a release Real-Debrid doesn't have. Another DMM user moves it into your library. Filling requests earns the DMM sponsor perks |
| [Hash lists](https://debridmediamanager.com/hashlists) | Share a list of releases so others can add them to their own accounts |
| [Browser extension](../dmm/safari.md) | Adds DMM buttons to movie and TV sites and next to magnet links |
| [Sponsor page](https://gatekeeper.debridmediamanager.com) | Where you sponsor and link your Patreon or GitHub Sponsors pledge. [What a sponsorship gives you](sponsorship.md) |

## 指南中会看到的术语 {#words-youll-see-in-the-guides}

| 术语 | 含义 |
|---|---|
| Debrid provider | 一种付费服务，会替你下载种子并让你在线播放：Real-Debrid、AllDebrid、TorBox、Premiumize、Offcloud、Debrid-Link |
| Cached | 服务商已经有这个资源，所以可以立即播放 |
| Usenet | 另一种获取资源的渠道。你需要一个 Usenet 服务商账号，或者用 TorBox Pro 来替你完成这一步 |
| NZB | 一个小文件，记录了 Usenet 资源的位置，作用类似种子文件之于种子 |
| Indexer | 用来搜索资源的网站。Sonarr 和 Radarr 靠它来找内容 |
| WebDAV | 一种通过网络共享文件的方式。Infuse、Kodi 和很多电视播放器都能打开它 |
| Mount | 让 zurg 的文件夹看起来像一个本地磁盘，这样 Plex、Jellyfin 或 Emby 就能扫描它 |
| Plex Media Server vs Plex apps | 服务器保存你的媒体库，电视和手机上的应用负责播放。rex 替代的是服务器，而不是这些应用 |
