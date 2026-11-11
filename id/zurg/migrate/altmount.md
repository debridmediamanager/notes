# Bermigrasi dari AltMount ke zurg {#migrating-from-altmount-to-zurg}

Baca dulu [halaman bersama](index.md). Di sana dijelaskan trash guard dan alasan library kamu masuk ke `__magic__`.

AltMount menyajikan pohon file yang paling bersih dari kelimanya. Tepat satu file per rilis. Tidak ada thumbnail, tidak ada iklan, tidak ada sampel, dan tidak ada sisa file. Migrasinya juga jadi jauh lebih kecil, karena memang tidak banyak yang perlu dipermasalahkan.

Dibandingkan dengan zurg pada lima rilis yang sama.

| | |
|---|---|
| zurg menambahkan | klip sampel, `.nfo`, `thumbnail.jpg`, iklan `.url`, direktori dalam arsip, **dan setiap rilis yang ditolak AltMount** |
| zurg kehilangan | tidak ada |
| diganti nama | **hanya rilis arsip (RAR)** |

!!!info Hanya jalur arsip yang mengganti nama
Pada tiga kali uji terpisah dengan build `0614008b`, rilis berkas tunggal biasa tetap memakai nama file dari pengunggah. Termasuk satu rilis yang nama di dalamnya berbeda dari nama NZB, dan satu rilis yang sepenuhnya terobfuskasi. Hanya rilis yang harus diekstrak dari RAR yang berakhir sebagai `<NZB name>.mp4`.

Build AltMount yang lebih lama mengganti nama lebih banyak dari ini. Periksa pohon file kamu sendiri sebelum mempercayai daftar di bawah. Satu perintah di bagian "What your library looks like afterwards" memberi tahumu hasilnya dalam hitungan detik.
!!!

## Masalah yang lebih besar adalah apa yang tidak pernah diimpor AltMount {#the-bigger-issue-is-what-altmount-never-imported}

AltMount menolak season pack 10 episode di keempat percobaan. Sebelumnya, artikelnya sudah diverifikasi ada di news server.

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

Pemeriksaannya tidak deterministik. Rilis yang sama pernah menghasilkan 196 segmen yang tidak terverifikasi, lalu 93, lalu 76. Pemeriksaannya juga bias terhadap ukuran. Mengatur `import.segment_sample_percentage: 1` mengambil sampel 1% dari segmen, jadi rilis yang lebih besar butuh lebih banyak STAT agar selesai sebelum batas waktu. Saat diulang di news host yang *lebih cepat*, malah lebih banyak yang ditolak, bukan lebih sedikit. Run itu kehilangan season pack sekaligus remux 41 GB. Latensi bukan penjelasannya.

Konsekuensinya untuk kamu begini. **Rilis yang diam-diam tidak pernah dipublikasikan oleh AltMount justru yang akan ditambahkan zurg.** Rilis itu belum punya item di Plex sekarang, jadi tidak ada yang tersimpan dan tidak ada yang terancam. Rilis itu tinggal muncul. Kalau library kamu lebih kecil dari koleksi NZB kamu, inilah alasannya.

Kalau kamu ingin AltMount tetap mengimpor selama kamu pindah, menurunkan `segment_sample_percentage` adalah pengaturan yang bisa dicoba. Itu belum diuji di sini.

## Seperti apa library kamu setelahnya {#what-your-library-looks-like-afterwards}

**Semuanya ditambahkan ulang** karena root library pindah ke `__magic__`. Lihat [halaman bersama](index.md) untuk alasan kenapa tidak ada jalan yang lebih murah.

Yang berubah di tengah jalan sebenarnya kecil. Rilis single-file biasa tetap memakai nama file yang diberikan AltMount, jadi sebagian besar library tetap terbaca sama. **Rilis archive kembali dengan nama poster-nya** dan satu folder lebih dalam. Itu jelas lebih baik untuk sebuah \*arr. Nama `father.brown.2013.s02e05.hdtv.x264-tla.mp4` memuat kualitas, sumber, dan grup yang dibuang oleh `FatherBrown.mp4`.

Untuk menemukan rilis archive, cari folder mount yang file tunggalnya bernama sama dengan folder itu.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

!!!info Apakah kamu melihat semua ini tergantung setup kamu
Jika Plex membaca mount secara langsung, nama-nama di atas adalah yang berubah di library kamu. Itu berlaku untuk setiap setup Windows dan setiap setup Linux atau macOS yang tidak memakai symlink farm \*arr.

