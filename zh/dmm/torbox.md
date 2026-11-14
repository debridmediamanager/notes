# DMM 中的 TorBox {#torbox-in-dmm}

DMM 需要 TorBox 的付费套餐：Essential、Standard 或 Pro。请把你的 API key 从 [torbox.app/settings](https://torbox.app/settings) 粘贴到 DMM 的 **Connect Torbox** 页面，然后搜索。TorBox 已经有缓存的资源会显示 **Instant TB**。免费套餐没有 API 访问权限，所以 DMM 无法使用它；而要把 Usenet 资源发送到 TorBox，则需要 Pro 套餐。

## 登录 {#sign-in}

1. 在 [debridmediamanager.com](https://debridmediamanager.com) 上点击 **Login with Torbox**。如果你已经用其他服务登录过，请在首页打开 **Debrid services**，然后点击 **Torbox Login**。
2. 点击 **Get API Key from Torbox**，它会打开 [torbox.app/settings](https://torbox.app/settings)，你的 API 密钥就在那里。
3. 将密钥粘贴到 **API Key** 中，然后点击 **Save API Key**。

![DMM's Connect Torbox page turning down a free-plan key, key blurred](../assets/dmm-torbox/01-free-plan.webp)

登录后，首页会显示 **Cast for TB** 和 **Requests**，**Debrid services** 会列出你的 TorBox 账户并带有 ✓。点击它可以查看你的套餐以及何时到期，或者点击 **Add another account** 添加其他账户，或点击 **Logout** 退出。

## 各套餐能做什么 {#what-each-plan-can-do}

| | Free | Essential or Standard | Pro |
|---|---|---|---|
| 登录 DMM | 否 | 是 | 是 |
| **Instant TB**、**DL with TB**、库以及 **Cast (TB)** | 否 | 是 | 是 |
| 将 Usenet 资源发送到 TorBox | 否 | 否 | 是 |
| 同时下载数量（TorBox 的活动槽位） | 1 | 3 或 5 | 10 |

如果用免费套餐的密钥登录，DMM 会提示 **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** TorBox 官方的[定价页面](https://torbox.app/pricing)显示，免费套餐不包含 API 访问，Usenet 仅在 Pro 套餐中提供。

## 查找 TorBox 已有的内容 {#find-what-torbox-already-has}

1. 搜索一部电影或剧集并打开它。
2. DMM 会向 TorBox 询问哪些版本已经缓存。这些版本会显示 **Instant TB** 和 **Cast (TB)**，并排在最前面。结果上方的 **TB ✓** 标签只显示这些版本。它会在过滤框里写入 `is:tb`；再点一次即可显示全部。
3. 点击 **Instant TB**，该版本会立即出现在你的 TorBox 库中。

![Night of the Living Dead (1968) on DMM with TorBox: Instant TB, Cast (TB) and DL with TB](../assets/dmm-torbox/02-results.webp)

TorBox 没有的版本会显示 **DL with TB**。点击后，TorBox 会先下载该版本，下载期间会占用你的一个活动槽位。大小旁边显示 **No seeders**，表示目前没有人分享它，可能永远无法下载完成。TorBox 总是会添加整个版本，无法只选择单个文件。

## 你的库 {#your-library}

按下 **Library**。它会列出你的 TorBox 种子和网页下载。

- **TB Add** 会打开 **Add to your TB library**。你可以粘贴磁力链接、上传 `.torrent` 文件，或粘贴直接下载链接，TorBox 会把这些链接作为网页下载来获取。
- **Backup** 会把你的列表保存到文件中。**TB Restore** 会把保存的列表重新添加回来。
- 其余功能与其他服务相同：请参阅 [your library](index.md#your-library)。

你发送到 TorBox 的 Usenet 下载不在 DMM 的库中。你可以在 TorBox 网站上找到它们，也可以在 Stremio 中的 DMM Cast 的 **DMM TB Library** 行里找到，或者通过 zurg 的 [TorBox 托管的 Usenet](../zurg/providers/torbox-nzb.md) 找到。

## 在 Stremio 中观看 {#watch-in-stremio}

在首页点击 **Cast for TB**，然后从那里安装插件。接着在 TorBox 已缓存的任意资源上点击 **Cast (TB)**。所有步骤都写在 [在 Stremio 中使用 DMM](stremio.md) 中。

在 Stremio 里，这个插件名为 **DMM Cast for TorBox**。它的 **DMM TB Library** 一行会列出你的 TorBox 种子，以及已完成的网盘和 Usenet 下载。

## 将 Usenet 资源发送到 TorBox（Pro） {#send-usenet-releases-to-torbox-pro}

1. 打开一部电影或剧集，然后点击 **Usenet** 标签。
2. 使用 TorBox Pro 时，列表标题为 **Send to TorBox**，每个版本旁边都有一个 **TorBox** 按钮。点击它。
3. DMM 会告诉你 TorBox 对它做了什么：
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![DMM's Usenet tab with TorBox Pro: Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

也登录了 Real-Debrid？列表标题会变成 **Send to Real-Debrid or TorBox**，并且会同时显示两个按钮。行末的文件图标则会改为保存 NZB 文件。刚接触 Usenet？先看看 [Usenet 新手入门](../guides/usenet-for-beginners.md)。

TorBox 会在缓存某个 Usenet 下载 30 天后将其删除。想要再次获取的话，重新发送一次即可。

## 用 TorBox 补全请求 {#fill-requests-with-torbox}

Real-Debrid 用户可以在 DMM 的[求片板](https://debridmediamanager.com/requests)上请求资源。在首页点击 **Requests**，然后对 TorBox 已缓存的资源点击 **Fulfil**。资源会从你的 TorBox 发送到请求者的 Real-Debrid。每发送 10 次，可获得 7 天的 DMM 赞助者权益：参见[不付费也能获得](../guides/sponsorship.md#earn-it-without-paying)。

## 出现问题时 {#when-something-is-wrong}

| 你看到的 | 怎么做 |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | 这个密钥对应的是 TorBox 免费套餐。请在 TorBox 上升级或续费，然后重新登录。 |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | 你登录之后付费套餐已经到期了。请在 TorBox 上续费。 |
| **API Error: Request failed with status code 403. Status: 403** | TorBox 没有接受这个密钥。请从 [torbox.app/settings](https://torbox.app/settings) 重新复制，要完整复制。 |
| Usenet 标签页上没有 **TorBox** 按钮 | 把 Usenet 版本发送到 TorBox 需要 Pro 套餐。Essential 和 Standard 没有这个按钮。 |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | 因为套餐不是 Pro，TorBox 拒绝了这个 NZB。 |
| 只有 **DL with TB**，没有 **Instant TB** | TorBox 没有缓存这些版本。可以点一个等它下载完，或者换一个其他版本。 |
| 只显示 **Instant TB** 版本 | 筛选框里的 **TB ✓** 标签是开着的（即筛选框里的 `is:tb`）。再点一次，或者点 **Reset**。 |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | DMM 目前还没有这个节目的种子。新集可能要等一阵子。可以试试 **Usenet** 标签页，或者稍后再来。 |
| 在 Stremio 里看到：**⚠️ TorBox refused your account** | TorBox 接受了插件的密钥，但不肯提供这个账户的服务，通常是因为套餐到期了。请到 [torbox.app/settings](https://torbox.app/settings) 查看。DMM 这边不用改任何东西。 |
| zurg 里看到：`Acquisition: dmm-torbox refused the search: No TorBox key linked.` | DMM [Torznab 页面](https://debridmediamanager.com/torznab) 上的赞助 `tb/cached` 源，需要你在该页面的 **Link a provider key** 下绑定 TorBox 密钥。仅在 DMM 上登录 TorBox 是不够的。zurg 里的 `api_key` 仍然填你的 DMM API 密钥。 |

TorBox 本身是不是挂了？可以查看 [Is TorBox Down Or Just Me?](https://debridmediamanager.com/is-torbox-down-or-just-me)。还是解决不了？可以到 [Discord](https://discord.com/invite/7u4YjMThXP) 的 **dmm-support** 论坛提问。[获取帮助](../guides/remote-help.md) 里写了该提供哪些信息。

## 常见问题 {#questions}

### zurg 的免费版不支持 TorBox 吗？ {#is-torbox-support-not-on-the-free-tier-of-zurg}

好，说明一下。zurg 的免费公开版只支持 Real-Debrid。TorBox、其他服务和 Usenet 在 zurg 的每夜构建版中，仅供赞助者使用。由于 zurg 无法读取免费账户，你的 TorBox 方案也必须是付费的。请按照 [TorBox 与 zurg 的设置指南](../zurg/providers/torbox.md) 进行设置。

### zurg 用错了 TorBox 套餐？ {#zurg-uses-the-wrong-torbox-plan}

zurg 的 nightly 版本在 2026 年 10 月 3 日之前，会把 TorBox 的 Pro 套餐当成 Standard，并允许同时下载 5 个，而不是 10 个。请更新 zurg。其余内容请参阅 [TorBox 在 zurg 中的限制](../zurg/providers/torbox-limits.md)。

### TB 搜索没有结果？ {#no-search-results-with-tb}

DMM 的搜索结果不受你登录的服务影响，无论用哪个都一样。TorBox 只决定哪些资源会显示 **Instant TB** 标记。如果什么都没看到，可以检查 **TB ✓** 标签是否已关闭，刷新页面，或者点击底部的 **Show More Results**。刚播出的新剧集在 DMM 上可能还没有种子资源，这时可以试试 **Usenet** 标签页。

### 可以同时使用 TorBox 和 Real-Debrid 吗？ {#can-i-use-torbox-and-real-debrid-together}

是的。两个服务都登录后，每个资源都会显示两边的按钮。如果某个资源 TorBox 已缓存、Real-Debrid 没有，就会出现一个 **TB → RD** 按钮，点击后会把它从 TorBox 转到你的 Real-Debrid。

### 使用 DMM 需要哪个 TorBox 套餐？ {#which-torbox-plan-do-i-need-for-dmm}

任何付费套餐都可以。如果你想把 Usenet 发布内容发送到 TorBox，或者想同时下载 10 个文件，就选 Pro。
