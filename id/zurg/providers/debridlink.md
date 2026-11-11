# Debrid-Link

`type: debridlink`

Daftar seedbox [Debrid-Link](https://debrid-link.com/id/diG1t) memuat semua file. Refresh library cukup satu kali penelusuran berhalaman, bukan satu pencarian per rilis. Ini adalah backend cloud termurah dari ketiganya untuk dijaga tetap sinkron.

## Dapatkan API key {#get-the-api-key}

Masuk dan buka [debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey). Buat sebuah key lalu salin.

## Atur konfigurasinya {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Pada instalasi container yang baru, biarkan setup yang menulisnya.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

Pada instalasi yang sudah punya `config.yml`, gunakan **Add provider** di Dashboard di `http://localhost:9999/config/` atau edit filenya. Restart dengan cara apa pun.

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` dibaca oleh `zurg setup` dan bukan oleh daemon yang sedang berjalan.

## Satu kredensial per entri {#one-credential-per-entry}

Debrid-Link me-resolve setiap file dengan ID yang menjadi milik akun listing. Tidak ada kunci kedua untuk dirotasi. `download_tokens` ditolak, begitu juga `strm_link_token` yang berbeda dari `token`. Akun kedua berarti entri kedua dengan `name`-nya sendiri.

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## Yang berfungsi di sini {#what-works-here}

Pembacaan library, streaming, redirect, STRM, penambahan magnet, unggahan `.torrent`, dan penghapusan semuanya sudah berfungsi. Akun tersebut mendapatkan direktori `__debridlink__` sendiri.

## Batasan yang perlu diketahui {#limits-worth-knowing}

**20 slot aktif.** Itu batas yang dijaga zurg sebelum menambah lebih banyak.

**8 permintaan API serentak.** Empat volume dari arsip multi-volume diselesaikan sekaligus.

**Konten kedaluwarsa.** Rilis yang sudah hilang memang diharapkan, bukan rusak.

**Tidak ada pengecekan cache.** Debrid-Link sudah menghentikan endpoint itu dan zurg tidak memakainya. Penambahan khusus cached hanya bisa memastikan hit dari respons penambahan itu sendiri. Menanyakan apakah sesuatu sudah ada di cache sebelum menambahkannya bukan pertanyaan yang bisa dijawab backend ini.

zurg memetakan kode error dari layanan ke langkah yang harus dilakukan berikutnya.

| Kode dari Debrid-Link | Yang dilakukan zurg |
|---|---|
| `badToken` atau `badSign` | Melaporkan kredensial yang salah. Perbaiki key-nya. |
| `floodDetected` | Menjeda akun selama satu jam. |
| `maxTorrent` `maxData` `maxLink` dan varian `Host`-nya | Melaporkan kuota penambahan atau trafik harian yang sudah habis. |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | Memperlakukan akun sebagai sementara tidak tersedia. |
| `badId` | Memperlakukan torrent sebagai sudah hilang. |

!!!warning Penolakan flood memakan waktu satu jam
`floodDetected` menahan akun selama satu jam penuh, bukan satu menit. Itu disengaja. Mencoba lagi saat kena penolakan flood justru memancing penolakan berikutnya. Beri jeda pada apa pun yang tadi membanjiri layanan sebelum kamu menjalankan ulang zurg.
!!!

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

Kalau cuma pakai satu akun, folder miliknya sendiri tidak ditampilkan di daftar root mount, jadi mount menampilkan file yang sama di bawah `__all__`.

## Saat terjadi masalah {#when-it-goes-wrong}

**Tidak ada yang terjadi selama satu jam.** Penolakan banjir. Lihat peringatan di atas.

**Grab ditolak tetapi pembacaan masih berfungsi.** Kuota harian untuk penambahan atau trafik sudah habis. Kuota akan di-reset sesuai jadwal layanan itu sendiri.

**Penambahan berhasil lalu diam saja.** Tanpa endpoint cache, tidak ada cara untuk mengetahui sebelumnya apakah hash sudah pernah tersimpan. Penambahan yang belum ter-cache akan diunduh seperti biasa.
