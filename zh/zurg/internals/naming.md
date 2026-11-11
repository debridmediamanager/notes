# zurg 命名 {#zurg-naming}

几乎 zurg 显示的所有名称都是实时计算的，从不存储。一个发布版本的文件夹名、其中文件的名称，以及其缓存记录在磁盘上的文件名，都会在每次查找时根据种子重新推导。没有任何东西会把这些名称写下来再读回去，因为存储的名称就成了需要和库保持同步的第二份数据。而修复或 NZB 重新解析，恰恰会破坏这种同步。

唯一的例外是操作者主动要求的重命名。这种重命名会被存储在发布版本本身上，并且优先于下面的所有推导规则。规则在第 9 节，面向用户的说明见重命名指南。本页其余部分描述的是未设置重命名时，发布版本所使用的名称。

这里先说明一个结果，因为它是与 zurg 集成时大多数意外的来源：文件夹可能在没有任何东西“重命名”它的情况下改变名称。原因是输入变了，输出自然也就变了。

本文件只列出规则，不列出阈值。如果某条规则是由启发式算法决定的，我们只会写出决定它的函数名，然后就此打住。这些阈值是根据真实发布版本调校的，而且会变化，把它们抄到这里只会多出一份需要保持同步的内容。代码引用均相对于包路径。

## 1. 版本文件夹名称 {#1-the-release-folder-name}

`internal/torrent/key.go`, GetKey / GetKey_Original

`__all__/` 下的文件夹名、`.zurgtorrent` 文件名、每次查找都会用到的键，以及 zurg 所说的 "access key"，都是同一个字符串。它按下面的顺序决定，第一个匹配的规则生效：

  | 条件                                        | 文件夹名                  |
  |---------------------------------------------|---------------------------|
  | `ignore_renames: false`，且设置了 Torrent.Rename | Torrent.Rename            |
  | `retain_rd_torrent_name: true`              | Name，不做修改            |
  | `retain_folder_name_extension: true` 且     | Name，不做修改            |
  |   Name 包含 OriginalName                    |                           |
  | 其他情况，即两个标志都是默认值              | OriginalName，先去掉 `.mp4`，再 |
  |                                             |   去掉 `.mkv`             |

`retain_rd_torrent_name` 会先被检查，它会完全屏蔽 `retain_folder_name_extension`。第二条规则只适用于 Name 中包含 OriginalName 子串的情况；如果不包含，去除后缀的操作照样会执行。

去除操作是运行两次的 `strings.TrimSuffix`，实际上包含三条规则。只去掉 `.mp4` 和 `.mkv`，所以 `.avi`、`.ts`、`.iso` 等后缀会保留在文件夹名中；它区分大小写，所以 `Movie.2019.MKV` 会保留 `.MKV`；两次去除是依次执行，而不是二选一，所以 `Movie.2019.mkv.mp4` 会变成 `Movie.2019`。之后可能还会追加一个后缀，见第4节。结果始终是单个路径组件，永远不会按 `/` 拆分。

已弃用。`retain_folder_name_extension` 和 `retain_rd_torrent_name` 已被弃用，将来会被移除。目前行为保持不变，但设置其中任何一个都会在启动时记录一条警告。这两个选项都以 Name 作为库的键，而 Name 会被账户在 zurg 下方改写（见第2节）；默认设置则以种子自身声明的名称作为键，账户不会改动它。在前面接着 Sonarr 或 Radarr 的实例上（即包含 `sabnzbd:` 或 `qbittorrent:` 块的实例），只有默认值才是正确的，因为导入之后如果访问密钥变了，就会丢失这个发布。`ignore_renames` 没有被弃用。

## 2. Name 和 OriginalName 的来源 {#2-where-name-and-originalname-come-from}

Real-Debrid   `internal/realdebrid/types.go`
              Name = `filename`, OriginalName = `original_filename`

TorBox        `internal/torbox/types.go`, wireTorrent.originalName
              Name = `name`。OriginalName 是所有文件都位于其下的那个唯一目录（前提是只有一个）；位于目录树根部的文件回退到 `name`，但唯一一个裸文件例外，它使用自己的名称。

AllDebrid     `internal/alldebrid/types.go`, originalName
              规则与 TorBox 相同，只是作用于展平后的文件列表，无法确定时回退到磁力链接的 `filename`。

NZB           `internal/nzb/provider.go`
              Name 和 OriginalName 都是 releaseName，种子的 Hash 则是 release id。见第 3 节。

由于 debrid 后端从种子自身的根文件夹推导 OriginalName，持有相同内容的两个账户会得到相同的文件夹名。

