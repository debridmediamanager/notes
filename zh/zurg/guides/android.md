# zurg+rex 用于 Android 和 Google TV {#zurgrex-for-android-and-google-tv}

zurg+rex 是装在你手机上的 Plex 服务器。zurg 接入你的 debrid 账户和 Usenet，rex 再把它们提供给你家里的每一个 Plex 应用，包括海报、季信息和观看进度。它可以运行在手机、平板、Android TV、Google TV 或 Fire TV 上，不需要电脑。

它需要赞助才能使用。不想赞助？[rex for Android](../../rex/android.md) 是免费的，播放它的插件提供的内容。

| 应用本身 | 在 Plex 应用中 | 在其他 Plex 应用中 |
|---|---|---|
| ![zurg+rex 中的状态页，库已就绪，rex 已登录 Plex](../../assets/zurg/android-status.webp) | ![Plex 应用中的 Big Buck Bunny 详情页，由同一部手机提供](../../assets/zurg/android-plex.webp) | ![Plezy 应用中同一个开放电影库](../../assets/zurg/android-plezy.webp) |

## 开始之前 {#before-you-start}

| 你需要 | 原因 |
|---|---|
| 运行 Android 8.0 或更新版本的设备 | 手机、平板、Android TV、Google TV 或 Fire TV。Usenet 需要 64 位设备 |
| 在 GitHub 账号上关联的赞助 | 应用及其引擎从赞助者仓库下载。请在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助并关联 GitHub |
| 一个网盘账号或一个 Usenet 账号 | zurg 接入的内容来源。TorBox 托管的 NZB（`torbox_nzb`）在 Android 上不可用 |
| 一个 Plex 账号 | rex 会出现在登录该账号的 Plex 应用中。免费账号即可 |
| 你的 DMM API key（来自 gatekeeper，可选） | 有了它，更多影片能获取名称和海报 |

## 第 1 步：下载 {#step-1-download-it}

