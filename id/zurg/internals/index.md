# Internal {#internals}

Cara zurg dibangun. Apa yang diukur dari zurg. Catatan desain di balik bagian-bagian yang rumit.
Ditulis untuk kamu yang akan mengubah kodenya. Tidak ada yang ada di sini yang dibutuhkan untuk menjalankan zurg.

## Bentuknya {#the-shape-of-it}

| Halaman | Isinya |
|---|---|
| [Architecture](architecture.md) | Bentuk keseluruhan sistem dan invarian yang gampang rusak. Mulai dari sini. |
| [Naming](naming.md) | Cara sebuah rilis dan file-filenya mendapat nama yang ditampilkan di mount. |
| [Persistent caches](persistent-caches.md) | Apa yang disimpan di disk antara restart dan apa dampaknya. |
| [Directory config UI/UX](uiux.md) | Penilaian desain di balik editor direktori. |

## Apa yang diukur {#what-was-measured}

| Halaman | Isinya |
|---|---|
| [Debrid baseline](debrid-baseline.md) | Berapa biaya zurg dan seberapa cepat rasanya di Real-Debrid, AllDebrid, dan TorBox. |
| [Torrent lifecycle](torrent-lifecycle.md) | Apa yang dilaporkan tiap akun saat sebuah grab berjalan, dicatat langsung. |
| [Real-Debrid API notes](realdebrid-behavior.md) | Arti link, pemilihan file, dan arti sebenarnya dari cached. |

## Kontrak yang harus dipenuhi zurg {#contracts-zurg-has-to-satisfy}

| Halaman | Isinya |
|---|---|
| [SABnzbd client contract](sabnzbd-client-contract.md) | Bentuk pasti yang diharapkan Sonarr dan Radarr dari SABnzbd. |
| [qBittorrent client contract](qbittorrent-client-contract.md) | Sama, tetapi untuk qBittorrent. |
| [plex_api.json](../../internals/plex_api.json) | Permukaan Plex API mentah yang digunakan zurg dalam kodenya. 1.2 MB. |

## Hal-hal yang salah {#things-that-went-wrong}

| Halaman | Isinya |
|---|---|
| [Plex trash sweep](plex-trash-sweep.md) | Menyelaraskan sweep dengan pandangan zurg sendiri tentang apa yang rusak. |
| [Stream timeout regression](stream-timeout-regression.md) | Stream lewat proxy yang berhenti bertahan saat pembacaan lama. |
| [rclone move refusal](rclone-move-refusal.md) | Impor kosong setelah sebuah backend menolak MOVE, dan patch-nya. |

## Pengujian {#testing}

- [Pengujian E2E](e2e-test.md) menjelaskan apa saja yang diuji oleh suite end to end dan berapa biaya untuk menjalankannya.

Apa yang dilakukan sebuah layanan tertentu dan apa batasannya ada di [Providers](../providers/index.md), bukan di sini.
