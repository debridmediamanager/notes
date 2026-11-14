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

**rex**を開きます。最初の画面には**Welcome to rex.**と表示されます。

1. **Allow notifications**を押し、次に**Allow**を押します。rex はバックグラウンドで動き、通知から停止できます。
2. **Let rex keep running in the background**を押します。開いたリストで**rex**を選び、**Don't optimize**を選択します。新しい Android では**Allow background usage**、次に**Unrestricted**です。rex に戻ります。両方のボタンの先頭に✓が付きます。
3. **Name**は Plex アプリがこのサーバーを呼ぶ名前です。必要なら変更してください。
4. **Port**は`32400`のままにします。この端末で別の Plex サーバーがすでに動いている場合、rex は**Another app here already uses this port, maybe a Plex server. Try 32500.**と表示します。`32500`と入力してください。
5. **Start rex**を押します。

**表示されるはずの画面。** **2 / 2**と**Sign in to Plex**です。

| 最初の画面 | Plex アプリでの映画のページ（ステップ5） |
|---|---|
| ![名前とポートの入力欄、Start rex があるrex for Androidの最初の画面](../assets/rex/android-setup.webp) | ![Internet Archive の1916年のサイレント映画が Plex for Android のページに表示されている様子](../assets/rex/android-plex-film.webp) |

## 第 4 步：登录 Plex {#step-4-sign-in-to-plex}

按下 **Sign in to Plex**。rex 会显示一个代码：**On any phone or computer, go to plex.tv/link and enter** it。

- **在手机或平板上**，你的浏览器也会打开一个 Plex 页面，上面写着 **rex for Android would like to sign in to your Plex account**。在那里登录即可。
- **在电视上**，请用手机或电脑打开 [plex.tv/link](https://plex.tv/link)，登录并输入代码。

使用你的 Plex 应用当前登录的账号。你可以按 **Skip for now**，之后再从 **Status** 登录。

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**你应该看到的结果。** **Signed in. rex shows up in the Plex apps as** 你的服务器名称。按 **Done**。**Status** 会显示 **RUNNING** 和 **Ready for the Plex apps.**

## 第 5 步：在 Plex 应用中观看 {#step-5-watch-in-a-plex-app}

用同一账号登录的任意 Plex 应用打开。如果 Plex 在这台设备上,**Status** 里有一个 **Open Plex** 按钮。

在 Plex for Android 中,打开 **Libraries**,然后是 **All Libraries**,再点你服务器名称下的 **Movies**。其他 Plex 应用也都在服务器名称下列出它。

Internet Archive 的首次同步需要一些时间:在我们的测试设备上大约半小时,rex 会逐个检查每部影片。在完成之前,**Status** 会显示 **Syncing**,完成后显示数量,例如 **Ready · 97 titles**。随便选一部影片播放即可。

![在电视上通过 Plex 应用播放 rex 提供的 1914 年卓别林短片](../assets/rex/android-tv-playing.webp)

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

- **播放在家里进行。** 在外面使用时，Plex 应用需要一个能访问到该设备的 HTTPS 地址，这就需要在你的路由器上设置端口转发到它。请参阅[在外面使用它（可选）](any-source.md#use-it-outside-your-home-optional)。
- **设备就是服务器。** 请保持它开机，通过 Wi-Fi 或以太网连接，并接通电源。如果要为无法播放某个文件的播放器转换视频，会用到设备自身的硬件，在便宜的盒子上可能会很慢。
- **只有插件带来的内容。** 设备本身没有存放任何文件的资料库。
- **暂未在 Google Play 上架。** 要更新的话，把 [releases 页面](https://github.com/debridmediamanager/rex-android/releases/latest)上的新文件直接安装到旧版本之上即可，rex 会自动重新启动。你的登录信息和插件都会保留。

## 故障排除 {#troubleshooting}

| 你看到的 | 该怎么做 |
|---|---|
| **App not installed as app isn't compatible with your phone.** | 你选的文件和处理器不匹配。请从步骤 1 的表格中选另一个文件。 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | 端口填 `32500` |
| **Use a number from 1024 to 65535** | 端口必须是该范围内的数字 |
| Plex 应用中看不到服务器 | 用步骤 4 中使用的同一账号登录 Plex 应用，并让两台设备保持在同一个家庭网络中。 |
| 媒体库是空的 | 首次同步仍在进行：等待 **Status** 显示出标题数量。 |
| 插件下方显示 **Sign in needed** | 按下它的 **Sign in** 按钮并输入验证码。 |
| 插件下方显示 **Needs an update** | 当前版本的应用已无法运行该插件的这个副本。刷新它的仓库并按下 **Update**。期间它的标题会保留。 |
| **That isn't a repository link. Try github.com/user/repo.** | 输入仓库链接，例如 `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | 链接有误，或仓库是私有的。请在浏览器中检查。 |
| 屏幕关闭时 rex 停止运行 | 重新设置步骤 3 中的后台设置，并参阅 [不要杀我的应用](https://dontkillmyapp.com/) |

**Logs** 会显示 rex 和插件最近输出的内容，其中的密钥和密码已被隐藏。如果支持人员要求提供日志，请按下 **Send logs to support**：在发送任何内容之前，你都能看到全部内容。然后按下 **Send**，并把得到的代码发送出去。

应用会发送什么内容、发往何处，请见其 [隐私政策](android-privacy.md)。

遇到问题？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。
