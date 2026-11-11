# Fitur & Kemampuan Jellyfin {#jellyfin-features--capabilities}

## Konfigurasi & Penyimpanan {#configuration--storage}
- Kunci konfigurasi ([`config.md`](../reference/config.md), `config.example.yml`): `jellyfin_server_url` (string, default `""`), `jellyfin_token` (string, default `""`). Keduanya dikomentari di `config.example.yml` dan tidak ada di `config.simple.yml`. `mount_path` harus diisi, kalau tidak pemindaian media (termasuk Jellyfin) akan dinonaktifkan (`pkg/scan/scanner.go`).
- Nilainya disimpan di `config.yml` lewat dashboard (`updateConfigFileAtomic`); tidak ada file data Jellyfin terpisah. Field-field dan helper `Get`/`Set`-nya ada di `zurgConfig` di `internal/config/config.go`; `ZurgConfigV1` (`internal/config/filters.go`) menyematkan struct itu secara inline.

(Terjemahan sebelumnya ditolak: code span berbeda (`Get`). Pertahankan struktur persis seperti aslinya.)

## Autentikasi & Validasi Server (QuickConnect) {#authentication--server-validation-quickconnect}
- Alur QuickConnect di Dashboard:
  - `/jellyfin/check-server` memastikan server bisa dijangkau lewat `System/Info/Public` dan melaporkan versi/nama serta ketersediaan QuickConnect (`HandleJellyfinCheckServer`, `pkg/jellyfin/auth.go:CheckServerReachable/CheckQuickConnectEnabled`).
  - `/jellyfin/auth` memulai QuickConnect (`InitiateQuickConnect`), membuat sesi autentikasi yang terikat cookie (`pkg/jellyfin/auth_session.go`), lalu menjalankan polling di latar belakang.
  - `/jellyfin/auth/status` mengembalikan status selesai/error sambil melakukan polling ke `/QuickConnect/Connect` + `/Users/AuthenticateWithQuickConnect` (`PollForQuickConnectAuth`, 60 percobaan dengan jeda 5 detik sebelum timeout).
  - `/jellyfin/server` menyimpan URL/token server ke config, menginisialisasi ulang klien Jellyfin, dan merespons dengan success/warning jika inisialisasi ulang gagal (`HandleJellyfinServerSelect`).
  - `/jellyfin/logout` menghapus config, menginisialisasi ulang scanner tanpa Jellyfin, dan membuang status dashboard yang tersimpan di cache (`JellyfinStatusFetcher.ClearCache`).
- Manajer sesi autentikasi melacak sesi QuickConnect, menyimpan secret/code/token/info user, dan membersihkannya setelah 10 menit (dicek setiap 5 menit). Manajer ini juga menyediakan getter yang thread-safe (`pkg/jellyfin/auth_session.go`; instance global ada di `auth_global.go`).
- Helper QuickConnect di `pkg/jellyfin/auth.go` mengirim header `Authorization: MediaBrowser …` standar dan berjalan dengan verifikasi TLS dinonaktifkan agar bisa menerima sertifikat self-signed (`newHTTPClient`). Klien scan tidak begitu: `mediabrowser.NewCore` membuat `http.Client` biasa dengan timeout 30 detik (`pkg/mediabrowser/core.go`). Akibatnya, server di balik sertifikat self-signed bisa dipasangkan dan divalidasi dengan baik, tetapi panggilan section/refresh-nya gagal karena masalah TLS.
- Endpoint validasi token `/System/Info` dipakai untuk memastikan kredensial sebelum disimpan (`ValidateToken`).

