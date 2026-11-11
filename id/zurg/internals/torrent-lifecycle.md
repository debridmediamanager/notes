# Siklus hidup torrent di Real-Debrid, AllDebrid, dan TorBox {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

Diukur pada 2026-08-30 terhadap akun live. Semua yang di bawah ini ditandai **diamati** berasal dari capture. Semua yang ditandai **disimpulkan** tidak berasal dari capture, dan alasannya dijelaskan.

zurg membutuhkan ini karena shim qBittorrent harus memberi tahu Sonarr dan Radarr tahap unduhan saat ini. Saat ini belum bisa. `TorrentInfo.Status` membawa kosakata status Real-Debrid, dan paket AllDebrid serta TorBox menerjemahkannya ke format itu sebelum kode zurg sendiri melihat torrent. Status TorBox `stalled (no seeds)` datang sebagai `queued`. Tidak ada yang membawa data seeder, kecepatan, atau eta sama sekali. Jadi tabel tahap harus dibangun dari wire, bukan dari paket penyedia yang sudah menormalkannya.

Harness-nya adalah `scripts/torrent_lifecycle_probe.py`. Script ini memanggil REST API mentah, sehingga hasil capture berupa status wire. Script ini menghapus semua yang ditambahkannya saat keluar, termasuk saat Ctrl-C.

---

## Cara pengukuran ini dilakukan {#how-this-was-measured}

### Akunnya {#the-accounts}

