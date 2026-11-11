# 命令行 {#command-line}

zurg 二进制文件既是服务器，也是一组工具。不带任何命令运行它就能启动服务器。每个命令都支持 `--help`，输出的内容就是本页的写作依据。

请在实例的工作目录中运行命令。除非你传入 `--config`，否则 zurg 会读取该目录下的 `./config.yml`。它的数据和日志文件夹也是相对于该目录解析的。

```
zurg [flags]
zurg [command]
```

## 所有命令都支持的标志 {#flags-every-command-takes}

| Flag | 作用 |
|---|---|
| `-c`, `--config` | 要读取的配置文件。默认为 `./config.yml`。 |
| `-v`, `--version` | 打印构建版本并退出。输出与 `zurg version` 一致。 |
| `-h`, `--help` | 打印 zurg 或某个命令的帮助信息。 |

## 初始设置 {#setting-up}

### zurg setup

会写入配置文件，并下载 rclone 和 ffprobe。然后它会把 zurg 注册为自动启动。缺少的内容它会向你询问。`--dry-run` 会打印执行计划，但不做任何更改。

密钥和密码从文件中读取。这样它们就不会留在你的 shell 历史记录里。

| 参数 | 作用 |
|---|---|
| `--provider` | 要配置的提供商。需要配置多个时可重复使用此参数。可选值为 realdebrid、torbox、alldebrid、nzb、premiumize、debridlink、offcloud、torbox_nzb 之一。torbox_nzb 会像 torbox 一样，从 `--torbox-token-file` 或 `TORBOX_TOKEN` 读取密钥。 |
| `--realdebrid-token-file` | 从此文件读取 Real-Debrid 令牌。`torbox`、`alldebrid`、`premiumize`、`debridlink` 和 `offcloud` 也有同样的参数。 |
| `--nntp-host` | `nzb` 提供商使用的新闻服务器。 |
| `--nntp-port` | 新闻服务器的端口。启用 TLS 时默认为 563，未启用时默认为 119。 |
| `--nntp-tls` | 使用 TLS。默认开启。 |
| `--nntp-username` | 新闻服务账号的用户名。 |
| `--nntp-password-file` | 从此文件读取新闻服务账号的密码。 |
| `--nntp-connections` | 新闻服务账号允许的连接数。默认为 8。 |
| `--mount-path` | 挂载点出现的位置。默认使用你所在平台的惯例路径。 |
| `--port` | HTTP 端口。如果省略此参数，会保留配置文件中已有的值。 |
| `--service-name` | 服务或计划任务的名称。默认为 `zurg`。 |
| `--service-scope` | `auto`、`user` 或 `system`。默认为 `auto`。 |
| `--service-user` | 系统服务运行所用的用户。 |
| `--no-service` | 完成所有配置，但不注册自动启动。 |
| `--no-start` | 注册服务，但不启动它。 |
| `--skip-downloads` | 不下载 rclone 和 ffprobe。 |
| `--skip-prerequisites` | 跳过当前平台的 FUSE 检查。 |
| `--non-interactive` | 遇到缺少的输入时直接失败，而不是询问。 |
| `--dry-run` | 打印执行计划，但不做任何更改。 |

每个平台都有各自的分步指南。

- [Linux](../setup/linux.md)
- [macOS](../setup/macos.md)
- [Windows](../setup/windows.md)
- [Docker](../setup/docker.md)

### zurg doctor

检查安装程序放置的内容。它会读取配置,并查找 rclone 和 ffprobe。然后检查服务、HTTP 端点和挂载点。出现问题时先运行它。

| Flag | What it does |
|---|---|
| `--working-dir` | The instance's working directory. Defaults to the current one. |
| `--service-name` | The service name to check. Defaults to `zurg`. |
| `--service-scope` | `auto`, `user` or `system`. Defaults to `auto`. |

### zurg service

只安装并控制开机自启,不运行其余的设置步骤。

| 命令 | 作用 |
|---|---|
| `zurg service install` | 安装开机自启并立即启动。加上 `--start=false` 可以只安装、不启动。 |
| `zurg service uninstall` | 移除开机自启。配置和数据会保留。 |
| `zurg service start` | 启动已安装的服务。 |
| `zurg service stop` | 停止服务。 |
| `zurg service restart` | 重启服务。 |
| `zurg service status` | 显示开机自启的状态。 |

