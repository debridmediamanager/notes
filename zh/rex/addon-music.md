# 教程：音乐插件 {#tutorial-a-music-addon}

本教程会把一个专辑文件夹放进 Plexamp、Plex Web 和 Plex for Android 都能播放的 **Music** 库中。
它支持 FLAC、MP3、AAC 以及其他常见格式。你的文件保持原位不动。MusicBrainz 提供已知专辑的详细信息。未知专辑则使用它们的标签和 `cover.jpg`。同目录下的 `.lrc` 文件会变成带时间轴的歌词。

本教程基于 [构建 rex 插件](addons.md) 及其 [音乐](addons.md#music) 部分。如果这是你第一次做插件，请先阅读[家庭视频教程](addon-home-videos.md)。

| 你需要 | 原因 |
|---|---|
| rex 2026.11.02 或更新版本，按照 [rex 与你自己的应用](any-source.md) 中的步骤（第 1 到 3 步）设置，并已认领 | rex 只有在被认领后才会向 Plex 请求专辑名称 |
| Python 3.8 或更新版本 | 插件本身，只使用标准库 |
| `ffprobe` | 为 rex 描述每个文件并读取其标签。它随 FFmpeg 一起提供 |
| 你的专辑，每张专辑一个文件夹 | `Artist/Album/01 Song.flac`，或任意层级：每个包含音频文件的文件夹都视为一张专辑 |
| 标签，或 MusicBrainz Picard | 插件会从每个文件的标签中读取专辑和艺术家（否则从文件夹名称中读取）。已由 [MusicBrainz Picard](https://picard.musicbrainz.org) 打标签的文件已带有其 release id，这是最可靠的匹配方式 |

本页将 rex 的地址写作 `192.168.1.20:32400`，并且在 rex 所在的机器上运行插件。

## 第 1 步：保存插件 {#step-1-save-the-addon}

将以下内容保存为 `music.py`：

```python
#!/usr/bin/env python3
"""music: a rex addon that puts a folder of albums into a Plex music library.

One folder per album (Artist/Album/01 Song.flac, any depth). Standard library only; needs ffprobe
on PATH. Albums are named by MusicBrainz: a file tagged by MusicBrainz Picard already carries its
release id, and any other album is looked up once by its artist, title and number of tracks.
"""
import hashlib, json, os, re, subprocess, sys, threading, time, urllib.error, urllib.parse, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

FOLDER = os.path.expanduser("~/Music")        # the albums
REX = "http://192.168.1.20:32400"             # rex's address
LISTEN = ("127.0.0.1", 9982)                  # where this addon answers; rex must reach it
NAME, LIBRARY = "mymusic", "Music"            # the source's name and its library's title

ME = "http://%s:%d" % LISTEN
FORCE = os.environ.get("REX_FORCE") == "1"  # REX_FORCE=1 lets one run remove more than half
AUDIO = {".flac", ".mp3", ".m4a", ".aac", ".ogg", ".oga", ".opus", ".wav", ".alac", ".aif", ".aiff", ".wma", ".ape", ".wv", ".dsf", ".mka"}
COVERS = ("cover.jpg", "folder.jpg", "front.jpg", "cover.png", "folder.png")
UA = "rex-music-addon/1.0 ( https://notes.debridmediamanager.com/rex/addon-music/ )"  # MusicBrainz asks for one
CACHE = os.path.join(FOLDER, ".rex")
os.makedirs(CACHE, exist_ok=True)
sys.stdout.reconfigure(line_buffering=True)


# ---- Serve the bytes: tracks, lyrics and covers, with Range -------------------------------
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        rel = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path).lstrip("/")
        file = os.path.realpath(os.path.join(FOLDER, rel[len("music/"):])) if rel.startswith("music/") else ""
        if not file.startswith(os.path.realpath(FOLDER) + os.sep) or not os.path.isfile(file):
            return self.send_error(404)
        size = os.path.getsize(file)
        start, end = 0, size - 1
        ranged = self.headers.get("Range", "").startswith("bytes=")
        if ranged:
            a, _, b = self.headers["Range"][6:].split(",")[0].partition("-")
            start, end = (int(a), int(b) if b else size - 1) if a else (size - int(b), size - 1)
            if start >= size:
                self.send_response(416); self.send_header("Content-Range", "bytes */%d" % size); self.end_headers()
                return
            end = min(end, size - 1)
        self.send_response(206 if ranged else 200)
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Content-Length", str(end - start + 1))
        if ranged:
            self.send_header("Content-Range", "bytes %d-%d/%d" % (start, end, size))
        self.end_headers()
        with open(file, "rb") as f:
            f.seek(start)
            left = end - start + 1
            while left > 0:
                chunk = f.read(min(1 << 20, left))
                if not chunk:
                    break
                try:
                    self.wfile.write(chunk)
                except (BrokenPipeError, ConnectionResetError):
                    return
                left -= len(chunk)

    def log_message(self, *args):
        pass


# ---- Describe each track ------------------------------------------------------------------
def probe(file):
    st = os.stat(file)
    key = hashlib.sha1(("%s|%d|%d" % (file, st.st_size, st.st_mtime)).encode()).hexdigest()[:16]
    path = os.path.join(CACHE, key + ".json")
    if not os.path.exists(path):
        out = subprocess.run(["ffprobe", "-v", "error", "-print_format", "json", "-show_format", "-show_streams", file],
                             capture_output=True, check=True).stdout
        with open(path, "wb") as f:
            f.write(out)
    with open(path) as f:
        return json.load(f)


def tags(info):
    """Tags of the file and its audio stream, keys lower-cased without spaces or underscores, so
    FLAC's MUSICBRAINZ_ALBUMID and MP3's "MusicBrainz Album Id" are both musicbrainzalbumid."""
    found = {}
    for source in [info.get("format", {})] + info.get("streams", []):
        for k, v in source.get("tags", {}).items():
            found.setdefault(re.sub(r"[ _]", "", k.lower()), v)
    return found


def number(value):
    m = re.match(r"\s*(\d+)", value or "")
    return int(m.group(1)) if m else None


ALBUMS = os.path.join(CACHE, "albums.json")
known = json.load(open(ALBUMS)) if os.path.exists(ALBUMS) else {}
last_ask = [0.0]


def release_id(artist, album, count):
    """MusicBrainz's release of this album with this many tracks, asked once and kept."""
    key = "%s|%s|%d" % (artist, album, count)
    if key not in known:
        time.sleep(max(0, last_ask[0] + 1.1 - time.time()))  # MusicBrainz takes one request a second
        last_ask[0] = time.time()
        q = 'release:"%s" AND artist:"%s"' % (album.replace('"', ""), artist.replace('"', ""))
        url = "https://musicbrainz.org/ws/2/release?fmt=json&limit=25&query=" + urllib.parse.quote(q)
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=30) as r:
                releases = json.load(r).get("releases", [])
        except Exception as e:
            print("MusicBrainz did not answer for %s - %s (%s): asking again next round" % (artist, album, e))
            return None
        fits = [x for x in releases if x.get("track-count") == count and x.get("status", "Official") == "Official"]
        known[key] = fits[0]["id"] if fits else None
        with open(ALBUMS, "w") as f:
            json.dump(known, f, indent=1)
        print("%s - %s: %s" % (artist, album, known[key] or "not on MusicBrainz with %d tracks" % count))
    return known[key]


def album_items(folder, files):
    infos = [(name, probe(os.path.join(folder, name))) for name in files]
    first = tags(infos[0][1])
    artist = first.get("albumartist") or first.get("artist") or os.path.basename(os.path.dirname(folder))
    album = first.get("album") or os.path.basename(folder)
    mbid = first.get("musicbrainzalbumid") or release_id(artist, album, len(files))
    rel_folder = os.path.relpath(folder, FOLDER).replace(os.sep, "/")
    cover = next((c for c in COVERS if os.path.exists(os.path.join(folder, c))), None)
    items = []
    for n, (name, info) in enumerate(infos, 1):
        t, rel = tags(info), rel_folder + "/" + name
        stem = os.path.splitext(name)[0]
        lyrics = [{"path": "music/%s/%s%s" % (rel_folder, stem, ext), "size": os.path.getsize(os.path.join(folder, stem + ext))}
                  for ext in (".lrc", ".txt") if os.path.exists(os.path.join(folder, stem + ext))]
        item = {
            "id": rel,
            "path": "music/" + rel,
            "kind": "track",
            "disc": number(t.get("disc")) or 1,
            "track": number(t.get("track")) or n,
            "media_info": info,
            "lyrics": lyrics,
            # Shown only if Plex does not know the album: what the tags say.
            "display": {"title": t.get("title") or stem, "artist": {"title": artist},
                        "album": {"title": album, "date": (t.get("date") or "")[:4] or None,
                                  "poster": ME + "/music/" + urllib.parse.quote(rel_folder + "/" + cover) if cover else None}},
        }
        if mbid:
            item["ids"] = {"mbid": mbid}
        items.append(item)
    return items


def albums():
    for root, dirs, files in os.walk(FOLDER):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        tracks = sorted(f for f in files if os.path.splitext(f)[1].lower() in AUDIO)
        if tracks:
            yield root, tracks


def clean(value):
    """Drops empty fields: rex refuses a field of the wrong type, and null is one."""
    if isinstance(value, dict):
        return {k: clean(v) for k, v in value.items() if v is not None}
    return value


# ---- Register, then send everything -------------------------------------------------------
def rex(method, path, body):
    req = urllib.request.Request(REX + path, json.dumps(body).encode(), method=method,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:  # rex says why in the body
        raise RuntimeError("rex answered %d: %s" % (e.code, e.read().decode(errors="replace")[:300])) from None


def sync():
    rex("PUT", "/rex/sources/" + NAME, {"url": ME, "directories": [{"name": "music", "music": LIBRARY}]})
    items = []
    for folder, files in albums():
        try:
            items += [clean(i) for i in album_items(folder, files)]
        except Exception as e:
            print("skipped %s: %s" % (folder, e))
    if not items:
        print("no music found in %s: not sending a snapshot" % FOLDER)
        return
    session = str(time.time())
    for n in range(0, len(items), 200):
        answer = rex("PUT", "/rex/feed/%s/snapshot" % NAME,
                     {"session": session, "part": n // 200, "complete": n + 200 >= len(items), "force": FORCE, "items": items[n:n + 200]})
        for bad in answer.get("rejected", []):
            print("rejected:", bad)
    print("sent %d tracks: %d created, %d updated, %d unchanged" % (len(items), answer["created"], answer["updated"], answer["unchanged"]))


if __name__ == "__main__":
    server = ThreadingHTTPServer(LISTEN, Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print("serving %s at %s" % (FOLDER, ME))
    while True:
        try:
            sync()
        except Exception as e:
            print("sync failed, trying again in 10 minutes:", e)
        time.sleep(600)
```

## 第 2 步：填写设置 {#step-2-fill-in-the-settings}

| 设置 | 填写内容 |
|---|---|
| `FOLDER` | 你的音乐文件夹，例如 `"/srv/music"` 或 `os.path.expanduser("~/Music")` |
| `REX` | rex 的地址 |
| `LISTEN` | 如果插件和 rex 在同一台机器上，保持 `127.0.0.1`；否则填写该机器的局域网 IP |
| `NAME`, `LIBRARY` | 插件在 rex 中的名称，以及音乐库的标题。运行一次后就保持 `NAME` 不变 |

## 第 3 步：运行 {#step-3-run-it}

+++ Linux 和 macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**你应该看到的结果。** 对于标签里没有 release id 的每张专辑，会有一行显示 MusicBrainz 的回复，最后是总数：

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz 每秒只接受一个请求，所以第一次处理大型收藏库会花一些时间：大约每张专辑一秒。每个结果都保存在音乐文件夹里的 `.rex/albums.json` 中，之后的运行就不再查询了。由 Picard 打过标签的专辑则永远不会被查询。

rex 的日志会显示每首曲目归入哪张专辑：

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

打开 Plexamp，选择 rex 的 **Music** 资料库作为它的资料库（Plex Web 和 Plex for Android 在 More 下面可以找到它）。《In Rainbows》会显示 Plex 的封面、曲目名称，以及 Radiohead 的照片和简介，不管你的文件叫什么名字。《Garage Demos》会显示其标签中的名称，以及文件夹里的 `cover.jpg`。如果某首歌旁边有同名的 `.lrc` 文件，播放时会逐行显示它的歌词。

要让它一直运行，可以参照家庭视频插件的设置方法：[第 4 步](addon-home-videos.md#step-4-keep-it-running)，把 `homevideos.py` 换成 `music.py` 即可。

## 工作原理 {#how-it-works}

| 部分 | 作用 |
|---|---|
| `Handler` | 处理 `/music/` 下的所有内容：歌曲（支持 `Range`，所以拖动进度条即时响应）、它们的 `.lrc` 歌词以及专辑封面 |
| `sync()`, first line | 将插件注册为一个名为 `music` 的目录，类型为音乐库：`"directories": [{"name": "music", "music": "Music"}]`。没有音乐库，rex 会拒绝所有曲目 |
| `album_items()` | 每首歌一个条目：`"kind": "track"`，它的 `disc` 和 `track` 编号（来自标签，没有则按其在文件夹中的顺序）、它的 `ffprobe` 输出，以及 `ids.mbid`（专辑的 MusicBrainz release id）。Plex 会在该 release 上按这些编号显示对应的曲目，所以编号必须正确 |
| `release_id()` | 为没有 release id 的专辑查找一个：按专辑名和艺人在 MusicBrainz 搜索，保留第一个官方发行版本，且曲目数与文件夹中的一致。同一张专辑会有很多发行版本（每个国家一个，豪华版等）；只要其中某个版本的曲目与你的相同，就能确定该专辑 |
| `display` | 专辑的名称（来自标签）以及封面；只有当 Plex 不认识该专辑时才显示封面 |
| `lyrics` | 与歌曲同名的 `.lrc`（带时间轴）或 `.txt` 文件，以 `[{"path": ..., "size": ...}]` 的形式发送。只有当文件大小变化时，rex 才会重新读取 |
| `sync()`, the rest | 每个请求 200 首歌，对所有歌曲做一次快照。你删除的专辑会在下一轮（每十分钟）从库中移除 |

rex 自己不读取任何标签。Plex 显示的所有内容都来自 release id；如果 Plex 没有相关信息，则来自你的 `display`。

## 修改设置 {#change-it}

- **另一种布局。** 一张专辑如果被拆成多个碟片文件夹（`CD1/`、`CD2/`），在这个插件眼里就是两张专辑，每张的曲目都太少，无法匹配。请在 `albums()` 中把这些文件夹归为一组，并为它们所有文件只发送一个 `release`；参见 [音乐](addons.md#music)。
- **用歌手自己的照片。** 发送 `display.artist.poster`，并以 `"artwork": "source"` 注册：参见 [你的插件中的更多内容](addon-more.md#artist-pictures)。
- **播放列表。** 发送每首歌在播放列表中的位置，rex 就会生成播放列表：参见 [你的插件中的更多内容](addon-more.md#collections-and-playlists)。
- **响度。** 如果你测量了每首歌的响度，请以 Plex 的命名方式把它作为 `loudness` 发送：参见 [音乐](addons.md#music)。rex 自己不做任何测量。

## 故障排除 {#troubleshooting}

| 你看到的 | 原因 | 解决办法 |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | 没有哪个官方发行版同时匹配该标题和艺术家，并且曲目数与你的一致。可能是缺了一首歌、多了一首附加曲目、标签里有拼写错误，或者 MusicBrainz 没有收录这张专辑 | 修正标签或文件夹，然后从 `.rex/albums.json` 中删除该专辑的那一行（或直接删除整个文件），这样它会被重新查询。也可以用 Picard 给这张专辑打标签 |
| 某张专辑的歌曲名称不对 | 找到的发行版曲目数与你的一致，但曲目顺序不同（是另一个版本） | 用 Picard 给这张专辑打标签，它会写入准确的发行版 |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz 太忙或无法访问 | 什么都不用做：下一轮会再次查询 |
| 尽管 Plex 认识这些专辑，专辑仍显示标签里的名字 | rex 还没有被认领，或者 release id 对应的内容 Plex 不认识 | 认领 rex：[在你自己的应用中添加 rex 的第 3 步](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | 库在某个 Plex 应用中被删除了 | 在 Plex 应用中重新添加：Add Library，Music，然后选择它的文件夹列表中提供的 `music` 文件夹 |
| `sync failed, ...: rex answered 409: ...more than half...` | 文件夹里超过一半的歌曲不见了 | 如果这是你的本意，用 `REX_FORCE=1` 运行一次；否则请修正 `FOLDER` |
| 没有歌词 | `.lrc` 文件的名字和歌曲不一致，或者歌曲是在文件出现之前发送的 | 让文件名和歌曲一致（`01 - Song.flac`、`01 - Song.lrc`）；下一轮会发送它 |

仍然卡住？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。
