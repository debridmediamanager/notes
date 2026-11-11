# TorBox 新闻服务器 {#torbox-news-server}

TorBox Pro 订阅包含一个 Usenet 账户。它是一台真正的 NNTP 服务器，zurg 可以像普通的 `type: nzb` 提供方一样使用它。本页记录这台服务器是什么，以及作为一个提供方位它值多少。下面所有数据都是在 2026-09-02 和 2026-09-03，从两台位于不同网络的主机上测得的。

## 线路上能看到什么 {#what-answers-on-the-wire}

`nntp.torbox.app:563` 通过 TLS 1.3 使用 NNTP 协议通信，证书由 Let's Encrypt 为 `nntp.torbox.app` 签发。欢迎语是 `200 Welcome to TorBox`。能力列表里写明了软件名称。

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
POST
```

这个实现字符串既不是 INN，也不是 Diablo，也不是一些服务商报告的 `nntpd`。
它是定制软件，名字已经说明了它的用途。前面有一个交换机，连接着一个或多个文章存储（spool）。

## 谁在运营它 {#who-runs-it}

四十个公开的读取服务器主机名都被探测过，看它们返回的那个实现字符串。其中三十二个给出了 NNTP 响应，六个报告了 `nntpswitch2`。这六个返回的能力列表完全相同，顺序也一样。

| 服务器 | 地址 | 欢迎语 |
|---|---|---|
| `nntp.torbox.app` | 78.152.55.171 | `200 Welcome to TorBox` |
| `news.cheapnews.eu` | 78.152.55.164 | `200 Welcome to Cheapnews` |
| `reader.xsnews.nl` | 94.232.116.131 | `200 Welcome to XS News` |
| `news.easyusenet.nl` | 94.232.116.128 | `200 Welcome to Easyusenet` |
| `news.hitnews.com` | 94.232.116.174 | `200 Welcome to Hitnews` |
| `news.usenext.de` | 94.232.116.150 | `200 Welcome to Aviteo Ltd DE` |

其余的都给出了不同的回应。包括 Omicron 系列品牌，以及 Eweka、Frugal、UsenetExpress、Giganews 和 Usenet.Farm。

地址基本说明了其余情况。`94.232.112.0/21` 登记在圣马力诺的 Abavia S.r.l. 名下，备案中的联系邮箱是 `abuse@abavia.com`。对 `94.232.116.0/24` 做反向扫描，这一个段里就返回了六十多个读取服务器名称。XS News、Easyusenet、Hitnews 和 UseNeXT 就在其中，旁边还有几十个较小的品牌。相邻的 `94.232.117.0/24` 从头到尾都是 XS News 的主机命名。

TorBox 不在这个段里。它位于阿姆斯特丹的一个地址段中，与 `news.cheapnews.eu` 相距七个地址。

**实测**的是软件指纹、地址归属和地址相邻关系。**推断**的是商业合作安排。TorBox 把自家的 Usenet 描述为多家 Usenet 服务商的高质量组合，而切换软件的表现也与此相符。所以比较稳妥的说法是：TorBox 在前面接入的，是 Abavia 和 XS News 品牌所用的同一套读取平台；而不是说 TorBox 转卖某一个具名的存储池。

## 账户能给你什么 {#what-the-account-gives-you}

| 属性 | 值 |
|---|---|
| 主机 | `nntp.torbox.app:563` TLS，也可在 119 端口连接 |
| `LIST ACTIVE` 中的新闻组 | 103,415 |
| 连接数 | 10 个，严格上限，包括握手过程中的连接 |
| 保留期 | TorBox 称该服务器为 3900+ 天 |
| 发帖 | 允许，`POST` 返回 `340 Start posting` |
| Overview 字段 | Subject、From、Date、Message-ID、References、Bytes、Lines、Xref:full |
| 压缩 | 同时提供 `XZVER` 和 `XZHDR` |
| 带宽 | 不限，但会计入 TorBox 控制面板的用量统计 |

凭据可以在 torbox.app 的 tools 里找到，点击 View Usenet Connection Details 即可。用户名就是账户的 auth id。密码只显示一次。重置后旧密码会立即失效，因此重置会导致所有已配置的客户端都无法连接。

出问题时，有两条拒绝信息很关键。`482 too many connections for your user` 表示达到了连接上限，只要有一个连接被归还就会立即解除。`482 Invalid username or password` 则说明凭据确实已失效。这两种失败都比较慢，大约需要两秒。成功的认证快得多，在一天的生产环境拨号中测得耗时在 64 毫秒到 592 毫秒之间。

## 文章编号窗口宽两周 {#the-article-number-window-is-two-weeks-wide}

`GROUP` 在一个繁忙的二进制新闻组上返回的计数，恰好等于高水位减去低水位。真实的存储池会有空缺，所以这种相等正是编号被人为合成的特征。而且这个编号窗口也很短。

| 新闻组 | 低水位 | 高水位 | 窗口内的编号数 |
|---|---|---|---|
| `alt.binaries.boneless` | 148068410000 | 150053594960 | 1,985,184,960 |
| `alt.binaries.teevee` | 2992135000 | 3392153099 | 400,018,099 |
| `alt.binaries.multimedia` | 31901685000 | 32301734812 | 400,049,812 |

对 `alt.binaries.boneless` 中最旧的编号进行采样，返回的文章发布日期是 2026-08-19。那是在撰写本文的十四天前。更早的文章在这台服务器上没有编号。

这不影响 zurg。NZB 通过消息 ID 来定位文章，而按消息 ID 查询能找到比这个窗口早得多的文章。但它确实影响任何遍历文章编号的程序。指向这台服务器的头部下载器或索引器，只能看到两周的 Usenet 内容，再往前的都看不到。

## 它是否把你的请求代理到其他提供商 {#is-it-proxying-your-request-to-other-providers}

不，三项测量都表明，答案来自平台本身已经持有的一个缓存副本。

**它拒绝得比去询问任何人都快。** 向三台服务器询问了二十五个从未存在过的消息 ID。

| 服务器 | 命中时的 `STAT` | 从未存在过的 ID 的 `STAT` |
|---|---|---|
| `nntp.torbox.app` | 37 ms | **43 ms** |
| `news.eweka.nl` | 20 ms | 471 ms |
| `newshosting.tweaknews.eu` | 44 ms | 909 ms |

如果一台服务器在回答前要先轮询上游，那么答案为"否"时反而最慢，因为每个上游都得先回复。而这台服务器给出"否"的速度，和确认"是"的速度一样快。这说明是本地索引在作答。

**首次获取没有额外延迟。** 对 2012 至 2018 年的十篇文章，先在同一连接上冷获取一次，然后马上再获取一次。

| 服务器 | 冷获取中位数 | 热获取中位数 |
|---|---|---|
| `nntp.torbox.app` | 49.6 ms | 30.9 ms |
| `news.eweka.nl` | 98.0 ms | 78.1 ms |

这里的冷热比是 1.6，而普通缓存池上是 1.25。这属于 TCP 和页面缓存的开销。如果首次请求需要从第三方获取，成本会高得多，而且只会在冷获取那一轮体现出来。一篇 792 KB 的文章冷获取用了 49 到 73 ms，约合 11 到 16 MB/s，这不可能留出向另一家服务商往返的时间。

**混合源不可能是其中某个成员的子集。** 这一点才是定论。如果这台服务器合并了多个骨干网，那么它的覆盖范围就是它们的并集，会包含至少某一个成员所缺少的文章。但它一篇都没有多出来，而且它的覆盖范围是 Omicron 账户的严格子集，为 71.2%。合并多家服务商不可能得出这样的结果。

还有一个相关细节，供想追溯来源的人参考。返回的头部是规范化后的，而不是原样的。字段顺序会变，大小写也会被改写，所以 `X-Received-Body-CRC` 变成 `X-Received-Body-Crc`，`Message-ID` 变成 `Message-Id`。在所检查的每一篇文章中，`Path` 都是 `not-for-mail`。普通的缓存池可以保留真实的传递链，而上面的一台服务器对同一篇文章返回的是 `news.tweak-news.eu!spooler.pl1!...!feed.tweaknews.nl!path-stripped`。因此，这些头部是从解析后的字段重新构建的，无法从中恢复原始的 feed 路径。

## 在 zurg 中配置 {#configuring-it-in-zurg}

该账户是一个普通的 `type: nzb` 服务器条目。其中有两个键最为重要。

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
        - name: torbox-news
          host: nntp.torbox.app
          port: 563
          tls: true
          username: YOUR_TORBOX_AUTH_ID
          password: YOUR_TORBOX_NEWS_PASSWORD
          connections: 8
          backbone: torbox
          backup: true
```

