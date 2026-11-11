# 从 InfiniDysk 迁移到 zurg {#migrating-from-infinidysk-to-zurg}

请先阅读[共享页面](index.md)。它解释了垃圾文件保护（trash guard），以及你的资料库为什么会出现在 `__magic__` 中。

在相同的五个发布资源上与 zurg 对比测得。

| | |
|---|---|
| zurg 多出的内容 | 示例片段、`.nfo` |
| zurg 少了的内容 | 混淆发布资源中 5 个以哈希命名的 par2 卷 |
| 被重命名 | **除多文件发布资源外的所有资源** |

!!!warning 重命名就是迁移的全部内容
只要发布资源解析为单个负载，InfiniDysk 就会把它的媒体文件重命名为 NZB 文件名。在 2026-09-01 的样本库中，五个里有四个变成了 `ToyStory5.mkv`、`Obfuscated.mkv`、`FatherBrown.mp4` 和 `MandaloriaREMUX.mkv`。只有十集的整季包保留了原来的集名。重命名适用于任意目录深度。`FatherBrown.mp4` 位于被保留的 `Father.Brown.2013.S02E05.HDTV.x264-TLA/` 目录*内部*。

zurg 会保留发布者的文件名。因此发布资源名称会回来，每个单负载发布资源的路径都会改变。Plex 和 \*arrs 正是通过这个名称来解析画质、发布组和集数的。
!!!

还有一个差异虽小，但如果你是第一次遇到，会比较困惑。InfiniDysk 会创建压缩包中的 `Sample/` 目录，并将其保留为**空**。zurg 则会把示例片段放进这个目录。

迁移的理由不在于内容。构建版本 `cd9b1205` 导入了参考样本库中的全部五个发布资源，包括整季包。不要指望 InfiniDysk 会丢失任何东西。你会重新得到的是命名方式。

!!!warning 永远不要遍历 WebDAV 根目录
`.ids` 对象存储会在其五个层级的每一层都实体化全部 16 个十六进制子目录，无论里面有什么内容。也就是 16^5，约 1,048,576 个目录。请明确地把 `find`、`du`、`rclone` 以及任何扫描工具指向 `/content`、`/nzbs` 或 `/completed-symlinks`。永远不要指向 `/`。
!!!

## 迁移后你的库是什么样子 {#what-your-library-looks-like-afterwards}

**所有内容都会重新添加**，因为库根目录会移动到 `__magic__`。原因见[共享页面](index.md)，那里说明了为什么没有更省事的办法。

这次迁移花费最少，收获却最多。几乎所有文件名都会变好。`ToyStory5.mkv` 会变成 `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`，从 `__magic__` 重新导入的 \*arr 终于能从文件名里解析出画质、来源、发布组和版本。只有季包保持不变，而它们的名字本来就能正确解析。

列出名字会变的发布内容。大部分都会变。

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

`-maxdepth 4` 很重要，因为重命名可能发生在压缩包目录里面一层。

!!!info 你是否会看到这些，取决于你的设置
如果 Plex 直接读取挂载点，那么你的库里变化的就是上面提到的这些名字。这包括所有 Windows 设置，以及没有 \*arr 符号链接库的 Linux 或 macOS 设置。

如果 Sonarr 和 Radarr 在开启重命名的情况下整理符号链接库，那么**你的文件名已经是它们整理好的样子**，上面这些名字都不会出现在 Plex 里。那时这些名字告诉你的，是 \*arr 解析时用的素材有多好。重新导入时这一点很重要。详见[共享页面](index.md)。
!!!

## 新内容会怎样出现 {#what-new-content-shows-up}

- **Sample clips.** The `Sample/` directories you already have stop being empty. This is the one worth configuring for. Set [`only_show_the_biggest_file: true`](../reference/config.md) if you do not want a 9 MB sample turning up as a second version of the episode.
- The `.nfo` inside RAR releases. Inert under Plex's default agents.
- Empty folders where an archive chain is broken. InfiniDysk created nothing for those.
- **par2 and sfv stop being visible.** That includes the hash-named volumes inside obfuscated releases. They carry no media extension so Plex will not have itemised them. If any non-Plex tooling of yours walked them then it will notice.

## 把你的 NZB 拿出来 {#get-your-nzbs-out}

zurg 的输入来源是一个包含 `.nzb` 文件的目录。每个 release 对应一个文件，文件名与 release 文件夹同名。InfiniDysk 的 WebDAV `/nzbs/<category>/` 会镜像队列，并且可以读取。

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

已完成的任务在完成后是否仍然保留在 `/nzbs` 下，**尚未验证**。它只镜像队列，而你的历史记录可能比队列更久远。对于缺失的部分，InfiniDysk 为重新挂载而保存的 NZB 元数据位于 `{CONFIG_PATH}/blobs/` 中。blob 格式尚未验证，因此在信任它之前请先检查。

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

如果你的安装中 blob 不是纯 XML，那么你的索引器的下载历史就是备用方案。

然后，为你实际拥有的每个 release 文件夹生成一个 `<release>.nzb` 文件。

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

从 `/nzbs/<category>/` 拉取的 NZB 通常已经带有正确的名称，文件夹名就是由此而来的。有两条 zurg 的命名规则值得对照列表检查。

