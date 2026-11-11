# TorBox 托管的 Usenet {#torbox-hosted-usenet}

`type: torbox_nzb`

使用 TorBox Pro 套餐时，Usenet 的部分由 TorBox 替你完成。zurg 会把其 watch 目录中的 `.nzb` 文件提交到你的 TorBox 账户。TorBox 会抓取每个发布、进行修复，并像处理其他 TorBox 下载一样提供服务。zurg 会把 TorBox 抓取到的内容和其他内容一起列在挂载点中。这种方式不需要新闻服务器账户，也不会在你的机器上解码任何 Usenet 文章。

这与 [TorBox 新闻服务器](torbox-news-server.md)不是一回事。后者是 `nzb` 后端使用的登录信息，它由后端自己读取文章，相关内容见 [Usenet](usenet.md)。它也不是 `torbox` 条目。那个条目列出的是你的种子，相关内容见 [TorBox](torbox.md) 页面。

## 你需要准备 {#what-you-need}

- **Un plan TorBox Pro.** Un plan inferior no acepta NZB.
- **Tu clave API de TorBox** desde [torbox.app/settings](https://torbox.app/settings).
  Es la misma clave que usa una entrada `torbox`.
- **Una nightly actual de zurg.** Las nightly requieren una suscripción activa.
- **Un host normal.** zurg+rex Android, un servidor de Plex en tu teléfono, no tiene backend `torbox_nzb`. En un dispositivo Android, reproduce los NZB alojados en TorBox a través de TorBox Cast de DMM o del addon de Kodi.

## 配置它 {#configure-it}

该条目需要填写 `token`，没有 `nntp` 块。`watchlist` 不能在这里设置，因为 NZB 账户无法添加种子。

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

在全新的容器安装中，先把你的密钥保存到 `~/zurg/secrets/torbox`，然后再运行设置读取它。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

如果已经有 `config.yml` 的安装，你也可以在 `http://localhost:9999/config/` 的仪表盘里点击 **Add provider**，然后选择 `torbox_nzb`。无论哪种方式，完成后都要重启 zurg。

```bash
docker compose restart zurg
```

## NZB 是如何进入的 {#how-nzbs-get-in}

```
这里说的是 DMM 的 Wanted 和 watchlist 等功能 ...
```

Wait, I need to be careful: no preamble. Here is the translation:

所有进入 `nzb` 条目的内容，都是以同样的方式进入这个条目的；DMM 的 TorBox 操作是唯一绕过 zurg 的路径。

- **监视目录。** 把文件放进配置文件旁边的 `nzbs/` 目录（宿主机上是 `~/zurg/nzbs/`，容器里是 `/config/nzbs/`）。zurg 会把它提交到 TorBox。
- **Sonarr 和 Radarr**，通过 zurg 兼容 SABnzbd 的接口接入。参见 [Sonarr and Radarr for Usenet](../guides/sonarr-radarr.md)。
- **资源获取。** Newznab 索引器、DMM Wanted 和 watchlist 会把内容抓取到这里。参见 [Acquisition](../guides/acquisition.md)。
- **DMM 的 TorBox 操作**作用于 Usenet 结果时，会直接把 NZB 发送到 TorBox。该资源也会列在 zurg 中，但 zurg 并没有保存它的 NZB，所以一旦 TorBox 删除了它，修复按钮就无法重新获取。

如果 TorBox 无法获取某个帖子，它会被报告给 Sonarr 或 Radarr 为下载失败。客户端会将该资源加入黑名单，然后重新搜索。

## 与 `nzb` 的区别 {#what-differs-from-nzb}

- **没有新闻源账户。** 这里不需要考虑连接数配额，也不用权衡服务商的保留期。TorBox 自己的缓存决定一个帖子能从哪里获取。
- **这里不解码任何文章。** TorBox 会获取整个发布内容。文章获取、PAR2 修复、文章缓存和文章检查都不适用，只有解压档案的磁盘缓存仍然生效。抓取是否完成，只看 TorBox 是否已经获取了它。
- **30 天缓存。** 如果别人已经在 TorBox 上获取过某个发布内容，它会立即可用。TorBox 会在缓存后 30 天删除该发布内容。仪表盘上的 repair 按钮会再次提交其 NZB 来重新获取，所以请把文件保留在 `nzbs/` 中。zurg 不会自行重新提交，因为 TorBox 会把无人值守的重复下载视为滥用。
- **每个进行中的 NZB 占用一个槽位。** TorBox 仍在获取的帖子会占用你套餐中的一个活动槽位。同一个密钥下的 `torbox` 条目，其种子也会使用这些槽位。
- **每小时 60 个帖子。** 每个密钥每小时 TorBox 最多接收这么多个新的 NZB。如果积压量很大，例如首次启动时 `nzbs/` 里已经有完整内容，就需要几个小时才能处理完。

## 每个实例一个 NZB 账户 {#one-nzb-account-per-instance}

一个实例只能使用一个 `nzb` 条目或一个 `torbox_nzb` 条目，两者不能同时用。两个都用的话，会把 `nzbs/` 里的每个文件都列出来。要同时运行两种，就给另一种单独开一个实例，并使用它自己的工作目录。两个实例都设置了 `dmm_api_key` 的话，[在其中一个实例上关闭 `dmm-wanted` 源](../guides/dmm-wanted.md#two-zurgs-on-one-key)，否则每个 Wanted 标题都会被抓取两次。这两种实例都可以和你的 debrid 账户并存。

zurg 的 Stremio 插件会把它选中的资源发送到该实例所绑定的 NZB 账户。使用 `torbox_nzb` 时，如果 TorBox 已经缓存了某个资源，并且此时没有其他 NZB 请求在排队，那么它会在插件的等待时间内开始播放。如果资源还没有缓存，就必须先在 TorBox 上下载完成，这通常比播放器的等待时间更长。

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

使用只有一个账户时，它自己的文件夹会从挂载的根目录列表中省略，因此挂载点会在 `__all__` 下显示相同的文件。目录名称跟随条目的名称，而名称默认为其类型。
