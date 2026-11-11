# Real-Debrid、AllDebrid 和 TorBox 上的种子生命周期 {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

2026-08-30 使用真实账号测量。下文标为 **observed** 的内容都来自抓包结果。标为 **inferred** 的内容则不是来自抓包，文中会说明原因。

zurg 需要这些信息，因为 qBittorrent 兼容层必须告诉 Sonarr 和 Radarr 下载目前处于哪个阶段。现在它做不到。

`TorrentInfo.Status` 使用的是 Real-Debrid 的状态词汇，AllDebrid 和 TorBox 的包在 zurg 自己的代码看到种子之前就会把状态转换成这套词汇。TorBox 的 `stalled (no seeds)` 会变成 `queued`。目前完全没有字段携带做种者数、速度或剩余时间。因此，阶段表必须从原始协议数据中构建，而不能依赖那些已经把状态统一掉的提供商包。

测试脚本是 `scripts/torrent_lifecycle_probe.py`。它直接调用原始 REST API，所以抓到的是协议层的原始状态。退出时它会删除自己添加的所有内容，包括按 Ctrl-C 中断的时候。

---

## 测量方法 {#how-this-was-measured}

### 账户 {#the-accounts}

| Provider | Account | Why this one |
|---|---|---|
| Real-Debrid | a test account | no running zurg uses it, so nothing else touched it during the run |
| AllDebrid | a test key | the account already held other magnets, so only ids the run created were ever deleted |
| TorBox | a live key | **another zurg instance was loaded with the same account**, which is not a footnote. See [Hazards](#hazards-found-on-the-way) |

Credentials come from `RD_TOKEN` `AD_KEY` `TB_KEY` in the environment. Nothing writes them to a
capture.

### 种子 {#the-torrents}

都是合法内容：开源（FOSS）镜像和公有领域影片。凡是来自 `.torrent` 文件的 info hash，都是测试工具从文件重新计算出来的，而不是手动输入的。Swarm 规模取自 tracker 的 scrape，且是同一天获取的。

| 用例 | 种子 | Info hash | 大小 | Tracker 做种数 | Webseeds |
|---|---|---|---|---|---|
| cached | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | 不适用 | 不适用 |
| cached | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | 不适用 | 不适用 |
| cached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 到 27 | 无 |
| uncached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| uncached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 个做种者和 0 个下载者 | 3 |
| seedless | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | 无 |
| seedless | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | 无 |
| nometa | 随机 40 位十六进制 | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | 无 | 无 | 无 |

这些 0 是真实的，不是 tracker 挂了。`torrent.ubuntu.com` 在同一轮循环中，对三个 Ubuntu 条目各 scrape 了两次：对 26.04.1 先返回 22 个、后返回 27 个做种者，而对两个 seedless 条目则返回空的 `d5:filesdee`。`bt1.archive.org` 和 Prelinger 条目也是同样的情况。

在添加任何内容之前，都先用 `checkcached` 向 TorBox 查询了每个 hash。在这三种缓存探测方式中，它是唯一不会造成破坏的。它对三条 cached 行都返回 cached，对其余六条都返回 uncached。这正好与用例名称所声称的分类一致。

### 轮询频率与上限 {#poll-cadence-and-caps}

3 s für die ersten 2 Minuten, danach 15 s. 1 s für den Cache-Fall, weil der gesamte Lebenszyklus dort schon innerhalb einer normalen Abfrage abgeschlossen sein kann. Für die Kampagne 15 Minuten pro Torrent als Obergrenze, statt des Script-Standards von 30. Das vorgeschlagene Standard-Timeout des Shims liegt bei 10 Minuten, und ein Torrent, der bei 15 noch läuft, ist bereits über das einzige Zeitfenster hinaus, das zählt. Real-Debrid-Adds liegen mindestens 20 s auseinander.

Jeder Provider lief als eigener Prozess mit eigenem Ausgabeverzeichnis. So bleibt der Abstand zwischen den Real-Debrid-Adds innerhalb eines Prozesses korrekt, und die drei können gleichzeitig laufen.

## Real-Debrid

### 端点 {#endpoints}

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### 观察到的状态值 {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

这里没有观察到。`compressing`、`virus`、`error`、`dead`。这些状态需要本次活动无法合法获得的内容才会出现。

### 每个状态下有哪些线路字段 {#which-wire-fields-exist-in-which-status}

这比词汇本身更重要。字段会出现，也会消失。如果映射器在每个状态下都去读 `speed`，那么有一半的时候它读到的都是一个不存在的键。

| 字段 | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | 有 | 有 | 有 | 有 | 有 |
| `progress` | 0 | 0 | **浮点百分比**，0 到 100 | **从 0 重新开始**并攀升到 100 | 100 |
| `seeders` | 有 | **缺失** | 有 | **缺失** | **缺失** |
| `speed` | **缺失** | **缺失** | 有，单位为字节每秒 | 有，抓取数据中始终为 0 | **缺失** |
| `bytes` / `original_bytes` | 0 | 真实大小 | 真实大小 | 真实大小 | 真实大小 |
| `filename` | `"Magnet"` | 真实名称 | 真实名称 | 真实名称 | 真实名称 |
| `files` | `[]` | 有内容 | 有内容 | 有内容 | 有内容 |
| `links` | `[]` | `[]` | `[]` | 在该阶段逐步填充 | 有内容 |
| `ended` | 缺失 | 缺失 | 缺失 | 缺失 | 有 |

`progress` 是**浮点数**，不是整数。抓取的数据里除了 100，还有 0.4、0.8 和 1.4。如果卡顿检测器把百分比取整，那么一个 100 GB 的资源即使以 1 MB/s 的速度正常下载，也会被误判为卡住了。

`progress` **会故意倒退**。当 status 变为 `uploading` 时，它会重置为 0，然后再次攀升到 100。判断是否有进展，必须以阶段变化或 progress 增长来定义，绝不能把它当作单调递增的百分比。

当种子离开 `downloading` 状态后，`seeders` 不会变成 0，而是直接消失。`speed` 也是如此。映射器必须把缺失的键视为未知，而不是 0。

### 每种情况的表现 {#what-each-case-did}

| Case | Torrent | Transitions with seconds from add | Verdict |
|---|---|---|---|
| cached | Big Buck Bunny | `downloaded`@0.0 | 端到端 1.32 秒完成 |
| cached | Sintel | `downloaded`@0.0 | 0.73 秒完成 |
| cached | Ubuntu 26.04.1 | `downloaded`@0.0 | 0.32 秒完成 |
| uncached | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | 此账户上已缓存 |
| uncached | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | 完成。3.71 GiB，用时 197 秒 |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | 失败 |
| seedless | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | 完成。未复现该问题 |
| seedless | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 之后再无状态变化 | **在 907.6 秒时仍为 `downloading`，已超时停止**。这就是卡住的表现 |
| nometa | random 40-hex | `magnet_conversion`@0.0 `magnet_error`@317.9 | 失败 |

### 缓存添加的延迟 {#the-cached-add-latency}

这就是适配层的仅缓存模式所依据的数字。

| Torrent | addMagnet 返回 | selectFiles 返回 | 第一次 `/torrents/info` | status |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**观察结果。** 缓存过的种子在 `selectFiles` 之后的第一次读取时就已经是 `downloaded` 了。整个同步过程的耗时就是两次往返请求。它从不经过 `queued`，也从不经过 `downloading`。

第二次运行在 `addMagnet` 和 `selectFiles` 之间，以及之后，每隔 0.25 s 轮询一次 `/torrents/info`。`--rd-select-detail` 就是这么做的，结果也确定了整体形态。

| Torrent | `selectFiles` 之前的状态 | `selectFiles` | 之后的第一次读取 | addMagnet 到 `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection`，列出 3 个文件，`links` 为空 | 在 t+1.314 s 返回 204 | `downloaded`，`progress` 100，`links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection`，列出 11 个文件 | 在 t+0.627 s 返回 204 | `downloaded`，`progress` 100，`links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection`，列出 1 个文件 | 在 t+0.219 s 返回 204 | `downloaded`，`progress` 100，`links` 1 | **0.430 s** |

所以完整的缓存流程就是 `waiting_files_selection` 紧接着 `downloaded`，中间没有别的状态。文件列表在 `selectFiles` 之前就已经有了。`links` 是 `selectFiles` 填上的。

**仅缓存的探测窗口只需要一次轮询。** 三个种子，大小分别是 123 MiB、264 MiB 和 6.04 GiB，从头到尾耗时 0.43 s 到 1.54 s。两秒的窗口，配合四分之一秒的轮询间隔，已经非常宽裕了。

Sonarr 和 Radarr 允许 `torrents/add` 调用最多等待 100 s（见 [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)）。与之相比，几秒的仅缓存探测窗口几乎没有成本。没有理由把它设成几十秒。

### 阶段映射器必须应对的怪癖 {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` 在种子仍处于 `magnet_conversion` 时返回 404，而且错误信息有误。**
  返回内容是 `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}`，但我们明明发送了 `files=all`。其实只是还没有可选的文件。这不是添加失败，种子仍然有效。两次遇到这个情况的运行都又存活了 318 秒。
- **私有 tracker 的 hash 可能立刻被判定失败，而不是等到 318 秒。** 2026-08-31 的 qBittorrent 报告中，对应的 hash（来自 UNIT3D 索引站的 CiNEPHiLES remux，`45e1ec0d…`）在 addMagnet 之后第一次读取时就返回 `magnet_error`，且没有任何文件，中间完全没有 `magnet_conversion` 阶段，添加后几秒就失败了。无论 Real-Debrid 是识别出了这个 hash，还是很快就对它失败，表现都一样：私有 hash 没有 DHT 节点群，所以 addMagnet 对它永远不会成功。而在已失效的实例上调用 selectFiles，又会返回前面提到的那个误导性的 404。
- **`addTorrent` 对未缓存的内容什么都不跳过，对已缓存的却全部跳过。** 为 Real-Debrid 没有的内容上传的 `.torrent`（archive.org 上的 Big Buck Bunny，有做种但未缓存），和普通磁力链接一样进入 `magnet_conversion`，文件的元数据并没有被用来解析。已缓存的那个（一个 Ubuntu ISO）在第一次读取时就返回 `waiting_files_selection` 并带上文件列表，被选中后不到两秒就变成 `downloaded`，完全没有经过 `magnet_conversion`。所以上传的价值在于能立即查到 hash 对应的缓存。这正是私有 tracker 的资源只要内容已缓存就能添加成功、而用磁力链接则永远无法添加的原因。
- **元数据解析在 318 秒后放弃。** 两次独立运行都从 `magnet_conversion` 变成了 `magnet_error`，时间分别是 317.9 秒和 318.0 秒。这是没有可连接节点的磁力链接会撞上的时间上限。无论该 hash 是否真的存在种子，结果都一样。
- **`seeders` 在 `magnet_conversion` 期间是错的。** 那个随机生成的 40 位十六进制 hash 在 80.9 秒时报告 `seeders: 1`，但实际上根本不存在这个种子。
- **刚添加的已缓存种子，其 `ended` 日期很旧。** 抓取的数据里，2026-08-30 添加的种子显示的是 `2025-12-28` 和 `2026-07-28`。这是 Real-Debrid 第一次拥有该内容的时间，而不是本实例完成下载的时间。不要用它来计算种子的年龄。
- **零节点的磁力链接在元数据解析阶段就失败了，永远到不了 webseed。** Real-Debrid 在拿到种子之后确实会使用 webseed。但它无法从没有节点的磁力链接中获取种子。所以只有 webseed 的资源如果以磁力链接添加，最终会是 `magnet_error`。这属于元数据失败，而不是 webseed 失败。从 `/torrents/info` 看，两者表现完全相同。

## AllDebrid

### 端点 {#endpoints-1}

`v4` 和 `v4.1` 不能互换，这个差异正好影响了本次测试。

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**文件上传的结果在 `files` 下返回，而不是 `magnets`。** 每个条目的字段相同，包括 `id`、`hash`、`name`、`ready` 和可选的单条 `error`，所以下面的 `ready` 标志在两种情况下都是缓存结果。但如果解码器是按磁力链接的响应写的，它读到的会是空列表。

**而且只有文件形式，AllDebrid 才能在没有 swarm 的情况下描述一个资源。** 2026-09-01 在测试账号上测得：两个结构相同的合成私有种子，哈希都是 swarm 从未见过的。以文件形式上传时，返回了真实的名称和大小（`"name":"zurg.private.ad.probe","size":65536`），列表状态为 `In queue`，计时还没开始。如果以单纯的 `magnets[]` 哈希发送，返回的是 `"name":"noname","size":0`。AllDebrid 接受了它，但对它一无所知。这正是所有私有 tracker 的资源通过哈希添加时的情况。

**`/v4/magnet/status` 已经停用。** 无论是否带 id，它都会返回 HTTP 200，内容为 `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`。`/v4/magnet/upload` 和 `/v4/magnet/delete` 仍然可用。因此，计划中“可以使用 v4 状态接口，并抽样一次 v4.1 做对比”的假设是错误的。v4.1 是唯一可用的状态接口。测试工具会为每个种子保留一次 v4 读取，让抓取记录本身作为证据，而不是只靠结论。

鉴权方式是 `Authorization: Bearer <apikey>`。不需要 `agent` 参数。

### 观察到的状态值 {#status-values-observed-1}

| `statusCode` | `status` | 已见 |
|---|---|---|
| 0 | `In queue` | 是 |
| 1 | `Downloading` | 是 |
| 2 | `Compressing / Moving` | **否** |
| 3 | `Uploading` | 是 |
| 4 | `Ready` | 是 |
| 5 及以上 | 错误代码 | **否** |

### 每个状态下有哪些线路字段 {#which-wire-fields-exist-in-which-status-1}

| 字段 | 排队中 (0) | 下载中 (1) | 上传中 (3) | 就绪 (4) |
|---|---|---|---|---|
| `status` / `statusCode` | 是 | 是 | 是 | 是 |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | 元数据到达前为 `"noname"` | 元数据到达后为真实名称 | 真实名称 | 真实名称 |
| `size` | 元数据到达前为 0 | 真实大小 | 真实大小 | 真实大小 |
| `downloaded` | 0 | **进度数值，单位为字节** | 等于 `size` | **不存在** |
| `downloadSpeed` | 0 | 是，单位为每秒字节数 | 0 | **不存在** |
| `seeders` | 0 | 是 | 0 | **不存在** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **该阶段的进度数值** | **不存在** |
| `processingPerc` | 0 | 0 | 0 | **不存在** |
| `files` / `nbLinks` | 不存在 | 不存在 | 不存在 | 存在 |
| `completionDate` | 0 | 0 | 0 | 已设置 |

**任何地方都没有百分比。** AllDebrid 的进度是 `downloaded / size`，两者都是以字节为单位的整数。在每次抓取的每个状态下，`processingPerc` 都保持为 0。

`Uploading` 是 AllDebrid 把已完成的下载移入其自有存储的阶段。它有自己的进度计数器，即 `uploaded` 和 `uploadSpeed`，整个阶段中其 `downloadSpeed` 都是 0。如果停滞规则只监控 `downloaded`，就会把正常的 `Uploading` 阶段判定为停滞。

### 每种情况的表现 {#what-each-case-did-1}

| 类型 | 种子 | 上传时的 `ready` | 从添加开始的秒数状态变化 | 结果 |
|---|---|---|---|---|
| cached | Big Buck Bunny | true | `Ready`@0.0 | 0.11 秒内完成 |
| cached | Sintel | true | `Ready`@0.0 | 0.12 秒内完成 |
| cached | Ubuntu 26.04.1 | true | `Ready`@0.0 | 0.11 秒内完成 |
| uncached | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | 已缓存 |
| uncached | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5，直到 634.9 之前所有计数器都为 0，`Uploading`@650.1 `Ready`@876.9 | 877 秒完成 |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3，之后所有计数器都为 0 | **907.8 秒时达到上限，仍处于 `Downloading`** |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4，直到 589.6 之前所有计数器都为 0，`Uploading`@619.9 `Ready`@650.2 | 650 秒完成 |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2，之后所有计数器都为 0 | **907.0 秒时达到上限，仍处于 `Downloading`** |
| nometa | random 40-hex | false | `In queue`@0.0 `Downloading`@9.4，之后所有计数器都为 0 | **907.4 秒时达到上限，仍处于 `Downloading`** |

针对 Debian 13.3.0 arm64 DVD-1（`6aa9b0a4709a0d6c4982fd0363614d9006877223`）的一次单独运行，捕获到了完整的未缓存生命周期，可以作为参考时序。

| 秒数 | 状态 | 变化内容 |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` 为 `"noname"`，`size` 为 0 |
| 2.2 | `Downloading` 1 version 2 | 仍然没有名称和大小 |
| 4.3 | `Downloading` | `filename` 和 `size` 已解析出来 |
| 6.5 到 55.1 | `Downloading` | `downloaded` 逐渐增长到 `size`。`downloadSpeed` 峰值接近 110 MB/s。`seeders` 从 8 增加到 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` 降到 0。`uploadSpeed` 和 `uploaded` 开始上升 |
| 65.6 | `Ready` 4 | `files` 和 `nbLinks` 出现。六个进度字段消失 |

3.72 GiB，用时 65.6 秒。

### AllDebrid 在任务等待自身基础设施时完全不报告进度 {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

这是最能改变超时设计的发现，而且经过两次独立运行才确认可信。

`Downloading` 且 `statusCode` 为 1 的状态在上传后几秒内就会出现。之后有一段时间，AllDebrid 会报告 `downloaded` 为 0、`downloadSpeed` 为 0、`seeders` 为 0、`uploaded` 为 0、`uploadSpeed` 为 0、`processingPerc` 为 0。即使之前已经正确报告过 `size` 和 `filename`，它也会把两者重新设为 0 和信息哈希。

| 运行 | 所有计数器保持为零的时长 | 之后发生了什么 |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 秒**，从 12.5 秒到 634.9 秒 | 15 秒内下载了 3.71 GiB，然后是 `Uploading`，876.9 秒时变为 `Ready` |
| ubuntu-16.04.6-desktop-i386 | **580 秒**，从 9.4 秒到 589.6 秒 | 30 秒内下载了 1.56 GiB，然后是 `Uploading`，650.2 秒时变为 `Ready` |

两个任务都完成了。前十分钟里，两者都没有报告任何一个字节的变化。

**十分钟的无进度超时会误杀健康的 AllDebrid 任务。** 建议的 `download_timeout_mins` 默认值 10，两次测试都落在这个时间窗口内。要么超时时间必须更长，要么 AllDebrid 的 `Downloading` 且 `size` 为 0 应当被视为一个独立阶段，计时器不对它计时。丢失名称和大小，是 AllDebrid 表示任务已分配但尚未开始的方式，并不是失败。

对比之下，有一次运行立刻就开始了：Debian 13.3.0 arm64 DVD-1 从 `In queue` 到出现真实字节计数只用了 6.5 秒。所以这段等待是排队，而不是固定的延迟。

### `ready` 标志是真实的缓存结果 {#the-ready-flag-is-a-real-cache-answer}

`/v4/magnet/upload` 响应里的 `ready` 字段，对 TorBox 也判定为已缓存的每个 hash 都是 true，对活动里下载的那两个 hash 则是 false。AllDebrid 没有单独的缓存探测接口，所以这个标志就是它的全部缓存信号。现在 zurg 会从两条添加路径（磁力链接和文件上传）中都取出它，作为 `MagnetResponse.Cached` 返回，并同时设置 `CacheKnown`。这样，无法回答的后端就不会被误认为是“未缓存”的结果。

**`ready` 为 false 意味着磁力链接已经被添加了。** 在不添加的情况下，没有办法向 AllDebrid 询问某个 hash 是否已缓存。因此，在 AllDebrid 上只走缓存路径时，必须把这次未命中的添加删掉。

## TorBox

### 端点 {#endpoints-2}

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### 观察到的状态值 {#status-values-observed-2}

`metaDL`、`checking`、`stalledDL`、`stalled (no seeds)`、`downloading`、`processing`
`uploading (no peers)`、`uploading`、`cached`

`processing`、`checking` 和 `stalledDL` **都不在 zurg 的翻译表中**
（`internal/torbox/types.go` `normalizeStatus`）。这三个都会落到默认分支，被报告为
`downloading`。

`checking` 是 TorBox 等待元数据的阶段，而不是校验哈希的阶段。如果磁力链接对应的 swarm 一直没有响应，它会先变成 `metaDL`，然后变成 `checking`，并一直停在那里。随机的 40 位十六进制哈希在 910 秒上限时仍是 `checking`，零 peer 的 Prelinger 条目在 911 秒时也是如此。TorBox 从不像 Real-Debrid 那样在 318 秒时放弃。

**上传 `.torrent` 文件会完全跳过这段等待，对于私有 tracker 的发布内容来说，这正是最大的区别。** 2026-09-01 在上面的账户上测试时，同一个合成的私有种子用两种方式发送。以哈希方式发送：被接受并返回 `torrent_id`，随后是 `checking`，其 `name` 只是光秃秃的哈希，`size: -1`、`files: null`、`eta: 8640000`——TorBox 在查找一个不在 DHT 中的 swarm，它会一直找到上限，并且不会报告任何相关信息。以文件方式发送，通过 `POST /torrents/createtorrent`，把字节放在 multipart 的 `file` 部分中：三秒后读回，显示的是种子自己的名称、真实大小，以及 `stalled (no seeds)`——内容同样没有人持有，但现在有了描述。关键在于阶段。`size: -1` 的 `checking` 映射为 `StageResolvingMetadata`，表示仍在处理中，无法得出任何结论；`stalled (no seeds)` 映射为 `StageStalledNoPeers`，qBittorrent 端点可以据此采取行动。一个已缓存的发布内容在同样的三秒内读回时为 `done`，进度 100%，并且文件列表已经在内。部件名称至关重要：用其他名称发送的文件根本不会被识别，端点会返回 `MISSING_REQUIRED_OPTION`，"You must provide either a file or magnet link"。

（之前的译文被驳回：代码片段不一致（` maps to `）。请保持结构完全不变。）

### 每个状态下有哪些线路字段 {#which-wire-fields-exist-in-which-status-2}

TorBox 在每个状态下都发送同一组键，只是改变其中的值。因此在这三者中，它最容易读。真正承载含义的是这些值。

| 状态 | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | 很小 | 8640000 | 真实值 |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | 真实值 |
| `downloading` | false 然后 **true** | false | false | true | 小数 | 秒 | 真实值 |
| `processing` | **true** | **false** | false | true | 1 | 秒 | 真实值 |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | 真实值 |
| `uploading` | true | **true** | true | true | 1 | 0 | 真实值 |
| `cached` | true | true | true | false | 1 | 0 | 真实值 |

字段名。计划中把这些字段都列为未经验证。

| 内容 | TorBox 字段 | 格式 |
|---|---|---|
| 进度 | `progress` | **一个小数**，不是百分比。`0.0793719` |
| 做种数 | `seeds` | 整数 |
| 下载者数 | `peers` | 整数 |
| 下载速率 | `download_speed` | 每秒字节数 |
| 上传速率 | `upload_speed` | 每秒字节数 |
| eta | `eta` | 秒。`8640000` 是表示未知的占位值 |
| 已获取字节数 | `total_downloaded` | 整数 |
| 资源健康度 | `availability` | 浮点数。在 `uploading (no peers)` 状态下会变成 **-1** |
| 数据位置 | `download_path` | 数据就绪前为 null |

`8640000` 等于 100 天。这是 TorBox 表示“不知道”的方式。zurg 的 shim 在没有数据可报时交给 Sonarr 的，也是同一个常量。

### 每种情况的表现 {#what-each-case-did-2}

| 类别 | 种子 | `checkcached` | 从添加开始计时的状态转换 | 结论 |
|---|---|---|---|---|
| 已缓存 | Big Buck Bunny | true | `cached`@0.0 | 在 0.83 s 内完成 |
| 已缓存 | Sintel | true | `cached`@0.0 | 在 0.94 s 内完成 |
| 已缓存 | Ubuntu 26.04.1 | true | `cached`@0.0 | 在 0.69 s 内完成 |
| 未缓存 | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 然后 **gone**@48.6 | 在 86.7% 时被另一个 zurg 删除 |
| 未缓存 | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 然后 **gone**@86.7 | 被另一个 zurg 删除 |
| 网络种子 | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 之后再没有其他状态 | **在 `checking` 状态下于 911.3 s 时超时**。TorBox 没有使用网络种子 |
| 无做种者 | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 然后 **gone**@200.4 | 在 `processing` 时被另一个 zurg 删除 |
| 无做种者 | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 然后 **gone**@462.3 | 在 91.9% 时被另一个 zurg 删除 |
| 无元数据 | 随机 40 位十六进制 | false | `metaDL`@0.0 `checking`@10.2 之后再没有其他状态 | **在 `checking` 状态下于 910.3 s 时超时** |

在 0.5 s 轮询间隔下，对 Debian 13.5.0 amd64 netinst
（`58846860f0a766f8a42b0bb214d8c713fdf1b167`）单独运行了一次。它存活的时间足够长，达到了 done，所以可以作为参考序列。

| 秒数 | 状态 | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB，用时 64.4 s。

这最后三行值得仔细看两遍。TorBox 大约在数据真正就绪**之前**十秒，就把 `download_finished` 设为 true，把 `progress` 设为 1。然后它又回到 `downloading`，进度值比它刚报告的还要低。在健康的下载中，`progress` 和 `download_state` 都会倒退。

---

## 阶段表 {#the-stage-table}

shim 将使用的 stage 枚举值为 `resolving-metadata` `queued` `downloading` `stalled-no-peers`
`finalizing` `done` `failed`，未知时使用空字符串。

### Real-Debrid

| 原始 `status` | 阶段 | 依据 |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **已观察到**。`bytes` 为 0，`files` 为空，`filename` 为字面值 `"Magnet"` |
| `waiting_files_selection` | `queued` | **已观察到**，使用 `--rd-select-detail` 时可见。文件列表已经出现。`links` 为空 |
| `queued` | `queued` | **已观察到**。真实大小和真实名称已经知道。没有 `seeders` 和 `speed` |
| `downloading` | `downloading` | **已观察到** |
| `downloading` 且 `seeders` 为 0 | `stalled-no-peers` | **已观察到**。92 次轮询中，`progress` 为 0、`seeders` 为 0、`speed` 为 0，持续了 904 秒 |
| `compressing` | `finalizing` | **推断**。没有实际见过 |
| `uploading` | `finalizing` | **已观察到**。进度从 0 重新开始，`seeders` 消失 |
| `downloaded` | `done` | **已观察到** |
| `magnet_error` | `failed` | **已观察到**，在 `magnet_conversion` 阶段持续 318 秒后出现 |
| `error` `virus` `dead` | `failed` | **推断**。没有实际见过 |

### AllDebrid

| `statusCode` | 阶段 | 依据 |
|---|---|---|
| 0 `In queue` | `queued` | **已观察到**。持续几秒钟。`filename` 可能仍为 `"noname"`，`size` 为 0 |
| 1 `Downloading` 且 `size` 为 0 | `queued` | **已观察到**。不是 `downloading`，也不是 `stalled-no-peers`。AllDebrid 已接收任务但尚未开始。在两次运行中分别停留 622 s 和 580 s，之后完成 |
| 1 `Downloading` 且 `size` 为真实值 | `downloading` | **已观察到** |
| 1 `Downloading` 且 `seeders` 为 0、`downloaded` 不变 | `stalled-no-peers` | **未观察到，也无法安全推断**。见下文 |
| 2 `Compressing / Moving` | `finalizing` | **推断得出**。未见到 |
| 3 `Uploading` | `finalizing` | **已观察到**。进度在这里由 `uploaded` 和 `uploadSpeed` 体现，`downloadSpeed` 为 0 |
| 4 `Ready` | `done` | **已观察到** |
| 5 及以上 | `failed` | **推断得出**。未见到 |

**AllDebrid 没有可观察到的停滞特征。** 一个 AllDebrid 已排队的任务和一个 AllDebrid 无法推进的任务，在网络上看起来完全相同。两者都是 `statusCode` 为 1、`size` 为 0，所有计数器都为零。Prelinger 条目在整个 907.8 s 上限内都处于这种状态，另外两个种子各自在这种状态下停留了十分钟，然后完成了。因此 AllDebrid 的响应中没有任何内容能区分这两者，AllDebrid 上的停滞判定只能依靠计时器。

（之前的译文被拒绝：代码片段不一致。请保持结构完全一致。）

### TorBox

| 原始 `download_state` | 阶段 | 依据 |
|---|---|---|
| `metaDL` | `resolving-metadata` | **已观察到**。`size` 为 0，`name` 与哈希值相同 |
| `checking` | `resolving-metadata` | **已观察到**。等待期间 `size` 为 **-1**。这是 TorBox 在等待种子，而不是在做哈希校验。zurg 目前的表中没有这一项 |
| `stalledDL` | `stalled-no-peers` | **已观察到**。zurg 目前的表中没有这一项 |
| `stalled (no seeds)` | `stalled-no-peers` | **已观察到**。名称说得有点夸张。有两次抓取在这个状态下 `seeds` 分别为 1 和 2。zurg 目前把它映射为 `queued` |
| `downloading` | `downloading` | **已观察到** |
| `processing` | `finalizing` | **已观察到**。zurg 目前的表中没有这一项 |
| `uploading (no peers)` | `finalizing` | **已观察到**，此时 `download_present` 为 false |
| `uploading` | `done` | **已观察到**，此时 `download_present` 为 true |
| `cached` `completed` `seeding` | `done` | `cached` **已观察到**。另外两个为**推断**得出 |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **推断**得出。尚未见到 |

**`download_finished` 和 `download_present` 这一对字段不能替代状态字符串。** `processing`、`uploading (no peers)` 以及部分 `downloading` 的情况，都会出现 `download_finished: true` 且 `download_present: false` 的组合。这是正常的收尾阶段，而不是已失效的种子。请参阅下面的注意事项。

---

## 无法测量的内容 {#what-could-not-be-measured}

- **在两个候选种子中，有一个复现了无做种的情况。** 两个种子在 tracker 上的做种者数都是零。
  ubuntu-16.04.6-desktop-i386 在三个服务商上仍然都下载成功，因为 DHT 提供了 tracker 不知道的 peer。
  ubuntu-24.04-beta-live-server-s390x 在 Real-Debrid 上卡住，一直到超时上限，也就是上面提到的卡住现象。
  在 tracker 上抓取到零，只是个较弱的预测指标。测试用例里保留两个候选种子。无论如何，Real-Debrid 对这两个种子都已经拿到了元数据，并且在第一次 `queued` 读取时就正确返回了 `bytes` 和 `filename`。
- **从未见到 Real-Debrid 的 `compressing` 状态。** 每次完整运行都是从 `downloading` 直接变成 `uploading`。
- **从未见到 AllDebrid 的状态码 2。** 每次抓取都是从 1 直接变成 3。
- **没有任何服务商触发过它自己的错误状态。** Real-Debrid 的 `error`、`virus` 和 `dead`，以及上面提到的 AllDebrid 所有大于 4 的状态码，还有 TorBox 的所有失败状态，都没有测到。要触发这些状态，需要被屏蔽、带病毒或已失效的内容，而不是 FOSS ISO。
- **TorBox 很少能完整跟踪到下载完成。** 测试批次中的四个种子和后续的一个种子，在下载途中被账号上另一个 zurg 删除了。详见下面的风险说明。只有一个 754 MiB 的镜像在那个进程下一次轮询之前完成了下载。

---

## 途中发现的隐患 {#hazards-found-on-the-way}

### TorBox 账户上的第二个 zurg 会删除正常的下载 {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

另一个 zurg 实例使用同一个 TorBox 账户，它的配置如下：

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**五个**探测用种子在正常下载时被删除了。这一点在**两边都能观察到**。测试脚本看到每个种子消失，另一个实例的日志也写明了原因。

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

这五个分别是 `86695315`、`86695708`、`86697191`、`86702627`、`86704212`。它们的原因都一样，而且都不是坏种子。

问题出在 `internal/torbox/types.go` 中 `normalizeStatus` 的第二条规则。

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

这种状态组合其实是 TorBox 的正常收尾阶段。0.5 秒一次的抓取给出了具体数字：在一个 754 MiB 的镜像上，从 `download_finished` 变为 true 到 `download_present` 变为 true，中间隔了 **9.6 秒**；在一个 3.7 GiB 的镜像上，这段时间至少有 17 秒，而清理恰好落在这段时间里。另一个 zurg 大约每 15 秒轮询一次库。所以，一个正常的 TorBox 下载能不能撑过自己的完成阶段，基本就是五五开。

这会带来三个后果。第一，用户在 TorBox 界面里看着完成的下载，可能已经从 zurg 库里消失了。第二，`delete_error_torrents` 的文档说它删除的是服务商标记为出错的种子，但这里它删掉的却是服务商标记为正常的种子。第三，在这个账户上对 TorBox 做的任何测量，都是在和这次清理抢时间。

**这里不修复。** 阶段 0 只负责测量，修复应该放到分阶段的工作中去做。到那时，`download_finished && !download_present` 应该被标记为 `finalizing`，而不是 `failed`。

### AllDebrid 账户上的第二个 zurg 侥幸未出问题 {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

用于此次活动的 AllDebrid 密钥，也被另一个 zurg 实例加载了，并且使用了与 TorBox 相同的三个 sweep 设置。

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

没有删除任何 AllDebrid 探测。原因在代码里，而不是运气好。`internal/alldebrid/types.go` 中的 `normalizeStatus` 只把大于等于 5 的状态码映射为 `error`，没有 `download_finished && !download_present` 这类结构性规则。所以一个正常的 AllDebrid 下载永远不会被误判为损坏。TorBox 的 bug 只是多出了这一条规则，而不是整体的 sweep 问题。

Real-Debrid 比较特殊。测试账号没有被其他 zurg 加载，没有任何东西在清理它，也没有任何东西干扰它。

### TorBox 对未知 id 的删除请求返回 HTTP 500 {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` 的返回也一样。所以一个已经不存在的种子，只看状态码，和 TorBox 故障是分不出来的。
zurg 会把它报告为 `account temporarily unavailable`。另一个实例的日志显示，它每 15 秒就重试一次删除已经删掉的
id。测试框架的应对办法是：删除失败后，再查一次 `mylist`，如果种子已经不在了，就当作已删除处理。

### 未出现 Real-Debrid 限流 {#real-debrid-throttling-did-not-appear}

九次添加、间隔 20 秒,整轮下来 451 和 429 都是零次。这和根目录 `CLAUDE.md` 里的记录一致:6 次添加、间隔 10 秒,结果 0/6;同样 6 次、间隔 20 秒,结果 6/6。20 秒这个下限是真有用的,不是什么迷信。

## 重新运行测试 {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Run it from a machine with residential egress. AllDebrid answers `NO_SERVER` to datacenter IPs.

Step 6 is not optional and step 3 is what makes it meaningful. After the 2026-08-30 campaign not one of the 34 instance ids the harness had claimed was left on any of the three accounts. Neither was any of the nine probe hashes.

Before touching TorBox, check whether any other zurg is loaded with the same account, read its sweep settings and expect the sweep described above.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Never change it. A probe that disappears mid-run is data.
