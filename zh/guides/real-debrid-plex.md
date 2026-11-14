# 用 zurg 在 Plex 中管理 Real-Debrid 库 {#a-real-debrid-library-in-plex-with-zurg}

zurg 会把你 Real-Debrid 账户里的所有内容显示为电脑上的文件夹，并已按 `movies` 和 `shows` 分好类。把这两个文件夹添加到 Plex Media Server 中，你的整个 Real-Debrid 库就能在所有 Plex 应用中播放，直接从 Real-Debrid 串流，无需先下载任何内容。你只需安装一次 zurg，它自带 rclone，因此无需再做其他设置。

不想运行 Plex Media Server 或挂载驱动器？[rex with zurg](../rex/with-zurg.md) 介绍了如何在不使用这两者的情况下，让 Plex 应用显示同一个库。

## 你需要准备 {#what-you-need}

- **赞助。** zurg 的 nightly 版本只提供给赞助者。在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助后，你的 GitHub 账号就能访问下载。[赞助能获得什么](sponsorship.md) 里有其他内容。
- **一个 Real-Debrid 高级账号**，以及它的 API 令牌：[你的 Real-Debrid API 令牌](real-debrid-api-token.md) 说明了去哪里找它。
- **与 zurg 在同一台电脑上的 Plex Media Server。** Plex 从 zurg 的文件夹里读取文件，所以它必须能看到这些文件。之后，任何 Plex 应用都可以观看。
- **一台保持开机的电脑**：Windows 10 或 11、Linux、Mac，或者装有 Docker 的 Linux 机器。

## 1. 安装 zurg {#1-install-zurg}

Each setup page starts with a one-line installer. When it says `Choose one or more providers in priority order:`, type `1` for Real-Debrid, then paste your token.

