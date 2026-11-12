# Membangun addon rex {#building-rex-addons}

[rex](https://rex.debridmediamanager.com/id/) menampilkan apa yang dikatakan sumbernya tentang dirinya. Sebuah sumber memberi tahu rex apa saja yang dimilikinya lewat feed API dan menyajikan file-file tersebut saat rex memintanya. rex memperlakukan semua sumber dengan cara yang sama. **Addon** adalah sumber yang kamu tulis sendiri untuk video rumahan, rekaman, katalog Stremio, [musik](#music), atau [saluran live](#live-tv).

Halaman ini menjelaskan apa yang dibutuhkan rex dari sebuah addon, cara memberi nama item-itemnya, dan aturan-aturan penting. Di akhir, ada [rex-stremio](https://github.com/debridmediamanager/rex-stremio) sebagai contoh satu file.

Sebuah addon melakukan tiga hal:

- **Menyajikan byte-nya.** rex mengambil setiap byte dari addon-mu lewat HTTP saat seseorang menekan play: sebuah file, atau stream tempat rex dialihkan.
- **Memberi tahu rex apa yang dimilikinya.** Addon mengirim daftar ke rex lewat feed API rex, dan setiap perubahan sesudahnya. rex tidak pernah memindai apa pun.
- **Memberi nama pada apa yang dibawanya.** Untuk hal-hal yang tidak dikenal agent mana pun, addon-mu mengirim judul, ringkasan, tanggal, dan artwork-nya sendiri. Aplikasi Plex menampilkannya seperti library lainnya.

Jika yang kamu bawa adalah film dan serial yang sudah dikenal Plex (Plex punya id IMDb atau TMDB-nya), kamu sebaiknya memakai [rex dengan aplikasimu sendiri](any-source.md). Dengan cara itu, Plex yang memberi nama dan deskripsi untuk semuanya.

Untuk membawa katalog addon Stremio-mu ke rex, kamu tidak perlu menulis apa pun: rex-stremio sudah siap pakai. Kamu tinggal menempelkan tautan addon-mu di halaman pengaturannya dan mencentang katalog yang kamu mau.

Kalau kamu tidak ingin menulis dan menjalankan server, kamu sebaiknya memakai addon JavaScript untuk [rex-addons](https://github.com/debridmediamanager/rex-addons): sebuah `manifest.json` dan sebuah `main.js`, dibagikan lewat repositori git, dan juga berjalan di [aplikasi Android zurg+rex](../zurg/guides/android.md). Addon ini berjalan di sandbox yang hanya bisa mengakses situs web yang tercantum di dalamnya dan tidak bisa membaca file-mu, jadi cocok untuk hal-hal yang ada di internet, bukan folder di disk-mu. [Menulis addon](https://github.com/debridmediamanager/rex-addons/blob/main/docs/writing-addons.md) menjelaskan caranya. Addon di halaman ini bisa ditulis dengan bahasa apa pun, menyajikan file-mu sendiri, dan melakukan apa pun yang kamu butuhkan.

**Mau mulai dari kode yang sudah jalan?** Tiga tutorial masing-masing membangun addon lengkap dalam satu file Python, hanya memakai standard library, dan menjelaskan fungsi tiap bagiannya:

| Tutorial | Membawa ke rex |
|---|---|
| [Video rumahan](addon-home-videos.md) | Sebuah folder berisi video-mu sendiri, sebagai library dengan judul, tanggal, dan poster yang diambil dari video |
| [Musik](addon-music.md) | Sebuah folder berisi album, dinamai oleh Plex lewat MusicBrainz, dengan lirik |
| [IPTV](addon-iptv.md) | Sebuah playlist M3U dan panduan XMLTV-nya, sebagai saluran Live TV dengan panduan |

Halaman ini menjelaskan setiap langkah yang diambil tutorial-tutorial tersebut. [Lebih banyak dari addon-mu](addon-more.md) menambahkan subtitle, trailer, chapter, koleksi, playlist, dan lainnya.

## Sebelum kamu mulai {#before-you-start}

| Yang kamu butuhkan | Alasannya |
|---|---|
| rex, diatur seperti di [rex dengan aplikasimu sendiri](any-source.md) (langkah 1 sampai 3) | Di situlah perpustakaan addon-mu muncul |
| rex nightly bertanggal 2026.10.25 atau lebih baru, atau 2026.11.02 atau lebih baru untuk [Musik](#music) dan [TV Langsung](#live-tv) | Halaman ini ditulis untuk versi itu |
| FFmpeg di tempat rex berjalan, jika addon-mu menyajikan stream | rex memutar stream dengan mengonversinya (cuma salin, jadi ringan). rex menemukan FFmpeg sendiri; lihat [Mengonversi video](any-source.md#converting-video-optional) |
| Addon-mu di mesin yang sama dengan rex, atau di jaringan rumahmu | Feed rex hanya menjawab mereka: lihat [Jaga port tetap privat](any-source.md#keep-the-port-private) |

Halaman ini menulis alamat rex sebagai `192.168.1.20:32400` dan alamat addon sebagai `127.0.0.1:9981`. Ganti dengan milikmu. Referensi API lengkap rex ada di [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Langkah 1. Sajikan byte-nya {#step-1-serve-the-bytes}

**Apa fungsinya.** Memberi setiap video sebuah URL yang bisa dibaca rex.

**Kenapa penting.** rex tidak menyimpan media apa pun. Setiap kali ada yang menekan play, rex membaca videonya dari addon kamu.

Addon kamu adalah server HTTP. Sebuah video ada di `<your address>/<path>`, dan `path` bisa kamu pilih sendiri. Ada dua jenis:

| Yang kamu sajikan | Caranya | Yang dilakukan rex |
|---|---|---|
| **Sebuah file** (`.mkv`, `.mp4`, ...) | Jawab `GET` dengan filenya. Jawab permintaan `Range` (`206`) supaya seek cepat; tanpa itu rex membaca dari awal setiap kali melakukan seek | Aplikasi Plex memutarnya langsung kalau bisa, atau rex mengonversinya |
| **Sebuah stream** (HLS, `.m3u8`) | Jawab `GET` dengan playlist-nya, atau redirect ke playlist itu. rex mengikuti redirect, dan login kamu tidak pernah dikirim ke host lain | rex selalu mengonversinya: salinan gambar dan suara ke dalam format yang bisa diputar aplikasi. Aplikasi yang membaca filenya langsung akan diarahkan ke konversi itu |

Opsional, tapi sayang kalau dilewatkan:

- **Login.** Basic auth (`user`, `password`) atau token bearer. rex hanya mengirimkannya ke alamat addon kamu sendiri.
- **Hapus.** Saat seseorang menghapus judul di aplikasi Plex, rex lebih dulu mengirim WebDAV `DELETE` untuk path tersebut ke addon kamu. Jawab dengan `2xx` (terhapus) atau `404` (sudah tidak ada) dan rex akan menghapus judulnya. Jawaban lain membuat aplikasi Plex menampilkan pesan bahwa judul itu tidak bisa dihapus.

## Langkah 2. Daftarkan ke rex {#step-2-register-with-rex}

**Fungsinya.** Memberi tahu rex nama addon Anda, lokasi file-filenya, dan library mana saja yang diisinya.

**Mengapa penting.** rex tidak membaca apa pun dari sumber yang tidak dikenalinya. Mendaftar ulang tidak mengubah apa pun, jadi lakukan setiap kali addon Anda mulai.

+++ Linux dan macOS
```bash
curl -X PUT http://192.168.1.20:32400/rex/sources/myaddon \
  -H 'Content-Type: application/json' \
  -d '{"url": "http://127.0.0.1:9981",
       "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++ Windows
```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/myaddon -ContentType application/json `
  -Body '{"url": "http://127.0.0.1:9981", "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++

| Field | Artinya |
|---|---|
| `url` | Lokasi file-file Anda. Byte video diambil dengan `GET <url>/<path>` |
| `user` dan `password`, atau `bearer` | Login addon Anda, jika punya. Jangan pernah menaruhnya di dalam `url` |
| `directories` | Library yang diisi addon Anda. Setiap entri berisi segmen path pertama (`name`) dan judul library: `shows` untuk library TV, `movies` untuk library film, `music` untuk library musik, atau beberapa sekaligus. rex membuat setiap library saat pertama kali dipakai; kalau Anda mengganti namanya di Plex, nama itu akan tetap dipakai |
| `trash` | `false` menghapus apa yang dihapus addon Anda (snapshot yang meninggalkannya, atau `DELETE`), alih-alih menyimpannya di trash rex |

Segmen pertama dari sebuah path menentukan library-nya: dengan contoh di atas, setiap path yang diawali `kids/` akan masuk ke **Kids**. Gunakan segmen pertama yang berbeda untuk setiap library.

**Yang akan Anda lihat.** rex membalas dengan sumbernya. Log rex menampilkan `SOURCES myaddon registered at http://127.0.0.1:9981` dan, untuk pertama kalinya, `SECTION create Kids (show) for myaddon's kids`. Library akan muncul di aplikasi Plex di bawah More dalam hitungan detik.

## Langkah 3. Deskripsikan setiap video {#step-3-describe-each-video}

**Fungsinya.** Membuat catatan yang disimpan rex untuk setiap video: di mana letaknya, apa itu, dan bagaimana tampilannya.

**Kenapa penting.** Catatan ini adalah semua yang diketahui rex. Probe yang hilang atau id yang berubah menyebabkan sebagian besar bug addon.

```json
{
  "id": "home-2026-07-22-beach",
  "path": "kids/summer-2026/beach.mp4",
  "kind": "episode", "season": 1, "episode": 3,
  "name": "Summer 2026",
  "media_info": { "...": "ffprobe's output, whole" },
  "display": {
    "title": "First day at the beach",
    "summary": "...",
    "date": "2026-07-22",
    "thumb": "http://127.0.0.1:9981/kids/summer-2026/beach.jpg",
    "show": {"title": "Summer 2026", "summary": "...", "poster": "https://...", "art": "https://..."},
    "season": {"poster": "https://..."}
  }
}
```

| Field | Wajib | Arti |
|---|---|---|
| `id` | ya | Kunci kamu untuk video ini, **selamanya**. rex menyimpan riwayat tontonan berdasarkan ini |
| `path` | ya | Lokasi byte-nya di bawah `url` kamu. Segmen pertamanya menentukan library mana yang dipilih |
| `media_info` | ya, dalam praktiknya | JSON `-show_format -show_streams` dari ffprobe untuk video (untuk stream, probe URL-nya). Tanpa ini file akan **ditahan**: disimpan tapi tidak ditampilkan, karena aplikasi Plex tidak akan memutar video yang tidak mereka kenal. Stream (`.m3u8`) tanpa ini ditolak dengan `not a video file`, jadi kirim stream hanya setelah kamu sudah melakukan probe |
| `kind` | untuk show | `episode` atau `movie`. Tanpa ini tidak ada yang menempatkan video: di library TV ia jadi episode dari show bernama sesuai `name`, dinomori menurut urutan file; di library film ia jadi film dengan judul sesuai nama filenya |
| `season`, `episode` | untuk episode | Tempat videonya. Beri nomor episode agar episode baru tidak menggeser yang lain |
| `name` | tidak | Nama show, dan yang mengelompokkan episodenya. Default: nama foldernya (nama file untuk path tanpa folder) |
| `release` | tidak | Mengelompokkan video yang masih satu rangkaian. Default: folder video |
| `display` | untuk yang tidak dikenali agent mana pun | Judul, ringkasan, tanggal, dan artwork: Langkah 4 |

`path` stream berakhir dengan `.m3u8`, dan `media_info`-nya berisi `"format_name": "hls"`. rex hanya menerimanya jika keduanya ada. File lain harus punya ekstensi video.

## Langkah 4. Beri nama dan rias {#step-4-name-and-dress-it}

**Fungsinya.** Memberi aplikasi Plex judul, ringkasan, tanggal, dan gambar untuk konten yang tidak dikenali agen Plex mana pun.

**Kenapa penting.** Tanpa `display`, episode hanya tampil sebagai "Episode 3" dengan kotak kosong, dan show tidak punya poster.

| Field | Tampil di mana |
|---|---|
| `title`, `summary` | Judul dan ringkasan video, persis seperti yang dikirim |
| `date` | Tanggal rilisnya (`YYYY-MM-DD`), dan tahunnya diambil dari situ. Atau hanya tahun (`YYYY`) untuk konten yang hanya diketahui tahunnya, seperti film lama: aplikasi Plex lalu menampilkan tahunnya saja tanpa hari rilis |
| `thumb` | Poster film, atau still episode |
| `art` | Latar belakang film |
| `show.title`, `show.summary`, `show.poster`, `show.art` | Show milik episode tersebut |
| `season.summary`, `season.poster` | Season milik episode tersebut (poster show dipakai kalau tidak ada) |

Setiap field bersifat opsional. Gambar harus berupa URL `http://` atau `https://`. rex mengambil gambarnya sendiri: dari internet publik, atau dari alamat addon Anda sendiri (`url` yang Anda daftarkan), dengan login addon Anda. Alamat lain di jaringan rumah Anda akan ditolak. Jadi addon bisa menyajikan gambarnya sendiri, misalnya satu frame dari setiap video rumahan. Gambar 2:3 paling cocok untuk poster, sedangkan 16:9 paling cocok untuk still dan latar belakang.

Cara rex menanganinya:

- **Hanya untuk yang belum punya nama.** Video yang dikirim dengan `kind` dan `ids` yang dikenali Plex akan tampil sesuai deskripsi Plex, dan `display` diabaikan.
- **Kiriman berikutnya memperbarui.** Kirim ulang video dengan `display` baru dan barisnya, show, serta season akan berubah di tempat; aplikasi akan menggambar ulang gambar yang baru. Show tetap memakai judul yang dibuat pertama kali.
- **Yang diedit pengguna menang.** Field yang sudah diedit dan dikunci seseorang di aplikasi Plex akan tetap memakai nilai mereka, dan poster yang mereka unggah tetap dipakai.
- **Dicek dulu.** Gambar yang bukan URL http(s), atau tanggal dengan format lain, akan menolak video tersebut dan memberi tahu field mana yang salah.

## Langkah 5. Kirimkan {#step-5-send-it}

**Apa fungsinya.** Mengirim video kamu ke rex: semua video sekarang, lalu perubahannya saat terjadi.

**Kenapa penting.** rex menunjukkan persis apa yang terakhir kamu kirim.

| Untuk | Kirim | rex menjawab |
|---|---|---|
| Menambah atau mengubah video | `POST /rex/feed/myaddon/items` dengan `{"items": [...]}` | Berapa video yang `created`, `updated`, `held`, `unchanged`, dan setiap video `rejected` beserta alasannya |
| Menghapus video | `DELETE /rex/feed/myaddon/items` dengan `{"ids": [...]}` | Berapa video yang `trashed`, `deleted`, `released` (yang tertahan dilupakan), dan `unknown` |
| Mengirim semuanya | `PUT /rex/feed/myaddon/snapshot` dengan `{"items": [...]}`. Dalam beberapa bagian: `"session"` (teks apa saja), `"part"` mulai dari 0, `"complete": true` di bagian terakhir | Hitungan yang sama, dan apa yang `removed`: setiap video milikmu yang tidak disebut dalam snapshot |

Kirim beberapa ratus video per permintaan. Snapshot yang tidak menyebut apa pun tidak akan menghapus apa pun, dan snapshot yang akan menghapus lebih dari separuh video kamu akan ditolak kecuali bagian terakhirnya memakai `"force": true`. Ini supaya addon yang kehilangan jejak tidak bisa mengosongkan perpustakaanmu secara tidak sengaja.

**Yang seharusnya kamu lihat.**

+++ Linux dan macOS
```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/items | head -c 400   # what rex shows, with each ratingKey
curl -s http://192.168.1.20:32400/rex/feed/myaddon/held                  # what waits for a probe
```
+++ Windows
```powershell
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/items   # what rex shows, with each ratingKey
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/held    # what waits for a probe
```
+++

Log rex menyebutkan setiap video yang ditolak dan alasannya: `FEED myaddon rejected <id>: <reason>`.

## Musik {#music}

**Fungsinya.** Memasukkan album ke pustaka musik, yang dimainkan oleh Plexamp, Plex Web, dan Plex for Android.

**Kenapa penting.** Plex memberi nama musik berdasarkan rilis MusicBrainz dari album. Kalau kamu kirim id-nya, Plex sendiri akan mengisi semua judul, sampul, foto artis, dan biografi.

Kirim setiap file audio sebagai track:

```json
{
  "id": "albums/in-rainbows/01",
  "path": "music/Radiohead/In Rainbows/01 - 15 Step.flac",
  "kind": "track",
  "ids": {"mbid": "3b408cb5-7d51-4188-b07c-fabcf308cda3"},
  "disc": 1, "track": 1,
  "media_info": { "...": "ffprobe's output, whole" }
}
```

| Field | Arti |
|---|---|
| `kind` | `track` |
| `path` | Sebuah file audio: `.flac`, `.mp3`, `.m4a`, `.aac`, `.ogg`, `.oga`, `.opus`, `.wav`, `.alac`, `.aif`, `.aiff`, `.wma`, `.ape`, `.wv`, `.dsf`, atau `.mka` |
| `ids.mbid` | Id **rilis** MusicBrainz dari album track tersebut: id yang ada di link `musicbrainz.org/release/<id>`, bukan milik release group atau recording. Atau `ids.plex`, guid album Plex sendiri (`plex://album/<id>`) |
| `disc`, `track` | Posisi track di rilis itu. Track Plex pada nomor tersebut yang akan ditampilkan |
| `release` | Salinan album mana yang menjadi milik track ini. Default: foldernya. Setiap salinan menjadi album tersendiri, karena Plex mencantumkan dua salinan, jadi kirim satu `release` untuk file-file dari satu salinan yang berada di folder disc (`CD1/`, `CD2/`) |
| `display` | Untuk musik yang tidak dikenal Plex: `title` track, `artist` (`title`, `summary`, `poster`, `art`), dan `album` (`title`, `summary`, `poster`, `date`) |
| `lyrics` | File lirik di sebelah file audio di addon kamu: `[{"path": "music/.../01 - 15 Step.lrc", "size": 147}]`. Berupa `.lrc` (lirik dengan waktu) atau `.txt`, yang ditampilkan sebagai lirik lagu |
| `loudness` | Hanya jika addon kamu mengukur loudness, memakai nama Plex: `gain`, `albumGain`, `peak`, `albumPeak`, `albumRange`, `loudness`, dan `lra`, fade `startRamp` dan `endRamp`, serta `levels`, yaitu loudness setiap 100 ms. rex sendiri tidak mengukur apa pun |

- **Siapkan pustaka musik dulu.** Deklarasikan satu di Langkah 2 (`"directories": [{"name": "music", "music": "Music"}]`), atau tambahkan pustaka Music di aplikasi Plex. Track yang tidak diterima pustaka musik mana pun akan ditolak: `no music library holds <file>`.
- **Mencari id rilis.** Cari MusicBrainz berdasarkan judul album dan artisnya (`https://musicbrainz.org/ws/2/release?query=release:%22In%20Rainbows%22%20AND%20artist:Radiohead&fmt=json`), lalu pilih rilis resmi dengan jumlah track yang sama. Sering ada beberapa hasil yang cocok (satu per negara), dan salah satunya sudah cukup untuk menamai album. MusicBrainz hanya menerima satu permintaan per detik per alamat dan menolak lebih dari itu, serta meminta User-Agent yang menyebut nama addon kamu. Tanyakan sekali per album dan simpan jawabannya.
- **rex tidak membaca tag.** Judul, sampul, genre, dan artis serupa diurus oleh Plex. Track yang rilisnya tidak dikenal Plex akan menampilkan `display` kamu, dikelompokkan di bawah artis dan album yang kamu sebutkan, atau nama filenya di bawah `[Unknown Artist]` jika tanpa `display`.
- **Diputar apa adanya.** FFmpeg tidak diperlukan, kecuali ada aplikasi yang meminta kualitas lebih rendah dari aslinya. Dalam kasus itu rex mengonversinya dengan FFmpeg, seperti yang dilakukan Plex.
- **Yang tidak tersedia.** Radio, mix, stasiun, dan track yang mirip secara sonik di Plexamp membutuhkan analisis yang tidak dilakukan rex.

**Hasil yang akan kamu lihat.** Album di pustaka musik dengan sampul dan nama track dari Plex, serta artisnya dengan foto. Di Plexamp, pilih pustaka musik milik rex sebagai pustaka yang digunakan.

## TV Langsung {#live-tv}

**Apa fungsinya.** Membuat live stream menjadi channel di **Live TV** pada Plex Web dan Plex for Android, lengkap dengan panduan TV, What's On, dan nomor channel.

**Kenapa penting.** Live stream saja hanya jadi satu baris di library. Dengan `channel`, orang menemukannya seperti mereka mencari TV: di panduan, berdasarkan apa yang sedang tayang.

Kirim live stream seperti di Langkah 3 (`.m3u8` dengan probe-nya), ditambah `channel`:

```json
"channel": {
  "number": "100.1",
  "title": "Rex News",
  "guide": [
    {"start": "2026-11-01T18:00:00Z", "end": "2026-11-01T19:00:00Z",
     "title": "Evening News", "summary": "The day's headlines.", "categories": ["News"]},
    {"start": "2026-11-01T19:00:00Z", "end": "2026-11-01T19:45:00Z",
     "title": "The Pilot", "type": "episode", "show": "Rex Stories", "season": 1, "episode": 1,
     "categories": ["Drama"]}
  ]
}
```

| Field | Arti |
|---|---|
| `number` | Nomor channel di panduan (`100.1`, `704`): huruf, angka, `.`, `-` dan `_`. Pilih nomor yang tidak dipakai addon lain; channel pertama yang dikirim dengan nomor itu akan tetap memakainya |
| `title` | Namanya di panduan. Default: judul `display` dari stream |
| `call_sign` | Nama pendeknya. Default: `title` |
| `guide` | Apa yang sedang tayang: `start` dan `end` (detik epoch, atau ISO 8601 dengan `Z` atau offset), `title`, dan opsional `summary`, `categories`, `thumb` dan `previously_shown` (`true` untuk tayangan ulang). Episode menambahkan `"type": "episode"` dengan `show`, `season` dan `episode`, dan panduan mengelompokkannya di bawah show-nya |

- **Kirim panduan dari beberapa jam ke belakang sampai sejauh yang kamu tahu** (sekitar seminggu, seperti file panduan TV), dan kirim ulang setiap kali berubah. rex menampilkan sebuah program sampai tiga jam setelah program itu berakhir. Setiap pengiriman mengganti panduan channel; pengiriman tanpa `channel` mempertahankannya; `"channel": null` mengakhiri channel.
- **FFmpeg dibutuhkan**, seperti untuk semua stream: rex mengonversi channel saat ada yang menonton.
- **Tidak ada yang direkam.** Plex Web dan Plex for Android tidak punya tombol Record.
- **Channel yang berakhir.** Daftarkan dengan `"trash": false` (Langkah 2) agar channel yang kamu hapus benar-benar dihapus, bukan disimpan di trash rex.
- **Fungsi kategori.** Episode di `Sports` atau `News` tampil di shelf Sports dan News pada What's On. Program tanpa `type` ditampilkan sebagai film, seperti yang dilakukan Plex untuk TV guide apa pun.

**Yang akan kamu lihat.** Di Plex Web atau Plex for Android, **Live TV** ada di menu aplikasi, channel ada di panduan pada nomornya, dan stream diputar saat kamu membukanya. Log rex menyebutkan channel yang ditolak beserta alasannya, misalnya `channel.guide[3]: end must be after start`.

[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) melakukan semua ini untuk channel server live-sports: ia memberi nomor berdasarkan grup mulai dari `100.1`, mempertahankan nomor setiap channel, dan mengambil panduannya dari Pluto TV dan file XMLTV gratis milik epgshare01.

## Aturan yang sering bikin bingung {#the-rules-that-trip-people-up}

| Aturan | Apa yang terjadi kalau dilanggar |
|---|---|
| **Id itu permanen.** Kalau diubah, videonya dianggap judul baru | Riwayat tontonan dan hasil edit tetap di baris lama, yang akan dihapus oleh snapshot berikutnya |
| **Satu video, satu path.** Dua id tidak boleh memakai `path` yang sama | Id kedua akan ditolak dengan pesan `... is already <id>'s file` |
| **Byte file tetap per id.** rex menyimpan stream yang pertama kali di-probe. Probe berikutnya hanya mengubah chapter-nya. Hanya stream (`.m3u8`) yang menerima probe baru jika stream-nya berbeda | Kalau byte file berubah (format lain, unggahan ulang yang sudah diperbaiki), beri id dan path baru |
| **Probe semua.** Tanpa `media_info`, tidak ada video | File menunggu di `held` sampai kiriman berikutnya membawa `media_info`. Stream akan ditolak |
| **Simpan nama source.** Baris milik (source, id) | Nama lain akan memulai source kosong. Baris lama tetap ada sampai kamu menghapusnya |
| **Snapshot harus lengkap.** Snapshot yang melewatkan satu channel akan menghapusnya | Jangan kirim snapshot setelah kegagalan parsial. Lewati putaran itu |

Untuk **mengganti** addon (atau script) yang sudah mengisi library, pertahankan nama source, id, dan segmen path pertamanya. Kiriman pertamamu kemudian akan memperbarui baris-barisnya di tempat, termasuk riwayat tontonan, alih-alih membuat baris baru.

## Contoh: rex-stremio {#example-rex-stremio}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) mengubah katalog add-on Stremio Anda menjadi library rex: film menjadi library film, serial menjadi library TV, dan saluran live menjadi library bernama Live TV (bukan panduan Live TV). Ia menjalankan Langkah 1 sampai 5 dan berupa satu file Python, hanya memakai standard library. Ia tidak menerima penghapusan: judul-judul dari katalog bukan miliknya untuk dihapus.

**Mendaftar.** Setiap katalog yang Anda centang menyebut sebuah library: Stremio Films, Stremio Shows, atau Live TV kecuali Anda mengganti namanya. rex-stremio mendaftar sebagai `stremio` dengan satu directory untuk tiap library, dinamai sesuai library itu (`stremio-films`), dan menyatakan library itu sebagai judul `shows` milik directory tersebut untuk katalog serial, atau judul `movies` untuk katalog film dan live TV.

**Menyajikan.** Link add-on streaming itu kedaluwarsa, jadi rex-stremio tidak menyimpan link apa pun. Ia menyajikan satu URL per judul, `/<directory>/<catalog>/<id>.<ext>`, dan menjawabnya dengan redirect ke link yang diminta pada saat itu:

```python
url = app.sync.resolve(vid)   # ask every stream addon, rank, take the first link that opens
self.send_response(302)
self.send_header("Location", url)
```

Ia meminta tiap add-on yang menyajikan judul itu (`/stream/<movie or series>/<id>.json`), hanya menyimpan link `http(s)` biasa (`infoHash` torrent bukan file yang bisa dibaca rex), membuang yang melebihi batas resolusi atau ukuran Anda, lalu mencoba sisanya dengan resolusi tertinggi lebih dulu. Link yang berhasil dibuka di-cache sampai satu jam sebelum kedaluwarsa (atau selama satu jam kalau link tidak menyebutkan masa berlakunya). rex mengikuti redirect dan membaca file, termasuk seeking, langsung dari link. Link yang butuh header sendiri akan di-relay oleh rex-stremio sendiri, dan playlist master HLS hanya dijawab dengan varian terbaiknya saja.

**Probing.** Sekali per judul, rex-stremio menjalankan ffprobe pada URL-nya sendiri, supaya `media_info` menggambarkan persis apa yang akan dibaca rex, lalu menyimpan hasilnya di cache. Ia memeriksa `probe_workers` judul sekaligus (4 jika tidak diatur), dan tetap hanya meminta tiap host add-on paling banyak sekali per `stream_interval_seconds`. Stream yang menghasilkan probe itu diingat dan dicoba lebih dulu pada setiap pemutaran, jadi yang diputar sama dengan yang sudah dilaporkan ke rex. Container dari probe menentukan ekstensi path: `.mkv`, `.mp4`, `.ts`, `.avi`, atau `.m3u8` untuk HLS.

**Probe tersimpan.** Dengan kunci API DMM (`dmm_api_key`, atau **DMM** di halaman pengaturan), stream torrent melewati ffprobe jika DMM sudah punya probe untuk filenya. Hash torrent diambil dari `infoHash` stream atau dari link-nya (link debrid Torrentio membawanya di path). rex-stremio membaca ukuran file dari jawaban link terhadap satu request `Range` satu byte, lalu meminta `POST /api/sponsor/mediainfo` DMM untuk hingga 100 hash sekaligus. Ia hanya memakai probe DMM jika tepat satu file dari rilis itu memiliki ukuran tersebut, dan nama itu jika stream menyebutkan nama filenya. Selain itu di-probe seperti di atas, dan hasil probe tersebut dikirim kembali ke DMM (`POST /api/sponsor/probes`: hash torrent, ukuran file, namanya jika stream menyebutkannya, dan output ffprobe tanpa alamat yang dibacanya), supaya sponsor berikutnya yang menemui file itu bisa melewatinya. DMM menyimpan probe pertama dari sebuah file dan menjawab snapshot milik zurg sendiri lebih dulu. `share_probes: false` membuat probe hanya tetap di rex-stremio; probe DMM tetap dipakai. Probe sebuah playlist tidak pernah dikirim.

**Penamaan.** Setiap film dan episode dikirim ke rex dengan `kind` dan id IMDb-nya di `ids`, supaya Plex menamainya seperti di [rex dengan aplikasi Anda sendiri](any-source.md). `display` berisi judul, ringkasan, tanggal, dan poster dari katalog, yang hanya tampil sampai Plex menamainya. Saluran live, atau judul yang hanya dikenal oleh add-on-nya, tidak punya id IMDb, jadi `display` saja yang menamainya.

**Penomoran.** Film adalah film. Season dan episode serial diambil dari Cinemeta, yang id-nya adalah id IMDb, dan mempertahankan nomornya, jadi episode baru tidak pernah menggeser yang lain. rex menempatkannya sesuai nomor TMDB, jadi jika nomor Cinemeta berbeda, episode akan masuk ke tempat yang salah.

**Id.** Id adalah katalog ditambah id IMDb (dan season serta episode), seperti `st-<catalog>-tt0111161`. Id ini tidak pernah berubah, jadi satu film di dua katalog menjadi dua item. Dengan **Catalogs as collections** aktif, film atau serial yang masuk ke beberapa katalog dari satu library menjadi satu judul di sana, di collection setiap katalog.

**Pengiriman.** Setiap enam jam dan setelah setiap penyimpanan: daftar, lalu tiap judul begitu selesai dicek (`POST .../items`, hingga 20 judul atau apa pun yang siap setiap 5 detik), lalu satu snapshot dari setiap katalog, dalam bagian berisi 200. Snapshot pertama setelah penyimpanan membawa `"force": true`, karena menghapus centang katalog bisa menghapus lebih dari separuh isi. Jika sebuah katalog menjawab kosong atau hanya sebagian, putaran itu tidak mengirim snapshot: ia tetap menambah dan memperbarui, tidak menghapus apa pun, dan putaran lengkap berikutnya yang akan menghapus apa yang memang sudah hilang.

## Pemecahan masalah {#troubleshooting}

| Yang kamu lihat | Penyebab | Solusi |
|---|---|---|
| `rejected`: `not a video file` | Nama file tidak punya ekstensi video, atau sebuah `.m3u8` yang probe-nya bukan `hls` | Beri nama stream dengan `.m3u8` dan kirim probe-nya. Lagu butuh `"kind": "track"` |
| `rejected`: `no music library holds <file>` | Tidak ada music library yang menerima track ini | Deklarasikan satu dengan `music` di Langkah 2 |
| Album menampilkan nama file kamu di bawah `[Unknown Artist]` | Tidak ada `ids.mbid`, atau id rilis yang tidak dikenal Plex, dan tidak ada `display` | Kirim id rilis MusicBrainz album, atau `display` |
| Sebuah album menampilkan track yang salah | `ids.mbid` menunjuk ke edisi lain dari album itu, misalnya edisi deluxe dengan lebih banyak track | Pilih rilis dengan jumlah track yang sesuai |
| Sebuah channel tidak ada di panduan Live TV | Tidak ada `channel`; channel ditolak dan log rex menjelaskan alasannya (`channel.guide[...]`); atau channel lain sudah memakai nomornya, yang tidak dicatat di log | Perbaiki field yang disebut log, atau pilih nomor yang masih kosong |
| Live TV tidak ada di aplikasi Plex | Belum ada item yang dikirim dengan `channel`, atau aplikasinya belum diuji | Kirim `channel`, dan gunakan Plex Web atau Plex untuk Android, aplikasi yang sudah diuji |
| Video tidak pernah muncul | Video itu ditahan (`media_info`-nya tidak punya stream, atau file dikirim tanpa itu), atau stream yang dikirim tanpa `media_info` ditolak | Probe video itu, lalu kirim ulang |
| `rejected`: `... is already <id>'s file` | Id lain sudah memakai `path` itu | Simpan satu id per path |
| Snapshot menjawab `409`: `the snapshot would remove more than half of this source's items` | Snapshot-mu menghilangkan lebih dari separuh item yang dimiliki rex darimu: disk yang hilang, listing yang gagal, atau memang pembersihan | Perbaiki bagian yang hilang. Jika memang disengaja, kirim bagian terakhir snapshot dengan `"force": true` |
| Episode berjudul "Episode 1" dan kotak kosong | Tidak ada `display` | Kirim `display` bersama setiap video |
| Film yang dikirim dengan id IMDb-nya tetap memakai judul `display`-mu, bukan judul Plex | rex meminta judul dari Plex hanya setelah rex diklaim | Klaim rex: [langkah 3 rex dengan aplikasimu sendiri](any-source.md#step-3-add-it-to-a-plex-account) |
| Gambar tidak muncul | URL ada di jaringan rumahmu tetapi tidak berada di bawah `url` addon yang terdaftar, atau bukan http(s) | Sajikan dari alamat addon-mu sendiri, atau host di internet publik. |
| Pemutaran gagal dengan 502 di log rex | Addon-mu tidak menjawab, atau situs stream menolaknya | Periksa log addon-mu sendiri dulu |
| Judul yang dihapus di aplikasi Plex tetap ada | Addon-mu menjawab `DELETE` dengan selain `2xx` atau `404` | Hapus di sisimu, lalu jawab dengan `2xx` |
| Judul yang sudah dihapus muncul lagi | Addon-mu masih mengirim video itu | Berhenti mengirim yang sudah dihapus |

Masih bingung? Tanyakan di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Mendapatkan bantuan](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.
