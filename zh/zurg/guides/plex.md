# Plex 功能与能力 {#plex-features--capabilities}

是和 Plex Media Server 一起运行 rex，还是用 rex 替代它？[从 Plex 迁移到 rex](../../rex/from-plex.md) 说明了 zurg 中哪些内容要保留（包括你的 rclone 挂载），以及要删除 zurg 的哪些 Plex 设置。

## 配置与存储 {#configuration--storage}
- 在 [`config.md`](../reference/config.md)/`config.example.yml` 中记录的配置项：`plex_server_url`、`plex_token`、`plex_match_every_mins`（默认 1440）、`plex_watchlist_enabled`、`plex_watchlist_check_every_secs`（`watchlist.check_every_secs` 的旧写法，默认 60 秒）、`mount_path`（匹配和扫描路径构建时必需）。仪表板中设置的选项会通过配置写入器（`updateConfigFileAtomic`）直接保存到 `config.yml`。
- 对于 0 或更小的值，watchlist 间隔会回退到默认值（`GetWatchlistCheckEverySecs`）；`plex_match_every_mins` 只有在正好为 `0` 时才会回退（`intOr`，`internal/config/config.go`）。两者都无法被禁用。仪表板会拒绝小于 1 的值（`internal/handlers/dashboard/dashboard.go`）。如果 `config.yml` 中的 `plex_match_every_mins` 是负数，zurg 启动时会报 `is negative; use 0 for the default` 并停止运行；它不会关闭匹配功能。
- watchlist 的获取由 `watchlist:` 配置块控制，包括 `enabled`、`check_every_secs`、`indexers`、`max_size_gb`、`max_season_size_gb` 和 `quality`（默认 `best`）。如果 `indexers` 为空，则借用 `stremio.indexers`。扁平的 `plex_watchlist_enabled`、`plex_watchlist_check_every_secs` 和 `watchlist_quality` 仍然是前三者（enabled、check_every_secs、quality）的旧写法。参见 [config.md](../reference/config.md#watchlist)。
- `mount_path` 也是发送给 Plex 的扫描路径以及受管 rclone 挂载的前缀（[`config.md`](../reference/config.md)，`pkg/scan/scanner.go`）。
- 库更新钩子（`on_library_update`）会把每个变更路径作为参数传入，经过 500 毫秒防抖和去重，且同一时间只运行一次，用于支持 Plex 自动扫描脚本（`internal/torrent/hooks.go`）。

## 认证与服务器发现 {#authentication--server-discovery}
- Web dashboard 流程:`/plex/auth` 会创建一个 PIN 会话(`pkg/plex/auth.go`,`CreatePlexAuthURL`),把它存进 `pkg/plex/auth_session.go`(10 分钟后自动清理,每 5 分钟扫描一次),然后通过 `/plex/auth/status` 轮询授权是否完成(`PollForAuthToken`,每 5 秒一次,最多 60 次,超时即停止)。
- `/plex/callback` 会显示一个进度页面。授权完成后,页面调用 `/plex/servers` 列出服务器,再调用 `/plex/server` 选择其中一个(`internal/handlers/dashboard/dashboard.go`)。
- 服务器发现(`pkg/plex/auth.go`):会获取带有 HTTP/HTTPS 两种端点的 Plex 资源,如果存在直连端点就过滤掉中继端点,处理 IPv6 地址,并对每个条目的 `/identity` 发起探测(TLS 验证已禁用)。只会考虑账号**拥有**的服务器(`auth.go` 中的 `device.Owned`),共享给你的服务器永远不会出现。探测失败的条目会直接从响应中剔除,而不是带着 `last_error` 返回(`enrichServersWithIdentity`,`auth.go`)。
- 选择服务器后会写入 `plex_server_url`/`plex_token` 到配置中,重新初始化 Plex 客户端,(重新)启动匹配调度器,触发一次匹配,并刷新缓存的仪表盘状态(`HandlePlexServerSelect`,`internal/handlers/dashboard/dashboard.go`)。`/plex/logout` 会清空已保存的值以及状态缓存。

## Plex 客户端能力（`pkg/plex/client.go`） {#plex-client-capabilities-pkgplexclientgo}
- 连接生命周期：延迟启动选项（`WithDeferredStart`）、用 `ValidateConnection` 防范 `/identity` 相关的问题，以及优雅关闭 `Close`。没有重启 API。仪表盘里的 `RestartAllowed`/`RestartReason` 是根据服务器地址（本地/局域网还是远程）推断出来的，只用于显示（`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`）。
- 扫描队列：动态作业队列/工作者（`common.DynamicJobQueue`）。`ProcessJob` 会发出 `GET /library/sections/{key}/refresh` 请求，带上 Plex 请求头，每个作业**最多只能带一个** `path` 查询参数，多于一个会被直接拒绝（`client.go`）。没有路径的作业就是整个分区的刷新。503 会变成服务器繁忙错误，404 会报告该媒体库已从 Plex 中删除。`GetJobQueueSize` 可以查看积压的作业数。
- 负载与卡住检测：`CheckServerLoad` 会检查 `/activities`，按 UUID 跟踪每个 `library.update.section` 的进度（进度或副标题有变化都算有进展）。`IsJobStuck` 通过 `librarySectionID` 标记卡住的作业，找不到时回退到按标题匹配。`GetServerActivitiesDetails` 也会创建和回收同样的跟踪器。原因是 `CheckServerLoad` 只在工作者有作业排队时才运行。以前 Plex 自己启动的扫描没有任何跟踪器，所以永远不会被报告为卡住，每次刷新时它的耗时都显示为零。两条路径都只为 `library.update.section` 保留历史记录；如果在这里跟踪其他类型，会和工作者的清理逻辑互相冲突，导致状态来回跳动。
- **活动副标题并不是暂停扫描正在等待的那个文件。** 2026-09-15 在 plex503 测试环境上测得：`library.update.section` 的副标题是扫描器的枚举指针，它比实际读取走得更快。挂载拒绝了三个文件的情况下，它指向的是第四个从未被请求过的文件；被阻塞的那个文件只在 56 秒的周期中出现了 290 毫秒。仪表盘将其显示为“Plex reports”，且不会把它关联到具体的发布版本。扫描真正在等什么，要看 zurg 自己的拒绝记录（`internal/universal/refused_reads.go`），只有它掌握这些信息。测试数据位于 `internal/handlers/dashboard/testdata/plex503-*`。
- 媒体库查询：`GetSections`（带位置信息的电影/剧集分区）、`GetSectionItemCount`、`FindSectionNormalized`（把路径和分区位置做匹配，并把前缀修正为媒体库的大小写）、`GetAllMediaItemsConcurrent`（分批、并发获取，配合 `includeGuids` 收集路径、GUID 和 IMDB ID），以及 `GetShowLevelIMDBIndex`（为电视分区获取剧集级别的 ID，让单集可以继承这些 ID）。
- 元数据与匹配辅助函数（`pkg/plex/match.go`）：`GetMetadataSummary`（`GET /library/metadata/{ratingKey}`）、`GetMatchCandidates`（`GET /library/metadata/{ratingKey}/matches?manual=1`，支持标题/年份/语言覆盖）、`LookupMetadataByGUID`/`LookupRatingKeyByGUID`（`GET /library/all?guid=…`）、`ApplyManualMatch`（`PUT /library/metadata/{ratingKey}/match`），以及 GUID 解析（`ExtractIMDBIDFromGUID`、`ExtractTMDBIDFromGUID`、`ExtractTVDBIDFromGUID`、`ExtractAnyIDFromGUIDs`；`MatchResult`/`MatchSelection` 类型）。
- 服务器信息：`GetServerIdentityOnly` 和 `GetServerDetails`（机器 ID/版本；后者还会汇总会话、转码和带宽数据）、`GetStreamingSessions`、`GetTranscodeSessions`、`GetServerActivitiesDetails`（附带是否卡住的状态）。
- 观看历史：`GetWatchHistory`（`GET /status/sessions/history/all`）、`GetMetadataBatch`（把用逗号拼接的 rating key 发给 `/library/metadata`），以及 `GetWatchHistoryWithMetadata`（`pkg/plex/history.go`），这些数据用于 `pkg/plex/stats.go` 中的统计。

## 媒体扫描器集成（`pkg/scan/scanner.go`） {#media-scanner-integration-pkgscanscannergo}
- 当设置了 `mount_path`、`plex_server_url` 和 `plex_token` 时初始化 Plex 客户端。连接成功前每 5 秒重试一次，连上后触发 `OnPlexReconnected` 回调。
- `TriggerScan` 会通过 `FindSectionNormalized` 把路径按 Plex 媒体库分组，然后为每个带 mount_path 前缀的路径排入一个刷新任务，每处理 50 个记录一次进度日志。它也支持 Jellyfin/Emby，这两者走的是不分组的路径。如果某个路径不属于任何媒体库，只有当这一批次的*所有*路径都没匹配上时才会发出警告；否则只是一条调试日志。所以一个种子同时存在于媒体库目录和仅 zurg 的目录（最近、音乐……）中时，不会发出警告。
- `ReinitializePlexClient` 允许仪表板更新时实时切换服务器或令牌。
- `GetQueueSizes` 暴露 Plex 队列深度，供 UI 和监控使用。

## 匹配与元数据同步（`internal/plex/matcher.go`、`internal/plex/schedule.go`） {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- 前提条件：需要已配置 Plex URL/token、`mount_path`，以及一个正常运行的 `scanner.PlexClient`；否则会直接返回明确的错误。
- 只有 `PlexRatingKey`（对剧集内容来说是剧集级别的）和 `IMDBID`（`internal/torrent/torrent_types.go`）会存在种子上。Plex 的 GUID 只在处理过程中用于提取 ID 和生成报告，从不持久化。
- 数据收集：从目录映射中拉取所有种子，并通过 `GetAllMediaItemsConcurrent` 获取所有 Plex 条目。在此之前会先运行一次 `GetShowLevelIMDBIndex`，使剧集继承剧集本身的 IMDB/TVDB/TMDB ID，而不是单集级别的 ID。条目以 `GrandparentRatingKey`（如果存在）为键。
- 同步步骤：
  - 将每个已存储的 rating key 与刚获取的 Plex 条目进行核对。如果 Plex 中已不存在该 key，则会连同种子的 IMDB ID 一起清除，并将该种子重新加入匹配队列。
  - 对没有 rating key 的种子进行基于路径的匹配：`buildPlexDirIndex` 会为每个 Plex 文件的每一级小写路径组件建立索引，然后在其中查找种子的 `GetKey`（O(1)，先出现的条目优先）。分配的目录与任何 Plex 库位置都不匹配的种子会先被跳过。
  - IMDB 回填：先使用已获取的批次数据（不调用 API），然后再对每个种子通过 `GetMetadataSummary` 逐个查询（最多 20 个并发）。
  - 检测没有种子对应的 Plex 条目。
  - 把人工设置的哈希+IMDB 配对发送给 DMM，从不发送 Plex 猜测出的 ID。DMM 接收时不带 key；如果设置了 `dmm_api_key`，则一并发送（`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`，`internal/torrent/mediainfo.go`）。
- `MatchSingleTorrent` 对单个种子执行相同的路径查找，用于定向扫描之后立即调用。如果种子已经有 rating key，则不执行任何操作。
- 报告：写入 `logs/match_report.txt`，汇总数量、未匹配的种子、被跳过的种子、没有种子的 Plex 条目，以及缺少 IMDB 的匹配项。
- 调度（`internal/plex/schedule.go`）：每次运行完成后都会写入 `data/plex_match_timestamp`。启动时，只有当该时间戳不存在或早于 `plex_match_every_mins` 时，`StartMatchingJob` 才会立即运行；否则会先等待剩余的时间。它会监听 `TorrentManager.PlexMatchTrigger` 上的手动触发、`ResetPlexMatchTicker` 上的实时间隔修改，并且在任务发生 panic 时最多重试运行三次。
- 手动触发端点 `/plex/match-torrents` 会向触发通道发送信号，并在任务运行中时拒绝执行；`/plex/match-torrents/status` 用于报告当前是否有任务在运行（`internal/handlers/utilities.go`）。

## 手动匹配与管理界面（`internal/handlers/manage`） {#manual-matching--manage-ui-internalhandlersmanage}
- 种子列表筛选器提供了 Plex 状态（`plex_matched`、`plex_in_library_not_matched`、`plex_no_imdb`、`plex_missing_metadata`），方便快速查看（`torrent_list_state.go`）。
- 单个种子的手动匹配页面 `/manage/{hash}/plex-match`：
  - 需要种子已经带有 `PlexRatingKey`（由匹配器设置），否则页面会显示 "torrent is not linked to Plex"。`resolvePlexRatingKey` 会用 `GetMetadataSummary` 验证这个 key，如果缺少 IMDB ID 就从中补上；如果 key 已经过期，则使用种子保存的 `tt…`/`tvdb://`/`tmdb://` ID，通过 `LookupRatingKeyByGUID` 重新解析（`internal/handlers/manage/handler.go`）。
  - 获取 Plex 手动匹配候选项，可以选择覆盖标题、年份和语言（共 44 个语言选项，默认 `en-US`）。匹配结果中会高亮显示当前选中的项（`torrent_matches.go`）。
  - 应用匹配（`HandleApplyPlexMatch`）会调用 `ApplyManualMatch`。因为 Plex 可能会重新分配 key，所以接着用所选的 GUID 重新查找 rating key，然后更新种子的 rating key 和 IMDB（包括用户可选填的 IMDB），保存修改，并带着成功或失败状态重定向。

## Watchlist 获取 {#watchlist-acquisition}

- Plex 观看列表是 `internal/acquisition/plex` 中的一个适配器，和 Seerr 一起运行在共享的获取服务上。现有的观看列表设置仍然有效，你也可以在 `acquisition.sources` 下配置适配器。
- 客户端使用 `discover.provider.plex.tv`，每次翻页获取 100 条。每次请求都会重新读取 Plex token，所以重新认证无需重启适配器即可生效。
- 共享执行器会从 Newznab 和 Torznab 索引器获取电影，或者获取每个计划中的季。它会优先选择整季包。搜索剧集时，由于不同索引器的映射不一样，会先尝试 TVDB，再尝试 IMDb。
- 进度、重试截止时间和每集的回执都会保存在 `data/acquisition.json` 中，重启后依然保留。之前的 Plex 账本会被自动导入。
- 只有所有计划目标都获取完成后，才会从列表中移除。请求失败的条目会留在观看列表里，并按持久化退避规则重试。仅重试移除操作时，不会再次获取。限制说明请参阅 [Plex 观看列表获取](plex-watchlist.md)，共享配置请参阅 [获取源](acquisition.md)。

## 仪表盘与 API 端点（`internal/handlers/router.go`、`internal/handlers/dashboard`） {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- Routes: `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`.
- Dashboard 显示 Plex 服务器信息和状态,数据来自 `PlexStatusFetcher`,它跑两个定时器:每 30 秒刷新一次串流会话、转码会话、带宽和服务器活动(`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`);每 5 分钟做一次完整抓取,这次还会重新读取服务器身份(`GetServerIdentityOnly`)、媒体库分区和每个分区的条目数。扫描活动会按文件名和种子列表做交叉比对,这样仪表盘就能把某个活动关联到对应的种子哈希。
- 分区/全部扫描接口会为一个或所有分区排队一次**完整**的分区刷新(`RefreshSection(key, nil)`,不带路径);它们不会处理 STRM 文件,也不会触发媒体库的其他副作用(`HandlePlexScan`/`HandlePlexScanAll`)。

## Plex Wrapped（`internal/handlers/dashboard/plex_wrapped.go`） {#plex-wrapped-internalhandlersdashboardplex_wrappedgo}
- `/plex-stats` 会渲染一个年度回顾，共 9 张幻灯片，数据来自过去 12 个月的 Plex 观看历史。`/plex-stats/data` 会以 JSON 形式返回同样的统计数据。`/plex-stats/image` 会通过无头 chromedp 渲染一张可分享的 PNG，尺寸可选 `square`（1080x1080，默认）、`instagram`（1080x1920）或 `facebook`（1200x630）。
- 统计数据每 24 小时最多获取一次，加上 `?refresh=true` 可以强制刷新。最多处理 10000 条历史记录。数据同时缓存在内存和磁盘上的 `data/plex_wrapped_cache.json` 中，启动时会重新加载。获取数据期间，页面会显示加载状态，不会卡住等待。

## 媒体库副作用与刷新链接 {#library-side-effects--refresh-links}
- 库的副作用会在目录分配变更、重命名、删除和文件修复时触发:`TriggerLibrarySideEffects` 会让受影响路径的 rclone VFS dircache 失效(这样媒体服务器就不会扫描到过期的列表),调用 `MediaScanner.TriggerScan`(触发 Plex 刷新),并运行用户的 `on_library_update` 钩子(`internal/torrent/hooks.go`)。
- 刷新流程只会在初始化完成后才运行 STRM 生成和副作用,以避免过早触发 Plex 扫描(`internal/torrent/refresh.go`)。

## 基础设施与脚本 {#infrastructure--scripts}
Nginx 示例虚拟主机，用于代理 Plex 流量（`nginx/plex.conf`）。

- `plex_update.sh` 是 `on_library_update: sh plex_update.sh "$@"` 对应的参考部分扫描脚本。把它放在 `docker-compose.yml` 旁边，因为该文件所在的文件夹挂载到了 `/config`，所以脚本已经在容器里了。
- 在 Windows 上，hook 是通过 PowerShell 运行的，而不是 `/bin/sh`（`pkg/script/script.go`），所以这个脚本在那里不会运行。[Usenet → 让 Plex 指向它](usenet.md#6-point-plex-at-it) 展示了 PowerShell 的写法。
- 运行 `make integration-test` 和 `make integration-test-media` 时会执行 `integration/plex_integration.sh`。如果主机上没有 Plex 服务器，它会明显地跳过，所以要看输出内容，而不是只看退出码。
- `scripts/plex-e2e-test.sh` 是一个独立的播放检查脚本，它会从 `config.yml` 中读取 `plex_server_url`/`plex_token`。

## 推荐的 Plex 设置 {#recommended-plex-settings}

zurg 在每次 Plex 状态刷新时都会检查并调整这些设置。`plex_settings_policy` 决定它做到什么程度：`off`、`warn`、`guard`（默认）或 `enforce`。设置列表在 `pkg/plex/settings.go`（`RecommendedSettings`）里，策略逻辑在 `pkg/plex/reconcile.go` 里。

如果 Plex 服务器没有报告某个设置，就会跳过它，所以缺少该设置的 Plex 版本不会被误报为配置有问题。

下面 16 个值里有 九 个与 Plex 自带的默认值不同，属于纠正项。其余 七 个与默认值一致，它们是守护项，只有在运维人员手动开启了对应功能时才会触发。这些行在两列里显示相同的值，这并不是错误：Plex 出厂时 `GenerateBIFBehavior` 是 `never`，而用于测量的服务器当时设为 `scheduled`。Plex 会在 `/:/prefs` 里报告每个设置的默认值，所以下表中的「Plex 出厂值」一列是从服务器读取的，而不是假设的（于 2026-09-05 在 Plex 1.42.2 上测得）。

### 关闭某个设置 {#opting-out-of-one-setting}

`plex_settings_policy` 是分级的，但所问的问题并不总是对应这个级别。如果你的文件会在媒体库文件夹之间移动（比如按标签整理），就需要 Plex 自己清空回收站，来清除遗留的条目；而 `guard` 会把这一功能关掉。改用 `warn` 来恢复这一功能，又会放弃文件系统事件的保护，而它们属于同一级别，并不是你想要的。

`plex_settings_ignore` 逐个列出要忽略的设置：

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

仪表板会替你写入这一项。配置页面在 Library Trash Sweep 设置上方有一个 **Let Plex Empty Its Own Trash** 开关。它会在这里添加和删除 `autoEmptyTrash`，并保持列表中的其他项不变。开启后要重启才会生效。

被忽略的设置仍会被读取，并仍显示在仪表板和 `zurg plex-settings` 中（标记为 `skip`），所以什么都不会被隐藏。它只是从不写入、不计为问题，也不会触发仪表板的回收站横幅。ID 不区分大小写。如果某个 ID 没有对应下表中的任何设置，启动时会报告出来，并且该设置仍保持受保护，因为拼写错误不能被当成选择退出。

忽略安全相关的设置风险自负，zurg 会在启动时提示一次，而不是每次刷新都提示。尤其是 `autoEmptyTrash`，它会在扫描遇到一次短暂中断的挂载点时清空媒体库。忽略它也意味着把清理工作交还给 Plex，详见下文。

### 谁来清空回收站 {#who-empties-the-trash}

关闭 `autoEmptyTrash` 会留下一件事没做完。Plex 被告知不要清除文件已不存在的条目，而 zurg 自己的删除以前一直是可选的，所以开箱即用时，资料库会积累失效条目，却没有任何东西去清理。两边都没错，这个缺口是真实存在的：当文件在资料库文件夹之间移动、旧条目却永远留着时，就会遇到这个问题。

zurg 现在接过了它之前交出去的这项工作。未设置 `plex_trash_sweep_every_mins` 时，[回收站清扫](../internals/plex-trash-sweep.md)每 60 分钟删除一次条目，但只有在没有其他东西在做这件事时才会运行。如果 Plex 仍在自行清空回收站（比如 `plex_settings_policy` 为 `off` 或 `warn`，或者 `autoEmptyTrash` 位于 `plex_settings_ignore` 中），zurg 就会退让，把工作留给 Plex。同一个资料库有两个清理者，两者之间的分歧就会变成删除。

清扫的范围比 Plex 自己的清空窄得多，这正是优先使用它的原因：它每次只删除一个条目，从不删除仍有文件的条目，只在挂载点当下可读时才删除，每轮最多删除 50 个条目，且不超过回收站的 10%；对于无法判定的条目，会先在 14 天内以损坏状态保持可见。它还需要设置 `plex_database_path`，因此只在 Plex 运行于本机时才会工作，并且要求 zurg 自己运行挂载（`rclone_enabled` 且设置了 `mount_path`）。zurg 使用 Plex 安装时附带的 `Plex SQLite` 程序读取该数据库，并会在 Linux、macOS 和 Windows 上 Plex 安装程序放置它的位置找到它，因此只需设置 `plex_database_path` 这一个键：

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
请保留单引号：在双引号中，YAML 会把反斜杠当作转义符。只有在 Plex 安装在其他位置时（例如 32 位 Plex）才设置 `plex_sqlite_binary`，例如：`'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`。
+++

将 `YOU` 替换为你的用户名：zurg 不会展开 `~` 或 `%LOCALAPPDATA%`。清扫会把 Plex 存储的路径与 `mount_path` 进行匹配，能处理盘符，例如 `Z:`（`pkg/utils/path_within.go`）。

如果想关闭删除、自己清空回收站，就写 `plex_trash_sweep_every_mins: 0`。这是明确的拒绝，与不写这个键是两回事。

这个键只会关闭 zurg 自己的删除，并不会把 Plex 的设置还回去。在 `guard` 模式下，zurg 仍会把 `autoEmptyTrash` 写成关闭，因此 Plex 扫描后仍不会清空回收站，条目会越积越多，却没有任何东西来清理。要把这项工作交还给 Plex，请使用仪表板开关，或设置 `plex_settings_ignore`。

### 安全 —— 在 `guard` 和 `enforce` 下修正 {#safety--corrected-under-guard-and-enforce}

这些设置丢的是数据，而不是时间，所以默认策略会直接写入它们，而不只是发出警告。只有 `autoEmptyTrash` 出厂时是有破坏性的值。其余三项出厂默认值已经符合 zurg 的要求，保留在这里，是为了发现有人误开了其中某一项的运维人员。

| 偏好设置 | Plex 默认值 | zurg 需要的值 | 原因 |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | Plex 每次扫描后都会清空回收站。如果挂载点在扫描遍历时短暂无法读取，每个文件都会被判定为已删除，Plex 就会永久删除它们，而不是把它们留在回收站里，等挂载恢复后再回来。 |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | 基于事件的更新漏掉了这里真正发生变化的内容。zurg 的目录树在它自己那一侧变化，这些变化不会经过本地内核，因此不会触发任何事件，媒体库就会悄悄过时。真正到达的事件，是*通过*挂载点进行的写入，而这些写入发生在目录还在组装的时候。 |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | 部分扫描依赖的也是同样的事件，所以它会在经由挂载点的写入时触发，也就是目录刚写到一半的时候，而从不会在远端变化时触发，而远端变化才是真正需要扫描的情况。 |
| `ButlerTaskBackupDatabase` | `1` | `1` | 每晚的数据库备份，是唯一能恢复 Plex 已经删除的媒体库的手段。 |

这两条 `FSEvent` 的原因，是在每个 zurg 支持的平台上实测之后改写的。之前的说法是，FUSE 挂载“不能可靠地发出这些事件，所以会在没人要求扫描的时候触发扫描”。这两点都说错了。

实测于 2026-09-05，每个平台都用其媒体服务器实际使用的 API 进行监听，测试对象是一个 rclone 挂载，其底层目录可以直接修改。**A** 是通过挂载点进行的写入；**B** 是同一个文件出现在远端，就像 zurg 自己的目录树发生变化时那样。

| 平台 | 挂载方式 | 监听方式 | A：通过挂载点写入 | B：远端发生变化 |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **无事件** |
| Docker | 同一挂载以 bind mount 方式挂入容器 | 容器内的 inotify | 同样四个事件，在容器内可见 | **无事件** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **无事件** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **无事件** |

每个平台都能收到 A 类事件，同一轮测试中，在原生文件系统（APFS、NTFS）上的对照组也产生了相同的事件，说明监听器本身工作正常。但没有一个平台收到 B 类事件，尽管目录缓存过期后，这个文件其实已经能通过挂载点看到了。

所以失效模式和之前的说法正好相反：基于事件的更新会在经由挂载点的写入时触发，比如 *arr 的导入落在一个还在组装中的目录里；而对于真正需要扫描的远端变化，它从不触发。问题不在于事件不可靠，而在于它们报告的是 debrid 挂载上所发生的事情中错误的那一半。

### 带宽 —— 仅在 `enforce` 下修正 {#bandwidth--corrected-under-enforce-only}

这些设置会让 Plex 为一个没人会去看的结果，把整个文件都解码一遍。在本地存储上没什么影响；但在 debrid 挂载上，每个字节都是一次提供商请求，而且这些操作会作用于整个库。那些输出是*可见的*分析，比如拖动进度条时的预览、章节缩略图、音量均衡和声音分析，则放到下面的 taste 层里，`enforce` 不会动它们。

| 设置项 | Plex 默认值 | zurg 的设定 |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### 口味 —— 始终报告，从不修正 {#taste--always-reported-never-corrected}

这些选项背后都有对应的功能，所以 zurg 只会说明每个值的代价，选择权留给你。未经同意就关掉其中任何一个，都会去掉运维人员看得到的功能，这不是 zurg 能替你做的决定，哪怕能省下再多带宽也一样。前两个选项，更省资源的选择能保留功能，只是把工作挪到维护时段；其余的则只能二选一：要功能，还是要带宽。

| Preference | Plex 默认值 | zurg 建议 | 原因 |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` 或 `never` | `asap` 会在每个文件入库的那一刻就解码，不管维护时段是否开启。`scheduled` 会保留 Skip Intro 按钮，并把这部分工作挪到维护时段里。 |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` 或 `never` | 同样的道理，只是对象是 Skip Credits。 |
| `GenerateBIFBehavior` | `never` | `never` | 会把整个视频解码，用来生成拖动进度条时显示的预览缩略图条。播放本身用不到它。 |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | 解码文件，为每个章节截取一帧画面，用于章节列表中每一项旁边的图片。 |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | 完整解码每个文件的音频来测量响度，用于在不同曲目和标题之间统一音量。 |
| `MusicAnalysisBehavior` | `scheduled` | `never` | 解码每一首曲目。文件数量多、都很小，所以请求数会很快触发账号的速率限制。换来的是音频分析功能：相似曲目混播和可视化效果。 |

### 维护时间窗口 {#the-maintenance-window}

zurg 不会改动 `ButlerStartHour`/`ButlerEndHour`,因为没有哪个时段对所有人都合适。值得手动设置一下:Plex 默认是 02:00–05:00,如果这个时段和大家观看的时间重叠,每次维护任务都会卡住。带宽层级里保留下来的内容都会在这个时段内运行。

### 停止正在进行的任务 {#stopping-a-pass-already-in-flight}

更改偏好设置只会影响*之后*的运行，不会停止正在进行的运行。Plex Media Server 会重新启动它的扫描器子进程，所以杀掉这些进程没有用：

+++ Linux 和 macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
在 Windows PowerShell 5.1 中，`curl` 是 `Invoke-WebRequest` 的别名，所以要输入 `curl.exe`。
+++

先把 `$TOKEN` 设置为你的 Plex token：在 shell 中用 `TOKEN=your-token`，在 PowerShell 中用 `$TOKEN = 'your-token'`。
