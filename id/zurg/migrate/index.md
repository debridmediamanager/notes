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

Anda tidak sedang memindahkan library. Anda sedang membangun ulang library. Dan `__magic__` memberi \*arr persis apa yang dulu diberikan symlink farm, tanpa farm-nya. Mereka tetap bisa memindah dan mengganti nama di dalamnya sebebas sebelumnya. Setiap pemindahan kini berupa penulisan baris, bukan operasi file.

!!!danger Jangan pernah biarkan \*arr memindahkan library lama ke dalam `__magic__`
Mengubah root folder series atau movie membuat Sonarr atau Radarr menawarkan untuk **memindahkan** file. Pilih tidak. Pemindahan di dalam `__magic__` gratis. Pemindahan dari tempat lain melintasi batas mount, dan itu berarti copy. Pemindahan antar dua volume dalam mount yang sama juga berarti copy. Di Docker, berikan satu volume untuk \*arr yang memuat seluruh mount milik zurg. Copy dari mount streaming akan menarik seluruh library Anda lewat jatah Usenet atau debrid Anda. Library lama Anda berupa pohon symlink, jadi yang ikut di-copy adalah setiap target yang ditunjuk symlink itu.
!!!

Pindahkan setiap file ke tempatnya sendiri. Setiap pemindahan adalah satu rename lewat mount milik zurg. Tidak ada yang di-copy dan tidak ada yang berubah di akun Anda. Script di bawah melakukannya dari library lama Anda yang berisi symlink. Path sebuah link di bawah root folder lama adalah tempat Sonarr atau Radarr mengharapkan episode atau film itu. Target-nya menyebut nama file. Jadi setiap file mendarat di path yang sama di bawah root folder baru seperti path link-nya di root folder lama. Library lama hanya dibaca. Library itu tetap berfungsi sampai Anda mengalihkan \*arr.

1. **Bangun zurg di samping server lama** seperti yang ditunjukkan halamannya. Biarkan zurg mendaftar seluruh library terlebih dahulu.
2. **Nyalakan `__magic__`** seperti yang ditunjukkan halamannya. Biarkan pemindaian Plex tetap mati dan antrean \*arr dijeda.
3. **Simpan fungsi `zurg_path` dari halaman server Anda** sebagai `zurg_path.sh` di samping script. Fungsi ini mengubah target sebuah link lama menjadi file yang disajikan zurg. Tiap server menata file-nya secara berbeda.
4. **Jalankan script** sekali untuk setiap root folder. Atur `OLD`, `NEW`, dan `LOG` untuk masing-masing. Setup dengan `sonarr4k` dan `radarr4k` di samping pasangan reguler membutuhkan empat kali jalan.

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

   Script mencetak satu baris untuk setiap link yang dibiarkannya.

   - `NOT IN ZURG` adalah link ke file yang tidak dimiliki zurg. NZB-nya tidak bisa dipulihkan, atau akunnya tidak ada di konfigurasi zurg.
   - `FAILED` adalah pemindahan yang ditolak zurg. Link kedua ke file yang sudah dipindahkan script akan mencetak ini setelah baris dari `mv` yang berbunyi `No such file or directory`. Sebuah file hanya bisa berada di satu path di `__magic__`. File itu tetap di tempat yang ditaruh link pertama.
   - `ALREADY THERE` adalah path yang sudah dimiliki root folder baru. Menjalankan script lagi akan melewati semua yang sudah ditempatkan sebelumnya.

5. **Alihkan setiap \*arr.** Pilih setiap series atau setiap movie, lalu edit bersamaan. Atur root folder ke yang baru di bawah `__magic__`. Saat ditanya apakah file akan dipindahkan, jawab **No, I'll Move the Files Myself**. Script sudah menaruh file-nya di sana. Lalu jalankan **Update All** agar \*arr menemukannya.
6. **Arahkan Plex ke root folder baru** dan ke tidak ada yang lain. Kotak berikutnya menjelaskan alasannya.

Setiap pemindahan memakan sekitar 15 milidetik pada library uji, dan tidak ada yang di-copy. Pantau `data/local` di dashboard `/magic/` milik zurg saat script berjalan. Angkanya hanya bertambah sebesar subtitle dan file kecil lain yang disalin script. Jika angkanya bertambah gigabyte, berarti ada sesuatu yang sedang di-copy. Berhenti dan periksa.

Link lama tetap berfungsi. File yang sudah dipindahkan tetap muncul di path `__all__` lamanya selain di path barunya. Build sebelum nightly 2026.10.04 menyembunyikannya dari path lama hingga 12 jam, padahal zurg tetap menyajikannya di sana. Pada build seperti itu, restart zurg sekali setelah script selesai. Jauhkan Plex dari folder lama dan dari `__all__` sampai Anda melakukannya.

Bagian zurg dari panduan ini diukur pada 2026-10-03. Bagian \*arr adalah edit root folder biasa dan tidak diuji untuk panduan ini. Coba satu series dulu.

!!!warning Arahkan setiap library Plex ke satu direktori, bukan dua
Library yang memindai direktori filter seperti `movies`, `shows`, atau `__all__` **dan** memindai `__magic__` akan menemukan setiap episode dua kali. `__magic__` juga memuat `__all__`-nya sendiri, jadi mengarahkan library ke root namespace berarti memindai seluruh library beserta yang sudah Anda atur. Pilih salah satu. Jika Anda memakai \*arr, arahkan Plex ke root folder yang Anda buat, yaitu `__magic__/tv` dan `__magic__/movies`. Jika Anda menelusuri library yang tidak diatur siapa pun, pilih direktori filter dan biarkan `__magic__` tidak dipakai.
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
