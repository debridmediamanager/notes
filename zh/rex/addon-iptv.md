# 教程：IPTV 插件 {#tutorial-an-iptv-addon}

本教程会把 IPTV 播放列表（M3U）和电视节目指南（XMLTV）转换成 Plex Web 和 Plex for Android 里的 **Live TV** 频道。每个频道都会保留原来的频道号和节目指南。它适用于使用 HLS（`.m3u8`）的 M3U 频道，以及能对应这些频道的任意 XMLTV 指南。

本教程基于 [构建 rex 插件](addons.md) 及其中的 [Live TV](addons.md#live-tv) 部分。如果这是你第一次做插件，请先阅读 [家庭视频教程](addon-home-videos.md)。如果想看体育直播，请使用 [用 rex 看直播电视](live-tv.md)。

| 你需要 | 原因 |
|---|---|
| rex 2026.11.02 或更新版本，按照 [用你自己的应用使用 rex](any-source.md) 设置（第 1 到 3 步），并已认领 | Plex 应用中的 Live TV 功能需要它 |
| rex 运行所在的机器上装有 FFmpeg | rex 会在有人观看时实时转换频道。参见 [视频转换](any-source.md#converting-video-optional) |
| 插件运行所在的机器上装有 Python 3.8 或更新版本，以及 `ffprobe` | 插件只使用标准库。`ffprobe` 每天检查一次每个频道 |
| 一个 M3U 播放列表 | 可以是 URL 或文件，包含 `#EXTINF` 行。`tvg-id` 把频道和节目指南关联起来，`tvg-chno` 给出频道号，`tvg-logo` 给出台标，`group-title` 给出分组 |
| 一个 XMLTV 指南（可选） | 可以是 URL 或文件，可以是压缩的也可以不是。没有它的话，频道会显示，但节目指南是空的 |

本页把 rex 的地址写作 `192.168.1.20:32400`，插件也运行在 rex 所在的机器上。

## 第 1 步：保存插件 {#step-1-save-the-addon}

将以下内容保存为 `iptv.py`：

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

## 第 2 步：填写设置 {#step-2-fill-in-the-settings}

| 设置项 | 填写内容 |
|---|---|
| `PLAYLIST` | 你的 M3U 的 URL，或它在本机上的路径 |
| `GUIDE` | 你的 XMLTV 节目指南的 URL 或路径。服务商提供的指南链接通常以 `xmltv.php`、`.xml` 或 `.xml.gz` 结尾 |
| `GROUPS` | 只填你想要的分组，写成它们的 `group-title` 值：`["News", "Sports"]`。如果要所有频道，就保留 `[]`。每个频道都会用 `ffprobe` 检查一遍（每个需要几秒），所以如果列表有几千个频道，会很慢，最好挑选分组。 |
| `REX`、`LISTEN` | rex 的地址，以及插件的响应地址（插件和 rex 在同一台机器上时填 `127.0.0.1`） |
| `NAME`、`LIBRARY` | 插件在 rex 中的名称，以及同样存放频道的库的标题。运行过一次后请保持 `NAME` 不变 |
| `FIRST` | 没有 `tvg-chno` 的第一个频道所获得的编号。选一个不与其他 Live TV 插件冲突的编号，例如 `500` |

## 第 3 步：运行 {#step-3-run-it}

+++ Linux 和 macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**你应该看到的内容。** 每个无法检查的频道占一行，最后是总数：

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

rex 的日志会显示为这些频道创建的库，以及频道的到达情况：

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

在 Plex Web 或 Plex for Android 中，打开 **Live TV**：会出现一个以你的 rex 名称命名的标签页，列出各个频道及其编号，并提供从三小时前到一周后的节目指南。选择正在播出的节目，然后点击 **Watch Now**：几秒钟后开始播放，这是 rex 开始转换所需的时间。What's On 列出当前和之后的节目；节目指南中分类为 `News` 或 `Sports` 的节目会出现在对应的分类栏中。

插件会每 30 分钟检查一次播放列表并重新发送节目指南。要让它持续运行，请按照家庭视频插件的设置方式进行：[第 4 步](addon-home-videos.md#step-4-keep-it-running)，只需把 `homevideos.py` 换成 `iptv.py`。

（之前的译文被拒绝：标记不一致。请完全保持结构不变。）

## 工作原理 {#how-it-works}

```
```

Wait, that's not right. Let me produce the actual translation.

| 部分 | 作用 |
|---|---|
| `channels()` | 读取播放列表：每一行 `#EXTINF` 以及其后的 URL。频道的 key（在 rex 中长期使用的 `id`）是它的 `tvg-id`（如果没有则使用名称） |
| `Handler` | 将 `/tv/<key>.m3u8` 作为重定向提供给该频道的流。每当有人切换到该频道时，rex 都会跟随这个重定向，附加组件会在那一刻查找流地址，因此会过期的链接依然可以正常播放 |
| `best_variant()` | 对提供多个版本的流（HLS 主播放列表）选取质量最好的那个，这样播放的内容就是经过检查的内容 |
| `probe()` | 对流执行 `ffprobe`，结果保留一天。rex 需要它来了解频道的画面和声音，并且由于探测结果没有时长，会将该频道视为直播。不是 HLS 或无响应的流会在本轮被跳过 |
| `guides()` | 每轮读取一次 XMLTV 文件，并为每个频道保留从三小时前到一周后的节目：标题、描述、分类、图片以及 `previously-shown`（重播）。带有 `xmltv_ns` 集数编号的节目会成为其所属节目的一集，编号从 1 开始（XMLTV 从 0 计数） |
| `number_for()` | 为每个频道分配一次编号，并将其保存在 `~/.rex-iptv.json` 中：如果没有其他频道使用播放列表中的 `tvg-chno`，就使用它；否则从 `FIRST` 开始取下一个空闲编号。Plex 应用中的收藏是按编号保存的，因此频道必须保持编号不变 |
| `sync()` | 以 `"trash": false` 注册，因此离开播放列表的频道会被直接删除，而不是保存在 rex 的回收站中。每个频道都会连同其 `channel`（编号、名称和节目指南）一起发送。每次请求发送 100 个频道（每个频道附带一周的节目指南），即所有频道的一次完整快照 |

## 修改设置 {#change-it}

- **不是 HLS 的流。** 很多提供商也会把每个频道提供为 MPEG-TS（`.ts`）格式。rex 只接受 HLS 格式（`.m3u8`）的直播频道，所以这个插件会跳过其他格式。请向提供商索要 HLS 链接（通常是播放列表 URL 中带 `output=m3u8`）。
- **自己的数字。** 插件停止运行时，编辑 `~/.rex-iptv.json` 里的数字即可，下一轮就会生效。
- **台标。** `tvg-logo` 会成为该频道在媒体库中的图片。节目指南网格显示的是频道编号和名称。
- **外部来源的节目表。** 任何能提供播出时间表的东西都可以用来填充 `guide`：提供商的 JSON API、体育赛程表、固定循环等。rex-live-sports 会根据 ESPN 的比分板生成节目指南，详见 [使用 rex 观看直播电视](live-tv.md)。

## 故障排除 {#troubleshooting}

| 你看到的 | 原因 | 解决办法 |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | 该频道是 MPEG-TS 或其他格式，或者它的流返回了错误（原因在末尾） | 使用该频道的 HLS 链接；暂时失效的流会在下一轮重新尝试 |
| `skipped <channel>: <urlopen error ...>`（`Connection refused`、Windows 上的 `actively refused it` 或 `HTTP Error 403`） | 流没有响应，或者拒绝了这台机器 | 在同一台机器的播放器里检查链接。IPTV 链接通常只能在登录时所用的地址上使用 |
| `no channel could be probed: not sending a snapshot` | 没有任何频道响应：提供商宕机，或者播放列表是空的 | 不会删除任何内容。检查 `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>`（Windows 上为 `WinError 10061`） | rex 没有运行，或者 `REX` 不是它的地址 | 启动 rex，或修正 `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | 一次性有超过一半的频道离开了播放列表，或者未通过检查 | 如果这是你的本意，就用 `REX_FORCE=1` 运行一次；否则等待提供商恢复 |
| 某个频道在节目指南中没有内容 | 它的 `tvg-id` 与节目指南中的任何 `<channel id>` 都不匹配，或者指南这一周没有该频道的数据 | 把播放列表中的 `tvg-id` 改成与节目指南的 id 一致 |
| Plex 应用中看不到直播电视 | 还没有发送任何频道，或者所用的应用不是已测试过的 Plex Web 或 Plex for Android | 运行插件，并使用 Plex Web 或 Plex for Android |
| Watch Now 失败 | rex 没有安装 FFmpeg，或者流已经停止 | rex 的日志会说明原因。关于 FFmpeg，请参阅 [视频转码](any-source.md#converting-video-optional) |

仍然解决不了？请到 [Discord](https://discord.com/invite/7u4YjMThXP) 上的 **rex-support** 论坛提问。
