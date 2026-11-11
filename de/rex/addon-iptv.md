# Anleitung: ein IPTV-Addon {#tutorial-an-iptv-addon}

Dieses Tutorial macht aus einer IPTV-Playlist (M3U) und einem TV-Programm (XMLTV) **Live-TV**-Kanäle in Plex Web und
Plex für Android. Jeder Kanal behält seine Nummer und sein Programm. Es funktioniert mit M3U-Kanälen, die HLS (`.m3u8`) nutzen,
und mit jedem XMLTV-Programm, das sie benennt.

Es folgt [Eigene rex-Addons bauen](addons.md) und dessen Abschnitt [Live-TV](addons.md#live-tv). Lies zuerst die
[Anleitung zu Heimvideos](addon-home-videos.md), wenn dies dein erstes Addon ist. Für Live-Sport nutze
[Live-TV mit rex](live-tv.md).

| Du brauchst | Warum |
|---|---|
| rex 2026.11.02 oder neuer, eingerichtet wie in [rex mit deiner eigenen App](any-source.md) (Schritte 1 bis 3) und beansprucht | Live-TV gibt es in den Plex-Apps |
| FFmpeg dort, wo rex läuft | rex wandelt einen Kanal um, während ihn jemand anschaut. Siehe [Video umwandeln](any-source.md#converting-video-optional) |
| Python 3.8 oder neuer und `ffprobe` dort, wo das Addon läuft | Das Addon nutzt nur die Standardbibliothek. `ffprobe` prüft jeden Kanal einmal am Tag |
| Eine M3U-Playlist | Eine URL oder eine Datei mit `#EXTINF`-Zeilen. `tvg-id` verknüpft einen Kanal mit seinem Programm, `tvg-chno` gibt seine Nummer an, `tvg-logo` sein Logo, `group-title` seine Gruppe |
| Ein XMLTV-Programm (optional) | Eine URL oder eine Datei, gzipped oder nicht. Ohne eines werden die Kanäle ohne Programm in der Übersicht angezeigt |

Diese Seite schreibt die Adresse von rex als `192.168.1.20:32400` und startet das Addon auf dem Rechner von rex.

## Schritt 1. Das Addon speichern {#step-1-save-the-addon}

Speichere das als `iptv.py`:

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

## Schritt 2. Die Einstellungen ausfüllen {#step-2-fill-in-the-settings}

Hier ist die Übersetzung:

| Einstellung | Eintragen |
|---|---|
| `PLAYLIST` | Die URL deiner M3U oder ihr Pfad auf diesem Rechner |
| `GUIDE` | Die URL oder der Pfad deines XMLTV-Guides. Der Guide-Link eines Anbieters endet meist auf `xmltv.php`, `.xml` oder `.xml.gz` |
| `GROUPS` | Nur die Gruppen, die du willst, als ihre `group-title`-Werte: `["News", "Sports"]`. Lass `[]` für alle Kanäle stehen. Jeder Kanal wird mit `ffprobe` geprüft (ein paar Sekunden pro Kanal), daher dauert eine Liste mit Tausenden lange: wähle lieber Gruppen aus |
| `REX`, `LISTEN` | Die Adresse von rex und wo das Addon antwortet (`127.0.0.1`, wenn das Addon auf dem Rechner von rex läuft) |
| `NAME`, `LIBRARY` | Der Name des Addons in rex und der Titel der Bibliothek, in der auch die Kanäle liegen. Behalte `NAME` bei, sobald du es einmal gestartet hast |
| `FIRST` | Die Nummer, die der erste Kanal ohne `tvg-chno` bekommt. Wähle Nummern, die frei sind von anderen Live-TV-Addons, zum Beispiel `500` |

## Schritt 3. Starten {#step-3-run-it}

+++ Linux und macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**Das solltest du sehen.** Eine Zeile für jeden Kanal, der nicht geprüft werden konnte, danach die Gesamtzahl:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

Das Log von rex zeigt die Bibliothek, die für die Kanäle angelegt wurde, und die Kanäle, die ankommen:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Öffne in Plex Web oder Plex für Android **Live TV**: Ein Tab mit dem Namen deines rex listet die Kanäle mit ihren Nummern auf, dazu die Programmübersicht von vor drei Stunden bis eine Woche voraus. Wähle aus, was gerade läuft, und drück auf **Watch Now**: Es startet nach ein paar Sekunden, so lange braucht rex, um es umzuwandeln. What's On zeigt, was jetzt und später läuft. Eine Folge, die in der Programmübersicht in der Kategorie `News` oder `Sports` steht, landet in diesen Bereichen.

Das Addon prüft die Playlist und schickt die Programmübersicht alle 30 Minuten neu. Damit es dauerhaft läuft, richte es so ein wie das Addon für Heimvideos: [Step 4](addon-home-videos.md#step-4-keep-it-running), nur mit `iptv.py` statt `homevideos.py`.

## So funktioniert es {#how-it-works}

| Teil | Was es macht |
|---|---|
| `channels()` | Liest die Playlist: jede `#EXTINF`-Zeile und die URL danach. Der Schlüssel eines Kanals, der in rex dauerhaft seine `id` ist, ist seine `tvg-id` (oder sein Name) |
| `Handler` | Liefert `/tv/<key>.m3u8` als Weiterleitung zum Stream des Kanals. rex folgt ihr jedes Mal, wenn jemand einschaltet, und das Addon sucht den Stream in diesem Moment nach, sodass Links, die ablaufen, weiterhin funktionieren |
| `best_variant()` | Wählt die beste Qualität aus einem Stream, der mehrere anbietet (eine HLS-Master-Playlist), damit abgespielt wird, was geprüft wurde |
| `probe()` | `ffprobe` des Streams, einen Tag gespeichert. rex braucht es, um Bild und Ton des Kanals zu kennen, und behandelt den Kanal als Live, weil seine Probe keine Länge hat. Ein Stream, der nicht HLS ist oder nicht antwortet, wird in dieser Runde übersprungen |
| `guides()` | Liest die XMLTV-Datei einmal pro Durchlauf und behält pro Kanal die Sendungen von drei Stunden zurück bis eine Woche voraus: Titel, Beschreibung, Kategorien, Bild und `previously-shown` (eine Wiederholung). Eine Sendung mit einer `xmltv_ns`-Episodennummer wird zu einer Folge ihrer Serie, nummeriert ab 1 (XMLTV zählt ab 0) |
| `number_for()` | Gibt jedem Kanal einmal seine Nummer und speichert sie in `~/.rex-iptv.json`: die `tvg-chno` der Playlist, wenn kein anderer Kanal sie hat, sonst die nächste freie ab `FIRST`. Favoriten in den Plex-Apps werden nach Nummer gespeichert, daher muss ein Kanal seine Nummer behalten |
| `sync()` | Registriert mit `"trash": false`, sodass ein Kanal, der die Playlist verlässt, gelöscht und nicht in rex' Papierkorb verschoben wird. Jeder Kanal wird mit seinem `channel` gesendet: Nummer, Name und Programm. Ein Abbild aller Kanäle, 100 pro Anfrage (je eine Woche Programm) |

## Ändern {#change-it}

- **Streams, die nicht HLS sind.** Viele Anbieter bieten jeden Kanal auch als MPEG-TS (`.ts`) an. rex nimmt einen Live-Kanal nur als HLS-Stream (`.m3u8`) an, deshalb überspringt dieses Addon die anderen: Frag deinen Anbieter nach HLS-Links (oft `output=m3u8` in der Playlist-URL).
- **Deine eigenen Nummern.** Bearbeite die Nummern in `~/.rex-iptv.json`, während das Addon gestoppt ist. Die nächste Runde übernimmt sie.
- **Logos.** `tvg-logo` wird zum Bild des Kanals in seiner Bibliothek. Das Programmraster zeigt Nummern und Namen.
- **Ein Programm von woanders.** Alles, was den Sendeplan kennt, kann `guide` füllen: eine JSON-API eines Anbieters, ein Sportspielplan oder eine feste Schleife. rex-live-sports baut Programme aus dem Scoreboard von ESPN, siehe [Live TV mit rex](live-tv.md).

## Fehlerbehebung {#troubleshooting}

| Du siehst | Warum | Lösung |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | Der Kanal ist MPEG-TS oder ein anderes Format, oder sein Stream hat mit einem Fehler geantwortet (der Grund steht am Ende) | Nimm den HLS-Link des Kanals; ein Stream, der gerade nicht läuft, wird in der nächsten Runde erneut versucht |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`, `actively refused it` unter Windows oder `HTTP Error 403`) | Der Stream hat nicht geantwortet oder diesen Rechner abgewiesen | Prüf den Link in einem Player auf demselben Rechner. IPTV-Links funktionieren oft nur von der Adresse aus, mit der du dich angemeldet hast |
| `no channel could be probed: not sending a snapshot` | Kein Kanal hat geantwortet: der Anbieter ist offline oder die Playlist ist leer | Es wird nichts entfernt. Prüf `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` unter Windows) | rex läuft nicht, oder `REX` ist nicht seine Adresse | Starte rex oder korrigier `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | Mehr als die Hälfte der Kanäle ist auf einmal aus der Playlist verschwunden oder hat den Check nicht bestanden | Wenn du das so wolltest, führ es einmal mit `REX_FORCE=1` aus; ansonsten warte, bis der Anbieter wieder da ist |
| Ein Kanal hat nichts im Guide | Seine `tvg-id` passt zu keiner `<channel id>` im Guide, oder der Guide hat für diese Woche nichts | Passe die `tvg-id` der Playlist an die IDs im Guide an |
| Live-TV fehlt in einer Plex-App | Es wurde noch kein Kanal gesendet, oder die App ist nicht Plex Web oder Plex for Android, die beiden getesteten Apps | Starte das Addon und nutze Plex Web oder Plex for Android |
| Watch Now schlägt fehl | rex hat kein FFmpeg, oder der Stream ist abgebrochen | Das rex-Log sagt dir den Grund. Zu FFmpeg siehe [Converting video](any-source.md#converting-video-optional) |

Immer noch hängengeblieben? Frag im **rex-support**-Forum auf [Discord](https://discord.com/invite/7u4YjMThXP).