这些命令都接受相同的参数。

| 参数 | 作用 |
|---|---|
| `--name` | 服务或计划任务的名称。默认为 `zurg`。 |
| `--scope` | `auto`、`user` 或 `system`。默认为 `auto`。 |
| `--user` | 系统服务运行时所用的用户。 |
| `--working-dir` | 服务启动时所在的工作目录。 |
| `--executable` | 服务运行的 zurg 可执行文件。 |

### zurg download-requirements

将 rclone 和 ffprobe 下载到一个文件夹中，并把它们的路径写入配置文件。除非你传入 `--skip-downloads`，否则 Setup 会自动为你完成这些操作。

| 参数 | 作用 |
|---|---|
| `--dir` | 二进制文件存放的位置。默认为 `bin`。 |
| `--rclone-version` | rclone 的发布版本，例如 `1.67.0`。默认为 `latest`。 |
| `--ffprobe-version` | ffprobe 的发布版本。默认为 `latest`。 |

### zurg update

这会用最新的赞助者 nightly 版本替换二进制文件。它使用的 GitHub 账户需要有 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 的赞助者访问权限。如果是在容器内运行，它会拒绝执行，因为下一次重新创建容器时会丢弃新的二进制文件。这种情况下请改为拉取新的镜像。`--force` 可以强制更新。

它通过 GitHub CLI 登录 GitHub。使用的是 PATH 中的 GitHub CLI，或者安装脚本放在 zurg 旁边 `bin` 目录里的那一个。即使 GitHub CLI 本身已经不在了，不带 keyring 保存的登录信息仍然可用。`GITHUB_TOKEN` 也可以。如果都找不到，它会打印用于重新安装 GitHub CLI 的安装命令。

### zurg version

打印构建信息。`zurg --version` 会输出同样的内容。

## 获取帮助 {#getting-help}

### zurg 支持 {#zurg-support}

发送给 DMM 支持团队的内容包括你的日志和配置，并会打印一个支持代码，例如 `K7QM-3XPD`。请把这个代码贴到你在 Discord 上的支持帖子里。该内容会保留 7 天，只有 DMM 支持团队能打开。

它发送的内容与仪表板上的 **Export Logs** 相同，所以当 zurg 无法启动，或者你无法访问仪表板时使用它。请在 zurg 的工作目录中运行：它会读取那里的 `config.yml`（或 `--config` 指定的文件）和 `logs/zurg.log`。在 Docker 中，运行 `docker exec <container> /app/docker-entrypoint.sh support`，它会自动选择正确的目录。如果容器无法保持运行，请使用与挂载 zurg 时相同的文件夹，运行 `docker run --rm -v <your config folder>:/config ghcr.io/debridmediamanager/zurg:<tag> support`。

发送前，令牌、密码、下载链接和你自己的主机名会先被移除，处理方式与仪表板相同。如果配置无法加载，则不会发送配置文件，而是发送它给出的错误信息。过长的日志会从最旧的一端截断以便符合大小限制，压缩包中会注明这一点。

如果 DMM 的支持服务器无法访问或拒绝了上传，zurg 会说明原因，并改为把这两个文件发送到公共粘贴网站，同时打印它们的链接。如果什么都无法发送，它会把同样经过脱敏的文件写入 `zurg-debug.tar.gz`，你可以将其附加到你的支持帖子中。

## 备份 {#backups}

### zurg backup

会生成一个 `.zurgbackup` 文件，里面保存的是其他地方都无法重建的内容。具体包括：包含令牌的配置文件，以及每个 `data/*.zurgtorrent` 文件和它的标签与账户关联。它还包括 `data/local/` 下的 `__magic__` 存储，以及 `nzbs/` 下的原始 NZB 文件。缓存、Plex 快照和日志都不会打包，这样备份文件的大小只和它要保护的内容相当。

实例不需要处于运行状态，所以可以放心地设置定时任务。这个文件是一个 gzip 压缩的 tar 包，里面包含你的令牌。请像保管密码一样保管它。

