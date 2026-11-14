# Usenet untuk pemula: apa yang perlu dibeli dan bagaimana cocoknya dengan zurg {#usenet-for-beginners-what-to-buy-and-how-it-fits-with-zurg}

Untuk streaming Usenet dengan zurg, kamu butuh akun **Usenet provider** yang menyimpan file, dan **file NZB** yang memberi tahu di mana setiap rilis berada. **Indexer** adalah situs pencarian untuk NZB, tapi kamu tidak wajib membelinya: tab **Usenet** di DMM bisa mencari NZB untuk film atau serial apa pun. zurg lalu memutar rilis itu langsung dari provider kamu, tanpa perlu mengunduh apa pun dulu.

## Tiga bagian utamanya {#the-three-pieces}

| Bagian | Apa itu | Apakah kamu harus bayar? |
|---|---|---|
| Provider, atau news server | Layanan yang menyimpan postingannya. Kamu dapat alamat server, username, password, dan jumlah koneksi. zurg membaca dari sini. | Ya. Ini satu-satunya yang harus kamu beli. |
| NZB | File kecil yang berisi daftar potongan dari satu rilis, mirip seperti file `.torrent` untuk torrent. | Tidak. |
| Indexer | Situs pencarian yang membuat NZB. Sonarr, Radarr, dan Prowlarr mencari di sini. | Opsional. |

Sebuah rilis di Usenet diposting sebagai ribuan potongan kecil. NZB mencatat daftarnya, provider kamu menyajikannya, dan zurg menyusunnya kembali menjadi video yang diminta player kamu.

## Yang kamu butuhkan {#what-you-need}

1. **Sponsorship zurg.** Usenet ada di build nightly zurg, yang datang dengan [sponsorship](sponsorship.md). zurg publik gratis hanya mendukung Real-Debrid.
2. **Satu akun penyedia Usenet.** Dua angka penting saat kamu membandingkan paket:
   - **Retention**: berapa hari ke belakang server menyimpan postingan. Film dan acara lama butuh retention yang lebih panjang.
   - **Connections**: berapa koneksi yang diizinkan paket dalam sekali waktu. zurg membaca sesuai angka itu, jadi isi konfigurasimu dengan angka asli dari paketmu.
3. **NZB.** Simpan dari tab Usenet di DMM, ambil dari indexer kamu sendiri, atau biarkan Sonarr, Radarr, atau zurg yang mencarinya.

Kamu tidak perlu:

