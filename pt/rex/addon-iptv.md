# Tutorial: um addon de IPTV {#tutorial-an-iptv-addon}

Este tutorial transforma uma playlist de IPTV (M3U) e um guia de programação (XMLTV) em canais de **Live TV** no Plex Web e no Plex para Android. Cada canal mantém o número e o guia. Funciona com canais M3U que usam HLS (`.m3u8`) e com qualquer guia XMLTV que os identifique.

Ele segue [Criando addons para o rex](addons.md) e a seção dele sobre [Live TV](addons.md#live-tv). Leia primeiro o [tutorial de vídeos caseiros](addon-home-videos.md) se esta for sua primeira vez com um addon. Para esportes ao vivo, use [Live TV com o rex](live-tv.md).

| Você precisa | Por quê |
|---|---|
| rex 2026.11.02 ou mais novo, configurado como em [rex com seu próprio app](any-source.md) (passos 1 a 3) e vinculado | Live TV fica nos apps do Plex |
| FFmpeg onde o rex roda | O rex converte um canal enquanto alguém assiste. Veja [Convertendo vídeo](any-source.md#converting-video-optional) |
| Python 3.8 ou mais novo e `ffprobe` onde o addon roda | O addon usa só a biblioteca padrão. O `ffprobe` verifica cada canal uma vez por dia |
| Uma playlist M3U | Uma URL ou um arquivo, com linhas `#EXTINF`. `tvg-id` liga um canal ao guia, `tvg-chno` dá o número, `tvg-logo` o logo e `group-title` o grupo |
| Um guia XMLTV (opcional) | Uma URL ou um arquivo, compactado em gzip ou não. Sem um, os canais aparecem sem nada no guia |

Esta página escreve o endereço do rex como `192.168.1.20:32400` e roda o addon na máquina do rex.

## Passo 1. Salve o addon {#step-1-save-the-addon}

Salve isso como `iptv.py`:

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

## Passo 2. Preencha as configurações {#step-2-fill-in-the-settings}

| Configuração | Coloque |
|---|---|
| `PLAYLIST` | A URL do seu M3U, ou o caminho dele nesta máquina |
| `GUIDE` | A URL ou o caminho do seu guia XMLTV. O link do guia de um provedor geralmente termina em `xmltv.php`, `.xml` ou `.xml.gz` |
| `GROUPS` | Só os grupos que você quer, pelos valores de `group-title`: `["News", "Sports"]`. Deixe `[]` para todos os canais. Cada canal é verificado com `ffprobe` (alguns segundos cada), então uma lista de milhares demora bastante: escolha grupos |
| `REX`, `LISTEN` | O endereço do rex, e onde o addon responde (`127.0.0.1` com o addon na mesma máquina do rex) |
| `NAME`, `LIBRARY` | O nome do addon no rex e o título da biblioteca que também tem os canais. Mantenha o `NAME` depois de rodar pela primeira vez |
| `FIRST` | O número que o primeiro canal sem `tvg-chno` recebe. Escolha números livres de outros addons de Live TV, como `500` |

## Passo 3. Execute {#step-3-run-it}

+++ Linux e macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**O que você deve ver.** Uma linha para cada canal que não pôde ser verificado, depois o total:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

O log do rex mostra a biblioteca criada para os canais e os canais que chegaram:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

No Plex Web ou no Plex para Android, abra **Live TV**: uma aba com o nome do seu rex lista os canais nos seus números, com o guia de três horas atrás até uma semana à frente. Escolha o que está passando e aperte **Watch Now**: ele começa a tocar em alguns segundos, o tempo que o rex leva para começar a converter. O What's On mostra o que está passando agora e depois; um episódio na categoria `News` ou `Sports` do guia aparece nessas prateleiras.

O addon verifica a playlist e envia o guia de novo a cada 30 minutos. Para mantê-lo rodando, configure-o como o addon de vídeos caseiros: [Passo 4](addon-home-videos.md#step-4-keep-it-running), com `iptv.py` no lugar de `homevideos.py`.

## Como funciona {#how-it-works}

| Parte | O que faz |
|---|---|
| `channels()` | Lê a playlist: cada linha `#EXTINF` e a URL logo depois. A chave de um canal, que é o `id` dele no rex para sempre, é o `tvg-id` (ou o nome) |
| `Handler` | Serve `/tv/<key>.m3u8` como um redirecionamento para o stream do canal. O rex segue esse redirecionamento toda vez que alguém sintoniza o canal, e o addon busca o stream naquele momento, então links que expiram continuam funcionando |
| `best_variant()` | Pega a melhor qualidade de um stream que oferece várias (uma master playlist HLS), para que o que toca seja o que foi verificado |
| `probe()` | `ffprobe` do stream, guardado por um dia. O rex precisa dele para saber a imagem e o som do canal, e trata o canal como ao vivo porque o probe não tem duração. Um stream que não é HLS, ou que não responde, é ignorado nesta rodada |
| `guides()` | Lê o arquivo XMLTV uma vez por rodada e mantém a programação de cada canal de três horas atrás até uma semana à frente: título, descrição, categorias, imagem e `previously-shown` (uma reprise). Uma programação com número de episódio em `xmltv_ns` vira um episódio da sua série, numerado a partir de 1 (o XMLTV conta a partir de 0) |
| `number_for()` | Dá a cada canal o seu número uma única vez e o guarda em `~/.rex-iptv.json`: o `tvg-chno` da playlist quando nenhum outro canal o usa, senão o próximo número livre a partir de `FIRST`. Os favoritos nos apps do Plex são guardados pelo número, então um canal precisa manter o seu |
| `sync()` | Registra com `"trash": false`, então um canal que sai da playlist é apagado, não mandado para a lixeira do rex. Cada canal é enviado com o seu `channel`: número, nome e guia. Um snapshot de todos os canais, 100 por requisição (uma semana de guia em cada) |

## Altere {#change-it}

- **Streams que não são HLS.** Muitos provedores também oferecem cada canal como MPEG-TS (`.ts`). O rex aceita um canal ao vivo como stream HLS (`.m3u8`), então este addon ignora os outros: peça ao seu provedor links HLS (geralmente `output=m3u8` na URL da playlist).
- **Seus próprios números.** Edite os números em `~/.rex-iptv.json` com o addon parado; a próxima rodada os envia.
- **Logos.** `tvg-logo` vira a imagem do canal na sua biblioteca. A grade do guia mostra números e nomes.
- **Um guia de outro lugar.** Qualquer coisa que conheça a programação pode preencher `guide`: uma API JSON de um provedor, uma agenda de esportes, um loop fixo. O rex-live-sports monta guias a partir do placar da ESPN, veja [Live TV com rex](live-tv.md).

## Solução de problemas {#troubleshooting}

| Você vê | Por quê | Solução |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | O canal é MPEG-TS ou outro formato, ou o stream respondeu com um erro (o motivo fica no final) | Use o link HLS do canal; um stream que está fora do ar é tentado de novo na próxima rodada |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`, `actively refused it` no Windows, ou `HTTP Error 403`) | O stream não respondeu, ou recusou esta máquina | Teste o link em um player na mesma máquina. Links de IPTV costumam funcionar só a partir do endereço que fez o login |
| `no channel could be probed: not sending a snapshot` | Nenhum canal respondeu: o provedor está fora do ar, ou a playlist está vazia | Nada é removido. Verifique `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` no Windows) | O rex não está rodando, ou `REX` não é o endereço dele | Inicie o rex, ou corrija `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | Mais da metade dos canais saiu da playlist, ou falhou na verificação, de uma vez | Se foi intencional, rode uma vez com `REX_FORCE=1`; caso contrário, espere o provedor voltar |
| Um canal não tem nada no guia | O `tvg-id` dele não corresponde a nenhum `<channel id>` no guia, ou o guia não tem nada para esta semana | Ajuste o `tvg-id` da playlist para bater com os ids do guia |
| A TV ao vivo não aparece em um app do Plex | Nenhum canal foi enviado ainda, ou o app não é o Plex Web nem o Plex para Android, os únicos testados | Rode o addon e use o Plex Web ou o Plex para Android |
| Watch Now falha | O rex não tem FFmpeg, ou o stream parou | O log do rex mostra o motivo. Para o FFmpeg, veja [Converting video](any-source.md#converting-video-optional) |

Ainda travado? Pergunte no fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP).
