# Bermigrasi dari nzbdav ke zurg {#migrating-from-nzbdav-to-zurg}

Baca [halaman bersama](index.md) dulu. Di situ dijelaskan soal trash guard dan kenapa library kamu masuk ke `__magic__`.

nzbdav-dev merilis versi terakhir v0.6.4 pada April 2026, dan repositori upstream-nya sudah tidak dikelola lagi.
Rilis itu tetap berfungsi. Migrasi ini tentang pindah dari software yang tidak dikelola lagi. Tidak perlu terburu-buru.

**Ini migrasi paling mudah dari lima migrasi yang ada.** Dibandingkan dengan zurg pada lima rilis yang sama, pohon file nzbdav hanya berbeda dalam dua hal.

| | |
|---|---|
| zurg mendapatkan | file `.nfo` dari rilis |
| zurg kehilangan | 5 volume par2 bernama hash di dalam rilis yang diobfuskasi |

**Tidak ada yang diganti namanya.** Setiap nama file yang disajikan nzbdav juga disajikan zurg dengan nama yang sama dan bentuk direktori yang sama. Hal ini juga berlaku di dalam arsip RAR. Kedua server sepakat soal semua 20 file non-par2 dalam korpus.

!!!warning Jangan pernah menelusuri root WebDAV
Object store `.ids` milik nzbdav membuat semua 16 anak hex di setiap dari lima level-nya, tidak peduli isinya. Artinya 16^5 atau sekitar 1.048.576 direktori. Arahkan `find`, `du`, `rclone`, dan scanner apa pun secara eksplisit ke `/content`, `/nzbs`, atau `/completed-symlinks`. Jangan pernah ke `/`.
!!!

## Seperti apa library kamu setelahnya {#what-your-library-looks-like-afterwards}

**Semua harus ditambahkan ulang** karena root library pindah ke `__magic__`.
Tidak ada jalur yang lebih murah dan tidak ada jalur parsial. Lihat [halaman bersama](index.md)
untuk alasannya.

Kabar baiknya, nzbdav adalah satu-satunya migrasi di mana **tidak ada yang kamu lihat berubah selain prefix-nya**. Setiap nama file yang disajikan zurg sama dengan yang dulu disajikan nzbdav. Sebuah \*arr yang melakukan impor ulang dari `__magic__` akan mem-parsing persis apa yang dulu di-parse.
Folder yang kamu atur sendiri tetap terlihat sama seperti biasanya.

Itu berlaku apa pun setup kamu. Di Windows dan di tempat lain di mana Plex membaca mount secara langsung, nama filenya identik. Jika Sonarr dan Radarr mengatur library symlink, nama filenya memang sudah dari mereka sejak awal dan sumber yang mereka parse tidak berubah. Jadi migrasi ini tidak mengubah cara library kamu dibaca. Ia hanya mengubah di mana library itu disimpan.

## Konten baru apa yang muncul {#what-new-content-shows-up}

- `.nfo` di dalam rilis RAR.
- **Klip sampel** di dalam `Sample/`. nzbdav menampilkan direktorinya dan klipnya, begitu juga zurg. Yang ini *bukan* hal baru buat kamu. nzbdav adalah satu-satunya dari empat server yang sudah menampilkannya.
- Folder kosong untuk rilis yang rantai arsipnya rusak. nzbdav tidak membuat apa-apa untuk rilis itu.
- File par2 dan sfv tidak lagi terlihat.

Tidak ada satu pun dari itu yang menghasilkan item Plex, kecuali klip sampel, dan nzbdav sudah memberikannya kepada kamu. Kalau sebelumnya itu tidak mengganggu kamu, berarti tidak ada yang berubah.

## Keluarkan NZB kamu {#get-your-nzbs-out}

zurg mendapat input dari sebuah direktori berisi file `.nzb`, dan nzbdav masih menyimpan semua milikmu di `/nzbs/<category>/`.
**Salin. Jangan pindahkan.** Menghapus dari `/nzbs/` akan membatalkan job.

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

Kedua server memberi nama folder rilis sesuai *nama file* NZB. Jadi stem yang kamu dapatkan kembali seharusnya sama dengan folder yang disajikan nzbdav. Periksa itu dan ganti nama yang tidak cocok.

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

Ada dua aturan penamaan zurg yang perlu dicek terhadap daftar itu.

- zurg menghapus `.mkv` atau `.mp4` di akhir nama folder. Jika ada stem yang berakhir seperti itu, atur `retain_folder_name_extension: true`.
- Dua rilis berbeda yang memakai stem sama akan mendapat sufiks ` {shorthash}` pada salah satunya. Cari sekarang dengan `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`.

## Bangun zurg berdampingan {#build-zurg-alongside}

nzbdav tetap melayani selama proses ini. Salin blok provider-nya ke config zurg.
Beri zurg mountpoint sendiri. Masukkan NZB-nya ke folder, lalu biarkan zurg memindainya. Direktori watch dibaca sekitar setiap 15 detik.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from nzbdav's provider settings
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
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l     # should approach your release count
```

## Pindah sepenuhnya {#cut-over}

Satu jalur, apa pun yang kamu punya sekarang. Tidak ada langkah di sini yang memindahkan byte.

**1. Aktifkan `__magic__`** lalu restart. Rute-rutenya didaftarkan saat startup, jadi toggle di dashboard butuh restart dulu sebelum namespace-nya bisa merespons.

```yaml
magic:
  enabled: true
