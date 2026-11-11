# 架构 {#architecture}

这是一份关于 zurg 整体结构的地图：它是什么，各个部分如何衔接，以及每个包为什么存在。目标读者是即将修改代码的人：这里会点明关键的架构决策，以及那些很容易在不知不觉中被破坏的不变量。

每个包的详细说明都在该包自己的 `doc.go` 里。本文档位于其上一层，讲的是整体的结构，以及这种结构背后的设计思路。

## zurg 是什么 {#what-zurg-is}

这是一个 Go 守护进程，它把 debrid 账户里的种子库呈现为一个虚拟文件系统。它本身不存储任何媒体。每次读取都会在请求时转换成一次对服务商 CDN 的范围 HTTP GET 请求。

它自己不保存任何内容，也拒绝 PUT 请求，所以就字节层面而言它是只读的。只接受两种写操作：重命名（只保存一个名字，不会改动任何账户，参见 [renaming.md](../guides/renaming.md)），以及 DELETE，它会把该发布从所有持有它的账户中删除。`__magic__` 在它自己的命名空间内增加了第三种写操作：一种被保存的目录布局（参见 [magic.md](../guides/magic.md)）。除了 `__magic__/__all__` 以及它直接下属的发布文件夹之外，这个命名空间里的所有位置都适用。这两者是下载客户端导入时所用的计算出的镜像。

提供四种视图，指向同一个库：

| 端点 | 用途 |
|---|---|
| `/dav/` | WebDAV，即 rclone 挂载的内容 |
| `/http/` | HTML 目录浏览器 |
| `/infuse/` | WebDAV 变体，适配了 Infuse 的特殊行为 |
| `/strm/` | `.strm` 文件中的签名 URL，供那些想要 URL 而不是挂载的播放器使用 |

rclone 通过 FUSE 挂载 `/dav/`，所以 Plex、Jellyfin、Emby 和 Infuse 看到的就是一个普通的目录树。

贯穿整个设计的难题，是文件系统所承诺的东西和 debrid API 所提供的东西之间的差距。文件系统承诺稳定的路径、即时的 `stat`、按需返回字节；而 debrid API 给的是有速率限制的 JSON、会失效的链接，以及完全没有文件系统语义。几乎每个包都是为了填补这差距的某一部分而存在的。

```
media player
    │
    ├─ rclone FUSE ──► /dav/  ──┐
    └─ direct HTTP ──► /http/ ──┤
                                ▼
                    internal/handlers  (chi router, auth, routing)
                                │
                internal/dav ───┤─── internal/htmlindex     (listings)
                                │
                                ▼
                    internal/torrent   (the library, in memory)
                                │  resolve link for this file
                                ▼
                    internal/universal (byte path, proxy/redirect, RAR)
                                │
                                ▼
                    internal/debrid    (Provider dispatch)
                                │
        ┌───────────┬───────────┼────────────┬──────────┐
        ▼           ▼           ▼            ▼          ▼
   realdebrid    torbox     alldebrid       nzb ──► nntp ──► par2
        └───────────┴───────────┘            (Usenet, no debrid service)
                    │
              internal/rdclient  (host rotation, rate limit, retry, DNS)
```

## 启动流程 {#boot-sequence}

`cmd/zurg` 是一个轻量的 Cobra CLI，提供 serve、version、network-test、清理 downloads/torrents、挂载控制和下载依赖等命令。真正的逻辑都在 `internal/app.go` 里。其中的 `MainApp` 特意写成一个容易读懂的函数：

1. 创建运行时目录（`logs`、`data`、`data/info`、`dump`、`strm`、`nzbs`）和日志记录器。
2. `ensureConfigAndRequirements`：加载配置，如果缺少 `ffprobe` 和 `rclone`，就下载它们（`internal/requirements`）。如果是第一次运行且没有配置文件，它会写入一份默认配置然后停止，除非 token 是从环境变量里读取的。
3. 尽早初始化 `strmlink`，这样如果数据目录不可写，问题会立刻报出来，而不是等下次重启后 `.strm` 文件失效时才发现。
4. 对 Real-Debrid 的下载主机运行**网络延迟测试**（`internal/rdclient`）。如果磁盘上的缓存结果够新，就直接加载缓存。这一步会给 CDN 主机排序，之后的主机轮换也依赖它。
5. 从注册表中构建所有已配置的 provider，把它们组装成一个 `debrid.Set`，并保留第一个 Real-Debrid provider 的类型化句柄。仪表盘、主机页面和网络测试仍然专门针对 RD 工作。
6. 构建 `TorrentManager`。它会立即在后台开始从磁盘加载缓存的库，然后再刷新它。
7. 挂载 chi 路由器，启动 HTTP 服务器，等服务器可以接受连接后再启动 rclone。
8. 等待 SIGINT/SIGTERM/SIGQUIT 信号。收到信号后，依次关闭 HTTP 服务器、停止 Plex 服务、卸载 rclone，每一步都有 20 秒的时间预算。

