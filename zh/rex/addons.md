# 构建 rex 插件 {#building-rex-addons}

[rex](https://rex.debridmediamanager.com/zh/) 会根据来源告诉它的信息来展示内容。来源通过 feed API 告诉 rex 它有哪些内容，并在 rex 请求时提供文件。rex 对所有来源一视同仁。**addon** 是你为家庭视频、录像、Stremio 目录、[音乐](#music)或[直播频道](#live-tv)自己写的来源。

本页介绍 rex 对 addon 的要求、如何为条目命名，以及几条关键规则。最后以 [rex-stremio](https://github.com/debridmediamanager/rex-stremio) 作为单文件示例结束。

addon 做三件事：

- **提供文件内容。** 有人点击播放时，rex 会通过 HTTP 从你的 addon 获取每个字节：可能是一个文件，也可能是 rex 被重定向到的一个流。
- **告诉 rex 它有哪些内容。** 它通过 rex 的 feed API 发送一份列表，之后的每次变动也都会发送。rex 从不扫描任何东西。
- **为它提供的内容命名。** 对于没有任何 agent 认识的内容，你的 addon 会自己提供标题、简介、日期和封面图。Plex 应用会像显示其他媒体库一样显示这些内容。

如果你要提供的是 Plex 已经认识的电影和剧集（它有这些内容的 IMDb 或 TMDB id），那么你更适合使用 [rex 搭配你自己的应用](any-source.md)。这样 Plex 会为你完成所有命名和描述。

如果你想把 Stremio addon 的目录接入 rex，那么无需编写任何代码，rex-stremio 已经现成可用。你只需在它的设置页面粘贴 addon 的链接，然后勾选你想要的目录即可。

如果你不想编写和运行服务器，可以改用 [rex-addons](https://github.com/debridmediamanager/rex-addons) 的 JavaScript addon：由一个 `manifest.json` 和一个 `main.js` 组成，通过 git 仓库分享，并且也能在 [zurg+rex Android 应用](../zurg/guides/android.md)中运行。它运行在沙箱中，只能访问其清单中列出的网站，无法读取你的文件，因此适合互联网上的内容，而不适合你磁盘上的文件夹。[编写 addon](https://github.com/debridmediamanager/rex-addons/blob/main/docs/writing-addons.md) 一文介绍了具体做法。本页中的 addon 可以使用任何语言编写，可以提供你自己的文件，也能做你需要的任何事情。

**想直接从可运行的代码开始？** 以下三个教程各自用一个 Python 文件构建一个完整的 addon，只使用标准库，并说明每个部分的作用：

| 教程 | 接入 rex 的内容 |
|---|---|
| [家庭视频](addon-home-videos.md) | 你自己的一个视频文件夹，作为媒体库提供标题、日期，以及从视频中截取的海报 |
| [音乐](addon-music.md) | 一个专辑文件夹，由 Plex 通过 MusicBrainz 命名，并附带歌词 |
| [IPTV](addon-iptv.md) | 一个 M3U 播放列表及其 XMLTV 节目指南，作为带节目指南的 Live TV 频道 |

本页会解释这些教程中的每一步。[你的 addon 的更多功能](addon-more.md)补充了字幕、预告片、章节、合集、播放列表等其他内容。

## 开始之前 {#before-you-start}

| 你需要 | 原因 |
|---|---|
| 按 [使用你自己的应用配置 rex](any-source.md) 设置 rex（第 1 到 3 步） | 你的插件库会显示在这里 |
| 日期为 2026.10.25 或更新的 rex 每日构建版；如果要用 [音乐](#music) 和 [直播电视](#live-tv)，需要 2026.11.02 或更新版本 | 本页就是按这个版本编写的 |
| 如果你的插件提供流，rex 所在的机器上需要安装 FFmpeg | rex 通过转换来播放流（只是复制，开销很小）。rex 会自己找到 FFmpeg，详见 [转换视频](any-source.md#converting-video-optional) |
| 你的插件与 rex 在同一台机器上，或在你的家庭网络中 | rex 的 feed 只会响应这些来源，详见 [保持端口私密](any-source.md#keep-the-port-private) |

本页将 rex 的地址写作 `192.168.1.20:32400`，插件的地址写作 `127.0.0.1:9981`。请替换成你自己的地址。rex 的完整 API 参考见 [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md)。

## 第 1 步：提供文件流 {#step-1-serve-the-bytes}

**作用。** 为每个视频提供一个 rex 可以读取的 URL。

**为什么重要。** rex 不保存任何媒体文件。每次有人点击播放时,rex 都会从你的插件里读取视频。

你的插件是一个 HTTP 服务器。视频位于 `<your address>/<path>`,其中 `path` 由你自己决定。视频分为两种:

| 你提供的内容 | 方式 | rex 的处理 |
|---|---|---|
| **文件**(`.mkv`、`.mp4` 等) | 对 `GET` 返回文件本身。支持 `Range` 请求(`206`),这样拖动进度条才快;没有它,rex 每次跳转都要从头读取 | Plex 应用能直接播放时就直接播放,否则 rex 会进行转换 |
| **流**(HLS,`.m3u8`) | 对 `GET` 返回播放列表,或者重定向到播放列表。会跟随重定向,并且你的登录信息永远不会发送到其他主机 | rex 始终会转换它:把画面和声音转码成应用可以播放的格式。如果应用直接读取文件,也会被引导到这个转换流程 |

可选但值得设置的内容:

- **登录。** Basic auth(`user`、`password`)或 bearer token。rex 只会把它发送到你插件自己的地址。
- **删除。** 当有人在 Plex 应用中删除某个条目时,rex 会先向你的插件发送该路径的 WebDAV `DELETE` 请求。如果返回 `2xx`(已删除)或 `404`(已经不存在),rex 就会移除该条目。返回其他任何结果,Plex 应用都会提示无法删除。

## 第 2 步：在 rex 中注册 {#step-2-register-with-rex}

**它的作用。** 告诉 rex 你的插件叫什么名字、字节数据放在哪里，以及它会往哪些媒体库里填内容。

**为什么重要。** rex 不会读取它不认识的源。重复注册不会产生任何变化，所以每次插件启动时都要注册一次。

+++ Linux 和 macOS
```bash
curl -X PUT http://192.168.1.20:32400/rex/sources/myaddon \
  -H 'Content-Type: application/json' \
  -d '{"url": "http://127.0.0.1:9981",
       "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++ Windows
```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/myaddon -ContentType application/json `
  -Body '{"url": "http://127.0.0.1:9981", "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++

| 字段 | 含义 |
|---|---|
| `url` | 字节数据所在的位置。视频的字节数据是 `GET <url>/<path>` |
| `user` 和 `password`，或 `bearer` | 插件的登录信息（如果有）。绝不要放在 `url` 里 |
| `directories` | 你的插件会往里填内容的媒体库。每一项由路径的第一段（`name`）和媒体库的标题组成：`shows` 对应电视剧库，`movies` 对应电影库，`music` 对应音乐库，也可以写多个。rex 第一次会自动创建每个媒体库；你在 Plex 里改了名字，会保留下来 |
| `trash` | 设为 `false` 时，你的插件删除的内容（快照中被剔除的条目，或 `DELETE` 请求）会直接删除，而不是保存到 rex 的回收站里 |

路径的第一段决定它属于哪个媒体库。以上面的例子为例，所有以 `kids/` 开头的路径都会进入 **Kids**。每个媒体库请使用不同的第一段。

**你应该看到的效果。** rex 会返回这个源。rex 的日志会显示 `SOURCES myaddon registered at http://127.0.0.1:9981`，第一次注册时还会显示 `SECTION create Kids (show) for myaddon's kids`。媒体库会在一秒内出现在 Plex 应用的 More 下面。

## 第 3 步：描述每个视频 {#step-3-describe-each-video}

**作用。** 生成 rex 为每个视频保存的记录：视频在哪里、是什么、长什么样。

**为什么重要。** 这条记录就是 rex 的全部依据。缺少 probe 或 id 随意变动，是大多数插件问题的根源。

```json
{
  "id": "home-2026-07-22-beach",
  "path": "kids/summer-2026/beach.mp4",
  "kind": "episode", "season": 1, "episode": 3,
  "name": "Summer 2026",
  "media_info": { "...": "ffprobe's output, whole" },
  "display": {
    "title": "First day at the beach",
    "summary": "...",
    "date": "2026-07-22",
    "thumb": "http://127.0.0.1:9981/kids/summer-2026/beach.jpg",
    "show": {"title": "Summer 2026", "summary": "...", "poster": "https://...", "art": "https://..."},
    "season": {"poster": "https://..."}
  }
}
```

| 字段 | 是否必填 | 含义 |
|---|---|---|
| `id` | 是 | 你给这个视频起的键，**要一直保持不变**。rex 的观看历史就靠它记录 |
| `path` | 是 | 视频文件在你的 `url` 下的位置。它的第一段决定使用哪个媒体库 |
| `media_info` | 实际上必填 | 视频的 ffprobe `-show_format -show_streams` JSON（如果是流，就对它的 URL 做 probe）。没有它，文件会被**挂起**：存得下，但不会显示，因为 Plex 应用不会播放它不认识的视频。`.m3u8` 流如果没有它会被拒绝，报 `not a video file`，所以只有 probe 过之后再提交流 |
| `kind` | 剧集时需要 | `episode` 或 `movie`。没有它，就没人知道该把视频放在哪：在剧集库里，它会被当作以 `name` 命名的剧集，按文件顺序编号；在电影库里，它会按文件名当作一部电影 |
| `season`、`episode` | 剧集时需要 | 决定它放在哪。给剧集编号时要保证新增的剧集不会挤掉其他剧集的编号 |
| `name` | 否 | 剧集的名字，也是把同一部剧的分集归到一起的依据。默认是它所在文件夹的名字（如果 path 没有文件夹，则用文件名） |
| `release` | 否 | 把应该归在一起的视频分组。默认是视频所在的文件夹 |
| `display` | 对于没有任何 agent 认识的内容需要 | 标题、简介、日期和封面：见第 4 步 |

流的 `path` 以 `.m3u8` 结尾，并且它的 `media_info` 里要有 `"format_name": "hls"`。rex 只有两者同时满足时才会接受。其他文件必须使用视频扩展名。

## 第 4 步：命名并美化 {#step-4-name-and-dress-it}

**做什么。** 为 Plex 中没有任何 Plex 元数据代理认识的内容，提供标题、简介、日期和图片。

**为什么重要。** 没有 `display` 的话，剧集只会显示"Episode 3"加一个空白封面，剧集本身也没有海报。

| 字段 | 显示位置 |
|---|---|
| `title`、`summary` | 视频的标题和简介，按发送的原样显示 |
| `date` | 发布日期（`YYYY-MM-DD`），并从中取出年份。如果只知道年份（比如一部老电影），可以只填年份（`YYYY`）：Plex 应用会显示年份，不显示具体发布日 |
| `thumb` | 电影的海报，或剧集的剧照 |
| `art` | 电影的背景图 |
| `show.title`、`show.summary`、`show.poster`、`show.art` | 剧集所属的剧集（节目） |
| `season.summary`、`season.poster` | 剧集所属的季（如果没有季海报，则用剧集的海报） |

所有字段都是可选的。图片必须是 `http://` 或 `https://` 网址。rex 会自己去获取这些图片：可以来自公共互联网，也可以来自你的插件自己的地址（你注册时填的 `url`），并带上你插件的登录信息。其他位于你家庭网络中的地址会被拒绝。因此，插件可以提供自己的图片，比如从每个家庭视频中截取的一帧。2:3 的图片最适合做海报，16:9 的图片最适合做剧照和背景。

rex 对这些内容的处理方式如下：

- **只用于没有其他来源命名的内容。** 如果视频带有 Plex 能识别的 `kind` 和 `ids`，就按 Plex 的描述显示，`display` 会被忽略。
- **之后的发送会更新内容。** 用新的 `display` 再次发送视频，它的那一行、剧集和季都会原地更新；应用会重新绘制新的图片。剧集会保留创建时使用的标题。
- **用户的设置优先。** 有人在 Plex 应用里编辑并锁定的字段会保留他们的值，他们上传的海报也会保留。
- **会做检查。** 如果图片不是 http(s) 网址，或者日期格式不对，视频会被拒绝，并且会指出是哪个字段出了问题。

## 第 5 步：发送 {#step-5-send-it}

**它的作用。** 把你的视频发送给 rex：一次性发送全部，之后有变化时再发送变化的部分。

**为什么重要。** rex 会准确显示你上次发送的内容。

| 操作 | 发送内容 | rex 的回复 |
|---|---|---|
| 添加或修改视频 | `POST /rex/feed/myaddon/items` 配合 `{"items": [...]}` | 有多少被 `created`、`updated`、`held`、`unchanged`，以及每个 `rejected` 的视频和原因 |
| 删除视频 | `DELETE /rex/feed/myaddon/items` 配合 `{"ids": [...]}` | 有多少被 `trashed`、`deleted`、`released`（被 held 的视频会被忘掉）和 `unknown` |
| 发送全部 | `PUT /rex/feed/myaddon/snapshot` 配合 `{"items": [...]}`。分批发送时：`"session"`（任意文本）、从 0 开始的 `"part"`，最后一批加上 `"complete": true` | 同样的统计数字，以及 `removed` 的内容：快照中没有列出的你的每个视频 |

每次请求发送几百个视频。一个不包含任何视频的快照不会删除任何东西。如果快照会删除超过一半的视频，那么除非最后一部分带有 `"force": true`，否则会被拒绝。这样一个丢失了记录的插件就不会意外清空你的库。

**你应该看到的内容。**

+++ Linux 和 macOS
```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/items | head -c 400   # what rex shows, with each ratingKey
curl -s http://192.168.1.20:32400/rex/feed/myaddon/held                  # what waits for a probe
```
+++ Windows
```powershell
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/items   # what rex shows, with each ratingKey
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/held    # what waits for a probe
```
+++

rex 的日志会列出每个被拒绝的视频及原因：`FEED myaddon rejected <id>: <reason>`。

## 音乐 {#music}

**它的作用。** 把专辑放进音乐库，Plexamp、Plex 网页版和 Plex for Android 都能播放。

**为什么重要。** Plex 通过专辑在 MusicBrainz 上的 release 来给音乐命名。发送这个 id，Plex 就会自己补全所有标题、封面、艺人照片和简介。

把每个音频文件作为一个 track 发送：

```json
{
  "id": "albums/in-rainbows/01",
  "path": "music/Radiohead/In Rainbows/01 - 15 Step.flac",
  "kind": "track",
  "ids": {"mbid": "3b408cb5-7d51-4188-b07c-fabcf308cda3"},
  "disc": 1, "track": 1,
  "media_info": { "...": "ffprobe's output, whole" }
}
```

| 字段 | 含义 |
|---|---|
| `kind` | `track` |
| `path` | 音频文件：`.flac`、`.mp3`、`.m4a`、`.aac`、`.ogg`、`.oga`、`.opus`、`.wav`、`.alac`、`.aif`、`.aiff`、`.wma`、`.ape`、`.wv`、`.dsf` 或 `.mka` |
| `ids.mbid` | 这首歌所在专辑的 MusicBrainz **release** id：即 `musicbrainz.org/release/<id>` 链接里的 id，而不是 release group 或 recording 的 id。也可以用 `ids.plex`，即 Plex 自己的专辑 guid（`plex://album/<id>`） |
| `disc`、`track` | 这首歌在该 release 中的位置。Plex 显示的是对应这些编号的那首曲目 |
| `release` | 这首歌属于专辑的哪一个版本。默认是它所在的文件夹。Plex 会把两个版本列为两张独立的专辑，所以如果一个版本的文件放在碟片文件夹（`CD1/`、`CD2/`）里，请为这个版本的所有文件发送同一个 `release` |
| `display` | 用于 Plex 不认识的音乐：歌曲的 `title`，艺人的 `artist`（`title`、`summary`、`poster`、`art`），以及专辑的 `album`（`title`、`summary`、`poster`、`date`） |
| `lyrics` | 附加在你的 addon 上、与它同目录的歌词文件：`[{"path": "music/.../01 - 15 Step.lrc", "size": 147}]`。`.lrc`（带时间轴的歌词）或 `.txt`，会作为歌曲的歌词显示 |
| `loudness` | 仅当你的 addon 测量响度时使用，字段名沿用 Plex 的命名：`gain`、`albumGain`、`peak`、`albumPeak`、`albumRange`、`loudness` 和 `lra`，`startRamp` 和 `endRamp` 淡入淡出，以及 `levels`（每 100 ms 的响度）。rex 自己不做任何测量 |

- **先要有音乐库。** 在第 2 步中声明一个（`"directories": [{"name": "music", "music": "Music"}]`），或在 Plex 应用里添加一个音乐库。没有任何音乐库接收的曲目会被拒绝：`no music library holds <file>`。
- **查找 release id。** 用专辑名和艺人名在 MusicBrainz 上搜索（`https://musicbrainz.org/ws/2/release?query=release:%22In%20Rainbows%22%20AND%20artist:Radiohead&fmt=json`），选一个曲目数与你的相符的官方 release。通常会匹配到好几个（每个国家一个），其中任何一个都能确定这张专辑。MusicBrainz 每个地址每秒只接受一次请求，超出就拒绝，并且要求提供写明你的 addon 名称的 User-Agent。每张专辑只查询一次，并保存结果。
- **rex 不读取标签。** 标题、封面、流派和相似艺人都由 Plex 提供。如果 Plex 不认识某首曲目的 release，它会显示你提供的 `display`，并归在你指定的艺人和专辑下；如果没有提供 `display`，则会以文件名显示在 `[Unknown Artist]` 下。
- **原样播放。** 无需 FFmpeg，除非某个应用请求低于原始质量的版本：此时 rex 会像 Plex 那样用 FFmpeg 进行转码。
- **暂不支持。** Plexamp 的电台、混音、Stations 和音效相似曲目需要 rex 不做的分析。

**你应该看到的效果。** 音乐库里出现该专辑，带有 Plex 提供的封面和曲目名，艺人也带有照片。在 Plexamp 中，选择 rex 的音乐库作为其 library。

## 直播电视 {#live-tv}

**它的作用。** 让直播流在 Plex Web 和 Plex for Android 的 **Live TV** 中成为一个频道，并带有电视节目指南、What's On 和频道号。

**为什么重要。** 光有直播流，它只是媒体库里的一行。加上 `channel` 之后，大家就能像找电视节目一样找到它：在节目指南里，按现在正在播出的内容查找。

和第 3 步一样发送直播流（带探测的 `.m3u8`），再加上 `channel`：

```json
"channel": {
  "number": "100.1",
  "title": "Rex News",
  "guide": [
    {"start": "2026-11-01T18:00:00Z", "end": "2026-11-01T19:00:00Z",
     "title": "Evening News", "summary": "The day's headlines.", "categories": ["News"]},
    {"start": "2026-11-01T19:00:00Z", "end": "2026-11-01T19:45:00Z",
     "title": "The Pilot", "type": "episode", "show": "Rex Stories", "season": 1, "episode": 1,
     "categories": ["Drama"]}
  ]
}
```

| 字段 | 含义 |
|---|---|
| `number` | 频道在节目指南中的编号（如 `100.1`、`704`）：可以使用字母、数字、`.`、`-` 和 `_`。请选择其他插件没有用过的编号；第一个带编号发送的频道会保留该编号 |
| `title` | 频道在节目指南中的名称。默认值：直播流的 `display` 标题 |
| `call_sign` | 频道的简称。默认值：`title` |
| `guide` | 正在播出的节目：`start` 和 `end`（Unix 时间戳，单位秒，或带 `Z` 或时区偏移的 ISO 8601 格式）、`title`，以及可选的 `summary`、`categories`、`thumb` 和 `previously_shown`（重播时设为 `true`）。剧集需要加上 `"type": "episode"`，以及 `show`、`season` 和 `episode`，节目指南会把它归到所属剧集下面 |

- **发送从几小时前到你所知的最远未来的节目单**（大约一周，和电视节目指南文件的常见范围一致），节目单有变化时要重新发送。rex 会一直列出节目，直到它结束后三小时。每次发送都会替换频道的节目单；不带 `channel` 的发送会保留原有节目单；`"channel": null` 会结束该频道。
- **需要 FFmpeg**，和所有直播流一样：rex 会在有人观看时实时转换频道。
- **不会录制。** Plex Web 和 Plex for Android 都没有 Record 按钮。
- **频道可以结束。** 注册时使用 `"trash": false`（见第 2 步），这样你删除的频道会被直接删掉，而不会进入 rex 的回收站。
- **分类的作用。** `Sports` 或 `News` 分类的剧集会出现在 What's On 的 Sports 和 News 栏目中。没有 `type` 的节目会按电影显示，这和 Plex 处理任何电视节目指南的方式一样。

**你应该看到的效果。** 在 Plex Web 或 Plex for Android 中，应用菜单里有 **Live TV**，节目指南中该频道显示在对应编号下，打开它时直播流会开始播放。如果 rex 拒绝了某个频道，日志会指出是哪个频道以及原因，例如 `channel.guide[3]: end must be after start`。

[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) 为直播体育服务器的频道完成了以上全部工作：它按分组从 `100.1` 开始编号，保留每个频道的编号，并从 Pluto TV 和 epgshare01 的免费 XMLTV 文件获取节目单。

## 容易踩坑的规则 {#the-rules-that-trip-people-up}

| Rule | What happens if you break it |
|---|---|
| **ID 一经确定永不更改。** 修改它，视频就会变成一个新标题 | 观看记录和编辑内容会留在旧行上，下一次快照会将其删除 |
| **一个视频，一个路径。** 两个 ID 不能共用同一个 `path` | 第二个会被拒绝：`... is already <id>'s file` |
| **每个 ID 对应的文件字节是固定的。** rex 会保留首次探测时得到的流；之后的探测只会更新章节。只有流（`.m3u8`）在探测到的流不同时才会接受新的探测结果 | 如果文件字节发生了变化（比如换了格式、重新上传了修复版），就给它分配新的 ID 和路径 |
| **所有内容都要探测。** 没有 `media_info` 就没有视频 | 文件会一直处于 `held` 状态，直到某次发送附带了媒体信息；流则会被拒绝 |
| **保持来源名称不变。** 数据行属于 (source, id) | 换一个名称会新建一个空的来源；旧来源的数据行会一直保留，直到你手动删除 |
| **快照必须完整。** 缺少某个频道的快照会把该频道删除 | 部分失败后不要发送快照：跳过这一轮 |

要**替换**已经填充过媒体库的插件（或脚本），请保持它的来源名称、ID 和第一段路径不变。这样你的第一次发送会原地更新其数据行，包括观看记录，而不是新建数据行。

## 示例：rex-stremio {#example-rex-stremio}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) 可以把你的 Stremio 插件目录变成 rex 库：电影进入电影库，剧集进入剧集库，直播频道进入名为 Live TV 的库（不是 Live TV 节目指南）。它负责第 1 到第 5 步，只有一个 Python 文件，仅使用标准库。它不会删除任何内容，目录里的标题不归它管，所以它不会去删。

**注册。** 你勾选的每个目录都对应一个库，除非你改了名字，否则就是 Stremio Films、Stremio Shows 或 Live TV。rex-stremio 以 `stremio` 注册，每个库对应一个目录，目录名与库名相关（`stremio-films`）。剧集目录的库会声明为目录的 `shows` 标题，电影和直播目录则声明为 `movies` 标题。

**提供播放。** 流媒体插件的链接会过期，所以 rex-stremio 不保存任何链接。它为每个标题提供一个地址 `/<directory>/<catalog>/<id>.<ext>`，并重定向到此刻现取的链接：

```python
url = app.sync.resolve(vid)   # ask every stream addon, rank, take the first link that opens
self.send_response(302)
self.send_header("Location", url)
```

它会向每个提供该标题的插件请求（`/stream/<movie or series>/<id>.json`），只保留普通的 `http(s)` 链接（种子的 `infoHash` 不是 rex 能读的文件），去掉超出你分辨率或大小限制的，然后按分辨率从高到低依次尝试。能打开的链接会缓存，直到它过期前一小时为止（如果链接里没有过期时间，则缓存一小时）。rex 跟随重定向，直接从链接读取文件，支持跳转。需要自带请求头的链接，由 rex-stremio 自己中转；HLS 主播放列表则只返回其中最佳的一个变体。

**探测。** 每个标题只探测一次：rex-stremio 对它自己的地址运行 ffprobe，因此 `media_info` 描述的正是 rex 将要读取的内容，并缓存结果。同时最多检查 `probe_workers` 个标题（未设置时为 4 个），并且对每个插件主机的请求间隔仍不少于 `stream_interval_seconds`。探测所用的流会被记住，之后每次播放都优先尝试它，所以播放的内容就是 rex 被告知的内容。探测得到的容器决定路径的扩展名：`.mkv`、`.mp4`、`.ts`、`.avi`，或 HLS 的 `.m3u8`。

**已存的探测结果。** 如果你设置了 DMM API 密钥（`dmm_api_key`，或设置页上的 **DMM**），当 DMM 已经有某个种子文件的探测结果时，种子流就会跳过 ffprobe。种子的哈希来自流的 `infoHash`，或来自它的链接（Torrentio 的 debrid 链接在路径里带有哈希）。rex-stremio 通过对链接发送一个字节的 `Range` 请求，从响应中读取文件大小，然后调用 DMM 的 `POST /api/sponsor/mediainfo`，每次最多查询 100 个哈希。只有当该发布版本中恰好有一个文件的大小相符时，它才采用 DMM 的探测结果；如果流里写明了文件名，还要求文件名也对得上。其他情况仍按上面的方式探测，而且探测结果会回传给 DMM（`POST /api/sponsor/probes`：种子哈希、文件大小、流中写明的文件名（如有），以及 ffprobe 的输出，但不含它读取的地址），这样下一个遇到该文件的赞助者就能跳过探测。DMM 保留某个文件的第一份探测结果，并优先采用 zurg 自己的快照。设置 `share_probes: false` 则只留在 rex-stremio 内部，DMM 的结果仍然会被使用。播放列表的探测结果从不会被发送。

**命名。** 每部电影和每集都会带着 `kind` 和它的 IMDb id（放在 `ids` 中）交给 rex，因此 Plex 会按 [用你自己的应用接入 rex](any-source.md) 中的方式命名。目录自带的标题、简介、日期和海报放在 `display` 中，它只在 Plex 完成命名之前显示。直播频道，或者只有插件自己知道的标题，没有 IMDb id，因此仅靠 `display` 来命名。

**编号。** 电影就是电影。剧集的季和集来自 Cinemeta，它的 id 与 IMDb 一致，并保留其原有编号，所以新增一集不会挤乱其他集。rex 会按 TMDB 的编号放置它们，因此当 Cinemeta 的编号与之不同时，某一集就会被放到错误的位置。

**Id。** id 由目录加上 IMDb id（以及季和集）组成，例如 `st-<catalog>-tt0111161`。它永远不变，所以同一部电影出现在两个目录里就是两个条目。开启 **Catalogs as collections** 后，同一库中多个目录都列出的电影或剧集，在库里只算一个标题，并分别出现在各自目录的合集中。

**发送。** 每六小时以及每次保存后执行一轮：先注册，然后每个标题在检查完成后立即发送（`POST .../items`，每次最多 20 个标题，或每 5 秒发送一次已就绪的标题），最后为每个目录发送一次快照，每份快照分成每部分 200 项。保存后的第一份快照带有 `"force": true`，因为取消勾选目录可能一次移除超过一半的内容。如果某个目录返回空结果或只返回部分结果，这一轮就不发送快照：它只添加和更新，不删除任何内容；之后一轮完整的更新会移除真正已经消失的内容。

## 故障排除 {#troubleshooting}

| 你看到的 | 原因 | 解决办法 |
|---|---|---|
| `rejected`：`not a video file` | 文件名没有视频扩展名，或者是 probe 不是 `hls` 的 `.m3u8` | 把流命名为 `.m3u8` 并发送它的 probe。歌曲需要 `"kind": "track"` |
| `rejected`：`no music library holds <file>` | 没有音乐库接收这首曲目 | 在第 2 步用 `music` 声明一个音乐库 |
| 专辑中你的文件名显示在 `[Unknown Artist]` 下 | 没有 `ids.mbid`，或者 Plex 不认识那个 release id，并且没有 `display` | 发送专辑的 MusicBrainz release id，或者发送 `display` |
| 专辑显示的曲目不对 | `ids.mbid` 指向了该专辑的另一个版本，比如曲目更多的豪华版 | 选一个曲目数与你的一致的 release |
| 频道不在 Live TV 节目指南中 | 没有 `channel`；它被拒绝了，rex 的日志会说明原因（`channel.guide[...]`）；或者另一个频道已经占用了这个编号，这种情况不会记录在日志中 | 修正日志中指出的字段，或者选一个空闲的编号 |
| Plex 应用中看不到 Live TV | 还没有发送带 `channel` 的项目，或者应用没有经过测试 | 发送一个 `channel`，并使用 Plex Web 或 Plex for Android，这两个是经过测试的应用 |
| 视频一直不出现 | 它被扣住了（其 `media_info` 没有流，或者发送时没带流信息），或者发送时没有 `media_info` 的流被拒绝了 | 对它做 probe 然后重新发送 |
| `rejected`：`... is already <id>'s file` | 另一个 id 已经使用了这个 `path` | 每个路径只保留一个 id |
| 快照返回 `409`：`the snapshot would remove more than half of this source's items` | 你的快照遗漏了 rex 从你那里拿到的一半以上内容：可能是磁盘缺失、列表获取失败，或者真的做了清理 | 修复丢失的部分。如果确实是有意的，就发送快照的最后一部分并带上 `"force": true` |
| 剧集标题显示为 "Episode 1"，并且海报是空白的 | 没有 `display` | 发送每个视频时附带 `display` |
| 用 IMDb id 发送的电影仍显示你的 `display` 标题，而不是 Plex 的标题 | rex 只有在被认领后才会向 Plex 请求标题 | 认领 rex：[使用你自己的应用时的第 3 步](any-source.md#step-3-add-it-to-a-plex-account) |
| 图片不显示 | URL 在你的家庭网络上，但不在你的插件注册的 `url` 之下，或者不是 http(s) | 从你插件自己的地址提供图片，或者把图片托管到公网上。 |
| 播放时 rex 日志中出现 502 | 你的插件没有应答，或者流的站点拒绝了它 | 先检查你插件自己的日志 |
| 在 Plex 应用中删除的标题仍然存在 | 你的插件对 `DELETE` 的应答不是 `2xx` 或 `404` | 先在你这边删除它，然后应答 `2xx` |
| 已删除的标题又回来了 | 你的插件仍然在发送这个视频 | 停止发送已被删除的内容 |

还是没解决？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。[获取帮助](../guides/remote-help.md) 说明了需要提供哪些信息。
