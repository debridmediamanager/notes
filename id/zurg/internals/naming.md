# penamaan zurg {#zurg-naming}

Hampir semua nama yang ditampilkan zurg itu dihitung, tidak pernah disimpan. Nama folder sebuah release, nama file di dalamnya, dan nama file di disk untuk cache record-nya semuanya diturunkan dari torrent setiap kali dicari. Tidak ada yang menulis nama-nama itu lalu membacanya lagi, karena nama yang disimpan adalah satu hal lagi yang harus selalu sejalan dengan library, dan menjaga keselarasan itu justru yang rusak saat repair atau re-resolution NZB.

Pengecualiannya adalah rename yang diminta operator. Rename itu DISIMPAN, di release itu sendiri, dan mengalahkan setiap derivasi di bawah. Aturannya ada di Bagian 9, dan panduan rename adalah versi untuk penggunanya. Semua yang lain di halaman ini menjelaskan nama yang dimiliki sebuah release ketika tidak ada rename yang diatur.

Ada satu konsekuensi yang perlu disebutkan dulu, karena ini sumber sebagian besar kejutan bagi siapa pun yang mengintegrasikan sesuatu dengan zurg: sebuah folder bisa berganti nama tanpa ada yang "mengganti namanya". Inputnya yang berubah, jadi outputnya ikut berubah.

File ini memuat aturan, bukan ambangnya. Jika sebuah aturan ditetapkan oleh heuristik, file ini cukup menyebut fungsi yang menetapkannya lalu berhenti di situ. Heuristik itu disetel berdasarkan release nyata dan bisa berubah, jadi menyalinnya ke sini hanya menambah satu hal lagi yang harus dijaga keselarasannya. Referensi kode bersifat relatif terhadap package.

## 1. Nama folder rilis {#1-the-release-folder-name}

`internal/torrent/key.go`, GetKey / GetKey_Original

Nama folder di bawah `__all__/`, nama file `.zurgtorrent`, kunci yang dipakai setiap pencarian, dan yang disebut zurg sebagai "access key" adalah satu string yang sama. String ini ditentukan dengan urutan berikut, dan kecocokan pertama yang menang:

  | Kondisi                                     | Nama folder               |
  |---------------------------------------------|---------------------------|
  | `ignore_renames: false`, Torrent.Rename diisi | Torrent.Rename          |
  | `retain_rd_torrent_name: true`              | Name, tidak diubah        |
  | `retain_folder_name_extension: true` DAN    | Name, tidak diubah        |
  |   Name mengandung OriginalName              |                           |
  | selain itu — kedua flag memakai nilai default | OriginalName, `.mp4` lalu |
  |                                             |   `.mkv` dipotong         |

`retain_rd_torrent_name` dicek lebih dulu dan menutupi `retain_folder_name_extension` sepenuhnya. Aturan kedua hanya berlaku jika Name mengandung OriginalName sebagai substring; jika tidak, pemotongan tetap dilakukan.

Pemotongan dilakukan dengan `strings.TrimSuffix` yang dijalankan dua kali, jadi sebenarnya ada tiga aturan dalam satu. Hanya `.mp4` dan `.mkv` yang dipotong, jadi `.avi`, `.ts`, `.iso` dan sisanya tetap ada di nama folder. Pencocokannya case sensitive, jadi `Movie.2019.MKV` tetap mempertahankan `.MKV`. Keduanya dijalankan berurutan, bukan sebagai alternatif, sehingga `Movie.2019.mkv.mp4` menjadi `Movie.2019`. Sebuah suffix mungkin ditambahkan setelahnya — lihat bagian 4. Hasilnya selalu satu komponen path dan tidak pernah dipecah di `/`.

**DEPRECATED.** `retain_folder_name_extension` dan `retain_rd_torrent_name` sudah deprecated dan akan dihapus. Perilakunya belum berubah untuk sekarang, dan mengatur salah satunya akan mencatat peringatan saat startup. Keduanya mengunci library pada Name, yang diubah akun di bawah zurg (bagian 2). Nilai default mengunci pada apa yang dideklarasikan torrent itu sendiri, yang tidak diubah akun. Pada instance yang melayani Sonarr atau Radarr — yang memiliki blok `sabnzbd:` atau `qbittorrent:` — nilai default adalah satu-satunya nilai yang benar, karena access key yang berpindah setelah impor akan membuat rilisnya hilang. `ignore_renames` tidak deprecated.