Real-Debrid 这两个字段的含义，是在 2026-08-27 用一个约 84k 个种子的测试账户测得的，通过只读方式调用 `GET /torrents/info` 抽样了 252 个种子。`original_filename` 在所有情况下都是种子声明的名称（即合集或文件夹名），从来不是单个文件的名称。`filename` 则不是这样。它会坍缩为某一个文件自身的基本名称，而且恰好在多文件种子中只选中一个文件时发生：在这种形态的 112 个抽样种子中有 90 个如此，而选中多个但非全部的 34 个种子和全部选中的 24 个种子中，一个都没有。在一个 221 个文件的合集里只选中一集时，`original_filename` 的值是 `Marvel Cinematic Universe MCU Collection 2008-2023 1080p jZQ`，而 `filename` 的值是 `Spider-Man.No.Way.Home.2021.1080p.BluRay.x264...-NOGRP.mkv`。所以默认设置给出的是合集名称，而 `retain_rd_torrent_name: true` 给出的是单个文件的名称。这也是该选项被弃用的原因：`filename` 会随账户状态变化，而访问密钥则不能随之变化。

## 3. NZB 版本命名 {#3-nzb-release-naming}

`internal/nzb/provider.go`, releaseName; `internal/nzb/parse.go`

release id（也就是它的 Hash）是 `hex(sha1(lowercase(nzb filename)))` 的结果。它基于文件名而不是内容计算，所以重新保存 NZB 不会让由它生成的 torrent 失去关联。
文件夹名就是该 FILENAME 去掉扩展名之后的部分。但如果这个主干看起来像哈希，或者经过清理（sanitize）后变成空字符串，就改用 NZB 自身 `<head>` 元数据里的名字。
之所以以文件名为准，是因为它是索引站写下的名字、下载器保存的名字，也是自动化工具用来查找该发布的名字。而索引站经常重新发布，元数据块里的 subject 行可能会不一样。
`stemLooksJunk`、`looksLikeHash` 和 `sanitizeReleaseName`（位于 `internal/nzb/parse.go`）负责解决这三个问题。把它们当作黑盒看待即可。

## 4. 三种名称后缀 {#4-the-three-name-suffixes}

  ` {xxxxxx}`   用在发布文件夹上，当两个不同的发布名称相同时：
                该发布自身信息哈希（infohash）的六位十六进制字符。在同名组内，最近添加的发布保留原始名称，其他的都加上该标签。这个决定在每次刷新时由一次能看到整个库的遍历来完成，并以 KeySuffixed 持久化，因此 GetKey 始终是仅依赖于种子本身的纯函数（`internal/torrent/key.go`，disambiguateNames）。Real-Debrid 种子和同一发布的 NZB 在这里被视为两个不同的发布，因为 NZB 的哈希是其文件名的 sha1。

  ` (tag).ext`  用在文件上，当同一发布内文件的基本名重复时，因为 zurg 会把种子的目录树压平成单个目录。标签取自已能区分这些冲突文件的目录，即在整个组中互不相同的最浅路径组件；如果没有，则取文件路径 sha1 的六位十六进制字符。哪一层深度符合条件，以及组件在文件名中可以保留什么，由 `internal/torrent/dupenames.go` 中的 `dupeTags` 和 `sanitizeTag` 决定；请把两者都当作黑盒处理。该组包含列表中的每个文件，无论是否被选中，因此一个不再被选中的文件仍会解析到它当初归档时使用的键。`__magic__` 是唯一的例外：它显示发布的真实目录树且不带任何标签，因为目录本身已经能区分这些文件，见第 8 节。

  `_xxxxxxxx`   用在磁盘上的文件名上，当其输入包含任何非 ASCII 字符时：该输入 sha256 的八位十六进制字符。见第 6 节。挂载点上永远不会出现。

## 5. 版本内的文件名 {#5-file-names-inside-a-release}

`internal/torrent/manager.go`。VisibleName(key, file) 是唯一的依据，决定挂载点显示什么名称，以及查找时必须匹配哪个名称。如果有 File.Rename，并且 `ignore_renames` 为 false，就用 File.Rename；否则用 SelectedFiles 的 key，这个 key 已经带上了第 4 节中提到的标签。GetFilename 改为返回 `filepath.Base(file.Path)`，所以会把标签丢掉。显示和查找都必须经过 VisibleName，否则对带标签名称的请求会找不到任何结果，而 N 个文件会共用同一个不带标签的名字。

## 6. 磁盘上的文件名 {#6-on-disk-filenames}

`internal/torrent/utils.go` 里的 sanitizeFilename 比较晦涩，而且它**只**作用于 zurg 在宿主机上写入的文件（`data/<name>.zurgtorrent` 和 STRM 目录树），从不影响挂载提供的内容。它比上面提到的任何规则都激进得多：一个挂载文件夹名为 `Три богатыря` 的版本，其缓存文件名是一串下划线加上 `_xxxxxxxx` 后缀，这个后缀用来把它和下一个西里尔字母标题区分开。这是另一个命名空间，本来就不打算和挂载的名字对应。

## 7. 压缩包内部 {#7-archive-interiors}

通过 RAR、ZIP 或 7z 提供的版本会列出压缩包内的内容，而不是分卷。下面两条规则会改变这些内容的显示名称。

