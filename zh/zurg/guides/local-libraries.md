# 本地 debrid 库与便携 zurg 种子 {#local-debrid-libraries-and-portable-zurgtorrents}

本地库的成员关系来自可移植的 `.zurgtorrent` 文件。它会出现在常规的 WebDAV、HTTP 和 provider 目录中。导入文件、列出文件以及刷新目录都不会添加种子，也不会解析下载链接。播放时，会通过你配置的账户解析请求的文件。

## 导出库 {#export-a-library}

+++ Linux 和 macOS
```sh
./zurg --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++ Windows
```powershell
.\zurg.exe --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++

`--provider` 是已配置账户的**名称**，包括自定义名称。省略它即可导出所有受支持的 debrid 副本。输入也可以是单个运行时缓存文件、旧版 `dump/` 目录，或现有的便携式目录。对于本地库，请导出其源目录（`torrents/<account>`），这样可以保留它对其他提供方的可选引用。

导出过程不需要联网。它会在写入前验证所有输入以及目标文件名冲突，报告并跳过没有选定文件元数据的运行时条目，按哈希合并各个资源，并写入 `<hash>.zurgtorrent`。内容完全相同的已有导出文件可以安全地重复导出。对于包含格式错误的旧版缓存条目的批量迁移，`--skip-invalid` 会导出有效条目，并报告省略了多少个。如果不加该参数，遇到第一个无效条目就会中止，且不会写入任何内容。`--replace` 允许替换相同哈希的便携式导出文件；它绝不会授权覆盖运行时缓存。

只有导出的文件适合分享。`data/*.zurgtorrent` 仍然是私有的运行时状态。`.zurgbackup` 还包含账户凭据，它是实例备份，不是可分享的库。

## 接收库 {#receive-a-library}

将导出的文件放入 `torrents/rd-local/`，然后配置接收端账户：

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: YOUR_OWN_TOKEN
    download_tokens: # Optional bandwidth fallback on another RD account.
      - SECOND_RD_TOKEN
    library:
      source: local
      # Optional; defaults to torrents/<account-name>.
      path: torrents/rd-local

  - name: tb-online
    type: torbox
    token: YOUR_OWN_TORBOX_TOKEN
    # Omitted library block means the provider owns this account's catalog.
```

在 Real-Debrid 和 AllDebrid 中，`download_tokens` 与其 provider 条目使用同一个本地目录。上面的第二个 RD 账户不需要目录，它的种子库也不会被导入。
这些是备用凭据，在当前下载 token 的带宽额度用完时使用；它们不会强制所有下载都走第二个账户。反过来，在 `providers` 下新增第二个 RD 条目，则会创建一个独立的目录，并拥有自己的本地目录。所有凭据都保留在配置中，并且不会包含在可移植导出内容中。

TorBox 也接受 `download_tokens`，但它的 token 轮换无法把已存储的 torrent/文件 ID 映射到另一个账户上的 ID。请为不同账户分别添加 TorBox provider 条目，每个条目使用各自的本地目录。

Premiumize、Offcloud 和 Debrid-Link 账户也可以保存本地库。它们都没有可移植的文件引用。因此，和 TorBox 一样，每个账户会在首次播放时将 hash 添加到自己的账户中，并按路径和大小匹配文件。每个账户请使用一个 provider 条目。

修改账户配置后请重启。文件的新增、替换和删除会由常规刷新循环自动识别。每个目录只扫描一层。路径必须是 `torrents/` 下互不相同的目录，这样常规备份才会包含它们。无法读取的目录或无效的替换文件会保留最后一次有效的内存条目，并记录问题。重启后，无效文件必须先修复，才能加入本地目录。

同一个 manifest 可以复制到 AllDebrid 或 TorBox 账户的本地目录中。它包含的是内容标识，而不是 provider 账户名称。同一个 hash 在多个账户中只会出现一次，但会有多个来源，并沿用现有的账户优先级和故障转移顺序。同一目录中某个 hash 的重复文件，使用排序后的第一个文件名；每个 hash 只保留一个 manifest。

即使从 provider 的在线库中移除，本地目录中的成员关系依然保留。重命名、标签、IMDb ID 和文件删除会写回 manifest。删除本地发布项会移除其源文档，但不会删除 provider 中的种子。删除带有在线副本的发布项时，也会删除这些在线副本，与常规的整体删除相同。

本地账户不能作为 watchlist、磁力链接上传或种子文件上传的目标。请通过导入 manifest 来添加条目。`add_torrents: false` 仍允许 RD/AD 兑换已有的共享引用，但会阻止播放时在需要时于 provider 端创建附加内容。

## 将在线账户卸载到本地库 {#offload-an-online-account-into-a-local-library}

AllDebrid 每个账户最多接受 1000 个 magnet，Real-Debrid 账户也会被占满。已完成的发布内容不需要让种子留在账户里也能继续播放。Real-Debrid 的 `/d/` 链接在种子被删除后仍然有效，AllDebrid 的锁定 `/f/` 链接在 magnet 被删除后也仍然有效。卸载功能正是依赖这一点。zurg 会把已完成的发布写入同一服务上的本地库，然后从在线账户中删除种子，从而释放名额。该发布在挂载中仍保留其文件夹，并通过已保存的链接播放。

为同一账户配置两个条目，一个在线，一个本地：

```yaml
providers:
  - name: ad
    type: alldebrid
    token: YOUR_AD_TOKEN
    library:
      offload_to: ad-local     # the local entry below
      offload_after_mins: 30   # optional, 30 is the default

  - name: ad-local
    type: alldebrid
    token: YOUR_AD_TOKEN       # the same token
    library:
      source: local            # manifests live in torrents/ad-local/
