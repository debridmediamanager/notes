# チュートリアル: 音楽アドオン {#tutorial-a-music-addon}

このチュートリアルでは、アルバムのフォルダーを、Plexamp、Plex Web、Plex for Android で再生できる **Music** ライブラリに追加します。

FLAC、MP3、AAC などの一般的なファイル形式に対応しています。ファイルは元の場所に置いたままです。既知のアルバムの詳細は MusicBrainz から取得します。不明なアルバムは、タグと `cover.jpg` を使います。近くにある `.lrc` ファイルは、タイミング付きの歌詞になります。

このチュートリアルは [rex アドオンの作り方](addons.md) と、その [Music](addons.md#music) セクションに沿って進めます。アドオンを初めて作る場合は、先に [ホームビデオのチュートリアル](addon-home-videos.md) を読んでください。

| 必要なもの | 理由 |
|---|---|
| rex 2026.11.02 以降。[自分のアプリでrex](any-source.md)の手順 1 から 3 までに従って設定済みで、claim 済みであること | rex は、claim 済みになってから初めて、Plex にアルバム名を問い合わせます |
| Python 3.8 以降 | アドオン本体の実行に必要です。標準ライブラリのみを使います |
| `ffprobe` | rex 用に各ファイルの情報を取得し、タグを読み取ります。FFmpeg に含まれています |
| アルバムのファイル。アルバムごとにフォルダーを分けてください | `Artist/Album/01 Song.flac` の形式でも、どの深さでも構いません。音声ファイルを含むフォルダーはすべてアルバムとして扱われます |
| タグ、または MusicBrainz Picard | アドオンは各ファイルのタグからアルバム名とアーティスト名を読み取ります。タグがない場合はフォルダー名を使います。[MusicBrainz Picard](https://picard.musicbrainz.org) でタグ付けされたファイルは、リリース ID を持っているため、最も確実に一致します |

このページでは、rex のアドレスを `192.168.1.20:32400` と書き、アドオンは rex と同じマシンで実行します。

## ステップ 1. アドオンを保存する {#step-1-save-the-addon}

これを `music.py` という名前で保存してください:

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

## ステップ 2. 設定を入力する {#step-2-fill-in-the-settings}

| Setting | Put |
|---|---|
| `FOLDER` | あなたの音楽フォルダ。例えば `"/srv/music"` や `os.path.expanduser("~/Music")` |
| `REX` | rex のアドレス |
| `LISTEN` | アドオンを rex と同じマシンで動かすなら `127.0.0.1` のままにする。そうでなければ、そのマシンの LAN IP |
| `NAME`, `LIBRARY` | rex 内でのアドオンの名前と、音楽ライブラリのタイトル。一度実行したら `NAME` はそのまま変えない |

## ステップ 3. 実行する {#step-3-run-it}

+++ Linux and macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**表示される内容。** タグに release id がない各アルバムについて、MusicBrainz からの応答を1行ずつ、最後に合計を表示します:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz は1秒に1リクエストしか受け付けないので、大きなコレクションの最初の実行には時間がかかります。目安はアルバム1つあたり約1秒です。すべての応答は音楽フォルダ内の `.rex/albums.json` に保存されるので、次回以降の実行では問い合わせは行われません。Picard でタグ付けされたアルバムは検索されません。

rex のログには、各トラックがアルバムに追加される様子が表示されます:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Plexamp を開き、ライブラリとして rex の **Music** ライブラリを選びます(Plex Web と Plex for Android では More の中に表示されます)。ファイル名が何であっても、In Rainbows には Plex のカバー、トラック名、Radiohead の写真と経歴が表示されます。Garage Demos には、タグに書かれた名前とフォルダ内の `cover.jpg` が表示されます。同じ名前の `.lrc` ファイルがある曲は、再生に合わせて歌詞が1行ずつ表示されます。

動かし続けるには、home videos アドオンと同じように設定します: [ステップ4](addon-home-videos.md#step-4-keep-it-running)。`homevideos.py` の代わりに `music.py` を使います。

## 仕組み {#how-it-works}

| Part | What it does |
|---|---|
| `Handler` | `/music/` 以下のすべてを提供します: 曲 (`Range` に対応しているので、シークは即座に効きます)、その `.lrc` 歌詞、そしてアルバムカバー |
| `sync()`, first line | 1つのディレクトリ `music` を音楽ライブラリとしてアドオンに登録します: `"directories": [{"name": "music", "music": "Music"}]`。音楽ライブラリがないと rex はすべてのトラックを拒否します |
| `album_items()` | 曲ごとに1つのアイテム: `"kind": "track"`、その `disc` と `track` の番号 (タグから、なければフォルダ内の位置から)、`ffprobe` の出力、そして `ids.mbid` (アルバムの MusicBrainz リリース ID)。Plex はそのリリースの同じ番号に自分のトラックを表示するので、番号は正しくなければなりません |
| `release_id()` | リリース ID がないアルバムのリリース ID を探します。アルバス名とアーティストで MusicBrainz を検索し、フォルダの曲数と同じ数のトラックを持つ最初の公式リリースを採用します。アルバムは国ごとやデラックス版など、多くのリリースに分かれています。あなたのトラックを含むどれか1つがアルバムを特定します |
| `display` | タグから取ったアルバム名と、Plex がアルバムを知らないときだけ表示されるカバー |
| `lyrics` | 曲名と同じ名前で隣にある `.lrc` (タイミング付き) または `.txt` ファイルを、`[{"path": ..., "size": ...}]` として送ります。rex はサイズが変わったときだけ読み直します |
| `sync()`, the rest | すべての曲のスナップショットを、1リクエストあたり200件ずつ取得します。削除したアルバムは次のラウンド (10分ごと) でライブラリから消えます |

rex はタグを自分では読みません。Plex に表示されるものはすべて、リリース ID から来るか、Plex がアルバムを知らない場合は `display` から来ます。

## 変更する {#change-it}

- **別のレイアウト。** アルバムがディスクごとのフォルダ（`CD1/`、`CD2/`）に分かれていると、このアドオンからは2つのアルバムに見えてしまい、それぞれトラック数が少なすぎて一致しません。そのようなフォルダは `albums()` でまとめて、すべてのファイルを1つの `release` として送ってください。詳しくは [音楽](addons.md#music) を見てね。
- **アーティストの写真で表示。** `display.artist.poster` を送り、`"artwork": "source"` で登録してください。詳しくは [アドオンのその他の機能](addon-more.md#artist-pictures) を見てね。
- **プレイリスト。** 各曲のプレイリスト内の位置を送ると、rex がプレイリストを作ってくれます。詳しくは [アドオンのその他の機能](addon-more.md#collections-and-playlists) を見てね。
- **ラウドネス。** 各曲のラウドネスを測っているなら、Plex の名前で `loudness` として送ってください。詳しくは [音楽](addons.md#music) を見てね。rex 自体は何も測定しません。

## トラブルシューティング {#troubleshooting}

| 表示される内容 | 原因 | 対処 |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | そのタイトルとアーティストで、曲数が N の公式リリースがありません。曲の欠落、ボーナストラック、タグの誤字、または MusicBrainz に載っていないアルバムが考えられます | タグかフォルダを直してから、`.rex/albums.json` (またはファイル全体) からそのアルバムの行を削除して、もう一度確認させてください。Picard でアルバムにタグを付けるのも手です |
| アルバムの曲名が違う | 見つかったリリースは曲数が同じでも、曲の順番が違います（別エディション） | Picard でアルバムにタグを付けてください。正確なリリースが書き込まれます |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz が混雑しているか、接続できませんでした | 何もしなくてOKです。次のラウンドでまた確認します |
| Plex は知っているのに、アルバムがタグの名前で表示される | rex が有効化されていないか、リリース ID が Plex の知らないものを指しています | rex を有効化してください: [step 3 of rex with your own app](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | Plex アプリでライブラリが削除されました | Plex アプリで Add Library → Music を選び、フォルダ一覧に出ている `music` フォルダを指定して追加し直してください |
| `sync failed, ...: rex answered 409: ...more than half...` | 曲の半分以上がフォルダから消えています | 意図したものなら、`REX_FORCE=1` を付けて一度だけ実行してください。そうでなければ `FOLDER` を直してください |
| 歌詞が表示されない | `.lrc` ファイルの名前が曲と違うか、曲が送信された後にファイルができました | 曲と同じ名前にしてください (`01 - Song.flac`, `01 - Song.lrc`)。次のラウンドで送られます |

それでも解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで聞いてみてください。
