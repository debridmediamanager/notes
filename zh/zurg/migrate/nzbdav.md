# 从 nzbdav 迁移到 zurg {#migrating-from-nzbdav-to-zurg}

先阅读[共享页面](index.md)。它解释了垃圾防护（trash guard）的作用，以及为什么你的库会进入 `__magic__`。

nzbdav-dev 的最后一个版本是 2026 年 4 月发布的 v0.6.4，上游仓库已不再维护。
该版本本身是能正常工作的。这次迁移是为了离开不再维护的软件。不需要仓促切换。

**这是五次迁移中最简单的一次。** 以相同的五个资源为基准与 zurg 对比，nzbdav 的文件树只有两处不同。

| | |
|---|---|
| zurg 多出 | 资源中的 `.nfo` 文件 |
| zurg 少了 | 经过混淆的资源里 5 个以哈希命名的 par2 分卷 |

**没有任何文件被重命名。** nzbdav 提供的每个文件名，zurg 都会以相同的名称、放在相同的目录结构中提供。RAR 压缩包内部也是如此。语料中全部 20 个非 par2 文件，两个服务器的结果一致。

!!!warning 永远不要遍历 WebDAV 根目录
nzbdav 的 `.ids` 对象存储会在五个层级的每一层都生成全部 16 个十六进制子目录，与内容无关。也就是 16^5，约 1,048,576 个目录。使用 `find`、`du`、`rclone` 或任何扫描工具时，请明确指定 `/content`、`/nzbs` 或 `/completed-symlinks`。切勿指向 `/`。
!!!

## 迁移后你的库是什么样子 {#what-your-library-looks-like-afterwards}

**Alles wird neu hinzugefügt**, weil der Bibliotheks-Root nach `__magic__` wechselt.
Es gibt keinen günstigeren Weg und keinen Teilweg. Warum, steht [auf der gemeinsamen Seite](index.md).

Die gute Nachricht: Bei nzbdav ist es die eine Migration, bei der **sich nichts außer dem Präfix ändert**. Jeder Dateiname, den zurg ausliefert, ist der, den nzbdav ausgeliefert hat. Ein \*arr, der aus `__magic__` neu importiert, parst genau das, was er vorher geparst hat. Ein Ordner, den du von Hand organisierst, sieht aus wie immer.

Das gilt für jede Einrichtung. Unter Windows und überall sonst, wo Plex den Mount direkt liest, sind die Dateinamen identisch. Wenn Sonarr und Radarr eine Symlink-Bibliothek organisieren, waren die Dateinamen schon ihre eigenen, und die Quelle, die sie parsen, bleibt unverändert. Diese Migration verändert also nichts daran, wie deine Bibliothek gelesen wird. Sie ändert nur, wo sie liegt.

## 新内容会怎样出现 {#what-new-content-shows-up}

- 位于 RAR 发布内的 `.nfo` 文件。
- `Sample/` 目录里的**样本片段**。nzbdav 会同时发布该目录和片段，zurg 也一样。这一点对你来说并不新鲜。四个服务中，只有 nzbdav 之前就已经这样做了。
- 对于压缩包链已损坏的发布，会生成空文件夹。nzbdav 对这些发布什么都不会创建。
- par2 和 sfv 文件不再可见。

除了样本片段之外，这些都不会在 Plex 中生成条目，而样本片段 nzbdav 早就给你了。如果之前这些没有困扰你，那么现在也不会有任何变化。

## 把你的 NZB 拿出来 {#get-your-nzbs-out}

zurg 读取的是一个 `.nzb` 文件目录，而 nzbdav 仍然保存着你所有的文件，位于
`/nzbs/<category>/`。**复制它们，不要移动。** 从 `/nzbs/` 删除会取消任务。

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

两台服务器都会用 NZB *文件名* 来命名发布资源文件夹。所以你找回的文件名主干（stem）应该与 nzbdav 提供的文件夹一致。请检查这一点，并重命名所有不一致的项。

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

有两条 zurg 命名规则值得对照这份列表检查。

- zurg 会去掉文件夹名末尾的 `.mkv` 或 `.mp4`。如果某个 stem 以这种方式结尾，就设置 `retain_folder_name_extension: true`。
- 如果两个不同的发布资源共享同一个 stem，其中一个会被加上 ` {shorthash}` 后缀。现在就用这条命令找出它们：`ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`。

## 在旁边搭建 zurg {#build-zurg-alongside}

nzbdav 会一直保持服务不中断。把它的 provider 配置块复制到 zurg 的配置里。
给 zurg 单独设置一个挂载点。把 NZB 放进监视目录，让它扫描。监视目录大约每 15 秒检查一次。

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from nzbdav's provider settings
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
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l     # should approach your release count
```

## 切换 {#cut-over}

无论你现在用的是哪种方式，只走这一条路径。这里的任何步骤都不会移动文件数据。

**1. 打开 `__magic__`**，然后重启。路由是在启动时注册的，所以仪表盘里的开关需要重启后，命名空间才会响应。

```yaml
magic:
  enabled: true
