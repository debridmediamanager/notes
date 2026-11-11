# Cache baca yang persisten {#persistent-read-caches}

Entri NZB yang diimpor, Real-Debrid, AllDebrid, dan TorBox semuanya menyimpan status library mereka di `data/*.zurgtorrent`. File-file ini menjelaskan isi library. Cache persiapan baca dan cache byte disimpan di sebelahnya, jadi saat cache turunan diubah atau dibersihkan, library tidak ditulis ulang dan tag, nama, serta asosiasi akun tidak hilang.

## Apa yang tetap ada setelah restart {#what-survives-a-restart}

| Cache | Lokasi | Pekerjaan yang dihindari |
| --- | --- | --- |
| Manifest dokumen NZB | `data/nzb-manifests/` | Mengurai ulang XML yang tidak berubah untuk nama, ukuran, klasifikasi recovery, password, dan jumlah segmen |
| Indeks artikel NZB | `data/nzb-index/` | Membangun ulang referensi artikel; dipakai oleh mode `mmap` dan `resident` |
| Artikel Usenet yang sudah di-decode | `data/bytecache/articles/` | Mengambil dan yEnc-decode artikel yang sudah pernah dibaca |
| Layout arsip | `data/archive-layouts/` | Membaca ulang header arsip untuk membangun ulang rentang volume, entri bertingkat, dan offset ZIP yang sudah dipelajari |
| Blok arsip yang sudah di-decompress | `data/bytecache/decoded/` | Men-decode ulang untuk mencapai rentang byte yang tersimpan setelah restart atau backward seek |
| State provider | `data/provider-cache/` | Membangun ulang jendela unduhan RD yang tidak berubah atau mengambil tabel region TorBox yang baru |
| Link pengiriman | `data/linkcache/` | Me-resolve URL yang masih valid lagi |

Layout arsip mendukung entri RAR/ZIP yang disimpan maupun dikompres, sumber bertingkat, span terenkripsi, dan arsip split yang didukung. Layout hanya menyimpan referensi sumber dan offset, bukan pembaca HTTP yang aktif. URL provider saat ini dipasang saat restore. Layout yang tidak lengkap karena volume hilang dibangun ulang dari sumber. Offset payload ZIP yang sudah dipelajari disimpan setelah pembacaan pertama, tanpa mengambil header setiap entri saat daftar direktori ditampilkan.

Manifest NZB dicek terhadap ukuran file sumber, waktu modifikasi dalam nanodetik, dan versi parser. `mmap` memulihkan metadata secara langsung dan memetakan indeks artikel saat dibutuhkan. `resident` memuat indeks itu ke memori heap. `reparse` memulihkan metadata secara langsung, tetapi tetap mengurai XML saat referensi artikel dibutuhkan. Library yang sudah ada akan membangun manifest saat scan pertama dengan versi ini; penyimpanan saat startup berlaku pada scan dan restart berikutnya.

Permintaan bersamaan untuk akun/file yang belum di-cache di AllDebrid dan TorBox sekarang berbagi satu resolusi. Membatalkan satu pemanggil tidak membatalkan resolusi milik pemanggil lain. RD tetap memakai coalescing yang sudah ada. TorBox memakai nama dan ukuran katalog yang sudah diketahui saat me-resolve file, sehingga tidak perlu mengambil detail itu lagi.

Record detail provider di `data/info/` di-memoize setelah JSON pertama kali di-decode per proses. Setiap penggunaan ulang memeriksa identitas file, ukuran, dan waktu modifikasi, lalu mengembalikan salinan yang independen. File library dan detail diganti secara atomik.

## Batas penyimpanan {#storage-budgets}

```yaml
nzb_article_disk_cache_mb: 512
archive_decoded_disk_cache_mb: 512
```

Pengaturan tingkat atas opsional ini diukur dalam MiB dan baru berlaku setelah
restart:

