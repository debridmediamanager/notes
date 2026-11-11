# Pengujian E2E {#e2e-testing}

Tes end-to-end untuk memastikan zurg berjalan dengan benar setelah deployment.

## Tes Playback Plex {#plex-playback-test}

Memverifikasi bahwa konten benar-benar bisa diputar lewat Plex dengan memilih film secara acak dan menguji seluruh alur pemutaran.

### Jalankan Tes {#run-the-test}

```bash
./scripts/plex-e2e-test.sh
```

Skrip ini otomatis membaca `plex_server_url` dan `plex_token` dari `config.yml`.

Untuk menimpa dengan pengaturan kustom:
```bash
PLEX_URL="http://your-plex:32400" PLEX_TOKEN="your-token" ./scripts/plex-e2e-test.sh
```

### Apa Yang Diuji {#what-it-tests}

| Step | Description |
|------|-------------|
| 1 | Cari library Movies lewat Plex API |
| 2 | Ambil total jumlah film |
| 3 | Pilih film secara acak |
| 4 | Ambil URL stream untuk film tersebut |
| 5 | Pastikan stream bisa diakses (HTTP 200) |
| 6 | Decode 3 detik video dengan ffmpeg |
| 7 | Buat dan verifikasi pelacakan sesi Plex |

### Output yang Diharapkan {#expected-output}

```
=== Plex E2E Playback Test ===

[1/7] Finding Movies library...
  Library key: 15
[2/7] Getting movie count...
  Total movies: 1234
[3/7] Selecting random movie...
  Selected: 2 Fast 2 Furious (2003) (ratingKey: 756524)
[4/7] Getting stream URL...
  File size: 54GiB
[5/7] Verifying stream accessibility...
  HTTP Status: 200 OK
[6/7] Decoding video (3 seconds)...
  Decoded 72 frames successfully
[7/7] Testing Plex session tracking...
  Session created and tracked

=== TEST PASSED ===
Movie '2 Fast 2 Furious (2003)' is playable via Plex
```

### Prasyarat {#prerequisites}

- Server Plex sudah berjalan dan bisa diakses
- `plex_server_url` dan `plex_token` sudah diatur di `config.yml`
- `curl`, `jq`, dan `ffmpeg` sudah terpasang

### Pemecahan masalah {#troubleshooting}

| Error | Penyebab | Solusi |
|-------|----------|--------|
| No movie library found | Tipe library salah atau kosong | Cek apakah Plex punya library "Movies" |
| Stream not accessible (HTTP 4xx) | Masalah auth atau path | Verifikasi token dan pastikan file-nya ada |
| Failed to decode video frames | File rusak atau masalah jaringan | Cek log zurg, coba film lain |
| Session not detected | Sesi Plex timeout | Cek log Plex |

## Suite Integrasi {#integration-suite}

```bash
ssh zen
cd /path/to/isolated/zurg/source
make integration-test
```

**Jalankan di target terisolasi pada `zen`.** Siapkan toolchain Go, shellcheck, rclone, dan probe move .NET di sana. Suite ini membuat proses zurg dan mount-nya sendiri. Suite ini tidak perlu menggantikan layanan zurg atau mount normal milik zen. Gunakan direktori sumber, `TMPDIR`, config, port, dan `MOUNT_PATH` yang terpisah. Periksa config scratch sebelum menjalankannya. Tetap gunakan `INTEGRATION_LOCK_FILE=/tmp/zurg-integration-rd.lock` di seluruh host, meskipun pakai `TMPDIR` pribadi, supaya sesi lain tetap antre dengan sesimu.

Tes yang prasyaratnya tidak ada akan di-skip dengan exit sukses. Baca outputnya untuk memastikan FUSE, rclone, Plex, dan NNTP benar-benar berjalan.

| Test | Butuh FUSE | Butuh Plex | Butuh akun Usenet |
|------|:----------:|:----------:|:-----------------:|
| `refresh_repair_integration.sh` | | | |
| `network_test_cache_integration.sh` | | | |
| `rclone_mount_integration.sh` | ya | | |
| `magic_mount_integration.sh` | ya | | |
| `magic_move_refusal.sh` | ya | | |
| `magic_library_move_integration.sh` | ya | | |
| `plex_integration.sh` | ya | ya | |
| `nzb_bench_integration.sh` | | | ya |

