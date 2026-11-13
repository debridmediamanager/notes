# rex dengan aplikasi Anda sendiri {#rex-with-your-own-app}

[rex](https://rex.debridmediamanager.com/id/) adalah media server untuk aplikasi resmi Plex yang tidak memiliki file apa pun. Aplikasi resmi Plex melihatnya sebagai server Plex biasa. Program lain, yang di halaman ini disebut **aplikasi kamu**, memberi tahu rex apa saja yang ada di library kamu dan menyajikan file-filenya. Saat kamu menekan play, rex men-stream file langsung dari aplikasi kamu. Tidak ada yang diunduh terlebih dahulu.

Halaman ini memandu kamu dari nol sampai bisa memutar sebuah film, step demi step. Halaman ini tidak mengasumsikan aplikasi tertentu. Halaman ini menjelaskan dengan tepat apa yang dibutuhkan rex dari sebuah aplikasi, jadi kamu bisa mengecek apakah aplikasimu sudah melakukannya, atau membuat aplikasi sendiri. Setiap step menjelaskan apa fungsinya, mengapa itu penting, dan apa yang seharusnya kamu lihat sebelum lanjut ke step berikutnya.

Ada empat hal yang perlu kamu ketahui sebelum mulai:

- **Aplikasi kamu yang menyajikan file.** rex mengambil setiap byte dari aplikasimu lewat HTTP atau HTTPS, seperti browser mengunduh sebuah file. rex tidak menyimpan file dan tidak butuh disk atau mount untuk media.
- **Aplikasi kamu memberi tahu rex apa yang dimilikinya.** Aplikasi mengirim daftar file ke rex lewat feed API milik rex, dan setiap perubahan setelahnya. rex tidak pernah membaca isi folder atau memindai apa pun.
- **Aplikasi kamu menentukan apa itu setiap file.** Aplikasi menyatakan apakah sebuah file itu film atau episode, judul mana yang dimilikinya (berdasarkan id IMDb dan TMDB) dan, untuk episode, season dan nomornya. rex tidak pernah menebak dari nama file.
- **Plex yang mendeskripsikannya.** Setelah rex terhubung ke akun Plex, rex menampilkan setiap judul dengan nama, poster, ringkasan, dan nama episode dari metadata Plex sendiri untuk id tersebut. Untuk hal-hal yang tidak dikenal agent Plex mana pun, aplikasi kamu sendiri yang memberi nama: lihat [Membangun addon rex](addons.md).

rex gratis untuk penggunaan pribadi (PolyForm Noncommercial): tidak ada tier sponsor dan tidak perlu akun untuk mengunduhnya. Lihat [rex.debridmediamanager.com](https://rex.debridmediamanager.com/id/). Hanya punya HP atau TV box? [rex untuk Android](android.md) menjalankan rex dan addon-addonnya di perangkat itu. Untuk sponsor, [zurg+rex](../zurg/guides/android.md), sebuah server Plex di HP kamu, juga menghubungkan library debrid dan Usenet kamu ke rex.

## Sebelum kamu mulai {#before-you-start}

| Yang kamu butuhkan | Alasannya |
|---|---|
| Nightly rex bertanggal 2026.10.25 atau yang lebih baru | Langkah 1 mengunduh yang paling baru |
| Mesin yang selalu menyala: Linux (Ubuntu 22.04 atau yang lebih baru), macOS, atau Windows (64 bit) | rex adalah server: aplikasi Plex kamu menghubunginya setiap kali kamu menekan play. Jika perintahnya berbeda, sebuah langkah punya tab untuk tiap sistem. [Docker](#run-rex-in-docker) ada di bagian bawah, untuk Linux |
| RAM 1 GB | Dengan 4,062 film dan 656 serial (34,678 episode), rex memakai kurang dari 500 MB saat mulai dan sekitar 730 MB saat perpustakaan dijelajahi. Mengonversi video memakai lebih banyak, plus core atau chip grafis yang lebih banyak |
| Aplikasi yang melakukan apa yang tercantum di [Yang harus dilakukan aplikasi kamu](#what-your-app-must-do) | Dari situlah perpustakaan kamu berasal |
| Aplikasi kamu mengirim dari mesin ini, jaringan rumahmu, atau Tailscale | rex hanya menerima feed dari sana ([Jaga port tetap privat](#keep-the-port-private)). Aplikasi di seedbox atau server cloud tidak bisa mengirim ke rex kecuali server itu ada di tailnet kamu; file-nya sendiri bisa dilayani dari mana saja yang bisa dijangkau rex |
| File ada di disk mesin ini? Sesuatu yang melayaninya lewat HTTP dan mengirimkannya | rex tidak pernah membaca disk. [Langkah 2](#step-2-see-it-work-by-hand) melakukannya secara manual untuk satu file; selain itu, tetap pakai Plex untuk file tersebut |
| Usenet? Sumber yang membacanya, misalnya zurg | rex tidak pernah berbicara dengan penyedia Usenet. zurg adalah sumber yang melakukannya: lihat [rex dengan zurg](with-zurg.md) |
| Akun Plex baru, khusus untuk rex | rex mendapatkan setiap judul, poster, ringkasan, dan nama episode dari Plex setelah ditambahkan ke [akun Plex](#step-3-add-it-to-a-plex-account). Sampai saat itu, judul tetap memakai nama file dan tidak punya poster |

## Apa yang harus dilakukan aplikasi Anda {#what-your-app-must-do}

Berikan daftar ini ke pembuat aplikasimu. Referensi API rex ada di [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

| Aplikasimu harus | Caranya | Kalau tidak |
|---|---|---|
| Sajikan setiap file lewat HTTP | `GET <address>/<path>` mengembalikan file-nya. Permintaan `Range` membuat seeking cepat; redirect diikuti. Basic auth atau bearer token diperbolehkan | Tidak ada yang bisa diputar: rex mencatat 502 |
| Daftarkan ke rex | `PUT /rex/sources/<name>` (huruf, angka, `-` dan `_`) dengan `{"url": ...}` dan, jika punya login, `"user"` dan `"password"` atau `"bearer"`, jangan pernah di dalam url. Ulangi setiap kali aplikasi mulai | rex tidak punya tempat untuk membaca |
| Kirim semua file yang dimiliki | `POST /rex/feed/<name>/items`, beberapa ratus file per permintaan | rex tetap kosong |
| Kirim output ffprobe tiap file | JSON `-show_format -show_streams` dari ffprobe, utuh, sebagai `media_info` | File akan **ditahan**: disimpan tapi tidak ditampilkan, karena aplikasi Plex menolak memutar file tanpa itu |
| Beri tahu jenis tiap file | `kind` (`movie`, `episode` atau `extra`) dan `ids`: `imdb` atau `tmdb` milik film atau **serial**-nya (salah satu saja sudah cukup), jangan pernah milik episode. Untuk episode, `season` dan `episode` ditaruh di item itu sendiri (di samping `kind`, bukan di dalam `ids`), sesuai penomoran TMDB; `episode_end` untuk file yang berisi beberapa episode | File tidak akan cocok: film dijadikan judul sesuai nama file, episode di serial yang dinamai sesuai rilis, dan nomornya mengikuti urutan file |
| Pakai `id` yang sama untuk sebuah file selamanya | Meski file-nya diganti nama | File yang diganti nama jadi judul baru dan riwayat tontonannya hilang |
| Kirim perubahan saat terjadi | `POST` yang sama untuk file baru atau yang berubah, `DELETE /rex/feed/<name>/items` untuk file yang dihapus | Pustakaan jadi basi |
| Kirim seluruh pustaka sesekali | `PUT /rex/feed/<name>/snapshot`. rex menghapus apa pun yang tidak disebut dalam snapshot | File yang sudah tidak dilacak aplikasimu tetap ada di rex |
| Terima `DELETE` WebDAV untuk sebuah file | Saat seseorang menghapus judul di aplikasi Plex, rex akan meminta aplikasimu menghapus file-nya dulu | Judulnya tetap ada dan aplikasi Plex memberi tahu bahwa judul itu tidak bisa dihapus |

## Langkah 1. Pasang rex {#step-1-install-rex}

**Apa yang dilakukannya.** Mengunduh rex ke `~/rex` (`$HOME\rex` di Windows) dan menjalankannya sebagai service, lengkap dengan semua yang dibutuhkan langkah-langkah berikutnya. Langkah setelah ini tidak perlu restart; hanya bagian opsional di bawah yang perlu.

**Kenapa ini penting.** rex adalah yang diajak bicara oleh aplikasi Plex kamu. Saat pertama kali dijalankan, rex membuat `rex.db`, yang menyimpan library kamu, semua yang dikirim aplikasimu, dan riwayat tontonanmu.

Di Linux kamu juga bisa menjalankan image Docker rex: lihat [Jalankan rex di Docker](#run-rex-in-docker).

+++ Linux and macOS
```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(curl -fsSL 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1' | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
P=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL "https://github.com/debridmediamanager/rex/releases/download/$TAG/rex-$TAG-$P.tar.gz" | tar xz --strip-components=1
```
+++ Windows
Di PowerShell:

```powershell
New-Item -ItemType Directory -Force $HOME\rex | Out-Null; cd $HOME\rex
$tag = (Invoke-RestMethod 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1')[0].tag_name
curl.exe -fLO "https://github.com/debridmediamanager/rex/releases/download/$tag/rex-$tag-windows-amd64.zip"
tar -xf "rex-$tag-windows-amd64.zip" --strip-components=1; Remove-Item "rex-$tag-windows-amd64.zip"
```
+++

Ini mengambil build rex terbaru, biasanya nightly, untuk mesinmu.

Cari LAN IP rex, yaitu alamatnya di jaringan rumahmu. Di Linux `hostname -I` menampilkan beberapa alamat: pilih yang ada di jaringan rumahmu, bukan yang diawali `172.17.` (Docker) atau `100.` (Tailscale). Di macOS `ipconfig getifaddr en0` menampilkannya (`en1` jika yang itu kosong). Di Windows `ipconfig` menampilkannya sebagai **IPv4 Address** di bawah adapter Wi-Fi atau Ethernet kamu. **Halaman ini menulisnya sebagai `192.168.1.20` di mana-mana: ganti dengan alamatmu.** Aplikasi Plex, aplikasimu, dan perintah-perintahmu sendiri akan menghubungi rex di alamat itu.

**Plex Media Server berjalan di mesin yang sama?** Akhiri perintah start rex di bawah dengan `--port 32500`, dan pakai `32500` di mana pun perintah atau pengaturan menulis `32400`, termasuk aturan firewall Windows. Alasannya, Plex sudah memakai port 32400 dan port yang dipakai aplikasi untuk menemukan server. Di port lain, rex tidak akan mengganggu itu. Aplikasi Plex kamu lalu menampilkan dua server dengan nama mesinnya: rex adalah yang dibagikan ke kamu, dengan nama akun baru di sebelahnya. Setelah rex masuk ke akun Plex-nya ([langkah 3](#step-3-add-it-to-a-plex-account)), kamu bisa mengganti namanya: login ke Plex sebagai akun itu, buka **Settings** milik rex, **General**, ubah **Friendly name** lalu simpan, kemudian restart rex seperti di bawah. Aplikasi Plex akan menampilkannya dengan nama baru setelah restart.

Sekarang jadikan ini sebuah service:

+++ Linux
Buat `~/.config/systemd/user/rex.service`:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rex
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
sudo loginctl enable-linger "$USER"
journalctl --user -u rex -f
```

**Perintah start** rex ada di baris `ExecStart`, dan kuncinya masuk ke `~/rex/rex.env`, satu `NAME=value` per baris. Setelah perubahan, `systemctl --user daemon-reload && systemctl --user restart rex` me-restart rex. `journalctl --user -u rex -f` menampilkan log-nya. `loginctl enable-linger` membuat rex tetap berjalan saat kamu log out.
+++ macOS
`run.sh` menjalankan rex di foldernya, dan LaunchAgent menjalankan `run.sh` saat kamu log in:

```bash
cp ~/rex/examples/run.sh.example ~/rex/run.sh
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.rex.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rex</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/rex/run.sh</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/rex/rex.log</string>
  <key>StandardErrorPath</key><string>$HOME/rex/rex.log</string>
</dict></plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.rex.plist
tail -F ~/rex/rex.log
```

**Perintah start** rex ada di baris terakhir `~/rex/run.sh`, dan kuncinya masuk ke `~/rex/rex.env`, satu `NAME=value` per baris. Setelah perubahan, `launchctl kickstart -k gui/$(id -u)/com.rex` me-restart rex. `tail -f ~/rex/rex.log` menampilkan log-nya.

rex berjalan selama kamu login di Mac. Untuk Mac yang restart sendiri, nyalakan automatic login (**System Settings**, **Users & Groups**). Jika macOS firewall aktif, izinkan rex saat macOS menanyakannya, atau tambahkan `~/rex/rex` di **Options** firewall.
+++ Windows
Buka PowerShell **sebagai administrator** dan masuk ke folder rex dengan `cd $HOME\rex`. Pertama buat `run.cmd`, yang menjalankan rex di foldernya dan menulis log-nya ke `rex.log`. Notepad akan menawarkan untuk membuat file-nya:

```powershell
notepad run.cmd
```

```bat
@echo off
cd /d "%~dp0"
rex.exe 2>> rex.log
```

Simpan. Lalu izinkan jaringanmu lewat Windows Firewall ke port rex dan dua port discovery, dan jalankan rex sekarang serta setiap kali kamu log in:

```powershell
New-NetFirewallRule -DisplayName rex -Protocol TCP -LocalPort 32400
New-NetFirewallRule -DisplayName "rex discovery" -Protocol UDP -LocalPort 32410,32414
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask rex -Action (New-ScheduledTaskAction -Execute "$HOME\rex\run.cmd") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Settings $settings
Start-ScheduledTask rex; Start-Sleep 3
Get-Content rex.log -Wait
```

**Perintah start** rex ada di baris `rex.exe` di `run.cmd`, dan kuncinya ditulis di atasnya, satu `set NAME=value` per baris. Setelah perubahan, `Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex` me-restart rex. `Get-Content $HOME\rex\rex.log -Wait` menampilkan log-nya.

Jalankan rex secara manual di PowerShell? Maka log-nya hanya ada di jendela itu, tanpa `rex.log`, dan tidak ada task yang menjalankannya setelah reboot. rex menyimpan database dan klaimnya di folder tempat ia dijalankan, jadi rex yang dijalankan dari folder lain akan menjadi server baru yang belum diklaim. Hentikan dengan Ctrl+C, lalu jalankan lagi dari folder rex dengan flag yang sama, atau lebih baik, atur task di atas.

rex berjalan selama kamu login di Windows, di jendelanya sendiri: biarkan terbuka. Di PowerShell, ketik `curl.exe` di mana pun halaman ini menulis `curl`: `curl` bawaan Windows PowerShell adalah perintah yang berbeda.
+++

**Yang harus kamu lihat.** Di antara baris-baris pertama:

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
INFO    no source yet: a source registers itself once pointed at this server (PUT /rex/sources/{name}, docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://192.168.1.20:32400  machine=...  items=0  parts=proxy
```

rex memberi nama dirinya sesuai nama mesin; aplikasi Plex kamu menampilkan nama itu. `no source yet` itu wajar: belum ada aplikasi yang mendaftar. Biarkan log tetap terbuka.

## Langkah 2. Lihat cara kerjanya secara manual {#step-2-see-it-work-by-hand}

**Apa yang dilakukannya.** Berperan sebagai aplikasi kamu untuk satu film, dengan file server sementara dan dua perintah `curl`.

**Kenapa penting.** Langkah ini membuktikan rex berjalan di mesin ini sebelum aplikasimu ikut terlibat. Kalau langkah ini berhasil tapi aplikasimu tidak, berarti masalahnya ada di aplikasimu. Lewati langkah ini kalau aplikasimu sudah diatur.

Kamu butuh `ffprobe`, web server kecil, dan satu file video. Kamu mendaftarkan folder file itu ke rex dengan nama `test`, lalu mengirim file ke rex dan memberitahu bahwa itu film Sintel (IMDb `tt1727587`, TMDB `45745`) beserta output dari ffprobe.

+++ Linux and macOS
Pasang `ffprobe` dan `jq` (`sudo apt install -y ffmpeg jq` di Linux, `brew install ffmpeg jq` di macOS). Taruh file di tempat web server kecil bisa menyajikannya:

```bash
mkdir -p ~/rex-test/movies/Sintel.2010
cp /path/to/any-video.mkv ~/rex-test/movies/Sintel.2010/Sintel.2010.mkv
cd ~/rex-test
python3 -m http.server 8099 --bind 127.0.0.1 &
```

Daftarkan ke rex:

```bash
curl -s -X PUT http://192.168.1.20:32400/rex/sources/test \
  -H 'Content-Type: application/json' -d '{"url": "http://127.0.0.1:8099"}'
```

Kirim file ke rex:

```bash
P=movies/Sintel.2010/Sintel.2010.mkv
jq -n --arg p "$P" \
  --argjson probe "$(ffprobe -v quiet -print_format json -show_format -show_streams "$P")" \
  '{items: [{id: $p, path: $p, kind: "movie", ids: {imdb: "tt1727587", tmdb: 45745}, media_info: $probe}]}' \
| curl -s -X POST http://192.168.1.20:32400/rex/feed/test/items \
    -H 'Content-Type: application/json' --data-binary @-
```
+++ Windows
Pasang `ffprobe` dan Python dengan `winget install Gyan.FFmpeg` dan `winget install Python.Python.3.13`, lalu buka jendela PowerShell baru. Taruh file di tempat web server kecil bisa menyajikannya:

```powershell
New-Item -ItemType Directory -Force $HOME\rex-test\movies\Sintel.2010 | Out-Null
Copy-Item C:\path\to\any-video.mkv $HOME\rex-test\movies\Sintel.2010\Sintel.2010.mkv
cd $HOME\rex-test
$server = Start-Process py '-m http.server 8099 --bind 127.0.0.1' -WindowStyle Hidden -PassThru
```

Daftarkan ke rex:

```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/test -ContentType application/json -Body '{"url": "http://127.0.0.1:8099"}'
```

Kirim file ke rex:

```powershell
$p = 'movies/Sintel.2010/Sintel.2010.mkv'
$probe = ffprobe -v quiet -print_format json -show_format -show_streams $p | Out-String | ConvertFrom-Json
$item = @{ id = $p; path = $p; kind = 'movie'; ids = @{ imdb = 'tt1727587'; tmdb = 45745 }; media_info = $probe }
Invoke-RestMethod -Method Post http://192.168.1.20:32400/rex/feed/test/items -ContentType application/json -Body (ConvertTo-Json @{ items = @($item) } -Depth 20)
```

PowerShell menampilkan jawaban rex sebagai daftar, bukan JSON.
+++

**Yang seharusnya kamu lihat.** Jawabannya `{"created":1,"updated":0,"held":0,"unchanged":0}` dan log rex mencetak:

```
INFO    FEED identified "Sintel.2010" -> movie tmdb:45745 (placed)
INFO    FEED test upsert: 1 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Sintel sekarang ada di **Movies**, diputar dari web server kecil tadi. Belum ada aplikasi Plex yang bisa membuka rex sebelum [langkah 3](#step-3-add-it-to-a-plex-account), jadi langkah ini hanya mengecek feed-nya saja.

**Bersihkan** dulu sebelum lanjut: menghapus test source juga menghapus semua yang sudah dikirim. Request pertama akan menjawab dengan path `confirm`. Kirim `DELETE` ke path itu dalam lima menit.

+++ Linux and macOS
```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/test
curl -s -X DELETE "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
kill %1
```
+++ Windows
```powershell
Invoke-RestMethod -Method Delete http://192.168.1.20:32400/rex/sources/test
Invoke-RestMethod -Method Delete "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
Stop-Process -InputObject $server
```
+++

**Kalau tidak berhasil.**

- `"held":1`: `media_info` hilang atau tidak punya stream. Cek apakah `ffprobe` mencetak JSON untuk file tersebut.
- Jawaban dengan `rejected`: file bukan video berdasarkan ekstensinya, file adalah sample, tidak punya `id` atau `path`, path-nya salah format, atau `id` lain sudah memakai path itu. Jawaban dan log rex memberi tahu alasan masing-masing.
- `404 no such source`: `PUT /rex/sources/test` belum dijalankan lebih dulu.

## Langkah 3. Tambahkan ke akun Plex {#step-3-add-it-to-a-plex-account}

**Apa fungsinya.** Mendaftarkan rex ke akun Plex, seperti halnya Anda mendaftarkan Plex Media Server sungguhan, lalu membagikannya ke akun Anda sendiri.

**Mengapa ini penting.** rex mengambil nama setiap judul, poster, ringkasan, dan nama episode dari metadata Plex sendiri, dan hanya boleh meminta ke Plex setelah berada di sebuah akun. Apa pun yang dikirim aplikasi Anda sebelum klaim akan langsung diberi nama saat masuk, dan Fix Match tidak punya apa-apa untuk ditawarkan sampai saat itu. Langkah ini juga menghapus pemberitahuan "unclaimed" dan diperlukan sebelum [menggunakan rex di luar rumah Anda](#use-it-outside-your-home-optional).

**Gunakan akun Plex baru untuk ini, jangan akun Anda sendiri.** rex tidak dibuat oleh Plex, dan Plex bisa mengambil tindakan terhadap akun yang mendaftarkannya. Jauhkan akun asli Anda, beserta riwayat tontonan, teman, dan Plex Pass apa pun, dari risiko: buat akun gratis baru di [plex.tv](https://www.plex.tv) dengan alamat email yang tidak Anda pakai di tempat lain, daftarkan rex di akun itu, lalu bagikan rex ke akun Anda sendiri. Dengan begitu Anda menonton dengan masuk sebagai diri sendiri, sama seperti saat menonton server milik teman. rex tidak memutar apa pun sebelum langkah ini selesai.

### Daftarkan rex di akun baru {#register-rex-on-the-fresh-account}

1. Masuk ke [plex.tv](https://www.plex.tv) **pakai akun baru tadi**, buka [plex.tv/claim](https://www.plex.tv/claim), lalu salin kodenya. Kodenya kedaluwarsa dalam sekitar lima menit.
2. Di mesin tempat rex berjalan (`curl.exe` di Windows):

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**Yang seharusnya kamu lihat.** Perintah kedua menampilkan `claimed="1"`, dan file `claim_state.json` ada di folder rex. Simpan cadangan file itu: tanpa file ini, rex harus di-claim ulang, dan rex menolak claim kedua selama file tersebut ada. Mulai sekarang judul akan muncul lengkap dengan nama dan posternya, tanpa perlu restart.

**Kalau tidak.**

- Perintah pertama menjawab `409` dengan `rex: already claimed`: rex sudah terhubung ke akun Plex.
- Perintah itu menjawab `500 Internal Server Error` dan rex mencatat `claim exchange failed`: kodenya sudah kedaluwarsa atau sudah dipakai. Dapatkan kode baru dari [plex.tv/claim](https://www.plex.tv/claim).

### Bagikan ke akun Anda sendiri {#share-it-with-your-own-account}

1. Masih masuk dengan akun baru, buka [app.plex.tv](https://app.plex.tv), lalu **Settings** (ikon kunci inggris), **Manage Library Access**, dan **Grant Library Access**.
2. Masukkan username atau email akun kamu sendiri, pilih server rex dan kedua library, **Movies** dan **TV Shows**, lalu kirim undangannya.
3. Keluar, masuk sebagai **kamu sendiri**, dan terima undangannya. Undangan itu dikirim lewat email dan juga muncul di app.plex.tv.

![Manage Library Access di pengaturan app.plex.tv, dengan tombol Grant Library Access](../assets/rex/20-plex-manage-library-access.webp)

![Dialog Grant Library Access dengan Movies dan TV Shows milik server rex sudah dicentang](../assets/rex/21-plex-grant-library-access.webp)

**Yang harusnya kamu lihat.** Saat masuk sebagai diri sendiri, aplikasi Plex menampilkan server rex di samping server milikmu sendiri, lengkap dengan kedua library. Riwayat tontonan kamu di rex adalah milikmu sendiri: riwayat itu disimpan terpisah dari akun baru. Untuk berbagi dengan anggota keluarga lain, caranya sama.

## Langkah 4. Hubungkan aplikasi Anda {#step-4-connect-your-app}

**Fungsinya.** Mengarahkan aplikasimu ke rex. Aplikasimu mendaftar, lalu mengirim seluruh library dan setiap perubahan saat terjadi.

**Kenapa ini penting.** Ini satu-satunya penghubung antara keduanya. rex tidak punya pengaturan untuk aplikasimu: aplikasimu yang mencari rex, bukan sebaliknya.

Beri aplikasimu alamat rex, `http://192.168.1.20:32400`. Cara memasukkannya tergantung aplikasimu.

**Apa yang harus kamu lihat.** Log rex akan menampilkan, di bawah nama yang didaftarkan aplikasimu:

```
INFO    SOURCES myapp registered at http://192.168.1.20:8080
INFO    SOURCES PUT /rex/sources/myapp -> 200
INFO    FEED myapp upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Some.Movie.2019.1080p" -> movie tmdb:12345 (placed)
INFO    FEED myapp upsert: 180 created, 0 updated, 20 held, 0 unchanged, 0 rejected
```

rex membaca setiap file dari alamat di baris `registered at`, jadi rex harus bisa menjangkau aplikasimu di alamat itu. rex mencatat baris itu lagi hanya saat alamatnya berubah. File `held` menunggu output ffprobe-nya dan muncul begitu aplikasimu mengirimkannya. Kamu bisa cek apa yang dimiliki rex dari aplikasimu kapan saja (di Windows, pakai `curl.exe` tanpa `| head -c 600`):

```bash
curl -s http://192.168.1.20:32400/rex/sources                # the apps that registered, and their addresses
curl -s http://192.168.1.20:32400/rex/feed/myapp/items | head -c 600   # what is shown
curl -s http://192.168.1.20:32400/rex/feed/myapp/held  | head -c 600   # what waits for ffprobe output
```

**Jika tidak.**

- Log rex kosong: aplikasimu tidak pernah sampai ke rex. Periksa alamat yang kamu berikan, dan pastikan port rex terbuka di antara kedua mesin.
- File masuk tapi tidak ada baris `identified`: aplikasimu tidak mengirim `kind` dan `ids` (file `held` dan kiriman ulang yang tidak berubah juga tidak mencetak apa pun). Judul-judul itu tetap tidak cocok sampai aplikasimu mengirimnya. Kamu tetap bisa memperbaiki satu per satu secara manual dengan **Fix Match** di aplikasi Plex yang login dengan akun baru. Akun utamamu, yang dipakai bersama rex, akan ditolak.
- Judul muncul tapi tidak ada yang bisa diputar: rex tidak bisa menjangkau aplikasimu di alamat `registered at`. Baris `upstream failed` di [Saat ada yang salah](#when-something-is-wrong) memeriksanya.

## Langkah 5. Tonton sesuatu {#step-5-watch-something}

**Apa fungsinya.** Membuka rex di aplikasi Plex, sama seperti kamu membuka server Plex mana pun.

**Kenapa penting.** Ini inti dari seluruh pengaturan. Langkah ini juga membuktikan mata rantai terakhir: rex membaca file dari aplikasimu saat kamu menonton.

Buka aplikasi Plex di ponsel, TV, atau komputer **di jaringan rumah yang sama**. rex akan muncul di bawah nama perangkat tersebut, dengan **Movies** dan **TV Shows**. Pilih film dan tekan play.

![Aplikasi Plex yang menampilkan Movies dan TV Shows dari server rex di sidebar, di samping grid film](../assets/rex/10-plex-server-libraries.webp)

Di rumah tidak perlu yang lain: aplikasi Plex menemukan rex dengan penemuan lokal bawaan Plex dan tersambung lewat jaringanmu. Perangkat harus berada di jaringan yang sama dengan rex (bukan Wi-Fi tamu atau VLAN terpisah). Penemuan berjalan di port UDP 32410 dan 32414, jadi firewall di mesin rex harus mengizinkannya (di Windows, aturan firewall langkah 1 sudah mengurusnya). rex menjawab penemuan saat memakai port 32400. Jika kamu memindahkan rex ke 32500 karena Plex berjalan di mesin yang sama, penemuan diserahkan ke Plex tersebut, dan aplikasi menemukan rex lewat akun Plex tempat rex [dibagikan dengan](#share-it-with-your-own-account). app.plex.tv di browser web juga berfungsi di rumah, lewat alamat HTTPS yang diberikan [rex-direct](#rex-direct) ke rex setelah diklaim (rex nightly 2026.11.02 atau lebih baru). Pertama kali, Chrome akan bertanya apakah app.plex.tv boleh mengakses perangkat di jaringan lokal: izinkan. `http://192.168.1.20:32400/web` bukan Plex Web: rex tidak punya aplikasi web sendiri, dan halaman itu hanya menunjukkan apakah rex sudah diklaim dan di mana menontonnya.

**Yang seharusnya kamu lihat.** Poster, judul, dan tahun seperti di server Plex mana pun. Pemutaran mulai dalam beberapa detik.

Dua hal yang mungkin kamu temui:

- **"yourhost server is unclaimed and not secure".** Aplikasi Plex mengatakan ini untuk server mana pun yang belum ada di akun Plex, dan rex tidak memutar apa pun sampai server itu masuk ke akun. Lakukan [langkah 3](#step-3-add-it-to-a-plex-account).
- **"This server is not powerful enough to convert video".** Jika semua judul gagal di semua perangkat, lihat log rex tepat setelah kamu menekan Play: `upstream failed` atau `502` di sana berarti rex tidak bisa menjangkau aplikasimu, dan FFmpeg tidak akan memperbaikinya. Baris `upstream failed` di [Saat ada yang salah](#when-something-is-wrong) menjelaskan apa yang harus dilakukan. Jika hanya sebagian file yang gagal, sering kali hanya di browser web, berarti perangkat tidak bisa memutar file itu apa adanya, biasanya suara AC3 atau DTS. Aplikasi Plex di TV dan ponsel memutar sebagian besar file apa adanya. Untuk memutar semuanya di mana saja, atur [Konversi video (opsional)](#converting-video-optional).

**Menghapus berarti menghapus di aplikasimu.** Saat masuk dengan akun baru, **Delete** pada judul di aplikasi Plex membuat rex meminta aplikasimu menghapus file tersebut, seperti dijelaskan di [Yang harus dilakukan aplikasimu](#what-your-app-must-do). Akun yang dibagikan rex tidak bisa menghapus. Untuk mematikan penghapusan: di app.plex.tv dengan akun baru, buka **Settings**, **Library** milik server rex, **Show Advanced**, hilangkan centang **Allow media deletion**, lalu simpan.

![Pengaturan Library server rex dengan Show Advanced terbuka dan Allow media deletion diberi garis tepi](../assets/rex/32-plex-allow-media-deletion.webp)

File yang dihapus aplikasimu masuk ke tempat sampah library seperti di Plex: file itu tetap ada, tidak tersedia, dengan riwayat tontonannya, dan kembali seperti semula jika aplikasimu mengirimnya lagi. **Empty Trash** pada library menghapusnya selamanya, dan **Empty trash automatically after every scan** (Settings, Library), yang nonaktif, melakukannya dengan sendirinya.

Setiap file masuk ke **Movies** atau **TV Shows** berdasarkan `kind` yang dikirim aplikasimu. File tanpa `kind` mengikuti folder pertamanya: `shows` masuk ke TV Shows, selain itu ke Movies.

Untuk memberi sebuah folder library sendiri, aplikasimu menambahkan `directories` ke pendaftarannya, dengan menyebutkan folder pertama dari path file dan judul library: `{"url": ..., "directories": [{"name": "anime", "shows": "Anime", "movies": "Anime Movies"}]}`. Cukup salah satu judul saja. rex membuatnya saat aplikasimu mendaftar dan memindahkan isi folder itu ke dalamnya apa adanya: riwayat tontonan, Fix Match, dan edit ikut terbawa. Entri yang salah format akan dilewati dan dicantumkan di `ignored` dalam jawaban, beserta alasannya. Ganti namanya di aplikasi Plex sesukamu. Jika kamu menghapusnya, ia tetap terhapus dan file-filenya kembali ke Movies atau TV Shows, sampai kamu menambahkannya lagi dengan **Add Library**, yang daftar foldernya menampilkan folder aplikasimu. [Library yang didefinisikan sumber](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#libraries-a-source-declares) berisi aturannya.

**Cadangkan** `rex.db` di folder rex (isinya library, riwayat tontonan, dan login aplikasimu, jadi jaga kerahasiaannya), `claim_state.json`, dan setelah rex-direct memberi rex nama, `rex-direct.json` (kunci sertifikatnya):

+++ Linux dan macOS
```bash
sudo apt install -y sqlite3    # once, on Linux; macOS has it
mkdir -p ~/rex-backup
sqlite3 ~/rex/rex.db ".backup $HOME/rex-backup/rex.db"
cp ~/rex/*.json ~/rex-backup/
```
+++ Windows
Windows tidak punya `sqlite3`, jadi hentikan rex sebentar lalu salin `rex.db` bersama dua file di sebelahnya yang namanya diawali sama:

```powershell
Stop-Process -Name rex; Start-Sleep 1
New-Item -ItemType Directory -Force $HOME\rex-backup | Out-Null
Copy-Item $HOME\rex\rex.db*, $HOME\rex\*.json $HOME\rex-backup
Start-ScheduledTask rex
```
+++

Di Docker, file-file itu ada di `~/rex/config` dan hanya bisa dibaca root. Cadangkan dari dalam container dengan `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`, lalu `mkdir -p ~/rex-backup && sudo cp ~/rex/config/rex.db.bak ~/rex/config/*.json ~/rex-backup/`.

[Pulihkan cadangan](#restore-a-backup) mengembalikannya.

Selesai. Bagian di bawah ini bersifat opsional.

## Gunakan di luar rumah (opsional) {#use-it-outside-your-home-optional}

**Apa yang dilakukannya.** Memberi rex alamat HTTPS yang bisa diakses aplikasi Plex dari luar rumah, lalu memberi tahu plex.tv tentang alamat itu.

**Kenapa ini penting.** Di luar rumah, app.plex.tv hanya bisa terhubung ke alamat HTTPS, dan aplikasi Plex lain juga lebih memilih HTTPS. Server Plex sungguhan bisa kembali memakai relay Plex, tapi rex tidak bisa, jadi kamu yang memilih cara aksesnya. rex harus sudah [claimed](#step-3-add-it-to-a-plex-account) dulu. Proxy yang menghadap internet harus memblokir `/rex/`: lihat [Keep the port private](#keep-the-port-private).

**Plex Pass.** Plex Web bisa diputar di luar rumah tanpa Plex Pass atau Remote Watch Pass di kedua akun. Aplikasi Plex lain belum diuji di luar rumah.

Apa pun pilihanmu, setiap data yang kamu tonton di luar rumah akan keluar lewat kecepatan **upload** koneksi rumahmu. Kira-kira, upload 20 Mbit/s cukup untuk satu 1080p WEB-DL, bukan remux.

| Kondisimu | Pakai | Alasan |
|---|---|---|
| Router punya IP publik dan kamu bisa forward satu port | **[rex-direct](#rex-direct)** (paling sederhana) | Aktif secara default: cukup satu port forward. DMM memberi rex nama dan sertifikat, serta menjaga nama itu tetap mengarah ke IP rumahmu |
| Kamu bisa memasang Tailscale di perangkat tempat kamu menonton | **[Tailscale serve](#tailscale-serve)** (terbaik) | Tidak ada yang perlu dibuka di router, dan tetap jalan di belakang koneksi internet apa pun. Sertifikatnya diperbarui otomatis, dan tidak ada orang di luar tailnet-mu yang bisa mengakses rex |
| Perangkat tanpa Tailscale (TV teman, hotel), dan router punya IP publik | **[Caddy](#caddy)** dengan domain sendiri, atau dengan nama `sslip.io` gratis | Koneksi langsung tanpa perantara, dan sertifikat gratis yang diperbarui otomatis. Kamu forward port 443 |
| Koneksimu tidak punya IPv4 publik (CGNAT atau DS-Lite, umum di kabel, seluler, dan beberapa penyedia fiber) tapi punya IPv6 | **[rex-direct over IPv6](#rex-direct-over-ipv6)** | Tidak perlu port forward dan tidak perlu menyewa apa pun: kamu cukup mengizinkan port 32400 lewat IPv6. Perangkat tempat kamu menonton juga perlu IPv6, dan kebanyakan jaringan seluler sudah punya |
| Koneksimu tidak punya IP publik sama sekali, atau kamu menonton di jaringan tanpa IPv6, dan perangkatmu tanpa Tailscale | **[VPS kecil](#a-small-vps)** | rex tidak punya relay dan tidak akan punya. VPS sewaan memberi IP publik, dan tunnel meneruskan semuanya ke rex dengan bandwidth penuh milik VPS |

Tidak direkomendasikan:

- **Tunnel Cloudflare.** Semua data lewat Cloudflare, yang juga membuang `Range` pada pembacaan pertama sebuah file, sehingga setiap kali pemutaran dimulai aplikasimu menarik seluruh file.
- **Tailscale Funnel, ngrok, dan tunnel hosted lainnya.** Mereka membatasi bandwidth atau data bulanan, yang cepat habis oleh satu film. Tailscale Funnel juga mempublikasikan seluruh rex, termasuk feed API: siapa pun di internet bisa menambah atau menghapus isi pustakamu.
- **Forward port 32400 tanpa rex-direct atau sertifikat sendiri.** Aplikasi Plex akan mendapat alamat HTTP biasa, dan app.plex.tv menolaknya.

### rex-direct

rex-direct adalah jawaban DMM untuk plex.direct, dan fitur ini aktif secara default. Di router Anda, teruskan port 32400 (TCP) ke mesin rex. Hanya itu, dan tidak perlu restart apa pun.

Setelah diklaim, rex mendapatkan dua nama dari DMM: `<hash>.rex-direct.debridmediamanager.com`, yang mengarah ke IP publik rumah Anda, dan `lan.<hash>.rex-direct.debridmediamanager.com`, yang mengarah ke IP LAN rex, lengkap dengan sertifikat untuk keduanya. Sertifikat pertama butuh beberapa menit; log rex akan memberi tahu bahwa sertifikat sedang diterbitkan lalu menampilkan setiap nama dalam baris `rex-direct:`. IP rumah baru dan perpanjangan sertifikat akan ditangani sendiri. Satu akun Plex bisa memegang hingga sepuluh nama rex-direct. Di rumah, aplikasi Plex, termasuk app.plex.tv, bisa memakai nama `lan.`, yang terhubung langsung ke rex lewat jaringan Anda, jadi port forward hanya diperlukan saat di luar rumah. Di app.plex.tv, izinkan akses ke perangkat di jaringan lokal saat Chrome menanyakannya; jika tidak, aplikasi akan kembali ke nama publik, yang memerlukan port forward. [Yang seharusnya Anda lihat](#what-you-should-see) memeriksa kedua nama tersebut.

Jika router Anda meneruskan port luar yang berbeda ke rex, tambahkan kunci `REX_DIRECT_PORT=<that port>` seperti yang ditunjukkan [langkah 1](#step-1-install-rex) untuk sistem Anda, lalu restart rex. Port forward tidak membuka API feed: lihat [Menjaga port tetap privat](#keep-the-port-private).

### rex-direct melalui IPv6 {#rex-direct-over-ipv6}

Untuk koneksi tanpa IPv4 publik (CGNAT atau DS-Lite) yang punya IPv6. Setelah DMM berhasil tersambung ke rex lewat alamat IPv6-nya dan menemukan server yang sama di sana, DMM juga mengarahkan nama rex-direct milik rex ke alamat itu. Kamu butuh rex nightly 2026.11.08 atau yang lebih baru, dan di Docker, pakai host networking.

IPv6 tidak butuh port forward, dan juga tidak butuh port mapping. rex harus memakai port yang sama di dalam dan di luar, jadi biarkan `REX_DIRECT_PORT` tidak diisi. Di firewall router kamu, izinkan koneksi TCP masuk ke port 32400 menuju mesin rex lewat IPv6. rex menawarkan IPv6-nya satu menit setelah mulai (atau setelah diklaim), lalu setiap 6 jam, jadi tambahkan aturan itu sebelum menjalankan rex, atau restart rex setelah menambahkannya. Sekitar satu menit kemudian, log-nya akan menampilkan kedua alamat:

```
rex-direct: https://<hash>.rex-direct.debridmediamanager.com:32400 -> <IPv4> and <IPv6>
```

Kalau tidak ada baris dengan `and <IPv6>` muncul dalam beberapa menit, berarti DMM tidak bisa menjangkau rex lewat IPv6. Cek aturan firewall-nya, dan pastikan rex di Docker memakai host networking. Di Windows, rex menawarkan alamat IPv6 sementara milik Windows, yang diganti Windows sekitar sehari sekali. Matikan alamat sementara dengan `netsh interface ipv6 set privacy state=disabled` di PowerShell yang dijalankan sebagai administrator, lalu restart rex supaya menawarkan alamat yang stabil. `<IPv4>` di baris itu adalah alamat bersama dari provider kamu dan tidak bisa dipakai untuk menjangkau rex, jadi perangkat yang kamu pakai untuk menonton juga perlu IPv6. Sebagian besar jaringan seluler sudah punya IPv6; jaringan hotel atau kantor yang hanya punya IPv4 tidak bisa menjangkau rex dengan cara ini.

### Tailscale serve

Pasang [Tailscale](https://tailscale.com/download) di mesin rex dan di perangkat tempat kamu menonton, lalu masuk dengan akun yang sama. Setelah itu, di mesin rex:

```bash
sudo tailscale serve --bg 32400
```

Di Windows, jalankan di PowerShell sebagai administrator tanpa `sudo`. Di macOS, gunakan [alat baris perintah](https://tailscale.com/kb/1080/cli) dari aplikasi Tailscale tanpa `sudo`.

Perintah tadi akan menampilkan alamat, misalnya `https://myhost.tailnet.ts.net`. Berikan alamat itu ke rex dengan menambahkan `:443` di belakangnya: ubah perintah start rex dari [langkah 1](#step-1-install-rex) dengan menambahkan `--announce-url https://myhost.tailnet.ts.net:443`, lalu restart rex.

Semua orang di tailnet kamu, termasuk siapa pun yang kamu ajak berbagi mesin ini, bisa memakai feed API milik rex. Bagikan mesin ini hanya kepada orang yang kamu percaya.

### Caddy

Kamu perlu meneruskan port 443 di router ke mesin rex, dan sebuah nama untuk IP rumahmu:

- **Domain sendiri:** sebuah record `A`, misalnya `rex.example.com`, yang mengarah ke IP rumahmu.
- **Tanpa domain:** pakai `1-2-3-4.sslip.io` dengan angka dari IP publikmu (`curl -s ifconfig.me` akan menampilkannya). Kalau IP-mu berubah, perbarui nama tersebut.

Pasang [Caddy](https://caddyserver.com/docs/install) dan beri file ini sebagai Caddyfile (`/etc/caddy/Caddyfile` untuk paket Linux Caddy; di macOS dan Windows, file bernama `Caddyfile` di foldernya sendiri, yang dibaca oleh `caddy run` di folder tersebut):

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` menjaga API feed tetap tertutup dari internet; aplikasimu tetap bisa mengakses rex secara langsung. Lalu muat ulang Caddy (`sudo systemctl reload caddy` untuk paket Linux). Di macOS dan Windows, jalankan `caddy run` di foldernya dan biarkan tetap berjalan seperti cara [langkah 1](#step-1-install-rex) menjaga rex tetap berjalan; di Windows, juga izinkan TCP port 443 lewat firewall seperti di langkah 1 untuk 32400. Kemudian akhiri perintah start rex dengan `--announce-url https://rex.example.com:443`, lalu restart rex.

### VPS kecil {#a-small-vps}

Untuk koneksi yang sama sekali tidak punya IP publik, atau saat kamu menonton di jaringan yang tidak memakai IPv6: VPS akan membawa semua stream, menggantikan [rex-direct over IPv6](#rex-direct-over-ipv6). rex tidak punya relay dan memang tidak akan punya, jadi server yang kamu sewa berperan sebagai router kamu: ia punya IP publik, dan sebuah tunnel dari mesin rex membawa semuanya ke rex. VPS apa pun dengan IPv4 publik bisa dipakai, biayanya beberapa euro per bulan. **Pilih yang kuota trafik bulanannya cukup untuk apa yang kamu tonton di luar rumah:** setiap byte lewat di sini, dan paket dengan kuota kecil akan cepat habis.

Kamu butuh IP VPS (`1.2.3.4` di bawah), port 443, 80 dan 7000 terbuka di sana, dan string acak panjang untuk tunnel (`openssl rand -hex 32`).

**Di VPS**, pasang [frp](https://github.com/fatedier/frp/releases) (program `frps`) dan [Caddy](https://caddyserver.com/docs/install). Buat `frps.toml`:

```toml
bindPort = 7000
auth.token = "your-long-random-string"
proxyBindAddr = "127.0.0.1"
```

`proxyBindAddr` menjaga ujung tunnel tetap di loopback VPS, jadi internet hanya bisa mengakses rex lewat Caddy. Buat `/etc/caddy/Caddyfile`, dengan IP VPS sebagai `1-2-3-4.sslip.io` (nama gratis yang selalu mengarah ke IP itu) atau domain kamu sendiri yang diarahkan ke sana:

```
1-2-3-4.sslip.io {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` menjaga API feed tetap tidak bisa diakses dari internet. Jalankan `frps -c frps.toml` sebagai service, lalu jalankan `sudo systemctl reload caddy`.

**Di mesin rex**, pasang frp juga (program `frpc`) dan buat `frpc.toml`:

```toml
serverAddr = "1.2.3.4"
serverPort = 7000
auth.token = "your-long-random-string"

[[proxies]]
name = "rex"
type = "tcp"
localIP = "192.168.1.20"
localPort = 32400
remotePort = 32400
```

Jalankan sebagai service: di Linux, misalnya `~/.config/systemd/user/frpc.service` dengan `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` dan `Restart=always`; di macOS dan Windows, jalankan `frpc -c frpc.toml` seperti cara [step 1](#step-1-install-rex) menjalankan rex. Lalu akhiri perintah start rex dengan `--announce-url https://1-2-3-4.sslip.io:443`, tambahkan key `REX_DIRECT_URL=off` (di balik CGNAT, IPv4 dari nama rex-direct tidak sampai ke rex, jadi plex.tv tidak seharusnya mencantumkannya), dan restart rex. app.plex.tv di rumah kemudian juga lewat VPS; aplikasi Plex lain di rumah tetap terhubung langsung ke rex.

### Yang seharusnya Anda lihat {#what-you-should-see}

```bash
curl -s https://lan.<hash>.rex-direct.debridmediamanager.com:32400/identity
```

menampilkan halaman XML pendek dengan `machineIdentifier` milik rex di komputer di rumah; `curl` tidak menampilkan apa-apa jika alamat atau sertifikatnya salah. Gunakan alamat Anda sendiri: rex mencatatnya saat mulai sebagai `rex-direct: https://lan.<hash>.rex-direct.debridmediamanager.com:32400 -> 192.168.1.20 (LAN)` (dengan `REX_DIRECT_URL=off` tidak ada). Buka alamat luar Anda dengan `/identity` ditambahkan di browser HP dengan Wi-Fi mati: dengan rex-direct, alamatnya adalah baris `rex-direct:` lain milik rex, dan dengan Tailscale serve `https://myhost.tailnet.ts.net`, yang hanya bisa dibuka HP saat Tailscale menyala. Halaman XML pendek akan muncul tanpa peringatan sertifikat.

Jika HP gagal, port belum diteruskan (atau, [lewat IPv6](#rex-direct-over-ipv6), belum diizinkan masuk), koneksi Anda berada di balik CGNAT tanpa IPv6, rex hanya bisa dijangkau lewat IPv6 dan jaringan HP tidak punya IPv6, atau sertifikat rex-direct masih diterbitkan (log rex menyebutkannya selama proses itu berjalan).

Log rex menyebutkan alamat yang diumumkannya:

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex mencetak ini setiap kali mulai. Masalah akan terlihat nanti sebagai `heartbeat failed` atau `announced but NOT visible`. Selain itu, server mendaftarkan alamat-alamat tersebut di plex.tv, dan aplikasi Plex di luar rumah memilih alamat yang bisa dijangkaunya. Jika rex mencatat `waiting for a claim`, lakukan [langkah 3](#step-3-add-it-to-a-plex-account) dulu.

## Riwayat tontonan Anda dari server Plex lain (opsional) {#your-watch-history-from-another-plex-server-optional}

Pernah nonton di server Plex lain sebelumnya? Setelah library kamu ada di rex, [Bring your watch history](import-watched.md) akan menyalin apa yang sudah kamu tonton, di menit mana kamu berhenti, dan rating bintang dari server itu, untuk setiap orang secara terpisah.

## Konversi video (opsional) {#converting-video-optional}

**Apa fungsinya.** Membuat rex mengonversi apa yang tidak bisa diputar oleh perangkat, seperti yang dilakukan Plex.

**Kenapa penting.** Tanpa ini, perangkat yang tidak bisa memutar file apa adanya akan menampilkan "This server is not powerful enough to convert video". Browser web paling sering mengalami ini, misalnya dengan suara AC3 atau DTS. Jika setiap judul gagal di setiap perangkat, penyebabnya ada di tempat lain: lihat [langkah 5](#step-5-watch-something).

Pasang **jellyfin-ffmpeg** 8, bukan `ffmpeg` yang disediakan sistem kamu. Ini build yang dipakai rex untuk pengukuran dan satu-satunya yang bisa mengonversi setiap file Dolby Vision, melakukan tonemap HDR di chip grafis, dan menggambar subtitle di sana. FFmpeg lain bisa mengonversi video biasa, dan log rex akan memberi tahu apa yang kurang (FFmpeg bawaan Ubuntu 22.04 juga meleset beberapa detik saat seeking). rex menemukannya sendiri.

+++ Linux
Paketnya ditaruh di `/usr/lib/jellyfin-ffmpeg`, di samping FFmpeg lain. Baris pertama memilih build untuk sistem kamu: ada build untuk Ubuntu 22.04, 24.04 dan 26.04 serta Debian 12 dan 13, di amd64 atau arm64. Di sistem lain, `curl` akan berhenti dengan error.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

Di Linux lain, ekstrak build portable jellyfin-ffmpeg ke `~/rex/ffmpeg`, tempat rex mencarinya, lalu restart rex. Build ini memakai driver grafis milik sistem kamu, jadi di sistem yang lebih lama konversinya hanya dilakukan di prosesor. Gunakan paket di mana pun ada.

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

Dengan chip grafis Intel atau AMD, jalankan juga `sudo usermod -aG render "$USER"` lalu reboot agar service mendapat grup tersebut. Di LXC, teruskan GPU ke container. Chip ini membuat konversi jadi cepat. Tanpa chip, rex memakai prosesor. Jika tidak ada chip Intel atau AMD, rex juga mencoba encoder kartu NVIDIA. Di Intel, `sudo apt install intel-opencl-icd` juga membuat HDR dan Dolby Vision dikonversi di chip, kira-kira secara real time untuk 4K di Intel kecil. Tanpa itu, keduanya dikonversi di prosesor, dan Intel berdaya rendah tidak bisa melakukannya secara real time di 4K.
+++ macOS
Build portable ditaruh di `~/rex/ffmpeg`, tempat rex mencarinya:

```bash
B=$( [ "$(uname -m)" = arm64 ] && echo macarm64 || echo mac64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
launchctl kickstart -k gui/$(id -u)/com.rex
```

Di Mac, rex selalu mengonversi di prosesor karena tidak ada cara baginya memakai chip grafis Mac.
+++ Windows
Build portable ditaruh di folder `ffmpeg` di dalam folder rex, tempat rex mencarinya:

```powershell
cd $HOME\rex
curl.exe -fLO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Expand-Archive jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip ffmpeg
Remove-Item jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex
```

Di Windows, rex mengonversi memakai encoder kartu NVIDIA jika ada, dan memakai prosesor jika tidak ada.
+++

**Yang seharusnya kamu lihat.** Log rex punya baris `transcoder:` yang menyebutkan FFmpeg dan perangkat keras yang ditemukan (`hardware none` berarti prosesor). `transcoder off` saat start berarti tidak ada yang ditemukan. File yang tadinya gagal sekarang bisa diputar. Log menunjukkan apa yang dikonversi, misalnya `video=copy h264 audio=ac3->aac`.

Subtitle dalam file yang dikonversi: subtitle gambar akan dibakar ke dalam gambar, dan subtitle teks yang kamu unggah ikut terbawa. Plex untuk Android dan iOS juga menyimpan subtitle teks sebagai track; aplikasi lain menggambarnya ke dalam gambar. Unduhan offline yang sudah dikonversi tetap tidak menyertakan subtitle teks.

## Subtitle {#subtitles}

**Apa yang dilakukannya.** Search Subtitles di aplikasi Plex akan mencari subtitle dari provider bawaan Plex setelah rex di-claim. rex memeriksa subtitle yang Anda pilih terhadap file dan memperbaiki timing-nya jika terlambat atau dibuat untuk frame rate lain. Jika akun Plex Anda diatur untuk menampilkan subtitle dan sebuah judul tidak punya subtitle dalam bahasa Anda, rex akan mencari satu selama hingga 3 detik sebelum mulai.

**Kenapa ini penting.** Hasil pertama dari Plex sering kali tidak sinkron dengan file-nya.

![Dialog Subtitles search di aplikasi Plex, menampilkan hasil bahasa Inggris untuk Sintel](../assets/rex/51-plex-search-subtitles.webp)

Tidak ada yang perlu diatur. rex memeriksa subtitle terhadap teks subtitle milik file itu jika ada. File yang tidak punya teks subtitle akan diperiksa terhadap suaranya saat Anda menekan play, yang membutuhkan [Converting video](#converting-video-optional) sudah diatur dan membaca enam potongan 90 detik dari file.

**Apa yang harus Anda lihat.** Log rex punya baris `SUBTITLE measured` untuk setiap subtitle yang diperiksanya, dan `SUBTITLE applied ... corrected by` saat ia memperbaiki satu subtitle.

## Kemampuan film dan serial TV {#movie-and-tv-capabilities}

Unduhan, deteksi intro dan credit, thumbnail seek, dan fitur server Plex lainnya yang dimiliki rex, beserta pengaturannya, ada di [panduan setup rex](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities). Musik dan Live TV berasal dari sumber yang mengirimkannya ([batasan rex](https://github.com/debridmediamanager/rex#limits)), misalnya [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) untuk saluran live. Tidak ada DVR, jadi tidak ada yang direkam. Foto hanya datang dari sumber yang mengirim gambar ([feed API](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#photos)), misalnya komik dari zurg. Plex Web menampilkannya; Plex untuk Android tidak menampilkan pustaka foto.

Tetap gunakan mode proxy default untuk pemutaran debrid bersama. Real-Debrid melacak IP publik setiap pengunduh; penggunaan satu akun dari beberapa IP akan memicu peringatan berbagi, meskipun unduhannya berhasil. URL unduhan TorBox memuat API key lengkap, jadi redirect memberi setiap klien dan akun pengguna bersama akses, termasuk untuk menghapus. Baca [risiko redirect dan setup](direct-download.md#before-you-start) dulu sebelum membiarkan aplikasi mengunduh langsung dari provider.

## Jalankan rex di Docker {#run-rex-in-docker}

Langkah-langkah ini untuk mesin Linux. Di macOS dan Windows, Docker Desktop menjalankan container di dalam mesin virtual, jadi host networking, LAN discovery, dan chip grafis tidak bekerja seperti di Linux. Pakai langkah di atas saja.

Buat folder, misalnya `~/rex`, dengan `compose.yml` ini:

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/config
```

- Chip grafis Intel atau AMD? Tambahkan `devices: ["/dev/dri:/dev/dri"]` supaya rex bisa mengonversi video memakai chip itu.
- `network_mode: host` membuat aplikasi Plex di jaringanmu bisa menemukan rex sendiri, dan membuat rex bisa mengakses aplikasimu di alamat yang didaftarkan, seolah-olah dari mesin itu sendiri.
- `./config` berisi `rex.db` dan, nanti, `claim_state.json`. File-file ini hanya bisa dibaca root, karena `rex.db` menyimpan login aplikasimu.
- Plex Media Server ada di mesin yang sama? Tambahkan `command: --port 32500` dan pakai `32500` di mana pun perintah atau pengaturan menulis `32400`.

```bash
docker compose up -d
docker compose logs -f rex
```

Kamu harus melihat baris yang sama seperti di [langkah 1](#step-1-install-rex). Lalu jalankan langkah 2 sampai 5 seperti di atas. Kalau aplikasimu juga jalan di container, aplikasi itu harus mendaftarkan alamat yang bisa dijangkau rex dari mesin, bukan alamat yang hanya bisa dilihat container lain.

Update dengan `docker compose pull && docker compose up -d`. Image-nya sudah membawa jellyfin-ffmpeg, jadi untuk [mengonversi video](#converting-video-optional) kamu hanya perlu memberikan chip grafisnya. HTTPS tetap bisa seperti di atas: Tailscale, Caddy, dan frp berjalan di mesin itu sendiri, dan `--announce-url ...` ditaruh di `command:` pada file compose.

## Jaga port tetap privat {#keep-the-port-private}

rex tidak meminta password di API feed-nya. API itu hanya menjawab dari mesin ini, jaringan rumahmu (10.x, 172.16-31.x, 192.168.x, 169.254.x, dan alamat IPv6 privat) dan Tailscale (100.64-127.x). Untuk siapa pun di luar jaringan tersebut, rex menjawab seolah-olah API-nya tidak ada. Jadi meneruskan port rex untuk [rex-direct](#rex-direct), atau membiarkannya masuk lewat IPv6, tidak membuat API itu terbuka. Router yang memberi pengunjung dari luar alamat miliknya sendiri membuat mereka terlihat seperti berasal dari jaringan lokal, dan itu membuat feed terbuka ke internet. Karena itu, aplikasimu harus melakukan push dari salah satu jaringan tersebut. Di belakang router rumah, perangkat dengan alamat IPv6 dalam rentang jaringan rumahmu juga dihitung, jadi nama host yang mengarah ke IPv6 rex akan berfungsi di rumah. Di VPS, beri nama rex dengan alamat dari jaringan privat. Proxy di mesin rex terlihat lokal bagi rex, jadi pastikan `/rex/*` tetap diblokir di proxy mana pun yang menghadap internet, seperti yang ada di contoh [Caddy](#caddy).

## Memperbarui {#updating}

rex tidak pernah memperbarui dirinya sendiri. Jalankan lagi blok unduh di [langkah 1](#step-1-install-rex) (blok ini mengganti program dan `data/`, dan membiarkan `rex.db`, kunci Anda, `claim_state.json`, serta `rex-direct.json` tetap utuh), lalu mulai ulang rex seperti yang ditunjukkan langkah 1. Di Windows, jalankan `Stop-Process -Name rex` sebelum blok unduh, karena Windows tidak mengizinkan `rex.exe` yang sedang berjalan untuk diganti, dan `Start-ScheduledTask rex` setelah blok unduh. Jika rex lalu keluar dengan `unrecognized arguments`, hapus flag yang disebutkan di situ dari perintah start rex: rex tidak lagi memilikinya.

## Nanti: pulihkan, pindahkan, hapus {#later-restore-move-remove}

### Pulihkan cadangan {#restore-a-backup}

Hentikan rex, hapus `rex.db` dan `rex.db-wal` serta `rex.db-shm` di sebelahnya, letakkan file cadangan Anda di folder rex, lalu jalankan rex lagi. Membiarkan `rex.db-wal` lama di tempatnya akan membatalkan pemulihan.

+++ Linux
```bash
systemctl --user stop rex
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
systemctl --user start rex
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
launchctl load ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
```powershell
Stop-Process -Name rex; Start-Sleep 1
Remove-Item $HOME\rex\rex.db*
Copy-Item $HOME\rex-backup\* $HOME\rex
Start-ScheduledTask rex
```
+++ Docker
```bash
cd ~/rex && docker compose down
sudo rm -f config/rex.db config/rex.db-wal config/rex.db-shm
sudo cp ~/rex-backup/rex.db.bak config/rex.db && sudo cp ~/rex-backup/*.json config/
docker compose up -d
```
+++

### Pindahkan rex ke mesin lain {#move-rex-to-another-machine}

Backup seperti di [langkah 5](#step-5-watch-something), lalu hentikan rex di mesin lama untuk selamanya, seperti blok pertama di [Hapus rex](#remove-rex). Di mesin baru, jalankan [langkah 1](#step-1-install-rex), tapi salin file backup kamu ke folder rex sebelum menjadikannya service. Ini tetap server yang sama untuk aplikasi Plex kamu, masih di-claim dan dibagikan. Lalu:

- Ganti alamat LAN IP di aplikasi kamu dengan yang baru, seperti di [langkah 4](#step-4-connect-your-app).
- Pindahkan port forward di router kamu ke mesin baru, atau aturan firewall IPv6-nya, sebelum rex mulai berjalan di sana. Nama rex-direct tetap sama dan otomatis mengikuti IP publik yang baru. Tailscale serve dan Caddy perlu diatur ulang di mesin baru.

### Pindahkan rex ke akun Plex lain {#move-rex-to-another-plex-account}

Kalau akun yang dipakai untuk claim rex hilang atau kena banned, atau kamu mau pakai rex di akun lain, buat akun baru, hentikan rex, hapus `claim_state.json` di folder rex, jalankan rex lagi, lalu ulangi [langkah 3](#step-3-add-it-to-a-plex-account): claim, lalu share lagi ke semua orang. Kalau kamu masih bisa login ke akun lama, hapus rex di sana juga: di app.plex.tv buka **Settings**, **Authorized Devices**, filter **by Servers**, lalu hapus rex. Dua langkah itu sudah cukup untuk unclaim. rex tidak punya fitur sign-out: request sign-out Plex (`DELETE /myplex/account`) mengembalikan 200 tapi rex tetap ter-claim. Library, Fix Match, perubahan yang sudah kamu buat, dan nama rex-direct tetap ada. Riwayat tontonan tiap orang akan kembali begitu rex di-share lagi ke akun mereka.

### Rex yang mana yang harus saya jalankan? {#which-rex-do-i-run}

rex tidak punya perintah version. Tanggal nightly ada di nama unduhannya (`2026.10.30.0040-nightly`), dan file program juga membawa tanggal yang sama: `ls -l ~/rex/rex` (di Windows `(Get-Item $HOME\rex\rex.exe).LastWriteTime`). Versi Plex yang ditampilkan aplikasi Anda bukan versi rex: rex sengaja melaporkan versi Plex Media Server yang terbaru, sehingga aplikasi menganggapnya sudah up to date, dan **Check for Updates** selalu menyatakan begitu.

### Hapus rex {#remove-rex}

Hentikan rex untuk selamanya:

+++ Linux
```bash
systemctl --user disable --now rex && rm ~/.config/systemd/user/rex.service
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist && rm ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
Di PowerShell sebagai administrator:

```powershell
Unregister-ScheduledTask rex -Confirm:$false; Stop-Process -Name rex
Remove-NetFirewallRule -DisplayName rex, "rex discovery"
```
+++ Docker
```bash
cd ~/rex && docker compose down
```
+++

Lalu hentikan aplikasimu agar tidak lagi mengirim ke rex. Di app.plex.tv, pakai akun baru, buka **Settings**, **Authorized Devices**, filter berdasarkan **Servers**, lalu hapus rex. Hapus port forward di router kamu (atau aturan firewall IPv6), dan hapus folder rex.

### Mendapatkan bantuan {#getting-help}

Tanyakan di forum **rex-support** [Discord](https://discord.com/invite/7u4YjMThXP) DMM: [Getting help](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan, dan cara sponsor mendapatkan bantuan jarak jauh.

## Ketika ada yang salah {#when-something-is-wrong}

| Yang kamu lihat | Yang harus dilakukan |
|---|---|
| `/rex/sources` tetap `{"size":0}` | Aplikasimu belum terdaftar. Periksa alamat yang diberikan kepadanya dan pastikan alamat itu bisa mencapai port rex |
| Push dijawab `404 no such source` | Aplikasimu mengirim push sebelum mendaftar. Aplikasi harus `PUT /rex/sources/<name>` dulu |
| Log rex menulis `held ... no media_info yet` | Aplikasimu mengirim file tanpa output ffprobe. Output itu akan muncul setelah datang |
| Judul menampilkan nama file dan tidak ada poster | rex tidak ada di akun Plex. Lakukan [langkah 3](#step-3-add-it-to-a-plex-account). Jika rex diklaim setelah aplikasimu mengirim library-nya, judulnya akan otomatis diberi nama yang benar begitu klaim berhasil |
| Sebuah judul ada di show yang salah, atau film diberi judul sesuai nama filenya | Aplikasimu tidak mengirim `kind` dan `ids` untuk judul itu, atau mengirim yang salah. Perbaiki di aplikasimu, atau gunakan **Fix Match** di aplikasi Plex yang sudah masuk dengan akun baru; Fix Match tetap sesuai pengaturanmu |
| Semua judul gagal di semua perangkat, sering dengan pesan "This server is not powerful enough to convert video", dan log rex menampilkan `upstream failed` atau `502` tepat setelah kamu menekan Play (jika FFmpeg sudah diatur, `TRANSCODE ... exited` dengan koneksi ditolak atau timeout) | rex tidak bisa mencapai aplikasimu di alamat yang didaftarkan, dan FFmpeg tidak bisa memperbaikinya. `curl -s http://192.168.1.20:32400/rex/sources` menunjukkan alamat itu sebagai `url` aplikasimu. Di mesin rex, jalankan `curl -I` ke alamat itu: jawaban HTTP apa pun, termasuk `401`, itu baik-baik saja; `Failed to connect` berarti rex tidak bisa mencapai aplikasimu di sana. Aplikasimu harus mendaftarkan alamat yang bisa diakses dari mesin rex: alamat `172.` adalah milik container, yang hanya bisa dijangkau rex dari mesin Linux yang sama. Build yang lebih baru langsung memberi tahu: rex mencatat `SOURCES <name>: cannot reach ... from this machine` |
| Log rex menampilkan `upstream failed: no source ... configured` | rex tidak punya pendaftaran dari aplikasimu. Minta aplikasimu mendaftar lagi: restart rex |
| Log rex menampilkan `part ... is unavailable upstream` | Aplikasimu menjawab 404 untuk file itu: sekarang aplikasinya tidak memilikinya |
| Tidak ada yang bisa diputar, muncul 401 atau 403 | Aplikasimu menolak login-nya sendiri. Minta aplikasimu mendaftar ulang dengan login yang berlaku |
| Snapshot dijawab 409 `would remove more than half` | Ini adalah penjaga rex terhadap aplikasi yang mengirim library setengah termuat. Jika penghapusannya memang benar, aplikasimu harus mengirim ulang seluruh snapshot dari part 0, dengan `"force": true` pada part terakhir. Mengirim ulang hanya part terakhir akan ditolak, dan mengirimnya sebagai snapshot baru dengan `force` akan menghapus semua yang disebut oleh part sebelumnya |
| Menghapus di aplikasi Plex gagal dan log rex menulis `DELETE refused by the source` | Aplikasimu tidak menerima `DELETE` untuk file itu. Hapus filenya di aplikasimu saja |
| Hanya sebagian file yang gagal dengan "This server is not powerful enough to convert video", sering hanya di browser web | Perangkat tidak bisa memutar file itu apa adanya. Coba aplikasi Plex di TV atau HP, atau atur [Mengonversi video](#converting-video-optional) |
| File Dolby Vision gagal dan log rex menulis `DoVi (Profile 5) color space is not supported` | rex tidak punya FFmpeg, atau FFmpeg-nya bukan jellyfin-ffmpeg. Pasang jellyfin-ffmpeg seperti yang ditunjukkan [Mengonversi video](#converting-video-optional), dan biarkan **Enable HDR tone mapping** aktif (Settings, Transcoder) |
| rex keluar dengan `cannot bind ...:32400 (another rex or Plex on this port? ...)` | Program lain memakai port itu. Plex Media Server di mesin ini: gunakan `--port 32500` seperti yang disebut [langkah 1](#step-1-install-rex). Rex lain, misalnya yang kamu jalankan manual: hentikan yang itu |
| Perangkat di rumah tidak bisa terhubung, dan baris `heartbeat ... ->` di log rex tidak menampilkan `http://192.168.1.20:32400` | rex mengumumkan alamat privat dari jaringan yang dilaluinya ke internet; di balik VPN atau Tailscale exit node, itu bukan jaringan rumahmu. Tambahkan `--announce-url http://192.168.1.20:32400` di akhir perintah start rex ([langkah 1](#step-1-install-rex)), lalu restart rex |
| Di rumah, app.plex.tv tidak bisa mencapai rex, dan alamat `lan.` dari [Yang seharusnya kamu lihat](#what-you-should-see) tidak merespons | Beberapa router dan filter DNS memblokir nama publik yang mengarah ke alamat rumah (DNS rebind protection). Izinkan `rex-direct.debridmediamanager.com` di sana, seperti pengguna Plex mengizinkan `plex.direct` |
| Mesin lain tidak bisa mencapai rex di Windows, padahal aturan firewall dari langkah 1 sudah ada | Jika kamu pernah mengklik **Cancel** saat Windows menanyakan apakah mengizinkan rex, Windows menyimpan aturan yang memblokirnya, dan aturan itu mengalahkan aturan port. Hapus di PowerShell sebagai administrator: <code>Get-NetFirewallApplicationFilter -Program "$HOME\rex\rex.exe" &#124; Get-NetFirewallRule &#124; Where-Object Action -eq Block &#124; Remove-NetFirewallRule</code> (jika rex ada di tempat lain, gunakan path-nya sendiri) |
| rex tidak muncul di aplikasi Plex saat kamu di luar rumah | Belum diklaim, atau perangkat tidak bisa mencapai alamat HTTPS ([rex-direct melalui IPv6](#rex-direct-over-ipv6) membutuhkan IPv6 di jaringan perangkat itu) |
| rex keluar dengan `argument --announce-url: '...' is not an http:// or https:// address` | Berikan `--announce-url` hanya alamatnya, seperti `https://myhost.tailnet.ts.net:443`: tanpa tanda kurung, tanda kutip, atau link di sekitarnya |
| rex berhenti saat kamu logout | Di Linux, jalankan `sudo loginctl enable-linger "$USER"` (langkah 1). Di macOS dan Windows, rex yang diatur seperti di langkah 1 berjalan selama kamu sedang login |
