# Penyedia {#providers}

Provider adalah satu akun yang dipakai zurg untuk membangun library-nya. Setiap akun adalah satu entri di bawah `providers:` dalam `config.yml`. Mau jalankan satu akun atau enam, terserah kamu. Rilisan yang ada di lebih dari satu akun hanya ditampilkan sekali, dan dibaca dari akun mana pun yang sedang bisa menyajikannya.

| Layanan | `type` | Halaman |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

Tiga halaman membahas lebih dalam dari sekadar pengaturan. [Batasan TorBox](torbox-limits.md) berisi angka terukur di balik throttling TorBox. [Server berita TorBox](torbox-news-server.md) dan [Server berita ElfHosted](elfhosted-news-server.md) mencatat apa sebenarnya akun Usenet yang disertakan dengan paket-paket tersebut. Nilai dulu dari situ sebelum menghabiskan slot provider untuk salah satunya.

Semua halaman di sini mengasumsikan instalasi container dari [Pengaturan Docker](../setup/docker.md). `~/zurg` adalah direktori compose di host. `/config` adalah direktori yang sama dilihat dari dalam container. Hanya ada satu `config.yml` dan kedua nama itu mengarah ke file yang sama.

Pada instalasi binary di Linux, macOS, atau Windows, [Pengaturan](../setup/index.md) mencantumkan apa yang menggantikan `docker compose restart zurg` dan baris `setup`. Cara pengecekannya juga sama. Jalankan dari folder zurg. Baca `logs/zurg.log` sebagai ganti `docker compose logs` (`Get-Content logs\zurg.log -Tail 100 -Wait` di PowerShell). Jalankan `./zurg doctor` (`.\zurg.exe doctor`) tanpa `--working-dir /config`. Tampilkan mount kamu sendiri, bukan `/zurg_mnt/zurg`: `/mnt/zurg`, `/Volumes/Zurg`, atau `Z:\`, kecuali kamu sudah mengubah `mount_path`. Di Windows PowerShell 5.1, ketik `curl.exe`, bukan `curl`.

## Tiga cara menambahkan akun {#three-ways-to-add-an-account}

Yang mana yang kamu pakai tergantung apakah `config.yml` sudah ada atau belum.

### Pada instalasi baru gunakan setup {#on-a-fresh-install-use-setup}

`zurg setup` menanyakan provider mana yang ingin dikonfigurasi dan hanya meminta kredensialnya. Akun hanya ditulis **jika belum ada `config.yml`**. Jika dijalankan lagi nanti, perintah ini akan memperbarui instalasi tanpa menyentuh akun yang sudah ada.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Pemilihnya menerima nomor atau nama, dan bisa memilih beberapa sekaligus.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

Apa pun yang Anda ketik tidak masuk ke compose file atau riwayat shell. Token langsung disimpan di `config.yml` dan file tersebut hanya bisa diakses oleh pemiliknya.

### Pada instalasi yang sudah ada gunakan Dashboard {#on-an-existing-install-use-the-dashboard}

Buka `http://localhost:9999/config/` lalu pakai **Add provider** di bawah Essentials.
Pilih tipenya. Tempel token-nya. Klik Save. Dashboard akan menulis entri itu kembali ke `config.yml` yang sama, di samping file compose kamu.

Perubahan provider perlu restart dulu sebelum berlaku. Dashboard akan memberi tahu, dan restart-nya cukup pakai satu perintah.

```bash
docker compose restart zurg
```

### Atau edit config.yml secara manual {#or-edit-configyml-by-hand}

