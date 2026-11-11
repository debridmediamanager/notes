# 让 Plex 清理扫描与 zurg 自身的文件状态保持一致 {#aligning-the-plex-trash-sweep-with-zurgs-own-file-status}

## 本文档的用途 {#purpose-of-this-document}

Plex 的 trash sweep 目前决定从 Plex 库中删除什么，依据是**文件是否存在加上一个时间计时器**。zurg 其实已经知道一件更有用的事：这个文件背后的内容是还能修复，还是已经永久失效。但它目前并没有用上这份信息。

这份文档是用来代替计时器的方案。它需要在**写任何代码之前**先过一遍，因为这次改动决定了哪些内容会从媒体库里删掉。现在的行为在两个方向上都有问题：它要等两周才删除第一天就已经确定失效的内容，同时又会删掉 zurg 还在积极修复的内容。

文档里记录了我们在代码中和一个正在运行的媒体库上确认过的内容，也写明了打算做什么，以及刻意不改什么。下面所有作为事实陈述的内容，都是在 2026-08-16 对正在运行的系统做过核对的，不是从命名上推断出来的。

范围：`internal/plexsweep`、`internal/plexdb`，以及 `internal/torrent` 中一个新的只读查询。修复行为本身不做改动。

---

## 1. 背景——已上线的内容，以及为何需要重新审视 {#1-background--what-shipped-and-why-it-needs-revisiting}

下面四个提交落地了这次清理功能：

| 提交 | 内容 |
|---|---|
| `4737b677` | 当 Plex 的 `autoEmptyTrash` 开启时发出警告 |
| `020042a3` | 清理程序（sweeper）：检测、防护、修复和逐项删除 |
| `51cc9f69` | Dashboard 配置界面和文档 |
| `1a481a8f` | 修复也计入上限，而不只是删除 |
| `c6f41621` | `plex_trash_sweep_min_age_days`，默认 14 |

清理的核心原则不变，依然是：**只要还有文件的内容，永远不会被删除。**
有有效文件的条目会被修复，或者保留原样、保留回收站图标。
包含有效剧集的 Shows 和 Seasons 永远不会被触碰。
删除是逐项进行的，绝不使用 Plex 的整库 `emptyTrash`。

这次重新审视的，只是*何时可以删除真正缺失的条目*这一规则。

### 计时器只是对 zurg 能直接回答的问题的一种近似 {#the-timer-is-a-proxy-for-a-question-zurg-can-answer-directly}

`plex_trash_sweep_min_age_days` 在删除条目前会等 14 天，理由是：红色垃圾桶图标是运维人员得知内容丢失的唯一提示，直接清除条目就会把这个提示销毁掉。

这个初衷是对的，但实现方式是猜的。它在两个方向上都有问题：

- 被标记为 `infringing torrent` 的种子**立即就已经失效**。让它的 Plex 条目再保留两周毫无意义，等也不可能让它恢复。
- 仍在重试中的种子，恢复可能需要**超过 14 天**。定时器会在 zurg 还在处理它的时候删掉条目。这是更严重的错误，因为它会删掉一个之后又会回来的内容的库条目。

---

## 2. 已验证的事实 {#2-verified-facts}

### 2.1 zurg 的状态模型 {#21-zurgs-state-model}

在 `internal/torrent` 中（不含测试）共有三种文件状态和两种种子状态：

| 层级 | 状态 |
|---|---|
| `File.State` | `ok_file`、`broken_file`、`deleted_file` |
| `Torrent.State` | `ok_torrent`、`broken_torrent` |

这两者都是 `pkg/fsm` 状态机。`FSMWithTime` 会记录每次状态切换的 unix 时间戳，并支持 `SinceWhen`，所以“这个东西已经坏了多久”其实已经能查到，不需要再额外添加任何东西。

**一个损坏的文件会让整个种子被判定为损坏。**
`MarkFileBrokenAndEnqueueRepair`（`internal/torrent/hooks.go:215-234`）：

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

