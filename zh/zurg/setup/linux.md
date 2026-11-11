# Linux 二进制文件安装 {#linux-binary-setup}

## 一行命令方式 {#one-line-option}

可选的赞助者引导脚本会安装系统软件包、下载适合当前 CPU 的版本，并运行设置与诊断：

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

它通过 GitHub 登录，并安装到 `~/zurg`。已有的二进制文件和配置会保留。如需手动安装或使用自定义路径，请继续往下看。

zurg 二进制文件可以自己完成安装的其余部分。它会写入配置、为当前机器下载正确的 rclone（如果 PATH 中还没有 ffprobe，也会下载 ffprobe），创建挂载点，并注册一个已启用的 systemd 服务。

本流程于 2026 年 9 月 4 日在全新的 Ubuntu 24.04 ARM64 和 x86_64 服务器上验证通过。

## 1. 安装 FUSE 3 {#1-install-fuse-3}

在 Debian、Ubuntu 及其衍生版上:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

其他发行版的软件包也叫 `fuse3`:Fedora 上用 `sudo dnf install fuse3`,Arch 上用 `sudo pacman -S fuse3`,openSUSE 上用 `sudo zypper install fuse3`。

检查辅助程序和设备是否都已就位:

```bash
command -v fusermount3
test -c /dev/fuse
```

如果 Plex、Jellyfin 或其他进程以另一个 Unix 用户身份运行,只需设置一次 `allow_other`:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

不做这个设置,挂载依然能用,但只有运行 zurg 的那个账户能打开它。`zurg doctor` 会把这个差异报告出来。

## 2. 下载 zurg {#2-download-zurg}

