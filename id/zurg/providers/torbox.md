# TorBox

`type: torbox`

[TorBox](https://torbox.app/subscription?referral=74ffa560-7381-4a18-adb1-cef97378c670) adalah library paling murah untuk zurg sinkronkan dan paling mudah dibatasi saat dibaca. Daftar torrent-nya sudah memuat setiap file. Satu kali refresh library cukup satu request, bukan satu request per torrent. Endpoint resolusi link-nya memakai kuota tetap, bukan rate. zurg sengaja berhati-hati dengannya.

## Dapatkan API key {#get-the-api-key}

Masuk dan buka [torbox.app/settings](https://torbox.app/settings). API key ada di halaman itu.

**Akun gratis tidak bisa dipakai dengan zurg.** TorBox membalas setiap permintaan library dari API key gratis dengan `PLAN_RESTRICTED_FEATURE`, jadi zurg tidak bisa membaca isi akun. Pakai paket berbayar. Paket berbayar yang habis masa berlakunya akan berubah jadi gratis dengan cara yang sama.

## Atur konfigurasinya {#configure-it}

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Pada instalasi container baru, biarkan setup yang menulisnya.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

Pada instalasi yang sudah punya `config.yml`, gunakan **Add provider** di Dashboard di `http://localhost:9999/config/` atau edit filenya. Apa pun caranya, restart setelahnya.

```bash
docker compose restart zurg
```

!!!warning Kunci TorBox di environment compose kamu tidak berpengaruh sendiri
`TORBOX_TOKEN` dibaca oleh `zurg setup`, bukan oleh daemon yang sedang berjalan. Hanya `TOKEN` milik Real-Debrid yang membuat config saat pertama kali start. Berikan kunci itu ke container setup atau tambahkan akunnya lewat Dashboard.
!!!

Untuk instalasi tanpa pengawasan, arahkan setup ke sebuah file, bukan ke environment variable.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## Dua kunci yang tidak berlaku di sini {#two-keys-that-do-not-apply-here}

`download_tokens` diterima tetapi tidak akan melakukan apa yang seharusnya di Real-Debrid.
Mengganti ke kunci kedua tidak memetakan ulang ID torrent dan file. Di TorBox, ID itu milik akun yang mendaftarkannya. Akun TorBox kedua butuh entri sendiri dengan `name` sendiri.

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` diterima tetapi tidak dipakai. TorBox membuat URL unduhan baru setiap permintaan. Tidak ada kredensial jangka panjang yang bisa dikunci oleh file `.strm`.

## Slot aktif adalah batas yang sebenarnya {#active-slots-are-the-real-ceiling}

Batasan utama TorBox adalah berapa banyak torrent yang boleh diunduh atau di-seed secara bersamaan. Real-Debrid membatasinya lewat bandwidth. TorBox membatasinya lewat slot.

| Paket | Slot aktif |
|---|---|
| Free | 1, tapi zurg tidak bisa memakai key gratis (lihat di atas) |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

zurg membaca paket dari akun dan membatasi penambahan torrent berdasarkan paket itu. Akun yang paketnya tidak bisa dibaca zurg dianggap punya 3.

Hitung semua hal lain yang menambahkan torrent dengan jatah slot yang sama. Sonarr dan Radarr yang mengambil lewat endpoint qBittorrent, pemindaian perbaikan, dan watchlist, semuanya memakai slot yang sama itu.

## Batasan yang perlu diketahui {#limits-worth-knowing}

**Penyelesaian tautan adalah anggaran sekitar seratus panggilan, bukan laju.**
Diukur pada 2026-08-30. Respons 429 dengan `Retry-After: 300` muncul pada panggilan kumulatif ke-100 ketika panggilan dikirim secepat mungkin. Respons itu muncul pada panggilan ke-94 ketika panggilan diatur satu per detik. Penguncian ini berlaku untuk seluruh akun. Ia menghentikan seluruh mount selama lima menit, bukan hanya pembacaan yang memicunya.

Ada dua hal yang mengikuti dari ini, dan zurg menanganinya sendiri.

- Ia tidak pernah menyelesaikan file yang tidak diminta siapa pun. Backend lain mendapat keuntungan dengan menyiapkan episode berikutnya lebih dulu. TorBox tidak bisa menanggung tebakan itu, karena media server yang menganalisis pustaka membuka setiap file tepat satu kali, dan setiap pembukaan itu dimulai dari kondisi dingin.
- Ia menyelesaikan volume arsip multi-volume secara berurutan, satu per satu. Lebih cepat akan menghabiskan batas beberapa kali lipat dan membeli volume di belakang volume yang rusak sebelum ada yang menyadari volume-volume itu tidak diperlukan.

**60 penambahan uncached per jam.** Penambahan cached sebagai gantinya berada di bawah anggaran per menit.

**300 permintaan per menit untuk semua endpoint dengan satu kunci.** zurg mengatur dirinya sendiri hingga 300 dikurangi 60, supaya percobaan ulang yang dibuat klien HTTP-nya sendiri tidak mendorong lonjakan yang sudah dianggarkan melewati batas nyata.

**Koneksi ke-21 ke satu host CDN mendapat 429.** Diukur pada 2026-08-23 dengan membuka satu koneksi setiap 500ms dan menahannya. Batasnya berlaku per host, bukan per kunci. Menyebarkan pembacaan ke armada TorBox menghindarinya, sedangkan menumpuknya ke satu node tidak. zurg mengantre setelah 20 koneksi alih-alih membuka koneksi baru. Dengan begitu, penolakan berubah menjadi jeda lokal yang singkat.

**Konten dihapus setelah jendela retensi paket.** Torrent yang sudah hilang adalah hal yang wajar, bukan kerusakan. Repair tidak menyentuhnya kecuali Anda memintanya secara khusus.

**Tidak ada pemilihan file per file.** Menambahkan torrent mengambil seluruhnya, dan repair menambahkan ulang seluruh rilis.

Gambaran lengkap beserta sumbernya ada di [TorBox limits](torbox-limits.md).

## Memilih wilayah CDN {#choosing-a-cdn-region}

```yaml
tb_cdn_host_preference: "auto"
```

`auto` membiarkan pilihan TorBox sendiri. `force_location_<region>` mengirim unduhan dari region itu.
Hanya region yang saat ini punya delivery node yang bisa dipaksa, dan daftar di Dashboard isinya persis
region-region itu. Jangan pakai `cdn_host_preference` di sini. Kunci itu khusus Real-Debrid, dan nilainya
adalah kode lokasi Real-Debrid.

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__all__/ | head
```

Kalau cuma ada satu akun, folder akunnya sendiri tidak ditampilkan di daftar root mount, jadi mount menampilkan file yang sama di bawah `__all__`.

## Saat terjadi masalah {#when-it-goes-wrong}

**Log-nya tertulis `Account <name> refused zurg` atau terus berulang `TorBox rejected the API key`.**
Paketnya sudah habis dan key-nya sekarang ada di paket gratis. Mulai dari nightly 2026.10.11.2240,
zurg tetap memuat akun kamu yang lain tanpa akun ini. Kartu akun di dashboard
menampilkan `Refused: the account's plan does not include API access`. Rilisnya tetap
terdaftar tapi tidak bisa diputar, dan tidak ada yang dihapus atau dipindah ke trash karena hal ini. zurg
meminta ulang ke TorBox setiap 10 menit dan akun ini akan dipakai lagi begitu paketnya
dibayar. Di nightly lama, seluruh library tidak pernah selesai dimuat, jadi konten dari
akun kamu yang lain juga ikut tidak muncul. Perbarui zurg atau perpanjang paketnya. Menonaktifkan
provider `torbox` di `config.yml` (beri tanda komentar) lalu me-restart zurg juga bisa.

**Pemutaran berhenti selama lima menit setiap kali.** Jatah requestdl sudah habis dan 429-nya berlaku untuk seluruh akun. Ada sesuatu yang me-resolve lebih banyak link dari yang dibutuhkan.
Penyebab yang paling sering adalah media server yang memindai seluruh mount sekaligus. Arahkan ke satu direktori saja, jangan ke semuanya.

**Grab tidak lagi diterima.** Entah semua slot aktif sudah penuh atau batas penambahan per jam sudah habis. Keduanya akan pulih sendiri, dan mencoba ulang tidak membantu.

**Sebuah rilis menampilkan lebih sedikit file dari yang kamu harapkan.** `__torbox__` hanya menampilkan apa yang benar-benar disimpan TorBox. Jika akun lain menyimpan rilis itu secara utuh, bagian lain dari mount tetap menyajikan semuanya.

**Sebuah torrent hilang.** Ini soal retensi. Lihat di atas. zurg tidak akan menambahkannya lagi tanpa pengawasan, karena menemukannya kembali hanya menghabiskan jatah akun tanpa hasil.
