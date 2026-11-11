# Baseline debrid {#the-debrid-baseline}

Apa yang dibutuhkan zurg dan seberapa cepat rasanya di jalur **debrid** — Real-Debrid, AllDebrid
dan TorBox. Di sini tidak ada pesaing. Penantangnya adalah zurg yang lebih baru, dan file ini
adalah tolok ukur yang harus dikalahkannya.

- **Build yang diuji:** `23869fa4` (`2026.08.18.0140-nightly-48-g23869fa4`)
- **Diukur:** 2026-08-19, di `zen` (2 core, 7,6 GB, Ubuntu 22.04)
- **Rig:** `scripts/dbench/`, dipasang di `~/dbench` di zen

## Cara membacanya {#how-to-read-it}

Tiga penyedia ini juga bukan tiga pesaing. Jumlah libraries mereka berbeda dua orde besaran — 3416 torrent di Real-Debrid, 479 di TorBox, 14 di AllDebrid — jadi waktu build dingin dalam angka mutlak lebih banyak bercerita tentang akun daripada tentang zurg. Karena itu, setiap angka yang bergantung pada ukuran juga diberikan per torrent, dan perbandingan yang paling berarti selalu **build ini melawan build berikutnya pada akun yang sama**.

Yang benar-benar bisa dibandingkan antarpenyedia adalah *bentuk* biayanya: berapa banyak panggilan API yang dibutuhkan backend per torrent, apakah ia membayar untuk verifikasi link atau tidak, dan apakah change poll-nya berupa halaman atau token.

## Konfigurasi {#configuration}

Setiap instance menjalankan satu provider, di port sendiri, dengan direktori data sendiri. Perubahan dari default bawaan hanya yang dibutuhkan untuk isolasi:

| Setting | Bench | Alasan |
|---|---|---|
| `host` / `port` | `127.0.0.1`, 9991-9994 | empat instance di satu host |
| `providers` | satu per instance | supaya biaya bisa dikaitkan ke satu backend |
| `rclone_enabled` | `false` | diukur lewat HTTP, tidak pernah lewat FUSE |
| `directories` | satu `all`, tanpa filter | biaya listing jadi fungsi dari ukuran library |
| `enable_repair` | `false` | Zurg lain sudah dimuat dengan akun TorBox yang sama, dan hanya satu instance yang boleh melakukan repair pada sebuah akun |

Semua setting lain dibiarkan di default bawaan *dengan sengaja*, termasuk dua yang sangat memengaruhi angka dan justru jadi temuan tersendiri:

- `log_level: DEBUG` — default bawaan (`pkg/logutil/factory.go`).
- `torrents_rate_limit_per_minute: 75` — default bawaan, dan batasan utama saat build Real-Debrid dari awal (cold).

## Korpus {#corpus}

Ada dua belas rilis, dengan **infohash yang sama di ketiga akun**, jadi perbedaan antar provider berarti perbedaan providernya, bukan filenya. Ukurannya mulai dari episode 1,5 GB sampai paket remux 334 GB. Bentuknya bervariasi: film satu file, season pack, dan series pack 349 file. Entri 0, `The Shawshank Redemption (1994) DS4K`, 7,31 GB, satu file, dipakai sebagai subjek streaming untuk fase latency dan throughput.

Bagian menyusun datanya yang paling merepotkan dan perlu dicatat. Cache TorBox tumpang tindih dengan library Real-Debrid sekitar 2% (3 hit dari 136 probe), jadi korpusnya harus digerakkan dari sisi TorBox, bukan Real-Debrid. AllDebrid tidak punya apa-apa di cache, tapi menerima magnet link secara instan, 14 dari 16. Real-Debrid perlu jeda 20-45 detik antar penambahan karena kena throttle 451, dan menolak dua: satu karena blokir nama deterministik yang sudah didokumentasikan (`Supergirl…WEB-DL…`, ditolak pada percobaan pertama yang bersih setelah jeda tenang tiga menit), dan satu lagi tetap kena throttle.

## Mengukur biaya API {#measuring-api-cost}

zurg tidak menyimpan penghitung permintaan keluar, dan `log_requests` sengaja melewati dua
endpoint Real-Debrid — `torrents/activeCount` dan `torrents?limit=1&…` — yang
keduanya merupakan seluruh poll deteksi perubahan. Jadi kalau jumlahnya dihitung dari log,
biaya idle Real-Debrid akan tercatat nol.

Karena itu, jumlah permintaan diambil dari luar proses. mitmproxy menangani terminasi TLS, sebuah addon menulis
satu baris JSONL per permintaan, dan instance dijalankan dengan `HTTPS_PROXY` dan
`SSL_CERT_FILE` yang mengarah ke CA intersepsi. Loader x509 milik Go menghormati
`SSL_CERT_FILE`, jadi kepercayaan hanya berlaku untuk proses itu saja dan tidak ada yang diubah di host. Permintaan diklasifikasikan sebagai `api`, `nettest`, `content` atau `other`.

