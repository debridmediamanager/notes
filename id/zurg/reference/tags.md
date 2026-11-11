# Dokumentasi Tag zurg {#zurg-tags-documentation}

Dokumen ini menjelaskan semua tag yang bisa otomatis diterapkan ke torrent di zurg.

## Tag Resolusi {#resolution-tags}

Tag resolusi diterapkan berdasarkan dimensi video dengan toleransi 5%. Sebuah stream cocok dengan suatu tingkat jika lebar dan tingginya minimal 95% dari dimensi yang tercantum. Gambar tertanam (cover art, thumbnail) diabaikan. Hanya tag resolusi tertinggi yang cocok yang diterapkan.

| Tag | Deskripsi |
|-----|-----------|
| `zurg_8k` | Resolusi >= 7680x4320 |
| `zurg_4k` | Resolusi >= 3840x2160 |
| `zurg_1440p` | Resolusi >= 2560x1440 |
| `zurg_1080p` | Resolusi >= 1920x1080 |
| `zurg_720p` | Resolusi >= 1280x720 |
| `zurg_480p` | Resolusi >= 720x480 |

## Tag Dynamic Range {#dynamic-range-tags}

Hanya salah satu tag ini yang diterapkan, tergantung karakteristik dynamic range video:

| Tag | Deskripsi |
|-----|-----------|
| `zurg_hdr` | Konten HDR (dideteksi dari color space BT.2020) |
| `zurg_dv` | Konten Dolby Vision |
| `zurg_sdr` | Konten Standard Dynamic Range (diterapkan saat tidak ada HDR maupun DV yang terdeteksi) |

Saat metadata HDR dan Dolby Vision sama-sama ada, tag Dolby Vision yang diutamakan dan `zurg_hdr` tidak diterapkan.

## Tag Bitrate Video {#video-bitrate-tags}

Tag bitrate video didasarkan pada bitrate stream video tertinggi yang ditemukan di semua file yang dianalisis, dengan mengabaikan gambar tertanam (cover art, thumbnail). Hanya tingkat tertinggi yang cocok yang diterapkan.

| Tag | Deskripsi |
|-----|-----------|
| `zurg_ultra_high_video_bitrate` | Bitrate video ≥ 100 Mbps |
| `zurg_high_video_bitrate` | Bitrate video ≥ 70 Mbps dan < 100 Mbps |
| `zurg_moderate_video_bitrate` | Bitrate video ≥ 40 Mbps dan < 70 Mbps |
| `zurg_low_video_bitrate` | Bitrate video ≥ 10 Mbps dan < 40 Mbps |
| `zurg_very_low_video_bitrate` | Bitrate video ≥ 0 Mbps dan < 10 Mbps |

## Tag Bitrate Audio {#audio-bitrate-tags}

Tag bitrate audio didasarkan pada bitrate audio tertinggi yang ditemukan di semua stream audio. Hanya tingkat tertinggi yang cocok yang diterapkan.

| Tag | Deskripsi |
|-----|-----------|
| `zurg_ultra_high_audio_bitrate` | Bitrate audio ≥ 2000 kbps (mis. DTS-HD MA, TrueHD, LPCM) |
| `zurg_high_audio_bitrate` | Bitrate audio ≥ 768 kbps dan < 2000 kbps (mis. DTS, AC3 bitrate tinggi) |
| `zurg_moderate_audio_bitrate` | Bitrate audio ≥ 384 kbps dan < 768 kbps (mis. AC3 standar, 5.1 AAC) |
| `zurg_low_audio_bitrate` | Bitrate audio ≥ 128 kbps dan < 384 kbps (mis. stereo AAC, MP3) |
| `zurg_very_low_audio_bitrate` | Bitrate audio ≥ 0 kbps dan < 128 kbps (mis. stereo kualitas rendah) |

## Tag Durasi {#duration-tags}

Tag durasi didasarkan pada durasi terpanjang yang ditemukan di semua file yang dianalisis, termasuk file audio saja. Hanya tingkat tertinggi yang cocok yang diterapkan.

| Tag | Deskripsi |
|-----|-------------|
| `zurg_80minsplus_duration` | Durasi ≥ 80 menit |
| `zurg_60to80mins_duration` | Durasi ≥ 60 menit dan < 80 menit |
| `zurg_40to60mins_duration` | Durasi ≥ 40 menit dan < 60 menit |
| `zurg_20to40mins_duration` | Durasi ≥ 20 menit dan < 40 menit |
| `zurg_0to20mins_duration` | Durasi ≥ 0 menit dan < 20 menit |

## Tag Bahasa {#language-tags}

Tag bahasa diterapkan untuk setiap bahasa unik yang terdeteksi di stream audio dan subtitle. Deteksi menggabungkan semua file yang dianalisis dalam torrent, jadi sebuah season pack membawa gabungan bahasa dari semua episode-nya. Hanya stream di dalam file video/audio yang dianalisis yang dihitung. File `.srt` terpisah di sebelahnya tidak pernah dibaca, dan stream yang tidak punya bahasa yang dideklarasikan akan default ke `und`.