`backup: true` 会保留这十个连接，用于获取其他所有账户都已拒绝的文章。繁忙的主账户不会转到它。只有真正返回 *no such article* 时才会转过去。关于 `backup` 和 `backbone` 的行为，请参阅[服务商键说明](../reference/config.md)。

建议配置 8 个连接，而不是 10 个。连接数上限会统计仍在握手中的连接，因此如果连接池一开始就打满上限，冷启动时会把自己拒之门外。留出两个备用连接，也方便手动运行检查而不影响正在使用的服务。切勿让第二个客户端使用同一组凭据。两个客户端共用一个十连接账户会互相争抢连接，服务器会断开较早的那个连接，而不是较新的那个。

## 它实际保存的内容 {#what-it-actually-holds}

覆盖率是用同一批文章 ID，与另外三个后端对比测得的。样本是从一个实时 zurg NZB 库中取出的 177 个发布，发布日期从 2011 年到 2026 年。每个发布按均匀间隔在文件中取 3 篇文章，共得到 531 个消息 ID。每个 ID 都向四个账号各询问一次，每个账号使用一个连接。另外三个账号分别是通过 Tweaknews 接入的 Omicron 账号、Eweka 账号和 Frugal 账号。

| 发布年份 | ID 数 | `nntp.torbox.app` | `newshosting.tweaknews.eu` | `news.eweka.nl` | `newswest.frugalusenet.com` |
|---|---|---|---|---|---|
| 2011 | 9 | 0 | 9 | 0 | 0 |
| 2012 | 21 | 16 | 21 | 21 | 21 |
| 2013 | 36 | 30 | 33 | 33 | 33 |
| 2014 | 36 | 33 | 36 | 36 | 36 |
| 2015 | 33 | 17 | 31 | 24 | 26 |
| 2016 | 36 | 31 | 36 | 36 | 36 |
| 2017 | 36 | 21 | 33 | 27 | 19 |
| 2018 | 36 | 16 | 36 | 24 | 24 |
| 2019 | 36 | 30 | 36 | 36 | 36 |
| 2020 | 36 | 34 | 36 | 36 | 36 |
| 2021 | 36 | 25 | 36 | 33 | 30 |
| 2022 | 36 | 29 | 36 | 27 | 27 |
| 2023 | 36 | 15 | 29 | 22 | 16 |
| 2024 | 36 | 23 | 35 | 32 | 33 |
| 2025 | 36 | 28 | 36 | 31 | 31 |
| 2026 | 36 | 30 | 36 | 30 | 30 |
| **总计** | **531** | **378 (71.2%)** | **515 (97.0%)** | **448 (84.4%)** | **434 (81.7%)** |