- zurg 会去掉文件夹名末尾的 `.mkv` 或 `.mp4`。如果有 release 文件夹以此结尾，请设置 `retain_folder_name_extension: true`。
- 两个不同的 release 如果同名，其中一个会加上 ` {shorthash}` 后缀。用 `cut -f2 releases.tsv | sort | uniq -d` 找出它们。InfiniDysk 也有同样的问题，只是表现不同：重新导入 NZB 时会生成 `<Release> (2)`。

## 在旁边搭建 zurg {#build-zurg-alongside}

InfiniDysk 在整个过程中都会持续提供服务。

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from InfiniDysk's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
enable_repair: true
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l          # should approach your release count
```

`__all__` 会包含所有版本，不受目录过滤器的影响。

## 切换 {#cut-over}

**1. 打开 `__magic__`**，然后重启。路由是在启动时注册的，所以仪表盘里的开关需要重启后，该命名空间才会响应。

```yaml
magic:
  enabled: true
```

**2. 创建根文件夹。** 它们应放在 `__magic__` 的根目录下，与 zurg 保存在那里的 `__all__` 并列。不要放在 `__magic__/__all__` 里，也不要直接放在 `__magic__` 本身或挂载根目录里。两个 \*arr 都会对这些位置报健康检查错误，并列的位置则两者都不会触发。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` 镜像了整个库，因此在你整理任何内容之前，每个版本都已经存在。

**3. 整理。** 在 `__magic__` 内部执行 `mv` 只会写入一条记录，不会移动任何数据。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**如果 Sonarr 和 Radarr 整理过你原来的库，那就用一个脚本把它搬过来。** 它会把旧库链接指向的每个文件重命名到 `__magic__` 下的一个新根文件夹里，每个文件都落在 \*arr 已经期望的路径上。不会复制任何东西。然后你切换 \*arr 的根文件夹，并确保它不会移动任何文件。具体步骤和脚本见[共享页面](index.md#coming-off-a-symlink-library)。千万不要让 \*arr 自己移动文件，那会跨越挂载边界，变成复制操作，并把你的整个库重新下载一遍。

该脚本需要一个针对 InfiniDysk 链接的 `zurg_path` 函数。把它保存为旁边的 `zurg_path.sh`，并将 `OLDMOUNT` 设置为 InfiniDysk 的挂载位置。

```bash
OLDMOUNT=/mnt/remote/infinidysk # InfiniDysk's mount, where the old links point
# The map from each .ids name to its release and file. Built once while InfiniDysk runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # InfiniDysk named a lone video after the release. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

InfiniDysk 的链接指向它的 `.ids` 存储，而 zurg 没有这种东西。因此该函数会读取一次 InfiniDysk 的 `completed-symlinks` 目录树，以弄清每个 `.ids` 名称对应哪个版本和哪个文件。脚本运行完成前请保持 InfiniDysk 处于运行状态。如果 InfiniDysk 把一个单独的视频命名为版本名，函数会取该版本中 zurg 提供的唯一一个视频。包含多个视频的版本绝不会去猜测，而是输出 `NOT IN ZURG`。

**4. 让 Plex 指向你创建的根文件夹**，即 `__magic__/tv` 和 `__magic__/movies`，而且只指向这两个。不要指向 `__magic__` 的根目录，那里同时也包含 `__magic__/__all__` 下的整个库；也不要同时指向 `__magic__` *和*某个筛选目录，否则每一集都会被找到两次。确认 `autoEmptyTrash` 为 `0`。添加新位置并扫描。然后移除旧位置，也就是你的 \*arr 库路径，或者如果 Plex 是直接读取它的话，就是 InfiniDysk 的挂载点。

**5. 抽查几个项目后清空回收站。** 观看状态会通过 GUID 匹配找回，但合集和封面图的选择不会。

在此之前请保持 InfiniDysk 运行。它不花钱，而且是你的回滚方案。完成后再停止它。

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## 之后 {#afterwards}

请保留 `{CONFIG_PATH}/blobs/` 和你恢复出来的 NZB 集合，直到你用有代表性的样本完成串流测试。

接下来说说获取。zurg 有一个可选开启的[兼容 SABnzbd 的端点](../guides/sonarr-radarr.md)，Sonarr 和 Radarr 可以通过它抓取内容。它取代 InfiniDysk，成为它们的下载客户端。抓取的内容会落到 `__magic__/__all__`，导入时通过重命名把它移出去。不会复制任何东西。
zurg 在报告抓取完成之前会先检查每一个抓取结果。它会向新闻服务器询问每个文件的开头和结尾，还会下载每个文件的第一篇文章。一个文件最多六十四篇，对于只有几个文件的发布，还会多检查几篇。有些新闻服务器在内容被下架后仍然说文章存在，只有真正下载一次才能发现问题。zurg 会尽量用 PAR2 文件重建缺了文章的发布。无法重建的，会报告为 **Failed**。然后 \*arr 会把它加入黑名单，再抓取另一个。
这个检查只是抽样，不是整个帖子。如果某段缺失的内容没有被抽样覆盖到，帖子仍会报告 Completed，但会在读到那个缺口时失败。
请让 \*arr 的根文件夹放在 `__magic__` 里面。根文件夹放在其他任何位置，每次导入都会完整复制一份。在 Docker 中，给 \*arr 只挂载一个卷，这个卷要包含 zurg 的整个挂载内容。如果下载文件夹和根文件夹分放在两个卷上，每次导入也会被复制。详见[同一个卷](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。
