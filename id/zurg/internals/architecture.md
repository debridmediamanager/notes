# Arsitektur {#architecture}

Peta tentang apa itu zurg, bagaimana bagian-bagiannya saling terhubung, dan mengapa setiap package ada. Ditujukan untuk seseorang yang akan mengubah kode: dokumen ini menjelaskan keputusan-keputusan penting dan invariant yang mudah dilanggar tanpa disadari.

Detail per package ada di `doc.go` masing-masing package. Dokumen ini adalah tingkat di atasnya: bentuk keseluruhan, dan alasan di balik bentuk tersebut.

## Apa itu zurg {#what-zurg-is}

Sebuah daemon Go yang menampilkan pustaka torrent dari akun debrid sebagai filesystem virtual. Ia tidak menyimpan media apa pun. Setiap read diubah menjadi HTTP GET dengan range ke CDN penyedia saat permintaan dibuat.

Ia tidak punya konten sendiri dan menolak PUT, jadi dari sisi byte ia bersifat read-only. Ada dua write yang diterima: rename, yang hanya menyimpan nama dan tidak menyentuh akun mana pun ([renaming.md](../guides/renaming.md)), dan DELETE, yang menghapus release dari setiap akun yang memilikinya. `__magic__` menambahkan write ketiga di dalam satu namespace, yaitu layout tersimpan ([magic.md](../guides/magic.md)). Ini berlaku di semua tempat dalam namespace itu kecuali di `__magic__/__all__` dan folder release yang langsung ada di dalamnya, yaitu cermin hasil komputasi yang diimpor oleh download client.

Empat tampilan untuk pustaka yang sama:

| Endpoint | Untuk |
|---|---|
| `/dav/` | WebDAV, yang di-mount oleh rclone |
| `/http/` | Penjelajah direktori HTML |
| `/infuse/` | Varian WebDAV dengan penyesuaian untuk keanehan Infuse |
| `/strm/` | Signed URL di dalam file `.strm`, untuk player yang butuh URL, bukan mount |

rclone melakukan FUSE-mount pada `/dav/`, sehingga Plex, Jellyfin, Emby dan Infuse melihat pohon direktori biasa.

Masalah desain di seluruh proyek ini adalah celah antara apa yang dijanjikan filesystem (path yang stabil, `stat` instan, byte sesuai permintaan) dan apa yang diberikan API debrid (JSON dengan rate limit, link yang cepat kedaluwarsa, dan tanpa semantik filesystem sama sekali). Hampir setiap package ada untuk menutup satu bagian dari celah itu.

```
media player
    │
    ├─ rclone FUSE ──► /dav/  ──┐
    └─ direct HTTP ──► /http/ ──┤
                                ▼
                    internal/handlers  (chi router, auth, routing)
                                │
                internal/dav ───┤─── internal/htmlindex     (listings)
                                │
                                ▼
                    internal/torrent   (the library, in memory)
                                │  resolve link for this file
                                ▼
                    internal/universal (byte path, proxy/redirect, RAR)
                                │
                                ▼
                    internal/debrid    (Provider dispatch)
                                │
        ┌───────────┬───────────┼────────────┬──────────┐
        ▼           ▼           ▼            ▼          ▼
   realdebrid    torbox     alldebrid       nzb ──► nntp ──► par2
        └───────────┴───────────┘            (Usenet, no debrid service)
                    │
              internal/rdclient  (host rotation, rate limit, retry, DNS)
```

## Urutan boot {#boot-sequence}

`cmd/zurg` adalah CLI Cobra yang tipis (serve, version, network-test, clear downloads/torrents, kontrol mount, download requirements). Semua hal yang sebenarnya terjadi ada di `internal/app.go`, yang `MainApp`-nya sengaja dibuat sebagai satu fungsi yang mudah dibaca:

1. Buat direktori runtime (`logs`, `data`, `data/info`, `dump`, `strm`, `nzbs`) dan logger-nya.
2. `ensureConfigAndRequirements` — muat config, dan unduh `ffprobe` dan `rclone` jika belum ada (`internal/requirements`). Saat pertama kali dijalankan tanpa config, program akan menulis config default lalu berhenti, kecuali token diambil dari environment.
3. Inisialisasi `strmlink` lebih awal, supaya direktori data yang tidak bisa ditulis langsung dilaporkan sekarang, bukan sebagai file `.strm` yang berhenti bisa di-resolve setelah restart berikutnya.
4. Jalankan **network latency test** ke download host Real-Debrid (`internal/rdclient`), atau muat hasil cache-nya dari disk jika masih cukup baru. Tes ini meranking host CDN dan dipakai nanti saat rotasi host.
5. Bangun setiap provider yang dikonfigurasi dari registry, rakit menjadi `debrid.Set`, dan simpan handle bertipe pada Real-Debrid pertama. Dashboard, halaman hosts, dan network test tetap berbicara dengan RD secara spesifik.
6. Buat `TorrentManager`, yang langsung memuat library cache dari disk di background lalu me-refresh-nya.
7. Pasang router chi, jalankan HTTP server, lalu jalankan rclone setelah server mulai menerima koneksi.
8. Tunggu SIGINT/SIGTERM/SIGQUIT. Saat sinyal diterima, hentikan HTTP server, hentikan layanan Plex, dan unmount rclone, masing-masing dengan batas waktu 20 detik.

