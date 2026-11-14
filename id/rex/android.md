# rex untuk Android {#rex-for-android}

rex adalah server media untuk aplikasi Plex yang tidak menyimpan file apa pun. rex untuk Android menjalankannya di ponsel, tablet, Android TV, Google TV, atau Fire TV, tanpa perlu komputer. Aplikasi Plex di perangkat Anda menemukannya seperti server Plex biasa dan memutar konten darinya.

Konten yang bisa diputar berasal dari **addon**. Awalnya ada film domain publik dari Internet Archive. Addon lain, seperti addon Stremio Anda, YouTube, dan Spotify, dapat dipasang dari dalam aplikasi setelah Anda menambahkan repository-nya.

rex untuk Android gratis. Ingin akun debrid dan Usenet Anda juga ada di sini? zurg+rex, server Plex di ponsel dengan zurg sudah terpasang, hadir dengan sponsorship: lihat [zurg+rex for Android](../zurg/guides/android.md).

## Sebelum kamu mulai {#before-you-start}

| Yang Anda butuhkan | Alasannya |
|---|---|
| Perangkat dengan Android 8.0 atau lebih baru | Ponsel, tablet, Android TV, Google TV atau Fire TV. Fire TV dengan Vega OS, seperti Fire TV Stick 4K Select, tidak menjalankan aplikasi Android |
| Akun Plex | rex muncul di aplikasi Plex yang masuk dengan akun tersebut. Akun gratis sudah cukup |
| Aplikasi Plex di perangkat tempat Anda menonton | Plex untuk Android, Android TV, iPhone, smart TV, Plex Web, Plexamp |

## Langkah 1. Dapatkan aplikasinya {#step-1-get-the-app}

Pilih satu cara. Setiap cara memperbarui rex dengan caranya sendiri.

