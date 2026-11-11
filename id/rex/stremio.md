# rex dengan addon Stremio Anda {#rex-with-your-stremio-addons}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) mengubah katalog addon Stremio menjadi library rex. Film, serial, dan saluran TV live lalu bisa diputar di aplikasi Plex. Tidak ada yang diunduh. Saat seseorang menekan putar, rex-stremio meminta tautan ke addon stream, lalu rex memutarnya.

Ini tidak butuh sponsor DMM. rex dan rex-stremio gratis. Kamu perlu addon stream yang mengembalikan tautan, biasanya lewat akun debrid kamu sendiri.

Yang kamu dapatkan:

- **Libraries.** Film masuk ke **Stremio Films**, serial masuk ke **Stremio Shows**, dan saluran TV live dari addon TV live masuk ke library bernama **Live TV**, kecuali kamu memberi nama sendiri pada library sebuah katalog. Library itu berupa daftar saluran; saluran tidak muncul di panduan Live TV aplikasi Plex.
- **Collections.** Beri beberapa katalog film library yang sama lalu centang **Catalogs as collections**: satu library, satu collection per katalog, dan film yang ada di beberapa katalog hanya muncul sekali.
- **Plex memberi nama sesuai yang diketahuinya.** Film dan episode dikirim ke rex dengan id IMDb-nya, jadi setelah rex dipasang di akun Plex, aplikasi menampilkan judul, poster, dan ringkasan yang biasa. Judul yang hanya diketahui addon, serta saluran live, tetap memakai nama dan gambar dari addon.

## Sebelum kamu mulai {#before-you-start}

