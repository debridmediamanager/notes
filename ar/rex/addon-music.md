# درس تعليمي: إضافة للموسيقى {#tutorial-a-music-addon}

يشرح هذا الدرس كيف تضع مجلدًا من الألبومات في مكتبة **Music** يشغّلها Plexamp وPlex Web وPlex for Android.
يدعم FLAC وMP3 وAAC وغيرها من الملفات الشائعة. تبقى ملفاتك في مكانها. يوفّر MusicBrainz تفاصيل الألبومات المعروفة. أما الألبومات غير المعروفة فتستخدم وسومها و`cover.jpg`. ويتحوّل ملف `.lrc` الموجود بجوارها إلى كلمات أغانٍ متزامنة مع التوقيت.

يتبع هذا الدرس [بناء إضافات rex](addons.md) وقسم [الموسيقى](addons.md#music) فيه. اقرأ [الدرس الخاص بمقاطع الفيديو المنزلية](addon-home-videos.md) أولًا إذا كانت هذه أول إضافة تبنيها.

| ما تحتاجه | السبب |
|---|---|
| rex 2026.11.02 أو أحدث، مُعدّ كما في [rex مع تطبيقك الخاص](any-source.md) (الخطوات من 1 إلى 3) ومربوط بحسابك | rex يطلب من Plex أسماء الألبومات فقط بعد أن يُربط بحسابك |
| Python 3.8 أو أحدث | الإضافة، وتعتمد على المكتبة القياسية فقط |
| `ffprobe` | يصف كل ملف لـ rex ويقرأ وسومه. يأتي مع FFmpeg |
| ألبوماتك، مجلد لكل ألبوم | `Artist/Album/01 Song.flac`، أو بأي عمق: كل مجلد يحتوي ملفات صوتية يُعدّ ألبومًا |
| الوسوم، أو MusicBrainz Picard | تقرأ الإضافة اسم الألبوم والفنان من وسوم كل ملف (وإلا فمن أسماء المجلدات). الملفات الموسومة بواسطة [MusicBrainz Picard](https://picard.musicbrainz.org) تحمل معرّف إصدارها بالفعل، وهي أدق طريقة للمطابقة |

يفترض هذا الدرس أن عنوان rex هو `192.168.1.20:32400`، وأن الإضافة تعمل على الجهاز نفسه الذي يعمل عليه rex.

## الخطوة 1. احفظ الإضافة {#step-1-save-the-addon}

احفظ هذا باسم `music.py`:

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

## الخطوة 2. املأ الإعدادات {#step-2-fill-in-the-settings}

| الإعداد | ضَع |
|---|---|
| `FOLDER` | مجلد موسيقاك، مثل `"/srv/music"` أو `os.path.expanduser("~/Music")` |
| `REX` | عنوان rex |
| `LISTEN` | أبقِ `127.0.0.1` مع الإضافة على جهاز rex؛ وإلا فعنوان IP للشبكة المحلية لذلك الجهاز |
| `NAME`, `LIBRARY` | اسم الإضافة في rex وعنوان مكتبة الموسيقى. أبقِ `NAME` كما هو بعد أن تشغّلها |

## الخطوة 3. شغّلها {#step-3-run-it}

+++ Linux and macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**ما الذي ستراه.** لكل ألبوم ليس له release id في وسومه، ستظهر سطر واحد يحمل ما ردّ به MusicBrainz، ثم المجموع في الأخير:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

يقبل MusicBrainz طلبًا واحدًا في الثانية، لذلك يستغرق التشغيل الأول على مجموعة كبيرة وقتًا طويلًا: نحو ثانية لكل ألبوم. يُحفظ كل رد في `.rex/albums.json` داخل مجلد الموسيقى لديك، ولا تطلب التشغيلات اللاحقة أي شيء. الألبومات الموسومة بواسطة Picard لا يُبحث عنها أبدًا.

سجل rex يُظهر وصول كل مقطع إلى ألبومه:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

افتح Plexamp واختر مكتبة **Music** الخاصة بـ rex كمكتبة له (تعرضها Plex Web وPlex for Android تحت More). يظهر لألبوم In Rainbows غلاف Plex وأسماء مقاطعه وصورة Radiohead وسيرتها الذاتية، مهما كانت أسماء ملفاتك. يعرض Garage Demos أسماء وسومه وملف `cover.jpg` الموجود في مجلده. الأغنية التي لها ملف `.lrc` بالاسم نفسه تعرض كلماتها، سطرًا سطرًا أثناء التشغيل.

لإبقائه يعمل، اضبطه مثل إضافة الفيديوهات المنزلية: [الخطوة 4](addon-home-videos.md#step-4-keep-it-running)، مع `music.py` بدلًا من `homevideos.py`.

## كيف تعمل {#how-it-works}

| الجزء | وظيفته |
|---|---|
| `Handler` | يقدّم كل شيء تحت `/music/`: الأغاني (مع `Range`، فيصبح التنقّل داخل المقطع فورياً)، وملفات الكلمات `.lrc` الخاصة بها، وأغلفة الألبومات |
| `sync()`، السطر الأول | يسجّل الإضافة بمجلد واحد، `music`، كمكتبة موسيقى: `"directories": [{"name": "music", "music": "Music"}]`. من دون مكتبة موسيقى يرفض rex كل مقطع |
| `album_items()` | عنصر واحد لكل أغنية: `"kind": "track"`، ورقما `disc` و`track` الخاصان بها (من وسومها، وإلا فمن موضعها في المجلد)، ومخرجات `ffprobe` الخاصة بها، و`ids.mbid`، وهو معرّف إصدار الألبوم في MusicBrainz. يعرض Plex مقطعه الخاص عند هذين الرقمين في ذلك الإصدار، لذا يجب أن تكون الأرقام صحيحة |
| `release_id()` | يجد معرّف الإصدار لألبوم لا يملك واحداً، عبر بحث في MusicBrainz باسم الألبوم والفنان، مع الإبقاء على أول إصدار رسمي يحتوي على عدد المقاطع نفسه الموجود في المجلد. يصدر الألبوم في إصدارات كثيرة (واحد لكل دولة، وطبعات deluxe)، وأي إصدار يحتوي على مقاطعك يحدد اسم الألبوم |
| `display` | أسماء الألبوم من الوسوم، وغلافه، ويُعرض الغلاف فقط عندما لا يعرف Plex الألبوم |
| `lyrics` | ملف `.lrc` (مزامَن بالتوقيت) أو `.txt` يحمل اسم الأغنية بجانبه، ويُرسل بالشكل `[{"path": ..., "size": ...}]`. يعيد rex قراءته فقط عندما يتغيّر حجمه |
| `sync()`، البقية | لقطة لكل أغنية، 200 في كل طلب: الألبوم الذي تحذفه يخرج من المكتبة في الجولة التالية (كل عشر دقائق) |

لا يقرأ rex الوسوم بنفسه. كل ما يعرضه Plex يأتي من معرّف الإصدار، أو من `display` الذي تكتبه عندما لا يملك Plex أي معلومات عن الألبوم.

## غيّرها {#change-it}

- **تخطيط آخر.** مجلد الألبوم المقسّم إلى مجلدات أقراص (`CD1/` و`CD2/`) يعتبره هذه الإضافة ألبومين، وكل واحد منهما فيه عدد مسارات قليل لا يكفي للمطابقة. اجمع هذه المجلدات في `albums()` وأرسل `release` واحدًا لكل ملفاتها. راجع [Music](addons.md#music).
- **الفنانون بصورهم الخاصة.** أرسل `display.artist.poster` وسجّل بـ `"artwork": "source"`. راجع [More from your addon](addon-more.md#artist-pictures).
- **قوائم التشغيل.** أرسل مكان كل أغنية في قائمة التشغيل، وسيُنشئ rex قائمة التشغيل بنفسه. راجع [More from your addon](addon-more.md#collections-and-playlists).
- **مستوى الصوت.** إذا كنت تقيس مستوى صوت كل أغنية، أرسله باسم `loudness` كما في Plex. راجع [Music](addons.md#music). rex لا يقيس أي شيء بنفسه.

## استكشاف الأخطاء وإصلاحها {#troubleshooting}

| ما تراه | السبب | الحل |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | لا يوجد إصدار رسمي بهذا العنوان والفنان بعدد مقاطعك: أغنية ناقصة، أو مقطع إضافي، أو خطأ مطبعي في الوسوم، أو ألبوم لا يدرجه MusicBrainz | صحّح الوسوم أو المجلد، ثم احذف سطر ذلك الألبوم من `.rex/albums.json` (أو الملف كله) ليُسأل من جديد. أو ضع وسوم الألبوم باستخدام Picard |
| تظهر أسماء أغانٍ خاطئة في ألبوم | الإصدار الذي وُجد يحتوي على عدد مقاطعك لكن بترتيب مختلف (نسخة مختلفة) | ضع وسوم الألبوم باستخدام Picard، فهو يكتب الإصدار الدقيق |
| `MusicBrainz did not answer for ...: asking again next round` | كان MusicBrainz مشغولاً أو غير متاح | لا شيء: الجولة التالية ستسأل من جديد |
| تظهر الألبومات بأسماء وسومها رغم أن Plex يعرفها | rex غير مُفعّل، أو أن معرّف الإصدار لا يشير إلى شيء يعرفه Plex | فعّل rex: [الخطوة 3 من rex مع تطبيقك الخاص](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | تم حذف المكتبة من أحد تطبيقات Plex | أعدها من تطبيق Plex: Add Library، ثم Music، واختر مجلد `music` الذي تعرضه قائمة المجلدات |
| `sync failed, ...: rex answered 409: ...more than half...` | أكثر من نصف الأغاني لم تعد موجودة في المجلد | إن كنت تقصد ذلك، شغّل مرة واحدة مع `REX_FORCE=1`، وإلا فأصلح `FOLDER` |
| لا توجد كلمات أغانٍ | اسم ملف `.lrc` يختلف عن اسم الأغنية، أو أن الأغنية أُرسلت قبل وصول الملف | سمّه مثل اسم الأغنية (`01 - Song.flac`، `01 - Song.lrc`)، والجولة التالية سترسله |

ما زلت عالقاً؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP).