`ZURG_PPROF=1` mengaktifkan pprof di `127.0.0.1:6060`. Hanya loopback, karena profiling instance yang sedang berjalan adalah satu-satunya cara untuk melihat penyebab CPU saat lonjakan scan, tapi endpoint ini tidak boleh bisa diakses dari jaringan.

## Lapisan 1 — Config {#layer-1--config}

`internal/config` adalah satu-satunya sumber kebenaran; hampir semua package lain membaca `ZurgConfigV1`. Typed getter menerapkan default saat sebuah field bernilai nol, jadi pemanggil tidak perlu mengecek apakah field itu ada atau tidak.

Bagian terbesarnya adalah `filters.go`: bahasa filter AND/OR bertingkat yang menetapkan setiap torrent ke satu atau lebih **direktori virtual**. Di sinilah daftar torrent yang datar berubah menjadi `movies/`, `shows/`, `anime/`, `recent/`.

Kondisinya mencakup nama torrent (`regex`, `contains`, `not_regex`), ukurannya, file-filenya (`any_file_inside_regex`, `any_file_inside_size_gte`), tag-tagnya (`tags_match_any`, `tags_missing_all`), umurnya (`added_within_hours`, `added_after`), properti turunan (`has_episodes`, `is_music`), dan akun asal torrent (`provider`, `not_provider`). Ada juga aturan tampilan per direktori: `only_show_the_biggest_file`, batas minimum dan maksimum ukuran.

Regex yang dipakai untuk tiap torrent di setiap pass penetapan dikompilasi sekali di level package. Alasannya, `MustCompile` per pemanggilan ternyata memakan cukup banyak waktu saat startup.

Config bisa diedit langsung dari dashboard. `UpdateConfigFileAtomic` melakukan edit per key dan tidak menulis ulang seluruh file, jadi komentar dan key yang tidak dikenal tetap aman.

## Lapisan 2 — Abstraksi backend {#layer-2--backend-abstraction}

`internal/debrid` adalah tulang punggungnya. Package ini memiliki tipe domain yang dipakai oleh semua package lain — `Torrent`, `TorrentInfo`, `File`, `Download`, `User` — dan interface `Provider` yang diimplementasikan oleh setiap backend.

### Provider dan capabilities {#provider-and-capabilities}

`Provider` dibuat tetap kecil: daftar torrent, ambil info, hapus, resolve tautan, verifikasi, ambil byte, dan laporkan status akun. Apa pun yang mungkin tidak dimiliki sebuah layanan dengan wajar dibuat sebagai **antarmuka kapabilitas opsional** yang di-type-assert oleh pemanggil, lalu pemanggil turun level kalau fitur itu tidak ada:

| Interface | Apa yang ditambahkan | Siapa yang membutuhkannya |
|---|---|---|
| `MagnetAdder` | menambah lewat hash, memilih file, jumlah slot aktif | repair |
| `TorrentRestarter` | coba ulang torrent yang gagal di tempat | repair, strategi termurah |
| `HostRotator` | menukar pool host CDN | tes jaringan, halaman `/hosts` |
| `DownloadLister` | daftar terpisah untuk unduhan hoster | direktori `__downloads__` |
| `ArchivePasswordKeeper` | password untuk arsip sebuah rilis | hanya Usenet |
| `PremiumMonitor` | sisa waktu paket | peringatan saat startup |

Selain itu, `Capabilities` adalah deskripsi diri provider. Isinya bukan apa yang bisa dilakukan provider, melainkan batas-batas yang harus dipatuhi saat menjalankannya. Ini ada karena perilaku library zurg berkembang mengikuti bentuk Real-Debrid, dan kalau bentuk itu di-hardcode, setiap backend lain akan jadi rusak atau boros.

Dua flag ini sudah benar-benar mengatur perilaku:

- **`ListIncludesFiles`**: daftar torrent sudah memuat detail per file. Ini membuat scan library dari kondisi awal (cold) berubah dari satu panggilan API per torrent menjadi hanya satu panggilan total. Ini perbedaan paling mahal antar backend.
- **`StoredLinksCanRot`**: tautan yang tersimpan bisa mati padahal torrent-nya masih terlihat sehat, jadi tautan harus diprobe. Ini sifat Real-Debrid dan cukup mahal. Pada backend yang membuat URL sesuai permintaan, tidak ada yang perlu diprobe. Melewati tahap ini adalah bedanya antara scan yang gratis dan scan yang memicu lockout untuk seluruh akun.

Sisanya (`ServesLinksLocally`, `MaxActiveSlots`, `MaxConcurrentRequests`, `AddsPerHour`, `ContentExpires`, `SupportsFileSelection`) dideklarasikan oleh setiap backend dan dibaca oleh kode generik. Nilai nol sengaja dibuat sebagai pembacaan yang paling konservatif, jadi provider yang lupa mengisi sebuah field akan mendapat perilaku hati-hati, bukan banjir request. Provider yang sama sekali tidak bisa di-resolve oleh zurg akan jatuh ke `unknownProviderCaps` di `internal/torrent/providers.go`. Di situ jawaban hati-hati tersebut ditulis sekali saja, alih-alih di setiap call site.

