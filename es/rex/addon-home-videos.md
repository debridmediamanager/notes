# Tutorial: un addon de vídeos caseros {#tutorial-a-home-videos-addon}

Este tutorial crea un addon de rex en un solo archivo de Python. Pone tus clips del móvil, archivos de videocámara o grabaciones de pantalla en una biblioteca **Home Videos** en todas las apps de Plex. Cada video obtiene un título, una fecha y una imagen de portada.

No se copia ni se sube nada. rex lee el archivo desde tu addon cuando pulsas play.

Es la versión funcional más corta de [Building rex addons](addons.md), pasos 1 a 5. Esta página te dice qué escribir.
Ese explica el porqué. Los tutoriales de [música](addon-music.md) e [IPTV](addon-iptv.md) usan la misma estructura base.

| Necesitas | Por qué |
|---|---|
| rex, configurado como en [rex with your own app](any-source.md) (pasos 1 a 3) | Ahí es donde aparece la biblioteca. Claimed, para que las apps de Plex puedan verla |
| Python 3.8 o más reciente | El addon. Solo usa la biblioteca estándar de Python |
| `ffprobe` y `ffmpeg` | `ffprobe` describe cada video para rex, `ffmpeg` recorta la imagen de portada. Ambos vienen con FFmpeg |
| Una carpeta de videos, en la máquina que ejecuta el addon | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`, en cualquier subcarpeta |

Esta página escribe la dirección de rex como `192.168.1.20:32400` y ejecuta el addon en la misma máquina que rex. Pon la tuya en su lugar.

## Paso 1. Guarda el addon {#step-1-save-the-addon}

**Qué hace.** Te da todo el addon: un pequeño servidor web para tus vídeos y un bucle que le avisa a rex sobre ellos cada cinco minutos.

Guarda esto como `homevideos.py`:

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

## Paso 2. Rellena la configuración {#step-2-fill-in-the-settings}

**Qué hace.** Apunta el addon a tu carpeta y a tu rex.

Cambia las cuatro líneas debajo del docstring:

| Ajuste | Qué poner |
|---|---|
| `FOLDER` | La carpeta de tus videos, como `"/srv/videos/home"`, o `os.path.expanduser("~/Videos/Home")` si está dentro de tu carpeta personal |
| `REX` | La dirección de rex, tal como la abres en el paso 3 de [rex con tu propia app](any-source.md) |
| `LISTEN` | Dónde responde el addon. Deja `127.0.0.1` si el addon corre en la misma máquina que rex. En otra máquina, pon la IP de LAN de esa máquina (rex lee los videos desde ahí, así que debe ser accesible desde rex) |
| `NAME`, `LIBRARY` | El nombre del addon en rex y el título de la biblioteca. No cambies `NAME` una vez que lo hayas ejecutado: las filas de rex le pertenecen |

## Paso 3. Ejecútalo {#step-3-run-it}

+++ Linux y macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**Qué deberías ver.** La primera ejecución analiza cada vídeo y extrae una imagen fija de cada uno, y luego los envía:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

El log de rex muestra el origen y la nueva biblioteca, y después los vídeos:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Abre una app de Plex: **Home Videos** está en More (fíjalo para verlo en Home). Cada vídeo tiene como título su nombre de archivo, como resumen la carpeta en la que está, como fecha de estreno la fecha del archivo, y una imagen fija tomada a una décima parte del recorrido como póster y como fondo. Dale a reproducir: se reproduce, y saltar a cualquier punto es instantáneo.

Detén el addon con Ctrl+C. Vuelve a ejecutarlo y envía los mismos vídeos como `unchanged` sin analizar nada: los análisis y las imágenes fijas se guardan en una carpeta `.rex` dentro de la carpeta de tus vídeos.

## Paso 4. Mantenlo en marcha {#step-4-keep-it-running}

El complemento tiene que estar en marcha siempre que alguien vea algo: rex lee cada vídeo desde él.

+++ Linux
Crea `~/.config/systemd/user/homevideos.service`, con la carpeta donde guardaste el complemento:

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

Si ejecutaste `sudo loginctl enable-linger "$USER"` para rex, el complemento también sigue funcionando después de cerrar sesión.
+++ macOS y Windows
Inícialo de la misma forma que inicias rex en el paso 1 de [rex con tu propia app](any-source.md#step-1-install-rex): un LaunchAgent en macOS, una tarea programada en Windows, con `python3 homevideos.py` (`python homevideos.py` en Windows) como comando y la carpeta del complemento como carpeta de trabajo.
+++

## Cómo funciona {#how-it-works}

Cada parte del archivo es un paso de [Building rex addons](addons.md):

| Parte | Paso | Qué hace |
|---|---|---|
| `Handler` | [1. Serve the bytes](addons.md#step-1-serve-the-bytes) | Responde a `GET /home/<file>` con el archivo, y a una petición `Range` solo con esos bytes (`206`), para que buscar en el video no lea desde el principio. `GET /stills/<name>.jpg` sirve los pósters. Cualquier cosa fuera de la carpeta es un `404` |
| `sync()`, primera línea | [2. Register](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` con la dirección del addon y un solo directorio, `home`, como biblioteca de películas. Se envía en cada ronda: registrarse otra vez no cambia nada |
| `describe()` | [3. Describe each video](addons.md#step-3-describe-each-video) | El `id` del video es su ruta en tu carpeta, así que si renombras un archivo se convierte en un título nuevo, sin su historial de reproducción. `kind: "movie"` hace que cada video sea una película propia, así que no hay que numerar nada. `media_info` es la salida de `ffprobe`, completa |
| `describe()`, `display` | [4. Name and dress it](addons.md#step-4-name-and-dress-it) | Título, resumen, fecha e imágenes. La URL del fotograma está bajo la dirección del propio addon, que es el único lugar de tu red desde el que rex descarga imágenes |
| `sync()`, el resto | [5. Send it](addons.md#step-5-send-it) | Una instantánea de todos los videos, con 200 una petición, así que un video que borres de la carpeta sale de la biblioteca en la siguiente ronda |

Las protecciones evitan que un mal momento vacíe tu biblioteca: una carpeta vacía o inexistente no envía nada, un video que `ffprobe` no puede leer se omite y se registra en el log, y el propio rex rechaza una instantánea que eliminaría más de la mitad de los videos.

## Cámbialo {#change-it}

- **Series en lugar de películas.** Envía `"kind": "episode"` con los números `season` y `episode` y `display.show`, y registra el directorio como `"shows"`. Numera los episodios para que un video nuevo nunca cambie a los demás: por fecha, no por posición en la carpeta. Ver [Paso 3](addons.md#step-3-describe-each-video).
- **Tus propios títulos.** Léelos de un archivo sidecar o de las etiquetas del video (`media_info["format"]["tags"]`) en lugar del nombre del archivo.
- **Subtítulos, colecciones, capítulos.** Archivos `.srt` junto a un video, una colección por carpeta, marcas de capítulo: ver [Más sobre tu addon](addon-more.md).
- **Permitir que las apps de Plex borren.** Añade un `do_DELETE` que borre el archivo y responda `204`. Sin él, el addon responde `501`, rex conserva el video (su log dice `DELETE refused by the source, row kept: home/... at homevideos: 501`) y la app dice que no se pudo borrar.

## Solución de problemas {#troubleshooting}

| Lo que ves | Por qué | Solución |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex no está en marcha, o `REX` no es su dirección | Inicia rex o corrige `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | Más de la mitad de los vídeos que rex tiene de este addon han desaparecido de la carpeta: un disco que no está montado, un `FOLDER` incorrecto o una limpieza grande | Si era lo que querías, ejecuta una vez `REX_FORCE=1 python3 homevideos.py`. Si no, corrige la carpeta; no se ha borrado nada |
| `no videos found in ...: not sending a snapshot` | La carpeta está vacía, no existe o no tiene archivos de vídeo | Corrige `FOLDER` |
| `skipped <file>: ...` | `ffprobe` no ha podido leerlo (un archivo roto o sin terminar) | Se vuelve a intentar en la siguiente ronda |
| `rejected: {'id': ..., 'reason': ...}` | rex ha rechazado un vídeo y dice por qué | Consulta [Building rex addons, Troubleshooting](addons.md#troubleshooting) |
| La biblioteca está, pero los pósters aparecen en blanco | Falta `ffmpeg`, o rex no puede acceder a `LISTEN` | Instala FFmpeg; si el addon está en otra máquina, pon `LISTEN` con la IP de la LAN de esa máquina, no `127.0.0.1` |
| La reproducción falla, y el log de rex dice `PART ... upstream failed: <urlopen error Connection refused ...>` | El addon no está en marcha, o rex no puede acceder a `LISTEN` | Inicia el addon. Si está en otra máquina, pon `LISTEN` con la IP de la LAN de esa máquina |

¿Sigues atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