设置 `ZURG_PPROF=1` 可以在 `127.0.0.1:6060` 上启用 pprof。它只监听本地回环地址，因为在扫描高峰期，只有分析正在运行的实例才能找出 CPU 消耗在哪里。但这个端口绝不能从网络上访问到。

## 第 1 层 — 配置 {#layer-1--config}

`internal/config` 是唯一的权威来源，几乎所有其他包都会读取 `ZurgConfigV1`。类型化的 getter 会在字段为零值时应用默认值，所以调用方不需要判断字段是否存在。

重点是 `filters.go`：它是一个嵌套的 AND/OR 过滤语言，会把每个种子分配到一个或多个 **虚拟目录**。正是它把扁平的种子列表变成 `movies/`、`shows/`、`anime/`、`recent/`。

条件包括：种子名称（`regex`、`contains`、`not_regex`）、大小、文件（`any_file_inside_regex`、`any_file_inside_size_gte`）、标签（`tags_match_any`、`tags_missing_all`）、时间（`added_within_hours`、`added_after`）、派生属性（`has_episodes`、`is_music`），以及种子来自哪个账户（`provider`、`not_provider`）。每个目录还有显示规则，比如 `only_show_the_biggest_file`，以及大小的下限和上限。

每次分配时用到的正则表达式，在包级别只编译一次。之前每次调用都执行 `MustCompile`，启动时间明显被它拖慢。

配置可以在仪表板里实时编辑。`UpdateConfigFileAtomic` 按键逐项修改，而不是重新序列化整个文件，所以注释和未知的键都会保留。

## 第 2 层 — 后端抽象 {#layer-2--backend-abstraction}

`internal/debrid` 是整个项目的核心。它定义了其他所有包都会用到的领域类型，包括 `Torrent`、`TorrentInfo`、`File`、`Download` 和 `User`，还定义了每个后端都要实现的 `Provider` 接口。

### 提供方与能力 {#provider-and-capabilities}

`Provider` 保持精简：列出种子、获取信息、删除、解析链接、验证、获取字节、报告账户状态。任何服务可能合理缺少的功能，都放进**可选能力接口**，调用方通过类型断言检测，缺失时自行降级处理。

| 接口 | 增加了什么 | 谁需要它 |
|---|---|---|
| `MagnetAdder` | 通过哈希添加、选择文件、活动槽位数 | 修复 |
| `TorrentRestarter` | 原地重试失败的种子 | 修复，最省事的策略 |
| `HostRotator` | 切换 CDN 主机池 | 网络测试、`/hosts` 页面 |
| `DownloadLister` | 单独的托管下载列表 | `__downloads__` 目录 |
| `ArchivePasswordKeeper` | 某个发布的压缩包密码 | 仅 Usenet |
| `PremiumMonitor` | 套餐剩余时间 | 启动时的警告 |

除此之外，`Capabilities` 是 provider 的自我描述，它描述的不是能做什么，而是必须在哪些限制内运行。之所以需要它，是因为 zurg 的库行为是围绕 Real-Debrid 的形态长出来的，如果把这种形态硬编码进去，其他后端要么直接坏掉，要么白白浪费资源。

有两个标志已经在驱动实际行为：

- **`ListIncludesFiles`**——种子列表本身已经带有每个文件的详细信息。这样冷启动扫描库时，从"每个种子调用一次 API"变成"总共只调用一次"。这是各后端之间最大的开销差异。
- **`StoredLinksCanRot`**——存储的链接可能失效，而种子看起来仍然正常，所以必须探测链接。这是 Real-Debrid 的特性，而且代价很高；对于按需生成 URL 的后端，没有可探测的东西，跳过这一步就是扫描免费还是触发账户级锁定的区别。

其余的——`ServesLinksLocally`、`MaxActiveSlots`、`MaxConcurrentRequests`、`AddsPerHour`、`ContentExpires`、`SupportsFileSelection`——每个后端都会声明，并由通用代码读取。零值被刻意设为最保守的解读：忘记设置某个字段的 provider 会得到谨慎的行为，而不是一大堆请求；如果 zurg 完全无法解析某个 provider，就回退到 `internal/torrent/providers.go` 中的 `unknownProviderCaps`，它只把这个保守答案写一次，而不是散落在每个调用点。

