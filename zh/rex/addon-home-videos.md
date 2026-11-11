# 教程：家庭视频插件 {#tutorial-a-home-videos-addon}

本教程用一个 Python 文件构建一个 rex 插件。它会把你的手机短片、摄像机文件或屏幕录像放进每个 Plex 应用里的 **Home Videos** 库。每个视频都会有标题、日期和海报截图。
不会复制或上传任何内容。播放时，rex 通过你的插件读取文件。

这是 [构建 rex 插件](addons.md) 第 1 到 5 步的最简可用版本。本页只说明要输入什么。
原因请看那篇。[音乐](addon-music.md) 和 [IPTV](addon-iptv.md) 教程使用相同的框架。

| 你需要 | 原因 |
|---|---|
| 按 [rex 与你自己的应用](any-source.md)（第 1 到 3 步）设置好的 rex | 库会显示在这里。已认领，Plex 应用才能看到它 |
| Python 3.8 或更新版本 | 插件使用。只用到 Python 的标准库 |
| `ffprobe` 和 `ffmpeg` | `ffprobe` 为 rex 描述每个视频，`ffmpeg` 截取海报截图。两者都随 FFmpeg 一起提供 |
| 一个视频文件夹，位于运行插件的机器上 | `.mp4`、`.mkv`、`.mov`、`.m4v`、`.avi`、`.webm`、`.mts`、`.m2ts`、`.3gp`，可以在任意子文件夹中 |

本页把 rex 的地址写作 `192.168.1.20:32400`，并且插件与 rex 运行在同一台机器上。请换成你自己的地址。

## 第 1 步：保存插件 {#step-1-save-the-addon}

**它的作用。** 给你一整套插件：一个用来提供视频的小型 Web 服务器，以及一个每五分钟把视频信息告诉 rex 的循环任务。

将此内容保存为 `homevideos.py`：

```python
#!/usr/bin/env python3
"""homevideos: a rex addon that puts a folder of home videos into a Plex movie library.

Standard library only; needs ffprobe and ffmpeg on PATH. Edit the four settings below.
"""
import hashlib, json, os, subprocess, sys, threading, time, urllib.error, urllib.parse, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

FOLDER = os.path.expanduser("~/Videos/Home")  # the videos, in any subfolders
REX = "http://192.168.1.20:32400"             # rex's address
LISTEN = ("127.0.0.1", 9981)                  # where this addon answers; rex must reach it
NAME, LIBRARY = "homevideos", "Home Videos"   # the source's name and its library's title

ME = "http://%s:%d" % LISTEN
FORCE = os.environ.get("REX_FORCE") == "1"  # REX_FORCE=1 lets one run remove more than half
VIDEO = {".mp4", ".mkv", ".mov", ".m4v", ".avi", ".webm", ".mts", ".m2ts", ".3gp"}
CACHE = os.path.join(FOLDER, ".rex")          # probes and stills, so a restart redoes nothing
os.makedirs(CACHE, exist_ok=True)
sys.stdout.reconfigure(line_buffering=True)  # log lines appear at once, also under a service


# ---- Step 1: serve the bytes ------------------------------------------------------------
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        rel = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path).lstrip("/")
        if rel.startswith("stills/"):  # pictures for display.thumb, from this addon's own address
            return self.send_file(os.path.join(CACHE, os.path.basename(rel)))
        if not rel.startswith("home/"):
            return self.send_error(404)
        return self.send_file(os.path.join(FOLDER, rel[len("home/"):]))

    def send_file(self, file):
        file = os.path.realpath(file)
        if not file.startswith(os.path.realpath(FOLDER) + os.sep) or not os.path.isfile(file):
            return self.send_error(404)
        size = os.path.getsize(file)
        start, end = 0, size - 1
        ranged = self.headers.get("Range", "").startswith("bytes=")
        if ranged:  # rex seeks with Range: answer 206 with just those bytes
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
                    return  # the player stopped reading: normal
                left -= len(chunk)

    def log_message(self, *args):
        pass


# ---- Step 3: describe each video ---------------------------------------------------------
def cached(key, make):
    """A JSON file per video in .rex/, redone only when the video changes."""
    path = os.path.join(CACHE, key + ".json")
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    value = make()
    with open(path, "w") as f:
        json.dump(value, f)
    return value


def describe(rel):
    file = os.path.join(FOLDER, rel)
    st = os.stat(file)
    key = hashlib.sha1(("%s|%d|%d" % (rel, st.st_size, st.st_mtime)).encode()).hexdigest()[:16]  # changes with the file
    probe = cached(key, lambda: json.loads(subprocess.run(
        ["ffprobe", "-v", "error", "-print_format", "json", "-show_format", "-show_streams", file],
        capture_output=True, check=True).stdout))
    still = os.path.join(CACHE, key + ".jpg")
    if not os.path.exists(still):  # a frame a tenth of the way in, as the poster and background
        at = float(probe["format"].get("duration", 0)) / 10
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", str(at), "-i", file, "-frames:v", "1",
                        "-vf", "scale=1280:-2", still], check=False)
    picture = ME + "/stills/" + key + ".jpg" if os.path.exists(still) else None
    when = time.strftime("%Y-%m-%d", time.localtime(st.st_mtime))
    return {
        "id": rel,                      # for good: rex keeps watch history on it
        "path": "home/" + rel,          # the first segment, home, picks the library
        "kind": "movie",
        "media_info": probe,
        "display": {"title": os.path.splitext(os.path.basename(rel))[0], "date": when,
                    "summary": os.path.dirname(rel), "thumb": picture, "art": picture},
    }


def videos():
    for root, dirs, files in os.walk(FOLDER):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for name in sorted(files):
            if os.path.splitext(name)[1].lower() in VIDEO:
                yield os.path.relpath(os.path.join(root, name), FOLDER).replace(os.sep, "/")


def clean(value):
    """Drops empty fields: rex refuses a field of the wrong type, and null is one."""
    if isinstance(value, dict):
        return {k: clean(v) for k, v in value.items() if v is not None}
    return value


# ---- Steps 2 and 5: register, then send everything --------------------------------------
def rex(method, path, body):
    req = urllib.request.Request(REX + path, json.dumps(body).encode(), method=method,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:  # rex says why in the body
        raise RuntimeError("rex answered %d: %s" % (e.code, e.read().decode(errors="replace")[:300])) from None


def sync():
    rex("PUT", "/rex/sources/" + NAME, {"url": ME, "directories": [{"name": "home", "movies": LIBRARY}]})
    items = []
    for rel in videos():
        try:
            items.append(clean(describe(rel)))
        except Exception as e:  # one bad file must not stop the rest
            print("skipped %s: %s" % (rel, e))
    if not items:
        print("no videos found in %s: not sending a snapshot" % FOLDER)
        return
    session = str(time.time())
    for n in range(0, len(items), 200):
        last = n + 200 >= len(items)
        answer = rex("PUT", "/rex/feed/%s/snapshot" % NAME,
                     {"session": session, "part": n // 200, "complete": last, "force": FORCE, "items": items[n:n + 200]})
        for bad in answer.get("rejected", []):
            print("rejected:", bad)
    print("sent %d videos: %d created, %d updated, %d unchanged" % (len(items), answer["created"], answer["updated"], answer["unchanged"]))


if __name__ == "__main__":
    server = ThreadingHTTPServer(LISTEN, Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print("serving %s at %s" % (FOLDER, ME))
    while True:
        try:
            sync()
        except Exception as e:
            print("sync failed, trying again in 5 minutes:", e)
        time.sleep(300)
```

