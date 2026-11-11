# Bermigrasi dari streamnzb v5.1.0 ke zurg {#migrating-from-streamnzb-v510-to-zurg}

streamnzb adalah addon Stremio. Ia mencari di indexer Newznab saat kamu menekan play dan men-stream hasil terbaiknya.
Tidak ada yang disimpan. Ia tidak punya mount filesystem WebDAV atau library Plex.

Tidak ada **library di disk yang perlu dijaga dan tidak ada status tontonan Plex yang berisiko**. Langkah path-preservation di panduan migrasi lain tidak berlaku.

zurg bisa menggantikannya dengan dua cara. Pakai salah satu atau keduanya.

- **Tetap pakai Stremio.** zurg punya [addon Stremio](../guides/stremio.md) sendiri. Ia mencari di indexer Newznab kamu saat kamu menekan play dan men-stream rilis yang kamu pilih lewat akun news kamu.
  Begitulah cara kerja streamnzb juga. Kamu hanya butuh zurg. Tidak perlu rclone dan tidak perlu media server. Setiap rilis yang diputar dengan cara ini juga tetap tersimpan di library zurg.
- **Bangun library.** zurg menyimpan rilis yang dimilikinya dalam sebuah library dan me-mount-nya untuk Plex, Jellyfin, atau Emby. Sonarr dan Radarr bisa mengisinya. zurg sendiri juga bisa mengisinya dari watchlist kamu.

Beberapa hal yang dilakukan streamnzb tidak punya padanan di zurg. Panduan ini menjelaskan yang mana.

Panduan ini lebih pendek dari panduan sejenisnya karena masalahnya juga lebih kecil.

## Apa yang perlu di-rescan dan konten baru apa yang muncul {#what-needs-rescanning-and-what-new-content-shows-up}

Dua pertanyaan yang dijawab oleh [panduan migrasi lain](index.md) sebenarnya tidak berlaku di sini. Ada baiknya saya jelaskan alasannya, supaya Anda tidak perlu menebak-nebak.

**Tidak ada yang perlu dipindai ulang karena memang tidak ada yang bisa dipindai ulang.** streamnzb tidak menyimpan pustaka apa pun, dan Plex tidak punya item yang terikat ke path mana pun. Jadi seluruh mekanisme trash-guard di halaman bersama itu tidak penting bagi Anda. Tidak ada item lama yang perlu dijaga dan tidak ada yang bisa terhapus karena kesalahan.

**Semuanya konten baru.** Apa pun yang Anda taruh di `nzbs/` milik zurg akan dipindai untuk pertama kalinya ke pustaka yang masih kosong. Atur pustaka Anda sesuai keinginan sebelum pemindaian pertama, jangan memperbaikinya belakangan. Ada dua pengaturan yang sebaiknya sudah siap lebih dulu.

- [`only_show_the_biggest_file: true`](../reference/config.md) pada direktori yang dipindai pustaka media Anda. Tanpa ini, klip sampel, file `.nfo`, dan file `.url` berisi iklan dari poster akan ikut terlihat.
- "Generate video preview thumbnails" **nonaktif** pada pustaka tersebut. Di mount streaming, setiap proses thumbnail adalah pembacaan penuh rilis yang memakan jatah berita Anda. Pemindaian pertama menyerahkan seluruh pustaka ke Plex sekaligus.

---

## Perubahan model {#the-model-change}

