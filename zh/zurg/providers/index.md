# 服务商 {#providers}

一个 provider 就是 zurg 用来构建资料库的一个账号。每个账号在 `config.yml` 的 `providers:` 下对应一项。你可以只用一个账号，也可以用六个。如果某个版本被多个账号同时持有，它只会列出一次，并从当前能提供它的那个账号读取。

| 服务 | `type` | 页面 |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

有三个页面比基础设置讲得更深。[TorBox 限制](torbox-limits.md) 列出了 TorBox 限速背后的实测数据。[TorBox 新闻服务器](torbox-news-server.md) 和 [ElfHosted 新闻服务器](elfhosted-news-server.md) 记录了这些套餐附带的 Usenet 账号实际是什么。在花一个 provider 名额之前，先看看这些页面，再做判断。

本页所有内容都假设你使用 [Docker 设置](../setup/docker.md) 中的容器安装方式。`~/zurg` 是主机上的 compose 目录。`/config` 是容器内看到的同一个目录。整个项目只有一个 `config.yml`，两个路径都指向它。

如果你是在 Linux、macOS 或 Windows 上使用二进制安装，[设置](../setup/index.md) 页面会列出替代 `docker compose restart zurg` 和 `setup` 命令的写法。下面的检查步骤也可以同样套用。请在 zurg 所在的文件夹中运行它们。读取 `logs/zurg.log`，而不是 `docker compose logs`（在 PowerShell 中使用 `Get-Content logs\zurg.log -Tail 100 -Wait`）。运行 `./zurg doctor`（Windows 下是 `.\zurg.exe doctor`）时，不要加 `--working-dir /config`。查看你自己的挂载点时，把 `/zurg_mnt/zurg` 换成你的实际路径：`/mnt/zurg`、`/Volumes/Zurg` 或 `Z:\`，除非你改过 `mount_path`。在 Windows PowerShell 5.1 中要输入 `curl.exe`，不要输入 `curl`。

## 添加账户的三种方式 {#three-ways-to-add-an-account}

要用哪一个，取决于 `config.yml` 是否已经存在。

### 全新安装时使用 setup {#on-a-fresh-install-use-setup}

`zurg setup` 会询问要配置哪些服务商，然后只提示输入它们的凭据。它**仅在还没有 `config.yml` 时**才写入账户。以后再次运行时，它会放心地更新安装，而不会改动你已有的账户。

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

选择器支持输入编号或名称，并且可以一次选择多个。

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

你输入的任何内容都不会写入 compose 文件，也不会留在 shell 历史记录里。令牌会直接写入 `config.yml`，并且该文件只有所有者可读写。

### 已有安装时使用 Dashboard {#on-an-existing-install-use-the-dashboard}

打开 `http://localhost:9999/config/`，在 Essentials 下点击 **Add provider**。
选择类型，粘贴 token，然后保存。Dashboard 会把这条配置写回到你 compose 文件旁边的同一个 `config.yml` 里。

修改 provider 之后需要重启才会生效。Dashboard 会提示你这一点，重启只需要一条命令。

```bash
docker compose restart zurg
```

### 或者手动编辑 config.yml {#or-edit-configyml-by-hand}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

文件在主机上的路径是 `~/zurg/config.yml`。添加这一条配置然后重启即可。

`mount_path` 在容器里是 `/zurg_mnt/zurg`，compose 文件必须绑定 `/zurg_mnt:/zurg_mnt:rshared`，挂载点才能传到主机上。这一点就是 [Docker 设置](../setup/docker.md)页面里的内容，也是容器安装与二进制安装唯一不一样的地方。

## 无人值守安装 {#unattended-installs}

每个服务商都有一个 token 文件参数和一个环境变量。要添加多个账户，就为每个账户重复使用 `--provider`。

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | 参数 | 环境变量 |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` 或 `TOKEN` 或 `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file`，配合 `--nntp-host` 和 `--nntp-username` | `NNTP_HOST` 等 |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` 不会仅凭 `TORBOX_TOKEN` 或 `--torbox-token-file` 自动推断，请传入 `--provider torbox_nzb`。

使用 `--non-interactive` 且完全不加 `--provider` 时，setup 会读取上面这些变量中已经设置的那些。

