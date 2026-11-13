# rex

[rex](https://rex.debridmediamanager.com/zh/) 是一个面向官方 Plex 应用的媒体服务器，它本身不存储任何文件。数据源告诉它你的媒体库里有什么，并提供每个文件的访问。你按下播放时，rex 再把对应文件串流过去。rex 供个人免费使用。它的[源代码](https://github.com/debridmediamanager/rex)以 PolyForm Noncommercial 许可证公开。它可在 Linux、macOS 和 Windows 上运行，也提供 Linux Docker 镜像 `ghcr.io/debridmediamanager/rex:nightly`（[搭配你自己的应用](any-source.md#run-rex-in-docker)，[搭配 zurg](with-zurg.md#run-rex-in-docker)）。

- [rex for Android](android.md) 可以在手机、平板或电视盒子上运行 rex 及其插件，不需要电脑。它是免费的
- [rex 常见问题](faq.md) 解答安装前需要了解的内容
- [rex 搭配你自己的应用](any-source.md) 设置一个通过 HTTP 提供文件并支持 rex 数据源 feed API 的数据源
- [rex 搭配你的 Stremio 插件](stremio.md) 通过 rex-stremio 为 rex 填充内容。它免费，也不需要赞助
- [rex 搭配 zurg](with-zurg.md) 通过 zurg 从你的debrid账户或 Usenet 为 rex 填充内容
- [rex 直播电视](live-tv.md) 通过 rex-live-sports 添加直播频道和节目指南
- [rex 音乐](music.md) 为 Plexamp 和受支持的 Plex 应用添加音乐库
- [从 Plex 迁移到 rex](from-plex.md) 让 rex 与 Plex 并行运行，或直接替代 Plex
- [与家人和朋友分享 rex](sharing.md) 邀请你一起观看的人
- [编写 rex 插件](addons.md) 把家庭视频、录像或 Stremio 目录导入 rex
- [插件教程](addon-home-videos.md) 用一个 Python 文件构建完整的家庭视频、音乐或 IPTV 插件
- [插件的更多功能](addon-more.md) 添加字幕、额外内容、章节、合集、播放列表等
- [导入你的观看历史](import-watched.md) 从 Plex 复制观看状态、评分和续播进度
- [rex 搭配 Kometa](kometa.md) 在 rex 媒体库上创建合集和海报徽章
- [应用从你的提供商下载](direct-download.md) 让 Plex 应用直接从数据源链接下载，rex 所在机器不需要存放电影
