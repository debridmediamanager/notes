# Changelog

## zurg menemukan anime, acara harian, dan special untuk Sonarr {#zurg-finds-anime-daily-shows-and-specials-for-sonarr}

Dulu, sumber Sonarr melewati serial harian, serial anime, dan episode spesial sebuah serial, masing-masing dengan satu peringatan. Sekarang, episode yang hilang dari acara harian juga diminta berdasarkan tanggal tayangnya (`The Daily Show 2026.11.03`). Untuk anime, permintaannya berdasarkan nomor yang dihitung oleh serinya sendiri (`Jujutsu Kaisen 30` adalah episode keenam musim kedua). Episode spesial diminta sebagai musim `00`. Semua ini berjalan di samping pencarian biasa berdasarkan musim dan episode. Parser Sonarr sendiri yang menentukan episode mana yang dimaksud tiap rilis, seperti untuk serial apa pun, dan profil kualitas menilainya seperti biasa.

Video yang disimpan untuk anime atau acara harian dinamai `JUJUTSU KAISEN - S02E06 - <the release's own name>`, karena pemindaian ulang Sonarr membaca file hanya dari namanya. Kalau tidak, `2nd Season - 06` akan masuk ke musim 1. Video untuk serial biasa dan episode spesial tetap memakai nama aslinya.

