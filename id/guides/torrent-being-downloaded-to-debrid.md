# Arti dari "Torrent is being downloaded to debrid" {#what-torrent-is-being-downloaded-to-debrid-means}

Layar hijau **Torrent is being downloaded to debrid...** berarti rilis yang kamu pilih belum ada di cache layanan debrid kamu. Torrentio, addon Stremio yang menampilkannya, baru saja menambahkan torrent tersebut ke akun Real-Debrid, TorBox, atau debrid lain milikmu, dan layanan itu sedang mengunduhnya sekarang. Setelah selesai, hasil yang sama akan diputar seperti biasa.

## Apa yang harus dilakukan {#what-to-do}

1. **Pilih hasil yang sudah ter-cache.** Di daftar Torrentio, `[RD+]` (atau `[TB+]`, `[AD+]`, `[PM+]`) berarti sudah ter-cache, jadi langsung bisa diputar. `[RD download]` berarti belum ter-cache. Hasil itu muncul setelah yang sudah ter-cache.
2. **Atau tunggu beberapa menit, lalu tekan hasil yang sama lagi.** Selama masih diunduh, layar hijau akan muncul lagi. Setelah selesai, video akan diputar.
3. **Pantau unduhannya** di [halaman torrents Real-Debrid](https://real-debrid.com/torrents), [dasbor TorBox](https://torbox.app/dashboard) Anda, atau [pustaka DMM](https://debridmediamanager.com/library). DMM menampilkan persentase, seeds, dan kecepatan setiap unduhan yang belum selesai.
4. **Macet di 0% dan tidak ada seeds?** Saat ini tidak ada yang membagikan rilis itu, jadi mungkin tidak akan pernah selesai. Pilih yang lain saja.
5. **Tidak mau melihat hasil ini sama sekali?** Buka [halaman konfigurasi Torrentio](https://torrentio.strem.fun/configure), atur layanan debrid dan kunci Anda seperti sebelumnya, centang **Don't show download to debrid links** di bagian **Options**, lalu tekan **INSTALL**. Anda hanya akan melihat hasil yang sudah ter-cache.

## Lihat apa yang sudah di-cache sebelum menekan play {#see-whats-cached-before-you-press-play}

Masuk ke [DMM](https://debridmediamanager.com/) dengan layanan debrid kamu, lalu cari judulnya. Di halaman hasilnya, tombol hijau **Instant RD** berarti Real-Debrid sudah menyimpan rilis tersebut di cache, jadi bisa langsung diputar. **DL with RD** berarti belum di-cache dan harus diunduh dulu. Ketuk chip **RD** di atas hasil untuk menyembunyikan semua yang belum di-cache. TorBox, AllDebrid, Premiumize, dan Offcloud juga punya tombol serupa (**Instant TB**, **DL with TB**, dan seterusnya).

## Pertanyaan {#questions}

### Berapa lama waktu yang dibutuhkan? {#how-long-does-it-take}

Ini tergantung berapa banyak orang yang membagikan torrent itu. Rilis yang populer biasanya siap dalam hitungan menit: dalam uji coba kami di Premiumize, film 1,5 GB siap lima menit setelah tombol pertama ditekan, diunduh dari tiga peer. Torrent yang jarang dibagikan bisa lambat, dan yang tidak dibagikan siapa pun mungkin tidak pernah selesai. Halaman torrents atau dashboard menampilkan kecepatan dan berapa banyak seed yang ditemukan.

### Kenapa ini terjadi pada beberapa hasil dan tidak pada yang lain? {#why-does-it-happen-on-some-results-and-not-others}

Layanan debrid menyimpan apa yang diunduh penggunanya. Kalau seseorang sudah mengambil rilis yang persis sama, berarti rilis itu sudah di-cache dan langsung bisa diputar. Kalau belum ada yang mengambilnya, atau layanannya sudah menghapusnya, akun kamu harus mengunduhnya dulu. Itulah perbedaan antara `[RD+]` dan `[RD download]`. TorBox [menjelaskan cara kerja cache-nya](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work).

### Kenapa hasil `[RD+]` menampilkannya? {#why-did-an-rd-result-show-it}

Real-Debrid tidak mengizinkan addon menanyakan apa yang sudah di-cache. Jadi di Real-Debrid, tanda `+` dari Torrentio berarti rilis itu pernah diputar oleh seseorang baru-baru ini, bukan berarti Real-Debrid baru saja memastikannya. Jika Real-Debrid sudah menghapusnya sejak itu, rilis akan diunduh ulang. Pilih hasil lain yang ber-`+` atau tunggu.

### Apakah debrid saya rusak? {#is-my-debrid-broken}

Tidak. Layar hijau berarti layanan kamu sudah menerima torrent dan sedang memprosesnya. Kalau memang ada masalah, Torrentio menampilkan layar merah atau kuning dengan tulisan lain, seperti "Access denied" atau "Some usage limit exceeded".

### Addon saya menampilkan pesan lain {#my-addon-says-something-else}

Kata-kata persisnya berasal dari Torrentio dan salinan self-hosted-nya. Addon lain menyampaikan hal yang sama dengan cara mereka sendiri. AIOStreams menampilkan "The file is being downloaded to your debrid. Try again later", Comet menampilkan "The media you tried to play is not cached yet on this debrid service", dan StremThru menampilkan "Downloading to Store". Penyebabnya sama, dan solusinya juga sama.
