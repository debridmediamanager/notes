# Bermigrasi dari decypharr ke zurg {#migrating-from-decypharr-to-zurg}

Baca [halaman bersama](index.md) dulu. Di sana dijelaskan trash guard dan kenapa library kamu masuk ke `__magic__`.

decypharr dan zurg memecahkan masalah yang sama dan susunan root-nya mirip. Sebagian besar setup bisa dibawa langsung.

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | a `directories:` entry with `not_provider: nzb` |
| `nzbs/<job>/` | a `directories:` entry with `provider: nzb` or the built-in `__nzb__` |

**Sisi debrid tidak perlu apa-apa.** Kedua server menampilkan akun yang sama
dan menyajikan nama file asli dari torrent. Path-path itu sama persis begitu zurg
berada di mountpoint decypharr. Semua yang di bawah ini membahas sisi Usenet.

Ada dua hal yang perlu diselesaikan sebelum kamu mulai.

- **Penyedia.** Penyedia tidak membatasi migrasi. zurg punya backend untuk
  setiap layanan yang didukung decypharr. Akun Premiumize dan Debrid-Link ikut pindah
  seperti yang lain. Masing-masing punya halaman di bawah [Penyedia](../providers/index.md).
- **Jangan ubah `folder_naming` decypharr sebelum migrasi.** Itu mengganti nama
  setiap folder di library sekaligus. Akibatnya semua target symlink dan semua
  path Plex mount-direct rusak sekaligus.

## Yang berbeda di sisi Usenet {#what-differs-on-the-usenet-side}

Dibandingkan dengan zurg pada lima rilis yang sama.

| | |
|---|---|
| zurg menambahkan | `thumbnail.jpg`, klip sampel, `.nfo`, iklan `.url`, direktori dalam arsip, **dan rilis terobfuskasi yang dibuang decypharr** |
| zurg kehilangan | tidak ada |
| diubah namanya | rilis berkas tunggal dan rilis arsip |

**Rilis berkas tunggal** keluar dari decypharr dengan nama sesuai job. Anda akan mendapatkan `ToyStory5/ToyStory5.mkv`, sedangkan zurg tetap mempertahankan nama dari pengunggah dan menyajikan `ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`.

**Rilis arsip** adalah kasus yang menarik dan layak dipahami karena menjelaskan dua gejala sekaligus. decypharr menghasilkan ini.

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

Itu adalah nama direktori dalam arsip dan nama berkas itu sendiri yang digabung **tanpa pemisah**. Ini adalah penggabungan path yang kehilangan `/`-nya. Jadi level direktori yang hilang dan nama berkas yang rusak sebenarnya adalah satu cacat, bukan dua. zurg mereproduksi struktur asli di `FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`.

**Rilis multi-berkas dan season pack tetap mempertahankan nama berkas aslinya di kedua sisi.** Keduanya akan cocok secara otomatis begitu nama foldernya cocok.

## Seperti apa library kamu setelahnya {#what-your-library-looks-like-afterwards}

**Semuanya ditambahkan ulang** karena root library pindah ke `__magic__`. Lihat [halaman bersama](index.md) untuk alasan kenapa tidak ada jalan yang lebih murah.

Keuntungannya ada di nama file. Setiap rilis dengan satu payload sekarang kembali dengan nama file dari pengunggah, bukan nama job. Jadi `ToyStory5/ToyStory5.mkv` berubah menjadi `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`. Itu string yang dibaca Sonarr, Radarr, dan Plex untuk mengambil kualitas, sumber, grup, dan edisi. Rilis arsip tidak lagi membawa nama yang menyatu dan sekarang berada di direktori arsipnya sendiri. Rilis multi-file dan season pack sudah terbaca dengan benar dan tidak berubah.