File `~/zurg/config.yml` ada di host. Tambahkan entry-nya lalu restart.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` di dalam container adalah `/zurg_mnt/zurg`, dan compose file harus melakukan bind
`/zurg_mnt:/zurg_mnt:rshared` supaya mount sampai ke host. Detailnya ada di halaman [Panduan setup Docker](../setup/docker.md). Ini satu-satunya bagian dari instalasi container yang berbeda dengan instalasi binary.

## Instalasi tanpa pengawasan {#unattended-installs}

Setiap provider punya flag token-file dan variabel lingkungan. Ulangi `--provider` untuk setiap akun yang ingin kamu pakai.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | Flag | Variabel lingkungan |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` atau `TOKEN` atau `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` dengan `--nntp-host` dan `--nntp-username` | `NNTP_HOST` dan sejenisnya |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` tidak pernah otomatis terdeteksi hanya dari `TORBOX_TOKEN` atau `--torbox-token-file`. Berikan `--provider torbox_nzb`.

Dengan `--non-interactive` dan tanpa `--provider` sama sekali, setup akan memakai variabel mana pun dari daftar di atas yang sudah diatur.

!!!warning Hanya Real-Debrid yang diisi oleh container yang berjalan
Daemon zurg sendiri membaca `TOKEN`, `RD_TOKEN`, dan `MOUNT_PATH` saat proses yang membuat `config.yml` dijalankan. Hanya itu daftarnya. `TORBOX_TOKEN` dan lainnya dibaca oleh `zurg setup`. Menaruh salah satunya di blok `environment:` compose lalu menjalankan container tidak akan berpengaruh apa-apa. Jalankan setup atau tambahkan akun lewat Dashboard.
!!!

## Yang diterima setiap entri {#what-every-entry-accepts}

| Kunci | Fungsinya |
|---|---|
| `type` | Wajib. Salah satu dari delapan tipe di atas. |
| `name` | Defaultnya `type`. Dipakai untuk membedakan dua akun di layanan yang sama. |
| `token` | Kunci API. Tidak dipakai oleh `nzb`. |
| `disabled` | Menonaktifkan akun tanpa menghapus kredensialnya. |
| `watchlist` | Menandai akun yang akan dicoba lebih dulu untuk torrent baru. |
| `add_torrents` | Atur `false` dan akun tetap melayani, tapi tidak pernah diberi torrent baru. |
| `warm_connections` | Jumlah koneksi yang tetap terbuka per host, supaya membaca file tidak perlu membuka koneksi baru setiap kali. |

Deskripsi lengkap dan semua yang lain ada di [referensi konfigurasi](../reference/config.md#accounts).

## Aturan yang diterapkan loader {#rules-the-loader-enforces}

- Nama harus unik. Dua akun Real-Debrid butuh `name: rd-main` dan `name: rd-backup`, kalau tidak pemuatan akan gagal.
- Nama `e` dipakai khusus untuk routing link `.strm`, jadi pilih nama lain.
- Paling banyak satu entri boleh mengatur `watchlist: true`.
- Kombinasi `watchlist: true` dan `add_torrents: false` pada entri yang sama tidak diterima.
- Hanya satu entri `nzb` atau `torbox_nzb` yang aktif yang didukung. News server tambahan dimasukkan di bawah `nntp.servers` pada entri `nzb`.
- Kalau semua entri dinonaktifkan, pemuatan gagal.
- Premiumize, Debrid-Link, dan Offcloud menolak `download_tokens` dan `strm_link_token` yang berbeda dari `token`. ID file mereka milik satu akun, jadi akun kedua harus berupa entri kedua.

## Cek apakah sudah berhasil {#check-it-worked}

Mulai dengan log dan diagnostic.

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` itu wajar di Docker, karena Compose yang mengatur auto-start. Warning tidak membuat doctor gagal. Yang membuatnya gagal hanya `FAIL`.

Lalu cek akunnya langsung dari Dashboard atau dari shell.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` berarti kredensialnya sudah terautentikasi. Nama di path adalah `name` akun. Defaultnya sama dengan `type`. Tambahkan `-u user:pass` kalau kamu sudah mengisi `username` di `config.yml`. Kalau tidak, Dashboard dan API-nya terbuka di port yang kamu publish.

Terakhir, cek library di mount.

```bash
ls /zurg_mnt/zurg/__all__/
```

Setiap akun yang dikonfigurasi punya direktori `__<name>__`. Isinya semua yang dimiliki akun itu, dan semua read dipaksa lewat akun tersebut. `__torbox__/Some.Release/` hanya men-stream dari TorBox, tidak dari tempat lain. Folder akun tunggal tidak ditampilkan di listing root mount, karena isinya sama dengan `__all__`. Path HTTP dan WebDAV langsung seperti `/http/__torbox__/` masih bisa diakses. Lewat mount, path itu tidak lagi bisa di-resolve. Jadi arahkan library atau script apa pun yang memakai `__<name>__` ke `__all__`.

Library yang besar butuh waktu saat pertama kali dimuat. Sampai prosesnya selesai, `/dav/movies/` mengembalikan 503 dan mount mungkin tidak menampilkan apa-apa.

## Menjalankan beberapa akun {#running-several-accounts}

Urutan hanya penting di satu tempat. Urutan daftar `providers:` menentukan urutan akun yang dicoba untuk menerima add. Akun dengan `watchlist: true` dicoba lebih dulu di mana pun posisinya. Untuk listing dan membaca, urutan tidak punya keistimewaan apa pun.

Sebelum mengarahkan media server ke hasilnya, ada dua hal yang perlu kamu tahu.

- Rilis yang sama muncul di direktori yang sudah difilter **dan** di bawah setiap direktori `__<name>__` yang menyimpannya. Arahkan Plex atau Jellyfin ke sebagian mount, jangan ke seluruhnya, atau mereka akan memindai konten yang sama beberapa kali.
- Tidak ada failover diam-diam di dalam direktori `__<name>__`. File yang mati di satu akun akan menghasilkan 404 di sana dan akan diputar lewat direktori akun lain. Bagian mount yang lain tetap menyajikannya dengan normal.
