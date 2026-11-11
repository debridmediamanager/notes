# درس تعليمي: إضافة لمقاطع الفيديو المنزلية {#tutorial-a-home-videos-addon}

يشرح هذا الدليل كيفية بناء إضافة rex واحدة بملف Python واحد. تضع الإضافة مقاطع هاتفك وملفات الكاميرا أو تسجيلات الشاشة
في مكتبة **Home Videos** داخل كل تطبيق Plex. يحصل كل فيديو على عنوان وتاريخ وصورة مصغّرة.
لا يُنسخ أي شيء ولا يُرفع. تقرأ rex الملف من الإضافة عندما تضغط على تشغيل.

هذه أقصر نسخة تعمل من [Building rex addons](addons.md) الخطوات من 1 إلى 5. تقول هذه الصفحة ما تكتبه.
أما تلك الصفحة فتشرح السبب. تستخدم دروس [الموسيقى](addon-music.md) و[IPTV](addon-iptv.md) الهيكل نفسه.

| تحتاج إلى | السبب |
|---|---|
| rex، مُعدّة كما في [rex مع تطبيقك الخاص](any-source.md) (الخطوات من 1 إلى 3) | هنا تظهر المكتبة. يجب أن تكون مُسجَّلة (claimed) حتى ترى تطبيقات Plex المكتبة |
| Python 3.8 أو أحدث | الإضافة نفسها. تستخدم مكتبة Python القياسية فقط |
| `ffprobe` و`ffmpeg` | يصف `ffprobe` كل فيديو لـ rex، ويقتطع `ffmpeg` الصورة المصغّرة. يأتي الاثنان مع FFmpeg |
| مجلد فيه فيديوهات، على الجهاز الذي يشغّل الإضافة | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`، في أي مجلدات فرعية |

يكتب هذا الدليل عنوان rex كـ `192.168.1.20:32400` ويشغّل الإضافة على الجهاز نفسه الذي يعمل عليه rex. ضع عنوانك مكانه.

## الخطوة 1. احفظ الإضافة {#step-1-save-the-addon}

**ما الذي يفعله؟** يمنحك الإضافة كاملةً: خادم ويب صغير لفيديوهاتك وحلقة تُخبر rex بها كل خمس دقائق.

احفظ هذا الملف باسم `homevideos.py`:

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

## الخطوة 2. املأ الإعدادات {#step-2-fill-in-the-settings}

**ما الذي يفعله.** يوجّه الإضافة إلى مجلدك وإلى rex.

غيّر الأسطر الأربعة التي تلي docstring:

| الإعداد | ضع |
|---|---|
| `FOLDER` | مجلد الفيديوهات الخاص بك، مثل `"/srv/videos/home"`، أو `os.path.expanduser("~/Videos/Home")` لمجلد داخل مجلدك الشخصي |
| `REX` | عنوان rex، كما تفتحه في الخطوة 3 من [rex مع تطبيقك الخاص](any-source.md) |
| `LISTEN` | المكان الذي تستجيب فيه الإضافة. أبقِ `127.0.0.1` إذا كانت الإضافة تعمل على الجهاز نفسه الذي يعمل عليه rex. على جهاز آخر، ضع عنوان LAN IP لذلك الجهاز (يقرأ rex الفيديوهات منه، لذا يجب أن يكون قابلاً للوصول من rex) |
| `NAME`, `LIBRARY` | اسم الإضافة داخل rex وعنوان المكتبة. أبقِ `NAME` كما هو بعد أن تشغّلها مرة: صفوف rex تابعة له |

## الخطوة 3. شغّلها {#step-3-run-it}

+++ Linux و macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**ما يجب أن تراه.** في التشغيل الأول يفحص rex كل فيديو ويقتطع منه صورة ثابتة، ثم يرسلها:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

يُظهر سجل rex المصدر والمكتبة الجديدة، ثم الفيديوهات:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

افتح تطبيق Plex: **Home Videos** موجودة تحت More (ثبّتها لتظهر في Home). لكل فيديو اسم ملفه كعنوان، والمجلد الذي يوجد فيه كملخص، وتاريخ الملف كتاريخ الإصدار، وصورة ثابتة من نقطة بعد عُشر مدة الفيديو كملصق وكخلفية. اضغط على تشغيل: يعمل الفيديو، والتنقل داخله فوري.

أوقف الإضافة بالضغط على Ctrl+C. شغّلها مرة أخرى فترسل نفس الفيديوهات بالحالة `unchanged` دون فحص أي شيء: تُحفظ نتائج الفحص والصور الثابتة في مجلد `.rex` داخل مجلد فيديوهاتك.

## الخطوة 4. أبقها تعمل {#step-4-keep-it-running}

لازم الإضافة تشتغل في كل مرة حد يتفرج، لأن rex بيقرأ كل فيديو منها.

+++ Linux
اعمل ملف `~/.config/systemd/user/homevideos.service`، واكتب فيه مسار المجلد اللي حفظت فيه الإضافة:

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

لو شغّلت `sudo loginctl enable-linger "$USER"` عشان rex، الإضافة هتفضل شغالة حتى بعد ما تسجّل خروج كمان.
+++ macOS و Windows
ابدأها بنفس الطريقة اللي بتبدأ بيها rex في الخطوة 1 من [rex with your own app](any-source.md#step-1-install-rex): LaunchAgent على macOS، أو scheduled task على Windows، مع `python3 homevideos.py` (`python homevideos.py` على Windows) كأمر، ومجلد الإضافة كمجلد شغل.
+++

## كيف تعمل {#how-it-works}

كل جزء من الملف هو خطوة واحدة من [بناء إضافات rex](addons.md):

| الجزء | الخطوة | ما الذي يفعله |
|---|---|---|
| `Handler` | [1. تقديم الملفات](addons.md#step-1-serve-the-bytes) | يرد على `GET /home/<file>` بالملف، وعلى طلب `Range` بالبايتات المطلوبة فقط (`206`)، حتى لا يضطر التقديم إلى القراءة من البداية عند التنقل داخل الفيديو. `GET /stills/<name>.jpg` يقدّم الملصقات. أي شيء خارج المجلد يُرد عليه بـ `404` |
| `sync()`، السطر الأول | [2. التسجيل في rex](addons.md#step-2-register-with-rex) | يرسل `PUT /rex/sources/homevideos` مع عنوان الإضافة ومجلد واحد، `home`، كمكتبة أفلام. يُرسل في كل جولة، والتسجيل مرة أخرى لا يغيّر شيئًا |
| `describe()` | [3. وصف كل فيديو](addons.md#step-3-describe-each-video) | الـ`id` الخاص بالفيديو هو مساره في مجلدك، لذا إذا أعدت تسمية ملف يصبح عنوانًا جديدًا دون سجل المشاهدة الخاص به. `kind: "movie"` يجعل كل فيديو فيلمًا مستقلًا، فلا حاجة لترقيم أي شيء. `media_info` هو خرج `ffprobe` كاملًا |
| `describe()`، `display` | [4. تسميته وتزيينه](addons.md#step-4-name-and-dress-it) | العنوان والملخص والتاريخ والصور. رابط الصورة يكون تحت عنوان الإضافة نفسه، وهذا هو المكان الوحيد على شبكتك الذي يجلب منه rex الصور |
| `sync()`، البقية | [5. إرساله](addons.md#step-5-send-it) | لقطة لكل فيديو، على دفعات من 200 عنصر في كل طلب، لذا أي فيديو تحذفه من المجلد يغادر المكتبة في الجولة التالية |

الحراس تمنع لحظة سيئة من تفريغ مكتبتك: مجلد فارغ أو مفقود لا يرسل شيئًا، والفيديو الذي لا يستطيع `ffprobe` قراءته يُتخطى ويُسجَّل، وrex نفسه يرفض أي لقطة قد تزيل أكثر من نصف الفيديوهات.

## غيّرها {#change-it}

- **المسلسلات بدلاً من الأفلام.** أرسل `"kind": "episode"` مع أرقام `season` و`episode`، و`display.show`، وسجّل المجلد باسم `"shows"`. رقّم الحلقات بحيث لا يغيّر فيديو جديد ترتيب الباقي: حسب التاريخ، لا حسب موقعها في المجلد. انظر [الخطوة 3](addons.md#step-3-describe-each-video).
- **عناوينك الخاصة.** اقرأها من ملف مرافق، أو من وسوم الفيديو (`media_info["format"]["tags"]`)، بدلاً من اسم الملف.
- **الترجمات والمجموعات وعلامات الفصول.** ملفات `.srt` بجانب الفيديو، ومجموعة لكل مجلد، وعلامات للفصول: انظر [المزيد من إضافتك](addon-more.md).
- **السماح لتطبيقات Plex بالحذف.** أضف `do_DELETE` يحذف الملف ويرد بالرمز `204`. بدونها ترد الإضافة بالرمز `501`، ويبقي rex الفيديو (سجله يقول `DELETE refused by the source, row kept: home/... at homevideos: 501`)، ويخبرك التطبيق أنه تعذّر حذفه.

## استكشاف الأخطاء وإصلاحها {#troubleshooting}

| ما تراه | السبب | الحل |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex غير قيد التشغيل، أو أن `REX` ليس عنوانه | شغّل rex، أو صحّح `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | أكثر من نصف الفيديوهات التي يملكها rex من هذه الإضافة لم تعد في المجلد: قرص غير مركّب، أو `FOLDER` خاطئ، أو تنظيف كبير | إذا كنت تقصد ذلك، شغّل الأمر مرة واحدة هكذا: `REX_FORCE=1 python3 homevideos.py`. وإلا فأصلح المجلد؛ لم يُحذف أي شيء |
| `no videos found in ...: not sending a snapshot` | المجلد فارغ، أو مفقود، أو لا يحتوي على ملفات فيديو | صحّح `FOLDER` |
| `skipped <file>: ...` | تعذّر على `ffprobe` قراءته (ملف تالف أو غير مكتمل) | سيُعاد المحاولة في الجولة التالية |
| `rejected: {'id': ..., 'reason': ...}` | رفض rex فيديو واحدًا، وذكر السبب | راجع [بناء إضافات rex، استكشاف الأخطاء وإصلاحها](addons.md#troubleshooting) |
| المكتبة موجودة لكن الملصقات فارغة | `ffmpeg` غير مثبّت، أو أن rex لا يستطيع الوصول إلى `LISTEN` | ثبّت FFmpeg؛ وإذا كانت الإضافة على جهاز آخر، فاضبط `LISTEN` على عنوان IP المحلي (LAN) لذلك الجهاز، وليس `127.0.0.1` |
| فشل التشغيل، وسجل rex يقول `PART ... upstream failed: <urlopen error Connection refused ...>` | الإضافة غير قيد التشغيل، أو أن rex لا يستطيع الوصول إلى `LISTEN` | شغّل الإضافة. وإذا كانت على جهاز آخر، فاضبط `LISTEN` على عنوان IP المحلي لذلك الجهاز |

ما زلت عالقًا؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP).
