# Bawa riwayat tontonan kamu ke rex {#bring-your-watch-history-to-rex}

rex dimulai tanpa riwayat tontonan. rex bisa menyalin judul yang sudah ditonton, posisi lanjut menonton, dan rating bintang dari server Plex lain.
Judul yang sudah ditonton tetap ditandai sudah ditonton. Judul yang ditonton sebagian kembali ke **Continue Watching**. Acara TV dan musim dihitung ulang episodenya.

Jalankan sekali dari komputer mana pun di rumah. Setiap orang yang memakai rex bisa mengimpor riwayat tontonannya sendiri.

## Sebelum kamu mulai {#before-you-start}

| Yang Anda butuhkan | Alasannya |
|---|---|
| rex sudah disiapkan, dengan library Anda di dalamnya, seperti di [rex dengan aplikasi Anda sendiri](any-source.md), [rex dengan addon Stremio Anda](stremio.md) atau [rex dengan zurg](with-zurg.md) | rex hanya menyalin riwayat ke judul yang sudah ada di library-nya. Jika library Anda masih terisi, jalankan impor lagi nanti: impor hanya menambahkan yang baru |
| rex nightly **2026.10.31 atau yang lebih baru** | Perbarui seperti di bagian Updating pada [rex's Updating section](any-source.md#updating) |
| Server Plex lama Anda, sedang berjalan | rex membaca riwayat dari server tersebut. Nyalakan lagi jika Anda mematikannya saat pindah ke rex |
| Komputer di jaringan rumah Anda, dengan `curl` | Impor hanya berjalan dari jaringan rumah Anda. Windows 10 dan 11, macOS, dan Linux semuanya sudah memiliki `curl` |

## 1. Salin alamat server lama kamu {#1-copy-your-old-servers-address}

1. Buka [app.plex.tv](https://app.plex.tv) di browser dan masuk sebagai **kamu sendiri**, akun yang riwayatnya ingin kamu ambil.
2. Pilih server lama kamu dan buka film apa pun di server itu.
3. Klik **⋯** (More), lalu **Get Info**.
4. Klik **View XML** di pojok kiri bawah kotak **Media Info** yang terbuka. Tab baru akan terbuka, penuh dengan teks.

   ![Kotak Media Info yang dibuka Get Info, dengan View XML di pojok kiri bawah](../assets/rex/40-plex-get-info.webp)
5. Salin **seluruh alamat** dari address bar tab itu.

Bentuknya seperti ini, semuanya dalam satu baris, dan diakhiri dengan `X-Plex-Token=` diikuti sebuah kode:

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

Kode itu adalah **Plex token** untuk server tersebut. Fungsinya seperti password untuk akun Plex kamu, jadi jangan pernah menempelkannya di Discord, postingan support, atau screenshot.

**Tidak ada View XML di langkah 4?** Plex Web hanya menampilkannya untuk server yang kamu miliki, jadi server yang dibagikan orang lain ke kamu tidak punya opsi ini. Gunakan developer tools browser di server lama kamu, seperti di [langkah 2](#2-get-your-token-on-rex), lalu pilih satu request ke server lama kamu (alamatnya mengandung `plex.direct`). Klik kanan request itu dan salin alamatnya: **Copy**, **Copy URL** di Chrome dan Edge, **Copy Value**, **Copy URL** di Firefox. Alamat itulah yang kamu butuhkan. Alamat itu berisi `X-Plex-Token=` dan kode di dalamnya, di antara bagian `X-Plex-` lainnya: tempelkan semuanya.

## 2. Ambil token kamu di rex {#2-get-your-token-on-rex}

Karena rex dibagikan ke kamu, **Get Info** di rex tidak punya **View XML**. Plex Web hanya menampilkannya untuk pemilik server. Jadi, ambil token dari browser kamu, seperti yang dikirim app.plex.tv ke rex:

1. Di app.plex.tv, masih login dengan akun kamu, buka developer tools browser: tekan **F12**, atau **⌥ ⌘ I** di Mac. Di Safari, aktifkan dulu **Show features for web developers** di **Settings**, **Advanced**.
2. Buka tab **Network** dan ketik `X-Plex-Token` di kotak filter-nya.
3. Buka film apa saja di server **rex**. Daftar akan terisi dengan request.
4. Klik salah satu yang alamatnya mengarah ke rex: kalau pakai rex-direct, alamatnya memuat `rex-direct.debridmediamanager.com`, atau alamat HTTPS yang kamu atur sendiri. Jangan yang mengarah ke `plex.tv`.
5. Salin nilai `X-Plex-Token`: Chrome dan Edge menampilkannya di bawah **Payload**, Firefox di bawah **Request**. Atau salin alamat request-nya, lalu ambil bagian setelah `X-Plex-Token=` sampai ketemu `&` berikutnya.

Kode ini berbeda dengan yang ada di langkah 1. Setiap server memberi akun kamu kode sendiri. rex memakai kode ini untuk tahu riwayat tontonan siapa yang sedang ia catat.

## 3. Jalankan impor {#3-run-the-import}

Di komputer di rumah, jalankan ini dengan dua nilai kamu yang sudah ditempel. `192.168.1.20` adalah IP LAN rex, seperti di panduan instalasi: ganti dengan IP kamu.

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

Di Windows, buka **PowerShell** dan ketik `curl.exe`, bukan `curl`. Biarkan kedua pasang tanda kutip ganda: alamat dari langkah 1 mengandung karakter `&`, yang akan merusak perintah jika tanda kutipnya dihapus.

Prosesnya butuh beberapa detik, lebih lama untuk pustaka besar: rex membaca setiap film dan episode di server lama.

**Yang akan kamu lihat.** Satu baris seperti ini:

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| Angka | Artinya |
|---|---|
| `watched` | Judul yang ditandai sudah ditonton oleh rex, dengan jumlah putar dan tanggal dari server lama |
| `inProgress` | Judul yang sempat kamu tonton sebagian: akan dilanjutkan dari tempat kamu berhenti |
| `rated` | Judul yang mendapat rating bintangnya |
| `alreadyHere` | Judul yang sudah kamu tonton atau mulai di rex. rex menyimpan yang sudah ada dan tidak mengubah apa pun di sana |
| `notInRex` | Judul yang punya riwayat di server lama tetapi tidak ada di rex, atau tidak sebagai judul yang sama |

Buka lagi aplikasi Plex kamu (atau muat ulang app.plex.tv) untuk melihatnya.

## Jalankan lagi kapan saja {#run-it-again-any-time}

Menjalankannya lagi tidak mengubah apa pun yang sudah kamu punya, jadi jalankan kapan saja ketika lebih banyak bagian pustakamu sudah masuk. Menjalankannya lagi tepat setelah yang pertama akan menampilkan `"watched":0` dan yang sebelumnya di bawah `alreadyHere`.

## Yang tidak ikut disalin {#what-is-not-copied}

- Riwayat orang lain di server lama Anda. Setiap orang menjalankan impor dengan dua token mereka sendiri.
- Daftar riwayat putar server, playlist, dan koleksi.
- Rating bintang untuk seluruh serial dan season. Rating film dan episode ikut disalin.
- Judul di library yang agent-nya di server lama bukan **Plex Movie** atau **Plex TV Series** (agent lama, seperti Plex Movie (Legacy) dan TheTVDB). rex mencari judul berdasarkan id yang diberikan agent Plex saat ini, sedangkan agent lama memberikan id yang berbeda, jadi judul-judul ini dihitung di `notInRex`.

## Jika tidak berhasil {#if-it-does-not-work}

| Yang kamu lihat | Yang harus dilakukan |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | Alamat yang di-paste berhenti sebelum token. Salin lagi dari address bar atau developer tools, lalu paste semuanya |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | Ada yang bukan alamat masuk ke tanda kutip setelah `-d` |
| `... refused the token: copy the address from View XML again` | Server lama menolak token. Ulangi langkah 1, dengan developer tools jika server itu dibagikan kepada kamu |
| `could not reach https://...` | rex tidak bisa terhubung ke server lama kamu. Server itu harus sedang berjalan, dan **mesin rex** harus bisa menjangkaunya: rex membaca dari server itu, bukan komputer kamu |
| `run the import from your home network` | Kamu mengirim perintah ke alamat luar rex. Gunakan LAN IP rex, seperti di langkah 3 |
| Halaman `Unauthorized` | rex tidak menerima token dari langkah 2. Salin lagi, dari permintaan ke rex, bukan ke `plex.tv` |
| `notInRex` jauh lebih tinggi dari yang kamu perkirakan | Sebagian besar library kamu belum ada di rex, atau library lama kamu memakai salah satu agent Plex yang lebih lama. Jalankan lagi setelah library kamu sudah masuk |

Masih buntu? Tanyakan di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Cara minta bantuan](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.
