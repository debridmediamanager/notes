# ElfHosted 新闻服务器 {#elfhosted-news-server}

ElfHosted 把 Usenet 账号和它的 Stremio 插件套餐绑在一起，并把这项服务称为 Usenet Essential。本页记录了这台服务器的情况。下面所有数据都是 2026-09-04 从同一台主机上测得的。由于 ElfHosted 公开过的唯一一个凭据已经失效，这个账号本身无法测量，这也是我们的第一个发现。

## 线路上能看到什么 {#what-answers-on-the-wire}

`news.elfhosted.com` 解析到 `94.232.116.124`，在 563 端口通过 TLS 1.3 说 NNTP，证书由 Let's Encrypt 为 `news.elfhosted.com` 签发。证书只包含这一个域名，没有别的，签发日期是 2026-08-17。同一台服务器在 119 端口上也用明文应答，问候语相同。问候语是 `200 Welcome to elfhosted`。

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

这和 [TorBox 阅读器](torbox-news-server.md) 报告的 `nntpswitch2` 字符串一样。这份列表是未认证时的，所以它在 `AUTHINFO USER` 处结束，而不是 `POST`。`HELP` 在没有凭据的情况下也会回应，并列出完整命令集，包括 `POST`、`IHAVE`、`XPAT` 和 `XGTITLE`，所以缺少的 `POST` 是会话的问题，而不是服务器的问题。

在认证之前，只有三个命令能用，其他都不行。

