# Server berita ElfHosted {#elfhosted-news-server}

ElfHosted menyertakan akun Usenet dengan paket addon Stremio-nya dan menyebutnya Usenet Essential. Halaman ini mencatat apa sebenarnya server itu. Semua di bawah diukur pada 2026-09-04 dari satu host. Akunnya sendiri tidak bisa diukur, karena satu-satunya kredensial yang pernah dipublikasikan ElfHosted sudah mati, dan itu temuan pertama.

## Apa yang terjawab di jaringan {#what-answers-on-the-wire}

`news.elfhosted.com` mengarah ke `94.232.116.124` dan berbicara NNTP over TLS 1.3 di 563 dengan
sertifikat Let's Encrypt untuk `news.elfhosted.com`. Sertifikat itu hanya memuat satu nama itu
saja dan diterbitkan pada 2026-08-17. Server yang sama juga menjawab plaintext di 119 dengan salam
yang sama. Salamnya adalah `200 Welcome to elfhosted`.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

Itu string `nntpswitch2` yang sama dengan yang dilaporkan [pembaca TorBox](torbox-news-server.md). Daftar ini adalah daftar tanpa autentikasi, jadi berakhir di `AUTHINFO USER` bukan `POST`. `HELP` menjawab tanpa kredensial dan mencantumkan seluruh perintah termasuk `POST` dan `IHAVE` dan `XPAT` dan `XGTITLE`, jadi `POST` yang tidak muncul berasal dari sesinya, bukan dari servernya.

Tiga perintah bekerja sebelum autentikasi dan tidak ada perintah lain yang bisa.

