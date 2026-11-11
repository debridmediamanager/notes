# Tutorial macOS {#macos-tutorial}

## Opsi satu baris {#one-line-option}

Bootstrap sponsor opsional akan memasang macFUSE jika diperlukan, mengunduh build Intel atau Apple silicon, lalu menjalankan pemilih provider dan diagnostik:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Ini memakai login browser GitHub. macOS mungkin masih perlu persetujuan di **System Settings > Privacy & Security** dan restart. Binary dan config yang sudah ada tetap dibiarkan. Lanjutkan ke bawah untuk cara manual.

## Langkah 1: Pasang macFUSE {#step-1-install-macfuse}

macFUSE memungkinkan rclone me-mount sistem file virtual zurg sebagai direktori sungguhan di Mac kamu.

1. Unduh `.dmg` terbaru dari [macfuse.io](https://macfuse.io)
2. Buka `.dmg` lalu jalankan installer-nya
3. Selama instalasi, macOS akan memblokir system extension. Buka **System Settings > Privacy & Security**, scroll ke bawah, lalu klik **Allow**
4. **Restart Mac kamu** (wajib agar kernel extension bisa dimuat)

Setelah restart, buka **Terminal** (tekan `Cmd + Space`, ketik "Terminal", tekan Enter) lalu cek apakah macOS akan memuat macFUSE. Ini pengecekan yang sama dengan yang dilakukan `zurg setup`:

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

Jika `macFUSE is ready` tidak muncul, berarti macOS belum mengizinkan extension-nya. Di Apple silicon, aktifkan third-party kernel extensions di Recovery, izinkan macFUSE di **System Settings > Privacy & Security**, lalu restart dan cek lagi.

## Langkah 2: Unduh zurg {#step-2-download-zurg}

Buka [GitHub Releases](https://github.com/debridmediamanager/zurg/releases) di browser yang sudah kamu login dengan akun GitHub yang punya akses ke zurg. Ambil nightly terbaru. Itu pre-release yang ada paling atas di daftar. Ambil zip `darwin-arm64`-nya, atau `darwin-amd64` kalau pakai Mac Intel. Jangan ambil release yang ditandai **Latest** oleh GitHub. Itu v1.0.0. Versi itu lebih lama dari `zurg setup` dan akan membalas `unknown command`.

Nightly itu khusus untuk sponsor. Sampai akun GitHub kamu punya akses, halaman itu akan menampilkan 404. Jadi sponsor dulu di [gatekeeper](https://gatekeeper.debridmediamanager.com/) untuk memberi akses. Build publik gratis adalah v1.0.0 dari [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Versi itu tidak punya `zurg setup`. Pasang secara manual seperti yang dijelaskan di [README-nya](https://github.com/debridmediamanager/zurg-public#readme), jangan ikuti langkah di bawah ini.

Lalu ekstrak.

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

Verifikasi:

```bash
./zurg version
```

## Disarankan: biarkan zurg menyelesaikan pengaturan {#recommended-let-zurg-finish-the-setup}

Dari direktori hasil ekstrak, jalankan:

```bash
./zurg setup
./zurg doctor
```

`setup` akan menanyakan provider mana yang mau dikonfigurasi. Pilih satu atau beberapa dari Real-Debrid, TorBox, AllDebrid, Usenet, Premiumize, Debrid-Link dan Offcloud sesuai urutan prioritas. Misalnya, masukkan `2,4` untuk TorBox lalu Usenet. Setup hanya meminta kredensial untuk provider yang dipilih, membuat `config.yml` dengan mode `0600`, mengunduh rclone (dan ffprobe, kecuali sudah ada di PATH kamu), menyiapkan `/Volumes/Zurg` dan memasang auto-start.

Setup memilih LaunchAgent jika user yang sedang login punya domain launchd GUI. Di Mac headless tanpa user GUI yang login, setup memasang LaunchDaemon sistem yang tetap menjalankan zurg sebagai user saat ini. Jalur ini tidak memerlukan auto-login.

Pemeriksaan prasyarat membedakan paket macFUSE yang sudah terpasang dengan ekstensi yang benar-benar bisa dimuat macOS. Di Apple silicon, instalasi macFUSE pertama mungkin masih memerlukan perubahan keamanan Recovery satu kali, persetujuan di **System Settings > Privacy & Security** dan reboot. Tidak ada installer yang bisa melewati konfirmasi tersebut.

Setup aman dijalankan ulang. Setup akan memperbarui service launchd yang dibuat, tetapi tidak mengganti `config.yml` yang sudah ada.

Sebelum streaming lewat mount, buka `config.yml` atau Dashboard di `http://localhost:9999/config/` dan atur `--vfs-cache-max-size` serta `--vfs-cache-min-free-space` di bawah `rclone_extra_args`. Jaga batas maksimum tetap di bawah setengah ruang disk kosong saat ini, dan sisakan minimal `20G` lewat setting `--vfs-cache-min-free-space`. Lalu jalankan `./zurg service restart`.

Sisa halaman ini menjelaskan konfigurasi dan setup Plex. Langkah 3, 4, 5 dan 7 adalah alternatif manual dan boleh dilewati setelah `zurg setup` berhasil.

## Langkah 3: Konfigurasi zurg secara manual {#step-3-configure-zurg-manually}

Buat file konfigurasi dengan API token Real-Debrid kamu:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

Ganti token placeholder dengan token asli kamu dari [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354):

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **Jangan hapus `mount_path`.** rclone akan memakai `/Volumes/Zurg` di macOS jika tidak diisi, tetapi pemindaian media server hanya aktif kalau `mount_path` diisi secara eksplisit. Kalau dihilangkan, Plex tidak akan pernah diberi tahu untuk refresh (Langkah 6).

> **Ukuran cache itu penting.** VFS cache menyimpan potongan file yang di-stream ke disk lokal kamu. Kalau disk penuh, performa macOS akan turun drastis. Spotlight, Plex, bahkan sistem operasi bisa jadi tidak responsif. Selalu atur **kedua** batas berikut:
>
> - `--vfs-cache-max-size`: batas maksimal total ukuran cache. Atur nilainya **tidak lebih dari 50% ruang kosong disk** kamu. Cek dengan `df -h /`.
> - `--vfs-cache-min-free-space`: cache berhenti menyimpan data kalau ruang kosong turun di bawah nilai ini. Atur minimal **20G atau lebih** sebagai pengaman.
>
> Misalnya, di disk 256GB dengan 100GB kosong, pakai `50G` untuk max size dan `20G` untuk min free space.

## Langkah 4: Unduh dependensi secara manual {#step-4-download-dependencies-manually}

zurg punya perintah bawaan yang men-download rclone dan ffprobe, lalu memperbarui `config.yml` dengan path-nya:

```bash
cd ~/zurg
./zurg download-requirements
```

Buat mount point dan direktori log. `/Volumes` dimiliki oleh root, jadi zurg tidak bisa membuat `/Volumes/Zurg` sendiri. Direktori log harus sudah ada sebelum launchd membuka file output-nya di Langkah 7:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

Lihat [referensi konfigurasi](../reference/config.md) untuk semua opsi yang tersedia, atau gunakan web Dashboard di `http://localhost:9999/config/` setelah menjalankan zurg.

## Langkah 5: Uji zurg secara manual {#step-5-test-zurg-manually}

Sebelum mengatur auto-start, pastikan semuanya berfungsi:

```bash
cd ~/zurg && ./zurg
```

Kamu harus melihat log yang menampilkan zurg mulai berjalan, terhubung ke Real-Debrid, dan di-mount lewat rclone. Di jendela terminal lain, cek dengan:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

Kalau semuanya sudah oke, hentikan zurg dengan `Ctrl+C`.

## Langkah 6: Pasang Plex Media Server {#step-6-install-plex-media-server}

1. Unduh dari [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/), lalu pilih **macOS** (Universal)
2. Buka file `.dmg` lalu seret **Plex Media Server** ke `/Applications`
3. Jalankan Plex Media Server dari Applications (atau lewat Spotlight: `Cmd + Space` → "Plex Media Server")
4. Browser kamu seharusnya otomatis terbuka ke setup wizard Plex. Ikuti langkahnya untuk mengklaim server kamu
5. **Aktifkan auto-start:** Klik kanan ikon Plex di menu bar, lalu centang **Launch at Login**
6. Dapatkan Plex token kamu. Cara termudah:
   - Buka media apa pun di Plex Web
   - Klik **Get Info** (atau **...** → **Get Info**)
   - Klik **View XML**
   - Cari `X-Plex-Token=` di bilah URL

Tambahkan Plex token ke config zurg kamu dengan mengedit `config.yml`:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## Langkah 7: Atur auto-start zurg secara manual {#step-7-set-up-zurg-auto-start-manually}

macOS LaunchAgents memulai layanan secara otomatis saat kamu login. Plex sudah menangani auto-start-nya sendiri (Langkah 6), jadi kita hanya perlu LaunchAgent untuk zurg.

### LaunchAgent zurg {#zurg-launchagent}

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

Pengaturan penting:
- **RunAtLoad** — memulai zurg saat kamu login
- **KeepAlive / SuccessfulExit: false** — jika zurg crash, launchd otomatis memulainya lagi
- **ThrottleInterval: 10** — menunggu 10 detik di antara percobaan restart

### Muat LaunchAgent {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Pastikan sudah terdaftar:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## Langkah 8: Konfigurasi Library Plex {#step-8-configure-plex-libraries}

Sekarang setelah zurg berjalan dan mount-nya aktif:

1. Buka [http://localhost:32400/web](http://localhost:32400/web)
2. Masuk ke **Settings** (ikon kunci inggris) → **Manage** → **Libraries**
3. Klik **Add Library**

**Tambahkan library Movies:**
- Type: **Movies**
- Klik **Browse for media folder**
- Navigasi ke `/Volumes/Zurg/movies`
- Klik **Add Library**

**Tambahkan library TV Shows:**
- Type: **TV Shows**
- Klik **Browse for media folder**
- Navigasi ke `/Volumes/Zurg/shows`
- Klik **Add Library**

**Pengaturan library yang disarankan** (di bawah Edit → Advanced untuk setiap library):
- Hilangkan centang **Empty trash automatically after every scan** — zurg yang mengatur siklus hidup konten
- Hilangkan centang **Generate video preview thumbnails** — menghemat bandwidth karena file di-stream dari Real-Debrid

## Langkah 9: Pastikan Semuanya Berfungsi {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## Langkah 10: Aktifkan Auto-Login (Opsional) {#step-10-enable-auto-login-optional}

Ini hanya diperlukan untuk jalur LaunchAgent manual. LaunchAgent mengharuskan pengguna login setiap kali reboot. Installer bawaan justru memakai LaunchDaemon di Mac headless.

Jika Anda memang sengaja memakai LaunchAgent manual di server headless, aktifkan auto-login supaya bisa berjalan tanpa pengawasan:

1. Buka **System Settings**
2. Masuk ke **Users & Groups**
3. Klik **Automatic login** lalu pilih user Anda
4. Masukkan password Anda

> **Catatan keamanan:** Auto-login berarti siapa pun yang punya akses fisik ke Mac bisa mengakses akun Anda. Gunakan ini hanya di mesin yang berada di lokasi tepercaya.

---

## Mengelola Layanan {#managing-the-services}

Untuk instalasi yang dibuat oleh `zurg setup`, pakai perintah yang sama di semua platform:

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` hanya menghapus auto-start. Binary, config, data, log, dan cache tetap dibiarkan. Perintah launchctl di bawah ini untuk LaunchAgent manual dari Langkah 7 (`com.zurg`). `zurg setup` memakai nama sendiri, yaitu `com.zurg.zurg`.

### Start / Stop / Restart

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Lihat Log {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### Muat Ulang Setelah Perubahan Konfigurasi {#reload-after-config-change}

Jika Anda mengedit file `.plist`:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

Jika Anda mengedit `config.yml`, cukup restart zurg:

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### Perbarui zurg {#update-zurg}

Build sponsor akan memperbarui dirinya sendiri:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` mengambil nightly terbaru. Ia mengunduhnya, memeriksa apakah binary baru melaporkan versi yang diharapkan, dan baru kemudian menggantinya dengan rename, sehingga proses yang sedang berjalan tidak pernah tertimpa. Kalau build yang terpasang sudah yang terbaru, ia memberi tahu dan tidak mengubah apa pun.

`update` masuk ke GitHub memakai akun yang kamu gunakan saat instalasi. Installer menyimpan GitHub CLI di `~/zurg/bin` untuk keperluan itu. Kalau `update` bilang tidak menemukan GitHub credential, berarti instalasimu lebih lama dari perubahan itu. Jalankan update installer sekali, dan setiap `zurg update` setelahnya akan berjalan. Perintah yang sama juga memperbarui build yang terlalu lama untuk punya `zurg update`.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Kamu juga bisa mengatur `GITHUB_TOKEN` sebagai gantinya. Gunakan classic token dengan scope `repo` dari akun GitHub yang punya akses ke zurg.

Secara manual, unduh zip `darwin-arm64` yang baru (`darwin-amd64` untuk Mac Intel) dari [Releases](https://github.com/debridmediamanager/zurg/releases) dengan cara yang sama seperti di Langkah 2, lalu:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

Hapus binary lama alih-alih menimpanya di tempat yang sama. Menulis ulang file membuat inode-nya tetap sama dan membatalkan tanda tangan kode ad-hoc-nya, lalu macOS akan membunuh build baru saat exec. Gejalanya: langsung keluar tanpa output apa pun. `zurg update` memakai rename justru karena alasan ini.

## Pemecahan masalah {#troubleshooting}

### "Operation not permitted" saat mount {#operation-not-permitted-when-mounting}

macFUSE perlu disetujui di System Settings:
1. Buka **System Settings > Privacy & Security**
2. Gulir ke bawah dan cari pesan blocked system extension
3. Klik **Allow**, lalu **reboot**

### Mount tampil sebagai "not a directory" atau macet {#mount-shows-as-not-a-directory-or-hangs}

Titik mount mungkin masih tersisa (stale) dari crash sebelumnya:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg terus restart (crash loop) {#zurg-keeps-restarting-crash-loop}

Cek log untuk error-nya:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

Penyebab umum:
- Sintaks `config.yml` salah. Validasi secara manual dengan `cd ~/zurg && ./zurg`
- Token Real-Debrid kedaluwarsa. Ambil yang baru dari [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410)
- `/Volumes/Zurg` tidak ada atau tidak dimiliki oleh user kamu. zurg tidak bisa membuatnya dan gagal dengan `ensure mount path: permission denied` (Langkah 4)
- Port 9999 sudah dipakai. Cek dengan `lsof -i :9999`

### macFUSE rusak setelah pembaruan macOS {#macfuse-breaks-after-macos-update}

Pembaruan besar macOS terkadang membuat kernel extension tidak berfungsi lagi. Instal ulang macFUSE:
1. Unduh versi terbaru dari [macfuse.io](https://macfuse.io)
2. Instal
3. Setujui extension di **System Settings > Privacy & Security**
4. Restart

### Semuanya berjalan tapi berhenti setelah reboot {#everything-was-working-but-stopped-after-reboot}

Jika Anda memasang LaunchAgent manual dan auto-login tidak diaktifkan, Anda harus login dulu sebelum LaunchAgent itu berjalan. Pilih salah satu:

- Aktifkan auto-login (lihat Langkah 10)
- SSH masuk — LaunchAgent akan otomatis dimuat begitu sesi pengguna sudah ada
- Gunakan VNC/Screen Sharing untuk login dari jarak jauh

Instalasi yang dibuat oleh `zurg setup` di Mac tanpa layar (headless) memakai LaunchDaemon dan tidak memerlukan login GUI. Periksa dengan `cd ~/zurg && ./zurg service status`.

Masih mengalami kendala? Tanyakan di forum **zurg-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Gambaran Arsitektur {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## Referensi Cepat {#quick-reference}

Jalankan perintah-perintah ini di `~/zurg`. Perintah `zurg service` untuk instalasi yang dibuat dengan `zurg setup`. Kalau kamu pakai LaunchAgent manual, gunakan perintah launchctl di [Mengelola Layanan](#managing-the-services).

| Aksi | Perintah |
|--------|---------|
| Jalankan zurg | `./zurg service start` |
| Hentikan zurg | `./zurg service stop` |
| Mulai ulang zurg | `./zurg service restart` |
| Cek instalasi | `./zurg doctor` |
| Hapus auto-start | `./zurg service uninstall` |
| Lihat log zurg | `tail -f ~/zurg/logs/zurg.log` |
| Lihat log rclone | `tail -f ~/zurg/logs/rclone.log` |
| Cek mount | `ls /Volumes/Zurg/` |
| Cek kesehatan zurg | `curl http://localhost:9999/http/version.txt` |
| Cek kesehatan Plex | `curl http://localhost:32400/identity` |
| Dashboard | `open http://localhost:9999/config/` |
| Paksa unmount | `umount -f /Volumes/Zurg` |
