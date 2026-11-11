# Regresi timeout stream proxy {#proxied-stream-timeout-regression}

## Ringkasan {#summary}

zurg memakai `download_timeout_secs` sebagai batas waktu total (wall-clock) untuk unduhan HTTP yang di-proxy. Nilai defaultnya 15 detik, jadi setiap respons upstream yang butuh lebih dari 15 detik untuk selesai akan terputus, padahal data masih terus masuk dengan normal.

Bug ini dilaporkan di Discord pada 2026-08-21 untuk `2026.08.21.0151-nightly` (`fc2a21f`). Permintaan range 2 GB yang diulang lewat zurg berakhir pada detik ke-15.001 setelah mengirim sekitar 1.26 GB dengan kecepatan 84 MB/s. Range yang sama berhasil diunduh langsung dari Real-Debrid, dan saat `download_timeout_secs` dinaikkan ke 3600, permintaan lewat zurg selesai dalam 25.8 detik.

Ini adalah regresi di zurg, bukan karena pemfilteran konten, kegagalan CDN, atau regresi di `fc2a21f`. Commit `6edeaa8c` (`Optimize client`, 2024-11-17) yang memperkenalkannya. Jalur penyajian proxy biasa sudah diperbaiki di `41db7245`, lalu `eff972b8` membuat kesalahan yang sama lebih sulit terulang lagi di batas API provider.

## Dampak bagi pengguna {#user-impact}

Path yang kena masalah adalah setiap response body yang di-proxy zurg dari debrid provider berbasis HTTP dan tetap terbuka lebih lama dari `download_timeout_secs`. Real-Debrid kena dari November 2024. TorBox dan AllDebrid ikut punya perilaku yang sama saat provider tersebut ditambahkan. Pembacaan NZB yang dilayani secara lokal tidak pernah lewat HTTP download client, jadi tidak kena.

Gejala yang terlihat oleh user:

- Infuse atau WebDAV client langsung lain freeze saat playback;
- playback gagal setelah seek membuka ranged request baru;
- download berhenti lebih awal padahal sudah menerima HTTP `206 Partial Content`; dan
- error di client yang kelihatannya menyalahkan file media atau CDN, padahal request langsung berjalan normal.

Player tidak selalu gagal tepat 15 detik setelah playback mulai. Dengan kecepatan 84 MB/s yang dilaporkan, zurg sudah mentransfer sekitar 1,26 GB sebelum deadline. Player bisa menghabiskan buffer itu selama beberapa menit sebelum kehabisan data, jadi cutoff jaringan yang tepat 15 detik terlihat seperti freeze playback yang acak.

## Penyebab utama {#root-cause}

`http.Client.Timeout` di Go adalah batas waktu untuk seluruh siklus request. Ini bukan timeout jika koneksi diam atau macet. Timer mulai saat request dimulai dan terus berjalan selama response body dibaca, terlepas dari apakah data masih mengalir atau tidak.

Sebelum `6edeaa8c`, download client sendiri tidak punya timeout untuk seluruh request:

```go
client: &http.Client{}
```

`download_timeout_secs` membatasi fase koneksi dan response header lewat dialer transport dan `ResponseHeaderTimeout`. Setelah response body datang, serving path bisa terus membaca selama client di sisi hilir membutuhkannya.

`6edeaa8c` merapikan transport HTTP dan menambahkan timeout dari konfigurasi ke client itu sendiri, sambil menghapus `ResponseHeaderTimeout`:

```go
client.client = &http.Client{
    Transport: transport,
    Timeout:   time.Duration(timeoutSecs) * time.Second,
}
```

Itu mengubah arti nilai 15 detik yang sudah ada. Nilai itu tetap melindungi fase koneksi, tapi sekarang juga memberi batas waktu mutlak untuk response body. Serving path sudah mengambil media lewat client ini, jadi regresinya langsung terasa begitu perubahan ini masuk.

Kegagalannya tidak berisik. zurg mengirim status dan header upstream yang sukses sebelum menyalin body ke player. Saat deadline client memotong body, operasi copy mengembalikan error, tapi serving path membuang error itu:

```go
n, _ = copyBuffered(resp, body)
```

