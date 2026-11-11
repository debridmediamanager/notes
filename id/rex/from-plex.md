# Pindah dari Plex ke rex {#move-from-plex-to-rex}

Anda menjalankan Plex Media Server dan ingin mencoba rex. Aplikasi Plex Anda tetap sama. Sumber library dan alamat server yang berubah.

## Apa yang berubah {#what-changes}

| | Plex Media Server | rex |
|---|---|---|
| Dari mana library berasal | Plex memindai folder di disk atau mount | Sebuah source (aplikasi kamu sendiri, rex-stremio, atau zurg) memberi tahu rex apa yang dimilikinya. rex tidak pernah memindai folder dan tidak butuh mount |
| Apa isi setiap file | Plex mencocokkannya dari nama file | Source yang mencari tahu lalu memberi tahu rex. rex tidak pernah membaca nama file |
| Kecocokan yang salah | Fix Match di server | **Fix Match** di aplikasi Plex, login sebagai akun pemilik rex. rex menyimpan pilihan kamu, dan source bisa mengambilnya kembali lalu menyimpannya, seperti yang dilakukan zurg ([kenapa judul ditempatkan seperti itu](with-zurg.md#why-dmm-places-the-files)) |
| Akun tempat server berada | Biasanya akun kamu sendiri | Akun Plex baru yang dibuat khusus untuk rex, dibagikan dengan akun kamu sendiri |
| Musik, Live TV, dan foto | Dari folder dan tuner | Hanya dari source yang mengirimkannya, seperti addon ([Building rex addons](addons.md#music)) atau comic books milik zurg. Plex Web menampilkan foto; Plex untuk Android tidak |
| Merekam TV | Ya | Tidak |

## Pilih cara {#pick-a-way}

| | Berdampingan dengan Plex | Menggantikan Plex |
|---|---|---|
| Yang kamu dapat | rex di samping Plex kamu. Aplikasimu menampilkan kedua server | rex sendirian, di port biasa Plex |
| Cocok untuk | Mencoba rex, atau tetap memakai Plex untuk foto atau musik di disk, atau merekam TV | Pindah secara permanen |
| Di mesin yang sama dengan Plex | rex berjalan di port `32500`, dan aplikasimu menemukannya lewat akun Plex yang dibagikan dengannya | Plex dihentikan, rex memakai port `32400` dan aplikasi di rumah menemukannya sendiri |

Mulailah dengan berdampingan dengan Plex meskipun kamu berniat menggantinya: menyalin riwayat tontonanmu membutuhkan server Plex lama kamu tetap berjalan. Lakukan langkah 1 sampai 3, pakai rex untuk beberapa waktu, dan lakukan langkah 4 saat kamu sudah siap.

## Langkah 1. Siapkan rex di samping Plex {#step-1-set-up-rex-beside-plex}

Atur rex dengan sumber yang akan mengisinya, seperti [rex dengan aplikasi Anda sendiri](any-source.md), [rex dengan addon Stremio Anda](stremio.md) atau [rex dengan zurg](with-zurg.md), sampai bisa menonton sesuatu. Sudah menjalankan zurg untuk Plex? Lewati instalasinya dan perbarui seperti yang ditunjukkan di langkah 1 rex dengan zurg: zurg memberi data ke rex mulai dari nightly **2026.10.27**.

- **Plex berjalan di mesin yang sama?** Pasang rex di port `32500`, seperti yang tertulis di [Pasang rex](any-source.md#step-1-install-rex) untuk kasus itu, dan berikan port itu juga ke sumber Anda. Aplikasi Anda kemudian akan menampilkan dua server dengan nama mesinnya: rex adalah yang dibagikan ke Anda, dengan nama akun baru di sebelahnya. [Pasang rex](any-source.md#step-1-install-rex) menjelaskan cara mengganti namanya.
- **Daftarkan rex di akun Plex baru,** bukan akun tempat server Plex Anda berada, seperti yang dijelaskan di [Tambahkan ke akun Plex](any-source.md#step-3-add-it-to-a-plex-account).
- **Jauh dari rumah dengan rex-direct?** Port 32400 di router Anda sudah diteruskan ke Plex. Teruskan juga port `32500` ke mesin rex, atau, [lewat IPv6](any-source.md#rex-direct-over-ipv6), izinkan `32500` masuk ke mesin tersebut.

Pakai zurg? Selama keduanya berjalan, zurg memberi data ke keduanya. Biarkan semua yang sudah ada di zurg untuk Plex seperti apa adanya (`plex_server_url`, `plex_token`, mount rclone Anda dan skrip scan apa pun): Plex tetap berjalan seperti sebelumnya, dan `rex_url` menambahkan rex.

## Langkah 2. Bawa riwayat tontonanmu {#step-2-bring-your-watch-history}

Setelah library Anda ada di rex, [Bawa riwayat tontonan Anda](import-watched.md) akan menyalin apa yang Anda tonton, di mana Anda berhenti, dan rating bintang Anda dari server Plex. Lakukan saat Plex masih berjalan. Setiap orang yang Anda bagikan akses harus menjalankannya untuk riwayat tontonan mereka sendiri.

## Langkah 3. Undang lagi teman-temanmu {#step-3-invite-your-people-again}

Teman dan keluarga kamu diundang ke server Plex kamu, bukan ke rex. rex itu server baru di akun yang baru, jadi undang mereka dari sana dan mereka tinggal menerima seperti share biasa: [Bagikan rex ke keluarga dan teman](sharing.md).

## Langkah 4. Pensiunkan Plex (opsional) {#step-4-retire-plex-optional}

**Hentikan Plex selamanya.** Di Linux, jalankan `sudo systemctl disable --now plexmediaserver`. Di Docker, hentikan container-nya dan hapus dari file compose kamu. Di Windows dan macOS, keluar dari Plex Media Server dan hapus dari aplikasi yang otomatis jalan saat kamu login.

**Pindahkan rex ke port 32400** jika sebelumnya ada di `32500` berdampingan dengan Plex di mesin yang sama:

1. Hapus `--port 32500` dari perintah start rex (atau baris `command:` di Docker), lalu restart rex seperti yang ditunjukkan [Pasang rex](any-source.md#step-1-install-rex) untuk sistemmu. Di Windows, izinkan port 32400 dan dua port discovery lewat firewall seperti di langkah itu.
2. Beri source-mu alamat rex yang baru, `http://192.168.1.20:32400` (IP LAN rex), lalu restart. Di zurg, isi `rex_url`. Di halaman pengaturan rex-stremio, isi **rex's address**.
3. Ganti `32500` menjadi `32400` di mana pun kamu memasukkan alamat rex, misalnya di Kometa.
4. Dengan rex-direct, arahkan port forward 32400 di router ke mesin rex dan hapus forward `32500`. Lewat IPv6, ubah aturan firewall dari `32500` ke `32400` lalu restart rex, supaya rex menawarkan IPv6-nya di port baru.

rex kemudian merespons di port 32400, dan aplikasi Plex di rumah menemukannya di jaringanmu dengan sendirinya.

**Pakai zurg? Rapikan pengaturan Plex-nya.** Config zurg mungkin masih mengarah ke Plex yang sudah kamu hentikan:

| Di `config.yml` zurg | Yang perlu dilakukan |
|---|---|
| `plex_server_url` dan `plex_token` | Hapus keduanya, atau tekan **Remove** di sebelah Plex pada dashboard zurg (halaman config, **Media Server Integration**). Pakai [watchlist Plex](../zurg/guides/plex-watchlist.md) zurg? Hapus hanya `plex_server_url`. Watchlist dibaca dari plex.tv dengan `plex_token` dan tidak butuh server Plex. Kamu juga bisa mengarahkannya ke rex: tekan **Re-Auth** di sana, login dengan akun baru, lalu pilih rex. zurg 2026.10.27 ke atas mengenali bahwa server-nya adalah rex dan tidak mengirim scan, pencocokan Plex, perbaikan season, atau pengecekan pengaturan Plex ke sana. Token-nya kemudian milik akun baru, jadi watchlist Plex akan mengikuti akun itu. |
| `on_library_update` yang menjalankan scan Plex, misalnya `plex_update.sh` | Hapus. rex langsung mendapat kabar setiap perubahan dari zurg. |
| `plex_database_path`, `plex_scan_check_url`, dan `plex_scan_check_token` | Hapus. Ketiganya merujuk ke Plex yang sudah kamu hentikan. |
| Mount rclone-mu (`rclone_enabled: true`, atau rclone yang kamu jalankan sendiri) | Simpan jika Sonarr, Radarr, Bazarr, atau aplikasi lain membaca file di sana. Jika Plex satu-satunya pembaca, kamu bisa mematikannya. rex membaca setiap file langsung dari zurg. |

Restart zurg setelah mengedit config-nya.

## Apa yang ikut dan apa yang tidak {#what-comes-along-and-what-does-not}

| Yang ikut pindah | Caranya |
|---|---|
| Film dan serial kamu | Sumbermu mengirimnya ke rex. Dengan zurg, file-file itu berasal dari akun debrid yang sama dengan yang dibaca Plex |
| Apa yang sudah kamu tonton, di mana kamu berhenti, dan rating bintang untuk film dan episode | [Bawa riwayat tontonanmu](import-watched.md), masing-masing orang sendiri |

| Tidak ikut pindah | Alasannya |
|---|---|
| Perbaikan Match yang kamu buat di Plex | rex tidak memakai match dari Plex. Sumbermu menentukan apa isi setiap file; perbaiki yang salah dengan **Fix Match** di rex |
| Koleksi | Tidak disalin. [Kometa dengan rex](kometa.md) membuatnya lagi dari konfigurasi Kometa kamu |
| Poster dan artwork yang kamu pilih | Hanya tersimpan di server lama |
| Playlist, dan daftar riwayat putar server | Hanya tersimpan di server lama |
| Akses teman-temanmu | Mereka diundang ke server lama. Undang mereka ke rex ([langkah 3](#step-3-invite-your-people-again)) |
| Musik dan foto di disk, TV langsung dari tuner, dan rekaman | rex tidak punya tuner dan tidak merekam apa pun; musik, foto dan saluran langsung hanya datang dari sumber yang mengirimnya. Simpan Plex di samping rex untuk itu |
| File di disk lokal | rex tidak memindai folder. Sebuah aplikasi harus menyajikannya dan memberi tahu rex: [rex dengan aplikasimu sendiri](any-source.md) |
