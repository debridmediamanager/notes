---
label: "Tutorial: music addon"
icon: unmute
order: 68
---

# Tutorial: a music addon

This tutorial puts a folder of albums into a **Music** library that Plexamp Plex Web and Plex for Android play.
It supports FLAC MP3 AAC and other common files. Your files stay where they are. MusicBrainz supplies known
album details. Unknown albums use their tags and `cover.jpg`. A nearby `.lrc` file becomes timed lyrics.

It follows [Building rex addons](addons.md) and its [Music](addons.md#music) section. Read the
[home videos tutorial](addon-home-videos.md) first if this is your first addon.

| You need | Why |
|---|---|
| rex 2026.11.02 or newer, set up as in [rex with your own app](any-source.md) (steps 1 to 3) and claimed | rex asks Plex for the albums' names only once it is claimed |
| Python 3.8 or newer | The addon, standard library only |
| `ffprobe` | Describes each file for rex and reads its tags. It comes with FFmpeg |
| Your albums, one folder per album | `Artist/Album/01 Song.flac`, or any depth: every folder with audio files in it is an album |
| Tags, or MusicBrainz Picard | The addon reads the album and artist from each file's tags (else from the folder names). Files tagged by [MusicBrainz Picard](https://picard.musicbrainz.org) already carry their release id, which is the surest match |

This page writes rex's address as `192.168.1.20:32400` and runs the addon on rex's machine.

## Step 1. Save the addon

Save this as `music.py`:

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

## Step 2. Fill in the settings

| Setting | Put |
|---|---|
| `FOLDER` | Your music folder, such as `"/srv/music"` or `os.path.expanduser("~/Music")` |
| `REX` | rex's address |
| `LISTEN` | Keep `127.0.0.1` with the addon on rex's machine; else that machine's LAN IP |
| `NAME`, `LIBRARY` | The addon's name in rex and the music library's title. Keep `NAME` once you have run it |

## Step 3. Run it

+++ Linux and macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**What you should see.** For each album without a release id in its tags, one line with what MusicBrainz answered, then the total:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz takes one request a second, so the first run over a large collection takes a while: about a second per album. Every answer is kept in `.rex/albums.json` in your music folder, and the next runs ask nothing. Albums tagged by Picard are never looked up.

rex's log shows each track arriving on its album:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Open Plexamp and pick rex's **Music** library as its library (Plex Web and Plex for Android list it under More). In Rainbows has Plex's cover, its track names and Radiohead's photo and biography, whatever your files are called. Garage Demos shows its tags' names and its folder's `cover.jpg`. A song with a `.lrc` file of the same name shows its lyrics, line by line as it plays.

To keep it running, set it up like the home videos addon: [Step 4](addon-home-videos.md#step-4-keep-it-running), with `music.py` in place of `homevideos.py`.

## How it works

| Part | What it does |
|---|---|
| `Handler` | Serves everything under `/music/`: the songs (with `Range`, so seeking is instant), their `.lrc` lyrics and the album covers |
| `sync()`, first line | Registers the addon with one directory, `music`, as a music library: `"directories": [{"name": "music", "music": "Music"}]`. Without a music library rex refuses every track |
| `album_items()` | One item per song: `"kind": "track"`, its `disc` and `track` numbers (from its tags, else its place in the folder), its `ffprobe` output, and `ids.mbid`, the album's MusicBrainz release id. Plex shows its own track at those numbers on that release, so the numbers must be right |
| `release_id()` | Finds the release id for an album without one: a MusicBrainz search by album and artist, keeping the first official release with as many tracks as the folder holds. An album comes out in many releases (one per country, deluxe editions); any one with your tracks names the album |
| `display` | The album's names from the tags, and its cover, shown only when Plex does not know the album |
| `lyrics` | A `.lrc` (timed) or `.txt` file with the song's name beside it, sent as `[{"path": ..., "size": ...}]`. rex reads it again only when its size changes |
| `sync()`, the rest | A snapshot of every song, 200 a request: an album you delete leaves the library at the next round (every ten minutes) |

rex reads no tags itself. Everything Plex shows comes from the release id, or from your `display` when Plex has none.

## Change it

- **Another layout.** An album split into disc folders (`CD1/`, `CD2/`) is two albums to this addon, each with too few tracks to match. Group such folders in `albums()` and send one `release` for all their files; see [Music](addons.md#music).
- **Artists by their own pictures.** Send `display.artist.poster` and register with `"artwork": "source"`: see [More from your addon](addon-more.md#artist-pictures).
- **Playlists.** Send each song's place in a playlist and rex makes the playlist: see [More from your addon](addon-more.md#collections-and-playlists).
- **Loudness.** If you measure each song's loudness, send it as `loudness` in Plex's names: see [Music](addons.md#music). rex measures nothing itself.

## Troubleshooting

| You see | Why | Fix |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | No official release of that title and artist has your number of tracks: a missing song, a bonus track, a typo in the tags, or an album MusicBrainz does not list | Fix the tags or the folder, then delete that album's line from `.rex/albums.json` (or the whole file) so it is asked again. Or tag the album with Picard |
| An album shows the wrong song names | The release found has your number of tracks in another order (a different edition) | Tag the album with Picard, which writes the exact release |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz was busy or unreachable | Nothing: the next round asks again |
| Albums show their tags' names although Plex knows them | rex is not claimed, or the release id names nothing Plex knows | Claim rex: [step 3 of rex with your own app](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | The library was deleted in a Plex app | Add it back in a Plex app: Add Library, Music, and pick the `music` folder its folder list offers |
| `sync failed, ...: rex answered 409: ...more than half...` | More than half of the songs are gone from the folder | If you meant it, run once with `REX_FORCE=1`; otherwise fix `FOLDER` |
| No lyrics | The `.lrc` file's name differs from the song's, or the song was sent before the file was there | Name it like the song (`01 - Song.flac`, `01 - Song.lrc`); the next round sends it |

Still stuck? Ask in the **rex-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP).