| Provider | Account | Kenapa yang ini |
|---|---|---|
| Real-Debrid | akun tes | tidak ada zurg yang berjalan memakainya, jadi tidak ada yang lain menyentuhnya selama run |
| AllDebrid | kunci tes | akunnya sudah berisi magnet lain, jadi hanya ID yang dibuat oleh run ini yang pernah dihapus |
| TorBox | kunci live | **instance zurg lain dimuat dengan akun yang sama**, dan ini bukan catatan kaki. Lihat [Hazards](#hazards-found-on-the-way) |

Kredensial diambil dari `RD_TOKEN` `AD_KEY` `TB_KEY` di environment. Tidak ada yang menulisnya ke
capture.

### Torrent-nya {#the-torrents}

Semua legal. Gambarnya FOSS dan filmnya public domain. Setiap info hash yang berasal dari `.torrent` dihitung ulang dari file oleh harness, bukan diketik manual. Ukuran swarm adalah hasil scrape tracker di hari yang sama.

| Case | Torrent | Info hash | Size | Seeder tracker | Webseed |
|---|---|---|---|---|---|
| cached | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | n/a | n/a |
| cached | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | n/a | n/a |
| cached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 sampai 27 | tidak ada |
| uncached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| uncached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 seeder dan 0 leecher | 3 |
| seedless | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | tidak ada |
| seedless | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | tidak ada |
| nometa | random 40-hex | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | tidak ada | tidak ada | tidak ada |

Angka nol itu memang benar, bukan tracker yang mati. `torrent.ubuntu.com` di-scrape dua kali untuk ketiga entri Ubuntu dalam loop yang sama. Hasilnya 22 lalu 27 seeder untuk 26.04.1, sementara untuk dua entri seedless tracker membalas `d5:filesdee` yang kosong. Hal yang sama berlaku untuk `bt1.archive.org` dan item Prelinger.

TorBox `checkcached` ditanyai tentang setiap hash sebelum ada yang ditambahkan. Ini satu-satunya pemeriksaan cache dari ketiganya yang tidak merusak apa pun. Hasilnya cached untuk tiga baris cached dan uncached untuk enam baris lainnya. Pembagian itulah yang sesuai dengan nama case.

### Jeda polling dan batasnya {#poll-cadence-and-caps}

3 s untuk 2 menit pertama, lalu 15 s. 1 s untuk kasus cached, karena seluruh siklus hidupnya di sana bisa selesai dalam satu polling biasa.
Batasnya 15 menit per torrent untuk kampanye, bukan default skrip sebesar 30. Timeout yang diusulkan shim adalah 10 menit, dan torrent yang masih bergerak di menit ke-15 sudah melewati satu-satunya jendela yang benar-benar penting.
Penambahan ke Real-Debrid diberi jarak minimal 20 s.

Setiap provider berjalan sebagai prosesnya sendiri dengan direktori output-nya sendiri. Dengan begitu, jarak penambahan Real-Debrid tetap akurat di dalam satu proses, dan ketiganya bisa berjalan bersamaan.

---

## Real-Debrid

### Endpoint {#endpoints}

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### Nilai status yang teramati {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

Tidak terlihat di sini. `compressing` `virus` `error` `dead`. Status-status itu butuh konten yang tidak mungkin didapat kampanye ini secara sah.

### Field wire mana yang ada di status mana {#which-wire-fields-exist-in-which-status}

Ini lebih penting daripada kosakatanya. Field bisa muncul dan hilang. Mapper yang membaca `speed` di setiap state akan membaca key yang tidak ada separuh waktu.

| Field | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | ya | ya | ya | ya | ya |
| `progress` | 0 | 0 | **persen float** 0 sampai 100 | **mulai ulang dari 0** lalu naik sampai 100 | 100 |
| `seeders` | ya | **tidak ada** | ya | **tidak ada** | **tidak ada** |
| `speed` | **tidak ada** | **tidak ada** | ya, dalam byte per detik | ya, selalu 0 di capture | **tidak ada** |
| `bytes` / `original_bytes` | 0 | ukuran asli | ukuran asli | ukuran asli | ukuran asli |
| `filename` | `"Magnet"` | nama asli | nama asli | nama asli | nama asli |
| `files` | `[]` | terisi | terisi | terisi | terisi |
| `links` | `[]` | `[]` | `[]` | terisi selama fase itu | terisi |
| `ended` | tidak ada | tidak ada | tidak ada | tidak ada | ada |

`progress` adalah **float**, bukan integer. Capture berisi 0.4, 0.8, dan 1.4 selain 100.
Detektor stall yang membulatkan persen ke integer akan menganggap rilis 100 GB sebagai stall pada kecepatan 1 MB/s.

`progress` **sengaja bergerak mundur**. Nilainya kembali ke 0 saat status berubah menjadi `uploading` lalu naik lagi sampai 100.
Pergerakan harus didefinisikan sebagai perubahan stage atau kenaikan progress, jangan pernah sebagai persentase yang selalu naik.

`seeders` menghilang, bukan menjadi nol, begitu torrent keluar dari `downloading`. `speed` juga begitu.
Mapper harus memperlakukan key yang tidak ada sebagai unknown, bukan sebagai nol.

### Apa yang dilakukan tiap kasus {#what-each-case-did}

| Kasus | Torrent | Transisi dengan detik sejak ditambahkan | Hasil |
|---|---|---|---|
| sudah di-cache | Big Buck Bunny | `downloaded`@0.0 | selesai dalam 1.32 s dari awal sampai akhir |
| sudah di-cache | Sintel | `downloaded`@0.0 | selesai dalam 0.73 s |
| sudah di-cache | Ubuntu 26.04.1 | `downloaded`@0.0 | selesai dalam 0.32 s |
| belum di-cache | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | sudah ada di cache akun ini |
| belum di-cache | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | selesai. 3.71 GiB dalam 197 s |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | gagal |
| tanpa seeder | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | selesai. Kasusnya tidak terulang |
| tanpa seeder | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 dan tidak ada lagi setelahnya | **dihentikan di 907.6 s masih `downloading`**. Ini pola macetnya |
| tanpa metadata | 40-hex acak | `magnet_conversion`@0.0 `magnet_error`@317.9 | gagal |

### Latensi add untuk cache {#the-cached-add-latency}

Ini angka yang jadi dasar mode cached-only shim.

| Torrent | addMagnet mengembalikan | selectFiles mengembalikan | `/torrents/info` pertama | status |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**Hasil pengamatan.** Torrent yang sudah cached langsung `downloaded` pada pembacaan pertama setelah `selectFiles`. Seluruh waktu sinkronnya hanya dua round trip. Status-nya tidak pernah melewati `queued` dan tidak pernah melewati `downloading`.

Run kedua melakukan polling `/torrents/info` tiap 0,25 s, baik di antara `addMagnet` dan `selectFiles` maupun setelahnya. Itu yang dilakukan `--rd-select-detail`, dan hasilnya memperjelas polanya.

| Torrent | Status sebelum `selectFiles` | `selectFiles` | Pembacaan pertama setelahnya | addMagnet sampai `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection` dengan 3 file terdaftar dan `links` kosong | 204 pada t+1.314 s | `downloaded` `progress` 100 `links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection` dengan 11 file terdaftar | 204 pada t+0.627 s | `downloaded` `progress` 100 `links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection` dengan 1 file terdaftar | 204 pada t+0.219 s | `downloaded` `progress` 100 `links` 1 | **0.430 s** |

Jadi urutan lengkap untuk torrent cached adalah `waiting_files_selection` lalu `downloaded`, dan tidak ada status di antaranya. Daftar file sudah ada sebelum `selectFiles`. `links` itulah yang diisi oleh `selectFiles`.

**Jendela probe cached-only bisa hanya satu polling.** Dari ujung ke ujung, waktunya 0,43 s sampai 1,54 s untuk tiga torrent berukuran 123 MiB, 264 MiB, dan 6,04 GiB. Jendela dua detik dengan polling seperempat detik sudah sangat longgar.

Dibandingkan dengan batas 100 s yang diberikan Sonarr dan Radarr untuk satu panggilan `torrents/add` (lihat [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)), jendela probe cached-only beberapa detik itu tidak membebani apa-apa. Tidak ada alasan untuk memasangnya sampai puluhan detik.

### Keanehan yang harus ditangani stage mapper {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` menjawab 404 saat torrent masih di `magnet_conversion`, dan errornya menyesatkan.**
  Body-nya `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}` padahal
  `files=all` sudah dikirim. Memang belum ada file yang bisa dipilih. Ini bukan kegagalan saat add dan torrent-nya tetap hidup.
  Kedua run yang mengalaminya tetap bertahan 318 s.
- **Hash tracker private bisa langsung ditolak, tidak perlu menunggu 318 s.** Hash di balik laporan qBittorrent
  tanggal 2026-08-31 (remux CiNEPHiLES dari indexer UNIT3D, `45e1ec0d…`) menjawab `magnet_error` dengan nol file pada
  pembacaan pertama setelah addMagnet. Tidak ada jendela `magnet_conversion` sama sekali, hanya beberapa detik setelah add.
  Apakah Real-Debrid mengenali hash itu atau langsung gagal, hasil yang terlihat sama: hash private tidak punya swarm DHT,
  jadi addMagnet tidak akan pernah berhasil untuk hash seperti itu, dan selectFiles pada instance yang sudah mati
  akan menjawab 404 yang menyesatkan seperti di atas.
- **`addTorrent` tidak melewati apa pun untuk konten yang belum di-cache, tapi melewati semuanya untuk konten yang sudah di-cache.** File `.torrent` yang diupload untuk konten
  yang tidak dimiliki Real-Debrid (Big Buck Bunny dari archive.org, di-seed tapi belum di-cache) masuk ke `magnet_conversion` seperti magnet biasa. Metadata file-nya
  tidak dipakai untuk resolve. Yang sudah di-cache (ISO Ubuntu) langsung menjawab `waiting_files_selection` dengan daftar file pada pembacaan pertama,
  dipilih, lalu selesai `downloaded` dalam dua detik, tanpa pernah melewati `magnet_conversion`. Jadi nilai upload itu ada pada lookup hash→cache yang instan.
  Inilah yang membuat rilis tracker private bisa ditambahkan kalau kontennya sudah di-cache, dan tidak akan pernah bisa ditambahkan sebagai magnet.
- **Resolusi metadata menyerah setelah 318 s.** Dua run terpisah berpindah dari `magnet_conversion` ke `magnet_error` pada 317.9 s dan 318.0 s. Itu batas yang
  dicapai magnet tanpa peer yang bisa dijangkau. Hasilnya sama, baik untuk hash itu ada torrent-nya atau tidak.
- **`seeders` berbohong selama `magnet_conversion`.** Hash 40-hex acak melaporkan `seeders: 1` pada 80.9 s. Tidak ada torrent untuk hash itu.
- **`ended` pada torrent cached yang baru ditambahkan membawa tanggal lama.** Capture-nya berisi `2025-12-28` dan `2026-07-28` untuk torrent yang ditambahkan pada 2026-08-30. Itu waktu Real-Debrid
  pertama kali memiliki kontennya, bukan waktu instance ini selesai. Jangan hitung umur dari nilai ini.
- **Magnet tanpa peer mati di resolusi metadata dan tidak pernah sampai ke webseed.** Real-Debrid memang menghormati webseed setelah punya torrent-nya. Tapi
  dari magnet tanpa peer, torrent-nya tidak bisa didapat. Jadi item yang hanya punya webseed dan ditambahkan sebagai magnet akan berakhir `magnet_error`. Itu kegagalan
  metadata, bukan kegagalan webseed, dan dari `/torrents/info` keduanya terlihat sama.

---

## AllDebrid

### Endpoint {#endpoints-1}

`v4` dan `v4.1` tidak bisa saling menggantikan, dan perbedaannya ikut berpengaruh di campaign ini.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**Upload file menjawab di bawah `files`, bukan `magnets`.** Field di tiap entri sama, yaitu `id`, `hash`, `name`, `ready`, dan `error` opsional per entri. Jadi flag `ready` di bawah tetap merupakan jawaban cache dalam kedua kasus. Tapi decoder yang ditulis untuk respons magnet akan membaca daftar kosong.

**Dan file adalah satu-satunya bentuk rilis yang bisa dideskripsikan AllDebrid tanpa swarm.** Diukur pada 2026-09-01 di akun uji, dengan dua torrent privat sintetis berbentuk sama yang hash-nya belum pernah dilihat swarm mana pun. Saat diunggah sebagai file, keduanya kembali dengan nama dan ukuran aslinya (`"name":"zurg.private.ad.probe","size":65536`), tercantum sebagai `In queue` dengan jam yang belum berjalan. Saat dikirim sebagai hash `magnets[]` polos, jawabannya adalah `"name":"noname","size":0`. AllDebrid menerimanya tapi tidak tahu apa-apa tentangnya. Ini yang terjadi pada rilis tracker privat mana pun yang ditambahkan lewat hash.

**`/v4/magnet/status` sudah tidak ada.** Dengan atau tanpa id, endpoint ini menjawab HTTP 200 dengan `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. `/v4/magnet/upload` dan `/v4/magnet/delete` masih berfungsi. Jadi asumsi di rencana bahwa endpoint status v4 bisa dipakai dan v4.1 cukup diambil sampelnya sekali untuk dibandingkan itu keliru. v4.1 adalah satu-satunya endpoint status. Harness mencatat satu pembacaan v4 per torrent supaya hasil capture membuktikannya, bukan sekadar mengklaimnya.

Autentikasinya memakai `Authorization: Bearer <apikey>`. Parameter `agent` tidak diperlukan.

### Nilai status yang teramati {#status-values-observed-1}

| `statusCode` | `status` | Seen |
|---|---|---|
| 0 | `In queue` | yes |
| 1 | `Downloading` | yes |
| 2 | `Compressing / Moving` | **no** |
| 3 | `Uploading` | yes |
| 4 | `Ready` | yes |
| 5 and above | the error codes | **no** |

### Field wire mana yang ada di status mana {#which-wire-fields-exist-in-which-status-1}

| Bidang | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | ya | ya | ya | ya |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"` sampai metadata masuk | nama asli setelah metadata masuk | nama asli | nama asli |
| `size` | 0 sampai metadata masuk | ukuran asli | ukuran asli | ukuran asli |
| `downloaded` | 0 | **nilai progres, dalam byte** | sama dengan `size` | **tidak ada** |
| `downloadSpeed` | 0 | ya, byte per detik | 0 | **tidak ada** |
| `seeders` | 0 | ya | 0 | **tidak ada** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **nilai progres untuk fase ini** | **tidak ada** |
| `processingPerc` | 0 | 0 | 0 | **tidak ada** |
| `files` / `nbLinks` | tidak ada | tidak ada | tidak ada | ada |
| `completionDate` | 0 | 0 | 0 | terisi |

**Tidak ada persentase di mana pun.** Progres di AllDebrid adalah `downloaded / size`, dan keduanya
berupa integer dalam byte. `processingPerc` tetap 0 di setiap state, di setiap capture.

`Uploading` adalah saat AllDebrid memindahkan download yang sudah selesai ke penyimpanannya sendiri. Fase ini punya
penghitung progres sendiri di `uploaded` dan `uploadSpeed`, sedangkan `downloadSpeed`-nya selalu 0. Aturan deteksi macet
yang hanya memantau `downloaded` akan menganggap fase `Uploading` yang sehat sebagai macet.

### Apa yang dilakukan tiap kasus {#what-each-case-did-1}

| Kasus | Torrent | `ready` saat upload | Transisi dengan detik sejak ditambahkan | Hasil |
|---|---|---|---|---|
| cached | Big Buck Bunny | true | `Ready`@0.0 | selesai dalam 0.11 s |
| cached | Sintel | true | `Ready`@0.0 | selesai dalam 0.12 s |
| cached | Ubuntu 26.04.1 | true | `Ready`@0.0 | selesai dalam 0.11 s |
| uncached | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | sudah ter-cache |
| uncached | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 dengan semua counter bernilai nol sampai 634.9 `Uploading`@650.1 `Ready`@876.9 | selesai dalam 877 s |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 dan semua counter bernilai nol setelah itu | **dihentikan pada 907.8 s masih `Downloading`** |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 dengan semua counter bernilai nol sampai 589.6 `Uploading`@619.9 `Ready`@650.2 | selesai dalam 650 s |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 dan semua counter bernilai nol setelah itu | **dihentikan pada 907.0 s masih `Downloading`** |
| nometa | 40-hex acak | false | `In queue`@0.0 `Downloading`@9.4 dan semua counter bernilai nol setelah itu | **dihentikan pada 907.4 s masih `Downloading`** |

Satu run terpisah terhadap Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) berhasil menangkap siklus uncached yang lengkap, dan ini jadi urutan acuan.

