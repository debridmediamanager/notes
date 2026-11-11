# Tutoriel : un addon musique {#tutorial-a-music-addon}

Ce tutoriel place un dossier d'albums dans une bibliothèque **Music** que Plexamp, Plex Web et Plex for Android peuvent lire.
Il prend en charge FLAC, MP3, AAC et d'autres formats courants. Vos fichiers restent là où ils sont.
MusicBrainz fournit les informations des albums connus. Les albums inconnus utilisent leurs tags et `cover.jpg`.
Un fichier `.lrc` situé à côté devient des paroles synchronisées.

Il suit [Building rex addons](addons.md) et sa section [Musique](addons.md#music). Lisez d'abord le [tutoriel sur les vidéos personnelles](addon-home-videos.md) si c'est votre premier addon.

| Il vous faut | Pourquoi |
|---|---|
| rex 2026.11.02 ou plus récent, configuré comme dans [rex avec votre propre application](any-source.md) (étapes 1 à 3) et claimed | rex ne demande à Plex les noms des albums qu'une fois qu'il est claimed |
| Python 3.8 ou plus récent | L'addon, bibliothèque standard uniquement |
| `ffprobe` | Décrit chaque fichier pour rex et lit ses tags. Il est fourni avec FFmpeg |
| Vos albums, un dossier par album | `Artist/Album/01 Song.flac`, ou n'importe quelle profondeur : chaque dossier contenant des fichiers audio est un album |
| Des tags, ou MusicBrainz Picard | L'addon lit l'album et l'artiste dans les tags de chaque fichier (sinon dans les noms de dossiers). Les fichiers taggés par [MusicBrainz Picard](https://picard.musicbrainz.org) portent déjà leur identifiant de release, ce qui donne la correspondance la plus sûre |

Cette page indique l'adresse de rex comme `192.168.1.20:32400` et lance l'addon sur la machine de rex.

## Étape 1. Enregistrer l'addon {#step-1-save-the-addon}

Enregistrez ceci dans `music.py` :

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

## Étape 2. Remplir les paramètres {#step-2-fill-in-the-settings}

| Setting | Mettez |
|---|---|
| `FOLDER` | Votre dossier de musique, par exemple `"/srv/music"` ou `os.path.expanduser("~/Music")` |
| `REX` | L'adresse de rex |
| `LISTEN` | Gardez `127.0.0.1` avec l'addon sur la machine de rex ; sinon, l'IP LAN de cette machine |
| `NAME`, `LIBRARY` | Le nom de l'addon dans rex et le titre de la bibliothèque musicale. Gardez `NAME` une fois que vous l'avez lancé |

## Étape 3. Lancer-le {#step-3-run-it}

+++ Linux et macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**Ce que tu devrais voir.** Pour chaque album qui n'a pas d'identifiant de release dans ses tags, une ligne avec la réponse de MusicBrainz, puis le total :

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz accepte une requête par seconde, donc la première exécution sur une grosse collection prend du temps : environ une seconde par album. Chaque réponse est gardée dans `.rex/albums.json` dans ton dossier musique, et les exécutions suivantes ne demandent plus rien. Les albums taggés par Picard ne sont jamais recherchés.

Le log de rex montre chaque piste arrivant dans son album :

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Ouvre Plexamp et choisis la bibliothèque **Music** de rex comme bibliothèque (Plex Web et Plex pour Android la listent sous More). In Rainbows affiche la pochette de Plex, les noms de ses pistes et la photo et la biographie de Radiohead, quel que soit le nom de tes fichiers. Garage Demos affiche les noms de ses tags et le `cover.jpg` de son dossier. Une chanson avec un fichier `.lrc` du même nom affiche ses paroles, ligne par ligne pendant la lecture.

Pour que ça tourne en continu, configure-le comme l'addon home videos : [Étape 4](addon-home-videos.md#step-4-keep-it-running), avec `music.py` à la place de `homevideos.py`.

## Comment ça marche {#how-it-works}

| Partie | Ce que ça fait |
|---|---|
| `Handler` | Sert tout ce qui se trouve sous `/music/` : les morceaux (avec `Range`, donc la navigation dans le morceau est instantanée), leurs paroles `.lrc` et les pochettes d'album |
| `sync()`, première ligne | Enregistre l'addon avec un seul dossier, `music`, comme bibliothèque musicale : `"directories": [{"name": "music", "music": "Music"}]`. Sans bibliothèque musicale, rex refuse toutes les pistes |
| `album_items()` | Un élément par morceau : `"kind": "track"`, ses numéros `disc` et `track` (pris dans ses tags, sinon selon sa place dans le dossier), sa sortie `ffprobe`, et `ids.mbid`, l'identifiant de release MusicBrainz de l'album. Plex affiche son propre titre à ces numéros sur cette release, donc les numéros doivent être justes |
| `release_id()` | Trouve l'identifiant de release d'un album qui n'en a pas : une recherche MusicBrainz par album et artiste, en gardant la première release officielle avec autant de pistes que le dossier en contient. Un album existe en plusieurs releases (une par pays, éditions deluxe) ; n'importe laquelle avec tes pistes donne le nom de l'album |
| `display` | Les noms de l'album tirés des tags, et sa pochette, affichée seulement quand Plex ne connaît pas l'album |
| `lyrics` | Un fichier `.lrc` (synchronisé) ou `.txt` portant le même nom que le morceau, envoyé sous la forme `[{"path": ..., "size": ...}]`. rex ne le relit que quand sa taille change |
| `sync()`, le reste | Un instantané de chaque morceau, 200 par requête : un album que tu supprimes quitte la bibliothèque au prochain cycle (toutes les dix minutes) |

rex ne lit aucun tag lui-même. Tout ce que Plex affiche vient de l'identifiant de release, ou de ton `display` quand Plex n'en a pas.

## Le modifier {#change-it}

- **Une autre disposition.** Un album découpé en dossiers de disque (`CD1/`, `CD2/`) compte pour deux albums aux yeux de cet addon, chacun avec trop peu de pistes pour correspondre. Regroupe ces dossiers dans `albums()` et envoie un seul `release` pour tous leurs fichiers ; voir [Musique](addons.md#music).
- **Artistes avec leurs propres images.** Envoie `display.artist.poster` et enregistre avec `"artwork": "source"` ; voir [Plus sur ton addon](addon-more.md#artist-pictures).
- **Playlists.** Envoie la position de chaque morceau dans une playlist et rex crée la playlist ; voir [Plus sur ton addon](addon-more.md#collections-and-playlists).
- **Volume sonore.** Si tu mesures le volume sonore de chaque morceau, envoie-le sous `loudness` dans les noms de Plex ; voir [Musique](addons.md#music). rex ne mesure rien lui-même.

## Dépannage {#troubleshooting}

| Vous voyez | Pourquoi | Solution |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | Aucune édition officielle de ce titre et de cet artiste n'a votre nombre de pistes : un morceau manquant, une piste bonus, une faute de frappe dans les tags, ou un album que MusicBrainz ne liste pas | Corrige les tags ou le dossier, puis supprime la ligne de cet album dans `.rex/albums.json` (ou le fichier entier) pour qu'il soit redemandé. Ou tague l'album avec Picard |
| Un album affiche les mauvais titres de morceaux | La version trouvée a votre nombre de pistes mais dans un autre ordre (une autre édition) | Tague l'album avec Picard, qui écrit la version exacte |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz était occupé ou injoignable | Rien : le prochain tour le redemande |
| Les albums affichent les noms de leurs tags alors que Plex les connaît | rex n'est pas réclamé, ou l'identifiant de la version ne correspond à rien que Plex connaît | Réclame rex : [étape 3 de rex avec ta propre app](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | La bibliothèque a été supprimée dans une app Plex | Rajoute-la dans une app Plex : Add Library, Music, puis choisis le dossier `music` proposé dans sa liste de dossiers |
| `sync failed, ...: rex answered 409: ...more than half...` | Plus de la moitié des morceaux ont disparu du dossier | Si c'était voulu, lance une fois avec `REX_FORCE=1` ; sinon, corrige `FOLDER` |
| Pas de paroles | Le nom du fichier `.lrc` ne correspond pas à celui du morceau, ou le morceau a été envoyé avant que le fichier ne soit là | Nomme-le comme le morceau (`01 - Song.flac`, `01 - Song.lrc`) ; le prochain tour l'envoie |

Toujours bloqué ? Pose ta question dans le forum **rex-support** sur [Discord](https://discord.com/invite/7u4YjMThXP).
