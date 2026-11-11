# Tutorial: addon musik {#tutorial-a-music-addon}

Tutorial ini memasukkan folder berisi album ke dalam library **Music** yang bisa diputar oleh Plexamp, Plex Web, dan Plex for Android.
Tutorial ini mendukung FLAC, MP3, AAC, dan file umum lainnya. File kamu tetap berada di tempatnya. MusicBrainz menyediakan detail album yang sudah dikenal. Album yang tidak dikenal memakai tag-nya dan `cover.jpg`. File `.lrc` di dekatnya akan menjadi lirik berwaktu.

Tutorial ini mengikuti [Membangun addon rex](addons.md) dan bagian [Music](addons.md#music) di dalamnya. Baca [tutorial home videos](addon-home-videos.md) dulu jika ini pertama kalinya kamu membuat addon.

| Yang kamu butuhkan | Alasannya |
|---|---|
| rex 2026.11.02 atau lebih baru, sudah disiapkan seperti di [rex dengan app kamu sendiri](any-source.md) (langkah 1 sampai 3) dan sudah diklaim | rex hanya meminta nama album dari Plex setelah sudah diklaim |
| Python 3.8 atau lebih baru | Addon-nya, hanya memakai standard library |
| `ffprobe` | Mendeskripsikan setiap file untuk rex dan membaca tag-nya. Tersedia bersama FFmpeg |
| Album kamu, satu folder per album | `Artist/Album/01 Song.flac`, atau kedalaman berapa pun: setiap folder yang berisi file audio dianggap sebagai album |
| Tag, atau MusicBrainz Picard | Addon membaca album dan artis dari tag setiap file (jika tidak ada, dari nama folder). File yang di-tag oleh [MusicBrainz Picard](https://picard.musicbrainz.org) sudah membawa release id-nya, yang merupakan pencocokan paling akurat |

Halaman ini menulis alamat rex sebagai `192.168.1.20:32400` dan menjalankan addon di mesin rex.

## Langkah 1. Simpan addon {#step-1-save-the-addon}

Simpan ini sebagai `music.py`:

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

## Langkah 2. Isi pengaturannya {#step-2-fill-in-the-settings}

| Setting | Isi |
|---|---|
| `FOLDER` | Folder musik kamu, misalnya `"/srv/music"` atau `os.path.expanduser("~/Music")` |
| `REX` | Alamat rex |
| `LISTEN` | Biarkan `127.0.0.1` untuk addon di mesin yang sama dengan rex; kalau tidak, isi IP LAN mesin tersebut |
| `NAME`, `LIBRARY` | Nama addon di rex dan judul library musik. Simpan `NAME` setelah kamu menjalankannya |

## Langkah 3. Jalankan {#step-3-run-it}

+++ Linux dan macOS
```bash
python3 music.py
```
+++ Windows
```powershell
python music.py
```
+++

**Yang seharusnya kamu lihat.** Untuk setiap album yang tidak punya release id di tag-nya, ada satu baris berisi jawaban dari MusicBrainz, lalu totalnya:

```
serving /home/you/Music at http://127.0.0.1:9982
Radiohead - In Rainbows: cd061329-348f-46f7-b6c1-7460a88e5edb
The Test Pilots - Garage Demos: not on MusicBrainz with 3 tracks
sent 13 tracks: 13 created, 0 updated, 0 unchanged
```

MusicBrainz hanya menerima satu permintaan per detik, jadi run pertama untuk koleksi besar butuh waktu cukup lama: sekitar satu detik per album. Setiap jawaban disimpan di `.rex/albums.json` di folder musikmu, dan run berikutnya tidak meminta apa pun. Album yang di-tag oleh Picard tidak pernah dicari.

Log rex menampilkan setiap track yang masuk ke album-nya:

```
FEED mymusic Radiohead/In Rainbows/01 - 15 Step.flac -> track 100005 on album 100004 of artist 100003
FEED mymusic upsert: 13 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Buka Plexamp dan pilih library **Music** milik rex sebagai library-nya (Plex Web dan Plex for Android menampilkannya di bawah More). In Rainbows akan menampilkan cover dari Plex, nama track-nya, serta foto dan biografi Radiohead, apa pun nama file-mu. Garage Demos menampilkan nama dari tag-nya dan `cover.jpg` dari folder-nya. Lagu yang punya file `.lrc` dengan nama yang sama akan menampilkan lirik-nya, baris demi baris saat diputar.

Agar tetap berjalan, atur seperti addon home videos: [Langkah 4](addon-home-videos.md#step-4-keep-it-running), dengan `music.py` sebagai pengganti `homevideos.py`.

## Cara kerjanya {#how-it-works}

| Bagian | Fungsinya |
|---|---|
| `Handler` | Melayani semua yang ada di bawah `/music/`: lagu-lagunya (dengan `Range`, jadi seeking langsung), file lirik `.lrc`-nya, dan sampul album |
| `sync()`, baris pertama | Mendaftarkan addon dengan satu direktori, `music`, sebagai music library: `"directories": [{"name": "music", "music": "Music"}]`. Tanpa music library, rex menolak setiap track |
| `album_items()` | Satu item per lagu: `"kind": "track"`, nomor `disc` dan `track`-nya (dari tag-nya, atau dari urutannya di folder), output `ffprobe`-nya, dan `ids.mbid`, yaitu release id MusicBrainz untuk album tersebut. Plex menampilkan track-nya sendiri pada nomor-nomor itu di release tersebut, jadi nomornya harus benar |
| `release_id()` | Mencari release id untuk album yang belum punya, lewat pencarian MusicBrainz berdasarkan album dan artis, dengan mengambil release resmi pertama yang jumlah tracknya sama dengan isi folder. Satu album punya banyak release (satu per negara, edisi deluxe), dan release mana pun yang berisi track kamu sudah cukup untuk menamai album |
| `display` | Nama-nama album dari tag, dan sampulnya, yang hanya ditampilkan ketika Plex tidak mengenali album tersebut |
| `lyrics` | File `.lrc` (ber-timestamp) atau `.txt` dengan nama yang sama dengan lagu, dikirim sebagai `[{"path": ..., "size": ...}]`. rex hanya membacanya lagi ketika ukurannya berubah |
| `sync()`, sisanya | Snapshot dari setiap lagu, 200 per request: album yang kamu hapus akan hilang dari library pada putaran berikutnya (setiap sepuluh menit) |

rex tidak membaca tag sendiri. Semua yang ditampilkan Plex berasal dari release id, atau dari `display` kamu jika Plex tidak punya datanya.

## Ubah {#change-it}

- **Layout lain.** Album yang dipecah ke folder disc (`CD1/`, `CD2/`) dianggap dua album oleh addon ini, masing-masing dengan terlalu sedikit track untuk dicocokkan. Kelompokkan folder seperti itu di `albums()` dan kirim satu `release` untuk semua file-nya; lihat [Musik](addons.md#music).
- **Artis dengan gambarnya sendiri.** Kirim `display.artist.poster` dan daftarkan dengan `"artwork": "source"`: lihat [Lainnya dari addon kamu](addon-more.md#artist-pictures).
- **Playlist.** Kirim posisi setiap lagu dalam playlist dan rex akan membuat playlist-nya: lihat [Lainnya dari addon kamu](addon-more.md#collections-and-playlists).
- **Loudness.** Jika kamu mengukur loudness tiap lagu, kirim sebagai `loudness` dengan nama dari Plex: lihat [Musik](addons.md#music). rex tidak mengukur apa pun sendiri.

## Pemecahan masalah {#troubleshooting}

| Yang kamu lihat | Kenapa | Cara memperbaiki |
|---|---|---|
| `<artist> - <album>: not on MusicBrainz with N tracks` | Tidak ada rilis resmi dengan judul dan artis itu yang jumlah lagunya sama dengan punyamu: ada lagu yang hilang, bonus track, typo di tag, atau album yang tidak ada di MusicBrainz | Perbaiki tag atau foldernya, lalu hapus baris album itu dari `.rex/albums.json` (atau seluruh file) supaya ditanyakan lagi. Atau tag album dengan Picard |
| Album menampilkan nama lagu yang salah | Rilis yang ditemukan punya jumlah lagu yang sama, tapi urutannya beda (edisi berbeda) | Tag album dengan Picard, yang akan menulis rilis yang tepat |
| `MusicBrainz did not answer for ...: asking again next round` | MusicBrainz sedang sibuk atau tidak bisa dihubungi | Tidak perlu apa-apa: putaran berikutnya akan bertanya lagi |
| Album menampilkan nama dari tag-nya padahal Plex mengenalnya | rex belum di-claim, atau release id tidak menunjuk ke apa pun yang dikenal Plex | Claim rex: [langkah 3 rex dengan aplikasimu sendiri](any-source.md#step-3-add-it-to-a-plex-account) |
| `rejected: ... no music library holds ...` | Library-nya sudah dihapus di aplikasi Plex | Tambahkan lagi di aplikasi Plex: Add Library, Music, lalu pilih folder `music` yang ditawarkan daftar foldernya |
| `sync failed, ...: rex answered 409: ...more than half...` | Lebih dari separuh lagu hilang dari folder | Kalau memang disengaja, jalankan sekali dengan `REX_FORCE=1`; kalau tidak, perbaiki `FOLDER` |
| Tidak ada lirik | Nama file `.lrc` berbeda dari nama lagunya, atau lagunya dikirim sebelum file itu ada | Beri nama seperti lagunya (`01 - Song.flac`, `01 - Song.lrc`); putaran berikutnya akan mengirimnya |

Masih buntu? Tanyakan di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP).