## Kapabilitas Klien Jellyfin (`pkg/jellyfin/client.go`) {#jellyfin-client-capabilities-pkgjellyfinclientgo}
- `Client` adalah cangkang tipis di atas `mediabrowser.Core` yang tertanam (`pkg/mediabrowser/core.go`). Core ini dipakai bersama dengan `pkg/emby` karena kedua server berasal dari basis kode yang sama. Satu-satunya method milik `Client` sendiri adalah `GetSections`. Pemindaian (`ProcessJob`), aktivitas, status server, lifecycle, antrean, header auth, dan pelacakan stuck semuanya datang dari core.
- Auth: panggilan ke Jellyfin mengirim header `Authorization: MediaBrowser … Token="<token>"` yang standar. Client Emby justru mengirim `X-Emby-Token`.
- Lifecycle: `NewClientWithLogger` membuat core (menghapus garis miring di akhir URL). Jika URL *atau* token kosong, ia memberi peringatan dan mengembalikan nil. Setelah itu `StartWorker` menjalankan worker pemindaian dinamis, kecuali `GO_TEST_MODE=1`. `Close` mematikan worker dan antrean.
- Antrean pemindaian: antrean job dinamis + `common.DefaultWorkerConfig`. `GetJobQueueSize` adalah nilai yang dibaca dashboard (lewat `MediaScanner.GetQueueSizes`). `GetJobQueue` hanya stub kompatibilitas yang mengembalikan slice berisi job kosong sebanyak ukuran antrean.
- Deteksi beban dan stuck: `CheckServerLoad` melakukan polling ke `/ScheduledTasks`, memantau task yang sedang berjalan dan namanya mengandung "scan", melacak jumlah stuck per task, lalu melaporkan sibuk saat ada pemindaian yang aktif. `IsJobStuck` menandai task yang melewati ambang stuck.
- Pelacakan aktivitas: `GetRunningTasks` mengembalikan struct `TaskActivity` yang detail, berisi ID, Name, State, Progress (dari `CurrentProgressPercentage`), Description, dan status stuck untuk ditampilkan di dashboard.
- Status server: `GetServerStatus` melakukan polling ke `/Sessions` untuk menghitung sesi streaming yang aktif, transcode (video/audio yang tidak direct), dan penggunaan bandwidth untuk ditampilkan di dashboard.
- Penemuan library: `GetSections` memanggil `/Library/VirtualFolders` dan mengembalikan section dengan ID/Title/Paths (setiap folder dari library)/Type. Setiap section kemudian ditambahkan jumlah item-nya lewat `Items?ParentId=<id>&Recursive=true&Limit=0`.
- Refresh: `ProcessJob` melaporkan setiap path yang berubah dalam satu job sekaligus lewat satu `POST /Library/Media/Updated`. Setiap path di body harus persis seperti yang dilihat server di filesystem-nya sendiri. Job tanpa path akan me-refresh seluruh library dengan `POST /Items/{id}/Refresh`. Method ini mengembalikan `ServerBusyError` saat 503, error "library may have been deleted" saat 404, dan isi response body untuk 4xx/5xx lainnya. `RefreshSection` memasukkan job ke antrean.
- Helper: `FindSectionNormalized` mencocokkan berdasarkan prefix path (yang cocok pertama menang) dan mengembalikan path dengan prefix-nya ditulis ulang sesuai huruf besar/kecil di lokasi library. Pengecekan prefix tidak case-sensitive di macOS dan Windows, dan case-sensitive persis di sistem lain (`pkg/common/pathutil.go`).

## Integrasi Pemindai Media (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Menginisialisasi client Jellyfin saat `mount_path`, URL server, dan token sudah ada; mencatat log keberhasilan dan membiarkan client tetap nil jika gagal. Tidak ada loop retry (berbeda dengan Plex), tetapi reinit manual tetap didukung.
- `TriggerScan` mengirim ke Jellyfin bersama server lain; `triggerJellyfinScan` mencari section lewat `FindSectionNormalized` dengan path yang diawali `mount_path`, lalu mengirim path yang berubah dari setiap section dalam satu request (Plex mengirim satu path per request).
- `GetQueueSizes` mengembalikan panjang antrean Plex/Jellyfin/Emby sekaligus, dan memakai -1 untuk server yang tidak terhubung.
- `ReinitializeJellyfinClient` menutup client yang ada lalu membangunnya ulang dengan konfigurasi terbaru (dipakai setelah autentikasi dashboard dan saat logout).

