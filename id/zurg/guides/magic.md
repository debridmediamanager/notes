# `__magic__`, direktori yang bisa kamu atur {#__magic__-a-directory-you-can-organise}

Setiap direktori zurg lainnya dihitung. `movies` menerapkan filter movies. `__all__` berisi semuanya.
Folder rilis berisi apa yang dilaporkan akun Anda. Tata letaknya dibangun ulang setiap kali refresh.

`__magic__` adalah satu-satunya direktori dengan **path tersimpan**. Memindahkan file hanya mengubah satu baris tabel. Tidak ada byte yang berpindah dan akun debrid tetap tidak berubah. Atur sendiri secara manual, atau biarkan Sonarr dan Radarr yang menggunakannya.

Isinya ada tiga jenis. `__magic__/__all__` berisi setiap rilis yang belum ditempatkan, dan ini adalah folder tempat klien unduhan mengimpor. Karena folder ini dihitung, tidak ada yang bisa dibuat di level paling atas, dan byte file tidak boleh ditulis menimpa nama yang sudah dipakai folder rilis (folder rilis menerima sidecar dengan nama yang belum dipakainya). Jika Anda punya kunci sponsor DMM, zurg akan memasukkan semua yang sudah diidentifikasi DMM ke `__movies__` dan `__shows__`, diurutkan berdasarkan judul ([lihat di bawah](#__movies__-and-__shows__-sorted-by-title)). Semua yang lain di root `__magic__` adalah milik Anda:

```
/mnt/zurg/__magic__
├── __all__     <- what nothing has placed yet, where a grab lands
├── __movies__  <- films zurg filed by title
├── __shows__   <- shows zurg filed by title
├── __anime__   <- anime shows, with magic.anime: true
├── anime
├── movies
└── tv          <- your *arr root folders
```

Path di halaman ini menggunakan mount Linux, `/mnt/zurg`. Di macOS path-nya `/Volumes/Zurg` dan di Windows `Z:\`, jadi `/mnt/zurg/__magic__/tv` sama dengan `/Volumes/Zurg/__magic__/tv` atau `Z:\__magic__\tv`.

Pemisahan ini justru intinya. Folder tempat klien mengimpor *dari* dan folder tempat klien mengimpor *ke* posisinya bersebelahan, jadi tidak ada yang berada di dalam yang lain. Akibatnya, impor manual yang diarahkan ke folder unduhan tidak akan menelusuri pohon perpustakaan Anda, dan baik Sonarr maupun Radarr tidak akan memberi peringatan soal susunan ini.

Fitur ini nonaktif secara default. Untuk mengaktifkannya, jalankan:

```yaml
magic:
  enabled: true
```

lalu mulai ulang zurg. Rute ditentukan saat startup, jadi mengubahnya dari dashboard membutuhkan restart sebelum namespace bisa merespons.

## Untuk apa ini {#what-it-is-for}

Sebuah \*arr mengimpor dengan **memindahkan** file dari folder download ke library. zurg tidak punya tempat untuk menerima perpindahan itu, jadi \*arr beralih ke menyalin. Padahal menyalin dari mount debrid berarti menarik seluruh release lewat jaringan, dan itulah yang justru ingin dihindari oleh mount ini.

Dengan `__magic__`, impor menjadi rename di dalam satu namespace: sebuah baris ditulis, file muncul di tempat yang ditentukan \*arr, dan tidak ada yang diunduh. Inilah yang membuat [endpoint SABnzbd](sonarr-radarr.md) berharga. Endpoint itu hanyalah lapisan tipis di atas mekanisme ini, dan tanpanya setiap impor akan menjadi unduhan penuh.

Ini hanya berfungsi jika **root folder** \*arr juga berada di dalam `__magic__`, misalnya `/mnt/zurg/__magic__/tv`, bukan direktori lain di mesin. Perpindahan ke tujuan di luar namespace adalah perpindahan antar dua filesystem, yang berarti salinan lagi. zurg menolaknya langsung dengan `403` daripada membiarkannya terjadi diam-diam. Satu-satunya tempat di dalam namespace yang juga ditolak adalah bagian paling atas dari `__magic__/__all__`, karena itu tata letak library itu sendiri, bukan tempat untuk menaruh file. [sabnzbd.md](sonarr-radarr.md) berisi pengaturan persisnya.

File yang ditempatkan di luar `__all__` tetap tercantum di sana, dan penghapusan di `__all__` menghapus dari akun. Karena itu zurg menolak menghapus file lewat `__all__` atau folder library lain selama ada penempatan di sini yang sedang di-stream dari file tersebut. Hapus lewat `__magic__` saja. Ini yang mencegah \*arr yang mengimpor dari `__all__` lalu membersihkan folder download-nya di sana, seperti yang dilakukan \*arr yang memakai proxy SABnzbd milik DMM, dari menghapus release yang baru saja diimpornya.

Dan \*arr harus bisa mengakses folder download dan root folder **lewat satu mount**. Container yang diberi `__magic__/__all__` dan `__magic__/tv` sebagai dua volume terpisah akan melihat dua filesystem, padahal keduanya milik zurg. Akibatnya kernel menolak rename di dalam container sebelum zurg sempat tahu, dan \*arr menyalin seluruh file. zurg mengubah salinan seperti itu menjadi penempatan setelah file selesai masuk dan mencatat `A client copied …`, tetapi unduhannya sudah terjadi. Pasang satu direktori yang berisi seluruh mount zurg ke dalam container. Lihat [Satu volume untuk folder download dan root folder](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

Penempatan dari akuisisi zurg sendiri juga ditaruh di sini. Sumber Radarr menaruh setiap release yang dikonfirmasinya ke folder film dengan perpindahan yang sama seperti impor, lalu meminta Radarr melakukan rescan. Lihat [acquisition.md](acquisition.md#placing-the-file).

zurg juga menempatkan file di sini secara mandiri, ke `__movies__` dan `__shows__`. Lihat [di bawah](#__movies__-and-__shows__-sorted-by-title).

Mengatur library secara manual adalah bagian lainnya, dan itu berjalan tanpa \*arr sama sekali.

## Jika belum ada yang disimpan, rilisan dari `__all__` tampil sebagai folder sungguhan {#with-nothing-stored-it-is-__all__s-releases-as-real-folders}

Buka `__magic__/__all__` di instalasi baru dan kamu akan melihat setiap rilis yang ada di `__all__`, masing-masing sebagai satu folder. Tabelnya mulai kosong dan hanya menyimpan **penyimpangan** dari default itu. Jadi library yang tidak kamu ubah sama sekali tidak menyimpan apa pun. Root `__magic__` hanya berisi mirror, dan rilis baru langsung muncul di sana begitu muncul di tempat lain. Begitu sesuatu menempatkan rilis, misalnya impor dari \*arr atau penyimpanan otomatis zurg ke `__movies__` dan `__shows__`, rilis itu keluar dari `__magic__/__all__`. Mirror adalah tempat untuk rilis yang belum ditempatkan siapa pun.

Tidak ada konfigurasi direktori di baliknya: tidak ada `only_show_the_biggest_file`, tidak ada filter ukuran. Yang kamu lihat adalah apa yang memang ada di dalam rilis.

Satu-satunya perbedaan dari `__all__` adalah **bentuk isi folder rilis**. Di tempat lain, zurg meratakan rilis menjadi satu direktori, diberi nama sesuai nama file, dengan akhiran jika dua file bentrok:

```
__all__/Show.S01/Show.S01E01.mkv
__all__/Show.S01/Gag Reel (Extras).mkv
```

`__magic__/__all__` menampilkan pohon yang benar-benar dimiliki rilis itu:

```
__magic__/__all__/Show.S01/Show.S01E01.mkv
__magic__/__all__/Show.S01/Extras/Gag Reel.mkv
```

Ini bukan sekadar soal tampilan. Sonarr dan Radarr memindai folder unduhan sebagai folder: file di dalam **subfolder** bernama `extras`, `samples`, `featurettes`, `trailers` atau `deleted scenes` akan dilewati, sedangkan file di level paling atas akan diproses. Jadi `Gag Reel (Extras).mkv` yang sudah diratakan akan ditawarkan untuk diimpor, padahal di pohon aslinya file itu terlewat. Lalu, impor mereka hanya kembali ke judul unduhan untuk parsing jika folder hanya berisi satu video. Jadi film yang diratakan bersama featurette-nya kehilangan fallback itu. Karena [endpoint SABnzbd](sonarr-radarr.md) memberi \*arr sebuah folder di bawah `__magic__/__all__`, aturan-aturan ini berlaku di permukaan inilah.

Ada dua detail tentang bentuknya:

- **Folder pembungkus tunggal dibuang.** Hampir setiap rilis berupa satu folder yang berisi semuanya, dan nama folder itulah yang sudah menjadi nama rilis, karena backend debrid menurunkan nama dari situ. Jadi `/Show.S01/Season 01/ep1.mkv` ditampilkan sebagai `Show.S01/Season 01/ep1.mkv`, bukan `Show.S01/Show.S01/Season 01/ep1.mkv`. Hanya satu level, dan hanya jika tidak ada apa pun di sebelahnya. Rilis yang punya file di level atas dan folder di sebelahnya tetap menampilkan keduanya.
- **Tidak ada akhiran nama duplikat.** Akhiran itu ada untuk menjaga daftar yang diratakan tetap tidak ambigu, dan pohon sudah punya direktori untuk keperluan itu.

Hal lain tentang folder rilis tidak berubah, termasuk arsip: set RAR tetap bisa dijelajahi sebagai direktori, hanya saja sekarang berada di tempat volume-volumenya berada di pohon. Rilis yang disajikan dari satu arsip yang diratakan tetap menampilkan isi arsip itu.

`__all__` dan filter `directories:` tetap datar. Keduanya adalah yang sebaiknya kamu arahkan ke media server, dan tidak ada yang berubah pada keduanya.

## Mengatur isinya {#organising-it}

Lewat mount, dengan perintah biasa:

+++ Linux
```bash
mkdir -p /mnt/zurg/__magic__/tv/The\ Show/Season\ 01
mv /mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /mnt/zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ macOS
```bash
mkdir -p /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01
mv /Volumes/Zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ Windows
```powershell
New-Item -ItemType Directory -Force "Z:\__magic__\tv\The Show\Season 01"
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Release.S01E01.1080p\ep1.mkv" `
  -Destination "Z:\__magic__\tv\The Show\Season 01\S01E01.mkv"
```
`-LiteralPath` menjaga tanda kurung siku yang dimiliki banyak nama rilis agar tidak dibaca sebagai wildcard.
+++

Sekarang file berada di path baru dan sudah tidak ada di path lama. File tetap di-stream dari akun yang sama seperti sebelumnya.

Folder rilis secara utuh juga bisa dipindah, cukup dalam satu baris:

+++ Linux
```bash
mv /mnt/zurg/__magic__/__all__/Some.Movie.2024.2160p /mnt/zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ macOS
```bash
mv /Volumes/Zurg/__magic__/__all__/Some.Movie.2024.2160p /Volumes/Zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ Windows
```powershell
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Movie.2024.2160p" -Destination "Z:\__magic__\movies\Some Movie (2024)"
```
+++

Direktori dipindah beserta semua isinya, sebagai satu batch. Pemindahan berlaku dua arah: file bisa dipindah *ke dalam* folder rilis maupun *keluar* dari folder rilis, dan folder akan menampilkannya berdampingan dengan entri milik rilis itu sendiri. Ini yang dibutuhkan program yang memasukkan sesuatu kembali ke folder tempat ia mengimpor. Jika sebuah nama datang dari dua tempat sekaligus, yang disengaja yang menang: yang kamu pindahkan mengalahkan yang diberikan rilis untuk nama itu, yang mengalahkan file asli di `data/local`, dan yang kalah tidak ditampilkan sehingga tidak muncul dua kali.

Ada satu pola yang gagal lewat built-in mount, dan hanya saat `union_writable: local` (default): mengganti nama direktori yang *kamu buat lewat mount*, yaitu `mkdir` lalu, nanti, `mv` terhadap direktori itu. Dengan urutan default, `mkdir` membuat direktori di upstream lokal rclone, sementara baris-baris di bawahnya membuat direktori yang sama juga ada di server. Akibatnya rclone mengganti nama salinan lokalnya, memindahkan baris satu per satu (zurg menjawab setiap permintaan dengan benar), lalu gagal menghapus sumber yang sudah diganti namanya:

```
ERROR : __magic__/tv/Saul: Dir.Rename error: RenameDir rmdir: object not found
```

Baris-baris akhirnya berada tepat di tempat yang kamu minta: zurg menyajikan path baru dan mengembalikan 404 untuk path lama. Tapi `mv` keluar dengan kode 1, dan mount menampilkan direktori sumber yang sudah kosong, bukan tujuan, sampai daftar isinya dibaca ulang. Tidak ada permintaan penghapusan itu yang sampai ke zurg, jadi apa pun yang dilakukan zurg tidak bisa mencegahnya. Memindahkan file dan memindahkan folder rilis secara utuh berfungsi di kedua urutan. Jika kamu ingin mengatur ulang direktori lewat mount, atur [`union_writable: server`](../reference/config.md#rclone-settings), di mana direktori hanya ada di namespace dan penggantian nama menjadi satu operasi di sisi server. Diukur pada rclone 1.71.2.

`rm` hanya menyembunyikan, lihat [Menghapus hanya menyembunyikan, tidak memusnahkan](#deleting-hides-it-does-not-destroy).

## `__movies__` dan `__shows__`, diurutkan berdasarkan judul {#__movies__-and-__shows__-sorted-by-title}

Kodi dan Plex mengenali isi sebuah file dari nama folder dan nama file-nya. Nama rilis seperti `Succession.S01.MULTi.1080p.BluRay.REMUX.AVC-DEMS` sering kali terlalu rumit untuk mereka baca. Saat diarahkan ke nama rilis, Kodi hanya mengenali 8 dari 56 serial dalam tes kami. Dengan kunci sponsor DMM, zurg menyimpan setiap rilis yang sudah diidentifikasi DMM ke dalam dua folder, dengan nama yang langsung cocok di pemutar:

```
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.mkv
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/tvshow.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/Season 01/Detective Conan (1996) - S01E1194 [tmdbid-30983].mkv
```

Pustaka yang sama, jika disimpan dengan cara ini, membuat Kodi dan Plex mencocokkan semua 70 film, semua 44 serial, dan semua 554 episode.

### Cara mengaktifkannya {#turning-it-on}

Kamu butuh zurg nightly dari 2026-10-26 atau yang lebih baru, `__magic__` diaktifkan, dan API key DMM kamu, yang ditampilkan [gatekeeper](https://gatekeeper.debridmediamanager.com/) setelah kamu menjadi sponsor:

```yaml
magic:
  enabled: true
dmm_api_key: YOUR_DMM_API_KEY
```

Restart zurg. Kedua folder akan terisi setelah library selesai dimuat dan DMM sudah mengidentifikasinya. Pada library besar, proses ini butuh beberapa menit untuk pertama kali. Setelah itu, rilis baru akan masuk dalam waktu satu menit setelah DMM mengidentifikasinya. Lalu tambahkan library **Movies** yang mengarah ke `/mnt/zurg/__magic__/__movies__` dan library **TV** yang mengarah ke `/mnt/zurg/__magic__/__shows__` (`/Volumes/Zurg/__magic__/...` di macOS, `Z:\__magic__\__movies__` dan `Z:\__magic__\__shows__` di Windows), lalu pindai. Di Kodi, atur scraper untuk sumber TV ke **The Movie Database**, seperti default-nya, dan pastikan tetap diperbarui: file `tvshow.nfo` membutuhkan versi 1.7 atau yang lebih baru dari TMDb TV scraper milik Kodi.

Arahkan setiap library ke folder-nya masing-masing, jangan ke `__magic__` itu sendiri. Kalau begitu, `__all__` dan folder lain ikut dipindai, dan semuanya akan muncul dua kali.

### Apa yang dilakukannya {#what-it-does}

- **Film atau serial sesuai yang DMM sebut**, bukan berdasarkan aturan folder. Film yang datang di dalam paket serial akan diarsipkan sebagai film tersebut.
- **Setiap rilis dari sebuah serial masuk ke satu folder**, dengan musim dan episode dinomori seperti cara TMDB menomorinya, yaitu urutan yang dipakai Plex secara default. Anime yang dinomori berdasarkan urutan tayangnya ditempatkan di musimnya: `Detective Conan - 1194` menjadi S01E1194.
- **ID TMDB ada di folder, di setiap nama file, dan di `.nfo`**, supaya setiap pemutar menemukannya di tempat yang dicarinya: Plex di folder, Kodi di `.nfo`, dan pemutar yang hanya membaca nama file di nama file.
- **Satu salinan per judul.** Jika dua rilis adalah episode atau film yang sama, yang lebih baik yang diarsipkan, berdasarkan resolusi lalu ukuran; yang satunya tetap di `__all__`.
- **Extras dan sample dibiarkan di `__all__`**, begitu juga apa pun yang belum diidentifikasi DMM. Sebuah rilis diarsipkan setelah DMM mengidentifikasinya.

### Anime di folder tersendiri {#anime-in-a-folder-of-its-own}

Acara anime bisa dipindah ke folder ketiga, `__anime__`, jadi Kodi dan Plex dapat library Anime sendiri, seperti dulu kalau kamu punya Sonarr kedua khusus anime. Butuh zurg nightly dari 2026-11-10 atau yang lebih baru, plus satu baris lagi:

```yaml
magic:
  enabled: true
  placement: true
  anime: true
dmm_api_key: YOUR_DMM_API_KEY
```

Restart zurg, lalu tambahkan library **TV** yang mengarah ke `/mnt/zurg/__magic__/__anime__` dan pindai. Yang dianggap anime itu keputusan DMM, berdasarkan TMDB: acara yang TMDB tandai sebagai animation, berbahasa Jepang dan dari Jepang, ketiganya sekaligus, atau yang diberi keyword *anime* oleh TMDB. Detective Conan, Ace of the Diamond, dan Cyberpunk: Edgerunners masuk ke `__anime__`; Hazbin Hotel (animasi dari AS), Alice in Borderland (Jepang, live action), dan LINK CLICK (animasi China) tetap di `__shows__`. Film tetap di `__movies__`, termasuk film anime: library Movies itu satu jenis, dan folder ini juga satu jenis.

Begitu fitur ini dinyalakan, semua acara anime pindah dari `__shows__` dalam beberapa menit. Pemutarmu akan melihatnya sebagai acara yang keluar dari satu library lalu muncul di library lain:

- **Plex** menghapusnya dari library TV (sebagai missing, atau langsung dihapus kalau Plex mengosongkan trash setelah scan), lalu memunculkannya di library Anime pada scan berikutnya. Status sudah ditonton ikut terbawa: Plex mengaitkannya ke acara, bukan ke library, jadi episode yang sudah ditonton di library TV akan tampil sudah ditonton di library Anime (diukur 2026-11-09).
- **Kodi** mengaitkan status ditonton ke path file, jadi ekspor library video kamu (Settings → Media → Library → Export) sebelum menyalakan ini, dan impor lagi setelah source Anime selesai dipindai.

Mematikannya akan memindahkan mereka kembali dengan cara yang sama.

### Dengan daftar keinginan DMM {#with-the-dmm-wanted-list}

Tekan **Want** di DMM dan zurg akan mengambil judulnya ([DMM wanted list](dmm-wanted.md)). Hasil ambilannya langsung disimpan di sini seperti biasa, jadi film atau serial akan muncul di Kodi dan Plex dengan namanya sendiri, tanpa melibatkan Sonarr atau Radarr. Torrent yang sudah diambil bisa butuh waktu hingga satu jam untuk disimpan; NZB disimpan begitu DMM mengenalinya.

### Dengan Sonarr dan Radarr {#with-sonarr-and-radarr}

Mereka tetap memegang library masing-masing. Rilis yang diambil Sonarr atau Radarr lewat zurg akan dibiarkan di `__all__` supaya mereka bisa mengimpornya, sejak saat mereka mengambilnya. zurg tidak pernah merapikan apa pun yang mereka taruh. Kalau salah satu dari mereka mengimpor judul yang sudah dirapikan zurg, dengan memindahkannya ke root folder sendiri, judul itu jadi milik mereka sejak saat itu dan zurg akan membiarkannya di sana.

Supaya Kodi dan Plex juga mencocokkan library mereka dengan cara yang sama:

- Aktifkan **Settings → Metadata → Kodi (XBMC) / Emby** di masing-masing aplikasi. Setelah itu, aplikasi akan menulis file `.nfo` berisi id judul di sebelah setiap film dan serial, dan zurg akan menyimpannya untuk mereka.
- Taruh id di nama folder mereka, di bawah **Settings → Media Management**:

  | | Format folder |
  |---|---|
  | Radarr | `{Movie CleanTitle} ({Release Year}) {tmdb-{TmdbId}}` |
  | Sonarr | `{Series TitleYear} {tvdb-{TvdbId}}` |

### Perlu diketahui {#good-to-know}

- **Menghapus di player akan menyembunyikan file**, seperti halnya penghapusan apa pun di `__magic__`. File tetap ada di akun debrid kamu, dan zurg tidak akan memasukkannya lagi.
- **Tidak ada yang bisa dipindahkan ke `__movies__`, `__shows__`, atau `__anime__`**: folder-folder itu diisi oleh zurg. Memindahkan sesuatu keluar dari folder tersebut, seperti yang dilakukan impor \*arr, tetap bisa.
- **Ketika identifikasi DMM terhadap sebuah rilis berubah**, zurg akan memindahkan file-filenya ke nama yang baru.
- **File yang rusak tetap berada di tempatnya** selama zurg memperbaikinya, jadi media server kamu tidak kehilangan file tersebut.
- **Tanpa kunci sponsor DMM, tidak ada yang dimasukkan.** Menghapus kunci, atau mematikan `__magic__`, membiarkan file yang sudah dimasukkan tetap di tempatnya.

## Pemindahan tetap bertahan saat repair, rename, dan re-listing {#a-move-survives-repair-rename-and-re-listing}

Ini bagian yang paling penting, karena kalau salah, susunan library yang sudah rapi bisa diam-diam hilang.

zurg memperbaiki release yang rusak dengan menambahkannya lagi ke akun. Torrent id berubah, access key berubah, file id berubah. Jadi kalau tabel memakai salah satunya sebagai kunci, setiap penempatan akan hilang begitu satu link rusak. Karena itu, baris dikunci pakai **hash konten** release dan **path file** di dalam release. Perbaikan tidak mengubah keduanya.

Konsekuensinya semua memang disengaja:

- **Perbaikan tetap menjaga tata letak kamu.** Release kembali dengan id baru, dan file-filenya tetap ada di tempat yang kamu tentukan.
- **Mengganti nama release tidak memindahkan apa pun.** Mengganti nama, dan sufiks yang ditambahkan zurg saat dua release berbeda akan memakai nama folder yang sama, sama-sama mengubah nama folder default sebuah release. Penempatan tidak terpengaruh.
- **File yang hilang tidak dilupakan.** Kalau perbaikan mengubah kumpulan file, misalnya Real-Debrid mengemas ulang release rar (penyebab yang paling sering), baris yang file-nya sudah tidak ada akan *tetap disimpan tapi tidak ditampilkan*. Kalau file-nya muncul lagi, posisinya juga kembali. Baris dalam kondisi ini muncul di dashboard sebagai **dangling**, dan di situ kamu bisa menghapusnya.
- **Menghapus release lalu menambahkannya lagi tetap menjaga tata letak kamu.** Reinsert dari DMM, atau hapus lalu tambahkan lagi release yang sama, akan mengembalikan hash yang sama. File-filenya kembali ke tempat yang kamu tentukan, dan folder yang sudah kamu hapus, misalnya folder job yang dihapus \*arr setelah impor, tetap tersembunyi. Untuk memunculkan kembali release di `__magic__/__all__`, cari release tersebut di halaman `__magic__` dashboard, lalu tekan **Unhide** pada tombstone release-nya.

Satu backend butuh lebih dari sekadar pencocokan path yang persis. Nama file post Usenet itu *di-resolve*, bukan diberikan, jadi dihitung ulang setiap kali dimuat dan tidak pernah disimpan. Artinya, post yang pertama kali dibaca saat news server tidak bisa dihubungi akan tetap memakai nama yang terobfuscate sampai pemuatan berikutnya berhasil mengambil nama aslinya. Untuk kasus ini, baris akan memakai indeks file di dalam NZB sebagai cadangan, dan kalau itu juga tidak cukup, memakai basename ditambah ukuran selama hanya ada satu file yang cocok.

## Menghapus hanya menyembunyikan, tidak memusnahkan {#deleting-hides-it-does-not-destroy}

`rm` di bawah `__magic__` membuat **tombstone**: entri hilang dari `__magic__`, tapi tetap ada persis di tempat semula di `__all__`, di setiap direktori filter, dan di akun debrid. Tidak ada yang benar-benar dihapus.

Itu bukan karena penakut. Justru itulah yang membuat \*arr aman dijadikan sumber. Saat upgrade kualitas, \*arr menghapus file lama, dan saat impor ia menghapus seluruh folder job. Kalau penghapusan itu menghapus konten, upgrade akan merusak release-nya. Kalau penghapusan hanya menghapus *baris*-nya, file akan muncul lagi di lokasi default, tepat di folder tempat \*arr mengimpor.

Kalau kamu ingin penghapusan benar-benar menghapus:

```yaml
magic:
  allow_delete: true
```

Maka penghapusan **file** juga akan menghapus kontennya dari akun. Folder release dan direktori tidak pernah begitu, apa pun pengaturannya. Folder release itulah yang dihapus Sonarr setelah setiap impor.

Entri di dalam arsip adalah episode atau film dari sebagian besar release Usenet. Entri itu tidak punya file sendiri. Arsipnya juga menyimpan semua isi lain dari release tersebut. Jadi menghapus satu entri baru menghapus seluruh release setelah tidak ada lagi yang di bawah `__magic__` memakai bagian mana pun darinya. Tidak boleh ada file dari arsip itu yang masih ditempatkan di mana pun. Folder miliknya harus sudah dihapus atau tidak ada lagi yang bisa diimpor. Itulah kondisi yang ditinggalkan upgrade pada episode Usenet yang digantikan. Sebelum ini ditangani, release yang digantikan tetap ada di library, dan NZB-nya tetap di `nzbs/` selamanya.

Video biasa dihapus sendiri. Release-nya ikut terhapus setelah tidak ada lagi yang di bawah `__magic__` memakai bagian mana pun darinya. Dua aturan yang sama menentukannya. Release biasanya mengunggah lebih dari sekadar video. `.nfo`, subtitle, atau poster ada di sebelahnya, dan tidak ada yang mengimpornya. Sebelum ini ditangani, file-file itu membuat release tetap ada di library setelah satu-satunya video dihapus. NZB-nya tetap di `nzbs/`, dan release debrid tetap ada di akun. Episode lain dari pack yang sama membuat release tetap ada selama masih ditempatkan atau masih ada di folder release. Begitu juga folder release yang sudah dipindahkan ke tempat lain, dan episode yang sudah berhenti terbaca tapi mungkin masih bisa diperbaiki. Menghapus sidecar di tempat ia diunggah tidak pernah menghapus release. Menghapus subtitle terakhir yang diimpor Sonarr atau Radarr di sebelah video itu, iya.

`dav_allow_rename` dan jalur hapus mount yang tidak dibatasi itu tidak ada hubungannya dengan semua ini. Keduanya mengatur jalur yang mengganti nama atau menghancurkan isi akun debrid. Penulisan di bawah `__magic__` tidak mencapai akun mana pun. `mount_read_only: true` tetap mengesampingkan semuanya, di kernel.

Membatalkan tombstone cukup dengan satu klik di dashboard.

Jadi upgrade meninggalkan release yang digantikannya di library kamu. **Manage > Duplicates** menampilkan sisa-sisa itu di samping release yang sekarang dipakai \*arr, dan menghapus yang kamu pilih. Lihat [menemukan release duplikat](acquisition.md#finding-duplicate-releases).

## Filter dan `__all__` tidak berubah {#filters-and-__all__-are-untouched}

Rilis yang sudah kamu pindahkan tetap ada di `movies`, tetap ada di `recent`, tetap ada di `__all__`, dengan nama aslinya. `__magic__` itu tampilan kedua dari library yang sama, bukan pemindahan.

Ini sering bikin orang kaget, jadi perlu saya tegaskan: **memindahkan sesuatu di `__magic__` hanya mengubah `__magic__`.** Direktori filter dihitung dari rilisnya, dan rilisnya sendiri tidak berubah.

Untuk media server, arahkan ke **salah satu** dari keduanya. Library Plex yang memindai `shows/` dan `__magic__/tv` sekaligus akan menemukan setiap episode dua kali. Hal yang sama berlaku untuk `__movies__`, `__shows__` dan `__anime__`: arahkan library ke salah satunya saja, jangan pernah ke `__magic__` itu sendiri.

## Sidecar: `.nfo`, poster, subtitle {#sidecars-nfo-posters-subtitles}

\*arr menulis metadata di sebelah video, dan Bazarr menulis subtitle. Itu file sungguhan dan zurg tidak punya tempat untuk menyimpannya di library debrid, jadi file-file itu disimpan di disk lokal di `data/local/__magic__/`.

Cara mengatur Bazarr, dan bagaimana subtitle-nya sampai ke rex, ada di [Subtitles with Bazarr](subtitles.md).

Kalau kamu pakai mount bawaan zurg, ini sudah berjalan dan kamu tidak perlu melakukan apa-apa: mount adalah gabungan dari `data/local` dan WebDAV zurg, dan rclone mengirim setiap file baru ke bagian lokal. zurg bahkan tidak pernah melihat penulisan itu. Inilah juga alasan tes "is this folder writable?" milik Sonarr lolos.

Kalau kamu memasang `/dav` sendiri, misalnya lewat rclone milikmu sendiri, Infuse, atau drive WebDAV di Windows, zurg menerima `PUT` dan menulis ke pohon yang sama, jadi kedua tampilan sama. Ada dua batas yang berlaku:

```yaml
magic:
  sidecar_max_mb: 32       # per file
  sidecar_budget_mb: 2048  # the whole tree
```

Melebihi batas pertama akan dapat `413`, melebihi batas kedua dapat `507`. Keduanya membatasi apa yang *zurg* tulis. Dengan `union_writable: local` yang default, upstream lokal milik rclone sendiri tidak bisa ditolak dari sini, tetapi pohon itu diukur ulang sebelum penolakan apa pun. Jadi file yang ditaruh rclone di sana dihitung ke anggaran saat zurg berikutnya diminta menulis file, kecuali file yang lebih besar dari `sidecar_max_mb`, yang tidak dihitung. `union_writable: server` membalik itu: pembuatan file itu sendiri sampai ke zurg, jadi batas-batas tadi berlaku untuk setiap penulisan lewat mount juga, dan apa pun di luar `__magic__` langsung ditolak.

Sidecar juga bisa ditaruh di dalam folder rilis, yaitu tempat *arr menulis `.nfo` untuk file yang dia impor ke sana. zurg menulis dan mengganti nama sidecar dengan nama apa pun yang belum dipakai rilis, dan menolak sidecar yang akan mengambil nama file asli rilis. Menghapus sidecar lewat `DELETE` benar-benar menghapusnya. Ini satu-satunya tempat di `__magic__` di mana penghapusan bukan tombstone: tombstone menyembunyikan entri yang masih ada di library di tempat lain, sedangkan isi sidecar hanya ada di `data/local` dan tidak di tempat lain.

## Dashboard {#the-dashboard}

Setelah library selesai dimuat, zurg mencatat satu baris log yang menyebutkan berapa baris yang ada di tabel dan berapa di antaranya yang dangling. Dengan begitu, library yang sudah kehilangan konten tidak akan terus menyimpan baris yang tidak dirujuk apa pun. `/magic/` pada port normal zurg menampilkan isi tabel: setiap baris yang tersimpan dikelompokkan per release, apa isinya dan dari mana asalnya, baris dangling di bagian tersendiri, serta pohon sidecar beserta ukurannya dibandingkan dengan anggarannya. Halaman ini juga menampilkan ukuran journal dan snapshot, serta ukuran seluruh `data/local`. Angka terakhir ini menunjukkan apakah sesuatu sedang diimpor dengan cara disalin. Di bawah `union_writable: local` (default), klien yang menyalin alih-alih memindahkan akan menaruh byte-nya di sana, dan tidak ada hal lain yang akan menampilkannya.

Di bawah `union_writable: server`, angka itu tetap nol dan log yang menyampaikannya. `PUT` dari klien yang menyalin akan ditolak, jadi pohon yang seharusnya diisinya tidak pernah ditulis. Byte-nya tidak hilang karena penolakan itu. Cache rclone yang menyimpannya dan mencoba lagi. Tetapi byte itu tidak lagi berada di disk ini dengan nama yang bisa dihitung zurg. [Panduan qBittorrent](sonarr-radarr-torrents.md) menjelaskan penyebabnya, yang dalam setiap kasus adalah pengaturan di sisi klien: sebuah \*arr hanya memindahkan impor jika ia bebas menghapus unduhan setelahnya.

Dari sana, Anda bisa reset sebuah placement (file kembali ke lokasi default), clear sebuah tombstone (entrinya kembali), drop sebuah baris dangling, prune semuanya sekaligus, atau delete sebuah sidecar. Setiap aksi dikonfirmasi sebelum dijalankan.

Daftar stored rows menampilkan seribu baris pertama. Pada library yang diatur oleh \*arr, itu hanya sebagian kecil dari tabel, karena setiap impor meninggalkan tombstone. Untuk menjangkau satu release, cari saja. Nama release, path di mount, atau hash akan menampilkan setiap baris yang tersimpan tentang release itu beserta tombol-tombolnya, berapa pun besarnya tabel. Daftar dangling menggunakan pencarian yang sama. Release yang tidak lagi ada di library tidak memiliki nama di tabel, hanya hash-nya dan path yang ditunjuk oleh barisnya.

Sidecar yang **tidak lagi dirujuk apa pun** didaftar terpisah dan dihitung: `.nfo` di samping release yang sudah keluar dari library, atau `.nfo` di dalam placement yang sudah dilupakan. Sidecar tersebut tetap disajikan. File asli adalah hal terakhir yang akan diresolve oleh sebuah path, dan tidak ada yang berada di atasnya yang mengklaim nama itu. Jadi yang hilang adalah alasan keberadaannya. zurg tidak pernah membersihkannya sendiri. Direktori yang Anda buat sendiri untuk sidecar, lewat mount alih-alih lewat zurg, akan terbaca sama, karena itu juga tidak meninggalkan baris apa pun.

Jika endpoint SABnzbd aktif, halaman ini juga menampilkan job-nya: id, nama, kategori, state, dan folder yang diserahkan ke \*arr. Ini cara tercepat untuk menjawab pertanyaan "kenapa Sonarr masih menampilkan ini sebagai downloading".

## Ketahanan {#durability}

Setiap perubahan ditambahkan ke `data/magic.journal` dan ditulis ke disk **sebelum** permintaan dijawab, jadi perpindahan yang dikira sudah dibuat oleh \*arr tetap aman meskipun terjadi crash. Journal digabung ke dalam snapshot `data/magic.json` saat startup, ketika ukurannya melewati ambang batas, dan saat shutdown.

Kedua file itu bukan tempat untuk mengubah tabel. zurg menyimpan tabel di memori dan menulis `magic.json` dari sana, jadi baris yang kamu hapus secara manual dari file saat zurg sedang berjalan akan muncul lagi setelah restart berikutnya. Gunakan tombol di dashboard.

Baris terakhir yang terpotong karena listrik mati akan dibuang, dan semua yang ada sebelumnya tetap disimpan. Snapshot yang ditulis oleh versi skema yang berbeda akan dibuang, bukan ditebak-tebak, dan baris journal dari versi lain akan menghentikan replay di titik itu. Snapshot atau journal yang tidak bisa dibaca hanya akan menjadi peringatan dan tabel kosong, bukan membuat start gagal. Tabel yang file-filenya tidak bisa *dibuka* akan membuat `__magic__` tetap melayani secara read-only, sebagai cermin dari `__all__` yang menjadi titik awalnya, dengan semua penulisan ditolak. Penulisan yang masuk selama shutdown ditolak dengan `503` daripada dikonfirmasi lalu hilang.

## Kode status {#status-codes}

Berguna kalau kamu mengendalikan namespace lewat WebDAV secara langsung; mount sudah menangani semua ini untukmu.

| Kode | Arti |
|---|---|
| `201` | MOVE, MKCOL atau PUT berhasil membuat sesuatu |
| `204` | DELETE, atau PUT yang mengganti sidecar |
| `400` | path yang tidak bisa disimpan oleh namespace ini, atau header `Destination` yang hilang atau tidak bisa dibaca |
| `403` | tujuan di luar `__magic__` atau di dalam `__movies__`, `__shows__` atau `__anime__`, path yang dijawab oleh library, path yang melewati sebuah file, `__magic__` itu sendiri, atau tabel yang hanya-baca |
| `404` | tidak ada apa-apa di sana (DELETE pada sesuatu yang tidak ada tetap menjawab `204`), atau MOVE keluar dari arsip yang sudah tidak punya entri tersebut |
| `405` | MKCOL di tempat yang sudah ada sesuatu, atau PUT ke direktori |
| `409` | parent tidak ada, direktori tidak kosong, tujuan sudah terisi dengan `Overwrite: T`, atau MOVE keluar dari arsip yang tidak bisa dibuka |
| `412` | tujuan sudah terisi dengan `Overwrite: F` |
| `413` / `507` | melebihi `sidecar_max_mb` / `sidecar_budget_mb` |
| `503` | sedang dimatikan, atau MOVE yang sumbernya tidak bisa dilayani saat ini — dengan `Retry-After` |

`MOVE` menolak tujuan apa pun di luar `__magic__`: direktori filter tetap hanya-baca.

Sebuah `MOVE` **keluar dari arsip** juga dicek terhadap arsipnya sendiri sebelum apa pun ditulis. Impor adalah `MOVE`, dan `MOVE` yang berhasil adalah janji yang tidak akan dicek ulang setelahnya. Daftar isi yang sudah dijelajahi client bukan bukti untuk itu: isi arsip yang sudah di-parse disimpan di memori cache, jadi rilis yang byte-nya sudah hilang tetap menampilkan episodenya. Karena itu, kesehatan volume, kerusakan artikel pada rilis, dan — jika keduanya tidak memberi jawaban — arsipnya sendiri akan diperiksa lebih dulu, persis seperti `HEAD` pada path yang sama memeriksanya, dan rilis yang sehat menjawab dari memori cache yang sama yang sudah dibangun oleh daftar isinya. Sumber yang tidak akan pernah bisa dibaca menghasilkan `409`, yang tidak bisa dibaca saat ini menghasilkan `503` dengan `Retry-After`, dan nama yang tidak ada di arsip tetap `404`. Tidak ada yang dicatat saat ditolak.

## Batasan yang perlu diketahui {#limits-worth-knowing}

- **`magic.enabled` perlu restart.** Rute didaftarkan saat startup.
- **Satu penempatan per file.** Memindahkan file lagi akan menempatkannya ulang; file yang sama tidak bisa muncul di dua path.
- **File di dalam set rar bisa ditempatkan** seperti file lain. Barisnya menyimpan volume dan path di dalamnya, jadi tetap aman saat di-repack seperti file biasa. Tapi tidak ada yang bisa dibuat *di bawah* file yang sudah ditempatkan. Path yang melewatinya akan ditolak.
- **`serve_strm_files` diabaikan di listing `__magic__`.** Namespace ini dibuat supaya \*arr bisa memindahkan file aslinya keluar, dan file `.strm` tidak bisa diimpor oleh apa pun. Klien yang meminta file `.strm` dengan nama tetap akan dilayani.
- **Path dibandingkan persis seperti yang diterima.** Tidak ada normalisasi Unicode dan tidak ada pengubahan huruf besar/kecil. Jadi klien yang menulis nama dengan cara tertentu lalu memintanya dengan cara lain tidak akan menemukannya.

## Lihat juga {#see-also}

- [sabnzbd.md](sonarr-radarr.md) — mengarahkan Sonarr dan Radarr ke zurg, yang memang tujuan dibuatnya `__magic__`
- [Daftar wanted DMM](dmm-wanted.md) — tekan Want di DMM dan zurg akan mengambilnya ke `__movies__`, `__shows__` atau `__anime__`
- [usenet.md](usenet.md) — backend NZB tempat hasil unduhan tersebut masuk
- [config.md](../reference/config.md#__magic__-a-directory-you-can-organise) — setiap kunci di blok `magic:`
