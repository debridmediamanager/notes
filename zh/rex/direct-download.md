# 应用从你的服务商下载 {#apps-download-from-your-provider}

正常情况下，rex 会读取来源中的每部电影，然后把它交给 Plex。如果来源返回的是文件链接，比如
debrid 下载链接，rex 可以把它直接交给 Plex。然后由 Plex 下载文件，rex 所在的机器不承载任何媒体。

这种方式只在 Plex 能够直接播放该文件时有效。需要 rex 转换的文件仍然要经过 rex，或者在你选择的情况下被拒绝。

于 2026-10-25 测试，环境为 zurg 搭配 Real-Debrid、Plezy 与 Android 版 Plex（Pixel 6），以及 Chrome 中的 Plex Web。

## 开始之前 {#before-you-start}

**为共享的 debrid 播放保留默认代理模式。** 重定向并不是共享同一个 debrid 账号的安全方式：

- **Real-Debrid 会记录每个下载端的公网 IP。** 同一个账号从多个 IP 使用，即使 CDN 能正常提供文件，也会收到共享警告。该账号的所有使用都应保持在同一个公网 IP 上。远程应用直接下载，而 rex 或其源在服务器 IP 上探测或转换，就违反了这条规则。播放成功并不能证明它是安全的。
- **TorBox 的下载链接在 `?token=` 中包含完整的 API 密钥。** 使用重定向会让每个客户端和共享用户账号都能访问它，包括删除操作，而不只是访问该文件。播放器日志和浏览器历史可能会保存这个密钥。不要把这些链接交给不可信的客户端。

只有在你能接受这些风险时才继续。保留 rex 的默认代理模式，意味着 rex 自己跟随源的重定向，而不是把服务商的链接交给应用。

