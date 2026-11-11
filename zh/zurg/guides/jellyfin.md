# Jellyfin 功能与能力 {#jellyfin-features--capabilities}

## 配置与存储 {#configuration--storage}
- 配置项（见 [`config.md`](../reference/config.md)、`config.example.yml`）：`jellyfin_server_url`（字符串，默认值 `""`）和 `jellyfin_token`（字符串，默认值 `""`）。这两项在 `config.example.yml` 里默认是注释掉的，`config.simple.yml` 里则完全没有。必须设置 `mount_path`，否则媒体扫描（包括 Jellyfin）会被禁用（`pkg/scan/scanner.go`）。
- 这些值通过仪表盘保存在 `config.yml` 里（`updateConfigFileAtomic`）。没有单独的 Jellyfin 数据文件。这些字段以及它们的 `Get`/`Set` 辅助函数定义在 `internal/config/config.go` 的 `zurgConfig` 上；`ZurgConfigV1`（`internal/config/filters.go`）内联嵌入了这个结构体。

## 身份验证与服务器校验（QuickConnect） {#authentication--server-validation-quickconnect}
- 仪表板快速连接流程:
  - `/jellyfin/check-server` 通过 `System/Info/Public` 检查服务器是否可达,并返回版本、名称以及快速连接是否可用(`HandleJellyfinCheckServer`,`pkg/jellyfin/auth.go:CheckServerReachable/CheckQuickConnectEnabled`)。
  - `/jellyfin/auth` 发起快速连接(`InitiateQuickConnect`),创建一个与 cookie 绑定的认证会话(`pkg/jellyfin/auth_session.go`),并启动后台轮询。
  - `/jellyfin/auth/status` 在轮询 `/QuickConnect/Connect` 和 `/Users/AuthenticateWithQuickConnect` 的同时,返回完成或错误状态(`PollForQuickConnectAuth`,每 5 秒尝试一次,共 60 次,超时后结束)。
  - `/jellyfin/server` 将服务器 URL 和令牌保存到配置中,重新初始化 Jellyfin 客户端,如果重新初始化失败,则返回成功或警告信息(`HandleJellyfinServerSelect`)。
  - `/jellyfin/logout` 清除配置,在不使用 Jellyfin 的情况下重新初始化扫描器,并丢弃缓存的仪表板状态(`JellyfinStatusFetcher.ClearCache`)。
- 认证会话管理器负责跟踪快速连接会话,存储 secret、code、令牌和用户信息,10 分钟后清理(每 5 分钟扫描一次),并提供线程安全的 getter(`pkg/jellyfin/auth_session.go`;全局实例位于 `auth_global.go`)。
- `pkg/jellyfin/auth.go` 中的快速连接辅助函数会发送标准的 `Authorization: MediaBrowser …` 请求头,并关闭 TLS 验证以兼容自签名证书(`newHTTPClient`)。扫描客户端则不这样做:`mediabrowser.NewCore` 构建的是一个普通的、超时时间为 30 秒的 `http.Client`(`pkg/mediabrowser/core.go`)。因此,位于自签名证书后面的服务器可以正常配对和验证,但其分区和刷新调用会因 TLS 失败。
- 保存前,使用令牌验证端点 `/System/Info` 来确认凭据(`ValidateToken`)。

## Jellyfin 客户端能力（`pkg/jellyfin/client.go`） {#jellyfin-client-capabilities-pkgjellyfinclientgo}
- `Client` 是内嵌的 `mediabrowser.Core`（`pkg/mediabrowser/core.go`）之上的一层薄封装，与 `pkg/emby` 共享，因为两个服务器都源自同一套代码。它自己唯一的方法是 `GetSections`；扫描（`ProcessJob`）、活动、服务器状态、生命周期、队列、认证头和卡住检测都来自 core。
- 认证：Jellyfin 的请求会发送标准的 `Authorization: MediaBrowser … Token="<token>"` 头；Emby 的客户端则改用 `X-Emby-Token`。
- 生命周期：`NewClientWithLogger` 会创建 core（去掉末尾的斜杠；如果 URL *或* token 为空，则输出警告并返回 nil）。接着，除非设置了 `GO_TEST_MODE=1`，否则 `StartWorker` 会启动动态扫描 worker；`Close` 会同时关闭 worker 和队列。
- 扫描队列：动态任务队列 + `common.DefaultWorkerConfig`；`GetJobQueueSize` 是仪表盘读取的数据（通过 `MediaScanner.GetQueueSizes`）。`GetJobQueue` 是一个兼容性占位函数，它返回一个切片，里面是与队列长度相同、但内容为空的任务。
- 负载与卡住检测：`CheckServerLoad` 轮询 `/ScheduledTasks`，监视名称中包含 "scan" 的正在运行任务，按任务统计卡住次数；扫描进行中时报告为忙碌。`IsJobStuck` 会标记超过卡住阈值的任务。
- 活动跟踪：`GetRunningTasks` 返回详细的 `TaskActivity` 结构体，包含 ID、Name、State、Progress（来自 `CurrentProgressPercentage`）、Description 以及卡住状态，供仪表盘显示。
- 服务器状态：`GetServerStatus` 轮询 `/Sessions`，统计活跃的流媒体会话数、转码数（视频/音频非直通）以及带宽使用情况，供仪表盘显示。
- 媒体库发现：`GetSections` 调用 `/Library/VirtualFolders`，返回包含 ID/Title/Paths（媒体库的每个文件夹）/Type 的分区，并通过 `Items?ParentId=<id>&Recursive=true&Limit=0` 为每个分区补充项目数量。
- 刷新：`ProcessJob` 会在一次 `POST /Library/Media/Updated` 请求中上报任务中所有发生变化的路径，请求体中每个路径都与服务器文件系统上的路径完全一致。没有路径的任务会通过 `POST /Items/{id}/Refresh` 刷新整个媒体库。遇到 503 时返回 `ServerBusyError`；遇到 404 时返回 "library may have been deleted" 错误；其他 4xx/5xx 则返回响应体。`RefreshSection` 负责将任务加入队列。
- 辅助函数：`FindSectionNormalized` 按路径前缀匹配（先匹配到者优先），并返回将前缀改写为媒体库位置大小写形式的路径。前缀比较在 macOS 和 Windows 上不区分大小写，其他系统上则为精确匹配（`pkg/common/pathutil.go`）。

