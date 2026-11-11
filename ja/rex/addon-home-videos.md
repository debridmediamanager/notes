# チュートリアル：ホームビデオ用アドオン {#tutorial-a-home-videos-addon}

このチュートリアルでは、Python ファイル 1 つで rex アドオンを作ります。スマホの動画、ビデオカメラのファイル、画面録画などを、すべての Plex アプリの **Home Videos** ライブラリに入れます。各動画には、タイトル、日付、ポスター用の静止画が付きます。
何もコピーもアップロードもされません。再生ボタンを押すと、rex がアドオンからファイルを読み込みます。

これは [Building rex addons](addons.md) の手順 1〜5 を、動く最短の形にまとめたものです。このページでは、入力するコマンドを説明します。
理由は、あちらで説明しています。[music](addon-music.md) と [IPTV](addon-iptv.md) のチュートリアルも、同じ骨組みを使っています。

| 必要なもの | 理由 |
|---|---|
| rex を [rex with your own app](any-source.md) の手順 1〜3 どおりにセットアップ済みであること | ライブラリが表示されるのはここです。Claim 済みなので、Plex アプリから見えるようになります |
| Python 3.8 以降 | アドオン本体です。Python の標準ライブラリだけを使います |
| `ffprobe` と `ffmpeg` | `ffprobe` は各動画の情報を rex に渡し、`ffmpeg` はポスター用の静止画を切り出します。どちらも FFmpeg に含まれています |
| アドオンを動かすマシン上にある動画のフォルダ | `.mp4`、`.mkv`、`.mov`、`.m4v`、`.avi`、`.webm`、`.mts`、`.m2ts`、`.3gp` のいずれか（サブフォルダ内も可） |

このページでは rex のアドレスを `192.168.1.20:32400` と書き、アドオンは rex と同じマシンで動かします。お使いの環境の値に読み替えてください。

## ステップ 1. アドオンを保存する {#step-1-save-the-addon}

**What it does.** アドオン全体をまとめたものです。動画用の小さなWebサーバーと、5分ごとにrexへ動画の情報を伝えるループが入っています。

`homevideos.py` という名前で保存してください:

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

## ステップ 2. 設定を入力する {#step-2-fill-in-the-settings}

**何をするか。** アドオンを、あなたのフォルダーと rex に向けます。

docstring の下にある 4 行を変更してください。

| 設定 | 入れる値 |
|---|---|
| `FOLDER` | 動画のフォルダーです。例: `"/srv/videos/home"`。ホームフォルダー内にある場合は `os.path.expanduser("~/Videos/Home")` のように書きます |
| `REX` | rex のアドレスです。[自分のアプリで rex を使う](any-source.md)の手順 3 で開くときのアドレスを入れます |
| `LISTEN` | アドオンが応答する場所です。アドオンを rex と同じマシンで動かす場合は `127.0.0.1` のままにしてください。別のマシンで動かす場合は、そのマシンの LAN IP を入れます (rex はそのマシンから動画を読み取るので、rex から到達できる必要があります) |
| `NAME`, `LIBRARY` | rex 内でのアドオンの名前と、ライブラリのタイトルです。一度実行したら `NAME` は変えないでください。rex の行はその名前に紐づいているためです |

## ステップ 3. 実行する {#step-3-run-it}

+++ Linux and macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**表示される内容。** 最初の実行では、すべての動画を調べて、それぞれから静止画を1枚切り出し、その後まとめて送信します:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

rex のログには、ソースと新しいライブラリが表示され、その後に動画が続きます:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Plex アプリを開いてください。**Home Videos** は More の下にあります(Home に表示したい場合はピン留めしてください)。各動画のタイトルはファイル名、サマリーはそのファイルが入っているフォルダー名、リリース日はファイルの日付になります。ポスターと背景には、動画の先頭から10分の1の位置で切り出した静止画が使われます。再生ボタンを押せばすぐに再生され、シークも即座に行えます。

Ctrl+C でアドオンを停止します。もう一度実行すると、何も調べずに同じ動画を `unchanged` として送信します。調べ結果と静止画は、動画フォルダー内の `.rex` フォルダーに保存されています。

## ステップ 4. 動かし続ける {#step-4-keep-it-running}

アドオンは誰かが視聴するたびに動いている必要があります。rex はそこからすべての動画を読み込むためです。

+++ Linux
アドオンを保存したフォルダーを指定して、`~/.config/systemd/user/homevideos.service` を作成します:

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

