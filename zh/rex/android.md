# rex 安卓版 {#rex-for-android}

rex 是一个用于 Plex 应用的媒体服务器，本身不拥有任何文件。rex for Android 可以把它直接跑在手机、平板、Android TV、Google TV 或 Fire TV 上，不需要电脑。你设备上的 Plex 应用会像找普通 Plex 服务器一样找到它，并从它那里播放内容。

它能播放的内容来自 **addons**（插件）。一开始就有互联网档案馆（Internet Archive）的公共领域电影。更多插件，比如你的 Stremio 插件、YouTube 和 Spotify，在添加它们的仓库后可以直接在应用里安装。

rex for Android 是免费的。如果你也想把 debrid 账户和 Usenet 加进来，可以用 zurg+rex：一个在手机上运行、内置 zurg 的 Plex 服务器，需要赞助才能使用。详见 [zurg+rex for Android](../zurg/guides/android.md)。

## 开始之前 {#before-you-start}

| 你需要 | 原因 |
|---|---|
| 运行 Android 8.0 或更新版本的设备 | 手机、平板、Android TV、Google TV 或 Fire TV。运行 Vega OS 的 Fire TV，例如 Fire TV Stick 4K Select，无法运行 Android 应用 |
| 一个 Plex 账户 | rex 会显示在登录了该账户的 Plex 应用中。免费账户就够用了 |
| 你观看时所用设备上的 Plex 应用 | Plex for Android、Android TV、iPhone、智能电视、Plex Web、Plexamp |

## 第 1 步：获取应用 {#step-1-get-the-app}