Proxy berada di jalur permintaan, jadi hanya dipakai untuk fase biaya API; fase pengukuran waktu berjalan langsung tanpa proxy. Pada TorBox, yang seluruh build-nya hanya terdiri dari empat panggilan, run dengan proxy dan run langsung menghasilkan 3.0 s dan 4.0 s. Jadi pada skala ini, proxy masih berada dalam noise.

## Hasil {#results}

Semua angka dari build `23869fa4` di zen, 2026-08-19. Latency dan throughput berasal dari satu run yang diselang-seling atas file 7.31 GB yang sama — infohash sama di ketiga akun, dan `ffprobe` melaporkan durasi 8552.574 s yang identik lewat masing-masing, jadi kontennya memang byte-identik.

### Pembangunan library dingin {#cold-library-build}

Cache kosong menjadi library terkompilasi. Ini satu-satunya angka yang tidak bisa dibandingkan antar provider, karena jumlah akunnya berbeda dua orde besaran. Jadi, baca kolom per-torrent-nya.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Torrent | 3,316 | 14 | 479 |
| Waktu sampai terkompilasi | **1,774 s** | 1.0 s | 3.0 s |
| Detik per torrent | 0.535 | 0.071 | 0.006 |
| Permintaan API | **7,442** | 7 | 4 |
| Permintaan API per torrent | **2.24** | 0.50 | 0.008 |
| Respons Non-2xx | **756 (10.2%)** | 0 | 0 |
| Byte API yang diterima | 2.87 MB | 27.9 KB | 298 KB |
| Permintaan network-test saat startup | 88 | 88 | 88 |
| Peak RSS | 77 MB | 26 MB | 52 MB |
| Detik CPU | 17.5 | 0.04 | 0.5 |

Dari 7,442 panggilan Real-Debrid, 3,414 adalah `torrents/info`, satu per torrent. Ini tidak bisa dihindari tanpa `ListIncludesFiles`. Sisanya, **3,992 `unrestrict/link`**, adalah verifikasi link proaktif. Real-Debrid adalah satu-satunya backend dengan `StoredLinksCanRot: true`, jadi hanya dia yang menanggung beban ini. TorBox menjawab seluruh scan dengan satu `mylist`, dan inilah yang didapat dari `ListIncludesFiles`.

Build Real-Debrid dijalankan dua kali, dan hasilnya cukup mirip sehingga peningkatan di build berikutnya tidak akan dianggap sebagai noise.

| | Percobaan 1 | Percobaan 2 |
|---|---|---|
| Waktu sampai terkompilasi | 1,774.5 s | 1,759.5 s |
| Permintaan API | 7,442 | 7,391 |
| `unrestrict/link` | 3,992 | 3,933 |
| Non-2xx | 756 | 699 |
| Detik CPU | 17.5 | 16.1 |

#### Apa saja kegagalannya {#what-the-failures-are}

Log alur dari run kedua masih tersimpan, jadi 699 error ini punya rincian:

| Status | Jumlah | Endpoint |
|---|---|---|
| 429 | 589 | `unrestrict/link` |
| 503 | 85 | `unrestrict/link` |
| 404 | **22** | `downloads/delete/{id}` |
| 451 | 3 | `unrestrict/link` |

Ada dua masalah terpisah, dan keduanya bukan "provider-nya lagi bermasalah":

- **589 penolakan rate-limit**, semuanya di `unrestrict/link`. `api_rate_limit_per_minute`
  default-nya 250 dan tidak menjaga unrestrict tetap di bawah batas yang sebenarnya diizinkan Real-Debrid, jadi sekitar 8% dari build dingin (cold build) berupa penolakan dan percobaan ulang.
- **22 dari 23 panggilan `downloads/delete` mengembalikan 404.** Pembersihan yang seharusnya menyeimbangkan 3.992 unrestrict ternyata tidak sekadar jarang berhasil, tapi gagal saat dijalankan. Pembersihan itu menghapus id yang memang tidak ada. Setiap unrestrict membuat entri permanen di daftar downloads akun, dan setelah scan-scan ini akun uji memiliki **12.469** entri.

Ada satu angka yang berubah antar run dan belum bisa dijelaskan: probe HEAD ke `*.download.real-debrid.com` berjumlah 88 di build pertama dan **3.426** di build kedua (sekitar satu per torrent). Angka ini berkorelasi dengan daftar downloads yang makin besar, dan run kedua juga memanggil `/downloads` delapan kali dibanding satu kali di run pertama. Tapi itu baru korelasi, belum tentu penyebab. Perlu dipastikan dulu sebelum mulai dioptimalkan.

### Restart hangat {#warm-restart}

Biaya cold ini memang hanya sekali.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Waktu sampai compiled | 4.0 s | 1.0 s | 2.0 s |
| Permintaan API | 17 | 6 | 4 |
| Permintaan network-test | 8 | 0 | 0 |
| Peak RSS | 77 MB | 27 MB | 39 MB |

1,774 s menjadi 4.0 s, dan 7,442 panggilan menjadi 17.

### Kondisi diam stabil {#idle-steady-state}

Sepuluh menit pustaka yang penuh berjalan tanpa melakukan apa-apa. Urutannya ditentukan oleh seberapa murah setiap backend bisa diminta data, dan ini contoh paling jelas mengapa `LibraryFingerprinter` ada.