Setiap cache defaultnya 512 MiB untuk seluruh instance. Nilai nol akan mematikan cache tersebut;
nilai negatif dianggap nol. Budget ini menghitung byte record termasuk checksum, bukan
overhead alokasi filesystem. Record yang paling lama tidak dipakai akan dihapus saat record baru masuk.
Mengurangi budget akan memangkas cache yang sudah ada saat inisialisasi. Jika dimatikan, file yang ada tetap bisa dihapus secara manual.

Cache artikel melengkapi cache RAM yang sudah ada. Cache archive menyimpan blok terdekode 64 KiB
dan melengkapi jendela RAM bergulir 64 MiB milik setiap decoder. Tidak ada cache yang mengunduh library di depan.
Pembacaan di luar blok terdekode yang disimpan tetap perlu didekode dari awal entri terkompresi. Cache VFS milik rclone
terpisah dan tetap melayani rentang yang sudah lengkap di cache tanpa masuk ke jalur ini; cache-cache ini juga
membantu pembacaan HTTP/WebDAV langsung.

Entri terkompresi hanya bisa didekode dari awalnya, jadi pembacaan yang jauh ke dalamnya berarti seluruh archive diambil dulu. zurg menahan pembacaan seperti ini selama 20 detik
lalu menjawab `503` daripada membiarkan klien tanpa balasan. Hasil dekode yang sudah dicapai disimpan, jadi pemutar yang mencoba ulang seek maju akan
makin jauh setiap kali. Pembacaan yang ditolak dekat akhir entri juga memulai satu dekode latar belakang untuk entri itu, satu entri setiap kali, yang menyimpan
8 MiB terakhir entri di `data/bytecache/decoded-tails/`. Setelah itu akhir file terbaca langsung, dan inilah yang diminta media server saat menganalisis file.
Penyimpanan itu memakai budget yang sama dengan `archive_decoded_disk_cache_mb` lagi dan dimatikan bersamanya.

Metadata turunan bertambah seiring library dan terpisah dari budget byte ini.
Pemindaian NZB menghapus manifest dan indeks artikel untuk dokumen yang sudah dihapus. Revisi layout archive yang usang bisa dihapus saat instance dihentikan; file itu bisa dibuang dan akan dibangun ulang saat dibutuhkan.

## Validasi dan pemulihan {#validation-and-recovery}

Catatan metadata dan blob byte yang baru punya checksum. Record yang rusak dan penulisan cache yang gagal akan kembali ke sumber. Record artikel hanya masuk ke disk cache setelah fetch lengkap berhasil, dan ditulis setelah artikelnya diserahkan ke read yang mengambilnya, jadi read tidak pernah menunggu cache. Jika ada banyak penulisan artikel sekaligus, lebih dari yang boleh berjalan bersamaan, record tambahan akan dibuang alih-alih menahan read. Record yang dibuang akan diambil ulang saat dibutuhkan lagi. Identitas artikel mencakup revisi NZB, konfigurasi server, file, dan segment. Identitas arsip mencakup referensi sumber saat ini, ukuran, konfigurasi akun, password, dan versi format. Penggantian sumber NZB juga membatalkan layout arsip dan byte yang sudah di-decode.

Sidik jari sumber lokal mengasumsikan penggantian mengubah ukuran atau waktu modifikasi. Sengaja tidak meng-hash seluruh XML setiap kali startup. Jika ingin mempertahankan keduanya saat penggantian, cache turunan yang terkait harus dihapus.

Snapshot RD hanya diterima untuk token dan batas download yang dikonfigurasi sama, dalam satu jam, dan setelah probe live mengonfirmasi entri terbaru dan total jumlahnya cocok. Jika daftar berubah, rekonsiliasi penuh akan dijalankan. Tabel region TorBox tetap memakai masa berlaku enam jam yang sudah ada. Masa berlaku URL pengiriman dan penanganan kegagalan provider tidak berubah: layout yang sudah hangat akan membuka payload-nya dulu sebelum mencatat keberhasilan HTTP, sehingga URL yang sudah dicabut bisa mengikuti jalur resolusi/retry yang normal.

