# Setup dengan Docker {#docker-setup}

Panduan ini menjalankan zurg di Docker dan mengekspos FUSE mount-nya di host Linux. Docker menyediakan zurg
rclone dan ffprobe. Perintah bawaan `setup` membuat config. `doctor` memeriksa instalasi.

Alur ini sudah diverifikasi pada 4 September 2026 dengan Docker Engine 29.1.1. Gunakan nightly bertanggal terbaru agar image memiliki pemilih provider di bawah ini.

> **Image sponsor:** `ghcr.io/debridmediamanager/zurg` hanya untuk sponsor. Jadilah sponsor di [gatekeeper](https://gatekeeper.debridmediamanager.com/). Dengan itu, akun GitHub Anda mendapat akses ke image tersebut.

> **Wajib host Linux:** mount yang terlihat di host pada panduan ini bergantung pada mount propagation Linux. Docker Desktop menjalankan container di dalam VM di macOS dan Windows. Ia tidak bisa meneruskan FUSE mount ini ke Finder atau Explorer, dan rex tidak bisa menjangkau zurg di dalamnya, jadi tidak ada yang bisa diputar di sana. Gunakan panduan binary [macOS](https://notes.debridmediamanager.com/id/zurg/setup/macos/) atau [Windows](https://notes.debridmediamanager.com/id/zurg/setup/windows/) di host tersebut. Di Linux dengan rex di mesin lain, beri container zurg `network_mode: host`, seperti yang ditunjukkan [rex dengan zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex).

## Opsi satu baris {#one-line-option}

Di host Linux yang baru, bootstrap opsional bisa memasang Docker jika Anda setujui, mengatur persistent FUSE mount propagation, login ke sponsor registry, menulis Compose project, menjalankan provider chooser, dan memverifikasi hasilnya:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

File dan config Compose yang sudah ada tetap dipertahankan. Bagian di bawah menunjukkan setiap langkah untuk operator yang lebih suka cara manual.

## Yang dilakukan installer di dalam container {#what-the-installer-does-in-a-container}

Flag-flag ini memang sengaja dibuat:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` menanyakan provider mana yang mau dikonfigurasi, hanya meminta kredensial untuk provider tersebut, lalu menulis `config.yml` dengan mode `0600`.
- `--no-service` menyerahkan auto-start ke kebijakan `restart: unless-stopped` milik Docker, alih-alih mencoba memasang systemd di dalam Alpine.
- `--skip-downloads` memakai rclone dan ffprobe yang sudah terpasang di image.
- `--mount-path` mencatat subdirektori yang mount FUSE-nya akan diteruskan kembali ke host.

Menjalankan setup lagi itu aman. Proses ini memvalidasi dan memperbarui instalasi, tetapi tidak mengganti `config.yml` yang sudah ada.

## 1. Pasang Docker dan buka kunci image {#1-install-docker-and-unlock-the-image}

Instal Docker Engine dengan plugin Compose di host Linux. Cek kedua perintah sebelum lanjut:

```bash
docker version
docker compose version
```

Login ke GitHub Container Registry dengan username GitHub kamu. Saat diminta password, tempelkan personal access token classic dengan scope `read:packages` dan `repo` sekaligus. Image ini ada di repositori privat, dan token yang hanya punya `read:packages` memang bisa login tapi tetap gagal saat pull:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Atur `ZURG_TAG` ke rilis sponsor bertanggal yang paling baru. Menyimpannya di `.env` memberimu target rollback yang jelas dan membuat upgrade jadi eksplisit:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

Ganti placeholder dengan tag rilis yang sebenarnya sebelum lanjut.

## 2. Siapkan mount propagation FUSE {#2-prepare-fuse-mount-propagation}

Mount FUSE harus dibuat di bawah mount induk yang shared. Jalankan ini sekali sebelum container pertama dijalankan:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

Verifikasi device dan mode propagation:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

Perintah kedua seharusnya menampilkan `shared` di bawah `PROPAGATION`.

## 3. Buat proyek compose {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

Buat `docker-compose.yml`:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

`privileged: true` tidak wajib. Perangkat FUSE, capability `SYS_ADMIN`, dan profil AppArmor unconfined adalah kumpulan yang lebih sempit yang dipakai untuk mount.

Jangan bind `/zurg_mnt/zurg` secara langsung. Mount FUSE harus berada di bawah bind `rshared` agar event mount-nya sampai ke host.

Container yang membaca mount, terutama Sonarr dan Radarr, mengikuti aturan yang sama dari sisi lain: bind parent-nya (`/zurg_mnt`) sekali saja, dengan `rslave`, lalu akses setiap folder lewat satu bind itu. Bind `__magic__/__all__` dan `__magic__/tv` ke sebuah \*arr sebagai dua volume membuat setiap impor berubah menjadi salinan seluruh file. Lihat [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

## 4. Jalankan setup bawaan {#4-run-the-built-in-setup}

Dari `~/zurg`, jalankan:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Pilih satu atau beberapa penyedia sesuai urutan prioritas. Misalnya masukkan `2,4` untuk TorBox lalu Usenet.  Setup hanya meminta kredensial mereka, membuat `config.yml` di `~/zurg`, mengaktifkan rclone, dan membuat `/zurg_mnt/zurg`. Tidak ada kredensial yang disimpan di file compose atau riwayat shell.

Untuk otomatisasi, ulangi `--provider` dan berikan flag `--nntp-*` atau token-file khusus penyedia. Setup mempertahankan config yang sudah ada pada eksekusi berikutnya.

Setup hanya menulis akun pada eksekusi yang membuat `config.yml`. Untuk menambahkan akun ke instalasi yang sudah punya config, gunakan **Add provider** di Dashboard atau edit file-nya, lalu restart. Setiap layanan punya halamannya sendiri berisi kredensial, blok config, dan batasan yang perlu kamu tahu: [Penyedia](../providers/index.md).

## 5. Jalankan zurg {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

Keluar dari tampilan log dengan `Ctrl+C`; container tetap berjalan. Dashboard ada di `http://localhost:9999/config/` dan mengedit `config.yml` yang sama, yang tersimpan di samping file compose.

Library yang besar bisa butuh waktu cukup lama untuk dimuat. Folder di mount gagal ditampilkan sampai proses itu selesai. Folder tersebut akan muncul kosong atau sebagai `Input/output error`, padahal Dashboard dan `version.txt` tetap berjalan normal. Itu artinya zurg masih memuat, bukan mount yang rusak. [Up versus ready](#up-versus-ready) menunjukkan cara mengetahui kapan proses muat sudah selesai.

## 6. Verifikasi dengan doctor {#6-verify-with-doctor}

Setelah library siap, jalankan alat diagnosa yang sama seperti yang dipakai instalasi biner:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` memeriksa config dan permission-nya, ffprobe, rclone, FUSE, endpoint HTTP, dan mount yang dilaporkan oleh zurg. `WARN service zurg is not installed` itu wajar di Docker karena Compose yang mengurus auto-start. Warning tidak membuat perintah gagal; yang membuatnya gagal hanya `FAIL`.

Pastikan juga mount yang dipropagasi terlihat dari luar container:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. Buat parent bersama tetap aman saat reboot {#7-make-the-shared-parent-survive-reboots}

Bind mount dari langkah 2 tidak bertahan setelah reboot. Buat systemd oneshot unit di host:

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

Pada reboot berikutnya, host menyiapkan parent yang shared sebelum Docker memulihkan container zurg.

## Up versus ready

zurg menjawab dua pertanyaan berbeda lewat HTTP. Keduanya tidak butuh password, meskipun `username` sudah diatur.

| Alamat | Membalas 200 saat | Selama library dimuat |
|---|---|---|
| `/http/version.txt` | zurg sedang berjalan | 200 |
| `/ready` | library sudah selesai dimuat | 503 dengan `Retry-After: 5` |

Health check container menanyakan yang pertama. `docker compose ps` menampilkan `healthy` begitu zurg berjalan. Library besar bisa terus dimuat cukup lama setelah itu. Akses `/ready` saat kamu butuh seluruh library. Alamat ini menampilkan `ready` setelah proses pemuatan selesai.

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

Script bisa menunggu seperti ini.

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### Mengapa health check tidak menunggu library {#why-the-health-check-does-not-wait-for-the-library}

Docker menyimpan satu status kesehatan untuk setiap container. Alat yang membacanya menganggap status itu sebagai "apakah zurg hidup". autoheal dan Docker Swarm me-restart container yang berubah menjadi unhealthy. `depends_on` dengan `condition: service_healthy` menahan layanan lain sampai zurg healthy.

Ada laporan cold start selama 15 sampai 90 menit pada library besar. Health check yang menunggu library selesai dimuat akan menahan setiap layanan dependen selama itu. Container rclone di depan zurg akan membuat folder mount-nya kosong selama itu juga. Folder kosong terlihat bagi media server seperti library yang sudah dihapus. Pemuatan yang lebih lama dari jumlah retry health check juga akan ditandai unhealthy. Setiap alat yang me-restart container unhealthy kemudian akan memulai pemuatan dari awal. Prosesnya tidak akan pernah selesai.

### Menggunakan readiness dengan Compose {#using-readiness-with-compose}

Biarkan container mount tetap memakai health check default supaya mount-nya langsung naik begitu zurg berjalan.

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

Tunggu di `/ready` pada apa pun yang membutuhkan seluruh library. Bisa berupa script scan atau job import.

Anda bisa membuat container zurg itu sendiri melaporkan healthy hanya setelah library selesai dimuat. Override health check-nya di `docker-compose.yml` dan atur `start_period` lebih lama dari proses load paling lambat Anda. Docker tidak menghitung kegagalan di dalam start period. Setiap service yang bergantung pada zurg kemudian ikut menunggu library juga. Jangan gabungkan ini dengan autoheal.

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## Mengelola dan memperbarui zurg {#managing-and-updating-zurg}

Jalankan perintah-perintah ini dari `~/zurg`:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

Compose project membaca `ZURG_TAG` dari `.env`, yang diset installer ke `latest` supaya setiap pull selalu mengambil nightly terbaru. Untuk upgrade, pull lalu recreate container, kemudian jalankan doctor:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`zurg update` bukan cara yang tepat di sini dan akan menolak jalan di dalam container. Binary yang ditulisnya ada di container layer dan akan hilang begitu container di-recreate, jadi `up` berikutnya diam-diam kembali ke build lama. Pakai pull image saja. `--force` akan melewati penolakan itu, tapi hanya untuk container yang memang mau kamu pertahankan.

Untuk rollback, ubah `ZURG_TAG` di `.env` ke tag nightly tertentu, lalu jalankan tiga perintah tadi lagi. Config, state library, log, dan cache yang di-bind-mount tidak ikut berpindah bersama container.

`docker compose down` menghapus container dan network, tapi file bind-mount di `~/zurg` dan parent mount di `/zurg_mnt` tetap ada.

## Apa yang ada di mana {#what-lives-where}

Semua yang ditulis zurg mengacu ke `/config`, jadi satu bind `./:/config` menyimpan seluruh instalasi:

| Path | Isinya |
|---|---|
| `config.yml` | Pengaturan dan kredensial provider; perubahan dari Dashboard ditulis kembali ke sini |
| `data/` | Status library, file lokal, kunci yang di-generate, dan cache VFS rclone |
| `logs/` | Log zurg dan rclone |
| `dump/` | Dump torrent saat diaktifkan |
| `strm/` | File `.strm` saat `save_strm_files` diaktifkan |
| `nzbs/` | Direktori watch untuk backend Usenet |

Menarik (pull) atau membuat ulang image tidak mengubah satu pun file ini.

`data/rclone-cache` adalah yang terus membesar. Mount mengunduh setiap file yang dibaca secara penuh dan menyimpannya setelah pemutaran selesai, hingga **256G** secara default, jadi direktori bind perlu ruang untuk cache di samping semua yang lain. Batas umur 72 jam tidak membatasinya dalam praktik. Apa pun yang membaca library, termasuk pemindaian harian media server, dihitung sebagai menyentuh file tersebut.

```bash
du -sh ./data/rclone-cache
```

Batasi lebih rendah di `config.yml` jika disk host tidak sanggup menampung sebanyak itu:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Mengubah path host di balik `/config` akan mengganti nama cache dan meninggalkan salinan lama yang yatim; zurg membersihkan pohon yang yatim saat start berikutnya dan mencatat apa yang dibebaskan. Lihat [config.md](../reference/config.md#disk-the-mount-uses).

### Environment seeding untuk instalasi tanpa pengawasan {#environment-seeding-for-unattended-installs}

Image ini masih mendukung jalur first-run yang lama. Jika tidak ada `config.yml`, `TOKEN` atau `RD_TOKEN` akan mengisi akun, dan `MOUNT_PATH` mengaktifkan mount. Variabel-variabel ini hanya dibaca saat file sedang dibuat. Setelah itu, file yang sudah ada selalu menang di setiap start berikutnya.

Real-Debrid adalah satu-satunya akun yang diisi dengan cara ini oleh container yang berjalan. `TORBOX_TOKEN`, `ALLDEBRID_TOKEN`, `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN`, `OFFCLOUD_TOKEN` dan `NNTP_HOST` dibaca oleh `zurg setup`. Jadi variabel tersebut berlaku di container setup sekali pakai di atas, dan tidak berpengaruh apa pun jika ditaruh di blok `environment:` milik service.

Perintah `setup` interaktif lebih disarankan untuk orang yang sedang menggunakan terminal, karena token tidak pernah masuk ke file compose. Pengisian lewat environment tetap berguna untuk otomatisasi yang sudah punya secret store.

### Meng-upgrade instalasi yang me-mount `/app` {#upgrading-an-install-that-mounted-app}

Proyek compose lama me-mount `/app/config.yml`, `/app/data`, dan path lain secara terpisah. Entrypoint tetap memilih `/app` setiap kali menemukan layout itu, sehingga saat image yang lebih baru di-pull, config dan cache lama tetap dipakai.

Untuk beralih ke layout satu folder, hentikan container, salin `config.yml`, `data/`, dan direktori state lain yang ada ke satu direktori di host, lalu mount direktori itu ke `/config`.

## Pemecahan masalah {#troubleshooting}

Mulai dengan diagnostik dan log terkini:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` atau `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

The container sudah ada sebelum installer bawaan. Pakai `2026.09.04.1449-nightly` atau image zurg bertanggal yang lebih baru, lalu buat ulang container-nya:

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

Mount FUSE yang lama sudah tidak berfungsi:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### Perangkat FUSE tidak tersedia {#fuse-device-is-unavailable}

Muat modulnya sekarang dan juga pada boot berikutnya:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

Lalu pastikan service compose masih menyertakan `/dev/fuse`, `SYS_ADMIN` dan pengaturan AppArmor.

### Mount kosong {#mount-is-empty}

Periksa setiap lapisan secara berurutan:

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

Path host harus berupa bind mount yang shared, dan volume di compose harus mem-bind parent-nya sebagai `/zurg_mnt:/zurg_mnt:rshared`.

Jika `/ready` gagal dengan error 503, berarti library masih dimuat dan mount-nya sudah benar. Folder-nya akan tampil kosong atau menampilkan `Input/output error` sampai proses load selesai. Tunggu saja, jangan restart zurg. Restart akan membuat proses load mulai dari awal lagi.

### Mount muncul dua kali di output `mount` {#mount-appears-twice-in-mount-output}

Itu normal. FUSE mount yang sama terlihat di mount namespace container dan host karena propagation-nya berjalan dengan benar.

Masih bingung? Tanyakan di forum **zurg-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Mendapatkan bantuan](../../guides/remote-help.md) menjelaskan apa saja yang perlu kamu sertakan.