日志里写的是 *"has broken file"*，用的是单数。十个文件里坏一个和十个全坏，产生的种子状态完全相同。没有任何东西会汇总文件状态。

**`Unfixable` 是按账户汇总的，而不是按文件。**
`markAsUnrepairable`（`internal/torrent/unplayable_unrepairable.go:44-71`）：

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

当**已经没有任何可修复的副本**时，这条记录才会被判定为不可修复。之所以不采用“每个副本都带有原因”这种判断，是有意为之的。否则，一个本来就无法修复的副本（比如 Usenet 后端没有 magnet 添加器）会让这个已经失效的资源永远留在可修复的候选列表里。`File` 上根本没有不可修复字段（`internal/torrent/file_types.go`）。

所以这三个层级回答的是三个不同的问题，而且**它们都没有回答影响范围**：

| 层级 | 能告诉你 | 无法告诉你 |
|---|---|---|
| `File.State` | 这个文件是正常、损坏还是已删除 | 它是否已经永久失效 |
| `TorrentCopy.UnrepairableReason` | 这个账户上的副本已经失效 | 其他账户的任何情况 |
| `Torrent.UnrepairableReason` | 没有任何账户能修复它 | 这个资源受影响的程度有多大 |

### 2.2 实时测量（生产媒体库，2026-08-16） {#22-live-measurements-a-production-library-2026-08-16}

仅统计损坏的种子,它们约占库的 **3%**。

**几乎所有损坏的种子(98%)都带有 `Unfixable` 原因**:

| 原因 | 占损坏种子的比例 |
|---|---|
| stalled download | 38% |
| infringing torrent | 37% |
| repair failed | 15% |
| duplicate file IDs (pack torrent) | 4% |
| rar'ed by RD | 1% |
| repair failed, no seeders | 1% |
| the lone cached file is broken | 不到 1% |
| invalid file ids | 不到 1% |
| repair failed, download status: error | 不到 1% |
| provider cannot re-add torrents | 不到 1% |

**其余 (2%) 损坏的种子没有原因**,仍然可以修复。

**但 `Unfixable` 不等于已经死亡。** zurg 已经把这些原因分成了永久和可恢复两类(`internal/torrent/unrepairable_reasons.go:44-70`)。`permanentReasons` 里有八种结论,任何重试都改变不了:infringing、unsupported、unavailable、invalid、too big、not allowed、no repairable files、invalid file ids,另外还有所有以 `repair failed, download status:` 开头的原因。其余的都明确算作临时性的,包括前面两个最大的类别:`stalled download`、`repair failed`、`duplicate file IDs`、`rar'ed by RD`、`not cached`、`the lone cached file is broken`、`full torrent repair failed`。

上面这些比例统计的时候,`repair failed, no seeders` 还是第九种永久性结论。但这里出现这个原因的条目说明它已经不是了:没有一个 zurg 支持的后端会报告做种者数量,所以这个结论从来没有被实际测量过,只是根据修复因为超时而跑不完推断出来的。现在它是临时性的,而且除此之外还无法被记录(`verdictClaims`),所以这些条目会退役,并像其他条目一样再次尝试。

按照这个划分来看上面的比例:

| | 占损坏种子的比例 |
|---|---|
| 永久无法修复 | **39%** |
| 无法修复但可恢复 | **59%** |
| 损坏,尚无原因 | 2% |

无法识别的原因(`provider cannot re-add torrents`,这里只有一条)既不在这两个列表里,`IsPermanentlyUnrepairable` 对它返回 false。这是保守的答案,也是我们想要的。

这是这个设计里最重要的发现:**如果规则只看 "`Unfixable` 是否已设置",会把 Plex 里的条目删掉,而数量是真正已死种子的两倍半多。**

关键在于这些损坏的种子相对于挂载点处于什么位置:

