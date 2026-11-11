# 用 rex 看直播电视 {#live-tv-with-rex}

rex 会在 Plex 网页版和 Plex for Android 的 **Live TV** 中显示插件频道，并提供节目指南和 **What's On**。选择一个频道即可立即播放。[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) 已经可以配合直播体育服务器使用。如果想使用 IPTV M3U 和 XMLTV 节目指南，请参阅 [教程：IPTV 插件](addon-iptv.md)。

你能获得以下功能：

- **节目指南。** 每个频道都有对应的编号，并显示当前和接下来的节目。
- **What's On。** 显示当前正在播出的内容、稍后开始的节目，以及即将播出的电影。
- **搜索。** 搜索节目名称，可以在 Live TV 和你的媒体库中找到它。
- **观看。** 选择一个频道即可直接播放直播。频道不会保存续播位置，也不会被标记为已观看。
- **类似电视运营商的频道列表。** rex-live-sports 默认提供美国频道列表，包含约 30 个体育频道，频道编号固定不变（ESPN 为 2，CBS 为 7）。它还提供 ESPN 上这些频道的赛程，以及时段频道（`NFL 1`、`NBA 1` 等）。时段频道会在比赛开始前列出当天的赛程，并能直播每一场比赛。同时还提供英国和德国的频道列表。
- **同样支持媒体库。** 这些频道保留在各自的 **Live Sports** 媒体库中，并按分组归入不同的合集。

## 开始之前 {#before-you-start}

