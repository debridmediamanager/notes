# rex untuk Android: kebijakan privasi {#rex-for-android-privacy-policy}

*Terakhir diperbarui: 16 November 2026.*

rex untuk Android menjalankan server media di perangkat Anda. Aplikasi ini tidak punya akun di kami, tidak ada iklan dan tidak ada analitik, dan tidak mengirim perpustakaan, tontonan, atau informasi apa pun tentang Anda kepada kami, kecuali untuk rex-direct dan log yang Anda pilih untuk dikirim, yang keduanya disebutkan di bawah.

## Apa yang keluar dari perangkat Anda, dan ke mana perginya {#what-leaves-your-device-and-where-it-goes}

| Lokasi | Isi | Kapan |
|---|---|---|
| **plex.tv** (Plex, Inc.) | Permintaan kode masuk (di ponsel atau tablet, satu lagi untuk halaman masuk Plex) dengan identifier aplikasi acak dan nama server ini; lalu, setelah Anda menyetujui satu, permintaan sekali pakai untuk kode klaim | Saat Anda memilih Sign in to Plex |
| **plex.tv** | Nama server, identifier, versi, dan alamat yang bisa dijangkau aplikasi Plex, sebagaimana server Plex mana pun melaporkan dirinya | Selama rex berjalan dan sudah masuk |
| **Layanan metadata Plex** | Id judul yang ditambahkan addon Anda, untuk mengambil poster dan deskripsi | Selama rex berjalan dan sudah masuk |
| **debridmediamanager.com** (rex-direct) | Identifier server, server token yang diberikan Plex, alamat IP lokal dan publiknya, serta port-nya | Setelah masuk, lalu setiap 6 jam, agar aplikasi Plex bisa menjangkau rex lewat HTTPS saat Anda di luar rumah |
| **logs.debridmediamanager.com** (log dukungan) | Versi aplikasi dan rex, model perangkat, versi Android, dan jenis prosesor, port dan status rex, nama, versi, repositori, status, jumlah judul, sinkronisasi terakhir, dan error terakhir tiap addon, selisih zona waktu, serta log aplikasi untuk proses ini dan proses sebelumnya, dengan token, kunci, kata sandi, dan dua bagian terakhir alamat IP publik disembunyikan. Tidak pernah berisi pengaturan addon, akun Plex, atau token Anda | Hanya saat Anda menekan Send di bawah Send logs to support, setelah melihat semuanya. Anda mendapat kode untuk diberikan ke tim dukungan; hanya staf dukungan yang bisa membacanya, dan kode itu dihapus setelah 7 hari |
| **Repositori addon yang Anda tambahkan** (seperti github.com) | Permintaan untuk isi repositori | Saat Anda menambah atau menyegarkan repositori |
| **Situs tiap addon** | Apa yang diminta addon, misalnya permintaan katalog ke archive.org | Saat addon melakukan sinkronisasi atau judul diputar |

Kata sandi akun Plex Anda tidak pernah melewati aplikasi: Anda masuk di halaman Plex sendiri. Token akun yang diberikan proses masuk itu ke aplikasi hanya dipakai sekali untuk mengklaim server, lalu dibuang. rex hanya menyimpan server token yang diterbitkan Plex untuknya.

## Apa yang tetap ada di perangkat Anda {#what-stays-on-your-device}

Perpustakaan Anda, riwayat tontonan, pengaturan addon (termasuk kunci apa pun yang Anda ketik) dan log. Aplikasi menyimpan log untuk sesi ini dan sesi sebelumnya, sehingga jika aplikasi crash, log tidak hilang. Log menyembunyikan token, kunci, kata sandi, dan bagian akhir alamat IP publik. Log hanya keluar dari perangkat jika Anda memilih Share atau Send logs to support di layar Logs. Menghapus instalasi aplikasi akan menghapus semua data tersebut.

## Add-on {#addons}

Addon adalah kode dari orang yang membuatnya, dipasang dari repositori yang Anda tambahkan. Kode ini berjalan terpisah dari bagian lain perangkat Anda dan hanya bisa mengakses situs yang disebutkannya, yang ditampilkan rex kepada Anda sebelum Anda memasangnya. Pasang addon hanya dari orang yang Anda percaya.

Addon yang memerlukan akun di situs webnya masuk dengan kode: Anda memasukkannya di halaman situs web tersebut, jadi kata sandi Anda tidak pernah melewati aplikasi. Token yang diberikan situs web itu kepada addon tetap tersimpan di perangkat Anda dan hanya dikirim kembali ke situs web itu. Menghapus addon akan menghapus token tersebut.

## Anak-anak {#children}

Aplikasi ini tidak ditujukan untuk anak-anak.

## Kontak {#contact}

support@debridmediamanager.com