| | 占损坏种子的比例 | Plex 看到的情况 |
|---|---|---|
| 损坏,**仍在挂载点上** | 大约四分之三 | 文件看起来存在 → 从不会被标记为墓碑。没有垃圾桶图标,只会在播放时失败 |
| 损坏,**已从挂载点消失** | 大约四分之一 | 文件缺失 → 被标记为墓碑 → **这些是清理任务的候选对象** |

这是关键的测量结果。它意味着清理任务只会遇到第二组,而对于这一组,zurg 通常已经持有结论。

Plex 这边,同一台主机:有一批已移入回收站的剧集,**没有一个**超过 14 天的窗口期(最早的墓碑是 2026-08-11)。另外还有少量空的剧集外壳,以及几十个空的季外壳。

---

## 3. 差距 {#3-the-gap}

`broken_torrent` 表示“至少有一样东西出了问题”。这对清理任务来说粒度不对。

举个具体例子：一个十集的合集里，有一集的文件永久丢失了，但整个种子作为一个整体仍然可以修复。问种子本身，它会返回“仍可修复”，所以清理任务会把那一集失效的 Plex 条目**永远**保留下去。

目前没有一种状态能区分“整个发布都已失效”和“发布中有某些内容损坏”。

---

## 4. 设计 {#4-design}

### 4.1 不新增第四种持久化状态 {#41-do-not-add-a-fourth-persisted-state}

显而易见的做法是新增一个种子状态，比如 `dead_torrent` 之类的。**否决。**

每个会切换种子状态的地方都得维护它，而一个过期的“all files broken”标记，比没有标记还糟，因为它会*授权删除*。这些信息其实已经存在于文件状态里，只是没有被汇总起来。

那就改成实时推导：

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

计算开销小，结果始终一致，而且不用持久化也能在仪表盘上显示。

实现时需要确定的定义：`deleted_file` 和 `broken_file` 一样，都要算作“不可读”；而一个**零文件**的种子必须返回 false，而不是空真。一个空的发布内容，不能证明它已经“死了”。

### 4.2 先询问文件，回退到种子 {#42-ask-the-file-fall-back-to-the-torrent}

Sweep 会先把 Plex 路径解析为 zurg 文件，然后按以下规则处理：

| zurg 的判定 | 清理操作 |
|---|---|
| 文件为 `ok_file` | **保留**，它并没有真的丢失 |
| `broken_file`，种子没有任何不可修复的原因 | **保留**，修复可能会恢复它，不管要等多久 |
| `broken_file`，设置了原因但**不是**永久性的 | **保留**，zurg 仍认为它可以恢复 |
| `broken_file`，原因是**永久**不可修复 | **删除**，任何重试都无法改变这个判定 |
| zurg 中没有该路径对应的种子 | **回退到存在时间窗口** |

永久性判断使用 `IsPermanentlyUnrepairable(reason)`（`internal/torrent/unrepairable_reasons.go:59`），用法与 `ForceRepairTorrent` 完全一致。直接复用它，而不是重新整理一份列表，这一点很重要：以后往 `permanentReasons` 里添加的原因，应该自动改变 Sweep 的行为；而无法识别的原因则必须保持为非永久性。

`AllFilesBroken()` **本身不能**授权删除。一个整体损坏、但原因仍可恢复的发布，依然在处理中。它的作用是完善报告和仪表盘，并让人在看日志时能分清"十集里坏了一集"和"整个合集都没了"。

最后一行解释了为什么 `plex_trash_sweep_min_age_days` 要保留。种子一旦从账户中彻底移除，它的 `.zurgtorrent` 也会一起消失，这时 zurg 已经无法提供任何判断。因此，这个计时器不再是主要规则，而只作为回退，用于确实没有更好选择的那种情况。

这也会在界面中降低该设置的地位。界面上的标签 "Keep Broken Entries Visible" 描述的是副作用而不是实际操作，这个问题也一并解决了。

### 4.3 路径 → 种子 → 文件查询 {#43-path--torrent--file-lookup}

现有的 Plex 匹配器方向相反：`buildPlexDirIndex`（`internal/plex/matcher.go:539`）为 Plex 路径的各个组成部分建立索引，再用种子的 key 去查找。清理扫描需要反过来做，思路相同：

