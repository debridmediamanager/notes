# Tutoriel : un addon IPTV {#tutorial-an-iptv-addon}

Ce tutoriel transforme une playlist IPTV (M3U) et un guide TV (XMLTV) en chaînes **Live TV** dans Plex Web et
Plex pour Android. Chaque chaîne garde son numéro et son guide. Ça marche avec les chaînes M3U qui utilisent HLS (`.m3u8`)
et avec n'importe quel guide XMLTV qui les nomme.

Il suit [Créer des addons rex](addons.md) et sa section [Live TV](addons.md#live-tv). Lis le
[tutoriel vidéos personnelles](addon-home-videos.md) d'abord si c'est ton premier addon. Pour le sport en direct, utilise
[Live TV avec rex](live-tv.md).

| Il te faut | Pourquoi |
|---|---|
| rex 2026.11.02 ou plus récent, installé comme dans [rex avec ta propre app](any-source.md) (étapes 1 à 3) et réclamé | Live TV est dans ses apps Plex |
| FFmpeg là où rex tourne | rex convertit une chaîne pendant que quelqu'un la regarde. Voir [Conversion vidéo](any-source.md#converting-video-optional) |
| Python 3.8 ou plus récent et `ffprobe` là où l'addon tourne | L'addon, bibliothèque standard seulement. `ffprobe` vérifie chaque chaîne une fois par jour |
| Une playlist M3U | Une URL ou un fichier, avec des lignes `#EXTINF`. `tvg-id` relie une chaîne à son guide, `tvg-chno` donne son numéro, `tvg-logo` son logo, `group-title` son groupe |
| Un guide XMLTV (facultatif) | Une URL ou un fichier, gzippé ou non. Sans guide, les chaînes sont listées sans rien dans le guide |

Cette page écrit l'adresse de rex `192.168.1.20:32400` et fait tourner l'addon sur la machine de rex.

## Étape 1. Enregistrer l'addon {#step-1-save-the-addon}

Enregistrez ceci sous `iptv.py` :

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

## Étape 2. Remplir les paramètres {#step-2-fill-in-the-settings}

| Paramètre | Mettez |
|---|---|
| `PLAYLIST` | L'URL de votre M3U, ou son chemin sur cette machine |
| `GUIDE` | L'URL ou le chemin de votre guide XMLTV. Le lien de guide d'un fournisseur se termine généralement par `xmltv.php`, `.xml` ou `.xml.gz` |
| `GROUPS` | Uniquement les groupes que vous voulez, sous leurs valeurs `group-title` : `["News", "Sports"]`. Gardez `[]` pour toutes les chaînes. Chaque chaîne est vérifiée avec `ffprobe` (quelques secondes chacune), donc une liste de milliers prend du temps : choisissez des groupes |
| `REX`, `LISTEN` | L'adresse de rex, et l'endroit où l'addon répond (`127.0.0.1` si l'addon est sur la machine de rex) |
| `NAME`, `LIBRARY` | Le nom de l'addon dans rex et le titre de la bibliothèque qui contient aussi les chaînes. Gardez `NAME` une fois que vous l'avez lancé |
| `FIRST` | Le numéro que reçoit la première chaîne sans `tvg-chno`. Choisissez des numéros éloignés de ceux des autres addons Live TV, par exemple `500` |

## Étape 3. Lancer-le {#step-3-run-it}

+++ Linux et macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**Ce que vous devriez voir.** Une ligne pour chaque chaîne qui n'a pas pu être vérifiée, puis le total :

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

Le journal de rex affiche la bibliothèque créée pour les chaînes et les chaînes qui arrivent :

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Dans Plex Web ou Plex pour Android, ouvrez **Live TV** : un onglet portant le nom de votre rex affiche les chaînes avec leurs numéros, et le guide va de trois heures en arrière à une semaine à l'avance. Choisissez ce qui est en cours et appuyez sur **Watch Now** : la lecture démarre après quelques secondes, le temps que rex met à lancer la conversion. What's On affiche ce qui passe maintenant et plus tard ; un épisode de la catégorie `News` ou `Sports` du guide apparaît dans ces sections.

