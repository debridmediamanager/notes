# Aplikasi mengunduh dari penyedia Anda {#apps-download-from-your-provider}

Biasanya rex membaca setiap film dari sumbernya lalu meneruskannya ke Plex. Jika sumber mengembalikan tautan file seperti
tautan unduhan debrid, rex bisa menyerahkannya langsung ke Plex. Plex kemudian mengunduh file tersebut dan mesin rex tidak membawa media apa pun.

Cara ini hanya berfungsi jika Plex bisa direct play file tersebut. Apa pun yang harus dikonversi oleh rex tetap melewati rex, atau ditolak jika Anda memilihnya.

Diuji pada 2026-10-25 dengan zurg di Real-Debrid, Plezy dan Plex untuk Android di Pixel 6, serta Plex Web di Chrome.

## Sebelum kamu mulai {#before-you-start}

**Tetap pakai mode proxy default untuk playback debrid yang dibagi.** Redirect bukan cara yang aman untuk berbagi satu akun debrid:

- **Real-Debrid melacak IP publik setiap downloader.** Pemakaian satu akun dari banyak IP bisa memicu peringatan berbagi akun, meskipun CDN berhasil menyajikan file. Pastikan semua pemakaian akun itu lewat satu IP publik. App remote yang download langsung, sementara rex atau source-nya melakukan probe atau konversi dari IP server, melanggar aturan ini. Playback yang berhasil tidak membuktikan bahwa cara itu aman.
- **URL download TorBox berisi API key lengkap di `?token=`.** Dengan redirect, setiap client dan akun user yang dibagi akan punya akses penuh, termasuk menghapus, bukan hanya akses ke file itu. Log player dan riwayat browser bisa menyimpan key tersebut. Jangan berikan link ini ke client yang tidak tepercaya.

Lanjutkan hanya jika risiko ini bisa kamu terima. Dengan mempertahankan mode proxy default, rex sendiri mengikuti redirect dari source, alih-alih memberikan link provider ke app.

