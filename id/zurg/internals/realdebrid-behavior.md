# Torrent {#torrents}

Real-Debrid mendukung pengunduhan torrent dan magnet link tanpa batas jumlah, serta memilih file mana di dalamnya yang ingin Anda unduh.
Jika file torrent atau magnet link sudah diunduh oleh pengguna lain, itu dianggap "cached" dan Real-Debrid langsung memberi Anda link cached tersebut.
Jika belum, Real-Debrid akan mencoba mengunduh magnet link dari public tracker atau DHT/PEX.
Jika berupa file torrent yang berisi info tracker, maka info tracker itu yang akan dipakai. Ini berguna untuk private tracker (sayangnya, banyak private tracker memblokir server unduh Real-Debrid).
Jika torrent sudah tidak punya seeder atau leecher dan tidak mungkin mengunduh semua piece-nya, maka akan muncul error.
Setelah selesai diunduh, Anda juga akan mendapat link cached yang terlihat seperti https://real-debrid.com/d/DOWNLOADCODE
DOWNLOADCODE adalah ID unik sepanjang tepat 13 karakter untuk file tertentu (karakter setelah karakter ke-13 diabaikan).

# Memilih file {#selecting-files}

As mentioned, it is possible to select files that you only want to download inside a torrent
Seperti yang sudah disebutkan, kamu bisa memilih file mana saja yang hanya ingin diunduh di dalam sebuah torrent.

If a torrent contains files A B and C and you select A and B, it will only download A and B
Jika sebuah torrent berisi file A, B, dan C, lalu kamu memilih A dan B, maka hanya A dan B yang akan diunduh.

The cached status of a torrent actually depends on this unique file selection
Status cached dari sebuah torrent sebenarnya bergantung pada pilihan file yang unik ini.

Going back to the torrent containing files A B and C, there are different cached status for A or B or B (single), A+B, B+C, A+C (pair), or A+B+C (all files)
Kembali ke torrent yang berisi file A, B, dan C, ada beberapa status cached yang berbeda untuk A atau B atau B (single), A+B, B+C, A+C (pair), atau A+B+C (all files).

Each unique selection redownloads the torrent again from trackers and returns a different cached link even if for the same file
Setiap pilihan unik akan mengunduh ulang torrent dari tracker dan menghasilkan link cached yang berbeda, meskipun untuk file yang sama.

# Tautan Cache {#cached-links}

Tautan cache bukan tautan yang bisa diunduh. Tautan itu hanya berfungsi sebagai wadah untuk KODE UNDUHAN di Real-Debrid.
Kamu harus "unrestrict" atau mengubahnya menjadi tautan asli yang bisa diunduh atau distreaming dari Real-Debrid, dan tautan itu kedaluwarsa setelah 7 hari.
Tautan cache bertahan lebih dari 7 hari. Jika sebuah torrent punya tautan cache yang masih berfungsi (artinya bisa di-unrestrict dengan berhasil), berarti torrent itu masih ter-cache di Real-Debrid.
Belum diketahui pasti, tetapi kemungkinan besar status cache sebuah torrent bisa diperpanjang jika lebih banyak pengguna meng-unrestrict tautan cache tersebut.

Perlu dicatat bahwa satu-satunya cara untuk memastikan tautan cache masih berfungsi adalah dengan meng-unrestrict-nya lalu memeriksa byte pertama dari tautan hasil unrestrict menggunakan header Range HTTP.
zurg mendukung dua cara verifikasi: HEAD (default, cepat) dan berbasis Range (GET bytes=0-0, lebih teliti) melalui opsi konfigurasi `use_range_verification`.

# Berbagi tautan cache antar akun (diukur 2026-08-19) {#cached-link-sharing-across-accounts-measured-2026-08-19}

