# Penilaian UI/UX Konfigurasi Direktori {#directory-configuration-uiux-assessment}

## Cakupan dan kondisi saat ini {#scope-and-current-state}
- Halaman: `Directory Configuration` di `http://localhost:9999/directories/`.
- UI saat ini: satu tabel datar yang berisi direktori di bawah judul seperti "MEDIA" dan "RECENT", dengan kolom nama direktori, urutan numerik, dan tautan aksi ("Edit", "Delete").
- Perilaku: edit/delete hanya memicu aksi sederhana; tidak ada pengelompokan selain judul, dan tidak ada alur pembuatan/pengeditan khusus untuk opsi YAML lengkap.

## Celah UX utama {#key-ux-gaps}
- **Arsitektur informasi**
  - Grup terlihat datar secara visual, jadi pengguna tidak bisa fokus ke satu grup dalam satu waktu.
  - Pengurutan mengandalkan angka manual (`group_order`), yang tidak intuitif dan rawan salah.
  - Belum ada kolom pencarian atau filter untuk cepat menemukan direktori.
  - Belum ada aksi massal (hapus/pindah) atau cara untuk memilih banyak item sekaligus.
- **Pengalaman membuat dan mengedit**
  - Alur tambah dan edit belum menampilkan skema YAML lengkap (pengaturan umum, filter ukuran/file/tag/waktu).
  - Belum ada tata letak yang terstruktur; field tidak dikelompokkan, sehingga pengguna cepat kewalahan saat opsinya makin banyak.
  - Belum ada pembuat aturan AND/OR bertingkat yang meniru logika filter bersarang di YAML.
  - Field terkait tag (`tags_match_all`, `tags_match_any`) sulit ditemukan dan belum ada bantuan untuk memilih.
  - Belum ada pratinjau langsung torrent yang cocok dengan pengaturan filter saat ini.
- **Panduan dan validasi**
  - Belum ada tooltip atau ikon info per field, dan belum ada tautan ke dokumentasi lengkap (misalnya `tags.md`).
  - Belum ada peringatan proaktif jika sebuah direktori tidak akan menghasilkan torrent sama sekali atau belum punya filter yang diperlukan.
  - Field regex dan pola lainnya belum punya umpan balik validasi real-time.
  - Penghapusan langsung terjadi tanpa konfirmasi atau opsi untuk membatalkan.
- **Aksesibilitas dan responsivitas**
  - Kontras dan keterbacaan belum diverifikasi terhadap WCAG; aksi yang hanya berupa ikon mungkin tidak punya label.
  - Drag-and-drop belum tersedia, dan belum ada cara mengurutkan ulang yang bisa diakses lewat keyboard.
  - Tata letak mobile belum dioptimalkan: tabel tidak menyesuaikan diri menjadi kartu bertumpuk, dan formulir mungkin tidak bisa digulir dengan baik.
  - Aksi masih berupa tautan teks; ikon dan target klik yang jelas belum ada.
- **Performa dan kehalusan interaksi**
  - Pencarian/filter (setelah ditambahkan nanti) perlu debouncing dan paginasi atau virtualisasi untuk daftar yang besar.
  - Drag-and-drop (setelah ditambahkan nanti) perlu penyimpanan dan fallback yang baik jika penyimpanan gagal.

## Perubahan UI/UX yang direkomendasikan {#recommended-uiux-changes}
- **Tampilan grup**
  - Tampilkan setiap `group` tingkat atas (misalnya media/recent/example) sebagai kartu atau bagian yang bisa dilipat, lengkap dengan daftarnya sendiri.
  - Sediakan aksi cepat per grup (lipat/buka, pilih massal).
- **Pengurutan**
  - Ganti kolom nomor urut dengan pegangan drag untuk mengurutkan ulang dalam grup; tampilkan urutan yang dihitung lewat tooltip atau badge sebaris.
  - Sediakan kontrol urutan yang ramah keyboard (tombol pindah ke atas/bawah) sebagai cadangan untuk aksesibilitas dan perangkat mobile.
- **Pencarian dan aksi massal**
  - Tambahkan bar pencarian/filter di atas daftar; beri debounce pada input.
  - Tambahkan checkbox untuk hapus atau pindah massal; sertakan opsi "pilih semua dalam grup".