1. 从 `DirectoryMap.Get(INT_ALL)` 构建 `map[strings.ToLower(GetKey(torrent))] *Torrent`。
2. 对一个 Plex 路径，用与 `splitPathComponents`（`matcher.go:525`）相同的规范化方式拆分成各个组成部分，逐一查找。命中的那个组成部分就是发布目录。
3. 在该种子内，将剩余的路径尾部与 `File.Path`（`internal/debrid/types.go:133`）匹配，从而定位到具体文件。

之所以必须通过 `TorrentManager` 走，而不是对 `data/*.zurgtorrent` 做字符串匹配，原因是：消歧义后的名称（`Some.Release {a1b2c3}`）、多账号副本和重命名，只有通过 `GetKey` 才能正确解析。

**查找失败不等于可以删除。** 无法解析 → 视为 "zurg 没有意见" → 按时间窗口回退。

### 4.4 不变更的部分 {#44-what-does-not-change}

- 不变量:只要还有活动文件的内容,就一律不删除。
- 有活动后代的剧集和季度,绝不处理。
- 逐项使用 `DELETE`,绝不使用 `emptyTrash`。
- 防护条件:rclone 已托管且正在运行、挂载可读、Plex 没有在扫描。
- 任何更改之前先做快照;上限同时约束修复和删除。

这些新规则只会让清理操作**更**保守或**更**精确——它们绝不会授权当前代码会拒绝的删除操作。

---

## 5. 实施计划 {#5-implementation-plan}

| # | 步骤 | 文件 |
|---|---|---|
| 0 | 在删除任何内容之前，先对真实库做一次试运行（dry-run）计数，确认永久/可恢复的划分是正确的门槛 | — |
| 1 | `AllFilesBroken()` 加单元测试（空版本、混合、全部损坏、全部已删除） | `internal/torrent/` |
| 2 | 只读状态查询：路径 → 种子 → 文件，返回一个小的判定值 | `internal/torrent/` 或 `internal/plexsweep/` 中的新文件 |
| 3 | 定义判定类型（`StatusOK`、`StatusRecoverable`、`StatusPermanentlyDead`、`StatusUnknown`），让清理逻辑不直接处理 zurg 内部细节 | `internal/plexsweep` |
| 4 | 把查询接入 `Sweeper`，通过接口实现，和 `Mount`/`Library`/`Trash` 现在的做法一样 | `internal/plexsweep/sweep.go` |
| 5 | 应用决策表；保留时间窗口作为 `StatusUnknown` 的回退方案 | `internal/plexsweep/sweep.go` |
| 6 | 在调用处注入 `TorrentManager` | `internal/app.go` |
| 7 | 测试：决策表的每一行各一个，外加一个查询失败的测试，证明无法解析的情况绝不会删除 | `internal/plexsweep/sweep_test.go` |
| 8 | 文档：`docs/config.md`、`config.example.yml`、`docs/CHANGELOG.md`，并重新措辞仪表盘标签 | 文档 + 模板 |

排序说明：步骤 1–3 是纯新增，不改变行为，可以合并为一次提交；步骤 5 是唯一会改变删除内容的一步。

## 6. 风险与待解决问题 {#6-risks-and-open-questions}

1. **接线顺序。** 已确认:`startPlexTrashSweep` 在 `internal/app.go:268` 被调用,而 `TorrentManager` 在 `internal/app.go:285` 才被构造,排在它之后。调用必须移到它之后,或者改用 setter。需要检查是否有其他东西依赖当前的位置。

2. **查找歧义。** 两个 torrent 的 key 与同一个路径组件冲突。处理方式:如果匹配到的候选项不止一个,就按 `StatusUnknown` 处理,而不是随便挑一个。

3. **`only_show_the_biggest_file`。** 电影目录会隐藏部分文件,所以 Plex 中的路径可能指向的并不是 zurg 实际提供的那个文件。查找时不能假定 Plex 的文件名会原样出现在 `File.Path` 中。

