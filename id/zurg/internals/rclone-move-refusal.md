# Import kosong setelah pemindahan yang ditolak {#empty-imports-after-a-refused-move}

Direproduksi dengan rclone 1.72.0, union local-first, VFS full caching, dan `File.Move(source, destination)` dari .NET 6 yang dipakai Sonarr 4.0.19.2979.

Saat backend menolak MOVE, `vfs.File.rename` milik rclone membiarkan direktori dan nama file tetap mengarah ke tujuan yang dicoba. .NET lalu beralih ke copy. Saat membuat tujuannya, .NET membuat entri cache VFS yang kosong. Saat membuka sumbernya, ia justru mengarah ke entri yang sama, sehingga copy membaca EOF dan melaporkan sukses. Reproduksi mengharapkan 4096 byte tapi hanya menerima nol. Mengubah penolakan WebDAV dari 409 ke 422 tidak mengubah hasilnya.

Patch di `scripts/patches/rclone-v1.72.0-rename.patch` mengembalikan direktori dan nama asli saat rename langsung gagal. Patch ini juga menyertakan tes regresi VFS dari upstream. Mount test menjalankan jalur lengkap WebDAV, union, FUSE, dan .NET dengan arsip palsu dan tanpa kredensial provider. Vonis kerusakannya disuntikkan selagi byte fixture masih bisa dibaca: .NET boleh saja menyalin byte tersebut dengan sukses, tapi tidak boleh membuatnya menjadi file kosong.

Build binary baru di samping yang sudah terpasang:

```sh
./scripts/build-rclone-move-fix.sh /absolute/path/to/rclone-fixed
RCLONE_TEST_BIN=/absolute/path/to/rclone-fixed ./integration/magic_move_refusal.sh
```

Build ini mengunci commit upstream `38ab3dd5b1df946aecf5bd085c671c86f46f68eb` (1.72.0). Build menjalankan tes rename VFS sebelum membangun. Mount test membutuhkan Linux FUSE dan Docker, atau `DOTNET_MOVE_PROBE_BIN` mandiri yang dibangun dari `integration/dotnet-move-probe`. Tes ini sengaja gagal jika dijalankan terhadap binary yang belum dipatch. `make integration-test` sudah menyertakan pengecekan ini. Saat menjalankan suite, arahkan `RCLONE_TEST_BIN` dan `RCLONE_BIN` ke binary yang sudah diperbaiki.

Instalasi perlu me-restart mount dengan pengaman media server yang biasa dipakai di deployment kamu. Simpan binary sebelumnya untuk rollback. File kosong yang sudah ada di upstream lokal sebuah union tetap ada setelah mount di-restart. Simpan dan hapus hanya artefak impor kosong yang sudah dikonfirmasi di sana. Restart akan membersihkan node VFS yang sudah usang, tapi tidak memperbaiki artikel Usenet yang hilang.

Perbaikan ini tidak menekan fallback copy .NET dan tidak membuat konten yang rusak bisa dibaca. Pengecekan ketersediaan zurg sebelum penyelesaian SABnzbd dan MOVE yang ditolaknya tetap menjadi proteksi terpisah. Sampling ketersediaan bukan verifikasi seluruh file. Lihat `sabnzbd-client-contract.md`.

Patch yang dikunci ini juga membawa perbaikan file-alias yang dipakai union tertanam. Dengan `action_policy: all`, local dan WebDAV bisa sama-sama menerima operasi file. Local Move atau Remove yang berhasil dan dipasangkan dengan WebDAV 404 hanya diterima setelah pencarian ulang yang baru membuktikan bahwa sumber di upstream yang gagal sudah tidak ada. Operasi yang gagal semua, sumber yang masih ada, parent tujuan yang hilang, dan error I/O atau izin lainnya tetap dianggap gagal. Binary yang dihasilkan melaporkan `v1.72.0-zurg-rename-sidecar-fix` supaya bisa dibedakan dari build VFS-only yang asli.
