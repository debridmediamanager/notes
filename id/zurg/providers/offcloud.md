# Offcloud

`type: offcloud`

Offcloud me-resolve file handle lewat endpoint cloud explore-nya. Ukuran file dicek ke delivery server, bukan langsung dipercaya dari listing. Metadata torrent yang sudah di-cache dipakai untuk mengisi path folder kalau bisa dicocokkan tanpa ambigu.

## Dapatkan API key {#get-the-api-key}

Masuk dan buka [offcloud.com/#/account](https://offcloud.com/#/account). API key ada di halaman itu.

## Atur konfigurasinya {#configure-it}

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Pada instalasi container baru, biarkan setup yang menulisnya.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

Pada instalasi yang sudah punya `config.yml`, gunakan **Add provider** di
Dashboard di `http://localhost:9999/config/` atau edit filenya. Restart
dengan cara apa pun.

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` dibaca oleh `zurg setup`, bukan oleh daemon yang sedang berjalan.

## Satu kredensial per entri {#one-credential-per-entry}

Handle file Offcloud menjadi milik akun yang mendaftarkannya. Tidak ada kunci kedua yang bisa dirotasi ke sana. `download_tokens` akan ditolak, begitu juga `strm_link_token` yang berbeda dengan `token`. Akun kedua berarti entri kedua dengan `name` sendiri.

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## Yang berfungsi di sini {#what-works-here}

Pembacaan library dan streamed reads dan redirected reads dan STRM dan penambahan magnet dan upload `.torrent` dan penghapusan semuanya berfungsi. Akun tersebut mendapat direktori `__offcloud__` sendiri.

## Batasan yang perlu diketahui {#limits-worth-knowing}

**8 gleichzeitige API-Anfragen.** Vier Teile eines mehrteiligen Archivs werden gleichzeitig aufgelöst.

Wait — I'm writing in Indonesian, not German. Let me correct that.

**8 permintaan API serentak.** Empat volume dari arsip multi-volume diselesaikan sekaligus.

**Konten kedaluwarsa.** Rilis yang sudah hilang memang diharapkan, bukan dianggap rusak. Repair tidak menyentuhnya kecuali kamu memintanya.

**Daftar torrent tidak memuat detail file.** Setiap rilis memerlukan pencarian sendiri saat pertama kali.

**Daftar file yang ambigu dianggap sebagai error, bukan tebakan.** Kadang metadata torrent yang di-cache tidak bisa dicocokkan ke tepat satu rilis. zurg melaporkannya daripada memilih path folder yang mungkin milik hal lain.

**Magnet yang rusak ditolak secara lokal.** Magnet itu tidak pernah sampai ke layanan. Magnet yang buruk tidak memakan biaya apa pun.

Kosakata kegagalan Offcloud cukup terbatas. `NOAUTH` adalah satu-satunya kode yang bisa ditangani zurg, dan artinya kredensial ditolak. Semua yang lain muncul sebagai penolakan tanpa alasan.

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__all__/ | head
```

Kalau cuma pakai satu akun, folder akunnya sendiri tidak ditampilkan di daftar root mount, jadi mount menampilkan file yang sama di bawah `__all__`.

## Saat terjadi masalah {#when-it-goes-wrong}

**`NOAUTH` di log.** Kuncinya sudah dicabut atau dibuat ulang. Dapatkan yang baru dari [offcloud.com/#/account](https://offcloud.com/#/account) lalu perbarui entri tersebut.

**`API refused request` tanpa keterangan lain.** Offcloud tidak menyebutkan alasannya. Periksa akunmu lewat browser sebelum menganggap zurg yang bermasalah.

**Sebuah rilis tidak menampilkan folder.** Metadata torrent yang tersimpan di cache tidak bisa dicocokkan dengan tepat satu rilis. File tetap bisa di-stream. Hanya saja strukturnya datar.

**URL hasil generate bisa diakses siapa pun yang memilikinya.** URL delivery diperbarui saat cache-nya kedaluwarsa atau saat sebuah pembacaan membatalkannya. Kuota yang terpakai adalah milik akunmu sendiri. Jaga agar URL dan akses `.strm` tetap pribadi.
