# Batas TorBox dan cara zurg menyesuaikan diri {#torbox-limits-and-how-zurg-adapts-to-them}

zurg-nya perilaku library tumbuh dari batasan Real-Debrid. Batasan TorBox berbeda secara jenis, bukan hanya besarnya, dan kalau diperlakukan seperti Real-Debrid, akun akan kena rate-limit hanya dalam hitungan detik setelah scan library pertama. Berikut batasan-batasannya, dari mana angkanya berasal, dan apa yang dilakukan zurg untuk masing-masing.

Batasan provider dideklarasikan di kode sebagai `debrid.Capabilities`, jadi kode library generik membacanya dan tidak mengasumsikan sendiri. Untuk menambah backend, cukup isi struct tersebut, tanpa perlu mengedit torrent manager.

## Batas permintaan {#rate-limits}

| Batas | Nilai | Sumber |
|---|---|---|
| Semua endpoint digabung, per API token | 300/min | [didokumentasikan](https://api-docs.torbox.app/) |
| `POST /torrents/createtorrent` (hanya uncached) | 60/jam | didokumentasikan |
| `POST /webdl/createwebdownload`, `POST /usenet/createusenetdownload` | 60/jam | didokumentasikan |
| `GET /torrents/requestdl` | **~100 panggilan, lalu 429**. Ini budget, bukan rate | diukur, 2026-08-30 |
| Koneksi bersamaan ke satu host CDN | **tepat 20**, 429 jika lebih | diukur, 2026-08-23 |
| Batas lonjakan global | aktif di ~40 bersamaan, membatasi *semua* endpoint | diukur |
| Pemulihan 429 | `Retry-After: 300`, batas biner | diukur |

Batasnya berlaku per API token dan disinkronkan di server TorBox. Jadi bukan per IP, artinya klien tambahan di mesin lain ikut memakai budget yang sama. TorBox juga sudah bilang begitu secara eksplisit: mereka berhenti menerima permintaan whitelist IP karena batasnya terikat ke token.

Ada tiga hal yang membuat kondisinya lebih ketat daripada yang terlihat dari angka 300/min:

- **300/min itu bukan per endpoint.** Itu satu budget yang dipakai seluruh key, jadi kalau setiap endpoint diatur pacing-nya secara terpisah, jumlah gabungannya bisa melewati batas yang tidak akan dilewati satu endpoint pun kalau dilihat sendiri-sendiri.
- **`requestdl` jauh lebih ketat dari yang didokumentasikan, dan ini bukan rate.** Endpoint inilah yang membuat URL download, dan ia menyerah setelah sekitar 100 panggilan, sementara `user/me`, `mylist`, dan `checkcached` tetap jalan lancar di 500+ panggilan dengan konkurensi yang sama.

  Memperlambat tidak menambah jumlahnya. Diukur pada 2026-08-30 di akun utama, tiga kali percobaan, masing-masing mulai dari kondisi lockout yang sudah dibersihkan:

  | Pacing | 429 muncul di | Waktu berlalu |
  |---|---|---|
  | secepat mungkin, dinaikkan 60→240/min | panggilan **100** | 56s |
  | satu per detik (60/min) | panggilan **94** | 108s |
  | satu tiap dua detik (30/min) | panggilan **101** | 198s |
  | satu tiap tiga detik (20/min) | **tidak pernah**, 241 panggilan | 721s, bersih |

  Memperlambat setengahnya memberi tambahan sembilan puluh detik tapi tidak menambah panggilan; memperlambat setengah lagi membuat 429 sama sekali tidak muncul. Yang dipegang akun ini adalah **100 panggilan per lima menit bergulir, yaitu 20/min**, dan hanya pembacaan itu yang cocok dengan keempat percobaan: ia memprediksi lockout di t≈100s, t≈200s, dan langsung untuk tiga percobaan pertama, serta memprediksi percobaan keempat tepat di batas dan tetap lolos.

  Ini koreksi paling penting saat membaca sisa file ini. Limiter per menit tidak akan bisa menjaga zurg tetap di bawah budget, jadi angka pacing di bawah ini lebih berfungsi untuk membuat alurnya halus daripada memberi ruang cadangan. Limiter yang lebih cepat tidak membuat pemindaian library selesai lebih cepat. Ia hanya mencapai lockout yang sama lebih cepat, dan saat itu terjadi mount tidak merespons apa pun selama lima menit. Satu-satunya cara untuk menambah jauh sejauh mana pemindaian bisa berjalan adalah dengan memakai *lebih sedikit* panggilan. Itu alasan read-ahead ditolak di sini, dan kenapa memberi nama pada file yang sudah di-resolve tidak boleh pernah memakan satu request pun.
- **429 itu seperti tebing, bukan lereng.** Begitu terpicu, 100% request gagal selama sekitar lima menit. Tidak ada penurunan throughput sebagian yang bisa dijalani begitu saja.

Download CDN dihitung terpisah dan **tidak** memakai budget API. Men-stream file tidak pernah memakan kuota resolve link. Ini sudah diverifikasi dari dua arah: download CDN yang dijenuhkan sampai 429 tidak membuat `requestdl` berhenti menjawab normal, dan sebaliknya.

### Dua batas berbeda yang sama-sama bernomor 20 {#two-different-limits-both-numbered-20}

Tabel di atas mencantumkan 20 dua kali, dan keduanya tidak berhubungan. Mencampuradukkannya gampang sekali dan bisa bikin kamu mengatur kecepatan hal yang salah.

- **`requestdl` pada ~20 konkurensi** adalah batas *API*: sekitar 100 panggilan pada konkurensi itu sebelum muncul 429, dan itu menghabiskan jatah request akun.
- **20 koneksi per host CDN** adalah batas *jalur byte*, diukur pada 2026-08-23 dengan ramp bertahap. Ini tidak butuh panggilan `requestdl` sama sekali. Memakai ulang satu URL yang sudah dibuat saja sudah cukup untuk mencapainya.

Batas jalur byte adalah **tepat 20** dan berperilaku sebagai batas keras, bukan kurva landai: 20 tetap bertahan baik saat diminta 24, 32, 40, atau 48 koneksi, dengan penolakan naik untuk menampung semua yang di atas garis itu.

Batas ini berlaku untuk **host CDN, bukan objek dan bukan IP**. Ini koreksi untuk pembacaan lama yang bilang "per IP di lapisan Cloudflare":

- Dua file *berbeda* yang dilayani dari satu host `nexus-NNN` berbagi satu anggaran 20 yang sama dan menolak kelebihan yang sama.
- Beban kerja yang sama persis tapi dibagi ke dua host berjalan bersih.
- 32 stream bersamaan yang disebar ke 16 host, semuanya dari satu IP, tidak masalah.

Sebagai pembanding dengan provider lain yang diukur dengan cara yang sama: Real-Debrid membatasi 32 per host (menolak di lapisan TCP, tanpa status HTTP), AllDebrid 32 (HTTP 429), dan Premiumize tidak menunjukkan batas sama sekali sampai 64. Angka 20 milik TorBox adalah yang terendah dari keempatnya.

**Edge global TorBox tidak punya batas seperti itu.** Angka 20 adalah sifat dari host per-node `nexus-NNN.<region>.tb-cdn.st` yang dibuat `requestdl`. Dua edge global, `nexus.erth.tb-cdn.earth` dan `nexus.hare.tb-cdn.earth`, melayani file apa pun di akun, dan keduanya sama-sama naik bertahap sampai 64 koneksi bersamaan tanpa satu pun penolakan. Hanya host-nya yang berbeda. Path dan token tetap mengautentikasi request. zurg belum menulis ulang ke edge ini saat ini (service `debrid` saudaranya sudah, lewat `TORBOX_CDN_EDGE`), jadi batas di atas yang berlaku di sini.

### Apa yang dilakukan zurg {#what-zurg-does}

- **`GetTorrentInfo` diambil dari daftar torrent.** `mylist` milik TorBox sudah menyertakan daftar file dari setiap torrent, jadi refresh library cukup satu request, bukan satu per torrent. Ini dideklarasikan sebagai `Capabilities.ListIncludesFiles`, dan jalur refresh melewati panggilan per-torrent maupun cache info di disk untuk provider yang mengaturnya. Pada akun dengan 213 torrent, bedanya adalah 213 request vs 1.

- **Satu limiter mengatur semua endpoint**, diset ke 240/menit dari batas dokumentasi 300, supaya ada sisa kuota untuk hal lain yang memakai key yang sama, seperti dashboard TorBox, client lain, atau zurg kedua.

- **`requestdl` punya limiter kedua di atasnya**, diset ke 15/menit. Satu resolusi memakai kuota dari keduanya. Angkanya sengaja di bawah 20/menit yang terukur, bukan tepat di angka itu, dengan alasan yang sama seperti limiter umum yang diset 240 dari 300: kuotanya dipakai oleh semua yang memegang key, sedangkan 20/menit diukur saat tidak ada yang lain memakainya. `TestTheRequestdlBudgetCannotBeSpentInsideItsWindow` menjaga invarian yang sebenarnya, yaitu seluruh jatah tidak boleh bisa habis dalam jendela waktu yang sama dengan saat jatah itu diisi ulang, jadi konstanta ini tidak bisa diam-diam naik lagi melewati batas.

- **Download client dibatasi 20 koneksi per host CDN** (`maxConnsPerCDNHost` di `internal/torbox/client.go`, diteruskan lewat `rdclient.HTTPClientOptions.MaxConnsPerHost`). `MaxConnsPerHost` milik Go membuat request ke-21 *menunggu koneksi kosong* alih-alih gagal, jadi batas ini mengubah penolakan dari provider menjadi antrean lokal. Tanpa ini, download client mewarisi setelan unlimited dari transport serbaguna dan bisa kena 429 di jalur data, padahal semua limiter API sudah dipatuhi.

- **Respons 429 menahan semua pemanggil** selama jendela `Retry-After`, daripada membiarkan tiap pemanggil menghabiskan request hanya untuk mengecek lagi bahwa mereka terkunci. Penguncian ini berlaku untuk seluruh akun, jadi 429 yang didapat dari endpoint mana pun menahan semuanya.

- **Konkurensi dibatasi 16 request yang sedang berjalan**, di bawah batas burst global sekitar 40, supaya masih ada ruang untuk download client.

- **Read-ahead dinonaktifkan.** zurg memanaskan file berikutnya dari sebuah rilis saat cold read, dan itu aman untuk backend yang punya budget per menit yang nyata. Yang bermasalah adalah library scan: scan membuka setiap file tepat satu kali, jadi setiap open adalah cold, penolakan warm-read tidak pernah terpicu, dan akun diminta dua resolusi per file. Diukur pada 2026-08-30, scan empat puluh file menghasilkan tepat empat puluh resolusi spekulatif di samping empat puluh read. Separuh budget habis untuk file yang tidak diminta siapa pun. TorBox mendeklarasikan `Capabilities.SpeculativeResolutionsAffordable` sebagai false dan tidak diminta resolusi spekulatif sama sekali.

- **Memberi nama file hasil resolusi tidak memakan request.** Setiap resolusi diakhiri dengan mencari nama dan panjang file tersebut untuk record download. Pencarian itu dulu lewat snapshot daftar, jadi begitu jendela kesegarannya yang tiga puluh detik habis, read berikutnya harus mengambil seluruh daftar torrent dulu sebelum bisa menjawab. Saat scan, itu terjadi tiap tiga puluh detik selama scan berjalan, dan pada library 3.700 torrent, listing itu harus di-page empat kali. Sekarang ia membaca listing yang sudah ada di tangan, berapa pun usianya, karena nama dan panjang file dari torrent yang sudah selesai tidak akan berubah.

- **Link cache disimpan selama satu hari, dengan pemulihan saat ditolak secara eksplisit.** Pemanggilan `requestdl` berulang mengembalikan URL yang identik dalam probe 2026-08-30, termasuk satu jam kemudian, dan URL berumur 3j25m masih melayani `206`. Ini membuktikan URL bisa dipakai ulang, bukan bahwa masa hidupnya tak terbatas. Pada 2026-09-04, URL cache yang autentikasinya benar mengembalikan `400` dengan “Invalid Presigned Token”, sementara resolusi baru untuk torrent/file yang sama menghasilkan host dan path yang berbeda dan melayani `206`. Query-nya tidak berubah. Memindahkan hanya path/query lama ke host baru tetap mengembalikan `400`.

  Cache 24 jam tetap merupakan pilihan budget: scan diresolusi dengan kecepatan 20/menit dan bisa memakan waktu berjam-jam. Penolakan token tidak valid yang eksplisit sekarang membatalkan URL itu dan mencoba resolusi baru. Pembaca yang bersamaan berbagi pekerjaan resolusi, dan penolakan yang terlambat tidak bisa menggusur URL cache yang lebih baru. Jika URL hasil resolusi baru juga ditolak, pemutaran dijeda secara lokal selama satu menit tanpa menghukum file tersebut. 400 generik tidak membuktikan URL sudah usang dan hanya memicu cooldown singkat. 429 dari CDN mempertahankan `Retry-After` dan menahan read ke host tersebut di semua file dan panggilan verifikasi. Budget API tetap terpisah.

- **`bypass_cache=true` di setiap pemanggilan list.** Cache `mylist` milik TorBox sendiri punya TTL sekitar 5 menit. Melayani dari cache itulah yang membuat mount WebDAV tertinggal 5–15 menit dari keadaan sebenarnya. Parameter ini tidak memakan kuota rate limit dan membuat perubahan terlihat dalam waktu di bawah satu detik.

- **Satu poll hanya memakai satu listing.** Poll perubahan library adalah satu-satunya pemanggil yang memaksa pengambilan ulang, karena tugasnya memang mendeteksi perubahan. Hitungan torrent aktif dalam tick yang sama, dan refresh penuh yang mengikuti setelah ada perubahan, keduanya membaca snapshot yang baru saja diisi. Memaksa juga di sana berarti seluruh library dibaca dua atau tiga kali per poll. Pada interval default sepuluh detik, itu ribuan pembacaan library penuh yang berlebihan per hari, padahal layanan itu sendiri sudah di-bypass cache listing-nya oleh zurg.

- **Daftar dibaca per halaman berisi 1000.** `mylist` membatasi satu respons maksimal 1000 torrent. Ini nilai default yang didokumentasikan untuk `limit`, dan meminta lebih tidak menaikkannya. Endpoint ini juga tidak melaporkan total maupun “masih ada lagi”. Satu request saja akan menjawab akun yang lebih besar dengan 1000 torrent terbaru dan tampak persis seperti library yang lengkap. zurg berpindah halaman lewat `offset` sampai halaman yang pendek datang, sambil menghapus id ganda selama jalan. Daftar diurutkan id menurun, jadi torrent yang ditambahkan di tengah penelusuran menggeser jendela satu posisi dan mengulang satu entri di sambungan halaman.

## Batas akun {#account-limits}

| Plan | Slot aktif | Seeding | Ukuran torrent maks | Catatan |
|---|---|---|---|---|
| Free | 1 | none | 10 GB | 1 tambah/24 jam, 10 tambah/bulan, tanpa torrent privat |
| Essential | 3 | — | 200 GB | tanpa jeda, tambah cached tanpa batas |
| Standard | 5 | 2 weeks | — | |
| Pro | 10 | 30 days | — | masa berlaku 30 hari |

Sumber: [Pembatasan Akun](https://support.torbox.app/en/articles/9836418-account-restrictions).

`/user/me` melaporkan plan sebagai angka, dan angkanya tidak urut sesuai harga:
**0 Free, 1 Essential, 2 Pro, 3 Standard**. Standard ditambahkan setelah Pro.
zurg membaca plan 2 sebagai Standard sampai 2026-10-03, sehingga akun Pro mendapat lima slot dan batas penggunaan minimum Standard.

**Slot aktif adalah pembatasan utama TorBox**, sedangkan pembatasan Real-Debrid adalah bandwidth. Sebuah torrent memakai satu slot selama diunduh *atau di-seeding*, jadi di paket berbayar, torrent yang sudah selesai bisa menahan satu slot sampai 30 hari.

### Apa yang dilakukan zurg {#what-zurg-does-1}

- **`GetActiveTorrentCount` melaporkan batas asli paket**, dibaca dari `plan` di data user, jadi repair memblokir dan menunggu alih-alih memasukkan add yang pasti ditolak akun. Provider yang tidak melaporkan batas dianggap tanpa batas, bukan memblokir selamanya.
- **Torrent yang ditambahkan ditandai never-seed secara default.** Seeding menahan slot selama berminggu-minggu dan menagih trafik keluar, dan keduanya tidak membantu mount streaming. `tb_seed_torrents` mengubahnya untuk operator yang tracker privatnya menghitung ratio: `never` mengirim `seed=3` (default), `always` mengirim `seed=2`, dan `auto` tidak menyertakan field-nya sama sekali. Deskripsi TorBox untuk field ini adalah "1 is auto. 2 is seed. 3 is don't seed. Optional. Default is 1, or whatever the user has in their settings. Overwrites option in settings", jadi nilai apa pun yang dikirim, termasuk `1`, menggantikan pengaturan Seeding akun, dan hanya field yang tidak ada yang membiarkan pengaturan itu berlaku. Mode yang sama dipakai di ketiga jalur add: add magnet, add khusus cached, dan upload `.torrent`. Dengan seeding aktif, torrent yang sudah selesai tetap memegang slotnya, sehingga repair dan endpoint download-client macet di batas begitu torrent yang sedang di-seed memegang semuanya.
- **Cache tidak pernah dicek sebelum menambahkan.** `checkcached` tidak punya call site sama sekali. Mode cached-only (`qbittorrent.download_timeout_mins: 0`) adalah satu-satunya pengecualian, sampai mode itu dibuat untuk menambahkan torrent dan memantau instance seperti backend lain, karena endpoint tersebut melaporkan apakah konten ada di cache TorBox, bukan apakah akun ini benar-benar memilikinya. Ini punya biaya nyata saat miss: add yang tidak cached menghabiskan jatah 60/jam, sedangkan probe tidak menghabiskan apa-apa. Add yang cached tetap berada di bawah anggaran 300/menit.

## Kedaluwarsa konten {#content-expiry}

Konten Pro kedaluwarsa setelah 30 hari. Torrent yang sudah kedaluwarsa dikembalikan oleh API sebagai `expired` atau `reported missing`, tetapi tetap melaporkan `download_finished: true` dengan `download_present: false`.

Kalau cuma membaca `download_finished`, kamu akan me-mount torrent yang setiap tautannya 404. zurg memetakan kedua kata itu ke status `error`, dan `Capabilities.ContentExpires` menandai hal itu sebagai kondisi normal untuk backend, bukan kesalahan.

**Dua boolean itu saja bukan tanda bahwa datanya hilang.** Download uncached yang sehat juga melaporkan `download_finished: true` dengan `download_present: false` selama 9,6 detik terakhir hidupnya, saat ia bergerak melalui `processing`, `downloading`, dan `uploading`. Ini diukur pada 2026-08-30 dengan polling 0,5 detik dan dicatat di `docs/torrent-lifecycle.md`. Dulu zurg membaca pasangan itu sebagai tanda mati apa pun string statusnya, dan instance mana pun yang menjalankan `delete_error_torrents: true` akan menghapus torrent seperti itu di tengah proses download. Pada hari itu, lima torrent probe terhapus dengan cara ini. Sekarang aturan struktural hanya memutuskan untuk payload yang sama sekali tidak punya `download_state`. Wording yang belum pernah dilihat kode ini diperlakukan sebagai pekerjaan yang sedang berjalan, karena `processing` juga dulu termasuk wording seperti itu sebelum diukur.

Pembacaan yang tetap mengenai file seperti itu sekarang memakan lebih dari satu panggilan. Jalur penyajian memperlakukan 404 pada URL pengiriman yang sudah dibuat sebagai tautan yang dicabut, bukan file yang hilang. Itu memang kondisinya di Real-Debrid, yang kodenya mati ketika baris downloads-nya dihapus. Jadi sebelum menyerah, zurg melakukan resolve ulang. Akibatnya, file TorBox yang kedaluwarsa memakan hingga empat panggilan `requestdl` per pembacaan, bukan satu seperti sebelumnya. Jumlahnya dibatasi per pembacaan, dan listing sudah menandai torrent itu sebagai `error`, jadi tidak ada yang menelusuri library yang kedaluwarsa dengan laju itu. Tapi klien yang terus-menerus memukul satu path yang kedaluwarsa akan membayar empat kali lipat dari biaya sebelumnya.

### Apa yang dilakukan zurg {#what-zurg-does-2}

**Tidak ada yang menambahkan ulang torrent dari backend yang kedaluwarsa dengan sendirinya.** Repair memperbaiki torrent yang rusak dengan menambahkan magnet-nya lagi. Di backend yang menyimpan konten, itu berarti perbaikan. Di backend yang membuat konten kedaluwarsa, itu berarti download ulang. Menjalankannya lewat timer ke seluruh library adalah perilaku yang pertama kali disebut TorBox sebagai alasan akun ditandai: "excessive transfer retention (using tools to artificially keep transfers active)". Setiap re-add yang tidak di-cache juga dihitung sebagai transfer masuk terhadap kuota paket.

Jadi sweep berkala melewati torrent yang salinan repair-nya ada di provider yang menyatakan `ContentExpires`. Torrent tersebut tetap rusak dan tetap terlihat. Tombol repair di dashboard tetap berfungsi, dan rilis yang juga ada di Real-Debrid tetap diperbaiki dari salinan itu seperti biasa. Yang membedakan adalah siapa yang meminta, bukan apa yang rusak.

## Penggunaan dan sistem penyalahgunaan {#usage-and-the-abuse-system}

TorBox tidak memeriksa permintaan satu per satu. Yang dihitung adalah jumlah byte yang ditransfer dalam jendela bergulir 15 hari, lalu dibandingkan dengan ambang batas yang diturunkan dari persentil ke-99 untuk setiap tier paket. Kalau melewati batas, kamu akan menerima tiga peringatan, dan **setiap peringatan memutar API key-mu** dan pada peringatan keempat kamu diblokir. Batas bawah yang dipublikasikan, yaitu nilai terendah yang bisa dicapai ambang batas dinamis itu:

| Paket | Batas bawah |
|---|---|
| Free | 5 TB/bulan |
| Essential | 10 TB/bulan |
| Standard | 20 TB/bulan |
| Pro | 30 TB/bulan |

Kedua arah dihitung: unggahan uncached yang masuk, dan semua yang dikirim TorBox keluar, baik ke perangkatmu maupun kembali ke swarm. Add yang cached tidak dihitung. Pencatatannya tepat per byte, jadi file yang hanya dibaca sebagian cuma dihitung sebesar yang sudah dibaca.

**`cooldown_until` di `/user/me` bukan salah satu dari peringatan itu, dan kalau kamu menganggapnya begitu, kamu bisa kehilangan satu hari.** Sudah diverifikasi pada 2026-08-12 di akun paket-2 saat cooldown aktif dan baru saja di-set (24 jam ke depan, `updated_at` baru satu menit yang lalu): `/user/me`, `checkcached`, dan `mylist` semuanya membalas `200 success:true`, WebDAV `PROPFIND` mengembalikan `207`, dan pembacaan rentang `bytes=0-0` mengembalikan **`206` dengan `Content-Range` yang benar dalam 2,8 detik**. Tidak ada lapisan yang menolak layanan. Total transfer akun itu 14,1 GB dari batas 30 TB/bulan, jadi itu cooldown karena laju API, bukan strike bandwidth. Pembedanya ada di **key**: peringatan sungguhan memutar key, dan setelah itu semua endpoint mengembalikan `AUTH_ERROR`. Sementara cooldown dengan key yang masih utuh tidak punya efek yang terlihat. Lalu, karena `checkcached` bisa melaporkan sebuah rilis sebagai cached padahal TorBox sebenarnya tidak akan menyajikannya, **pembacaan rentang adalah satu-satunya probe yang membuktikan layanan benar-benar berjalan**. Jadi cek jalur byte dulu sebelum menyimpulkan TorBox tidak bisa dipakai.

Sumber: [The TorBox Abuse System](https://support.torbox.app/en/articles/10336778-the-torbox-abuse-system).

### Apa yang dilakukan zurg {#what-zurg-does-3}

- **Torrent yang ditambahkan tidak pernah di-seed secara default**, jadi tidak ada tagihan saat data keluar untuk konten yang hanya dibaca zurg. `tb_seed_torrents: always` (atau `auto` pada akun yang diatur untuk seed) adalah satu-satunya setting yang mengubah ini, dan upload-nya ditagih seperti biasa.
- **Penggunaan diambil sampelnya lalu dihitung selisihnya.** API tidak menyediakan angka bergulir, hanya penghitung seumur hidup di `/user/me`. Jadi account refresher mencatat penghitung itu setiap 30 menit ke `data/torbox_usage.json` dan menghitung selisih antar sampel. Jika angka 30 hari terakhir melewati 80% dari batas minimum paket, akan muncul peringatan di log. Peringatan itulah inti dari sampling ini. Dashboard hanya menampilkan apa yang diproksikan zurg sendiri, tidak pernah selisih ini. Instalasi baru belum punya riwayat dan akan memberitahukan hal itu, bukannya menampilkan angka nol yang menenangkan.
- **Kunci yang ditolak dilaporkan sebagai kemungkinan peringatan penyalahgunaan**, bukan sebagai typo konfigurasi dan bukan sebagai kerusakan konten. Alasannya, rotasi kunci adalah cara TorBox menyampaikan peringatan semacam itu. Kalau diperlakukan sebagai kerusakan, seluruh library akan dianggap perlu diperbaiki.

## Sengaja tidak dipetakan {#deliberately-unmapped}

An `download_state` yang tidak dikenali dilaporkan sebagai `downloading`, bukan `error`.
Dengan `delete_error_torrents` diaktifkan, status error membuat zurg menghapus torrent dari akun — jadi status baru yang diperkenalkan TorBox setelah kode ini ditulis tidak boleh menyebabkan penghapusan.
