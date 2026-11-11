# Setup binary Linux {#linux-binary-setup}

## Opsi satu baris {#one-line-option}

Bootstrap sponsor opsional akan memasang paket sistem, mengunduh build CPU yang sesuai, lalu menjalankan setup dan diagnostik:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

Proses ini masuk lewat GitHub dan memasang ke `~/zurg`. Binary dan config yang sudah ada tetap dibiarkan. Lanjutkan di bawah untuk
rute manual atau path kustom.

Binary zurg bisa membangun sisa instalasinya sendiri. Ia menulis config, mengunduh rclone yang benar (dan ffprobe, kecuali sudah ada di PATH Anda) untuk mesin tersebut, membuat mount, dan mendaftarkan service systemd yang diaktifkan.

Alur ini sudah diverifikasi pada 4 September 2026 di server Ubuntu 24.04 ARM64 dan x86_64 yang baru.

## 1. Pasang FUSE 3 {#1-install-fuse-3}

Pada Debian, Ubuntu, dan turunannya:

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

Distro lain juga memakai nama paket `fuse3`: `sudo dnf install fuse3` di Fedora, `sudo pacman -S fuse3` di Arch, `sudo zypper install fuse3` di openSUSE.

Pastikan helper dan device-nya sudah ada:

```bash
command -v fusermount3
test -c /dev/fuse
```

Jika Plex, Jellyfin, atau proses lain berjalan sebagai pengguna Unix yang berbeda, aktifkan `allow_other` sekali saja:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

Tanpa pengaturan itu, mount tetap berfungsi, tetapi hanya akun yang menjalankan zurg yang bisa membukanya. `zurg doctor` menampilkan perbedaannya.

## 2. Unduh zurg {#2-download-zurg}

