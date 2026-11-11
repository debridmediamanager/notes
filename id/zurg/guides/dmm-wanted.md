# Ambil apa yang kamu mau dari DMM {#fetch-what-you-want-from-dmm}

Tekan **Want** pada film atau acara di [Debrid Media Manager](https://debridmediamanager.com), dan zurg-mu akan mengambilnya. Tidak perlu mengatur Sonarr atau Radarr, dan tidak ada yang perlu di-mount.
Acara akan terus mendapatkan episode barunya saat tayang.

Ini untuk sponsor: zurg membaca daftar kamu menggunakan API key DMM kamu.

## Yang kamu butuhkan {#what-you-need}

- Sebuah nightly zurg dari 2026-10-25 atau yang lebih baru.
- Kunci API DMM kamu di `config.yml` zurg. Ini adalah kunci yang ditampilkan [gatekeeper](https://gatekeeper.debridmediamanager.com/) setelah kamu sponsori:

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- Sesuatu untuk tempat zurg mengambil file: akun debrid yang menerima torrent, provider `nzb` atau `torbox_nzb` untuk Usenet, atau keduanya.

Hanya itu persiapannya. zurg membaca daftar kamu sekali per menit sejak zurg mulai berjalan.

## Menambahkan judul {#adding-titles}

1. Tempel kunci yang sama di halaman [Settings](https://debridmediamanager.com/settings) DMM.
2. Buka sebuah film lalu tekan **Want**. Di halaman season sebuah serial, **Want S2** menambahkan season itu,
   dan **Want all seasons** menambahkan seluruh serial, termasuk season baru.
3. Daftar kamu ada di [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted).
   Di situ tertulis kapan zurg terakhir membacanya, dan kapan setiap film diambil. Daftar yang panjang
   ditampilkan 120 judul per halaman.

Permintaan dari Seerr, Overseerr, atau Jellyseerr juga bisa masuk ke daftar yang sama: lihat
[Seerr through DMM](../../dmm/seerr.md).

## Mengikuti daftar {#following-a-list}

Tempel halaman daftar Trakt atau MDBList ke [daftar wanted](https://debridmediamanager.com/wanted) kamu
lalu tekan **Follow**. Setiap film dan serial di dalamnya ditandai sebagai wanted, dan DMM membaca ulang
daftar itu setiap enam jam, jadi yang ditambahkan ke daftar itu nanti juga ikut wanted. Halaman yang didukung:

- `https://trakt.tv/users/<user>/lists/<list>` dan `https://trakt.tv/lists/<id>`
- `https://trakt.tv/users/<user>/watchlist`, kalau profil Trakt itu publik
- `https://mdblist.com/lists/<user>/<list>`

Di halaman Trakt milik DMM sendiri, watchlist kamu dan setiap daftar milikmu punya tombol **Follow with Want**
yang melakukan hal yang sama.

Untuk watchlist IMDb, Letterboxd, Rotten Tomatoes, atau Plex: di mdblist.com, buat
[daftar eksternal](https://docs.mdblist.com/docs/external_lists) dari URL-nya lalu follow
daftar itu. MDBList akan menjaganya tetap sinkron dengan sumbernya.

Yang dilakukan follow:

- Serial dianggap wanted secara utuh, termasuk season baru.
- Hanya judul yang baru masuk ke daftar sejak terakhir dibaca yang ditambahkan. Judul yang kamu hapus dari
  daftar wanted tetap terhapus, dan judul yang keluar dari daftar tetap wanted.
  **Unfollow** tetap menyimpan apa yang sudah ditambahkan daftar itu.
- Halaman menampilkan setiap daftar beserta jumlah judulnya, berapa yang sudah ditambahkan sejauh ini, dan
  kapan terakhir dibaca. **Read again** membacanya sekarang juga. Judul tanpa IMDb id dilewati, dan
  jumlahnya ditampilkan.
- Daftar wanted kamu menampung 10.000 judul yang masih perlu diambil: setiap serial, dan setiap film yang belum
  diambil zurg atau sedang menunggu upgrade. Film yang sudah diambil zurg tidak dihitung. Judul yang tidak muat
  akan ditambahkan di pembacaan berikutnya, begitu ada ruang.

## Pindah dari Radarr atau Sonarr {#moving-from-radarr-or-sonarr}

Pindahkan semua yang masih dicari:

1. Di Radarr atau Sonarr, buka **System → Backup**, tekan **Backup Now** lalu unduh
   zip-nya. Backup terjadwal di folder `Backups` juga bisa dipakai.
2. Di [daftar wanted](https://debridmediamanager.com/wanted) kamu, tekan **Import a Radarr or
   Sonarr backup** lalu pilih zip-nya. Setelah itu, lakukan hal yang sama dengan backup aplikasi satunya.

Yang ikut terbawa:

- Dari Radarr, setiap film yang dipantau dan belum punya file, yang sudah mencapai
  minimum availability-nya. Film tanpa IMDb id tidak ikut; halaman itu menunjukkan jumlahnya.
- Dari Sonarr, setiap acara TV yang dipantau dan masih punya episode tayang yang belum ada,
  hanya season tersebut saja.
- Judul yang sudah ada di daftarmu tetap seperti semula.

Hanya database di dalam zip yang diunggah. Sisa backup, termasuk API key aplikasi, tetap di komputermu.

Dua hal tidak ikut terbawa:

- **Quality profiles.** zurg memilih rilis berdasarkan [pengaturan acquisition](acquisition.md#configuration) sendiri. Radarr biasanya menolak salinan camera dan telesync. Untuk menyingkirkannya, tambahkan ke [`exclude_words`](acquisition.md#excluding-releases-by-name):

  ```yaml
  acquisition:
    exclude_words: [CAM, CAMRip, HDCAM, TS, HDTS, TELESYNC, TC, HDTC, TELECINE]
  ```

- **Nomor season Sonarr, jika berbeda.** Daftarmu memberi nomor season seperti TMDB. Sonarr mengikuti TheTVDB, yang memecah beberapa anime panjang menjadi lebih banyak season, jadi season Sonarr yang tidak ada di TMDB tidak akan diambil. Cek acara-acara itu di halaman DMM-nya dan tekan **Want** pada season yang kurang.

## Apa yang diambil zurg {#what-zurg-fetches}

- **Sebuah film** sekali. Setelah itu film tersebut keluar dari daftar yang dibaca zurg. Film yang diambil di bawah resolusi `quality` yang dituju (2160p untuk `best`) tetap berada di daftar. zurg akan mengambil salinan yang lebih baik ketika sudah rilis dan menghapus salinan yang diambil sebelumnya. Salinan yang kamu tambahkan sendiri akan tetap disimpan. `upgrades: false` di bawah `acquisition:` pada konfigurasi zurg mematikan fitur ini. `/wanted` menampilkan apa yang sudah diambil zurg dan resolusi yang masih ditunggunya, kecuali jika kamu memakai daftar resolusi di bawah.
- **Sebuah film di 1080p dan 4K**, kalau kamu ingin keduanya, misalnya supaya TV 1080p bisa memutar versi 1080p tanpa file 4K perlu ditranscode. Butuh nightly 2026-10-31 atau yang lebih baru. Daftarkan resolusinya di konfigurasi zurg:

  ```yaml
  acquisition:
    quality: [1080p, 4k]
  ```

  zurg lalu menyimpan salinan setiap film di tiap resolusi tersebut. Setiap salinan mengambil rilis terbaik pada atau di bawah resolusinya sendiri dan ditingkatkan secara terpisah, jadi salinan 1080p tidak pernah berubah menjadi 2160p. Selama belum ada rilis yang lebih baik dari 1080p, keduanya biasanya mengambil rilis yang sama dan kamu hanya mendapat satu file. `720p` juga bisa ditambahkan. Serial tetap mendapat satu salinan, dipilih seolah kamu hanya menulis resolusi tertinggi. Film yang sudah diambil zurg sebelum kamu menambahkan daftar ini akan diambil ulang di tiap resolusi. zurg tidak menghapus salinan lama, jadi hapus sendiri jika tidak diinginkan lagi. Aturan lengkapnya ada di [salinan di beberapa resolusi](acquisition.md#a-copy-at-each-of-several-resolutions).
- **Sebuah serial**: setiap episode yang sudah tayang dari musim yang kamu pilih, sebagai season pack jika satu pack mencakup satu musim penuh dan sebagai episode tunggal jika musim itu masih tayang. Pengecekan episode baru terus berjalan sampai kamu menghapus serial itu. Specials tidak diambil.

Rilis datang dari Usenet sebagai NZB dan dari torrent yang sudah ter-cache di akun debrid kamu. Torrent yang belum di-cache tidak pernah ditambahkan. Jika kamu belum mengatur indexer apa pun, zurg mencari di indexer milik DMM. Kualitas, batas ukuran, kata yang dihindari, serta bahasa audio dan subtitle yang harus dimiliki sebuah rilis diatur di [pengaturan acquisition](acquisition.md#configuration). Pengaturan ini sama untuk semua sumber.

## Menontonnya di Kodi atau Plex {#watching-it-in-kodi-or-plex}

Dengan `__magic__` aktif, zurg menyimpan file yang diambilnya berdasarkan judul, ke dalam `__magic__/__movies__` dan `__magic__/__shows__`, dengan penamaan yang cocok dengan Kodi dan Plex. Arahkan library Movies dan library TV ke dua folder tersebut, atau dengan `magic.anime` tambahkan library Anime ke `__magic__/__anime__`: lihat [`__movies__` and `__shows__`](magic.md#__movies__-and-__shows__-sorted-by-title).

```yaml
magic:
  enabled: true
```

## Dua zurg dengan satu kunci {#two-zurgs-on-one-key}

Setiap zurg membaca daftar yang sama, jadi kalau ada dua zurg, setiap judul akan diambil dua kali. Simpan daftar di salah satu saja dan matikan di yang lain:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## Saat berhenti {#when-it-stops}

Jika sponsor Anda berakhir atau Anda mereset kunci Anda, zurg mencatat bahwa DMM menolak kunci tersebut dan meminta lagi setiap jam. Apa yang sudah diambil tetap ada di perpustakaan Anda.

Detail lebih lanjut: [DMM wanted list](acquisition.md#dmm-wanted-list) di referensi acquisition.
