# “Torrent is being downloaded to debrid”是什么意思 {#what-torrent-is-being-downloaded-to-debrid-means}

绿色的 **Torrent is being downloaded to debrid...** 界面表示你选的资源还没有缓存到你的 debrid 服务中。显示它的 Stremio 插件 Torrentio 刚刚把这个种子添加到你的 Real-Debrid、TorBox 或其他 debrid 账户中，服务器正在下载。下载完成后，同一个结果就能像其他资源一样正常播放了。

## 该怎么做 {#what-to-do}

1. **改选已缓存的结果。** 在 Torrentio 的列表里，`[RD+]`（或 `[TB+]`、`[AD+]`、`[PM+]`）表示已缓存，可以立即播放。`[RD download]` 表示未缓存。这些结果排在已缓存的后面。
2. **或者等几分钟，再点一次同一个结果。** 下载还没完成时，你会再次看到绿屏。下载完成后就能播放了。
3. **查看下载进度**，可以在 [Real-Debrid 的种子页面](https://real-debrid.com/torrents)、[TorBox 控制台](https://torbox.app/dashboard) 或 [DMM 库](https://debridmediamanager.com/library) 查看。DMM 会显示每个未完成下载的百分比、做种数和速度。
4. **一直卡在 0%，也没有做种者？** 目前没有人在分享这个资源，它可能永远无法完成。换一个别的结果吧。
5. **完全不想看到这些结果？** 打开 [Torrentio 配置页面](https://torrentio.strem.fun/configure)，像之前一样设置你的网盘服务和密钥，在 **Options** 下勾选 **Don't show download to debrid links**，然后点击 **INSTALL**。这样你就只会看到已缓存的结果了。

## 在按下播放之前先看看哪些已缓存 {#see-whats-cached-before-you-press-play}

[DMM](https://debridmediamanager.com/) 登录你的 debrid 服务，然后搜索片名。在页面上，绿色的 **Instant RD** 按钮表示 Real-Debrid 已经缓存了该版本，可以立即播放。**DL with RD** 表示尚未缓存，需要先下载。点击结果上方的 **RD** 标签，即可隐藏所有未缓存的内容。TorBox、AllDebrid、Premiumize 和 Offcloud 也有同样的按钮（例如 **Instant TB**、**DL with TB** 等）。

## 常见问题 {#questions}

### 需要多长时间？ {#how-long-does-it-take}

这取决于分享这个种子的人有多少。热门资源通常几分钟就能准备好：我们在 Premiumize 上测试时，一部 1.5 GB 的电影在第一次点击后五分钟就准备好了，下载来源是三个 peer。很少有人分享的资源可能会很慢，而没人分享的则可能永远无法完成。种子页面或仪表盘会显示速度以及找到了多少个 seed。

### 为什么有些结果会出现这种情况，有些却不会？ {#why-does-it-happen-on-some-results-and-not-others}

调试服务会保留用户下载过的内容。如果有人已经抓取过完全相同的版本，它就已经在缓存里，可以立即播放。如果没有人抓取过，或者服务后来已经删掉了它，你的账户就得先把它下载下来。这就是 `[RD+]` 和 `[RD download]` 的区别。TorBox [解释了它的缓存机制](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work)。

### 为什么一个 `[RD+]` 结果也显示了它？ {#why-did-an-rd-result-show-it}

Real-Debrid 不允许插件查询哪些内容已缓存。所以在 Real-Debrid 上，Torrentio 的 `+` 表示该版本最近有人播放过，而不是 Real-Debrid 刚刚确认它已缓存。如果 Real-Debrid 之后把它移除了，就会重新下载。选择另一个带 `+` 的结果，或者等一等。

### 我的 debrid 坏了吗？ {#is-my-debrid-broken}

不对。绿屏表示你的服务已经接收了种子,正在处理。真正出问题时,Torrentio 会显示红屏或黄屏,并带上其他文字,例如 "Access denied" 或 "Some usage limit exceeded"。

### 我的插件显示了别的内容 {#my-addon-says-something-else}

这些确切的文字来自 Torrentio 以及它的自托管副本。其他插件会用自己的方式说同样的话。AIOStreams 会显示 "The file is being downloaded to your debrid. Try again later"，Comet 会显示 "The media you tried to play is not cached yet on this debrid service"，StremThru 会显示 "Downloading to Store"。原因相同，解决办法也相同。
