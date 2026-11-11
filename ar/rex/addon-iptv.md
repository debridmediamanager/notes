# درس تعليمي: إضافة IPTV {#tutorial-an-iptv-addon}

هذا الدرس يحوّل قائمة IPTV (M3U) ودليل البرامج التلفزيوني (XMLTV) إلى قنوات **Live TV** في Plex Web وPlex for Android. كل قناة تحتفظ برقمها ودليلها. يعمل مع قنوات M3U التي تستخدم HLS (`.m3u8`) وأي دليل XMLTV يذكرها بأسمائها.

يتبع [بناء إضافات rex](addons.md) وقسم [Live TV](addons.md#live-tv) فيه. اقرأ [درس الفيديوهات المنزلية](addon-home-videos.md) أولاً إذا كانت هذه أول إضافة تبنيها. وللرياضة المباشرة استخدم [Live TV مع rex](live-tv.md).

| ما تحتاجه | السبب |
|---|---|
| rex 2026.11.02 أو أحدث، مُعدّ كما في [rex مع تطبيقك الخاص](any-source.md) (الخطوات من 1 إلى 3) ومربوط بحسابك | Live TV موجودة في تطبيقات Plex |
| FFmpeg على الجهاز الذي يعمل عليه rex | يحوّل rex القناة أثناء مشاهدتها. انظر [تحويل الفيديو](any-source.md#converting-video-optional) |
| Python 3.8 أو أحدث و`ffprobe` على الجهاز الذي تعمل عليه الإضافة | الإضافة تستخدم المكتبة القياسية فقط. يفحص `ffprobe` كل قناة مرة واحدة في اليوم |
| قائمة M3U | رابط أو ملف، فيه أسطر `#EXTINF`. يربط `tvg-id` القناة بدليلها، و`tvg-chno` يعطيها رقمها، و`tvg-logo` شعارها، و`group-title` مجموعتها |
| دليل XMLTV (اختياري) | رابط أو ملف، مضغوط بصيغة gzip أو غير مضغوط. بدونه تظهر القنوات بدون أي شيء في الدليل |

يكتب هذا الدرس عنوان rex بالشكل `192.168.1.20:32400` ويشغّل الإضافة على الجهاز نفسه الذي يعمل عليه rex.

## الخطوة 1. احفظ الإضافة {#step-1-save-the-addon}

احفظ هذا باسم `iptv.py`:

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

## الخطوة 2. املأ الإعدادات {#step-2-fill-in-the-settings}

| الإعداد | ضع |
|---|---|
| `PLAYLIST` | رابط ملف M3U الخاص بك، أو مساره على هذا الجهاز |
| `GUIDE` | رابط دليل XMLTV أو مساره. عادةً ما ينتهي رابط الدليل من المزود بـ `xmltv.php` أو `.xml` أو `.xml.gz` |
| `GROUPS` | المجموعات التي تريدها فقط، كقيم `group-title` الخاصة بها: `["News", "Sports"]`. أبقِ `[]` لكل القنوات. يتم فحص كل قناة باستخدام `ffprobe` (بضع ثوانٍ لكل قناة)، لذا فالقائمة التي تضم آلاف القنوات تستغرق وقتاً طويلاً: اختر المجموعات |
| `REX`, `LISTEN` | عنوان rex، والمكان الذي تستجيب فيه الإضافة (`127.0.0.1` إذا كانت الإضافة على الجهاز نفسه الذي يعمل عليه rex) |
| `NAME`, `LIBRARY` | اسم الإضافة في rex وعنوان المكتبة التي تحتوي أيضاً على القنوات. أبقِ `NAME` كما هو بعد أن تشغّله مرة واحدة |
| `FIRST` | الرقم الذي تحصل عليه أول قناة لا تحتوي على `tvg-chno`. اختر أرقاماً بعيدة عن أرقام إضافات Live TV الأخرى، مثل `500` |

## الخطوة 3. شغّلها {#step-3-run-it}

+++ Linux و macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**ما الذي يجب أن تراه.** سطر لكل قناة لم يمكن التحقق منها، ثم الإجمالي:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

يُظهر سجل rex المكتبة التي أُنشئت للقنوات والقنوات التي وصلت:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

في Plex Web أو Plex for Android، افتح **Live TV**: ستجد تبويبًا باسم rex الخاص بك يعرض القنوات بأرقامها، مع الدليل من ثلاث ساعات مضت حتى أسبوع قادم. اختر ما يُعرض الآن واضغط **Watch Now**: سيبدأ التشغيل بعد بضع ثوانٍ، وهو الوقت الذي يحتاجه rex لبدء تحويل البث. تعرض What's On ما يُعرض الآن وما سيُعرض لاحقًا، والحلقة التي تنتمي إلى فئة `News` أو `Sports` في الدليل تظهر ضمن هذين القسمين.

تتحقق الإضافة من قائمة التشغيل وترسل الدليل من جديد كل 30 دقيقة. لإبقائها تعمل، اضبطها بالطريقة نفسها التي ضبطت بها إضافة الفيديوهات المنزلية: [الخطوة 4](addon-home-videos.md#step-4-keep-it-running)، مع استخدام `iptv.py` بدلًا من `homevideos.py`.

## كيف تعمل {#how-it-works}

| الجزء | وظيفته |
|---|---|
| `channels()` | يقرأ قائمة التشغيل: كل سطر `#EXTINF` والرابط الذي يليه. مفتاح القناة، وهو `id` الخاص بها في rex بشكل دائم، هو `tvg-id` الخاص بها (أو اسمها) |
| `Handler` | يقدم `/tv/<key>.m3u8` كإعادة توجيه إلى بث القناة. يتبع rex هذه الإعادة في كل مرة يفتح فيها أحد القناة، وتبحث الإضافة عن البث في تلك اللحظة، لذلك تستمر الروابط التي تنتهي صلاحيتها في العمل |
| `best_variant()` | يختار أفضل جودة من البث الذي يقدم عدة جودات (قائمة HLS الرئيسية)، فيكون ما يُشغَّل هو ما جرى التحقق منه |
| `probe()` | يشغل `ffprobe` على البث، ويحتفظ بالنتيجة ليوم كامل. يحتاجها rex ليعرف الصورة والصوت الخاصين بالقناة، ويعامل القناة على أنها مباشرة لأن نتيجة الفحص لا تحتوي على مدة. البث الذي ليس من نوع HLS، أو الذي لا يستجيب، يُتخطى في هذه الجولة |
| `guides()` | يقرأ ملف XMLTV مرة واحدة في كل جولة، ويحتفظ لكل قناة ببرامجها من ثلاث ساعات مضت إلى أسبوع قادم: العنوان، والوصف، والفئات، والصورة، و`previously-shown` (إعادة). البرنامج الذي يحمل رقم حلقة `xmltv_ns` يصبح حلقة من مسلسله، مرقمة ابتداءً من 1 (لأن XMLTV يعد من 0) |
| `number_for()` | يعطي كل قناة رقمها مرة واحدة ويحفظه في `~/.rex-iptv.json`: يأخذ `tvg-chno` من قائمة التشغيل إذا لم تكن قناة أخرى تملكه، وإلا فالرقم الحر التالي ابتداءً من `FIRST`. تُحفظ المفضلات في تطبيقات Plex حسب الرقم، لذلك يجب أن تحتفظ القناة برقمها |
| `sync()` | يسجّل مع `"trash": false`، فتُحذف القناة التي تغادر قائمة التشغيل بدلاً من حفظها في سلة المهملات الخاصة بـ rex. تُرسل كل قناة مع `channel` الخاص بها: الرقم والاسم والدليل. لقطة لكل القنوات، 100 في الطلب الواحد (أسبوع من الدليل لكل قناة) |

## غيّرها {#change-it}

- **بثوث ليست بصيغة HLS.** كثير من المزوّدين يقدمون أيضًا كل قناة بصيغة MPEG-TS (`.ts`). يقبل rex القناة الحية كبث HLS (`.m3u8`)، لذلك تتجاهل هذه الإضافة الباقي: اطلب من مزوّدك روابط HLS (غالبًا `output=m3u8` في رابط قائمة التشغيل).
- **أرقامك الخاصة.** عدّل الأرقام في `~/.rex-iptv.json` والإضافة متوقفة، وستُرسلها الجولة التالية.
- **الشعارات.** يصبح `tvg-logo` صورة القناة في مكتبتها. وتعرض شبكة الدليل الأرقام والأسماء.
- **دليل من مصدر آخر.** أي مصدر يعرف الجدول يمكنه ملء `guide`: واجهة JSON من مزوّد، أو جدول مباريات رياضية، أو حلقة ثابتة. يبني rex-live-sports أدلة من لوحة نتائج ESPN، انظر [البث المباشر مع rex](live-tv.md).

## استكشاف الأخطاء وإصلاحها {#troubleshooting}

| ما تراه | السبب | الحل |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | القناة من نوع MPEG-TS أو صيغة أخرى، أو أن بثها ردّ بخطأ (السبب يظهر في نهاية السطر) | استخدم رابط HLS المباشر للقناة. البث المتوقف يُعاد تجربته في الجولة التالية. |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`، أو `actively refused it` على Windows، أو `HTTP Error 403`) | البث لم يرد، أو رفض هذا الجهاز | تحقّق من الرابط في مشغّل على الجهاز نفسه. روابط IPTV كثيراً ما تعمل فقط من العنوان الذي سجّلت الدخول منه. |
| `no channel could be probed: not sending a snapshot` | لم ترد أي قناة: المزوّد متوقف، أو قائمة التشغيل فارغة | لا يُحذف شيء. تحقّق من `PLAYLIST`. |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` على Windows) | rex لا يعمل، أو أن `REX` ليس عنوانه | شغّل rex، أو صحّح `REX`. |
| `sync failed, ...: rex answered 409: ...more than half...` | أكثر من نصف القنوات خرجت من قائمة التشغيل، أو فشلت في فحصها، دفعة واحدة | إذا كان ذلك مقصوداً، شغّله مرة واحدة مع `REX_FORCE=1`. وإلا، انتظر حتى يعود المزوّد. |
| القناة ليس لها أي بيانات في الدليل | `tvg-id` الخاص بها لا يطابق أي `<channel id>` في الدليل، أو أن الدليل لا يحتوي على شيء لهذا الأسبوع | طابق `tvg-id` في قائمة التشغيل مع المعرّفات الموجودة في الدليل. |
| Live TV غير ظاهر في تطبيق Plex | لم تُرسل أي قناة بعد، أو أن التطبيق ليس Plex Web ولا Plex for Android، وهما التطبيقان اللذان جُرّبا | شغّل الإضافة، واستخدم Plex Web أو Plex for Android. |
| فشل Watch Now | rex لا يملك FFmpeg، أو توقف البث | سجلّ rex يوضح السبب. لإعداد FFmpeg، انظر [تحويل الفيديو](any-source.md#converting-video-optional). |

ما زلت عالقاً؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP).