Pada saat itu response `206` sudah terkirim dan tidak bisa diganti dengan status error. Dengan request logging dimatikan, tidak ada yang mencatat kenapa body-nya terpotong. Akibatnya, client di sisi hilir menerima response partial-content yang terlihat sukses, padahal body-nya berakhir sebelum panjang yang dijanjikan tercapai.

## Riwayat regresi {#regression-history}

| Tanggal | Commit | Efek |
|---|---|---|
| 2024-06-28 | `c3aea427` | Memindahkan pembacaan serving yang sudah ada ke `DownloadFile`. Ini tidak mengubah perilaku karena download client saat itu belum punya timeout untuk seluruh request. |
| 2024-11-17 | `6edeaa8c` | Menambahkan `http.Client.Timeout` ke download client. Ini adalah regresi yang mulai memotong body proxy yang biasa. |
| 2026-02-26 | `dea98d34` | Dengan benar mendiagnosis batas 15 detik yang sama untuk pembacaan arsip RAR, menambahkan streaming client tanpa timeout, dan hanya memindahkan jalur RAR ke sana. Serving file biasa tetap memakai `DownloadFile`. |
| 2026-08-02 | `e9318e66` | Memindahkan download ke interface `debrid.Provider` yang mendukung banyak provider, dan memindahkan panggilan serving biasa apa adanya. Ini tidak membuat bug Real-Debrid, tapi provider HTTP baru ikut mewarisi method yang tidak aman. |
| 2026-08-21 | `fc2a21f` | Nightly yang dipakai di laporan. Nightly ini memang berisi bug-nya, tapi bukan yang memperkenalkannya. |
| 2026-08-21 | `41db7245` | Mengubah playback proxy biasa agar memakai `DownloadFileStreaming`, dan menambahkan regression test end-to-end pertama untuk timeout. |
| 2026-08-21 | `eff972b8` | Membuat `DownloadFile` setiap HTTP provider tanpa timeout sebagai pengaman struktural, dan memperluas cakupan test ke Real-Debrid, AllDebrid, TorBox, serta sebuah NZB sebagai kontrol. |

Near miss yang penting adalah fix RAR di bulan Februari. Pesan commit-nya secara eksplisit menyebutkan bahwa `http.Client.Timeout` mencakup body, dan bahwa default 15 detik itu yang mematikan stream RAR. Diagnosisnya benar, tapi fix-nya hanya dibatasi ke reader RAR. Dengan memisahkan method `DownloadFile` dan `DownloadFileStreaming`, jalur serving biasa tetap memakai pilihan yang tidak aman itu selama enam bulan lagi.

## Mengapa tidak terdeteksi {#why-it-stayed-hidden}

Beberapa hal membuat regresi ini tersembunyi selama sekitar 21 bulan:

1. Sebagian besar deployment media server membaca zurg lewat rclone, bukan WebDAV langsung. rclone memakai request range yang dibatasi ukurannya. Default managed mount saat ini mulai dari 4 MB dan naik sampai batas 512 MB, jadi di koneksi cepat banyak request upstream individual selesai dalam 15 detik. Ini mengurangi paparan masalahnya, tetapi tidak membuat jalurnya aman, terutama di koneksi yang lebih lambat.
2. Client WebDAV langsung seperti Infuse bisa meminta range yang besar atau terbuka. Request seperti itu membuat satu response upstream tetap hidup cukup lama sampai pasti kena deadline, dan itulah sebabnya reproduksi di Discord bisa dipastikan muncul persis di tiga offset berbeda.
3. Buffering playback membuat penyebab dan gejala tampak terpisah. Request upstream mati di detik ke-15, tetapi playback baru berhenti setelah player menghabiskan byte yang sudah terkirim. Jeda yang terlihat berubah-ubah tergantung bitrate, buffering, dan seek.
4. Response-nya tampak sukses. CDN mengembalikan `206` yang valid, zurg meneruskannya, dan error saat menyalin body diabaikan setelah header sudah terkirim. Tes langsung ke CDN tetap sehat, dan log biasa tidak berisi error timeout.
5. Menaikkan setting terlihat seperti solusi. Itu membuat defect tampak seperti nilai tuning yang terlalu kecil, padahal sebenarnya ini timeout yang dipasang di abstraksi yang salah.
6. Tes yang ada memakai body atau range yang selesai dalam batas timeout yang dikonfigurasi. Tidak ada tes yang sengaja membiarkan body response terus mengalir melewati deadline lalu memeriksa panjang lengkap dan checksum lewat jalur serving.
7. Perbaikan RAR yang sempit menghilangkan manifestasi paling jelas dari sebelumnya, tetapi tidak menghilangkan default yang tidak aman untuk download biasa.

