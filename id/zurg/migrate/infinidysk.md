# Bermigrasi dari InfiniDysk ke zurg {#migrating-from-infinidysk-to-zurg}

Baca [halaman bersama](index.md) dulu. Di sana dijelaskan trash guard dan alasan library kamu masuk ke `__magic__`.

Dibandingkan dengan zurg pada lima rilis yang sama.

| | |
|---|---|
| zurg menambah | klip sample, file `.nfo` |
| zurg kehilangan | 5 volume par2 bernama hash di dalam rilis yang diobfuskasi |
| diganti nama | **setiap rilis kecuali yang multi-file** |

!!!warning Penggantian nama adalah inti dari migrasi
InfiniDysk mengganti nama file media sebuah rilis menjadi nama file NZB setiap kali rilis itu hanya punya satu payload. Pada korpus 2026-09-01, empat dari lima hasilnya menjadi `ToyStory5.mkv`, `Obfuscated.mkv`, `FatherBrown.mp4`, dan `MandaloriaREMUX.mkv`. Hanya season pack sepuluh episode yang tetap memakai nama episodenya. Penggantian nama ini berlaku di kedalaman mana pun. `FatherBrown.mp4` berada *di dalam* direktori `Father.Brown.2013.S02E05.HDTV.x264-TLA/` yang dipertahankan.

zurg mempertahankan nama file dari poster. Jadi nama rilis kembali, dan setiap rilis single-payload berubah path-nya. Nama itulah yang di-parse Plex dan \*arrs untuk mengambil kualitas, group, dan episode.
!!!

Ada satu perbedaan lagi. Kecil, tapi bisa membingungkan kalau kamu belum pernah lihat. InfiniDysk membuat direktori `Sample/` dalam arsip dan membiarkannya **kosong**. zurg menaruh klip sample di dalamnya.

Isi konten bukan alasan untuk pindah. Build `cd9b1205` mengimpor kelima rilis dari korpus referensi, termasuk season pack. Jangan berharap melihat InfiniDysk menjatuhkan sesuatu. Yang kamu dapat kembali adalah penamaannya.

!!!warning Jangan pernah menelusuri root WebDAV
Object store `.ids` memunculkan 16 child hex di setiap dari lima level-nya, terlepas dari isinya. Artinya 16^5, atau sekitar 1.048.576 direktori. Arahkan `find`, `du`, `rclone`, dan scanner apa pun secara eksplisit ke `/content`, `/nzbs`, atau `/completed-symlinks`. Jangan pernah ke `/`.
!!!

## Seperti apa library kamu setelahnya {#what-your-library-looks-like-afterwards}

**Semua harus ditambahkan ulang** karena root library pindah ke `__magic__`. Lihat
[halaman bersama](index.md) untuk alasan kenapa tidak ada jalan yang lebih murah.

Ini adalah migrasi yang paling sedikit merugikan kamu dan paling banyak memberi keuntungan. Hampir semua nama file jadi lebih baik. `ToyStory5.mkv` berubah jadi
`Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`, dan \*arr yang mengimpor ulang dari `__magic__` akhirnya bisa membaca kualitas, sumber, grup, dan edisi langsung dari nama file. Hanya season pack yang tetap sama, dan itu memang sudah terbaca dengan benar.

Daftar rilis yang namanya berubah. Jumlahnya kemungkinan besar banyak.

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

`-maxdepth 4` itu penting karena perubahan nama bisa terjadi satu level di dalam direktori arsip.

!!!info Apakah kamu melihat semua ini tergantung setup kamu
Jika Plex membaca mount secara langsung, maka nama-nama di atas adalah yang berubah di library kamu. Itu berlaku untuk semua setup Windows dan setup Linux atau macOS yang tidak memakai symlink farm \*arr.

Jika Sonarr dan Radarr mengatur library symlink dengan renaming aktif, maka **nama file kamu sudah sesuai dengan mereka** dan tidak ada nama di atas yang muncul di Plex. Yang nama-nama itu tunjukkan adalah seberapa bagus parse yang dipakai \*arr. Itu penting saat kamu impor ulang. Lihat [halaman bersama](index.md).
!!!

## Konten baru apa yang muncul {#what-new-content-shows-up}

