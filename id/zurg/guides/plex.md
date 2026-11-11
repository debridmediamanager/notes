# Fitur & Kemampuan Plex {#plex-features--capabilities}

Menjalankan rex bersama Plex Media Server, atau menggantikannya? [Pindah dari Plex ke rex](../../rex/from-plex.md) menjelaskan apa yang tetap dipertahankan di zurg, termasuk mount rclone Anda, dan pengaturan Plex zurg mana yang harus dihapus.

## Konfigurasi & Penyimpanan {#configuration--storage}
- Kunci konfigurasi yang didokumentasikan di [`config.md`](../reference/config.md)/`config.example.yml`: `plex_server_url`, `plex_token`, `plex_match_every_mins` (default 1440), `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` (ejaan lama dari `watchlist.check_every_secs`, default 60s), `mount_path` (wajib untuk pencocokan dan pembuatan path scan). Pengaturan yang dibuat lewat dashboard langsung disimpan ke `config.yml` melalui config writer (`updateConfigFileAtomic`).
- Interval watchlist kembali ke default untuk nilai 0 atau kurang (`GetWatchlistCheckEverySecs`). `plex_match_every_mins` hanya kembali ke default jika nilainya tepat `0` (`intOr`, `internal/config/config.go`). Keduanya tidak bisa dinonaktifkan. Dashboard menolak nilai di bawah 1 (`internal/handlers/dashboard/dashboard.go`). Jika `plex_match_every_mins` bernilai negatif di `config.yml`, zurg berhenti saat startup dengan pesan `is negative; use 0 for the default`. Nilai itu tidak pernah mematikan pencocokan.
- Akuisisi watchlist diatur lewat blok `watchlist:`: `enabled`, `check_every_secs`, `indexers`, `max_size_gb`, `max_season_size_gb`, dan `quality` (default `best`). Jika `indexers` kosong, nilainya meminjam `stremio.indexers`. Kunci datar `plex_watchlist_enabled`, `plex_watchlist_check_every_secs`, dan `watchlist_quality` tetap dihitung sebagai ejaan lama dari yang pertama, kedua, dan terakhir dari daftar tersebut. Lihat [config.md](../reference/config.md#watchlist).
- `mount_path` juga menjadi awalan untuk path scan yang dikirim ke Plex dan mount rclone yang dikelola ([`config.md`](../reference/config.md), `pkg/scan/scanner.go`).
- Hook on-library-update (`on_library_update`) menerima setiap path yang berubah sebagai argumen. Pemanggilannya di-debounce 500 ms dan duplikasinya dihapus, dan hanya satu pemanggilan yang berjalan dalam satu waktu. Ini memungkinkan skrip autoscan Plex (`internal/torrent/hooks.go`).

## Autentikasi & Penemuan Server {#authentication--server-discovery}
- Alur dashboard web: `/plex/auth` membuat sesi PIN (`pkg/plex/auth.go`, `CreatePlexAuthURL`), menyimpannya di `pkg/plex/auth_session.go` (dibersihkan otomatis setelah 10 menit, dicek setiap 5 menit), lalu terus memeriksa penyelesaian lewat `/plex/auth/status` (`PollForAuthToken`, 60 percobaan dengan jeda 5 detik sebelum timeout).
- `/plex/callback` menampilkan halaman progres. Setelah diotorisasi, halaman ini memanggil `/plex/servers` untuk menampilkan daftar server, lalu `/plex/server` untuk memilih salah satunya (`internal/handlers/dashboard/dashboard.go`).
- Pencarian server (`pkg/plex/auth.go`): mengambil resource Plex dengan endpoint HTTP dan HTTPS, membuang relay jika koneksi langsung tersedia, menangani alamat IPv6, dan mengecek `/identity` untuk setiap entri (verifikasi TLS dinonaktifkan). Hanya server yang **dimiliki** akun yang dipertimbangkan (`device.Owned`, `auth.go`). Server yang dibagikan tidak pernah muncul. Entri yang gagal dicek akan dihapus dari respons, bukan dikembalikan dengan `last_error` terisi (`enrichServersWithIdentity`, `auth.go`).
- Saat memilih server, nilai `plex_server_url`/`plex_token` ditulis ke config, Plex client diinisialisasi ulang, scheduler matcher di-(re)start, trigger match dijalankan, dan cache status dashboard di-refresh (`HandlePlexServerSelect`, `internal/handlers/dashboard/dashboard.go`). `/plex/logout` menghapus nilai yang tersimpan dan cache status.

## Kemampuan Klien Plex (`pkg/plex/client.go`) {#plex-client-capabilities-pkgplexclientgo}
- Siklus hidup koneksi: opsi deferred start (`WithDeferredStart`), guard `ValidateConnection` terhadap `/identity`, dan `Close` yang berhenti dengan rapi. Tidak ada API restart. `RestartAllowed`/`RestartReason` di dashboard disimpulkan dari URL server (lokal/LAN vs. remote) dan hanya untuk tampilan (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`).
- Antrean scan: job queue/worker dinamis (`common.DynamicJobQueue`). `ProcessJob` mengirim `GET /library/sections/{key}/refresh` dengan header Plex dan **paling banyak satu** parameter query `path` per job. Lebih dari satu langsung ditolak (`client.go`). Job tanpa path berarti refresh seluruh section. 503 menjadi error server-busy, dan 404 melaporkan bahwa library sudah dihapus dari Plex. `GetJobQueueSize` menampilkan backlog.
- Deteksi beban dan stuck: `CheckServerLoad` memeriksa `/activities`, melacak progress `library.update.section` per UUID (perubahan progress *atau* subtitle dihitung sebagai progress), dan `IsJobStuck` menandai job yang basi berdasarkan `librarySectionID`, dengan fallback Title. `GetServerActivitiesDetails` membuat dan menghapus tracker yang sama. Alasannya, `CheckServerLoad` hanya jalan saat worker punya job di antrean. Dulu scan yang dimulai Plex sendiri tidak punya tracker sama sekali, jadi tidak pernah bisa dilaporkan stuck, dan waktu berjalannya selalu terbaca nol di setiap refresh. Kedua jalur hanya menyimpan riwayat untuk `library.update.section`. Melacak yang lain di sini akan bolak-balik bentrok dengan prune worker.
- **Subtitle activity bukan file yang sedang ditunggu scan yang tertahan.** Diukur di rig plex503 pada 2026-09-15: subtitle `library.update.section` adalah penunjuk enumerasi scanner dan berjalan lebih cepat daripada pembacaan. Saat mount menolak tiga file, subtitle justru menyebut file keempat yang belum pernah diminta. Ia juga menyebut file yang diblokir selama 290 ms dari siklus 56 detik. Dashboard menampilkannya sebagai "Plex reports" dan tidak menautkannya ke release. Apa yang sebenarnya ditunggu scan berasal dari penolakan read milik zurg sendiri (`internal/universal/refused_reads.go`), karena hanya sisi itu yang tahu. Korpusnya ada di `internal/handlers/dashboard/testdata/plex503-*`.
- Query library: `GetSections` (section movie/show beserta locations), `GetSectionItemCount`, `FindSectionNormalized` (mencocokkan path dengan location section dan mengoreksi prefix ke huruf besar-kecil library), `GetAllMediaItemsConcurrent` (fetch batch dan konkuren dengan `includeGuids` untuk mengumpulkan path, GUID, dan IMDB ID), serta `GetShowLevelIMDBIndex` (ID tingkat show untuk section TV, supaya episode bisa mewarisinya).
- Helper metadata & pencocokan (`pkg/plex/match.go`): `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`), `GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`, dengan override title/year/language), `LookupMetadataByGUID`/`LookupRatingKeyByGUID` (`GET /library/all?guid=…`), `ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`), dan parsing GUID (`ExtractIMDBIDFromGUID`, `ExtractTMDBIDFromGUID`, `ExtractTVDBIDFromGUID`, `ExtractAnyIDFromGUIDs`; tipe `MatchResult`/`MatchSelection`).
- Info server: `GetServerIdentityOnly` dan `GetServerDetails` (machine ID/versi; yang kedua juga menjumlahkan sesi/transcode/bandwidth), `GetStreamingSessions`, `GetTranscodeSessions`, `GetServerActivitiesDetails` (diberi anotasi status stuck).
- Riwayat tontonan: `GetWatchHistory` (`GET /status/sessions/history/all`), `GetMetadataBatch` (rating key digabung dengan koma terhadap `/library/metadata`), dan `GetWatchHistoryWithMetadata` (`pkg/plex/history.go`), yang menjadi sumber statistik di `pkg/plex/stats.go`.

## Integrasi Pemindai Media (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Menginisialisasi client Plex saat `mount_path`, `plex_server_url`, dan `plex_token` sudah diatur. Mencoba lagi setiap 5 detik sampai terhubung, lalu memanggil callback `OnPlexReconnected`.
- `TriggerScan` mengelompokkan path per section Plex (lewat `FindSectionNormalized`) dan memasukkan satu job refresh ke antrean untuk setiap path dengan prefix `mount_path`. Progres dicatat setiap 50 path. Juga mendukung Jellyfin/Emby, yang memakai jalur tanpa pengelompokan. Path yang tidak masuk ke section mana pun hanya diberi peringatan jika *tidak ada* path dalam batch tersebut yang cocok. Kalau tidak, cukup ditulis sebagai baris debug, jadi torrent yang ada di folder library dan juga di folder khusus zurg (recent, music, dll.) tidak memicu peringatan.
- `ReinitializePlexClient` memungkinkan pembaruan dasbor mengganti server atau token secara langsung, tanpa perlu restart.
- `GetQueueSizes` menampilkan kedalaman antrean Plex untuk keperluan UI dan monitoring.

## Pencocokan & Sinkronisasi Metadata (`internal/plex/matcher.go`, `internal/plex/schedule.go`) {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- Prasyarat: membutuhkan URL dan token Plex yang sudah dikonfigurasi, `mount_path`, dan `scanner.PlexClient` yang aktif. Kalau tidak, fungsi ini akan mengembalikan error yang jelas.
- Satu-satunya state Plex yang disimpan di torrent adalah `PlexRatingKey` (level show untuk konten episodik) dan `IMDBID` (`internal/torrent/torrent_types.go`). GUID Plex hanya dipakai sementara saat ekstraksi ID dan pelaporan, dan tidak pernah disimpan.
- Pengumpulan data: mengambil semua torrent dari directory map dan semua item Plex lewat `GetAllMediaItemsConcurrent`. Sebelumnya ada pass `GetShowLevelIMDBIndex`, supaya episode mewarisi ID IMDB/TVDB/TMDB milik show-nya, bukan ID level episode. Item di-key dengan `GrandparentRatingKey` jika ada.
- Langkah sinkronisasi:
  - Validasi setiap rating key yang tersimpan terhadap item Plex yang baru diambil. Key yang sudah tidak ada di Plex akan dihapus beserta IMDB ID torrent-nya, dan torrent tersebut dimasukkan lagi ke antrean untuk dicocokkan.
  - Pencocokan berbasis path untuk torrent tanpa rating key: `buildPlexDirIndex` mengindeks setiap komponen path (huruf kecil) dari setiap file Plex, lalu `GetKey` torrent dicari di indeks itu (O(1), entri pertama yang menang). Torrent yang direktorinya tidak cocok dengan lokasi section Plex mana pun akan dilewati dulu.
  - Pengisian IMDB: pertama dari batch yang sudah diambil (tanpa panggilan API), lalu per torrent lewat `GetMetadataSummary` (maks. 20 concurrent).
  - Mendeteksi item Plex yang tidak punya torrent.
  - Mengirim pasangan hash+IMDB yang diisi manual oleh pengguna ke DMM, bukan ID tebakan Plex. DMM menerimanya tanpa key, dan `dmm_api_key` ikut dikirim kalau sudah diatur (`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`, `internal/torrent/mediainfo.go`).
- `MatchSingleTorrent` menjalankan pencarian path yang sama untuk satu torrent. Fungsi ini dipakai tepat setelah targeted scan. Kalau torrent sudah punya rating key, fungsi ini tidak melakukan apa-apa.
- Pelaporan: menulis `logs/match_report.txt` yang berisi ringkasan jumlah, torrent yang tidak cocok, torrent yang dilewati, item Plex tanpa torrent, dan kecocokan yang belum punya IMDB.
- Penjadwalan (`internal/plex/schedule.go`): setiap run yang selesai mencatat `data/plex_match_timestamp`. Saat mulai, `StartMatchingJob` langsung jalan hanya jika stempel itu tidak ada atau lebih tua dari `plex_match_every_mins`. Kalau tidak, job menunggu sisa waktunya dulu. Job ini juga mendengarkan trigger manual di `TorrentManager.PlexMatchTrigger`, perubahan interval langsung di `ResetPlexMatchTicker`, dan akan dijalankan ulang sampai tiga kali kalau mengalami panic.
- Endpoint trigger manual `/plex/match-torrents` mengirim sinyal ke trigger channel dan menolak jika run sedang berjalan. `/plex/match-torrents/status` melaporkan apakah ada run yang sedang berjalan (`internal/handlers/utilities.go`).

## Pencocokan Manual & UI Manage (`internal/handlers/manage`) {#manual-matching--manage-ui-internalhandlersmanage}
- Filter daftar torrent punya status Plex (`plex_matched`, `plex_in_library_not_matched`, `plex_no_imdb`, `plex_missing_metadata`) untuk tampilan cepat (`torrent_list_state.go`).
- Halaman pencocokan manual per torrent di `/manage/{hash}/plex-match`:
  - Torrent harus sudah punya `PlexRatingKey` (diisi oleh matcher). Kalau belum, halaman akan menampilkan "torrent is not linked to Plex". `resolvePlexRatingKey` memvalidasi kunci itu dengan `GetMetadataSummary`, mengisi IMDB ID yang kosong dari situ, dan kalau kuncinya sudah tidak valid, mencari ulang lewat `LookupRatingKeyByGUID` pakai ID `tt…`/`tvdb://`/`tmdb://` yang tersimpan di torrent (`internal/handlers/manage/handler.go`).
  - Mengambil kandidat pencocokan manual dari Plex dengan opsi override judul/tahun/bahasa (44 pilihan bahasa, default `en-US`). Hasilnya ditampilkan dengan pilihan saat ini disorot (`torrent_matches.go`).
  - Menerapkan kecocokan (`HandleApplyPlexMatch`) memanggil `ApplyManualMatch`, lalu mencari ulang rating key berdasarkan GUID yang dipilih, karena Plex mungkin memberi kunci baru. Setelah itu rating key dan IMDB torrent diperbarui (termasuk IMDB opsional yang dimasukkan pengguna), perubahannya disimpan, dan halaman dialihkan dengan status sukses atau error.

## Akuisisi dari watchlist {#watchlist-acquisition}

- Watchlist Plex adalah adapter di `internal/acquisition/plex`, berjalan di layanan acquisition bersama bersama Seerr. Pengaturan watchlist yang sudah ada tetap berfungsi; adapter juga bisa dikonfigurasi di bawah `acquisition.sources`.
- Klien memakai `discover.provider.plex.tv` dan mengambil 100 item per halaman. Token Plex dibaca ulang untuk setiap request, jadi autentikasi ulang langsung berlaku tanpa perlu me-restart adapter.
- Executor bersama mengambil film, atau setiap season yang sudah direncanakan, dari indexer Newznab dan Torznab, dengan lebih mengutamakan season pack. Untuk pencarian TV, TVDB dicoba dulu sebelum IMDb karena pemetaan di tiap indexer berbeda.
- Progres, batas waktu retry, dan bukti per episode tetap tersimpan setelah restart di `data/acquisition.json`. Ledger Plex yang lama otomatis diimpor.
- Penghapusan dilakukan setelah semua target yang direncanakan berhasil di-acquire. Request yang gagal tetap ada di watchlist dan akan dicoba lagi dengan backoff yang tersimpan. Retry yang hanya untuk penghapusan tidak akan melakukan acquire lagi. Lihat [Plex watchlist acquisition](plex-watchlist.md) untuk batasannya dan [acquisition sources](acquisition.md) untuk konfigurasi bersamanya.

## Dashboard & Endpoint API (`internal/handlers/router.go`, `internal/handlers/dashboard`) {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- Routes: `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`.
- Dashboard menampilkan info dan status server Plex lewat `PlexStatusFetcher` dengan dua ticker: setiap 30 detik ia me-refresh streaming sessions, transcodes, bandwidth, dan server activities (`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`); setiap 5 menit ia melakukan fetch penuh yang juga membaca ulang identitas (`GetServerIdentityOnly`), library sections, dan jumlah item per section. Scan activities dicocokkan dengan daftar torrent berdasarkan nama file, supaya dashboard bisa menautkan activity ke torrent hash.
- Endpoint scan per section/semua section memasukkan antrean refresh **penuh** section (`RefreshSection(key, nil)`, tanpa path) untuk satu atau semua section; endpoint ini tidak menyentuh file STRM dan tidak memicu efek samping library (`HandlePlexScan`/`HandlePlexScanAll`).

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- `/plex-stats` menampilkan ringkasan tahunan 9 slide dari riwayat tontonan Plex 12 bulan terakhir; `/plex-stats/data` mengembalikan statistik yang sama dalam format JSON, `/plex-stats/image` membuat PNG yang bisa dibagikan melalui headless chromedp (`square` 1080x1080 sebagai default, `instagram` 1080x1920, `facebook` 1200x630).
- Statistik diambil paling banyak sekali per 24 jam (`?refresh=true` memaksa pengambilan ulang), dibatasi 10000 item riwayat, dan disimpan dalam cache baik di memori maupun di disk pada `data/plex_wrapped_cache.json`, yang dimuat ulang saat startup. Selama proses pengambilan berjalan, halaman menampilkan status loading alih-alih memblokir.

## Efek Samping Library & Tautan Refresh {#library-side-effects--refresh-links}
- Efek samping library dipicu saat assignment direktori berubah, saat rename, penghapusan, dan perbaikan file. `TriggerLibrarySideEffects` menghapus cache dircache rclone VFS untuk path yang terdampak (supaya media server tidak memindai daftar yang sudah usang), memanggil `MediaScanner.TriggerScan` (yang memicu refresh Plex), dan menjalankan hook `on_library_update` milik pengguna (`internal/torrent/hooks.go`).
- Pipeline refresh hanya menjalankan pembuatan STRM dan efek samping setelah inisialisasi selesai, agar Plex tidak melakukan scan terlalu dini (`internal/torrent/refresh.go`).

## Infrastruktur & Skrip {#infrastructure--scripts}
- Contoh vhost Nginx untuk meneruskan trafik Plex (`nginx/plex.conf`).
- `plex_update.sh` adalah skrip partial-scan acuan untuk `on_library_update: sh plex_update.sh "$@"`. Letakkan di samping `docker-compose.yml`, yang foldernya di-mount ke `/config`, jadi skripnya sudah ada di dalam container. Di Windows, hook dijalankan lewat PowerShell, bukan `/bin/sh` (`pkg/script/script.go`), jadi skrip ini tidak jalan di sana. [Usenet → Arahkan Plex ke sana](usenet.md#6-point-plex-at-it) menunjukkan bentuk PowerShell-nya.
- `integration/plex_integration.sh` jalan di bawah `make integration-test` dan `make integration-test-media`. Di host yang tidak punya server Plex, skrip ini akan melewati tes dengan pesan yang jelas, jadi baca outputnya, jangan cuma lihat exit code. `scripts/plex-e2e-test.sh` adalah pengecekan playback mandiri yang membaca `plex_server_url`/`plex_token` dari `config.yml`.

## Pengaturan Plex yang Direkomendasikan {#recommended-plex-settings}

Pengaturan default Plex mengasumsikan disk lokal yang selalu tersedia dan bisa dibaca kapan saja. Mount zurg tidak begitu. Datanya datang dari provider lewat HTTP, dan mount itu kadang tidak bisa dibaca sebentar saat rclone sedang menyambung ulang. Beberapa default Plex justru jadi masalah dalam kondisi seperti ini.

zurg memeriksa pengaturan ini setiap kali Plex melakukan refresh status. `plex_settings_policy` menentukan seberapa jauh zurg akan bertindak: `off`, `warn`, `guard` (default) atau `enforce`. Daftarnya ada di `pkg/plex/settings.go` (`RecommendedSettings`), dan kebijakannya ada di `pkg/plex/reconcile.go`.

Pengaturan yang tidak dilaporkan server akan dilewati, jadi versi Plex yang tidak punya pengaturan tertentu tidak akan dianggap salah konfigurasi.

Sembilan dari enam belas nilai di bawah ini memang berbeda dari default Plex, dan sisanya tujuh sama dengan default. Tujuh pengaturan itu berfungsi sebagai penjaga, bukan koreksi, dan hanya akan aktif kalau kamu sudah mengubahnya sendiri. Baris-baris itu menampilkan nilai yang sama di kedua kolom, dan itu bukan kesalahan. Plex mengirim `GenerateBIFBehavior` dengan nilai `never`, sedangkan server yang dipakai untuk pengukuran ini ternyata sudah di `scheduled`. Kolom "Plex ships" di bawah dibaca langsung dari server lewat `/:/prefs`, bukan diasumsikan. Pengukuran dilakukan pada 2026-09-05 dengan Plex 1.42.2.

### Menonaktifkan satu pengaturan {#opting-out-of-one-setting}

`plex_settings_policy` punya tingkatan, dan tingkatan tidak selalu jadi pertanyaan yang sebenarnya ditanyakan. Kalau file kamu berpindah antar folder library (misalnya pengurutan berbasis tag), kamu bergantung pada Plex untuk mengosongkan trash-nya sendiri supaya entri yang tertinggal ikut hilang, dan `guard` mematikan itu. Turun ke `warn` untuk mendapatkannya kembali juga berarti melepas guard event filesystem, yang berada di tingkatan yang sama dan bukan yang kamu minta.

`plex_settings_ignore` menyebutkan setting satu per satu:

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

Dashboard yang menulis ini untukmu. Halaman config punya saklar **Let Plex Empty Its Own Trash** di atas setting Library Trash Sweep. Saklar itu menambah dan menghapus `autoEmptyTrash` di sini dan membiarkan sisa daftar tidak tersentuh. Mengaktifkannya berlaku setelah restart berikutnya.

Setting yang di-ignore tetap dibaca dan tetap ditampilkan di dashboard dan di `zurg plex-settings` (ditandai `skip`), jadi tidak ada yang disembunyikan. Setting itu hanya tidak pernah ditulis, tidak pernah dihitung sebagai masalah, dan tidak pernah berada di balik banner trash dashboard. ID dicocokkan tanpa membedakan huruf besar-kecil. ID yang tidak menyebut setting apa pun di tabel di bawah akan dilaporkan saat startup dan setting tersebut tetap dijaga guard, karena salah ketik tidak boleh dianggap sebagai opt-out.

Meng-ignore setting keamanan itu atas risikomu sendiri, dan zurg memberi tahu hal itu sekali saat mulai, bukan di setiap refresh. `autoEmptyTrash` khususnya adalah setting yang mengosongkan library saat sebuah scan bertemu mount yang sempat bermasalah. Meng-ignore-nya juga mengembalikan tugas pembersihan ke Plex. Lihat di bawah.

### Siapa yang mengosongkan trash {#who-empties-the-trash}

Mematikan `autoEmptyTrash` membuat satu pekerjaan tertinggal. Plex sudah diberi tahu untuk tidak menghapus entri yang filenya sudah hilang. Sejak lama, penghapusan dari zurg sendiri bersifat opt-in, jadi dengan pengaturan standar, perpustakaan menumpuk entri mati dan tidak ada yang membersihkannya. Keduanya tidak salah, tetapi celahnya nyata. Inilah yang kena ketika sebuah file dipindah antar folder perpustakaan dan entri lama tetap ada selamanya.

zurg sekarang mengambil alih tugas yang dulu dilepasnya. Jika `plex_trash_sweep_every_mins` tidak diisi, [pembersihan sampah](../internals/plex-trash-sweep.md) menghapus entri setiap 60 menit, tetapi hanya jika tidak ada pihak lain yang melakukannya. Jika Plex masih mengosongkan sampahnya sendiri, misalnya karena `plex_settings_policy` bernilai `off` atau `warn`, atau karena `autoEmptyTrash` ada di `plex_settings_ignore`, zurg mundur dan menyerahkannya ke Plex. Dua pembersih di satu perpustakaan adalah cara perbedaan pendapat di antara keduanya berubah menjadi penghapusan.

Pembersihan ini jauh lebih sempit daripada pengosongan sampah bawaan Plex, dan itulah alasan kenapa lebih baik memakainya. Ia menghapus satu entri per waktu, tidak pernah entri yang masih punya file, dan hanya dari mount yang bisa dibaca saat itu. Setiap putaran dibatasi 50 penghapusan dan 10% dari sampah. Entri yang belum jelas statusnya tetap terlihat sebagai rusak selama 14 hari dulu. Pembersihan ini juga butuh `plex_database_path` diisi, jadi hanya berjalan di tempat Plex ada di host ini, dan zurg yang menjalankan mount-nya sendiri (`rclone_enabled` dengan `mount_path` diisi). zurg membaca database itu dengan program `Plex SQLite` yang dipasang Plex, dan menemukannya di lokasi yang dipakai installer Plex di Linux, macOS, dan Windows. Jadi `plex_database_path` adalah satu-satunya kunci yang perlu kamu atur:

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
Tetap pakai tanda kutip tunggal. Di dalam tanda kutip ganda, YAML membaca backslash sebagai escape. Atur `plex_sqlite_binary` hanya untuk Plex yang dipasang di tempat lain, misalnya Plex 32-bit: `'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`.
+++

Ganti `YOU` dengan nama user kamu. zurg tidak mengembangkan `~` maupun `%LOCALAPPDATA%`. Pembersihan mencocokkan path yang disimpan Plex dengan `mount_path`, dan itu sudah menangani huruf drive seperti `Z:` (`pkg/utils/path_within.go`).

Untuk mematikan penghapusan dan mengosongkan sampah sendiri, tulis `plex_trash_sweep_every_mins: 0`. Itu penolakan yang eksplisit, dan berbeda dari sekadar tidak menulis kuncinya.

Kunci itu hanya mematikan penghapusan dari zurg sendiri. Kunci itu tidak mengembalikan pengaturan ke Plex. Dalam mode `guard`, zurg tetap menulis `autoEmptyTrash` menjadi off, jadi Plex tetap tidak akan mengosongkan sampahnya setelah pemindaian, dan entri akan terus menumpuk tanpa ada yang membersihkannya. Gunakan sakelar di dasbor atau `plex_settings_ignore` untuk mengembalikan pekerjaan itu ke Plex.

### Keamanan — dikoreksi di bawah `guard` dan `enforce` {#safety--corrected-under-guard-and-enforce}

Ini kehilangan data, bukan waktu, makanya kebijakan default menuliskannya alih-alih hanya memberi peringatan. Hanya `autoEmptyTrash` yang dikirim dengan nilai yang merusak. Tiga yang lain sudah default sesuai keinginan zurg, dan ada di sini untuk menangkap operator yang mengaktifkannya.

| Preferensi | Default Plex | Yang diinginkan zurg | Alasan |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | Plex mengosongkan tempat sampahnya setelah setiap pemindaian. Jika mount sebentar tidak bisa dibaca saat pemindaian sedang menelusurinya, setiap file terbaca sebagai terhapus dan Plex menghapusnya secara permanen, alih-alih membiarkannya di tempat sampah untuk kembali bersama mount. |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | Pembaruan berbasis event melewatkan perubahan yang benar-benar terjadi di sini. Pohon zurg berubah di sisinya sendiri, yang tidak pernah melewati kernel lokal, jadi tidak ada event yang dimunculkan dan library diam-diam menjadi usang. Event yang tetap datang adalah tulisan yang dibuat *melalui* mount, yang masuk saat sebuah direktori masih disusun. |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | Partial scan berjalan berdasarkan event yang sama, jadi ia terpicu oleh tulisan yang masuk lewat mount, tepat saat direktori setengah tertulis, dan tidak pernah terpicu oleh perubahan di sisi remote yang sebenarnya butuh pemindaian. |
| `ButlerTaskBackupDatabase` | `1` | `1` | Backup database harian adalah satu-satunya hal yang bisa memulihkan library yang sudah dihapus Plex. |

Dua alasan `FSEvent` ditulis ulang setelah diukur, di setiap platform tempat zurg di-mount. Tulisan sebelumnya menyebut bahwa mount FUSE "tidak mengeluarkannya dengan andal, sehingga ini memicu pemindaian pada momen yang tidak diminta siapa pun". Kedua bagian itu salah.

Diukur pada 2026-09-05, setiap platform diamati dengan API yang memang dipakai media server-nya, terhadap mount rclone yang direktori backing-nya bisa diubah langsung. **A** adalah tulisan yang dibuat melalui mount. **B** adalah file yang sama muncul di sisi seberang, seperti saat pohon zurg berubah sendiri.

| Platform | Mount | Diamati dengan | A: melalui mount | B: berubah di sisi seberang |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **tidak ada event** |
| Docker | mount yang sama di-bind-mount ke dalam container | inotify, di dalam container | empat yang sama, terlihat di dalam container | **tidak ada event** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **tidak ada event** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **tidak ada event** |

Setiap platform mengirimkan A, dan kontrol pada filesystem native (APFS, NTFS) dalam run yang sama menghasilkan event yang sama, jadi watcher-nya bekerja. Tidak ada platform yang mengirimkan B, padahal file itu sudah terlihat lewat mount setelah cache direktorinya kedaluwarsa.

Jadi mode kegagalannya kebalikan dari yang diklaim: pembaruan berbasis event terpicu saat tulisan datang *melalui* mount, misalnya impor \*arr yang mendarat di direktori yang masih disusun, dan tidak pernah terpicu untuk perubahan di sisi remote, yang justru alasan utama untuk memindai. Bukan berarti event tidak andal. Masalahnya, event melaporkan separuh yang salah dari apa yang terjadi di mount debrid.

### Bandwidth — dikoreksi hanya di `enforce` {#bandwidth--corrected-under-enforce-only}

Masing-masing ini membuat Plex men-decode seluruh file untuk hasil yang tidak pernah dilihat siapa pun. Tidak masalah di penyimpanan lokal, tetapi di mount debrid setiap byte berarti satu request ke provider, dan ini jalan di seluruh library. Analisis yang outputnya *memang* terlihat, seperti preview saat scrubbing, gambar chapter, volume leveling, dan sonic analysis, justru ada di tier taste di bawah, tempat `enforce` tidak akan menyentuhnya.

| Preferensi | Default Plex | zurg maunya |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### Selera — selalu dilaporkan, tidak pernah dikoreksi {#taste--always-reported-never-corrected}

Setiap opsi ini punya fitur di baliknya, jadi zurg hanya memberi tahu berapa harganya dan membiarkan pilihannya di tangan Anda. Mematikannya tanpa diminta akan menghilangkan sesuatu yang bisa dilihat pengelola, dan itu bukan keputusan zurg, sehebat apa pun penghematan bandwidth-nya. Untuk dua yang pertama, opsi yang lebih murah tetap mempertahankan fiturnya dan memindahkan pekerjaannya ke jendela pemeliharaan. Untuk sisanya, pilihannya adalah antara fitur itu atau bandwidth.

| Preferensi | Default Plex | Saran zurg | Alasan |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` atau `never` | `asap` men-decode setiap file begitu masuk, di luar jendela pemeliharaan. `scheduled` tetap mempertahankan tombol Skip Intro dan memindahkan pekerjaannya ke jendela tersebut. |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` atau `never` | Sama, untuk Skip Credits. |
| `GenerateBIFBehavior` | `never` | `never` | Men-decode seluruh video untuk membuat strip gambar yang muncul saat scrubbing. Pemutaran tidak memerlukannya. |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | Men-decode file untuk mengambil satu frame per chapter, untuk gambar di samping setiap entri dalam daftar chapter. |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | Men-decode seluruh audio setiap file untuk mengukurnya, untuk menyeimbangkan volume antar track dan judul. |
| `MusicAnalysisBehavior` | `scheduled` | `never` | Men-decode setiap track. Banyak file kecil, jadi ini jumlah permintaan yang bisa membuat akun kena pembatasan laju. Ini memberi analisis suara: campuran lagu serupa dan visualiser. |

### Jendela pemeliharaan {#the-maintenance-window}

zurg tidak menyentuh `ButlerStartHour`/`ButlerEndHour`, karena tidak ada jam yang cocok untuk semua orang. Bagian ini layak diatur secara manual: Plex secara default menggunakan 02:00–05:00, dan jika jendela waktunya bertabrakan dengan jam saat orang menonton, setiap tugas perawatan jadi terhambat. Apa pun yang lolos di tingkat bandwidth akan berjalan di dalam jendela ini.

### Menghentikan pass yang sedang berjalan {#stopping-a-pass-already-in-flight}

Mengubah preferensi hanya menghentikan run *berikutnya*, bukan yang sedang berjalan. Plex Media Server akan memunculkan ulang child scanner-nya, jadi mematikannya tidak ada gunanya:

+++ Linux dan macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
Di Windows PowerShell 5.1, `curl` adalah nama lain dari `Invoke-WebRequest`, jadi ketik `curl.exe`.
+++

Atur `$TOKEN` ke Plex token kamu dulu: `TOKEN=your-token` di shell, atau `$TOKEN = 'your-token'` di PowerShell.