| | Panggilan API/menit | Byte API/menit | CPU s / 10 menit | Peak RSS | Yang dikirim |
|---|---|---|---|---|---|
| AllDebrid | **4.0** | **867** | 0.20 | 28 MB | satu delta Live Mode per poll, kosong jika tidak berubah |
| TorBox | 7.9 | 43.6 KB | 0.33 | 53 MB | membaca halaman `mylist`, tidak ada delta feed, tidak ada validator cache |
| Real-Debrid | 11.4 | 59.8 KB | 0.43 | 85 MB | `torrents?limit=1` + `activeCount`, ditambah `/downloads` |

Real-Debrid menghabiskan 32 dari 114 panggilannya untuk mengambil ulang daftar `/downloads`, daftar yang sama yang tumbuh menjadi 12,469 entri saat build dingin.

Tabel ini juga alasan jumlah panggilan dihitung lewat proxy, bukan dari `log_requests`: 80 dari 114 panggilan idle Real-Debrid mengarah ke dua endpoint yang ditekan oleh `ShouldSkipLogging`, sehingga log akan melaporkan biaya idle-nya hampir nol.

### Listing

Tidak ada hambatan di mana pun, pada ukuran library berapa pun.

| | Real-Debrid (3,312) | AllDebrid (14) | TorBox (479) |
|---|---|---|---|
| PROPFIND seluruh library, Depth 1 | 26 ms / 1.17 MB | 1 ms / 5.1 KB | 7 ms / 172 KB |
| Indeks HTML | 14 ms / 645 KB | 1 ms / 2.4 KB | 3 ms / 90 KB |
| PROPFIND satu release, Depth 1 | 1 ms | 11 ms | 3 ms |

### Tekan play {#press-play}

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Buka pertama (cold), 1 MB | 1.294 s | **0.476 s** | 0.565 s |
| Waktu sampai byte pertama, 64 MB | **0.158 s** | 0.203 s | 0.208 s |
| Scrub, median dari 8 | 0.343 s | **0.259 s** | 0.356 s |
| Baca ulang (warm), 64 MB | 2.065 s | 2.163 s | **1.960 s** |
| ffprobe | 1.98 s | 1.34 s | **0.99 s** |
| RSS | 75 MB | **30 MB** | 50 MB |

**Baca ulang yang hangat sama saja dengan baca dingin.** Di jalur Usenet, pembacaan ulang selesai dalam 0.05-0.17 s dari LRU 512 MB; di sini tetap butuh pengambilan penuh, karena jalur debrid hanya meneruskan (proxy) ke CDN dan tidak menyimpan cache apa pun. Dengan `rclone_enabled: false`, ini berarti zurg bekerja sendiri. Pada instalasi normal, VFS cache milik rclone yang menyerapnya. Tetapi sebagai sifat zurg itu sendiri, tidak ada jalur hangat sama sekali.

### Throughput

256 MB pembacaan berurutan, tiga pengulangan, urutan diputar di antara pengulangan.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Rata-rata MB/s | 25.75 | 27.21 | **35.96** |
| Min-maks MB/s | 20.09-29.57 | 17.52-32.21 | **34.31-37.57** |
| CPU detik per GB | 7.8 | **5.3** | 7.9 |
| Median TTFB | 1.023 s | **0.267 s** | 0.489 s |
| RSS puncak | 88 MB | **29 MB** | 55 MB |
| Pembacaan selesai | 3/3 | 3/3 | 3/3 |

TorBox adalah yang tercepat sekaligus paling stabil. Dua lainnya berfluktuasi hingga 40% antar pengulangan. Median TTFB Real-Debrid di bawah beban empat kali lipat dari AllDebrid.

### Ke mana waktu buka dingin sebenarnya habis {#where-cold-open-actually-goes}

`apiref.py` mengukur bagian milik provider sendiri, yaitu panggilan yang mengubah file tersimpan menjadi URL yang bisa diambil, dan byte pertama dari URL itu, dengan zurg tidak ikut di jalurnya. Script ini dijalankan dua kali. Run pertama dibuat sebelum perbaikan AllDebrid, jadi baris itu hanya punya satu sampel.

| | resolve | CDN TTFB | total provider | zurg cold open | porsi zurg |
|---|---|---|---|---|---|
| Real-Debrid, run 1 | 0.133 s | 0.267 s | 0.400 s | 1.294 s | **0.89 s** |
| Real-Debrid, run 2 | 0.157 s | 0.383 s | 0.540 s | 1.294 s | **0.75 s** |
| AllDebrid | 0.139 s | 0.333 s | 0.472 s | 0.476 s | 0.00 s |
| TorBox, run 1 | 0.260 s | 0.277 s | 0.537 s | 0.565 s | 0.03 s |
| TorBox, run 2 | 0.270 s | 0.381 s | 0.651 s | 0.565 s | ~0 |

Angka provider dan angka zurg diambil pada waktu yang berbeda, jadi selisihnya hanya perkiraan, bukan angka yang tepat. Polanya tetap sama di kedua run: AllDebrid dan TorBox hampir tidak menambah waktu di luar biaya provider itu sendiri, sedangkan Real-Debrid menambah 0.75-0.89 s. Selisih itulah yang paling jelas perlu kita perbaiki.