RD mengembalikan ID link dalam dua panjang: 13 karakter (~70%) dan 16 karakter (~30%). 3 karakter ekstra itu menentukan SIAPA yang boleh melakukan unrestrict pada link tersebut:
- Kalau dipotong jadi 13 karakter pertama, link /d/ bisa di-unrestrict dari akun premium MANA PUN, tidak hanya akun yang membuatnya. Library torrent pemanggil tidak berubah. Satu-satunya efek sampingnya adalah entri di riwayat downloads pemanggil.
- Kalau dikirim dengan ID 16 karakter penuh, link yang sama hanya bisa di-unrestrict dari akun yang membuatnya. Akun lain akan mendapat "unavailable_file", bahkan saat torrent asalnya masih hidup, bahkan kalau pemanggil punya infohash yang sama di library-nya sendiri, dan terlepas dari parameter ip.

Jadi selalu potong jadi 13 karakter sebelum melakukan unrestrict pada link yang tersimpan. Tes dengan ID yang tidak dipotong akan "membuktikan" secara keliru bahwa berbagi link itu mustahil.

Link cache tetap bertahan saat akun pembuatnya menghapus torrent-nya, tetapi link itu mati karena umur. Dari sampel skala besar: link yang dibuat 1-2 bulan lalu masih bisa di-unrestrict lintas akun, sedangkan link yang lebih tua dari sekitar 3 bulan semuanya mengembalikan "hoster_unavailable". Terpisah dari itu, RD bisa mengeluarkan kontennya sendiri dari cache-nya (hash yang sebulan lalu terbukti cached bisa jadi downloading-from-0-seeders bulan berikutnya). Dalam kasus itu, link mengembalikan "unavailable_file" untuk semua orang, termasuk akun pembuatnya.

Cara membaca error unrestrict pada link cache yang tersimpan:
- Link 13 karakter + hoster_unavailable -> link sudah kedaluwarsa karena umur. Tambahkan lagi torrent dengan pemilihan file yang sama untuk mendapatkan link baru (lihat bagian perbaikan di bawah).
- Link 13 karakter + unavailable_file -> RD sudah mengeluarkan kontennya sepenuhnya. Link baru memerlukan download ulang sungguhan dari seeder.
- Link 16 karakter + unavailable_file -> ini tidak menunjukkan apa-apa soal ketersediaan. Kamu hanya bukan akun yang membuat link itu. Potong jadi 13 karakter lalu coba lagi.

Link yang sudah di-unrestrict (URL host *.download) diikat ke IP oleh pelacakan di sisi server, bukan dengan penolakan. CDN dengan senang hati melayani IP asing dengan 206, tetapi real-debrid mencatat IP download dan penggunaan link dari satu akun oleh banyak IP akan memicu peringatan berbagi akun. Kirimkan IP downloader ke unrestrict/link (parameter ip) supaya link dibuat untuk IP yang akan menarik datanya.

# Memperbaiki tautan cache yang rusak {#repairing-broken-cached-links}

Kadang tautan cache atau bahkan tautan unrestricted dari sebuah file di dalam torrent sudah tidak berfungsi lagi.
Ini bisa terjadi karena error API unrestrict, atau tautan unrestricted mengembalikan respons error HTTP.
Untuk memperbaikinya, kamu harus mengunduh ulang torrent dan membuat tautan cache baru atau segar.
Kamu bisa coba mengunduh ulang torrent dengan pilihan file yang sama persis, lalu lihat apakah tautan cache baru atau segar berhasil dibuat.
Kalau itu tidak berhasil, berarti kamu harus memilih file yang berbeda dari torrent tersebut.
Misalnya, kalau hanya satu file yang rusak dari torrent berisi banyak file, pilih hanya file yang rusak itu.
Kalau tautan cache yang dihasilkan masih rusak, coba tambahkan file lain ke pilihan.
Ulangi terus sampai kamu mendapatkan tautan cache segar yang berfungsi.

# Perilaku RAR {#rar-behavior}