| 参数 | 作用 |
|---|---|
| `-o`, `--out` | 指定写入位置。默认为当前目录下的 `zurg-<timestamp>.zurgbackup`。 |
| `--include-caches` | 同时打包派生的元数据和缓存数据，用于快速恢复。Plex 快照和日志仍然不包括。这个文件可能会很大。 |

### zurg restore-backup

将 `.zurgbackup` 解压到当前目录。每个文件都会还原到它原来的路径。请先停止 zurg，因为还原时会写入运行中的实例也在写入的文件。

```
zurg restore-backup my-backup.zurgbackup
```

目录中已有的配置文件会保持不变。这个文件保存着整个库所依赖的令牌。如果要覆盖它，请加上 `--force-config`。

## 测量 {#measuring}

### zurg benchmark-my-setup

像播放器一样读取真实字节，并报告波动范围，而不是单一数字。

它分三个阶段运行。第一阶段是每个账号单独测试，这个数字可以拿来和服务商承诺的数值对照。第二阶段是所有账号同时测试。如果每个账号单独能跑到 70 MiB/s，同时跑时却只有 25 MiB/s，说明它们共用了一条已经跑满的上行链路。最后一阶段通过 rclone 挂载读取。它和第一阶段的差距，就是 FUSE 和 VFS 带来的开销。

采样会落在随机偏移位置。底层每一层都有缓存，如果反复读取同一个偏移，测到的就是缓存，而不是链路本身。

它不会添加也不会删除任何东西，但会占用你的带宽。每个账号要读取「采样大小 × 迭代次数」的数据，共两遍。挂载阶段还要额外算进去。

| 参数 | 作用 |
|---|---|
| `-n`, `--iterations` | 每个阶段、每个账号的采样次数。默认值为 3。 |
| `--sample-mb` | 每次采样读取的 MiB 数。默认值为 128。设为 1024 可以越过 rclone 的 read-chunk 逐步增长阶段，得到稳定的挂载速度数值。 |
| `--provider` | 只测试指定名称的账号。可重复使用。 |
| `--skip-concurrent` | 跳过所有账号同时测试的阶段。 |
| `--skip-mount` | 跳过挂载阶段。 |
| `--json` | 以 JSON 格式输出报告。 |

### zurg network-test

此工具用于测量本机到各个 Real-Debrid 下载服务器的连接速度，分别测试 IPv4 和 IPv6。结果会写入 `logs/network-test.log`，同时保存到 `data/`，服务器会从那里读取数据来选择要使用的主机。如果想通过代理进行测试，请在环境变量中设置 `PROXY`。

| 参数 | 作用 |
|---|---|
| `-t`, `--test-url` | 指定一个文件 URL，测试时会从每台服务器上获取该 URL 路径下的文件，而不是使用 Real-Debrid 自带的测速文件。 |

## Plex

