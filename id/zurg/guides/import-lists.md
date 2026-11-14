# Mengikuti daftar di Sonarr dan Radarr {#following-a-list-in-sonarr-and-radarr}

Sonarr dan Radarr bisa mengikuti daftar acara TV atau film. Setiap judul di daftar itu akan ditambahkan dan dicari. Dengan zurg sebagai download client, setiap grab masuk ke akun debrid kamu dan diimpor ke `__magic__` seperti biasa. Jadi daftar itu adalah bagian library yang mengisi dirinya sendiri. Daftar horor memberi kamu bagian library horor, dan judul baru akan muncul seiring daftar itu bertambah.

Halaman ini mengasumsikan \*arrs sudah melakukan grab melalui zurg. Kalau belum, mulailah dengan [Sonarr & Radarr untuk torrent](sonarr-radarr-torrents.md).

## Gunakan MDBList, bukan IMDb {#use-mdblist-and-not-imdb}

Kedua aplikasi masih menampilkan tipe list IMDb, dan tidak ada yang bisa dipakai dengan list IMDb biasa lagi.

- Radarr menolak ID list berbentuk `ls12345678`. Radarr hanya menerima `top250` atau `popular`, atau watchlist pengguna `ur12345678`.
- Sonarr menerima ID tersebut, lalu mendapat jawaban kosong dari IMDb. Tombol Test menampilkan `Imdb call resulted in an unexpected StatusCode [Accepted]`.

[MDBList](https://mdblist.com) adalah jalan keluarnya untuk kedua aplikasi. MDBList menerbitkan list apa pun sebagai feed JSON yang bisa dibaca kedua aplikasi lewat tipe Custom List. Film dan serial ada di list yang terpisah, jadi kamu perlu menambahkan satu list ke masing-masing aplikasi.

## 1. Pilih daftar {#1-pick-a-list}

Daftar publik tidak perlu akun. Cari genre yang kamu mau di MDBList lalu buka sebuah daftar. Berikut dua daftar horor yang masih berfungsi per Oktober 2026:

| Daftar | Berisi | URL feed |
|---|---|---|
| Horor | film | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horor Serial | serial | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

URL feed adalah URL halaman daftar tersebut dengan `/json` di belakangnya. Buka dulu di browser. Kamu akan melihat halaman teks yang diawali dengan `[{"id":`.

Untuk membuat daftar sendiri, masuk ke MDBList lalu buat daftar baru. Daftar bisa mengikuti filter seperti genre dan rating minimum, atau menyalin daftar IMDb yang sudah kamu punya. URL feed-nya bekerja dengan cara yang sama.

## 2. Tambahkan ke Radarr {#2-add-it-to-radarr}

**Settings → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | bebas, misalnya `Horror` |
| Enable | on |
| Enable Automatic Add | on |
| Search on Add | baca peringatan di bawah dulu |
| Monitor | Movie Only |
| Root Folder | folder film kamu di dalam `__magic__`, misalnya `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` di macOS, `Z:\__magic__\movies` di Windows) |
| Quality Profile | yang kamu pakai |
| List URL | URL feed film |

Tekan **Test** lalu **Save**.

## 3. Tambahkan ke Sonarr {#3-add-it-to-sonarr}

**Settings → Import Lists → + → Custom List**

| Field | Value |
|---|---|
| Name | apa saja, misalnya `Horror Shows` |
| Enable Automatic Add | on |
| Monitor | All Episodes, atau Pilot Episode untuk mencoba satu serial dulu |
| Root Folder | folder TV kamu di dalam `__magic__`, misalnya `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` di macOS, `Z:\__magic__\tv` di Windows) |
| Quality Profile | yang kamu pakai |
| Series Type | Standard |
| Season Folder | on |
| Search for Missing Episodes | baca peringatan di bawah dulu |
| List URL | URL feed serial |

Tekan **Test** lalu **Save**.

## Daftar besar langsung mengambil semuanya sekaligus {#big-lists-grab-everything-at-once}

Daftar dengan search on add aktif akan langsung mengambil setiap judul begitu daftar tersebut disinkronkan. Daftar film di atas berisi 400 judul dan daftar serial berisi 148 serial beserta setiap episodenya. Itu banyak pengambilan sekaligus. Akun debrid dan indexer Anda akan terasa bebannya, dan indexer yang punya batas rate limit akan mulai menolak pencarian.

Ada dua cara yang lebih ringan.

- Biarkan search on add tetap mati. Judul-judulnya tetap ditambahkan dan dipantau, tetapi tidak ada pencarian. Cari judul yang Anda inginkan dari halaman Movies atau Series.
- Mulai dengan daftar yang pendek. Tambahkan daftar yang besar setelah batch pertama sudah masuk.

Aplikasi juga menyinkronkan daftar sesuai jadwalnya sendiri. **System → Tasks → Import List Sync** menjalankannya sekarang juga.

## Menghapus daftar {#removing-a-list}

Menghapus daftar akan menghentikan judul baru masuk dari daftar tersebut. Judul yang sudah ditambahkan tetap ada. Di **Settings → Import Lists**, **Clean Library Level** menentukan apa yang terjadi pada judul yang keluar dari daftar. Biarkan di Disabled kecuali kamu memang ingin aplikasi menghapus item secara otomatis.
