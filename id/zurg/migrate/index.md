# Bermigrasi ke zurg {#migrating-to-zurg}

Baca halaman ini dulu. Halaman ini berlaku untuk setiap migrasi dan isinya sebagian besar dari yang kamu perlukan. Halaman per-server dibuat singkat karena bagian yang sama ada di sini.

## Versi singkatnya {#the-short-version}

**zurg menerbitkan setiap file media yang diterbitkan server yang Anda tinggalkan, dan lebih banyak lagi.** Itu diukur pada 2026-09-01. Lima rilis yang sama dimasukkan ke kelima server, lalu mount-nya dibaca ulang dengan `tree`. Ini [perbandingan lengkapnya](https://github.com/debridmediamanager/usenet-streaming-benchmark). Satu-satunya yang zurg terbitkan *lebih sedikit* adalah parity par2. Plex tidak pernah mengubahnya menjadi item library.

Jadi **Anda tidak akan kehilangan konten.** Sebagian akan muncul dengan nama file yang berbeda. Itulah inti masalah di halaman ini. Plex mengikat item library ke path file. File di path baru berarti item baru.

Yang Anda korbankan bukan file-nya. Yang dikorbankan adalah **kurasi**.

| Tetap aman | Ikut hilang bersama item lama |
|---|---|
| Tanda sudah ditonton, jumlah putaran, posisi lanjut tonton | Keanggotaan Collections |
| Rating dari pengguna | Entri playlist (karena menyimpan item id) |
| File-nya sendiri | Poster, art, dan perbaikan match manual yang sudah dipilih |
| | `added_at`. Library Anda akan banjir di Recently Added |

Status tonton tetap aman karena `metadata_item_settings` diindeks berdasarkan akun dan GUID `plex://`, bukan berdasarkan path atau item id. Status itu akan terpasang lagi saat item baru cocok ke GUID yang sama. Kalau Plex salah match item yang ditambahkan ulang, status tonton tidak akan kembali. Cek beberapa item setelah scan pertama.

Anda bisa menghindari pengorbanan ini sepenuhnya, dengan konsekuensi lain. Tulis ulang `media_parts.file` di database Plex supaya baris-barisnya tidak pernah mati. Atau buat pohon shim symlink yang merekonstruksi setiap path lama di atas mount zurg. Dua cara ini bisa berhasil. Namun keduanya adalah operasi tidak resmi pada skema yang tidak terdokumentasi dan bisa berubah antarversi Plex. Penulisan ulang yang setengah jadi lebih buruk daripada dua hasil yang ingin dicegah.

Panduan-panduan ini mengambil jalan yang sederhana, dan memberi tahu Anda dengan jelas apa konsekuensinya.

## Pustakamu akan masuk ke `__magic__` dan bukan ke symlink farm {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

Setiap server di daftar ini memberikan library-nya ke \*arrs lewat banyak symlink. **zurg tidak melakukan itu, dan kamu sebaiknya tidak membuat ulang yang seperti itu.** zurg punya [`__magic__`](../guides/magic.md) sebagai gantinya. Itu satu-satunya direktori yang path-nya *disimpan*, bukan *dihitung*. Pemindahan di dalamnya cuma menulis ulang satu baris di tabel kecil. Tidak ada byte yang berpindah. Tidak ada yang disalin. Release tetap di tempatnya di akun. Arahkan Sonarr dan Radarr ke sana, dan mereka bebas mengatur serta mengganti nama sesuka hati tanpa biaya apa pun.

Itu bukan cuma satu bagian yang lebih sedikit. Itu lapisan yang tidak bisa rusak seperti lapisan lama. Symlink harus menunjuk ke path yang nyata. Target yang paling jelas adalah `__all__/<release>/<file>`, dan path itu *dihitung*. Path itu berubah saat release diganti namanya. Path itu berubah lagi saat dua release bentrok dan zurg menambahkan sufiks `{shorthash}` pada salah satunya. Setiap perubahan seperti itu diam-diam membuat link menggantung. Penempatan `__magic__` dikunci dengan hash konten release plus path file di dalamnya. Jadi ia tetap aman saat diganti namanya. Ia tetap aman saat ada sufiks `{shorthash}`. Ia juga tetap aman saat perbaikan menambahkan ulang release dengan id yang sama sekali baru.

Jadi, apa pun yang kamu pakai sekarang, **path-nya akan berubah dan library-nya harus ditambahkan ulang**. Ini berlaku untuk library symlink \*arr dan juga untuk Plex yang langsung diarahkan ke mount lama. Ini adalah trade-off yang disebut di atas, dan inilah seluruh biaya setiap migrasi di sini.

## Kondisi saat ini bergantung pada platform yang kamu pakai {#what-you-have-today-depends-on-your-platform}

Ini menentukan apakah tabel penggantian nama di halaman berikutnya menggambarkan pustaka Plex Anda atau hanya sumber tempat pustaka itu dibangun. Pastikan ini benar sebelum Anda membacanya.

### Linux dan macOS. \*arrs kamu sudah mengganti nama semuanya {#linux-and-macos-your-arrs-already-renamed-everything}

Strategi symlink adalah pengaturan yang terdokumentasi untuk keempat server di sini, dan strategi ini hanya ada di platform ini. Server menerbitkan `completed-symlinks/<category>/<release>/<file>.rclonelink`. Lalu `rclone mount
--links` mengubah setiap file itu menjadi symlink sungguhan. Lalu **Sonarr dan Radarr mengimpor dari farm itu ke pustaka di path yang mereka pilih.** Mount adalah sumbernya, bukan pustakanya.

Ada dua konsekuensinya.

- **Path yang dimiliki Plex adalah milik \*arr.** Selalu. Root folder, lalu folder series, lalu folder season. Tidak satu pun dari itu berisi nama release.
- **Nama file juga milik \*arr jika Anda membiarkan rename aktif.** Itulah yang disebut "Rename Episodes" dan "Rename Movies". Jika rename dimatikan, nama file adalah nama dari server sumber, dan tabel di halaman berikutnya menjelaskan persis apa yang Anda lihat.

Jadi jika Anda menjalankan \*arr dengan rename aktif, tabel rename per server **tidak** menjelaskan pustaka Anda. Tabel itu menjelaskan apa yang diterima \*arr saat impor. Hal itu tetap penting. Nama file sumber yang lebih baik berarti parse yang lebih baik, dan Anda akan segera melakukan impor ulang.

### Windows. Tidak ada lapisan symlink sama sekali {#windows-no-symlink-layer-at-all}

Farm symlink butuh `rclone mount --links`, dan itu tidak ada dalam setup Windows. Mount-nya berupa huruf drive lewat WinFsp, dan Plex serta \*arrs langsung mengarah ke sana. Jadi **Plex menampilkan nama file asli dari server**, dan tabel penggantian nama menjelaskan dengan tepat apa yang akan berubah. Halaman [setup Windows](../setup/windows.md) membahas huruf drive dan aturan sesinya.

Perintah shell di halaman per-server ditulis untuk Linux dan macOS (di macOS, baca `/mnt/zurg` sebagai `/Volumes/Zurg`). Di Windows, baca `/mnt/zurg` sebagai `Z:\`, hentikan server lama dengan cara apa pun Anda menjalankannya, dan buat folder serta pindahkan file di `__magic__` dengan perintah PowerShell di [panduan `__magic__`](../guides/magic.md).

### Berpindah dari pustaka symlink {#coming-off-a-symlink-library}

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never let an \*arr move the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr offer to **move**
the files. Say no. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. So is a move between two volumes of the same
mount. In Docker give the \*arr one volume that holds zurg's whole mount. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Move each file into place yourself instead. Every move is one rename through
zurg's mount. Nothing is copied and nothing on your account changes. The script
below does it from your old library of symlinks. A link's path under the old
root folder is where Sonarr or Radarr expects the episode or film. Its target
names the file. So each file lands at the same path under the new root folder
that its link had under the old one. The old library is only read. It keeps
working until you switch the \*arr over.

1. **Build zurg beside the old server** as its page shows. Let it list the
   whole library first.
2. **Turn on `__magic__`** as its page shows. Keep Plex scans off and the
   \*arr queues paused.
3. **Save the `zurg_path` function from your server's page** as
   `zurg_path.sh` beside the script. It turns an old link's target into the
   file zurg serves. Each server lays its files out differently.
4. **Run the script** once per root folder. Set `OLD` and `NEW` and `LOG` for
   each one. A setup with `sonarr4k` and `radarr4k` beside the regular pair
   needs four runs.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   It prints a line for every link it leaves alone.

   - `NOT IN ZURG` is a link to a file zurg does not have. Its NZB could not be
     recovered or its account is not in zurg's config.
   - `FAILED` is a move zurg refused. A second link to a file the script
     already moved prints this after a line from `mv` that says `No such file
     or directory`. A file can sit at only one path in `__magic__`. It stays
     where the first link put it.
   - `ALREADY THERE` is a path the new root folder already holds. Running the
     script again skips everything it placed before.

5. **Switch each \*arr over.** Select every series or every movie and edit them
   together. Set the root folder to the new one under `__magic__`. When it asks
   whether to move the files answer **No, I'll Move the Files Myself**. The
   script already put them there. Then run **Update All** so it finds them.
6. **Point Plex at the new root folders** and at nothing else. The next box
   says why.

Each move took about 15 milliseconds on a test library and nothing was copied.
Watch `data/local` on zurg's `/magic/` dashboard while the script runs. It
grows only by the subtitles and other small files the script copies. A number
that grows by gigabytes means something is being copied. Stop and look.

The old links keep working. A moved file still shows at its old `__all__` path
as well as at its new one. Builds before the 2026.10.04 nightly hid it at the
old path for up to 12 hours even though zurg still served it there. On one of
those builds restart zurg once the script is done. Keep Plex away from the old
folders and from `__all__` until you have.

The zurg side of this was measured on 2026-10-03. The \*arr side is its
ordinary root folder edit and was not tested for this guide. Do one series
first.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice — and `__magic__`
holds its own `__all__`, so pointing a library at the root of the namespace
scans the whole library along with what you organised. Pick one. If you use the
\*arrs then point Plex at the root folders you made, `__magic__/tv` and
`__magic__/movies`. If you browse a library nobody organises then pick the
filter directories and leave `__magic__` off.
!!!

## Satu pengaman yang tidak boleh kamu lewatkan {#the-one-guard-you-must-not-skip}

**`autoEmptyTrash` harus `0` sebelum kamu menyentuh apa pun.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Di Windows, di PowerShell:

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex melaporkan pengaturan ini sebagai `0` atau `false` saat dimatikan.

Plex menghapus secara lunak. Di `0`, item yang file-nya sudah tidak ada akan tetap di trash dan kembali jika file-nya muncul lagi. Di `1`, item langsung hilang permanen begitu scan mendeteksinya. Mount yang putus selama sepuluh detik saat scan bisa ikut menghapus seluruh library. Ini sudah pernah memakan puluhan ribu item.

Dengan panduan yang disederhanakan ini, pengaturan tersebut justru bekerja lebih keras dibanding sebelumnya, bukan lebih ringan. **Trash adalah tempat item lama kamu menunggu selagi kamu memeriksa item yang baru.** Kosongkan trash saat kamu sudah yakin, jangan sebelumnya. Langkah itulah yang membuat kehilangan data benar-benar terjadi, dan ini satu-satunya hal yang tidak bisa dibatalkan di semua panduan ini.

Selagi di sana, matikan **"Generate video preview thumbnails"** untuk library yang terdampak. Di streaming mount, setiap proses pembuatan thumbnail adalah pembacaan penuh rilis melalui kuota Usenet atau debrid kamu. Migrasi memberi Plex banyak item baru sekaligus.

## Yang didapat setiap migrasi {#what-every-migration-gains}

Dua di antaranya adalah file baru yang muncul di folder yang sudah dipindai Plex. Ada baiknya kamu tahu dulu supaya tidak kaget.

- **Klip sampel.** zurg adalah satu-satunya dari kelima tool ini yang menampilkan file sampel di dalam direktori `Sample/` pada rilis RAR. Plex mungkin mengambil `-sample.mp4` berukuran 9 MB sebagai extra atau sebagai versi kedua dari episode. Kalau kamu tidak mau itu terjadi, atur [`only_show_the_biggest_file: true`](../reference/config.md) pada direktori yang dipindai library media kamu.
- **File `.nfo`.** zurg adalah satu-satunya yang menyimpannya. File ini tidak berpengaruh pada agent default Plex. Agent XBMC dan NFO akan membacanya kalau kamu memakainya.
- **`thumbnail.jpg` dan iklan `.url`.** Tidak berpengaruh. `thumbnail.jpg` bukan nama file yang dipakai Plex untuk poster, dan file `.url` itu iklan dari poster tersebut.
- **Folder kosong** saat rantai arsip sebuah rilis terputus. Plex mengabaikan direktori yang tidak berisi media.
- **par2 dan sfv menghilang.** zurg menyembunyikannya dengan membaca isi file, bukan dari namanya. Plex tidak pernah mendata file ini, jadi tidak terlihat di library kamu. Ini hanya berpengaruh pada tool yang sebelumnya menelusuri file tersebut.

## Panduannya {#the-guides}

- [Dari AltMount](altmount.md). Hanya mengganti nama rilis arsip
- [Dari decypharr](decypharr.md). Mengganti nama rilis file tunggal dan arsip
- [Dari InfiniDysk](infinidysk.md). Mengganti nama rilis file tunggal dan arsip
- [Dari nzbdav](nzbdav.md). Tidak mengganti nama apa pun dan ini yang paling mudah dari kelima tool
- [Dari streamnzb](streamnzb.md). Tidak ada library yang perlu dimigrasi. zurg punya addon Stremio sendiri

Mau pindah dari Plex, bukan ke zurg? [Pindah dari Plex ke rex](../../rex/from-plex.md) tetap menggunakan zurg dan aplikasi Plex kamu, serta menjalankan rex di samping atau menggantikan server Plex kamu.

Perilaku penamaan di setiap halaman diukur pada 2026-09-01 menggunakan
kumpulan lima rilis. Build yang dipakai adalah zurg `bda7e3c3`, AltMount `0614008b`, InfiniDysk
`cd9b1205`, nzbdav `794948be`, dan decypharr `0dd1cbbd`. Build yang lebih lama
atau lebih baru mungkin memberi nama yang berbeda. Coba cek beberapa rilis di
folder library kamu sendiri sebelum mempercayai daftar pindai ulang secara utuh.
