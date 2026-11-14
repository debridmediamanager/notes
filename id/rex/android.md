# rex untuk Android {#rex-for-android}

rex adalah server media untuk aplikasi Plex yang tidak menyimpan file apa pun. rex untuk Android menjalankannya di ponsel, tablet, Android TV, Google TV, atau Fire TV, tanpa perlu komputer. Aplikasi Plex di perangkat Anda menemukannya seperti server Plex biasa dan memutar konten darinya.

Konten yang bisa diputar berasal dari **addon**. Awalnya ada film domain publik dari Internet Archive. Addon lain, seperti addon Stremio Anda, YouTube, dan Spotify, dapat dipasang dari dalam aplikasi setelah Anda menambahkan repository-nya.

rex untuk Android gratis. Ingin akun debrid dan Usenet Anda juga ada di sini? zurg+rex, server Plex di ponsel dengan zurg sudah terpasang, hadir dengan sponsorship: lihat [zurg+rex for Android](../zurg/guides/android.md).

## Sebelum kamu mulai {#before-you-start}

| Yang Anda butuhkan | Alasannya |
|---|---|
| Perangkat dengan Android 8.0 atau lebih baru | Ponsel, tablet, Android TV, Google TV atau Fire TV |
| Akun Plex | rex muncul di aplikasi Plex yang login dengan akun tersebut. Akun gratis sudah cukup |
| Aplikasi Plex di perangkat tempat Anda menonton | Plex untuk Android, Android TV, iPhone, smart TV, Plex Web, Plexamp |

Aplikasi ini belum ada di Google Play. Anda perlu memasang file aplikasinya (APK) sendiri.

## Langkah 1. Unduh {#step-1-download-it}

| Perangkat Anda | Unduh |
|---|---|
| Sebagian besar ponsel, tablet, dan TV box (64-bit) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| Box 32-bit yang lebih lama atau lebih murah, termasuk Fire TV Stick | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| Emulator di PC | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

Pada perangkat Anda, unduh file yang sesuai dengan prosesornya. Setiap tautan selalu mengarah ke versi terbaru.