`stripRedundantRoot`（`internal/universal/rar_streamer.go`）会移除包裹整个压缩包的前导目录。`payloadRenames`（`internal/universal/deobfuscate.go`）会把单个混淆的主文件用发布名称显示，并同时移动所有与它主干名相同的条目。

判断是否混淆的是同一文件中的 `looksObfuscated`，它是 zurg 对 SABnzbd 测试的移植版。它要判断的是 opaque（不透明名称），周围的守卫条件也一并在此处理。

磁盘上的文件不会被改写。`archiveName` 也会解析压缩包自身的原始拼写。

## 8. 目录名称 {#8-directory-names}

`internal/torrent/manager.go`, `internal/torrent/provider_directories.go`

内置且保留的名称：

    __all__          所有资源
    __unplayable__   没有可播放内容的资源
    __dump__         已转储的种子
    __downloads__    下载视图
    __magic__        可写的覆盖层，是唯一一个目录结构是存储而非计算得出的目录。它自己的 `__all__` 镜像了库，也就是 `__all__` 包含的每个资源，各自以其文件 `File.Path` 值描述的目录树呈现，而不是扁平化（`internal/magic/tree.go`）。镜像旁边的所有内容都是用户存储的。镜像是计算出来的，所以不能往里面写任何东西；`internal/magic/resolve.go` 中的 `MirrorDirectory` 就是指它的名字
    int__all__       内部哈希索引

`__downloads__` 和 `__magic__` 不是过滤器，所以它们是手动追加到根目录列表中的；`__magic__` 只在启用 magic 时才会出现。任何以 `int__` 开头的名称都会被完全跳过，不会出现在根目录列表中。

每个账户还会多一个名称，即 `"__" + account name + "__"`，例如 `__realdebrid__`、`__torbox__`、`__nzb__`，它是根据 providers 配置块生成的。它还决定读取请求发往哪里：即使另一个账户也有同一个资源，并且按配置顺序会优先命中，通过 `__torbox__` 打开的文件仍由 TorBox 提供。如果某个账户的名称与保留名称冲突，它就不会生成这个目录，zurg 会发出警告。根目录下的其他所有内容，都是 `directories:` 配置块中的键，原样使用。

## 9. 用户重命名 {#9-user-renames}

`internal/torrent/rename.go`, `internal/torrent/rename_bulk.go`

重命名只是一个显示层，不会改动 debrid 账户上的任何内容。它存储为 Torrent.Rename 或 File.Rename，优先级高于上面的所有推导规则。只有设置 `ignore_renames: true` 后，zurg 才会完全忽略它。

只有当名称去掉首尾空白后不为空、不包含 `/` 或 `\`、并且与自身的 `filepath.Clean` 结果相同（这也会排除 `.` 和 `..`），而且不与其他哈希已有的访问键冲突时，种子重命名才会被接受。应用重命名时会重新设置目录映射的键，在新名称下写入 `.zurgtorrent`，并且会删除旧名称下的那个文件。如果旧文件留着不删，重启时会两个都加载，重命名就会悄悄恢复原样。

季修复（`/torrents/season-fix/plan` 和 `/apply`）是一个批量文件重命名，依据的是 Plex 自己的剧集匹配结果。plan 只读，会给出每个文件的跳过原因。apply 需要一个明确的哈希列表，而不是一个“全部应用”的开关。仪表盘通过 `/season-fix/` 调用这两个接口，操作员也可以在那里看到映射规则和跳过原因的说明。

## 10. 对集成 zurg 的应用的影响 {#10-consequences-for-anything-integrating-with-zurg}

如果你要根据种子的名称来构建路径（比如符号链接集合、远程路径映射或脚本），以下是常见的出错方式：

  a. 扩展名。只有 `.mkv` 和 `.mp4` 会被去掉，并且区分大小写。其他容器格式的扩展名会保留在文件夹名中。

  b. 重命名。`Torrent.Rename` 的优先级高于推导出的名称，而 RD 自己对种子的重命名会在你不知情的情况下改变 `Name`。

  c. 哈希后缀。两个不同的发布版本如果名称相同，其中一个会变成 ` {a1b2c3}`，而哪一个会带后缀，会随着新内容的加入而变化。

  d. 重复文件标签。发布版本中基础文件名重复的文件，会以 `name (tag).ext` 的形式提供，其中的 tag 是一个目录组件或路径哈希。`filepath.Base(file.Path)` 无法还原这个标签。

  e. 压缩包重命名。压缩包内经过混淆的载荷文件，会以发布版本的名称呈现，而不是它自己的名称。

  f. NZB 的名称来自 `.nzb` 的文件名，而不是它内部的任何内容，除非文件名本身是哈希。文件名决定文件夹名。

  g. 清理后的磁盘文件名与挂载名称属于不同的命名空间，对于非 ASCII 的发布版本，两者有意不一致。

最可靠的做法是先通过哈希定位发布版本，然后向 zurg 询问它的名称。自己去重构名称就是在猜，而上面的每条规则都是猜错的一种方式。
