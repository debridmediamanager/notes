# Apa itu DMM dan bagaimana cara memakainya? {#what-is-dmm-and-how-do-i-use-it}

[Debrid Media Manager](https://debridmediamanager.com) (DMM) adalah situs web gratis untuk mencari film dan serial lalu menambahkannya ke akun debrid Anda: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, atau Debrid-Link. Anda masuk dengan akun tersebut, cari judulnya, lalu tekan **Instant RD** (atau tombol layanan Anda) pada salah satu rilisnya. Judulnya langsung masuk ke library Anda dan siap ditonton dari DMM, di Stremio atau Kodi, atau di Plex lewat [zurg](../zurg/index.md).

DMM bersifat open source dan bukan bagian dari Real-Debrid atau layanan lain. File-filenya tetap tersimpan di layanan debrid Anda.

## Masuk {#sign-in}

1. Buka [debridmediamanager.com](https://debridmediamanager.com) lalu tekan layanan Anda: **Login with Real Debrid**, **Login with AllDebrid**, **Login with Torbox**, **Login with Premiumize**, **Login with Offcloud** atau **Login with Debrid-Link**.
2. Di Real-Debrid, tekan **Sign in with Real-Debrid**. DMM akan menampilkan sebuah kode: tekan **Open real-debrid.com/device**, masukkan kodenya di sana lalu setujui. Halaman DMM akan selesai dengan sendirinya. Anda juga bisa menempelkan [API token](../guides/real-debrid-api-token.md) Anda di bawah **or paste an API key** lalu tekan **Save API Key**.
3. Layanan lain: ikuti halaman login mereka. Jika diminta API key, salin dari akun Anda di layanan tersebut, tempelkan, lalu tekan **Save API Key**.

![DMM's sign-in page](../assets/dmm-index/01-sign-in.webp)

Punya layanan lain juga? Buka **Debrid services** di halaman utama DMM lalu tekan tombol **Login**-nya, misalnya **AllDebrid Login**.

Hanya punya Easynews? Tekan **Login with Easynews**. Anda bisa mencari di Easynews dan mengirimnya ke Stremio, tetapi library-nya memerlukan akun debrid. Sponsor juga bisa login dengan **Login with DMM key**.

## Cari film atau serial {#search-a-movie-or-show}

1. Ketik judul di **Search movies & shows...** pada halaman utama. Pilih salah satu dari saran yang muncul, atau tekan **Search** untuk melihat daftar lengkapnya.
2. Tekan poster. Halaman judul tersebut menampilkan rilis yang ditemukan DMM.
3. Tekan chip layanan Anda di atas hasil (**RD**, **PM** dan seterusnya) untuk hanya menampilkan rilis yang sudah ada di layanan tersebut.

![DMM's home page after signing in](../assets/dmm-index/02-home.webp)

## Arti tombol-tombol pada rilis {#what-the-buttons-on-a-release-mean}

![Rilis Sintel di DMM, sudah masuk dengan Premiumize](../assets/dmm-index/03-results.webp)

| Tombol | Fungsinya |
|---|---|
| **Instant RD** (**Instant TB**, **Instant AD**, **Instant PM**, **Instant OC**, **Instant DL**) | Layanan Anda sudah punya rilis ini. Tekan tombolnya dan rilis langsung masuk ke library Anda. |
| **DL with RD** (**DL with TB** dan seterusnya; **Add to DL** di Debrid-Link) | Layanan Anda belum punya rilis ini. Tetap tekan tombolnya, rilis akan ditambahkan dan layanan mengunduhnya dulu. Pilih tombol **Instant** kalau Anda ingin langsung menonton. [Kenapa ini terjadi](../guides/torrent-being-downloaded-to-debrid.md). |
| **RD (100%)** (**PM (100%)** dan seterusnya) | Rilis sudah ada di library Anda. Angkanya menunjukkan sampai mana unduhannya. Tekan tombolnya untuk menghapus rilis dari library Anda. |
| **Check RD** (**Check AD**, **Check DL**) | Menanyakan ke layanan itu apakah rilis ini sudah ada di cache mereka saat ini. |
| **Cast (RD)** (**Cast (PM)** dan seterusnya) | Mengirim rilis ke Stremio. Lihat [DMM di Stremio](stremio.md). |
| **Watch** | Membuka tab **Ready to play**. Tekan **Play** dan player Anda akan terbuka. Pilih player di **Settings** → **Video player**. |
| **Copy** | Menyalin magnet link dari rilis dan menampilkan **Magnet link copied.** Kalau **Download .magnet files instead of copy** dicentang di **Settings**, tombolnya akan bertuliskan **Download** dan menyimpan file .magnet. |
| **Report** | Menandai rilis yang bermasalah: **XXX / Porn Content**, **Incorrect IMDB ID**, **Malware / Executable File**, dan untuk serial **Tagged for Wrong Season**. |

Tab **Usenet** di sebelah **Torrents** menampilkan rilis Usenet untuk judul yang sama. **NZB** mengunduh satu rilis. Untuk memasukkannya ke library, Anda perlu Real-Debrid atau TorBox. Punya Easynews? Tambahkan di **Settings**, maka Easynews juga ikut dicari di sini.

## Pustaka Anda {#your-library}

Tekan **Library** di halaman utama. Di sana tercantum semua yang ada di akun yang kamu gunakan untuk masuk: nama, ukuran, status, dan kapan ditambahkan.

![Kotak pencarian dan tombol-tombol library](../assets/dmm-index/04-library.webp)

- Cari dengan **search by filename/hash/id, supports regex**, atau persempit dengan **Movies**, **TV shows**, dan **Others**.
- Tekan sebuah baris untuk melihat detailnya beserta tombol **Hashlist**, **Delete**, **Cast**, dan **Copy**. Ikon di ujung setiap baris berfungsi sama.
- **Backup** menyimpan daftarmu ke file `.dmm.json`. **RD Restore** (**PM Restore** dan sebagainya) menambahkan kembali daftar yang sudah disimpan.
- **Share List** mengubah apa yang ditampilkan, atau yang kamu pilih, menjadi [hash list](hashlists.md) yang bisa ditambahkan orang lain ke akun mereka sendiri.
- **Delete List** menghapus semua yang ditampilkan setelah konfirmasi **Yes, delete!**. Cari atau pilih dulu.

## Langkah selanjutnya {#where-to-go-next}

- [DMM di Stremio](stremio.md): tonton apa yang kamu temukan di Stremio dengan addon DMM Cast.
- [Daftar hash](hashlists.md): tambahkan seluruh library bersama ke milikmu, atau bagikan milikmu sendiri.
- [TorBox di DMM](torbox.md): paket TorBox mana yang melakukan apa di DMM, dan cara mengirim rilis Usenet ke TorBox Pro.
- ["Torrent is being downloaded to debrid"](../guides/torrent-being-downloaded-to-debrid.md): apa arti layar itu di Stremio dan bagaimana DMM menunjukkan mana yang sudah cached.
- [Tombol DMM di Safari](safari.md): ekstensi browser menambahkan tombol DMM ke IMDb, Trakt, dan situs film serta TV lainnya.

DMM juga melayani proyek-proyek lainnya:

- **zurg** bertanya ke DMM film atau episode mana yang sesuai dengan setiap file. Sponsor mendapatkan API key DMM dari [gatekeeper](https://gatekeeper.debridmediamanager.com/). Tanpa itu, zurg mengandalkan nama file dan lebih sedikit judul yang cocok. [rex dengan zurg](../rex/with-zurg.md#why-dmm-places-the-files) menjelaskan perbedaannya.
- **Sonarr Radarr and Prowlarr** bisa mencari di DMM sebagai indexer torrent Torznab atau indexer Usenet Newznab. Keduanya butuh sponsorship yang aktif dan API key DMM. Atur keduanya di halaman [Torznab](https://debridmediamanager.com/torznab) dan [Newznab](https://debridmediamanager.com/newznab).
- **Your wanted list**: tekan **Want** atau ikuti daftar Trakt, MDBList, atau TMDB. zurg akan mengambil daftar itu dan episode baru saat tayang. Butuh sponsorship. Lihat [Daftar keinginan DMM](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr and Jellyseerr** bisa memakai DMM sebagai Radarr dan Sonarr. Permintaan kemudian masuk ke daftar yang diinginkan agar zurg mengambilnya. Butuh sponsorship. Lihat [Seerr lewat DMM](seerr.md).
- **rex-direct** memberi rex yang sudah diklaim alamat dan sertifikatnya sendiri. Lihat [rex-direct](../rex/any-source.md#rex-direct).

Semua yang dibuka oleh sponsorship dan di mana setiap hal diatur ada di [Apa yang didapat dari sponsor](../guides/sponsorship.md).

## Ketika ada yang salah {#when-something-is-wrong}

| Yang Anda lihat | Yang harus dilakukan |
|---|---|
| **Real-Debrid menolak API key itu.** | Token yang Anda tempel bukan token yang valid. Salin lagi dari [real-debrid.com/apitoken](https://real-debrid.com/apitoken), atau tekan **Sign in with Real-Debrid** saja. Selengkapnya di [Your Real-Debrid API token](../guides/real-debrid-api-token.md). |
| **That code expired before it was approved. Try again.** | Kode Real-Debrid sudah habis waktu. Tekan **Sign in with Real-Debrid** lagi dan setujui kode baru lebih cepat. |
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | Paket gratis TorBox tidak bisa dipakai dengan DMM. Upgrade paketnya, atau masuk dengan layanan lain. |
| Hanya tombol **DL with RD**, tidak ada **Instant RD** | Layanan Anda tidak punya rilis ini di cache. Tekan salah satu dan tunggu sampai selesai diunduh, atau coba rilis lain. |

Masih bingung? Tanya di forum **dmm-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Mendapatkan bantuan](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Pertanyaan {#questions}

### Sebenarnya apa itu DMM? {#what-actually-is-dmm}

Situs pencarian untuk akun debrid Anda. Situs ini mencari rilis dari sebuah film atau serial, memberi tahu rilis mana yang sudah ada di layanan Anda, lalu menambahkan rilis yang Anda pilih ke akun Anda. DMM sendiri tidak menyimpan file apa pun.

### Bagaimana cara memakainya? {#how-do-i-use-it}

Masuk dengan layanan debrid Anda, cari judul, buka, lalu tekan **Instant RD** (atau tombol **Instant** dari layanan Anda) pada sebuah rilis. Setelah itu, tekan **Watch**, cast ke Stremio, atau biarkan zurg memasukkannya ke Plex.

### Apakah DMM dibuat oleh Real-Debrid? {#is-dmm-made-by-real-debrid}

Tidak. DMM adalah proyek open-source yang bekerja dengan Real-Debrid dan lima layanan lainnya. Orang sering mencarinya dengan nama "Real-Debrid Media Manager".

### Apakah gratis? {#is-it-free}

Ya. Kamu perlu akun debrid sendiri, yang merupakan layanan berbayar. Sponsor DMM menambahkan fitur tambahan seperti daftar wanted dan indexer: lihat [Apa yang kamu dapat dari sponsor](../guides/sponsorship.md).

### Layanan apa saja yang berfungsi? {#which-services-work}

Real-Debrid, AllDebrid, TorBox (paket berbayar), Premiumize, Offcloud dan Debrid-Link. Easynews berfungsi untuk pencarian dan casting, bukan untuk library.