| Your computer | Install with | Your library shows up at |
|---|---|---|
| Windows | [zurg on Windows](../zurg/setup/windows.md) | `Z:\movies` and `Z:\shows` |
| Linux | [zurg on Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` and `/mnt/zurg/shows` |
| Mac | [zurg on macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` and `/Volumes/Zurg/shows` |
| Linux with Docker | [One Docker Compose file](../zurg/guides/docker-compose.md), which runs Plex Media Server beside zurg | `/zurg_mnt/zurg/movies` and `/zurg_mnt/zurg/shows` |

The installer ends with `zurg doctor`, a list of `PASS` lines.

## 2. 检查文件夹 {#2-check-the-folders}

打开 zurg 的驱动器或文件夹。你应该能看到 `movies`、`shows`、`__all__`、`__downloads__`、`__unplayable__` 和 `version.txt`。

第一次启动时，zurg 会读取你整个 Real-Debrid 账户。在这完成之前，这些文件夹会一直是空的。要确认的话，在浏览器中打开 `http://localhost:9999/ready`：等你的媒体库加载完成后，页面会显示 `ready`。

## 3. 在 Plex 中添加文件夹 {#3-add-the-folders-in-plex}

在 Plex Web 中，点击侧边栏里服务器名称旁边的 **Add Library** 按钮：

1. 选择 **Movies**，然后点击 **Next**。
2. 点击 **Browse for media folder**，选择上表中 zurg 的 `movies` 文件夹，例如 Windows 上的 `Z:\movies`。
3. 点击 **Add Library**。

对 **TV Shows** 和 `shows` 文件夹重复同样的操作。之后 Plex 会扫描这两个库，并自动补全海报和标题。

## 4. 让 zurg 通知 Plex 有新内容 {#4-let-zurg-tell-plex-about-new-things}

Plex 不会察觉到 Real-Debrid 账户里新增了内容,zurg 可以告诉它。打开 zurg 的仪表盘 `http://localhost:9999/config/`,进入 **Media Server Integration**,然后点击 **Login with Plex**。登录 Plex 并选择你的服务器。

![The Media Server Integration section of zurg's dashboard, with the Login with Plex button](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

之后 zurg 会在每个有变化的文件夹上请求 Plex 进行扫描。它还会关闭几项对流媒体库有风险的 Plex 设置,例如 **Empty trash automatically after every scan**:[Recommended Plex Settings](../zurg/guides/plex.md#recommended-plex-settings) 列出了这些设置。

## 出现问题时 {#when-something-is-wrong}

| 你看到的情况 | 你该怎么做 |
|---|---|
| Plex 找不到任何东西，或者 zurg 的文件夹是空的 | zurg 还在读取你的账户。等到 `http://localhost:9999/ready` 显示 `ready`，然后在 Plex 里重新扫描。 |
| 在 Windows 上没有 `Z:` 盘，或者 Plex 找不到 `Z:\movies` | `Z:` 属于你的 Windows 桌面会话，zurg 的安装程序会在你登录时在那里启动 zurg。以管理员身份打开的 PowerShell 也看不到它。[Windows 出问题时](../zurg/setup/windows.md#when-something-is-wrong)列出了每种情况的处理方法。 |
| 在 Linux 上，Plex 看到的是空文件夹，或者打不开它，并且 `./zurg doctor` 提示 `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | Plex 和 zurg 用的不是同一个用户。用 <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code> 允许其他用户访问，然后在 zurg 的文件夹里运行 `./zurg service restart`。 |
| 在 Docker 里，zurg 重启后 Plex 的媒体库变空，并且 `docker exec plex ls /zurg_mnt/zurg` 提示 `Transport endpoint is not connected` | 用 `rslave` 把 zurg 的文件夹挂载给 Plex 的容器：`/zurg_mnt:/zurg_mnt:rslave`。[一个 Docker Compose 文件示例](../zurg/guides/docker-compose.md)里有这一项。 |
| zurg 的文件夹里出现了新内容，但 Plex 里没有 | 执行第 4 步。在那之前，先在 Plex 里对该媒体库点击 **Scan Library Files**。 |
| zurg 提示 `bad_token` | Real-Debrid 令牌不对，或者被截断了。[你的 Real-Debrid API 令牌](real-debrid-api-token.md#when-something-is-wrong)里有解决办法。 |
| 你的磁盘被占满了 | zurg 会保存一份你播放过的内容的缓存，默认最多 256G。按照[控制缓存大小](../zurg/setup/windows.md#keeping-the-cache-small)（Windows）或[挂载点使用的磁盘](../zurg/setup/linux.md#disk-the-mount-uses)（Linux）中的说明进行限制。 |

还是解决不了？到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **zurg-support** 论坛提问。[获取帮助](remote-help.md)里写了需要附上哪些信息。

## 常见问题 {#questions}

### 有没有教程可以设置 DMM、zurg 和 rclone 以便在 Plex 中串流？ {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

本页面。你不需要自己设置 rclone，zurg 的安装程序会下载它，并由 zurg 运行。DMM 用来查找资源并把它们添加到你的 Real-Debrid 账户中（[What DMM is and how to use it](../dmm/index.md)）。之后 zurg 会在它的文件夹中显示这些内容，Plex 再把它们识别出来。

### 电影会下载到我的电脑上吗？ {#do-the-movies-download-to-my-computer}

不对。Plex 在你点击播放时，会通过 zurg 从 Real-Debrid 读取每个文件。zurg 会缓存已播放过的内容，缓存可能会变得很大，具体请看上面的磁盘一行。

### 可以不用 Plex Media Server 吗？ {#can-i-skip-plex-media-server}

是的，可以配合 rex 使用。[rex 与 zurg](../rex/with-zurg.md) 会把你的 zurg 库显示在 Plex 应用中，不需要 Plex Media Server，也不需要挂载。你也可以两者一起运行：[一个 Docker Compose 文件](../zurg/guides/docker-compose.md) 就能在同一台机器上运行 zurg、Plex Media Server 和 rex。

### 它也支持 TorBox 或 Usenet 吗？ {#does-it-work-with-torbox-or-usenet-too}

Yes。zurg 的安装程序也支持 TorBox、AllDebrid、Premiumize、Debrid-Link、Offcloud 和 Usenet，并且都会放进同一个 `movies` 和 `shows` 文件夹里。[Providers](../zurg/providers/index.md) 页面里每个服务商都有一个单独的说明。