Real-Debrid punya perilaku menyimpan torrent dalam file RAR (tanpa kompresi) jika kamu memilih tipe file yang tidak didukung dan tidak bisa di-stream
Tipe file video yang sudah dikonfirmasi: .avi .flv .m2ts .m4v .mkv .mov .mp4 .mpg .mpeg .ts .webm .wmv
Tipe file audio yang sudah dikonfirmasi: .mp3 .flac .m4a
Saat tipe file ini dipilih, Real-Debrid menghasilkan link file individual yang bisa di-stream
Kalau kamu memilih selain itu, dijamin Real-Debrid akan menyimpannya dalam arsip RAR
Kalau kamu memilih video .mkv dan subtitle .sub, file akan di-RAR
Begitu juga kalau kamu hanya memilih poster .jpg, file akan di-RAR

Sebuah torrent, meskipun punya banyak file, kalau di-RAR hanya akan menghasilkan satu link cached (yang mengarah ke file RAR)
Kalau kamu hanya memilih tipe file video/audio yang sudah dikonfirmasi, file tidak akan di-RAR dan kamu akan mendapat link cached untuk setiap file yang dipilih

# Menghapus baris daftar unduhan akan mencabut URL yang dibuatnya {#deleting-a-downloads-list-row-revokes-the-url-it-minted}

Diukur 2026-08-22 pada akun uji, satu unrestrict per kasus.

Sebuah unrestrict membuat baris di /downloads dan sebuah URL di satu host bernomor, misalnya
https://124-4.download.real-debrid.com/d/<13-char code>/<filename>. Kodenya tidak terikat ke host: sebelum baris dihapus, kode yang sama menjawab 200 di 44-4, 125-4, dan juga di 124-4 miliknya sendiri. Segmen nama file di akhir bersifat opsional di semua kasus; zurg menghapusnya dan kedua bentuk menjawab sama.

DELETE /downloads/delete/<id> mencabut kode itu, dan yang tersisa ditentukan oleh host mana saja yang sudah pernah menyajikannya:

  - Baris dihapus dengan URL belum pernah diambil: setiap host menjawab 404 dengan X-Error: invalid_download_code. Masih 404 30 detik kemudian, jadi kondisinya tidak berubah dengan sendirinya.
  - Baris dihapus setelah satu pengambilan lewat 44-4: 44-4 tetap menjawab 200, sementara host pencetak 124-4 dan 125-4 yang tidak pernah dipakai sama-sama menjawab 404 invalid_download_code.

Jadi pengambilan mengaktifkan kode di host yang menyajikannya, dan baris itulah yang membuat host lain tetap bisa menyajikan. Ini kebalikan dari asumsi yang menjadi dasar pembersihan daftar downloads, dan ini penting karena zurg memilih host unduhan per permintaan (ensureReachableDownloadServer menulis ulang ke salah satu dari N host tercepat): host yang dituju oleh HEAD verifikasi belum tentu host yang dipilih untuk permintaan berikutnya. Resolusi yang tertinggal di link cache setelah barisnya dihapus akan menjawab 404 invalid_download_code di hampir setiap permintaan berikutnya, yang terlihat seperti tautan yang sudah rusak dan menandai rilis yang sehat sebagai rusak.

Unrestrict ulang untuk link yang sama setelah penghapusan akhirnya mencetak id baru di host baru dan berfungsi normal. Id tidak pernah dipakai ulang.

Tapi tidak langsung. Pengukuran pertama di sini menulis "tidak terpengaruh" karena diambil beberapa menit kemudian. Diukur ulang 2026-08-23 pada akun uji: setelah DELETE /downloads/delete/<id>, unrestrict/link terus mengembalikan *id mati yang sama* selama 75 detik, dan baru mencetak id baru pada t+81s.

Dua hal mengikuti, dan keduanya ada di kode. downloadsCleanupMinAge menahan baris selama dua menit sebelum dipensiunkan, sehingga instance lain yang me-resolve link yang sama dalam jendela itu mendapat kode yang masih hidup. Dan jalur penyajian yang mengulang unrestrict (empat percobaan dalam sekitar enam detik) sepenuhnya berada di dalam jendela itu, jadi kegagalannya tidak menunjukkan apa-apa tentang file. Ketika setiap resolusi kembali sebagai URL yang baru saja menjawab 404, zurg menolak pembacaan dengan Retry-After alih-alih menandai rilis sebagai rusak.