| Detik | Status | Yang berubah |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` bernilai `"noname"` dan `size` bernilai 0 |
| 2.2 | `Downloading` 1 version 2 | masih belum ada nama dan size |
| 4.3 | `Downloading` | `filename` dan `size` terisi |
| 6.5 sampai 55.1 | `Downloading` | `downloaded` naik sampai `size`. `downloadSpeed` mencapai puncak sekitar 110 MB/s. `seeders` naik dari 8 ke 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` turun ke 0. `uploadSpeed` dan `uploaded` mulai naik |
| 65.6 | `Ready` 4 | `files` dan `nbLinks` muncul. Enam field progres hilang |

3.72 GiB dalam 65.6 s.

### AllDebrid tidak melaporkan progres sama sekali saat job menunggu infrastrukturnya sendiri {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

Ini temuan yang paling mengubah desain timeout, dan butuh dua run independen sampai kami yakin.

`Downloading` dengan `statusCode` 1 muncul dalam hitungan detik setelah upload. Untuk beberapa waktu setelah itu
AllDebrid melaporkan `downloaded` 0 dan `downloadSpeed` 0 dan `seeders` 0 dan `uploaded` 0 dan
`uploadSpeed` 0 dan `processingPerc` 0. Ia juga mengembalikan `size` ke 0 dan `filename` ke info
hash, padahal sebelumnya sudah melaporkan keduanya dengan benar.

