# Usenet

`type: nzb`

Usenet adalah tipe provider, bukan layanan debrid. Tidak ada API token dan tidak ada remote library. Kamu memasukkan file `.nzb` ke watch directory dan zurg mengubah setiap file menjadi release. Artikel diambil dari news server kamu dan di-decode pada saat player meminta byte tersebut.

Halaman ini hanya berisi entri provider dan spesifik Docker. Semua hal lain tentang menjalankan Usenet di zurg ada di [Usenet with zurg](../guides/usenet.md). Itu panduan lengkapnya, mulai dari akun news dan NZB sampai mount dan Plex. Baca halaman itu setelah ini.

## Atur konfigurasinya {#configure-it}

Tidak ada `token`. Entri baru dianggap valid kalau ada blok `nntp` dengan host.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

Atur `connections` sesuai dengan yang benar-benar diizinkan paket kamu. zurg membaca dengan jumlah itu
karena satu koneksi hanya membawa sebagian kecil throughput paket. Streaming
memakai seluruh jatah yang tersedia, bukan mengambil satu artikel dalam satu waktu. Kalau melebihi
jumlah yang diizinkan paket, koneksinya akan ditolak.

Pada instalasi container yang baru, setup akan menanyakan semuanya.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

Untuk instalasi tanpa pengawasan, password diambil dari file dan semua yang lain diambil dari flag.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` default-nya true dan `--nntp-port` default-nya 563 dengan TLS atau 119
tanpa TLS.

Pada instalasi yang sudah punya `config.yml`, pakai **Add provider** di Dashboard di `http://localhost:9999/config/` atau edit filenya. Restart dengan cara apa pun.

```bash
docker compose restart zurg
```

## Tempat NZB disimpan di dalam container {#where-the-nzbs-go-in-a-container}

Direktori watch adalah `nzbs/` di sebelah config. Artinya `~/zurg/nzbs/` di host dan `/config/nzbs/` di dalam container. Itu direktori yang sama. Taruh file dari host.

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

Kalau hanya ada satu akun, folder `__nzb__`-nya sendiri tidak ditampilkan di daftar root mount, jadi cari di `__all__`. Direktori watch dibaca sekitar setiap 15 detik. Karena berada di dalam bind `./:/config`, direktori ini tetap aman saat `docker compose pull` dan container dibuat ulang, sama seperti file lainnya.

## Aturan khusus untuk tipe ini {#rules-specific-to-this-type}

- **Hanya satu entri `nzb` yang aktif.** Kalau ada dua, keduanya akan memindai direktori yang sama dan menggandakan setiap rilis. Server berita tambahan sebaiknya ditaruh di bawah `nntp.servers` milik entri itu. Dengan begitu, semuanya melayani library yang sama, bukan salinan kedua. Entri `nzb` di samping entri [`torbox_nzb`](torbox-nzb.md) juga ditolak dengan alasan yang sama.
- **`watchlist: true` ditolak.** Server berita tidak pernah menerima torrent.
- **`add_torrents` diabaikan** dan saat startup akan muncul peringatan tentang hal itu, dengan alasan yang sama.
- **`download_tokens` dan `strm_link_token` tidak berpengaruh.** Tidak ada kredensial yang perlu dirotasi.
- **Direktorinya bernama `__nzb__`** karena namanya mengikuti tipe secara default. Atur `name: usenet` pada entri kalau kamu lebih suka menelusuri `__usenet__`.

## Server berita kedua lebih berguna daripada yang terlihat {#a-second-news-server-is-worth-more-than-it-looks}

Retensi berlaku per provider. Artikel yang sudah habis masa simpannya di satu server sering kali masih ada di server lain.

Tanpa akun kedua, satu-satunya cara memulihkan artikel yang hilang adalah PAR2, dan itu berarti membaca **seluruh release**. Jadi server kedua adalah pembeda antara mengambil satu artikel saja dan membaca ulang semuanya.

Akun tambahan ditaruh di bawah `nntp.servers` pada entri ini, bukan di entri `nzb` kedua. `priority`, `backup`, dan `backbone` menentukan siapa yang ditanya dan dalam urutan apa. Pembacaan dijalankan sesuai total kuota gabungan dari akun-akun yang tidak diberi tanda `backup`. Contoh konfigurasi lengkap dan fungsi setiap kunci ada di [Usenet dengan zurg](../guides/usenet.md#more-than-one-usenet-provider).

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

Dengan hanya satu akun, folder miliknya sendiri tidak ditampilkan di daftar root mount, jadi mount menampilkan file yang sama di bawah `__all__`.

Probe di sini melakukan autentikasi ke news server menggunakan paling banyak satu koneksi dari pool yang sudah ada. Tidak ada account API yang bisa ditanya.

## Saat terjadi masalah {#when-it-goes-wrong}

Dua gejala ini berasal dari entri provider itu sendiri, bukan dari library.

**Pembacaan tersendat dan zurg turun ke satu artikel per waktu.** `pipeline_depth` lebih tinggi dari yang bisa ditangani server. zurg menurunkannya sendiri dan memberi peringatan. Atur ke `1` secara eksplisit untuk server yang tidak bisa menangani beberapa perintah sekaligus.

**Throughput buruk pada link dengan latency tinggi.** Biarkan `socket_receive_buffer_kb` tidak diatur. Buffer yang di-pin adalah buffer yang berhenti di-tune oleh kernel. Di Linux, itu membuat receive window tertahan di sekitar 64 KiB dan memakan sebagian besar throughput akun.

Semua hal lain ada di baris tabel troubleshooting pada [Usenet with zurg](../guides/usenet.md#troubleshooting). Koneksi yang ditolak, streaming yang lambat, provider yang tidak pernah dihubungi, dan edit Dashboard yang menghapus `nntp.servers` juga ada di sana.
