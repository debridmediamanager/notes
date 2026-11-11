# Menyelaraskan sapuan sampah Plex dengan status file milik zurg {#aligning-the-plex-trash-sweep-with-zurgs-own-file-status}

## Tujuan dokumen ini {#purpose-of-this-document}

Pembersihan sampah Plex saat ini memutuskan apa yang dihapus dari pustaka Plex dengan **ketiadaan file ditambah timer usia**. zurg sebenarnya sudah tahu sesuatu yang jauh lebih baik, yaitu apakah konten di balik file itu masih bisa diperbaiki atau sudah benar-benar mati, tetapi zurg tidak memeriksanya.

Dokumen ini adalah rencana untuk mengganti timer itu dengan pengetahuan tersebut. Dokumen ini perlu ditinjau **sebelum** ada kode yang ditulis, karena perubahan ini menentukan apa yang dihapus dari pustaka media, dan perilaku saat ini salah ke dua arah: pembersihan menunggu dua minggu untuk menghapus konten yang sudah diketahui mati sejak hari pertama, dan pembersihan menghapus konten yang masih sedang diperbaiki oleh zurg.

Dokumen ini mencatat apa saja yang sudah diverifikasi di kode dan di pustaka yang sedang berjalan, apa yang diusulkan, dan apa yang sengaja dibiarkan. Semua yang dinyatakan sebagai fakta di bawah ini sudah dicek pada sistem yang sedang berjalan tanggal 2026-08-16, bukan hanya ditebak dari penamaan.

Cakupan: `internal/plexsweep`, `internal/plexdb`, dan query baru yang hanya membaca dari `internal/torrent`. Tidak ada perubahan pada perilaku perbaikan itu sendiri.

---

## 1. Latar belakang — apa yang sudah dirilis, dan mengapa perlu ditinjau ulang {#1-background--what-shipped-and-why-it-needs-revisiting}

Empat commit masuk untuk sweep ini:

| Commit | Isi |
|---|---|
| `4737b677` | Beri peringatan saat `autoEmptyTrash` di Plex aktif |
| `020042a3` | Sweeper: deteksi, guard, perbaikan, dan penghapusan per item |
| `51cc9f69` | UI config Dashboard dan dokumentasi |
| `1a481a8f` | Hitung perbaikan terhadap batas, bukan hanya penghapusan |
| `c6f41621` | `plex_trash_sweep_min_age_days`, default 14 |

Invarian utama sweep ini tidak berubah dan tetap berlaku: **tidak pernah ada yang masih punya
file yang dihapus.** Item yang punya file yang masih ada akan diperbaiki, atau dibiarkan dengan ikon trash-nya. Show dan season yang masih punya episode yang ada tidak pernah disentuh. Penghapusan dilakukan per item, bukan dengan `emptyTrash` milik Plex yang berlaku untuk seluruh section.

Yang sedang ditinjau ulang hanya aturan untuk *kapan entri yang benar-benar hilang boleh
dihapus*.

### Timer hanyalah perkiraan untuk pertanyaan yang bisa langsung dijawab zurg {#the-timer-is-a-proxy-for-a-question-zurg-can-answer-directly}

`plex_trash_sweep_min_age_days` menunggu 14 hari sebelum menghapus sebuah entri, dengan alasan bahwa ikon sampah merah adalah satu-satunya pemberitahuan yang didapat operator bahwa konten hilang, dan menghapus entri berarti pemberitahuan itu ikut hilang.

Niatnya sudah benar, tapi mekanismenya cuma tebakan. Mekanisme ini salah ke dua arah:

- Torrent yang ditandai `infringing torrent` **langsung diketahui sudah mati**. Membiarkan entri Plex-nya bertahan dua minggu tidak membantu siapa pun, karena menunggu tidak akan membuatnya hidup lagi.
- Torrent yang masih dicoba ulang bisa butuh **lebih dari 14 hari** untuk kembali. Timer menghapus entrinya saat zurg masih mengerjakannya. Ini kesalahan yang lebih parah, karena entri library dihapus untuk konten yang kemudian kembali.