| 方式 | 适合 |
|---|---|
| Google Play | 手机、平板、Android TV 和 Google TV。即将推出 |
| Amazon Appstore | Fire TV 和 Fire 平板。即将推出 |
| [Obtainium](#with-obtainium) | 手机和平板。更新会自动获取 |
| [Downloader](#with-downloader-on-fire-tv) | Fire TV 和电视盒子 |
| [GitHub 上的文件](#the-file-from-github) | 任何设备。更新需要你自己安装 |

选一种方式即可。每种方式都有自己的更新方法来保持 rex 为最新版本。

**各种方式不能混用。** Google Play、Amazon Appstore 和 GitHub 上的文件（Obtainium 和 Downloader 安装的也是这个）使用的签名不同，因此无法互相更新。要切换方式，请先卸载 rex，然后重新执行第 2 步和第 3 步。

**它们默认的插件不同。** GitHub 上的文件默认已添加 [rex-addons](https://github.com/debridmediamanager/rex-addons) 仓库。应用商店版本默认只有 Internet Archive 插件；如果你想要 rex-addons，请自行添加（参见 [附加组件](#addons)）。

### 使用 Obtainium {#with-obtainium}

[Obtainium](https://obtainium.imranr.dev/) 可以从 GitHub 安装应用，并保持它们更新。

1. 安装 Obtainium。
2. 在同一台设备上，打开 [rex.debridmediamanager.com/obtainium](https://rex.debridmediamanager.com/zh/obtainium)。Obtainium 会打开并询问是否要 **Import app**。点按 **Continue**。
3. 点按 **rex**，然后点按 **Install**。Obtainium 会根据你设备的处理器选择对应的文件。
4. 第一次安装时，Android 会提示 Obtainium 不允许安装应用。打开 **Allow from this source**，然后返回。
5. 点按 **Install**。如果 Play Protect 显示 **App scan recommended**，点按 **Scan app**，然后点按 **Install**。

当有新版本发布时，Obtainium 会在 rex 旁边显示 **Update**。

### 在 Fire TV 上使用 Downloader {#with-downloader-on-fire-tv}

1. 在 Fire TV 上，从 Appstore 安装 AFTVnews 出品的 **Downloader**。
2. 打开它，选中地址框并输入 `rex.debridmediamanager.com/tv`。按 **Next**。它会下载 `rex-android-armeabi-v7a.apk`。
3. 按 **Install**。第一次时，Fire TV 会改为打开 **Developer options**。选择 **Install unknown apps**，再选 **Downloader**，让它显示 **ON**。按两次返回键，然后再次按 **Install**。
4. 按 **Install**，然后按 **Open**。

要更新，请重复第 2 到 4 步。一个简短的 Downloader 代码即将推出。

### 从 GitHub 下载文件 {#the-file-from-github}

在设备上,下载适合其处理器的文件。每个链接始终指向最新版本:

| 你的设备 | 下载 |
|---|---|
| 大多数手机、平板和电视盒子(64 位) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Fire TV,以及较旧或较便宜的 32 位盒子 | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| 电脑上的模拟器 | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

所有版本及其更新内容都在[发布页面](https://github.com/debridmediamanager/rex-android/releases)。不确定选哪个?先试试 `arm64-v8a`。同一个文件既能用于手机,也能用于电视。

打开下载的文件。Android 会提示**不允许从此来源安装未知应用**。点按**设置**,打开**允许来自此来源**,然后返回并点按**安装**。

要更新,直接把新文件覆盖安装到旧版本上即可。rex 会自动重新启动,你的登录信息和插件都会保留。

**你应该看到的画面。** 应用列表中出现 **rex**。

## 第 2 步：启动 rex {#step-2-start-rex}

**rex** 打开。第一个界面显示 **Welcome to rex.**

1. 点 **Allow notifications**，然后点 **Allow**。rex 会在后台运行，并显示一条通知，你可以通过它停止 rex。
2. 点 **Let rex keep running in the background**。在打开的列表中，选择 **rex**，然后选 **Don't optimize**。在较新的 Android 上，应该是 **Allow background usage**，然后选 **Unrestricted**。返回 rex。这两个按钮现在前面都有 ✓。
3. **Name** 是 Plex 应用里显示的服务器名称。想改就改。
4. **Port** 保持 `32400`。如果这台设备上已经运行了其他 Plex 服务器，rex 会提示 **Another app here already uses this port, maybe a Plex server. Try 32500.** 此时输入 `32500`。
5. 点 **Start rex**。

**你应该看到的画面。** **2 / 2** 和 **Sign in to Plex.**

| 第一个界面 | Plex 应用中的影片页面（第 4 步） |
|---|---|
| ![rex for Android 的第一个界面，包含名称和端口字段以及 Start rex](../assets/rex/android-setup.webp) | ![Plex for Android 中来自 Internet Archive 的一部 1916 年无声电影的页面](../assets/rex/android-plex-film.webp) |

## 第 3 步：登录 Plex {#step-3-sign-in-to-plex}

按下 **Sign in to Plex**。rex 会显示一个代码：**On any phone or computer, go to plex.tv/link and enter** it。

- **在手机或平板上**，你的浏览器也会打开一个 Plex 页面，上面写着 **rex for Android would like to sign in to your Plex account**。在那里登录即可。
- **在电视上**，请用手机或电脑打开 [plex.tv/link](https://plex.tv/link)，登录并输入代码。

使用你的 Plex 应用当前登录的账号。你可以按 **Skip for now**，之后再从 **Status** 登录。

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**你应该看到的结果。** **Signed in. rex shows up in the Plex apps as** 你的服务器名称。按 **Done**。**Status** 会显示 **RUNNING** 和 **Ready for the Plex apps.**

## 第 4 步：在 Plex 应用中观看 {#step-4-watch-in-a-plex-app}

用同一账号登录的任意 Plex 应用打开。如果 Plex 在这台设备上,**Status** 里有一个 **Open Plex** 按钮。

在 Plex for Android 中,打开 **Libraries**,然后是 **All Libraries**,再点你服务器名称下的 **Movies**。其他 Plex 应用也都在服务器名称下列出它。

Internet Archive 的首次同步需要一些时间:在我们的测试设备上大约半小时,rex 会逐个检查每部影片。在完成之前,**Status** 会显示 **Syncing**,完成后显示数量,例如 **Ready · 97 titles**。随便选一部影片播放即可。

![在电视上通过 Plex 应用播放 rex 提供的 1914 年卓别林短片](../assets/rex/android-tv-playing.webp)

## 附加组件 {#addons}

**Addons** 列出你安装过的插件。每个插件都会显示它的标题和上次同步的时间。它的按钮有 **Sync now**、**Settings**、**Log** 和 **Remove**；在手机上，把这一排按钮左右滑动即可看到全部。**Enabled** 开关可以在不删除插件的情况下将其关闭。

插件来自 **repositories**（仓库）：即保存插件的 git 仓库。Internet Archive 插件已预装。如需更多插件，请添加 [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons)（见下方 **Add a repository**），它提供以下插件：

| 插件 | 提供的内容 |
|---|---|
| Stremio addons | 你的 Stremio 插件中的电影和剧集目录，播放内容来自你的流插件提供的流 |
| YouTube | 你的 YouTube 播放列表。需要使用验证码登录 |
| Spotify | 你的 Spotify 资料库，作为音乐提供给 Plex 和 Plexamp。需要先登录 YouTube 插件 |

**安装插件。** 在 **Repositories** 下，点击仓库旁边的 **Addons**，然后点击插件下方的 **Install**。rex 会显示它能访问的网站，并再次询问一次，然后开始同步该插件。

**登录。** 需要账户的插件会显示 **Sign in to start.**。点击它的 **Sign in** 按钮：在任意设备上前往它指定的页面，并输入显示的验证码。

**添加仓库。** 在 **Add a repository** 下，输入仓库链接（`github.com/user/repo` 即可），然后点击 **Add**。请只从你信任的人那里安装。如需编写自己的插件，请参阅 [rex-addons](https://github.com/debridmediamanager/rex-addons)。

## 在家中的其他设备上观看 {#watch-on-other-devices-at-home}

Plex 应用只要登录的是同一个账号，就能在家庭网络里通过名称找到 rex：电视、另一部手机、电脑上的 Plex 网页版都可以。**Status** 会显示 rex 在家里的地址，例如 `http://192.168.1.20:32400`。

如果想让家人用自己的 Plex 账号观看，请参阅 [与家人和朋友共享 rex](sharing.md)。

## 保持运行 {#keep-it-running}

- rex 在设备开机期间持续运行。通知中的 **Stop** 可以停止它；**Status** 中有 **Start**、**Stop** 和 **Restart**。
- 在 **Settings** 中打开 **Start when this device turns on**。否则重启后，请打开 rex 并按 **Start**。
- 一些手机仍会关闭后台应用。[Don't kill my app](https://dontkillmyapp.com/) 说明了你的应用需要哪些设置。
- 要重命名服务器，请在 Plex 应用中打开 **Settings**、**General**，然后修改 **Friendly name**。

## 限制 {#limits}

- **在家里可以播放。** 在外面时,Plex 应用需要一个能访问到设备的 HTTPS 地址,这就需要在你的路由器上为它设置端口转发。参见 [在家庭之外使用](any-source.md#use-it-outside-your-home-optional)。
- **设备就是服务器。** 让它保持开机,通过 Wi-Fi 或以太网联网,并接上电源。当播放器无法播放某个文件时,转码会使用设备自身的硬件,在便宜的盒子上可能会很慢。
- **只有插件带来的内容。** 设备本身没有存放文件的库。

## 故障排除 {#troubleshooting}

| 你看到的 | 该怎么做 |
|---|---|
| **App not installed as app isn't compatible with your phone.** | 你选错了处理器对应的文件。请从第 1 步的表格中换另一个文件试试 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | 把端口填成 `32500` |
| **Use a number from 1024 to 65535** | 端口必须是这个范围内的数字 |
| Plex 应用里找不到这台服务器 | 让 Plex 应用登录你第 3 步用的同一个账号，并确保两台设备连在同一个家庭网络上 |
| 媒体库是空的 | 第一次同步还在进行中：等到 **Status** 显示出标题数量 |
| 插件下面显示 **Sign in needed** | 按下它的 **Sign in** 按钮，然后输入验证码 |
| 插件下面显示 **Needs an update** | 这个版本的应用已经无法运行该插件的这个副本。请刷新它的仓库，然后按 **Update**。这期间它的标题会保留 |
| **That isn't a repository link. Try github.com/user/repo.** | 输入仓库的链接，例如 `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | 链接有误，或者仓库是私有的。请用浏览器打开检查一下 |
| 屏幕关闭后 rex 就停止运行 | 重新设置第 2 步中的后台选项，并参考 [别杀我的应用](https://dontkillmyapp.com/) |

**Logs** 会显示 rex 和插件最近输出的内容，其中的密钥和密码已被隐藏。如果支持人员索要日志，请按 **Send logs to support**：在任何内容发送之前，你都能看到全部内容，然后按 **Send**，并把得到的代码发出去。

应用会发送哪些内容、发送到哪里，都写在它的[隐私政策](android-privacy.md)里。

还有问题？可以到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。
