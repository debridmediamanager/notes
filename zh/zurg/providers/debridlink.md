# Debrid-Link

`type: debridlink`

[Debrid-Link](https://debrid-link.com/id/diG1t) 的 seedbox 列表包含所有文件。刷新媒体库时只需分页遍历一次，而不必为每个发布逐一查询。在三种云端后端中，它是保持同步成本最低的一种。

## 获取 API 密钥 {#get-the-api-key}

登录并打开 [debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey)。生成一个密钥并复制它。

## 配置它 {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

在全新的容器安装中，让 setup 来写入它。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

如果安装时已经有 `config.yml`，请在 `http://localhost:9999/config/` 的 Dashboard 中使用 **Add provider**，或者直接编辑该文件。两种方式之后都要重启。

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` 由 `zurg setup` 读取，而不是由正在运行的守护进程读取。

## 每个条目一个凭据 {#one-credential-per-entry}

Debrid-Link 通过属于列表账户的 ID 来解析每个文件。
没有可以轮换的第二个密钥。`download_tokens` 会被拒绝,`strm_link_token` 与 `token` 不一致时也会被拒绝。
要添加第二个账户,就新建一条配置,并使用它自己的 `name`。

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## 这里能用的功能 {#what-works-here}

库浏览、流式读取、重定向读取、STRM、磁力链接添加、`.torrent` 上传和删除都可以正常工作。该账户会有一个它自己的 `__debridlink__` 目录。

## 值得了解的限制 {#limits-worth-knowing}

**20 个活跃槽位。** 这是 zurg 在此之上继续添加内容时的上限。

**8 个并发 API 请求。** 多卷压缩包的四个分卷会同时解析。

**内容会过期。** 已经消失的发布资源属于正常情况，而不是故障。

**没有缓存检查。** Debrid-Link 已经下线了该接口，zurg 也不再使用它。仅缓存添加只能从添加请求的响应本身判断是否命中。在添加之前询问某个内容是否已缓存，这个后端无法回答。

zurg 会把服务返回的错误代码对应到接下来该做的事。

| Debrid-Link 返回的代码 | zurg 的处理 |
|---|---|
| `badToken` 或 `badSign` | 报告凭据有误，请修复密钥。 |
| `floodDetected` | 暂停该账户一小时。 |
| `maxTorrent` `maxData` `maxLink` 及其 `Host` 变体 | 报告当日添加或流量配额已用完。 |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | 将该账户视为暂时不可用。 |
| `badId` | 将该种子视为已不存在。 |

!!!warning 遭遇洪泛拒绝要等一小时
`floodDetected` 会把账户暂停整整一小时，而不是一分钟。这是有意为之。在洪泛拒绝之后继续重试，只会招来下一次拒绝。重启 zurg 之前，先把之前那些高频请求的东西放慢下来。
!!!

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

只有一个账号时，它自己的文件夹不会出现在挂载的根目录列表里，所以挂载点会把同样的文件显示在 `__all__` 下面。

## 出错时怎么办 {#when-it-goes-wrong}

**一小时内什么都不会发生。** 这是被拒绝的洪水请求。参见上面的警告。

**抓取被拒绝，但读取仍然正常。** 每日添加或流量配额已经用完。它会按服务商自己的计划重置。

**添加成功后就一直卡着。** 如果没有缓存接口，就无法提前知道某个哈希是否已经被缓存。未缓存的添加会像其他任务一样下载。
