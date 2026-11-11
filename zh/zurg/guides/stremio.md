# Stremio 插件 {#the-stremio-addon}

zurg 可以作为 Stremio 的插件来响应请求。Stremio 会按 IMDb ID 发起查询。zurg 会搜索你的 Newznab 索引器，并把所选版本的 NZB 拉取到 Usenet 后端。之后它会像处理其他 zurg 版本一样进行播放和修复。
通过这种方式播放的所有内容也会进入你的媒体库，并出现在 Plex 中。

## 配置 {#configuration}

插件需要一个 NZB 账户，即 `nzb` 或 [`torbox_nzb`](../providers/torbox-nzb.md)，由它负责提供实际的数据。另外还需要至少一个索引器。使用 `torbox_nzb` 时，如果 TorBox 已经缓存了某个版本，并且没有其他 NZB 任务在排队，那么它会在插件的等待时间内开始播放。未缓存的版本必须先在 TorBox 上下载完成，这个时间比播放器的等待时间长。

```yaml
stremio:
  enabled: true
  # token: ""            # generated and kept in data/stremio-token when empty
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_KEY
    - name: second-indexer
      url: https://second-indexer.example
      api_key: YOUR_KEY
      api_path: /api/v1/api   # for an indexer that 404s the default /api
```

这些设置都在配置页面的 **Stremio Addon** 下面，包括开关、索引器列表和结果数量上限。插件的地址也显示在这里，并带有复制按钮，地址是根据你打开控制面板时使用的地址生成的。请使用这个地址：参见[在其他设备上安装](#installing-it-on-another-device)。

zurg 启动时会在日志里输出插件地址：

```
<zurg>/stremio/<token>/manifest.json
```

把它粘贴到 Stremio 里（在 Addons 中，搜索框可以直接输入网址）。路径中的 token 就是全部的授权凭据。Stremio 客户端本身不发送任何认证信息，所以这些路由和 SABnzbd 的端点一样，不走基本认证。请像对待密码一样保管这个地址：它生成的播放链接里包含你的索引器 API 密钥，任何拿到地址的人都可能消耗你的索引器抓取次数和新闻服务器连接数。

## 在其他设备上安装 {#installing-it-on-another-device}

Stremio 只接受在运行 Stremio 本身的那台电脑上使用明文 `http` 的插件地址。也就是 zurg 所在机器上的 `http://127.0.0.1` 或 `http://localhost`。其他情况都需要 `https`。电视、手机或另一台电脑即使能正常访问 zurg，只要使用 `http://` 地址，就会显示 **failed to load manifest**。局域网地址和 Tailscale 地址也一样。只要你是通过这类地址的明文 `http` 打开配置页面，页面就会在插件地址旁边提示这一点。

zurg 自己不提供 `https`。你需要在它前面放一个能提供 `https` 的东西。然后在 `https` 地址上打开配置页面，从那里复制插件地址。zurg 会根据每个请求进来时使用的地址来生成插件地址和所有播放链接。这里没有公开 URL 设置，`base_url` 在这里也不会用到。同一个 zurg 可以同时服务局域网内的播放器和外部的播放器。

前面的那个东西必须告诉 zurg 两件事。主机名来自 `Host` 请求头或 `X-Forwarded-Host`。协议来自 `X-Forwarded-Proto: https`。如果没有这个请求头，插件仍能加载，但播放链接会变成 `http://`，播放会失败。下面每个选项都会同时发送这两个请求头。

Stremio 用到两个路径。`/stremio/` 是插件。`/strm/e/` 是你按下播放后，把播放器带到视频的路径。由于 Stremio 无法发送密码，这两个路径都不需要 zurg 的密码也能访问。保护它们的是插件地址里的 token。当 zurg 对外网开放时，只发布这两个路径。其他内容，比如你的控制面板和媒体库，都不要公开。

### Tailscale Serve

如果每台运行 Stremio 的设备都能运行 Tailscale，这是最简单的方法。zurg 不会暴露在互联网上。

1. 在 Tailscale 管理控制台中打开 MagicDNS 和 HTTPS certificates。
2. 在 zurg 所在的机器上运行这条命令。如果 zurg 不在 9999 端口，请换成你自己的端口。

   ```bash
   tailscale serve --bg 9999
   ```

   在 Windows 上，在 PowerShell 中运行同样的命令。如果提示 access denied，就改用以管理员身份打开的 PowerShell。在 Linux 上，除非你已经把自己设为 Tailscale 的 operator（`sudo tailscale set --operator=$USER`），否则要在前面加上 `sudo`。在 macOS 上，如果找不到 `tailscale`，可以使用 Tailscale 应用自带的版本：`/Applications/Tailscale.app/Contents/MacOS/Tailscale`。

3. 打开 `https://<machine>.<tailnet>.ts.net/config/`，从 **Stremio Addon** 卡片中复制插件地址。

Tailscale 会获取证书，并同时发送两个标头。运行 `tailscale serve reset` 可以再次关闭它。

无法运行 Tailscale 的设备可以改用 Tailscale Funnel。它会把同一个地址发布到互联网上。只发布 Stremio 需要的内容。

```bash
tailscale funnel --bg --set-path /stremio http://127.0.0.1:9999/stremio
tailscale funnel --bg --set-path /strm/e http://127.0.0.1:9999/strm/e
```

配置页面不在这个地址上。像平时一样打开页面，复制插件地址，然后把开头换成 `https://<machine>.<tailnet>.ts.net`。Tailscale 会限制 Funnel 的带宽，4K remux 可能会卡顿。

### 你自己的反向代理 {#your-own-reverse-proxy}

已经在用反向代理，并且有域名和证书？那就把 zurg 加进去。

Caddy 会保留 `Host` 请求头，并自动发送 `X-Forwarded-Proto`。
这样只会公开两个 Stremio 路径，其他内容都不会暴露。

```
zurg.example.com {
    handle /stremio/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle /strm/e/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle {
        respond 404
    }
}
```

nginx 默认不会发送这两个请求头，除非你明确配置。

```nginx
location ~ ^/(stremio|strm/e)/ {
    proxy_pass http://127.0.0.1:9999;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
}
```

把它放进已经监听 443 端口、并配有证书的 `server` 块里。`proxy_buffering off` 能让视频流直接传输，而不经过 nginx 的缓冲区。

### Cloudflare Tunnel

具名隧道可以让 zurg 通过你在 Cloudflare 上的域名获得一个 `https` 地址，而且不需要开放端口。Cloudflare 会保留 `Host` 请求头，并自己发送 `X-Forwarded-Proto`。只在隧道的 `config.yml` 里为 Stremio 的路径配置路由。

```yaml
ingress:
  - hostname: zurg.example.com
    path: ^/(stremio|strm/e)/
    service: http://127.0.0.1:9999
  - service: http_status:404
```

先说两件事。Cloudflare 在请求超过 100 秒后会放弃。某个版本的第一次播放可能会超过这个时间。这时再按一次播放就能开始了。另外，Cloudflare 的条款允许它限制没有付费套餐、却通过其网络传输大量视频的账户。每次播放都会经过这条隧道。

## 播放时会发生什么 {#what-a-play-does}

选择一个视频流就等于执行一次 grab：zurg 从索引器下载 NZB，把它放进 `nzbs/`（使用与 SABnzbd 端点相同的命名规则，所以同一个版本被 grab 两次，或者已经被 *arr grab 过，都会被找到，而不会重复添加）。然后它等待库中列出这个文件，再把播放器重定向到已签名的 `/strm/e/` 端点。每个 `.strm` 文件本来就是通过这个端点播放的，支持范围读取、账号故障转移，以及 RAR/7z 包内读取。

所以一个版本的第一次播放会比 debrid 视频流慢。需要获取并解析 NZB，还要读取压缩包内部，通常几秒钟；如果是混淆过的帖子，需要先运行命名识别流程，可能要一两分钟。超过等待时间的播放会返回带 Retry-After 的 503，再点一次播放就会走快速路径。之后的每次播放都是即时的。

如果一个版本列出来后发现里面没有可播放的内容，点击就还没有结束。这通常是因为它已经从 spool 里消失了，或者新闻服务器检查把所有文件都标记为损坏。播放 URL 带着生成它时的请求，所以 zurg 会重新给这个标题的版本排序，然后依次尝试所选条目之后的那些行。每一行都走同样的 grab 和列出流程。第一个能播放的版本就是播放器被重定向到的地方。它会遍历整个结果，而不只是列表里显示的那些行。`max_results` 是用户想滚动查看多少条，如果让它同时限制恢复尝试，那么一个显示在第十行的标题，最多只能尝试九个，不管搜索实际找到了多少。选中项*之后*的那些行是有意为之的：它们分辨率相同、体积更小，或者分辨率更低，绝不会是用户跳过的更大版本。

作为备选的版本如果仍在拉取中，同样返回 503。再次点击播放会解决这个问题：已被拒绝的版本会立即被拒绝，备选版本则走快速路径找到。只有最终的拒绝会继续往下尝试，503 永远不会继续往下尝试。每次尝试都会消耗一次索引器 grab，并且像其他 grab 一样把版本留在库里，所以整个链条受 25 秒预算和 6 次尝试上限的约束。预算是真正的限制，因为每次尝试的代价并不相同：已经从 spool 里消失的版本会在一秒内被拒绝，而一个需要拉取并打开压缩包、最后才发现里面没有内容的版本，可能单独就占满整个预算。如果所有尝试过的行都被拒绝，结果就是原来一直返回的 404。每次回退都会以 info 级别记录日志，包括被拒绝的版本和接下来尝试的版本。

基于 2026 年 9 月 7 日对另外三个基于 Usenet 的 Stremio 插件的测评：stremio-addon-findings-2026-09-07.md。简单来说，按分辨率的上限修复了上一轮发现的问题，但覆盖率仍然减少了一半。原因是只有五层的分组，在第一个可播放的条目是已经从 spool 里消失的版本时，就无路可走了。上面的回退机制是那一轮的第一个修复。此后分组已从五个扩大到十个。

## 搜索行为 {#search-behaviour}

- 电影搜索使用 `t=movie`，剧集使用 `t=tvsearch` 加上 `season`/`ep`，两者都按 `imdbid` 搜索。请使用纯数字，因为有几个索引器对 `tt` 格式会返回零结果。
- 每个索引器会被请求 `search_limit` 个发布版本（默认 100）。下面的每个限制都是在这些请求结果中做选择，所以它是答案的上限。
- 索引器并行搜索。如果某个索引器拒绝请求（例如触发了突发限制或密钥失效），只会损失它自己的结果，不会影响整个列表。拒绝记录会按索引器分别写入日志。
- 结果按发布名称去重，先按分辨率排序，再按大小排序，并且*每个分辨率*最多保留 `max_results` 个（默认 10）。之所以按分辨率计数，是因为排序首先按 2160p 排列。热门影片在大小上限之下的 UHD 发布版本比任何上限都多，如果在整个列表上计数，每个热门影片都只会得到 remux，搜索到的其他内容全被挤掉。
- 每个分辨率保留的是大小的分布，而不是最大的几个。从最大的发布版本到最小的发布版本，均匀间隔地挑选，并且最大和最小的两个始终包括在内。如果只保留最大的几个，一个包含五个的 1080p 档位就全是 19 到 30 GB 之间的 remux，而手机或笔记本可以直接播放的 4 GB 压制版会被上限去掉。2026 年 9 月 7 日的测量显示，zurg 为《肖申克的救赎》列出的十五个条目中有三个小于 6 GB，而同一批索引器上同样大小的发布版本有四十个。列表在同一分辨率内仍按大小降序排列。索引器没有给出大小的发布版本在这个维度上没有位置，只会填补有大小的发布版本留下的空位。
- 每个流的描述包含发布名称、大小、找到它的索引器，以及发布距今多久（如果索引器提供了这个信息），例如 `3d`、`126d`、`2y`。2026 年 9 月的那一轮中，新闻服务器上的内容过期是播放失败最常见的原因，而发布日期是观众可以用来避开它的唯一信号。
- 超过 `max_size_gb` 的发布版本会在排序前被丢弃，适用于无法播放 remux 的播放器。默认没有此限制，因为上面的分布已经把每个分辨率最小的发布版本与其 remux 一起列出。索引器没有给出大小的发布版本会保留。这个限制在渲染列表时才生效，因此修改上限对已缓存的影片同样适用。
- 结果缓存在磁盘上（`data/stremio-cache/`，每个影片一个文件），所以重新打开一部影片不会调用索引器。索引器通常有每日配额，而且 Treasure Maps 在短时间内连续请求大约六次后就会拒绝。缓存的有效时间取决于搜索到的结果数量，因为结果少说明上传还在进行中，或者某个索引器当时宕机：一个结果缓存一小时，两个缓存两小时，最多四小时；五个或以上说明答案已经确定，缓存 `cache_hours`（默认 24，这是唯一可配置的档位）。空结果从不缓存。已缓存的流列表底部会有一个 **refresh** 项，说明列表已经有多久。打开该项（它在浏览器中打开，而不是播放器中）会清除该影片的缓存，重新打开影片时会重新搜索。缓存在重启后仍然保留，过期条目会自动清理。
- 第 0 季（特别篇）会被直接拒绝，而不是错误地去搜索。按 ID 搜索的覆盖范围取决于索引器本身：只能通过文本搜索找到的发布版本不会出现在结果中。