Unduh arsip Linux yang sesuai dari [rilis sponsor](https://github.com/debridmediamanager/zurg/releases). Pilih `linux-amd64` untuk mesin Intel atau AMD, dan `linux-arm64` untuk mesin ARM.

Ambil nightly terbaru. Itu adalah pre-release di urutan paling atas. Jangan ambil rilis yang diberi tanda **Latest** oleh GitHub. Itu adalah v1.0.0. Versi itu lebih lama dari `zurg setup` dan akan membalasnya dengan `unknown command`.

Nightly hanya untuk sponsor. Sampai akun GitHub kamu punya akses, halaman itu akan menampilkan 404. Jadi sponsor dulu di [gatekeeper](https://gatekeeper.debridmediamanager.com/) untuk memberi akses. Build publik gratis adalah v1.0.0 dari [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). Build itu tidak punya `zurg setup`. Atur secara manual sesuai [README-nya](https://github.com/debridmediamanager/zurg-public#readme), jangan ikuti langkah di bawah ini.

Ekstrak ke direktori yang seharusnya menampung seluruh instalasi:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

Semua yang disimpan zurg tetap berada di samping binary itu: `config.yml`, helper yang diunduh, status library, log, dan cache rclone.

## 3. Jalankan setup {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

Setup akan menanyakan provider mana yang ingin dikonfigurasi. Pilih satu atau beberapa dalam urutan prioritas:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

Misalnya masukkan `2,4` untuk TorBox lalu Usenet. Setup hanya meminta kredensial untuk provider yang dipilih. Setelah itu, ia akan:

1. Membuat dan memvalidasi `config.yml`.
2. Membatasi akses config hanya untuk pemiliknya dengan mode `0600`.
3. Mengunduh rclone native ke `bin/`, dan ffprobe juga, kecuali sudah ada di PATH kamu.
4. Mengaktifkan mount rclone di `/mnt/zurg`.
5. Memasang dan menjalankan service systemd yang sudah diaktifkan.

Gunakan mount di dalam home directory kamu jika kamu tidak punya izin untuk membuat `/mnt/zurg`:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

Setup aman dijalankan ulang. Setup akan memperbarui service yang dibuat, tetapi tidak menggantikan `config.yml` yang sudah ada.

### Memilih scope systemd {#choosing-the-systemd-scope}

Dengan systemd user manager yang berjalan, scope default `auto` akan memasang `~/.config/systemd/user/zurg.service`. Jika tidak, setup akan memasang `/etc/systemd/system/zurg.service` dan meminta sudo untuk menjalankannya sebagai user yang sedang aktif.

Pilih secara eksplisit jika diperlukan:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

Agar user service bisa jalan sebelum login pertama setelah reboot, aktifkan lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

Menjalankan setup sebagai `root` di server akan memilih system service yang dimiliki root.

## 4. Verifikasi instalasi {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

`doctor` memeriksa konfigurasi dan izinnya, kedua tool yang diunduh, FUSE, unit systemd, endpoint HTTP, dan mount yang dilaporkan oleh zurg.

Library Real-Debrid yang besar butuh waktu untuk dibangun pada run pertama. Service bisa saja sudah active, sementara daftar mount pertama masih menunggu scan itu selesai.

`version.txt` akan merespons begitu zurg berjalan. Library yang besar tetap dimuat setelah itu. Folder-foldernya akan muncul kosong atau sebagai `Input/output error` sampai prosesnya selesai. `/ready` akan memberitahumu kapan itu terjadi.

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## Disk yang dipakai mount {#disk-the-mount-uses}

Mount ini men-cache setiap file yang dibacanya di `~/zurg/data/rclone-cache`. Setelah pemutaran selesai, seluruh file tetap disimpan. Kalau dibiarkan, cache itu terus membesar sampai **256G** dan tidak berkurang. Cache juga tidak dibersihkan saat video berhenti. Batas umur 72h juga tidak akan menolong. rclone menganggap sebuah file baru diakses setiap kali ada yang membacanya, dan proses perawatan malam harian dari media server membaca seluruh library.

Cek isinya dulu.

```bash
du -sh ~/zurg/data/rclone-cache
```

Kalau 256G terlalu besar untuk ruang disk kamu, batasi lebih kecil di `config.yml`.

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Restart zurg setelahnya. Untuk mengosongkannya secara manual, hentikan zurg dulu, lalu jalankan perintah ini.

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

Memindahkan direktori zurg akan mengganti nama cache dan meninggalkan salinan lama. zurg akan membersihkannya saat start berikutnya dan mencatat berapa banyak ruang yang dibebaskan. Detail dan cara opt-out ada di [referensi konfigurasi](../reference/config.md#disk-the-mount-uses).

## Mengelola zurg {#managing-zurg}

Jalankan perintah-perintah ini dari direktori zurg:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

`uninstall` hanya menghapus auto-start. Binary, config, data, log, dan cache tetap ada di tempatnya.

Untuk memantau log layanan pengguna (user service):

```bash
journalctl --user -u zurg.service -f
```

Untuk layanan sistem (system service):

```bash
sudo journalctl -u zurg.service -f
```

## Memperbarui zurg {#updating-zurg}

Build sponsor memperbarui dirinya sendiri:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

`update` mengambil nightly terbaru. Perintah ini mengunduhnya, memeriksa apakah binary baru melaporkan versi yang diharapkan, lalu baru menggantinya dengan rename, sehingga proses yang sedang berjalan tidak pernah tertimpa. Jika build yang terpasang sudah yang terbaru, perintah ini akan memberi tahu dan tidak mengubah apa pun.

`update` masuk ke GitHub dengan akun yang kamu pakai saat instalasi. Installer menyimpan GitHub CLI di `~/zurg/bin` untuk keperluan ini. Jika `update` bilang tidak menemukan GitHub credential, berarti instalasimu lebih lama dari perubahan itu. Jalankan update dari installer sekali saja, lalu setiap `zurg update` setelahnya akan berjalan. Perintah installer yang sama juga memperbarui build yang terlalu lama untuk punya `zurg update`. Perintah ini hanya mengganti binary dan tidak menyentuh yang lain.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

Server tanpa GitHub CLI bisa mengatur `GITHUB_TOKEN` sebagai gantinya. Gunakan classic token dengan scope `repo` dari akun GitHub yang punya akses ke zurg.

## Konfigurasi yang sudah ada dan unattended {#existing-and-unattended-configs}

Setup tidak pernah menimpa `config.yml` yang sudah ada. Untuk setup tanpa interaksi, ulangi `--provider` dan berikan flag token-file atau `--nntp-*` yang sesuai. Variabel `REALDEBRID_TOKEN`, `TORBOX_TOKEN`, `ALLDEBRID_TOKEN` dan `NNTP_*` juga bisa dipakai. Jalankan `./zurg setup --help` untuk daftar lengkapnya.

Lihat [configuration reference](../reference/config.md) untuk setiap pengaturan.

Masih bingung? Tanya di forum **zurg-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Lihat juga {#see-also}

- [Docker](docker.md) — pengaturan container dan propagasi mount FUSE
- [macOS](macos.md) — installer binary yang sama dengan macFUSE dan launchd
- [Windows](windows.md) — installer binary yang sama dengan WinFsp dan scheduled task interaktif