### Tag Bahasa Audio {#audio-language-tags}
Format: `zurg_aud_[language_code]`

Contoh:
- `zurg_aud_eng` - track audio bahasa Inggris
- `zurg_aud_jpn` - track audio bahasa Jepang

### Tag Bahasa Subtitle {#subtitle-language-tags}
Format: `zurg_sub_[language_code]`

Contoh:
- `zurg_sub_eng` - subtitle Bahasa Inggris
- `zurg_sub_spa` - subtitle Bahasa Spanyol

## Menggunakan Tag untuk Filter {#using-tags-for-filtering}

Tag bisa dipakai di file konfigurasi untuk menyaring torrent ke direktori tertentu. Ada empat filter tag berbasis daftar, ditambah dua kondisi tag tunggal:

### Jenis Filter Tag {#tag-filter-types}

1. `tags_match_all`: Semua tag yang ditentukan harus ada
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: Minimal salah satu tag yang ditentukan harus ada
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: Mengembalikan true jika tidak ada satu pun tag filter yang ada (kebalikan dari "tags_match_any")
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: Mengembalikan true jika minimal satu tag filter tidak ada (kebalikan dari "tags_match_all")
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

Nama tag di keempat filter ini dibandingkan tanpa memedulikan huruf besar-kecil. Torrent yang tidak punya tag sama sekali akan gagal di `tags_match_all` dan `tags_match_any`, tapi lolos di `tags_missing_all` dan `tags_missing_any`. Nah, di situlah torrent yang belum pernah dianalisis biasanya berakhir.

Keempat key ini dicek sesuai urutan di atas, dan key pertama yang ada akan menentukan seluruh blok filter. Jadi, beri setiap filter tag entrinya sendiri di bawah `and:`/`or:`, jangan digabung beberapa sekaligus dalam satu blok.

### Kondisi Satu Tag {#single-tag-conditions}

`has_tag` dan `not_has_tag` menerima satu nama tag saja, bukan daftar, dan pencocokannya case-sensitive (membedakan huruf besar dan kecil). Berbeda dengan empat filter di atas, keduanya hanya bisa menolak torrent, tidak bisa memilih torrent sendiri. Blok filter yang isinya hanya `has_tag` tidak akan cocok dengan apa pun, jadi keduanya harus ditempatkan bersama kondisi lain di blok filter yang sama.

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### Contoh Konfigurasi Direktori {#example-directory-configuration}

Berikut contoh cara menggunakan filter tag dalam konfigurasi direktori:

```yaml
"quality movies":
  filters:
    - and:
      - tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
      - tags_match_any: ["zurg_high_video_bitrate", "zurg_ultra_high_video_bitrate"]  # Must have either high or ultra-high video bitrate
      - tags_match_any: ["zurg_high_audio_bitrate", "zurg_ultra_high_audio_bitrate"]  # Must have either high or ultra-high audio bitrate
      - tags_match_any: ["zurg_60to80mins_duration", "zurg_80minsplus_duration"]  # Must be at least 60 minutes long
      - tags_missing_all: ["zurg_sdr", "zurg_very_low_video_bitrate"]  # Must not have SDR or very low video bitrate
      - tags_missing_any: ["zurg_dv"]  # Must be missing Dolby Vision (prefer HDR10)
```

## Catatan {#notes}

- Tag diterapkan otomatis berdasarkan analisis media, yang membutuhkan binary `ffprobe` dan hanya berjalan pada torrent baru jika `auto_analyze_new_torrents` diaktifkan. Aksi analyze di dashboard dan aksi media info per torrent di halaman manage juga bisa memicunya secara manual.
- Belum ada tag yang diterapkan sampai minimal satu file sudah dianalisis. Torrent yang belum dianalisis tidak punya `zurg_sdr`, tier bitrate, maupun tier durasi.
- Setiap tag `zurg_*` dihapus dan dihitung ulang setiap kali analisis berjalan. Tag tanpa prefix itu (tag buatan user, penugasan direktori) tetap dipertahankan.
- Beberapa tag bahasa bisa ada sekaligus.
- Hanya satu tag resolusi yang diterapkan (yang tertinggi yang cocok).
- Hanya satu tag dynamic range yang diterapkan.
- Hanya satu tag tier bitrate video yang diterapkan (yang tertinggi yang cocok).
- Hanya satu tag tier bitrate audio yang diterapkan (yang tertinggi yang cocok).
- Hanya satu tag tier durasi yang diterapkan (yang tertinggi yang cocok).
- Toleransi 5% diterapkan untuk pengecekan resolusi.
- Bitrate video dihitung berdasarkan stream dengan bitrate tertinggi (bukan rata-rata).
- Bitrate audio dihitung berdasarkan stream dengan bitrate tertinggi (bukan rata-rata).
- Stream yang tidak melaporkan bitrate dihitung sebagai 0, jadi file yang stream-nya tidak punya metadata bitrate akan masuk ke tier `very_low`.
- Durasi dihitung berdasarkan file terpanjang yang sudah dianalisis dalam torrent (termasuk file yang hanya berisi audio).
- Filter tag bisa dikombinasikan dengan filter lain untuk mengatur konten secara lebih presisi.