## 第 2 步：填写设置 {#step-2-fill-in-the-settings}

**它的作用。** 让插件指向你的文件夹和你的 rex。

修改文档字符串下面的四行:

| 设置 | 填写内容 |
|---|---|
| `FOLDER` | 你的视频文件夹,例如 `"/srv/videos/home"`;如果在你的主目录下,可以用 `os.path.expanduser("~/Videos/Home")` |
| `REX` | rex 的地址,就是你在 [用你自己的应用使用 rex](any-source.md) 第 3 步里打开的那个地址 |
| `LISTEN` | 插件响应请求的地址。如果插件和 rex 在同一台机器上,保持 `127.0.0.1` 即可。如果在另一台机器上,填那台机器的局域网 IP(rex 需要从那里读取视频,所以 rex 必须能访问到它) |
| `NAME`、`LIBRARY` | 插件在 rex 里的名字,以及媒体库的标题。运行过一次之后就保持 `NAME` 不变,因为 rex 里的条目都归它所有 |

## 第 3 步：运行 {#step-3-run-it}

+++ Linux 和 macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**你应该看到的效果。** 首次运行时会探测每个视频，并从每个视频中截取一张静帧，然后把它们发送出去：

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

rex 的日志会先显示来源和新建的库，然后列出视频：

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

打开 Plex 应用：**Home Videos** 在 More 下面（固定它就能在首页看到）。每个视频的标题是它的文件名，简介是它所在的文件夹，上映日期是文件的日期，海报和背景图都是取自视频十分之一位置的静帧。点击播放：能正常播放，拖动进度也是即时的。

用 Ctrl+C 停止插件。再次运行时，它会把相同的视频标记为 `unchanged` 发送，而不做任何探测：探测结果和静帧保存在视频所在文件夹里的 `.rex` 文件夹中。

## 第 4 步：保持运行 {#step-4-keep-it-running}

插件需要在有人观看时一直运行，因为 rex 会从它那里读取每个视频。

+++ Linux
在你保存插件的文件夹中，创建 `~/.config/systemd/user/homevideos.service`：

```ini
[Unit]
Description=homevideos rex addon
After=network-online.target

[Service]
WorkingDirectory=%h/rex-addons
ExecStart=/usr/bin/python3 %h/rex-addons/homevideos.py
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now homevideos
journalctl --user -u homevideos -f
```

