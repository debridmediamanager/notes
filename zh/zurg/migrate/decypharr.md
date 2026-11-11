# 从 decypharr 迁移到 zurg {#migrating-from-decypharr-to-zurg}

先读一下[共享页面](index.md)。它解释了 trash guard 的作用，以及你的库为什么会放进 `__magic__` 里。

decypharr 和 zurg 解决的是同一个问题，它们的根目录结构很接近，所以大部分设置都可以沿用。

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | 一个 `directories:` 条目，带 `not_provider: nzb` |
| `nzbs/<job>/` | 一个 `directories:` 条目，带 `provider: nzb`，或者用内置的 `__nzb__` |

**debrid 这一侧不需要任何改动。** 两个服务器列出的是同样的账号，展示的也都是种子本身的文件名。只要 zurg 挂载在 decypharr 的挂载点上，这些路径就完全一样。下面的内容都是关于 Usenet 那一侧的。

开始之前，有两件事要先确认。

- **Providers。** 它们不会限制迁移。zurg 支持 decypharr 所有的服务。Premiumize 和 Debrid-Link 账号也一样可以迁过来。每个服务都有自己的页面，见 [Providers](../providers/index.md)。
- **迁移前不要改 decypharr 的 `folder_naming`。** 它会一次性重命名库里的每一个文件夹。这样一来，所有符号链接目标和所有 mount-direct 的 Plex 路径都会同时失效。

## Usenet 方面有哪些不同 {#what-differs-on-the-usenet-side}

对比 zurg 处理的同样五个发布版本:

| | |
|---|---|
| zurg 多出的内容 | `thumbnail.jpg`、样片、`.nfo`、`.url` 广告文件、压缩包内的子目录，**还有 decypharr 丢掉的那个混淆过的发布版本** |
| zurg 少掉的内容 | 无 |
| 被重命名的 | 单文件发布版本和压缩包发布版本 |

**单文件发布版本**在 decypharr 里会以任务名来命名。你会得到 `ToyStory5/ToyStory5.mkv`，而 zurg 保留的是发布者取的名字，即 `ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`。

**压缩包发布版本**比较特别，值得了解一下，因为它同时解释了两个现象。这是 decypharr 生成的结果：

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

这是压缩包内子目录名和文件自身名字直接拼在一起、**中间没有任何分隔符**的结果。相当于路径拼接时丢了 `/`。所以缺失的那一层目录和格式错误的文件名其实是同一个问题，而不是两个。zurg 会还原真实结构，输出为 `FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`。

**多文件发布版本和整季合集在两边都保留真实的文件名。** 只要文件夹名匹配，它们就会自动对上。

## 迁移后你的库是什么样子 {#what-your-library-looks-like-afterwards}

**一切都要重新添加**，因为库根目录会移动到 `__magic__`。至于为什么没有更省事的办法，请看[公共页面](index.md)。

好处体现在文件名上。每个单文件发布现在都会以发布者的文件名出现，而不再是任务名。所以 `ToyStory5/ToyStory5.mkv` 会变成 `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`。Sonarr、Radarr 和 Plex 正是靠解析这种字符串来识别画质、来源、发布组和版本的。压缩包类发布不再带着焊死的名字，而是放在压缩包自己的目录里。多文件发布和整季合集本来就能正确识别，不会有变化。

