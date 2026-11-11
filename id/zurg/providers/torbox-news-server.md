# Server berita TorBox {#torbox-news-server}

Paket TorBox Pro sudah termasuk akun Usenet. Ini adalah server NNTP sungguhan, dan zurg bisa memakainya sebagai provider `type: nzb` biasa. Halaman ini mencatat apa itu server tersebut dan seberapa berguna sebagai slot provider. Semua yang tertulis di bawah diukur pada 2026-09-02 dan 2026-09-03 dari dua host di jaringan yang berbeda.

## Apa yang terjawab di jaringan {#what-answers-on-the-wire}

`nntp.torbox.app:563` berbicara NNTP melalui TLS 1.3 di belakang sertifikat Let's Encrypt untuk `nntp.torbox.app`. Sapaan awalnya adalah `200 Welcome to TorBox`. Daftar capability menyebutkan nama perangkat lunaknya.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
POST
```

String implementasi itu bukan INN, bukan Diablo, dan bukan `nntpd` yang dilaporkan sebagian penyedia. Itu perangkat lunak khusus, dan namanya sudah menjelaskan fungsinya. Ada switch di depan satu atau beberapa article spool.

## Siapa yang menjalankannya {#who-runs-it}

Empat puluh hostname reader publik diuji untuk string implementasi itu. Tiga puluh dua menjawab NNTP, dan enam di antaranya melaporkan `nntpswitch2`. Keenam hostname itu mengembalikan daftar capability yang sama persis, dengan urutan yang sama persis.

| Reader | Alamat | Sapaan |
|---|---|---|
| `nntp.torbox.app` | 78.152.55.171 | `200 Welcome to TorBox` |
| `news.cheapnews.eu` | 78.152.55.164 | `200 Welcome to Cheapnews` |
| `reader.xsnews.nl` | 94.232.116.131 | `200 Welcome to XS News` |
| `news.easyusenet.nl` | 94.232.116.128 | `200 Welcome to Easyusenet` |
| `news.hitnews.com` | 94.232.116.174 | `200 Welcome to Hitnews` |
| `news.usenext.de` | 94.232.116.150 | `200 Welcome to Aviteo Ltd DE` |

Sisanya menjawab dengan cara yang berbeda. Termasuk merek-merek Omicron, Eweka, Frugal, UsenetExpress, Giganews, dan Usenet.Farm.

Alamat IP menjawab sisanya. `94.232.112.0/21` terdaftar atas nama Abavia S.r.l. dari San Marino, dengan `abuse@abavia.com` tercatat di datanya. Pemindaian reverse terhadap `94.232.116.0/24` menemukan lebih dari enam puluh nama reader di blok itu saja. XS News, Easyusenet, Hitnews, dan UseNeXT ada di sana, berdampingan dengan puluhan merek kecil lainnya. Blok tetangga `94.232.117.0/24` sepenuhnya berisi penamaan host XS News.

TorBox tidak berada di blok itu. TorBox berada di rentang Amsterdam, tujuh alamat dari `news.cheapnews.eu`.

**Terukur** adalah sidik jari perangkat lunaknya, kepemilikan alamatnya, dan kedekatan lokasinya. **Disimpulkan** adalah pengaturan komersialnya. TorBox menggambarkan Usenet-nya sebagai campuran penyedia Usenet berkualitas tinggi, dan perangkat lunak switch-nya sesuai dengan klaim itu. Jadi pernyataan yang aman adalah TorBox berada di depan platform reader yang sama dengan yang dijalankan merek Abavia dan XS News, bukan bahwa TorBox menjual ulang satu spool bernama tertentu.

## Apa yang didapat dari akun {#what-the-account-gives-you}

| Properti | Nilai |
|---|---|
| Host | `nntp.torbox.app:563` TLS, juga merespons di 119 |
| Grup di `LIST ACTIVE` | 103,415 |
| Koneksi | 10, batas keras yang dihitung persis, termasuk yang sedang handshake |
| Retention | 3900+ hari, diklaim oleh TorBox untuk server ini |
| Posting | diizinkan, `POST` mengembalikan `340 Start posting` |
| Field overview | Subject, From, Date, Message-ID, References, Bytes, Lines, Xref:full |
| Kompresi | `XZVER` dan `XZHDR` keduanya ditawarkan |
| Bandwidth | tidak terbatas, tetapi dihitung di angka usage pada dashboard TorBox |

Kredensial diambil dari torbox.app di menu tools, lalu pilih View Usenet Connection Details. Username adalah auth id akun kamu. Password hanya ditampilkan sekali. Setiap reset akan membatalkan password sebelumnya, jadi reset akan merusak semua client yang sudah dikonfigurasi.

Ada dua pesan penolakan yang penting saat ada masalah. `482 too many connections for your user` berarti batas koneksi sudah tercapai, dan pesan ini hilang begitu satu koneksi dikembalikan. `482 Invalid username or password` berarti kredensialnya memang sudah mati. Keduanya gagal lambat, sekitar dua detik. Auth yang berhasil jauh lebih cepat, diukur antara 64 ms sampai 592 ms selama sehari dial produksi.

## Jendela nomor artikel lebarnya dua minggu {#the-article-number-window-is-two-weeks-wide}

`GROUP` pada grup binary yang ramai melaporkan jumlah yang persis sama dengan batas atas dikurangi batas bawah. Spool asli punya celah, jadi kesamaan itu adalah tanda nomor yang dibuat secara sintetis. Jendelanya juga pendek.

| Grup | Batas bawah | Batas atas | Nomor dalam jendela |
|---|---|---|---|
| `alt.binaries.boneless` | 148068410000 | 150053594960 | 1,985,184,960 |
| `alt.binaries.teevee` | 2992135000 | 3392153099 | 400,018,099 |
| `alt.binaries.multimedia` | 31901685000 | 32301734812 | 400,049,812 |

Saat saya mengambil sampel nomor tertua di `alt.binaries.boneless`, artikel yang muncul diposting pada 2026-08-19. Itu empat belas hari sebelum tulisan ini dibuat. Apa pun yang lebih lama tidak punya nomor di server ini.

Ini tidak memengaruhi zurg. NZB mengakses artikel berdasarkan message id, dan pencarian message id menjangkau artikel yang jauh lebih lama daripada jendela tersebut. Yang terkena dampak adalah apa pun yang menelusuri nomor artikel. Header downloader atau indexer yang diarahkan ke server ini hanya melihat dua minggu Usenet dan tidak ada apa pun sebelumnya.

## Apakah ia meneruskan permintaan Anda ke penyedia lain {#is-it-proxying-your-request-to-other-providers}

Tidak. Tiga pengukuran menunjukkan jawabannya berasal dari spool yang sudah dipegang platform.

**Server menolak lebih cepat daripada harus bertanya ke siapa pun.** Dua puluh lima message id yang tidak pernah ada di mana pun ditanyakan ke tiga server.

| Server | `STAT` saat ketemu | `STAT` untuk id yang tidak pernah ada |
|---|---|---|
| `nntp.torbox.app` | 37 ms | **43 ms** |
| `news.eweka.nl` | 20 ms | 471 ms |
| `newshosting.tweaknews.eu` | 44 ms | 909 ms |

Server yang mengecek dulu ke upstream sebelum menjawab justru paling lambat ketika jawabannya "tidak ada", karena setiap upstream harus membalas dulu. Yang ini menjawab "tidak ada" dalam waktu yang sama dengan waktu ia mengonfirmasi "ada". Artinya, yang menjawab adalah indeks lokal.

**Tidak ada penalti untuk fetch pertama.** Sepuluh artikel dari tahun 2012 sampai 2018 diambil dalam kondisi dingin, lalu langsung diambil lagi di koneksi yang sama.

| Server | median dingin | median hangat |
|---|---|---|
| `nntp.torbox.app` | 49.6 ms | 30.9 ms |
| `news.eweka.nl` | 98.0 ms | 78.1 ms |

Rasio dingin ke hangat di sini 1.6, sedangkan di spool biasa 1.25. Selisih itu berasal dari TCP dan page cache. Kalau fetch dari pihak ketiga dilakukan saat request pertama, biayanya akan jauh lebih besar dan hanya terlihat di pass dingin. Artikel 792 KB sampai dalam kondisi dingin dalam 49 sampai 73 ms, sekitar 11 sampai 16 MB/s. Angka ini tidak menyisakan ruang untuk round trip ke provider lain.

**Sebuah blend tidak mungkin menjadi subset dari salah satu anggotanya.** Ini argumen yang menentukan. Kalau server menggabungkan beberapa backbone, coverage-nya adalah gabungan semuanya, dan ia akan punya artikel yang tidak dimiliki setidaknya satu anggotanya. Nyatanya, server ini tidak punya artikel seperti itu. Ia merupakan subset ketat dari akun Omicron, yaitu 71.2 persen. Penggabungan provider tidak bisa menghasilkan pola seperti ini.

Ada satu detail terkait untuk yang mau menelusuri sumbernya. Header yang dikembalikan sudah dinormalisasi, bukan apa adanya. Urutan field berubah dan kapitalisasinya ditulis ulang, jadi `X-Received-Body-CRC` menjadi `X-Received-Body-Crc` dan `Message-ID` menjadi `Message-Id`. `Path` adalah `not-for-mail` di setiap artikel yang dicek. Spool biasa bisa mempertahankan rantai asli, dan salah satu server di atas mengembalikan `news.tweak-news.eu!spooler.pl1!...!feed.tweaknews.nl!path-stripped` untuk artikel yang sama. Jadi header dibangun ulang dari field yang sudah diparse, dan jalur feed tidak bisa dipulihkan dari header tersebut.

## Mengonfigurasinya di zurg {#configuring-it-in-zurg}

Akunnya adalah entri server `type: nzb` yang normal. Ada dua kunci yang paling penting.

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
        - name: torbox-news
          host: nntp.torbox.app
          port: 563
          tls: true
          username: YOUR_TORBOX_AUTH_ID
          password: YOUR_TORBOX_NEWS_PASSWORD
          connections: 8
          backbone: torbox
          backup: true
```