## 2. Fakta yang sudah diverifikasi {#2-verified-facts}

### 2.1 Model status zurg {#21-zurgs-state-model}

Ada tiga level file dan dua level torrent (dihitung di `internal/torrent`, tidak termasuk tes):

| Level | Status |
|---|---|
| `File.State` | `ok_file`, `broken_file`, `deleted_file` |
| `Torrent.State` | `ok_torrent`, `broken_torrent` |

Keduanya adalah mesin `pkg/fsm`. `FSMWithTime` mencatat timestamp unix setiap transisi dan mendukung `SinceWhen`, jadi "sudah berapa lama ini rusak" sebenarnya sudah bisa dijawab tanpa menambahkan apa pun.

**Satu file rusak sudah cukup untuk menghukum seluruh torrent.**
`MarkFileBrokenAndEnqueueRepair` (`internal/torrent/hooks.go:215-234`):

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

Log-nya menulis *"has broken file"*, dalam bentuk tunggal. Satu dari sepuluh file yang rusak dan sepuluh dari sepuluh yang rusak menghasilkan status torrent yang sama persis. Tidak ada yang mengagregasi status file.

**`Unfixable` mengagregasi per akun, bukan per file.**
`markAsUnrepairable` (`internal/torrent/unplayable_unrepairable.go:44-71`):

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

Entri dianggap mati kalau **tidak ada lagi salinan yang bisa diperbaiki**. Sengaja bukan "setiap salinan punya alasan". Salinan yang memang tidak mungkin diperbaiki (backend Usenet tidak punya magnet adder) akan membuat rilis mati tetap memenuhi syarat untuk diperbaiki selamanya. `File` sama sekali tidak punya field unrepairable (`internal/torrent/file_types.go`).

Jadi ketiga level menjawab tiga pertanyaan berbeda, dan **tidak satu pun menjawab cakupan**:

| Level | Memberi tahu | Tidak bisa memberi tahu |
|---|---|---|
| `File.State` | file ini ok / rusak / dihapus | apakah file ini mati permanen |
| `TorrentCopy.UnrepairableReason` | salinan di akun ini mati | apa pun tentang akun lain |
| `Torrent.UnrepairableReason` | tidak ada akun yang bisa memperbaiki ini | seberapa banyak bagian rilis yang terdampak |

### 2.2 Pengukuran langsung (perpustakaan produksi, 2026-08-16) {#22-live-measurements-a-production-library-2026-08-16}

Persentase di bawah ini adalah dari torrent yang rusak, yang jumlahnya sekitar **3% dari library**.

**Hampir semua yang rusak (98%) punya alasan `Unfixable`**:

| Alasan | Persentase dari yang rusak |
|---|---|
| stalled download | 38% |
| infringing torrent | 37% |
| repair failed | 15% |
| duplicate file IDs (pack torrent) | 4% |
| rar'ed by RD | 1% |
| repair failed, no seeders | 1% |
| the lone cached file is broken | under 1% |
| invalid file ids | under 1% |
| repair failed, download status: error | under 1% |
| provider cannot re-add torrents | under 1% |

**Sisanya (2%) rusak tanpa alasan** — tetap bisa diperbaiki.

**Tapi `Unfixable` tidak sama dengan mati.** zurg sebenarnya sudah memilah alasan-alasan ini menjadi permanen dan bisa dipulihkan (`internal/torrent/unrepairable_reasons.go:44-70`). `permanentReasons` berisi delapan vonis yang tidak bisa diubah dengan mencoba ulang — infringing, unsupported, unavailable, invalid, too big, not allowed, no repairable files, invalid file ids — ditambah alasan apa pun yang diawali `repair failed, download status:`. Selain itu, termasuk dua kelompok terbesar di atas, secara eksplisit dianggap sementara: `stalled download`, `repair failed`, `duplicate file IDs`, `rar'ed by RD`, `not cached`, `the lone cached file is broken`, `full torrent repair failed`.

