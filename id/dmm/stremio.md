# Pakai DMM di Stremio dengan DMM Cast {#use-dmm-in-stremio-with-dmm-cast}

DMM Cast adalah addon Stremio dari Debrid Media Manager. Lewat addon ini DMM muncul di Stremio: kamu pilih rilis di DMM, tekan **Cast**, lalu Stremio menampilkannya sebagai stream yang diputar dari akun debrid atau Easynews milikmu sendiri. Singkatnya, login di DMM, buka halaman Cast dari provider kamu, pasang addon di Stremio, lalu tekan **Cast** pada film atau serial apa pun.

Cast di sini berarti addon DMM. Bukan Chromecast atau screen mirroring.

## Yang kamu butuhkan {#what-you-need}

- Sign-in DMM dengan Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link, atau Easynews.
- Stremio. [Stremio Web](https://web.stremio.com) bisa dipakai tanpa akun Stremio.

Tidak perlu sponsorship.

## Atur dulu {#set-it-up}

1. Masuk di [debridmediamanager.com](https://debridmediamanager.com) dengan provider kamu. Easynews masuk lewat **Settings**.
2. Di halaman utama DMM, tekan **Cast for RD**, **Cast for TB** dan seterusnya. Kalau kamu sudah masuk dengan beberapa akun, ada satu baris **Cast** dengan satu tombol per provider. Setiap provider punya halaman Cast sendiri:

   | Provider | Halaman Cast |
   |---|---|
   | Real-Debrid | [debridmediamanager.com/stremio](https://debridmediamanager.com/stremio) |
   | TorBox | [debridmediamanager.com/stremio-torbox](https://debridmediamanager.com/stremio-torbox) |
   | AllDebrid | [debridmediamanager.com/stremio-alldebrid](https://debridmediamanager.com/stremio-alldebrid) |
   | Premiumize | [debridmediamanager.com/stremio-premiumize](https://debridmediamanager.com/stremio-premiumize) |
   | Offcloud | [debridmediamanager.com/stremio-offcloud](https://debridmediamanager.com/stremio-offcloud) |
   | Debrid-Link | [debridmediamanager.com/stremio-debridlink](https://debridmediamanager.com/stremio-debridlink) |
   | Easynews | [debridmediamanager.com/stremio-easynews](https://debridmediamanager.com/stremio-easynews) |

   ![Halaman Cast DMM untuk Premiumize, alamat addon disamarkan](../assets/dmm-stremio/01-dmm-cast-page.webp)

3. Tekan **Install (web)**. Stremio Web terbuka dengan addon-nya. Tekan **Install** di sana.

   ![Stremio Web meminta untuk memasang DMM Cast](../assets/dmm-stremio/02-stremio-install.webp)

   Untuk Stremio lain, salin alamat yang ditampilkan di bawah tombol lalu tambahkan di sana. Di Stremio Web caranya **Addons** → **Add addon** → tempel → **Add** → **Install**. Alamat ini pribadi untuk akunmu, jadi jangan pernah membagikannya.

4. Kembali ke DMM, cari film atau serial lalu buka. Rilis yang sudah ada di provider kamu akan mendapat tombol **Cast**: **Cast (RD)**, **Cast (TB)**, **Cast (AD)**, **Cast (PM)**, **Cast (OC)** atau **Cast (DL)**. Tekan tombol itu. DMM akan menampilkan **Cast started in Stremio** (untuk serial, **Casting succeeded.** beserta jumlah episode yang di-cast) dan mencoba membuka judul tersebut di aplikasi Stremio kamu.

   ![Menekan Cast (PM) di DMM](../assets/dmm-stremio/03-dmm-cast-button.webp)

5. Buka judul tersebut di Stremio. Cast kamu muncul sebagai **DMM Cast PM (Yours)** (RD, TB dan seterusnya untuk provider lain). Tekan untuk memutar.

   ![Stremio menampilkan cast sebagai DMM Cast PM (Yours)](../assets/dmm-stremio/04-stremio-streams.webp)

## Apa lagi yang bisa kamu dapat di Stremio {#what-else-you-get-in-stremio}

- **DMM Cast PM ✨ · Cast a file inside a torrent** pada setiap film dan episode. Opsi ini membuka judul tersebut di DMM, sehingga kamu bisa melakukan cast rilisan dari sana.
- Hingga lima stream tambahan dari cast orang lain dan dari rilisan yang sudah dimiliki provider kamu. Atur jumlahnya di bawah **Other streams limit** pada halaman Cast. Sponsor bisa menaikkannya hingga sepuluh.
- Baris di Board Stremio: **DMM PM Movies** dan **DMM PM TV Shows** berisi cast kamu. **DMM PM Library** berisi semua yang ada di akun kamu, dan setiap item dibuka beserta file-filenya. Easynews tidak punya baris Library.
- Tidak mau baris-baris itu? Pasang addon dengan **Without catalogs** → **Install (web)** sebagai gantinya. Stream tetap muncul.
- **Manage Casted Links** di halaman Cast menampilkan cast kamu. Centang yang ingin dihapus (atau **Select All**) lalu tekan **Delete Selected** untuk menghapusnya dari Stremio.
- **Hide "Cast a file inside a torrent" option** di halaman Cast menghilangkan baris ✨.

Di Debrid-Link, cast akan menambahkan rilisan ke akun kamu. Rilisan yang belum ada di Debrid-Link akan memulai unduhan sungguhan dan memakai satu dari 50 torrent kamu untuk hari itu.

## Ketika ada yang salah {#when-something-is-wrong}

| Yang Anda lihat | Yang perlu dilakukan |
|---|---|
| Hanya **DMM Cast PM ✨ · Cast a file inside a torrent** (RD, TB…) yang muncul, tanpa stream lain | Belum ada yang di-cast untuk judul ini. Tekan baris itu: akan membuka judul tersebut di DMM. Tekan **Cast** pada sebuah rilis, lalu buka kembali judul itu di Stremio. |
| **⚠️ DMM Cast · Set up DMM Cast for Premiumize again** (atau provider Anda) sebagai satu-satunya stream | Addon di Stremio sudah tidak cocok dengan sign-in DMM Anda. Tekan untuk membuka halaman Cast Anda, sign in, lalu hapus addon lama dari Stremio dan pasang lagi dari halaman itu. |
| **Real-Debrid Required. You must be logged in with Real-Debrid to use the Stremio Cast feature.** (atau TorBox, Easynews…) | Anda belum sign in ke provider itu di DMM, atau Anda membuka halaman Cast milik provider lain. Tekan **Login with …**, atau gunakan tombol **Cast for …** di halaman depan DMM. |
| **No episodes in this release on Premiumize** | DMM tidak bisa mencocokkan file pada rilis itu dengan episode. Cast rilis lain. |
| Alamat addon yang ditempel di kolom pencarian di bagian atas Stremio Web tidak melakukan apa-apa | Kolom itu hanya untuk mencari. Gunakan **Addons** → **Add addon**. |

Masih bingung? Tanyakan di forum **dmm-cast-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Pertanyaan {#questions}

### Bisakah saya mencari DMM di Stremio? {#can-i-search-dmm-in-stremio}

Tidak. DMM Cast tidak menambahkan pencarian ke Stremio, dan hasil pencarian Stremio tidak menampilkan apa pun darinya. Cari di [debridmediamanager.com](https://debridmediamanager.com) lalu tekan **Cast**. Dari judul yang sudah kamu buka di Stremio, baris ✨ akan membawamu ke judul tersebut di DMM.

### Apakah ini berfungsi di TV, Fire TV, atau ponsel saya? {#does-it-work-on-my-tv-fire-tv-or-phone}

Cast disimpan di DMM, bukan di perangkat yang kamu pakai untuk cast. Setiap Stremio yang memakai alamat addon kamu akan menampilkannya. Cast dari ponsel atau komputer kamu, lalu pilih stream **(Yours)** di Stremio di tempat kamu menonton.

### Penyedia mana saja yang berfungsi? {#which-providers-work}

Real-Debrid, TorBox, AllDebrid, Premiumize, Offcloud, Debrid-Link dan Easynews. Masing-masing punya halaman Cast dan addon sendiri. Pasang satu untuk setiap akun yang ingin kamu pakai di Stremio.

### Kenapa Stremio hanya menampilkan Cast dan tidak ada stream? {#why-does-stremio-show-only-cast-and-no-stream}

Belum ada yang di-cast untuk judul itu. Tekan baris ✨, cast rilis di DMM, lalu buka judul tersebut di Stremio lagi.

### Bisakah saya memutar seluruh pustaka debrid saya di Stremio? {#can-i-play-my-whole-debrid-library-in-stremio}

Ya. Baris **DMM Library** di Board Stremio berisi semua yang ada di akun kamu (bukan di Easynews). Buka sebuah item untuk melihat file-filenya.

### Apakah saya perlu sponsorship? {#do-i-need-a-sponsorship}

Tidak. Untuk DMM Cast, sponsorship hanya menaikkan **Other streams limit** dari lima menjadi sepuluh. Dapatkan API key DMM kamu di [gatekeeper](https://gatekeeper.debridmediamanager.com/) lalu tempel di **Settings** DMM.