## Mengapa timeout yang lebih tinggi terlihat memperbaikinya {#why-a-higher-timeout-appeared-to-fix-it}

Mengubah setting menjadi 3600 detik tidak mengubah apa yang dicakup oleh timeout tersebut. Setting itu hanya memindahkan batas waktu total cukup jauh agar transfer 25.8 detik yang dilaporkan bisa selesai:

```text
15 seconds   < 25.8-second transfer < 3600 seconds
```

Ini cuma workaround, bukan perbaikan yang aman. Timeout total untuk satu request yang terbatas tetap bisa memotong body yang cukup panjang, misalnya kalau client-nya lambat atau koneksinya dijeda. Setting ini juga dipakai untuk dial timeout download client dan request verifikasi yang dibatasi, jadi kalau dinaikkan sampai satu jam, host yang tidak bisa dijangkau bisa butuh waktu jauh lebih lama untuk dinyatakan gagal. Build yang sudah diperbaiki sebaiknya memakai nilai konfigurasi normal. Nilai itu tidak lagi membatasi body media yang di-proxy.

## Perbaikan dan pengaman {#fix-and-guardrails}

Perbaikan sementara di `41db7245` mengubah `streamFileToResponse` supaya mengambil data lewat `Provider.DownloadFileStreaming`. Client ini memakai transport yang sama, tapi tidak punya `http.Client.Timeout`, jadi umur body tidak lagi terikat ke `download_timeout_secs`. Request tetap memakai context dari request downstream, jadi saat pemutar diputus, pembacaan dari upstream ikut dibatalkan. Pembuatan koneksi dan TLS handshake tetap dibatasi oleh transport.

Lalu `eff972b8` menghapus ketergantungan pada pemanggil yang harus memilih method dengan nama yang mengandung "Streaming":

- `DownloadFile` milik Real-Debrid sekarang memakai `DoStreaming`.
- Helper bersama `debrid.DownloadRanged` menerima `StreamingDoer`, yang hanya mengekspos `DoStreaming`; AllDebrid dan TorBox memakai helper ini.
- Dengan begitu, kedua method download provider aman untuk response body yang panjang.
- Pembacaan terbatas yang bukan untuk playback, misalnya dua pembacaan 64 KiB untuk hash OpenSubtitles, sekarang diberi deadline context sendiri, bukan meminjam body timeout di level client yang tidak aman.

Regression test di `internal/universal/stream_timeout_test.go` memakai server lokal yang mengirim body 1.6 MB dalam 16 chunk selama sekitar 1.6 detik, padahal timeout yang dikonfigurasi satu detik. Test memastikan panjang dan checksum-nya sama persis:

- langsung lewat kedua method download provider untuk Real-Debrid, AllDebrid, dan TorBox;
- end to end lewat `streamFileToResponse` untuk ketiga provider berbasis HTTP; dan
- lewat provider lokal berbentuk NZB sebagai kontrol yang tidak terdampak.

Aturannya sekarang eksplisit: method yang mengembalikan body download tidak boleh pernah memakai timeout untuk seluruh request. Probe singkat dan pembacaan metadata sebaiknya membawa deadline di context-nya sendiri; body streaming harus tetap hidup sampai selesai, dibatalkan dari downstream, atau sampai ada error transport yang sebenarnya.

## Dibatasi oleh progres, bukan oleh waktu {#bounded-by-progress-not-by-time}