这三个都要对接这台主机上的 Plex 服务器。先配置 Plex。参见 [Plex Integration](config.md#plex-integration)。

### zurg plex-settings

报告对挂载有影响的 Plex 设置,并按策略进行修正。Plex 的默认设置是为本地磁盘设计的。其中一项会在扫描遇到短暂故障时删除媒体库。其他设置会让 Plex 解码它拥有的每一个文件。[plex.md](../guides/plex.md#recommended-plex-settings) 解释了每一项设置。

| Flag | What it does |
|---|---|
| `-p`, `--policy` | `off`、`warn`、`guard` 或 `enforce`,仅对本次运行有效。默认值为配置中的 `plex_settings_policy`。传入更严格的策略可以先预览效果,再决定是否采用。 |

### zurg plex-drift

这个工具只读取 Plex 的数据库，不会写入。它会检查数据库里指向挂载目录下的每个文件，并报告那些已经不存在的。请在扫描媒体库之前运行它。如果扫描碰到这些文件，就会把它们变成删除操作。先知道数量，扫描就成了一个有把握的决定，而不是赌博。

它需要 `plex_database_path`，并且 Plex 与它必须在同一台主机上。

### zurg plex-backups

列出 zurg 保存的 Plex 数据库快照，最新的排在最前。每一行显示快照的拍摄时间、大小，以及拍摄时每个媒体库里有多少条目。这些数量直接取自快照本身，所以列表显示的正是每个快照实际能还原的内容。[Plex 库维护](config.md#plex-library-maintenance-same-host-only)说明了 zurg 何时会拍摄这些快照。

## 分享 {#sharing}

### zurg export-torrents

写出便携的 `.zurgtorrent` 文件，用来描述你的资源，文件里不包含你的账号信息。不会写入任何凭据，也不包含 torrent id、修复状态或 CDN 链接，而且不会联系任何服务商。

它会读取 `data/*.zurgtorrent` 或旧的导出文件。传入一个文件或文件夹，就只导出那些内容。接收方把文件放到 `torrents/<their-account>/` 里，并把该账号设置为 `library.source: local`。接收端的说明见 [portable-libraries.md](../guides/local-libraries.md)。

| 参数 | 作用 |
|---|---|
| `--provider` | 导出这个已配置账号所持有的资源。 |
| `--output` | 便携文件的保存位置。 |
| `--replace` | 替换相同 hash 的已有导出文件。 |
| `--skip-invalid` | 批量导出时，跳过并统计无法读取的条目。 |

### zurg nzb-share

构建你的 NZB 中一部分的分享包，你可以将其发布。结果是一个文件夹，里面有一个 `manifest.json`，以及每个发布资源一个 `.nzb.gz` 文件，文件名为内容哈希。每个 NZB 都会先清理。注释、DOCTYPE 和水印元数据会被删除。原始文件名也会被删除。发帖人和日期同样会删除，每个文件都会使用同一个固定的新闻组，因为有些索引站每次下载时都会改动这三项。索引站在主题、标题或密码中隐藏的账户标记会被剪掉。你发布的内容只包含发布资源的名称，绝不包含下载它的账户。真正的压缩包密码会保留，因为接收者需要它们才能读取资源。

把这个文件夹发布到任何静态位置即可。Git 仓库可以用，Pages 站点或 `rclone serve` 也可以。被剥离内容的审计记录保存在你的电脑上，并会在这里打印出来。它包含的正是这次清理要去除的那些标识符。

| 参数 | 作用 |
|---|---|
| `--from` | 要分享的监视文件夹。会递归遍历。默认为 `nzbs`。 |
| `--out` | 输出文件夹。默认为 `nzb-share-<timestamp>`。 |
| `--title` | 记录在清单中的标题。 |
| `--filter` | 只分享与此正则表达式匹配的源路径。 |

仪表盘也可以提供分享服务。参见 [公开 NZB 分享](config.md#public-nzb-sharing)。

### zurg nzb-sync

将共享库拉取到你的监视文件夹中。它会从 URL 或本地路径读取共享的 `manifest.json`。每个 NZB 在写入前都会与清单中的哈希值进行校验。字节数据由你自己的新闻服务账户获取。

```
zurg nzb-sync https://example.com/share/manifest.json
```

它只会添加。你已有的条目会被跳过，共享永远不会删除任何内容。同一发布的两个共享会按内容哈希去重。

| 参数 | 作用 |
|---|---|
| `--into` | 要写入的监视文件夹。默认为 `nzbs`。 |
| `--dry-run` | 报告将会写入的内容，但不写入任何东西。 |

## 清除 Real-Debrid 账户 {#clearing-a-real-debrid-account}

这两个命令会删除 Real-Debrid 账户里某一类的全部内容。删除后无法撤销。它们只适用于 Real-Debrid。

两个命令都要求你提供已登录的 Real-Debrid 浏览器会话中的 `auth` cookie，而不是 API token。命令会打印一行 JavaScript 来显示它。在 real-debrid.com 的浏览器控制台中运行这行代码，然后把结果粘贴进去。

| 命令 | 作用 |
|---|---|
| `zurg clear-torrents` | 删除账户中的所有种子。 |
| `zurg clear-downloads` | 删除账户中的所有下载记录。这些是解除限制后的链接。 |

## Shell 自动补全 {#shell-completion}

`zurg completion bash` 会输出一段 bash 的自动补全脚本。`zsh`、`fish` 和 `powershell` 同样可以。`zurg completion <shell> --help` 会告诉你该把它放到哪里。