还有第三种形态，上面两个标志都无法表达：AllDebrid 的列表不带文件，但它的单个种子接口接受一**批** id。这个问题在 provider 内部处理，而不是用一个能力来表达，因为它只改变 provider 自己发请求的方式；通用刷新仍然一次只询问一个种子，无需知道这件事。

### Set

`Set` 指的是按配置顺序排列的所有已配置提供商。种子管理器、处理程序和仪表板都依赖它，而不是任何具体的客户端。有两种访问方式很重要：**扇出**，即一个操作会针对每个账户执行（比如刷新库）；**分发**，即一个操作必须送到拥有该种子的那个账户（比如删除、解析、修复）。它还保存账户的健康状况和可用性状态。

### 链接缓存 {#link-cache}

`LinkCache` 会按**令牌**来保存已解析的 URL，而不只是按链接。在某个令牌下生成的 URL 只对该令牌的配额有效，所以当某个令牌被限速（带宽上限）时，它名下的条目必须整体作废，而不能在轮换到的下一个令牌上继续使用。条目的过期时间以 `Generated` 时间戳为准，而不是插入时间，因此从服务商自己的下载列表预先填充的链接，会按服务商的时间表过期。

### 各个后端 {#the-backends}

| 包 | 说明 | 需要了解的内容 |
|---|---|---|
| `internal/realdebrid` | Real-Debrid，最早的后端 | 三个独立的 HTTP 客户端：限速的 API、限速的 unrestrict，以及轮换主机的下载。巴黎本地时间戳在包的边界处规范化，并且不会泄漏到包外。`DownloadTokenManager` 会在某个令牌过期时轮换令牌。 |
| `internal/torbox` | TorBox REST | 使用 REST 并设置 `bypass_cache=true`，而不是 TorBox 的 WebDAV，因为 WebDAV 的视图会比实际情况慢 5–15 分钟。它没有逐文件的链接，所以链接是合成的：`torbox://<torrent-id>/<file-id>`。这种格式在重启后保持稳定，而且在日志里可读；裸的 CDN URL 带着 API 密钥，做不到这两点。有两个叠加的限速器：文档中的 300/min，以及专门针对 `requestdl` 的、更严格的一个。参见 [torbox-limits.md](../providers/torbox-limits.md)。 |
| `internal/alldebrid` | AllDebrid v4.1 | 使用表单编码的 POST。逻辑上的失败会以 HTTP **200** 返回，并带有 `status:"error"`，所以 HTTP 状态码无法说明调用是否成功。文件位于 `/magnet/files` 之后，该接口接受批量请求，因此并发的查询会被合并成单个请求。嵌套的文件树会按深度优先展平，而且这个顺序很关键。 |
| `internal/nzb` | Usenet，根本不是 debrid 服务 | `nzbs/` 中的 NZB 文件会变成 torrent；读取时按需抓取文章并进行 yEnc 解码。链接格式为 `nzb://<nzb-id>/<file-index>`，并在本地提供服务，因此 `DownloadFile` 会合成 HTTP 响应，而不是代理一个响应。 |
| `internal/nntp` | 精简的 Usenet 客户端 | 连接池受账户连接数配额的限制，按 message id 执行 BODY/STAT，并做 yEnc 解码。单个连接只能获得可达吞吐量的一小部分，因此一个文件的读取会分散到整个连接配额上。 |
| `internal/par2` | GF(2^16) 上的 PAR2 / Reed-Solomon | 当某篇文章已经从服务器上过期时，该发布自带的恢复卷会重建它原本携带的字节。它的代价很特别：计算需要每个受保护文件的每一个幸存分片，且只需一次。因此它作为后台任务运行，一次只处理一个发布，并生成字节区间补丁，读取器用它们代替空白内容提供服务。 |
| `internal/rdclient` | 共享的底层 HTTP | 在按延迟排序的 CDN 端点之间轮换主机，令牌桶限速，带退避的重试，代理支持，自定义 DNS，强制 IPv4/IPv6，以及地理位置固定的 CDN 偏好。`IPRepository` 负责网络测试及其磁盘缓存。 |

`internal/nzb` 证明了这个抽象是成立的。它在一个本地目录和一个新闻服务器上实现了同一个接口，之所以行得通，是因为这个接口真正的约定是*"用字节回应一个范围 GET"*，而不是*"代理一个 CDN"*。