如果你为 rex 运行过 `sudo loginctl enable-linger "$USER"`，那么你退出登录后，插件也会继续运行。
+++ macOS 和 Windows
按照 [rex with your own app](any-source.md#step-1-install-rex) 第 1 步启动 rex 的方式来启动插件：macOS 用 LaunchAgent，Windows 用计划任务。命令用 `python3 homevideos.py`（Windows 上用 `python homevideos.py`），工作文件夹设为插件所在的文件夹。
+++

## 工作原理 {#how-it-works}

文件的每一部分都是[构建 rex 插件](addons.md)中的一个步骤：

| 部分 | 步骤 | 作用 |
|---|---|---|
| `Handler` | [1. 提供文件内容](addons.md#step-1-serve-the-bytes) | 对 `GET /home/<file>` 返回文件本身；对带 `Range` 的请求只返回那部分字节（`206`），这样拖动进度条时不必从头读取。`GET /stills/<name>.jpg` 提供海报。文件夹之外的任何路径都返回 `404` |
| `sync()`，第一行 | [2. 注册](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos`，带上插件的地址和一个目录 `home`，作为电影库。每轮都会发送：重复注册不会有任何变化 |
| `describe()` | [3. 描述每个视频](addons.md#step-3-describe-each-video) | 视频的 `id` 就是它在你文件夹中的路径，所以重命名文件会变成一个新标题，观看记录也不会跟过来。`kind: "movie"` 会让每个视频都成为独立的电影，因此不需要给它们编号。`media_info` 是 `ffprobe` 的完整输出。 |
| `describe()`，`display` | [4. 命名并美化](addons.md#step-4-name-and-dress-it) | 标题、简介、日期和图片。剧照的 URL 位于插件自己的地址下，这是 rex 在你的网络中唯一获取图片的地方。 |
| `sync()`，其余部分 | [5. 发送](addons.md#step-5-send-it) | 每个视频的快照，每次请求返回 200，因此你从文件夹中删除的视频会在下一轮从库中移除。 |

这些保护措施可以避免糟糕的时刻清空你的库：空的或缺失的文件夹不会发送任何内容；`ffprobe` 无法读取的视频会被跳过并记录日志；rex 本身也会拒绝会移除超过一半视频的快照。

## 修改设置 {#change-it}

- **Serie statt Filme.** Sende `"kind": "episode"` mit den Nummern `season` und `episode` sowie `display.show`, und registriere das Verzeichnis als `"shows"`. Nummeriere die Episoden so, dass ein neues Video die anderen nie verschiebt: nach Datum, nicht nach Position im Ordner. Siehe [Schritt 3](addons.md#step-3-describe-each-video).
- **Eigene Titel.** Lies sie aus einer Sidecar-Datei oder aus den Tags des Videos (`media_info["format"]["tags"]`) statt aus dem Dateinamen.
- **Untertitel, Sammlungen, Kapitel.** `.srt`-Dateien neben einem Video, eine Sammlung pro Ordner, Kapitelmarken: siehe [Mehr aus deinem Addon](addon-more.md).
- **Plex-Apps löschen lassen.** Füge ein `do_DELETE` hinzu, das die Datei löscht und mit `204` antwortet. Ohne das antwortet das Addon mit `501`, rex behält das Video (im Log steht `DELETE refused by the source, row kept: home/... at homevideos: 501`), und die App meldet, dass es nicht gelöscht werden konnte.

## 故障排除 {#troubleshooting}

| 你看到的 | 原因 | 解决办法 |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex 没在运行，或者 `REX` 不是它的地址 | 启动 rex，或修正 `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | rex 里来自这个插件的视频，有一半以上已经不在文件夹里了：可能是磁盘没挂载、`FOLDER` 填错，或者做了大规模清理 | 如果这是你的本意，就执行一次 `REX_FORCE=1 python3 homevideos.py`。否则请修正文件夹；什么都没有被删除 |
| `no videos found in ...: not sending a snapshot` | 文件夹是空的、不存在，或者里面没有视频文件 | 修正 `FOLDER` |
| `skipped <file>: ...` | `ffprobe` 读不了它（文件损坏或者还没下载完） | 下一轮会重新尝试 |
| `rejected: {'id': ..., 'reason': ...}` | rex 拒绝了某个视频，并说明了原因 | 参见 [Building rex addons, Troubleshooting](addons.md#troubleshooting) |
| 媒体库里有内容，但海报是空白的 | 缺少 `ffmpeg`，或者 rex 连不上 `LISTEN` | 安装 FFmpeg；如果插件在另一台机器上，把 `LISTEN` 设为那台机器的局域网 IP，不要用 `127.0.0.1` |
| 播放失败，rex 的日志显示 `PART ... upstream failed: <urlopen error Connection refused ...>` | 插件没有运行，或者 rex 连不上 `LISTEN` | 启动插件。如果它在另一台机器上，把 `LISTEN` 设为那台机器的局域网 IP |

还是解决不了？欢迎到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。
