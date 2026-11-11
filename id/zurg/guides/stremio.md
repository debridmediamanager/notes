# Addon Stremio {#the-stremio-addon}

zurg bisa menjawab Stremio sebagai addon. Stremio meminta berdasarkan IMDb id. zurg mencari di indexer Newznab kamu dan mengambil NZB dari release yang dipilih ke backend Usenet. Setelah itu release diputar dan diperbaiki seperti release zurg lainnya.
Semua yang diputar dengan cara ini juga masuk ke library dan muncul di Plex.

## Konfigurasi {#configuration}

Addon ini butuh akun NZB, `nzb` atau [`torbox_nzb`](../providers/torbox-nzb.md), yang dipakai untuk mengirim datanya, dan minimal satu indexer. Dengan `torbox_nzb`, rilis yang sudah ada di TorBox akan mulai dalam waktu tunggu addon, selama tidak ada post NZB lain yang sedang menunggu. Rilis yang belum ter-cache harus selesai diproses di TorBox dulu, dan itu butuh waktu lebih lama daripada yang biasanya ditunggu player.

```yaml
stremio:
  enabled: true
  # token: ""            # generated and kept in data/stremio-token when empty
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_KEY
    - name: second-indexer
      url: https://second-indexer.example
      api_key: YOUR_KEY
      api_path: /api/v1/api   # for an indexer that 404s the default /api
```