| Cara | Cocok untuk |
|---|---|
| Google Play | Ponsel, tablet, Android TV dan Google TV. Segera hadir |
| Amazon Appstore | Fire TV dan tablet Fire. Segera hadir |
| [Obtainium](#with-obtainium) | Ponsel dan tablet. Pembaruan datang dengan sendirinya |
| [Downloader](#with-downloader-on-fire-tv) | Fire TV dan kotak TV |
| [File dari GitHub](#the-file-from-github) | Perangkat apa pun. Kamu memasang pembaruan sendiri |

**Cara-cara ini tidak bisa dicampur.** Google Play, Amazon Appstore, dan file dari GitHub (yang juga dipasang oleh Obtainium dan Downloader) ditandatangani secara berbeda, jadi yang satu tidak bisa memperbarui yang lain. Untuk berpindah, hapus rex lalu lakukan Langkah 2 dan 3 lagi.

**Cara-cara ini mulai dengan addon yang berbeda.** File dari GitHub dimulai dengan repositori [rex-addons](https://github.com/debridmediamanager/rex-addons) sudah ditambahkan. Versi di toko hanya dimulai dengan addon Internet Archive; tambahkan rex-addons sendiri (lihat [Add-on](#addons)) jika kamu menginginkannya.

### Dengan Obtainium {#with-obtainium}

[Obtainium](https://obtainium.imranr.dev/) memasang aplikasi dari GitHub dan menjaganya tetap terbarui.

1. Pasang Obtainium.
2. Di perangkat yang sama, buka [rex.debridmediamanager.com/obtainium](https://rex.debridmediamanager.com/id/obtainium). Obtainium akan terbuka dan menanyakan **Import app**. Tekan **Continue**.
3. Tekan **rex**, lalu **Install**. Obtainium akan memilih file yang sesuai dengan prosesor perangkatmu.
4. Pertama kali, Android akan bilang bahwa Obtainium tidak diizinkan memasang aplikasi. Aktifkan **Allow from this source** lalu kembali.
5. Tekan **Install**. Jika Play Protect menampilkan **App scan recommended**, tekan **Scan app**, lalu **Install**.

Saat ada versi baru, Obtainium akan menampilkan **Update** di sebelah rex.

### Dengan Downloader di Fire TV {#with-downloader-on-fire-tv}

1. Di Fire TV, pasang **Downloader** buatan AFTVnews dari Appstore.
2. Buka aplikasinya, pilih kotak alamat, lalu ketik `rex.debridmediamanager.com/tv`. Tekan **Next**. Aplikasi akan mengunduh `rex-android-armeabi-v7a.apk`.
3. Tekan **Install**. Pertama kali, Fire TV malah membuka **Developer options**. Pilih **Install unknown apps**, lalu pilih **Downloader** sampai tulisannya **ON**. Tekan Back dua kali, lalu tekan **Install** lagi.
4. Tekan **Install**, lalu **Open**.

Untuk memperbarui, ulangi langkah 2 sampai 4. Kode pendek Downloader akan segera tersedia.

### File dari GitHub {#the-file-from-github}

On perangkat, unduh file untuk prosesornya. Setiap tautan selalu mengarah ke versi terbaru:

| Perangkat Anda | Unduh |
|---|---|
| Sebagian besar ponsel, tablet, dan TV box (64-bit) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Fire TV, dan box 32-bit yang lebih lama atau lebih murah | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Emulator di PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Setiap versi beserta perubahannya ada di [halaman releases](https://github.com/debridmediamanager/rex-android/releases). Belum yakin? Coba `arm64-v8a` dulu. Satu file ini berfungsi untuk ponsel maupun TV.

Buka file yang sudah diunduh. Android akan bilang bahwa **isn't allowed to install unknown apps from this source**. Tekan **Settings**, nyalakan **Allow from this source**, kembali, lalu tekan **Install**.

Untuk memperbarui, instal file baru di atas file lama. rex akan mulai lagi dengan sendirinya dan sign-in serta addon Anda tetap tersimpan.

**Yang seharusnya Anda lihat.** **rex** ada di daftar aplikasi Anda.

## Langkah 2. Jalankan rex {#step-2-start-rex}

**Buka rex.** Layar pertama bertuliskan **Welcome to rex.**

1. Tekan **Allow notifications**, lalu **Allow**. rex berjalan di latar belakang dengan notifikasi yang bisa kamu pakai untuk menghentikannya.
2. Tekan **Let rex keep running in the background**. Di daftar yang terbuka, pilih **rex** lalu pilih **Don't optimize**. Di Android yang lebih baru, tombolnya **Allow background usage**, lalu **Unrestricted**. Kembali ke rex. Kedua tombol sekarang diawali ✓.
3. **Name** adalah nama yang ditampilkan aplikasi Plex untuk server ini. Ubah kalau kamu mau.
4. Biarkan **Port** di `32400`. Kalau ada server Plex lain yang sudah berjalan di perangkat ini, rex akan menampilkan **Another app here already uses this port, maybe a Plex server. Try 32500.** Ketik `32500`.
5. Tekan **Start rex**.

**Yang seharusnya kamu lihat.** **2 / 2** dan **Sign in to Plex.**

| Layar pertama | Halaman film di aplikasi Plex (Langkah 4) |
|---|---|
| ![Layar pertama rex untuk Android, dengan kolom name dan port serta tombol Start rex](../assets/rex/android-setup.webp) | ![Film bisu tahun 1916 dari Internet Archive di halaman Plex untuk Android](../assets/rex/android-plex-film.webp) |

## Langkah 3. Masuk ke Plex {#step-3-sign-in-to-plex}

Tekan **Sign in to Plex**. rex menampilkan kode: **On any phone or computer, go to plex.tv/link and enter** it.

- **On a phone or tablet** browser kamu juga akan membuka halaman Plex yang bertuliskan **rex for Android would like to sign in to your Plex account**. Masuk di sana.
- **On a TV** buka [plex.tv/link](https://plex.tv/link) di ponsel atau komputer kamu, masuk, lalu masukkan kodenya.

Gunakan akun yang dipakai untuk masuk di aplikasi Plex kamu. Kamu bisa menekan **Skip for now** dan masuk nanti dari **Status**.

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**Yang seharusnya kamu lihat.** **Signed in. rex shows up in the Plex apps as** nama server kamu. Tekan **Done**. **Status** menampilkan **RUNNING** dan **Ready for the Plex apps.**

## Langkah 4. Tonton di aplikasi Plex {#step-4-watch-in-a-plex-app}

Buka aplikasi Plex mana pun yang sudah masuk dengan akun yang sama. Jika Plex ada di perangkat ini, **Status** punya tombol **Open Plex**.

Di Plex untuk Android, buka **Libraries**, lalu **All Libraries**, lalu **Movies** di bawah nama server Anda. Aplikasi Plex lain juga menampilkannya di bawah nama server.

Sinkronisasi pertama Internet Archive butuh waktu. Kira-kira setengah jam di perangkat uji kami, sambil rex memeriksa setiap film. **Status** menampilkan **Syncing** sampai selesai, lalu jumlahnya, misalnya **Ready · 97 titles**. Tekan putar pada film mana pun.

![Aplikasi Plex di TV memutar film pendek Chaplin 1914 dari rex di TV yang sama](../assets/rex/android-tv-playing.webp)

## Add-on {#addons}

**Addons** menampilkan daftar addon yang sudah Anda pasang. Setiap addon menampilkan judulnya dan kapan terakhir kali disinkronkan. Tombolnya adalah **Sync now**, **Settings**, **Log** dan **Remove**; di ponsel, geser baris tombol ke samping untuk melihat semuanya. Sakelar **Enabled** mematikan addon tanpa menghapusnya.

Addon berasal dari **repositories**: repositori git yang berisi addon. Addon Internet Archive sudah terpasang. Untuk lebih banyak, tambahkan [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) (lihat **Add a repository** di bawah), yang menyediakan:

| Addon | Apa yang dibawa |
|---|---|
| Stremio addons | Katalog film dan serial dari addon Stremio Anda, diputar dari stream yang diberikan addon stream Anda |
| YouTube | Playlist YouTube Anda. Anda masuk dengan kode |
| Spotify | Pustaka Spotify Anda sebagai musik untuk Plex dan Plexamp. Perlu addon YouTube, yang sudah masuk |

**Pasang satu.** Di bawah **Repositories**, tekan **Addons** di samping repositori, lalu **Install** di bawah addon. rex menampilkan situs web mana saja yang bisa dijangkau dan bertanya sekali lagi, lalu mulai menyinkronkannya.

**Masuk.** Addon yang memerlukan akun Anda akan menampilkan **Sign in to start.** Tekan tombol **Sign in**-nya: buka halaman yang disebutkan di perangkat apa pun dan masukkan kode yang ditampilkan.

**Tambah repositori.** Di bawah **Add a repository**, ketik tautannya (`github.com/user/repo` sudah cukup) lalu tekan **Add**. Pasang hanya dari orang yang Anda percaya. Untuk membuat addon sendiri, lihat [rex-addons](https://github.com/debridmediamanager/rex-addons).

## Tonton di perangkat lain di rumah {#watch-on-other-devices-at-home}

Setiap aplikasi Plex yang masuk dengan akun yang sama akan menemukan rex di jaringan rumah Anda lewat namanya: TV Anda, ponsel lain, Plex Web di komputer. **Status** menampilkan alamat rex di rumah, seperti `http://192.168.1.20:32400`.

Untuk membiarkan keluarga menonton dengan akun Plex mereka sendiri, lihat [Bagikan rex ke keluarga dan teman](sharing.md).

## Biarkan tetap berjalan {#keep-it-running}

- rex berjalan selama perangkat menyala. **Stop** pada notifikasi akan menghentikannya; **Status** memiliki **Start**, **Stop** dan **Restart**.
- Di **Settings**, aktifkan **Start when this device turns on**. Jika tidak, buka rex dan tekan **Start** setelah perangkat dinyalakan ulang.
- Beberapa ponsel tetap menghentikan aplikasi latar belakang. [Don't kill my app](https://dontkillmyapp.com/) menjelaskan apa yang dibutuhkan aplikasimu.
- Untuk mengganti nama server, buka **Settings**, **General** di aplikasi Plex dan ubah **Friendly name**.

## Batasan {#limits}

- **Bisa diputar di rumah.** Di luar rumah, aplikasi Plex butuh alamat HTTPS yang bisa menjangkau perangkat, dan itu berarti perlu port forward di router ke perangkat tersebut. Lihat [Gunakan di luar rumah Anda](any-source.md#use-it-outside-your-home-optional).
- **Perangkatnya adalah servernya.** Biarkan menyala, terhubung lewat Wi-Fi atau Ethernet, dan tetap dicolokkan. Mengonversi video untuk pemutar yang tidak bisa memutar sebuah file memakai hardware bawaan perangkat dan bisa jadi lambat di kotak murah.
- **Hanya yang dibawa addon.** Perangkat ini tidak punya pustaka file sendiri.

## Pemecahan masalah {#troubleshooting}

| Yang Anda lihat | Yang harus dilakukan |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Anda memilih file yang salah untuk prosesornya. Coba file yang lain dari tabel di Langkah 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Ketik `32500` sebagai port |
| **Use a number from 1024 to 65535** | Port harus berupa angka dalam rentang itu |
| Server tidak ada di aplikasi Plex | Masuk ke aplikasi Plex dengan akun yang sama seperti di Langkah 3, dan pastikan kedua perangkat berada di jaringan rumah yang sama |
| Perpustakaan kosong | Sinkronisasi pertama masih berjalan: tunggu sampai **Status** menampilkan jumlah judul |
| **Sign in needed** di bawah addon | Tekan tombol **Sign in** pada addon itu dan masukkan kodenya |
| **Needs an update** di bawah addon | Versi aplikasi ini tidak bisa lagi menjalankan salinan addon tersebut. Segarkan repository-nya lalu tekan **Update**. Judul-judulnya tetap ada sementara itu |
| **That isn't a repository link. Try github.com/user/repo.** | Ketik tautan repository, misalnya `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | Tautannya salah atau repository-nya privat. Periksa di browser |
| rex berhenti saat layar mati | Atur ulang pengaturan latar belakang di Langkah 2, dan lihat [Jangan matikan aplikasi saya](https://dontkillmyapp.com/) |

**Logs** menampilkan apa yang dikatakan rex dan addon belakangan ini, dengan kunci dan kata sandi disembunyikan. Jika tim support meminta log, tekan **Send logs to support**: Anda bisa melihat semuanya sebelum apa pun dikirim, lalu tekan **Send** dan posting kode yang Anda dapat.

Apa yang dikirim aplikasi dan ke mana, ada di [kebijakan privasi](android-privacy.md)-nya.

Masih bingung? Tanyakan di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP).
