# Apa fungsi masing-masing bagian {#what-each-piece-does}

The nama-nama ini tidak menjelaskan fungsinya, jadi di sini ada satu baris untuk masing-masing. Yang tidak ditandai **For sponsors** itu gratis. Untuk mengetahui mana yang kamu butuhkan, gunakan [Choose your setup](choose-your-setup.md).

## Tiga proyeknya {#the-three-projects}

| Nama | Fungsinya |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Situs web untuk mencari rilis dan menambahkannya ke akun debrid kamu. Situs ini juga mencari di Usenet dan Easynews |
| [zurg](../zurg/index.md) | Menggabungkan setiap akun debrid dan Usenet menjadi satu perpustakaan. Plex, Jellyfin dan Emby membacanya sebagai folder, Infuse dan Kodi lewat WebDAV, dan rex mengambilnya langsung. Build terbaru hanya untuk sponsor |
| [rex](../rex/index.md) | Media server untuk aplikasi Plex yang tidak punya file sendiri. zurg atau addon memberi tahu rex apa saja yang ada. Gratis untuk penggunaan pribadi |

## Menonton langsung dari DMM {#watching-straight-from-dmm}

Tidak perlu server untuk semua ini.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | Addon Stremio yang memutar rilis dari akun debrid atau Easynews kamu. Bisa juga dipakai di Nuvio |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Jelajahi, cari, dan putar dari akun debrid atau Easynews kamu langsung di dalam Kodi |
| DMM Watch | Tombol di DMM yang membuka file di pemutar kamu sendiri, seperti VLC atau Infuse |

## Memberi makan rex {#feeding-rex}

