# Sumber akuisisi {#acquisition-sources}

Watchlist Plex kamu, [daftar wanted DMM](#dmm-wanted-list), [Seerr](https://github.com/seerr-team/seerr)
[Radarr](https://radarr.video) dan [Sonarr](https://sonarr.tv) memakai satu mesin akuisisi. Mesin ini melacak progres,
percobaan ulang, dan konfirmasi. Hasil Newznab menjadi NZB untuk backend Usenet zurg. Hasil Torznab
menjadi info hash untuk akun debrid. Lihat [Newznab dan Torznab](#newznab-and-torznab).

Mesin hanya mengonfirmasi grab setelah memeriksanya. NZB harus sampai ke news server. Pada akun `torbox_nzb`,
TorBox yang harus mengambilnya. Torrent harus muncul di library beserta file-filenya. Lihat
[Memverifikasi grab](#verifying-a-grab).

Release yang di-grab zurg menyimpan id dari judul yang di-grab, semuanya, yang dipakai Plex untuk mencocokkan judul:
IMDb, TMDB, dan untuk show, TVDB. Release itu tidak pernah dikenali ulang dari namanya. Id tersebut menggantikan id
yang diberikan DMM atau nama release, kecuali id yang kamu atur sendiri secara manual. Release yang sudah ada di library
saat zurg memilihnya mungkin ditambahkan untuk judul lain, jadi id tersebut hanya dipakai kalau release itu belum punya id
atau id-nya sama. Jika [`rex_url`](../reference/config.md#rex) diatur, film yang di-grab dikirim ke rex sebagai film itu,
dengan id tersebut, meskipun DMM tidak bisa menempatkannya. Episode dari show tetap diberi nomor sesuai penempatan DMM
dan membawa id show. Saat start, zurg melakukan hal yang sama untuk setiap release yang di-grab oleh job tersimpan
sebelumnya, sehingga release yang kehilangan id sebelum perubahan ini ikut diperbaiki.

## Konfigurasi {#configuration}

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

Jalankan ini di instance zurg dengan provider `nzb` atau akun `torbox_nzb` (TorBox Pro), akun debrid yang menerima torrent, atau keduanya. NZB dari indexer Newznab masuk ke direktori `nzbs/`. Akun `torbox_nzb` tidak punya news server untuk dicek; unduhan di sana dicek dari apakah TorBox sudah mengambilnya. Torrent dari indexer Torznab dikirim ke akun debrid. Torrent hanya ditambahkan kalau akun itu sudah punya cache-nya. Tanpa salah satu dari kedua jenis akun, sumbernya tidak akan jalan. Halaman acquisition menjelaskan alasannya. Plex perlu `plex_token` yang sudah ada. Seerr perlu base URL dan API key-nya sendiri, terpisah dari pengaturan Plex di zurg. Subpath URL dan URL yang berakhir dengan `/api/v1` didukung. Radarr perlu base URL-nya (URL base seperti `/radarr` dan `/api/v3` di akhir boleh saja), API key-nya dari **Settings > General**, dan `library_path` kalau zurg ter-mount di path yang berbeda: lihat [Radarr behavior](#radarr-behavior). Sonarr memakai tiga pengaturan yang sama: lihat [Sonarr behavior](#sonarr-behavior).

Keduanya dibaca saat zurg start, sama seperti bagian block lainnya. `indexer_concurrency` mencakup pencarian dan unduhan NZB sekaligus, karena indexer membatasi key-nya, bukan endpoint-nya. API key indexer sering dipakai bersama, dan tiga panggilan per key adalah angka yang terbukti aman untuk key yang juga melayani aplikasi lain.

Jaga nama dan URL Seerr tetap sama: keduanya mengidentifikasi antrean yang tersimpan. Memutar (rotate) key Seerr tidak menghapus antreannya. Restart setelah menambah sumber atau mengubah URL atau kredensialnya. Pengaturan `watchlist:` dan `plex_watchlist_enabled` yang sudah ada tetap jalan lewat adapter `plex-watchlist` otomatis. Source `plex_watchlist` yang eksplisit, bahkan kalau dinonaktifkan, menggantikan saklar enable lama. Hanya satu source Plex yang bisa memakai akun Plex yang dikonfigurasi. Pengaturan pencarian bersama kembali ke `watchlist:` dan default-nya; indexer yang tidak disebutkan kembali ke indexer watchlist/Stremio.

## Mengecualikan rilis berdasarkan nama {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` berisi daftar kata yang tidak boleh ada di nama release mana pun yang diambil.
Gunakan ini untuk menghindari Dolby Vision atau HDR10+ pada player yang tidak bisa menampilkannya
sambil tetap mengambil 4K. Ini berlaku untuk semua sumber, yaitu
watchlist Plex, Seerr, Radarr, dan Sonarr. Ini berlaku untuk hasil Usenet maupun torrent. Release
yang dikecualikan tidak akan pernah diunduh, disimpan, ditambahkan ke akun debrid, atau
dikirim ke Radarr atau Sonarr. Kosongkan saja jika Anda tidak ingin mengecualikan apa pun. zurg membacanya
saat startup, sama seperti pengaturan lain di `config.yml`.

## Mengutamakan rilis berdasarkan nama {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

`prefer_words` berisi daftar kata, seperti nama release group, yang membuat sebuah release naik ke posisi teratas di antara release dengan resolusi yang sama. Pencocokannya sama seperti `exclude_words`: harus kata utuh, tidak peduli huruf besar atau kecil. Daftar ini berurutan: release dengan kata pertama didahulukan dibanding release dengan kata kedua, dan seterusnya. Ini hanya preferensi, bukan filter. Kalau tidak ada release yang memuat salah satu kata tersebut, zurg akan mengambil apa yang biasanya diambil tanpa kata-kata itu.

Release yang diprioritaskan tidak pernah mendahului resolusi. Dengan `quality: best`, release 2160p dari grup mana pun tetap didahulukan dibanding release 1080p yang diprioritaskan. Dengan `quality: 1080p`, release 2160p yang diprioritaskan tidak akan mendahului release 1080p. Naik ke resolusi yang lebih tinggi tetap terjadi kalau grup yang diprioritaskan tidak punya release di resolusi tersebut.

Ini berlaku untuk semua source, dan untuk hasil Usenet maupun torrent. Dengan source `radarr` atau `sonarr`, profil tetap harus menerima release yang diprioritaskan. Kalau Radarr atau Sonarr memakai zurg sebagai download client, mereka yang memilih release sendiri, dan `prefer_words` tidak berlaku di sana. Kalau tidak ingin memprioritaskan apa pun, cukup hapus opsi ini.

Release film juga tidak pernah diambil kalau tahun di namanya selisih lebih dari satu dari tahun film tersebut, apa pun source-nya. Beberapa indexer kadang salah menaruh posting film di bawah IMDb id film lain. Misalnya, DrunkenSlug menaruh The Aswang Chronicles (2012) di bawah sekuelnya tahun 2014. Nama tanpa tahun tidak ditolak karena alasan ini. Untuk wanted list DMM, yang mengirim semua judul yang dikenal untuk sebuah film (judul asli, judul alternatif, dan terjemahan), release yang namanya tidak memuat salah satu judul itu secara utuh juga ditolak. Contohnya, DrunkenSlug menaruh Przesluchanie (1982) di bawah An Affair (1982), dan `Rocky.2015` bukan *Rocky Horror Show Live*. Nama boleh berhenti di tempat subjudul dimulai, yaitu setelah titik dua atau tanda hubung dengan spasi, jadi `Diana.2021` cocok dengan *Diana: The Musical*. Huruf beraksen dan umlaut cocok dalam kedua bentuk, jadi `Les.Miserables` dan `Verwuenscht.nochmal` juga dihitung.

Cara nama dicocokkan:

- **Hanya kata utuh.** Nama dibaca sebagai kata yang terdiri dari huruf dan angka. Titik, spasi, tanda hubung, garis bawah, kurung siku, dan kurung biasa semuanya memisahkan kata. Huruf besar atau kecil tidak berpengaruh. `DV` mengecualikan `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` dan `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD`. Kata ini tidak mengecualikan `DVDRip`, `DVD9`, `Come and See DvD 1`, atau judul seperti *Adventures*, karena tidak ada satu pun yang memuat kata DV.
- **Frasa dicocokkan sesuai urutan.** `Dolby Vision` atau `DV HDR` cocok jika kata-kata itu berdampingan dengan urutan yang sama, apa pun pemisahnya.
- **Tanda `+` di akhir ikut menjadi bagian kata.** `HDR10+` adalah kata tersendiri. Jika `HDR10` dikecualikan, release HDR10+ tidak ikut terpengaruh. Jika `HDR10+` dikecualikan, HDR10 biasa tidak ikut terpengaruh. Tulis keduanya jika ingin mengecualikan keduanya. Tanda `+` di antara dua kata berfungsi sebagai pemisah, seperti pada `DD+7.1` atau `DV+HDR10`.
- **Dua keluarga penulisan dihitung sebagai satu kata.** Salah satu penulisan dalam daftar akan mengecualikan semua penulisan dari keluarga yang sama.

  | Tulis salah satu dari | Mengecualikan nama yang memuat salah satu dari |
  |---|---|
  | `DV`, `DoVi`, `Dolby Vision`, `DolbyVision` | `DV`, `DoVi`, `Dolby.Vision`, `Dolby-Vision`, `Dolby Vision`, `DolbyVision` |
  | `HDR10+`, `HDR10Plus` | `HDR10+`, `HDR10Plus` |

  Selain itu, tidak ada penulisan lain yang disamakan. `HDR` mengecualikan nama yang memuat kata HDR, tapi tidak `HDR10`, `HDR10+`, atau `HDRip`. `WEB-DL` cocok dengan `WEB-DL`, `WEB.DL`, dan `WEB DL`, tetapi tidak dengan `WEBDL`.
- **Hanya nama release yang dibaca.** Nama inilah judul yang dijawab indexer sebelum apa pun diunduh. Isi file di dalamnya tidak dibaca. Release Dolby Vision yang namanya tidak menyebutkannya tidak akan dikecualikan.

Mengecualikan sebuah kata tidak pernah memengaruhi resolusi. Dengan `DV` yang dikecualikan, release 2160p dengan HDR biasa atau HDR10 tetap diambil, dan `quality: 4k` tetap mendahulukan 2160p. Release yang dikecualikan dihitung sebagai tidak ditemukan. Pencarian film atau episode akan terus membuka halaman tiap indexer sampai mendapat sepuluh release yang boleh diambil, indexer kehabisan hasil, atau sepuluh halaman sudah dibaca. Pencarian season hanya membaca satu halaman, lalu mencari secara terpisah episode mana pun yang tidak punya release di halaman tersebut. Judul yang semua release-nya dikecualikan akan gagal dengan "no eligible releases", sama seperti judul yang semua release-nya melebihi `max_size_gb`, lalu dicoba lagi nanti. Permintaan 4K dari Seerr hanya mengambil release 2160p, jadi permintaan itu akan menunggu kalau semua release 2160p dikecualikan.

### Pengecualian dan profil Radarr atau Sonarr {#exclusions-and-radarr-or-sonarr-profiles}

Dengan sumber `radarr` atau `sonarr`, pengecualian dijalankan lebih dulu. Release yang dikecualikan tidak pernah diberikan ke parser Radarr atau Sonarr. Skor custom format apa pun tidak bisa memunculkannya lagi, dan itu tidak dihitung sebagai penolakan oleh profile. Setiap release lain dinilai oleh profile seperti dijelaskan di [Radarr behavior](#radarr-behavior) dan [Sonarr behavior](#sonarr-behavior). Sebuah release harus lolos keduanya. Custom format yang memberi skor Dolby Vision di bawah minimum profile melakukan hal yang sama di dalam *arr, dan membiarkannya tidak berbahaya.

Upgrade mengikuti aturan yang sama. Jika satu-satunya release yang bisa menaikkan file ke cutoff profile-nya dikecualikan, file tetap di bawah cutoff dan pass upgrade zurg terus mencari tanpa mengambil apa pun. Ini terjadi ketika custom format memberi Dolby Vision skor tinggi dan skor cutoff membutuhkannya. Turunkan skor cutoff atau hapus skor itu dari custom format.

Saat Radarr atau Sonarr memakai zurg sebagai download client lewat blok `sabnzbd:` atau `qbittorrent:`, mereka mencari di indexer mereka sendiri dan memilih release sendiri. `exclude_words` tidak berlaku di sana. Kecualikan kata yang sama di *arr dengan custom format yang diberi skor di bawah minimum profile, atau **Must Not Contain** di release profile.

## Memilih berdasarkan bahasa audio dan subtitle {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

`audio_languages` hanya mengambil rilis yang punya track audio dalam salah satu bahasa yang tercantum, dan `subtitle_languages` hanya mengambil rilis yang punya track subtitle dalam salah satunya. Biarkan salah satunya kosong jika tidak mau meminta apa pun. Keduanya berlaku untuk setiap sumber.

Setiap daftar juga berfungsi sebagai urutan: torrent dengan bahasa yang lebih awal didahulukan dibanding torrent yang hanya punya bahasa yang lebih belakang. `[de, original]` mengambil dub bahasa Jerman jika ada, dan bahasa asli jika tidak ada.

zurg membaca bahasa dari stream rilis, bukan dari namanya. Kebanyakan rilis tidak menyebutkan bahasanya: hampir tidak ada rilis Parasite yang bertuliskan KOREAN. Tulis kode ISO 639, dua atau tiga huruf: `en`, `eng`, `de`, `deu`, dan `ger` semuanya bisa dipakai. Nama seperti `german` akan ditolak saat startup.

Beberapa bahasa punya dub atau subtitle yang berbeda, dan kode tertentu bisa menunjuk salah satunya:

| Tulis | Untuk |
|---|---|
| `es-419`, `es-ES` | Spanyol Amerika Latin (Latino) atau Spanyol Kastilia |
| `pt-BR`, `pt-PT` | Portugis Brasil atau Portugis Eropa |
| `fr-CA`, `fr-FR` | Prancis Kanada (VFQ) atau Prancis dari Prancis (VFF, VFI) |
| `nl-BE` | Flemish |
| `yue`, `cmn` | Kanton atau Mandarin |
| `zh-Hant`, `zh-Hans` | Subtitle Mandarin Tradisional atau Sederhana (`zh-TW` dan `zh-HK` dibaca sebagai Tradisional, `zh-CN` sebagai Sederhana; untuk audio Kanton tulis `yue`) |
| `nb`, `nn` | Norwegia Bokmål atau Nynorsk |

Kode biasa mengambil semua variannya: `es` mengambil Latino dan Kastilia, `zh` mengambil Kanton dan Mandarin, `no` mengambil Bokmål dan Nynorsk. Bagian setelah bahasa yang tidak bisa dibaca zurg, misalnya `es-latam`, akan ditolak saat startup. zurg membaca varian sebuah track dari judulnya, karena stream tidak pernah menyimpannya dalam bentuk yang bisa dibaca zurg: "Latino", "Spanish (Latin American)", "Castellano", "French (Canada)", "VFQ", "Portuguese (Brazilian)", "Chinese (Cantonese)", "繁体中字". Track yang judulnya tidak menyebutkan apa pun tidak akan ditolak karena itu. Nama rilis menjadi penentu jika menyebutkannya, misalnya `Dual-Lat`, `[Castellano]`, `MULTi.VFQ`, `VF2`, `PT-BR`, atau `[ES-LA]`. Nama tidak pernah menolak apa pun, dan judul track lebih diutamakan daripada nama. Untuk `[es-419, es]`, zurg mengambil, secara berurutan: track yang judulnya Latino, track tanpa judul di rilis yang namanya Latino, track tanpa judul, track tanpa judul di rilis yang namanya Castellano, dan track yang judulnya Castellano. Untuk rumah tangga Amerika Latin:

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

`audio_or_subtitles: true` mengambil rilis yang punya audio atau subtitle, tidak harus keduanya. Rilis dengan audio didahulukan dibanding rilis yang hanya punya subtitle.

`original` berarti bahasa yang digunakan saat judul dibuat, sebagaimana tercatat di TMDB: bahasa Korea untuk Parasite, bahasa Prancis untuk Anatomy of a Fall. zurg meminta informasi itu ke DMM, jadi perlu `dmm_api_key`. Tanpa kunci itu, `original` tidak meminta apa pun.

### Cara sebuah rilis dinilai {#how-a-release-is-judged}

- **Sebelum torrent ditambahkan.** DMM menyimpan data ffprobe dari setiap rilis yang sudah dianalisis oleh zurg. Dengan `dmm_api_key` diatur, zurg membaca data itu untuk setiap hasil torrent dalam satu panggilan. Torrent yang streamnya tidak punya bahasa tersebut tidak akan pernah ditambahkan. Torrent yang punya bahasa itu akan didahulukan dibanding torrent yang tidak diketahui isinya. Dalam pengukuran lima film pada 2026-10-25, DMM punya data ini untuk sekitar sepertiga torrent yang sudah di-cache oleh Real-Debrid.
- **Setelah diambil.** Setiap grab, baik torrent maupun Usenet, diperiksa sekali begitu sudah ada di library: memakai data DMM jika ada, kalau tidak pakai ffprobe. Grab yang streamnya tidak punya bahasa tersebut disingkirkan seperti dead post. Grab itu dihapus dari akun debrid atau dikeluarkan dari watch directory, lalu kandidat berikutnya langsung dicoba. Dasbor menjelaskan alasannya, misalnya "it has no English audio, only French".
- **Upgrade tetap mempertahankan bahasanya.** Saat daftar keinginan DMM meng-upgrade film ke resolusi yang lebih baik, rilis baru harus punya bahasa yang setidaknya sama awal di daftar bahasamu dengan salinan yang digantikannya. Salinan Latino 1080p tidak ditukar dengan salinan Castilian 2160p.
- **Yang tidak diketahui tetap diambil.** Rilis tidak pernah ditolak karena hal yang tidak bisa dibaca. Ini mencakup track tanpa tag, track yang bertag `und` atau `mul`, rilis yang hanya bisa dijangkau lewat arsipnya, atau tidak ada hasil probe dalam satu menit. zurg mencatat di log bahwa ia mengambilnya apa adanya.

Track komentar dan track audio deskripsi tidak dihitung sebagai audio film, dan subtitle komentar tidak dihitung sebagai subtitle film. Ini termasuk komentar yang hanya disebut di judulnya, seperti "Commentary by Bong Joon Ho" pada Parasite. Track subtitle yang berjudul forced (forzados, forcés), tanda atau lagu tidak dihitung sebagai subtitle. Flag forced saja tidak membuat track dikeluarkan: remux film asing biasanya menandai subtitle Inggris penuhnya sebagai forced supaya pemutar tetap menampilkannya.

Hanya file video utama dari rilis yang dinilai, yaitu yang durasinya minimal seperlima dari yang terpanjang. Extras sering punya lebih sedikit dub dibanding film. Dalam season pack, setiap episode harus punya bahasa tersebut.

Rilis yang disingkirkan karena bahasa tetap disingkirkan selama 30 hari, sama seperti dead post, bahkan jika kamu mengubah bahasanya.

## Daftar keinginan DMM {#dmm-wanted-list}

Sponsor DMM menambahkan film dan serial ke daftar keinginan dengan tombol **Want** di halaman mereka di debridmediamanager.com, dan daftarnya ada di `/wanted`. zurg membaca daftar itu setiap kali `dmm_api_key` diisi, jadi kamu tidak perlu menulis apa-apa lagi. Tidak ada yang di-mount dan tidak ada Sonarr atau Radarr yang terlibat. Sumbernya bernama `dmm-wanted` dan dicek setiap 60 detik.

- **Apa yang diambil.** Film diambil sekali, lalu setiap peningkatan kualitasnya (lihat di bawah), atau satu salinan di tiap resolusi saat `quality` berupa daftar (lihat di bawah). Untuk serial, episode yang sudah tayang di musim yang diinginkan diambil, atau di semua musim kalau seluruh serial diinginkan, beserta episode barunya saat tayang.
  DMM mengirim id IMDb, TMDB, dan TVDB tiap judul, tahunnya, dan untuk serial, episode yang sudah tayang sejauh ini, dengan penomoran seperti yang dipakai TMDB. Special tidak pernah didaftar. Musim yang masih tayang diambil sebagai episode satuan, karena belum ada pack yang mencakupnya.
- **Kapan dicari.** Film dicari saat baru keluar untuk di rumah: DMM mengirim tanggal paling awal rilis digital, fisik, atau TV yang diketahui TMDB, dan zurg menunggu paling lama sampai hari itu, lalu mencari setiap dua menit selama enam jam dan setiap sepuluh menit sampai dua hari sesudahnya, sama seperti untuk [episode baru](#sonarr-behavior). Tidak pernah tanggal bioskop: WEB-DL diunggah bersama rilis digital. Episode terbaru sebuah serial diberi tanggal dengan cara yang sama, mulai dari jam tayangnya jika DMM mengetahuinya. Judul tanpa tanggal tetap memakai percobaan ulang biasa, paling lama terpisah seminggu, dan tidak ada item di daftar yang pernah di-[parkir](#persistence-and-recovery). Film yang menunggu percobaan berikutnya akan dicari pada pengecekan berikutnya saat DMM melihat unggahan Usenet baru yang menyebut namanya.
- **Ke mana diarahkan.** Sama seperti sumber lain: NZB dari indexer Newznab ke backend Usenet instance ini, atau torrent dari indexer Torznab ke akun debrid yang sudah punya file itu di cache, tergantung mana yang diprioritaskan `prefer` lebih dulu. `quality`, `max_size_gb` (per episode untuk pack musim), `exclude_words`, dan [bahasa](#choosing-by-audio-and-subtitle-language) berlaku, begitu juga `max_season_size_gb` jika kamu menulisnya.
- **Indexer.** Jika tidak ada indexer yang ditulis di bawah `acquisition:`, `watchlist:`, atau `stremio:`, kunci ini juga mencari di indexer milik DMM: indexer Usenet-nya dan torrent yang diketahuinya ada di Real-Debrid atau AllDebrid (`/api/torznab/cached`). Menulis indexer apa pun akan menggantikan keduanya.
- **Konfirmasi.** Setelah pengambilan film diperiksa, zurg memberi tahu DMM, dan film itu keluar dari daftar yang dibaca zurg, kecuali jika menunggu peningkatan atau salinan lain darinya (lihat di bawah); `/wanted` menunjukkan kapan itu terjadi. Serial tetap ada di daftar dan terus diikuti sampai kamu menghapusnya di sana. Menghapus judul akan menghentikan pekerjaan untuknya.
- **Peningkatan kualitas.** Film yang nama rilisnya menyebut resolusi di bawah yang dituju `quality` (2160p untuk `best` dan `4k`, 1080p untuk `1080p`, 720p untuk `720p`) tetap ada di daftar. zurg mengambil rilis yang menyebut resolusi lebih tinggi daripada salinan yang dimilikinya saat rilis itu keluar, sampai zurg memegang yang lebih baik. Setelah salinan yang lebih baik lolos pemeriksaan, salinan lama dihapus jika zurg yang mengambilnya, mulai dari nightly 2026-10-30: torrent dari akun tempat zurg menambahkannya, atau NZB dari folder pantau. Salinan yang sudah milikmu sejak awal tetap disimpan, begitu juga salinan yang sudah punya bagian di bawah `__magic__`, misalnya karena impor Radarr. Rilis yang namanya tidak menyebut resolusi tidak pernah ditingkatkan, dan `quality: smallest` tidak meningkatkan apa pun. Sampai rilis yang lebih baik muncul, film dicari sekitar seminggu sekali, dan tidak pernah di-[parkir](#persistence-and-recovery). Fitur ini aktif secara default; `upgrades: false` di blok `acquisition:` mematikannya.
- **Satu salinan di tiap beberapa resolusi.** Dengan `quality` ditulis sebagai daftar, misalnya `[1080p, 4k]`, setiap film disimpan satu salinan untuk tiap resolusi di dalamnya. Lihat [satu salinan di tiap beberapa resolusi](#a-copy-at-each-of-several-resolutions).
- **Tanpa akun pengambilan.** Instance tanpa provider `nzb`, tanpa akun `torbox_nzb` (TorBox Pro), dan tanpa akun debrid yang menerima torrent tidak membaca daftar ini.

**Dua zurg dengan kunci yang sama akan mengambil setiap judul.** Keduanya membaca daftar yang sama, jadi jalankan daftar keinginan di salah satunya dan matikan di yang lain dengan menuliskannya sebagai disabled:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

Sponsorship yang sudah berakhir atau kunci yang direset akan menghentikan daftar ini. zurg mencatat peringatan bahwa DMM menolak `dmm_api_key` dan mencoba lagi satu jam kemudian, atau langsung saat kamu mengisi kunci baru. Yang sudah diambil tetap ada di perpustakaanmu.

### Satu salinan untuk tiap beberapa resolusi {#a-copy-at-each-of-several-resolutions}

Tulis `quality` sebagai list supaya ada satu salinan setiap film di wanted list untuk tiap resolusi, misalnya supaya TV 1080p bisa memutar salinan 1080p tanpa file 4K perlu ditranskode:

```yaml
acquisition:
  quality: [1080p, 4k]
```

Setiap salinan mengambil release terbaik dengan resolusi sama atau lebih rendah dari resolusinya sendiri, dan tidak pernah yang lebih tinggi. Salinan 1080p tidak mengambil release 2160p, dan tidak juga release yang namanya tidak menyebut resolusi, karena bisa saja resolusinya apa pun. Salinan 4K hanya mengambil release seperti itu jika tidak ada release yang menyebut resolusi bisa diambil, lalu menyimpannya selamanya, karena release yang tidak menyebut resolusi tidak pernah di-upgrade. Setiap salinan di-upgrade sendiri, sampai ke resolusinya sendiri. Jika keduanya akan mengambil release yang sama, mereka berbagi satu salinan, dan salinan itu baru dihapus setelah tidak ada lagi yang memakainya:

| Release yang keluar | Salinan 1080p | Salinan 4K | Di library kamu |
|---|---|---|---|
| 720p | 720p-nya | 720p-nya juga | 720p-nya |
| + 1080p | naik ke 1080p | naik ke 1080p | 1080p-nya |
| + 2160p | tetap | naik ke 2160p | 1080p dan 2160p |

Film yang hanya rilis dalam 2160p langsung mendapat salinan 4K-nya, dan salinan 1080p-nya ketika release 1080p atau lebih rendah muncul. Sampai saat itu film dicari sekitar seminggu sekali dan tidak pernah di-park. Film dikeluarkan dari list yang dibaca zurg hanya setelah setiap salinan memegang release yang tidak perlu diganti dengan yang lebih baik.

- **Isi list.** Dua atau lebih dari `4k` (atau `2160p`), `1080p`, dan `720p`, masing-masing sekali, dalam urutan dan huruf besar/kecil apa pun. zurg menolak start jika isinya lain dan menampilkan `acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`. List berisi satu nilai dibaca sebagai nilai itu, jadi `[1080p]` sama dengan `quality: 1080p` dan hanya punya satu salinan; tulis `4k` di sana, karena `[2160p]` ditolak.
- **Hanya di blok `acquisition:`.** `quality` di bawah `watchlist:` berupa satu nilai; list di sana membuat zurg tidak bisa start. Pengaturan quality di halaman config hanya mengedit `watchlist.quality`, dan tidak berpengaruh apa-apa selama `acquisition.quality` ditulis.
- **Hanya film di wanted list DMM.** Serial di list itu, dan semua sumber lain, tetap mendapat satu salinan, dipilih seolah `quality` hanya menyebut resolusi tertinggi di list: `[1080p, 4k]` berlaku seperti `quality: 4k` untuk mereka, dan `[720p, 1080p]` seperti `quality: 1080p`, yang tetap mengambil release 2160p jika tidak ada release 1080p.
- **Dengan `upgrades: false`** setiap salinan menyimpan release pertama yang diambilnya. Selama baru ada 720p, kedua salinan adalah 720p itu selamanya.
- **Film yang sudah diambil sebelum kamu menulis list** akan diambil ulang, satu salinan per resolusi. Salinan yang release terbaiknya sudah ada di library dipakai apa adanya. zurg tidak pernah menghapus salinan lama yang diambil sebelumnya: hapus sendiri jika salinan baru menggantikannya.
- **Kembali ke satu nilai** membiarkan salinan tetap di tempatnya.
- **`/wanted` menampilkan film sebagai sudah diambil** begitu salinan pertamanya masuk, dengan release pertama yang diambil zurg. Tidak ditampilkan resolusi mana yang masih menunggu. Film yang diambil sebelum kamu menulis list bisa tetap menampilkan "waiting for" untuk resolusi yang ditunggu saat itu.

### Streaming film dari YouTube {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM wanted list, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the wanted list takes a stream:
  a film the Plex watchlist also wants is not settled for it by one, since Plex cannot
  play it, and the watchlist keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one wanted list (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the wanted list while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## Perilaku Seerr {#seerr-behavior}

Adapter ini mengikuti [request routes](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts),
[status definitions](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)
dan [API contract](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml) milik seerr-team/seerr.

- Mengecek semua halaman request yang sudah disetujui memakai `X-Api-Key`. Jika satu halaman gagal, daftar antrean sebelumnya tetap dipakai dan pekerjaan untuk sumber itu dijeda.
- Mengecek ulang persetujuan sebelum acquisition. Request yang pending, declined, failed, completed, removed, atau sudah available tidak akan memulai grab.
- Mengonversi ID lewat Seerr. Acquisition untuk TV dibatasi hanya ke season yang diminta dan sudah disetujui, beserta episode yang sudah tayang. Season yang belum lengkap tetap pending.
- Memisahkan 4K dan non-4K. Rilis 1080p tidak bisa memenuhi request 4K.
- Mengecek ulang request yang masih terbuka setiap 30 menit setelah acquisition berhasil, untuk menemukan episode baru yang sudah tayang di season yang diminta. Episode yang belum diumumkan baru menjadi pekerjaan setelah muncul di metadata Seerr.
- Mengutamakan pack setelah semua episode yang diketahui sudah tayang. Season yang masih tayang memakai episode lepasan. Specials (season 0) tidak didukung. Request dengan season 0 yang disetujui tidak akan di-acquire sama sekali, dan akan gagal sampai dipark.
- Tidak melakukan penulisan status request atau availability apa pun. Scan media server dari Seerr yang melaporkan ketersediaan yang sebenarnya dan memberi tahu requester. Menyimpan NZB tidak membuktikan bahwa file itu sudah terindeks atau bisa diputar, makanya engine mengeceknya dulu sebelum menganggap season sudah acquired.

Atur library scan Seerr agar mencakup library yang dilayani instance ini. Jika Sonarr/Radarr sudah men-acquire request yang sama, matikan alur kerja yang tumpang tindih itu sebelum mengaktifkan adapter ini. Adapter ini tidak meniru server *arr dan tidak mengubah setup service Seerr. Polling sudah menangani pemulihan setelah restart, jadi webhook tidak diperlukan.

## Perilaku Radarr {#radarr-behavior}

Radarr menyimpan daftar dan memiliki library-nya. zurg yang melakukan pencarian dan pengunduhan. Radarr tidak pernah mencari dan tidak pernah mengambil sendiri: zurg membaca film apa saja yang diinginkan Radarr, memilih release dari indexer-nya sendiri, memeriksanya lewat news server (fetch TorBox pada akun `torbox_nzb`) atau akun debrid yang menyimpannya, lalu menaruh video di folder film tersebut di dalam `__magic__` dan meminta Radarr melakukan rescan untuk film itu saja. Tidak ada yang disalin: video itu adalah file di library zurg yang sekarang terlihat oleh Radarr di folder-nya.

### Menyiapkan Radarr {#setting-up-radarr}

1. **Root folder di dalam `__magic__`, satu level di bawahnya.** Contohnya
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` di macOS,
   `Z:\__magic__\movies` di Windows). Bukan `__magic__` itu sendiri, dan bukan
   `__magic__/__all__`, yang berisi setiap rilis di library. Film yang foldernya
   ada di tempat lain akan dilewati, dengan satu peringatan di log zurg.
   Di Windows, Radarr hanya melihat `Z:` jika berjalan di logon session yang sama
   dengan zurg, jadi bukan sebagai Windows service: lihat
   [aturan session](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Import list dengan search on add dimatikan.** Tambahkan film sesuka kamu (manual, lewat list, atau Seerr yang diarahkan ke Radarr). Biarkan **Search for Movie** tidak dicentang saat menambahkan, karena zurg yang melakukan pencarian.
3. **Tidak perlu indexer dan download client.** Jika Radarr punya itu, ia bisa mengambil dari sumber lain selain zurg, jadi matikan automatic search di indexer-nya (atau hapus indexer-nya) untuk film yang ditangani zurg.
4. **`library_path` adalah tempat Radarr melihat `__magic__`.** Jika Radarr berjalan di mesin yang sama dengan zurg dan melihat mount di lokasi yang sama dengan zurg, biarkan kosong: nilai defaultnya adalah `mount_path` zurg ditambah `/__magic__`. Jika Radarr berjalan di container yang memasang zurg di lokasi lain, atur ke path tersebut, misalnya `/data/zurg/__magic__`. Film di `/data/zurg/__magic__/movies/Heat (1995)` kemudian ditempatkan di `movies/Heat (1995)` di dalam `__magic__` milik zurg. Path Windows seperti `Z:\__magic__` juga bisa dipakai. Container Radarr hanya didukung di host Linux: Docker Desktop di macOS dan Windows menjalankan container di dalam VM, dan meneruskan mount zurg ke dalamnya belum diuji, jadi jalankan Radarr secara native di sana.

   Jika Radarr juga menerima grab dari endpoint [SABnzbd](sonarr-radarr.md) atau [qBittorrent](sonarr-radarr-torrents.md) milik zurg, ia harus melihat folder download-nya di `library_path/__all__`, lewat volume yang sama dengan root folder-nya, atau setiap impor dari sana akan menjadi salinan utuh dari file. zurg menanyakan ke Radarr di mana ia melihat keduanya dan memberi tahu di halaman acquisition, di log, dan di `zurg doctor` jika keduanya tidak bisa berbagi mount; lihat [Satu volume untuk folder download dan root folder](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### Yang diminta zurg dari Radarr {#what-zurg-asks-radarr-for}

Setiap poll membaca daftar film Radarr dan memproses setiap film yang **monitored**, **tersedia** sesuai minimum availability film tersebut, dan yang tidak punya file atau punya file di bawah cutoff profil kualitasnya, selama profil itu mengizinkan upgrade. Di bawah cutoff berarti di bawah cutoff quality atau di bawah cutoff custom-format score, sesuai cara Radarr menghitungnya. Film yang belum rilis, misalnya film yang tanggal rilisnya beberapa bulan lagi, menunggu sampai Radarr menyatakan film itu tersedia.

Setiap kandidat release yang akan diperiksa zurg dikirim ke parser Radarr (`/api/v3/parse`) dan dinilai dengan profil kualitas film, jadi yang diterima zurg adalah yang juga akan diterima Radarr:

- **Harus film yang sama.** Radarr harus mencocokkan judulnya ke film yang sama. Pencarian ID dari indexer kadang mengembalikan film lain (pencarian *Psycho* pernah mengembalikan *Ed Gein: The Real Psycho*), dan judul yang tidak cocok dengan film mana pun akan ditolak. Tahun dalam judul yang selisihnya lebih dari satu dari tahun film juga ditolak.
- **Daftar izin dan skor minimum profil diterapkan lebih dulu.** Kualitas hasil parse harus diizinkan oleh profil, skor custom format harus mencapai minimum profil, dan ukurannya harus sesuai batas kualitas di **Settings > Quality** untuk durasi film.
- **Release harus dalam bahasa profil.** Dengan **Original** (default), Radarr harus membaca judulnya sebagai bahasa asli film, jadi release yang hanya berbahasa Prancis untuk film berbahasa Inggris akan ditolak. Judul yang tidak menyebut bahasa dianggap bahasa asli. Jika bahasa tertentu disebut, release harus dalam bahasa itu, dan **Any** menerima semua bahasa. Aturan ini berlaku sama untuk file pertama maupun upgrade.
- **Upgrade bergerak menuju cutoff.** Film tanpa file menerima release apa pun yang lolos pemeriksaan di atas. Setelah punya file di bawah cutoff, hanya release yang lebih baik yang diambil: kualitas yang lebih tinggi menurut urutan profil selama file masih di bawah cutoff quality, atau skor custom format yang lebih tinggi (minimal sebesar upgrade step profil) selama file masih di bawah cutoff score. Release dengan kualitas lebih rendah tidak pernah diambil. Release PROPER dan REPACK dengan kualitas yang sama tidak dihitung sebagai upgrade.

Profil diterapkan pada release yang akan diambil zurg sebagai daftar izin: film yang tepat, kualitas yang diizinkan, skor minimum, bahasa, dan batas ukuran. Secara default, urutan preferensi profil tidak dipakai untuk memilih di antara release yang diizinkan. zurg mengambil release yang diizinkan pertama yang paling murah untuk diperiksa, dengan mencoba release web (WEB-DL, WEBRip) dulu, lalu Blu-ray, lalu yang lain, karena release web paling sering diposting sebagai satu file video. Jika profil lebih menyukai kualitas yang lebih baik daripada yang datang dan mengizinkan upgrade, Radarr akan melihat file film berada di bawah cutoff, dan upgrade pass zurg mencari release yang lebih baik setelah film punya file. File pertama datang dengan cepat, dan urutan profil dilayani oleh upgrade. Atur `best_first: true` agar pengambilan pertama mengikuti urutan profil. Lihat [Mengambil yang terbaik dari profil dulu](#taking-the-profiles-best-first).

Ketika pencarian dengan id IMDb atau TMDB film tidak memberi hasil sama sekali, zurg mencari lagi berdasarkan judul dan tahun, seperti yang dilakukan Radarr. Banyak posting, terutama dokumenter kecil, diindeks tanpa id sama sekali. Parser Radarr yang memutuskan apakah setiap hasil itu film yang dimaksud, jadi film lain dengan nama yang sama ditolak seperti kecocokan salah lainnya.

Radarr hanya ditanya tentang sebuah release ketika zurg akan memeriksanya, satu release dalam satu waktu, jadi film dengan release satu file memakan satu sampai tiga pertanyaan. Tidak ada pertanyaan lagi setelah direct post tersimpan. Judul yang menyebut resolusi yang tidak punya kualitas yang diizinkan di profil, misalnya release 2160p untuk profil HD-1080p, langsung ditolak tanpa bertanya ke Radarr. Judul yang tidak menyebut resolusi, atau menyebut lebih dari satu, selalu dikirim ke Radarr, begitu juga setiap judul jika profil mengizinkan kualitas yang namanya tidak menyebut resolusi (SDTV, DVD, Unknown, Raw-HD, BR-DISK). zurg membuat paling banyak delapan panggilan ke satu Radarr dalam satu waktu.

Jika Radarr tidak bisa dihubungi, belum ada keputusan: film menunggu poll berikutnya, dan tidak ada release yang dikesampingkan hanya karena Radarr tidak menjawab.

### Menempatkan file {#placing-the-file}

Setelah sebuah rilis dicek, zurg menaruh video-nya di folder film seperti cara Radarr mengimpornya, yaitu dengan memindahkannya ke dalam `__magic__`. Tidak ada yang disalin atau diunduh.

- **Video terbesar yang akan ditaruh.** Itu adalah file `.mkv`, `.mp4`,
  `.m4v`, `.avi`, `.mov`, atau `.ts` terbesar dalam rilis, termasuk yang ada di dalam arsipnya. Rilis yang disajikan dari satu arsip berarti isi arsip itu. Set RAR dengan file lepas di sebelahnya, misalnya postingan scene yang berisi sampel dan `.nfo`, dijelajahi sebagai folder rilis, dan video di dalamnya ditaruh dari situ. Sampel, featurette, subtitle, dan file `.nfo` tetap berada di `__magic__/__all__`. File mempertahankan nama yang dimilikinya di rilis, kecuali kalau nama itu tidak menyebut apa-apa tentang film (tidak ada tahun dan tidak ada kata dari judulnya). Dalam kasus itu, file memakai nama rilis supaya Radarr bisa membaca kualitasnya.
- **Sampel tidak pernah ditaruh.** Video yang dinamai sebagai sampel (`sample-…`, `….sample.mkv`, atau berada di folder `Sample/`) dilewati, berapa pun ukurannya, kecuali nama rilisnya sendiri juga menyebut sample. Film yang hanya punya kata itu di judulnya (`Sample.Size.2019`, `Death.Proof.2007`) akan menyebutnya juga di nama rilis. Dalam kasus itu, video hanya dilewati kalau ukurannya kurang dari seperlima rilisnya. Rilis yang video satu-satunya adalah sampel, termasuk postingan yang isinya cuma sampel, akan disisihkan dan kandidat berikutnya dicoba. Dengan begitu, upgrade tidak akan mengganti file kamu dengan klip satu menit.
- **Rilis ditolak sebelum dipindahkan kalau tidak bisa dibaca.** Ini adalah pengecekan yang dilakukan impor Sonarr atau Radarr lewat mount. Rilis yang artikelnya sudah tidak disimpan lagi oleh news server, atau arsipnya tidak pernah bisa dibuka, disisihkan seperti postingan mati, lalu kandidat berikutnya dicoba. Rilis yang tidak bisa dibaca untuk sementara, misalnya karena akunnya sedang cooling down, akan dicoba lagi nanti.
- **Radarr menyimpan satu file per film, jadi upgrade akan menggantikan file lama.** Setelah video baru ada di folder, setiap video lain yang ditaruh oleh library zurg disembunyikan dari folder itu. Disembunyikan berarti di-tombstone, sama seperti penghapusan lewat mount: rilis lama tetap ada di `__all__` dan di akunnya. File asli yang kamu taruh sendiri di folder tidak disentuh. File lama baru dihapus setelah file baru berhasil ditaruh, jadi kalau penempatan gagal, film tetap punya file yang dulu dimilikinya.
- **Radarr dipindai ulang setelahnya.** zurg memberi tahu mount folder mana yang berubah, sehingga pemindaian ulang tidak membaca folder yang masih diingat mount sebagai kosong. Setelah itu zurg meminta Radarr memindai ulang film tersebut saja.

Sumber Radarr membutuhkan `__magic__` (`magic.enabled`). Tanpa itu, sumber tidak akan berjalan dan hal tersebut akan ditulis di log serta di halaman acquisition.

### Yang ditampilkan Radarr {#what-radarr-shows}

**Activity** tetap kosong: tidak ada entri antrean dan tidak ada event grab atau import, karena Radarr tidak melakukan grab apa pun. Film tersebut cukup memiliki file setelah rescan yang diminta zurg, dan kualitas serta custom format-nya adalah pembacaan Radarr terhadap file itu. Log zurg mencatat setiap film yang selesai diproses.

`only_new_items` dan `remove_after_grab` tidak berpengaruh untuk sumber Radarr. Film yang diinginkan Radarr adalah pekerjaan, sama seperti permintaan Seerr yang sudah disetujui, dan Radarr yang memutuskan kapan sebuah film berhenti diinginkan. Jaga agar `name` sumber tetap sama: nama itu mengidentifikasi antrean yang tersimpan, sedangkan URL dan key boleh diubah sesuka hati.

## Perilaku Sonarr {#sonarr-behavior}

Sonarr bekerja dengan cara yang sama seperti Radarr. Sonarr menyimpan daftar dan memiliki perpustakaan.
zurg yang melakukan pencarian dan pengunduhan. Sonarr tidak pernah mencari dan tidak pernah mengambil. zurg membaca episode yang belum ada di Sonarr dan memilih rilis dari indexer-nya sendiri. Ia memeriksa rilis itu dengan server berita (fetch TorBox pada akun `torbox_nzb`) atau akun debrid yang menyimpannya, lalu menaruh video tiap episode di folder musim series tersebut di dalam `__magic__`. Setelah itu, zurg meminta Sonarr memindai ulang series itu saja. Tidak ada yang disalin.

### Menyiapkan Sonarr {#setting-up-sonarr}

1. **Root folder di dalam `__magic__`, satu level di bawah.** Misalnya
   `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` di macOS,
   `Z:\__magic__\tv` di Windows). Series yang folder-nya ada di tempat lain
   akan dilewati dengan satu warning di log zurg.
   Di Windows, Sonarr harus jalan di logon session zurg, sama seperti Radarr.
2. **Search on add dimatikan.** Tambahkan series sesuka kamu. Biarkan
   **Start search for missing episodes** tetap mati, karena zurg yang
   melakukan pencarian.
3. **Tidak perlu indexer dan download client.** Kalau Sonarr punya keduanya,
   Sonarr bisa ikut mengambil file bersama zurg, jadi matikan automatic search
   di indexer-nya untuk series yang diurus zurg.
4. **`library_path` adalah tempat Sonarr melihat `__magic__`.** Cara kerjanya
   persis sama seperti untuk Radarr, termasuk pengecekan bahwa Sonarr bisa
   mengakses download folder dan root folder milik zurg lewat satu volume.
   Kosongkan saja kalau Sonarr melihat mount di lokasi yang sama dengan tempat
   zurg memasangnya.

### Yang diminta zurg dari Sonarr {#what-zurg-asks-sonarr-for}

Setiap poll membaca daftar *missing episodes* dari Sonarr. Itu adalah episode yang dimonitor dari series yang juga dimonitor, sudah tayang, dan belum punya file. zurg mengelompokkannya per season dan mengerjakan setiap season sebagai satu pekerjaan.

- **Season yang sudah selesai tayang bisa diambil sebagai pack.** Saat setiap episode dalam satu season hilang dan tidak ada yang masih akan tayang, zurg mencoba season pack dulu. Kalau tidak ada, episode yang hilang dari season itu diambil satu per satu dari hasil pencarian season tersebut. Season yang sebagian filenya sudah ada tidak pernah mengambil pack. Nanti salinan kedua dari episode-episode itu masuk ke folder.
- **Episode baru adalah pekerjaan baru.** Saat episode minggu depan tayang, season itu muncul lagi di daftar dengan episode tersebut. zurg tidak mencari ulang episode yang sudah dimilikinya.
- **Episode baru dicari lagi dalam hitungan menit.** Rilisnya biasanya diunggah dalam satu jam setelah episode tayang, jadi pencarian tepat saat tayang sering tidak menemukan apa-apa. Selama enam jam setelah episode tayang, zurg mencoba lagi setiap dua menit, lalu setiap sepuluh menit sampai dua hari setelah tayang. Setelah itu zurg mundur seperti untuk hal lain (lihat [persistence and recovery](#persistence-and-recovery)). Di akun debrid, rilisnya juga harus sudah ter-cache di sana, karena zurg hanya menambahkan apa yang dimiliki akun tersebut.
- **Episode yang dihapus akan dicari lagi.** Saat Sonarr mendaftarkan episode yang sudah pernah diambil zurg, zurg memeriksa folder season. Kalau tidak ada lagi video untuk episode itu, episode tersebut dicari ulang. Kalau videonya masih ada, berarti Sonarr belum melakukan rescan dan tidak ada yang dicari.
- **Upgrade dihitung per file.** File episode dianggap upgrade jika berada di bawah cutoff quality profile-nya, selama profile itu mengizinkan upgrade. Di bawah cutoff berarti di bawah cutoff quality atau di bawah skor custom format cutoff. Daftar Cutoff Unmet milik Sonarr hanya menghitung quality. Di Sonarr 4.0.20, file dengan quality cutoff yang skornya 0 dari cutoff score 40 tidak masuk daftar itu. zurg menghitung keduanya, sama seperti aturan upgrade bawaan Sonarr. Satu file yang berisi dua episode dihitung sebagai satu upgrade untuk keduanya.
- **Episode daily show dicari berdasarkan tanggal tayangnya.** Rilisnya diberi nama menurut tanggal (`The.Daily.Show.2026.11.03.Min.Jin.Lee...`), dan indexer tidak menemukannya dengan nomor episode. Karena itu, setiap episode yang hilang juga dicari sebagai pencarian teks berisi judul series dan tanggalnya, yaitu `The Daily Show 2026.11.03`. Parser Sonarr mengubah tanggal itu kembali menjadi episode (S31E124), sama seperti untuk judul yang dinomori per season.
- **Episode anime dicari berdasarkan nomor yang dipakai show itu.** Rilis fansub dinomori dari episode pertama show (`[SubsPlease] Jujutsu Kaisen - 30` adalah episode keenam season kedua), jadi setiap episode yang hilang juga dicari sebagai pencarian teks berisi judul series dan nomor tersebut, yaitu `JUJUTSU KAISEN 30`. Batch yang mencakup nomor-nomor satu season (`(25-47)`) dihitung sebagai season pack. Parser Sonarr memetakan nomor itu ke episodenya, dengan nama scene untuk season tersebut (`Jujutsu Kaisen 2nd Season`, `Jujutsu Kaisen S2`), jadi judul yang dinomori dengan salah satu cara tetap dinilai sebagai episode yang benar. Rilis yang tidak dicocokkan Sonarr ke series mana pun, misalnya karena memakai nama scene yang tidak dikenalnya, ditolak seperti yang lain.
- **Specials adalah season 0.** Specials yang dimonitor di Sonarr didaftarkan seperti season biasa, dan dicari sebagai season `00` (indexer yang diminta season `0` malah menjawab season lain). Hanya rilis yang menyebut `S00Exx` yang bisa cocok. Special yang hanya disebut dengan judulnya tidak menghasilkan apa-apa, di Sonarr juga begitu. Specials ditempatkan di folder sesuai nama di **Specials Folder Format**.

Setiap kandidat rilis diperiksa oleh parser Sonarr sendiri (`/api/v3/parse`) dan dinilai menurut quality profile series tersebut. Yang diterima zurg adalah yang juga akan diterima Sonarr.

- **Harus series dan season yang sama.** Sonarr harus mencocokkan judul ke series yang sama. Judul yang tidak cocok dengan series mana pun akan ditolak, kecuali series itu tidak memakai penomoran scene dan pencarian series bawaan Sonarr menemukan series ini sebagai hasil pertama berdasarkan nama dalam judul (misalnya judul berbahasa asing).
- **Pack harus berisi seluruh season.** Pack parsial ditolak. Pack yang ditulis sebagai rentang, misalnya `Season 1 E01-E07`, diterima kalau rentangnya mencakup seluruh season. Pack yang berisi beberapa season dihitung untuk setiap season yang disebutnya (lihat [Packs of several seasons](#packs-of-several-seasons)). Sonarr membaca `S01-S05` hanya sebagai season 1 dan tidak pernah menyebut di mana rentang berakhir, jadi zurg membaca rentang itu dari judul. Sonarr tetap harus mencocokkannya ke series dan menganggapnya sebagai pack penuh multi-season. Ukurannya dinilai berdasarkan durasi setiap season yang disebut.
- **Episode harus hanya episode itu saja.** Rilis yang berisi dua episode ditolak untuk satu episode.
- **Profile berlaku seperti di Radarr.** Quality harus diizinkan. Skor custom format harus mencapai minimum profile. Ukuran harus sesuai batas quality di **Settings > Quality** untuk durasi episode yang ada di rilis itu. Upgrade harus mengalahkan file saat ini menurut aturan Sonarr. Profile Sonarr tidak punya pengaturan bahasa, jadi bahasa hanya dihitung lewat skor custom format, sama seperti di Sonarr.

Urutan rilis yang diizinkan berbeda dengan Radarr. Season pack dicoba sebelum episode lepasan karena satu grab sudah mencakup banyak episode. Di antara rilis yang diizinkan Sonarr, zurg mengambil yang paling tinggi peringkatnya menurut pengaturan `quality`. Dengan `best`, yang dipilih adalah resolusi tertinggi lalu ukuran terbesar, dan pack dinilai dari isinya per episode. Jadi season yang sudah selesai tayang dengan pack 1080p akan diisi dari pack itu, meski hasil pencarian yang sama memuat semua episode dalam 2160p. Setelah itu proses upgrade mengganti episode per episode. Pack yang berisi lebih dari `max_size_gb` per episode, atau lebih dari `max_season_size_gb` yang kamu tulis untuk satu season, tidak pernah dijadikan kandidat. `best_first: true` mengubah kedua aturan ini. Lihat [Taking the profile's best first](#taking-the-profiles-best-first).

Judul yang menyebut resolusi tanpa quality yang diizinkan di profile akan ditolak tanpa bertanya ke Sonarr. zurg membuat paling banyak delapan panggilan ke satu Sonarr sekaligus. Jika Sonarr tidak bisa dihubungi, tidak ada keputusan yang dibuat. Season itu menunggu poll berikutnya dan tidak ada rilis yang dikesampingkan.

### Menempatkan file-file {#placing-the-files}

Setelah rilis diperiksa, video tiap episode masuk ke folder season. Itu folder tempat file season yang sudah ada berada. Untuk season yang belum punya file, folder yang dipakai adalah folder yang ditentukan **Season Folder Format** di Sonarr, misalnya `Season 1`. Seri yang diatur tidak memakai folder season akan menyimpan filenya di folder seri.

- **Setiap episode punya video sendiri.** Video dicari lewat nomor episode dalam namanya, termasuk di dalam arsip rilis. Sebuah pack menempatkan setiap episode yang diambil darinya. Sampel dan file `.nfo` tetap berada di `__magic__/__all__`, dan sampel tidak pernah ditempatkan sebagai episode.
- **Pack yang kurang satu episode ditolak sebelum apa pun dipindahkan.** Pack itu disisihkan seperti posting mati, lalu pack berikutnya atau episode lepasan dicoba.
- **Episode lepasan yang namanya tidak menyebut nomornya mendapat video terbesar dari rilis.** Posting yang diobfuskasi sering seperti ini.
- **Video anime atau acara harian ditempatkan di bawah seri dan episodenya.** Rescan membaca file hanya dari namanya dan tidak tahu penomoran scene. `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` di folder seri diimpor sebagai S01E08, padahal parser Sonarr membaca judul yang sama sebagai S02E08. Jadi video ditempatkan sebagai `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv`, yang akan terimpor dengan benar. Nama aslinya tetap dipertahankan setelah episode supaya Sonarr masih bisa membaca kualitas dan grup-nya. Video dari seri standar dan special tetap memakai namanya sendiri, karena nama itu sudah menunjukkan episodenya.
- **Upgrade hanya menggantikan episodenya sendiri.** Video lama dari episode itu disembunyikan dari folder season setelah video baru masuk. Episode lain di folder itu tidak diubah. Disembunyikan berarti di-tombstone, seperti yang dilakukan untuk Radarr.
- **Sonarr di-rescan setelahnya.** zurg memberi tahu mount folder mana yang berubah dan meminta Sonarr melakukan rescan seri.
- **Satu episode yang hilang tidak menahan yang lain.** Jika sebuah episode belum punya rilis yang bisa diambil zurg, episode yang berhasil ditemukan tetap diperiksa dan ditempatkan. Sonarr diminta rescan untuk episode-episode itu segera. Episode yang hilang dicari lagi sesuai jadwal retry biasa.

Sumber Sonarr membutuhkan `__magic__` (`magic.enabled`). Tanpa itu, sumber tidak akan berjalan, dan hal itu ditulis di log serta di halaman acquisition.

**Activity** di Sonarr tetap kosong, seperti di Radarr. Episodenya akan punya file setelah rescan yang diminta zurg. `only_new_items` dan `remove_after_grab` tidak berpengaruh untuk sumber Sonarr.

## Paket beberapa musim {#packs-of-several-seasons}

Sebuah season bisa diambil dari pack yang berisi beberapa season, misalnya `Game.of.Thrones.S01-08.BDRip.1080p` atau `Breaking Bad Season 1-5`. Indexer menyimpan pack seperti ini di bawah setiap season yang dicakupnya. Di feed DMM, 72 dari 691 hasil untuk Breaking Bad season 3 adalah pack dengan beberapa season. Untuk beberapa season, salah satu pack ini adalah satu-satunya salinan yang dimiliki sebuah akun.

- **Judulnya menunjukkan season apa saja.** `S01-S05`, `S01-05`, `[S01-08]`, `S1-9`, `Seasons 1-8`, `Season 1 to 5`, `Season 1 · 2 · 3`, `Stagioni 01-05`, dan `Temporadas 1-4` semuanya dibaca. Judul tanpa nomor season, seperti `Complete Series`, tidak diambil. Judul yang hanya menyebut satu season sebagai kata, seperti `Season 3 Complete`, juga tidak. Judul seperti itu memang tidak pernah dibaca sebagai pack.
- **Hanya season itu yang dipindahkan.** Pack yang diambil untuk season 4 hanya menaruh episode season 4 ke folder season. File season lain tetap berada di tempat library mencantumkannya. Pack yang filenya tidak memuat semua episode dari season tersebut akan ditolak sebelum ada yang dipindahkan, apa pun yang tertulis di judulnya.
- **Ukuran dinilai per episode.** Ukuran pack dibagi dengan jumlah season yang disebutkan, lalu dibagi lagi dengan jumlah episode season itu, dan hasilnya dibandingkan dengan `max_size_gb`, sama seperti encode yang sama jika diposting per episode. Pack 346 GB berisi delapan season masing-masing sepuluh episode berarti 4,3 GB per episode. Remux season 2 I Love Lucy yang berisi 31 episode berukuran 106 GiB, atau 3,4 GiB per episode, dan masih muat di batas 40 yang ditulis. Jika sumbernya tidak mencantumkan episode season tersebut, pack tidak dibatasi per episode. `max_season_size_gb` yang kamu tulis akan membatasi setiap season yang disebut pack, di atas batas per episode. Secara default, batas ini tidak ada.
- **Kualitas tetap yang utama.** Pack diurutkan seperti rilis lainnya: resolusi dulu, lalu isinya per episode, sesuai urutan di halaman season DMM. Pack 2160p untuk satu season diambil sebelum pack 1080p untuk delapan season. Di dalam resolusi yang sama, remux milik satu season didahulukan daripada pack delapan season yang total ukurannya lebih besar tetapi per episodenya lebih kecil.
- **Season lain dari show yang sama memakai pack yang sama.** Setelah satu season mengambil pack beberapa season, season lain dari show itu akan mencoba pack tersebut lebih dulu, sebelum setiap pack dengan resolusi yang sama hasil pencarian mereka sendiri. Pack itu sudah ada di akun, jadi tidak ada biaya tambahan. Saat season-season sebuah show sedang memilih di antara pack beberapa season, mereka memilih satu per satu. Dengan begitu, season yang diminta bersamaan (misalnya satu series Sonarr dengan semua season-nya pada satu polling) tidak masing-masing memilih salinan show yang berbeda. Setelah salah satu dari mereka memilih tanpa pack seperti itu, karena tidak ada di akun atau profil tidak mengizinkannya, sisanya memilih sekaligus. Season yang diminta satu jam kemudian akan mencari dari awal.

## Melihat cara kerjanya {#watching-it-work}

Tautan **Acquisition** di dasbor membuka `/acquisition/` pada port zurg sendiri.
Setiap sumber mendapat satu baris yang menunjukkan berapa banyak judulnya yang sudah selesai, sedang berjalan, menunggu, dikesampingkan, dan antre, di samping jumlah judul yang dikerjakan zurg sekaligus, jumlah panggilan yang dibuat ke satu indexer sekaligus, dan jumlah koneksi news yang boleh dipakai akun `nzb`-nya.
Di bawahnya, setiap sumber punya tabel dengan satu baris per judul. Sebuah baris menampilkan status, apa yang sedang dilakukan judul yang berjalan saat ini (pencarian, berapa hasil yang sudah dinilai dan diterima sejauh ini, kandidat yang sedang diperiksa, pengecekan ke server news, penempatan), percobaannya, release yang dipilih beserta kualitas dan skor yang diberikan sumber, di mana judul itu ditempatkan, dan kapan judul yang menunggu akan dicoba lagi berikutnya. Judul yang semua release-nya sudah tidak tersisa untuk dicoba akan menjelaskan alasannya, dengan penolakan dari sumber dihitung per aturan: `14 refused by the source's own rules (title mismatch 7, quality 5, size 2)`. Release yang ditolak karena resolusinya tanpa bertanya ke sumber dihitung di bawah quality.
Halaman ini memperbarui dirinya sendiri setiap lima detik. Snapshot yang sama ada di `/acquisition/status.json`, di mana alasan tadi menjadi `detail` judulnya. Saat tidak ada sumber yang diaktifkan, atau acquisition sudah dikonfigurasi tapi dijeda, halaman akan memberi tahu hal itu beserta alasannya.

Setiap film yang dipilih releasenya mendapat satu baris di log, untuk mengukur waktu dihabiskan di mana:

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` adalah hasil yang dikembalikan pencarian, `local_refusals` hasil yang ditolak tanpa bertanya ke sumber, `radarr_refusals` hasil yang ditolak oleh aturan sumber itu sendiri, `inspected` NZB yang dibaca, `radarr_calls` pertanyaan yang diajukan ke sumber (NZB yang dibaca ditambah penolakan di jalan menuju ke sana, jika sumbernya Radarr), dan waktunya dihitung dari awal pencarian. Release yang ditolak tanpa bertanya dicatat satu per satu hanya pada level debug.

## Memeriksa *arr yang hanya memakai zurg sebagai download client {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

Sonarr atau Radarr yang diarahkan ke endpoint [SABnzbd](sonarr-radarr.md) atau
[qBittorrent](sonarr-radarr-torrents.md) milik zurg melakukan pencariannya sendiri, dan tidak
perlu sumber di sini. zurg tetap membutuhkan API key-nya, karena tiga pengaturannya
menentukan apakah setiap impor hanya berupa rename gratis atau seluruh rilis diunduh
dari akun debrid dan ditulis ke disk zurg: Remove Completed pada klien qBittorrent, folder unduhan
dan root folder berada di satu volume, dan root folder di dalam `__magic__`. Dengan key tersebut, zurg
mengaktifkan Remove Completed sendiri (lihat [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
dan memberi peringatan untuk dua pengaturan lainnya. Lihat
[Satu volume untuk folder unduhan dan root folder](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

Cara termudah untuk memberi zurg key ini adalah lewat banner di dashboard utama,
yang dijelaskan di bawah. Atau tambahkan sebagai sumber yang dimatikan:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

Sumber Radarr atau Sonarr dengan `enabled: false` tidak mengunduh apa pun. zurg tidak pernah
membaca daftar keinginannya dan tidak pernah mencarinya. Dengan `url` dan `api_key`
diisi, dan salah satu dari dua endpoint aktif, zurg hanya membaca root folder, remote path mapping,
dan download client milik \*arr, saat start, setiap sepuluh menit, dan begitu \*arr pertama kali
memanggil salah satu endpoint. Jika Remove Completed pada klien qBittorrent zurg untuk \*arr tersebut
sedang mati, zurg menyalakannya; ini satu-satunya perubahan yang dilakukan zurg, dan zurg
melaporkan layout yang membuat impor menjadi salinan. Setiap sumber dengan URL dan API key,
baik aktif maupun tidak, diperiksa dan dikoreksi dengan cara yang sama. Sumber tersebut
tercantum di halaman acquisition di bawah **Checked, never searched for**, dengan
apa yang diubah zurg. Temuannya masuk ke log, dan `zurg doctor` menampilkannya sebagai
`imports (<name>)`. `library_path` tidak dinilai untuk sumber seperti ini, karena
tidak ada yang ditempatkan untuknya. Sumber yang ditambahkan ke config.yml secara manual dibaca saat start, jadi restart zurg setelah menambahkan sumber dengan cara itu.

zurg juga mendeteksi Sonarr atau Radarr yang tidak bisa diperiksanya. Keduanya mengirim nama mereka di
setiap permintaan ke endpoint (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), jadi zurg
mencatat mana yang memanggilnya dan dari alamat mana. Ketika ada yang memanggil dan tidak ada
sumber dengan jenis yang sama memiliki URL dan API key, zurg mencatat satu peringatan, `zurg
doctor` melaporkannya di baris `*arr settings`-nya, dan dashboard utama menampilkan banner dengan
form untuk URL dan API key. URL diisi dengan tebakan: alamat tempat \*arr memanggil, pada port default-nya (8989 untuk Sonarr, 7878
untuk Radarr). Alamat itu sering kali milik container, dan zurg mungkin bisa atau tidak bisa menjangkaunya, jadi ubah ke URL apa pun yang bisa menjangkau \*arr dari tempat zurg berjalan. API key ada di \*arr pada Settings, General, Security. zurg
pertama-tama meminta status ke \*arr dengan key itu, dan tidak menyimpan apa pun kecuali \*arr menjawab sebagai aplikasi dengan nama yang sesuai. Lalu zurg menambahkan sumber di atas ke config.yml dengan `enabled: false`, dan menjaga isi file lainnya tetap seperti semula, lalu langsung memeriksanya tanpa restart. Form menampilkan apa yang ditemukan dan diubah zurg. Key ditulis ke config.yml dan dikirim ke \*arr, dan tidak ke tempat lain.

Banner dicocokkan berdasarkan jenis, bukan alamat: \*arr memanggil zurg dari dalam container-nya, lewat alamat yang tidak ada hubungannya dengan URL tempat zurg menjangkaunya, jadi satu sumber Sonarr dengan key sudah cukup untuk menyembunyikan banner untuk semua Sonarr.

(Terjemahan sebelumnya ditolak: code span berbeda (` reports it on its `). Pertahankan struktur persis.)

## Mencari rilis duplikat {#finding-duplicate-releases}

Upgrade membiarkan release yang digantikannya tetap ada di library kamu. Dengan `magic.allow_delete` mati, perintah hapus dari Radarr atau Sonarr untuk file lama hanya menyembunyikannya di `__magic__`, jadi release lama tetap ada di `__all__` dan di akunnya.

Grab dari lebih dari satu indexer, atau season pack bersama episode lepas, juga menyisakan beberapa release dari hal yang sama. **Manage > Duplicates** (`/manage/duplicates/`) menampilkannya, menunjukkan release mana yang dipakai Radarr atau Sonarr, dan memungkinkan kamu menghapus yang lain. Halaman ini tidak pernah menghapus apa pun dengan sendirinya.

**Release mana yang sedang dipakai dibaca dari path, bukan dari nama.** Setiap file yang dipegang Radarr dan Sonarr dinamai lewat path di bawah `__magic__`, dan zurg tahu setiap path berasal dari release mana, karena proses pemindahan yang menaruh file di sana mencatatnya. Tampilan ini membaca setiap file yang sudah diimpor setiap \*arr, baik dimonitor atau tidak, sudah mencapai cutoff atau belum, lalu melacak tiap file ke release-nya. File Sonarr dilacak episode demi episode, jadi season pack yang tiga episodenya diambil Sonarr ditampilkan sebagai sedang dipakai untuk ketiga episode itu.

**Release mana yang mungkin salinan hanyalah tebakan, dan halaman ini mengatakannya.** Release dikelompokkan dengan sebuah film, atau dengan sebuah season, ketika:

- sebuah file \*arr ada di dalamnya,
- history \*arr mencatat bahwa ia mengimpor dari release itu, atau menghapus file yang berasal darinya (karena upgrade, dihapus manual, atau hilang dari disk),
- zurg mengidentifikasinya sebagai IMDb id film atau series tersebut, atau
- nama release-nya menunjukkan judul dan tahun (tahun yang meleset satu, atau tahun kedua Radarr untuk film, tetap dihitung) atau nama series dan season.

Setiap release menampilkan kriteria mana yang membuatnya masuk grup. Sebuah season hanya menjadi grup jika beberapa release memuat episode yang sama: enam puluh release satu-episode dari satu season adalah enam puluh episode yang berbeda. Grup season menampilkan episode yang dimuat lebih dari satu release, release mana yang memuat tiap episode, release mana yang berisi file Sonarr, dan berapa banyak episode yang dimuat tiap release yang tidak dimiliki release lain dalam grup. Tidak ada release yang dipilih sebagai pemenang. Release yang tidak cocok dengan item Radarr atau Sonarr mana pun ada di bawah **Name matches only**, dikelompokkan berdasarkan nama dan IMDb id-nya.

**Setiap release berstatus In use, No reference found, atau Unknown.**

| Status | Arti |
|---|---|
| In use | Sebuah file yang saat ini dipegang Radarr atau Sonarr ada di release ini. Release ini tidak bisa dipilih. |
| No reference found | Setiap Radarr dan Sonarr yang dikonfigurasi sudah dibaca sepenuhnya, dan tidak ada file mereka di release ini. Plex, Jellyfin, dan klien lain yang membaca mount tidak terlihat dari sini, jadi ini bukan bukti bahwa tidak ada yang memutarnya. |
| Unknown | zurg tidak bisa memastikannya. Setiap release berstatus Unknown selama sebuah \*arr tidak bisa dibaca, selama library masih dimuat, atau saat `__magic__` mati. Sebuah release juga Unknown ketika file \*arr untuk film atau episode yang sama tidak bisa dilacak ke release mana pun, atau ketika history \*arr menunjukkan file dari release ini hilang dari disk dan film atau episode itu tidak punya file sejak saat itu. |

**Kualitas ditampilkan dalam istilah profil.** Untuk release yang dipakai \*arr, nilainya adalah penilaian \*arr itu sendiri terhadap file tersebut. Untuk release yang pernah diimpornya sebelumnya, nilainya adalah penilaian yang diberikan saat itu. Selain itu, nilainya dibaca dari nama release dan halaman ini mengatakannya. Masing-masing ditempatkan dalam quality profile item tersebut, misalnya "rank 15 of 17 in 4K or best available (cutoff at 17)".

**Penghapusan membaca ulang dulu.** Pilih release, lalu pilih **Check again and delete**. zurg membaca ulang file saat ini dari setiap \*arr, dan baru setelah itu menawarkan penghapusan. Release yang sudah mulai dipakai sejak halaman dimuat akan dikeluarkan dari daftar, dan release Unknown hanya dihapus jika kamu mencentangnya lagi di dialog itu. Penghapusannya sendiri adalah bulk delete dari halaman manage, yang menghapus setiap salinan release dari setiap akun yang memilikinya.

**Kapan dibaca.** Saat halaman dibuka untuk pertama kali, halaman ini membaca setiap Radarr dan Sonarr di bawah `acquisition.sources`, termasuk history impor dan penghapusan. Membaca history library besar bisa memakan waktu satu menit. Setelah itu, halaman menampilkan apa yang terakhir dibaca dan kapan, sampai kamu memilih **Read Radarr and Sonarr again**. Source dengan `enabled: false` tetap dibaca: mematikan acquisition tidak mengubah apa yang dipegang \*arr. Halaman menampilkan jumlah tiap source: file yang dibaca, yang dilacak ke sebuah release, yang berada di luar `library_path`-nya, dan yang berada di dalam `__magic__` tetapi tidak mengarah ke mana pun. Jika tidak satu pun file dari sebuah source bisa dilacak ke release, periksa `library_path`-nya.

Laporan yang sama tersedia di `/manage/duplicates/report.json`, dan `POST /manage/duplicates/check` dengan `{"hashes": [...]}` membaca ulang \*arr dan memberikan status setiap release.

## Newznab dan Torznab {#newznab-and-torznab}

Entri indexer memberi tahu jenisnya lewat `type`. Jika tidak ada, artinya `newznab`, yaitu jenis yang dipakai semua entri yang ditulis sebelum fitur ini ada. Kueri untuk keduanya sama, tetapi hasilnya berbeda. Hasil Newznab adalah NZB, yang diambil lalu disimpan ke `nzbs/` untuk backend Usenet. Hasil Torznab adalah info hash, yang diserahkan ke akun debrid. Hasil Torznab yang tidak memiliki atribut magnet atau `infohash` akan dilewati. zurg tidak pernah mengunduh `.torrent`, jadi hasil yang hanya bisa dijangkau lewat cara itu tidak bisa diproses.

**Torrent hanya pernah ditambahkan ke akun yang sudah memilikinya.** Setiap akun yang menerima penambahan akan ditawari hash-nya, kecuali akun Real-Debrid yang dilewati untuk nama rilis yang ditolak mentah-mentah, karena cache tiap akun terpisah dan satu akun yang sudah membersihkan sebuah rilis tidak berarti akun berikutnya juga begitu. Akun pertama yang sudah memilikinya akan mengambilnya. Jika tidak ada akun yang memilikinya, ini dianggap kandidat gagal biasa, sehingga proses berpindah ke rilis berikutnya di peringkat, yang mungkin torrent lain atau NZB.

Di TorBox dan Debrid-Link, jika tidak ada hasil, tidak ada yang ditambahkan. Di AllDebrid dan Offcloud, torrent langsung dihapus. Real-Debrid dan Premiumize akan menambahkan torrent lalu memantaunya selama hingga 20 detik. Konten yang sudah ter-cache siap dalam satu atau dua detik. Apa pun yang masih diunduh setelah itu akan dihapus lagi. Jadi tidak ada unduhan yang dibiarkan berjalan di akun. Meski begitu, percobaan yang meleset tetap tidak sepenuhnya gratis. Percobaan itu tetap bisa dihitung terhadap batas penambahan akun. Di TorBox, percobaan ini memakai salah satu dari 60 penambahan uncached yang diizinkan per jam.

Akun yang diberi tanda `watchlist: true` ditawari torrent lebih dulu. Akun lainnya mengikuti urutan dalam daftar `providers:` kamu. Akun yang diberi tanda `add_torrents: false` tidak pernah ditawari torrent.

`prefer` menentukan jenis mana yang dicoba lebih dulu jika keduanya bisa memenuhi target dengan resolusi yang sama. Resolusi didahulukan: torrent 2160p yang sudah dimiliki akun akan diambil sebelum NZB 1080p, apa pun isi `prefer`-nya. `usenet` adalah pilihan default, karena mengambil dari Usenet memakan satu unduhan sedangkan torrent memakan satu slot penambahan akun. `torrents` membalik urutannya, dan `best` menghapus pembedaan itu dan mengambil apa pun yang ada di urutan teratas peringkat, yaitu rilis yang lebih besar dalam satu resolusi.

Satu film mencoba hingga tiga torrent per percobaan. Setiap torrent memakan satu penambahan. Hingga 24 NZB-nya diperiksa sendiri-sendiri, seperti yang dijelaskan di [memilih rilis film](#choosing-a-movies-release). Dengan `usenet`, NZB dari satu resolusi dicoba sebelum torrent-nya. Dengan `torrents`, torrent-nya datang lebih dulu. Dengan `best`, setiap torrent menunggu gilirannya sesuai peringkat. NZB dari satu resolusi dicoba bersama-sama di posisi NZB terbaiknya. Dengan sumber Radarr, NZB dari semua resolusi dicoba bersama-sama di posisi yang terbaik, dimulai dari yang paling murah, seperti yang dijelaskan di bagian itu. Satu paket musim mencoba tiga rilis per percobaan, dari jenis apa pun. Begitu juga setiap episode lepas.

Verifikasi yang ditunggu sebuah grab berbeda tergantung sumbernya. Rilis Usenet dicek ke news server, yang merupakan satu-satunya cara untuk tahu apakah postingannya masih ada. Akun `torbox_nzb` tidak memiliki news server untuk dicocokkan, jadi grab di sana dicek apakah TorBox sudah mengambil NZB-nya. Torrent hanya ditambahkan karena akun menyatakan sudah memiliki kontennya, jadi yang masih perlu dipastikan adalah bahwa rilis tersebut sudah masuk ke library dengan file di dalamnya. Itulah yang dicek, dan rilis yang oleh akun tercatat kosong akan dikesampingkan seperti postingan mati.

Instalasi tanpa akun NZB (`nzb` atau `torbox_nzb`) tetap bisa menjalankan akuisisi hanya dari indexer Torznab. Indexer Newznab-nya tidak dicari di sana, karena tidak ada apa pun di instalasi itu yang bisa memutar NZB. Log akan menyebutkan hal ini sekali untuk masing-masing indexer tersebut. Instalasi tanpa akun yang menerima torrent juga tidak mencari indexer Torznab-nya, dengan cara yang sama. Dalam kedua kasus, rilis dari jenis yang tidak punya tempat untuk disimpan di instalasi itu tidak akan pernah menjadi kandidat. Rilis seperti itu tidak memakai jatah rilis mana pun dalam sebuah percobaan, dan sumber seperti Radarr tidak akan pernah ditanya tentangnya.

### Batas indexer dan kunci yang ditolak {#indexer-limits-and-refused-keys}

**zurg menahan diri di bawah batas DMM, bukan menabraknya.** DMM mengizinkan kunci sponsor 20 pencarian per menit untuk semua feed torrent-nya, jadi zurg mengirim paling banyak satu pencarian ke DMM setiap tiga detik. Pencarian yang melewati batas itu akan menunggu gilirannya, dan menunggu bukan berarti pencarian gagal. Pencarian yang gilirannya baru datang setelah usaha untuk judulnya harus berakhir, atau lebih dari dua menit lagi, tidak akan dikirim: judul tersebut tetap lanjut dengan hasil dari indexer lain.

**Indexer yang menjawab 429 atau 503 dibiarkan dulu selama waktu yang dia minta.** Setiap pencarian, unduhan NZB, dan pengecekan kemampuan menunggu sesuai `Retry-After`-nya, sampai dua menit, termasuk permintaan yang sudah menunggu gilirannya. Indexer yang minta lebih lama tidak akan ditanya sampai waktu itu lewat.

**Beberapa zurg dengan satu kunci DMM berbagi 20 pencariannya.** Setiap zurg tetap menghitung seluruh jatah, jadi dua atau tiga zurg di satu kunci masih bisa menabrak batas DMM, dan setiap penolakan menjeda pencarian DMM zurg tersebut selama satu menit. Akibatnya, judul bisa menunggu lebih lama untuk pencarian dan pengambilannya.

**Kunci yang ditolak dibiarkan dulu selama satu jam.** Indexer yang menjawab error 100 (kunci salah) atau 101 (akun ditangguhkan, yang dijawab DMM saat sponsor sudah berakhir) tidak akan ditanya lagi selama satu jam, baik untuk pencarian maupun unduhan NZB. Log hanya mencatatnya sekali, misalnya `DMM torrents refused the API key: check dmm_api_key`, dan halaman acquisition menampilkannya di bawah **Indexers not asked now**. Kunci yang kamu ubah di `config.yml` langsung dicek ulang. Error lain hanya berlaku untuk pencarian itu saja.

## Memilih rilis sebuah film {#choosing-a-movies-release}

Kandidat Usenet untuk film dicoba berdasarkan seberapa mahal biayanya untuk dikonfirmasi, bukan hanya seberapa bagus kualitasnya. Post yang berisi satu video bernama hanya butuh dua kali pembacaan artikel di zurg dan biasanya sudah lengkap, sedangkan satu set arsip empat puluh volume butuh satu kali pengecekan ukuran dan pembacaan di kedua ujung setiap volume, dan sekitar dua pertiga set remux multi-volume di indexer sudah hilang. Jumlah `files` dari indexer itu sendiri memperkirakan bentuk post, jadi kandidat diurutkan berdasarkan jumlah ini: sepuluh file atau kurang, lalu sampai tiga puluh, lalu lebih banyak, lalu tidak diketahui, dan berdasarkan jumlah file di dalam setiap kelompok. Di antara post dengan biaya yang sama, jika sumber seperti Radarr menilai rilis dengan profil miliknya sendiri, judul yang menyebut WEB-DL atau WEBRip didahulukan, lalu Blu-ray, lalu sisanya, dan post yang lebih besar didahulukan di setiap kelompok. Peringkat dari sumber itu sendiri tidak dipakai di sini, karena hanya bisa diketahui dengan bertanya ke sumber, dan zurg baru bertanya tentang sebuah rilis saat akan memeriksanya. Tanpa sumber, peringkat kualitas lalu ukuran yang menentukan. Jika tidak ada sumber yang menilai kandidat, resolusi yang diminta oleh pengaturan `quality` didahulukan sebelum biaya, jadi watchlist yang diatur ke `best` tetap mendapatkan resolusi terbaik yang tersedia, dengan post termurah didahulukan di dalamnya. Hasil yang judulnya merujuk ke salah satu bagian dari post terpisah (`[1/9] "Movie.part1.rar"`) tidak pernah dijadikan kandidat, dan dari dua post dengan nama yang sama hanya post dengan jumlah file lebih sedikit yang disimpan, karena pustaka hanya bisa menampung salah satunya.

Setelah itu, hingga 24 kandidat diperiksa: setiap NZB diunduh dan dibaca dengan parser milik zurg sendiri. Post dengan paling banyak dua file konten, salah satunya video bernama `.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov`, atau `.ts` berukuran minimal 500 MB, disebut direct post; volume PAR2 dan sidecar seperti `.nfo`, `.sfv`, `.srr`, `.nzb`, gambar, `.txt`, `.url`, dan `.exe` tidak dihitung sebagai konten. Direct post pertama langsung disimpan. Archive post ditahan dulu sampai direct post yang ada habis, lalu dicoba dengan volume paling sedikit lebih dulu, melalui gerbang yang hanya membolehkan paling banyak enam rilis arsip menunggu di news server dalam satu waktu. Post yang isinya hanya data perbaikan dan sidecar tidak pernah disimpan. NZB yang sudah diperiksa disimpan di memori, jadi saat rilis yang sudah disimpan ternyata mati dan judulnya dicoba lagi, kandidat berikutnya langsung dicapai tanpa mengunduh ulang NZB sebelumnya. Pencarian dan unduhan NZB berbagi satu batas permintaan yang sedang berjalan per indexer, dan jika indexer membalas `429` atau `503`, permintaan diulang setelah jeda, dengan menghormati `Retry-After`-nya. Dashboard menampilkan setiap langkah: pencarian, kandidat mana yang sedang diperiksa, dan apa yang sudah disimpan. Serial memakai alur awal: tiga rilis peringkat terbaik yang tidak dikesampingkan. Jika sumber menilai rilis, seperti yang dilakukan Sonarr, setiap rilis diajukan ke sumber lebih dulu, dan rilis yang ditolak sumber tidak memakan salah satu dari tiga slot. `best_first` mengubah urutan kedua alur seperti yang dijelaskan di bagian berikutnya.

## Mengambil yang teratas dari profil lebih dulu {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

Nonaktif secara default. Jika diaktifkan, pencarian pertama dari sumber Radarr atau Sonarr akan mengikuti urutan preferensi dari quality profile, bukan berdasarkan biaya pengecekan sebuah rilis. Watchlist Plex dan Seerr tidak punya profile, jadi tidak terpengaruh. Halaman acquisition akan menunjukkan kalau fitur ini sedang aktif.

- **Resolusi terbaik dari profile didahulukan.** Setiap rilis ditempatkan berdasarkan resolusi yang tertulis di judulnya. Posisinya ditentukan oleh kualitas terbaik yang diizinkan profile di resolusi tersebut. zurg membacanya dari profile yang sudah dimilikinya dan tidak meminta apa pun lagi dari Radarr dan Sonarr. WEB-DL, Blu-ray, dan remux dengan resolusi yang sama berbagi posisi yang sama. Di dalam satu posisi, film tetap mengambil rilis yang paling murah untuk dicek. Serial mengambil rilis yang paling tinggi peringkatnya di `quality`. Judul yang tidak menyebut resolusi ditaruh paling akhir.
- **Cutoff dihitung sebagai yang teratas.** Selama profile mengizinkan upgrade, setiap kualitas di atas atau sama dengan cutoff dianggap sama dengan cutoff. Proses upgrade tidak akan pernah menggantikan salah satu dari kualitas tersebut. Profile yang melakukan upgrade sampai WEB 1080p tidak mendapat keuntungan dari opsi best first, meskipun profile itu juga mengizinkan 2160p. Profile yang tidak mengizinkan upgrade tetap memakai seluruh urutannya. File pertama yang didapat akan disimpan.
- **Turun ke bawah profile jika gagal.** Rilis yang NZB-nya tidak bisa diunduh atau dibaca akan dilewati. Rilis yang ditolak oleh news server tetap disingkirkan seperti sebelumnya. Rilis berikutnya dalam urutan profile akan dicoba. Satu percobaan tetap hanya membaca paling banyak 24 NZB secara keseluruhan, apa pun posisinya.
- **Fitur ini didahulukan sebelum preferensi Usenet atau torrent.** Torrent yang sudah dimiliki sebuah akun akan diambil lebih dulu daripada NZB yang berada di posisi lebih rendah di profile. `prefer` tetap menentukan pilihan antara NZB dan torrent yang berada di posisi yang sama.
- **Season pack harus sama baiknya dengan episode lepas.** Pack yang peringkatnya lebih rendah dari episode lepas dari pencarian yang sama akan dilewati. Episodenya kemudian diambil satu per satu. Sonarr juga membuat pilihan yang sama. Hanya pencarian itu saja yang dibandingkan. Sebuah episode tidak akan dicari lagi secara terpisah untuk memastikan tidak ada rilis yang lebih baik.

Fitur ini punya konsekuensi. Bagian teratas profile 2160p sebagian besar berisi set remux dan Blu-ray dengan empat puluh volume atau lebih, bukan file video tunggal. Set seperti itu butuh waktu lebih lama untuk dicek. Lebih sering sudah hilang dari news server. Selain itu, set tersebut juga harus menunggu giliran di gerbang archive. Akibatnya, file pertama biasanya datang lebih lama. Jika semua rilis terbaik sebuah judul sudah hilang, setiap rilis itu akan diambil, dicek, lalu disingkirkan sebelum zurg turun ke bawah profile. Sebuah season yang diambil sebagai episode lepas memerlukan beberapa kali pengambilan, sedangkan dengan pack cukup satu kali. Yang dihemat adalah pengambilan kedua. File pertama yang sudah berada di cutoff tidak akan pernah di-upgrade.

## Apa yang dilakukan akuisisi pada daftar milik sumber {#what-acquiring-does-to-the-sources-own-list}

Watchlist Plex adalah daftar yang dibuat seseorang, dan itu satu-satunya catatan bahwa mereka menginginkan sebuah judul. Plex tidak menyimpan riwayat entri yang sudah dihapus. Dua pengaturan menentukan apa yang boleh dilakukan zurg terhadap watchlist itu. Keduanya berlaku untuk sumber `plex_watchlist`. Sumber Seerr dan Radarr tidak punya daftar yang ditulis zurg, jadi keduanya tidak berpengaruh di sana.

`remove_after_grab` (default `true`) menghapus judul yang sudah didapat dari watchlist setelah rilis di baliknya diperiksa. Begitulah fitur ini selalu bekerja: watchlist dibaca sebagai antrean hal yang harus didapat, dan judul yang sudah didapat zurg dianggap selesai. Kalau kamu atur ke `false`, watchlist tetap jadi watchlist, yaitu daftar yang tahan lama untuk dijelajahi, dan zurg memenuhinya di latar belakang tanpa mengubahnya. Membiarkan judul tetap di daftar tidak memakan biaya untuk dicek ulang. Buktinya sudah mencakup judul itu, jadi tidak ada indexer yang ditanya lagi soal judul tersebut.

Judul yang tidak didapat zurg sama sekali tetap ada di watchlist, apa pun pengaturan ini. Kalau setiap rilis yang menuntaskan judul itu sudah ada di library, entah salinanmu sendiri atau yang dibawa permintaan lain, tidak ada yang diambil atau ditambahkan. Menghapusnya hanya akan mengubah daftarmu. Rilis-rilis itu tetap diperiksa, dan judul itu tetap dihitung selesai, jadi tidak dicari lagi selama masih ada di daftar. Kalau dihapus lalu ditambahkan lagi, ia akan tetap ada. Pertunjukan yang salah satu musim atau episodenya pernah diambil zurg dianggap sudah didapat, dan akan keluar seperti biasa.

`only_new_items` (default `true`) mengadopsi apa pun yang sudah ada di daftar saat sumber pertama kali dijalankan, dan hanya bertindak atas yang ditambahkan setelahnya. Saat fitur ini diaktifkan, yang dimulai adalah memantau sebuah daftar, bukan menghabiskan satu malam untuk mengerjakan semuanya. Atur ke `false` kalau kamu ingin memperlakukan daftar yang sudah ada sebagai tumpukan tertunda.

Pengaturan ini berlaku **sekali, saat sumber pertama kali dijalankan**. Sumber yang sudah punya antrean berarti sudah berjalan, dan antrean itulah, bukan sakelar ini, yang mencatat apa yang sudah dan belum dikerjakan. Jadi mengaktifkannya nanti tidak akan pernah menghapus tumpukan yang sedang berjalan. Judul yang sudah diadopsi tetap diadopsi selama masih ada di daftar. Menghapusnya lalu menambahkannya lagi adalah permintaan baru yang biasa.

## Memverifikasi grab {#verifying-a-grab}

Sebuah NZB yang tersimpan belum tentu rilis. Indexer yang menjawab, jawabannya bisa diurai sebagai NZB, dan file-nya sampai ke `nzbs/` itu semua fakta tentang indexer, bukan tentang posting. Jadi setiap NZB yang diambil akan dicek ke akun news yang sudah dikonfigurasi sebelum mesin mengonfirmasi permintaan. Enam belas artikel pertama dan artikel terakhir dari setiap file konten ditanya dengan `STAT`. Artikel pertama dari setiap file, ditambah beberapa lagi untuk rilis dengan sedikit file, diunduh utuh (paling banyak enam puluh empat). Alasannya, server news bisa menjawab `STAT` untuk artikel yang kontennya sudah mereka turunkan. Artikel yang ditolak `STAT` juga diunduh utuh sebelum dianggap hilang, karena server news bisa juga menolak `STAT` untuk artikel yang masih mereka sajikan (NewsDemon pernah begitu pada 2026-10-21). Paling banyak enam belas artikel seperti ini per rilis. Pengecekan ini sama dengan yang dilakukan `/api?mode=addfile` untuk Sonarr dan Radarr. Ada tiga kemungkinan jawaban, dan memisahkannya itu intinya:

- **Artikel hilang.** Pengambilan tidak dihitung. Tanda terima dibuka lagi, jadi target kembali diminta, dan rilis itu dicatat sebagai mati selama 30 hari. Dengan begitu, percobaan berikutnya akan memilih kandidat berikutnya, bukan kembali ke rilis yang sudah ada di pustaka. Rilis yang ada di daftar ini bukan kandidat: tidak diunduh, dan tidak memakan salah satu kandidat yang dicoba dalam satu percobaan. Jadi deretan posting mati di urutan atas akan dilewati, bukan membuat semua yang di bawahnya tidak terjangkau. Season pack yang mati membuat seluruh season kembali diminta, dan episode lepasannya yang diambil. NZB yang disimpan oleh permintaan ini sendiri akan dihapus dari folder pantau, supaya setelah restart NZB itu tidak dimuat dan dicek lagi sebelum pustaka terbuka. NZB yang sudah ada di folder pantau atau pustaka, dan NZB yang diimpor Sonarr atau Radarr, tetap di tempatnya.
- **Akun tidak bisa ditanya.** Pool sedang mati, akun kena pembatasan laju, atau kasus biasa ketika pustaka belum mendaftarkan NZB baru. Karena belum ada yang terbukti, belum ada keputusan: permintaan dicek ulang dalam 20 detik, lalu setelah 40 dan 80 detik, lalu setiap dua menit. Waktu tunggu ini tidak memakan percobaan ulang. Pengecekan yang hanya kehabisan waktu tidak termasuk kasus ini. Pengecekan itu langsung dimulai lagi dengan waktu penuh, sampai tiga kali, sebelum mulai menunggu. Waktu penuhnya lima menit, atau lebih lama untuk rilis dengan banyak file pada akun dengan sedikit koneksi. zurg menghitungnya dari jumlah file dan koneksi, dari pengecekan paling lambat yang pernah diukur, dan dari enam pengecekan yang berjalan bersamaan, lalu menggandakannya. Rilis 90 volume di empat koneksi sekarang mendapat sekitar 53 menit. Dulu lima menit selalu habis di setiap percobaan, sampai rilis itu disisihkan tanpa pernah dicek. Dua puluh pengecekan selama dua jam yang tidak memastikan apa pun membuat rilis itu disisihkan seperti rilis mati, dan percobaan berikutnya mencoba rilis lain. Permintaan tidak pernah dikonfirmasi untuk rilis yang tidak bisa dicek siapa pun.
- **Rilisnya ada.** Tanda terima melepas apa yang ditahannya, dan konfirmasi dilanjutkan.

Pengecekan menunggu sampai zurg selesai mempelajari ukuran file rilis yang pasti, atau sudah menyerah mempelajarinya. Titik ini sama dengan titik yang dicek endpoint SABnzbd. Mempelajari ukuran berarti membaca artikel pertama dari setiap file, dan pengecekan juga melakukannya, jadi menjalankan keduanya bersamaan hanya membuat keduanya lebih lambat. Pada daftar 99 film, mengecek setiap rilis begitu muncul di daftar membuat file terakhir baru masuk ke folder Radarr setelah hampir sembilan menit. Pengecekan yang masih menunggu ukuran saat waktunya habis langsung dimulai lagi, sama seperti pengecekan yang kehabisan waktu. Rilis yang masih dihitung ukurannya setelah 30 menit tetap dicek. Paling banyak enam rilis dicek bersamaan, sisanya menunggu gilirannya.

Pengecekan hanya membaca. Ia tidak memindahkan isi artikel ke cache dan tidak mencatat artikel mati, jadi tidak bisa membungkam file yang bisa diputar. Ketika pass penentuan ukuran baru saja mengunduh artikel pertama sebuah file, pengecekan membaca salinan itu dan tidak mengunduhnya lagi.

Instalasi tanpa akun NZB (`nzb` atau `torbox_nzb`) tidak punya apa pun untuk mengecek pengambilan NZB. Pengambilan tetap berjalan di sana jika akun debrid menerima torrent. Setiap torrent dicek dengan melihat apakah ia sampai ke pustaka dengan isi file, seperti yang dijelaskan di [Newznab dan Torznab](#newznab-and-torznab). Torrent itu juga harus memuat sesuatu yang bisa diputar: video, audio, atau arsip yang bisa di-stream zurg (RAR, 7z, zip, atau bagian bernomor). Torrent yang hanya berisi program, image disc, atau teks adalah palsu. Hal seperti ini sering muncul dalam beberapa jam pertama setelah episode baru tayang. Torrent seperti itu disisihkan seperti posting mati, dan rilis berikutnya langsung dicoba. Jika zurg menambahkannya ke akun untuk permintaan ini, torrent itu dihapus lagi dari akun. Torrent yang sudah ada di akun sebelumnya dibiarkan di tempatnya. Permintaan NZB tidak pernah dikonfirmasi tanpa akun NZB, karena tidak ada yang bisa mengeceknya atau memutarnya. NZB yang masih menunggu dari sebelum akun NZB terakhir dihapus akan disisihkan seperti posting mati, dan rilis berikutnya dicoba.

## Penyimpanan dan pemulihan {#persistence-and-recovery}

`data/acquisition.json` menyimpan ID sumber/permintaan, percobaan, tenggat coba ulang, pekerjaan yang sedang berjalan, dan receipt untuk tiap akuisisi, termasuk episode. File ini juga mencatat, per sumber, bahwa snapshot pertama sudah diadopsi, jadi `only_new_items` diputuskan sekali saja, bukan setiap kali restart.

Target media yang cocok dan edisi berbagi receipt antar sumber. Nama file rilis juga dicek duplikatnya terhadap library dan NZB yang tersimpan. Receipt juga menyimpan grab yang masih menunggu jawaban dari news server, dan ledger menyimpan rilis yang sudah diketahui mati. Jadi restart di tengah masa tunggu tidak membuat grab yang belum dicek dianggap selesai, dan rilis yang mati tidak dikembalikan ke ranking.

Receipt tidak dipercaya begitu saja. Sebelum judul dianggap sudah dimiliki, zurg memeriksa bahwa hal yang menyelesaikannya masih ada: video yang sudah ditaruh di folder Radarr atau Sonarr, atau, untuk wanted DMM, watchlist Plex, atau judul Seerr, rilisnya sendiri ada di library. Kalau sudah dihapus, zurg mencarinya lagi, termasuk saat judulnya masih terdaftar dan job-nya sudah selesai. Rilis yang dihapus dari halaman manage tidak akan diambil lagi.

Setiap NZB yang tersimpan langsung ditulis ke disk. Jumlah percobaan dan waktu coba ulang ditulis dalam satu menit, jadi crash bisa menghilangkan sampai satu menit dari data itu, tapi tidak pernah menghilangkan grab. Penulisan men-flush file sementara, mengganti ledger, lalu men-flush direktori induk jika didukung. NZB yang sudah ditulis sebelum crash tetap dipakai ulang, meskipun penulisan ledger terakhir belum selesai. Setelah akuisisi tercatat, percobaan hapus dari Plex tidak akan mengakuisisi judul itu lagi.

Kegagalan dicoba ulang setelah 5, 10, dan 15 menit, lalu satu jam, lalu enam jam. Setelah itu, judul menunggu setengah dari lamanya ia sudah gagal, jadi jedanya makin panjang: sekitar setengah hari setelah sehari gagal, dua hari setelah empat hari, dan paling lama sekitar seminggu, plus minus seperempat, supaya judul yang gagal bersamaan tidak coba ulang bersamaan. Percobaan yang habis lima menit tanpa menemukan apa-apa juga dihitung sebagai kegagalan.

Percobaan yang tidak menemukan apa-apa saat salah satu indexer kamu tidak bisa ditanya tidak dihitung. Indexer itu minta dibiarkan sampai waktu tertentu, paling lama sehari lagi (`Retry-After`). Judul dicoba lagi setelah waktu itu, dan paling lama sama panjangnya lagi setelahnya, supaya antrean judul tidak menanyai indexer sekaligus. Indexer yang istirahat sepuluh menit berarti percobaan berikutnya dalam dua puluh menit. Ini terjadi paling banyak tiga kali berturut-turut, lalu percobaan dihitung seperti biasa. Indexer yang tidak menyebut waktu, misalnya yang menjawab 410 Gone atau menolak kunci API-nya, tidak ditunggu.

Judul yang sudah gagal selama dua minggu, dengan minimal delapan percobaan, akan **parked**: zurg berhenti menanyai indexer tentang judul itu. Judul tetap tampil di halaman akuisisi sebagai parked, dengan lama gagal dan alasannya, dan log menyebutkannya sekali. **Resume** di halaman itu, untuk satu judul atau untuk semua judul parked dari satu sumber, memulainya lagi dari coba ulang pendek pertama. Sumber yang berhenti mencantumkan judul lalu mencantumkannya lagi sudah meminta ulang, jadi itu juga melanjutkannya.

Grab yang dikonfirmasi news server memulai ulang dua minggu judul itu, jadi musim yang masih menemukan episode tidak akan pernah di-park. Upgrade juga tidak, dari sumber mana pun. Rilis yang lebih baik bisa keluar berbulan-bulan kemudian dan judulnya tetap terdaftar, jadi judul itu tetap mendapat percobaan paling lama seminggu sekali. Begitu juga apa pun di daftar wanted DMM, dengan alasan yang sama: film yang belum rilis, atau film lama yang belum ada yang upload, tetap wanted sampai didapat atau kamu menghapusnya. Hitungan dan tenggat tetap bertahan setelah reboot, termasuk shutdown yang lama.

Antrean yang gagal terus-menerus itu mahal, dengan cara yang tidak terlihat di daftar judul. Di satu instalasi, ribuan judul Radarr dan Sonarr yang tidak ditemukan sama sekali dicoba ulang tiap enam jam tanpa henti. Itu membuat indexer naik dari beberapa ratus kueri sehari menjadi puluhan ribu, dan indexer akhirnya menangguhkan akun. Kebanyakan berupa film tanpa rilis Usenet, dan upgrade yang semua rilisnya yang diizinkan profil sudah ditolak. Permintaan Seerr yang masih terbuka tetap dipantau. Item Plex hanya keluar dari watchlist setelah semua musim yang direncanakan diakuisisi *dan* dicek (NZB dicek ke news server, atau, pada akun `torbox_nzb`, dengan melihat apakah TorBox sudah mengambilnya; torrent dicek dengan sampai ke library dalam keadaan ada yang bisa diputar), hanya jika `remove_after_grab` mengizinkan, dan hanya jika zurg sudah mengambil sesuatu untuk item itu. Fallback episode lepasannya tetap dibatasi pada episode yang ditemukan di hasil indexer.

Sumber yang tidak tersedia menjeda pekerjaannya sendiri. Jika penulisan state gagal, akuisisi lanjutan dijeda sampai penyimpanan berhasil. Ledger yang tidak bisa dibaca atau tidak didukung menjeda akuisisi dan file-nya dibiarkan utuh. Perbaiki atau pulihkan file itu, lalu restart zurg. Layanan zurg lainnya tetap berjalan.

`data/plex-watchlist.json` yang lama diimpor sekali beserta riwayat, percobaan ulang, dan jumlah percobaan yang hanya menunggu penghapusan Plex, semuanya tetap utuh. File aslinya disimpan. Kedua ledger ikut dalam backup normal tanpa `--include-caches`. Pertahankan `data/` dan `nzbs/` saat container diganti.

## Menambahkan adapter lain {#adding-another-adapter}

Implementasikan `acquisition.Source` di package-nya sendiri:

1. `ID()` mengidentifikasi instance tersebut setelah restart.
2. `List(ctx)` mengembalikan snapshot lengkap dari referensi `Item`. Gagalkan snapshot jika terjadi error pagination. Simpan hanya metadata, jangan pernah menyimpan kredensial atau objek user API yang lengkap.
3. `Resolve(ctx, item)` memvalidasi ulang item dan mengembalikan target movie, season, atau episode yang sudah dinormalisasi. `Gone` membatalkan pekerjaan yang tidak diinginkan. `Follow` menjaga request yang masih terbuka tetap dipantau setelah target saat ini didapatkan.
4. `Complete(ctx, item)` menandai acquisition satu kali sebagai selesai. Harus tetap aman jika dipanggil berulang kali setelah crash. Daftar read-only bisa pakai no-op. Engine hanya memanggilnya setelah semua grab di balik item sudah merespons, jadi adapter tidak perlu memeriksa release sendiri. Jangan anggap pemanggilan ini sebagai bukti apa pun selain itu.

Source yang punya quality profile sendiri juga bisa mengimplementasikan `acquisition.Assessor`, yang menilai tiap kandidat release berdasarkan aturannya sendiri. Adapter Radarr dan Sonarr melakukannya lewat parser masing-masing.

Daftarkan tipe konfigurasi dan factory-nya di acquisition service. Queue, persistence, retry, dan executor tidak perlu cabang khusus untuk source tertentu. Trakt, MDBList, dan Simkl bisa cocok dengan kontrak ini, tetapi belum diimplementasikan.
