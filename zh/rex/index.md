# rex

[rex](https://rex.debridmediamanager.com/zh/) 是一个给官方 Plex 应用用的媒体服务器，本身不存放任何文件。数据源会告诉它你的库里有什么，并提供每个文件。你按下播放时，rex 才把对应的文件流式传输出来。rex 个人使用免费。它的[源代码](https://github.com/debridmediamanager/rex)以 PolyForm Noncommercial 许可证公开。它可以在 Linux、macOS 和 Windows 上运行，也提供 Linux Docker 镜像 `ghcr.io/debridmediamanager/rex:nightly`（[配合你自己的应用](any-source.md#run-rex-in-docker)，[配合 zurg](with-zurg.md#run-rex-in-docker)）。

- [rex 常见问题](faq.md) 介绍安装前需要了解的内容
- [rex 配合你自己的应用](any-source.md) 设置一个通过 HTTP 提供文件并兼容 rex 数据源接口的数据源
- [rex 配合你的 Stremio 插件](stremio.md) 用 rex-stremio 填充 rex。它免费，不需要赞助
- [rex 配合 zurg](with-zurg.md) 通过 zurg 从 debrid 账户或 Usenet 填充 rex
- [rex 的直播电视](live-tv.md) 通过 rex-live-sports 添加直播频道和节目指南
- [rex 的音乐](music.md) 为 Plexamp 和支持的 Plex 应用添加音乐库
- [从 Plex 迁移到 rex](from-plex.md) 让 rex 与 Plex 并行运行，或完全替代 Plex
- [与家人和朋友共享 rex](sharing.md) 邀请你一起观看的人
- [编写 rex 插件](addons.md) 把家庭视频、录像或 Stremio 目录接入 rex
- [插件教程](addon-home-videos.md) 用一个 Python 文件构建完整的家庭视频、音乐或 IPTV 插件
- [插件的更多功能](addon-more.md) 添加字幕、额外内容、章节、合集、播放列表等
- [导入你的观看记录](import-watched.md) 从 Plex 复制观看状态、评分和续播进度
- [rex 配合 Kometa](kometa.md) 在 rex 库上创建合集和海报徽章
- [应用从你的服务商下载](direct-download.md) 让 Plex 应用直接从数据源链接下载，使 rex 所在的机器不必保存电影
