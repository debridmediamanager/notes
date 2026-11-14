# rex 安卓版 {#rex-for-android}

rex 是一个用于 Plex 应用的媒体服务器，本身不拥有任何文件。rex for Android 可以把它直接跑在手机、平板、Android TV、Google TV 或 Fire TV 上，不需要电脑。你设备上的 Plex 应用会像找普通 Plex 服务器一样找到它，并从它那里播放内容。

它能播放的内容来自 **addons**（插件）。一开始就有互联网档案馆（Internet Archive）的公共领域电影。更多插件，比如你的 Stremio 插件、YouTube 和 Spotify，在添加它们的仓库后可以直接在应用里安装。

rex for Android 是免费的。如果你也想把 debrid 账户和 Usenet 加进来，可以用 zurg+rex：一个在手机上运行、内置 zurg 的 Plex 服务器，需要赞助才能使用。详见 [zurg+rex for Android](../zurg/guides/android.md)。

## 开始之前 {#before-you-start}

| 你需要 | 原因 |
|---|---|
| 运行 Android 8.0 或更新版本的设备 | 手机、平板、Android TV、Google TV 或 Fire TV |
| 一个 Plex 账号 | rex 会出现在登录了该账号的 Plex 应用中。免费账号即可 |
| 你观看所用设备上的 Plex 应用 | Plex for Android、Android TV、iPhone、智能电视、Plex Web、Plexamp |

它还没有上架 Google Play。你需要自己安装应用文件（APK）。

## 第 1 步：下载 {#step-1-download-it}

```
在设备上，下载适合其处理器的文件。每个链接始终指向最新版本：
```

Wait, I should not wrap in a code fence. Correct output:

在设备上，下载适合其处理器的文件。每个链接始终指向最新版本：

| 你的设备 | 下载 |
|---|---|
| 大多数手机、平板和电视盒子（64 位） | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| 较旧或较便宜的 32 位盒子，包括 Fire TV Stick | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| 电脑上的模拟器 | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

