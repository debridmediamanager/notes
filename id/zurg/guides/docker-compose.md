# Satu file Docker Compose untuk zurg, Plex, dan rex {#one-docker-compose-file-for-zurg-plex-and-rex}

Di mesin Linux, satu `docker-compose.yml` bisa menjalankan zurg, Plex Media Server, dan rex sekaligus. zurg menampilkan library kamu sebagai folder di `/zurg_mnt/zurg`, Plex Media Server membaca folder tersebut, dan rex mengambil library yang sama langsung dari zurg, jadi tidak perlu folder. Jalankan installer Docker zurg sekali, lalu ganti `docker-compose.yml`-nya dengan yang di bawah ini.

Ingin Plex Media Server atau rex saja, tidak keduanya? Hapus saja yang tidak dipakai dari file. Kalau tanpa Plex, hapus juga baris `command:` milik rex.

Docker Desktop di Windows atau Mac tidak bisa menjalankan ini: folder zurg tidak sampai ke Explorer atau Finder, dan rex tidak bisa menjangkau zurg yang ada di dalamnya. Gunakan [zurg di Windows](../setup/windows.md) atau [zurg di macOS](../setup/macos.md) untuk kondisi tersebut.

## Sebelum kamu mulai {#before-you-start}

- **Mesin Linux** yang selalu menyala. Installer akan menambahkan Docker jika belum ada.
- **Sponsorship zurg.** Image zurg bersifat privat. Sponsor di [gatekeeper](https://gatekeeper.debridmediamanager.com/) dan akun GitHub kamu akan mendapat akses.
- **Real-Debrid API token kamu**, atau login untuk layanan lain yang didukung zurg: [Real-Debrid API token kamu](../../guides/real-debrid-api-token.md).
- **Untuk Plex Media Server**, akun Plex kamu. **Untuk rex**, akun Plex baru yang khusus dibuat untuk itu: [rex dengan zurg](../../rex/with-zurg.md#before-you-start) menjelaskan alasannya.

## 1. Jalankan installer Docker milik zurg {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Skrip ini memasang Docker jika belum ada (akan bertanya dulu), menyiapkan `/zurg_mnt` untuk folder zurg sekarang dan setiap kali komputer di-reboot, membantu Anda login ke GitHub untuk image zurg, menulis `~/zurg/docker-compose.yml`, meminta layanan dan token Anda, menjalankan zurg, lalu menjalankan `zurg doctor`. [Pengaturan Docker untuk zurg](../setup/docker.md) melakukan hal yang sama secara manual.

**Yang harus Anda lihat.**

```bash
ls /zurg_mnt/zurg
```

Daftarnya berisi `__all__`, `__downloads__`, `__unplayable__`, `movies`, `shows` dan `version.txt`.

## 2. Ganti dengan file lengkap {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

Ganti semua isinya dengan ini:

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

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** adalah layanan installer itu sendiri, tidak diubah.
- **plex** melihat folder zurg di path yang sama dengan yang dipakai zurg, `/zurg_mnt/zurg`, jadi pemindaian yang diminta zurg menyebut folder yang dikenal Plex. `rslave` menjaga folder tetap ada saat zurg di-restart. Isi `TZ` dengan zona waktu Anda.
- **PLEX_CLAIM** memasukkan Plex Media Server ke akun Anda saat pertama kali dijalankan. Setelah masuk ke Plex, buka [plex.tv/claim](https://www.plex.tv/claim), salin kodenya, lalu tempel tepat setelah `=`. Kodenya kedaluwarsa dalam beberapa menit, jadi segera jalankan stack-nya.
- **rex** adalah layanan dari [rex dengan zurg](../../rex/with-zurg.md#d2-start-rex-in-docker), berjalan di port 32500 karena Plex Media Server memakai 32400. File-filenya berakhir di `~/rex/config`, tempat rex dengan zurg mencarinya.

Simpan, lalu jalankan semuanya:

```bash
docker compose up -d
docker compose ps
```

Jika `docker` menampilkan permission denied, tambahkan `sudo` di depan setiap perintah `docker` di halaman ini.

**Yang seharusnya Anda lihat.** Tiga container: `plex` dan `zurg` menampilkan `(healthy)`, `rex` menampilkan `Up`. File Plex Media Server sendiri masuk ke `~/plex`.

## 3. Tambahkan folder zurg di Plex {#3-add-zurgs-folders-in-plex}

Buka Plex Web di `http://<this machine's LAN IP>:32400/web`. Tambahkan library **Movies** dengan folder `/zurg_mnt/zurg/movies` dan library **TV Shows** dengan `/zurg_mnt/zurg/shows`, seperti yang ditunjukkan di [Real-Debrid in Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex).

Supaya Plex tahu ada hal baru, buka dashboard zurg di `http://<this machine's LAN IP>:9999/config/` lalu tekan **Login with Plex** di bawah **Media Server Integration** ([langkah 4 di sana](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)).

## 4. Siapkan rex {#4-set-up-rex}

Ikuti [rex with zurg](../../rex/with-zurg.md) dari [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) sampai [D5](../../rex/with-zurg.md#d5-watch), dengan `32500` di setiap tempat yang tertulis `32400`. Misalnya, baris zurg adalah `rex_url: http://192.168.1.20:32500`, dengan IP LAN rex. Aplikasi Plex kamu kemudian akan menampilkan kedua server, dan [langkah 2 dari rex with zurg](../../rex/with-zurg.md#step-2-install-rex) menjelaskan cara membedakannya.

## Memperbarui {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

Itu memperbarui zurg, Plex, dan rex sekaligus. Jika rex bersama zurg menjalankan `docker compose` di `~/rex`, jalankan di sini, di `~/zurg`, dengan `rex` di akhir perintah, supaya hanya menyentuh rex: `docker compose stop rex` menggantikan `docker compose down`, dan `docker compose up -d rex` menggantikan `docker compose up -d`.

## Ketika ada yang salah {#when-something-is-wrong}

`docker compose logs --tail=100 zurg` (atau `plex`, `rex`) menampilkan apa yang terakhir dikatakan sebuah container.

| Yang Anda lihat | Yang harus dilakukan |
|---|---|
| Installer menampilkan `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | Anda memakai Mac atau Windows. Instal zurg dengan installer [Windows](../setup/windows.md) atau [macOS](../setup/macos.md) sebagai gantinya. |
| `Error response from daemon: error from registry: unauthorized` saat Docker menarik zurg | Mesin ini belum masuk ke registry GitHub menggunakan akun yang punya akses ke zurg. Jadi sponsor di [gatekeeper](https://gatekeeper.debridmediamanager.com/), lalu jalankan installer lagi. Untuk masuk secara manual, lihat [pengaturan Docker zurg](../setup/docker.md#1-install-docker-and-unlock-the-image): token harus punya `read:packages` dan `repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` belum di-share. Jalankan `sudo mount --bind /zurg_mnt /zurg_mnt` dan `sudo mount --make-rshared /zurg_mnt`, lalu `docker compose up -d`. Installer membuat ini tetap aktif setelah reboot; kalau manual, lihat [langkah 7 pengaturan Docker zurg](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| `zurg` terus restart, dan log-nya berakhir dengan `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` dan `mapping key "..." already defined` | Pengaturan itu ada dua kali di config zurg. Jalankan `sudo nano ~/zurg/config.yml`, hapus salah satu dari dua baris yang disebut error, simpan, lalu jalankan `docker compose restart zurg`. |
| Log zurg menampilkan `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | Folder zurg belum muncul. Pastikan baris volume zurg adalah `/zurg_mnt:/zurg_mnt:rshared`, yaitu parent-nya dan bukan `/zurg_mnt/zurg`, dan `/zurg_mnt` sudah di-share (baris di atas). [Mount kosong](../setup/docker.md#mount-is-empty) punya pengecekan lebih lanjut. |
| Library Plex kosong setelah zurg restart, dan `docker exec plex ls /zurg_mnt/zurg` menampilkan `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | Baris volume Plex tidak punya `rslave`. Harus berbunyi `/zurg_mnt:/zurg_mnt:rslave`. Perbaiki lalu jalankan `docker compose up -d`. |
| rex berhenti dengan `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server sudah memakai port 32400. Biarkan `command: --port 32500` pada rex. |
| `/zurg_mnt/zurg/movies` kosong, atau menampilkan `Input/output error`, tepat setelah start | zurg masih membaca akun Anda. `curl http://localhost:9999/ready` akan menampilkan `ready` saat selesai. Jangan restart zurg selama itu: proses membaca akan mulai ulang dari awal. |
| Judul muncul di rex tapi tidak ada yang bisa diputar | Baris `upstream failed` pada [rex dengan zurg, bagian When something is wrong](../../rex/with-zurg.md#when-something-is-wrong) mengecek apakah rex bisa menjangkau zurg. |
| Disk penuh | zurg menyimpan salinan dari yang sudah diputar di `~/zurg/data/rclone-cache`, hingga 256G secara default. [What lives where](../setup/docker.md#what-lives-where) menunjukkan cara membatasinya. |

Masih buntu? Tanyakan di forum **zurg-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Pertanyaan {#questions}

### Bisakah kamu cek file docker compose saya? {#can-you-check-my-docker-compose-file}

Bandingkan dengan yang di atas. Yang paling penting: zurg memasang `/zurg_mnt` dengan `rshared`, Plex memasang `/zurg_mnt` yang sama dengan `rslave`, dan rex memakai image `ghcr.io/debridmediamanager/rex` dengan `network_mode: host`. Service bernama `rex` yang menjalankan `plexinc/pms-docker` itu hanyalah Plex Media Server kedua, bukan rex.

### Apakah saya perlu container rclone terpisah? {#do-i-need-a-separate-rclone-container}

Tidak. zurg menjalankan rclone di dalam container-nya sendiri dan memasang library Anda di `/zurg_mnt/zurg` sendiri.

### Bisakah saya memakai Plex Media Server dan rex bersama? {#can-i-use-plex-media-server-and-rex-together}

Ya, begitulah cara kerja file ini. Plex Media Server memutar dari folder zurg, dan rex memutar langsung dari zurg. Aplikasi Plex Anda akan menampilkan keduanya. Simpan hanya salah satu yang Anda pakai jika Anda tidak ingin keduanya muncul.

### Apakah ini bisa dipakai di NAS? {#does-this-work-on-a-nas}

Ini sudah diuji di PC Linux, bukan di NAS. Installer membutuhkan terminal (SSH) dengan `sudo`, dan FUSE (`/dev/fuse`). Jika langkah 1 selesai dan folder zurg ada di `/zurg_mnt/zurg`, lanjutkan ke langkah 2.

### Dengan versi apa ini diuji? {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`, rex `2026.11.14.1123-nightly` dan Plex Media Server `1.43.5.11079`, pada 14 November 2026.
