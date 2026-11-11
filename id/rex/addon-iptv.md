# Tutorial: addon IPTV {#tutorial-an-iptv-addon}

Tutorial ini mengubah playlist IPTV (M3U) dan panduan TV (XMLTV) menjadi channel **Live TV** di Plex Web dan Plex untuk Android. Tiap channel tetap mempertahankan nomor dan guide-nya. Cara ini bekerja dengan channel M3U yang memakai HLS (`.m3u8`) dan guide XMLTV apa pun yang menyebut channel tersebut.

Tutorial ini mengikuti [Building rex addons](addons.md) dan bagian [Live TV](addons.md#live-tv)-nya. Baca [tutorial home videos](addon-home-videos.md) dulu kalau ini pertama kalinya kamu membuat addon. Untuk olahraga live, pakai [Live TV with rex](live-tv.md).

| Yang kamu butuhkan | Alasannya |
|---|---|
| rex 2026.11.02 atau yang lebih baru, sudah disiapkan seperti di [rex dengan aplikasi sendiri](any-source.md) (langkah 1 sampai 3) dan sudah diklaim | Live TV ada di aplikasi Plex-nya |
| FFmpeg di tempat rex berjalan | rex mengonversi channel saat ada yang menontonnya. Lihat [Mengonversi video](any-source.md#converting-video-optional) |
| Python 3.8 atau yang lebih baru dan `ffprobe` di tempat addon berjalan | Addon-nya hanya memakai standard library. `ffprobe` mengecek tiap channel sekali sehari |
| Playlist M3U | Berupa URL atau file, dengan baris `#EXTINF`. `tvg-id` menghubungkan channel ke guide-nya, `tvg-chno` memberi nomornya, `tvg-logo` memberi logonya, `group-title` memberi grupnya |
| Guide XMLTV (opsional) | Berupa URL atau file, boleh di-gzip atau tidak. Tanpa guide, channel tetap muncul tapi tidak ada info di guide-nya |

Halaman ini menulis alamat rex sebagai `192.168.1.20:32400` dan menjalankan addon di mesin rex.

## Langkah 1. Simpan addon {#step-1-save-the-addon}

Simpan ini sebagai `iptv.py`:

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

## Langkah 2. Isi pengaturannya {#step-2-fill-in-the-settings}

| Pengaturan | Isi dengan |
|---|---|
| `PLAYLIST` | URL M3U Anda, atau path-nya di mesin ini |
| `GUIDE` | URL atau path panduan XMLTV Anda. Tautan panduan dari penyedia biasanya berakhiran `xmltv.php`, `.xml` atau `.xml.gz` |
| `GROUPS` | Hanya grup yang Anda inginkan, sebagai nilai `group-title`-nya: `["News", "Sports"]`. Biarkan `[]` untuk setiap channel. Setiap channel dicek dengan `ffprobe` (beberapa detik per channel), jadi daftar berisi ribuan channel akan memakan waktu lama: pilih grup saja |
| `REX`, `LISTEN` | Alamat rex, dan tempat addon merespons (`127.0.0.1` jika addon berjalan di mesin yang sama dengan rex) |
| `NAME`, `LIBRARY` | Nama addon di rex dan judul library yang juga menyimpan channel. Biarkan `NAME` seperti itu setelah Anda menjalankannya |
| `FIRST` | Nomor yang didapat channel pertama tanpa `tvg-chno`. Pilih nomor yang tidak bentrok dengan addon Live TV lain, misalnya `500` |

## Langkah 3. Jalankan {#step-3-run-it}

+++ Linux dan macOS
```bash
python3 iptv.py
```
+++ Windows
```powershell
python iptv.py
```
+++

**Yang akan kamu lihat.** Satu baris untuk setiap channel yang tidak bisa dicek, lalu totalnya:

```
serving https://example.com/playlist.m3u at http://127.0.0.1:9983
skipped Gone Channel: <urlopen error [Errno 111] Connection refused>
sent 2 channels: 2 created, 0 updated, 0 unchanged
```

Log rex menunjukkan library yang dibuat untuk channel-channel dan channel yang masuk:

```
SOURCES iptv registered at http://127.0.0.1:9983
SECTION create Live Channels (movie) for iptv's tv
FEED iptv upsert: 2 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Di Plex Web atau Plex untuk Android, buka **Live TV**: akan ada tab dengan nama rex kamu yang berisi daftar channel sesuai nomornya, dengan guide dari tiga jam yang lalu sampai seminggu ke depan. Pilih acara yang sedang tayang lalu tekan **Watch Now**: acara akan mulai diputar setelah beberapa detik, yaitu waktu yang dibutuhkan rex untuk mulai mengonversinya. What's On menampilkan apa yang sedang tayang sekarang dan nanti; episode yang ada di kategori `News` atau `Sports` di guide akan muncul di rak-rak tersebut.

Addon ini mengecek playlist dan mengirim guide lagi setiap 30 menit. Agar tetap berjalan, atur seperti addon home videos: [Langkah 4](addon-home-videos.md#step-4-keep-it-running), dengan `iptv.py` menggantikan `homevideos.py`.

## Cara kerjanya {#how-it-works}

| Bagian | Fungsinya |
|---|---|
| `channels()` | Membaca playlist: setiap baris `#EXTINF` dan URL di bawahnya. Kunci sebuah channel, yaitu `id`-nya di rex secara permanen, adalah `tvg-id`-nya (atau namanya) |
| `Handler` | Melayani `/tv/<key>.m3u8` sebagai redirect ke stream channel. rex mengikutinya setiap kali seseorang menyetel channel, dan addon mencari stream-nya saat itu juga, jadi tautan yang kedaluwarsa tetap bisa dipakai |
| `best_variant()` | Mengambil kualitas terbaik dari stream yang menawarkan beberapa varian (HLS master playlist), jadi yang diputar adalah yang sudah diperiksa |
| `probe()` | `ffprobe` dari stream, disimpan selama sehari. rex membutuhkannya untuk mengetahui gambar dan suara channel, dan menganggap channel sebagai live karena hasil probe-nya tidak punya durasi. Stream yang bukan HLS, atau tidak merespons, dilewati pada putaran ini |
| `guides()` | Membaca file XMLTV sekali per putaran dan menyimpan program setiap channel dari tiga jam yang lalu sampai seminggu ke depan: judul, deskripsi, kategori, gambar, dan `previously-shown` (pengulangan). Program dengan nomor episode `xmltv_ns` menjadi episode dari acaranya, dinomori mulai dari 1 (XMLTV menghitung dari 0) |
| `number_for()` | Memberi setiap channel nomornya sekali dan menyimpannya di `~/.rex-iptv.json`: `tvg-chno` dari playlist jika tidak ada channel lain yang memakainya, jika tidak, nomor bebas berikutnya dari `FIRST`. Favorit di aplikasi Plex disimpan berdasarkan nomor, jadi channel harus mempertahankan nomornya |
| `sync()` | Mendaftar dengan `"trash": false`, sehingga channel yang keluar dari playlist akan dihapus, bukan disimpan di tempat sampah rex. Setiap channel dikirim bersama `channel`-nya: nomor, nama, dan guide. Ini snapshot dari setiap channel, 100 per permintaan (masing-masing dengan seminggu guide) |

## Ubah {#change-it}

- **Stream yang bukan HLS.** Banyak penyedia juga menawarkan setiap channel dalam format MPEG-TS (`.ts`). rex hanya menerima channel live sebagai stream HLS (`.m3u8`), jadi addon ini melewati yang lain. Minta link HLS ke penyedia Anda (biasanya `output=m3u8` ada di URL playlist).
- **Angka Anda sendiri.** Edit angka di `~/.rex-iptv.json` saat addon dihentikan. Putaran berikutnya akan memakai angka tersebut.
- **Logo.** `tvg-logo` menjadi gambar channel di library-nya. Grid panduan menampilkan nomor dan nama.
- **Panduan dari sumber lain.** Apa pun yang tahu jadwal bisa mengisi `guide`: API JSON dari penyedia, jadwal olahraga, atau loop tetap. rex-live-sports membuat panduan dari scoreboard ESPN, lihat [Live TV dengan rex](live-tv.md).

## Pemecahan masalah {#troubleshooting}

| Yang kamu lihat | Penyebab | Solusi |
|---|---|---|
| `skipped <channel>: not a live HLS stream (...)` | Channel-nya berformat MPEG-TS atau format lain, atau stream-nya membalas dengan error (alasannya ada di akhir) | Pakai link HLS milik channel itu; stream yang mati akan dicoba lagi di putaran berikutnya |
| `skipped <channel>: <urlopen error ...>` (`Connection refused`, `actively refused it` di Windows, atau `HTTP Error 403`) | Stream tidak merespons, atau menolak mesin ini | Cek link di pemutar pada mesin yang sama. Link IPTV sering hanya bisa dibuka dari alamat yang dipakai untuk login |
| `no channel could be probed: not sending a snapshot` | Tidak ada channel yang merespons: provider sedang mati, atau playlist-nya kosong | Tidak ada yang dihapus. Cek `PLAYLIST` |
| `sync failed, ...: <urlopen error [Errno 111] Connection refused>` (`WinError 10061` di Windows) | rex tidak berjalan, atau `REX` bukan alamatnya | Jalankan rex, atau perbaiki `REX` |
| `sync failed, ...: rex answered 409: ...more than half...` | Lebih dari separuh channel keluar dari playlist, atau gagal dicek, sekaligus | Kalau memang disengaja, jalankan sekali dengan `REX_FORCE=1`; kalau tidak, tunggu provider kembali normal |
| Sebuah channel tidak punya data di guide | `tvg-id`-nya tidak cocok dengan `<channel id>` mana pun di guide, atau guide tidak punya data untuk minggu ini | Samakan `tvg-id` di playlist dengan id di guide |
| Live TV tidak muncul di aplikasi Plex | Belum ada channel yang dikirim, atau aplikasinya bukan Plex Web atau Plex for Android, dua aplikasi yang sudah diuji | Jalankan addon-nya, dan pakai Plex Web atau Plex for Android |
| Watch Now gagal | rex tidak punya FFmpeg, atau stream-nya berhenti | Log rex menjelaskan penyebabnya. Untuk FFmpeg, lihat [Converting video](any-source.md#converting-video-optional) |

Masih buntu? Tanya di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP).