`repair failed, no seeders` adalah yang kesembilan saat persentase di atas diambil, dan entri yang membawanya di sini adalah alasan kenapa sekarang tidak lagi: tidak ada backend yang diajak bicara zurg melaporkan seeders, jadi vonis itu tidak pernah benar-benar diukur — ia cuma disimpulkan dari repair yang kehabisan waktu. Sekarang ia bersifat sementara, dan juga tidak bisa dicatat (`verdictClaims`), jadi entri-entri itu pensiun dan dicoba lagi seperti yang lain.

Kalau pembagian itu diterapkan ke persentase di atas:

| | Persentase dari yang rusak |
|---|---|
| Permanen tidak bisa diperbaiki | **39%** |
| Tidak bisa diperbaiki tapi bisa dipulihkan | **59%** |
| Rusak, belum ada alasan | 2% |

Alasan yang tidak dikenali (`provider cannot re-add torrents`, satu entri di sini) tidak ada di kedua daftar, dan `IsPermanentlyUnrepairable` mengembalikan false untuknya — jawaban yang konservatif, dan memang itu yang kita mau.

Ini temuan paling penting untuk desainnya: **aturan yang berpatokan pada "`Unfixable` is set" akan menghapus entri Plex untuk dua setengah kali lebih banyak rilis daripada yang benar-benar mati.**

Yang penting, di mana torrent rusak itu berada terhadap mount:

| | Persentase dari yang rusak | Yang dilihat Plex |
|---|---|---|
| Rusak, **masih ada di mount** | sekitar tiga dari empat | File terlihat ada → tidak pernah di-tombstone. Tidak ada ikon sampah; gagalnya baru terasa saat diputar |
| Rusak, **sudah hilang dari mount** | sekitar satu dari empat | File hilang → di-tombstone → **inilah kandidat sweep** |

Ini pengukuran kuncinya. Artinya sweep hanya pernah bertemu kelompok kedua, dan untuk kelompok itu zurg biasanya sudah punya vonis.

Di sisi Plex, host yang sama: ada tumpukan leaf yang sudah di-trash, **tidak ada** yang lewat jendela 14 hari (tombstone tertua 2026-08-11). Ditambah beberapa show shell kosong dan beberapa lusin season shell kosong.

---

## 3. Celahnya {#3-the-gap}

`broken_torrent` berarti "setidaknya ada satu hal yang salah". Itu granularitas yang salah untuk sweep.

Contohnya: sebuah pack sepuluh episode di mana file satu episode hilang permanen, tetapi torrent-nya secara keseluruhan masih bisa diperbaiki. Kalau ditanyakan ke torrent, hasilnya "still repairable", jadi sweep akan tetap menyimpan entri Plex episode mati itu **selamanya**.

Tidak ada state yang berarti *"seluruh rilis ini mati"* yang berbeda dari *"ada sesuatu di rilis ini yang rusak"*.

## 4. Desain {#4-design}

### 4.1 Jangan tambahkan status keempat yang disimpan {#41-do-not-add-a-fourth-persisted-state}

Langkah yang paling jelas adalah membuat state torrent baru, misalnya `dead_torrent`. **Ditolak.**

Setiap tempat yang mengubah state torrent harus ikut mengelolanya, dan flag "all files broken" yang sudah usang lebih buruk daripada tidak ada flag sama sekali, karena flag itu *memberi izin untuk penghapusan*. Informasinya sebenarnya sudah ada di state file, hanya belum digabungkan.

Jadi, hitung saja dari data yang ada:

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

Cara ini murah, selalu konsisten, dan bisa ditampilkan di dashboard tanpa perlu disimpan.

Definisi yang perlu diputuskan saat implementasi: `deleted_file` harus dihitung sebagai tidak-terbaca bersama `broken_file`, dan torrent dengan **nol** file harus mengembalikan false, bukan true secara otomatis. Rilis kosong bukan bukti bahwa torrent itu mati.

