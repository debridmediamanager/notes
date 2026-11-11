# Kometa dengan rex {#kometa-with-rex}

[Kometa](https://kometa.wiki) membuat koleksi, menambahkan badge pada poster (4K, HDR, rating) dan mengisi rating serta genre di server Plex. rex menjawab Kometa seperti server Plex, jadi config yang sama bisa dipakai untuk library rex kamu.

Semua di bawah ini sudah diuji pada 2026-10-23 dengan Kometa 2.5.3 (image Docker `kometateam/kometa`), dan sebuah rex yang sudah diklaim berisi film dan satu show.

## Sebelum kamu mulai {#before-you-start}

| Anda perlu | Alasannya |
|---|---|
| rex sudah disiapkan dan ditambahkan ke akun Plex, seperti di [Tambahkan ke akun Plex](any-source.md#step-3-add-it-to-a-plex-account) | Kometa mengedit library, dan hanya akun tempat rex terdaftar yang boleh melakukannya. rex yang belum diklaim tidak melayani siapa pun |
| rex nightly **2026.10.24 atau lebih baru** | Perbarui seperti di [bagian Updating rex](any-source.md#updating) |
| Docker di mesin mana pun yang bisa menjangkau rex | Kometa berjalan sebagai container. Dokumentasi Kometa sendiri membahas [cara instal lainnya](https://kometa.wiki/en/latest/kometa/install/overview/) |
| Kunci API TMDb gratis | Kometa membutuhkannya untuk dirinya sendiri, meskipun rex tidak. Buat di **Settings → API** di themoviedb.org, seperti yang dijelaskan di [halaman getting started TMDb](https://developer.themoviedb.org/docs/getting-started) |

## 1. Dapatkan token rex {#1-get-rexs-token}

Kometa masuk ke rex memakai Plex token. Gunakan token yang diberikan rex saat kamu mendaftarkannya. Di mesin rex:

+++ Linux dan macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

Dengan [rex di Docker](any-source.md#run-rex-in-docker), file-nya hanya bisa diakses root: `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**Yang seharusnya kamu lihat.** Satu baris, `"token": "..."`. Salin teks di antara pasangan tanda kutip kedua. Perlakukan seperti password: token ini membuka seluruh server. Jika kamu mendaftarkan rex lagi, token akan berubah dan Kometa butuh yang baru.

**Bukan token akun kamu sendiri.** Di [Bagikan ke akun kamu sendiri](any-source.md#share-it-with-your-own-account), akun kamu mendapat rex sebagai share. Share hanya bisa menonton, tidak bisa mengedit, jadi dengan token-nya Kometa berhenti dengan `Plex Token is read only`, atau, jika share mengizinkan download, gagal saat pertama kali melakukan perubahan.

## 2. Tulis config Kometa {#2-write-kometas-config}

Buat folder untuk Kometa, misalnya `~/kometa/config` (`$HOME\kometa\config` di Windows), lalu taruh ini di `config.yml` di dalamnya:

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` adalah IP LAN dan port rex, alamat dari [Install rex](any-source.md#step-1-install-rex). Jangan pakai `127.0.0.1` atau `localhost`, karena di dalam container Kometa, alamat itu mengarah ke container itu sendiri.
- Nama di bawah `libraries:` harus persis sama dengan library di rex: **Movies** dan **TV Shows**, plus library lain yang kamu tambahkan atau ubah namanya. Hapus library yang tidak ingin kamu biarkan disentuh Kometa.

Ini cuma awal yang sederhana. Dokumentasi Kometa punya [daftar lengkap setiap koleksi dan overlay default](https://kometa.wiki/en/latest/defaults/guide/), dan file koleksi buatanmu sendiri juga bisa dipakai.

## 3. Jalankan sekali {#3-run-it-once}

+++ Linux dan macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` membuat Kometa menjalankan satu putaran sekarang lalu berhenti. Tanpa itu, Kometa tetap berjalan dan menunggu jadwal hariannya.

**Yang harus kamu lihat.** Di output Kometa, untuk setiap library:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

Di aplikasi Plex, library film punya tab **Collections** berisi koleksi genre, dan poster-posternya memakai lencana. Akunmu sendiri dan semua orang yang kamu bagikan rex juga akan melihat koleksi dan lencana yang sama. Proses pertama di library yang besar butuh waktu cukup lama, karena Kometa membaca setiap judul dan menggambar ulang setiap poster yang diberi lencana.

## Jika tidak berhasil {#if-it-does-not-work}

| Pesan Kometa | Artinya |
|---|---|
| `Plex Token is read only. Please get a new token` | rex belum ditambahkan ke akun Plex, atau token itu milik akunmu sendiri, bukan yang dari langkah 1 |
| Kometa terhubung, tapi setiap perubahan gagal | Token itu milik akunmu sendiri. Pakai yang dari langkah 1 |
| `url_poster failed to update poster` | Mesin rex tidak bisa mengakses situs tempat gambar itu berada |
| `Plex URL is probably invalid` atau timeout | `url` tidak bisa menjangkau rex dari tempat Kometa berjalan. Buka `http://192.168.1.20:32400/identity` dari mesin itu: seharusnya menampilkan `machineIdentifier` milik rex |
| `Plex Error: Plex Library '...' not found. Options: [...]` | Nama di bawah `libraries:` tidak cocok. Salin salah satu dari daftar yang ditampilkan |

Masih buntu? Tanya di forum **rex-support** di [Discord](https://discord.com/invite/7u4YjMThXP). [Meminta bantuan](../guides/remote-help.md) menjelaskan apa saja yang perlu disertakan.

## Apa yang bisa dan tidak bisa dilihat Kometa {#what-kometa-can-and-cannot-see}

Kometa mencocokkan judul berdasarkan id TMDb, TVDb, dan IMDb yang ditampilkan rex untuk judul tersebut. Judul yang tidak berhasil diidentifikasi sumbernya, yang masih menampilkan nama file dan tidak punya poster, tidak punya id tersebut, sehingga Kometa akan melewatkannya dari apa pun yang dibangun dari id itu. Perbaiki dulu dengan Fix Match di aplikasi Plex.

Sudah diuji di rex: koleksi dari pencarian judul, berdasarkan id TMDb, dan smart collections; koleksi genre default beserta posternya; overlay resolusi dan rating; serta pembaruan rating kritikus dan genre dari TMDb. Belum diuji: playlist, library musik, dan operasi Kometa lainnya. Jika ada yang gagal, log Kometa akan menyebutkan permintaan yang gagal, dan itu layak dilaporkan di Discord.
