# 从 streamnzb v5.1.0 迁移到 zurg {#migrating-from-streamnzb-v510-to-zurg}

streamnzb is a Stremio addon. It searches Newznab indexers when you press play and streams the winner.
Nothing is kept. It has no filesystem WebDAV mount or Plex library.

There is **no library on disk to preserve and no Plex watch state at risk**. The path-preservation steps in
the other migration guides do not apply.

zurg can take its place in two ways. Use one or both.

- **Keep Stremio.** zurg has a [Stremio addon](../guides/stremio.md) of its
  own. It searches your Newznab indexers when you press play and streams the
  release you pick through your news account. That is how streamnzb works too.
  It needs nothing but zurg. No rclone and no media server. Every release played
  this way also stays in zurg's library.
- **Build a library.** zurg keeps the releases it has in a library and mounts
  it for Plex or Jellyfin or Emby. Sonarr and Radarr can fill it. So can zurg
  itself from your watchlist.

A few things streamnzb did have no zurg equivalent. This guide says which.

This guide is shorter than its siblings because the problem is smaller.

## 哪些内容需要重新扫描，又有哪些新内容会出现 {#what-needs-rescanning-and-what-new-content-shows-up}

[其他迁移指南](index.md)里讲的那两个问题，在这里其实不太适用。值得说明一下原因，免得你自己去琢磨。

**没有任何东西需要重新扫描，因为没有可扫描的内容。** streamnzb 不保存任何媒体库，Plex 里也没有任何项目绑定到任何路径上。所以共享页面上的那套 trash-guard 机制对你来说并不起关键作用。没有旧项目需要保留，也不会因为一次误操作被丢进回收站。

**全部都是新内容。** 你放进 zurg 的 `nzbs/` 里的任何东西，都是在空库上的首次扫描。最好在第一次扫描前就把媒体库设置好，而不是事后再修。有两项设置最好先配置好。

- 在媒体库扫描的目录上设置 [`only_show_the_biggest_file: true`](../reference/config.md)。不设的话，样例片段、`.nfo` 文件和海报的 `.url` 广告都会显示出来。
- 在这些媒体库上把 "Generate video preview thumbnails" 设为**关闭**。在流媒体挂载上，每次生成缩略图都要完整读取一遍资源，会消耗你新闻服务器的流量额度。首次扫描时，Plex 会一次性把整个媒体库都交给它处理。

---

## 模型的变化 {#the-model-change}

| | streamnzb | zurg |
|---|---|---|
| 内容获取 | 每次播放请求时搜索 Newznab 索引站 | [Stremio 插件](../guides/stremio.md)在每次播放请求时搜索 Newznab 索引站。媒体库还可以通过 `.nzb` 文件和 SABnzbd 接口来填充，见[获取](../guides/acquisition.md) |
| 排序与筛选 | jhin 特征、筛选配置和 AvailNZB 检查 | 先按分辨率排序，再在每个分辨率内按大小分布排序。没有特征，也没有筛选配置 |
| 保留 | 不保留任何内容。每次播放都重新搜索 | 持久化的媒体库。通过插件播放过的版本会保留在库中 |
| 客户端 | Stremio。插件同时也是元数据提供者 | 通过 zurg 的插件使用 Stremio，插件只提供播放流。任何媒体服务器都可以通过挂载点使用。Infuse 则可以直接使用 WebDAV |
| 文件系统 | 无 | rclone FUSE 挂载，加上 WebDAV，再加上一个简单的 HTTP 索引 |
| 压缩包 | RAR 和 7z **仅支持 STORE**。压缩过的版本无法播放 | 压缩的 RAR 和 7z 可以透明地流式播放 |
| 混淆的帖子 | 拒绝 | 从 yEnc 头和 PAR2 中恢复文件名。以版本名称呈现内容 |
| 损坏的帖子 | 通过 AvailNZB 跳过 | PAR2 修复会重建缺失的文章。如果某个版本的开头已丢失，插件会跳过它并尝试下一个 |
| SABnzbd API | 没有。它在 119 端口提供一个 NNTP 代理 | 有，而且需要主动开启。每次抓取都会在新闻服务器上检查。能用 PAR2 重建的失效帖子会被重建，不能重建的会报告为 **Failed** |

