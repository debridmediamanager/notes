# Tutorial: un complemento de IPTV {#tutorial-an-iptv-addon}

Este tutorial convierte una lista de IPTV (M3U) y una guía de TV (XMLTV) en canales de **Live TV** en Plex Web y Plex para Android. Cada canal conserva su número y su guía. Funciona con canales M3U que usan HLS (`.m3u8`) y con cualquier guía XMLTV que los nombre.

Sigue [Crear addons de rex](addons.md) y su sección [Live TV](addons.md#live-tv). Lee primero el [tutorial de vídeos personales](addon-home-videos.md) si es tu primer addon. Para deportes en directo usa [Live TV con rex](live-tv.md).

| Necesitas | Por qué |
|---|---|
| rex 2026.11.02 o más reciente, configurado como en [rex con tu propia app](any-source.md) (pasos 1 a 3) y reclamado | Live TV está en sus apps de Plex |
| FFmpeg donde se ejecuta rex | rex convierte un canal mientras alguien lo ve. Consulta [Convertir vídeo](any-source.md#converting-video-optional) |
| Python 3.8 o más reciente y `ffprobe` donde se ejecuta el addon | El addon usa solo la biblioteca estándar. `ffprobe` comprueba cada canal una vez al día |
| Una lista M3U | Una URL o un archivo, con líneas `#EXTINF`. `tvg-id` vincula un canal con su guía, `tvg-chno` da su número, `tvg-logo` su logo y `group-title` su grupo |
| Una guía XMLTV (opcional) | Una URL o un archivo, comprimido con gzip o no. Sin ella, los canales aparecen sin nada en la guía |

Esta página escribe la dirección de rex como `192.168.1.20:32400` y ejecuta el addon en la misma máquina que rex.

## Paso 1. Guarda el addon {#step-1-save-the-addon}

Guarda esto como `iptv.py`:

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

## Paso 2. Rellena la configuración {#step-2-fill-in-the-settings}

| Setting | Poner |
|---|---|
| `PLAYLIST` | La URL de tu M3U, o su ruta en esta máquina |
| `GUIDE` | La URL o ruta de tu guía XMLTV. El enlace de la guía de un proveedor normalmente termina en `xmltv.php`, `.xml` o `.xml.gz` |
| `GROUPS` | Solo los grupos que quieras, como sus valores de `group-title`: `["News", "Sports"]`. Deja `[]` para todos los canales. Cada canal se comprueba con `ffprobe` (unos segundos cada uno), así que una lista de miles tarda mucho: elige grupos |
| `REX`, `LISTEN` | La dirección de rex, y en qué dirección responde el addon (`127.0.0.1` con el addon en la misma máquina que rex) |
| `NAME`, `LIBRARY` | El nombre del addon en rex y el título de la biblioteca que también contiene los canales. Mantén `NAME` una vez lo hayas ejecutado |
| `FIRST` | El número que recibe el primer canal sin `tvg-chno`. Elige números libres de los de otros addons de Live TV, como `500` |

## Paso 3. Ejecútalo {#step-3-run-it}

+++ Linux y macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**Lo que deberías ver.** Una línea por cada canal que no se pudo comprobar, y luego el total:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

El registro de rex muestra la biblioteca creada para los canales y los canales que van llegando:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

En Plex Web o Plex para Android, abre **Live TV**: una pestaña con el nombre de tu rex lista los canales con sus números, con la guía desde hace tres horas hasta una semana por delante. Elige lo que está en emisión y pulsa **Watch Now**: se reproduce tras unos segundos, el tiempo que tarda rex en empezar a convertirlo. What's On muestra lo que está en emisión ahora y lo que viene después; un episodio de la categoría `News` o `Sports` de la guía aparece en esas estanterías.

El addon comprueba la playlist y vuelve a enviar la guía cada 30 minutos. Para mantenerlo en marcha, configúralo igual que el addon de vídeos caseros: [Paso 4](addon-home-videos.md#step-4-keep-it-running), con `iptv.py` en lugar de `homevideos.py`.

## Cómo funciona {#how-it-works}

| Parte | Qué hace |
|---|---|
| `channels()` | Lee la lista de reproducción: cada línea `#EXTINF` y la URL que va después. La clave de un canal, que es su `id` en rex para siempre, es su `tvg-id` (o su nombre) |
| `Handler` | Sirve `/tv/<key>.m3u8` como una redirección al stream del canal. rex la sigue cada vez que alguien sintoniza, y el addon busca el stream en ese momento, así que los enlaces que caducan siguen funcionando |
| `best_variant()` | Toma la mejor calidad de un stream que ofrece varias (una playlist maestra HLS), para que lo que se reproduce sea lo que se comprobó |
| `probe()` | `ffprobe` del stream, guardado durante un día. rex lo necesita para saber la imagen y el sonido del canal, y trata el canal como en directo porque su probe no tiene duración. Un stream que no es HLS, o que no responde, se salta en esta ronda |
| `guides()` | Lee el archivo XMLTV una vez por ronda y guarda los programas de cada canal desde hace tres horas hasta una semana hacia adelante: título, descripción, categorías, imagen y `previously-shown` (una repetición). Un programa con un número de episodio `xmltv_ns` se convierte en un episodio de su serie, numerado desde 1 (XMLTV cuenta desde 0) |
| `number_for()` | Asigna a cada canal su número una sola vez y lo guarda en `~/.rex-iptv.json`: el `tvg-chno` de la lista de reproducción si ningún otro canal lo tiene, si no, el siguiente libre a partir de `FIRST`. Los favoritos en las apps de Plex se guardan por número, así que un canal debe conservarlo |
| `sync()` | Se registra con `"trash": false`, así que un canal que sale de la lista de reproducción se borra, no se guarda en la papelera de rex. Cada canal se envía con su `channel`: número, nombre y guía. Una copia de todos los canales, 100 por petición (con una semana de guía cada uno) |

## Cámbialo {#change-it}

- **Streams que no son HLS.** Muchos proveedores también ofrecen cada canal como MPEG-TS (`.ts`). rex toma un canal en vivo como stream HLS (`.m3u8`), así que este addon omite los demás: pide a tu proveedor enlaces HLS (a menudo `output=m3u8` en la URL de la lista de reproducción).
- **Tus propios números.** Edita los números en `~/.rex-iptv.json` mientras el addon está detenido; la siguiente ronda los envía.
- **Logos.** `tvg-logo` se convierte en la imagen del canal en su biblioteca. La parrilla de la guía muestra números y nombres.
- **Una guía de otro sitio.** Cualquier cosa que conozca el horario puede alimentar `guide`: una API JSON de un proveedor, un calendario deportivo, un bucle fijo. rex-live-sports construye guías a partir del marcador de ESPN, ver [Live TV with rex](live-tv.md).

## Solución de problemas {#troubleshooting}

| Lo que ves | Por qué | Solución |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | El canal es MPEG-TS u otro formato, o su stream respondió con un error (el motivo está al final) | Usa el enlace HLS del canal; un stream que está caído se vuelve a probar en la siguiente ronda |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`, `actively refused it` en Windows, o `HTTP Error 403`) | El stream no respondió, o rechazó esta máquina | Comprueba el enlace en un reproductor desde la misma máquina. Los enlaces de IPTV a menudo solo funcionan desde la dirección que inició sesión |
| `no channel could be probed: not sending a snapshot` | Ningún canal respondió: el proveedor está caído, o la lista de reproducción está vacía | No se elimina nada. Revisa `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` en Windows) | rex no está en ejecución, o `REX` no es su dirección | Inicia rex, o corrige `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | Más de la mitad de los canales salieron de la lista de reproducción, o fallaron su comprobación, de golpe | Si era lo que querías, ejecútalo una vez con `REX_FORCE=1`; si no, espera a que el proveedor vuelva |
| Un canal no tiene nada en la guía | Su `tvg-id` no coincide con ningún `<channel id>` de la guía, o la guía no tiene nada para esta semana | Haz que el `tvg-id` de la lista de reproducción coincida con los ids de la guía |
| No aparece la TV en vivo en una app de Plex | Todavía no se envió ningún canal, o la app no es Plex Web ni Plex para Android, las únicas probadas | Ejecuta el addon, y usa Plex Web o Plex para Android |
| Watch Now falla | rex no tiene FFmpeg, o el stream se detuvo | El log de rex indica el motivo. Para FFmpeg, consulta [Converting video](any-source.md#converting-video-optional) |

¿Sigues atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
