# zurg Documentación de etiquetas {#zurg-tags-documentation}

Este documento describe todas las etiquetas posibles que se pueden aplicar automáticamente a los torrents en zurg.

## Etiquetas de resolución {#resolution-tags}

Las etiquetas de resolución se aplican según las dimensiones del vídeo, con un margen de tolerancia del 5 %: un stream coincide con un nivel cuando su ancho y su alto son al menos el 95 % de las dimensiones indicadas. Las imágenes incrustadas (carátulas, miniaturas) se ignoran. Solo se aplica la etiqueta de resolución más alta que coincida.

| Tag | Description |
|-----|-------------|
| `zurg_8k` | Resolution >= 7680x4320 |
| `zurg_4k` | Resolution >= 3840x2160 |
| `zurg_1440p` | Resolution >= 2560x1440 |
| `zurg_1080p` | Resolution >= 1920x1080 |
| `zurg_720p` | Resolution >= 1280x720 |
| `zurg_480p` | Resolution >= 720x480 |

## Etiquetas de rango dinámico {#dynamic-range-tags}

Solo se aplica una de estas etiquetas según las características de rango dinámico del video:

| Etiqueta | Descripción |
|-----|-------------|
| `zurg_hdr` | Contenido HDR (detectado por el espacio de color BT.2020) |
| `zurg_dv` | Contenido Dolby Vision |
| `zurg_sdr` | Contenido de rango dinámico estándar (se aplica cuando no se detecta ni HDR ni DV) |

Cuando hay metadatos de HDR y de Dolby Vision al mismo tiempo, la etiqueta de Dolby Vision tiene prioridad y `zurg_hdr` no se aplica.

## Etiquetas de bitrate de vídeo {#video-bitrate-tags}

Las etiquetas de bitrate de vídeo se basan en el bitrate de stream de vídeo más alto encontrado en todos los archivos analizados, ignorando las imágenes incrustadas (carátulas, miniaturas). Solo se aplica el nivel más alto que coincida.

| Etiqueta | Descripción |
|-----|-------------|
| `zurg_ultra_high_video_bitrate` | Bitrate de vídeo ≥ 100 Mbps |
| `zurg_high_video_bitrate` | Bitrate de vídeo ≥ 70 Mbps y < 100 Mbps |
| `zurg_moderate_video_bitrate` | Bitrate de vídeo ≥ 40 Mbps y < 70 Mbps |
| `zurg_low_video_bitrate` | Bitrate de vídeo ≥ 10 Mbps y < 40 Mbps |
| `zurg_very_low_video_bitrate` | Bitrate de vídeo ≥ 0 Mbps y < 10 Mbps |

## Etiquetas de bitrate de audio {#audio-bitrate-tags}

Las etiquetas de tasa de bits de audio se basan en la tasa de bits de audio más alta encontrada en todos los streams de audio. Solo se aplica el nivel más alto que coincida.

| Etiqueta | Descripción |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | Tasa de bits de audio ≥ 2000 kbps (p. ej., DTS-HD MA, TrueHD, LPCM) |
| `zurg_high_audio_bitrate` | Tasa de bits de audio ≥ 768 kbps y < 2000 kbps (p. ej., DTS, AC3 de alta tasa de bits) |
| `zurg_moderate_audio_bitrate` | Tasa de bits de audio ≥ 384 kbps y < 768 kbps (p. ej., AC3 estándar, AAC 5.1) |
| `zurg_low_audio_bitrate` | Tasa de bits de audio ≥ 128 kbps y < 384 kbps (p. ej., AAC estéreo, MP3) |
| `zurg_very_low_audio_bitrate` | Tasa de bits de audio ≥ 0 kbps y < 128 kbps (p. ej., estéreo de baja calidad) |

## Etiquetas de duración {#duration-tags}

Las etiquetas de duración se basan en la duración más larga encontrada en todos los archivos analizados, incluidos los archivos solo de audio. Solo se aplica el nivel más alto que coincida.

| Etiqueta | Descripción |
|-----|-------------|
| `zurg_80minsplus_duration` | Duración ≥ 80 minutos |
| `zurg_60to80mins_duration` | Duración ≥ 60 minutos y < 80 minutos |
| `zurg_40to60mins_duration` | Duración ≥ 40 minutos y < 60 minutos |
| `zurg_20to40mins_duration` | Duración ≥ 20 minutos y < 40 minutos |
| `zurg_0to20mins_duration` | Duración ≥ 0 minutos y < 20 minutos |

## Etiquetas de idioma {#language-tags}