### 添加后端 {#adding-a-backend}

新包，实现 `debrid.Provider`，在 `init` 里调用 `debrid.Register`，并在 `internal/app.go` 里加一个空白导入。`internal/debrid` 里的内容不做任何改动。

## 第 3 层 — 库 {#layer-3--the-library}

`internal/torrent` 是 zurg 的核心，也是其中最大的包。`TorrentManager` 把整个库保存在 `cmap` 并发映射中，以实现无锁读取；它通过评估配置过滤器来把种子分配到各个目录，解析并缓存链接，并运行后台任务。

### 持久化 {#persistence}

每个条目都会以 JSON 格式写入 `data/<name>.zurgtorrent`，每个种子的详细信息则缓存在 `data/info/` 下。重启时会从磁盘加载数据，马上就能用，然后再刷新。这一点很重要，因为冷启动扫描受速率限制，而不是受 CPU 限制。已经从账户中移除的种子可以归档到 `dump/`，并以 `__dump__` 目录的形式显示出来（`load_dumped_torrents`）。

其他地方无法重建的状态（配置、每个 zurgtorrent、`data/local/` 下的 `__magic__` 存储、`nzbs/` 下的源 NZB）会保存在一个流式写入的 `.zurgbackup` 文件中。`zurg backup` 可以生成这个文件，仪表盘的 Backup & Restore 页面也可以。`zurg restore-backup <file>` 会把它解压到工作目录。`internal/backup` 负责管理这个格式。清单是第一个条目，因此恢复时会先验证手头的内容，然后才开始写入。

保留目录名：`__all__`、`__unplayable__`、`__dump__`、`__downloads__`，以及每个账户对应的一个 `__<provider-name>__`。

### Torrent 与 TorrentCopy {#torrent-vs-torrentcopy}

一个资源可以同时存在于多个账户中，但 zurg 只会显示一次。两者的分工如下：

- **内容信息属于条目**（`Torrent`）：名称、hash、存在哪些文件、标签、IMDB id、重命名设置。
- **账户信息属于副本**（`TorrentCopy`）：该账户生成的 torrent id、它提供的链接、它自己的损坏状态，以及它的重试计数。

尤其是文件 id 是每个账户各自的。Real-Debrid 会在一个 torrent 内为文件编号，并标记其中一部分为已选中；TorBox 只列出它已下载的文件，并且用自己的方式编号。因此 `FileSource` 会按 provider 保存 `FileID`。修复时，选择的文件是根据正在修复的那个副本的 id 来构建的。如果读到了别的账户的 id，就会重新添加错误的文件。

副本按照配置中的顺序保存，这个顺序也就是偏好顺序。读取时会优先使用第一个健康的副本，如果它不可用就故障转移到下一个。删除条目会删除它的所有副本。没有任何副本的条目不存在。

### GetKey 必须保持纯函数 {#getkey-must-stay-pure}

`GetKey` 是虚拟库中一个种子的名字，也就是它的目录条目、它的 `.zurgtorrent` 文件名，以及每次查找都要经过的句柄。它是**每次查找时重新计算的，从不存储**。这就排除了通过检查当前已被占用的名字来解决重名冲突的办法：答案会随着库的变化而变化，一个种子可能会以它被归档时的名字再也找不到。

唯一的后缀是给那种比较少见的冲突准备的，即两个*不同的*发布版本共用同一个名字。这个后缀是内容自身哈希的一个标记，和名字本身一样是纯粹的。开启它的标志由刷新过程决定，因为刷新过程能看到整个库，并且这个标志会保存在种子上。

### 后台任务 {#background-jobs}

| 任务 | 文件 | 作用 |
|---|---|---|
| 刷新 | `refresh.go` | 轮询每个账户，将列出的实例合并到条目中，为新实例获取信息，分配目录，并清理多余数据。在两次完整轮询之间，用一次轻量的单项获取来检查是否有变化。 |
| 修复 | `repair.go` | 查找并修复损坏的种子。 |
| 下载 | `manager.go` | 将 hoster 下载列表刷新到 `__downloads__` 中。 |
| 网络测试 | `handlers` | 定期重新为 CDN 主机排序。 |

每个任务的运行间隔都可以在运行时通过通道重新设置，因此在仪表盘中修改配置后无需重启即可生效。上次运行的时间戳会被持久化保存（`data/repair_timestamp`、`data/downloads_timestamp`），这样重启后就不会重复运行刚刚执行过的任务。

### 修复 {#repair}

