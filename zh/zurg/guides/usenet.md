# 使用 zurg 访问 Usenet {#usenet-with-zurg}

zurg 的 `nzb` 后端会把 `.nzb` 文件变成一个挂载的媒体库。它没有下载器，也没有已完成文件夹。
播放前不会下载任何内容。它把 NZB 和有大小上限的缓存保存在 `data/bytecache` 和 `data/par2` 中，外加索引记录。`nzb_article_disk_cache_mb` 默认为 512 MiB。拖动进度时，zurg 只获取覆盖那些字节的文章。一个 60 GB 的 remux 并不需要 60 GB 的磁盘空间。

Usenet 与 debrid 后端使用相同的库过滤器、挂载和媒体服务器集成。Usenet 资源可以和 Real-Debrid 或 TorBox 的内容并存。你也可以只使用 Usenet。

**支持多个 Usenet 提供商。** 一个 `nzb` 条目可以包含任意数量的新闻服务账号——提供商数量不限，付费或免费账号都可以，你有多少就用多少——zurg 会逐篇文章依次尝试这些账号。这一点比通常的冗余更重要：保留期是按提供商计算的，所以多一个账号，往往就是多拉一次文章和从 PAR2 重建整个资源之间的区别。参见 [使用多个 Usenet 提供商](#more-than-one-usenet-provider)。

本指南介绍如何配置新闻服务账号、NZB、挂载以及 Plex。

| | |
|---|---|
| 配置参考 | [config.md → Usenet accounts](../reference/config.md#usenet-accounts) |
| 仪表盘 | `http://localhost:9999/config/` → Essentials → Providers |
| 代码位置 | `internal/nzb`（后端）、`internal/nntp`（新闻客户端）、`internal/par2`（修复计算） |
| 监视目录 | `nzbs/`，位于 zurg 的工作目录中（Docker 中为 `/config`） |
| 修复缓存 | `data/par2/` |
| 已解析的文件名 | `data/nzb-names/`，这样混淆过的资源只需读取一次文件名，而不是每次重启都读取 |
| 文章索引 | `data/nzb-index/`，在 `nzb_segments: mmap` 下使用——这是 Linux、macOS 和 BSD 上的默认设置 |

---

## 你需要准备 {#what-you-need}

- **至少一个 Usenet 提供商账号。** 保留时长（retention）最重要。4000+ 天的提供商仍然保留着 1000 天的提供商已经过期的帖子。你套餐的**连接数上限**是第二个要了解的数字，zurg 会读取这个值来决定如何连接。
- **如果有更多账号，就多加一些。** 再加一个位于不同骨干网的无限量提供商，或者一个便宜的块账号来补缺，是提升 Usenet 配置价值最高的做法。参见[使用多个 Usenet 提供商](#more-than-one-usenet-provider)。
- **NZB 文件，或者能帮你获取它们的工具。** 从你的索引站下载 NZB，然后放进 `nzbs/` 目录。或者开启 [SABnzbd 兼容接口](sonarr-radarr.md)，让 Sonarr 和 Radarr 把 NZB 交给它。它会写入同一个目录。zurg 自己也能搜索你的 Newznab 索引站。在你于 [Stremio](stremio.md) 中点击播放时会这样做。对于你观看列表和 Seerr 以及 \*arrs 通过[获取功能](acquisition.md)发出的请求，它同样会这样做。Debrid 账号的种子有自己的接口，兼容 [qBittorrent](sonarr-radarr-torrents.md)。
- **zurg**，如果你想要文件系统挂载而不是直接使用 WebDAV，还需要 `rclone`。zurg 首次运行时会为你下载 rclone。

---

## 1. 配置新闻服务器账号 {#1-configure-your-news-accounts}

每个 zurg 账户在 `providers:` 下都是一个条目。Usenet 账户使用服务器凭据而不是 API 令牌进行认证，所以它包含 `nntp` 块而不是 `token`：

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

就这些。如果你还有 debrid 账户，可以加在它旁边：

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| 键 | 默认值 | 说明 |
|---|---|---|
| `host` | *(必填)* | 新闻服务器。缺失或为空会导致启动错误。 |
| `port` | 启用 TLS 时为 `563`，否则为 `119` | |
| `tls` | `false` | 建议开启。明文 NNTP 会以明文发送你的密码，以及你的读取记录，路径上的任何人都能看到。 |
| `username` / `password` | `""` | |
| `connections` | `8` | **请设置为你套餐的实际额度。** 这不是一个可以随意客气对待的速率限制：单个连接只能承载服务商吞吐量的一小部分，所以 zurg 会按这个数值读取。设置过低会导致串流很慢；超过套餐限制，服务器就会开始拒绝连接。 |
| `warm_connections` | `4` | 保持打开的空闲、已认证连接，这样读取时就不用等待建立新连接。一次建连大约需要 0.8 秒，包括 TCP、TLS、问候和 `AUTHINFO`。如果没有这个下限，每次启动和每段空闲期之后，都要在按需读取时付出这笔开销。这些连接占用的是 `connections` 中的名额，而不是额外增加的：套餐会把它们计为打开的连接，zurg 也会定期发送 `DATE` 来保持它们存活，所以下限不能超过额度。`-1` 表示不保留任何连接，这适合按连接时长计费的套餐。顶层的 `warm_connections` 会为没有设置该项的账户提供默认值，参见 [预热连接](../reference/config.md#warm-connections)。 |
| `cache_size_mb` | `512` | 保存在内存中的已解码文章数据。它在所有正在读取的文件之间共享，而不是每个文件各占一份。 |
| `servers` | `[]` | 更多的新闻账户，参见 [多个 Usenet 提供商](#more-than-one-usenet-provider)。 |

配置校验器会强制执行以下两条规则：

- **只能有一个已启用的 `nzb` 提供商条目。** 两个条目会各自扫描同一个 `nzbs/` 目录，导致每个发布内容都被重复。这并不限制你能使用多少个 *Usenet 提供商*：额外的新闻账户应放在该条目的 `nntp.servers` 下，它们服务的是同一个库，而不是再复制一份。
- **`watchlist: true` 无法指向它。** Usenet 后端无法添加内容，因此它永远不能成为 Plex 观看列表添加内容的目标账户。

### 使用多个 Usenet 服务商 {#more-than-one-usenet-provider}

保留度是按供应商分别计算的。多取一次和整个发布做一次 PAR2 重建之间的差别，就在于另一个账号是否还保存着这篇文章。这就是为什么在这里，第二个账号比普通的冗余更有价值。

`nntp` 块中已有的配置项描述的是第一个账号。`servers` 下的任何条目都是另一个账号。相同 `priority` 的账号分担负载，数字越大的账号只有在数字更小的账号之后才会被询问，而 `backup` 账号只有在所有主账号都未能送达这篇文章之后才会被使用。现有的单账号配置无需任何改动即可继续工作：

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

每个账号都保留自己的连接数上限，读取操作由最低的可用 `priority` 上所有非备用账号的合计连接数来驱动。在上面的例子中就是 30 + 20 = 50，两者都使用默认的 `priority`。因此，在同一 `priority` 下再加一个不限量的供应商，既能带来保留度保险，也能提升吞吐量。而 `backup` 账号两者都不提供，这是有意为之：它只承载主账号无法提供的内容。如果把它的连接数算进去，每个读取预读窗口都会变大，而稳定播放时根本用不到这部分容量。

下表中的三个配置项决定了由谁来被询问：

| 键 | 默认值 | 作用 |
|---|---|---|
| `name` | `host` 的值 | 在日志中标识该账号。 |
| `priority` | `0` | 决定先问谁，数字越小越先被问。相同 `priority` 的账号按书写顺序被询问，但如果某个账号还有空闲连接，就优先选它，而不是选连接数已用完的账号，因此两个条件相同的账号会分担负载，而不是排队等待同一个账号。 |
| `backup` | `false` | 将账号标记为按量计费的块账号。只有当所有主账号都表示缺少该文章、发来了损坏的副本、中途失败或无法连接时，才会去询问它。主账号仅仅是**忙碌**还不够：zurg 会等待主账号，而不会去花费按量计费的流量来获取一个不限量账号本可以提供的内容。 |
| `backbone` | `""` | 指定该账号所对应的文章存储池名称。两个位于同一 backbone 上的账号保存的是相同的文章，因此一旦其中一个表示缺少某篇文章，同一存储池上的其他账号就会被跳过，而不会为同一个答案再多付出一次往返请求。 |

每个账号还会从自己的连接数中留出一个专属的预热下限。保留度缺口会直接绕过主账号，因此第一次被用到的账号，恰恰是最没有人预先建立过连接的那个。两个连接的按量计费账号可以通过 `warm_connections: -1` 设置为不保留预热连接。

转售非常普遍，所以值得填写 `backbone`。你从不同公司购买的两个账号，可能位于同一个存储池上。如果不填，每次缺失都会被请求两次。分组名称随你取，这个字符串只会和其他条目做比较。

zurg 启动时会列出它将使用的每个账号：

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

用来判断某个发布是否需要修复的清点过程，会在认定文章缺失之前询问每一个账号，并且每个账号只询问其前面的账号所缺少的那部分内容。传输失败绝不会被误认为文章已过期：如果某个账号超时，或者在传输中途丢失了文章，报告的就是这个失败。这样，超时就不会导致静默地提供内容，也不会为本来并未丢失的内容安排修复。完全无法连接的账号不计入结果：如果另一个账号表示文章已不存在，那就按已不存在处理。

### 在 Dashboard 中配置服务商 {#configuring-providers-in-the-dashboard}

`http://localhost:9999/config/` → **Essentials** → **Providers** 可以完成同样的操作，无需编辑 YAML。表格会按照 config 中的顺序列出每个账户：

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

对于 `nzb` 行，Token 列显示的是**新闻服务器主机**，而不是 token 提示，因为这里没有需要隐藏的 token。后面会显示它还有多少个额外的新闻服务器。

**添加 Usenet 账户：**

1. 点击 **Add provider**。
2. 把 **Type** 设为 `nzb`。token 字段会消失，NNTP 字段会出现在原来的位置。
3. 如果不想用 `nzb` 这个名字，就在 **Name** 里填一个别的。它会作为每个账户的目录名，所以这里填 `usenet`，挂载后的路径就是 `__usenet__`。不填则保持为空。
4. 填写 **NNTP host**、**Port**、**TLS**（默认勾选，保持开启即可）、**Username**、**Password**、**Connections**（占位符为 `8`，请填写你套餐实际允许的数量）和 **Cache size MB**（占位符为 `512`）。
5. **Watchlist target** 保持不勾选。后端无法添加内容，勾选后保存会被拒绝。勾选 **Disabled** 可以让这一项保留在 `config.yml` 中，但不加载。
6. 点击 **Save**。

表单会像真的应用了修改一样做校验，所以出错时会弹出提示，而不会写出一个损坏的配置。如果你想添加**第二个** `nzb` provider，表单会拒绝保存。错误信息会引导你去 **Further news servers**（或 `nntp.servers`），额外的新闻账户应该加在那里。

**添加另一个新闻服务器**（第二个账户，或另一个骨干网上的 block 账户）：在 `nzb` 那一行点击 **Edit**，然后在 **Further news servers** 下点击 **Add news server**。每个服务器都有自己的 **Name**、**NNTP host**、**Port**、**TLS**、**Username**、**Password**、**Connections**、**Priority**、**Backbone** 和 **Backup only**。点击 **Remove server** 可以删除其中一个。点击 **Save** 会把所有服务器写入 `nntp.servers`。

**编辑某一项**：点击该行的 **Edit**。表单会加载所有内容，但不包括密码。第一个账户和每个额外服务器的密码都会留空，留空表示*保留现有密码*，只有想修改时才需要输入新密码。表单中没有对应字段的设置，会按照 `config.yml` 中的原样保留。

**Delete** 会先要求确认，然后从 `config.yml` 中删除该 provider 条目。它不会影响你的 `nzbs/` 目录。NZB 文件会保留在原处，并随 provider 一起恢复。最后一个已启用的 provider 既不能删除，也不能禁用。

这里的每次修改都会直接写入 `config.yml`，并显示：

> Provider changes saved to config.yml — restart zurg to apply

Provider 的修改**不会**热加载。请先重启 zurg，再期待任何变化生效。

---

## 2. 启动 zurg 并确认账号 {#2-start-zurg-and-confirm-the-accounts}

+++ Linux 和 macOS
```bash
./zurg
```
+++ Windows
```powershell
.\zurg.exe
```
+++

如果 `zurg setup` 把 zurg 设置成了开机自启，请改用 `zurg service restart` 重启它（Linux/macOS 用 `./zurg service restart`，Windows 用 `.\zurg.exe service restart`）。

zurg 会在启动时验证一次新闻组账户，因为密码错误否则要等很久之后才会表现为所有文件都无法播放：

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

如果全部失败，报错同样很明显：

```
Cannot reach the news server for nzb: <reason>
```

先检查端口和 TLS 是否配对正确（`563` + `tls: true`，或 `119` + `tls: false`），再检查凭据，最后确认套餐是否真的处于激活状态。

**有多个账户时，要看警告，不要只看 connected 那一行。** 每个无法连接的账户都会单独显示一条警告，只要*有一个*账户能响应，启动就会继续，上面那个错误只会在所有账户都无法连接时出现。所以如果第二个服务商已经失效，启动看起来仍然正常，除非你留意到这些警告：

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. 添加 NZB 文件 {#3-add-nzb-files}

zurg 启动时会创建 `nzbs/` 监视文件夹。这个文件夹位于 zurg 运行所在的目录里。把 NZB 文件复制到其中即可。

+++ Linux 和 macOS
```bash
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```
+++ Windows
```powershell
Copy-Item "$HOME\Downloads\Some.Release.2024.2160p.nzb" nzbs\
```
+++

一两秒内 zurg 就会发现该文件并读取它，读取完成后库里就会立即列出它。日志会显示它读取了什么：

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### 出现的速度 {#how-quickly-it-appears}

zurg 每秒大约检查一次 `nzbs/` 目录本身，每次检查只需一次系统调用，不管目录里有多少个 NZB。所以文件一放进去，几乎马上就会被读取，而不用等下一次媒体库变动检查。一个[混淆过的发布](#obfuscated-releases)会慢一点，因为它真正的文件名必须先从它自己的文章里读出来，这通常在一秒之内完成，完成后就会立刻被列出。现在这两个等待都不再依赖 `check_for_changes_every_secs`。以前是依赖的：混淆发布被放进去后，要等最多两个完整间隔才会出现，一个是等目录被读取，另一个是因为文件名是在那次能发现它的检查刚过之后才解析出来的。在间隔为 10 秒的情况下测过，从放入到发布出现共用了 17.7 秒，其中实际工作只占 0.67 秒。

定期检查依然保留，仍然是兜底。它用来捕捉被监视目录自己无法报告的两种情况：一个 NZB **在原位被替换**，用的还是它原来的名字；以及某些文件系统的目录时间戳精度太粗，无法区分同一秒内发生的两次变化。

### 会被识别的内容 {#what-gets-picked-up}

- 直接位于 `nzbs/` **目录下**、文件名以 `.nzb` 结尾的文件（不区分大小写）。
- **会跳过子目录。** `nzbs/movies/foo.nzb` 不会被识别。请直接平铺放置，不要分类存放——库的组织方式由目录过滤器决定，而不是由这个文件夹决定。
- **仅支持纯 XML。** `.nzb.gz` 不会被解压，也不会被读取；请先解压再使用。
- 解析失败的文件会被跳过并给出警告，不会中断扫描。

### 发布的名称是什么 {#what-the-release-is-called}

zurg 显示的名称（也就是 Plex 看到的文件夹名）是：

1. NZB 自带的 `<meta type="name">` 值（如果有，且经过清理后仍然保留）；否则
2. **去掉 `.nzb` 后缀的文件名**。

所以大多数情况下，*NZB 的文件名就是发布名称*。请像给发布命名那样给文件起名，因为媒体服务器会用它来匹配：

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/indexer_download_48213.nzb
```

如果两个不同的发布最终重名，zurg 会用一个简短的哈希标签来区分它们（`Some.Release {a1b2c3}`），这和 zurg 其他地方的做法一样。

### 有密码保护的发布 {#password-protected-releases}

如果索引器把压缩包密码记录在 NZB 的元数据块中，zurg 在从 RAR 分卷中串流时就会使用它：

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

不需要其他设置。如果受密码保护的资源其 NZB 中没有密码元数据，就无法打开。

### 混淆的发布 {#obfuscated-releases}

对于文件名随机的帖子，zurg 会处理，代价是在扫描时一次性付出。zurg 会先尝试较便宜的来源：文章自己的 yEnc 头里仍然声明的文件名，每个文件对应一篇文章。如果这一步不行，它就退回到发布的 PAR2 索引，该索引记录了每个文件的真实名称，以及其前 16 KiB 的 MD5。文件名和精确长度都在文章头部里，所以扫描在头部到达时就能给出结果，而正文会继续写入缓存，供之后读取。因此，即使是混淆过的发布，也能由同样的文章确定名称和大小。它会记录恢复出的内容：

```
Recovered 27 filename(s) in Some.Release
```

整个命名过程对每个 NZB 限时 90 秒，所以服务器无法连接时只会拖慢扫描，不会让它卡死。名称会在库据此建立*之前*确定，因为库是按文件名来索引文件的，之后再改名会导致这些文件丢失。

**完全混淆的帖子没有可以恢复的真实名称。** 有些发布者在建立恢复集之前就做了混淆，所以 PAR2 索引恢复出来的名称本身也是随机的（例如 `aJPSgA7eYizyzjJXT.part01.rar`），压缩包里的文件同样是一串哈希。帖子里的任何信息都说明不了这是什么发布，只有 NZB 自己的名称能说明。因此，zurg 会用发布名称来呈现这些内容，这和 SABnzbd 在解压结束时做的事一样：

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

只有明显属于该发布的文件会被重命名：压缩包中最大的条目，并且只有当它至少是下一个条目的三倍大时才会改名。它的扩展名不能是光盘结构的一部分（`.vob`、`.m2ts`、`.mpls`），而且它的名称不能包含任何有意义的信息。与它同名的字幕和样本文件会跟着它一起改名。包含多个大小相近文件的压缩包，例如整季合集，会保持不动，因为其中没有任何一个文件能代表整个发布。压缩包内原有的文件名仍然可以作为访问地址使用，所以在重新扫描之前就已经开始播放的播放器，不会丢失这个文件。

### 替换和删除 {#replacing-and-removing}

- **Removing** an NZB from `nzbs/` removes the release from the library, drops its cached reader and article cache, and forgets any repaired bytes it held.
- **Deleting a Usenet release from the Dashboard deletes the `.nzb` file from disk.** There is nowhere else for it to live. This is not the same as deleting a torrent from a debrid account, where the file stays on the service.
- **Replacing an NZB in place is the slow way to do it.** Writing over a file does not change the directory, so the watch above cannot see it; what notices is the periodic change check, which reads the file's modification time and re-parses it — up to the first `check_for_changes_every_secs` check that comes more than 15 seconds after the last directory read (about 30 seconds at the default). Removing the old file and adding the new one is noticed within a second or two, and is what an indexer or the SABnzbd endpoint does anyway.

## 4. 发布内容在挂载中的位置 {#4-where-releases-land-in-the-mount}

Usenet 发布内容和普通的库条目一样，所以你现有的 `directories:` 过滤器可以原样用在它身上：

```yaml
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

除此之外，这个账户还会多一个自己的目录：默认是 `__nzb__`，如果你在 provider 条目里设置了 `name:`，就是 `__<name>__`。这个目录不只是个视图：在它下面的读取会**固定**走 Usenet 账户，不会故障转移，所以它是测试 Usenet 播放能否正常工作（而不是悄悄由某个 debrid 账户来响应）的最佳位置。如果 Usenet 是你唯一的账户，挂载的根目录列表里就不会显示这个文件夹，而 `__all__` 包含相同的文件，所以请在挂载点的 `__all__` 下测试播放，或者直接打开 HTTP 路径 `http://localhost:9999/http/__nzb__/`。

使用 Usenet 编写过滤器时，有四点需要注意：

- **标签过滤器会在 Usenet 内容分析完成后生效。** 每个 `zurg_*` 标签（分辨率、HDR、码率、时长、语言）都来自 ffprobe。zurg 会自己通过自带的服务器、以新闻服务器能承受的速度对 Usenet 文件运行 ffprobe，因此 Usenet 发布内容在分析完成后，和其他内容一样能拿到标签。在此之前，以 `tags_match_any` 为条件的目录不会收录它。
- **`.par2` 和 `.sfv` 文件会被隐藏。** 它们是修复用的辅助文件；zurg 自己会读取它们，而且一个整季合集里有八个这样的文件，媒体服务器根本用不上。`.nfo` 会保留，因为 Kodi、Emby 和 Jellyfin 会读取它。
- **RAR 分卷是内容，而不是需要解压的压缩包。** `.rar` 和 `.rNN` 保持可见，一组分卷会在挂载点中以一个*文件夹*的形式出现，文件夹里就是压缩包内的文件——zurg 直接从压缩包中串流视频，无需解压。如果一个发布内容*只有*一组分卷，那它会直接以内容本身的形式呈现，中间不会有压缩包文件夹：正片直接位于发布文件夹中，这也是媒体服务器查找文件的位置。与分卷一同发布的文件——`.nfo`、发布者的 `.txt`、海报图、字幕——同样会列在那里。
- **`force_select_playable_files` 不适用于此。** 一个 Usenet 帖子是完整的，没有什么需要挑选的。所有内容文件都已经提供给你了。

在接入媒体服务器之前，先浏览一下结果。`http://localhost:9999/http/` 是一个纯 HTML 索引，准确显示挂载点将会呈现的内容：

+++ Linux 和 macOS
```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```
+++ Windows
请输入 `curl.exe` 而不是 `curl`：在 Windows PowerShell 5.1 中，`curl` 只是 `Invoke-WebRequest` 的别名。

```powershell
curl.exe -s http://localhost:9999/http/__nzb__/ | Select-Object -First 10
```
+++

---

## 5. 使用 rclone 挂载 {#5-mount-it-with-rclone}

### 简单方式：让 zurg 运行 rclone {#the-easy-path-let-zurg-run-rclone}

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg 会用为自己读取模式预先调好的 VFS 配置来启动 rclone（缓冲区大小、分块大小、缓存模式、目录缓存时间、超时），保持挂载在线，并在库发生变化时让正确的 dircache 条目失效。`mount_path` 同时也是 zurg 告诉 Plex 该扫描哪些路径时使用的前缀，所以即使你挂载到别处，也必须设置它。

验证：

+++ Linux
```bash
ls /mnt/zurg/
ls /mnt/zurg/__all__/
```
+++ macOS
```bash
ls /Volumes/Zurg/
ls /Volumes/Zurg/__all__/
```
+++ Windows
在桌面上打开 PowerShell 窗口运行：这个盘符只在挂载它的登录会话中可见（[会话规则](../setup/windows.md#keeping-it-running-the-session-rules)）。

```powershell
Get-ChildItem Z:\
Get-ChildItem Z:\__all__\
```
+++

### 手动方式：使用你自己的 rclone {#the-manual-path-your-own-rclone}

如果你已经在用 rclone，可以把一个 WebDAV remote 指向 zurg：

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

+++ Linux
rclone 不会创建挂载点，而 `/mnt` 属于 root：

```bash
sudo mkdir -p /mnt/zurg && sudo chown "$USER" /mnt/zurg
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ macOS
需要 [macFUSE](../setup/macos.md#step-1-install-macfuse) 和来自 [rclone.org](https://rclone.org/downloads/) 的 rclone：Homebrew 安装的 rclone 无法挂载。rclone 不会创建挂载点，而 `/Volumes` 属于 root：

```bash
sudo mkdir -p /Volumes/Zurg && sudo chown "$USER" /Volumes/Zurg
rclone mount zurg: /Volumes/Zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ Windows
需要 [WinFsp](https://winfsp.dev)。盘符不能被占用，而且只有与运行 rclone 处于同一个登录会话中的程序才能看到它（[会话规则](../setup/windows.md#keeping-it-running-the-session-rules)）。

```powershell
rclone mount zurg: Z: --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++

`--vfs-handle-caching 0` 需要 rclone 1.74 或更新版本。它会让 rclone 在读取器关闭文件后不再多下载五秒。如果省略它会有什么代价，可以看 README。

仍然要把 `config.yml` 里的 `mount_path` 设为你实际挂载的位置，否则媒体服务器的扫描通知会基于错误的前缀生成。

### Docker

zurg 在镜像里的工作目录是 `/config`，监视目录和修复缓存都位于其下。一个绑定挂载就能把它们和其他所有内容一起带进容器：

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./:/config
    ports:
      - 9999:9999
```

这样，你把 NZB 放进宿主机上的 `./nzbs`，容器里无需重启就能识别到。

这种挂载需要 Linux 宿主机。macOS 和 Windows 上的 Docker Desktop 会把容器运行在虚拟机里，挂载无法被 Finder、Explorer 或者安装在宿主机上的 Plex 看到。这种情况下请改用 [macOS](../setup/macos.md) 或 [Windows](../setup/windows.md) 版本的可执行文件（[原因](../setup/docker.md)）。

> 在 `/config` 之前安装的用户，当时是分别把 `/app/config.yml`、`/app/nzbs` 和 `/app/data` 单独挂载的。这些安装会继续像以前一样正常工作，详见 [docker.md](../setup/docker.md#upgrading-an-install-that-mounted-app)。

---

## 6. 将 Plex 指向它 {#6-point-plex-at-it}

这里除了最后一小节，其他内容都不是 Usenet 专属的，但顺序很重要。

1. **把你的 Plex 凭据告诉 zurg**，这样 zurg 就能让 Plex 只扫描发生变化的路径，而不用你等待定期的全量扫描。最简单的方法是通过 Dashboard 的 Plex 授权流程，它会把值写回 `config.yml`：

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **添加指向挂载目录子文件夹的媒体库**，千万不要指向挂载根目录：

   - Movies → `/mnt/zurg/movies`（macOS 上为 `/Volumes/Zurg/movies`，Windows 上为 `Z:\movies`）
   - TV Shows → `/mnt/zurg/shows`（macOS 上为 `/Volumes/Zurg/shows`，Windows 上为 `Z:\shows`）

   在 Windows 上，只有 Plex 和 zurg 运行在同一个登录会话中，Plex 才能看到 `Z:`。`zurg setup` 创建的登录计划任务就能做到这一点。详见[会话规则](../setup/windows.md#keeping-it-running-the-session-rules)。

   同一个版本会出现在每个筛选规则匹配它的目录中，也会出现在 `__all__` 和 `__nzb__` 下。如果你让 Plex 指向根目录，它就会把同一批文件重复扫描好几遍。

3. **在每个媒体库的 Edit → Advanced 中设置两个选项**：

   - **取消勾选 "Empty trash automatically after every scan"。** 这是最关键的一项。如果 Plex 扫描时挂载突然断开，比如 zurg 重启或者 rclone 重新挂载，Plex 就会认为所有文件都被删除了。开启自动清空后，这些文件会立刻被永久删除；关闭后，它们只会留在回收站里，等挂载恢复时再回来。之前就有人因此丢了一个 30,000 项的媒体库。
   - **取消勾选 "Generate video preview thumbnails"。** 每张缩略图都要在整个文件里定位一次，对于 Usenet 来说，这相当于通过你的连接额度完整读取一遍该版本。

4. **Plex 扫描期间绝对不要重启 zurg。** 重启前先检查一下：

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   在 Windows 上，请在 zurg 文件夹中打开 PowerShell 运行：

   ```powershell
   $TOKEN = ((Select-String -Path config.yml -Pattern '^plex_token:').Line -split '\s+')[1].Trim('"', "'")
   (Invoke-RestMethod "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN").MediaContainer.size
   @((Invoke-RestMethod "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN").MediaContainer.Directory | Where-Object refreshing -eq 1).Count
   ```

   如果 sessions 那一行显示 `size="0"`（Windows 上为 `0`），并且计数不断刷新且为 `0`，就可以安全重启。如果 sessions 那一行完全没有输出，说明 Plex 拒绝了令牌或者没有响应，下面的 `0` 毫无意义，请先检查 `plex_token`。（PowerShell 会把这种拒绝显示为 `401` 错误。）（请使用 `grep -o … | wc -l`，不要用 `grep -c`：grep 在没找到内容时会以非零状态退出，而这恰恰是*正常*情况，它会打断 `&&` 链，导致本应被保护的重启命令无法执行。）

5. **部分扫描。** `on_library_update` 会收到每一条发生变化的路径；仓库根目录下的 `plex_update.sh` 是参考脚本：

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

   该脚本需要 `curl`、`xmllint` 和 `python3`，Docker 镜像中都已包含。还需要把脚本中的 `zurg_mount` 一行设为你的挂载路径。在 Windows 上，hook 通过 PowerShell 而不是 `sh` 运行，所以这个脚本在 Windows 上无法使用。每条变化的路径都会作为 `$args` 中的一个元素传入，路径相对于挂载点，使用正斜杠（`movies/Big Buck Bunny`）。用 `@args` 把它们传给 PowerShell 脚本即可：

   ```yaml
   on_library_update: '& C:\zurg\my_update.ps1 @args'
   ```

   完成第 1 步并设置了 `mount_path` 之后，zurg 就会在变化的路径上自动请求 Plex 扫描，所以只有在其他情况下才需要 hook。

**Usenet 内容在 Plex 中暂时拿不到的信息：** 在 zurg 分析完成之前（见第 4 节），这些内容没有任何信息，因此首次播放时 Plex 可能会像处理任何本地文件一样自行分析。版本扫描完成后，文件大小很快就会稳定：第一次列出时，可能显示根据文章数量估算的大致值，之后再显示精确长度。精确长度来自恢复索引（如果有的话），否则就从每个文件的一篇文章中获取。对于一个大型分卷压缩包，如果它的恢复索引已经给出了每个文件的精确长度，那么校验通过的一个分卷就能确定共享的文章步长。之后每个同级分卷在返回第一个字节前，都会用自己的文章头来核对这个推断。长度一旦确定，媒体库就会被通知该版本已变化，挂载和 Plex 都会看到真实长度。在连接数为 12 或更少的账户上，zurg 一次最多计算 8 个版本的大小（且不会超过账户的连接数）；连接数更多的账户可以同时计算更多（16 个连接时为 12 个，20 个或以上时为 16 个）。当获取流程需要向新闻服务器核对某个版本时，这次核对会排在这些大小计算和预读之后排队，并且绝不会占用播放器正在等待的那条读取连接。

### Jellyfin / Emby / Infuse

Jellyfin 和 Emby 使用 `jellyfin_server_url` / `jellyfin_token` 以及 `emby_server_url` / `emby_token`，收到的扫描通知相同；详见 [jellyfin.md](jellyfin.md)。Infuse 可以直接指向 `http://<host>:9999/dav/`，完全不需要 rclone。

## 7. 当某个文章缺失时 {#7-when-an-article-is-missing}

这正是 Usenet 会遇到的问题，debrid 则不会。文章会因为服务商的保留期到期或被下架而消失，一个发布可能在列表里显示正常，但其中几篇文章已经没了。

zurg 的应对方式，按优先级排列：

1. **问问另一个新闻服务器。** 一个服务商已经过期的文章，通常在另一个服务商那里还能找到。这只需要一次获取，详见 [More than one Usenet provider](#more-than-one-usenet-provider)。
2. **用发布自带的 PAR2 文件重建。** 这些文件本来就是为此发布的。但代价很高：Reed-Solomon 需要读取每一个幸存的分片，才能算出缺失的那一块。所以一个 200 GB 的发布，要读 200 GB，才能恢复几 MB 的数据。
3. **返回空白数据。** 只有前两种方法都无法解决时才会这样做。

PAR2 修复是后台任务，同时最多只处理两个发布，并且需要：

```yaml
enable_repair: true            # the default; set false to turn PAR2 repair off
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

重建出的数据会写入 `data/par2/<nzb-id>/`，下次打开文件时会直接读取，所以重启后不需要把整个发布重新读一遍。只保留真正缺失的部分，一次损坏通常只占几 MB。超出预算时，会按最近最少使用的顺序删除整个发布的数据。每个发布的修复数据都会打上它所依据的 NZB 的修改时间戳。如果 NZB 被重新保存，这些数据就会被丢弃，而不会在可能已经变动的偏移位置上提供字节。

一次修复开始时会有提示，结束后会告诉你它花了多少成本：

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s on the avx2 kernel, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

有两点值得注意：

- **播放永远优先于修复。** 连接按等待的先后分配：先处理播放时的即时读取，然后是预读，修复排在最后。不过，修复相对于预读会保证拿到四分之一的连接额度，所以正在播放的文件仍然可以修复卡住它的那段空缺。
- **zurg 的库级修复在这里帮不上忙。** 那个机制是把种子重新添加到它原来所在的账户里。如果后端无法添加内容，它只能报告发布已损坏，却无法修复。对于 Usenet 来说，PAR2 就是修复手段。

如果一个发布的 NZB 里没有 PAR2 文件，而且你也没有第二个新闻账户，那它就完全没有恢复途径。这是发布本身的问题，不是 zurg 的问题。

## 性能 {#performance}

以下是与实时新闻服务器（连接数很多的账号）对比的测试结果：

| | |
|---|---|
| 单流，直接文件 | ~100 Mbit/s |
| 单流，来自 RAR 分卷 | 90–106 Mbit/s |
| 两个并发流，合计 | ~124 Mbit/s |

连接数上限决定了单流速率的第一道天花板。zurg 会按文章数和字节数来设置预读量，让连接数始终保持满载：小文章的压缩包帖子至少预读 64 MiB，多 MB 的帖子则保留原有的连接数和流水线窗口。所以：

- **把 `connections` 设成你套餐的真实连接数。** 这是最关键的调优项。只有八个连接是无法流畅播放 remux 的。
- **两个主账号的连接数会叠加。** 读取速率按照与最低且有效的 `priority` 相同的非 `backup` 账号的连接数总和来驱动。所以在同一优先级下再加一个不限量的服务商，既能提高上限，也能补上第一个账号的保留期空缺。`backup` 账号不计入其中。
- **`warm_connections`（默认 4）提升的是延迟，不是吞吐量。** 它会保持这么多个连接处于已打开、空闲且已认证的状态，因此在启动或长时间空闲后，第一次读取不必再花约 0.8 秒拨号才能收到第一个字节：冷启动到首字节需 1.5 秒，热连接只需 0.15 秒。流一旦开始运行，它就不再有任何作用。
- **实际发生的拨号会固定到同一个后端，因此它们的 TLS 会话可以恢复。** 一次拨号大约耗时 0.8 秒，这是 2026-08-29 在一台实时新闻服务器上测得的：TCP 106ms，TLS 握手 213ms，欢迎信息 256ms，两次 `AUTHINFO` 交换共 218ms。服务商的主机名是轮转的（这个主机名会解析出 11 个地址），而 TLS 会话票据只在签发它的那台机器上有效。因此，如果每次都重新拨号到 DNS 解析器返回的第一个地址，只有 **0/3** 个会话能恢复；而重新拨号到同一个地址，则 **3/3** 都能恢复。现在每个账号都会重新拨号到它上一次连接所用的地址，这样**每次重新拨号都能节省 110–140ms**：恢复的握手耗时 109–141ms，而完整握手需要 225–261ms。往返延迟约 18ms 的服务器节省的时间会少一些。一旦该地址停止响应，固定就会被解除，主机名会重新解析，因此不会卡在服务商已经退役的机器上。但如果拒绝信息来自 NNTP，比如账号已达连接上限或密码被拒绝，则会保留固定，因为这是账号本身的应答，而不是后端的问题。每次拨号都会在 debug 级别记录各阶段的耗时，包括 `resumed=`。
- `cache_size_mb`（默认 512）由所有正在读取的文件共享。如果你同时运行多个流，可以调高它；但它不会让单个流变快。推测性读取最多只能占用其中的一半，并且最多给两个读取者使用，剩下的一半留给已经读取或即将读取的文章。
- 一个发布版本是以 RAR 打包还是以普通文件发布，对吞吐量已经没有太大影响。

**单篇文章变慢，不再拖住整个流。** 顺序读取时平均约 90 MB/s，但仍会每次掉到 1–5 MB/s，持续约一秒。每次掉速都是同一个原因：其他连接已经完成了它们的文章并进入空闲，而某一篇文章却迟迟没有到达。当一次读取在某篇文章上等待的时间超过该读取者已习惯的时长时，zurg 会向**第二个连接**请求同一篇文章，并使用先到的那个结果。由于流水线中一批卡住的请求可能会在同一个失效的 socket 上阻塞播放位置之后的多篇连续文章，因此来自同一读取者的最多 5 篇不同文章可能会一起被对冲；如果是单篇小于 1 MiB 的文章的帖子，则最多一两篇。同一篇文章绝不会被请求两次。账号每分钟最多只为第二次请求付费 20 次。截止时间仍为该读取者最近等待时间的两倍，下限为 250 ms（单篇文章小于 1 MiB 的帖子为 125 ms），上限为 2 s。只有客户端真正在等待的读取才会被对冲，预读、下一卷的预取和修复都不会。服务器刚刚*拒绝*的文章也不会被对冲：这类文章一秒后就会等待自己的确认，在这段窗口内再次请求并不能说明什么。每次对冲会在 debug 级别记录一行，说明这次读取阻塞了多久；紧随其后的一行会说明第二次请求是否获胜。

对于已声明的范围，播放位置处的文章会先进入优先级调度器，然后才会提供后续字节。流水线连接接下来会被分配连续的文章轮次，而不是连续的数据块，因此最早可用的文章会分散到整个连接数上。至少 64 MiB 的请求会被视为播放，并获得完整的范围前沿；较小的跳转仍然只是探测，只会打开一个较窄的预热区间。

### 跨越卷边界 {#crossing-a-volume-boundary}

RAR 集里的文件是一卷一卷地播放的，每一卷都要向新闻服务器账号单独读取一次。zurg 会在当前卷还在播放时就打开下一卷，并读取它的前 4 MB，所以切换时不会从零开始。对于用小分卷发布的资源，光靠这段开头是不够的：4 MB 大约只有以 ~395 KB 分片发布的资源的十篇文章，而 ~26 MB 的分卷每隔 1.7 秒播放就会出现一个边界。这样一来，流会在四分之一秒内把内存里预热好的开头用完，然后还得等一个往返，才能拿到后面的数据。在 2026 年 9 月 8 日，我们用一台 Hetzner CCX23，通过十个连接做了测试。这个资源的播放速度是 **14–16 MB/s**，而同一账号上的普通文件能跑到 **86–99 MB/s**。它的每秒速率在 1 到 29 MB/s 之间大起大落，同时账号 60 个预读槽位中，有 46 到 55 个一直空着没用。

现在，当播放进度距离边界进入 32 MiB 以内时，zurg 会把下一卷预热到一整个预读窗口的深度。刚切换进入的那一卷，会保留它已经赚到的窗口，不会重新从两篇文章开始。播放头几秒内还够不着的卷，仍然只预热到开头，这样媒体库扫描（每个条目一个读取器，每个读几 MB）就不会把它永远读不到的每一卷都拉出一整个窗口。这些都不需要配置，也不会改变内存上限：一个账号同时仍然只占用两个预读窗口，即正在播放的那一卷和正在预热的那一卷，都包含在 `cache_size_mb` 之内。

修复本身就很慢，因为它要读完整个资源。但修复是以后台优先级运行的，速度受新闻服务器限制，而不是受 zurg 自己的计算限制。

### 内存：监视目录的开销 {#memory-what-a-watch-directory-costs}

NZB 就是一份文章列表,而一个大型库里的文章非常多。解析一个 NZB 时,会把每篇文章的 message id 及其偏移量保存在内存里,方便读取时查找。之前的版本会在进程的整个生命周期里保留所有这些数据。在一个包含 2,636 个 NZB、共 2760 万个 `<segment>` 元素的监视目录上测量,这部分占用了 **1.52 GB 的活动堆内存**,平均每篇文章约 58 字节,另外还要加上文章缓存。其中几乎没有一部分真正被用到:列表时只需要名称、大小和数量,只有真正在读取或修复的文件,才需要知道它的文章叫什么。

`nzb_segments` 决定 zurg 是否保留这些数据:

```yaml
nzb_segments: mmap             # mmap (default) | reparse | resident
nzb_segments_idle_secs: 120    # how long a release's articles are kept after the last read
```

- **`mmap`**:列表会写入 `data/nzb-index/<id>.bin`,需要时再把这个文件映射到内存。这样数据存放在页缓存中,而不是 zurg 的堆上,内存紧张时内核可以回收。**Linux、macOS 和 BSD 上的默认值。**会占用大致与列表本身相当的磁盘空间。
- **`reparse`**:一个 release 稳定下来后,列表会被释放,之后需要读取或修复时,再从磁盘重新读取并解析 NZB。不占用任何磁盘空间,这正是选它的理由:适合 `data/` 不能增长的主机。
- **`resident`**:所有文章列表始终保存在内存中。**之前的行为**,也是之前每个版本的做法。仍然支持,只是不再是默认值。

无论设置哪一种,列表操作都不会加载任何东西:文件的名称、大小和文章数量都不需要把文章列表放进内存就能返回。因此刷新库、指纹检查,以及 *arr 询问某个任务是否已经稳定,都不会增加开销。惰性模式的代价是:某个 release 在 `nzb_segments_idle_secs` 内(清理任务每 30 秒运行一次)没有被任何操作碰过,那么它的第一次读取会变慢。而且一个 release 的所有文件会一起加载,所以按顺序读取季度合集的 rar 分卷时,这个代价只付一次。

在一个包含 60 个文件、30,000 个分段的 release 上测量:

| | 每个 release 的堆内存 | 空闲 release 的首次读取 | 读取路径上每篇文章的耗时 |
|---|---|---|---|
| `resident` | 1.74 MB | — | 6 ns |
| `reparse` | 21.3 kB | 39 ms | 52 ns |
| `mmap` | 16.6 kB | 0.27 ms | 63 ns |

每篇文章 50 纳秒,与获取一篇文章所需的毫秒相比根本不算什么,所以读取路径上的数字没有看起来那么重要。真正要看的是重新加载:`reparse` 要重新读取并解析整个 XML 文档,在季度合集上这需要几十毫秒,然后才能读到第一个字节;`mmap` 只是一次 `mmap` 调用、每个文件一个切片头,再加上对刚映射的索引做一次校验和。在这三种方式里,它只需 0.08 毫秒,另外的 0.19 毫秒是为了发现坏字节所付出的代价,而不是把它当作 message id 直接返回。

再看整个库而不是单个 release。2,636 个 NZB、2760 万篇文章,同一个二进制文件在同一批语料上运行三次,扫描后保持空闲:

| | 常驻内存集(resident set) | 活动堆内存 | 空闲 CPU | 冷打开,p50 | 磁盘上的索引 |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

热打开(1 毫秒)、流式吞吐量(38–39 MB/s)和启动时间,三种模式下几乎没有差别。`mmap` 打开冷 release 的速度*比*全部保存在内存里还快,因为在 `resident` 模式下,本次运行中从未打开过的 release 同样需要解析。而映射一个已写好的数据区只是一次系统调用,解析则要处理几 MB 的 XML。

索引会在 NZB 变化时自动重写,如果无法读取则自行修复:回退到 NZB 并重新写出。当 NZB 被移出监视目录时,索引也会被删除。索引的文件头和内容都有校验和,所以坏字节会被检测出来,而不会被当作没人发布过的 message id 返回。它当前占用多少空间,可以在 Dashboard 首页的 **Article Index** 下查看,也可以在后端启动时输出的日志行中看到。在 **Windows** 上没有映射:索引会被读入堆中,这等于常驻内存*加上*一次重新加载,所以那里的默认值仍是 `resident`,值得选择的惰性模式是 `reparse`。

## 故障排除 {#troubleshooting}

| 症状 | 原因 | 解决方法 |
|---|---|---|
| 启动时出现 `Cannot reach the news server for nzb` | 主机/端口/TLS 搭配错误、凭据有误，或套餐未激活 | `563` 对应 `tls: true`，`119` 对应 `tls: false`；然后重新检查凭据 |
| 资料库为空，没有 `Loaded NZB` 日志行 | `nzbs/` 缺失，或位置不对 | 它相对于 zurg 的**工作目录**。检查 systemd 单元中的 `WorkingDirectory=`，或 Docker 中挂载到 `/config` 的目录，即 compose 文件旁边的 `nzbs/`。只有早于 `/config` 的安装才会监视 `/app/nzbs` |
| 某个 NZB 从不出现 | 位于子目录中，或命名为 `.nzb.gz`，或无法解析 | 直接移动到 `nzbs/` 中，并解压。查看日志中是否有 `Skipping` 警告 |
| 资源显示的名称没有用 | NZB 的文件名即为名称，除非存在 `<meta type="name">` | 将 `.nzb` 重命名为资源名 |
| 资源内的文件名是随机的 | 混淆过的帖子，恢复失败 | 查看是否有 `Recovered N filename(s)`。如果 NZB 中没有 PAR2 文件，就无法找到真实文件名的来源 |
| 文件夹正确，但视频仍是随机名 | 完全混淆的帖子，且压缩包里有多个大小相近的文件 | 只有明确的单一主文件会被重命名为资源名。单个压缩包内的整季合集会保留压缩包给出的文件名 |
| 串流很慢 | `connections` 保持默认值 8 | 设为套餐允许的数量 |
| 长时间闲置后的第一次播放要等一秒才开始，之后正常 | warm floor 未开启，或被单连接账户限制为零 | 不设置 `warm_connections`（默认为 4），并检查它和顶层 `warm_connections` 是否被设为负数 |
| 服务商拒绝连接 | `connections` 超过了套餐允许的数量 | 调低到真实数值 |
| 播放卡顿，或某段静音 | 缺失的文章 | 在日志中查找 `PAR2 repair of …`；确认 `enable_repair: true`；添加[另一个 Usenet 服务商](#more-than-one-usenet-provider) |
| 某段一直静音，且从未出现修复日志 | `enable_repair` 关闭，或 NZB 不包含 `.par2` 文件 | 设置 `enable_repair: true`。如果帖子没有恢复文件，只有另一个新闻账户能帮上忙 |
| 第二个服务商似乎从未被请求 | 两个账户使用了相同的 `backbone`，所以第一个报告文章缺失后，第二个会被跳过 | 修正 `backbone` 的值。只有确实位于同一存储池的账户才应共用名称 |
| 多个账户中有一个失效，但启动时看起来正常 | 只有*所有*账户都无法连接时启动才会失败 | 在日志中搜索 `is not reachable`。每个失效账户都会按名称发出警告 |
| 按量计费账户被扣费，而无限账户上有相同的文章 | 它上面缺少 `backup: true` | 设置它。主账户仅仅繁忙时，读取请求将不再转到计费账户 |
| 按标签过滤的目录中缺少某个资源 | 它尚未被分析，因此没有 `zurg_*` 标签 | 等待分析完成，或在 Dashboard 中运行 Analyze & Tag Library |
| 挂载中看不到 `.par2` 文件 | 有意为之，它们作为修复辅助文件被隐藏 | 无需修复。zurg 仍会读取它们 |
| 在 Dashboard 中修改了服务商，但没有任何变化 | 服务商的更改会写入 `config.yml`，但不会热重载 | 重启 zurg。服务商表格下方的横幅有说明 |
| zurg 重启后 Plex 清空了资料库 | 挂载断开时正有扫描在进行，且开启了 auto-empty-trash | 关闭 auto-empty，并在任何重启前先暂停会话*并*刷新状态 |
| 资源出现后不久，文件大小略有变化 | 首次列表只能根据文章数量估算。精确长度随后才会得到，来自 PAR2 索引或文件自身的 yEnc 头 | 这是正常的，只会变化一次。长度会写入 `data/nzb-sizes/` 并保留，直到 NZB 变化 |

### 询问某个文章 {#asking-about-one-article}

`GET /debug/nzb/probe` 会通过 zurg 已在使用的新闻账户池，以按需读取的优先级，向新闻账户发出一次查询。之所以需要它，是因为之前的办法行不通：一个账户只提供八个连接，而 zurg 会占满全部八个。所以手动探测某个帖子时，要么得有第二个账户，要么得先停掉服务器。可停掉服务器又会破坏正在诊断的状态。在 Windows 上运行这些命令时，请用 `curl.exe` 代替 `curl`。

```bash
# Is this article still there? A STAT, so nothing is transferred.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?message_id=abc@news.example'

# The same question addressed the way you have it: a release id from the
# library, a file index counting from zero, an article number counting from one.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&file=0&article=3'

# &body=1 fetches the one article and reports what actually arrived against what
# the article says should have. This is how a provider that strips trailing
# bytes is identified: `short: true` with `decoded_bytes` below `span_bytes`.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&article=3&body=1'
```

它返回 `{"probes": [...]}`，其中包含一个 `nzb` 提供方的对象，内容有 `found`、`missing` 以及耗时。它会按优先级依次询问新闻账户，直到某个账户找到该文章为止（备用账户只有在主账户都找不到时才会被询问）。它不会告诉你是哪个新闻账户拿到了文章。这个接口是只读的：它抓取的任何内容都不会进入文章缓存，找不到的文章也不会被记为失效。所以探测不会让一个能正常播放的文件被屏蔽。

---

还是搞不定？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **zurg-support** 论坛提问。[获取帮助](../../guides/remote-help.md) 里说明了需要提供哪些信息。

## 另请参阅 {#see-also}

- [config.md](../reference/config.md) — 每个选项，包括 [Usenet 账户参考](../reference/config.md#usenet-accounts) 和 [目录过滤器参考](../reference/config.md#7-directories--filters)
- [plex.md](plex.md) — zurg 如何驱动 Plex 的扫描、匹配和垃圾清理
- [jellyfin.md](jellyfin.md) — Jellyfin 集成
- [docker.md](../setup/docker.md) — Docker 设置、FUSE 传播和故障排除
- [tags.md](../reference/tags.md) — 标签系统
- [architecture.md](../internals/architecture.md) — 结合上下文了解 `internal/nzb` 和 `internal/nntp`
