# Whisparr

Whisparr itu Radarr untuk film dewasa dan adegan. Whisparr memakai zurg sebagai klien qBittorrent-nya. Setiap grab dikirim ke akun debrid kamu. Proses import hanya mengganti nama path di dalam `__magic__`; tidak ada yang diunduh atau disalin.

Semua yang ada di bawah ini diuji pada 2026-10-23 dengan Whisparr `3.6.5.1886` (image `ghcr.io/hotio/whisparr:v3`), Prowlarr, zurg yang dibangun dari `main` hari itu, dan akun Real-Debrid. File film 17 GB di-grab, di-import, lalu diputar dari mount.

## Sebelum kamu mulai {#before-you-start}

Siapkan zurg untuk Radarr dulu, dengan [Sonarr & Radarr untuk torrent](sonarr-radarr-torrents.md): akun yang menerima torrent, `__magic__` aktif, dan endpoint qBittorrent aktif. Whisparr memakai ulang semua itu.

## 1. Kategori Whisparr di zurg {#1-whisparrs-category-in-zurg}

Whisparr mengirim unduhannya dengan kategori `whisparr`. Tombol **Test** di langkah 3 akan membuat kategori itu di zurg, jadi kamu tidak perlu menambahkan apa-apa. Kalau tetap ingin mencantumkannya di `config.yml`, tambahkan di samping kategori yang sudah ada:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Jalankan Whisparr {#2-run-whisparr}

Di host Linux, beri Whisparr volume yang sama dengan Radarr, yaitu folder **di atas** mount zurg dengan `rslave` ([alasannya](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)):

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` dan `PGID` adalah user Linux tempat Whisparr berjalan. Image Docker zurg sendiri mengizinkan user mana pun membaca mount-nya. zurg yang diinstal sebagai binary biasa hanya begitu jika dijalankan sebagai root atau dengan `user_allow_other` aktif ([setup Linux](../setup/linux.md#1-install-fuse-3)). Kalau tidak, atur `PUID` dan `PGID` ke user tempat zurg berjalan (`id -u` dan `id -g` akan menampilkannya). Jika tidak, Whisparr akan melihat mount-nya kosong.

Di macOS dan Windows, compose file ini tidak berlaku, dengan alasan yang dijelaskan di [langkah 8 panduan Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Instal Whisparr sebagai aplikasi biasa di sana, dan perhatikan hal-hal yang tercantum di [Sebelum kamu mulai](sonarr-radarr.md#before-you-start) pada panduan itu: gunakan user yang sama dengan zurg di macOS, dan gunakan aplikasi tray, bukan Windows service, di Windows. Hanya image Docker di atas yang sudah diuji.

Buka `http://<your server>:6969`.

## 3. Tambahkan zurg sebagai download client {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**, isi persis seperti untuk Radarr ([kolom-kolomnya](sonarr-radarr-torrents.md#what-to-put-in-each-field)), kecuali **Category** diisi `whisparr`. Biarkan **Remove Completed** tetap aktif. Klik **Test**, lalu **Save**.

## 4. Tambahkan root folder {#4-add-the-root-folder}

Buat folder di mount, lalu tambahkan di **Settings → Media Management → Root Folders**:

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

Folder ini ada di samping `__magic__/movies`, bukan di dalamnya. Whisparr menyimpan setiap film di bawah studionya, dengan format `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. Indexer {#5-indexers}

DMM tidak punya kategori dewasa di indexer-nya, jadi Whisparr butuh indexer lain. Di Prowlarr, indexer publik **Knaben** dan **The Pirate Bay** sama-sama berhasil dipakai. **XXXClub** dilindungi Cloudflare, dan Prowlarr tidak bisa menambahkannya tanpa Cloudflare solver.

Lalu hubungkan Prowlarr ke Whisparr lewat **Settings → Apps → + → Whisparr** di Prowlarr, dengan alamat Whisparr dan API key-nya (ada di **Settings → General** Whisparr). Prowlarr akan menambahkan indexer-nya sendiri ke Whisparr.

zurg hanya menerima rilis yang sudah ada di akun kamu (`cached_only`, aktif secara default). Kalau zurg menolak satu rilis, Whisparr akan mengambil hasil berikutnya.

## 6. Ambil satu {#6-grab-one}

Tambahkan film di Whisparr dengan **Start search for missing movie** dicentang. Jika berhasil, riwayat Whisparr akan menampilkan **Grabbed** lalu **Imported** dalam hitungan detik, dan film tersebut ada di mount:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

Di macOS, path-nya diawali `/Volumes/Zurg`; di Windows, buka `Z:\__magic__\whisparr\movies` di Explorer. Tidak ada yang masuk ke folder `data/local` milik zurg. File di-stream dari akun Anda.

## Menontonnya {#watching-it}

Arahkan library Plex atau Jellyfin ke `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` di macOS, `Z:\__magic__\whisparr` di Windows) supaya film-film ini tersimpan di library sendiri.

Di rex, film-film ini muncul di library mana pun yang dipilih oleh folder zurg, sama seperti rilis lainnya, yang pada kebanyakan setup berarti library movies.
