# Más de tu addon {#more-from-your-addon}

[Building rex addons](addons.md) cubre lo básico. Esta página añade subtítulos, tráilers, capítulos, colecciones, listas de reproducción, imágenes de artistas, películas conocidas, bibliotecas grandes, correcciones y eliminación. Cada sección añade campos a [Paso 5](addons.md#step-5-send-it). Pruébalos en los tutoriales de [vídeos caseros](addon-home-videos.md), [música](addon-music.md) o [IPTV](addon-iptv.md).

Todos los ejemplos se enviaron a rex nightly 2026.11.02. La referencia completa está en [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Películas y series que Plex conoce {#films-and-shows-plex-knows}

**Qué hace.** Hace que Plex muestre el nombre de una película o episodio, con su póster, reparto, sinopsis y valoraciones, en lugar de tu `display`.

Envía `kind` y los ids del título: un id de IMDb (`tt...`) o de TMDB de la película, o de la **serie** en el caso de un episodio, con `season` y `episode` según la numeración de TMDB:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**Lo que deberías ver.** La película es **Big Buck Bunny (2008)** con las imágenes de Plex, sin importar cómo se llame el archivo. rex no lee nada de los nombres: lo que envíes es lo que muestra. [rex con tu propia app](any-source.md) lo explica en detalle, incluidos los episodios.

## Subtítulos {#subtitles}

**Qué hace.** Ofrece archivos de subtítulos que están junto a un video como sus subtítulos, que la gente elige, descarga o incrusta igual que uno subido.

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| Campo | Significado |
|---|---|
| `path` | Dónde está el archivo en tu addon, igual que un video. Su extensión es su formato: `srt`, `ass`, `ssa`, `smi`, `txt` o `psb` |
| `language` | `en` o `eng`, como lo conozcas. rex no lee el idioma del nombre del archivo |
| `forced`, `hearing_impaired` | `true` para marcarlo así |
| `size` | Su tamaño en bytes. rex vuelve a leer el archivo solo cuando su ruta es nueva o su tamaño cambió |

**Qué deberías ver.** El video muestra un subtítulo **English (SRT External)**. Si omites `subtitles`, se mantiene lo que enviaste antes; `[]` elimina los tuyos (un subtítulo subido o descargado se conserva). Un archivo que rex no puede leer se deja fuera y se registra en el log, y el video se sigue reproduciendo.

## Tráilers y otros extras {#trailers-and-other-extras}

**Qué hace.** Pone un tráiler, un featurette o una escena eliminada debajo de su película o serie, en **Extras**, en lugar de convertirlo en un título propio.

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

Un extra pertenece al título de los otros videos de su `release` (por defecto, su carpeta). `extra_type` puede ser `trailer`, `deleted`, `featurette`, `behindthescenes`, `interview`, `scene`, `short`, `opening`, `ending` u `other`. rex nunca decide que un video es un extra por su nombre o su carpeta: solo `kind: "extra"` lo convierte en uno.

**Qué deberías ver.** La página de la película muestra el tráiler en Extras, y la biblioteca no lo lista.

## Capítulos {#chapters}

**Qué hace.** Permite saltar entre capítulos en el reproductor.

Ejecuta `ffprobe` también con `-show_chapters` y envía su salida tal cual:

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**Qué deberías ver.** Los capítulos del video, con sus nombres y tiempos. Para añadir capítulos a los videos que rex ya tiene, vuelve a enviar sus probes con `-show_chapters` en la siguiente snapshot.

## Colecciones y listas de reproducción {#collections-and-playlists}

**Qué hace.** Agrupa los títulos en colecciones de tu biblioteca, y las canciones o los vídeos en listas de reproducción, creadas y mantenidas al día por tu addon.

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| Campo | Significado |
|---|---|
| `collections` | Las colecciones en las que está el título, por nombre. Cada una se crea la primera vez que un título la nombra |
| `playlists` | Las listas de reproducción en las que está el archivo, por título, con su posición en cada una desde 1. Cada una es una lista de reproducción del propietario del servidor, de audio cuando su primera canción es una pista y de vídeo en caso contrario |

La gente conserva sus cambios: un título que alguien sacó de una colección se queda fuera, una canción que alguien añadió a tu lista de reproducción mantiene su posición, y una lista de reproducción que alguien renombró sigue siendo suya. Si omites el campo, se mantiene lo que enviaste antes; `[]` (o `{}` en el caso de las listas de reproducción) saca el archivo de todo aquello en lo que tu addon lo había puesto.

**Lo que deberías ver.** En la pestaña Collections de la biblioteca aparece **Summer 2026**; en Playlists aparece **Road trip**, en tu orden.

## Imágenes de artistas {#artist-pictures}

**Qué hace.** Muestra tus imágenes para los artistas que envía tu addon de música, incluso para los artistas que Plex conoce y para los que pondría su propia imagen.

Regístralo con `"artwork": "source"` y envía la imagen en cada pista:

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

Sin `artwork: "source"`, un artista que Plex conoce mantiene la imagen de Plex, y `display.artist` solo se muestra para los artistas que Plex no conoce. En cualquier caso, una imagen que alguien eligió o subió desde una app de Plex se conserva.

## Bibliotecas grandes: enviar sondeos una sola vez {#big-libraries-send-probes-once}

**Qué hace.** Permite que una instantánea de miles de videos envíe casi nada de salida de `ffprobe`, así que es pequeña y rápida.

Envía `probe`, un texto corto de tu propia cosecha que cambia cuando el probe del video cambiaría (un hash de su salida de `ffprobe` sirve). Una vez que rex tiene un video con ese `probe`, envía solo el `probe`, sin `media_info`:

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

rex responde `"unchanged": 1`. Cuando no tiene ese `probe` (un video nuevo, o uno cuyo probe cambió), no cambia nada y te lo pide:

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

Envía de nuevo esos elementos con su `media_info`. Una instantánea cuenta un elemento deseado como enviado, así que nunca se elimina por ello. Comprueba que tu rex lo admite: la respuesta a [registering](addons.md#step-2-register-with-rex) lista `"features": ["probe_digest"]`.

## Lo que la gente arregló: Fix Match {#what-people-fixed-fix-match}

**Qué hace.** Le indica a tu addon cuáles de sus vídeos alguien asignó a mano en una app de Plex (Fix Match), para que a partir de ahí los pueda enviar directamente.

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

Cada entrada es un `release` (una carpeta, a menos que envíes `release`) y los ids de la película o serie a la que se asignó. rex mantiene la asignación sin importar lo que envíes después, así que nada se rompe si lo ignoras; leerlo permite que tu addon envíe `kind` e `ids` por su cuenta y recuerde la corrección si las filas de rex alguna vez se reconstruyen. Si no hay nada asignado, la respuesta es `{"size": 0}`.

## Quitar tu addon {#removing-your-addon}

**Qué hace.** Quita tu addon y todo lo que envió desde rex, sin tocar sus archivos.

Hace dos solicitudes: la primera indica cuánto se eliminaría y da un enlace válido durante cinco minutos; la segunda lo borra.

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

El historial de reproducción se borra junto con las filas. Registrarlo y enviarlo de nuevo más adelante empieza desde cero, con filas nuevas. Para **reemplazar** un addon por una versión nueva, mantén su nombre, sus ids y el primer segmento de sus rutas: la nueva versión entonces actualiza las mismas filas. rex nunca borra las bibliotecas; si quieres eliminarlas, hazlo desde una app de Plex.

## Quién puede enviar a rex {#who-may-send-to-rex}

rex's feed (`/rex/sources` y `/rex/feed`) no requiere token. Solo responde a programas que estén en la propia máquina de rex, en tu red doméstica (`192.168.x.x`, `10.x.x.x`, `172.16-31.x.x` y direcciones IPv6 privadas) y en Tailscale (`100.64-127.x.x`). Para cualquier otro, esa ruta no existe, incluso si reenvías el puerto de rex para rex-direct o lo dejas entrar por IPv6. Un reverse proxy en la máquina de rex accede a ella como un programa local, así que si pones uno delante de rex, bloquea `/rex/` ahí.
