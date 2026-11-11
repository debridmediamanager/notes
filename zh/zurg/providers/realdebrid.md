# Real-Debrid

`type: realdebrid`

zurg 最初是为 [Real-Debrid](http://real-debrid.com/?id=20476302) 做的服务器，到现在仍然最懂它。它是唯一支持按文件选择、单独的 `__downloads__` 列表、CDN 节点选择和专用 `.strm` 令牌的后端。

## 获取 API 令牌 {#get-the-api-token}

登录并打开 [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354)。

令牌是一长串十六进制字符串。请完整复制。

!!!warning 先关闭自动远程流量
在你的[账户页面](http://real-debrid.com/?id=20476410)中，确保 **Use my
Remote Traffic automatically when needed** 未勾选。保持开启的话，普通播放会在你不知情的情况下消耗你的远程流量额度。
!!!

## 配置它 {#configure-it}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

在全新的容器安装中，让安装程序替你写入这些内容即可。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

如果已经有 `config.yml`，请使用位于 `http://localhost:9999/config/` 的 Dashboard，或直接编辑该文件。然后重启。

```bash
docker compose restart zurg
```

### 容器可以从环境变量中自动读取的唯一提供商 {#the-one-provider-a-container-can-seed-from-the-environment}

Real-Debrid 是唯一一个守护进程会自行创建配置的账户。你 compose 文件里 `environment:` 块中的 `TOKEN` 或 `RD_TOKEN` 会在创建 `config.yml` 的那次运行中写入该文件。`MOUNT_PATH` 则用来设置挂载路径。

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

这两个变量**只在**第一次运行时读取。文件一旦存在，它就是唯一的配置来源。过期的变量不会悄悄覆盖你在 Dashboard 中设置的挂载路径。如果某个 `MOUNT_PATH` 因此被忽略，启动时会给出警告。

## 此后端还会用到的其他密钥 {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` 是同一服务上的备用 API 令牌。当当前令牌的带宽额度用完时，它们会接手。它们使用此条目的目录，它们自己的种子库永远不会被导入。

`strm_link_token` 负责处理发往 `/strm/` 的读取请求，这样播放器打开 `.strm` 文件时，就不会消耗你实时挂载播放所用的令牌。未设置时会回退到 `token`。

这两项都值得配置，因为 Real-Debrid 是少数会轮换凭据的后端之一。

## Real-Debrid 与其他提供商不同的地方 {#what-real-debrid-does-that-the-others-do-not}

- **按文件选择。** 添加一个版本时，可能只会拉取其中一部分。所以
  `force_select_playable_files` 才有可操作的对象，修复时也能只针对损坏的文件，
  而不必重新添加整个版本。
- **名为 downloads 的第二个列表。** 挂载根目录下的 `__downloads__` 是不限速链接列表，只有 Real-Debrid 提供。批量清空它需要 Web 会话 Cookie，所以 Dashboard 上的按钮是唯一的途径。没有 Real-Debrid 账户的安装会收到相应提示，而不会被显示成假的成功。
- **CDN 节点选择。** `rd_cdn_host_preference` 用于在 Real-Debrid 自行选择的节点、其对应的 Cloudflare 镜像节点，以及指定国家之间做选择。参见 [CDN 与节点选择](../reference/config.md#cdn--host-selection)。
- **修复。** 记录在某个文件上的 Real-Debrid 链接可能会失效，而种子仍显示正常。这正是 zurg 需要修复子系统的根本原因，也是唯一需要它的后端。

## 值得了解的限制 {#limits-worth-knowing}

**同一账户上两次添加之间需要间隔 20 秒。** 这是 2026-08-17 对实时 API 测得的结果。把六个干净的发布名以 10 秒间隔添加，结果六次全被拒绝。同样的六个，间隔 20 秒，则六次全部通过。zurg 会把自己的添加节奏控制在这个下限上。

**被拒绝的添加，和被屏蔽的文件名，看起来一模一样。** Real-Debrid 对两者都返回 `451 infringing_file`。节流机制还会“记仇”：一旦触发，即使之后好几分钟都没有请求，它仍会继续拒绝。某次生产环境的修复扫描，因为开始时三次添加彼此相隔不到十三秒，结果花了四个小时什么都没添加成功。

**有些发布仅凭名称就会被拒绝。** 自 2026 年 10 月 14 日起，共有十一个字符串会触发这种情况。WEB-DL、WEB.x264 和 WEB.H264 只有在完全一致的情况下才会命中，所以 web-dl、Web-Dl 以及 scene 常见的 WEB.h264 都能通过。WEBRip、BDRip、HDRip、DVDRip、HDTV.x264、HDTV.XviD、BluRay.x264 和 p.BluRay.DTS 无论大小写都会命中。最后一个要求前面紧跟一个 p，例如 1080p.BluRay.DTS；2002.BluRay.DTS 这样的发布则没问题。只有完全一致的分隔符才算数：WEB.DL、WEB-x264 和 BluRay-x264 都可以通过。名称中包含其中任意一个的发布，每次第一次请求都会被拒绝，不管其背后是什么内容。发布内部的文件如果自身名称命中规则，虽然会被接受，但无法串流。zurg 清楚这些规则，会直接在本地拒绝这类抓取，而不是白白占用一个添加名额，再经历两次 60 秒的重试去面对必然失败的结果。

**账户里已经有的内容，再添加一份副本，永远不会下载。** Real-Debrid 会接受这次添加，但不会为它抓取任何东西。实例会一直停在进度 0%，做种者 0 个。

**种子列表不包含文件详情。** 每个种子都需要单独调用一次 info 接口。这就是 zurg 保留磁盘端 info 缓存的原因。对大型库做冷扫描是最耗时的情况，而缓存能避免这一过程重复进行。

三个配置项用于控制 API 的请求节奏，默认值适合普通账户。

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

只有一个账户时,它自己的文件夹会从挂载的根目录列表中省略,
所以挂载点下会在 `__all__` 下显示同样的文件。

## 出错时怎么办 {#when-it-goes-wrong}

**`RD Permission denied` 出现在日志里。** 说明密钥已被吊销或轮换了。请到 [real-debrid.com/apitoken](http://real-debrid.com/?id=20476302) 获取新密钥，然后在 Dashboard 或 `config.yml` 里更新对应条目。

**每次抓取都返回 451。** 要么是 Real-Debrid 直接拒绝了这个发布名称，要么是添加的间隔太近，限流仍在生效。安静一段时间就会恢复，重试是没用的。

**首次启动时挂载点什么都列不出来。** 大型库需要一些时间加载。在加载完成之前，`/dav/movies/` 会返回 503。

**链接通过了校验，但什么都播不出来。** 请开启 `use_range_verification`，这样 zurg 会用一个字节的范围 GET 来检查，而不是 `HEAD`。有些网络和部分 Real-Debrid 服务器对 `HEAD` 的响应不正确。