第二重要的部分。文件带有 FSM 状态（`ok_file` / `broken_file`，通过 `pkg/fsm`）；torrent 和副本各自也带有自己的状态。当链接不再提供字节数据时，修复会按策略逐级升级：

1. **原地重启**（`TorrentRestarter`）：成本最低。不需要重新上传，不占用添加名额，而且 torrent 保留原来的 id，因此库中的条目得以保留，而不是被删除后再重新发现。刷新时，如果在账户中发现一个失败的 torrent，就会对它发起重启。但前提是实例允许处理失败的 torrent，也就是 `enable_repair` 或 `delete_error_torrents` 至少开启一个。两者都关闭时，账户保持原样（`mayRestartFailedTorrents`）。
2. **重新下载损坏的文件**：只重新选择已损坏的文件。
3. **重新插入**：重新添加 magnet 并获取新的链接。
4. **归档**：对于无法恢复的发布版本，这是最后的手段。
5. **提供给不持有该资源的账户**（`repair_across_accounts.go`）：各服务商的缓存相互独立，因此某个账户已清除或因文件名而拒绝的发布版本，可能在另一个账户上被缓存。当所有持有该发布版本的账户都无法修复时，会依次询问已配置但不持有该资源的账户，第一个已经拥有该 hash 的账户就接手。随后的列表会通过常规的 `absorbCopy` 路径，将它作为第二个副本关联到条目上，该路径会自行清除条目的判定结果。这一步始终只使用仅缓存模式，通过 `AddIfCached` 实现，绝不经过 `restrict_repair_to_cached`。如果账户需要去拉取文件，这次添加会被撤回并再次删除，所以这始终是一次修复，而不是重新下载。无响应的账户会退避，退避时间从一天到大约两周不等。每次扫描最多只发出十次请求，这使得在一个由被判定不可用的发布版本组成的库上无人值守地运行它也能承受。

围绕这些的还有：指数退避；按副本设置的重试上限（`RepairCycles`、`AssignRetries`，并持久化，使上限在重启后依然有效）；来自 `Capabilities.AddsPerHour` 的每小时添加预算闸门；活动槽位检查；通过基于集合的队列进行去重；以及一个在整次扫描范围内生效的启发式规则：一连串的 hoster-unavailable 失败会被视为一次服务商中断，而不是 N 个损坏的 torrent。无法修复的判定按副本记录，只有在*每一个*副本都带有此类判定时，才会传播到条目本身。Real-Debrid 的永久性错误与 TorBox 上的副本无关。

操作员可以手动强制修复。强制标记保存在 torrent 上，而不是 context 上，因为在扫描中途到达的请求会被放入队列，稍后由扫描自身的 context 取出处理。按钮也会走到第 5 步，并且按此顺序执行：它先清除该发布版本上的所有判定，因此持有它的账户会像之前一样被重试；只有这次尝试失败时，才会提供给其他账户。由于它会清除这些判定，指定的 torrent 在扫描收集其被判定不可用的条目时即符合条件，并且只会在刚刚运行的那次修复之后再次被判定不可用。因此它是在该修复之后被收集，而不是在循环中收集。否则，这将是唯一一条有人在等待的路径，却也是唯一一条永远不会提供备选方案的路径。

### 包中的其他内容 {#everything-else-in-the-package}

`mediainfo.go`（ffprobe 分析，为时长/编解码器标签提供数据），`tags.go`，
`rename.go`（刷新后仍需保留的重命名），`delete.go`，`strm.go`
（为整个库生成 `.strm` 文件），`hooks.go`（生命周期事件触发的用户脚本），
`assign_links.go`，`unrestrict.go`，`opensubtitles.go`，
`provider_directories.go`，`reset_all.go`。

## 第 4 层 — 服务 {#layer-4--serving}

### 路由 {#router}

`internal/handlers` 负责构建 chi 路由器，并把所有部分连接起来。WebDAV 的非标准方法（`PROPFIND`、`MKCOL`、`MOVE`）会在 `init` 时注册到 chi 上。基本认证（Basic auth）会包裹所有路由，但有两个例外：`version.txt` 和 `/ready`（这样健康检查才能正常工作），以及 `.strm` 端点。媒体播放器打开 `.strm` 时没有凭据可以提供，所以路径中的签名令牌会代替它来完成授权。

注释里记录了两条路由经验，值得记住，别再重复踩坑。chi 只会在单个路径段内应用正则路径参数。因此，通过压缩包访问的文件（`<archive>.rar/<inner>.mkv`），或者压缩包内的嵌套目录，都匹配不到任何路由。这两种情况都需要尾部通配符。另外，种子内的路径是否属于列表还是下载，要看它的尾部斜杠，前提是路由不再关心路径有多深。

