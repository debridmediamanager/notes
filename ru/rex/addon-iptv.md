# Руководство: дополнение для IPTV {#tutorial-an-iptv-addon}

Этот урок превращает IPTV-плейлист (M3U) и телепрограмму (XMLTV) в каналы **Live TV** в Plex Web и Plex для Android. Каждый канал сохраняет свой номер и программу передач. Работает с M3U-каналами, которые используют HLS (`.m3u8`), и с любым XMLTV-гидом, который их называет.

Он опирается на [Создание аддонов rex](addons.md) и его раздел [Live TV](addons.md#live-tv). Если ты впервые делаешь аддон, сначала прочитай [инструкцию по домашним видео](addon-home-videos.md). Для спортивных трансляций используй [Live TV с rex](live-tv.md).

| Что нужно | Зачем |
|---|---|
| rex 2026.11.02 или новее, настроенный, как в [rex со своим приложением](any-source.md) (шаги с 1 по 3), и привязанный к аккаунту | Live TV есть в приложениях Plex |
| FFmpeg там, где работает rex | rex конвертирует канал, пока кто-то его смотрит. См. [Конвертация видео](any-source.md#converting-video-optional) |
| Python 3.8 или новее и `ffprobe` там, где работает аддон | Сам аддон использует только стандартную библиотеку. `ffprobe` раз в сутки проверяет каждый канал |
| M3U-плейлист | URL или файл со строками `#EXTINF`. `tvg-id` связывает канал с программой передач, `tvg-chno` задает его номер, `tvg-logo` — логотип, `group-title` — группу |
| XMLTV-гид (необязательно) | URL или файл, в gzip или без него. Без него каналы показываются без программы передач |

В этом уроке адрес rex указан как `192.168.1.20:32400`, а аддон запускается на той же машине, где работает rex.

## Шаг 1. Сохраните дополнение {#step-1-save-the-addon}

Сохрани это как `iptv.py`:

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

## Шаг 2. Заполните настройки {#step-2-fill-in-the-settings}

| Настройка | Что указать |
|---|---|
| `PLAYLIST` | URL вашего M3U или путь к нему на этой машине |
| `GUIDE` | URL или путь к вашему XMLTV-гиду. Ссылка на гид от провайдера обычно заканчивается на `xmltv.php`, `.xml` или `.xml.gz` |
| `GROUPS` | Только те группы, которые вы хотите, как их значения `group-title`: `["News", "Sports"]`. Оставьте `[]` для каждого канала. Каждый канал проверяется с помощью `ffprobe` (несколько секунд на канал), так что список из тысяч займёт много времени: выбирайте группы |
| `REX`, `LISTEN` | Адрес rex и то, где аддон принимает запросы (`127.0.0.1`, если аддон работает на той же машине, что и rex) |
| `NAME`, `LIBRARY` | Имя аддона в rex и название библиотеки, в которой также лежат каналы. Не меняйте `NAME` после первого запуска |
| `FIRST` | Номер, который получит первый канал без `tvg-chno`. Выбирайте номера, не пересекающиеся с номерами других аддонов Live TV, например `500` |

## Шаг 3. Запустите его {#step-3-run-it}

+++ Linux and macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**Что должно появиться.** Строка для каждого канала, который не удалось проверить, а затем итог:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

В логе rex видно, что библиотека создана для каналов и какие каналы пришли:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

В Plex Web или Plex для Android откройте **Live TV**: вкладка с именем вашего rex покажет каналы под их номерами и программу передач от трёх часов назад до недели вперёд. Выберите то, что идёт в эфире, и нажмите **Watch Now**: через несколько секунд всё запустится, пока rex начнёт конвертацию. Раздел What's On показывает, что идёт сейчас и что будет позже; эпизод из категории `News` или `Sports` в программе передач попадает на эти полки.

Аддон проверяет плейлист и обновляет программу передач каждые 30 минут. Чтобы он работал постоянно, настройте его так же, как аддон для домашних видео: [Step 4](addon-home-videos.md#step-4-keep-it-running), только вместо `homevideos.py` используйте `iptv.py`.

## Как это работает {#how-it-works}

| Часть | Что делает |
|---|---|
| `channels()` | Читает плейлист: каждую строку `#EXTINF` и URL под ней. Ключ канала, который в rex служит его `id` навсегда, это его `tvg-id` (или его имя) |
| `Handler` | Отдаёт `/tv/<key>.m3u8` как редирект на поток канала. rex переходит по нему каждый раз, когда кто-то включает канал, а аддон ищет поток именно в этот момент, поэтому ссылки, которые истекают, продолжают работать |
| `best_variant()` | Выбирает лучшее качество из потока, в котором есть несколько вариантов (HLS master playlist), чтобы воспроизводилось то, что было проверено |
| `probe()` | `ffprobe` потока, результат хранится сутки. rex нужен он, чтобы узнать картинку и звук канала, а канал считается прямым эфиром, потому что у его probe нет длительности. Поток, который не HLS или не отвечает, пропускается в этом раунде |
| `guides()` | Читает файл XMLTV один раз за раунд и оставляет программы каждого канала с трёх часов назад до недели вперёд: название, описание, категории, картинку и `previously-shown` (повтор). Программа с номером эпизода в `xmltv_ns` становится эпизодом своего сериала, нумеруемым с 1 (XMLTV считает с 0) |
| `number_for()` | Присваивает каждому каналу номер один раз и хранит его в `~/.rex-iptv.json`: берётся `tvg-chno` из плейлиста, если его не использует другой канал, иначе следующий свободный номер начиная с `FIRST`. Избранное в приложениях Plex хранится по номеру, поэтому канал должен его сохранять |
| `sync()` | Регистрируется с `"trash": false`, поэтому канал, который пропал из плейлиста, удаляется, а не попадает в корзину rex. Каждый канал отправляется с `channel`: номер, название и программа передач. Снимок всех каналов, по 100 за запрос (неделя программы передач на каждый) |

## Как это изменить {#change-it}

- **Потоки, которые не HLS.** Многие провайдеры также предлагают каждый канал в формате MPEG-TS (`.ts`). rex принимает живой канал как HLS-поток (`.m3u8`), поэтому этот аддон пропускает остальные: попросите у провайдера ссылки HLS (часто это `output=m3u8` в URL плейлиста).
- **Свои номера.** Меняйте номера в `~/.rex-iptv.json`, пока аддон остановлен; при следующем цикле они применятся.
- **Логотипы.** `tvg-logo` становится картинкой канала в его библиотеке. В сетке программы отображаются номера и названия.
- **Программа из другого источника.** Всё, что знает расписание, может заполнить `guide`: JSON API провайдера, спортивное расписание или фиксированный цикл. rex-live-sports строит программу по табло ESPN, см. [Live TV with rex](live-tv.md).

## Устранение неполадок {#troubleshooting}

| Что видите | Почему | Как исправить |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | Канал в формате MPEG-TS или другом, либо его поток ответил ошибкой (причина в конце строки) | Используйте HLS-ссылку канала; поток, который не работает, будет проверен снова в следующем раунде |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`, `actively refused it` в Windows или `HTTP Error 403`) | Поток не ответил или отказал этой машине | Проверьте ссылку в плеере на той же машине. IPTV-ссылки часто работают только с того адреса, с которого был выполнен вход |
| `no channel could be probed: not sending a snapshot` | Ни один канал не ответил: провайдер недоступен или плейлист пуст | Ничего не удаляется. Проверьте `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` в Windows) | rex не запущен или `REX` указывает не на его адрес | Запустите rex или исправьте `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | Больше половины каналов сразу пропали из плейлиста или не прошли проверку | Если это было задумано, запустите один раз с `REX_FORCE=1`; иначе дождитесь, пока провайдер вернётся |
| У канала нет программы в гиде | Его `tvg-id` не совпадает ни с одним `<channel id>` в гиде, или в гиде нет данных на эту неделю | Сопоставьте `tvg-id` из плейлиста с id в гиде |
| В приложении Plex нет Live TV | Каналы ещё не были отправлены, или приложение не Plex Web и не Plex for Android, а единственные протестированные | Запустите аддон и используйте Plex Web или Plex for Android |
| Watch Now не работает | В rex нет FFmpeg, либо поток остановился | В логе rex написано, в чём причина. Про FFmpeg см. [Converting video](any-source.md#converting-video-optional) |

Всё ещё не получается? Задайте вопрос на форуме **rex-support** в [Discord](https://discord.com/invite/7u4YjMThXP).