日常使用时，Stremio 可以保持原样。添加 zurg 的插件，然后像以前一样选择影片即可。zurg 会搜索你的索引站，并播放你选中的内容。[Stremio 页面](../guides/stremio.md)介绍了设置方法。某个版本第一次播放时，需要等 zurg 获取 NZB 并列出该版本，这通常只需要几秒钟。之后再播放同一个版本，就会立即开始。

你的媒体服务器要有媒体库，还需要有东西来填充它。

- **SABnzbd 接口。** 设置 `sabnzbd.enabled: true` 后，zurg 会作为下载客户端回应 Sonarr 和 Radarr。导入其实就是在 `__magic__` 内做一次重命名。抓取的文件会进入 `__magic__/__all__`。导入时，文件会从那里移动到你旁边建立的根文件夹中。不会复制任何内容。大多数媒体库设置都应该使用这种方式。见 [Sonarr 和 Radarr](../guides/sonarr-radarr.md)。在报告抓取完成之前，zurg 会在新闻服务器上检查每一次抓取。它会检查每个文件的开头和结尾，还会下载每个文件的第一篇文章。文件多的版本最多要检查六十四个文件，再加上几个额外的检查。有些新闻服务器在内容被下架后仍然会说文章存在，只有实际下载才能发现。zurg 会在 PAR2 文件允许的情况下，重建缺少文章的版本。无法重建的版本会报告为 **Failed**。随后 \*arr 会将其加入黑名单，并抓取另一个版本。
- **获取。** zurg 可以自行获取请求。这些请求来自你的 Plex 观看列表，以及 Seerr 和 \*arr。它会搜索你的 Newznab 索引站，并以同样的方式检查每次抓取。见[获取](../guides/acquisition.md)。
- **手动放入。** 从你的索引站网站下载 `.nzb` 文件，然后复制到 `nzbs/` 中。文件名是固定的，目录大约每 15 秒重新扫描一次，文件不会被移动或消耗。这种方式始终可用，是最可靠的基准方案。
- **Sonarr 和 Radarr 的 "Usenet Blackhole"。** 可以将 \*arr 配置为 Blackhole 下载客户端，并把 *Nzb Folder* 设为 zurg 的 `nzbs/`。这样可以在不使用接口的情况下恢复搜索和抓取的自动化，但有一定代价。\*arr 会等待一个已完成的下载出现在它的监视文件夹中，然后再导入。zurg 永远不会生成这样的文件，因为版本会出现在挂载点中。因此，\*arr 的队列会显示该项目永远不会完成。你获得的是自动化的 NZB 投递，而不是 \*arr 的导入和重命名流程。这部分 \*arr 端的做法在编写指南时没有重新验证。zurg 端已在代码中验证，位置是 `internal/nzb/provider.go:30`。
- **索引站自己的 RSS 或购物车下载到目录。** 这完全取决于索引站，还需要你自己编写脚本来抓取。这种方式未经验证，只是因为有些索引站提供此功能，所以在这里提一下。

**放入文件前先命名。** 挂载点中的版本文件夹是以 NZB *文件名*命名的。只有当文件名看起来像哈希时，才会使用 `<meta type="name">` 头。这是 2026-08-19 在全部五个服务器上测得的结果。如果文件名是 `indexer_download_48213.nzb`，Plex 就没有可以匹配的内容，所以请先把它重命名为版本名称。这也意味着文件夹名称完全由你掌控。两个不同版本如果同名，会加上 ` {shorthash}` 后缀。

---

## 可以保留的配置 {#configuration-that-carries-over}

第一项是 Usenet 服务商。streamnzb 在 **Settings → Providers** 下配置服务商，需要填写 host、port、username、password 和 connections。也支持环境变量。同一个账号会变成 zurg 的 `nntp` 配置块。

streamnzb 中的写法（这是使用文档中键名的环境变量形式）：

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

zurg 的 `config.yml` 中的写法：

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

streamnzb 中的第二个服务商，例如 `PROVIDER_2_*`，要放到 `nntp.servers` 下面，zurg 会逐篇文章地依次尝试各个账号。`priority` 直接对应。zurg 还多出两个 streamnzb 没有的概念。设置 `backup: true` 会把一个按量计费的块账号标记为备用，只有当所有主账号都返回 *no such article* 时才会去查询它。设置 `backbone` 可以避免同一个 spool 上的两个账号被重复询问同一个问题。只允许有一个 `nzb` 服务条目，额外的新闻账号应放在它里面，而不是放在它旁边。

