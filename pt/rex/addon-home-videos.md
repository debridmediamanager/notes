# Tutorial: um addon de vídeos caseiros {#tutorial-a-home-videos-addon}

Este tutorial cria um addon do rex em um único arquivo Python. Ele coloca seus clipes do celular, arquivos de filmadora ou gravações de tela em uma biblioteca **Home Videos** em todos os apps do Plex. Cada vídeo recebe título, data e uma imagem de capa.
Nada é copiado nem enviado. O rex lê o arquivo do seu addon quando você aperta play.

É a versão mais curta que funciona de [Construindo addons do rex](addons.md), passos 1 a 5. Esta página diz o que digitar.
Aquela explica o porquê. Os tutoriais de [música](addon-music.md) e [IPTV](addon-iptv.md) usam o mesmo esqueleto.

| Você precisa de | Por quê |
|---|---|
| rex, configurado como em [rex com seu próprio app](any-source.md) (passos 1 a 3) | É ali que a biblioteca aparece. Reivindicado, para que os apps do Plex possam vê-la |
| Python 3.8 ou mais novo | O addon. Ele usa apenas a biblioteca padrão do Python |
| `ffprobe` e `ffmpeg` | `ffprobe` descreve cada vídeo para o rex, `ffmpeg` recorta a imagem de capa. Os dois vêm com o FFmpeg |
| Uma pasta de vídeos, na máquina que roda o addon | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`, em qualquer subpasta |

Esta página escreve o endereço do rex como `192.168.1.20:32400` e roda o addon na mesma máquina do rex. Coloque o seu no lugar.

## Passo 1. Salve o addon {#step-1-save-the-addon}

**O que ele faz.** Te dá o addon inteiro: um pequeno servidor web para os seus vídeos e um loop que avisa o rex sobre eles a cada cinco minutos.

Salve isto como `homevideos.py`:

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

## Passo 2. Preencha as configurações {#step-2-fill-in-the-settings}

**O que faz.** Aponta o addon para a sua pasta e o seu rex.

Mude as quatro linhas abaixo da docstring:

| Configuração | Coloque |
|---|---|
| `FOLDER` | A pasta dos seus vídeos, como `"/srv/videos/home"`, ou `os.path.expanduser("~/Videos/Home")` se ela estiver dentro da sua pasta pessoal |
| `REX` | O endereço do rex, como você o abre no passo 3 de [rex com o seu próprio app](any-source.md) |
| `LISTEN` | Onde o addon responde. Mantenha `127.0.0.1` se o addon roda na mesma máquina do rex. Em outra máquina, coloque o IP da LAN dessa máquina (o rex lê os vídeos dela, então precisa conseguir alcançá-la a partir do rex) |
| `NAME`, `LIBRARY` | O nome do addon no rex e o título da biblioteca. Mantenha o `NAME` depois de rodar pela primeira vez: as linhas do rex pertencem a ele |

## Passo 3. Execute {#step-3-run-it}

+++ Linux e macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**O que você deve ver.** Na primeira execução, o rex faz a sondagem de cada vídeo, gera um quadro de cada um e envia tudo:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

O log do rex mostra a origem e a nova biblioteca, depois os vídeos:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Abra um app do Plex: **Home Videos** fica em More (fixe-o para vê-lo na tela inicial). Cada vídeo tem o nome do arquivo como título, a pasta em que está como resumo, a data do arquivo como data de lançamento, e um quadro tirado a um décimo do início como pôster e plano de fundo. Dê play: ele toca, e pular para outro ponto é instantâneo.

Pare o addon com Ctrl+C. Ao rodar de novo, ele envia os mesmos vídeos como `unchanged` sem fazer nenhuma sondagem: as sondagens e os quadros ficam guardados em uma pasta `.rex` dentro da pasta dos seus vídeos.

## Passo 4. Mantenha em execução {#step-4-keep-it-running}

O addon precisa estar rodando sempre que alguém assistir: o rex lê cada vídeo a partir dele.

+++ Linux
Crie `~/.config/systemd/user/homevideos.service`, com a pasta onde você salvou o addon:

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

Se você rodou `sudo loginctl enable-linger "$USER"` para o rex, o addon continua rodando mesmo depois que você sair da sessão.
+++ macOS e Windows
Inicie-o do mesmo jeito que você inicia o rex no passo 1 de [rex com seu próprio app](any-source.md#step-1-install-rex): um LaunchAgent no macOS, uma tarefa agendada no Windows, com `python3 homevideos.py` (`python homevideos.py` no Windows) como comando e a pasta do addon como pasta de trabalho.
+++

## Como funciona {#how-it-works}

Cada parte do arquivo é um passo de [Criando addons para o rex](addons.md):

| Parte | Passo | O que faz |
|---|---|---|
| `Handler` | [1. Sirva os bytes](addons.md#step-1-serve-the-bytes) | Responde a `GET /home/<file>` com o arquivo, e uma requisição `Range` com só esses bytes (`206`), para que buscar um trecho não leia desde o início. `GET /stills/<name>.jpg` serve os pôsteres. Qualquer coisa fora da pasta retorna `404` |
| `sync()`, primeira linha | [2. Registre no rex](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` com o endereço do addon e um diretório, `home`, como uma biblioteca de filmes. Enviado a cada rodada: registrar de novo não muda nada |
| `describe()` | [3. Descreva cada vídeo](addons.md#step-3-describe-each-video) | O `id` do vídeo é o caminho dele na sua pasta, então se você renomear um arquivo, ele vira um título novo, sem o histórico de exibição. `kind: "movie"` faz cada vídeo ser um filme próprio, então nada precisa ser numerado. `media_info` é a saída completa do `ffprobe` |
| `describe()`, `display` | [4. Dê nome e visual](addons.md#step-4-name-and-dress-it) | Título, sinopse, data e imagens. A URL da imagem fica sob o endereço do próprio addon, que é o único lugar da sua rede de onde o rex busca imagens |
| `sync()`, o resto | [5. Envie](addons.md#step-5-send-it) | Um snapshot de todos os vídeos, 200 por requisição, então um vídeo que você apagar da pasta sai da biblioteca na próxima rodada |

As proteções evitam que um momento ruim esvazie sua biblioteca: uma pasta vazia ou inexistente não envia nada, um vídeo que o `ffprobe` não consegue ler é pulado e registrado no log, e o próprio rex recusa um snapshot que removeria mais da metade dos vídeos.

## Altere {#change-it}

- **Séries em vez de filmes.** Envie `"kind": "episode"` com os números de `season` e `episode` e `display.show`, e registre o diretório como `"shows"`. Numere os episódios para que um vídeo novo nunca mude a ordem dos outros: por data, não pela posição na pasta. Veja [Passo 3](addons.md#step-3-describe-each-video).
- **Seus próprios títulos.** Leia-os de um arquivo sidecar ou das tags do vídeo (`media_info["format"]["tags"]`) em vez do nome do arquivo.
- **Legendas, coleções, capítulos.** Arquivos `.srt` ao lado de um vídeo, uma coleção por pasta, marcas de capítulo: veja [Mais sobre o seu addon](addon-more.md).
- **Deixe os apps do Plex apagarem.** Adicione um `do_DELETE` que apague o arquivo e responda `204`. Sem ele, o addon responde `501`, o rex mantém o vídeo (o log dele diz `DELETE refused by the source, row kept: home/... at homevideos: 501`), e o app informa que não foi possível apagar.

## Solução de problemas {#troubleshooting}

| Você vê | Por quê | Solução |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | O rex não está rodando, ou `REX` não é o endereço dele | Inicie o rex, ou corrija `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | Mais da metade dos vídeos que o rex tem deste addon sumiu da pasta: um disco que não está montado, um `FOLDER` errado ou uma limpeza grande | Se foi intencional, rode uma vez com `REX_FORCE=1 python3 homevideos.py`. Caso contrário, corrija a pasta; nada foi removido |
| `no videos found in ...: not sending a snapshot` | A pasta está vazia, não existe ou não tem arquivos de vídeo | Corrija `FOLDER` |
| `skipped <file>: ...` | O `ffprobe` não conseguiu ler o arquivo (um arquivo quebrado ou incompleto) | Ele será tentado de novo na próxima rodada |
| `rejected: {'id': ..., 'reason': ...}` | O rex recusou um vídeo e informa o motivo | Veja [Building rex addons, Troubleshooting](addons.md#troubleshooting) |
| A biblioteca aparece, mas os pôsteres estão em branco | O `ffmpeg` não está instalado, ou o rex não consegue acessar `LISTEN` | Instale o FFmpeg; com o addon em outra máquina, defina `LISTEN` como o IP da LAN dessa máquina, e não `127.0.0.1` |
| A reprodução falha, e o log do rex diz `PART ... upstream failed: <urlopen error Connection refused ...>` | O addon não está rodando, ou o rex não consegue acessar `LISTEN` | Inicie o addon. Com ele em outra máquina, defina `LISTEN` como o IP da LAN dessa máquina |

Ainda travado? Pergunte no fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP).