| Run | Berapa lama semua counter tetap nol | Apa yang terjadi berikutnya |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 s** dari 12.5 s sampai 634.9 s | 3.71 GiB terunduh dalam 15 s, lalu `Uploading`, lalu `Ready` pada 876.9 s |
| ubuntu-16.04.6-desktop-i386 | **580 s** dari 9.4 s sampai 589.6 s | 1.56 GiB terunduh dalam 30 s, lalu `Uploading`, lalu `Ready` pada 650.2 s |

Keduanya selesai. Tidak satu pun melaporkan pergerakan byte sedikit pun selama sepuluh menit pertama.

**Timeout tanpa pergerakan selama sepuluh menit akan membatalkan job AllDebrid yang sehat.** Nilai default `download_timeout_mins` yang diusulkan, yaitu 10, masuk ke dalam jendela ini dua dari dua kali. Entah timeout harus lebih panjang dari ini, atau AllDebrid `Downloading` dengan `size` 0 harus dihitung sebagai tahap tersendiri yang tidak diawasi oleh jam timeout. Hilangnya nama dan ukuran adalah cara AllDebrid memberi tahu bahwa job sudah ditugaskan tapi belum mulai, dan itu bukan kegagalan.

Run yang langsung mulai menjadi kontrasnya. Debian 13.3.0 arm64 DVD-1 berpindah dari `In queue` ke counter byte yang nyata dalam 6.5 s. Jadi waktu tunggunya adalah antrean, bukan delay tetap.

