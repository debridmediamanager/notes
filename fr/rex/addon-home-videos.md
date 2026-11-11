# Tutoriel : un addon pour vidéos personnelles {#tutorial-a-home-videos-addon}

Ce tutoriel crée un addon rex en un seul fichier Python. Il met tes clips de téléphone, fichiers de caméscope ou enregistrements d'écran
dans une bibliothèque **Home Videos** dans toutes les apps Plex. Chaque vidéo reçoit un titre, une date et une image d'affiche.
Rien n'est copié ni envoyé. rex lit le fichier depuis ton addon quand tu appuies sur lecture.

C'est la version fonctionnelle la plus courte de [Créer des addons rex](addons.md) étapes 1 à 5. Cette page te dit quoi taper.
Celle-là explique pourquoi. Les tutoriels [musique](addon-music.md) et [IPTV](addon-iptv.md) utilisent le même squelette.

| Il te faut | Pourquoi |
|---|---|
| rex, configuré comme dans [rex avec ta propre app](any-source.md) (étapes 1 à 3) | C'est là que la bibliothèque apparaît. Revendiquée, pour que les apps Plex puissent la voir |
| Python 3.8 ou plus récent | L'addon. Il utilise uniquement la bibliothèque standard de Python |
| `ffprobe` et `ffmpeg` | `ffprobe` décrit chaque vidéo pour rex, `ffmpeg` découpe l'image d'affiche. Les deux viennent avec FFmpeg |
| Un dossier de vidéos, sur la machine qui fait tourner l'addon | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`, dans n'importe quel sous-dossier |

Cette page écrit l'adresse de rex `192.168.1.20:32400` et fait tourner l'addon sur la même machine que rex. Mets la tienne à la place.

## Étape 1. Enregistrer l'addon {#step-1-save-the-addon}

**Ce que ça fait.** Ça vous donne tout l'addon : un petit serveur web pour vos vidéos et une boucle qui informe rex à leur sujet toutes les cinq minutes.

Enregistrez ceci sous `homevideos.py` :

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

## Étape 2. Remplir les paramètres {#step-2-fill-in-the-settings}

**Ce que ça fait.** Indique à l'addon ton dossier et ton rex.

Modifie les quatre lignes sous la docstring :

| Réglage | Mets |
|---|---|
| `FOLDER` | Le dossier de tes vidéos, par exemple `"/srv/videos/home"`, ou `os.path.expanduser("~/Videos/Home")` pour un dossier dans ton dossier personnel |
| `REX` | L'adresse de rex, telle que tu l'ouvres à l'étape 3 de [rex avec ta propre application](any-source.md) |
| `LISTEN` | Là où l'addon répond. Garde `127.0.0.1` quand l'addon tourne sur la machine de rex. Sur une autre machine, mets l'IP LAN de cette machine (rex lit les vidéos depuis elle, donc rex doit pouvoir l'atteindre) |
| `NAME`, `LIBRARY` | Le nom de l'addon dans rex et le titre de la bibliothèque. Garde `NAME` une fois que tu l'as lancé : les lignes de rex lui appartiennent |

## Étape 3. Lancer-le {#step-3-run-it}

+++ Linux et macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**Ce que vous devriez voir.** Au premier lancement, rex analyse chaque vidéo, en extrait une image fixe, puis les envoie :

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

Le log de rex affiche la source et la nouvelle bibliothèque, puis les vidéos :

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Ouvrez une application Plex : **Home Videos** se trouve sous More (épinglez-le pour le voir sur Home). Chaque vidéo a le nom de son fichier comme titre, le dossier dans lequel elle se trouve comme résumé, la date du fichier comme date de sortie, et une image fixe prise à un dixième de la vidéo comme affiche et arrière-plan. Appuyez sur lecture : ça marche, et la navigation est instantanée.

Arrêtez l'addon avec Ctrl+C. Relancez-le : il envoie les mêmes vidéos avec `unchanged` sans rien analyser. Les analyses et les images fixes sont conservées dans un dossier `.rex` à l'intérieur du dossier de vos vidéos.

## Étape 4. Le garder en marche {#step-4-keep-it-running}

L'addon doit tourner en permanence pendant qu'on regarde : rex lit chaque vidéo depuis lui.

+++ Linux
Crée `~/.config/systemd/user/homevideos.service`, avec le dossier dans lequel tu as enregistré l'addon :

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

Si tu as lancé `sudo loginctl enable-linger "$USER"` pour rex, l'addon continue de tourner même après ta déconnexion.
+++ macOS et Windows
Démarre-le comme tu démarres rex à l'étape 1 de [rex avec ta propre app](any-source.md#step-1-install-rex) : un LaunchAgent sous macOS, une tâche planifiée sous Windows, avec `python3 homevideos.py` (`python homevideos.py` sous Windows) comme commande et le dossier de l'addon comme dossier de travail.
+++

## Comment ça marche {#how-it-works}

