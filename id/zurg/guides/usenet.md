# Usenet dengan zurg {#usenet-with-zurg}

`backend` `nzb` zurg mengubah file `.nzb` menjadi library yang di-mount. Tidak ada downloader atau folder completed.
Tidak ada yang diunduh sebelum diputar. zurg menyimpan NZB dan cache terbatas di `data/bytecache` dan `data/par2`
beserta record indeks. `nzb_article_disk_cache_mb` default-nya 512 MiB. Saat seek, zurg hanya mengambil artikel yang mencakup byte tersebut. File remux 60 GB tidak butuh disk 60 GB.

Usenet memakai filter library, mount, dan integrasi media-server yang sama dengan backend debrid. Rilis Usenet bisa berdampingan dengan konten Real-Debrid atau TorBox. Kamu juga bisa memakai Usenet saja.

**Beberapa provider Usenet didukung.** Satu entri `nzb` bisa memuat berapa pun akun berita: provider tanpa batas, akun block, apa pun yang kamu punya. zurg akan berpindah ke akun berikutnya artikel demi artikel. Ini lebih penting di sini dibanding redundansi biasanya, karena retensi berlaku per provider. Jadi akun kedua sering kali menjadi pembeda antara cukup satu pengambilan tambahan dan harus membangun ulang seluruh rilis dari PAR2. Lihat [Lebih dari satu provider Usenet](#more-than-one-usenet-provider).

Panduan ini mencakup akun berita, NZB, mount, dan Plex.

| | |
|---|---|
| Referensi konfigurasi | [config.md → Usenet accounts](../reference/config.md#usenet-accounts) |
| Dashboard | `http://localhost:9999/config/` → Essentials → Providers |
| Lokasi kode | `internal/nzb` (backend), `internal/nntp` (klien news), `internal/par2` (matematika perbaikan) |
| Folder pantau | `nzbs/`, di working directory zurg (`/config` di Docker) |
| Cache perbaikan | `data/par2/` |
| Nama file yang sudah di-resolve | `data/nzb-names/`, supaya release yang terobfuscate hanya dibaca namanya sekali, bukan sekali per restart |
| Indeks artikel | `data/nzb-index/`, di bawah `nzb_segments: mmap`, yaitu default di Linux, macOS, dan BSD |

---

## Yang kamu butuhkan {#what-you-need}

- **Setidaknya satu akun penyedia Usenet.** Retensi adalah yang paling penting. Penyedia dengan retensi 4000+ hari masih menyimpan postingan yang sudah hilang dari penyedia 1000 hari. **Batas koneksi** paketmu adalah angka kedua yang perlu kamu tahu. Angka inilah yang dibaca zurg.
- **Akun tambahan, jika kamu punya.** Penyedia unlimited kedua di *backbone* yang berbeda, atau akun blok murah untuk menutup celah, adalah hal dengan nilai tertinggi yang bisa kamu tambahkan ke pengaturan Usenet. Lihat [More than one Usenet provider](#more-than-one-usenet-provider).
- **File NZB atau sesuatu yang mengambilnya.** Unduh dari indexer kamu lalu taruh di `nzbs/`. Atau aktifkan [SABnzbd-compatible endpoint](sonarr-radarr.md) dan biarkan Sonarr dan Radarr yang menyerahkannya. Endpoint ini menulis ke direktori yang sama. zurg juga bisa mencari sendiri di indexer Newznab kamu. Ini terjadi saat kamu menekan play di [Stremio](stremio.md). Ini juga terjadi untuk permintaan dari daftar tonton kamu dan dari Seerr serta \*arrs melalui [acquisition](acquisition.md). Torrent untuk akun debrid punya endpoint sendiri yang kompatibel dengan [qBittorrent](sonarr-radarr-torrents.md).
- **zurg**, ditambah `rclone` jika kamu ingin mount filesystem alih-alih WebDAV langsung. zurg akan mengunduh rclone untukmu saat pertama kali dijalankan.

---

## 1. Konfigurasikan akun news Anda {#1-configure-your-news-accounts}

Setiap akun di zurg adalah satu entri di bawah `providers:`. Akun Usenet diautentikasi dengan kredensial server, bukan token API, jadi isinya memakai blok `nntp`, bukan `token`:

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

Hanya itu saja. Tambahkan akun debrid di sebelahnya jika kamu punya:

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| Kunci | Default | Catatan |
|---|---|---|
| `host` | *(wajib)* | Server berita. Host yang kosong atau tidak ada akan menyebabkan error saat startup. |
| `port` | `563` dengan TLS, `119` tanpa TLS | |
| `tls` | `false` | Aktifkan. NNTP tanpa enkripsi mengirim password kamu dalam teks biasa, dan bacaanmu bisa dilihat siapa pun di jalurnya. |
| `username` / `password` | `""` | |
| `connections` | `8` | **Atur ini sesuai kuota paket kamu.** Ini bukan batas laju yang bisa dinegosiasikan: satu koneksi hanya membawa sebagian kecil throughput penyedia, dan zurg membaca sesuai angka ini. Terlalu rendah membuat streaming lambat; melebihi batas paket, dan server mulai menolak koneksi. |
| `warm_connections` | `4` | Koneksi terautentikasi yang menganggur tetap terbuka supaya pembacaan tidak perlu menunggu dial. Satu dial memakan sekitar 0.8s untuk TCP, TLS, greeting, dan `AUTHINFO`. Tanpa batas bawah, biaya ini dibayar saat permintaan setelah setiap start dan setiap jeda sepi. Koneksi ini diambil dari `connections`, bukan tambahan. Paket menghitungnya sebagai koneksi terbuka, dan zurg menjaganya tetap hidup dengan `DATE` berkala, jadi batas bawahnya dibatasi oleh kuota. `-1` tidak menyimpan koneksi sama sekali, yang diinginkan paket yang ditagih berdasarkan waktu koneksi. `warm_connections` di level atas menetapkan default untuk akun yang tidak menyatakan nilainya sendiri. Lihat [koneksi hangat](../reference/config.md#warm-connections). |
| `cache_size_mb` | `512` | Data artikel yang sudah didekode dan disimpan di memori, dipakai bersama oleh semua file yang sedang dibaca, bukan per file. |
| `servers` | `[]` | Akun berita tambahan. Lihat [Lebih dari satu penyedia Usenet](#more-than-one-usenet-provider). |

Dua aturan yang dicek oleh validator konfigurasi:

- **Hanya satu entri provider `nzb` yang aktif.** Dua entri akan sama-sama memindai direktori `nzbs/` yang sama dan menggandakan setiap rilis. Ini bukan batas jumlah *penyedia Usenet* yang bisa kamu pakai. Akun berita tambahan ditaruh di bawah `nntp.servers` milik satu entri itu, tempat mereka melayani pustaka yang sama, bukan membuat salinan kedua.
- **`watchlist: true` tidak bisa menargetkannya.** Backend Usenet tidak bisa menambahkan konten, jadi ia tidak pernah bisa menjadi akun tempat penambahan watchlist Plex masuk.

### Lebih dari satu penyedia Usenet {#more-than-one-usenet-provider}

Retensi berlaku per penyedia. Selisihnya antara satu kali fetch tambahan dan rebuild PAR2 untuk seluruh rilis adalah apakah akun lain masih menyimpan artikelnya. Itulah sebabnya akun kedua lebih berharga di sini dibanding redundansi biasa.

Kunci yang sudah ada di blok `nntp` menjelaskan akun pertama. Apa pun di bawah `servers` adalah akun lain. Akun dengan `priority` yang sama berbagi beban. Angka yang lebih tinggi baru ditanya setelah yang lebih rendah. Akun `backup` baru ditanya setelah semua akun primer gagal mengirim artikel tersebut. Konfigurasi akun tunggal yang sudah ada tetap berjalan tanpa perlu diubah:

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Setiap akun punya jatah koneksinya sendiri. Pembacaan dijalankan sesuai **gabungan jatah koneksi dari akun non-backup yang berbagi `priority` terendah yang aktif**. Dalam contoh di atas, 30 + 20 = 50, karena keduanya memakai priority default. Jadi penyedia tanpa batas kedua di priority yang sama memberi throughput tambahan sekaligus asuransi retensi. Akun `backup` tidak memberi keduanya, dan itu disengaja. Akun ini hanya membawa apa yang tidak bisa dipenuhi primer. Jika dihitung, jendela read-ahead akan melebar setiap saat, padahal kapasitas itu tidak pernah dipakai saat playback normal.

Ada tiga kunci yang menentukan akun mana yang ditanya:

| Key | Default | Efek |
|---|---|---|
| `name` | nilai dari `host` | Memberi label pada akun di log. |
| `priority` | `0` | Akun mana yang ditanya lebih dulu, dari yang terendah. Akun dengan priority yang sama ditanya sesuai urutan penulisan, kecuali akun yang masih punya koneksi bebas didahulukan daripada akun yang jatahnya sudah habis. Jadi dua akun yang setara berbagi beban dan tidak antre di satu akun. |
| `backup` | `false` | Menandai akun block berbayar yang hanya ditanya setelah semua primer menyatakan artikelnya tidak ada, mengirim salinan yang rusak, gagal di tengah jalan, atau tidak bisa dihubungi. Primer yang hanya **sibuk** tidak cukup. zurg akan menunggu daripada menghabiskan byte berbayar untuk sesuatu yang bisa dilayani akun unlimited. |
| `backbone` | `""` | Menyebutkan spool artikel tempat akun tersebut terhubung. Dua akun di backbone yang sama menyimpan artikel yang sama. Jadi begitu salah satunya menyatakan artikel tidak ada, akun lain di spool yang sama dilewati, tidak perlu membayar round trip untuk jawaban yang sama. |

Setiap akun juga punya batas hangat sendiri, diambil dari jatah koneksinya sendiri. Celah retensi membuat pembacaan langsung melewati primer, jadi akun yang pertama kali dipakai adalah akun yang koneksinya belum pernah dipanaskan. Akun block dengan dua koneksi bisa diatur agar tidak memakai batas hangat sama sekali dengan `warm_connections: -1`.

Banyak yang menjual ulang akses Usenet, jadi isi `backbone` dengan benar. Dua akun yang kamu beli dari perusahaan berbeda bisa saja berada di spool yang sama. Kalau tidak diisi, setiap miss akan ditanyakan dua kali. Kamu bebas memberi nama grup apa pun. String itu hanya dibandingkan dengan entri lain.

Saat startup, zurg menyebutkan semua akun yang akan dipakainya:

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

Sensus yang memutuskan apakah sebuah rilis perlu diperbaiki akan menanyakan setiap akun sebelum menyatakan artikel hilang. Setiap akun hanya ditanya tentang artikel yang tidak ada di akun sebelumnya. Kegagalan transport tidak pernah disalahartikan sebagai artikel yang sudah kedaluwarsa. Jika sebuah akun timeout atau menjatuhkan artikel di tengah jalan, kegagalan itulah yang dilaporkan. Dengan begitu, timeout tidak pernah membuat keheningan disajikan atau repair dijadwalkan untuk sesuatu yang sebenarnya belum hilang. Akun yang sama sekali tidak bisa dihubungi tidak dihitung. Jika akun lain menyatakan artikel itu sudah hilang, artikel tersebut dianggap hilang.

### Mengonfigurasi penyedia di Dashboard {#configuring-providers-in-the-dashboard}

`http://localhost:9999/config/` → **Essentials** → **Providers** melakukan hal yang sama tanpa perlu mengedit YAML. Tabel ini menampilkan semua akun sesuai urutan di config:

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

Untuk baris `nzb`, kolom Token menampilkan **host news server** alih-alih petunjuk token, karena memang tidak ada token yang perlu disembunyikan. Setelah itu ada angka yang menunjukkan berapa news server tambahan yang dimiliki.

**Untuk menambahkan akun Usenet:**

1. Klik **Add provider**.
2. Atur **Type** ke `nzb`. Kolom token akan hilang dan kolom NNTP muncul di tempatnya.
3. Biarkan **Name** kosong kalau kamu tidak ingin nama lain selain `nzb`. Nama ini dipakai sebagai nama direktori per akun, jadi kalau kamu isi `usenet`, di mount kamu akan muncul `__usenet__`.
4. Isi **NNTP host**, **Port**, **TLS** (sudah dicentang secara default, biarkan saja menyala), **Username**, **Password**, **Connections** (teks petunjuk `8`; isi dengan jatah koneksi sesuai paket kamu) dan **Cache size MB** (teks petunjuk `512`).
5. Biarkan **Watchlist target** tidak dicentang. Backend tidak bisa menambahkan konten, jadi kalau dicentang saat menyimpan, akan ditolak. **Disabled** membuat entri tetap ada di `config.yml` tanpa dimuat.
6. Klik **Save**.

Formulir divalidasi seolah-olah perubahan sudah diterapkan, jadi kalau ada kesalahan, kamu akan mendapat peringatan (alert) dan config tidak akan rusak. Menambahkan provider `nzb` **kedua** akan ditolak. Pesan errornya akan mengarahkan kamu ke **Further news servers** (atau `nntp.servers`), tempat akun news tambahan seharusnya dimasukkan.

**Untuk menambahkan news server lain**, misalnya akun kedua atau akun block di backbone lain, klik **Edit** pada baris `nzb`, lalu klik **Add news server** di bagian **Further news servers**. Setiap server punya **Name**, **NNTP host**, **Port**, **TLS**, **Username**, **Password**, **Connections**, **Priority**, **Backbone** dan **Backup only** sendiri-sendiri. **Remove server** menghapus satu server. **Save** akan menulis semuanya ke `nntp.servers`.

**Untuk mengedit salah satu**, klik **Edit** pada barisnya. Formulir akan memuat semua pengaturan kecuali password, baik untuk akun pertama maupun untuk setiap news server tambahan. Kolom password akan dibiarkan kosong, dan artinya *pakai yang sudah ada*. Ketik password baru hanya kalau kamu memang ingin menggantinya. Pengaturan yang tidak punya kolom di formulir akan tetap dibiarkan seperti yang ada di `config.yml`.

**Delete** akan meminta konfirmasi, lalu menghapus entri provider dari `config.yml`. Direktori `nzbs/` kamu tidak akan tersentuh. File NZB tetap berada di tempatnya dan akan muncul kembali bersama provider. Provider aktif terakhir tidak bisa dihapus maupun dinonaktifkan.

Setiap perubahan di sini langsung ditulis ke `config.yml` dan akan menampilkan pesan:

> Provider changes saved to config.yml — restart zurg to apply

Perubahan provider **tidak** dimuat ulang secara otomatis (hot-reload). Restart zurg dulu sebelum berharap ada perubahan.

---

## 2. Jalankan zurg dan konfirmasi akun {#2-start-zurg-and-confirm-the-accounts}

+++ Linux dan macOS
```bash
./zurg
```
+++ Windows
```powershell
.\zurg.exe
```
+++

Jika `zurg setup` memasang zurg agar berjalan otomatis, mulai ulang dengan `zurg service restart` sebagai gantinya (`./zurg service restart`, atau `.\zurg.exe service restart` di Windows).

zurg memeriksa akun news sekali saat startup, karena kata sandi yang salah jika tidak akan muncul jauh lebih lambat sebagai semua file gagal diputar:

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

Kegagalan total juga sama mencoloknya:

```
Cannot reach the news server for nzb: <reason>
```

Periksa dulu pasangan port dan TLS (`563`+`tls: true`, atau `119`+`tls: false`), lalu kredensialnya, lalu apakah paket langganannya benar-benar aktif.

**Jika punya beberapa akun, baca peringatannya, jangan hanya baris connected.** Setiap akun yang tidak bisa dijangkau mendapat peringatannya sendiri, dan startup tetap berjalan selama *satu* akun masih merespons. Error di atas hanya muncul jika semua akun tidak bisa dijangkau. Jadi penyedia kedua yang mati akan terlihat seperti startup yang sehat, kecuali Anda memperhatikannya:

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. Tambahkan file NZB {#3-add-nzb-files}

zurg membuat folder pantau `nzbs/` saat mulai berjalan. Folder ini ada di folder tempat zurg dijalankan. Salin file NZB ke dalamnya.

+++ Linux and macOS
```bash
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```
+++ Windows
```powershell
Copy-Item "$HOME\Downloads\Some.Release.2024.2160p.nzb" nzbs\
```
+++

Dalam satu-dua detik zurg menyadari file itu dan membacanya, lalu library langsung menampilkannya begitu proses baca selesai. Log akan menunjukkan apa yang dibacanya:

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### Seberapa cepat muncul {#how-quickly-it-appears}

zurg memantau `nzbs/` sendiri, dengan pengecekan sekitar sekali per detik yang hanya memakai satu syscall, berapa pun jumlah NZB di dalam direktori itu. Jadi file yang masuk ke sana dibaca hampir seketika, bukan menunggu pengecekan perubahan library berikutnya. Sebuah [obfuscated release](#obfuscated-releases) butuh waktu sedikit lebih lama, karena nama file aslinya harus dibaca dulu dari artikel-artikelnya sendiri, biasanya jauh di bawah satu detik, dan release itu langsung muncul begitu proses ini selesai. Kedua jeda ini tidak lagi bergantung pada `check_for_changes_every_secs`. Dulu iya: sebuah obfuscated release bisa baru muncul hingga dua interval penuh setelah dijatuhkan, satu untuk pembacaan direktori dan satu lagi karena namanya baru selesai di-resolve sesaat setelah pengecekan yang seharusnya mendeteksinya. Diukur pada interval 10 detik, jaraknya 17,7 detik dari saat file dijatuhkan sampai release muncul, dan 0,67 detik di antaranya adalah waktu pemrosesannya.

Pengecekan berkala tetap ada dan tetap menjadi cadangan. Pengecekan inilah yang menangkap dua hal yang tidak bisa dilaporkan sendiri oleh direktori yang dipantau: NZB yang **diganti di tempat** dengan nama yang sudah ada, dan filesystem yang timestamp direktorinya terlalu kasar untuk membedakan dua perubahan yang terjadi dalam detik yang sama.

### Apa yang diambil {#what-gets-picked-up}

- File **langsung di dalam `nzbs/`** yang namanya berakhiran `.nzb`, tidak peduli huruf besar atau kecil.
- **Subdirektori dilewati.** `nzbs/movies/foo.nzb` tidak akan terbaca. Taruh semua di satu folder saja, jangan dikelompokkan. Pengelompokan library diatur lewat directory filters, bukan lewat folder ini.
- **Hanya XML biasa.** `.nzb.gz` tidak akan di-unpack maupun dibaca, jadi decompress dulu.
- File yang gagal di-parse akan dilewati dengan warning dan tidak menghentikan proses scan.

### Nama rilisnya apa {#what-the-release-is-called}

Nama yang ditampilkan zurg, dan karenanya nama folder yang dilihat Plex, adalah:

1. Nilai `<meta type="name">` milik NZB itu sendiri, kalau ada dan masih lolos sanitasi, jika tidak,
2. **nama file tanpa `.nzb`**.

Jadi, sebagian besar waktu, *nama file NZB adalah nama rilisnya*. Beri nama file seperti kamu memberi nama rilisnya, karena itulah yang akan dicoba dicocokkan oleh media server kamu:

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/indexer_download_48213.nzb
```

Dua rilis berbeda yang berakhir dengan nama yang sama dibedakan dengan tag hash pendek (`Some.Release {a1b2c3}`), sama seperti di tempat lain di zurg.

### Rilis yang dilindungi kata sandi {#password-protected-releases}

Jika indexer mencatat sandi arsip di blok metadata NZB, zurg akan menggunakannya saat streaming dari set RAR:

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

Tidak perlu yang lain. Rilis yang dilindungi sandi yang NZB-nya tidak memuat metadata sandi tidak bisa dibuka.

### Rilis yang diobfuskasi {#obfuscated-releases}

Posting yang nama filenya acak tetap bisa ditangani, dengan biaya yang dibayar sekali saat scan. zurg mencoba sumber yang murah dulu, yaitu nama file yang masih dideklarasikan artikel di yEnc header-nya sendiri, satu artikel per file. Kalau gagal, ia jatuh ke indeks PAR2 rilisan, yang mencatat nama asli tiap file terhadap MD5 dari 16 KiB pertamanya. Nama dan ukuran pastinya ada di header artikel, jadi scan bisa memberi jawaban begitu header itu datang, sementara body-nya lanjut masuk ke cache untuk dibaca nanti. Jadi rilisan yang di-obfuscate tetap dapat nama dan ukuran dari artikel yang sama. Ia mencatat apa yang berhasil dipulihkan:

```
Recovered 27 filename(s) in Some.Release
```

Seluruh proses penamaan dibatasi 90 detik per NZB, jadi server yang tidak bisa dihubungi hanya memperlambat scan, tidak membuatnya macet. Nama dipastikan *sebelum* library dibangun darinya, karena library menyimpan file berdasarkan nama, dan kalau diganti nanti, file itu akan hilang.

**Posting yang sepenuhnya di-obfuscate tidak punya nama asli untuk dipulihkan.** Beberapa poster melakukan obfuscate sebelum membuat recovery set, jadi indeks PAR2 mengembalikan nama yang memang acak (`aJPSgA7eYizyzjJXT.part01.rar`), dan file di dalam arsipnya juga berupa hash. Tidak ada yang ada di posting itu yang tahu isi rilisannya, hanya nama NZB itu sendiri. Jadi zurg menampilkan payload dengan nama rilisan, sama seperti yang dilakukan SABnzbd di akhir unpacking:

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

Hanya file yang jelas merupakan rilisan yang diganti namanya: entri terbesar di dalam arsip, dan hanya jika ukurannya minimal tiga kali lipat dari entri berikutnya, ekstensinya bukan bagian dari struktur disc (`.vob`, `.m2ts`, `.mpls`), dan namanya tidak bermakna apa-apa. Subtitle dan sampel yang namanya sama ikut mengikutinya. Arsip yang berisi beberapa file dengan ukuran mirip, misalnya season pack, dibiarkan apa adanya, karena tidak ada satu pun dari file itu yang merupakan rilisannya. Nama-nama asli di dalam arsip tetap berfungsi sebagai alamat, jadi pemutar yang sudah jalan sebelum rescan tidak kehilangan file-nya.

### Mengganti dan menghapus {#replacing-and-removing}

- **Menghapus** NZB dari `nzbs/` akan menghapus rilis itu dari library, membuang reader dan article cache-nya, serta melupakan byte hasil perbaikan yang dulu disimpannya.
- **Menghapus rilis Usenet dari Dashboard akan menghapus file `.nzb` dari disk.** Tidak ada tempat lain untuk file itu. Ini berbeda dengan menghapus torrent dari akun debrid, yang file-nya tetap ada di layanan.
- **Mengganti NZB di tempat adalah cara yang lambat.** Menimpa file tidak mengubah direktori, jadi watch di atas tidak akan mendeteksinya. Yang mendeteksi adalah pengecekan perubahan berkala, yang membaca waktu modifikasi file dan mem-parse ulang file tersebut, yaitu pada pengecekan `check_for_changes_every_secs` pertama yang terjadi lebih dari 15 detik setelah pembacaan direktori terakhir (sekitar 30 detik pada pengaturan default). Menghapus file lama lalu menambahkan file baru terdeteksi dalam satu atau dua detik, dan itu juga yang dilakukan indexer atau endpoint SABnzbd.

## 4. Tempat rilis muncul di mount {#4-where-releases-land-in-the-mount}

Rilis Usenet adalah entri pustaka biasa, jadi filter `directories:` yang sudah kamu punya berlaku tanpa perubahan:

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

Selain itu, akun mendapat direktori sendiri: `__nzb__` secara default, atau `__<name>__` jika kamu mengatur `name:` pada entri provider. Direktori itu bukan sekadar tampilan. Pembacaan di dalamnya **dipatok** ke akun Usenet tanpa failover, jadi itu tempat yang tepat untuk menguji apakah pemutaran Usenet berjalan tanpa akun debrid yang diam-diam menjawab. Jika Usenet adalah satu-satunya akun, folder itu tidak ditampilkan di daftar root mount dan `__all__` berisi file yang sama, jadi uji pemutaran lewat `__all__` di mount, atau buka jalur HTTP langsung `http://localhost:9999/http/__nzb__/`.

Ada empat hal khusus Usenet yang perlu diketahui saat menulis filter:

- **Filter tag cocok dengan konten Usenet setelah dianalisis.** Setiap tag `zurg_*` (resolusi, HDR, bitrate, durasi, bahasa) berasal dari ffprobe. zurg menjalankan ffprobe pada file Usenet sendiri, lewat server sendiri dan dengan kecepatan yang bisa ditangani news server, jadi rilis Usenet mendapat tag seperti yang lain setelah dianalisis. Sampai saat itu, direktori yang memakai `tags_match_any` tidak akan menampungnya.
- **File `.par2` dan `.sfv` disembunyikan.** Itu adalah perancah perbaikan. zurg membacanya sendiri, dan tidak ada media server yang membutuhkannya, apalagi delapan file per season pack. `.nfo` tetap ditampilkan, karena Kodi, Emby, dan Jellyfin membacanya.
- **Set RAR adalah konten, bukan arsip yang perlu di-unpack.** `.rar` dan `.rNN` tetap terlihat, dan sebuah set volume muncul di mount sebagai *folder* yang isinya adalah file di dalamnya. zurg men-stream video langsung dari arsip tanpa mengekstraknya. Rilis yang *hanya* berisi satu set volume justru menggantikan isinya sendiri, tanpa folder arsip di antaranya: payload berada langsung di folder rilis, tempat media server mencarinya. File yang diposting bersama set, seperti `.nfo`, `.txt` dari poster, artwork, dan subtitle, tetap ditampilkan di sana juga.
- **`force_select_playable_files` tidak berlaku.** Posting Usenet itu utuh, jadi tidak ada yang perlu dipilih. Setiap file konten sudah ditawarkan.

Cek hasilnya dulu sebelum melibatkan media server. `http://localhost:9999/http/` adalah indeks HTML biasa dari apa yang akan ditampilkan mount:

+++ Linux dan macOS
```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```
+++ Windows
Ketik `curl.exe`, bukan `curl`: di Windows PowerShell 5.1, `curl` adalah nama lain dari `Invoke-WebRequest`.

```powershell
curl.exe -s http://localhost:9999/http/__nzb__/ | Select-Object -First 10
```
+++

---

## 5. Pasang dengan rclone {#5-mount-it-with-rclone}

### Jalur mudah: biarkan zurg menjalankan rclone {#the-easy-path-let-zurg-run-rclone}

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg menjalankan rclone dengan profil VFS yang sudah disetel untuk pola bacanya sendiri (ukuran buffer, ukuran chunk, mode cache, waktu dir-cache, timeout). zurg juga menjaga mount tetap hidup dan menghapus entri dircache yang tepat ketika library berubah. `mount_path` juga menjadi awalan yang dipakai zurg untuk memberi tahu Plex path mana yang harus di-scan, jadi harus diisi walaupun kamu mount di tempat lain.

Cek dulu:

+++ Linux
```bash
ls /mnt/zurg/
ls /mnt/zurg/__all__/
```
+++ macOS
```bash
ls /Volumes/Zurg/
ls /Volumes/Zurg/__all__/
```
+++ Windows
Jalankan di jendela PowerShell di desktop kamu: drive-nya hanya terlihat di sesi logon yang me-mount-nya ([aturan sesi](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
Get-ChildItem Z:\
Get-ChildItem Z:\__all__\
```
+++

### Jalur manual: rclone milik Anda sendiri {#the-manual-path-your-own-rclone}

Jika Anda sudah mengelola rclone, arahkan remote WebDAV ke zurg:

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

+++ Linux
rclone tidak membuat mount point, dan `/mnt` dimiliki oleh root:

```bash
sudo mkdir -p /mnt/zurg && sudo chown "$USER" /mnt/zurg
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ macOS
Memerlukan [macFUSE](../setup/macos.md#step-1-install-macfuse) dan rclone dari [rclone.org](https://rclone.org/downloads/): rclone dari Homebrew tidak bisa di-mount. rclone tidak membuat mount point, dan `/Volumes` dimiliki oleh root:

```bash
sudo mkdir -p /Volumes/Zurg && sudo chown "$USER" /Volumes/Zurg
rclone mount zurg: /Volumes/Zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ Windows
Memerlukan [WinFsp](https://winfsp.dev). Huruf drive tidak boleh sedang dipakai, dan hanya program di sesi logon tempat rclone berjalan yang bisa melihatnya ([aturan sesi](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
rclone mount zurg: Z: --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++

`--vfs-handle-caching 0` memerlukan rclone 1.74 atau yang lebih baru, dan mencegah rclone terus mengunduh selama lima detik lagi setelah pembaca menutup file. README menjelaskan apa akibatnya jika opsi ini dihilangkan.

Tetap atur `mount_path` di `config.yml` ke lokasi tempat Anda me-mount, atau notifikasi pemindaian media server akan dibuat dengan prefix yang salah.

### Docker

Direktori kerja zurg di image adalah `/config`, dan direktori watch serta cache repair berada di dalamnya. Satu bind mount membawa semuanya, termasuk file lain:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./:/config
    ports:
      - 9999:9999
```

Setelah itu, NZB yang kamu taruh di `./nzbs` pada host akan langsung terbaca di dalam container tanpa perlu restart.

Untuk mount ini kamu butuh host Linux. Docker Desktop di macOS dan Windows menjalankan container di dalam VM, dan mount tersebut tidak sampai ke Finder, Explorer, atau Plex yang terpasang di host. Di sana, gunakan binary [macOS](../setup/macos.md) atau [Windows](../setup/windows.md) ([alasannya](../setup/docker.md)).

> Instalasi yang dibuat sebelum `/config` di-bind-mount, yaitu `/app/config.yml`, `/app/nzbs`, dan `/app/data` dimount terpisah, tetap berjalan seperti biasa. Lihat [docker.md](../setup/docker.md#upgrading-an-install-that-mounted-app).

---

## 6. Arahkan Plex ke sana {#6-point-plex-at-it}

1. **Berikan kredensial Plex ke zurg**, supaya zurg bisa meminta Plex memindai hanya path yang berubah, alih-alih membuatmu menunggu pemindaian penuh berkala. Cara termudah adalah lewat alur autentikasi Plex di Dashboard, yang akan menulis nilainya kembali ke `config.yml`:

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **Tambahkan library yang mengarah ke subdirektori mount**, jangan pernah ke root mount:

   - Movies → `/mnt/zurg/movies` (`/Volumes/Zurg/movies` di macOS, `Z:\movies` di Windows)
   - TV Shows → `/mnt/zurg/shows` (`/Volumes/Zurg/shows` di macOS, `Z:\shows` di Windows)

   Di Windows, Plex hanya bisa melihat `Z:` jika berjalan di sesi logon yang sama dengan zurg. Task logon dari `zurg setup` memastikan hal itu. Lihat [aturan sesi](../setup/windows.md#keeping-it-running-the-session-rules).

   Rilis yang sama muncul di setiap direktori yang filternya cocok *dan* di bawah `__all__` dan `__nzb__`. Jika Plex diarahkan ke root, file yang sama akan dipindai berulang kali.

3. **Atur dua opsi library** di Edit → Advanced untuk setiap library:

   - **Hilangkan centang "Empty trash automatically after every scan".** Ini yang paling penting. Jika mount bermasalah sebentar saat Plex sedang memindai (misalnya zurg restart atau rclone di-remount), Plex akan menganggap semua file sudah dihapus. Dengan auto-empty aktif, file langsung dihapus permanen. Dengan opsi ini mati, file tetap ada di trash dan kembali saat mount pulih. Ini pernah membuat library berisi 30,000 item hilang.
   - **Hilangkan centang "Generate video preview thumbnails".** Setiap thumbnail butuh seek ke seluruh file. Di Usenet, itu berarti membaca penuh rilis lewat jatah koneksimu.

4. **Jangan pernah restart zurg saat Plex sedang memindai.** Cek dulu sebelum melakukannya:

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   Di Windows, jalankan ini di PowerShell dari folder zurg:

   ```powershell
   $TOKEN = ((Select-String -Path config.yml -Pattern '^plex_token:').Line -split '\s+')[1].Trim('"', "'")
   (Invoke-RestMethod "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN").MediaContainer.size
   @((Invoke-RestMethod "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN").MediaContainer.Directory | Where-Object refreshing -eq 1).Count
   ```

   Jika sesi menampilkan `size="0"` (`0` di Windows) dan hitungan yang di-refresh menunjukkan `0`, berarti aman. Jika baris sesi tidak menampilkan apa pun, Plex menolak token atau tidak merespons, dan `0` di bawahnya tidak berarti apa-apa. Periksa `plex_token` sebelum restart. (PowerShell menampilkannya sebagai error `401`.) (Gunakan `grep -o … | wc -l`, bukan `grep -c`. grep keluar dengan kode non-zero saat tidak menemukan apa-apa, dan itu justru kondisi *baik*. Jika tidak, rantai `&&` akan terhenti tepat sebelum restart yang seharusnya dijaga.)

5. **Pemindaian parsial.** `on_library_update` menerima setiap path yang berubah. `plex_update.sh` di root repo adalah skrip referensinya:

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

   Skrip ini membutuhkan `curl`, `xmllint`, dan `python3`, yang sudah ada di Docker image. Baris `zurg_mount` juga harus diatur ke path mount-mu. Di Windows, hook dijalankan di PowerShell, bukan `sh`, jadi skrip ini tidak berjalan di sana. Setiap path yang berubah masuk sebagai satu elemen `$args`, relatif terhadap mount, dengan garis miring maju (`movies/Big Buck Bunny`). Berikan path-path itu ke skrip PowerShell dengan `@args`:

   ```yaml
   on_library_update: '& C:\zurg\my_update.ps1 @args'
   ```

   zurg sudah meminta Plex memindai path yang berubah setelah langkah 1 selesai dan `mount_path` diatur. Jadi hook hanya perlu untuk keperluan lain.

**Yang tidak akan didapat Plex dari konten Usenet:** Tidak ada apa pun sampai zurg menganalisisnya (lihat bagian 4). Jadi Plex mungkin melakukan analisis sendiri saat pertama kali diputar, seperti yang dilakukannya untuk file lokal lainnya. Ukuran file akan stabil tak lama setelah rilis dipindai. Daftar pertama mungkin menampilkan perkiraan murah berdasarkan jumlah artikel, lalu panjang yang tepat menyusul. Panjang itu diambil dari recovery index jika ada, dan jika tidak, dari satu artikel per file. Untuk arsip multi-volume besar yang recovery index-nya sudah mencantumkan panjang tepat setiap file, satu volume yang sudah diverifikasi bisa menentukan jarak artikel (stride) yang sama. Setiap volume lain akan memeriksa inferensi itu terhadap header-nya sendiri sebelum menyajikan byte pertamanya. Begitu sebuah panjang tercatat, library diberi tahu bahwa rilis berubah, sehingga mount dan Plex sama-sama melihat panjang yang sebenarnya. zurg memproses hingga delapan rilis sekaligus, dan tidak pernah lebih dari jumlah koneksi akun. Ini berlaku untuk akun dengan dua belas koneksi atau kurang. Akun yang lebih besar memproses lebih banyak: dua belas rilis untuk 16 koneksi, enam belas mulai dari 20 koneksi. Saat akuisisi memeriksa rilis dengan news server, pemeriksaan itu antre bersama sizing dan read-ahead ini. Pemeriksaan tidak pernah mengambil koneksi yang disimpan untuk read yang sedang ditunggu pemutar.

### Jellyfin / Emby / Infuse

Jellyfin dan Emby memakai `jellyfin_server_url` / `jellyfin_token` dan `emby_server_url` / `emby_token`, lalu menerima notifikasi scan yang sama; lihat [jellyfin.md](jellyfin.md). Infuse bisa langsung diarahkan ke `http://<host>:9999/dav/` tanpa perlu rclone sama sekali.

## 7. Ketika sebuah artikel hilang {#7-when-an-article-is-missing}

Ini adalah kegagalan yang dimiliki Usenet, tetapi debrid tidak. Artikel bisa habis masa retensinya di penyedia tertentu atau dihapus, dan sebuah rilis bisa tetap tercantum dengan sempurna padahal beberapa artikelnya sudah hilang.

Jawaban zurg, berdasarkan urutan prioritas:

1. **Tanya server berita lain.** Artikel yang sudah habis masa retensinya di satu penyedia sering kali masih ada di penyedia lain. Ini cukup satu kali pengambilan. Lihat [Lebih dari satu penyedia Usenet](#more-than-one-usenet-provider).
2. **Bangun ulang dari file PAR2 milik rilis itu sendiri.** Memang untuk keperluan inilah file PAR2 diposting. Caranya perlu membaca *seluruh rilis*. Reed-Solomon harus menggabungkan setiap slice yang masih ada untuk menghitung satu slice yang hilang. Jadi untuk posting 200 GB, kamu harus membaca 200 GB hanya untuk memulihkan beberapa megabyte.
3. **Sajikan kekosongan.** Ini hanya dilakukan jika kedua cara di atas tidak bisa memberi jawaban.

Perbaikan PAR2 berjalan sebagai tugas latar belakang, paling banyak dua rilis sekaligus, dan membutuhkan:

```yaml
enable_repair: true            # the default; set false to turn PAR2 repair off
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

Byte hasil rekonstruksi ditulis di `data/par2/<nzb-id>/` dan akan dipakai lagi saat file dibuka berikutnya, jadi restart tidak membuat seluruh rilis harus dibaca ulang. Hanya bagian yang benar-benar hilang yang disimpan. Rilis yang rusak biasanya hanya memakan beberapa megabyte. Jika batas anggaran terlampaui, rilis yang paling lama tidak diakses akan dihapus lebih dulu. Setiap bagian rilis diberi stempel waktu modifikasi dari NZB tempat bagian itu direkonstruksi. Jadi jika NZB disimpan ulang, bagian tersebut dibuang dan tidak disajikan, karena offset-nya mungkin sudah berubah.

Saat perbaikan dimulai, zurg akan memberi tahu, lalu menyebutkan biayanya:

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s on the avx2 kernel, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

Ada dua hal yang perlu kamu ketahui:

- **Pemutaran selalu didahulukan dibanding perbaikan.** Koneksi dibagikan berdasarkan siapa yang sedang menunggu. Pembacaan langsung didahulukan, lalu read-ahead, dan perbaikan di urutan terakhir. Namun perbaikan dijamin mendapat seperempat dari jatah terhadap read-ahead, sehingga file yang sedang diputar tetap bisa memperbaiki celah yang membuatnya macet.
- **Perbaikan tingkat library dari zurg tidak bisa membantu di sini.** Mekanisme itu menambahkan ulang torrent ke akun asalnya. Backend yang tidak bisa menambahkan konten hanya bisa melaporkan rilis itu rusak, tanpa bisa memperbaikinya. Untuk Usenet, PAR2 *adalah* perbaikannya.

Rilis yang NZB-nya tidak punya file PAR2 dan kamu tidak punya akun server berita kedua tidak punya jalur pemulihan sama sekali. Itu sifat dari posting-nya sendiri, bukan karena zurg.

---

## Performa {#performance}

| | |
|---|---|
| Satu stream, file langsung | ~100 Mbit/s |
| Satu stream, dari set RAR | 90–106 Mbit/s |
| Dua stream bersamaan, total | ~124 Mbit/s |

Jatah koneksi menentukan batas pertama untuk kecepatan single-stream. zurg menjaga jatah itu tetap terisi dengan mengatur read-ahead dalam artikel dan byte: posting artikel kecil untuk arsip mendapat jangkauan minimal 64 MiB, sementara posting berukuran beberapa megabyte tetap memakai jendela koneksi-dan-pipeline yang sudah ada. Jadi:

- **Atur `connections` sesuai jumlah koneksi paket kamu.** Ini adalah pengaturan utama untuk tuning. Delapan koneksi tidak akan cukup untuk men-stream remux.
- **Dua akun primary itu saling menambah.** Pembacaan diatur sesuai gabungan jatah koneksi dari akun non-`backup` yang memakai `priority` terendah yang aktif. Jadi penyedia unlimited kedua dengan priority yang sama juga menaikkan batas atas, sekaligus menutupi celah retensi dari yang pertama. Akun `backup` tidak dihitung.
- **`warm_connections` (4 secara default) membeli latency, bukan throughput.** Ia menahan sejumlah koneksi tetap terbuka, idle, dan sudah terautentikasi, sehingga read pertama setelah start atau setelah jeda lama tidak menghabiskan ~0.8 detik untuk dial sebelum byte pertama: 1.5 detik sampai byte pertama saat dingin, dibanding 0.15 detik saat hangat. Setelah stream berjalan, ia tidak mengubah apa pun.
- **Dial yang memang terjadi dipaku ke satu backend, sehingga TLS session-nya bisa di-resume.** Satu dial memakan sekitar 0.8 detik, diukur dengan server news live pada 2026-08-29: 106ms TCP, 213ms TLS handshake, 256ms greeting, 218ms untuk dua pertukaran `AUTHINFO`. Hostname provider adalah rotasi (yang satu ini resolve ke 11 alamat), dan TLS session ticket hanya berlaku di mesin yang mengeluarkannya. Jadi dial ulang ke alamat mana pun yang pertama kali diberikan resolver hanya me-resume **0 dari 3** sesi, sementara dial ulang ke alamat yang sama me-resume **3 dari 3**. Setiap akun sekarang dial ulang ke alamat tempat koneksi terakhirnya berasal, dan itu menghemat **110–140ms di setiap dial ulang**. Handshake yang di-resume memakan 109–141ms, dibanding 225–261ms untuk handshake penuh. Server dengan round trip ~18ms akan menghemat lebih sedikit. Pin dilepas dan nama di-resolve ulang begitu alamat itu berhenti merespons, jadi tidak ada yang terkunci ke mesin yang sudah dipensiunkan provider. Penolakan yang sampai ke NNTP, seperti akun yang sudah mencapai batas koneksinya atau password yang ditolak, tetap mempertahankan pin, karena itu jawaban dari akun, bukan dari backend. Setiap dial mencatat fasenya di level debug, termasuk `resumed=`.
- `cache_size_mb` (default 512) dipakai bersama oleh semua file yang sedang dibaca. Naikkan jika kamu menjalankan beberapa stream bersamaan. Ini tidak membuat satu stream lebih cepat. Speculative read boleh memakai paling banyak setengahnya untuk paling banyak dua reader, sisanya disisakan untuk artikel yang sudah dikonsumsi atau akan segera dikonsumsi.
- Apakah sebuah rilis dikemas RAR atau diposting sebagai file biasa sekarang tidak terlalu berpengaruh pada throughput.

**Satu artikel lambat tidak lagi menghentikan stream.** Sebuah sequential read dengan rata-rata ~90 MB/s tetap bisa turun ke 1–5 MB/s selama sekitar satu detik setiap kali, dan setiap penurunan itu penyebabnya sama: sebuah artikel berhenti datang sementara koneksi lain menyelesaikan artikel mereka lalu idle. Ketika sebuah read sudah menunggu satu artikel lebih lama dari yang biasanya diperkirakan reader itu, zurg meminta artikel yang sama ke **koneksi kedua** dan melayani jawaban mana pun yang datang lebih dulu. Batch pipelined yang macet bisa menahan beberapa artikel playhead berturut-turut di socket mati yang sama, jadi hingga lima artikel berbeda dari satu reader boleh di-hedge bersamaan, atau satu sampai dua pada post yang artikelnya di bawah 1 MiB. Satu artikel tidak pernah diminta dua kali. Akun tetap hanya membayar untuk paling banyak 20 permintaan kedua per menit. Deadline tetap dua kali lipat dari waktu tunggu terakhir reader itu sendiri, tidak pernah kurang dari 250 ms (125 ms untuk post yang artikelnya di bawah 1 MiB) dan tidak pernah lebih dari 2 s. Hanya read yang benar-benar ditunggu client yang di-hedge. Read-ahead, prefetch volume berikutnya, dan repair tidak. Artikel yang baru saja *ditolak* server juga tidak di-hedge: artikel itu sudah menunggu konfirmasinya sendiri satu detik kemudian, dan meminta di dalam jendela itu tidak membuktikan apa-apa. Setiap hedge menulis satu baris di level debug yang menyatakan berapa lama read tadi terblokir, dan baris berikutnya menyatakan apakah permintaan kedua yang menang.

Untuk rentang yang dideklarasikan, artikel playhead masuk ke priority scheduler sebelum byte-byte berikutnya ditawarkan. Koneksi pipelined kemudian dibagi per putaran artikel berurutan, bukan per potongan berdampingan, sehingga artikel berguna pertama tersebar di seluruh jatah koneksi. Request minimal 64 MiB diperlakukan sebagai playback dan mendapat full range frontier. Seek kecil tetap dianggap probe dan hanya membuka ramp yang sempit.

### Melintasi batas volume {#crossing-a-volume-boundary}

Sebuah file di dalam set RAR disajikan satu volume per waktu, dan setiap volume adalah pembacaan terpisah ke akun Usenet. zurg membuka volume berikutnya selagi volume yang sedang berjalan masih diputar, dan membaca empat megabyte pertamanya, jadi perpindahan ke volume baru tidak dimulai dari nol. Pada rilis yang diposting dengan volume kecil, bagian awal itu saja tidak cukup: empat megabyte kira-kira sepuluh artikel dari rilis yang diposting dalam bagian ~395 KB, dan volume ~26 MB menempatkan batas setiap 1,7 detik pemutaran. Jadi stream menghabiskan bagian awal yang sudah hangat dari memori dalam seperempat detik, lalu menunggu satu round trip untuk semua yang ada di belakangnya. Diukur di Hetzner CCX23 dengan sepuluh koneksi pada 8 September 2026, rilis itu di-stream dengan **14–16 MB/s**, sementara file biasa di akun yang sama mencapai **86–99 MB/s**. Laju satu detiknya berayun antara 1 dan 29 MB/s, dan 46 sampai 55 dari 60 slot read-ahead akun itu tidak terpakai.

zurg sekarang menghangatkan volume berikutnya sepanjang satu jendela read-ahead penuh begitu stream mendekati batas dalam 32 MiB. Volume yang baru saja dimasuki stream juga mempertahankan jendela yang sudah didapat, alih-alih mulai lagi dari dua artikel. Volume yang belum akan dicapai posisi putar dalam beberapa detik masih hanya dihangatkan sampai bagian awalnya. Ini mencegah pemindaian library (satu reader per entri, beberapa megabyte dari masing-masing) menarik satu jendela dari setiap volume berikutnya yang tidak akan pernah dibaca. Tidak ada yang perlu dikonfigurasi, dan batas memori tidak berubah: sebuah akun tetap membawa dua jendela read-ahead sekaligus, yaitu volume yang sedang diputar dan volume yang sedang dihangatkan, di dalam `cache_size_mb`.

Perbaikan memang lambat secara alami karena harus membaca seluruh rilis. Namun perbaikan berjalan dengan prioritas latar belakang dan dibatasi oleh server Usenet, bukan oleh perhitungan zurg sendiri.

### Memori: berapa biaya watch directory {#memory-what-a-watch-directory-costs}

Sebuah NZB adalah daftar artikel, dan library besar berarti sangat banyak artikel. Saat di-parse, setiap message id beserta offset-nya disimpan di memori supaya sebuah read bisa menemukannya. Build sebelum ini menyimpan semuanya selama proses berjalan. Diukur pada direktori pantau berisi 2,636 NZB (27.6 juta elemen `<segment>`), ini memakan **1.52 GB heap aktif**, sekitar 58 byte per artikel, di luar cache artikel. Hampir semuanya tidak terpakai. Sebuah listing hanya butuh nama, ukuran, dan jumlah. Hanya file yang sedang dibaca atau diperbaiki yang perlu tahu nama artikelnya.

`nzb_segments` menentukan apakah zurg menyimpannya:

```yaml
nzb_segments: mmap             # mmap (default) | reparse | resident
nzb_segments_idle_secs: 120    # how long a release's articles are kept after the last read
```

- **`mmap`**: daftarnya ditulis ke `data/nzb-index/<id>.bin`, lalu file itu di-map saat dibutuhkan. Byte-nya ada di page cache, bukan di heap zurg, jadi kernel bisa membebaskannya saat memori menipis. **Default di Linux, macOS, dan BSD.** Memakan disk kira-kira sebanyak daftarnya sendiri.
- **`reparse`**: daftar dilepas dari memori setelah sebuah rilis stabil, dan NZB dibaca ulang dari disk saat read atau repair membutuhkannya. Tidak memakan disk sama sekali, dan itu alasan utama memilihnya. Cocok untuk host yang `data/`-nya tidak boleh membesar.
- **`resident`**: semua daftar artikel selalu ada di memori. **Perilaku sebelumnya**, dan yang dilakukan setiap build lama. Masih didukung, hanya saja sekarang bukan lagi default.

Apa pun pengaturannya, listing tidak pernah memuat apa-apa. Nama file, ukuran, dan jumlah artikelnya dijawab tanpa daftar artikel mendekati memori. Jadi refresh library, pengecekan fingerprint, dan *arr yang menanyakan apakah sebuah job sudah stabil tetap gratis. Biaya mode lazy adalah read pertama pada rilis yang sudah tidak disentuh selama `nzb_segments_idle_secs` (sapuan berjalan tiap 30 detik). Seluruh file dalam sebuah rilis dimuat bersamaan, jadi saat menelusuri volume rar sebuah season pack secara berurutan, biayanya cukup dibayar sekali.

Diukur pada rilis 60 file dengan 30,000 segmen:

| | heap per rilis | read pertama rilis yang idle | per artikel di jalur read |
|---|---|---|---|
| `resident` | 1.74 MB | — | 6 ns |
| `reparse` | 21.3 kB | 39 ms | 52 ns |
| `mmap` | 16.6 kB | 0.27 ms | 63 ns |

Lima puluh nanodetik per artikel itu tidak berarti dibanding milidetik untuk mengambil satu artikel, jadi angka jalur read kurang penting daripada kelihatannya. Yang perlu ditimbang adalah reload. `reparse` membaca ulang dan mem-parse seluruh dokumen XML. Pada season pack, ini memakan puluhan milidetik sebelum byte pertama bergerak. `mmap` cukup satu pemanggilan `mmap`, satu slice header per file, dan checksum dari indeks yang baru di-map. Dari ketiganya, itu hanya 0.08 ms. Sisa 0.19 ms adalah harga untuk menangkap byte yang rusak, alih-alih menyajikannya sebagai message id.

Untuk seluruh library, bukan satu rilis (2,636 NZB, 27.6 juta artikel, binary yang sama dijalankan tiga kali pada corpus yang sama, idle setelah scan):

| | resident set | heap aktif | CPU idle | cold open, p50 | index di disk |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Warm open (1 ms), throughput streaming (38–39 MB/s), dan waktu startup tidak terlihat berbeda di antara ketiganya. `mmap` membuka rilis cold *lebih cepat* daripada menyimpan semuanya di memori. Sebab, di bawah `resident`, rilis yang belum pernah dibuka di run ini tetap harus di-parse. Sedangkan me-map arena yang sudah ditulis hanyalah satu syscall, bukan mem-parse megabyte XML.

Indeks ditulis ulang setiap kali NZB berubah. Kalau suatu saat tidak bisa dibaca, indeks memperbaiki dirinya sendiri dengan kembali ke NZB dan menulisnya lagi. Indeks juga dihapus saat NZB keluar dari direktori pantau. Header dan isinya sama-sama di-checksum, jadi byte yang rusak akan tertangkap, bukan disajikan sebagai message id yang tidak pernah diposting siapa pun. Ukurannya saat ini bisa dilihat di halaman depan Dashboard, di bawah **Article Index**, dan di baris yang dicatat backend saat startup. Di **Windows** tidak ada mapping. Indeks akan dibaca ke heap, yang berarti memori resident *ditambah* reload. Karena itu, default di sana tetap `resident`, dan `reparse` adalah mode lazy yang layak dipilih.

---

## Pemecahan masalah {#troubleshooting}

| Gejala | Penyebab | Solusi |
|---|---|---|
| `Cannot reach the news server for nzb` saat startup | Pasangan host/port/TLS salah, kredensial salah, atau paket tidak aktif | `563` dipasangkan dengan `tls: true`, `119` dengan `tls: false`; lalu cek ulang kredensialnya |
| Library kosong, tidak ada baris `Loaded NZB` | Folder `nzbs/` tidak ada, atau ada di tempat yang salah | Folder ini relatif terhadap **working directory** zurg. Cek `WorkingDirectory=` di unit systemd kamu, atau direktori yang di-bind ke `/config` di Docker, yaitu `nzbs/` di sebelah file compose. Hanya instalasi yang lebih lama dari `/config` yang memantau `/app/nzbs` |
| Satu NZB tidak pernah muncul | Ada di subfolder, bernama `.nzb.gz`, atau tidak bisa di-parse | Pindahkan langsung ke `nzbs/`, lalu dekompres. Cek log untuk peringatan `Skipping` |
| Rilis muncul dengan nama yang tidak berguna | Nama file NZB dipakai sebagai nama, karena tidak ada `<meta type="name">` | Ganti nama `.nzb` menjadi nama rilisnya |
| File di dalam rilis punya nama acak | Post yang di-obfuscate dan pemulihannya gagal | Cek `Recovered N filename(s)`. Tanpa file PAR2 di dalam NZB, tidak ada sumber untuk nama aslinya |
| Video masih punya nama acak, meski folder sudah benar | Post yang sepenuhnya di-obfuscate, dan arsipnya berisi beberapa file dengan ukuran mirip | Hanya payload tunggal yang jelas yang diganti namanya sesuai rilis. Season pack dalam satu arsip tetap memakai nama dari arsipnya |
| Streaming lambat | `connections` masih default 8 | Atur sesuai jatah paket |
| Pemutaran pertama setelah lama tidak dipakai butuh beberapa detik untuk mulai, lalu berjalan normal | Warm floor mati, atau dibatasi jadi nol oleh akun satu koneksi | Biarkan `warm_connections` tidak diatur (defaultnya 4), dan pastikan baik itu maupun `warm_connections` tingkat atas tidak diset negatif |
| Koneksi ditolak oleh provider | `connections` melebihi yang diizinkan paket | Turunkan ke angka yang sebenarnya |
| Pemutaran tersendat atau ada bagian yang diam | Artikel hilang | Cari `PAR2 repair of …` di log; pastikan `enable_repair: true`; tambahkan [penyedia Usenet lain](#more-than-one-usenet-provider) |
| Ada bagian yang diam dan tidak pernah muncul baris repair | `enable_repair` mati, atau NZB tidak memuat file `.par2` | Atur `enable_repair: true`. Jika post tidak punya file pemulihan, hanya akun berita lain yang bisa membantu |
| Provider kedua tampaknya tidak pernah ditanya | Kedua akun memakai `backbone` yang sama, jadi yang kedua dilewati setelah yang pertama bilang artikelnya tidak ada | Perbaiki nilai `backbone`. Hanya akun yang memang berada di spool yang sama boleh berbagi nama |
| Salah satu dari beberapa akun mati, tapi startup terlihat normal | Startup hanya gagal jika *semua* akun tidak bisa dijangkau | Grep log untuk `is not reachable`. Setiap akun bermasalah memberi peringatan dengan namanya |
| Akun block ditagih untuk artikel yang juga ada di akun unlimited | `backup: true` belum dipasang | Pasang. Jika primary hanya sibuk, pembacaan tidak akan lagi dialihkan ke akun berbayar |
| Rilis hilang dari direktori yang difilter tag | Belum dianalisis, jadi belum punya tag `zurg_*` | Tunggu analisisnya, atau jalankan Analyze & Tag Library dari dashboard |
| File `.par2` tidak terlihat di mount | Disengaja, karena disembunyikan sebagai perancah perbaikan | Tidak perlu diperbaiki. zurg tetap membacanya |
| Mengubah provider di Dashboard tapi tidak terjadi apa-apa | Perubahan provider ditulis ke `config.yml` tapi tidak di-hot-reload | Restart zurg. Banner di bawah tabel provider menyebutkannya |
| Plex mengosongkan library setelah zurg direstart | Scan sedang berjalan saat mount tidak ada, dan auto-empty-trash aktif | Matikan auto-empty, dan hentikan sesi *dan* refresh state sebelum melakukan restart apa pun |
| Ukuran file berubah sedikit sesaat setelah rilis muncul | Daftar pertama hanya bisa memperkirakan dari jumlah artikel. Panjang pastinya datang belakangan, dari indeks PAR2 atau header yEnc milik file itu | Ini wajar dan akan stabil sekali. Panjangnya ditulis ke `data/nzb-sizes/` dan disimpan sampai NZB berubah |

### Menanyakan tentang satu artikel {#asking-about-one-article}

`GET /debug/nzb/probe` mengajukan satu pertanyaan ke akun berita lewat pool yang sudah dipakai zurg, dengan prioritas yang sama seperti pembacaan permintaan. Endpoint ini ada karena cara lainnya tidak berhasil. Sebuah akun hanya memberi delapan koneksi, dan zurg memakai semuanya. Jadi untuk mengecek sebuah post secara manual, kamu harus punya akun kedua atau menghentikan server. Padahal menghentikan server akan menghapus state yang sedang kamu diagnosis.
Di Windows, gunakan `curl.exe` dan bukan `curl` pada perintah-perintah ini.

```bash
# Is this article still there? A STAT, so nothing is transferred.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?message_id=abc@news.example'

# The same question addressed the way you have it: a release id from the
# library, a file index counting from zero, an article number counting from one.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&file=0&article=3'

# &body=1 fetches the one article and reports what actually arrived against what
# the article says should have. This is how a provider that strips trailing
# bytes is identified: `short: true` with `decoded_bytes` below `span_bytes`.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&article=3&body=1'
```

Endpoint ini membalas `{"probes": [...]}` dengan satu objek untuk provider `nzb`, berisi `found`, `missing`, dan berapa lama prosesnya. Ia bertanya ke akun berita sesuai urutan prioritas sampai ada yang punya artikelnya (akun cadangan baru dicek kalau akun utama tidak punya). Endpoint ini tidak memberi tahu akun berita mana yang punya artikelnya. Sifatnya hanya membaca: apa pun yang diambil tidak masuk ke cache artikel, dan artikel yang tidak ditemukan tidak dicatat sebagai artikel mati. Jadi probe tidak akan membuat file yang masih bisa diputar jadi diam-diam dianggap rusak.

---

Masih mentok? Tanya di forum **zurg-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Lihat juga {#see-also}

- [config.md](../reference/config.md) — setiap opsi, termasuk [referensi akun Usenet](../reference/config.md#usenet-accounts) dan [referensi filter direktori](../reference/config.md#7-directories--filters)
- [plex.md](plex.md) — cara zurg mengatur pemindaian Plex, pencocokan, dan pembersihan sampah
- [jellyfin.md](jellyfin.md) — integrasi Jellyfin
- [docker.md](../setup/docker.md) — pengaturan Docker, propagasi FUSE, dan pemecahan masalah
- [tags.md](../reference/tags.md) — sistem tag
- [architecture.md](../internals/architecture.md) — `internal/nzb` dan `internal/nntp` dalam konteks
