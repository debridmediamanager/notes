# 从 AltMount 迁移到 zurg {#migrating-from-altmount-to-zurg}

请先阅读[共享页面](index.md)。它解释了 trash guard 的作用，以及你的库为什么会落在 `__magic__` 里。

AltMount 输出的目录树是五者中最干净的。每个 release 只有一个文件，没有缩略图、没有广告、没有 sample，也没有残留文件。因此迁移量也相应很小，因为几乎没有需要争论的地方。

以下是与 zurg 对比同样五个 release 的结果。

| | |
|---|---|
| zurg 多出的内容 | sample 片段、`.nfo`、`thumbnail.jpg`、`.url` 广告、压缩包内部的目录，**以及 AltMount 拒绝的每一个 release** |
| zurg 少的内容 | 无 |
| 重命名 | **仅限压缩包（RAR）release** |

!!!info 只有压缩包路径会重命名
在 build `0614008b` 上进行的三次独立运行中，普通单文件 release 都保留了发布者的文件名。其中包括一个内部名称与 NZB 名称不同的 release，以及一个完全混淆命名的 release。只有需要从 RAR 中解压的 release 变成了 `<NZB name>.mp4`。

较早的 AltMount build 重命名的范围比这更大。在信任下面的列表之前，请先检查你自己的目录树。“迁移后你的库是什么样”下面的那条命令，几秒钟就能告诉你结果。
!!!

## 更大的问题是 AltMount 从未导入的内容 {#the-bigger-issue-is-what-altmount-never-imported}

AltMount 在四次运行中都拒绝了一个 10 集的整季合集。开始之前，我们已经确认这些文章在新闻服务器上确实存在。

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

这项检查结果并不稳定。同一个发布，先后出现了 196、93、76 个未验证的分段。它还与文件大小有关：文件越大，结果越差。把 `import.segment_sample_percentage: 1` 设置为 1%，只会抽查 1% 的分段，因此体积更大的发布需要更多次 STAT 请求，才能在截止时间前完成验证。改用*更快*的新闻服务器重复测试，拒绝的数量反而更多。那次运行把整季合集和一个 41 GB 的 remux 都丢掉了。所以问题不在延迟。

这对你的实际影响是：**AltMount 悄悄没有发布的那些内容，正是 zurg 会添加的。** 它们目前在 Plex 里没有对应条目，所以没有任何东西被保留，也没有任何东西处于风险之中，它们只是会出现。如果你的媒体库比 NZB 收藏小，原因就在这里。

如果你想在迁移期间让 AltMount 继续导入，可以试试降低 `segment_sample_percentage`。这一点我们没有在这里测试过。

## 迁移后你的库是什么样子 {#what-your-library-looks-like-afterwards}

**Everything is re-added** because the library root moves to `__magic__`. See
[the shared page](index.md) for why there is no cheaper path.

What changes on the way through is small. Plain single-file releases keep the
filename AltMount gave them so most of the library reads the same. **Archive
releases come back under the poster's name** and one directory deeper. That is
strictly better for an \*arr. The name
`father.brown.2013.s02e05.hdtv.x264-tla.mp4` carries the quality and source and
group that `FatherBrown.mp4` threw away.

Find the archive releases by looking for a mount folder whose single file is
named after the folder.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

!!!info Whether you see any of this depends on your setup
If Plex reads the mount directly then the names above are what changes in your
library. That covers every Windows setup and any Linux or macOS one without an
\*arr symlink farm.

If Sonarr and Radarr organise a symlink library with renaming on then **your
filenames are already theirs** and none of the names above appear in Plex. What
the names tell you then is how good a parse the \*arr was working from. That
matters when you re-import. See [the shared page](index.md).
!!!

## 新内容会怎样出现 {#what-new-content-shows-up}

AltMount 不会发布这些内容，所以共享页面列表中的所有内容都适用于你。

- **样片**，位于 `Sample/` 中。这是唯一值得配置的项。如果你不想让 9 MB 的样片作为第二个版本出现，可以设置 [`only_show_the_biggest_file: true`](../reference/config.md)。
- `thumbnail.jpg`、`.nfo` 和海报的 `.url` 广告文件。这些都没有实际作用。
- **AltMount 拒绝的整个发布资源**却作为新的库条目出现。
- 压缩包链条断裂时留下的空文件夹。

## 把你的 NZB 拿出来 {#get-your-nzbs-out}

AltMount 接管了你提供的每个 NZB。原始文件被移走，压缩副本保存在 `<config>/.nzbs/<category>/<queueID>-<name>.nzbz`。挂载文件夹与 `.nzbz` 之间的对应关系记录在 `<config>/metadata/complete/<Release>/` 下的 `.meta` 文件里。这些是二进制文件，魔数为 `AM3`，`.nzbz` 的路径以普通字符串的形式存放在其中。

zurg 需要每个发布对应一个 `.nzb` 文件，文件名就是发布名，并且直接放在 `nzbs/` 里。子目录会被跳过。`metadata/complete/<Release>` 的目录名*就是*挂载文件夹名，文件也必须用这个名字。

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

在我们实测的 v0.3.2 版本上，`.nzbz` 解压后是导入 NZB 的 gzip 副本。源码里还为这些文件保留了 zstd-protobuf 的读取路径，所以用 `zcat` 和 `grep` 检查一下并不是多此一举。如果某个文件被拒绝，就改走 API。`GET /api/files/export-nzb?path=<virtual path>` 会从存储中重新生成一份完全一致的 NZB，`POST /api/files/export-batch` 则返回一个 ZIP。这两个接口都需要 JWT，而不是 API key。

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