Ada satu bentuk lagi yang tidak diwakili oleh kedua flag tadi: daftar AllDebrid tidak memuat file, tetapi endpoint per-torrent-nya menerima *batch* id. Ini ditangani di dalam provider, bukan lewat kapabilitas, karena yang berubah hanya cara provider menggunakan request-nya sendiri. Refresh generik tetap meminta satu torrent per waktu dan tidak perlu tahu apa-apa soal ini.

### Set

`Set` adalah semua provider yang sudah dikonfigurasi, sesuai urutan di config. Set ini dipakai oleh torrent manager, handler, dan dashboard sebagai pengganti client tertentu. Ada dua pola akses yang penting: **fan-out**, saat sebuah operasi dijalankan ke setiap akun (misalnya refresh library), dan **dispatch**, saat sebuah operasi harus sampai ke satu akun yang memiliki torrent tersebut (delete, resolve, repair). Set ini juga menyimpan state kesehatan/ketersediaan akun.

### Link cache

`LinkCache` menyimpan URL yang sudah di-resolve dengan kunci **berdasarkan token**, bukan hanya berdasarkan link. URL yang dibuat dari satu token hanya valid untuk kuota token itu, jadi ketika sebuah token kena batas bandwidth, semua entry-nya harus dibuang sekaligus dan tidak boleh dipakai lagi dengan token berikutnya dalam rotasi. Entry kedaluwarsa berdasarkan timestamp `Generated`, bukan waktu entry dimasukkan, jadi link yang diisi dari daftar unduhan milik provider akan kedaluwarsa sesuai jadwal provider.

### Backend-backend {#the-backends}

| Paket | Apa itu | Yang perlu diketahui |
|---|---|---|
| `internal/realdebrid` | Real-Debrid, backend aslinya | Tiga klien HTTP terpisah: API dengan pembatasan laju, unrestrict dengan pembatasan laju, dan download dengan rotasi host. Timestamp waktu Paris dinormalisasi di batas paket dan tidak pernah bocor keluar darinya. `DownloadTokenManager` mengganti token saat satu token kedaluwarsa. |
| `internal/torbox` | REST TorBox | Memakai REST dengan `bypass_cache=true`, bukan WebDAV TorBox, karena tampilan WebDAV tertinggal 5–15 menit dari kondisi sebenarnya. Tidak ada tautan per file, jadi tautan dibuat secara sintetis sebagai `torbox://<torrent-id>/<file-id>`. Tautannya tetap sama setelah restart dan mudah dibaca di log, sedangkan URL CDN biasa yang memuat API key tidak. Ada dua pembatas yang bertumpuk: 300/menit sesuai dokumentasi, dan pembatas yang jauh lebih ketat untuk `requestdl`. Lihat [torbox-limits.md](../providers/torbox-limits.md). |
| `internal/alldebrid` | AllDebrid v4.1 | POST dengan form-encoded. Kegagalan logis datang sebagai HTTP **200** dengan `status:"error"`, jadi status HTTP tidak bisa dijadikan patokan apakah sebuah panggilan berhasil. File ada di balik `/magnet/files`, yang menerima batch, sehingga pencarian yang bersamaan digabung menjadi satu permintaan. Pohon file bertingkat diratakan secara depth-first, dan urutannya itu krusial. |
| `internal/nzb` | Usenet, sama sekali bukan layanan debrid | File NZB di `nzbs/` diubah menjadi torrent. Pembacaan mengambil artikel dan melakukan yEnc-decode saat dibutuhkan. Tautannya berbentuk `nzb://<nzb-id>/<file-index>` dan disajikan secara lokal, jadi `DownloadFile` membuat respons HTTP sendiri, bukan mem-proxy satu. |
| `internal/nntp` | Klien Usenet minimal | Connection pool dibatasi oleh jatah koneksi akun, dengan BODY/STAT berdasarkan message id dan yEnc decode. Satu koneksi hanya mendapat sebagian kecil dari throughput yang bisa dicapai, jadi pembacaan sebuah file dibagi ke seluruh jatah koneksi. |
| `internal/par2` | PAR2 / Reed-Solomon di atas GF(2^16) | Saat sebuah artikel sudah hilang dari server, recovery volume milik rilis itu sendiri membangun ulang byte yang dibawa artikel tersebut. Prosesnya mahal dengan cara tertentu: perhitungannya butuh setiap slice yang masih ada dari setiap file yang tercakup, sekali saja. Karena itu prosesnya dijalankan sebagai background job, satu rilis dalam satu waktu, dan menghasilkan patch rentang byte yang dipakai pembaca sebagai pengganti bagian yang kosong. |
| `internal/rdclient` | HTTP low-level bersama | Rotasi host di antara endpoint CDN yang diurutkan berdasarkan latensi, pembatasan laju dengan token-bucket, retry dengan backoff, dukungan proxy, DNS kustom, pemaksaan IPv4/IPv6, dan preferensi CDN berbasis geo-pin. `IPRepository` mengelola tes jaringan beserta cache-nya di disk. |