Se aplican etiquetas de idioma para cada idioma único detectado en las pistas de audio y subtítulos. La detección combina todos los archivos analizados del torrent, así que un pack de temporada lleva la unión de los idiomas de sus episodios. Solo cuentan las pistas dentro de los archivos de video/audio analizados: un `.srt` suelto junto a ellos nunca se lee. Las pistas sin idioma declarado usan `und` por defecto.

### Etiquetas de idioma de audio {#audio-language-tags}
Formato: `zurg_aud_[language_code]`

Ejemplo:
- `zurg_aud_eng` - pista de audio en inglés
- `zurg_aud_jpn` - pista de audio en japonés

### Etiquetas de idioma de subtítulos {#subtitle-language-tags}
Formato: `zurg_sub_[language_code]`

Ejemplo:
- `zurg_sub_eng` - Subtítulos en inglés
- `zurg_sub_spa` - Subtítulos en español

## Usar etiquetas para filtrar {#using-tags-for-filtering}

Los tags se pueden usar en el archivo de configuración para filtrar torrents en directorios específicos. Hay cuatro filtros de tags basados en listas, además de dos condiciones de un solo tag:

### Tipos de filtro de etiquetas {#tag-filter-types}

1. `tags_match_all`: Todas las etiquetas especificadas deben estar presentes
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: Al menos una de las etiquetas especificadas debe estar presente
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: Devuelve true si ninguna de las etiquetas del filtro está presente (lo contrario de "tags_match_any")
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: Devuelve true si al menos una de las etiquetas del filtro falta (lo contrario de "tags_match_all")
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

Los nombres de las etiquetas en estos cuatro filtros se comparan sin distinguir mayúsculas y minúsculas. Un torrent sin ninguna etiqueta no pasa `tags_match_all` ni `tags_match_any`, pero sí pasa `tags_missing_all` y `tags_missing_any`; ahí es donde acaban los torrents que nunca se han analizado.

Las cuatro claves se comprueban en el orden indicado arriba y la primera que esté presente decide todo el bloque de filtros, así que dale a cada filtro de etiquetas su propia entrada bajo `and:`/`or:` en lugar de combinar varios en un mismo bloque.

### Condiciones de una sola etiqueta {#single-tag-conditions}

`has_tag` y `not_has_tag` aceptan un solo nombre de etiqueta en lugar de una lista, y distinguen entre mayúsculas y minúsculas. A diferencia de los cuatro filtros anteriores, solo pueden descartar un torrent, nunca seleccionar uno por sí solos: un bloque de filtro que contenga únicamente `has_tag` no coincide con nada, así que tienen que ir junto a otra condición en el mismo bloque.

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### Ejemplo de configuración de directorio {#example-directory-configuration}

Aquí tienes un ejemplo de cómo usar filtros de etiquetas en la configuración de un directorio:

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

## Notas {#notes}

- Las etiquetas se aplican automáticamente según el análisis de medios, que necesita un binario `ffprobe` y solo se ejecuta en los torrents recién añadidos cuando `auto_analyze_new_torrents` está activado. El botón de analizar del panel y la acción de información de medios por torrent en la página de gestión la lanzan manualmente.
- No se etiqueta nada hasta que se haya analizado al menos un archivo. Un torrent sin analizar no tiene `zurg_sdr`, ni nivel de bitrate, ni nivel de duración.
- Cada etiqueta `zurg_*` se borra y se vuelve a calcular en cada análisis. Las etiquetas sin ese prefijo (etiquetas de usuario, asignaciones de directorios) se mantienen.
- Pueden haber varias etiquetas de idioma a la vez.
- Solo se aplica una etiqueta de resolución (la más alta que coincida).
- Solo se aplica una etiqueta de rango dinámico.
- Solo se aplica un nivel de bitrate de vídeo (el más alto que coincida).
- Solo se aplica un nivel de bitrate de audio (el más alto que coincida).
- Solo se aplica un nivel de duración (el más alto que coincida).
- Para las comprobaciones de resolución se aplica un factor de tolerancia del 5 %.
- Los bitrates de vídeo se basan en el stream con el bitrate más alto (no en la media).
- Los bitrates de audio se basan en el stream con el bitrate más alto (no en la media).
- Un stream que no informa de bitrate cuenta como 0, así que un archivo cuyos streams no traen metadatos de bitrate acaba en el nivel `very_low`.
- La duración se basa en el archivo analizado más largo del torrent (contando también los archivos solo de audio).
- Los filtros por etiqueta se pueden combinar con otros filtros para organizar el contenido con precisión.