### Flag `ready` adalah jawaban cache yang nyata {#the-ready-flag-is-a-real-cache-answer}

Field `ready` pada response `/v4/magnet/upload` bernilai true untuk setiap hash yang juga ditandai cached oleh TorBox, dan bernilai false untuk dua hash yang didownload oleh campaign. AllDebrid tidak punya cache probe terpisah, jadi flag ini adalah satu-satunya sinyal cache. Sekarang zurg membawa flag ini dari kedua jalur add, yaitu magnet dan file upload, sebagai `MagnetResponse.Cached` dengan `CacheKnown` diset. Dengan begitu, backend yang tidak bisa menjawab tidak akan pernah salah dikira sebagai backend yang melaporkan miss.

**Nilai `ready` yang false berarti magnet sudah ditambahkan.** Tidak ada cara untuk menanyakan ke AllDebrid apakah sebuah hash sudah cached tanpa menambahkannya dulu. Jalur cached-only di AllDebrid harus menghapus miss tersebut.

---

## TorBox

### Endpoint {#endpoints-2}

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### Nilai status yang teramati {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing` dan `checking` dan `stalledDL` **tidak ada di tabel terjemahan zurg**
(`internal/torbox/types.go` `normalizeStatus`). Ketiganya jatuh ke cabang default dan dilaporkan sebagai `downloading`.

`checking` adalah saat TorBox menunggu metadata, bukan saat memverifikasi hash. Magnet yang swarm-nya tidak pernah merespons akan berstatus `metaDL` lalu `checking`, dan terus di situ. Hash 40-hex acak masih `checking` pada batas 910 detik, dan item Prelinger tanpa peer pada detik ke-911 juga begitu. TorBox tidak pernah menyerah seperti Real-Debrid yang berhenti di 318 detik.

**Mengunggah `.torrent` melewati tahap tunggu itu sepenuhnya, dan itulah perbedaan utamanya untuk rilis private tracker.** Diukur pada 2026-09-01 di akun di atas, torrent private sintetis yang sama dikirim dengan dua cara. Sebagai hash: diterima dengan `torrent_id`, lalu `checking` dengan `name` berisi hash mentah, `size: -1`, `files: null` dan `eta: 8640000`. TorBox mencari swarm yang tidak ada di DHT, dan akan terus begitu sampai batas waktu tanpa melaporkan apa pun. Sebagai file, lewat `POST /torrents/createtorrent` dengan byte-byte di dalam bagian multipart `file`: tiga detik kemudian dibaca kembali dengan nama asli torrent, ukuran aslinya, dan `stalled (no seeds)`. Kontennya sama yang tidak dipegang siapa pun, tapi sekarang sudah dideskripsikan. Tahapnya yang penting. `checking` dengan `size: -1` dipetakan ke `StageResolvingMetadata`, yang artinya pekerjaan masih berjalan dan belum ada kesimpulan yang bisa diambil. `stalled (no seeds)` dipetakan ke `StageStalledNoPeers`, yang bisa ditindaklanjuti oleh endpoint qBittorrent. Rilis yang sudah ter-cache terbaca `done` dengan 100% beserta daftar filenya dalam tiga detik yang sama. Nama part itu penting sekali: file yang dikirim dengan nama lain sama sekali tidak terdeteksi, dan endpoint akan menjawab `MISSING_REQUIRED_OPTION`, "You must provide either a file or magnet link".

(Terjemahan sebelumnya ditolak: span kode berbeda (` maps to `). Pertahankan struktur persis seperti aslinya.)

