# DMM hash list: tambahkan library orang lain ke library kamu {#dmm-hash-lists-add-someones-library-to-yours}

Daftar hash adalah daftar rilis yang dibagikan seseorang dari pustaka debrid mereka lewat DMM. Buka salah satu, masuk ke DMM dengan layanan debrid Anda, lalu tekan tombol layanan Anda: rilisnya akan masuk ke akun Anda sendiri. Daftar yang dibagikan ada di [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com), dan Anda bisa membagikan daftar Anda sendiri dari **Library** di DMM dengan **Share List**.

Sebuah daftar berisi nama rilis, hash, dan ukurannya. Tidak ada file dan tidak ada akun.

## Cari list {#find-a-list}

- Di halaman utama DMM, tekan **Hash lists**. Halaman itu akan membuka [hashlists.debridmediamanager.com](https://hashlists.debridmediamanager.com) dengan daftar acak. **Previous hash list**, **Random hash list** dan **Next hash list** dipakai untuk pindah antar daftar.
- Orang-orang memposting daftar di forum **hashlists** di [Discord](https://discord.com/invite/7u4YjMThXP). Setiap daftar berupa tautan seperti `https://hashlists.debridmediamanager.com/<id>.html`. Kalau dibuka, daftar tersebut akan terbuka di DMM.

## Tambahkan list ke library kamu {#add-a-list-to-your-library}

1. Buka daftar. Jika tertulis **Login to RD/AD/TB/PM/OC/DL to download**, masuk ke [DMM](https://debridmediamanager.com) dulu di browser yang sama (lihat [cara masuk](index.md#sign-in)), lalu buka lagi daftarnya.
2. DMM memeriksa rilis mana yang sudah dimiliki layanan Anda. DMM hanya menampilkan rilis tersebut dan menyembunyikan yang sudah ada di pustaka Anda. Kotak hijau **hidden** menghitung jumlah rilis yang disembunyikan.
3. Persempit daftar jika perlu:
   - **Movies** dan **TV Shows** menampilkan satu jenis saja. Angkanya menghitung judul, bukan file.
   - **One per title** menyimpan rilis terbaik untuk setiap judul.
   - Chip hijau **other files** di sebelah judul menampilkan semua rilisnya.
   - **quick search on filename, hash, or id; supports regex** digunakan untuk mencari dalam daftar.
4. Tekan tombol di sebuah baris (**RD**, **TB**, **AD**, **PM**, **OC** atau **DL**) untuk menambahkan rilis itu saja.
5. Atau tekan **RD Download** (**TB Download**, **PM Download** dan seterusnya) untuk menambahkan semua rilis yang ditampilkan. Angka di tombol itu menunjukkan jumlahnya. DMM akan bertanya dulu, misalnya **Add 11 releases to Premiumize?**: tekan **Add 11** untuk memulai.

![Daftar hash bersama berisi film terbuka di DMM, sudah masuk dengan Premiumize](../assets/dmm-hashlists/01-hash-list.webp)

**Show All** juga menampilkan rilis yang tidak dimiliki layanan Anda, dan **Show Instant** kembali ke rilis yang sudah ter-cache.

**RD Download** hanya menambahkan rilis yang sudah dimiliki Real-Debrid, satu per menit, karena Real-Debrid menjeda akun yang menambah terlalu cepat. Enam puluh rilis memakan waktu sekitar satu jam. Penambahan berjalan di halaman, jadi biarkan tab tetap terbuka sampai muncul tulisan **Started 60 downloads.** TorBox dan AllDebrid melewati rilis yang tidak mereka miliki di cache.

## Bagikan library kamu sendiri {#share-your-own-library}

1. Di halaman utama DMM, tekan **Library**.
2. Cari atau centang rilis yang ingin kamu bagikan. Jika tidak ada yang dicentang, semua yang ditampilkan akan dibagikan.
3. Tekan **Share List** (tombolnya bertuliskan **Share (3)** jika kamu mencentang tiga rilis). Ketik nama di **Enter a title for the hash list** lalu tekan **OK**.
4. DMM akan membuka alamat baru daftar kamu di hashlists.debridmediamanager.com. Alamat itu bisa menampilkan 404 selama satu sampai dua menit saat sedang dipublikasikan. Muat ulang halamannya, lalu bagikan alamat tersebut.

![The title prompt after pressing Share List](../assets/dmm-hashlists/02-share-list.webp)

Daftar yang dibagikan bersifat publik. Siapa pun yang memiliki alamatnya bisa membukanya, dan **Random hash list** bisa menampilkan daftar kamu ke orang asing. Hanya nama, hash, dan ukuran yang disertakan: tidak pernah akun, kunci, atau alamat tracker kamu.

Untuk membagikan satu rilis tanpa mempublikasikan apa pun, tekan ikon bagikan di ujung barisnya di library (atau **Hashlist** di detailnya). DMM akan membuka daftar yang hanya berisi satu rilis. Salin alamat halaman itu lalu kirimkan.

## Ketika ada yang salah {#when-something-is-wrong}

| Yang Anda lihat | Yang harus dilakukan |
|---|---|
| **Login to RD/AD/TB/PM/OC/DL to download** | Anda belum masuk ke DMM di browser ini. Masuk dulu, lalu buka daftar itu lagi. |
| Semuanya **hidden** dan daftarnya terlihat kosong | Baris yang hidden sudah ada di library Anda, atau layanan Anda tidak memilikinya. Tekan **Show All**. |
| **This hash list is still being published; refresh in a minute or two.** | Daftar ini baru saja dibagikan. Tunggu satu atau dua menit, lalu refresh. |
| **0 files** dan tidak ada baris | Daftar itu kosong. Tekan **Next hash list** atau **Random hash list**. |
| **Everything already downloaded** | Setiap rilis yang ditampilkan sudah ada di library Anda. |
| **Torrent not instant in TorBox; skipped.** atau **Torrent not instant in AD; skipped.** | Layanan Anda tidak punya cache untuk torrent itu, jadi DMM melewatinya alih-alih memulai download. |
| **Skipping 3 items with no info hash — they cannot be shared.** | Baris-baris itu (misalnya TorBox web downloads) tidak punya hash untuk dibagikan. Sisa daftarnya tetap dibagikan. |
| **Failed to generate hash list; try again soon.** | Gagal membagikan daftar. Coba lagi nanti. |

Masih bingung? Tanyakan di forum **dmm-support** di [Discord](https://discord.com/invite/7u4YjMThXP).

## Pertanyaan {#questions}

### Bagaimana cara menambahkan hash list ke library saya sendiri? {#how-do-i-add-hash-lists-to-my-own-library}

Buka daftarnya, masuk ke DMM dengan layanan debrid Anda, lalu tekan tombol layanan Anda pada sebuah baris, atau **RD Download** (atau **Download** layanan Anda) untuk semua yang ditampilkan. Lihat [Add a list to your library](#add-a-list-to-your-library).

### Kenapa semua item di hash list saya tersembunyi? {#why-are-all-the-items-in-my-hash-list-hidden}

DMM menyembunyikan apa yang sudah ada di library Anda dan apa yang tidak ada di cache layanan Anda. Kotak **hidden** menunjukkan jumlahnya. **Show All** menampilkan sisanya.

### Kenapa acara TV tidak muncul di hash list? {#why-dont-tv-shows-show-up-in-a-hash-list}

Tekan **TV Shows** di bagian atas daftar. Jika tertulis **0 TV Shows**, berarti daftar itu tidak punya acara TV: kebanyakan daftar bersama berisi film. Acara yang tidak tersedia di layanan Anda juga disembunyikan, jadi coba **Show All**.

### Kenapa menambahkan hash list selambat ini? {#why-is-adding-a-hash-list-so-slow}

Di Real-Debrid, DMM menambahkan satu rilis per menit supaya Real-Debrid tidak menangguhkan akun Anda. Layanan lainnya berjalan lebih cepat.

### Apakah ada API untuk menanyakan hash list? {#is-there-an-api-to-query-the-hash-lists}

Tidak ada search API. Setiap shared list adalah sebuah file di [repositori hashlists](https://github.com/debridmediamanager/hashlists) yang publik di GitHub. Setiap halaman mengarahkan ke DMM dengan list dikemas ke dalam link setelah `#` (JSON nama, hash, dan ukuran yang dikompresi dengan lz-string). List yang sangat besar disimpan di sebelahnya sebagai `lists/<id>.txt`.

### Apakah membagikan list juga membagikan akun saya? {#does-sharing-a-list-share-my-account}

Tidak. Daftar hanya berisi nama rilis, hash, dan ukuran.
