# macOS 教程 {#macos-tutorial}

## 一行命令方式 {#one-line-option}

The optional sponsor bootstrap installs macFUSE when needed, downloads the Intel or Apple silicon build, and runs the provider chooser and diagnostics:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

It uses GitHub browser sign-in. macOS may still need approval under **System Settings > Privacy & Security** and a reboot. Existing binaries and configs stay in place. Continue below for the manual route.

## 第 1 步：安装 macFUSE {#step-1-install-macfuse}

macFUSE 可以让 rclone 把 zurg 的虚拟文件系统挂载成你 Mac 上的一个真实目录。

1. 从 [macfuse.io](https://macfuse.io) 下载最新的 `.dmg`
2. 打开 `.dmg` 并运行安装程序
3. 安装过程中，macOS 会阻止系统扩展。前往 **System Settings > Privacy & Security**，向下滚动，然后点击 **Allow**
4. **重启你的 Mac**（内核扩展需要重启后才能加载）

重启后，打开 **Terminal**（按 `Cmd + Space`，输入 "Terminal"，再按回车），检查 macOS 能否加载 macFUSE。这和 `zurg setup` 做的检查是一样的：

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

如果没有出现 `macFUSE is ready`，说明 macOS 还没有允许这个扩展。在 Apple 芯片的 Mac 上，先在恢复模式中启用第三方内核扩展，然后到 **System Settings > Privacy & Security** 中允许 macFUSE，再重启并重新检查一次。

## 第 2 步：下载 zurg {#step-2-download-zurg}

在已登录拥有 zurg 访问权限的 GitHub 账号的浏览器中打开 [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)。选最新的 nightly 版本，就是列表顶部那个 pre-release。下载它的 `darwin-arm64` zip 压缩包；如果你是 Intel 芯片的 Mac，就下载 `darwin-amd64`。不要选 GitHub 标记为 **Latest** 的那个版本，那是 v1.0.0。它比 `zurg setup` 还早，运行时会返回 `unknown command`。

Nightly 版本只面向赞助者。在你的 GitHub 账号获得访问权限之前，这个页面会返回 404。想获得访问权限，可以到 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 赞助。免费公开版是 v1.0.0，来自 [zurg-public](https://github.com/debridmediamanager/zurg-public/releases)。它没有 `zurg setup`，所以请按 [它的 README](https://github.com/debridmediamanager/zurg-public#readme) 里的说明手动设置，而不是照着下面的步骤做。

然后解压。

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

验证：

```bash
./zurg version
```

## 推荐：让 zurg 自动完成设置 {#recommended-let-zurg-finish-the-setup}

从解压后的目录运行：

```bash
./zurg setup
./zurg doctor
```

`setup` 会询问要配置哪些提供商。按优先级顺序选择一个或多个：Real-Debrid、TorBox、AllDebrid、Usenet、Premiumize、Debrid-Link 和 Offcloud。例如输入 `2,4`，表示先配置 TorBox，再配置 Usenet。它只会询问所选服务的凭据，然后创建模式为 `0600` 的 `config.yml`，下载 rclone（如果 PATH 中没有 ffprobe，也会一并下载），准备 `/Volumes/Zurg`，并安装开机自启。

如果当前用户有 GUI launchd 域，它会安装 LaunchAgent。如果是没有登录 GUI 用户的无头 Mac，它会安装系统级 LaunchDaemon，仍以当前用户身份运行 zurg。这种方式不需要开启自动登录。

前置条件检查会区分已安装的 macFUSE 软件包和 macOS 真正能加载的扩展。在 Apple silicon 上，第一次安装 macFUSE 可能还需要在恢复模式中一次性修改安全设置，然后在 **System Settings > Privacy & Security** 中批准，并重启电脑。没有任何安装程序能绕过这些确认步骤。

重复运行 setup 是安全的。它会更新生成的 launchd 服务，但不会替换已有的 `config.yml`。

在通过挂载点串流之前，请打开 `config.yml`，或访问 `http://localhost:9999/config/` 上的 Dashboard，在 `rclone_extra_args` 下设置 `--vfs-cache-max-size` 和 `--vfs-cache-min-free-space`。最大缓存大小要低于当前可用磁盘空间的一半，并用最小可用空间设置至少保留 `20G`。然后运行 `./zurg service restart`。

本页其余部分介绍配置和 Plex 设置。第 3、4、5 和 7 步是手动方式，如果 `zurg setup` 成功，可以跳过。

## 第 3 步：手动配置 zurg {#step-3-configure-zurg-manually}

创建一个配置文件，填入你的 Real-Debrid API token：

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

把占位 token 替换成你从 [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354) 获取的实际 token：

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **别删掉 `mount_path`。** 没有它的话，rclone 在 macOS 上会默认用 `/Volumes/Zurg`，但只有明确设置了 `mount_path`，媒体服务器的扫描功能才会启用。如果漏掉它，Plex 就不会收到刷新通知（见第 6 步）。

> **缓存大小非常关键。** VFS 缓存会把串流文件的数据块存在你的本地硬盘上。如果缓存把硬盘写满，macOS 的性能会严重下降，Spotlight、Plex 甚至系统本身都可能卡死。请务必同时设置**这两个**上限：
>
> - `--vfs-cache-max-size`：缓存总大小的硬上限。把它设置为**不超过可用磁盘空间的 50%**。可以用 `df -h /` 查看。
> - `--vfs-cache-min-free-space`：可用空间低于这个值时就停止缓存。作为安全保险，建议保持在 **20G 或以上**。
>
> 例如，在一块 256GB、剩余 100GB 的硬盘上，就用 `50G` 作为最大缓存，`20G` 作为最小可用空间。

## 第 4 步：手动下载依赖 {#step-4-download-dependencies-manually}

zurg 有一个内置命令，可以下载 rclone 和 ffprobe，并把它们的路径写入 `config.yml`：

```bash
cd ~/zurg
./zurg download-requirements
```

创建挂载点和日志目录。`/Volumes` 归 root 所有，所以 zurg 无法自己创建 `/Volumes/Zurg`。日志目录必须在 Step 7 中 launchd 打开输出文件之前就存在。

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

所有可用选项请参阅[配置参考](../reference/config.md)。启动 zurg 后，也可以打开网页版 Dashboard 修改配置：`http://localhost:9999/config/`。

## 第 5 步：手动测试 zurg {#step-5-test-zurg-manually}

在设置自动启动之前，先确认一切正常：

```bash
cd ~/zurg && ./zurg
```

你应该能看到日志输出，显示 zurg 正在启动、连接到 Real-Debrid，并通过 rclone 挂载。在另一个终端窗口里检查一下：

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

如果一切正常，就按 `Ctrl+C` 停止 zurg。

## 第 6 步：安装 Plex Media Server {#step-6-install-plex-media-server}

1. 从 [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) 下载，选择 **macOS**（Universal）
2. 打开 `.dmg`，把 **Plex Media Server** 拖到 `/Applications`
3. 从“应用程序”里启动 Plex Media Server（或用 Spotlight：按 `Cmd + Space`，然后输入 "Plex Media Server"）
4. 浏览器应该会自动打开 Plex 设置向导，按照提示认领你的服务器
5. **开启自动启动：**右键点击菜单栏里的 Plex 图标，勾选 **Launch at Login**
6. 获取你的 Plex token，最简单的方法是：
   - 在 Plex Web 中打开任意一个媒体项目
   - 点击 **Get Info**（或 **...** → **Get Info**）
   - 点击 **View XML**
   - 在地址栏里找到 `X-Plex-Token=`

编辑 `config.yml`，把 Plex token 加到你的 zurg 配置里：

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## 第 7 步：手动设置 zurg 开机自启 {#step-7-set-up-zurg-auto-start-manually}

macOS LaunchAgents 会在你登录时自动启动服务。Plex 已经自行处理了自动启动（第 6 步），所以我们只需要为 zurg 创建一个 LaunchAgent。

### zurg LaunchAgent

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

关键设置：
- **RunAtLoad** — 登录时自动启动 zurg
- **KeepAlive / SuccessfulExit: false** — 如果 zurg 崩溃，launchd 会自动重新启动它
- **ThrottleInterval: 10** — 两次重启尝试之间等待 10 秒

### 加载 LaunchAgent {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

验证是否已注册：

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## 第 8 步：配置 Plex 媒体库 {#step-8-configure-plex-libraries}

Now que zurg está en marcha y el montaje está activo:

1. Abre [http://localhost:32400/web](http://localhost:32400/web)
2. Ve a **Settings** (icono de llave inglesa) → **Manage** → **Libraries**
3. Haz clic en **Add Library**

**Añade la biblioteca de películas:**
- Type: **Movies**
- Haz clic en **Browse for media folder**
- Navega hasta `/Volumes/Zurg/movies`
- Haz clic en **Add Library**

**Añade la biblioteca de series:**
- Type: **TV Shows**
- Haz clic en **Browse for media folder**
- Navega hasta `/Volumes/Zurg/shows`
- Haz clic en **Add Library**

**Ajustes recomendados de la biblioteca** (en Edit → Advanced de cada biblioteca):
- Desmarca **Empty trash automatically after every scan**: zurg gestiona el ciclo de vida del contenido
- Desmarca **Generate video preview thumbnails**: ahorra ancho de banda, ya que los archivos se transmiten desde Real-Debrid

## 第 9 步：验证一切正常 {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## 第 10 步：启用自动登录（可选） {#step-10-enable-auto-login-optional}

这一步只在手动安装 LaunchAgent 的情况下需要。LaunchAgent 要求每次重启后都有用户登录。内置安装程序在无头 Mac 上使用的是 LaunchDaemon。

如果你确实想在无头服务器上使用手动 LaunchAgent，请开启自动登录，让它无人值守也能启动：

1. 打开 **System Settings**
2. 进入 **Users & Groups**
3. 点击 **Automatic login** 并选择你的用户
4. 输入你的密码

> **安全提示：** 开启自动登录后，任何能物理接触这台 Mac 的人都可以访问你的账户。请只在可信的环境中使用。

---

## 管理服务 {#managing-the-services}

对于由 `zurg setup` 创建的安装，所有平台都使用相同的命令：

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` 只会移除开机自启动，二进制文件、配置、数据、日志和缓存都会保留。下面的 launchctl 命令适用于第 7 步中手动创建的 LaunchAgent（`com.zurg`）。`zurg setup` 创建的是它自己的 `com.zurg.zurg`。

### 启动 / 停止 / 重启 {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### 查看日志 {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### 修改配置后重新加载 {#reload-after-config-change}

如果你编辑 `.plist` 文件：

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

如果你编辑 `config.yml`，只需重启 zurg：

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### 更新 zurg {#update-zurg}

赞助者版本会自我替换:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` 会获取最新的 nightly 版本并下载。然后它检查新的二进制文件报告的版本是否符合预期,之后再通过重命名替换进去,所以正在运行的进程不会被覆盖。如果已安装的版本已经是最新的,它会告诉你并且不做任何改动。

`update` 会用你安装时所用的账号登录 GitHub。安装程序为此把 GitHub CLI 放在 `~/zurg/bin` 里。如果 `update` 说没有找到 GitHub 凭据,那说明你的安装早于这项改动。运行一次安装程序的更新功能,之后每次 `zurg update` 就都能正常工作了。对于太旧、还没有 `zurg update` 的版本,同一条命令也能完成更新。

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

你也可以改为设置 `GITHUB_TOKEN`。请使用来自有 zurg 访问权限的 GitHub 账号、带有 `repo` 范围的经典令牌(classic token)。

如果要手动更新,请从 [发布页面](https://github.com/debridmediamanager/zurg/releases) 下载新的 `darwin-arm64` zip 文件(Intel Mac 则下载 `darwin-amd64`),方法与第 2 步相同,然后:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

请删除旧的二进制文件,而不是直接原地覆盖。直接改写文件会保留相同的 inode,并使其临时代码签名失效,macOS 随后会在执行时直接终止新版本。症状是程序立刻退出,没有任何输出。`zurg update` 正是为了避免这个问题才采用重命名替换的方式。

## 故障排除 {#troubleshooting}

### 挂载时出现 "Operation not permitted" {#operation-not-permitted-when-mounting}

macFUSE 需要在“系统设置”中批准:
1. 打开 **System Settings > Privacy & Security**
2. 向下滚动,找到被阻止的系统扩展提示
3. 点击 **Allow**,然后**重启**

### 挂载显示 "not a directory" 或卡住 {#mount-shows-as-not-a-directory-or-hangs}

挂载点可能是上次崩溃后遗留的残留状态：

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg 不断重启（崩溃循环） {#zurg-keeps-restarting-crash-loop}

检查日志中的错误:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

常见原因:
- `config.yml` 语法无效。可以手动运行 `cd ~/zurg && ./zurg` 来验证。
- Real-Debrid 令牌已过期。请到 [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410) 重新获取一个。
- `/Volumes/Zurg` 不存在,或者不属于你的用户。zurg 无法创建它,并会报 `ensure mount path: permission denied` 错误(见第 4 步)。
- 端口 9999 已被占用。可以用 `lsof -i :9999` 检查。

### macOS 更新后 macFUSE 失效 {#macfuse-breaks-after-macos-update}

大版本的 macOS 更新有时会让内核扩展失效。请重新安装 macFUSE：
1. 从 [macfuse.io](https://macfuse.io) 下载最新版本
2. 安装它
3. 在 **System Settings > Privacy & Security** 中批准该扩展
4. 重启电脑

### 之前一切正常，重启后却停止工作 {#everything-was-working-but-stopped-after-reboot}

```
如果你安装了手动的 LaunchAgent，并且没有开启自动登录，那么必须先登录，它才会启动。你可以选择以下任一方式：
- 开启自动登录（见第 10 步）
- 通过 SSH 连接 —— 用户会话存在后，LaunchAgent 就会自动加载
- 使用 VNC/屏幕共享远程登录
```

Wait, I should output only the translation without code fence. Correcting:

如果你安装了手动的 LaunchAgent，并且没有开启自动登录，那么必须先登录，它才会启动。你可以选择以下任一方式：
- 开启自动登录（见第 10 步）
- 通过 SSH 连接 —— 用户会话存在后，LaunchAgent 就会自动加载
- 使用 VNC/屏幕共享远程登录

通过 `zurg setup` 在无头 Mac 上创建的安装使用的是 LaunchDaemon，不需要图形界面登录。你可以用 `cd ~/zurg && ./zurg service status` 来检查。

还是搞不定？可以到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **zurg-support** 论坛提问。[获取帮助](../../guides/remote-help.md)一文说明了需要提供哪些信息。

## 架构概览 {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## 快速参考 {#quick-reference}

在 `~/zurg` 中运行以下命令。带 `zurg service` 的命令适用于通过 `zurg setup` 安装的版本;手动 LaunchAgent 请使用 [管理服务](#managing-the-services) 中的 launchctl 命令。

| 操作 | 命令 |
|--------|---------|
| 启动 zurg | `./zurg service start` |
| 停止 zurg | `./zurg service stop` |
| 重启 zurg | `./zurg service restart` |
| 检查安装 | `./zurg doctor` |
| 移除自动启动 | `./zurg service uninstall` |
| 查看 zurg 日志 | `tail -f ~/zurg/logs/zurg.log` |
| 查看 rclone 日志 | `tail -f ~/zurg/logs/rclone.log` |
| 检查挂载 | `ls /Volumes/Zurg/` |
| 检查 zurg 运行状态 | `curl http://localhost:9999/http/version.txt` |
| 检查 Plex 运行状态 | `curl http://localhost:32400/identity` |
| 仪表盘 | `open http://localhost:9999/config/` |
| 强制卸载 | `umount -f /Volumes/Zurg` |
