# Mendapatkan bantuan untuk zurg dan rex {#getting-help-with-zurg-and-rex}

## Tanya di Discord {#ask-in-discord}

Posting di forum [Discord](https://discord.com/invite/7u4YjMThXP) untuk yang kamu pakai: **zurg-support** **rex-support** atau **dmm-support**. Buat satu thread untuk setiap masalah. Jelaskan apa yang kamu lakukan, apa yang kamu harapkan, dan apa yang terjadi. Tambahkan detail di bawah ini.

**Untuk zurg**, klik **Export Logs** di dashboard zurg lalu tempel link yang diberikan. Link itu akan mengunggah log dan config zurg dengan token, password, dan API key kamu sudah dihapus. Kalau tidak bisa mengunggah, **Download Logs** memberi hasil yang sama sebagai file yang bisa kamu lampirkan. Tempel juga output dari `zurg doctor`:

| zurg berjalan sebagai | Jalankan |
|---|---|
| Binary di Linux atau macOS | `./zurg doctor` di folder zurg |
| Binary di Windows | `.\zurg.exe doctor` di folder zurg |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**Untuk rex**, tekan Play sekali pada yang gagal, lalu tempel bagian akhir log rex. rex menyamarkan token Plex di dalam log.

| rex berjalan sebagai | Jalankan |
|---|---|
| Layanan systemd di Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd di macOS | `tail -n 200 ~/rex/rex.log` |
| Task Scheduler di Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| Jendela terminal | 200 baris terakhir di jendela itu |

Di log yang panjang, baris yang paling penting adalah error, warning, dan keputusan rex untuk setiap play. Tambahkan `| grep -E 'ERROR|WARN|upstream|DECISION'` ke perintah Linux, macOS, atau Docker untuk hanya menampilkan baris itu. Di Windows, jalankan `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50`.

## Bantuan jarak jauh untuk sponsor {#remote-help-for-sponsors}

Ketika sebuah thread tidak bisa menyelesaikannya, seorang helper bisa mengetik di terminal Anda sambil Anda mengawasi. **Bantuan jarak jauh untuk zurg dan rex diperuntukkan bagi sponsor dan gratis.** [Jadilah sponsor di gatekeeper](https://gatekeeper.debridmediamanager.com/). Hubungkan Discord di sana untuk mendapatkan role sponsor, lalu ajukan pertanyaan di thread dukungan Anda.

Halaman ini menyiapkannya dengan [upterm](https://github.com/owenthereal/upterm) melalui `upterm.debridmediamanager.com`. Cara ini berjalan di Linux macOS dan Windows.

Anda tidak perlu akun, kata sandi, perubahan router, atau instalasi sebelumnya. Perintah-perintahnya akan mengunduh dan menjalankan upterm. Awasi setiap perintah di terminal yang sama. Ketik `exit` untuk mengakhiri sesi.

### 1. Pilih mesinnya {#1-pick-the-machine}

Jalankan upterm di mesin yang menjalankan zurg atau rex. Itu bisa berupa server, bukan komputer di depan kamu.

| Tempat berjalan | Yang harus dilakukan |
|---|---|
| Komputer ini | Buka terminal di sini lalu lanjut ke langkah 2. |
| Server cloud seperti Hetzner atau Oracle atau VPS | SSH ke server dulu. Lalu gunakan baris Linux di langkah 2 di jendela SSH itu. |
| NAS atau server di rumah seperti Synology atau Unraid | Buka terminal-nya. Lalu gunakan baris Linux di langkah 2 di sana. |
| Docker | Gunakan mesin yang menjalankan Docker dan bukan container. |

Kamu juga bisa SSH dari Windows. PowerShell sudah punya `ssh` bawaan.

```bash
ssh you@your-server
```

**Synology** mematikan SSH secara default. Nyalakan di Control Panel > Terminal & SNMP > Enable SSH service. Lalu login dengan akun admin. Gunakan alamat NAS dari router kamu atau dari Synology Assistant.

Jika langkah 2 menampilkan `cannot create directory` di Synology, nyalakan Control Panel > User & Group > Advanced > Enable user home service lalu jalankan lagi.

**Unraid** punya terminal di halaman webnya. Klik ikon `>_` di pojok kanan atas.

### 2. Mulai sesi {#2-start-a-session}

Tempelkan baris untuk sistem yang kamu pilih di langkah 1.

#### Linux dan macOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

Buka PowerShell. Tidak perlu dijalankan sebagai administrator.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

Di laptop ARM seperti Surface Pro X, ganti `amd64` dengan `arm64`.

Pertama kali, upterm akan bertanya apakah akan mempercayai `upterm.debridmediamanager.com`. Ketik `yes`. Fingerprint yang ditampilkan seharusnya yang ini.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. Kirim baris SSH ke helper kamu {#3-send-the-ssh-line-to-your-helper}

upterm menampilkan beberapa baris. Salin baris di bawah **SSH**, yang tampilannya seperti ini.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**Kirimkan lewat pesan pribadi.** Jangan pernah memposting di channel publik. Siapa pun yang memilikinya bisa mengetik di mesin Anda.

Lalu biarkan jendela tetap terbuka dan jangan klik di dalamnya: di Windows, klik di dalam jendela PowerShell bisa menjeda apa pun yang sedang berjalan di dalamnya sampai Anda menekan `Esc`. Anda bisa melihat semua yang diketik helper Anda di jendela itu saat mereka mengetiknya.

### 4. Akhiri sesi {#4-end-it}

**Ketik `exit` di jendela itu saat kamu sudah selesai.** Sesi akan berakhir dan baris perintah langsung berhenti bekerja.

Menutup jendela saja tidak cukup: sesinya tetap berjalan. Kalau kamu sudah menutupnya, buka terminal baru, jalankan `~/upterm/upterm session list` (di Windows `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`), lalu jalankan program yang sama dengan `session stop` dan nama yang ditampilkan.

Untuk minta bantuan lagi nanti, tempel saja baris dari langkah 2 lagi. Setiap sesi mendapat baris yang baru.

## Untuk helper {#for-helpers}

Jalankan baris SSH yang dikirim ke kamu. Kunci SSH apa pun bisa dipakai. Kalau belum punya, jalankan `ssh-keygen -t ed25519` sekali dulu. Kamu akan masuk ke terminal mereka: PowerShell di Windows, dan shell biasa mereka di Linux dan macOS.

Untuk menyalin file, karakter `:` pada ID sesi membingungkan `scp`, jadi berikan ID itu sebagai user saja: `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

Minta mereka mengetik `exit` kalau kamu sudah selesai.