| | streamnzb | zurg |
|---|---|---|
| Akuisisi konten | Mencari indexer Newznab per permintaan play | [Addon Stremio](../guides/stremio.md) mencari indexer Newznab per permintaan play. Library juga terisi dari file `.nzb` dan endpoint SABnzbd serta [akuisisi](../guides/acquisition.md) |
| Pemeringkatan dan pemilihan | jhin traits dan filter profile serta pengecekan AvailNZB | Resolusi dulu, lalu sebaran ukuran di tiap resolusi. Tidak ada traits dan tidak ada filter profile |
| Penyimpanan | Tidak ada yang disimpan. Setiap play adalah pencarian baru | Library persisten. Rilis yang diputar lewat addon tetap tersimpan di dalamnya |
| Client | Stremio. Addon-nya juga berfungsi sebagai penyedia metadata | Stremio lewat addon zurg, yang hanya menjawab stream. Media server apa pun lewat mount. Atau WebDAV langsung untuk Infuse |
| Filesystem | Tidak ada | Mount rclone FUSE plus WebDAV plus indeks HTTP biasa |
| Arsip | RAR dan 7z **STORE only**. Rilis yang terkompresi tidak akan bisa diputar | RAR dan 7z terkompresi di-stream secara transparan |
| Post yang diobfuskasi | Ditolak | Nama dipulihkan dari header yEnc dan PAR2. Payload ditampilkan dengan nama rilis |
| Post yang rusak | Dilewati lewat AvailNZB | Perbaikan PAR2 membangun ulang artikel yang hilang. Addon melewati rilis yang bagian awalnya hilang dan mencoba yang berikutnya |
| SABnzbd API | Tidak. Sebagai gantinya ada proxy NNTP di port 119 | Ya dan opt-in. Setiap grab dicek ke news server. Post yang mati dibangun ulang dari PAR2 jika memungkinkan dan dilaporkan Failed jika tidak |

Untuk sehari-hari, Stremio bisa tetap seperti biasa. Tambahkan addon zurg dan pilih judul seperti sebelumnya. zurg akan mencari di indexer kamu dan memutar apa yang kamu pilih. [Halaman Stremio](../guides/stremio.md) menjelaskan setup-nya. Play pertama dari sebuah rilis akan menunggu sementara zurg mengambil NZB dan mendaftar isi rilis tersebut. Biasanya hanya beberapa detik. Setiap play berikutnya dari rilis itu langsung mulai.

Library untuk media server kamu butuh sesuatu untuk mengisinya.

- **Endpoint SABnzbd.** Mengatur `sabnzbd.enabled: true` membuat zurg menjawab Sonarr dan Radarr sebagai download client. Proses import berupa rename di dalam `__magic__`. Grab akan masuk ke `__magic__/__all__`. Import memindahkan file dari sana ke root folder yang kamu buat di sebelahnya. Tidak ada yang disalin. Sebagian besar setup library sebaiknya memakai ini. Lihat [Sonarr &
  Radarr](../guides/sonarr-radarr.md). zurg mengecek setiap grab ke news server sebelum melaporkannya selesai. Ia memeriksa bagian awal dan akhir setiap file. Ia juga mengunduh artikel pertama dari setiap file. Itu bisa sampai enam puluh empat artikel ditambah beberapa lagi untuk rilis dengan sedikit file. Beberapa news server masih bilang sebuah artikel ada padahal kontennya sudah diturunkan, dan hanya unduhan yang bisa menunjukkan hal itu. zurg membangun ulang rilis yang artikelnya hilang dari file PAR2-nya jika memungkinkan. Yang tidak bisa dibangun ulang akan dilaporkan **Failed**. \*arr kemudian memasukkannya ke blocklist dan mengambil yang lain.
- **Akuisisi.** zurg bisa mengambil permintaan sendiri. Permintaan itu datang dari watchlist Plex kamu dan dari Seerr serta \*arr. Ia mencari di indexer Newznab kamu dan mengecek setiap grab dengan cara yang sama. Lihat [akuisisi](../guides/acquisition.md).
- **Manual drop.** Unduh `.nzb` dari situs indexer kamu dan salin ke `nzbs/`. Namanya tetap dan direktorinya dipindai ulang kira-kira setiap 15 detik. File tidak pernah dipindahkan atau dihabiskan. Ini selalu berhasil dan merupakan dasar yang paling jujur.
- **Sonarr dan Radarr "Usenet Blackhole".** \*arr bisa diatur dengan download client Blackhole yang *Nzb Folder*-nya adalah `nzbs/` milik zurg. Dengan cara ini otomatisasi search-and-grab kembali, tanpa endpoint, dengan satu konsekuensi. \*arr menunggu unduhan yang sudah selesai muncul di watch folder-nya lalu mengimpornya. zurg tidak pernah menghasilkan unduhan seperti itu karena rilisnya muncul di mount. Jadi antrean \*arr akan menampilkan item itu tidak pernah selesai. Kamu mendapat pengiriman NZB otomatis, bukan pipeline import dan rename milik \*arr. Sisi \*arr dari cara ini belum diverifikasi ulang untuk panduan ini. Sisi zurg sudah diverifikasi dalam kode di `internal/nzb/provider.go:30`.
- **RSS atau unduhan cart dari indexer ke sebuah direktori.** Ini sepenuhnya bergantung pada indexer dan pada kamu yang menulis script untuk pengambilannya. Belum diverifikasi dan hanya disebutkan karena beberapa indexer menawarkannya.

