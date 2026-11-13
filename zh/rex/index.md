# rex

[rex](https://rex.debridmediamanager.com/zh/) 是一个给官方 Plex 应用用的媒体服务器，本身不存任何文件。数据源告诉它你的库里有什么，并提供每个文件。你按下播放时，rex 再把该文件串流出来。rex 个人使用免费。它的[源代码](https://github.com/debridmediamanager/rex)以 PolyForm Noncommercial 许可证公开。它运行于 Linux、macOS 和 Windows，也提供 Linux Docker 镜像 `ghcr.io/debridmediamanager/rex:nightly`（[配合你自己的应用](any-source.md#run-rex-in-docker)，[配合 zurg](with-zurg.md#run-rex-in-docker)）。

- [rex for Android](https://github.com/debridmediamanager/rex-android) 可以在手机、平板或电视盒子上运行 rex 及其插件，不需要电脑。它是免费的
- [rex questions](faq.md) 回答安装前需要了解的事项
- [rex with your own app](any-source.md) 设置一个通过 HTTP 提供文件、并支持 rex 反馈 API 的数据源
- [rex with your Stremio addons](stremio.md) 通过 rex-stremio 为 rex 填充内容。它免费，也不需要赞助
- [rex with zurg](with-zurg.md) 通过 zurg 从 debrid 账户或 Usenet 为 rex 填充内容
- [Live TV with rex](live-tv.md) 通过 rex-live-sports 添加直播频道和节目指南
- [Music with rex](music.md) 为 Plexamp 和支持的 Plex 应用添加音乐库
- [Move from Plex to rex](from-plex.md) 让 rex 与 Plex 并行运行，或者替代 Plex
- [Share rex with family and friends](sharing.md) 邀请你一起看片的人
- [Building rex addons](addons.md) 把家庭视频、录像或 Stremio 目录带进 rex
- [Addon tutorials](addon-home-videos.md) 用一个 Python 文件构建完整的家庭视频、音乐或 IPTV 插件
- [More from your addon](addon-more.md) 添加字幕、附加内容、章节、合集、播放列表等更多功能
- [Bring your watch history](import-watched.md) 从 Plex 复制观看状态、评分和续播进度
- [Kometa with rex](kometa.md) 在 rex 库中创建合集和海报徽章
- [Apps download from your provider](direct-download.md) 让 Plex 应用直接从数据源链接下载，这样 rex 所在的机器就不用存放电影
