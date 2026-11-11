# Real-Debrid

`type: realdebrid`

zurg mulai sebagai server [Real-Debrid](http://real-debrid.com/?id=20476302) dan masih paling paham dengan Real-Debrid. Ini satu-satunya backend dengan pemilihan file per file, daftar `__downloads__` terpisah, pemilihan host CDN, dan token `.strm` khusus.

## Dapatkan API token {#get-the-api-token}

Masuk dan buka [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354).
Token-nya berupa string hex yang panjang. Salin semuanya.

!!!warning Matikan dulu penggunaan remote traffic otomatis
Di [halaman akun](http://real-debrid.com/?id=20476410) kamu, pastikan **Use my
Remote Traffic automatically when needed** tidak dicentang. Kalau tetap aktif, kuota remote traffic kamu akan terpakai untuk streaming biasa tanpa pemberitahuan.
!!!

## Atur konfigurasinya {#configure-it}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

Pada instalasi container yang baru, biarkan setup yang menuliskannya untuk Anda.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

Pada instalasi yang sudah punya `config.yml`, gunakan Dashboard di
`http://localhost:9999/config/` atau edit file-nya. Lalu restart.

```bash
docker compose restart zurg
```

### Satu-satunya provider yang bisa di-seed dari environment oleh container {#the-one-provider-a-container-can-seed-from-the-environment}

Real-Debrid adalah satu-satunya akun yang dibuatkan config sendiri oleh daemon yang berjalan. `TOKEN` atau `RD_TOKEN` di blok `environment:` compose kamu akan mengisi `config.yml` saat run yang membuat file itu. `MOUNT_PATH` mengisi mount.

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

Keduanya hanya dibaca **saat run pertama** itu. Setelah file ada, file itu adalah satu-satunya sumber kebenaran. Variabel lama tidak akan pernah diam-diam membatalkan mount path yang sudah kamu atur di Dashboard. Saat startup, akan muncul peringatan jika `MOUNT_PATH` diabaikan karena alasan ini.

## Key tambahan yang dipakai backend ini {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` adalah token API cadangan di layanan yang sama. Token ini mengambil alih ketika
bandwidth token aktif sudah habis. Token ini memakai katalog entri ini, dan
perpustakaan torrent milik mereka tidak pernah diimpor.

`strm_link_token` menangani pembacaan yang masuk ke `/strm/`, jadi saat player membuka file
`.strm`, token yang dipakai mount live kamu tidak ikut terpakai. Jika tidak diisi, token ini
memakai `token` sebagai gantinya.

Keduanya layak dipakai di sini karena Real-Debrid adalah salah satu dari dua backend yang memang merotasi kredensial.

## Hal yang dilakukan Real-Debrid dan tidak dilakukan provider lain {#what-real-debrid-does-that-the-others-do-not}

- **Pemilihan per file.** Saat menambahkan sebuah rilis, bisa saja hanya sebagian yang diambil. Jadi `force_select_playable_files` punya sesuatu untuk dikerjakan, dan repair bisa hanya memperbaiki file yang rusak, tidak perlu menambahkan ulang seluruh rilis.
- **Daftar kedua bernama downloads.** `__downloads__` di root mount adalah daftar tautan unrestricted yang hanya dimiliki Real-Debrid. Menghapusnya sekaligus membutuhkan cookie sesi web. Jadi tombol Dashboard adalah satu-satunya cara. Instalasi tanpa akun Real-Debrid akan diberi tahu, bukan ditampilkan seolah-olah berhasil.
- **Pemilihan host CDN.** `rd_cdn_host_preference` memilih antara pilihan Real-Debrid sendiri, saudara Cloudflare-nya, atau negara tertentu. Lihat [CDN dan pemilihan host](../reference/config.md#cdn--host-selection).
- **Repair.** Tautan Real-Debrid yang tercatat untuk sebuah file bisa berhenti berfungsi, padahal torrent-nya masih dilaporkan sehat. Itulah alasan utama zurg punya subsistem repair, dan ini satu-satunya backend yang membutuhkannya.

## Batasan yang perlu diketahui {#limits-worth-knowing}

**Dua penambahan pada satu akun perlu jeda 20 detik di antaranya.** Diukur terhadap API live pada 2026-08-17. Enam nama rilis yang bersih, ditambahkan dengan jeda sepuluh detik, ditolak enam kali dari enam. Enam rilis yang sama dengan jeda dua puluh detik diterima enam kali dari enam. zurg mengatur kecepatan penambahannya sendiri agar sesuai batas minimum itu.

**Penambahan yang ditolak terlihat persis seperti nama file yang diblokir.** Real-Debrid membalas keduanya dengan `451 infringing_file`. Throttle itu juga punya ingatan. Begitu terpicu, ia terus menolak selama beberapa menit meski sudah tenang. Satu sapuan perbaikan produksi menghabiskan empat jam tanpa menambahkan apa pun, karena tiga penambahan masuk dalam rentang tiga belas detik satu sama lain di awal sapuan itu.

**Beberapa rilis ditolak hanya dari namanya.** Sejak 14 Oktober 2026 ada sebelas string seperti itu. WEB-DL, WEB.x264 dan WEB.H264 hanya dihitung jika persis dalam bentuk itu, jadi web-dl, Web-Dl dan WEB.h264 dari scene tetap lolos. WEBRip, BDRip, HDRip, DVDRip, HDTV.x264, HDTV.XviD, BluRay.x264 dan p.BluRay.DTS dihitung dalam huruf apa pun. Yang terakhir butuh huruf p tepat di depannya, seperti pada 1080p.BluRay.DTS. Rilis 2002.BluRay.DTS baik-baik saja. Hanya separator yang persis sama yang dihitung. WEB.DL, WEB-x264 dan BluRay-x264 semuanya lolos. Rilis yang dinamai dengan salah satu dari itu ditolak pada permintaan pertama setiap kali, apa pun isinya. File di dalam rilis yang namanya cocok diterima tetapi tidak akan bisa di-stream. zurg mengenal pola-pola ini dan menolak grab tersebut secara lokal, daripada menghabiskan slot penambahan dan dua percobaan ulang masing-masing enam puluh detik untuk kegagalan yang sudah pasti.

**Salinan kedua dari konten yang sudah dimiliki akun tidak pernah terunduh.** Real-Debrid menerima penambahan itu lalu tidak mengambil apa pun untuknya. Instance tetap di 0 persen dengan 0 seeder selamanya.

**Daftar torrent tidak memuat detail file.** Setiap torrent butuh panggilan info sendiri. Itulah sebabnya zurg menyimpan cache info di disk. Pemindaian dingin pada pustaka besar adalah kasus paling mahal, dan cache inilah yang mencegahnya terulang.

Tiga kunci mengatur kecepatan API, dan nilai default-nya cocok untuk akun biasa.

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Kalau cuma ada satu akun, folder akunnya sendiri tidak ditampilkan di daftar root mount, jadi mount menampilkan file yang sama di bawah `__all__`.

## Saat terjadi masalah {#when-it-goes-wrong}

**`RD Permission denied` di log.** Kuncinya sudah dicabut atau diganti. Dapatkan yang baru dari [real-debrid.com/apitoken](http://real-debrid.com/?id=20476302) lalu perbarui entri di Dashboard atau di `config.yml`.

**Setiap grab kembali 451.** Bisa jadi nama rilisnya termasuk yang ditolak Real-Debrid sepenuhnya, atau penambahan datang terlalu berdekatan sehingga throttle masih menahan. Masalah ini hilang dengan membiarkannya tenang, bukan dengan mencoba ulang.

**Mount tidak menampilkan apa pun saat pertama kali dijalankan.** Library yang besar butuh waktu untuk dimuat. `/dav/movies/` akan menjawab 503 sampai proses selesai.

**Link lolos verifikasi lalu tidak menyajikan apa pun.** Aktifkan `use_range_verification` supaya zurg memeriksa dengan GET ber-range satu byte, bukan `HEAD`. Beberapa jaringan dan beberapa server Real-Debrid menjawab `HEAD` dengan tidak benar.