4. **开销。** 每次扫描都构建 key 索引,复杂度是 O(库大小)。在几千个 torrent 的规模下这没什么问题,而且扫描每天只跑一次。应该每次扫描构建一次,而不是每个条目构建一次。

5. ~~**`Unfixable` 会被清除吗?**~~ **已解决:会。** `refresh.go:851-857` 在 torrent 校验通过、回到 `ok_torrent`("all links intact, no broken files")时会清除它;`repair.go:165-181` 在强制修复时会清除它,包括条目本身和所有副本。所以恢复的版本不会带着过时的判定,设计上也不需要防范这种情况。

6. **损坏但仍存在的 torrent。** 不在本次范围内:Plex 从不会把它们标记为已删除,所以扫描也永远看不到它们。值得注意的是,在播放失败之前,它们对 Plex 和本功能来说都是不可见的。

## 7. 实施经过（2026-08-16） {#7-how-it-was-implemented-2026-08-16}

已合并为 `feat: decide plex trash sweep removals from zurg's repair verdicts`。

凡是实现过程中解决了本文档未决的问题，或偏离了 §4 的地方，都在下面列出决定及原因：

- **查找时会将路径的父目录与 `DirectoryMap[INT_ALL]` 做精确匹配**，而不是逐个扫描路径的每一段（§4.3）。挂载点以扁平方式组织资源，即 `<library dir>/<key>/<visible name>`，而 Plex 记录的路径来自挂载点，挂载点会原样提供 key。精确未命中时返回未知，key 冲突的歧义（风险 2）也随之消失：精确的 key 不会发生冲突。
- **决策表第 1 行已修改。** 一个 `ok_file` 如果在挂载点上仍然缺失，说明它是被过滤器隐藏了，而不是"确实已经没了"。如果一直保留，过滤器改动后 Plex 里就会留下一个永久的垃圾桶图标。因此它改为回退到时间窗口判断。
- **`deleted_file` 在每条规则中都与 `broken_file` 一同计算**，而不只是在 `AllFilesBroken()` 中。表中各行写的是"非 `ok_file`"。
- **多版本项目以整体为单位判断**（表格原本是按文件判断的，而清理扫描的单位是带有多个 part 的 Plex 项目）。只要有一个 part 可恢复，整个项目就保留；只有当所有 part 都已失效时，该项目才算失效；其他任何混合情况都回退到时间窗口判断。
- **文件名对应到一个种子、却对应不到具体文件时**（重命名、压缩包列表、`only_show_the_biggest_file`，即风险 3）：只有当该条目的原因是永久性的**且** `AllFilesBroken()` 为真时才判为失效；如果种子已损坏但没有永久性判定，则判为可恢复；其他情况判为未知。只要仍有任何文件可读，无法匹配的文件名就不会因关联关系而被判定为失效。
- **接线（风险 1）：** `startPlexTrashSweep` 已移到 `internal/app.go` 中管理器构造之后；原先的位置没有任何依赖。判定结果通过 `plexsweep.Verdicts` 传给清理扫描，由 `TorrentManager.FileStatusForMountPath` 实现。在第一次刷新填充 `INT_ALL` 之前，所有查找都返回未知，清理扫描的行为与原先的按时间窗口版本完全一致。

## 8. 明确排除在范围之外的内容 {#8-explicitly-out-of-scope}

- **空的剧集和季壳。** 清理只会删除叶子（也就是单集），所以一个完全失效的剧集会留下空壳（在实测的库里，有几部剧和几十个季）。这是单独的问题，需要小心处理顺序：先删除叶子，再重新检查父级，只有子项数量为零时才删除父级。
- 任何对修复行为、修复队列，或 zurg 何时把某个内容标记为无法修复的改动。
- Plex 自己的 `autoEmptyTrash`，已经由 `4737b677` 中的警告处理。
- 实测库中现有的积压内容，我们有意留给人工决定。