### 4.2 Tanyakan ke file, lalu gunakan torrent sebagai cadangan {#42-ask-the-file-fall-back-to-the-torrent}

Sweep memetakan path Plex ke file zurg, lalu menerapkan:

| Keputusan zurg | Sweep |
|---|---|
| file adalah `ok_file` | **pertahankan** — file itu sebenarnya belum hilang |
| `broken_file`, torrent tidak punya alasan tidak bisa diperbaiki | **pertahankan** — repair mungkin memulihkannya, berapa pun lama waktunya |
| `broken_file`, alasan sudah diisi tapi **tidak** permanen | **pertahankan** — zurg masih menganggapnya bisa dipulihkan |
| `broken_file`, alasannya **permanen** tidak bisa diperbaiki | **hapus** — tidak ada percobaan ulang yang bisa mengubah keputusan ini |
| zurg tidak punya torrent untuk path ini | **gunakan jendela umur** |

Tes permanen adalah `IsPermanentlyUnrepairable(reason)`
(`internal/torrent/unrepairable_reasons.go:59`), dan dipakai persis seperti `ForceRepairTorrent` memakainya. Memakai fungsi ini daripada membuat daftar sendiri itu penting: alasan yang ditambahkan ke `permanentReasons` nanti harus otomatis mengubah perilaku sweep, dan alasan yang tidak dikenali harus tetap dianggap tidak permanen.

`AllFilesBroken()` **tidak** cukup untuk memberi izin menghapus. Release yang semuanya rusak tapi punya alasan yang masih bisa dipulihkan tetap sedang dikerjakan. Fungsi ini dipakai untuk memperjelas laporan dan dashboard, serta membedakan "satu episode dari sepuluh hilang" dengan "seluruh pack hilang" supaya mudah dibaca manusia di log.

Baris terakhir menjelaskan kenapa `plex_trash_sweep_min_age_days` tetap ada. Begitu torrent hilang sepenuhnya dari akun, `.zurgtorrent`-nya ikut hilang, dan zurg tidak punya lagi keputusan untuk diberikan. Timer tidak lagi menjadi aturan utama dan berubah menjadi fallback untuk kasus yang memang tidak punya pilihan lain.

Perubahan ini juga menurunkan posisi setting ini di UI, yang sekaligus menyelesaikan keluhan terpisah bahwa labelnya ("Keep Broken Entries Visible") menggambarkan efek samping, bukan tindakannya.

### 4.3 Pencarian path → torrent → file {#43-path--torrent--file-lookup}

Matcher Plex yang ada berjalan ke arah sebaliknya: `buildPlexDirIndex`
(`internal/plex/matcher.go:539`) mengindeks komponen path Plex dan mencarinya berdasarkan torrent key. Sweep butuh kebalikannya, dibangun dari ide yang sama:

1. Buat `map[strings.ToLower(GetKey(torrent))] *Torrent` dari
   `DirectoryMap.Get(INT_ALL)`.
2. Untuk path Plex, pecah jadi komponen dengan normalisasi yang sama seperti `splitPathComponents` (`matcher.go:525`) dan cari tiap komponen. Direktori rilis adalah komponen yang cocok.
3. Di dalam torrent tersebut, cocokkan sisa path dengan `File.Path` (`internal/debrid/types.go:133`) untuk menemukan file yang dimaksud.

Alasan ini harus lewat `TorrentManager` dan bukan string-match `data/*.zurgtorrent`: nama yang sudah dibedakan (`Some.Release {a1b2c3}`), salinan multi-akun, dan rename hanya bisa diselesaikan dengan benar lewat `GetKey`.

**Lookup yang gagal bukan izin untuk menghapus.** Kalau tidak bisa diselesaikan → anggap sebagai "zurg tidak punya pendapat" → fallback ke age-window.

### 4.4 Yang tidak berubah {#44-what-does-not-change}

