# AllDebrid

`type: alldebrid`

[AllDebrid](https://alldebrid.com/?uid=1kk5i&lang=en) 是另一个会轮换凭证的后端。所以 `download_tokens` 和单独的 `.strm` 令牌在这里都有实际作用。它的文件列表来自它自己的接口，而不是来自磁力链接列表。这会改变首次扫描大型库时的体验。

## 获取 API 密钥 {#get-the-api-key}

登录并打开 [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i)。
生成一个密钥并复制。

## 配置它 {#configure-it}

```yaml
zurg: v1
providers:
  - type: alldebrid
    token: YOUR_ALLDEBRID_API_KEY
mount_path: "/zurg_mnt/zurg"
```

在全新安装的容器中,让 setup 来写入即可。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider alldebrid
```

如果已经有 `config.yml`,请在 `http://localhost:9999/config/` 的仪表盘中使用 **Add provider**,或直接编辑该文件。无论哪种方式,都需要重启。

```bash
docker compose restart zurg
```

`ALLDEBRID_TOKEN` 是由 `zurg setup` 读取的,而不是由正在运行的守护进程读取。仅把它写在 compose 的 `environment:` 块中并启动容器,本身不会产生任何效果。

## 此后端还会用到的其他密钥 {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: alldebrid
    token: PRIMARY_AD_API_KEY
    strm_link_token: AD_KEY_FOR_STRM
    download_tokens:
      - SECOND_AD_API_KEY
```

`download_tokens` 是同一服务上的备用密钥。当当前密钥的带宽额度用完时，它们会接管。它们使用本条目的目录，它们自己的资料库永远不会被导入。

`strm_link_token` 负责处理到达 `/strm/` 的读取请求，这样播放器打开 `.strm` 时就不会消耗你的实时挂载所用密钥的额度。未设置时，它会回退到 `token`。

## 首次扫描会逐步填充内容 {#the-first-scan-fills-in-gradually}

AllDebrid v4.1 把文件详情从磁力链接列表里挪到了单独的接口。只列出你的磁力链接，zurg 并不知道里面有什么。每个资源都需要单独查询一次。

好消息是，这个查询**只需要做一次**，而不是每次重启都做。磁力链接一旦变成 Ready，它的文件树就不会再变。所以 zurg 存在磁盘上的信息缓存对它来说是永久有效的。接口前面有一个批处理器，负责处理首次扫描。你在第一次运行时看到的是一个大型资料库分批出现，之后就不会再这样了。

## 值得了解的限制 {#limits-worth-knowing}

**没有公布的活动磁力数量上限。** zurg 不会自己设一个上限。修复时从不需要等待本来就不紧张的空间。

**每个密钥每分钟 600 次请求。** 这是文档中写明的额度。zurg 把速率控制在 600 减 100，这样 HTTP 客户端自己发起的重试就不会把突发请求推过真实上限。实际中并发才是真正的瓶颈，并发被限制为 12，与文档中写明的每秒 12 次请求保持一致。

**同一个投递服务器的第 33 个连接会收到 429。** 这是 2026-08-23 测得的，方法是每 500 毫秒开一个连接并保持不断开。AllDebrid 每次解锁都会分配一个新的投递主机名。所以只有当多个读取恰好共用同一个主机时，这个限制才会生效。超过 32 个时，zurg 会排队等待，而不是继续拨号。

**没有按文件选择的功能。** 添加磁力链接会获取其中的全部内容，修复时也会整体重新添加该发布。

**内容会自行消失。** 磁力链接会随时间从账户中被移除，链接也可能被网盘方删除。一个已经消失的发布属于预期结果，而不是数据损坏。除非你主动要求，修复时会保持不动。

**保存的链接不会失效。** 与某个文件关联的锁定链接，会根据磁力链接的当前状态重新生成。磁力链接自身的状态已经能说明数据是否还在。zurg 不会在每次冷扫描时为每个种子消耗一次解锁额度，去获取一个状态本来就能免费告诉我们的结果。

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/alldebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

只有一个账号时，它自己的文件夹会从挂载的根目录列表中省略，
所以挂载点会在 `__all__` 下显示相同的文件。

## 出错时怎么办 {#when-it-goes-wrong}

**`AllDebrid rejected the API key` 出现在日志里。** 说明 key 被撤销或重新生成了。请到 [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i) 获取新的 key，然后更新对应的条目。

**冷启动的库加载得很慢。** 这是正常的。参见上面的章节。每个资源只需查询一次，之后不会重复。

**某个资源在挂载的其他位置可以播放，但在 `__alldebrid__` 下返回 404。** 失效判定是按账户进行的，而该目录会把读取固定到这一个账户上。说明其他账户手里有一份可用的副本。