Mutasi link pengiriman memicu flush disk yang digabung sekitar satu detik kemudian. Retry lima menit dan flush saat shutdown tetap berjalan. Penulisan atomik mencegah read melihat record yang belum selesai ditulis, tetapi ini bukan jaminan fsync terhadap pemadaman listrik. File cache baru memakai mode `0600` di Unix karena link dan layout arsip terenkripsi bisa membawa kredensial atau kunci turunan. Di Windows, ACL dari direktori tempat file berada yang dipakai, bukan bit izin Unix.

## Backup dengan cache yang sudah hangat {#backups-with-warm-caches}

Backup default tetap menyimpan state utama yang otoritatif. Untuk menyertakan cache turunan dan cache VFS rclone milik instance ini:

```sh
./zurg backup --include-caches --out warm.zurgbackup
```

Ukurannya bisa jauh lebih besar dari backup standar. Backup ini mencakup root yang tercantum di atas, cache penamaan, ukuran, dan PAR2 NZB, serta state network-test. Log dan snapshot database Plex tetap dikecualikan. Cache rclone di luar `data/rclone-cache/` tidak ikut disertakan. Hentikan instance jika snapshot yang konsisten dari cache aktif itu penting.

Untuk restore, hentikan instance dulu, lalu jalankan `./zurg restore-backup warm.zurgbackup`.
Backup menyimpan timestamp sumber dengan presisi nanodetik, jadi NZB yang tidak berubah bisa tetap memakai indeks dan manifest-nya. Cache yang di-restore tetap menjalani pengecekan validasi dan kedaluwarsa yang normal. Backup juga berisi token dan kredensial yang di-cache dari config.

## Pemeriksaan yang bisa direproduksi {#reproducible-checks}

`BenchmarkParsedDocumentStartup` membandingkan parsing XML dengan setiap mode restore manifest, memakai 60 file dan 30.000 segmen. `BenchmarkDetailJSONRefresh` membandingkan jalur baca JSON dengan akses memoized untuk record 1.000 file. Keduanya adalah benchmark filesystem lokal yang sudah warm, bukan pengukuran startup produksi end-to-end.

Diukur di Apple M3 Pro dengan tiga kali run 500 ms pada 2026-09-05 (median per operasi):

| Operasi | Waktu | Byte yang dialokasikan |
| --- | ---: | ---: |
| Parse XML NZB | 43,49 ms | 20,27 MB |
| Restore metadata di mode `mmap` | 0,224 ms | 59 KB |
| Restore metadata dan indeks artikel yang resident | 0,577 ms | 1,79 MB |
| Restore metadata di mode `reparse` | 0,199 ms | 59 KB |
| Baca/decode record detail provider | 0,538 ms | 784 KB |
| Pakai ulang record detail dengan cek stat dan copy | 0,0084 ms | 59 KB |

Kasus decode detail mengosongkan memo baru sebelum setiap pemanggilan dan sudah termasuk biaya pengisian memo itu. Angka-angka ini hanya membandingkan dua jalur akses yang ada sekarang. Angka ini tidak memperkirakan latensi jaringan dan tidak memproyeksikan waktu boot seluruh library.

Regression test mencakup penggunaan ulang setelah restart, korupsi, perubahan sumber, isolasi akun, resolusi concurrent, identitas byte di awal/tengah/akhir, seek mundur melewati jendela RAM, dan pencabutan URL setelah layout di-restore.

```sh
go test ./...
go test -race ./internal/debrid ./internal/nzb ./internal/rarstream ./internal/universal ./pkg/cachefile ./pkg/diskcache
go test ./internal/nzb ./internal/torrent -run '^$' -bench 'Benchmark(ParsedDocumentStartup|DetailJSONRefresh)$' -benchmem
make integration-test
```

Integration target membutuhkan akun uji live yang sudah didokumentasikan dan dependensi host. Script integration yang di-skip tidak memverifikasi perubahan cache.
