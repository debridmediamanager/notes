# Apa yang didapat dari sponsor {#what-a-sponsorship-gives-you}

DMM itu gratis. Sponsor yang membayar hosting-nya dan menjaga zurg serta rex tetap jalan. Halaman ini mencantumkan semua perk dan tempat mengaturnya.

Jadi sponsor di [gatekeeper](https://gatekeeper.debridmediamanager.com/). Login di sana untuk melihat API key DMM kamu. **Open DMM with this key** akan menghubungkannya di browser itu. Masukkan key yang sama di layanan lain yang memintanya. Jaga kerahasiaannya karena fungsinya seperti password.

Perk mengikuti sponsorship. Saat sponsorship berakhir, DMM menghentikan perk-nya pada request berikutnya. Plugin Jellyfin dan Emby yang sudah kamu pasang tetap berfungsi, tetapi download baru dan update akan berhenti. Gatekeeper mencabut akses zurg dan role Discord pada pengecekan berikutnya. **Reset key** langsung menghentikan key lama di semua tempat sekaligus.

## zurg

| Yang Anda dapatkan | Di mana |
|---|---|
| Build nightly dengan semua provider dan Usenet beserta image Docker | [zurg setup](../zurg/setup/index.md) setelah Anda menerima undangan GitHub |
| Aplikasi Android zurg+rex, server Plex di ponsel Anda | [Panduan Android](../zurg/guides/android.md) setelah Anda menerima undangan GitHub |
| Seluruh source code zurg | Repositori privat di GitHub |
| Setiap rilis yang diberi nama sesuai rex dan Plex | `dmm_api_key` di [config zurg](../zurg/reference/config.md) |
| Detail media DMM tanpa membaca file dulu, dan pengecekan bahasa sebelum rilis ditambahkan | Tidak ada selain `dmm_api_key` |
| Folder `__magic__` yang diurutkan otomatis saat diaktifkan | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Daftar wanted DMM Anda yang diambil oleh zurg | [Daftar wanted DMM](../zurg/guides/dmm-wanted.md) |
| Indexer Usenet dan torrent milik DMM yang dicari saat Anda tidak punya indexer sendiri | `dmm_api_key` plus penyedia Usenet atau akun debrid yang bisa menambahkan torrent |
| Rilis dipilih berdasarkan bahasa asli setiap judul | `original` di [bahasa audio dan subtitle](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| Film yang diinginkan tapi tidak ada di indexer mana pun, di-stream dari unggahan YouTube resminya | [Streaming film dari YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

Fitur `dmm_api_key` membutuhkan build nightly zurg. Build publik gratis tidak menyertakannya.

## DMM

| Yang kamu dapat | Di mana |
|---|---|
| Daftar wanted yang diambil zurg beserta episode baru dan upgrade. Isi dari DMM atau Kodi, atau dari daftar Trakt dan MDBList, atau dari backup Radarr atau Sonarr | [Daftar wanted DMM](../zurg/guides/dmm-wanted.md) |
| Permintaan dari Seerr, Overseerr, atau Jellyseerr masuk ke daftar wanted kamu | [Seerr lewat DMM](../dmm/seerr.md) |
| Hasil Easynews apa pun dikirim ke zurg kamu dengan satu klik | Hasil Easynews di halaman film atau acara di DMM |
| DMM sebagai indexer Newznab untuk Usenet | [Halaman Newznab](https://debridmediamanager.com/newznab) DMM |
| DMM sebagai indexer Torznab dengan feed khusus cache untuk Real-Debrid, AllDebrid, Debrid-Link, TorBox, Premiumize, dan Offcloud | [Halaman Torznab](https://debridmediamanager.com/torznab) DMM. TorBox, Premiumize, dan Offcloud juga butuh service key yang sudah ditautkan |
| Tujuh plugin Jellyfin untuk library debrid dan Usenet, dan enam plugin Emby untuk library debrid, tanpa mount apa pun | Halaman [Jellyfin](https://debridmediamanager.com/jellyfin) dan [Emby](https://debridmediamanager.com/emby) DMM |
| Sepuluh stream lain per judul di Stremio Cast dan Kodi, bukan lima | Settings DMM untuk Real-Debrid, TorBox, dan AllDebrid; halaman Cast masing-masing provider untuk yang lain |
| Upload NZB didahulukan dengan 2 TB Usenet per hari, bukan 300 GB | Tab Usenet DMM |
| Prioritas dan kuota yang sama untuk Sonarr dan Radarr | API key DMM kamu sebagai Password di [halaman SABnzbd](https://debridmediamanager.com/sabnzbd) DMM |
| Tiga upload torrent ke Real-Debrid sekaligus, bukan satu | Tombol upload di hasil pencarian dan library DMM |
| Tambah ke DMM Wanted dan folder Wanted di dalam Kodi | Pasangkan Kodi di [halaman Kodi](https://debridmediamanager.com/kodi) DMM |
| API DMM untuk nama rilis, cek cache, detail media, dan metadata | [Dokumentasi API](https://debridmediamanager.com/api-docs) |

## rex

rex gratis dan tidak memerlukan sponsor. Build Android-nya hanya tersedia di dalam aplikasi zurg+rex khusus sponsor. Dengan kunci, [rex-stremio](../rex/stremio.md) menambahkan stream debrid dari torrent yang sudah dimiliki DMM dan sudah memiliki probe-nya, dalam hitungan detik, alih-alih memeriksa setiap torrent satu per satu. Tempel kunci tersebut di kolom **DMM** pada rex-stremio. Kolom ini berbagi hasil probe file torrent dengan DMM, kecuali kamu mematikannya.

## Bantuan {#help}

| Apa yang kamu dapatkan | Di mana |
|---|---|
| Bantuan jarak jauh gratis untuk zurg dan rex di terminal kamu sendiri sambil kamu menonton | [Mendapatkan bantuan](remote-help.md) |
| Peran Sponsor di Discord | Hubungkan Discord di gatekeeper |

## Dapatkan tanpa membayar {#earn-it-without-paying}

Isi permintaan di [papan permintaan](https://debridmediamanager.com/requests) DMM. Setiap 10 permintaan yang terisi dapat 7 hari keuntungan DMM di atas. Hanya satu isian per orang per hari yang dihitung. Tautkan kunci dari akun gatekeeper gratis di papan untuk mengklaimnya.

Waktu yang didapat hanya membuka tabel DMM di atas. Waktu itu tidak membuka zurg nightly, kode sumber, peran Discord, bantuan jarak jauh, atau aplikasi Android. Semua itu butuh sponsor berbayar. Fitur `dmm_api_key` juga butuh nightly.

Macet? Tanya di forum **dmm-support** di [Discord](https://discord.com/invite/7u4YjMThXP).