| Perintah | Jawaban |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` dan `LIST` dan `STAT` dan `POST` | `480 Authentication required for command.` |

## Siapa yang menjalankannya {#who-runs-it}

Di halaman TorBox, operatornya harus ditebak dari kedekatan alamatnya. Yang ini tidak perlu. `news.elfhosted.com` ada langsung di dalam blok reader Abavia.

`94.232.116.124` ada di `94.232.112.0/21`, `AS48345 AS-ABAVIA`, terdaftar atas nama Abavia S.r.l. dari San Marino. Reverse sweep pada `94.232.116.0/24` mengembalikan 79 nama. Empat puluh lima di antaranya menjawab NNTP di port 563, dan semuanya melaporkan `nntpswitch2 (local-dev)` dengan daftar capability yang identik byte per byte dan urutannya sama. Router perbatasan milik Abavia sendiri juga ada di /24 yang sama, begitu juga feeder XS News, web host, dan nameserver-nya.

| Alamat | Reader | Sapaan |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHosted berjarak empat alamat dari Easyusenet, tujuh dari XS News, dan dua belas dari TorrentClaw. TorrentClaw adalah addon Stremio lain yang berjalan di depan platform yang sama.

Tidak ada multiplexing berbasis nama. Menghubungi alamat dengan servername `reader.xsnews.nl`, atau dengan nama yang sama sekali tidak ada, tetap mengembalikan sertifikat yang sama dan sapaan `200 Welcome to elfhosted` yang sama. Satu alamat untuk setiap brand.

TorBox tidak ada di blok ini. TorBox berada di `78.152.55.171` pada `AS3257 GTT` di Belanda. Jadi atribusi ke ElfHosted lebih kuat dari keduanya. TorBox menjalankan perangkat lunak yang sama tapi bertetangga dengan brand dari keluarga ini. ElfHosted menjalankannya di ruang alamat milik Abavia sendiri.

**Terukur** adalah sidik jari perangkat lunak, kepemilikan alamat, sertifikat, dan tidak adanya multiplexing berbasis nama. **Disimpulkan** adalah bahwa spool di baliknya memang milik Abavia sendiri, bukan campuran yang dirakit ElfHosted. Tidak ada yang di jaringan yang bisa membedakan keduanya tanpa kredensial.

## Kredensial yang dipublikasikan sudah mati {#the-published-credential-is-dead}

Pada 2025-12-20 ElfHosted mengumumkan akses NNTP yang disertakan dengan NzbDav sebagai proof of concept selama dua bulan, bekerja sama dengan penyedia infrastruktur Usenet yang tidak disebutkan namanya. Mereka juga mempublikasikan satu kredensial bersama di pengumuman tersebut.

| Field | Seperti yang dipublikasikan, 2025-12-20 |
|---|---|
| Host | `news.elfhosted.com` |
| Port | 563 SSL |
| Username | `elfie` |
| Password | `elfie` |
| Connections | 100 |
| Cost | gratis sampai Februari 2026 |

Kredensial itu sudah diatur sebelumnya di NzbDav untuk pengguna baru. Pengumumannya juga bilang bahwa kerja sama ini akan ditinjau ulang setelah proof of concept selesai. Dan memang sudah selesai. Kredensialnya sekarang tidak bisa dipakai untuk autentikasi lagi.

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

Di software ini, `482 Invalid username or password` memang jawaban untuk akun yang benar-benar sudah tidak ada, bukan batas koneksi, yang justru menampilkan `482 too many connections for your user`. Waktu responsnya juga cocok. Lima kali dial dengan username yang tidak pernah ada dan dua kali dial dengan `elfie` memberikan penolakan yang sama dengan pola waktu yang sama.

| Dial | Jawaban | Waktu |
|---|---|---|
| Username acak, lima kali dial | `482 Invalid username or password` | median 2066 ms, kisaran 2043 sampai 2070 |
| `elfie` dan `elfie`, dua kali dial | `482 Invalid username or password` | 2043 ms dan 2212 ms |

Kredensial yang sudah dicabut dan username yang memang tidak pernah dibuat tidak bisa dibedakan di sini, baik dari kodenya maupun dari waktu responsnya. Sekitar dua detik adalah waktu yang dibutuhkan software ini untuk menolak, dan TorBox reader juga begitu.

Jadi angka 100 connections itu menggambarkan penawaran yang sudah berakhir. Ini satu-satunya angka yang pernah dipublikasikan ElfHosted tentang server ini, dan tidak berlaku untuk apa pun yang bisa kamu beli sekarang. Paket Usenet Essential kemungkinan memberikan kredensial per pelanggan, tapi hal itu tidak bisa dicek dari luar.

Pengumuman yang sama juga mempublikasikan endpoint Newznab internal di `elfhosted-internal.zyclops` yang menerima API key apa pun dan bisa difilter untuk menampilkan hasil yang diketahui sehat untuk backbone tertentu. Endpoint inilah yang dimaksud ElfHosted store saat bilang bahwa paket Usenet sudah termasuk indexer. Endpoint ini menampilkan sinyal ketersediaan dan kesehatan, bukan konten. Kata mereka sendiri, ini "crystal ball" untuk kesehatan infrastruktur, bukan "treasure map". Paket tetap membutuhkan indexer asli di samping endpoint ini.

## Yang tidak bisa diukur {#what-could-not-be-measured}

Semua yang menentukan apakah sebuah slot provider layak diisi. Semuanya butuh kredensial.

| Properti | Status |
|---|---|
| Batas koneksi | tidak diketahui, angka 100 hanya berlaku untuk proof of concept yang sudah dipensiunkan |
| Retensi | tidak pernah dipublikasikan |
| Grup di `LIST ACTIVE` | butuh auth |
| Jendela nomor artikel | butuh auth |
| Cakupan dibandingkan backbone lain | butuh auth |
| Throughput satu koneksi | butuh auth |
| Posting | server menawarkan `POST`, tapi status akunnya tidak diketahui |

Trial tujuh hari harganya satu dolar dan sekaligus memberi kredensialnya. Menjalankan sweep 531 message id yang sama seperti di [halaman TorBox](torbox-news-server.md#what-it-actually-holds), selama seminggu itu, akan menjawab semua baris di atas.

## Apa yang sudah diberitahukan platform {#what-the-platform-already-tells-you}

Dua fakta dari pengukuran TorBox tetap berlaku, satu tidak.

Yang tetap berlaku: semantik penolakan dan waktu penolakannya. Software-nya sama, jadi jawabannya juga sama, sehingga `482 Invalid username or password` di sini tetap berarti kredensial sudah mati, dan batasnya berupa string yang berbeda.

Yang tetap berlaku: jendela nomor artikel. Reader `nntpswitch2` membuat nomor artikel secara sintetis dalam jendela yang pendek, jadi apa pun yang menelusuri nomor, bukan message id, hanya melihat Usenet dua minggu ke belakang. Ini sifat dari platform-nya, bukan dari satu akun saja. Pembacaan yang digerakkan NZB mengakses artikel lewat message id, jadi tidak terpengaruh.

Yang tidak berlaku: cakupan. Reader TorBox diukur sebagai subset ketat dari akun Omicron, yaitu 71,2 persen, dengan nol artikel sendiri dari 531. Itu berasal dari endpoint TorBox, bukan endpoint ini, dan TorBox bahkan tidak termasuk dalam blok ini. Angka itu adalah perkiraan awal terdekat untuk software dan operator yang sama, tetapi bukan pengukuran untuk ElfHosted. Anggap itu sebagai hipotesis yang perlu diuji, bukan sebagai jawabannya.

## Mengonfigurasinya di zurg {#configuring-it-in-zurg}

Jika kredensial sudah didapat, itu adalah entri server `type: nzb` biasa di samping server utama.

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

Mulai dari 8 koneksi dan naikkan hanya setelah batas sebenarnya sudah diukur. Angka 100 yang dipublikasikan sudah tidak berlaku, dan pool yang membuka koneksi melewati batas yang belum diketahui akan menolak dirinya sendiri saat cold start.

Atur `backbone: abavia` dan bukan nama merek, karena XS News, Easyusenet, Hitnews, UseNeXT, dan yang ini semuanya berasal dari platform yang sama. Jika diperlakukan sebagai backbone terpisah, pool bisa menghitung satu spool sebagai beberapa spool. `backup: true` membuatnya hanya dipakai untuk artikel yang sudah ditolak oleh semua server utama.

Jangan pernah mengarahkan klien kedua ke kredensial yang sama. Server menolak pemegang yang lebih lama, bukan yang lebih baru, sehingga konsumen kedua akan merugikan yang pertama.

## Apakah layak dapat slot {#is-it-worth-a-slot}

Tidak bisa dibeli sendiri. Fitur ini datang bersama paket add-on Stremio seharga sembilan dolar per bulan, yang
juga mencakup add-on yang di-host, instance NzbDav, dan akun TorBox Essentials. Sebagai salah satu item di dalam paket itu, fitur ini tidak
menambah biaya apa pun, dan itu adalah hal terkuat yang bisa dikatakan tentang fitur ini tanpa kredensial.

Jika dibandingkan dengan stack yang sudah punya akun Omicron dan Eweka serta Frugal, menambah pembaca keempat dari platform ini
adalah taruhan yang sama seperti yang pernah diambil halaman TorBox, dan kalah. Taruhan itu belum diukur di sini, jadi ini masih
sebatas perkiraan awal, bukan keputusan akhir. Yang bisa memastikannya adalah satu dolar, satu minggu, dan 531 id sweep.
