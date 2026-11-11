# Руководство: дополнение для домашних видео {#tutorial-a-home-videos-addon}

Этот урок создаёт аддон rex в одном Python-файле. Он добавляет ваши клипы с телефона, файлы с камеры или записи экрана в библиотеку **Home Videos** во всех приложениях Plex. Для каждого видео есть название, дата и постер-кадр.
Ничего не копируется и не загружается. rex читает файл из вашего аддона, когда вы нажимаете «играть».

Это самая короткая рабочая версия [Building rex addons](addons.md), шаги с 1 по 5. На этой странице написано, что именно набирать.
Там объясняется, почему. Уроки [music](addon-music.md) и [IPTV](addon-iptv.md) используют тот же каркас.

| Что нужно | Зачем |
|---|---|
| rex, настроенный как в [rex with your own app](any-source.md) (шаги с 1 по 3) | Там появляется библиотека. Claimed, чтобы приложения Plex её видели |
| Python 3.8 или новее | Аддон. Он использует только стандартную библиотеку Python |
| `ffprobe` и `ffmpeg` | `ffprobe` описывает каждое видео для rex, `ffmpeg` вырезает постер-кадр. Оба входят в FFmpeg |
| Папка с видео на машине, где запущен аддон | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`, в любых подпапках |

На этой странице адрес rex записан как `192.168.1.20:32400`, а аддон запускается на той же машине, что и rex. Подставьте свои значения.

## Шаг 1. Сохраните дополнение {#step-1-save-the-addon}

**Что делает.** Даёт весь аддон целиком: небольшой веб-сервер для ваших видео и цикл, который сообщает rex о них каждые пять минут.

Сохраните это как `homevideos.py`:

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

## Шаг 2. Заполните настройки {#step-2-fill-in-the-settings}

**Что делает.** Указывает аддону вашу папку и ваш rex.

Измените четыре строки под докстрингом:

| Настройка | Что указать |
|---|---|
| `FOLDER` | Папка с вашими видео, например `"/srv/videos/home"`, или `os.path.expanduser("~/Videos/Home")`, если папка находится в вашей домашней директории |
| `REX` | Адрес rex, как вы открываете его на шаге 3 в [rex с вашим собственным приложением](any-source.md) |
| `LISTEN` | Где аддон отвечает. Оставьте `127.0.0.1`, если аддон работает на той же машине, что и rex. На другой машине укажите LAN IP этой машины (rex читает видео с неё, поэтому rex должен до неё достучаться) |
| `NAME`, `LIBRARY` | Имя аддона в rex и название библиотеки. Не меняйте `NAME` после первого запуска: строки rex привязаны к нему |

## Шаг 3. Запустите его {#step-3-run-it}

+++ Linux и macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**Что вы должны увидеть.** При первом запуске rex проверяет каждое видео и вырезает из него кадр, а затем отправляет их:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

Лог rex показывает источник и новую библиотеку, а затем видео:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Откройте приложение Plex: **Home Videos** находится в разделе More (закрепите его, чтобы он появился на Home). У каждого видео в качестве названия стоит имя файла, в качестве описания — папка, в которой оно лежит, в качестве даты выхода — дата файла, а в качестве постера и фона — кадр с отметки в одну десятую пути. Запустите воспроизведение: видео играет, а перемотка работает мгновенно.

Остановите аддон сочетанием Ctrl+C. При повторном запуске он отправит те же видео со статусом `unchanged` и ничего не будет проверять: пробы и кадры хранятся в папке `.rex` внутри папки с вашими видео.

## Шаг 4. Пусть работает постоянно {#step-4-keep-it-running}

Дополнение должно работать, когда кто-то смотрит: rex читает из него каждое видео.

+++ Linux
Создай `~/.config/systemd/user/homevideos.service` и укажи папку, в которую ты сохранил дополнение:

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

Если ты для rex выполнил `sudo loginctl enable-linger "$USER"`, дополнение продолжит работать и после выхода из системы.
+++ macOS и Windows
Запусти его так же, как запускаешь rex на шаге 1 в [rex с собственным приложением](any-source.md#step-1-install-rex): LaunchAgent в macOS или запланированная задача в Windows, с `python3 homevideos.py` (`python homevideos.py` в Windows) в качестве команды и папкой дополнения как рабочей папкой.
+++

## Как это работает {#how-it-works}

Каждая часть файла — это один шаг в [Создании дополнений для rex](addons.md).

| Часть | Шаг | Что делает |
|---|---|---|
| `Handler` | [1. Отдача байтов](addons.md#step-1-serve-the-bytes) | Отвечает на `GET /home/<file>` самим файлом, а на запрос с `Range` отдаёт только нужные байты (`206`), так что перемотка не читает всё с начала. `GET /stills/<name>.jpg` отдаёт постеры. Всё, что лежит вне папки, получает `404` |
| `sync()`, первая строка | [2. Регистрация](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` с адресом дополнения и одной директорией, `home`, как медиатекой. Отправляется каждый раунд: повторная регистрация ничего не меняет |
| `describe()` | [3. Описание каждого видео](addons.md#step-3-describe-each-video) | `id` видео — это его путь в твоей папке, так что если переименуешь файл, он станет новым тайтлом, без истории просмотра. `kind: "movie"` делает каждое видео отдельным фильмом, так что нумеровать ничего не нужно. `media_info` — это полный вывод `ffprobe` |
| `describe()`, `display` | [4. Назови и оформи](addons.md#step-4-name-and-dress-it) | Название, описание, дата и картинки. URL кадра идёт под собственным адресом дополнения, и это единственное место в твоей сети, откуда rex берёт картинки |
| `sync()`, остальное | [5. Отправка](addons.md#step-5-send-it) | Снимок всех видео, 200 за один запрос, так что видео, которое ты удалишь из папки, уйдёт из медиатеки при следующем раунде |

Защиты не дают плохому моменту опустошить твою медиатеку: пустая или отсутствующая папка ничего не отправляет, видео, которое `ffprobe` не может прочитать, пропускается и записывается в лог, а сам rex отказывается от снимка, который удалил бы больше половины видео.

## Как это изменить {#change-it}

- **Сериалы вместо фильмов.** Отправляйте `"kind": "episode"` с номерами `season` и `episode` и `display.show`, а каталог регистрируйте как `"shows"`. Нумеруйте эпизоды так, чтобы новое видео никогда не сдвигало остальные: по дате, а не по позиции в папке. См. [Шаг 3](addons.md#step-3-describe-each-video).
- **Свои названия.** Читайте их из sidecar-файла или из тегов видео (`media_info["format"]["tags"]`), а не из имени файла.
- **Субтитры, коллекции, главы.** Файлы `.srt` рядом с видео, коллекция на каждую папку, метки глав: см. [Дополнительно в вашем аддоне](addon-more.md).
- **Разрешить удаление из приложений Plex.** Добавьте `do_DELETE`, который удаляет файл и отвечает `204`. Без него аддон отвечает `501`, rex сохраняет видео (в его логе будет `DELETE refused by the source, row kept: home/... at homevideos: 501`), а приложение сообщает, что удалить не удалось.

## Устранение неполадок {#troubleshooting}

| Вы видите | Почему | Как исправить |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex не запущен, или `REX` указывает не на его адрес | Запустите rex или исправьте `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | Больше половины видео, которые rex получил от этого аддона, пропали из папки: диск не смонтирован, неверный `FOLDER` или большая чистка | Если так и задумано, запустите один раз командой `REX_FORCE=1 python3 homevideos.py`. Если нет, исправьте папку; ничего не было удалено |
| `no videos found in ...: not sending a snapshot` | Папка пустая, её нет или в ней нет видеофайлов | Исправьте `FOLDER` |
| `skipped <file>: ...` | `ffprobe` не смог прочитать файл (он повреждён или не докачан) | В следующем цикле попытка повторится |
| `rejected: {'id': ..., 'reason': ...}` | rex отклонил одно видео и объясняет причину | См. [Building rex addons, Troubleshooting](addons.md#troubleshooting) |
| Библиотека есть, но постеры пустые | Не установлен `ffmpeg`, или rex не может достучаться до `LISTEN` | Установите FFmpeg; если аддон работает на другой машине, задайте `LISTEN` в LAN-IP этой машины, а не `127.0.0.1` |
| Воспроизведение не работает, а в логе rex есть `PART ... upstream failed: <urlopen error Connection refused ...>` | Аддон не запущен, или rex не может достучаться до `LISTEN` | Запустите аддон. Если он на другой машине, задайте `LISTEN` в LAN-IP этой машины |

Всё ещё не получается? Спросите на форуме **rex-support** в [Discord](https://discord.com/invite/7u4YjMThXP).