`backup: true` menyediakan sepuluh koneksi untuk artikel yang sudah ditolak oleh semua akun lain. Primary yang sibuk tidak akan
dialihkan ke sini. Hanya *no such article* yang asli yang membuatnya dipakai. Lihat
[kunci provider](../reference/config.md) untuk cara `backup` dan `backbone` bekerja.

Atur 8, bukan 10. Batas ini menghitung koneksi yang masih handshake, jadi pool yang langsung membuka sampai batas
akan menolak dirinya sendiri saat cold start. Menyisakan dua koneksi cadangan juga memberi ruang untuk menjalankan pengecekan
secara manual tanpa mengganggu produksi. Jangan pernah mengarahkan client kedua ke kredensial yang sama. Dua pengguna dari satu akun sepuluh koneksi akan saling
kekurangan, dan server akan menolak pemegang yang lebih lama, bukan yang lebih baru.

## Apa yang sebenarnya disimpannya {#what-it-actually-holds}

Cakupan diukur terhadap tiga backbone lain dengan ID artikel yang sama. Sampelnya 177 rilis dari pustaka NZB zurg yang sedang aktif. Tanggal posting berkisar dari 2011 sampai 2026. Dari setiap rilis diambil tiga artikel dengan jarak yang merata di seluruh file. Hasilnya 531 message id. Setiap id ditanyakan ke empat akun, masing-masing lewat satu koneksi. Tiga lainnya adalah akun Omicron lewat Tweaknews, akun Eweka, dan akun Frugal.

