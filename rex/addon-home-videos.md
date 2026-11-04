# Tutorial: a home videos addon

This tutorial builds a complete rex addon in one Python file. It puts a folder of your own videos (phone clips, camcorder files, screen recordings) into a **Home Videos** library in every Plex app, each with a title, a date and a still from the video as its poster. Nothing is copied or uploaded: when someone presses play, rex reads the file from your addon.

It is the shortest working version of [Building rex addons](addons.md), Steps 1 to 5, so read the two side by side: this page says what to type, that one says why. The [music](addon-music.md) and [IPTV](addon-iptv.md) tutorials build on the same skeleton.

| You need | Why |
|---|---|
| rex, set up as in [rex with your own app](any-source.md) (steps 1 to 3) | That is where the library shows up. Claimed, so Plex apps can see it |
| Python 3.8 or newer | The addon. It uses only Python's standard library |
| `ffprobe` and `ffmpeg` | `ffprobe` describes each video for rex, `ffmpeg` cuts the poster still. Both come with FFmpeg |
| A folder of videos, on the machine that runs the addon | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`, in any subfolders |

This page writes rex's address as `192.168.1.20:32400` and runs the addon on the same machine as rex. Put yours in their place.

## Step 1. Save the addon

**What it does.** Gives you the whole addon: a small web server for your videos and a loop that tells rex about them every five minutes.

Save this as `homevideos.py`:

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

## Step 2. Fill in the settings

**What it does.** Points the addon at your folder and your rex.

Change the four lines under the docstring:

| Setting | Put |
|---|---|
| `FOLDER` | Your videos' folder, such as `"/srv/videos/home"`, or `os.path.expanduser("~/Videos/Home")` for one under your home folder |
| `REX` | rex's address, as you open it in step 3 of [rex with your own app](any-source.md) |
| `LISTEN` | Where the addon answers. Keep `127.0.0.1` when the addon runs on rex's machine. On another machine, put that machine's LAN IP (rex reads the videos from it, so it must be reachable from rex) |
| `NAME`, `LIBRARY` | The addon's name in rex and the library's title. Keep `NAME` once you have run it: rex's rows belong to it |

## Step 3. Run it

+++ Linux and macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**What you should see.** The first run probes every video and cuts a still from each, then sends them:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

rex's log shows the source and the new library, then the videos:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Open a Plex app: **Home Videos** is under More (pin it to see it on Home). Each video has its file name as its title, the folder it is in as its summary, the file's date as its release date, and a still from a tenth of the way in as its poster and background. Press play: it plays, and seeking is instant.

Stop the addon with Ctrl+C. Run it again and it sends the same videos as `unchanged` without probing anything: the probes and stills are kept in a `.rex` folder inside your videos' folder.

## Step 4. Keep it running

The addon has to run whenever someone watches: rex reads every video from it.

+++ Linux
Create `~/.config/systemd/user/homevideos.service`, with the folder you saved the addon in:

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

If you ran `sudo loginctl enable-linger "$USER"` for rex, the addon keeps running after you log out too.
+++ macOS and Windows
Start it the way you start rex in step 1 of [rex with your own app](any-source.md#step-1-install-rex): a LaunchAgent on macOS, a scheduled task on Windows, with `python3 homevideos.py` (`python homevideos.py` on Windows) as the command and the addon's folder as the working folder.
+++

## How it works

Each part of the file is one step of [Building rex addons](addons.md):

| Part | Step | What it does |
|---|---|---|
| `Handler` | [1. Serve the bytes](addons.md#step-1-serve-the-bytes) | Answers `GET /home/<file>` with the file, and a `Range` request with just those bytes (`206`), so seeking does not read from the start. `GET /stills/<name>.jpg` serves the posters. Anything outside the folder is a `404` |
| `sync()`, first line | [2. Register](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` with the addon's address and one directory, `home`, as a movie library. Sent every round: registering again changes nothing |
| `describe()` | [3. Describe each video](addons.md#step-3-describe-each-video) | The video's `id` is its path in your folder, so rename a file and it becomes a new title, without its watch history. `kind: "movie"` makes each video a film of its own, so nothing has to be numbered. `media_info` is `ffprobe`'s output, whole |
| `describe()`, `display` | [4. Name and dress it](addons.md#step-4-name-and-dress-it) | Title, summary, date and pictures. The still's URL is under the addon's own address, which is the one place on your network rex fetches pictures from |
| `sync()`, the rest | [5. Send it](addons.md#step-5-send-it) | A snapshot of every video, 200 a request, so a video you delete from the folder leaves the library at the next round |

The guards keep a bad moment from emptying your library: an empty or missing folder sends nothing, a video `ffprobe` cannot read is skipped and logged, and rex itself refuses a snapshot that would remove more than half of the videos.

## Change it

- **Shows instead of films.** Send `"kind": "episode"` with `season` and `episode` numbers and `display.show`, and register the directory as `"shows"`. Number episodes so a new video never shifts the others: by date, not by position in the folder. See [Step 3](addons.md#step-3-describe-each-video).
- **Your own titles.** Read them from a sidecar file or from the video's tags (`media_info["format"]["tags"]`) instead of the file name.
- **Subtitles, collections, chapters.** `.srt` files beside a video, a collection per folder, chapter marks: see [More from your addon](addon-more.md).
- **Let Plex apps delete.** Add a `do_DELETE` that deletes the file and answers `204`. Without it the addon answers `501`, rex keeps the video (its log says `DELETE refused by the source, row kept: home/... at homevideos: 501`), and the app says it could not be deleted.

## Troubleshooting

| You see | Why | Fix |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex is not running, or `REX` is not its address | Start rex, or fix `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | More than half of the videos rex has from this addon are gone from the folder: a disk that is not mounted, a wrong `FOLDER`, or a big clean-up | If you meant it, run once as `REX_FORCE=1 python3 homevideos.py`. Otherwise fix the folder; nothing was removed |
| `no videos found in ...: not sending a snapshot` | The folder is empty, missing or has no video files | Fix `FOLDER` |
| `skipped <file>: ...` | `ffprobe` could not read it (a broken or unfinished file) | It is tried again next round |
| `rejected: {'id': ..., 'reason': ...}` | rex refused one video, and says why | See [Building rex addons, Troubleshooting](addons.md#troubleshooting) |
| The library is there but posters are blank | `ffmpeg` is missing, or rex cannot reach `LISTEN` | Install FFmpeg; with the addon on another machine, set `LISTEN` to that machine's LAN IP, not `127.0.0.1` |
| Playing fails, and rex's log says `PART ... upstream failed: <urlopen error Connection refused ...>` | The addon is not running, or rex cannot reach `LISTEN` | Start the addon. With it on another machine, set `LISTEN` to that machine's LAN IP |

Still stuck? Ask in the **rex-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP).
