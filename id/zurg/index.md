# zurg

zurg menyatukan akun debrid dan library Usenet kamu dalam satu folder virtual. zurg tidak menyimpan video lokal apa pun. Tidak ada yang diambil sampai player memintanya. Remux 60 GB tidak memakan 60 GB ruang disk lokal.

Empat tampilan untuk library yang sama:

| Endpoint | Untuk |
|---|---|
| `/dav/` | WebDAV, yang di-mount oleh rclone |
| `/http/` | Browser direktori HTML |
| `/infuse/` | Varian WebDAV yang menyesuaikan keunikan Infuse |
| `/strm/` | URL bertanda tangan di dalam file `.strm`, untuk player yang butuh URL, bukan mount |

## Pengaturan {#setup}

Jalankan zurg di mesin kamu.

- [Linux](setup/linux.md) — FUSE 3 dan auto-start systemd
- [Docker](setup/docker.md) — host Linux dengan mount yang terlihat dari host
- [macOS](setup/macos.md) — macFUSE dan auto-start launchd
- [Windows](setup/windows.md) — WinFsp dan task huruf drive

## Penyedia {#providers}

Arahkan zurg ke sebuah akun. Setiap halaman membahas kredensial dan entri `config.yml`. Contohnya menggunakan Docker. Instalasi binary memakai entri config yang sama. Lihat [Pengaturan](setup/index.md) untuk perintahnya.

| Halaman | Yang berbeda dari halaman ini |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | Pemilihan per file, `__downloads__`, pilihan host CDN, token `.strm` terpisah |
| [TorBox](providers/torbox.md) | Satu permintaan per refresh library, dan batas slot aktif, bukan batas bandwidth |
| [AllDebrid](providers/alldebrid.md) | Daftar file datang dari endpoint tersendiri, jadi pemindaian pertama terisi bertahap |
| [Premiumize](providers/premiumize.md) | Transfer yang sudah selesai ditambah file cloud yang tertinggal, dengan folder tetap utuh |
| [Debrid-Link](providers/debridlink.md) | Daftar seedbox memuat semua file, dan tidak ada pengecekan cache |
| [Offcloud](providers/offcloud.md) | Ukuran dicek di server pengiriman, path folder dari metadata cache |
| [Usenet](providers/usenet.md) | Tipe `nzb` sebagai entri provider. Tanpa token, sebagai gantinya direktori pemantau |
| [Batasan TorBox](providers/torbox-limits.md) | Angka terukur di balik throttling TorBox, dan cara zurg mengatur ritmenya |
| [Server berita TorBox](providers/torbox-news-server.md) · [Server berita ElfHosted](providers/elfhosted-news-server.md) | Apa itu akun Usenet bawaan, dilihat dari sisi jaringan |

[Halaman bersama](providers/index.md) berisi tiga cara menambahkan akun di Docker dan aturan yang diterapkan oleh pemuat config.

## Panduan {#guides}

Mengelola library

- [Usenet](guides/usenet.md) — backend `nzb` dari awal sampai akhir: akun news, NZB, mount, Plex
- [Sonarr & Radarr untuk Usenet](guides/sonarr-radarr.md) — pencarian \*arrs dan jawaban zurg sebagai SABnzbd, jadi impor cukup rename, bukan download
- [Sonarr & Radarr untuk torrent](guides/sonarr-radarr-torrents.md) — sama, dengan zurg menjawab sebagai qBittorrent; Prowlarr juga
- [Pencarian zurg untuk Sonarr & Radarr](guides/sonarr-radarr-fetch.md). Radarr dan Sonarr menyimpan daftarnya, dan zurg yang mencari serta menempatkan release-nya. Tidak ada indexer atau download client di keduanya.
- [`__magic__`](guides/magic.md) — satu-satunya direktori yang layout-nya disimpan, jadi kamu sendiri yang mengaturnya, dengan library difile berdasarkan judul untuk Kodi dan Plex
- [Renaming](guides/renaming.md) — rename release atau file di mana saja di library. Move akan ditolak dan halaman itu menjelaskan alasannya
- [Plex](guides/plex.md) — apa yang dilakukan zurg dengan token Plex, dan apa yang sengaja tidak dilakukannya
- [Jellyfin](guides/jellyfin.md) — sama, untuk Jellyfin
- [rex with zurg](../rex/with-zurg.md) — media server untuk aplikasi Plex yang tidak memiliki file apa pun, diisi oleh zurg dari akun debrid kamu. Selengkapnya di [rex](../rex/index.md)
- [Addon Stremio](guides/stremio.md) — Stremio mencari lewat indexer kamu sendiri, dan memutar langsung dari backend Usenet
- [Watchlist dan Seerr](guides/acquisition.md) mengambil apa yang kamu minta lewat indexer kamu sendiri
- [Watchlist Plex](guides/plex-watchlist.md) adalah sisi Plex dari itu
- [Daftar wanted DMM](guides/dmm-wanted.md) mengambil apa yang kamu tekan Want di DMM, tanpa perlu setup apa pun lagi
- [Local libraries](guides/local-libraries.md) memutar daftar release bersama lewat akun kamu sendiri
- [Android dan Google TV](guides/android.md) menjalankan seluruh library di ponsel atau TV box

## Migrasi {#migrating}

Pindahkan pustaka yang sudah ada ke zurg tanpa perlu mengunduh ulang atau memindai ulang.

- [Dari AltMount](migrate/altmount.md)
- [Dari decypharr](migrate/decypharr.md)
- [Dari InfiniDysk](migrate/infinidysk.md)
- [Dari nzbdav](migrate/nzbdav.md)
- [Dari streamnzb](migrate/streamnzb.md)

## Referensi {#reference}

- [Konfigurasi](reference/config.md) — setiap opsi di `config.yml`
- [Command line](reference/cli.md) berisi daftar setiap perintah dan flag yang diterima binary
- [Outbound identity](reference/outbound-identity.md) menjelaskan apa yang dikatakan zurg tentang dirinya kepada layanan yang dipanggilnya
- [MCP server](reference/mcp.md) memungkinkan agen AI mengendalikan zurg melalui Model Context Protocol
- [Tags](reference/tags.md) — apa yang diterapkan pada torrent, dan alasannya
- [Changelog](reference/changelog.md) — apa yang berubah dan kapan

## Internal {#internals}

Cara zurg dibangun, hasil pengukurannya, dan catatan desain di balik bagian-bagian yang rumit.

- [Arsitektur](internals/architecture.md): bentuk keseluruhannya, dan invariant yang gampang rusak
- [Baseline debrid](internals/debrid-baseline.md): berapa biaya zurg dan seberapa cepat terasa di RD, AD, dan TorBox
- [Siklus hidup torrent](internals/torrent-lifecycle.md): apa yang dilaporkan tiap akun saat sebuah grab berjalan, diukur langsung
- [Kontrak klien SABnzbd](internals/sabnzbd-client-contract.md): bentuk pasti yang diharapkan Sonarr dan Radarr
- [Pembersihan sampah Plex](internals/plex-trash-sweep.md) · [Regresi timeout stream](internals/stream-timeout-regression.md) · [UI/UX konfigurasi direktori](internals/uiux.md)
- [Pengujian E2E](internals/e2e-test.md) · [Catatan API Real-Debrid](internals/realdebrid-behavior.md)
- [Kontrak klien qBittorrent](internals/qbittorrent-client-contract.md) · [Cache persisten](internals/persistent-caches.md)
- [Penamaan](internals/naming.md) · [Penolakan rclone move](internals/rclone-move-refusal.md)

---

zurg dibagikan ke sponsor: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Sponsor](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