### Field wire mana yang ada di status mana {#which-wire-fields-exist-in-which-status-2}

TorBox mengirim set key yang sama di setiap state dan hanya mengubah value-nya. Jadi ini yang paling mudah dibaca dari ketiganya. Value-nya yang membawa artinya.

| Kondisi | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | tiny | 8640000 | real |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | real |
| `downloading` | false lalu **true** | false | false | true | fraction | seconds | real |
| `processing` | **true** | **false** | false | true | 1 | seconds | real |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | real |
| `uploading` | true | **true** | true | true | 1 | 0 | real |
| `cached` | true | true | true | false | 1 | 0 | real |

Nama field. Rencana sebelumnya mencantumkan semua ini sebagai belum terverifikasi.

| Apa | Field TorBox | Bentuk |
|---|---|---|
| progress | `progress` | **pecahan dari satu**, bukan persentase. `0.0793719` |
| seeder | `seeds` | integer |
| leecher | `peers` | integer |
| kecepatan download | `download_speed` | byte per detik |
| kecepatan upload | `upload_speed` | byte per detik |
| eta | `eta` | detik. `8640000` adalah nilai placeholder untuk "tidak diketahui" |
| byte yang diambil | `total_downloaded` | integer |
| kesehatan swarm | `availability` | float. Berubah jadi **-1** di `uploading (no peers)` |
| lokasi datanya | `download_path` | null sampai datanya ada |

`8640000` itu 100 hari. Itu cara TorBox bilang kalau dia tidak tahu. Itu juga konstanta yang sama dengan yang dikirim shim zurg ke Sonarr saat tidak ada yang bisa dilaporkan.

### Apa yang dilakukan tiap kasus {#what-each-case-did-2}

| Kasus | Torrent | `checkcached` | Transisi dengan detik sejak add | Hasil |
|---|---|---|---|---|
| cached | Big Buck Bunny | true | `cached`@0.0 | selesai dalam 0.83 s |
| cached | Sintel | true | `cached`@0.0 | selesai dalam 0.94 s |
| cached | Ubuntu 26.04.1 | true | `cached`@0.0 | selesai dalam 0.69 s |
| belum di-cache | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 lalu **hilang**@48.6 | dihapus oleh zurg lain di 86.7% |
| belum di-cache | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 lalu **hilang**@86.7 | dihapus oleh zurg lain |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 dan tidak ada lagi yang lain | **dibatasi di 911.3 s di `checking`**. TorBox tidak memakai webseed |
| tanpa seed | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 lalu **hilang**@200.4 | dihapus oleh zurg lain di `processing` |
| tanpa seed | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 lalu **hilang**@462.3 | dihapus oleh zurg lain di 91.9 persen |
| tanpa meta | 40-hex acak | false | `metaDL`@0.0 `checking`@10.2 dan tidak ada lagi yang lain | **dibatasi di 910.3 s di `checking`** |

Run terpisah dengan poll 0.5 s terhadap Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`) berhasil sampai selesai, dan ini jadi urutan referensi.

| Detik | Status | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB dalam 64.4 s.

Baca tiga baris terakhir dua kali. TorBox mengatur `download_finished` jadi true dan `progress` jadi 1 kira-kira
sepuluh detik **sebelum** data benar-benar ada. Lalu statusnya kembali ke `downloading` dengan nilai progress
yang lebih rendah dari yang baru saja dilaporkan. Baik `progress` maupun `download_state` mundur
padahal download-nya sehat.

---

(Terjemahan sebelumnya ditolak: code span berbeda (`download_state`). Pertahankan struktur persis.)

## Tabel stage {#the-stage-table}

The enum stage yang akan digunakan shim adalah `resolving-metadata` `queued` `downloading` `stalled-no-peers` `finalizing` `done` `failed`, dan string kosong untuk status yang tidak dikenal.

### Real-Debrid

| `status` mentah | Tahap | Dasar |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **diamati**. `bytes` 0, `files` kosong, dan `filename` berisi teks literal `"Magnet"` |
| `waiting_files_selection` | `queued` | **diamati** dengan `--rd-select-detail`. File sudah tampil. `links` kosong |
| `queued` | `queued` | **diamati**. Ukuran dan nama asli sudah diketahui. Tidak ada `seeders` dan tidak ada `speed` |
| `downloading` | `downloading` | **diamati** |
| `downloading` dengan `seeders` 0 | `stalled-no-peers` | **diamati**. 904 s dengan `progress` 0, `seeders` 0, dan `speed` 0 selama 92 polling |
| `compressing` | `finalizing` | **disimpulkan**. Belum pernah terlihat |
| `uploading` | `finalizing` | **diamati**. Progress mulai dari 0 lagi dan `seeders` hilang |
| `downloaded` | `done` | **diamati** |
| `magnet_error` | `failed` | **diamati** setelah 318 s di `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **disimpulkan**. Belum pernah terlihat |

### AllDebrid