Jika Sonarr dan Radarr mengatur library symlink dengan renaming aktif, maka **nama file kamu sudah mengikuti mereka** dan tidak ada nama di atas yang muncul di Plex. Nama-nama itu lalu memberi tahu seberapa bagus parse yang dipakai \*arr. Itu penting saat kamu melakukan import ulang. Lihat [halaman bersama](index.md).
!!!

## Konten baru apa yang muncul {#what-new-content-shows-up}

AltMount tidak menerbitkan semua ini, jadi semua yang ada di daftar halaman bersama berlaku untuk Anda.

- **Sample clip** di dalam `Sample/`. Ini satu-satunya yang layak dikonfigurasi. Atur [`only_show_the_biggest_file: true`](../reference/config.md) jika Anda tidak ingin sample 9 MB muncul sebagai versi kedua.
- `thumbnail.jpg`, `.nfo`, dan file `.url` poster. Semuanya tidak berpengaruh.
- **Seluruh rilis yang ditolak AltMount** muncul sebagai item baru di library.
- Folder kosong jika rantai arsip terputus.

## Keluarkan NZB kamu {#get-your-nzbs-out}

AltMount mengambil alih setiap NZB yang kamu masukkan ke sana. File aslinya dipindahkan, dan salinan terkompresinya disimpan di `<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. Pemetaan dari folder mount ke `.nzbz` ada di file `.meta` di bawah `<config>/metadata/complete/<Release>/`. File itu berformat biner dengan magic `AM3`, dan path `.nzbz` tersimpan di dalamnya sebagai string biasa.

zurg maunya satu `.nzb` per rilis, dinamai sesuai nama rilisnya, dan ditaruh langsung di `nzbs/` tanpa subfolder. Subfolder akan dilewati. Nama direktori `metadata/complete/<Release>` *adalah* nama folder mount, dan itulah nama persis yang harus dimiliki filenya.

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

Pada instalasi v0.3.2 yang sudah kami ukur, `.nzbz` ternyata hasil dekompresi berupa salinan gzip dari NZB yang diimpor. Source code-nya juga punya jalur zstd-protobuf untuk file-file ini, jadi mengecek pakai `zcat` dan `grep` itu bukan hal yang berlebihan. File yang ditolak akan diproses lewat API. `GET /api/files/export-nzb?path=<virtual path>` membuat ulang NZB yang akurat dari store, dan `POST /api/files/export-batch` mengembalikan ZIP. Keduanya butuh JWT, bukan API key.

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

Ambil virtual path dari tampilan file di UI AltMount atau dari `/api/files/info`, jangan menebak formatnya. Hasil unduhannya bernama `<queueID>-<name>.nzb`. Ganti namanya jadi `<Release>.nzb` supaya zurg menamai foldernya dengan benar.

Satu pengecekan kewarasan: jumlah `.nzb` yang berhasil dipulihkan harus sama dengan jumlah direktori `metadata/complete/*/`.

## Bangun zurg berdampingan {#build-zurg-alongside}

AltMount tetap melayani terus. Jalankan zurg di port 9999. Tidak ada bentrok
dengan port 8585 milik AltMount.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

Siap-siap, di sini bakal ada **lebih banyak** folder dibanding yang dulu ada di AltMount. Itu tandanya kelas refused-import mulai masuk.

## Pindah sepenuhnya {#cut-over}

Satu jalur saja untuk apa pun yang kamu punya sekarang. Tidak ada yang memindahkan byte di sini.

**1. Nyalakan `__magic__`** lalu restart. Rute didaftarkan saat startup, jadi toggle di dashboard perlu restart dulu sebelum namespace merespons.

```yaml
magic:
  enabled: true
```

**2. Buat root folder.** Letakkan di root `__magic__`, sejajar dengan `__all__` yang tetap dipakai zurg di sana. Bukan `__magic__/__all__`, bukan `__magic__` itu sendiri, dan bukan root mount. Kedua \*arr akan memunculkan health check untuk folder-folder itu. Folder sejajar tidak memicu keduanya.

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

**Kalau Sonarr dan Radarr yang mengatur library lama kamu, pindahkan dengan satu script.** Script ini mengganti nama setiap file yang ditunjuk library lama ke root folder baru di bawah `__magic__`. Setiap file mendarat di path yang sudah diharapkan \*arr. Tidak ada yang disalin. Lalu kamu ganti root folder \*arr tanpa membiarkannya memindahkan apa pun. Langkah dan script-nya ada di [halaman bersama](index.md#coming-off-a-symlink-library). Jangan pernah biarkan \*arr memindahkan file sendiri. Itu melewati batas mount. Artinya itu menyalin dan akan mengunduh ulang library kamu.

Script butuh fungsi `zurg_path` untuk link AltMount. Simpan ini sebagai `zurg_path.sh` di sebelahnya dan atur `OLDMOUNT` ke lokasi mount AltMount kamu.

```bash
OLDMOUNT=/mnt/altmount          # AltMount's mount, where the old links point
zurg_path() {
  case "$1" in "$OLDMOUNT"/*) ;; *) return ;; esac   # not a link into AltMount
  local name=${1##*/} f videos
  local release; release=$(basename "$(dirname "$1")")
  [ -f "$ZURG/__all__/$release/$name" ] && { echo "$ZURG/__all__/$release/$name"; return; }
  # AltMount named a lone video or an unpacked archive after the release. Take its one video.
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Fungsi ini mengharapkan folder rilis tepat di atas file pada target setiap link. Path persis yang dipakai link AltMount belum diperiksa untuk panduan ini. Jalankan `readlink` pada salah satu link dulu. Kalau AltMount memberi nama video tunggal atau arsip yang sudah di-unpack sesuai nama rilis, fungsi mengambil satu video yang disajikan zurg di rilis itu. Rilis dengan lebih dari satu video tidak pernah ditebak. Fungsi akan mencetak `NOT IN ZURG` sebagai gantinya.