### Ketiga provider dalam satu instance {#all-three-providers-in-one-instance}

Instance yang digabung membawa semua akun sekaligus, dan korpus uji ini sengaja ada di ketiganya, jadi ini menguji jalur saat satu rilis dipegang oleh beberapa akun.

| | Hanya Real-Debrid | Ketiganya digabung |
|---|---|---|
| Torrent yang terlihat | 3,316 | 3,781 |
| Rilis unik | 3,318 | 3,778 |
| Waktu sampai compiled | 1,774 s | 1,775 s |
| Permintaan API | 7,442 | 7,491 |
| RSS puncak | 77 MB | 82 MB |
| PROPFIND seluruh library | 26 ms / 1.17 MB | 23 ms / 1.34 MB |

Menambahkan TorBox dan AllDebrid ke instance Real-Debrid hampir tidak memakan biaya: ada 465 torrent tambahan dengan 49 panggilan API tambahan dan 5 MB RSS, dan waktunya tidak terasa berbeda. Penggabungannya memang nyata. 3,809 torrent dari ketiga akun jika dihitung terpisah menjadi 3,781 di sini, karena korpusnya turun dari tiga salinan menjadi satu.

### Deteksi tambah dan hapus {#add-and-delete-detection}

Berapa lama dari perubahan di provider sampai mount sudah sama.

| | Delete detected | Add detected |
|---|---|---|
| Real-Debrid | 18.7 s | 12.7 s |
| AllDebrid | 16.5 s | 14.4 s |

Keduanya masih dalam satu tick `check_for_changes_every_secs` ditambah satu refresh, jadi tidak ada yang menunggu `library_resync_every_mins`. TorBox tidak diuji: release probe-nya ada terus di akun itu, dan menghapusnya tidak bisa dibatalkan tanpa add ulang yang mungkin tidak ter-cache.

### Outage provider, CDN tetap up {#provider-outage-cdn-up}

`ca/outage.py` membuat setiap panggilan API provider mengembalikan 503, sementara permintaan konten tetap diteruskan. Setelah itu zurg dijalankan ke dalam kondisi tersebut.

| | Dibaca sebelum | Library dikompilasi saat outage | Dibaca saat outage |
|---|---|---|---|
| Real-Debrid | 206, 1.60 s | tidak pernah (180 s) | timeout pada 120 s |
| AllDebrid | 206, 0.44 s | tidak pernah (180 s) | timeout pada 120 s |
| TorBox | 206, 1.53 s | tidak pernah (180 s) | 400 dalam 0.035 s |

**Memulai zurg saat provider-nya sedang down menghasilkan mount yang kosong.** Ini skenario yang paling penting secara operasional, yaitu host reboot saat Real-Debrid sedang 503, dan ini kondisi yang persis menghancurkan puluhan ribu item Plex di `fun` pada Agustus. Saat itu mount yang kosong sesaat selama scan terbaca sebagai "semua file sudah dihapus". Pengamannya ada di Plex (`autoEmptyTrash 0`), bukan di zurg.

Real-Debrid dan AllDebrid juga membuat reader menunggu sampai timeout-nya sendiri, alih-alih gagal dengan cepat. TorBox menjawab dalam 35 ms.

### 503 sementara membuat rilis jadi folder kosong {#a-transient-503-leaves-releases-as-empty-folders}

Cacat paling jelas dari run ini, dan ditemukan secara kebetulan.

Dari 3,316 torrent dalam cold build Real-Debrid, **85 respons adalah 503** dan **84 torrent berakhir di `broken_torrent`**. Rilis dalam kondisi itu masih tercantum di mount, tetapi direktorinya **kosong**. Hal ini sudah diverifikasi lewat PROPFIND pada dua di antaranya. Keduanya menyimpan 10 dan 3 file terpilih di catatan tersimpan, tetapi tidak menyajikan satu file pun.

Kondisi ini tidak hilang dengan sendirinya. Bench berjalan dengan `enable_repair: false`, dan rilis-rilis tersebut masih rusak lebih dari satu jam dan beberapa kali restart kemudian.

Mengaktifkan repair (default bawaan) memang mengerjakannya, tetapi lambat. Dengan pass yang dipicu secara manual:

| Waktu berlalu | Rusak | Sedang diperbaiki |
|---|---|---|
| 0 menit | 85 | 0 |
| ~2 menit | 77 | 2 |
| ~15 menit | 73 | 4 |

Dua belas rilis dalam seperempat jam, dan lajunya melambat setelah beberapa menit pertama. Dengan laju seperti ini, kerusakan sebanyak satu cold build butuh lebih dari satu jam untuk dibereskan, dan setiap rilis yang belum terjangkau akan menjadi folder kosong selama itu.

Jadi tingkat keparahannya bergantung pada satu setting:

- Dengan repair aktif (default), 503 saat scan membuat rilis kehilangan file-filenya sampai pass repair menjangkaunya. Untuk library penuh, itu kira-kira satu jam.
- Dengan repair nonaktif, rilis tersebut menjadi folder kosong tanpa batas waktu.