`internal/nzb` adalah bukti bahwa abstraksinya berhasil. Paket ini mengimplementasikan antarmuka yang sama di atas direktori lokal dan news server. Hal ini bisa berjalan karena kontrak sebenarnya dari antarmuka adalah *"jawab GET dengan rentang (ranged) menggunakan bytes"*, bukan *"proxy sebuah CDN"*.

### Menambahkan backend {#adding-a-backend}

Paket baru, implementasikan `debrid.Provider`, panggil `debrid.Register` di `init`, lalu tambahkan blank import di `internal/app.go`. Tidak ada yang berubah di `internal/debrid`.

## Lapisan 3 — Library {#layer-3--the-library}

`internal/torrent` adalah inti dari zurg dan paket terbesarnya. `TorrentManager` menyimpan seluruh library dalam peta konkuren `cmap` untuk pembacaan tanpa lock, menetapkan torrent ke direktori dengan mengevaluasi filter di config, me-resolve dan men-cache link, serta menjalankan background job.

### Persistence

Setiap entri ditulis ke `data/<name>.zurgtorrent` sebagai JSON, dan info per-torrent
di-cache di `data/info/`. Saat restart, data dimuat dari disk dan langsung siap dipakai,
lalu di-refresh di belakang layar. Ini penting karena scan dari nol dibatasi oleh
rate-limit, bukan CPU. Torrent yang sudah tidak ada di akun bisa
diarsipkan ke `dump/` dan ditampilkan sebagai direktori `__dump__`
(`load_dumped_torrents`).

Status yang tidak bisa dibangun ulang dari mana pun (config, setiap zurgtorrent, penyimpanan `__magic__` di `data/local/`, dan NZB sumber di `nzbs/`) disimpan dalam satu file `.zurgbackup` yang di-stream.
`zurg backup` membuatnya (begitu juga halaman Backup & Restore di dashboard), dan `zurg restore-backup <file>` mengekstraknya
ke working directory. `internal/backup` mengatur formatnya. Manifest adalah
entri pertama, jadi restore akan memvalidasi isi file sebelum menulis apa pun.

Nama direktori yang dicadangkan: `__all__`, `__unplayable__`, `__dump__`,
`__downloads__`, dan satu per akun sebagai `__<provider-name>__`.

### Torrent vs TorrentCopy

Satu rilis bisa ada di lebih dari satu akun. zurg hanya menampilkannya sekali. Pembagiannya begini:

- **Fakta konten milik entri** (`Torrent`): nama, hash, file apa saja yang ada, tag, IMDB id, rename.
- **Fakta akun milik salinan** (`TorrentCopy`): torrent id yang dibuat akun itu, link yang dibagikannya, status rusak miliknya sendiri, dan penghitung retry-nya.

File id khususnya berbeda di tiap akun. Real-Debrid memberi nomor file dalam sebuah torrent dan menandai sebagian file sebagai terpilih. TorBox hanya mencantumkan file yang sudah diunduhnya dan memberi nomor dengan caranya sendiri. Karena itu `FileSource` menyimpan `FileID` untuk tiap provider. Repair membangun pilihannya dari id salinan yang sedang diperbaikinya. Kalau kamu membaca id akun yang salah, file yang salah akan ikut ditambahkan lagi.

Salinan disimpan sesuai urutan di config, dan urutan itu juga menjadi urutan prioritas. Saat membaca, zurg memilih salinan sehat pertama dan pindah ke salinan berikutnya kalau gagal. Menghapus entri akan menghapus semua salinannya. Entri tanpa salinan dianggap tidak ada.

### GetKey harus tetap pure {#getkey-must-stay-pure}

`GetKey` adalah nama sebuah torrent di pustaka virtual: entri direktorinya, nama file `.zurgtorrent`-nya, dan pegangan yang dipakai setiap pencarian. Nilainya **dihitung ulang di setiap pencarian, tidak pernah disimpan**. Artinya, tabrakan nama tidak bisa diselesaikan dengan mengecek apa yang sudah dipakai, karena jawabannya akan berubah seiring perubahan pustaka, dan sebuah torrent bisa jadi tidak bisa ditemukan lagi dengan nama yang dipakai saat ia didaftarkan.

Akhiran hanya dipakai untuk kasus yang lebih jarang, yaitu ketika dua rilis *berbeda* memakai nama yang sama. Akhiran itu berupa tag dari hash konten itu sendiri, dan sama murninya dengan nama itu sendiri. Flag yang mengaktifkannya ditentukan oleh proses refresh, yang bisa melihat seluruh pustaka, lalu disimpan pada torrent.

### Background jobs

| Job | File | Fungsinya |
|---|---|---|
| Refresh | `refresh.go` | Cek setiap akun, gabungkan instance yang terdaftar ke dalam entri, ambil info untuk yang baru, tetapkan direktori, lalu bersihkan entri lama. Memakai pengambilan satu item yang ringan sebagai cek perubahan di antara poll penuh. |
| Repair | `repair.go` | Cari dan perbaiki torrent yang rusak. |
| Downloads | `manager.go` | Refresh daftar hoster-downloads ke dalam `__downloads__`. |
| Network test | `handlers` | Secara berkala menyusun ulang peringkat host CDN. |