在这个库里，TorBox 的应答量比另外三个付费后端都少。

真正决定这个槽位值不值得留的，是另一个数字。**TorBox 没有任何其他后端缺少的文章。** 531 篇里一篇都没有。和 Omicron 账号相比，它是严格的子集，完全没有自己独有的文章。它确实有 9 篇 Frugal 缺少的文章，以及 6 篇 Eweka 缺少的文章，但这些在 Omicron 上也都有。与此同时，Omicron 账号单独持有 61 篇其他后端都没有的文章。

这台服务器的未命中是真实的，并不是服务器忙、回答得不好。全部 153 次未命中，几分钟后用新连接重新询问，一次都没有返回。之前形态相同的一轮测试重新询问了 77 次未命中，只拿回 1 篇。所以否定答复里大约 1% 是噪声，其余都是确实不存在。

命中也是真实的。四台服务器都声称有的 20 篇文章，随后用 `BODY` 完整拉取。四台都交付了 20/20。这台服务器上的 `STAT` 可以放心理解为：数据确实会送达。

单连接吞吐量也在同一批测试中测了，但这里不报告，因为它不稳定。从同一台主机跑了三轮，TorBox 的速度在 1.6 到 7.4 MB/s 之间浮动，另外三家的范围与之重叠，也没有稳定的先后顺序。打算规划连接池的人，应该用自己的主机来测。

表格需要附上三点说明。第一，样本来自一位运营者的库，所以它反映的是该库的收录情况。第二，同一个发布里的三篇文章彼此并不独立，因此每个年份的单元格实际上只相当于 12 个发布，而不是 36 个。第三，`STAT` 的回答只是对某一篇文章的判断，而不是对整个发布的结论。

## 值不值得占一个位置 {#is-it-worth-a-slot}

该账户不额外收费，因为它随 Pro 一起提供。这是它最有力的理由。

它并不是一个可靠的保留（retention）主干，如果把它当作主干来配置，你会失望。在与另外三个付费账户的对比测试中，它覆盖的真实库比它们少，而且它也没有找到任何其他账户已经判定不存在的文章。已经有 Omicron 账户的堆栈，再添加这个账户并不会有任何收获。

仍然有两种实际的用法。单一服务商的配置可以免费多一个第二意见，而任何第二意见都比没有强。另外，`backup: true` 让错误的猜测成本很低，因为只有在所有主账户都回答“没有这篇文章”之后，才会去询问备用账户。
