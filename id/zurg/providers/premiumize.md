# Premiumize

`type: premiumize`

Premiumize me-mount transfer yang sudah selesai **dan** file cloud yang tetap ada setelah daftar transfer dibersihkan. Folder bertingkat tetap menyimpan path-nya. Library yang sudah kamu atur di Premiumize akan muncul di mount dengan susunan yang sama seperti yang kamu tinggalkan.

## Dapatkan API key {#get-the-api-key}

Masuk dan buka [premiumize.me/account](https://www.premiumize.me/account). API key-nya ada di halaman itu.

## Atur konfigurasinya {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Pada instalasi container yang baru, biarkan setup yang menulisnya.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

Pada instalasi yang sudah punya `config.yml`, gunakan **Add provider** di
Dashboard pada `http://localhost:9999/config/` atau edit filenya. Restart
dengan cara apa pun.

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` dibaca oleh `zurg setup`, bukan oleh daemon yang sedang
berjalan. Kalau cuma ada di blok `environment:` compose, variabel ini tidak
berpengaruh apa-apa.

## Satu kredensial per entri {#one-credential-per-entry}

Premiumize file ID dimiliki oleh akun yang mendaftarkannya. Tidak ada kunci kedua untuk diganti. `download_tokens` langsung ditolak, begitu juga `strm_link_token` yang berbeda dari `token`. Akun Premiumize kedua adalah entri kedua dengan `name` sendiri.

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

Loader sengaja menyatakannya dengan jelas, bukan diam-diam mengabaikan kunci tersebut. Loader akan menolak config dan menyebutkan nama entrinya.

## Yang berfungsi di sini {#what-works-here}

Penelusuran pustaka dan pembacaan streaming serta pembacaan yang dialihkan dan STRM dan penambahan magnet dan unggahan `.torrent` dan penghapusan semuanya berfungsi. Akun ini mendapatkan direktori `__premiumize__` sendiri seperti akun lainnya.

## Hash disimpan di disk {#hashes-are-remembered-on-disk}

Hash yang diberikan lewat zurg ditulis ke
`data/premiumize/<account>/sources.json` di dalam bind `/config`. Pencocokan
antar akun tetap berfungsi setelah restart dan setelah daftar transfer
yang selesai dibersihkan.

Konten cloud yang kamu impor lewat cara lain tidak punya hash yang tercatat. Konten ini tetap
bisa di-stream. Konten ini tidak bisa diperbaiki lewat hash dan tidak bisa dicocokkan ke
akun lain lewat hash.

!!!warning Menghapus transfer juga menghapus file-filenya
Menghapus transfer Premiumize lewat zurg juga menghapus file yang dimiliki
transfer itu. Ini perilaku Premiumize sendiri, bukan sesuatu yang ditambahkan zurg di atasnya.
!!!

## Batasan yang perlu diketahui {#limits-worth-knowing}

**Penyimpanan cloud dan fair use adalah batas milik akun kamu sendiri.** zurg tidak menaikkan
batas itu dan tidak mengakalinya.

**8 permintaan API bersamaan.** Empat volume dari arsip multi-volume diselesaikan sekaligus.

**Konten bisa kedaluwarsa.** Rilis yang sudah hilang adalah hasil yang wajar, bukan kesalahan.
Repair membiarkannya begitu saja kecuali kamu memintanya.

**Daftar torrent tidak memuat detail file.** Setiap rilis butuh pencarian sendiri saat pertama kali diakses.

zurg memetakan kode error dari layanan ke langkah berikutnya yang seharusnya dilakukan.

| Kode dari Premiumize | Yang dilakukan zurg |
|---|---|
| `authentication_failed` | Melaporkan kredensial yang salah. Perbaiki key-nya. |
| `rate_limit_reached` | Menjeda akun selama satu menit. |
| `account_limit_reached` atau `service_limit_reached` | Melaporkan kuota yang sudah habis. |
| `service_down` | Memperlakukan akun sebagai sementara tidak tersedia. |
| `not_found` | Memperlakukan torrent sebagai sudah hilang. |

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

Kalau cuma pakai satu akun, folder akunmu sendiri tidak ditampilkan di daftar root mount, jadi mount menampilkan file yang sama di bawah `__all__`.

## Saat terjadi masalah {#when-it-goes-wrong}

**Semua gagal karena kredensial tidak valid.** Buat ulang kunci di [premiumize.me/account](https://www.premiumize.me/account) lalu perbarui entri tersebut.
Perlu diketahui bahwa Premiumize memberikan jawaban yang sama untuk kunci yang hilang dan kunci yang salah. Pesan errornya tidak bisa memberi tahu mana yang terjadi.

**Rilisan bisa di-stream tapi tidak bisa diperbaiki.** Rilisan tersebut tidak punya hash yang tercatat. Artinya, rilisan itu masuk ke akun lewat jalur lain selain zurg. Lihat penjelasan di atas.

**Pembacaan berhenti sejenak selama satu menit.** Batas rate limit sudah tercapai dan zurg sengaja menahan akun tersebut. Akun akan lanjut sendiri setelahnya.

**URL yang dihasilkan bisa dipakai siapa saja yang memilikinya.** URL delivery dan akses `.strm` sebaiknya dijaga kerahasiaannya. Kuota yang dipakai tetap milik akun Anda sendiri.