Daftar rilis yang namanya berubah.

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
done
```

!!!info Kamu akan melihat ini atau tidak tergantung setup kamu
Kalau Plex membaca mount secara langsung, nama di atas adalah yang berubah di library kamu. Itu berlaku untuk semua setup Windows dan setup Linux atau macOS yang tidak memakai symlink farm \*arr.

Kalau Sonarr dan Radarr mengatur library symlink dengan renaming aktif, **nama file kamu sudah sesuai dengan nama dari mereka** dan tidak ada nama di atas yang muncul di Plex. Yang bisa kamu lihat dari nama itu adalah seberapa bagus parse yang dipakai \*arr. Ini penting saat kamu melakukan import ulang. Lihat [halaman bersama](index.md).
!!!

## Konten baru apa yang muncul {#what-new-content-shows-up}

- **Klip sampel** di dalam `Sample/`. Ini yang paling layak dikonfigurasi. Atur [`only_show_the_biggest_file: true`](../reference/config.md) kalau kamu tidak mau sampel 9 MB muncul sebagai versi kedua.
- `thumbnail.jpg`, file `.nfo`, dan file `.url` iklan dari poster. Semuanya tidak berpengaruh.
- **Rilis terobfuskasi yang dijatuhkan decypharr** muncul sebagai item baru di perpustakaan. decypharr tidak menerbitkan apa pun untuk postingan yang namanya berupa hash penuh. zurg menyelesaikannya ke nama rilis yang sebenarnya lalu menyajikannya.
- Folder kosong di tempat rantai arsip terputus.

## Ambil kembali NZB Anda {#get-your-nzbs-back}

**decypharr tidak bisa memberikannya kepada Anda.** Ia menyimpan satu binary terkompresi per job
di `usenet/meta/<uuid>.meta` dan direktori `usenet/nzbs/` yang kosong saat diuji. Tidak ada ekspor yang terdokumentasi. Apakah blob `.meta` bisa di-decode kembali menjadi NZB belum terverifikasi. Anggap file aslinya tidak bisa dipulihkan.

Yang Anda punya adalah nama job. Di kedua server, nama folder job *adalah* nama file NZB. Jadi daftar folder itulah daftar belanjaan Anda.

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

Untuk setiap job, unduh ulang NZB dari indexer Anda dengan mencari nama folder tersebut. Lalu **ganti nama file menjadi persis nama itu ditambah `.nzb`** sebelum memasukkannya ke direktori `nzbs/` zurg. Nama file adalah nama folder, dan nama folder itulah yang membuat path tetap stabil.

Dua aturan selama proses ini.

- **Lewati rilis apa pun yang sudah dimiliki akun debrid.** Symlink di-resolve melalui salinan torrent. Jika NZB juga ditambahkan, zurg akan melihat dua rilis berbeda dengan satu nama, dan salah satunya diberi sufiks hash menjadi `Some.Release {a1b2c3}`. Ini akan merusak apa pun yang mengarah ke nama polos tersebut.
- Rilis yang tidak lagi ada di indexer Anda akan hilang begitu saja. Dengan `autoEmptyTrash` diatur ke `0`, item Plex tetap ada di tempat sampah sampai Anda memutuskan untuk menghapusnya.

## Bangun zurg berdampingan {#build-zurg-alongside}

Jalankan zurg di samping decypharr dengan mountpoint sendiri. Keduanya boleh membaca daftar akun debrid yang sama sekaligus, karena listing hanya bersifat read-only.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30                # your plan's real allowance
retain_rd_torrent_name: false        # align with decypharr's folder_naming
retain_folder_name_extension: false  # true if your folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                         # optional: mirror decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

Lalu cek dulu bahwa sisi debrid sudah sejalan sebelum lanjut.

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

Kadang folder torrent berbeda secara *sistematis*. Ekstensi ada atau tidak ada. Nama hasil rename RD muncul menggantikan nama asli. Dalam kasus seperti itu, balik `retain_rd_torrent_name` atau `retain_folder_name_extension` lalu scan ulang, jangan memperbaiki satu per satu secara manual. Folder yang hanya ada di sisi decypharr adalah job Usenet. Nama folder Premiumize dan Debrid-Link belum dibandingkan dengan decypharr. Cek folder akun-akun itu di sini juga.

## Pindah sepenuhnya {#cut-over}

Satu jalur, apa pun yang kamu punya sekarang. Tidak ada langkah di sini yang memindahkan byte.

**1. Aktifkan `__magic__`** lalu restart. Rute didaftarkan saat startup, jadi toggle di dashboard butuh restart sebelum namespace merespons.

```yaml
magic:
  enabled: true
