# Руководство: аддон для музыки {#tutorial-a-music-addon}

Этот учебник помещает папку с альбомами в библиотеку **Music**, которую воспроизводят Plexamp, Plex Web и Plex for Android.
Поддерживаются FLAC, MP3, AAC и другие распространённые форматы. Ваши файлы остаются на месте. Информацию об известных альбомах берём из MusicBrainz. Для неизвестных альбомов используем их теги и `cover.jpg`. Файл `.lrc` рядом с треком превращается в синхронизированный текст песни.

Это руководство опирается на [Building rex addons](addons.md) и его раздел [Музыка](addons.md#music). Если вы впервые делаете аддон, сначала прочитайте [руководство по домашним видео](addon-home-videos.md).

| Что нужно | Зачем |
|---|---|
| rex 2026.11.02 или новее, настроенный по [rex with your own app](any-source.md) (шаги с 1 по 3) и привязанный | rex запрашивает у Plex названия альбомов только после привязки |
| Python 3.8 или новее | Для аддона, только стандартная библиотека |
| `ffprobe` | Описывает каждый файл для rex и читает его теги. Входит в состав FFmpeg |
| Ваши альбомы, по одной папке на альбом | `Artist/Album/01 Song.flac` или любая вложенность: каждая папка с аудиофайлами считается альбомом |
| Теги или MusicBrainz Picard | Аддон берёт альбом и исполнителя из тегов каждого файла (иначе из названий папок). Файлы, размеченные [MusicBrainz Picard](https://picard.musicbrainz.org), уже содержат идентификатор релиза, и это самое надёжное совпадение |

В этом руководстве адрес rex записан как `192.168.1.20:32400`, а аддон запускается на той же машине, где работает rex.

## Шаг 1. Сохраните дополнение {#step-1-save-the-addon}

Сохраните это как `music.py`:

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

## Шаг 2. Заполните настройки {#step-2-fill-in-the-settings}

| Setting | Put |
|---|---|
| `FOLDER` | Ваша папка с музыкой, например `"/srv/music"` или `os.path.expanduser("~/Music")` |
| `REX` | Адрес rex |
| `LISTEN` | Оставьте `127.0.0.1`, если аддон работает на той же машине, что и rex; иначе укажите LAN IP этой машины |
| `NAME`, `LIBRARY` | Имя аддона в rex и название музыкальной библиотеки. После первого запуска оставьте `NAME` без изменений |

## Шаг 3. Запустите его {#step-3-run-it}

+++ Linux и macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**Что должно быть видно.** Для каждого альбома без release id в тегах выводится одна строка с тем, что ответил MusicBrainz, а в конце общее количество:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz принимает один запрос в секунду, поэтому первый запуск на большой коллекции занимает время: примерно по секунде на альбом. Каждый ответ сохраняется в `.rex/albums.json` в вашей папке с музыкой, и при следующих запусках ничего не запрашивается. Альбомы, тегированные Picard, никогда не проверяются.

Лог rex показывает, как каждый трек попадает в свой альбом:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Откройте Plexamp и выберите в качестве библиотеки библиотеку **Music** от rex (в Plex Web и Plex for Android она находится в More). У In Rainbows будет обложка из Plex, названия треков, а также фото и биография Radiohead, независимо от того, как называются ваши файлы. У Garage Demos отображаются имена из тегов и `cover.jpg` из папки. У песни с файлом `.lrc` с таким же именем отображаются текст, построчно по мере воспроизведения.

Чтобы он работал постоянно, настройте его так же, как аддон home videos: [Шаг 4](addon-home-videos.md#step-4-keep-it-running), только вместо `homevideos.py` используйте `music.py`.

## Как это работает {#how-it-works}

| Часть | Что делает |
|---|---|
| `Handler` | Отдаёт всё, что лежит под `/music/`: песни (с `Range`, так что перемотка работает мгновенно), их `.lrc`-тексты и обложки альбомов |
| `sync()`, first line | Регистрирует аддон с одной папкой, `music`, как музыкальную библиотеку: `"directories": [{"name": "music", "music": "Music"}]`. Без музыкальной библиотеки rex отказывается принимать любой трек |
| `album_items()` | Один элемент на песню: `"kind": "track"`, её номера `disc` и `track` (из тегов, а если их нет, то по порядку в папке), её вывод `ffprobe` и `ids.mbid`, id релиза альбома в MusicBrainz. Plex показывает свой трек под этими номерами в этом релизе, поэтому номера должны быть правильными |
| `release_id()` | Находит id релиза для альбома, у которого его нет: ищет в MusicBrainz по названию альбома и исполнителю и берёт первый официальный релиз, где столько же треков, сколько в папке. Альбом выходит в многих релизах (по одному на страну, делюкс-издания), подойдёт любой, где есть ваши треки, он и задаёт альбом |
| `display` | Названия альбома из тегов и его обложка, которая показывается только тогда, когда Plex её не знает |
| `lyrics` | Файл `.lrc` (с таймингом) или `.txt` с именем песни рядом, отправляется как `[{"path": ..., "size": ...}]`. rex перечитывает его только тогда, когда меняется размер |
| `sync()`, the rest | Снимок каждой песни, по 200 за запрос: удалённый альбом уходит из библиотеки при следующем цикле (каждые десять минут) |

rex не читает теги сам. Всё, что показывает Plex, берётся из id релиза или из вашего `display`, если у Plex его нет.

## Как это изменить {#change-it}

- **Другая структура.** Альбом, разбитый на папки с дисками (`CD1/`, `CD2/`), для этого аддона — это два альбома, и в каждом слишком мало треков, чтобы их сопоставить. Объедини такие папки в `albums()` и отправь один `release` для всех их файлов; см. [Музыка](addons.md#music).
- **Исполнители со своими картинками.** Отправь `display.artist.poster` и зарегистрируй с `"artwork": "source"`; см. [Ещё о твоём аддоне](addon-more.md#artist-pictures).
- **Плейлисты.** Отправь позицию каждой песни в плейлисте, и rex сам создаст плейлист; см. [Ещё о твоём аддоне](addon-more.md#collections-and-playlists).
- **Громкость.** Если ты измеряешь громкость каждой песни, отправляй её как `loudness` в именах Plex; см. [Музыка](addons.md#music). rex сам ничего не измеряет.

## Устранение неполадок {#troubleshooting}

| Вы видите | Почему | Что делать |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | Официального релиза с таким названием и исполнителем и вашим количеством треков нет: пропущена песня, добавлен бонусный трек, опечатка в тегах или альбом не значится в MusicBrainz | Исправьте теги или папку, затем удалите строку этого альбома из `.rex/albums.json` (или весь файл), чтобы его спросили снова. Или проставьте теги альбому через Picard |
| У альбома неверные названия песен | Найденный релиз содержит ваше количество треков, но в другом порядке (другое издание) | Проставьте теги альбому через Picard, он запишет точный релиз |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz был занят или недоступен | Ничего не делайте: в следующем цикле запрос повторится |
| Альбомы показывают названия из тегов, хотя Plex их знает | rex не подключён к вашему аккаунту, или id релиза не соответствует ничему в Plex | Подключите rex: [шаг 3 инструкции rex со своим приложением](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | Библиотека была удалена в одном из приложений Plex | Добавьте её обратно в приложении Plex: Add Library, Music, и выберите папку `music`, которую предлагает список папок |
| `sync failed, ...: rex answered 409: ...more than half...` | Больше половины песен пропало из папки | Если это было задумано, запустите один раз с `REX_FORCE=1`; если нет, исправьте `FOLDER` |
| Нет текстов песен | Имя файла `.lrc` не совпадает с именем песни, либо песня была отправлена до того, как файл появился | Назовите его так же, как песню (`01 - Song.flac`, `01 - Song.lrc`); в следующем цикле он отправится |

Всё равно застряли? Спросите на форуме **rex-support** в [Discord](https://discord.com/invite/7u4YjMThXP).
