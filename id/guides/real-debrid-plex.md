# Perpustakaan Real-Debrid di Plex dengan zurg {#a-real-debrid-library-in-plex-with-zurg}

zurg menampilkan semua isi akun Real-Debrid Anda sebagai folder di komputer, yang sudah diurutkan ke dalam `movies` dan `shows`. Tambahkan dua folder itu ke Plex Media Server, dan seluruh perpustakaan Real-Debrid Anda bisa diputar di setiap aplikasi Plex, di-stream langsung dari Real-Debrid tanpa perlu mengunduh apa pun terlebih dahulu. Anda cukup memasang zurg sekali; zurg sudah membawa rclone sendiri, jadi tidak ada lagi yang perlu diatur.

Tidak ingin menjalankan Plex Media Server atau drive yang di-mount? [rex dengan zurg](../rex/with-zurg.md) menunjukkan perpustakaan yang sama ke aplikasi Plex tanpa keduanya.

## Yang kamu butuhkan {#what-you-need}

- **Sponsorship.** Nightly build zurg hanya untuk sponsor. Sponsor di [gatekeeper](https://gatekeeper.debridmediamanager.com/) dan akun GitHub kamu akan mendapat akses ke unduhan. [Apa yang didapat dari sponsorship](sponsorship.md) berisi penjelasan lengkapnya.
- **Akun premium Real-Debrid** dan API token-nya: [API token Real-Debrid kamu](real-debrid-api-token.md) menjelaskan cara menemukannya.
- **Plex Media Server di komputer yang sama dengan zurg.** Plex membaca file dari folder zurg, jadi Plex harus bisa melihatnya. Aplikasi Plex apa pun kemudian bisa dipakai untuk menonton.
- **Komputer yang tetap menyala**: Windows 10 atau 11, Linux, Mac, atau mesin Linux dengan Docker.

## 1. Pasang zurg {#1-install-zurg}

Setiap halaman setup dimulai dengan installer satu baris. Saat muncul tulisan `Choose one or more providers in priority order:`, ketik `1` untuk Real-Debrid, lalu tempelkan token Anda.

| Komputer Anda | Install dengan | Library Anda muncul di |
|---|---|---|
| Windows | [zurg on Windows](../zurg/setup/windows.md) | `Z:\movies` dan `Z:\shows` |
| Linux | [zurg on Linux](../zurg/setup/linux.md) | `/mnt/zurg/movies` dan `/mnt/zurg/shows` |
| Mac | [zurg on macOS](../zurg/setup/macos.md) | `/Volumes/Zurg/movies` dan `/Volumes/Zurg/shows` |
| Linux dengan Docker | [Satu file Docker Compose](../zurg/guides/docker-compose.md), yang menjalankan Plex Media Server di samping zurg | `/zurg_mnt/zurg/movies` dan `/zurg_mnt/zurg/shows` |

Installer diakhiri dengan `zurg doctor`, berupa daftar baris `PASS`.

## 2. Periksa folder-folder {#2-check-the-folders}

Buka drive atau folder zurg. Kamu akan melihat `movies`, `shows`, `__all__`, `__downloads__`, `__unplayable__` dan `version.txt`.

Saat pertama kali dijalankan, zurg membaca seluruh akun Real-Debrid kamu. Sampai proses itu selesai, folder-folder-nya tetap kosong. Untuk mengeceknya, buka `http://localhost:9999/ready` di browser: halaman itu akan menampilkan `ready` begitu library kamu sudah masuk.

## 3. Tambahkan folder-folder di Plex {#3-add-the-folders-in-plex}

Di Plex Web, tekan **Add Library**, tombol di sebelah nama server Anda di sidebar:

1. Pilih **Movies** lalu tekan **Next**.
2. Tekan **Browse for media folder** lalu pilih folder `movies` milik zurg dari tabel di atas, misalnya `Z:\movies` di Windows.
3. Tekan **Add Library**.

Lakukan hal yang sama untuk **TV Shows** dan folder `shows`. Plex kemudian memindai keduanya dan mengisi poster serta judulnya.

## 4. Biarkan zurg memberi tahu Plex tentang hal-hal baru {#4-let-zurg-tell-plex-about-new-things}

Plex tidak otomatis tahu saat ada file baru masuk ke akun Real-Debrid Anda. zurg bisa memberitahunya. Buka dasbor zurg di `http://localhost:9999/config/`, masuk ke **Media Server Integration**, lalu tekan **Login with Plex**. Login ke Plex dan pilih server Anda.

![Bagian Media Server Integration di dasbor zurg, dengan tombol Login with Plex](../assets/real-debrid-plex/01-zurg-login-with-plex.webp)

Setelah itu zurg akan meminta Plex untuk memindai setiap folder yang berubah. zurg juga mematikan beberapa pengaturan Plex yang berisiko untuk perpustakaan streaming, seperti **Empty trash automatically after every scan**: [Pengaturan Plex yang Direkomendasikan](../zurg/guides/plex.md#recommended-plex-settings) berisi daftar lengkapnya.

## Ketika ada yang salah {#when-something-is-wrong}

| Yang kamu lihat | Yang harus dilakukan |
|---|---|
| Plex tidak menemukan apa pun, atau folder zurg kosong | zurg masih membaca akunmu. Tunggu sampai `http://localhost:9999/ready` menampilkan `ready`, lalu pindai lagi di Plex. |
| Di Windows tidak ada drive `Z:`, atau Plex tidak bisa menemukan `Z:\movies` | `Z:` hanya ada di sesi desktop Windows kamu, dan installer zurg menjalankan zurg di sana saat kamu login. PowerShell yang dibuka sebagai administrator juga tidak bisa melihatnya. [Saat ada yang salah di Windows](../zurg/setup/windows.md#when-something-is-wrong) membahas tiap kasus. |
| Di Linux, Plex melihat folder kosong atau tidak bisa membukanya, dan `./zurg doctor` menampilkan `user_allow_other is not enabled in /etc/fuse.conf; the mount will be visible only to the zurg service user` | Plex berjalan dengan user yang berbeda dari zurg. Izinkan user lain dengan <code>echo user_allow_other &#124; sudo tee -a /etc/fuse.conf</code>, lalu jalankan `./zurg service restart` di folder zurg. |
| Di Docker, library Plex jadi kosong setelah zurg restart, dan `docker exec plex ls /zurg_mnt/zurg` menampilkan `Transport endpoint is not connected` | Berikan folder zurg ke container Plex dengan `rslave`: `/zurg_mnt:/zurg_mnt:rslave`. [Satu file Docker Compose](../zurg/guides/docker-compose.md) sudah memuatnya. |
| Hal baru muncul di folder zurg tapi tidak di Plex | Lakukan langkah 4. Sampai itu selesai, tekan **Scan Library Files** pada library di Plex. |
| zurg menampilkan `bad_token` | Token Real-Debrid salah atau terpotong. [Token API Real-Debrid kamu](real-debrid-api-token.md#when-something-is-wrong) punya perbaikannya. |
| Disk kamu penuh | zurg menyimpan salinan dari apa yang kamu putar, sampai 256G secara default. Batasi dengan cara di [Menjaga cache tetap kecil](../zurg/setup/windows.md#keeping-the-cache-small) (Windows) atau [Disk yang dipakai mount](../zurg/setup/linux.md#disk-the-mount-uses) (Linux). |

Masih buntu? Tanya di forum **zurg-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Meminta bantuan](remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Pertanyaan {#questions}

### Apakah ada panduan untuk mengatur DMM, zurg, dan rclone agar bisa streaming di Plex? {#is-there-a-guide-to-set-up-dmm-zurg-and-rclone-to-stream-in-plex}

Halaman ini. Anda tidak perlu mengatur rclone sendiri: installer zurg akan mengunduhnya dan zurg yang menjalankannya. DMM adalah tempat Anda mencari rilis dan menambahkannya ke akun Real-Debrid Anda ([What DMM is and how to use it](../dmm/index.md)). zurg lalu menampilkannya di folder-folder miliknya dan Plex akan mengambilnya.

### Apakah film diunduh ke komputer saya? {#do-the-movies-download-to-my-computer}

Tidak. Plex membaca setiap file dari Real-Debrid melalui zurg saat kamu menekan play. zurg memang menyimpan cache dari apa yang sudah diputar, dan ukurannya bisa jadi besar: lihat baris disk di atas.

### Bisakah saya melewati Plex Media Server? {#can-i-skip-plex-media-server}

Ya, bisa dengan rex. [rex dengan zurg](../rex/with-zurg.md) menampilkan library zurg kamu di aplikasi Plex, tanpa Plex Media Server dan tanpa mount. Kamu juga bisa menjalankan keduanya: [Satu file Docker Compose](../zurg/guides/docker-compose.md) menjalankan zurg, Plex Media Server, dan rex di satu mesin.

### Apakah ini juga bisa dipakai dengan TorBox atau Usenet? {#does-it-work-with-torbox-or-usenet-too}

Ya. Installer zurg juga menyediakan TorBox, AllDebrid, Premiumize, Debrid-Link, Offcloud, dan Usenet, dan semuanya ditaruh di folder `movies` dan `shows` yang sama. [Penyedia](../zurg/providers/index.md) punya halaman untuk masing-masing.
