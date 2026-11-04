---
label: "Tutorial: IPTV addon"
icon: broadcast
order: 67
---

# Tutorial: an IPTV addon

This tutorial builds a rex addon that turns an IPTV playlist (an M3U file) and its TV guide (an XMLTV file) into channels of **Live TV** in Plex Web and Plex for Android: every channel at its number, a guide of what is on, What's On, and the channel playing the moment you pick it. It works with any M3U whose channels are HLS streams (`.m3u8`), such as your IPTV provider's or a list of free-to-air channels, and any XMLTV guide that names them.

It follows [Building rex addons](addons.md) and its [Live TV](addons.md#live-tv) section, with the same shape as the [home videos tutorial](addon-home-videos.md): read that one first if this is your first addon. For live sports there is a ready-made addon instead: [Live TV with rex](live-tv.md).

| You need | Why |
|---|---|
| rex 2026.11.02 or newer, set up as in [rex with your own app](any-source.md) (steps 1 to 3) and claimed | Live TV is in its Plex apps |
| FFmpeg where rex runs | rex converts a channel while someone watches it. See [Converting video](any-source.md#converting-video-optional) |
| Python 3.8 or newer and `ffprobe` where the addon runs | The addon, standard library only. `ffprobe` checks each channel once a day |
| An M3U playlist | A URL or a file, with `#EXTINF` lines. `tvg-id` links a channel to its guide, `tvg-chno` gives its number, `tvg-logo` its logo, `group-title` its group |
| An XMLTV guide (optional) | A URL or a file, gzipped or not. Without one, channels are listed with nothing in the guide |

This page writes rex's address as `192.168.1.20:32400` and runs the addon on rex's machine.

## Step 1. Save the addon

Save this as `iptv.py`:

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

## Step 2. Fill in the settings

| Setting | Put |
|---|---|
| `PLAYLIST` | Your M3U's URL, or its path on this machine |
| `GUIDE` | Your XMLTV guide's URL or path. A provider's guide link usually ends in `xmltv.php`, `.xml` or `.xml.gz` |
| `GROUPS` | Only the groups you want, as their `group-title` values: `["News", "Sports"]`. Keep `[]` for every channel. Each channel is checked with `ffprobe` (a few seconds each), so a list of thousands takes long: pick groups |
| `REX`, `LISTEN` | rex's address, and where the addon answers (`127.0.0.1` with the addon on rex's machine) |
| `NAME`, `LIBRARY` | The addon's name in rex and the title of the library that also holds the channels. Keep `NAME` once you have run it |
| `FIRST` | The number the first channel without a `tvg-chno` gets. Pick numbers clear of other Live TV addons', such as `500` |

## Step 3. Run it

+++ Linux and macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**What you should see.** A line for every channel that could not be checked, then the total:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

rex's log shows the library made for the channels and the channels arriving:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

In Plex Web or Plex for Android, open **Live TV**: a tab with your rex's name lists the channels at their numbers, with the guide from three hours ago to a week ahead. Pick what is on and press **Watch Now**: it plays after a few seconds, the time rex takes to start converting it. What's On lists what is on now and later; an episode in the guide's `News` or `Sports` category is on those shelves.

The addon checks the playlist and sends the guide again every 30 minutes. To keep it running, set it up like the home videos addon: [Step 4](addon-home-videos.md#step-4-keep-it-running), with `iptv.py` in place of `homevideos.py`.

## How it works

| Part | What it does |
|---|---|
| `channels()` | Reads the playlist: each `#EXTINF` line and the URL after it. A channel's key, which is its `id` in rex for good, is its `tvg-id` (or its name) |
| `Handler` | Serves `/tv/<key>.m3u8` as a redirect to the channel's stream. rex follows it every time someone tunes in, and the addon looks the stream up at that moment, so links that expire keep working |
| `best_variant()` | Takes the best quality of a stream that offers several (an HLS master playlist), so what plays is what was checked |
| `probe()` | `ffprobe` of the stream, kept a day. rex needs it to know the channel's picture and sound, and takes the channel as live because its probe has no length. A stream that is not HLS, or does not answer, is skipped this round |
| `guides()` | Reads the XMLTV file once per round and keeps each channel's programmes from three hours ago to a week ahead: title, description, categories, picture, and `previously-shown` (a repeat). A programme with an `xmltv_ns` episode number becomes an episode of its show, numbered from 1 (XMLTV counts from 0) |
| `number_for()` | Gives each channel its number once and keeps it in `~/.rex-iptv.json`: the playlist's `tvg-chno` when no other channel has it, else the next free one from `FIRST`. Favourites in the Plex apps are kept by number, so a channel must keep its |
| `sync()` | Registers with `"trash": false`, so a channel that leaves the playlist is deleted, not kept in rex's trash. Each channel is sent with its `channel`: number, name and guide. A snapshot of every channel, 100 a request (a week of guide each) |

## Change it

- **Streams that are not HLS.** Many providers also offer each channel as MPEG-TS (`.ts`). rex takes a live channel as an HLS stream (`.m3u8`), so this addon skips the others: ask your provider for HLS links (often `output=m3u8` in the playlist URL).
- **Your own numbers.** Edit the numbers in `~/.rex-iptv.json` while the addon is stopped; the next round sends them.
- **Logos.** `tvg-logo` becomes the channel's picture in its library. The guide grid shows numbers and names.
- **A guide from somewhere else.** Anything that knows the schedule can fill `guide`: a provider's JSON API, a sports schedule, a fixed loop. rex-live-sports builds guides from ESPN's scoreboard, see [Live TV with rex](live-tv.md).

## Troubleshooting

| You see | Why | Fix |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | The channel is MPEG-TS or another format, or its stream answered with an error (the reason is at the end) | Use the channel's HLS link; a stream that is down is tried again next round |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`, `actively refused it` on Windows, or `HTTP Error 403`) | The stream did not answer, or refused this machine | Check the link in a player on the same machine. IPTV links often work only from the address that logged in |
| `no channel could be probed: not sending a snapshot` | No channel answered: the provider is down, or the playlist is empty | Nothing is removed. Check `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` on Windows) | rex is not running, or `REX` is not its address | Start rex, or fix `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | More than half of the channels left the playlist, or failed their check, at once | If you meant it, run once with `REX_FORCE=1`; otherwise wait for the provider to come back |
| A channel has nothing in the guide | Its `tvg-id` matches no `<channel id>` in the guide, or the guide has nothing for this week | Match the playlist's `tvg-id` to the guide's ids |
| Live TV is missing in a Plex app | No channel was sent yet, or the app is not Plex Web or Plex for Android, the apps tested | Run the addon, and use Plex Web or Plex for Android |
| Watch Now fails | rex has no FFmpeg, or the stream stopped | rex's log says why. For FFmpeg, see [Converting video](any-source.md#converting-video-optional) |

Still stuck? Ask in the **rex-support** forum on [Discord](https://discord.com/invite/7u4YjMThXP).