| `statusCode` | Tahap | Dasar |
|---|---|---|
| 0 `In queue` | `queued` | **teramati**. Berlangsung beberapa detik. `filename` mungkin masih `"noname"` dan `size` 0 |
| 1 `Downloading` dengan `size` 0 | `queued` | **teramati**. Bukan `downloading` dan bukan `stalled-no-peers`. AllDebrid sudah menerima pekerjaan itu tetapi belum memulainya. Ditahan selama 622 s dan 580 s dalam dua percobaan yang kemudian selesai |
| 1 `Downloading` dengan `size` nyata | `downloading` | **teramati** |
| 1 `Downloading` dengan `seeders` 0 dan `downloaded` tidak bergerak | `stalled-no-peers` | **belum pernah teramati dan tidak bisa disimpulkan dengan aman**. Lihat di bawah |
| 2 `Compressing / Moving` | `finalizing` | **disimpulkan**. Belum pernah terlihat |
| 3 `Uploading` | `finalizing` | **teramati**. `uploaded` dan `uploadSpeed` menunjukkan progresnya di sini, dan `downloadSpeed` bernilai 0 |
| 4 `Ready` | `done` | **teramati** |
| 5 ke atas | `failed` | **disimpulkan**. Belum pernah terlihat |

**AllDebrid tidak punya pola stall yang bisa diamati.** Pekerjaan yang sedang diantre di AllDebrid dan pekerjaan yang tidak bisa maju di AllDebrid terlihat sama persis di jaringan. Keduanya `statusCode` 1 dengan `size` 0 dan semua penghitung bernilai nol. Item Prelinger berada dalam kondisi itu selama penuh batas 907.8 s, dan dua torrent lain berada dalam kondisi itu selama sepuluh menit masing-masing lalu selesai. Jadi tidak ada yang di respons AllDebrid yang bisa membedakan keduanya, dan vonis stall di AllDebrid hanya bisa datang dari penghitung waktu.

### TorBox

| `download_state` mentah | Tahap | Dasar |
|---|---|---|
| `metaDL` | `resolving-metadata` | **diamati**. `size` 0 dan `name` sama dengan hash |
| `checking` | `resolving-metadata` | **diamati**. `size` **-1** selama状态 ini berlangsung. Di sinilah TorBox menunggu torrent, bukan memeriksa hash. Belum ada di tabel zurg saat ini |
| `stalledDL` | `stalled-no-peers` | **diamati**. Belum ada di tabel zurg saat ini |
| `stalled (no seeds)` | `stalled-no-peers` | **diamati**. Nama ini terlalu melebih-lebihkan. Dua tangkapan memiliki `seeds` 1 dan 2 saat berada dalam status ini. zurg saat ini memetakannya ke `queued` |
| `downloading` | `downloading` | **diamati** |
| `processing` | `finalizing` | **diamati**. Belum ada di tabel zurg saat ini |
| `uploading (no peers)` | `finalizing` | **diamati** ketika `download_present` bernilai false |
| `uploading` | `done` | **diamati** ketika `download_present` bernilai true |
| `cached` `completed` `seeding` | `done` | `cached` **diamati**. Dua lainnya **diperkirakan** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **diperkirakan**. Belum pernah terlihat |

**Pasangan `download_finished` dan `download_present` bukan pengganti string status.** Baik
`processing`, `uploading (no peers)`, maupun sebagian `downloading` membawa `download_finished: true` dengan
`download_present: false`. Kombinasi itu adalah fase finalizing yang normal, bukan torrent yang mati. Lihat
peringatan di bawah.

---

## Yang tidak bisa diukur {#what-could-not-be-measured}

- **Kasus seedless berhasil direproduksi pada satu dari dua kandidat.** Keduanya punya nol peer dari tracker.
  ubuntu-16.04.6-desktop-i386 tetap terunduh di ketiga provider karena DHT memberi peer yang tidak diketahui tracker. ubuntu-24.04-beta-live-server-s390x macet di Real-Debrid sampai batas waktunya habis dan inilah observasi macet di atas. Nilai nol dari scrape tracker itu prediktor yang lemah. Tetap simpan dua kandidat di kasus ini. Real-Debrid tetap menyimpan metadata untuk keduanya dan melaporkan `bytes` serta `filename` dengan benar sejak pembacaan `queued` pertama.
- **Status `compressing` dari Real-Debrid tidak pernah terlihat.** Setiap run yang selesai langsung beralih dari `downloading` ke `uploading`.
- **Kode status 2 dari AllDebrid tidak pernah terlihat.** Setiap capture langsung beralih dari 1 ke 3.
- **Tidak ada provider yang sampai memunculkan kosakata error-nya sendiri.** Status `error`, `virus`, dan `dead` dari Real-Debrid, semua kode AllDebrid di atas 4, serta semua status gagal dari TorBox belum pernah diuji. Untuk memunculkannya dibutuhkan konten yang diblokir, terinfeksi, atau kedaluwarsa, bukan ISO FOSS.
- **TorBox jarang bisa dipantau sampai selesai.** Empat torrent kampanye dan satu torrent lanjutan dihapus di tengah unduhan oleh zurg lain di akun yang sama. Lihat bahaya di bawah. Hanya citra 754 MiB yang selesai sebelum proses tersebut melakukan polling berikutnya.

