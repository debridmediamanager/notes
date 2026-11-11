# Dokumentasi Konfigurasi zurg {#zurg-configuration-documentation}

Dokumen ini menjelaskan semua opsi konfigurasi yang tersedia untuk zurg. Atur opsi-opsi ini di file `config.yml` kamu.

> **Tip:** Sebagian besar pengaturan bisa diatur lewat **Dashboard** di `http://localhost:9999/config/`. Antarmuka web ini memudahkan kamu melihat dan mengubah pengaturan tanpa harus mengedit file config secara langsung.

## Bermigrasi dari konfigurasi sebelum `providers` {#migrating-from-a-pre-providers-config}

Kalau config kamu ditulis sebelum dukungan multi-account masuk, config itu tetap bisa jalan. Key level atas `token:`, `download_tokens:`, dan `strm_link_token:` tetap dibaca sebagai satu hal yang memang bisa mereka wakili: satu akun Real-Debrid. Saat startup, zurg akan memberi peringatan bahwa key tersebut sudah deprecated. Satu-satunya perubahan yang perlu kamu buat di file config adalah memindahkannya ke dalam entri `providers`, dan kamu bisa melakukannya kapan saja. Tidak ada key lain yang diganti nama, diubah tipenya, atau dihapus.

Meski begitu, bukan hanya itu yang berubah. Ada beberapa directive yang namanya dan nilainya tetap sama, tapi cara kerjanya sedikit berbeda karena kode yang membacanya sudah dipindah. Semuanya dikumpulkan di [Apa lagi yang berubah saat kamu upgrade](#what-else-changes-when-you-upgrade) di bawah. Layak dibaca kalau kamu memfilter archive, tag, atau waktu sebuah release ditambahkan.

### Satu-satunya perubahan yang perlu dilakukan {#the-one-change-to-make}

Dulu satu akun Real-Debrid ditulis sebagai tiga kunci tingkat atas. Sekarang ketiganya ada di dalam satu entri `providers`.

Sebelumnya:

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

Sesudahnya:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

Hapus kunci lama setelah dipindahkan. Jika dibiarkan di samping blok `providers` yang sudah mengatur Real-Debrid, kunci itu diabaikan, dan saat dijalankan akan muncul peringatan tentang kunci tersebut. Dengan begitu, keduanya tidak akan diam-diam berbeda soal token mana yang aktif. Tidak ada lagi yang perlu diubah di file kamu. Semua kunci lain tetap sama nama dan artinya, dan config yang kredensial satu-satunya adalah `token:` cukup dengan perubahan ini saja.

Kamu tidak wajib melakukannya. Config yang belum dipindahkan tetap bisa jalan: ketiga kunci itu dibaca sebagai satu akun Real-Debrid bernama `realdebrid`, dan saat dijalankan program akan menyebutkan kunci mana yang dibaca beserta penulisan yang seharusnya dipakai. Kunci ini sudah deprecated, bukan lagi didukung: fitur akun baru hanya bisa diakses lewat entri `providers`.

Environment variable `TOKEN` / `RD_TOKEN` masih berfungsi dan tetap otomatis membuat config saat pertama kali dijalankan.

### Apa yang menjadi mungkin, yang mungkin Anda inginkan {#what-became-possible-that-you-may-want}

Semua ini tidak wajib. Ini yang didapat dari blok `providers`:

| Sekarang tersedia | Di mana |
|---|---|
| Backend TorBox, AllDebrid, dan Usenet, bisa dipakai bersama Real-Debrid atau menggantikannya | [Akun](#accounts) |
| Beberapa akun dari layanan yang sama, dibedakan dengan `name` | [Akun](#accounts) |
| `disabled: true` untuk menonaktifkan akun tanpa menghapus kredensialnya | [Akun](#accounts) |
| `watchlist: true` untuk memilih akun mana yang dicoba lebih dulu untuk menambahkan torrent baru | [Akun](#accounts) |
| Filter direktori `provider:` / `not_provider:`, dan direktori per akun | [Direktori](#7-directories--filters) |
| `rd_cdn_host_preference` dan `tb_cdn_host_preference` untuk memilih CDN per layanan | [Pemilihan CDN & Host](#cdn--host-selection) |

Ada dua perubahan kecil yang perlu kamu tahu:

- `cdn_host_preference` masih berfungsi dan tetap berarti Real-Debrid. Sekarang ini menjadi alias untuk `rd_cdn_host_preference`, yang akan diutamakan jika keduanya diatur.
- Kredensial Plex dari alur auth di Dashboard sekarang disimpan kembali ke `config.yml` sebagai `plex_server_url` dan `plex_token`. Dulu kredensial ini ada di `data/plex.json`.

### Bermigrasi secara manual vs. lewat dashboard {#migrating-by-hand-vs-by-dashboard}

Dashboard bisa menyelesaikannya untuk kamu. Config yang belum dimigrasi tetap bisa dimuat, jadi editor providers bisa diakses, dan editor ini menampilkan akun Real-Debrid tempat kunci level atas kamu dibaca. Saat kamu menyimpan akun apa pun, kunci-kunci itu akan dipindahkan ke blok `providers` di disk. Mengedit file secara manual lalu restart juga menghasilkan hal yang sama, dan itu satu-satunya pilihan jika config sama sekali tidak bisa dimuat.

Satu hal yang sekarang tidak lagi diterima Dashboard: `POST /config` dulu menerima `token`, `download_tokens` dan `strm_link_token` sebagai kunci level atas, tapi sekarang membalas `400 Unknown config option`. Kredensial sekarang diedit per akun. Skrip apa pun yang mengatur ketiga kunci itu perlu diperbarui.

### Apa lagi yang berubah saat Anda memperbarui {#what-else-changes-when-you-upgrade}

Setiap directive di bawah tetap memakai nama, tipe, dan nilainya. Yang berubah adalah kode yang membacanya, jadi config yang sama bisa menghasilkan hasil yang berbeda. Tidak ada yang perlu kamu ubah. Ini hanya gambaran tentang apa yang bisa kamu harapkan, dan apa yang perlu kamu ubah hanya jika kamu tidak setuju dengannya.

**Filter sekarang bisa melihat isi arsip.** `any_file_inside_regex`, `any_file_inside_contains`, `any_file_inside_size_gte`/`_lte`, bentuk `not_`-nya, `has_episodes`, dan `is_music` dulu dievaluasi terhadap arsipnya sendiri: satu entri bernama `Show.part01.rar`, dengan ukuran seukuran volumenya. Setelah zurg mendaftar sebuah arsip, filter ini sekarang dievaluasi terhadap isinya: nama file aslinya, ukuran aslinya, dan sengaja *tidak* memakai ukuran arsipnya sendiri, yang dulu menutupi semua isinya. Season pack yang dulu terbaca sebagai satu file raksasa sekarang cocok dengan `has_episodes`. `any_file_inside_regex: /\.mkv$/i` mulai cocok di tempat yang dulu gagal, dan `any_file_inside_not_regex` berhenti cocok di tempat yang dulu lolos. Selain itu, release yang semua filenya `.rar`/`.r00`/`.par2` sekarang akhirnya sampai ke filter, padahal dulu langsung masuk ke `__unplayable__`.

Perubahan ini berlaku bertahap per release, bukan sekaligus: hanya untuk arsip yang sudah didaftar zurg, dan daftar yang ditulis oleh parser lama akan dibuang. Jadi sebuah release berpindah saat pertama kali dibuka. Kalau direktori kamu bergantung pada cara baca yang lama, tulis ulang aturannya terhadap nama arsip dengan `regex`/`not_regex`, yang tetap cocok dengan nama release.

**Filter tag tidak lagi menangkap release yang tidak pernah di-probe.** Tag `zurg_*` berasal dari ffprobe. Saat tidak ada yang bisa di-probe, semua tabel tier berakhir di nilai terendah, dan release tetap diberi stempel `zurg_sdr`, `zurg_very_low_video_bitrate`, `zurg_very_low_audio_bitrate`, dan `zurg_0to20mins_duration`, seolah-olah menggambarkan file yang belum pernah diukur. Tag-tag itu sekarang tidak lagi dibuat. Filter yang memakai salah satu dari empat tag ini akan berubah artinya untuk release yang tidak bisa di-probe: `has_tag`/`tags_match_all`/`tags_match_any` berhenti menangkapnya, dan, bagian yang perlu kamu cek, `not_has_tag`, `tags_missing_all`, dan `tags_missing_any` **mulai** menangkapnya. Filter yang memakai tier lain tidak terpengaruh.

**`added_within_hours` / `added_within_days` / `added_after` / `added_before` membaca stempel waktu yang lebih lama untuk duplikat.** Saat sebuah release muncul lebih dari sekali, entrinya sekarang melaporkan waktu tambah paling awal, bukan yang pertama kali terlihat. Jadi salinan kedua dari release lama tidak lagi terlihat seperti baru ditambahkan. Direktori bergaya `recent` bisa saja membuang release yang dulu tetap disimpannya.

**Mount sekarang menyimpan daftar direktori selama 12 jam.** `check_for_changes_every_secs` dulu mengatur `--dir-cache-time` milik rclone, sehingga daftar kedaluwarsa setiap 15 detik secara default. Sekarang daftar bertahan selama 12 jam, dan zurg secara eksplisit melupakan entri terkait setiap kali library berubah, yang membuat scan media server tetap hangat. Untuk kembali ke cara lama, timpa langsung. `rclone_extra_args` menang atas flag bawaan apa pun:

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**Setiap akun mendapat direktori `__<account>__`.** Direktori ini dibuat dari blok `providers`, bukan dari `directories`. Isinya semua yang dimiliki akun itu, direktori ini mengabaikan filter direktori kamu, dan membaca dikunci ke akun tersebut. `directories` tidak bisa menyembunyikannya. Jika ada lebih dari satu akun, direktori ini ditampilkan di root mount. Build sebelum nightly 2026.10.24.0551 juga menampilkan folder akun tunggal di sana. Mulai dari nightly tersebut, folder itu tidak lagi ada di daftar root mount, karena `__all__` adalah library yang sama. Path HTTP dan WebDAV langsung seperti `/http/__realdebrid__/` masih merespons. Lewat mount, path itu juga tidak lagi bisa di-resolve. Arahkan library atau script apa pun yang memakai `__<name>__` ke `__all__`.

**Dua release yang punya nama sama sekarang menjadi dua entri.** Dulu keduanya digabung menjadi satu, dan diam-diam melipat file satu release ke release lainnya. Yang tidak mempertahankan nama polos diberi akhiran enam karakter dari info hash-nya, misalnya `Movie.2024 {a1b2c3}`. String yang diberi akhiran inilah yang dicocokkan oleh `regex`, `not_regex`, `contains`, dan `not_contains`, jadi pola berjangkar akan melewatkannya. Selain itu, entri yang dibedakan karena basename ganda akan diganti namanya sekali saat upgrade, dari file id buatan akun menjadi tag yang berasal dari path.

**File `.strm` berubah bentuk.** Dengan `serve_strm_files`, setiap `.strm` yang disajikan mount berubah isi dan ukuran yang dilaporkannya. URL-nya sekarang menunjuk ke entri library, bukan ke link satu akun, jadi bisa failover dan tetap berfungsi setelah repair. Media server akan melihat setiap `.strm` berubah. Dengan `save_strm_files`, file yang sudah ditulis akan ditulis ulang di tempat dengan nama yang sama saat zurg pertama kali dijalankan, dan media server akan mengambil URL baru pada scan berikutnya. Bentuk baru ini ditandatangani dengan secret di `data/strm_secret`. Jika file itu tidak bisa ditulis, zurg mencatat peringatan dan tetap jalan, tetapi link berhenti berfungsi setelah restart berikutnya. Jadi jangan diabaikan.

**`load_dumped_torrents` tidak akan memuat `dump/` dari sebelum upgrade.** Torrent yang di-cache sekarang membawa akun asalnya, dan yang tidak punya stempel itu akan dilewati. Cache utama akan mengimpor ulang dari akun pada refresh berikutnya. `dump/` tidak punya akun di belakangnya, jadi akan kosong dengan peringatan di log. Ekspor ulang dari instance yang sedang berjalan jika kamu membutuhkannya.

**Repair mengambil jalur yang berbeda saat `restrict_repair_to_cached` dan `only_full_torrent_repair` bernilai false.** Kedua key tidak berubah saat diatur ke `true`. Saat keduanya mati, yang merupakan default, strategi per file dan batch digantikan oleh satu kali add ulang yang menyebutkan file yang rusak. Tujuannya sama, hanya permintaan ke akun yang berbeda.

**Perubahan kecil.** `ignore_renames` sekarang juga menentukan nama `.zurgtorrent` di disk (bermigrasi sendiri saat dimuat). `retries_until_failed` sekarang membatasi retry fair-usage Real-Debrid, yang dulu diulang terus tanpa henti. `auto_analyze_new_torrents: false` dan `ffprobe_binary` yang tidak ada tidak lagi menahan pembersihan cache, yang dulu ikut dilewati bersama analisisnya. Filter ukuran yang mengecualikan volume pertama arsip sekarang menyembunyikan seluruh arsip itu, alih-alih jatuh ke volume berikutnya. Aset statis tanpa autentikasi diperluas dari `/static/css/*` menjadi `/static/*`. Tidak ada route yang sebelumnya dilindungi menjadi publik.

## Konfigurasi Windows {#windows-configuration}

Saat menjalankan zurg di Windows, path harus ditulis dengan format yang berbeda:

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Poin penting untuk Windows:**
- Beri tanda kutip di sekitar semua path
- Untuk `mount_path`: gunakan huruf drive seperti `P:\` (ditulis sebagai `P:\\` di YAML) atau `P:/`
- Untuk path binary: garis miring `/` juga bisa dipakai dan menghindari masalah escape
- Pastikan ekstensi `.exe` disertakan untuk executable

## 1. Dasar-dasar (Setup Dulu) {#1-essentials-setup-first}

Ini adalah pengaturan wajib agar server bisa jalan.

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `zurg` | string | *(wajib)* | Pengenal versi konfigurasi. Harus diisi `v1`; nilai lain (termasuk jika kunci ini tidak ada) akan membuat proses pemuatan gagal. |
| `providers` | list | *(wajib)* | Akun debrid dan Usenet Anda, satu entri untuk masing-masing. Lihat [Akun](#accounts) di bawah. Kunci `token`, `download_tokens`, dan `strm_link_token` di level atas yang berasal dari sebelum `providers` sudah tidak dipakai lagi. Kunci ini tetap bisa dimuat sebagai satu akun Real-Debrid, dan startup akan memberi peringatan. Jika blok `providers` sudah mengonfigurasi Real-Debrid, blok itu yang dipakai dan kunci lama diabaikan. |
| `mount_path` | string | Bergantung OS | Path filesystem tempat rclone mount Anda berada. zurg memakai path ini untuk memberi tahu media server (Plex, Jellyfin, Emby) di mana file berada. Path ini juga dipakai sebagai titik mount saat `rclone_enabled` bernilai true. Defaultnya `/mnt/zurg` (Linux), `/Volumes/Zurg` (macOS), atau `Z:` (Windows). Pengguna Docker sebaiknya mengisi ini dengan `/zurg_mnt/zurg` beserta volume mount `/zurg_mnt:/zurg_mnt:rshared` (lihat [docker.md](../setup/docker.md)). |
| `base_url` | string | `""` | URL zurg Anda yang bisa diakses dari luar. URL ini disisipkan ke dalam file STRM supaya media server bisa melakukan streaming. Jika tidak diisi, file STRM akan berisi URL `localhost` yang tidak bisa dipakai dari perangkat lain. Gunakan IP Tailscale, IP LAN, atau domain yang sudah di-reverse-proxy. Contoh: `http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### Akun {#accounts}

Setiap entri di `providers` adalah satu akun. Boleh ada berapa pun yang berjalan bersamaan: Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link, dan Offcloud sekaligus, atau beberapa akun di layanan yang sama.

| Opsi | Tipe | Default | Keterangan |
|--------|------|---------|-------------|
| `type` | string | *(wajib)* | Backend yang dipakai akun ini: `realdebrid`, `torbox`, `alldebrid`, `premiumize`, `debridlink`, `offcloud`, `nzb`, atau `torbox_nzb` ([Usenet yang di-host TorBox](../providers/torbox-nzb.md)). |
| `name` | string | nilai dari `type` | Membedakan akun ini dari akun lain dengan tipe yang sama. Nama ini dipakai oleh filter `provider`, [direktori per akun](#per-account-directories), path cache, dan dashboard. Nama harus unik di antara entri, dan `e` dicadangkan untuk routing tautan STRM. |
| `token` | string | *(wajib)* | API token atau key akun. Dapatkan token Real-Debrid di http://real-debrid.com/?id=20475782, token TorBox di https://torbox.app/settings, dan token AllDebrid di https://alldebrid.com/apikeys?uid=1kk5i. Tidak dipakai oleh `nzb`, yang melakukan autentikasi lewat `nntp`. Token Real-Debrid juga bisa diberikan lewat environment variable `TOKEN` atau `RD_TOKEN` untuk membuat config otomatis saat pertama kali dijalankan. |
| `download_tokens` | list | `[]` | **Real-Debrid dan AllDebrid:** token API cadangan untuk layanan yang sama, dipakai saat jatah bandwidth token yang aktif sudah habis. Token ini memakai katalog entri ini, termasuk [katalog lokal](#local-debrid-catalogs), tanpa mengimpor library torrent dari akun tambahan. **TorBox:** diterima, tetapi rotasi tidak memetakan ulang ID torrent/file yang spesifik untuk akun; gunakan entri provider terpisah untuk akun yang berbeda. Tidak dipakai oleh NZB. Premiumize, Debrid-Link, dan Offcloud memerlukan entri akun terpisah karena file ID yang tersimpan milik akun tempat listing dibuat. |
| `strm_link_token` | string | `""` | Token API terpisah yang me-resolve permintaan baca yang masuk ke endpoint `/strm/`, sehingga saat player membuka `.strm`, token yang dipakai live mount untuk streaming tidak ikut terpakai. Jika tidak diatur, akan memakai `token`. **Real-Debrid dan AllDebrid**: dua backend yang merotasi kredensial, sehingga hanya di sini mengarahkan trafik `.strm` ke key tersendiri berarti sesuatu. Diterima tetapi tidak dipakai pada entri `torbox` dan `nzb`. Premiumize, Debrid-Link, dan Offcloud hanya menerima `token` milik akun itu sendiri di sini. |
| `disabled` | bool | `false` | Menyimpan akun di config tanpa memuatnya. Jika semua entri disabled, proses load akan gagal. |
| `watchlist` | bool | `false` | Menandai akun yang dicoba pertama kali untuk penambahan torrent baru. Ini mencakup endpoint download-client dan indexer Torznab dari acquisition. Paling banyak satu entri yang boleh mengatur ini, dan tidak pernah pada entri `nzb` atau `torbox_nzb`. Jika tidak ada yang diatur, akun pertama yang bisa menambahkan torrent akan dipakai. NZB dari acquisition dikirim ke backend Usenet dan tidak pernah ke akun ini. Lihat [Daftar pantau](#watchlist). |
| `add_torrents` | bool | `true` | Apakah akun ini diberi torrent baru sama sekali, yaitu yang diberikan ke endpoint download-client dan yang diambil acquisition dari indexer Torznab. Atur `false` untuk akun arsip, atau akun yang kuotanya sudah terpakai: akun tetap melayani dan membaca library-nya, tetapi tidak pernah diisi torrent baru. **Urutan daftar `providers:` adalah urutan percobaan untuk akun yang menerima penambahan**, jadi key ini dan urutan tersebut dibaca bersamaan; akun yang bertanda `watchlist: true` dicoba lebih dulu di mana pun posisinya. Tidak bisa dikombinasikan dengan `watchlist: true` pada entri yang sama, dan pada entri `nzb` key ini diabaikan dengan peringatan saat startup, karena news server tidak pernah diberi torrent. Lihat [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see). |
| `warm_connections` | int | `1` | Berapa koneksi yang tetap dibuka dan sudah di-handshake oleh akun ini **ke setiap host yang pernah dipakainya**, agar pembacaan tidak perlu membuka koneksi dulu. Maksimal 4. `-1` tidak menyimpan koneksi sama sekali. Diabaikan pada entri `nzb`, yang batas minimumnya per akun dan diatur di [`nntp.warm_connections`](../guides/usenet.md). Lihat [koneksi hangat](#warm-connections). |
| `nntp` | block | *(wajib untuk `nzb`)* | Kredensial news server. Wajib untuk tipe `nzb` dan diabaikan oleh tipe lain. |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

Pengaturan `download_tokens` milik TorBox tidak memberikan fallback pemutaran lintas-akun seperti yang diizinkan oleh locked link RD dan AD.
Resolver-nya mengganti API key sambil tetap menyimpan ID torrent/file dari sumber yang sudah ada. Entri provider TorBox yang terpisah
menjaga ID dan katalog tiap akun tetap independen. Untuk library lokal, letakkan manifest portabel di direktori sumber milik masing-masing entri.

#### Seeding TorBox {#torbox-seeding}

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `tb_seed_torrents` | string | `never` | Apakah torrent yang ditambahkan zurg ke akun TorBox akan di-seed. `never` mematikan seeding untuk setiap penambahan. `auto` menyerahkan pilihannya ke pengaturan seeding di akun TorBox kamu. `always` mengaktifkan seeding untuk setiap penambahan. Berlaku untuk setiap akun TorBox di config, dan untuk penambahan berikutnya begitu nilainya diubah. Nilai lain apa pun membuat zurg tidak bisa mulai. |

```yaml
tb_seed_torrents: never
```

Biarkan di `never` kecuali kamu memang butuh. Opsi ini ada untuk tracker privat yang menghitung rasio kamu. Rilis yang diambil lewat endpoint
[`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see)
sebagai file `.torrent` ditambahkan dengan pengaturan ini, jadi kalau pakai `always` (atau `auto` di akun yang diatur untuk seeding), TorBox akan mengunggahnya kembali ke swarm tracker. Mengimpornya ke Sonarr atau Radarr tidak mengubah hal itu: unduhan yang sudah selesai dan dihapus oleh client tetap tersimpan di akun.

**Torrent yang sedang di-seed menahan salah satu slot aktif paket kamu selama torrent itu masih di-seed.** TorBox menghitung torrent yang sedang di-seed sama seperti torrent yang sedang diunduh. Paketnya mengizinkan 3, 5, atau 10 sekaligus (Essential, Standard, Pro) dan seeding bisa berlangsung sampai 24 jam, 14 hari, atau 30 hari. Begitu semua slot dipakai torrent yang di-seed, grab dan repair baru di akun itu akan macet sampai ada slot yang kosong, baik karena waktu seeding torrent habis maupun karena kamu menghapusnya di TorBox. Seeding juga dihitung sebagai upload untuk batas penggunaan wajar (fair use) TorBox. Dengan `never`, semua ini tidak terjadi, makanya itu jadi default.

`auto` tidak mengirim preferensi seeding apa pun ke TorBox, jadi pengaturan seeding di akun kamu yang berlaku. Di akun yang pengaturannya belum pernah diubah, itu berarti Auto bawaan TorBox. `always` dan `never` menimpa pengaturan akun hanya untuk torrent yang ditambahkan zurg dan membiarkan yang lain di akun tidak berubah.

#### Akun Usenet {#usenet-accounts}

Tipe `nzb` adalah Usenet, bukan layanan debrid: file `.nzb` yang dimasukkan ke direktori `nzbs/` akan menjadi torrent di library, dan pembacaan dipenuhi dengan mengambil artikel dari news server Anda lalu men-decode-nya saat dibutuhkan. Hanya satu entri `nzb` yang aktif yang didukung, karena keduanya akan memindai direktori yang sama. News server tambahan ditaruh di `nntp.servers` milik entri tersebut, karena mereka melayani library yang sama, bukan salinan kedua darinya. Entri `nzb` di samping entri [`torbox_nzb`](../providers/torbox-nzb.md) juga ditolak dengan alasan yang sama. Jalankan jenis itu di instance sendiri, dengan direktori kerja sendiri.

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `host` | string | *(wajib)* | Nama host news server, misalnya `news.example.com`. |
| `port` | int | `563` dengan TLS, `119` tanpa TLS | Port news server. |
| `tls` | bool | `false` | Membungkus koneksi dengan TLS. |
| `username` | string | `""` | Username akun. |
| `password` | string | `""` | Password akun. |
| `connections` | int | `8` | Jumlah koneksi bersamaan yang diizinkan untuk akun. zurg membaca dengan jumlah ini. Satu koneksi hanya membawa sebagian kecil throughput paket, jadi streaming memakai seluruh jatah, bukan mengambil satu artikel sekaligus. Melebihi batas paket akan membuat koneksi ditolak, jadi isi dengan angka yang sebenarnya. |
| `pipeline_depth` | int | `4` | Berapa banyak artikel yang diminta zurg sekaligus pada satu koneksi. Batasnya 8. Atur ke `1` untuk server yang tidak bisa menangani beberapa perintah sekaligus. zurg akan turun ke 1 sendiri dengan peringatan jika batch terus terputus. |
| `socket_receive_buffer_kb` | int | tidak diatur | Mengunci receive buffer kernel tiap koneksi pada angka ini dalam KiB. Biarkan tidak diatur. Buffer yang dikunci berarti kernel berhenti menyesuaikannya. Di Linux, itu menjaga receive window tetap sekitar 64 KiB dan memangkas sebagian besar throughput akun pada jalur yang punya latensi. Opsi ini ada untuk kernel yang tidak pernah menyesuaikan atau yang batas atasnya diatur terlalu rendah. |
| `cache_size_mb` | int | `512` | Berapa banyak data artikel yang sudah di-decode disimpan di memori. Angka ini dibagi untuk semua file yang sedang dibaca, bukan per file. |
| `servers` | list | `[]` | Akun news tambahan sebagai cadangan, artikel per artikel. Lihat [lebih dari satu news server](#more-than-one-news-server). |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### Lebih dari satu news server {#more-than-one-news-server}

Retensi berlaku per provider: artikel yang sudah hilang di satu server sering kali masih ada di server lain. Tanpa akun kedua, satu-satunya cara memulihkan artikel yang mati adalah PAR2, dan itu berarti membaca **seluruh rilis**. Jadi server kedua membuat bedanya antara mengambil satu artikel dan membaca ulang semuanya.

Kunci di atas menjelaskan akun pertama. Apa pun di bawah `servers` adalah akun tambahan, yang hanya ditanyakan ketika akun sebelumnya tidak punya artikelnya. Konfigurasi satu server yang sudah ada tetap berjalan tanpa perubahan.

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `name` | string | nilai `host` | Memberi label pada akun di log. |
| `host`, `port`, `tls`, `username`, `password`, `connections`, `pipeline_depth`, `warm_connections`, `socket_receive_buffer_kb` | | | Sama seperti di atas. Setiap akun punya jatah koneksinya sendiri. Pipelining dan receive buffer diatur per akun karena toleransi terhadapnya bergantung pada server. |
| `priority` | int | `0` | Siapa yang ditanya lebih dulu, yang nilainya paling rendah lebih dulu. Akun dengan prioritas yang sama ditanya sesuai urutan penulisannya, kecuali akun yang masih punya koneksi bebas didahulukan daripada akun yang jatahnya sudah habis. Jadi dua akun yang sama akan berbagi beban. |
| `backup` | bool | `false` | Menandai block account, yang baru ditanyai setelah semua primary menjawab *no such article*. Primary yang **sibuk** belum cukup: zurg menunggunya, daripada menghabiskan byte berbayar (metered) untuk sesuatu yang bisa dilayani akun tak terbatas. |
| `backbone` | string | `""` | Spool artikel yang dituju akun ini. Dua akun di backbone yang sama menyimpan artikel yang sama, jadi begitu salah satunya menyatakan tidak punya suatu artikel, akun satunya dilewati alih-alih ditanya hal yang sama. |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Sensus yang memutuskan apakah sebuah rilis perlu diperbaiki akan menanyai setiap akun sebelum menyatakan artikel hilang. Dengan begitu, rilis yang punya lubang di satu provider tidak memicu pembangunan ulang PAR2 kalau provider lain masih bisa menyajikannya.

Kunci tingkat atas mengatur apa yang ditinggalkan perbaikan:

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `par2_patch_cache_mb` | int | `512` | Seberapa besar bagian `data/par2/` yang boleh dipakai oleh byte hasil rekonstruksi perbaikan PAR2. Byte ini satu-satunya hal yang tidak bisa diminta ulang dari server berita, karena artikel pembawanya sudah hilang. Jadi dengan menyimpannya, restart tidak memaksa pembacaan ulang seluruh rilis hanya untuk memulihkan beberapa megabyte yang sama. Hanya rentang artikel yang mati yang disimpan, yang besarnya satu digit megabyte per rilis rusak. Seluruh rilis dibuang, yang paling lama tidak dipakai dulu, saat anggaran terlampaui. Nilai negatif mematikan persistensi dan menjaga perbaikan tetap di memori selama proses berjalan. |

Dua kunci berikut mengatur berapa memori yang dipakai NZB yang sudah di-parse:

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `nzb_segments` | string | `mmap` di Linux/macOS/BSD, `resident` di Windows | Cara daftar artikel dari NZB yang sudah di-parse disimpan. **Perlu restart.** `mmap` menulis daftar ke `data/nzb-index/<id>.bin` dan memetakan file itu saat dibutuhkan, sehingga byte-nya ada di page cache, bukan di heap zurg. `reparse` melepaskannya setelah rilis stabil dan membaca ulang NZB dari disk saat pembacaan atau perbaikan membutuhkannya, tanpa memakan ruang disk sama sekali. `resident` menyimpan semuanya di memori selama proses berjalan: **perilaku sebelumnya**, dan yang dipakai setiap build sebelumnya. Nilai yang tidak dikenali memakai default dan disebut dalam peringatan saat startup. Mode yang benar-benar aktif selalu dicatat saat startup. |
| `nzb_segments_idle_secs` | int | `120` | Berapa lama daftar artikel sebuah rilis disimpan setelah pembacaan terakhir, pada mode lazy. **Perlu restart.** Sapuan berjalan setiap 30 detik, jadi 10 adalah jendela terpendek yang bisa dipenuhi dan batas minimum di Dashboard. Diabaikan saat `resident`, karena mode itu tidak pernah melepaskan apa pun. `0` memakai default. |

Pertukarannya perlu dijelaskan terang-terangan, karena ini bukan pertukaran memori-untuk-kecepatan yang biasa. Sebuah listing (refresh library, pengecekan fingerprint, atau *arr yang menanyakan apakah sebuah job sudah selesai) tidak pernah menyentuh artikel di mode apa pun. Nama file, ukuran, dan jumlah artikelnya dijawab langsung dari entri itu sendiri. Yang harus dibayar mode lazy adalah pembacaan *pertama* dari rilis yang tidak disentuh selama `nzb_segments_idle_secs`. Yang mereka hemat adalah heap yang ditempati daftar artikel di sisa waktu.

Diukur pada rilis 60 file, 30.000 segmen (Apple M3 Pro):

| | heap per rilis, sudah stabil | pembacaan pertama rilis yang menganggur | per artikel di jalur pembacaan |
|---|---|---|---|
| `resident` | 1.74 MB (58 B/segment) | — | 6 ns |
| `reparse` | 21.3 kB (0.71 B/segment) | 39 ms | 52 ns |
| `mmap` | 16.6 kB (0.55 B/segment) | 0.27 ms | 63 ns |

Dua pertiga waktu muat ulang `mmap` adalah checksum atas indeks yang baru saja dipetakan. Pemetaannya sendiri hanya 0.08 ms. Checksum itu sepadan: tanpa checksum, satu byte rusak di dalam arena akan disajikan sebagai message id yang tidak pernah diposting. Server berita menjawabnya sebagai artikel mati, dan setiap lapisan di atasnya membacanya sebagai kerusakan pada rilis.

Dan pada library sungguhan (2,636 NZB, 27.6 juta segmen, binary yang sama dijalankan tiga kali atas korpus yang sama, dalam keadaan menganggur setelah scan):

| | resident set | heap hidup | CPU saat menganggur | cold open, p50 | indeks di disk |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Open dalam kondisi hangat, throughput streaming, dan waktu startup tidak terlihat bedanya. `mmap` menjadi default di mana pun ada pemetaan sungguhan karena unggul di semua aspek kecuali disk. Itu termasuk cold open, karena memetakan arena yang sudah ditulis hanyalah satu syscall, sedangkan mem-parse NZB lagi berarti megabyte XML. Biayanya sekitar 55 byte disk per artikel dan satu penulisan tambahan per rilis saat scan. Indeks ditulis ulang setiap kali NZB berubah dan dihapus saat NZB dihapus. Pilih `reparse` di host yang `data/`-nya tidak boleh membesar. Di Windows tidak ada pemetaan. Indeks akan dibaca ke heap, yang berarti memori resident *ditambah* muat ulang. Jadi default di sana tetap `resident`, dan `reparse` adalah mode lazy yang layak dipilih.

## 2. Integrasi Media Server {#2-media-server-integration}

Hubungkan zurg ke media server Anda agar pembaruan library, pencocokan metadata, dan pemantauan watchlist berjalan otomatis.

### Premiumize, Debrid-Link dan Offcloud {#premiumize-debrid-link-and-offcloud}

```yaml
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY_OR_OAUTH_TOKEN
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_TOKEN
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
```

Backend ini mendukung penelusuran library, pembacaan streaming dan redirect, STRM, penambahan magnet, unggahan `.torrent`, dan penghapusan. Setiap akun juga muncul di direktori `__<name>__` sendiri. Tambahkan akun lewat dashboard atau `zurg setup`; setup tanpa pengawasan menerima `--premiumize-token-file`, `--debridlink-token-file` dan `--offcloud-token-file`, atau `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN` dan `OFFCLOUD_TOKEN`.

Premiumize memasang transfer yang sudah selesai dan file cloud yang tetap disimpan setelah daftar transfer dibersihkan. Folder bersarang tetap mempertahankan path-nya. Hash yang diberikan lewat zurg disimpan di `data/premiumize/<account>/sources.json` supaya pencocokan antar akun tetap berjalan saat restart atau saat transfer yang selesai dibersihkan. Konten cloud yang diimpor tanpa hash yang tercatat tetap bisa di-stream, tetapi tidak bisa diperbaiki dengan hash atau dicocokkan ke akun lain dengan hash. Menghapus transfer Premiumize lewat zurg juga menghapus file milik transfer tersebut. Kuota penyimpanan cloud dan fair-use tetap menjadi batas milik akun itu sendiri.

Debrid-Link menampilkan daftar seedbox dengan pagination dan mengurai setiap file berdasarkan ID-nya. Endpoint cache-nya yang sudah dihentikan tidak dipakai; penambahan khusus cached hanya bisa memastikan hit dari respons penambahan. Kegagalan karena kuota harian untuk penambahan dan trafik dilaporkan sebagai batas akun. Backend berhenti sementara setelah ditolak karena flood.

Offcloud mengurai file handle lewat endpoint cloud explore. Ukuran file dicek terhadap delivery server, dan metadata torrent yang di-cache memberikan path folder jika bisa dicocokkan dengan jelas. Daftar file yang ambigu dilaporkan sebagai error. Magnet yang format-nya salah ditolak sebelum dikirim.

URL delivery diperbarui saat cache-nya kedaluwarsa atau saat pembacaan membuatnya tidak valid. Jaga URL yang dihasilkan dan akses STRM tetap privat; kuota provider adalah milik akun yang mengirim byte-nya. Ketiga backend ini memakai satu kredensial per entri akun dan tidak berganti-ganti memakai file ID milik akun lain.

### Integrasi Plex {#plex-integration}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `plex_server_url` | string | `""` | URL server Plex Anda. Wajib untuk pencocokan Plex dan fitur watchlist. Contoh: `http://localhost:32400` |
| `plex_token` | string | `""` | Token autentikasi Plex Anda. Wajib diisi bersama `plex_server_url`. |
| `plex_scan_check_url` | string | nilai dari `plex_server_url` | Server Plex tempat zurg bertanya apakah pemindaian library sedang berjalan sebelum me-restart mount. Zurg akan menunggu selama pemindaian masih berjalan. Mount yang hilang di tengah pemindaian membuat Plex membuang semua yang tidak bisa dilihatnya. Atur ini pada instance yang tidak menjalankan integrasi Plex sendiri. Biasanya satu instance per provider. Mengatur `plex_server_url` di sana juga akan memulai pencocokan Plex. |
| `plex_scan_check_token` | string | nilai dari `plex_token` | Token untuk `plex_scan_check_url`. |
| `plex_match_every_mins` | int | `1440` | Seberapa sering (dalam menit) zurg memindai library Plex Anda untuk mencocokkan torrent dengan item Plex. Ini mengaktifkan fitur seperti menampilkan torrent mana yang sesuai dengan media Plex mana. Minimal 1; `0` memakai nilai default. Membutuhkan `mount_path` diatur. |
| `plex_watchlist_enabled` | bool | `false` | Nama lama dari `watchlist.enabled` (lihat [Watchlist](#watchlist)); tetap didukung. |
| `plex_watchlist_check_every_secs` | int | — | Nama lama dari `watchlist.check_every_secs`; tetap didukung jika blok tidak mengatur nilainya. |
| `watchlist_quality` | string | `"best"` | Nama lama dari `watchlist.quality`; tetap didukung jika blok tidak mengatur nilainya. |
| `plex_settings_policy` | string | `"guard"` | Seberapa jauh zurg boleh mengoreksi preferensi Plex yang penting untuk mount debrid. Salah satu dari `off` (jangan sentuh apa pun), `warn` (laporkan semua, jangan ubah apa pun), `guard` (perbaiki hanya pengaturan yang nilai salahnya membuat library hilang, laporkan sisanya) atau `enforce` (juga perbaiki pengaturan yang membuat Plex men-decode seluruh file untuk hasil yang tidak dilihat siapa pun). Apa pun yang punya fitur tampilan, seperti Skip Intro, Skip Credits, scrubbing preview, gambar chapter, penyamaan volume, atau analisis sonik, hanya dilaporkan. Lihat [Pengaturan Plex](../guides/plex.md#recommended-plex-settings). |
| `plex_settings_ignore` | list | — | ID preferensi Plex yang dibiarkan zurg tidak disentuh, apa pun kebijakannya, tanpa membedakan huruf besar dan kecil. Berlaku per pengaturan, bukan per tingkat, jadi menonaktifkan satu pengaturan tidak membuat pengaturan lain di sebelahnya ikut terlepas. ID yang tidak dikenali zurg akan dilaporkan saat startup dan tidak mengubah apa pun. Sakelar **Let Plex Empty Its Own Trash** di Dashboard menulis `autoEmptyTrash` ke daftar ini. Lihat [Menonaktifkan satu pengaturan](../guides/plex.md#opting-out-of-one-setting). |

> **Catatan:** Plex paling baik diatur lewat alur autentikasi Dashboard (web UI); alur ini menulis `plex_server_url` dan `plex_token` kembali ke `config.yml`. Kunci di atas tetap didukung untuk konfigurasi manual.

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### rex

zurg bisa mengisi [rex](../../rex/with-zurg.md), server media untuk aplikasi Plex resmi yang membaca setiap file dari zurg.

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `rex_url` | string | `""` | URL rex yang membangun librarynya dari zurg ini, misalnya `http://192.168.1.20:32400`. Saat memilih rex di Plex sign-in pada dashboard, nilai ini diatur ke alamat yang dipakai rex untuk mengambil sumber (alamat LAN atau Tailscale-nya, HTTP biasa), dan feed langsung jalan tanpa perlu restart; atur manual jika ingin mengisi rex tanpa sign in ke Plex. zurg lalu mengirim librarynya ke rex: setiap file video di direktori yang dikonfigurasi, setiap file audio di direktori yang diatur dengan `rex_music`, dan comic book di direktori yang diatur dengan `rex_photos`, beserta path, ukuran, id IMDb, dan detail media yang dibaca ffprobe. Pengiriman dilakukan setelah library selesai dimuat, setiap `rex_snapshot_every_hours`, dan setiap kali ada release yang ditambahkan, dianalisis, diganti namanya, dipindah, atau dihapus. rex tidak bisa memutar file sebelum ffprobe menganalisisnya, jadi mengatur `rex_url` akan menyalakan `auto_analyze_new_torrents` apa pun nilai key tersebut, dan menganalisis sisa library setelah selesai dimuat lalu setiap hari. Setiap probe membaca dari akun yang memiliki release, jadi jaga direktorinya tetap sempit, dan jangan pakai filter `tags_*` (dengan filter apa pun, setiap release di akun akan dianalisis) jika kamu tidak ingin library yang tidak pernah kamu tonton ikut menghabiskan traffic. Refresh juga mencari id IMDb setiap release baru lewat `dmm_api_key` sebelum menyimpannya (lihat `dmm_api_key` untuk cara release ditempatkan). Subtitle yang ditulis *arr atau Bazarr di samping video dalam `__magic__` ikut dikirim ke rex bersama videonya (lihat [`__magic__`](../guides/magic.md)). zurg memberi tahu rex tempat membaca file: WebDAV-nya di `http://<address>:<port>/dav`, dengan `username` dan `password` jika diatur. Address adalah `host` jika itu satu alamat; jika tidak, nilai default-nya adalah alamat yang dipakai koneksi zurg ke rex, dan rex harus bisa menjangkau zurg di sana. Di container, itu adalah alamat container itu sendiri, yang hanya bisa dijangkau rex dari mesin Linux yang sama: di Windows dan macOS, pasang zurg dengan installer, bukan di Docker Desktop, dan di Linux dengan rex di mesin lain, beri container zurg `network_mode: host` ([rex dengan zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex)). rex yang sedang mati akan dicoba ulang lalu dikirimi seluruh library; tidak ada yang menunggunya. Tidak ada scan Plex yang dikirim selama `plex_server_url` menunjuk ke rex yang sama ini. Setelah setiap snapshot dan setiap sepuluh menit, zurg membaca Fix Matches yang dibuat di rex untuk release-release-nya dan menyimpannya sebagai id yang diset manual untuk release tersebut, kecuali kamu sudah mengatur id lain di halaman manage sejak itu; DMM lalu menempatkan release berdasarkan id tersebut. Untuk memberi direktori library sendiri di rex, atur [`rex_shows`, `rex_movies`, `rex_music` atau `rex_photos`](#directory-options) padanya. Kosongkan `rex_url` jika kamu tidak menjalankan rex. |
| `rex_source` | string | `"zurg"` | Nama sumber yang dikenali rex untuk zurg ini. Beri setiap zurg yang mengisi rex yang sama nama sendiri. |
| `rex_snapshot_every_hours` | int | `6` | Seberapa sering seluruh library dikirim ulang ke rex, yang memperbaiki apa pun yang tertinggal karena pengiriman yang terlewat. Default-nya cocok untuk semua setup. |

```yaml
rex_url: "http://192.168.1.20:32400"
```

### Watchlist

Tambahkan sesuatu ke watchlist Plex kamu, dan zurg akan mengambilnya. Setiap item baru di watchlist dicari di indexer kamu. Indexer Newznab memberi NZB. NZB itu masuk ke backend Usenet persis seperti grab Sonarr atau pemutaran Stremio. Ketiganya memakai aturan penamaan yang sama, jadi mereka saling menemukan grab satu sama lain dan tidak mengunduh dobel. Indexer Torznab memberi torrent. Torrent hanya ditambahkan ke akun debrid jika akun itu sudah punya cache-nya. `prefer` menentukan jenis mana yang dicoba lebih dulu di antara rilis dengan resolusi yang sama. Film menjadi satu rilis. Serial diambil per musim, dan season pack didahulukan daripada episode lepasan. Musim yang tidak ada pack-nya akan kembali ke episode lepasan yang ditemukan pencarian, yaitu rilis terbaik untuk tiap episode. Item hanya keluar dari watchlist setelah rilis di baliknya dicek, dan hanya jika `remove_after_grab` mengizinkan. Kegagalan tetap ada di daftar. Item dicoba lagi setelah 5, 10, dan 15 menit, lalu setelah satu jam, lalu makin jarang. Judul yang gagal selama dua minggu akan diparkir sampai kamu melanjutkannya di halaman acquisition. Lihat [persistence and recovery](../guides/acquisition.md#persistence-and-recovery).

Kamu perlu `plex_token` dan minimal satu indexer. Tanpa daftar sendiri, monitor meminjam daftar milik addon Stremio. Monitor berbicara dengan layanan cloud Plex, jadi `plex_server_url` tidak wajib. NZB memerlukan provider `nzb` atau `torbox_nzb` di instance yang sama. Torrent memerlukan akun debrid yang menerimanya. Salah satu saja sudah cukup.

Setiap opsi di bawah ada di halaman config pada **Plex Watchlist**, termasuk daftar indexer. Dashboard menulis blok ini, bukan key flat lama. Mematikan monitor di sana juga menghapus `plex_watchlist_enabled`, karena key itu ikut digabung ke saklar.

| Opsi | Tipe | Default | Keterangan |
|--------|------|---------|-------------|
| `enabled` | bool | `false` | Menyalakan monitor. Key lama `plex_watchlist_enabled` tetap dihitung. |
| `check_every_secs` | int | `60` | Seberapa sering watchlist dicek di layanan cloud Plex. |
| `indexers` | list | `[]` | Indexer yang dicari, masing-masing dengan `name`, `url`, `api_key`, dan opsional `api_path` dan `type`. `type: torznab` menandai indexer torrent. Jika tidak ada, nilainya `newznab`. Bentuknya sama dengan `stremio.indexers`, yang dipinjam utuh saat daftar ini kosong. |
| `prefer` | string | `"usenet"` | Jenis mana yang dicoba lebih dulu saat NZB dan torrent dengan resolusi yang sama sama-sama bisa dipakai. Resolusi diputuskan lebih dulu, jadi torrent 2160p didahulukan sebelum NZB 1080p. `usenet` mencoba NZB lebih dulu, `torrents` mencoba torrent lebih dulu, dan `best` membiarkan ranking yang memutuskan. Lihat [Newznab and Torznab](../guides/acquisition.md#newznab-and-torznab). |
| `max_size_gb` | int | `0` | Rilis yang lebih besar dari ini dibuang untuk film dan episode tunggal, serta season pack yang berisi lebih dari ini per episode. `0` berarti tidak ada batas, jadi `best` bisa mengambil remux full-disc. Rilis yang ukurannya tidak disebutkan indexer tetap dipertahankan. |
| `max_season_size_gb` | int | `0` | Batas untuk tiap musim yang ada di season pack, per musim yang disebutkan. `0` berarti tidak ada batas: pack hanya dibatasi oleh `max_size_gb` per episode, jika itu diisi, sehingga remux dari musim panjang tetap dihitung. |
| `quality` | string | `"best"` | Rilis mana yang menang: `best` (resolusi dulu, lalu ukuran), `4k`, `1080p`, `720p` (mengutamakan resolusi itu, lalu kembali ke best), atau `smallest`. Key lama `watchlist_quality` tetap dihitung. Hanya satu nilai di sini. Hanya `acquisition.quality` yang menerima daftar (lihat [Acquisition sources](#acquisition-sources)). |

Blok `acquisition` juga menerima `concurrency` (default `8`, `1` sampai `200`), yaitu berapa banyak judul yang dicari, dicek, dan ditempatkan sekaligus. Ada juga `indexer_concurrency` (default `3`, `1` sampai `16`), yaitu berapa banyak panggilan ke satu indexer yang berjalan bersamaan. Pertahankan nilai yang terakhir ini tetap rendah jika kunci indexer dipakai bersama.

`exclude_words` tidak punya salinan di blok ini. Untuk menyaring kata seperti `DV` atau `HDR10+` dari grab watchlist, tambahkan blok `acquisition:` yang hanya berisi `exclude_words`. Semua pengaturan di atas tetap berlaku. Lihat [excluding releases by name](../guides/acquisition.md#excluding-releases-by-name).

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  quality: best
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: your-api-key
```

### Sumber akuisisi {#acquisition-sources}

`acquisition.sources` berisi daftar layanan yang diambil zurg, masing-masing di antrean bersama yang dijelaskan di [sumber akuisisi](../guides/acquisition.md). Pengaturan pencarian (`indexers`, `quality`, `prefer`, `max_size_gb`, `max_season_size_gb`) ada di samping `sources` dalam blok `acquisition:` dan kembali ke nilai di blok `watchlist:` di atasnya. Hanya `acquisition.quality` yang juga menerima daftar resolusi, misalnya `[1080p, 4k]`. zurg lalu menyimpan satu salinan tiap film di daftar DMM wanted untuk masing-masing resolusi. Serial di daftar itu dan sumber lainnya memakai resolusi tertinggi dalam daftar sebagai satu `quality`-nya. Lihat [satu salinan di tiap beberapa resolusi](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

`best_first` hanya ada di blok `acquisition:` dan defaultnya mati. Jika dinyalakan, pengambilan pertama dari sumber `radarr` atau `sonarr` akan mengikuti urutan preferensi quality profile. Resolusi terbaik yang diizinkan datang lebih dulu. Apa pun yang sama dengan atau di atas cutoff dihitung sebagai cutoff. Saat sebuah rilis gagal, zurg turun ke bawah profil. Jika dimatikan, film mengambil rilis yang diizinkan dan paling murah untuk dicek. Serial mengambil rilis yang diberi peringkat pertama oleh `quality`. Upgrade pass kemudian menuju cutoff. Rilis terbaik sering kali berupa set arsip besar, jadi file pertama biasanya tiba lebih lambat. Lihat [mengambil yang terbaik dari profil lebih dulu](../guides/acquisition.md#taking-the-profiles-best-first).

`exclude_words` (list, default kosong) juga ada di sana dan tidak punya fallback ke watchlist. Rilis yang namanya memuat salah satu kata ini tidak akan pernah diambil, dari sumber mana pun. Pencocokan berdasarkan kata utuh dan tidak peka huruf besar-kecil, jadi `DV` tidak menangkap `DVDRip`. `DV`, `DoVi` dan `Dolby Vision` dihitung sebagai satu kata, begitu juga `HDR10+` dan `HDR10Plus`. `HDR10` dan `HDR10+` adalah kata yang berbeda. Entri tanpa huruf atau angka akan ditolak saat startup. Aturan lengkapnya dan cara kombinasinya dengan profil Radarr dan Sonarr ada di [mengecualikan rilis berdasarkan nama](../guides/acquisition.md#excluding-releases-by-name).

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `name` | string | wajib | Huruf, angka, `_` dan `-`, harus unik. Dipakai sebagai nama antrean tersimpan milik sumber ini, jadi jaga agar tetap sama. |
| `type` | string | wajib | `plex_watchlist`, `seerr`, `radarr` atau `sonarr`. |
| `enabled` | bool | `false` | Sumber yang nonaktif tetap disimpan di file dan tidak di-poll. Sumber `radarr` atau `sonarr` yang nonaktif masih dibaca, hanya-baca, oleh [tampilan duplikat](../guides/acquisition.md#finding-duplicate-releases) di halaman manage. |
| `check_every_secs` | int | `60` | Seberapa sering sumber di-poll. |
| `url` | string | | `seerr`, `radarr` dan `sonarr`: URL dasar HTTP(S) layanan, tanpa kredensial, query, atau fragment. URL dasar serta `/api/v1` di akhir (Seerr) atau `/api/v3` (Radarr, Sonarr) juga diterima. |
| `api_key` | string | | `seerr`, `radarr` dan `sonarr`: API key layanan. Dikirim sebagai header, tidak pernah di URL, dan disembunyikan dari log serta config yang dibagikan. |
| `library_path` | string | `mount_path` + `/__magic__` | Khusus `radarr` dan `sonarr`: tempat \*arr melihat direktori `__magic__` milik zurg, misalnya `/data/zurg/__magic__` untuk container yang me-mount zurg di `/data/zurg`. Folder film atau serial di bawahnya ditempatkan di path relatif yang sama di dalam `__magic__`; folder di tempat lain dilewati. Harus absolut; path Windows seperti `Z:\__magic__` juga diterima. zurg juga membandingkannya dengan tempat \*arr melihat folder download dari download client zurg, dan melaporkan tata letak yang membuat impor menjadi salinan; lihat [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |
| `remove_after_grab` | bool | `true` | Khusus `plex_watchlist`; tidak berpengaruh untuk `seerr`, `radarr` dan `sonarr`. |
| `only_new_items` | bool | `true` | Khusus `plex_watchlist`; tidak berpengaruh untuk `seerr`, `radarr` dan `sonarr`, yang item wanted-nya selalu dikerjakan. |

```yaml
acquisition:
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /data/zurg/__magic__
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /data/zurg/__magic__
```

### Pemeliharaan Library Plex (hanya host yang sama) {#plex-library-maintenance-same-host-only}

Fitur-fitur ini harus berjalan di mesin yang sama dengan zurg, karena fitur ini membaca file database Plex secara langsung. `plex_server_url` sering kali menunjuk ke host atau container lain, dan tidak ada endpoint HTTP yang bisa memberikan file tersebut. Karena itu, fitur ini memakai path yang ditentukan secara eksplisit dan tetap nonaktif sampai kamu mengaturnya.

zurg hanya **membaca** database ini, lewat handle read-only. zurg tidak pernah menulis ke database dan tidak pernah menghentikan Plex. Satu-satunya file yang dibuat zurg adalah snapshot di folder `data/plex-backups/` milik zurg sendiri, bukan di folder Plex.

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `plex_database_path` | string | `""` | Path lengkap ke `com.plexapp.plugins.library.db`. Jika dikosongkan, semua fitur di bagian ini dimatikan. |
| `plex_sqlite_binary` | string | lokasi instalasi Plex: `/usr/lib/plexmediaserver/Plex SQLite` di Linux, `/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite` di macOS, `%ProgramFiles%\Plex\Plex Media Server\Plex SQLite.exe` di Windows | Plex punya build SQLite sendiri. `sqlite3` biasa bisa gagal membaca database ini, atau bahkan merusaknya. |
| `plex_backups_keep` | int | `5` | Jumlah snapshot yang disimpan. Setiap snapshot sebesar seluruh database. Jika diisi `0` secara eksplisit, zurg hanya mengamati dan tidak pernah membuat snapshot. |
| `plex_backups_every_mins` | int | `15` | Jeda minimum antar snapshot, supaya zurg yang crash berulang kali tidak menyalin database setiap kali restart. |
| `plex_trash_sweep_every_mins` | int | tidak diisi (lihat catatan) | Seberapa sering entri Plex yang file-nya sudah hilang dari mount dihapus. Jika tidak diisi, zurg yang memutuskan: penghapusan berjalan setiap 60 menit kalau tidak ada yang lain mengosongkan trash Plex, dan mundur kalau Plex masih mengosongkannya sendiri. Jika diisi `0` secara eksplisit, penghapusan oleh zurg dimatikan dan trash diserahkan kepadamu. Jika bernilai negatif, seluruh sweep dimatikan, termasuk bagian repair-nya. `0` **tidak** mengembalikan pengosongan trash ke Plex. Itu diatur lewat `plex_settings_ignore` dan sakelar **Let Plex Empty Its Own Trash** di dashboard. Lihat [Who empties the trash](../guides/plex.md#who-empties-the-trash). |
| `plex_trash_sweep_max_items` | int | `50` | Jumlah maksimum entri yang boleh dihapus dalam satu sweep. Jika melebihi batas ini, sweep dibatalkan tanpa menghapus apa pun. |
| `plex_trash_sweep_max_percent` | int | `10` | Batas yang sama, tetapi dalam persen dari isi trash, sehingga ikut menyesuaikan dengan ukuran library. |
| `plex_trash_sweep_min_age_days` | int | `14` | Berapa lama sebuah entri mempertahankan ikon trash merahnya sebelum sweep boleh menghapusnya. Ini menjadi cadangan untuk entri yang belum ada keputusannya dari zurg. Release yang diketahui zurg sudah mati permanen langsung dihapus tanpa menunggu, dan release yang masih dalam proses repair tetap dipertahankan berapa pun usianya. Jika diisi `0` secara eksplisit, entri langsung dihapus begitu pengaman lainnya terpenuhi. |

**Kenapa perlu snapshot?** Plex sebenarnya sudah membuat backup sendiri setiap malam. Masalahnya, bahaya datang saat mount terganggu ketika Plex sedang scan. Kondisi ini bisa mengosongkan library dalam hitungan detik. Backup malam hari bisa sudah berumur 24 jam pada saat itu, sedangkan snapshot yang dibuat tepat sebelum zurg menyentuh mount hanya berumur beberapa detik.

#### Yang tidak akan pernah dihapus oleh trash sweep {#what-the-trash-sweep-will-never-remove}

Sampah Plex bukan daftar hal yang boleh dihapus. Isinya cuma kandidat, dan sebagian besar di antaranya keliru:

- **Item yang masih punya file.** Plex menandai seluruh film sebagai terhapus saat satu versinya hilang, jadi item di sampah sering masih punya versi yang bisa diputar. Sweep justru membuang versi "hantu" itu, dan item keluar dari sampah dengan koleksi, artwork, status tontonan, dan `added_at` yang masih utuh. Jika perbaikan itu gagal karena alasan apa pun, item **dibiarkan saja**. Item tetap ada di perpustakaanmu dengan ikon sampahnya. Item itu tidak pernah dihapus.
- **Show atau season yang episodenya masih ada.** Item ini sama sekali tidak punya file, jadi tidak ada alasan dari mount untuk menghapusnya.
- **Item yang file-nya belum benar-benar dikonfirmasi hilang**, tepat sebelum dihapus.

Penghapusan dilakukan per item, bukan memakai `emptyTrash` bawaan Plex. `emptyTrash` berlaku untuk seluruh section dan akan ikut menghapus semua entri di atas, dan itulah hal yang tidak boleh dilakukan sweep.

#### zurg sudah tahu apakah file itu akan kembali {#zurg-already-knows-whether-it-is-coming-back}

Untuk setiap file yang hilang, pembersihan akan menanyakan status perbaikan milik zurg sendiri sebelum menggunakan timer:

| Keputusan zurg | Pembersihan |
|---|---|
| file masih terbaca (filter menyembunyikannya dari mount) | kembali ke jendela usia |
| rusak, dan perbaikan belum menyerah | **menyimpan entri**, berapa pun lama perbaikannya |
| rusak dengan alasan yang tidak bisa diperbaiki selamanya (infringing, invalid, not allowed, …) | **langsung menghapusnya** — menunggu tidak akan mengembalikannya |
| tidak ada keputusan — torrent sudah keluar sepenuhnya dari akun, atau path tidak dapat diselesaikan | kembali ke jendela usia |

Item dengan beberapa versi dinilai sebagai satu kesatuan: jika satu versi masih dalam perbaikan, seluruh entri disimpan, dan entri baru dianggap mati jika semua versinya mati. Pencarian yang gagal tidak pernah menjadi izin untuk menghapus. Apa pun yang tidak bisa dijamin zurg akan ditangani oleh jendela usia di bawah, persis seperti sebelumnya.

#### Ikon trash adalah status, jadi penghapusan menunggu {#the-trash-icon-is-a-status-so-removal-waits}

Plex punya tiga status, dan hanya status tengah yang terlihat sebagai masalah:

| State | Yang kamu lihat |
|---|---|
| Live | entri normal yang bisa diputar |
| **Trashed** | entri **masih ada di library kamu dan masih dihitung**, abu-abu dengan **ikon sampah merah**, dan tidak bisa diputar |
| Purged | tidak ada apa-apa, entri sudah hilang sepenuhnya dari Plex |

Ikon sampah adalah satu-satunya tanda bahwa konten hilang, dan jika entri dihapus permanen (purge), tanda itu ikut hilang. Item tidak lagi terlihat rusak, dan malah seolah-olah tidak pernah ada. Jadi entri yang tidak ada vonisnya dari zurg dibiarkan saja sampai ia membawa ikon itu selama `plex_trash_sweep_min_age_days`. Masa tunggu ini adalah kesempatanmu untuk melihatnya dan mengambil ulang. Yang masih rusak setelah itu berarti memang sampah yang layak dibersihkan.

Ini juga berfungsi sebagai lapisan pengaman ketiga di bawah batas (caps) dan mount probe. Masalah mount yang sifatnya sementara biasanya sudah selesai jauh sebelum masa tunggu berakhir.

Masa tunggu hanya berlaku untuk **penghapusan**. Perbaikan mengembalikan item yang bisa diputar ke library kamu, jadi perbaikan dilakukan pada sweep berikutnya tanpa menunggu. Menunggu hanya akan membuat item yang sebenarnya berfungsi tetap memakai ikon sampah tanpa alasan.

Tidak ada status ini yang menyentuh file. File sudah hilang dari mount sejak awal, dan itulah penyebab tombstone tadi. Tidak ada yang pernah dihapus dari akun debrid kamu.

#### Kapan ia menolak untuk berjalan {#when-it-refuses-to-run}

- zurg tidak mengelola rclone (`rclone_enabled: false`). Jadi zurg tidak bisa memastikan mount yang bukan miliknya, dan "file-nya hilang" tidak berarti apa-apa.
- rclone tidak berjalan, atau mount tidak bisa dibaca. Probe membuka dan membaca sebuah file, bukan memanggil `stat`, karena `stat` dijawab dari cache direktori rclone dan tetap berhasil jauh setelah pembacaan berhenti berfungsi.
- Plex sedang memindai. Pemindaian yang sedang berjalan masih menentukan apa yang hilang.
- Salah satu batas akan terlampaui. Ini yang paling penting: **mount yang kosong tetapi bisa dibaca lolos semua pemeriksaan lain**, dan membuat seluruh library terlihat terhapus. Jika melewati batas, penyapuan dibatalkan sepenuhnya, tidak ada yang dihapus, dan hal itu dicatat di log.

Snapshot diambil sebelum apa pun dihapus, dan jika snapshot gagal, penyapuan dibatalkan.

> **Mematikannya:** atur `plex_trash_sweep_every_mins: 0` (menghapus kuncinya tidak sama: zurg lalu memutuskan berdasarkan apakah Plex mengosongkan sampahnya sendiri). Mengubahnya memerlukan restart zurg. Itu hanya mematikan penghapusan oleh zurg. Untuk membuat Plex mengosongkan sampahnya sendiri lagi, gunakan sakelar **Let Plex Empty Its Own Trash** di dasbor, atau cantumkan `autoEmptyTrash` di `plex_settings_ignore`.

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

Itu lokasi tempat Linux package menyimpan database. Di macOS dan Windows, tulis path lengkapnya, karena zurg tidak memperluas `~` atau `%LOCALAPPDATA%`. `plex_sqlite_binary` sudah memakai lokasi default tempat Plex dipasang di setiap sistem.

| Plex di | `plex_database_path` |
|---|---|
| macOS | `/Users/you/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db` |
| Windows | `C:\Users\you\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db` |

Tulis path Windows di dalam tanda kutip tunggal di YAML agar backslash-nya tetap seperti yang ditulis.

> **Pengaturan Plex terkait, di luar zurg:** matikan **Settings → Library → Empty trash automatically after every scan** di Plex. Pengaturan ini aktif secara default di Plex dan tidak aman untuk mount zurg. Pemindaian yang bertemu mount yang sebentar tidak bisa dibaca akan menghapus library secara permanen, alih-alih menyimpannya di sampah tempat library itu bisa kembali bersama mount. zurg mematikannya sendiri di bawah kebijakan default `guard`, dan memberi tahu hal itu di dasbor dan di log. Jika file kamu berpindah antar folder library dan kamu membutuhkan pembersihan itu, sakelar **Let Plex Empty Its Own Trash** di halaman config akan mengembalikannya ke Plex dengan risiko kamu sendiri.

### Integrasi Lainnya {#other-integrations}

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `jellyfin_server_url` | string | `""` | URL server Jellyfin kamu. Mengaktifkan notifikasi refresh library saat zurg mendeteksi perubahan. Contoh: `http://localhost:8096` |
| `jellyfin_token` | string | `""` | Token API Jellyfin untuk autentikasi. |
| `emby_server_url` | string | `""` | URL server Emby kamu. Mengaktifkan notifikasi refresh library saat zurg mendeteksi perubahan. Contoh: `http://localhost:8096` |
| `emby_token` | string | `""` | Token API Emby untuk autentikasi. |
| `dmm_api_key` | string | `""` | API key DMM kamu. [gatekeeper](https://gatekeeper.debridmediamanager.com/) menampilkannya sekali setelah kamu jadi sponsor. DMM kemudian menempatkan file kamu dan mengisi daftar wanted kamu. |
| `dmm_metadata_secret` | string | `""` | Secret untuk API metadata internal DMM. Jika diisi, torrent tanpa IMDb id (atau hanya dengan penanda miss dari OpenSubtitles) akan diidentifikasi saat startup dari nama rilisnya lewat DMM, yang hanya menjawab jika tepat satu judul cocok. Torrent yang tidak bisa dinamai akan tetap memiliki id kosong, sehingga pencocok Plex tetap bisa mengisinya. |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. Pemutaran & Struktur File {#3-playback--file-structure}

Mengatur file apa saja yang dilihat media server Anda dan bagaimana konten di-stream.

### Mode Streaming {#streaming-mode}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | Jika true, pembacaan **mount** dijawab dengan redirect ke URL unduhan milik akun itu sendiri, bukan diteruskan lewat zurg. Ini mengurangi penggunaan CPU dan bandwidth zurg, tetapi klien harus bisa langsung menjangkau server akun tersebut. Diabaikan untuk backend yang tautannya disajikan secara lokal. File Usenet tidak punya URL untuk diberikan, jadi selalu diteruskan. **Baca risiko provider di bawah sebelum mengaktifkan.** |
| `serve_strm_files` | bool | `false` | Jika true, zurg menyajikan file `.strm` sebagai pengganti file video asli di mount WebDAV. Media server seperti Plex/Jellyfin membaca file `.strm` untuk mendapatkan URL streaming. **Penting:** Saat diaktifkan, file video asli disembunyikan dan digantikan oleh entri `.strm`. |
| `save_strm_files` | bool | `false` | Jika true, zurg menulis file `.strm` ke direktori `strm/` di samping binary zurg. Berguna untuk setup yang ingin file STRM tersimpan permanen di disk (misalnya, untuk impor manual ke media server). Menggunakan `base_url` untuk URL di dalam file. Hanya file yang bisa dibuka oleh player yang mendapat file `.strm`, yaitu video dan audio yang dikenali ditambah apa pun yang disebut `addl_playable_extensions`. Jadi subtitle, poster, NFO, dan volume PAR2 tidak ikut masuk ke folder, dan file apa pun yang ditulis build lama akan dihapus saat release itu dipindai ulang berikutnya. File `.strm` yang URL-nya sudah tidak cocok, karena `base_url` berubah atau ditulis build lama, akan ditulis ulang di tempatnya saat start berikutnya, atau langsung saat `base_url` diubah di dasbor. File yang sudah cocok tidak disentuh, sehingga media server tidak membaca ulang seluruh folder pada setiap pemindaian. |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

**Biarkan pembacaan mount tetap diteruskan (default) untuk pemutaran debrid bersama.** Real-Debrid melacak IP publik setiap pengunduh. Penggunaan satu akun dari banyak IP akan mendapat peringatan berbagi, meskipun unduhan berhasil. Pastikan semua penggunaan akun itu memakai satu IP publik, termasuk probe server dan konversi, bukan hanya unduhan dari player. URL unduhan TorBox berisi API key lengkap di `?token=`, jadi redirect memberi setiap klien dan akun pengguna bersama akses, termasuk penghapusan. Log player dan riwayat browser bisa menyimpannya. Jangan berikan tautan TorBox ke klien yang tidak tepercaya.

Risiko ini berlaku untuk redirect mount dengan `disable_stream_proxy: true` maupun redirect `/strm/`. Membiarkan `disable_stream_proxy: false` **tidak** membuat pemutaran `.strm` menjadi diteruskan atau aman untuk berbagi jarak jauh.

#### Apa yang dijangkau dan tidak dijangkau oleh `disable_stream_proxy` {#what-disable_stream_proxy-does-and-does-not-reach}

Ini mengatur mount. Ini tidak berlaku untuk endpoint `/strm/`, di backend mana pun:

| Pembacaan datang lewat | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| Mount, proxy aktif (default) | di-proxy lewat zurg | di-proxy |
| Mount, proxy nonaktif | `302` ke URL akun | di-proxy — tidak ada URL untuk di-redirect |
| File `.strm`, pengaturan yang mana pun | `307` ke URL akun | di-proxy |

File `.strm` dibuka oleh player yang tidak punya sesi dengan zurg, jadi endpoint hanya bisa memberikan URL yang bisa diambil sendiri oleh player. Menyalakan proxy tidak membuat lalu lintas itu lewat zurg lagi.

Yang perlu kamu tahu: pembacaan dari file `.strm` tidak mendapat penghitungan bandwidth, tidak ada failover di tengah stream ke akun lain, dan tidak ada deteksi link rusak, padahal semua itu didapat oleh pembacaan mount. Jadi library yang disajikan terutama lewat `.strm` hampir tidak merasakan efek `disable_stream_proxy`, baik nyala maupun mati.

`serve_strm_files` dan `disable_stream_proxy` itu terpisah, meskipun versi lama halaman ini bilang sebaliknya. File `.strm` disajikan sebagai teks sebelum keputusan streaming diambil, jadi keduanya bisa diaktifkan bersamaan. Tapi dengan `serve_strm_files` aktif, setiap pemutaran akan datang ke endpoint `/strm/`, yaitu baris di atas tempat `disable_stream_proxy` tidak berpengaruh apa-apa.

### Penyaringan & Deteksi File {#file-filtering--detection}

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `addl_playable_extensions` | list | `[]` | Ekstensi file yang harus dianggap zurg sebagai media yang bisa diputar, selain format video/audio bawaan. Titik, tanda kutip, dan huruf besar/kecil akan dirapikan oleh dashboard. Tambahkan ekstensi seperti `m3u` atau `cbz` kalau kamu ingin file tersebut terlihat dan bisa dipilih. |
| `force_select_playable_files` | bool | `false` | Kalau true, zurg otomatis memilih semua file yang bisa diputar di dalam torrent, meskipun file tersebut awalnya tidak dipilih. Bekerja untuk ekstensi video bawaan maupun `addl_playable_extensions`. Berguna kalau torrent punya file video yang belum dipilih tapi ingin kamu akses. |
| `delete_torrent_if_extensions_found` | list | `[]` | Kalau ada file dalam torrent yang punya salah satu ekstensi ini, seluruh torrent akan dihapus dari RD. Berguna untuk otomatis menghapus torrent yang berisi konten tidak diinginkan, seperti arsip `.rar` (bukan yang diekstrak oleh RD) atau file `.zipx`. |
| `stream_compressed_archives` | bool | `true` | Menyajikan file yang ada di dalam arsip terkompresi dengan cara mendekodekannya saat dibaca. Decoder menyimpan jendela terbatas di memori. Atur `false` untuk menolak arsip terkompresi seperti yang dilakukan build lama. |

Format bawaan yang bisa diputar adalah `.avi`, `.flv`, `.m2ts`, `.m4v`, `.mkv`, `.mov`, `.mp4`, `.mpg`, `.mpeg`, `.ts`, `.webm`, `.wmv`, `.mp3`, `.flac`, `.m4a`, dan `.m4b`.

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### Metadata & Penamaan {#metadata--naming}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-----------|
| `retain_folder_name_extension` | bool | `false` | **Sudah usang — akan dihapus.** Jika `true`, nama folder memakai `Name` akun apa adanya, termasuk ekstensinya, bukan `OriginalName` yang sudah dipotong akhiran `.mp4` lalu `.mkv`. Ini hanya berlaku jika `Name` mengandung `OriginalName` sebagai substring; di tempat lain, pemotongan tetap dilakukan. `retain_rd_torrent_name` dicek lebih dulu dan menutupi opsi ini sepenuhnya. |
| `retain_rd_torrent_name` | bool | `false` | **Sudah usang — akan dihapus.** Jika `true`, nama folder adalah `Name` akun (`filename` dari Real-Debrid); jika `false`, nama folder adalah `OriginalName` (`original_filename`), yaitu nama yang dideklarasikan oleh torrent itu sendiri. Ini penting untuk pack dengan satu file yang dipilih: Real-Debrid memangkas `filename` menjadi nama dasar file itu sendiri, sementara `original_filename` tetap nama pack. Jadi **`false` menghasilkan nama pack dan `true` menghasilkan nama file individual**. |
| `ignore_renames` | bool | `false` | Jika `true`, zurg mengabaikan metadata rename di torrent dan memakai nama file asli. Aktifkan ini jika file yang di-rename menyebabkan masalah pencocokan di media server kamu. Tidak usang. |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

Kedua flag usang ini membuat library dikunci berdasarkan `Name`, yang terus ditulis ulang oleh akun di bawah zurg; default-nya mengunci berdasarkan nama yang dideklarasikan torrent, yang tidak diubah oleh akun. Mengaktifkan salah satunya akan mencatat peringatan saat startup, dan pada instance yang melayani Sonarr atau Radarr (blok `sabnzbd:` atau `qbittorrent:`), default adalah satu-satunya nilai yang benar. Access key yang berpindah setelah impor akan membuat rilis hilang. Perilakunya tidak berubah di rilis ini: nama folder siapa pun tidak akan berpindah. `docs/naming.txt` adalah kumpulan lengkap aturan penamaan.

### Penulisan Mount {#mount-writes}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `dav_allow_rename` | bool | `true` | Jika false, WebDAV MOVE lewat mount akan ditolak dengan 403. Aktif secara default: mengganti nama torrent atau file adalah tujuan utama dari mount yang bisa ditulis, dan itu tidak menghapus apa pun. |

**WebDAV DELETE lewat mount selalu dijalankan — tidak ada key untuk itu.** Ini menghapus file dari library, dan merilis dari setiap akun debrid yang menyimpannya begitu tidak ada yang tersisa. Pahami dulu konsekuensinya sebelum mengarahkan penulis ke mount: rclone meng-flush file yang ditimpa sebagai DELETE lalu PUT, jadi apa pun yang menulis ulang file di tempat (penulis `.nfo`, proses trickplay, rename \*arr, atau `touch` yang nyasar) akan menghapus konten alih-alih menggantinya. Mount juga memakai kredensial rclone sendiri, jadi autentikasi tidak bisa membedakan keduanya. Hanya bagian PUT yang ditolak yang mencegah urutan ini selesai diam-diam. `mount_read_only: true` adalah yang benar-benar mencegah DELETE sampai ke zurg.

Penulisan yang ditolak dijawab dengan **403** dan mencatat config key yang bisa mengizinkannya, jadi klien yang penulisannya berhenti bekerja akan memberi tahu alasannya di `logs/zurg.log`.

Satu efek samping yang perlu diketahui: ketika sebuah program menulis lewat mount FUSE, cache VFS rclone menyimpan salinan yang sudah diubah dan mencoba ulang upload yang ditolak dengan jeda backoff. Mount menampilkan file yang sudah diubah secara lokal sampai entri cache itu dibuang, sementara file di sisi server tidak tersentuh sepanjang waktu itu. `mount_read_only: true` menghindari ini sepenuhnya dengan membuat penulisan gagal di kernel, sebelum rclone menyimpan apa pun ke cache.

```yaml
dav_allow_rename: true
```

Lihat juga `mount_read_only`, yang membuat kernel menolak penulisan sebelum sampai ke zurg.

### Cache daftar direktori {#directory-listing-cache}

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `disable_listing_cache` | bool | `false` | Saat true, setiap listing direktori dibuat ulang dari awal pada setiap permintaan. Biarkan mati: saat menyala, `PROPFIND Depth:1` pada `__all__` me-render ulang seluruh library setiap kali diminta — terukur 59 ms untuk 6,120 release, 121 ms untuk 2,636 release Usenet, 148 ms untuk `__magic__/__all__` — dan pemindaian media server meminta listing yang sama berulang-ulang. |

```yaml
disable_listing_cache: false
```

Cache menyimpan hasil render terakhir dari setiap direktori tingkat atas, satu untuk setiap varian mount (`/dav`, `/infuse`, `/http`), dan mengembalikannya sampai library berubah. Yang dihitung sebagai perubahan bukan tebakan: tepatnya kumpulan kejadian yang memang membuat rclone melupakan salinan cache-nya sendiri untuk listing yang sama — release ditambahkan, dihapus, diganti nama, dipindahkan, file rusak atau pulih — dan rclone menyimpan listing tersebut selama **dua belas jam**. Jadi listing yang disajikan dari sini tidak akan pernah lebih lama usianya daripada yang sudah disajikan mount, dan ada batas keras 60 detik di atasnya sebagai pengaman tambahan.

`__magic__/__all__` — mirror, dan satu-satunya listing di namespace yang layak di-cache, karena root di atasnya hanya berisi mirror dan beberapa baris — juga melacak tata letak yang tersimpan, sehingga impor \*arr hanya membatalkan listing itu dan membiarkan render direktori lain tetap utuh. Permintaan `__downloads__` dan `Depth: 0` sama sekali tidak di-cache.

Respons membawa header `X-Zurg-Listing: hit` atau `miss`, supaya instalasi yang sedang berjalan bisa diukur:

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`, direktori yang bisa kamu atur {#__magic__-a-directory-you-can-organise}

Setiap direktori lain adalah saved filter. Sebuah rilis ada di `movies` karena cocok dengan filter movies, jadi tidak ada tempat di library untuk *menaruh* sesuatu. `__magic__` adalah pengecualiannya: `__magic__/__all__` adalah salinan persis dari `__all__`, dan root di sebelahnya milikmu. Apa pun bisa dipindahkan keluar dari mirror ke mana saja di dalam namespace. Pemindahan menulis ulang satu baris di `data/magic.journal`, lalu dipadatkan ke `data/magic.json`. Tidak ada byte yang berpindah dan tidak ada torrent yang diganti namanya. Baris-baris itu memakai content hash rilis sebagai kuncinya, jadi repair yang membangun ulang rilis tidak akan menghilangkan lokasi tempat kamu menaruh sesuatu. Inilah yang membuat Radarr dan Sonarr bisa mengimpor dengan rename, bukan dengan copy.

Penjelasan lengkapnya, termasuk apa saja yang tetap bertahan setelah repair dan arti tiap penolakan, ada di [docs/magic.md](../guides/magic.md).

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `magic.enabled` | bool | `false` | Menyajikan `__magic__` sama sekali. Nonaktif secara default karena ini adalah tree yang bisa ditulis, dan \*arr yang mengarah ke root folder yang salah bisa mengatur ulang library. Jika belum ada yang dipindahkan, `__all__` miliknya persis sama dengan `__all__` library, dan root tidak berisi apa pun selain itu. |
| `magic.allow_delete` | bool | `false` | Jika true, DELETE terhadap **file** di bawah `__magic__` juga menghapus kontennya, seperti DELETE pada mount itu sendiri selalu lakukan. Jika nonaktif, delete hanya menyembunyikan: entri keluar dari `__magic__` dan tetap ada di `__all__` dan di setiap direktori filter. Folder rilis dan direktori tidak pernah menghapus konten, apa pun nilai pengaturan ini. Sonarr menghapus folder job setelah setiap impor. Menghapus video atau entri di dalam arsip juga menghapus seluruh rilisnya, selama tidak ada lagi yang di bawah `__magic__` memakai bagian mana pun darinya. |
| `magic.sidecar_max_mb` | int | `32` | File tunggal terbesar yang boleh di-`PUT` oleh klien ke `__magic__`. Jika melebihi batas ini, penulisan ditolak dengan **413**. |
| `magic.sidecar_budget_mb` | int | `2048` | Ukuran terbesar yang boleh dicapai seluruh tree sidecar. Jika melebihi batas ini, penulisan ditolak dengan **507 Insufficient Storage**. Status ini memberi tahu sesuatu yang tidak diberikan 413: menghapus sesuatu akan membuat permintaan yang sama berhasil. Total dihitung dengan menelusuri tree saat startup, jadi restart tidak mengembalikan kuota ke tree yang sudah penuh. Penghitungan juga diulang sebelum setiap penolakan. Tree ini adalah direktori `data/local` yang sama tempat mount milik zurg menulis, jadi file yang dihapus dari sana di belakang zurg tidak boleh terus dihitung. Nilai nol atau negatif memakai default; tidak ada cara untuk meminta tanpa batas. |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` tidak berlaku di sini, begitu juga jalur delete mount yang tidak dibatasi. Keduanya mengatur rute yang mengganti nama dan menghapus apa yang dimiliki akun debrid. Penulisan di bawah `__magic__` tidak menyentuh akun mana pun. `mount_read_only: true` tetap menimpa semuanya, di level kernel.

Ada dua hal yang perlu kamu tahu. Direktori filter sengaja tidak diubah, jadi rilis yang kamu pindahkan di dalam `__magic__` tetap ada di `recent` dan `movies` dengan nama aslinya. Arahkan media server ke `__magic__` **atau** ke filter, jangan ke keduanya. Lalu, apa pun yang benar-benar baru ditulis ke mount (`.nfo`, subtitle, poster) masuk ke `data/local` milik zurg sendiri dan digabung ke listing. Itulah sebabnya sidecar di sebelah rilis langsung bisa berfungsi.

#### File sidecar, dan untuk apa dua batas itu {#sidecar-files-and-what-the-two-caps-are-for}

Mount embed adalah union yang upstream pertamanya `data/local`, jadi saat sebuah program membuat file baru di mount, rclone menulisnya di sana dan zurg tidak pernah ditanya. Tidak ada yang membatasi pohon itu, kecuali [`union_writable: server`](#rclone-settings) membalik urutan union. Dalam kasus itu, create sampai ke zurg sebagai `PUT` dan ditolak di luar `__magic__`, dan dibatasi oleh dua batas di dalamnya.

Dengan urutan default, dua batas itu untuk klien jenis lain: klien yang memasang `/dav` secara langsung, tanpa union di depannya. Klien ini mengirim `PUT` ke zurg, dan zurg menulis body-nya ke `data/local/__magic__/<path>`, yaitu direktori yang sama dengan yang disajikan union. Jadi kedua tampilan menunjukkan satu direktori, bukan dua. Tanpa batas, ini bisa jadi penyimpanan file umum yang bisa diakses lewat WebDAV. Itulah alasan `sidecar_max_mb` dan `sidecar_budget_mb` ada, untuk mencegahnya.

Dua aturan mengikuti dari apa itu `__magic__`. Keduanya adalah penolakan yang mungkin dilihat klien:

- **Mirror adalah milik library.** `__magic__/__all__` dan folder rilis langsung di dalamnya dihitung otomatis, jadi `MOVE`, `MKCOL` atau `DELETE` yang ditujukan ke salah satunya akan mendapat **403**. Baris di sana akan jadi alamat kedua untuk rilis yang sudah punya alamat. Lebih dalam dari itu adalah folder milik rilis, dan menulis di sana sama biasanya seperti di tempat lain. Di sinilah \*arr menaruh `.nfo` di sebelah file yang sudah diimpornya.
- **Tidak ada yang dijawab library boleh ditimpa.** Folder rilis, entri di dalamnya, dan path tempat sebuah move meletakkan sesuatu, semuanya dirender dari library. Jadi `PUT` atau `MOVE` file asli ke salah satunya akan mendapat **403**. Ini termasuk nama di dalam folder rilis yang tidak dimiliki rilis itu. Listing folder itu milik rilis, jadi file yang ditaruh di antara entrinya tidak akan tampil di listing mana pun.
- **Penempatan tidak pernah menghancurkan file asli.** Memindahkan sesuatu yang dipegang library ke path yang sudah dipakai sidecar akan ditolak, bukan ditimpa, meskipun dengan `Overwrite: T`. Hal yang sama berlaku untuk direktori berisi file asli yang dipindah ke arah sebaliknya. Direktori itu tidak boleh di-rename ke path yang dijawab library, karena file-filenya nanti berada di folder yang hanya didaftar oleh rilis itu saja.

`DELETE` pada sidecar benar-benar menghapusnya. Ini satu-satunya tempat di `__magic__` di mana delete bukan tombstone. Tombstone menyembunyikan entri yang masih dipegang library di tempat lain, sedangkan byte sidecar hanya ada di `data/local` dan tidak di tempat lain.

#### Halaman `__magic__` {#the-__magic__-page}

Dasbor punya halaman sendiri untuk namespace ini, di `/magic/`. Halaman ini ditautkan dari quick links dashboard setiap kali `__magic__` dikonfigurasi atau disajikan. Di sinilah tabelnya bisa dilihat, dan ini satu-satunya tempat dua dari state-nya bisa diakses.

Halaman ini menampilkan berapa banyak baris yang tersimpan (placement, tombstone, dan directory, dihitung terpisah), berapa ruang yang dipakai journal dan snapshot di disk, berapa banyak dari `sidecar_budget_mb` yang dipakai oleh pohon sidecar, dan ukuran seluruh `data/local`. Angka terakhir inilah yang perlu kamu pantau. Client yang menyalin, bukan memindahkan, akan menaruh datanya di sana. Jadi kalau `data/local` sampai membengkak ke gigabyte, berarti ada yang mengimpor dengan cara yang keliru. Baris-barisnya dikelompokkan per release. Tabel yang sangat besar akan dipotong di halaman dan halaman akan memberi tahu berapa banyak yang dipotong. Angka-angka di atasnya selalu menghitung seluruh tabel.

Daftar stored rows hanya menampilkan seribu baris pertama. Setiap \*arr meninggalkan tombstone setiap kali melakukan import, jadi di library yang sudah rapi, sebagian besar baris ada di luar seribu pertama itu. Kotak pencarian di halaman stored rows dan dangling pages bisa mencari satu release berdasarkan nama, path di mount, atau hash-nya. Hasilnya menampilkan semua baris yang tersimpan tentang release itu beserta tombolnya. `data/magic.json` bukan jalan pintas untuk itu. zurg menulis file tersebut dari memori saat berhenti, jadi baris yang kamu hapus dari file itu secara manual selagi zurg berjalan akan muncul lagi.

Ada tiga tombol, dan ketiganya menjalankan satu operasi yang sama: sebuah baris berhenti ada.

- **Reset** sebuah placement, dan file atau folder kembali ke tempat yang ditentukan library.
- **Unhide** sebuah tombstone, dan entri tersebut muncul lagi di `__magic__`. Tidak ada yang dihancurkan untuk menyembunyikannya. Release di `__all__` yang tidak pernah muncul di `__magic__/__all__`, bahkan setelah dihapus lalu ditambahkan lagi, punya release tombstone: barisnya dikunci berdasarkan hash-nya, dan hash itu tidak berubah saat release ditambahkan ulang. Cari release tersebut dan unhide baris itu.
- **Delete** sebuah baris **dangling**, yaitu baris yang release-nya, atau file di dalam release-nya, sudah tidak ada lagi di library. Baris seperti ini tidak mengarah ke mana pun, jadi tidak bisa di-list, dipindahkan, atau dihapus lewat mount. Baris ini sengaja disimpan, bukan dibuang, karena repair yang mengembalikan release juga akan mengembalikan tempat yang sudah kamu tentukan. Sebelum halaman ini ada, tidak ada cara untuk membersihkannya. **Clear all dangling rows** menyapu semuanya sekaligus.

Sidecar juga ditampilkan, dan yang **nothing accounts for any more** dipisahkan dari yang lain dan dihitung tersendiri. Ini setara dengan dangling row untuk sidecar: `.nfo` atau poster yang ditulis di samping release yang sudah keluar dari library, atau di dalam folder yang placement-nya sudah dilupakan. Sidecar seperti ini tetap disajikan. File asli adalah hal terakhir yang diresolve oleh path `__magic__`, dan tidak ada yang di atasnya yang masih mengklaim nama itu. Jadi yang hilang hanyalah alasan file itu ditaruh di sana. zurg tidak pernah membersihkan sidecar sendiri. File yang tertinggal di samping release yang sudah dihapus tetap milikmu, dan repair yang mengembalikan release itu akan mengaitkan folder tersebut lagi. Direktori yang kamu buat sendiri untuk sidecar lewat mount, bukan lewat zurg, juga ditampilkan dengan cara yang sama di sini, karena direktori itu juga tidak meninggalkan baris apa pun.

Menghapus sidecar dari halaman ini benar-benar menghapus file-nya, sama seperti `DELETE` lewat mount. Setiap tombol mengubah cache mount untuk path yang terlibat, karena mount menyimpan daftar direktori selama dua belas jam dengan polling dimatikan.

Jika endpoint SABnzbd aktif, halaman ini juga menampilkan job yang sudah diserahkan kepadanya: id yang dikenal client untuk tiap job, kategorinya, apakah release-nya sudah sampai di library, dan folder untuk diimpor setelah itu. Sonarr dan Radarr menghapus job mereka sendiri. Job berstatus Failed atau Stuck yang tidak akan pernah dihapus oleh mereka bisa dibersihkan dari halaman ini. Itu terjadi ketika zurg sudah bukan download client mereka. Lihat [sabnzbd.md](../guides/sonarr-radarr.md).

Blok `magic:` dan `sabnzbd:` bisa diedit penuh dari [halaman konfigurasi](#sabnzbd-the-download-client-sonarr-and-radarr-see), dan keduanya menampilkan **Restart Required**, yang memang berarti harfiah: route yang melayani `__magic__` dan endpoint SABnzbd didaftarkan sekali saat startup, dari nilai-nilai ini. Mengaktifkan salah satunya akan menulisnya ke `config.yml` tetapi tidak mengubah apa pun pada run yang sedang berjalan. Halaman `__magic__` juga memberi tahu hal ini, alih-alih menampilkan namespace yang kosong.

### `sabnzbd`, download client yang dilihat Sonarr dan Radarr {#sabnzbd-the-download-client-sonarr-and-radarr-see}

zurg bisa merespons Sonarr dan Radarr seolah-olah dia adalah SABnzbd. Mereka mengirimkan NZB ke zurg, zurg menulis file-nya ke `nzbs/` untuk backend Usenet, dan begitu rilisnya sudah ada di library, job akan melaporkan **Completed** dengan folder job di bawah `__magic__/__all__` untuk diimpor. Tidak ada yang diunduh untuk diimpor: \*arr hanya mengganti nama file di dalam mount, yang berupa satu baris di tabel `__magic__`.

Fitur ini butuh kedua bagiannya agar berguna: provider `nzb` atau `torbox_nzb` untuk menerima NZB, dan `magic.enabled` agar ada tempat untuk mengimpor. Fitur ini nonaktif sampai kamu mengaktifkannya. Panduan setup lengkap, termasuk apa yang perlu dimasukkan di \*arr, ada di [docs/sabnzbd.md](../guides/sonarr-radarr.md).

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `sabnzbd.enabled` | bool | `false` | Daftarkan endpoint di `/api` dan `/sabnzbd/api`. Saat nonaktif, kedua rute ini tidak ada. |
| `sabnzbd.api_key` | string | dibuat otomatis | Satu-satunya penjaga endpoint ini. Sonarr dan Radarr tidak mengirim basic auth, jadi rute ini berada di luar autentikasi tersebut dan key inilah yang menggantikannya. Jika dibiarkan kosong saat blok diaktifkan, zurg akan membuatkan satu, menyimpannya di `data/sabnzbd-apikey` agar tetap ada setelah restart, dan mencatatnya sekali saat startup. |
| `sabnzbd.categories` | list | `[tv, movies]` | Kategori yang dilaporkan ke klien. Semuanya mengarah ke direktori yang sama, jadi opsi ini hanya ada agar klien tidak memberi peringatan tentang kategori yang tidak ditemukan. Tambahkan apa pun yang sudah kamu atur di \*arr. `*` selalu ikut dilaporkan. |
| `sabnzbd.history_limit` | int | `60` | Berapa banyak entri riwayat yang dibaca Sonarr dan Radarr. zurg menahan job yang sudah selesai melewati batas ini di antrean sampai ada slot yang kosong, yaitu saat klien menghapus satu entri atau saat satu entri sudah sepuluh menit tidak dihapus sementara ada job yang menunggu. Samakan dengan `DownloadClientHistoryLimit` di klien jika kamu menaikkannya. `0` membuat mereka memakai default 60. |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__/__all__` | Direktori selesai yang dilaporkan ke klien. Ini harus berupa path yang **dilihat \*arr**, yang berbeda dari path zurg sendiri jika \*arr berjalan di container yang me-mount library di lokasi lain. Path ini juga harus berada di volume yang sama dengan root folder, atau setiap impor akan menjadi salinan. Lihat [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

Key API adalah satu-satunya autentikasi, jadi perlakukan endpoint ini seperti kamu memperlakukan port zurg yang lain: di jaringan tepercaya, atau di belakang sesuatu yang memang tepercaya. Basic auth tidak bisa dipakai untuk ini. Klien tidak pernah mengirimkannya, dan respons 401 akan dilaporkan ke pengguna sebagai "unable to connect", bukan sebagai kegagalan autentikasi.

### `qbittorrent`, download client torrent yang dilihat Sonarr dan Radarr {#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see}

zurg bisa menjawab Sonarr dan Radarr seolah-olah dia qBittorrent. Mereka memberikan magnet atau `.torrent`, dan zurg menambahkan info hash ke akun debrid. Setelah rilisnya masuk ke library, torrent melaporkan **finished** dengan folder di bawah `__magic__/__all__` untuk diimpor. Tidak ada yang perlu diunduh untuk diimpor. \*arr mengganti nama file di dalam mount, dan itu jadi satu baris di tabel `__magic__`.

Ada dua bagian yang membuat ini berguna. Akun yang bisa menambahkan torrent akan membaca magnet, dan `magic.enabled` memberi \*arr tempat untuk mengimpor. Fitur ini mati sampai kamu menyalakannya. Setup lengkap, termasuk apa yang harus diisi di \*arr, ada di [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md).

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `qbittorrent.enabled` | bool | `false` | Mendaftarkan endpoint di `/api/v2` dan `/qbittorrent/api/v2`. Selama ini mati, kedua route itu tidak ada. |
| `qbittorrent.api_key` | string | dibuat otomatis | Satu-satunya gerbang untuk endpoint ini. Klien mengirimkannya sebagai bearer token saat field **API Key** mereka diisi, dan menerimanya sebagai password di `auth/login` saat field itu kosong. Jika dibiarkan kosong dengan blok ini aktif, zurg akan membuatnya sendiri, menyimpannya di `data/qbittorrent-apikey` agar tetap ada setelah restart, dan mencatatnya sekali saat startup. |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | Kategori yang dilaporkan ke klien, yaitu dua kategori yang memang disediakan \*arr. Semuanya mengarah ke direktori yang sama, jadi opsi ini hanya ada supaya klien tidak memberi peringatan tentang kategori yang tidak bisa dia temukan. |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__/__all__` | Save path yang dilaporkan ke klien, dan induk dari setiap folder yang mereka impor. Path ini harus path yang **dilihat \*arr**, yang tidak selalu sama dengan path zurg kalau \*arr berjalan di container yang me-mount library di tempat lain. Path ini harus berada di volume yang sama dengan root folder, kalau tidak setiap impor akan jadi copy; lihat [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). Set `sabnzbd.complete_dir` ke nilai yang sama jika kamu menjalankan kedua endpoint. |
| `qbittorrent.download_timeout_mins` | int | `15` | Berapa lama sebuah grab boleh berjalan tanpa pergerakan, yaitu tidak ada perubahan stage dan tidak ada kenaikan progress, sebelum akun itu ditinggalkan dan akun berikutnya yang menerima torrent dicoba. `0` berarti cached-only: grab hanya diterima jika akun itu sudah punya kontennya, dan ditolak di dalam add jika tidak, dan penolakan inilah satu-satunya yang ditindaklanjuti Sonarr dan Radarr. Angka negatif tidak pernah menyerah. Lihat [Timeouts and cached-only mode](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode). |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

Lima belas menit adalah angka hasil pengukuran, bukan pilihan asal. AllDebrid menaruh job yang sehat di antrean sendiri dengan semua counter di nol sebelum memindahkan satu byte pun. Dua dari dua percobaan diam di sana selama 580 dan 622 detik. Rekamannya ada di [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md).

Akun mana yang dipakai untuk sebuah grab ditentukan oleh [`add_torrents`](#accounts) dan urutan daftar `providers:`. Grab yang timeout, atau yang ditinggalkan oleh sebuah akun, akan dihapus dari akun itu sebelum yang berikutnya dicoba. Hanya instance yang ditambahkan zurg sendiri untuk grab itu dan belum pernah selesai yang bisa jadi kandidat. Tidak ada hal lain yang dijawab endpoint ini yang menghapus apa pun dari akun debrid.

API key adalah seluruh autentikasinya. Perlakukan endpoint ini seperti port zurg yang lain. Taruh di jaringan tepercaya, atau di belakang sesuatu yang tepercaya. Basic auth tidak bisa dipakai untuk ini. Klien tidak pernah mengirimkannya, dan mereka menganggap 401 sebagai kegagalan autentikasi yang fatal dan tidak pernah dicoba ulang.

### Addon `stremio` {#the-stremio-addon}

zurg bisa jadi addon Stremio yang mencari di indexer Newznab milikmu sendiri dan memutar lewat backend Usenet. Kamu butuh akun NZB, `nzb` atau [`torbox_nzb`](../providers/torbox-nzb.md), dan minimal satu indexer. Dengan `torbox_nzb`, rilis yang sudah ada di TorBox akan mulai dalam waktu tunggu addon, asalkan tidak ada post NZB lain yang sedang antre. Rilis yang belum ada di cache harus selesai diproses di TorBox dulu, dan itu lebih lama daripada waktu tunggu player. Fitur ini mati sampai kamu menyalakannya. Cara setup dan apa yang terjadi saat memutar ada di [stremio.md](../guides/stremio.md).

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `stremio.enabled` | bool | `false` | Mendaftarkan rute addon di `/stremio/`. Saat mati, rute ini membalas 404. |
| `stremio.token` | string | dibuat otomatis | Segmen path yang menjaga setiap rute addon. Ini satu-satunya otorisasi. Jika dibiarkan kosong, zurg membuatnya sendiri dan menyimpannya di `data/stremio-token`. |
| `stremio.indexers` | list | `[]` | Endpoint Newznab yang akan dicari. Setiap entri punya `name`, `url`, `api_key`, dan `api_path` opsional. |
| `stremio.max_results` | int | `10` | Berapa banyak rilis per resolusi yang disimpan setelah diranking. Batasnya berlaku per resolusi. Tiap tier menyimpan sebaran dari rilis terbesar sampai yang terkecil. `0` memakai default. |
| `stremio.search_limit` | int | `100` | Berapa banyak rilis yang diminta dari tiap indexer per pencarian. Semua batas lain memilih dari hasil yang diminta ini, jadi ini adalah batas atas untuk seluruh jawaban. `0` memakai default. |
| `stremio.max_size_gb` | int | `0` | Membuang rilis yang lebih besar dari nilai ini sebelum diranking, untuk player yang tidak bisa memutar remux. `0`, yang menjadi default, tidak membuang apa pun. Rilis tanpa ukuran yang tercantum tetap disimpan. |
| `stremio.cache_hours` | int | `24` | Berapa lama jawaban lengkap berisi lima hasil atau lebih disajikan dari `data/stremio-cache` sebelum indexer ditanya lagi. Jawaban yang lebih sedikit disimpan lebih singkat. Jawaban kosong tidak pernah disimpan. `0` memakai default. |

### Analisis Media {#media-analysis}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | Saat true, zurg otomatis menjalankan ffprobe pada setiap torrent baru yang ditambahkan untuk mengambil metadata media (resolusi, codec, durasi, track audio/subtitle). Metadata ini dipakai oleh filter direktori berbasis tag seperti `zurg_4k`, `zurg_aud_eng`, dan tingkat durasi. Nonaktifkan jika kamu tidak memakai filter berbasis tag atau ingin mengurangi penggunaan CPU saat menambahkan torrent baru. |
| `ffprobe_binary` | string | `"ffprobe"` | Path ke file executable ffprobe. Hanya perlu jika ffprobe tidak ada di PATH sistem kamu. Dipakai untuk analisis media. |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. Kesehatan & Perbaikan (Otomatisasi) {#4-health--repairs-automation}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `enable_repair` | bool | `true` | Mengaktifkan perbaikan torrent otomatis. Jika tidak diatur, berarti aktif. Saat torrent menjadi tidak tersedia (misalnya dihapus dari cache RD), zurg akan mencoba mencari dan menambahkan pengganti. Di AllDebrid, zurg juga memulai ulang magnet yang gagal karena alasan yang bisa diperbaiki dengan percobaan kedua, seperti `no peers` atau `tracker error`, alih-alih membiarkannya gagal. **Penting:** Hanya satu instance zurg yang boleh mengaktifkan repair agar tidak terjadi konflik. Jika opsi ini dan `delete_error_torrents` sama-sama nonaktif, zurg membiarkan torrent yang gagal di akun persis seperti apa adanya dan hanya mencatatnya di log. |
| `repair_every_mins` | int | `60` | Seberapa sering (dalam menit) zurg memindai torrent yang rusak dan perlu diperbaiki. Nilai yang lebih kecil membuat masalah terdeteksi lebih cepat, tapi penggunaan API jadi lebih banyak. |
| `repair_timeout_mins` | int | `30` | Waktu maksimum (dalam menit) zurg menunggu operasi perbaikan selesai. Jika perbaikan lebih lama dari ini, torrent ditandai rusak dan dilewati sampai siklus perbaikan berikutnya. |
| `stalled_download_mins` | int | `10` | Jumlah menit minimum sebelum torrent yang sedang diunduh dianggap macet. Ambang batas sebenarnya adalah `max(GB_downloaded, stalled_download_mins)`, jadi unduhan besar otomatis mendapat waktu lebih lama. Tambah nilai ini untuk torrent yang lambat atau sedikit seeder (misalnya tracker publik) yang butuh waktu lebih lama untuk selesai. |
| `restrict_repair_to_cached` | bool | `false` | Jika true, zurg hanya memakai torrent yang sudah ada di cache Real-Debrid untuk perbaikan. Artinya perbaikan lebih cepat (tidak perlu menunggu unduhan), tapi bisa gagal jika tidak ada alternatif yang sudah di-cache. Jika false, zurg bisa menambahkan torrent yang belum di-cache dan butuh waktu untuk diunduh. |
| `only_full_torrent_repair` | bool | `false` | Jika true, perbaikan memasukkan ulang seluruh torrent dengan pilihan file aslinya, atau menyerah. Jika langkah pertama ini gagal, torrent langsung ditandai rusak dan melewati strategi arsip serta per-file yang seharusnya dijalankan setelahnya. |
| `check_for_changes_every_secs` | int | `15` | Seberapa sering (dalam detik) zurg mengecek Real-Debrid untuk mendeteksi perubahan library (torrent baru, torrent yang dihapus, perubahan status). Nilai yang lebih kecil berarti media server kamu diperbarui lebih cepat, tapi panggilan API lebih banyak. |
| `library_resync_every_mins` | int | `10` | Seberapa sering pengecekan perubahan dibangun ulang dari daftar lengkap, bukan dari probe ringan. Ini adalah jaring pengaman yang menangkap drift yang mungkin terlewat oleh probe. Ini bukan seberapa sering zurg melakukan polling. Real-Debrid mengambil jalurnya sendiri dan mengabaikan opsi ini. |
| `library_detail` | string | `resident` | `resident` menyimpan detail file di memori. `lazy` melepas detail yang idle. `auto` hanya melepas detail yang idle saat tekanan memori berlangsung terus-menerus. Semua provider memakai kebijakan ini untuk seluruh instance. Perlu restart. Lihat [Detail library](#library-detail). |
| `library_detail_idle_secs` | int | `300` | Waktu minimum tanpa pembacaan detail sebelum `lazy` atau `auto` boleh melepas sebuah tabel. Penyapuan berjalan setiap 30 detik. Diabaikan oleh `resident`; nilai nol atau tidak valid memakai 300. Perlu restart. |
| `downloads_every_mins` | int | `720` | Seberapa sering (dalam menit) zurg mengambil ulang unduhan RD kamu (tautan unrestricted, tautan file locker) dan me-mount-nya. Ini adalah unduhan non-torrent dari RD. |
| `delete_error_torrents` | bool | `false` | Jika true, zurg otomatis menghapus torrent dari RD yang berada dalam status error (misalnya torrent mati yang tidak bisa diunduh). Ini menjaga library RD kamu tetap bersih, tapi torrent dihapus permanen. Di AllDebrid, magnet yang gagal dan bisa diperbaiki dengan percobaan kedua akan dimulai ulang alih-alih dihapus, bahkan saat repair nonaktif, dan baru dihapus jika memulai ulang tidak membantu. |
| `on_library_update` | string | `""` | Perintah shell yang dijalankan setiap kali zurg mendeteksi perubahan library. Setiap path direktori yang berubah diteruskan sebagai argumen. Biasanya dipakai untuk memicu pemindaian library Plex/Jellyfin pada folder tertentu agar update lebih cepat. |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
library_detail: resident
library_detail_idle_secs: 300
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

### Memperbaiki lintas akun {#repairing-across-accounts}

Setiap strategi repair lain menambahkan kembali sebuah release ke akun asalnya, dan itu bentuk yang tepat selama akun tersebut masih bisa menyediakan kontennya. Bentuk itu salah untuk satu kasus.

Layanan-layanan ini punya cache yang terpisah-pisah. Sebuah release yang sudah dihapus Real-Debrid, atau yang ditolak hanya karena nama filenya, bisa saja masih ada di cache AllDebrid sekarang, dengan info hash yang sama. Release-nya tidak rusak. Yang bermasalah hanya akunnya.

Jadi ketika sebuah release sudah ditolak oleh setiap akun yang memilikinya, zurg menawarkannya ke akun-akun yang sudah kamu konfigurasi tapi belum punya release itu, sesuai urutan kemunculannya di blok `providers`. Akun pertama yang ternyata sudah punya release itu akan mengambilnya, zurg lalu mendaftarkan akun tersebut, dan release itu mendapat salinan kedua seperti release multi-akun pada umumnya: punya file id dan link sendiri, serta failover baca antara kedua akun. Status verdict pada entri akan hilang dengan sendirinya begitu ada salinan yang bisa diperbaiki.

Tidak ada setting untuk ini. Menambahkan akun kedua sudah merupakan keputusannya. zurg sudah mendaftarkan akun itu, menyajikan konten darinya, dan mengalihkan pembacaan ke sana saat gagal. Menanyakan akun itu soal release yang tidak bisa diproduksi akun pertama juga bagian dari pengaturan yang sama. Fitur ini mengikuti `enable_repair` seperti repair lainnya.

Tombol repair pada sebuah release juga melakukan ini, dengan urutan yang benar: pertama mencoba ulang di akun yang memegang release itu, persis seperti sebelumnya, dan baru menawarkan release itu ke akun lain kalau percobaan tersebut gagal. Ini satu-satunya jalur yang tetap jalan walaupun sweep repair dimatikan sepenuhnya.

Yang mencegah ini menjadi loop penambahan adalah bentuk penawarannya, bukan sebuah saklar:

- **Sebuah akun hanya pernah diberi konten yang sudah dimilikinya.** Penawaran berupa add yang akan ditarik dan dihapus lagi kecuali akun itu menyelesaikannya dalam lima belas detik. Akun yang harus mengambil release dari swarm dibiarkan persis seperti saat ditemukan, tanpa memakai kuota transfer sedikit pun. Ini repair, bukan download ulang. `restrict_repair_to_cached` tidak mengontrol ini dan tidak pernah dibaca di sini: key itu mengatur repair akun atas salinannya sendiri, sedangkan jalur ini hanya mau cache, apa pun nilai key itu.
- **Hanya release yang tidak bisa disajikan oleh apa pun.** Release yang masih berfungsi tidak pernah disalin, begitu juga release yang belum selesai ditangani repair.
- **Akun yang menolak akan semakin jarang ditanya.** Jeda setelah penolakan dimulai dari satu hari dan dua kali lipat setiap kali ditolak lagi, sampai sekitar dua minggu. Release yang hanya sedang tidak ada di cache minggu ini akan ditemukan lagi dalam beberapa hari; yang sudah hilang selamanya cukup ditanyakan dua minggu sekali. Tanpa peluruhan ini, mode always-on berarti setiap release mati di setiap akun akan ditambahkan tiap hari, selamanya.
- **Paling banyak sepuluh release per sweep**, jadi sweep pertama setelah menambahkan akun kedua akan memproses tumpukan backlog selama berjam-jam, bukan sekaligus dalam satu lonjakan.

Akun yang sudah punya salinan release itu tidak pernah ditawari instance kedua, seburuk apa pun salinan yang dimilikinya. Strategi repair sendiri yang mengurus akun itu, dan di Real-Debrid add duplikat tidak pernah benar-benar mengunduh. Release yang key-nya bukan info hash bittorrent, yaitu cara backend Usenet mengenali release miliknya sendiri, tidak pernah ditawarkan ke mana pun.

Ini satu-satunya tempat zurg menambahkan sesuatu ke akun yang kontennya kedaluwarsa tanpa diminta. Repair tidak akan menambahkan ulang release ke akun seperti itu sesuai timer, karena mengambil ulang konten yang sengaja dihapus layanannya adalah pola yang oleh layanan-layanan tersebut disebut penyalahgunaan. Penawaran dari cache bukan hal itu: tidak ada yang diambil, tidak ada kuota yang terpakai, dan konten yang diklaim sudah ada di cache layanan karena ada pihak lain yang menaruhnya di sana.

### Detail library {#library-detail}

**`library_detail: resident` tetap menjadi default.** Pilih mode dan waktu idle di halaman konfigurasi dashboard atau di `config.yml`. Kedua pengaturan baru berlaku setelah zurg di-restart. Menyimpannya tidak akan mengubah sebagian library yang sedang berjalan. Kebijakan ini berlaku untuk setiap provider dalam satu instance.

| Mode | Perilaku | Kompromi |
|---|---|---|
| `resident` | Menyimpan detail file setiap release di memori. | Akses lebih mudah diprediksi karena tidak ada pemuatan ulang detail; pemakaian memori paling tinggi. |
| `lazy` | Melepas detail setelah `library_detail_idle_secs` tidak digunakan. | Mengurangi memori saat idle meskipun RAM masih banyak; mengakses detail yang sudah dilepas butuh pemuatan ulang. |
| `auto` | Menyimpan detail selama memori masih cukup, dan melepas tabel idle tertua saat tekanan memori berlangsung terus-menerus. | Menyesuaikan diri dengan kondisi runtime; menambah pemantauan tekanan dan waktu muat ulang yang kurang bisa diprediksi. |

Nama, ukuran, rename, dan visibilitas tetap tersedia untuk listing di semua mode. Saat file dibuka atau diperbaiki, detail yang sudah dilepas akan dibangun ulang sesuai kebutuhan. `auto` tidak langsung memuat ulang seluruh library saat tekanan memori berakhir. Detail akan kembali seiring digunakan dan tetap resident sampai tekanan dan jendela idle memungkinkan pelepasan lagi.

#### Deteksi tekanan otomatis {#automatic-pressure-detection}

`auto` mengambil sampel setiap 30 detik. Dua pembacaan yang berjarak minimal 30 detik dan berada di atas atau sama dengan **90%** dari anggaran yang terukur akan memulai eviction, dalam batch maksimal **128 tabel idle** per sapuan. Eviction terus berjalan sampai pemakaian mencapai **80%** atau kurang, lalu berhenti sebentar selama minimal satu menit sebelum mempertimbangkan episode baru. Lonjakan singkat tidak memicu eviction. Jendela idle yang sudah dikonfigurasi selalu berlaku.

Pembacaan yang paling ketat dari yang tersedia yang menentukan keputusan:

- **Memori host:** total dikurangi memori yang tersedia, termasuk perkiraan OS atas cache yang bisa direklaim. Filesystem cache yang penuh saja bukan berarti RAM kekurangan.
- **Container Linux dan batas layanan:** `memory.max` dan `memory.high` cgroup v2, atau `memory.limit_in_bytes` v1, beserta pemakaian masing-masing leluhur yang terlihat. Cache file dingin dikurangi perhitungannya. Batas container dibaca ulang saat runtime; namespace cgroup privat dapat menyembunyikan batas di atas root yang terlihat.
- **Anggaran runtime yang eksplisit:** `memory_limit_mb` yang positif, dalam MiB, dibandingkan dengan memori yang dikelola Go. `GOMEMLIMIT`, jika diatur, lebih diutamakan; `GOMEMLIMIT=off` menonaktifkan sinyal khusus ini. Tekanan dari host dan container tetap berlaku. Batas Go otomatis yang berasal dari cache Usenet diabaikan karena naik seiring heap aktif dan tidak mengukur RAM yang tersedia.

Tidak perlu anggaran tambahan untuk mengaktifkan `auto`:

```yaml
library_detail: auto
library_detail_idle_secs: 300
# Optional explicit Go runtime budget, also used by the collector:
# memory_limit_mb: 1024
```

Tanpa pengukuran yang bisa dipakai, eviction otomatis akan berhenti sementara.

Ini adalah optimasi memori yang bertahap, **bukan batas memori yang keras**: file yang sedang aktif, perubahan yang belum disimpan, snapshot pemulihan, dan cache lain bisa mendominasi memori, dan lonjakan alokasi mendadak bisa lebih cepat daripada sapuan. `memory_limit_mb` tetap berupa batas collector yang lunak; mengaturnya di bawah data live bisa menyebabkan garbage collection berlebihan.

#### Integritas data dan biaya {#data-integrity-and-cost}

Eviction menyimpan **snapshot pemulihan terkompresi** di samping dump `data/*.zurgtorrent` yang sudah ada. Reload dari disk harus sama dengan snapshot itu. Jika dump hilang, rusak, atau diganti, zurg memulihkan snapshot dan tetap menyimpan rilis di memori, lalu mencoba menyimpan data hasil pemulihan lagi. `auto` juga mencoba ulang tabel kotor yang idle saat tekanan memori sudah berakhir, dengan pass penyimpanan terpisah yang dibatasi. Penulisan file dan perubahan state langsung memulihkan kepemilikan, termasuk penulisan lewat pointer yang dipegang stream saat eviction. Penyimpanan yang gagal membiarkan perubahan tetap di memori dan kotor. Penulisan yang saling tumpang tindih tidak diakui oleh save yang lebih lama. Perubahan baru aman dari exit proses kalau save-nya berhasil.

Diukur di Apple Silicon Mac dengan Go 1.26.4, memakai 500 rilis per bentuk lewat jalur konversi dan persistensi, termasuk snapshot pemulihan:

| Bentuk | Byte resident/entri | Byte lazy/entri | Pengurangan | Rata-rata rebuild |
|---|---:|---:|---:|---:|
| Film Real-Debrid, 3 file | 3,662 | 2,845 | 22% | 88 µs |
| Season pack Real-Debrid, 24 file | 15,670 | 7,366 | 53% | 371 µs |
| TorBox, 2 file | 3,019 | 2,680 | 11% | 56 µs |
| AllDebrid, 1 file | 2,580 | 2,516 | 2% | 55 µs |
| Set RAR, 7 volume | 5,343 | 3,303 | 38% | 109 µs |

Ini adalah angka heap yang tertahan per rilis, bukan RSS seluruh proses. Rebuild membaca file lokal yang baru ditulis; storage yang cold atau remote bisa lebih lama. Pilih `lazy` untuk reklamasi idle yang konsisten, atau `auto` untuk reklamasi hanya saat tekanan memori. Pakai `resident` kalau akses yang bisa diprediksi lebih penting daripada RAM. Rilis kecil hemat sedikit saja, dan snapshot pemulihan memang sengaja memakai memori untuk melindungi data. Angka-angka ini menggambarkan entri yang di-evict pada `lazy` maupun `auto`; mode otomatis bisa menyimpan lebih banyak entri pada waktu tertentu.

## 5. Jaringan & Konektivitas (Teknis) {#5-network--connectivity-technical}

Pengaturan infrastruktur yang mengatur bagaimana zurg melakukan bind, autentikasi, dan terhubung ke jaringan.

### Server Binding

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `host` | string | `"[::]"` | Antarmuka jaringan yang dipakai. `[::]` mendengarkan di semua antarmuka (IPv4 dan IPv6). Pakai `0.0.0.0` untuk IPv4 saja, atau IP tertentu untuk membatasi akses ke satu antarmuka. |
| `port` | string | `"9999"` | Port tempat zurg mendengarkan. Variabel environment `PORT` akan menimpa nilai ini jika diatur, yang berguna untuk deployment dalam container. |

```yaml
host: "[::]"
port: 9999
```

### Koneksi hangat {#warm-connections}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `warm_connections` | int | *(tidak diisi)* | Batas minimum untuk setiap akun yang tidak menetapkan nilainya sendiri. Jika tidak diisi, setiap backend memakai default-nya: 1 per host untuk akun debrid, 2 per akun untuk akun news. `-1` mematikan warming di semua tempat. Nilai `warm_connections` milik akun selalu menang, termasuk atas `-1` global. |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**Seberapa besar manfaatnya bergantung pada host, dan untuk layanan debrid hasilnya lebih kecil dari yang terdengar.** Koneksi yang tidak mengirim apa pun adalah yang pertama dibersihkan layanan ini, dan mereka melakukannya dengan cepat. Diukur dari host live pada 2026-08-29, dengan membiarkan koneksi diam tetap terbuka sambil menunggu sampai diputus:

| Host | Koneksi diam | Setelah melayani permintaan |
|---|---|---|
| host unduh Real-Debrid | ditutup setelah 30s | langsung ditutup |
| `api.alldebrid.com` | ditutup setelah 15s | masih terbuka di menit ke-4 |
| `api.torbox.app` | ditutup setelah 15s | masih terbuka di menit ke-4 |
| `api.real-debrid.com` | ditutup setelah 4s | ditutup setelah 5s |

Jadi, warm floor hanya layak dipakai untuk host unduh, dan tidak banyak gunanya di tempat lain. API Real-Debrid sama sekali tidak bisa di-warm. Tidak ada floor yang bisa mengalahkan pemutusan 4 detik tanpa membuat traffic palsu agar koneksi tetap hidup, dan zurg memang tidak akan melakukan itu. Daripada menebak, **floor ini mengukur sendiri**: ia menutup koneksinya sendiri setelah 15 detik dan memeriksa apakah tiap koneksi masih hidup saat itu. Jika sebuah host terus-menerus menutup koneksi sebelum read sempat memakainya, floor berhenti dipakai untuk host itu dan read-nya kembali melakukan dial seperti biasa. Kamu tidak perlu mengatur apa pun untuk ini, dan floor yang tidak terpakai di library yang sepi tidak akan salah dianggap gagal.

Ada dua hal lagi yang perlu kamu tahu sebelum menaikkan nilainya:

- **Floor akun debrid berlaku per host, sedangkan floor akun news berlaku per akun.** Akun debrid terhubung ke banyak host: satu hostname API dan satu host pengiriman untuk tiap link. Host mana saja yang dipakai baru bisa diketahui setelah link dibuat, jadi host yang dijaga tetap hangat adalah host yang benar-benar sudah dipakai akun tersebut. Paling banyak 16 host dijaga sekaligus, dan host yang tidak dipakai selama 10 menit akan dilepas. Akun news hanya punya satu host, yang disebut di config, dan ia menahan sesinya selama paket mengizinkan. Itulah sebabnya floor akun news paling bisa diandalkan manfaatnya. Lihat [Usenet](../guides/usenet.md).
- **Warm connection adalah koneksi sungguhan, dan mereka ikut dihitung ke batas per host yang diawasi provider**, yaitu 32 di Real-Debrid dan AllDebrid, dan 20 di TorBox. Itu sebabnya floor debrid dibatasi maksimal 4. Dengan ukuran itu, batas tersebut hampir tidak terpakai. Jika floor-nya besar, batas itu akan habis untuk soket yang tidak membawa apa-apa.

Floor ini dinonaktifkan saat `proxy` diatur, karena proxy HTTP atau SOCKS membuat zurg melakukan dial ke proxy, bukan ke host tujuan. Jadi tidak ada yang layak ditahan terbuka di sisi seberangnya.

### Autentikasi & Proxy {#authentication--proxy}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `username` | string | `""` | Username untuk autentikasi dasar HTTP. Jika diisi bersama `password`, semua permintaan ke zurg (dashboard, WebDAV, API) harus diautentikasi. Kosongkan untuk menonaktifkan autentikasi. |
| `password` | string | `""` | Password untuk autentikasi dasar HTTP. Harus diisi bersama `username`. |
| `proxy` | string | `""` | Arahkan semua trafik jaringan keluar dari zurg lewat proxy. Mendukung protokol `http://`, `https://`, dan `socks5://`. Berguna jika ISP kamu memblokir atau membatasi trafik Real-Debrid. Contoh: `socks5://user:pass@host:port`. Variabel lingkungan `PROXY` dipakai saat opsi ini kosong. |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Pengaturan Rclone {#rclone-settings}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | Jika true, zurg mengelola mount rclone secara otomatis. Dengan ini kamu tidak perlu lagi menjalankan rclone secara terpisah. zurg memulai, memantau, dan memulai ulang proses rclone bila diperlukan. Mount memakai `mount_path` sebagai titik mount. |
| `rclone_binary` | string | `"rclone"` | Path ke executable rclone. Hanya perlu diisi jika rclone tidak ada di PATH sistem kamu. |
| `rclone_extra_args` | list | `[]` | Flag command-line tambahan yang diteruskan ke perintah mount rclone. Gunakan ini untuk menimpa default VFS hasil benchmark milik zurg (lihat tabel di bawah). Setiap entri adalah satu string flag. Pengaturan RC dan flag backend `--union-*`/`--webdav-*` ditolak, karena zurg membuatnya sendiri. Flag yang kamu tulis akan mengalahkan apa yang sudah dibangun zurg, dan `union_writable` jadi tidak lagi menggambarkan mount yang sebenarnya. |
| `mount_read_only` | bool | `false` | Jika true, mount dijalankan dengan `--read-only` milik rclone, sehingga kernel menolak penulisan sebelum sampai ke zurg. Tidak ada mekanisme lain yang membatasi DELETE pada mount, jadi ini satu-satunya cara untuk menolaknya. Meski begitu, ini tidak mencakup klien yang berbicara langsung ke endpoint WebDAV. Ini juga menghentikan penulisan nyasar agar tidak masuk ke upstream union lokal mount. Timpa per flag dengan `rclone_extra_args: ["--read-only=false"]`. |
| `rclone_cache_reclaim` | bool | `true` | Menentukan apakah zurg menghapus pohon cache VFS yang tertinggal dari konfigurasi mount sebelumnya. rclone menamai cache-nya sesuai nama remote, dan nama itu di-hash dari upstream union, yang memuat path absolut `data/local`. Jadi memindahkan direktori zurg atau mengubah `union_writable` akan mengganti nama cache dan meninggalkan pohon lama di tempat yang tidak dihitung batas mana pun dan tidak pernah dikunjungi pembersih. Saat mount dimulai, zurg bertanya ke rclone yang sedang berjalan pohon mana yang aktif, lalu menghapus sisanya dan mencatat berapa banyak ruang yang dibebaskan. Zurg tidak melakukan apa-apa kecuali pohon aktif berada di lokasi yang dilaporkan rclone, dan melewati penyapuan sepenuhnya jika `rclone_extra_args` mengatur `--cache-dir`. Atur ke `false` jika kamu ingin menyimpan semua pohon yang tertinggal. Lihat [Disk yang dipakai mount](#disk-the-mount-uses). |
| `union_writable` | string | `"local"` | Menentukan sisi union mount tertanam mana tempat file baru ditulis. `local`, nilai default, langsung menaruhnya ke upstream lokal (`data/local`) tanpa dilihat zurg. `server` menempatkan upstream WebDAV di urutan pertama, sehingga pembuatan file sampai ke zurg: ditolak di luar `__magic__`, dan ditulis sebagai sidecar berukuran terbatas di dalamnya. Penulisan yang ditolak tidak pernah sampai ke disk. Cache VFS rclone menerimanya lalu mencoba upload ulang dengan backoff, sehingga dibatasi oleh batas cache dan terlihat di `logs/rclone.log`. Dengan urutan `local`, byte tanpa batas akan masuk ke `data/local`. Satu catatan yang teramati di bawah `server`: mengganti nama file sidecar lewat mount bisa menghasilkan error. File terlihat di kedua upstream, jadi rclone menerapkan perpindahan ke masing-masing. Pemindahan release di dalam `__magic__`, yaitu jalur import *arr, tidak terpengaruh. Beralih ke `server` hanya mengubah lokasi pembuatan file *baru* dan tidak ada yang lain. Apa pun yang sudah ditulis urutan `local` ke `data/local` tetap ada sampai kamu menghapusnya. Baris yang dicatat zurg saat startup menyebutkan mode yang aktif (`new files go to zurg over WebDAV (union_writable: server)`), jadi itu yang sebaiknya kamu cek, bukan keberadaan path `data/local`. Path itu tetap bagian dari union di kedua urutan. |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
rclone_cache_reclaim: true
union_writable: "local"
```

#### Default yang Dioptimalkan dari Benchmark {#benchmark-optimized-defaults}

zurg memakai pengaturan VFS rclone yang sudah diuji dengan benchmark dan dioptimalkan untuk performa streaming:

| Setting | Default | Alasan |
|---------|---------|-----|
| `--buffer-size` | 256M | Buffer besar agar streaming lancar |
| `--vfs-read-chunk-size` | 32M | Berapa lama pembacaan baru perlu naik bertahap. Chunk pertama diambil dengan ukuran ini lalu berlipat dua setelahnya, jadi di 4M, pembacaan dari offset yang belum pernah dibaca menghabiskan sebagian besar waktunya di bawah kecepatan penuh koneksi. Ini ukuran permintaan, bukan transfer paksa. rclone tetap berhenti mengambil data saat reader berhenti. |
| `--vfs-read-chunk-size-limit` | 512M | Batas di mana penggandaan di atas berhenti. Chunking aktif secara default, jadi ini adalah batas atas yang dicapai saat naik bertahap, bukan sesuatu yang diaktifkan oleh override. |
| `--vfs-read-ahead` | 128M | Keseimbangan antara efisiensi buffer dan bandwidth |
| `--max-read-ahead` | 1M | Buffer kernel FUSE yang kecil mengurangi pembacaan kecil. Tidak dikirim di Windows. |
| `--vfs-read-wait` | 5ms | Penting: nilai yang lebih tinggi menyebabkan perlambatan parah |
| `--vfs-cache-mode` | full | Cache penuh untuk performa terbaik. Tidak selalu pilihan yang tepat untuk player yang membaca mount melalui share. Lihat [When the cache costs more than it buys](#when-the-cache-costs-more-than-it-buys). |
| `--vfs-cache-max-size` | 256G | Batas keras untuk cache VFS di disk. Ini bukan config key. Timpa dengan `rclone_extra_args`. |
| `--vfs-cache-min-free-space` | 10G | Berhenti melakukan caching sebelum disk cache penuh |
| `--vfs-cache-max-age` | 72h | Berapa lama file cache yang tidak tersentuh disimpan. Kata kuncinya adalah "tidak tersentuh", dan media server jarang membiarkan sesuatu tidak tersentuh. Lihat [Disk the mount uses](#disk-the-mount-uses). |
| `--vfs-cache-poll-interval` | 1m | Pembaruan cache yang responsif |
| `--vfs-fast-fingerprint` | on | Mengidentifikasi file tanpa melakukan hashing |
| `--dir-cache-time` | 12h | Daftar direktori disimpan selama berjam-jam. zurg menghapus entri terkait lewat RC API saat library berubah, jadi scan media server tetap cepat. |
| `--attr-timeout` | 60s | File library bersifat immutable, dan perubahan state menghapus entri terkait secara eksplisit. Dibatasi agar ukuran yang sudah usang tidak bertahan melewati satu kali scan. |
| `--poll-interval` | 0 | Pengecekan perubahan adalah tugas zurg, bukan rclone |
| `--timeout` | 5m | Timeout idle IO |
| `--no-modtime` / `--no-checksum` | on | Keduanya tidak berarti untuk library debrid, dan memintanya tetap memakan permintaan |
| `--async-read` | default rclone (aktif), tidak dikirim | zurg tidak menaruh flag ini di command line, dan rclone menganggapnya true secara default. Jadi mount membaca secara asinkron, dan semua angka di halaman ini diukur dengan cara itu. Sebuah field tuning pernah mengklaim bisa menonaktifkannya. Yang sebenarnya terjadi hanyalah menambahkan flag polos, yang hanya menetapkan default yang memang sudah berlaku. Untuk benar-benar mematikannya: `rclone_extra_args: ["--async-read=false"]`. |
| `--low-level-retries` | 3 | Downloader VFS rclone sudah memulai ulang pembacaan yang gagal sepuluh kali per open, dan setiap restart diulang oleh backend pacer sebanyak nilai ini. Dengan default rclone 10, itu berarti 100 permintaan untuk satu open file yang sengaja dijawab zurg dengan 503. |
| `--retries` | 1 | Anggaran untuk seluruh command. Untuk mount yang tidak pernah keluar, nilai ini hanya memperbanyak kegagalan saat startup. |
| `--vfs-handle-caching` | 0, aktif di rclone 1.74+ | rclone 1.74 mulai menjaga downloader file tetap hidup selama lima detik setelah penutupan terakhir. Jadi, membuka file berarti lima detik penuh dari apa pun yang bisa dialirkan koneksi, bukan dari apa yang benar-benar dibaca. Pengukuran dengan server 50 MB/s: satu pembacaan 1 MiB menarik 245-250 MiB, bukan 3-6 MiB, dan sapuan dua puluh file naik dari 80 MiB menjadi 4,2 GiB. Masa tenggang ini ada untuk `serve nfs`, yang tidak pernah dijalankan zurg. rclone yang lebih lama tidak punya flag ini dan menolak start jika menemukan flag yang tidak dikenal, jadi zurg menanyakan versi binary dulu dan tidak mengirim apa pun untuk versi di bawah 1.74. |
| `--log-level` | NOTICE | Tingkat verbositas rclone sendiri, selalu dikirim |
| `--cache-dir` | `data/rclone-cache` | Dihitung relatif terhadap working directory |
| `--log-file` | `logs/rclone.log` | Dihitung relatif terhadap working directory |

`--vfs-cache-max-size`, `--vfs-cache-min-free-space`, `--low-level-retries`, `--retries`, `--vfs-handle-caching`, `--log-level`, `--cache-dir` dan `--log-file` adalah konstanta di `internal/rclone/manager.go`. Baris lainnya berasal dari `tuneVFSOptions` di `internal/rclone/tuning.go`, termasuk `--vfs-cache-max-age` dan `--vfs-cache-poll-interval`, meskipun namanya menyesatkan.

### Disk yang dipakai mount {#disk-the-mount-uses}

`--vfs-cache-mode full` berarti file yang dibaca lewat mount akan diunduh **sepenuhnya** ke `data/rclone-cache` dan tetap tersimpan di sana setelah pemutaran selesai. Ini bukan buffer sementara yang kosong saat video berhenti. Jika dibiarkan, cache akan terus membesar sampai mencapai `--vfs-cache-max-size`, yang defaultnya **256G**, dan tetap di situ.

Ada dua batas yang seharusnya membatasi cache, tetapi dalam praktiknya hanya satu yang berfungsi:

- `--vfs-cache-max-size` (256G) adalah batas yang sebenarnya. Atur nilainya tidak lebih dari setengah ruang kosong pada disk tempat `data/` berada.
- `--vfs-cache-max-age` (72h) menghapus file yang tidak disentuh siapa pun selama tiga hari. rclone menghitungnya dari catatannya sendiri di `data/rclone-cache/vfsMeta/`, bukan dari atime filesystem, dan **apa pun yang membaca library akan memperbaruinya**. Server Plex dengan tugas terjadwal yang aktif membaca setiap file yang tersimpan di cache selama jendela pemeliharaan malam hari. Jadi pada 2026-09-09, sebuah instance yang cache-nya berisi 362 file memiliki ATime dari pagi yang sama untuk semuanya. Tidak ada yang kedaluwarsa dalam beberapa bulan, dan tidak akan pernah ada. Jangan mengandalkan penghapusan berdasarkan umur; andalkan batas ukuran.

Turunkan batasnya dengan `rclone_extra_args`:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`--vfs-cache-min-free-space` (10G secara default) menghentikan caching ketika disk hampir penuh sampai batas tersebut. Biarkan nilainya jauh di atas nol jika disk dipakai bersama dengan aplikasi lain.

Untuk membersihkan cache secara manual, hentikan zurg terlebih dahulu, lalu kosongkan kedua folder:

```bash
rm -rf data/rclone-cache/vfs/* data/rclone-cache/vfsMeta/*
```

Ukur dengan `du -sh data/rclone-cache`. Entri yang diunduh sebagian adalah sparse file, jadi ukuran yang menghitung byte semu akan melaporkan jauh lebih besar daripada yang sebenarnya digunakan disk.

#### Saat cache lebih mahal daripada manfaatnya {#when-the-cache-costs-more-than-it-buys}

`full` adalah pilihan default yang tepat untuk media server di host yang sama: ia membaca file
sekali, dan semua setelahnya dibaca dari lokal. Tapi ini tidak otomatis cocok untuk
hardware player yang membaca mount lewat file share.

Dengan `full`, setiap pembacaan harus sudah tersimpan di disk sebelum sampai ke pembaca,
dan yang diambil adalah seluruh file, bukan hanya bagian yang sedang ditonton. Kalau ada
share di depannya, satu disk melayani player sementara rclone masih menulis ke disk yang sama.
Player Zidoo yang membaca share Windows tersendat di setiap judul sampai cache dimatikan,
dan setelah itu berjalan lancar (dilaporkan 2026-08-30). Penjelasan mekanisme di atas
adalah dugaan paling masuk akal untuk laporan tersebut, bukan sesuatu yang sudah diukur di sini. Jadi,
anggap ini hal pertama yang dicoba saat client yang membaca langsung tersendat di mount,
padahal media server di host yang sama memutarnya tanpa masalah:

```yaml
rclone_extra_args:
  - "--vfs-cache-mode"
  - "off"
```

Yang dikorbankan itu nyata. Tanpa salinan lokal, seek akan membaca ulang dari provider,
pemutaran kedua akan mengunduh file lagi, dan tidak ada yang tersimpan setelah restart. Pengaturan ini juga
mengubah apa yang diterima mount sebagai write, jadi biarkan default kalau di host tersebut
ada \*arr yang mengimpor lewat mount — lihat [qbittorrent.md](../guides/sonarr-radarr-torrents.md).

#### Cache yang tertinggal setelah pindah {#caches-stranded-by-a-move}

rclone memberi nama cache-nya sesuai remote yang di-cache, dan nama itu membawa hash dari konfigurasi remote tersebut. Remote zurg adalah union, dan upstream-nya menyimpan path absolut dari `data/local`. Jadi nama itu ikut berubah ketika konfigurasinya berubah:

| Upstream union | Pohon cache |
|---|---|
| `/home/you/zurg/data/local :webdav:` | `vfs/zurg{QaSkn}` |
| `:webdav: /home/you/zurg/data/local` (`union_writable: server`) | `vfs/zurg{HdSp7}` |
| `/other/root/data/local :webdav:` (zurg dipindah) | `vfs/zurg{Psid2}` |

rclone hanya menghitung pohon yang sedang dipakainya. Pohon dengan nama lama tidak dihitung terhadap batas mana pun, tidak dikunjungi oleh cleaner, dan tidak dihapus oleh siapa pun. Jadi memindahkan direktori zurg, atau drive eksternal yang kembali dengan mount point baru, bisa meninggalkan satu cache utuh di belakang. Kalau ini terjadi beberapa kali, instalasi dengan batas 256G bisa berakhir menyimpan beberapa terabyte.

zurg membersihkan pohon-pohon itu saat mount dimulai. zurg bertanya ke rclone yang sedang berjalan pohon mana yang aktif, lalu menghapus sisanya sambil mencatat berapa yang dibebaskan. zurg tidak melakukan apa-apa kalau pohon yang aktif tidak berada di disk tempat rclone bilang. Pembersihan juga dilewati sepenuhnya kalau `rclone_extra_args` mengatur `--cache-dir`, karena direktori yang kamu pilih sendiri mungkin dipakai bersama zurg lain. Atur `rclone_cache_reclaim: false` untuk mematikannya dan menyimpan semua pohon yang terlantar.

Empat flag lagi ditambahkan sesuai platform, semuanya di Linux: `--allow-other` dan `--allow-non-empty` selalu ada, sedangkan `--uid` dan `--gid` hanya ditambahkan kalau id user yang menjalankan bisa dibaca. `--max-read-ahead` dipasang di semua platform kecuali Windows, dan `--read-only` dipasang setiap kali [`mount_read_only`](#rclone-settings) diatur.

Nilai buffer dan read-wait ditentukan lewat benchmark di koneksi 600 Mbps, dengan hasil throughput cold-cache sekitar ~533 Mbps dan TTFB sekitar ~235ms. Ukuran read chunk diukur ulang belakangan di host dengan kecepatan sekitar ~70 MB/s. Dengan pengujian berpasangan dan bergantian, median throughput di Real-Debrid naik dari 49.1 -> 56.5 MB/s saat ukurannya diubah dari 4M ke 32M, dan hasilnya sama di TorBox.

**Timpa default** dengan `rclone_extra_args`:
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

Flag RC (`--rc`, `--rc-addr`, dan apa pun lain yang diawali `rc-`) ditolak. zurg menjalankan remote control rclone sendiri untuk menghapus cache VFS setiap kali library berubah.

### User Agent & Jaringan {#user-agent--network}

| Option | Type | Default | Deskripsi |
|--------|------|---------|-------------|
| `user_agent` | string | Chrome UA | User-Agent HTTP bersama untuk provider, indexer, ffprobe, dan integrasi keluar. Kosong akan mengembalikan default browser generik; nilai custom yang kamu isi akan dikirim apa adanya. Perlu restart. Lihat [identitas request keluar](outbound-identity.md). |
| `omit_user_agent` | boolean | `false` | Menghilangkan HTTP User-Agent (ffprobe memakai nilai kosong), dan menimpa `user_agent`. Request ke GitHub tetap mengirim satu, karena GitHub menolak request tanpa itu. Perlu restart. |
| `outbound_client_name` | string | `"Media Client"` | Nama produk/klien untuk integrasi media server jika didukung. Kosong akan mengembalikan default. Perlu restart. |
| `outbound_client_id` | string | `"media-client"` | Identifier klien Plex, termasuk sign-in untuk integrasi media server jika didukung. Kosong akan mengembalikan default. Perlu restart. |
| `outbound_client_version` | string | `"1.0"` | Versi klien untuk integrasi media server jika didukung. Kosong akan mengembalikan default. Perlu restart. |
| `outbound_device_name` | string | `"Media Client"` | Nama perangkat untuk integrasi media server jika didukung. Kosong akan mengembalikan default. Perlu restart. |
| `outbound_device_id` | string | `"media-client"` | Identifier perangkat Jellyfin/Emby untuk integrasi media server jika didukung. Kosong akan mengembalikan default. Perlu restart. |
| `outbound_platform` | string | `"Desktop"` | Platform Plex untuk integrasi media server jika didukung. Kosong akan mengembalikan default. Perlu restart. |
| `force_ipv6` | bool | `false` | Memaksa semua tes jaringan dan pemilihan host zurg memakai IPv6. Aktifkan ini kalau jaringanmu punya konektivitas IPv6 yang lebih baik ke server RD (misalnya beberapa ISP membatasi IPv4 tapi tidak IPv6). |
| `unrestrict_ip` | string | `""` | Alamat IP yang dikirim ke RD saat membuka link download. Berguna di setup multi-jaringan kalau kamu ingin download dibuat untuk IP tertentu (misalnya IP exit VPN) alih-alih IP tempat zurg berjalan. |
| `dns_servers` | list | `[]` (DNS sistem) | Server DNS custom untuk me-resolve hostname RD. Berguna kalau DNS sistemmu lambat, tidak stabil, atau diblokir ISP-mu. Kosongkan untuk memakai resolver sistem. Harus menyertakan port (misalnya `1.1.1.1:53`). |
| `network_test_every_mins` | int | `1440` | Seberapa sering (dalam menit) zurg menjalankan ulang tes latensi jaringan untuk mencari server download RD tercepat. Tidak bisa dinonaktifkan — nilai `<= 0` diperlakukan sebagai `1440`. Hasil di-cache ke `data/network_test_results.json` dan `data/network_test_timestamp`; saat restart, jika cache masih cukup baru, tes jaringan dilewati. |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### Berbagi NZB publik {#public-nzb-sharing}

Share NZB adalah URL yang diambil oleh penerima, jadi URL ini hanya berguna kalau penerima bisa menjangkau host ini. Hal itu tidak bisa dijamin untuk zurg yang berada di balik NAT rumahan. Kedua key ini mengarahkan URL tersebut lewat layanan [zrok](https://zrok.io): zurg menghubungi layanan secara outbound dan melayani share melalui koneksi itu, jadi **tidak ada port lokal yang terbuka** dan tidak ada yang baru menjawab di host ini. Yang dibawa tunnel hanyalah dua route share yang dilindungi token, bukan dashboard dan bukan library.

Jika kedua key kosong dan tidak ada environment yang aktif di `data/zrok`, sharing tetap berjalan di jaringan tempat host ini berada tanpa menghubungi tempat lain. Itulah default-nya. Perhatikan bagian kedua: setelah sebuah environment *pernah* diaktifkan, `zrok_account_token` yang kosong tidak lagi berarti hanya lokal, karena proses enable itulah yang menyalakan sharing dan statusnya tersimpan. Untuk mematikan public sharing lagi, hapus `data/zrok`.

Membuat, melayani, dan mencabut share bekerja dengan cara yang sama di kedua kondisi. Share token di path adalah otorisasi untuk URL lokal maupun URL publik.

URL publik tetap sama setelah restart: share di sisi layanan dicari lalu dilekatkan kembali, bukan dibuat ulang. Yang tidak bertahan adalah saat kamu enable lagi: environment baru mendapat share baru, dan URL yang sudah dibagikan di bawah share lama berhenti bisa di-resolve. Itu terjadi ketika kamu menghapus `data/zrok`, dan juga jika identitas yang tersimpan di dalamnya hilang atau tidak bisa dibaca, karena enable ulang adalah satu-satunya jalan kembali dari kondisi itu.

Menghapus `data/zrok` secara manual juga meninggalkan environment itu, dan share di bawahnya, terdaftar di akun zrok. Identitas yang seharusnya bisa melepaskannya justru yang baru saja kamu hapus, jadi bersihkan dari console zrok jika kekacauan itu mengganggu. Cara ini juga bukan cara mematikan sharing di tempat: zurg yang sedang berjalan masih memegang koneksi yang sedang dilayaninya, sehingga URL lama tetap bekerja sampai proses di-restart. zurg melepas environment sendiri setiap kali menggantinya, dan menolak mengganti environment yang tidak bisa dihubungi layanannya untuk dilepas, atau yang file-nya ditemukan di disk tetapi tidak bisa dibaca, karena enable di atas itu akan meninggalkan environment yang masih hidup setiap kali restart.

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `zrok_account_token` | string | `""` | Enable token zrok yang menyalakan public sharing. Gratis dari [myzrok.io](https://myzrok.io) untuk layanan hosted; dari controller milikmu sendiri jika self-host. Hanya dibutuhkan untuk **enable pertama**: enable menukarkannya sekali dan menyimpannya, bersama identitas environment, di bawah `data/zrok`. Setiap panggilan berikutnya diautentikasi dari salinan yang tersimpan itu, jadi key boleh dihapus dari `config.yml` setelahnya dan public sharing tetap naik saat restart berikutnya. Perhatikan konsekuensinya untuk secret: menghapus key dari config tidak menghapus token dari host. Ada dua alasan untuk tetap menaruhnya di sana: enable yang *gagal* (token ditolak, atau layanan tidak bisa dihubungi) belum selesai, dan retry membutuhkan key itu; dan setiap *enable ulang* juga membutuhkannya, jadi instance yang key-nya sudah dihapus lalu kehilangan identitas di `data/zrok` tidak bisa pulih sendiri. Token yang dirotasi akan diambil dari sini dan diterapkan ke environment tersimpan, dengan identitas dan URL publik tetap utuh. |
| `zrok_api_endpoint` | string | `""` | Layanan zrok yang dihubungi, untuk deployment self-hosted; kosong berarti memakai default SDK, `https://api-v2.zrok.io` (layanan hosted). Dibaca **hanya saat enable**. Begitu `data/zrok` berisi environment yang aktif, endpoint yang tersimpan di sana yang berlaku, jadi mengarahkan zurg yang sudah aktif ke layanan lain berarti menghapus `data/zrok` lalu enable lagi. Identitas itu milik layanan yang menerbitkannya, jadi cara ini memang yang paling jujur. Endpoint ini tidak menggantikan `zrok_account_token`: enable pertama tetap butuh token dari layanan yang disebut di sini. Environment variable `ZROK2_API_ENDPOINT` milik SDK mengalahkan key ini pada saat yang sama. |

Keterjangkauan terbelah dua untuk layanan self-hosted, dan hanya satu bagian yang ada di tanganmu: **zurg ini** menjangkau API controller (alamat tailnet sudah cukup untuk itu), sedangkan **penerimamu** menjangkau frontend layanan. Layanan yang hanya bisa dijangkau dari tailnet milikmu sendiri akan memberikan URL share yang hanya bisa dibuka dari tailnet milikmu sendiri.

Ada dua hal lagi yang harus selaras di layanan self-hosted. URL share adalah yang diiklankan layanan untuk frontend-nya, dan host tanpa scheme dianggap `https`, jadi frontend yang melayani HTTP biasa perlu TLS di depannya, atau URL yang diiklankan membawa scheme dan port sendiri. Lalu share dibuat di namespace yang di-resolve oleh SDK zrok, yaitu `public` kecuali `ZROK2_DEFAULT_NAMESPACE` milik SDK menyatakan lain. zurg tidak mengunci keduanya, jadi layanan yang namespace-nya bernama lain harus memberi tahu lewat variabel itu.

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. Performa & Tuning (Lanjutan) {#6-performance--tuning-advanced}

Pengaturan ini jarang perlu diubah, kecuali saat debugging atau saat mengoptimalkan untuk kondisi jaringan Anda.

### Cache baca yang persisten {#persistent-read-caches}

Dua cache byte tetap bertahan saat restart. Keduanya dipakai bersama di seluruh instance, dan masing-masing punya jatah disk sendiri dalam MiB. Perubahan baru berlaku setelah restart.

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `nzb_article_disk_cache_mb` | int | `512` | Artikel Usenet yang sudah didekode, disimpan di `data/bytecache/articles/`. Artikel yang pernah dibaca sekali akan dilayani dari disk pada pembacaan berikutnya. `0` mematikannya. |
| `archive_decoded_disk_cache_mb` | int | `512` | Blok arsip yang sudah didekompresi, disimpan di `data/bytecache/decoded/`. Saat seek mundur atau restart, proses tidak perlu mendekode ulang entri dari awal. Jatah yang sama juga dipakai untuk `data/bytecache/decoded-tails/`, yang menyimpan 8 MiB terakhir dari entri terkompresi setelah ada yang memintanya. `0` mematikan keduanya. |

Saat jatah penuh, catatan yang paling lama tidak terpakai akan dihapus lebih dulu. [persistent-caches.md](../internals/persistent-caches.md) membahas semua cache yang bertahan saat restart.

### Pemilihan CDN & Host {#cdn--host-selection}

> **Terkait:** Tes latensi jaringan yang menentukan host tercepat berjalan secara berkala berdasarkan [`network_test_every_mins`](#user-agent--network) (default: setiap 1440 menit / 24 jam).

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | Mengatur server download RD mana yang diprioritaskan zurg. `auto` memakai apa pun yang diberikan RD. `force_cloudflare` mengubah host menjadi kembarannya yang berakhiran `.cloud`, yang menuju ke mesin yang sama lewat Cloudflare. Ini berguna jika IP langsungnya diblokir. `force_numbered` langsung memakai host bernomor milik RD. `force_location_<location>` (misalnya `force_location_syd`, `force_location_fra`) mengarahkan lewat server di negara tertentu. |
| `cdn_host_preference` | string | — | Alias lama untuk `rd_cdn_host_preference`, dipertahankan demi kompatibilitas dan hanya untuk Real-Debrid. Jika keduanya diisi, yang eksplisit yang dipakai. |
| `tb_cdn_host_preference` | string | `"auto"` | Wilayah CDN TorBox. `auto` membiarkan pilihan TorBox sendiri. `force_location_<region>` membuat download dilayani dari wilayah tersebut. Hanya wilayah yang saat ini punya delivery node yang bisa dipaksa, dan select di dashboard hanya menampilkan wilayah itu. Tidak ada fallback ke kunci lama, karena nilainya adalah kode lokasi Real-Debrid dan tidak berarti apa-apa di sini. |
| `number_of_hosts` | int | `0` (semua) | Membatasi zurg ke N host download tercepat. Setelah menguji kecepatan host yang tersedia, zurg hanya memakai N teratas. Isi `0` untuk memakai semua host yang tersedia. Nilai seperti `3` mengurangi penyebaran koneksi, tetapi memastikan kamu selalu memakai server tercepat. |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` dan `force_location_*` tidak bisa dipakai bersamaan.** RD hanya menyediakan kembaran `.cloud` untuk host bernomornya, bukan untuk host khusus negara. Diukur pada 2026-08-09, semua 25 subdomain bernomor punya kembaran, dan tidak ada satu pun dari 22 subdomain khusus negara yang punya. Jadi akun yang mengaktifkan Cloudflare di pengaturan akun RD selalu diberi host bernomor, dan preferensi lokasi apa pun tidak bisa dipenuhi untuk akun tersebut. zurg mendeteksi ini dari link yang di-unrestrict saat startup, melewati probe geo yang pasti gagal, dan mencatat alasannya di log jika lokasi tetap dikonfigurasi.

> **Catatan tentang verifikasi `force_location_*`:** Saat memakai preferensi geo-lokasi seperti `force_location_nyk`, endpoint API `/rest/1.0/downloads` milik RD menormalkan URL download ke server bernomor (misalnya `128-4.download.real-debrid.com`), padahal respons unrestrict yang sebenarnya mengembalikan server geo (misalnya `nyk7-4.download.real-debrid.com`). Kode download sendiri menyematkan server bernomor (misalnya kode `...4128` dipetakan ke server `128-4`). Untuk memastikan routing geo berjalan, cek log zurg atau respons unrestrict mentah. Jangan **mengandalkan** API downloads milik RD.

### Rate Limits

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | Jumlah maksimum panggilan API RD per menit untuk operasi umum (semua selain daftar torrent). RD punya batasnya sendiri; ini mencegah zurg menabraknya dan kena blokir sementara. Naikkan hanya kalau kamu yakin paket RD kamu memang mengizinkannya. |
| `torrents_rate_limit_per_minute` | int | `75` | Jumlah maksimum panggilan API RD per menit khusus untuk endpoint `/torrents` yang dipakai untuk mengambil daftar torrent kamu. Ini dipisah karena daftar torrent adalah panggilan API yang paling sering dan punya pola laju sendiri. |
| `fetch_torrents_page_size` | int | `5000` | Berapa banyak torrent yang diambil per halaman saat menyinkronkan library RD kamu. Nilai yang lebih besar berarti panggilan API lebih sedikit tapi respons lebih besar. Kalau library kamu sangat besar (10.000+ torrent), nilai yang lebih tinggi mempersingkat waktu sinkronisasi. |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### Verifikasi Link {#link-verification}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | Mengatur cara zurg memeriksa apakah link download masih valid. Jika `false`, zurg memakai request `HEAD` (ringan, tidak ada data yang ditransfer). Jika `true`, zurg memakai header `Range` (`GET bytes=0-0`) yang hanya mengunduh 1 byte. Aktifkan ini jika jaringan kamu atau server RD tidak merespons request HEAD dengan benar, sehingga link dianggap gagal padahal sebenarnya masih valid. |

```yaml
use_range_verification: false
```

### Timeout & Retry {#timeouts--retries}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `api_timeout_secs` | int | `60` | Jumlah detik maksimal untuk menunggu respons dari setiap panggilan API RD. Naikkan nilainya kalau koneksimu lambat dan panggilan API sering timeout. |
| `download_timeout_secs` | int | `15` | Jumlah detik maksimal untuk menunggu saat menguji link download (dipakai saat tes kecepatan host dan verifikasi link). Ini bukan timeout untuk unduhan file yang sebenarnya. |
| `retries_until_failed` | int | `2` | Berapa kali panggilan API yang gagal akan dicoba ulang sebelum menyerah dan menandainya sebagai gagal. Nilai yang lebih tinggi membuat lebih tahan terhadap gangguan RD yang sebentar, tapi deteksi kegagalan jadi lebih lambat. |
| `retry_503_errors` | bool | `false` | Kalau `true`, request yang mendapat respons 503 (Service Unavailable) dari RD akan dicoba ulang. RD mengembalikan 503 saat maintenance atau kelebihan beban. Aktifkan ini kalau kamu sering mengalami error 503 yang biasanya cepat pulih sendiri. |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### Unduhan & Debugging {#downloads--debugging}

| Opsi | Tipe | Default | Deskripsi |
|------|------|---------|-----------|
| `get_downloads_limit` | int | `-1` | Jumlah maksimum entri download RD (non-torrent) yang akan diambil. `-1` berarti tidak ada batas (ambil semua), `0` berarti tidak mengambil download sama sekali, dan angka positif akan membatasinya. Berguna jika kamu pakai fitur unrestricting link langsung dari RD dan ingin file-file itu terlihat di zurg. Jika key ini tidak ditulis, nilainya `-1`. Nilai `0` yang ditulis secara eksplisit akan dihormati sebagai "cache none" dan akan mencatat peringatan saat startup, karena biasanya itu adalah config yang ditulis sebelum `0` berubah artinya. |
| `load_dumped_torrents` | bool | `false` | Saat `true`, data torrent dimuat dari folder `dump/` saat startup. Ini adalah mekanisme pemulihan. Jika zurg sebelumnya sudah menyimpan state torrent (misalnya saat crash), mengaktifkan ini akan mengembalikan state tersebut tanpa mengambil ulang semuanya dari RD. |
| `log_requests` | bool | `false` | Saat `true`, mencatat statistik detail untuk setiap permintaan download (path file, waktu respons, byte yang dikirim). Berguna untuk debug masalah streaming atau memahami pola akses. Log yang dihasilkan cukup banyak, jadi matikan di production. |
| `log_level` | string | `DEBUG` | Seberapa detail log yang dicatat: `DEBUG`, `INFO`, `WARN`, `ERROR` atau `FATAL`. Mengubahnya dari dasbor langsung berlaku, tanpa restart, dan semua komponen langsung diatur levelnya sekaligus. Ini menimpa environment variable `LOG_LEVEL`, jadi kontrol di dasbor tetap berfungsi pada container yang sudah menyertakan nilai tertentu. Hapus key ini agar pilihannya dikembalikan ke `LOG_LEVEL`. Nilai yang bukan nama level akan diabaikan dengan peringatan saat startup, bukan menyebabkan error fatal. |
| `traffic_alert_gb` | int | `0` | Memberi peringatan saat satu akun debrid memindahkan lebih dari sekian GiB lewat zurg dalam sehari (hari direset pukul 00:05 CET, mengikuti jatah Real-Debrid). Peringatan menyebutkan file mana yang paling banyak dipakai jam ini dan siapa yang membacanya, jadi scan library atau client yang menarik seluruh file akan terlihat saat sedang terjadi. zurg juga mencatat ringkasan file terbesar jam tersebut di awal setiap jam, dan satu baris untuk setiap pembacaan tunggal 1 GiB atau lebih, terlepas dari apakah alert diatur atau tidak. `0` mematikan alert. |
| `traffic_alert_webhook` | string | — | Webhook Discord tempat alert traffic juga dikirim. Rahasiakan: siapa pun yang punya URL-nya bisa mengirim pesan ke channel itu. |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
traffic_alert_gb: 500
```

## 7. Direktori & Filter {#7-directories--filters}

Tentukan direktori virtual yang mengatur torrent Anda berdasarkan aturan filter yang fleksibel. Setiap direktori muncul sebagai folder di mount Anda dan hanya menampilkan torrent yang cocok dengan filternya.

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### Opsi direktori {#directory-options}

| Opsi | Tipe | Default | Deskripsi |
|--------|------|---------|-------------|
| `group` | string | nama direktori itu sendiri | Direktori yang memakai group sama akan bersaing untuk setiap torrent: torrent masuk ke direktori pertama yang filter-nya cocok, dan tidak ada direktori lain dalam group itu yang mendapatkannya. Direktori di group yang berbeda masing-masing mendapat salinannya sendiri. |
| `group_order` | int | `0` (dianggap sebagai `1`) | Prioritas dalam group, makin kecil makin dulu. Jika urutannya sama, nama direktori yang menentukan. |
| `filters` | list | `[]` | Aturan yang menentukan apa saja yang boleh ada di sini. Torrent cocok dengan direktori jika **salah satu** entri dalam daftar cocok. Daftar kosong atau tidak ada akan cocok dengan semua torrent. |
| `only_show_the_biggest_file` | bool | `false` | Hanya tampilkan file terbesar dari setiap torrent, dan sembunyikan sampel, extra, serta file pendamping. |
| `only_show_files_with_size_lte` | int | `0` (nonaktif) | Sembunyikan file yang lebih besar dari jumlah byte ini. |
| `only_show_files_with_size_gte` | int | `0` (nonaktif) | Sembunyikan file yang lebih kecil dari jumlah byte ini. |
| `rex_shows` | string | `""` (tidak ada) | Dipakai bersama `rex_url`: judul library TV di rex yang menampilkan episode dari direktori ini. |
| `rex_movies` | string | `""` (tidak ada) | Dipakai bersama `rex_url`: judul library Movies di rex yang menampilkan film dari direktori ini, serta file apa pun yang tidak bisa dikenali rex sebagai episode. |
| `rex_music` | string | `""` (tidak ada) | Dipakai bersama `rex_url`: judul library musik di rex yang menampilkan file audio dari direktori ini (`.flac`, `.mp3`, `.m4a`, `.m4b`), termasuk audiobook. Tanpa opsi ini, tidak ada file audio yang dikirim ke rex. |
| `rex_photos` | string | `""` (tidak ada) | Dipakai bersama `rex_url`: judul library Photos di rex yang menampilkan komik dari direktori ini (`.cbz`, `.cbr`). Setiap komik menjadi album berisi halamannya, yang bisa dibuka satu per satu di Plex Web dan diputar sebagai slideshow. Plex for Android tidak menampilkan library foto. Komik tetap berupa file di mount. |

File yang dipaksa terlihat secara eksplisit di zurg akan mengabaikan ketiga opsi visibilitas di atas.

### Kondisi filter {#filter-conditions}

| Kondisi | Tipe | Deskripsi |
|-----------|------|-------------|
| `id` | string | ID torrent. Menentukan: tidak ada yang lain di entri yang sama yang diperiksa. |
| `regex` | string | Nama torrent cocok dengan pola. |
| `not_regex` | string | Nama torrent tidak cocok dengan pola. |
| `contains` | string | Nama torrent mengandung teks (tidak peka huruf besar/kecil). |
| `contains_strict` | string | Nama torrent mengandung teks (peka huruf besar/kecil). |
| `not_contains` | string | Nama torrent tidak mengandung teks (tidak peka huruf besar/kecil). |
| `not_contains_strict` | string | Nama torrent tidak mengandung teks (peka huruf besar/kecil). |
| `size_gte` | int | Total ukuran torrent minimal sebanyak byte ini. |
| `size_lte` | int | Total ukuran torrent paling banyak sebanyak byte ini. |
| `any_file_inside_regex` | string | Ada file di dalam torrent yang cocok dengan pola. |
| `any_file_inside_not_regex` | string | Ada file di dalam torrent yang tidak cocok dengan pola. |
| `any_file_inside_contains` | string | Ada file yang mengandung teks (tidak peka huruf besar/kecil). |
| `any_file_inside_contains_strict` | string | Ada file yang mengandung teks (peka huruf besar/kecil). |
| `any_file_inside_not_contains` | string | Ada file yang tidak mengandung teks (tidak peka huruf besar/kecil). |
| `any_file_inside_not_contains_strict` | string | Ada file yang tidak mengandung teks (peka huruf besar/kecil). |
| `any_file_inside_size_gte` | int | Ada file yang ukurannya minimal sebanyak byte ini. |
| `any_file_inside_size_lte` | int | Ada file yang ukurannya paling banyak sebanyak byte ini. |
| `added_within_hours` | int | Torrent ditambahkan dalam jumlah jam ini. |
| `added_within_days` | int | Torrent ditambahkan dalam jumlah hari ini. |
| `added_after` | string | Torrent ditambahkan pada atau setelah tanggal ini. Format `YYYY-MM-DD` atau `YYYY-MM-DD HH:MM`. |
| `added_before` | string | Torrent ditambahkan sebelum tanggal ini, dengan format yang sama. Jika dipasangkan dengan `added_after`, keduanya harus terpenuhi. |
| `has_episodes` | bool | Deteksi episode: penanda musim/episode atau hash CRC di nama torrent atau file, atau deretan file bernomor. Torrent yang file terbesarnya minimal 5x file terbesar kedua dibaca sebagai film dengan konten tambahan dan ditolak. |
| `is_music` | bool | Ada file yang berakhiran `.m3u`, `.mp3`, `.flac`, `.m4a` atau `.m4b`. |
| `has_tag` | string | Torrent memiliki tag ini. Bertindak sebagai gerbang: tanpa tag ini, tidak ada yang lain di entri yang bisa cocok. |
| `not_has_tag` | string | Torrent tidak memiliki tag ini, dan bekerja sebagai gerbang dengan cara yang sama. |
| `tags_match_all` | list | Semua tag yang tercantum ada (tidak peka huruf besar/kecil). |
| `tags_match_any` | list | Minimal satu tag yang tercantum ada. |
| `tags_missing_all` | list | Tidak ada satu pun tag yang tercantum. |
| `tags_missing_any` | list | Minimal satu tag yang tercantum tidak ada. |
| `provider` | string | Rilis dimiliki oleh akun ini, yang dinamai dengan `name`-nya di blok providers. Ini gerbang, bukan pencocokan: jika digabung dengan kondisi lain, keduanya harus terpenuhi. Jika berdiri sendiri, seluruh akun masuk ke direktori. |
| `not_provider` | string | Tidak ada akun yang memegang rilis ini yang merupakan akun ini. Bekerja sebagai gerbang dengan cara yang sama. |
| `and` | list | Setiap kondisi bersarang harus cocok. |
| `or` | list | Minimal satu kondisi bersarang harus cocok. |

Tag berasal dari analisis media — lihat [tags.md](tags.md) untuk daftar lengkapnya.

Pola ditulis sebagai `/expression/flags`, dengan flag berupa salah satu dari `i` (tidak peka huruf besar/kecil), `m` (multi-line), `s` (titik cocok dengan newline) dan `x` (extended). Nilai tanpa garis miring dikompilasi sebagai regular expression Go biasa.

Kondisi dalam satu entri filter **tidak** digabung dengan AND secara default — kebanyakan dari kondisi tersebut sudah membuat entri cocok begitu salah satunya terpenuhi. Gunakan blok `and:` yang eksplisit jika kamu ingin semuanya terpenuhi:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### Direktori per akun {#per-account-directories}

Di samping `__all__`, setiap akun yang dikonfigurasi mendapatkan direktori sendiri, dinamai sesuai akunnya: `__realdebrid__`, `__torbox__`, `__alldebrid__`, `__nzb__`. Akun-akun ini tidak dikonfigurasi. Mereka muncul karena akunnya ada, dan hilang ketika akunnya dihapus. Jika hanya ada satu akun, folder akunnya tidak ditampilkan di daftar root mount, dan `__all__` berisi file yang sama. Jalur HTTP dan WebDAV langsung seperti `/http/__realdebrid__/` tetap berfungsi. Lewat mount, jalur ini tidak lagi bisa diakses. Arahkan library atau script apa pun yang memakai `__<name>__` ke `__all__`.

Setiap direktori berisi apa pun yang dimiliki akunnya. Berbeda dengan direktori yang difilter, direktori ini juga menentukan ke mana pembacaan data diarahkan. Sebuah rilis yang dimiliki dua akun hanya menjadi satu entri di library. Tanpa pengaturan ini, setiap salinannya akan di-stream dari akun mana pun yang urutannya paling depan di blok `providers`:

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

Pin ini mengecualikan akun lain, bukan sekadar memprioritaskan akun yang disebut. Tidak ada failover diam-diam. Jika TorBox tidak bisa menyajikan file tersebut, pembacaan di bawah `__torbox__` akan gagal, alih-alih diam-diam menjawab dengan data dari Real-Debrid. Pembacaan di bagian lain mount tidak terpengaruh dan tetap failover seperti biasa.

Karena akun-akunnya tidak selalu memiliki konten yang sama, ada dua konsekuensi:

- Direktori hanya menampilkan file yang benar-benar dimiliki akunnya. Jika TorBox hanya mengunduh sebagian rilis yang sudah lengkap di Real-Debrid, `__torbox__` hanya menampilkan bagian tersebut.
- Status rusak dinilai per akun. File yang mati di Real-Debrid tetapi sehat di TorBox akan menghasilkan 404 di bawah `__realdebrid__`, dan bisa diputar di bawah `__torbox__`. Sementara itu, bagian lain mount tetap menyajikannya.

Direktori dinamai sesuai `name` akun, yang secara default sama dengan `type`-nya. Dua akun pada layanan yang sama perlu nama yang berbeda (`rd-main`, `rd-backup`), dan masing-masing mendapat direktori sendiri. Backend Usenet secara default bernama `nzb`, sehingga muncul sebagai `__nzb__`. Atur `name: usenet` pada entri provider tersebut jika kamu ingin menjelajah `__usenet__`.

Kamu bisa mengganti nama akun nanti. zurg akan melihat rilis yang sama di bawah nama baru dan memindahkannya ke sana. Direktori lama hilang bersama nama lamanya. Jika media server membaca direktori itu, arahkan ke direktori baru sebelum kamu mengganti nama.

Rilis yang sama muncul di setiap akun yang memilikinya, dan juga di direktori yang difilter. Karena itu, arahkan media server ke sebagian mount saja, bukan seluruhnya. Kalau tidak, server akan memindai konten yang sama berkali-kali.

Akun yang dinamai sama dengan direktori yang sudah dipakai zurg (`all`, `unplayable`, `dump`, `downloads`) tidak mendapat direktori per akun. zurg akan mencatat peringatan saat startup, alih-alih mengambil alih direktori yang sudah ada.

### Katalog debrid lokal {#local-debrid-catalogs}

Setiap entri penyedia debrid menerima blok `library` opsional:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: PRIMARY_RD_TOKEN
    download_tokens: # Optional bandwidth fallback.
      - SECOND_RD_TOKEN
    library:
      source: local
      path: torrents/rd-local
```

`source` secara default bernilai `provider`. Dengan `local`, file `.zurgtorrent` portabel menentukan keanggotaan, dan pemutaran memakai kredensial akun ini. `path` secara default bernilai `torrents/<resolved-account-name>` dan harus tetap berada di bawah `torrents/`. Direktori sumber yang sama tidak boleh dimiliki oleh dua akun yang aktif. Penyedia NZB tetap memakai pustaka `nzbs/` yang sudah ada.

Dalam contoh ini, kedua token RD melayani satu katalog di `torrents/rd-local/`. Token kedua tidak perlu entri penyedia atau direktori, dan pustaka torrent-nya tidak diimpor. `download_tokens` tetap memakai perilaku fallback bandwidth-nya; token ini tidak memaksa setiap unduhan lewat token kedua. Sebaliknya, dua entri penyedia lokal terpisah memiliki dua direktori katalog yang berbeda, meskipun keduanya Real-Debrid. Kredensial tetap berada di konfigurasi dan tidak pernah diekspor ke file portabel.

Lihat [pustaka portabel](../guides/local-libraries.md) untuk ekspor offline, migrasi
dari `dump/`, cara berbagi, dan batas pemutaran.

#### Memindahkan akun online ke perpustakaan lokal {#offloading-an-online-account-into-a-local-library}

Akun Real-Debrid atau AllDebrid yang memiliki katalognya sendiri (tanpa `source`, atau `source: provider`) bisa memindahkan rilis yang sudah selesai ke library lokal dan menghapusnya dari akun, sehingga slotnya kosong:

```yaml
providers:
  - name: rd
    type: realdebrid
    token: YOUR_RD_TOKEN
    library:
      offload_to: rd-local      # a local entry of the same type
      offload_after_mins: 30    # optional, 30 is the default

  - name: rd-local
    type: realdebrid
    token: YOUR_RD_TOKEN        # the same account
    library:
      source: local
```

| Kunci | Default | Keterangan |
|---|---|---|
| `library.offload_to` | none | Nama entri `source: local` yang aktif dan bertipe sama. Hanya akun `realdebrid` dan `alldebrid` yang menerimanya, karena hanya link dari kedua akun ini yang tetap jalan setelah torrent dihapus. Nilai ini tidak boleh menunjuk ke akun itu sendiri. |
| `library.offload_after_mins` | `30` | Berapa lama rilis harus sudah lengkap di akun sebelum dipindahkan otomatis. Dihitung dari saat zurg pertama kali melihatnya lengkap, jadi kalau restart, hitungannya mulai dari awal lagi. Butuh `offload_to`. |

Rilis hanya akan dipindahkan jika setiap file punya link yang bisa ditukar oleh akun lain, tidak ada yang sedang memperbaiki atau mengunduhnya, tidak ada job Sonarr atau Radarr di endpoint qBittorrent yang masih mencantumkannya, dan pemindahan itu menjaga nama folder serta setiap direktori tempatnya berada. Folder-nya tetap di tempat semula dan tidak ada pemindaian media server yang dimulai. Halaman rilis di dashboard bisa memindahkan satu rilis secara manual, dengan atau tanpa `offload_to`. Lihat [library portabel](../guides/local-libraries.md#offload-an-online-account-into-a-local-library) untuk urutan langkahnya, apa yang terjadi kalau salah satu gagal, dan bagaimana pemutaran lokal pada token bersama dilindungi.
