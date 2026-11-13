# Apa fungsi masing-masing bagian {#what-each-piece-does}

Nama-nama ini tidak menjelaskan fungsinya, jadi berikut satu baris untuk masing-masing. Untuk mencari mana yang kamu butuhkan, gunakan [Choose your setup](choose-your-setup.md).

## Tiga proyeknya {#the-three-projects}

| Nama | Fungsinya |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Sebuah situs web untuk mencari rilis dan menambahkannya ke akun debrid kamu. Situs ini juga mencari di Usenet dan Easynews. Gratis |
| [zurg](../zurg/index.md) | Semua akun debrid dan Usenet dalam satu folder. Plex, Jellyfin, Emby, Infuse dan rex membaca folder itu seperti drive biasa. Untuk sponsor |
| [rex](../rex/index.md) | Sebuah media server yang tidak memiliki file apa pun. Sumbernya memberi tahu apa yang mereka punya dan setiap aplikasi Plex dapat memutarnya. Gratis untuk penggunaan pribadi |

## Menonton langsung dari DMM {#watching-straight-from-dmm}

Tidak perlu server untuk semua ini.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | Addon Stremio yang memutar rilis dari akun debrid atau Easynews kamu |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Jelajahi, cari, dan putar dari akun debrid atau Easynews kamu di dalam Kodi |
| DMM Watch | Tombol di DMM yang membuka file di pemutar kamu sendiri, seperti VLC atau Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | Putar dan unduh musik dari Real-Debrid langsung di browser kamu |

## Memberi makan rex {#feeding-rex}

| Name | Apa fungsinya |
|---|---|
| [rex-stremio](../rex/stremio.md) | Mengubah addon Stremio Anda menjadi library rex, sehingga bisa diputar di aplikasi Plex. Gratis |
| [rex addons](../rex/addons.md) | Program kecil yang memberi rex sesuatu untuk diputar: YouTube, Spotify, IPTV, video rumahan, atau apa pun yang Anda tulis sendiri |
| [rex for Android](../rex/android.md) | rex dan addon-nya di ponsel atau TV box Android, tanpa komputer. Gratis. Untuk library debrid dan Usenet Anda, sponsor menggunakan zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | Server Plex di ponsel Anda: zurg dan rex bersama dalam satu perangkat Android. Untuk sponsor |

## Di dalam Jellyfin dan Emby {#inside-jellyfin-and-emby}

| Nama | Fungsinya |
|---|---|
| [RD, AD, TB, PM, OC and DL zurg](https://debridmediamanager.com/jellyfin) | Satu plugin untuk setiap penyedia debrid. Library debrid Anda muncul di Jellyfin atau [Emby](https://debridmediamanager.com/emby) tanpa aplikasi zurg atau mount. Untuk sponsor |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Plugin Jellyfin yang men-streaming NZB lewat akun Usenet Anda sendiri. Untuk sponsor |

## Menambahkan judul untukmu {#adding-titles-for-you}

| Name | Apa fungsinya |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Tekan **Want** di DMM dan zurg kamu akan mengambilnya, termasuk episode baru. Untuk sponsor |
| [Seerr lewat DMM](../dmm/seerr.md) | Permintaan keluarga di Seerr masuk ke daftar Wanted kamu. Untuk sponsor |
| [Torznab dan Newznab](https://debridmediamanager.com/torznab) | DMM sebagai indexer untuk Sonarr, Radarr dan Prowlarr, dengan zurg sebagai download client. Untuk sponsor |
| [Addon Stremio zurg](../zurg/guides/stremio.md) | Mencari di Usenet saat kamu menekan play di Stremio dan memutarnya lewat zurg |
| [`__magic__`](../zurg/guides/magic.md) | Folder zurg yang kamu atur sendiri, atau biarkan Sonarr dan Radarr yang mengaturnya |

## Fitur DMM lainnya {#the-rest-of-dmm}

| Nama | Fungsinya |
|---|---|
| [Papan permintaan](https://debridmediamanager.com/requests) | Minta rilis yang belum ada di Real-Debrid. Pengguna DMM lain akan memindahkannya ke perpustakaanmu. Memenuhi permintaan memberi keuntungan sponsor DMM |
| [Daftar hash](https://debridmediamanager.com/hashlists) | Bagikan daftar rilis supaya orang lain bisa menambahkannya ke akun mereka |
| [Ekstensi browser](../dmm/safari.md) | Menambahkan tombol DMM ke situs film dan serial TV serta di sebelah tautan magnet |
| [Halaman sponsor](https://gatekeeper.debridmediamanager.com) | Tempat kamu menjadi sponsor dan menautkan pledge Patreon atau GitHub Sponsors-mu. [Apa yang kamu dapatkan dari sponsorship](sponsorship.md) |

## Istilah yang akan kamu temui di panduan {#words-youll-see-in-the-guides}

| Kata | Artinya |
|---|---|
| Penyedia debrid | Layanan berbayar yang mengunduh torrent untuk kamu dan memungkinkan kamu streaming: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | Penyedia sudah punya rilisnya, jadi langsung bisa diputar |
| Usenet | Tempat lain untuk mendapatkan rilis. Kamu butuh akun penyedia Usenet, atau TorBox Pro untuk melakukannya untuk kamu |
| NZB | File kecil yang menunjukkan lokasi rilis Usenet, seperti file torrent untuk torrent |
| Indexer | Situs pencarian untuk rilis. Sonarr dan Radarr menggunakannya untuk mencari sesuatu |
| WebDAV | Cara berbagi file lewat web. Infuse, Kodi, dan banyak pemutar TV bisa membukanya |
| Mount | Membuat folder zurg terlihat seperti drive lokal, sehingga Plex, Jellyfin, atau Emby bisa memindainya |
| Plex Media Server vs Plex apps | Server menyimpan library kamu. Aplikasi di TV dan HP kamu yang memutarnya. rex menggantikan server, bukan aplikasinya |
