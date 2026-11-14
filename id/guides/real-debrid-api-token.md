# Token API Real-Debrid Anda: di mana mendapatkannya dan arti errornya {#your-real-debrid-api-token-where-to-get-it-and-what-the-errors-mean}

Token API Real-Debrid kamu ada di [real-debrid.com/apitoken](https://real-debrid.com/apitoken). Masuk ke Real-Debrid, buka halaman itu, lalu salin kode di bawah **API Private Token**. Tempel ke DMM atau zurg. Kalau aplikasi menampilkan `bad_token`, berarti token yang dimilikinya salah atau tidak lengkap: salin lagi dari halaman itu.

## Dapatkan token Anda {#get-your-token}

1. Masuk di [real-debrid.com](https://real-debrid.com). Kalau belum masuk, halaman token hanya menampilkan **403-Forbidden**.
2. Buka [real-debrid.com/apitoken](https://real-debrid.com/apitoken).
3. Salin seluruh kode di bawah **API Private Token**. Panjangnya 52 huruf kapital dan angka.

![Halaman API Private Token Real-Debrid, token diblur](../assets/real-debrid-api-token/01-apitoken.webp)

Perlakukan token ini seperti kata sandi. Token ini tidak kedaluwarsa, dan siapa pun yang memilikinya bisa memakai seluruh akun kamu. Peringatan dari Real-Debrid sendiri di halaman itu: **This token is not meant to be used into public apps, it is insecure !**

**Refresh** di halaman itu akan memberi kamu token baru. Real-Debrid menyarankannya kalau kamu merasa token kamu dipakai orang lain. Setelah refresh, tempel token baru ke setiap aplikasi yang sebelumnya memakai token lama.

## Masukkan ke DMM {#put-it-in-dmm}

1. Di [debridmediamanager.com](https://debridmediamanager.com), tekan **Login with Real Debrid**.
2. Di bawah **or paste an API key**, tempel token ke **API Key** lalu tekan **Save API Key**. **Get API Key from Real-Debrid** akan membuka halaman token untukmu.

![DMM's Connect Real-Debrid page](../assets/real-debrid-api-token/02-dmm-paste-key.webp)

DMM sebenarnya tidak perlu token: **Sign in with Real-Debrid** menampilkan kode yang kamu setujui di real-debrid.com/device. Dengan cara itu DMM punya sign-in sendiri, dan akan diperbarui otomatis. Selengkapnya di [What is DMM and how do I use it?](../dmm/index.md#sign-in)

## Masukkan ke zurg {#put-it-in-zurg}

Di `config.yml`, di bawah `providers`:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
```

Atau di Dashboard zurg di `http://localhost:9999`: buka **Config**, tekan **Edit** pada baris realdebrid di bawah **Providers**, tempel token ke **Token**, lalu tekan **Save**. Restart zurg dengan salah satu cara tersebut. [Real-Debrid dengan zurg](../zurg/providers/realdebrid.md) berisi sisanya, termasuk pengaturan `TOKEN` untuk Docker.

Untuk mengecek apa kata zurg:

```bash
curl -sS -X POST http://localhost:9999/api/providers/realdebrid/test
```

Token yang ditolak Real-Debrid akan menampilkan `account connection check failed; verify credentials and network`.

## Periksa token sendiri {#check-a-token-yourself}

```bash
curl -H "Authorization: Bearer YOUR_RD_API_TOKEN" https://api.real-debrid.com/rest/1.0/user
```

Di Windows, ketik `curl.exe` sebagai ganti `curl`. Token yang valid akan menampilkan akun Anda: `username`, `"type": "premium"` dan tanggal `expiration`. Token yang salah akan menampilkan:

```json
{
	"error": "bad_token",
	"error_code": 8
}
```

## Ketika ada yang salah {#when-something-is-wrong}

Error dari Real-Debrid selalu datang dengan nama dan nomor. zurg menampilkan keduanya, seperti `bad_token (status code: 401) (code: 8)`.

| Yang Anda lihat | Artinya dan yang perlu dilakukan |
|---|---|
| `bad_token`, code 8. Di zurg: `Failed to get user information: api response error: bad_token (status code: 401) (code: 8) trying again in 30s` | Real-Debrid tidak mengenali token itu. Token tersebut salah disalin, terpotong, atau sudah diganti. Salin lagi dari [real-debrid.com/apitoken](https://real-debrid.com/apitoken), seluruhnya tanpa ada yang di depan atau di belakang, lalu restart zurg. |
| zurg: `Account realdebrid refused zurg (credential rejected)` | Sama seperti `bad_token`. Akun lain Anda tetap berjalan dan zurg akan meminta ke Real-Debrid lagi setiap 10 menit. |
| DMM: **Real-Debrid rejected that API key.** | Sama seperti `bad_token`. Salin lagi, atau tekan **Sign in with Real-Debrid** sebagai gantinya. |
| `permission_denied`, code 9. Di zurg: `RD Permission denied (code=9)` | Real-Debrid menolak akunnya, bukan tokennya. Dokumennya menyebut akun yang dikunci, dan pada beberapa permintaan, akun yang tidak premium. Masuk di real-debrid.com dan cek akun serta sisa hari **Premium** Anda. Jika keduanya terlihat baik-baik saja, tekan **Refresh** di halaman token lalu tempel token baru, seperti yang disarankan pesan zurg. |
| `ip_not_allowed`, code 22. Di zurg: `RD refused link generation from this IP (code=22, ip_not_allowed)` | Bukan masalah token. Real-Debrid tidak mau membuat link unduhan untuk alamat server dan VPS. Jalankan dari koneksi rumahan, atau beli Remote Traffic dari Real-Debrid. |
| `service_unavailable`, code 25 | Real-Debrid sendiri sedang bermasalah. Tidak ada yang perlu Anda ubah. Cek [Is Real-Debrid down or just me?](https://debridmediamanager.com/is-real-debrid-down-or-just-me) dan coba lagi nanti. |
| **403-Forbidden** di real-debrid.com/apitoken | Anda belum masuk ke Real-Debrid. Masuk dan buka halaman itu lagi. |

Setiap kode tercantum di [API docs Real-Debrid](https://api.real-debrid.com/), di bagian bawah.

## Pertanyaan {#questions}

### Di mana saya menemukan token API Real-Debrid saya? {#where-do-i-find-my-real-debrid-api-token}

Di [real-debrid.com/apitoken](https://real-debrid.com/apitoken), saat sudah masuk. Salin kode di bawah **API Private Token**.

### Token saya berfungsi di aplikasi lain tetapi zurg bilang tidak valid. Kenapa? {#my-token-works-in-another-app-but-zurg-says-its-invalid-why}

Akun Anda hanya punya satu API token. Banyak aplikasi tidak memakainya sama sekali: mereka masuk dengan kode, seperti **Sign in with Real-Debrid** di DMM. Jadi, kalau aplikasi lain berjalan, belum tentu zurg punya token yang benar. Salin lagi token dari halaman token ke zurg, tanpa spasi atau karakter apa pun sebelum dan sesudahnya, lalu restart zurg.

### Apakah token itu kedaluwarsa? {#does-the-token-expire}

Tidak, token API tidak punya tanggal berakhir. Login lewat aplikasi itu berbeda: aplikasi tersebut mendapat kredensial sendiri, dan kredensial itu diperbarui secara otomatis.

### Apakah aman memberikan token saya ke addon atau situs web? {#is-it-safe-to-give-my-token-to-an-addon-or-website}

Hanya untuk aplikasi yang Anda percaya. Token ini membuka seluruh akun Anda, dan Real-Debrid menyatakan token tersebut tidak dimaksudkan untuk aplikasi publik. Jika aplikasi menyediakan sign-in dengan kode, gunakan cara itu saja.
