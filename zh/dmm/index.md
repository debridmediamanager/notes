# DMM

[Debrid Media Manager](https://debridmediamanager.com) 帮你找到电影和剧集，并把它们保存在你的 debrid 库中。

DMM 浏览器扩展会在 IMDb、Trakt 以及其他电影和剧集网站上添加一个按钮。[Safari 中的 DMM 按钮](safari.md) 介绍了 Safari 的设置方法。

DMM 也为其他项目提供服务：

- **zurg** 会向 DMM 询问每个文件对应的是哪部电影或哪一集。赞助者可以从 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 获取 DMM API 密钥。没有它，zurg 只能依赖文件名，匹配到的标题会更少。[rex with zurg](../rex/with-zurg.md#why-dmm-places-the-files) 解释了两者的区别。
- **Sonarr、Radarr 和 Prowlarr** 可以把 DMM 当作 Torznab 种子索引器或 Newznab Usenet 索引器来搜索。两者都需要有效的赞助和 DMM API 密钥。请在 [Torznab](https://debridmediamanager.com/torznab) 和 [Newznab](https://debridmediamanager.com/newznab) 页面中完成设置。
- **你的想看列表**：按下 **Want**，或者关注一个 Trakt 或 MDBList 列表。zurg 会获取列表中的内容，并在新剧集播出时把它们也获取下来。需要赞助。详见 [DMM 想看列表](../zurg/guides/dmm-wanted.md)。
- **Seerr、Overseerr 和 Jellyseerr** 可以把 DMM 当作 Radarr 和 Sonarr 来使用。之后，请求会进入你的想看列表，由 zurg 去获取。需要赞助。详见 [通过 DMM 使用 Seerr](seerr.md)。
- **rex-direct** 会为已认领的 rex 提供自己的地址和证书。详见 [rex-direct](../rex/any-source.md#rex-direct)。

赞助能解锁哪些功能，以及每项功能在哪里设置，都写在 [赞助能给你带来什么](../guides/sponsorship.md) 中。

遇到问题？到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **dmm-support** 论坛提问即可。[获取帮助](../guides/remote-help.md) 说明了应该提供哪些信息。
