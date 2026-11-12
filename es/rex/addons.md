# Crear addons para rex {#building-rex-addons}

[rex](https://rex.debridmediamanager.com/es/) muestra lo que sus fuentes le dicen que tienen. Una fuente le indica a rex qué tiene
a través de la API de feeds y le sirve los archivos cuando rex los pide. rex trata todas las fuentes por igual. Un **addon** es una
fuente que escribes tú mismo para vídeos caseros, grabaciones, catálogos de Stremio, [música](#music) o [canales en vivo](#live-tv).

Esta página explica qué necesita rex de un addon, cómo nombrar sus elementos y las reglas que más importan. Termina
con [rex-stremio](https://github.com/debridmediamanager/rex-stremio) como ejemplo de un solo archivo.

Un addon hace tres cosas:

- **Sirve los bytes.** rex descarga todos los bytes de tu addon por HTTP cuando alguien pulsa play: un archivo o un stream al que rex es redirigido.
- **Le dice a rex qué tiene.** Envía a rex una lista a través de la API de feeds de rex, y todos los cambios posteriores. rex nunca escanea nada.
- **Nombra lo que aporta.** Para las cosas que ningún agente conoce, tu addon envía él mismo el título, la sinopsis, la fecha y las imágenes. Las apps de Plex las muestran como cualquier otra biblioteca.

Si lo que aportas son películas y series que Plex ya conoce (tiene sus ids de IMDb o TMDB), te conviene más [rex con tu propia app](any-source.md): así Plex nombra y describe todo por ti.

Para llevar a rex los catálogos de tus addons de Stremio no tienes que escribir nada: rex-stremio ya está listo. Pegas los enlaces de tus addons en su página de ajustes y marcas los catálogos que quieres.

Si prefieres no escribir ni ejecutar un servidor, te conviene un addon de JavaScript para [rex-addons](https://github.com/debridmediamanager/rex-addons): un `manifest.json` y un `main.js`, compartidos a través de un repositorio de git, que también funciona en la [app de zurg+rex para Android](../zurg/guides/android.md). Se ejecuta en un entorno aislado que solo llega a los sitios web que enumera y no puede leer tus archivos, así que sirve para cosas de internet, no para una carpeta de tu disco. [Escribir un addon](https://github.com/debridmediamanager/rex-addons/blob/main/docs/writing-addons.md) explica cómo. Los addons de esta página pueden estar en cualquier lenguaje, servir tus propios archivos y hacer lo que necesites.

**¿Prefieres empezar desde código que funciona?** Tres tutoriales construyen cada uno un addon completo en un solo archivo de Python, usando solo la biblioteca estándar, y explican qué hace cada parte:

| Tutorial | Lleva a rex |
|---|---|
| [Vídeos caseros](addon-home-videos.md) | Una carpeta con tus propios vídeos, como biblioteca con títulos, fechas y pósteres recortados de los vídeos |
| [Música](addon-music.md) | Una carpeta de álbumes, nombrados por Plex a través de MusicBrainz, con letras |
| [IPTV](addon-iptv.md) | Una lista M3U y su guía XMLTV, como canales de Live TV con guía |

Esta página explica cada paso que siguen esos tutoriales. [Más de tu addon](addon-more.md) añade subtítulos, tráileres, capítulos, colecciones, listas de reproducción y lo demás.

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| rex, configurado como en [rex con tu propia app](any-source.md) (pasos 1 a 3) | Ahí es donde aparece la biblioteca de tu addon |
| Un nightly de rex con fecha 2026.10.25 o posterior, o 2026.11.02 o posterior para [Música](#music) y [TV en directo](#live-tv) | Esta página está escrita para esa versión |
| FFmpeg donde se ejecuta rex, si tu addon sirve streams | rex reproduce un stream convirtiéndolo (una copia, muy ligera). rex encuentra FFmpeg por sí mismo; mira [Convertir video](any-source.md#converting-video-optional) |
| Tu addon en la misma máquina que rex, o en tu red doméstica | La API de rex solo responde a esas: mira [Mantén el puerto privado](any-source.md#keep-the-port-private) |

Esta página escribe la dirección de rex como `192.168.1.20:32400` y la del addon como `127.0.0.1:9981`. Pon las tuyas en su lugar. La referencia completa de la API de rex está en [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Paso 1. Sirve los bytes {#step-1-serve-the-bytes}

**Qué hace.** Le da a cada video una URL que rex puede leer.

**Por qué importa.** rex no guarda contenido multimedia. Cada vez que alguien pulsa play, rex lee el video desde tu addon.

Tu addon es un servidor HTTP. Un video vive en `<your address>/<path>`, y `path` es lo que tú elijas. Hay dos tipos:

| You serve | How | What rex does |
|---|---|---|
| **A file** (`.mkv`, `.mp4`, ...) | Answer `GET` with the file. Answer `Range` requests (`206`) so seeking is fast; without them rex reads from the start to every seek | Plex apps play it directly when they can, or rex converts it |
| **A stream** (HLS, `.m3u8`) | Answer `GET` with the playlist, or a redirect to it. Redirects are followed, and your login is never sent to another host | rex always converts it: a copy of the picture and sound into what the app plays. An app that reads the file directly is sent to that conversion |

Opcional, pero vale la pena:

- **A login.** Basic auth (`user`, `password`) or a bearer token. rex sends it only to your addon's own address.
- **Deletes.** When someone deletes a title in a Plex app, rex first sends your addon a WebDAV `DELETE` for the path. Answer `2xx` (deleted) or `404` (already gone) and rex removes the title. Anything else, and the Plex app says it could not be deleted.

## Paso 2. Regístrate en rex {#step-2-register-with-rex}

**Qué hace.** Le dice a rex el nombre de tu addon, dónde están sus bytes y qué bibliotecas llena.

**Por qué importa.** rex no lee nada de una fuente que no conoce. Registrarla de nuevo no cambia nada, así que hazlo cada vez que arranque tu addon.

+++ Linux y macOS
```bash
curl -X PUT http://192.168.1.20:32400/rex/sources/myaddon \
  -H 'Content-Type: application/json' \
  -d '{"url": "http://127.0.0.1:9981",
       "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++ Windows
```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/myaddon -ContentType application/json `
  -Body '{"url": "http://127.0.0.1:9981", "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++

| Campo | Significado |
|---|---|
| `url` | Dónde están tus bytes. Los bytes de un video son `GET <url>/<path>` |
| `user` y `password`, o `bearer` | El inicio de sesión de tu addon, si tiene uno. Nunca dentro de `url` |
| `directories` | Las bibliotecas que llena tu addon. Cada entrada es un primer segmento de ruta (`name`) y el título de la biblioteca: `shows` para una biblioteca de series, `movies` para una de películas, `music` para una de música, o varias. rex crea cada biblioteca la primera vez; si la renombras en Plex, el cambio se mantiene |
| `trash` | `false` borra lo que tu addon elimina (una snapshot que la deja fuera, o un `DELETE`) en lugar de guardarlo en la papelera de rex |

El primer segmento de una ruta decide a qué biblioteca va: con el ejemplo de arriba, toda ruta que empiece por `kids/` acaba en **Kids**. Usa un primer segmento distinto para cada biblioteca.

**Qué deberías ver.** rex responde con la fuente. El log de rex dice `SOURCES myaddon registered at http://127.0.0.1:9981` y, la primera vez, `SECTION create Kids (show) for myaddon's kids`. La biblioteca aparece en las apps de Plex, dentro de More, en menos de un segundo.

## Paso 3. Describe cada video {#step-3-describe-each-video}

**Qué hace.** Crea el registro que rex guarda de cada vídeo: dónde está, qué es y cómo se ve.

**Por qué importa.** Este registro es todo lo que rex sabe. Un probe que falta o un id que cambia causa la mayoría de los errores del addon.

```json
{
  "id": "home-2026-07-22-beach",
  "path": "kids/summer-2026/beach.mp4",
  "kind": "episode", "season": 1, "episode": 3,
  "name": "Summer 2026",
  "media_info": { "...": "ffprobe's output, whole" },
  "display": {
    "title": "First day at the beach",
    "summary": "...",
    "date": "2026-07-22",
    "thumb": "http://127.0.0.1:9981/kids/summer-2026/beach.jpg",
    "show": {"title": "Summer 2026", "summary": "...", "poster": "https://...", "art": "https://..."},
    "season": {"poster": "https://..."}
  }
}
```

| Campo | Obligatorio | Significado |
|---|---|---|
| `id` | sí | Tu clave para este vídeo, **para siempre**. rex guarda el historial de reproducción con ella |
| `path` | sí | Dónde están sus bytes dentro de tu `url`. Su primer segmento elige la biblioteca |
| `media_info` | sí, en la práctica | El JSON de ffprobe con `-show_format -show_streams` del vídeo (para un stream, haz el probe de su URL). Sin él, el archivo queda **retenido**: se guarda pero no se muestra, porque las apps de Plex no reproducen un vídeo del que no saben nada. Un stream (`.m3u8`) sin él se rechaza con `not a video file`, así que envía un stream solo cuando ya le hayas hecho el probe |
| `kind` | para una serie | `episode` o `movie`. Sin él, nada coloca el vídeo: en una biblioteca de series es un episodio de una serie con el nombre de `name`, numerado en el orden de los archivos; en una biblioteca de películas, una película con el título de su archivo |
| `season`, `episode` | para un episodio | Dónde va. Numera los episodios de forma que uno nuevo nunca desplace a los demás |
| `name` | no | El nombre de la serie, y lo que agrupa sus episodios. Valor por defecto: el nombre de su carpeta (el nombre del archivo, para una ruta sin carpeta) |
| `release` | no | Agrupa los vídeos que pertenecen juntos. Valor por defecto: la carpeta del vídeo |
| `display` | para lo que ningún agente conoce | Título, resumen, fecha e imágenes: Paso 4 |

La `path` de un stream termina en `.m3u8`, y su `media_info` dice `"format_name": "hls"`. rex solo lo acepta si se cumplen las dos cosas. Cualquier otro archivo debe tener una extensión de vídeo.

## Paso 4. Ponle nombre y arréglalo {#step-4-name-and-dress-it}

**Qué hace.** Le da a las apps de Plex un título, resumen, fecha e imágenes para lo que ningún agente de Plex conoce.

**Por qué importa.** Sin `display`, un episodio aparece como "Episode 3" con una miniatura en blanco, y una serie no tiene póster.

| Campo | Dónde se muestra |
|---|---|
| `title`, `summary` | El título y el resumen del video, tal cual se envían |
| `date` | Su fecha de estreno (`YYYY-MM-DD`), y el año a partir de ella. O solo el año (`YYYY`) para algo que se conoce solo por su año, como una película antigua: las apps de Plex muestran entonces el año y no el día de estreno |
| `thumb` | El póster de una película, o la imagen fija de un episodio |
| `art` | El fondo de una película |
| `show.title`, `show.summary`, `show.poster`, `show.art` | La serie a la que pertenece el episodio |
| `season.summary`, `season.poster` | La temporada del episodio (el póster de la serie cuando no hay uno) |

Todos los campos son opcionales. Las imágenes son URL `http://` o `https://`. rex las descarga por sí mismo: desde internet público, o desde la dirección de tu addon (la `url` que registraste), con el inicio de sesión de tu addon. Cualquier otra dirección de tu red doméstica se rechaza. Así, un addon puede servir sus propias imágenes, como un fotograma de cada video casero. Una imagen 2:3 es el mejor póster, y una 16:9 la mejor imagen fija y fondo.

Cómo las trata rex:

- **Solo para lo que nada identifica.** Un video enviado con `kind` e `ids` que Plex conoce se muestra como Plex lo describe, y `display` se ignora.
- **Los envíos posteriores actualizan.** Si vuelves a enviar un video con un `display` nuevo, su fila, serie y temporada cambian en su sitio; las apps vuelven a dibujar las imágenes nuevas. Una serie conserva el título con el que se creó.
- **Gana la gente.** Un campo que alguien editó y bloqueó en una app de Plex conserva su valor, y un póster que subió se mantiene.
- **Se comprueba.** Una imagen que no es una URL http(s), o una fecha con otro formato, rechaza el video e indica qué campo es.

## Paso 5. Envíalo {#step-5-send-it}

**Qué hace.** Envía a rex tus vídeos: todos de una vez de vez en cuando, y los cambios a medida que ocurren.

**Por qué importa.** rex te muestra exactamente lo último que le enviaste.

| Para | Envía | rex responde |
|---|---|---|
| Añadir o cambiar vídeos | `POST /rex/feed/myaddon/items` con `{"items": [...]}` | Cuántos fueron `created`, `updated`, `held`, `unchanged`, y cada `rejected` con su motivo |
| Quitar vídeos | `DELETE /rex/feed/myaddon/items` con `{"ids": [...]}` | Cuántos fueron `trashed`, `deleted`, `released` (los retenidos se olvidan) y `unknown` |
| Enviar todo | `PUT /rex/feed/myaddon/snapshot` con `{"items": [...]}`. Por partes: `"session"` (cualquier texto), `"part"` desde 0, `"complete": true` en la última | Los mismos recuentos, y qué `removed`: cada vídeo tuyo que el snapshot no nombró |

Envía unos cientos de vídeos por petición. Un snapshot que no nombra nada no elimina nada, y uno que quitaría más de la mitad de tus vídeos se rechaza, a menos que su última parte lleve `"force": true`: un addon que perdió el control de las cosas no puede vaciar tu biblioteca por accidente.

**Lo que deberías ver.**

+++ Linux y macOS
```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/items | head -c 400   # what rex shows, with each ratingKey
curl -s http://192.168.1.20:32400/rex/feed/myaddon/held                  # what waits for a probe
```
+++ Windows
```powershell
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/items   # what rex shows, with each ratingKey
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/held    # what waits for a probe
```
+++

El log de rex nombra cada vídeo rechazado y el motivo: `FEED myaddon rejected <id>: <reason>`.

## Música {#music}

**Qué hace.** Trae álbumes a una biblioteca de música, que Plexamp, Plex Web y Plex para Android reproducen.

**Por qué importa.** Plex nombra la música según la edición de MusicBrainz del álbum. Envía ese id y Plex rellena por sí mismo todos los títulos, portadas, fotos de artista y biografías.

Envía cada archivo de audio como una pista:

```json
{
  "id": "albums/in-rainbows/01",
  "path": "music/Radiohead/In Rainbows/01 - 15 Step.flac",
  "kind": "track",
  "ids": {"mbid": "3b408cb5-7d51-4188-b07c-fabcf308cda3"},
  "disc": 1, "track": 1,
  "media_info": { "...": "ffprobe's output, whole" }
}
```

| Campo | Significado |
|---|---|
| `kind` | `track` |
| `path` | Un archivo de audio: `.flac`, `.mp3`, `.m4a`, `.aac`, `.ogg`, `.oga`, `.opus`, `.wav`, `.alac`, `.aif`, `.aiff`, `.wma`, `.ape`, `.wv`, `.dsf` o `.mka` |
| `ids.mbid` | El id de **release** de MusicBrainz del álbum de la pista: el id del enlace `musicbrainz.org/release/<id>`, no el de un release group ni el de una grabación. O bien `ids.plex`, el guid de álbum propio de Plex (`plex://album/<id>`) |
| `disc`, `track` | Dónde está la pista en esa edición. La pista de Plex con esos números es la que se muestra |
| `release` | A qué copia del álbum pertenece la pista. Por defecto: su carpeta. Cada copia es un álbum aparte, ya que Plex lista dos copias, así que envía un `release` para los archivos de una copia que están en carpetas de disco (`CD1/`, `CD2/`) |
| `display` | Para música que Plex no conoce: el `title` de la pista, su `artist` (`title`, `summary`, `poster`, `art`) y su `album` (`title`, `summary`, `poster`, `date`) |
| `lyrics` | Archivos de letras junto a él en tu addon: `[{"path": "music/.../01 - 15 Step.lrc", "size": 147}]`. Un `.lrc` (letra con tiempos) o un `.txt`, que se muestran como la letra de la canción |
| `loudness` | Solo si tu addon mide el volumen, con los nombres de Plex: `gain`, `albumGain`, `peak`, `albumPeak`, `albumRange`, `loudness` y `lra`, los fundidos `startRamp` y `endRamp`, y `levels`, el volumen cada 100 ms. rex no mide nada por sí mismo |

- **Primero, una biblioteca de música.** Declara una en el Paso 2 (`"directories": [{"name": "music", "music": "Music"}]`), o añade una biblioteca de Música en una app de Plex. Una pista que ninguna biblioteca de música acepta se rechaza: `no music library holds <file>`.
- **Encontrar el id de release.** Busca en MusicBrainz por el título del álbum y el artista (`https://musicbrainz.org/ws/2/release?query=release:%22In%20Rainbows%22%20AND%20artist:Radiohead&fmt=json`) y elige una edición oficial con tu número de pistas; varias suelen coincidir (una por país), y cualquiera de ellas identifica el álbum. MusicBrainz responde una petición por segundo por dirección y rechaza más, y pide un User-Agent que nombre tu addon; pregunta una vez por álbum y guarda la respuesta.
- **rex no lee etiquetas.** Títulos, portadas, géneros y artistas similares son de Plex. Una pista cuyo release Plex no conoce muestra tu `display`, agrupada bajo el artista y el álbum que indiques, o su nombre de archivo bajo `[Unknown Artist]` si no lo incluyes.
- **Se reproduce tal cual.** No hace falta FFmpeg, salvo que una app pida una calidad inferior a la original: en ese caso rex lo convierte con FFmpeg, igual que hace Plex.
- **No disponible.** La radio, las mezclas, las emisoras y las pistas sonoramente similares de Plexamp necesitan un análisis que rex no hace.

**Qué deberías ver.** El álbum en la biblioteca de música con la portada y los nombres de pista de Plex, y su artista con una foto. En Plexamp, elige la biblioteca de música de rex como biblioteca.

## TV en vivo {#live-tv}

**Qué hace.** Convierte un stream en directo en un canal de **Live TV** en Plex Web y Plex para Android, con una guía de programación, What's On y un número de canal.

**Por qué importa.** Un stream en directo por sí solo es solo una fila en la biblioteca. Con un `channel`, la gente lo encuentra como encuentra la TV: en la guía, por lo que se emite ahora.

Envía el stream en directo como en el Paso 3 (un `.m3u8` con su probe), más un `channel`:

```json
"channel": {
  "number": "100.1",
  "title": "Rex News",
  "guide": [
    {"start": "2026-11-01T18:00:00Z", "end": "2026-11-01T19:00:00Z",
     "title": "Evening News", "summary": "The day's headlines.", "categories": ["News"]},
    {"start": "2026-11-01T19:00:00Z", "end": "2026-11-01T19:45:00Z",
     "title": "The Pilot", "type": "episode", "show": "Rex Stories", "season": 1, "episode": 1,
     "categories": ["Drama"]}
  ]
}
```

| Campo | Significado |
|---|---|
| `number` | El número del canal en la guía (`100.1`, `704`): letras, dígitos, `.`, `-` y `_`. Elige números que no usen otros addons; el primer canal enviado con un número lo conserva |
| `title` | Su nombre en la guía. Por defecto: el título `display` del stream |
| `call_sign` | Su nombre corto. Por defecto: `title` |
| `guide` | Lo que se emite: `start` y `end` (segundos epoch, o ISO 8601 con `Z` o un offset), `title` y, opcionalmente, `summary`, `categories`, `thumb` y `previously_shown` (`true` para una repetición). Un episodio añade `"type": "episode"` con `show`, `season` y `episode`, y la guía lo agrupa bajo su serie |

- **Envía la guía desde unas horas atrás hasta donde sepas la programación** (unas dos semanas, como hacen los archivos de guía de TV), y vuelve a enviarla cuando cambie. rex muestra un programa hasta tres horas después de que termine. Cada envío reemplaza la guía del canal; un envío sin `channel` la conserva; `"channel": null` termina el canal.
- **Se necesita FFmpeg**, como con cualquier stream: rex convierte el canal mientras alguien lo ve.
- **Nada se graba.** Plex Web y Plex para Android no ofrecen un botón Record.
- **Canales que terminan.** Regístralos con `"trash": false` (Paso 2) para que un canal que elimines se borre y no vaya a la papelera de rex.
- **Qué hace una categoría.** Un episodio en `Sports` o `News` aparece en las filas Sports y News de What's On. Un programa sin `type` se muestra como película, como hace Plex con cualquier guía de TV.

**Qué deberías ver.** En Plex Web o Plex para Android, **Live TV** en el menú de la app, el canal en la guía con su número, y el stream reproduciéndose al abrirlo. El log de rex indica qué canal se ha rechazado y por qué, por ejemplo `channel.guide[3]: end must be after start`.

[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) hace todo esto para los canales de un servidor de deportes en directo: los numera por grupo desde `100.1`, mantiene el número de cada canal y toma sus guías de Pluto TV y de los archivos XMLTV gratuitos de epgshare01.

## Las reglas que más confunden {#the-rules-that-trip-people-up}

| Regla | Qué pasa si la rompes |
|---|---|
| **Un id es para siempre.** Si lo cambias, el video pasa a ser un título nuevo | El historial de reproducción y las ediciones se quedan en la fila anterior, que la siguiente snapshot elimina |
| **Un video, una ruta.** Dos ids no pueden compartir un `path` | El segundo se rechaza: `... is already <id>'s file` |
| **Los bytes de un archivo son fijos por id.** rex conserva los streams con los que se analizó por primera vez; un análisis posterior solo cambia sus capítulos. Solo un stream (`.m3u8`) acepta un nuevo análisis cuando sus streams son distintos | Si los bytes de un archivo cambian (otro formato, una subida corregida), dale un id y un path nuevos |
| **Analiza todo.** Sin `media_info`, no hay video | Un archivo espera en `held` hasta que un envío traiga uno; un stream se rechaza |
| **Conserva el nombre de la fuente.** Las filas pertenecen a (source, id) | Otro nombre crea una fuente vacía; las filas de la anterior se quedan hasta que la borres |
| **Las snapshots son completas.** Una que omita un canal lo elimina | No envíes una snapshot tras un fallo parcial: sáltate esa ronda |

Para **reemplazar** un addon (o un script) que ya llenó una biblioteca, conserva su nombre de fuente, sus ids y el primer segmento del path. Tu primer envío actualizará entonces sus filas en su sitio, con historial de reproducción y todo, en lugar de crear filas nuevas.

## Ejemplo: rex-stremio {#example-rex-stremio}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) convierte los catálogos de tus addons de Stremio en bibliotecas de rex: las películas van a una biblioteca de películas, las series a una biblioteca de series y los canales en vivo a una biblioteca llamada Live TV (no la guía de Live TV). Hace los pasos 1 a 5 y es un solo archivo de Python que solo usa la biblioteca estándar. No borra nada: los títulos de un catálogo no son suyos para borrarlos.

**Registro.** Cada catálogo que marcas indica una biblioteca: Stremio Films, Stremio Shows o Live TV, a menos que le cambies el nombre. rex-stremio se registra como `stremio` con un directorio por biblioteca, con el nombre de esta (`stremio-films`), y declara esa biblioteca como el título `shows` del directorio para los catálogos de series, o como su título `movies` para los catálogos de películas y de canales en vivo.

**Reproducción.** Los enlaces de los streams de los addons caducan, así que rex-stremio no guarda enlaces. Sirve una URL por título, `/<directory>/<catalog>/<id>.<ext>`, y responde con una redirección a un enlace que pide en ese momento:

```python
url = app.sync.resolve(vid)   # ask every stream addon, rank, take the first link that opens
self.send_response(302)
self.send_header("Location", url)
```

Pregunta a cada addon que sirve el título (`/stream/<movie or series>/<id>.json`), se queda solo con los enlaces `http(s)` normales (el `infoHash` de un torrent no es un archivo que rex pueda leer), descarta los que superan tus límites de resolución o tamaño y prueba el resto empezando por la mayor resolución. El enlace que se abre se guarda en caché hasta una hora antes de que caduque (una hora si el enlace no dice cuándo caduca). rex sigue la redirección y lee el archivo, con búsqueda, directamente desde el enlace. Un enlace que necesita sus propias cabeceras lo retransmite el propio rex-stremio, y una playlist HLS maestra la responde solo con su mejor variante.

**Sondeo.** Una vez por título, rex-stremio ejecuta ffprobe sobre su propia URL, para que `media_info` describa exactamente lo que leerá rex, y guarda el resultado en caché. Comprueba `probe_workers` títulos a la vez (4 si no lo cambias), y aun así pregunta a cada host de addon como máximo una vez cada `stream_interval_seconds`. El stream del que salió ese sondeo se recuerda y se prueba primero en cada reproducción, así que lo que se reproduce es lo que se le dijo a rex. El contenedor del sondeo elige la extensión de la ruta: `.mkv`, `.mp4`, `.ts`, `.avi` o `.m3u8` para HLS.

**Sondeos guardados.** Con una clave de API de DMM (`dmm_api_key`, o **DMM** en la página de ajustes), un stream de torrent se salta ffprobe cuando DMM ya tiene un sondeo de su archivo. El hash del torrent sale del `infoHash` del stream o de su enlace (los enlaces debrid de Torrentio lo llevan en la ruta). rex-stremio lee el tamaño del archivo de la respuesta del enlace a un `Range` de un byte, y pide a `POST /api/sponsor/mediainfo` de DMM hasta 100 hashes cada vez. Solo toma el sondeo de DMM cuando exactamente un archivo de ese release tiene ese tamaño, y ese nombre cuando el stream indica el nombre de su archivo. Todo lo demás se sondea como arriba, y ese sondeo vuelve a DMM (`POST /api/sponsor/probes`: el hash del torrent, el tamaño del archivo, su nombre cuando el stream lo indica, y la salida de ffprobe sin la dirección que leyó), para que el siguiente patrocinador que se encuentre el archivo se lo salte. DMM se queda con el primer sondeo de un archivo y responde primero a las instantáneas propias de zurg. `share_probes: false` los mantiene solo en rex-stremio; los de DMM se siguen usando. El sondeo de una playlist nunca se envía.

**Nombres.** Cada película y cada episodio llega a rex con `kind` y su id de IMDb en `ids`, para que Plex lo nombre como en [rex con tu propia app](any-source.md). El título, el resumen, la fecha y el póster del catálogo van en `display`, que solo se muestra hasta que Plex lo nombra. Un canal en vivo, o un título que solo conoce su addon, no tiene id de IMDb, así que `display` es lo único que lo nombra.

**Numeración.** Una película es una película. Las temporadas y los episodios de una serie vienen de Cinemeta, cuyos ids son de IMDb, y conservan sus números, así que un episodio nuevo nunca desplaza a los demás. rex los coloca según los números de TMDB, así que donde los de Cinemeta difieren, un episodio cae en el sitio equivocado.

**Ids.** Un id es el catálogo más el id de IMDb (y la temporada y el episodio), como `st-<catalog>-tt0111161`. Nunca cambia, así que una película en dos catálogos son dos elementos. Con **Catalogs as collections** activado, una película o serie que varios catálogos de una biblioteca listan es un solo título ahí, dentro de la colección de cada catálogo.

**Envío.** Cada seis horas y después de cada guardado: registra, luego cada título en cuanto se comprueba (`POST .../items`, hasta 20 títulos o lo que esté listo cada 5 segundos), y después una instantánea de cada catálogo, en partes de 200. La primera instantánea tras un guardado lleva `"force": true`, porque desmarcar catálogos puede eliminar más de la mitad. Si un catálogo responde vacío o solo en parte, la ronda no envía instantánea: añade y actualiza, no elimina nada, y una ronda completa posterior elimina lo que realmente salió.

## Solución de problemas {#troubleshooting}

| Lo que ves | Por qué | Solución |
|---|---|---|
| `rejected`: `not a video file` | El nombre del archivo no tiene extensión de vídeo, o es un `.m3u8` cuyo probe no es `hls` | Nombra los streams como `.m3u8` y envía su probe. Una canción necesita `"kind": "track"` |
| `rejected`: `no music library holds <file>` | Ninguna biblioteca de música acepta la pista | Declara una con `music` en el Paso 2 |
| Los álbumes muestran tus nombres de archivo bajo `[Unknown Artist]` | No hay `ids.mbid`, o hay un id de release que Plex no conoce, y no hay `display` | Envía el id de release de MusicBrainz del álbum, o `display` |
| Un álbum muestra las pistas equivocadas | `ids.mbid` apunta a otra edición, como una deluxe con más pistas | Elige una release con tu número de pistas |
| Un canal no aparece en la guía de Live TV | No hay `channel`; fue rechazado y el log de rex dice por qué (`channel.guide[...]`); o otro canal ya tiene ese número, lo cual no se registra | Corrige el campo que indica el log, o elige un número libre |
| Falta Live TV en una app de Plex | Aún no se envió ningún item con `channel`, o la app no fue probada | Envía un `channel`, y usa Plex Web o Plex para Android, que son las apps probadas |
| Un vídeo nunca aparece | Está retenido (su `media_info` no tiene streams, o se envió un archivo sin él), o un stream enviado sin `media_info` fue rechazado | Analízalo con probe y envíalo de nuevo |
| `rejected`: `... is already <id>'s file` | Otro id tiene ese `path` | Mantén un solo id por path |
| Un snapshot responde `409`: `the snapshot would remove more than half of this source's items` | Tu snapshot deja fuera más de la mitad de lo que rex tiene de ti: un disco que falta, un listado fallido o una limpieza real | Arregla lo que falta. Si era intencionado, envía la última parte del snapshot con `"force": true` |
| Episodios con título "Episode 1" y tiles en blanco | No hay `display` | Envía `display` con cada vídeo |
| Una película enviada con su id de IMDb mantiene tu título `display`, no el de Plex | rex pide los títulos a Plex solo cuando está reclamado | Reclama rex: [paso 3 de rex con tu propia app](any-source.md#step-3-add-it-to-a-plex-account) |
| Las imágenes no se muestran | La URL está en tu red local pero no bajo la `url` registrada de tu addon, o no es http(s) | Sírvelas desde la dirección propia de tu addon, o aloja en internet público. |
| La reproducción falla con 502 en el log de rex | Tu addon no respondió, o el sitio del stream lo rechazó | Revisa primero el log de tu addon |
| Un título borrado en una app de Plex sigue ahí | Tu addon respondió al `DELETE` con algo distinto de `2xx` o `404` | Bórralo de tu lado y luego responde `2xx` |
| Un título borrado vuelve | Tu addon sigue enviando el vídeo | Deja de enviar lo que se borró |

¿Sigues atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Pedir ayuda](../guides/remote-help.md) explica qué incluir.
