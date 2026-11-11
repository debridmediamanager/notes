# Tutorial: addon video rumah {#tutorial-a-home-videos-addon}

Tutorial ini membuat addon rex dalam satu file Python. Addon ini memasukkan klip ponsel, file camcorder, atau rekaman layar kamu ke library **Home Videos** di setiap aplikasi Plex. Setiap video mendapatkan judul, tanggal, dan gambar poster.
Tidak ada yang disalin atau diunggah. rex membaca file dari addon kamu saat kamu menekan play.

Ini adalah versi paling singkat yang berfungsi dari [Building rex addons](addons.md) Langkah 1 sampai 5. Halaman ini memberitahu apa yang harus diketik.
Halaman itu menjelaskan alasannya. Tutorial [musik](addon-music.md) dan [IPTV](addon-iptv.md) memakai kerangka yang sama.

| Yang kamu butuhkan | Alasan |
|---|---|
| rex, diatur seperti di [rex with your own app](any-source.md) (langkah 1 sampai 3) | Di sanalah library muncul. Sudah di-claim, supaya aplikasi Plex bisa melihatnya |
| Python 3.8 atau yang lebih baru | Untuk addon. Hanya memakai pustaka standar Python |
| `ffprobe` dan `ffmpeg` | `ffprobe` mendeskripsikan setiap video untuk rex, `ffmpeg` memotong gambar poster. Keduanya ada di FFmpeg |
| Folder berisi video, di mesin yang menjalankan addon | `.mp4`, `.mkv`, `.mov`, `.m4v`, `.avi`, `.webm`, `.mts`, `.m2ts`, `.3gp`, di subfolder mana pun |

Halaman ini menulis alamat rex sebagai `192.168.1.20:32400` dan menjalankan addon di mesin yang sama dengan rex. Ganti dengan alamat milikmu.

## Langkah 1. Simpan addon {#step-1-save-the-addon}

**Fungsinya.** Memberi kamu seluruh addon: server web kecil untuk video kamu dan sebuah loop yang memberi tahu rex tentang video tersebut setiap lima menit.

Simpan ini sebagai `homevideos.py`:

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

## Langkah 2. Isi pengaturannya {#step-2-fill-in-the-settings}

**Apa yang dilakukannya.** Mengarahkan addon ke folder dan rex Anda.

Ubah empat baris di bawah docstring:

| Pengaturan | Isi |
|---|---|
| `FOLDER` | Folder video Anda, misalnya `"/srv/videos/home"`, atau `os.path.expanduser("~/Videos/Home")` untuk folder di dalam home Anda |
| `REX` | Alamat rex, seperti yang Anda buka di langkah 3 di [rex dengan aplikasi Anda sendiri](any-source.md) |
| `LISTEN` | Tempat addon menjawab. Biarkan `127.0.0.1` jika addon berjalan di mesin yang sama dengan rex. Di mesin lain, isi IP LAN mesin itu (rex membaca video dari sana, jadi harus bisa dijangkau dari rex) |
| `NAME`, `LIBRARY` | Nama addon di rex dan judul library. Biarkan `NAME` seperti itu setelah Anda menjalankannya: baris-baris rex menjadi milik nama itu |

## Langkah 3. Jalankan {#step-3-run-it}

+++ Linux dan macOS
```bash
python3 homevideos.py
```
+++ Windows
```powershell
python homevideos.py
```
+++

**Yang akan kamu lihat.** Saat pertama kali dijalankan, rex memeriksa setiap video dan mengambil satu gambar diam dari masing-masing, lalu mengirimkannya:

```
serving /home/you/Videos/Home at http://127.0.0.1:9981
sent 3 videos: 3 created, 0 updated, 0 unchanged
```

Log rex menampilkan sumber dan library baru, lalu videonya:

