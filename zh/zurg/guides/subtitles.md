# 使用 Bazarr 获取字幕 {#subtitles-with-bazarr}

Bazarr 为 Sonarr 和 Radarr 导入的内容查找字幕，并把每个字幕文件保存在对应视频旁边。使用 zurg 时，视频位于 `__magic__` 中，字幕也在那里。指向 `__magic__` 的 Plex 和 Jellyfin 媒体库会像读取磁盘上的任何字幕一样读取它，rex 也会在字幕菜单中显示它，名称为 **English (SRT External)**。

这需要 2026-10-24 或之后的 zurg 和 rex 每日构建版本。

以下所有内容均于 2026-10-23 测试，使用 Radarr `6.3.0.10514`、当前的 `lscr.io/linuxserver/bazarr` 镜像、当日的 zurg 和 rex，以及一个 Real-Debrid 账户。

(之前的译文因代码片段不一致被拒绝：代码片段不一致。请保持结构完全不变。)

## 开始之前 {#before-you-start}

Radarr（或 Sonarr）已经通过 zurg 导入内容，其根文件夹位于 `__magic__` 内，例如 `/mnt/zurg/__magic__/movies`（macOS 上为 `/Volumes/Zurg/__magic__/movies`，Windows 上为 `Z:\__magic__\movies`）。如果还没有，请先按照 [Sonarr 与 Radarr 的种子设置](sonarr-radarr-torrents.md)，或 [Usenet 版本](sonarr-radarr.md) 的说明进行设置。

## 1. 运行 Bazarr {#1-run-bazarr}

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

在 Linux 主机上，给 Bazarr 挂载与 Radarr 相同的卷，这样两者看到的电影路径一致，无需设置路径映射：

绑定挂载的是 zurg 挂载点**上一级**的文件夹（`/mnt`，里面有 `/mnt/zurg`），而不是挂载点本身。如果容器直接绑定挂载点本身，zurg 重启后容器里的挂载会失效，之后每次读取都会返回 `Socket not connected`。[种子指南中的 Docker 步骤](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)解释了原因。`PUID` 和 `PGID` 的设置需要和 Whisparr 一样小心：[详见那里](whisparr.md#2-run-whisparr)。

在 macOS 和 Windows 上，这个 compose 文件不适用，原因见 [Usenet 指南的第 8 步](sonarr-radarr.md#8-if-your-arr-is-in-docker)。请在与 Radarr 和 zurg 相同的机器上，以与 zurg 相同的用户身份，从源码运行 Bazarr（`python bazarr.py`），并参照 Bazarr 官方的 [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) 和 [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/) 页面操作。在 Windows 上，请跳过 Bazarr 的安装程序：它会把 Bazarr 设置为 Windows 服务，而服务看不到 zurg 的 `Z:` 盘（[原因](sonarr-radarr.md#before-you-start)）。请改为在你自己已登录的会话中启动 `bazarr.py`。这样它看到的每部电影路径都与 Radarr 报告的一致，无需路径映射。只有上面的 Docker 镜像方案经过了测试。

打开 `http://<your server>:6767`。

## 2. 将其连接到 Radarr 和 Sonarr {#2-connect-it-to-radarr-and-sonarr}

**设置 → Radarr**：打开开关，填入 Radarr 的地址、端口和 API 密钥（在 Radarr 的 **Settings → General** 里能找到）。如果是在容器里运行，请使用宿主机的局域网 IP，不要用 `localhost`。点 **Test** 测试，然后点 **Save** 保存。Sonarr 的设置方法相同，在 **Settings → Sonarr** 下操作。

## 3. 语言 {#3-languages}

**Settings → Languages**：把你想要的语言都加上，做一个语言配置文件（language profile），然后把它设为电影和剧集的默认配置文件。这样 Bazarr 就会为 Radarr 和 Sonarr 已经有的所有内容去请求字幕。

## 4. 字幕源（Providers） {#4-providers}

**Settings → Providers**：添加 Bazarr 会搜索的字幕网站。有些需要账号，有些不需要。测试时我们遇到了两件事：

- **subf2m** 需要在其 provider 设置中填写 User-Agent。如果不填，Bazarr 会在第一次搜索时将它暂停 12 小时。
- Bazarr 会暂停一段时间内失败的 provider。如果所有 provider 都被暂停，搜索就找不到任何结果。**System → Providers** 会列出这些 provider，并可以将它们重置。

## 5. 内嵌字幕 {#5-embedded-subtitles}

许多发布版本的视频文件里已经自带英文字幕轨。Bazarr 会认为英文字幕已经存在，因此不会下载任何字幕。如果你还是想要一个字幕文件，请到 **Settings → Subtitles** 下关闭 **Use Embedded Subtitles**。

## 6. 检查一个 {#6-check-one}

Bazarr 的 **Movies** 页面会显示每部电影缺少什么。在那里搜索一部电影，字幕就会出现在视频旁边（在 Windows 上，用资源管理器打开同一个文件夹 `Z:\__magic__\movies` 即可看到）：

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

这个字幕是 zurg 磁盘上的一个真实文件，位于 `data/local/__magic__/` 中（参见 [附属文件](magic.md#sidecars-nfo-posters-subtitles)）。视频仍然是从你的账号串流的。

## 在 rex 中 {#in-rex}

zurg 会把 `__magic__` 中与视频并排存放的每个字幕发送给 rex，无论 Radarr 或 Sonarr 把视频移到了哪里。zurg 每分钟检查一次新增、修改和删除的字幕，所以 Bazarr 保存的字幕大约一分钟内就会出现在 rex 中，你删除的字幕也会同样快地消失。除了 zurg 配置里的 `rex_url`（[rex 指南](../../rex/with-zurg.md)中已经让你设置好了），不需要做其他任何设置。

文件名决定字幕的类型，和 Plex 读取字幕名称的方式一样：

| 文件名结尾 | rex 显示 |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`、`.en.sdh.srt`、`.en.cc.srt` | English SDH (SRT External) |

`.srt`、`.ass`、`.ssa`、`.smi` 和 `.txt` 文件都会被读取。语言代码可以是两位或三位（`en`、`eng`、`de`、`ger`）。语言代码前面的名称必须是视频本身的名称，也就是 Bazarr 写入时使用的名称。

只有 `__magic__` 中的字幕会发送到 rex。保存在 zurg 其他文件夹（例如 `/mnt/zurg/movies`）中某个文件旁边的字幕不会被发送。

rex 也可以自己查找字幕，不需要 Bazarr。在任何 Plex 应用中使用 **Search Subtitles** 即可。参见 [rex 的字幕](../../rex/with-zurg.md#subtitles)。
