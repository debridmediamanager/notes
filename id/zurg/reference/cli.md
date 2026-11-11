# Command line

The binary zurg adalah server sekaligus kumpulan alat. Jalankan tanpa perintah apa pun untuk memulai server. Setiap perintah menerima `--help` dan menampilkan teks yang menjadi dasar halaman ini.

Jalankan perintah dari direktori kerja instance. zurg membaca `./config.yml` di sana kecuali kamu memberikan `--config`. Folder data dan log-nya juga dihitung relatif terhadap direktori tersebut.

```
zurg [flags]
zurg [command]
```

## Flag yang dipakai semua perintah {#flags-every-command-takes}

| Flag | Fungsinya |
|---|---|
| `-c`, `--config` | File konfigurasi yang akan dibaca. Defaultnya `./config.yml`. |
| `-v`, `--version` | Menampilkan build lalu keluar. Outputnya sama dengan `zurg version`. |
| `-h`, `--help` | Menampilkan bantuan untuk zurg atau untuk satu perintah. |

## Pengaturan {#setting-up}

### zurg setup

Menulis config dan mengunduh rclone dan ffprobe. Lalu mendaftarkan zurg agar berjalan otomatis. Ia akan menanyakan hal apa pun yang belum ada. `--dry-run` menampilkan rencananya dan tidak mengubah apa pun.

Kunci dan kata sandi dibaca dari file. Dengan begitu, semuanya tidak tersimpan di riwayat shell kamu.

| Flag | Fungsinya |
|---|---|
| `--provider` | Satu provider yang akan dikonfigurasi. Ulangi flag ini untuk lebih dari satu. Salah satu dari realdebrid, torbox, alldebrid, nzb, premiumize, debridlink, offcloud, torbox_nzb. torbox_nzb membaca kuncinya dari `--torbox-token-file` atau `TORBOX_TOKEN`, sama seperti torbox. |
| `--realdebrid-token-file` | Membaca token Real-Debrid dari file ini. Flag yang sama juga ada untuk `torbox`, `alldebrid`, `premiumize`, `debridlink` dan `offcloud`. |
| `--nntp-host` | Server berita untuk provider `nzb`. |
| `--nntp-port` | Port-nya. Defaultnya 563 dengan TLS dan 119 tanpa TLS. |
| `--nntp-tls` | Menggunakan TLS. Aktif secara default. |
| `--nntp-username` | Username akun berita kamu. |
| `--nntp-password-file` | Membaca kata sandi akun berita dari file ini. |
| `--nntp-connections` | Jumlah koneksi yang diizinkan untuk akun berita. Defaultnya 8. |
| `--mount-path` | Lokasi mount muncul. Defaultnya mengikuti konvensi untuk platform kamu. |
| `--port` | Port HTTP. Jika tidak diisi, nilai di config akan tetap dipakai. |
| `--service-name` | Nama service atau scheduled task. Defaultnya `zurg`. |
| `--service-scope` | `auto`, `user` atau `system`. Defaultnya `auto`. |
| `--service-user` | User tempat service sistem berjalan. |
| `--no-service` | Mengonfigurasi semuanya, tapi tidak mendaftarkan auto-start. |
| `--no-start` | Mendaftarkan service, tapi tidak menjalankannya. |
| `--skip-downloads` | Tidak mengunduh rclone atau ffprobe. |
| `--skip-prerequisites` | Melewati pengecekan FUSE untuk platform ini. |
| `--non-interactive` | Gagal alih-alih menanyakan input yang kurang. |
| `--dry-run` | Menampilkan rencana dan tidak mengubah apa pun. |

Setiap platform punya panduan sendiri.

- [Linux](../setup/linux.md)
- [macOS](../setup/macos.md)
- [Windows](../setup/windows.md)
- [Docker](../setup/docker.md)

### zurg doctor

Memeriksa apa yang sudah dipasang oleh setup. Alat ini membaca konfigurasi dan mencari rclone serta ffprobe. Setelah itu, alat ini memeriksa service, endpoint HTTP, dan mount. Jalankan ini dulu saat ada sesuatu yang tidak berfungsi.

| Flag | Fungsinya |
|---|---|
| `--working-dir` | Direktori kerja instance. Defaultnya direktori saat ini. |
| `--service-name` | Nama service yang akan diperiksa. Defaultnya `zurg`. |
| `--service-scope` | `auto`, `user` atau `system`. Defaultnya `auto`. |