### 列表 {#listings}

`internal/dav` 生成 PROPFIND 的 XML，处理 DELETE、MOVE（重命名，包括跨目录和跨种子的校验）以及 Infuse 的相关变体。`pkg/dav` 自己生成 XML，用的是经过优化的字符串拼接，而不是 XML marshalling；它还负责把 WebDAV 客户端需要的 RFC 3339 转成 RFC 1123，并对路径同时做 URL 和 XML 转义。

`internal/htmlindex` 把同样的目录树渲染成 HTML，用于 `/http/`。

两者应用的是完全相同的可见性规则：只显示最大的文件、大小阈值、broken/deleted 状态；并且两者都会折叠多卷 RAR 压缩包，只显示第一卷。

### 字节路径 {#the-byte-path}

`internal/universal` 是请求变成字节的地方：

- 链接解析通过 `singleflight` 去重，所以同一个文件的一百次并发读取只需要解析一次。
- 根据 `disable_stream_proxy` 决定是代理还是重定向。但本地提供的链接（`ServesLinksLocally`）永远不能重定向，因为客户端没有可以打开的地方。
- 链接失效时重新 unrestrict，次数上限是一个很小的数字。
- 每个文件有一个网络故障冷却机制：连续 3 次错误后，该文件会被暂停 5 分钟。这样就不会因为一个无法访问的 CDN 主机而陷入无限重试循环。
- 遇到限流窗口时，短暂挂起而不是直接报错。冷却时间很短时如果让读取报错，一个被限流的账号就会在 rclone 的 VFS 里引发错误风暴：等待的请求卡住，读取进程进入 D-state，媒体服务器也可能僵死。所以暂时挂起读取反而更划算。更长的冷却等级仍然快速失败。
- 按 token 统计带宽，计数器在 CET 午夜重置，与 Real-Debrid 的每日流量重置时间保持一致。

### 压缩包 {#archives}

`internal/rarstream` 通过字节范围请求（HTTP 206）解析 RAR4、RAR5 和 ZIP 的文件头，在各个分卷之间构建块映射，并即时还原单个文件的内容。**不做解压**，只支持存储（stored）的数据，这正是 scene 发布版通常采用的方式。`VolumeKey` 和 `IsVolume` 会统一处理多种分卷命名规则（`.part001.rar`、`.r00`、`.rar`），`dav` 和 `htmlindex` 借此把各个分卷合并为一个条目。列表会缓存在种子上，并带有解析器的 `ListingVersion` 标记。由其他解析器生成的列表会被丢弃，而不会直接返回。

### STRM

`internal/strmlink` 负责编码并签名 `.strm` 文件中包含的 URL。
它所替代的、仅支持 Real-Debrid 的方案原本是"意外地"安全的：URL 中包含 RD 的 13 位下载码，因此持有该 URL 本身*就是*授权的证明。
其他后端则通过可以轻易枚举的 id（如 `torbox://17/3`）来定位文件，所以如果沿用同样的结构，任何能访问该端口的人都可以为该账户铸造 CDN URL，或消耗其新闻服务器连接。
在 `data/strm_secret` 中的密钥上计算 HMAC 可以堵住这个漏洞：不是由 zurg 写入的令牌无法被解析。
该密钥必须比进程存活得更久：每个已写入的 `.strm` 只有在其签名密钥有效期间才会保持有效。

### 仪表板与管理 {#dashboard-and-management}

`internal/handlers/dashboard` 会用嵌入的模板渲染网页界面，
模板在启动时就预先解析好，这样语法错误能尽早暴露，而不是等到请求时才出问题。
页面包括：实时种子状态、可交互的 YAML 配置编辑器、主机延迟、
目录管理、提供商管理、媒体服务器连接状态、
账户/高级会员信息、带宽、rclone 状态，以及 Plex "Wrapped" 统计。
每个媒体服务器的状态获取器并发运行，让页面加载保持流畅，
响应迅速。

`internal/handlers/manage` 是按种子逐个操作的界面，包括：标签、文件列表（含状态详情）、
Plex 匹配、重命名、按文件删除/恢复/强制显示、
批量删除和扫描。

