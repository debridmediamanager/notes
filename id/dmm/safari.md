# Tombol DMM di Safari {#dmm-buttons-in-safari}

Ekstensi browser DMM menampilkan tombol **DMM🔎** di situs film dan serial. Tombol itu membuka judul tersebut di DMM. Di sebelah tautan magnet, ada tombol **DMM🧲** yang menambahkan torrent ke pustaka DMM kamu.

Di Chrome dan Firefox, install [ekstensi Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) atau [add-on Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). Safari memakai kode yang sama sebagai [userscript Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) dengan manajer userscript.

Pilih salah satu manajer:

| Manajer | Harga | Berjalan di | Memperbarui skrip |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | Gratis | Mac, iPhone, iPad | Saat kamu ketuk **Update** di popup-nya |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | $2.99 | Mac, iPhone, iPad | Otomatis |

## Dengan Userscripts {#with-userscripts}

1. Pasang [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) dari App Store lalu buka sekali.
2. Aktifkan ekstensinya:
   - **Mac:** Safari > **Settings** > **Extensions**, centang **Userscripts**.
   - **iPhone dan iPad:** **Settings** > **Apps** > **Safari** > **Extensions** > **Userscripts**, nyalakan **Allow Extension**.
3. Izinkan jalan di semua situs. Tautan magnet bisa ada di situs mana saja, jadi skripnya harus bisa jalan di mana-mana.
   - **Mac:** di panel **Extensions** yang sama, klik **Edit Websites…** lalu atur **When visiting other websites** ke **Allow**.
   - **iPhone dan iPad:** di layar **Userscripts** yang sama, atur **All Websites** ke **Allow**.
4. Di Safari, buka [file userscript DMM](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). Filenya akan tampil sebagai teks biasa.
5. Buka popup Userscripts: tombol toolbar-nya di Mac, atau tombol **aA** di address bar di iPhone. Ketuk prompt instalasi yang muncul lalu konfirmasi.

Untuk memperbarui nanti, buka popup Userscripts dan ketuk **Update** saat skrip DMM muncul di daftar.

## Dengan Tampermonkey {#with-tampermonkey}

1. Pasang [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) dari App Store.
2. Aktifkan dan biarkan berjalan di setiap situs, seperti pada langkah 2 dan 3 di atas, dengan **Tampermonkey** sebagai ganti **Userscripts**.
3. Di Safari, buka [halaman Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) untuk skrip tersebut lalu klik **Install this script**.
4. Tampermonkey akan membuka halaman instalasinya. Klik **Install**.

Tampermonkey memeriksa versi baru sekali sehari.

## Pastikan ini berfungsi {#check-it-works}

Buka [Dune: Part Two di Letterboxd](https://letterboxd.com/film/dune-part-two/). Tombol **DMM🔎** berwarna teal muncul di sebelah judul, dan tombol itu membuka film tersebut di DMM.

Tidak ada tombol? Coba cek hal-hal berikut:

- Popup manajer menampilkan **Debrid Media Manager** dan sakelarnya sudah menyala.
- Safari mengizinkan manajer berjalan di situs itu. Saat diminta, pilih **Always Allow on Every Website**.
- Halaman sudah selesai dimuat. Situs seperti TMDB, Wikipedia, dan AniList menampilkan tombolnya sedikit setelah halaman selesai dimuat.