### zurg service

Memasang dan mengatur auto-start tanpa menjalankan sisa setup.

| Command | What it does |
|---|---|
| `zurg service install` | Memasang auto-start dan langsung menjalankannya. Tambahkan `--start=false` untuk memasang tanpa menjalankan. |
| `zurg service uninstall` | Menghapus auto-start. Config dan data tetap ada. |
| `zurg service start` | Menjalankan service yang sudah terpasang. |
| `zurg service stop` | Menghentikannya. |
| `zurg service restart` | Memulai ulang. |
| `zurg service status` | Menampilkan status auto-start. |

Semua perintah di atas menerima flag yang sama.

| Flag | What it does |
|---|---|
| `--name` | Nama service atau scheduled task. Defaultnya `zurg`. |
| `--scope` | `auto`, `user` atau `system`. Defaultnya `auto`. |
| `--user` | User yang dipakai service sistem untuk berjalan. |
| `--working-dir` | Working directory tempat service dimulai. |
| `--executable` | Binary zurg yang dijalankan service. |

### zurg download-requirements

Mengunduh rclone dan ffprobe ke sebuah folder lalu menuliskan path-nya ke config. Setup melakukan ini untuk Anda kecuali Anda menjalankan `--skip-downloads`.

| Flag | Fungsinya |
|---|---|
| `--dir` | Tempat binary disimpan. Default-nya `bin`. |
| `--rclone-version` | Rilis rclone, misalnya `1.67.0`. Default-nya `latest`. |
| `--ffprobe-version` | Rilis ffprobe. Default-nya `latest`. |

### zurg update