| Anda butuh | Alasannya |
|---|---|
| Mesin yang selalu menyala, Linux atau macOS, untuk rex dan rex-stremio sekaligus | rex-stremio adalah satu program Python dan berjalan di samping rex. Layanan di bawah ini untuk Linux; [Docker](#in-docker) juga bisa dipakai |
| Python 3.9 atau lebih baru, `git` dan `ffprobe` | rex-stremio memeriksa stream setiap judul sekali dengan ffprobe, karena rex perlu tahu isi sebuah file sebelum bisa memutarnya. Dengan kunci API DMM, stream debrid dari torrent yang sudah dimiliki DMM sudah punya hasil probe, jadi pemeriksaan itu dilewati; yang lain akan di-probe |
| Addon stream yang memberi tautan, bukan torrent | rex memutar file. Atur layanan debrid Anda di addon supaya memberi tautan |
| Akun Plex baru yang khusus dibuat untuk rex | Seperti di panduan pengaturan rex: rex diklaim pada akun ini lalu dibagikan ke akun Anda sendiri |

## Langkah 1. Pasang rex dan tambahkan ke akun Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Ikuti [rex dengan aplikasi Anda sendiri](any-source.md):

1. [Langkah 1. Pasang rex](any-source.md#step-1-install-rex), termasuk mencari IP LAN rex. Gunakan nama itu di setiap perintah.
2. [Langkah 3. Tambahkan ke akun Plex](any-source.md#step-3-add-it-to-a-plex-account): daftarkan rex di akun baru dan bagikan ke akun Anda sendiri.

Lewati langkah 2 dan 4 di sana: rex-stremio adalah aplikasi Anda.

Live channel, dan addon yang streamnya berupa playlist `.m3u8`, hanya bisa diputar lewat konversi video rex. Untuk itu, atur juga [Converting video](any-source.md#converting-video-optional) di mesin rex. Film dan episode yang disajikan sebagai file (`.mkv`, `.mp4`) tidak perlu langkah tambahan.

## Langkah 2. Pasang rex-stremio {#step-2-install-rex-stremio}

**Apa yang dilakukannya.** Mengunduh rex-stremio ke `~/rex-stremio` di mesin rex dan menjalankannya sebagai service.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
mkdir -p ~/.config/systemd/user
cp ~/rex-stremio/rex-stremio.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-stremio
journalctl --user -u rex-stremio -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
cd ~/rex-stremio && python3 rex_stremio.py
```

Service ini tetap berjalan selama jendela Terminal itu masih terbuka.
+++

**Yang seharusnya kamu lihat.** Baris seperti ini:

```
... INFO relay and settings on http://127.0.0.1:9982/, 0 catalog(s), rex at http://127.0.0.1:32400
```

Halaman pengaturan rex-stremio dan alamat tempat rex membaca video sama-sama ada di `127.0.0.1:9982`, jadi hanya mesin ini yang bisa mengaksesnya.

## Langkah 3. Tambahkan addon Anda {#step-3-add-your-addons}

Buka `http://127.0.0.1:9982/` di browser pada mesin rex. Tidak ada layar? Dari komputer Anda, jalankan `ssh -L 9982:127.0.0.1:9982 you@<rex's LAN IP>` lalu buka alamat yang sama selama SSH masih berjalan.

1. Di bawah **Addons**, tempel tautan manifest addon, seperti di Stremio, lalu tekan **Add**. Lakukan untuk:
   - **Catalogs**, misalnya Cinemeta: `https://v3-cinemeta.strem.io/manifest.json`.
   - **Streams**: addon yang mencari rilis dan memutarnya lewat layanan debrid Anda. Buka halaman configure-nya, pilih layanan debrid Anda, tempel API key-nya, lalu salin tautan manifest yang dibuatnya. Jika addon hanya menawarkan hasil yang sudah ter-cache, pilih opsi itu. Tautan ini berisi kunci debrid Anda, jadi jaga kerahasiaannya.

   ![Bagian Addons rex-stremio dengan Cinemeta dan Public Domain Movies sudah ditambahkan](../assets/rex/90-stremio-addons.webp)

2. Di bawah **Catalogs**, centang katalog yang Anda inginkan. Beri nama library tempat masing-masing katalog masuk, lalu atur **How many** film, episode, atau channel yang akan diambil. Untuk satu library dengan satu koleksi per katalog, berikan katalog-katalog itu library yang sama lalu centang **Catalogs as collections**.
3. Di bawah **Streams**, atur **Highest resolution** dan **Largest file** yang ingin Anda putar, atau biarkan di any.
4. Di bawah **rex**, atur alamatnya menjadi `http://<rex's LAN IP>:32400`.
5. Jika Anda sponsor DMM, tempel API key DMM Anda di bawah **DMM** ([gatekeeper](https://gatekeeper.debridmediamanager.com/) menampilkannya setelah Anda sponsor). Stream debrid dari torrent yang sudah punya probe di DMM akan melewati pengecekannya. Selain itu, stream akan dicek, dan hasil pengecekan rex-stremio terhadap file torrent (bukan stream HTTP biasa atau playlist HLS) dikirim kembali ke DMM untuk sponsor berikutnya (`share_probes: false` di `config.json` akan menghentikannya). Tekan **Save and sync**.

![Bagian Catalogs, Streams, rex, dan DMM di rex-stremio, dengan tombol Save and sync](../assets/rex/91-stremio-catalogs-rex.webp)

**Yang harus Anda lihat.** Di log rex, seperti di [langkah 4 rex dengan aplikasi Anda sendiri](any-source.md#step-4-connect-your-app):

```
INFO    SOURCES PUT /rex/sources/stremio -> 200
INFO    FEED stremio upsert: ...
```

Judul muncul di rex saat setiap judul selesai dicek, bukan saat seluruh katalog selesai. rex-stremio mengecek beberapa judul sekaligus. Sinkronisasi berjalan lagi setiap enam jam dan setiap kali Anda menyimpan.

## Langkah 4. Bagikan library baru dan mulai tonton {#step-4-share-the-new-libraries-and-watch}

Perpustakaan yang dibuat rex-stremio masih baru, jadi akun Anda sendiri belum bisa melihatnya. Bagikan ke akun Anda sendiri seperti di [langkah 3](any-source.md#share-it-with-your-own-account), dengan login sebagai akun baru tersebut, dan juga ke siapa pun yang ingin Anda bagikan rex.

Lalu buka aplikasi Plex sebagai diri Anda sendiri dan tekan putar pada sesuatu. rex-stremio akan meminta tautan dari stream addon Anda pada saat itu, dan rex memutarnya. Untuk menonton di luar rumah atau di app.plex.tv, berikan rex alamat tersendiri: [Gunakan di luar rumah](any-source.md#use-it-outside-your-home-optional).

## Di Docker {#in-docker}

rex-stremio's [README](https://github.com/debridmediamanager/rex-stremio#set-up) berisi perintah Docker. Di dalam container, rex membaca video dari alamat container di jaringan Anda, bukan dari `127.0.0.1`, dan README menunjukkan cara mengaturnya.

## Memperbarui {#updating}

```bash
cd ~/rex-stremio && git pull && systemctl --user restart rex-stremio
```

Di macOS, hentikan dengan Ctrl+C, jalankan `git pull` di `~/rex-stremio` lalu mulai lagi.

## Yang tidak bisa dilakukan {#what-it-cannot-do}

- **Episodes are numbered as Cinemeta numbers them.** For a few shows that differs from TMDB's numbering, which rex follows, so an episode can land in the wrong place.
- **How many counts episodes** for a series catalog, not shows.
- **Turning Catalogs as collections on or off** sends the titles to rex again as new ones, so what was watched on them may not carry over. Decide before you start watching.
- **Only film, series and channel catalogs** are listed, and none that need a search or a genre first.
- **Live channels** cannot be paused far back, resumed later or marked watched, and play only in apps that ask rex to convert them (the Plex apps and Plezy; Plex Web is not tested). Channels with no working stream, or with DRM, are left out.
- **Anyone who can reach rex-stremio's address can play through it.** Leave it on `127.0.0.1` unless rex runs elsewhere.

The README lists the [rest of its limits](https://github.com/debridmediamanager/rex-stremio#limits) and every setting in `config.json`. To build an addon of your own, see [Building rex addons](addons.md), which also explains how rex-stremio works inside.