Interval tiap job bisa diubah saat runtime lewat channel, jadi perubahan config dari dashboard langsung berlaku tanpa perlu restart. Waktu terakhir job dijalankan disimpan (`data/repair_timestamp`, `data/downloads_timestamp`) supaya restart tidak menjalankan ulang job yang baru saja berjalan.

### Repair

Ini bagian terbesar kedua di paket ini. File membawa state FSM (`ok_file` / `broken_file`, lewat `pkg/fsm`); torrent dan copy punya state sendiri. Saat link berhenti mengirim byte, repair naik bertahap lewat beberapa strategi:

1. **Restart di tempat** (`TorrentRestarter`) — paling murah: tidak ada upload baru, tidak makan slot add, dan torrent tetap memakai id-nya, jadi entri library tetap ada dan tidak dihapus lalu ditemukan lagi. Refresh menjalankannya untuk torrent gagal yang ditemukan di akun, dan hanya pada instance yang memang boleh menangani torrent gagal: `enable_repair` atau `delete_error_torrents`. Kalau keduanya mati, akun dibiarkan apa adanya (`mayRestartFailedTorrents`).
2. **Download ulang file yang rusak** — pilih ulang hanya file yang rusak.
3. **Reinsert** — tambahkan lagi magnet dan ambil link baru.
4. **Archive** — jalan terakhir untuk rilis yang tidak bisa dipulihkan.
5. **Tawarkan ke akun yang tidak memegang rilis itu** (`repair_across_accounts.go`) — tiap layanan punya cache sendiri-sendiri, jadi rilis yang sudah dihapus dari satu akun, atau ditolak karena nama file, bisa di-cache di akun lain. Begitu tidak ada akun pemegang rilis yang bisa memperbaikinya, akun yang dikonfigurasi dan tidak memegang rilis itu ditanya satu per satu, dan yang pertama sudah punya hash-nya akan mengambilnya. Listing setelahnya menggabungkannya ke entri sebagai salinan kedua lewat jalur `absorbCopy` biasa, yang otomatis menghapus verdict entri. Selalu hanya cached-only, lewat `AddIfCached` dan tidak pernah lewat `restrict_repair_to_cached` — add yang harus diambil dulu oleh akun akan dibatalkan dan dihapus lagi, jadi ini tetap repair dan bukan download ulang. Akun yang tidak menjawab akan di-backoff dari satu hari sampai sekitar dua minggu, dan satu sweep hanya membuat paling banyak sepuluh tawaran. Itulah yang membuatnya terjangkau dijalankan tanpa diminta terhadap library berisi rilis yang sudah divonis rusak.

Selain itu ada exponential backoff, batas retry per copy (`RepairCycles`, `AssignRetries`, disimpan permanen supaya batasnya tetap berlaku setelah restart), gate budget add per jam dari `Capabilities.AddsPerHour`, pengecekan slot aktif, deduplikasi lewat antrean berbasis set, dan heuristik untuk satu sweep yang membaca rentetan kegagalan hoster-unavailable sebagai satu outage provider, bukan N torrent rusak. Verdict tidak bisa diperbaiki dicatat per copy dan hanya naik ke entri saat *setiap* copy punya verdict itu. Error permanen dari Real-Debrid tidak berarti apa-apa untuk copy TorBox.

Operator bisa memaksa repair secara manual. Status paksa disimpan di torrent, bukan di context, karena permintaan yang datang di tengah sweep akan diparkir di antrean dan diambil nanti di bawah context sweep itu sendiri. Tombol ini juga sampai ke langkah 5, dan urutannya begini: pertama ia menghapus semua verdict pada rilis itu, jadi akun yang memegangnya dicoba lagi persis seperti sebelumnya, dan tawaran hanya jalan kalau percobaan itu gagal. Karena verdict-nya dihapus, torrent yang disebut namanya memenuhi syarat saat sweep mengumpulkan entri yang sudah divonis rusak, dan baru divonis rusak lagi oleh repair yang baru saja berjalan, jadi ia dikumpulkan setelah repair itu, bukan di dalam loop. Kalau tidak, satu-satunya jalur yang ada orang menunggunya justru jalur yang tidak pernah menawarkan apa-apa.

### Yang lain di dalam package {#everything-else-in-the-package}

`mediainfo.go` (analisis ffprobe, yang memberi data durasi/codec ke tag), `tags.go`, `rename.go` (rename yang harus tetap ada setelah refresh), `delete.go`, `strm.go` (membuat file `.strm` untuk seluruh library), `hooks.go` (skrip pengguna pada event siklus hidup), `assign_links.go`, `unrestrict.go`, `opensubtitles.go`, `provider_directories.go`, `reset_all.go`.

## Lapisan 4 — Serving {#layer-4--serving}

### Router

`internal/handlers` membangun router chi dan menghubungkan semuanya. Method WebDAV yang tidak standar (`PROPFIND`, `MKCOL`, `MOVE`) didaftarkan ke chi saat `init`. Basic auth membungkus semuanya *kecuali* `version.txt` dan `/ready` (supaya health check tetap jalan), serta endpoint `.strm`. Media player yang membuka `.strm` tidak punya kredensial untuk dikirim, jadi token bertanda tangan di path itulah yang memberi izin.

