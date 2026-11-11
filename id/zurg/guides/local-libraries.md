# Pustaka debrid lokal dan zurgtorrent portabel {#local-debrid-libraries-and-portable-zurgtorrents}

A local library takes its membership from portable `.zurgtorrent` files. It
appears in the normal WebDAV, HTTP and provider directories. Importing files,
listing them and refreshing the catalog do not add torrents or resolve download
links. Playback resolves the requested file through your configured account.

Perpustakaan lokal mengambil daftar isinya dari file `.zurgtorrent` yang bisa
dibawa ke mana-mana. Perpustakaan ini muncul di direktori WebDAV, HTTP, dan
penyedia layanan yang biasa. Mengimpor file, menampilkan daftarnya, dan
menyegarkan katalog tidak menambahkan torrent atau mengambil tautan unduhan.
Saat diputar, file yang diminta akan diambil melalui akun yang sudah kamu atur.

## Ekspor pustaka {#export-a-library}

+++ Linux dan macOS
```sh
./zurg --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++ Windows
```powershell
.\zurg.exe --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++

`--provider` adalah **nama** akun yang sudah dikonfigurasi, termasuk nama kustom. Hilangkan
opsi ini untuk mengekspor semua salinan debrid yang didukung. Input juga bisa berupa satu
file cache runtime, direktori `dump/` lama, atau katalog portable yang sudah ada.
Untuk library lokal, ekspor direktori sumbernya (`torrents/<account>`), karena
referensi opsionalnya ke provider lain tetap terjaga.

Ekspor berjalan offline. Ia memvalidasi semua input dan tabrakan tujuan sebelum menulis apa pun,
melaporkan dan melewati entri runtime yang tidak punya metadata file yang dipilih, menggabungkan rilis berdasarkan hash, dan menulis `<hash>.zurgtorrent`. Ekspor yang sama persis dengan yang sudah ada aman untuk diulang. Untuk migrasi massal yang berisi entri cache lama yang rusak, `--skip-invalid` mengekspor entri yang valid dan melaporkan berapa banyak yang dilewati. Tanpa opsi ini, entri tidak valid pertama akan membatalkan proses sebelum ada yang ditulis. `--replace` mengizinkan penggantian ekspor portable dengan hash yang sama; opsi ini tidak pernah memberi izin untuk menimpa cache runtime.

Hanya file hasil ekspor yang dimaksudkan untuk dibagikan. `data/*.zurgtorrent` tetap menjadi state runtime pribadi. File `.zurgbackup` juga berisi kredensial akun dan merupakan backup instance, bukan library yang bisa dibagikan.

## Terima pustaka {#receive-a-library}

Taruh file hasil ekspor di `torrents/rd-local/`, lalu atur
akun penerima:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: YOUR_OWN_TOKEN
    download_tokens: # Optional bandwidth fallback on another RD account.
      - SECOND_RD_TOKEN
    library:
      source: local
      # Optional; defaults to torrents/<account-name>.
      path: torrents/rd-local

  - name: tb-online
    type: torbox
    token: YOUR_OWN_TORBOX_TOKEN
    # Omitted library block means the provider owns this account's catalog.
