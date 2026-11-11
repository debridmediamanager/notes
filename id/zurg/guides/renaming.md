# Mengganti nama rilis dan file {#renaming-releases-and-files}

Mount zurg hanya bisa diubah dengan satu cara: kamu bisa **mengganti nama** folder rilis atau file di dalamnya, di mana saja di library. Fitur ini aktif secara default. Tidak ada yang disalin, tidak ada yang diunduh, dan akun debrid tidak tersentuh. Nama baru disimpan di sebelah rilis dan menggantikan nama yang biasanya dihitung zurg.

Yang tidak bisa kamu lakukan adalah **memindahkan** apa pun. Mengganti nama dan memindahkan terlihat seperti gerakan yang sama di file manager, tapi zurg memperlakukannya sebagai dua hal yang berlawanan. Alasannya dijelaskan di [bagian terakhir](#why-a-move-is-refused-when-a-rename-is-not).

Untuk *layout* yang tersimpan, bukan *nama* yang tersimpan, seperti folder yang kamu atur atau \*arr yang mengimpor dengan cara memindahkan, lihat [`__magic__`](magic.md). Halaman ini hanya membahas nama saja.

## Mengganti nama lewat mount {#renaming-through-the-mount}

Rename di mount adalah WebDAV `MOVE` yang tujuannya hanya berbeda dari sumbernya di segmen path terakhir. rclone mengubah rename di mount (FUSE `rename(2)`, atau versi WinFsp-nya di Windows) menjadi persis seperti itu. Jadi `mv` atau `Rename-Item` di mount, rename di Finder, Explorer, atau file manager lain, dan klien WebDAV semuanya sampai ke handler yang sama.

+++ Linux and macOS

```bash
mv "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show.S01E01.mkv" \
   "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show - s01e01.mkv"
```

Di macOS, mount ada di `/Volumes/Zurg` kecuali kamu sudah mengubah `mount_path`.

+++ Windows

```powershell
Rename-Item -LiteralPath "Z:\shows\Show.S01.1080p.WEB-DL\Show.S01E01.mkv" -NewName "Show - s01e01.mkv"
```

+++

Dua level ini sama-sama bisa dipakai:

| Rename | Disimpan sebagai |
|---|---|
| A release folder | `Torrent.Rename` |
| A file inside a release | `File.Rename` |

Endpoint `/dav/` dan `/infuse/` menerima `MOVE`. `/http/` tidak. Itu cuma browser read-only dan membalas `405` di luar `__magic__`.

### Apa yang harus dipenuhi sebuah nama {#what-a-name-has-to-satisfy}

Nama baru diterima jika, setelah spasi di awal dan akhir dihapus, nama tidak kosong, tidak mengandung `/` atau `\`, sama dengan hasil `filepath.Clean` dari nama itu sendiri (yang juga menolak `.` dan `..`), dan untuk folder release, tidak bentrok dengan access key dari hash yang *berbeda*. Nama file harus unik di dalam release-nya sendiri.

| Hasil | Status |
|---|---|
| Berhasil diganti namanya | `201` |
| Nama kosong, ada separator di dalamnya, atau tujuan hanya menyebut folder | `400` |
| Nama sudah dipakai | `412` |
| Sumber tidak ditemukan | `404` |
| Di dalam arsip, atau ditolak (lihat di bawah) | `403` |

Mengganti nama file *di dalam arsip* tidak bisa dilakukan. Isi arsip dibuat otomatis dari arsipnya, jadi tidak ada tempat untuk menulis nama baru. zurg akan menolaknya dengan `403` yang menyebutkan files inside an archive cannot be renamed.

## Mengganti nama dari dashboard dan API {#renaming-from-the-dashboard-and-the-api}

Dua rename yang sama itu adalah endpoint `POST`, dan masing-masing punya reset yang sesuai untuk menghapus nama yang tersimpan dan mengembalikan rilis ke nama hasil hitungannya:

```
POST /manage/{torrentHash}/rename
POST /manage/{torrentHash}/clear-rename
POST /manage/{torrentHash}/files/{fileid}/rename
POST /manage/{torrentHash}/files/{fileid}/clear-rename
```

Tidak ada padanan `clear-rename` lewat mount. Rename kembali ke nama asli akan menyimpan nama itu, bukan menghapus override-nya.

### Perbaikan season {#the-season-fix}

`GET /torrents/season-fix/plan` dan `POST /torrents/season-fix/apply` adalah bulk file rename yang digerakkan oleh pencocokan episode milik Plex sendiri, untuk rilis yang file-nya dinomori dengan cara yang tidak bisa diurai oleh apa pun. Plan bersifat read-only dan memberi alasan skip per file. Apply menerima daftar hash yang eksplisit, bukan flag apply-everything, jadi kamu memastikan sendiri apa yang sudah kamu lihat.

## Apa yang tetap bertahan setelah ganti nama {#what-a-rename-survives}

Nama yang tersimpan ada pada rilis dan ikut diserialisasi ke dalam `.zurgtorrent`-nya, jadi nama itu tetap bertahan saat:

- **Library di-refresh**, termasuk refresh yang membangun ulang entri file rilis dari daftar milik provider.
- **Restart.**
- **Repair**, yang menambahkan ulang rilis berdasarkan hash dengan id baru.
- **Provider mengganti nama torrent di belakang layar**, seperti yang dilakukan Real-Debrid.

Nama itu juga ikut berpindah. `.zurgtorrent` yang diekspor membawa rename-nya, jadi [pustaka lokal](local-libraries.md) akan tiba dengan nama yang sudah kamu berikan.

Satu hal yang tidak bisa dipertahankan nama itu adalah `ignore_renames: true`, dan memang itulah fungsi key tersebut. zurg mengabaikan semua nama yang tersimpan, menampilkan nama yang dihitung, dan menolak rename baru lewat mount. Rename-nya tidak dihapus, hanya diabaikan, jadi begitu kamu mengembalikan key itu ke nilai semula, rename-nya muncul lagi.

## Apa yang ikut berubah di sekitarnya {#what-a-rename-changes-around-it}

A rename is a view, but several things are built from that view, and they are updated with it:

- **The mount.** rclone's directory cache is invalidated for the old and the new path, so the change shows up without waiting out the cache.
- **`.strm` files**, if `save_strm_files` is on. The old ones are deleted and written again under the new name.
- **Plex dan Jellyfin** diminta untuk memeriksa rilis itu lagi.
- **The on-disk cache record.** The `.zurgtorrent` is written under the new name and the old file is deleted. That deletion matters: left behind, a restart loads both, the hash collision resolves back to the other copy, and the rename silently reverts. That was a real bug, seen on 2026-08-17.
- **The SABnzbd and qBittorrent endpoints**, which recompute the folder they report to Sonarr and Radarr on every poll, so a rename mid-import moves the path they are told to import from rather than stranding them.

## Tiga jebakan {#three-traps}

**Mengganti nama bisa memindahkan sebuah release saat refresh berikutnya.** Keanggotaan direktori ditentukan dengan menjalankan filter `directories:` pada nama release, dan filter itu membaca *nama yang sudah diganti*. Proses rename sengaja tidak mengevaluasi ulang filter tersebut. Release tetap berada di direktori yang sudah ada. Tapi refresh berikutnya akan melakukannya. Jadi, jika sebuah filter cocok dengan sesuatu di dalam nama, lalu nama barumu tidak lagi cocok, release itu akan pindah ke direktori lain nanti, tanpa ada tanda apa pun saat rename dilakukan. Saat mengganti nama, berhati-hatilah terhadap filter yang bergantung pada nama.

**Mengubah ekstensi berarti mengubah jenis file.** Tidak ada yang mencegah `episode.mkv` menjadi `episode.txt`; hanya pemisah path yang ditolak. Tapi keterlihatan file dinilai dari nama yang dilihat client, jadi file yang sudah diganti namanya bisa hilang dari `only_show_the_biggest_file`, dari logika file yang bisa diputar, dan dari pemindaian media server.

**URL `.strm` yang sudah diberikan ke aplikasi lain akan rusak.** Token bertanda tangan menyimpan access key dan nama file, jadi URL yang sudah disalin sebelum rename tidak akan mengarah ke mana pun setelahnya dan akan merespons `404`. Pohon `.strm` milik zurg sendiri akan ditulis ulang, tetapi apa pun yang sudah menyalin URL dari situ tidak.

## Mematikannya {#turning-it-off}

| Key | Default | Effect |
|---|---|---|
| `dav_allow_rename` | `true` | `false` menolak `MOVE` pada mount dengan `403`, dan menyebut key ini di body |
| `ignore_renames` | `false` | `true` mengabaikan semua rename yang tersimpan, menyajikan nama yang dihitung, dan menolak rename baru lewat mount dengan `403` |
| `mount_read_only` | `false` | `true` menjalankan rclone dengan `--read-only`, jadi kernel menolak penulisan sebelum zurg melihatnya |

`dav_allow_rename` hanya berlaku untuk mount. Key ini tidak membatasi endpoint dashboard,
dan tidak membatasi penulisan di bawah `__magic__`, karena folder itu tidak terhubung ke akun debrid mana pun.
Mirror adalah satu pengecualian, dan bukan karena key ini: `__magic__/__all__`
dan folder rilis yang langsung ada di dalamnya adalah layout asli library,
jadi penulisan ke salah satu dari itu akan ditolak apa pun nilai key ini. Di dalam folder rilis, aturannya kembali normal.
`mount_read_only` berlaku di atas semua hal, di level kernel, dan juga satu-satunya cara untuk menghentikan `DELETE` pada mount. Lihat [config.md](../reference/config.md) untuk alasan kenapa itu lebih penting daripada rename.

## Mengapa pemindahan ditolak sedangkan ganti nama tidak {#why-a-move-is-refused-when-a-rename-is-not}

| Percobaan | Status |
|---|---|
| Memindahkan folder rilis ke direktori lain | `403` |
| Memindahkan file ke rilis lain | `403` |
| Memindahkan file ke subfolder di dalam rilisnya sendiri | `400` |
| Men-rename atau memindahkan direktori level atas | `405` |
| Memindahkan apa pun keluar dari `__magic__` | `403` |
| Menulis di `__magic__/__all__`, atau di nama yang langsung ada di dalamnya | `403` |

Aturan dasarnya selalu sama: **rename punya tempat untuk disimpan, sedangkan move tidak.**

Nama rilis adalah satu string di rilis itu, jadi menulis nama baru cukup dengan mengubah field, dan setiap lookup berikutnya akan membacanya kembali. Tapi direktori level atas bukan folder, melainkan saved filter, dan isinya dihitung ulang dari config `directories:` setiap kali refresh. Memindahkan rilis "ke" `movies` tidak akan menulis apa-apa, karena tidak ada yang membaca jawaban tersimpan untuk pertanyaan itu. Refresh berikutnya akan menghitung ulang isinya dari filter dan membatalkan perubahan tadi. Menolak adalah jawaban yang jujur. Hal yang sama berlaku untuk subfolder di dalam rilis, karena bentuknya berasal dari daftar file milik akun itu sendiri.

`__magic__` ada karena layout yang tersimpan memang sangat berguna, dan ia menyelesaikan masalah penyimpanan alih-alih berpura-pura masalahnya tidak ada. Move di dalamnya menulis satu baris ke tabel kecil yang dikunci dengan content hash, sehingga tetap bertahan ketika repair menambahkan lagi rilis itu dengan id baru. Tabel itu sengaja dibatasi hanya untuk satu namespace.

Ada alasan kedua untuk tidak memperluas daftar penolakan begitu saja. [rclone-move-refusal.md](../internals/rclone-move-refusal.md) mendokumentasikan apa yang terjadi pada `MOVE` yang ditolak jika client tidak menyangkanya: di rclone 1.72.0, entry VFS dibiarkan menunjuk ke tujuan yang dicoba, dan client yang kembali ke copy lalu delete membaca EOF dan melaporkan sukses, sehingga menghasilkan file berukuran nol yang dia kira sudah ditulis. Setiap penolakan di atas adalah penolakan yang harus bisa ditangani oleh sistem.
