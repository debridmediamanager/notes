# 更多 addon 功能 {#more-from-your-addon}

[构建 rex 插件](addons.md)介绍了基础内容。本页补充字幕、预告片、章节、合集、播放列表、艺术家图片、已知影片、大型媒体库、修复和移除等内容。每个部分都会为 [第 5 步](addons.md#step-5-send-it) 添加字段。你可以在 [家庭视频](addon-home-videos.md)、[音乐](addon-music.md) 或 [IPTV](addon-iptv.md) 教程中试用它们。

所有示例都已发送到 rex nightly 2026.11.02。完整参考文档见 [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md)。

## Plex 认识的电影和剧集 {#films-and-shows-plex-knows}

**What it does.** Lets Plex name a film or episode, with its poster, cast, summary and ratings, instead of your `display`.

Send `kind` and the title's ids: an IMDb (`tt...`) or TMDB id of the film, or of the **show** for an episode, with `season` and `episode` on TMDB's numbering:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**What you should see.** The film is **Big Buck Bunny (2008)** with Plex's artwork, whatever the file is called. rex reads nothing from names: what you send is what it shows. [rex with your own app](any-source.md) covers this in full, episodes included.

## 字幕 {#subtitles}

**功能说明。** 提供与视频放在同一位置的字幕文件，并把它们作为该视频的字幕。用户可以像选择上传的字幕一样挑选、下载，或将其烧录进画面。

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| 字段 | 含义 |
|---|---|
| `path` | 字幕文件在你的插件上的位置，与视频的路径相同。扩展名即为格式：`srt`、`ass`、`ssa`、`smi`、`txt` 或 `psb` |
| `language` | `en` 或 `eng`，按你所知填写。rex 不会从文件名中读取语言 |
| `forced`, `hearing_impaired` | 设为 `true` 即可标记 |
| `size` | 文件大小，单位为字节。只有路径是新的或大小发生了变化，rex 才会重新读取该文件 |

**你应该看到的效果。** 视频会列出一个 **English (SRT External)** 字幕。省略 `subtitles` 会保留你之前发送的内容；发送 `[]` 会移除你发送的字幕（上传或下载的字幕仍然保留）。rex 无法读取的文件会被忽略并记录到日志中，但视频仍会被正常接收。

## 预告片和其他附加内容 {#trailers-and-other-extras}

**功能说明。** 把预告片、花絮或删减片段放到对应电影或剧集的 **Extras** 中，而不是让它作为一个单独的标题出现。

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

额外内容属于其 `release` 中其他视频所在的标题（默认是它所在的文件夹）。`extra_type` 可以是 `trailer`、`deleted`、`featurette`、`behindthescenes`、`interview`、`scene`、`short`、`opening`、`ending` 或 `other`。rex 从不通过文件名或文件夹来判断视频是不是额外内容，只有 `kind: "extra"` 才会把它标记为额外内容。

**你应该看到的效果。** 电影页面会在 Extras 下显示这个预告片，媒体库里则不会列出它。

## 章节 {#chapters}

**作用。** 让用户可以在播放器中跳转到不同章节。

同时运行 `ffprobe` 并加上 `-show_chapters`，然后原样发送它的输出：

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**你应该看到的。** 视频的章节，包括章节名称和时间。要给 rex 已有的视频添加章节，请在下一次快照中再次发送它们的 probe 结果（加上 `-show_chapters`）。

## 合集和播放列表 {#collections-and-playlists}

**它的作用。** 将影片按合集分组，将歌曲或视频按播放列表分组，这些合集和播放列表由你的插件创建并保持更新。

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| 字段 | 含义 |
|---|---|
| `collections` | 该影片所属的合集，按名称列出。每个合集会在某个影片首次提到它时创建。 |
| `playlists` | 该文件所属的播放列表，按标题列出，并标明它在每个列表中的位置（从 1 开始）。每个播放列表都属于服务器所有者，若其第一首歌是音轨，则为音频列表，否则为视频列表。 |

你的改动会被保留：有人把某个影片移出了合集，它就会一直留在外面；有人在你的播放列表里添加了一首歌，这首歌会保留它的位置；有人重命名了播放列表，它就归他们所有。省略某个字段会保留你之前发送的内容；发送 `[]`（播放列表则为 `{}`）会把文件从你的插件放入的所有位置移除。

**你应该看到的效果。** 媒体库的 Collections 标签页会列出 **Summer 2026**；Playlists 中会按你的顺序列出 **Road trip**。

## 艺人图片 {#artist-pictures}

**作用。** 对于你的音乐插件发送过来的艺人,显示你提供的图片,即使 Plex 已经认识这位艺人并自带图片,也照样显示。

注册时使用 `"artwork": "source"`,并在每首曲目上发送图片:

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

如果没有 `artwork: "source"`,Plex 已经认识的艺人会保留 Plex 自己的图片,`display.artist` 只会在 Plex 不认识的艺人上显示。不管哪种情况,如果有人在 Plex 应用里挑选或上传过图片,都会保留。

## 大型媒体库：只发送一次探测 {#big-libraries-send-probes-once}

**作用。** 让一份包含数千个视频的快照几乎不发送 `ffprobe` 输出，因此体积小、速度快。

发送 `probe`，这是你自己生成的一段简短文本，每当视频的 probe 发生变化时它也会随之改变（使用 `ffprobe` 输出的哈希值即可）。一旦 rex 已有带该 `probe` 的视频，就只发送 `probe`，不带 `media_info`：

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

rex 会回复 `"unchanged": 1`。如果它没有该 `probe`（新视频，或 probe 已变化的视频），它不会做任何更改，而是请求该数据：

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

再次带上 `media_info` 发送这些条目。快照会把想要的条目视为已发送，因此不会因此被移除。请确认你的 rex 支持这一功能：[注册](addons.md#step-2-register-with-rex)的回复中应列出 `"features": ["probe_digest"]`。

## 用户修复了什么：Fix Match {#what-people-fixed-fix-match}

**功能说明。** 告诉你的插件，它的哪些视频被人在 Plex 应用里手动匹配过（Fix Match），这样插件之后就能直接发送它们。

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

每一条记录都包括一个 `release`（一个文件夹，除非你发送的是 `release`），以及它所匹配到的电影或剧集的 ids。无论你之后发送什么，rex 都会保留这个匹配，所以即使你忽略这些内容也不会出问题；但读取它可以让你的插件自己发送 `kind` 和 `ids`，并且在 rex 的记录被重建时仍能记住这次修正。如果没有任何匹配，返回结果为 `{"size": 0}`。

## 移除你的 addon {#removing-your-addon}

**作用。** 将你的插件及其发送出去的全部内容从 rex 中移除，同时不改动它的文件。

这需要两次请求：第一次会显示将要删除多少内容，并给出一个五分钟内有效的链接；第二次请求则执行删除。

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

观看历史会随记录一起删除。之后重新注册并再次发送，会从零开始，生成新的记录。若想用新版本**替换**某个插件，请保留它的名称、ID 以及路径的第一段：新版本会更新同一批记录。rex 从不删除媒体库；如果你想删掉它们，请在 Plex 应用中自行删除。

## 谁可以发送到 rex {#who-may-send-to-rex}

rex 的 feed（`/rex/sources` 和 `/rex/feed`）不需要 token。它只响应 rex 所在机器本身、你的家庭网络（`192.168.x.x`、`10.x.x.x`、`172.16-31.x.x` 以及私有 IPv6 地址）和 Tailscale（`100.64-127.x.x`）上的程序；对于其他人来说，这些地址根本不存在，即使你为 rex-direct 转发了 rex 的端口，或者通过 IPv6 允许访问也一样。如果你在 rex 所在的机器上放了反向代理，它会把请求当作本地程序来访问 rex，所以如果你在 rex 前面放了反向代理，要在那里屏蔽 `/rex/`。