请列出文件名会变化的发布。

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
done
```

!!!info 你会不会看到这些，取决于你的设置
如果 Plex 直接读取挂载目录，那么你的库里变化的就是上面提到的这些名字。这涵盖所有 Windows 设置，以及没有 \*arr 符号链接库的 Linux 或 macOS 设置。

如果 Sonarr 和 Radarr 在整理符号链接库时开启了重命名，那么**你的文件名已经是它们定的了**，Plex 里也不会出现上面说的这些名字。这时文件名能告诉你的，是 \*arr 解析时用的素材有多好。重新导入时这一点很重要。详见[公共页面](index.md)。
!!!

## 新内容会怎样出现 {#what-new-content-shows-up}

- **示例片段**位于 `Sample/` 中。这是最值得配置的部分。如果你不希望 9 MB 的示例片段作为第二个版本出现，请设置 [`only_show_the_biggest_file: true`](../reference/config.md)。
- `thumbnail.jpg`、`.nfo` 以及海报的 `.url` 广告文件。这些都是无作用的。
- decypharr 放出的**混淆发布**会作为新的媒体库条目出现。对于完全以哈希命名的帖子，decypharr 根本没有发布任何内容。zurg 会将其解析为真实的发布名称并提供播放。
- 压缩包链断裂处留下的空文件夹。

## 找回你的 NZB {#get-your-nzbs-back}

**decypharr 无法把它们还给你。** 它为每个任务在 `usenet/meta/<uuid>.meta` 保存一个压缩的二进制文件，还有一个 `usenet/nzbs/` 目录，测试时是空的。没有任何文档记载可以导出。这些 `.meta` 文件能否还原为 NZB 尚未经过验证。请把原始文件当作无法恢复。

你手里有的是任务名称。在两台服务器上，任务文件夹名*就是* NZB 文件名。所以这份文件夹列表就是你的购物清单。

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

对于每个任务，在你的索引站上搜索该文件夹名，重新下载 NZB。然后**把文件重命名为该文件夹名加 `.nzb`**，再放进 zurg 的 `nzbs/` 目录。文件名就是文件夹名，而正是文件夹名让路径保持稳定。

这样做时请遵守两条规则。

- **跳过任何已被 debrid 账户持有的版本。** 符号链接会通过种子副本解析。如果再添加 NZB，zurg 会看到两个不同的版本使用同一个名称，并会给其中一个加上哈希后缀，变成 `Some.Release {a1b2c3}`。这样一来，之前指向无后缀名称的东西就会失效。
- 如果你的索引站已经不再提供某个版本，它就是真的没了。`autoEmptyTrash` 设为 `0` 时，Plex 条目会留在回收站里，直到你决定删除它为止。

## 在旁边搭建 zurg {#build-zurg-alongside}

在 decypharr 旁边单独运行 zurg，并给它一个独立的挂载点。两者可以同时列出同一个 debrid 账户，因为列出操作是只读的。

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30                # your plan's real allowance
retain_rd_torrent_name: false        # align with decypharr's folder_naming
retain_folder_name_extension: false  # true if your folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                         # optional: mirror decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

然后，在继续之前，先检查 debrid 端的文件夹是否对得上。

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

有时候种子文件夹会*系统性地*不一样。比如扩展名有或没有，或者出现的是 RD 重命名后的名字而不是原名。这种情况下，请切换 `retain_rd_torrent_name` 或 `retain_folder_name_extension`，然后重新扫描，而不是手动修改任何东西。只存在于 decypharr 端的文件夹就是 Usenet 任务。Premiumize 和 Debrid-Link 的文件夹名称没有和 decypharr 的进行比较，所以也请在这里检查这些账户的文件夹。

## 切换 {#cut-over}

**1. 打开 `__magic__`**，然后重启。路由是在启动时注册的，所以仪表盘上的开关要重启后，这个命名空间才会响应。

```yaml
magic:
  enabled: true
```

**2. 创建根文件夹。** 它们要放在 `__magic__` 的根目录下，和 zurg 保留在那里的 `__all__` 并排。不要放在 `__magic__/__all__` 里，也不要直接放在 `__magic__` 里，更不要放在挂载根目录下。两个 \*arrs 都会对这些位置报健康检查警告，和它并排的位置则不会触发任何警告。

在 Docker 中，\*arrs 必须通过同一个卷访问 `__all__` 和这些根文件夹。decypharr 的部署常常会分别挂载下载文件夹和媒体文件夹。两个卷会让每次导入都变成一次完整复制。最好只挂载一次 zurg 挂载点的父目录。[教程](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)里有具体演示。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` 镜像了整个资料库，所以在你整理任何内容之前，每个发布都已经在那里了。