- Invarian: tidak ada yang memiliki file aktif yang dihapus.
- Show dan season yang memiliki turunan aktif tidak pernah disentuh.
- Per item `DELETE`, jangan pernah `emptyTrash`.
- Penjaga: rclone dikelola dan berjalan, mount membaca, Plex tidak sedang memindai.
- Snapshot sebelum ada perubahan; batas (cap) berlaku untuk perbaikan *dan* penghapusan.

Aturan baru hanya membuat sweep **lebih** konservatif atau **lebih** presisi —
aturan itu tidak pernah memberi izin untuk penghapusan yang sebenarnya akan ditolak oleh kode saat ini.

---

## 5. Rencana implementasi {#5-implementation-plan}

| # | Langkah | File |
|---|---|---|
| 0 | Pastikan pemisahan permanen/dapat dipulihkan memang gerbang yang tepat, dengan hitungan dry-run terhadap library live sebelum ada yang dihapus | — |
| 1 | `AllFilesBroken()` + unit test (release kosong, campuran, semua rusak, semua terhapus) | `internal/torrent/` |
| 2 | Lookup status read-only: path → torrent → file, mengembalikan nilai verdict yang kecil | file baru di `internal/torrent/` atau `internal/plexsweep/` |
| 3 | Definisikan tipe verdict (`StatusOK`, `StatusRecoverable`, `StatusPermanentlyDead`, `StatusUnknown`) supaya sweep tidak pernah menangani internal zurg secara langsung | `internal/plexsweep` |
| 4 | Hubungkan lookup ke `Sweeper` lewat interface, seperti `Mount`/`Library`/`Trash` yang sudah ada | `internal/plexsweep/sweep.go` |
| 5 | Terapkan decision table; pertahankan age window sebagai fallback untuk `StatusUnknown` | `internal/plexsweep/sweep.go` |
| 6 | Inject `TorrentManager` di call site | `internal/app.go` |
| 7 | Tes: satu untuk tiap baris decision table, plus tes kegagalan lookup yang membuktikan unresolvable tidak pernah menghapus | `internal/plexsweep/sweep_test.go` |
| 8 | Dokumentasi: `docs/config.md`, `config.example.yml`, `docs/CHANGELOG.md`, dan ubah ulang label dashboard | docs + templates |

Catatan urutan: langkah 1–3 murni penambahan tanpa perubahan perilaku dan bisa masuk
sebagai satu commit; langkah 5 adalah satu-satunya yang mengubah apa yang dihapus.

---

## 6. Risiko dan pertanyaan terbuka {#6-risks-and-open-questions}

1. **Urutan pemasangan.** Sudah dikonfirmasi: `startPlexTrashSweep` dipanggil di `internal/app.go:268`, sedangkan `TorrentManager` dibuat di `internal/app.go:285`, yaitu setelahnya. Pemanggilan itu harus dipindah ke belakang, atau pakai setter. Perlu dicek dulu apakah ada yang bergantung pada posisinya yang sekarang.
2. **Pencarian yang ambigu.** Dua torrent yang kuncinya bertabrakan dengan komponen path yang sama. Solusinya: kalau lebih dari satu kandidat cocok, anggap sebagai `StatusUnknown` daripada memilih salah satu.
3. **`only_show_the_biggest_file`.** Direktori movies menyembunyikan file, jadi path Plex bisa menyebut file yang bukan file yang akan disajikan zurg. Pencarian tidak boleh berasumsi bahwa nama file Plex muncul persis sama di `File.Path`.
4. **Biaya.** Membangun indeks kunci di setiap sapuan berarti O(library). Dengan beberapa ribu torrent, itu masih sepele, dan sapuannya jalan setiap hari. Bangun indeks per sapuan, bukan per item.
5. ~~**Apakah `Unfixable` pernah dihapus?**~~ **Sudah diselesaikan: ya.** `refresh.go:851-857` menghapusnya saat sebuah torrent lolos verifikasi dan kembali ke `ok_torrent` ("all links intact, no broken files"), dan `repair.go:165-181` menghapusnya (entri dan setiap salinan) saat perbaikan dipaksa. Jadi rilis yang sudah pulih tidak membawa vonis lama, dan desainnya tidak perlu menjaga terhadap hal itu.
6. **Torrent yang rusak tapi masih ada.** Di luar cakupan di sini: Plex tidak pernah menandai torrent ini sebagai terhapus, jadi sapuan tidak pernah melihatnya. Perlu dicatat bahwa torrent ini tidak terlihat oleh Plex maupun oleh fitur ini sampai pemutaran gagal.

