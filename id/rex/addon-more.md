# Lebih banyak dari addon kamu {#more-from-your-addon}

[Membangun addon rex](addons.md) membahas dasarnya. Halaman ini menambahkan subtitle, trailer, chapter, collection,
playlist, gambar artis, film yang dikenal, library besar, perbaikan, dan penghapusan. Setiap bagian menambahkan field ke
[Langkah 5](addons.md#step-5-send-it). Coba di tutorial [home videos](addon-home-videos.md), [music](addon-music.md),
atau [IPTV](addon-iptv.md).

Setiap contoh dikirim ke rex nightly 2026.11.02. Referensi lengkapnya ada di [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Film dan acara yang dikenali Plex {#films-and-shows-plex-knows}

**Apa yang dilakukannya.** Membuat Plex menampilkan nama film atau episode, dengan poster, pemeran, ringkasan, dan rating, alih-alih `display` Anda.

Kirim `kind` dan id judulnya: id IMDb (`tt...`) atau TMDB dari film, atau dari **acara** untuk sebuah episode, dengan `season` dan `episode` sesuai penomoran TMDB:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**Apa yang akan Anda lihat.** Filmnya adalah **Big Buck Bunny (2008)** dengan artwork dari Plex, apa pun nama filenya. rex tidak membaca apa pun dari nama file: yang Anda kirim itulah yang ditampilkan. [rex dengan aplikasi Anda sendiri](any-source.md) membahas ini secara lengkap, termasuk episode.

## Subtitle {#subtitles}

**Fungsinya.** Menyediakan file subtitle yang diletakkan di samping video sebagai subtitle-nya. Orang bisa memilihnya, mengunduhnya, atau men-burn in-nya, sama seperti subtitle yang diunggah.

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| Field | Arti |
|---|---|
| `path` | Lokasi file di addon-mu, sama seperti video. Ekstensinya menentukan formatnya: `srt`, `ass`, `ssa`, `smi`, `txt` atau `psb` |
| `language` | `en` atau `eng`, sesuai yang kamu tahu. rex tidak membaca bahasa dari nama file |
| `forced`, `hearing_impaired` | `true` untuk menandainya |
| `size` | Ukurannya dalam byte. rex hanya membaca ulang file saat path-nya baru atau ukurannya berubah |

**Yang akan kamu lihat.** Video akan menampilkan subtitle **English (SRT External)**. Jika `subtitles` tidak kamu sertakan, yang kamu kirim sebelumnya tetap dipakai. Mengirim `[]` akan menghapus milikmu (subtitle yang diunggah atau yang diunduh tetap ada). File yang tidak bisa dibaca rex akan dilewati dan dicatat di log, tapi videonya tetap diambil.

## Trailer dan extras lainnya {#trailers-and-other-extras}

**Apa fungsinya.** Menaruh trailer, featurette, atau adegan yang dihapus di bawah film atau acara TV-nya, di bagian **Extras**, alih-alih menjadikannya judul tersendiri.

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

Sebuah extra termasuk ke judul dari video lain dalam `release`-nya (secara default folder-nya). `extra_type` bisa berupa `trailer`, `deleted`, `featurette`, `behindthescenes`, `interview`, `scene`, `short`, `opening`, `ending`, atau `other`. rex tidak pernah menentukan sebuah video sebagai extra berdasarkan nama atau folder-nya: hanya `kind: "extra"` yang membuatnya menjadi extra.

**Yang akan kamu lihat.** Halaman film menampilkan trailer di bawah Extras, dan library tidak mencantumkannya.

## Chapter {#chapters}

**Fungsinya.** Memungkinkan orang melompat antar bab di pemutar.

Jalankan `ffprobe` dengan `-show_chapters` juga, dan kirim outputnya apa adanya:

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**Yang seharusnya terlihat.** Bab-bab video, beserta nama dan waktunya. Untuk menambahkan bab ke video yang sudah ada di rex, kirim ulang probe-nya dengan `-show_chapters` di snapshot berikutnya.

## Koleksi dan playlist {#collections-and-playlists}

**Fungsinya.** Mengelompokkan judul di perpustakaan Anda ke dalam koleksi, dan lagu atau video ke dalam playlist, yang dibuat dan diperbarui terus oleh addon Anda.

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| Field | Arti |
|---|---|
| `collections` | Koleksi tempat judul ini berada, berdasarkan nama. Setiap koleksi dibuat saat pertama kali sebuah judul menyebutnya |
| `playlists` | Playlist tempat file ini berada, berdasarkan judul, beserta urutannya di tiap playlist mulai dari 1. Setiap playlist milik pemilik server, berupa audio jika lagu pertamanya berupa track, dan video jika tidak |

Pengguna tetap menyimpan perubahan mereka: judul yang dikeluarkan seseorang dari koleksi tetap di luar, lagu yang ditambahkan seseorang ke playlist Anda tetap pada posisinya, dan playlist yang diganti namanya tetap menjadi miliknya. Jika field dibiarkan kosong, yang sudah Anda kirim sebelumnya tetap dipertahankan; `[]` (atau `{}` untuk playlist) akan mengeluarkan file dari semua yang dimasukkan addon Anda.

**Yang akan Anda lihat.** Tab Collections di perpustakaan menampilkan **Summer 2026**; Playlists menampilkan **Road trip**, sesuai urutan Anda.

## Gambar artis {#artist-pictures}

**Apa yang dilakukannya.** Menampilkan gambar Anda untuk artis yang dikirim addon musik Anda, bahkan untuk artis yang sudah dikenal Plex dan akan diberi gambarnya sendiri oleh Plex.

Daftarkan dengan `"artwork": "source"`, dan kirim gambarnya di setiap track:

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

Tanpa `artwork: "source"`, artis yang sudah dikenal Plex tetap memakai gambar Plex, dan `display.artist` hanya tampil untuk artis yang tidak dikenal Plex. Dalam kedua kasus, gambar yang dipilih atau diunggah seseorang lewat aplikasi Plex tetap dipakai.

## Library besar: kirim probe sekali saja {#big-libraries-send-probes-once}

**Apa fungsinya.** Membuat snapshot ribuan video hampir tidak mengirim output `ffprobe` sama sekali, sehingga ukurannya kecil dan cepat.

Kirim `probe`, sebuah teks pendek milik Anda sendiri yang berubah setiap kali probe video berubah (hash dari output `ffprobe` juga bisa). Setelah rex memiliki video dengan `probe` tersebut, kirim `probe` saja, tanpa `media_info`:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

rex akan menjawab `"unchanged": 1`. Jika rex belum memiliki `probe` tersebut (video baru, atau video yang probe-nya berubah), rex tidak mengubah apa pun dan meminta datanya:

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

Kirim lagi item tersebut beserta `media_info`-nya. Snapshot menganggap item yang diinginkan sebagai sudah terkirim, jadi item itu tidak akan dihapus karenanya. Pastikan rex Anda mendukung fitur ini: jawaban untuk [registering](addons.md#step-2-register-with-rex) mencantumkan `"features": ["probe_digest"]`.

## Yang orang perbaiki: Fix Match {#what-people-fixed-fix-match}

**Fungsinya.** Memberi tahu addon kamu video mana yang dicocokkan secara manual oleh seseorang di aplikasi Plex (Fix Match), supaya addon bisa langsung mengirimkannya mulai dari situ.

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

Setiap entri adalah `release` (sebuah folder, kecuali kamu mengirim `release`) dan id dari film atau acara yang dicocokkannya. rex tetap menyimpan kecocokan itu apa pun yang kamu kirim berikutnya, jadi tidak ada yang rusak jika kamu mengabaikan ini. Tapi dengan membacanya, addon kamu bisa mengirim `kind` dan `ids` sendiri, dan tetap ingat perbaikannya jika baris-baris rex suatu saat dibangun ulang. Jika tidak ada yang dicocokkan, jawabannya `{"size": 0}`.

## Menghapus addon kamu {#removing-your-addon}

**Apa yang dilakukannya.** Menghapus addon kamu dan semua yang dikirimnya dari rex, tanpa menyentuh file-filenya.

Ada dua permintaan: yang pertama menunjukkan berapa banyak yang akan dihapus dan memberi tautan yang berlaku selama lima menit, yang kedua menghapusnya.

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

Riwayat tontonan ikut terhapus bersama barisnya. Mendaftar dan mengirim ulang nanti akan mulai dari nol, dengan baris baru. Untuk **mengganti** addon dengan versi baru, pertahankan namanya, id-nya, dan segmen pertama dari path-nya: versi baru itu lalu akan memperbarui baris yang sama. Library tidak pernah dihapus oleh rex; hapus sendiri lewat aplikasi Plex kalau kamu memang ingin menghapusnya.

## Siapa yang boleh mengirim ke rex {#who-may-send-to-rex}

rex 的 feed（`/rex/sources` 和 `/rex/feed`）不需要 token。它只回应来自 rex 所在机器本身、你的家庭网络（`192.168.x.x`、`10.x.x.x`、`172.16-31.x.x` 以及私有 IPv6 地址）和 Tailscale（`100.64-127.x.x`）的程序；对其他任何人来说，这个 feed 就像不存在一样，即使你为 rex-direct 转发了 rex 的端口，或是让它通过 IPv6 对外开放，也是一样。在 rex 所在机器上的反向代理会以本地程序的身份访问它，所以如果你在 rex 前面放了反向代理，就要在那里屏蔽 `/rex/`。
