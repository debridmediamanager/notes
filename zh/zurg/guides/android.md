# zurg+rex 用于 Android 和 Google TV {#zurgrex-for-android-and-google-tv}

The Android 应用会在设备上运行 zurg 引擎，并在它旁边运行 rex：也就是你自己的 Plex 服务器，跑在手机或电视盒子上，供 Plex 应用使用。同一个应用支持手机、平板、Android TV 和 Google TV。需要 Android 8.0 或更高版本。Fire TV 可以侧载同一个 APK。如果播放器没有系统文件应用，请使用 WebDAV 播放器。Usenet 需要 64 位 Android；TorBox 托管的 NZB（`torbox_nzb`）在 Android 上不可用。

## 安装与设置 {#install-and-set-up}

从私有赞助者仓库的 nightly 版本中下载 APK。大多数手机和电视盒子选择 `arm64-v8a`，较老的 32 位设备选择 `armeabi-v7a`，模拟器或兼容的 Chromebook 选择 `x86_64`。每个 APK 都包含手机和电视界面。

应用本身不包含 zurg。登录 GitHub 后，你需要在应用内安装引擎。必须是赞助者账户才能使用。在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助一下，就能让你的 GitHub 账户获得访问权限。Setup 会一步步带你完成。

请允许从你打开 APK 所用的应用安装。Android 或 Play Protect 可能会要求你确认侧载。应用 ID 是 `com.debridmediamanager.zurg`。更新时必须保留发布签名身份，否则无法覆盖安装。

1. 打开 zurg 并登录 GitHub，然后安装一个引擎版本。没装引擎之前，应用无法启动媒体库。
2. 添加网盘账户并测试凭据。同一个服务商下有多个账户时，用账户名加以区分。Usenet 的连接数限制会计入该账户的所有其他使用者。
3. 选择 Phone、Tablet、TV box 或 TV stick。配置文件会设置引擎的内存目标和磁盘缓存大小。Go 堆目标并不是硬性的 RSS 上限。
4. 允许通知和后台运行。如果这台设备需要一直提供媒体库服务，请开启 start after reboot。
5. 启动媒体库。账户内容较多时，首次加载可能需要好几分钟。通知和 Status 界面会显示目录何时准备就绪。

## 在本设备上观看 {#watch-on-this-device}

使用 **Library** 浏览文件夹并播放文件。**More** 可以选择其他播放器，或使用 Android 文档 URI。所选播放器可以设为首选播放器。

**Files** 和文档选择器会在 zurg 存储根目录下显示同一个库。文件以随机访问的方式流式播放，不会先完整下载。

从 **Files** 中选择播放器之前，请先打开一次该播放器并完成设置。

对于 WebDAV 播放器，请添加 `http://127.0.0.1:9999/dav/` 作为源。如果你修改过端口，请使用 **Status** 中显示的端口。VLC、Kodi 和 Nova 可以浏览 WebDAV 源；只接受单个 URL 的播放器可以从 **Library** 启动。

在电视上，使用方向键（D-pad）和 **Select** 移动并激活控件，按 **Back** 返回，按 **Menu** 或 **More** 进行发布项操作。选中文本框后可以编辑，编辑完按 **Back** 返回导航。在手机上，长按也可以打开 **More**。

**Repair**、**rename**、**tags**、**show all files** 和 **delete** 操作的是整个所属发布项，而不是单个文件。**delete** 会先要求确认，然后从其网盘账户中删除。

**MediaInfo** 使用内置的 ffprobe，并在控制台中显示解析出的视频、音频和字幕详情。无需单独安装任何媒体工具。

## 在 Plex 应用中观看 {#watch-in-the-plex-apps}

从 2026 年 11 月 10 日的每日构建版开始，应用还会运行 rex（该每日构建版中为 64 位设备，11 月 11 日的每日构建版起支持所有受支持的设备）。rex 是一个面向 Plex 应用的媒体服务器，应用会把 zurg 指向它，这样你的库就会出现在官方 Plex 应用和 Plezy 中，包括本设备以及家中其他设备。库开始运行后，在 Status 中会显示 **rex for the Plex apps**：选择 **Sign in to Plex** 并批准登录（在电视上，请在 plex.tv/link 输入代码）。服务器会以本设备的名称显示在 Plex 中。rex 会借助设备的硬件编码器，把播放器无法播放的内容转换为可播放的格式。若要关闭 rex，请前往 Settings、Connection 进行关闭；此后 zurg 将停止向它提供内容。

## 通过本地网络共享 {#share-over-the-local-network}

在设置中启用 **Expose on local network**。zurg 会生成凭据,并显示设备的局域网 WebDAV 地址。在另一台设备的播放器中输入该地址和这些凭据。请保持 Android 主机通电并持续运行。
HTTP 基本认证不会加密流量;请只在可信的本地网络中使用。
默认是仅本机回环访问。播放器的 intent 中永远不会包含你的服务器密码。

## 设置、备份与更新 {#settings-backups-and-updates}

设置页包括连接、供应商、库、修复、资源和日志。

高级页接受原始 YAML，保存前会让已安装的引擎先验证。设置页没有填写 DMM API key 的字段。要使用 [DMM wanted list](dmm-wanted.md) 和 DMM 的发布命名，请在高级页中添加 `dmm_api_key: YOUR_DMM_API_KEY`。保存正在运行的配置时，应用会先询问，然后再重启服务器。

Web dashboard 会打开本地仪表盘，用于设置桌面集成。

日志页包含引擎最近的输出，以及 supervisor 最后 200 行。分享日志时，已配置的密钥和 URL 会被隐去。备份包含凭据和库状态，请妥善保存。恢复前先停止 zurg。Android 会拒绝备份链接和特殊文件，并且会先恢复到 loopback。

更新页会检查私有赞助者仓库。GitHub 设备登录会请求 `repo` 权限，因为发布资源是私有的。GitHub token 会使用基于 Android Keystore 的加密偏好设置进行加密存储。你也可以手动提供一个对该仓库具有读取权限的 token。如果 Android 无法再解密已保存的登录信息，更新页会请你重新登录，但会保留你的库配置。

下载的更新必须与应用 ID 和签名密钥一致，并且版本号必须更高。Android 安装程序会在替换应用前询问你。

如果你使用的是自带引擎的构建版本进行更新，应用会没有引擎。请在更新页安装一次引擎，你的供应商和库设置会原样保留。

应用和引擎是分开更新的。更新页会列出赞助者仓库最近 30 个发布版本中的引擎版本，标出你当前正在使用的版本，并可以安装其中任意一个。如果新的 nightly 版本在你的设备上出现问题，请安装对你来说能正常工作的那个版本。更换引擎前，请先在状态页停止你的库。应用只会运行使用其自身密钥签名的引擎包，并且每次启动时都会再次校验。

常驻通知中有一个 Stop 操作。快速设置磁贴也可以启动或停止服务器。电池豁免可以帮助应对 Android 的空闲限制；各厂商自带的任务清理工具可能需要额外设置，请参考 [Don't kill my app](https://dontkillmyapp.com/)。
