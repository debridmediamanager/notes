# rex 与你自己的应用 {#rex-with-your-own-app}

[rex](https://rex.debridmediamanager.com/zh/) ist ein Medienserver für die offiziellen Plex-Apps, der selbst keine Dateien besitzt. Die offiziellen Plex-Apps sehen rex als normalen Plex-Server. Ein anderes Programm, das diese Seite **deine App** nennt, teilt rex mit, was in deiner Bibliothek liegt, und liefert die Dateien aus. Wenn du auf Abspielen drückst, streamt rex die Datei direkt aus deiner App. Es wird nichts vorher heruntergeladen.

Diese Seite führt dich Schritt für Schritt von null bis zum ersten abgespielten Film. Sie setzt keine bestimmte App voraus. Sie sagt genau, was rex von einer App erwartet, damit du prüfen kannst, ob deine App das leistet, oder selbst eine bauen kannst. Bei jedem Schritt steht, was er tut, warum er wichtig ist und was du sehen solltest, bevor du weitermachst.

Vier Dinge solltest du vor dem Start wissen:

- **Deine App liefert die Dateien.** rex holt jedes Byte von deiner App über HTTP oder HTTPS, so wie ein Browser eine Datei herunterlädt. rex speichert keine Dateien und braucht für Medien keine Festplatte und kein Mount.
- **Deine App meldet rex, was sie hat.** Sie schickt rex eine Liste der Dateien über die Feed-API von rex und danach jede Änderung. rex listet nie einen Ordner auf und scannt nichts.
- **Deine App entscheidet, was jede Datei ist.** Sie sagt, ob eine Datei ein Film oder eine Episode ist, zu welchem Titel sie gehört (per IMDb- und TMDB-ID) und bei einer Episode, welche Staffel und Nummer sie hat. rex rät nie anhand des Dateinamens.
- **Plex beschreibt es.** Sobald rex mit einem Plex-Konto verbunden ist, zeigt es jeden Titel mit Name, Poster, Zusammenfassung und Episodennamen aus den eigenen Metadaten von Plex für diese IDs. Für Inhalte, die kein Plex-Agent kennt, benennt deine App sie selbst: siehe [Building rex addons](addons.md).

rex ist für die private Nutzung kostenlos (PolyForm Noncommercial). Es gibt keine Sponsorenstufe und du brauchst kein Konto, um es herunterzuladen. Siehe [rex.debridmediamanager.com](https://rex.debridmediamanager.com/zh/). Hast du nur ein Handy oder eine TV-Box? [rex für Android](android.md) betreibt rex und seine Addons auch darauf. Für Sponsoren verbindet [zurg+rex](../zurg/guides/android.md), ein Plex-Server auf deinem Handy, außerdem deine Debrid- und Usenet-Bibliothek mit rex.

## 开始之前 {#before-you-start}

| 你需要的 | 原因 |
|---|---|
| rex 的每日构建版 2026.10.25 或更新版本 | 第 1 步会下载最新版本 |
| 一台保持开机的机器：Linux（Ubuntu 22.04 或更新版本）、macOS 或 Windows（64 位） | rex 是一个服务器：你的 Plex 应用在你按下播放时会连接到它。命令因系统而异的步骤会为每个系统提供一个标签页。[Docker](#run-rex-in-docker) 在下文，适用于 Linux |
| 1 GB 内存 | 在有 4,062 部电影和 656 部剧集（34,678 集）的库中，rex 启动时占用不到 500 MB，浏览库时约占用 730 MB。转换视频需要更多内存，还需要更多 CPU 核心或显卡 |
| 一个能完成 [应用必须做到的事](#what-your-app-must-do) 中所列功能的应用 | 你的库就是从这里来的 |
| 你的应用从这台机器、你的家庭网络或 Tailscale 推送数据 | rex 只接受来自这些地方的数据推送（[保持端口私密](#keep-the-port-private)）。位于种子盒或云服务器上的应用无法向 rex 推送，除非该服务器在你的 tailnet 中；文件本身可以从 rex 能访问到的任何地方提供 |
| 文件存放在这台机器的磁盘上？需要一个通过 HTTP 提供并推送这些文件的服务 | rex 从不直接读取磁盘。[第 2 步](#step-2-see-it-work-by-hand) 会手动为一个文件演示这一过程；其他文件请继续使用 Plex 管理 |
| Usenet？需要一个能读取它的源，例如 zurg | rex 从不与 Usenet 提供商通信。zurg 是能做到这一点的源：参见 [rex 与 zurg](with-zurg.md) |
| 专为 rex 新建的 Plex 账户 | rex 会在[添加到 Plex 账户](#step-3-add-it-to-a-plex-account)后从 Plex 获取所有标题、海报、简介和剧集名称。在此之前，标题会保留文件名，且没有海报 |

## 你的应用需要做什么 {#what-your-app-must-do}

把这份清单交给开发你应用的人。rex 自己的 API 参考文档见 [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md)。

| 你的应用必须 | 做法 | 如果不这样做 |
|---|---|---|
| 通过 HTTP 提供每个文件 | `GET <address>/<path>` 返回该文件。`Range` 请求能让拖动进度更快;会跟随重定向。允许使用 Basic 认证或 bearer 令牌 | 什么都播放不了:rex 会记录 502 |
| 向 rex 注册 | `PUT /rex/sources/<name>`(名称只能包含字母、数字、`-` 和 `_`),请求体为 `{"url": ...}`;如果有登录信息,则加上 `"user"` 和 `"password"` 或 `"bearer"`,但绝不能放在 url 里。每次启动时都要再注册一次 | rex 没有可读取的来源 |
| 发送它拥有的每一个文件 | `POST /rex/feed/<name>/items`,每次请求发送几百个文件 | rex 会一直是空的 |
| 发送每个文件的 ffprobe 输出 | ffprobe 的 `-show_format -show_streams` JSON,完整地放在 `media_info` 中 | 该文件会被**暂存**:已保存但不显示,因为 Plex 应用没有它就拒绝播放该文件 |
| 说明每个文件是什么 | `kind`(`movie`、`episode` 或 `extra`)和 `ids`:电影的或**剧集**的 `imdb` 或 `tmdb`(二者任选其一即可),绝不能用单集的。对于单集,`season` 和 `episode` 放在条目本身上(与 `kind` 同级,不要放在 `ids` 里),编号采用 TMDB 的方式;如果一个文件包含多集,则用 `episode_end` | 该文件无法匹配:电影会以文件名作为标题,剧集会以发布名作为剧名,并按文件顺序编号 |
| 让每个文件的 `id` 永远保持不变 | 即使文件被重命名也要如此 | 重命名后的文件会变成新的标题,并丢失观看历史 |
| 实时发送变更 | 新增或修改的文件使用相同的 `POST`,被删除的文件使用 `DELETE /rex/feed/<name>/items` | 媒体库会变得过时 |
| 不时发送完整的媒体库 | `PUT /rex/feed/<name>/snapshot`。快照中未列出的内容,rex 会将其删除 | 你的应用已丢失记录的文件会残留在 rex 中 |
| 接受对文件的 WebDAV `DELETE` 请求 | 当有人在 Plex 应用中删除某个标题时,rex 会先请求你的应用删除该文件 | 该标题会保留,Plex 应用会提示无法删除 |

## 第 1 步：安装 rex {#step-1-install-rex}

**它做什么。** 把 rex 下载到 `~/rex`（Windows 上是 `$HOME\rex`），并把它作为服务启动，后面几步需要的东西都会准备好。接下来的步骤不需要重启；只有下面的可选部分才需要。

**为什么重要。** rex 是你的 Plex 应用所连接的对象。第一次启动时会创建 `rex.db`，里面保存你的媒体库、应用发送的所有内容以及观看历史。

在 Linux 上，你也可以改为运行 rex 的 Docker 镜像：见 [在 Docker 中运行 rex](#run-rex-in-docker)。

+++ Linux and macOS
```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(curl -fsSL 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1' | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
P=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL "https://github.com/debridmediamanager/rex/releases/download/$TAG/rex-$TAG-$P.tar.gz" | tar xz --strip-components=1
```
+++ Windows
在 PowerShell 中：

```powershell
New-Item -ItemType Directory -Force $HOME\rex | Out-Null; cd $HOME\rex
$tag = (Invoke-RestMethod 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1')[0].tag_name
curl.exe -fLO "https://github.com/debridmediamanager/rex/releases/download/$tag/rex-$tag-windows-amd64.zip"
tar -xf "rex-$tag-windows-amd64.zip" --strip-components=1; Remove-Item "rex-$tag-windows-amd64.zip"
```
+++

这一步会为你的机器下载 rex 的最新版本，通常是 nightly 构建。

找到 rex 的局域网 IP，也就是它在家庭网络中的地址。在 Linux 上，`hostname -I` 会输出好几个地址：选家庭网络那个，不要选以 `172.17.`（Docker）或 `100.`（Tailscale）开头的。在 macOS 上，`ipconfig getifaddr en0` 会输出它（如果没有输出，就用 `en1`）。在 Windows 上，`ipconfig` 会在你的 Wi-Fi 或以太网适配器下面以 **IPv4 Address** 列出它。**本页所有地方都写作 `192.168.1.20`：请替换成你自己的地址。** Plex 应用、你的应用以及你自己的命令都会通过这个地址连接 rex。

**Plex Media Server 和 rex 在同一台机器上吗？** 请在下面的启动命令末尾加上 `--port 32500`，并且在所有命令或设置中把 `32400` 换成 `32500`，包括 Windows 防火墙规则。Plex 已经占用了 32400 端口，以及应用用来查找服务器的端口；如果 rex 用其他端口，就会把这些端口留给 Plex。这样你的应用里会出现两个同名的服务器：rex 是分享给你的那个，旁边会带着新账号的名字。等 rex 绑定到它的 Plex 账号之后（[第 3 步](#step-3-add-it-to-a-plex-account)），你可以给它改名：用该账号登录 Plex，打开 rex 的 **Settings**，进入 **General**，修改 **Friendly name** 并保存，然后按下面的方法重启 rex。重启后，Plex 应用会显示新名字。

现在把它设置为服务：

+++ Linux
创建 `~/.config/systemd/user/rex.service`：

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rex
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
sudo loginctl enable-linger "$USER"
journalctl --user -u rex -f
```

rex 的**启动命令**是 `ExecStart` 那一行，密钥写在 `~/rex/rex.env` 中，每行一个 `NAME=value`。修改后，执行 `systemctl --user daemon-reload && systemctl --user restart rex` 即可重启 rex。`journalctl --user -u rex -f` 可以查看它的日志。`loginctl enable-linger` 可以让 rex 在你注销后继续运行。
+++ macOS
`run.sh` 会在它所在的文件夹中启动 rex，而 LaunchAgent 会在你登录时启动 `run.sh`：

```bash
cp ~/rex/examples/run.sh.example ~/rex/run.sh
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.rex.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rex</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/rex/run.sh</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/rex/rex.log</string>
  <key>StandardErrorPath</key><string>$HOME/rex/rex.log</string>
</dict></plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.rex.plist
tail -F ~/rex/rex.log
```

rex 的**启动命令**是 `~/rex/run.sh` 的最后一行，密钥写在 `~/rex/rex.env` 中，每行一个 `NAME=value`。修改后，执行 `launchctl kickstart -k gui/$(id -u)/com.rex` 即可重启 rex。`tail -f ~/rex/rex.log` 可以查看它的日志。

只要你登录了这台 Mac，rex 就会一直运行。如果这台 Mac 会自己重启，请打开自动登录（**System Settings**，**Users & Groups**）。如果开启了 macOS 防火墙，请在系统询问时允许 rex，或者在防火墙的 **Options** 中添加 `~/rex/rex`。
+++ Windows
以**管理员身份**打开 PowerShell，然后用 `cd $HOME\rex` 进入 rex 的文件夹。首先创建 `run.cmd`，它会在 rex 所在的文件夹中启动 rex，并把日志写入 `rex.log`。记事本会提示你创建该文件：

```powershell
notepad run.cmd
```

```bat
@echo off
cd /d "%~dp0"
rex.exe 2>> rex.log
```

保存文件。然后在 Windows 防火墙中放行 rex 的端口以及两个发现端口，并立即启动 rex，之后每次登录时也自动启动：

```powershell
New-NetFirewallRule -DisplayName rex -Protocol TCP -LocalPort 32400
New-NetFirewallRule -DisplayName "rex discovery" -Protocol UDP -LocalPort 32410,32414
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask rex -Action (New-ScheduledTaskAction -Execute "$HOME\rex\run.cmd") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Settings $settings
Start-ScheduledTask rex; Start-Sleep 3
Get-Content rex.log -Wait
```

rex 的**启动命令**是 `run.cmd` 中的 `rex.exe` 那一行，密钥写在它上面，每行一个 `set NAME=value`。修改后，执行 `Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex` 即可重启 rex。`Get-Content $HOME\rex\rex.log -Wait` 可以查看它的日志。

如果你是在 PowerShell 中手动启动的 rex，那么它的日志只会显示在那个窗口里，不会生成 `rex.log`，重启后也没有任务会帮你启动它。rex 会把数据库和认领信息保存在它启动时所在的文件夹中，所以从其他文件夹启动的 rex 会是一个新的、未被认领的服务器。请按 Ctrl+C 停止它，然后在 rex 的文件夹中用相同的参数重新启动；更好的做法是设置上面的任务。

rex 只有在你登录 Windows 时才会运行，并且会在自己的窗口中运行：请保持窗口打开。在 PowerShell 中，本页提到 `curl` 的地方请输入 `curl.exe`：Windows PowerShell 自带的 `curl` 是另一个命令。
+++

**你应该看到什么。** 前几行日志中会有：

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
INFO    no source yet: a source registers itself once pointed at this server (PUT /rex/sources/{name}, docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://192.168.1.20:32400  machine=...  items=0  parts=proxy
```

rex 会以机器名称命名自己，你的 Plex 应用会显示这个名字。`no source yet` 是正常的：还没有应用注册。保持日志窗口打开。

## 第 2 步：手动验证它能工作 {#step-2-see-it-work-by-hand}

**作用。** 用一个临时文件服务器和两条 `curl` 命令，替你的应用扮演一次角色，只处理一部电影。

**为什么重要。** 它能在应用介入之前，先证明 rex 在这台机器上能正常工作。如果这一步成功，而你的应用不行，那问题就出在应用上。如果你的应用已经配置好了，可以跳过这一步。

你需要 `ffprobe`、一个小型网页服务器和一个视频文件。先用名称 `test` 把文件所在的文件夹注册到 rex 里，然后把文件发给 rex，并告诉它这是电影 Sintel（IMDb `tt1727587`，TMDB `45745`），同时附上 ffprobe 的输出。

+++ Linux and macOS
安装 `ffprobe` 和 `jq`（Linux 上运行 `sudo apt install -y ffmpeg jq`，macOS 上运行 `brew install ffmpeg jq`）。把文件放到一个小型网页服务器能够提供访问的位置：

```bash
mkdir -p ~/rex-test/movies/Sintel.2010
cp /path/to/any-video.mkv ~/rex-test/movies/Sintel.2010/Sintel.2010.mkv
cd ~/rex-test
python3 -m http.server 8099 --bind 127.0.0.1 &
```

用 rex 注册这个文件夹：

```bash
curl -s -X PUT http://192.168.1.20:32400/rex/sources/test \
  -H 'Content-Type: application/json' -d '{"url": "http://127.0.0.1:8099"}'
```

把文件发给 rex：

```bash
P=movies/Sintel.2010/Sintel.2010.mkv
jq -n --arg p "$P" \
  --argjson probe "$(ffprobe -v quiet -print_format json -show_format -show_streams "$P")" \
  '{items: [{id: $p, path: $p, kind: "movie", ids: {imdb: "tt1727587", tmdb: 45745}, media_info: $probe}]}' \
| curl -s -X POST http://192.168.1.20:32400/rex/feed/test/items \
    -H 'Content-Type: application/json' --data-binary @-
```
+++ Windows
用 `winget install Gyan.FFmpeg` 和 `winget install Python.Python.3.13` 安装 `ffprobe` 和 Python，然后打开一个新的 PowerShell 窗口。把文件放到一个小型网页服务器能够提供访问的位置：

```powershell
New-Item -ItemType Directory -Force $HOME\rex-test\movies\Sintel.2010 | Out-Null
Copy-Item C:\path\to\any-video.mkv $HOME\rex-test\movies\Sintel.2010\Sintel.2010.mkv
cd $HOME\rex-test
$server = Start-Process py '-m http.server 8099 --bind 127.0.0.1' -WindowStyle Hidden -PassThru
```

用 rex 注册这个文件夹：

```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/test -ContentType application/json -Body '{"url": "http://127.0.0.1:8099"}'
```

把文件发给 rex：

```powershell
$p = 'movies/Sintel.2010/Sintel.2010.mkv'
$probe = ffprobe -v quiet -print_format json -show_format -show_streams $p | Out-String | ConvertFrom-Json
$item = @{ id = $p; path = $p; kind = 'movie'; ids = @{ imdb = 'tt1727587'; tmdb = 45745 }; media_info = $probe }
Invoke-RestMethod -Method Post http://192.168.1.20:32400/rex/feed/test/items -ContentType application/json -Body (ConvertTo-Json @{ items = @($item) } -Depth 20)
```

PowerShell 会把 rex 的回复显示为列表，而不是 JSON。
+++

**你应该看到什么。** 回复是 `{"created":1,"updated":0,"held":0,"unchanged":0}`，rex 的日志会打印：

```
INFO    FEED identified "Sintel.2010" -> movie tmdb:45745 (placed)
INFO    FEED test upsert: 1 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Sintel 现在出现在 **Movies** 里，并从这个小型网页服务器播放。在 [第 3 步](#step-3-add-it-to-a-plex-account) 之前，没有任何 Plex 应用能打开 rex，所以这一步只检查数据源本身。

**清理。** 继续之前，删除测试数据源会同时删除它发送过的所有内容。第一次请求会返回一个 `confirm` 路径；在五分钟内向该路径发送 `DELETE` 请求。

+++ Linux and macOS
```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/test
curl -s -X DELETE "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
kill %1
```
+++ Windows
```powershell
Invoke-RestMethod -Method Delete http://192.168.1.20:32400/rex/sources/test
Invoke-RestMethod -Method Delete "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
Stop-Process -InputObject $server
```
+++

**如果没有成功。**

- `"held":1`：缺少 `media_info`，或者它里面没有任何流。请检查 `ffprobe` 是否为该文件输出了 JSON。
- 回复中出现 `rejected`：文件的扩展名不是视频格式、是样片、缺少 `id` 或 `path`、路径格式不正确，或者另一个 `id` 已经占用了该路径。回复和 rex 的日志会分别说明原因。
- `404 no such source`：说明之前没有先执行 `PUT /rex/sources/test`。

## 第 3 步：添加到 Plex 账号 {#step-3-add-it-to-a-plex-account}

**What it does.** Registers rex on a Plex account, as you would a real Plex Media Server, and shares it with your own account.

**Why it matters.** rex gets every title's name, poster, summary and episode names from Plex's own metadata, and it may only ask Plex once it is on an account. What your app sends before the claim is named as soon as it lands, and Fix Match has nothing to offer until then. It also removes the "unclaimed" notice and is needed before [using rex outside your home](#use-it-outside-your-home-optional).

**Use a fresh Plex account for this, not your own.** rex is not made by Plex, and Plex could take action against an account that registers it. Keep your real account, with its watch history, friends and any Plex Pass, out of reach: make a new free account at [plex.tv](https://www.plex.tv) with an email address you do not use elsewhere, register rex on that one, and share rex with your own account. You then watch signed in as yourself, the way you would watch a friend's server. rex plays nothing until this step is done.

### 在新账号上注册 rex {#register-rex-on-the-fresh-account}

1. 用**全新的账号**登录 [plex.tv](https://www.plex.tv)，打开 [plex.tv/claim](https://www.plex.tv/claim) 并复制验证码。验证码大约五分钟后过期。
2. 在 rex 所在的机器上（Windows 上使用 `curl.exe`）：

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**正常情况下你会看到的结果。** 第二条命令会显示 `claimed="1"`，并且 rex 的文件夹里会出现 `claim_state.json`。请备份这个文件：没有它，rex 就得重新绑定，而只要该文件还在，rex 就会拒绝再次绑定。之后影片会带着名称和海报显示出来，无需重启。

**如果不是这样。**

- 第一条命令返回 `409` 和 `rex: already claimed`：rex 已经绑定了某个 Plex 账号。
- 它返回 `500 Internal Server Error`，并且 rex 记录了 `claim exchange failed`：验证码已过期或已被使用。请到 [plex.tv/claim](https://www.plex.tv/claim) 重新获取一个。

### 与你自己的账号共享 {#share-it-with-your-own-account}

1. 仍然登录着新账户，打开 [app.plex.tv](https://app.plex.tv)，然后点击 **Settings**（扳手图标）、**Manage Library Access**，再点击 **Grant Library Access**。
2. 输入你自己账户的用户名或邮箱，选择 rex 服务器以及两个媒体库 **Movies** 和 **TV Shows**，然后发送邀请。
3. 退出登录，以**你自己的身份**登录，然后接受邀请。邀请会通过邮件发送，也会出现在 app.plex.tv 中。

![app.plex.tv 设置中的 Manage Library Access，以及 Grant Library Access 按钮](../assets/rex/20-plex-manage-library-access.webp)

![Grant Library Access 对话框，rex 服务器的 Movies 和 TV Shows 已勾选](../assets/rex/21-plex-grant-library-access.webp)

**你应该看到的效果。** 以你自己的身份登录后，Plex 应用会在你自己的服务器旁边列出 rex 服务器，并显示两个媒体库。你在 rex 上的观看记录属于你自己，会与新账户的记录分开保存。如果家里还有其他人需要访问，也用同样的方法共享即可。

## 第 4 步：连接你的应用 {#step-4-connect-your-app}

**作用。** 让你的应用指向 rex。你的应用会先注册，然后发送整个库，之后每次变化都会实时发送。

**为什么重要。** 这是两者之间唯一的连接。rex 没有针对你的应用的设置：是你的应用去找 rex，而不是反过来。

把 rex 的地址 `http://192.168.1.20:32400` 填入你的应用。具体怎么填，取决于你的应用。

**你应该看到什么。** rex 的日志会在你的应用注册时使用的名称下打印：

```
INFO    SOURCES myapp registered at http://192.168.1.20:8080
INFO    SOURCES PUT /rex/sources/myapp -> 200
INFO    FEED myapp upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Some.Movie.2019.1080p" -> movie tmdb:12345 (placed)
INFO    FEED myapp upsert: 180 created, 0 updated, 20 held, 0 unchanged, 0 rejected
```

rex 会从 `registered at` 那一行的地址读取每个文件，所以你的应用必须能在该地址被访问；只有地址变化时，rex 才会再次记录这一行。`held` 文件正在等待 ffprobe 输出，你的应用一发送结果，它们就会出现。随时都可以从你的应用检查 rex 拥有的内容（在 Windows 上使用 `curl.exe`，不要加 `| head -c 600`）：

```bash
curl -s http://192.168.1.20:32400/rex/sources                # the apps that registered, and their addresses
curl -s http://192.168.1.20:32400/rex/feed/myapp/items | head -c 600   # what is shown
curl -s http://192.168.1.20:32400/rex/feed/myapp/held  | head -c 600   # what waits for ffprobe output
```

**如果没有。**

- rex 日志里完全没有内容：你的应用没有连到 rex。检查你填写的地址，以及两台机器之间 rex 的端口是否开放。
- 文件到了，但没有 `identified` 行：你的应用没有发送 `kind` 和 `ids`（held 文件和内容未变的重复发送也不会打印这些）。在此之前，这些标题都不会被匹配；你仍然可以用一个新账户登录的 Plex 应用，通过 **Fix Match** 手动修正。与 rex 共享的你自己的账户会被拒绝。
- 标题出现了，但无法播放：rex 无法访问你的应用在 `registered at` 中的地址。[出问题时怎么办](#when-something-is-wrong)表格中的 `upstream failed` 一行会帮你检查这一点。

## 第 5 步：观看内容 {#step-5-watch-something}

**作用。** 在 Plex 应用中打开 rex，和打开任何 Plex 服务器的方式一样。

**为什么重要。** 这是整个设置的核心。它也验证了最后一环：你观看时，rex 能从你的应用中读取文件。

在**同一个家庭网络**中的手机、电视或电脑上打开 Plex 应用。rex 会显示在该设备名称下，并带有 **Movies** 和 **TV Shows**。选一部电影，然后按播放。

![Plex 应用的侧边栏显示 rex 服务器的 Movies 和 TV Shows，旁边是电影网格](../assets/rex/10-plex-server-libraries.webp)

在家里不需要其他设置：Plex 应用通过 Plex 自带的本地发现功能找到 rex，然后通过你的网络连接。这要求设备与 rex 位于同一网络（不能是访客 Wi-Fi 或单独的 VLAN）。发现功能使用 UDP 端口 32410 和 32414，所以运行 rex 的机器上的防火墙必须允许这些端口（在 Windows 上，第 1 步的防火墙规则已经包含这些）。rex 使用端口 32400 时会响应发现请求。如果因为 Plex 和 rex 运行在同一台机器上，你把 rex 改到了 32500，那么发现功能就交给 Plex 处理，应用会通过 rex 所[共享到的](#share-it-with-your-own-account) Plex 账户找到它。在家里，网页浏览器中的 app.plex.tv 也能用，使用 [rex-direct](#rex-direct) 在 rex 被认领后分配给它的 HTTPS 地址（需要 rex nightly 2026.11.02 或更新版本）。第一次使用时，Chrome 会询问 app.plex.tv 是否可以访问本地网络上的设备：请允许。`http://192.168.1.20:32400/web` 不是 Plex Web：rex 没有自己的网页应用，那个页面只显示 rex 是否已被认领以及在哪里观看。

**你应该看到的。** 海报、标题和年份，和任何 Plex 服务器一样。播放会在几秒内开始。

你可能会遇到两种情况：

- **"yourhost server is unclaimed and not secure"。** Plex 应用对任何不在 Plex 账户上的服务器都会显示这条提示，在它加入账户之前，rex 无法播放任何内容。请完成[第 3 步](#step-3-add-it-to-a-plex-account)。
- **"This server is not powerful enough to convert video"。** 如果每个设备上的每个标题都失败，请在按下播放后立即查看 rex 的日志：那里如果出现 `upstream failed` 或 `502`，说明 rex 无法连接到你的应用，FFmpeg 无法解决这个问题。[出现问题时](#when-something-is-wrong)表格中的 `upstream failed` 一行说明了该怎么做。如果只有部分文件失败，通常是在网页浏览器中，说明该设备无法直接播放这些文件，常见原因是 AC3 或 DTS 音频。电视和手机上的 Plex 应用大多数文件都能直接播放。要在所有设备上播放所有内容，请设置[转换视频](#converting-video-optional)。

**删除会在你的应用中生效。** 使用新账户登录后，在 Plex 应用中对某个标题点击 **Delete**，rex 就会让你的应用删除该文件，具体见[你的应用必须做什么](#what-your-app-must-do)。与 rex 共享的其他账户无法删除。要关闭删除功能：在 app.plex.tv 中以新账户登录，打开 **Settings**，进入 rex 服务器的 **Library**，点击 **Show Advanced**，取消勾选 **Allow media deletion** 并保存。

![rex 服务器的 Library 设置，已展开 Show Advanced，Allow media deletion 被框选](../assets/rex/32-plex-allow-media-deletion.webp)

你的应用删除的文件会像在 Plex 中一样进入库的回收站：文件会保留，显示为不可用，并保留观看历史；如果你的应用再次发送该文件，它会恢复原样。在库中点击 **Empty Trash** 会永久删除它们。**Empty trash automatically after every scan**（位于 Settings，Library 中）默认关闭，开启后会自动完成这项操作。

每个文件会根据你的应用发送的 `kind` 归入 **Movies** 或 **TV Shows**。没有 `kind` 的文件则根据其第一级文件夹决定：`shows` 归入 TV Shows，其他一律归入 Movies。

要为某个文件夹单独创建库，你的应用需要在注册信息中添加 `directories`，指明文件路径的第一级文件夹以及库的标题：`{"url": ..., "directories": [{"name": "anime", "shows": "Anime", "movies": "Anime Movies"}]}`。只写其中一个标题也可以。rex 会在你的应用注册时创建这些库，并把该文件夹中已有的内容原样移入，包括观看历史、Fix Match 和编辑内容。格式错误的条目会被跳过，并在响应的 `ignored` 中列出原因。你可以在 Plex 应用中随意重命名这些库。删除某个库后它会保持删除状态，其文件会回到 Movies 或 TV Shows，直到你用 **Add Library** 重新添加它，其文件夹列表会显示你应用中的文件夹。[来源声明的库](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#libraries-a-source-declares)中有相关规则。

**备份** rex 文件夹中的 `rex.db`（它包含你的库、观看历史和应用登录信息，请妥善保管），以及 `claim_state.json`，并且在 rex-direct 为 rex 分配名称后，还要备份 `rex-direct.json`（它是证书密钥）：

+++ Linux and macOS
```bash
sudo apt install -y sqlite3    # once, on Linux; macOS has it
mkdir -p ~/rex-backup
sqlite3 ~/rex/rex.db ".backup $HOME/rex-backup/rex.db"
cp ~/rex/*.json ~/rex-backup/
```
+++ Windows
Windows 没有 `sqlite3`，所以先暂停 rex，然后复制 `rex.db` 以及旁边两个文件名开头相同的文件：

```powershell
Stop-Process -Name rex; Start-Sleep 1
New-Item -ItemType Directory -Force $HOME\rex-backup | Out-Null
Copy-Item $HOME\rex\rex.db*, $HOME\rex\*.json $HOME\rex-backup
Start-ScheduledTask rex
```
+++

在 Docker 中，这些文件位于 `~/rex/config`，且只有 root 用户可以读取。请在容器内备份：先运行 `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`，然后运行 `mkdir -p ~/rex-backup && sudo cp ~/rex/config/rex.db.bak ~/rex/config/*.json ~/rex-backup/`。

[恢复备份](#restore-a-backup)可以把它们放回原处。

到这里就完成了。下面的内容都是可选的。

## 在家庭网络之外使用（可选） {#use-it-outside-your-home-optional}

**功能说明。** 为 rex 提供一个外出时 Plex 应用也能访问的 HTTPS 地址，并把这个地址告诉 plex.tv。

**为什么重要。** 外出时，app.plex.tv 只能连接 HTTPS 地址，其他 Plex 应用也优先使用 HTTPS。真正的 Plex 服务器可以退回到 Plex 的中继，但 rex 不能，所以你需要自己选择访问方式。rex 必须先[添加到 Plex 账户](#step-3-add-it-to-a-plex-account)。面向互联网的代理必须屏蔽 `/rex/`：参见[保持端口私密](#keep-the-port-private)。

**Plex Pass。** 在外面使用 Plex Web 播放时，两个账户都不需要 Plex Pass 或 Remote Watch Pass。其他 Plex 应用在外出时尚未测试。

无论你选哪种方式，外出观看的每个字节都会经过家里网络的**上传**速度。粗略估计，20 Mbit/s 的上传速度只够传一个 1080p WEB-DL，传不了 remux。

| 你的情况 | 使用 | 原因 |
|---|---|---|
| 你的路由器有公网 IP，并且可以转发端口 | **[rex-direct](#rex-direct)**（最简单） | 默认开启：只需转发一个端口。DMM 会为 rex 分配一个域名和证书，并让域名始终指向你的家庭 IP |
| 你能在要观看的设备上安装 Tailscale | **[Tailscale serve](#tailscale-serve)**（最佳） | 路由器上无需开放任何端口，在任何互联网连接下都能用。证书会自动续期，tailnet 之外的人无法访问 rex |
| 没有 Tailscale 的设备（朋友家的电视、酒店），并且你的路由器有公网 IP | **[Caddy](#caddy)**，使用你自己的域名，或免费的 `sslip.io` 域名 | 直连，中间没有第三方，证书免费且自动续期。需要转发 443 端口 |
| 你的宽带没有公网 IPv4（CGNAT 或 DS-Lite，常见于有线宽带、移动网络和部分光纤运营商），但有 IPv6 | **[rex-direct over IPv6](#rex-direct-over-ipv6)** | 无需端口转发，也无需租用任何服务：只需在 IPv6 上放行 32400 端口。你观看的设备也需要 IPv6，大多数移动网络都支持 |
| 你的宽带完全没有公网 IP，或者你观看的网络没有 IPv6，并且设备上没有 Tailscale | **[小型 VPS](#a-small-vps)** | rex 没有中继，也不会有。你租用的 VPS 拥有公网 IP，隧道把所有流量转发给 rex，带宽为 VPS 的全部带宽 |

不推荐：

- **Cloudflare tunnel。** 每个字节都要经过 Cloudflare，而且它会丢弃文件首次读取时的 `Range`，因此每次开始播放，你的应用都要把整个文件拉下来。
- **Tailscale Funnel、ngrok 和其他托管隧道。** 它们会限制带宽或每月流量，一部电影很快就会用完。Tailscale Funnel 还会公开 rex 的全部内容，包括订阅源 API：互联网上的任何人都能向你的库中添加或删除内容。
- **在不使用 rex-direct 或自有证书的情况下转发 32400 端口。** Plex 应用只能拿到明文 HTTP 地址，而 app.plex.tv 会拒绝这种地址。

### rex-direct

rex-direct 是 DMM 对 plex.direct 的回应，默认就是开启的。在你的路由器上，把端口 32400（TCP）转发到运行 rex 的机器。就这些，不需要重启任何东西。

rex 被认领后，DMM 会给它两个域名：`<hash>.rex-direct.debridmediamanager.com` 指向你家的公网 IP，`lan.<hash>.rex-direct.debridmediamanager.com` 指向 rex 的局域网 IP。两个域名都会配有证书。第一个证书需要几分钟。rex 的日志会显示它正在签发，然后在 `rex-direct:` 开头的行里列出每个域名。家里公网 IP 的变化和证书续期会自动处理。一个 Plex 账号最多可以拥有十个 rex-direct 域名。在家时，Plex 应用（包括 app.plex.tv）可以使用 `lan.` 域名，它直接通过你的局域网连接 rex，所以端口转发只用于不在家的时候。在 app.plex.tv 中，当 Chrome 询问时，请允许访问本地网络上的设备；否则它会退回到公网域名，而公网域名需要端口转发。[你应该看到的内容](#what-you-should-see) 可以帮你检查这两个域名。

如果你的路由器把另一个外部端口转发到 rex，请按照 [第 1 步](#step-1-install-rex) 中对应你系统的说明添加键 `REX_DIRECT_PORT=<that port>`，然后重启 rex。端口转发不会开放 feed API：请参阅 [保持端口私密](#keep-the-port-private)。

### rex-direct over IPv6

对于没有公网 IPv4（CGNAT 或 DS-Lite），但有 IPv6 的网络连接。DMM 通过 IPv6 地址连上 rex 并确认是同一台服务器后，会把 rex 的 rex-direct 域名也指向这个地址。你需要 rex nightly 2026.11.08 或更新版本，并且在 Docker 中使用主机网络模式（host networking）。

IPv6 没有端口转发，也没有端口映射：rex 在内外必须使用同一个端口，所以不要设置 `REX_DIRECT_PORT`。在路由器的防火墙中，允许通过 IPv6 访问 rex 所在机器的 32400 端口的入站 TCP 连接。rex 会在启动（或被认领）一分钟后公布它的 IPv6 地址，之后每 6 小时公布一次，所以请在启动 rex 之前添加这条规则，或者添加后重启 rex。大约一分钟后，它的日志会同时显示两个地址：

```
rex-direct: https://<hash>.rex-direct.debridmediamanager.com:32400 -> <IPv4> and <IPv6>
```

如果几分钟内都没有出现包含 `and <IPv6>` 的日志行，说明 DMM 无法通过 IPv6 连到 rex。请检查防火墙规则，并确认 Docker 中的 rex 使用的是主机网络模式。在 Windows 上，rex 公布的是 Windows 的临时 IPv6 地址，而 Windows 大约每天会替换一次。请在管理员 PowerShell 中运行 `netsh interface ipv6 set privacy state=disabled` 关闭临时地址，然后重启 rex，让它改用固定地址。该日志行中的 `<IPv4>` 是运营商的共享地址，无法连到 rex，所以你要观看内容的设备也需要支持 IPv6。大多数移动网络都支持 IPv6；如果是只有 IPv4 的酒店或办公室网络，就无法通过这种方式连接 rex。

### Tailscale serve

在 rex 所在的机器和你用来观看的设备上安装 [Tailscale](https://tailscale.com/download)，并登录同一个账号。然后在 rex 所在的机器上执行：

```bash
sudo tailscale serve --bg 32400
```

在 Windows 上，以管理员身份在 PowerShell 中运行，不要加 `sudo`。在 macOS 上，使用 Tailscale 应用的[命令行工具](https://tailscale.com/kb/1080/cli)，同样不要加 `sudo`。

命令会输出一个地址，例如 `https://myhost.tailnet.ts.net`。把它交给 rex，方法是：在 [第 1 步](#step-1-install-rex) 中 rex 的启动命令末尾加上 `--announce-url https://myhost.tailnet.ts.net:443`（注意地址后面要加 `:443`），然后重启 rex。

你 tailnet 里的所有人都可以访问 rex 的 feed API，包括你共享这台机器的人。只和你信任的人共享这台机器。

### Caddy

你需要在路由器上把 443 端口转发到运行 rex 的机器，并为你家的 IP 地址准备一个域名：

- **自己的域名：** 添加一条 `A` 记录，比如 `rex.example.com`，指向你家的 IP。
- **没有域名：** 用你公网 IP 的数字组成 `1-2-3-4.sslip.io`（`curl -s ifconfig.me` 可以显示你的公网 IP）。如果你的 IP 变了，就更新这个域名。

安装 [Caddy](https://caddyserver.com/docs/install)，并把下面这个 Caddyfile 放进去（Linux 软件包使用 `/etc/caddy/Caddyfile`；macOS 和 Windows 上，请在一个单独的文件夹里新建名为 `Caddyfile` 的文件，然后在该文件夹中运行 `caddy run`，它会读取这个文件）：

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` 会让 feed API 不对外网开放，你的应用仍然可以直接访问 rex。然后重新加载 Caddy（Linux 软件包执行 `sudo systemctl reload caddy`）。在 macOS 和 Windows 上，请改为在其文件夹中启动 `caddy run`，并像[步骤 1](#step-1-install-rex) 保持 rex 运行那样让它保持运行；在 Windows 上，还要像步骤 1 为 32400 端口做的那样，在防火墙中放行 TCP 443 端口。最后，在 rex 的启动命令末尾加上 `--announce-url https://rex.example.com:443`，然后重启 rex。

### 小型 VPS {#a-small-vps}

对于完全没有公网 IP 的连接，或者在不支持 IPv6 的网络上观看时，VPS 会承载所有流量，替代 [rex-direct over IPv6](#rex-direct-over-ipv6) 的做法。rex 没有中继，也不会提供中继，所以你租用的服务器要代替路由器：它拥有公网 IP，并通过一条隧道把 rex 所在机器的流量全部转发给 rex。任何带公网 IPv4 的 VPS 都可以，每月几欧元就够。**请选择月流量能覆盖你在外观看用量的套餐：** 每个字节都会经过它，流量上限小的套餐很快就会用完。

你需要 VPS 的 IP（下文用 `1.2.3.4` 表示），它上面要开放端口 443、80 和 7000，还需要一个用于隧道的长随机字符串（`openssl rand -hex 32`）。

**在 VPS 上**，安装 [frp](https://github.com/fatedier/frp/releases)（`frps` 程序）和 [Caddy](https://caddyserver.com/docs/install)。创建 `frps.toml`：

```toml
bindPort = 7000
auth.token = "your-long-random-string"
proxyBindAddr = "127.0.0.1"
```

`proxyBindAddr` 会让隧道的服务端只监听 VPS 的环回地址，因此互联网只能通过 Caddy 访问 rex。创建 `/etc/caddy/Caddyfile`，把 VPS 的 IP 写成 `1-2-3-4.sslip.io`（这是一个免费域名，始终指向该 IP），或者使用你自己指向该 IP 的域名：

```
1-2-3-4.sslip.io {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` 会阻止互联网访问 feed API。将 `frps -c frps.toml` 设置为服务后启动，然后执行 `sudo systemctl reload caddy`。

**在 rex 所在的机器上**，同样安装 frp（`frpc` 程序），并创建 `frpc.toml`：

```toml
serverAddr = "1.2.3.4"
serverPort = 7000
auth.token = "your-long-random-string"

[[proxies]]
name = "rex"
type = "tcp"
localIP = "192.168.1.20"
localPort = 32400
remotePort = 32400
```

把它设置为服务运行：在 Linux 上，例如创建 `~/.config/systemd/user/frpc.service`，其中写入 `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` 和 `Restart=always`；在 macOS 和 Windows 上，则按照 [第 1 步](#step-1-install-rex) 启动 rex 的方式，运行 `frpc -c frpc.toml`。然后在 rex 的启动命令末尾加上 `--announce-url https://1-2-3-4.sslip.io:443`，添加配置键 `REX_DIRECT_URL=off`（在 CGNAT 后面，rex-direct 域名的 IPv4 无法连到 rex，所以 plex.tv 不应该列出它），最后重启 rex。这样，家里的 app.plex.tv 也会改走 VPS；家里其他 Plex 应用仍然直接连接 rex。

### 你应该看到什么 {#what-you-should-see}

```bash
curl -s https://lan.<hash>.rex-direct.debridmediamanager.com:32400/identity
```

会返回一个简短的 XML 页面，里面有 rex 的 `machineIdentifier`，这是在家里电脑上的情况。如果地址或证书不对，`curl` 什么也不显示。请使用你自己的地址：rex 启动时会在日志里打印，例如 `rex-direct: https://lan.<hash>.rex-direct.debridmediamanager.com:32400 -> 192.168.1.20 (LAN)`（如果设置了 `REX_DIRECT_URL=off`，就不会有这一行）。在手机上关掉 Wi-Fi，然后用浏览器打开你的外网地址，并在末尾加上 `/identity`。如果用的是 rex-direct，外网地址就是 rex 日志里另一行 `rex-direct:` 输出的地址。如果用的是 Tailscale serve，地址是 `https://myhost.tailnet.ts.net`，但手机需要开启 Tailscale 才能打开。正常情况下会显示一个简短的 XML 页面，并且没有证书警告。

如果手机打不开，可能的原因有：端口没有转发（或者[通过 IPv6](#rex-direct-over-ipv6) 没有放行）；你的网络位于没有 IPv6 的 CGNAT 后面；rex 只能通过 IPv6 访问，而手机的网络没有 IPv6；或者 rex-direct 的证书还在签发中（这时 rex 的日志会有相应提示）。

rex 的日志会列出它对外宣告的地址：

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex 每次启动都会打印这些。如果之后出现 `heartbeat failed` 或 `announced but NOT visible`，说明有问题。否则服务器会把这些地址列在 plex.tv 上，离家在外的 Plex 应用会选择它能访问的那一个。如果 rex 日志显示 `waiting for a claim`，请先完成[第 3 步](#step-3-add-it-to-a-plex-account)。

## 从另一台 Plex 服务器导入观看记录（可选） {#your-watch-history-from-another-plex-server-optional}

看过别的 Plex 服务器吗？你的媒体库进入 rex 后，[导入观看记录](import-watched.md)可以把你在那边看过的内容、看到的位置和星级评分都复制过来，每个人的记录分别导入。

## 视频转码（可选） {#converting-video-optional}

**功能说明。** 让 rex 像 Plex 一样转换设备无法播放的内容。

**为什么重要。** 没有它的话,设备无法直接播放某个文件时会出现 "This server is not powerful enough to convert video"。网页浏览器最常遇到这个问题,例如 AC3 或 DTS 音轨。如果每个影片在每台设备上都失败,那原因是另外一个,请看[第 5 步](#step-5-watch-something)。

请安装 **jellyfin-ffmpeg** 8,而不是系统自带的 `ffmpeg`。它是 rex 测试时使用的版本,也是唯一能转换所有 Dolby Vision 文件、在显卡上做 HDR 色调映射并在那里绘制字幕的版本。其他 FFmpeg 可以转换普通视频,rex 的日志会说明它缺少什么(Ubuntu 22.04 自带的版本也会出现几秒的跳转偏差)。rex 会自动找到它。

+++ Linux
该软件包会安装到 `/usr/lib/jellyfin-ffmpeg`,与其他 FFmpeg 并存。第一行命令会为你的系统选择对应的版本:提供 Ubuntu 22.04、24.04 和 26.04,以及 Debian 12 和 13 的版本,支持 amd64 或 arm64。其他系统上 `curl` 会报错并停止。

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

在其他 Linux 上,把 jellyfin-ffmpeg 的便携版解压到 `~/rex/ffmpeg`(rex 会在这里查找),然后重启 rex。它使用你系统自带的显卡驱动,所以在较旧的系统上只能用处理器转换。只要有软件包,就优先使用软件包。

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

如果你使用的是 Intel 或 AMD 显卡,还要运行 `sudo usermod -aG render "$USER"`,然后重启,让服务获得该用户组;在 LXC 中,需要把 GPU 直通进去。显卡能让转换变快;没有显卡时 rex 会使用处理器。如果没有 Intel 或 AMD 显卡,rex 还会尝试 NVIDIA 显卡的编码器。在 Intel 平台上,运行 `sudo apt install intel-opencl-icd` 后,显卡也能转换 HDR 和 Dolby Vision。在小型 Intel 设备上,4K 转换速度大约接近实时。没有它的话,这些内容会由处理器转换,而低功耗 Intel 处理器无法实时完成 4K 转换。
+++ macOS
便携版需要放到 `~/rex/ffmpeg`,rex 会在这里查找:

```bash
B=$( [ "$(uname -m)" = arm64 ] && echo macarm64 || echo mac64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
launchctl kickstart -k gui/$(id -u)/com.rex
```

在 Mac 上,rex 始终使用处理器转换,因为它无法使用 Mac 的显卡。
+++ Windows
便携版需要放到 rex 文件夹中的 `ffmpeg` 文件夹里,rex 会在这里查找:

```powershell
cd $HOME\rex
curl.exe -fLO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Expand-Archive jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip ffmpeg
Remove-Item jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex
```

在 Windows 上,如果有 NVIDIA 显卡,rex 会使用其编码器转换;否则使用处理器转换。
+++

**你应该看到什么。** rex 的日志中会有一行 `transcoder:`,说明找到的 FFmpeg 和硬件(`hardware none` 表示使用处理器);启动时如果显示 `transcoder off`,说明没有找到任何 FFmpeg。之前失败的文件现在可以播放了,日志会显示转换的内容,例如 `video=copy h264 audio=ac3->aac`。

关于转换后文件中的字幕:图形字幕会被烧录进画面,你上传的字幕会一起带过来。Plex 的 Android 和 iOS 应用还会把文本字幕保留为一个音轨,其他应用则会把它绘制到画面里。转换后的离线下载仍然不包含文本字幕。

## 字幕 {#subtitles}

**功能说明。** 在 Plex 应用中搜索字幕时，一旦 rex 认领成功，就能从 Plex 自带的提供方找到字幕。rex 会把你选中的字幕和文件对照检查，如果字幕时间偏晚，或者是为其他帧率制作的，它会修正时间轴。当你的 Plex 账户设置为显示字幕，而某个影片没有你所用语言的字幕时，rex 会在播放开始前最多花 3 秒寻找字幕。

**为什么重要。** Plex 自带的第一条搜索结果，往往与文件不同步。

![Plex 应用中的字幕搜索对话框，列出了《Sintel》的英文结果](../assets/rex/51-plex-search-subtitles.webp)

无需任何设置。如果文件自带文本字幕，rex 会用它来检查字幕。没有文本字幕的文件，则会在你按下播放时根据声音进行检查。这需要先设置[视频转换（可选）](#converting-video-optional)，并且会读取文件中六段、每段 90 秒的内容。

**你应该看到什么。** rex 的日志中，每检查一条字幕都会有一行 `SUBTITLE measured`；当它修正了某条字幕时，会出现 `SUBTITLE applied ... corrected by`。

## 电影和剧集功能 {#movie-and-tv-capabilities}

[rex 的安装指南](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities)里有下载、片头和片尾检测、进度条缩略图，以及 rex 提供的其他 Plex 服务器功能和对应设置。音乐和直播电视来自会提供它们的来源（[rex 的限制](https://github.com/debridmediamanager/rex#limits)），比如直播频道可以用 [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports)。没有 DVR，所以不会录制任何内容。照片只能来自会提供图片的来源（[feed API](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#photos)），比如 zurg 提供的漫画。Plex Web 能显示这些照片，但 Plex for Android 不显示照片库。

共享的 debrid 播放请保持默认的代理模式。Real-Debrid 会记录每个下载者的公网 IP。同一账号多个 IP 下载，即使下载成功，也会收到共享警告。TorBox 的下载链接包含完整的 API 密钥，所以如果重定向，每个客户端和共享用户账号都能访问，包括删除文件。在让应用直接从服务商下载之前，请先阅读[重定向风险和设置](direct-download.md#before-you-start)。

## 在 Docker 中运行 rex {#run-rex-in-docker}

这些步骤适用于 Linux 机器。在 macOS 和 Windows 上，Docker Desktop 会把容器运行在虚拟机里，因此 host 网络模式、局域网发现和显卡都无法像在 Linux 上那样工作。这种情况请改用上面的步骤。

新建一个文件夹，比如 `~/rex`，并在里面放一个这样的 `compose.yml`：

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/config
```

- 用的是 Intel 或 AMD 显卡？加上 `devices: ["/dev/dri:/dev/dri"]`，这样 rex 就能用它来转换视频。
- `network_mode: host` 能让你网络里的 Plex 应用自己找到 rex，也能让 rex 以本机的方式访问你的应用所注册的地址。
- `./config` 里会保存 `rex.db`，之后还会有 `claim_state.json`。它们只有 root 用户可以读取，因为 `rex.db` 存着你应用的登录信息。
- 同一台机器上还运行着 Plex Media Server？加上 `command: --port 32500`，然后在所有命令或设置里把 `32400` 都换成 `32500`。

```bash
docker compose up -d
docker compose logs -f rex
```

你应该会看到和[第 1 步](#step-1-install-rex)一样的输出。然后像上面那样做第 2 到第 5 步。如果你的应用也运行在容器里，它必须注册一个机器本身能访问到的地址，而不是只有其他容器能看到的地址。

更新时运行 `docker compose pull && docker compose up -d` 就行。镜像里已经包含 jellyfin-ffmpeg，所以要[转换视频](#converting-video-optional)，只需要把显卡交给容器就好。HTTPS 的配置和上面一样：Tailscale、Caddy 和 frp 都运行在机器本身上，`--announce-url ...` 则写进 compose 文件的 `command:` 里。

## 保持端口私有 {#keep-the-port-private}

rex 的 feed API 不需要密码。它只响应来自本机、家庭网络（10.x、172.16-31.x、192.168.x、169.254.x 以及私有 IPv6 地址）和 Tailscale（100.64-127.x）的请求。对其他所有人，它的表现就像这个 API 不存在一样。因此，为 [rex-direct](#rex-direct) 转发 rex 的端口，或者通过 IPv6 放行它，都不会把它暴露到公网。如果路由器把外部访问者的请求转换成它自己的地址再发给 rex，这些人就会被当成本地访问，feed 也就对互联网开放了。所以你的应用必须从上述网络之一发起推送。在家用路由器后面时，IPv6 地址位于家庭网络范围内的设备也算数，因此解析到 rex IPv6 地址的主机名在家里可以正常使用。在 VPS 上，请用私有网络中的地址来指向 rex。rex 所在机器上的代理对 rex 来说看起来是本地的，所以在任何面向互联网的代理中，都要像 [Caddy](#caddy) 示例那样屏蔽 `/rex/*`。

## 更新 {#updating}

rex 不会自动更新。请再次运行[第 1 步](#step-1-install-rex)中的下载代码块（它会替换程序和 `data/`，并保留 `rex.db`、你的密钥、`claim_state.json` 和 `rex-direct.json`），然后按第 1 步所示重新启动 rex。在 Windows 上，下载代码块之前先运行 `Stop-Process -Name rex`，因为 Windows 不允许替换正在运行的 `rex.exe`；下载之后运行 `Start-ScheduledTask rex`。如果 rex 随后以 `unrecognized arguments` 退出，请从 rex 的启动命令中删除它指出的参数：rex 已不再支持这些参数。

## 之后：恢复、迁移、移除 {#later-restore-move-remove}

### 恢复备份 {#restore-a-backup}

停止 rex，删除旁边的 `rex.db`、`rex.db-wal` 和 `rex.db-shm`，把备份文件放进 rex 的文件夹，然后启动 rex。如果保留旧的 `rex.db-wal`，恢复就会被撤销。

+++ Linux
```bash
systemctl --user stop rex
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
systemctl --user start rex
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
launchctl load ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
```powershell
Stop-Process -Name rex; Start-Sleep 1
Remove-Item $HOME\rex\rex.db*
Copy-Item $HOME\rex-backup\* $HOME\rex
Start-ScheduledTask rex
```
+++ Docker
```bash
cd ~/rex && docker compose down
sudo rm -f config/rex.db config/rex.db-wal config/rex.db-shm
sudo cp ~/rex-backup/rex.db.bak config/rex.db && sudo cp ~/rex-backup/*.json config/
docker compose up -d
```
+++

### 将 rex 迁移到另一台机器 {#move-rex-to-another-machine}

以下是翻译内容：

备份方法与 [第 5 步](#step-5-watch-something) 相同，然后按 [删除 rex](#remove-rex) 第一个代码块的做法，在旧机器上彻底停止 rex。在新机器上执行 [第 1 步](#step-1-install-rex)，但在把 rex 注册为服务之前，先把备份文件复制到 rex 的文件夹中。对你的 Plex 应用来说，这还是同一台服务器，仍然已认领并已共享。然后：

- 按照 [第 4 步](#step-4-connect-your-app) 的做法，把应用改为新机器的局域网 IP。
- 在 rex 在新机器上启动之前，把路由器的端口转发改到新机器，或者更新 IPv6 防火墙规则。rex-direct 域名保持不变，公网 IP 变化后会自动跟随。Tailscale serve 和 Caddy 需要在新机器上重新设置。

### 将 rex 迁移到另一个 Plex 账号 {#move-rex-to-another-plex-account}

如果 rex 所绑定的账号丢失或被封禁，或者你想让 rex 换到另一个账号上，请注册一个全新的账号，停止 rex，删除 rex 文件夹里的 `claim_state.json`，然后启动 rex，重新执行[第 3 步](#step-3-add-it-to-a-plex-account)：先认领，再重新分享给所有人。如果你还能登录旧账号，也请在那里把 rex 移除：打开 app.plex.tv，进入 **Settings**、**Authorized Devices**，按 **Servers** 筛选，然后把 rex 删掉。这两步就是解除认领的全部操作。rex 没有登出功能：Plex 的登出请求（`DELETE /myplex/account`）会返回 200，但 rex 仍然保持认领状态。资料库、Fix Match、编辑内容以及 rex-direct 的名称都会保留，每个人的观看历史会在 rex 重新分享到其账号后恢复。

### 我该运行哪个 rex？ {#which-rex-do-i-run}

rex 没有 version 命令。nightly 的日期写在下载的文件名里（`2026.10.30.0040-nightly`），程序文件的修改时间也是同一个日期：Linux/macOS 用 `ls -l ~/rex/rex`，Windows 用 `(Get-Item $HOME\rex\rex.exe).LastWriteTime`。你的应用里显示的 Plex 版本不是 rex 的版本：rex 特意上报当前 Plex Media Server 的版本，所以应用会把它当作最新版，**Check for Updates** 也总是显示已是最新。

### 移除 rex {#remove-rex}

+++ Linux
```bash
systemctl --user disable --now rex && rm ~/.config/systemd/user/rex.service
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist && rm ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
在管理员身份运行的 PowerShell 中：

```powershell
Unregister-ScheduledTask rex -Confirm:$false; Stop-Process -Name rex
Remove-NetFirewallRule -DisplayName rex, "rex discovery"
```
+++ Docker
```bash
cd ~/rex && docker compose down
```
+++

然后停止你的应用向 rex 推送内容。在 app.plex.tv 中，用新账号打开 **Settings**，进入 **Authorized Devices**，按 **Servers** 筛选，然后移除 rex。删除路由器上的端口转发（或 IPv6 防火墙规则），并删除 rex 的文件夹。

### 获取帮助 {#getting-help}

在 DMM [Discord](https://discord.com/invite/7u4YjMThXP) 的 **rex-support** 论坛提问。[获取帮助](../guides/remote-help.md) 里写了需要附上哪些信息，以及赞助者如何获得远程帮助。

## 出现问题时 {#when-something-is-wrong}

| 现象 | 处理方法 |
|---|---|
| `/rex/sources` 一直是 `{"size":0}` | 你的应用还没有注册。检查它拿到的地址，以及它能否访问 rex 的端口 |
| 推送时返回 `404 no such source` | 你的应用在注册之前就推送了。它必须先 `PUT /rex/sources/<name>` |
| rex 的日志显示 `held ... no media_info yet` | 你的应用发送文件时没有附带 ffprobe 输出。等它收到后，这个问题就会消失 |
| 标题显示文件名，没有海报 | rex 没有加入 Plex 账户。请执行[步骤 3](#step-3-add-it-to-a-plex-account)。如果 rex 是在你的应用发送媒体库之后才被认领的，认领完成后它们会自动显示正确的名称 |
| 某个标题归到了错误的剧集下，或者电影显示的是文件名 | 你的应用没有为它发送 `kind` 和 `ids`，或者发送的值不对。请在你的应用里修正，或者用已登录新账户的 Plex 应用执行 **Fix Match**；Fix Match 的设置会保留 |
| 所有设备上的所有标题都无法播放，常见提示为 "This server is not powerful enough to convert video"，并且你一按播放，rex 的日志就显示 `upstream failed` 或 `502`（如果已经设置了 FFmpeg，则显示 `TRANSCODE ... exited`，并伴有连接被拒绝或超时）| rex 无法通过它注册的地址访问你的应用，而 FFmpeg 解决不了这个问题。运行 `curl -s http://192.168.1.20:32400/rex/sources`，可以看到这个地址就是你应用的 `url`。在 rex 所在的机器上对它运行 `curl -I`：只要返回任何 HTTP 响应（包括 `401`）就没问题；如果显示 `Failed to connect`，说明 rex 在那里无法连接到你的应用。你的应用必须注册一个 rex 所在机器能访问的地址：`172.` 开头的地址是容器自己的，只有同一台 Linux 机器上的 rex 才能访问。较新的版本会直接说明这一点：rex 会记录 `SOURCES <name>: cannot reach ... from this machine` |
| rex 的日志显示 `upstream failed: no source ... configured` | rex 没有收到你的应用的注册信息。让应用重新注册：重启它 |
| rex 的日志显示 `part ... is unavailable upstream` | 你的应用对该文件返回了 404：它现在没有这个文件 |
| 无法播放，出现 401 或 403 | 你的应用拒绝了它自己的登录。让它用当前的登录信息重新注册 |
| 快照返回 409 `would remove more than half` | 这是 rex 的保护机制，用于防止应用发送了一个只加载了一半的媒体库。如果确实需要删除，你的应用必须从第 0 部分开始重新发送整个快照，并在最后一部分加上 `"force": true`。只重发最后一部分会被拒绝；而把它作为一个独立的新快照发送并带上 `force`，会删除之前各部分指定的所有内容 |
| 在 Plex 应用中删除失败，rex 的日志显示 `DELETE refused by the source` | 你的应用不接受对该文件的 `DELETE` 操作。请改为在你的应用中删除 |
| 只有部分文件显示 "This server is not powerful enough to convert video"，通常只在网页浏览器中出现 | 该设备无法直接播放这个文件。可以试试电视或手机上的 Plex 应用，或者设置[视频转码](#converting-video-optional) |
| 杜比视界（Dolby Vision）文件播放失败，rex 的日志显示 `DoVi (Profile 5) color space is not supported` | rex 没有安装 FFmpeg，或者安装的不是 jellyfin-ffmpeg。按照[视频转码](#converting-video-optional)的说明安装 jellyfin-ffmpeg，并在（Settings, Transcoder）中保持 **Enable HDR tone mapping** 为开启 |
| rex 退出，并提示 `cannot bind ...:32400 (another rex or Plex on this port? ...)` | 另一个程序占用了该端口。如果是本机上的 Plex Media Server：按[步骤 1](#step-1-install-rex)的说明使用 `--port 32500`。如果是另一个 rex，比如你手动启动的那个：停止它 |
| 家里的设备无法连接，并且 rex 的 `heartbeat ... ->` 行中没有 `http://192.168.1.20:32400` | rex 会公布它访问互联网所用网络的内网地址；如果你使用了 VPN 或 Tailscale 出口节点，这个地址就不是你家里的网络。请在 rex 的启动命令（[步骤 1](#step-1-install-rex)）末尾加上 `--announce-url http://192.168.1.20:32400`，然后重启 rex |
| 在家里时，app.plex.tv 无法访问 rex，并且[你应该看到的内容](#what-you-should-see)中的 `lan.` 地址也无法响应 | 有些路由器和 DNS 过滤器会屏蔽指向家庭内网地址的公共域名（DNS 重绑定保护）。请在那里允许 `rex-direct.debridmediamanager.com`，就像 Plex 用户需要允许 `plex.direct` 一样 |
| 在 Windows 上，其他机器无法访问 rex，尽管步骤 1 中的防火墙规则已经存在 | 如果你曾在 Windows 询问是否允许 rex 时点击了 **Cancel**，Windows 会保存一条阻止 rex 的规则，而该规则优先于端口规则。请以管理员身份在 PowerShell 中删除它：<code>Get-NetFirewallApplicationFilter -Program "$HOME\rex\rex.exe" &#124; Get-NetFirewallRule &#124; Where-Object Action -eq Block &#124; Remove-NetFirewallRule</code>（如果 rex 放在其他位置，请使用它自己的路径） |
| 出门在外时，rex 不在 Plex 应用中显示 | 未认领，或者该设备无法访问 HTTPS 地址（[rex-direct over IPv6](#rex-direct-over-ipv6) 需要该设备所在网络支持 IPv6） |
| rex 退出，并提示 `argument --announce-url: '...' is not an http:// or https:// address` | `--announce-url` 只需填写地址本身，例如 `https://myhost.tailnet.ts.net:443`：地址外面不要加方括号、引号或链接格式 |
| 你注销登录后 rex 停止运行 | 在 Linux 上，执行 `sudo loginctl enable-linger "$USER"`（见步骤 1）。在 macOS 和 Windows 上，按步骤 1 设置后的 rex 只在你登录期间运行 |
