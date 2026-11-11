# zurg Tags Dokumentation {#zurg-tags-documentation}

Dieses Dokument beschreibt alle möglichen Tags, die in zurg automatisch auf Torrents angewendet werden können.

## Auflösungs-Tags {#resolution-tags}

Resolution-Tags werden anhand der Videoabmessungen mit einem Toleranzfaktor von 5 % vergeben: Ein Stream passt zu einer Stufe, wenn sowohl seine Breite als auch seine Höhe mindestens 95 % der angegebenen Abmessungen erreichen. Eingebettete Bilder (Cover-Art, Thumbnails) werden ignoriert. Es wird nur der höchste passende Resolution-Tag vergeben.

| Tag | Beschreibung |
|-----|-------------|
| `zurg_8k` | Auflösung >= 7680x4320 |
| `zurg_4k` | Auflösung >= 3840x2160 |
| `zurg_1440p` | Auflösung >= 2560x1440 |
| `zurg_1080p` | Auflösung >= 1920x1080 |
| `zurg_720p` | Auflösung >= 1280x720 |
| `zurg_480p` | Auflösung >= 720x480 |

## Dynamic-Range-Tags {#dynamic-range-tags}

Nur eines dieser Tags wird anhand der Dynamic-Range-Eigenschaften des Videos gesetzt:

| Tag | Beschreibung |
|-----|-------------|
| `zurg_hdr` | HDR-Inhalt (erkannt am BT.2020-Farbraum) |
| `zurg_dv` | Dolby-Vision-Inhalt |
| `zurg_sdr` | Standard-Dynamic-Range-Inhalt (wird gesetzt, wenn weder HDR noch DV erkannt wird) |

Wenn sowohl HDR- als auch Dolby-Vision-Metadaten vorhanden sind, hat das Dolby-Vision-Tag Vorrang und `zurg_hdr` wird nicht gesetzt.

## Video-Bitrate-Tags {#video-bitrate-tags}

Videobitrate-Tags basieren auf der höchsten Videostream-Bitrate, die in allen analysierten Dateien gefunden wurde. Eingebettete Bilder (Cover-Art, Thumbnails) werden dabei ignoriert. Es wird nur die höchste passende Stufe angewendet.

| Tag | Beschreibung |
|-----|-------------|
| `zurg_ultra_high_video_bitrate` | Videobitrate ≥ 100 Mbps |
| `zurg_high_video_bitrate` | Videobitrate ≥ 70 Mbps und < 100 Mbps |
| `zurg_moderate_video_bitrate` | Videobitrate ≥ 40 Mbps und < 70 Mbps |
| `zurg_low_video_bitrate` | Videobitrate ≥ 10 Mbps und < 40 Mbps |
| `zurg_very_low_video_bitrate` | Videobitrate ≥ 0 Mbps und < 10 Mbps |

## Audio-Bitrate-Tags {#audio-bitrate-tags}

Audio-Bitrate-Tags basieren auf der höchsten Audio-Bitrate, die über alle Audiospuren gefunden wird. Nur die höchste passende Stufe wird angewendet.

| Tag | Beschreibung |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | Audio-Bitrate ≥ 2000 kbps (z. B. DTS-HD MA, TrueHD, LPCM) |
| `zurg_high_audio_bitrate` | Audio-Bitrate ≥ 768 kbps und < 2000 kbps (z. B. DTS, AC3 mit hoher Bitrate) |
| `zurg_moderate_audio_bitrate` | Audio-Bitrate ≥ 384 kbps und < 768 kbps (z. B. Standard-AC3, 5.1 AAC) |
| `zurg_low_audio_bitrate` | Audio-Bitrate ≥ 128 kbps und < 384 kbps (z. B. Stereo-AAC, MP3) |
| `zurg_very_low_audio_bitrate` | Audio-Bitrate ≥ 0 kbps und < 128 kbps (z. B. Stereo mit niedriger Qualität) |

## Dauer-Tags {#duration-tags}

Die Dauer-Tags basieren auf der längsten Dauer, die in allen analysierten Dateien gefunden wurde, einschließlich reiner Audiodateien. Nur die höchste passende Stufe wird angewendet.

| Tag | Beschreibung |
|-----|-------------|
| `zurg_80minsplus_duration` | Dauer ≥ 80 Minuten |
| `zurg_60to80mins_duration` | Dauer ≥ 60 Minuten und < 80 Minuten |
| `zurg_40to60mins_duration` | Dauer ≥ 40 Minuten und < 60 Minuten |
| `zurg_20to40mins_duration` | Dauer ≥ 20 Minuten und < 40 Minuten |
| `zurg_0to20mins_duration` | Dauer ≥ 0 Minuten und < 20 Minuten |

## Sprach-Tags {#language-tags}

Sprachtags werden für jede eindeutige Sprache angelegt, die in Audio- und Untertitelspuren erkannt wird. Die Erkennung sammelt alle analysierten Dateien eines Torrents, daher enthält ein Staffel-Pack die Vereinigung der Sprachen aller seiner Episoden. Nur Spuren in analysierten Video- oder Audiodateien zählen. Eine eigenständige `.srt`-Datei daneben wird nie gelesen. Spuren ohne angegebene Sprache bekommen den Standardwert `und`.