(Terjemahan sebelumnya ditolak: judul-judulnya berbeda. Pertahankan struktur persis.)

## 2. Dari mana Name dan OriginalName berasal {#2-where-name-and-originalname-come-from}

  Real-Debrid   `internal/realdebrid/types.go`
                Name = `filename`, OriginalName = `original_filename`

  TorBox        `internal/torbox/types.go`, wireTorrent.originalName
                Name = `name`. OriginalName = satu-satunya direktori tempat semua file berada, jika hanya ada satu. File di root pohon akan memakai `name`, kecuali satu file tunggal tanpa folder, yang memakai namanya sendiri.

  AllDebrid     `internal/alldebrid/types.go`, originalName
                Aturan yang sama seperti TorBox, diterapkan pada daftar file yang sudah diratakan, dengan cadangan ke `filename` milik magnet.

  NZB           `internal/nzb/provider.go`
                Name dan OriginalName sama-sama releaseName, dan Hash torrent adalah release id. Bagian 3.

Karena backend debrid menurunkan OriginalName dari folder root torrent itu sendiri, dua akun yang menyimpan konten yang sama akan menghasilkan nama folder yang sama.

Arti dua field Real-Debrid, diukur pada 2026-08-27 terhadap akun uji dengan ~84k torrent, 252 di antaranya diambil sampelnya secara read-only melalui `GET /torrents/info`: `original_filename` selalu berupa nama yang dideklarasikan torrent, yaitu nama pack atau folder, di setiap kasus, dan tidak pernah nama satu file. `filename` bukan itu. Ia mengerucut menjadi nama dasar satu file, dan itu terjadi persis ketika satu file dari torrent multi-file yang dipilih: 90 dari 112 torrent sampel dengan bentuk itu, dibandingkan 0 dari 34 yang memilih beberapa tapi tidak semua file, dan 0 dari 24 yang memilih semua file. Pada pack 221 file dengan satu episode dipilih, `original_filename` berisi `Marvel Cinematic Universe MCU Collection 2008-2023 1080p jZQ` sementara `filename` berisi `Spider-Man.No.Way.Home.2021.1080p.BluRay.x264...-NOGRP.mkv`. Jadi, default memberi nama pack, sedangkan `retain_rd_torrent_name: true` memberi nama file individual. Itulah sebabnya flag ini di-deprecated: `filename` mengikuti status akun, sedangkan kunci akses tidak boleh begitu.

## 3. Penamaan rilis NZB {#3-nzb-release-naming}

`internal/nzb/provider.go`, releaseName; `internal/nzb/parse.go`

ID release, yang juga menjadi Hash-nya, adalah `hex(sha1(lowercase(nzb filename)))`
— dihitung dari nama file, bukan isinya, jadi menyimpan ulang NZB tidak akan membuat torrent yang dibuat darinya terlepas. Nama folder adalah nama FILE tersebut tanpa ekstensinya, kecuali bagian namanya terlihat seperti hash atau habis hilang saat disanitasi. Dalam kasus itu, nama metadata `<head>` milik NZB yang dipakai sebagai gantinya. Nama file yang dipilih karena itulah nama yang ditulis oleh indexer, disimpan oleh downloader, dan dicari oleh automasi, sementara indexer sering repost dengan subject line di blok metadata. `stemLooksJunk`, `looksLikeHash`, dan `sanitizeReleaseName` di `internal/nzb/parse.go` menjawab ketiga pertanyaan tersebut; anggap saja sebagai kotak hitam.

## 4. Tiga akhiran nama {#4-the-three-name-suffixes}

