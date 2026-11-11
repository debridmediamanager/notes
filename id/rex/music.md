# Musik dengan rex {#music-with-rex}

rex dapat menyimpan pustaka musik untuk Plexamp, Plex Web, dan Plex untuk Android. Sebuah addon musik mengirim setiap lagu beserta rilis MusicBrainz-nya. Plex mengisi nama, sampul, detail artis, genre, dan artis serupa.

Yang kamu dapatkan:

- **Album yang Plex kenali.** Album yang dikirim dengan rilis MusicBrainz-nya tampil seperti di server Plex mana pun, dengan sampul dan nama lagu dari Plex. Album yang tidak dikenali Plex menampilkan nama dan gambar yang dikirim oleh addon.
- **Kualitas asli.** Lagu diputar dalam format aslinya, misalnya FLAC.
- **Lirik dan loudness**, jika addon mengirimkannya: lirik ditampilkan bersama lagu, dan rex meneruskan loudness setiap lagu ke aplikasi, seperti yang dilakukan Plex.
- **Pemutaran, rating, dan playlist milikmu sendiri.** Pemutaran, rating, dan playlist disimpan per akun Plex. Playlist pintar dari Plexamp juga dibuat di rex.

## Sebelum kamu mulai {#before-you-start}

| Yang Anda butuhkan | Alasannya |
|---|---|
| Rex nightly bertanggal 2026.11.02 atau yang lebih baru | Musik masuk di build itu |
| rex sudah disiapkan seperti di [rex dengan aplikasi Anda sendiri](any-source.md) | Di situlah pustaka musik muncul |
| Addon musik | Program apa pun yang mengirim lagu lewat feed API rex. Untuk folder album di disk Anda sendiri, [Tutorial: addon musik](addon-music.md) adalah contoh lengkap dalam satu file Python |
| [Konversi video](any-source.md#converting-video-optional), opsional | rex hanya mengonversi lagu untuk aplikasi yang diatur ke kualitas musik lebih rendah dari aslinya |

## Langkah 1. Pasang rex dan tambahkan ke akun Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Ikuti [rex dengan aplikasimu sendiri](any-source.md):

1. [Langkah 1. Pasang rex](any-source.md#step-1-install-rex), termasuk mencari IP LAN rex. Halaman ini menulisnya sebagai `192.168.1.20`: ganti dengan IP milikmu.
2. [Langkah 3. Tambahkan ke akun Plex](any-source.md#step-3-add-it-to-a-plex-account): daftarkan rex di akun baru tersebut dan bagikan ke akunmu sendiri.

## Langkah 2. Arahkan addon musik Anda ke rex {#step-2-point-your-music-addon-at-rex}

rex needs a music library for the songs. Если ваш аддон объявляет её, rex создаёт её при регистрации аддона. Если не объявляет, сначала добавьте её в приложении Plex, вошедшем под новым аккаунтом: **Add Library**, **Music**, любая папка. Песня, отправленная до появления музыкальной библиотеки, отклоняется.

Затем укажите аддону адрес rex, `http://192.168.1.20:32400`, так, как написано в его собственной инструкции. Он регистрируется в rex и отправляет свои альбомы.

**Что вы должны увидеть.** В логе rex:

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    SECTION create Music (artist) for <addon>'s music
INFO    FEED <addon> upsert: ...
```

Строка `SECTION create` появляется только тогда, когда аддон объявляет библиотеку. Музыкальная библиотека появляется в rex, каждый альбом находится под своим исполнителем. Песня, которую rex отклонил, попадает в лог с причиной, например `no music library holds <file>`.

## Langkah 3. Bagikan pustaka musik {#step-3-share-the-music-library}

Perpustakaan musik baru, jadi belum ada yang membagikannya. Saat sudah masuk dengan akun baru, tambahkan ke share akun Anda sendiri dan ke share semua orang lain di **Manage Library Access** ([Share rex](sharing.md)).

## Langkah 4. Dengarkan {#step-4-listen}

- **Plexamp**: masuk dengan akun Plex kamu sendiri lalu pilih library musik rex sebagai library kamu.
- **Plex Web dan Plex untuk Android**: library musik ada bersama library rex lainnya.

**Yang seharusnya kamu lihat.** Album dengan sampul dan nama track dari Plex, serta artis dengan fotonya. Tekan play.

## Yang tidak bisa dilakukan {#what-it-cannot-do}

- **Tidak ada radio, mix, atau stasiun.** Radio, mix, stasiun, dan lagu serupa secara sonik di Plexamp butuh analisis setiap lagu, dan rex tidak melakukannya.
- **Tidak punya folder musik sendiri.** rex tidak memindai apa pun dan tidak membaca tag. Sebuah addon harus mengirim setiap lagu, beserta rilis MusicBrainz dari album-nya supaya Plex bisa memberinya nama.
- **Dua salinan album berarti dua album**, seperti di server Plex mana pun: salinan FLAC dan salinan MP3 masing-masing tampil sebagai album sendiri.
- **Sudah diuji di Plexamp, Plex Web, dan Plex untuk Android.** Aplikasi Plex lain, serta unduhan offline di Plexamp, belum pernah dicoba.

Untuk membuat addon musik sendiri, mulailah dari [Tutorial: addon musik](addon-music.md); [Building rex addons](addons.md#music) memuat setiap field-nya.
