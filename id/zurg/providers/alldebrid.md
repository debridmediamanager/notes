# AllDebrid

`type: alldebrid`

[AllDebrid](https://alldebrid.com/?uid=1kk5i&lang=en) adalah backend lain yang memutar kredensial. Jadi `download_tokens`
dan token `.strm` terpisah sama-sama punya arti di sini. Daftar file-nya diambil dari
endpoint milik mereka sendiri, bukan dari daftar magnet. Itu mengubah rasanya saat pemindaian pertama pada library yang besar.

## Dapatkan API key {#get-the-api-key}

Masuk dan buka [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i).
Buat kunci lalu salin.

## Atur konfigurasinya {#configure-it}

```yaml
zurg: v1
providers:
  - type: alldebrid
    token: YOUR_ALLDEBRID_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Pada instalasi container baru, biarkan setup yang menuliskannya.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider alldebrid
```

Pada instalasi yang sudah punya `config.yml`, gunakan **Add provider** di
Dashboard di `http://localhost:9999/config/` atau edit filenya. Di kedua cara,
jangan lupa restart.

```bash
docker compose restart zurg
```

`ALLDEBRID_TOKEN` dibaca oleh `zurg setup`, bukan oleh daemon yang sedang
berjalan. Memasukkannya ke blok `environment:` di compose lalu menjalankan
container tidak akan berpengaruh dengan sendirinya.

## Key tambahan yang dipakai backend ini {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: alldebrid
    token: PRIMARY_AD_API_KEY
    strm_link_token: AD_KEY_FOR_STRM
    download_tokens:
      - SECOND_AD_API_KEY
```

`download_tokens` adalah kunci cadangan pada layanan yang sama. Kunci ini mengambil alih ketika jatah bandwidth kunci yang aktif sudah habis. Kunci ini memakai katalog entri ini, dan perpustakaan milik mereka sendiri tidak pernah diimpor.

`strm_link_token` menangani permintaan baca yang masuk ke `/strm/` agar pemutar yang membuka file `.strm` tidak menghabiskan kunci yang dipakai mount live kamu untuk streaming. Jika tidak diatur, kunci ini kembali memakai `token`.

## Scan pertama akan mengisi sedikit demi sedikit {#the-first-scan-fills-in-gradually}

AllDebrid v4.1 memindahkan detail file dari daftar magnet ke endpoint terpisah. Mengambil daftar magnet tidak memberi tahu zurg apa saja isinya. Setiap rilis butuh satu kali pencarian.

Kabar baiknya, pencarian itu cukup dilakukan **sekali saja** dan tidak setiap kali restart. Struktur file sebuah magnet tidak berubah begitu statusnya Ready. Jadi cache info zurg di disk berlaku permanen untuk magnet tersebut. Ada batcher di depan endpoint yang menangani pemindaian awal. Yang kamu lihat saat pertama kali menjalankan adalah library besar yang muncul sedikit demi sedikit, dan setelah itu proses ini tidak perlu diulang lagi.

## Batasan yang perlu diketahui {#limits-worth-knowing}

**Tidak ada batas maksimal magnet aktif yang dipublikasikan.** zurg tidak membuat batas sendiri. Repair tidak pernah menunggu ruang yang memang tidak pernah terbatas.

**600 permintaan per menit untuk satu kunci.** Itulah anggaran yang tercantum di dokumentasi. zurg mengatur lajunya di angka 600 dikurangi 100, supaya percobaan ulang yang dilakukan klien HTTP-nya sendiri tidak mendorong lonjakan permintaan melewati batas yang sebenarnya. Dalam praktiknya, konkurensi adalah batasan yang paling menentukan, dan jumlahnya dibatasi 12 agar sesuai dengan dokumentasi 12 permintaan per detik.

**Koneksi ke-33 ke satu server pengiriman akan mendapat 429.** Diukur pada 2026-08-23 dengan membuka satu koneksi setiap 500 ms dan menahannya. AllDebrid membuat nama host pengiriman yang baru setiap kali melakukan unlock. Jadi batasan ini hanya berlaku ketika beberapa pembacaan kebetulan memakai host yang sama. zurg mengantrekan permintaan di atas 32 alih-alih membuka koneksi baru.

**Tidak ada pemilihan file per file.** Menambahkan magnet akan mengambil semuanya, dan repair menambahkan ulang seluruh rilisnya.

**Konten bisa hilang dengan sendirinya.** Magnet dihapus dari akun seiring waktu, dan tautan juga bisa dihapus oleh hoster. Rilis yang sudah hilang adalah hasil yang wajar, bukan kerusakan. Repair tidak akan menyentuhnya kecuali kamu memintanya.

**Tautan tersimpan tidak basi.** Tautan terkunci yang tercatat untuk sebuah file dibuat ulang dari kondisi terkini magnet tersebut. Status magnet sudah menunjukkan apakah datanya ada. zurg tidak perlu menghabiskan satu unlock per torrent di setiap pemindaian dingin hanya untuk mengetahui apa yang sudah bisa dilihat dari statusnya.

## Cek apakah sudah berhasil {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/alldebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Kalau cuma ada satu akun, folder akunnya sendiri tidak ditampilkan di daftar root mount,
jadi mount menampilkan file yang sama di bawah `__all__`.

## Saat terjadi masalah {#when-it-goes-wrong}

**`AllDebrid rejected the API key` di log.** Kunci API-nya sudah dicabut atau dibuat ulang. Ambil yang baru dari [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i) lalu perbarui entri-nya.

**Library yang baru pertama kali dibuka muncul lambat.** Ini memang wajar. Lihat bagian di atas. Prosesnya hanya satu kali lookup per rilis dan tidak akan diulang.

**Sebuah rilis bisa diputar dari mount lain, tapi kena 404 di `__alldebrid__`.** Status rusak dinilai per akun, dan direktori itu memaksa pembacaan hanya lewat akun ini. Akun lain mungkin punya salinan yang bagus.