Ada dua pelajaran routing yang sudah dicatat di komentar dan sebaiknya tidak perlu dipelajari ulang: chi hanya menerapkan path param regex **di dalam satu segmen**. Akibatnya, file yang diakses lewat arsip (`<archive>.rar/<inner>.mkv`) atau direktori bertingkat di dalam arsip itu tidak cocok dengan route mana pun. Keduanya butuh wildcard di akhir. Lalu, path di dalam torrent dibagi antara listing dan download berdasarkan trailing slash, setelah route tidak lagi peduli seberapa dalam path itu.

### Listings

`internal/dav` menghasilkan XML PROPFIND dan menangani DELETE, MOVE (rename, termasuk validasi lintas direktori dan lintas torrent), serta varian Infuse.

`pkg/dav` membuat XML sendiri dengan membangun string yang sudah dioptimalkan, bukan memakai XML marshalling. Paket ini juga mengubah format RFC 3339 ke RFC 1123 yang dibutuhkan client WebDAV, dan meng-escape path untuk URL maupun XML.

`internal/htmlindex` merender pohon yang sama sebagai HTML untuk `/http/`.

Keduanya menerapkan aturan visibilitas yang sama, yaitu hanya file terbesar, batas ukuran, serta status broken/deleted. Keduanya juga menggabungkan arsip RAR multi-volume sehingga hanya volume pertama yang terlihat.

### Jalur byte {#the-byte-path}

`internal/universal` adalah tempat permintaan berubah jadi byte:

- Resolusi link di-deduplicate dengan `singleflight`, jadi seratus pembacaan bersamaan dari file yang sama cuma memakan satu kali resolusi.
- Proxy atau redirect, sesuai `disable_stream_proxy`. Tapi link yang disajikan secara lokal (`ServesLinksLocally`) tidak pernah bisa di-redirect, karena client tidak punya apa-apa untuk dibuka.
- Unrestrict ulang saat link rusak, sampai batas kecil.
- Cooldown per-file untuk error jaringan: 3 error berturut-turut membuat file didiamkan selama 5 menit. Ini yang mencegah host CDN yang tidak bisa dijangkau jadi loop retry tanpa henti.
- Menahan pembacaan sebentar selama jendela rate-limit, bukannya langsung error. Kalau pembacaan dibalas error selama cooldown singkat, satu akun yang kena throttle bisa berubah jadi badai error lewat VFS rclone: waiter yang macet, reader D-state, media server yang ikut hang. Jadi menahan pembacaan itu lebih murah. Kelas cooldown yang lebih panjang tetap gagal cepat.
- Pembukuan bandwidth per-token, dengan counter direset jam tengah malam CET supaya cocok dengan reset traffic harian Real-Debrid.

### Archives

`internal/rarstream` mengurai header RAR4, RAR5 dan ZIP melalui permintaan rentang byte (HTTP 206), membangun peta chunk di seluruh volume, dan menyusun ulang isi satu file secara langsung. **Tidak ada dekompresi**. Hanya data yang disimpan (stored) yang didukung, dan itu yang dipakai rilisan scene. `VolumeKey` dan `IsVolume` menyeragamkan banyak konvensi penamaan multi-bagian (`.part001.rar`, `.r00`, `.rar`) yang dipakai `dav` dan `htmlindex` untuk menggabungkan volume menjadi satu entri. Daftar file di-cache pada torrent dan diberi stempel `ListingVersion` dari parser, sehingga daftar yang dibuat oleh parser berbeda akan dibuang, bukan disajikan.

### STRM

`internal/strmlink` meng-encode dan menandatangani URL yang ada di dalam `.strm`. Skema khusus Real-Debrid yang digantikannya aman hanya karena kebetulan: URL-nya berisi kode download 13 karakter milik RD, jadi memiliki URL itu *adalah* bukti otorisasi. Backend lain mengakses file lewat id yang sangat mudah ditebak (`torbox://17/3`), jadi bentuk yang sama akan membiarkan siapa pun yang bisa menjangkau port membuat URL CDN atas nama akun atau menghabiskan koneksi server news-nya. HMAC atas secret di `data/strm_secret` menutup celah itu. Token yang tidak ditulis oleh zurg tidak akan bisa di-resolve.
Secret harus bertahan melewati proses. Setiap `.strm` yang sudah ditulis hanya akan tetap valid selama kunci penandatanganannya masih ada.

### Dashboard dan manajemen {#dashboard-and-management}

`internal/handlers/dashboard` merender UI web dari template yang di-embed,
di-parse lebih dulu saat startup supaya error sintaks langsung ketahuan, bukan saat ada request.
Halamannya: status torrent live, editor config YAML yang interaktif, latensi host, manajemen direktori, manajemen provider, status koneksi media server, info akun/premium, bandwidth, status rclone, dan statistik Plex "Wrapped".
Pengambil status untuk tiap media server berjalan bersamaan supaya halaman tetap terasa responsif saat dimuat.

`internal/handlers/manage` adalah UI operasi per-torrent: tag, daftar file beserta detail state, pencocokan Plex, rename, delete/restore/force-show per file, bulk delete, dan scan.