- **Sample clips.** Folder `Sample/` yang sudah ada tidak lagi kosong. Ini yang paling perlu dikonfigurasi. Atur [`only_show_the_biggest_file: true`](../reference/config.md) jika Anda tidak ingin klip sample 9 MB muncul sebagai versi kedua dari episode.
- File `.nfo` di dalam rilis RAR. Tidak berpengaruh di agen default Plex.
- Folder kosong di tempat rantai arsip terputus. InfiniDysk tidak membuat apa pun untuk itu.
- **File par2 dan sfv tidak lagi terlihat.** Termasuk volume bernama hash di dalam rilis yang diobfuskasi. File itu tidak punya ekstensi media, jadi Plex tidak akan mendaftarkannya. Jika ada alat non-Plex yang Anda pakai untuk membaca folder itu, alat tersebut akan melihat perbedaannya.

## Keluarkan NZB kamu {#get-your-nzbs-out}

zurg dapat input dari sebuah direktori berisi file `.nzb`. Satu file per rilis, dan namanya mengikuti nama folder rilisnya. WebDAV InfiniDysk di `/nzbs/<category>/` mencerminkan antrean dan bisa dibaca.

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

Apakah job yang sudah selesai tetap tercantum di `/nzbs` setelah selesai itu **belum terverifikasi**. Folder itu mencerminkan antrean, dan riwayatmu mungkin lebih dalam daripada antreanmu. Untuk rilis yang tidak ada di sana, metadata NZB yang disimpan InfiniDysk untuk remount ada di `{CONFIG_PATH}/blobs/`. Format blob juga belum terverifikasi, jadi cek dulu sebelum mengandalkannya.

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

Kalau blob di instalasimu bukan XML biasa, riwayat unduhan dari indexer-mu jadi cadangannya.

Setelah itu, buat file `<release>.nzb` untuk setiap folder rilis yang memang kamu punya.

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

NZB yang diambil dari `/nzbs/<category>/` biasanya sudah punya nama yang benar. Dari situlah nama folder berasal. Ada dua aturan penamaan zurg yang perlu dicek terhadap daftarmu.

- zurg menghapus `.mkv` atau `.mp4` di akhir nama folder. Kalau ada folder rilis yang berakhiran begitu, atur `retain_folder_name_extension: true`.
- Dua rilis berbeda yang namanya sama akan mendapat akhiran ` {shorthash}` pada salah satunya. Cari dengan `cut -f2 releases.tsv | sort | uniq -d`. InfiniDysk punya masalah serupa dengan cara lain. Mengimpor ulang NZB di sana membuat `<Release> (2)`.

## Bangun zurg berdampingan {#build-zurg-alongside}

InfiniDysk tetap menyajikan konten selama proses berlangsung.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from InfiniDysk's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
enable_repair: true
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l          # should approach your release count
```

`__all__` berisi semua rilis tanpa memedulikan filter direktori.

## Pindah sepenuhnya {#cut-over}

Satu jalur, apa pun yang kamu punya sekarang. Tidak ada langkah di sini yang memindahkan data.

**1. Aktifkan `__magic__`** lalu restart. Rute didaftarkan saat startup, jadi toggle di dashboard butuh restart dulu sebelum namespace-nya merespons.

```yaml
magic:
  enabled: true
```

**2. Buat folder root.** Folder ini ditaruh di root `__magic__`, sejajar dengan `__all__` yang disimpan zurg di sana. Jangan di `__magic__/__all__`, jangan di `__magic__` itu sendiri, dan jangan di root mount. Kedua \*arr akan memunculkan health check untuk lokasi itu; folder sejajar tidak memicunya.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` mencerminkan library sehingga setiap rilis sudah ada sebelum kamu mulai mengatur apa pun.

