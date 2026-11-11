# Tutorial: un complemento de música {#tutorial-a-music-addon}

Este tutorial pone una carpeta de álbumes en una biblioteca **Music** que reproducen Plexamp, Plex Web y Plex para Android.
Admite FLAC, MP3, AAC y otros formatos de audio comunes. Tus archivos se quedan donde están. MusicBrainz aporta los datos de los álbumes conocidos. Los álbumes desconocidos usan sus etiquetas y `cover.jpg`. Un archivo `.lrc` junto a la canción se convierte en letras con tiempos.

Sigue [Crear addons para rex](addons.md) y su sección [Music](addons.md#music). Si es tu primer addon, lee antes el [tutorial de vídeos caseros](addon-home-videos.md).

| Necesitas | Por qué |
|---|---|
| rex 2026.11.02 o más reciente, configurado como en [rex con tu propia app](any-source.md) (pasos 1 a 3) y reclamado | rex le pide a Plex los nombres de los álbumes solo cuando ya está reclamado |
| Python 3.8 o más reciente | El addon, solo con la biblioteca estándar |
| `ffprobe` | Describe cada archivo para rex y lee sus etiquetas. Viene con FFmpeg |
| Tus álbumes, una carpeta por álbum | `Artist/Album/01 Song.flac`, o con cualquier profundidad: cada carpeta con archivos de audio dentro es un álbum |
| Etiquetas, o MusicBrainz Picard | El addon lee el álbum y el artista de las etiquetas de cada archivo (si no, de los nombres de las carpetas). Los archivos etiquetados con [MusicBrainz Picard](https://picard.musicbrainz.org) ya llevan su id de edición, que es la coincidencia más segura |

Esta página escribe la dirección de rex como `192.168.1.20:32400` y ejecuta el addon en la máquina de rex.

## Paso 1. Guarda el addon {#step-1-save-the-addon}

Guarda esto como `music.py`:

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

## Paso 2. Rellena la configuración {#step-2-fill-in-the-settings}

| Setting | Put |
|---|---|
| `FOLDER` | Tu carpeta de música, como `"/srv/music"` o `os.path.expanduser("~/Music")` |
| `REX` | La dirección de rex |
| `LISTEN` | Deja `127.0.0.1` con el addon en la máquina de rex; si no, la IP de la LAN de esa máquina |
| `NAME`, `LIBRARY` | El nombre del addon en rex y el título de la biblioteca de música. Mantén `NAME` una vez que lo hayas ejecutado |

## Paso 3. Ejecútalo {#step-3-run-it}

+++ Linux y macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**Lo que deberías ver.** Por cada álbum sin un release id en sus etiquetas, una línea con lo que respondió MusicBrainz, y luego el total:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz acepta una solicitud por segundo, así que la primera ejecución sobre una colección grande tarda un poco: alrededor de un segundo por álbum. Cada respuesta se guarda en `.rex/albums.json` dentro de tu carpeta de música, y las siguientes ejecuciones no preguntan nada. Los álbumes etiquetados por Picard nunca se buscan.

El log de rex muestra cada pista al llegar a su álbum:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Abre Plexamp y elige la biblioteca **Music** de rex como su biblioteca (Plex Web y Plex para Android la muestran en More). In Rainbows muestra la portada de Plex, sus nombres de pistas y la foto y biografía de Radiohead, sin importar cómo se llamen tus archivos. Garage Demos muestra los nombres de sus etiquetas y el `cover.jpg` de su carpeta. Una canción con un archivo `.lrc` del mismo nombre muestra su letra, línea por línea mientras suena.

Para mantenerlo en funcionamiento, configúralo igual que el addon de home videos: [Step 4](addon-home-videos.md#step-4-keep-it-running), con `music.py` en lugar de `homevideos.py`.

## Cómo funciona {#how-it-works}

| Parte | Qué hace |
|---|---|
| `Handler` | Sirve todo lo que hay bajo `/music/`: las canciones (con `Range`, así que buscar dentro de la pista es instantáneo), sus letras `.lrc` y las portadas de los álbumes |
| `sync()`, primera línea | Registra el addon con un solo directorio, `music`, como biblioteca de música: `"directories": [{"name": "music", "music": "Music"}]`. Sin una biblioteca de música, rex rechaza todas las pistas |
| `album_items()` | Un elemento por canción: `"kind": "track"`, sus números de `disc` y `track` (de sus etiquetas, o si no, su posición en la carpeta), su salida de `ffprobe` y `ids.mbid`, el id de la release de MusicBrainz del álbum. Plex muestra su propia pista en esos números de esa release, así que los números deben ser correctos |
| `release_id()` | Busca el id de la release de un álbum que no lo tiene: una búsqueda en MusicBrainz por álbum y artista, quedándose con la primera release oficial que tenga tantas pistas como contiene la carpeta. Un álbum aparece en muchas releases (una por país, ediciones deluxe); cualquiera que tenga tus pistas identifica el álbum |
| `display` | Los nombres del álbum según las etiquetas, y su portada, que solo se muestra cuando Plex no conoce el álbum |
| `lyrics` | Un archivo `.lrc` (con tiempos) o `.txt` con el mismo nombre que la canción, enviado como `[{"path": ..., "size": ...}]`. rex solo vuelve a leerlo cuando cambia su tamaño |
| `sync()`, lo demás | Una instantánea de todas las canciones, 200 por petición: un álbum que borres sale de la biblioteca en la siguiente ronda (cada diez minutos) |

rex no lee las etiquetas por sí mismo. Todo lo que muestra Plex sale del id de la release, o de tu `display` cuando Plex no tiene nada.

## Cámbialo {#change-it}

- **Otro diseño.** Un álbum dividido en carpetas de disco (`CD1/`, `CD2/`) es para este addon dos álbumes, cada uno con muy pocas pistas para encontrar coincidencia. Agrupa esas carpetas en `albums()` y envía un `release` para todos sus archivos; consulta [Music](addons.md#music).
- **Artistas con sus propias fotos.** Envía `display.artist.poster` y regístrate con `"artwork": "source"`: consulta [More from your addon](addon-more.md#artist-pictures).
- **Listas de reproducción.** Envía la posición de cada canción en una lista de reproducción y rex crea la lista: consulta [More from your addon](addon-more.md#collections-and-playlists).
- **Volumen (loudness).** Si mides el volumen de cada canción, envíalo como `loudness` con los nombres de Plex: consulta [Music](addons.md#music). rex no mide nada por sí mismo.

## Solución de problemas {#troubleshooting}

| Lo que ves | Por qué | Solución |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | Ningún lanzamiento oficial de ese título y artista tiene tu número de pistas: falta una canción, hay una pista extra, un error de escritura en las etiquetas, o un álbum que MusicBrainz no tiene listado | Corrige las etiquetas o la carpeta, y luego borra la línea de ese álbum en `.rex/albums.json` (o el archivo entero) para que se vuelva a preguntar. O etiqueta el álbum con Picard |
| Un álbum muestra nombres de canciones incorrectos | El lanzamiento encontrado tiene tu número de pistas en otro orden (una edición distinta) | Etiqueta el álbum con Picard, que escribe el lanzamiento exacto |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz estaba ocupado o no era accesible | Nada: la siguiente ronda vuelve a preguntar |
| Los álbumes muestran los nombres de sus etiquetas aunque Plex los conozca | rex no está reclamado, o el id del lanzamiento no corresponde a nada que Plex conozca | Reclama rex: [paso 3 de rex con tu propia app](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | Se borró la biblioteca desde una app de Plex | Vuelve a añadirla en una app de Plex: Add Library, Music, y elige la carpeta `music` que ofrece su lista de carpetas |
| `sync failed, ...: rex answered 409: ...more than half...` | Más de la mitad de las canciones ya no están en la carpeta | Si era lo que querías, ejecútalo una vez con `REX_FORCE=1`; si no, corrige `FOLDER` |
| No hay letras | El nombre del archivo `.lrc` no coincide con el de la canción, o la canción se envió antes de que el archivo existiera | Ponle el mismo nombre que a la canción (`01 - Song.flac`, `01 - Song.lrc`); la siguiente ronda la envía |

¿Sigues atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
