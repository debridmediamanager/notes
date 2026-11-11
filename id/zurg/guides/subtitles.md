# Subtitle dengan Bazarr {#subtitles-with-bazarr}

Bazarr mencari subtitle untuk apa pun yang diimpor Sonarr dan Radarr, lalu menyimpan setiap subtitle di samping videonya. Dengan zurg, videonya ada di `__magic__`, dan subtitlenya juga. Library Plex dan Jellyfin yang mengarah ke `__magic__` membacanya seperti subtitle biasa di disk, dan rex juga menampilkannya, sebagai **English (SRT External)** di menu subtitle.

Ini membutuhkan zurg dan rex dari nightly 2026-10-24 atau yang lebih baru.

Semua yang ada di bawah ini diuji pada 2026-10-23 dengan Radarr `6.3.0.10514`, image `lscr.io/linuxserver/bazarr` yang terbaru, zurg dan rex dari hari itu, serta akun Real-Debrid.

## Sebelum kamu mulai {#before-you-start}

Radarr (atau Sonarr) sudah mengimpor lewat zurg, dengan root folder di dalam `__magic__`, misalnya `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` di macOS, `Z:\__magic__\movies` di Windows). Jika belum, ikuti [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md) atau [for Usenet](sonarr-radarr.md) dulu.

## 1. Jalankan Bazarr {#1-run-bazarr}

Di Linux, beri Bazarr volume yang sama dengan Radarr, supaya keduanya melihat film di path yang sama dan tidak perlu path mapping:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

Bind-nya adalah folder **di atas** mount zurg (`/mnt`, yang berisi `/mnt/zurg`), bukan mount-nya sendiri. Container yang bind ke mount itu sendiri akan menyimpan mount yang sudah mati begitu zurg di-restart, dan setiap pembacaan akan menjawab `Socket not connected`. [Langkah Docker di panduan torrent](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) menjelaskan alasannya. `PUID` dan `PGID` perlu diatur dengan hati-hati seperti untuk Whisparr: [lihat di sana](whisparr.md#2-run-whisparr).

Di macOS dan Windows, compose file ini tidak berlaku, karena alasan di [langkah 8 panduan Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Jalankan Bazarr dari source (`python bazarr.py`) di mesin yang sama dengan Radarr dan zurg, sebagai user yang sama dengan zurg, dengan mengikuti halaman resmi Bazarr untuk [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) dan [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/). Di Windows, lewati installer Bazarr: installer itu memasang Bazarr sebagai Windows service, dan service tidak bisa melihat drive `Z:` milik zurg ([alasannya](sonarr-radarr.md#before-you-start)). Sebaliknya, jalankan `bazarr.py` dari sesi login kamu sendiri. Dengan begitu, Bazarr akan melihat setiap film di path yang dilaporkan Radarr, dan tidak perlu path mapping. Hanya image Docker di atas yang sudah diuji.

Buka `http://<your server>:6767`.

## 2. Hubungkan ke Radarr dan Sonarr {#2-connect-it-to-radarr-and-sonarr}

**Settings → Radarr**: aktifkan, lalu masukkan alamat, port, dan API key Radarr (ada di **Settings → General** Radarr). Dari dalam container, gunakan IP LAN host, bukan `localhost`. **Test**, lalu **Save**. Sonarr caranya sama, di **Settings → Sonarr**.

## 3. Bahasa {#3-languages}

**Settings → Languages**: tambahkan bahasa yang kamu mau, buat language profile dengan bahasa-bahasa itu, lalu jadikan sebagai default profile untuk movies dan series. Bazarr kemudian akan meminta subtitle untuk semua yang sudah ada di Radarr dan Sonarr.

## 4. Provider {#4-providers}

**Settings → Providers**: tambahkan situs subtitle yang dicari Bazarr. Ada yang butuh akun dan ada yang tidak. Dua hal yang kami temui saat pengujian:

- **subf2m** butuh User-Agent di pengaturan provider-nya. Tanpa itu, Bazarr akan menjeda provider ini selama 12 jam pada pencarian pertama.
- Bazarr menjeda provider yang gagal selama beberapa waktu, dan jika semua provider sedang dijeda, pencarian tidak akan menemukan apa-apa. **System → Providers** menampilkan daftarnya dan bisa meresetnya.

## 5. Subtitle tertanam {#5-embedded-subtitles}

Banyak rilis sudah membawa track bahasa Inggris di dalam file video. Bazarr menganggap itu sebagai bahasa Inggris yang sudah ada dan tidak mengunduh apa pun. Kalau kamu tetap ingin file subtitle, matikan **Use Embedded Subtitles** di **Settings → Subtitles**.

## 6. Cek satu {#6-check-one}

Halaman **Movies** di Bazarr menunjukkan subtitle apa yang belum ada untuk tiap film. Cari salah satu film dari sana, dan subtitle-nya akan muncul di sebelah file videonya (di Windows, cek folder yang sama di `Z:\__magic__\movies` lewat Explorer):

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

Subtitle itu adalah file asli di disk zurg, di `data/local/__magic__/` (lihat [Sidecar](magic.md#sidecars-nfo-posters-subtitles)). Videonya tetap di-stream dari akun kamu.

## Di rex {#in-rex}

zurg mengirim ke rex setiap subtitle yang ada di samping video di `__magic__`, di mana pun Radarr atau Sonarr memindahkan video itu.

zurg memeriksa subtitle baru, yang berubah, dan yang dihapus setiap satu menit. Jadi subtitle yang disimpan Bazarr muncul di rex dalam sekitar satu menit, dan subtitle yang kamu hapus juga hilang secepat itu. Kamu tidak perlu mengatur apa-apa selain `rex_url` di config zurg, yang sudah kamu atur di [panduan rex](../../rex/with-zurg.md).

Nama file menunjukkan jenis subtitlenya, sama seperti cara Plex membaca nama subtitle:

| Nama file berakhiran | rex menampilkan |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

File `.srt`, `.ass`, `.ssa`, `.smi` dan `.txt` akan dibaca. Kodenya bisa dua atau tiga huruf (`en`, `eng`, `de`, `ger`). Nama sebelum kode bahasa harus sama dengan nama video itu sendiri, seperti yang ditulis Bazarr.

Hanya subtitle di `__magic__` yang sampai ke rex. Subtitle yang disimpan di samping file di folder zurg lain, misalnya `/mnt/zurg/movies`, tidak akan dikirim.

rex juga bisa mencari subtitle sendiri: **Search Subtitles** di aplikasi Plex mana pun, tanpa perlu Bazarr sama sekali. Lihat [subtitle di rex](../../rex/with-zurg.md#subtitles).