Tampilan duplikatnya ada di `internal/duplicates`. `internal/arrinventory` dan `Inventory` reader di samping adapter Radarr dan Sonarr membaca setiap file yang dipegang sebuah \*arr, hanya-baca dan terpisah dari proses akuisisi. `magic.Resolver.HolderOf` melacak path tiap file ke release asalnya, dan package ini mengelompokkan release yang mungkin memegang film atau episode yang sama. Pengelompokan memakai nama, IMDb id, dan history \*arr. Apakah sebuah release sedang dipakai hanya diputuskan dari path yang sudah dilacak.

`internal/static` meng-embed CSS, favicon, logo, dan robots.txt dengan `go:embed`, jadi binary-nya mandiri.

## Lapisan 5 — Mount {#layer-5--the-mount}

`internal/rclone` mengawasi rclone sebagai subproses: ia membangun perintah mount (sebuah WebDAV remote yang mengarah ke `/dav/` milik zurg sendiri),
menjalankan dan menghentikannya, melakukan health-check setiap 30 s dengan backoff restart eksponensial (1 s → 60 s), dan memulai ulang saat gagal.

Port RC sementara di rentang 49152–65535 dipilih saat startup untuk invalidasi cache VFS dan query status. Invalidasi ini penting di dua momen:
sekali saat library yang di-cache selesai dimuat, dan sekali lagi setelah refresh penuh pertama. Kalau tidak, daftar parsial yang diambil mount
saat proses loading akan tetap tersimpan selama `--dir-cache-time`.

Kredensial dikirim lewat environment variable, tidak pernah lewat command line. `Controller` adalah interface yang dipakai handler dan dashboard;
`Runner` dan `Command` mengabstraksi manajemen proses untuk testing.

## Lapisan 6 — Media server {#layer-6--media-servers}

Ada dua hal berbeda yang sama-sama memakai kata "Plex":

- **`pkg/plex`, `pkg/jellyfin`, `pkg/emby`** adalah *klien* media server. Masing-masing memenuhi `common.MediaServerWorker`. `pkg/common` menyediakan siklus hidup job yang dipakai bersama: antrean dinamis tanpa batas, pelacakan percobaan ulang per job, exponential backoff dengan jitter, circuit breaker setelah beberapa kegagalan berturut-turut, dan deteksi job yang macet. Paket ini juga berisi helper path yang menangani case-insensitive APFS di macOS. `pkg/scan` berada di atasnya sebagai `MediaScanner` terpadu. Ia meneruskan job refresh path ke server yang memiliki path tersebut dan melaporkan kedalaman antrean per server.
- **`internal/plex`** berisi perilaku khusus zurg. `Matcher` mencocokkan torrent dengan item library Plex memakai path file, id IMDB, serta identifier TVDb/TMDb. Ia berjalan berkala dalam worker pool dengan metadata yang di-cache, dan mengisi id IMDB yang ditemukan ke torrent.
- **`internal/acquisition`** mengurus antrean akuisisi yang persisten dan executor bersama. Executor ini mengambil NZB dari indexer Newznab dan torrent yang sudah cached dari indexer Torznab. Watchlist Plex, Seerr, Radarr, dan Sonarr adalah source adapter yang mengubah permintaan menjadi target movie, season, atau episode. `data/acquisition.json` menyimpan tenggat percobaan ulang dan progres per target di antara restart. Lihat [sumber akuisisi](../guides/acquisition.md) untuk konfigurasi dan kontrak adapter.

`pkg/mediabrowser` berisi tipe-tipe yang dipakai bersama oleh Emby dan Jellyfin.

## Lapisan 7 — Pendukung {#layer-7--support}

| Package | Fungsi |
|---|---|
| `pkg/fsm` | Dua varian state machine kecil: `FSMWithExternalMutex` untuk saat FSM ada di dalam sesuatu yang sudah di-lock, dan `FSMWithTime` untuk saat FSM butuh lock sendiri dan timestamp transisi (jadi `SinceWhen` bisa menjawab "sudah berapa lama ini rusak"). |
| `pkg/logutil` | Zap dengan output ganda: konsol berwarna dan file yang berputar (10 MB × 20 lewat lumberjack). Tingkat verbosity diambil dari `log_level` di config.yml, lalu ke environment variable `LOG_LEVEL`, dan kalau tidak ada juga ke DEBUG. Levelnya disimpan di `zap.AtomicLevel` yang dipakai bersama, jadi dashboard bisa mengubah level semua logger sekaligus tanpa restart. Termasuk membaca log kembali untuk viewer di dashboard dan untuk Export Logs. |
| `pkg/utils` | Penyimpanan blocked-host, aturan visibilitas file, penyamaran token, deteksi video/audio, penamaan `.strm`, dan `GetZurgBaseURL` (yang menghormati `X-Forwarded-*` saat berada di belakang reverse proxy). |
| `pkg/script` | Menjalankan script lifecycle-event buatan pengguna; PowerShell di Windows, `/bin/sh` di tempat lain. |
| `pkg/dmm` | Client untuk API pencarian debridmediamanager.com, dibatasi 1 request per 2 detik sesuai batas di server. Dipakai oleh pemantau watchlist. |
| `internal/version` | Metadata build yang disisipkan lewat ldflags; juga banner ASCII di `/http/version.txt`. |
| `internal/requirements` | Mengunduh `ffprobe` dan `rclone` yang sesuai platform dari GitHub releases saat pertama kali dijalankan, lalu menulis path *relatif* ke config.yml supaya config tetap portabel. Platform yang tidak didukung cuma memberi peringatan, tidak sampai gagal. |
| `internal/clear` | Menghapus download dan torrent RD secara massal dengan menjalankan web interface memakai auth cookie, diulang terus sampai kosong. |
| `internal/handlers/tmplcache` | Caching template untuk dashboard. |