Semua versi beserta perubahannya ada di [halaman rilis](https://github.com/debridmediamanager/rex-android/releases).

Belum yakin? Coba `arm64-v8a` dulu. Satu file ini bisa dipakai di ponsel maupun TV.

## Langkah 2. Pasang {#step-2-install-it}

Buka file yang sudah diunduh. Android akan bertanya dulu:

1. Muncul tulisan bahwa aplikasi **tidak diizinkan untuk memasang aplikasi tidak dikenal dari sumber ini**. Tekan **Settings**, nyalakan **Allow from this source**, lalu kembali.
2. Tekan **Install**.

Di TV box tanpa browser, unduh file dengan aplikasi downloader yang bisa membuka APK.

**Yang seharusnya terlihat.** **rex** ada di daftar aplikasi Anda.

## Langkah 3. Jalankan rex {#step-3-start-rex}

Buka **rex**. Layar pertama bertuliskan **Welcome to rex.**

1. Tekan **Allow notifications**, lalu **Allow**. rex berjalan di latar belakang dengan notifikasi yang bisa kamu pakai untuk menghentikannya.
2. Tekan **Let rex keep running in the background**. Di daftar yang terbuka, pilih **rex** dan pilih **Don't optimize**. Di Android yang lebih baru, pilihannya **Allow background usage**, lalu **Unrestricted**. Kembali ke rex. Kedua tombol sekarang diawali ✓.
3. **Name** adalah nama yang ditampilkan aplikasi Plex untuk server ini. Ubah kalau kamu mau.
4. Biarkan **Port** di `32400`. Kalau ada server Plex lain yang sudah berjalan di perangkat ini, rex akan menampilkan **Another app here already uses this port, maybe a Plex server. Try 32500.** Ketik `32500`.
5. Tekan **Start rex**.

**Yang harus kamu lihat.** **2 / 2** dan **Sign in to Plex.**

| Layar pertama | Halaman film di aplikasi Plex (Langkah 5) |
|---|---|
| ![Layar pertama rex untuk Android, dengan kolom nama dan port serta tombol Start rex](../assets/rex/android-setup.webp) | ![Film bisu tahun 1916 dari Internet Archive di halamannya di Plex untuk Android](../assets/rex/android-plex-film.webp) |

## Langkah 4. Masuk ke Plex {#step-4-sign-in-to-plex}

Tekan **Sign in to Plex**. rex menampilkan kode: **On any phone or computer, go to plex.tv/link and enter** it.

- **On a phone or tablet** browser kamu juga akan membuka halaman Plex yang bertuliskan **rex for Android would like to sign in to your Plex account**. Masuk di sana.
- **On a TV** buka [plex.tv/link](https://plex.tv/link) di ponsel atau komputer kamu, masuk, lalu masukkan kodenya.

Gunakan akun yang dipakai untuk masuk di aplikasi Plex kamu. Kamu bisa menekan **Skip for now** dan masuk nanti dari **Status**.

![rex for Android on a TV showing the code to enter at plex.tv/link](../assets/rex/android-tv-signin.webp)

**Yang seharusnya kamu lihat.** **Signed in. rex shows up in the Plex apps as** nama server kamu. Tekan **Done**. **Status** menampilkan **RUNNING** dan **Ready for the Plex apps.**

## Langkah 5. Tonton di aplikasi Plex {#step-5-watch-in-a-plex-app}

Buka aplikasi Plex mana pun yang sudah masuk dengan akun yang sama. Jika Plex ada di perangkat ini, **Status** punya tombol **Open Plex**.

Di Plex untuk Android, buka **Libraries**, lalu **All Libraries**, lalu **Movies** di bawah nama server Anda. Aplikasi Plex lain juga menampilkannya di bawah nama server.

Sinkronisasi pertama Internet Archive butuh waktu. Kira-kira setengah jam di perangkat uji kami, sambil rex memeriksa setiap film. **Status** menampilkan **Syncing** sampai selesai, lalu jumlahnya, misalnya **Ready · 97 titles**. Tekan putar pada film mana pun.

![Aplikasi Plex di TV memutar film pendek Chaplin 1914 dari rex di TV yang sama](../assets/rex/android-tv-playing.webp)

## Add-on {#addons}

**Addons** mencantumkan apa saja yang sudah kamu pasang. Setiap addon menampilkan judulnya dan kapan terakhir kali disinkronkan. Tombolnya adalah **Sync now**, **Settings**, **Log** dan **Remove**; di ponsel, geser baris tombol ke samping untuk melihat semuanya. Sakelar **Enabled** mematikan addon tanpa menghapusnya.

Addon berasal dari **repositories**: repositori git yang berisi addon. Aplikasi ini sudah menambahkan [rex-addons](https://github.com/debridmediamanager/rex-addons) sejak awal, yang menawarkan film domain publik dari Internet Archive, dan sudah terpasang dari awal. Untuk lebih banyak, tambahkan [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) (lihat **Add a repository** di bawah), yang menawarkan:

| Addon | Yang dibawa |
|---|---|
| Stremio addons | Katalog film dan serial dari addon Stremio kamu, diputar dari stream yang diberikan addon stream kamu |
| YouTube | Playlist YouTube kamu. Kamu masuk dengan kode |
| Spotify | Perpustakaan Spotify kamu sebagai musik untuk Plex dan Plexamp. Perlu addon YouTube, sudah masuk |

**Pasang satu.** Di bawah **Repositories**, tekan **Addons** di samping repositori, lalu **Install** di bawah addon. rex menampilkan situs web mana saja yang bisa dijangkaunya dan bertanya sekali lagi, lalu mulai menyinkronkannya.

**Masuk.** Addon yang memerlukan akun kamu akan menampilkan **Sign in to start.** Tekan tombol **Sign in**-nya: buka halaman yang disebutkan di perangkat mana pun dan masukkan kode yang ditampilkan.

**Tambahkan repositori.** Di bawah **Add a repository**, ketik tautannya (`github.com/user/repo` sudah cukup) dan tekan **Add**. Pasang hanya dari orang yang kamu percaya. Untuk menulis addon sendiri, lihat [rex-addons](https://github.com/debridmediamanager/rex-addons).

## Tonton di perangkat lain di rumah {#watch-on-other-devices-at-home}

Setiap aplikasi Plex yang masuk dengan akun yang sama akan menemukan rex di jaringan rumah Anda lewat namanya: TV Anda, ponsel lain, Plex Web di komputer. **Status** menampilkan alamat rex di rumah, seperti `http://192.168.1.20:32400`.

Untuk membiarkan keluarga menonton dengan akun Plex mereka sendiri, lihat [Bagikan rex ke keluarga dan teman](sharing.md).

## Biarkan tetap berjalan {#keep-it-running}

- rex berjalan selama perangkat menyala. **Stop** pada notifikasi akan menghentikannya; **Status** memiliki **Start**, **Stop** dan **Restart**.
- Di **Settings**, aktifkan **Start when this device turns on**. Jika tidak, buka rex dan tekan **Start** setelah perangkat dinyalakan ulang.
- Beberapa ponsel tetap menghentikan aplikasi latar belakang. [Don't kill my app](https://dontkillmyapp.com/) menjelaskan apa yang dibutuhkan aplikasimu.
- Untuk mengganti nama server, buka **Settings**, **General** di aplikasi Plex dan ubah **Friendly name**.

## Batasan {#limits}

- **Berfungsi di rumah.** Di luar rumah, aplikasi Plex memerlukan alamat HTTPS yang bisa menjangkau perangkat, dan itu butuh port forward di router ke perangkat tersebut. Lihat [Gunakan di luar rumah](any-source.md#use-it-outside-your-home-optional).
- **Perangkatnya adalah servernya.** Biarkan tetap menyala, terhubung ke Wi-Fi atau Ethernet, dan tetap tercolok listrik. Mengonversi video untuk pemutar yang tidak bisa memutar file tertentu memakai perangkat keras bawaan perangkat, dan bisa lambat di kotak murah.
- **Hanya yang dibawa addon.** Tidak ada perpustakaan file di perangkat itu sendiri.
- **Belum ada di Google Play.** Untuk memperbarui, pasang file baru dari [rilis](https://github.com/debridmediamanager/rex-android/releases/latest) di atas file lama, dan rex akan mulai lagi dengan sendirinya. Akun masuk dan addon Anda tetap ada.

## Pemecahan masalah {#troubleshooting}

| Yang kamu lihat | Yang harus dilakukan |
|---|---|
| **App not installed as app isn't compatible with your phone.** | Kamu memilih file yang salah untuk prosesornya. Coba file lainnya dari tabel di Langkah 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | Ketik `32500` sebagai port |
| **Use a number from 1024 to 65535** | Port harus berupa angka dalam rentang itu |
| Server tidak ada di aplikasi Plex | Masuk ke aplikasi Plex dengan akun yang sama seperti di Langkah 4, dan pastikan kedua perangkat berada di jaringan rumah yang sama |
| Pustaka kosong | Sinkronisasi pertama masih berjalan: tunggu sampai **Status** menampilkan jumlah judul |
| **Sign in needed** di bawah addon | Tekan tombol **Sign in** lalu masukkan kodenya |
| **Needs an update** di bawah addon | Versi aplikasi ini tidak bisa lagi menjalankan salinan addon tersebut. Segarkan repository-nya lalu tekan **Update**. Judul-judulnya tetap ada sementara itu |
| **That isn't a repository link. Try github.com/user/repo.** | Ketik link repository-nya, misalnya `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | Link-nya salah atau repository-nya privat. Cek di browser |
| rex berhenti saat layar mati | Atur ulang pengaturan background di Langkah 3, dan lihat [Jangan matikan aplikasiku](https://dontkillmyapp.com/) |

**Logs** menampilkan apa yang dikatakan rex dan addon belakangan ini, dengan kunci dan sandi disembunyikan. Jika tim support meminta log, tekan **Send logs to support**: kamu bisa melihat semuanya sebelum apa pun dikirim, lalu tekan **Send** dan posting kode yang kamu dapat.

Apa yang dikirim aplikasi dan ke mana tercantum di [kebijakan privasi](android-privacy.md).

Masih macet? Tanyakan di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP).