**3. 整理。** 在 `__magic__` 里面执行 `mv` 只会写入一条记录，不会移动任何字节。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**如果 Sonarr 和 Radarr 之前整理过你的旧资料库，就用一个脚本把它迁移进来。** 脚本会把旧资料库链接到的每个文件重命名，移动到 `__magic__` 下的一个新根文件夹中。每个文件都会落在 \*arr 已经期望的路径上。整个过程不复制任何东西。然后你切换 \*arr 的根文件夹，同时确保它不会移动任何文件。具体步骤和脚本见[共享页面](index.md#coming-off-a-symlink-library)。千万不要让 \*arr 自己移动文件。那样会跨越挂载边界，变成一次复制，还会把你的资料库整个重新下载一遍。

脚本需要为 decypharr 的链接提供一个 `zurg_path` 函数。把它保存为 `zurg_path.sh`，放在脚本旁边，并把 `OLDMOUNT` 设置为 decypharr 的挂载位置。

```bash
OLDMOUNT=/mnt/decypharr         # decypharr's mount, where the old links point
zurg_path() {
  local rel=${1#"$OLDMOUNT"/__all__/}
  [ "$rel" = "$1" ] && return   # not a link into decypharr
  local job=${rel%%/*} name=${1##*/} f videos
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # decypharr welded an archive's inner folder and file into one name.
  for f in "$ZURG/__all__/$job"/*/*; do
    [ "$(basename "$(dirname "$f")")$(basename "$f")" = "$name" ] && { echo "$f"; return; }
  done
  # decypharr named a lone video after the job. Take the job's one video.
  case "$name" in "$job".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$job" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

指向 debrid 发布或多文件 NZB 发布的链接，在两台服务器上指的是同一个文件。decypharr 对两类 NZB 发布做了重命名：一类是把单个视频以任务名命名，另一类是把压缩包的文件夹和文件拼成了一个名字。该函数会找到 zurg 中这两者的对应副本。如果一个任务里有多个视频，函数不会去猜，而是输出 `NOT IN ZURG`。

**4. 让 Plex 只指向你创建的根文件夹**，也就是 `__magic__/tv` 和 `__magic__/movies`。绝对不要指向 `__magic__` 的根目录，因为那里还包含 `__magic__/__all__` 下的整个资料库。也不要同时指向 `__magic__` 和某个筛选目录，否则每一集都会被找到两次。确认 `autoEmptyTrash` 为 `0`。添加新位置并扫描，然后再移除旧位置。旧位置就是你的 \*arr 资料库路径；如果 Plex 是直接读取的，那就是 decypharr 的挂载点。

**5. 抽查几个条目之后，清空回收站。** 观看状态会通过 GUID 匹配恢复。合集和封面图的选择则不会恢复。

在那之前请保持 decypharr 运行。它不耗费任何资源，也是你的回退方案。同样，不要删除它的配置、`db/` 或 `usenet/` 状态。全部完成后再停止它。

```bash
sudo systemctl stop decypharr
```

## 之后 {#afterwards}

**自动化两边都能延续。** zurg 提供一个可选开启的 [SABnzbd 兼容接口](../guides/sonarr-radarr.md),让 Sonarr 和 Radarr 可以把 NZB 交给它;还有一个可选开启的 [qBittorrent 兼容接口](../guides/sonarr-radarr-torrents.md),让它们可以把磁力链接或 `.torrent` 交给它,由你的 debrid 账户处理。两者都会通过重命名从 `__magic__/__all__` 导入。下面是你的选择。

- **NZB。** 开启 `sabnzbd.enabled`,然后把 \*arr 指向 zurg。zurg 在报告下载完成之前会先检查每一次抓取。它会向新闻服务器询问每个文件开头和结尾的部分。它还会下载每个文件的第一篇文章,最多六十四篇,对于只有几个文件的发布,会再多取几篇。有些新闻服务器在内容被下架后仍然说文章存在,只有实际下载才能发现这一点。zurg 会在可能的情况下,用 PAR2 文件修复缺失了文章的发布。无法修复的会被报告为 **Failed**,\*arr 随后会将其加入黑名单并抓取另一个。这次检查只是抽样,而不是检查整个帖子。如果帖子缺失的部分没有被抽样覆盖到,它仍会报告 Completed,直到读取到缺口处才会失败。
- **种子。** 开启 `qbittorrent.enabled`,并将其添加为第二个下载客户端。当索引器提供的是 `.torrent` 文件而不是裸磁力链接时,私有 tracker 的发布也能正常工作,因为该文件可以直接通过哈希值在账户缓存中查找。
- **手动添加。** zurg 的仪表板没有添加按钮。通过 qBittorrent 接口添加磁力链接或 `.torrent` 时,带上某个 \*arr 的分类,它就会交给那个 \*arr。[手动添加发布](../guides/sonarr-radarr-torrents.md#11-adding-a-release-by-hand)一节说明了具体做法。通过 DMM 添加的磁力链接,以及放入 `nzbs/` 的 NZB,都会在 zurg 中列出,但它们不会自行交给 Sonarr 或 Radarr。zurg 自身的[获取功能](../guides/acquisition.md)也会自动抓取请求。这些请求来自你的 Plex 观看列表以及 Seerr 和 \*arr。当你的账户已经缓存了相应内容时,它会从 Newznab 索引器获取 NZB,从 Torznab 索引器获取种子。
- **混合模式。** 保留 decypharr 只作为 \*arr 的下载客户端,把内容推送到同一批 debrid 账户中,而由 zurg 负责提供挂载。两者列出的是同一个账户,因此 zurg 会识别到 decypharr 添加的内容。此时 \*arr 的导入步骤需要做远程路径映射,指向 zurg 的目录树。该目录树和根文件夹必须位于同一个卷中。建议先用一次抓取做测试。