```

Untuk Real-Debrid dan AllDebrid, `download_tokens` memakai katalog lokal yang sama
dengan entri provider-nya. Akun RD kedua di atas tidak butuh direktori, dan
library torrent-nya tidak diimpor.
Ini adalah kredensial cadangan yang dipakai saat jatah bandwidth dari token unduh yang aktif
habis; kredensial ini tidak memaksa setiap unduhan lewat akun kedua. Kalau kamu menambah
entri RD kedua di bawah `providers`, akan dibuat katalog terpisah dengan direktorinya sendiri. Semua kredensial tetap ada di config dan dikecualikan dari ekspor portabel.

TorBox juga menerima `download_tokens`, tetapi rotasi token-nya tidak memetakan
ID torrent/file yang tersimpan ke ID di akun lain. Gunakan entri provider TorBox
terpisah untuk akun yang berbeda, masing-masing dengan katalog lokal sendiri.

Akun Premiumize, Offcloud, dan Debrid-Link juga bisa menyimpan library lokal. Tidak ada satu pun yang punya
referensi file yang portabel. Jadi, seperti TorBox, masing-masing menambahkan hash ke akunnya sendiri saat pemutaran pertama
dan mencocokkan file berdasarkan path dan ukuran. Gunakan satu entri provider per akun.

Restart setelah mengubah konfigurasi akun. Penambahan, penggantian, dan penghapusan file
diambil oleh refresh loop biasa. Setiap direktori dipindai satu level ke dalam. Path harus berupa direktori yang berbeda di bawah `torrents/`, supaya backup biasa ikut menyertakannya. Direktori yang tidak bisa dibaca atau penggantian yang tidak valid akan tetap memakai entri terakhir yang valid di memori dan mencatat masalahnya. Setelah restart, file yang tidak valid harus diperbaiki dulu sebelum bisa masuk ke katalog.

Manifest yang sama bisa disalin ke direktori lokal akun AllDebrid atau TorBox. Manifest
ini berisi identitas konten, bukan nama akun provider. Hash yang sama di beberapa akun
akan muncul sekali dengan beberapa sumber, mengikuti preferensi akun dan urutan failover yang sudah ada. File duplikat untuk satu hash dalam satu
direktori memakai nama file pertama menurut urutan abjad; simpan satu manifest per hash.

Keanggotaan katalog lokal tetap ada meski torrent dihapus dari library online provider.
Perubahan nama, tag, IMDb ID, dan penghapusan file disimpan kembali ke dalam manifest.
Menghapus rilis lokal akan menghapus dokumen sumbernya; ini tidak menghapus torrent di provider. Menghapus rilis yang punya salinan online juga akan menghapus salinan online tersebut, seperti yang dilakukan penghapusan seluruh rilis biasa.

Akun lokal bukan target untuk watchlist, upload magnet, atau upload file torrent. Tambahkan entri dengan mengimpor manifest. `add_torrents: false` tetap membiarkan RD/AD menukarkan referensi bersama yang sudah ada, tetapi mencegah pemutaran membuat lampiran di sisi provider saat diperlukan.

## Pindahkan akun online ke pustaka lokal {#offload-an-online-account-into-a-local-library}

AllDebrid menerima paling banyak 1000 magnet per akun, dan akun Real-Debrid juga bisa penuh. Rilis yang sudah selesai tidak perlu torrent-nya tetap ada di akun agar bisa diputar. Link `/d/` Real-Debrid tetap berfungsi setelah torrent dihapus, dan link `/f/` AllDebrid yang terkunci juga tetap berfungsi setelah magnet dihapus. Fitur offloading bergantung pada hal ini. zurg menulis rilis yang sudah selesai ke local library di layanan yang sama, lalu menghapus torrent dari akun online, sehingga slot-nya kosong. Rilis itu tetap punya folder di mount dan diputar dari link yang tersimpan.

Atur dua entri untuk akun yang sama, satu online dan satu local:

```yaml
providers:
  - name: ad
    type: alldebrid
    token: YOUR_AD_TOKEN
    library:
      offload_to: ad-local     # the local entry below
      offload_after_mins: 30   # optional, 30 is the default

  - name: ad-local
    type: alldebrid
    token: YOUR_AD_TOKEN       # the same token
    library:
      source: local            # manifests live in torrents/ad-local/