```

**2. Buat root folder.** Folder ini harus berada di root `__magic__`, sejajar dengan `__all__` yang disimpan zurg di sana. Bukan `__magic__/__all__`, bukan `__magic__` itu sendiri, dan bukan mount root. Kedua \*arr akan memunculkan health check untuk folder-folder itu; folder sejajar tidak memicunya.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` mencerminkan library sehingga setiap rilis sudah ada sebelum kamu mulai mengatur apa pun.

**3. Atur filenya.** `mv` di dalam `__magic__` hanya menulis satu baris dan tidak memindahkan byte.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Kalau Sonarr dan Radarr sudah mengatur library lama kamu, pindahkan dengan satu script.** Script ini mengganti nama setiap file yang ditunjuk library lama ke dalam root folder baru di bawah `__magic__`. Setiap file akan berada di path yang sudah diharapkan \*arr. Tidak ada yang disalin. Lalu ganti root folder \*arr-nya tanpa membiarkannya memindahkan apa pun. Langkah-langkah dan script-nya ada di [halaman bersama](index.md#coming-off-a-symlink-library). Jangan pernah biarkan \*arr memindahkan file sendiri. Itu melewati batas mount. Itu akan jadi penyalinan dan akan mengunduh ulang library kamu.

Script ini butuh fungsi `zurg_path` untuk link nzbdav. Simpan ini sebagai `zurg_path.sh` di sebelahnya dan atur `OLDMOUNT` ke lokasi tempat nzbdav di-mount.

```bash
OLDMOUNT=/mnt/nzbdav            # nzbdav's mount, where the old links point
# The map from each .ids name to its release and file. Built once while nzbdav runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # A file under another name. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Link nzbdav menunjuk ke store `.ids`-nya, dan zurg tidak punya hal seperti itu. Jadi fungsi ini membaca tree `completed-symlinks` milik nzbdav sekali saja untuk mengetahui rilis dan file mana yang diwakili setiap nama `.ids`. Biarkan nzbdav tetap jalan sampai script selesai. nzbdav tidak mengganti nama apa pun, jadi setiap nama yang ditemukannya adalah nama yang juga dilayani zurg.

**4. Arahkan Plex ke root folder yang sudah kamu buat** — `__magic__/tv` dan `__magic__/movies` — dan hanya ke situ saja. Jangan pernah root `__magic__`, karena di sana juga ada seluruh library di `__magic__/__all__`, dan jangan pernah `__magic__` *dan* sebuah filter directory sekaligus, atau setiap episode akan terdeteksi dua kali. Pastikan `autoEmptyTrash` bernilai `0`. Tambahkan lokasi baru dan scan. Lalu hapus yang lama. Itu adalah path library \*arr kamu, atau mount nzbdav kalau Plex membacanya langsung.

**5. Kosongkan trash** setelah kamu mengecek beberapa item secara acak. Status tontonan kembali lewat pencocokan GUID. Koleksi dan pilihan artwork tidak.

Biarkan nzbdav tetap jalan sampai saat itu. Tidak ada biayanya dan itu jadi rollback kamu. Setelah selesai, hentikan.

```bash
sudo systemctl stop nzbdav
```

## Setelahnya {#afterwards}

Simpan folder config nzbdav sampai kamu sudah melakukan streaming dari sampel yang representatif. Itu satu-satunya salinan lain dari NZB kamu.

Sekarang, pikirkan soal cara mengambil file. zurg punya [endpoint yang kompatibel dengan SABnzbd](../guides/sonarr-radarr.md) yang bisa diaktifkan secara opsional, dan Sonarr serta Radarr bisa mengambil file lewat endpoint itu. Endpoint ini menggantikan nzbdav sebagai download client mereka. Hasil ambil file masuk ke `__magic__/__all__`, lalu proses import memindahkannya keluar dengan cara rename. Tidak ada yang disalin.

zurg memeriksa setiap hasil ambil file sebelum melaporkannya selesai. Ia bertanya ke server news tentang awal dan akhir setiap file. Ia juga mengunduh artikel pertama dari setiap file. Itu bisa sampai enam puluh empat artikel, ditambah beberapa lagi untuk rilis yang hanya punya sedikit file. Beberapa server news masih bilang sebuah artikel ada padahal isinya sudah dihapus, dan hanya unduhan yang bisa menunjukkan itu. zurg membangun ulang rilis yang artikelnya hilang dari file PAR2 jika memungkinkan. Rilis yang tidak bisa dibangun ulang akan dilaporkan **Failed**. Lalu \*arr memasukkannya ke blocklist dan mengambil rilis lain.

Pemeriksaan ini hanya sampel, bukan seluruh post. Post yang kehilangan bagian yang tidak tercakup sampel tetap dilaporkan Completed, dan akan gagal saat pembacaan yang mengenai celah tersebut.

Pastikan root folder \*arr berada di dalam `__magic__`. Root folder di tempat lain akan membuat salinan penuh setiap import. Di Docker, berikan \*arr satu volume yang berisi seluruh mount zurg. Download folder dan root folder di dua volume terpisah juga akan menyalin setiap import. Lihat [satu volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