| 命令 | 回应 |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` 和 `LIST` 和 `STAT` 和 `POST` | `480 Authentication required for command.` |

## 谁在运营它 {#who-runs-it}

TorBox 那一页只能靠相邻关系推断运营方，这一页不用了。这里 `news.elfhosted.com` 就在 Abavia 的读取器地址段里。

`94.232.116.124` 位于 `94.232.112.0/21` 中，属于 `AS48345 AS-ABAVIA`，注册方是位于圣马力诺的 Abavia S.r.l.。对 `94.232.116.0/24` 做反向扫描，返回 79 个主机名。其中 45 个在 563 端口响应 NNTP，且这 45 个都报告 `nntpswitch2 (local-dev)`，能力列表逐字节相同，顺序也一样。Abavia 自己的边界路由器也在同一个 /24 里，XS News 的上游馈送、网站主机和域名服务器同样在里面。

| Address | Reader | Greeting |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHosted 占用的 4 个地址属于 Easyusenet，7 个属于 XS News，12 个属于 TorrentClaw。TorrentClaw 是另一个挂在同一平台前面的 Stremio 插件。

这里没有基于名称的多路复用。用 servername `reader.xsnews.nl` 去连这个地址，或者用一个根本不存在的名字去连，返回的证书和 `200 Welcome to elfhosted` 问候语都一样。也就是说，每个品牌一个地址。

TorBox 不在这个地址段里。它位于荷兰的 `78.152.55.171`，属于 `AS3257 GTT`。所以 ElfHosted 的归属判断比 TorBox 那边更有把握。TorBox 跑的是同样的软件，但挨着这个系列里的某个品牌；ElfHosted 则直接跑在 Abavia 自己的地址空间里。

**实测**的部分包括软件指纹、地址归属、证书，以及没有基于名称的多路复用。**推断**的部分是：背后的库存确实是 Abavia 自己的，而不是 ElfHosted 自己拼凑的混合来源。在没有凭据的情况下，线路上的数据无法区分这两种情况。

## 公开的凭据已失效 {#the-published-credential-is-dead}

2025-12-20，ElfHosted 宣布将 NNTP 访问与 NzbDav 捆绑推出，作为为期两个月的概念验证，合作方是一家未公开名称的 Usenet 基础设施提供商。公告中还公布了一组共用凭据。

| 字段 | 2025-12-20 公布的内容 |
|---|---|
| 主机 | `news.elfhosted.com` |
| 端口 | 563 SSL |
| 用户名 | `elfie` |
| 密码 | `elfie` |
| 连接数 | 100 |
| 费用 | 2026 年 2 月前免费 |

新用户在 NzbDav 里已经预先配置好了这些信息。公告说，概念验证结束后会重新评估这个安排。现在验证已经结束，这组凭据已经无法通过认证了。

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

在这个软件上，`482 Invalid username or password` 才是真正的失效回复，而不是连接数上限。连接数上限对应的是 `482 too many connections for your user`。时间也对得上。用一个从未存在过的用户名拨了五次，和用 `elfie` 拨了两次，得到的是同一种拒绝，耗时也处于同一范围。

| 连接尝试 | 回复 | 耗时 |
|---|---|---|
| 随机用户名，拨号五次 | `482 Invalid username or password` | 中位数 2066 毫秒，范围 2043 到 2070 毫秒 |
| `elfie` 和 `elfie`，拨号两次 | `482 Invalid username or password` | 2043 毫秒和 2212 毫秒 |

从代码和耗时来看，已经失效的凭据和从未发放过的用户名都无法区分。这个软件大约需要两秒才会拒绝，TorBox 的读取器也是这样。

所以，100 个连接的数字说的是一个已经结束的优惠。这是 ElfHosted 对这台服务器公布过的唯一数字，而现在你已经买不到它了。付费的 Usenet Essential 应该是每个客户单独发放凭据，但这一点从外部无法验证。

同一份公告还公布了一个内部 Newznab 端点，地址是 `elfhosted-internal.zyclops`。它接受任何 API key，还可以按某个骨干网筛选出健康的结果。ElfHosted 商店说 Usenet 套餐包含索引器，指的就是这个端点。它提供的是可用性和健康状态信号，而不是内容本身。官方的说法是它像是基础设施健康的水晶球，而不是寻宝图。套餐里仍然需要另外配一个真正的索引器。

## 无法测量的内容 {#what-could-not-be-measured}

这些都决定了一个提供商连接槽位值不值得占用，而它们全都需要凭据。

| 属性 | 状态 |
|---|---|
| 连接上限 | 未知，100 这个数字只适用于已停用的概念验证版本 |
| 保留时长 | 从未公布 |
| `LIST ACTIVE` 中的新闻组 | 需要认证 |
| 文章编号范围 | 需要认证 |
| 与其他骨干网的覆盖率对比 | 需要认证 |
| 单连接吞吐量 | 需要认证 |
| 发帖 | 服务器支持 `POST`，但账户情况未知 |

七天试用只要一美元，还能拿到凭据。在这一周内，用跟 [TorBox 页面](torbox-news-server.md#what-it-actually-holds) 里相同的 531 条 Message-ID 扫描一遍，上表每一行的答案就都能知道了。

## 平台本身已经告诉你的信息 {#what-the-platform-already-tells-you}

两个结论可以沿用到这里，有一个不能。

可以沿用的是拒绝的语义和拒绝的时机。软件相同，返回的结果也相同，所以 `482 Invalid username or password` 在这里同样表示凭据已失效，只是上限对应的字符串不同。

也可以沿用的是文章编号窗口。`nntpswitch2` 读取器只会在一个很短的窗口内合成文章编号，所以任何按编号而不是按 message id 遍历的工具，看到的都只是大约两周的 Usenet 内容。这是平台本身的特性，不是某个账户的问题。通过 NZB 驱动的读取是按 message id 寻址文章的，不受影响。

不能沿用的是覆盖范围。在 TorBox 上的测量显示，它的读取器是 Omicron 账户的严格子集，覆盖率为 71.2%，531 篇文章中没有一篇是它自己的。但那是 TorBox 端点的结果，不是这个端点的，而且 TorBox 也不在这个区块里。它是同一软件、同一运营方的最接近的先验参考，但它并不是 ElfHosted 的测量结果。请把它当作需要验证的假设，而不是答案。

## 在 zurg 中配置 {#configuring-it-in-zurg}

如果拿到了凭据，它就是一个普通的 `type: nzb` 服务器条目，和主服务器放在一起使用。

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

一开始先用 8 个连接，等测出真实上限后再往上加。公布的 100 已经作废，如果连接数超过未知的上限，连接池在冷启动时就会把自己拒之门外。请写 `backbone: abavia`，不要写品牌名。XS News、Easyusenet、Hitnews、UseNeXT 以及这个服务其实都是同一个平台，如果把它们当成不同的 backbone，连接池就会把同一个 spool 算成好几个。`backup: true` 会让它只负责那些所有主服务器都已经拒绝过的文章。

千万不要把第二个客户端指向同一个凭据。服务器会踢掉较早的那个连接，而不是较新的那个，所以再接入一个消费者，就会把第一个挤掉。

## 值不值得占一个位置 {#is-it-worth-a-slot}

它不能单独购买。它需要搭配每月九美元的 Stremio 插件套餐才能使用，
该套餐还包含一个托管插件、一个 NzbDav 实例，以及一个 TorBox Essentials 账户。
作为其中的一项，它不会额外收费，这也是在没有凭据的情况下，关于它能说的最有利的一点。

对于已经有 Omicron 账户、Eweka 和 Frugal 的技术栈来说，再从这个平台加一个第四个读取源，
和 TorBox 页面所做、并最终输掉的那次赌注是同一种赌注。这个赌注在这里还没有被测量过，
所以它只是一个先验判断，而不是结论。
要验证它，只需要一美元、一周时间，以及 531 个 ID 的扫描。