rex 用に `sudo loginctl enable-linger "$USER"` を実行していれば、ログアウト後もアドオンは動き続けます。
+++ macOS and Windows
[rex を自分のアプリで使う](any-source.md#step-1-install-rex) の手順 1 で rex を起動するのと同じ方法で起動します。macOS なら LaunchAgent、Windows ならスケジュールタスクを使い、コマンドには `python3 homevideos.py`（Windows では `python homevideos.py`）、作業フォルダーにはアドオンのフォルダーを指定します。
+++

## 仕組み {#how-it-works}

この ファイルの各 パート は、[rex アドオンの作り方](addons.md) の1つの ステップ に対応しています。

| パート | ステップ | 役割 |
|---|---|---|
| `Handler` | [1. バイトを配信する](addons.md#step-1-serve-the-bytes) | `GET /home/<file>` にはファイルで応答し、`Range` リクエストにはそのバイトだけを `206` で返すので、シークしても先頭から読み直しになりません。`GET /stills/<name>.jpg` はポスターを配信します。フォルダの外へのリクエストはすべて `404` になります |
| `sync()`, 最初の行 | [2. rex に登録する](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` で、アドオンのアドレスと、映画ライブラリとしてのディレクトリ1つ `home` を送ります。毎ラウンド送信されますが、何度登録しても変わりはありません |
| `describe()` | [3. 各動画を説明する](addons.md#step-3-describe-each-video) | 動画の `id` はフォルダ内のパスなので、ファイル名を変えると、視聴履歴のない新しいタイトルとして扱われます。`kind: "movie"` にすると各動画が個別の映画になるので、番号を振る必要はありません。`media_info` は `ffprobe` の出力をそのまま全部入れたものです |
| `describe()`, `display` | [4. 名前を付けて飾る](addons.md#step-4-name-and-dress-it) | タイトル、概要、日付、画像。スチルのURLはアドオン自身のアドレスの下にあり、これが rex がネットワーク上で画像を取得する唯一の場所です |
| `sync()`, 残りの部分 | [5. 送信する](addons.md#step-5-send-it) | すべての動画のスナップショットを 200 リクエストで送ります。フォルダから削除した動画は、次のラウンドでライブラリから消えます |

安全装置があるので、悪いタイミングでライブラリが空になることはありません。空または存在しないフォルダは何も送信されず、`ffprobe` が読めない動画はスキップされてログに記録されます。さらに rex 自身も、動画の半分以上を削除してしまうスナップショットは受け付けません。

## 変更する {#change-it}

- **映画ではなくシリーズ。** `"kind": "episode"` と `season`、`episode` の番号、`display.show` を送り、ディレクトリを `"shows"` として登録します。新しい動画を追加しても他のエピソードの番号がずれないように、番号はフォルダ内の位置ではなく日付で付けてください。詳しくは [ステップ 3](addons.md#step-3-describe-each-video) を見てください。
- **自分のタイトル。** ファイル名ではなく、サイドカーファイルか動画のタグ（`media_info["format"]["tags"]`）からタイトルを読み取ります。
- **字幕、コレクション、チャプター。** 動画の横に置く `.srt` ファイル、フォルダごとのコレクション、チャプターマークについては、[アドオンのその他の機能](addon-more.md) を見てください。
- **Plex アプリからの削除を許可する。** ファイルを削除して `204` を返す `do_DELETE` を追加します。これがないと、アドオンは `501` を返し、rex は動画を残します（ログには `DELETE refused by the source, row kept: home/... at homevideos: 501` と出ます）。アプリには削除できなかったと表示されます。

## トラブルシューティング {#troubleshooting}

| 表示される内容 | 原因 | 対処 |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex が動いていないか、`REX` がその場所を指していません | rex を起動するか、`REX` を直す |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | このアドオンで rex が持っている動画の半分以上がフォルダから消えています。マウントされていないディスク、間違った `FOLDER`、大規模な整理のいずれかです | わざと行ったなら、`REX_FORCE=1 python3 homevideos.py` で一度だけ実行してください。そうでなければフォルダを直してください。何も削除されていません |
| `no videos found in ...: not sending a snapshot` | フォルダが空、存在しない、または動画ファイルがありません | `FOLDER` を直す |
| `skipped <file>: ...` | `ffprobe` がファイルを読めませんでした（壊れているか、書き込みが終わっていないファイル） | 次のラウンドで再度試されます |
| `rejected: {'id': ..., 'reason': ...}` | rex が動画を1本拒否し、その理由を示しています | [rex アドオンの作り方、トラブルシューティング](addons.md#troubleshooting) を参照 |
| ライブラリはあるのにポスターが空白 | `ffmpeg` が入っていないか、rex が `LISTEN` に到達できません | FFmpeg をインストールする。アドオンを別のマシンで動かしている場合は、`LISTEN` にそのマシンの LAN IP を設定する（`127.0.0.1` ではなく） |
| 再生に失敗し、rex のログに `PART ... upstream failed: <urlopen error Connection refused ...>` と出る | アドオンが動いていないか、rex が `LISTEN` に到達できません | アドオンを起動する。別のマシンで動かしている場合は、`LISTEN` にそのマシンの LAN IP を設定する |

まだ解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで聞いてください。