从[赞助者版本发布页](https://github.com/debridmediamanager/zurg/releases)下载对应的 Linux 压缩包。Intel 或 AMD 机器选 `linux-amd64`，ARM 机器选 `linux-arm64`。

选最新的每夜构建版，也就是列表顶部的预发布版本。不要选 GitHub 标记为 **Latest** 的那个版本，那是 v1.0.0。它比 `zurg setup` 更旧，运行这个命令会返回 `unknown command`。

每夜构建版只提供给赞助者。在你的 GitHub 账号获得访问权限之前，该页面会返回 404。请在 [gatekeeper](https://gatekeeper.debridmediamanager.com/) 上赞助，以获得访问权限。免费的公开版本是 [zurg-public](https://github.com/debridmediamanager/zurg-public/releases) 上的 v1.0.0。它没有 `zurg setup` 命令。请按照 [其 README](https://github.com/debridmediamanager/zurg-public#readme) 的说明手动设置，不要照着下面的步骤做。

将其解压到应该存放整个安装内容的目录中：

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

zurg 保存的所有内容都放在该二进制文件旁边：`config.yml`、下载的辅助程序、库状态、日志和 rclone 缓存。

## 3. 运行设置 {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

安装程序会询问要配置哪些服务商。选择一个或多个，并按优先级顺序排列：

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

例如输入 `2,4`，表示先用 TorBox，再用 Usenet。安装程序只会询问你所选服务商的凭据。然后它会：

1. 创建并验证 `config.yml`。
2. 将配置文件权限设为 `0600`，只允许所有者访问。
3. 下载原生版 rclone 到 `bin/`。如果 PATH 里还没有 ffprobe，也会一并下载。
4. 在 `/mnt/zurg` 启用 rclone 挂载。
5. 安装并启动一个已启用的 systemd 服务。

如果你没有权限创建 `/mnt/zurg`，可以在主目录里使用挂载点：

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

安装程序可以放心地重复运行。它会更新生成的服务，但不会替换已有的 `config.yml`。

### 选择 systemd 作用域 {#choosing-the-systemd-scope}

在 systemd 用户管理器正常工作时，默认的 `auto` 范围会安装 `~/.config/systemd/user/zurg.service`。否则，setup 会安装 `/etc/systemd/system/zurg.service`，并请求 sudo 以当前用户身份运行它。

需要时可以手动选择：

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

如果希望用户服务在重启后、首次登录之前就启动，请启用 lingering：

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

在服务器上以 `root` 身份运行 setup，会选择由 root 拥有的系统服务。

## 4. 验证安装 {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` 会检查配置及其权限、两个已下载的工具、FUSE、systemd 单元、HTTP 端点，以及 zurg 报告的挂载点。

大型 Real-Debrid 库在首次运行时需要一些时间来建立。服务可能已经处于 active 状态，而第一次的挂载列表还在等待扫描完成。

`version.txt` 在 zurg 运行后就会响应。大型库在此之后仍会继续加载。在加载完成之前，其文件夹会显示为空，或显示为 `Input/output error`。`/ready` 会告诉你加载何时完成。

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## 挂载所用的磁盘 {#disk-the-mount-uses}

挂载点会把它读取过的每个文件缓存到 `~/zurg/data/rclone-cache` 下。播放结束后，整个文件仍然保留在缓存里。放任不管的话，这个缓存会增长到 **256G**，并且一直占着空间。视频停止播放时它也不会被清理。72 小时的过期时间也帮不上忙。只要有人读取文件，rclone 就会把它视为刚被使用，而媒体服务器每晚的维护任务会读取整个媒体库。

先看看缓存里有什么。

```bash
du -sh ~/zurg/data/rclone-cache
```

如果 256G 对磁盘来说太大，就在 `config.yml` 里把上限设得更低。

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

之后重启 zurg。如果想手动清空缓存，先停止 zurg，再运行下面的命令。

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

移动 zurg 目录会让缓存也跟着改名，旧的副本会留在原处。zurg 会在下次启动时回收这些旧副本，并在日志里记录释放了多少空间。详细说明以及如何关闭这个功能，请参阅[配置参考](../reference/config.md#disk-the-mount-uses)。

## 管理 zurg {#managing-zurg}

从 zurg 目录运行以下命令：

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` 只会移除开机自启。二进制文件、配置、数据、日志和缓存都会保留。

查看用户服务的实时日志：

```bash
journalctl --user -u zurg.service -f
```

查看系统服务的实时日志：

```bash
sudo journalctl -u zurg.service -f
```

## 更新 zurg {#updating-zurg}

赞助者版本会自己替换自己：

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` 会获取最新的 nightly 版本。它先下载，检查新二进制文件报告的版本是否符合预期，然后才通过重命名的方式换上去，所以正在运行的进程不会被覆盖。如果已安装的版本已经是最新的，它会提示你并且不做任何更改。

`update` 会使用你安装时所用的 GitHub 账号登录。安装程序为此把 GitHub CLI 保存在 `~/zurg/bin` 中。如果 `update` 提示它找不到 GitHub 凭据，说明你的安装版本早于该变更。运行一次安装程序的 update 功能，之后每次 `zurg update` 都能正常工作。同一个命令也能更新太旧、没有 `zurg update` 的版本。它只替换二进制文件，不会改动其他任何东西。

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

如果服务器上没有 GitHub CLI，可以改为设置 `GITHUB_TOKEN`。请使用来自有 zurg 访问权限的 GitHub 账号、带有 `repo` 范围的 classic token。

## 已有配置和无人值守配置 {#existing-and-unattended-configs}

设置过程绝不会替换已有的 `config.yml`。如果要无人值守地进行设置，请重复使用 `--provider`，并提供对应的 token 文件或 `--nntp-*` 参数。`REALDEBRID_TOKEN`、`TORBOX_TOKEN`、`ALLDEBRID_TOKEN` 和 `NNTP_*` 环境变量同样有效。运行 `./zurg setup --help` 查看完整列表。

所有设置项请参阅[配置参考](../reference/config.md)。

还是搞不定？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **zurg-support** 论坛提问。[获取帮助](../../guides/remote-help.md)里说明了该提供哪些信息。

## 另请参阅 {#see-also}

- [Docker](docker.md) — 容器设置和 FUSE 挂载传播
- [macOS](macos.md) — 使用 macFUSE 和 launchd 的同一个二进制安装程序
- [Windows](windows.md) — 使用 WinFsp 和交互式计划任务的同一个二进制安装程序