| Tahun posting | ids | `nntp.torbox.app` | `newshosting.tweaknews.eu` | `news.eweka.nl` | `newswest.frugalusenet.com` |
|---|---|---|---|---|---|
| 2011 | 9 | 0 | 9 | 0 | 0 |
| 2012 | 21 | 16 | 21 | 21 | 21 |
| 2013 | 36 | 30 | 33 | 33 | 33 |
| 2014 | 36 | 33 | 36 | 36 | 36 |
| 2015 | 33 | 17 | 31 | 24 | 26 |
| 2016 | 36 | 31 | 36 | 36 | 36 |
| 2017 | 36 | 21 | 33 | 27 | 19 |
| 2018 | 36 | 16 | 36 | 24 | 24 |
| 2019 | 36 | 30 | 36 | 36 | 36 |
| 2020 | 36 | 34 | 36 | 36 | 36 |
| 2021 | 36 | 25 | 36 | 33 | 30 |
| 2022 | 36 | 29 | 36 | 27 | 27 |
| 2023 | 36 | 15 | 29 | 22 | 16 |
| 2024 | 36 | 23 | 35 | 32 | 33 |
| 2025 | 36 | 28 | 36 | 31 | 31 |
| 2026 | 36 | 30 | 36 | 30 | 30 |
| **Total** | **531** | **378 (71.2%)** | **515 (97.0%)** | **448 (84.4%)** | **434 (81.7%)** |

