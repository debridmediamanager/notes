# TorBox

`type: torbox`

[TorBox](https://torbox.app/subscription?referral=74ffa560-7381-4a18-adb1-cef97378c670) 是 zurg 同步成本最低的库，也是最容易被限速的读取来源。它的种子列表已经包含每个文件的信息，所以刷新一次库只需要一次请求，而不是每个种子一次。它的链接解析接口是固定的配额，而不是速率限制。zurg 在这方面会特别小心。

## 获取 API 密钥 {#get-the-api-key}

登录后打开 [torbox.app/settings](https://torbox.app/settings)。API key
就在这个页面上。

**免费账户无法与 zurg 配合使用。** 如果使用免费 key，TorBox 会对每个库请求返回 `PLAN_RESTRICTED_FEATURE`，所以 zurg 无法读取账户里的内容。请使用付费套餐。付费套餐过期后也会同样变成免费的，无法使用。

## 配置它 {#configure-it}

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

在全新安装的容器中，让 setup 来写入即可。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

如果安装时已经有 `config.yml`，请在 `http://localhost:9999/config/` 的仪表板中使用 **Add provider**，或直接编辑该文件。无论哪种方式，之后都要重启。

```bash
docker compose restart zurg
```

!!!warning 只在 compose 环境变量中写入 TorBox 密钥是没有作用的
`TORBOX_TOKEN` 由 `zurg setup` 读取，而不是由正在运行的守护进程读取。只有 Real-Debrid 的 `TOKEN` 会在首次启动时写入配置。请把密钥传给 setup 容器，或在仪表板中添加该账户。
!!!

如果是无人值守安装，请让 setup 读取文件，而不是环境变量。

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## 这里不适用的两个密钥 {#two-keys-that-do-not-apply-here}

`download_tokens` 这个配置项可以写，但在 Real-Debrid 上它不会起到原本的作用。
给 Real-Debrid 换第二个 key 并不会重新映射 torrent 和文件的 ID。在 TorBox 上，这些 ID 属于最初列出它们的那个账号。如果要用第二个 TorBox 账号，需要为它单独写一个条目，并设置自己的 `name`。

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` 这个配置项可以写，但没有任何作用。TorBox 每次请求都会生成一个新的下载链接。`.strm` 文件没有可以绑定的长期有效凭证。

## 活动插槽才是真正的上限 {#active-slots-are-the-real-ceiling}

TorBox 最主要的限制是同时下载或做种的种子数量。Real-Debrid 的限制是带宽，TorBox 的限制是名额。

| 套餐 | 活动名额 |
|---|---|
| Free | 1，但 zurg 无法使用免费密钥（见上文） |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

zurg 会从账户读取套餐信息，并据此限制能否继续添加种子。如果它读不到账户的套餐，就按 3 个名额处理。

其他所有会添加种子的功能，也都要占用同一份名额。通过 qBittorrent 接口抓取的 Sonarr 和 Radarr、修复扫描，以及 watchlist，都会占用这些相同的名额。

## 值得了解的限制 {#limits-worth-knowing}

**链接解析是大约一百次调用的配额，而不是速率限制。**
实测于 2026-08-30。当调用尽可能快地发出时，第 100 次累计调用时收到一个带有 `Retry-After: 300` 的 429。当调用被限制为每秒一次时，则在第 94 次调用时收到。这种锁定是账户级别的，它会让整个挂载点停止五分钟，而不仅仅是触发它的那次读取。

由此可以得出两点，zurg 会自动处理这两件事。

- 它从不解析没有人请求的文件。其他后端会提前预读下一集，而 TorBox 承受不起这种猜测。因为媒体服务器分析媒体库时，每个文件只会打开一次，而每一次打开都是冷启动。
- 它会严格逐个解析多卷压缩包的各个分卷。如果并行解析，会把上限消耗好几倍，还可能为一个已损坏分卷后面的分卷付出代价，而在发现它们并不需要之前，这些开销就已经产生了。

**每小时 60 次未缓存添加。** 已缓存的添加则计入每分钟的配额。

**每个密钥在所有端点上每分钟 300 次请求。** zurg 将自身的速率控制在 300 减去 60，这样它的 HTTP 客户端自行发起的重试就不会把受配额控制的突发请求推过真正的上限。

**同一个 CDN 主机的第 21 个连接会收到 429。** 实测于 2026-08-23，方法是每 500 毫秒打开一个连接并保持不关闭。该限制是按主机而不是按密钥计算的。把读取分散到 TorBox 的各个节点可以避免它，而全部集中到同一个节点则不行。zurg 会将超过 20 个的连接排队，而不是直接拨号。这样就把拒绝变成了一段很短的本地等待。

**内容会在套餐的保留期结束后被删除。** 一个已经消失的种子属于正常情况，而不是故障。除非你特别要求，修复操作不会处理它。

**不支持按文件选择。** 添加种子会获取其全部内容，修复时也会把整个发布资源重新添加。

完整的说明和来源见 [TorBox 限制](torbox-limits.md)。

## 选择 CDN 区域 {#choosing-a-cdn-region}

```yaml
tb_cdn_host_preference: "auto"
```

`auto` 保持 TorBox 自己的选择不变。`force_location_<region>` 会让下载从该地区提供。只有当前宣布有投递节点的地区才能被强制指定，Dashboard 的下拉列表也只列出这些地区。这里不要使用 `cdn_host_preference`。该配置项仅适用于 Real-Debrid，其取值是 Real-Debrid 的地区代码。

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__all__/ | head
```

只有一个账户时，它自己的文件夹不会出现在挂载的根目录列表里，所以挂载点会在 `__all__` 下显示同样的文件。

## 出错时怎么办 {#when-it-goes-wrong}

**日志里出现 `Account <name> refused zurg`，或者不断重复 `TorBox rejected the API key`。**
套餐已到期，这个 key 现在是免费套餐。从 nightly 2026.10.11.2240 开始，
zurg 会在没有这个账户的情况下加载你的其他账户。仪表盘上该账户的卡片会显示
`Refused: the account's plan does not include API access`。它的资源仍会列出，但无法播放，
也不会因此删除或移入回收站。zurg 每 10 分钟会重新向 TorBox 请求一次，套餐恢复付费后会重新接入该账户。
在旧版 nightly 上，整个库一直加载不完，所以你其他账户的内容也会不显示。
更新 zurg 或续费套餐即可解决。在 `config.yml` 中注释掉 `torbox` provider 并重启 zurg 也可以。

**播放每次会卡住五分钟。** requestdl 配额已经用完，429 是针对整个账户的。
是某个东西解析的链接超出了实际需要。
媒体服务器一次扫描整个挂载点是最常见的原因。让它只指向其中一个目录，而不是全部。

**添加任务不再被接受。** 要么所有活动槽位都满了，要么每小时的添加上限已经用完。
两种情况都会自动恢复，重试也没有用。

**某个资源列出的文件比你预期的少。** `__torbox__` 只列出 TorBox 实际持有的内容。
如果另一个账户完整持有该资源，挂载点的其余部分仍会提供全部内容。

**某个种子不见了。** 这是保留期限的问题，见上文。zurg 不会在无人值守的情况下重新添加它，
因为重新发现它会白白消耗账户的配额。