Semua pengaturannya ada di halaman config, di bawah **Stremio Addon**: tombol on/off, daftar indexer, dan batas jumlah hasil. URL addon juga ditampilkan di sana, lengkap dengan tombol salin, dibuat dari alamat yang kamu pakai untuk membuka dashboard. Gunakan alamat itu: lihat [Memasang di perangkat lain](#installing-it-on-another-device).

Saat startup, zurg mencatat URL addon di log:

```
<zurg>/stremio/<token>/manifest.json
```

Tempel URL itu di Stremio (Addons → kotak pencarian menerima URL). Token di path itu adalah otorisasi utamanya. Klien Stremio tidak mengirim autentikasi sendiri, jadi rute ini ada di luar basic auth, sama seperti endpoint SABnzbd. Perlakukan URL ini seperti password: link putar yang dihasilkan membawa api key indexer kamu, dan siapa pun yang punya URL ini bisa memakai jatah grab indexer dan koneksi news server kamu.

## Memasang di perangkat lain {#installing-it-on-another-device}

Stremio hanya menerima addon lewat `http` biasa di komputer tempat Stremio itu sendiri berjalan. Artinya `http://127.0.0.1` atau `http://localhost` di mesin zurg. Di tempat lain, addon harus pakai `https`. TV, ponsel, atau komputer kedua akan menampilkan **failed to load manifest** untuk alamat `http://`, walaupun mereka bisa mengakses zurg dengan baik. Termasuk alamat LAN dan alamat Tailscale. Halaman konfigurasi akan memberi tahu hal ini di dekat URL addon setiap kali kamu membukanya lewat `http` biasa di alamat seperti itu.

zurg tidak menyajikan `https` sendiri. Pasang sesuatu di depannya yang melakukannya. Lalu buka halaman konfigurasi lewat alamat `https`, dan salin URL addon dari sana. zurg membuat URL addon dan setiap link play dari alamat tempat setiap permintaan masuk. Tidak ada pengaturan URL publik, dan `base_url` tidak dipakai di sini. Satu zurg bisa melayani pemutar di LAN dan pemutar dari jarak jauh sekaligus.

Apa pun yang ada di depan harus memberi tahu zurg dua hal. Nama host diambil dari header `Host` atau `X-Forwarded-Host`. Skema diambil dari `X-Forwarded-Proto: https`. Tanpa header itu, addon tetap bisa dimuat, tetapi link play akan kembali sebagai `http://` dan pemutarannya gagal. Setiap opsi di bawah ini mengirim kedua header tersebut.

Stremio memakai dua path. `/stremio/` adalah addon. `/strm/e/` adalah tempat tombol play mengarahkan pemutar ke videonya. Keduanya bisa diakses tanpa password zurg karena Stremio tidak bisa mengirim password. Token di URL addon yang melindungi keduanya. Saat zurg dibuka ke internet, publikasikan hanya kedua path ini. Semua yang lain adalah dashboard dan perpustakaanmu.

### Tailscale Serve

Pilihan paling sederhana kalau semua perangkat yang menjalankan Stremio bisa menjalankan Tailscale. zurg
tetap tidak terhubung ke internet.

1. Di konsol admin Tailscale, aktifkan MagicDNS dan HTTPS certificates.
2. Jalankan ini di mesin zurg. Pakai port kamu sendiri kalau zurg tidak di 9999.

   ```bash
   tailscale serve --bg 9999
   ```

   Di Windows, jalankan perintah yang sama di PowerShell. Kalau muncul access denied, buka PowerShell sebagai administrator. Di Linux, tambahkan `sudo` di depannya, kecuali kamu sudah menjadikan dirimu operator Tailscale (`sudo tailscale set --operator=$USER`). Di macOS, kalau `tailscale` tidak ditemukan, salinan milik aplikasi Tailscale ada di `/Applications/Tailscale.app/Contents/MacOS/Tailscale`.

3. Buka `https://<machine>.<tailnet>.ts.net/config/` lalu salin URL addon dari kartu **Stremio Addon**.

Tailscale yang mengurus sertifikatnya dan mengirim kedua header. `tailscale serve reset` untuk mematikannya lagi.

Perangkat yang tidak bisa menjalankan Tailscale bisa pakai Tailscale Funnel. Funnel membuat alamat yang sama bisa diakses dari internet. Publikasikan hanya yang dibutuhkan Stremio.

```bash
tailscale funnel --bg --set-path /stremio http://127.0.0.1:9999/stremio
tailscale funnel --bg --set-path /strm/e http://127.0.0.1:9999/strm/e
```

Halaman config tidak ada di alamat itu. Salin URL addon dari halaman seperti biasa kamu membukanya, lalu ganti bagian awalnya dengan `https://<machine>.<tailnet>.ts.net`. Tailscale membatasi bandwidth yang didapat Funnel. Remux 4K mungkin akan tersendat.

### Reverse proxy milik sendiri {#your-own-reverse-proxy}

Sudah punya reverse proxy dengan domain dan sertifikat? Tambahkan zurg ke situ.
Caddy otomatis menjaga header `Host` dan mengirim `X-Forwarded-Proto` sendiri.
Ini hanya mempublikasikan dua path Stremio dan tidak ada yang lain.

```
zurg.example.com {
    handle /stremio/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle /strm/e/* {
        reverse_proxy 127.0.0.1:9999
    }
    handle {
        respond 404
    }
}
```

nginx tidak mengirim kedua header itu kecuali kamu memintanya secara eksplisit.

```nginx
location ~ ^/(stremio|strm/e)/ {
    proxy_pass http://127.0.0.1:9999;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
}
```

Letakkan itu di dalam blok `server` yang sudah mendengarkan di 443 dengan sertifikatmu. `proxy_buffering off` membuat stream video langsung diteruskan, bukan lewat buffer nginx.

### Cloudflare Tunnel

Sebuah named tunnel memberi zurg alamat `https` di domain yang kamu punya di Cloudflare
tanpa perlu membuka port. Cloudflare menjaga header `Host` dan mengirim `X-Forwarded-Proto` sendiri. Rute hanya path Stremio di `config.yml` milik tunnel.

```yaml
ingress:
  - hostname: zurg.example.com
    path: ^/(stremio|strm/e)/
    service: http://127.0.0.1:9999
  - service: http_status:404
```

Ada dua hal yang perlu kamu tahu dulu. Cloudflare menyerah pada sebuah request setelah 100 detik. Pemutaran pertama dari sebuah release bisa butuh waktu lebih lama dari itu. Tekan play lagi dan pemutarannya akan jalan. Dan ketentuan Cloudflare membolehkan mereka membatasi akun yang mengirim banyak video lewat jaringannya tanpa paket berbayar. Setiap pemutaran lewat tunnel.

## Apa yang dilakukan sebuah play {#what-a-play-does}

Memilih stream berarti melakukan grab: zurg mengunduh NZB dari indexer, menaruhnya di `nzbs/` (dengan aturan penamaan yang sama seperti endpoint SABnzbd, jadi rilis yang di-grab dua kali, atau sudah di-grab oleh *arr, akan ditemukan dan tidak diduplikasi), menunggu library menampilkannya, lalu mengarahkan player ke endpoint `/strm/e/` yang ditandatangani. Endpoint itu juga yang dipakai setiap file `.strm` untuk diputar: baca rentang (ranged reads), failover akun, dan isi arsip RAR/7z.

Jadi, putar rilis untuk pertama kali pasti lebih lama daripada stream debrid. NZB harus diambil dan di-parse, dan isi arsip harus dibaca. Biasanya butuh beberapa detik, dan bisa sampai satu hingga dua menit untuk posting yang namanya diobfuscate dan harus melewati proses penamaan ulang. Kalau pemutaran melewati waktu tunggu, server akan menjawab 503 dengan Retry-After. Tekan play lagi dan kamu akan masuk ke jalur cepat. Pemutaran berikutnya langsung jalan.

Kalau rilis sudah tampil di library tapi ternyata tidak ada yang bisa diputar, biasanya karena rilisnya sudah hilang dari spool, atau semua file ditandai rusak oleh pengecekan server berita, klik kamu tidak berhenti di situ. URL play membawa permintaan yang dibuat untuk URL tersebut, jadi zurg menyusun ulang peringkat rilis untuk judul itu dan mencoba baris-baris setelah yang kamu pilih. Setiap percobaan melewati jalur grab-and-list yang sama. Rilis pertama yang bisa diputar akan jadi tujuan redirect player. zurg memeriksa seluruh hasil, bukan cuma baris yang tampil di daftar. `max_results` adalah jumlah yang mau kamu scroll, dan kalau nilai itu juga membatasi pemulihan, judul yang muncul di baris ke-sepuluh hanya bisa mencoba sembilan rilis, padahal pencarian mungkin sudah menemukan lebih banyak. Baris *setelah* pilihan memang sengaja dipakai: resolusinya sama dan ukurannya lebih kecil, atau resolusi di bawahnya. Rilis yang lebih besar yang sudah kamu lewati tidak akan dicoba. Fallback yang masih dalam proses ingest akan menjawab 503 yang sama. Tekan play lagi untuk menyelesaikannya: rilis yang ditolak langsung ditolak, dan fallback ditemukan lewat jalur cepat. Hanya penolakan terakhir yang diteruskan ke fallback, 503 tidak pernah begitu. Setiap percobaan memakai satu grab indexer dan rilisnya tetap ada di library seperti grab biasa, jadi rantai ini dibatasi anggaran dua puluh lima detik dan batas cadangan enam percobaan. Anggaran itu menjadi pembatas utama karena biaya tiap percobaan tidak sama. Rilis yang sudah hilang dari spool ditolak dalam waktu kurang dari satu detik, sedangkan rilis yang harus di-ingest dan membuka arsip sebelum ternyata tidak berisi apa-apa bisa menghabiskan hampir seluruh anggaran sendirian. Kalau semua baris yang dicoba ditolak, jawabannya tetap 404 seperti sebelumnya. Setiap fallback dicatat di level info, lengkap dengan rilis yang ditolak dan rilis yang dicoba berikutnya.

Kami membandingkannya dengan tiga addon Stremio lain yang memakai Usenet pada 7 September 2026: stremio-addon-findings-2026-09-07.md. Intinya, batas per resolusi memperbaiki masalah dari putaran sebelumnya, tapi cakupannya tetap turun setengah. Penyebabnya, bucket berisi lima entri tidak punya cadangan ketika entri pertama yang bisa diputar ternyata rilis yang sudah hilang dari spool. Fallback di atas adalah perbaikan pertama dari putaran itu. Bucket sekarang sudah diperbesar dari lima menjadi sepuluh.

## Perilaku pencarian {#search-behaviour}

- Pencarian film memakai `t=movie`, dan episode memakai `t=tvsearch` dengan `season`/`ep`. Keduanya dicari lewat `imdbid` sebagai angka saja, karena beberapa indexer mengembalikan nol hasil untuk bentuk `tt`.
- Setiap indexer diminta `search_limit` rilis (default 100). Setiap batas di bawah memilih dari apa yang diminta ini, jadi itulah batas atas jawabannya.
- Indexer dicari secara paralel. Kalau satu menolak (karena batas burst atau kunci yang mati), hanya hasilnya yang hilang, bukan seluruh daftar. Penolakan dicatat per indexer.
- Hasil dideduplikasi berdasarkan nama rilis, diurutkan berdasarkan resolusi dulu lalu ukuran, dan dibatasi `max_results` (default 10) *per resolusi*. Batasnya dihitung per resolusi karena urutannya dimulai dari 2160p. Judul populer punya lebih banyak rilis UHD di bawah batas ukuran daripada batas mana pun, jadi kalau dihitung untuk seluruh daftar, judul populer hanya akan dijawab dengan remux, apa pun yang lain ditemukan pencarian.
- Yang disimpan tiap resolusi adalah sebaran ukurannya, bukan beberapa yang terbesar: pilihan yang berjarak merata dari rilis terbesar sampai yang terkecil, dan keduanya selalu disertakan. Kalau diambil dari atas, tingkat 1080p berisi lima itu berarti lima remux antara 19 dan 30 GB, dan encode 4 GB yang bisa langsung diputar di HP atau laptop justru hilang karena batas tadi. Diukur pada 7 September 2026, tiga dari lima belas entri zurg untuk The Shawshank Redemption berukuran di bawah 6 GB, sementara ada empat puluh rilis serupa di indexer yang sama. Daftar tetap diurutkan dari ukuran terbesar ke terkecil dalam satu resolusi. Rilis yang ukurannya tidak dilaporkan indexer tidak punya tempat di sumbu itu, jadi rilis tersebut hanya mengisi sisa ruang yang tidak dipakai rilis yang berukuran.
- Deskripsi setiap stream memuat nama rilis, ukurannya, indexer yang menemukannya, dan sudah berapa lama diposting, seperti `3d`, `126d`, atau `2y`, kalau indexer melaporkannya. Usia artikel di news server adalah penyebab paling umum play gagal pada putaran 7 September, dan tanggal posting adalah satu-satunya sinyal yang bisa dipakai penonton untuk menghindarinya.
- Rilis yang lebih besar dari `max_size_gb` dibuang sebelum pengurutan, untuk pemutar yang tidak bisa memutar remux. Secara default tidak ada batas, karena sebaran di atas sudah menampilkan rilis terkecil tiap resolusi di samping remux-nya. Ukuran yang tidak dilaporkan indexer tetap disimpan. Batas ini diterapkan saat daftar ditampilkan, jadi mengubah batasnya langsung berlaku juga untuk judul yang sudah di-cache.
- Hasil disimpan di disk (`data/stremio-cache/`, satu file per judul), jadi membuka ulang judul tidak memakan panggilan indexer. Indexer sering punya kuota harian, dan Treasure Maps menolak setelah sekitar enam panggilan beruntun yang cepat. Berapa lama jawaban disimpan bergantung pada banyaknya hasil yang ditemukan, karena daftar yang tipis menandakan upload masih berdatangan atau indexer sedang mati. Satu hasil disimpan satu jam, dua hasil dua jam, sampai empat. Lima hasil atau lebih dianggap jawaban final dan disimpan selama `cache_hours` (default 24, satu-satunya tingkat yang bisa diatur). Jawaban kosong tidak pernah di-cache. Daftar stream yang di-cache punya item **refresh** di bagian bawah yang menunjukkan sudah berapa lama usianya. Membuka item itu (terbuka di browser, bukan di pemutar) menghapus cache untuk judul tersebut, dan membuka ulang judulnya akan mencari dari awal. Cache bertahan setelah restart, dan entri yang sudah kedaluwarsa dibersihkan sendiri.
- Season 0 (specials) ditolak daripada dicari dengan cara yang salah. Cakupan pencarian berdasarkan id bergantung pada indexer, jadi rilis yang hanya ditemukan lewat pencarian teks tidak akan muncul.
