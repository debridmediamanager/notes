# Live TV dengan rex {#live-tv-with-rex}

rex menampilkan saluran addon di **Live TV** pada Plex Web dan Plex untuk Android, lengkap dengan panduan dan What's On. Pilih saluran, lalu langsung diputar. [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) sudah siap dipakai dengan server live-sports. Untuk IPTV M3U dan panduan XMLTV, lihat [Tutorial: addon IPTV](addon-iptv.md).

Yang kamu dapatkan:

- **Panduan.** Setiap saluran dengan nomornya, beserta acara yang sedang tayang dan yang berikutnya.
- **What's On.** Apa yang sedang tayang sekarang, apa yang mulai nanti, dan film yang akan datang.
- **Pencarian.** Nama sebuah program akan menemukannya di Live TV maupun di pustakamu.
- **Menonton.** Pilih saluran dan langsung diputar secara live. Saluran tidak menyimpan titik lanjut dan tidak pernah ditandai sudah ditonton.
- **Daftar saluran, seperti penyedia TV kabel.** rex-live-sports dimulai dengan daftar saluran AS: sekitar 30 jaringan olahraga dengan nomor yang tidak pernah berubah (ESPN nomor 2, CBS nomor 7), jadwal pertandingan ESPN di saluran-saluran tersebut, dan saluran slot (`NFL 1`, `NBA 1` dan seterusnya) yang mendaftar pertandingan hari itu sebelum dimulai dan memutar setiap pertandingan secara live. Ada juga daftar saluran Inggris dan Jerman.
- **Pustakanya juga.** Saluran tetap berada di pustaka **Live Sports** mereka sendiri, diurutkan ke dalam satu koleksi untuk setiap grup.

## Sebelum kamu mulai {#before-you-start}

