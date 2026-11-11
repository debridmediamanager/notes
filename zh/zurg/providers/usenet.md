# Usenet

`type: nzb`

Usenet 是一种提供商类型，但不是 debrid 服务。它没有 API token，也没有远程库。你把 `.nzb` 文件放进监视目录，zurg 会把每个文件变成一个 release。播放器请求数据时，文章才会从你的新闻服务器获取并解码。

本页只介绍提供商条目和 Docker 的具体设置。关于在 zurg 上运行 Usenet 的其他内容，都在 [Usenet with zurg](../guides/usenet.md) 中。那里是完整的教程，包括新闻账号、NZB、挂载和 Plex。建议你在读完本页后再去看那篇。

## 配置它 {#configure-it}

这里没有 `token`。只要有带 host 的 `nntp` 块，这一条配置才算有效。

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

把 `connections` 设为你的套餐实际允许的数量。zurg 按这个数量读取，因为单个连接只能占到套餐吞吐量的一部分。流媒体播放时会用满这个配额，而不是一次只取一篇文章。超过套餐允许的数量，连接会被拒绝。

如果是全新安装容器，setup 会提示你填写所有内容。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

如果是无人值守安装，密码从文件读取，其他所有参数都通过命令行标志传入。

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` 默认为 true。`--nntp-port` 的默认值是：开启 TLS 时为 563，未开启时为 119。

如果安装中已经有 `config.yml`，可以在 `http://localhost:9999/config/` 的 Dashboard 中使用 **Add provider**，也可以直接编辑该文件。两种方式改完后都要重启。

```bash
docker compose restart zurg
```

## 容器中 NZB 的存放位置 {#where-the-nzbs-go-in-a-container}

监视目录是配置文件旁边的 `nzbs/`。也就是说，宿主机上是 `~/zurg/nzbs/`，容器内是 `/config/nzbs/`。两者是同一个目录。请从宿主机放入文件。

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

如果只有一个账户，它自己的 `__nzb__` 文件夹不会出现在挂载根目录的列表中，所以请到 `__all__` 下查找。监视目录大约每 15 秒检查一次。由于它位于 `./:/config` 绑定挂载之内，因此和其他内容一样，在执行 `docker compose pull` 和重新创建容器后依然保留。

## 此类型的专用规则 {#rules-specific-to-this-type}

- **Só pode haver uma entrada `nzb` ativada.** Duas iam escanear o mesmo diretório e duplicar cada release. Mais servidores de notícias devem ir dentro de `nntp.servers` dessa única entrada. Assim servem a mesma biblioteca, em vez de criar uma segunda cópia dela. Uma entrada `nzb` ao lado de uma [`torbox_nzb`](torbox-nzb.md) também é recusada, pelo mesmo motivo.
- **`watchlist: true` é recusado.** Um servidor de notícias nunca recebe um torrent.
- **`add_torrents` é ignorado** e o arranque avisa disso, pelo mesmo motivo.
- **`download_tokens` e `strm_link_token` não fazem nada.** Não há nenhuma credencial para rodar.
- **O diretório é `__nzb__`** porque o nome assume por defeito o tipo. Defina `name: usenet` na entrada se preferir navegar por `__usenet__`.

## 第二个新闻服务器的价值比你想象的更大 {#a-second-news-server-is-worth-more-than-it-looks}

Retention 是按服务商分开计算的。一个服务器已经过期的文章，通常在另一个服务器上还能找到。如果没有第二个账号，恢复一篇失效的文章只能靠 PAR2，而这需要读取**整个发布内容**。所以第二个服务器的作用是：只需抓取一篇文章，还是要把所有内容重新读一遍，两者的差别就在这里。

额外的账号应该放在这个条目的 `nntp.servers` 下面，而不是新建第二个 `nzb` 条目。`priority`、`backup` 和 `backbone` 决定先问谁、按什么顺序来问。读取速率按所有未标记为 `backup` 的账号的合计额度来控制。完整的配置示例以及每个键的作用，请见 [Usenet with zurg](../guides/usenet.md#more-than-one-usenet-provider)。

## 检查是否生效 {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

使用只有一个账号时，它自己的文件夹不会出现在挂载的根目录列表中，因此挂载点会在 `__all__` 下显示同样的文件。

这里的探测会从现有连接池中最多占用一个连接，向新闻服务器进行身份验证。没有可以查询的账号 API。

## 出错时怎么办 {#when-it-goes-wrong}

**读取时出现撕裂，zurg 一次只能处理一篇文章。** `pipeline_depth` 设得比服务器能承受的值高。zurg 会自己把它调低并发出警告。如果服务器无法同时处理多个命令，请显式设为 `1`。

**高延迟链路上吞吐量很差。** 不要设置 `socket_receive_buffer_kb`。固定的缓冲区会让内核停止调优它。在 Linux 上，这会把接收窗口卡在 64 KiB 左右，账户的大部分吞吐量就白白损失了。

其他问题都在 [使用 zurg 的 Usenet](../guides/usenet.md#troubleshooting) 的故障排除表格里有对应条目。连接被拒绝、串流缓慢、供应商从未被请求，以及在 Dashboard 中编辑后 `nntp.servers` 被删掉，这些都能在那里找到。
