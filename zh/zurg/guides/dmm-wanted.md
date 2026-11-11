# 从 DMM 获取你想要的内容 {#fetch-what-you-want-from-dmm}

[Debrid Media Manager](https://debridmediamanager.com) 上点 **Want**，选一部电影或剧集，你的 zurg 就会把它抓下来。不需要设置 Sonarr 或 Radarr，也不需要挂载任何东西。剧集播出新一集时，也会自动获取。

这个功能只面向赞助者：zurg 会用你的 DMM API key 读取你的清单。

## 你需要准备 {#what-you-need}

- 2026-10-25 或之后的 zurg nightly 版本。
- 你的 DMM API key，填在 zurg 的 `config.yml` 里。这是你赞助后 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 显示给你的密钥：

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- zurg 要下载内容的目标：一个支持种子的 debrid 账户、用于 Usenet 的 `nzb` 或 `torbox_nzb` 提供商，或者两者都要。

这就是全部设置。zurg 从启动那一刻起，每分钟读取一次你的列表。

## 添加影片 {#adding-titles}

1. 在 DMM 的 [设置](https://debridmediamanager.com/settings) 页面粘贴同一个密钥。
2. 打开一部电影并点击 **Want**。在剧集的季页面上，**Want S2** 会添加该季，**Want all seasons** 会添加整部剧，包括之后新增的季。
3. 你的列表位于 [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted)。页面会显示 zurg 上次读取该列表的时间，以及每部电影被抓取的时间。列表较长时，每页显示 120 个标题。

来自 Seerr、Overseerr 或 Jellyseerr 的请求也可以出现在同一个列表中：参见 [通过 DMM 使用 Seerr](../../dmm/seerr.md)。

## 订阅列表 {#following-a-list}

把 Trakt 或 MDBList 列表的页面粘贴到你的[想看列表](https://debridmediamanager.com/wanted)上，然后点 **Follow**。列表里的每部电影和每个节目都会进入想看列表，DMM 每六小时会重新读取一次列表，所以之后加进列表的内容也会被加进来。支持以下页面：

- `https://trakt.tv/users/<user>/lists/<list>` 和 `https://trakt.tv/lists/<id>`
- `https://trakt.tv/users/<user>/watchlist`（前提是该 Trakt 账号是公开的）
- `https://mdblist.com/lists/<user>/<list>`

在 DMM 自己的 Trakt 页面上，你的观看清单和每个列表旁边都有一个 **Follow with Want** 按钮，效果一样。

如果是 IMDb、Letterboxd、Rotten Tomatoes 或 Plex 的观看清单：先在 mdblist.com 上用它的网址创建一个[外部列表](https://docs.mdblist.com/docs/external_lists)，然后关注这个列表。MDBList 会让它和原始来源保持同步。

关注之后会发生这些事：

- 节目会整部加入想看，包括之后新增的季。
- 只有自上次读取以来新加入列表的内容才会被添加。你从想看列表里删掉的内容会保持删除状态，从列表里移走的内容会保留在想看里。**Unfollow** 会保留列表已经添加的内容。
- 页面会显示每个列表的标题数量、目前已添加的数量，以及上次读取的时间。**Read again** 会立即重新读取。没有 IMDb id 的标题会被忽略，数量里会注明有多少个。
- 你的列表最多可容纳 10,000 个仍待获取的标题：包括所有节目，以及 zurg 还没有获取或正在等待升级的电影。zurg 已经获取的电影不计算在内。超出容量的标题会在之后的读取中添加，等有空位了再加入。

## 从 Radarr 或 Sonarr 迁移 {#moving-from-radarr-or-sonarr}

在 Radarr 或 Sonarr 中，打开 **System → Backup**，点击 **Backup Now**，然后下载
   zip 文件。其 `Backups` 文件夹中的定时备份也可以用。

在你的 [想看列表](https://debridmediamanager.com/wanted) 上，点击 **Import a Radarr or
   Sonarr backup**，选择 zip 文件。然后对另一个应用的备份做同样的操作。

会导入的内容：

- 从 Radarr 导入：每部受监控、没有文件、并且已达到 minimum availability 的电影。没有 IMDb id 的电影会被跳过，页面上会显示跳过的数量。
- 从 Sonarr 导入：每部受监控、且有已播出但缺失集数的剧集，只导入缺失的那几季。
- 已经在你列表里的标题保持不变。

只有 zip 里的数据库会被上传。备份中的其他内容（包括应用的 API key）都留在你的电脑上。

有两样东西不会被导入：

- **Quality profiles（质量配置）。** zurg 会根据自己的[获取设置](acquisition.md#configuration)来选择版本。Radarr 通常会拒绝 camera 和 telesync 版本；要把它们挡在外面，请把它们加到 [`exclude_words`](acquisition.md#excluding-releases-by-name) 里：

  ```yaml
  acquisition:
    exclude_words: [CAM, CAMRip, HDCAM, TS, HDTS, TELESYNC, TC, HDTC, TELECINE]
  ```

- **Sonarr 的季号（如果不一样）。** 你的列表按 TMDB 的方式给季编号。Sonarr 遵循 TheTVDB，而 TheTVDB 会把一些长播动画拆成更多季，所以 TMDB 没有的 Sonarr 季不会被获取。请在这些剧集的 DMM 页面上检查，并对缺少的季点击 **Want**。

## zurg 会获取什么 {#what-zurg-fetches}

- **一部电影**只抓取一次。之后它就会离开 zurg 读取的列表。如果抓到的版本低于 `quality` 要求的分辨率（`best` 对应 2160p），它会留在列表里。这样一旦出现更好的版本，zurg 就会抓取新版本，并删除之前抓的那个。你自己添加的版本会被保留。在 zurg 配置的 `acquisition:` 下设置 `upgrades: false` 可以关闭这个功能。`/wanted` 会显示 zurg 已经抓到的内容，以及它仍在等待的分辨率，不过使用下面列出的分辨率列表时除外。
- **一部电影同时保留 1080p 和 4K 版本**，如果你两种都想要，比如让 1080p 电视直接播放 1080p 文件，避免转码 4K 文件。需要 2026-10-31 或更新的 nightly 版本。在 zurg 配置中列出分辨率：

  ```yaml
  acquisition:
    quality: [1080p, 4k]
  ```

  这样 zurg 会为每部电影在每种分辨率下各保留一个版本。每个版本都会选取不高于自身分辨率的最佳发布版本，并且各自独立升级，所以 1080p 版本永远不会变成 2160p 版本。如果还没有比 1080p 更好的发布版本，两个版本通常会选中同一个发布，你最终只会得到一个文件。列表中也可以加上 `720p`。剧集仍然只保留一个版本，选择方式与你只写最高分辨率时相同。在你添加分辨率列表之前，zurg 已经抓取过的电影会在每种分辨率下重新抓取。zurg 不会删除之前的版本，所以如果不需要，请自己删除。完整规则请参阅[同一部影片保留多个分辨率版本](acquisition.md#a-copy-at-each-of-several-resolutions)。
- **一部剧集**：你选定季的每一集已播出的内容。能用整季包的季会抓整季包，仍在播出的季则抓单集。它会持续检查新集，直到你移除该剧集。特别篇不会被抓取。

发布内容可以来自 Usenet 的 NZB，也可以来自你的 debrid 账户中已缓存的种子。未缓存的种子永远不会被添加。如果你没有设置任何索引器，zurg 会搜索 DMM 自己的索引。质量、大小限制、要避开的词语，以及发布内容必须包含的音频和字幕语言，都由 zurg 的[抓取设置](acquisition.md#configuration)统一控制，适用于所有来源。

## 在 Kodi 或 Plex 中观看 {#watching-it-in-kodi-or-plex}

开启 `__magic__` 后，zurg 会按标题整理它获取的文件，放进 `__magic__/__movies__` 和 `__magic__/__shows__`，文件名按 Kodi 和 Plex 能识别的方式命名。把 Movies 库和 TV 库分别指向这两个文件夹即可。如果开启了 `magic.anime`，还要把 Anime 库指向 `__magic__/__anime__`。详见 [`__movies__` 和 `__shows__`](magic.md#__movies__-and-__shows__-sorted-by-title)。

```yaml
magic:
  enabled: true
```

## 一个 key 运行两个 zurg {#two-zurgs-on-one-key}

每个 zurg 都读取同一份列表，所以如果有两个 zurg，就会把每个标题抓取两次。只在其中一个上保留这份列表，在其他的上把它关掉：

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## 何时会停止 {#when-it-stops}

如果你的赞助过期了，或者你重置了密钥，zurg 会记录 DMM 拒绝了该密钥，并且每小时重新请求一次。它已经获取的内容仍然保留在你的媒体库中。

更多细节：请参阅 acquisition 参考文档中的 [DMM wanted list](acquisition.md#dmm-wanted-list)。