在设备上打开[下载页面](https://zurg.debridmediamanager.com/zh/download.html#android)，使用你的赞助者账号登录 GitHub，然后选择适合其处理器的文件：

| 你的设备 | 文件 |
|---|---|
| 大多数手机、平板和电视盒子（64 位） | `android-arm64-v8a.apk` |
| 较旧的 32 位手机和电视棒 | `android-armeabi-v7a.apk` |
| Chromebook 和模拟器 | `android-x86_64.apk` |

同一个文件在手机和电视上都能用。

**GitHub 显示 404？** 你登录的账号还没有赞助者访问权限。如果你刚刚赞助过，请先[接受邀请](https://github.com/debridmediamanager/zurg/invitations)；邀请会在 15 分钟内发出。

## 第 2 步：安装 {#step-2-install-it}

打开下载的文件，并允许从打开它的应用安装。Android 或 Play Protect 可能会要求你确认。

**你应该看到的效果。** 应用列表中出现 **zurg+rex**。

## 第 3 步：登录 GitHub 并安装引擎 {#step-3-sign-in-to-github-and-install-the-engine}

打开应用。它显示 **Welcome to zurg+rex.**

1. 按 **Sign in with GitHub**。应用会显示一个代码：按 **Open GitHub**，输入代码并批准。由于赞助者版本是私有的，GitHub 会请求 `repo` 访问权限。
2. **安装引擎。** 引擎就是 zurg 和 rex 本身，它们单独打包，所以可以独立于应用更新。按 **Install**。Android 会在安装前询问：允许即可。

**你应该看到的。** **Add your providers.**

## 第 4 步：添加你的服务商 {#step-4-add-your-providers}

1. 点击 **Add an account**，然后选择服务商。
2. 如果是 debrid 账户，把它的 token 粘贴到 **Provider token** 里。如果是 Usenet 账户，请填写 **NNTP server**、**Port**、**Username**、**Password** 和 **Connections**。
3. 点击 **Test account**，然后点击 **Add provider**。

想加多少账户就加多少。同一个服务商下有两个账户时，用 **Account name** 来区分。Usenet 账户的连接数上限，会被所有其他正在使用它的应用和设备共享占用。

## 第 5 步：启动你的媒体库 {#step-5-start-your-library}

1. 选择 **Phone**、**Tablet**、**TV box** 或 **TV stick**。选择越小的设备，占用的内存和缓存就越少。
2. 允许通知，并让应用在后台运行。如果这台设备需要一直为你的媒体库提供服务，请打开 **Start after reboot**。
3. 按下 **Start my library**。

**你应该看到的情况。** **Status** 会显示 **Ready for your players**，并统计你的资源数量。账户较大时，首次加载可能需要几分钟。

## 第 6 步：登录 Plex {#step-6-sign-in-to-plex}

在 **Status** 页面的 **rex for the Plex apps** 下，点击 **Sign in to Plex**。

- **在手机或平板上**，浏览器会打开 Plex 的登录页面。在那里登录即可。
- **在电视上**，应用会显示 **On any device, go to plex.tv/link and enter**，后面跟一个验证码。请在手机或电脑上打开 plex.tv/link 并输入该验证码。

请使用你的 Plex 应用所登录的账号。

**你应该看到的结果。** 显示 **Ready for the Plex app**；如果本设备上装有 Plex，还会出现 **Open Plex** 按钮。

## 第 7 步：在 Plex 应用中观看 {#step-7-watch-in-a-plex-app}

在同一账号下登录任意 Plex 应用即可:可以是本机、电视、另一部手机或家里的电脑。你的服务器会以本设备的名称显示在列表中,下面有 **Debrid Movies** 和 **Debrid TV** 两个媒体库。点击播放即可。

rex 会使用设备自带的视频编码器,把播放器无法直接播放的内容转换成可播放的格式。

## 获取更多名称相同的片名 {#get-more-titles-named}

打开 **Settings**、**Library**，把你的 DMM API key 粘贴到 **Dmm api key** 中，然后保存。zurg 随后会向 DMM 查询每个文件是什么内容。

没有密钥时，zurg 只能根据发布名称来判断，因此能获取到名称和海报的影片会变少。

如果某个标题仍然显示不对，可以在 Plex 应用中修正：打开它的 **⋯** 菜单，然后选择 **Fix Match**。

该字段从 2026 年 11 月 14 日起的每日构建版中可用。在较旧的版本中，请在 **Settings**、**Advanced** 中添加 `dmm_api_key: YOUR_DMM_API_KEY`。同一个密钥也可以读取你的 [DMM 想看列表](dmm-wanted.md)。

## 附加组件 {#addons}

附加组件会为 rex 带来更多可观看的内容，不只是你的媒体库。打开 **Addons**：Internet Archive 附加组件已预先安装，会添加公共领域电影，[rex-addons](https://github.com/debridmediamanager/rex-addons) 仓库也已列出。通过链接添加另一个仓库，打开它，然后安装它提供的附加组件。

每个附加组件都会说明它能访问哪些网站，如果更新后要访问新的网站，会先询问你。只从你信任的人那里安装附加组件。**Log** 会显示附加组件最近做了什么。移除附加组件只会删除它的内容条目。

## 此设备上的其他播放器 {#other-players-on-this-device}

不用 Plex 应用也能看。

- **Library** 会浏览你的文件夹，并用你选择的播放器播放文件。**More** 提供另一个播放器，以及该资源的操作：repair、rename、tags、show all files 和 delete。这些操作针对整个资源，其中 delete 会先询问，然后从你的 provider 账户中删除它。
- **Files** 应用和文档选择器会在 zurg 根目录下显示同一个库。先打开一次你的播放器并完成设置，然后再从 Files 中选择它。
- VLC、Kodi 和 Nova 等 WebDAV 播放器使用 `http://127.0.0.1:9999/dav/` 作为源。如果你修改了端口，**Status** 会显示地址。

在电视上，用 D-pad 和 Select 移动，用 Back 返回，用 Menu 或 **More** 打开资源的操作菜单。选中文本框即可输入，输入完成后按 Back 继续。

## 与家里的其他播放器共享 {#share-with-other-players-at-home}

Plex 在家里的应用无需额外设置：它们会自己找到 rex。如果是其他设备上的 WebDAV 播放器，请打开 **Settings**、**Connection**，然后开启 **Expose on local network**。zurg 会生成用户名和密码，并显示需要在该播放器中输入的地址。

请只在你信任的网络上使用此功能：密码以明文传输。该功能默认关闭，只有你手动开启后才会生效。

## 保持运行 {#keep-it-running}

- 通知会显示服务器的状态，并带有 **Stop** 按钮。快速设置磁贴也可以启动和停止它。
- 有些手机会无论如何都停止后台应用。[Don't kill my app](https://dontkillmyapp.com/) 说明了你的应用需要哪些设置。
- **Updates** 会检查新的应用和新的引擎，二者分别更新。如果新的 nightly 版本在你的设备上出现问题，请按 **Show engine versions**，然后安装之前能正常工作的那个版本。先在 **Status** 页面停止你的库。
- **Settings** 里有 **Create backup** 和 **Restore backup**。备份中包含你的密码和令牌，所以要妥善保管。恢复备份前请先停止你的库。
- 在 **Settings** 的 **Connection** 下关闭 **rex for the Plex apps**，即可关闭 rex。这样 zurg 就不会再向它输送内容了。

## 应用会发送什么，发送到哪里 {#what-the-app-sends-and-where}

| 位置 | 内容 | 时机 |
|---|---|---|
| GitHub | 你的登录信息，然后是请求赞助者版本的下载 | 登录时，以及点击 **Updates** 检查更新时 |
| 你的提供商 | 你的账户令牌或 Usenet 登录信息，以及请求你的资料库和文件 | 资料库运行期间 |
| debridmediamanager.com | 你的发布名称（用于识别每个发布的内容），如果你输入过，还会附带你的 DMM API 密钥 | 开启 rex 并运行资料库时 |
| plex.tv 和 Plex 的元数据服务 | 一次登录验证码请求；之后是服务器名称、地址，以及你的标题 ID，用于获取海报和简介 | 登录 Plex 时，以及 rex 以登录状态运行时 |
| debridmediamanager.com（rex-direct） | rex 的标识符、Plex 发给它的服务器令牌、它的 IP 地址和端口，以便 Plex 应用通过 HTTPS 访问它 | 登录 Plex 后，之后每 6 小时一次 |
| 每个插件的网站和你添加的仓库 | 插件所请求的内容 | 插件同步或播放某个标题时 |
| logs.debridmediamanager.com | 版本号、设备型号、应用和引擎的日志，以及你的配置（其中的密钥、密码和令牌会替换为 `[redacted]`） | 仅当你在 **Send logs to support** 下点击 **Send** 时，且你已看过全部内容后。7 天后删除 |

你的 GitHub 令牌加密后存储在设备上。卸载应用会删除它保存的所有内容。

## 限制 {#limits}

- **设备就是服务器。** 请保持它开机、联网并接通电源。在廉价设备上转换视频会很慢。
- **在家里播放。** 外出时，Plex 应用需要一个能访问到该设备的 HTTPS 地址，这需要在你的路由器上设置端口转发。参见 [在外面使用](../../rex/with-zurg.md#use-it-outside-your-home-optional)。
- **Usenet 需要 64 位 Android。** 32 位设备只能运行 debrid 库。
- **不在 Google Play 上架。** 它会在应用内更新，位于 **Updates** 下。

## 故障排除 {#troubleshooting}

| 你看到的 | 该怎么做 |
|---|---|
| GitHub 在下载页面返回 404 | 用你的赞助者账号登录 GitHub，然后[接受邀请](https://github.com/debridmediamanager/zurg/invitations)。还不是赞助者？去 [gatekeeper](https://gatekeeper.debridmediamanager.com/) |
| **未安装引擎。zurg 需要先安装一个引擎，才能提供你的库。** | 按 **Install an engine**，并允许 Android 安装它 |
| **这台设备在赞助者版本中暂时没有可用的引擎。** | 最新的 nightly 版本没有适配你处理器的引擎。到支持频道问问 |
| **这是 32 位设备。支持 Debrid 库；Usenet 需要 64 位 Android。** | 添加一个 debrid 账号，或者换一台 64 位设备来用 Usenet |
| **Plex 代码已过期。请重新获取一个。** | 再次按 **Sign in to Plex**，并在 10 分钟内输入新代码 |
| Plex 应用里看不到这个服务器 | 用第 6 步所用的账号登录 Plex 应用，并确保两台设备连接的是同一个家庭网络 |
| 影片只显示文件名，没有海报 | 输入你的 DMM API key（见[获取更多正确的片名](#get-more-titles-named)），或者在 Plex 应用里使用 **Fix Match** |
| 屏幕关闭后就停止工作 | 重新允许后台运行，并查看 [Don't kill my app](https://dontkillmyapp.com/) |
| 更新后应用没有引擎了 | 在 **Updates** 里重新安装一次引擎。你的 providers 和设置都会保留 |

如果支持人员要日志，打开 **Logs**，按 **Send logs to support**。发送前你可以先看到所有内容，然后按 **Send**，把得到的代码发出去。

还有问题？到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **zurg-support** 论坛提问。