| Nama | Fungsinya |
|---|---|
| [rex-stremio](../rex/stremio.md) | Mengubah addon Stremio kamu menjadi library rex, sehingga bisa diputar di aplikasi Plex |
| [rex addons](../rex/addons.md) | Program kecil yang memberi rex sesuatu untuk diputar: YouTube, Spotify, IPTV, video rumahan, atau apa pun yang kamu tulis sendiri |
| [rex-live-sports](../rex/live-tv.md) | Addon rex yang menampilkan saluran olahraga langsung dan panduan di Live TV aplikasi Plex |
| [rex-direct](../rex/any-source.md#rex-direct) | Memberi rex kamu alamat aman sendiri, sehingga aplikasi Plex bisa mengaksesnya dari luar rumah |
| [rex for Android](../rex/android.md) | rex dan addon-nya di ponsel atau TV box Android, tanpa komputer |
| [zurg+rex for Android](../zurg/guides/android.md) | Server Plex di ponselmu: zurg dan rex bersama-sama di satu perangkat Android, dengan library debrid dan Usenet kamu. Untuk sponsor |

## Di dalam Jellyfin dan Emby {#inside-jellyfin-and-emby}

| Nama | Fungsinya |
|---|---|
| [Plugin debrid](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | Satu plugin untuk tiap penyedia debrid: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, dan Debrid-Link. Pustaka debrid kamu muncul di Jellyfin atau [Emby](https://debridmediamanager.com/emby) tanpa perlu aplikasi zurg atau mount. Untuk sponsor |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Plugin Jellyfin yang memutar NZB lewat akun Usenet kamu sendiri. Untuk sponsor |

## Menambahkan judul untukmu {#adding-titles-for-you}

| Nama | Fungsinya |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Tekan **Want** di DMM dan zurg kamu akan mengambilnya, termasuk episode baru. Untuk sponsor |
| [Seerr through DMM](../dmm/seerr.md) | Permintaan keluarga di Seerr masuk ke daftar Wanted kamu. Untuk sponsor |
| [Torznab](https://debridmediamanager.com/torznab) dan [Newznab](https://debridmediamanager.com/newznab) | DMM sebagai indexer untuk Sonarr, Radarr, dan Prowlarr. Untuk sponsor |
| zurg sebagai download client | zurg menjawab Sonarr dan Radarr seperti qBittorrent untuk [torrents](../zurg/guides/sonarr-radarr-torrents.md) dan SABnzbd untuk [Usenet](../zurg/guides/sonarr-radarr.md), jadi kamu tidak perlu menjalankan keduanya. Untuk sponsor |
| [Addon Stremio dari zurg](../zurg/guides/stremio.md) | Mencari di Usenet saat kamu menekan play di Stremio dan memutarnya lewat zurg. Untuk sponsor |
| [`__magic__`](../zurg/guides/magic.md) | Folder zurg yang kamu atur sendiri, atau biarkan Sonarr dan Radarr yang mengaturnya. Untuk sponsor |

## Fitur DMM lainnya {#the-rest-of-dmm}

| Nama | Fungsinya |
|---|---|
| Tab Usenet | Mengirim rilis Usenet ke library Real-Debrid kamu, tanpa perlu akun Usenet. Sponsor didahulukan dan mendapat jatah harian yang lebih besar |
| [Request board](https://debridmediamanager.com/requests) | Minta rilis yang tidak ada di Real-Debrid. Pengguna DMM lain akan memindahkannya ke library kamu. Isi 10 request dan dapatkan 7 hari fitur sponsor DMM |
| [Hash lists](https://debridmediamanager.com/hashlists) | Bagikan daftar rilis supaya orang lain bisa menambahkannya ke akun mereka sendiri |
| Browser extension | Menambahkan tombol DMM ke situs film dan TV serta di samping magnet link. Untuk [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) dan [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | Situs sponsor. Jadi sponsor di sana, hubungkan pledge Patreon atau GitHub Sponsors kamu dan dapatkan API key DMM kamu. [Manfaat yang didapat dari sponsorship](sponsorship.md) |

## Istilah yang akan kamu temui di panduan {#words-youll-see-in-the-guides}

| Kata | Artinya |
|---|---|
| Release | Satu salinan film, episode, atau season seperti yang dipublikasikan seseorang. Satu judul biasanya punya banyak release, dengan kualitas yang berbeda |
| Debrid provider | Layanan berbayar yang mengunduh torrent untukmu dan memungkinkanmu men-stream-nya: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | Provider sudah punya release-nya, jadi langsung bisa diputar |
| Usenet | Tempat lain untuk mendapatkan release. Pakai akun Usenet sendiri, biarkan TorBox Pro atau Easynews yang mengurusnya, atau minta DMM mengirim hasil ke Real-Debrid |
| Easynews | Layanan Usenet berbayar dengan pencarian sendiri yang memutar file langsung lewat web |
| NZB | File kecil yang menunjukkan lokasi release Usenet, seperti file torrent untuk torrent |
| Indexer | Situs pencarian untuk release. Sonarr dan Radarr memakainya untuk mencari sesuatu |
| Sonarr, Radarr and Prowlarr | Aplikasi yang mengambilkan judul untukmu: Sonarr untuk serial, Radarr untuk film. Prowlarr menyimpan indexer mereka di satu tempat |
| Seerr | Situs permintaan untuk keluarga dan teman. Overseerr dan Jellyseerr bekerja dengan cara yang sama |
| Stremio, Nuvio and Kodi | Aplikasi pemutar media. Addon memberi mereka hal-hal untuk diputar. Nuvio mendukung addon Stremio |
| DMM API key | Kunci sponsor dari gatekeeper. Tempel di tempat yang diminta panduan, dan jaga kerahasiaannya seperti password |
| Nightly | Build terbaru dari zurg atau rex, dibuat setiap malam. Nightly zurg hanya untuk sponsor |
| WebDAV | Cara berbagi file lewat web. Infuse, Kodi, dan banyak pemutar TV bisa membukanya |
| Mount | Membuat folder zurg terlihat seperti drive lokal, sehingga Plex, Jellyfin, atau Emby bisa memindainya |
| rclone | Alat yang dipakai zurg untuk membuat mount. Setup zurg mengurusnya untukmu |
| `.strm` | File kecil yang menyimpan tautan sebagai pengganti video, untuk pemutar seperti Kodi |
| Source | Apa pun yang memberi tahu rex apa yang dimilikinya dan menyajikan file-filenya: zurg, rex-stremio, atau sebuah addon |
| Claim | Memasang rex ke akun Plex, supaya bisa menampilkan judul dan poster, dan aplikasi Plex bisa menemukannya |
| Plex Media Server vs Plex apps | Server menyimpan library-mu. Aplikasi di TV dan ponselmu yang memutarnya. rex menggantikan server, bukan aplikasinya |