**Beri nama file sebelum kamu drop.** Folder rilis di mount dinamai sesuai *nama file* NZB. Header `<meta type="name">` hanya dipakai jika nama filenya terlihat seperti hash. Itu diukur di kelima server pada 2026-08-19. File bernama `indexer_download_48213.nzb` tidak memberi Plex apa pun untuk dicocokkan, jadi ganti namanya ke nama rilis dulu. Ini juga berarti nama folder sepenuhnya ada di bawah kendali kamu. Dua rilis berbeda dengan nama yang sama akan mendapat akhiran ` {shorthash}`.

---

## Konfigurasi yang ikut terbawa {#configuration-that-carries-over}

Ada dua hal yang perlu dipindahkan. Yang pertama adalah penyedia Usenet kamu. streamnzb mengatur penyedia di **Settings → Providers** dengan host, port, username, password, dan connections. Environment variable juga bisa dipakai. Akun yang sama akan menjadi blok `nntp` milik zurg.

Sebelum di streamnzb. Ini bentuk environment variable dengan nama key yang tercantum di dokumentasi.

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

Sesudah di `config.yml` milik zurg.

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

Penyedia kedua di streamnzb, seperti `PROVIDER_2_*`, masuk ke `nntp.servers`. Di situ zurg akan mencoba akun satu per satu untuk setiap artikel. `priority` langsung dipetakan. zurg juga punya dua konsep yang tidak ada padanannya di streamnzb. Dengan `backup: true`, sebuah akun blok berbayar hanya dicek kalau semua akun utama menjawab *no such article*. Dengan `backbone`, dua akun di spool yang sama tidak akan ditanya hal yang sama dua kali. Entri `nzb` hanya boleh ada satu. Akun berita tambahan harus dimasukkan ke dalamnya, bukan ditaruh di sebelahnya.

Yang kedua adalah indexer kamu. Indexer ditaruh di `stremio.indexers` dengan URL dan API key yang sama. Acquisition memakai daftar yang sama kalau tidak punya daftarnya sendiri.

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

Tidak ada yang lain dari `data/config.json` streamnzb yang ikut pindah. Blok `streams` dan `filter_profiles` menentukan apa yang ditawarkan addon streamnzb. Addon zurg punya satu daftar per judul dan peringkatnya sendiri. Pengaturan terdekatnya ada dua. `max_size_gb` membuang rilis yang melebihi ukuran tertentu. `max_results` menentukan berapa banyak rilis yang disimpan untuk setiap resolusi. Sisanya ada di [halaman Stremio](../guides/stremio.md).

---

## Riwayat tontonan {#watch-history}

streamnzb menyimpan riwayat pemutaran per-stream di database-nya. Secara default itu SQLite di `data/streamnzb.db`, dan bisa juga pakai Postgres. Dari data itu streamnzb membangun baris Continue Watching dan Because You Watched. Dokumennya menjelaskan isinya sebagai "library, search and play history, bad releases, and metrics".

**Semua itu tidak bisa dipindah ke library Plex.** Status tontonan Plex disimpan per-item di database Plex sendiri, dan terikat ke item yang harus sudah ada di library dulu. Tidak ada importer di kedua sisi. Ini sebenarnya bukan kehilangan data, lebih ke perbedaan model. Baris riwayat streamnzb mengacu ke pencarian dan stream, bukan ke file. Kalau kamu mau menyimpan catatannya sebelum mematikan setup lama, database-nya berupa SQLite biasa dan bisa langsung dibaca.

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

Nama tabel yang pasti tidak didokumentasikan dan belum diverifikasi untuk panduan ini. Cara mengetahuinya adalah dengan menjalankan `.tables`. Di Postgres, data yang sama ada di database mana pun yang ditunjuk oleh `DATABASE_URL`. Status tontonan di setup barumu mulai dari nol dan terkumpul di Plex sejak pemutaran pertama.

