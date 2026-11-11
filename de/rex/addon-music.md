# Anleitung: ein Musik-Addon {#tutorial-a-music-addon}

Dieses Tutorial legt einen Ordner mit Alben in eine **Music**-Bibliothek, die Plexamp, Plex Web und Plex for Android abspielen.
Es unterstützt FLAC, MP3, AAC und andere gängige Dateien. Deine Dateien bleiben, wo sie sind. MusicBrainz liefert bekannte Albumdetails. Unbekannte Alben nutzen ihre Tags und `cover.jpg`. Eine `.lrc`-Datei daneben wird zu zeitgesteuerten Liedtexten.

Es baut auf [Eigene rex-Addons bauen](addons.md) und dessen Abschnitt [Music](addons.md#music) auf. Lies zuerst das [Tutorial zu Heimvideos](addon-home-videos.md), wenn es dein erstes Addon ist.

| Du brauchst | Warum |
|---|---|
| rex 2026.11.02 oder neuer, eingerichtet wie in [rex mit deiner eigenen App](any-source.md) (Schritte 1 bis 3) und beansprucht | rex fragt Plex erst nach den Namen der Alben, wenn es beansprucht ist |
| Python 3.8 oder neuer | Das Addon, nur mit der Standardbibliothek |
| `ffprobe` | Beschreibt jede Datei für rex und liest ihre Tags. Es kommt mit FFmpeg |
| Deine Alben, ein Ordner pro Album | `Artist/Album/01 Song.flac`, oder beliebig tief verschachtelt: Jeder Ordner mit Audiodateien darin ist ein Album |
| Tags oder MusicBrainz Picard | Das Addon liest Album und Künstler aus den Tags jeder Datei (sonst aus den Ordnernamen). Dateien, die von [MusicBrainz Picard](https://picard.musicbrainz.org) getaggt wurden, tragen bereits ihre Release-ID, das ist der sicherste Treffer |

Diese Seite schreibt die Adresse von rex als `192.168.1.20:32400` und führt das Addon auf dem Rechner von rex aus.

## Schritt 1. Das Addon speichern {#step-1-save-the-addon}

Speichere das als `music.py`:

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

## Schritt 2. Die Einstellungen ausfüllen {#step-2-fill-in-the-settings}

| Setting | Put |
|---|---|
| `FOLDER` | Dein Musikordner, zum Beispiel `"/srv/music"` oder `os.path.expanduser("~/Music")` |
| `REX` | rex' Adresse |
| `LISTEN` | Lass `127.0.0.1` beim Addon auf dem Rechner von rex stehen, sonst die LAN-IP dieses Rechners |
| `NAME`, `LIBRARY` | Der Name des Addons in rex und der Titel der Musikbibliothek. Behalte `NAME`, sobald du es einmal gestartet hast |

## Schritt 3. Starten {#step-3-run-it}

+++ Linux und macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**Das solltest du sehen.** Für jedes Album ohne release id in seinen Tags steht eine Zeile mit der Antwort von MusicBrainz, am Ende die Gesamtzahl:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz erlaubt eine Anfrage pro Sekunde, daher dauert der erste Durchlauf über eine große Sammlung eine Weile: etwa eine Sekunde pro Album. Jede Antwort wird in `.rex/albums.json` in deinem Musikordner gespeichert, und die nächsten Durchläufe fragen nichts mehr ab. Alben, die von Picard getaggt wurden, werden nie nachgeschlagen.

Das Log von rex zeigt, wie jeder Titel seinem Album zugeordnet wird:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Öffne Plexamp und wähle rex' **Music**-Bibliothek als Bibliothek aus (Plex Web und Plex für Android zeigen sie unter More an). In Rainbows hat dann Plex' Cover, die Titelnamen und Radioheads Foto und Biografie, egal wie deine Dateien heißen. Garage Demos zeigt die Namen aus seinen Tags und das `cover.jpg` aus seinem Ordner. Ein Song mit einer `.lrc`-Datei gleichen Namens zeigt seine Liedtexte, Zeile für Zeile, während er läuft.

Damit es dauerhaft läuft, richte es wie das Home-Videos-Addon ein: [Schritt 4](addon-home-videos.md#step-4-keep-it-running), mit `music.py` statt `homevideos.py`.

## So funktioniert es {#how-it-works}

| Teil | Was er macht |
|---|---|
| `Handler` | Bedient alles unter `/music/`: die Songs (mit `Range`, damit Spulen sofort geht), ihre `.lrc`-Texte und die Albumcover |
| `sync()`, erste Zeile | Meldet das Addon mit einem Verzeichnis, `music`, als Musikbibliothek an: `"directories": [{"name": "music", "music": "Music"}]`. Ohne Musikbibliothek lehnt rex jeden Track ab |
| `album_items()` | Ein Item pro Song: `"kind": "track"`, seine `disc`- und `track`-Nummern (aus den Tags, sonst aus seiner Position im Ordner), seine `ffprobe`-Ausgabe und `ids.mbid`, die MusicBrainz-Release-ID des Albums. Plex zeigt bei diesen Nummern seinen eigenen Track dieses Releases, also müssen die Nummern stimmen |
| `release_id()` | Findet die Release-ID für ein Album, das keine hat: eine MusicBrainz-Suche nach Album und Künstler, wobei das erste offizielle Release mit so vielen Tracks genommen wird, wie der Ordner enthält. Ein Album erscheint in vielen Releases (eines pro Land, Deluxe-Editionen). Jedes Release, das deine Tracks enthält, passt und bestimmt das Album |
| `display` | Die Namen des Albums aus den Tags und sein Cover, das nur angezeigt wird, wenn Plex das Album nicht kennt |
| `lyrics` | Eine `.lrc`- (zeitgesteuert) oder `.txt`-Datei mit dem Namen des Songs daneben, gesendet als `[{"path": ..., "size": ...}]`. rex liest sie nur dann neu ein, wenn sich ihre Größe ändert |
| `sync()`, der Rest | Ein Snapshot jedes Songs, 200 pro Anfrage: ein Album, das du löschst, verschwindet beim nächsten Durchlauf (alle zehn Minuten) aus der Bibliothek |

rex liest selbst keine Tags. Alles, was Plex anzeigt, kommt von der Release-ID oder von deinem `display`, wenn Plex keins hat.

## Ändern {#change-it}

- **Ein anderes Layout.** Ein Album, das in Disc-Ordner aufgeteilt ist (`CD1/`, `CD2/`), gilt für dieses Addon als zwei Alben, in denen jeweils zu wenige Tracks zum Abgleich sind. Fasse solche Ordner in `albums()` zusammen und schick eine `release` für alle ihre Dateien; siehe [Music](addons.md#music).
- **Künstler mit eigenen Bildern.** Schick `display.artist.poster` und registriere mit `"artwork": "source"`: siehe [More from your addon](addon-more.md#artist-pictures).
- **Playlists.** Schick die Position jedes Songs in einer Playlist, und rex erstellt die Playlist: siehe [More from your addon](addon-more.md#collections-and-playlists).
- **Lautheit.** Wenn du die Lautheit jedes Songs misst, schick sie als `loudness` in Plex-Namen: siehe [Music](addons.md#music). rex misst selbst nichts.

## Fehlerbehebung {#troubleshooting}

| Du siehst | Warum | Lösung |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | Es gibt kein offizielles Release mit diesem Titel und Interpret, das deine Anzahl an Titeln hat: ein fehlender Song, ein Bonustrack, ein Tippfehler in den Tags oder ein Album, das MusicBrainz nicht listet | Korrigiere die Tags oder den Ordner und lösche dann die Zeile dieses Albums aus `.rex/albums.json` (oder die ganze Datei), damit danach erneut nachgefragt wird. Alternativ tagge das Album mit Picard |
| Bei einem Album werden die falschen Songnamen angezeigt | Das gefundene Release hat deine Anzahl an Titeln, aber in einer anderen Reihenfolge (eine andere Edition) | Tagge das Album mit Picard, das schreibt das genaue Release |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz war beschäftigt oder nicht erreichbar | Nichts tun: die nächste Runde fragt erneut nach |
| Alben zeigen die Namen aus ihren Tags, obwohl Plex sie kennt | rex ist nicht beansprucht, oder die Release-ID bezeichnet nichts, was Plex kennt | Beanspruche rex: [Schritt 3 von rex mit deiner eigenen App](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | Die Bibliothek wurde in einer Plex-App gelöscht | Füge sie in einer Plex-App wieder hinzu: Add Library, Music, und wähle den Ordner `music`, den die Ordnerliste anbietet |
| `sync failed, ...: rex answered 409: ...more than half...` | Mehr als die Hälfte der Songs fehlt im Ordner | Wenn du das so wolltest, führe es einmal mit `REX_FORCE=1` aus; ansonsten korrigiere `FOLDER` |
| Keine Songtexte | Der Name der `.lrc`-Datei weicht vom Namen des Songs ab, oder der Song wurde gesendet, bevor die Datei da war | Benenne sie wie den Song (`01 - Song.flac`, `01 - Song.lrc`); die nächste Runde sendet sie |

Immer noch hängen geblieben? Frag im Forum **rex-support** auf [Discord](https://discord.com/invite/7u4YjMThXP).
