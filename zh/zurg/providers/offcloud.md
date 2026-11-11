# Offcloud

`type: offcloud`

Offcloud 通过其 cloud explore 端点解析文件句柄。文件大小会与交付服务器核对，而不是直接相信列表里的数值。只要能无歧义地匹配，缓存的种子元数据就会提供文件夹路径。

## 获取 API 密钥 {#get-the-api-key}

登录并打开 [offcloud.com/#/account](https://offcloud.com/#/account)。API 密钥就在该页面上。

## 配置它 {#configure-it}

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

在全新的容器安装中，让 setup 写入它。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

如果已经有 `config.yml`，就在 `http://localhost:9999/config/` 的 Dashboard 中使用 **Add provider**，或者直接编辑该文件。两种方式之后都要重启。

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` 由 `zurg setup` 读取，运行中的守护进程不会读取它。

## 每个条目一个凭据 {#one-credential-per-entry}

Offcloud 文件句柄属于列出它们的那个账户。
这里没有可以轮换的第二个密钥。
`download_tokens` 会被拒绝，`strm_link_token` 与 `token` 不同也会被拒绝。
第二个账户就是另一个条目，需要有自己的 `name`。

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## 这里能用的功能 {#what-works-here}

库浏览、流式读取、重定向读取、STRM、磁力链接添加、`.torrent` 上传和删除都可以正常使用。该账户会有一个自己的 `__offcloud__` 目录。

## 值得了解的限制 {#limits-worth-knowing}

**同时最多 8 个 API 请求。** 一个多卷压缩包的四个分卷会同时解析。

**内容会过期。** 资源没了是正常情况，不算故障。除非你主动要求，修复时会跳过它。

**种子列表不包含文件详情。** 每个资源第一次使用时，都要单独查询一次。

**文件列表有歧义时，按报错处理，而不是乱猜。** 有时缓存的种子元数据无法精确匹配到唯一一个资源。zurg 会直接报错，而不是挑一个可能属于别的内容的文件夹路径。

**格式错误的磁力链接会在本地被拒绝。** 它们根本不会发送到服务端。坏的磁力链接不会有任何代价。

Offcloud 的失败错误码很少。`NOAUTH` 是 zurg 唯一能处理的错误码，它表示凭据被拒绝。其他情况都只会返回一个没有原因的拒绝。

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__all__/ | head
```

只有一个账号时，它自己的文件夹不会出现在挂载的根目录列表里，所以挂载点会在 `__all__` 下显示同样的文件。

## 出错时怎么办 {#when-it-goes-wrong}

**`NOAUTH` 出现在日志里。** 说明密钥已被吊销或重新生成。请到 [offcloud.com/#/account](https://offcloud.com/#/account) 获取新密钥,然后更新对应的配置项。

**只有 `API refused request`,没有其他信息。** Offcloud 没有说明原因。在归咎于 zurg 之前,先在浏览器里检查一下账号。

**某个发布没有列出任何文件夹。** 缓存的种子元数据无法精确匹配到唯一的发布。文件依然可以播放,只是没有文件夹结构,全部平铺显示。

**生成的链接对任何拿到它的人都有效。** 下载链接会在缓存过期或读取操作使其失效时刷新。它们消耗的配额是账号自己的。请保管好这些链接和 `.strm` 文件,不要公开分享。