---

## Apa yang kamu dapatkan {#what-you-gain}

- **Perpustakaan sungguhan.** Plex, Jellyfin, dan Emby memindai filesystem dan menyimpan metadata, lalu melacak status tontonan di setiap client yang mereka dukung. Bukan cuma Stremio.
- **Perbaikan PAR2.** Rilis dengan artikel yang hilang akan dibangun ulang dari file recovery-nya sendiri di latar belakang. Cara streamnzb menangani rilis yang rusak adalah melewatkannya. Cara zurg adalah memperbaikinya.
- **Rilis yang diobfuscate.** zurg memulihkan nama file asli dari header yEnc dan indeks PAR2, lalu menampilkan payload yang sepenuhnya diobfuscate dengan nama rilisnya. Diukur di pengujian, `Obfuscated.nzb` menyajikan `Toy.Story.5.2026...KyoGo.mkv` yang bersih. streamnzb menolak rilis seperti ini begitu saja.
- **RAR dan 7z terkompresi.** streamnzb hanya men-streaming arsip STORE'd, dan README-nya jelas menulis "Compressed RAR releases will not play". zurg men-streaming video dari arsip terkompresi dan tetap mereproduksi struktur direktori di dalamnya.
- **Pemutaran kedua langsung mulai.** streamnzb mencari dan memeriksa ulang setiap kali kamu memutar. zurg menyimpan apa yang sudah kamu putar. Rilis yang sudah ada di perpustakaan langsung bisa diputar. Semua yang diambil Sonarr atau Radarr sudah berada dalam kondisi ini sejak awal.
- **Kedalaman multi-akun.** Ada prioritas, akun `backup` yang dihitung per pemakaian, `backbone` untuk dedup, dan jalur perbaikan ketika semua akun tidak punya artikelnya.

## Apa yang hilang {#what-you-lose}

Jangan remehkan fitur-fitur ini. Justru fitur inilah produknya.

- **jhin dan profil filter.** Addon zurg juga mencari di indexer Anda. Addon ini hanya mengurutkan berdasarkan resolusi dan ukuran. Tidak ada sifat jhin, profil filter, atau skor.
- **Pengecekan AvailNZB.** zurg tidak bertanya ke siapa pun apakah sebuah rilis masih hidup. Addon mengeceknya dengan membaca bagian awal rilis yang Anda pilih. Kalau bagian itu sudah hilang, addon lanjut ke rilis berikutnya dalam daftar. Grab dari Sonarr atau Radarr dicek dulu ke news server Anda sebelum dianggap selesai. Kerusakan yang ada lebih dalam di file akan ketahuan saat sebuah pembacaan sampai ke bagian itu. Perbaikan PAR2 lalu membangunnya kembali, selama postingan membawa data pemulihan yang cukup. Pada 2026-08-19, set RAR yang kehilangan volume utuh tampil sebagai folder kosong, bukan sebagai error.
- **Katalog dan baris milik streamnzb.** Katalog bawaan dan metadata-nya, serta baris Continue Watching dan Because You Watched, berasal dari riwayatnya sendiri. Addon zurg hanya melayani stream. Media server punya versinya sendiri dari baris-baris tersebut untuk pustakanya.
- **Proxy NNTP di port 119.** Kalau SABnzbd atau NZBGet diarahkan ke streamnzb sebagai news server mereka, maka mereka perlu kredensial provider yang asli lagi.

---

## Menyiapkan zurg {#standing-up-zurg}

`config.yml` yang sudah jalan untuk Usenet saja.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

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

Jangan pakai filter `tags_match_any` untuk konten Usenet. Tag `zurg_*` berasal dari ffprobe, dan ffprobe tidak pernah jalan di backend ini. Akibatnya, direktori seperti itu tidak akan pernah berisi rilis Usenet. Sebagai gantinya, filter berdasarkan nama, ekstensi, ukuran, dan `has_episodes`.

Lalu jalankan.

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__all__/
```

Kalau Usenet adalah satu-satunya akun kamu, folder `__nzb__` tidak ditampilkan di daftar root mount, dan `__all__` berisi file yang sama. Jadi, tes pemutaran lewat `__all__` di mount, atau buka jalur HTTP langsung `http://localhost:9999/http/__nzb__/`. Subdirektori di dalam `nzbs/` dilewati, dan `.nzb.gz` tidak dibaca.