```

新发布会继续出现在 `ad` 上。每次完整列出该账户之后，以及每隔五分钟，zurg 都会逐个移动符合条件的发布。满足以下条件时，发布才会被移动：

- 从本次 zurg 进程首次看到它完整开始，它在账户上已完整存在 `offload_after_mins` 分钟。重启后等待会重新开始。
- 每个文件在该账户上都有一个其他账户可以兑换的有效链接。只要有任何文件缺少链接，该发布就保留在线上。
- 它是健康的，没有在修复中，并且没有任何实例仍在下载。没有修复任务或下载客户端占用其种子。
- Sonarr 或 Radarr 的 qBittorrent 任务中没有任何任务仍列出它。请在 *arr 中开启 Remove Completed Downloads，这样任务会在导入后被移除。否则，该发布会一直保留在线上，直到你移除任务。
- 最近一小时内，获取流程没有添加它。
- 移动它不会改变它所在的任何目录，并且保留其文件夹名。如果某个目录带有指定在线账户的 `provider:` 过滤器，移动后会丢失该发布，因此这类发布保留在线上。

顺序是固定的：先把清单 `<hash>.zurgtorrent` 写入本地库，接着把发布加入本地库，最后才从在线账户删除种子。如果无法写入清单，则什么都不会删除。如果删除失败，在线副本会与本地副本并存，下一次刷新时会显示种子是否仍然存在。如果本地库中已经有该发布的清单，则会原地更新，而不会重复写入。清单中在线账户的链接会被刷新，其名称和编辑内容会跟随挂载所显示的发布，另一服务的链接则会保留。

发布会离开 `__ad__`，出现在 `__ad-local__` 下。其他所有目录，包括 `__all__` 和你自己的目录，都会继续以相同名称列出它。不会启动媒体服务器扫描，因为媒体服务器索引的内容没有变化。请让 Plex 和其他媒体服务器指向这些目录，而不是指向某个按账户划分的目录。

两个条目使用同一个令牌时，本地播放可能会重新把某个发布附加到同一账户上（见下文），这样该种子就会出现在在线列表中。如果某个发布的在线种子是这样的附加项，或者本地播放正在添加一个附加项，zurg 绝不会卸载该发布，因为删除它会破坏刚刚获取到它的播放。

只有 Real-Debrid 和 AllDebrid 可以卸载。TorBox、Premiumize、Offcloud 和 Debrid-Link 没有能在种子被删除后仍然有效的链接，因此它们的本地播放会把种子重新添加回去，卸载就不会释放任何空间。zurg 会拒绝在这些账户上设置 `offload_to`。

仪表板也可以单独移动某个发布。在发布页面的 Accounts 表格中，只要存在同类型的本地库，即使没有设置 `offload_to`，每个 Real-Debrid 或 AllDebrid 副本旁边都会显示 Move to local library。如果该发布暂时无法移动，按钮会被禁用，并说明原因。配置页面上的账户设置也提供同样的选项，并显示自 zurg 启动以来已移动的发布数量，以及最近一次错误。

## 文件中包含什么 {#what-travels-in-the-file}

带版本号的 JSON 格式包含 `format: "zurgtorrent"` 和数字类型的 `version: 1`。
它包含 infohash、发布名称、添加时间戳、重命名、标签、IMDb ID，
以及所选文件的路径、大小和可选的重命名。引用是可选的：

| 提供商 | 可移植引用 | 播放 |
|---|---|---|
| Real-Debrid | 标准的 13 位字符 `https://real-debrid.com/d/...` | 使用接收方的凭据和下载 IP 进行解析。 |
| AllDebrid | 锁定的 `https://alldebrid.com/f/...` | 使用接收方的凭据解锁。 |
| TorBox | 哈希以及文件路径/大小 | 首次播放时在接收方一侧获取一个种子，并按路径和大小匹配其文件。 |
| Premiumize、Offcloud、Debrid-Link | 哈希以及文件路径/大小 | 首次播放时在接收方的账户中添加该哈希，并按路径和大小匹配其文件。 |