Ini mengganti binary dengan nightly terbaru untuk sponsor. Akun GitHub yang dipakai harus punya akses sponsor dari [gatekeeper](https://gatekeeper.debridmediamanager.com/). Di dalam container, perintah ini menolak jalan, karena recreate berikutnya akan membuang binary yang baru. Tarik image baru di sana saja. `--force` tetap memperbarui.

Perintah ini masuk ke GitHub lewat GitHub CLI. Yang dipakai adalah GitHub CLI yang ada di PATH kamu, atau yang disimpan installer di `bin` di sebelah zurg. Sesi masuk yang disimpan GitHub CLI tanpa keyring tetap bisa dipakai, meskipun GitHub CLI-nya sudah tidak ada. `GITHUB_TOKEN` juga bisa dipakai. Kalau tidak menemukan satu pun, perintah ini akan menampilkan perintah installer untuk memasang lagi GitHub CLI.

### zurg version

Mencetak build-nya. `zurg --version` mencetak hal yang sama.

## Cadangan {#backups}

### zurg backup

Menulis file `.zurgbackup` yang berisi apa saja yang tidak bisa dibuat ulang dari tempat lain. Isinya adalah config beserta token-nya, dan setiap `data/*.zurgtorrent` beserta tag dan tautan akunnya. File ini juga menyimpan `__magic__` store di `data/local/` dan NZB sumber di `nzbs/`. Cache, snapshot Plex, dan log tidak disertakan supaya ukuran backup tetap sebesar data yang dilindunginya.

Instance tidak perlu sedang berjalan. Jadi aman untuk dijadwalkan. File ini berupa gzip tar yang berisi token kamu. Simpan seperti kamu menyimpan password.

| Flag | Fungsinya |
|---|---|
| `-o`, `--out` | Lokasi tujuan penulisan file. Defaultnya `zurg-<timestamp>.zurgbackup` di direktori saat ini. |
| `--include-caches` | Juga menyertakan metadata turunan dan byte yang sudah di-cache agar restore lebih cepat. Snapshot Plex dan log tetap tidak disertakan. Ukurannya bisa jadi besar. |

### zurg restore-backup

Mengekstrak `.zurgbackup` ke direktori saat ini. Setiap file dikembalikan ke path asalnya. Hentikan zurg dulu. Proses restore menulis file yang juga sedang ditulis oleh instance zurg yang berjalan.

```
zurg restore-backup my-backup.zurgbackup
```

Konfigurasi yang sudah ada di direktori dibiarkan begitu saja. File itu berisi token yang menjadi tumpuan seluruh library. Kalau mau menimpanya, pakai `--force-config`.

## Pengukuran {#measuring}

### zurg benchmark-my-setup

Benchmark ini membaca byte asli seperti cara player membacanya, lalu melaporkan rentang hasilnya, bukan cuma satu angka. Prosesnya ada tiga fase. Pertama, tiap akun dites sendiri-sendiri. Angka ini yang bisa kamu bandingkan dengan janji layanannya. Kedua, semua akun dites bersamaan. Akun yang masing-masing bisa 70 MiB/s saat sendirian tapi cuma 25 MiB/s saat bersamaan berarti mereka berbagi satu uplink yang sudah penuh. Ketiga, benchmark membaca lewat mount rclone. Selisihnya dengan fase pertama adalah biaya dari FUSE dan VFS.

Sampel diambil di offset acak. Setiap lapisan di bawahnya melakukan caching, dan kalau satu offset dibaca ulang, yang terukur nanti cache, bukan koneksinya.

Benchmark ini tidak menambah atau menghapus apa pun. Tapi benchmark ini memakai bandwidth kamu. Tiap akun membaca sample size dikali iteration count, dua kali. Fase mount ditambahkan di atasnya.

| Flag | Fungsinya |
|---|---|
| `-n`, `--iterations` | Jumlah sampel per akun per fase. Defaultnya 3. |
| `--sample-mb` | MiB yang dibaca per sampel. Defaultnya 128. Pakai 1024 untuk melewati ramp read-chunk rclone supaya dapat angka mount yang stabil. |
| `--provider` | Benchmark hanya akun dengan nama ini. Bisa diulang. |
| `--skip-concurrent` | Melewati fase semua akun. |
| `--skip-mount` | Melewati fase mount. |
| `--json` | Menampilkan laporan dalam format JSON. |

### zurg network-test

Mengukur seberapa cepat host ini mencapai setiap server unduh Real-Debrid melalui IPv4 dan IPv6. Hasilnya disimpan ke `logs/network-test.log` dan ke `data/`, tempat server membacanya untuk memilih host. Atur `PROXY` di environment untuk menguji lewat proxy.

| Flag | Fungsinya |
|---|---|
| `-t`, `--test-url` | URL file yang path-nya diambil dari setiap server, bukan file speed test milik Real-Debrid sendiri. |

## Plex

Ketiga ini bekerja dengan server Plex di host ini. Konfigurasi Plex dulu. Lihat [Plex Integration](config.md#plex-integration).

### zurg plex-settings

Melaporkan pengaturan Plex yang penting untuk mount dan memperbaiki apa yang diizinkan oleh policy. Default Plex mengasumsikan disk lokal. Salah satunya menghapus library ketika scan mengalami gangguan sesaat. Yang lain membuat Plex men-decode setiap file yang dimilikinya. [plex.md](../guides/plex.md#recommended-plex-settings) menjelaskan masing-masing.

| Flag | Fungsinya |
|---|---|
| `-p`, `--policy` | `off`, `warn`, `guard` atau `enforce` untuk run ini. Defaultnya adalah `plex_settings_policy` dari config. Jika memakai yang lebih ketat, kamu bisa melihat pratinjaunya sebelum mengadopsinya. |

### zurg plex-drift

Membaca database Plex tanpa menulis apa pun ke dalamnya, lalu memeriksa setiap file yang ditunjuknya di bawah mount. Hasilnya melaporkan file-file yang sudah tidak ada. Jalankan sebelum library scan. Scan yang menemui file-file itu akan menghapusnya dari library. Dengan mengetahui jumlahnya lebih dulu, scan menjadi keputusan yang disengaja dan bukan sebuah pertaruhan.

Ini membutuhkan `plex_database_path` dan Plex berada di host yang sama.

### zurg plex-backups

Menampilkan daftar snapshot database Plex yang disimpan zurg, dengan yang paling baru di atas. Setiap baris menunjukkan kapan snapshot itu diambil, ukurannya, dan berapa banyak item yang ada di setiap library pada saat itu. Jumlah item tersebut diambil langsung dari snapshot-nya. Jadi daftar ini menunjukkan apa yang benar-benar bisa dipulihkan dari setiap snapshot. [Plex Library Maintenance](config.md#plex-library-maintenance-same-host-only) menjelaskan kapan zurg membuat snapshot tersebut.

## Berbagi {#sharing}

### zurg export-torrents

Membuat file `.zurgtorrent` portabel yang menjelaskan rilismu tanpa akunmu di dalamnya. Tidak ada kredensial yang dimasukkan. Tidak ada torrent id, state perbaikan, atau link CDN juga. Tidak ada provider yang dihubungi.

Alat ini membaca `data/*.zurgtorrent` atau file dump lama. Berikan file atau folder untuk mengekspor hanya file-file itu. Penerima menaruh file di `torrents/<their-account>/` dan mengatur akun tersebut ke `library.source: local`. [portable-libraries.md](../guides/local-libraries.md) menjelaskan sisi penerima.

| Flag | Fungsi |
|---|---|
| `--provider` | Mengekspor rilis yang dimiliki akun yang dikonfigurasi ini. |
| `--output` | Lokasi file portabel disimpan. |
| `--replace` | Mengganti ekspor yang sudah ada dengan hash yang sama. |
| `--skip-invalid` | Melewati dan menghitung entri yang tidak bisa dibaca saat ekspor massal. |

### zurg nzb-share

Membuat salinan terbagi dari NZB kamu yang bisa dipublikasikan. Hasilnya adalah folder berisi `manifest.json` dan satu `.nzb.gz` untuk setiap rilis, dinamai berdasarkan content hash. Setiap NZB dibersihkan dulu. Komentar, DOCTYPE, dan metadata watermark dihapus. Nama file asli juga dihapus. Poster dan tanggal ikut dihapus, dan setiap file mendapat newsgroup tetap yang sama, karena beberapa indexer mengubah ketiganya setiap kali file diunduh. Stempel akun yang disembunyikan indexer di dalam subject, title, atau password akan dipotong. Yang kamu publikasikan hanya menamai rilisnya, bukan akun yang mengunduhnya. Password arsip asli tetap dibiarkan, karena penerima membutuhkannya untuk membuka rilis.

Publikasikan folder itu di tempat statis mana pun. Repositori git bisa, situs Pages juga bisa, atau `rclone serve`. Audit tentang apa saja yang dihapus tetap ada di mesin kamu dan dicetak di sini. Audit ini berisi identifier yang justru ingin dihapus oleh proses pembersihan.

| Flag | Fungsinya |
|---|---|
| `--from` | Folder pantau yang akan dibagikan. Dijelajahi secara rekursif. Default-nya `nzbs`. |
| `--out` | Folder output. Default-nya `nzb-share-<timestamp>`. |
| `--title` | Judul yang dicatat di dalam manifest. |
| `--filter` | Hanya membagikan path sumber yang cocok dengan ekspresi reguler ini. |

Dashboard juga bisa menyajikan share. Lihat [Berbagi NZB publik](config.md#public-nzb-sharing).

### zurg nzb-sync

Menarik pustaka bersama ke dalam folder pantau Anda. Alat ini mengikuti `manifest.json` milik sebuah share dari URL atau path lokal. Setiap NZB diperiksa terhadap hash di manifest sebelum ditulis. Akun berita Anda sendiri yang mengambil byte-nya.

```
zurg nzb-sync https://example.com/share/manifest.json
```

Alat ini hanya menambah. Entri yang sudah ada akan dilewati dan share tidak pernah menghapus apa pun. Dua share dengan rilis yang sama akan dideduplikasi berdasarkan hash konten.

| Flag | Fungsinya |
|---|---|
| `--into` | Folder pantau tempat menulis. Defaultnya `nzbs`. |
| `--dry-run` | Melaporkan apa yang akan ditulis dan tidak menulis apa pun. |

## Menghapus akun Real-Debrid {#clearing-a-real-debrid-account}

Ini dua perintah yang menghapus semua item dari satu jenis di akun Real-Debrid. Penghapusannya tidak bisa dibatalkan. Keduanya hanya bekerja untuk Real-Debrid.

Keduanya meminta cookie `auth` dari sesi browser Real-Debrid yang sudah login, bukan API token Anda. Keduanya mencetak satu baris JavaScript yang menampilkan cookie itu. Jalankan di console browser pada real-debrid.com, lalu tempel hasilnya.

| Perintah | Fungsinya |
|---|---|
| `zurg clear-torrents` | Menghapus setiap torrent di akun. |
| `zurg clear-downloads` | Menghapus setiap download di akun. Itu adalah tautan unrestricted. |

## Penyelesaian shell {#shell-completion}

`zurg completion bash` mencetak skrip completion untuk bash. Hal yang sama juga berlaku untuk `zsh`, `fish`, dan `powershell`. `zurg completion <shell> --help` memberi tahu kamu di mana skrip tersebut harus diletakkan.