| Yang Anda butuhkan | Alasannya |
|---|---|
| Rex nightly bertanggal 2026.11.02 atau yang lebih baru | Fitur Live TV hadir di build itu |
| rex sudah disiapkan seperti di [rex dengan aplikasi Anda sendiri](any-source.md), dengan [Konversi video](any-source.md#converting-video-optional) | rex mengonversi setiap channel saat Anda menontonnya (salinan, murah) |
| Server live-sports, di mesin rex atau jaringan rumah Anda | rex-live-sports mengambil channel-nya dari server itu |
| Docker | Dipakai untuk menjalankan live-sports di Langkah 2. [README](https://github.com/yowmamasita/live-sports-public)-nya memuat cara lain |
| Python 3.9 atau yang lebih baru, `git`, `ffmpeg` dan `ffprobe` di mesin rex | rex-live-sports memeriksa stream setiap channel dengan ffprobe dan membuat posternya dengan ffmpeg |

## Langkah 1. Pasang rex dan tambahkan ke akun Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Ikuti [rex dengan aplikasi Anda sendiri](any-source.md):

1. [Langkah 1. Instal rex](any-source.md#step-1-install-rex), termasuk mencari IP LAN rex. Halaman ini menulisnya sebagai `192.168.1.20`: ganti dengan IP Anda sendiri.
2. [Langkah 3. Tambahkan ke akun Plex](any-source.md#step-3-add-it-to-a-plex-account): daftarkan rex di akun baru dan bagikan ke akun Anda sendiri.
3. [Konversi video](any-source.md#converting-video-optional).

Lewati langkah 2 dan 4 di sana: rex-live-sports adalah aplikasi Anda.

## Langkah 2. Jalankan server live-sports {#step-2-start-a-live-sports-server}

**Apa yang dilakukannya.** Menjalankan live-sports, yang mencari channel olahraga dan memeriksa setiap beberapa menit mana yang sedang menayangkan siaran.

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**Apa yang harus kamu lihat.** `http://192.168.1.20:8765` menampilkan dashboard live-sports di browser. Pemeriksaan pertama untuk setiap channel memakan waktu beberapa menit.

## Langkah 3. Pasang rex-live-sports {#step-3-install-rex-live-sports}

**Apa fungsinya.** Mengunduh rex-live-sports ke `~/rex-live-sports` di mesin rex lalu menjalankannya.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

Di `config.json`, atur `live_sports_url` ke `http://192.168.1.20:8765` dan `rex_url` ke `http://192.168.1.20:32400`. Lalu:

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

Di `config.json`, atur `live_sports_url` ke `http://192.168.1.20:8765` dan `rex_url` ke `http://192.168.1.20:32400`. Lalu:

```bash
python3 rex_live_sports.py
```

Program berjalan selama jendela Terminal itu tetap terbuka.
+++

**Yang seharusnya kamu lihat.** Kira-kira seperti ini:

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

Sebelum pengecekan pertama live-sports selesai, log menampilkan `live-sports lists no channel that plays yet`. Lalu sinkronisasi pertama mengecek stream setiap channel lineup yang dimiliki live-sports, sekitar satu menit untuk 30 channel, dan mencatat:

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

Itu adalah 30 channel lineup yang dimiliki live-sports, ditambah slot dengan pertandingan hari itu. Sinkronisasi berjalan lagi setiap lima menit dan hanya mengecek channel yang belum terlihat hari itu.

## Langkah 4. Bagikan library dan buka Live TV {#step-4-share-the-library-and-open-live-tv}

Perpustakaan **Live Sports** baru, jadi belum ada di berbagi akun mana pun. Masuk dengan akun baru tersebut, lalu tambahkan ke berbagi akun kamu sendiri dan semua akun lain di **Manage Library Access** ([Berbagi rex](sharing.md)). Berbagi akan memungkinkan akunnya menonton Live TV, kecuali kamu mematikannya untuk akun tersebut.

Lalu buka aplikasi Plex sebagai dirimu sendiri:

- **Plex Web**: **Live TV & DVR** ada di sidebar, bersama perpustakaan rex.
- **Plex for Android**: tab **Live TV** di bagian bawah, dengan rex dipilih di bagian atas; **Live TV & DVR** juga tercantum bersama perpustakaan rex.

**Yang seharusnya kamu lihat.** **Guide** dan **What's On** ada di bagian atas. Guide mencantumkan setiap channel dengan nomornya beserta acara yang sedang tayang. Pilih sebuah program lalu tekan **Watch Now**.

## Channel, nomor dan panduan {#channels-numbers-and-guides}

`config.json` menyebut lineup-nya: `lineups/us.json` sebagaimana adanya, `lineups/uk.json` atau `lineups/de.json` untuk jaringan Inggris atau Jerman. Channel lineup selalu ada di nomornya, sementara live-sports punya salinannya yang bisa diputar.

Jaringan AS mendapat pertandingannya dari jadwal ESPN (`Chicago Bears at Seattle Seahawks`, mulai dari kickoff selama durasi biasa cabang olahraganya; NFL, college football, NBA, NHL, MLB, liga-liga besar Eropa, MLS dan F1). ESPN hanya mencantumkan penyiar AS, jadi jaringan Inggris dan Jerman mendapat panduan yang dimiliki [epgshare01](https://epgshare01.online/) untuk channel dengan nama yang sama, seperti halnya setiap channel di sekitar pertandingannya. Channel yang tidak ada di panduan manapun menampilkan namanya sendiri dalam blok enam jam.

Slot datang setelah jaringan: `NFL 1` sampai `NFL 10` di `700.1` sampai `700.10`, `NBA 1` sampai `NBA 6` mulai di `701.1`, lalu NHL, MLB, Soccer dan F1. Setiap pertandingan hari itu masuk ke slot kosong pertama untuk cabang olahraganya, jadi panduan sudah menampilkannya sebelum mulai. Dari 15 menit sebelum kickoff sampai pertandingan selesai, slot itu memutar stream live-sports yang memuatnya, dicari dari nama kedua tim. Di antara pertandingan, slot tidak memutar apa-apa. Slot baru muncul pertama kali saat memutar sebuah pertandingan.

Tanpa lineup (`"lineup": ""` di `config.json`), setiap channel dari grup `Live:` dan `Sports` milik live-sports justru ada semua, dan diberi nomor per grup: `100.1`, `100.2` untuk grup pertama, `101.1` untuk grup berikutnya. Nomor ini tidak bertabrakan dengan nomor rendah yang dipakai tuner atau sumber lain. Channel mempertahankan nomornya selama live-sports masih mencantumkannya minimal seminggu sekali. Channel Pluto TV mendapat jadwal Pluto TV sendiri dan tidak disertakan kecuali kamu memintanya: `"groups": ["Live:", "Sports", "Pluto:"]`. Semua setting ada di [README](https://github.com/debridmediamanager/rex-live-sports#settings) rex-live-sports.

## Memperbarui {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

Di macOS, hentikan dengan Ctrl+C, jalankan `git pull` di `~/rex-live-sports` lalu mulai lagi.

## Yang tidak bisa dilakukan {#what-it-cannot-do}

- **Tidak ada rekaman.** Plex Web dan Plex untuk Android tidak menampilkan tombol Record.
- **Panduan dicocokkan berdasarkan nama.** Sebuah saluran bisa mendapat panduan dari feed lain dengan merek yang sama, dan banyak saluran acara tidak punya panduan sama sekali.
- **Slot mencari stream sebuah pertandingan berdasarkan nama tim di judulnya.** Stream yang dinamai lain (`nfl ravens`) tidak ditemukan, dan pertandingan yang tidak punya stream ada di panduan tetapi tidak bisa diputar.
- **Plex menganggap program tanpa nomor episode sebagai film**, seperti yang dilakukan pada setiap panduan TV, jadi pertandingan juga muncul di bagian film What's On.
- **Live TV hanya diuji di Plex Web dan Plex untuk Android.** Aplikasi Plex lain belum dicoba.
- **Siapa pun yang bisa menjangkau alamat rex-live-sports bisa memutar lewat sana.** Biarkan `listen` tetap di `127.0.0.1`.

Untuk membawa saluran Anda sendiri, dengan panduan yang sudah Anda punya, lihat [Building rex addons](addons.md#live-tv).