虚拟路径请从 AltMount UI 的文件视图或 `/api/files/info` 获取，不要自己猜格式。下载下来的文件名是 `<queueID>-<name>.nzb`。把它重命名为 `<Release>.nzb`，zurg 才能正确命名文件夹。

最后做一个简单检查：恢复出的 `.nzb` 数量应该等于 `metadata/complete/*/` 目录的数量。

## 在旁边搭建 zurg {#build-zurg-alongside}

AltMount 全程都能正常提供服务。把 zurg 跑在 9999 端口上，和 AltMount 的 8585 端口不会冲突。

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

这里的文件夹会比 AltMount 时**更多**。这就是被拒绝导入的那类内容冒出来了。

## 切换 {#cut-over}

**只走这一条路线，按你现在的情况来。** 这里的步骤都不会移动任何数据。

**1. 开启 `__magic__`**，然后重启。路由在启动时注册，
所以仪表盘里的开关要重启后，该命名空间才会响应。

```yaml
magic:
  enabled: true
```

**2. 创建根文件夹。** 它们放在 `__magic__` 的根目录下，和 zurg 保留在那里的
`__all__` 并排。不要放在 `__magic__/__all__` 里，不要直接放在 `__magic__` 本身，也不要放在挂载根目录。两个 \*arr 都会对这些位置报健康检查警告；并排放置则两者都不会触发。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` 镜像了整个库，所以在整理之前，每个发布都已经在那里了。

**3. 整理。** 在 `__magic__` 内部执行 `mv` 只会写入一条记录，不会移动任何数据。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**如果 Sonarr 和 Radarr 整理过你的旧库，那就用一个脚本把它搬进来。** 它会把旧库链接指向的每个文件，重命名到 `__magic__` 下的一个新根文件夹里。每个文件都会落在 \*arr 已经期望的路径上。不会复制任何东西。然后你切换 \*arr 的根文件夹，并确保它不会移动任何文件。步骤和脚本在[共享页面](index.md#coming-off-a-symlink-library)上。永远不要让 \*arr 自己移动文件。那会跨越挂载边界，变成复制，并且会把你的库重新下载一遍。

脚本需要一个给 AltMount 链接用的 `zurg_path` 函数。把它保存为 `zurg_path.sh`，放在脚本旁边，并把 `OLDMOUNT` 设置为 AltMount 的挂载位置。

```bash
OLDMOUNT=/mnt/altmount          # AltMount's mount, where the old links point
zurg_path() {
  case "$1" in "$OLDMOUNT"/*) ;; *) return ;; esac   # not a link into AltMount
  local name=${1##*/} f videos
  local release; release=$(basename "$(dirname "$1")")
  [ -f "$ZURG/__all__/$release/$name" ] && { echo "$ZURG/__all__/$release/$name"; return; }
  # AltMount named a lone video or an unpacked archive after the release. Take its one video.
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

这个函数期望每个链接目标中，文件正上方那一级就是发布文件夹。本指南没有核实 AltMount 链接使用的确切路径。请先对一个链接运行 `readlink`。如果 AltMount 把单独一个视频或解压后的压缩包以发布名命名，函数会取 zurg 在该发布中提供的那一个视频。包含多个视频的发布永远不会被猜测，而是会打印 `NOT IN ZURG`。

**4. 让 Plex 指向你创建的根文件夹**，也就是 `__magic__/tv` 和 `__magic__/movies`，并且只指向这些。绝不要指向 `__magic__` 的根目录，因为那里还包含位于 `__magic__/__all__` 的整个库；也不要同时指向 `__magic__` 和某个筛选目录，否则每一集都会被找到两次。确认 `autoEmptyTrash` 为 `0`。添加新位置并扫描。然后删除旧位置。旧位置是你 \*arr 的库路径，如果 Plex 是直接读取的，则是 AltMount 的挂载点。

**5. 在抽查几个条目之后，清空回收站。** 观看状态会通过 GUID 匹配找回来。但合集和封面图的选择不会。

在此之前请保持 AltMount 运行。它不花钱，而且是你的回滚方案。全部完成后再停止它。

```bash
sudo systemctl stop altmount
```

## 之后 {#afterwards}

在停用 AltMount 之前，先用有代表性的样本串流测试一下。它的配置目录里保存着 `.nzbz` 存储，这也是你 NZB 的另一份唯一副本。

现在说说获取。zurg 有一个可选开启的 [SABnzbd 兼容接口](../guides/sonarr-radarr.md)，Sonarr 和 Radarr 可以通过它抓取。它会取代 AltMount，作为它们的下载客户端。zurg 在报告抓取完成之前会先检查每次抓取。它会向新闻服务器询问每个文件的开头和结尾是否存在，还会下载每个文件的第一篇文章。文件多时最多会下载六十四篇，只有几个文件的发布则会多下一些。有些新闻服务器即使内容已经被删除，仍然声称文章存在，只有真正下载才能发现问题。zurg 会在可能的情况下，用 PAR2 文件重建缺了文章的发布。无法重建的会被报告为 **Failed**。之后 \*arr 会把它加入黑名单，再去抓取另一个。这次检查只是抽样，并不是检查整个帖子。如果帖子缺失的那一段没有被抽样覆盖到，它仍然会报告 Completed，但在读取到缺口时才会失败。

请把 \*arr 的根文件夹放在 `__magic__` 里面。放在其他任何位置的根文件夹，每次导入都会完整复制一份。在 Docker 中，给 \*arr 只挂载一个卷，让它包含 zurg 的整个挂载内容。如果下载文件夹和根文件夹分别位于两个卷上，每次导入也都会被复制。
参见[单卷设置](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。
