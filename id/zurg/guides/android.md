# zurg+rex untuk Android dan Google TV {#zurgrex-for-android-and-google-tv}

Aplikasi Android menjalankan mesin zurg di perangkat dan rex di sampingnya: server Plex Anda sendiri di ponsel atau kotak TV Anda, untuk aplikasi Plex. Satu aplikasi berfungsi di ponsel, tablet, Android TV, dan Google TV. Android 8.0 atau yang lebih baru diperlukan. Fire TV dapat memasang APK yang sama lewat sideload. Gunakan pemutar WebDAV jika tidak ada aplikasi Files bawaan sistem. Usenet memerlukan Android 64-bit; NZB yang di-host TorBox (`torbox_nzb`) tidak tersedia di Android.

Tidak punya akun debrid atau Usenet, hanya addon? [rex untuk Android](../../rex/android.md) gratis dan tidak perlu sponsorship.

## Pasang dan atur {#install-and-set-up}

[Unduh APK](https://zurg.debridmediamanager.com/id/download.html#android) dari rilis nightly di repositori sponsor pribadi. Pilih `arm64-v8a` untuk
kebanyakan ponsel dan TV box, `armeabi-v7a` untuk perangkat 32-bit yang lebih lama, atau `x86_64` untuk emulator atau
Chromebook yang kompatibel. Setiap APK sudah menyertakan antarmuka ponsel dan TV.

Aplikasi ini tidak berisi zurg itu sendiri. Setelah masuk ke GitHub, kamu instal engine dari dalam aplikasi. Akun sponsor diperlukan. Jadi sponsor di [gatekeeper](https://gatekeeper.debridmediamanager.com/) untuk memberi akun GitHub kamu akses. Setup akan memandu kamu melewati langkah ini.

Izinkan instalasi dari aplikasi yang kamu pakai untuk membuka APK. Android atau Play Protect mungkin meminta kamu mengonfirmasi sideloading. ID aplikasinya adalah `com.debridmediamanager.zurg`. Update harus mempertahankan identitas penandatanganan rilis.

1. Buka zurg dan masuk ke GitHub, lalu instal versi engine. Aplikasi
   tidak bisa memulai library sebelum engine terpasang.
2. Tambahkan akun provider dan uji kredensialnya. Nama akun membedakan beberapa akun di provider yang sama. Batas koneksi Usenet mencakup semua pemakai lain dari akun tersebut.
3. Pilih Phone, Tablet, TV box, atau TV stick. Profil mengatur target memori engine dan ukuran cache disk. Target heap Go bukan batas RSS yang ketat.
4. Izinkan notifikasi dan operasi latar belakang. Aktifkan start after reboot jika perangkat ini harus selalu menyajikan library.
5. Mulai library. Pemuatan pertama untuk akun besar bisa memakan waktu beberapa menit. Notifikasi dan layar Status menunjukkan kapan direktori sudah siap.

## Tonton di perangkat ini {#watch-on-this-device}

Gunakan Library untuk menelusuri folder dan memutar file. More menawarkan pemutar lain atau URI dokumen Android. Pemutar yang kamu pilih bisa dijadikan pemutar utama. Files dan document picker menampilkan library yang sama di bawah root penyimpanan zurg. File di-stream dengan random access, jadi tidak diunduh penuh dulu. Buka pemutarmu sekali dan selesaikan setup-nya sebelum memilihnya dari Files.

Untuk pemutar WebDAV, tambahkan `http://127.0.0.1:9999/dav/` sebagai source. Pakai port yang tertera di Status kalau kamu mengubah port-nya. VLC, Kodi, dan Nova bisa menelusuri source WebDAV. Pemutar yang hanya menerima URL satu per satu bisa dijalankan dari Library. Di TV, gunakan D-pad dan Select untuk memindahkan dan mengaktifkan kontrol, Back untuk kembali, dan Menu atau More untuk aksi release. Pilih text field untuk mengeditnya, lalu tekan Back untuk kembali ke navigasi. Long-press juga membuka More di ponsel.

Repair, rename, tags, show all files, dan delete bekerja pada seluruh release yang memilikinya. Delete akan minta konfirmasi dan menghapus dari akun provider-nya. MediaInfo memakai ffprobe yang sudah termasuk, lalu menampilkan detail video, audio, dan subtitle di dashboard. Kamu tidak perlu memasang tool media terpisah.

## Tonton di aplikasi Plex {#watch-in-the-plex-apps}

Mulai dari nightly tanggal 10 November 2026, aplikasi ini juga menjalankan rex (di perangkat 64-bit pada nightly tersebut, dan di semua perangkat yang didukung mulai dari nightly 11 November), sebuah media server untuk aplikasi Plex, lalu mengarahkan zurg ke sana. Dengan begitu, library Anda muncul di aplikasi Plex resmi dan di Plezy, di perangkat ini maupun di perangkat lain di rumah Anda. Setelah library Anda berjalan, Status menampilkan **rex for the Plex apps**: pilih **Sign in to Plex** dan setujui sign-in-nya (di TV, masukkan kode di plex.tv/link). Server akan muncul di Plex dengan nama perangkat ini. rex mengonversi apa pun yang tidak bisa diputar oleh pemutar dengan encoder hardware perangkat. Untuk mematikan rex, buka Settings, Connection; zurg kemudian berhenti mengirimkan data ke sana.

## Bagikan lewat jaringan lokal {#share-over-the-local-network}

In Settings, aktifkan **Expose on local network**. zurg membuat kredensial dan menampilkan alamat WebDAV LAN perangkat. Masukkan alamat itu dan kredensial tersebut ke player di perangkat lain. Pastikan perangkat Android host tetap menyala dan berjalan.
Autentikasi HTTP basic tidak mengenkripsi lalu lintas; gunakan jaringan lokal yang tepercaya.
Loopback adalah default. Intent player tidak pernah berisi kata sandi server Anda.

## Pengaturan, cadangan, dan pembaruan {#settings-backups-and-updates}

Settings mencakup koneksi, provider, library, repair, resources, dan logging.
Advanced menerima YAML mentah dan meminta engine yang terpasang untuk memvalidasinya sebelum disimpan. Settings tidak punya kolom untuk DMM API key kamu. Tambahkan `dmm_api_key: YOUR_DMM_API_KEY` di Advanced untuk [daftar wanted DMM](dmm-wanted.md) dan penamaan rilis DMM. Saat menyimpan konfigurasi yang sedang berjalan, aplikasi akan bertanya dulu sebelum me-restart server.
Web dashboard membuka dashboard lokal untuk pengaturan integrasi desktop.

Logs berisi output terbaru dari engine dan 200 baris terakhir dari supervisor.
Saat log dibagikan, secret dan URL yang sudah dikonfigurasi akan disamarkan. Backups berisi kredensial dan state library, jadi simpan di tempat yang privat. Hentikan zurg sebelum melakukan restore. Android menolak link backup dan file khusus, dan restore dilakukan ke loopback dulu.

Updates memeriksa repositori sponsor yang privat. Sign-in perangkat GitHub meminta scope `repo` karena release assets-nya bersifat privat. Token GitHub dienkripsi dengan preferences yang didukung Android Keystore. Token yang kamu masukkan secara manual juga didukung, selama punya akses baca ke repositori tersebut. Jika Android tidak bisa lagi mendekripsi sign-in yang tersimpan, Updates akan meminta kamu sign in ulang dan konfigurasi library kamu tetap dipertahankan. Update yang diunduh harus cocok dengan application ID dan signing key, serta memiliki version code yang lebih baru. Installer Android akan bertanya dulu sebelum mengganti aplikasi.

Jika kamu memperbarui dari build yang sudah membawa engine sendiri, aplikasi akan kehilangan engine-nya. Pasang engine dari Updates sekali saja, dan provider serta pengaturan library kamu akan tetap terbawa tanpa diubah.

Aplikasi dan engine diperbarui secara terpisah. Updates menampilkan engine versi dari 30 rilis terbaru di repositori sponsor, menandai yang sedang kamu pakai, dan bisa memasang versi mana pun dari daftar itu. Jika nightly baru bermasalah di perangkatmu, pasang versi yang sudah terbukti bekerja untukmu. Hentikan library kamu di Status sebelum mengganti engine. Aplikasi hanya menjalankan paket engine yang ditandatangani dengan kuncinya sendiri, dan memeriksanya lagi setiap kali aplikasi dijalankan.

Notifikasi persisten punya aksi Stop. Tile Quick Settings juga bisa menjalankan atau menghentikan server. Battery exemption membantu mengatasi batasan idle Android. Task killer dari pabrikan tertentu mungkin memerlukan pengaturan tambahan. Lihat [Jangan matikan aplikasiku](https://dontkillmyapp.com/).