TorBox menjawab untuk lebih sedikit bagian pustaka ini dibanding ketiga backbone berbayar lainnya.

Angka yang menentukan apakah slot ini layak dipertahankan adalah angka yang lain. **TorBox tidak punya apa pun yang tidak dimiliki yang lain.** Tidak ada satu artikel pun dari 531. Dibandingkan dengan akun Omicron, TorBox adalah himpunan bagian yang murni tanpa artikel sendiri sama sekali. TorBox memang punya 9 artikel yang tidak dimiliki Frugal dan 6 yang tidak dimiliki Eweka. Semuanya juga ada di Omicron. Sementara itu, akun Omicron saja punya 61 artikel yang tidak dimiliki backbone lain.

Miss di server ini itu nyata, bukan server yang sedang sibuk lalu menjawab dengan buruk. Semua 153 miss ditanyakan lagi lewat koneksi baru beberapa menit kemudian, dan tidak ada satu pun yang berhasil. Pada run sebelumnya dengan pola yang sama, 77 miss ditanyakan ulang dan hanya 1 yang berhasil. Jadi sekitar 1 persen dari jawaban negatif itu gangguan, sisanya memang artikelnya tidak ada.

Hit juga nyata. Dua puluh artikel yang diklaim ada oleh keempat server lalu diambil penuh dengan `BODY`. Keempatnya mengirim 20 dari 20. `STAT` di server ini bisa dipercaya artinya byte-nya memang akan sampai.

Throughput satu koneksi juga diukur dalam run yang sama, tetapi tidak dilaporkan di sini karena hasilnya tidak stabil. Tiga putaran dari satu host menunjukkan TorBox berada di antara 1,6 dan 7,4 MB/s, sementara ketiga yang lain berada di rentang yang tumpang tindih dan tidak ada urutan yang konsisten. Siapa pun yang ingin menentukan ukuran pool sebaiknya mengukur sendiri dari host mereka.

Ada tiga catatan yang perlu disertakan bersama tabel. Sampelnya berasal dari pustaka satu operator, jadi hanya mencerminkan apa yang dikumpulkan pustaka tersebut. Tiga artikel dari satu rilis tidak independen satu sama lain, jadi setiap sel per tahun sebenarnya hanya dua belas rilis, bukan tiga puluh enam. Dan jawaban `STAT` adalah klaim tentang satu artikel, bukan putusan tentang seluruh rilis.

## Apakah layak dapat slot {#is-it-worth-a-slot}

Akunnya tidak menambah biaya apa pun karena sudah termasuk dalam Pro. Itu alasan terkuat untuk memakainya.

Akun ini bukan backbone retensi, dan jika Anda mengatur seolah-olah begitu, Anda akan kecewa. Akun ini menjawab untuk porsi perpustakaan nyata yang lebih sedikit dibanding tiga akun berbayar yang dibandingkan dengannya, dan tidak menghasilkan satu artikel pun yang belum ditolak oleh akun lain. Stack yang sudah punya akun Omicron tidak mendapat keuntungan apa pun dari menambahkan akun ini.

Ada dua kegunaan yang masuk akal. Setup dengan satu provider mendapat second opinion gratis, dan second opinion lebih baik daripada tidak ada sama sekali. Lalu `backup: true` membuat tebakan yang salah jadi murah, karena akun backup baru ditanya setelah semua primary menjawab bahwa artikel tersebut tidak ada.