```

Rilis baru terus masuk ke `ad`. Setelah setiap daftar lengkap dari akun itu, dan setiap lima menit, zurg memindahkan rilis yang memenuhi syarat, satu per satu. Sebuah rilis memenuhi syarat jika:

- Rilis itu sudah lengkap di akun selama `offload_after_mins`, dihitung sejak proses zurg ini pertama kali melihatnya lengkap. Jika zurg di-restart, hitungan tunggunya mulai dari awal lagi.
- Setiap file punya link yang berfungsi di akun itu yang bisa ditukar oleh akun lain. Rilis yang salah satu filenya tidak punya link seperti ini tetap online.
- Rilis itu sehat, tidak sedang diperbaiki, dan tidak ada instance-nya yang masih diunduh. Tidak ada pass perbaikan atau download client yang memegang torrent-nya.
- Tidak ada job qBittorrent dari Sonarr atau Radarr yang masih mencantumkannya. Aktifkan Remove Completed Downloads di *arr supaya job dihapus setelah diimpor. Kalau tidak, rilis itu tetap online sampai kamu menghapus job-nya.
- Akuisisi tidak menambahkannya dalam satu jam terakhir.
- Memindahkannya tidak mengubah direktori mana pun tempat rilis itu berada dan nama folder-nya tetap sama. Direktori dengan filter `provider:` yang menyebut akun online akan kehilangannya, jadi rilis seperti itu tetap online.

Urutannya tetap. Manifest `<hash>.zurgtorrent` ditulis ke local library lebih dulu, rilis itu masuk ke local library berikutnya, dan baru setelah itu torrent dihapus dari akun online. Jika manifest tidak bisa ditulis, tidak ada yang dihapus. Jika penghapusan gagal, salinan online tetap ada di samping salinan local, dan refresh berikutnya akan menunjukkan apakah torrent-nya masih ada. Manifest yang sudah ada di local library untuk rilis itu akan diperbarui di tempat, bukan ditulis dua kali. Link akun online di dalamnya akan di-refresh, nama dan editannya mengikuti rilis seperti yang ditampilkan mount, dan link layanan lain tetap dipertahankan.

Rilis itu keluar dari `__ad__` dan muncul di `__ad-local__`. Direktori lain, termasuk `__all__` dan direktori buatanmu sendiri, tetap menampilkannya dengan nama yang sama. Tidak ada scan media server yang dimulai, karena tidak ada yang diindeks media server yang berubah. Arahkan Plex dan media server lain ke direktori-direktori itu, bukan ke direktori per akun.

Jika kedua entri memakai token yang sama, putar lokal bisa melampirkan rilis ke akun yang sama lagi (lihat di bawah), dan torrent itu kemudian muncul di daftar online. zurg tidak pernah melakukan offload pada rilis yang torrent online-nya merupakan lampiran seperti itu, atau selama putar lokal sedang menambahkan lampiran, karena penghapusannya akan merusak pemutaran yang baru saja mendapatkannya.

Hanya Real-Debrid dan AllDebrid yang bisa di-offload. TorBox, Premiumize, Offcloud, dan Debrid-Link tidak punya link yang bertahan setelah torrent dihapus, jadi putar lokal di akun-akun itu akan menambahkan torrent-nya kembali, dan offload tidak akan membebaskan apa pun. zurg menolak `offload_to` di akun-akun tersebut.

Dashboard juga bisa memindahkan satu rilis saja. Di halaman sebuah rilis, tabel Accounts menampilkan tombol Move to local library di samping setiap salinan Real-Debrid atau AllDebrid saat local library dengan tipe yang sama ada, meskipun tanpa `offload_to`. Jika rilis belum bisa dipindahkan, tombol itu dinonaktifkan dan menjelaskan alasannya. Pengaturan akun di halaman konfigurasi menawarkan pilihan yang sama, dan menampilkan berapa banyak rilis yang sudah dipindahkan sejak zurg dimulai, serta error terakhir.

## Apa saja yang ikut dalam file {#what-travels-in-the-file}

Format JSON versi ini memakai `format: "zurgtorrent"` dan `version: 1` (angka).
Isinya infohash, nama rilis, timestamp penambahan, nama ubahan, tag, IMDb ID,
serta path file yang dipilih, ukurannya, dan nama ubahan file (opsional). Referensi bersifat opsional:

| Provider | Referensi portabel | Pemutaran |
|---|---|---|
| Real-Debrid | `https://real-debrid.com/d/...` kanonik dengan 13 karakter | Resolve dengan kredensial dan IP unduh penerima. |
| AllDebrid | `https://alldebrid.com/f/...` yang terkunci | Buka kunci dengan kredensial penerima. |
| TorBox | Hash dan path/ukuran file | Dapatkan torrent sisi penerima saat pertama kali diputar, lalu cocokkan file-filenya berdasarkan path dan ukuran. |
| Premiumize, Offcloud, Debrid-Link | Hash dan path/ukuran file | Tambahkan hash di akun penerima saat pertama kali diputar, lalu cocokkan file-filenya berdasarkan path dan ukuran. |

