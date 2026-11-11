# 赞助能给你带来什么 {#what-a-sponsorship-gives-you}

免费的 DMM 也能用。赞助可以支付它的托管费用，让 zurg 和 rex 持续更新。本页列出了所有权益，以及在哪里设置。

在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助。登录后就能看到你的 DMM API key。点击 **Open DMM with this key**，就能在当前浏览器中关联它。其他要求填写该 key 的服务，也填同一个 key。请妥善保管，因为它相当于密码。

权益随赞助而定。赞助结束后，DMM 会在下一次请求时停止提供这些权益。Gatekeeper 会在下一次检查时撤销 zurg 的访问权限和 Discord 身份组。点击 **Reset key** 可以让旧 key 立即在所有地方失效。

## zurg

| 你能获得什么 | 位置 |
|---|---|
| 每日构建版，包含所有服务商和 Usenet，以及 Docker 镜像 | 接受 GitHub 邀请后，查看 [zurg 设置](../zurg/setup/index.md) |
| zurg+rex Android 应用，可以在你的手机上运行 Plex 服务器 | 接受 GitHub 邀请后，查看 [Android 指南](../zurg/guides/android.md) |
| 完整的 zurg 源代码 | GitHub 上的私有仓库 |
| 每个以 rex 和 Plex 命名的发布版本 | [zurg 配置](../zurg/reference/config.md) 中的 `dmm_api_key` |
| 无需先读取文件即可获取 DMM 媒体详情，并在添加发布版本前进行语言检查 | 除 `dmm_api_key` 外无其他要求 |
| 启用后，自动为你整理 `__magic__` 文件夹 | [\_\_magic\_\_](../zurg/guides/magic.md) |
| 由 zurg 获取你的 DMM 想看列表 | [DMM 想看列表](../zurg/guides/dmm-wanted.md) |
| 当你没有自己的索引器时，搜索 DMM 的 Usenet 和 torrent 索引器 | `dmm_api_key`，加上 Usenet 服务商或可以添加 torrent 的 debrid 账户 |
| 按每部作品的原始语言选择发布版本 | [音频和字幕语言](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) 中的 `original` |
| 没有任何索引器收录的想看电影，改为从其官方 YouTube 上传版本串流播放 | [从 YouTube 串流电影](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

`dmm_api_key` 相关功能需要 zurg 每日构建版。免费公开版不包含这些功能。

## DMM

| 你能得到什么 | 位置 |
|---|---|
| zurg 会抓取的想看列表，包含新集数和升级版本。可以从 DMM、Kodi、Trakt 和 MDBList 列表，或 Radarr、Sonarr 的备份来填充 | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| Seerr、Overseerr 或 Jellyseerr 的请求会进入你的想看列表 | [Seerr through DMM](../dmm/seerr.md) |
| 在电影或剧集页面的 Easynews 结果中，一键把任意结果发送到你的 zurg | DMM 上电影或剧集页面的 Easynews 结果 |
| 把 DMM 用作 Usenet 的 Newznab 索引器 | DMM 的 [Newznab 页面](https://debridmediamanager.com/newznab) |
| 把 DMM 用作 Torznab 索引器，为 Real-Debrid、AllDebrid、Debrid-Link、TorBox、Premiumize 和 Offcloud 提供仅缓存的订阅源。TorBox、Premiumize 和 Offcloud 还需要绑定对应服务的密钥 | DMM 的 [Torznab 页面](https://debridmediamanager.com/torznab)。TorBox、Premiumize 和 Offcloud 还需要绑定对应服务的密钥 |
| 为 Debrid 和 Usenet 库提供七个 Jellyfin 插件，为 Debrid 库提供六个 Emby 插件，无需挂载任何内容 | DMM 的 [Jellyfin](https://debridmediamanager.com/jellyfin) 和 [Emby](https://debridmediamanager.com/emby) 页面 |
| 在 Stremio、Cast 和 Kodi 中，每个标题提供十个其他流，而不是五个 | Real-Debrid、TorBox 和 AllDebrid 在 DMM 的 Settings 中设置；其他服务在各自的 Cast 页面中设置 |
| NZB 上传优先处理，每天的 Usenet 额度为 2 TB，而不是 300 GB | DMM 的 Usenet 标签页 |
| Sonarr 和 Radarr 使用相同的优先级和额度 | 在 DMM 的 [SABnzbd 页面](https://debridmediamanager.com/sabnzbd) 中，把你的 DMM API key 填到 Password 字段 |
| 可以同时向 Real-Debrid 上传三个种子文件，而不是一个 | DMM 搜索结果和库中的上传按钮 |
| 把内容添加到 DMM Wanted，并在 Kodi 中生成一个 Wanted 文件夹 | 在 DMM 的 [Kodi 页面](https://debridmediamanager.com/kodi)中配对 Kodi |
| 使用赞助者密钥登录后，可以在其他设备上恢复你的设置 | DMM Settings |
| DMM API 提供发布名称查询、缓存检查、媒体详情和元数据 | [API docs](https://debridmediamanager.com/api-docs) |

## rex

rex 免费使用，不需要赞助。它的 Android 版本只包含在仅限赞助者使用的 zurg+rex 应用中。拥有密钥后，[rex-stremio](../rex/stremio.md) 会在几秒内添加 DMM 已经掌握探测结果的种子的 debrid 流，而不必逐个探测。将密钥粘贴到 rex-stremio 的 **DMM** 字段中。除非你关闭此功能，否则它会与 DMM 共享种子文件的探测结果。

## 帮助 {#help}

| 你能得到什么 | 位置 |
|---|---|
| 在你看视频的同时，在你自己的终端里免费获得 zurg 和 rex 的远程帮助 | [获取帮助](remote-help.md) |
| Discord 上的 Sponsor 角色 | 在 gatekeeper 上连接 Discord |

## 免费也能获得 {#earn-it-without-paying}

在 DMM 的[请求板](https://debridmediamanager.com/requests)上完成请求。每完成 10 个请求可获得 7 天的 DMM 权益。同一个人每天只有一次完成会计入。从请求板上的免费 gatekeeper 账户中获取密钥,即可领取这些时长。

获得的时长只会开通上文提到的 DMM 表格,不会开通 zurg 每夜版、源代码、Discord 身份组、远程帮助或 Android 应用。这些需要付费赞助。`dmm_api_key` 相关功能还需要每夜版。

遇到问题?请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **dmm-support** 论坛提问。
