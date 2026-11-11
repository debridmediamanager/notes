# Pertanyaan tentang rex {#rex-questions}

Jawaban singkat untuk pertanyaan yang sering muncul sebelum kamu memasang rex, dan juga setelahnya. Setiap jawaban memiliki tautan ke panduan yang berisi detailnya.

## Sebelum kamu memasang {#before-you-install}

### Apa itu rex? {#what-is-rex}

A media server untuk aplikasi Plex resmi yang tidak menyimpan file apa pun. Aplikasi Anda akan melihat satu server Plex tambahan dengan poster, musim, riwayat tontonan, dan Continue Watching. Sebuah **source** memberi tahu rex apa saja yang ada di perpustakaan dan melayani setiap file. rex memutarnya langsung saat Anda menekan play. Tidak ada yang diunduh dulu.

Ini adalah server tersendiri. Ini bukan plugin Plex Media Server dan tidak memerlukannya. Jalankan di samping Plex jika Anda ingin keduanya. [Install rex](any-source.md#step-1-install-rex) menjelaskan nama-nama yang dipakai, dan [Move from Plex to rex](from-plex.md) membahas kedua jalurnya.

### Berapa biayanya? {#what-does-it-cost}

rex gratis untuk penggunaan pribadi tanpa paket berbayar. Kode sumbernya bersifat publik di bawah lisensi PolyForm Noncommercial. Penggunaan komersial tidak diizinkan. Setiap build bisa diunduh secara publik di [GitHub Releases](https://github.com/debridmediamanager/rex/releases), kecuali build Android, yang hanya tersedia di dalam aplikasi [zurg+rex Android](../zurg/guides/android.md) khusus sponsor, yaitu server Plex yang berjalan di ponsel Anda.

Beberapa hal di sekitarnya mungkin berbayar:

| | |
|---|---|
| [rex-stremio](stremio.md), aplikasi Anda sendiri atau addon sebagai sumbernya | Gratis |
| zurg nightly, sumber untuk pustaka debrid atau Usenet | Keuntungan untuk [sponsor DMM](https://gatekeeper.debridmediamanager.com) |
| Kunci API DMM, untuk kecocokan persis DMM di zurg | Opsional, juga dari menjadi sponsor DMM |
| Image Docker rex | Gratis dan publik, untuk Linux: [rex di Docker](any-source.md#run-rex-in-docker) |

### Apakah akun Plex saya berisiko? {#is-my-plex-account-at-risk}

rex bukan buatan Plex, dan Plex bisa mengambil tindakan terhadap akun yang mendaftarkannya. Gunakan **akun Plex gratis baru** yang khusus dibuat untuk rex, lalu bagikan ke akun Anda sendiri. Riwayat tontonan, teman, dan Plex Pass Anda tetap ada di akun Anda sendiri. [Tambahkan ke akun Plex](any-source.md#step-3-add-it-to-a-plex-account) menjelaskan langkahnya. Gunakan rex dengan risiko Anda sendiri.

### Aplikasi Plex mana saja yang bisa dipakai? {#which-plex-apps-work}

Seberapa jauh setiap aplikasi Plex sudah dicoba dengan rex:

| Aplikasi | Diuji |
|---|---|
| Plex Web (app.plex.tv) | Paling banyak: menelusuri, memutar, mengonversi, subtitle, musik, Live TV, dan memutar dari luar rumah dengan akun gratis di kedua sisi |
| Plex for Android (ponsel) | Di Pixel 6: memutar, mengonversi, dan [mengunduh dari penyedia Anda](direct-download.md). Di emulator: musik dan Live TV |
| Plexamp | Di emulator Android: menelusuri dan memutar pustaka musik, dengan gambar artis dan playlist |
| Plex for iOS | Di iPad: memutar dan mengonversi. Dolby Vision punya bug aplikasi (lihat di bawah) |
| Plex for Apple TV | Memutar, termasuk saluran live di pustaka |
| Plex Desktop | Plex for Mac: memutar dan mengonversi |
| Plezy | Di Pixel 6: memutar, dan mengunduh dari penyedia Anda |
| Plex HTPC | Belum diuji |
| Plex for Android TV, NVIDIA Shield, Google TV | Belum diuji |
| Plex for Roku | Belum diuji |
| Aplikasi Smart TV (Samsung, LG dan lainnya) | Belum diuji |
| Infuse | Belum diuji |

Dari luar rumah, hanya Plex Web yang sudah diuji.

### Apakah bisa memutar 4K, HDR, dan Dolby Vision? {#does-it-play-4k-hdr-and-dolby-vision}

Ya. File diputar dalam kualitas aslinya: rex memberikan file ke aplikasi apa adanya, lalu aplikasi yang memutuskan apa yang bisa ditampilkan. Jika aplikasi tidak bisa memutar file apa adanya, rex mengonversinya, asalkan FFmpeg sudah diatur ([Converting video](any-source.md#converting-video-optional)). Konversi mengubah HDR dan Dolby Vision menjadi gambar standar (Settings, Transcoder, **Enable HDR tone mapping**, aktif secara default), di chip grafis jika memungkinkan. Dengan runtime OpenCL dari Intel terpasang, mesin Intel kecil (J4105) bisa mengonversi 4K HDR10 dan Dolby Vision profile 5 ke 1080p kira-kira secara real time. Tanpa FFmpeg, file yang tidak bisa diputar aplikasi akan menampilkan "This server is not powerful enough to convert video". Jika setiap judul menampilkan pesan itu di setiap perangkat, FFmpeg bukan solusinya: lihat [Nothing plays](#nothing-plays-or-every-app-says-it-is-not-powerful-enough).

**Plex for iOS dan Dolby Vision.** Plex for iOS 2026.20.0 berhenti di 0:00 saat memutar file Dolby Vision apa adanya. Real Plex Media Server yang melayani file yang sama juga macet dengan cara yang sama, jadi masalahnya ada di aplikasinya. File HDR10 dan SDR 4K bisa diputar.

### Apakah saya butuh Plex Pass? {#do-i-need-plex-pass}

Tidak. rex memberitahu aplikasi Plex bahwa akun tempat rex terdaftar memiliki Plex Pass, jadi memutar dari luar rumah dan mengonversi video tetap berfungsi dengan akun gratis. Memutar dari luar rumah sudah diuji di Plex Web dengan akun gratis di kedua sisi; aplikasi lain belum diuji dari luar rumah. Edisi film, Dashboard, Downloads, lewati intro dan kredit, serta sisa [Movie and TV capabilities](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities) juga berfungsi. Aplikasi tetap bisa menerapkan aturannya sendiri.

### Bisakah saya mengunduh untuk ditonton offline? {#can-i-download-for-offline-viewing}

Unduhan **Downloads** di aplikasi Plex sudah tersedia. rex menyiapkan unduhan di mesinnya sendiri, baik sebagai file asli maupun yang sudah dikonversi dengan FFmpeg, lalu menyimpannya di folder di sebelah `rex.db` sampai aplikasi mengambilnya. Akun tempat rex didaftarkan selalu bisa mengunduh. Orang yang Anda bagikan akses juga perlu izin unduh di share mereka ([Share rex](sharing.md#what-each-person-may-see-and-do)). Aplikasi tetap bisa menerapkan aturannya sendiri. Unduhan yang dikonversi tidak menyertakan subtitle teks. Menyimpan unduhan di ponsel dan menontonnya secara offline belum pernah diuji.

### Bisakah beberapa orang memakainya, masing-masing dengan riwayatnya sendiri? {#can-several-people-use-it-each-with-their-own-history}

Ya. Setiap orang yang Anda bagikan rex-nya akan masuk dengan akunnya sendiri dan mendapatkan status tontonan, Continue Watching, rating, dan playlist mereka sendiri. Masing-masing bisa menyalin riwayat tontonannya dari server Plex lama ([Bring your watch history](import-watched.md)). [Share rex with family and friends](sharing.md) berisi langkah-langkahnya, termasuk untuk managed users anak-anak.

### Perangkat keras apa yang dibutuhkan? {#what-hardware-does-it-need}

Mesin yang selalu menyala, dengan Linux (amd64 atau arm64, glibc 2.35 ke atas, jadi Ubuntu 22.04 ke atas), macOS (Intel atau Apple Silicon), atau Windows 64-bit. Bisa juga aplikasi zurg+rex untuk Android di perangkat Android/Google TV (64-bit sampai build nightly 11 November 2026), yang menjalankan zurg dan rex sekaligus (khusus sponsor; lihat [panduan Android](../zurg/guides/android.md)).

**Memori:** siapkan 1 GB. Dengan perpustakaan 4.062 film dan 656 serial, rex memakai kurang dari 500 MB saat start dan sekitar 730 MB saat perpustakaan dijelajahi. Konversi video butuh tambahan memori lagi.

**Disk:** tidak perlu untuk film. rex menyimpan perpustakaannya di `rex.db`. Unduhan dan gambar yang dibuat analisis (pratinjau seek, gambar bab) juga disimpan di sebelahnya, kalau kamu memakainya.

**Konversi:** hanya dengan FFmpeg. Chip grafis membuatnya cepat: film 1080p yang dikonversi di chip Intel kecil mulai dalam sekitar 2 detik. Chip mana yang dipakai rex di tiap sistem ada di [Per platform](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#by-platform): di macOS, konversi selalu dilakukan di prosesor.

### Apakah rex membaca file lokal saya? {#does-it-read-my-local-files}

Tidak. rex tidak pernah memindai folder atau disk dan tidak butuh mount. Setiap file datang dari sumber melalui HTTP. File di disk Anda sendiri tetap bisa dipakai: sesuatu harus menyajikannya dan memberi tahu rex tentang file tersebut, seperti yang ditunjukkan di [rex dengan aplikasi Anda sendiri](any-source.md).

### Apakah bisa dipakai dengan Usenet? {#does-it-work-with-usenet}

Ya, lewat sumber yang membaca Usenet, seperti zurg. rex tidak pernah berbicara langsung dengan penyedia Usenet: sumber membaca file-nya dan menyajikannya ke rex seperti file lainnya. Atur zurg untuk itu dengan [Usenet](../zurg/guides/usenet.md) dan arahkan ke rex seperti di [rex dengan zurg](with-zurg.md).

### Apakah saya butuh zurg? {#do-i-need-zurg}

Tidak. zurg hanyalah salah satu sumber di antara yang lain. rex menerima apa pun yang berbicara dengan feed API-nya:

- [rex dengan aplikasi Anda sendiri](any-source.md): aplikasi apa pun yang menyajikan file melalui HTTP
- [rex dengan add-on Stremio Anda](stremio.md): katalog dari add-on Stremio
- [rex dengan zurg](with-zurg.md): akun debrid Anda atau Usenet
- [Membangun add-on rex](addons.md): video rumahan, rekaman atau saluran, dengan program buatan Anda sendiri, serta tiga [tutorial](addon-home-videos.md) sebagai titik awal

Beberapa sumber dapat mengisi pustaka Movies dan TV yang sama.

### Apakah saya perlu membuka port? {#do-i-need-to-forward-a-port}

Tidak di rumah. Aplikasi Plex di jaringan rumah Anda menemukan rex tanpa perlu mengubah router. app.plex.tv juga berfungsi melalui alamat HTTPS yang diberikan [rex-direct](any-source.md#rex-direct) untuk rex yang sudah diklaim.

rex memerlukan alamatnya sendiri untuk menonton dari luar rumah atau untuk rumah tangga lain. Cara paling sederhana adalah satu port forward ([rex-direct](any-source.md#rex-direct)). Dengan IPv6 dan tanpa IPv4 publik, gunakan [rex-direct over IPv6](any-source.md#rex-direct-over-ipv6). [Tailscale serve](any-source.md#tailscale-serve) tidak memerlukan port forward pada perangkat yang menjalankan Tailscale. [Use it outside your home](any-source.md#use-it-outside-your-home-optional) membandingkan pilihan-pilihannya.

### Apa yang tidak dilakukan rex? {#what-does-it-not-do}

Tidak ada tuner atau DVR. Musik, Live TV, dan foto memerlukan sumber yang mengirimkannya. Lihat [Musik dengan rex](music.md) dan [Live TV dengan rex](live-tv.md). zurg mengirim komik sebagai foto yang ditampilkan Plex Web. Radio dan stasiun mix Plexamp belum tersedia. rex tidak punya relay, jadi penggunaan dari luar rumah memerlukan alamatnya sendiri ([Gunakan dari luar rumah](any-source.md#use-it-outside-your-home-optional)).

## Setelah kamu memasang {#after-you-install}

### Kenapa aplikasi menampilkan versi Plex, dan "Check for Updates"? {#why-does-the-app-show-a-plex-version-and-check-for-updates}

rex memperkenalkan diri ke aplikasi dan ke plex.tv sebagai Plex Media Server, jadi aplikasi menampilkan nomor versi Plex Media Server. Nomor itu bukan milik rex. **Check for Updates** selalu menjawab bahwa server sudah terbaru: rex tidak pernah memperbarui dirinya sendiri. Untuk memperbarui rex, unduh nightly yang lebih baru seperti di [Updating](any-source.md#updating).

### Kenapa browser saya di port 32400/web tidak membuka pustaka? {#why-does-my-browser-at-port-32400web-not-open-a-library}

rex tidak punya web app sendiri. Membuka `http://<rex's LAN IP>:32400/web` akan menampilkan halaman status singkat. Tontonlah di aplikasi Plex atau di browser lewat [app.plex.tv](https://app.plex.tv).

![Halaman yang ditampilkan rex di /web saat belum di-claim](../assets/rex/80-rex-web-page.webp)

### Data apa saja yang keluar dari komputer saya? {#what-leaves-my-machine}

- **plex.tv, saat mulai dan sekali sehari, terdaftar atau tidak:** id, nama, dan versi server, untuk membaca daftar rilis publik Plex dan mencari nomor versi terbaru.
- **plex.tv, setelah terdaftar di akun Plex:** klaim, alamat server (alamat LAN dan alamat HTTPS-nya), dan nama library-nya.
- **Layanan metadata Plex, setelah terdaftar:** id setiap judul, untuk mendapatkan nama, poster, ringkasan, dan episodenya. Pencarian subtitle, lewat **Search Subtitles** atau pengaturan subtitle otomatis seseorang, mengirim nama dan sidik jari file.
- **Host artwork, saat sebuah aplikasi menampilkannya:** permintaan untuk poster dan gambar yang disebut sumber-sumbermu.
- **DMM, untuk rex-direct, setelah terdaftar dan kemudian setiap 6 jam:** id server, token-nya di akun Plex, dan IP LAN-nya. DMM memeriksa ke plex.tv bahwa server itu milikmu, melihat IP publik-mu, dan mengarahkan nama rex-direct-mu ke IP itu dan ke IP LAN. Jika mesin punya alamat IPv6 global, rex juga mengirimkannya, satu menit setelah mulai (atau setelah diklaim) dan kemudian setiap 6 jam, dan setiap kali DMM terhubung ke sana untuk memastikan alamat itu mencapai server yang sama. Matikan dengan `REX_DIRECT_URL=off`.
- **Sumber-sumbermu, saat kamu memutar atau menghapus:** permintaan untuk file yang kamu putar, dan penghapusan (di bawah).
- **Server Plex lamamu, hanya saat kamu [membawa riwayat tontonanmu](import-watched.md):** permintaan untuk riwayat tontonanmu.
- **Webhook, hanya jika kamu mengatur beberapa:** event, ke alamat yang kamu atur.

rex tidak bertanya kepada siapa pun apa itu sebuah rilis: sumbernya yang memutuskan dan memberi tahu rex. zurg, misalnya, bertanya kepada DMM ([Mengapa DMM menempatkan file](with-zurg.md#why-dmm-places-the-files)).

### Apakah menghapus di aplikasi Plex juga menghapus file-nya? {#does-deleting-in-a-plex-app-delete-the-file}

Ya. Menghapus film atau episode di aplikasi Plex, saat masuk dengan akun tempat rex terdaftar, akan menghapus file-nya di sumber, sama seperti server Plex menghapus file dari disknya. Sumber di akun debrid, seperti zurg, akan menghapusnya di sana. Jika sumber menolak, judul tetap ada dan aplikasi akan memberi tahu bahwa judul tidak bisa dihapus. Orang yang kamu bagikan akses tidak bisa menghapus. [Menghapus di aplikasi Plex](any-source.md#step-5-watch-something) menjelaskan cara mematikannya.

### Tidak ada yang bisa diputar, atau semua aplikasi bilang perangkatnya tidak cukup kuat {#nothing-plays-or-every-app-says-it-is-not-powerful-enough}

Lihat log rex tepat setelah kamu menekan Play. `upstream failed` atau `502` di sana berarti rex tidak bisa menjangkau sumber kamu di alamat yang diberikan sumber tersebut, dan memasang FFmpeg tidak akan memperbaikinya. Penyebab yang paling umum adalah zurg di Docker Desktop pada Windows atau macOS. Baris `upstream failed` di [rex dengan zurg](with-zurg.md#when-something-is-wrong) atau [rex dengan aplikasi sendiri](any-source.md#when-something-is-wrong) memeriksa alamat tersebut dan memberi tahu apa yang harus diubah. Jika hanya sebagian file yang gagal, sering kali hanya di web browser, berarti perangkat tidak bisa memutarnya apa adanya: atur [Konversi video](any-source.md#converting-video-optional).

### Sebuah judul salah dicocokkan. Bagaimana cara memperbaikinya? {#a-title-is-matched-wrong-how-do-i-fix-it}

Sumber yang menentukan apa isi setiap file, dan rex menampilkan judul tersebut. Masuk dengan akun tempat rex terdaftar, lalu gunakan **Fix Match**: rex menyimpan pilihan Anda, dan sebuah sumber dapat membacanya kembali untuk menyimpannya sebagai pencocokan untuk rilis tersebut, seperti yang dilakukan zurg ([Mengapa DMM menempatkan file](with-zurg.md#why-dmm-places-the-files)).

### Di mana saya bisa mendapatkan bantuan? {#where-do-i-get-help}

[Mendapatkan bantuan](../guides/remote-help.md) menjelaskan di mana harus bertanya dan apa saja yang perlu disertakan: forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP), dan bantuan jarak jauh untuk sponsor.