Nama akun, kredensial, ID torrent/file dari provider, URL CDN, URL input MediaInfo,
ID Plex, status perbaikan, dan antrean penghapusan tidak diekspor. Importer akan menolak
field yang tidak dikenal serta URL referensi yang membawa kredensial atau tidak sesuai.
Importer juga tidak mengambil URL saat memvalidasi manifest. Usenet tetap memakai format sumber `.nzb`;
cache runtime NZB tidak bisa diekspor sebagai torrent portabel.

## Pemutaran dan batasan {#playback-and-limits}

Pelacakan lokal mengubah siapa yang memiliki katalog. Itu tidak menjamin bahwa penyedia masih menyimpan datanya atau bisa menyajikannya. Akses akun, lokasi jaringan yang diizinkan, slot aktif, kuota, dan batas laju tetap berlaku.

Kalau ada, RD dan AD memakai referensi terkunci yang dibagikan. Manifes hanya-hash, serta referensi RD yang oleh API dipastikan tidak ada, bisa menetapkan konten di akun penerima. TorBox selalu membutuhkan lampiran akun itu dan selalu memakai ulang torrent yang cocok dan sudah ada di akun penerima lebih dulu. Penambahan memakai pengaturan jeda penyedia yang sudah ada dan dijalankan berurutan per akun. Kalau akun melaporkan jumlah slotnya, atau zurg mengetahuinya, penambahan ke akun yang penuh akan ditolak, dan permintaan pemutaran berikutnya setelah satu menit akan dicoba lagi. AllDebrid, Premiumize, dan Offcloud tidak melaporkan apa pun, jadi penambahan tetap dijalankan dan akun yang penuh akan menolaknya. Penambahan yang belum pasti ditahan selama 30 menit sebelum dicoba lagi. Torrent yang sedang disiapkan hanya dicek saat pemutaran diminta lagi.

ID penerima dan handle file native yang sudah diselesaikan disimpan secara pribadi di `data/local-torrents/`. Catatan itu tetap ada setelah restart dan ikut masuk ke backup biasa. zurg tidak pernah menghapus lampiran tersebut secara otomatis, karena penambahan idempoten bisa saja mengembalikan torrent yang sudah dimiliki penerima. Offloading juga tidak menyentuhnya. Kegagalan penyedia membuat entri lokal tetap terlihat dan mundur, bukan memulai perbaikan di latar belakang atau mengulang penambahan untuk setiap pemindaian.

Rilis arsip lokal menampilkan volume sumbernya tanpa ekstraksi otomatis atau pemeriksaan di latar belakang. Path eksplisit di dalam arsip tetap bisa memanggil archive reader. Probing MediaInfo otomatis dan prefetch file berikutnya dinonaktifkan pada entri yang punya salinan lokal.

## Migrasi dump lama {#migrate-an-old-dump}

Ekspor `dump/` dengan perintah di atas, letakkan hasilnya di direktori `torrents/<name>/` milik akun penerima, lalu aktifkan `library.source: local`. Matikan `load_dumped_torrents` setelah migrasi. Pembaca `__dump__` lama yang bersifat opt-in tetap dipertahankan demi kompatibilitas; library lokal baru tidak menggunakannya. Cache runtime yang tidak memiliki tipe akun perlu diekspor ulang dari instance yang mengenali provider-nya sebelum bisa dibagikan.

Backup yang ditulis oleh build ini menggunakan format 2 agar menyertakan root durable yang baru. Perintah restore masih membaca backup format 1. Build yang lebih lama menolak format 2 daripada diam-diam menghilangkan library lokal.