每个版本及其更新内容都在[发布页面](https://github.com/debridmediamanager/rex-android/releases)上。

不确定？先试试 `arm64-v8a`。同一个文件既适用于手机，也适用于电视。

## 第 2 步：安装 {#step-2-install-it}

打开下载好的文件。Android 会先询问：

1. 它提示**不允许从此来源安装未知应用**。点击**设置**，打开**允许来自此来源**，然后返回。
2. 点击**安装**。

如果是没有浏览器的电视盒子，请使用能打开 APK 的下载器应用来下载该文件。

**你应该看到的效果。** 应用列表中出现 **rex**。

## 第 3 步：启动 rex {#step-3-start-rex}

```
```

Ah, the input is not a code fence; I should not add one. Let me give the translation properly.

**打开 rex。** 第一个屏幕写着 **Welcome to rex.**

1. 点 **Allow notifications**，然后点 **Allow**。rex 会在后台运行，并带有一个通知，你可以通过它停止 rex。
2. 点 **Let rex keep running in the background**。在打开的列表中，选择 **rex**，然后选 **Don't optimize**。在较新的 Android 上，选项是 **Allow background usage**，然后选 **Unrestricted**。返回 rex。两个按钮现在都以 ✓ 开头。
3. **Name** 是 Plex 应用中显示的服务器名称。如果你想，可以修改。
4. **Port** 保持 `32400`。如果这台设备上已经运行了另一个 Plex 服务器，rex 会提示 **Another app here already uses this port, maybe a Plex server. Try 32500.** 那就输入 `32500`。
5. 点 **Start rex**。

**你应该看到的画面。** **2 / 2** 和 **Sign in to Plex**。

| 第一个屏幕 | Plex 应用中的影片页面（第 5 步） |
|---|---|
| ![rex for Android 的第一个屏幕，包含名称和端口字段以及 Start rex](../assets/rex/android-setup.webp) | ![Internet Archive 上一部 1916 年无声电影在 Plex for Android 中的页面](../assets/rex/android-plex-film.webp) |

## 第 4 步：登录 Plex {#step-4-sign-in-to-plex}

按下 **Sign in to Plex**。rex 会显示一个代码：**On any phone or computer, go to plex.tv/link and enter** it。

- **在手机或平板上**，你的浏览器也会打开一个 Plex 页面，上面写着 **rex for Android would like to sign in to your Plex account**。在那里登录即可。
- **在电视上**，请用手机或电脑打开 [plex.tv/link](https://plex.tv/link)，登录并输入代码。

使用你的 Plex 应用当前登录的账号。你可以按 **Skip for now**，之后再从 **Status** 登录。

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**你应该看到的结果。** **Signed in. rex shows up in the Plex apps as** 你的服务器名称。按 **Done**。**Status** 会显示 **RUNNING** 和 **Ready for the Plex apps.**

## 第 5 步：在 Plex 应用中观看 {#step-5-watch-in-a-plex-app}

打开任意一个已登录同一账号的 Plex 应用。如果 Plex 在这台设备上,**Status** 里会有一个 **Open Plex** 按钮。

在 Plex for Android 中,打开 **Libraries**,然后是 **All Libraries**,再点你服务器名称下的 **Movies**。其他 Plex 应用也会在服务器名称下列出它。

Internet Archive 的首次同步需要一点时间:在我们的测试设备上大约半小时,rex 会逐一检查每部影片。**Status** 会显示 **Syncing**,直到完成,然后显示数量,比如 **Ready · 97 titles**。随便选一部影片播放就行。

![The Plex app on a TV playing a 1914 Chaplin short from rex on the same TV](../assets/rex/android-tv-playing.webp)

## 附加组件 {#addons}

**Addons** 列出你安装过的插件。每个插件都会显示它的条目数，以及上次同步的时间。它的按钮有 **Sync now**、**Settings**、**Log** 和 **Remove**；在手机上，左右滑动按钮所在的那一行即可看到全部按钮。**Enabled** 开关可以在不删除插件的情况下关闭它。

插件来自 **repositories**（仓库），也就是存放插件的 git 仓库。应用一开始就添加了 [rex-addons](https://github.com/debridmediamanager/rex-addons)，其中提供 Internet Archive 的公共领域电影，并且从一开始就已安装。如果想要更多，可以添加 [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons)（见下方的 **Add a repository**），它提供：

| 插件 | 功能 |
|---|---|
| Stremio addons | 你的 Stremio 插件中的电影和剧集目录，播放来源是你的流媒体插件提供的串流 |
| YouTube | 你的 YouTube 播放列表。需要用验证码登录 |
| Spotify | 你的 Spotify 音乐库，作为音乐提供给 Plex 和 Plexamp。需要已登录的 YouTube 插件 |

**安装一个插件。** 在 **Repositories** 下，点击某个仓库旁边的 **Addons**，然后点击插件下方的 **Install**。rex 会列出它能访问的网站，并再次询问你是否确认，然后开始同步该插件。

**登录。** 需要账号的插件会显示 **Sign in to start.**。点击它的 **Sign in** 按钮：在任意设备上打开它指定的页面，并输入屏幕上显示的验证码。

**添加仓库。** 在 **Add a repository** 下，输入它的链接（`github.com/user/repo` 就够了），然后点击 **Add**。只从你信任的人那里安装。想自己编写插件，请参阅 [rex-addons](https://github.com/debridmediamanager/rex-addons)。

## 在家中的其他设备上观看 {#watch-on-other-devices-at-home}

Plex 应用只要登录的是同一个账号，就能在家庭网络里通过名称找到 rex：电视、另一部手机、电脑上的 Plex 网页版都可以。**Status** 会显示 rex 在家里的地址，例如 `http://192.168.1.20:32400`。

如果想让家人用自己的 Plex 账号观看，请参阅 [与家人和朋友共享 rex](sharing.md)。

## 保持运行 {#keep-it-running}

- rex 在设备开机期间持续运行。通知中的 **Stop** 可以停止它；**Status** 中有 **Start**、**Stop** 和 **Restart**。
- 在 **Settings** 中打开 **Start when this device turns on**。否则重启后，请打开 rex 并按 **Start**。
- 一些手机仍会关闭后台应用。[Don't kill my app](https://dontkillmyapp.com/) 说明了你的应用需要哪些设置。
- 要重命名服务器，请在 Plex 应用中打开 **Settings**、**General**，然后修改 **Friendly name**。

## 限制 {#limits}

- **It plays at home.** Away from home, Plex apps need an HTTPS address that reaches the device, which needs a port forward on your router to it. See [Use it outside your home](any-source.md#use-it-outside-your-home-optional).
- **The device is the server.** Keep it on, on Wi-Fi or Ethernet, and plugged in. Converting video for a player that can't play a file uses the device's own hardware and can be slow on a cheap box.
- **Only what addons bring.** It has no library of files on the device itself.
- **Not on Google Play yet.** To update, install the new file from [the releases](https://github.com/debridmediamanager/rex-android/releases/latest) over the old one, and rex starts again by itself. Your sign-in and addons stay.

## 故障排除 {#troubleshooting}

| 你看到的内容 | 该怎么做 |
|---|---|
| **App not installed as app isn't compatible with your phone.** | 你选错了处理器对应的文件。请从第 1 步的表格中换一个文件再试 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | 将端口输入为 `32500` |
| **Use a number from 1024 to 65535** | 端口必须是这个范围内的数字 |
| The server isn't in the Plex app | 让 Plex 应用登录到第 4 步所用的同一个账号，并确保两台设备处于同一个家庭网络中 |
| The library is empty | 首次同步仍在进行：请等待，直到 **Status** 显示出标题数量 |
| **Sign in needed** under an addon | 点击该插件下的 **Sign in** 按钮，然后输入验证码 |
| **Needs an update** under an addon | 此版本的应用已无法运行该插件的这个副本。请刷新它的仓库，然后点击 **Update**。在此期间，它的标题会保留 |
| **That isn't a repository link. Try github.com/user/repo.** | 输入仓库的链接，例如 `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | 链接有误，或者仓库是私有的。请在浏览器中检查一下 |
| rex stops when the screen is off | 重新设置第 3 步中的后台运行选项，并参考 [Don't kill my app](https://dontkillmyapp.com/) |

**Logs** 会显示 rex 和插件最近输出的内容，其中的密钥和密码已隐藏。如果支持人员索要日志，请点击 **Send logs to support**：在发送任何内容之前，你都可以先看到全部内容，然后点击 **Send**，并把得到的代码发给对方。

应用会发送哪些内容、发往何处，请参阅其[隐私政策](android-privacy.md)。

遇到问题？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。