- **Download client** seperti SABnzbd atau NZBGet. zurg yang men-streaming release-nya. Untuk Sonarr dan Radarr, zurg berperan sebagai SABnzbd itu sendiri: lihat [Sonarr & Radarr untuk Usenet](../zurg/guides/sonarr-radarr.md).
- **Disk untuk seluruh release.** zurg hanya mengambil bagian yang menutupi apa yang sedang diputar. File remux 60 GB tidak butuh disk 60 GB.
- **Alat untuk unpack atau repair.** zurg memutar langsung dari dalam set RAR dan membangun ulang bagian yang hilang dari file PAR2 release itu sendiri.
- **Akun debrid.** Usenet bisa berjalan sendiri, atau berdampingan dengan Real-Debrid dan TorBox dalam library zurg yang sama.
- **Keanggotaan indexer**, setidaknya untuk memulai. Lihat [pertanyaan tentang indexer](#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers) di bawah.

Layak ditambahkan nanti: **penyedia kedua.** Postingan yang hilang di satu penyedia sering masih ada di penyedia lain. Saat satu penyedia tidak punya sebagian data, zurg meminta ke penyedia berikutnya. Dengan hanya satu penyedia, zurg harus membaca seluruh release untuk membangun ulang bagian itu. Lihat [a second news server](../zurg/providers/usenet.md#a-second-news-server-is-worth-more-than-it-looks).

## Bagaimana zurg menjalankannya {#how-zurg-plays-it}

1. Sebuah NZB masuk ke folder `nzbs/` milik zurg. Kamu yang memasukkannya, atau Sonarr, Radarr, atau zurg sendiri yang melakukannya.
2. Dalam waktu satu-dua detik, zurg membacanya dan mencantumkan rilisan tersebut di pustakanya, dinamai sesuai NZB-nya.
3. Kamu tekan play di Plex, Jellyfin, atau rex. zurg mengambil potongan-potongan untuk posisi itu dari provider kamu lalu menyerahkannya. Kalau kamu loncat ke depan, zurg mengambil dari posisi baru itu.

Tidak ada yang menunggu sampai unduhan selesai. Untuk menyiapkannya langkah demi langkah, ikuti [Usenet dengan zurg](../zurg/guides/usenet.md). Pengaturan provider dan detail Docker ada di [Usenet provider](../zurg/providers/usenet.md).

## Di mana posisi DMM {#where-dmm-fits}

Setiap halaman film dan acara di [DMM](https://debridmediamanager.com) punya tab **Usenet** di sebelah **Torrents**. Tab ini menampilkan rilis Usenet dari judul tersebut dari indexer DMM. Siapa pun yang sudah masuk ke DMM bisa memakainya.

![Tab Usenet DMM untuk Night of the Living Dead (1968), sudah masuk dengan TorBox Pro](../assets/usenet-for-beginners/01-dmm-usenet-tab.webp)

Apa yang bisa dilakukan tiap baris bergantung pada akun yang kamu pakai untuk masuk:

| Tombol | Fungsinya | Perlu |
|---|---|---|
| Ikon file di ujung, atau **NZB** jika itu satu-satunya tombol | Menyimpan NZB, dinamai sesuai rilisnya, dengan watermark indexer dihapus. Taruh di folder `nzbs/` milik zurg. | Masuk ke DMM |
| **Send** | DMM mengambil rilis dari Usenet dan menambahkannya ke pustaka Real-Debrid kamu. Kamu tidak perlu akun Usenet untuk ini. | Real-Debrid |
| **TorBox** | Mengirim NZB ke TorBox, yang akan mengunduh rilis itu untuk kamu. | TorBox Pro, lihat [TorBox di DMM](../dmm/torbox.md) |

Sponsor mendapat dua fitur tambahan:

- **zurg mencari di indexer DMM untuk kamu.** Dengan DMM API key kamu di config zurg sebagai `dmm_api_key` dan tanpa indexer sendiri, zurg akan mencari di indexer DMM saat mengambil [daftar wanted DMM](../zurg/guides/dmm-wanted.md) atau [watchlist](../zurg/guides/acquisition.md) kamu.
- **DMM sebagai indexer Newznab** untuk Sonarr, Radarr dan Prowlarr. Atur di [halaman Newznab](https://debridmediamanager.com/newznab) milik DMM. Setiap key mendapat 30 pencarian dan 15 grab per menit, serta 250 grab per hari.

## Ketika ada yang salah {#when-something-is-wrong}

| Yang Anda lihat | Yang harus dilakukan |
|---|---|
| Log zurg: `Cannot reach the news server for nzb` | zurg tidak bisa masuk ke penyedia Anda. Periksa alamat server, username, dan password. Port `563` dipakai dengan `tls: true`, port `119` dengan `tls: false`. |
| Log zurg: `Usenet account <name> is not reachable` | Salah satu dari beberapa akun gagal, sementara yang lain tetap jalan. Perbaiki detail akun tersebut. |
| Penyedia Anda menolak koneksi, misalnya `502 Too many connections` | Nilai `connections` di konfigurasi zurg lebih tinggi dari yang diizinkan paket Anda, atau ada aplikasi lain yang memakai login yang sama. Turunkan ke jumlah sesuai paket Anda. |
| Sebuah rilis muncul sebagai `indexer_download_48213` atau sejenisnya | zurg memberi nama rilis sesuai file NZB-nya. Ganti nama `.nzb` menjadi nama rilisnya. |
| Sebuah file di dalam rilis punya nama acak | Posting tersebut menyembunyikan nama file-nya dan zurg tidak bisa mendapatkannya kembali. Pilih rilis lain. |
| Log zurg: `rar: RAR4 header-encrypted archives are not supported` | Arsip rilis itu dikunci dengan format lama yang tidak bisa dibuka zurg. Pilih rilis lain. |
| Playback tersendat atau ada celah yang diputar senyap | Potongan rilis hilang dari penyedia Anda. zurg membangun ulang potongan tersebut dari file PAR2 jika posting-nya punya file itu. Penyedia kedua bisa mengatasi sebagian besar masalah ini. |
| DMM: **No Usenet results found.** | Indexer DMM tidak punya hasil untuk judul ini. Coba tab **Torrents**, atau indexer Anda sendiri. |

Tabel pemecahan masalah lengkap ada di [Usenet dengan zurg](../zurg/guides/usenet.md#troubleshooting). Masih buntu? Tanyakan di forum **zurg-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Mendapatkan bantuan](remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Pertanyaan {#questions}

### Bisakah seseorang menjelaskan sistem Usenet kepada saya? {#can-someone-explain-the-usenet-system-to-me}

Usenet adalah jaringan server berita yang menyimpan postingan. Sebuah rilis diposting sebagai ribuan potongan kecil. Provider menjual akses ke server-servernya, NZB berisi daftar potongan dari satu rilis, dan indexer adalah tempat kamu mencari NZB. zurg mengambil NZB dan memutar rilis itu langsung dari provider kamu.

### Apakah harus memiliki keanggotaan seumur hidup dengan indexer Usenet? {#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers}

Tidak, kamu tidak perlu indexer apa pun untuk mulai. Tab Usenet di DMM akan mencari NZB untukmu, dan zurg milik sponsor bisa mencari langsung di indexer milik DMM. Kalau kamu ingin indexer sendiri untuk hasil yang lebih banyak, indexer Newznab apa pun bisa dipakai di zurg, Sonarr, dan Radarr, apa pun paket yang kamu pilih.

### Bagaimana nama file seharusnya diatur untuk Usenet? {#how-are-the-files-supposed-to-be-named-for-usenet}

Beri nama NZB sesuai rilisnya, misalnya `Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb`. zurg memakai nama itu sebagai nama folder rilisnya, dan itulah yang dicocokkan oleh Plex dan aplikasi lainnya. NZB yang sudah memuat nama di dalamnya akan memakai nama tersebut. Tombol NZB di DMM sudah otomatis menyimpan file dengan nama rilisnya.

### Apakah zurg mendukung Usenet? {#does-zurg-do-usenet}

Ya, di nightly build untuk sponsor. Isi detail provider kamu, masukkan NZB ke `nzbs/`, dan langsung bisa diputar. [Usenet dengan zurg](../zurg/guides/usenet.md) menjelaskan langkah-langkahnya.

### Apa itu TorBox NNTP? {#what-is-torbox-nntp}

Paket Pro TorBox punya dua fitur Usenet. Halaman harganya menunjukkan Usenet hanya ada di Pro (dicek 14 November 2026).

- **Unduhan Usenet yang di-host.** TorBox mengunduh seluruh rilis untuk kamu dan menyajikannya seperti unduhan TorBox biasa. Kirim NZB dari tab Usenet di DMM atau dari provider `torbox_nzb` di zurg. Kamu tidak perlu login news server. Lihat [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md).
- **Login news server (NNTP).** Pakai di zurg seperti provider lain. Batasnya 10 koneksi. Hasil pengukuran September 2026 menunjukkan koleksi yang ditemukan lebih sedikit dibanding tiga provider berbayar lain, jadi paling cocok sebagai cadangan. Lihat [Server berita TorBox](../zurg/providers/torbox-news-server.md).

### Bisakah saya menggunakan satu akun Usenet di dua tempat? {#can-i-use-one-usenet-account-in-two-places}

Sebaiknya jangan. Dua aplikasi yang memakai satu login akan berbagi koneksi dan saling mengeluarkan. Server bisa memutus koneksi yang lebih lama untuk memberi jalan ke koneksi yang lebih baru. Beberapa penyedia juga melarang berbagi akun dalam syarat layanannya. Jadi, berikan setiap zurg akunnya sendiri.
