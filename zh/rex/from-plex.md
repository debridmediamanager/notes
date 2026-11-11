# 从 Plex 迁移到 rex {#move-from-plex-to-rex}

你运行着 Plex Media Server，想试试 rex。你的 Plex 应用保持不变，变的只是媒体库来源和服务器地址。

## 有哪些变化 {#what-changes}

| | Plex Media Server | rex |
|---|---|---|
| Where the library comes from | Plex scans folders on a disk or a mount | A source (your own app, rex-stremio or zurg) tells rex what it has. rex never scans a folder and needs no mount |
| What each file is | Plex matches it from its file name | The source works it out and tells rex. rex never reads a file name |
| A wrong match | Fix Match on the server | **Fix Match** in a Plex app, signed in as the account that owns rex. rex keeps your pick, and a source can take it back and keep it, as zurg does ([why titles are placed as they are](with-zurg.md#why-dmm-places-the-files)) |
| The account the server is on | Usually your own | A fresh Plex account made for rex, shared with your own |
| Music, Live TV and photos | From folders and a tuner | Only from a source that sends them, such as an addon ([Building rex addons](addons.md#music)) or zurg's comic books. Plex Web shows photos; Plex for Android does not |
| Recording TV | Yes | No |

## 选择一种方式 {#pick-a-way}

| | 与 Plex 并存 | 取代 Plex |
|---|---|---|
| 你能得到什么 | rex 与你的 Plex 并存。你的应用会同时列出两个服务器 | 只有 rex，使用 Plex 原来的端口 |
| 适合 | 试用 rex，或者保留 Plex 来看硬盘上的照片或音乐，或者录制电视节目 | 彻底迁移 |
| 与 Plex 在同一台机器上 | rex 运行在端口 `32500`，你的应用通过与其共享的 Plex 账户找到它 | 停止 Plex，rex 使用端口 `32400`，家里的应用会自动找到它 |

即使你打算替换 Plex，也请先与 Plex 并存运行：复制观看记录需要你的旧 Plex 服务器处于运行状态。先完成第 1 到 3 步，用一段时间 rex，准备好后再做第 4 步。

## 第 1 步：在 Plex 旁边设置 rex {#step-1-set-up-rex-beside-plex}

按照 [rex with your own app](any-source.md)、[rex with your Stremio addons](stremio.md) 或 [rex with zurg](with-zurg.md) 的说明设置 rex，配好提供内容的数据源，直到能看到视频为止。已经在用 zurg 给 Plex 提供内容？那就不用重新安装，按 rex with zurg 第 1 步的说明更新即可。从 **2026.10.27** 的 nightly 版本起，zurg 会向 rex 提供内容。

- **Plex 和 rex 装在同一台机器上？** 按 [Install rex](any-source.md#step-1-install-rex) 中针对这种情况的说明，把 rex 放在端口 `32500` 上，并让数据源也使用这个端口。这样你的应用里会出现两个同名的服务器（都用机器名）：分享给你的那个是 rex，旁边会带着新账号的名字。改名的方法见 [Install rex](any-source.md#step-1-install-rex)。
- **请在一个新的 Plex 账号上注册 rex**，不要用你 Plex 服务器所用的那个账号。具体见 [Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account)。
- **在外面通过 rex-direct 访问？** 路由器的 32400 端口已经转发给 Plex 了。还需要把端口 `32500` 也转发到 rex 所在的机器上；如果走 [IPv6](any-source.md#rex-direct-over-ipv6)，则要允许 `32500` 端口访问该机器。

在用 zurg？两者同时运行时，zurg 会同时向两边提供内容。请保持 zurg 里原有的 Plex 设置不变（`plex_server_url`、`plex_token`、你的 rclone 挂载和任何扫描脚本）。Plex 会和之前一样工作，再加上 `rex_url` 就能接入 rex。

## 第 2 步：迁移你的观看记录 {#step-2-bring-your-watch-history}

一旦你的库进入 rex，[导入观看历史](import-watched.md) 会把你在 Plex 服务器上的观看记录、观看进度和星级评分复制过来。请在 Plex 仍在运行时进行此操作。你分享内容的每个人都需要为自己的历史记录各自执行一次。

## 第 3 步：重新邀请你的家人和朋友 {#step-3-invite-your-people-again}

你的朋友和家人是被邀请到你的 Plex 服务器上的，而不是 rex。rex 是一个新服务器，在全新的账户上，所以请从那里邀请他们，他们接受邀请的方式和其他任何共享一样：[与家人和朋友共享 rex](sharing.md)。

## 第 4 步：停用 Plex（可选） {#step-4-retire-plex-optional}

仅在用 rex 替代 Plex 时才需要这一步。若想同时保留两者，请跳过。

**彻底停用 Plex。** 在 Linux 上，运行 `sudo systemctl disable --now plexmediaserver`。在 Docker 中，停止它的容器，并把它从 compose 文件里删掉。在 Windows 和 macOS 上，退出 Plex Media Server，并把它从登录时自动启动的应用中移除。

**如果 rex 和 Plex 在同一台机器上使用 `32500` 端口，请把 rex 改到 32400 端口**：

1. 从 rex 的启动命令中删除 `--port 32500`（Docker 中则是 `command:` 那一行），然后按照你系统对应的 [安装 rex](any-source.md#step-1-install-rex) 说明重启 rex。在 Windows 上，请按该步骤的说明，在防火墙中放行 32400 端口和两个发现端口。
2. 把 rex 的新地址 `http://192.168.1.20:32400`（rex 的局域网 IP）填到你的数据源中，然后重启它：即 zurg 的 `rex_url`，或 rex-stremio 设置页中的 **rex's address**。
3. 你在其他地方填过 rex 地址的，例如 Kometa，都把 `32500` 改成 `32400`。
4. 如果使用 rex-direct，请把路由器上 32400 端口的转发指向 rex 所在的机器，并删除 `32500` 的那条转发。如果通过 IPv6 访问，请把防火墙规则从 `32500` 改为 `32400`，然后重启 rex，让它在新端口上提供 IPv6 服务。

此后 rex 会在 32400 端口上响应，家里的 Plex 应用会自动在局域网中找到它。

**在使用 zurg？请整理它的 Plex 设置。** zurg 的配置中可能仍指向你已停用的 Plex：

| 在 zurg 的 `config.yml` 中 | 该怎么做 |
|---|---|
| `plex_server_url` 和 `plex_token` | 两个都删掉，或者在 zurg 仪表盘（配置页，**Media Server Integration**）中点击 Plex 旁边的 **Remove**。如果你在使用 zurg 的 [Plex 片单](../zurg/guides/plex-watchlist.md)，只删除 `plex_server_url`：片单是通过 `plex_token` 从 plex.tv 读取的，不需要 Plex 服务器。你也可以把它们指向 rex：在该处点击 **Re-Auth**，用新账号登录，然后选择 rex。zurg 2026.10.27 及更新版本会识别出服务器是 rex，不再向它发送扫描、Plex 匹配、季度修复或 Plex 设置检查。此时使用的令牌是新账号的，因此 Plex 片单也会跟随该账号 |
| 运行 Plex 扫描的 `on_library_update`，例如 `plex_update.sh` | 删除它。rex 会直接从 zurg 收到每一次变动的通知 |
| `plex_database_path`、`plex_scan_check_url` 和 `plex_scan_check_token` | 删除它们。它们指向的是你已停用的 Plex |
| 你的 rclone 挂载（`rclone_enabled: true`，或你自己运行的 rclone） | 如果 Sonarr、Radarr、Bazarr 或其他程序需要读取那里的文件，就保留它。如果 Plex 是唯一的读取方，你可以关掉它：rex 会直接从 zurg 读取每个文件 |

修改 zurg 的配置后，请重启 zurg。

## 哪些内容会迁移，哪些不会 {#what-comes-along-and-what-does-not}

| Comes along | How |
|---|---|
| Your movies and shows | Your source sends them to rex. With zurg they come from the same debrid account Plex reads |
| What you watched, where you stopped, your star ratings on movies and episodes | [Bring your watch history](import-watched.md), each person on their own |

| Does not come along | Why |
|---|---|
| Fix Matches you made on Plex | rex does not use Plex's matches. Your source says what each file is; fix what it gets wrong with **Fix Match** in rex |
| Collections | Not copied. [Kometa with rex](kometa.md) builds them again from your Kometa config |
| Posters and artwork you picked | Kept on the old server only |
| Playlists, and the server's play history list | Kept on the old server only |
| Your friends' access | They were invited to the old server. Invite them to rex ([step 3](#step-3-invite-your-people-again)) |
| Music and photos on a disk, Live TV from a tuner, and recordings | rex has no tuner and records nothing; music, photos and live channels come only from a source that sends them. Keep Plex beside rex for them |
| Files on a local disk | rex scans no folders. An app has to serve them and tell rex about them: [rex with your own app](any-source.md) |