TorBox punya versi yang lebih parah. Ia melaporkan `StoredLinksCanRot: false`, sehingga refresh tidak pernah memverifikasi ulang link-nya. Tidak ada jalur lain untuk menghapus kondisi rusak selain repair. Satu rilis TorBox yang ditandai rusak selama uji outage masih rusak 68 menit dan beberapa kali restart kemudian, padahal provider-nya melaporkan `cached`, `download_present`, satu file, 7.31 GB.

### Integritas baca {#read-integrity}

Dalam throughput run pertama, satu read dari AllDebrid mengembalikan 263.798.425 byte untuk range 268.435.456 byte, dengan status 206 dan tanpa error. Kejadian ini **tidak bisa direproduksi**: delapan kali pengulangan di Real-Debrid dan AllDebrid masing-masing selalu mengembalikan range penuh. Saya catat sebagai kejadian sekali saja, bukan defect, tapi tetap perlu diwaspadai.

## Di bawah beban Plex {#under-plexs-load}

Semua di atas hanya satu pembaca dalam satu waktu, dan itu bukan cara media server bekerja.
Plex memindai — ribuan file, sedikit demi sedikit — dan Plex juga melakukan streaming, dan keduanya saling tumpang tindih. Fase-fase ini mengukur mount di bawah kedua beban tersebut.

**Baca angka agregat sebagai sifat dari zen, bukan dari zurg.** Setiap target mentok di 73-78 MB/s apa pun providernya dan apa pun modenya, yang merupakan batas link host. Yang bisa digeneralisasi adalah *tingkat penyelesaian* dan pola kegagalan per provider; batas atasnya ada di lokal.

### Banyak reader, file berbeda, satu provider {#multiple-readers-different-files-one-provider}

96 MB per stream, file yang berbeda-beda.

| stream | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 1 | 44.8 | 52.1 | 45.6 | 51.8 |
| 2 | 72.3 | 63.5 | 71.4 | 69.8 |
| 4 | 73.7 | 64.2 | 74.6 | 70.2 |
| 8 | 73.6 | 73.4 | 65.5 | 75.1 |
| 12 | 77.1 | 73.8 | 76.3 | 77.1 |

Agregat MB/s. Pipa sudah penuh di dua stream; lebih dari itu, pembaca tambahan hanya membagi
bandwidth yang sama. Median per stream turun dari sekitar 45 MB/s di satu stream menjadi sekitar 8 MB/s di dua belas stream.

Kolom penyelesaian ini yang paling menarik:

| stream | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 4 | 4/4 | **2/4** | 4/4 | 4/4 |
| 8 | 8/8 | **3/8** | 8/8 | 8/8 |
| 12 | 10/12 | **4/12** | 9/12 | 10/12 |

**AllDebrid berhenti menyelesaikan pembacaan dari empat file berbeda yang dibaca bersamaan.** Data masih
mengalir. Agregatnya tetap di batas host, tetapi stream satu per satu tidak selesai,
dan median per stream turun ke nol di delapan dan dua belas stream, dengan median TTFB di atas
3 s. Sisanya masih lancar sampai dua belas stream, di mana keempatnya kehilangan satu atau dua.

> **Dicabut 2026-08-23. Ini bukan batas konkurensi provider.** Diuji ulang langsung ke API
> dengan bitrate pemutaran yang dibatasi, bukan dengan kecepatan penuh lewat zurg, AllDebrid
> berhasil me-resolve **4/8/12/16/24 link berbeda yang berjalan bersamaan dengan 100%** dan menjaga **24/24** stream live.
> Kegagalan di atas disebabkan oleh **tiga host CDN AllDebrid yang null-routed**:
> `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`. Ketiganya di-resolve ke `0.0.0.0` dan
> menampung **15,6% dari link yang berhasil di-resolve**. Host pertama sama dengan host yang tercatat sebagai link mati sekali saja di bagian bawah dokumen ini; ternyata bukan kejadian sekali saja.
>
> Host mati hanya gagal jika file-nya ada di dalam batch, jadi jumlah kegagalan naik seiring N
> dan bentuknya persis seperti batas konkurensi. **Setiap ladder yang menarik lebih banyak file berbeda saat naik akan menghasilkan hasil palsu yang sama.**
>
> Seluruh kolom penyelesaian di sini terbatas oleh metode yang sama. Pengujiannya menarik data dengan kecepatan penuh
> lewat link yang jenuh di 73–78 MB/s, jadi yang diukur adalah **pembagian bandwidth, bukan batas provider**. Batas per host yang sebenarnya, semuanya tidak terdokumentasi, adalah Real-Debrid **32**
> (dijatuhkan di lapisan TCP), AllDebrid **32** (HTTP 429), TorBox **20** per host `nexus-NNN`
> (HTTP 429, per host, bukan per IP), dan tidak ditemukan batas untuk Premiumize pada 64.
>
> Satu catatan agar tidak salah membaca pencabutan ini: host null-routed gagal dalam sekitar 0,1 s,
> sedangkan median TTFB di atas berjalan lebih dari 3 s. Itu kegagalan lambat dengan
> ciri yang berbeda, jadi kemungkinan besar bandwidth starvation juga ikut terjadi. Keduanya menunjuk jauh dari batas provider.
>
> **Perbaikan yang tersirat dari ini:** perlakukan kegagalan tingkat koneksi pada host CDN AllDebrid sebagai sesuatu yang bisa dicoba ulang dengan **membuka kunci link lagi**. `/link/unlock` yang baru akan mengembalikan host yang berbeda. Jangan kurangi konkurensi. Pencarian DNS yang menolak `0.0.0.0` menangkap semua kasus yang terlihat di sini dan tidak memakan biaya apa pun.