## Keputusan lintas bagian {#cross-cutting-decisions}

**Kapabilitas daripada `if provider == "realdebrid"`.** Apa pun yang mengasumsikan bentuk Real-Debrid harus ditaruh di balik flag kapabilitas, bukan pengecekan tipe. Aturan inilah yang menjaga torrent manager tetap tidak terikat pada backend tertentu.

**Kontrak interface adalah byte, bukan proxy.** `Provider` tidak pernah menjanjikan CDN remote, hanya bahwa ranged GET bisa dijawab. Itulah sebabnya backend Usenet cocok. Dua tempat asumsi CDN sempat bocor (redirect, dan memberikan URL ke ffprobe, yang butuh sesuatu yang bisa dibuka oleh binary eksternal) sekarang sudah dijaga oleh `ServesLinksLocally`.

**Pairing link berdasarkan posisi itu krusial.** `TorrentInfo.Links[i]` berpasangan dengan file **terpilih** ke-i di `TorrentInfo.Files`. Provider yang tidak bisa membuat link untuk sebuah file harus melaporkannya sebagai *tidak terpilih*, bukan menghilangkannya. Kalau tidak, setiap file berikutnya diam-diam akan mengarah ke link yang salah. Setiap backend wajib menjaga aturan ini.

**Satu torrent hanya milik satu akun.** Setiap pemanggilan yang sampai ke layanan harus dikirim lewat provider milik torrent tersebut (`ProviderFor`, `resolveLink`, `verifyLink`, `DeleteByID`), bukan lewat provider utama. Kalau salah, penghapusan bisa terjadi di akun yang keliru.

**Disk adalah tingkat tersendiri.** Entri `.zurgtorrent`, detail per-torrent di `data/info/`, hasil network-test beserta timestamp-nya, timestamp job, secret penandatanganan STRM, cache listing RAR, dan host yang diblokir. Saat restart, sistem melanjutkan dari kondisi tersimpan, bukan memindai ulang.

**Semuanya diatur kecepatannya.** Token bucket per-provider, batas konkurensi, gerbang penambahan per jam, TTL link, cooldown per-file, dan rate-limit hold. Khususnya di TorBox, resolusi link adalah sumber daya yang paling langka, dan link cache di depannya yang membuat scan library menjadi terjangkau.

**Pembacaan tanpa lock, penulisan dipersempit.** Concurrent map menopang pohon directory/torrent/file. Mutasi dijaga oleh lock per-torrent (`copiesMu`, `tagsMutex`, `operationsMutex`, `archiveCacheMutex`), bukan oleh lock global.

**`rdclient` dipakai bersama, tapi kebijakannya milik Real-Debrid.** Klasifikasi error dan aturan retry-nya berasal dari RD. Ia melaporkan respons non-2xx sebagai error sambil tetap mengembalikan response-nya. Jadi provider yang butuh status, misalnya 429 dengan `Retry-After`, harus memeriksa `resp` sebelum `err`.

(Terjemahan sebelumnya ditolak: code span-nya berbeda (`Retry-After`). Pertahankan struktur persis seperti aslinya.)

## Build, test, deploy

- **Build**: `make build`. Versi, commit, dan waktu build disisipkan lewat
  ldflags ke dalam `internal/version`.
- **Tes unit**: `go test ./...`. Pre-commit menjalankan gofmt, golangci-lint,
  `go test -short`, dan suite kualitas lengkap.
- **Tes integrasi**: `make integration-test`, dimulai dari yang paling murah, dengan
  `refresh_repair` di urutan terakhir karena harus menunggu scan library penuh selesai. Jalankan di host yang sudah punya Go, rclone, FUSE, dan Plex sekaligus. Di tempat lain, tes mount dan Plex akan di-skip dengan jelas tapi tetap exit 0, jadi baca outputnya, jangan cuma lihat exit code. Lihat [e2e-test.md](e2e-test.md).
- **Docker**: build Alpine dua tahap; image runtime menambahkan ffmpeg, rclone,
  fuse3, dan healthcheck.
- **Deploy**: `make deploy USER=… HOST=… DIR=…`, yang menghentikan Plex dan layanan zurg,
  mengganti binary, menunggu `version.txt` merespons 200, lalu menjalankan ulang Plex.

## Di mana mencari dulu {#where-to-look-first}

Komentar di basis kode ini selalu mencatat *mengapa*, biasanya kegagalan yang melatarbelakangi kode tersebut.
Setiap package punya `doc.go`. Kalau kamu mengubah sesuatu, baca dulu `doc.go` milik package itu dan block comment di atas type yang kamu sentuh.
Di sana ada batasan-batasan yang tidak terlihat dari signature-nya.