## Dasbor & Rute {#dashboard--routes}
- Router memasang endpoint Jellyfin berikut: `/jellyfin/check-server`, `/jellyfin/auth`, `/jellyfin/auth/status`, `/jellyfin/server`, `/jellyfin/logout`, `/jellyfin/scan/{sectionID}`, `/jellyfin/scan-all` (`internal/handlers/router.go`).
- Modal dashboard (templates/scripts) menjalankan QuickConnect, menampilkan status dan error, serta menyimpan atau menghapus kredensial. Ukuran antrean, kartu library dengan tombol scan, dan aktivitas server ditampilkan di `dashboard.tmpl`.
- `JellyfinStatusFetcher` (`internal/handlers/dashboard/mediabrowser_status.go`) mengisi JSON dashboard dari cache latar belakang, jadi halaman tidak perlu menunggu. Ia memvalidasi token, menandai konektivitas, mengisi daftar library (ID/Name/Paths/Type/ItemCount), dan mengumpulkan aktivitas task yang sedang berjalan serta jumlah sesi, transcode, dan bandwidth. Aktivitas dan sesi diperbarui setiap 30 detik. Fetch penuh, termasuk library, berjalan setiap 5 menit. `response.go` menyajikan salinan cache (`JellyfinServerInfo`, `jellyfin_queue_size`).
- Endpoint scan library (`HandleJellyfinScan`, `HandleJellyfinScanAll`) memasukkan antrean refresh seluruh library tanpa path, untuk satu section library atau semua section, seperti yang dilakukan padanan Plex-nya. Endpoint ini mengembalikan 503 jika tidak ada klien Jellyfin yang dikonfigurasi (`internal/handlers/dashboard/dashboard.go`).
- `jellyfin_server_url` dan `jellyfin_token` juga bisa ditulis lewat handler update konfigurasi generik, jadi keduanya bisa diatur tanpa modal QuickConnect (`handlers["jellyfin_server_url"]`/`["jellyfin_token"]` di `dashboard.go`; `updateJellyfinServerURL` di `scripts.tmpl`).

## Efek Samping Library & Penyegaran {#library-side-effects--refresh}
- Setiap efek samping pada library (perubahan penugasan direktori, sinkronisasi STRM, perbaikan) memanggil `MediaScanner.TriggerScan`, yang mencakup refresh Jellyfin saat klien terhubung (`internal/torrent/hooks.go:TriggerLibrarySideEffects` → `pkg/scan/scanner.go`).
- Pemanggilan yang sama juga lebih dulu menghapus entri dircache VFS rclone yang terdampak, sehingga scan Jellyfin melihat perubahannya, bukan daftar file yang tersimpan di cache selama berjam-jam.
- Sinkronisasi STRM dan hook `on_library_update` berjalan bersama pemicu scan (hook-nya di-debounce 500ms dan dideduplikasi); Jellyfin menerima path library yang diberi awalan mount_path di dalam job refresh.

## Lain-lain {#miscellaneous}
Emby adalah integrasi bersaudara dengan config key sendiri (`emby_server_url`, `emby_token`) dan core bersama yang sama, tetapi tidak ada QuickConnect. Kamu login dengan API key, atau pilih user lalu masukkan password (`/emby/users`, `/emby/auth`). Kartu dashboard-nya menampilkan library dengan tombol scan (`/emby/scan/{sectionID}`, `/emby/scan-all`), serta activities dan sessions seperti di Jellyfin (`EmbyStatusFetcher`).
- `pkg/jellyfin/windows_path_test.go` memastikan path Windows tidak masuk ke URL request dan sampai ke body tanpa berubah. `find_section_test.go` mencakup pencocokan prefix.
