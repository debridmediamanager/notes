# TorBox hosted Usenet

`type: torbox_nzb`

Dengan paket TorBox Pro, TorBox mengurus bagian Usenet untuk kamu. zurg
mengirim file `.nzb` di watch directory-nya ke akun TorBox kamu. TorBox
mengambil setiap rilis, memperbaikinya, lalu menyajikannya seperti unduhan
TorBox lainnya. zurg menampilkan apa yang diambil TorBox di mount, berdampingan
dengan konten lainnya. Tidak perlu akun news server, dan tidak ada artikel
Usenet yang di-decode di mesin kamu.

Ini bukan [news server TorBox](torbox-news-server.md). Itu adalah login untuk
backend `nzb`, yang membaca artikel sendiri dan dibahas di [Usenet](usenet.md).
Itu juga bukan entri `torbox`. Entri itu menampilkan torrent kamu, dan dibahas
di halaman [TorBox](torbox.md).

## Yang kamu butuhkan {#what-you-need}

- **Paket TorBox Pro.** Paket yang lebih rendah tidak menerima NZB.
- **API key TorBox Anda** dari [torbox.app/settings](https://torbox.app/settings).
  Ini adalah key yang sama dengan yang dipakai entri `torbox`.
- **zurg nightly terbaru.** Nightly memerlukan sponsorship yang aktif.
- **Host biasa.** zurg+rex Android, yaitu Plex server di ponsel Anda, tidak memiliki backend `torbox_nzb`. Di perangkat Android, putar NZB yang dihosting TorBox melalui TorBox Cast di DMM atau addon Kodi sebagai gantinya.

## Atur konfigurasinya {#configure-it}

Entri ini memakai `token`; tidak ada blok `nntp`. `watchlist` tidak bisa diatur di sini, karena akun NZB tidak bisa menambahkan torrent.

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

Pada instalasi container yang baru, simpan kunci kamu di `~/zurg/secrets/torbox` dulu, lalu biarkan setup membacanya.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

Pada instalasi yang sudah punya `config.yml`, kamu juga bisa pakai **Add provider** di Dashboard di `http://localhost:9999/config/` dan pilih `torbox_nzb`. Restart zurg dengan cara mana pun.

```bash
docker compose restart zurg
```

## Cara NZB masuk {#how-nzbs-get-in}

Semua yang masuk ke entri `nzb` masuk ke sini dengan cara yang sama. Aksi TorBox di DMM adalah satu-satunya jalur yang melewati zurg.

- **Direktori pantau.** Taruh file ke `nzbs/` di samping config (`~/zurg/nzbs/` di host, `/config/nzbs/` di dalam container). zurg akan mengirimkannya ke TorBox.
- **Sonarr dan Radarr** lewat endpoint yang kompatibel dengan SABnzbd milik zurg. Lihat [Sonarr and Radarr for Usenet](../guides/sonarr-radarr.md).
- **Akuisisi.** Indexer Newznab, DMM Wanted, dan daftar pantauan akan mengambil konten ke sini. Lihat [Acquisition](../guides/acquisition.md).
- **Aksi TorBox di DMM** pada hasil Usenet mengirim NZB langsung ke TorBox. Rilisnya juga muncul di zurg, tapi zurg tidak menyimpan NZB untuknya, jadi tombol repair tidak bisa mengambilnya lagi setelah TorBox menghapusnya.

Posting yang tidak bisa diambil TorBox akan dilaporkan ke Sonarr atau Radarr sebagai unduhan gagal. Klien akan memasukkan rilis itu ke daftar blokir dan mencari lagi.

## Yang berbeda dari `nzb` {#what-differs-from-nzb}

- **Tanpa akun berita.** Tidak ada jatah koneksi yang perlu diukur dan tidak ada retensi penyedia yang perlu dipertimbangkan. Spool milik TorBox sendiri yang menentukan apa saja yang bisa diambil dari sebuah post.
- **Tidak ada artikel yang di-decode di sini.** TorBox mengambil seluruh rilis. Pengambilan artikel, perbaikan PAR2, cache artikel, dan pemeriksaan artikel tidak berlaku; cache disk untuk arsip yang sudah di-decode tetap berlaku. Sebuah grab dianggap selesai jika TorBox sudah mengambilnya.
- **Cache 30 hari.** Rilis yang sudah diambil orang lain di TorBox langsung siap. TorBox menghapus rilis 30 hari setelah TorBox menyimpannya di cache. Tombol repair di dashboard mengambilnya lagi dengan mengirim NZB-nya sekali lagi, jadi simpan file-filenya di `nzbs/`. zurg tidak pernah mengirim ulang sendiri, karena TorBox menganggap pengunduhan ulang tanpa pengawasan sebagai penyalahgunaan.
- **Satu slot per NZB yang sedang berjalan.** Post yang masih diambil TorBox memakai satu dari slot aktif paket Anda. Entri `torbox` pada key yang sama memakai slot yang sama untuk torrent-nya.
- **60 post per jam.** TorBox menerima sebanyak itu NZB baru per jam untuk setiap key. Backlog besar, misalnya seluruh isi `nzbs/` saat pertama kali dijalankan, akan habis dalam hitungan jam.

## Satu akun NZB per instance {#one-nzb-account-per-instance}

Sebuah instance hanya boleh berisi satu entri `nzb` atau satu entri `torbox_nzb`, tidak boleh keduanya. Jika keduanya ada, setiap file di `nzbs/` akan terdaftar dua kali. Untuk menjalankan keduanya, beri jenis yang satunya lagi instance sendiri dengan direktori kerja sendiri. Jika `dmm_api_key` dipasang di kedua instance, [matikan sumber `dmm-wanted` di salah satu](../guides/dmm-wanted.md#two-zurgs-on-one-key), atau setiap judul Wanted akan diambil dua kali. Keduanya bisa berjalan berdampingan dengan akun debrid Anda.

Addon Stremio dari zurg mengirim pilihannya ke akun NZB mana pun yang dimiliki instance. Dengan `torbox_nzb`, rilisan yang sudah ada di TorBox akan mulai diputar dalam waktu tunggu addon, selama tidak ada post NZB lain yang sedang menunggu. Rilisan yang belum di-cache harus selesai diproses di TorBox dulu, dan itu membutuhkan waktu lebih lama dari yang biasanya ditunggu pemutar.

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

Kalau cuma ada satu akun, folder miliknya sendiri tidak ditampilkan di daftar root mount,
jadi mount hanya menampilkan file yang sama di bawah `__all__`. Nama direktori mengikuti
nama entri, dan secara default namanya sama dengan tipenya.