## 媒体扫描器集成（`pkg/scan/scanner.go`） {#media-scanner-integration-pkgscanscannergo}
- 当 `mount_path`、服务器 URL 和 token 都存在时，初始化 Jellyfin 客户端；成功时记录日志，失败时客户端保持为 nil。没有重试循环（与 Plex 不同），但支持手动重新初始化。
- `TriggerScan` 会和其他服务器一起把任务分派给 Jellyfin；`triggerJellyfinScan` 通过 `FindSectionNormalized` 解析媒体库（使用带 `mount_path` 前缀的路径），并把每个媒体库的变更路径合并到一次请求中发送（Plex 则是每个请求只发一个路径）。
- `GetQueueSizes` 会一起返回 Plex、Jellyfin、Emby 的队列长度；如果某个服务器未连接，则返回 -1。
- `ReinitializeJellyfinClient` 会先关闭已有的客户端，再用当前配置重新创建（在仪表板认证之后和退出登录时使用）。

## 仪表盘与路由 {#dashboard--routes}
- 路由器挂载了 Jellyfin 端点：`/jellyfin/check-server`、`/jellyfin/auth`、`/jellyfin/auth/status`、`/jellyfin/server`、`/jellyfin/logout`、`/jellyfin/scan/{sectionID}`、`/jellyfin/scan-all`（`internal/handlers/router.go`）。
- 仪表板弹窗（templates/scripts）负责驱动 QuickConnect、显示状态和错误，并保存或移除凭据；队列大小、带扫描按钮的媒体库卡片和服务器活动都显示在 `dashboard.tmpl` 中。
- `JellyfinStatusFetcher`（`internal/handlers/dashboard/mediabrowser_status.go`）从后台缓存中填充仪表板 JSON，而不会阻塞页面：它会验证令牌、标记连接状态、填充媒体库列表（ID/Name/Paths/Type/ItemCount），并收集正在运行的任务活动，以及会话、转码和带宽数量。活动和会话每 30 秒刷新一次；完整抓取（包括媒体库）每 5 分钟刷新一次。`response.go` 提供缓存副本（`JellyfinServerInfo`、`jellyfin_queue_size`）。
- 媒体库扫描端点（`HandleJellyfinScan`、`HandleJellyfinScanAll`）会像 Plex 的对应功能一样，为单个或所有媒体库分区排队一次整库刷新，不需要指定路径；如果没有配置 Jellyfin 客户端，则返回 503（`internal/handlers/dashboard/dashboard.go`）。
- `jellyfin_server_url` 和 `jellyfin_token` 也可以通过通用配置更新处理程序写入，因此无需使用 QuickConnect 弹窗即可设置（`dashboard.go` 中的 `handlers["jellyfin_server_url"]`/`["jellyfin_token"]`；`scripts.tmpl` 中的 `updateJellyfinServerURL`）。

## 媒体库副作用与刷新 {#library-side-effects--refresh}
- 任何库的副作用（目录分配变更、STRM 同步、修复）都会调用 `MediaScanner.TriggerScan`。当客户端已连接时，这也包括 Jellyfin 刷新（`internal/torrent/hooks.go:TriggerLibrarySideEffects` → `pkg/scan/scanner.go`）。
- 同一个调用会先清除受影响的 rclone VFS dircache 条目，这样 Jellyfin 的扫描就能看到变更，而不是读取缓存了数小时的目录列表。
- STRM 同步和 `on_library_update` 钩子与扫描触发同时运行（钩子做了 500ms 防抖并去重）。Jellyfin 在刷新任务中接收的是带 mount_path 前缀的库路径。

## 其他 {#miscellaneous}
Emby 是与 Jellyfin 并列的集成，有自己的配置键（`emby_server_url`、`emby_token`），同时共用同一套核心代码，但没有 QuickConnect。你可以用 API 密钥登录，也可以选择用户并输入密码（`/emby/users`、`/emby/auth`）。
- 它的仪表盘卡片会列出媒体库，并带有扫描按钮（`/emby/scan/{sectionID}`、`/emby/scan-all`）。活动和会话的显示方式和 Jellyfin 一样（`EmbyStatusFetcher`）。
- `pkg/jellyfin/windows_path_test.go` 用来检查：Windows 路径不会出现在请求 URL 中，并且会原样传到请求体里。`find_section_test.go` 负责测试前缀匹配。
