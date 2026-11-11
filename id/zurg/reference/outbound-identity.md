# Identitas permintaan keluar {#outbound-request-identity}

`user_agent` mengatur User-Agent HTTP bersama yang dipakai untuk API debrid dan pembacaan CDN,
pencarian Newznab, unduhan NZB, OpenSubtitles, probe ffprobe, integrasi media-server,
unduhan dependensi, update, dan ekspor berbagi/log (opsional).
Defaultnya adalah agent browser generik. Kalau dikosongkan, nilai default akan kembali. Nilai kustom yang kamu isi sendiri dikirim persis seperti yang kamu ketik, meskipun nilai itu mengidentifikasi aplikasinya.
`omit_user_agent: true` menekan header User-Agent dari klien HTTP Go dan memberi ffprobe agent yang kosong, sehingga menimpa string yang sudah dikonfigurasi. Beberapa layanan mungkin menolak permintaan tanpa agent. GitHub menolak semuanya dengan 403, jadi permintaan ke GitHub (`zurg update` serta unduhan rclone dan ffprobe) tetap membawa agent yang dikonfigurasi, atau agent browser generik kalau tidak ada yang diatur.

Plex, Jellyfin, dan Emby juga memerlukan metadata klien/perangkat. Atur dengan `outbound_client_name`, `outbound_client_id`, `outbound_client_version`, `outbound_device_name`, `outbound_device_id`, dan `outbound_platform`. Defaultnya masing-masing adalah `Media Client`, `media-client`, `1.0`, `Media Client`, `media-client`, dan `Desktop`. Plex memakai client ID untuk autentikasi, pemindaian, dan permintaan metadata; Jellyfin/Emby memakai device ID di metadata autentikasi mereka. Kolom-kolom ini hanya dipakai kalau protokolnya mendukungnya. Mengubah ID bisa membuat klien/perangkat tampil berbeda di media server.

Semua pengaturan ini tersedia di bagian Network & Connectivity pada dashboard. Dashboard menampilkan nilai yang tersimpan dengan default yang sudah diterapkan. Restart akan menerapkan semua pengaturan sekaligus; menyimpan saja tidak mengubah identitas yang sedang berjalan. Nilainya harus berupa printable ASCII, maksimal 2048 karakter; kolom klien/perangkat tidak boleh berisi tanda kutip atau backslash. Token autentikasi dan nama header protokol tetap tidak berubah, termasuk kredensial `X-Zurg-Token` yang wajib dipakai DMM.

Klien provider/indexer menghapus header `Referer`, `Origin`, dan `X-Zurg*` sebelum mengirim permintaan, termasuk saat redirect. Redirect tidak bisa membocorkan path privat atau parameter query API-key dari URL sebelumnya lewat Referer. Autentikasi, permintaan range, cookie provider, dan batas redirect tetap berjalan seperti biasa. Tidak ada ID klien/perangkat aplikasi yang ditambahkan ke permintaan ini.

NNTP mengirim `AUTHINFO USER`, `AUTHINFO PASS`, `BODY`, `STAT`, `DATE`, dan `QUIT` sesuai kebutuhan, tanpa perintah identifikasi software. Tidak ada ID software NNTP yang perlu diatur. Username/password tetap ada di konfigurasi NNTP masing-masing provider. Tes transkrip TLS dan plaintext mencakup autentikasi, akses artikel, keep-alive, dan shutdown.

Ini hanya meminimalkan identitas aplikasi yang eksplisit; ini tidak memberikan anonimitas. Layanan remote tetap bisa melihat kredensial, IP sumber, konten yang diminta, dan waktunya. Perilaku TLS/HTTP, identitas kustom, API key yang didaftarkan aplikasi, dan pola akses (termasuk link tes jaringan Real-Debrid) tetap bisa dipakai untuk mengorelasikan data. URL dari luar, metadata torrent, ID artikel, payload berbagi, dan isi log/konfigurasi yang diekspor tidak ditulis ulang. URL unduhan software mengidentifikasi software yang diminta. Pemutar eksternal dan alat yang dijalankan terpisah memakai pengaturannya sendiri.

Tes regresi tingkat socket mencakup default, agent kustom dan yang dihilangkan, redirect, autentikasi yang tetap terjaga, serta metadata media-server. Tes config/dashboard mencakup validasi, round trip YAML, dan penerapan pengaturan saat restart.
