# `__magic__`，一个可以自行整理的目录 {#__magic__-a-directory-you-can-organise}

零碎的其他 zurg 目录都是动态计算出来的。`movies` 会套用 movies 过滤器，`__all__` 包含所有内容。

一个 release 文件夹里放的是账号报告的内容。每次刷新时，目录结构都会重新生成。

`__magic__` 是唯一一个路径是**保存下来**的目录。移动文件只会改写数据库里的一行记录。文件内容不会搬动，debrid 账号也保持不变。你可以手动整理，也可以让 Sonarr 和 Radarr 来用它。

它里面有三类东西。`__magic__/__all__` 放的是还没有被归位的所有 release，也是下载客户端导入时所使用的文件夹。它是动态计算的，所以顶层不能新建任何东西，也不能用文件内容覆盖 release 文件夹里已经存在的名字（release 文件夹只接受它没用到的名字下的 sidecar 文件）。如果你有 DMM 赞助者密钥，zurg 会把 DMM 识别出的所有内容按标题归入 `__movies__` 和 `__shows__`（[见下文](#__movies__-and-__shows__-sorted-by-title)）。`__magic__` 根目录下的其他内容都由你自己决定：

```
/mnt/zurg/__magic__
├── __all__     <- what nothing has placed yet, where a grab lands
├── __movies__  <- films zurg filed by title
├── __shows__   <- shows zurg filed by title
├── __anime__   <- anime shows, with magic.anime: true
├── anime
├── movies
└── tv          <- your *arr root folders
```

本页的路径使用 Linux 挂载点 `/mnt/zurg`。在 macOS 上是 `/Volumes/Zurg`，在 Windows 上是 `Z:\`，所以 `/mnt/zurg/__magic__/tv` 对应的就是 `/Volumes/Zurg/__magic__/tv` 或 `Z:\__magic__\tv`。

这种分开放置正是关键所在。客户端导入*来源*的文件夹和导入*目标*的文件夹是平级的，互不包含：手动导入时指向下载文件夹，不会遍历你的媒体库目录树，Sonarr 和 Radarr 也不会对这种安排发出警告。

它默认是关闭的。用下面的方式开启：

```yaml
magic:
  enabled: true
```

然后重启。路由是在启动时确定的，所以在控制面板里切换它之后，需要先重启，命名空间才会生效。

## 用途 {#what-it-is-for}

\*arr 导入文件时会把文件从下载文件夹**移动**到媒体库中。zurg 没有地方接收这次移动，所以 \*arr 退而改为复制。而从 debrid 挂载点复制，意味着要通过网络把整个发布内容下载下来，这正是挂载要避免的事。

使用 `__magic__` 时，导入只是同一个命名空间内的一次重命名：写入一条记录，文件出现在 \*arr 指定的位置，什么都不会下载。正是这一点让 [SABnzbd 端点](sonarr-radarr.md)值得一用。它只是构建在这之上的一层薄封装，没有它，每次导入都得完整下载。

这要求 \*arr 的**根文件夹也必须位于 `__magic__` 内**，比如 `/mnt/zurg/__magic__/tv`，而不是机器上别的什么目录。移动的目标如果在命名空间之外，那就是两个文件系统之间的移动，实质上又变回了复制。zurg 会直接以 `403` 拒绝，而不是悄悄放行。命名空间内唯一被拒绝的位置是 `__magic__/__all__` 的顶层，那是媒体库自身的目录结构，不是用来放文件的地方。具体设置见 [sabnzbd.md](sonarr-radarr.md)。

从 `__all__` 中放置出去的文件仍会在那里列出，而在 `__all__` 中删除会直接从账户里删掉文件。因此，只要这里的放置内容仍在从中串流，zurg 就会拒绝通过 `__all__` 或其他任何媒体库文件夹删除该文件。请改在 `__magic__` 下删除。这样可以防止这样一种情况：像 DMM 的 SABnzbd 代理那样，\*arr 从 `__all__` 中导入文件后又清理了那里的下载文件夹，结果把刚导入的发布内容删掉了。

而且 \*arr 必须通过**同一个挂载点**访问下载文件夹和根文件夹。如果容器分别挂载 `__magic__/__all__` 和 `__magic__/tv` 两个卷，那么它看到的就是两个文件系统，即使两者都属于 zurg。内核会在请求到达 zurg 之前就在容器内拒绝这次重命名，于是 \*arr 只好复制整个文件。zurg 会在复制完成后把这样的复制转回放置操作，并记录 `A client copied …`，但下载已经发生了。请把 zurg 整个挂载目录绑定为容器中的一个目录。参见 [下载文件夹与根文件夹共用一个卷](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。

zurg 自身的获取流程也会在这里放置文件。Radarr 来源会把它确认的每个发布内容，用与导入相同的移动操作放入电影文件夹，然后通知 Radarr 重新扫描。参见 [acquisition.md](acquisition.md#placing-the-file)。

zurg 还会自行把文件放入 `__movies__` 和 `__shows__`。参见[下文](#__movies__-and-__shows__-sorted-by-title)。

手动整理媒体库是另一半内容，而且完全不需要 \*arr 也能使用。

## 没有存储任何内容时，它会把 `__all__` 中的发布内容显示为真实文件夹 {#with-nothing-stored-it-is-__all__s-releases-as-real-folders}

打开一个全新安装的 `__magic__/__all__`，你会看到 `__all__` 里的每个发布都以一个文件夹的形式出现。这个表一开始是空的，只记录与默认状态的**偏差**，所以没动过的库什么都不会记录。`__magic__` 的根目录只有镜像，新发布只要在别处出现，就会立刻出现在这里。一旦有东西放置了某个发布（\*arr 的导入，或 zurg 自己把它归档到 `__movies__` 和 `__shows__`），它就会离开 `__magic__/__all__`。镜像里放的就是还没被放置的内容。

这里没有目录配置：没有 `only_show_the_biggest_file`，也没有大小过滤。发布里有什么，你就看到什么。

它和 `__all__` 唯一的区别在于**发布文件夹内部的结构**。在其他地方，zurg 会把发布压平成一个目录，用文件名作为键；如果两个文件会重名，就加上后缀：

```
__all__/Show.S01/Show.S01E01.mkv
__all__/Show.S01/Gag Reel (Extras).mkv
```

`__magic__/__all__` 显示的是发布实际拥有的目录树：

```
__magic__/__all__/Show.S01/Show.S01E01.mkv
__magic__/__all__/Show.S01/Extras/Gag Reel.mkv
```

这不只是外观上的差别。Sonarr 和 Radarr 是把下载文件夹当作文件夹来扫描的：放在 `extras`、`samples`、`featurettes`、`trailers` 或 `deleted scenes` **子文件夹**里的文件会被跳过，而放在顶层的文件则会被考虑。所以被压平的 `Gag Reel (Extras).mkv` 会被提供给导入，而在真实目录树里它本来是被忽略的。另外，只有当文件夹里只有一个视频时，它们的导入才会回退到下载本身的标题来解析。因此，如果一部电影和它的花絮被压平放在一起，就会失去这个回退。由于[SABnzbd 端点](sonarr-radarr.md)会把 \*arr 指向 `__magic__/__all__` 下的一个文件夹，这正是这些规则所作用的界面。

关于这种结构有两个细节：

- **单层包裹文件夹会被去掉。** 几乎所有发布都是一个文件夹装着所有内容，而这个文件夹正是发布本来的*名字*，debrid 后端也是从它推导名称的。所以 `/Show.S01/Season 01/ep1.mkv` 显示为 `Show.S01/Season 01/ep1.mkv`，而不是 `Show.S01/Show.S01/Season 01/ep1.mkv`。只去掉一层，而且只有在它旁边没有其他东西时才去掉：如果发布顶层有一个文件，旁边还有一个文件夹，那么两者都会保留。
- **不加重名后缀。** 这些后缀是为了让压平后的列表保持无歧义，而目录树本身就有子目录来做到这一点，所以不需要后缀。

发布文件夹的其他方面都保持不变，包括压缩包：RAR 分卷集仍然可以像目录一样浏览，只是现在它会位于其分卷在目录树中所在的位置；如果一个发布来自一个被压平的压缩包，它仍然会列出该压缩包的内容。

`__all__` 和 `directories:` 过滤器仍然保持扁平。它们是媒体服务器应该指向的地方，这些内容都不会改变。

## 整理它 {#organising-it}

通过挂载目录，用普通命令操作：

+++ Linux
```bash
mkdir -p /mnt/zurg/__magic__/tv/The\ Show/Season\ 01
mv /mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /mnt/zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ macOS
```bash
mkdir -p /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01
mv /Volumes/Zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ Windows
```powershell
New-Item -ItemType Directory -Force "Z:\__magic__\tv\The Show\Season 01"
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Release.S01E01.1080p\ep1.mkv" `
  -Destination "Z:\__magic__\tv\The Show\Season 01\S01E01.mkv"
```
`-LiteralPath` 可以避免许多发布名中的方括号被当成通配符来解析。
+++

文件现在位于新路径，旧路径下已经没有它了。它仍然从原来的同一个账户串流播放。

整个发布文件夹也可以一次移动，只需一行命令：

+++ Linux
```bash
mv /mnt/zurg/__magic__/__all__/Some.Movie.2024.2160p /mnt/zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ macOS
```bash
mv /Volumes/Zurg/__magic__/__all__/Some.Movie.2024.2160p /Volumes/Zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ Windows
```powershell
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Movie.2024.2160p" -Destination "Z:\__magic__\movies\Some Movie (2024)"
```
+++

目录会连同其下的所有内容一起移动，作为一批操作完成。移动是双向的：文件既可以移入发布文件夹，也可以移出。文件夹中会把它和发布自身的条目列在一起。这对于那些要把东西放回自己所导入的文件夹中的程序来说很重要，它们需要看到这些文件。如果同一个名称同时来自两个地方，那么你主动做出的选择优先：你移动过的内容优先于发布本身对该名称的定义，而发布定义又优先于 `data/local` 中的真实文件。被覆盖的那一项不会被列出，因此不会重复显示。

有一种情况会通过内置挂载失败，而且只在默认设置 `union_writable: local` 下出现：重命名你通过挂载创建的目录，也就是先 `mkdir` 创建目录，之后再对它执行 `mv`。在默认顺序下，`mkdir` 会在 rclone 自己的本地上游创建该目录，而其下的条目同时在服务端让这个目录也存在。于是 rclone 会重命名它的本地副本，再逐个移动条目。zurg 对每一次移动都会正确响应，但随后 rclone 在删除一个已经被它重命名掉的源目录时失败：

```
ERROR : __magic__/tv/Saul: Dir.Rename error: RenameDir rmdir: object not found
```

最终条目都会出现在你要求的位置：zurg 提供新路径，旧路径返回 404。但 `mv` 会以退出码 1 结束，并且在目录列表重新读取之前，挂载仍会显示已被清空的源目录，而不是目标目录。这个删除请求从来没有到达 zurg，所以 zurg 无论做什么都无法阻止它。移动文件和移动整个发布文件夹在任一顺序下都能正常工作。如果你要通过挂载重新组织目录，请设置 [`union_writable: server`](../reference/config.md#rclone-settings)。这样目录只存在于命名空间中，重命名就是一次服务端操作。以上结果基于 rclone 1.71.2 测得。

`rm` 只是隐藏内容，参见 [删除只是隐藏，并不会真正销毁](#deleting-hides-it-does-not-destroy)。

## 按标题排序的 `__movies__` 和 `__shows__` {#__movies__-and-__shows__-sorted-by-title}

Kodi 和 Plex 通过文件夹名和文件名来判断文件是什么，而 `Succession.S01.MULTi.1080p.BluRay.REMUX.AVC-DEMS` 这样的发布名称往往超出它们的识别能力。在我们的测试中，直接用发布名称时，Kodi 只识别出 56 部剧中的 8 部。使用 DMM 赞助者密钥后，zurg 会把 DMM 已识别的每个发布文件放进两个文件夹，文件夹名称是播放器能直接匹配的格式：

```
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.mkv
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/tvshow.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/Season 01/Detective Conan (1996) - S01E1194 [tmdbid-30983].mkv
```

同一个库以这种方式整理后，Kodi 和 Plex 成功匹配了全部 70 部电影、全部 44 部剧集和全部 554 集。

### 开启它 {#turning-it-on}

你需要 2026-10-26 或之后的 zurg nightly 版本，开启 `__magic__`，还要有你的 DMM API key。赞助之后，[gatekeeper](https://gatekeeper.debridmediamanager.com/) 会把这个 key 显示给你：

```yaml
magic:
  enabled: true
dmm_api_key: YOUR_DMM_API_KEY
```

重启 zurg。库加载完、DMM 识别完之后，这两个文件夹才会有内容。库比较大的话，第一次可能要几分钟。之后，DMM 一识别到新资源，就会在一分钟内归入对应文件夹。接着添加一个指向 `/mnt/zurg/__magic__/__movies__` 的 **Movies** 库，和一个指向 `/mnt/zurg/__magic__/__shows__` 的 **TV** 库（macOS 上是 `/Volumes/Zurg/__magic__/...`，Windows 上是 `Z:\__magic__\__movies__` 和 `Z:\__magic__\__shows__`），然后扫描。在 Kodi 里，把 TV 源的刮削器设为 **The Movie Database**（默认就是它），并保持更新。`tvshow.nfo` 文件需要 Kodi 的 TMDb TV 刮削器 1.7 或更高版本。

每个库都要指向它自己的文件夹，别指向 `__magic__` 本身。那样会把 `__all__` 和你其他的文件夹也扫一遍，同一个内容就会被找到两次。

### 它的作用 {#what-it-does}

- **Film or show is what DMM says it is**, never a folder rule. A film that came inside a show's pack is filed as that film.
- **Every release of a show lands in one folder**, with seasons and episodes numbered the way TMDB numbers them, the order Plex uses by default. Anime numbered by its run is placed in its season: `Detective Conan - 1194` is S01E1194.
- **The TMDB id is in the folder, in every file name and in the `.nfo`**, so each player finds it where it looks: Plex in the folder, Kodi in the `.nfo`, and players that read only file names in the file name.
- **One copy per title.** When two releases are the same episode or film, the better one is filed, by resolution and then size; the other stays in `__all__`.
- **Extras and samples are left in `__all__`**, and so is anything DMM has not identified. A release is filed once DMM identifies it.

### 动漫放在独立的文件夹中 {#anime-in-a-folder-of-its-own}

动漫可以放进第三个文件夹 `__anime__`，这样 Kodi 和 Plex 就能有自己的动漫库，就像给动漫单独配一个 Sonarr 一样。这需要 2026-11-10 或更新的 zurg nightly 版本，还要加一行：

```yaml
magic:
  enabled: true
  placement: true
  anime: true
dmm_api_key: YOUR_DMM_API_KEY
```

重启 zurg，然后添加一个 **TV** 库，指向 `/mnt/zurg/__magic__/__anime__` 并扫描。DMM 根据 TMDB 判断什么是动漫，满足以下任一条件即可：TMDB 把该剧列为动画，并且语言是日语、产地是日本，三个条件都满足；或者 TMDB 给它打了 *anime* 关键词。《名侦探柯南》、《钻石王牌》和《赛博朋克：边缘行者》会进入 `__anime__`。《地狱少女》（美国动画）、《爱丽丝梦游仙境：边境》（日语真人剧）和《LINK CLICK》（中国动画）则留在 `__shows__`。电影都留在 `__movies__`，包括动画电影。Movies 库只能是一种类型，这个文件夹也是一样。

开启这个功能后，所有动漫剧集会在几分钟内从 `__shows__` 移出。对播放端来说，看起来就是剧集从一个库消失，又出现在另一个库里：

- **Plex** 会把它们从 TV 库中移除（显示为缺失，如果你开启了扫描后清空回收站，则直接删除），并在下一次扫描时把它们加入 Anime 库。观看状态会保留：Plex 把观看记录绑定在剧集上，而不是库上，所以在 TV 库里看过的集数，在 Anime 库里也会显示为已看过（2026-11-09 实测）。
- **Kodi** 把观看状态绑定在文件路径上，所以在开启之前，先导出你的视频库（Settings → Media → Library → Export）。等 Anime 源扫描完成后，再导入。

关闭这个功能时，它们会以同样的方式移回去。

### 配合 DMM 的想看列表 {#with-the-dmm-wanted-list}

按下 DMM 上的 **Want** 后，zurg 会去获取该影视作品（[DMM 想看列表](dmm-wanted.md)）。获取到的内容会和其他内容一样归档到这里，因此电影或剧集会以其自身名称出现在 Kodi 和 Plex 中，无需 Sonarr 或 Radarr 参与。种子被抓取后，最长可能需要一小时才会完成归档；NZB 则在 DMM 识别后立即归档。

### 配合 Sonarr 和 Radarr {#with-sonarr-and-radarr}

他们各自保留自己的媒体库。Sonarr 或 Radarr 通过 zurg 抓取的版本，从抓取那一刻起就会留在 `__all__` 里等他们导入，zurg 从不会整理他们自己放置的内容。如果他们把 zurg 已经整理好的影片移动到自己的根文件夹里导入，那这个影片就归他们所有，之后 zurg 会一直把它留在那里。

要让 Kodi 和 Plex 也用同样的方式匹配他们的媒体库：

- 在各自的 **Settings → Metadata → Kodi (XBMC) / Emby** 中开启该选项。之后每部电影和每个剧集旁边都会写入一个带有片名 id 的 `.nfo` 文件，zurg 会保留这些文件。
- 在 **Settings → Media Management** 中，把 id 加到文件夹名里：

  | | 文件夹格式 |
  |---|---|
  | Radarr | `{Movie CleanTitle} ({Release Year}) {tmdb-{TmdbId}}` |
  | Sonarr | `{Series TitleYear} {tvdb-{TvdbId}}` |

### 须知 {#good-to-know}

- **在播放器里删除会隐藏文件**，就像在 `__magic__` 里做的任何删除一样。文件仍保留在你的 debrid 账户中，zurg 也不会再次把它归档。
- **无法把任何东西移入 `__movies__`、`__shows__` 或 `__anime__`**：这些文件夹由 zurg 负责填充。把文件从它们里面移出去（像 \*arr 导入那样）是可以的。
- **当 DMM 对某个发布版本的识别发生变化时**，zurg 会把它的文件移动到新名称下。
- **出现故障的文件会保留原位**，zurg 修复期间，你的媒体服务器不会丢失它。
- **没有 DMM 赞助密钥时，任何内容都不会被归档。** 删除密钥，或关闭 `__magic__`，已经归档的内容都会留在原处。

## 移动操作在修复、重命名和重新列出后依然有效 {#a-move-survives-repair-rename-and-re-listing}

zurg 修复损坏的版本时，是把它重新添加到账户里。种子 ID 会变，访问密钥会变，文件 ID 也会变。所以如果用这些作为键的表，链接一旦失效，每条放置记录都会丢失。因此，记录改为以版本的**内容哈希**加上文件在版本内的**路径**作为键，而这两者在修复时都不会改变。

以下这些都是有意设计的：

- **修复后你的布局保持不变。** 版本会以新的 ID 回来，文件仍然待在你放置它们的位置。
- **重命名版本不会移动任何东西。** 重命名，以及两个不同版本可能共用同一文件夹名时 zurg 加上的后缀，都会改变版本默认文件夹的名字。放置记录不受影响。
- **消失的文件不会被遗忘。** 如果修复改变了文件集合（Real-Debrid 重新打包 rar 版本是最常见的原因），那么对应文件已不存在的记录会被*保留但不列出*。文件回来后，它的位置也会恢复。处于这种状态的记录会在仪表盘上显示为 **dangling**，你可以在那里将其删除。
- **删除版本后再重新添加，布局同样保留。** DMM 的 reinsert，或者先删除再重新添加同一个版本，都会得到相同的哈希。文件会回到你放置它们的位置；而你删除过的文件夹（例如 \*arr 导入后删除的任务文件夹）仍然保持隐藏。要让该版本重新出现在 `__magic__/__all__` 中，请在仪表盘的 `__magic__` 页面搜索它，然后在它的版本墓碑记录上按 **Unhide**。

有一个后端需要的不只是精确的路径匹配。Usenet 帖子的文件名是*解析得出*的，而不是直接给出的：每次加载时都会重新推导，且从不存储。因此，如果帖子首次读取时新闻服务器无法连接，它会保留混淆后的文件名，直到之后某次加载恢复出真实文件名为止。对于这类帖子，记录会退而使用文件在 NZB 中的索引；如果仍然对不上，再退而使用“基本文件名 + 大小”，前提是恰好只有一个文件匹配。

## 删除只是隐藏，并不会真的销毁 {#deleting-hides-it-does-not-destroy}

在 `__magic__` 下执行 `rm` 会写入一个 **墓碑标记**（tombstone）：条目从 `__magic__` 中消失，但在 `__all__`、每个过滤目录以及调试网盘账户中仍保持原样。什么都没有被删除。

这并不是畏首畏尾，而是让 \*arr 能够安全对接的关键。\*arr 在质量升级时会删除旧文件，在导入时会删除整个任务文件夹。如果这些删除操作真的会移除内容，升级就会毁掉原有版本；而如果删除只是移除了*记录*，文件就会重新出现在默认位置，也就是 \*arr 导入时所用的文件夹里。

如果你希望删除操作真正删除内容：

```yaml
magic:
  allow_delete: true
```

这样一来，**文件**删除也会同时从账户中移除内容。发布文件夹和目录则永远不会，无论此项如何设置：前者正是 Sonarr 每次导入后都会删除的东西。

压缩包内的条目，在大多数 Usenet 发布中就是那一集剧集或那部电影。它本身没有独立的文件，压缩包里还装着该发布的其他所有内容。因此，只有当 `__magic__` 下已没有任何内容使用其中的任何部分时，删除它才会连同整个发布一起移除。它的任何文件都不能再被放置在任何位置。它自己的文件夹必须被删除，或者里面已经没有可供导入的内容。这正是升级后被替换的 Usenet 剧集所处的状态。在这个问题被处理之前，被替换的版本会一直留在媒体库中，它的 NZB 也会永远留在 `nzbs/` 里。

普通视频文件会被单独删除。只有当 `__magic__` 下已没有任何内容使用该发布的任何部分时，发布才会一并删除。同样的两条规则决定这一点。发布通常不止包含视频：`.nfo`、字幕或海报会与视频放在一起，但没有人会导入这些文件。在这个问题被处理之前，视频被删除后，这些附属文件仍会让发布留在媒体库中，它的 NZB 会留在 `nzbs/` 里，调试网盘上的发布也会留在账户中。同一季合集中的其他剧集，只要仍被放置或仍位于发布文件夹中，就会保留该发布；被移动到其他位置的发布文件夹也会保留该发布；无法读取但仍可能被修复的剧集同样会保留它。在发布原来的位置删除附属文件，永远不会删除发布本身。只有删除 Sonarr 或 Radarr 导入到视频旁边的最后一个字幕，才会删除发布。

`dav_allow_rename` 以及挂载点自身不经过权限控制的删除路径，都与上述内容无关。它们针对的是会重命名或销毁调试网盘所持有内容的操作路径；而 `__magic__` 下的写入操作不会触及任何账户。`mount_read_only: true` 仍会在内核层面覆盖一切。

撤销墓碑标记只需在仪表板上点击一下。

所以升级后，被替换的版本仍会留在你的媒体库中。**Manage > Duplicates** 会把这些残留版本与 \*arr 当前使用的版本并列列出，你可以选择删除其中的任意版本：参见 [查找重复版本](acquisition.md#finding-duplicate-releases)。

## 过滤器和 `__all__` 不受影响 {#filters-and-__all__-are-untouched}

一个你移动过的资源，仍然会出现在 `movies` 里，仍然在 `recent` 里，仍然在 `__all__` 里，文件名也还是原来的。`__magic__` 只是同一个库的第二个视图，不是把资源搬走了。

这一点容易让人意外，所以值得明确说明：**在 `__magic__` 里移动东西，只会改变 `__magic__`。** 筛选目录是根据资源计算出来的，而资源本身没有变。

对于媒体服务器，请只指向两者中的**一个**。如果 Plex 媒体库同时扫描 `shows/` 和 `__magic__/tv`，每一集都会被找到两次。`__movies__`、`__shows__` 和 `__anime__` 也是同样的道理：媒体库只指向其中一个，永远不要指向 `__magic__` 本身。

## 附属文件：`.nfo`、海报、字幕 {#sidecars-nfo-posters-subtitles}

\*arr 会在视频旁边写入元数据，Bazarr 会写入字幕。这些都是真实文件，而 zurg 无处可放在 debrid 库中，所以它们会存到本地磁盘的 `data/local/__magic__/` 下。

设置 Bazarr，以及它的字幕如何到达 rex，请参阅 [使用 Bazarr 配置字幕](subtitles.md)。

如果你使用 zurg 内置的挂载，这些已经自动完成，不需要你做任何操作。挂载点是 `data/local` 和 zurg 的 WebDAV 的联合体，rclone 会把每个新建的文件发送到本地那一半。zurg 根本不会收到这次写入。这也是 Sonarr 的 "is this folder writable?" 测试能通过的原因。

如果你自己挂载 `/dav`，比如用你自己的 rclone、Infuse，或者 Windows 的 WebDAV 网络驱动器，zurg 会接受 `PUT` 请求，并写入同一个目录树，因此两边看到的内容一致。这里有两个上限：

```yaml
magic:
  sidecar_max_mb: 32       # per file
  sidecar_budget_mb: 2048  # the whole tree
```

第一个上限对应 `413`，第二个对应 `507`。它们限制的是 *zurg* 能写入的内容。在默认的 `union_writable: local` 设置下，rclone 自己的本地上游无法从这里拒绝，不过每次拒绝之前都会重新统计目录树的大小。因此，rclone 放进去的文件会在 zurg 下次需要写入时计入预算，但超过 `sidecar_max_mb` 的文件除外，它们不会被计入。`union_writable: server` 则相反：创建请求会直接到达 zurg，所以上限会约束经由挂载的每一次写入，而且 `__magic__` 之外的任何位置都会被直接拒绝。

边车文件也可以放在发布文件夹内部，\*arr 为它导入的文件写入 `.nfo` 时就是这样。对于发布文件夹中尚未占用的任何名称，zurg 都可以写入和重命名；如果名称会与该发布自身的文件冲突，zurg 则会拒绝。对边车文件执行 `DELETE` 会真正删除它，这是 `__magic__` 中唯一一个删除不是删除标记（tombstone）的地方。删除标记只会隐藏库中其他位置仍然存在的条目，而边车文件的内容只存在于 `data/local` 中，别处没有。

## 仪表板 {#the-dashboard}

库加载完成后，zurg 会输出一行日志，说明表里共有多少行、其中有多少行是悬空的。这样，库里的内容丢失之后，就不会留下一堆没人引用的行，越积越多。普通端口上的 `/magic/` 会显示表里存的内容：所有行按发布分组，列出每一行是什么、来自哪里，悬空的行单独放在一个区域，并显示 sidecar 目录树及其大小和预算。它还会显示日志（journal）和快照（snapshot）的大小，以及整个 `data/local` 的大小。这个数字能说明某个东西是不是通过复制来导入的。在默认的 `union_writable: local` 下，如果客户端是复制而不是移动，字节就会写到这里，别的地方都不会显示它们。

在 `union_writable: server` 下，这个数字始终为零，改由日志来告诉你情况。复制型客户端的 `PUT` 会被拒绝，因此它本来要填充的目录树根本不会被写入。被拒绝并不代表数据丢失：rclone 的缓存会保留这些字节并重试，但它们不再以 zurg 能统计的名字存放在这块磁盘上。[qBittorrent 指南](sonarr-radarr-torrents.md)说明了原因：这总是客户端的设置问题。只有当 \*arr 可以放心地在之后删除下载内容时，它才会移动导入的文件。

在这个页面上，你可以重置某个放置位置（文件会回到默认位置）、清除墓碑（条目会恢复）、删除一个悬空行、一次性清理所有这些内容，或者删除某个 sidecar。每项操作在执行前都会先让你确认。

存储行列表只显示前一千行。如果库是由 \*arr 组织的，那么这一千行只占表的很小一部分，因为每次导入都会留下一个墓碑。要查看某个发布，直接搜索即可：搜索发布名称、挂载路径或哈希，就能列出与该发布相关的所有已存行及其按钮，无论表有多大。悬空列表也支持同样的搜索。库里已经不存在的发布，在表中没有名称，只有它的哈希，以及它的行所指向的路径。

**已经无人引用**的 sidecar 会单独列出并计数，例如某个发布已离开库的 `.nfo` 文件，或某个已被遗忘的放置位置内的文件。它们仍然会被提供访问，因为真实文件是路径最终解析到的对象，而它们上层已经没有东西声明这个名字。但失去的是它们存在的理由。zurg 从不自动清理这些文件。你通过挂载（而不是通过 zurg）自己为 sidecar 创建的目录，也会以同样的方式显示，因为它不会留下任何行。

如果 SABnzbd 端点已开启，页面还会列出它的任务，包括 id、名称、分类、状态，以及交给 \*arr 的文件夹。当你想知道“为什么 Sonarr 还显示这个在下载中”时，这是最快的查看方式。

## 持久性 {#durability}

每次改动都会先追加到 `data/magic.journal`，并在回复请求之前刷新到磁盘。这样，\*arr 认为已经完成的移动，即使遇到崩溃也不会丢失。journal 会在启动时、文件变得超过阈值时，以及关机时，合并进 `data/magic.json` 快照。

这两个文件都不是用来修改表格的。zurg 把表格保存在内存里，并从内存写出 `magic.json`。所以如果 zurg 运行时你手动从文件里删掉某一行，下次重启后它还会回来。请使用仪表板上的按钮来修改。

如果断电导致最后一行被截断，这一行会被丢弃，之前的内容都会保留。如果快照是由其他架构版本写入的，它会被直接丢弃，而不会被猜测着读取。如果 journal 中某一行来自其他版本，回放会在那一行停止。快照或 journal 无法读取时，只会给出警告并使用空表，不会导致启动失败。如果某个表的文件无法*打开*，`__magic__` 会以只读方式提供服务，和它最初作为 `__all__` 镜像的状态一致，所有写入都会被拒绝。关机期间收到的写入请求会返回 `503`，而不是先被确认然后丢失。

## 状态码 {#status-codes}

有助于直接通过 WebDAV 操作命名空间；挂载点会替你处理好这些。

| 代码 | 含义 |
|---|---|
| `201` | MOVE、MKCOL 或 PUT 成功创建了内容 |
| `204` | DELETE，或替换了附属文件的 PUT |
| `400` | 命名空间无法存储的路径，或缺失或无法解析的 `Destination` 头 |
| `403` | 目标位于 `__magic__` 之外，或位于 `__movies__`、`__shows__` 或 `__anime__` 之内，或是库所应答的路径，或路径经过一个文件，或 `__magic__` 本身，或只读的表 |
| `404` | 那里什么都没有（对不存在的内容执行 DELETE 仍返回 `204`），或从一个已不再包含该条目的压缩包中 MOVE |
| `405` | 对已存在的内容执行 MKCOL，或对目录执行 PUT |
| `409` | 父目录缺失、目录非空、目标已被占用且 `Overwrite: T`，或从一个无法打开的压缩包中 MOVE |
| `412` | 目标已被占用且 `Overwrite: F` |
| `413` / `507` | 超过 `sidecar_max_mb` / `sidecar_budget_mb` |
| `503` | 正在关闭，或 MOVE 的源暂时无法提供服务，并附带 `Retry-After` |

`MOVE` 会拒绝任何位于 `__magic__` 之外的目标：过滤目录保持只读。

**从压缩包中**的 `MOVE` 也会在写入任何内容之前，先对压缩包本身进行检查。导入就是一次 `MOVE`，而一次成功的 `MOVE` 之后不会有任何东西再次检查，客户端遍历过的列表也不能作为依据：解析后的压缩包内容会被缓存，因此一个数据已经丢失的发布资源仍会继续列出它的剧集。所以会先检查卷的健康状况、发布资源的文章损坏情况，以及在这些信息无法说明问题时的压缩包本身。这与对同一路径执行 `HEAD` 时的检查完全一致；而健康的发布资源会直接从其列表已经构建好的同一份缓存中返回结果。源永远无法读取时返回 `409`，暂时无法读取时返回带 `Retry-After` 的 `503`，压缩包中不存在的名称则仍返回 `404`。拒绝时不会记录任何内容。

## 值得了解的限制 {#limits-worth-knowing}

- **`magic.enabled` 需要重启。** 路由是在启动时注册的。
- **每个文件只能放置一次。** 再次移动文件会重新放置它，同一个文件不能出现在两个路径下。
- **rar 分卷包里的文件可以像普通文件一样放置。** 记录会保存分卷和分卷内的路径，所以重新打包后依然有效，和普通文件一样。不过，已放置的文件*下面*不能再创建任何东西：经过该文件的路径会被拒绝。
- **`__magic__` 的目录列表会忽略 `serve_strm_files`。** 这个命名空间的用途是让 \*arr 把真实文件移出去，而 `.strm` 不是任何工具能导入的文件。客户端如果按名称请求它，仍然会得到响应。
- **路径按传入的原样比较。** 不做 Unicode 规范化，也不做大小写折叠。所以如果客户端拼写名称的方式和请求时不一样，是找不到的。

## 另请参阅 {#see-also}

- [sabnzbd.md](sonarr-radarr.md) — 将 Sonarr 和 Radarr 指向 zurg，这正是 `__magic__` 的设计初衷
- [DMM wanted list](dmm-wanted.md) — 在 DMM 上点击 Want，zurg 就会把它抓取到 `__movies__`、`__shows__` 或 `__anime__` 中
- [usenet.md](usenet.md) — 这些抓取内容最终落地的 NZB 后端
- [config.md](../reference/config.md#__magic__-a-directory-you-can-organise) — `magic:` 配置块中的每一个键