Chaque partie du fichier correspond à une étape de [Créer des addons rex](addons.md) :

| Partie | Étape | Ce qu'elle fait |
|---|---|---|
| `Handler` | [1. Servir les octets](addons.md#step-1-serve-the-bytes) | Répond à `GET /home/<file>` avec le fichier, et à une requête `Range` avec seulement ces octets (`206`), pour que la recherche dans la vidéo ne lise pas depuis le début. `GET /stills/<name>.jpg` sert les affiches. Tout ce qui est en dehors du dossier donne un `404` |
| `sync()`, première ligne | [2. S'enregistrer auprès de rex](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` avec l'adresse de l'addon et un seul dossier, `home`, comme bibliothèque de films. Envoyé à chaque cycle : s'enregistrer à nouveau ne change rien |
| `describe()` | [3. Décrire chaque vidéo](addons.md#step-3-describe-each-video) | L'`id` de la vidéo est son chemin dans ton dossier, donc si tu renommes un fichier, il devient un nouveau titre, sans son historique de visionnage. `kind: "movie"` fait de chaque vidéo un film à part entière, donc rien n'a besoin d'être numéroté. `media_info` est la sortie complète de `ffprobe` |
| `describe()`, `display` | [4. Nommer et habiller](addons.md#step-4-name-and-dress-it) | Titre, résumé, date et images. L'URL de l'image est sous l'adresse de l'addon lui-même, c'est le seul endroit de ton réseau d'où rex récupère des images |
| `sync()`, le reste | [5. Envoyer](addons.md#step-5-send-it) | Un instantané de chaque vidéo, 200 par requête, donc une vidéo que tu supprimes du dossier quitte la bibliothèque au cycle suivant |

Les garde-fous évitent qu'un mauvais moment vide ta bibliothèque : un dossier vide ou absent n'envoie rien, une vidéo que `ffprobe` ne peut pas lire est ignorée et consignée dans le journal, et rex refuse lui-même un instantané qui supprimerait plus de la moitié des vidéos.

## Le modifier {#change-it}

- **Des séries au lieu de films.** Envoie `"kind": "episode"` avec les numéros `season` et `episode`, ainsi que `display.show`, et déclare le dossier comme `"shows"`. Numérote les épisodes pour qu'une nouvelle vidéo ne décale jamais les autres : par date, pas par position dans le dossier. Voir [Étape 3](addons.md#step-3-describe-each-video).
- **Vos propres titres.** Lis-les depuis un fichier sidecar ou depuis les tags de la vidéo (`media_info["format"]["tags"]`) au lieu du nom du fichier.
- **Sous-titres, collections, chapitres.** Les fichiers `.srt` à côté d'une vidéo, une collection par dossier, les marques de chapitres : voir [Plus d'infos sur votre addon](addon-more.md).
- **Laisser les applis Plex supprimer.** Ajoute un `do_DELETE` qui supprime le fichier et répond `204`. Sans lui, l'addon répond `501`, rex garde la vidéo (son log indique `DELETE refused by the source, row kept: home/... at homevideos: 501`), et l'appli indique qu'elle n'a pas pu être supprimée.

## Dépannage {#troubleshooting}

| Vous voyez | Pourquoi | Solution |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex ne tourne pas, ou `REX` n'est pas son adresse | Lancez rex, ou corrigez `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | Plus de la moitié des vidéos que rex a de cet addon ont disparu du dossier : un disque non monté, un mauvais `FOLDER`, ou un gros nettoyage | Si c'était voulu, lancez une fois `REX_FORCE=1 python3 homevideos.py`. Sinon, corrigez le dossier ; rien n'a été supprimé |
| `no videos found in ...: not sending a snapshot` | Le dossier est vide, absent ou ne contient aucun fichier vidéo | Corrigez `FOLDER` |
| `skipped <file>: ...` | `ffprobe` n'a pas pu le lire (fichier cassé ou incomplet) | Il sera réessayé au prochain cycle |
| `rejected: {'id': ..., 'reason': ...}` | rex a refusé une vidéo et indique pourquoi | Voir [Créer des addons rex, Dépannage](addons.md#troubleshooting) |
| La bibliothèque est là mais les affiches sont vides | `ffmpeg` est absent, ou rex ne peut pas atteindre `LISTEN` | Installez FFmpeg ; si l'addon tourne sur une autre machine, réglez `LISTEN` sur l'IP LAN de cette machine, pas sur `127.0.0.1` |
| La lecture échoue, et le journal de rex indique `PART ... upstream failed: <urlopen error Connection refused ...>` | L'addon ne tourne pas, ou rex ne peut pas atteindre `LISTEN` | Lancez l'addon. S'il tourne sur une autre machine, réglez `LISTEN` sur l'IP LAN de cette machine |

Toujours bloqué ? Demandez dans le forum **rex-support** sur [Discord](https://discord.com/invite/7u4YjMThXP).