Episode spesial masuk ke folder yang dinamai oleh **Specials Folder Format** di Sonarr. Hanya rilis yang bernama `S00Exx` yang bisa cocok dengan episode spesial. Lihat [Apa yang diminta zurg dari Sonarr](../guides/acquisition.md#what-zurg-asks-sonarr-for).

## Simpan film yang diinginkan di 1080p dan 4K {#keep-a-wanted-film-at-1080p-and-at-4k}

`quality: [1080p, 4k]` di blok `acquisition:` menyimpan dua salinan setiap film di daftar DMM wanted kamu, supaya TV 1080p bisa memutar salah satunya tanpa transcoding file 4K. Setiap salinan mengambil rilis terbaik dengan resolusi sama atau lebih rendah dari resolusinya sendiri, dan naik sendiri ke resolusi itu. Selama belum ada yang lebih baik dari 1080p, keduanya berbagi satu salinan. Serial, dan semua sumber lain, tetap hanya dapat satu salinan. Lihat [a copy at each of several resolutions](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

## pembaruan zurg berfungsi setelah instalasi satu baris {#zurg-update-works-after-the-one-line-install}

Installer satu baris masuk ke GitHub lewat GitHub CLI. Mereka mengunduh CLI itu khusus untuk keperluan tersebut lalu menghapusnya lagi setelah selesai. `zurg update` kemudian mencari GitHub CLI dan tidak menemukannya. Proses berhenti dengan pesan "no GitHub credential found" padahal sesi login kamu masih tersimpan. GitHub CLI bawaan Ubuntu terlalu lama untuk menyerahkan sesi login itu, jadi update juga berhenti dengan cara yang sama di sana.

`zurg update` sekarang juga menggunakan GitHub CLI yang disimpan installer di `bin` di sebelah zurg. Sesi login yang disimpan GitHub CLI tanpa keyring sekarang bisa dipakai, meskipun CLI-nya sudah tidak ada. Jika tetap tidak menemukan apa pun, perintah akan mencetak satu perintah yang memperbaikinya. Jalankan update dari installer sekali saja, dan setiap `zurg update` berikutnya akan masuk sendiri.

## Banyaknya tautan Real-Debrid lama yang gagal sekaligus tidak lagi disebut sebagai gangguan {#many-old-real-debrid-links-failing-at-once-is-no-longer-called-an-outage}

Link Real-Debrid berhenti jalan beberapa bulan setelah dibuat, jadi rilis yang ditambahkan di waktu yang kurang lebih sama juga berhenti diputar di waktu yang kurang lebih sama. Kalau lebih dari lima di antaranya gagal dalam satu kali repair, zurg mencatat "suspected provider-wide outage" dan menahan repair untuk semua kecuali lima. Akibatnya, satu batch besar tetap rusak jauh lebih lama dan kelihatannya seperti Real-Debrid sedang down. Sekarang zurg lebih dulu meminta Real-Debrid untuk rilis di akun yang sama yang masih bisa diputar. Kalau yang itu bisa diputar, berarti link yang gagal memang sudah tua, dan semua rilis di-repair seperti biasa. Hanya ketika Real-Debrid juga menolak link yang masih berfungsi, zurg menganggapnya sebagai outage dan menunggu.

## Tautan sesi Emby di dasbor membuka dasbor Emby {#the-dashboards-emby-session-links-open-embys-dashboard}

Tautan "active sessions" dan "transcodes" di panel Emby pada dashboard sebelumnya membuka `/web/#/dashboard`, yaitu alamat Jellyfin untuk halaman itu, dan Emby terus macet di splash screen. Sekarang kedua tautan membuka `/web/index.html#!/dashboard`, alamat yang dipakai Emby sendiri. Tautan di panel Jellyfin tidak berubah.

## .nfo yang hilang tidak lagi mengirim rilis Usenet ke repair {#a-missing-nfo-no-longer-sends-a-usenet-release-to-repair}

Post-Usenet lama sering kehilangan .nfo-nya lebih dulu, sementara setiap bagian video dan arsip masih utuh. zurg menganggap itu sebagai kerusakan pada seluruh rilis. Setiap kali menemukan .nfo seperti itu, zurg memulai perbaikan, dan itu terulang lagi setiap kali restart. Perbaikan yang benar-benar diperlukan jadi menunggu di belakang ratusan perbaikan yang tidak berguna. Beberapa rilis yang sebenarnya bisa diputar dengan baik ditandai sebagai unrepairable, dan satu-satunya cara untuk memulihkannya adalah dengan menghapus .nfo-nya.

Sekarang, file .nfo atau file kecil lain di samping video yang hilang akan dibaca sebagai kosong dan tidak meminta perbaikan. File tersebut juga tidak lagi membuat rilis ditandai sebagai unrepairable. Video yang rusak bisa diperbaiki lagi ketika .nfo di sampingnya sudah tidak ada. Rilis yang sudah ditandai unrepairable dengan cara ini akan dicek ulang dalam sekitar satu hari dan kembali normal dengan sendirinya.

## File Usenet tidak lagi memutar kesunyian ketika server mengirim artikel dari unggahan lain {#usenet-files-no-longer-play-silence-where-a-server-sent-another-uploads-article}

Beberapa news server menjawab permintaan satu artikel dari file Anda dengan artikel dari unggahan lain yang punya nomor sama. zurg baru menyadarinya ketika unggahan lain itu punya artikel lebih sedikit daripada file Anda. Pada file pendek seperti volume RAR dan episode pendek, zurg mengambil artikel yang salah dan memutar keheningan untuk bagian tersebut. Log-nya menyebut `an internal mapping failure in zurg` dan menulis bahwa offset-nya `falls between two articles that are both present and neither covers`. Sekarang zurg juga memeriksa ukuran file yang dinyatakan setiap artikel. Artikel dari file lain akan ditolak, dan zurg akan meminta artikel yang benar dari akun news Anda yang lain. Artikel yang sudah disimpan build lama di cache artikelnya juga ditolak. Jika hanya punya satu akun, bagian tersebut tetap diputar sebagai keheningan. Sekarang log akan menulis bahwa server mengirim artikel dari file lain, bukan menyalahkan zurg.

## Koneksi Usenet kembali ke kecepatan penuh setelah aplikasi lain berhenti menggunakan akun {#usenet-connections-come-back-at-full-speed-after-another-app-stops-using-the-account}

Jika penyedia Usenet Anda pernah menolak zurg karena terlalu banyak koneksi, misalnya saat program lain atau zurg sebelumnya masih memakai sebagian koneksi, zurg terus menambah koneksi satu per detik selama ia berjalan, bahkan setelah ruang koneksi kembali tersedia. Setiap kali ada jeda sepi, rentetan pengambilan (grab) dimulai lagi dari dua koneksi hangat, sehingga akun besar butuh lebih dari satu menit untuk kembali ke kecepatan penuh dan impor ikut antre di belakangnya, dengan "waited 5s for a connection (queued for the account's allowance)" di log debug. Sekarang, setelah penyedia kembali menerima koneksi dan satu menit berlalu tanpa penolakan lagi, zurg langsung membuka koneksi yang dibutuhkan.

## Log debug menyebutkan kapan sebuah fetch menunggu koneksi saat beberapa news server dikonfigurasi {#the-debug-log-says-when-a-fetch-waits-for-a-connection-with-several-news-servers-configured}

Dengan satu news server, fetch yang menunggu koneksi lebih dari lima detik akan meninggalkan baris debug yang memberitahukan hal itu. Dengan dua server atau lebih, baris itu tidak pernah muncul, jadi menambahkan server kedua membuat baris itu hilang, terlepas dari apakah penungguan sudah berhenti atau belum. Sekarang baris itu juga muncul untuk pengaturan multi-server dan menyebutkan server-server yang sedang ditunggu oleh fetch tersebut.

## Grab Usenet tanpa file repair dan artikel pertama yang mati langsung gagal {#a-usenet-grab-with-no-repair-files-and-a-dead-first-article-fails-at-once}

A release posted tanpa file PAR2 yang artikel pertamanya sudah hilang dari semua news server akan ditahan selama lima menit sebelum Radarr atau Sonarr tahu bahwa grab-nya gagal, sambil menunggu perbaikan yang tidak punya apa-apa untuk diperbaiki. Sekarang zurg langsung mengecek bahwa tidak ada data pemulihan dan melaporkan grab gagal saat itu juga, jadi client memasukkannya ke blocklist dan lanjut ke rilis berikutnya.

## Grab Usenet yang diperbaiki oleh repair tidak lagi dilaporkan gagal lima menit kemudian {#a-usenet-grab-that-repair-fixed-is-no-longer-reported-failed-five-minutes-later}

Saat sebuah grab kehilangan beberapa artikel dan file PAR2-nya bisa membangunnya kembali, zurg memperbaikinya. Tapi read-ahead yang berjalan selama perbaikan bisa meminta lagi artikel yang hilang itu, lalu ditolak sebentar setelah perbaikan selesai. Penolakan itu membuat release masuk lagi ke daftar rusak, sehingga grab ditahan selama lima menit lalu dilaporkan gagal, dan Radarr atau Sonarr memasukkan release yang sebenarnya bisa diputar dengan baik ke daftar blokir. Penolakan untuk artikel yang sudah dibangun ulang oleh perbaikan tidak lagi dihitung sebagai kerusakan.

## Unduhan yang di-upgrade dan datang bersama .nfo atau subtitle ikut dihapus {#upgraded-downloads-that-came-with-an-nfo-or-subtitles-are-deleted-too}

Dengan `magic.allow_delete`, video yang dihapus yang tidak berada di dalam arsip RAR dulunya dihapus sendirian. File `.nfo`, subtitle, dan poster yang diposting di sebelahnya tetap menjaga unduhan itu di perpustakaan Anda. NZB-nya tetap tinggal di `nzbs/` dan torrent-nya tetap ada di akun debrid Anda. Setiap peningkatan kualitas pada unduhan seperti itu meninggalkan sisa. Sekarang seluruh unduhan dihapus begitu tidak ada lagi yang di `__magic__` memakainya. Unduhan akan tetap ada selama episode lain dari unduhan tersebut masih ada di perpustakaan Anda atau masih menunggu di folder sendiri untuk diimpor. Subtitle yang diimpor Sonarr atau Radarr di sebelah video akan tetap menahan video itu sampai subtitle tersebut juga dihapus.

## Unduhan Usenet yang diganti dan gagal tidak lagi menumpuk {#replaced-and-failed-usenet-downloads-no-longer-pile-up}

Dengan `magic.allow_delete`, menghapus episode atau film yang berasal dari arsip RAR dulu hanya menyembunyikannya. Download asalnya tetap ada di library, dan NZB-nya tetap tersimpan di `nzbs/` selamanya. Saat kamu meng-upgrade episode satuan ke season pack, satu download seperti ini tertinggal untuk setiap episode.

Sekarang seluruh download akan dihapus begitu tidak ada lagi yang memakainya di `__magic__`. Download tetap disimpan selama episode lain dari arsip yang sama masih ada di library kamu. Download juga tetap disimpan selama folder-nya sendiri masih punya sesuatu yang bisa di-import.

Sonarr dan Radarr meminta file dari download yang gagal dihapus saat mereka menghapusnya. zurg tetap menyimpan NZB-nya. Sekarang zurg akan menghapusnya jika tidak ada yang di-import dari rilis tersebut. Download yang selesai dan sudah di-import tetap menyimpan NZB-nya seperti biasa, karena file yang di-import masih diputar dari NZB tersebut.

## zurg sekarang memberi tahu ketika library selesai dimuat {#zurg-now-says-when-the-library-has-finished-loading}

Docker menganggap zurg sehat begitu sudah berjalan. Library yang besar bisa terus memuat selama lebih dari satu jam setelah itu. Selama itu, folder di mount gagal dengan `Input/output error` dan kelihatannya seperti instalasi yang rusak. Alamat `/ready` yang baru bisa membedakan keduanya. Alamat ini menjawab 503 sampai library selesai dimuat, dan menjawab 200 setelah selesai. Alamat ini tidak perlu password. Di dalam container, `/app/healthcheck.sh --ready` memeriksa hal yang sama. Health check bawaan container tetap hanya memeriksa apakah zurg sedang berjalan. Dengan begitu, proses pemuatan pertama yang lama tidak akan membuat container di-restart atau menahan mount yang bergantung padanya. Health check sekarang juga membaca environment variable `PORT`. Dulu, container yang mengatur `PORT` diperiksa di port yang salah.

## Acquisition dapat melewati rilis berdasarkan kata dalam namanya {#acquisition-can-skip-releases-by-words-in-their-names}

Atur `exclude_words` di blok `acquisition:` dan zurg tidak akan pernah mengambil rilis yang namanya memuat salah satu kata tersebut. `exclude_words: [DV, HDR10+]` menjaga Dolby Vision dan HDR10+ tetap tidak masuk ke TV yang tidak bisa memutarnya, tetapi tetap mengambil 4K dengan HDR biasa. Ini berlaku untuk watchlist Plex, Seerr, Radarr dan Sonarr, serta untuk Usenet dan torrent. Hanya kata utuh yang dicocokkan. `DV` tidak menangkap `DVDRip` atau film berjudul Adventures. `DV`, `DoVi` dan `Dolby Vision` artinya sama, begitu juga `HDR10+` dan `HDR10Plus`. Radarr dan Sonarr tidak pernah ditanya tentang rilis yang dikecualikan.

## Radarr dan Sonarr dapat mengambil kualitas terbaik profil lebih dulu {#radarr-and-sonarr-can-take-the-profiles-best-quality-first}

zurg biasanya mengambil rilis yang diizinkan dan paling cepat dicek. Untuk film, biasanya itu WEB-DL 1080p. Proses upgrade kemudian bergerak menuju cutoff profil Anda. Untuk serial, season pack diambil lebih dulu sebelum episode lepas. Jadi, pack 1080p bisa mengisi satu season meskipun episode 2160p sebenarnya tersedia. Atur `best_first: true` di bawah `acquisition:`, dan pengambilan pertama akan mengikuti profil kualitas Radarr atau Sonarr Anda. Resolusi terbaik yang diizinkan akan diambil lebih dulu. Apa pun yang sama dengan atau di atas cutoff dianggap sudah cukup bagus. Jika sebuah rilis ternyata sudah hilang, zurg akan turun ke urutan berikutnya dalam profil. File pertama mungkin butuh waktu lebih lama untuk tiba, karena rilis terbaik sering kali berupa posting multi-bagian yang berukuran besar. Fitur ini nonaktif secara default.

## Hasil torrent tidak lagi mendesak NZB di tempat yang tidak ada akun menerima torrent {#torrent-results-no-longer-crowd-out-nzbs-where-no-account-takes-torrents}

Pada instance yang punya penyedia NZB tapi tidak punya akun debrid yang menerima torrent, acquisition tetap mencari di indexer Torznab, dan setiap torrent yang ditemukan memakan satu dari tiga rilis yang disediakan untuk tiap percobaan episode atau season pack sebuah show. Dengan `prefer: torrents`, atau saat torrent 4K diranking di atas NZB 1080p, NZB tidak pernah dicoba dan episode-nya gagal. Sekarang indexer Torznab dilewati di kondisi seperti itu, dengan satu baris di log yang memberi tahu hal ini, dan rilis yang tidak bisa ditaruh di instance tidak lagi dihitung sebagai percobaan. Movie juga tidak lagi bertanya ke Radarr soal torrent seperti itu.

## Acquisition tidak lagi menganggap NZB sudah selesai jika tidak ada yang bisa memutarnya {#acquisition-no-longer-counts-an-nzb-as-done-where-nothing-can-play-it}

Pada instance yang punya akun debrid tetapi tanpa penyedia NZB, akuisisi tetap mencari di indexer Newznab kamu, dan NZB yang berhasil diambil dihitung sebagai selesai tanpa pengecekan apa pun. Judul dari watchlist Plex bisa hilang dari daftar untuk file yang tidak bisa diputar oleh instance tersebut. Sekarang indexer Newznab dilewati di sana, dengan satu baris di log yang memberi tahu hal itu, dan NZB tidak pernah dihitung sebagai selesai pada instance tanpa penyedia NZB.

## Rilis yang tidak punya apa pun lagi untuk diputar dilaporkan sekali, bukan setiap hari {#a-release-with-nothing-left-to-play-is-reported-once-instead-of-every-day}

Ketika setiap file yang bisa diputar dari sebuah rilis sudah dihapus, zurg memperingatkan bahwa rilis itu "has no playable file that still reads" setiap hari. Perpustakaan dengan seratus rilis seperti itu mencatat seratus peringatan setiap hari untuk rilis yang tidak pernah disentuh siapa pun. Sekarang peringatan hanya muncul sekali, dan rilis itu baru diperiksa lagi setelah ada sesuatu yang berubah. Memulihkan file tetap langsung mengembalikannya.

## Rilis rusak di AllDebrid dan TorBox kembali ketika file-nya masih bisa diputar {#broken-releases-on-alldebrid-and-torbox-come-back-when-the-files-still-play}

Rilis yang hanya ada di AllDebrid, TorBox, Premiumize, Offcloud atau Debrid-Link
bisa tetap rusak dan tersembunyi selama berminggu-minggu, padahal akunnya masih menyajikannya. Repair tidak menambahkan ulang rilis
di layanan ini dengan sendirinya, karena mereka sengaja menghapus konten, dan
tidak ada yang pernah memeriksa apakah file-filenya sudah mulai berfungsi. Sekarang Repair
menanyakan ke akun sekali sehari apakah file dari rilis yang rusak masih bisa diputar, lalu
mengembalikan yang masih bisa diputar, tanpa menambahkan apa pun. Apa pun yang benar-benar dihapus oleh akun tetap perlu tombol Repair. MCP repair outlook juga menyampaikan hal yang sama, bukan bilang bahwa tidak akan ada pemindaian yang pernah menanganinya.

## Grab yang diantrekan TorBox untuk slot gratis kini tampil sebagai queued dan selesai {#grabs-torbox-queues-for-a-free-slot-show-as-queued-and-finish}

Ketika semua slot unduhan di akun TorBox sedang terpakai, TorBox memasukkan grab baru dari Sonarr dan Radarr ke antriannya, dan zurg kehilangan jejak grab tersebut. Grab itu tampil sebagai fetching metadata selama sekitar sepuluh menit lalu berubah menjadi error, sehingga Sonarr dan Radarr membuangnya. Ketika TorBox kemudian mengunduhnya, tidak ada yang mengimpornya. Sekarang zurg mengikuti grab yang masih antre sampai TorBox memulainya dan terus mengikutinya sampai selesai. Selama menunggu, grab ditampilkan sebagai queued, dan timeout no-progress tidak berjalan sampai TorBox benar-benar memulainya.

## Kamu bisa mencari satu rilis di halaman `__magic__` {#you-can-search-for-one-release-on-the-__magic__-page}

Di library yang diatur Sonarr atau Radarr, setiap impor meninggalkan folder job tersembunyi. Halaman `__magic__` hanya menampilkan seribu baris pertama yang tersimpan. Rilis yang kamu cari biasanya tidak ada di daftar itu, jadi tombol Unhide dan Reset-nya tidak bisa dijangkau. Catatan di bawah daftar malah menunjuk ke data/magic.json.

Mengedit file itu saat zurg berjalan tidak akan berhasil. zurg akan menulisnya ulang dari memori saat berhenti, jadi barisnya akan muncul lagi setelah restart.

Baris yang tersimpan dan halaman yang menggantung sekarang punya kotak pencarian. Ketik nama rilis, path dari mount kamu, atau hash. Setiap baris yang tersimpan tentang rilis itu akan ditampilkan lengkap dengan tombolnya, berapa pun besar tabelnya.

Ini juga cara mengembalikan rilis yang ada di `__all__` tapi tidak pernah muncul di `__magic__/__all__.` Menghapus rilis lalu menambahkannya lagi, atau memasukkannya ulang dari DMM, tetap menjaga hash-nya. Jadi rilis itu kembali dengan semua yang pernah disimpan `__magic__` tentangnya, termasuk folder job yang dihapus setelah impornya. Cari rilisnya, lalu tekan Unhide pada baris release-tombstone-nya.

## `__magic__` di Windows berhenti menambah journal-nya selamanya {#__magic__-on-windows-stops-growing-its-journal-forever}

On Windows, zurg logged `cannot truncate data\magic.journal ... Access is
denied.` every time it tried to tidy the file where `__magic__` records your
moves and folders. The file was never emptied, so it grew with every change
and every start read all of it again. After a few thousand changes in one run,
each further change also rewrote the whole saved layout. zurg now empties it
on Windows as it always did elsewhere, and the first start after updating
clears what has piled up. If tidying ever fails, zurg tries again after more
changes instead of on every one.

## Memulihkan file lewat MCP langsung mengembalikan rilisnya {#restoring-a-file-over-mcp-puts-its-release-back-right-away}

Memulihkan file dengan MCP tool `zurg_release_file_restore` dulu membawa file kembali, tetapi rilisnya tetap ditandai rusak dan masih berada di `__unplayable__` sampai library di-refresh berikutnya. Sekarang tool ini melakukan hal yang sama seperti tombol Restore di torrent manager: rilis keluar dari `__unplayable__`, kembali ke folder-nya beserta file .strm-nya, dan disimpan dalam kondisi itu. Seperti sebelumnya, tool ini tidak meminta Plex, Jellyfin, atau script on_library_update Anda untuk melakukan rescan.

## Kembalikan file yang disembunyikan oleh repair yang gagal {#bring-back-files-a-failed-repair-hid}

Build lama menandai file sebagai terhapus saat perbaikan menyerah pada satu akun, bahkan ketika akun lain masih bisa memutarnya, dan rilis itu lalu hilang dari setiap folder. Torrent manager sekarang punya filter baru "Deleted, still served" yang menampilkan rilis yang tidak punya apa pun lagi untuk diputar, tetapi file terhapusnya masih disajikan oleh sebuah akun. Tahan tombol Restore dan zurg akan memeriksa tautan setiap file, lalu memasukkan file yang bisa diputar kembali ke foldernya, sama seperti menekan Restore pada setiap file.

zurg tidak melakukan ini dengan sendirinya. File yang sengaja Anda hapus disimpan dengan cara yang persis sama, jadi lihat daftarnya dan pulihkan hanya yang tidak Anda hapus. Rilis yang masih memutar sesuatu tidak dimasukkan ke daftar, karena menghapus extra atau episode biasanya memang penghapusan yang disengaja.

## Acquisition mencari melewati halaman pertama hasil pencarian {#acquisition-looks-past-the-first-page-of-search-results}

Dulu, akuisisi hanya membaca halaman pertama yang dikembalikan indexer. Dengan DMM, yang mengembalikan sepuluh hasil per halaman dengan yang terbesar di depan, batas ukuran bisa menyingkirkan semua hasil itu, dan film gagal dengan "no eligible releases" setiap beberapa jam, padahal rilis yang lebih kecil ada di halaman berikutnya. Sekarang akuisisi terus meminta halaman lain sampai mendapatkan cukup rilis yang sesuai dengan batas Anda, hingga sepuluh halaman. Untuk serial, episode yang tidak ditemukan oleh pencarian musim, biasanya episode yang lebih lama saat episode terbaru memenuhi hasil, sekarang akan dicari secara terpisah.

## File mati di folder film dan acara `__magic__` kini dikeluarkan agar Radarr dan Sonarr menyadarinya {#dead-files-in-__magic__-movie-and-show-folders-now-drop-out-so-radarr-and-sonarr-notice}

A file that Radarr or Sonarr had imported into a folder under `__magic__` kept showing at its full size after the release stopped working, so a rescan still saw it and the movie or episode never went back to wanted. It now leaves the folder at the same moment it leaves every other listing: once repair can no longer bring it back, or a day after it broke when repair is off. The next rescan marks it missing and acquisition looks for a replacement. If the file starts working again it reappears in the same place.

## Season Fix mengurutkan paket multi-musim dan extras bernomor {#season-fix-sorts-multi-season-packs-and-numbered-extras}

Season Fix sekarang membaca sendiri season yang disebut di setiap file, jadi pack seperti
`Full Metal Panic S2 - 01`, `Bakuman II - 01`, `KonoSuba 2 - 01` atau
`Demon Slayer Mugen Train Arc - 01` akan menempatkan setiap episode di season-nya sendiri, bukan membiarkan Plex menumpuk semuanya di season 1. Batch yang dinamai dalam romaji atau dengan akhiran, seperti `Sergeant Keroro 001-358` atau
`Dragon Ball Z COMPLETE`, dikenali saat file-filenya berbagi judul yang sama. Nama dengan underscore, `Ep01`, `1.01.` atau angka di dalam judul episode juga dibaca sesuai maksudnya.

Extra bernomor seperti `Special 01`, `OVA 01`, `- 11 (OVA)` dan ringkasan `24.5` dulu menempel pada episode asli sebagai versi kedua, dan Play bisa memilih extra itu. Sekarang namanya diberi akhiran `-other` dari Plex agar muncul sebagai extra.

## Tautan Real-Debrid yang mati tidak lagi menahan pemindaian library selama beberapa menit {#a-dead-real-debrid-link-no-longer-holds-a-library-scan-for-minutes}

Ketika Real-Debrid terus membalas sebuah file dengan link yang sama yang sudah dicabut, zurg menunggu beberapa menit, karena itu normal tepat setelah unduhan dihapus. File yang masih ditolak dengan cara itu setelah lima menit sekarang dianggap sebagai link rusak dan dikirim ke repair, alih-alih meminta pembaca untuk datang kembali nanti. Sebelumnya, satu file yang mati bisa menahan pemindaian Plex selama sekitar sepuluh menit.

## Job Usenet yang gagal dan macet bisa dibersihkan dari halaman `__magic__` {#failed-and-stuck-usenet-jobs-can-be-cleared-from-the-__magic__-page}

Pekerjaan Failed atau Stuck di daftar SABnzbd tetap ada selamanya setelah Sonarr atau Radarr berhenti menggunakan zurg sebagai download client. Restart tidak menghapusnya. Satu-satunya cara adalah menghapus `data/sabnzbd-jobs.json` secara manual. Sekarang halaman `__magic__` punya tombol **Clear** di setiap pekerjaan Failed atau Stuck, dan tombol di atas daftar untuk menghapus semuanya sekaligus. Tahan tombolnya sampai bilahnya penuh. Pekerjaan Queued dan Completed tidak akan disentuh. NZB milik pekerjaan tersebut juga akan dihapus, kecuali jika ada impor di bawah `__magic__` yang masih memakai rilis itu.

## Addon Stremio memberi tahu bahwa ia butuh https {#the-stremio-addon-says-when-it-needs-https}

Stremio hanya memuat addon lewat http di komputer tempat Stremio berjalan. Di TV, ponsel, atau komputer lain, alamat http akan gagal dengan "failed to load manifest" meskipun perangkat tersebut bisa menjangkau zurg. Halaman konfigurasi sekarang menampilkan pemberitahuan tentang hal ini di samping URL addon setiap kali Anda membukanya lewat http pada alamat seperti itu. Panduan Stremio menunjukkan tiga cara untuk memasang zurg di belakang https. Ketiganya adalah Tailscale Serve, reverse proxy Anda sendiri, dan Cloudflare tunnel.

## Plex langsung mendeteksi film atau episode begitu Radarr atau Sonarr mengimpornya ke `__magic__` {#plex-picks-up-a-movie-or-episode-as-soon-as-radarr-or-sonarr-imports-it-into-__magic__}

Setelah Radarr atau Sonarr memindahkan file ke folder di bawah `__magic__`, zurg meminta Plex untuk memindai file itu sendiri. Plex hanya memindai folder, jadi Plex menjawab seolah semuanya baik-baik saja dan tidak menambahkan apa pun, dan film tersebut tetap hilang sampai jadwal pemindaian Plex berikutnya. Sekarang zurg meminta Plex untuk memindai folder tempat file itu berada. Hal yang sama berlaku untuk file yang digantikan oleh upgrade, sehingga versi lama ikut hilang, dan untuk endpoint pemindaian manual, tool MCP `zurg_plex_scan_releases`, pemindaian setelah rename atau penghapusan file, serta path yang diberikan ke `on_library_update`.

## Halaman Manage mencantumkan rilis duplikat dan mana yang dipakai Radarr atau Sonarr {#the-manage-page-lists-duplicate-releases-and-which-one-radarr-or-sonarr-uses}

Upgrade membiarkan rilisan yang digantikannya tetap ada di library kamu, dan grab dari
indexer yang berbeda bisa membuat lebih dari satu salinan film atau season. Tampilan baru
Duplicates di halaman Manage mengelompokkan rilisan yang berisi film atau episode yang sama, dan
menunjukkan rilisan mana yang sedang dipakai Radarr atau Sonarr. zurg mencari tahu itu dari lokasi
file di `__magic__`, bukan dari nama rilisnya.

Untuk season, zurg menampilkan setiap episode yang dimiliki lebih dari satu rilisan dan
rilisan mana tempat file Sonarr berada. Jadi, pack yang hanya diambil beberapa episode oleh Sonarr
tetap ditandai sebagai sedang dipakai. Rilisan lainnya ditandai "No reference found" atau
"Unknown", beserta alasannya. Pilih yang ingin kamu hapus, lalu zurg membaca ulang Radarr dan Sonarr
sebelum menghapus, dan melewatkan apa pun yang sudah mulai dipakai sejak tadi. Tidak ada yang pernah
dihapus secara otomatis.

## Slot unduhan TorBox yang sibuk dihitung sesuai cara TorBox menghitungnya {#torboxs-busy-download-slots-are-counted-the-way-torbox-counts-them}

Sebelum repair atau pemutaran pertama menambahkan torrent ke TorBox, zurg memeriksa apakah akun masih punya slot unduhan yang kosong. Dulu zurg menghitung semua torrent yang belum selesai diunduh sepenuhnya. Akibatnya, torrent yang sedang seeding terlewat, padahal TorBox menghitungnya sebagai slot di paket kamu selama hingga 30 hari. Sebaliknya, torrent yang kontennya sudah kedaluwarsa ikut terhitung, padahal torrent seperti itu tidak memakai slot sama sekali. Beberapa torrent kedaluwarsa di dalam library saja sudah bisa membuat repair menunggu seolah-olah semua slot sedang terpakai.
zurg sekarang hanya menghitung torrent yang oleh TorBox ditandai sebagai aktif.

## TorBox bisa melakukan seeding untuk private tracker {#torbox-can-seed-for-private-trackers}

A new setting, `tb_seed_torrents`, decides whether the torrents zurg adds to TorBox seed. It stays at `never` unless you change it, so nothing changes for anyone who leaves it alone. Set it to `always` if a private tracker needs your ratio, or to `auto` to let the seeding setting on your TorBox account decide. It can be changed from the dashboard's Health & Repairs section and takes effect on the next add.

Torrent yang sedang di-seed memakai salah satu slot aktif paket TorBox Anda selama masih di-seed, sampai 30 hari di Pro. Jika torrent yang di-seed memenuhi semua slot, unduhan baru dan perbaikan di akun itu harus menunggu sampai ada slot yang kosong.

## Set RAR yang volumenya bernama tidak berurutan kini bisa diputar {#rar-sets-whose-volumes-are-named-out-of-order-now-play}

Rilis yang setiap volume RAR-nya punya nama berbeda, misalnya nama acak per volume atau `Movie 2026 part1.rar`, dulu muncul sebagai satu arsip per volume. Yang pertama menampilkan film-nya, tapi berhenti bekerja setelah bagian pertama, dan yang lain tidak menampilkan apa-apa. Sekarang zurg membaca di dalam volume itu sendiri di mana posisi volume tersebut, lalu menyusun kembali setnya. Dulu kamu harus memperbaikinya sendiri dengan mengganti nama volume menjadi `part001.rar` dan seterusnya. Perbaikan ini hanya berjalan jika volume-volumenya bernomor dan membentuk satu set yang lengkap. Jika ada yang hilang atau dua volume mengklaim posisi yang sama, rilis dibiarkan seperti semula dan log menjelaskan alasannya. Arsip terkompresi yang volume-nya diunggah tidak berurutan juga sekarang bisa diputar.

## Pemindaian Plex yang masih melakukan analysing tidak lagi dilaporkan macet {#a-plex-scan-that-is-still-analysing-is-no-longer-reported-as-stuck}

Plex menjaga progres dan folder saat ini tetap tidak berubah selama ia menganalisis file yang ditemukan oleh pemindaian, dan proses ini bisa memakan waktu lama pada pustaka yang besar atau remote. Dulu dasbor menyebut kondisi itu sebagai pemindaian macet dan menyarankan untuk me-restart Plex di tengah proses. Sekarang zurg mendengarkan feed pembaruan milik Plex sendiri dan menghitung item yang masih dikerjakan oleh Plex, jadi hanya pemindaian yang benar-benar berhenti yang akan ditandai.

## Unggahan torrent yang hanya cached mempertahankan penolakan add pada provider dengan pembatasan laju {#cached-only-torrent-uploads-preserve-the-refusing-add-on-rate-paced-providers}

Sebuah `.torrent` yang dikirim dalam mode cached-only sekarang sampai ke TorBox dan ditolak saat ditambahkan, meskipun batas tambah per jam membungkus backend. Miss uncached tidak membuat transfer dan tidak memakan slot aktif; tetap saja, miss itu menghabiskan salah satu dari 60 add uncached TorBox per jam. Add biasa tetap mengunggah file asli.
Panduan qBittorrent sekarang mencantumkan keenam provider unggah torrent dan menjelaskan jalur cached-only Debrid-Link dan TorBox yang berbeda.

## File yang kamu hapus saat sedang dipulihkan tetap terhapus {#a-file-you-delete-while-it-is-being-restored-stays-deleted}

Menghapus file atau rilis saat restore masih memeriksa tautannya sekarang akan menunggu pemeriksaan itu selesai lalu menang. Refresh library yang sudah berjalan tidak lagi bisa memunculkan kembali rilis yang baru saja kamu hapus.

## Pencarian jauh ke dalam arsip terkompresi tidak lagi membuat pembaca macet {#a-seek-far-into-a-compressed-archive-no-longer-hangs-the-reader}

A file di dalam RAR atau zip yang terkompresi hanya bisa di-decode dari awal,
jadi pembacaan di dekat akhir file yang besar dulu harus menunggu seluruh arsip
tanpa balasan sama sekali. Plex bisa menunggu pembacaan seperti itu lebih dari
satu jam, dan itu cukup untuk membuat database-nya terkunci. Sekarang zurg
membalas dalam 20 detik, tetap menyimpan progres yang sudah dicapai, dan
menyiapkan bagian akhir file di latar belakang supaya pembacaan berikutnya
langsung cepat.

## Penolakan Real-Debrid mengikuti aturan nama file yang dipublikasikan {#real-debrid-refusals-follow-the-published-filename-rules}

Ketika Real-Debrid menolak menambahkan ulang sebuah rilis saat repair, zurg sekarang memeriksa nama rilis dan nama file-file di dalamnya terhadap aturan penamaan file yang dipublikasikan. Rilis yang diblokir oleh aturan tersebut ditandai sebagai infringing secara permanen. Penolakan lain akan dianggap sebagai Real-Debrid memperlambat penambahan, dan rilis tetap masuk antrean untuk putaran repair berikutnya, alih-alih dihapus.

## Memulihkan file langsung mengembalikannya ke tempat semula {#restoring-a-file-puts-it-back-where-it-belongs-straight-away}

Tindakan Restore di halaman manage sebuah release sekarang memindahkan release itu kembali ke direktorinya, menyimpan status yang dipulihkan, dan langsung menulis file STRM-nya begitu file tersebut lolos pengecekan. File yang sudah dipulihkan tidak lagi tertahan di direktori unplayable sampai refresh provider berikutnya, dan release yang file rusak terakhirnya sudah dipulihkan tidak lagi dilaporkan rusak setelah restart. File yang Anda hapus tetap terhapus sampai Anda memulihkannya.

## Tolak artikel Usenet asing sebelum mengirim byte {#reject-foreign-usenet-articles-before-serving-bytes}

Tolak artikel Usenet dengan nomor yang sama yang total yEnc positifnya lebih kecil dari nomor tertinggi yang tercantum di NZB, termasuk cache yang tersimpan dan jalur progresif, supaya fallback akun yang valid menyediakan byte-nya.

## Pertahankan klasifikasi penolakan RD yang berbasis bukti {#preserve-evidence-backed-rd-refusal-classification}

Jangan tampilkan respons addMagnet 451 sebagai penolakan rilis kecuali ada bukti throttle khusus akun yang mencakup seluruh operasi, dan pertahankan error sementara selama perbaikan.

## Perjelas jendela baca file rusak yang sudah kedaluwarsa {#clarify-expired-broken-file-read-windows}

Laporkan jendela percobaan ulang pembacaan file rusak yang sudah kedaluwarsa, tanpa mengklaim bahwa perbaikan sudah menyerah.

## Tampilkan kesehatan file yang tercatat di MCP {#expose-recorded-file-health-in-mcp}

Tampilkan jumlah kesehatan per file yang sudah tercatat di tampilan rilis MCP, dan buat tabel file yang dimuat secara lazy tetap aman untuk diperiksa tanpa mengklaim bahwa sebuah status lifecycle adalah probe penyajian langsung.

## Tangani operasi sidecar duplikat {#handle-duplicate-sidecar-operations}

Kenali respons "missing source" yang bertipe dari alias WebDAV duplikat, sambil tetap mempertahankan error all-failed dan permission yang sebenarnya.

## Unduhan ulang dengan nama yang sama diperbaiki, bukan gagal {#a-re-grab-under-the-same-name-is-repaired-instead-of-failed}

Mengambil ulang NZB dengan nama yang sudah dipegang zurg tidak lagi memeriksa dan memperbaiki salinan lama selagi salinan baru sedang dibaca. Pengambilan menunggu file baru, jadi rilis dengan artikel yang hilang yang bisa dibangun ulang oleh PAR2 akan diperbaiki dan diselesaikan, bukan dilaporkan gagal.

## Kegagalan perbaikan tidak lagi disangka sebagai penghapusan oleh pengguna {#repair-failures-no-longer-masquerade-as-user-deletions}

Kegagalan perbaikan otomatis sekarang hanya menandai sumber provider yang gagal sebagai rusak, sehingga salinan alternatif yang sehat tetap dipertahankan dan refresh provider berikutnya bisa mengembalikan visibilitas file.

## Torrent tanpa IMDb id diidentifikasi berdasarkan nama rilis lewat DMM {#torrents-without-an-imdb-id-are-identified-by-release-name-through-dmm}

Dengan `dmm_metadata_secret` diatur, job IMDb tidak lagi membutuhkan kunci OpenSubtitles. Torrent yang tidak punya id, atau hanya punya penanda miss dari OpenSubtitles, akan diidentifikasi saat startup dari tag `imdb-tt…` di namanya. Kalau tidak ada, resolver DMM yang akan mencoba, dan resolver ini hanya menjawab kalau satu judul cocok persis. Romanisasi fansub seperti "Kaijuu 8-gou" dicocokkan lewat alias DMM ke Kaiju No. 8, sedangkan nama yang dipakai bersama oleh beberapa serial dibiarkan saja. Torrent yang tidak bisa dinamai oleh DMM tetap punya id kosong, jadi pencocokan di Plex masih bisa mengisinya.

## Film Radarr yang tidak dikenali indexer mana pun berdasarkan id dicari berdasarkan nama {#a-radarr-movie-that-no-indexer-knows-by-id-is-searched-for-by-name}

Banyak post Usenet diindeks tanpa ID IMDb atau TMDB. zurg mencari film Radarr hanya
berdasarkan id, jadi dokumenter yang tidak ada indexer pun memberi hasil untuk
id-nya gagal dengan "no eligible releases", padahal pencarian Radarr sendiri
berdasarkan nama menemukan rilis yang bersih. Sekarang, kalau pencarian id tidak
menemukan apa pun untuk diambil, zurg juga mencari berdasarkan judul dan tahun.
Parser Radarr sendiri tetap memutuskan apakah tiap hasil memang film tersebut.
Pencarian berdasarkan nama hanya dilakukan kalau pencarian id sama sekali tidak
menemukan apa-apa. Film yang ditemukan pencarian id akan diindeks berdasarkan id,
dan meminta lagi berdasarkan nama hanya akan mengambil post yang sama.

## NZB yang ditemukan lewat Prowlarr dapat diunduh {#nzbs-found-through-prowlarr-can-be-downloaded}

Prowlarr menyerahkan setiap NZB Usenet dengan redirect ke indexer, dan opsi ini tidak bisa dimatikan. Dulu zurg hanya mengikuti redirect ke host yang sama, jadi untuk indexer yang diatur lewat Prowlarr, setiap akuisisi NZB gagal dengan pesan "answered 301 Moved Permanently" dan tidak ada yang berhasil diambil. Sekarang redirect tersebut sudah diikuti. API key milik link tetap tidak pernah dikirim ke host lain, dan redirect dari HTTPS ke HTTP biasa tetap ditolak.

## Indexer yang menolak selama berjam-jam tidak lagi menghambat akuisisi {#an-indexer-that-refuses-for-hours-no-longer-stalls-acquisition}

Prowlarr menjawab pencarian pada indexer yang sudah dinonaktifkan dengan `429` dan `Retry-After` berisi beberapa jam. zurg menunggu dua menit lalu bertanya lagi, tiga kali, jadi setiap pencarian menghabiskan enam menit hanya untuk indexer itu. Proses acquisition menyerah pada setiap judul setelah lima kali percobaan, dan membuang semua hasil yang sudah dijawab indexer lain, jadi tidak ada yang berhasil diambil sama sekali sampai indexer itu kembali. Sekarang, indexer yang meminta dibiarkan lebih dari dua menit akan dilewati sampai waktu yang disebutkannya, dan pencarian tetap berjalan di indexer lainnya.

## Judul yang dihapus setelah akuisisi dicari lagi {#a-title-deleted-after-acquisition-is-searched-for-again}

Ketika file yang diambil zurg untuk Sonarr atau Radarr dihapus, baik karena bukan versi yang diinginkan maupun karena alasan lain, dan judulnya muncul lagi di daftar yang hilang, zurg menjawab "completed without a search, the release was already held" lalu tidak pernah mencarinya lagi. Sekarang zurg memeriksa folder season atau film di `__magic__` dulu. Episode atau film yang videonya sudah tidak ada akan dicari lagi. Yang videonya masih ada, yang terjadi selama Sonarr belum melakukan rescan, akan dibiarkan saja.

## "Scan in Plex" pada daftar yang tidak terdeteksi menunggu hasilnya {#scan-in-plex-on-the-undetected-list-waits-for-the-result}

Tombol hold-to-scan di daftar undetected dulu memuat ulang halaman dua detik setelah ditekan, padahal pencocokan dengan Plex belum mulai. Di library besar, pencocokan itu butuh beberapa menit, jadi daftarnya selalu kembali tanpa perubahan dan tombolnya kelihatan tidak melakukan apa-apa. Sekarang tombolnya menampilkan bahwa pencocokan sedang berjalan, menunggu sampai selesai, memberi tahu berapa banyak release yang berhasil dicocokkan, lalu memuat ulang halaman.

## Rilis yang namanya diakhiri spasi kini cocok dengan Plex {#a-release-whose-name-ends-in-a-space-is-matched-to-plex}

A release whose file name has a space before the extension, such as
`... [Hurtom] v2 .mkv`, gets a directory whose name ends in a space. Plex found
it, tetapi zurg tidak pernah bisa mencocokkannya, sehingga file itu tetap ada di daftar undetected setelah setiap scan. Sekarang sudah cocok.

## Menghapus file di halaman manage membuat posisi Anda tetap {#deleting-a-file-on-the-manage-page-keeps-your-place}

Menghapus, memulihkan, mengganti nama, atau menampilkan paksa satu file di halaman manage sebuah rilis dulu membuat halaman dimuat ulang dari atas, jadi saat merapikan paket besar kamu harus scroll lagi ke bawah setiap selesai klik. Sekarang halaman kembali ke baris file tersebut dan menyorotnya.

## Dasbor menerima path mount yang diketik dengan tanda kutip {#the-dashboard-takes-a-mount-path-typed-with-quotes}

Jalur mount yang ditempel ke dashboard persis seperti yang ditulis config.yml, misalnya `"/Users/me/Plex Media Server/ZurgMount"` atau `'Z:\'`, ditolak dengan pesan "mount path should be absolute" karena tanda kutipnya dibaca sebagai bagian dari jalur. Sekarang dashboard otomatis menghapus sepasang tanda kutip yang cocok di sekitar nilai tersebut, lalu menyimpan jalurnya tanpa tanda kutip.

## Pengambilan watchlist Plex yang gagal menjelaskan penyebabnya {#a-failed-plex-watchlist-fetch-says-why}

Saat Plex menolak permintaan watchlist, log sekarang menampilkan alasan dari Plex sendiri, misalnya `unexpected status: 401: Invalid token`, bukan hanya status-nya. Kalau kamu masih melihat `Failed to fetch watchlist: ... unexpected status: 400`, tulisan itu berasal dari build yang lebih lama dari Agustus. Perbarui zurg: build terbaru meminta watchlist dalam halaman-halaman yang diterima Plex.

## Rilis yang terlalu rusak untuk memori perbaikan langsung gagal {#a-release-too-damaged-for-repairs-memory-fails-at-once}

Ketika sebuah rilis Usenet kehilangan lebih banyak data daripada yang bisa ditangani PAR2 untuk diperbaiki sekaligus di memori, zurg sekarang memberi tahu hal itu lalu berhenti, dan Sonarr atau Radarr memilih rilis lain. Dulu, zurg menahan grab tetap menunggu, lalu mencoba lagi setiap beberapa menit, dan memeriksa ulang seluruh rilis setiap kali untuk mendapatkan jawaban yang sama. Kerusakan yang belum dipastikan hilang, seperti artikel yang tidak dijawab oleh server, tetap dicoba ulang.

## Setup melewati konfigurasi kosong dan memberi tahu kapan prompt token disembunyikan {#setup-gets-past-an-empty-config-and-says-when-the-token-prompt-is-hidden}

`zurg setup`, dan installer yang menjalankannya, menolak lanjut selama file `config.yml` kosong masih ada, dengan error yang berakhir tanpa keterangan apa-apa. Config yang kosong sekarang otomatis diganti. Config yang sudah ada isinya tetap tidak akan pernah ditimpa, dan error-nya sekarang menyebutkan file mana yang dimaksud dan cara mulai dari awal. Prompt token sekarang memberi tahu bahwa apa yang kamu ketik atau tempel akan tetap tersembunyi. Sebelumnya, hal ini terlihat seperti terminal menolak input. Typo di `config.yml` sekarang dilaporkan sebagai error di `config.yml`, bukan "outbound identity config" yang bersifat internal.

## Server berita cadangan kini mengisi artikel yang salah dijawab server utama {#a-backup-news-server-now-fills-in-articles-the-main-server-answers-wrongly}

Beberapa news server menjawab permintaan untuk satu artikel dengan potongan dari upload yang berbeda. zurg mengenali potongan yang salah itu, tetapi tidak pernah meminta server cadangan untuk potongan yang benar, sehingga bagian yang hilang diputar sebagai senyap atau file tidak bisa dibuka, meskipun server cadangan punya datanya. Sekarang zurg meminta ke server berikutnya, seperti yang dilakukan SABnzbd.

## Rilis Usenet berformat RAR masuk ke direktorinya tanpa perlu restart {#a-rard-usenet-release-reaches-its-directory-without-a-restart}

Sebuah rilis yang diposting sebagai set RAR dikelompokkan ke dalam direktori berdasarkan nama volumenya sampai arsipnya dibuka, dan setelah itu berdasarkan file di dalamnya. Tidak ada yang mengelompokkannya ulang setelah arsip dibuka, jadi direktori yang mencari `.mkv` atau nomor episode melewatkan rilis RAR yang baru diambil sampai zurg dimulai ulang, dan Plex serta Jellyfin tidak pernah melihatnya di sana. Sekarang rilis itu langsung pindah ke direktori yang tepat begitu arsipnya pertama kali didaftar.

## Film yang diposting dengan nama acak diberi nama sesuai rilisnya {#a-movie-posted-under-a-random-name-is-named-after-its-release}

Beberapa posting Usenet memberi film nama acak, misalnya `eq5KVi5Y3iTwFEn1Nub8yPY9yd6oUzTu.mkv`, dan mengulangi nama itu di mana saja dalam posting yang bisa memuat nama asli. zurg dulu mempertahankan nama itu, sehingga Radarr dan Sonarr tidak punya apa pun di nama file untuk dijadikan acuan. Sekarang zurg memberi nama file sesuai rilisnya, seperti yang dilakukan SABnzbd: hanya jika file tersebut jelas merupakan satu-satunya file besar dari rilis, hanya untuk file video, dan tidak pernah untuk struktur disc atau arsip. Ini berlaku untuk rilis yang diambil mulai sekarang; yang sudah ada di library tetap memakai namanya.

## Aturan ukuran kini berlaku untuk file di dalam arsip {#size-rules-now-apply-to-files-inside-archives}

Film Usenet yang diposting sebagai set RAR ditampilkan sebagai file-file yang ada di dalam arsip.
File-file itu melewati pengaturan `only_show_the_biggest_file` dan
`only_show_files_with_size_gte`/`_lte` pada sebuah direktori, jadi file lain yang ikut di dalam postingan tetap terlihat di samping film. Banyak postingan menyertakan gambar kecil yang dinamai sesuai judul film, lembar tangkapan layar berstempel waktu, dan Jellyfin memakainya sebagai poster. Pengaturan ukuran sekarang berlaku untuk isi arsip dengan cara yang sama seperti untuk file lainnya.

## Rilis Usenet yang file PAR2 terbesarnya lebih dari 512 MB kini bisa diperbaiki {#usenet-releases-whose-largest-par2-file-is-over-512-mb-can-be-repaired}

Ketika sebuah rilis kekurangan potongan, zurg membangunnya kembali dari file PAR2 milik rilis itu sendiri. Dulu zurg menolak membaca file PAR2 yang lebih besar dari 512 MB, padahal pada rilis besar file itu menyimpan lebih banyak data perbaikan dibanding file lain, dan sering kali itu satu-satunya file yang ada. Rilis seperti itu tidak bisa diperbaiki seberapa pun sedikit bagian yang hilang, dan zurg terus mencoba lagi, mengunduh semua file PAR2 yang lebih kecil setiap kali sebelum akhirnya menyerah. Sekarang zurg bisa membaca file PAR2 dengan ukuran berapa pun.

Rilis yang kerusakannya lebih besar dari yang bisa ditampung satu perbaikan di memori langsung ditolak begitu kerusakannya dihitung, sebelum file PAR2 mana pun diunduh.

## Sonarr dapat menyerahkan episode yang hilang ke zurg {#sonarr-can-hand-its-missing-episodes-to-zurg}

zurg sekarang bisa mengambil daftar dari Sonarr juga. Tambahkan source `sonarr` di bawah `acquisition.sources` dengan URL dan API key Sonarr. zurg lalu mengerjakan episode yang belum ada di Sonarr dan file episode yang ingin di-upgrade. Ia mencari di indexer kamu dan memeriksa apakah news server masih menyimpan release tersebut. Setiap episode ditaruh di folder season-nya di dalam `__magic__`, lalu zurg meminta Sonarr untuk memindai ulang series-nya. Untuk cara ini, Sonarr tidak perlu indexer atau download client.

Satu season yang belum ada sama sekali dan sudah selesai tayang bisa diambil sebagai satu season pack. Selain itu, prosesnya dilakukan episode per episode. Setiap release lebih dulu dicek oleh parser Sonarr sendiri. Release harus cocok dengan series dan episode yang benar, serta sesuai dengan quality profile series tersebut. Upgrade hanya mengganti episode yang di-upgrade. Jika satu episode dalam season belum punya release, episode lain tetap ditaruh dan Sonarr dipindai ulang untuk episode-episode itu. Series harian dan anime dilewati untuk sementara, dengan catatan di log. Untuk sisi Sonarr dalam setup ini, lihat `docs/acquisition.md`.

## Akuisisi bekerja pada banyak judul sekaligus {#acquisition-works-on-many-titles-at-once}

Judul dari daftar tontonan atau layanan permintaan dulu diambil satu per satu, jadi daftar panjang butuh waktu sama dengan jumlah semua judulnya. Sekarang zurg mengerjakan hingga delapan judul sekaligus, diatur lewat `acquisition.concurrency`. Judul yang muncul belakangan di daftar tidak lagi menunggu judul-judul di depannya selesai.

Rilis baru tidak lagi menunggu dua menit sebelum zurg memeriksanya. zurg memeriksa setiap detik sampai rilis itu muncul di pustaka, selama maksimal satu setengah menit. Ketika server berita tidak lagi menyimpan sebuah rilis, zurg langsung lanjut ke kandidat berikutnya, bukan mencoba lagi lima menit kemudian. Memeriksa sebuah rilis juga tidak lagi harus muat di sisa waktu pencarian, jadi pencarian yang lambat pada daftar panjang tidak lagi menunda judul hingga beberapa menit. Peningkatan kualitas untuk judul yang sudah ada menunggu sampai judul yang belum ada dari daftar yang sama selesai, sehingga keduanya tidak pernah berebut panggilan indexer atau koneksi server berita.

## Rilis Usenet yang diperbaiki dengan PAR2 tetap diperbaiki selama dibaca {#a-usenet-release-repaired-with-par2-stays-repaired-while-it-is-read}

Saat beberapa artikel dari sebuah release hilang dari news server, zurg membangunnya kembali dari file PAR2 milik release tersebut, lalu menyajikan byte hasil rekonstruksi itu. Bagian zurg yang mengambil data lebih dulu sebelum diputar tidak tahu soal potongan hasil rekonstruksi, jadi ia kembali meminta artikel yang hilang ke server. Artikelnya memang masih hilang, dan zurg melaporkan release itu rusak lagi, padahal semua byte yang disajikannya sudah benar. Release yang diperbaiki saat proses impor bisa gagal beberapa saat kemudian, dan klien unduh akan membuang salinan yang bagus lalu mengambil yang lain. Sekarang zurg tidak lagi meminta apa pun ke server untuk data yang sudah ia bangun ulang.

## Radarr dapat menyerahkan film yang diinginkan ke zurg {#radarr-can-hand-its-wanted-movies-to-zurg}

zurg sekarang bisa mengambil daftarnya dari Radarr. Tambahkan sumber `radarr` di bawah `acquisition.sources` dengan URL dan API key Radarr, lalu zurg akan mengerjakan film-film yang belum ada di Radarr atau yang ingin di-upgrade. Ia mencari di indexer kamu, mengecek apakah news server masih menyimpan release tersebut, menaruh file video di folder film itu di dalam `__magic__`, lalu meminta Radarr untuk rescan film tersebut. Untuk cara ini, Radarr tidak perlu indexer atau download client.

Setiap release yang diambil zurg sudah lebih dulu lewat parser milik Radarr sendiri, jadi dipastikan filmnya benar dan sesuai dengan quality profile: kualitas yang diizinkan, skor custom format minimum, batas ukuran, dan upgrade hanya ke arah cutoff. zurg memilih release pertama yang diizinkan dan paling cepat dicek, dengan web release didahulukan, dan membiarkan kualitas yang menjadi preferensi profile untuk upgrade berikutnya. zurg hanya bertanya ke Radarr tentang sebuah release saat akan mengeceknya, satu per satu, dan tidak pernah bertanya tentang release yang judulnya menyebut resolusi yang tidak ada kualitasnya di profile. Jadi, untuk sebagian besar film, Radarr yang sedang sibuk hanya perlu menjawab satu sampai tiga pertanyaan, bukan satu untuk setiap hasil pencarian.

Jika Radarr melihat mount zurg di path yang berbeda, atur `library_path` ke lokasi tempat Radarr melihat `__magic__`. Halaman Acquisition baru di dashboard menampilkan setiap judul yang sedang dikerjakan zurg, apa yang sedang dilakukannya sekarang, dan di mana setiap release ditempatkan. `docs/acquisition.md` berisi panduan setup untuk sisi Radarr.

## Akuisisi memilih rilis Usenet yang paling cepat dikonfirmasi {#acquisition-picks-the-usenet-release-that-is-quickest-to-confirm}

Saat zurg mengambil sebuah film, sekarang ia pertama-tama melihat postingan yang hanya berisi satu file video. Postingan jenis ini jauh lebih sering masih lengkap di news server, dan cukup dua kali pembacaan artikel untuk memastikannya. Sebelum menyimpan apa pun, zurg membaca NZB dari setiap kandidat. Ia menyimpan postingan single-video pertama yang ditemukan, dan baru mencoba set arsip multi-volume kalau tidak ada satu pun yang tersedia. Set yang paling kecil diambil lebih dulu, dan jumlahnya tidak lebih dari enam sekaligus. Hasil yang judulnya merujuk ke salah satu bagian dari postingan yang terpecah akan dilewati. Saat diuji dengan IMDb Top 100, cara memilih ini memangkas jumlah NZB yang harus diambil zurg dari 517 menjadi 156. Pencarian dan pengunduhan NZB sekarang berbagi satu batas permintaan yang sedang berjalan per indexer, dan zurg akan menunggu kalau indexer bilang sedang sibuk. Permintaan film tanpa quality profile di belakangnya tetap mendapatkan resolusi yang diminta lebih dulu. Akuisisi serial tidak berubah.

## Akuisisi memeriksa rilis begitu zurg mengetahui ukurannya {#acquisition-checks-a-release-once-zurg-knows-its-sizes}

zurg dulu memeriksa rilis baru dengan news server begitu rilis itu muncul
di library, sementara zurg juga masih membaca rilis yang sama untuk mengetahui
ukuran file-nya. Keduanya meminta artikel yang sama lewat koneksi yang sama, jadi
pada daftar yang panjang keduanya berjalan sangat lambat. Pada daftar 99 film, film
terakhir baru sampai ke Radarr setelah hampir sembilan menit. Sekarang zurg memeriksa
rilis setelah ukurannya diketahui, seperti yang sudah dilakukannya untuk Sonarr dan Radarr
lewat endpoint SABnzbd, memeriksa paling banyak enam rilis sekaligus, dan memakai ulang
artikel pertama yang sudah diunduh pemeriksaan ukuran jika artikel itu masih ada. Serangkaian rilis
yang disimpan sekarang menghasilkan satu kali refresh library, bukan satu kali per rilis.
Memeriksa rilis sekarang didahulukan dari pemeriksaan ukuran rilis lain, tetapi tidak
pernah mendahului pemutaran, dan akun dengan lebih dari dua belas koneksi sekarang
mempelajari ukuran hingga enam belas rilis sekaligus, bukan delapan.

## Rilis Usenet yang sudah diambil dengan beberapa potongan hilang diperbaiki sebelum dinyatakan gagal {#a-grabbed-usenet-release-with-a-few-missing-pieces-is-repaired-before-it-is-failed}

Sebelum memberi tahu Radarr atau Sonarr bahwa unduhan sudah selesai, zurg memeriksa dulu apakah potongan-potongan rilis tersebut masih ada di news server. Dulu, ketika pemeriksaan itu menemukan ada potongan yang hilang, zurg langsung menandai unduhan sebagai gagal, padahal file PAR2 dari rilis itu sebenarnya bisa memperbaiki potongan yang hilang. Radarr kemudian membuang rilis tersebut dan mencari rilis lain, yang sering kali kualitasnya lebih buruk. Sekarang zurg akan memperbaiki potongan yang hilang lebih dulu, dan baru melaporkan unduhan gagal jika cara itu tidak berhasil. Dalam seminggu penggunaan grab sungguhan, sebagian besar rilis yang gagal dengan cara ini ternyata punya file PAR2 yang sebenarnya bisa menyelamatkannya.

## Rilis Usenet yang rusak menunggu giliran perbaikan alih-alih langsung gagal {#damaged-usenet-releases-wait-their-turn-for-a-repair-instead-of-being-failed}

zurg memperbaiki paling banyak dua rilis yang rusak dalam satu waktu, dan satu perbaikan bisa memakan waktu dari beberapa menit sampai lebih dari satu jam. Unduhan rusak ketiga hanya punya waktu lima menit untuk mulai sebelum zurg memberi tahu Radarr atau Sonarr bahwa unduhan itu gagal, jadi ketika beberapa datang bersamaan, semua kecuali dua dibuang tanpa ada yang mencoba memperbaikinya, dan log tidak mencatat apa pun tentang itu. zurg sekarang menahan unduhan selama perbaikannya masih antre, sampai tiga jam, dan log akan memberi tahu saat sebuah perbaikan sedang menunggu gilirannya.

## Unduhan Usenet tidak lagi menunggu selamanya untuk ukuran file yang tidak akan pernah diketahui {#a-usenet-download-no-longer-waits-for-ever-on-file-sizes-nothing-is-going-to-learn}

zurg menahan unduhan yang sudah selesai dari Radarr dan Sonarr sampai tahu ukuran pasti tiap file, karena klien memeriksa ukuran saat impor. Setelah re-grab tertentu, zurg bisa berhenti mencoba mempelajari ukuran sambil tetap menunggu ukuran itu, sehingga unduhan terjebak di antrean sampai klien menyerah, sering kali dua jam kemudian. Sekarang zurg menghitung ulang ukuran rilis seperti itu, dan ketika tidak ada lagi cara untuk mendapatkan ukuran dan semua bagian rilis sudah ada di server berita, zurg memberi tahu klien bahwa unduhan sudah siap.

## Rilis Usenet yang penyebarnya hanya mengganti nama volume arsip pertama kini bisa diputar lagi {#usenet-releases-whose-poster-renamed-only-the-first-archive-volume-play-again}

Beberapa pengunggah mengganti nama volume pertama dari sebuah arsip dengan nama rilis dan membiarkan sisanya dengan nama aslinya, jadi sebuah rilis datang sebagai `Show.S02E03.part03.rar` ditambah `show.203.r00` sampai `show.203.r19`. zurg mengelompokkan volume berdasarkan nama, melihat dua arsip yang belum lengkap, dan tidak bisa membuka keduanya. Sekarang zurg membaca header volume pertama, mengenali volume mana saja yang seharusnya digabung dengannya, dan memberinya nama yang sesuai, jadi episode bisa diputar dan diimpor. Folder yang arsipnya memang kehilangan volume sekarang menampilkan pesan yang jelas, bukan error server yang umum.

## Rilis Usenet yang disamarkan dengan volume bernomor kini bisa diputar {#obfuscated-usenet-releases-whose-volumes-are-just-numbered-now-play}

Beberapa rilis menyembunyikan semua nama file di balik string acak dan sebuah angka, jadi sebuah film datang sebagai `f342c135….01`, `….02` dan seterusnya, dengan file teks dan sampul yang ikut bernomor di antaranya. zurg tidak mengenali ini sebagai bagian dari satu arsip, mencantumkannya sebagai file lepas, dan Radarr serta Sonarr tidak menemukan apa pun untuk diimpor. Sekarang zurg membaca awal setiap file bernomor, menggabungkan bagian-bagian arsip dengan urutan yang benar (bahkan ketika bagian pertama diunggah paling akhir), dan mengeluarkan file teks serta gambar dari arsip tersebut.

## NZB season pack di atas 32 MB kini diterima {#season-pack-nzbs-over-32-mb-are-accepted}

zurg menolak NZB yang lebih besar dari 32 MB yang dikirim lewat endpoint SABnzbd-nya, dengan jawaban "request body too large". NZB untuk season pack besar sering kali melebihi ukuran itu: sebuah season 526 GB datang sebagai NZB 49 MB. Sekarang zurg menerima NZB sampai 256 MB. NZB 49 MB dengan hampir setengah juta piece bisa dimuat dalam waktu kurang dari setengah menit.

## File dari posting Usenet yang dibungkus tetap mempertahankan nama aslinya {#files-from-wrapped-usenet-posts-keep-their-real-names}

Beberapa tool posting membungkus setiap nama file di subject line, seperti `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv]-[3/4]`, dan biasanya membiarkan nama file yang dikutip kosong. zurg dulu menyimpan pembungkus itu sebagai bagian dari nama, jadi episode tercantum sebagai `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv`, dan Sonarr serta media server tidak bisa mencocokkannya. Sekarang zurg mengambil nama file dari dalam pembungkus. Rilis yang sudah ada di library akan dibaca ulang sekali untuk mendapatkan nama yang sudah diperbaiki.

## Unduhan yang sudah dilaporkan gagal tidak lagi memakan slot perbaikan milik yang baru {#downloads-already-reported-failed-no-longer-take-repair-slots-from-new-ones}

Setelah zurg memberi tahu Radarr atau Sonarr bahwa unduhan gagal, klien akan membuangnya dan mencari yang lain. zurg tetap mencoba memperbaiki unduhan seperti itu setiap kali restart, dan perbaikan yang sia-sia ini bisa memakai kedua slot perbaikan sekaligus, sementara unduhan baru yang masih bisa diselamatkan harus menunggu. Sekarang zurg berhenti memperbaiki unduhan begitu ia sudah melaporkannya gagal.

## Laporan kerusakan menyebutkan setiap file {#damage-reports-name-every-file}

When a Usenet release was missing pieces, zurg's failure message listed the
damaged files by name, and a file the post itself never named showed up as a
blank: "across 4 file(s): , , , ". Such a file is now listed by its place in
the release, as in "file 12 of 73", so the message says which files are hit.

## Stremio melewati rilis yang videonya dimulai dengan kosong {#stremio-skips-a-release-whose-video-starts-with-nothing}

Ketika bagian awal video dari rilis Usenet sudah hilang dari news server, zurg mengisinya dengan keheningan dan menyerahkannya ke Stremio seolah-olah tidak ada masalah, jadi pemutar tidak menampilkan apa pun dan filmnya terlihat rusak. Sekarang zurg memeriksa byte-byte pertama sebelum memulai pemutaran. Jika tidak ada data asli di sana, zurg berpindah ke rilis berikutnya dalam daftar, sama seperti yang sudah dilakukannya untuk rilis yang tidak punya apa pun yang bisa diputar. Film yang punya celah di bagian tengah atau akhir tetap bisa diputar.

## File yang rusak tetap ada di library selama zurg masih akan mencobanya lagi {#broken-files-stay-in-the-library-while-zurg-will-still-retry-them}

Ketika zurg tidak bisa memperbaiki file yang rusak pada percobaan pertama, zurg langsung mengeluarkan file itu dari mount, padahal zurg masih akan mencoba lagi sehari kemudian. Plex membaca file yang hilang sebagai file yang sudah dihapus, sehingga satu kali pemindaian library bisa memindahkan episode, season, dan seluruh serial ke tempat sampah. Sekarang file yang rusak tetap berada di mount selama zurg masih berencana mencoba perbaikan lagi. File baru dikeluarkan ketika zurg yakin kontennya memang sudah tidak ada, misalnya saat layanan menolak rilis tersebut sepenuhnya atau tidak ada lagi yang bisa diputar di dalamnya.

## Radarr dan Sonarr mencari lagi saat rilis yang mereka ambil dua kali ternyata mati {#radarr-and-sonarr-search-again-when-a-release-they-grab-twice-is-dead}

Ketika release pertama yang diambil Radarr ternyata mati, pencarian berikutnya sering memilih release yang sama dari indexer lain, dengan nama yang sama. zurg mencatat pengambilan kedua itu dengan job id milik yang pertama. Radarr dan Sonarr mengingat setiap unduhan yang pernah mereka lihat gagal dengan id tersebut, jadi mereka menganggap pengambilan baru sebagai kegagalan yang lama dan tidak pernah memeriksanya lagi: tidak ada kegagalan, tidak ada blocklist, tidak ada pencarian baru. Film itu begitu saja berhenti. Dalam satu kali jalan IMDb Top 100 lewat Radarr, 25 film berakhir seperti itu.

Pengambilan release yang sudah pernah dijawab zurg mendapat job id sendiri, sama seperti cara SABnzbd memberi nama setiap unduhan. Ketika release itu juga mati, Radarr menerima kegagalan kedua, memasukkannya ke blocklist, lalu mencari lagi.

## Rilis Usenet yang mati dilaporkan gagal dalam hitungan menit, bukan hingga setengah jam {#dead-usenet-releases-are-reported-failed-in-minutes-instead-of-up-to-half-an-hour}

zurg mengecek artikel sebuah release yang sudah di-grab sebelum memberi tahu Radarr atau Sonarr bahwa release itu sudah selesai, dan zurg menunggu ukuran file release tersebut stabil dulu sebelum bertanya. Post yang mati adalah release yang ukuran filenya tidak pernah datang, jadi pengecekan itu tertahan di balik jeda tiga puluh menit sementara klien menunggu kabar. Sekarang, setelah zurg mencoba dan gagal mendapatkan ukuran file sebuah release, zurg langsung mengecek artikelnya. Release yang artikelnya sudah hilang akan dilaporkan gagal, sehingga klien bisa lanjut ke release lain.

Sebuah release yang ditemukan rusak saat dibaca juga ditahan selama lima menit untuk perbaikan PAR2, meskipun `enable_repair: false`, yang berarti perbaikan tidak pernah dimulai. Jeda itu sekarang dilewati kapan pun tidak ada perbaikan yang bisa dijalankan.

Dalam satu kali run IMDb Top 100 lewat Radarr dengan lebih dari separuh release yang di-grab sudah mati, dua jeda ini menyumbang sebagian besar waktu yang dihabiskan sebuah film di zurg.

## Rilis yang ternyata rusak saat impor akan ditandai gagal, sehingga Radarr mengambil yang lain {#a-release-that-turns-out-damaged-during-import-is-failed-so-radarr-grabs-another}

zurg memeriksa satu artikel per file sebelum memberi tahu Radarr bahwa sebuah rilis sudah siap, jadi rilis dengan celah di tengah file bisa lolos. Ketika impor Radarr kemudian sampai ke celah itu, zurg menolak memindahkan file, dan itu sudah benar, tetapi unduhan tetap terlihat belum selesai, bukan gagal. Radarr menandai film sebagai "import blocked" dan tidak pernah mencari salinan lain. Dalam satu kali run IMDb Top 100 melalui Radarr, lima film macet dengan cara itu.

Impor yang ditolak sekarang menandai unduhan sebagai failed. Radarr memasukkan rilis itu ke blocklist dan mencari rilis lain.

## Rilis yang sepenuhnya di-obfuscate tidak lagi menghasilkan file video tanpa nama {#a-fully-obfuscated-release-no-longer-comes-out-with-a-nameless-video-file}

Ketika posting Usenet menyembunyikan semua nama file, zurg mencari tahu sendiri file utamanya dari beberapa byte pertamanya lalu memberinya nama sesuai rilis, seperti yang dilakukan SABnzbd. Pemeriksaan itu dijalankan paling akhir dalam satu proses dengan batas sembilan puluh detik, dan ketika grab datang sekaligus dalam satu lonjakan, batas itu bisa habis lebih dulu. Akibatnya, file video diterbitkan dengan nama rilis tanpa ekstensi sama sekali. Radarr dan Sonarr melewatkan file seperti itu, sehingga unduhan tetap menunggu di antrean mereka untuk file yang sebenarnya bisa mereka impor.

Sekarang sebuah rilis dinamai ulang, sampai tiga kali, hingga zurg sempat memeriksa file tersebut. Baru setelah itu rilis ditampilkan ke library dan *arr Anda. Dalam satu kali run IMDb Top 100 lewat Radarr, hasilnya adalah Seven Samurai, file .mkv berukuran 42 GB.

## Rilis dengan aksen atau CJK di nama filenya tetap mempertahankan seluruh namanya {#releases-with-accents-or-cjk-in-their-filenames-keep-their-whole-names}

Sebuah rilis yang nama filenya memakai karakter di luar huruf Inggris biasa keluar dari zurg dengan bagian depan nama yang hilang. `Détective Conan S11E01 - 286 [MULTI] [AVC].mkv` disajikan sebagai `tective Conan S11E01 - 286 [MULTI] [AVC].mkv`, dan judul berbahasa Mandarin atau Jepang kehilangan lebih banyak lagi, karena semua karakter sampai karakter seperti itu yang terakhir ikut terbuang.

Sonarr dan Radarr tidak bisa berbuat apa-apa dengan nama yang tersisa. Nama seperti `tective
Conan S11E01` tidak cocok dengan series mana pun, jadi mereka beralih ke riwayat grab unduhan, menolak mengimpor hanya berdasarkan itu, dan menahan item dengan "release was matched to series by ID. Automatic import is not possible." Rilis itu tetap di antrean dan tidak ada yang menggerakkannya.

Ini juga bisa membuat Anda kehilangan file. Ketika satu-satunya hal yang membedakan dua file berada setelah karakter beraksen terakhir, keduanya keluar dengan nama yang sama, padahal nama adalah path. Satu rilis Prancis dengan sepuluh volume perbaikan membuat kesepuluhnya direduksi menjadi nama yang sama dan hanya menerbitkan empat file, padahal postingan berisi tiga belas, sehingga data perbaikan tidak punya jalan untuk diakses.

zurg sekarang membaca setiap karakter di atas ASCII biasa sebagai bagian dari nama file, yang memang itulah sifatnya: penghitung part, penanda `yEnc`, tanda kurung, dan ekstensi file yang dipakai poster semuanya ASCII biasa, jadi karakter selain itu termasuk bagian dari judul. Rilis dengan nama ASCII biasa tidak terpengaruh dan keluar persis seperti sebelumnya.

File rilis yang sudah ada di library Anda tetap memakai nama yang dulu dipakai saat diarsipkan, karena zurg tidak meninjau ulang daftar file yang sudah dicatat. Tambahkan ulang rilis yang terdampak dan nama yang sudah diperbaiki akan diambil.

(Terjemahan sebelumnya ditolak: rentang kode berbeda (` was served as `). Pertahankan struktur persis seperti semula.)

## Nama yang ditulis dalam bahasa Jepang, Korea, Mandarin, Thai atau Arab dibiarkan apa adanya {#a-name-written-in-japanese-korean-chinese-thai-or-arabic-is-left-alone}

zurg mengganti nama file di dalam arsip jika namanya tidak menjelaskan isinya. Jadi, rilisan yang diposting sebagai hash akan muncul dengan nama rilisannya sendiri. Untuk memutuskan itu, zurg dulu membandingkan huruf kapital dengan huruf kecil, padahal banyak skrip tidak punya keduanya. File bernama `오징어 게임 S01E01` mendapat nilai nol untuk keduanya, gagal dalam pengecekan nama biasa, lalu diganti namanya seolah-olah itu hash, termasuk S01E01-nya. Han, kana, Hangul, Thai, Ibrani, dan Arab semuanya terkena dampak ini.

Sekarang, huruf yang tidak punya kapital maupun huruf kecil akan langsung menjawab pertanyaan itu, tidak lagi membuatnya gagal. Nama dalam skrip-skrip tersebut tetap dipertahankan seperti saat diposting, dan hash tetap diganti namanya seperti sebelumnya.

zurg juga sekarang mencatat di log jika dua file dalam satu rilisan berakhir dengan nama yang sama. Nama adalah path, jadi ketika itu terjadi, rilisan secara diam-diam hanya menampilkan lebih sedikit file daripada yang sebenarnya ada, dan file tambahannya tidak bisa dibuka sama sekali. Sebelumnya tidak ada yang melaporkannya, sehingga bug nama file beraksen di entri sebelumnya tidak terlihat. Satu-satunya petunjuk saat itu adalah daftar folder yang jumlah barisnya lebih sedikit dari yang seharusnya.

## Perbaikan nama file sekarang juga berlaku untuk rilis yang sudah kamu punya {#the-filename-fixes-now-reach-releases-you-already-have}

Dua entri di atas mengubah cara zurg membaca nama file dari post Usenet. Namun, zurg menyimpan hasil pembacaan setiap NZB dan memakainya lagi setiap kali start, alih-alih memproses ulang seluruh direktori pantau Anda. Hasil yang tersimpan itu masih versi lama, jadi setelah upgrade, rilis yang sudah ada tetap menampilkan nama yang salah seperti sebelumnya. Hanya NZB yang baru ditambahkan yang mendapat nama yang benar.

zurg sekarang menyadari bahwa cara ia membaca post sudah berbeda dari cara hasil tersimpan dibuat, lalu ia membaca ulang. Start pertama setelah upgrade akan membaca ulang setiap NZB di direktori pantau Anda sekali saja. Proses ini sedikit lebih lama dari biasanya, lalu semuanya kembali normal. Tidak ada yang diunduh ulang dan tidak ada artikel yang diambil. zurg hanya membaca ulang file yang sudah ada di disk Anda.

Jika sebuah rilis terdampak, file-filenya akan kembali dengan nama yang diberikan post. Namun, klien unduh Anda mungkin masih menyimpan impor yang gagal sebelumnya. Jadi, rilis yang sudah lama tertahan di Sonarr atau Radarr karena tidak bisa diimpor perlu dihapus dulu item antreannya, baru kemudian impor akan dicoba lagi.

## Judul yang mengandung tanda baca juga tetap mempertahankan seluruh namanya {#titles-with-punctuation-in-them-keep-their-whole-names-too}

Perbaikan nama file di atas daftar ini sudah membuat zurg berhenti memotong nama di karakter beraksen dan karakter Mandarin. Tapi perbaikannya belum cukup. zurg menentukan apa itu nama file dengan mendaftar karakter yang boleh ada di dalamnya, dan daftar itu kurang dua puluh tanda umum. Akibatnya, judul yang memuat salah satu tanda itu tetap dipotong di tempat yang sama:

    Tom & Jerry - The Movie.1992.1080p.mkv   ->   Jerry - The Movie.1992.1080p.mkv
    Mairimashita! Iruma-kun (2026) [22].mp4  ->   Iruma-kun (2026) [22].mp4

`!`, `&`, `#`, `$`, `%`, `@`, `~`, `;`, `=` dan `^` semuanya menyebabkan hal ini.

Mendaftar karakter yang boleh ada di judul itu permainan yang tidak akan pernah selesai, jadi zurg sekarang tidak lagi mencobanya. Sebuah nama adalah nama file, dan satu-satunya karakter yang pasti tidak boleh ada di dalamnya adalah karakter yang ditolak semua sistem file: `/ \ : * ? " < > |`. Karakter lain sekarang menjadi bagian dari judul.

Saya sudah mengeceknya terhadap setiap NZB di folder pantau yang besar. Dari subjek yang berupa nama file biasa, hampir semua yang sebelumnya terpotong sekarang menyimpan nama lengkapnya. Subjek yang masih terpotong hanya yang kehilangan stempel unduhan per-unduhan dari indexer, dan memang begitulah seharusnya.

## Rilis yang file-nya diganti nama akan mengambil nama barunya sendiri {#a-release-whose-files-were-renamed-picks-the-new-names-up-on-its-own}

Perubahan perbaikan nama file di atas mengubah nama yang digunakan zurg untuk file-file di dalam rilis Usenet, dan rilis yang sudah ada di library Anda tidak selalu ikut terbarui. zurg mencocokkan rilis yang sudah dikenalnya dengan daftar file baru melalui link yang disimpan untuk setiap file, dan link Usenet memuat posisi file di dalam rilis. Ketika nama yang sudah diperbaiki urutannya berbeda dari nama lama, posisi itu ikut berpindah, link yang tersimpan tidak lagi menunjuk ke file yang sama, dan tidak ada lagi yang bisa dicocokkan, sehingga nama lama tetap dipakai.

Sekarang zurg kembali menggunakan ukuran file, yang tidak berubah. Jika hanya ada satu file di dalam rilis dengan ukuran tersebut, itulah filenya dan namanya diambil. Jika ada dua file dengan ukuran yang sama, zurg tidak mengganti nama apa pun daripada menebak dan memberi nama episode yang salah pada file lain.

Rilis yang posisinya tidak berpindah sudah mendapatkan nama baru dan tidak terpengaruh, begitu juga semua backend non-Usenet, karena link-nya tidak berubah ketika sebuah file diganti nama.

## File yang tidak bisa dibaca mount tidak lagi menahan semua yang lain {#a-file-the-mount-cannot-read-stops-holding-everything-else-up}

Saat pembacaan file gagal karena alasan yang tidak bisa dijelaskan zurg, zurg menyuruh klien untuk mencoba lagi, dan terus mengulang hal itu selama file tersebut terus gagal. rclone menanggapi ini dengan serius: satu pembacaan file seperti itu memakan waktu 55 detik dan tiga lusin permintaan sebelum menyerah. Karena rclone memperlambat seluruh koneksinya ke server yang terus mengembalikan error, file sehat berikutnya butuh 3.66 detik untuk terbuka, bukan 0.04.

Sekarang, percobaan ulang berhenti setelah satu menit dengan kegagalan yang sama. Pembacaan dijawab dengan cara yang sama seperti pembacaan file rusak sebelumnya, file tetap ada di daftar library kamu, dan pembacaan yang sama hanya butuh setengah detik.

zurg tetap mencoba mengunduh setiap kali, jadi file yang kembali normal akan diambil oleh pembacaan berikutnya.

## Mount berhenti mengunduh begitu kamu berhenti membaca {#the-mount-stops-downloading-once-you-stop-reading}

Pemindaian perpustakaan, pemeriksaan subtitle, atau apa pun yang sebentar menyentuh banyak file sebelumnya menarik data dari akun debrid kamu jauh lebih banyak daripada yang dibaca.

rclone 1.74 mulai membuat sebuah file terus diunduh selama lima detik setelah program terakhir menutupnya. Tidak ada yang menunggu byte-byte itu, dan di akun yang cepat, lima detik berarti beberapa ratus megabyte per file. Membaca 1 MiB dari masing-masing dua puluh file menarik 4.2 GiB, padahal dulu hanya 80 MiB.

zurg sekarang mematikan fitur itu. Mount dengan rclone 1.73 ke bawah tidak terpengaruh dan tidak berubah, karena opsinya memang tidak ada di sana.

Jika kamu menjalankan rclone sendiri, bukan mount dari zurg, tambahkan `--vfs-handle-caching 0` ke perintah mount kamu pada rclone 1.74 atau yang lebih baru. README membahasnya.

## Rilis yang kehilangan satu volume arsip tidak lagi kehilangan sisanya {#a-release-that-loses-one-archive-volume-no-longer-loses-the-rest}

Rilis Usenet yang dikirim sebagai satu set rar atau 7z multi-bagian bisa berhenti diimpor sepenuhnya. Sonarr dan Radarr terus menunggu di "Waiting for import" dan tidak pernah beranjak dari situ, sementara folder rilisnya hanya berisi bagian rar, atau malah hilang sama sekali.

Ketika zurg tidak bisa membaca satu volume dari sebuah set, zurg menyisihkan volume itu dan membiarkan listing berikutnya berjalan tanpa volume tersebut. Listing itu menemukan set kekurangan satu volume, berhenti di volume setelahnya, dan ikut menyisihkan volume itu. Sebuah rilis kehilangan volumenya satu per satu, kira-kira setiap sepuluh menit, dan begitu tidak ada yang tersisa, rilis itu keluar dari library dan keluar dari folder tempat download client mengimpor. Bagi Sonarr, path yang tidak ada bukan folder kosong, melainkan impor yang gagal selamanya.

Volume yang sudah diketahui tidak bisa dibaca sekarang tetap berada di dalam set-nya. Setiap listing berhenti di volume yang sama dan melaporkan hal yang sama tentangnya. Jadi rilis yang kehilangan sebagian posting-nya dilaporkan sekali saja, dan client kamu bisa memasukkannya ke blocklist lalu mencari salinan lain. Rilis yang semua volumenya bisa dibaca tidak terpengaruh.

## Pemindaian mengikuti library ke lokasi barunya di bawah `__magic__` {#scans-follow-the-library-into-its-new-home-under-__magic__}

Cermin library kamu pindah dari `__magic__` ke `__magic__/__all__` di 2026.09.17.2240-nightly. Sebagian zurg masih menyebut lokasi lama.

Saat rilis baru datang, scan yang diminta zurg ke Plex atau Jellyfin mengarah ke folder yang sudah tidak ada sejak rilis itu. Akibatnya, tidak ada yang pernah masuk antrean, dan konten baru harus menunggu scan terjadwal dari media server. Siapa pun yang menjalankan skrip `on_library_update` juga diberi path yang sama.

Sekarang keduanya menyebut folder tempat download client kamu diberi tahu untuk mengimpor. Daftar yang dihapus zurg dari cache mount saat sebuah rilis datang atau pergi juga sudah memakai folder yang sama.

## Watchlist sekarang bisa menerima torrent dari indexer Torznab {#the-watchlist-can-take-torrents-now-from-torznab-indexers}

Sampai sekarang, watchlist atau request Seerr hanya bisa dipenuhi dari Usenet. Tambahkan `type: torznab` ke sebuah indexer dan zurg akan mencarinya juga. Hasil berupa torrent akan diberikan ke akun debrid, bukan ditulis ke `nzbs/`.

**Torrent hanya pernah diberikan ke akun yang sudah punya file itu di cache.** Setiap akun yang menerima add akan ditawari hash-nya, karena cache-nya terpisah-pisah, dan akun pertama yang sudah memegang release tersebut akan mengambilnya. Kalau tidak ada akun yang punya, itu berarti kandidat ini tidak berhasil. Jadi zurg pindah ke release berikutnya, yang bisa berupa torrent lain atau NZB. Tidak ada yang diunduh ke akun Anda, tidak ada kuota add uncached yang terpakai, dan tidak ada proses yang dibiarkan berjalan untuk sesuatu yang tidak ditunggu siapa pun.

Ketika kedua jenis indexer bisa memberikan jawaban, `prefer` menentukan mana yang dicoba lebih dulu. Nilai default-nya adalah `usenet` kecuali Anda mengubahnya, jadi instalasi yang hanya punya indexer Newznab akan berjalan persis seperti sebelumnya. `torrents` membalik urutannya, dan `best` mengambil apa pun yang ada di urutan teratas peringkat, torrent atau bukan.

Grab torrent tetap menunggu untuk dicek seperti yang lain, tetapi pertanyaannya berbeda. Akun sudah menyatakan bahwa mereka punya kontennya, jadi yang dicek adalah apakah release itu sudah masuk ke library Anda dengan file di dalamnya. Release yang tercatat kosong akan disisihkan supaya release berikutnya mendapat gilirannya.

Anda juga bisa menjalankan akuisisi hanya dengan indexer Torznab, tanpa provider `nzb`.

## Agen yang membaca library tidak lagi menganggap setiap rilis kosong {#an-agent-reading-the-library-no-longer-calls-every-release-empty}

Daftar MCP zurg hanya mengukur ukuran sebuah rilis saat diminta, karena menelusuri tabel file seluruh pustaka memakan waktu nyata. Untuk rilis yang belum diukur, daftar melaporkan ukuran dan jumlah file sebagai nol. Tidak ada apa pun dalam jawabannya yang memberi tahu pembaca bahwa nol berarti "belum diukur", bukan "tidak ada apa-apa di sana". Agen yang diminta mencantumkan isi sebuah direktori akan mengatakan film 6.6 GB tidak punya file, padahal tool untuk satu rilis selalu memberikan jawaban yang benar.

Daftar yang belum mengukur sekarang membiarkan kedua angka itu kosong, alih-alih melaporkan nol. Untuk mendapatkannya, pakai `with_size`, urutkan berdasarkan ukuran, atau pakai filter ukuran. `zurg_library_search` kini juga menerima `with_size`, yang sebelumnya tidak bisa. Jadi kamu tidak perlu lagi mempersempit atau mengurutkan ulang hasil hanya untuk mendapatkan ukuran.

## zurg doctor memberi tahu apakah endpoint MCP sedang merespons {#zurg-doctor-says-whether-the-mcp-endpoint-is-answering}

`zurg doctor` memeriksa apakah port dashboard merespons dan berhenti di situ,
yang tidak berarti apa-apa tentang `/mcp`. Endpoint yang diaktifkan di config
tapi kemudian ditolak server untuk dilayani, yang terjadi saat `username`
kosong, terlihat sehat dari luar dan hanya menjelaskan dirinya dalam satu
baris di log startup, dan tidak di tempat lain.

Saat `mcp.enabled` diatur, `doctor` sekarang berbicara dengan protokol ke `/mcp` dan
melaporkan apa yang kembali: merespons, menolak kredensial yang dikonfigurasi, atau
diaktifkan tapi tidak dilayani. Instance dengan endpoint mati tidak ditanyai
soal itu dan tidak mendapat baris apa pun.

## Membuka endpoint MCP di browser sekarang menjelaskan apa itu {#opening-the-mcp-endpoint-in-a-browser-now-tells-you-what-it-is}

Membuka `/mcp` di browser menampilkan "Bad Request: GET requires an Mcp-Session-Id header", yang memang benar, tetapi tidak menjawab pertanyaan apa pun. Sekarang endpoint akan menjelaskan dirinya sendiri saat dibuka di browser: protokol apa yang dipakai, alamat yang harus dituju client, contoh snippet untuk jembatan stdio, build yang sedang jalan, dan setiap tool yang sedang ditawarkan, dikelompokkan per toolset. Tool yang menjelaskan apa yang akan dilakukannya dan menunggu konfirmasi akan diberi tanda.

Daftar itu diambil dari hasil registrasi yang sebenarnya, bukan salinan kedua yang ditulis manual. Jadi tool yang dihilangkan oleh `read_only`, oleh toolset Anda, atau oleh sakelar lifecycle tidak akan ditampilkan seolah-olah bisa Anda panggil. Halaman ini juga memberi tahu Anda jika endpoint berjalan tanpa autentikasi.

Client tidak terpengaruh. Halaman ini hanya dikirim untuk GET yang meminta HTML dan tidak membawa session, yang berarti browser, bukan client MCP. GET dari client tetap membuka event stream seperti sebelumnya.

## Pemutaran Usenet menghabiskan jatah koneksi lebih cepat {#usenet-playback-fills-the-connection-allowance-sooner}

Pembacaan Usenet sekarang memasukkan artikel di posisi pemutaran ke dalam penjadwal akun sebelum menawarkan sisa rentang yang diminta. Saat rentang besar dibagi ke beberapa koneksi pipeline, artikel-artikel yang berurutan dibagikan ke koneksi-koneksi itu secara bergantian, bukan memberi koneksi pertama empat artikel pertama, koneksi kedua empat artikel berikutnya, dan seterusnya. Dengan begitu, artikel yang berguna pertama kembali di putaran koneksi pertama, tidak menunggu di belakang byte yang datang belakangan.

Postingan arsip dengan artikel kecil mendapat jendela read-ahead minimal 64 MiB. Postingan modern dengan artikel berukuran beberapa megabyte tetap memakai jendela yang sudah ada. Jumlah artikel yang lebih banyak tidak menambah pemakaian memori: badan artikel spekulatif dibatasi untuk dua pembaca dan setengah dari `cache_size_mb` (256 MiB dengan nilai default), sedangkan cache artikel tetap memakai batas keras yang sudah ada. Permintaan berukuran pemutaran sekarang mulai dari 64 MiB, bukan 128 MiB, jadi buffer pemutar 90 MiB tidak lagi jatuh ke jalur seek/probe. Seek kecil tetap memakai jalur itu.

Batch pipeline yang tersendat boleh melakukan hedging hingga lima artikel berbeda sekaligus. Batas akun sebanyak dua puluh permintaan artikel per menit tidak berubah, dan read-ahead, perbaikan, serta pekerjaan lain yang tidak ada klien menunggunya tetap tidak pernah di-hedge.

Membuka arsip multi-volume juga jadi lebih hemat. Jika PAR2 sudah memberi panjang pasti setiap volume, header yEnc yang sudah terverifikasi dari satu volume bisa dipakai sebagai stride artikel yang umum untuk kumpulan volume saudara yang besar. Setiap volume saudara memverifikasi inferensi itu dari header-nya sendiri sebelum menyajikan byte pertamanya, jadi resolusi tidak lagi membayar satu artikel secara serial untuk setiap volume, tanpa mempercayai geometri hasil inferensi untuk data. Pemulihan nama file juga sekarang menjawab dari header yEnc, tidak menunggu sisa artikel itu selesai diunduh.

## File .strm yang tersimpan mengikuti perubahan Base URL {#saved-strm-files-follow-a-base-url-change}

Mengganti Base URL membuat setiap `.strm` yang sudah ada di `strm/` tetap mengarah ke alamat lama. Restart juga tidak membantu, karena zurg hanya menulis file yang belum ada. Sekarang, `.strm` yang URL-nya berbeda dari yang akan ditulis zurg akan ditulis ulang di tempatnya. Ini terjadi setiap kali start, dan langsung saat Base URL diubah di dasbor atau `save_strm_files` diaktifkan di sana. File yang sudah benar dibiarkan saja, jadi media server tidak perlu membaca ulang seluruh folder pada setiap pemindaian.

Jellyfin menyimpan URL yang sudah ia baca dari `.strm` dan akan mengambil URL yang baru pada pemindaian library berikutnya. `.strm` yang masih berisi tautan akun dari build lama juga ikut ditulis ulang, ke bentuk yang bisa berpindah antar akun dan tetap bertahan saat perbaikan. `.strm` yang diedit manual di dalam `strm/` akan ditimpa, jadi arahkan Base URL ke alamat yang memang kamu inginkan.

## Mengaktifkan watchlist Plex tidak lagi mengosongkannya {#turning-the-plex-watchlist-on-no-longer-empties-it}

Saat watchlist diaktifkan, dulu zurg membaca seluruh daftar Anda sebagai antrean tertunda dan mengerjakannya satu per satu, sambil menghapus setiap judul yang sudah diproses. Pada run pertama, 121 judul hilang dari daftar 163 item dalam sekitar empat menit. Plex tidak menyimpan catatan tentang entri watchlist yang sudah dihapus, jadi satu-satunya cara untuk mengembalikannya adalah snapshot yang dibuat sebelumnya. Tidak ada apa pun di config maupun log yang memberi tahu bahwa hal ini akan terjadi.

Dua pengaturan sekarang menentukan apa yang dilakukan acquire terhadap daftar tersebut. Daftar itu milik Anda, bukan milik zurg.

**`watchlist.only_new_items`** aktif secara default. Saat watchlist diaktifkan, zurg mulai memantaunya. Semua yang sudah ada di daftar dianggap sudah ditangani, dan yang Anda tambahkan setelahnya akan di-acquire. Pengaturan ini hanya berlaku sekali, pada run pertama, dan tidak pernah menimpa antrean yang sudah ada. Jadi instalasi yang sedang mengerjakan watchlist akan tetap berjalan seperti sebelumnya.

**`watchlist.remove_after_grab`** aktif secara default, yang memang selalu menjadi perilaku fitur ini, jadi tidak ada yang berubah untuk Anda kecuali Anda memintanya. Matikan pengaturan ini agar watchlist tetap menjadi watchlist. Daftar itu tetap jadi tempat Anda menjelajah untuk memutuskan apa yang mau ditonton, dan zurg memenuhinya di latar belakang tanpa pernah mengubahnya. Judul yang dibiarkan di daftar tidak memakan biaya untuk diperiksa ulang, karena catatan sudah mencakupnya dan tidak ada indexer yang ditanya lagi.

Keduanya ada di halaman config dan berlaku saat restart berikutnya. Sumber acquisition yang Anda tulis secara eksplisit di bawah `acquisition.sources` dapat mengatur keduanya per sumber. Keduanya tidak berarti apa-apa untuk sumber Seerr, karena sumber itu tidak memiliki daftar yang ditulis zurg.

## Watchlist dan permintaan Seerr menunggu server berita sebelum dibersihkan {#watchlist-and-seerr-requests-wait-for-the-news-servers-before-they-are-cleared}

Dulu, grab dianggap selesai begitu NZB-nya sampai di watch directory. Indexer menjawab, jawabannya terbaca sebagai NZB, dan file-nya ditulis. Itu tiga fakta tentang indexer, dan tidak ada satu pun tentang posting-nya. Permintaan lalu ditandai selesai berdasarkan ketiga fakta itu. Untuk watchlist Plex, artinya entri-nya dihapus, dan Plex tidak menyimpan catatan dari entri yang sudah dihapus. Jadi posting yang mati bisa mengambil satu-satunya catatan bahwa kamu ingin judul itu, sebelum ada yang membaca satu byte pun darinya. Satu kali proses pada watchlist berisi 163 item menghapus 121 judul, dan 12 rilis di baliknya tidak bisa dibaca.

Sekarang setiap rilis yang diambil diperiksa ke news server dulu sebelum apa pun dianggap berhasil. Pemeriksaannya sama seperti yang sudah dilakukan endpoint SABnzbd sejak nightly 08.28. Ada tiga kemungkinan jawaban, dan ketiganya dipisahkan.

- **Artikelnya sudah hilang.** Grab tidak dihitung. Judul tetap ada di watchlist kamu, permintaan tetap terbuka, dan rilisnya dicatat sebagai mati. Dengan begitu, percobaan berikutnya memilih kandidat selanjutnya, bukan terus memakai rilis yang sudah ada di library kamu. Rilis yang diketahui mati tidak memakan biaya sama sekali. Rilis itu tidak diambil dan tidak dihitung sebagai salah satu dari tiga kandidat yang dicoba dalam satu percobaan. Jadi deretan posting mati di urutan atas akan dilewati, bukan dicoba ulang terus-menerus. Season pack yang ternyata mati akan mengembalikan seluruh season ke daftar yang dicari, supaya episode-episode lepasnya bisa diambil.
- **Server tidak bisa ditanya.** Pool sedang down, akun kena throttle, atau library belum mencantumkan NZB yang baru. Tidak ada yang terkonfirmasi, jadi tidak ada keputusan yang diambil. Permintaan menunggu dan diperiksa lagi, dan menunggu tidak menghabiskan jatah percobaan ulang. Rilis yang masih tidak bisa diperiksa setelah sekitar dua jam akan dikesampingkan seperti rilis yang mati, dan giliran diberikan ke rilis berikutnya. Judul tidak pernah dihapus berdasarkan rilis yang tidak sempat diperiksa siapa pun.
- **Rilisnya ada.** Sama seperti sebelumnya.

Instalasi tanpa akun Usenet tidak punya apa-apa untuk diperiksa, jadi tidak terpengaruh.

## Memeriksa rilis besar tidak lagi kehabisan waktu di server berita yang lambat {#checking-a-big-release-no-longer-runs-out-of-time-on-a-slow-news-server}

Sebelum sebuah grab dilaporkan selesai, zurg menanyakan ke server berita tentang setiap file
di dalamnya. Sebelumnya ia menanyakannya satu file per satu. Beberapa akun menjawab
pertanyaan itu dengan lambat dan harus bergantian, jadi mengirim semuanya sekaligus lewat satu
koneksi tidak membuatnya lebih cepat. Server dari satu provider butuh lebih dari
lima detik per file, sehingga sebuah rilis 4K dengan 133 volume memakan sekitar dua belas menit
hanya untuk tanya-jawab, dan setiap pengecekan diberi batas lima. Pengecekan itu tidak
pernah bisa selesai, jadi Sonarr dan Radarr menunggu tiga jam lalu melihat grab
gagal, dan watchlist menunggu selamanya.

File-file itu sekarang ditanyakan beberapa sekaligus, memakai semua koneksi yang dimiliki akun kecuali satu yang disisakan untuk pemutaran. Jadi semakin banyak koneksi yang diizinkan akun Anda, semakin cepat rilis besar dicek.
Diukur pada rilis 133 volume yang sama yang dulu tidak pernah bisa dicek: di bawah dua menit dengan dua belas koneksi. Dengan empat koneksi, rilis itu tetap kehabisan waktu, karena pertanyaannya sendiri yang memakan waktu. Rilis kecil tidak lebih lambat dari sebelumnya.

Rilis yang pengecekannya tidak bisa selesai tepat waktu tidak lagi dibiarkan menghambat judul. Watchlist menyingkirkannya seperti cara ia menyingkirkan rilis mati, lalu mencoba rilis berikutnya. Endpoint SABnzbd melaporkannya gagal seperti biasa, sehingga Sonarr dan Radarr mencari rilis lain.

## Pengambilan khusus cache di TorBox tidak lagi mengunduh rilis yang seharusnya dilewati {#cached-only-grabs-on-torbox-no-longer-download-the-releases-they-were-meant-to-skip}

TorBox punya flag yang membuat add menolak apa pun yang belum mereka simpan. Flag ini ada di API mereka tapi tidak ada di dokumentasi mana pun, dan zurg tidak memakainya. Akibatnya, grab hanya-cache menambahkan torrent, menunggu untuk melihat apakah selesai, lalu menghapusnya lagi ketika ternyata itu download sungguhan. Satu dari enam puluh add per jam milik akun itu terpakai, satu slot transfer ditempati, dan byte ditarik untuk rilis yang sudah diberi tahu ke *arr untuk dilewati.

Grab hanya-cache sekarang meminta kontennya, dan langsung ditolak dalam waktu kurang dari satu detik jika TorBox tidak punya kontennya, tanpa sisa apa pun di akun. Miss tetap memakan satu dari enam puluh add per jam itu, jadi zurg tetap mengaturnya seperti sebelumnya. Dan hit tetap diperiksa, tidak langsung dipercaya: cache TorBox bisa bilang ya untuk konten yang ternyata gagal mereka layani, jadi rilis harus selesai dulu sebelum zurg melaporkannya.

## Pengambilan khusus cache di Debrid-Link tidak lagi menghabiskan jatah tambah harian {#cached-only-grabs-on-debrid-link-no-longer-spend-the-daily-add-allowance}

Debrid-Link menerima info hash saja maupun magnet, dan hanya menambahkan hash ketika kontennya sudah ada di sana. zurg sebelumnya mengirim magnet, yang artinya perintah untuk mengambil. Setiap permintaan cached-only yang meleset tetap diterima, dihitung dari jatah 50 penambahan uncached per hari dan salah satu dari 20 slot transfer akun, lalu dihapus lagi agar jatahnya kembali. Setelah 50 kali meleset, akun tidak bisa menambahkan apa pun lagi sampai reset harian.

Sekarang permintaan cached-only mengirim hash. Permintaan yang meleset langsung ditolak dalam sekitar seperseratus detik dan tidak menyentuh akun sama sekali, jadi *arr bisa memproses daftar rilis yang panjang tanpa menghabiskan apa pun untuk rilis yang memang tidak ada di cache. Ini juga berlaku untuk permintaan yang datang sebagai file .torrent. File itu ada supaya layanan tidak perlu melakukan pencarian metadata yang dipaksa oleh info hash saja, sedangkan pertanyaan cache tidak membutuhkan pencarian itu sama sekali.

## Penguncian akibat batas laju Debrid-Link kembali diberi jeda mundur {#debrid-link-rate-limit-lockouts-are-backed-off-from-again}

Debrid-Link membalas penguncian per-endpoint yang berlangsung satu jam dengan HTTP 503 dan alasannya ada di body. zurg memperlakukan setiap 503 sebagai layanan yang sedang mati sebentar, jadi zurg tidak pernah membaca alasannya dan terus mencoba lagi endpoint yang sudah bilang untuk menunggu satu jam. Sekarang zurg mengenali penguncian ini dan tetap tidak memakai endpoint itu sampai penguncian selesai.

## `__magic__` sekarang mencerminkan library kamu di `__magic__/__all__`, sementara root-nya tetap untukmu {#__magic__-now-mirrors-your-library-at-__magic____all__-leaving-its-root-to-you}

Dulu namespace mencerminkan `__all__` di root-nya sendiri, dan itu membuat folder tempat download client mengambil file sama dengan folder tempat setiap rilis sudah berada. Root folder Sonarr atau Radarr harus diletakkan *di dalam* folder download supaya bisa menghindari dua health check yang muncul akibat susunan itu. Selain itu, manual import yang diarahkan ke folder download akan menelusuri seluruh library hanya untuk mencari satu rilis.

Mirror-nya sekarang pindah satu level ke bawah. `__magic__/__all__` adalah library seperti yang tercantum di `__all__`, dan itu yang sekarang dihitung oleh `sabnzbd.complete_dir` dan `qbittorrent.save_path`. Root dari `__magic__` jadi milikmu, untuk folder `tv`, `movies`, dan `anime` yang kamu arahkan para \*arr. Keduanya saling bersaudara, jadi tidak ada yang berisi yang lain dan tidak ada client yang memberi peringatan.

**Ini mengubah path.** Kalau kamu mengatur `sabnzbd.complete_dir` atau `qbittorrent.save_path` secara manual — misalnya pada kasus pemetaan container — tambahkan `/__all__` di belakangnya. Kalau kamu mengarahkan library Plex atau Jellyfin ke `__magic__` itu sendiri, bukan ke folder di dalamnya, path-nya ikut bergeser satu level; arahkan ke `__magic__/__all__` atau ke folder tempat kamu melakukan import. Root folder kamu tidak ikut pindah, dan tidak ada yang tersimpan di tabel yang berpindah: placement adalah path di bawah folder yang sudah kamu buat, dan tombstone diindeks berdasarkan rilisnya, jadi susunan yang sudah ada tidak terpengaruh. Grab yang sedang berjalan saat kamu upgrade masih membawa path lama dan perlu di-grab ulang.

Tidak ada yang bisa ditulis ke `__magic__/__all__`: baris di sana akan menjadi alamat kedua untuk rilis yang sudah punya alamat, jadi MOVE, MKCOL, atau DELETE yang diarahkan ke sana akan ditolak. Menulis *di dalam* folder rilis tidak berubah, dan di situlah sebuah \*arr menaruh .nfo di samping file yang sudah di-import.

## Export Logs sekarang memberi tahu ke mana tautanmu pergi dan berapa lama masa berlakunya {#export-logs-now-tells-you-where-your-links-went-and-how-long-they-last}

Export Logs mencoba beberapa host paste dan memberikan link dari host pertama yang mau menerima file. Dulu tidak pernah dijelaskan host mana yang dipakai, dan host-host ini tidak sama. Host utama menyimpan paste selama 180 hari dan memperpanjangnya setiap kali ada yang membacanya, sedangkan host cadangan menghapusnya setelah tiga hari. Link-nya terlihat sama, jadi laporan yang dikirim hari Jumat bisa berubah menjadi dua link yang sudah mati pada Senin, tanpa ada penjelasan apa pun. Sekarang setiap link datang bersama nama host yang menyimpannya dan batas waktu yang berlaku untuknya.

Alasan kamu selalu jatuh ke host cadangan ada di bagian kedua. Host utama memblokir alamat yang mengunggah beberapa kali dalam waktu singkat, dan Export Logs mengirim dua file setiap kali kamu klik. Jadi serangkaian laporan bug membuat alamat itu ditolak, lalu setiap permintaan dari mesin tersebut ikut ditolak, termasuk saat membaca kembali paste yang sudah disimpan. zurg tetap memasukkan kedua bagian dari setiap export berikutnya ke host itu dan mencatatnya sebagai upload yang gagal, sehingga log mengarah ke file, bukan ke alamatnya. Sekarang host yang menolak mesin kamu dibiarkan selama sehari, dan log akan menyebutkan bahwa itulah yang terjadi.

## Mengunggah info debug tidak lagi mempublikasikan kunci indexer dan download client kamu {#uploading-debug-info-no-longer-publishes-your-indexer-and-download-client-keys}

Export Logs menyensor setiap kredensial yang ditemukan sebelum mengirim config ke paste host, tetapi dulunya hanya memeriksa level paling atas. Kunci di dalam blok bersarang tidak ikut tersensor dan terkirim apa adanya: API key indexer Newznab Anda, baik dari daftar Stremio maupun daftar watchlist, token addon Stremio, API key SABnzbd dan qBittorrent, token akun zrok, dan token scan Plex. Yang paling berbahaya adalah API key indexer, karena itu terkait dengan akun Usenet Anda, bukan milik zurg.

Sekarang semuanya sudah disensor. Token provider dan password news server tidak pernah terpengaruh.

## zurg bisa dikendalikan oleh agen AI {#zurg-can-be-driven-by-an-ai-agent}

Ada endpoint baru di `/mcp` yang memakai Model Context Protocol. Jadi, klien seperti Claude bisa mencari library, mencari tahu kenapa sebuah release tidak bisa diputar, dan memperbaikinya lewat tool yang bertipe, bukan dengan membaca HTML dashboard.

Fitur ini mati secara default. Nyalakan dengan `mcp: {enabled: true}`, lalu arahkan klien ke `http://your-zurg:9999/mcp` dengan username dan password yang sama seperti untuk dashboard. Klien yang hanya mendukung stdio bisa pakai `zurg mcp`. Perintah ini terhubung ke instance yang sudah berjalan, jadi tidak menjalankan instance kedua.

Selain tool, zurg juga menyediakan dokumentasinya sendiri dan state live-nya sebagai resource yang bisa langsung dibaca klien. Ada juga enam prompt untuk prosedur yang layak diikuti persis, misalnya mendiagnosis release yang tidak bisa diputar, menyiapkan scan Plex dengan aman, dan memilah apa saja yang sudah dinyerah oleh repair.

Fitur ini juga tahu batasnya. Setiap aksi yang menghapus sesuatu akan menjelaskan dulu apa yang akan dilakukannya, dan baru bertindak setelah kamu mengonfirmasi rencana persis itu. `read_only: true` menyembunyikan semua tool yang mengubah sesuatu. Tool yang bisa menghentikan zurg atau mount-nya tetap berada di balik saklar sendiri. Tidak ada hasil yang menyertakan token, password, atau tautan yang sudah di-resolve.

Lihat [server MCP](mcp.md).

## zurg memberi tahu saat build kamu sudah usang {#zurg-says-when-your-build-is-out-of-date}

Sebelumnya zurg tidak pernah menunjukkan umur sebuah build, sehingga bug yang sudah diperbaiki di bulan Agustus bisa muncul di laporan bug bulan September dengan perbaikannya yang sudah tiga minggu lalu, dan tidak ada orang di thread itu yang punya alasan untuk curiga. Sekarang zurg sekali sehari bertanya ke repositori publik tentang rilis terbarunya dan, jika build kamu lebih lama dari rilis itu, menulis satu baris yang menyebut nama rilisnya, tanggalnya, dan build kamu. Sisa waktu zurg diam saja: tidak ada yang dicetak jika kamu sudah yang terbaru, tidak ada yang dicetak jika GitHub tidak bisa dihubungi, dan build yang tidak tahu kapan dibuatnya, yaitu image Docker, tidak ditebak-tebak. Sponsor yang memakai nightly selalu berada di depan rilis publik terakhir dan tidak pernah melihatnya sama sekali. Hasilnya di-cache selama sehari sehingga restart tidak memakan request, penolakan tidak dicoba lagi sampai besok, dan seluruh fitur ini bisa dimatikan dengan `disable_update_check: true`.

## Tautan mati di dalam rilis yang diarsipkan tidak lagi dinyatakan sehat di setiap pemindaian {#a-dead-link-inside-an-archived-release-stops-being-declared-healthy-every-sweep}

Ketika sebuah release disajikan sebagai satu arsip dan repair tidak bisa mempersempit add ulang lebih jauh lagi, zurg memeriksa apakah arsipnya sendiri masih bisa dibaca. Kalau masih bisa, zurg menghapus tanda rusak pada release tersebut alih-alih menghukumnya sebagai rusak. Semua tanda itu dihapus, termasuk tanda pada file yang diakses akun langsung lewat link milik mereka sendiri. Link arsip yang sudah terverifikasi membuktikan bahwa arsipnya bisa dibaca, dan sama sekali tidak membuktikan apa pun tentang file-file itu. Jadi, file yang link-nya sudah tidak disajikan akun dikembalikan ke status sehat berdasarkan pembacaan yang tidak ada kaitannya. Sweep berikutnya meng-unrestrict file itu dan menemukannya mati lagi, release dihukum rusak lagi, dan pass yang menghukumnya itu justru berakhir dengan memulihkannya lagi. Pada release 64 file dengan 9 link yang sudah tidak disajikan akun, siklus ini berjalan 111 kali dalam seminggu, dua kali dalam 40 detik yang sama, dengan dua magnet add per pass. Keringanan ini sekarang hanya berlaku untuk file yang benar-benar disajikan oleh arsip, yaitu file yang tidak punya link sendiri. File yang diakses akun tetap mempertahankan vonis yang didapat dari link-nya sendiri dan masuk ke repair, satu-satunya jalur yang bisa membuatkan link yang berfungsi untuknya.

## Unduhan yang hanya sebagian yang sampai tidak lagi menggantung di antrean selamanya {#downloads-that-only-partly-arrive-no-longer-sit-in-the-queue-for-ever}

Ketika sebagian file dari sebuah rilis tidak bisa dibaca, zurg menahan unduhannya di antrean dan menunggu ukuran file yang tepat, padahal ukuran itu tidak akan pernah datang. Pemeriksaan yang seharusnya menemukan masalah ini baru berjalan setelah ukuran-ukuran tersebut diterima. Sonarr dan Radarr menampilkan unduhan seperti itu di 0% tanpa sisa waktu, selama zurg masih berjalan. Mereka tidak pernah memasukkan rilisnya ke daftar blokir atau mencari rilis lain.

Sekarang zurg bertanya ke server berita tentang sebuah rilis yang sudah menunggu selama tiga puluh menit. Jika artikelnya sudah hilang, atau server berita sama sekali tidak bisa ditanya, zurg melaporkan unduhannya gagal. Rilis yang ukuran filenya memang masih dalam perjalanan tidak terpengaruh dan tetap ditahan sampai ukurannya diterima.

## Rilis yang ditinggalkan satu akun bisa diperbaiki dari akun lain {#a-release-one-account-gave-up-on-can-be-repaired-from-another}

Layanan debrid punya cache masing-masing yang terpisah. Release yang sudah dihapus Real-Debrid, atau yang ditolak hanya dari nama filenya, bisa saja masih ter-cache di AllDebrid saat ini dengan hash yang sama. Sampai sekarang zurg tidak bisa memakai itu. Repair selalu menambahkan ulang release ke akun asalnya, jadi begitu akun itu menyerah, tidak ada lagi yang bisa dicoba. Release itu tetap mati di library kamu, padahal akun lain yang sudah kamu bayar menyimpannya.

Sekarang, release yang sudah ditolak oleh semua akun yang menyimpannya akan ditawarkan ke akun kamu yang lain. Akun pertama yang sudah punya release itu akan mengambilnya, dan release tersebut kembali dengan kedua akun di belakangnya, lalu beralih otomatis di antara keduanya seperti release lain yang disimpan dua akun. Tidak ada yang perlu kamu nyalakan. Kalau kamu sudah punya akun kedua yang dikonfigurasi dan repair aktif, inilah yang dilakukan repair saat pilihan lainnya habis.

Akun hanya akan diberi konten yang memang sudah dimilikinya. Kalau akun harus mengambil release itu dulu, penambahannya dibatalkan dan dihapus lagi, jadi tidak ada yang diunduh dan tidak ada kuota transfer yang terpakai. Akun yang menjawab tidak akan ditanya lagi setelah sehari, lalu dua hari, lalu empat hari, sampai sekitar dua minggu. Dengan begitu, release yang sudah hilang untuk selamanya tidak akan terus membebani kamu saat dicek.

## Pengambilan khusus cache dinilai oleh akunmu, bukan oleh pencarian cache {#cached-only-grabs-are-judged-by-your-account-not-by-a-cache-lookup}

Dalam mode cached-only, zurg dulu menanyakan ke TorBox, Premiumize, dan Offcloud apakah sebuah rilis ada di cache mereka, lalu langsung meneruskan jawabannya ke Sonarr. Endpoint tersebut menjawab pertanyaan yang berbeda dari yang sebenarnya ditanyakan. Mereka hanya bilang bahwa konten ada di cache layanan itu, bukan bahwa akun kamu benar-benar akan memilikinya, dan tidak ada yang memeriksa torrent-nya setelah itu. Jadi jawaban "ya" yang ternyata berujung pada download diteruskan ke Sonarr sebagai grab instan yang sudah dijanjikan, padahal itulah hal yang justru mau dicegah oleh cached-only.

Sekarang semua akun diperlakukan dengan cara yang sama. Torrent ditambahkan, instance-nya diawasi, dan hanya torrent yang selesai dalam jendela waktu yang dihitung sebagai cached. Yang lainnya langsung dihapus lagi dan grab-nya ditolak, sehingga Sonarr lanjut ke rilis berikutnya dalam daftarnya. Konsekuensinya, kalau torrent tidak ada di cache pada ketiga layanan ini, sekarang tetap memakai satu slot add, padahal sebelumnya pengecekan cache tidak memakan slot sama sekali.

## Kunci cadangan AllDebrid tidak lagi menjawab untuk library kamu {#an-alldebrid-backup-key-no-longer-answers-for-your-library}

`download_tokens` di akun AllDebrid itu adalah akun AllDebrid terpisah, yang disimpan untuk jatah unduhannya.
Begitu kunci akun utama mencapai batasnya dan keluar dari rotasi, setiap panggilan lain ikut dikirim lewat kunci cadangan juga: daftar magnet, daftar file sebuah rilis, add, delete, restart, tautan tersimpan di balik `__downloads__`, dan probe deteksi perubahan.
Jadi refresh library bisa mendaftar magnet milik akun cadangan dan menganggapnya milik kamu, delete bisa dikirim ke akun yang tidak pernah menyimpan magnet itu dan kembali seolah-olah sudah terhapus, dan begitu semua kunci kena batas, katalog mati total hanya karena ini sebenarnya cuma batas byte.
Sekarang hanya unlock tautan yang memutar kunci.
Semua yang berkaitan dengan akunmu sekarang ditanyakan ke akunmu sendiri.

## Rilis yang sehat tidak lagi bolak-balik masuk dan keluar dari daftar Broken {#a-healthy-release-stops-flapping-in-and-out-of-the-broken-list}

Sebuah release yang akunnya terus menawarkan satu link mati bisa nyangkut di daftar Broken di dashboard setengah dari setiap jam, padahal semua file di dalamnya bisa diputar dengan lancar. Repair menghapus link yang sudah menjawab `hoster_unavailable` selama tiga siklus supaya bisa memberi alamat baru untuk release itu, dan mengingat penghapusan tersebut supaya daftar berikutnya tidak memunculkan lagi link mati itu. Ingatan itu kemudian terhapus karena hal yang salah: repair apa pun yang selesai dengan baik akan menghapusnya, termasuk proses yang tidak menghasilkan apa-apa dan hanya memastikan alamat yang sudah dipegang entri itu masih bisa dibaca. "Archive yang menyediakannya masih bisa dibaca" adalah kasus paling ekstrem. Itu memang membuktikan satu link yang melayani release tersebut masih berfungsi, tapi sama sekali tidak mengatakan apa pun tentang link yang ditolak akun. Jadi penyerahan (give-up) itu terlupakan, refresh berikutnya mengadopsi lagi link mati yang sama, repair gagal menetapkannya lagi dan entri itu dicap gagal lagi, dan siklus tiga puluh menit ini tidak pernah berakhir. Diukur di library hidup selama tiga hari: satu release dicap gagal ulang 129 kali, ada 556 kali pencapan gagal di seluruh library dalam seminggu, dan setiap siklus menghabiskan dua sampai empat kali penambahan magnet. Sekarang, hanya repair yang benar-benar menetapkan ulang alamat release yang melupakan give-up. Repair manual tetap melupakan semuanya, jadi operator bisa mengembalikan link secara manual.

## Rilis yang disajikan sebagai satu arsip tidak lagi ditandai rusak di setiap sweep {#a-release-served-as-one-archive-is-no-longer-marked-broken-every-sweep}

Beberapa rilis disajikan sebagai satu arsip tunggal: file `.rar` membawa satu-satunya tautan akun, dan setiap episode di dalamnya tercantum sebagai file tersendiri tanpa tautan apa pun. Meski begitu, repair sweep tetap menanyakan akun tentang file-file di dalam arsip itu. Tidak ada yang bisa ditanyakan, jadi tidak ada akun yang dihubungi dan tidak ada yang diukur. Tapi jawabannya tetap muncul sebagai "file is broken", dan sweep menulis status itu ke setiap file lalu memakainya untuk menghukum seluruh rilis.

Akibatnya, dua kali magnet add terbuang. Akun diminta hanya untuk file yang rusak, lalu menjawab dengan tautan arsip tunggal yang sama seperti sebelumnya. Fallback arsip kemudian memverifikasi tautan itu dan memulihkan setiap file yang tadi sudah dihukum. Saat diuji di library yang hidup, 44 episode dari satu arsip 4,9 GB mengalami siklus ini setiap setengah jam.

Sekarang, file yang tidak punya tautan dari akun mana pun akan dibiarkan begitu saja. File arsip itu sendiri dinilai seperti sebelumnya. Jika tautan yang benar-benar melayani rilis itu berhenti bisa di-resolve, file tersebut ditandai broken, dan rilisnya ikut broken.

## Lalu lintas kembali ke token akun Anda sendiri begitu jatah kuotanya di-reset {#traffic-goes-back-to-your-own-accounts-token-once-its-allowance-resets}

Akun Real-Debrid yang sudah menghabiskan jatah hariannya akan memindahkan traffic-nya ke entri `download_tokens` pertama yang masih punya jatah. Watcher memasukkan kembali token akun itu ke rotasi begitu akun bisa mengirim byte lagi.

Tapi mendapatkan token kembali tidak otomatis mengembalikan traffic. Rotasi melanjutkan dari titik terakhir dia berhenti dan hanya mengecek apakah token itu sedang kena batas. Akibatnya, akun cadangan terus menerima semua byte sepanjang hari, padahal counter akun utama sudah di nol.

Sekarang urutan di `download_tokens` berfungsi sebagai preferensi, bukan posisi yang harus dilewati satu per satu. Token yang paling depan dan masih bisa melayani yang akan dipakai. Jadi akun utama kembali menerima traffic dalam waktu satu menit setelah counter-nya di-reset.

## Remote rclone yang mengarah ke alamat yang salah kini memberitahukannya {#an-rclone-remote-pointed-at-the-wrong-address-now-says-so}

Jika URL dari rclone WebDAV remote tidak memiliki `/dav/` di ujungnya, setiap listing gagal dengan "couldn't list files: 405 Method Not Allowed" dan tidak ada tempat yang menjelaskan alasannya. Dashboard tetap merespons normal di browser, jadi zurg terlihat sehat, dan log zurg sendiri diam tentang client yang gagal setiap beberapa detik. Sekarang zurg membalas request WebDAV yang datang di luar `/dav/` dengan alamat yang benar, yang akan ditampilkan rclone sebagai bagian dari error-nya sendiri, dan menulis satu peringatan yang menyebutkan client yang mengirimnya.

## Instalasi Windows kembali mengirim pemindaian ke media server {#windows-installs-now-send-media-server-scans-again}

Nilai `mount_path` `Z:`, yang ditulis oleh `zurg setup` di Windows, membuat path scan relatif terhadap direktori aktif di drive itu, bukan terhadap root-nya. Akibatnya, setiap path tidak cocok dengan section library yang seharusnya, sehingga tidak ada scan yang pernah dikirim. Peringatan yang muncul setelahnya meminta kamu memeriksa `mount_path` yang sebenarnya sudah benar. Config yang sudah ada tidak perlu diubah.

## Bulk scan membaca pustaka Plex sekali, bukan sekali per torrent {#bulk-scan-reads-the-plex-library-once-instead-of-once-per-torrent}

Pencocokan setelah bulk scan dari dashboard membaca ulang seluruh library Plex untuk setiap torrent dalam batch. Jadi, saat scan library yang besar, ratusan fetch library penuh yang identik dikirim ke server Plex yang biasanya sedang sibuk melakukan scanning.

## Path pustaka di Windows cocok tanpa memedulikan huruf besar atau kecil {#windows-library-paths-match-regardless-of-case}

A Plex, Jellyfin atau Emby library yang tercatat sebagai `Z:\Movies` tidak lagi terlewat dari `Z:\movies` yang dibuat zurg dari nama direktorinya sendiri. NTFS tidak membedakan huruf besar dan kecil, jadi keduanya menunjuk ke satu direktori yang sama. Pencocokan yang persis membuat scan dilewati dan melaporkan mount_path sebagai salah.

## File yang berhenti disajikan tidak lagi menghambat pemindaian Plex {#a-file-that-stops-serving-no-longer-stalls-a-plex-scan}

Sebuah file yang rusak tetap ada di daftar direktori dan membalas read dengan `503 File temporarily unavailable (being repaired)` sampai sesuatu mencabut status itu, yaitu selama repair berjalan, sampai repair selesai. Plex berhenti menunggu saat mendapat 503, jadi satu file seperti itu saja bisa menahan library scan, dan library yang punya banyak file seperti itu tidak pernah selesai di-scan sama sekali. Jellyfin melewatinya begitu saja dan terlihat baik-baik saja.

Itu dua keputusan yang terpisah, dan sekarang punya jawaban yang terpisah juga. Entry tetap ditampilkan selama file itu mungkin kembali, karena entry yang hilang dari folder dibaca oleh media scanner sebagai penghapusan dan item-nya akan dibuang ke trash. Itu tidak berubah. Yang berubah adalah cara read dijawab: read dijawab 503 selama satu menit setelah file berhenti melayani, dan 404 setelahnya. Satu menit adalah waktu yang masih bisa dipakai client, karena rclone mencoba ulang 503 dan menyerah pada read sekitar titik itu. Jadi gangguan singkat tetap teratasi dan read-nya berhasil. Setelah itu, 503 memang sudah menggagalkan read dan merugikan setiap scan di belakangnya.

Saya mengukurnya dengan Plex sungguhan pada library lima belas film, dengan sepuluh file ditolak dan semua file tetap terdaftar. Read yang menjawab 404 menyelesaikan scan dalam 5 detik. Sedangkan 503 yang tidak pernah dicabut hanya menemukan tiga dari lima belas film ketika run dihentikan paksa pada menit kesepuluh.

## Job SABnzbd baru tidak lagi menunggu di belakang pemeriksaan ukuran seluruh pustaka {#new-sabnzbd-jobs-no-longer-wait-behind-a-full-librarys-size-checks}

Saat zurg restart dengan library Usenet yang besar, zurg langsung mengantrekan pengecekan ukuran untuk setiap rilis dan lupa mana pengecekan yang gagal dan masih berada dalam jeda coba ulang satu jam. Akibatnya, rilis baru yang baru diambil bisa tertahan di belakang ribuan pengecekan latar belakang, sementara Sonarr atau Radarr menunggu ukuran file yang tepat. Sekarang pengecekan ukuran memakai antrean worker tetap, rilis yang punya job SABnzbd sedang menunggu akan dipindahkan ke depan, dan pengecekan yang sudah selesai serta jeda coba ulang tetap tersimpan setelah restart di `data/nzb-sizes/`. Selama ada pekerjaan dalam antrean, zurg melaporkan jumlah yang menunggu, prioritas klien, dan yang sedang berjalan setiap satu menit.

## Download yang tidak pernah dibersihkan client tidak lagi menghentikan impor download baru {#downloads-a-client-never-clears-no-longer-stop-new-ones-from-being-imported}

zurg menampilkan ke Sonarr, Radarr, dan download client lain sebuah halaman berisi download yang sudah selesai, dan menyimpan setiap item di halaman itu sampai client menghapusnya. Client hanya menghapus item yang sudah mereka impor atau gagal, jadi impor yang mereka blokir, misalnya judul yang tidak bisa mereka cocokkan, akan tetap ada di halaman selamanya. Begitu halaman penuh dengan item-item seperti itu, setiap download baru yang selesai menunggu dalam antrean dan tidak pernah diimpor. Download yang sudah sepuluh menit di halaman tanpa dihapus sekarang memberi tempatnya kepada download yang sedang menunggu, sama seperti SABnzbd menghapus baris lama dari halaman history-nya ketika baris baru masuk. Tidak ada yang berubah selama halaman masih punya ruang, dan mengambil ulang sebuah release akan memberinya tempat sendiri.

## Download yang dicari berdasarkan id-nya langsung ditemukan begitu selesai {#a-download-looked-up-by-its-id-is-found-as-soon-as-it-finishes}

Tool yang menanyakan zurg tentang satu unduhan per waktu berdasarkan id-nya, seperti LazyLibrarian, sekarang langsung diberi tahu bahwa unduhan itu sudah selesai begitu memang sudah selesai, meskipun halaman unduhan yang selesai yang dibaca Sonarr dan Radarr sedang penuh. Sebelumnya, unduhan seperti itu bisa terlihat belum selesai bagi mereka sampai ada tempat di halaman tersebut yang kosong.

## Perbaikan season kini punya halaman di dashboard {#season-fix-has-a-page-in-the-dashboard}

Penggantian nama seluruh library yang merapikan episode bernomor fansub agar sesuai nama yang dibaca Plex sudah bisa diakses lewat dua endpoint HTTP sejak dirilis: `/torrents/season-fix/plan` dan `/torrents/season-fix/apply`. Tidak ada kontrolnya di dashboard, dan hanya dijelaskan dalam satu paragraf di referensi penamaan. Fitur yang tidak bisa ditemukan sama saja tidak ada. Padahal bulan ini ada orang di channel wishlist yang memintanya, tanpa tahu bahwa fitur itu sudah dibuat.

`/season-fix/` sekarang menjelaskan apa yang dilakukan proses ini. Halaman ini menampilkan bentuk kanonis yang dihasilkan, dibandingkan dengan nama fansub yang digantikan. Halaman ini juga menjelaskan dari mana struktur musim berasal: dari penyedia metadata Plex sendiri, bukan dari library lokal, karena library yang musimnya sudah tergabung adalah hal yang sedang diperbaiki. Halaman ini juga mencantumkan apa saja yang tidak akan disentuh mapper dan alasannya. Hasil pemindaian yang hampir kosong adalah tanda bahwa cara konservatif ini bekerja dengan benar, bukan error.

Pemindaian tetap dijalankan lewat tombol. Proses planning memeriksa setiap torrent dan menanyakan Plex untuk setiap serial yang cocok, jadi membuka halaman ini tidak langsung memulainya. Hasil dikelompokkan per serial, dengan setiap penggantian nama ditampilkan dari nama lama ke nama baru, dan file yang dilewati ada di bagian yang bisa dibuka. Entri yang ditandai sebagai kemungkinan salah kecocokan serial akan tampil dalam keadaan tidak dicentang, dan konfirmasinya juga menyebutkan hal itu. Dengan begitu, saat semuanya diterapkan sekaligus, tidak ada rilis yang cocok dengan serial yang salah diganti namanya secara diam-diam.

## Putar rilis terkompresi yang terbagi ke beberapa volume {#play-a-compressed-release-that-is-split-across-several-volumes}

A release that was packed with compression rather than stored whole stopped at the end of its first volume. Every file inside it listed with the right name and size and then refused to play, leaving a bad header CRC in the log. zurg now carries the unpacking across each volume join, so these releases play from start to finish.

## Startup lebih cepat saat akun Anda menyimpan torrent yang gagal {#start-up-quickly-when-your-account-holds-failed-torrents}

Setiap kali library di-refresh, zurg memeriksa ulang setiap torrent yang oleh layanan debrid Anda ditandai sebagai gagal, satu per satu, padahal layanan itu hanya mengizinkan beberapa permintaan per detik. Pada akun yang memiliki beberapa ratus torrent seperti itu, proses ini saja memakan waktu lebih dari satu menit, setiap kali refresh, dan library Anda tidak bisa dibaca selama itu setiap kali dimulai. Waktu selama itu cukup bagi Plex untuk memindai folder yang belum ada lalu menandai semua isinya sebagai tidak tersedia. Sekarang zurg membaca informasi yang sudah ia ketahui tentang torrent gagal dari disk, dan hanya menanyakan ulang ke layanan ketika layanan menyatakan torrent tersebut sudah tidak gagal lagi.

## Berhenti meminta ulang ke AllDebrid tentang magnet yang sudah mereka tolak untuk dicoba lagi {#stop-re-asking-alldebrid-about-magnets-it-has-already-refused-to-retry}

Ketika magnet gagal, zurg meminta AllDebrid untuk mengambilnya lagi. AllDebrid menolak
beberapa di antaranya, dan penolakan itu tidak dihitung ke dalam dua percobaan
yang diberikan untuk setiap torrent. Akibatnya, magnet yang sama terus ditanyakan setiap
kali library di-refresh selama zurg berjalan. Sekarang jawabannya diingat selama
satu jam, beserta status yang diberikan akun tersebut, jadi magnet yang berubah akan
ditanyakan lagi. Jumlah percobaan juga disimpan ke disk, sehingga tidak lagi
dilupakan setiap kali restart dan dihitung ulang dari awal.

## Jaga link tetap stabil untuk rilis yang ada dua kali di akun Anda {#keep-the-link-steady-for-a-release-your-account-holds-twice}

A release added twice to one account has two of everything, including two download links per file. zurg kept one link per account, so each copy replaced the other's on every refresh and the entry never settled. Nothing was unplayable, but the log filled with re-pointing and the library was rewritten to disk every few seconds. zurg now leaves the link alone when it can only see part of what the account holds.

Sebuah rilis yang ditambahkan dua kali ke satu akun akan punya dua dari segalanya, termasuk dua tautan unduhan untuk setiap file. zurg hanya menyimpan satu tautan per akun, jadi setiap salinan menggantikan tautan milik salinan lain pada setiap refresh dan entri itu tidak pernah stabil. Tidak ada yang tidak bisa diputar, tetapi log penuh dengan pengarahan ulang dan library ditulis ulang ke disk setiap beberapa detik. Sekarang zurg membiarkan tautan itu tetap apa adanya ketika ia hanya bisa melihat sebagian dari isi akun.

## Pengecekan perubahan di TorBox lebih cepat saat akun menyimpan torrent yang gagal {#faster-change-checks-on-torbox-when-the-account-holds-failed-torrents}

TorBox tidak punya cara untuk menanyakan apakah sebuah akun berubah, jadi zurg membaca halaman kecil berisi torrent terbaru dan memantau torrent yang belum selesai. Torrent yang gagal di TorBox tidak pernah selesai, jadi satu kegagalan lama membuat setiap pengecekan membaca halaman yang jauh lebih besar, terus-menerus selama akun itu ada. Torrent yang gagal sekarang tidak lagi dipantau untuk perubahan yang memang tidak mungkin terjadi.

## Rilis yang tidak bisa diimpor *arr Anda tidak lagi dihapus oleh percobaan tersebut {#a-release-your-arr-could-not-import-is-no-longer-deleted-by-the-attempt}

Ketika zurg menolak memindahkan rilis keluar dari folder staging Usenet karena rilis tersebut tidak bisa dibaca dari news server, Sonarr dan Radarr tidak begitu saja menyerah. .NET menangani pemindahan yang gagal dengan menyalin file lalu menghapus file aslinya, dan zurg ikut menjalankan penghapusan itu, sehingga rilisnya hilang dan sebuah file kosong tertinggal di tempat file tersebut diimpor. Penghapusan yang mengikuti pemindahan yang ditolak kini juga ditolak dengan alasan yang sama, dan rilisnya tetap berada di tempatnya.

## Pembacaan Usenet membedakan batch yang lambat dari yang macet {#usenet-reads-tell-a-slow-batch-from-a-stalled-one}

zurg meminta koneksi Usenet kedua untuk sebuah artikel ketika tunggunya sudah terlalu lama, lalu mengambil jawaban mana pun yang datang lebih dulu. Keputusan bahwa tunggunya sudah terlalu lama dulu diambil berdasarkan jam. Padahal batch yang berisi artikel-artikel besar di akun cepat yang wajar, diminta dua kali selagi artikel pertamanya masih datang.

Sekarang keputusan itu diambil berdasarkan byte yang datang. Koneksi Usenet sudah memperbarui timeout-nya setiap kali ada byte masuk, dan pembaca juga ikut melihat bukti itu. Batch yang sedang di tengah artikel besar dibiarkan saja, berapa lama pun artikel itu butuh waktu. Hanya batch yang byte-nya sudah berhenti yang diminta dari tempat lain.

Ketika sebuah koneksi mengambil sekumpulan artikel lalu tidak menjawab satu pun, zurg langsung meminta sisa batch itu dari koneksi lain sekaligus, bukan mencari tiap artikel yang hilang satu per satu. Koneksi yang diam tidak pernah diputus, jadi artikelnya tetap dihitung kalau akhirnya datang. Hanya artikel yang benar-benar tidak datang yang diminta ulang, paling banyak sekali per batch. Artikel yang paling dekat dengan posisi putar didahulukan, dan satu permintaan kedua selalu disisakan, supaya pembacaan berikutnya yang diam di tempat tetap bisa meminta artikelnya sendiri.

Sebuah pembacaan juga tidak lagi menganggap waktu yang dihabiskan untuk permintaan kedua sebagai kecepatan normalnya. Yang dipelajarinya hanyalah waktu tunggu yang bersedia dijalani zurg, tidak lebih. Di akun yang setiap artikelnya wajar membutuhkan satu detik atau lebih, ambang batasnya sekarang menetap di dekat kecepatan yang benar-benar dikirim akun itu, bukan turun ke pengaturan terpendeknya dan meminta dua kali untuk sebagian besar artikel.

## Read-ahead Usenet menjaga jendelanya tetap penuh di seluruh artikel dan volume {#usenet-read-ahead-keeps-its-window-full-across-articles-and-volumes}

Read-ahead dulu berhenti meminta byte baru selama artikel sebelumnya masih terlambat, jadi satu artikel yang lambat menghabiskan jendela yang sudah dibangun. Sekarang zurg tetap menjaga jendela byte yang diminta dengan batas tertentu selama transfer berlangsung, dan satu batch artikel bisa melintasi sambungan antara dua volume RAR yang tersimpan, alih-alih berhenti di titik sambungan itu.

Jendela ini memakai paling banyak seperempat dari cache RAM yang kamu atur, dan tidak pernah lebih dari 128 MiB, jadi cache yang lebih kecil akan mendapat jendela yang lebih kecil juga. Setiap permintaan tetap mengikuti pembatalannya sendiri serta batas koneksi dan cache dari akunmu.

## Pemutaran Usenet memakai CPU lebih sedikit di prosesor lama {#usenet-playback-costs-less-cpu-on-older-processors}

Read cache memberi checksum pada setiap record yang disimpannya. Pada prosesor Intel dan AMD yang punya SSE4.1 tapi tidak punya AVX, SHA-256 berjalan tanpa bantuan hardware sama sekali, dan biaya itu terasa saat playback. Sekarang zurg memakai checksum 256-bit yang lebih cepat di prosesor tersebut. Setiap record membawa versi, jadi kerusakan tetap terdeteksi, cache yang sudah ada tetap bisa dibaca, dan prosesor lain tetap memakai SHA-256.

## NZB yang dibagikan tidak lagi mengarah kembali ke akun yang mengambilnya {#nzb-shares-no-longer-point-back-to-the-account-that-grabbed-them}

Beberapa indexer memberi setiap unduhan detail yang bisa mengarah kembali ke akun Anda, dan sebagian dari detail itu ada di kolom yang disimpan share. Satu indexer menyisipkan token baru di judul rilis dan sering juga di password, lalu mengganti poster, tanggal, dan newsgroup di setiap file. Indexer lain menaruh nomor akun Anda di depan subjek salah satu file. Indexer ketiga menaruh penanda akun di setiap poster. `zurg nzb-share` sekarang menghapus poster dan tanggal, memberi setiap file newsgroup tetap yang sama, memotong stempel di subjek, dan mengabaikan token di mana pun letaknya. Kalau nama dan judul tidak cocok, nama yang dipakai. Dua orang yang mengambil rilis yang sama sekarang mempublikasikan file yang sama. Share juga tidak lagi melewatkan NZB yang disimpan dengan encoding Latin-1, dan tidak lagi menggandakan backslash yang kadang ada di subjek.

Apa saja yang dihapus oleh proses pembersihan ada di [`zurg nzb-share`](cli.md#zurg-nzb-share).

## Pustaka lokal kini menambahkan hash di AllDebrid, Premiumize, dan Offcloud {#local-libraries-add-the-hash-on-alldebrid-premiumize-and-offcloud}

Perpustakaan lokal yang manifest-nya tidak punya tautan portabel akan menambahkan hash ke akunmu saat pertama kali diputar. Manifest yang diekspor dari TorBox selalu seperti itu. Begitu juga manifest yang tautan AllDebrid-nya sudah kedaluwarsa. Di AllDebrid, Premiumize, dan Offcloud, setiap pemutaran seperti itu gagal dengan pesan "provider did not report an active torrent allowance". zurg meminta akun melaporkan batas slot torrent-nya sebelum menambahkan. Ketiga provider itu tidak pernah melaporkannya. Sekarang zurg kembali ke jumlah slot yang dideklarasikan, sama seperti cara repair bekerja. Jika keduanya tidak ada, zurg tetap menambahkan hash dan membiarkan provider menolak akun yang penuh.

## File Offcloud kini melaporkan durasinya {#offcloud-files-report-their-length}

Saat me-resolve file Offcloud, panjang filenya tidak terisi. Library lokal memeriksa panjang itu terhadap manifest-nya. Akibatnya, setiap pemutaran Offcloud ditolak dengan pesan "resolved file size does not match the portable manifest". Pemutaran biasa juga kehilangan penanganan range yang membutuhkan panjang. Sekarang zurg meminta panjang ke delivery server dengan cara yang sama seperti yang sudah dilakukan daftar Offcloud.

## zurg berjalan di ponsel Android dan Google TV {#zurg-runs-on-android-phones-and-google-tv}

Aplikasi Android baru menjalankan perpustakaanmu langsung di perangkat itu sendiri. Aplikasi ini menyesuaikan diri dengan ponsel, tablet, Android TV, dan Google TV. Aplikasi ini butuh Android 8.0 atau yang lebih baru, dan Usenet butuh Android 64-bit. Aplikasi akan memandumu mengatur akun penyedia dan profil perangkat, lalu memulai perpustakaan. Kamu bisa menjelajahinya di dalam aplikasi atau lewat Files milik Android, lalu memutarnya di pemutar eksternal pilihanmu dengan seeking penuh. Remote TV bisa dipakai untuk mengontrol setiap layar. MediaInfo berjalan di perangkat tanpa alat tambahan. Perpustakaan juga bisa dibagikan ke perangkat lain di jaringan lokalmu, dilindungi kata sandi. Kata sandi itu tidak pernah dikirim ke pemutar.

APK-nya ada di rilis nightly untuk sponsor. Aplikasi ini tidak membawa zurg sendiri. Setelah kamu masuk ke GitHub, aplikasi akan memasang mesin zurg sebagai paket kedua. Aplikasi dan mesin diperbarui secara terpisah. Updates menampilkan setiap versi mesin yang masih dipublikasikan, sehingga nightly yang bermasalah di perangkatmu bisa dikembalikan ke versi yang sudah berfungsi. Siapa pun yang sudah memasang build Android pertama perlu memasang mesin dari Updates sekali saja. Penyedia dan pengaturan perpustakaan tetap terbawa dan tidak berubah.

Mesin untuk perangkat ARM 64-bit sekarang mencari alamat penyedia lewat resolver bawaan Android. Mesin di build pertama bisa gagal menjangkau penyedia sama sekali.

Panduan pengaturan dan catatan pemutar ada di [Android](../guides/android.md).

## NZB baru muncul di pustaka dalam hitungan detik {#a-new-nzb-shows-up-in-the-library-within-seconds}

Dulu, NZB yang masuk ke watch directory harus menunggu pengecekan perubahan berkala berikutnya. Setelah itu, release yang terobfuskasi masih harus menunggu satu interval lagi sampai nama file aslinya dibaca. Dengan interval default, totalnya bisa mencapai 20 sampai 30 detik, dan selama itu grab di Sonarr atau Radarr terus berstatus Queued.

Sekarang zurg mengecek watch directory sendiri setiap detik. Cara ini tidak bergantung pada filesystem events, jadi hasilnya sama saja di NAS maupun di dalam container. Sebuah release langsung ditampilkan begitu nama-namanya sudah terbaca. Season pack berisi dua puluh release tetap hanya butuh satu kali listing. Pengecekan berkala tetap dipertahankan sebagai cadangan untuk NZB yang diganti dengan nama yang sudah pernah ada.

## Stream Usenet tetap menjaga kecepatannya {#usenet-streams-hold-their-speed}

File di dalam set RAR sampai ke akun news satu volume demi satu. zurg membuka volume berikutnya lebih awal supaya perpindahan antarvolume tidak mulai dari kondisi dingin. Dulu zurg hanya memanaskan empat megabyte pertama. Pada rilis yang dipecah menjadi volume kecil, itu berarti ada batas volume setiap satu atau dua detik pemutaran dan macet di setiap batas. Salah satu rilis seperti itu hanya bisa distreaming dengan kecepatan 14 sampai 16 MB/s, padahal file biasa di akun yang sama berjalan di 86 sampai 99 MB/s. Sekarang volume berikutnya dipanaskan sepenuhnya sedalam satu jendela read-ahead begitu stream sudah berada dalam jarak 32 MiB darinya. Volume yang baru saja dimasuki stream tetap mempertahankan read-ahead yang sudah didapatnya. Volume yang tidak sedang didekati tetap hanya dipanaskan di bagian kepalanya. Dengan begitu, pemindaian library tidak menarik data yang tidak akan pernah dibaca.

Saat streaming biasa, sekitar satu detik dari setiap dua puluh detik dulu habis karena satu artikel yang lambat, sementara semua koneksi lain harus menunggu di belakangnya. Sekarang zurg meminta artikel itu ke koneksi kedua begitu waktu tunggunya sudah terlalu lama, lalu memakai jawaban mana pun yang datang lebih dulu. Ini hanya dilakukan untuk pembacaan yang sedang ditunggu pemutar. Read-ahead dan repair tidak pernah digandakan. Jumlah permintaan tambahan dibatasi dua puluh per menit per akun.

Pembacaan yang sedang ditunggu pemutar sekarang didahulukan di lebih banyak tempat. Read-ahead tidak lagi mengambil koneksi bebas terakhir milik akun. Tahap penentuan ukuran saat startup juga menyisakan satu koneksi bebas. Sebuah pembacaan memakai koneksi yang sudah dimiliki akun, bukan membuka koneksi sendiri. Pembacaan itu menunggu koneksi yang sedang dibuka, daripada membayar untuk membuka koneksi lain. Artikel yang sedang ditunggu pemutar boleh mendahului permintaan antre untuk byte yang lebih jauh. Dalam satu pengukuran, byte pertama dari sebuah pembacaan tiba dalam 177 ms, bukan 354 ms. Pemanasan, keep-alive, dan pembacaan sekarang juga berbagi satu batas koneksi. zurg tidak pernah membuka lebih banyak koneksi daripada yang diizinkan akun.

Menyimpan artikel yang sudah didekode ke disk cache tidak lagi menahan pembacaan yang mengambil artikel tersebut. Dulu penulisannya berada di dalam kunci yang dibutuhkan semua pembacaan lain. Sekarang penulisan dilakukan setelah byte sampai ke pemutar. Jika ada lonjakan yang lebih besar daripada yang bisa dikejar cache, zurg melewati catatan tambahan itu daripada memperlambat pemutaran. Cache yang sudah ada tetap dipakai apa adanya.

## Sonarr dan Radarr berhenti menunggu grab yang tidak akan pernah selesai {#sonarr-and-radarr-stop-waiting-on-grabs-that-can-never-finish}

Endpoint SABnzbd dulu kadang membiarkan beberapa job antre selamanya. Client tidak pernah memasukkannya ke blocklist dan tidak pernah mengambil release lain. Setiap kasus di bawah sekarang dilaporkan sebagai Failed beserta pesan yang menjelaskan alasannya. Failed itulah yang membuat Sonarr dan Radarr memasukkan release ke blocklist lalu mencari lagi.

Release bisa keluar dari library setelah di-grab. Bisa jadi dihapus dari dashboard, dibuang dari watch directory, atau dihapus oleh semua akun. Dulu job-nya diam di 0% dan tidak ada yang bakal menggerakkannya. Sekarang job akan Failed begitu release sudah hilang selama lima belas menit. Tidak ada yang Failed dalam lima belas menit pertama setelah restart, selama library masih dimuat.

Grab bisa jatuh pada release yang sudah dikosongkan oleh import sebelumnya. Ini terjadi saat upgrade menghapus file hasil import, lalu search memilih release yang sama lagi. Dulu zurg menjawab Completed dan mengarahkan client ke folder yang sudah kosong. Sekarang grab ulang pada release yang sudah dikosongkan langsung Failed. Folder yang tetap kosong selama lima belas menit juga membuat job-nya Failed. Ini mencakup folder yang dikosongkan lewat pemindahan manual, atau lewat import yang dicatat di job lain. Grab yang melakukan import tetap menampilkan Completed selama proses itu selesai.

Ada release yang tidak pernah selesai dicek artikelnya. zurg menanyakan ke news server apakah artikel milik release itu masih ada sebelum melaporkan grab selesai. Dulu pengecekan yang gagal selesai diulang setiap menit tanpa henti. Sekarang job akan Failed setelah tiga puluh percobaan berturut-turut yang rentangnya minimal tiga jam. Akun news yang mati selama satu jam tidak membuat semua job yang menunggu ikut masuk blocklist. Pengecekan yang akhirnya berhasil menjawab akan mereset hitungan.

Ada release yang tidak punya arsip lengkap. Satu set bisa tidak punya volume yang berisi awal file. Bisa juga hilang satu volume di tengah. Atau mulainya bukan dari volume pertama. Dulu Sonarr diarahkan ke folder yang tidak pernah bisa diimpor, dan Sonarr terus mencobanya selamanya. Sekarang grab akan Failed. Keputusan ini terikat pada volume persis yang dipakai saat dicapai. Perbaikan PAR2, grab ulang, atau akun kedua yang punya volume yang hilang akan membuat release ini dinilai ulang.

## Token unduh cadangan mengambil alih saat jatah harian habis {#backup-download-tokens-take-over-when-the-daily-allowance-runs-out}

Real-Debrid menolak unduhan begitu sebuah token sudah menghabiskan kuota hariannya. zurg seharusnya membuang token itu dan pindah ke entri berikutnya di `download_tokens`. Hal ini berhenti terjadi saat playback, ketika proxied streams pindah ke HTTP client baru. Penolakannya datang sebagai respons biasa dan tidak ada yang menandai token itu sebagai sudah habis. Akibatnya, semua token cadangan menganggur dan setiap pembacaan terus memakai token yang kuotanya sudah habis.

Penolakan sekarang dikenali di mana pun zurg menemuinya. Itu berarti saat playback, dan juga di refresh loop dan repair. Keduanya mengecek link baik ada yang sedang diputar atau tidak. Penolakan yang datang tanpa header biasa dari Real-Debrid juga sekarang membuang token itu.

Token yang sudah dibuang diuji sekali per menit supaya bisa kembali segera setelah kuotanya terisi lagi. Dulu tes itu memakai link yang di-cache di bawah token yang dibuang itu sendiri. Tidak ada yang mengisi ulang cache itu setelah token berhenti melayani, jadi tes tidak menemukan apa-apa dan token tetap tidak dipakai sampai reset malam atau restart. Sekarang tes meminjam link dari token mana pun yang masih melayani.

Reset harian dulu terlambat satu hari. Real-Debrid mereset kuota beberapa menit setelah tengah malam CET. zurg melewatkan tengah malam pertama setiap kali start dan baru reset di tengah malam kedua. Akun yang sudah menghabiskan kuotanya tetap dilayani dari token cadangan selama sehari lagi. zurg juga menghitung tengah malam itu dari tanggal di host, sehingga di wilayah barat Eropa reset jatuh pada jam berapa pun zurg kebetulan dijalankan. Sekarang setiap reset dijadwalkan berdasarkan tanggal dalam CET.

## Grab magnet tetap menyimpan nama rilisnya di akun debrid {#a-magnet-grab-keeps-its-release-name-on-the-debrid-account}

Sonarr dan Radarr memberikan seluruh magnet dari indexer ke endpoint qBittorrent. Dulu zurg memotongnya menjadi info hash saja sebelum menambahkannya. Display name dan trackers tidak pernah sampai ke akun. Pada indexer yang hanya memberikan magnet, display name adalah satu-satunya tempat nama rilis tersimpan. Torrent yang belum di-cache lalu muncul di daftar akun dengan hash 40 karakter. Untuk torrent yang tidak ada yang seed, itu satu-satunya nama yang pernah didapatnya.

Sekarang magnet sampai ke akun persis seperti yang dikirim client. Repair, Plex watchlist, dan portable library tetap hanya menambahkan hash kosong karena mereka tidak punya nama untuk diteruskan.

## Dump .strm hanya berisi file yang bisa dibuka pemutar {#the-strm-dump-holds-only-files-a-player-can-open}

`save_strm_files` dulu menulis `.strm` untuk setiap file terpilih dalam sebuah rilis. Subtitle, poster, NFO, dan volume PAR2 ikut jadi entri pustaka yang kalau dibuka tidak menampilkan apa-apa. TorBox dan AllDebrid menandai semua file sebagai terpilih. Post Usenet dengan file perbaikannya di samping video juga begitu. Sekarang hanya video dan audio yang dikenali yang dapat `.strm`, ditambah file apa pun yang disebut di `addl_playable_extensions`. Video di dalam set RAR tetap ditulis, sedangkan volume di sekitarnya tidak. Entri yang ditulis oleh build sebelumnya akan dihapus saat rilis itu dijelajahi lagi.

Beberapa jalur penulisan juga meminta media server untuk memindai sebelum file `.strm`-nya ada. Plex, Jellyfin, atau Emby bisa saja memeriksa folder yang kosong dan tidak mengindeks apa pun. Tidak ada yang memintanya memeriksa lagi sampai rilisnya berubah. Sekarang file ditulis dulu di setiap jalur.

## Memindahkan folder zurg tidak lagi membuat cache mount tertinggal {#moving-the-zurg-folder-no-longer-strands-the-mount-cache}

Cache rclone mount menyimpan apa yang dibacanya di `data/rclone-cache`. rclone memberi nama cache itu sesuai konfigurasinya sendiri. Konfigurasi itu mencakup path lengkap folder `data/local` milik zurg. Memindahkan folder zurg atau mengubah `union_writable` membuat cache mendapat nama baru. Pohon lama tetap tersimpan di disk, tempat batas ukuran tidak menghitungnya dan tidak ada yang membersihkannya. Beberapa kali pindah bisa meninggalkan sampai terabyte.

Saat mount dimulai, zurg sekarang meminta rclone untuk mengecek pohon cache mana yang aktif, lalu menghapus yang lain. Zurg mencatat berapa banyak ruang yang dibebaskan. Pembersihan dilewati jika `rclone_extra_args` sudah mengatur `--cache-dir` sendiri. Atur `rclone_cache_reclaim: false` jika Anda ingin menyimpan pohon lama.

Cache yang aktif juga lebih besar dari perkiraan kebanyakan orang. Ukurannya naik sampai 256G secara default dan tetap di situ. Proses malam hari di media server menyentuh setiap file, jadi batas usia 72 jam hampir tidak pernah menghapus apa pun. Rencanakan dengan batas ukuran. Cara menurunkannya ada di [the configuration reference](config.md#disk-the-mount-uses).

## Poster dan file .nfo terus masuk ke `__magic__` {#posters-and-nfo-files-keep-landing-in-__magic__}

Klien yang menulis lewat mount zurg menaruh file baru di `data/local`. Itu folder tempat `__magic__` menyimpan sidecar-nya. zurg menghitung setiap file di sana terhadap `sidecar_budget_mb`. Beberapa video yang ditulis \*arr lewat mount bisa menghabiskan seluruh anggaran. Setelah itu, setiap .nfo dan poster ditolak seolah-olah foldernya penuh. Menaikkan anggaran juga tidak pernah membantu.

File yang lebih besar dari `sidecar_max_mb` tidak mungkin datang lewat jalur sidecar zurg. File-file itu sekarang tidak lagi dihitung terhadap anggaran. zurg akan menyebutkannya sekali saat startup, karena file-file itu tetap memakan ruang disk.

Menghapus path `__magic__` yang sudah tidak ada sekarang berhasil. Mount bisa menghapus sidecar bersama dari kedua sisinya tanpa merusak pembersihan impor.

## Pemutaran Stremio mencoba rilis berikutnya saat yang pertama sudah tidak tersedia {#a-stremio-play-tries-the-next-release-when-the-first-has-aged-off}

Dulu, satu klik Stremio hanya mencoba satu rilis. Kalau rilis itu tidak berisi apa pun yang bisa diputar, pemutaran gagal dengan 404. Penyebab umumnya adalah posting yang sudah hilang dari news server. Daftar stream sebenarnya mungkin menampilkan belasan rilis lain.

Sekarang, saat pemutaran ditolak, sistem mencoba hingga dua baris lagi dari daftar berperingkat yang sama. Percobaan dimulai dari baris setelah yang kamu pilih. Jadi cadangannya adalah resolusi yang sama dan ukuran lebih kecil, atau tingkat di bawahnya. Tidak pernah rilis yang lebih besar yang tadi kamu lewati. Rilis yang masih diambil tetap menjawab 503 seperti sebelumnya, dan menekan play lagi akan mengambilnya. Setiap percobaan memakai satu indexer grab dan rilis tersebut tetap ada di library. Play link yang dibuat sebelum perubahan ini tetap berjalan seperti biasa.

## Daftar Stremio menampilkan setiap resolusi dan berbagai ukuran {#stremio-lists-show-every-resolution-and-a-spread-of-sizes}

Batas jumlah stream dulu dihitung untuk seluruh daftar. Hasil 4K selalu tampil paling atas, dan judul yang populer punya lebih banyak hasil seperti itu daripada batasnya. Akibatnya, daftar bisa penuh dengan remux 20 sampai 40 GB dan menyembunyikan semua rilis 1080p dan 720p yang ditemukan pencarian.

`stremio.max_results` sekarang dihitung per resolusi dan default-nya 5. Nilai yang kamu atur sendiri tetap angkanya, tapi sekarang berlaku untuk tiap resolusi.

Dalam satu resolusi, daftar dulu hanya menyimpan rilis yang paling besar. Encode 4 GB yang bisa diputar di HP atau laptop justru yang terpotong. Sekarang tiap resolusi menyimpan pilihan dengan jarak yang merata, mulai dari rilis terbesar sampai yang terkecil. Kedua ujungnya selalu disertakan.

Deskripsi tiap stream sekarang diakhiri dengan berapa lama lalu rilis itu diposting. Tampilannya `3d`, `126d`, atau `2y`. Umur rilis adalah petunjuk terbaik bahwa postingan mungkin sudah hilang dari news server. Hasil yang di-cache sebelum perubahan ini tidak menampilkan umur sampai cache judul tersebut diperbarui.

Manifest addon sekarang memuat versi build yang sebenarnya, bukan `0.1.0`. `zurg --version` mencetak detail build yang sama dengan `zurg version` dan tidak membutuhkan file config.

## Rilis yang sehat tidak lagi hilang dari pustaka {#healthy-releases-stop-disappearing-from-the-library}

A kegagalan koneksi atau pencarian DNS ke API Real-Debrid sekarang menandai akun sebagai sementara tidak tersedia. Dulu, cara ini menandai file yang sehat sebagai rusak. File tersebut kemudian menunggu perbaikan setelah jaringan kembali normal.

Pembersihan setelah library refresh dulu menunggu analisis media di latar belakang. Saat pembersihan berjalan, refresh yang lebih baru mungkin sudah menambahkan kembali sebuah release. Pembersihan yang terlambat itu lalu menghapusnya lagi. Sekarang pembersihan selesai sebelum refresh kembali. Analisis media tetap berjalan di latar belakang.

## Kodi bisa menelusuri share WebDAV {#kodi-can-browse-the-webdav-share}

WebDAV listing sekarang memberikan path lengkap untuk setiap folder dan file, termasuk awalan `/dav/`. Kodi dan pemutar lain yang ketat dulu menghapus awalan itu sehingga tidak bisa membuka folder atau media. Nama dengan karakter yang di-escape dan path di dalam arsip tetap menyimpan alamatnya.

## Server berita yang sibuk tidak lagi membuat lubang di stream {#a-busy-news-server-no-longer-puts-holes-in-a-stream}

Sebuah news server bisa menjawab "no such article" untuk artikel yang sebenarnya ia punya, saat sedang sibuk. Dulu zurg mengecek ulang jawaban itu beberapa ratus milidetik kemudian lewat koneksi yang sama. Setelah itu zurg menyajikan rentang tersebut sebagai nol dan menganggap artikelnya hilang selama sehari. Satu read 32 MiB pernah kembali dengan 384.000 byte nol, padahal artikel itu ternyata disajikan dengan benar satu menit kemudian.

Sekarang, artikel yang ditolak akan ditanyakan sekali lagi, satu detik kemudian. Pertanyaan kedua dikirim lewat koneksi lain yang sedang kosong. Read menunggu jawaban itu alih-alih langsung mengisi celahnya. Artikel yang memang sudah hilang tetap disajikan sebagai data kosong dan diperbaiki seperti sebelumnya. Jadi, release yang rusak butuh sekitar satu detik lebih lama untuk sampai ke data kosong itu.

Artikel yang koneksinya diam juga sekarang ditanyakan ulang sekali lewat koneksi lain. Dulu, hal ini membuat seluruh respons gagal. Sebuah stream RAR pernah menjawab 500 untuk artikel yang sebenarnya hanya lambat dikirim oleh provider.

## Pilih cara zurg mengidentifikasi dirinya ke layanan yang dihubunginya {#choose-how-zurg-identifies-itself-to-the-services-it-calls}

Permintaan ke layanan debrid dan indexer sekarang memakai User-Agent browser umum secara default. Pencarian subtitle juga memakai itu dan tidak lagi mengirim `zurg v0`. Permintaan tersebut juga tidak mengirim header origin dan referrer, begitu pula header milik zurg sendiri. Ini tetap berlaku saat ada redirect. Redirect tidak bisa membocorkan path pribadi atau API key dari URL sebelumnya.

`user_agent` mengatur agent yang berbeda, dan `omit_user_agent` tidak mengirim agent sama sekali. Kunci `outbound_*` mengatur nama client dan device yang dilihat Plex, Jellyfin, dan Emby. Semua pengaturan ini ada di dashboard di bawah Network & Connectivity dan baru berlaku setelah restart. Koneksi Usenet tidak mengirim identifier software sama sekali. Ini menghapus identifier milik zurg sendiri. Ini tidak membuat kamu jadi anonim.

Detailnya ada di [Identitas keluar](outbound-identity.md).

## zurg mengosongkan sampah Plex secara default {#zurg-empties-the-plex-trash-by-default}

zurg mematikan pengaturan Plex "Empty trash automatically after every scan". Kalau tidak, scan yang bertemu mount yang sebentar tidak bisa dibaca akan menghapus library, bukan menyimpannya dulu. Sisa yang tertinggal dari itu tidak ada yang sadar. Plex tidak lagi membersihkan entri yang sudah mati, dan penghapusan bawaan dari zurg harus diaktifkan secara manual. Jadi secara default tidak ada yang membersihkannya. Entri yang file-nya sudah lama hilang menumpuk. Kasus yang paling kelihatan adalah file yang dipindah antar folder library, dengan entri lama yang tetap ada selamanya.

Kalau `plex_trash_sweep_every_mins` tidak diisi, trash sweep sekarang berjalan setiap 60 menit. Ia berhenti sementara kalau Plex masih mengosongkan trash-nya sendiri. Ia menghapus satu entri sekali jalan, dan tidak pernah menghapus entri yang masih punya file. Ia hanya berjalan terhadap mount yang bisa dibaca. Apa pun yang tidak bisa ia nilai tetap terlihat sebagai rusak selama 14 hari dulu. Tulis `plex_trash_sweep_every_mins: 0` kalau mau penghapusan tetap mati dan kamu kosongkan trash sendiri.

Pengaturan itu tidak mengembalikan pengosongan trash ke Plex. Halaman config sekarang punya sakelar Let Plex Empty Its Own Trash untuk itu. Risikonya tertulis di sebelahnya.

Restore juga sudah bisa sekarang. Plex melewati scan biasa untuk folder yang sudah pernah di-scan. Serial yang masuk trash padahal file-nya sudah kembali bisa tetap di trash terus dari scan ke scan. Sweep sekarang meminta Plex untuk melakukan forced scan pada folder itu. Scan yang dimulai manual dari dashboard sekarang juga mencapai path `__magic__` tempat library Usenet diindeks. Dulu ia tidak menemukan section Plex dan tidak melakukan apa-apa.

Cara dua pembersih ini membagi tugas dijelaskan di [Plex](../guides/plex.md#who-empties-the-trash).

## Arsip yang rusak hanya menampilkan byte yang benar atau tidak sama sekali {#damaged-archives-list-the-right-bytes-or-nothing-at-all}

Beberapa set RAR yang rusak dulu mencantumkan video yang memutar byte yang salah. Set yang kehilangan satu volume di tengah menyajikan sisa file yang bergeser dengan ekor berisi nol. Set seperti itu sekarang ditolak. Set yang header pertamanya tidak bisa dibaca punya byte berikutnya yang bergeser. zurg sekarang membaca header lanjutan lebih dulu sehingga setiap offset tetap benar. File setelah film di volume terakhir juga tetap disimpan. Marker akhir RAR4 dulu salah dikira enkripsi. Set split dengan blok akhir yang diberi padding kehilangan volume pertamanya. Sekarang set itu mencantumkan video yang lengkap.

NZB dengan 10% atau lebih artikelnya hilang akan ditolak sebelum apa pun disajikan. Konten yang sudah dipulihkan oleh PAR2 tetap bisa diputar.

Daftar arsip yang sudah ada dibangun ulang sehingga perbaikan ini sampai ke rilis yang sudah ada di pustaka.

## Perpustakaan besar bisa mengembalikan memori yang menganggur {#large-libraries-can-give-idle-memory-back}

`library_detail` menentukan apakah daftar file setiap release tetap disimpan di memori. `resident` menyimpan semuanya dan tetap menjadi default. `lazy` melepas daftar file yang belum dibaca oleh siapa pun selama `library_detail_idle_secs`. Listing tetap tersedia, dan daftar file akan dimuat lagi dari disk saat ada yang membacanya. `auto` melakukan hal yang sama, tetapi hanya ketika tekanan memori di host atau container berlangsung terus-menerus. Season pack besar memakai memori jauh lebih sedikit di kedua mode tersebut. Salinan pemulihan terkompresi melindungi daftar file jika cache disk-nya rusak. Perubahan yang belum disimpan tidak pernah dilepas. Dashboard menyediakan ketiga mode. Perubahan memerlukan restart.

Saat startup juga memakai memori lebih sedikit jika riwayat download Real-Debrid-nya besar. Menyimpan dan memuat riwayat itu serta cache library tidak lagi membuat salinan tambahan.

Trade-off-nya ada di [referensi konfigurasi](config.md#library-detail).

## Watchlist Plex dan permintaan Seerr berbagi satu antrean {#plex-watchlist-and-seerr-requests-share-one-queue}

Blok `acquisition:` memasukkan item watchlist Plex dan permintaan Seerr ke dalam satu antrean. Keduanya dicari di indexer Newznab kamu, lalu hasilnya masuk ke backend Usenet. Permintaan Seerr baru diikuti setelah disetujui. Hanya season yang diminta yang diambil. Permintaan 4K dipisahkan dari permintaan 1080p. Permintaan Seerr yang masih terbuka dicek ulang untuk episode yang baru tayang.

Progres sekarang tetap tersimpan setelah restart. Ini mencakup tenggat waktu percobaan ulang, jumlah percobaan, dan episode mana yang sudah selesai. Akuisisi yang terhenti akan dilanjutkan dari titik terakhirnya. Akuisisi yang sudah selesai hanya mencoba ulang menghapus item dari watchlist dan tidak mencari lagi. State yang tersimpan ikut dalam backup normal. Pengaturan `watchlist:` yang sudah ada tetap berfungsi seperti biasa.

Pengaturannya ada di [Akuisisi](../guides/acquisition.md).

## Pustaka debrid bisa tinggal di file lokal yang portabel {#debrid-libraries-can-live-in-portable-local-files}

Akun debrid sekarang bisa mengambil pustakanya dari folder berisi file `.zurgtorrent`, bukan dari daftar milik akun itu sendiri. `zurg export-torrents` menulis pustaka yang sudah ada menjadi file-file tersebut. File-file itu hanya menjelaskan isinya dan tidak memuat kredensial maupun tautan unduhan. Jadi, pustaka bisa dibagikan. Orang yang menerimanya memutar lewat akunnya sendiri, dan batasan dari penyedianya tetap berlaku. Mengimpor, mendaftar, dan menyegarkan file-file itu tidak menambah apa pun ke akun.

Konfigurasi yang sudah ada tetap berfungsi. Cadangan baru memakai format 2 dan butuh build ini atau yang lebih baru untuk dipulihkan.

Ekspor dan pengaturan ada di [Pustaka lokal](../guides/local-libraries.md).

## Cache baca tetap bertahan setelah restart {#read-caches-survive-a-restart}

zurg sekarang menyimpan cache baca di disk, jadi tetap ada setelah restart. Ini mencakup NZB yang sudah di-parse dan artikel Usenet yang sudah di-decode. Juga mencakup layout arsip dan blok arsip yang sudah di-decode, serta link unduhan. Setelah restart, zurg tidak perlu mem-parse setiap NZB atau membaca ulang header setiap arsip. Setiap cache byte dibatasi 512 MiB secara default. `zurg backup --include-caches` menambahkan cache ke backup supaya restore-nya lebih cepat.

Permintaan untuk file AllDebrid atau TorBox yang sama pada saat yang sama sekarang berbagi satu pencarian link.

Pengaturan dan batasnya ada di [Cache persisten](../internals/persistent-caches.md).

## Pengambilan Usenet diperiksa lebih ketat sebelum berstatus Completed {#usenet-grabs-are-checked-more-closely-before-they-read-completed}

Sebelum grab berstatus Completed, zurg meminta news server untuk memeriksa enam belas artikel pertama dan artikel terakhir dari setiap file konten. Dulu hanya artikel pertama yang diperiksa. Akibatnya, celah di header media terlewat. Pemeriksaan dikirim sebagai satu batch per file, jadi arsip besar tidak lagi kehabisan waktu.

Rilis yang artikel yang hilangnya sudah diperbaiki sepenuhnya oleh PAR2 sekarang bisa diimpor. Dulu gagal karena artikel aslinya masih hilang dari server. Perbaikan sebagian tetap tidak dihitung.

`sabnzbd.history_limit` sekarang bisa dicocokkan dengan batas history yang lebih besar di Sonarr atau Radarr. Dengan begitu, tumpukan job selesai yang besar akan dikosongkan dalam batch yang lebih besar. Kedua sisi harus memakai angka yang sama. Nilai default tetap enam puluh.

## `enforce` tidak mengganggu fitur Plex yang bisa kamu lihat {#enforce-leaves-the-plex-features-you-can-see-alone}

`plex_settings_policy: enforce` tidak lagi mematikan scrubbing previews atau chapter pictures. Begitu juga volume levelling dan sonic analysis. Masing-masing men-decode seluruh file dan itu memakan bandwidth pada mount debrid. Tapi masing-masing juga memberi sesuatu yang bisa kamu lihat. Sekarang semuanya berada bersama Skip Intro dan Skip Credits sebagai soal selera. zurg tetap melaporkan biaya masing-masing. Hanya saja zurg tidak lagi membuat pilihan itu untukmu. Grup bandwidth sekarang hanya berisi analysis yang outputnya tidak ada yang melihat.

## Tautan debrid yang kedaluwarsa pulih tanpa membuat pemutaran gagal {#expired-debrid-links-recover-without-failing-playback}

A tautan TorBox yang token bertandanya sudah basi sekarang otomatis diganti dengan yang baru. Pembaca yang menunggu file yang sama berbagi satu pencarian itu. Kegagalan yang terus berulang akan menjeda pemutaran tanpa menandai file sebagai rusak.

Saat server unduhan TorBox, Real-Debrid, atau AllDebrid meminta zurg untuk menunggu, zurg sekarang menunggu selama yang diminta. zurg juga berhenti mencoba ulang server yang terus menolak. Ini berlaku untuk pemutaran, pemeriksaan tautan, dan pembacaan arsip. Tautan yang dicabut dan dibuka lewat `__downloads__` juga otomatis diganti dengan yang baru.

## zurg memperbarui dirinya sendiri {#zurg-updates-itself}

`zurg update` mengganti binary yang sedang berjalan dengan nightly sponsor terbaru. Command ini membaca release feed memakai login GitHub CLI jika ada, dan `GITHUB_TOKEN` atau `GH_TOKEN` jika tidak ada. Sebelum apa pun diganti, ia mengecek download runs dan melaporkan versi yang diharapkan. Binary ditukar dengan rename, jadi update tidak akan gagal walaupun zurg sedang berjalan. Build yang sudah memakai nightly terbaru, atau lebih baru darinya, dibiarkan saja. Di dalam container, command ini menolak dan mengarahkan Anda ke image pull, karena binary yang diganti di sana akan hilang saat container dibuat ulang. Pakai `--force` untuk mengabaikan penolakan ini. Installer juga mendapat mode `update` yang cocok untuk build lama yang belum punya command ini.

Panduan per platform: [Linux](../setup/linux.md#updating-zurg), [macOS](../setup/macos.md#update-zurg), [Windows](../setup/windows.md#updating-zurg), [Docker](../setup/docker.md).

## Satu pengaturan Plex bisa dikecualikan dari kebijakan {#one-plex-setting-can-be-opted-out-of-the-policy}

`plex_settings_ignore` menyebutkan preferensi Plex yang dibiarkan zurg, apa pun isi `plex_settings_policy`. Opsi ini ada untuk setup yang memang membutuhkan salah satu preferensi itu. Misalnya, library yang file-nya pindah antar folder bergantung pada Plex yang mengosongkan tempat sampahnya sendiri untuk menghapus entri yang tertinggal, dan kebijakan default mematikan fitur itu. Tapi kalau kamu menurunkan ke `warn` supaya fitur itu aktif lagi, pengaman filesystem-event di sebelahnya ikut hilang. Pengaturan yang di-ignore tetap dibaca dan tetap dilaporkan, di dashboard dan sebagai `skip` di `zurg plex-settings`. Bedanya, pengaturan itu tidak pernah ditulis, tidak pernah diberi peringatan, dan tidak pernah muncul di banner tempat sampah. Meng-ignore pengaturan keamanan itu tanggung jawabmu sendiri, dan zurg akan memberi tahu hal ini sekali saat startup. Id yang tidak cocok dengan pengaturan apa pun akan dilaporkan dan pengaturannya tetap dijaga, jadi salah ketik tidak akan dianggap sebagai opt-out.

Pengaturannya sendiri, dan apa yang dilakukan setiap level kebijakan terhadapnya, ada di [Plex](../guides/plex.md#recommended-plex-settings).

## Installer satu baris untuk setiap host yang didukung {#one-line-installers-for-every-supported-host}

Instalasi baru sekarang punya bootstrap satu baris opsional untuk Linux, macOS, Windows, dan Docker di Linux. Bootstrap ini memeriksa atau memasang prasyarat platform, memakai login browser GitHub untuk akses sponsor, mengunduh arsitektur yang sesuai, lalu menyerahkan proses ke `zurg setup` dan `zurg doctor`. Binary dan konfigurasi yang sudah ada tetap dipertahankan, dan semua panduan manual tetap tersedia.

## Setup menanyakan provider mana yang ingin dikonfigurasi {#setup-asks-which-providers-to-configure}

Instalasi `zurg setup` yang baru tidak lagi mengasumsikan Real-Debrid. Installer interaktif akan menanyakan satu atau lebih provider sesuai urutan prioritas, lalu hanya mengumpulkan kredensial untuk provider yang dipilih. Instalasi non-interaktif bisa mengulang `--provider` dan menggunakan flag token-file khusus provider atau environment variable. Konfigurasi yang sudah ada tetap dipertahankan, dan input Real-Debrid lama berupa `--token-file`, `TOKEN`, dan `RD_TOKEN` tetap kompatibel selama diberikan secara eksplisit.

## Lonjakan impor yang lebih besar dari jendela riwayat Sonarr tidak lagi kehilangan impor {#a-burst-larger-than-sonarrs-history-window-no-longer-loses-imports}

Sonarr dan Radarr meminta SABnzbd untuk setiap job yang masih antre, tetapi hanya enam puluh entri riwayat terbaru. Itu biasanya menggambarkan downloader sungguhan dengan cukup baik: penyelesaian datang sedikit demi sedikit, dan klien menghapus tiap job setelah mengimpornya. Library NZB yang di-cache berbeda. Pencarian musim secara massal bisa menyelesaikan ratusan job episode satu per satu sebelum poll berikutnya dari klien, dan dulu zurg menghapus semua job itu dari antrean sambil hanya mengembalikan enam puluh di riwayat. Setiap job di luar halaman itu tidak muncul di kedua respons, jadi klien tidak pernah mengimpor atau menandainya gagal, dan rilisnya tetap berada di root `__magic__` selamanya.

Sekarang zurg menyimpan job yang sudah selesai di luar halaman yang terlihat itu di dalam antrean. Saat klien mengimpor dan menghapus enam puluh yang pertama, penyelesaian berikutnya naik ke riwayat. Jadi musim yang diambil sebagai episode individual akan habis diproses dalam batch yang terbatas, bukan berlomba melawan jendela berukuran tetap. Season pack tetap berperilaku sebagai satu job.

## Penghapusan lewat mount selalu berhasil, dan `dav_allow_delete` sudah dihapus {#a-delete-through-the-mount-always-works-and-dav_allow_delete-is-gone}

Menghapus file dari media server yang mengarah ke mount dulunya tidak menampilkan apa-apa. zurg menolak WebDAV DELETE dengan 403, rclone mengubahnya menjadi I/O error, dan klien melaporkan kegagalan tanpa penyebab. Plex hanya menjawab `400 Bad Request` dan tidak mencatat apa pun, jadi tombolnya memang tidak berfungsi dan tidak ada yang memberi tahu alasannya. Kunci yang mengizinkannya, `dav_allow_delete`, sudah dihapus. DELETE lewat mount sekarang diterima di mana saja, tanpa konfigurasi apa pun. File konfigurasi yang masih menyetel kunci ini bukan error, karena kunci yang tidak dikenal diabaikan. Hanya saja kunci itu sudah tidak berpengaruh apa-apa.

Yang dulu dijaga oleh kunci itu belum hilang, jadi perlu disampaikan dengan jelas: rclone tidak punya cara untuk menyatakan "overwrite", dan saat menyimpan ulang file, ia mengirim DELETE lalu PUT. Artinya, program yang menulis ulang file di tempat, seperti penulis `.nfo`, proses trickplay, rename \*arr, atau `touch` yang nyasar, akan menghapus rilis dari akun debrid, bukan mengganti file. Mount membawa kredensial milik rclone sendiri, jadi tidak ada yang di hulu bisa membedakannya dari penghapusan yang disengaja. Bagian PUT masih ditolak, dan itulah yang mencegah urutan ini selesai diam-diam. Jika ada yang menulis ke mount kamu, setel `mount_read_only: true`. Ini akan menggagalkan penulisan di kernel sebelum sampai ke zurg sama sekali.

## Watchlist Plex mengambil konten lewat indexer Newznab kamu {#the-plex-watchlist-acquires-through-your-newznab-indexers}

Monitor watchlist sekarang sudah jalan, dan memakai indexer Anda sendiri. Versi lama mencari lewat API key DMM. Versi itu diam-diam berhenti bekerja saat Plex memindahkan watchlist ke host discover-nya, karena endpoint yang di-poll mulai membalas 404. Sekarang monitor polling ke host yang benar. Setiap item watchlist baru dicari di indexer Newznab yang sudah Anda konfigurasi: film akan diambil release yang paling cocok, dan serial diambil per musim dengan **lebih memilih season pack** daripada episode lepasan. Kalau ada musim yang belum ada yang upload pack-nya, monitor akan mengambil episode lepasan, dengan release terbaik untuk tiap episode. Kalau link NZB dari release yang dipilih gagal diambil (misalnya kena limit 429 dari indexer), monitor akan lanjut ke kandidat peringkat berikutnya, jadi item tidak ikut gagal. NZB yang dipilih masuk ke backend Usenet lewat aturan penamaan yang sama dengan endpoint SABnzbd dan addon Stremio. Dengan begitu, ketiganya saling mengenali grab satu sama lain dan tidak ada duplikasi. Item baru dihapus dari watchlist setelah benar-benar ada yang berhasil diambil. Urutan lama menghapus dulu baru bertanya kemudian, jadi kegagalan apa pun diam-diam menghilangkan item dari daftar Anda.

Atur lewat blok `watchlist:` yang baru: `enabled`, `check_every_secs` (default 60), `indexers` (kalau kosong, akan memakai `stremio.indexers`), `max_size_gb` (default 40, untuk film dan episode tunggal), `max_season_size_gb` (default 100, untuk season pack), dan `quality` (`best`, `4k`, `1080p`, `720p`, `smallest`). Key `plex_watchlist_*` yang lama tetap punya arti yang sama. `plex_token` sudah cukup untuk kebutuhan Plex monitor ini. Monitor berkomunikasi dengan layanan cloud Plex, jadi tetap bisa jalan di instance yang tidak punya `plex_server_url`. Pencarian TV mengutamakan id TVDB dan mencoba sekali lagi dengan id IMDb kalau hasilnya kosong. Alasannya, indexer mengindeks TV berdasarkan TVDB, dan pemetaan IMDb di level serial mereka belum rapi. Serial yang punya banyak indexing bisa saja mengembalikan nol hasil untuk pencarian imdbid.

Semua key ada di halaman konfigurasi di bawah **Plex Watchlist**, dan juga di [referensi konfigurasi](config.md#watchlist).

## Addon Stremio di atas indexer Newznab kamu {#a-stremio-addon-over-your-newznab-indexers}

zurg sekarang bisa menjawab Stremio secara langsung. Nyalakan blok `stremio:`, daftarkan indexer Newznab kamu, lalu tempel URL `/stremio/<token>/manifest.json` yang tercatat di log ke Stremio. Klien akan meminta stream berdasarkan IMDb id, zurg mencari di indexer (film dengan `t=movie`, episode dengan `t=tvsearch` beserta season dan episode), dan hasilnya dikembalikan dengan urutan resolusi dulu sebagai stream yang bisa diputar. Saat kamu memilih salah satu, NZB-nya ditarik ke backend Usenet lewat aturan penamaan yang sama dengan endpoint SABnzbd, jadi rilis yang diambil dua kali akan dikenali, bukan diduplikasi. Lalu stream diputar lewat endpoint `/strm/e/` yang ditandatangani, termasuk range, failover, dan isi arsip. Semua yang diputar masuk ke library, jadi muncul di Plex seperti rilis lainnya.

Token di path adalah seluruh otorisasinya. Token dibuat dan disimpan di `data/stremio-token` jika config tidak menyebutkan token. Hasil pencarian di-cache di `data/stremio-cache`, jadi membuka lagi sebuah judul tidak memakan panggilan ke indexer. Masa berlaku cache mengikuti seberapa banyak hasil pencariannya: satu jam per hasil sampai empat hasil, lalu `stremio.cache_hours` (default 24) mulai dari lima hasil. Jawaban kosong tidak pernah di-cache. Daftar stream yang di-cache punya item penyegaran yang menghapus cache untuk judul itu. Rilis yang lebih besar dari `stremio.max_size_gb` (default 40) dibuang dari daftar, supaya remux satu disc penuh tidak mengalahkan semua pilihan lain yang bisa diputar.

Penjelasan lengkap, termasuk biaya untuk putar pertama: [Addon Stremio](../guides/stremio.md).

## Satu folder berisi seluruh instalasi Docker, dan folder itu di-mount saat pertama kali dijalankan {#one-folder-is-the-whole-docker-install-and-it-mounts-on-the-first-run}

Cara yang didokumentasikan untuk menjalankan zurg di Docker adalah satu perintah `docker run` dengan `TOKEN` di dalamnya, dan hasilnya adalah container yang tidak me-mount apa pun. Config yang dibuat otomatis membiarkan `rclone_enabled` mati dan `mount_path` tidak diisi, jadi `/zurg_mnt/zurg` tetap kosong sampai seseorang menemukan dua kontrol itu di Dashboard. Config itu juga ditulis di dalam container, jadi `docker pull` berikutnya membuang jawabannya bersama cache library. Panduan cepat perlu catatan kaki yang mendaftar kedua hal itu, dan itu artinya panduan cepat mengakui bahwa ia tidak berfungsi.

`MOUNT_PATH` sekarang mengisi `rclone_enabled: true` dan `mount_path` ke dalam config pada run yang membuatnya, di samping apa yang sudah diisi `TOKEN`. Working directory image adalah `/config`, dan semua yang disimpan zurg di-resolve terhadapnya: `config.yml`, `data/`, `logs/`, `dump/`, `strm/`, `nzbs/` dan cache rclone. Jadi satu `-v ~/zurg:/config` menyimpan seluruh instalasi, dan update image tidak memindahkan apa pun. Run pertama cukup satu perintah dan berakhir dengan library yang ter-mount, bukan dengan repot bolak-balik ke Dashboard.

Kedua variabel hanya dibaca **saat belum ada file config**, dan diabaikan setelahnya. Aturan ini sama dengan yang sudah dipakai `log_level` terhadap `LOG_LEVEL`, dengan alasan yang sama: `MOUNT_PATH` yang tertinggal di file compose tidak boleh diam-diam membatalkan mount path yang diubah kemudian di Dashboard. Startup sekarang memberi peringatan ketika variabel ini diset dan tidak cocok dengan config, supaya operator yang men-deploy ulang tapi tidak melihat efek apa pun tahu alasannya.

Instalasi yang dibuat dengan layout lama tidak berubah. Docker membuat target setiap bind mount, jadi keberadaan `/app/config.yml`, `/app/data` atau `/app/logs` menunjukkan bahwa itu layout lama, dan container tetap memakai `/app` jika menemukan salah satunya. Setup lengkapnya, dan apa yang merusak mount yang terlihat dari host, ada di [Docker](../setup/docker.md).

## TorBox dan AllDebrid juga menerima `.torrent`, sehingga pengambilan privat tidak menggantung {#torbox-and-alldebrid-are-handed-the-torrent-too-so-a-private-grab-is-not-left-hanging}

File `.torrent` yang dikirim \*arr mulai ikut saat add sejak rilis terakhir, tapi hanya Real-Debrid yang bisa menerimanya. Dua akun lainnya masih hanya menerima info hash, dan untuk rilis dari private tracker, itu satu-satunya bentuk yang tidak bisa mereka pakai. Tidak ada yang gagal, dan justru itu yang bikin susah dilihat: saat diuji langsung di akun TorBox, hash tanpa swarm publik diterima dengan torrent id, lalu malah tertahan di `checking` dengan `size: -1`, tanpa daftar file, dan estimasi seratus hari. Persis seperti yang dilaporkan dari grab TorrentLeech yang "cuma nge-hang, nggak ada yang ke-download". File dari rilis yang sama langsung dijawab dengan nama asli, ukuran asli, dan daftar filenya, jadi endpoint qBittorrent bisa lanjut mengerjakan tugasnya.

Kedua akun sekarang menerima file. `createtorrent` TorBox dan `magnet/upload/file` AllDebrid sama-sama menerima file sebagai pengganti magnet, dan jawabannya dalam bentuk yang sama dengan yang dulu dikembalikan add magnet, jadi tidak ada yang berubah setelah add. AllDebrid tetap melaporkan status pada upload itu sendiri apakah kontennya sudah ada di mereka, dan itu satu-satunya jawaban cache yang pernah diberikan akun tersebut. Sudah diverifikasi langsung lewat jalur add zurg di kedua akun: rilis yang sudah ter-cache terunggah dan terbaca `done` dengan 100% beserta daftar filenya dalam hitungan detik, dan rilis yang tidak ada yang pegang terbaca dengan nama, ukuran, dan status stalled karena kekurangan peer. Status ini bisa ditangani endpoint, sedangkan hash tadi berujung pada torrent yang tidak pernah ter-resolve dan tidak pernah selesai.

Satu penolakan sekarang juga bisa dibaca dengan jelas. Panggilan TorBox yang ditolak dengan 4xx dulu sampai ke pemanggil sebagai pesan polos dari HTTP client bersama, "unexpected status code: 400", karena body respons, tempat TorBox menaruh kode dan detail error-nya, dibuang demi error itu. Jadi file `.torrent` yang tidak mau diproses TorBox hanya dilaporkan ke \*arr sebagai angka status, tanpa keterangan lain. Sekarang body dibaca dulu, dan alasan dari akun itu ikut disampaikan bersama penolakannya.

Cara mengatur indexer: [Sonarr & Radarr, torrent](../guides/sonarr-radarr-torrents.md).

## Entri arsip terkompresi di-stream, didekode sesuai kebutuhan {#compressed-archive-entries-stream-decoded-on-demand}

Entri RAR atau zip deflate yang terkompresi tidak bisa menjawab ranged read seperti entri stored. Byte-nya hanya ada di balik decoder yang harus berjalan dari awal entri. Karena itu zurg menolaknya: rilis yang isinya hanya terkompresi dijawab dengan 415, dan sibling terkompresi dari entri stored dilewati. Itu jawaban yang jujur untuk streamer, tapi juga menyembunyikan sebagian besar katalog Usenet yang lebih lama, yaitu setiap poster yang mengemas dengan kompresi, utuh dan lengkap.

Entri-entri ini sekarang disajikan dengan men-decode maju sesuai permintaan ke dalam window memori yang dibatasi. Tidak ada yang ditulis ke disk, dan tidak ada yang di-decode kecuali yang diminta oleh read. Playback berurutan, pola yang dihasilkan player, akan sampai di tepi window dan memajukannya sedikit setiap read. Seek mundur melewati apa yang disimpan window akan memulai ulang decode dari awal entri. Seluruh byte entri sama persis dengan yang akan diekstrak unrar: tiga entri jpg dari volume RAR4 terkompresi asli di-decode persis byte per byte dibandingkan fixture yang sama yang dibaca oleh pass decoder independen, md5 demi md5.

Menelusuri volume dari split set membutuhkan volume chain dari rardecode, yang membuka `.part02.rar` dari filesystem. Volume zurg berada di balik ranged network reader. Decoder sekarang di-vendor di `internal/rardecode` (MIT, upstream v1.1.3) dengan satu perubahan: `OpenReaderOver` menerima opener, sehingga setiap volume berikutnya diambil dari set berdasarkan nama yang diturunkan sendiri oleh archive.

Bentuk listing ikut berubah. Rilis yang isinya hanya terkompresi sekarang menampilkan payload-nya (`stream_compressed_archives: false` mengembalikan penolakan lama), dan archive campuran mendaftarkan sibling terkompresinya di samping entri stored-nya. Listing versi 15.

## Sonarr dan Radarr bisa mengambil torrent, dan Prowlarr bisa mendorongnya {#sonarr-and-radarr-can-grab-torrents-and-prowlarr-can-push-them}

zurg bisa menjawab *arr seolah-olah dia qBittorrent. Mereka memberinya magnet atau `.torrent`, lalu zurg menambahkan info hash-nya ke akun debrid, yaitu Real-Debrid, TorBox, atau AllDebrid, sesuai yang kamu atur. Setelah rilisnya masuk ke library, torrent akan berstatus finished dan punya folder di bawah `__magic__` untuk diimpor. Proses impornya sama dengan rename yang sudah lama dipakai endpoint SABnzbd untuk grab Usenet: sebuah baris di tabel `__magic__`, tanpa ada byte yang dipindah.

Endpoint ini terdaftar di `/api/v2` dan `/qbittorrent/api/v2`. Endpoint ini nonaktif sampai kamu mengaktifkannya, dan dijaga oleh API key yang dikirim klien sebagai bearer token. Sebuah grab ditawarkan ke setiap akun yang menerima torrent, sesuai urutan di `providers:`. Jika grab berhenti bergerak, yaitu tidak ada perubahan stage, tidak ada kenaikan progress, selama `qbittorrent.download_timeout_mins` menit (default-nya lima belas), grab itu dilepas dari akunnya dan dicoba di akun berikutnya. Nilai `0` hanya menerima konten yang sudah ter-cache di akun, dan menolak sisanya saat proses add. Penolakan inilah satu-satunya yang ditindaklanjuti *arr. Apa yang dilakukan akun terhadap sebuah download dipetakan ke status yang dipahami klien, dan kecepatan, swarm, serta sisa waktu ditampilkan jika akun melaporkannya.

Ada satu keterbatasan yang perlu kamu tahu. API qBittorrent tidak punya cara untuk menyatakan bahwa download gagal. Jadi rilis yang tidak mau diterima akun mana pun akan sampai ke klien sebagai peringatan, bukan entri blocklist. Peringatan itu terlihat di queue beserta alasannya, tetapi tidak pernah di-grab ulang secara otomatis. Endpoint SABnzbd tidak punya masalah ini.

Prowlarr berbicara ke endpoint yang sama untuk perannya sebagai download client: mendorong rilis ke akun secara manual. Tidak ada impor yang terjadi setelah push dari Prowlarr. Itu memang tugas *arr.

Panduan lengkapnya, yang diambil dari instalasi yang sedang berjalan: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## `__magic__`, direktori yang bisa kamu atur {#__magic__-a-directory-you-can-organise}

Setiap direktori yang disajikan zurg adalah filter tersimpan. Sebuah rilisan ada di `movies` karena cocok dengan filter movies, dan sekaligus ada di `__all__`, `recent`, dan `movies`. Jadi sejauh ini tidak pernah ada tempat di pustaka untuk *menaruh* sesuatu. Itu tidak masalah sampai sebuah program ingin memindahkan file. Radarr dan Sonarr mengimpor dengan memindahkan, dan mount yang tidak bisa menerima perpindahan membuat mereka menyalin. Akibatnya, setiap impor menarik seluruh rilisan dari host debrid atau dari Usenet, padahal itu justru yang ingin dihindari oleh mount ini.

`__magic__` adalah direktori baru di level teratas. Awalnya isinya salinan persis dari `__all__`: setiap rilisan sebagai folder, berisi tepat apa yang ada di `__all__/<release>/`, termasuk isi arsip virtual. Di dalamnya, apa saja bisa dipindahkan ke mana saja. Jalankan `mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01` lalu `mv` sebuah episode ke sana, dan episode itu langsung ada di sana. Tidak ada byte yang berpindah, tidak ada torrent yang di-rename, tidak ada yang diunduh ulang, dan `__all__` tetap tidak berubah. Sebuah perpindahan hanya mengubah satu baris di tabel kecil. Tabel itu memakai hash konten rilisan dan path file di dalamnya sebagai kunci. Jadi perbaikan yang menambahkan ulang rilisan dan membangun ulang semua id di sekitarnya tidak akan menghilangkan catatan tentang di mana kamu menaruh sesuatu. Mengganti nama rilisan dari dashboard juga tidak.

Perpindahan berlaku dua arah. File bisa dipindahkan *ke dalam* folder rilisan dan juga keluar darinya. Folder itu akan menampilkan file tersebut di samping entri milik rilisan. Ini yang dibutuhkan program yang mengembalikan sesuatu ke folder tempat ia mengimpor. Jika sebuah nama datang dari dua tempat sekaligus, yang disengaja yang menang. Apa yang kamu pindahkan mengalahkan nama yang diberikan rilisan, dan keduanya mengalahkan file yang ada di `data/local`. Yang kalah tidak ditampilkan, jadi tidak muncul dua kali.

Menghapus adalah sisi lainnya, dan secara default sifatnya menyembunyikan, bukan menghancurkan. `rm` di dalam `__magic__` menghapus entri dari `__magic__` tetapi membiarkannya tetap ada di `__all__` dan di setiap direktori filter. Jadi klien yang merapikan pustaka tidak bisa menghilangkan apa pun. Folder rilisan juga bisa hilang dengan cara yang sama. Inilah yang memungkinkan Sonarr menghapus folder job setelah impor tanpa menyentuh rilisan yang baru saja ia impor. `magic.allow_delete: true` mengaktifkan arti yang lebih kuat untuk file, yaitu isinya ikut dihapus. Folder rilisan dan direktori tetap hanya disembunyikan, apa pun nilai pengaturan itu.

Fitur ini nonaktif secara default, karena ini adalah tree yang bisa ditulisi. Sebuah \*arr yang diarahkan ke root folder yang salah bisa mengatur ulang seluruh pustaka:

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

Dua kunci `sidecar_` ditujukan untuk klien yang me-mount `/dav` secara langsung, bukan lewat mount bawaan zurg. Klien tersebut mengirim `PUT` ke zurg untuk file `.nfo` baru, poster, atau track subtitle. Sekarang zurg menulis isinya ke `data/local/__magic__/…`, yaitu tree yang sama tempat mount bawaan zurg menyimpan file seperti itu. Dengan begitu kedua tampilan menunjukkan satu direktori, bukan dua. File itu bisa dibaca dengan range, panjang, dan waktu modifikasi seperti file lainnya. Batasannya mencegah fitur ini berubah menjadi penyimpanan file umum. File yang lebih besar dari `sidecar_max_mb` ditolak dengan 413. Jika menulis file akan membuat tree melebihi `sidecar_budget_mb`, penulisan ditolak dengan 507. Tidak ada yang dijawab oleh pustaka yang boleh ditimpa. Folder rilisan, entri di dalamnya, atau path tempat sesuatu dipindahkan akan menghasilkan 403. Perpindahan juga tidak pernah menghancurkan file asli hanya untuk memberi ruang bagi sebuah baris.

Ada dua hal yang perlu diketahui sebelum mengarahkan apa pun ke sini. Direktori filter sengaja tidak diubah. Jadi rilisan yang dipindahkan di dalam `__magic__` tetap ada di `recent` dan `movies` dengan nama aslinya. Arahkan media server ke `__magic__` **atau** ke filter, jangan ke keduanya. Selain itu, mount ini sejak dulu hanya bisa ditulis ke satu arah. Apa pun yang benar-benar baru dan ditulis ke dalamnya, misalnya `.nfo`, subtitle, atau poster, akan masuk ke `data/local` milik zurg sendiri dan digabungkan ke dalam daftar. Itulah sebabnya sidecar di samping rilisan langsung berfungsi, dan kenapa tes tulis root-folder milik \*arr lolos.

`dav_allow_rename` dan `dav_allow_delete` tidak ada hubungannya dengan semua ini. Keduanya melindungi jalur yang mengganti nama dan menghapus apa yang dipegang akun debrid. Penulisan di bawah `__magic__` tidak menyentuh akun mana pun. `mount_read_only: true` tetap mengesampingkan semuanya.

Dashboard punya halaman untuk fitur ini, di `/magic/`. Halaman itu menampilkan setiap baris yang ada di tabel, dikelompokkan per rilisan. Untuk setiap baris, halaman menunjukkan apa itu, file dari rilisan mana yang dipindahkan, dan dari mana file tersebut sekarang disajikan. Halaman juga menampilkan jumlah baris, ukuran journal dan snapshot di disk, serta seberapa banyak `sidecar_budget_mb` yang dipakai file asli di samping pustaka. Halaman ini juga melaporkan ukuran seluruh `data/local`. Angka inilah yang menunjukkan apakah sesuatu sedang diimpor dengan cara menyalin. Klien yang menyalin alih-alih memindahkan akan menaruh byte di sana, dan tidak ada hal lain di dashboard yang akan pernah menampilkannya.

Tiga status yang ditampilkan tidak bisa dicapai dari sisi klien. Sebuah penempatan bisa di-**reset**, sehingga file kembali ke tempat yang diberikan pustaka. Sebuah tombstone bisa di-**unhidden**, sehingga entri kembali ditampilkan. Sebuah baris **dangling**, yaitu baris yang rilisannya atau file di dalam rilisannya sudah tidak ada di pustaka, bisa dihapus satu per satu atau sekaligus. Ini hal baru. Baris seperti itu tidak menghasilkan apa pun, jadi klien tidak bisa menampilkan, memindahkan, atau menghapusnya. Baris itu sengaja tidak dihapus, karena perbaikan yang mengembalikan rilisan juga mengembalikan penempatannya. Sebelumnya tidak ada tempat untuk membersihkannya. Sidecar juga ditampilkan, dengan klasifikasi yang sama. File asli di dalam folder yang tidak lagi dimiliki siapa pun, misalnya `.nfo` di samping rilisan yang sudah keluar dari pustaka atau di dalam penempatan yang sudah dilupakan, ditandai sebagai **orphaned** dan dihitung terpisah. Tidak ada yang dibersihkan otomatis, dengan alasan yang sama seperti baris dangling. File itu tetap milikmu, dan perbaikan yang mengembalikan rilisan akan mengenali folder tersebut lagi. Menghapus satu file di sana benar-benar menghapus file itu, sama seperti `DELETE` lewat mount. Setiap tombol tersebut memberi tahu mount untuk melupakan daftar yang berubah, karena mount menyimpan cache direktori selama dua belas jam dengan polling dimatikan.

`magic:` dan `sabnzbd:` sekarang bisa diedit dari halaman konfigurasi. Keduanya ditandai **Restart Required** karena memang demikian: rute yang melayani `__magic__` dan endpoint SABnzbd ditentukan sekali saat startup, langsung dari nilai-nilai ini. Mengaktifkan salah satunya akan menulisnya ke `config.yml`, tetapi tidak mengubah sesi yang sedang berjalan. Halaman `__magic__` juga menyebutkan hal ini secara langsung, alih-alih menampilkan namespace kosong seolah semuanya baik-baik saja.

### Sonarr dan Radarr sekarang bisa memberikan NZB ke zurg {#sonarr-and-radarr-can-now-hand-zurg-an-nzb}

Alasan `__magic__` ada adalah agar sebuah \*arr punya tempat untuk mengimpor. Sekarang zurg juga menyediakan kebalikannya: sebuah endpoint di `/api` yang menjawab Sonarr dan Radarr seolah-olah zurg adalah SABnzbd. Arahkan mereka ke host dan port zurg, tempel API key-nya, dan grab akan masuk ke `nzbs/` untuk backend Usenet. Setelah rilisnya masuk ke library, job melaporkan Completed dengan sebuah folder di bawah `__magic__`. Impornya hanyalah rename di dalam mount: satu baris di tabel, tidak ada byte yang dibaca, dan tidak ada yang diunduh dari Usenet untuk memasukkannya ke folder series.

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

Fitur ini nonaktif secara default, dan perlu kedua bagiannya agar berguna: provider `nzb` untuk membaca NZB, dan `magic.enabled` agar ada tempat untuk mengimpor. Endpoint ini tidak berada di balik basic auth zurg, karena tidak ada \*arr yang pernah mengirim auth ke download client. Lapisan HTTP mereka juga membaca 401 sebagai "unable to connect". API key adalah satu-satunya gerbang, jadi perlakukan port itu dengan hati-hati. Root folder harus berada **di dalam** `__magic__` (`__magic__/tv`, `__magic__/movies`), bukan di `__magic__` itu sendiri atau di atasnya. Kalau tidak, pemeriksaan kesehatan root folder dari client akan bermasalah.

Satu hal yang perlu kamu ketahui sebelum memindahkan sebuah library: **sinyal kegagalannya belum lengkap**. Rilis yang ada di library tetapi tidak ada yang bisa diimpor di dalamnya dilaporkan `Failed`. Ini terjadi kalau setiap file rusak, terhapus, atau tersaring, atau kalau yang ada hanya scaffolding perbaikan dan sidecar, seperti pada NZB yang isinya hanya volume recovery. Status `Failed` inilah yang membuat kedua client memasukkan rilis itu ke blocklist dan mengambil alternatif lain. Sebuah set RAR dihitung sebagai konten, karena zurg men-stream video langsung dari dalamnya. Pengecualiannya adalah set yang sama sekali tidak bisa di-stream zurg, yaitu yang hanya berisi entri terkompresi. Set seperti itu dilaporkan Failed sejak ada yang membukanya dan menemukan hal tersebut. Keputusan itu disimpan bersama rilisnya, karena mempelajarinya butuh pembacaan setiap volume dalam set. Yang tidak dilaporkan adalah post yang artikelnya sudah habis dari news server. zurg belum memeriksa hal ini, jadi rilis yang sudah mati dilaporkan Completed seperti yang lain, lalu gagal pada pembacaan pertama. Akibatnya Sonarr melihatnya sebagai kegagalan impor, bukan kegagalan download. Kasus ini masih harus ditangani secara manual. Bagian lain dari alur ini berfungsi dengan baik, termasuk pembersihan setelah impor: folder job yang dihapus Sonarr menjadi tombstone, dan rilisnya tetap berada di `__all__`.

Grab tidak menunggu poll perubahan berikutnya. zurg membaca ulang watch directory segera setelah dia menulis ke dalamnya. Ini hanya berlaku untuk akun Usenet. Satu season pack berarti dua puluh grab dalam beberapa detik, dan membaca ulang library debrid berisi puluhan ribu torrent hanya untuk mendeteksi satu file lokal akan menjadi dua puluh kali pekerjaan yang sia-sia. Jika tidak ada provider `nzb` yang dikonfigurasi sama sekali, zurg sekarang memberi tahu saat startup, daripada menerima grab yang tidak akan pernah dibaca.

Halaman `__magic__` menampilkan daftar job secara hanya-baca: `nzo_id` yang digunakan tiap client untuk mengenali sebuah grab, kategorinya, kapan grab itu masuk, apakah library sudah mencantumkan rilisnya, dan, setelah itu, folder tempat \*arr mengimpor.

Setup lengkapnya, termasuk remote path mapping untuk \*arr yang berjalan dalam container dan arti setiap error saat connection test, ada di `docs/sabnzbd.md`.

## Mount memanfaatkan lebih banyak bandwidth yang tersedia {#the-mount-reaches-more-of-the-bandwidth-it-has}

Membaca file lewat mount rclone lebih lambat daripada mengambil byte yang sama lewat HTTP. Penyebabnya ada pada cara sebuah pembacaan dimulai, bukan cara ia berjalan. Potongan pertama diminta sebesar 4 MB lalu digandakan dari situ. Jadi pembacaan yang dimulai dari offset dingin menghabiskan sebagian besar waktunya di bawah kecepatan yang sebenarnya bisa dilewatkan koneksi, dan setiap seek memulai pembacaan baru. Potongan pertama sekarang diminta sebesar 32 MB.

Diukur pada host dengan sekitar 70 MB/s bandwidth unduh yang bisa dipakai, dan setiap pengaturan diuji bergantian supaya satu menit yang lambat tidak jatuh hanya pada salah satunya. Median throughput mount di Real-Debrid naik dari 49 menjadi 57 MB/s, dan TorBox naik dengan pola yang sama. AllDebrid mendapat keuntungan lebih kecil di sini karena batasnya per koneksi, bukan per akun.

Ukuran potongan adalah seluruh efeknya. Read-ahead FUSE juga dinaikkan selama pengujian, tapi tidak mengubah apa pun. Ini juga tidak menambah penggunaan bandwidth. Ukuran potongan adalah seberapa banyak yang *diminta*, bukan seberapa banyak yang ditransfer, dan rclone berhenti mengambil saat pemutaran berhenti. Pembacaan 4 MB tetap mengambil 6 MB, sama seperti saat read-ahead dimatikan sepenuhnya. Jadi library yang dijelajahi dan dicicipi, bukan ditonton sampai habis, tidak mengunduh lebih banyak dari sebelumnya.

Tidak ada yang perlu kamu ubah. Nilai baru langsung dipakai sebagai default, dan `rclone_extra_args` tetap bisa menimpanya.

## `zurg benchmark-my-setup` menunjukkan seberapa cepat setup kamu sebenarnya {#zurg-benchmark-my-setup-answers-how-fast-the-setup-actually-is}

Sampai sekarang, satu-satunya cara untuk tahu apakah stream yang lambat disebabkan oleh akun, host, atau mount adalah dengan menebak. Perintah baru ini membaca byte sungguhan melalui jalur yang sama dengan yang dipakai player, lalu melaporkan distribusinya: min, median, rata-rata, max, dan time to first byte. Jadi kamu tidak hanya dapat satu angka yang bisa saja dihasilkan oleh satu sampel yang kebetulan sial.

Perintah ini berjalan dalam tiga fase. Pertama, setiap akun sendiri-sendiri. Ini adalah angka yang bisa kamu bandingkan dengan janji layanannya. Kedua, semua akun yang dikonfigurasi berjalan bersamaan. Ini satu-satunya fase yang bisa membedakan provider yang lambat dari uplink yang kewalahan. Akun yang masing-masing mampu mempertahankan 70 MiB/s saat sendirian, tetapi hanya 25 MiB/s saat bersamaan, adalah satu bottleneck, bukan tiga masalah. Laporannya akan memberi tahu kamu yang mana dari keduanya yang sedang kamu lihat. Ketiga, pembacaan yang sama melalui mount rclone. Selisihnya terhadap fase pertama adalah biaya dari FUSE dan VFS. Fase mount dilewati jika `rclone_enabled` dimatikan.

Sampel ditempatkan pada offset acak, dan ini bukan detail kecil. Setiap lapisan di bawahnya melakukan caching. VFS rclone menyimpan apa yang sudah diambil, dan edge CDN debrid menyimpan apa yang sudah dikirim. Jadi membaca ulang offset yang sama justru mengukur cache, bukan link. Di setup live, file yang sama menunjukkan 47 MiB/s saat pertama kali dibaca dan 285 MiB/s pada pembacaan kedua di region yang sama.

Ukuran sampel juga mengubah arti angka mount, jadi laporannya akan menyebutkan hal ini. rclone membuka file dengan `vfs_read_chunk_size` lalu menggandakannya dari situ. Karena itu, sampel pendek sebagian besar waktunya masih dalam tahap naik bertahap. Pada satu setup, hasilnya 47 MiB/s untuk sampel 256 MiB dibandingkan 88 MiB/s untuk 1 GiB, sementara HTTP stabil di sekitar ~70 untuk keduanya. Default 128 MiB adalah angka untuk seek-and-scrub, dan `--sample-mb 1024` adalah batas sustained. Keduanya tidak salah. Run akan memberi tahu kamu yang mana yang baru saja kamu ambil.

`-n` mengatur jumlah iterasi. `--provider` membatasi run ke akun yang disebutkan namanya. `--skip-mount` dan `--skip-concurrent` melewati satu fase. `--json` mengeluarkan laporan untuk scripting. Perhatikan bahwa perintah ini memakai bandwidth sungguhan dari akunmu sendiri: iterasi x ukuran sampel per akun, dua kali, ditambah fase mount. Jalankan dari direktori zurg, karena backend NZB membaca folder `nzbs/` relatif terhadap working directory. Akun yang tidak menampilkan apa pun akan dilaporkan seperti itu, bukan sebagai akun tanpa file besar.

## Rilis Real-Debrid yang berfungsi tidak lagi ditandai rusak setelah pemeriksaan tautan {#working-real-debrid-releases-are-no-longer-marked-broken-after-a-link-check}

Sejak nightly tanggal 2026-08-20, library yang sehat pun bisa memenuhi log dengan `Link verification failed during refresh` dan `keeping files as broken`, masing-masing disertai `404 Not Found` dan `invalid_download_code` dari sebuah download host. Padahal tidak ada yang salah dengan release-nya.

Nightly itu menambahkan pembersihan untuk baris yang dibuat Real-Debrid di My Downloads: setiap link yang diverifikasi zurg membuat satu baris. Kalau dibiarkan, daftarnya terus bertambah satu baris per torrent setiap cold build, sampai saat startup harus memuat puluhan ribu baris. Pembersihan ini menghapus baris-baris tersebut di latar belakang, dengan anggapan bahwa baris dan URL yang dibuatnya adalah dua hal yang terpisah.

Anggapan itu keliru. Menghapus baris akan mencabut download code, dan yang membuatnya tetap hidup hanyalah host yang sudah pernah mengambilnya. Diukur pada 2026-08-22: code yang dibuat di `124-4` lalu diambil sekali lewat `44-4` tetap menjawab `200` di `44-4`, sementara `124-4` dan `125-4` yang tidak tersentuh sama-sama menjawab `404 invalid_download_code`. zurg memilih download host per request, dari beberapa yang tercepat, jadi host yang memverifikasi sebuah link jarang menjadi host yang memintanya berikutnya. Hasil resolusinya tetap tersimpan di cache selama empat jam, dan setiap request terhadapnya dalam rentang itu kembali `404`. Hasilnya dibaca sebagai link yang sudah mati, dan release-nya ditandai broken.

Sekarang, resolusi langsung dikeluarkan dari link cache begitu barisnya masuk antrean untuk dihapus, sehingga tidak ada yang memutar ulang URL yang sedang akan hilang. Request berikutnya akan me-resolve link baru. Baris-barisnya tetap dibersihkan. Release yang salah ditandai broken akan pulih sendiri pada refresh berikutnya, jadi tidak perlu menambahkan ulang atau memindai ulang apa pun.

## Serial yang dinamai menurut tanggal tayang dicatat sebagai serial, bukan film {#shows-named-by-air-date-are-filed-as-shows-not-movies}

Program tanpa nomor musim dan episode diberi nama menurut tanggal tayangnya, misalnya `WWE SmackDown 2026-08-21`, dan begitu juga setiap acara harian dan acara larut malam setelahnya. Tidak ada yang di tes episode yang tahu soal aturan ini. Tes itu mencari `S01E01`, mencari nomor musim atau episode yang ditulis lengkap, mencari hash dari rilis anime, dan kalau semua itu tidak ketemu, ia mencari deretan file bernomor untuk dibaca sebagai urutan. Rilis harian cuma berisi satu file dengan satu tanggal, jadi jawabannya tidak, dan rilis itu jatuh ke direktori pertama yang mau menerimanya. Di sebagian besar konfigurasi, direktorinya adalah movies.

Sekarang tanggal tayang dihitung sebagai penanda yang seharusnya, ditulis `2026-08-21`, `2026.08.21`, `2026 08 21`, `2026_08_21` atau `20260821`. Hanya tanggal yang valid yang lolos: bulannya harus salah satu dari dua belas dan harinya salah satu dari tiga puluh satu. Jadi tahun yang berdampingan dengan resolusi, seperti `Movie.2026.05.1080p`, tidak pernah dibaca sebagai tanggal. Diuji pada pustaka berisi 6755 rilis, tidak ada film yang pindah direktori. Diuji pada 4734 rilis acara harian sungguhan, 4633 sekarang dikenali. Sisanya adalah nama scene lama yang menyingkat tahun jadi dua digit atau menaruh tahun di belakang. Itu tidak bisa dibedakan dari tata letak channel audio dengan keyakinan yang cukup.

Pustaka yang sudah ada di disk akan menata ulang file-nya sendiri saat startup, jadi cukup restart berikutnya. Kamu tidak perlu scan ulang atau impor ulang.