导出内容不包括账户名、凭据、提供商的种子/文件 ID、CDN URL、MediaInfo 输入 URL、Plex ID、修复状态或删除队列。导入器会拒绝未知字段，以及包含凭据或意外的引用 URL。验证清单时不会去请求这些 URL。Usenet 保留其 `.nzb` 源格式；NZB 运行时缓存无法导出为可移植的种子。

## 播放与限制 {#playback-and-limits}

本地跟踪改变的是谁拥有这个目录，但它不能保证提供方仍然保存着文件数据，或者仍然能提供这些数据。账户权限、允许的网络位置、活动槽位、配额和速率限制依然有效。

如果存在，RD 和 AD 会使用共享的锁定引用。仅有哈希的清单，以及 API 明确报告不存在的 RD 引用，都可以在接收方账户上确立内容。TorBox 始终需要将内容关联到该账户，并且会优先复用接收方账户上已有的匹配种子。添加操作会遵循提供方现有的节奏控制，并且在每个账户上按顺序串行执行。当账户报告了槽位数，或者 zurg 知道槽位数时，向已满的账户添加会被拒绝，之后的下一次播放请求会在一分钟后再试一次。AllDebrid、Premiumize 和 Offcloud 不报告槽位数，因此添加会照常进行，而已满的账户会拒绝它。对于状态不确定的添加，会暂停 30 分钟再尝试；正在准备中的种子只会在再次请求播放时检查。

接收方 ID 和已解析的原生文件句柄会私密地保存在 `data/local-torrents/` 中。这份记录在重启后依然保留，并包含在常规备份里。zurg 绝不会自动删除这些关联，因为一次幂等的添加可能返回了接收方原本就拥有的种子。卸载（Offloading）同样不会动它们。提供方出现故障时，本地条目会保持可见，并进入退避状态，而不会启动后台修复，也不会在每次扫描时重复添加。

本地压缩包发布版本只列出其源卷，不会自动解压，也不会在后台检查。对于压缩包内的明确路径，仍然可以调用压缩包读取器。在有本地副本的条目上，会禁止自动 MediaInfo 探测和下一文件预取。

## 迁移旧的导出数据 {#migrate-an-old-dump}

使用上面的命令导出 `dump/`，把结果放到接收账户的 `torrents/<name>/` 目录下，然后启用 `library.source: local`。迁移完成后，关闭 `load_dumped_torrents`。旧的可选 `__dump__` 读取器仍保留以兼容旧版本，新的本地库不会使用它。缺少账户类型的运行时缓存，需要先从一个了解其提供商的实例重新导出，才能共享。

这个版本写出的备份使用格式 2，以包含新的持久化根目录。恢复命令仍然可以读取格式 1 的备份。旧版本会拒绝格式 2 的备份，而不会悄悄丢掉本地库。