```
SOURCES homevideos registered at http://127.0.0.1:9981
SECTION create Home Videos (movie) for homevideos's home
FEED homevideos upsert: 3 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Buka aplikasi Plex: **Home Videos** ada di bawah More (pin supaya muncul di Home). Setiap video memakai nama file sebagai judulnya, folder tempat file berada sebagai ringkasannya, tanggal file sebagai tanggal rilisnya, dan gambar diam dari titik sepersepuluh durasi sebagai poster dan background-nya. Tekan putar: videonya langsung diputar, dan pindah posisi (seeking) terjadi seketika.

Hentikan addon dengan Ctrl+C. Jalankan lagi, dan rex akan mengirim video yang sama sebagai `unchanged` tanpa memeriksa apa pun. Hasil probe dan gambar diam disimpan di folder `.rex` di dalam folder video kamu.

## Langkah 4. Biarkan tetap berjalan {#step-4-keep-it-running}

Addon ini harus berjalan setiap kali ada yang menonton: rex membaca setiap video darinya.

+++ Linux
Buat `~/.config/systemd/user/homevideos.service`, dengan folder tempat kamu menyimpan addon:

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

Kalau kamu sudah menjalankan `sudo loginctl enable-linger "$USER"` untuk rex, addon tetap berjalan juga setelah kamu logout.
+++ macOS dan Windows
Mulai addon dengan cara yang sama seperti kamu memulai rex di langkah 1 di [rex dengan aplikasi sendiri](any-source.md#step-1-install-rex): sebagai LaunchAgent di macOS, atau sebagai tugas terjadwal di Windows, dengan `python3 homevideos.py` (`python homevideos.py` di Windows) sebagai perintahnya dan folder addon sebagai folder kerjanya.
+++

## Cara kerjanya {#how-it-works}

Setiap bagian dari berkas ini adalah satu langkah dari [Membangun addon rex](addons.md):

| Bagian | Langkah | Fungsinya |
|---|---|---|
| `Handler` | [1. Sajikan byte-nya](addons.md#step-1-serve-the-bytes) | Menjawab `GET /home/<file>` dengan berkasnya, dan permintaan `Range` dengan hanya byte tersebut (`206`), sehingga seeking tidak membaca dari awal. `GET /stills/<name>.jpg` menyajikan poster. Apa pun di luar folder adalah `404` |
| `sync()`, baris pertama | [2. Daftarkan](addons.md#step-2-register-with-rex) | `PUT /rex/sources/homevideos` dengan alamat addon dan satu direktori, `home`, sebagai library film. Dikirim setiap putaran: mendaftar ulang tidak mengubah apa pun |
| `describe()` | [3. Deskripsikan setiap video](addons.md#step-3-describe-each-video) | `id` video adalah path-nya di folder Anda, jadi jika Anda mengganti nama berkas, ia menjadi judul baru tanpa riwayat tontonannya. `kind: "movie"` membuat setiap video menjadi film tersendiri, sehingga tidak perlu ada penomoran. `media_info` adalah output `ffprobe` secara utuh |
| `describe()`, `display` | [4. Beri nama dan lengkapi](addons.md#step-4-name-and-dress-it) | Judul, ringkasan, tanggal, dan gambar. URL still berada di bawah alamat addon itu sendiri, yang merupakan satu-satunya tempat di jaringan Anda rex mengambil gambar |
| `sync()`, sisanya | [5. Kirim](addons.md#step-5-send-it) | Snapshot dari setiap video, 200 per permintaan, sehingga video yang Anda hapus dari folder keluar dari library pada putaran berikutnya |

Pengaman menjaga agar momen buruk tidak mengosongkan library Anda: folder kosong atau hilang tidak mengirim apa pun, video yang tidak bisa dibaca `ffprobe` dilewati dan dicatat, dan rex sendiri menolak snapshot yang akan menghapus lebih dari separuh video.

(Terjemahan sebelumnya ditolak: tautan tujuannya berbeda. Pertahankan struktur persis seperti semula.)

## Ubah {#change-it}

- **Serial TV, bukan film.** Kirim `"kind": "episode"` dengan nomor `season` dan `episode`, lalu `display.show`, dan daftarkan direktorinya sebagai `"shows"`. Beri nomor episode supaya video baru tidak menggeser yang lain: berdasarkan tanggal, bukan posisi di folder. Lihat [Langkah 3](addons.md#step-3-describe-each-video).
- **Judul sendiri.** Baca judulnya dari file sidecar atau dari tag video (`media_info["format"]["tags"]`), bukan dari nama file.
- **Subtitle, koleksi, chapter.** File `.srt` di samping video, satu koleksi per folder, dan penanda chapter: lihat [Lebih lanjut dari addon Anda](addon-more.md).
- **Biarkan aplikasi Plex menghapus.** Tambahkan `do_DELETE` yang menghapus file dan menjawab `204`. Tanpa itu, addon menjawab `501`, rex tetap menyimpan video (lognya menulis `DELETE refused by the source, row kept: home/... at homevideos: 501`), dan aplikasinya bilang file tidak bisa dihapus.

## Pemecahan masalah {#troubleshooting}

| Yang Anda lihat | Penyebab | Cara memperbaiki |
|---|---|---|
| `sync failed, trying again in 5 minutes: <urlopen error [Errno 111] Connection refused>` | rex tidak berjalan, atau `REX` bukan alamatnya | Jalankan rex, atau perbaiki `REX` |
| `sync failed, ...: rex answered 409: {... "error":"the snapshot would remove more than half of this source's items" ...}` | Lebih dari separuh video yang dimiliki rex dari addon ini hilang dari folder: disk belum ter-mount, `FOLDER` salah, atau pembersihan besar-besaran | Jika memang disengaja, jalankan sekali dengan `REX_FORCE=1 python3 homevideos.py`. Jika tidak, perbaiki folder; tidak ada yang dihapus |
| `no videos found in ...: not sending a snapshot` | Folder kosong, tidak ada, atau tidak berisi file video | Perbaiki `FOLDER` |
| `skipped <file>: ...` | `ffprobe` tidak bisa membacanya (file rusak atau belum selesai) | Akan dicoba lagi pada putaran berikutnya |
| `rejected: {'id': ..., 'reason': ...}` | rex menolak satu video, dan memberi tahu alasannya | Lihat [Membangun addon rex, Pemecahan Masalah](addons.md#troubleshooting) |
| Librarynya ada tapi posternya kosong | `ffmpeg` belum terpasang, atau rex tidak bisa mengakses `LISTEN` | Pasang FFmpeg; jika addon berjalan di mesin lain, atur `LISTEN` ke IP LAN mesin tersebut, bukan `127.0.0.1` |
| Pemutaran gagal, dan log rex menulis `PART ... upstream failed: <urlopen error Connection refused ...>` | Addon tidak berjalan, atau rex tidak bisa mengakses `LISTEN` | Jalankan addon. Jika addon ada di mesin lain, atur `LISTEN` ke IP LAN mesin tersebut |

Masih bingung? Tanyakan di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP).