L'addon vérifie la playlist et renvoie le guide toutes les 30 minutes. Pour le faire tourner en continu, configurez-le comme l'addon home videos : [Étape 4](addon-home-videos.md#step-4-keep-it-running), avec `iptv.py` à la place de `homevideos.py`.

## Comment ça marche {#how-it-works}

| Partie | Ce qu'elle fait |
|---|---|
| `channels()` | Lit la playlist : chaque ligne `#EXTINF` et l'URL qui suit. La clé d'une chaîne, qui est son `id` dans rex pour de bon, est son `tvg-id` (ou son nom) |
| `Handler` | Sert `/tv/<key>.m3u8` comme redirection vers le flux de la chaîne. rex la suit à chaque fois que quelqu'un se met sur la chaîne, et l'addon recherche le flux à ce moment-là, donc les liens qui expirent continuent de fonctionner |
| `best_variant()` | Prend la meilleure qualité d'un flux qui en propose plusieurs (une playlist HLS maîtresse), pour que ce qui se lit soit ce qui a été vérifié |
| `probe()` | `ffprobe` du flux, gardé un jour. rex en a besoin pour connaître l'image et le son de la chaîne, et considère la chaîne comme un direct parce que son probe n'a pas de durée. Un flux qui n'est pas en HLS, ou qui ne répond pas, est ignoré pour ce tour |
| `guides()` | Lit le fichier XMLTV une fois par tour et garde les programmes de chaque chaîne, de trois heures en arrière à une semaine en avant : titre, description, catégories, image, et `previously-shown` (une rediffusion). Un programme avec un numéro d'épisode `xmltv_ns` devient un épisode de son émission, numéroté à partir de 1 (XMLTV compte à partir de 0) |
| `number_for()` | Donne à chaque chaîne son numéro une seule fois et le garde dans `~/.rex-iptv.json` : le `tvg-chno` de la playlist si aucune autre chaîne ne l'a, sinon le prochain numéro libre à partir de `FIRST`. Les favoris dans les applis Plex sont gardés par numéro, donc une chaîne doit conserver le sien |
| `sync()` | S'enregistre avec `"trash": false`, donc une chaîne qui quitte la playlist est supprimée, et non gardée dans la corbeille de rex. Chaque chaîne est envoyée avec son `channel` : numéro, nom et guide. Un instantané de toutes les chaînes, 100 par requête (une semaine de guide chacune) |

## Le modifier {#change-it}

- **Flux qui ne sont pas HLS.** Beaucoup de fournisseurs proposent aussi chaque chaîne en MPEG-TS (`.ts`). rex accepte une chaîne en direct sous forme de flux HLS (`.m3u8`), donc cet addon ignore les autres : demandez à votre fournisseur des liens HLS (souvent `output=m3u8` dans l'URL de la playlist).
- **Vos propres numéros.** Modifiez les numéros dans `~/.rex-iptv.json` pendant que l'addon est arrêté ; le prochain cycle les enverra.
- **Logos.** `tvg-logo` devient l'image de la chaîne dans sa bibliothèque. La grille du guide affiche les numéros et les noms.
- **Un guide d'ailleurs.** Tout ce qui connaît le programme peut alimenter `guide` : une API JSON de fournisseur, un calendrier sportif, une boucle fixe. rex-live-sports construit des guides à partir du scoreboard d'ESPN, voir [Live TV avec rex](live-tv.md).

## Dépannage {#troubleshooting}

| Vous voyez | Pourquoi | Solution |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | La chaîne est en MPEG-TS ou dans un autre format, ou son flux a répondu par une erreur (la raison est à la fin) | Utilisez le lien HLS de la chaîne ; un flux en panne est réessayé au prochain passage |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`, `actively refused it` sous Windows, ou `HTTP Error 403`) | Le flux n'a pas répondu, ou il a refusé cette machine | Vérifiez le lien dans un lecteur sur la même machine. Les liens IPTV ne fonctionnent souvent que depuis l'adresse qui s'est connectée |
| `no channel could be probed: not sending a snapshot` | Aucune chaîne n'a répondu : le fournisseur est en panne, ou la playlist est vide | Rien n'est supprimé. Vérifiez `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` sous Windows) | rex ne tourne pas, ou `REX` n'est pas la bonne adresse | Démarrez rex, ou corrigez `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | Plus de la moitié des chaînes ont quitté la playlist, ou ont échoué à leur vérification, d'un coup | Si c'est voulu, lancez une fois avec `REX_FORCE=1` ; sinon, attendez que le fournisseur revienne |
| Une chaîne n'a aucun programme dans le guide | Son `tvg-id` ne correspond à aucun `<channel id>` du guide, ou le guide n'a rien pour cette semaine | Faites correspondre le `tvg-id` de la playlist aux ids du guide |
| Le Live TV manque dans une application Plex | Aucune chaîne n'a encore été envoyée, ou l'application n'est ni Plex Web ni Plex pour Android, les seules testées | Lancez l'addon, et utilisez Plex Web ou Plex pour Android |
| Watch Now ne fonctionne pas | rex n'a pas FFmpeg, ou le flux s'est arrêté | Le log de rex indique la cause. Pour FFmpeg, voir [Conversion vidéo](any-source.md#converting-video-optional) |

Toujours bloqué ? Posez votre question dans le forum **rex-support** sur [Discord](https://discord.com/invite/7u4YjMThXP).
