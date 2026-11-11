# 获取 zurg 和 rex 的帮助 {#getting-help-with-zurg-and-rex}

## 在 Discord 中提问 {#ask-in-discord}

在你所用产品对应的 [Discord](https://discord.com/invite/7u4YjMThXP) 论坛里发帖：**zurg-support**、**rex-support** 或 **dmm-support**。每个问题单独开一个帖子。说明你做了什么、你原本期望什么，以及实际发生了什么。再补充下面的细节。

**对于 zurg**，在 zurg 的仪表盘上点击 **Export Logs**，然后粘贴它给出的链接。它会上传 zurg 的日志和配置，并去掉你的 token、密码和 API 密钥。如果上传失败，可以用 **Download Logs** 下载同样的内容作为文件附上。另外，也请粘贴 `zurg doctor` 的输出。

| zurg 的运行方式 | 运行命令 |
|---|---|
| Linux 或 macOS 上的二进制文件 | 在 zurg 所在文件夹里执行 `./zurg doctor` |
| Windows 上的二进制文件 | 在 zurg 所在文件夹里执行 `.\zurg.exe doctor` |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**对于 rex**，先在失败的那个内容上按一次 Play，然后粘贴 rex 日志的末尾部分。rex 会在日志里屏蔽 Plex token。

| rex 的运行方式 | 运行命令 |
|---|---|
| Linux 上的 systemd 服务 | `journalctl --user -u rex -n 200 --no-pager` |
| macOS 上的 launchd | `tail -n 200 ~/rex/rex.log` |
| Windows 上的任务计划程序 | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| 终端窗口 | 该窗口中的最后 200 行 |

日志很长时，最关键的是错误、警告，以及 rex 对每次播放做出的判断。想只看这些内容，可以在 Linux、macOS 或 Docker 的命令末尾加上 `| grep -E 'ERROR|WARN|upstream|DECISION'`。在 Windows 上则运行 `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50`。

## 赞助者的远程帮助 {#remote-help-for-sponsors}

当一个帖子没能解决问题时，帮手可以在你的终端里输入，而你在旁边看着。**为 zurg 和 rex 提供的远程帮助面向赞助者，且是免费的。**[在 gatekeeper 上成为赞助者](https://gatekeeper.debridmediamanager.com/)。在那里连接 Discord 以获取赞助者角色，然后在你的支持帖子中提问。

本页介绍如何通过 `upterm.debridmediamanager.com` 使用 [upterm](https://github.com/owenthereal/upterm) 进行设置。它适用于 Linux、macOS 和 Windows。

你不需要账户密码，也不需要修改路由器，更不需要事先安装任何东西。这些命令会下载并启动 upterm。请在同一个终端里逐条查看每条命令。输入 `exit` 即可结束会话。

### 1. 选择机器 {#1-pick-the-machine}

在运行 zurg 或 rex 的那台机器上运行 upterm。这可能是一台服务器，而不是你面前的电脑。

| 运行位置 | 该怎么做 |
|---|---|
| 这台电脑 | 在这里打开终端，然后进入第 2 步。 |
| 云服务器，比如 Hetzner、Oracle 或 VPS | 先通过 SSH 连上去。然后在那个 SSH 窗口里使用第 2 步中的 Linux 命令。 |
| 家里的 NAS 或服务器，比如 Synology 或 Unraid | 打开它的终端。然后在那里使用第 2 步中的 Linux 命令。 |
| Docker | 使用运行 Docker 的那台机器，而不是容器。 |

你在 Windows 上也可以使用 SSH。PowerShell 自带 `ssh` 命令。

```bash
ssh you@your-server
```

**Synology** 默认关闭了 SSH。在 Control Panel > Terminal & SNMP > Enable SSH service 里打开它。然后用管理员账户登录。NAS 地址可以在路由器里或 Synology Assistant 里找到。

如果在 Synology 上第 2 步提示 `cannot create directory`，那就在 Control Panel > User & Group > Advanced > Enable user home service 里打开它，然后再运行一次。

**Unraid** 的网页里有终端。点击右上角的 `>_` 图标。

### 2. 开始会话 {#2-start-a-session}

粘贴你在第 1 步选择的系统对应的那一行。

#### Linux 和 macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

打开 PowerShell。不需要以管理员身份运行。

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

如果是 Surface Pro X 这类 ARM 笔记本，请把 `amd64` 替换为 `arm64`。

第一次运行时，upterm 会询问是否信任 `upterm.debridmediamanager.com`。输入 `yes`。它显示的指纹应该是这一个。

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. 把 SSH 命令发给你的帮手 {#3-send-the-ssh-line-to-your-helper}

upterm 会输出几行内容。复制 **SSH** 下面的那一行，它长这样。

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**请通过私信发送。** 千万不要发到公共频道。任何拿到它的人都能在你的电脑上输入命令。

然后保持窗口打开，不要在窗口里点击。在 Windows 上，如果你在 PowerShell 窗口里点击，窗口里正在运行的内容可能会暂停，直到你按下 `Esc`。你的帮手在窗口里输入的每一条内容，你都能实时看到。

### 4. 结束会话 {#4-end-it}

**完成后，在该窗口中输入 `exit`。** 会话随即结束，链接会立即失效。

仅关闭窗口是不够的：会话仍在运行。如果你已经关闭了窗口，请打开一个新终端，运行 `~/upterm/upterm session list`（Windows 上运行 `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`），然后用 `session stop` 加上它显示的名称运行同一个程序。

以后需要再次获取帮助时，再次粘贴第 2 步中的那一行即可。每个会话都会生成一个新的链接。

## 给帮手的说明 {#for-helpers}

运行你收到的 SSH 命令。任何 SSH 密钥都可以用；如果你没有，先运行一次 `ssh-keygen -t ed25519`。之后你就会进入对方的终端：Windows 上是 PowerShell，Linux 和 macOS 上是他们平时用的 shell。

要复制文件，会话 ID 里的 `:` 会让 `scp` 混乱，所以改为把它作为用户名传入：`scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`。

完成后，请对方输入 `exit`。

（之前的译文被退回：代码片段不一致。请保持结构完全不变。）