`force_location_integration.sh` **tidak** termasuk dalam suite. Tes ini memeriksa sesuatu tentang jalur jaringan host ke CDN Real-Debrid, bukan tentang zurg. Jadi tes ini akan gagal di tempat jalur itu tidak bisa dijawab, apa pun perubahan yang sedang diuji. Jalankan secara sengaja dengan `make force-location-test`, di host yang IPv4-nya ke region yang dipaksa berfungsi. Lihat [Tes Integrasi Force Location](#force-location-integration-test).

Lima tes yang memakai Real-Debrid menggunakan akun yang sama. Lihat [akun dibagi bersama](#the-real-debrid-test-account-is-shared). Benchmark memakai akun news dan sama sekali tidak menyentuh Real-Debrid. Tapi benchmark tetap mengambil lock host-wide yang sama dengan tes lainnya. Hasil benchmark yang diukur bersamaan dengan pembacaan dari suite lain sebenarnya mengukur suite lain itu.

Tes mount juga bisa jalan di Mac jika macFUSE terpasang. Tes ini sudah diverifikasi di macFUSE dan di `fusermount` Linux. Tes Plex membutuhkan `plex_server_url` dan `plex_token` di config scratch-nya. Plex juga harus bisa mengakses setiap direktori induk dari mount scratch. Mount yang berada di bawah home directory pribadi bisa berfungsi untuk user tes, tetapi tidak bisa diakses oleh Plex.

`make integration-test` membangun zurg, menjalankan shellcheck pada script, self-test `lib.sh`, dan unit test `integration/nzbbench`, lalu menjalankan ketujuh tes dari yang paling murah: network test cache, rclone mount, Plex, mount `__magic__`, penolakan move .NET, refresh/repair, dan benchmark Usenet di urutan terakhir. Dua yang terakhir adalah yang paling mahal. Refresh/repair menunggu scan library penuh, dan benchmark membaca gigabyte dari news server dua kali. Jadi kesalahan di tes lain tidak perlu membuatmu menunggu lama hanya untuk menemukannya. `make integration-test-media` menjalankan tes mount rclone, Plex, dan mount `__magic__`. `make nzb-bench-test` hanya menjalankan benchmark.

Setiap script memiliki work dir sendiri di bawah `$TMPDIR`, port sendiri, dan menulis log zurg ke sana. Suite berjalan dengan `STREAM_LOGS=false`, jadi hanya assertion tes yang tampil di terminal. Set `STREAM_LOGS=true` untuk mengikuti log zurg di stderr saat debugging.

Helper bersama ada di `integration/lib.sh` (kontrol proses, API Real-Debrid, query library di disk) dan `integration/lib_media.sh` (FUSE dan Plex). Untuk menambah tes, source helper-helper ini, jangan copy script tes lain.

`integration/lib_test.sh` mencakup helper itu sendiri. Tes ini tidak butuh akun, tidak butuh jaringan, dan selesai sekitar satu detik. `integration/nzb_bench_timing_gate_test.sh` mencakup cara wrapper benchmark menerjemahkan exit code tool menjadi bahasa suite. Tes ini berjalan dari laporan asli yang sudah dipangkas di `integration/testdata/`. Keduanya dijalankan dengan `make test-integration-lib`.

### Akun Real-Debrid untuk tes dipakai bersama {#the-real-debrid-test-account-is-shared}

Suite ini menjalankan satu akun uji Real-Debrid, dan akun itu tidak privat. Zurg produksi milik `zen` memantau library yang sama, jadi zurg itu ikut mendaftar dan me-refresh torrent yang baru saja ditambahkan oleh tes. Instance mana pun di akun ini **dengan repair diaktifkan** juga ikut memverifikasi, memperbaiki, dan merapikan torrent tersebut.

Kedua kegagalan di bawah didiagnosis pada 2026-08-23, saat zurg milik `macmini` berjalan di akun ini dengan repair aktif setiap 10 menit. Instance itu dihentikan pada 2026-08-29 dan tidak ada yang mengawasinya, sementara run milik `zen` memakai `enable_repair: false`. Jadi per 2026-09-01 kedua kegagalan itu tidak punya sumber yang aktif. Keduanya akan muncul lagi begitu repair dinyalakan di mana pun pada akun ini, dan itulah sebabnya serialisasi di bawah tetap berlaku.

Apa dampaknya pada sebuah run, setelah empat dari enam script gagal pada build yang diuji *dan* juga pada baseline-nya:

- **Fixture yang tidak pernah muncul.** Real-Debrid men-dedupe download id per link, dan menghapus baris downloads akan mencabut kode itu untuk siapa pun yang memegangnya. Cleanup dari instance lain mencabut kode yang baru saja di-resolve oleh run ini, verifikasi run ini lalu menjawab `404 invalid_download_code`, dan zurg menandai file itu sebagai rusak. Torrent yang rusak disembunyikan dari setiap listing. Tes kemudian menulis `zurg serves the fixture over HTTP but it never appeared under .../mnt/movies within 180s`, yang terkesan seperti bug mount atau dircache, padahal bukan keduanya.
- **Delete yang dibatalkan.** Instance yang melakukan repair menambahkan lagi torrent yang baru saja dihapus oleh run ini, sehingga `refresh never dropped <hash> after it was deleted from the account` gagal, padahal library itu sudah melaporkan kondisi yang benar.

Assertion delete dan repair yang paling terdampak. Sebelum menyalahkan perubahan, baca konteks kegagalan yang dijelaskan di bawah. Dan jika sebuah run harus bersih, hentikan dulu repair di instance lain.

**Dua script ini tidak boleh berjalan bersamaan**, baik di host ini maupun dari sesi lain di host ini. Keduanya berbagi anggaran API per menit milik akun, sehingga satu pasangan memicu `API rate limit (code=34)` dan assertion mulai gagal karena trafik, bukan karena perilaku (diukur di `fun`, dua run paralel). Selain itu, setiap script menghapus torrent *berdasarkan hash*, sehingga cleanup satu run dengan senang hati akan menghapus fixture run lain. Karena itu setiap script mengambil lock untuk seluruh host di awal `main`, sebelum panggilan API pertama, dan menahannya sampai keluar.

| Variabel | Default | Keterangan |
|----------|---------|-------------|
| `INTEGRATION_LOCK_FILE` | `$TMPDIR/zurg-integration-rd.lock` | Lock-nya. `flock` jika tersedia, jika tidak, direktori `.d` yang diberi stempel pid (macOS tidak punya `flock`) |
| `INTEGRATION_LOCK_WAIT` | `0` | Detik untuk antre di belakang run yang sedang berjalan. `0` langsung menolak, dan itu yang kamu mau. Alternatifnya adalah menunggu satu jam di belakang cold scan |

Lock yang tertinggal dari run yang dihentikan paksa akan diambil alih secara otomatis: direktori itu menyimpan pid pemiliknya, dan `flock` dilepas oleh kernel. Lock ini tentu tidak memberi tahu zen atau macmini apa pun. Ia hanya menjaga agar run di host ini tidak saling tabrakan.

**Membaca kegagalan.** Setiap `fail` sekarang mencetak, dari log zurg run tersebut: jumlah tiap gejala akun bersama, yaitu `invalid_download_code`, `hoster_unavailable`, baris rate-limit, `code=34`, `Link verification failed`, `keeping files as broken`, `broken_file]`, dan `Deleted downloads entry`. Setelah itu sepuluh baris terakhir dari baris-baris tersebut, lalu beberapa baris terakhir yang menyebut fixture yang sedang diuji. Baris `none present, so this failure is probably zurg's own and not the account's` adalah tanda untuk memeriksa kodenya sebagai gantinya.

`docs/realdebrid-behavior.txt` memuat semantik link yang mendasari semua ini: link mana yang di-redeem dari akun mana, dan mengapa `unavailable_file` serta `hoster_unavailable` memiliki arti yang berbeda.

### Durasi Berjalan {#runtime}

Run pertama di work dir yang sama harus melewati cold library scan: satu panggilan info dan satu verifikasi link per torrent, dibatasi oleh jatah API akun. Di akun dengan beberapa ribu torrent, itu bisa memakan waktu puluhan menit. Akun ini punya 3.361 torrent pada 2026-08-29, cukup untuk memicu `code=34` terus-menerus dan membuat satu script berjalan sekitar dua puluh menit. Work dir menyimpan tiga cache di antara run supaya run berikutnya bisa melewatinya: `info/`, `linkcache/`, dan hasil network test. Hapus work dir untuk memaksa jalur cold.

`linkcache/` adalah data yang dipersist oleh `internal/debrid.LinkCache`, satu file per instance provider. Bagian inilah yang menghemat dua puluh menit tadi. Saat pertama kali melihat sebuah torrent, zurg me-resolve salah satu link-nya untuk verifikasi. Itu satu panggilan `unrestrict/link` per torrent saat cache kosong, dan gratis saat cache sudah terisi. Manfaatnya dibatasi oleh TTL cache 4 jam. Suite yang dijalankan ulang keesokan harinya akan kembali cold, jadi ini mempercepat iterasi, bukan run pertama.

Baik `info/` maupun `linkcache/` tidak bebas dari link, dan keduanya menyimpan kode yang bisa dicabut oleh instance lain di akun bersama. `.zurginfo` adalah `TorrentInfo` apa adanya, jadi isinya termasuk kode `/d/` Real-Debrid milik torrent, dan `linkcache/` menyimpan hasil resolve kode-kode tersebut. Keduanya tetap dipertahankan. Membangun ulang keduanya yang memakan waktu puluhan menit. Entry yang dicabut bukan jawaban yang salah. Verifikasi akan menerima `404 invalid_download_code`, lalu zurg membuang entry itu dan mint ulang, jadi hanya entry yang dicabut yang butuh panggilan. Akan ada beberapa entry seperti itu di setiap run, dan kecepatannya akan bervariasi tergantung jumlahnya.

Fixture lebih sempit lagi. `clean_state_for_hash` menghapus entry `info/` yang hash-nya cocok, jadi daftar link-nya selalu diambil ulang dari akun. `linkcache/` diindeks per link, bukan per hash, dan tidak disapu per fixture. Itu berarti *hasil resolve* salah satu link tersebut masih bisa berasal dari run sebelumnya. Hal ini tidak memengaruhi assertion apa pun di sini, karena fixture menguji refresh, routing, mount, dan repair. Resolusi yang sudah basi akan gagal verifikasi dan di-mint ulang sebelum salah satu dari pengujian itu melihatnya.

### Tes Integrasi Refresh/Repair {#refreshrepair-integration-test}

```bash
./integration/refresh_repair_integration.sh
```

Automatic repair tetap nonaktif di config scratch. Dua permintaan eksplisit `/manage/{hash}/repair` melewati setting itu dan memperbaiki fixture-nya.
Mengaktifkan unattended repair juga akan memindai dan mengubah entri yang tidak terkait di akun bersama, sehingga jatah API yang dibutuhkan assertion ikut habis.
`refresh_repair_config_test.sh` memeriksa config yang dihasilkan tanpa lalu lintas provider, dengan menggunakan input scratch yang sudah di-redact dan diambil dari kegagalan 2026-09-10.

| Skenario | Deskripsi |
|----------|-----------|
| 1. Refresh Otomatis (Penambahan) | Menambahkan torrent lewat RD API lalu menunggu refresh loop mendeteksinya — tanpa restart, karena kalau tidak, yang diuji malah jalur cold-load |
| 2. Penugasan & Perutean Direktori | Memverifikasi file muncul di direktori virtual HTTP/DAV |
| 3. Persistensi (Restart) | Me-restart zurg dan memastikan state cache tetap ada |
| 4. Refresh Otomatis (Penghapusan) | Menghapus torrent dan menunggu obsolete-key sweep menghapusnya |
| 5. Pemicu Repair | Memicu repair lewat Manage API, memastikan zurg mencatat bahwa permintaan diterima, dan menunggu `ok_torrent` dengan 0 file rusak |
| 6. Verifikasi Repair | Me-repair torrent kedua dan mengambil file video darinya dengan range request |

#### Variabel Lingkungan {#environment-variables}

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `12345` | Port untuk instance zurg uji coba |
| `CONFIG_PATH` | `config.yml` | Config tempat meminjam kredensial: `token` dari provider `realdebrid`, serta `username`/`password` di level atas |
| `TEST_HASH` | *(bawaan)* | Hash torrent untuk tes refresh |
| `REPAIR_TEST_HASH` | *(bawaan)* | Hash torrent dengan bagian yang rusak untuk tes repair |
| `VERIFY_TEST_HASH` | *(bawaan)* | Hash torrent untuk tes verifikasi repair |
| `READY_TIMEOUT` | `120` | Detik untuk menunggu zurg siap |
| `INITIAL_SCAN_TIMEOUT` | `3600` | Detik untuk menunggu putaran refresh penuh pertama selesai |
| `REFRESH_TIMEOUT` | `120` | Detik untuk menunggu refresh mendeteksi penambahan atau penghapusan |
| `REPAIR_TIMEOUT` | `300` | Detik untuk menunggu repair selesai |
| `STREAM_LOGS` | `true` | Ikuti log zurg di stderr |
| `ZURG_BIN` | `$(pwd)/zurg` | Path ke binary zurg. Harus absolut, karena zurg dijalankan dari direktori kerja |
| `WORK_DIR` | `$TMPDIR/zurg-refresh-repair` | Direktori kerja (dipertahankan di antara run) |
| `WORK_DIR_CLEANUP` | `false` | Hapus direktori kerja saat keluar, sehingga cache yang membuat run berikutnya lebih cepat ikut terhapus |

### Tes Integrasi Force Location {#force-location-integration-test}

```bash
make force-location-test
```

Tidak ikut `make integration-test`. Tes ini dijalankan secara manual. Saat diukur di `fun` pada 2026-08-29, host `nyk` yang dipaksa ternyata me-resolve ke rekaman AAAA, dan download client memakai `tcp4` untuk menghubunginya. Akibatnya, setiap HEAD berakhir dengan `no suitable address found`. Dengan tiga kali percobaan ulang untuk tiap link, pemindaian library yang ditunggu tes ini bisa terus berjalan hampir satu jam sebelum gagal, dan kegagalannya ada di jaringan host, bukan di zurg. Tes ini sebenarnya sudah melewati pengecekan jika sebuah region tidak sehat (lihat di bawah), tetapi pengecekan itu tidak menangani host yang tidak bisa menjangkau region yang *sehat* lewat IPv4.

Tes ini menyiapkan cache jaringan yang dikunci ke `LOCATION` (default `nyk`), lalu memastikan bahwa link yang di-resolve lewat endpoint `/strm/` milik zurg mengarahkan ke host download di lokasi tersebut. `MAX_GEO_PROBES` (default `4`) membatasi jumlah geo server yang diperiksa oleh tahap seed.

Dengan `cdn_host_preference` diatur, setiap link yang diverifikasi zurg akan lewat region yang dipaksa. Jika region itu tidak sehat, daftar hasilnya kosong dan kegagalannya terlihat seperti bug di zurg. Karena itu, tes ini mengecek region dulu dan melewatinya (skip), bukan gagal, jika Real-Debrid tidak mau membuat link untuk region tersebut atau host yang diberikan tidak mau menyajikan data.

### Tes Integrasi Network Test Cache {#network-test-cache-integration-test}

```bash
./integration/network_test_cache_integration.sh
```

Menjalankan zurg dua kali: start pertama harus menjalankan latency sweep dan menulis `data/network_test_results.json`, sedangkan start kedua harus memuat file itu dan tidak menjalankan sweep baru.

### Tes Integrasi Rclone Mount {#rclone-mount-integration-test}

```bash
./integration/rclone_mount_integration.sh
```

Ini menelusuri jalur yang benar-benar dilalui player: FUSE → zurg HTTP → Real-Debrid:

| Step | Assertion |
|------|-----------|
| 2 | zurg memasang mount-nya sendiri dan mencatat `Mount verification successful` |
| 3 | direktori yang dikonfigurasi terlihat di root mount |
| 4a–4c | fixture masuk ke library, disajikan lewat HTTP, dan sampai ke mount. Langkahnya dibuat bertahap supaya kalau gagal, pesannya menyebut hop yang rusak, bukan sekadar "not in the mount" |
| 5 | membaca file lewat FUSE mengembalikan byte asli |
| 6 | mematikan zurg melepas mount |

Langkah 4c adalah assertion dircache VFS. Fixture hanya sampai ke mount kalau daftar direktorinya di-invalidate, bukan disajikan dari daftar yang sudah di-cache sebelum torrent-nya masuk.

Library dipersempit dengan regex yang dibuat dari nama fixture itu sendiri, jadi mount hanya berisi satu rilis, bukan seluruh akun. `MOUNT_PATH` default-nya `$WORK_DIR/mnt`, tidak pernah `/mnt/zurg` milik produksi. `RCLONE_BIN` default-nya `$(pwd)/bin/rclone`.

### Tes Integrasi Plex {#plex-integration-test}

```bash
./integration/plex_integration.sh
```

| Langkah | Yang dicek |
|------|-----------|
| 2 | zurg mencatat log `Successfully connected to Plex server` |
| 3 | fixture-nya muncul di library, dan kalau juga muncul di mount, file itu harus bisa dibaca (Plex membacanya sebagai user-nya sendiri) |
| 4 | section baru yang sekali pakai dibuat di atas `$MOUNT_PATH/movies` |
| 5 | zurg me-resolve path library-nya ke section itu, lalu mengantri refresh **untuk path fixture** |
| 6 | Plex akhirnya mengindeks item-nya |

Fixture yang muncul di mount itu prasyarat di sini, bukan asersinya. Kalau Plex sudah dikonfigurasi, zurg juga menjalankan matcher-nya ke seluruh library Plex. Itu bersaing dengan refresh, jadi daftar VFS bisa tertinggal jauh. Test-nya mencatat hal ini lalu lanjut setelah `MOUNT_VISIBLE_TIMEOUT` (default `420`). Langkah 5 dan 6 sudah gagal kalau Plex tidak bisa melihat file-nya, dan memastikan invalidasi bekerja adalah tugas test mount. `PLEX_URL` dan `PLEX_TOKEN` menimpa `plex_server_url`/`plex_token` di config.

Plex otomatis men-scan section baru dan bisa selesai sebelum pembuatan section kembali. Test melaporkan jumlah awal itu. Langkah 5 secara terpisah mengecek bahwa zurg mengantri path yang benar setelah permintaan manage eksplisit.

Section dibuat dengan `agent=tv.plex.agents.none` dan scanner `Plex Video Files`, jadi Plex mengindeks secara lokal tanpa menanyakan agent metadata online. Section itu dihapus saat keluar, termasuk saat gagal, dari EXIT trap. Tapi tidak ada yang jalan saat SIGKILL, jadi setelah run yang di-kill, cek dan hapus hanya section milik kamu sendiri. Harness membiarkan section yang sudah ada karena bisa jadi milik sesi lain. Library yang sudah ada tidak pernah disentuh.

Langkah 5 meminta zurg menjalankan efek sampingnya lewat `POST /manage/{hash}/scan`, bukan menunggu pass refresh. Trigger penugasan direktori hanya jalan sekali, yaitu saat torrent ditemukan, dan itu pasti terjadi sebelum section ada. Menunggu pass penuh berikutnya memakan waktu puluhan menit di akun dengan beberapa ribu torrent. Mapping yang diuji tidak berubah: zurg tetap harus me-resolve path library-nya sendiri ke section yang tepat.

### Regresi Benchmark Usenet {#usenet-benchmark-regression}

```bash
./integration/nzb_bench_integration.sh
make nzb-bench-test
```

Tidak ada bagian lain di suite yang membaca satu byte pun lewat NNTP. Perubahan pada article fetcher, yEnc decoder, PAR2 repair, atau archive reader bisa membuat throughput turun setengah, memori dua kali lipat, atau mulai menyajikan silence untuk article yang sudah hilang, dan semua test lain tetap lulus. Test ini membaca empat release yang sudah di-stage lewat zurg scratch, lalu memeriksa angka dan byte-nya.

**Kenapa pakai A/B dan bukan angka yang disimpan.** Throughput di news server live naik turun 10–20% sepanjang malam. Enam kali baca release yang sama pernah berada di kisaran 34–50 MB/s dalam satu sesi. Jadi kalau pakai rentang ketat terhadap angka yang dicatat minggu lalu, test akan gagal karena kondisi jaringan, bukan karena kodenya. Makanya test ini mengukur dua binary di jendela waktu yang sama, di host yang sama, dengan urutan yang bergantian di tiap rep supaya pemanasan di sisi provider kena ke keduanya, lalu membandingkan median-nya.

A adalah baseline: secara default, tag `*-nightly` terbaru yang bisa dijangkau dari `HEAD`. Tag itu di-extract dengan `git archive`, dibangun sekali, lalu di-cache di work dir supaya run berikutnya bisa memakainya lagi. B adalah kandidat, yaitu `zurg` yang baru saja dibangun dari repo ini. **Sebuah metrik dianggap gagal kalau B lebih buruk dari A lebih dari 5%** (`BENCH_TOLERANCE`). Kalau lebih baik, dilaporkan sebagai peningkatan. Kalau metrik hilang di salah satu sisi, hasilnya `n/a`, bukan regresi. Di tiap rep, test mengukur cold open, time to first byte, read 64 MiB, re-read 64 MiB yang sama dalam keadaan warm, scrub delapan titik, read 256 MiB beserta CPU-detik per gigabyte dan peak RSS di sebelahnya (hanya Linux, karena keduanya diambil dari `/proc`), dan durasi container yang dibaca `ffprobe`.

Correctness hanya diperiksa pada kandidat, dan tidak pernah lewat clock. Setiap read mencatat md5 yang harus cocok dengan konstanta yang tercatat dan harus sama antara kedua binary. Release yang rusak hanya boleh menyajikan byte asli atau silence, tidak ada yang lain. Repair kemudian harus mencapai byte asli dan tetap benar setelah restart.

Corpus-nya tersimpan di `integration/nzbbench/corpus/`, berisi enam NZB untuk enam pertanyaan:

| NZB | Isinya | Untuk apa |
|-----|--------|-----------|
| `ToyStory5.nzb` | WEB-DL 6.61 GB, 1.576 article × 4 MiB | semua angka throughput dan latency, dan assertion ffprobe |
| `ToyStory5Damaged.nzb` | release yang sama, tapi message-id article 21 dirusak sehingga server mana pun menjawab `430` | hole harus terbaca sebagai byte asli atau silence. Selain itu adalah bug correctness. Lalu PAR2 harus memperbaikinya, dan hasil repair harus bertahan setelah restart |
| `Obfuscated.nzb` | film yang sama, diposting sebagai tujuh file dengan nama `<hex> [n/7] yEnc`. Nama aslinya hanya bisa diambil dari index PAR2 | pemeriksaan penamaan: file harus muncul dengan nama `.mkv` yang asli dan ukuran yang benar, tanpa `.par2` yang terlihat |
| `FatherBrown.nzb` | RAR 11 volume berisi satu episode, direktori `Sample/`, dan nfo | archive reader: struktur folder harus tetap utuh, dan read di dalam archive punya angka throughput sendiri (`rar_read_MBps`, satu read per rep) |
| `WrongTurn3.nzb.gz` | 7z stored 58 GB dalam 54 volume masing-masing 1 GiB (yang terakhir lebih kecil) plus tujuh file PAR2, berupa tree UHD BluRay lengkap. Di-gzip karena NZB-nya 7 MB dalam bentuk biasa | split-7z reader: volume harus digabung dan header di ujung volume terakhir harus dibaca sebelum apa pun di-list. Listing itulah yang diukur (`sevenzip_list_s`, satu per rep dari layout yang sudah dibersihkan). Setelah itu, stream fitur 57.6 GB harus membalas 16 MiB pada offset 8 GiB dengan md5 yang tercatat. Ini pemeriksaan correctness, bukan pemeriksaan waktu. Tidak ada angka throughput, karena setiap volume release ini kehilangan sekitar seperlima article-nya di provider ini. Read yang diukur akan lebih banyak mengukur waktu pencarian hole |
| `NestedRar.nzb` | repost XviD dua CD: satu set volume RAR5 luar yang member-nya adalah volume dari dua set RAR di dalamnya, di `CD1/` dan `CD2/`, plus klip `Sample/` dan nfo | nested-archive reader: kedua set dalam harus dibuka. Flat test menolak dua set yang bisa dibandingkan, dan direktori dari poster-lah yang mengelompokkannya. Kedua film harus muncul dengan ukuran aslinya dan punya angka throughput sendiri (`nested_read_MBps`, satu read per rep) |

**Satu akun, satu instance.** Zurg kedua di akun news akan bersaing dengan yang pertama untuk jatah koneksinya, dan server akan menolak yang *lebih lama*. Di `fun`, `zurg-usenet` produksi memegang semua koneksi yang diizinkan paket akun, jadi benchmark berjalan dengan 10 koneksi (`BENCH_NNTP_CONNECTIONS`). Penolakan `Too many connections` dilaporkan sebagai **skip, bukan kegagalan**. Hal yang sama berlaku untuk server yang tidak bisa dijangkau atau `AUTHINFO` yang ditolak. Lingkungannya memang tidak bisa menjawab pertanyaan itu, jadi test memberi tahu hal tersebut dan tidak menyalahkan build-nya.

Sekitar 15–20 menit untuk default empat rep, ditambah beberapa menit sekali saja saat baseline pertama kali harus dibangun.

| Variable | Default | Deskripsi |
|----------|---------|-----------|
| `PORT` | `12358` | Port untuk instance zurg benchmark (satu per waktu) |
| `WORK_DIR` | `$TMPDIR/zurg-nzb-bench` | Menyimpan config yang dibuat, run dir dan log kedua binary, `report.json`, dan binary baseline yang di-cache. Disimpan di antara run. `data/` yang persisten itulah yang membuat rep berikutnya mengukur restart, bukan cold learn |
| `BENCH_ENV_FILE` | `~/.config/zurg/bench-account.env` | File akun, di-source kalau ada. Baris `KEY=value` untuk variabel `BENCH_NNTP_*`. **Cara yang didukung untuk memberi benchmark akunnya sendiri**, dan yang menjaga credential tetap di luar repo dan di luar shell history |
| `CONFIG_PATH` | `config.yml` | Config tempat meminjam akun news, kalau environment dan file akun tidak menyebutkannya: blok `nntp:` dari provider `type: nzb` pertama. Peminjaman ditolak kalau akun itu sudah punya koneksi terbuka di sini. Lihat di bawah |
| `BENCH_NNTP_HOST` / `_PORT` / `_TLS` / `_USER` / `_PASS` | *(dari `BENCH_ENV_FILE`, lalu `CONFIG_PATH`)* | Akun news. Nilai yang di-export mengalahkan file akun. Kalau tidak ditemukan di mana pun → skip |
| `BENCH_NNTP_CONNECTIONS` | `10` | Koneksi yang dibuka benchmark. Ini batas atas: akun yang dikonfigurasi dengan jumlah lebih kecil tetap memakai angkanya sendiri |
| `BENCH_ALLOW_SHARED_ACCOUNT` | *(tidak diatur)* | Set ke `1` untuk benchmark di akun pinjaman yang sudah punya koneksi terbuka. Hanya kalau kamu sudah memastikan akunnya masih punya ruang |
| `BASELINE_REF` | `*-nightly` terbaru yang bisa dijangkau dari `HEAD` | Pembanding. Di-resolve setelah `git fetch --tags` yang dilakukan sebisanya |
| `BASELINE_BIN` | *(dibangun dari `BASELINE_REF`)* | Baseline yang sudah dibangun sebelumnya, dipakai apa adanya. Cara membandingkan dengan sesuatu yang sudah tidak bisa dibangun di sini |
| `BENCH_REPS` | `4` | Rep per binary. Median dihitung dari rep-rep ini |
| `BENCH_TOLERANCE` | `0.05` | Seberapa buruk B boleh lebih dari A sebelum dianggap regresi |
| `BENCH_SKIP` | *(kosong)* | Daftar phase yang dipisah koma untuk dilewati: `repair`, `obfuscated`, `rar`, `ffprobe`. `ffprobe` otomatis ditambahkan kalau tidak ada di `PATH` dan tidak ada di `bin/` |
| `REPORT_JSON` | `$WORK_DIR/report.json` | Tempat report disimpan |
| `STREAM_LOGS` | `true` | Ikuti `zurg.log` kandidat di stderr. Progres dari tool tetap dicetak dalam kondisi apa pun |

`report.json` berisi setiap baris per rep untuk kedua binary, median, verdict per metrik, output `version` dari kedua binary, serta host dan OS. Jadi angka di dalamnya bisa dibaca bersama kode yang menghasilkannya. Untuk mencatat sekumpulan angka tanpa membandingkan apa pun, panggil tool langsung dengan satu `--bin`. Tool akan mengukur, menulis JSON, lalu keluar dengan kode 0:

```bash
cd integration/nzbbench && go build -o /tmp/nzbbench . && cd -
/tmp/nzbbench --config /path/to/a-config-with-an-nzb-provider.yml --port 12358 \
  --corpus integration/nzbbench/corpus --work /tmp/nzbbench-record \
  --bin candidate=./zurg --out /tmp/record.json
```

Config harus milik Anda sendiri: config yang dibuat wrapper membawa password akun news dalam teks biasa dan dihapus saat run selesai.

`integration/nzbbench/README.md` mendokumentasikan flag dan exit code milik tool itu sendiri.

**Exit code `nzb_bench_integration.sh`.** `0` perbandingan sudah dibuat dan lulus, atau host tidak bisa melakukan benchmark sama sekali dan run dilewati; `1` sebuah assertion fungsional gagal atau sebuah metrik mundur; `4` semua assertion fungsional lulus dan timing gate **tidak dinilai** -- news server melewati batas stabilitas tool selama window itu, sehingga perbandingan throughput dan latency dibuang. 4 sengaja dibuat bukan 1 seperti build yang rusak dan bukan 0 seperti skip: tidak ada keputusan soal performa, solusinya adalah jalankan ulang di window yang lebih tenang, dan run mencetak banner yang menyebut gate beserta spread yang membuatnya gagal. `make integration-test` mengubah setiap baris recipe yang gagal menjadi exit 2 milik make sendiri, jadi saat suite dijalankan Anda akan melihat make dengan exit non-zero plus banner tadi, bukan baris "All integration tests passed." dari target tersebut; panggil script secara langsung jika ada yang perlu bercabang berdasarkan nilai 4 itu sendiri.

### Prasyarat {#prerequisites-1}

- Token Real-Debrid di `config.yml` (sebagai provider `realdebrid`) atau `RD_TOKEN`
- `curl`, `python3`, dan binary zurg yang sudah dibangun
- `shellcheck` untuk `make lint-integration` (dilewati dengan pemberitahuan jika tidak ada)
- Untuk tes mount dan Plex: `fusermount`/macFUSE, binary rclone, dan
  `user_allow_other` di `/etc/fuse.conf` supaya Plex bisa membaca mount-nya
- Untuk pengecekan penolakan move: rclone yang sudah diperbaiki dari
  `scripts/build-rclone-move-fix.sh`, diatur
  lewat `RCLONE_BIN` dan `RCLONE_TEST_BIN` sekaligus. rclone upstream yang lebih baru tapi belum di-patch tidak cukup. Lihat [regresi MOVE](rclone-move-refusal.md).
  Berikan helper yang sudah dibangun lewat `DOTNET_MOVE_PROBE_BIN`, atau Docker untuk membangunnya. Saat membangunnya sebagai user container tanpa privilege, berikan .NET `XDG_DATA_HOME` yang bisa ditulis, serta direktori cache CLI dan NuGet-nya.
- Untuk benchmark Usenet: akun berita, plus Go, `git`, `tar`, dan `make` —
  benchmark ini membangun baseline-nya dari `git archive` sebuah tag nightly

### Beri benchmark akun news sendiri {#give-the-benchmark-its-own-news-account}

Jatah koneksi itu milik **akun**, bukan milik proses. Kalau benchmark kamu arahkan ke akun yang sudah dipakai instance produksi, keduanya akan berbagi jatah yang sama. Pada titik itu server akan menolak pemegang koneksi yang *lebih lama*, yaitu produksi, yang sama sekali tidak tahu soal benchmark yang menyebabkannya.

Karena itu, benchmark hanya meminjam dari `CONFIG_PATH` sebagai cadangan, dan **menolak meminjam akun yang sudah punya koneksi terbuka di host ini**. Siapkan akun sendiri di `~/.config/zurg/bench-account.env`:

```
BENCH_NNTP_HOST=news.example.net
BENCH_NNTP_PORT=563
BENCH_NNTP_TLS=true
BENCH_NNTP_USER=...
BENCH_NNTP_PASS=...
BENCH_NNTP_CONNECTIONS=25
```

Pilih akun yang punya sisa kapasitas yang tidak dipakai siapa pun. Pilih server yang batas maksimal terukurnya jauh di atas konfigurasi instance mana pun, supaya benchmark tidak sampai membuat reader kehabisan jatah. Apa pun yang kamu `export` di command line tetap lebih diutamakan daripada file tersebut. Kalau kamu sudah memastikan ada sisa kapasitas, `BENCH_ALLOW_SHARED_ACCOUNT=1` bisa dipakai untuk melewati penolakan itu.

### Tidak termasuk dalam suite {#not-in-the-suite}

`rename_integration.sh`, `tag_stats_integration.sh` dan
`test_repair_verification.sh` tidak dijalankan oleh `make integration-test`. Mereka masih punya salinan sendiri dari helper versi lama, yang ada sebelum `lib.sh`. Pindahkan ke `lib.sh` dan beri mereka port yang tidak bentrok sebelum dihubungkan.
