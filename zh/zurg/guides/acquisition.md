# 获取来源 {#acquisition-sources}

Plex 观看列表、你的 [DMM 想看列表](#dmm-wanted-list)、[Seerr](https://github.com/seerr-team/seerr)、
[Radarr](https://radarr.video) 和 [Sonarr](https://sonarr.tv) 共用同一个获取引擎。它负责跟踪进度、
重试和确认。Newznab 的结果会变成 NZB，供 zurg 的 Usenet 后端使用。Torznab 的结果会变成
info hash，供 debrid 账户使用。参见 [Newznab 和 Torznab](#newznab-and-torznab)。

引擎只有在检查过之后才会确认一次抓取。NZB 必须能够到达新闻服务器。在 `torbox_nzb` 账户上，则改由 TorBox 去获取。种子必须在库中以文件的形式出现。参见 [验证抓取](#verifying-a-grab)。

zurg 抓取到的发布会保留它所对应标题的 ID，也就是 Plex 用来匹配标题的每一个 ID：IMDb、TMDB，以及剧集的 TVDB。之后不会再根据名称重新识别它。这些 ID 会替换 DMM 或发布名称给它的任何 ID，但绝不会替换你手动设置的 ID。如果某个发布在 zurg 选中它之前就已经在你的库中，它可能是为别的内容添加的，因此只有在它没有 ID，或者已有的 ID 与之相同时，才会采用这些 ID。设置 [`rex_url`](../reference/config.md#rex) 后，抓取的电影会按这些 ID 作为该电影发送给 rex，即使 DMM 无法为它定位也一样。剧集的集数仍然按 DMM 的定位来编号，但会带上该剧的 ID。zurg 启动时，还会对已保存任务抓取过的每个发布做同样的处理，从而修复那些在此改动之前丢失了 ID 的发布。

## 配置 {#configuration}

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

在 zurg 实例上运行此功能，需要配置 `nzb` 提供方或 `torbox_nzb` 账户（TorBox Pro），或者一个支持种子的 debrid 账户，也可以两者都配置。来自 Newznab 索引器的 NZB 会进入其 `nzbs/` 目录。`torbox_nzb` 账户没有可供比对的新闻服务器；在该账户上抓取的内容，会通过 TorBox 是否已成功获取来判断。来自 Torznab 索引器的种子会交给 debrid 账户处理。只有当该账户已缓存这些种子时，才会添加。两种账户都没有时，这些源不会启动。原因请见获取页面。Plex 需要已有的 `plex_token`。Seerr 需要其 base URL 和 API key，与 zurg 中的任何 Plex 设置无关。支持 URL 子路径，以及以 `/api/v1` 结尾的 URL。Radarr 需要其 base URL（像 `/radarr` 这样的 URL base 以及末尾的 `/api/v3` 都可以）、来自 **Settings > General** 的 API key，以及当其看到的 zurg 挂载路径不同时所用的 `library_path`：参见 [Radarr 行为](#radarr-behavior)。Sonarr 使用相同的三项设置：参见 [Sonarr 行为](#sonarr-behavior)。

这两项都会在 zurg 启动时读取，与该配置块中的其他设置一样。`indexer_concurrency` 同时涵盖搜索和 NZB 下载，因为索引器是按 key 而不是按接口计量的。索引器 key 通常是共享的，经过测试，对于同时服务其他应用的 key，每个 key 三次调用是安全的。

请保持名称和 Seerr URL 不变：它们用于标识已保存的队列。更换 Seerr key 不会丢失其队列。添加源或修改其 URL 或凭据后，需要重启。现有的 `watchlist:` 和 `plex_watchlist_enabled` 设置会通过自动的 `plex-watchlist` 适配器继续生效。显式的 `plex_watchlist` 源，即使被禁用，也会覆盖旧的启用开关。同一时间只有一个 Plex 源可以使用已配置的 Plex 账户。共享的搜索设置会回退到 `watchlist:` 及其现有默认值；未指定的索引器会回退到 watchlist/Stremio 索引器。

## 按名称排除版本 {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` 列出的是任何获取到的版本名称里都不能出现的词。
用它来让不支持杜比视界或 HDR10+ 的播放器不接收这些版本，同时仍然可以获取 4K。它对所有来源一视同仁：Plex 观看列表、Seerr、Radarr 和 Sonarr 都适用。它对 Usenet 和 torrent 的搜索结果同样适用。被它排除的版本永远不会被获取、保存、添加到 debrid 账户，也不会交给 Radarr 或 Sonarr。不设置它就不会排除任何内容。zurg 和 `config.yml` 中的其他配置一样，在启动时读取它。

## 按名称优先版本 {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

`prefer_words` 列出一些单词（比如发布组名），用来把某个分辨率下的发布排到最前面。它的匹配方式和 `exclude_words` 一样：整词匹配，不区分大小写。列表是有顺序的：含有第一个单词的发布排在含有第二个单词的发布前面，依此类推。它只是一种偏好，不是过滤条件。如果没有任何发布含有这些单词，zurg 就会按没有这些单词时的做法来选。

被偏好的发布永远不会越过分辨率。使用 `quality: best` 时，任何发布组的 2160p 发布仍然排在被偏好的 1080p 发布前面；使用 `quality: 1080p` 时，被偏好的 2160p 发布不会排到 1080p 发布前面。如果偏好的发布组在更高分辨率下没有发布，那么升级到更高分辨率的操作仍然会进行。

它适用于所有来源，对 Usenet 和种子结果同样生效。使用 `radarr` 或 `sonarr` 来源时，配置文件仍然必须接受被偏好的发布。当 Radarr 或 Sonarr 把 zurg 当作下载客户端时，由它们自己选择发布，此时 `prefer_words` 不起作用。不设置它就等于不偏好任何内容。

电影的发布如果名称中的年份与该电影年份相差超过一年，无论来自哪个来源，都不会被选用。有些索引器会把某些帖子归到别的电影的 IMDb id 下：例如 DrunkenSlug 把 The Aswang Chronicles (2012) 归到了它 2014 年的续集下。名称中没有年份的发布不会因此被拒绝。对于 DMM 的想看列表（它会发送一部电影的所有已知标题，包括原始标题、别名和译名），名称中如果没有完整包含其中任何一个标题，该发布同样会被拒绝：例如 DrunkenSlug 把 Przesluchanie (1982) 归到了 An Affair (1982) 下，而 `Rocky.2015` 不是 *Rocky Horror Show Live*。名称可以在标题的副标题开始处之前停止，即冒号之后或带空格的破折号之后，所以 `Diana.2021` 就是 *Diana: The Musical*。重音符号和变音符号两种写法都可以匹配，所以 `Les.Miserables` 和 `Verwuenscht.nochmal` 都算数。

名称的匹配方式如下：

- **只匹配完整单词。** 名称按由字母和数字组成的单词来读取。点、空格、破折号、下划线、方括号和圆括号都用来分隔单词。不区分大小写。`DV` 会排除 `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` 和 `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD`。它不会排除 `DVDRip`、`DVD9`、`Come and See DvD 1`，也不会排除 *Adventures* 这样的标题，因为它们都不含 DV 这个单词。
- **短语按顺序匹配。** `Dolby Vision` 或 `DV HDR` 会匹配这些单词相邻且顺序一致的情况，中间用什么分隔都行。
- **结尾的 `+` 属于单词的一部分。** `HDR10+` 是一个独立的单词。排除 `HDR10` 不会影响 HDR10+ 发布，排除 `HDR10+` 也不会影响普通的 HDR10。想要两个都排除，就把两个都列出来。两个单词之间的 `+` 起分隔作用，比如 `DD+7.1` 或 `DV+HDR10`。
- **同一家族的写法算作一个单词。** 列表中的任意一种写法，都会排除其所在家族的所有写法。

  | 写任意一种 | 会排除含有以下任意一种的名称 |
  |---|---|
  | `DV`、`DoVi`、`Dolby Vision`、`DolbyVision` | `DV`、`DoVi`、`Dolby.Vision`、`Dolby-Vision`、`Dolby Vision`、`DolbyVision` |
  | `HDR10+`、`HDR10Plus` | `HDR10+`、`HDR10Plus` |

  其他写法都不会被归并。`HDR` 会排除含有 HDR 单词的名称，但不会排除 `HDR10`、`HDR10+` 或 `HDRip`。`WEB-DL` 匹配 `WEB-DL`、`WEB.DL` 和 `WEB DL`，但不匹配 `WEBDL`。
- **只读取发布名称。** 这是索引器在下载任何内容之前返回的标题。内部的文件不会被读取。如果名称中没有说明，杜比视界发布就不会被排除。

排除某个单词绝不会影响分辨率。即使排除了 `DV`，带普通 HDR 或 HDR10 的 2160p 发布仍然会被选用，`quality: 4k` 仍然会把 2160p 排在最前。被排除的发布视为未找到。电影或剧集搜索会持续翻阅每个索引器的结果，直到凑够十个可以选用的发布、索引器没有更多结果，或者读满十页为止。季搜索只读取一页，并会为该页中没有可用发布的每一集单独搜索。所有发布都被排除的标题会以 "no eligible releases" 失败，与所有发布都超过 `max_size_gb` 的情况一样，之后会再次尝试。Seerr 的 4K 请求只接受 2160p 发布，所以当所有 2160p 发布都被排除时，它会等待。

### 排除规则与 Radarr 或 Sonarr 配置 {#exclusions-and-radarr-or-sonarr-profiles}

使用 `radarr` 或 `sonarr` 源时，先执行排除规则。被排除的发布版本永远不会交给 Radarr 或 Sonarr 的解析器。任何自定义格式分数都无法把它救回来，它也不算是配置文件的拒绝。其他所有发布版本都会按照 [Radarr 行为](#radarr-behavior) 和 [Sonarr 行为](#sonarr-behavior) 中的描述，由配置文件来判断。一个发布版本必须同时通过这两关。如果某个自定义格式给 Dolby Vision 的分数低于配置文件的最低分，它在 *arr 内部起的作用相同，保留它也没有坏处。

升级遵循同样的规则。如果能把文件提升到配置文件截止线的唯一发布版本都被排除了，文件就会停留在截止线以下，zurg 的升级流程会继续查找，但不会取走任何东西。这种情况出现在自定义格式给 Dolby Vision 打了很高的分，而截止分数又需要它的时候。解决办法是降低截止分数，或者从自定义格式中去掉这个分数。

当 Radarr 或 Sonarr 通过 `sabnzbd:` 或 `qbittorrent:` 配置块把 zurg 用作下载客户端时，它们会自己搜索索引器并亲自挑选发布版本。`exclude_words` 在这种情况下不起作用。请在 *arr 中排除相同的词：使用分数低于配置文件最低分的自定义格式，或者在发布配置文件中使用 **Must Not Contain**。

## 按音频和字幕语言选择 {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

`audio_languages` 只会保留至少有一条列出语言音轨的资源，`subtitle_languages` 只保留至少有一条列出语言字幕的资源。两个都不写就不做任何筛选。两个设置对所有来源都生效。

每个列表同时也是一个优先顺序：语言排在前面的种子会排在只有后面语言的种子前面。`[de, original]` 有德语配音就选德语配音，没有就选原声。

zurg 是从资源的流里读语言的，不看资源名。大多数资源名里并不写语言，《寄生虫》的资源几乎没有一个写了 KOREAN。语言代码写 ISO 639 的两位或三位字母就行：`en`、`eng`、`de`、`deu` 和 `ger` 都能用。`german` 这种名字会在启动时被拒绝。

有些语言的配音或字幕会有区别，这时可以用代码指定具体版本：

| Write | For |
|---|---|
| `es-419`, `es-ES` | 拉丁美洲西班牙语（Latino）或卡斯蒂利亚西班牙语 |
| `pt-BR`, `pt-PT` | 巴西葡萄牙语或欧洲葡萄牙语 |
| `fr-CA`, `fr-FR` | 魁北克法语（VFQ）或法国法语（VFF、VFI） |
| `nl-BE` | 佛兰德语 |
| `yue`, `cmn` | 粤语或普通话 |
| `zh-Hant`, `zh-Hans` | 繁体或简体中文字幕（`zh-TW` 和 `zh-HK` 按繁体处理，`zh-CN` 按简体处理；粤语音频请写 `yue`） |
| `nb`, `nn` | 挪威语书面语（Bokmål）或新挪威语（Nynorsk） |

只写基础代码时会包含该语言的所有版本：`es` 同时包含 Latino 和卡斯蒂利亚，`zh` 同时包含粤语和普通话，`no` 同时包含 Bokmål 和 Nynorsk。语言后面如果跟着 zurg 无法识别的部分，例如 `es-latam`，会在启动时被拒绝。zurg 是通过音轨的标题判断它属于哪个版本的，因为流里的信息 zurg 读不出来。标题里可能写着 "Latino"、"Spanish (Latin American)"、"Castellano"、"French (Canada)"、"VFQ"、"Portuguese (Brazilian)"、"Chinese (Cantonese)" 或 "繁体中字"。如果音轨标题什么版本都没写，它不会因此被拒绝。资源名在有标注时可以用来判断，比如 `Dual-Lat`、`[Castellano]`、`MULTi.VFQ`、`VF2`、`PT-BR` 或 `[ES-LA]`。资源名永远不会拒绝任何东西，而且音轨标题的优先级比资源名高。以 `[es-419, es]` 为例，zurg 按顺序选择：标题为 Latino 的音轨；资源名为 Latino 且音轨没有标题的；没有标题的音轨；资源名为 Castellano 且音轨没有标题的；最后是标题为 Castellano 的音轨。如果你的家里是拉丁美洲人，可以这样设置：

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

`audio_or_subtitles: true` 表示只要资源有音频或字幕之一就保留，不需要两者都有。有音频的资源会排在只有字幕的资源前面。

`original` 指作品制作时使用的语言，以 TMDB 的记录为准：《寄生虫》是韩语，《坠落的审判》是法语。zurg 会向 DMM 查询这个信息，所以需要设置 `dmm_api_key`。没有这个 key 的话，`original` 不会做任何筛选。

### 版本如何被评判 {#how-a-release-is-judged}

- **在添加种子之前。** DMM 会保存 zurg 分析过的每个资源的 ffprobe 数据。设置了 `dmm_api_key` 后，zurg 只需一次调用就能读取所有种子结果的这些数据。如果某个种子的音轨里没有所需语言，它就永远不会被添加。有所需语言的种子会排在完全不了解情况的种子前面。2026-10-25 对五部电影做的测试显示，DMM 掌握了 Real-Debrid 已缓存种子中约三分之一的数据。
- **抓取之后。** 每个抓取的资源，无论是种子还是 Usenet，入库后都会被探测一次：有 DMM 数据就用 DMM 的，没有就用 ffprobe。如果某个抓取资源的音轨里没有所需语言，它会像失效帖子一样被搁置。它会从 debrid 账户或监视目录中移除，下一个候选资源会立即被尝试。仪表盘会说明原因，例如 "it has no English audio, only French"。
- **升级时保留语言。** 当 DMM 的 wanted list 把某部电影升级到更好的分辨率时，新资源必须包含至少与被替换版本同样靠前的语言（按你的语言列表排序）。拉丁美洲西班牙语的 1080p 版本不会被换成卡斯蒂利亚语的 2160p 版本。
- **无法识别的按未知处理，予以保留。** 无法读取的资源绝不会因此被拒绝。包括未标记的音轨、标记为 `und` 或 `mul` 的音轨、只能通过压缩包访问的资源，以及一分钟内没有探测结果的资源。zurg 会记录它是按原样保留的。

评论音轨和音频描述音轨不计入影片的音频，评论字幕也不计入影片的字幕。这包括仅在标题中注明是评论的音轨，例如《寄生虫》的 "Commentary by Bong Joon Ho"。标题为 forced（forzados、forcés）、signs 或 songs 的字幕轨不计入字幕。仅有 forced 标记并不会排除某个音轨：外语电影的 remux 版本会把完整的英语字幕标记为 forced，好让播放器显示出来。

只判断资源的主视频文件，即时长至少为最长文件五分之一的文件。附加内容的配音通常比影片少。在整季合集中，每一集都必须有该语言。

因语言而被搁置的资源会被搁置 30 天，与失效帖子一样，即使你之后更改了语言设置也是如此。

## DMM 愿望清单 {#dmm-wanted-list}

DMM 赞助者在 debridmediamanager.com 页面上点击 **Want** 按钮，把电影和剧集加入想看列表，列表显示在 `/wanted` 页面。只要设置了 `dmm_api_key`，zurg 就会读取这个列表，不需要再写别的配置。不用挂载任何东西，也不涉及 Sonarr 或 Radarr。这个来源叫 `dmm-wanted`，每 60 秒轮询一次。

- **会抓取什么。** 电影会抓取一次，之后如有升级（见下文）也会抓取升级版本；如果 `quality` 是一个列表（见下文），则会按其中每个分辨率各抓一份。剧集会抓取所想季中已播出的集数；如果整部剧都想看，则抓取每一季已播出的集数；新集播出后也会继续抓取。DMM 会为每个标题发送 IMDb、TMDB 和 TVDB 的 ID、年份，剧集还会发送已播出的集数，编号与 TMDB 的一致。特别篇从不列出。正在播出的那一季会按零散单集抓取，因为还没有合集能覆盖它。
- **何时搜索。** 电影会在它首次上线家庭观看时开始搜索：如果 TMDB 知道它最早的数字版、实体版或电视播出日期，DMM 会发送那一天的日期，zurg 等到那一天才开始搜索，之后每两分钟搜索一次，持续六小时，然后每十分钟搜索一次，直到该日期后两天，这与[新集](#sonarr-behavior)的做法相同。绝不使用影院上映日期：WEB-DL 是随数字版一起发布的。剧集的最新一集也按同样方式定日期，如果 DMM 知道它的播出时间，就精确到播出的那个小时。没有日期的标题保持普通重试，间隔最长一周，列表上的内容永远不会被[暂停](#persistence-and-recovery)。等待下一次尝试的电影，会在下一次轮询时，如果 DMM 看到有新的 Usenet 帖子提到它，就立即搜索。
- **下载到哪里。** 与其他来源相同：来自 Newznab 索引器的 NZB 会进入本实例的 Usenet 后端，来自 Torznab 索引器的种子则会进入已经缓存了该资源的debrid账户，具体取决于 `prefer` 优先选哪一个。`quality`、`max_size_gb`（整季合集则按每集计算）、`exclude_words` 和[语言](#choosing-by-audio-and-subtitle-language)都会生效；如果你写了 `max_season_size_gb`，它也会生效。
- **索引器。** 如果没有在 `acquisition:`、`watchlist:` 或 `stremio:` 下写任何索引器，这个密钥还会搜索 DMM 自己的索引器：它的 Usenet 索引器，以及它知道 Real-Debrid 或 AllDebrid 已经有缓存的种子（`/api/torznab/cached`）。只要写了任何索引器，这两者都会被替换。
- **确认。** 电影的下载检查通过后，zurg 会告知 DMM，电影就会从 zurg 读取的列表中移除，除非它在等待升级或等待它的另一份副本（见下文）。`/wanted` 页面会显示这些状态。剧集会留在列表上，持续被跟踪，直到你在那里把它删除。删除标题后，zurg 就会停止处理它。
- **升级。** 如果电影的发布名称标明的分辨率低于 `quality` 所指向的分辨率（`best` 和 `4k` 为 2160p，`1080p` 为 1080p，`720p` 为 720p），它会留在列表上。一旦出现标明分辨率更高的发布版本，zurg 就会抓取它，直到持有该版本为止。当更好的副本通过检查后，如果旧副本是 zurg 抓取的，就会被删除，从 2026-10-30 的夜间任务起生效：对于种子，是 zurg 添加它的那个账户中的种子；对于 NZB，是监视目录中的 NZB。如果旧副本本来就是你的，则会保留；如果其中任何内容已被放到 `__magic__` 下（例如被 Radarr 导入），也会保留。发布名称中没有标明分辨率的版本永远不会升级，`quality: smallest` 也不会升级任何内容。在出现更好的发布版本之前，电影大约每周搜索一次，并且永远不会被[暂停](#persistence-and-recovery)。此功能默认开启；在 `acquisition:` 块中设置 `upgrades: false` 即可关闭。
- **多个分辨率各一份副本。** 当 `quality` 写成列表，例如 `[1080p, 4k]` 时，每部电影会保留其中每个分辨率各一份副本。参见[多个分辨率各一份副本](#a-copy-at-each-of-several-resolutions)。
- **没有抓取账户。** 如果实例没有 `nzb` 提供方、没有 `torbox_nzb` 账户（TorBox Pro），也没有支持种子的 debrid 账户，它就不会读取这个列表。

**同一个密钥下运行两个 zurg 时，两者都会抓取每个标题。** 两者读取的是同一个列表，所以请只在其中一个上运行想看列表，并在其他实例上将其设为禁用：

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

赞助过期或密钥被重置都会导致列表停止。zurg 会记录一条警告，说明 DMM 拒绝了 `dmm_api_key`，然后每小时重试一次；如果你设置了新密钥，则会立即重试。此前已经抓取的内容会保留在你的媒体库中。

### 每种分辨率各保留一份副本 {#a-copy-at-each-of-several-resolutions}

将 `quality` 写成列表，可以让愿望清单中的每部电影在其中的每种分辨率下都保留一份副本。例如，这样 1080p 电视播放时就不会因为 4K 文件需要转码而受影响：

```yaml
acquisition:
  quality: [1080p, 4k]
```

每份副本都只取不高于自身分辨率的最佳版本，绝不取高于它的版本。1080p 副本不会取 2160p 版本，也不会取名称中未标明分辨率的版本，因为那可能是任何分辨率。4K 副本只有在无法取到标明分辨率的版本时，才会取这类未标明分辨率的版本，并会一直保留，因为未标明分辨率的版本永远不会被升级。每份副本各自升级，最高升级到自身的分辨率。如果两份副本会取到同一个版本，它们就共用一份副本，只有两者都不再持有它时，这份副本才会被删除：

| 已发布的版本 | 1080p 副本 | 4K 副本 | 你的库中 |
|---|---|---|---|
| 720p | 该 720p | 同一个 720p | 该 720p |
| + 1080p | 升级为该 1080p | 升级为该 1080p | 该 1080p |
| + 2160p | 保持不变 | 升级为该 2160p | 该 1080p 和该 2160p |

只发布了 2160p 的电影会立即获得 4K 副本，等出现 1080p 或更低分辨率的版本时再获得 1080p 副本。在此之前，大约每周搜索一次，且绝不会被搁置。只有当每份副本都持有一个它不再希望升级的版本时，这部电影才会离开 zurg 读取的清单。

- **列表可以写什么。** 两个或更多的 `4k`（或 `2160p`）、`1080p` 和 `720p`，每个只能出现一次，顺序和大小写不限。写其他内容时 zurg 会拒绝启动，并提示 `acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`。只有一个值的列表会被当作该单个值处理，所以 `[1080p]` 等同于 `quality: 1080p`，只保留一份副本；如果想要 4K，就在这里写 `4k`，因为 `[2160p]` 会被拒绝。
- **只能写在 `acquisition:` 块中。** `watchlist:` 下的 `quality` 只能是一个值；在那里写列表会导致 zurg 无法启动。配置页面上的画质设置只会修改 `watchlist.quality`，当 `acquisition.quality` 已写入时，它不会产生任何影响。
- **只适用于 DMM 愿望清单上的电影。** 清单上的剧集以及所有其他来源仍然只获得一份副本，选择方式就像 `quality` 只列出了最高的那个分辨率：对它们来说，`[1080p, 4k]` 等同于 `quality: 4k`，`[720p, 1080p]` 等同于 `quality: 1080p`，后者在没有 1080p 版本发布时仍然会取 2160p 版本。
- **设置 `upgrades: false` 时**，每份副本都保留它取到的第一个版本。只发布了 720p 时，两份副本都会永久是这个 720p。
- **在你写入该列表之前已获取的电影**会重新获取，每种分辨率各一份副本。如果某份副本的最佳版本已经在你的库中，它就直接使用该版本。zurg 绝不会删除之前获取的副本：如果新副本替代了它，请自行删除。
- **改回单个值**时，现有副本保持不变。
- **一旦第一份副本入库，`/wanted` 就会将这部电影显示为已获取**，并显示 zurg 取到的第一个版本。它不会显示仍在等待哪种分辨率。在你写入该列表之前已获取的电影，可能会一直显示着当时所等待的分辨率的 "waiting for"（等待中）状态。

### 从 YouTube 串流一部电影 {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM 想看列表, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the 想看列表 takes a stream:
  a film the Plex 观看列表 also wants is not settled for it by one, since Plex cannot
  play it, and the 观看列表 keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one 想看列表 (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the 想看列表 while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## Seerr 的行为 {#seerr-behavior}

适配器遵循 seerr-team/seerr 的[请求路由](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts)、[状态定义](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)和[API 约定](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml)。

- 用 `X-Api-Key` 轮询所有页的已批准请求。某一页失败时，会保留之前的队列，并暂停该来源的工作。
- 获取前会再次检查批准状态。Pending、declined、failed、completed、removed 和已经可用的请求都不会触发抓取。
- 通过 Seerr 解析 ID。电视剧的获取只限于已批准的请求季，以及这些季中已知已播出的剧集。只有部分剧集的季会保持 pending。
- 4K 和非 4K 分开处理。1080p 的版本无法满足 4K 的请求。
- 成功获取后，每 30 分钟重新检查一次未完结的请求，找出请求季中新播出的剧集。未公布的剧集只有在出现在 Seerr 的元数据中后才会变成待办任务。
- 所有已知剧集都播出后，优先使用合集包。仍在播出的季使用单集。不支持特别篇（season 0）。如果批准的请求包含 season 0，就完全不会获取，并且会一直失败，直到它被 parked（暂停）为止。
- 不会对请求状态或可用性做任何写入。Seerr 的媒体服务器扫描会报告实际的可用性，并通知请求者。保存 NZB 并不能证明它已被索引或可播放，所以引擎会先检查，然后才把某一季计为已获取。

请把 Seerr 的媒体库扫描配置为包含本实例所服务的媒体库。如果 Sonarr/Radarr 已经在获取同样的请求，请先关闭这个重叠的工作流，再启用本适配器。适配器不会模拟 *arr 服务器，也不会改变 Seerr 的服务设置。轮询机制负责重启后的恢复，因此不需要 webhook。

## Radarr 的行为 {#radarr-behavior}

Radarr 保存片单，并管理媒体库。zurg 负责搜索和下载。Radarr 从不搜索，也从不抓取资源：zurg 读取 Radarr 想要的内容，从自己的索引器中挑选一个资源，用新闻服务器（`torbox_nzb` 账户下使用 TorBox 的获取功能）或持有该资源的 debrid 账户进行检查，然后把视频放进 `__magic__` 里对应电影的文件夹，并让 Radarr 只重新扫描这一部电影。没有任何内容被复制：视频只是 zurg 媒体库中的一个文件，Radarr 在它的文件夹里看到的就是这个文件。

### 设置 Radarr {#setting-up-radarr}

1. **Stammordner innerhalb von `__magic__`, eine Ebene tiefer.** Zum Beispiel
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` unter macOS,
   `Z:\__magic__\movies` unter Windows). Nicht `__magic__` selbst und nicht
   `__magic__/__all__`, denn dort sind alle Releases der Bibliothek aufgelistet. Ein Film,
   dessen Ordner woanders liegt, wird übersprungen, und zurg schreibt eine Warnung in das Log.
   Unter Windows sieht Radarr `Z:` nur, wenn es in derselben Anmeldesitzung läuft wie zurg, also nicht als Windows-Dienst: siehe
   [die Sitzungsregeln](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Importlisten mit Suche beim Hinzufügen deaktiviert.** Füge Filme hinzu, wie du willst (von Hand, über Listen, Seerr mit Verbindung zu Radarr). Lass **Search for Movie** beim Hinzufügen aus, denn die Suche übernimmt zurg.
3. **Keine Indexer und kein Download-Client nötig.** Hat Radarr welche, kann es parallel zu zurg Releases holen. Deshalb deaktivierst du die automatische Suche bei den Indexern (oder entfernst sie) für die Filme, um die sich zurg kümmert.
4. **`library_path` ist der Pfad, unter dem Radarr `__magic__` sieht.** Läuft Radarr auf demselben Rechner wie zurg und sieht den Mount an der Stelle, an der zurg ihn einbindet, lass die Option weg: Standardmäßig ist sie zurgs `mount_path` plus `/__magic__`. Läuft Radarr in einem Container, der zurg an einer anderen Stelle einbindet, setze den Pfad dorthin, zum Beispiel `/data/zurg/__magic__`. Ein Film unter `/data/zurg/__magic__/movies/Heat (1995)` wird dann in `movies/Heat (1995)` innerhalb von zurgs `__magic__` abgelegt. Windows-Pfade wie `Z:\__magic__` funktionieren ebenfalls. Ein Radarr-Container wird nur auf einem Linux-Host unterstützt: Docker Desktop unter macOS und Windows führt Container in einer VM aus, und das Durchreichen von zurgs Mount dorthin ist nicht getestet. Betreibe Radarr dort deshalb nativ.

   Nimmt Radarr außerdem Downloads über zurgs [SABnzbd](sonarr-radarr.md)- oder [qBittorrent](sonarr-radarr-torrents.md)-Endpunkt entgegen, muss es deren Download-Ordner unter `library_path/__all__` sehen, und zwar über dasselbe Volume wie seine Stammordner. Sonst ist jeder Import daraus eine Kopie der gesamten Datei. zurg fragt Radarr, wo es beide sieht, und meldet dies auf der Acquisition-Seite, im Log und in `zurg doctor`, falls sie sich kein Mount teilen können. Siehe dazu [Ein Volume für den Download-Ordner und die Stammordner](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### zurg 向 Radarr 请求什么 {#what-zurg-asks-radarr-for}

每次轮询都会读取 Radarr 的电影列表，并处理每一部符合以下条件的电影：已设为监控，已到最低可用性（minimum availability）所要求的时间，并且没有文件，或者文件质量低于其质量配置文件的截止线，且该配置文件允许升级。"低于截止线"指低于截止质量，或低于截止自定义格式分数，计算方式与 Radarr 相同。尚未上映的影片（比如几个月后才上映的电影）会一直等到 Radarr 表示它已可用。

zurg 即将检查的每个候选资源，都会交给 Radarr 自己的解析器（`/api/v3/parse`）处理，并按该电影的质量配置文件进行判断。因此，zurg 接受的资源就是 Radarr 也会接受的资源：

- **必须是同一部电影。** Radarr 必须把标题匹配到同一部电影。索引器的 ID 搜索会返回其他影片（搜索 *Psycho* 时返回了 *Ed Gein: The Real Psycho*），而无法匹配到任何电影的标题会被拒绝。标题中的年份与电影年份相差超过一年的，同样会被拒绝。
- **先应用配置文件的允许列表和最低分数。** 解析出的质量必须被该配置文件允许，自定义格式分数必须达到配置文件的最低要求，并且大小必须符合 **Settings > Quality** 中该质量对于这部电影片长的限制。
- **资源语言必须符合配置文件的设定。** 默认选项 **Original** 下，Radarr 必须把标题识别为影片本身的语言，因此某部英文电影的纯法语资源会被拒绝。标题中没有写明语言的，视为原始语言。标题写明了某种语言的，要求该语言；选择 **Any** 则接受所有语言。首次获取文件和升级时都适用这一规则。
- **升级会逐步朝截止线推进。** 没有文件的电影，会接受任何通过上述检查的资源。一旦它有了低于截止线的文件，就只接受更好的资源：文件质量低于截止质量时，接受配置文件排序中更高的质量；文件分数低于截止分数时，接受自定义格式分数更高（且至少高出配置文件的升级步长）的资源。更低的质量永远不会被接受。同一质量的 PROPER 和 REPACK 资源不算升级。

配置文件会作为允许列表应用于 zurg 即将获取的资源：正确的电影、允许的质量、最低分数、语言和大小限制。默认情况下，zurg 不会用配置文件的优先顺序在允许的资源中挑选。它会取第一个允许且检查成本最低的资源，并优先尝试网络资源（WEB-DL、WEBRip），然后是蓝光资源，最后才是其他资源，因为网络资源最常以单个视频文件的形式发布。如果配置文件偏好比到手的资源更好的质量，并且允许升级，那么 Radarr 会把电影的文件视为低于截止线，zurg 的升级流程会在电影有了文件之后寻找更好的资源。首个文件会很快到手，配置文件的优先顺序则通过升级来实现。如果希望首次获取也遵循配置文件的顺序，请设置 `best_first: true`。参见[让首次获取遵循配置文件的最优先顺序](#taking-the-profiles-best-first)。

当通过电影的 IMDb 或 TMDB ID 搜索完全没有结果时，zurg 会像 Radarr 一样，改用标题和年份重新搜索。很多帖子，尤其是小型纪录片，在索引中根本没有 ID。每个结果是否为该电影由 Radarr 的解析器决定，同名的其他影片同样会被拒绝。

只有当 zurg 即将检查某个资源时才会询问 Radarr，并且一次只询问一个资源，因此只含单个文件的资源会产生一到三次询问。直接帖子保存后就不再询问。如果标题中写明的分辨率在配置文件中没有对应的允许质量（例如 HD-1080p 配置文件收到 2160p 资源），该资源会被直接拒绝，无需询问 Radarr。标题中没有写明分辨率，或写明了多个分辨率的，始终会交给 Radarr 判断；配置文件允许的质量名称中不带分辨率（SDTV、DVD、Unknown、Raw-HD、BR-DISK）时，所有标题也都会交给 Radarr 判断。zurg 对同一个 Radarr 同时最多发出八个请求。

如果无法连接到 Radarr，则不会做出任何决定：电影会等到下一次轮询，并且不会因为 Radarr 没有响应而排除任何资源。

### 放置文件 {#placing-the-file}

一个资源检查通过后，zurg 会把它的视频放进电影的文件夹，方式和 Radarr 导入时一样，也就是移动到 `__magic__` 里面。什么都不会被复制或下载。

- **放进去的是最大的那个视频。** 也就是资源里（包括压缩包里面的内容）最大的 `.mkv`、`.mp4`、`.m4v`、`.avi`、`.mov` 或 `.ts` 文件。从单个压缩包里提供的资源，就以压缩包里的内容为准。如果一组 RAR 旁边还有散放的文件，比如一个带样片和 `.nfo` 的发布帖，那么它会被当作资源文件夹来浏览，视频从这个文件夹里取出放进去。样片、花絮、字幕和 `.nfo` 文件都留在 `__magic__/__all__` 里。文件保留它在资源中的原名，除非这个名字看不出是哪部电影（没有年份，也没有片名中的任何词），这时它会改成资源的名字，这样 Radarr 才能读出画质。
  - **样片永远不会被放进去。** 被识别为样片的视频（`sample-…`、`….sample.mkv`，或者放在 `Sample/` 文件夹里的）会被排除，不管它多大，除非资源本身的名字也带有 sample。如果片名里只是含有这个词的电影（比如 `Sample.Size.2019`、`Death.Proof.2007`），资源名里也会带着这个词，这种情况下只有当视频不到资源总大小的五分之一时才会被排除。如果资源里唯一的视频就是样片，包括只有样片的帖子，这个资源会被搁置，然后尝试下一个候选，这样升级就不会用一段一分钟的短片替换你原来的文件。
- **无法读取的文件会在移动前被拒绝。** 这是通过挂载进行 Sonarr 或 Radarr 导入时会做的检查。新闻服务器已经不再保存其文章的资源，或者压缩包永远无法打开，这类资源会像失效的帖子一样被搁置，然后尝试下一个候选。如果资源现在暂时读不了，比如所在账号正在冷却期，它会稍后再试。
- **Radarr 每部电影只保留一个文件，所以升级会替换旧文件。** 新视频放进文件夹后，zurg 库里放进去的其他视频都会从文件夹中隐藏。这里的隐藏和通过挂载删除一样，是打上墓碑标记：旧资源仍然保留在 `__all__` 里，账号上也仍然保留。你自己放进文件夹的真实文件不会被动。旧文件会在新文件放好之后才处理，所以如果放置失败，电影仍然保留原来的文件。
- **之后 Radarr 会重新扫描。** zurg 会告诉挂载哪些文件夹发生了变化，这样重新扫描时就不会读到挂载还记着是空的那个文件夹，然后 zurg 会请求 Radarr 只重新扫描这一部电影。

Radarr 源需要 `__magic__`（`magic.enabled`）。没有它的话，该源不会启动，日志和获取页面上都会说明这一点。

### Radarr 显示什么 {#what-radarr-shows}

**Activity** 保持为空：没有队列条目，也没有 grab 或 import 事件，因为 Radarr 并没有抓取任何东西。zurg 请求重新扫描之后，电影就直接有了文件，它的画质和自定义格式是 Radarr 对该文件的判断。zurg 的日志会记录它完成的每一部电影。

`only_new_items` 和 `remove_after_grab` 对 Radarr 来源不起作用。Radarr 想要的电影就相当于待办任务，跟 Seerr 已批准的请求一样，什么时候不再需要某部电影由 Radarr 决定。请保持来源的 `name` 不变：它用来标识已保存的队列，而 URL 和 key 可以随意修改。

## Sonarr 的行为 {#sonarr-behavior}

Sonarr 的工作方式和 Radarr 一样。Sonarr 负责维护清单，并管理媒体库。
zurg 负责搜索和下载。Sonarr 从不搜索，也从不抓取。zurg 会读取 Sonarr 缺失的剧集，并从它自己的索引器中挑选一个版本。它会通过新闻服务器（使用 `torbox_nzb` 账户时为 TorBox 的 fetch）或持有该文件的 debrid 账户来校验这个版本，然后把每集的视频放进 `__magic__` 里对应剧集的季文件夹中。接着，它会请 Sonarr 只重新扫描这一部剧集。整个过程不会复制任何文件。

### 设置 Sonarr {#setting-up-sonarr}

1. **根文件夹位于 `__magic__` 内，且只深一级。** 例如
   `/mnt/zurg/__magic__/tv`（macOS 上为 `/Volumes/Zurg/__magic__/tv`，Windows 上为 `Z:\__magic__\tv`）。文件夹不在该位置的剧集会被跳过，并在 zurg 的日志中输出一条警告。
   在 Windows 上，Sonarr 必须和 zurg 运行在同一个登录会话中，Radarr 也是如此。
2. **添加时关闭搜索。** 随意添加剧集即可，但请保持 **Start search for missing episodes** 关闭，因为搜索工作由 zurg 完成。
3. **不需要索引器，也不需要下载客户端。** 如果 Sonarr 已经配置了它们，它可能会与 zurg 一起抓取资源，因此请为 zurg 负责管理的剧集关闭其索引器的自动搜索。
4. **`library_path` 是 Sonarr 看到 `__magic__` 的路径。** 它的工作方式与 Radarr 完全相同，包括检查 Sonarr 能否通过同一个卷访问 zurg 的下载文件夹和根文件夹。如果 Sonarr 看到的挂载位置与 zurg 的挂载位置相同，则省略此项即可。

### zurg 向 Sonarr 请求什么 {#what-zurg-asks-sonarr-for}

每次轮询都会读取 Sonarr 的缺失剧集。这些是已经播出、已被监控、且还没有文件的被监控剧集。zurg 会按季把它们分组，把每一季当作一项任务来处理。

- **已经播完的整季可能会以季包的形式获取。** 当一季的每一集都缺失，且没有任何一集还没播出时，zurg 会先尝试季包。否则，这一季缺失的剧集会从该季的搜索结果中逐集获取。如果某一季已经有部分文件，就永远不会使用季包，否则文件夹里会出现这些剧集的第二份副本。
- **新播出的剧集是新任务。** 下周的剧集播出后，这一季会带着这一集重新出现在列表里。zurg 不会重新搜索它已经拥有的剧集。
- **新剧集会在几分钟内再次搜索。** 它的发布通常在播出后一小时内上传，所以刚播出时立即搜索往往找不到。剧集播出后的六小时内，zurg 每两分钟重试一次；之后每十分钟重试一次，直到播出两天后为止。再之后，它会像处理其他任务一样逐步退避（见[持久化与恢复](#persistence-and-recovery)）。在网盘账户上，发布还必须已经在该账户中缓存，因为 zurg 只会添加账户已经持有的内容。
- **被删除的剧集会重新获取。** 当 Sonarr 列出一个 zurg 已经获取过的剧集时，zurg 会检查该季的文件夹。如果这一集的视频已经不在那里，就会重新搜索。如果视频还在，说明 Sonarr 还没有重新扫描，因此不会进行搜索。
- **升级按文件判断。** 当配额配置文件允许升级时，低于截止线的剧集文件就算作可升级。"低于截止线"指低于截止画质，或低于截止自定义格式分数。Sonarr 自己的 Cutoff Unmet 列表只统计画质。在 Sonarr 4.0.20 上，画质已达到截止画质、但得分为 0（截止分数为 40）的文件不会出现在该列表中。zurg 两项都会统计，与 Sonarr 自己的升级规则一致。一个文件包含两集时，对这两集来说算作同一次升级。
- **每日节目的剧集按播出日期查找。** 这类发布以日期命名（`The.Daily.Show.2026.11.03.Min.Jin.Lee...`），索引器不会按集数查找，因此每个缺失的剧集还会以"剧名加日期"的文本形式搜索，即 `The Daily Show 2026.11.03`。Sonarr 的解析器会把日期转换回对应的剧集（S31E124），处理按季编号的标题时也是如此。
- **动画的剧集按作品自身的集数查找。** 字幕组发布使用从第一集开始的连续编号（`[SubsPlease] Jujutsu Kaisen - 30` 是第二季的第六集），因此每个缺失的剧集还会以"剧名加该编号"的文本形式搜索，即 `JUJUTSU KAISEN 30`。跨越整季编号的批量包（`(25-47)`）算作该季的季包。Sonarr 的解析器会结合该季的场景名称（`Jujutsu Kaisen 2nd Season`、`Jujutsu Kaisen S2`）把编号映射到剧集，因此无论标题用哪种编号，都会被判定为正确的剧集。无法匹配到任何剧集的发布（例如使用了 Sonarr 不认识的场景名称）会像其他发布一样被拒绝。
- **特别篇为第 0 季。** Sonarr 中被监控的特别篇会像其他季一样列出，并以季号 `00` 请求（请求季号 `0` 时索引器会返回另一季的内容）。只有标明 `S00Exx` 的发布才能匹配：仅用标题命名的特别篇会解析为空，Sonarr 也是如此。它们会被放入 Sonarr 的 **Specials Folder Format** 所指定的文件夹。

每个候选发布都会交给 Sonarr 自己的解析器（`/api/v3/parse`），并按剧集的画质配置文件进行判断。zurg 接受的内容，就是 Sonarr 也会接受的内容。

- **必须是该剧集的该季。** Sonarr 必须把标题匹配到同一部剧集。无法匹配到任何剧集的标题会被拒绝，除非该剧集不使用场景编号，并且 Sonarr 自己的剧集查找首先通过标题中的名称找到了这部剧集（例如外语标题）。
- **季包必须是整季。** 不完整的季包会被拒绝。写成范围的季包（如 `Season 1 E01-E07`）只要范围就是整季，就会被接受。包含多季的季包会分别对其中的每一季计算（见[多季季包](#packs-of-several-seasons)）。Sonarr 会把 `S01-S05` 只读作第 1 季，而且从不说明范围在哪里结束，因此 zurg 会从标题中读取范围。Sonarr 仍然必须把它匹配到该剧集，并将其识别为完整的多季季包。它的大小则按所包含的每一季的时长来判断。
- **剧集必须只包含这一集。** 包含两集的发布会被拒绝，不能用作单集。
- **配置文件的规则与 Radarr 相同。** 画质必须被允许。自定义格式分数必须达到配置文件的最低要求。大小必须符合 **Settings > Quality** 中该画质的限制，并按发布所含剧集的时长计算。升级必须按 Sonarr 的规则超过当前文件。Sonarr 的配置文件没有语言设置，因此语言只能通过自定义格式的分数体现，这与 Sonarr 中的做法一致。

在允许的发布中，哪一个优先，与 Radarr 的处理方式不同。季包会先于零散剧集尝试，因为一次获取季包就能拿到多集，而零散剧集需要多次获取。在 Sonarr 允许的发布中，zurg 会选择其 `quality` 设置排在第一位的那个。设为 `best` 时，先比较分辨率，再比较大小，也就是按季包中每集的内容量来排序。因此，即使同一搜索结果中每一集都有 2160p 版本，一个已经播完的整季只要有 1080p 季包，就会先用该季包来补全。之后的升级流程会逐集替换这些文件。超过 `max_size_gb`（每集）或你设置的 `max_season_size_gb`（每季）的季包，永远不会成为候选。`best_first: true` 会同时改变这两点。参见[优先采用配置文件的最佳项](#taking-the-profiles-best-first)。

如果标题中的分辨率在配置文件里没有允许的画质，该发布会在不询问 Sonarr 的情况下直接被拒绝。zurg 对同一个 Sonarr 同时最多发起八个请求。如果无法连接 Sonarr，则不做任何决定：该季等待下一次轮询，且不会放弃任何发布。

### 放置文件 {#placing-the-files}

一个版本检查过之后，每一集的视频会放进季文件夹。这就是该季已有文件所在的文件夹。如果某季还没有任何文件，则使用 Sonarr 的 **Season Folder Format** 所定义的文件夹，例如 `Season 1`。设置为不使用季文件夹的剧集，文件会放进剧集文件夹。

- **每一集都有自己的视频。** 视频通过文件名中的集数来查找，包括版本压缩包内的文件。一个合集会放置它所对应的每一集。样片和 `.nfo` 文件保留在 `__magic__/__all__` 中，样片永远不会被当作某一集放置。
- **缺少某一集的合集会在移动任何文件之前被拒绝。** 它会像失效的帖子一样被搁置，然后尝试下一个合集或零散的单集。
- **文件名里找不到集数的零散单集，会拿到该版本中最大的视频。** 经过混淆的帖子经常是这种情况。
- **动画或每日节目的视频会放在剧集和集数之下。** 重新扫描时只看文件名，不知道场景编号。比如剧集文件夹里的 `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` 会被导入为 S01E08，而 Sonarr 的解析器会把同样的标题读成 S02E08。因此视频会被放置为 `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv`，这样导入就是正确的。原文件名保留在集数之后，Sonarr 仍能读取它的画质和发布组。普通剧集和特别篇的视频保留原名，因为原名里已经有集数了。
- **升级只替换它自己的那一集。** 新视频放好之后，该集的旧视频会从季文件夹中隐藏，即标记为 tombstoned，Radarr 也是这样处理的。文件夹里的其他集不受影响。
- **之后 Sonarr 会重新扫描。** zurg 会告诉挂载点哪些文件夹有变化，并请求 Sonarr 重新扫描该剧集。
- **缺一集不会拖累其他集。** 当某一集暂时没有 zurg 可以获取的版本时，已经找到的其他集仍会被检查和放置。Sonarr 会立即被要求为这些集重新扫描。缺的那一集会按平时的重试计划再次查找。

Sonarr 来源需要启用 `__magic__`（`magic.enabled`）。没有它，该来源将无法启动，并会在日志和获取页面上说明原因。

与 Radarr 一样，Sonarr 中的 **Activity** 会保持为空。在 zurg 请求的重新扫描完成之后，这些集就会直接有文件。`only_new_items` 和 `remove_after_grab` 对 Sonarr 来源不起作用。

## 多季合集 {#packs-of-several-seasons}

一季可以从包含多季的合集中获取，比如
`Game.of.Thrones.S01-08.BDRip.1080p` 或 `Breaking Bad Season 1-5`。索引站会把这类合集归到它涵盖的每一季下面。在 DMM 的 feed 中，Breaking Bad 第 3 季的 691 个结果里有 72 个是多季合集。对某些季来说，账户里只有其中一个合集这一份副本。

- **标题会说明包含哪些季。** `S01-S05`、`S01-05`、`[S01-08]`、`S1-9`、`Seasons 1-8`、`Season 1 to 5`、`Season 1 · 2 · 3`、`Stagioni 01-05` 和 `Temporadas 1-4` 都能识别。没有季号的标题，比如 `Complete Series`，不会被采用。只把单个季以文字形式提到的标题，比如 `Season 3 Complete`，也不采用。这些标题从来不会被当作合集读取。
- **只放入该季。** 为第 4 季获取的合集，只会把第 4 季的集放进季文件夹。其他季的文件保留在媒体库列出的位置。如果合集的文件并未包含该季的每一集，无论标题怎么写，都会在移动任何文件之前被拒绝。
- **大小按每集计算。** 合集的大小先除以它所包含的季数，再除以该季的集数，然后和 `max_size_gb` 比较，就像同一个版本逐集发布时那样。一个 346 GB、包含八个 10 集季的合集，每集 4.3 GB。I Love Lucy 第 2 季 31 集的 remux 为 106 GiB，每集 3.4 GiB，在你设定的 40 之内。如果来源没有列出该季的集数，则这类合集不设每集上限。你写的 `max_season_size_gb` 会额外限制合集中包含的每一季，默认没有此限制。
- **画质仍然优先。** 合集和其他发布版本的排序方式一样：先看分辨率，再看每集的内容量，与 DMM 季页面的排序一致。一个 2160p 的单季合集会优先于 1080p 的八季合集。在同一分辨率下，某一季自己的 remux 会排在总体更大、但每集更小的八季合集之前。
- **同一部剧的其他季使用同一个合集。** 一旦某一季拿到了多季合集，这部剧的其他季会先尝试这个合集，排在它们自己搜索到的同分辨率其他合集之前。它已经在账户里，所以不花费任何额外成本。当某部剧的季在多季合集之间做选择时，它们会一次选一个，因此一起请求的季（例如一个 Sonarr 剧集的所有季在同一次轮询中被请求）不会各自选中不同的副本。一旦其中某一季在没有这类合集的情况下做出了选择（因为账户里没有，或配置不允许），其余的季就会同时选择。一小时后请求的季会重新搜索。

## 观看运行效果 {#watching-it-work}

仪表盘上的 **Acquisition** 链接会在 zurg 自己的端口上打开 `/acquisition/`。
每个来源占一行，显示其中有多少条标题已完成、运行中、等待中、已搁置和排队中，同时显示 zurg 同时处理的标题数、同时向单个索引器发出的请求数，以及其 `nzb` 账户允许的新闻服务器连接数。
在这一行下方，每个来源都有一张表，每条标题一行。
每一行显示状态。对于运行中的标题，还会显示它此刻正在做什么（搜索、到目前为止已有多少结果被判定并放行、正在检查的候选项、与新闻服务器的核对、放置）。此外还显示其尝试次数、所选的发布版本及来源给出的质量和评分、放置位置，以及等待中的标题下次何时尝试。
没有可再尝试的发布版本的标题会说明原因，并按规则统计来源的拒绝次数：`14 refused by the source's own rules
(title mismatch 7, quality 5, size 2)`。
因分辨率被拒绝、且未询问来源的发布版本，计入 quality 之下。
页面每五秒自动刷新一次。
同一份快照位于 `/acquisition/status.json`，其中该原因即标题的 `detail` 字段。
当没有启用任何来源，或已配置获取但处于暂停状态时，页面会说明情况及原因。

每部为其选中发布版本的电影，都会在日志中输出一行，用于衡量时间花在哪里：

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` 是搜索返回的结果数，`local_refusals` 是未询问来源就被拒绝的结果数，`radarr_refusals` 是来源自身规则拒绝的结果数，`inspected` 是读取的 NZB 数，`radarr_calls` 是向来源提出的询问次数（即读取的 NZB 数加上途中被拒绝的次数，当来源为 Radarr 时），耗时从搜索开始时计算。未询问就被拒绝的发布版本仅在 debug 级别逐条记录。

## 检查仅将 zurg 作为下载客户端的 \*arr {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

A Sonarr or Radarr pointed at zurg's [SABnzbd](sonarr-radarr.md) or
[qBittorrent](sonarr-radarr-torrents.md) endpoint does its own searching, so it does not
need a source here. zurg still wants its API key, because three of its settings
decide whether every import is a free rename or a whole release downloaded
from the debrid account and written to zurg's disk: Remove Completed on a
qBittorrent client, the download folder and the root folders on one volume,
and root folders inside `__magic__`. With the key, zurg turns Remove Completed
on by itself (see [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
and warns about the other two. See
[One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

The easiest way to give zurg the key is the banner on the main dashboard,
described below. Or add it as a source that is switched off:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

A Radarr or Sonarr source with `enabled: false` acquires nothing. zurg never
reads its wanted list and never searches for it. With its `url` and `api_key`
set, and one of the two endpoints on, zurg only reads the \*arr's root folders,
remote path mappings and download clients, at start, every ten minutes and as
soon as the \*arr first calls one of the endpoints. It turns Remove Completed
on for the \*arr's zurg qBittorrent client when it is off, the one change zurg
makes, and reports a layout that makes imports copies. Every source with a URL
and an API key, enabled or not, is checked and corrected the same way. It is
listed on the acquisition page under **Checked, never searched for**, with
what zurg changed, the findings go to the log, and `zurg doctor` shows them as
`imports (<name>)`. `library_path` is not judged for such a source, since
nothing is placed for it. A source added to config.yml by hand is read at
start, so restart zurg after adding one that way.

zurg also notices a Sonarr or Radarr it cannot check. Both send their name in
every request to the endpoints (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), so zurg
records which ones call it and from which address. When one calls and no
source of its kind has a URL and an API key, zurg logs one warning, `zurg
doctor` reports it on its `*arr settings` line, and the main dashboard shows a
banner with a form for its URL and API key. The URL is filled in with a guess:
the address the \*arr calls from, on its default port (8989 for Sonarr, 7878
for Radarr). That address is often a container's own, which zurg may or may
not reach, so change it to whatever URL reaches the \*arr from where zurg
runs. The API key is in the \*arr under Settings, General, Security. zurg
first asks the \*arr for its status with that key, and saves nothing unless it
answers as the app it was named as. It then adds the source above to
config.yml with `enabled: false`, keeping everything else in the file as it
was, and checks it straight away, with no restart. The form shows what zurg
found and changed. The key is written to config.yml and sent to the \*arr, and
nowhere else.

The banner matches by kind, not by address: an \*arr calls zurg from inside
its container, on an address that has nothing to do with the URL zurg reaches
it on, so one Sonarr source with a key silences the banner for every Sonarr.

## 查找重复版本 {#finding-duplicate-releases}

**升级后,被替换的版本仍会留在你的库里。** 当 `magic.allow_delete` 关闭时,Radarr 或 Sonarr 删除旧文件只会把它隐藏在 `__magic__` 里,所以旧版本仍留在 `__all__` 中,也仍在你的账号上。从多个索引器抓取,或者整季合集旁边还有单集,同样会留下多个同一内容的版本。**Manage > Duplicates**(`/manage/duplicates/`)会列出这些版本,告诉你 Radarr 或 Sonarr 正在使用哪一个,并让你删除其他版本。它不会自己删除任何东西。

**正在使用的版本是通过路径而不是名称判断的。** Radarr 和 Sonarr 持有的每个文件都用 `__magic__` 下的一个路径来标识,而 zurg 知道每个路径来自哪个版本,因为把文件移到那里的操作会记下这一点。该视图会读取每个 \*arr 已导入的每个文件(无论是否受监控、是否达到截止标准),并把每个文件追溯到其版本。Sonarr 的文件是逐集追溯的,所以如果 Sonarr 从一个整季合集中取了三集,这三集会显示为正在使用该合集。

**哪些版本可能是副本只是推测,页面也会这样标明。** 满足以下任一条件时,版本会与某部电影或某一季归为一组:

- 某个 \*arr 文件在其中,
- \*arr 的历史记录显示它从这些版本导入过文件,或删除过来自这些版本的文件(升级、手动删除,或文件从磁盘上消失),
- zurg 将它们识别为该电影或剧集的 IMDb id,或
- 它们的名称符合片名和年份(年份相差一年,或 Radarr 记录的第二个年份,仍然算数),或符合剧集名和季数。

每个版本都会列出是哪些条件把它归入该组。只有当多个版本包含相同的集时,一整季才会成为一个组:同一季的六十个单集版本,是六十个不同的集。整季组会列出被多个版本共同包含的集、每集由哪些版本包含、Sonarr 的文件在哪个版本中,以及每个版本独有的集数(即组内其他版本都不包含的集)。页面不会选出一个胜出的版本。没有任何 Radarr 或 Sonarr 条目与之匹配的版本,会列在 **Name matches only** 下,按它们的名称和 IMDb id 分组。

**每个版本的状态为 In use、No reference found 或 Unknown 之一。**

| 状态 | 含义 |
|---|---|
| In use | Radarr 或 Sonarr 当前持有的某个文件在该版本中。该版本无法被选中。 |
| No reference found | 所有已配置的 Radarr 和 Sonarr 都已完整读取,且它们的文件都不在该版本中。Plex、Jellyfin 及其他读取挂载的客户端在这里是看不到的,所以这并不能证明没有任何东西在播放它。 |
| Unknown | zurg 无法判断。只要有某个 \*arr 无法读取、库仍在加载中,或 `__magic__` 关闭,所有版本都会显示为 Unknown。当同一部电影或同一集的某个 \*arr 文件无法追溯到任何版本时,该版本也会显示为 Unknown;当 \*arr 的历史记录显示该版本的某个文件已从磁盘上消失,并且此后这部电影或这一集再没有文件时,该版本同样显示为 Unknown。 |

**画质按质量配置文件的标准显示。** 对于 \*arr 正在使用的版本,显示的是 \*arr 自己给该文件的评级。对于它之前导入过的版本,显示的是当时给出的评级。其他情况则从版本名称中读取,并会注明这一点。每个评级都会放入该条目的质量配置文件中,例如 "rank 15 of 17 in 4K or best available (cutoff at 17)"。

**删除前会先重新读取。** 选中版本后点击 **Check again and delete**。zurg 会重新读取每个 \*arr 当前的文件,然后才提供删除选项。页面加载后才开始被使用的版本会被排除在外;Unknown 的版本只有在该对话框中再次勾选后才会被删除。真正的删除操作是管理页面的批量删除,它会从所有持有该版本的账号中删除该版本的每个副本。

**什么时候读取。** 首次打开页面时,会读取 `acquisition.sources` 下的每个 Radarr 和 Sonarr,包括导入和删除历史。读取大型库的历史可能需要一分钟。之后页面会显示上次读取的内容和时间,直到你点击 **Read Radarr and Sonarr again**。`enabled: false` 的来源仍会被读取:关闭 acquisition 并不会改变该 \*arr 持有的内容。页面会显示每个来源的计数:已读取的文件数、已追溯到版本的文件数、位于其 `library_path` 之外的路径上的文件数,以及位于 `__magic__` 内但指向不存在内容的文件数。如果某个来源的文件一个都没有追溯到版本,请检查它的 `library_path`。

同样的报告也位于 `/manage/duplicates/report.json`,而 `POST /manage/duplicates/check` 配合 `{"hashes": [...]}` 会重新读取 \*arr,并返回每个版本的状态。

## Newznab 和 Torznab {#newznab-and-torznab}

索引器条目用 `type` 标明自己的类型。没有这个字段时按 `newznab` 处理,这也是这个字段出现之前写的所有条目的含义。两种类型的查询完全相同,但返回的结果不同。Newznab 的结果是一个 NZB,会被获取后写入 `nzbs/`,交给 Usenet 后端使用。Torznab 的结果是一个信息哈希,会交给一个 debrid 账户。如果 Torznab 结果里既没有磁力链接,也没有 `infohash` 属性,就会被跳过。zurg 从不下载 `.torrent` 文件,所以只能通过它才能拿到的结果,zurg 无法处理。

**种子只会添加到已经持有该内容的账户。** 每个允许添加的账户都会收到这个哈希,但有一种例外:如果某个 Real-Debrid 账户直接拒绝某个发布名称,就跳过它。原因是各个缓存彼此独立,一个账户清除了某个发布,并不代表下一个账户也没有。第一个已经持有该内容的账户会接手。在所有账户里都没找到时,这只是一次普通的候选失败,遍历会顺着排名移到下一个发布,下一个可能是另一个种子,也可能是一个 NZB。

在 TorBox 和 Debrid-Link 上,未命中时不会添加任何东西。在 AllDebrid 和 Offcloud 上,未命中的种子会立即被删除。Real-Debrid 和 Premiumize 会先把种子添加进去,然后最多监视 20 秒。已缓存的内容通常一两秒内就能就绪。超过这个时间仍在下载的,会被再次移除。因此账户上不会留下任何正在运行的下载。不过未命中也不是完全没有代价:它仍然可能占用账户的添加次数限制。在 TorBox 上,每次未命中会占用每小时 60 次未缓存添加中的一次。

标记为 `watchlist: true` 的账户会最先收到种子。其余账户按照 `providers:` 列表中的顺序依次尝试。标记为 `add_torrents: false` 的账户则永远不会收到种子。

`prefer` 决定当两种结果都能满足同一目标分辨率时,优先尝试哪一种。分辨率始终优先:一个账户已经持有的 2160p 种子,会先于 1080p 的 NZB 被选中,不管 `prefer` 怎么设置。`usenet` 是默认值,因为获取 Usenet 资源只消耗一次下载,而种子会占用账户的一个添加名额。`torrents` 则反过来。`best` 不区分两者,直接按排名取第一个,在同一分辨率内取体积更大的发布。

一部电影每次尝试最多试三个种子,每个种子都会消耗一次添加。它的 NZB 最多会逐个检查 24 个,具体说明见[选择电影的版本](#choosing-a-movies-release)。使用 `usenet` 时,某个分辨率的 NZB 会排在该分辨率的种子之前尝试。使用 `torrents` 时,种子排在前面。使用 `best` 时,每个种子按排名依次轮到。某个分辨率的 NZB 会在其中最好的那个所在的位置一起尝试。如果来源是 Radarr,所有分辨率的 NZB 会在其中最好的那个所在的位置一起尝试,并按成本从低到高排序,具体见该章节的说明。一季合集每次尝试会试三个发布,无论哪种类型。单集也一样。

发布的验证方式取决于来源。Usenet 发布需要到新闻服务器上查询,这是确认帖子是否还在的唯一方法。`torbox_nzb` 账户没有可以查询的新闻服务器,所以抓取结果会通过 TorBox 是否已经获取该 NZB 来检查。种子之所以被添加,是因为账户已经声明持有该内容,所以剩下要确认的只是这个发布是否已经进入媒体库并包含文件。检查的正是这一点。如果账户列出的发布是空的,就会像失效的帖子一样被弃用。

如果安装环境中没有 NZB 账户(`nzb` 或 `torbox_nzb`),它仍然可以只靠 Torznab 索引器运行获取任务。这种情况下,Newznab 索引器不会被搜索,因为该安装环境中没有任何东西能播放 NZB。日志会针对每个这样的索引器说明一次。如果安装环境中没有能接收种子的账户,它也不会搜索 Torznab 索引器,处理方式相同。无论哪种情况,安装环境无处存放的发布类型都永远不会成为候选,因此不会占用尝试中的发布名额,Radarr 等来源也永远不会被询问这类发布。

### 索引器限制与被拒绝的密钥 {#indexer-limits-and-refused-keys}

**zurg 不会撞上 DMM 的限制，而是主动避开它。** DMM 允许赞助者的 key 每分钟在其所有种子 feed 上共 20 次搜索，因此 zurg 向 DMM 发出搜索的频率最多为每三秒一次。超出的搜索会排队等待，等待并不算搜索失败。如果某次搜索的轮到时间晚于其标题的尝试结束时间，或者晚于两分钟以上，则不会发出该搜索，标题会直接使用其他索引器找到的结果继续处理。

**返回 429 或 503 的索引器会在其要求的时间内被暂停访问。** 每次搜索、NZB 下载和能力检查都会等待其 `Retry-After` 时间，最长两分钟，包括已经在排队等待轮次的请求。要求等待更长时间的索引器，会在那之前不再被请求。

**同一个 DMM key 下的多个 zurg 共享其 20 次搜索额度。** 每个 zurg 都会遵守整个额度的限制，因此同一个 key 下放两三个 zurg 仍然可能撞上 DMM 的限制。每次被拒绝后，该 zurg 的 DMM 搜索会暂停一分钟。这样一来，某个标题的搜索和抓取可能需要等待更长时间。

**被拒绝的 key 会暂停使用一小时。** 如果索引器返回错误 100（key 错误）或 101（账户已暂停，这是 DMM 在赞助已过期时返回的错误），则在一小时内不会再次请求，搜索和 NZB 下载都一样。日志只会记录一次，例如 `DMM torrents refused the API key: check dmm_api_key`，并且获取页面的 **Indexers not asked now** 下会列出该索引器。在 `config.yml` 中更改 key 后，会立即重新请求。其他任何错误只影响当次搜索。

## 选择电影的版本 {#choosing-a-movies-release}

电影的 Usenet 候选资源会按确认它们所需的成本来尝试，而不只是按质量好坏排序。只包含一个命名视频的帖子，zurg 只需读取两次文章，通常也是完整的。而一个四十卷的压缩包，则需要在每一卷的首尾各做一次检查和读取，而且索引站上大约三分之二的多卷 remux 套装已经失效。索引站自己的 `files` 计数可以预测帖子的结构，因此候选资源按它排序：十个文件或更少，然后最多三十个，然后更多，最后是未知，每一组内再按数量排序。在成本相同的帖子之间，如果 Radarr 这类来源会根据它自己的配置文件判断发布版本，那么标题中含 WEB-DL 或 WEBRip 的排第一，然后是 Blu-ray，其余的排最后，每一组内较大的帖子优先。来源自己的排名不在这里使用，因为只有询问来源才能得知，而 zurg 只在即将检查某个发布版本时才会去询问。没有来源时，先按质量排名，再按大小。若没有任何来源对候选资源做判断，则 `quality` 设置所要求的分辨率优先于成本，因此设为 `best` 的观察列表仍会在可用的资源中取得最佳分辨率，同一分辨率内最便宜的帖子优先。标题为拆分帖子其中一部分的结果（`[1/9] "Movie.part1.rar"`）永远不会成为候选。同名的两个帖子中只保留文件较少的那个，因为资料库只能容纳其中一个。

之后最多检查 24 个候选：每个 NZB 都会被获取，并由 zurg 自己的解析器读取。若一个帖子最多包含两个内容文件，其中一个是有名字的视频（`.mkv`、`.mp4`、`.m4v`、`.avi`、`.mov` 或 `.ts`），且大小至少 500 MB，它就是直接帖子。PAR2 卷以及 `.nfo`、`.sfv`、`.srr`、`.nzb`、图片、`.txt`、`.url` 和 `.exe` 等附属文件都不算内容。第一个直接帖子会立即保存。压缩包帖子会被暂时搁置，直到当前可见的直接帖子用完，然后按卷数从少到多尝试，并通过一个闸门控制，同一时间最多只有六个压缩包发布版本在新闻服务器上等待。只包含修复数据和附属文件的帖子永远不会被保存。已检查过的 NZB 会保存在内存中，因此当一个已保存的发布版本被发现已失效、标题再次尝试时，无需重新获取之前的 NZB，就能直接取得下一个候选。搜索和 NZB 下载共享每个索引站的同时进行请求数量限制。如果索引站返回 `429` 或 `503`，会在暂停后重新请求，并遵守其 `Retry-After`。仪表板会显示每一步：搜索、正在检查哪个候选，以及保存了什么。剧集使用前面所述的流程：排名最靠前、且未被搁置的三个发布版本。当来源（如 Sonarr）会判断发布版本时，每个版本都会先交给它判断，被它拒绝的版本不计入这三个名额。`best_first` 会按下一节所述改变两轮遍历的顺序。

## 优先采用配置文件中最好的版本 {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

默认关闭。开启后，Radarr 或 Sonarr 来源的首次抓取会按质量配置文件的偏好顺序进行，而不再按检查每个版本的成本来排序。Plex 观看列表和 Seerr 没有配置文件，不受影响。获取页面会显示它是否已开启。

- **配置文件中最好的分辨率排在最前。** 每个版本根据其标题中标明的分辨率排位。其位次由配置文件在该分辨率下允许的最佳质量决定。zurg 直接读取它已有的配置文件，不会再向 Radarr 和 Sonarr 额外询问。同一分辨率下的 WEB-DL、Blu-ray 和 remux 共享同一位次。在同一位次内，电影仍然选择检查成本最低的版本。剧集则选择 `quality` 排在最前的那个。标题中没有写明分辨率的版本排在最后。
- **截止质量视为最高。** 只要配置文件允许升级，所有不低于截止质量的版本都与截止质量同等对待。升级流程永远不会替换其中任何一个。如果配置文件升级到 WEB 1080p 为止，那么即使它也允许 2160p，开启"最好优先"也没有任何好处。不允许升级的配置文件则保留完整的顺序，它的第一个文件就是最终保留的那个。
- **沿着配置文件向下回退。** 如果某个版本的 NZB 无法获取或读取，就直接跳过。新闻服务器拒绝的版本照旧搁置。接着尝试配置文件顺序中的下一个版本。无论位次如何，单次尝试总共最多只读取 24 个 NZB。
- **优先级高于 Usenet 或 torrent 的偏好设置。** 如果某个账户已经持有一个 torrent，它会先于位次较低的 NZB 被选中。若两者位次相同，仍由 `prefer` 决定选 NZB 还是 torrent。
- **季包的质量必须不低于单集。** 如果在同一次搜索中，某个季包的排位低于一个单集，该季包就会被跳过，改为逐集获取。Sonarr 也是这样处理的。比较仅限于那一次搜索，不会为了查找是否有更好的版本而单独再次搜索某一集。

这样做也有代价。2160p 配置文件的顶部大多是 remux 和 Blu-ray 合集，常常有四十卷或更多，而不是单个视频文件。这类合集检查起来更耗时，更容易已从新闻服务器上消失，还要在归档闸门排队等候。因此第一个文件通常会来得更晚。如果某个标题的最佳版本全都已经消失，那么每个版本都会被抓取、检查，然后搁置，之后 zurg 才会沿配置文件向下移动。以单集形式获取的整季，会比一个季包多出几次抓取。它节省的是第二次抓取。已达到截止质量的第一个文件永远不会被升级。

## 获取操作对来源自身列表的影响 {#what-acquiring-does-to-the-sources-own-list}

观看列表 (Plex watchlist) 是有人整理出来的列表，它是唯一能说明对方想看某部影片的记录。Plex 不会保留已移除条目的历史记录。

两个设置决定 zurg 可以对它做什么。两者都适用于 `plex_watchlist` 源。Seerr 和 Radarr 源没有 zurg 会写入的列表，所以这两个设置在那里不起作用。

`remove_after_grab`（默认 `true`）会在其背后的版本被检查后，把已获取的影片从观看列表中移除。这一直是该功能的原有行为：观看列表被当作待获取的队列来读取，zurg 已经获取到的影片就算处理完了。把它设为 `false`，观看列表就保持为观看列表，成为一个可以随时浏览的持久列表。zurg 会在后台满足其中的条目，但不会修改列表。保留某部影片不会带来重新检查的成本：已有的回执已经覆盖它，因此不会再次向索引器询问它。

zurg 没有为其获取到任何内容的影片，无论此设置如何，都会留在观看列表中。如果用于确定该影片的所有版本都已经在库中（无论是你自己的副本，还是其他请求带进来的），也就是说没有获取或添加任何内容，那么移除它只会修改你的列表。这些版本仍会被检查，该影片仍算作已完成，因此只要它还在列表中，就不会再次搜索。你把它移除后再重新添加，它同样会留在列表中。zurg 获取过任一季或任一集的剧集，就算它获取到了，并且照旧移除。

`only_new_items`（默认 `true`）会在源第一次运行时接管列表中已有的所有内容，之后只处理新添加的条目。启用该功能应当是开始监视一个列表，而不是花一个晚上把上面的所有内容都处理一遍。设为 `false`，则把现有列表视为待处理的积压。

它**只在源第一次运行时生效一次**。已经有队列的源说明已经在运行过，记录它已做和未做事项的是那个队列，而不是这个开关。因此之后再打开它，绝不会丢掉正在处理中的积压。

被接管的影片只要还在列表中，就一直保持被接管状态。把它移除后再重新添加，则是一次普通的新请求。

## 验证抓取结果 {#verifying-a-grab}

保存下来的 NZB 不等于可用的发布。索引器有回应、回应能解析成 NZB、文件也进了 `nzbs/`，这些都只说明索引器那边的情况，不说明这个帖子本身能不能用。所以每个获取到的 NZB 在引擎确认请求之前，都会先拿去问一遍已配置的新闻服务器账号。每个内容文件的前 16 篇文章和最后一篇，都会用 `STAT` 查询。每个文件的第一篇文章，再加上文件较少的发布中的几篇，会被整篇抓取（最多 64 篇），因为新闻服务器可能对已经下架的文章也回应 `STAT`。`STAT` 拒绝的文章，在判定为没有之前也会被整篇抓取一次，因为新闻服务器也可能对仍然提供的文章拒绝 `STAT`（NewsDemon 在 2026-10-21 就这样）。每个发布最多有 16 篇这样的文章。这和 `/api?mode=addfile` 为 Sonarr 和 Radarr 做的检查是同一套流程。结果分三种，把它们分开很关键：

- **文章没有了。** 这次抓取不算数。收据重新打开，目标重新变回待获取状态，这个发布被记为失效 30 天，这样下一次尝试会排到下一个候选，而不是又选中已经在库里的那个。在这个名单上的发布不算候选：不会被抓取，也不占用一次尝试里的候选名额，所以排在前面的一串失效帖子会被依次跳过，而不会把后面的全部挡在外面。失效的整季合集会让整季重新变回待获取；零散的单集则照常获取。如果 NZB 获取是 zurg 自己保存的，就会从监视目录里删除，这样重启之后，在库打开前不会再次加载和检查它。已经在监视目录或库里的 NZB，以及 Sonarr 或 Radarr 导入过的 NZB，都保留在原处。
- **无法询问账号。** 比如池子宕机、账号被限流，或者最普通的情况：库里还没有列出这个新 NZB。这时什么都没确定，所以也不做任何决定：请求会在 20 秒后重新检查，然后是 40 秒、80 秒，之后每两分钟一次，而且等待不消耗任何重试次数。检查只是单纯超时，这种情况不算在内：它会立即用完整时间重新开始，最多三次，之后才进入等待。这个时间是五分钟，但如果发布文件很多而账号连接数很少，时间会更长。zurg 会根据这两个数值、检查过程中测得的最慢速度，以及同时运行的六个检查来算出时间，然后再翻倍。比如一个 90 卷的发布、用 4 个连接，大约需要 53 分钟。以前五分钟每次都会用完，最后这个发布只能未经检查就被搁置。两小时内二十次检查都无法确定结果，这个发布会像失效的一样被搁置，下一次尝试就换一个发布。请求绝不会在无人能检查的发布上被确认。
- **发布是可用的。** 收据释放它所持有的内容，然后继续确认请求。

检查会等到 zurg 学完发布中每个文件的准确大小，或者放弃获取大小为止，SABnzbd 端点也是在这个时点检查。学习大小会读取每个文件的第一篇文章，检查也会读取，所以两者同时进行只会让两边都变慢。比如一份 99 部电影的列表，如果每个发布一被列出就立即检查，Radarr 文件夹里最后一个文件要等将近九分钟才出现。如果检查在等待大小时超时，它会像其他超时的检查一样立即重新开始。发布如果仍在获取大小超过 30 分钟，就会照常检查。同时检查的发布不超过六个，其余的排队等待。

检查只读取，不会把文章内容移入缓存，也不会记录失效文章，所以它不可能让一个能播放的文件被屏蔽。大小获取过程刚刚拿到某个文件的第一篇文章时，检查会读取这份副本，而不会再抓取一次。

没有 NZB 账号（`nzb` 或 `torbox_nzb`）的安装，没有办法检查 NZB 获取。不过，如果有网盘账号接收种子，这种安装仍然会执行获取。每个种子都要检查它进入库时是否包含文件，具体做法见 [Newznab and Torznab](#newznab-and-torznab)。它还必须包含可以播放的东西：视频、音频，或 zurg 能流式读取的压缩包（RAR、7z、zip 或分卷）。只包含程序、光盘镜像或文本的种子是假货，新剧集在播出后的头几个小时里经常出现这类东西。这样的种子会像失效帖子一样被搁置，并立即尝试下一个发布。如果 zurg 为这次请求把它添加到了账号里，它会从账号中再次删除。账号原本就有的种子则保留在原处。没有 NZB 账号时，绝不会确认 NZB 获取，因为既无法检查，也无法播放。在最后一个 NZB 账号被移除之前就已经在等待的请求，会像失效帖子一样被搁置，然后尝试下一个发布。

## 持久化与恢复 {#persistence-and-recovery}

`data/acquisition.json` 记录每个获取任务的来源/请求 ID、尝试次数、重试截止时间、进行中的工作和收据，包括剧集。它还会记录每个来源是否已采用首次快照，因此 `only_new_items` 只决定一次，而不是每次重启都重新决定。

匹配的媒体目标和版本会在不同来源之间复用收据。发布文件名也会与库和已保存的 NZB 去重。收据还会记录仍在等待新闻服务器回复的抓取，账本则记录已确认失效的发布。因此，重启时如果正处于等待中，既不会把未检查的抓取当作已确认，也不会把已失效的发布重新交回排序。

收据不会被永久信任。在一个标题被视为已拥有之前，zurg 会检查确定它的内容是否仍然存在：对于 Radarr 或 Sonarr，是文件夹中已放置的视频；对于 DMM 想要列表、Plex 观看列表或 Seerr 标题，则是库中的该发布本身。如果之后被删除，即使标题仍在列表中且任务已完成，也会重新搜索。而从管理页面删除的发布不会再次获取。

每个保存的发布都会立即写入磁盘。尝试次数和重试时间会在一分钟内写入，因此崩溃最多可能丢失一分钟的这些数据，但绝不会丢失一次抓取。写入时会先刷新临时文件，再替换账本，并在支持的情况下刷新父目录。崩溃前已写入的 NZB 即使最后一次账本写入未完成，也会被复用。获取一旦被记录，Plex 删除重试就不会再次获取该标题。

失败后分别在 5、10、15 分钟后重试，然后是一小时，再然后是六小时。此后，标题的等待时间为其已失败时长的一半，因此等待时间会逐步增长：失败一天后约半天，失败四天后约两天，最长约一周，上下浮动四分之一，这样一起失败的标题不会同时重试。一次尝试在五分钟内耗尽却未找到任何结果，也算作失败。

如果未找到结果，并且你的某个索引器无法被查询，因为它要求在某个时间之前不要再请求（即 `Retry-After`，且该时间不超过一天后），则不计为失败。该标题会在那个时间之后重试，之后最多再等同样长的时间，这样一队标题就不会同时向索引器发出请求。如果索引器暂停十分钟，则会在二十分钟内再次尝试。这种情况最多连续发生三次，之后该次尝试按正常方式计算。未给出时间的索引器（例如返回 410 Gone 或拒绝密钥的索引器）则不予等待。

一个标题失败超过两周且尝试次数至少八次，就会被标记为 **parked**：zurg 停止向索引器询问它。它会在获取页面上以 parked 状态显示，并附上失败时长和原因，日志会记录一次。在该页面上点击 **Resume**，无论是单个标题，还是某个来源的所有 parked 标题，都会从第一个短重试重新开始。来源停止列出某个标题后又重新列出，即表示它重新请求了该标题，这同样会使其恢复。

新闻服务器确认的抓取会让标题的两周计时重新开始，因此仍在找到剧集的一季永远不会被 parked。升级也不会，无论来自哪个来源：其更好的发布可能要几个月后才出现，而该标题仍保留在列表中，因此它的重试间隔最多保持在一周之内。DMM 想要列表中的内容也不会被 parked，理由相同：一部尚未上映的电影，或一部没人发布的老电影，都会一直保持在想要列表中，直到被获取或你将其移除。计数和截止时间在重启后仍然保留，包括长时间关机。

一个永远失败的队列所带来的开销，是标题列表无法显示的。在某个安装中，数千个 Radarr 和 Sonarr 标题始终找不到任何结果，每六小时重试一次且永不停止。这使一个索引器的查询量从每天几百次增加到数万次，最终索引器暂停了该账户。其中大多数是没有 Usenet 发布的电影，以及配置文件允许的每个发布都已被拒绝的升级。未完成的 Seerr 请求仍会被监控。Plex 项目只有在所有计划的季都已获取并已检查后才会离开观看列表。检查方式如下：NZB 需对照新闻服务器确认；在 `torbox_nzb` 账户上，则看 TorBox 是否已获取该 NZB；种子需要能在库中找到可播放的内容。此外，还必须满足 `remove_after_grab` 允许，且 zurg 确实为其获取过内容。零散剧集回退仍然只限于在索引器结果中找到的剧集。

不可用的来源只暂停它自己的工作。状态写入失败会暂停后续获取，直到保存成功。无法读取或不受支持的账本会暂停获取并保留该文件；修复或恢复它，然后重启 zurg。zurg 的其他服务会继续运行。

先前的 `data/plex-watchlist.json` 会被一次性导入，历史记录、重试次数和尝试次数都会保留，且仅等待 Plex 删除的部分保持完整。原始文件会保留。两个账本都包含在普通备份中，无需 `--include-caches`。容器替换时，请保留 `data/` 和 `nzbs/`。

## 添加另一个适配器 {#adding-another-adapter}

在独立的包中实现 `acquisition.Source`：

1. `ID()` 用于在重启后仍能识别该实例。
2. `List(ctx)` 返回一份完整的 `Item` 引用快照。分页出错时，整个快照都要失败。只持久化元数据，绝不保存凭据或完整的 API 用户对象。
3. `Resolve(ctx, item)` 会重新校验该条目，并返回规范化的电影、季或剧集目标。`Gone` 用于取消不再需要的工作。`Follow` 用于在当前目标获取完成后，继续监控一个仍然打开的请求。
4. `Complete(ctx, item)` 用于确认一次性获取已经完成。崩溃后重复调用也必须没问题。只读列表可以使用空操作。引擎只会在该条目背后的所有抓取都返回结果后才调用它，所以适配器永远不需要自己检查某个发布版本。被调用这一事实，不能被当作超出这个意思之外的任何证据。

如果某个来源有自己的质量配置，它还可以实现 `acquisition.Assessor`，按照各自的规则评判每个候选发布版本。Radarr 和 Sonarr 适配器就是通过各自的解析器这样做的。

在 acquisition 服务中注册它的配置类型和工厂。队列、持久化、重试和执行器都不需要任何针对具体来源的分支。Trakt、MDBList 和 Simkl 可以套用这个契约，但目前还没有实现。