Ada tiga format sufiks. Ketiganya tidak berhubungan.

  ` {xxxxxx}`   Pada folder rilis, saat dua rilis BERBEDA memakai nama yang sama:
                enam karakter hex dari infohash milik rilis itu sendiri. Di dalam
                grup, rilis yang PALING BARU ditambahkan tetap memakai nama polos
                dan semua rilis lain mendapat tag. Ditentukan sekali per refresh oleh
                satu proses yang bisa melihat seluruh library, lalu disimpan sebagai
                KeySuffixed, sehingga GetKey tetap merupakan fungsi murni dari torrent
                (`internal/torrent/key.go`, disambiguateNames). Torrent RD dan NZB
                dari rilis yang sama dihitung sebagai dua rilis berbeda di sini,
                karena hash NZB adalah sha1 dari nama filenya.

  ` (tag).ext`  Pada FILE yang basename-nya berulang di dalam satu rilis, karena zurg
                meratakan pohon torrent menjadi satu direktori. Tag-nya adalah
                direktori yang sudah membedakan file-file yang bentrok, yaitu komponen
                path terdangkal yang berbeda di seluruh grup. Jika tidak ada, dipakai enam
                karakter hex dari sha1 atas path file. Kedalaman mana yang memenuhi syarat,
                dan apa yang boleh dibawa komponen ke dalam nama file, diatur oleh `dupeTags`
                dan `sanitizeTag` di `internal/torrent/dupenames.go`. Perlakukan keduanya
                sebagai opaque. Grup mencakup setiap file dalam daftar, dipilih atau tidak,
                sehingga file yang berhenti dipilih tetap menghasilkan key tempat ia dicatat.
                `__magic__` adalah satu-satunya pengecualian: ia menampilkan pohon asli rilis
                tanpa tag sama sekali, karena di sana direktorinya sudah membedakan file-file
                tersebut. Lihat bagian 8.

  `_xxxxxxxx`   Pada nama file DI DISK yang inputnya mengandung karakter non-ASCII:
                delapan karakter hex dari sha256 input tersebut. Lihat bagian 6.
                Tidak pernah muncul di mount.

## 5. Nama file di dalam rilis {#5-file-names-inside-a-release}

`internal/torrent/manager.go`. VisibleName(key, file) adalah satu-satunya acuan untuk nama yang ditampilkan mount dan nama yang harus cocok saat lookup: File.Rename jika ada dan `ignore_renames` bernilai false, kalau tidak, pakai kunci SelectedFiles, yang sudah membawa tag dari bagian 4. GetFilename malah mengembalikan `filepath.Base(file.Path)` dan karena itu membuang tag tersebut. Tampilan dan lookup harus sama-sama lewat VisibleName, kalau tidak permintaan untuk nama yang bertag akan tidak ketemu apa-apa, sementara N file memakai nama polos yang sama.

## 6. Nama file di disk {#6-on-disk-filenames}

`internal/torrent/utils.go`, sanitizeFilename, itu tidak transparan, dan fungsinya HANYA berlaku untuk
file yang ditulis zurg ke host (`data/<name>.zurgtorrent` dan pohon STRM),
tidak pernah untuk yang disajikan mount. Fungsinya jauh lebih agresif dibanding apa pun di atas:
rilis yang folder mount-nya bernama `Три богатыря` punya file cache yang namanya berupa
deretan underscore ditambah sufiks `_xxxxxxxx`, yang membuatnya tetap berbeda dari
judul Cyrillic berikutnya. Itu ruang nama yang berbeda, dan memang tidak dimaksudkan untuk cocok.

## 7. Isi arsip {#7-archive-interiors}

Rilisan yang disajikan dari RAR, ZIP atau 7z menampilkan isi arsipnya, bukan volume-volumenya. Dua aturan mengubah nama untuk isi tersebut.
`stripRedundantRoot` (`internal/universal/rar_streamer.go`) menghapus direktori induk di awal yang membungkus seluruh arsip. `payloadRenames`
(`internal/universal/deobfuscate.go`) menampilkan satu payload yang ter-obfuscate dengan nama RILISAN, sekaligus memindahkan setiap entri yang berbagi nama dasar yang sama dengannya. Yang dianggap ter-obfuscate adalah `looksObfuscated` di file yang sama, yaitu port zurg dari tes SABnzbd. Tes ini mengecek nama yang buram, beserta pengaman di sekitarnya. Tidak ada yang ditulis ulang di disk, dan `archiveName` juga mengenali ejaan asli arsipnya.

## 8. Nama direktori {#8-directory-names}

`internal/torrent/manager.go`, `internal/torrent/provider_directories.go`

Bawaan, dan dicadangkan:

    __all__          setiap rilis
    __unplayable__   rilis yang tidak ada apa pun yang bisa diputar
    __dump__         torrent yang di-dump
    __downloads__    tampilan downloads
    __magic__        overlay yang bisa ditulis, satu-satunya direktori yang layout-nya disimpan, bukan dihitung. `__all__`-nya sendiri mencerminkan
                     library — setiap rilis yang ada di `__all__`, masing-masing sebagai
                     pohon direktori yang digambarkan oleh nilai `File.Path` file-filenya
                     bukan diratakan (`internal/magic/tree.go`) — dan
                     semua yang ada di samping mirror itu adalah yang disimpan pengguna.
                     Mirror itu dihitung, jadi tidak boleh ada yang ditulis ke dalamnya;
                     `MirrorDirectory` di `internal/magic/resolve.go` menamainya
    int__all__       indeks hash internal