```

**2. Buat root folder.** Letakkan di root `__magic__`, sejajar dengan `__all__` yang tetap disimpan zurg di sana. Bukan `__magic__/__all__`, bukan `__magic__` itu sendiri, dan bukan root mount. Kedua \*arr akan memunculkan health check untuk lokasi itu. Folder sejajar tidak memicunya.

Di Docker, \*arr harus bisa mengakses `__all__` dan root folder ini lewat satu volume. Setup decypharr sering mem-bind folder downloads dan folder media secara terpisah. Dua volume membuat setiap impor menjadi salinan penuh. Bind parent dari mount zurg sekali saja. [Panduan](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) menunjukkan caranya.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` mencerminkan library, jadi setiap rilis sudah ada sebelum kamu mengatur apa pun.

**3. Atur.** `mv` di dalam `__magic__` hanya menulis satu baris dan tidak memindahkan byte.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Kalau Sonarr dan Radarr yang mengatur library lama kamu, pindahkan ke sini dengan satu script.** Script ini mengganti nama setiap file yang ditunjuk library lama ke root folder baru di bawah `__magic__`. Setiap file masuk ke path yang sudah diharapkan \*arr. Tidak ada yang disalin. Lalu kamu ganti root folder \*arr tanpa membiarkannya memindahkan apa pun. Langkah dan scriptnya ada di [halaman bersama](index.md#coming-off-a-symlink-library). Jangan pernah biarkan \*arr memindahkan file sendiri. Itu melintasi batas mount, jadi jadi salinan dan akan mengunduh ulang library kamu.

Script ini butuh fungsi `zurg_path` untuk link decypharr. Simpan sebagai `zurg_path.sh` di sebelahnya dan atur `OLDMOUNT` ke lokasi tempat decypharr di-mount.

```bash
OLDMOUNT=/mnt/decypharr         # decypharr's mount, where the old links point
zurg_path() {
  local rel=${1#"$OLDMOUNT"/__all__/}
  [ "$rel" = "$1" ] && return   # not a link into decypharr
  local job=${rel%%/*} name=${1##*/} f videos
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # decypharr welded an archive's inner folder and file into one name.
  for f in "$ZURG/__all__/$job"/*/*; do
    [ "$(basename "$(dirname "$f")")$(basename "$f")" = "$name" ] && { echo "$f"; return; }
  done
  # decypharr named a lone video after the job. Take the job's one video.
  case "$name" in "$job".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$job" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Link ke rilis debrid atau rilis NZB multi-file menunjuk file yang sama di kedua server. decypharr mengganti nama dua jenis rilis NZB. Ia memberi nama video tunggal dengan nama job, dan ia menggabungkan folder dan file arsip menjadi satu nama. Fungsi ini menemukan salinan zurg untuk keduanya. Job dengan lebih dari satu video tidak pernah ditebak. Sebagai gantinya, ia mencetak `NOT IN ZURG`.

**4. Arahkan Plex ke root folder yang kamu buat**, yaitu `__magic__/tv` dan `__magic__/movies`, dan hanya ke itu. Jangan pernah ke root `__magic__`, karena itu juga memuat seluruh library di `__magic__/__all__`. Jangan pernah juga `__magic__` *dan* sebuah direktori filter, atau setiap episode akan terdeteksi dua kali. Pastikan `autoEmptyTrash` bernilai `0`. Tambahkan lokasi baru lalu scan. Setelah itu, hapus yang lama. Itu adalah path library \*arr kamu, atau mount decypharr jika Plex membacanya langsung.

**5. Kosongkan trash** setelah kamu cek beberapa item secara acak. Status tonton kembali lewat pencocokan GUID. Collection dan pilihan artwork tidak.

Biarkan decypharr tetap berjalan sampai saat itu. Ia tidak memakan biaya dan ia rollback kamu. Jangan hapus config-nya juga, atau state `db/` dan `usenet/`-nya. Kalau sudah selesai, hentikan.

```bash
sudo systemctl stop decypharr
```

## Setelahnya {#afterwards}

**Automation ikut terbawa, kedua bagiannya.** zurg punya endpoint yang kompatibel dengan SABnzbd (opt-in) [lihat di sini](../guides/sonarr-radarr.md) sehingga Sonarr dan Radarr bisa mengirim NZB ke zurg, dan endpoint yang kompatibel dengan qBittorrent (opt-in) [lihat di sini](../guides/sonarr-radarr-torrents.md) sehingga mereka bisa mengirim magnet atau `.torrent` untuk akun debrid. Keduanya diimpor dari `__magic__/__all__` dengan cara di-rename. Ini pilihanmu.

- **NZB.** Aktifkan `sabnzbd.enabled` lalu arahkan \*arr ke zurg. zurg mengecek setiap grab sebelum melaporkannya selesai. Ia bertanya ke news server tentang awal dan akhir setiap file. Ia juga mengunduh artikel pertama dari setiap file. Itu bisa sampai enam puluh empat artikel, ditambah beberapa lagi untuk rilis dengan hanya sedikit file. Beberapa news server masih bilang sebuah artikel ada padahal isinya sudah dihapus, dan hanya unduhan yang bisa menunjukkannya. zurg membangun ulang rilis dengan artikel yang hilang dari file PAR2-nya jika memungkinkan. Yang tidak bisa dibangun ulang akan dilaporkan **Failed**. \*arr lalu memasukkannya ke blocklist dan mengambil yang lain. Pengecekannya hanya sampel, bukan seluruh post. Post yang kehilangan bagian yang tidak tersentuh sampel tetap dilaporkan Completed dan baru gagal saat pembacaan yang mengenai celah itu.
- **Torrent.** Aktifkan `qbittorrent.enabled` dan tambahkan sebagai download client kedua. Rilis dari private tracker bisa bekerja jika indexer memberikan file `.torrent`, bukan magnet saja, karena file itu membuat pencarian cache akun memakai hash secara langsung.
- **Tambah sekali jalan.** Dashboard zurg tidak punya tombol add. Tambahkan magnet atau `.torrent` lewat endpoint qBittorrent dengan kategori salah satu \*arr, maka rilisnya akan masuk ke \*arr tersebut. [Menambahkan rilis secara manual](../guides/sonarr-radarr-torrents.md#11-adding-a-release-by-hand) menjelaskan caranya. Magnet yang ditambahkan lewat DMM dan NZB yang dimasukkan ke `nzbs/` sama-sama muncul di zurg. Keduanya tidak otomatis sampai ke Sonarr atau Radarr. [Akuisisi](../guides/acquisition.md) bawaan zurg juga mengambil permintaan secara otomatis. Permintaan itu berasal dari watchlist Plex kamu serta dari Seerr dan \*arr. Ia mengambil NZB dari indexer Newznab dan torrent dari indexer Torznab jika akunmu sudah punya rilisnya di cache.
- **Hybrid.** Pertahankan decypharr murni sebagai download client \*arr yang mendorong ke akun debrid yang sama, dengan zurg menyajikan mount-nya. Keduanya mendaftar akun yang sama sehingga zurg menangkap apa pun yang ditambahkan decypharr. Langkah import \*arr kemudian membutuhkan remote path mapping ke tree zurg. Tree itu dan root folder harus berada dalam satu volume. Uji satu grab dulu.
