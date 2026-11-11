# Tutorial: um addon de música {#tutorial-a-music-addon}

Este tutorial coloca uma pasta de álbuns em uma biblioteca **Music** que o Plexamp, o Plex Web e o Plex for Android reproduzem.
Ele suporta FLAC, MP3, AAC e outros arquivos comuns. Seus arquivos continuam onde estão. O MusicBrainz fornece os detalhes de álbuns conhecidos. Álbuns desconhecidos usam as tags deles e o `cover.jpg`. Um arquivo `.lrc` ao lado vira letra com tempo.

Ele segue [Building rex addons](addons.md) e a seção [Music](addons.md#music) dele. Leia o
[tutorial de vídeos caseiros](addon-home-videos.md) primeiro se este for seu primeiro addon.

| Você precisa | Por quê |
|---|---|
| rex 2026.11.02 ou mais recente, configurado como em [rex com seu próprio app](any-source.md) (passos 1 a 3) e claimed | O rex pede os nomes dos álbuns ao Plex só depois que ele está claimed |
| Python 3.8 ou mais recente | O addon, só com a biblioteca padrão |
| `ffprobe` | Descreve cada arquivo para o rex e lê as tags dele. Vem com o FFmpeg |
| Seus álbuns, uma pasta por álbum | `Artist/Album/01 Song.flac`, ou qualquer profundidade: toda pasta com arquivos de áudio dentro é um álbum |
| Tags, ou MusicBrainz Picard | O addon lê o álbum e o artista das tags de cada arquivo (senão, dos nomes das pastas). Arquivos marcados pelo [MusicBrainz Picard](https://picard.musicbrainz.org) já trazem o ID da release, que é a correspondência mais segura |

Esta página escreve o endereço do rex como `192.168.1.20:32400` e executa o addon na máquina do rex.

## Passo 1. Salve o addon {#step-1-save-the-addon}

Salve isso como `music.py`:

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

## Passo 2. Preencha as configurações {#step-2-fill-in-the-settings}

| Setting | Put |
|---|---|
| `FOLDER` | Sua pasta de música, como `"/srv/music"` ou `os.path.expanduser("~/Music")` |
| `REX` | O endereço do rex |
| `LISTEN` | Mantenha `127.0.0.1` com o addon na máquina do rex; senão, o IP da LAN dessa máquina |
| `NAME`, `LIBRARY` | O nome do addon no rex e o título da biblioteca de música. Mantenha o `NAME` depois que você tiver executado |

## Passo 3. Execute {#step-3-run-it}

+++ Linux e macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**O que você deve ver.** Para cada álbum sem um release id nas tags, aparece uma linha com a resposta do MusicBrainz e, no final, o total:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

O MusicBrainz aceita um pedido por segundo, então a primeira execução em uma coleção grande demora um pouco: cerca de um segundo por álbum. Cada resposta fica salva em `.rex/albums.json` na sua pasta de música, e as próximas execuções não fazem nenhuma consulta. Álbuns marcados pelo Picard nunca são consultados.

O log do rex mostra cada faixa sendo associada ao seu álbum:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Abra o Plexamp e escolha a biblioteca **Music** do rex como biblioteca dele (o Plex Web e o Plex para Android a listam em More). In Rainbows mostra a capa do Plex, os nomes das faixas e a foto e a biografia do Radiohead, não importa como os seus arquivos se chamem. Garage Demos mostra os nomes das tags e o `cover.jpg` da pasta. Uma música com um arquivo `.lrc` de mesmo nome mostra a letra, linha por linha, conforme toca.

Para mantê-lo rodando, configure-o como o addon de vídeos caseiros: [Step 4](addon-home-videos.md#step-4-keep-it-running), trocando `homevideos.py` por `music.py`.

## Como funciona {#how-it-works}

| Parte | O que faz |
|---|---|
| `Handler` | Atende tudo em `/music/`: as músicas (com `Range`, então buscar um ponto da faixa é instantâneo), as letras `.lrc` delas e as capas dos álbuns |
| `sync()`, primeira linha | Registra o addon com um diretório, `music`, como biblioteca de música: `"directories": [{"name": "music", "music": "Music"}]`. Sem uma biblioteca de música, o rex recusa todas as faixas |
| `album_items()` | Um item por música: `"kind": "track"`, os números `disc` e `track` dela (das tags, senão pela posição na pasta), a saída do `ffprobe` e `ids.mbid`, o id da release do álbum no MusicBrainz. O Plex mostra a própria faixa nesses números dessa release, então os números precisam estar certos |
| `release_id()` | Encontra o id da release de um álbum que não tem um: faz uma busca no MusicBrainz por álbum e artista, mantendo a primeira release oficial com tantas faixas quanto a pasta tiver. Um álbum aparece em várias releases (uma por país, edições deluxe); qualquer uma com as suas faixas dá nome ao álbum |
| `display` | Os nomes do álbum vindos das tags, e a capa dele, mostrada somente quando o Plex não conhece o álbum |
| `lyrics` | Um arquivo `.lrc` (com tempo) ou `.txt` com o nome da música ao lado, enviado como `[{"path": ..., "size": ...}]`. O rex lê de novo só quando o tamanho muda |
| `sync()`, o resto | Um snapshot de cada música, 200 por requisição: um álbum que você apaga sai da biblioteca na próxima rodada (a cada dez minutos) |

O rex não lê tags por conta própria. Tudo que o Plex mostra vem do id da release, ou do seu `display` quando o Plex não tem nada.

## Altere {#change-it}

- **Another layout.** An album split into disc folders (`CD1/`, `CD2/`) is two albums to this addon, each with too few tracks to match. Group such folders in `albums()` and send one `release` for all their files; see [Music](addons.md#music).
- **Artists by their own pictures.** Send `display.artist.poster` and register with `"artwork": "source"`: see [More from your addon](addon-more.md#artist-pictures).
- **Playlists.** Send each song's place in a playlist and rex makes the playlist: see [More from your addon](addon-more.md#collections-and-playlists).
- **Loudness.** If you measure each song's loudness, send it as `loudness` in Plex's names: see [Music](addons.md#music). rex measures nothing itself.

## Solução de problemas {#troubleshooting}

| Você vê | Por quê | Correção |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | Não existe nenhum lançamento oficial com esse título e artista que tenha o seu número de faixas: uma música faltando, uma faixa bônus, um erro de digitação nas tags, ou um álbum que o MusicBrainz não lista | Corrija as tags ou a pasta e depois apague a linha desse álbum em `.rex/albums.json` (ou o arquivo inteiro) para que ele seja consultado de novo. Ou marque o álbum com o Picard |
| Um álbum mostra os nomes errados das músicas | O lançamento encontrado tem o seu número de faixas, mas em outra ordem (outra edição) | Marque o álbum com o Picard, que grava o lançamento exato |
| `MusicBrainz did not answer for ...: asking again next round` | O MusicBrainz estava ocupado ou fora do ar | Nada: a próxima rodada tenta de novo |
| Os álbuns mostram os nomes das tags, mesmo o Plex conhecendo eles | O rex não foi autorizado, ou o id do lançamento não corresponde a nada que o Plex conheça | Autorize o rex: [passo 3 do rex com o seu próprio app](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | A biblioteca foi apagada em um app do Plex | Adicione-a de novo em um app do Plex: Add Library, Music, e escolha a pasta `music` que a lista de pastas oferecer |
| `sync failed, ...: rex answered 409: ...more than half...` | Mais da metade das músicas sumiu da pasta | Se você quis isso, rode uma vez com `REX_FORCE=1`; caso contrário, corrija o `FOLDER` |
| Sem letras | O nome do arquivo `.lrc` é diferente do nome da música, ou a música foi enviada antes de o arquivo existir | Dê a ele o mesmo nome da música (`01 - Song.flac`, `01 - Song.lrc`); a próxima rodada envia o arquivo |

Ainda travado? Pergunte no fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP).