### Banyak reader, satu file {#multiple-readers-one-file}

Level yang sama, satu file, offset berbeda — pola read-ahead ditambah seek.

| stream | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| 4 | 4/4 | 4/4 | 4/4 |
| 8 | 8/8 | 8/8 | 8/8 |
| 12 | 10/12 | 9/12 | 10/12 |

Di sini AllDebrid **baik-baik saja** — 4/4 dan 8/8 — padahal sebelumnya 2/4 dan 3/8 pada file yang berbeda.
Pembalikan ini adalah diagnosisnya: batasnya bukan bandwidth dan bukan batas per torrent, melainkan **link resolution** yang bersamaan. File yang berbeda berarti unlock yang berbeda; satu file hanya di-resolve sekali lalu tinggal streaming.

> **Dicabut 2026-08-23** — pembalikan ini punya penjelasan yang lebih sederhana. File yang berbeda menggunakan host CDN yang berbeda, dan tiga milik AllDebrid di-null-route; satu file hanya di-resolve ke satu host, dan hasilnya bisa berhasil atau tidak. Link resolution sendiri sudah diukur dan bersih pada 24 bersamaan. Lihat catatan di atas.

### Banyak reader di provider berbeda {#multiple-readers-across-different-providers}

Ini kasus provider campuran, dan butuh korpus yang tidak bisa diberikan oleh korpus yang cocok. Karena instance gabungan melayani rilis multi-akun dari `Sources[0]`, setiap pembacaan dari korpus yang cocok selalu jatuh ke Real-Debrid. Jadi pool di sini bersifat provider-*eksklusif*: 8 file hanya dimiliki Real-Debrid, 7 hanya AllDebrid, dan 8 hanya TorBox.

| stream (per provider) | agregat MB/s | selesai | RD | AD | TB |
|---|---|---|---|---|---|
| 3 (masing-masing 1) | 55.3 | 2/3 | 28.8 | — | 27.9 |
| 6 (masing-masing 2) | 66.9 | 5/6 | 16.1 | 13.3 | 21.5 |
| 12 (masing-masing 4) | 75.9 | 11/12 | 7.4 | 8.4 | 9.0 |

Kolom per provider adalah median per-stream dalam MB/s.

Pembacaan di akun yang berbeda memang berjalan paralel, tapi semuanya tetap sampai ke batas host 76 MB/s yang juga bisa dicapai satu provider sendirian. **Di host ini, mencampur backend tidak menambah bandwidth.** Apakah itu menambah bandwidth di tempat lain tergantung pada punya link yang lebih lebar daripada yang bisa diisi satu provider, dan zen tidak punya. Yang didapat justru ketersediaan, dan itu pun hanya sebagian, seperti terlihat di bagian failover di bawah.

Satu-satunya kegagalan yang konsisten adalah satu file AllDebrid yang hostname CDN-nya, `l4m5n6.debrid.it`, resolve ke **0.0.0.0**. Itu AllDebrid yang memberikan tautan mati, bukan zurg. Tapi zurg menghabiskan sekitar 4 detik untuk tiga kali retry sebelum mengembalikan 500, dan karena file ini tidak ada di akun lain, tidak ada yang bisa dijadikan cadangan.

### Failover: hanya dari satu arah {#failover-only-from-one-direction}

Karena instance gabungan tidak bisa membagi beban, manfaat yang seharusnya didapat adalah tetap bertahan saat satu akun bermasalah. `ca/cdnfail.py` menolak CDN satu akun sambil membiarkan semua API dan akun lain tetap normal, jadi library tetap bisa dimuat dan hanya data file yang terpengaruh. Rilis yang dibaca adalah korpus yang cocok, dan ketiga akun menyimpan semuanya.

| CDN yang dimatikan | pembacaan yang berhasil | apa yang dilakukan pembacaan |
|---|---|---|
| Real-Debrid | 2/2 | beralih ke AllDebrid, 0.6 s |
| AllDebrid | **0/3** | satu percobaan di AllDebrid, 503, lalu **500 ke klien dalam 0.1 s** |

**Failover hanya terjadi saat akun yang gagal adalah Real-Debrid**, dan alasannya adalah kemampuan yang tidak diatur oleh backend lain. Refresh memverifikasi link secara proaktif hanya saat `StoredLinksCanRot` bernilai true, dan itu hanya Real-Debrid:

```
Link verification failed during refresh for /A.Business.Proposal…: (code: 503)
```