| 你需要 | 原因 |
|---|---|
| 2026.11.02 或更新的 rex nightly 版本 | 直播电视功能是在这个版本中加入的 |
| 按照 [自带应用的 rex](any-source.md) 设置好 rex，并启用 [视频转码](any-source.md#converting-video-optional) | rex 会在你观看时转换每个频道（只是复制一份，开销很小） |
| 一台直播体育服务器，放在 rex 所在的机器上或你的家庭网络中 | rex-live-sports 从它那里获取频道 |
| Docker | 用于在第 2 步中运行 live-sports。其 [README](https://github.com/yowmamasita/live-sports-public) 中列出了其他安装方式 |
| rex 所在的机器上需要安装 Python 3.9 或更新版本、`git`、`ffmpeg` 和 `ffprobe` | rex-live-sports 用 ffprobe 检查每个频道的流，并用 ffmpeg 绘制它的海报 |

## 第 1 步：安装 rex 并将其添加到 Plex 账户 {#step-1-install-rex-and-add-it-to-a-plex-account}

按照 [用你自己的应用使用 rex](any-source.md)：

1. [第 1 步。安装 rex](any-source.md#step-1-install-rex)，包括查找 rex 的局域网 IP。本页写作 `192.168.1.20`，请替换为你自己的 IP。
2. [第 3 步。将其添加到 Plex 账户](any-source.md#step-3-add-it-to-a-plex-account)：在新账户上注册 rex，并与你自己的账户共享。
3. [转换视频](any-source.md#converting-video-optional)。

跳过那里的第 2 步和第 4 步：rex-live-sports 就是你的应用。

## 第 2 步：启动体育直播服务器 {#step-2-start-a-live-sports-server}

**功能说明。** 运行 live-sports，它会查找体育频道，并每隔几分钟检查哪些频道正在播放。

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**你应该看到的。** 在浏览器中打开 `http://192.168.1.20:8765` 可以看到 live-sports 的仪表板。每个频道的首次检查需要几分钟。

## 第 3 步：安装 rex-live-sports {#step-3-install-rex-live-sports}

**功能说明。** 在 rex 所在的机器上把 rex-live-sports 下载到 `~/rex-live-sports` 并启动它。

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

在 `config.json` 中，把 `live_sports_url` 设为 `http://192.168.1.20:8765`，`rex_url` 设为 `http://192.168.1.20:32400`。然后：

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

在 `config.json` 中，把 `live_sports_url` 设为 `http://192.168.1.20:8765`，`rex_url` 设为 `http://192.168.1.20:32400`。然后：

```bash
python3 rex_live_sports.py
```

只要那个终端窗口保持打开，它就会一直运行。
+++

**你应该看到什么。** 类似这样的一行：

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

在 live-sports 完成第一次检查之前，它会记录 `live-sports lists no channel that plays yet`。然后第一次同步会检查 live-sports 拥有的每个阵容频道的流，30 个频道大约需要一分钟，并记录：

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

这就是 live-sports 拥有的 30 个阵容频道，再加上当天有比赛的时段。它每五分钟再同步一次，并且只检查当天还没见过的频道。

## 第 4 步：共享媒体库并打开直播电视 {#step-4-share-the-library-and-open-live-tv}

**Live Sports** 库是新建的，所以还没有分享给任何账户。用新账户登录后，请在 **Manage Library Access** 中把它添加到你自己账户的分享里，也添加到其他人的分享里（[分享 rex](sharing.md)）。除非你为某个账户关闭了该选项，否则分享给它的账户都可以观看 Live TV。

然后以你自己的身份打开 Plex 应用：

- **Plex Web**：侧边栏里有 **Live TV & DVR**，下面列出了 rex 的库。
- **Plex for Android**：底部有 **Live TV** 标签页，顶部选择 rex；**Live TV & DVR** 也会和 rex 的库一起列出来。

**你应该看到的内容。** 顶部有 **Guide** 和 **What's On**。节目指南会按频道号列出每个频道及其正在播出的节目。选择一个节目，然后点击 **Watch Now**。

## 频道、编号和节目指南 {#channels-numbers-and-guides}

`config.json` 里指定了频道阵容：`lineups/us.json` 为原样复制，`lineups/uk.json` 或 `lineups/de.json` 分别对应英国或德国的电视台。阵容中的频道就在它的编号上，而 live-sports 里有一份可以播放的副本。

美国电视台的比赛来自 ESPN 的赛程表（如 `Chicago Bears at Seattle Seahawks`），从开球时间开始，持续该项运动的常规时长。涵盖的项目有：NFL、大学橄榄球、NBA、NHL、MLB、欧洲各大联赛、MLS 和 F1。ESPN 只提供美国广播商的信息，因此英国和德国的电视台改为使用 [epgshare01](https://epgshare01.online/) 为同名频道提供的节目指南。和所有频道一样，比赛前后都会有相应的节目安排。没有任何指南列出的频道，会以其自身名称显示，每段时长六小时。

频道位排在电视台之后：`NFL 1` 到 `NFL 10` 对应 `700.1` 到 `700.10`，`NBA 1` 到 `NBA 6` 从 `701.1` 开始，之后是 NHL、MLB、Soccer 和 F1。当天的每场比赛都会分配到其项目中第一个空闲的频道位，因此在开赛前节目指南上就能看到。从开赛前 15 分钟起，直到比赛结束，该频道位都会播放包含这场比赛的 live-sports 直播源，匹配依据是双方球队的名称。比赛之间，频道位不播放任何内容。频道位在第一次播放某场比赛时才会出现。

如果没有阵容（`config.json` 中为 `"lineup": ""`），则改为列出 live-sports 中 `Live:` 和 `Sports` 分组的所有频道，按分组编号：第一组为 `100.1`、`100.2`，下一组为 `101.1`，避开调谐器或其他来源常用的低位编号。只要 live-sports 每周至少列出一次某个频道，该频道就会保留其编号。Pluto TV 频道使用 Pluto TV 自己的节目表，除非你另外指定，否则不会包含在内：`"groups": ["Live:", "Sports", "Pluto:"]`。所有设置项都在 rex-live-sports 的 [README](https://github.com/debridmediamanager/rex-live-sports#settings) 中。

## 更新 {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

在 macOS 上，按 Ctrl+C 停止它，在 `~/rex-live-sports` 中运行 `git pull`，然后再重新启动。

## 它做不到的事 {#what-it-cannot-do}

- **无法录制。** Plex Web 和 Plex for Android 上没有 Record 按钮。
- **节目单按名称匹配。** 频道可能会拿到同一品牌其他频道的节目单，而且很多赛事频道根本没有节目单。
- **槽位通过比赛名称中的队伍来查找比赛流。** 名称不同的流（比如 `nfl ravens`）找不到，而没有任何流的比赛虽然会出现在节目单里，却无法播放。
- **Plex 会把没有集数编号的节目当作电影。** 这和任何电视节目单的处理方式一样，所以比赛也会出现在 What's On 的电影里。
- **直播电视只在 Plex Web 和 Plex for Android 中测试过。** 其他 Plex 应用还没有测试。
- **任何能访问 rex-live-sports 地址的人都可以通过它播放。** 请保持 `listen` 为 `127.0.0.1`。

如果想用你已有的节目单添加自己的频道，请参阅 [Building rex addons](addons.md#live-tv)。
