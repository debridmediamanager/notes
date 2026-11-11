# チュートリアル：IPTV アドオン {#tutorial-an-iptv-addon}

このチュートリアルでは、IPTV のプレイリスト（M3U）と番組表（XMLTV）を、Plex Web と
Plex for Android の **Live TV** チャンネルに変換します。各チャンネルは、番号と番組表をそのまま保ちます。
HLS（`.m3u8`）を使う M3U チャンネルと、それを名前で指定している XMLTV 番組表であれば動作します。

このページは [rex アドオンの作り方](addons.md) と、その [Live TV](addons.md#live-tv) のセクションに沿って進みます。アドオンを初めて作るなら、先に [ホームビデオのチュートリアル](addon-home-videos.md) を読んでください。ライブスポーツの場合は [rex での Live TV](live-tv.md) を使ってください。

| 必要なもの | 理由 |
|---|---|
| rex 2026.11.02 以降。[独自アプリでの rex](any-source.md) の手順 1〜3 のとおりにセットアップし、claim 済みであること | Live TV は Plex アプリで使えるため |
| rex が動いているマシンの FFmpeg | 誰かがチャンネルを視聴しているときに、rex がそのチャンネルを変換します。[動画の変換](any-source.md#converting-video-optional) を参照してください |
| アドオンを動かすマシンの Python 3.8 以降と `ffprobe` | アドオンは標準ライブラリだけを使います。`ffprobe` は各チャンネルを 1 日 1 回チェックします |
| M3U プレイリスト | URL またはファイル。`#EXTINF` 行を含むこと。`tvg-id` でチャンネルを番組表に紐付け、`tvg-chno` で番号、`tvg-logo` でロゴ、`group-title` でグループを指定します |
| XMLTV 番組表（任意） | URL またはファイル。gzip 圧縮されていてもいなくても使えます。ない場合、チャンネルは番組表なしで並びます |

このページでは rex のアドレスを `192.168.1.20:32400` と書き、アドオンは rex のマシン上で実行するものとします。

## ステップ 1. アドオンを保存する {#step-1-save-the-addon}

次の内容を `iptv.py` として保存してください:

```python
#!/usr/bin/env python3
"""iptv: a rex addon that turns an M3U playlist and its XMLTV guide into Live TV channels.

Standard library only; needs ffprobe on PATH. Plays HLS (.m3u8) channels; others are skipped.
"""
import gzip, io, json, os, re, subprocess, sys, threading, time, urllib.error, urllib.parse, urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PLAYLIST = "https://example.com/playlist.m3u"   # your M3U: a URL or a file path
GUIDE = "https://example.com/guide.xml.gz"       # its XMLTV guide: a URL or a file path, .gz or not
GROUPS = []                                      # only these group-title values; [] keeps every channel
REX = "http://192.168.1.20:32400"                # rex's address
LISTEN = ("127.0.0.1", 9983)                     # where this addon answers; rex must reach it
NAME, LIBRARY = "iptv", "Live Channels"          # the source's name and its library's title
FIRST = 1                                        # the first channel number this addon hands out

ME = "http://%s:%d" % LISTEN
FORCE = os.environ.get("REX_FORCE") == "1"  # REX_FORCE=1 lets one run remove more than half
STATE = os.path.expanduser("~/.rex-iptv.json")   # channel numbers and probes, kept across restarts
state = json.load(open(STATE)) if os.path.exists(STATE) else {"numbers": {}, "probes": {}}
streams = {}                                     # channel key -> the stream URL to send rex to
sys.stdout.reconfigure(line_buffering=True)


def read(source):
    """A URL's or a file's bytes, un-gzipped."""
    if re.match(r"https?://", source):
        with urllib.request.urlopen(urllib.request.Request(source, headers={"User-Agent": "rex-iptv/1.0"}), timeout=60) as r:
            data = r.read()
    else:
        with open(os.path.expanduser(source), "rb") as f:
            data = f.read()
    return gzip.decompress(data) if data[:2] == b"\x1f\x8b" else data


# ---- Serve the bytes: a channel's path redirects to its stream ----------------------------
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        key = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path)[len("/tv/"):-len(".m3u8")]
        if not self.path.startswith("/tv/") or key not in streams:
            return self.send_error(404)
        self.send_response(302)  # rex follows it and converts the stream while someone watches
        self.send_header("Location", best_variant(streams[key]))  # asked now: stream links can expire
        self.end_headers()

    def log_message(self, *args):
        pass


# ---- The playlist --------------------------------------------------------------------------
def channels():
    """(key, name, logo, number, group, url) for each #EXTINF entry of the playlist."""
    found, info = [], None
    for line in read(PLAYLIST).decode("utf-8", "replace").splitlines():
        line = line.strip()
        if line.startswith("#EXTINF"):
            attrs = dict(re.findall(r'([\w-]+)="([^"]*)"', line))
            info = (attrs, line.rsplit(",", 1)[-1].strip())
        elif line and not line.startswith("#") and info:
            attrs, name = info
            info = None
            if GROUPS and attrs.get("group-title") not in GROUPS:
                continue
            key = re.sub(r"[^A-Za-z0-9_-]+", "-", attrs.get("tvg-id") or name).strip("-") or "channel"
            found.append((key, name, attrs.get("tvg-logo"), attrs.get("tvg-chno"), attrs.get("tvg-id"), line))
    return found


def best_variant(url):
    """An HLS master playlist's highest-bandwidth variant; any other playlist as it is."""
    with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "rex-iptv/1.0"}), timeout=30) as r:
        text, final = r.read().decode("utf-8", "replace"), r.geturl()
    best, lines = None, text.splitlines()
    for i, line in enumerate(lines):
        if line.startswith("#EXT-X-STREAM-INF"):
            bw = int((re.search(r"BANDWIDTH=(\d+)", line) or [0, 0])[1])
            nxt = next((l.strip() for l in lines[i + 1:] if l.strip() and not l.startswith("#")), None)
            if nxt and (best is None or bw > best[0]):
                best = (bw, urllib.parse.urljoin(final, nxt))
    return best[1] if best else url


def probe(url):
    """ffprobe of the stream, kept for a day: rex needs it, and an HLS probe of a live channel has no duration."""
    old = state["probes"].get(url)
    if old and old["at"] > time.time() - 86400:
        return old["info"]
    out = subprocess.run(["ffprobe", "-v", "error", "-rw_timeout", "15000000", "-print_format", "json",
                          "-show_format", "-show_streams", url], capture_output=True, timeout=60)
    info = json.loads(out.stdout or b"{}")
    if info.get("format", {}).get("format_name") != "hls" or not info.get("streams"):
        raise ValueError("not a live HLS stream (%s)" % (out.stderr.decode().strip()[-200:] or info.get("format", {}).get("format_name")))
    state["probes"][url] = {"at": time.time(), "info": info}
    return info


# ---- The guide -----------------------------------------------------------------------------
def when(xmltv):
    """XMLTV's "20261104180000 +0100" as ISO 8601, which rex takes."""
    t = datetime.strptime(xmltv[:14], "%Y%m%d%H%M%S")
    zone = xmltv[14:].strip() or "+0000"
    return t.strftime("%Y-%m-%dT%H:%M:%S") + zone[:3] + ":" + zone[3:5]


def guides(wanted):
    """Each wanted channel's programmes from three hours ago to a week ahead."""
    now = datetime.now(timezone.utc)
    lo, hi = (now - timedelta(hours=3)).strftime("%Y%m%d%H%M%S"), (now + timedelta(days=7)).strftime("%Y%m%d%H%M%S")
    found = {c: [] for c in wanted}
    for _, el in ET.iterparse(io.BytesIO(read(GUIDE))):
        if el.tag != "programme":
            continue
        start, stop, ch = el.get("start", ""), el.get("stop", ""), el.get("channel")
        if ch in found and start and stop and stop[:14] > lo and start[:14] < hi:
            p = {"start": when(start), "end": when(stop), "title": el.findtext("title") or "?",
                 "summary": el.findtext("desc"), "categories": [c.text for c in el.findall("category") if c.text]}
            ns = el.findtext("episode-num[@system='xmltv_ns']")
            m = re.match(r"\s*(\d+)?\s*\.\s*(\d+)", ns or "")
            if m and m.group(2):  # xmltv_ns counts from 0: "0.4." is season 1, episode 5
                p.update(type="episode", show=p["title"], title=el.findtext("sub-title") or p["title"],
                         season=int(m.group(1) or 0) + 1, episode=int(m.group(2)) + 1)
            if el.find("previously-shown") is not None:
                p["previously_shown"] = True
            icon = el.find("icon")
            if icon is not None and (icon.get("src") or "").startswith("http"):
                p["thumb"] = icon.get("src")
            found[ch].append({k: v for k, v in p.items() if v not in (None, [])})
        el.clear()
    return found


# ---- Register, then send every channel ------------------------------------------------------
def rex(method, path, body):
    req = urllib.request.Request(REX + path, json.dumps(body).encode(), method=method,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:  # rex says why in the body
        raise RuntimeError("rex answered %d: %s" % (e.code, e.read().decode(errors="replace")[:300])) from None


def number_for(key, chno):
    """Handed out once and kept, so a favourite stays on its channel: the playlist's tvg-chno if free."""
    if key not in state["numbers"]:
        taken, n = set(state["numbers"].values()), FIRST
        while str(n) in taken:
            n += 1
        state["numbers"][key] = chno if chno and chno not in taken else str(n)
    return state["numbers"][key]


def sync():
    rex("PUT", "/rex/sources/" + NAME, {"url": ME, "trash": False,
                                        "directories": [{"name": "tv", "movies": LIBRARY}]})
    listed = channels()
    guide = guides({c[4] for c in listed if c[4]})
    items = []
    for key, name, logo, chno, tvg_id, url in listed:
        try:
            stream = best_variant(url)
            info = probe(stream)
        except Exception as e:
            print("skipped %s: %s" % (name, e))
            continue
        streams[key] = url
        item = {"id": key, "path": "tv/%s.m3u8" % key, "media_info": info,
                "display": {"title": name},
                "channel": {"number": number_for(key, chno), "title": name, "guide": guide.get(tvg_id, [])}}
        if logo and logo.startswith("http"):
            item["display"]["thumb"] = logo
        items.append(item)
    with open(STATE, "w") as f:
        json.dump(state, f)
    if not items:
        print("no channel could be probed: not sending a snapshot")
        return
    session = str(time.time())
    for n in range(0, len(items), 100):  # a week of guide per channel: 100 channels a request
        answer = rex("PUT", "/rex/feed/%s/snapshot" % NAME,
                     {"session": session, "part": n // 100, "complete": n + 100 >= len(items), "force": FORCE, "items": items[n:n + 100]})
        for bad in answer.get("rejected", []):
            print("rejected:", bad)
    print("sent %d channels: %d created, %d updated, %d unchanged" % (len(items), answer["created"], answer["updated"], answer["unchanged"]))


if __name__ == "__main__":
    server = ThreadingHTTPServer(LISTEN, Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    print("serving %s at %s" % (PLAYLIST, ME))
    while True:
        try:
            sync()
        except Exception as e:
            print("sync failed, trying again in 30 minutes:", e)
        time.sleep(1800)
```

## ステップ 2. 設定を入力する {#step-2-fill-in-the-settings}

| 設定 | 入力内容 |
|---|---|
| `PLAYLIST` | M3U の URL、またはこのマシン上のパス |
| `GUIDE` | XMLTV ガイドの URL またはパス。プロバイダーのガイドリンクは通常 `xmltv.php`、`.xml`、`.xml.gz` で終わります |
| `GROUPS` | 必要なグループだけを `group-title` の値で指定します（例: `["News", "Sports"]`）。全チャンネルを対象にする場合は `[]` のままにします。各チャンネルは `ffprobe` で確認されます（1 チャンネルあたり数秒）。数千件のリストだと時間がかかるので、グループを選んでください |
| `REX`, `LISTEN` | rex のアドレスと、アドオンが応答するアドレス（アドオンを rex と同じマシンで動かす場合は `127.0.0.1`） |
| `NAME`, `LIBRARY` | rex でのアドオンの名前と、チャンネルも入っているライブラリのタイトル。一度実行したあとは `NAME` をそのまま残してください |
| `FIRST` | `tvg-chno` がないチャンネルに最初に割り当てられる番号。他の Live TV アドオン（例: `500`）と重ならない番号を選んでください |

## ステップ 3. 実行する {#step-3-run-it}

+++ Linux and macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**表示されるもの。** チェックできなかったチャンネルごとに1行ずつ表示され、最後に合計が出ます:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

rex のログには、チャンネル用に作られたライブラリと、届いたチャンネルが表示されます:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Plex Web または Plex for Android で **Live TV** を開きます。rex の名前が付いたタブに、チャンネルが番号順に並び、3時間前から1週間先までの番組表が表示されます。放送中の番組を選んで **Watch Now** を押すと、数秒後に再生が始まります。この数秒は rex が変換を開始するまでの時間です。**What's On** には今と今後の放送中の番組が表示されます。番組表で `News` または `Sports` カテゴリの番組は、それぞれの棚に並びます。

アドオンは30分ごとにプレイリストを確認し、番組表を再送信します。実行し続けるには、ホームビデオ用アドオンと同じように設定してください: [ステップ4](addon-home-videos.md#step-4-keep-it-running)。ただし `homevideos.py` の代わりに `iptv.py` を使います。

## 仕組み {#how-it-works}

| 部分 | 役割 |
|---|---|
| `channels()` | プレイリストを読み込みます。各 `#EXTINF` 行と、その後の URL を読みます。チャンネルのキー（rex では永続的な `id` になります）は `tvg-id`（なければ名前）です |
| `Handler` | `/tv/<key>.m3u8` に対して、チャンネルのストリームへのリダイレクトを返します。視聴者がチャンネルを選ぶたびに rex がそれを追いかけ、その時点でアドオンがストリームを探し直します。そのため、期限切れになるリンクでも動き続けます |
| `best_variant()` | 複数の画質を持つストリーム（HLS のマスタープレイリスト）から最高画質を選びます。再生されるのは、確認済みのものになります |
| `probe()` | ストリームに `ffprobe` を実行し、結果を1日保存します。rex はこれでチャンネルの映像と音声を知ります。probe には長さがないため、チャンネルはライブとして扱われます。HLS でない、または応答しないストリームは、今回はスキップされます |
| `guides()` | XMLTV ファイルを1ラウンドに1回読み込み、各チャンネルの番組を3時間前から1週間先まで保持します。タイトル、説明、カテゴリ、画像、`previously-shown`（再放送）を含みます。`xmltv_ns` のエピソード番号がある番組は、その番組のエピソードになり、1から番号が振られます（XMLTV は0から数えるため） |
| `number_for()` | 各チャンネルに一度だけ番号を割り当て、`~/.rex-iptv.json` に保存します。他のチャンネルが使っていなければプレイリストの `tvg-chno` を使い、使われていれば `FIRST` から空いている次の番号を使います。Plex アプリのお気に入りは番号で保存されるため、チャンネルは番号を変えないようにする必要があります |
| `sync()` | `"trash": false` で登録するので、プレイリストから消えたチャンネルは rex のゴミ箱に入らず、削除されます。各チャンネルは `channel`（番号、名前、ガイド）と一緒に送られます。全チャンネルのスナップショットを、1リクエストあたり100件ずつ送ります（各チャンネルに1週間分のガイド付き） |

## 変更する {#change-it}

- **HLS ではないストリーム。** 多くのプロバイダーは、各チャンネルを MPEG-TS（`.ts`）形式でも提供しています。rex はライブチャンネルを HLS ストリーム（`.m3u8`）として扱うため、このアドオンはそれ以外をスキップします。プロバイダーに HLS のリンクを求めてください（多くの場合、プレイリストの URL に `output=m3u8` が含まれています）。
- **好みの番号。** アドオンを停止した状態で `~/.rex-iptv.json` の番号を編集してください。次のラウンドでその番号が送られます。
- **ロゴ。** `tvg-logo` はライブラリ内でそのチャンネルの画像になります。ガイドのグリッドには番号と名前が表示されます。
- **別の場所からのガイド。** 番組表を知っているものなら何でも `guide` に入れられます。プロバイダーの JSON API、スポーツの日程、固定のループなどです。rex-live-sports は ESPN のスコアボードからガイドを作成します。詳しくは [rex での Live TV](live-tv.md) を参照してください。

## トラブルシューティング {#troubleshooting}

| 表示されるもの | 原因 | 対処法 |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | チャンネルが MPEG-TS などの別形式か、ストリームがエラーを返しています（理由は末尾にあります） | チャンネルの HLS リンクを使ってください。停止中のストリームは次のラウンドで再度確認されます |
| `skipped <channel>: <urlopen error ...>`（`Connection refused`、Windows では `actively refused it`、または `HTTP Error 403`） | ストリームが応答しなかったか、このマシンからのアクセスを拒否されました | 同じマシンのプレーヤーでリンクを確認してください。IPTV のリンクは、ログインしたアドレスからのみ動く場合があります |
| `no channel could be probed: not sending a snapshot` | どのチャンネルも応答しませんでした。プロバイダーがダウンしているか、プレイリストが空です | 何も削除されていません。`PLAYLIST` を確認してください |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>`（Windows では `WinError 10061`） | rex が起動していないか、`REX` のアドレスが正しくありません | rex を起動するか、`REX` を修正してください |
| `sync failed, ...: rex answered 409: ...more than half...` | チャンネルの半分以上が一度にプレイリストから外れたか、チェックに失敗しました | 意図した操作なら、`REX_FORCE=1` を付けて一度だけ実行してください。そうでなければ、プロバイダーの復旧を待ってください |
| チャンネルのガイドに何も表示されない | プレイリストの `tvg-id` がガイドの `<channel id>` と一致していないか、今週分のガイドがありません | プレイリストの `tvg-id` をガイドの id に合わせてください |
| Plex アプリでライブ TV が見つからない | まだチャンネルが送信されていないか、テスト済みのアプリ（Plex Web と Plex for Android）以外を使っています | アドオンを実行し、Plex Web か Plex for Android を使ってください |
| Watch Now が失敗する | rex に FFmpeg がないか、ストリームが停止しました | rex のログに理由が出ています。FFmpeg については [Converting video](any-source.md#converting-video-optional) を参照してください |

それでも解決しない場合は、[Discord](https://discord.com/invite/7u4YjMThXP) の **rex-support** フォーラムで聞いてください。
