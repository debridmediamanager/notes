# 迁移到 zurg {#migrating-to-zurg}

I don't see the page content yet. Please paste the text you want translated, and I'll translate it into Simplified Chinese.

## 简要版 {#the-short-version}

**zurg 发布的媒体文件，包含你要离开的服务器发布的所有文件，而且更多。** 这是在 2026-09-01 测得的。同样的五个发布版本被放进了五台服务器，然后用 `tree` 读回挂载内容。完整对比见[这里](https://github.com/debridmediamanager/usenet-streaming-benchmark)。
zurg 发布得*更少*的只有 par2 奇偶校验文件。Plex 从来不会把它们变成媒体库条目。

所以**你不会丢失内容。** 有些文件会换个文件名出现。这正是本页要解决的问题。Plex 把媒体库条目绑定到文件路径上。文件路径变了，就是一个新条目。

你要付出的代价不是文件，而是**整理好的内容**。

| 会保留 | 随旧条目一起消失 |
|---|---|
| 已观看标记、播放次数、续播位置 | 合集成员关系 |
| 用户评分 | 播放列表条目（它们存的是条目 ID） |
| 文件本身 | 手动选的海报、封面图和手动匹配修正 |
| | `added_at`。你的媒体库会被刷到"最近添加"里 |

观看状态之所以能保留，是因为 `metadata_item_settings` 是按账户和 `plex://` GUID 来索引的，而不是按路径或条目 ID。新条目匹配到同一个 GUID 时，状态就会重新挂上。如果 Plex 对重新添加的条目匹配错了，状态就回不来。第一次扫描完后，抽查几个确认一下。

你可以完全避开这个代价，但要付出别的成本。改写 Plex 数据库里的 `media_parts.file`，让这些记录不会失效。或者搭一个符号链接垫片目录树，在 zurg 的挂载上重建每一条旧路径。两种办法都行得通。但两者都是对一个没有文档的数据库结构动手术，而且这个结构会随 Plex 版本变化。改写做了一半，比它本来要防止的两种结果都更糟。

这些指南选择了简单的路线，并且会明确告诉你它的代价是什么。

## 你的库会落在 `__magic__` 里，而不是符号链接农场 {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

本列表中的每个服务器，都通过一大堆符号链接把库交给 \*arrs。
**zurg 不这么做，你也不该自己去搭一套。** 它改用
[`__magic__`](../guides/magic.md)。这是唯一一个路径是*存储*下来、而不是*计算*出来的目录。
在里面移动一下，只是改写一个小表里的一行，没有字节被搬动，也没有任何东西被复制。
资源仍然留在你账户里的原位。把 Sonarr 和 Radarr 指向它，它们想怎么整理、怎么重命名都行，而且不花任何成本。

这不只是少了一个活动部件。它是一层不会像旧方案那样崩掉的结构。符号链接必须指向一个真实路径，而显而易见的目标是
`__all__/<release>/<file>`，而这个路径是*计算*出来的。资源一改名，它就变；两个资源撞名时，zurg 会给其中一个加上 `{shorthash}` 后缀，它又变一次。每次变化都会悄悄让链接失效。
`__magic__` 的落位是以资源的内容哈希加上文件在其中的路径为键的。所以改名不影响它，`{shorthash}` 后缀不影响它，即使修复时用一个全新的 id 把资源重新添加，它也照样有效。

所以无论你现在用的是什么，**路径会变，库也得重新添加**。这对 \*arr 符号链接库成立，对直接指向旧挂载点的 Plex 也成立。这正是上文所说的代价，也是这里每一次迁移的全部成本。

## 你现在的设置取决于你的平台 {#what-you-have-today-depends-on-your-platform}

这一点决定了下面这些页面中的重命名表格描述的是你的 Plex 媒体库，还是它所基于的源文件。在读这些表格之前，请先把这点弄清楚。

### Linux 和 macOS。你的 \*arrs 已经重命名了所有文件 {#linux-and-macos-your-arrs-already-renamed-everything}

符号链接策略是这里四个服务器的官方推荐设置，而且只在这些平台上可用。服务器会发布 `completed-symlinks/<category>/<release>/<file>.rclonelink`。然后 `rclone mount
--links` 会把每个文件转换成真正的符号链接。最后 **Sonarr 和 Radarr 从这个农场导入，放进它们自己选定路径下的库中。** 挂载点是源，而不是库。

这带来两个结果。

- **Plex 看到的路径是 \*arr 设定的。** 始终如此。依次是根文件夹、剧集文件夹、季文件夹。这些路径里都不包含发布名称。
- **如果你保留了重命名功能，文件名也是 \*arr 设定的。** 也就是 "Rename Episodes" 和 "Rename Movies"。如果关闭重命名，文件名就是源服务器的名称，后面几页的表格正好描述你看到的内容。

所以，如果你开启了 \*arr 的重命名，那么各服务器的重命名表格**并不**描述你的库。它们描述的是 \*arr 在导入时拿到的文件名。这一点仍然重要。源文件名越好，解析就越准确，而你接下来就要重新导入。

### Windows。完全没有符号链接层 {#windows-no-symlink-layer-at-all}

符号链接库需要用到 `rclone mount --links`，而这在 Windows 设置中并不适用。挂载点是通过 WinFsp 生成的一个盘符，Plex 和 \*arrs 直接指向它。因此 **Plex 显示的是服务器自身的文件名**，重命名表正是说明了你会看到哪些变化。[Windows 设置](../setup/windows.md)页面介绍了盘符及其会话规则。

各个服务器页面中的 shell 命令是按 Linux 和 macOS 编写的（在 macOS 上，请把 `/mnt/zurg` 理解为 `/Volumes/Zurg`）。在 Windows 上，请把 `/mnt/zurg` 理解为 `Z:\`，无论你之前用什么方式启动的旧服务器，都要先将其停止。然后使用 [`__magic__` 指南](../guides/magic.md)中的 PowerShell 命令，在 `__magic__` 中创建文件夹和移动文件。

### 从符号链接库迁移 {#coming-off-a-symlink-library}

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never let an \*arr move the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr offer to **move**
the files. Say no. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. So is a move between two volumes of the same
mount. In Docker give the \*arr one volume that holds zurg's whole mount. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Move each file into place yourself instead. Every move is one rename through
zurg's mount. Nothing is copied and nothing on your account changes. The script
below does it from your old library of symlinks. A link's path under the old
root folder is where Sonarr or Radarr expects the episode or film. Its target
names the file. So each file lands at the same path under the new root folder
that its link had under the old one. The old library is only read. It keeps
working until you switch the \*arr over.

1. **Build zurg beside the old server** as its page shows. Let it list the
   whole library first.
2. **Turn on `__magic__`** as its page shows. Keep Plex scans off and the
   \*arr queues paused.
3. **Save the `zurg_path` function from your server's page** as
   `zurg_path.sh` beside the script. It turns an old link's target into the
   file zurg serves. Each server lays its files out differently.
4. **Run the script** once per root folder. Set `OLD` and `NEW` and `LOG` for
   each one. A setup with `sonarr4k` and `radarr4k` beside the regular pair
   needs four runs.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   It prints a line for every link it leaves alone.

   - `NOT IN ZURG` is a link to a file zurg does not have. Its NZB could not be
     recovered or its account is not in zurg's config.
   - `FAILED` is a move zurg refused. A second link to a file the script
     already moved prints this after a line from `mv` that says `No such file
     or directory`. A file can sit at only one path in `__magic__`. It stays
     where the first link put it.
   - `ALREADY THERE` is a path the new root folder already holds. Running the
     script again skips everything it placed before.

5. **Switch each \*arr over.** Select every series or every movie and edit them
   together. Set the root folder to the new one under `__magic__`. When it asks
   whether to move the files answer **No, I'll Move the Files Myself**. The
   script already put them there. Then run **Update All** so it finds them.
6. **Point Plex at the new root folders** and at nothing else. The next box
   says why.

Each move took about 15 milliseconds on a test library and nothing was copied.
Watch `data/local` on zurg's `/magic/` dashboard while the script runs. It
grows only by the subtitles and other small files the script copies. A number
that grows by gigabytes means something is being copied. Stop and look.

The old links keep working. A moved file still shows at its old `__all__` path
as well as at its new one. Builds before the 2026.10.04 nightly hid it at the
old path for up to 12 hours even though zurg still served it there. On one of
those builds restart zurg once the script is done. Keep Plex away from the old
folders and from `__all__` until you have.

The zurg side of this was measured on 2026-10-03. The \*arr side is its
ordinary root folder edit and was not tested for this guide. Do one series
first.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice — and `__magic__`
holds its own `__all__`, so pointing a library at the root of the namespace
scans the whole library along with what you organised. Pick one. If you use the
\*arrs then point Plex at the root folders you made, `__magic__/tv` and
`__magic__/movies`. If you browse a library nobody organises then pick the
filter directories and leave `__magic__` off.
!!!

## 你绝对不能跳过的一道保护 {#the-one-guard-you-must-not-skip}

**在动手之前，先把 `autoEmptyTrash` 设为 `0`。**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

在 Windows 上，用 PowerShell 执行：

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex 中该设置关闭时显示为 `0` 或 `false`。

Plex 的删除是“软删除”。设为 `0` 时，文件已消失的条目会留在回收站里，如果文件又回来了，条目也会恢复。设为 `1` 时，扫描一发现文件缺失，条目就会被永久删除。挂载点在扫描期间断开十秒，整个媒体库就可能一并丢失。以前已经有过这样的情况，丢了几万条目。

在这些简化指南中，这个设置的作用比以前更重要，而不是更少。**回收站是你的旧条目在等待你检查新条目的地方。** 确认一切都正常后再清空它，不要提前。清空回收站才是真正造成损失的那一步，也是这些指南中唯一不可逆的操作。

顺便，请为受影响的媒体库关闭 **"Generate video preview thumbnails"**（生成视频预览缩略图）。在流媒体挂载上，每次生成缩略图都要通过你的 Usenet 或 debrid 额度完整读取一遍资源文件。迁移时，Plex 会一次性收到大量新条目，这会让读取量急剧增加。

## 每次迁移能获得什么 {#what-every-migration-gains}

两个是新文件，会出现在 Plex 已经扫描的文件夹里。它们可能会让你意外，所以最好先了解一下。

- **示例片段。** 在五个工具里，只有 zurg 会把 RAR 发布包里 `Sample/` 目录中的示例文件也放出来。Plex 可能会把一个 9 MB 的 `-sample.mp4` 当成额外内容，或者当成该集的第二个版本。如果你不想这样，就在媒体库扫描的目录上设置 [`only_show_the_biggest_file: true`](../reference/config.md)。
- **`.nfo` 文件。** 只有 zurg 会保留它们。在 Plex 默认的元数据代理下，它们不起作用。如果你使用 XBMC and NFO 代理，它会读取这些文件。
- **`thumbnail.jpg` 和 `.url` 广告文件。** 不起作用。Plex 不会把 `thumbnail.jpg` 当作海报文件名，而 `.url` 文件只是海报网站的广告。
- **空文件夹**，出现在某个发布包的压缩分卷链断开的地方。Plex 会忽略里面没有媒体文件的目录。
- **par2 和 sfv 文件消失了。** zurg 是通过读取文件的实际内容，而不是文件名来识别并隐藏它们的。Plex 从来不会为它们建立条目，所以对你的媒体库来说看不出任何变化。只有会遍历这些文件的工具才会受到影响。

## 指南 {#the-guides}

- [从 AltMount 迁移](altmount.md)。只重命名压缩包类型的发布资源
- [从 decypharr 迁移](decypharr.md)。重命名单文件和压缩包类型的发布资源
- [从 InfiniDysk 迁移](infinidysk.md)。重命名单文件和压缩包类型的发布资源
- [从 nzbdav 迁移](nzbdav.md)。不重命名任何内容，是这五个里最简单的
- [从 streamnzb 迁移](streamnzb.md)。没有需要迁移的媒体库。zurg 自带一个 Stremio 插件

想离开 Plex，而不是迁移到 zurg？[从 Plex 迁移到 rex](../../rex/from-plex.md) 会保留 zurg 和你的 Plex 应用，并让 rex 与你的 Plex 服务器并行运行，或者直接替代它。

每个页面上的命名行为，都是在 2026-09-01 用一个包含五个发布资源的样本集测得的。测试所用的版本分别是：zurg `bda7e3c3`、AltMount `0614008b`、InfiniDysk `cd9b1205`、nzbdav `794948be`、decypharr `0dd1cbbd`。比这些更早或更新的版本，命名方式可能不同。在完全相信重新扫描列表之前，请先用你自己的目录树抽查几个发布资源。
