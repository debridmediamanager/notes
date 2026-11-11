# Pengaturan {#setup}

Installer biner adalah jalur tercepat di Linux, macOS, dan Windows. Docker tetap tersedia di host Linux kalau container lebih cocok untuk kamu. Docker Desktop di macOS dan Windows menjalankan container di dalam VM, jadi mount tidak bisa muncul di Finder atau Explorer dan rex tidak bisa mengakses zurg. Di sana, pakai biner saja.

## Installer satu baris untuk kemudahan {#one-line-convenience-installers}

Installer-nya mengunduh build nightly khusus sponsor. Jadi sponsor dulu di [gatekeeper](https://gatekeeper.debridmediamanager.com/). Itu yang memberi akses ke akun GitHub kamu.

Untuk instalasi sponsor baru, pilih perintah untuk host kamu:

+++ Linux dan macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker di Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
Di PowerShell:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

Bootstrap ini memeriksa prasyarat platform, login ke GitHub untuk akses sponsor, mengunduh build yang sesuai, dan menjalankan provider chooser. Binary dan config yang sudah ada tetap dipertahankan. Setiap panduan di bawah juga tetap menyediakan rute manual lengkap.

- [Linux](linux.md)
- [Docker](docker.md) (host Linux)
- [macOS](macos.md)
- [Windows](windows.md)

Setelah zurg terpasang, [Providers](../providers/index.md) menjelaskan cara mengarahkannya ke sebuah akun.
Ada satu halaman untuk tiap layanan, berisi kredensial, entri `config.yml`, dan apa yang berbeda dari layanan itu. Halaman-halaman tersebut ditulis untuk Docker. Pada instalasi binary, entri `config.yml` provider dan langkah di Dashboard sama saja, `./zurg service restart` (`.\zurg.exe service restart` di Windows) menggantikan `docker compose restart zurg`, dan baris `docker compose run --rm zurg setup` menjadi `./zurg setup` (`.\zurg.exe setup` di Windows) dengan flag yang sama kecuali `--no-service --skip-downloads --mount-path /zurg_mnt/zurg` milik container. Flag `--…-file` kemudian menunjuk ke file di mesin kamu, bukan file di bawah `/config`.