Itulah yang menurunkan peringkat sumber, setelah itu pembacaan berpindah ke akun lain dengan rapi. AllDebrid dan TorBox tidak pernah diperiksa, jadi CDN yang mati di salah satunya tidak pernah terdeteksi, sumbernya tidak pernah diturunkan, dan setiap pembacaan rilis itu mengembalikan 500, selama kondisinya masih ada.

Ada dua hal lagi yang terlihat dari ini:

- **Jalur baca sama sekali tidak punya fallback inline.** 503 dari CDN akun yang dipilih langsung diubah menjadi 500 untuk klien dalam 0.1 s; akun lain yang menyimpan file yang sama tidak dicoba. Pemulihan sepenuhnya menjadi tugas refresh di latar belakang, jadi bahkan dalam kasus Real-Debrid ada jeda waktu saat pembacaan gagal.
- Ini mekanisme yang sama hilangnya di balik rilis TorBox yang tetap `broken_torrent` selama 68 menit. Tidak ada yang memverifikasi ulang link TorBox atau AllDebrid, jadi tidak ada yang menghapus status buruk atau menyadari saat sudah pulih.

### Link mati dari provider {#a-dead-link-from-the-provider}

Satu file AllDebrid di pool eksklusif gagal setiap kali dicoba, di setiap scan run dan setiap mixed-reader run. Hostname CDN-nya di-resolve ke null route:

```
$ getent hosts l4m5n6.debrid.it
::              l4m5n6.debrid.it
0.0.0.0
```

AllDebrid memberikan link yang mengarah ke `0.0.0.0`. Bagian itu masalah provider, bukan zurg. Yang menjadi tanggung jawab zurg adalah apa yang dilakukan setelahnya: tiga kali percobaan selama sekitar 4 s, lalu 500. File ini tidak ada di akun lain, jadi memang tidak ada yang bisa dijadikan cadangan. Tapi hasil failover di atas menunjukkan bahwa zurg tetap tidak akan fallback meskipun ada.

> **2026-08-23: bukan satu host, dan bukan satu file.** Tiga hostname CDN AllDebrid di-null-route sekaligus: `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`. Ketiganya menyumbang **5 dari 32 link di satu sampel dan 4 dari 32 di sampel lain, untuk konten yang tidak berhubungan**. AllDebrid terus memberikan host mati yang sama untuk file yang berbeda, dan masih begitu beberapa hari setelah run ini. Ini adalah lubang yang terus ada di armada mereka, dan inilah yang memunculkan temuan concurrency yang sudah ditarik di atas.
>
> Tiga kali percobaan dan 500 itu respons yang salah. **Sebaiknya unlock ulang**: `/link/unlock` mengembalikan host yang berbeda. Lakukan juga pre-flight dengan DNS lookup yang menolak `0.0.0.0`, karena cara ini menangkap setiap kasus yang teramati tanpa biaya apa pun.

### Scanning

`ffprobe` di seluruh 23 file campuran, yang merupakan pola dari pass analisis Plex.

| concurrency | files/min | per-file median | per-file max | CPU s |
|---|---|---|---|---|
| 1 | 43.7 | 1.16 s | 3.11 s | 2.22 |
| 4 | 112.0 | 1.67 s | 4.19 s | 1.29 |
| 8 | 142.3 | 1.87 s | 6.67 s | 1.16 |

Pemindaian ternyata cukup baik dijalankan paralel: 3,3x dari satu thread ke delapan, dengan latensi per file hanya naik 60%. Untuk library Real-Debrid berisi 3.316 release, itu kira-kira **76 menit dengan satu thread dan 23 menit dengan delapan**, belum termasuk pekerjaan Plex sendiri.

### Streaming sambil scanning {#streaming-while-scanning}

Kasus yang perlu diwaspadai adalah scan terhadap mount yang sedang bermasalah sesaat, karena itulah yang membuat
puluhan ribu item Plex hilang di `fun`.

| concurrency scan | stream sendiri | stream saat scan | dipertahankan | waktu scan keseluruhan |
|---|---|---|---|---|
| 4 | 57.7 MB/s | 66.5 MB/s | 115% | 11.8 s |
| 8 | 67.8 MB/s | 66.8 MB/s | 98.5% | 9.7 s |

**Scan tidak membuat stream kekurangan.** Penonton tetap mendapatkan hampir seluruh throughput-nya, dan waktu hingga byte pertama justru membaik (1.18 s menjadi 0.15 s) karena koneksinya sudah hangat pada saat itu. Ini satu-satunya bagian di mana jalur debrid berperilaku lebih baik dari yang dikhawatirkan.

## Defect yang ditemukan run ini {#defects-this-run-surfaced}

**503 sementara membuat rilis jadi folder kosong.** 85 x 503 selama satu cold build membuat 84 rilis masuk ke `broken_torrent`, dan rilis yang rusak ditampilkan tanpa file apa pun di dalamnya. Dengan repair nonaktif, status ini tidak pernah hilang. Dengan repair aktif, status ini hanya hilang saat sebuah pass menjangkaunya. Di TorBox sama sekali tidak ada jalur verifikasi ulang (`StoredLinksCanRot: false`), dan satu rilis yang rusak di sana masih rusak 68 menit kemudian, padahal provider melaporkan rilis itu cached dan tersedia.