**3. Atur.** `mv` di dalam `__magic__` hanya menulis satu baris dan tidak memindahkan data.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Kalau Sonarr dan Radarr yang mengatur library lama kamu, pindahkan dengan satu script.** Script ini mengganti nama setiap file yang ditunjuk library lama ke dalam folder root baru di bawah `__magic__`. Setiap file mendarat di path yang sudah diharapkan \*arr. Tidak ada yang disalin. Setelah itu kamu ganti root folder \*arr tanpa membiarkannya memindahkan apa pun. Langkah dan script-nya ada di [halaman bersama](index.md#coming-off-a-symlink-library). Jangan pernah biarkan \*arr memindahkan file sendiri. Itu melintasi batas mount. Itu berarti menyalin dan mengunduh ulang library kamu.

Script ini butuh fungsi `zurg_path` untuk link InfiniDysk. Simpan ini sebagai `zurg_path.sh` di sebelahnya dan atur `OLDMOUNT` ke lokasi mount InfiniDysk.

```bash
OLDMOUNT=/mnt/remote/infinidysk # InfiniDysk's mount, where the old links point
# The map from each .ids name to its release and file. Built once while InfiniDysk runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # InfiniDysk named a lone video after the release. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Link InfiniDysk mengarah ke penyimpanan `.ids`-nya, dan zurg tidak punya hal seperti itu. Jadi fungsi ini membaca pohon `completed-symlinks` milik InfiniDysk sekali saja untuk mengetahui rilis dan file mana yang diwakili setiap nama `.ids`. Biarkan InfiniDysk tetap berjalan sampai script selesai. Jika InfiniDysk memberi nama satu video saja berdasarkan rilisnya, fungsi mengambil satu-satunya video yang disajikan zurg di rilis itu. Rilis dengan lebih dari satu video tidak pernah ditebak. Sebagai gantinya script mencetak `NOT IN ZURG`.

**4. Arahkan Plex ke folder root yang sudah kamu buat** — `__magic__/tv` dan `__magic__/movies` — dan hanya ke situ. Jangan pernah ke root `__magic__`, karena di sana juga ada seluruh library di `__magic__/__all__`, dan jangan pernah ke `__magic__` *dan* folder filter sekaligus, atau setiap episode akan terdeteksi dua kali. Pastikan `autoEmptyTrash` bernilai `0`. Tambahkan lokasi baru dan scan. Lalu hapus yang lama. Itu adalah path library \*arr kamu, atau mount InfiniDysk kalau Plex membacanya langsung.

**5. Kosongkan trash** setelah kamu memeriksa beberapa item. Status tonton kembali lewat pencocokan GUID. Koleksi dan pilihan artwork tidak.

Biarkan InfiniDysk berjalan sampai saat itu. Tidak ada biayanya dan itu jadi jalan balik kamu. Kalau sudah selesai, baru hentikan.

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## Setelahnya {#afterwards}

Simpan `{CONFIG_PATH}/blobs/` dan set NZB yang sudah kamu pulihkan sampai kamu selesai streaming dari sampel yang mewakili.

Sekarang pikirkan soal akuisisi. zurg punya [endpoint yang kompatibel dengan SABnzbd](../guides/sonarr-radarr.md) yang harus diaktifkan sendiri, dan Sonarr serta Radarr bisa mengambil file lewat endpoint itu. Endpoint ini menggantikan InfiniDysk sebagai download client mereka. Hasil grab masuk ke `__magic__/__all__`, lalu proses import memindahkannya dengan rename. Tidak ada yang disalin.

zurg memeriksa setiap grab sebelum melaporkannya selesai. Ia menanyakan ke news server soal awal dan akhir setiap file. Ia juga mengunduh artikel pertama dari setiap file. Jumlahnya bisa sampai enam puluh empat, ditambah beberapa lagi untuk rilis yang hanya punya sedikit file. Beberapa news server masih bilang sebuah artikel ada padahal isinya sudah dihapus, dan cara satu-satunya untuk tahu adalah dengan mengunduhnya. zurg membangun ulang rilis dengan artikel yang hilang dari file PAR2-nya kalau memungkinkan. Rilis yang tidak bisa dibangun ulang akan dilaporkan sebagai **Failed**. Setelah itu, \*arr akan memasukkannya ke daftar blokir dan mengambil yang lain. Pemeriksaan ini hanya sampel, bukan seluruh post. Post yang kehilangan bagian yang tidak tersentuh sampel tetap dilaporkan Completed, lalu gagal saat pembacaan mengenai bagian yang hilang itu.

Simpan root folder \*arr di dalam `__magic__`. Root folder di tempat lain akan membuat salinan penuh dari setiap import. Di Docker, berikan satu volume untuk \*arr yang berisi seluruh mount zurg. Download folder dan root folder di dua volume berbeda juga akan membuat salinan setiap import. Lihat [satu volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
