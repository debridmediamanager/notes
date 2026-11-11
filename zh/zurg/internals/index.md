# 内部机制 {#internals}

zurg 的构造。它的测量数据。那些比较别扭的部分背后的设计思路。这份文档写给即将修改代码的人。运行 zurg 不需要看这些内容。

## 整体结构 {#the-shape-of-it}

| 页面 | 内容 |
|---|---|
| [Architecture](architecture.md) | 整体结构，以及容易被破坏的不变量。建议从这里开始。 |
| [Naming](naming.md) | 一个发布及其文件如何获得挂载中显示的名称。 |
| [Persistent caches](persistent-caches.md) | 哪些内容会在重启之间保存在磁盘上，以及它们带来的开销。 |
| [Directory config UI/UX](uiux.md) | 目录编辑器背后的设计评估。 |

## 测量了什么 {#what-was-measured}

| 页面 | 内容 |
|---|---|
| [Debrid baseline](debrid-baseline.md) | zurg 的成本，以及它在 Real-Debrid、AllDebrid 和 TorBox 上的速度表现。 |
| [Torrent lifecycle](torrent-lifecycle.md) | 抓取过程中每个账户实际上报的内容，实时采集。 |
| [Real-Debrid API notes](realdebrid-behavior.md) | 链接的含义、文件选择，以及 cached 的真正含义。 |

## zurg 必须满足的约定 {#contracts-zurg-has-to-satisfy}

| 页面 | 内容 |
|---|---|
| [SABnzbd client contract](sabnzbd-client-contract.md) | Sonarr 和 Radarr 对 SABnzbd 所期望的确切数据格式。 |
| [qBittorrent client contract](qbittorrent-client-contract.md) | 同上，针对 qBittorrent。 |
| [plex_api.json](../../internals/plex_api.json) | zurg 所依赖的原始 Plex API 接口。1.2 MB。 |

## 出过的问题 {#things-that-went-wrong}

| 页面 | 内容 |
|---|---|
| [Plex trash sweep](plex-trash-sweep.md) | 让清理与 zurg 自身对损坏文件的判断保持一致。 |
| [Stream timeout regression](stream-timeout-regression.md) | 代理的流在长时间读取时不再能持续工作。 |
| [rclone move refusal](rclone-move-refusal.md) | 后端拒绝 MOVE 后导入为空，以及对应的补丁。 |

## 测试 {#testing}

- [E2E 测试](e2e-test.md) 说明了端到端测试套件覆盖哪些内容，以及运行它需要付出什么代价。

某个服务的功能及其限制，请参见 [Providers](../providers/index.md)，而不是在这里。