### Library Plex pertama {#the-first-plex-library}

Arahkan library ke **subdirektori** dari mount, seperti `/mnt/zurg/movies` dan `/mnt/zurg/shows`. Jangan pernah ke root. Rilis yang sama muncul di `__all__` dan di setiap direktori yang cocok, jadi kalau root yang di-scan, isinya akan ter-scan berkali-kali. Kalau Usenet adalah satu-satunya akun kamu, `__nzb__` tidak muncul di daftar root mount dan tidak bisa di-resolve lewat mount, karena `__all__` sudah berisi file yang sama. Beri zurg `plex_server_url` dan `plex_token` supaya zurg bisa meminta partial scan.

Ada dua pengaturan library yang penting dari scan pertama, baik library-nya baru maupun sudah lama. Masalah yang ingin dicegah adalah mount yang sempat putus *selama* scan berjalan.

1. **Hilangkan centang "Empty trash automatically after every scan"** supaya `autoEmptyTrash` bernilai 0. Kalau mount hilang di tengah scan, Plex akan menganggap semua file sudah terhapus. Restart zurg atau remount rclone sudah cukup untuk memicu ini. Kalau auto-empty aktif, file langsung dihapus permanen. Kalau dimatikan, file hanya masuk ke trash dan akan kembali saat mount hidup lagi. Masalah seperti ini pernah membuat puluhan ribu item hilang.
2. **Hilangkan centang "Generate video preview thumbnails".** Di Usenet, setiap proses thumbnail berarti membaca penuh rilis tersebut dan memakai kuota koneksi kamu.

Dan jangan pernah restart zurg saat Plex sedang scan. Pemeriksaan awal dan kedua poin di atas harus bernilai nol.

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Pakai `grep -o … | wc -l` dan bukan `grep -c`. grep akan keluar dengan status non-zero kalau tidak menemukan apa-apa, dan itu justru kondisi *yang baik* di sini. Hasilnya, rantai `&&` atau script dengan `set -e` akan berhenti tepat sebelum restart yang seharusnya dijaga.

Ukuran file baru stabil beberapa saat setelah rilis pertama kali muncul di daftar. NZB tidak mencatat berapa panjang sebuah file. Jadi daftar pertama memperkirakan ukurannya dari ukuran artikel yang tercatat di NZB. Perkiraan ini bisa meleset sampai sekitar 3 persen lebih tinggi. Setelah itu zurg mempelajari panjang file yang sebenarnya di latar belakang dan menyimpannya. Scan yang berjalan sebelum itu akan melihat nilai perkiraan. Plex kemudian menganggap file tersebut sudah berubah dan menganalisisnya sekali lagi. Tidak ada yang terhapus.

## Menjalankan keduanya secara bersamaan {#running-both-side-by-side}

Tidak ada yang bentrok di port. streamnzb memakai 7000 dan 119, dan zurg memakai 9999. Jadi cara transisi yang masuk akal adalah tetap membiarkan streamnzb melayani Stremio selagi library zurg terisi.

Satu-satunya resource yang dipakai bersama adalah akun news. **Keduanya membaca dari jatah koneksi yang sama, dan provider menegakkannya untuk keduanya.** Paket dengan 50 koneksi tidak bisa menjalankan streamnzb di 50 dan zurg di 30. Kelebihannya akan ditolak, dan di sisi zurg itu terlihat seperti stream yang lambat atau macet. Bagi secara eksplisit. Coba `PROVIDER_1_CONNECTIONS=20` di streamnzb dan `connections: 30` di zurg. Beri zurg seluruh jatah ketika streamnzb sudah dipensiunkan, karena throughput single-stream zurg ditentukan oleh angka itu.

Saat kamu mematikan streamnzb, hapus addon Stremio-nya dari client kamu. Simpan salinan `data/` kalau kamu ingin riwayatnya. `config.json` dan `streamnzb.db` adalah seluruh state-nya. Setelah itu, arahkan ulang semua yang sebelumnya memakai NNTP proxy di 119 ke provider kamu secara langsung.
