# E2E 测试 {#e2e-testing}

端到端测试，用于在部署后验证 zurg 是否正常工作。

## Plex 播放测试 {#plex-playback-test}

通过随机选择一部电影并测试完整的播放流程，验证内容能否通过 Plex 真正播放。

### 运行测试 {#run-the-test}

```bash
./scripts/plex-e2e-test.sh
```

该脚本会自动从 `config.yml` 中读取 `plex_server_url` 和 `plex_token`。

如需使用自定义设置进行覆盖：
```bash
PLEX_URL="http://your-plex:32400" PLEX_TOKEN="your-token" ./scripts/plex-e2e-test.sh
```

### 测试内容 {#what-it-tests}

| Step | Description |
|------|-------------|
| 1 | 通过 Plex API 找到 Movies 库 |
| 2 | 获取电影总数 |
| 3 | 随机选择一部电影 |
| 4 | 获取该电影的流媒体 URL |
| 5 | 验证流可以访问（HTTP 200） |
| 6 | 用 ffmpeg 解码 3 秒视频 |
| 7 | 创建并验证 Plex 会话跟踪 |

### 预期输出 {#expected-output}

```
=== Plex E2E Playback Test ===

[1/7] Finding Movies library...
  Library key: 15
[2/7] Getting movie count...
  Total movies: 1234
[3/7] Selecting random movie...
  Selected: 2 Fast 2 Furious (2003) (ratingKey: 756524)
[4/7] Getting stream URL...
  File size: 54GiB
[5/7] Verifying stream accessibility...
  HTTP Status: 200 OK
[6/7] Decoding video (3 seconds)...
  Decoded 72 frames successfully
[7/7] Testing Plex session tracking...
  Session created and tracked

=== TEST PASSED ===
Movie '2 Fast 2 Furious (2003)' is playable via Plex
```

### 前提条件 {#prerequisites}

- Plex 服务器正在运行并且可以访问
- 已在 `config.yml` 中配置 `plex_server_url` 和 `plex_token`
- 已安装 `curl`、`jq` 和 `ffmpeg`

### 故障排除 {#troubleshooting}

| 错误 | 原因 | 解决方法 |
|-------|-------|-----|
| No movie library found | 库类型不对或库是空的 | 检查 Plex 里是否有名为 "Movies" 的库 |
| Stream not accessible (HTTP 4xx) | 认证或路径有问题 | 确认 token 正确，并且文件确实存在 |
| Failed to decode video frames | 文件损坏或网络有问题 | 查看 zurg 日志，换一部电影试试 |
| Session not detected | Plex 会话超时 | 查看 Plex 日志 |

## 集成测试套件 {#integration-suite}

```bash
ssh zen
cd /path/to/isolated/zurg/source
make integration-test
```

**在 `zen` 上使用一个独立的目标环境运行。** 在那里准备 Go 工具链、shellcheck、rclone 和 .NET move probe。测试套件会自己创建 zurg 进程和挂载点，不需要替换 zen 上正常运行的 zurg 服务或挂载。请为它使用单独的源目录、`TMPDIR`、配置、端口和 `MOUNT_PATH`。运行前先检查临时配置。即使使用私有的 `TMPDIR`，也要保留主机级别的 `INTEGRATION_LOCK_FILE=/tmp/zurg-integration-rd.lock`，这样其他会话仍会和你的测试排队执行。

前置条件不满足的测试可以跳过，并以成功状态退出。请阅读它们的输出，确认 FUSE、rclone、Plex 和 NNTP 确实都运行了。

| 测试 | 需要 FUSE | 需要 Plex | 需要 Usenet 账号 |
|------|:----------:|:----------:|:----------------------:|
| `refresh_repair_integration.sh` | | | |
| `network_test_cache_integration.sh` | | | |
| `rclone_mount_integration.sh` | 是 | | |
| `magic_mount_integration.sh` | 是 | | |
| `magic_move_refusal.sh` | 是 | | |
| `magic_library_move_integration.sh` | 是 | | |
| `plex_integration.sh` | 是 | 是 | |
| `nzb_bench_integration.sh` | | | 是 |

