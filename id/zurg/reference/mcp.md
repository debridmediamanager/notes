# Endpoint MCP {#the-mcp-endpoint}

zurg bisa menjawab AI agent lewat [Model Context Protocol](https://modelcontextprotocol.io):
client bertanya tool apa saja yang ada, zurg menjelaskan tool-tool itu, lalu agent memanggilnya untuk membaca library, mencari tahu kenapa sebuah release tidak bisa diputar, memperbaikinya, atau mengendalikan media server. Operasinya sama dengan yang ada di dashboard dan CLI, hanya saja disajikan sebagai tool bertipe dengan schema, bukan sebagai HTML dan redirect 303.

Endpoint ini mati secara default. Endpoint ini dilindungi basic auth yang sama dengan dashboard, dan zurg tidak akan menjalankannya sama sekali kalau tidak ada username yang diatur. Kalau username kosong, setiap route di server bisa diakses publik, dan tool-tool ini bisa menghapus release.

## Konfigurasi {#configuration}

```yaml
mcp:
  enabled: true
```

Itu sudah semua untuk instalasi biasa. Sisanya punya nilai default yang perlu Anda ketahui:

```yaml
mcp:
  enabled: true
  toolsets: [library, releases, repair]   # the default; see below
  read_only: false                        # withhold every tool that changes anything
  allow_unauthenticated: false            # serve /mcp with no username set
  allow_lifecycle: false                  # admit the tools that stop zurg or its mount
  page_limit: 50                          # items a listing returns by default; 500 is the cap
  max_result_kb: 256                      # ceiling on one result; a page over it is trimmed
  session_timeout_mins: 30                # -1 keeps sessions for the life of the process
```

Sama seperti blok fitur lainnya, pengaturan ini dibaca sekali saat startup: jika diubah, Anda perlu restart.

## Menghubungkan {#connecting}

### Melalui HTTP {#over-http}

Endpoint-nya adalah `/mcp` di port zurg yang biasa, dengan protokol Streamable HTTP. Arahkan client ke `http://<host>:9999/mcp` dengan kredensial dashboard.

```bash
npx @modelcontextprotocol/inspector
# Transport:  Streamable HTTP
# URL:        http://localhost:9999/mcp
# Header:     Authorization: Basic <base64 of user:password>
```

### Melalui stdio {#over-stdio}

Klien yang hanya bisa berbicara lewat stdio memakai subperintah `zurg mcp`, yang menjembatani ke instance zurg yang sedang berjalan:

```json
{
  "mcpServers": {
    "zurg": {
      "command": "/path/to/zurg",
      "args": ["mcp"],
      "cwd": "/path/to/your/zurg/directory"
    }
  }
}
```

`cwd` itu penting: semua path zurg dihitung dari direktori kerja, dan dari situ `zurg mcp` membaca `config.yml` untuk mengambil port dan kredensial. Dengan itu, perintahnya tidak perlu argumen apa pun. `--username` dan `--password` menimpa kredensial lokal. Nilai `--url` kustom tidak pernah mewarisi kredensial dari config lokal. Jadi kalau endpoint itu memang butuh login, berikan kedua flag kredensial secara eksplisit. Dengan begitu, password lokal tidak akan terkirim ke host lain secara tidak sengaja.

Perintah ini tidak menjalankan instance kedua. Instance zurg kedua akan memuat seluruh library, memakai slot provider tambahan di akun yang pemakaiannya dihitung, dan berebut mount dengan yang pertama. Jadi `zurg mcp` hanya meneruskan koneksi ke daemon, dan tidak melayani apa pun kalau daemon belum berjalan. Output diagnostiknya dikirim ke stderr, karena stdout dipakai untuk protokol.

Ada satu keterbatasan. Notifikasi yang dikirim server di luar pemanggilan apa pun tidak ikut melewati jembatan ini. Progress dan baris log yang muncul *selama* sebuah pemanggilan ikut di respons pemanggilan itu dan sampai dengan normal. Itu mencakup semua yang dikirim zurg.

## Kumpulan alat {#toolsets}

zurg punya ratusan tool, dan itu lebih banyak dari yang bisa ditangani client dengan baik. Lewat sekitar delapan puluh, model lebih sering memilih tool yang salah, dan schema-nya saja bisa memakan puluhan ribu token. Jadi `toolsets` memilih grup, dan default-nya adalah subset yang berfungsi, bukan semuanya.

| Toolset | Ada di default | Yang dicakup |
|---|:-:|---|
| `library` | ya | Pencarian, daftar direktori, jumlah tag |
| `releases` | ya | Satu release secara detail: file, salinan per akun, dan apa yang bisa melayani tiap file |
| `repair` | ya | Apa yang rusak, apakah repair akan menjangkaunya, dan memaksa repair |
| `releases_write` | | Menghapus, mengganti nama, memberi tag, force-show, dan menulis file `.strm` |
| `magic` | | Namespace `__magic__`: layout yang tersimpan, barisnya, dan memindahkan sesuatu |
| `plex` | | Plex, Jellyfin dan Emby: status, pencocokan, dan pemindaian yang terproteksi |
| `providers` | | Akun yang dikonfigurasi: apa yang bisa dilakukan tiap akun, apakah bisa dijangkau, dan berapa yang sudah dihabiskan |
| `usenet` | | Backend NZB: akun berita, probe artikel, kerusakan, dan cache artikel |
| `clients` | | Endpoint SABnzbd, qBittorrent dan Stremio yang dihubungi Sonarr dan Radarr |
| `diagnostics` | | Log, penghitung byte, memori, dan goroutine |
| `config` | | Membaca konfigurasi, mencari drift, dan menulis sekumpulan key pilihan |
| `mount` | | Mount rclone: status, melupakan daftar yang di-cache, dan me-restart-nya |
| `system` | | Fakta build, `doctor`, service, backup, dan update |

`toolsets: [all]` mengaktifkan semua grup. Nama yang diawali `-` akan mengurangi, jadi `[all, -config, -system]` berarti seluruh surface tanpa dua grup yang mengubah mesin, bukan library. Nama yang tidak dikenali akan memberi peringatan saat startup dan diabaikan: typo tidak boleh membuat endpoint hilang.

Tool yang menghentikan zurg, mengontrol service-nya, atau me-restart mount tidak punya grup sendiri. Tool tersebut ada di `system` dan `mount`, dan tetap disembunyikan sampai `allow_lifecycle` diatur, apa pun isi `toolsets`.

Grup `server` yang kecil, berisi info tentang build ini dan apakah library sudah selesai dimuat, selalu terdaftar apa pun isi `toolsets`. Kalau grup ini disembunyikan, client tidak akan tahu bahwa semua jawaban lain sedang tidak lengkap.

## Apa yang tidak akan dilakukan tanpa diminta {#what-it-will-not-do-without-being-asked}

**Konfirmasi.** Tool yang mengambil sesuatu akan menjelaskan apa yang akan dilakukannya
dan mengembalikan sebuah token. Tool hanya benar-benar bertindak saat dipanggil lagi dengan token itu.
Token dibuat dari rencana, jadi konfirmasi tidak bisa dibawa ke rencana yang berbeda. Jika library berubah
di antara dua panggilan, panggilan kedua akan kembali menjelaskan, bukan langsung bertindak. Token hanya bisa dipakai sekali, berlaku dua menit,
dan tidak bertahan setelah restart.

**`read_only`.** Satu saklar yang menyembunyikan setiap tool yang mengubah sesuatu, apa pun isi `toolsets`.
Pertanyaan yang sebenarnya diajukan operator adalah "apakah ini bisa merusak library saya", bukan "tool mana yang menulis".
Tool-tool tersebut dihilangkan dari `tools/list`, jadi client tidak bisa memilih kemampuan yang tidak akan pernah
diizinkan oleh endpoint ini. Pengecekan saat pemanggilan tetap ada sebagai pertahanan berlapis, jika pengaturan
live berubah setelah server dibuat.

**`allow_lifecycle`.** Tool yang menghentikan zurg, mengontrol service-nya, atau me-cycle mount
disembunyikan dengan cara yang sama di balik saklar terpisah. Masing-masing bisa membuat seluruh library hilang sekaligus.
Aksi process/service juga tidak bisa melaporkan hasilnya sendiri, karena bisa saja mengakhiri proses yang sedang menjawab panggilan.

**Rahasia.** Tidak ada hasil tool yang memuat provider token, API key, password news-server, link CDN yang sudah di-resolve, atau URL `.strm` yang ditandatangani. Output log disensor (redacted) sebelum keluar. Link yang sudah di-resolve bisa dipakai oleh siapa pun yang memegangnya terhadap akun yang membuatnya, dan transkrip bukan tempat yang tepat untuk menyimpannya.

**Ukuran.** Setiap daftar dibatasi dua kali: dengan batas halaman, dan dengan batas atas pada ukuran hasil yang sudah di-marshal. Satu akun yang diukur terhadap ini memiliki 84,000 release, sekitar dua belas megabyte nama sebelum satu file pun didaftar. Hasil yang melebihi batas akan dipotong, dan hasilnya akan memberi tahu bahwa ia telah dipotong.

## Catatan {#notes}

Endpoint ini mewarisi basic auth dari dasbor karena didaftarkan di dalamnya.
Permintaan lintas origin akan ditolak: `/mcp` itu untuk agen lokal, bukan untuk halaman web.
Reverse proxy di depan zurg bisa dipakai. Pemeriksaan DNS-rebinding di library protokol akan menolak proxy yang meneruskan `Host`-nya sendiri sambil menghubungi `127.0.0.1`. Karena itu, zurg mematikan pemeriksaan tersebut dan membiarkan basic auth yang menjaga akses.

`zurg mcp --help` menampilkan daftar flag untuk bridge. `zurg doctor` memeriksa apakah endpoint itu merespons sama sekali.