| Yang kamu butuhkan | Alasannya |
|---|---|
| rex sudah diatur seperti di [rex dengan app kamu sendiri](any-source.md), [rex dengan addon Stremio kamu](stremio.md) atau [rex dengan zurg](with-zurg.md), dan satu film bisa diputar | Halaman ini mengubah start command rex dan, untuk beberapa source, satu setting dari source tersebut |
| rex nightly **2026.10.26 atau lebih baru** | Build lama tidak punya setting ini. Perbarui seperti di bagian [Memperbarui di rex](any-source.md#updating) |
| Source yang bisa menjawab dengan link | rex hanya bisa meneruskan link yang diberikan source. [Langkah 1](#step-1-let-your-source-hand-out-links) menjelaskan source mana yang mendukung ini |

## Pilih seberapa ketat {#choose-how-strict}

| | `redirect` | `redirect-only` |
|---|---|---|
| Aplikasi memutar file apa adanya | Aplikasi mengunduh dari penyedia Anda | Aplikasi mengunduh dari penyedia Anda |
| Aplikasi butuh file dikonversi (kualitas lebih rendah, audio yang tidak bisa diputar, subtitle yang sudah menempel di video) | rex mengonversinya, membaca file dari sumber Anda seperti sebelumnya | Ditolak: aplikasi menampilkan error |
| File yang dikirim sumber Anda langsung, bukan lewat link (misalnya file Usenet milik zurg) | Diputar lewat rex seperti sebelumnya | Ditolak |
| Plex Web | Diputar, lewat rex | Semua file Real-Debrid ditolak (lihat di bawah) |

Pilih `redirect` kalau Anda ingin semuanya tetap bisa diputar dan tetap hemat sebisa mungkin. Pilih `redirect-only` kalau mesin rex tidak boleh sama sekali membawa film, misalnya VPS kecil dengan batas kuota data.

Apa pun pilihan Anda, setiap aplikasi dan orang yang Anda bagikan rex kepadanya akan mendapat link yang diberikan sumber Anda ke rex untuk apa pun yang mereka putar, dan layanan di balik link itu, misalnya layanan debrid Anda, akan melihat setiap dari mereka mengunduhnya.

## Langkah 1. Biarkan sumber Anda memberikan tautan {#step-1-let-your-source-hand-out-links}

**Apa fungsinya.** Sumber Anda menjawab setiap pembacaan dengan tautan ke file di tempat lain (HTTP redirect), bukan file itu sendiri.

**Mengapa ini penting.** rex hanya bisa meneruskan tautan yang diberikan sumbernya. Sumber yang mengirim file langsung akan tetap dikirim melalui rex.

| Sumber | Yang harus dilakukan |
|---|---|
| [rex-stremio](stremio.md) | Tidak ada yang perlu dilakukan: sumber ini menjawab dengan tautan yang diberikan addon stream. Tautan yang memerlukan header sendiri, dan playlist live, tetap dikirim sendiri |
| [zurg](with-zurg.md) | Aktifkan `disable_stream_proxy`, lihat di bawah. zurg tidak punya tautan untuk file Usenet, jadi file tersebut selalu dikirim sendiri |
| [Aplikasi Anda sendiri](any-source.md) | Jawab `GET` file dengan `302` atau `307` ke tautan tersebut |

### zurg

Pengaturan ini ada di config zurg, jadi apa pun yang membaca zurg (rclone, server Plex atau Jellyfin di mount zurg) ikut mendapat tautannya. Detailnya ada di [referensi config](../zurg/reference/config.md) zurg.

+++ Linux dan macOS
Cek dulu apakah pengaturan itu sudah ada di config zurg:

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

Kalau mencetak satu baris, ubah baris itu jadi `disable_stream_proxy: true` dengan `nano ~/zurg/config.yml`. Kalau tidak mencetak apa-apa, tambahkan baris itu:

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Buka config zurg dengan `notepad $HOME\zurg\config.yml`. Kalau ada baris `disable_stream_proxy:`, ubah jadi `disable_stream_proxy: true`; kalau tidak ada, tambahkan baris itu di akhir. Simpan, lalu restart zurg:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
Di folder zurg:

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

Kalau mencetak satu baris, ubah dengan `sudo nano config.yml`. Kalau tidak:

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**Yang harus kamu lihat.** zurg start lagi seperti biasa. Film masih diputar lewat rex di tahap ini: rex sendiri mengikuti tautannya sampai langkah 2.

## Langkah 2. Biarkan rex meneruskan tautannya {#step-2-let-rex-pass-the-links-on}

**Apa fungsinya.** rex memberikan link dari sumbermu langsung ke aplikasi, alih-alih mengunduh film untuknya.

Tambahkan `--part-mode redirect` (atau `--part-mode redirect-only`) di akhir perintah start rex, lalu restart rex dan buka log-nya. [Install rex](any-source.md#step-1-install-rex) menunjukkan di mana perintah start berada di sistemmu dan cara merestart rex serta melihat log-nya. Di Linux, baris `ExecStart` di `~/.config/systemd/user/rex.service` kemudian akan terbaca seperti ini, tanpa tambahan apa pun:

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

Pertahankan apa pun yang sudah ada di baris itu, seperti `--port 32500` atau `--announce-url ...`.

**Apa yang harus kamu lihat.** Baris start berakhir dengan `parts=redirect`:

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

Dengan `redirect-only`, barisnya berakhir dengan `parts=redirect-only`, dan beberapa baris di atasnya rex menulis `transcoder off: --part-mode redirect-only`.

## Langkah 3. Putar sesuatu {#step-3-play-something}

Biarkan log rex tetap terbuka, lalu putar film di Plezy atau Plex untuk Android.

**Yang harus kamu lihat.** Untuk setiap pembacaan yang dilakukan aplikasi, akan muncul satu baris yang menyebut server penyedia kamu:

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

Itu artinya rex meneruskan aplikasi ke server dari link tersebut, di sini server Real-Debrid. Jika yang muncul adalah baris yang berakhir dengan `-> 206 len=...`, artinya rex mengirim film itu sendiri: lihat [Jika tidak berhasil](#if-it-does-not-work).

## Apa fungsi tiap aplikasi {#what-each-app-does}

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | Diunduh dari penyedia kamu | Diunduh dari penyedia kamu |
| Plex for Android, Original quality | Diunduh dari penyedia kamu, saat rex membiarkan file diputar apa adanya | Sama |
| Plex for Android, kualitas lebih rendah, atau audio yang tidak bisa diputar | rex mengonversinya | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | Diputar lewat rex | "Playback Error: This server is not powerful enough to convert video." |

Plex Web sama sekali tidak bisa memakai tautan Real-Debrid: Real-Debrid menandai filenya sebagai unduhan, bukan video, jadi browser menolak memutarnya. Di bawah `redirect`, Plex Web diam-diam beralih ke konversi lewat rex dalam satu detik, jadi tetap berfungsi; di bawah `redirect-only`, tidak ada yang bisa jadi cadangan.

## Di Docker {#in-docker}

Jika kamu sudah mengikuti [rex di Docker](any-source.md#run-rex-in-docker), langkah 2 adalah baris `command:` di bawah `rex:` dalam `compose.yml` milik rex, di sebelah `image:`:

```yaml
    command: --part-mode redirect
```

Sudah punya `command: --port 32500`? Ubah jadi `command: --port 32500 --part-mode redirect`. Lalu jalankan `docker compose up -d` di folder rex, dan `docker compose logs -f rex` akan menampilkan baris `parts=redirect` yang sama.

## Jika tidak berhasil {#if-it-does-not-work}

| Yang kamu lihat | Artinya |
|---|---|
| rex keluar dengan `invalid choice` untuk `--part-mode` | rex lebih lama dari 2026.10.26. Perbarui sesuai [bagian Pembaruan rex](any-source.md#updating) |
| Log rex menampilkan `-> 206 len=...` untuk setiap pembacaan | Sumbernya masih mengirim file itu sendiri. Dengan zurg: `disable_stream_proxy: true` tidak ada di konfigurasi zurg, atau zurg belum di-restart setelah langkah 1 |
| `-> 206 len=...` hanya untuk beberapa judul | Sumbernya mengirim judul-judul itu sendiri: file Usenet dari zurg, atau tautan rex-stremio yang harus diteruskan rex |
| `-> 403: the source answered with the bytes, not a link` | `redirect-only` menolak file yang dikirim sumbernya sendiri, dengan alasan yang sama seperti di atas |
| Tidak ada baris `PART` sama sekali saat film diputar | Aplikasinya memutar hasil konversi, bukan file aslinya. Atur kualitasnya ke Original |

Masih bingung? Tanyakan di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Cara meminta bantuan](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Kembali {#going-back}

Hapus `--part-mode ...` dari perintah start rex (atau baris `command:` di Docker) lalu restart rex. Sumber Anda tetap bisa memberikan link: dengan pengaturan rex yang sudah dihapus, rex akan mengikuti link tersebut sendiri. Untuk zurg, atur `disable_stream_proxy` kembali ke `false` lalu restart zurg, maka zurg akan kembali meneruskan file sendiri, untuk rclone dan apa pun yang lain yang membacanya juga.