- **Permukaan tambah/edit**
  - Gunakan modal atau panel samping dengan tata letak berbagian: General, Size Filters, File Filters, Tag Filters, Time Filters, dan Advanced.
  - Tambahkan subbagian yang bisa dilipat agar tidak membingungkan; simpan status terbuka selama sesi.
- **Pembuat aturan**
  - Sediakan pembuat AND/OR visual yang meniru struktur YAML: grup bersarang, pill kondisi, pemilih properti/operator/nilai (misalnya has_episodes, regex dengan matches/does not match).
  - Izinkan konversi AND/OR di setiap node; tampilkan pratinjau ekspresi hasilnya.
- **Pemilih tag**
  - Multi-select dengan autocomplete dari tag yang tersedia; tampilkan deskripsi dan jumlah tag sebagai tooltip jika ada.
  - Bedakan dengan jelas `tags_match_all` dan `tags_match_any`.
- **Pratinjau**
  - Tambahkan "Preview matching torrents" untuk mengambil contoh hasil sesuai status filter saat ini; tampilkan status skeleton/loading dan penanganan error.
- **Panduan**
  - Tampilkan tooltip sebaris atau ikon info untuk setiap field; tautkan ke dokumentasi lebih lengkap bila perlu (misalnya [tags.md](../reference/tags.md)).
  - Tampilkan petunjuk kontekstual (misalnya "Only show largest file") yang menjelaskan efek samping perilaku.
- **Validasi dan keamanan**
  - Blokir penyimpanan saat filter wajib kosong atau validasi gagal; tampilkan error sebaris.
  - Validasi regex real-time di sisi klien plus konfirmasi server saat submit agar tidak berbeda hasil.
  - Beri peringatan jika konfigurasi tidak akan cocok dengan torrent apa pun (berdasarkan pratinjau atau heuristik).
  - Dialog konfirmasi untuk penghapusan; tawarkan undo singkat/snackbar jika memungkinkan (soft delete jika didukung).
- **Aksesibilitas dan desain responsif**
  - Periksa kontras untuk palet yang dipilih; pastikan status fokus dan label ARIA untuk kontrol.
  - Pastikan bagian yang bisa dilipat, pegangan drag, dan aksi bisa diakses dengan keyboard.
  - Di mobile, tampilkan grup sebagai kartu bertumpuk; pastikan modal/panel bisa di-scroll dengan header lengket untuk aksi.
  - Pasangkan ikon dengan label untuk aksi utama; pastikan target yang hanya berikon punya nama yang bisa diakses.
- **Polesan visual**
  - Gunakan ikonografi yang konsisten untuk edit/hapus/urutkan ulang; tambahkan divider tipis dan chip untuk menandai konteks atau status grup.
  - Pertimbangkan pewarnaan per grup agar mudah dipindai (dengan kontras yang aksesibel).

## Dependensi dan asumsi yang perlu dikonfirmasi {#dependencies-and-assumptions-to-confirm}
- Dukungan API untuk: menyimpan urutan grup, operasi massal, serialisasi AND/OR bertingkat, sumber metadata tag, dan endpoint preview query.
- Perilaku penghapusan: soft delete vs hard delete, jendela undo, dan kebutuhan audit.
- Model kepemilikan/izin (jika multi-user) untuk menampilkan metadata terakhir diedit dan mencegah konflik.
- Batasan performa untuk preview/pencarian; strategi paging atau virtualisasi untuk dataset besar.

## Prioritas implementasi {#implementation-priorities}
1) Susun ulang daftar menjadi kartu/collapsible yang dikelompokkan; tambahkan bar pencarian/filter dan dialog konfirmasi.
2) Perkenalkan modal atau panel samping berbagai bagian untuk tambah/edit dengan tooltip dan validasi dasar; tambahkan multi-select tag.
3) Tambahkan drag-and-drop + pengurutan ulang dengan keyboard yang disimpan permanen; terapkan rule builder AND/OR.
4) Tambahkan preview torrent yang cocok dengan request yang di-debounce dan penanganan error.
5) Selesaikan aksesibilitas (jalur keyboard, ARIA) dan tata letak kartu bertumpuk yang responsif untuk mobile.