第二项是你的索引器。它们要放到 `stremio.indexers` 下面，URL 和 API key 保持不变。当 Acquisition 没有自己的列表时，会使用同一份列表。

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

streamnzb 的 `data/config.json` 中其他内容都不会转移。`streams` 和 `filter_profiles` 两个块决定了 streamnzb 的插件提供什么。zurg 的插件每个标题只有一份列表，并使用自己的排序方式。它最接近的两个设置是：`max_size_gb` 会丢弃超过指定大小的版本；`max_results` 设定每个分辨率保留多少个版本。其余内容请参阅 [Stremio 页面](../guides/stremio.md)。

---

## 观看历史 {#watch-history}

streamnzb 会在它的数据库里保存每个串流的播放历史。默认是 SQLite，文件位于 `data/streamnzb.db`，也可以选择使用 Postgres。“继续观看”和“因为你看过”这两行内容都是从这里生成的。它的文档把这部分内容描述为“library, search and play history, bad releases, and metrics”。

**这些数据都无法迁移到 Plex 资料库。** Plex 的观看状态保存在 Plex 自己的数据库里，按条目记录，而且条目必须先存在于资料库中才行。两边都没有现成的导入工具。这与其说是数据丢失，不如说是两种模型不匹配。streamnzb 的历史记录指向的是搜索和串流，而不是文件。如果你想在停用之前保留这些记录，可以直接读取它。数据库就是普通的 SQLite 文件。

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

官方没有记录确切的表名，本指南也没有验证过。运行 `.tables` 就能查到。如果用的是 Postgres，数据则保存在 `DATABASE_URL` 指向的数据库里。新环境中的观看状态会从零开始，之后从第一次播放起，在 Plex 里逐步积累。

---

## 你能获得什么 {#what-you-gain}

- **真正的媒体库。** Plex、Jellyfin 和 Emby 会扫描文件系统,保存元数据,并在它们支持的每个客户端上记录观看进度。不只是 Stremio。
- **PAR2 修复。** 缺少分段的发布会在后台用它自带的恢复文件重建。streamnzb 对付坏发布的办法是直接跳过,zurg 的办法是修好它。
- **混淆发布。** zurg 从 yEnc 头和 PAR2 索引中恢复真实文件名,并以发布名称呈现完全混淆的负载。在测试中,`Obfuscated.nzb` 提供了干净的 `Toy.Story.5.2026...KyoGo.mkv`。streamnzb 会直接拒绝这些发布。
- **压缩的 RAR 和 7z。** streamnzb 只串流 STORE 模式的压缩包,其 README 写得很明确:"Compressed RAR releases will not play"。zurg 可以从压缩包中串流视频,并在此过程中还原内部的目录结构。
- **二次播放即刻开始。** streamnzb 每次播放都要搜索和检查。zurg 会记住你播放过的内容,已经在媒体库中的发布可以立即播放。Sonarr 或 Radarr 获取的所有内容一开始就是这种状态。
- **多账号的深度支持。** 支持优先级、计费的 `backup` 账号、`backbone` 去重,以及所有账号都缺失时的修复路径。

## 你会失去什么 {#what-you-lose}

- **jhin 和过滤配置。** zurg 的插件也会搜索你的索引器。它只按分辨率和大小排序，没有 jhin 特性、过滤配置或评分。

- **AvailNZB 检查。** zurg 不会去问别人某个版本是否还活着。插件会读取你所选版本开头的内容来确认。如果开头已经失效，它就会跳到列表中的下一个版本。从 Sonarr 或 Radarr 抓取的内容，要先在你的新闻服务器上检查过，才算完成。文件更深处的损坏，会在读取到那里时才被发现。如果帖子里有足够的恢复数据，PAR2 修复就会把它重建好。2026-08-19 那天，一个缺少整卷的 RAR 集被列为空文件夹，而不是报错。

- **streamnzb 的目录和行。** 它内置的目录、元数据，以及 Continue Watching 和 Because You Watched 这两行，都来自它自己的历史记录。zurg 的插件只提供流。媒体服务器会为媒体库生成它自己版本的这些行。

