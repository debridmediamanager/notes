# Seerr melalui DMM {#seerr-through-dmm}

Tambahkan DMM ke [Seerr](https://github.com/seerr-team/seerr) sebagai Radarr dan Sonarr. Permintaan yang disetujui
akan masuk ke [daftar wanted DMM](../zurg/guides/dmm-wanted.md) Anda agar zurg mengambilnya. Anda tidak perlu
Radarr atau Sonarr. Seerr hanya perlu bisa menjangkau debridmediamanager.com. Overseerr dan Jellyseerr
bekerja dengan cara yang sama.

Fitur ini untuk sponsor. Seerr masuk menggunakan API key DMM dari [gatekeeper](https://gatekeeper.debridmediamanager.com/).

## Yang kamu butuhkan {#what-you-need}

- zurg membaca daftar wanted Anda dengan `dmm_api_key` di `config.yml`. Lihat [Fetch what you want from DMM](../zurg/guides/dmm-wanted.md#what-you-need).
- Seerr sudah disiapkan dengan server Plex, Jellyfin atau Emby Anda supaya tahu episode mana yang sudah Anda punya.

## Tambahkan DMM sebagai Radarr {#add-dmm-as-radarr}

Di Seerr, buka **Settings → Services** lalu tekan **Add Radarr Server**. Isi seperti ini:

| Kolom | Isi |
|---|---|
| Default Server | dicentang |
| 4K Server | tidak dicentang |
| Server Name | `DMM`, atau nama apa saja |
| Hostname or IP Address | `debridmediamanager.com` |
| Port | `443` |
| Use SSL | dicentang |
| API Key | API key DMM kamu |
| URL Base | `/api/arr/radarr` |

Tekan **Test**. Setelah terhubung, pilih **Any** untuk Quality Profile dan **/dmm** untuk Root Folder.
Biarkan Minimum Availability seperti adanya. Centang **Enable Scan** lalu tekan **Add Server**.

![Dialog Add Radarr Server di Seerr yang sudah diisi untuk DMM](../assets/seerr-dmm/01-seerr-radarr-dmm.webp)

Kalau Test gagal, cek lagi key-nya: itu yang ada di halaman [Settings](https://debridmediamanager.com/settings) DMM. DMM juga akan menolaknya kalau status sponsorship kamu sudah habis.

## Tambahkan DMM sebagai Sonarr {#add-dmm-as-sonarr}

Tekan **Add Sonarr Server** dan isi URL Base dengan `/api/arr/sonarr`. Setelah **Test**, pilih **Any** untuk profil dan root folder, lalu pilih `/dmm` untuk keduanya. Centang **Enable Scan** dan tekan **Add Server**.

![Dialog Add Sonarr Server milik Seerr yang sudah diisi untuk DMM](../assets/seerr-dmm/02-seerr-sonarr-dmm.webp)

## Meminta {#requesting}

Ajukan seperti biasa. Film yang disetujui akan masuk ke daftar wanted Anda:

![Requesting a film in Seerr](../assets/seerr-dmm/03-seerr-request-movie.webp)

![The film shows as requested](../assets/seerr-dmm/04-seerr-movie-requested.webp)

Untuk serial, pilih musim yang Anda inginkan. Permintaan berikutnya bisa menambah musim lain. Untuk mengikuti seluruh serial termasuk musim baru, tekan **Want all seasons** di halaman DMM-nya.

![Picking seasons of a show](../assets/seerr-dmm/05-seerr-request-seasons.webp)

Daftar [wanted list](https://debridmediamanager.com/wanted) Anda menampilkan setiap judul dalam hitungan detik. zurg
mengambilnya dalam waktu satu menit.

## Apa yang ditampilkan Seerr {#what-seerr-shows}

Seerr membaca daftar DMM sekali sehari di **Radarr Scan** dan **Sonarr Scan**. Untuk menjalankannya sekarang, buka **Settings → Jobs & Cache** lalu tekan **Run Now** di sebelah masing-masing.

- **Sebuah film** yang sudah diambil zurg akan tampil sebagai **Available**.

  ![Film yang sudah diambil tampil sebagai available](../assets/seerr-dmm/06-seerr-movie-available.webp)

- **Sebuah serial** akan tetap **Processing** sampai episodenya masuk ke library Plex, Jellyfin atau Emby kamu dan scan Seerr di server tersebut menemukannya. DMM tidak tahu episode mana yang dimiliki zurg.

## Menghapus judul {#removing-a-title}

Buka judul di Seerr, tekan tombol roda gigi lalu pilih **Remove from Radarr** (atau **Remove from Sonarr**). Itu akan menghapusnya dari daftar yang diinginkan. Yang sudah diambil zurg tetap ada di perpustakaanmu. **Open in Radarr** di sebelahnya akan membuka judul tersebut di DMM.

Mentok? Tanya di forum **dmm-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Seerr melalui DMM atau sumber Seerr milik zurg sendiri {#seerr-through-dmm-or-zurgs-own-seerr-source}

zurg juga bisa membaca Seerr sendiri, dengan [sumber `seerr`](../zurg/guides/acquisition.md#configuration).
Pakai salah satu dari keduanya, jangan keduanya:

- **Lewat DMM**, Seerr cukup bisa terhubung ke internet, permintaannya muncul di daftar keinginan Anda di samping yang Anda tambahkan dengan **Want**, dan pemindaian harian Seerr menandai film yang diambil zurg sebagai tersedia.
- **Sumber milik zurg sendiri** memperlakukan permintaan 4K terpisah dari permintaan 1080p, tetapi zurg harus bisa menjangkau Seerr.