**4. Arahkan Plex ke root folder yang kamu buat**, yaitu `__magic__/tv` dan `__magic__/movies`, dan hanya ke itu. Jangan pernah ke root `__magic__`, yang juga berisi seluruh library di `__magic__/__all__`. Dan jangan pernah ke `__magic__` *dan* sebuah direktori filter, atau setiap episode akan ditemukan dua kali. Pastikan `autoEmptyTrash` bernilai `0`. Tambahkan lokasi baru lalu scan. Setelah itu hapus yang lama. Itu adalah path library \*arr kamu, atau mount AltMount kalau Plex membacanya langsung.

**5. Kosongkan trash** setelah kamu memeriksa beberapa item secara acak. State tontonan kembali lewat pencocokan GUID. Koleksi dan pilihan artwork tidak.

```bash
sudo systemctl stop altmount
```

Biarkan AltMount berjalan sampai saat itu. Tidak ada biayanya dan itu jalur rollback kamu. Setelah selesai, hentikan.

## Setelahnya {#afterwards}

Jangan hentikan AltMount sebelum kamu sudah stream dari sampel yang mewakili. Folder config-nya menyimpan store `.nzbz`, dan itu satu-satunya salinan NZB kamu yang lain.

Sekarang soal akuisisi. zurg punya [endpoint kompatibel SABnzbd](../guides/sonarr-radarr.md) opt-in yang bisa dipakai Sonarr dan Radarr untuk grab. Endpoint ini menggantikan AltMount sebagai download client mereka. zurg memeriksa setiap grab sebelum melaporkannya selesai. Ia menanyakan news server tentang awal dan akhir setiap file. Ia juga mengunduh artikel pertama dari setiap file. Jumlahnya bisa sampai enam puluh empat, ditambah beberapa lagi untuk rilis dengan sedikit file. Beberapa news server masih bilang sebuah artikel ada padahal isinya sudah dihapus, dan hanya unduhan yang bisa menunjukkan itu. zurg membangun ulang rilis dengan artikel yang hilang dari file PAR2-nya jika memungkinkan. Rilis yang tidak bisa dibangun ulang akan dilaporkan sebagai **Failed**. Lalu \*arr akan memasukkannya ke blocklist dan grab rilis lain. Pemeriksaannya hanya sampel, bukan seluruh post. Post yang kehilangan bagian yang tidak tercakup sampel tetap dilaporkan Completed, dan baru gagal saat pembacaan mengenai celah itu. Simpan root folder \*arr di dalam `__magic__`. Root folder di tempat lain akan menyalin setiap impor secara penuh. Di Docker, berikan satu volume untuk \*arr yang memuat seluruh mount zurg. Download folder dan root folder di dua volume juga akan menyalin setiap impor. Lihat [satu volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
