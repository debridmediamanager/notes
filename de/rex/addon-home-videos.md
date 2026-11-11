# Anleitung: ein Addon für Heimvideos {#tutorial-a-home-videos-addon}

Dieses Tutorial baut einen rex-Addon in einer einzigen Python-Datei. Es legt deine Handyclips, Camcorder-Dateien oder Bildschirmaufnahmen in eine **Home Videos**-Bibliothek, die in jeder Plex-App erscheint. Jedes Video bekommt einen Titel, ein Datum und ein Standbild als Poster.
Es wird nichts kopiert oder hochgeladen. rex liest die Datei aus deinem Addon, wenn du auf Play drückst.

Es ist die kürzeste funktionierende Version von [Building rex addons](addons.md), Schritte 1 bis 5. Diese Seite sagt dir, was du eintippen musst.
Dort steht, warum. Die Tutorials [music](addon-music.md) und [IPTV](addon-iptv.md) verwenden dasselbe Grundgerüst.

| Du brauchst | Warum |
|---|---|
| rex, eingerichtet wie in [rex with your own app](any-source.md) (Schritte 1 bis 3) | Dort taucht die Bibliothek auf. Beansprucht, damit die Plex-Apps sie sehen können |
| Python 3.8 oder neuer | Für das Addon. Es nutzt nur die Standardbibliothek von Python |
| `ffprobe` und `ffmpeg` | `ffprobe` beschreibt jedes Video für rex, `ffmpeg` schneidet das Standbild für das Poster aus. Beide sind im FFmpeg-Paket enthalten |
| Ein Ordner mit Videos, auf dem Rechner, der das Addon ausführt | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`, auch in Unterordnern |

Diese Seite schreibt rex' Adresse als `192.168.1.20:32400` und führt das Addon auf demselben Rechner wie rex aus. Trag an deren Stelle deine eigenen Werte ein.

## Schritt 1. Das Addon speichern {#step-1-save-the-addon}

**Was es macht.** Gibt dir das ganze Addon: einen kleinen Webserver für deine Videos und eine Schleife, die rex alle fünf Minuten über sie informiert.

Speichere dies als `homevideos.py`:

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

## Schritt 2. Die Einstellungen ausfüllen {#step-2-fill-in-the-settings}

**Was es macht.** Richtet das Addon auf deinen Ordner und dein rex aus.

Ändere die vier Zeilen unter dem Docstring:

| Einstellung | Eintragen |
|---|---|
| `FOLDER` | Der Ordner mit deinen Videos, zum Beispiel `"/srv/videos/home"`, oder `os.path.expanduser("~/Videos/Home")` für einen Ordner in deinem Home-Verzeichnis |
| `REX` | Die Adresse von rex, so wie du sie in Schritt 3 von [rex mit deiner eigenen App](any-source.md) öffnest |
| `LISTEN` | Wo das Addon antwortet. Lass `127.0.0.1`, wenn das Addon auf demselben Rechner wie rex läuft. Auf einem anderen Rechner trägst du dessen LAN-IP ein (rex liest die Videos von dort, deshalb muss er von rex aus erreichbar sein) |
| `NAME`, `LIBRARY` | Der Name des Addons in rex und der Titel der Bibliothek. Behalte `NAME`, sobald du es einmal gestartet hast: Die Zeilen von rex gehören dazu |

## Schritt 3. Starten {#step-3-run-it}

+++ Linux und macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**Was du sehen solltest.** Beim ersten Durchlauf wird jedes Video geprüft und davon ein Standbild erstellt. Danach werden sie gesendet:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

rex's log zeigt die Quelle und die neue Bibliothek, dann die Videos:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Öffne eine Plex-App: **Home Videos** findest du unter More (pinn es an, dann siehst du es auf Home). Jedes Video hat seinen Dateinamen als Titel, den Ordner, in dem es liegt, als Zusammenfassung, das Datum der Datei als Erscheinungsdatum und ein Standbild von einem Zehntel des Weges als Poster und Hintergrund. Drück auf Play: Es spielt ab, und Vorspulen klappt sofort.

Stoppe das Addon mit Ctrl+C. Startest du es erneut, sendet es dieselben Videos als `unchanged`, ohne etwas zu prüfen. Die Probes und Standbilder liegen im Ordner `.rex` innerhalb des Ordners deiner Videos.

## Schritt 4. Dafür sorgen, dass es weiterläuft {#step-4-keep-it-running}

Der Addon muss immer laufen, wenn jemand schaut: rex liest jedes Video daraus.

+++ Linux
Erstelle `~/.config/systemd/user/homevideos.service` mit dem Ordner, in dem du das Addon gespeichert hast:

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

Wenn du für rex `sudo loginctl enable-linger "$USER"` ausgeführt hast, läuft das Addon auch weiter, nachdem du dich abgemeldet hast.
+++ macOS und Windows
Starte es so, wie du rex in Schritt 1 von [rex mit deiner eigenen App](any-source.md#step-1-install-rex) startest: als LaunchAgent unter macOS, als geplante Aufgabe unter Windows, mit `python3 homevideos.py` (`python homevideos.py` unter Windows) als Befehl und dem Ordner des Addons als Arbeitsordner.
+++

## So funktioniert es {#how-it-works}

Jeder Teil der Datei gehört zu einem Schritt aus [Eigene rex-Addons bauen](addons.md):

| Teil | Schritt | Was er macht |
|---|---|---|
| `Handler` | [1. Die Bytes ausliefern](addons.md#step-1-serve-the-bytes) | Antwortet auf `GET /home/<file>` mit der Datei und auf eine `Range`-Anfrage mit genau diesen Bytes (`206`), damit das Spulen nicht vom Anfang liest. Über `GET /stills/<name>.jpg` werden die Poster ausgeliefert. Alles außerhalb des Ordners bekommt ein `404` |
| `sync()`, erste Zeile | [2. Registrieren](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` mit der Adresse des Addons und einem Verzeichnis, `home`, als Filmbibliothek. Wird in jeder Runde gesendet: Erneut registrieren ändert nichts |
| `describe()` | [3. Jedes Video beschreiben](addons.md#step-3-describe-each-video) | Die `id` des Videos ist sein Pfad in deinem Ordner. Benennst du eine Datei um, wird sie zu einem neuen Titel, ohne Wiedergabeverlauf. Mit `kind: "movie"` wird jedes Video ein eigener Film, daher muss nichts nummeriert werden. `media_info` ist die komplette Ausgabe von `ffprobe` |
| `describe()`, `display` | [4. Benennen und aufhübschen](addons.md#step-4-name-and-dress-it) | Titel, Zusammenfassung, Datum und Bilder. Die URL des Stills liegt unter der eigenen Adresse des Addons, also dem einzigen Ort in deinem Netzwerk, von dem rex Bilder abruft |
| `sync()`, der Rest | [5. Abschicken](addons.md#step-5-send-it) | Ein Snapshot aller Videos, 200 pro Anfrage, damit ein Video, das du aus dem Ordner löschst, bei der nächsten Runde aus der Bibliothek verschwindet |

Die Schutzmechanismen verhindern, dass ein schlechter Moment deine Bibliothek leert: Ein leerer oder fehlender Ordner sendet nichts, ein Video, das `ffprobe` nicht lesen kann, wird übersprungen und protokolliert, und rex selbst lehnt einen Snapshot ab, der mehr als die Hälfte der Videos entfernen würde.

## Ändern {#change-it}

- **Serien statt Filme.** Sende `"kind": "episode"` mit den Nummern `season` und `episode` sowie `display.show`, und registriere das Verzeichnis als `"shows"`. Nummeriere die Episoden so, dass ein neues Video die anderen nie verschiebt: nach Datum, nicht nach Position im Ordner. Siehe [Schritt 3](addons.md#step-3-describe-each-video).
- **Eigene Titel.** Lies sie aus einer Sidecar-Datei oder aus den Tags des Videos (`media_info["format"]["tags"]`) statt aus dem Dateinamen.
- **Untertitel, Sammlungen, Kapitel.** `.srt`-Dateien neben einem Video, eine Sammlung pro Ordner, Kapitelmarken: siehe [Mehr aus deinem Addon](addon-more.md).
- **Plex-Apps löschen lassen.** Füge ein `do_DELETE` hinzu, das die Datei löscht und mit `204` antwortet. Ohne das antwortet das Addon mit `501`, rex behält das Video (im Log steht `DELETE refused by the source, row kept: home/... at homevideos: 501`), und die App meldet, dass es nicht gelöscht werden konnte.

## Fehlerbehebung {#troubleshooting}

| Du siehst | Warum | Lösung |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex läuft nicht, oder `REX` ist nicht die richtige Adresse | rex starten, oder `REX` korrigieren |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | Mehr als die Hälfte der Videos, die rex von diesem Addon hat, sind aus dem Ordner verschwunden: eine Festplatte, die nicht eingehängt ist, ein falsches `FOLDER` oder eine große Aufräumaktion | Wenn du das so willst, einmal mit `REX_FORCE=1 python3 homevideos.py` starten. Sonst den Ordner korrigieren; es wurde nichts gelöscht |
| `no videos found in ...: not sending a snapshot` | Der Ordner ist leer, fehlt oder enthält keine Videodateien | `FOLDER` korrigieren |
| `skipped <file>: ...` | `ffprobe` konnte sie nicht lesen (eine kaputte oder unfertige Datei) | Es wird in der nächsten Runde erneut versucht |
| `rejected: {'id': ..., 'reason': ...}` | rex hat ein Video abgelehnt und sagt, warum | Siehe [rex-Addons bauen, Fehlerbehebung](addons.md#troubleshooting) |
| Die Bibliothek ist da, aber die Poster sind leer | `ffmpeg` fehlt, oder rex kann `LISTEN` nicht erreichen | FFmpeg installieren; wenn das Addon auf einem anderen Rechner läuft, `LISTEN` auf die LAN-IP dieses Rechners setzen, nicht `127.0.0.1` |
| Abspielen schlägt fehl, und das rex-Log zeigt `PART ... upstream failed: <urlopen error Connection refused ...>` | Das Addon läuft nicht, oder rex kann `LISTEN` nicht erreichen | Das Addon starten. Läuft es auf einem anderen Rechner, `LISTEN` auf die LAN-IP dieses Rechners setzen |

Noch Probleme? Frag im **rex-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP).