## Bahaya yang ditemukan di jalan {#hazards-found-on-the-way}

### Zurg kedua di akun TorBox menghapus unduhan yang sehat {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

Instance zurg lain dimuat dengan akun TorBox yang sama. Config-nya berbunyi

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**Lima** torrent probe dihapus padahal sedang diunduh dengan normal. Ini **teramati** di
kedua sisi. Harness melihat setiap torrent hilang, dan jurnal instance lain menjelaskan alasannya.

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

Kelima torrent itu adalah `86695315` `86695708` `86697191` `86702627` `86704212`. Semuanya membawa
alasan yang sama. Tidak satu pun dari mereka yang rusak.

Mekanismenya ada di aturan kedua di `normalizeStatus` pada `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

Kombinasi itu adalah fase finalisasi TorBox yang normal. Capture 0.5 s memberi angka pada fase itu. Pada image 754 MiB, jendela dari `download_finished` menjadi true sampai `download_present` menjadi true adalah **9.6 detik**. Pada image 3.7 GiB, jendelanya setidaknya 17 s dan sapuan jatuh tepat di dalam jendela itu. Instance zurg lain memeriksa library kira-kira setiap 15 s. Apakah unduhan TorBox yang sehat bisa bertahan setelah selesai itu hampir seperti lempar koin.

Ada tiga akibatnya. Unduhan TorBox yang dilihat pengguna selesai di UI TorBox bisa hilang dari library zurg mereka. `delete_error_torrents` didokumentasikan sebagai penghapus torrent yang oleh provider dinyatakan rusak, tetapi di sini ia menghapus torrent yang oleh provider dinyatakan baik-baik saja. Dan setiap pengukuran TorBox di akun ini sedang berpacu dengan sapuan itu.

**Belum diperbaiki di sini.** Phase 0 hanya mengukur. Perbaikannya ada di pekerjaan stage. Di sana `download_finished && !download_present` menjadi `finalizing`, bukan `failed`.

### Zurg kedua di akun AllDebrid lolos tanpa masalah {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

Kunci AllDebrid yang dipakai kampanye ini juga dimuat oleh instance zurg lain, dengan tiga setting sweep yang sama seperti di TorBox.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

Tidak ada probe AllDebrid yang dihapus. Alasannya ada di kode, bukan karena kebetulan. `normalizeStatus` di `internal/alldebrid/types.go` hanya memetakan kode status 5 ke atas menjadi `error` dan tidak punya aturan struktural seperti `download_finished && !download_present`. Jadi unduhan AllDebrid yang sehat tidak akan pernah terbaca sebagai rusak. Bug di TorBox ada pada aturan tambahan itu, bukan pada sweep secara umum.

Real-Debrid itu yang berbeda sendiri. Tidak ada zurg lain yang dimuat dengan akun uji, jadi tidak ada yang melakukan sweep ke sana dan tidak ada yang mengganggu.

### TorBox membalas delete untuk id yang tidak dikenal dengan HTTP 500 {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` memberikan jawaban yang sama. Jadi torrent yang sudah tidak ada tidak bisa dibedakan dari gangguan TorBox hanya dari status code. zurg melaporkannya sebagai `account temporarily unavailable`. Journal instance lainnya menunjukkan bahwa ia terus mencoba menghapus id yang sudah dihapus setiap 15 s. Harness mengatasinya dengan meminta `mylist` setelah penghapusan gagal, lalu menganggap torrent yang sudah tidak ada sebagai sudah terhapus.

### Throttling Real-Debrid tidak muncul {#real-debrid-throttling-did-not-appear}

Sembilan penambahan dengan jeda 20 detik menghasilkan nol 451 dan nol 429 selama seluruh kampanye. Ini sesuai dengan catatan di `CLAUDE.md` root bahwa 6 penambahan dengan jeda 10 detik gagal 0/6 dan 6 penambahan yang sama dengan jeda 20 detik berhasil 6/6. Batas minimum 20 detik ini benar-benar berpengaruh dan bukan takhayul.

---

## Menjalankan ulang kampanye {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Jalankan dari mesin dengan residential egress. AllDebrid membalas `NO_SERVER` untuk IP datacenter.

Langkah 6 tidak opsional, dan langkah 3 yang membuatnya berarti. Setelah kampanye 2026-08-30, tidak ada satu pun dari 34 instance id yang diklaim harness yang tersisa di ketiga akun. Begitu juga dengan sembilan probe hash.

Sebelum menyentuh TorBox, cek apakah ada zurg lain yang dimuat dengan akun yang sama, baca pengaturan sweep-nya, dan harapkan sweep seperti yang dijelaskan di atas.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Jangan pernah mengubahnya. Probe yang hilang di tengah run itu adalah data.
