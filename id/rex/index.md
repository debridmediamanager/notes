# rex

[rex](https://rex.debridmediamanager.com/id/) adalah media server untuk aplikasi resmi Plex yang tidak memiliki file apa pun. Sebuah source memberi tahu rex apa saja yang ada di library Anda, lalu menyajikan setiap file. rex men-stream file tersebut saat Anda menekan play. rex gratis untuk penggunaan pribadi. [Source code](https://github.com/debridmediamanager/rex)-nya bersifat publik di bawah lisensi PolyForm Noncommercial. rex berjalan di Linux, macOS, dan Windows, serta sebagai image Docker Linux `ghcr.io/debridmediamanager/rex:nightly` ([dengan app Anda sendiri](any-source.md#run-rex-in-docker), [dengan zurg](with-zurg.md#run-rex-in-docker)).

- [Pertanyaan tentang rex](faq.md) menjawab hal-hal yang perlu Anda ketahui sebelum memasang
- [rex dengan app Anda sendiri](any-source.md) menyiapkan source yang menyajikan file lewat HTTP dan menggunakan feed API rex
- [rex dengan addon Stremio Anda](stremio.md) mengisi rex dengan rex-stremio. Gratis dan tidak perlu sponsorship
- [rex dengan zurg](with-zurg.md) mengisi rex dari akun debrid atau Usenet lewat zurg
- [Live TV dengan rex](live-tv.md) menambahkan channel live dan panduan acara lewat rex-live-sports
- [Musik dengan rex](music.md) menambahkan library musik untuk Plexamp dan aplikasi Plex yang didukung
- [Pindah dari Plex ke rex](from-plex.md) menjalankan rex di samping Plex atau menggantikannya
- [Bagikan rex dengan keluarga dan teman](sharing.md) mengundang orang-orang yang Anda tonton bersama
- [Membuat addon rex](addons.md) membawa video rumahan, rekaman, atau katalog Stremio ke dalam rex
- [Tutorial addon](addon-home-videos.md) membuat addon video rumahan, musik, atau IPTV lengkap dalam satu file Python
- [Lebih banyak dari addon Anda](addon-more.md) menambahkan subtitle, extras, chapter, collection, playlist, dan lainnya
- [Bawa riwayat tontonan Anda](import-watched.md) menyalin status tonton, rating, dan titik lanjut dari Plex
- [Kometa dengan rex](kometa.md) membuat collection dan badge poster di library rex
- [Aplikasi mengunduh dari provider Anda](direct-download.md) memungkinkan aplikasi Plex mengunduh dari link source sehingga mesin rex tidak menyimpan film apa pun