`__downloads__` dan `__magic__` bukan filter, jadi keduanya ditambahkan ke daftar root secara manual, dan `__magic__` hanya muncul saat magic diaktifkan. Nama apa pun yang diawali `int__` dilewati sepenuhnya dari daftar root.

Untuk setiap akun ada satu lagi, `"__" + account name + "__"` — `__realdebrid__`, `__torbox__`, `__nzb__` — dibuat dari blok providers. Direktori ini juga menentukan ke mana pembacaan diarahkan: file yang dibuka di bawah `__torbox__` dilayani oleh TorBox meskipun akun lain memiliki release yang sama dan akan menang berdasarkan urutan config. Akun yang namanya bentrok dengan nama yang dicadangkan tidak mendapatkan direktori ini, dan zurg akan memberi peringatan. Semua yang lain di root adalah key dari blok `directories:`, apa adanya.

## 9. Ganti nama oleh pengguna {#9-user-renames}

`internal/torrent/rename.go`, `internal/torrent/rename_bulk.go`

Rename itu cuma tampilan, bukan perubahan apa pun pada akun debrid kamu. Disimpan sebagai Torrent.Rename atau File.Rename, dan nilainya menang atas semua turunan nama di atasnya, sampai `ignore_renames: true` membuat zurg mengabaikannya sama sekali.

Rename torrent hanya diterima kalau namanya, setelah di-trim, tidak kosong, tidak mengandung `/` atau `\`, sama dengan hasil `filepath.Clean` dari nama itu sendiri (ini juga menolak `.` dan `..`), dan tidak bentrok dengan access key yang sudah ada milik hash lain. Saat diterapkan, peta direktori akan diganti kuncinya, `.zurgtorrent` ditulis dengan nama baru, dan file lama dengan nama lama DIHAPUS. Kalau file lama tertinggal, saat restart zurg akan memuat keduanya dan rename-nya diam-diam kembali ke nama lama.

Season fix (`/torrents/season-fix/plan` dan `/apply`) adalah rename file massal yang digerakkan oleh pencocokan episode milik Plex sendiri. Plan hanya membaca dan memberi alasan skip per file. Apply menerima daftar hash yang eksplisit, bukan flag apply-all. Dashboard menjalankan keduanya dari `/season-fix/`, dan di halaman itu juga aturan pemetaan serta alasan skip dijelaskan untuk operator.

## 10. Konsekuensi bagi apa pun yang terintegrasi dengan zurg {#10-consequences-for-anything-integrating-with-zurg}

Kalau kamu membuat path dari nama torrent, misalnya symlink farm, remote path mapping, atau script, ini cara-cara yang biasanya bikin salah:

  a. Ekstensinya. Hanya `.mkv` dan `.mp4` yang dilepas, dan case-sensitive. Container lain tetap menyimpan ekstensinya di nama folder.

  b. Rename. `Torrent.Rename` menang atas nama yang diturunkan, dan kalau RD mengganti nama torrent, `Name` ikut berubah tanpa kamu sadari.

  c. Hash suffix. Kalau dua rilis berbeda punya nama yang sama, salah satunya dapat ` {a1b2c3}`, dan rilis mana yang kena suffix itu bisa berpindah seiring konten baru ditambahkan.

  d. Tag file duplikat. File yang basename-nya berulang di dalam satu rilis disajikan sebagai `name (tag).ext`, dengan tag berupa komponen direktori atau hash path. `filepath.Base(file.Path)` tidak bisa menghasilkan ulang tag ini.

  e. Rename arsip. Payload terobfuskasi di dalam arsip disajikan dengan nama rilis, bukan nama aslinya.

  f. Nama NZB diambil dari FILENAME file `.nzb`, bukan dari isi di dalamnya, kecuali nama file-nya berupa hash. Beri nama file-nya, beri nama folder-nya.

  g. Nama file di disk yang sudah disanitasi itu namespace yang berbeda dari nama mount, dan untuk rilis non-ASCII memang sengaja tidak cocok.

Cara yang paling andal untuk mencari rilis adalah lewat hash, lalu tanyakan ke zurg namanya apa. Menyusun ulang nama itu sama saja dengan menebak, dan setiap aturan di atas adalah cara supaya tebakan itu meleset.