| 你需要 | 原因 |
|---|---|
| 按照 [rex 与你自己的应用](any-source.md)、[rex 与你的 Stremio 插件](stremio.md) 或 [rex 与 zurg](with-zurg.md) 的说明完成设置，并且一部电影可以正常播放 | 本页会修改 rex 的启动命令，并且对部分源还会修改该源的一个设置 |
| rex nightly **2026.10.26 或更新版本** | 旧版本没有这个设置。请按照 [rex 的更新部分](any-source.md#updating) 进行更新 |
| 一个能返回链接的源 | rex 只能转交源提供给它的链接。[第 1 步](#step-1-let-your-source-hand-out-links) 说明了哪些源可以做到 |

## 选择严格程度 {#choose-how-strict}

| | `redirect` | `redirect-only` |
|---|---|---|
| 应用直接播放文件 | 应用从你的服务商下载 | 应用从你的服务商下载 |
| 应用需要转换文件（画质更低、无法播放的音频、烧录字幕） | rex 转换文件，和以前一样从你的源读取文件 | 拒绝：应用会显示错误 |
| 源直接发送的文件，而不是链接（比如 zurg 的 Usenet 文件） | 和以前一样通过 rex 播放 | 拒绝 |
| Plex Web | 能播放，经过 rex | 每个 Real-Debrid 文件都会被拒绝（见下文） |

如果你想让所有内容都能继续播放，同时尽量省流量，就选 `redirect`。如果 rex 所在的机器绝对不能承载电影，比如流量有上限的小型 VPS，就选 `redirect-only`。

无论选哪个，你分享 rex 的每个应用和每个人，拿到的都是你的源为 rex 提供的、他们所播放内容对应的链接。而链接背后的服务（比如你的 debrid 服务）会看到他们每个人都在下载这个文件。

## 第 1 步：让你的来源提供链接 {#step-1-let-your-source-hand-out-links}

**作用。** 你的数据源在每次读取时,不返回文件本身,而是返回一个指向别处文件的链接(HTTP 重定向)。

**为什么重要。** rex 只能转发数据源给它的链接。如果数据源直接发送文件本身,文件仍会经过 rex 转发。

| 数据源 | 该怎么做 |
|---|---|
| [rex-stremio](stremio.md) | 无需操作:它返回的是 stream 插件提供的链接。需要自带请求头的链接,以及直播播放列表,仍由它自己发送 |
| [zurg](with-zurg.md) | 开启下文介绍的 `disable_stream_proxy`。zurg 没有 Usenet 文件的链接,所以这类文件始终由它自己发送 |
| [你自己的应用](any-source.md) | 对文件的 `GET` 请求返回 `302` 或 `307`,并指向该链接 |

### zurg

这个设置属于 zurg，所以其他读取 zurg 的程序（rclone、挂载了 zurg 的 Plex 或 Jellyfin 服务器）也会用到这些链接。详情请参阅 zurg 的[配置参考](../zurg/reference/config.md)。

+++ Linux 和 macOS
先看看这个设置是否已经在 zurg 的配置里：

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

如果它输出了一行，就用 `nano ~/zurg/config.yml` 把它改成 `disable_stream_proxy: true`。如果没有输出，就把它加进去：

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
用 `notepad $HOME\zurg\config.yml` 打开 zurg 的配置文件。如果里面有 `disable_stream_proxy:` 这一行，就把它改成 `disable_stream_proxy: true`；如果没有，就在文件末尾添加这一行。保存后重启 zurg：

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
进入 zurg 所在的文件夹：

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

如果它输出了一行，就用 `sudo nano config.yml` 修改它。如果没有输出：

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**你应该看到的效果。** zurg 会像平常一样重新启动。到这一步为止，电影仍然通过 rex 播放：rex 会自己跟随链接，直到第 2 步为止。

## 第 2 步：让 rex 转发链接 {#step-2-let-rex-pass-the-links-on}

**功能说明。** rex 会把你的来源提供的链接直接交给应用，而不是替它下载电影。

在 rex 的启动命令末尾加上 `--part-mode redirect`（或 `--part-mode redirect-only`），然后重启 rex 并打开它的日志。[安装 rex](any-source.md#step-1-install-rex) 页面说明了启动命令在你的系统中的位置，以及如何重启 rex 和查看日志。在 Linux 上，`~/.config/systemd/user/rex.service` 中的 `ExecStart` 这一行应当像这样，除此之外不要再添加其他内容：

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

该行上已有的内容保留，例如 `--port 32500` 或 `--announce-url ...`。

**你应该看到的内容。** 启动那一行以 `parts=redirect` 结尾：

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

如果使用 `redirect-only`，则以 `parts=redirect-only` 结尾，并且上面几行中 rex 会显示 `transcoder off: --part-mode redirect-only`。

## 第 3 步：播放内容 {#step-3-play-something}

保持 rex 的日志窗口打开，然后在 Plezy 或 Android 版的 Plex 中播放一部电影。

**你应该看到什么。** 应用每读取一次数据，日志里就会出现一行，标明你的服务商服务器：

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

这说明 rex 把应用转到了链接所在的服务器，这里是 Real-Debrid 的服务器。如果某行以 `-> 206 len=...` 结尾，则说明 rex 直接发送了影片本身。请参阅 [如果无法正常工作](#if-it-does-not-work)。

## 每个应用的作用 {#what-each-app-does}

| 应用 | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | 从你的服务商下载 | 从你的服务商下载 |
| Plex for Android, Original quality | 当 rex 允许按原样播放文件时，从你的服务商下载 | 相同 |
| Plex for Android, a lower quality, or audio it cannot play | rex 进行转换 | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | 通过 rex 播放 | "Playback Error: This server is not powerful enough to convert video." |

Plex Web 完全无法使用 Real-Debrid 的链接：Real-Debrid 把它的文件标记为下载，而不是视频，浏览器会拒绝播放。在 `redirect` 模式下，Plex Web 会在一秒内悄悄回退到通过 rex 转换，所以仍然能正常工作；在 `redirect-only` 模式下则没有可以回退的选项。

## 在 Docker 中 {#in-docker}

如果你按照 [在 Docker 中运行 rex](any-source.md#run-rex-in-docker) 的步骤操作，第 2 步是在 rex 的 `compose.yml` 里，`rex:` 下面、紧挨着 `image:` 的地方添加一行 `command:`：

```yaml
    command: --part-mode redirect
```

已经有 `command: --port 32500` 了？那就改成 `command: --port 32500 --part-mode redirect`。然后在 rex 的文件夹里运行 `docker compose up -d`，再运行 `docker compose logs -f rex`，就能看到同样的 `parts=redirect` 日志行。

## 如果无法正常工作 {#if-it-does-not-work}

| 你看到的 | 含义 |
|---|---|
| rex 因 `--part-mode` 报 `invalid choice` 退出 | rex 版本早于 2026.10.26。请按 [rex 的更新部分](any-source.md#updating) 所述进行更新 |
| rex 日志对每次读取都显示 `-> 206 len=...` | 数据源仍然直接发送文件本身。使用 zurg 时，zurg 配置中缺少 `disable_stream_proxy: true`，或者在第 1 步之后没有重启 zurg |
| 只有部分影片出现 `-> 206 len=...` | 这些内容由数据源直接发送：zurg 的 Usenet 文件，或者 rex-stremio 必须中转的链接 |
| `-> 403: the source answered with the bytes, not a link` | `redirect-only` 拒绝了数据源直接发送的文件，原因同上 |
| 播放影片时完全没有 `PART` 行 | 应用播放的是转码版本，而不是文件本身。请将其画质设为 Original |

仍然无法解决？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。[获取帮助](../guides/remote-help.md) 中说明了需要提供哪些信息。

## 返回 {#going-back}

从 rex 的启动命令中删除 `--part-mode ...`（如果用的是 Docker，就删除 `command:` 那一行），然后重启 rex。只要去掉了 rex 的这个设置，你的源依然可以继续发放链接：rex 会自己去跟随这些链接。对于 zurg，把 `disable_stream_proxy` 改回 `false` 并重启 zurg，它就会重新自己传输文件，rclone 以及其他读取它的程序也一样。
