# Akuisisi watchlist Plex {#plex-watchlist-acquisition}

Watchlist Plex adalah adapter pada [mesin akuisisi bersama](acquisition.md),
bersama Seerr. Pengaturan `watchlist.enabled` dan pengaturan watchlist Plex versi lama
tetap berfungsi. Adapter ini mencari judul dari watchlist cloud dan menyerahkannya
ke executor bersama. Adapter mulai setelah library selesai dimuat. Adapter membutuhkan
provider `nzb` pada instance zurg yang sama, akun debrid yang menerima torrent, atau keduanya.

Progres disimpan di `data/acquisition.json`. File `data/plex-watchlist.json` yang lama
diimpor sekali tanpa dihapus. Riwayat, tenggat retry, jumlah percobaan, dan
akuisisi yang hanya menunggu penghapusan dari Plex tetap aman setelah reboot. Kedua file state
ikut dalam backup normal. Simpan `data/` dan
`nzbs/` saat membuat ulang container.

Rilis datang dari indexer Newznab sebagai NZB dan dari indexer Torznab sebagai info
hash yang diserahkan ke akun debrid yang sudah memilikinya. NZB membutuhkan
provider `nzb`. Torrent membutuhkan akun debrid. `prefer` menentukan mana yang dicoba
lebih dulu di antara rilis dengan resolusi yang sama. Lihat [Newznab dan Torznab](acquisition.md#newznab-and-torznab).

Akuisisi yang berhasil menghapus item dari watchlist, kecuali `remove_after_grab: false`
menyatakan lain; jika opsi ini dimatikan, judul tetap ada dan zurg memenuhinya di
latar belakang. Judul yang sudah kamu miliki tetap ada dalam kondisi apa pun: jika setiap rilis
yang menyelesaikannya sudah ada di library, zurg tidak mengambil apa pun untuknya dan
membiarkan daftar kamu tetap utuh. `only_new_items` (aktif secara default) berarti saat fitur
ini dinyalakan, zurg mulai memantau daftar, bukan mengerjakan semua yang sudah ada di dalamnya.
Keduanya didokumentasikan di
[apa yang dilakukan akuisisi pada daftar milik sumber](acquisition.md#what-acquiring-does-to-the-sources-own-list). Setiap season
yang direncanakan sekarang harus diakuisisi sebelum sebuah show dihapus; season yang berhasil
diingat, sementara season yang belum berhasil akan di-retry. Season pack lebih diutamakan.
Fallback episode lepas mengakuisisi episode yang ditemukan di hasil indexer, karena
watchlist tidak menyediakan daftar episode yang diharapkan. Ini bukan pemantauan terus-menerus
terhadap episode baru setelah item keluar dari watchlist.

Penghapusan menunggu pengecekan. Entri watchlist adalah satu-satunya catatan bahwa kamu
menginginkan sebuah judul. Plex tidak menyimpan riwayat untuk entri yang sudah dihapus. Jadi sebuah judul
tidak pernah dihapus hanya berdasarkan grab yang belum diperiksa. NZB diperiksa
terhadap news server. Torrent harus sampai ke library dengan file di dalamnya. Rilis
yang gagal pengecekan membiarkan judul tetap di tempatnya dan dicatat sebagai mati. Retry
kemudian memberi peringkat pada kandidat berikutnya. Pengecekan yang tidak bisa dilakukan
membuat judul tetap dalam antrean, bukan memutuskan apa pun.
Lihat [memverifikasi hasil grab](acquisition.md#verifying-a-grab).

Kegagalan di-retry dengan backoff yang persisten selama item masih ada di daftar.
Setelah akuisisi tercatat, penghapusan Plex yang gagal atau terputus hanya di-retry
untuk penghapusan itu saja. State yang rusak dipertahankan dan akuisisi dijeda sampai
diperbaiki atau dipulihkan. Kegagalan tulis menjeda akuisisi sampai penyimpanan berhasil.

Lihat [sumber akuisisi](acquisition.md) untuk konfigurasi, interval retry, perilaku
Seerr, dan kontrak adapter.