## 7. Cara implementasinya (2026-08-16) {#7-how-it-was-implemented-2026-08-16}

Sudah di-merge sebagai `feat: decide plex trash sweep removals from zurg's repair verdicts`.
Jika implementasi menjawab pertanyaan yang dibiarkan terbuka di dokumen ini, atau menyimpang dari §4, keputusan dan alasannya:

- **Pencarian mencocokkan direktori induk dari path secara persis** dengan `DirectoryMap[INT_ALL]`, alih-alih memindai setiap komponen path (§4.3). Mount menata rilis secara datar — `<library dir>/<key>/<visible name>` — dan Plex mencatat path dari mount, yang menyajikan key apa adanya. Jika tidak ada yang cocok persis, jawabannya unknown, dan ambiguitas tabrakan key (risiko 2) hilang: key yang persis tidak bisa bertabrakan.
- **Baris 1 pada tabel keputusan diubah.** `ok_file` yang ternyata tidak ada di mount berarti file itu disembunyikan oleh filter, bukan "tidak benar-benar hilang". Jika tetap dipertahankan selamanya, ikon sampah permanen akan tertinggal setelah filter diubah. Keputusan kembali ke jendela umur.
- **`deleted_file` dihitung bersama `broken_file`** di setiap aturan, tidak hanya di `AllFilesBroken()`. Baris-baris tabel dibaca sebagai "bukan `ok_file`".
- **Item multi-versi dinilai sebagai satu kesatuan** (tabel sebelumnya per file, sementara unit sapuan adalah item Plex yang punya bagian): satu bagian yang bisa dipulihkan membuat seluruh item tetap dipertahankan; item dianggap mati hanya jika semua bagiannya mati; kombinasi lain jatuh ke jendela umur.
- **Nama file yang mengarah ke torrent tetapi tidak ke file** (rename, daftar isi arsip, `only_show_the_biggest_file` — risiko 3) dianggap mati hanya jika alasan entri itu permanen **dan** `AllFilesBroken()`. Bisa dipulihkan jika torrent rusak tanpa putusan permanen, dan selain itu unknown. Nama yang tidak cocok tidak pernah dihukum karena asosiasi selama masih ada file yang bisa dibaca.
- **Wiring (risiko 1):** `startPlexTrashSweep` dipindah ke bawah pembuatan manager di `internal/app.go`. Tidak ada yang bergantung pada posisi lamanya. Putusan sampai ke sapuan lewat `plexsweep.Verdicts`, yang diimplementasikan oleh `TorrentManager.FileStatusForMountPath`. Sebelum refresh pertama mengisi `INT_ALL`, setiap pencarian menjawab unknown dan sapuan berperilaku persis seperti versi jendela umur.

## 8. Di luar cakupan secara eksplisit {#8-explicitly-out-of-scope}

- **Kosong show dan season shell.** Sweep hanya menghapus leaf, jadi show yang sudah mati total meninggalkan husk (beberapa show dan beberapa lusin season di library yang diukur). Ini terpisah dan perlu penanganan urutan yang hati-hati: hapus leaf, cek ulang parent, dan hapus hanya saat jumlah child-nya nol.
- Perubahan apa pun pada perilaku repair, repair queue, atau kapan zurg menandai sesuatu sebagai unrepairable.
- `autoEmptyTrash` milik Plex sendiri, yang sudah ditangani oleh peringatan di `4737b677`.
- Backlog yang sudah ada di library yang diukur, sengaja dibiarkan untuk keputusan manual.