### Audiosprach-Tags {#audio-language-tags}
Format: `zurg_aud_[language_code]`

Beispiel:
- `zurg_aud_eng` - englische Audiospur
- `zurg_aud_jpn` - japanische Audiospur

### Untertitelsprach-Tags {#subtitle-language-tags}
Format: `zurg_sub_[language_code]`

Beispiel:
- `zurg_sub_eng` - Englische Untertitel
- `zurg_sub_spa` - Spanische Untertitel

## Tags zum Filtern verwenden {#using-tags-for-filtering}

Tags können in der Konfigurationsdatei verwendet werden, um Torrents in bestimmte Verzeichnisse zu filtern. Es gibt vier listenbasierte Tag-Filter und zusätzlich zwei Einzel-Tag-Bedingungen:

### Tag-Filtertypen {#tag-filter-types}

1. `tags_match_all`: Alle angegebenen Tags müssen vorhanden sein
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: Mindestens einer der angegebenen Tags muss vorhanden sein
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: Gibt true zurück, wenn keiner der Filter-Tags vorhanden ist (das Gegenteil von "tags_match_any")
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: Gibt true zurück, wenn mindestens einer der Filter-Tags fehlt (das Gegenteil von "tags_match_all")
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

Tag-Namen werden in diesen vier Filtern ohne Berücksichtigung der Groß- und Kleinschreibung verglichen. Ein Torrent ohne jegliche Tags fällt bei `tags_match_all` und `tags_match_any` durch und besteht `tags_missing_all` und `tags_missing_any`. Genau dort landen Torrents, die noch nie analysiert wurden.

Die vier Schlüssel werden in der oben genannten Reihenfolge geprüft, und der erste vorhandene entscheidet über den ganzen Filterblock. Gib deshalb jeden Tag-Filter unter `and:`/`or:` einen eigenen Eintrag, statt mehrere in einem Block zu kombinieren.

### Bedingungen mit einem Tag {#single-tag-conditions}

`has_tag` und `not_has_tag` nehmen einen einzelnen Tag-Namen statt einer Liste und vergleichen dabei case-sensitiv (Groß- und Kleinschreibung zählt). Anders als die vier Filter oben können sie einen Torrent nur ablehnen, nicht von sich aus auswählen: Ein Filterblock, der nur `has_tag` enthält, passt auf nichts. Deshalb müssen sie immer zusammen mit einer anderen Bedingung im selben Block stehen.

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### Beispiel für eine Verzeichniskonfiguration {#example-directory-configuration}

Hier ist ein Beispiel, wie du Tag-Filter in einer Verzeichniskonfiguration verwendest:

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

## Hinweise {#notes}

- Tags werden automatisch anhand einer Medienanalyse vergeben. Dafür brauchst du eine `ffprobe`-Binary. Bei neu hinzugefügten Torrents läuft die Analyse nur, wenn `auto_analyze_new_torrents` aktiviert ist. Die Analyse-Aktion im Dashboard und die Aktion für die Medieninfos pro Torrent auf der Verwaltungsseite starten sie auf Abruf.
- Es wird erst etwas getaggt, wenn mindestens eine Datei analysiert wurde. Ein nicht analysierter Torrent hat kein `zurg_sdr`, keine Bitrate-Stufe und keine Dauer-Stufe.
- Jedes `zurg_*`-Tag wird bei jedem Analysedurchlauf gelöscht und neu berechnet. Tags ohne dieses Präfix (Nutzer-Tags, Verzeichniszuweisungen) bleiben erhalten.
- Mehrere Sprach-Tags können gleichzeitig vorhanden sein.
- Es wird nur ein Auflösungs-Tag vergeben (das höchste passende).
- Es wird nur ein Dynamic-Range-Tag vergeben.
- Es wird nur ein Video-Bitrate-Stufen-Tag vergeben (das höchste passende).
- Es wird nur ein Audio-Bitrate-Stufen-Tag vergeben (das höchste passende).
- Es wird nur ein Dauer-Stufen-Tag vergeben (das höchste passende).
- Bei den Auflösungsprüfungen wird eine Toleranz von 5 % angewendet.
- Video-Bitraten beziehen sich auf den Stream mit der höchsten Bitrate (nicht auf den Durchschnitt).
- Audio-Bitraten beziehen sich auf den Stream mit der höchsten Bitrate (nicht auf den Durchschnitt).
- Ein Stream, der keine Bitrate meldet, zählt als 0. Eine Datei, deren Streams keine Bitrate-Metadaten haben, landet deshalb in der Stufe `very_low`.
- Die Dauer richtet sich nach der längsten analysierten Datei im Torrent (auch reine Audiodateien zählen mit).
- Tag-Filter lassen sich mit anderen Filtern kombinieren, um Inhalte genau zu sortieren.