2. **Pembersihan download-entry rusak, dan biayanya menumpuk.** 3.992 `unrestrict/link` berbanding 23 `downloads/delete`, dan **22 dari 23 itu mengembalikan 404**. Pembersihannya menghapus id yang tidak ada. Jumlah entri akun naik dari 12.469 menjadi **18.768** selama dua cold build berikutnya. zurg membaca seluruh daftar per 5.000 saat startup, jadi kebocoran ini berubah menjadi biaya startup yang ikut membesar.

3. **589 penolakan rate-limit dalam satu cold build.** Semuanya di `unrestrict/link`, sekitar 8% dari pass. Default `api_rate_limit_per_minute: 250` tidak menjaga unrestrict tetap di dalam batas nyata Real-Debrid. Ini dan 503 tadi adalah kejadian yang sama yang memicu defect 1.

4. **Startup saat provider sedang outage menghasilkan mount kosong.** Read ke Real-Debrid atau AllDebrid lalu menggantung sampai timeout client sendiri, alih-alih gagal cepat. TorBox menjawab 400 dalam 35 ms.

5. ~~**AllDebrid berhenti menyelesaikan read bersamaan untuk file yang berbeda.**~~ **Dicabut 2026-08-23. Lihat catatan di "Multiple readers, different files" di atas.** Penyebabnya adalah tiga host CDN AllDebrid yang null-routed membawa 15,6% link, bukan batas concurrency. Saat diuji ulang langsung, AD menyelesaikan 24 link berbeda secara bersamaan dengan tingkat keberhasilan 100% dan mempertahankan 24/24 stream. Teks asli disimpan di bawah untuk catatan.

   2 dari 4, 3 dari 8, 4 dari 12. Level yang sama terhadap *satu* file baik-baik saja (4/4, 8/8), jadi batasnya ada pada resolusi link yang berjalan bersamaan, bukan bandwidth atau cap per torrent. Empat file diputar bersamaan adalah hal biasa di malam hari untuk satu rumah tangga.

6. **Rilis dengan banyak akun selalu disajikan dari akun yang sama.** `File.PrimarySource` mengembalikan `Sources[0]`, jadi pilihannya adalah akun yang pertama kali terlihat. Terverifikasi 7 dari 7 rilis corpus disajikan oleh Real-Debrid, padahal AllDebrid dan TorBox memegang salinan yang identik. Sistem ini tidak pernah memilih akun yang lebih cepat atau yang beban kerjanya lebih ringan.

7. **Failover hanya berjalan satu arah, dan tidak pernah inline.** Saat CDN Real-Debrid menolak, read berpindah ke AllDebrid. Saat CDN AllDebrid menolak, 0 dari 3 read berhasil dilayani, dan masing-masing mengembalikan 500 dalam 0,1 detik tanpa mencoba dua akun yang memegang file yang sama. Hanya Real-Debrid yang mengatur `StoredLinksCanRot`, jadi hanya link-nya yang diverifikasi ulang saat refresh, dan hanya kegagalannya yang menurunkan source. Tidak ada yang di read path mencoba akun kedua saat terjadi error.

8. **Tes jaringan saat startup berjalan untuk setiap backend.** Ada 88 HEAD request ke host download Real-Debrid pada instance yang hanya TorBox dan instance yang hanya AllDebrid, padahal keduanya tidak membutuhkan hasilnya.

9. **href PROPFIND milik collection itu sendiri menghasilkan 404.** zurg mengeluarkan `<d:href>/all/…</d:href>`, menghilangkan prefix `/dav`, dan mengambil path itu mengembalikan 404. Child dikeluarkan sebagai href relatif polos, jadi hanya entri self yang salah. RFC 4918 menghendaki href yang bisa di-resolve oleh client. rclone dan Plex hanya bisa berfungsi karena mereka tidak memakainya.

10. **`user`/`user/me` dipanggil tiga kali setiap startup**, cold maupun warm, di TorBox dan AllDebrid.

## Bukan defect, tapi perlu diketahui {#not-defects-but-worth-knowing}

- **Real-Debrid tidak melakukan deduplikasi berdasarkan infohash.** Menambahkan magnet yang sudah ada di akun akan membuat entri *kedua*. Itulah sebabnya 3,416 torrent menjadi 3,318 rilis unik, dan hal ini membuat probe deteksi penghapusan yang pertama tidak valid: probe itu menghapus duplikat yang baru saja dibuatnya lalu menyimpulkan bahwa tidak ada yang pernah terdeteksi.
- **`torrents_rate_limit_per_minute` default-nya 75**, dan angka inilah yang membatasi build Real-Debrid cold. Ini memang default yang disengaja, bukan bug, tetapi angka ini juga yang menentukan angka 29 menit.

## Menjalankan ulang {#rerunning}

```bash
cd ~/dbench && ./runall.sh          # p1..p6
./p7.py adddel rd,ad && ./p7.py outage rd,ad,tb
./apiref.py rd,ad,tb                # provider-side reference latency
./report.py                         # tables
```

Jangan pernah menjalankan dua instance sekaligus, dan hanya bandingkan angka dari satu run yang diinterleave — kecepatan provider bisa berubah jauh sepanjang malam.