`force_location_integration.sh` **不在**测试套件中。它检验的是这台主机到 Real-Debrid CDN 的网络路径，而不是 zurg 本身。因此无论你改了什么，只要该路径无法响应，它就会失败。如果要运行它，请在一台能通过 IPv4 正常访问目标区域的主机上，使用 `make force-location-test` 手动执行。详见[强制位置集成测试](#force-location-integration-test)。

其中五个使用 Real-Debrid 的测试会操作同一个账号，详见[测试账号是共享的](#the-real-debrid-test-account-is-shared)。基准测试使用的是新闻账号，完全不碰 Real-Debrid，但它同样会获取主机级别的锁。如果它与其他套件同时读取数据，测得的结果就是其他套件的读取表现。

如果 macFUSE 已安装，挂载测试也可以在 Mac 上运行。它已在 macFUSE 和 Linux `fusermount` 上验证过。Plex 测试需要在其临时配置中提供 `plex_server_url` 和 `plex_token`，并且 Plex 必须能够访问挂载点的每一级父目录。如果挂载点位于私有主目录下，测试用户可以正常访问，但 Plex 可能无法访问。

`make integration-test` 会先构建 zurg，再对脚本运行 shellcheck、执行 `lib.sh` 的自检，以及 `integration/nzbbench` 的单元测试，然后按从便宜到昂贵的顺序运行全部七项：网络测试缓存、rclone 挂载、Plex、`__magic__` 挂载、.NET 移动拒绝、刷新/修复，最后是 Usenet 基准测试。最后两项最耗时。刷新/修复要等待完整的媒体库扫描，而基准测试要从新闻服务器上连续读取数GB数据两次。因此，其他任何测试出现的错误都应尽早暴露，而不是让你等到这两项之后才发现。`make integration-test-media` 运行 rclone、Plex 和 `__magic__` 挂载测试，`make nzb-bench-test` 只运行基准测试。

每个脚本都会在 `$TMPDIR` 下使用自己的工作目录、自己的端口，并把 zurg 的日志写到那里。测试套件以 `STREAM_LOGS=false` 运行，因此终端上只会显示测试自身的断言。调试时如果想在标准错误输出中跟踪 zurg 的日志，可以设置 `STREAM_LOGS=true`。

共享辅助函数位于 `integration/lib.sh`（进程控制、Real-Debrid API、磁盘媒体库查询）和 `integration/lib_media.sh`（FUSE 与 Plex）。如需新增测试，请直接引入这些文件，不要复制其他脚本的代码。`integration/lib_test.sh` 用于测试辅助函数本身，不需要账号、不需要网络，大约只需一秒。`integration/nzb_bench_timing_gate_test.sh` 用于检验基准测试包装脚本如何把工具的退出码转换为测试套件的状态含义，它基于 `integration/testdata/` 中一份精简的真实报告运行。这两项都在 `make test-integration-lib` 中运行。

### Real-Debrid 测试账号是共享的 {#the-real-debrid-test-account-is-shared}

这套测试套件使用一个 Real-Debrid 测试账号，而且这个账号并不私有。`zen` 上正在生产环境运行的 zurg 也在监控同一个库，所以它会列出并刷新测试刚刚添加的那些种子。账号上任何**开启了修复（repair）**的实例，也会对它们进行验证、修复和整理。

下面两种故障是在 2026-08-23 诊断的，当时 `macmini` 上的 zurg 以每 10 分钟一次的频率在这个账号上运行修复。该实例已于 2026-08-29 停止，且没有任何进程在监管它；而 zen 的运行使用 `enable_repair: false`。因此截至 2026-09-01，两种故障都没有正在产生的来源。只要这个账号上任何地方重新开启修复，它们就会立刻再次出现，所以下面的串行化要求依然有效。

在六个脚本中有四个在被测构建版本*和*其基线版本上都失败之后，这对一次运行的影响如下：

- **测试夹具始终不出现。** Real-Debrid 会按链接对下载 ID 去重，删除 downloads 行会让所有持有该代码的人都失效。另一个实例的清理操作会撤销本次运行刚刚解析出的代码，本次运行的验证返回 `404 invalid_download_code`，zurg 便把该文件标记为损坏。损坏的种子会在所有列表中被隐藏。随后测试会输出 `zurg serves the fixture over HTTP but it never appeared under .../mnt/movies within 180s`，这看起来像是挂载或 dircache 的 bug，但两者都不是。
- **删除被撤销。** 一个执行修复的实例会把本次运行刚刚删除的种子重新添加回来，于是 `refresh never dropped <hash> after it was deleted from the account` 失败，而此时库本身报告的是真实情况。

受影响最大的是删除和修复相关的断言。在归咎于某个改动之前，请先阅读下面描述的故障上下文。如果一次运行必须是干净的，请先停止其他实例的修复。

**这些脚本中任何两个都不得同时运行**，无论是在本机上，还是来自本机的另一个会话。它们共享该账号每分钟的 API 配额，因此两个同时运行会触发 `API rate limit (code=34)`，断言开始因流量而非行为失败（在 `fun` 上测得，两次并行运行）。另外，每个脚本都是*按哈希*删除种子的，所以一次运行的清理会很乐意删掉另一次运行的测试夹具。因此，每个脚本都会在 `main` 的顶部、第一次 API 调用之前获取一个主机范围的锁，并一直持有到退出为止。

| 变量 | 默认值 | 说明 |
|----------|---------|-------------|
| `INTEGRATION_LOCK_FILE` | `$TMPDIR/zurg-integration-rd.lock` | 锁文件。存在 `flock` 时使用它，否则使用带有进程 ID 标记的 `.d` 目录（macOS 不自带 `flock`） |
| `INTEGRATION_LOCK_WAIT` | `0` | 排队等待正在进行的运行的秒数。`0` 会立即拒绝，这正是你想要的——否则就得在一次冷扫描后面干等一个小时 |

被终止的运行遗留的锁会被自动回收：目录中记录了持有者的进程 ID，而 `flock` 由内核在进程退出时释放。当然，这把锁对 zen 或 macmini 毫无作用，它只负责把本机的运行彼此隔开。

**如何阅读失败信息。** 现在每个 `fail` 都会从该次运行的 zurg 日志中打印：各项共享账号症状的计数（`invalid_download_code`、`hoster_unavailable`、限速相关行、`code=34`、`Link verification failed`、`keeping files as broken`、`broken_file]`、`Deleted downloads entry`），然后是这些行中的最后十行，再接着是最后几行提到被测夹具的日志。`none present, so this failure is probably zurg's own and not the account's` 这一行则提示你应该去检查代码。

`docs/realdebrid-behavior.txt` 中记录了这一切背后的链接语义：哪些链接从哪个账号兑换，以及为什么 `unavailable_file` 和 `hoster_unavailable` 含义不同。

### 运行时长 {#runtime}

第一次对某个工作目录运行时，会进行一次冷启动的库扫描：每个种子调用一次 info，再做一次链接校验，速度受账户 API 配额限制。账户上有几千个种子时，这一步要花几十分钟。这个账户在 2026-08-29 有 3,361 个种子，结果持续出现 `code=34`，一个脚本大约要跑 20 分钟。工作目录会在两次运行之间保留三类缓存，后续运行就能跳过这一步：`info/`、`linkcache/` 和网络测试结果。如果想强制走冷启动流程，删除工作目录即可。

`linkcache/` 由 `internal/debrid.LinkCache` 持久化，每个 provider 实例一个文件。省下那 20 分钟的主要就是它。某个种子第一次出现时，会解析其中一个链接来验证，缓存为空时，每个种子要调用一次 `unrestrict/link`；缓存热的时候，这一步不用调用。不过收益受缓存 4h TTL 限制，第二天重新运行测试套件时又是冷启动，所以它加快的是迭代速度，而不是第一次运行。

`info/` 和 `linkcache/` 都包含链接相关的数据，共享同一账户的其他实例可能会撤销其中的代码。`.zurginfo` 是原样保存的 `TorrentInfo`，因此会带有种子的 Real-Debrid `/d/` 代码；`linkcache/` 则保存这些代码解析后的结果。两者仍然都会保留。重建它们正是耗时几十分钟的原因。被撤销的条目也不算错误答案：验证时会得到 `404 invalid_download_code`，zurg 会让该条目失效并重新生成，所以只有被撤销的条目需要额外调用一次。每次运行都可能会遇到一些，加速效果会随数量变化。

测试夹具的范围还要更窄。`clean_state_for_hash` 会删除哈希匹配的 `info/` 条目，所以它的链接列表总会从账户重新获取。`linkcache/` 是按链接而不是按哈希建立索引的，不会按夹具清理，因此其中某个链接的*解析结果*仍可能来自之前的运行。这里的任何断言都不依赖这一点，因为测试夹具验证的是刷新、路由、挂载和修复；如果某个解析结果已过期，验证会失败，并在任何测试看到它之前重新生成。

### 刷新/修复集成测试 {#refreshrepair-integration-test}

```bash
./integration/refresh_repair_integration.sh
```

在测试用的配置里，自动修复保持关闭。两个明确的 `/manage/{hash}/repair` 请求会绕过这个设置，修复各自的测试数据。
如果开启无人值守修复，还会扫描并改动共享账号里不相关的条目，消耗断言需要的 API 额度。
`refresh_repair_config_test.sh` 会检查生成的配置，不会产生任何 provider 流量。它使用的是 2026-09-10 那次失败中捕获的、已脱敏的测试输入。

| Scenario | Description |
|----------|-------------|
| 1. 自动刷新（添加） | 通过 RD API 添加一个种子，然后等待刷新循环发现它。不能重启，否则测的就是冷加载路径了 |
| 2. 目录分配与路由 | 验证文件会出现在 HTTP/DAV 虚拟目录里 |
| 3. 持久化（重启） | 重启 zurg，确认缓存状态被保留下来 |
| 4. 自动刷新（删除） | 删除种子，然后等待过期键清理把它移除 |
| 5. 触发修复 | 通过 Manage API 触发修复，断言 zurg 记录了它已接受请求，并等待 `ok_torrent`，且损坏文件数为 0 |
| 6. 修复验证 | 修复第二个种子，并对其中一个视频文件做范围请求读取 |

#### 环境变量 {#environment-variables}

| 变量 | 默认值 | 说明 |
|----------|---------|-------------|
| `PORT` | `12345` | 测试用 zurg 实例的端口 |
| `CONFIG_PATH` | `config.yml` | 用来借用凭据的配置文件：`realdebrid` 提供方的 `token`，以及顶层的 `username`/`password` |
| `TEST_HASH` | *(内置)* | 用于刷新测试的种子哈希 |
| `REPAIR_TEST_HASH` | *(内置)* | 用于修复测试、带有损坏分片的种子哈希 |
| `VERIFY_TEST_HASH` | *(内置)* | 用于修复验证测试的种子哈希 |
| `READY_TIMEOUT` | `120` | 等待 zurg 就绪的秒数 |
| `INITIAL_SCAN_TIMEOUT` | `3600` | 等待第一次完整刷新结束的秒数 |
| `REFRESH_TIMEOUT` | `120` | 等待刷新识别到新增或删除内容的秒数 |
| `REPAIR_TIMEOUT` | `300` | 等待修复完成稳定的秒数 |
| `STREAM_LOGS` | `true` | 跟踪 zurg 在 stderr 上的日志 |
| `ZURG_BIN` | `$(pwd)/zurg` | zurg 二进制文件的路径，必须是绝对路径，因为 zurg 是从工作目录启动的 |
| `WORK_DIR` | `$TMPDIR/zurg-refresh-repair` | 工作目录（会在多次运行之间保留） |
| `WORK_DIR_CLEANUP` | `false` | 退出时删除工作目录，同时丢弃让后续运行更快的缓存 |

### 强制位置集成测试 {#force-location-integration-test}

```bash
make force-location-test
```

不属于 `make integration-test`，需要手动运行。2026-08-29 在 `fun` 上测试时发现，强制指定的 `nyk` 主机解析出了 AAAA 记录，而下载客户端通过 `tcp4` 连接，因此每个 HEAD 请求都以 `no suitable address found` 结束。每个请求重试三次，本测试所等待的库扫描会卡住将近一小时，然后才因主机网络问题而失败，而不是因为 zurg。测试在区域不健康时已有跳过逻辑（见下文），但该保护无法覆盖“主机无法通过 IPv4 访问*健康*区域”的情况。

预置一个网络测试缓存，并固定到 `LOCATION`（默认 `nyk`），然后断言通过 zurg 的 `/strm/` 端点解析出的链接会重定向到该位置的下载主机。`MAX_GEO_PROBES`（默认 `4`）限制预置步骤探测的 geo 服务器数量。

设置了 `cdn_host_preference` 后，zurg 验证的每个链接都会走强制指定的区域，因此不健康的区域会让列表为空，失败看起来像是 zurg 的 bug。所以测试会先检查该区域：如果 Real-Debrid 不为其生成链接，或返回的主机不提供数据，则跳过而不是失败。

### 网络测试缓存集成测试 {#network-test-cache-integration-test}

```bash
./integration/network_test_cache_integration.sh
```

运行两次 zurg：第一次启动时必须执行延迟测试，并写入 `data/network_test_results.json`；第二次启动时要直接读取该文件，不再执行新的测试。

### Rclone 挂载集成测试 {#rclone-mount-integration-test}

```bash
./integration/rclone_mount_integration.sh
```

沿着播放器实际走的路径：FUSE → zurg HTTP → Real-Debrid：

| 步骤 | 检查内容 |
|------|-----------|
| 2 | zurg 挂载自己的目录，并记录 `Mount verification successful` |
| 3 | 配置的目录在挂载根目录下可见 |
| 4a–4c | fixture 进入库、通过 HTTP 提供服务，并到达挂载点——分阶段进行，这样一旦失败，就能指出是哪一环出了问题，而不只是报“不在挂载中” |
| 5 | 通过 FUSE 读取文件能拿到真实数据 |
| 6 | 关闭 zurg 后会释放挂载 |

第 4c 步是 VFS dircache 检查：只有当目录列表被失效、而不是沿用 torrent 下载前缓存的列表时，fixture 才能出现在挂载中。

库会用一个由 fixture 自身名称构造的正则表达式来缩小范围，因此挂载里只包含一个发布版本，而不是整个账户。`MOUNT_PATH` 默认为 `$WORK_DIR/mnt`——绝不会是生产环境的 `/mnt/zurg`。`RCLONE_BIN` 默认为 `$(pwd)/bin/rclone`。

### Plex 集成测试 {#plex-integration-test}

```bash
./integration/plex_integration.sh
```

| 步骤 | 断言 |
|------|------|
| 2 | zurg 日志出现 `Successfully connected to Plex server` |
| 3 | 该 fixture 出现在库中；如果它也出现在挂载点里，就必须可读（Plex 以自己的用户身份读取） |
| 4 | 在 `$MOUNT_PATH/movies` 上新建一个一次性的 section |
| 5 | zurg 将其库路径解析到该 section，并**针对 fixture 的路径**排队一次刷新 |
| 6 | Plex 最终为该条目建立索引 |

挂载点里出现这个 fixture 是前提条件，而不是断言本身：
配置了 Plex 后，zurg 还会对整个 Plex 库运行匹配器，这会和刷新操作抢资源，所以 VFS 列表可能落后很久。
测试会明确说明这一点，并在 `MOUNT_VISIBLE_TIMEOUT`（默认 `420`）之后继续执行。步骤 5 和 6 在 Plex 看不到文件时本身就会失败，而验证失效机制是否正常工作是挂载测试的职责。
`PLEX_URL` 和 `PLEX_TOKEN` 会覆盖配置中的 `plex_server_url`/`plex_token`。

Plex 会自动扫描新建的 section，可能在创建命令返回之前就已经扫描完成。
测试会报告这个初始计数；步骤 5 则会独立检查：在明确发出 manage 请求后，zurg 是否排队了正确的路径。

该 section 使用 `agent=tv.plex.agents.none` 和 `Plex Video
Files` 扫描器创建，这样 Plex 会在本地建立索引，不会查询在线元数据 agent。退出时（包括失败时，通过 EXIT trap）它会被删除。不过被 SIGKILL 强制终止时不会执行任何清理，所以在这种运行之后，只检查并删除你自己的 section。测试不会动已有的 section，因为它们可能属于另一个会话。已有的库则永远不会被改动。

步骤 5 通过 `POST /manage/{hash}/scan` 让 zurg 执行这些副作用，而不是等待一次完整的刷新流程。目录分配触发器只会在发现种子时触发一次，而那时 section 必然还不存在。如果等下一次完整扫描，在拥有几千个种子的账户上要花几十分钟。
被测的映射关系没有改变：zurg 仍然需要自己把库路径解析到正确的 section。

### Usenet 基准回归 {#usenet-benchmark-regression}

```bash
./integration/nzb_bench_integration.sh
make nzb-bench-test
```

除此之外，套件里没有其他测试会通过 NNTP 读取任何字节。修改文章抓取器、yEnc 解码器、PAR2 修复或压缩包读取器后，吞吐量可能减半，内存可能翻倍，或者在文章丢失的地方开始输出静音，而其他测试仍然会全部通过。这个测试会通过临时的 scratch zurg 读取四个预先准备好的发布，同时检查数字和字节。

**为什么用 A/B 对比，而不是存一个固定数值。** 新闻服务器上的吞吐量在一个晚上里会波动 10–20%。同一个发布在一次会话里读了六次，速度在 34–50 MB/s 之间。如果拿上周记录的数字做一个很窄的范围，测试会因为网络波动而失败，而不是因为代码有问题。所以这个测试在同一时间窗口、同一台主机上测量两个二进制文件。它会逐轮交替两者的先后顺序，让服务商端的预热效果落到两边，然后比较它们的中位数。

A 是基线：默认是从 `HEAD` 能访问到的最新 `*-nightly` 标签，用 `git archive` 解压后构建一次，然后缓存在工作目录下，后续运行直接复用。B 是候选版本，也就是本仓库刚刚构建出的 `zurg`。**当 B 比 A 差超过 5%（`BENCH_TOLERANCE`）时，该指标判定为失败。** 更好的结果会报告为改进。如果某个指标只在一侧存在，则记为 `n/a`，不算回归。每一轮都会测量以下内容：冷打开、首字节时间、64 MiB 读取、同样 64 MiB 的热状态重读、八点抽查、256 MiB 读取（附带每 GB 的 CPU 秒数和峰值 RSS，仅限 Linux，两者都来自 `/proc`），以及 `ffprobe` 读取到的容器时长。

正确性只针对候选版本进行检查，而且不靠计时。每次读取都会记录一个 md5，它必须和已记录的常量一致，并且两个二进制文件之间也必须一致。受损的发布只能返回原始字节或静音，不能返回其他内容。修复之后，必须能恢复到原始内容，并且在重启后仍然正确。

语料库检入在 `integration/nzbbench/corpus/` 下，包含六个 NZB，各自回答一个问题：

| NZB | 内容 | 用途 |
|-----|------|------|
| `ToyStory5.nzb` | 6.61 GB 的 WEB-DL，1,576 个 4 MiB 文章 | 所有吞吐量和延迟数字，以及 ffprobe 断言 |
| `ToyStory5Damaged.nzb` | 同一个发布，但第 21 篇文章的 message-id 被破坏，因此任何服务器都会返回 `430` | 空洞必须读作原始字节或静音，其他结果都是正确性缺陷。随后 PAR2 必须修复它，并且修复结果在重启后依然有效 |
| `Obfuscated.nzb` | 同一部电影被拆成七个文件，文件名为 `<hex> [n/7] yEnc`，真实名称只能从 PAR2 索引中恢复 | 命名检查：必须以真实的 `.mkv` 文件名、正确的大小列出，并且不能看到任何 `.par2` 文件 |
| `FatherBrown.nzb` | 一个 11 卷的 RAR，包含一集剧集、一个 `Sample/` 目录和一个 nfo | 压缩包读取器：文件夹结构必须保留，压缩包内部的读取有自己的吞吐量数字（`rar_read_MBps`，每轮一次读取） |
| `WrongTurn3.nzb.gz` | 一个 58 GB 的 stored 7z，分为 54 卷，每卷 1 GiB（最后一卷较小），另外还有七个 PAR2 文件，是一个完整的 UHD BluRay 目录树。因为 NZB 原文有 7 MB，所以使用 gzip 压缩 | 分卷 7z 读取器：分卷必须先拼接起来，并在列出任何内容之前读取最后一卷末尾的文件头。计时的正是这个列出过程（`sevenzip_list_s`，每轮从清空的布局开始测一次）。随后，57.6 GB 的正片流必须在 8 GiB 位置返回 16 MiB，并且 md5 与记录的一致。这是正确性检查，不是计时检查。这里没有吞吐量数字，因为这个发布的每个分卷在该服务商上都缺失约五分之一的文章，计时读取测到的其实是空洞探测的耗时 |
| `NestedRar.nzb` | 一个两张光盘的 XviD 重新发布：一个外层 RAR5 分卷集，其成员是另外两个 RAR 集的分卷，分别位于 `CD1/` 和 `CD2/` 中，另外还有一个 `Sample/` 片段和一个 nfo | 嵌套压缩包读取器：两个内层集合都必须被打开。扁平测试会拒绝两个可比较的集合，而发布者的目录结构正是用来区分它们的。两部电影都必须按真实大小列出，并且各自有自己的吞吐量数字（`nested_read_MBps`，每轮一次读取） |

**一个账号，一个实例。** 同一个新闻账号上的第二个 zurg 会和第一个争抢连接配额。服务器会拒绝*较早*的那个连接。在 `fun` 上，生产环境中的 `zurg-usenet` 占满了该账号套餐允许的所有连接，所以基准测试只使用 10 个连接（`BENCH_NNTP_CONNECTIONS`）。如果返回 `Too many connections` 拒绝，结果会报告为**跳过，而不是失败**。服务器不可达或 `AUTHINFO` 被拒绝，情况也一样：环境无法回答这个问题，所以测试会直接说明，而不是怪到构建上。

默认四轮大约需要 15–20 分钟。另外，第一次需要构建基线时，还要额外花几分钟。

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `12358` | 基准测试 zurg 实例使用的端口（同一时间只运行一个） |
| `WORK_DIR` | `$TMPDIR/zurg-nzb-bench` | 保存生成的配置、两个二进制文件的运行目录和日志、`report.json`，以及缓存的基线二进制文件。会在多次运行之间保留。持久化的 `data/` 让后续轮次测的是重启，而不是冷启动学习 |
| `BENCH_ENV_FILE` | `~/.config/zurg/bench-account.env` | 账号文件，存在时会被 source 加载。内容是 `BENCH_NNTP_*` 变量的 `KEY=value` 行。**这是为基准测试单独提供账号的推荐方式**，也能让凭据不进入仓库，也不会留在 shell 历史里 |
| `CONFIG_PATH` | `config.yml` | 当环境变量和账号文件都没有指定时，从这个配置里借用新闻账号：取第一个 `type: nzb` 提供方的 `nntp:` 块。如果该账号在这里已经有打开的连接，则拒绝借用，见下文 |
| `BENCH_NNTP_HOST` / `_PORT` / `_TLS` / `_USER` / `_PASS` | *（优先来自 `BENCH_ENV_FILE`，其次来自 `CONFIG_PATH`）* | 新闻账号信息。导出的环境变量优先级高于账号文件。任何地方都找不到时 → 跳过 |
| `BENCH_NNTP_CONNECTIONS` | `10` | 基准测试打开的连接数。这是上限：如果账号配置的连接数更少，则保留账号自己的数字 |
| `BENCH_ALLOW_SHARED_ACCOUNT` | *（未设置）* | 设为 `1`，允许在已经有连接打开的借用账号上运行基准测试。仅在你确认账号有足够余量时使用 |
| `BASELINE_REF` | `HEAD` 能访问到的最新 `*-nightly` | 用来对比的目标。会在尽力执行的 `git fetch --tags` 之后解析 |
| `BASELINE_BIN` | *（从 `BASELINE_REF` 构建）* | 预先构建好的基线，会原样使用。适用于在这里已经无法构建的对比对象 |
| `BENCH_REPS` | `4` | 每个二进制文件的轮数。中位数基于这些轮次计算 |
| `BENCH_TOLERANCE` | `0.05` | B 允许比 A 差多少，超过后才算回归 |
| `BENCH_SKIP` | *（无）* | 要跳过的阶段，用逗号分隔：`repair`、`obfuscated`、`rar`、`ffprobe`。如果 `PATH` 和 `bin/` 中都找不到 `ffprobe`，则会自动加入它 |
| `REPORT_JSON` | `$WORK_DIR/report.json` | 报告的输出位置 |
| `STREAM_LOGS` | `true` | 在 stderr 上跟踪候选版本的 `zurg.log`。无论如何，工具自己的进度都会打印 |

`report.json` 保存了两个二进制文件每一轮的所有数据、中位数、每个指标的判定结果、两个二进制文件的 `version` 输出，以及主机和操作系统信息。这样，报告中的任何数字都能对照生成它的代码来解读。如果只想记录一组数字而不做对比，可以直接调用工具并只传一个 `--bin`。它会完成测量、写出 JSON，然后以 0 退出：

```bash
cd integration/nzbbench && go build -o /tmp/nzbbench . && cd -
/tmp/nzbbench --config /path/to/a-config-with-an-nzb-provider.yml --port 12358 \
  --corpus integration/nzbbench/corpus --work /tmp/nzbbench-record \
  --bin candidate=./zurg --out /tmp/record.json
```

配置文件必须是你自己的。包装脚本生成的那份配置里带有新闻账号的明文密码,并且运行结束后会被删除。

`integration/nzbbench/README.md` 记录了该工具自身的参数和退出码。

**`nzb_bench_integration.sh` 的退出码。** `0` 表示比较已完成且通过,或者主机根本无法进行基准测试,因此本次运行被跳过;`1` 表示某个功能断言失败,或某项指标出现回退;`4` 表示所有功能断言都通过了,但计时检查**未作判定**。原因是在测试窗口内新闻服务器超过了该工具的稳定性上限,所以吞吐量和延迟的比较结果被丢弃了。4 特意既不同于代表构建有问题的 1,也不同于代表跳过的 0:性能方面没有得出任何结论,处理办法是在更空闲的时段重新运行。运行时会打印一个横幅,指出是哪项检查,以及哪些波动范围导致它未通过。`make integration-test` 会把任何失败的配方行转成 make 自己的退出码 2,所以套件运行时你看到的是 make 返回非零值,再加上这个横幅,而不是该目标输出的 "All integration tests passed." 行。如果需要根据 4 本身做分支判断,请直接调用该脚本。

### 前提条件 {#prerequisites-1}

- Real-Debrid 令牌，写在 `config.yml` 里（作为 `realdebrid` provider），或者设置 `RD_TOKEN`
- `curl`、`python3`，以及一个已构建好的 zurg 二进制文件
- 运行 `make lint-integration` 需要 `shellcheck`（如果没装，会显示一条提示并跳过）
- 挂载和 Plex 测试需要：`fusermount`/macFUSE、一个 rclone 二进制文件，以及在 `/etc/fuse.conf` 里开启 `user_allow_other`，这样 Plex 才能读取挂载点
- 运行 move 拒绝检查需要：来自 `scripts/build-rclone-move-fix.sh` 的修正版 rclone，并且要同时通过 `RCLONE_BIN` 和 `RCLONE_TEST_BIN` 进行设置。仅仅是较新的未打补丁的上游 rclone 是不够的。详见 [MOVE 回归问题](rclone-move-refusal.md)。你可以通过 `DOTNET_MOVE_PROBE_BIN` 提供一个预编译的辅助程序，也可以使用 Docker 来构建它。如果以非特权容器用户身份构建，需要为 .NET 同时提供一个可写的 `XDG_DATA_HOME`，以及它的 CLI 和 NuGet 缓存目录。
- 运行 Usenet 基准测试需要：一个新闻服务账号，以及 Go、`git`、`tar` 和 `make`。它会基于某个 nightly 标签的 `git archive` 来构建基线。

### 为基准测试单独准备一个新闻账号 {#give-the-benchmark-its-own-news-account}

连接配额属于**账户**，而不属于某个进程。如果让基准测试指向生产实例已经在用的账户，两者就会共同占用这份配额。这时服务器会拒绝*更早建立的*连接，也就是生产实例的连接，而生产实例完全不知道是基准测试造成了这个问题。

所以，基准测试只在没有其他选择时才会借用 `CONFIG_PATH` 中的账户，并且**拒绝借用在本机上已经有连接打开的账户**。最好在 `~/.config/zurg/bench-account.env` 中为它配置一个专用账户：

```
BENCH_NNTP_HOST=news.example.net
BENCH_NNTP_PORT=563
BENCH_NNTP_TLS=true
BENCH_NNTP_USER=...
BENCH_NNTP_PASS=...
BENCH_NNTP_CONNECTIONS=25
```

选一个有余量、且没有其他服务依赖的账户。也就是说，这个服务器的实测上限要远高于任何实例的配置值，这样基准测试就不会挤占读取服务的连接。在命令行中导出的变量优先级高于该文件。如果你已经确认有足够的余量，可以设置 `BENCH_ALLOW_SHARED_ACCOUNT=1` 来覆盖这一拒绝规则。

### 不在套件中 {#not-in-the-suite}

`rename_integration.sh`、`tag_stats_integration.sh` 和 `test_repair_verification.sh` 不会被 `make integration-test` 运行。它们还带着自己那份旧的辅助函数副本，都是 `lib.sh` 出现之前的版本。先把它们迁移到 `lib.sh` 上，并分配互不冲突的端口，然后再接入测试流程。