- **端口 119 上的 NNTP 代理。** 如果 SABnzbd 或 NZBGet 把 streamnzb 设为新闻服务器，那它们就需要重新填入真实的服务商凭据。

## 搭建 zurg {#standing-up-zurg}

一个仅使用 Usenet 的可用 `config.yml`。

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

不要对 Usenet 内容使用 `tags_match_any` 过滤器。`zurg_*` 标签来自 ffprobe，而 ffprobe 在这个后端上从不运行。这样的目录永远不会包含 Usenet 资源。请改为按名称、扩展名、大小以及 `has_episodes` 进行过滤。

然后启动它。

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__all__/
```

如果 Usenet 是你唯一的账户，那么它的 `__nzb__` 文件夹不会出现在挂载点的根目录列表中，而 `__all__` 中包含相同的文件。所以请在挂载点下的 `__all__` 中测试播放，或者打开直接 HTTP 路径 `http://localhost:9999/http/__nzb__/`。`nzbs/` 的子目录会被跳过，`.nzb.gz` 文件也不会被读取。

### 第一个 Plex 媒体库 {#the-first-plex-library}

将库指向挂载点下的子目录，例如 `/mnt/zurg/movies` 和 `/mnt/zurg/shows`，不要指向根目录。同一个版本会同时出现在 `__all__` 和每个匹配的目录里，如果指向根目录，就会被扫描好几遍。如果你只用 Usenet 这一个账号，`__nzb__` 不会出现在挂载根目录的列表里，也无法通过挂载访问，因为 `__all__` 里已经有相同的文件。给 zurg 填上 `plex_server_url` 和 `plex_token`，它才能请求局部扫描。

下面两个库设置从第一次扫描起就很重要，不管库是全新的还是已经用了一段时间。它们要防范的问题是扫描过程中挂载短暂断开。

1. **取消勾选 "Empty trash automatically after every scan"**，让 `autoEmptyTrash` 为 0。如果扫描途中挂载消失，Plex 就会认为所有文件都被删除了。zurg 重启或 rclone 重新挂载都可能触发这种情况。开启自动清空的话，这些条目会立刻被永久删除；关闭后，它们只会留在回收站里，挂载恢复后会自动回来。以前就有人因此丢了几万条记录。
2. **取消勾选 "Generate video preview thumbnails"**。在 Usenet 上，每次生成缩略图都要完整读取一遍版本内容，会消耗你的连接流量额度。

另外，zurg 正在扫描时不要重启它。预检项和以上两项都必须为零。

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

请用 `grep -o … | wc -l`，而不是 `grep -c`。grep 没有匹配到内容时会以非零状态退出，而这正是这里的正常情况。它会中断 `&&` 链或 `set -e` 脚本，导致本该保护的那次重启根本执行不了。

文件大小在版本刚出现在列表里之后，还会稍微调整一下。NZB 并不记录文件有多长，所以第一次列出时，zurg 会根据 NZB 里记录的文章大小估算一个值。这个估算值可能比实际偏高最多约 3%。之后 zurg 会在后台算出精确长度并保存下来。在此之前进行的扫描看到的是估算值，Plex 就会把这个文件当作已修改，并重新分析一次。不会有任何文件被删除。

---

## 两者并行运行 {#running-both-side-by-side}

端口不会冲突。streamnzb 占用 7000 和 119，zurg 占用 9999。所以比较稳妥的过渡方式是：在 zurg 库慢慢填满的同时，让 streamnzb 继续为 Stremio 提供服务。

唯一的共享资源是新闻账号。**两者读取的是同一个连接额度，服务商会对两边一起限制。** 如果方案是 50 个连接，那就不能让 streamnzb 用 50 个、zurg 再用 30 个。超出的连接会被拒绝，在 zurg 这边看起来就像播放缓慢或卡住。所以要明确地分配。可以在 streamnzb 中尝试 `PROVIDER_1_CONNECTIONS=20`，同时在 zurg 中设置 `connections: 30`。等 streamnzb 退役后，把全部额度都给 zurg，因为 zurg 的单流吞吐量取决于这个数值。

关掉 streamnzb 时，请从你的客户端中移除它的 Stremio 插件。如果想保留历史记录，就备份一份 `data/`。它的 `config.json` 和 `streamnzb.db` 就是它的全部状态。然后，把所有通过 119 端口使用 NNTP 代理的地方，改为直接连接你的服务商。
