# rex

[rex](https://rex.debridmediamanager.com/id/) adalah media server untuk aplikasi resmi Plex yang tidak memiliki file apa pun. Sebuah source memberi tahu rex apa saja yang ada di library Anda, dan melayani setiap file. rex men-stream file tersebut saat Anda menekan play. rex gratis untuk penggunaan pribadi. [Source code](https://github.com/debridmediamanager/rex)-nya bersifat publik di bawah lisensi PolyForm Noncommercial. rex berjalan di Linux, macOS, dan Windows, serta sebagai image Docker Linux `ghcr.io/debridmediamanager/rex:nightly` ([dengan app Anda sendiri](any-source.md#run-rex-in-docker), [dengan zurg](with-zurg.md#run-rex-in-docker)).

- [rex untuk Android](android.md) menjalankan rex beserta addon-nya di ponsel, tablet, atau TV box, tanpa komputer. Gratis. Untuk sponsor, ada [zurg+rex](../zurg/guides/android.md), sebuah server Plex di ponsel Anda, yang juga menghubungkan library debrid dan Usenet Anda ke rex
- [Pertanyaan tentang rex](faq.md) menjawab hal-hal yang perlu Anda ketahui sebelum menginstal
- [rex dengan app Anda sendiri](any-source.md) menyiapkan source yang melayani file melalui HTTP dan menggunakan feed API rex
- [rex dengan addon Stremio Anda](stremio.md) mengisi rex dengan rex-stremio. Gratis dan tidak memerlukan sponsorship
- [rex dengan zurg](with-zurg.md) mengisi rex dari akun debrid atau Usenet melalui zurg
- [Live TV dengan rex](live-tv.md) menambahkan saluran live dan panduan program melalui rex-live-sports
- [Musik dengan rex](music.md) menambahkan library musik untuk Plexamp dan app Plex yang didukung
- [Pindah dari Plex ke rex](from-plex.md) menjalankan rex di samping Plex atau menggantikannya
- [Bagikan rex dengan keluarga dan teman](sharing.md) mengundang orang-orang yang Anda tonton bersama
- [Membuat addon rex](addons.md) membawa video rumahan, rekaman, atau katalog Stremio ke dalam rex
- [Tutorial addon](addon-home-videos.md) membuat addon lengkap untuk video rumahan, musik, atau IPTV dalam satu file Python
- [Lebih banyak dari addon Anda](addon-more.md) menambahkan subtitle, extras, chapter, collection, playlist, dan lainnya
- [Bawa riwayat tontonan Anda](import-watched.md) menyalin status tontonan, rating, dan titik lanjut dari Plex
- [Kometa dengan rex](kometa.md) membuat collection dan badge poster di library rex
- [App mengunduh dari provider Anda](direct-download.md) membiarkan app Plex mengunduh dari link source sehingga mesin rex tidak menyimpan film apa pun
