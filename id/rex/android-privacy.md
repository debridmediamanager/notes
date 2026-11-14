# rex untuk Android: kebijakan privasi {#rex-for-android-privacy-policy}

*Terakhir diperbarui: 14 November 2026.*

rex untuk Android menjalankan media server di perangkat kamu. rex tidak punya akun di kami, tanpa iklan dan tanpa analitik, dan rex tidak mengirim perpustakaan, tontonan, atau apa pun tentang kamu ke kami, kecuali untuk rex-direct dan log yang kamu pilih untuk dikirim, keduanya disebut di bawah.

## Apa yang keluar dari perangkat Anda, dan ke mana perginya {#what-leaves-your-device-and-where-it-goes}

| Where | What | When |
|---|---|---|
| **plex.tv** (Plex, Inc.) | Permintaan kode masuk dengan pengenal aplikasi acak dan nama server ini; lalu, setelah kamu menyetujuinya, permintaan sekali pakai untuk kode klaim | Saat kamu memilih Sign in to Plex |
| **plex.tv** | Nama server, pengenal, versi, dan alamat yang bisa dijangkau aplikasi Plex | Saat rex berjalan dan kamu sudah masuk, seperti yang dilaporkan server Plex mana pun tentang dirinya sendiri |
| **Layanan metadata Plex** | ID judul yang ditambahkan addon kamu, untuk mengambil poster dan deskripsi | Saat rex berjalan dan kamu sudah masuk |
| **debridmediamanager.com** (rex-direct) | Pengenal server, token server yang diberikan Plex, alamat IP lokal dan publik, serta port-nya | Setelah masuk, lalu setiap 6 jam, agar aplikasi Plex bisa menjangkau rex lewat HTTPS saat kamu di luar rumah |
| **logs.debridmediamanager.com** (log dukungan) | Versi aplikasi dan rex, model perangkat, versi Android dan jenis prosesor, port dan status rex, nama, versi, repositori, status, jumlah judul, sinkronisasi terakhir, dan error terakhir tiap addon, selisih zona waktu, serta log aplikasi untuk proses ini dan sebelumnya, dengan token, kunci, kata sandi, dan dua bagian terakhir alamat IP publik disembunyikan. Tidak pernah pengaturan addon, akun Plex, atau token kamu | Hanya saat kamu menekan Send di bawah Send logs to support, setelah melihat semuanya. Kamu mendapat kode untuk diberikan ke tim dukungan; hanya staf dukungan yang bisa membacanya, dan akan dihapus setelah 7 hari |
| **Repositori addon yang kamu tambahkan** (seperti github.com) | Permintaan untuk isi repositori | Saat kamu menambah atau menyegarkan repositori |
| **Situs tiap addon** | Apa yang diminta addon, misalnya permintaan katalog ke archive.org | Saat addon melakukan sinkronisasi atau judul diputar |

Kata sandi akun Plex kamu tidak pernah melewati aplikasi: kamu masuk di halaman Plex sendiri. Token akun yang diberikan proses masuk itu kepada aplikasi dipakai sekali untuk mengklaim server, lalu dibuang. rex hanya menyimpan token server yang diterbitkan Plex untuknya.

## Apa yang tetap ada di perangkat Anda {#what-stays-on-your-device}

Perpustakaan Anda, riwayat tontonan, pengaturan addon (termasuk kunci apa pun yang Anda ketik) dan log. Aplikasi menyimpan log untuk sesi ini dan sesi sebelumnya, sehingga jika aplikasi crash, log tidak hilang. Log menyembunyikan token, kunci, kata sandi, dan bagian akhir alamat IP publik. Log hanya keluar dari perangkat jika Anda memilih Share atau Send logs to support di layar Logs. Menghapus instalasi aplikasi akan menghapus semua data tersebut.

## Add-on {#addons}

Addon adalah kode dari siapa pun yang menulisnya, dipasang dari repositori yang Anda tambahkan. Kode itu berjalan terpisah dari bagian lain perangkat Anda dan hanya bisa mengakses situs yang disebutkannya, yang akan ditampilkan rex kepada Anda sebelum Anda memasangnya. Pasang addon hanya dari orang yang Anda percaya.

Addon yang membutuhkan akun di situs webnya, misalnya YouTube, masuk dengan kode: Anda memasukkannya di halaman milik situs tersebut, jadi kata sandi Anda tidak pernah melewati aplikasi. Token yang diberikan situs itu kepada addon tetap tersimpan di perangkat Anda dan hanya dikirim kembali ke situs tersebut. Menghapus addon akan menghapus token itu.

## Anak-anak {#children}

Aplikasi ini tidak ditujukan untuk anak-anak.

## Kontak {#contact}

support@debridmediamanager.com
