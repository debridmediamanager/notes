# zurg 配置文档 {#zurg-configuration-documentation}

此文档详细介绍了 zurg 所有可用的配置选项。请在 `config.yml` 文件中设置这些选项。

> **提示：** 大多数设置都可以通过 `http://localhost:9999/config/` 的 **Dashboard** 进行配置。网页界面让你无需直接编辑配置文件，就能更方便地查看和修改设置。

## 从旧的 `providers` 配置迁移 {#migrating-from-a-pre-providers-config}

如果你的配置文件是在支持多账号之前写的，它仍然可以启动。顶层的 `token:`、`download_tokens:` 和 `strm_link_token:` 会被当作它们唯一能表示的东西来读取，也就是一个 Real-Debrid 账号。启动时会警告这些键已被弃用。你只需要把它们移到某个 `providers` 条目下面，什么时候改都行。这是配置文件唯一需要的改动，其他键没有被重命名、改类型或删除。

不过，这并不是唯一的变化。有一些指令名称和值都没变，但决定的事情已经有点不同了，因为读取它们的代码改了位置。这些内容都收集在下面的 [升级后还有哪些变化](#what-else-changes-when-you-upgrade) 中。如果你会按压缩包、标签或发布时间进行过滤，值得读一读。

### 需要做的唯一改动 {#the-one-change-to-make}

以前，一个 Real-Debrid 账号要用三个顶层键来配置。现在这三个键都放进了同一个 `providers` 条目里。

修改前：

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

修改后：

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

把键移过去之后，记得删掉旧的键。如果它们和已经配置了 Real-Debrid 的 `providers` 块放在一起，会被忽略，启动时还会发出警告，这样两者就不会悄悄地对哪个 token 生效产生分歧。文件里的其他内容都不用改，其他键的名字和含义都没变；如果你的配置里唯一的凭据是 `token:`，那只需要做这一处修改。

这一步不是必须的。没有迁移的配置仍然能启动：这三个键会被当作一个名为 `realdebrid` 的 Real-Debrid 账号来读取，启动时会列出它读取了哪些键，以及应该改写成什么。这些键已被弃用，但不再受支持，新的账号功能只能通过 `providers` 条目来使用。

`TOKEN` / `RD_TOKEN` 环境变量仍然可用，首次运行时仍会自动创建配置文件。

### 现在可以做到的新功能 {#what-became-possible-that-you-may-want}

以下内容都不是必需的。这些是 `providers` 配置块带来的功能：

| 现已支持 | 位置 |
|---|---|
| TorBox、AllDebrid 和 Usenet 后端，可与 Real-Debrid 并用，也可替代它 | [账户](#accounts) |
| 同一服务可配置多个账户，通过 `name` 区分 | [账户](#accounts) |
| 使用 `disabled: true` 可暂停某个账户，且不会删除其凭据 | [账户](#accounts) |
| 使用 `watchlist: true` 选择新的种子添加请求优先尝试哪个账户 | [账户](#accounts) |
| `provider:` / `not_provider:` 目录过滤器，以及每个账户的目录 | [目录](#7-directories--filters) |
| 使用 `rd_cdn_host_preference` 和 `tb_cdn_host_preference` 为每个服务选择 CDN | [CDN 与主机选择](#cdn--host-selection) |

还有两个小改动值得了解：

- `cdn_host_preference` 仍然可用，并且仍然指 Real-Debrid。它现在是 `rd_cdn_host_preference` 的别名，两者都设置时以后者为准。
- Dashboard 认证流程获得的 Plex 凭据现在会写回 `config.yml`，保存为 `plex_server_url` 和 `plex_token`。以前它们保存在 `data/plex.json` 中。

### 手动迁移还是用面板迁移 {#migrating-by-hand-vs-by-dashboard}

Dashboard 可以帮你完成这一步。未迁移的配置能正常加载，所以可以打开 providers 编辑器，它会列出你顶层键所对应的 Real-Debrid 账号。保存任意一个账号后，这些键就会被移到磁盘上的 `providers` 块中。

手动编辑文件并重启也能达到同样的效果。如果配置根本无法加载，这是唯一的办法。

Dashboard 现在不再接受一项内容：`POST /config` 以前可以接收顶层的 `token`、`download_tokens` 和 `strm_link_token`，现在会返回 `400 Unknown config option`。现在改为按账号分别编辑凭据。凡是用脚本操作这三个字段的，都需要更新。

### 升级时还有哪些变化 {#what-else-changes-when-you-upgrade}

**过滤器现在能看到压缩包内部。** `any_file_inside_regex`、`any_file_inside_contains`、`any_file_inside_size_gte`/`_lte`、它们的 `not_` 形式，以及 `has_episodes` 和 `is_music`，以前是拿压缩包本身来判断的：一条记录叫 `Show.part01.rar`，大小就是分卷的大小。现在 zurg 列出压缩包之后，这些过滤器改为判断压缩包里的内容，包括真实的文件名、真实的文件大小，并且刻意*不再*使用压缩包自身的大小，因为它会把里面的文件都压得没了存在感。以前显示为一个超大文件的整季合集，现在能匹配 `has_episodes` 了；`any_file_inside_regex: /\.mkv$/i` 以前匹配不上，现在能匹配了；而 `any_file_inside_not_regex` 以前能通过的，现在可能不再通过。另外，如果一个发布版本的所有文件都是 `.rar`/`.r00`/`.par2`，它现在会进入过滤器，而以前会直接被归入 `__unplayable__`。

这个变化是逐个发布版本生效的，而不是一次性全部生效：它只作用于 zurg 已经列出过的压缩包，并且由旧版解析器写入的列表会被丢弃，所以一个发布版本会在第一次被打开时才发生变化。如果你的某个目录依赖旧的判断方式，可以改用 `regex`/`not_regex` 针对压缩包名称来写，它们仍然匹配发布版本的名称。

**标签过滤器不再误抓从未探测过的发布版本。** `zurg_*` 标签来自 ffprobe。如果一个发布版本根本无法探测，所有等级表都会落到最低档，而该版本仍会被打上 `zurg_sdr`、`zurg_very_low_video_bitrate`、`zurg_very_low_audio_bitrate` 和 `zurg_0to20mins_duration` 这几个标签，等于在描述一个没人测量过的文件。现在不再输出这四个标签。如果你的过滤器用到了其中某个标签，那么对于无法探测的发布版本，含义会变：`has_tag`、`tags_match_all` 和 `tags_match_any` 不再能抓到它们；而值得留意的是另一个方向：`not_has_tag`、`tags_missing_all` 和 `tags_missing_any` **会开始**抓到它们。使用其他等级标签的过滤器不受影响。

**`added_within_hours` / `added_within_days` / `added_after` / `added_before` 对重复项读取的是更早的时间戳。** 当同一个发布版本出现多次时，现在条目报告的是最早的添加时间，而不再是第一次见到的时间。这样一来，一个旧发布版本的第二份副本就不会再显得像是刚添加的了。因此，一个 `recent` 风格的目录可能会丢掉之前保留的某个发布版本。

**挂载点现在会把目录列表缓存 12 小时。** 以前 `check_for_changes_every_secs` 会设置 rclone 的 `--dir-cache-time`，所以默认情况下列表每 15 秒就过期一次。现在列表会保留 12 小时，并且每当库发生变化时，zurg 会明确地让受影响的条目失效，这样媒体服务器的扫描就能保持缓存命中。如果要恢复原来的行为，可以直接覆盖它：`rclone_extra_args` 的优先级高于任何内置参数：

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**每个账户都会有一个 `__<account>__` 目录。** 它由 `providers` 配置块创建，而不是由 `directories` 创建，包含该账户持有的全部内容，忽略你的目录过滤器，并且把读取固定到该账户上。`directories` 无法关掉它。当配置了多个账户时，它会出现在挂载点根目录下。在 nightly 2026.10.24.0551 之前的版本中，单个账户的文件夹也会列在那里；从这个 nightly 开始，它不再出现在挂载点的根目录列表中，因为 `__all__` 包含的是同一个库。直接的 HTTP 和 WebDAV 路径（例如 `/http/__realdebrid__/`）仍然可以访问。通过挂载点访问时，它也不能再解析了；如果有任何媒体库或脚本使用了 `__<name>__`，请改为指向 `__all__`。

**两个同名的发布版本现在是两个条目。** 以前它们会被合并成一个，一个发布版本的文件会悄悄被并入另一个的内容中。不保留原始名称的那个会加上其 info hash 的六个字符作为后缀，例如 `Movie.2024 {a1b2c3}`。`regex`、`not_regex`、`contains` 和 `not_contains` 匹配的就是这个带后缀的字符串，所以使用了锚定的模式会匹配不到它。另外，因重复基础文件名而被区分开的条目，会在升级时一次性重命名：从账户生成的文件 ID 改为基于路径派生的标签。

**`.strm` 文件的格式变了。** 启用 `serve_strm_files` 后，挂载点提供的每个 `.strm` 文件，其内容和报告的大小都会改变：URL 现在指向的是库中的条目，而不再是某个账户的链接，因此它能自动切换故障源，并且在修复之后依然有效。媒体服务器会看到每个 `.strm` 都发生了变化。启用 `save_strm_files` 后，已经写好的文件会在 zurg 首次启动时以相同的文件名原地重写，媒体服务器会在下一次扫描时获取新的 URL。新格式使用存放在 `data/strm_secret` 的密钥进行签名；如果无法写入该文件，zurg 会记录一条警告并照常启动，但在下次重启后这些链接将无法解析，这一点值得重视，别忽略。

**`load_dumped_torrents` 不会加载升级前的 `dump/`。** 缓存的种子现在会带上它们来自哪个账户的标记，没有这个标记的会被跳过。主缓存会在下一次刷新时从账户重新导入；而 `dump/` 背后没有账户，所以它会是空的，并在日志中给出警告。如果你需要这些数据，请从正在运行的实例上重新导出。

**当 `restrict_repair_to_cached` 和 `only_full_torrent_repair` 都为 false 时，修复的路径不同了。** 两个配置项设为 `true` 时的行为没有变化。两者都关闭时（即默认情况），原来的逐文件和批量策略被替换为一次重新添加，并指明损坏的文件。意图相同，但发给账户的请求不同了。

**其他小变化。** `ignore_renames` 现在也决定磁盘上 `.zurgtorrent` 文件的名称（加载时会自动迁移）。`retries_until_failed` 现在限制 Real-Debrid 公平使用策略的重试次数，以前是无限重试。`auto_analyze_new_torrents: false` 和缺少 `ffprobe_binary` 不再会阻止缓存清理，以前清理会和分析一起被跳过。如果某个大小过滤器排除了压缩包的第一个分卷，现在会整个隐藏该压缩包，而不再回退到后面的分卷。未认证的静态资源范围从 `/static/css/*` 扩大到了 `/static/*`；但没有任何原本受保护的路由因此变成公开的。

## Windows 配置 {#windows-configuration}

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Windows 下的关键要点：**
- 所有路径都要用引号括起来
- 对于 `mount_path`：使用盘符，例如 `P:\`（在 YAML 中写成 `P:\\`）或 `P:/`
- 对于二进制文件路径：正斜杠 `/` 可用，还能避免转义问题
- 可执行文件记得带上 `.exe` 扩展名

## 1. 基础设置（先做这一步） {#1-essentials-setup-first}

这些是让服务器跑起来的必不可少的设置。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `zurg` | string | *(必填)* | 配置版本标识符。必须设置为 `v1`；其他任何值（包括缺少该键）都会导致加载失败。 |
| `providers` | list | *(必填)* | 你的 debrid 和 Usenet 账户，每个账户一条。见下方 [账户](#accounts)。providers 之前的顶层 `token`、`download_tokens` 和 `strm_link_token` 键已弃用：它们仍然可以加载，会作为单个 Real-Debrid 账户使用，启动时会发出警告。如果 `providers` 块已经配置了 Real-Debrid，则以它为准，多余的键会被忽略。 |
| `mount_path` | string | 因操作系统而异 | 你的 rclone 挂载所在的文件系统路径。zurg 用它告诉媒体服务器（Plex、Jellyfin、Emby）去哪里找文件。当 `rclone_enabled` 为 true 时，它也会用作挂载点。默认值为 `/mnt/zurg`（Linux）、`/Volumes/Zurg`（macOS）或 `Z:`（Windows）。Docker 用户应将其设置为 `/zurg_mnt/zurg`，并配合 `/zurg_mnt:/zurg_mnt:rshared` 卷挂载（见 [docker.md](../setup/docker.md)）。 |
| `base_url` | string | `""` | zurg 实例的外部可访问 URL。会嵌入到 STRM 文件中，以便媒体服务器能够串流内容。如果未设置，STRM 文件将包含 `localhost` URL，其他设备无法访问。可以使用你的 Tailscale IP、局域网 IP 或反向代理后的域名。示例：`http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### 账户 {#accounts}

第一段:

每个 `providers` 中的条目都是一个账户。可以同时运行任意数量的账户,比如 Real-Debrid、TorBox、AllDebrid、Premiumize、Debrid-Link 和 Offcloud 一起用,或者同一服务下有多个账户。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `type` | 字符串 | *(必填)* | 该账户使用哪个后端:`realdebrid`、`torbox`、`alldebrid`、`premiumize`、`debridlink`、`offcloud`、`nzb` 或 `torbox_nzb`([TorBox 托管的 Usenet](../providers/torbox-nzb.md))。 |
| `name` | 字符串 | `type` 的值 | 用来区分同类型的不同账户。它是 `provider` 过滤器、[按账户目录](#per-account-directories)、缓存路径和仪表盘使用的名称。各条目的名称必须唯一,而且 `e` 为 STRM 链接路由保留。 |
| `token` | 字符串 | *(必填)* | 账户的 API token 或 key。Real-Debrid 的 token 从 http://real-debrid.com/?id=20475782 获取,TorBox 的从 https://torbox.app/settings 获取,AllDebrid 的从 https://alldebrid.com/apikeys?uid=1kk5i 获取。`nzb` 不使用它,而是通过 `nntp` 进行认证。首次运行时,也可以通过 `TOKEN` 或 `RD_TOKEN` 环境变量提供 Real-Debrid 的 token,以自动创建配置。 |
| `download_tokens` | 列表 | `[]` | **Real-Debrid 和 AllDebrid:** 同一服务的备用 API token,在当前 token 的带宽额度用完时使用。它们使用该条目的目录(包括[本地目录](#local-debrid-catalogs)),但不会导入额外账户的种子库。**TorBox:** 可以设置,但轮换时不会重新映射账户专属的种子/文件 ID;不同账户请使用单独的 provider 条目。`nzb` 不使用此项。Premiumize、Debrid-Link 和 Offcloud 需要单独的账户条目,因为它们保存的文件 ID 只属于列出它们的那个账户。 |
| `strm_link_token` | 字符串 | `""` | 一个单独的 API token,用来解析到达 `/strm/` 端点的读取请求,这样播放器打开 `.strm` 文件时就不会占用实时挂载所用的 token。未设置时回退到 `token`。**Real-Debrid 和 AllDebrid**——这两个后端会轮换凭据,所以只有它们才需要为 `.strm` 流量单独指定一个 key。在 `torbox` 和 `nzb` 条目上可以设置,但不会使用。Premiumize、Debrid-Link 和 Offcloud 在这里只接受账户自己的 `token`。 |
| `disabled` | 布尔 | `false` | 让账户保留在配置中但不加载。如果所有条目都被禁用,加载会失败。 |
| `watchlist` | 布尔 | `false` | 将该账户标记为新种子添加时优先尝试的账户。这包括下载客户端端点以及 acquisition 的 Torznab 索引器。最多只能有一个条目设置它,并且 `nzb` 和 `torbox_nzb` 条目不能设置。如果都没设置,则使用第一个能添加种子的账户。acquisition 的 NZB 会交给 Usenet 后端,绝不会交给这个账户。参见[观察列表](#watchlist)。 |
| `add_torrents` | 布尔 | `true` | 该账户是否会接收新种子,包括下载客户端端点交给它的种子,以及 acquisition 从 Torznab 索引器获取的种子。如果是归档账户,或者配额已经被占用的账户,请设为 `false`:它仍会继续提供和读取其库内容,但不会再有新内容加入。**`providers:` 列表的顺序就是接收新添加的账户的尝试顺序**,所以这个键和该顺序要一起看;标记为 `watchlist: true` 的账户无论位于哪里都会最先尝试。不能与同一条目上的 `watchlist: true` 同时使用。在 `nzb` 条目上它会被忽略,并在启动时给出警告,因为新闻服务器永远不会收到种子。参见 [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see)。 |
| `warm_connections` | 整数 | `1` | 该账户对它**已经使用过的每个主机**保持多少个已拨号并完成握手的连接,这样读取时就不必再临时建立连接。上限为 4。`-1` 表示不保留任何连接。在 `nzb` 条目上会被忽略,其下限按账户设置,位于 [`nntp.warm_connections`](../guides/usenet.md)。参见[预热连接](#warm-connections)。 |
| `nntp` | 块 | *(`nzb` 必填)* | 新闻服务器凭据。`nzb` 类型必填,其他类型会忽略它。 |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

TorBox 的 `download_tokens` 设置不提供 RD 和 AD 锁定链接所支持的跨账户播放回退。它的解析器会更换 API key,同时保留现有源中的种子/文件 ID。使用单独的 TorBox provider 条目,可以让每个账户的 ID 和目录保持独立。对于本地库,请把可移植的 manifest 放到每个条目自己的源目录中。

#### TorBox 做种 {#torbox-seeding}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `tb_seed_torrents` | string | `never` | zurg 添加到 TorBox 账户的种子是否做种。`never` 会对每次添加都关闭做种。`auto` 将选择权交给你 TorBox 账户上的做种设置。`always` 会对每次添加都开启做种。它适用于配置中的每个 TorBox 账户，并在修改后立即对下一次添加生效。填写其他任何值都会导致 zurg 无法启动。 |

```yaml
tb_seed_torrents: never
```

除非你确实需要，否则保持 `never`。这个选项是为那些会统计分享率的私有 tracker 准备的。通过 [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see) 端点抓取的 `.torrent` 文件版本会按此设置添加，所以在 `always`（或者账户设置为做种时的 `auto`）下，TorBox 会把它重新上传回 tracker 的种子群。把它导入 Sonarr 或 Radarr 并不能阻止这一点：下载完成后客户端删除了文件，但它仍会留在账户里做种。

**做种中的种子会在做种期间一直占用你套餐的一个活动名额。** TorBox 把正在做种的种子和正在下载的种子同样计入。套餐允许同时 3、5 或 10 个（Essential、Standard、Pro），做种时间最长分别为 24 小时、14 天或 30 天。一旦所有名额都被做种种子占满，该账户上的新抓取和修复就会卡住，直到有名额空出来，也就是某个种子的做种时间到期，或你在 TorBox 上将其删除。做种还会计入 TorBox 的公平使用限制中的上传量。设为 `never` 则不会出现这些情况，这也是它作为默认值的原因。

`auto` 完全不向 TorBox 发送做种偏好，因此以你账户的做种设置为准。如果没人改过该设置，那就是 TorBox 自带的 Auto。`always` 和 `never` 只会覆盖 zurg 添加的种子所用的账户设置，账户上的其他内容保持不变。

#### Usenet 账户 {#usenet-accounts}

`nzb` 类型用的是 Usenet，而不是 debrid 服务：放进 `nzbs/` 目录里的 `.nzb` 文件会变成库里的种子，读取时，zurg 会从你的新闻服务器抓取文章并即时解码。同时只能启用一个 `nzb` 条目，因为两个条目会扫描同一个目录。额外的新闻服务器请放到该条目的 `nntp.servers` 下面，它们提供的是同一个库，而不是再复制一份。同一配置里如果还有 [`torbox_nzb`](../providers/torbox-nzb.md) 条目，`nzb` 条目同样会被拒绝，原因相同。请把这类条目放到单独的实例里运行，并使用它自己的工作目录。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `host` | string | *（必填）* | 新闻服务器的主机名，例如 `news.example.com`。 |
| `port` | int | 启用 TLS 时为 `563`，否则为 `119` | 新闻服务器端口。 |
| `tls` | bool | `false` | 使用 TLS 加密连接。 |
| `username` | string | `""` | 账户用户名。 |
| `password` | string | `""` | 账户密码。 |
| `connections` | int | `8` | 账户允许的并发连接数。zurg 会按这个数量读取：单个连接只能承载套餐吞吐量的一部分，所以流媒体播放需要占满这个配额，而不是一次只抓一篇文章。超出套餐允许的数量会导致连接被拒绝，因此请填写实际数值。 |
| `pipeline_depth` | int | `4` | 单个连接上 zurg 一次请求的文章数量。上限为 8。如果服务器无法同时处理多个命令，请设为 `1`。当批次连续中断时，zurg 会自动降为 1 并给出警告。 |
| `socket_receive_buffer_kb` | int | 未设置 | 把每个连接的内核接收缓冲区固定为这个 KiB 数。建议保持不设置。固定后的缓冲区内核就不再自动调节了。在 Linux 上，这会把接收窗口锁定在约 64 KiB，在有一定延迟的链路上会损失账户的大部分吞吐量。此选项只适用于从不自动调节或上限设置过低的内核。 |
| `cache_size_mb` | int | `512` | 内存中缓存的已解码文章数据总量。这是所有正在读取的文件共用的总量，而不是每个文件各自的上限。 |
| `servers` | list | `[]` | 备用的新闻服务器账户，按文章逐条回退。参见 [多个新闻服务器](#more-than-one-news-server)。 |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### 使用多个新闻服务器 {#more-than-one-news-server}

保留期是按提供商分开计算的。一个服务器已经过期的文章，通常在另一个服务器上还在。如果没有第二个账号，恢复失效文章的唯一办法是 PAR2，而这需要读取**整个发布**。所以第二个服务器的作用，就是区别在于只抓一篇文章，还是把所有内容重读一遍。

上面这些键对应的是第一个账号。`servers` 下面的任何内容都是额外的账号，只有前面的账号都没有这篇文章时才会去询问。原来的单服务器配置继续有效，不用改。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `name` | string | `host` 的值 | 在日志中标识该账号。 |
| `host`、`port`、`tls`、`username`、`password`、`connections`、`pipeline_depth`、`warm_connections`、`socket_receive_buffer_kb` | | | 同上。每个账号有自己的连接配额。流水线和接收缓冲区按账号单独设置，因为每个服务器能承受的程度不同。 |
| `priority` | int | `0` | 谁先被询问，数字小的先问。优先级相同的账号按书写顺序询问，但如果一个账号还有空闲连接，而另一个的配额已用完，则优先选有空闲连接的那个，所以两个等同的账号可以分摊负载。 |
| `backup` | bool | `false` | 标记为备用块账号，只有在所有主账号都回复*没有这篇文章*之后才会去询问。仅仅主账号**忙碌**并不算数：zurg 会等它，而不是把计费流量花在一个无限流量账号就能提供的内容上。 |
| `backbone` | string | `""` | 该账号解析到的文章存储池。两个账号在同一个 backbone 上，意味着它们持有相同的文章，所以一旦其中一个说没有某篇文章，另一个就会被跳过，不会再问同样的问题。 |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

判断一个发布是否需要修复的普查，会在认定某篇文章缺失之前询问每一个账号。这样，一个提供商有缺口的发布，只要另一个提供商还能提供，就不会触发 PAR2 重建。

顶层的一个键决定修复后会留下什么：

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `par2_patch_cache_mb` | int | `512` | PAR2 修复重建出的字节可以占用 `data/par2/` 的多少空间。这些字节是读取器无法再向新闻服务器重新索取的部分，因为携带它们的文章已经不在了。保留它们，意味着重启后不必为了恢复这几兆数据而重读整个发布。只有失效文章的片段会被保存，每个受损发布只有个位数兆字节；超出预算时，会按最近最少使用的顺序整体删除发布。设为负数会关闭持久化，修复结果只保存在内存中，直到进程结束。 |

还有两个选项决定解析后的 NZB 在内存中的占用：

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `nzb_segments` | string | Linux/macOS/BSD 上为 `mmap`，Windows 上为 `resident` | 解析后的 NZB 文章列表如何保存。**需要重启。** `mmap` 会把列表写入 `data/nzb-index/<id>.bin`，并按需映射该文件，因此数据存在页缓存中，而不是 zurg 的堆内存里。`reparse` 会在发布稳定后释放这些数据，当读取或修复需要时再从磁盘重新解析 NZB，本身不占用任何磁盘空间。`resident` 会在进程存活期间把所有列表都保存在内存中，这是**之前的行为**，也是之前每个版本的做法。无法识别的值会使用默认值，并在启动警告中指出；无论如何，实际生效的模式都会在启动时记录到日志中。 |
| `nzb_segments_idle_secs` | int | `120` | 在惰性模式下，发布的文章列表在最后一次读取之后保留多久。**需要重启。** 清理任务每 30 秒运行一次，所以 10 是它能支持的最短时间，也是仪表盘的下限。在 `resident` 模式下会被忽略，因为该模式从不释放任何内容。`0` 表示使用默认值。 |

这里的取舍值得直说，因为它不是常见的内存换速度。列出文件的操作（库刷新、指纹检查、*arr 询问某个任务是否已经稳定）在任何模式下都不会碰到文章：文件名、大小和文章数量都直接从条目本身获取。惰性模式的代价，是在 `nzb_segments_idle_secs` 时间内无人访问的发布，*第一次*读取会变慢；而它们节省的，是其余时间里文章列表占用的堆内存。以下是在一个 60 个文件、30,000 个分段的发布上测得的数据（Apple M3 Pro）：

| | 发布稳定后的堆内存 | 空闲发布的首次读取 | 读取路径上每篇文章的开销 |
|---|---|---|---|
| `resident` | 1.74 MB（每个分段 58 B） | — | 6 ns |
| `reparse` | 21.3 kB（每个分段 0.71 B） | 39 ms | 52 ns |
| `mmap` | 16.6 kB（每个分段 0.55 B） | 0.27 ms | 63 ns |

`mmap` 重新加载的时间中，有三分之二花在对刚映射的索引做校验和上，而映射本身只需 0.08 ms。这笔开销是值得的：没有它，arena 中哪怕一个错误字节，都会被当作一个没人发布过的 message id 去服务，新闻服务器会回复它为失效文章，而上层的每一层都会把这当成发布本身受损。

再看一个真实的库：2,636 个 NZB，2750 万个分段，同一个二进制文件在同一批语料上运行三次，扫描后保持空闲：

| | 常驻内存集 | 活动堆内存 | 空闲 CPU | 冷打开，p50 | 磁盘上的索引 |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

热打开、流式吞吐量和启动时间几乎没有差别。在有真正内存映射的平台上，`mmap` 是默认值，因为除了磁盘占用之外，它在其他各项指标上都更好。冷打开也是如此：映射一个已写好的 arena 只是一次系统调用，而重新解析 NZB 则要处理几兆的 XML。它每个文章大约占用 55 字节磁盘，并且在扫描时每个发布多一次写入；只要 NZB 变化，索引就会重写，NZB 删除时索引也会一并删除。如果宿主机上的 `data/` 不能增长，请选择 `reparse`。在 Windows 上没有内存映射，索引只能读入堆内存，这等于常驻内存*加上*一次重新加载，所以那里的默认值仍是 `resident`，而值得选择的惰性模式是 `reparse`。

## 2. 媒体服务器集成 {#2-media-server-integration}

把 zurg 连接到你的媒体服务器，这样库更新、元数据匹配和观看列表监控都能自动完成。

### Premiumize、Debrid-Link 和 Offcloud {#premiumize-debrid-link-and-offcloud}

```yaml
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY_OR_OAUTH_TOKEN
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_TOKEN
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
```

这些后端支持浏览库、流式读取和重定向读取、STRM、磁力链接添加、`.torrent` 上传以及删除。每个账户还会在自己的 `__<name>__` 目录下显示。你可以通过仪表板或 `zurg setup` 添加账户。无人值守设置支持 `--premiumize-token-file`、`--debridlink-token-file` 和 `--offcloud-token-file`，也支持环境变量 `PREMIUMIZE_TOKEN`、`DEBRIDLINK_TOKEN` 和 `OFFCLOUD_TOKEN`。

Premiumize 会挂载已完成的传输，以及清空传输列表后仍保留的云端文件。嵌套文件夹会保留其路径。通过 zurg 提供的哈希会保存到 `data/premiumize/<account>/sources.json`，因此即使重启或清空已完成的传输，跨账户的哈希匹配也不会丢失。没有记录哈希的导入云端内容仍然可以流式播放，但无法通过哈希修复，也无法通过哈希与其他账户匹配。通过 zurg 删除 Premiumize 传输时，也会删除该传输所拥有的文件。云存储和 fair-use 配额仍然是账户自身的限制。

Debrid-Link 会分页列出种子箱内容，并通过文件 ID 解析每个文件。它已停用的缓存端点不再使用；仅缓存的添加操作只能从添加请求的响应中确定是否命中。每日添加次数和流量配额的失败会被报告为账户限制。后端在收到 flood 拒绝后会暂停。

Offcloud 通过云端 explore 端点解析文件句柄。文件大小会与交付服务器进行核对。在能够明确匹配的情况下，缓存的种子元数据会提供文件夹路径。如果文件列表存在歧义，则会报告为错误。格式错误的磁力链接会在提交前被拒绝。

交付 URL 会在缓存过期或读取使其失效时刷新。请将生成的 URL 和 STRM 访问保持私密；服务提供商的配额归提供字节流的账户所有。这三个后端每个账户条目只使用一个凭据，不会在其他账户的文件 ID 之间轮换。

### Plex 集成 {#plex-integration}

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `plex_server_url` | string | `""` | 你的 Plex 服务器地址。做 Plex 匹配和 watchlist 功能时必须填。例如：`http://localhost:32400` |
| `plex_token` | string | `""` | 你的 Plex 认证 token。需要和 `plex_server_url` 一起填。 |
| `plex_scan_check_url` | string | `plex_server_url` 的值 | zurg 在重启挂载之前，会先问这个 Plex 服务器是否正在扫描库。如果在扫描，它就等着。扫描途中挂载突然消失，Plex 会把它看不到的内容全部删掉。在不需要自己运行 Plex 集成的实例上设置这个值。通常每个提供商一个实例就够了。如果在那里设置 `plex_server_url`，也会启动 Plex 匹配。 |
| `plex_scan_check_token` | string | `plex_token` 的值 | `plex_scan_check_url` 使用的 token。 |
| `plex_match_every_mins` | int | `1440` | zurg 多久扫描一次你的 Plex 库，把种子和 Plex 条目对应起来（单位：分钟）。这样就能显示哪些种子对应哪些 Plex 媒体等功能。最小值为 1；填 `0` 会使用默认值。需要设置 `mount_path`。 |
| `plex_watchlist_enabled` | bool | `false` | `watchlist.enabled` 的旧写法（参见 [Watchlist](#watchlist)）；仍然有效。 |
| `plex_watchlist_check_every_secs` | int | — | `watchlist.check_every_secs` 的旧写法；如果对应的配置块没有设置它，仍然有效。 |
| `watchlist_quality` | string | `"best"` | `watchlist.quality` 的旧写法；如果对应的配置块没有设置它，仍然有效。 |
| `plex_settings_policy` | string | `"guard"` | zurg 可以在多大范围内修改对挂载很重要的 Plex 设置。可选值：`off`（什么都不动）、`warn`（全部报告，不做修改）、`guard`（只修复错误值会导致丢失库内容的设置，其余只报告）或 `enforce`（另外修复那些会让 Plex 为没人看的结果解码整个文件的设置）。凡是背后有可见功能的设置，比如 Skip Intro、Skip Credits、拖动预览缩略图、章节图片、音量均衡、声音分析，都只会报告，不会修改。参见 [Plex settings](../guides/plex.md#recommended-plex-settings)。 |
| `plex_settings_ignore` | list | — | zurg 不论策略如何都不去动的 Plex 偏好设置 id，匹配时不区分大小写。这是按单个设置生效，而不是按档位生效，所以排除其中一个不会影响它旁边的其他设置。如果某个 id 对应的设置 zurg 并不认识，启动时会报告，不做任何修改。仪表板（Dashboard）上的 **Let Plex Empty Its Own Trash** 开关会把 `autoEmptyTrash` 写进这个列表。参见 [Opting out of one setting](../guides/plex.md#opting-out-of-one-setting)。 |

> **注意：** 最好通过仪表板（Dashboard，网页界面）的认证流程来配置 Plex，它会把 `plex_server_url` 和 `plex_token` 写回 `config.yml`。上面这些键依然支持手动配置。

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### rex

zurg 可以为 [rex](../../rex/with-zurg.md) 提供内容。rex 是一个媒体服务器，供官方 Plex 应用使用，它会读取 zurg 中的每个文件。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rex_url` | string | `""` | 由这个 zurg 构建媒体库的 rex 的 URL，例如 `http://192.168.1.20:32400`。在仪表盘的 Plex 登录中选择一个 rex 后，这里会被设为 rex 获取来源的地址（它的局域网或 Tailscale 地址，使用纯 HTTP），信息流无需重启即可开始工作；如果你想在不登录 Plex 的情况下为 rex 提供内容，可以手动设置。zurg 随后会把媒体库推送到 rex：配置目录中的每个视频文件、`rex_music` 中的每个音频文件以及 `rex_photos` 中的漫画，都会附带其路径、大小、IMDb id 以及 ffprobe 读取到的媒体详情。推送时机包括：媒体库加载完成后、每隔 `rex_snapshot_every_hours` 一次，以及任何版本被添加、分析、重命名、移动或删除时。rex 必须等 ffprobe 分析完文件后才能播放它，因此设置 `rex_url` 会强制开启 `auto_analyze_new_torrents`，无论该键如何配置；媒体库加载后，其余部分会被分析一次，之后每天分析一次。每次探测都会从持有该版本的账户读取，所以如果你不想为一个从不观看的媒体库消耗流量，请保持目录范围较窄，并且不要使用 `tags_*` 过滤器（只要使用其中任何一个，账户上的每个版本都会被分析）。刷新时，在放置每个新版本之前，还会通过 `dmm_api_key` 查询其 IMDb id（放置规则见 `dmm_api_key`）。\*arr 或 Bazarr 写在 `__magic__` 中视频旁边的字幕会随视频一起发送到 rex（参见 [`__magic__`](../guides/magic.md)）。zurg 会告诉 rex 去哪里读取文件：即其 WebDAV 地址 `http://<address>:<port>/dav`，若设置了 `username` 和 `password` 也会一并提供。地址取 `host` 的值（当它是单个地址时）；否则（默认情况下）取 zurg 连接 rex 时所使用的出站地址，并且 rex 必须能够访问该地址。在容器中，这指的是容器自身的地址，只有同一台 Linux 机器上的 rex 才能访问它：在 Windows 和 macOS 上，请使用安装程序安装 zurg，而不要在 Docker Desktop 中运行；在 Linux 上，如果 rex 位于另一台机器，请为 zurg 的容器设置 `network_mode: host`（参见 [rex 与 zurg 配合使用](../../rex/with-zurg.md#d4-connect-zurg-to-rex)）。如果 rex 离线，会先重试，然后整个媒体库都会被重新发送；这不会阻塞任何操作。当 `plex_server_url` 指向同一个 rex 时，不会发送 Plex 扫描。每次快照后以及每十分钟，zurg 会读取你在 rex 中为其版本所做的 Fix Matches，并将每个结果保存为该版本手动设置的 id，除非你之后在管理页面上另行设置了 id；随后 DMM 会据此放置该版本。若要为某个目录在 rex 中单独设置媒体库，请在该目录上设置 [`rex_shows`、`rex_movies`、`rex_music` 或 `rex_photos`](#directory-options)。如果你不运行 rex，请将 `rex_url` 留空。 |
| `rex_source` | string | `"zurg"` | rex 用来识别此 zurg 的来源名称。为每个向同一个 rex 提供内容的 zurg 设置各自不同的名称。 |
| `rex_snapshot_every_hours` | int | `6` | 整个媒体库重新推送到 rex 的频率，用于修复因推送丢失而遗留的问题。默认值适用于所有配置。 |

```yaml
rex_url: "http://192.168.1.20:32400"
```

### 关注列表 {#watchlist}

在你的 Plex 观看列表里添加一个条目,zurg 就会去获取它。每个新加入的条目都会在你的索引器上搜索。Newznab 索引器会返回一个 NZB,它会像 Sonarr 抓取或 Stremio 播放那样直接放进 Usenet 后端。三者共用同一套命名规则,所以能找到彼此抓取的内容,不会重复下载。Torznab 索引器返回的是种子,只有当某个 debrid 账户已经缓存了它时,才会把它加入该账户。`prefer` 决定在分辨率相同的多个版本之间先尝试哪一类。电影只会变成一个版本。剧集则按季获取,季合集优先于单集。如果没有人发布某一季的合集,就回退到搜索结果中的单集,每一集取最佳版本。只有当对应版本已经检查过,并且 `remove_after_grab` 允许时,条目才会从观看列表中移除。失败的条目会留在列表里,会在 5、10、15 分钟后重试,然后是一小时后,之后间隔越来越长。如果某个标题连续失败两周,就会被暂停,直到你在获取页面上手动恢复它。参见 [持久化与恢复](../guides/acquisition.md#persistence-and-recovery)。

需要 `plex_token` 和至少一个索引器。如果没有自己的列表,它会借用 Stremio 插件的列表。监控器连接的是 Plex 的云服务,所以不需要 `plex_server_url`。NZB 需要同一实例上有 `nzb` 或 `torbox_nzb` 提供方。种子需要一个能接收它们的 debrid 账户。两者满足其一即可。

下表中的每个选项都在配置页面的 **Plex Watchlist** 下,包括索引器列表。仪表盘写入的是这个配置块,而不是旧版的扁平键。关闭仪表盘中的监控开关时,也会清除 `plex_watchlist_enabled`,因为该键会与开关做逻辑或。

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enabled` | bool | `false` | 启动监控器。旧版的 `plex_watchlist_enabled` 键仍然有效。 |
| `check_every_secs` | int | `60` | 多久在 Plex 云服务上轮询一次观看列表。 |
| `indexers` | list | `[]` | 要搜索的索引器,每个包含 `name`、`url`、`api_key`,以及可选的 `api_path` 和 `type`。`type: torznab` 表示种子索引器。不填则默认为 `newznab`。格式与 `stremio.indexers` 相同,此列表为空时会整体借用它。 |
| `prefer` | string | `"usenet"` | 当 NZB 和种子的分辨率相同、两者都能满足需求时,先尝试哪一类。分辨率优先,所以 2160p 的种子会排在 1080p 的 NZB 之前。`usenet` 表示先试 NZB,`torrents` 表示先试种子,`best` 则完全由排名决定。参见 [Newznab 与 Torznab](../guides/acquisition.md#newznab-and-torznab)。 |
| `max_size_gb` | int | `0` | 电影和单集中超过此大小的版本会被丢弃;季合集中若某集超过此大小,整个合集也会被丢弃。`0` 表示不限制,因此 `best` 会选择完整光盘的 remux。索引器未标明大小的版本会保留。 |
| `max_season_size_gb` | int | `0` | 对季合集中每一季的大小上限,按合集里标明的每一季分别计算。`0` 表示不限制:只有在设置了 `max_size_gb` 时,合集才会按每集大小受其限制,因此长季的 remux 仍会计入。 |
| `quality` | string | `"best"` | 决定哪个版本胜出:`best`(先看分辨率,再看大小)、`4k`、`1080p`、`720p`(优先该分辨率,找不到则回退到 best)或 `smallest`。旧版的 `watchlist_quality` 键仍然有效。这里只接受一个值;只有 `acquisition.quality` 接受列表(参见[获取来源](#acquisition-sources))。 |

`acquisition` 块还可以设置 `concurrency`(默认 `8`,范围 `1` 到 `200`),即同时搜索、检查和放置的标题数量;以及 `indexer_concurrency`(默认 `3`,范围 `1` 到 `16`),即同时对同一个索引器发起的请求数量。如果索引器的 key 是共享的,请把后者设得低一些。

此块中没有 `exclude_words` 的副本。如果想让 `DV` 或 `HDR10+` 之类的词不出现在观看列表的抓取结果中,请添加一个只包含 `exclude_words` 的 `acquisition:` 块。上面的所有设置仍然生效。参见[按名称排除版本](../guides/acquisition.md#excluding-releases-by-name)。

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  quality: best
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: your-api-key
```

### 获取来源 {#acquisition-sources}

`acquisition.sources` lists the services zurg acquires for, each on the shared queue described in [acquisition sources](../guides/acquisition.md). The search settings (`indexers`, `quality`, `prefer`, `max_size_gb`, `max_season_size_gb`) sit beside `sources` in the `acquisition:` block and fall back to the `watchlist:` block above. Only `acquisition.quality` also takes a list of resolutions, such as `[1080p, 4k]`: zurg then keeps a copy of each film on the DMM wanted list at each of them, while shows on that list, and every other source, take the list's highest resolution as their one `quality`. See [a copy at each of several resolutions](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

`best_first` belongs to the `acquisition:` block alone and is off by default. Turned on it makes a `radarr` or `sonarr` source's first grab follow the quality profile's order of preference. The best allowed resolution comes first. Anything at or above the cutoff counts as the cutoff. When a release fails zurg moves down the profile. When it is off a movie takes the allowed release that is cheapest to check. A series takes the one `quality` ranks first. The upgrade pass heads for the cutoff afterwards. The best release is more often a large archive set so the first file tends to arrive later. See [taking the profile's best first](../guides/acquisition.md#taking-the-profiles-best-first).

`exclude_words` (list, default empty) sits there too and has no watchlist fallback. A release whose name has one of these words is never taken, from any source. Matching is by whole word and ignores case, so `DV` does not catch `DVDRip`. `DV`, `DoVi` and `Dolby Vision` count as one word, and so do `HDR10+` and `HDR10Plus`. `HDR10` and `HDR10+` are different words. An entry with no letter or digit is refused at startup. The full rules and how they combine with Radarr and Sonarr profiles are in [excluding releases by name](../guides/acquisition.md#excluding-releases-by-name).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | required | 字母、数字、`_` 和 `-`，且必须唯一。用于标识该来源保存的队列，所以请保持不变。 |
| `type` | string | required | `plex_watchlist`、`seerr`、`radarr` 或 `sonarr`。 |
| `enabled` | bool | `false` | 已禁用的来源会保留在文件中，但不会被轮询。已禁用的 `radarr` 或 `sonarr` 来源仍会被只读方式读取，供管理页面的[重复项视图](../guides/acquisition.md#finding-duplicate-releases)使用。 |
| `check_every_secs` | int | `60` | 轮询该来源的频率。 |
| `url` | string | | `seerr`、`radarr` 和 `sonarr`：服务的 HTTP(S) 基础 URL，不含凭据、查询参数或片段。可以填写基础 URL，也可以带结尾的 `/api/v1`（Seerr）或 `/api/v3`（Radarr、Sonarr）。 |
| `api_key` | string | | `seerr`、`radarr` 和 `sonarr`：服务的 API 密钥。以请求头发送，绝不放在 URL 中，并会从共享日志和配置中隐去。 |
| `library_path` | string | `mount_path` + `/__magic__` | 仅适用于 `radarr` 和 `sonarr`：*arr 看到 zurg `__magic__` 目录的位置，例如容器把 zurg 挂载在 `/data/zurg` 时，可填写 `/data/zurg/__magic__`。该目录下的电影或剧集文件夹会以相同的相对路径放在 `__magic__` 内；其他位置的文件夹会被跳过。必须是绝对路径；也接受 `Z:\__magic__` 这类 Windows 路径。zurg 还会将其与 *arr 看到的 zurg 下载客户端下载文件夹位置进行比较，如果布局会导致导入变成复制，就会报告；详见 [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。 |
| `remove_after_grab` | bool | `true` | 仅适用于 `plex_watchlist`；对 `seerr`、`radarr` 和 `sonarr` 无效。 |
| `only_new_items` | bool | `true` | 仅适用于 `plex_watchlist`；对 `seerr`、`radarr` 和 `sonarr` 无效，因为它们的待获取项目始终需要处理。 |

```yaml
acquisition:
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /data/zurg/__magic__
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /data/zurg/__magic__
```

### Plex 库维护（仅限同一主机） {#plex-library-maintenance-same-host-only}

这些功能需要 Plex 与 zurg 安装在同一台机器上，因为它们会直接读取 Plex 的数据库文件。`plex_server_url` 通常指向另一台主机或容器，而 HTTP 接口无法提供该文件，因此这些功能改由明确指定的路径驱动，在你设置路径之前默认保持关闭。

zurg 只会通过只读句柄**读取**此数据库。它从不写入数据库，也从不停止 Plex。它唯一创建的文件是位于自身 `data/plex-backups/` 中的快照，绝不会放在 Plex 的目录里。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `plex_database_path` | string | `""` | `com.plexapp.plugins.library.db` 的完整路径。留空则会关闭本节中的所有功能。 |
| `plex_sqlite_binary` | string | Plex 的安装位置：Linux 上为 `/usr/lib/plexmediaserver/Plex SQLite`，macOS 上为 `/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite`，Windows 上为 `%ProgramFiles%\Plex\Plex Media Server\Plex SQLite.exe` | Plex 自带定制的 SQLite 版本。标准的 `sqlite3` 可能无法处理此数据库，甚至会损坏它。 |
| `plex_backups_keep` | int | `5` | 保留的快照数量。每个快照都与整个数据库一样大。显式设为 `0` 则只观察，从不创建快照。 |
| `plex_backups_every_mins` | int | `15` | 两次快照之间的最短间隔，避免 zurg 反复崩溃重启时每次都复制数据库。 |
| `plex_trash_sweep_every_mins` | int | 未设置（见说明） | 多久清理一次那些文件已从挂载点消失的 Plex 条目。未设置时由 zurg 自行决定：如果没有其他程序在清空 Plex 的回收站，则每 60 分钟执行一次清理；如果 Plex 仍在清空，则 zurg 暂停清理。显式设为 `0` 会关闭 zurg 自身的清理，回收站交由你自行处理；负值则会完全关闭清理任务，包括修复部分在内。`0` **不会**把 Plex 自身的回收站清空功能交还给 Plex，那由 `plex_settings_ignore` 和仪表盘中的 **Let Plex Empty Its Own Trash** 开关控制。参见 [谁来清空回收站](../guides/plex.md#who-empties-the-trash)。 |
| `plex_trash_sweep_max_items` | int | `50` | 单次清理最多可删除的条目数。超过此数量时将中止清理，且不删除任何条目。 |
| `plex_trash_sweep_max_percent` | int | `10` | 同样的上限，但以回收站内条目的百分比计算，因此会随媒体库大小自动调整。 |
| `plex_trash_sweep_min_age_days` | int | `14` | 条目在被清理之前会保留红色回收站图标的时长——这是针对 zurg 无法判定状态的条目所用的后备规则。若 zurg 确认某个版本已永久失效，则会立即删除而无需等待；仍在修复中的条目则无论时长如何都会保留。显式设为 `0` 时，只要其他保护条件允许，即会立即删除。 |

**为什么要做快照**，既然 Plex 已经每晚自动备份：真正的风险在于 Plex 正在扫描时挂载点受到干扰，这可能在几秒内清空整个媒体库。此时，每晚的备份可能已经过时 24 小时；而在 zurg 触碰挂载点之前刚拍下的快照，只有几秒的时间差。

#### 回收站清理永远不会删除的内容 {#what-the-trash-sweep-will-never-remove}

Plex 的回收站并不是一份可以放心删除的清单，它只是一份候选名单，其中很大一部分是错的：

- **仍然有文件的条目。** 只要一部电影的某个版本消失，Plex 就会把整部电影标记为已删除，因此回收站里的条目经常还有能正常播放的版本。清理程序会改为删除那个幻影版本，这样条目就会连同合集、海报、观看状态和 `added_at` 一起从回收站里恢复出来。如果这一修复因任何原因失败，该条目会**被保留**，它会留在你的库里，并带着回收站图标。它永远不会被删除。
- **剧集或季的分集仍然存在的剧集或季。** 这些条目本身没有任何文件，所以挂载点的任何状况都不能成为删除它们的理由。
- **在删除前，清理程序没有逐个确认其文件已丢失的任何条目。**

删除是逐个条目进行的，而不是使用 Plex 自带的 `emptyTrash`。`emptyTrash` 是针对整个媒体库分区的，它会把上面所有这些条目一并清掉，而这恰恰是清理程序绝对不能做的事。

#### zurg 已经知道文件是否会回来 {#zurg-already-knows-whether-it-is-coming-back}

对于每个缺失的文件，清理程序会先询问 zurg 自己的修复状态，然后才去看时间限制。

| zurg 的判定 | 清理程序的处理 |
|---|---|
| 文件仍然可以读取（过滤器把它从挂载中隐藏了） | 回退到时间窗口 |
| 已损坏，且修复尚未放弃 | **保留该条目**，无论修复需要多长时间 |
| 已损坏，且原因永久无法修复（infringing、invalid、not allowed 等） | **立即删除**，等待也无法让它恢复 |
| 没有判定结果，即种子已完全离开账户，或路径无法解析 | 回退到时间窗口 |

一个包含多个版本的条目会作为整体来判断：只要有一个版本仍在修复中，就保留整个条目；只有当所有版本都确定失效时，该条目才会被视为失效。查询失败绝不能作为删除的理由。zurg 无法确认的任何内容，都照旧交由下面的时间窗口处理。

#### 回收站图标代表状态，所以删除要等待 {#the-trash-icon-is-a-status-so-removal-waits}

Plex 有三种状态，其中只有中间那种会以问题的形式显示出来：

| 状态 | 你看到的内容 |
|---|---|
| 正常 | 一个正常的条目，可以播放 |
| **已回收（Trashed）** | 条目**仍在你的库中，也仍被计数**，显示为灰色，并带有**红色垃圾桶图标**，无法播放 |
| 已清除（Purged） | 什么都没有，条目已从 Plex 中彻底删除 |

垃圾桶图标是你唯一能看到内容已丢失的提示。而清除条目会连这个提示一起去掉：条目不再明显损坏，而是直接消失。因此，zurg 没有判定结果的条目会保留在库中，直到它带着这个图标满 `plex_trash_sweep_min_age_days` 天。这段时间就是你发现它并重新获取的机会；过了这段时间仍然损坏的，才是值得清理的垃圾。

它还是上限和挂载探测之外的第三道安全防线。挂载的临时故障通常会在这段时间结束前自行恢复。

宽限期**只针对删除**。修复会把一个可播放的条目放回库中，所以无论如何都会在下一次扫描时进行，不必等待。否则，一个已经正常工作的条目会无缘无故地继续带着垃圾桶图标。

以上这些状态都不会影响文件。文件早已从挂载点消失，这正是产生墓碑记录的原因。而且，你的 debrid 账户中的任何内容都不会被删除。

#### 何时拒绝运行 {#when-it-refuses-to-run}

- zurg 没有在管理 rclone（`rclone_enabled: false`），它没法为一个不归它管的挂载点作保，所以“文件不见了”这句话毫无意义。
- rclone 没在运行，或者挂载点读不出东西。探测会打开并读取一个文件，而不是调用 `stat`，因为 `stat` 是由 rclone 的目录缓存回答的，即使读取早已失效，它仍会一直成功。
- Plex 正在扫描。扫描进行中时，它仍在判断哪些文件缺失。
- 任一上限会被超过。这一条最重要：**一个返回空内容但可读的挂载点会通过其他所有检查**，并让整个媒体库看起来都被删了。一旦超过上限，清理会整体中止，不删除任何东西，并在日志里说明这一点。

在删除任何内容之前会先做一次快照，快照失败则会中止清理。

> **关闭方法：**将 `plex_trash_sweep_every_mins: 0`（删除这个键并不等同于设为 0：此时 zurg 会根据 Plex 是否自动清空自己的回收站来决定）。修改后需要重启 zurg。这只会关闭 zurg 的删除功能。如果想让 Plex 重新自动清空回收站，请使用仪表盘上的 **Let Plex Empty Its Own Trash** 开关，或者把 `autoEmptyTrash` 列在 `plex_settings_ignore` 里。

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

这个路径是 Linux 安装包存放数据库的位置。在 macOS 和 Windows 上请完整写出路径，因为 zurg 不会展开 `~` 或 `%LOCALAPPDATA%`。`plex_sqlite_binary` 已经默认指向各系统上 Plex 的安装位置。

| Plex 所在系统 | `plex_database_path` |
|---|---|
| macOS | `/Users/you/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db` |
| Windows | `C:\Users\you\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db` |

在 YAML 中，Windows 路径请用单引号括起来，这样其中的反斜杠会按原样保留。

> **与 zurg 无关、但相关的 Plex 设置：**请把 Plex 的 *Settings → Library → Empty trash automatically after every scan* **关闭**。这个选项在 Plex 中默认是开启的，在 zurg 挂载点上并不安全——扫描时如果遇到一个短暂无法读取的挂载点，就会永久删除媒体库内容，而不是把它们放进回收站，等挂载恢复后又能找回来。在默认的 `guard` 策略下，zurg 会自己关闭这个选项，并在仪表盘和日志中说明。如果你的文件需要在不同媒体库文件夹之间移动，并且需要这种清理功能，可以在配置页面使用 **Let Plex Empty Its Own Trash** 开关把它交还给 Plex，风险自负。

### 其他集成 {#other-integrations}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `jellyfin_server_url` | string | `""` | 你的 Jellyfin 服务器地址。zurg 检测到变化时会通知它刷新媒体库。示例：`http://localhost:8096` |
| `jellyfin_token` | string | `""` | 用于身份验证的 Jellyfin API 令牌。 |
| `emby_server_url` | string | `""` | 你的 Emby 服务器地址。zurg 检测到变化时会通知它刷新媒体库。示例：`http://localhost:8096` |
| `emby_token` | string | `""` | 用于身份验证的 Emby API 令牌。 |
| `dmm_api_key` | string | `""` | 你的 DMM API 密钥。赞助之后，[gatekeeper](https://gatekeeper.debridmediamanager.com/) 会显示一次它。DMM 随后会整理你的文件并填充你的 wanted 列表。 |
| `dmm_metadata_secret` | string | `""` | DMM 内部元数据 API 的密钥。设置后，启动时会通过 DMM 根据发布名称来识别没有 IMDb id（或只有 OpenSubtitles 的缺失标记）的种子。DMM 只在能精确匹配到唯一标题时才会返回结果。无法识别的种子会保留空 id，这样 Plex 匹配器仍然可以为它们补全信息。 |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. 播放与文件结构 {#3-playback--file-structure}

控制你的媒体服务器能看到哪些文件，以及内容如何进行流式传输。

### 流媒体模式 {#streaming-mode}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | 为 true 时，**挂载**读取会被重定向到账户自己的下载 URL，而不是经过 zurg 代理。这样能降低 zurg 的 CPU 和带宽占用，但客户端必须能直接访问账户的服务器。对于链接在本地提供的后端无效。Usenet 文件没有可分发的 URL，因此始终会被代理。**启用前请先阅读下面的服务商风险。** |
| `serve_strm_files` | bool | `false` | 为 true 时，zurg 在 WebDAV 挂载中用 `.strm` 文件代替实际视频文件。Plex/Jellyfin 等媒体服务器会读取 `.strm` 文件来获取串流 URL。**重要：** 启用后，实际视频文件会被隐藏，并替换为 `.strm` 条目。 |
| `save_strm_files` | bool | `false` | 为 true 时，zurg 会把 `.strm` 文件写入 zurg 二进制文件旁边的 `strm/` 目录。如果你想在磁盘上保留 STRM 文件（例如手动导入媒体服务器），这个选项很有用。文件内的 URL 使用 `base_url`。只有播放器能打开的文件才会生成，即识别出的视频和音频，以及 `addl_playable_extensions` 中指定的任何扩展名。因此字幕、海报、NFO 和 PAR2 分卷不会被输出，旧版本写入的这些文件会在下次扫描该资源时被删除。如果某个 `.strm` 的 URL 不再匹配（因为 `base_url` 变了，或旧版本写入了它），下次启动时会原地重写；如果在仪表板上修改 `base_url`，则会立即重写。已经匹配的文件不会被改动，因此媒体服务器不会在每次扫描时重新读取整个文件夹。 |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

**共享 debrid 播放时，请保持挂载读取走代理（默认设置）。** Real-Debrid 会记录每个下载者的公网 IP，即使下载成功，同一账户使用多个 IP 也会收到共享警告。请让该账户的所有使用都固定在同一个公网 IP 上，包括服务器探测和转换，而不仅仅是播放器下载。TorBox 的下载 URL 在 `?token=` 中包含完整的 API 密钥，因此重定向会让每个客户端和共享用户账户都获得访问权限，包括删除权限。播放器日志和浏览器历史记录可能会保留这些信息。不要把 TorBox 链接交给不可信的客户端。

这些风险同时适用于 `disable_stream_proxy: true` 的挂载重定向和 `/strm/` 重定向。保持 `disable_stream_proxy: false` **不会**让 `.strm` 播放变成走代理，也不会让它在远程共享时变得安全。

#### `disable_stream_proxy` 的作用范围与不作用的范围 {#what-disable_stream_proxy-does-and-does-not-reach}

它管的是挂载（mount）。它对任何后端的 `/strm/` 端点都不起作用：

| 读取方式 | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| 挂载，proxy 开启（默认） | 经由 zurg 代理 | 代理 |
| 挂载，proxy 关闭 | 重定向（`302`）到账户的 URL | 代理，因为没有可以重定向过去的 URL |
| `.strm` 文件，两种设置都一样 | 重定向（`307`）到账户的 URL | 代理 |

`.strm` 是由一个与 zurg 没有会话的播放器打开的，所以端点只能把播放器自己能获取的 URL 交出去。开启 proxy 并不会让这部分流量重新经过 zurg。需要知道的一点是：通过 `.strm` 文件发起的读取，没有带宽统计，也不会在播放中途切换到另一个账户，更不会检测失效链接。而挂载读取这些都有。所以，如果你的库主要通过 `.strm` 提供，那不管怎么设置，`disable_stream_proxy` 带来的变化都很小。

`serve_strm_files` 和 `disable_stream_proxy` 是相互独立的，本页旧版本的说法并不准确。`.strm` 在做任何串流决策之前就已经作为文本返回了，所以两者可以同时开启。不过，只要 `serve_strm_files` 开着，每次播放都会走 `/strm/` 端点，而这正是上表中 `disable_stream_proxy` 不起任何作用的那一行。

### 文件过滤与检测 {#file-filtering--detection}

| 选项 | 类型 | 默认值 | 描述 |
|--------|------|---------|-------------|
| `addl_playable_extensions` | list | `[]` | zurg 除了内置的视频/音频格式外，还会把这些扩展名的文件当作可播放的媒体。仪表盘会自动统一扩展名的点号、引号和大小写。如果你想让 `m3u` 或 `cbz` 之类的文件可见并可选择，就把它们加进来。 |
| `force_select_playable_files` | bool | `false` | 设为 true 时，zurg 会自动选中种子里所有可播放的文件，即使一开始没有选中。内置视频扩展名和 `addl_playable_extensions` 都适用。如果种子里有你想访问但没被选中的视频文件，这个选项很有用。 |
| `delete_torrent_if_extensions_found` | list | `[]` | 只要种子里有任何一个文件的扩展名在这个列表里，整个种子都会从 RD 删除。适合用来自动清理含有不需要内容的种子，比如 `.rar` 压缩包（不包括 RD 解压出来的）或 `.zipx` 文件。 |
| `stream_compressed_archives` | bool | `true` | 读取压缩包里的文件时，边读边解码并播放。解码器只会在内存中保留一个有限的窗口。设为 `false` 则和旧版本一样，拒绝处理压缩包。 |

内置的可播放格式有 `.avi`、`.flv`、`.m2ts`、`.m4v`、`.mkv`、`.mov`、`.mp4`、`.mpg`、`.mpeg`、`.ts`、`.webm`、`.wmv`、`.mp3`、`.flac`、`.m4a` 和 `.m4b`。

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### 元数据与命名 {#metadata--naming}

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `retain_folder_name_extension` | bool | `false` | **已弃用，之后会移除。** 设为 true 时，文件夹名就是账户里的 `Name`，原样保留，包括扩展名。而不是用 `OriginalName`，并去掉末尾的 `.mp4` 和 `.mkv`。它只对 `Name` 包含 `OriginalName` 作为子串的情况生效，其他情况下仍然会去掉。`retain_rd_torrent_name` 会先被检查，并完全覆盖它。 |
| `retain_rd_torrent_name` | bool | `false` | **已弃用，之后会移除。** 设为 true 时，文件夹名是账户的 `Name`（Real-Debrid 的 `filename`）。设为 false 时用 `OriginalName`（`original_filename`），也就是种子本身声明的名字。这点对只选了一个文件的种子包很重要：Real-Debrid 会把 `filename` 缩成那个文件自己的 basename，而 `original_filename` 仍然是种子包的名字，所以 **`false` 得到的是种子包的名字，`true` 得到的是单个文件的名字**。 |
| `ignore_renames` | bool | `false` | 设为 true 时，zurg 会忽略种子中的所有重命名元数据，直接使用原始文件名。如果重命名的文件导致媒体服务器匹配出问题，就开启这个选项。不是已弃用的选项。 |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

两个已弃用的开关都以 `Name` 作为库的索引键，而这个字段会被账户在 zurg 底下改写；默认值则以种子声明的名字作为索引键，账户不会动它。无论设置哪一个，启动时都会记录一条警告。如果实例前面接的是 Sonarr 或 Radarr（即有 `sabnzbd:` 或 `qbittorrent:` 块），那么只有默认值才是正确的，因为访问密钥在导入后变动，会导致这个版本丢失。本版本的行为没有变化：没有人的文件夹名会变动。`docs/naming.txt` 是完整的命名规则。

### 挂载写入 {#mount-writes}

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `dav_allow_rename` | bool | `true` | 为 false 时，通过挂载点发起的 WebDAV MOVE 会被拒绝并返回 403。默认开启：重命名种子或文件正是可写挂载的用途，而且不会丢失任何内容。 |

**通过挂载点发起的 WebDAV DELETE 始终会被执行，没有对应的配置项。** 它会从库中删除文件；一旦没有任何文件剩下，还会把该资源从持有它的每个 debrid 账户中删除。在把写入程序指向挂载点之前，先想清楚代价：rclone 会把被覆盖的文件以 DELETE 加 PUT 的方式刷新，所以任何原地重写文件的操作（比如 `.nfo` 写入程序、trickplay 处理、\*arr 重命名，或者一次误操作的 `touch`）都会删除内容而不是替换它；而且挂载使用的是 rclone 自己的凭据，认证无法区分这两种操作。只有 PUT 那一步被拒绝，才能阻止这个序列悄无声息地完成。`mount_read_only: true` 才是真正阻止删除请求到达 zurg 的方法。

被拒绝的写入会返回 **403**，并在 `logs/zurg.log` 中记录允许该写入的配置项，所以写入停止工作的客户端，原因会记录在那里。

还有一个需要知道的后续影响：程序通过 FUSE 挂载写入时，rclone 的 VFS 缓存会保留修改后的副本，并按退避策略重试被拒绝的上传。在该缓存条目被丢弃之前，挂载点显示的仍是本地修改过的文件，而服务器端的文件始终没有变化。`mount_read_only: true` 可以完全避免这个问题，它会在内核层直接让写入失败，rclone 不会缓存任何内容。

```yaml
dav_allow_rename: true
```

另见 `mount_read_only`，它会让内核在写入到达 zurg 之前就将其拒绝。

### 目录列表缓存 {#directory-listing-cache}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `disable_listing_cache` | bool | `false` | 设为 true 时，每次请求都会从头重新渲染每个目录列表。建议保持关闭：开启后，对 `__all__` 发起的 `PROPFIND Depth:1` 每次都要把整个库重新渲染一遍。实测 6,120 个 release 需要 59 毫秒，2,636 个 Usenet release 需要 121 毫秒，`__magic__/__all__` 需要 148 毫秒。而媒体服务器扫描时，会一遍遍地请求同一个列表。 |

```yaml
disable_listing_cache: false
```

缓存会保存每个顶层目录最近一次的渲染结果，每种挂载方式（`/dav`、`/infuse`、`/http`）各存一份，并一直返回这份结果，直到库发生变化。什么算变化并不是猜的：正是那些本来就会让 rclone 丢弃自己缓存的同一列表的事件，比如添加、删除、重命名、重新归档 release，或者文件损坏、恢复正常。rclone 会把这些列表保存 **十二小时**。所以这里提供的列表，绝不会比挂载当前提供的那份更旧。另外还有一个硬性的 60 秒上限，作为双重保险。

`__magic__/__all__` 是镜像，也是命名空间里唯一值得缓存的列表，因为它上面的根目录只有镜像和少数几行。它还会记录存储布局，所以 \*arr 导入时只会让这一个列表失效，其他目录的渲染结果保持不变。`__downloads__` 和 `Depth: 0` 请求完全不缓存。

响应中会带上 `X-Zurg-Listing: hit` 或 `miss` 响应头，所以正在运行的安装可以直接测量效果：

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`，一个可以自行整理的目录 {#__magic__-a-directory-you-can-organise}

除了这一个，其他每个目录都是保存的筛选器。比如某个版本在 `movies` 里，是因为它符合 movies 筛选器，所以资料库里根本没有地方可以*放*东西。`__magic__` 是例外：`__magic__/__all__` 是 `__all__` 的精确副本，它旁边的根目录归你所有，任何东西都可以从镜像里移到命名空间中的任意位置。移动操作只会改写 `data/magic.journal` 里的一行，再压缩进 `data/magic.json`。不会移动任何字节，也不会重命名任何种子。这些行以版本的内容哈希为键，所以重建该版本的修复操作不会丢失你放置东西的位置。这就是让 Radarr 和 Sonarr 通过重命名而不是复制来导入的原因。

完整说明，包括修复后哪些东西会保留、每种拒绝的含义，请见 [docs/magic.md](../guides/magic.md)。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `magic.enabled` | bool | `false` | 是否提供 `__magic__`。默认关闭，因为它是一个可写的目录树。如果某个 \*arr 指向了错误的根文件夹，可能会把资料库整理乱。在没有移动任何东西的情况下，它自己的 `__all__` 与资料库的完全一致，根目录下也没有其他内容。 |
| `magic.allow_delete` | bool | `false` | 设为 true 时，对 `__magic__` 下**文件**的 DELETE 也会删除内容，就像对挂载点本身的 DELETE 总是会做的那样。默认关闭时，删除只是隐藏：条目会离开 `__magic__`，但仍保留在 `__all__` 和每个筛选目录中。无论此项如何设置，版本文件夹和目录都不会删除内容。Sonarr 每次导入后都会删除任务文件夹，所以这一点很重要。删除视频或压缩包内的条目，也会在其整个版本都不再被 `__magic__` 下的任何内容使用后，连同该版本一起删除。 |
| `magic.sidecar_max_mb` | int | `32` | 客户端可以 `PUT` 到 `__magic__` 中的单个文件的最大大小。超过此值，写入会被拒绝并返回 **413**。 |
| `magic.sidecar_budget_mb` | int | `2048` | 整个 sidecar 目录树可以增长到的最大大小。超过此值，写入会被拒绝并返回 **507 Insufficient Storage**。这一点是 413 没有说明的：删除某些内容后，同一请求就会成功。总大小在启动时通过遍历目录树计算，所以重启不会把额度还给一个已经写满的目录树。每次拒绝之前也会再算一次，因为该目录树就是 zurg 自己挂载写入的同一个 `data/local` 目录。如果有文件在 zurg 背后被从那里删除，就不能继续为它计费。设为零或负数时使用默认值，没有办法设置为不限制。 |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` 在这里不适用，挂载点上不受门控的删除路径也不适用。它们管的是会重命名和销毁 debrid 账户所持内容的路由。`__magic__` 下的写入不会触及任何账户。`mount_read_only: true` 仍然会在内核层面覆盖一切。

有两点值得注意。筛选目录按设计保持不变，所以你在 `__magic__` 里移动过的版本，仍然会以原名出现在 `recent` 和 `movies` 中。请让媒体服务器只指向 `__magic__` **或** 筛选目录，不要两者都指。任何真正新写入挂载点的内容（`.nfo`、字幕、海报）都会落在 zurg 自己的 `data/local` 中，并合并进目录列表。这就是为什么版本旁边的 sidecar 文件能直接生效。

#### 附属文件，以及两个上限的用途 {#sidecar-files-and-what-the-two-caps-are-for}

挂载点中的嵌入式挂载是一个 union，它的第一个上游是 `data/local`。因此，当程序在挂载点上新建文件时，rclone 会直接写到那里，zurg 根本不会被询问。这个目录树没有任何上限，除非 [`union_writable: server`](#rclone-settings) 调换了 union 的顺序。这样一来，创建请求会以 `PUT` 的形式发给 zurg。在 `__magic__` 之外，这类请求会被拒绝；在 `__magic__` 之内，则受两个上限约束。

在默认顺序下，这两个上限针对的是另一类客户端：直接挂载 `/dav`、前面没有 union 的客户端。这类客户端会向 zurg 发送 `PUT`，zurg 会把请求体写入 `data/local/__magic__/<path>`，也就是 union 所服务的那个目录。所以两个视图显示的是同一个目录，而不是两个。如果没有边界，这就会变成一个可通过 WebDAV 访问的通用文件存储。`sidecar_max_mb` 和 `sidecar_budget_mb` 正是为了防止这种情况而存在的。

由 `__magic__` 的性质决定，有两条规则，客户端可能会看到这两种拒绝：

- **镜像属于库本身。** `__magic__/__all__` 以及直接位于其中的 release 文件夹都是计算生成的，所以针对它们的 `MOVE`、`MKCOL` 或 `DELETE` 会返回 **403**。那里的一行记录会成为一个已经有地址的 release 的第二个地址。更深一层是 release 自己的文件夹，在那里写入和其他位置一样普通。这正是 \*arr 把 `.nfo` 放在它导入的文件旁边的地方。
- **库所应答的内容不能被覆盖。** release 文件夹、其中的条目，以及移动操作放置过东西的路径，都是从库中渲染出来的。所以对这些路径执行的、写入真实文件的 `PUT` 或 `MOVE` 会返回 **403**。这也包括 release 中并不存在、却位于 release 文件夹内的名称。该文件夹的列表属于这个 release，因此放在里面的文件不会被任何列表列出。
- **放置操作绝不会销毁真实文件。** 把库中持有的内容移动到 sidecar 占用的路径上，会被拒绝而不是覆盖，即使设置了 `Overwrite: T` 也一样。反过来，把包含真实文件的目录移动过去也是如此：它不能被重命名到库所应答的路径上，否则它的文件会落进一个只列出该 release、别无其他内容的文件夹里。

`DELETE` 一个 sidecar 会真正删除它。这是 `__magic__` 中唯一一处删除并非墓碑（tombstone）的情况。墓碑只会隐藏库在别处仍然持有的条目，而 sidecar 的字节只存在于 `data/local` 中，别无其他地方。

#### `__magic__` 页面 {#the-__magic__-page}

仪表盘上有一个属于该命名空间的独立页面，地址是 `/magic/`。只要配置或提供了 `__magic__`，仪表盘的快速链接里就会出现它。表格只能在这里看到，其中两种状态也只能从这里进入。

页面会显示存储了多少行（placements、tombstones 和 directories 分别统计），journal 和 snapshot 在磁盘上占多少空间，sidecar 目录树用掉了 `sidecar_budget_mb` 的多少，以及整个 `data/local` 的大小。最需要留意的是最后这个数字。会复制而不是移动的客户端会把字节写到那里，所以如果 `data/local` 涨到几 GB，说明有东西在用错误的方式导入。行按 release 分组。表格很大时，页面会截断显示并注明截断了多少行，而上面的计数始终针对整个表格。

stored rows 列表只显示前一千行。\*arr 每次导入都会留下一个 tombstone，所以在整理好的库里，大部分行都排在这一千行之后。stored rows 和 dangling 页面上的搜索框可以按名称、挂载路径或 hash 查找某个 release，并列出关于它的所有行及其按钮。`data/magic.json` 不能替代这个做法：zurg 只在停止时从内存中把它写出来，所以 zurg 运行时手动从文件中删掉的行会重新出现。

页面上有三个按钮，它们都通过同一个操作实现，也就是让一行不再存在：

- **Reset** 一个 placement，文件或文件夹就会回到库默认的位置。
- **Unhide** 一个 tombstone，这个条目会重新出现在 `__magic__` 中。隐藏它时没有销毁任何东西。如果某个 release 在 `__all__` 中，但即使删除后再添加，也从未出现在 `__magic__/__all__` 里，那它就有一个 release tombstone。行是按它的 hash 作为键的，而重新添加不会改变 hash。搜索这个 release，然后 unhide 对应的那一行即可。
- **Delete** 一个 **dangling** 行，也就是其 release 或其中的某个文件已经不在库里的行。这样的行解析不到任何东西，所以无法通过挂载列出、移动或删除。之所以保留而不直接丢弃，是因为之后修复并恢复该 release 时，它会回到你放置它的位置。在这个页面出现之前，没有办法清理这类行。**Clear all dangling rows** 可以一次性全部清掉。

sidecar 也会被列出。那些**已经没有任何东西对其负责**的 sidecar 会单独列出并计数。它们相当于 sidecar 的 dangling 行：一个 `.nfo` 或海报文件，写在一个已经离开库的 release 旁边，或者写在一个 placement 已被遗忘的文件夹里。它们仍然会被提供访问，因为真实文件是 `__magic__` 路径解析的最后一步，而上面已经没有任何东西再占用这个名字。失去的只是它们被放在那里的理由。zurg 从不自动清理这类文件：被删除的 release 旁边留下的文件仍然是你的，而修复并恢复该 release 时，会重新为该文件夹建立对应关系。你通过挂载而不是 zurg 为 sidecar 自己建的目录，在这里也会以同样的方式显示，因为这样做同样不会留下任何行。

从页面删除 sidecar 会真的删除文件，效果和通过挂载执行 `DELETE` 一样。每个按钮都会更新挂载为相关路径缓存的内容，因为挂载会缓存目录列表 12 小时，并且关闭了轮询。

如果启用了 SABnzbd 端点，页面还会列出它接收到的任务：客户端识别每个任务所用的 id、它的分类、release 是否已经进入库，以及它完成后要导入的文件夹。Sonarr 和 Radarr 会自行移除它们自己的任务。如果某个 Failed 或 Stuck 任务无论如何都不会被它们移除，可以在这个页面上清除。这种情况通常发生在 zurg 已经不再是它们的下载客户端时。参见 [sabnzbd.md](../guides/sonarr-radarr.md)。

`magic:` 和 `sabnzbd:` 两个配置块都可以在 [配置页面](#sabnzbd-the-download-client-sonarr-and-radarr-see) 中完整编辑，并且都标注了 **Restart Required**，这正是它的字面含义：提供 `__magic__` 的路由和 SABnzbd 端点是在启动时根据这些值一次性注册的。启用其中任何一个都会把设置写入 `config.yml`，但不会改变正在响应请求的这次运行。`__magic__` 页面也会明确说明这一点，而不是渲染一个空的命名空间。

### `sabnzbd`，即 Sonarr 和 Radarr 看到的下载客户端 {#sabnzbd-the-download-client-sonarr-and-radarr-see}

zurg 可以像 SABnzbd 一样应答 Sonarr 和 Radarr。它们把一个 NZB 交给它，它会把文件写入 `nzbs/`，供 Usenet 后端使用。一旦该发行版进入库中，任务就会显示 **Completed**，并在 `__magic__/__all__` 下生成一个任务文件夹，供导入使用。导入时无需下载任何内容：\*arr 会在挂载点内重命名文件，这只是 `__magic__` 表中的一行记录。

两部分都需要才能发挥作用：需要一个 `nzb` provider 或 `torbox_nzb` provider 来接收 NZB，还需要 `magic.enabled` 来提供导入的来源。默认关闭，需要时才开启。完整设置（包括在 \*arr 中要填写什么）见 [docs/sabnzbd.md](../guides/sonarr-radarr.md)。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `sabnzbd.enabled` | bool | `false` | 在 `/api` 和 `/sabnzbd/api` 上注册端点。关闭时，这两个路由都不存在。 |
| `sabnzbd.api_key` | string | 自动生成 | 端点唯一的访问控制。Sonarr 和 Radarr 不发送基础认证，因此这些路由不在认证范围内，由此密钥代替认证。若在启用该模块时留空，zurg 会生成一个密钥，保存在 `data/sabnzbd-apikey` 中以便重启后保留，并在启动时记录一次。 |
| `sabnzbd.categories` | list | `[tv, movies]` | 报告给客户端的分类。它们都指向同一个目录，所以这个选项只是为了避免客户端警告找不到分类。请添加你在 \*arr 中配置的任何分类。`*` 始终也会被报告。 |
| `sabnzbd.history_limit` | int | `60` | Sonarr 和 Radarr 读取的历史记录条数。zurg 会将超出此数量的已完成任务保留在队列中，直到出现空位。空位会在客户端清除某条记录时出现，或在有任务等待时某条记录已超过十分钟未被清除时出现。如果你调高了 `DownloadClientHistoryLimit`，请与之保持一致。`0` 表示保留它们的默认值 60。 |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__/__all__` | 报告给客户端的已完成目录。它必须是**\*arr** 看到的路径：当 \*arr 运行在容器中且将库挂载到其他位置时，它与 zurg 自身的路径不同。它还必须与根文件夹位于同一个卷中，否则每次导入都会变成复制。参见 [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。 |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

API 密钥是唯一的认证方式，因此请像对待 zurg 的其他端口一样对待此端点：仅在可信网络上使用，或放在某种防护之后。无法对它使用基础认证，因为客户端从不发送它；而 401 会以 "unable to connect" 的形式告知用户，而不是认证失败。

### `qbittorrent`，即 Sonarr 和 Radarr 看到的种子下载客户端 {#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see}

zurg 可以像 qBittorrent 一样响应 Sonarr 和 Radarr。它们会把磁力链接或 `.torrent` 文件交给 zurg，zurg 再把 info hash 添加到某个 debrid 账户中。资源进入库之后，该 torrent 会显示 **finished**，并在 `__magic__/__all__` 下生成一个可供导入的文件夹。导入时无需下载任何内容。\*arr 会在挂载点内重命名文件，这一步会在 `__magic__` 表中生成一行记录。

要让它真正好用，需要两部分配合。能够添加 torrent 的账户负责读取磁力链接，而 `magic.enabled` 则为 \*arr 提供一个导入位置。该功能默认关闭，需要时再开启。完整的设置步骤（包括在 \*arr 中需要填写的内容）见 [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md)。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `qbittorrent.enabled` | bool | `false` | 在 `/api/v2` 和 `/qbittorrent/api/v2` 上注册端点。关闭时，这两个路由都不存在。 |
| `qbittorrent.api_key` | string | generated | 端点唯一的访问控制。当客户端的 **API Key** 字段已设置时，它们会以 Bearer 令牌的形式发送该密钥；当该字段未设置时，则在 `auth/login` 中将其作为密码提交。如果功能已启用但此项为空，zurg 会生成一个密钥，保存到 `data/qbittorrent-apikey` 中以便重启后保留，并在启动时记录一次到日志中。 |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | 报告给客户端的分类，即 \*arr 默认自带的两个分类。它们都指向同一个目录，因此设置此项只是为了避免客户端提示找不到某个分类。 |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__/__all__` | 报告给客户端的保存路径，也是它们导入时所用的所有文件夹的父目录。它必须是 **\*arr** 所看到的路径，当 \*arr 运行在容器中且库挂载在其他位置时，这个路径就与 zurg 自身的路径不同。它还必须与根文件夹位于同一个卷中，否则每次导入都会变成复制；参见 [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。如果你同时运行两个端点，请将 `sabnzbd.complete_dir` 设为相同的值。 |
| `qbittorrent.download_timeout_mins` | int | `15` | 一次抓取在无任何进展（阶段没有变化，进度也没有上升）的情况下可以持续多久，超过后该账户会被放弃，并尝试下一个接受 torrent 的账户。`0` 表示仅缓存模式：只有当账户已持有该内容时才接受抓取，否则直接在添加阶段拒绝，这是 Sonarr 和 Radarr 唯一会据此采取行动的拒绝情况。负数则永不放弃。参见 [超时与仅缓存模式](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode)。 |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

15 分钟是实测得出的数值，而不是随意选定的。AllDebrid 会把一个健康的任务放进它自己的队列，此时所有计数都为零，还没有传输任何字节。两次测试中，任务都卡在这一状态，分别等待了 580 秒和 622 秒。相关记录见 [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md)。

一次抓取会交给哪个账户，由 [`add_torrents`](#accounts) 和 `providers:` 列表的顺序决定。如果某次抓取超时，或被某个账户放弃，那么在尝试下一个账户之前，会先从该账户中删除它。只有 zurg 为该次抓取自行添加、且从未完成的实例，才会成为候选。除此之外，此端点返回的其他任何内容都不会从 debrid 账户中删除任何东西。

API key 是身份验证的全部内容。请像对待 zurg 端口的其他部分一样对待此端点：将它放在可信任的网络中，或置于可信任的网络之后。此端点不能使用 Basic auth。客户端从不发送它，并且会把 401 视为硬性的身份验证失败，因此不会重试。

### `stremio` 插件 {#the-stremio-addon}

zurg 可以作为一个 Stremio 插件使用，它会搜索你自己的 Newznab 索引站，并通过 Usenet 后端播放。它需要一个 NZB 账号，即 `nzb` 或 [`torbox_nzb`](../providers/torbox-nzb.md)，还需要至少一个索引站。使用 `torbox_nzb` 时，如果没有其他 NZB 帖子在排队，TorBox 已经缓存好的版本会在插件的等待时间内开始播放。没缓存的版本则必须先在 TorBox 上下载完成，这比播放器的等待时间要长。该功能默认关闭，需要时再手动开启。设置方法和播放时的具体流程见 [stremio.md](../guides/stremio.md)。

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stremio.enabled` | bool | `false` | 在 `/stremio/` 下注册插件路由。关闭时这些路由返回 404。 |
| `stremio.token` | string | 自动生成 | 用于保护所有插件路由的路径段，它就是全部的授权依据。留空时 zurg 会自动生成一个，并保存在 `data/stremio-token` 中。 |
| `stremio.indexers` | list | `[]` | 要搜索的 Newznab 端点。每个端点需要 `name`、`url` 和 `api_key`，可选 `api_path`。 |
| `stremio.max_results` | int | `10` | 排序后，每个分辨率保留多少个版本。上限按分辨率分别计算。每个档位会从最大的版本到最小的版本之间均匀保留。`0` 表示使用默认值。 |
| `stremio.search_limit` | int | `100` | 每次搜索时，每个索引站最多请求多少个版本。其他所有限制都是从这里请求到的结果中做选择，所以它决定了整个返回结果的上限。`0` 表示使用默认值。 |
| `stremio.max_size_gb` | int | `0` | 在排序前丢弃超过此大小的版本，适用于无法播放 remux 的播放器。默认值 `0` 表示不丢弃任何版本。没有标明大小的版本会保留。 |
| `stremio.cache_hours` | int | `24` | 当完整结果达到五个或以上时，它会在 `data/stremio-cache` 中保存多久，之后才会重新向索引站请求。结果较少的会保存更短的时间。空结果从不保存。`0` 表示使用默认值。 |

### 媒体分析 {#media-analysis}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | 设为 true 时，zurg 会对每个新添加的种子自动运行 ffprobe，提取媒体元数据（分辨率、编解码器、时长、音轨和字幕轨道）。这些元数据是基于标签的目录过滤器（如 `zurg_4k`、`zurg_aud_eng` 和时长分级）的基础。如果你不使用基于标签的过滤器，或者想减少新增内容时的 CPU 占用，可以关闭它。 |
| `ffprobe_binary` | string | `"ffprobe"` | ffprobe 可执行文件的路径。只有在 ffprobe 不在系统 PATH 中时才需要设置。用于媒体分析。 |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. 健康检查与修复（自动化） {#4-health--repairs-automation}

“设置好就不用管”部分。这里控制 zurg 如何通过自动检测和修复损坏的种子来保持你的库健康。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `enable_repair` | bool | `true` | 启用自动种子修复。未设置时即为启用。当某个种子变得不可用（例如从 RD 缓存中被移除）时，zurg 会尝试找到并添加替代种子。在 AllDebrid 上，它还会重启因无做种者或 tracker 错误等二次尝试可以修复的原因而失败的磁力链接，而不是让它一直处于失败状态。**重要：** 为避免冲突，只能有一个 zurg 实例启用修复。如果这个选项和 `delete_error_torrents` 都关闭，zurg 会保持失败的种子在账户中原样不动，只把它们记录到日志里。 |
| `repair_every_mins` | int | `60` | zurg 扫描需要修复的损坏种子的频率（以分钟为单位）。数值越小，问题发现得越快，但 API 用量也会越高。 |
| `repair_timeout_mins` | int | `30` | 等待修复操作完成的最长时间（以分钟为单位）。如果修复耗时超过这个值，该种子会被标记为损坏，并在下一个修复周期之前被跳过。 |
| `stalled_download_mins` | int | `10` | 下载中的种子被视为停滞之前的最短时间（以分钟为单位）。实际阈值为 `max(GB_downloaded, stalled_download_mins)`，因此大文件会自动获得更多时间。对于速度慢或做种者少的种子（例如公共 tracker 上的种子），如果需要更多时间才能下完，可以调大这个值。 |
| `restrict_repair_to_cached` | bool | `false` | 设为 true 时，zurg 只会使用 Real-Debrid 上已经缓存的种子进行修复。这样修复更快（不用等下载），但如果没有可用的缓存替代种子，修复可能会失败。设为 false 时，zurg 可以添加需要时间下载的未缓存种子。 |
| `only_full_torrent_repair` | bool | `false` | 设为 true 时，修复会以原始文件选择重新插入整个种子，否则放弃。如果这第一步失败，种子会立即被标记为损坏，并跳过原本会接着尝试的压缩包和逐文件修复策略。 |
| `check_for_changes_every_secs` | int | `15` | zurg 轮询 Real-Debrid 以检测库变化（新种子、被移除的种子、状态变化）的频率（以秒为单位）。数值越小，媒体服务器中的更新越快，但 API 调用也越多。 |
| `library_resync_every_mins` | int | `10` | 变化检查多久从完整列表重建一次，而不是使用轻量探测。它是一道安全网，用来捕获探测可能漏掉的偏差。它并不是 zurg 轮询的频率。Real-Debrid 走自己的路径，会忽略这个选项。 |
| `library_detail` | string | `resident` | `resident` 会把文件详情保留在内存中。`lazy` 会释放闲置的详情。`auto` 只在持续的内存压力下才释放闲置的详情。所有提供商共用这个实例级策略。需要重启。参见 [库详情](#library-detail)。 |
| `library_detail_idle_secs` | int | `300` | 在 `lazy` 或 `auto` 模式下，某个表在多久没有被读取详情后才可能被释放（最短时间）。清理任务每 30 秒运行一次。`resident` 模式下此项被忽略；值为零或无效时使用 300。需要重启。 |
| `downloads_every_mins` | int | `720` | zurg 重新获取你的 RD 下载（解除限制的链接、文件存储链接）并挂载它们的频率（以分钟为单位）。这些是来自 RD 的非种子下载。 |
| `delete_error_torrents` | bool | `false` | 设为 true 时，zurg 会自动从 RD 删除处于错误状态的种子（例如无法下载的失效种子）。这能让你的 RD 库保持整洁，但种子会被永久删除。在 AllDebrid 上，如果失败的磁力链接可以通过二次尝试修复，就会重启它而不是删除，即使修复已关闭也是如此；只有重启也没有帮助时才会删除。 |
| `on_library_update` | string | `""` | zurg 检测到库变化时执行的 shell 命令。每个发生变化的目录路径会作为参数传入。常用于触发 Plex/Jellyfin 对特定文件夹进行媒体库扫描，以加快更新。 |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
library_detail: resident
library_detail_idle_secs: 300
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

### 跨账户修复 {#repairing-across-accounts}

其他所有修复策略都是把一个版本重新添加回它原来所在的账户，只要该账户还能提供这些内容，这样做就是对的。但有一种情况下这样做是错的。

各个服务都有各自独立的缓存。Real-Debrid 已经清除的版本，或者它只看文件名就拒绝的版本，可能正好在 AllDebrid 上处于缓存中，而且信息哈希相同。版本本身没有问题，只是那个账户出了问题。

所以，当一个版本被所有持有它的账户放弃后，zurg 会把它提供给配置中*没有*持有它的其他账户，顺序按照你 `providers` 配置块中的出现顺序。第一个已经缓存了它的账户会接收它，zurg 会把这个账户列出来，然后这个版本就会像其他多账户版本一样获得第二份副本：拥有自己的文件 ID、自己的链接，并在两个账户之间进行读取故障转移。该条目的失败判定会在存在可修复副本后自动清除。

这里没有设置项。添加第二个账户本身就是决定，zurg 已经会列出它、从它提供服务，并把读取故障转移到它；询问它某个第一个账户无法提供的版本，也只是同一套机制的延伸。它和其他修复一样遵循 `enable_repair`。

版本上的修复按钮也会这样做，而且顺序正确：它会先像以前一样重试持有该版本的账户，只有这次尝试失败时，才会把版本提供给其他账户。即使修复扫描被完全关闭，这条路径仍然有效。

防止它变成无限添加循环的，是这种提供方式本身的形态，而不是某个开关：

- **账户只会收到它本来就已持有的内容。** 这次提供是一次添加，如果该账户没有在十五秒内完成，就会被撤回并删除。如果某个账户需要从 swarm 去获取该版本，它会保持原样，不会消耗任何传输额度。这是修复，不是重新下载。`restrict_repair_to_cached` 不会控制这一点，代码中也从不读取它：该配置项针对的是账户修复自己的副本，而这条路径无论它如何设置，都只限于缓存内容。
- **只针对没有任何账户能提供的版本。** 能正常播放的版本不会被复制，修复还没有放弃的版本也不会。
- **对于拒绝提供的账户，询问会越来越少。** 出现一次未命中后，等待时间从一天开始，每多一次未命中就翻一倍，最长约两周。如果一个版本只是这周缺少缓存，几天内就会再次被找到；如果它已经永久消失，就会固定变成每两周问一次。如果没有这种递减，始终开启就意味着每个失效版本在每个账户上每天都要添加一次，而且永远如此。
- **每次扫描最多处理十个版本**，因此添加第二个账户后的第一次扫描会在几个小时内逐步处理积压，而不是一次性集中爆发。

如果某个账户已经持有该版本的副本，即使那份副本已经损坏，也不会再收到同一版本的第二个实例：修复自己的策略负责管理这个账户。在 Real-Debrid 上，重复添加根本不会真正下载。键不是 bittorrent 信息哈希的版本（Usenet 后端就是用这种方式标识自己的版本）则永远不会提供给任何账户。

这是 zurg 唯一一处会在未被请求的情况下，向内容会过期的账户添加内容的地方。修复本身不会定时把版本重新添加到这类账户上，因为重新获取服务已经主动移除的内容，正是这些服务所称的滥用行为。缓存提供与此不同：不会获取任何内容，也不会消耗额度，而且被声明的内容本来就已经在服务的缓存里，因为是别人把它放进去的。

### 库详情 {#library-detail}

**`library_detail: resident` 仍然是默认值。** 你可以在仪表盘的配置页面或 `config.yml` 中选择模式和空闲时间。这两个设置都要重启 zurg 后才会生效，保存它们不会让正在运行的库部分切换。该策略适用于实例中的每个提供方。

| 模式 | 行为 | 取舍 |
|---|---|---|
| `resident` | 把每个版本的文件详情都保存在内存中。 | 访问可预测，不需要重新加载详情；占用的内存最多。 |
| `lazy` | 在 `library_detail_idle_secs` 时间内未被使用后，释放其详情。 | 即使内存充足，也能减少空闲时的内存占用；访问冷数据时需要重新加载。 |
| `auto` | 内存充足时保留详情；持续承压时，释放最久未使用的空闲详情表。 | 能根据运行状况调整；需要额外的压力监控，重新加载的延迟也不太好预测。 |

在每种模式下，名称、大小、重命名和可见性都可以用于列表显示。打开或修复文件时，会按需重建已释放的详情。压力结束后，`auto` 不会主动重新加载整个库：详情会随着使用逐步回到内存中，并一直保留，直到压力和空闲时间窗口again允许再次释放。

#### 自动压力检测 {#automatic-pressure-detection}

`auto` 每 30 秒采样一次。在已测得的预算中，如果两次读数至少间隔 30 秒，且都达到或超过 **90%**，就开始驱逐。每次清理最多驱逐 **128 个空闲表**，分批进行。驱逐会一直持续到使用率降到 **80%** 或以下，然后至少暂停一分钟，之后才会考虑新的一轮。短暂的峰值不会触发驱逐。配置的空闲时间窗口始终生效。

决策以可用的最严格读数为准：

- **Host memory:** 宿主机内存：总量减去可用量，包括操作系统估算的可回收缓存。文件系统缓存被占满本身并不代表内存不足。

- **Linux containers and service limits:** Linux 容器和服务限制：cgroup v2 的 `memory.max` 和 `memory.high`，或 v1 的 `memory.limit_in_bytes`，并加上每个可见祖先 cgroup 自身的使用量。冷文件缓存会被扣除。容器限制会在运行时重新读取；私有 cgroup 命名空间可能会隐藏可见根节点之上的限制。

- **An explicit runtime budget:** 明确的运行时预算：正数的 `memory_limit_mb`（单位 MiB）与 Go 管理的内存进行比较。如果设置了 `GOMEMLIMIT`，则它优先；`GOMEMLIMIT=off` 会禁用这一特定信号。宿主机和容器的内存压力仍然生效。由 Usenet 缓存推算出的自动 Go 上限会被忽略，因为它会随活动堆增长而上升，并不能反映可用内存。

启用 `auto` 不需要额外的预算：

```yaml
library_detail: auto
library_detail_idle_secs: 300
# Optional explicit Go runtime budget, also used by the collector:
# memory_limit_mb: 1024
```

如果没有可用的测量值，自动驱逐会暂停。

这是一种逐步的内存优化，**不是硬性的内存上限**：正在使用的文件、未保存的更改、恢复快照以及其他缓存可能占据大部分内存，而突发的内存分配也可能快过清理程序。`memory_limit_mb` 仍然只是一个软性的回收器限制；如果把它设得低于实际的活动数据量，可能会导致过于频繁的垃圾回收。

#### 数据完整性与成本 {#data-integrity-and-cost}

驱逐时会保留一份**压缩的恢复快照**，同时也保留现有的 `data/*.zurgtorrent` 转储文件。磁盘重新加载的数据必须与该快照一致。如果转储文件丢失、损坏或被替换，zurg 会恢复快照并让该发布保持驻留，然后重试保存恢复后的数据。`auto` 模式在内存压力结束后，也会用单独的、有上限的保存流程重试空闲的脏表。文件写入和状态变更会立即恢复所有权，包括流通过指针在驱逐期间进行的写入。保存失败时，变更会保持驻留并标记为脏数据；重叠的写入不会被较早的保存确认。只有保存成功，变更才能在进程退出后保留下来。

在搭载 Apple Silicon 芯片的 Mac 上，使用 Go 1.26.4 进行测量。每种形态使用 500 个发布，经过转换和持久化路径，包括恢复快照。

| 形态 | 驻留每条目字节数 | 惰性每条目字节数 | 降幅 | 平均重建耗时 |
|---|---:|---:|---:|---:|
| Real-Debrid 电影，3 个文件 | 3,662 | 2,845 | 22% | 88 µs |
| Real-Debrid 整季合集，24 个文件 | 15,670 | 7,366 | 53% | 371 µs |
| TorBox，2 个文件 | 3,019 | 2,680 | 11% | 56 µs |
| AllDebrid，1 个文件 | 2,580 | 2,516 | 2% | 55 µs |
| RAR 分卷集，7 卷 | 5,343 | 3,303 | 38% | 109 µs |

这些是每个发布保留的堆内存数据，而不是整个进程的 RSS。重建时读取的是最近写入的本地文件；冷存储或远程存储可能耗时更长。想要稳定的空闲回收就选 `lazy`，只在内存压力下回收就选 `auto`。当可预测的访问比节省内存更重要时，保留 `resident`。小型发布节省的内存很少，而恢复快照是有意花费内存来保护数据的。这些测量数据描述的是 `lazy` 和 `auto` 两种模式下被驱逐的条目；自动模式在任意时刻可能保留更多条目。

## 5. 网络与连接（技术） {#5-network--connectivity-technical}

基础设置，用于控制 zurg 如何绑定端口、进行身份验证以及连接网络。

### 服务器绑定 {#server-binding}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `host` | string | `"[::]"` | 要绑定的网络接口。`[::]` 表示监听所有接口（IPv4 和 IPv6）。如果只用 IPv4，就填 `0.0.0.0`；如果想把访问限制在某一个接口上，就填那个接口的具体 IP。 |
| `port` | string | `"9999"` | zurg 监听的端口。设置了 `PORT` 环境变量后会覆盖这个值，在容器化部署时很方便。 |

```yaml
host: "[::]"
port: 9999
```

### 预热连接 {#warm-connections}

打开一个到 debrid 服务的连接成本很高，而用它传输数据几乎没有成本。根据 2026-08-29 从一台实际主机上的测量，新建一个到 Real-Debrid 下载主机的连接，在真正请求文件中的任何一个字节之前，要先花一次 TCP 往返，再加上 68–85 毫秒的 TLS 握手。而 zurg 的 HTTP 传输层在读取真正需要数据之前什么都不会打开，并且在空闲 90 秒后会主动丢弃未使用的连接。除了非常繁忙的库，在一段安静时间之后的那次读取，都要在观众自己的路径上付出这笔代价。

预热下限会把这笔代价移出观众的路径：每个账户会保持指定数量的连接，提前拨号并完成握手，这样读取请求到达时，传输层手边就已经有一个可用的连接。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `warm_connections` | int | *(未设置)* | 所有未自行设置该项的账户的预热下限。未设置时，每个后端使用其默认值：debrid 账户每个主机 1 个，news 账户每个账户 2 个。`-1` 会在所有地方关闭预热。账户自己的 `warm_connections` 始终优先，包括优先于全局的 `-1`。 |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**预热的收益取决于主机，对 debrid 服务来说，比听起来要小。** 一个没有发送任何数据的连接，是这些服务最先回收的，而且回收得很快。根据 2026-08-29 从实际主机上的计时，保持一个静默连接打开，等待对方把它断开：

| 主机 | 静默连接 | 处理完一次请求之后 |
|---|---|---|
| Real-Debrid 下载主机 | 30 秒后关闭 | 立即关闭 |
| `api.alldebrid.com` | 15 秒后关闭 | 4 分钟后仍保持打开 |
| `api.torbox.app` | 15 秒后关闭 | 4 分钟后仍保持打开 |
| `api.real-debrid.com` | 4 秒后关闭 | 5 秒后关闭 |

所以预热下限只对下载主机比较值得，对其他地方作用不大。Real-Debrid 的 API 根本无法预热：任何下限都赶不上 4 秒就挂断的机制，除非制造流量来保持连接存活，而 zurg 不会这么做。

与其凭假设，**预热下限会自己测量**：它每 15 秒淘汰自己的连接，并在淘汰时检查每个连接是否仍然存活。如果某个主机总是在读取能使用连接之前就把它们关掉，预热就会放弃该主机，它的读取会像以前一样拨号。无需为此做任何配置，而且冷清库中没有被读取的下限也不会被误判。

在提高该值之前，还有两点值得了解：

- **debrid 账户的下限按主机计算，news 账户的下限按账户计算。** debrid 账户会通过多个主机访问，包括一个 API 主机名，以及每个链接对应的下载主机。具体是哪些主机，要等链接生成之后才能知道，所以被预热的主机是账户实际用过的那些。同时最多保留 16 个，超过 10 分钟未使用的会被淘汰。news 账户只有一个主机，在配置中指定，并在套餐允许的时间内一直保持会话，这也是它的下限能够稳定发挥作用的原因。参见 [Usenet](../guides/usenet.md)。
- **预热连接是真实的连接，会计入服务商限制的每主机上限**：Real-Debrid 和 AllDebrid 为 32，TorBox 为 20。这也是 debrid 下限上限为 4 的原因：这个大小基本不会占用上限，而更大的下限会把这些名额浪费在没有传输任何数据的套接字上。

当设置了 `proxy` 时，预热下限会被禁用。HTTP 或 SOCKS 代理会让 zurg 连接代理而不是目标主机，代理另一端没有什么值得保持打开的东西。

### 身份验证与代理 {#authentication--proxy}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `username` | string | `""` | HTTP basic auth 用户名。与 `password` 一起设置后，所有发往 zurg 的请求（仪表盘、WebDAV、API）都需要认证。留空则关闭认证。 |
| `password` | string | `""` | HTTP basic auth 密码。必须与 `username` 一起设置。 |
| `proxy` | string | `""` | 让 zurg 的所有出站网络流量都走代理。支持 `http://`、`https://` 和 `socks5://` 协议。如果你的网络运营商屏蔽或限速 Real-Debrid 流量，这个选项会很有用。示例：`socks5://user:pass@host:port`。此键为空时，会使用 `PROXY` 环境变量。 |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Rclone 设置 {#rclone-settings}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | 设为 true 时，zurg 会自动管理一个 rclone 挂载。这样你就不用单独运行 rclone 了，zurg 会按需启动、监控并重启 rclone 进程。挂载点使用 `mount_path`。 |
| `rclone_binary` | string | `"rclone"` | rclone 可执行文件的路径。只有当 rclone 不在系统 PATH 里时才需要设置。 |
| `rclone_extra_args` | list | `[]` | 传给 rclone 挂载命令的额外命令行参数。如果想覆盖 zurg 基准测试优化过的 VFS 默认值，就在这里设置（见下表）。每一项是一个参数字符串。RC 设置以及 `--union-*`/`--webdav-*` 后端参数是不允许的：这些由 zurg 自己构造，如果你加了这些参数，就会覆盖 zurg 生成的配置（`union_writable` 就不再准确描述挂载了）。 |
| `mount_read_only` | bool | `false` | 设为 true 时，挂载会带上 rclone 的 `--read-only` 启动，这样内核会在写操作到达 zurg 之前就直接拒绝。除此之外，没有任何东西能拦住挂载上的 DELETE，所以这是唯一能拒绝删除的办法。不过它不能拦住直接访问 WebDAV 端点的客户端。它还能防止误写入挂载在本地联合上游里的内容。如果想按参数单独覆盖，可以用 `rclone_extra_args: ["--read-only=false"]`。 |
| `rclone_cache_reclaim` | bool | `true` | zurg 是否要删除之前挂载配置留下的 VFS 缓存目录。rclone 会根据远端名字来命名缓存，而这个名字是由联合上游计算哈希得出的，上游里包含 `data/local` 的绝对路径。所以只要移动了 zurg 目录，或者切换了 `union_writable`，缓存名字就会变，旧的目录就会被遗留在没有任何上限统计、也没有任何清理程序会去处理的地方。挂载启动时，zurg 会问正在运行的 rclone 当前用的是哪个缓存目录，然后删除其余的，并记录释放了多少空间。只有当当前使用的目录确实在 rclone 说的位置时才会执行，而且当 `rclone_extra_args` 设置了 `--cache-dir` 时会完全跳过这一步。如果想保留所有遗留目录，就设为 `false`。参见 [挂载使用的磁盘](#disk-the-mount-uses)。 |
| `union_writable` | string | `"local"` | 嵌入式挂载的联合中，新建的文件写到哪一边。`local` 是默认值，会直接写到本地上游（`data/local`），zurg 完全不知道。`server` 会把 WebDAV 上游排在最前面，这样创建请求就会先到达 zurg：在 `__magic__` 之外会被拒绝，在 `__magic__` 之内则会写成有大小上限的 sidecar 文件。被拒绝的写入永远不会落到磁盘上。rclone 的 VFS 缓存会先接收它，然后按退避策略重试上传，所以它受缓存上限约束，并且可以在 `logs/rclone.log` 里看到。如果用 `local` 的顺序，这些字节就会无限制地写进 `data/local`。在 `server` 模式下我们测到一个需要注意的问题：通过挂载重命名 sidecar 文件时可能会返回错误（这个文件在两个上游上都能看到，所以 rclone 会对两边都执行移动）。不过在 `__magic__` 内发布移动，也就是 \*arr 的导入路径，是不受影响的。切换到 `server` 只会改变*新*文件的创建位置，别的都不变：在 `local` 顺序下已经写进 `data/local` 的内容会保留，直到你自己删除。zurg 启动时打印的那一行会说明当前实际生效的模式（`new files go to zurg over WebDAV (union_writable: server)`），所以应该看这行来确认，而不是看有没有 `data/local` 这个路径。无论哪种顺序，这个路径都是联合的一部分。 |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
rclone_cache_reclaim: true
union_writable: "local"
```

#### 基于基准测试的默认值 {#benchmark-optimized-defaults}

zurg 使用经过基准测试的 rclone VFS 设置，针对流媒体性能做了优化：

| 设置 | 默认值 | 原因 |
|---------|---------|-----|
| `--buffer-size` | 256M | 大缓冲区，让流媒体播放更流畅 |
| `--vfs-read-chunk-size` | 32M | 全新读取时的加速过程会持续多久。第一个块按这个大小获取，之后逐步翻倍。如果是 4M，从冷偏移量开始读取时，大部分时间都会低于线路速率。这是请求大小，不是强制传输。当读取端停止读取时，rclone 仍会停止拉取。 |
| `--vfs-read-chunk-size-limit` | 512M | 上面的翻倍过程在此停止。分块默认开启，所以这是翻倍的上限，而不是需要覆盖参数才会启用的设置。 |
| `--vfs-read-ahead` | 128M | 在缓冲区和带宽效率之间取得平衡 |
| `--max-read-ahead` | 1M | 较小的 FUSE 内核缓冲区可以减少小读取。Windows 上不传递此参数。 |
| `--vfs-read-wait` | 5ms | 关键：值越高，性能下降越严重 |
| `--vfs-cache-mode` | full | 完全缓存，性能最佳。对于通过共享访问挂载的播放器，这并不总是合适的取舍，参见 [缓存的代价超过收益的时候](#when-the-cache-costs-more-than-it-buys)。 |
| `--vfs-cache-max-size` | 256G | 磁盘上 VFS 缓存的硬性上限。这不是配置项，请使用 `rclone_extra_args` 覆盖它。 |
| `--vfs-cache-min-free-space` | 10G | 在缓存磁盘写满之前停止缓存 |
| `--vfs-cache-max-age` | 72h | 未被访问的缓存文件保留多久。关键词是"未被访问"，而媒体服务器几乎不会让任何文件保持未被访问状态，参见 [挂载占用的磁盘空间](#disk-the-mount-uses)。 |
| `--vfs-cache-poll-interval` | 1m | 缓存更新响应迅速 |
| `--vfs-fast-fingerprint` | on | 不对文件进行哈希即可识别文件 |
| `--dir-cache-time` | 12h | 目录列表会保留数小时。当资源库发生变化时，zurg 会通过 RC API 清除受影响的条目，因此媒体服务器扫描时缓存依然保持热度。 |
| `--attr-timeout` | 60s | 资源库文件是不可变的，状态变化时会显式清除受影响的条目。设置上限，确保过时的大小不会超过一次扫描周期。 |
| `--poll-interval` | 0 | 变更轮询由 zurg 负责，而不是 rclone |
| `--timeout` | 5m | IO 空闲超时 |
| `--no-modtime` / `--no-checksum` | on | 对 debrid 资源库来说，这两项都没有意义，而且请求它们会增加请求次数 |
| `--async-read` | rclone 默认值（on），不传递 | zurg 不会在命令行中设置此参数，rclone 默认将其设为 true。因此挂载是异步读取的，本页所有数据都是在这种模式下测得的。以前有一个调优字段声称可以禁用它，但实际上它只是追加了这个裸参数，而这恰好就是它原本的默认值。要真正关闭它，请使用：`rclone_extra_args: ["--async-read=false"]`。 |
| `--low-level-retries` | 3 | rclone 的 VFS 下载器每次打开文件时已经会重启失败的读取十次，而每次重启又会被后端 pacer 重试这么多次。如果使用 rclone 默认的 10，那么对于 zurg 刻意返回 503 的文件，每次打开就会产生 100 次请求。 |
| `--retries` | 1 | 整个命令的重试预算。对于永不退出的挂载，它只会放大启动失败的影响。 |
| `--vfs-handle-caching` | 0，rclone 1.74+ 上为 on | rclone 1.74 开始在文件最后一次关闭后，将其下载器保持存活五秒。因此，访问一个文件会消耗五秒链路所能承载的流量，而不是实际读取的量。以 50 MB/s 的服务器为基准测试，一次 1 MiB 的读取拉取了 245–250 MiB，而不是 3–6 MiB；二十个文件的扫描从 80 MiB 增加到 4.2 GiB。这个宽限期是为 `serve nfs` 设计的，而 zurg 从不运行它。旧版 rclone 没有此参数，遇到未知参数会拒绝启动，因此 zurg 会先询问二进制文件的版本，低于 1.74 时不传递该参数。 |
| `--log-level` | NOTICE | rclone 自身的日志详细程度，始终传递 |
| `--cache-dir` | `data/rclone-cache` | 相对于工作目录解析 |
| `--log-file` | `logs/rclone.log` | 相对于工作目录解析 |

`--vfs-cache-max-size`、`--vfs-cache-min-free-space`、`--low-level-retries`、`--retries`、`--vfs-handle-caching`、`--log-level`、`--cache-dir` 和 `--log-file` 是 `internal/rclone/manager.go` 中的常量；其余各行都来自 `internal/rclone/tuning.go` 中的 `tuneVFSOptions`，包括 `--vfs-cache-max-age` 和 `--vfs-cache-poll-interval`，尽管名字如此。

### 挂载所用的磁盘 {#disk-the-mount-uses}

`--vfs-cache-mode full` 的意思是，通过挂载读取的文件会被**完整**下载到 `data/rclone-cache`，并且在播放结束后仍保留在那里。它不是一个播放结束就清空的临时缓冲区。如果放任不管，缓存会一直增长到 `--vfs-cache-max-size`（默认 **256G**），并一直停在那个大小。

本来应该有两个限制来约束缓存，但实际上只有一个起作用：

- `--vfs-cache-max-size`（256G）才是真正的上限。把它设置为不超过 `data/` 所在磁盘可用空间的一半。
- `--vfs-cache-max-age`（72h）会清除三天内没有被访问过的文件。rclone 是根据它自己在 `data/rclone-cache/vfsMeta/` 中的记录来计算的，而不是看文件系统的 atime，而且**任何读取媒体库的操作都会刷新它**。开启了计划任务的 Plex 服务器会在每晚的维护时段读取每一个已缓存的文件，所以在 2026-09-09，一个缓存里有 362 个文件的实例，每个文件的 ATime 都是同一天早上。几个月来没有任何文件因为过期被清除，以后也不会。所以不要指望按时间清理，要以大小上限为准来规划。

用 `rclone_extra_args` 降低上限：

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`--vfs-cache-min-free-space`（默认 10G）会在磁盘快要写满时停止缓存。如果磁盘与其他程序共用，请把它设置得远大于零。

要手动清空缓存，先停止 zurg，然后清空这两个目录：

```bash
rm -rf data/rclone-cache/vfs/* data/rclone-cache/vfsMeta/*
```

用 `du -sh data/rclone-cache` 来测量大小。未完全下载的条目是稀疏文件，所以按表观字节数计算的大小会比磁盘实际占用多得多。

#### 缓存何时弊大于利 {#when-the-cache-costs-more-than-it-buys}

`full` 是同一主机上媒体服务器的正确默认值：它只需读取一次文件，之后的所有读取都在本地完成。但对于通过文件共享读取挂载点的硬件播放器来说，它不一定适用。

在 `full` 模式下，读取的数据必须先写入磁盘，才能交给读取方。而且取回的是整个文件，而不是正在观看的那一部分。如果前面还有一层共享，那么一块磁盘既要给播放器提供数据，又要同时被 rclone 写入。有用户报告（2026-08-30），Zidoo 播放器读取 Windows 共享时，每部影片都会卡顿，直到关闭缓存后才恢复流畅。上面的机制只是对这份报告的合理推测，并非我们在这里测量得出的结论。因此，当直接读取的客户端在挂载点上卡顿，而同一主机上的媒体服务器播放正常时，可以先尝试这一点：

```yaml
rclone_extra_args:
  - "--vfs-cache-mode"
  - "off"
```

这样做也有实际代价。没有本地副本时，拖动进度会重新从提供商读取数据，第二次播放会再次下载整个文件，而且重启后什么都不会保留。另外，这也会改变挂载点接受写入的方式。因此，如果某台主机上的 \*arr 会通过挂载点导入文件，就不要改动默认设置，详见 [qbittorrent.md](../guides/sonarr-radarr-torrents.md)。

#### 移动后残留的缓存 {#caches-stranded-by-a-move}

rclone 会以它所缓存的 remote 命名缓存，而这个名字里带有该 remote 配置的哈希值。zurg 的 remote 是一个联合（union）remote，其上游中嵌入了 `data/local` 的绝对路径，因此配置一变，名字也会跟着变：

| Union 上游 | 缓存目录树 |
|---|---|
| `/home/you/zurg/data/local :webdav:` | `vfs/zurg{QaSkn}` |
| `:webdav: /home/you/zurg/data/local`（`union_writable: server`） | `vfs/zurg{HdSp7}` |
| `/other/root/data/local :webdav:`（zurg 被移动） | `vfs/zurg{Psid2}` |

rclone 只统计它正在使用的那棵目录树。旧名字下的目录树不计入任何上限，也不会被任何清理程序扫描，更不会被删除。因此，移动 zurg 目录，或者外接硬盘以新的挂载点重新出现，都会留下一整份缓存。多次这样移动之后，一个上限为 256G 的安装最终可能占用好几 TB。

zurg 会在挂载启动时回收这些目录树：它会询问正在运行的 rclone 当前使用的是哪棵目录树，删除其余的，并记录释放了多少空间。只有当当前使用的目录树确实位于 rclone 所报告的磁盘位置时，zurg 才会执行回收。如果 `rclone_extra_args` 中设置了 `--cache-dir`，zurg 会完全跳过这一步，因为你指定的目录可能与另一个 zurg 共享。若要关闭此功能并保留所有孤立的目录树，请设置 `rclone_cache_reclaim: false`。

平台还会额外添加四个参数，都只针对 Linux：`--allow-other` 和 `--allow-non-empty` 始终添加；只有在能读取当前运行用户的 id 时，才会添加 `--uid` 和 `--gid`。除 Windows 外，所有平台都会传入 `--max-read-ahead`；只要设置了 [`mount_read_only`](#rclone-settings)，就会传入 `--read-only`。

缓冲区和读取等待的数值是在 600 Mbps 的网络连接上通过基准测试确定的，冷缓存吞吐量约为 533 Mbps，首字节时间（TTFB）约为 235ms。之后我又在一台约 70 MB/s 的主机上重新测量了读取块大小。成对、交替测试的结果显示，在 Real-Debrid 上把它从 4M 改为 32M 后，吞吐量中位数从 49.1 提升到 56.5 MB/s；在 TorBox 上也呈现相同的变化趋势。

**使用 `rclone_extra_args` 覆盖默认值**：
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

RC 相关参数（`--rc`、`--rc-addr`，以及其他以 `rc-` 开头的参数）会被拒绝。zurg 自己会运行 rclone 的远程控制接口，用来在库内容变化时使 VFS 缓存失效。

### User Agent 与网络 {#user-agent--network}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `user_agent` | string | Chrome UA | 供提供方、索引器、ffprobe 和对外集成使用的共享 HTTP User-Agent。留空会恢复为通用浏览器默认值；手动填写的自定义值会原样发送。需要重启。参见 [对外请求标识](outbound-identity.md)。 |
| `omit_user_agent` | boolean | `false` | 不发送 HTTP User-Agent（ffprobe 会使用空值），优先级高于 `user_agent`。发往 GitHub 的请求仍会带上一个，因为 GitHub 会拒绝没有它的请求。需要重启。 |
| `outbound_client_name` | string | `"Media Client"` | 在支持的情况下，媒体服务器集成使用的产品或客户端名称。留空会恢复默认值。需要重启。 |
| `outbound_client_id` | string | `"media-client"` | 在支持的情况下，Plex 客户端标识符，包括媒体服务器集成的登录信息。留空会恢复默认值。需要重启。 |
| `outbound_client_version` | string | `"1.0"` | 在支持的情况下，媒体服务器集成使用的客户端版本。留空会恢复默认值。需要重启。 |
| `outbound_device_name` | string | `"Media Client"` | 在支持的情况下，媒体服务器集成使用的设备名称。留空会恢复默认值。需要重启。 |
| `outbound_device_id` | string | `"media-client"` | 在支持的情况下，媒体服务器集成使用的 Jellyfin/Emby 设备标识符。留空会恢复默认值。需要重启。 |
| `outbound_platform` | string | `"Desktop"` | 在支持的情况下，媒体服务器集成使用的 Plex 平台名称。留空会恢复默认值。需要重启。 |
| `force_ipv6` | bool | `false` | 强制 zurg 的所有网络测试和主机选择都使用 IPv6。如果你的网络连接 RD 服务器时 IPv6 更好，可以开启这个选项（例如某些网络服务商会限速 IPv4 但不限速 IPv6）。 |
| `unrestrict_ip` | string | `""` | 解除限制下载链接时传给 RD 的 IP 地址。在多网络环境中很有用，比如你想让下载链接绑定到特定 IP（例如 VPN 出口 IP），而不是 zurg 所在机器的 IP。 |
| `dns_servers` | list | `[]`（系统 DNS） | 用于解析 RD 主机名的自定义 DNS 服务器。如果系统 DNS 很慢、不稳定或被网络服务商屏蔽，这个选项会很有用。留空则使用系统解析器。必须包含端口（例如 `1.1.1.1:53`）。 |
| `network_test_every_mins` | int | `1440` | zurg 多久（以分钟为单位）重新运行一次网络延迟测试，以找到最快的 RD 下载服务器。这个测试无法关闭，`<= 0` 的值会被当作 `1440`。结果会缓存到 `data/network_test_results.json` 和 `data/network_test_timestamp`。重启时，如果缓存足够新，就会跳过网络测试。 |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### 公共 NZB 分享 {#public-nzb-sharing}

NZB 分享是接收者要去获取的一个 URL，所以只有当他们能访问这台主机时它才有用。而躲在家庭 NAT 后面的 zurg 无法保证这一点。这两个配置项会把该 URL 改为通过 [zrok](https://zrok.io) 服务转发：zurg 主动向外连接到该服务，并通过这条连接提供分享。因此**不会打开本地端口**，本机也不会多出任何新的监听服务。隧道里只传输两个带令牌校验的分享路由，从不传输控制面板，也从不传输媒体库。

两个值都为空，并且 `data/zrok` 下没有已启用的环境时，分享保持在本机已有的网络上，不会连接到任何地方，这是默认行为。注意后半句：一旦某个环境*已经*启用，即使 `zrok_account_token` 为空，也不再意味着仅限本地。因为启用这一步会打开公开分享，而且这个设置会被保存下来。要关闭公开分享，需要删除 `data/zrok`。

无论哪种方式，创建、提供和撤销分享的操作都一样。路径中的分享令牌就是本地 URL 和公开 URL 的授权凭证。

公开 URL 在重启后依然有效：zurg 会查找服务端已有的分享并重新关联，而不是重新创建。但重新启用后就保留不了了：新环境会得到新的分享，旧 URL 将失效。删除 `data/zrok` 时会这样，如果保存在其中的身份丢失或无法读取，也会这样，因为重新启用是唯一的恢复方式。

手动删除 `data/zrok` 并不会把该环境及其下的分享从 zrok 账户中注销。负责释放它们的身份文件已经被你删掉了，所以如果这些残留会造成困扰，请到 zrok 控制台手动清理。这也不是临时关闭分享的方法：正在运行的 zurg 仍保持着它已经在提供服务的连接，所以旧 URL 会一直可用，直到进程重启。zurg 在替换环境时会自行释放旧环境。如果它无法连接服务来完成释放，或者在磁盘上找到了无法读取的文件，它会拒绝替换。因为在这种情况下覆盖启用，会让每次重启都丢弃一个仍在运行的环境。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `zrok_account_token` | string | `""` | 用于开启公开分享的 zrok 启用令牌。托管服务可以在 [myzrok.io](https://myzrok.io) 免费获取；如果你自建了控制器，则从自己的控制器获取。**仅限首次启用**需要它：启用时会兑换一次该令牌，并把它与环境身份一起保存到 `data/zrok` 下，之后每次调用都使用这份保存的副本进行认证。所以之后可以把密钥从 `config.yml` 中移除，下次重启时公开分享仍会正常启动。需要注意这对密钥意味着什么：把密钥从配置中删掉，并不会把令牌从主机上移除。以下两种情况建议仍然保留它：一是启用*失败*（比如令牌被拒绝，或无法连接服务）时，这并不算完成启用，重试时需要这个密钥；二是之后的*重新*启用也需要它，所以如果实例已经移除了密钥，又丢失了 `data/zrok` 下的身份，它无法自行恢复。轮换后的令牌会从这里读取，并应用到已保存的环境上，身份和公开 URL 都保持不变。 |
| `zrok_api_endpoint` | string | `""` | 要连接的 zrok 服务，适用于自建部署；留空则使用 SDK 的默认值 `https://api-v2.zrok.io`（托管服务）。**仅在启用时**读取。一旦 `data/zrok` 中保存了已启用的环境，其中保存的端点就优先生效。因此，要让已启用的 zurg 改用另一个服务，需要删除 `data/zrok` 后重新启用。身份属于签发它的那个服务，所以这样处理本身也是正确的。它不能替代 `zrok_account_token`：首次启用时，仍然需要这里指定的服务所签发的令牌。在同一时刻，SDK 自带的环境变量 `ZROK2_API_ENDPOINT` 优先级高于此配置项。 |

对于自建服务，可达性有两个不同的方向，而只有其中一个由你控制：**这台 zurg** 需要访问控制器 API，只要是 tailnet 地址就够了；而**你的接收者**需要访问服务的前端。因此，如果服务只能在你自己的 tailnet 中访问，它生成的分享 URL 也只有你的 tailnet 能打开。

自建服务还有两点需要对齐。分享 URL 是服务为其前端公布的地址。如果只写裸主机名而不带协议，系统会默认使用 `https`。所以如果前端提供的是纯 HTTP，要么在前面加上 TLS，要么让公布的 URL 自带协议和端口。另外，分享是在 zrok SDK 解析出的命名空间中创建的，默认是 `public`，除非 SDK 自己的 `ZROK2_DEFAULT_NAMESPACE` 另有指定。zurg 不会固定这两项。如果服务的命名空间叫别的名字，就需要通过该环境变量告诉 zurg。

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. 性能与调优（高级） {#6-performance--tuning-advanced}

除非在调试或针对你所在的网络环境做优化，否则很少需要改动这些设置。

### 持久化读取缓存 {#persistent-read-caches}

两个字节缓存在重启后仍会保留。两者都在整个实例中共享,各自有独立的磁盘配额(单位 MiB)。更改在重启后生效。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `nzb_article_disk_cache_mb` | int | `512` | 解码后的 Usenet 文章保存在 `data/bytecache/articles/` 中。读取过一次的文章,下次会直接从磁盘提供。`0` 表示关闭。 |
| `archive_decoded_disk_cache_mb` | int | `512` | 解压后的压缩包数据块保存在 `data/bytecache/decoded/` 中。向后 seek 或重启后,不必再从该条目的开头重新解码。同样的配额也用于 `data/bytecache/decoded-tails/`,该目录会在某个压缩条目被请求过后,保留它末尾的 8 MiB。`0` 会同时关闭这两项。 |

配额写满时,最久未使用的记录会优先被清理。[persistent-caches.md](../internals/persistent-caches.md) 列出了所有重启后仍会保留的缓存。

### CDN 与主机选择 {#cdn--host-selection}

> **相关：** 用来确定最快主机的网络延迟测试会定期运行，周期由 [`network_test_every_mins`](#user-agent--network) 决定（默认：每 1440 分钟，即 24 小时）。

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | 控制 zurg 优先使用哪些 RD 下载服务器。`auto` 表示使用 RD 提供的任何服务器。`force_cloudflare` 会把主机改写为它的 `.cloud` 对应域名，这样就能通过 Cloudflare 访问同一台机器，适用于直连 IP 被封锁的情况。`force_numbered` 直接使用 RD 的编号主机。`force_location_<location>`（例如 `force_location_syd`、`force_location_fra`）会通过指定国家的服务器路由。 |
| `cdn_host_preference` | string | — | `rd_cdn_host_preference` 的旧版别名，仅为兼容而保留，且只适用于 Real-Debrid。如果两个都设置了，以明确指定的那个为准。 |
| `tb_cdn_host_preference` | string | `"auto"` | TorBox CDN 区域。`auto` 保持 TorBox 自己的选择不变；`force_location_<region>` 会让下载从该区域提供。只有当前提供投递节点的区域才能被强制指定，仪表盘里的 select 下拉列表只会列出这些区域。这里没有回退到旧版配置项——旧配置项的值是 Real-Debrid 的位置代码，在这里没有意义。 |
| `number_of_hosts` | int | `0`（全部） | 将 zurg 限制为 N 个最快的下载主机。对可用主机进行测速后，zurg 只使用前 N 个。设为 `0` 则使用所有可用主机。像 `3` 这样的值会减少连接分散，但能确保你始终使用最快的服务器。 |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` 和 `force_location_*` 不能同时使用。** RD 只为它的编号主机发布 `.cloud` 对应域名——经测量（2026-08-09），全部 25 个编号子域名都有对应域名，而 22 个按国家命名的子域名都没有。因此，在 RD 账户设置中启用了 Cloudflare 的账户，总是会被分配到编号主机，任何位置偏好都无法生效。zurg 会在启动时根据它解除限制的链接检测到这种情况，跳过注定失败的地理探测，并且如果你仍然配置了位置偏好，它会记录原因。

> **关于 `force_location_*` 验证的说明：** 使用类似 `force_location_nyk` 这样的地理位置偏好时，RD 的 `/rest/1.0/downloads` API 端点会把下载 URL 规范化为编号服务器（例如 `128-4.download.real-debrid.com`），即使实际的解除限制响应返回的是地理服务器（例如 `nyk7-4.download.real-debrid.com`）。下载代码本身会嵌入编号服务器（例如代码 `...4128` 对应服务器 `128-4`）。要验证地理路由是否生效，请查看 zurg 的日志或原始的解除限制响应——**不要**依赖 RD 的 downloads API。

### 速率限制 {#rate-limits}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | 常规操作（除列出种子以外的所有操作）每分钟允许的最大 RD API 调用次数。RD 自己也有限制；这个设置可以防止 zurg 触发 RD 的限制而被暂时封禁。只有在你确定自己的 RD 套餐允许的情况下才需要调高。 |
| `torrents_rate_limit_per_minute` | int | `75` | 专门用于获取种子列表的 `/torrents` 接口每分钟允许的最大 RD API 调用次数。之所以单独设置，是因为列出种子是最频繁的 API 调用，而且它有自己的速率特点。 |
| `fetch_torrents_page_size` | int | `5000` | 同步 RD 库时每页获取的种子数量。数值越大，API 调用次数越少，但每次返回的数据也越大。如果你的库非常大（10,000 个以上种子），调高这个值可以缩短同步时间。 |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### 链接验证 {#link-verification}

| 选项 | 类型 | 默认值 | 描述 |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | 控制 zurg 如何验证下载链接是否仍然有效。为 false 时,zurg 使用 `HEAD` 请求(很轻量,不传输数据)。为 true 时,使用 `Range` 头(`GET bytes=0-0`),只下载 1 个字节。如果你的网络或 RD 服务器对 HEAD 请求响应不正常,导致链接被误判为失效,就开启这个选项。 |

```yaml
use_range_verification: false
```

### 超时与重试 {#timeouts--retries}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `api_timeout_secs` | int | `60` | 等待任意 RD API 调用响应的最长秒数。如果你的网络比较慢,API 调用老是超时,可以把这个值调大一些。 |
| `download_timeout_secs` | int | `15` | 测试下载链接时(用于主机测速和链接验证)等待的最长秒数。这不是实际文件下载的超时时间。 |
| `retries_until_failed` | int | `2` | API 调用失败后,在放弃并标记为失败之前最多重试几次。值越大,越能扛住 RD 的临时故障,但失败检测会变慢。 |
| `retry_503_errors` | bool | `false` | 设为 true 时,遇到 RD 返回 503(Service Unavailable)的请求会重试。RD 在维护或负载过高时会返回 503。如果你经常遇到自己很快就能恢复的 503 错误,可以开启这个选项。 |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### 下载与调试 {#downloads--debugging}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `get_downloads_limit` | int | `-1` | 要获取的 RD 下载条目（非种子）的最大数量。`-1` 表示不限制（全部获取），`0` 则完全跳过下载获取，正数则设定上限。如果你使用 RD 的直链解锁功能，并希望这些文件在 zurg 中可见，这个选项很有用。如果不写这个键，等同于 `-1`；如果明确写了 `0`，则会被视为"不缓存任何内容"，并在启动时记录一条警告，因为这通常是 `0` 含义改变之前写下的旧配置。 |
| `load_dumped_torrents` | bool | `false` | 设为 true 时，启动时会从 `dump/` 文件夹加载种子数据。这是一种恢复机制：如果 zurg 之前转储过种子状态（例如在崩溃期间），启用此项即可恢复该状态，无需从 RD 重新获取全部数据。 |
| `log_requests` | bool | `false` | 设为 true 时，会为每个下载请求记录详细统计信息（文件路径、响应时间、发送的字节数）。适合用于调试串流问题或了解访问模式。日志量会很大，生产环境中请关闭。 |
| `log_level` | string | `DEBUG` | 日志详细程度：`DEBUG`、`INFO`、`WARN`、`ERROR` 或 `FATAL`。在 dashboard 中修改后立即生效，无需重启，并会同时调整所有组件的日志级别。它会覆盖 `LOG_LEVEL` 环境变量，因此即使容器内置了某个值，dashboard 的控制仍然有效；如果不写这个键，则把选择权交还给 `LOG_LEVEL`。无法识别为日志级别的值会在启动时被忽略并给出警告，而不会导致程序退出。 |
| `traffic_alert_gb` | int | `0` | 当某个网盘账户一天内通过 zurg 传输的流量超过此 GiB 数时发出警告（每天在 CET 时间 00:05 重置，与 Real-Debrid 的流量配额一致）。警告会列出本小时内用量最大的文件以及读取它们的对象，这样在扫库或客户端整文件拉取时，你能在发生的同时就看到。无论是否设置此警报，zurg 都会在每小时整点记录该小时最大文件的摘要，并在任何单次读取达到 1 GiB 或以上时记录一行。`0` 表示关闭警报。 |
| `traffic_alert_webhook` | string | — | 流量警报同时会发送到的 Discord webhook。请妥善保密：任何拿到该 URL 的人都可以向该频道发消息。 |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
traffic_alert_gb: 500
```

#### 向支持团队发送日志 {#sending-logs-to-support}

**Export Logs**（仪表盘上的）和 `zurg support` 会把脱敏后的日志和配置发送到 DMM 的支持服务器 `logs.debridmediamanager.com`，并给你一个代码，用来粘贴到支持帖子里。没有对应的设置项。如果无法连接该服务器，或者服务器拒绝上传，文件就会改传到公共粘贴站点，按以下顺序依次尝试：`paste.c-net.org`、`temp.sh`、`0x0.st`。如果你的防火墙只允许 zurg 访问部分主机，请放行 `logs.debridmediamanager.com`。

如果某个主机返回 403，说明它把这台机器拒之门外了，zurg 会在接下来的 24 小时内跳过它，`logs.debridmediamanager.com` 也包括在内。仪表盘上的 **Download Logs** 会给你同样经过脱敏的文件，但不会把它们发送到任何地方。

## 7. 目录与过滤器 {#7-directories--filters}

定义虚拟目录，根据灵活的过滤规则整理你的种子。每个目录都会在挂载中显示为一个文件夹，并且只显示符合其过滤条件的种子。

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### 目录选项 {#directory-options}

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `group` | string | 目录自己的名字 | 共享同一个 group 的目录会为每个种子竞争:种子会落到第一个过滤器匹配的目录中,同组的其他目录都不会再收到它。不同组的目录各自拥有一份副本。 |
| `group_order` | int | `0`(视为 `1`) | 组内的优先级,数值越小越靠前。数值相同时按目录名排序。 |
| `filters` | list | `[]` | 决定哪些内容属于这里的规则。只要列表中有**任意**一条匹配,种子就匹配该目录。列表为空或不存在时,匹配所有种子。 |
| `only_show_the_biggest_file` | bool | `false` | 只显示每个种子中最大的文件,隐藏样本、附加内容和配套文件。 |
| `only_show_files_with_size_lte` | int | `0`(关闭) | 隐藏大于此字节数的文件。 |
| `only_show_files_with_size_gte` | int | `0`(关闭) | 隐藏小于此字节数的文件。 |
| `rex_shows` | string | `""`(无) | 与 `rex_url` 配合使用:rex 中显示本目录剧集的电视库标题。 |
| `rex_movies` | string | `""`(无) | 与 `rex_url` 配合使用:rex 中显示本目录电影以及 rex 无法判断为剧集的文件的电影库标题。 |
| `rex_music` | string | `""`(无) | 与 `rex_url` 配合使用:rex 中显示本目录音频文件(`.flac`、`.mp3`、`.m4a`、`.m4b`,包括有声书)的音乐库标题。未设置时,没有任何音频文件会进入 rex。 |
| `rex_photos` | string | `""`(无) | 与 `rex_url` 配合使用:rex 中显示本目录漫画(`.cbz`、`.cbr`,每本都是一个相册,包含其所有页面)的照片库标题。Plex 网页版会逐页浏览并以幻灯片形式播放。Plex for Android 不显示照片库。漫画文件仍保留在挂载点上。 |

在 zurg 中被明确强制显示的文件会忽略以上三个可见性选项。

### 过滤条件 {#filter-conditions}

| 条件 | 类型 | 说明 |
|-----------|------|-------------|
| `id` | string | 种子的 ID。具有决定性：同一条目中的其他内容都不会被考虑。 |
| `regex` | string | 种子名称匹配该模式。 |
| `not_regex` | string | 种子名称不匹配该模式。 |
| `contains` | string | 种子名称包含该文本（不区分大小写）。 |
| `contains_strict` | string | 种子名称包含该文本（区分大小写）。 |
| `not_contains` | string | 种子名称不包含该文本（不区分大小写）。 |
| `not_contains_strict` | string | 种子名称不包含该文本（区分大小写）。 |
| `size_gte` | int | 种子总大小至少为这么多字节。 |
| `size_lte` | int | 种子总大小至多为这么多字节。 |
| `any_file_inside_regex` | string | 种子中有某个文件匹配该模式。 |
| `any_file_inside_not_regex` | string | 种子中有某个文件不匹配该模式。 |
| `any_file_inside_contains` | string | 某个文件包含该文本（不区分大小写）。 |
| `any_file_inside_contains_strict` | string | 某个文件包含该文本（区分大小写）。 |
| `any_file_inside_not_contains` | string | 某个文件不包含该文本（不区分大小写）。 |
| `any_file_inside_not_contains_strict` | string | 某个文件不包含该文本（区分大小写）。 |
| `any_file_inside_size_gte` | int | 某个文件至少为这么多字节。 |
| `any_file_inside_size_lte` | int | 某个文件至多为这么多字节。 |
| `added_within_hours` | int | 种子是在这么多小时内添加的。 |
| `added_within_days` | int | 种子是在这么多天内添加的。 |
| `added_after` | string | 种子是在该日期当天或之后添加的。格式为 `YYYY-MM-DD` 或 `YYYY-MM-DD HH:MM`。 |
| `added_before` | string | 种子是在该日期之前添加的，格式相同。与 `added_after` 配合使用时，两个条件都必须成立。 |
| `has_episodes` | bool | 剧集识别：种子或文件名中有季/集标记或 CRC 哈希，或者有一串编号文件。若最大文件至少是第二大文件的 5x，则会被视为带花絮的电影并被拒绝。 |
| `is_music` | bool | 某个文件以 `.m3u`、`.mp3`、`.flac`、`.m4a` 或 `.m4b` 结尾。 |
| `has_tag` | string | 种子带有该标签。起门槛作用：如果没有它，该条目中的其他条件都无法匹配。 |
| `not_has_tag` | string | 种子不带该标签，同样起门槛作用。 |
| `tags_match_all` | list | 列出的每个标签都存在（不区分大小写）。 |
| `tags_match_any` | list | 列出的标签中至少存在一个。 |
| `tags_missing_all` | list | 列出的标签都不存在。 |
| `tags_missing_any` | list | 列出的标签中至少有一个不存在。 |
| `provider` | string | 该版本由此账户持有，账户以 providers 块中的 `name` 指定。它是门槛而非匹配条件：与其他条件组合时，两者都必须成立。单独使用时，会将整个账户纳入目录。 |
| `not_provider` | string | 持有该版本的账户都不是此账户。同样起门槛作用。 |
| `and` | list | 每个嵌套条件都必须匹配。 |
| `or` | list | 至少一个嵌套条件必须匹配。 |

标签来自媒体分析，完整列表请见 [tags.md](tags.md)。

模式的写法为 `/expression/flags`，其中 flags 可以是以下任意组合：`i`（不区分大小写）、`m`（多行）、`s`（点号匹配换行符）和 `x`（扩展模式）。不带斜杠的值会被当作纯 Go 正则表达式编译。

同一个过滤条目中的条件默认**不是**以 AND 连接的——它们大多数只要满足其中一个，就会匹配该条目。如果你需要所有条件都满足，请使用明确的 `and:` 块：

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### 每账户目录 {#per-account-directories}

除了 `__all__` 之外，每个已配置的账户还会有一个以其命名的专属目录，例如 `__realdebrid__`、`__torbox__`、`__alldebrid__`、`__nzb__`。这些目录不需要配置，只要账户存在就会出现，账户删除后随之消失。只有一个账户时，它自己的文件夹会从挂载根目录列表中隐藏，但 `__all__` 中的内容相同。直接的 HTTP 和 WebDAV 路径（例如 `/http/__realdebrid__/`）仍然可以访问。通过挂载访问时，它也无法再解析。任何使用 `__<name>__` 的媒体库或脚本，请改为指向 `__all__`。

每个目录保存该账户持有的全部内容，而且与过滤目录不同，它还决定读取请求走哪个账户。同一个版本如果由两个账户持有，在媒体库中只是一个条目。如果没有这个设计，每份副本都会从 `providers` 配置块中排在最前的账户读取：

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

固定（pin）会排除其他账户，而不只是优先选择指定的账户。没有静默切换：如果 TorBox 无法提供该文件，`__torbox__` 下的读取就会失败，而不会悄悄返回 Real-Debrid 的数据。挂载中其他位置的读取不受影响，仍会正常切换。

由于各账户持有的内容并不完全相同，会产生两个结果：

- 目录只列出该账户实际持有的文件。如果 TorBox 只下载了 Real-Debrid 已完整拥有的某个版本的一部分，`__torbox__` 中就只显示那一部分。
- 损坏状态按账户判断。在 Real-Debrid 上已失效、但在 TorBox 上健康的文件，在 `__realdebrid__` 下会返回 404，在 `__torbox__` 下可以播放，而挂载中的其他位置仍然会提供该文件。

目录以账户的 `name` 命名，`name` 默认为其 `type`。同一服务的两个账户需要不同的名称（`rd-main`、`rd-backup`），并各自获得一个目录。Usenet 后端默认为 `nzb`，因此显示为 `__nzb__`。如果你想浏览 `__usenet__`，请在该 provider 条目上设置 `name: usenet`。

之后可以重命名账户。zurg 会看到同一批版本以新名称列出，并将它们移到新目录下。旧名称对应的旧目录随之消失。如果媒体服务器读取该目录，请在重命名之前先将其指向新目录。

同一个版本会同时出现在所有持有它的账户目录和你的过滤目录中，因此请让媒体服务器只指向挂载的一部分，而不是全部，否则它会多次扫描相同的内容。

如果账户的名称与 zurg 已在使用的目录名（`all`、`unplayable`、`dump`、`downloads`）相同，该账户将不会获得专属目录，zurg 会在启动时记录一条警告，而不会接管已有目录。

### 本地 debrid 目录库 {#local-debrid-catalogs}

每个 debrid 提供商条目都可以选填一个 `library` 块：

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: PRIMARY_RD_TOKEN
    download_tokens: # Optional bandwidth fallback.
      - SECOND_RD_TOKEN
    library:
      source: local
      path: torrents/rd-local
```

`source` 默认为 `provider`。设为 `local` 时，由可移植的 `.zurgtorrent` 文件决定成员关系，播放则使用此账户的凭据。`path` 默认为 `torrents/<resolved-account-name>`，并且必须位于 `torrents/` 目录下。同一个源目录不能同时属于两个已启用的账户。NZB 提供商保留其现有的 `nzbs/` 库。

在这个示例中，两个 RD token 共用 `torrents/rd-local/` 中的同一个目录。第二个 token 不需要单独的提供商条目或目录，它的 torrent 库也不会被导入。`download_tokens` 保留其带宽回退行为，并不会强制所有下载都经过第二个 token。相反，两个独立的本地提供商条目各自拥有两个不同的目录，即使两者都是 Real-Debrid。凭据只保存在配置中，绝不会导出到可移植文件里。

关于离线导出、从 `dump/` 迁移、共享规则以及播放限制，请参阅 [可移植库](../guides/local-libraries.md)。

#### 将在线账户卸载到本地库 {#offloading-an-online-account-into-a-local-library}

自有内容库的 Real-Debrid 或 AllDebrid 账户（没有 `source`，或 `source: provider`）可以把已完成的发布内容移入本地库，并从账户中删除，这样就会释放它们占用的槽位：

```yaml
providers:
  - name: rd
    type: realdebrid
    token: YOUR_RD_TOKEN
    library:
      offload_to: rd-local      # a local entry of the same type
      offload_after_mins: 30    # optional, 30 is the default

  - name: rd-local
    type: realdebrid
    token: YOUR_RD_TOKEN        # the same account
    library:
      source: local
```

| 键 | 默认值 | 含义 |
|---|---|---|
| `library.offload_to` | 无 | 要移入的目标，即同类型且已启用的 `source: local` 条目的名称。只有 `realdebrid` 和 `alldebrid` 账户接受它，因为只有这两类的链接在 torrent 被删除后仍然有效。它不能指向账户本身。 |
| `library.offload_after_mins` | `30` | 发布内容必须在账户上保持完整多久才会被自动移入。从 zurg 首次看到它完整时开始计算，因此重启后会重新开始等待。需要设置 `offload_to`。 |

只有当以下条件都满足时，发布内容才会被移动：每个文件都有另一个账户可以兑换的链接；没有任何修复或下载任务正在处理它；qBittorrent 接口中没有 Sonarr 或 Radarr 任务仍在列出它；并且移动后能保留其文件夹名称和所在的每一层目录。它的文件夹保持原位，也不会启动媒体服务器扫描。仪表板中的发布页面可以手动移动单个发布内容，无论是否设置 `offload_to`。关于步骤顺序、某一步失败时会发生什么，以及共享 token 上的本地播放如何受到保护，请参阅[便携式库](../guides/local-libraries.md#offload-an-online-account-into-a-local-library)。