!!!warning 运行中的容器只会预置 Real-Debrid
zurg 守护进程本身只在创建 `config.yml` 的那次运行中读取 `TOKEN`、`RD_TOKEN` 和 `MOUNT_PATH`，也就只有这些。`TORBOX_TOKEN` 等其他变量由 `zurg setup` 读取。只把它们写进 compose 的 `environment:` 块然后启动容器，是不会生效的。请运行 setup，或者在 Dashboard 中添加账户。
!!!

## 每个条目接受的内容 {#what-every-entry-accepts}

| 键 | 作用 |
|---|---|
| `type` | 必填。上面列出的八种类型之一。 |
| `name` | 默认与 `type` 相同。用于区分同一服务上的两个账户。 |
| `token` | API 密钥。`nzb` 类型不使用。 |
| `disabled` | 停用该账户，但保留凭据不删除。 |
| `watchlist` | 标记后，新添加的种子会优先尝试使用该账户。 |
| `add_torrents` | 设为 `false` 后，该账户仍会提供串流服务，但不会再分配新内容。 |
| `warm_connections` | 每个主机保持打开的连接数，这样读取时就不必每次重新建立连接。 |

完整说明和其他内容请见[配置参考](../reference/config.md#accounts)。

## 加载器强制执行的规则 {#rules-the-loader-enforces}

名称必须唯一。两个 Real-Debrid 账户需要分别使用 `name: rd-main` 和
  `name: rd-backup`，否则加载会失败。
名称 `e` 保留给 `.strm` 链接路由使用，请换一个其他名称。
最多只能有一个条目设置 `watchlist: true`。
同一个条目同时设置 `watchlist: true` 和 `add_torrents: false` 会被拒绝。
只支持一个已启用的 `nzb` 或 `torbox_nzb` 条目。多余的新闻服务器
请放在 `nzb` 条目的 `nntp.servers` 下面。
如果所有条目都被禁用，加载会失败。
Premiumize、Debrid-Link 和 Offcloud 会拒绝 `download_tokens`，以及与 `token` 不同的
`strm_link_token`。它们的文件 ID 只属于一个账户，
所以第二个账户必须另建一个条目。

## 检查是否生效 {#check-it-worked}

先从日志和诊断开始。

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

在 Docker 中，`WARN service zurg is not installed` 属于正常现象，因为 Compose 负责自动启动。警告不会让 doctor 失败，只有 `FAIL` 才会。

然后从 Dashboard 或命令行测试账户本身。

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` 表示凭据验证通过。路径中的名称就是账户的 `name`，默认与其 `type` 相同。如果你在 `config.yml` 中设置了 `username`，就加上 `-u user:pass`。没有设置的话，Dashboard 及其 API 在你发布的端口上是开放的。

最后，查看挂载点上的媒体库。

```bash
ls /zurg_mnt/zurg/__all__/
```

每个已配置的账户都会有一个 `__<name>__` 目录。它包含该账户的全部内容，并将读取固定到该账户。`__torbox__/Some.Release/` 只会从 TorBox 串流，不会走其他途径。由于 `__all__` 与之是同一个媒体库，单个账户的文件夹不再列在挂载点的根目录中。`/http/__torbox__/` 之类的 HTTP 和 WebDAV 直接路径仍然可以访问。通过挂载点访问时，它也不再能解析；请把所有使用 `__<name>__` 的媒体库或脚本改为指向 `__all__`。

大型媒体库首次加载需要一些时间。在加载完成前，`/dav/movies/` 会返回 503，挂载点可能什么也列不出来。

## 运行多个账户 {#running-several-accounts}

只有一处需要注意顺序。`providers:` 列表的顺序，就是接受添加操作的账户被尝试的顺序。设置了 `watchlist: true` 的账户，无论排在哪里，都会优先被尝试。对于列出和读取文件而言，顺序没有任何优先级。

在把媒体服务器指向结果之前，有两点值得了解。

- 同一个资源会同时出现在你的过滤目录**以及**每个包含它的 `__<name>__` 目录下。让 Plex 或 Jellyfin 只指向挂载点的某一部分，而不是整个挂载点，否则它会把同样的内容扫描好几遍。
- 在 `__<name>__` 目录内部不会静默切换。某个文件在一个账户上失效时，该目录下会返回 404，但它仍可以在另一个账户的目录下播放。挂载点的其他部分仍然可以正常提供该文件。