它的重复项视图是 `internal/duplicates`。`internal/arrinventory` 以及 Radarr 和 Sonarr 适配器旁边的
`Inventory` 读取器会读取每个 \*arr 持有的文件，
只读取、不参与获取。
`magic.Resolver.HolderOf` 会把每个文件的路径追溯到它来自的发布资源，这个包还会把
可能包含同一部电影或同几集的发布资源归为一组。分组依据是名称、IMDb ID
以及 \*arr 历史记录。某个发布资源是否正在使用，完全由追溯到的
路径决定。

`internal/static` 用 `go:embed` 嵌入 CSS、favicon、logo 和 robots.txt，
所以二进制文件是自包含的。

## 第 5 层 — 挂载 {#layer-5--the-mount}

`internal/rclone` 把 rclone 当作子进程来管理。它会构建挂载命令（一个指向 zurg 自身 `/dav/` 的 WebDAV 远程），负责启动和停止，每 30 秒做一次健康检查，失败时按指数退避重启（从 1 秒到 60 秒）。

启动时会在 49152–65535 之间随机选一个临时 RC 端口，用于 VFS 缓存失效和状态查询。这个失效操作在两个时刻很关键：缓存库加载完成后，以及第一次完整刷新之后。否则挂载在加载途中拿到的不完整目录列表，会在整个 `--dir-cache-time` 期间一直留着。

凭据通过环境变量传递，从不放在命令行参数里。`Controller` 是处理器和仪表盘使用的接口；`Runner` 和 `Command` 则是为测试而抽象出来的进程管理部分。

## 第 6 层 — 媒体服务器 {#layer-6--media-servers}

两个不同的东西都叫 "Plex"：

- **`pkg/plex`、`pkg/jellyfin`、`pkg/emby`** 是媒体服务器的*客户端*，各自实现 `common.MediaServerWorker`。`pkg/common` 提供共享的任务生命周期：无上限的动态队列、每个任务的重试记录、带抖动的指数退避、连续失败后的熔断器，以及卡住任务检测。它还包含处理 macOS 大小写不敏感 APFS 的路径辅助函数。`pkg/scan` 在此之上提供统一的 `MediaScanner`，它会把路径刷新任务分配给拥有该路径的服务器，并报告每台服务器的队列深度。
- **`internal/plex`** 是 zurg 专用的逻辑：`Matcher` 使用文件路径、IMDB ID 和 TVDb/TMDb 标识符，把种子与 Plex 资料库条目配对。它会定期在工作池中运行，并缓存元数据，还会把发现的 IMDB ID 回填到种子上。
- **`internal/acquisition`** 负责持久化的获取队列和共享执行器，它从 Newznab 索引器获取 NZB，从 Torznab 索引器获取缓存种子。Plex 观看列表、Seerr、Radarr 和 Sonarr 是来源适配器，会把请求解析为电影、季或集目标。`data/acquisition.json` 会在重启之间保存重试截止时间和每个目标的进度。配置和适配器约定请参阅 [获取来源](../guides/acquisition.md)。

`pkg/mediabrowser` 存放 Emby 和 Jellyfin 共用的类型。

## 第 7 层 — 支持 {#layer-7--support}

| Package | Purpose |
|---|---|
| `pkg/fsm` | 两种小型状态机：`FSMWithExternalMutex` 用于嵌入到已经加锁的东西里的情况，`FSMWithTime` 用于需要自己的锁和状态切换时间戳的情况（这样 `SinceWhen` 就能告诉你这个状态已经持续多久了）。 |
| `pkg/logutil` | 基于 Zap 的双路输出：彩色控制台和滚动日志文件（通过 lumberjack，10 MB × 20 个）。日志级别来自 config.yml 中的 `log_level`，没有的话回退到环境变量 `LOG_LEVEL`，再没有就用 DEBUG。级别保存在共享的 `zap.AtomicLevel` 里，所以仪表盘可以一次性修改所有日志记录器的级别，无需重启。还包括为仪表盘日志查看器和 Export Logs 读取日志的功能。 |
| `pkg/utils` | 被屏蔽主机的持久化、文件可见性规则、令牌脱敏、视频/音频检测、`.strm` 命名，以及 `GetZurgBaseURL`（在反向代理后面会遵循 `X-Forwarded-*`）。 |
| `pkg/script` | 运行用户定义的生命周期事件脚本；Windows 上使用 PowerShell，其他系统使用 `/bin/sh`。 |
| `pkg/dmm` | debridmediamanager.com 搜索 API 的客户端，按服务器端的每 2 秒 1 次进行限速。观察列表监控会用到它。 |
| `internal/version` | 通过 ldflags 注入的构建元数据；同时也是 `/http/version.txt` 处的 ASCII 横幅。 |
| `internal/requirements` | 首次运行时，从 GitHub 发布页下载与平台匹配的 `ffprobe` 和 `rclone`，并把*相对*路径写入 config.yml，这样配置文件就能随处移植。不支持的平台只会发出警告，不会直接失败。 |
| `internal/clear` | 通过带认证 Cookie 的网页界面批量删除 Real-Debrid 的下载和种子，循环直到清空。 |
| `internal/handlers/tmplcache` | 仪表盘的模板缓存。 |