Membiarkan sampai selesai hanya menyisakan satu cara agar sebuah read tidak pernah berakhir: sebuah node pengiriman yang terus membuka response tapi berhenti mengirim isinya, atau tidak pernah menjawab sama sekali. Pada September 2026, scan Plex menggantung selama sebelas jam pada satu file Real-Debrid yang read-nya tidak pernah gagal. Client ini tidak punya batas waktu untuk menyerah, dan `--timeout` rclone adalah batas idle: zurg meneruskan body dalam penulisan 256 KiB, jadi node yang mengirim 256 KiB setiap lima menit, di bawah 1 KB/s, akan mereset timeout itu selamanya. Node yang lebih lambat memang memicunya, tapi rclone lalu mengirim request yang sama ke node yang sama, dan mencatat satu error setiap tiga timeout. Diukur di zen dengan rclone 1.75 dan flag mount-nya sendiri pada 2026-10-03, reader pada node seperti itu masih terblokir setelah 30 menit.

`internal/universal/starved_read.go` sekarang memutus proxied read begitu node telah mengirim kurang dari 1 MiB selama 30 detik yang dihabiskan zurg untuk menunggu node tersebut. Hanya waktu menunggu node yang dihitung: dari saat request mendapat koneksi sampai header-nya tiba, dan waktu di dalam setiap read body. Waktu yang dipakai untuk menulis ke client tidak dihitung, jadi properti di atas tetap berlaku dan client yang lambat atau dijeda bisa menjaga stream tetap terbuka selama yang dia mau. File yang dipotong dijawab dengan `503` selama dua menit agar retry rclone langsung berakhir, alih-alih masing-masing menunggu habis satu jendela lagi. Read NZB yang dilayani secara lokal tidak diawasi.

Read file di dalam archive tidak pernah sampai ke `streamFileToResponse`, jadi mereka tidak termasuk batas itu sampai kartu 204. Byte-nya berasal dari span tiap volume, diambil lewat client yang sama oleh `providerDoer.Do` dan dibaca oleh parser RAR, dan node bisa menahan salah satu dari itu selama dia mau menjaga koneksi. Setiap fetch volume sekarang diawasi oleh batas yang sama, entry ditolak selama dua menit ketika salah satunya dipotong, dan pemotongan saat archive sedang di-list akan menggagalkan listing alih-alih membiarkan parser meninggalkan volume itu sebagai rusak, yang pada set lima volume sungguhan menyajikan panjang penuh entry dengan byte yang salah setelah volume kedua.

Kartu 222 menemukan hal yang sama di balik setiap cara lain node bisa menggagalkan read volume: 5xx, 429, koneksi yang putus di tengah header. Parser menganggap masing-masing sebagai volume rusak dan men-list archive tanpa volume itu, dan listing itu di-cache, jadi pada set yang sama 503 pada volume 3 menyajikan byte yang salah mulai dari offset 16,057 dan terus menyajikannya setelah node pulih. Parser sekarang membedakan volume yang byte-nya tidak bisa di-parse dari volume yang byte-nya tidak pernah datang (`rarstream.ErrVolumeUnavailable`, ditandai oleh `HTTPSrc` untuk status yang dilihatnya, oleh `providerDoer` untuk semua yang gagal pada remote read, dan oleh body NZB untuk apa yang dikelas reader-nya sebagai transport). Yang kedua menggagalkan listing, termasuk set bersarang dan pengelompokan volume-head, dan kegagalannya dijawab `503` dengan `Retry-After`, tidak pernah di-cache sebagai kegagalan archive, tidak pernah dicatat sebagai verdict, dan tidak pernah dijawab pada browse dengan volume mentah menggantikan isi archive. Volume yang rusak atau tidak ada tetap di-list di sekitarnya seperti sebelumnya.

Penulisan 256 KiB yang disebut di atas juga dihapus di kartu 204. Copy tetap mengisi buffer-nya selagi node cepat, jadi body cepat tetap keluar dalam buffer penuh seperti sebelumnya, tapi byte pertama dikirim begitu tiba dan tidak pernah ditahan lebih dari 250 ms (`defaultCopyFlushAfter` di `internal/universal/downloader.go`), sambil men-flush response bersama byte itu. Node yang lambat tidak lagi menahan client dari header-nya. Sebelumnya, di zen lewat rclone dan flag mount-nya sendiri, entry archive pada node yang mengirim 64 KiB lalu 16 KiB setiap empat menit tidak pernah mengirim apa pun ke rclone ketika rclone menyerah tepat pada lima menit, tiga kali berturut-turut: semua yang sudah dikirim node masih ada di buffer.