```

**2. 创建根文件夹。** 它们要放在 `__magic__` 的根目录下，和 zurg 在那里保存的 `__all__` 并排。不要放在 `__magic__/__all__` 里，也不要直接放在 `__magic__` 本身或挂载根目录下。这两个 \*arr 对这些位置都会报健康检查错误；并排放置则不会触发任何报错。

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` 镜像了整个资料库，所以在你整理任何内容之前，每个发布版本都已经在那里了。

**3. 开始整理。** 在 `__magic__` 内部执行 `mv` 只会写一条记录，不会移动任何数据。

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**如果 Sonarr 和 Radarr 是在你的旧资料库上整理的，那就用一个脚本把它搬进来。** 脚本会把旧资料库链接指向的每个文件，重命名到 `__magic__` 下的一个新根文件夹里。每个文件都会落在 \*arr 已经期望的路径上。不会复制任何东西。然后你切换 \*arr 的根文件夹，同时不让它移动任何文件。步骤和脚本在[共享页面](index.md#coming-off-a-symlink-library)上。千万不要让 \*arr 自己移动文件。那样会跨越挂载边界，变成复制，还会把你的资料库重新下载一遍。

脚本需要一个 `zurg_path` 函数来处理 nzbdav 的链接。把它保存为 `zurg_path.sh`，和脚本放在同一目录下，并把 `OLDMOUNT` 设置为 nzbdav 的挂载位置。

```bash
OLDMOUNT=/mnt/nzbdav            # nzbdav's mount, where the old links point
# The map from each .ids name to its release and file. Built once while nzbdav runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # A file under another name. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

nzbdav 的链接指向它自己的 `.ids` 存储，而 zurg 没有这种东西。所以这个函数会先读取一次 nzbdav 的 `completed-symlinks` 目录树，弄清每个 `.ids` 名称对应哪个发布版本和哪个文件。在脚本运行完成之前，请保持 nzbdav 运行。nzbdav 不重命名任何东西，所以它找到的每个名称都是 zurg 能提供的。

**4. 让 Plex 指向你创建的根文件夹**——`__magic__/tv` 和 `__magic__/movies`——并且只指向这些。不要指向 `__magic__` 的根目录，因为那里还有位于 `__magic__/__all__` 的完整资料库；也不要同时指向 `__magic__` *和* 某个过滤目录，否则每一集都会被找到两次。确认 `autoEmptyTrash` 为 `0`。添加新位置并扫描。然后删除旧的位置。旧位置就是你的 \*arr 资料库路径；如果 Plex 是直接读取的，那旧位置就是 nzbdav 的挂载点。

**5. 清空回收站**，前提是你已经抽查过几个条目。观看状态会通过 GUID 匹配恢复。合集和封面图的选择则不会。

在那之前请保持 nzbdav 运行。它不花费任何成本，而且它就是你的回滚方案。全部完成后再停止它。

```bash
sudo systemctl stop nzbdav
```

## 之后 {#afterwards}

在你从一批有代表性的文件中完成串流之前，请保留 nzbdav 的配置目录。它是你 NZB 的唯一另一份副本。

现在来考虑获取。zurg 提供了一个可选的[兼容 SABnzbd 的端点](../guides/sonarr-radarr.md)，Sonarr 和 Radarr 可以通过它抓取内容。它会取代 nzbdav，成为它们的下载客户端。抓取的内容会落到 `__magic__/__all__`，导入时通过重命名将其移出，不会复制任何东西。zurg 在报告抓取完成之前会先检查每个内容。它会向新闻服务器询问每个文件的开头和结尾。它还会下载每个文件的第一篇文章。文件多的话最多可达六十四篇，文件少的发布内容则会再加上几篇。有些新闻服务器在内容已被下架后仍然声称文章存在，只有实际下载才能发现问题。zurg 会在可能的情况下，利用 PAR2 文件修复缺失了文章的发布内容。无法修复的则会被报告为 **Failed**。随后 \*arr 会将其加入黑名单，并抓取另一个版本。这项检查只是抽样，并不是检查整个帖子。如果某个帖子缺失的部分不在抽样范围内，它仍会报告为 Completed，但会在读取到缺口时失败。

请把 \*arr 的根文件夹放在 `__magic__` 里面。如果根文件夹放在其他位置，每次导入都会产生一份完整的副本。在 Docker 中，请只给 \*arr 挂载一个卷，并让它包含 zurg 的整个挂载点。如果下载文件夹和根文件夹分别在两个卷上，每次导入同样会产生副本。请参阅[单一卷](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders)。