## 横切设计决策 {#cross-cutting-decisions}

**能力判断，而不是 `if provider == "realdebrid"`。** 凡是假设 Real-Debrid 结构的代码，都应该放在能力标志（capability flag）后面，而不是用类型判断。这条规则能让 torrent 管理器保持与后端无关。

**接口的约定是字节，而不是代理。** `Provider` 从不承诺远端 CDN，只保证能够回应一个范围 GET（ranged GET）请求。这也是 Usenet 后端能够适配的原因。CDN 假设曾在两个地方泄漏出来：重定向，以及把 URL 交给 ffprobe（它需要外部二进制程序能够打开的地址）。现在这两处都由 `ServesLinksLocally` 保护。

**按位置配对链接很关键。** `TorrentInfo.Links[i]` 与 `TorrentInfo.Files` 中第 i 个**被选中**的文件一一对应。如果某个 provider 无法为某个文件生成链接，它必须把该文件报告为*未选中*，而不能直接省略它，否则后面的每个文件都会悄悄对应到错误的链接上。每个后端都必须遵守这一点。

**一个 torrent 只属于一个账号。** 任何需要访问服务的调用，都必须通过该 torrent 所属的 provider 分发（`ProviderFor`、`resolveLink`、`verifyLink`、`DeleteByID`），而不能走主 provider。做错了就会从错误的账号里删除文件。

**磁盘是真正的一层存储。** 包括 `.zurgtorrent` 条目、`data/info/` 下每个 torrent 的详细信息、网络测试结果和时间戳、任务时间戳、STRM 签名密钥、RAR 列表缓存，以及被屏蔽的主机。重启后会接着之前的进度继续，而不是重新扫描。

**所有操作都有节奏控制。** 包括每个 provider 的令牌桶（token bucket）、并发上限、每小时的添加限制、链接的有效期（TTL）、每个文件的冷却时间，以及限流暂停。尤其是在 TorBox 上，链接解析是最稀缺的资源，前面的链接缓存才是让库扫描变得可以承受的关键。

**读取无锁，写入范围窄。** 并发 map 支撑着目录、torrent 和文件树；修改操作由每个 torrent 自己的锁保护（`copiesMu`、`tagsMutex`、`operationsMutex`、`archiveCacheMutex`），而不是依赖任何全局锁。

**`rdclient` 是共用的，但它的策略属于 Real-Debrid。** 它的错误分类和重试规则都来自 RD。遇到非 2xx 状态时，它会返回一个错误，同时仍然返回响应。因此，如果某个 provider 需要读取状态码（比如带有 `Retry-After` 的 429），必须先检查 `resp`，再检查 `err`。

## 构建、测试与部署 {#build-test-deploy}

- **Build**：`make build`。版本号、commit 和构建时间会通过
  ldflags 注入到 `internal/version` 中。
- **Unit tests**：`go test ./...`。提交前检查（pre-commit）会运行 gofmt、golangci-lint、
  `go test -short`，以及完整的质量检查套件。
- **Integration tests**：`make integration-test`，会从最省资源的测试开始跑，`refresh_repair` 放在最后，因为它要等整个媒体库扫描完成。请在同时装有 Go、rclone、FUSE 和 Plex 的机器上运行。否则挂载和 Plex 相关的测试会明显地跳过，但仍然以 0 退出，所以要看输出内容，而不是只看退出码。详见 [e2e-test.md](e2e-test.md)。
- **Docker**：两阶段 Alpine 构建；运行时镜像额外加入了 ffmpeg、rclone、fuse3，还有一个健康检查。
- **Deploy**：`make deploy USER=… HOST=… DIR=…`，它会停止 Plex 和 zurg 服务，替换二进制文件，等 `version.txt` 返回 200，然后重启 Plex。

## 先看哪里 {#where-to-look-first}

代码库中的注释始终记录*为什么*这样写，通常是促使写下这段代码的那次故障。每个包都有一个 `doc.go`。如果你要修改某处代码，请先阅读该包的 `doc.go`，以及你要修改的类型上方的块注释。它们记录了从函数签名中看不出来的约束。
