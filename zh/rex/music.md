# 用 rex 听音乐 {#music-with-rex}

rex 可以为 Plexamp、Plex Web 和 Plex for Android 保存一个音乐库。音乐插件会发送每首歌曲及其 MusicBrainz 版本信息。Plex 会补充名称、封面、艺术家详情、流派和相似艺术家。

你会得到：

- **Plex 认识的专辑。** 带有 MusicBrainz 版本信息发送的专辑，看起来就和在任何 Plex 服务器上一样，有 Plex 的封面和曲目名称。Plex 不认识的专辑则显示插件发送的名称和图片。
- **原始音质。** 歌曲以其原本的格式播放，例如 FLAC。
- **歌词和响度。** 如果插件发送了歌词，歌词会随歌曲一起显示。rex 还会像 Plex 一样，把每首歌的响度信息传给各个应用。
- **你自己的播放记录和播放列表。** 播放记录、评分和播放列表按 Plex 账户分别保存。Plexamp 创建的智能播放列表也会保存在 rex 上。

## 开始之前 {#before-you-start}

| 你需要的 | 原因 |
|---|---|
| 2026.11.02 或更新日期的 rex nightly 版本 | 音乐功能是在该版本中加入的 |
| 按照 [rex with your own app](any-source.md) 设置好 rex | 音乐库就是在这里显示的 |
| 一个音乐 addon | 任何通过 rex 的 feed API 发送歌曲的程序。如果你想用自己硬盘里的专辑文件夹，[Tutorial: a music addon](addon-music.md) 是一个完整的示例，只用一个 Python 文件就能实现 |
| [Converting video](any-source.md#converting-video-optional)，可选 | 只有当应用设置的音乐质量低于原始文件时，rex 才会转换歌曲 |

## 第 1 步：安装 rex 并将其添加到 Plex 账户 {#step-1-install-rex-and-add-it-to-a-plex-account}

按照[用你自己的应用使用 rex](any-source.md)操作：

1. [第 1 步：安装 rex](any-source.md#step-1-install-rex)，包括查找 rex 的局域网 IP。本页写的是 `192.168.1.20`：把它换成你自己的 IP。
2. [第 3 步：添加到 Plex 账户](any-source.md#step-3-add-it-to-a-plex-account)：在新账户上注册 rex，然后共享给你自己的账户。

## 第 2 步：将你的音乐插件指向 rex {#step-2-point-your-music-addon-at-rex}

rex需要一个音乐库来存放歌曲。如果你的插件声明了音乐库，rex会在插件注册时自动创建它。如果没有声明，请先用新账号登录Plex应用，添加一个库：点击**Add Library**，选择**Music**，然后选一个任意文件夹。在音乐库存在之前发送的歌曲会被拒绝。

然后按照插件自己的说明，把rex的地址`http://192.168.1.20:32400`填进去。插件会向rex注册自己，并发送它的专辑。

**你应该看到的结果。** 在rex的日志中：

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    SECTION create Music (artist) for <addon>'s music
INFO    FEED <addon> upsert: ...
```

只有插件声明了音乐库时，才会出现`SECTION create`这一行。音乐库会出现在rex里，每张专辑都归在对应的艺术家之下。被rex拒绝的歌曲会在日志中显示原因，例如`no music library holds <file>`。

## 第 3 步：共享音乐库 {#step-3-share-the-music-library}

音乐库是新建的，还没有分享给任何人。用新账号登录后，在 **Manage Library Access**（[分享 rex](sharing.md)）里，把它分享到你自己的账号，以及其他所有人的账号。

## 第 4 步：开始听 {#step-4-listen}

- **Plexamp**：用你自己的 Plex 账号登录，然后选择 rex 的音乐库作为你的媒体库。
- **Plex 网页版和 Plex for Android**：音乐库与 rex 的其他媒体库放在一起。

**你应该看到的效果。** 专辑会显示 Plex 的封面和曲目名称，艺人会显示照片。点击播放即可。

## 它做不到的事 {#what-it-cannot-do}

- **没有电台、混音或电台站点。** Plexamp 的电台、混音、站点和“声音相似”歌曲都需要分析每首歌曲，而 rex 不做这件事。
- **没有自己的音乐文件夹。** rex 不扫描任何目录，也不读取标签。插件需要把每首歌曲发送过来，并附上其专辑的 MusicBrainz release，Plex 才能正确命名。
- **同一张专辑的两个副本就是两张专辑。** 和其他 Plex 服务器一样，FLAC 版本和 MP3 版本会各自显示为一张专辑。
- **已在 Plexamp、Plex Web 和 Plex for Android 中测试。** 其他 Plex 应用，以及 Plexamp 的离线下载功能，尚未测试。

如果你想自己编写音乐插件，请从[教程：音乐插件](addon-music.md)开始；[构建 rex 插件](addons.md#music)列出了所有字段。
