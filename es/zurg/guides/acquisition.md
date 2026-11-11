# Fuentes de adquisición {#acquisition-sources}

Watchlist de Plex, tu [lista de deseados de DMM](#dmm-wanted-list), [Seerr](https://github.com/seerr-team/seerr), [Radarr](https://radarr.video) y [Sonarr](https://sonarr.tv) usan un mismo motor de adquisición. Lleva el control del progreso, los reintentos y los acuses de recibo. Los resultados de Newznab se convierten en NZB para el backend de Usenet de zurg. Los resultados de Torznab se convierten en info hashes para una cuenta de debrid. Consulta [Newznab y Torznab](#newznab-and-torznab).

El motor solo confirma una captura después de comprobarla. Un NZB tiene que llegar al servidor de noticias. En una cuenta `torbox_nzb`, TorBox tiene que descargarlo en su lugar. Un torrent tiene que aparecer en la biblioteca con sus archivos. Consulta [Verificar una captura](#verifying-a-grab).

Una versión que zurg captura conserva los ids del título para el que se capturó, todos los que Plex usa para hacer coincidir los títulos: IMDb, TMDB y, en el caso de una serie, TVDB. Nunca se vuelve a identificar a partir de su nombre. Esos ids reemplazan cualquier id que le haya asignado DMM o el nombre de la versión, aunque nunca uno que hayas puesto tú a mano. Una versión que ya estaba en tu biblioteca cuando zurg la eligió puede haberse añadido para otra cosa, así que solo toma esos ids cuando no tiene ninguno o ya tiene el mismo. Con [`rex_url`](../reference/config.md#rex) configurado, una película capturada se envía a rex como esa película, usando esos ids, incluso cuando DMM no pudo ubicarla; los episodios de una serie siguen numerados según la ubicación de DMM y llevan los ids de la serie. Al arrancar, zurg hace lo mismo con cada versión que sus trabajos guardados capturaron antes, lo que repara las versiones que perdieron sus ids antes de este cambio.

## Configuración {#configuration}

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

Ejecútalo en una instancia de zurg con un proveedor `nzb` o una cuenta `torbox_nzb` (TorBox Pro), una cuenta de debrid que acepte torrents, o ambas. Los NZB de indexadores Newznab llegan a su directorio `nzbs/`. Una cuenta `torbox_nzb` no tiene servidores de noticias contra los que comprobar; una descarga ahí se verifica según si TorBox la obtuvo.
Los torrents de indexadores Torznab se envían a una cuenta de debrid. Solo se añaden cuando esa cuenta ya los tiene en caché. Si no hay ninguno de los dos tipos de cuenta, las fuentes no se inician. La página de adquisición explica el motivo. Plex necesita el `plex_token` existente. Seerr necesita su URL base y su clave API, de forma independiente a cualquier ajuste de Plex en zurg. Se admiten subrutas en la URL y URLs que terminan en `/api/v1`. Radarr necesita su URL base (una URL base como `/radarr` y un `/api/v3` final están bien), su clave API de **Settings > General** y `library_path` cuando ve el montaje de zurg en otra ruta: consulta [Comportamiento de Radarr](#radarr-behavior). Sonarr usa los mismos tres ajustes: consulta [Comportamiento de Sonarr](#sonarr-behavior).

Ambos se leen al iniciar zurg, como el resto del bloque. `indexer_concurrency` cubre las búsquedas y las descargas de NZB juntas, porque un indexador limita la clave y no el endpoint. Las claves de indexador suelen compartirse, y tres llamadas por clave es lo que se ha medido como seguro en claves que también sirven a otra aplicación.

Mantén estables los nombres y las URLs de Seerr: identifican las colas guardadas. Rotar una clave de Seerr conserva su cola. Reinicia después de añadir fuentes o cambiar sus URLs o credenciales. Los ajustes existentes `watchlist:` y `plex_watchlist_enabled` siguen funcionando a través de un adaptador `plex-watchlist` automático. Una fuente `plex_watchlist` explícita, incluso desactivada, reemplaza el interruptor de activación heredado. Solo una fuente de Plex puede usar la cuenta de Plex configurada. Los ajustes de búsqueda compartidos recurren a `watchlist:` y sus valores predeterminados existentes; los indexadores omitidos recurren a los indexadores de watchlist/Stremio.

## Excluir versiones por nombre {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` enumera palabras que ningún release adquirido puede tener en su nombre.
Úsalo para evitar Dolby Vision o HDR10+ en un reproductor que no puede mostrarlos,
manteniendo a la vez el 4K. Se aplica por igual a todas las fuentes: la lista de seguimiento de Plex, Seerr, Radarr y Sonarr.
Se aplica tanto a los resultados de Usenet como a los de torrent. Un release que excluye nunca se descarga, guarda, añade a una cuenta de debrid ni se envía a Radarr o Sonarr.
Déjalo fuera si no quieres excluir nada. zurg lo lee al arrancar, igual que el resto de `config.yml`.

## Preferir versiones por nombre {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

`prefer_words` enumera palabras, como grupos de release, que colocan un release primero entre los releases de su resolución. Se compara igual que `exclude_words`: palabras completas, sin distinguir mayúsculas. La lista es un orden: un release con la primera palabra va antes que uno con la segunda, y así sucesivamente. Es una preferencia, no un filtro. Si ningún release tiene ninguna de las palabras, zurg toma lo que habría tomado sin ellas.

Un release preferido nunca pasa por delante de una resolución. Con `quality: best`, un release de 2160p de cualquier grupo sigue yendo antes que uno preferido de 1080p, y con `quality: 1080p` un 2160p preferido no pasa por delante de los releases de 1080p. Una mejora a una resolución más alta sigue ocurriendo cuando el grupo preferido no tiene ningún release en esa resolución.

Se aplica a todas las fuentes, y a los resultados de Usenet y de torrent por igual. Con una fuente `radarr` o `sonarr`, el perfil aún tiene que aceptar el release preferido. Cuando Radarr o Sonarr usan zurg como cliente de descarga, ellos eligen el release por su cuenta y `prefer_words` no se aplica ahí. Omítela si no quieres preferir nada.

Tampoco se toma nunca el release de una película cuando su nombre indica un año con más de uno de diferencia respecto al de la película, sea cual sea la fuente. Algunos indexadores archivan publicaciones bajo el id de IMDb de otra película: DrunkenSlug archiva The Aswang Chronicles (2012) bajo su secuela de 2014. Un nombre sin año no se rechaza por esto. Para la lista de deseados de DMM, que envía todos los títulos por los que se conoce una película (original, alternativos y traducciones), también se rechaza un release cuyo nombre no contiene completo uno de ellos: DrunkenSlug archiva Przesluchanie (1982) bajo An Affair (1982), y `Rocky.2015` no es *Rocky Horror Show Live*. Un nombre puede terminar donde empieza el subtítulo de un título, después de dos puntos o de un guion con espacios, así que `Diana.2021` es *Diana: The Musical*. Los acentos y los umlauts coinciden de las dos formas, así que `Les.Miserables` y `Verwuenscht.nochmal` cuentan.

Cómo se compara un nombre:

- **Solo palabras completas.** Un nombre se lee como palabras formadas por letras y dígitos. Los puntos, espacios, guiones, guiones bajos, corchetes y paréntesis separan todas las palabras. No importa si es mayúscula o minúscula. `DV` excluye `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` y `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD`. No excluye `DVDRip`, `DVD9`, `Come and See DvD 1` ni un título como *Adventures*, porque ninguno tiene la palabra DV.
- **Las frases coinciden en orden.** `Dolby Vision` o `DV HDR` coinciden con esas palabras una junto a otra, en ese orden, sea cual sea lo que las separe.
- **El `+` final forma parte de la palabra.** `HDR10+` es una palabra propia. Excluir `HDR10` deja en paz a los releases HDR10+, y excluir `HDR10+` deja en paz al HDR10 normal. Pon ambas para excluir las dos. Un `+` entre dos palabras las separa, como en `DD+7.1` o `DV+HDR10`.
- **Dos familias de grafías cuentan como una sola palabra.** Cualquier grafía de la lista excluye todas las grafías de su familia.

  | Escribe cualquiera de | Excluye nombres con cualquiera de |
  |---|---|
  | `DV`, `DoVi`, `Dolby Vision`, `DolbyVision` | `DV`, `DoVi`, `Dolby.Vision`, `Dolby-Vision`, `Dolby Vision`, `DolbyVision` |
  | `HDR10+`, `HDR10Plus` | `HDR10+`, `HDR10Plus` |

  Nada más tiene alias. `HDR` excluye nombres con la palabra HDR y no `HDR10`, `HDR10+` ni `HDRip`. `WEB-DL` coincide con `WEB-DL`, `WEB.DL` y `WEB DL`, y no con `WEBDL`.
- **Solo se lee el nombre del release.** Es el título que responde el indexador, antes de descargar nada. Los archivos de dentro no se leen. Un release de Dolby Vision cuyo nombre no lo indique no se excluye.

Excluir una palabra nunca afecta a la resolución. Con `DV` excluido, un release de 2160p con HDR normal o HDR10 se sigue tomando, y `quality: 4k` sigue poniendo primero los 2160p. Un release excluido cuenta como no encontrado. Una búsqueda de película o de episodio sigue avanzando por las páginas de cada indexador hasta tener diez releases que pueda tomar, hasta que el indexador se queda sin resultados, o hasta haber leído diez páginas. Una búsqueda de temporada lee una página y busca por separado cualquier episodio que esa página deje sin release. Un título cuyos releases están todos excluidos falla con "no eligible releases", igual que uno cuyos releases están todos por encima de `max_size_gb`, y se vuelve a intentar más tarde. Una petición 4K de Seerr solo toma releases de 2160p, así que espera cuando todos los releases de 2160p están excluidos.

### Exclusiones y perfiles de Radarr o Sonarr {#exclusions-and-radarr-or-sonarr-profiles}

Con una fuente `radarr` o `sonarr`, la exclusión va primero. Una release excluida nunca llega al parser de Radarr o Sonarr. Ninguna puntuación de formato personalizado la devuelve, y no cuenta como un rechazo por parte del perfil. Cada una de las demás releases la juzga el perfil tal como se describe en [Radarr behavior](#radarr-behavior) y [Sonarr behavior](#sonarr-behavior). Una release tiene que pasar ambos filtros. Un formato personalizado que puntúe Dolby Vision por debajo del mínimo del perfil hace lo mismo dentro de las *arr, y dejarlo no hace ningún daño.

Las mejoras siguen la misma regla. Si las únicas releases que subirían un archivo hasta el cutoff del perfil están excluidas, el archivo se queda por debajo del cutoff y el paso de mejoras de zurg sigue buscando sin quitar nada. Eso pasa cuando un formato personalizado da a Dolby Vision una puntuación alta y la puntuación de cutoff la necesita. Baja la puntuación de cutoff o quita esa puntuación del formato personalizado.

Cuando Radarr o Sonarr usan zurg como cliente de descargas a través del bloque `sabnzbd:` o `qbittorrent:`, buscan en sus propios indexadores y eligen la release ellos mismos. `exclude_words` no se aplica ahí. Excluye las mismas palabras en las *arr con un formato personalizado con puntuación por debajo del mínimo del perfil o con **Must Not Contain** en un perfil de release.

## Elegir por idioma de audio y subtítulos {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

`audio_languages` solo admite lanzamientos con una pista de audio en uno de los
idiomas indicados, y `subtitle_languages` solo lanzamientos con una pista de subtítulos
en alguno de ellos. Si omites cualquiera de los dos, no se pide nada por ese lado. Ambos se aplican a todas las fuentes.

Cada lista también es un orden: un torrent con un idioma anterior va por delante
de uno que solo tiene un idioma posterior. `[de, original]` toma un doblaje en alemán si
hay uno, y el idioma original si no lo hay.

zurg lee el idioma de los streams del lanzamiento, no de su nombre. La mayoría de
lanzamientos no dicen en su nombre qué idiomas tienen: casi ninguno de los de Parasite
dice KOREAN. Escribe códigos ISO 639 de dos o tres letras: `en`, `eng`, `de`, `deu` y `ger`
funcionan todos. Un nombre como `german` se rechaza al arrancar.

Algunos idiomas tienen doblajes o subtítulos que varían, y un código puede indicar uno de ellos:

| Escribe | Para |
|---|---|
| `es-419`, `es-ES` | Español latinoamericano (Latino) o castellano |
| `pt-BR`, `pt-PT` | Portugués brasileño o europeo |
| `fr-CA`, `fr-FR` | Francés québécois (VFQ) o de Francia (VFF, VFI) |
| `nl-BE` | Flamenco |
| `yue`, `cmn` | Cantonés o mandarín |
| `zh-Hant`, `zh-Hans` | Subtítulos en chino tradicional o simplificado (`zh-TW` y `zh-HK` se leen como tradicional, `zh-CN` como simplificado; para audio en cantonés escribe `yue`) |
| `nb`, `nn` | Noruego bokmål o nynorsk |

El código sin más abarca todos ellos: `es` toma latino y castellano, `zh`
cantonés y mandarín, `no` bokmål y nynorsk. Una parte después del idioma que
zurg no puede leer, como `es-latam`, se rechaza al arrancar. zurg averigua de cuál es una pista
por su título, porque los streams nunca lo traen en un formato que zurg pueda leer:
"Latino", "Spanish (Latin American)", "Castellano", "French (Canada)", "VFQ",
"Portuguese (Brazilian)", "Chinese (Cantonese)", "繁体中字". Una pista cuyo
título no dice nada de eso nunca se rechaza por ese motivo. El nombre del lanzamiento decide el empate
cuando dice algo, como `Dual-Lat`, `[Castellano]`, `MULTi.VFQ`, `VF2`,
`PT-BR` o `[ES-LA]`. Un nombre nunca rechaza nada, y el título de una pista
tiene prioridad sobre él. Para `[es-419, es]` zurg toma, en orden, una pista titulada Latino,
una sin título en un lanzamiento llamado Latino, una sin título, una sin título
en un lanzamiento llamado Castellano, y una pista titulada Castellano. Para un
hogar latinoamericano:

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

`audio_or_subtitles: true` admite un lanzamiento que tenga el audio o los
subtítulos, en lugar de ambos. Un lanzamiento con el audio va por delante de uno con
solo subtítulos.

`original` significa el idioma en que se hizo el título, según lo registra TMDB:
coreano para Parasite, francés para Anatomy of a Fall. zurg lo pide a DMM, así que
necesita `dmm_api_key`. Sin la clave, `original` no pide nada.

### Cómo se evalúa una versión {#how-a-release-is-judged}

- **Antes de añadir un torrent.** DMM guarda los datos de ffprobe de cada release que zurg ha analizado. Con `dmm_api_key` configurada, zurg los lee para todos los resultados de torrent en una sola llamada. Un torrent cuyos streams no tienen el idioma nunca se añade. Uno que sí lo tiene va por delante de los torrents de los que no se sabe nada. En una medición de cinco películas el 2026-10-25, DMM tenía estos datos para aproximadamente un tercio de los torrents que Real-Debrid tenía en caché.
- **Después de la descarga.** Cada descarga, sea torrent o Usenet, se analiza una vez que está en la biblioteca: con los datos de DMM si los tiene, y si no, con ffprobe. Una descarga cuyos streams no tienen el idioma se aparta como una publicación caída. Se quita de la cuenta de debrid o del directorio de vigilancia, y el siguiente candidato se prueba enseguida. El panel muestra el motivo, por ejemplo "it has no English audio, only French".
- **Una mejora mantiene sus idiomas.** Cuando la lista de deseados de DMM mejora una película a una resolución mejor, la nueva release debe tener idiomas al menos tan arriba en tus listas como la copia que reemplaza. Una copia 1080p en latino no se cambia por una 2160p en castellano.
- **Lo desconocido se acepta.** Una release nunca se rechaza por lo que no se puede leer. Eso incluye las pistas sin etiquetar, una pista etiquetada `und` o `mul`, una release a la que solo se llega a través de sus archivos comprimidos, o una que no tiene análisis en un minuto. zurg registra que la aceptó tal cual.

Los comentarios y las pistas de audiodescripción no cuentan como audio de la película, y los subtítulos de comentarios no cuentan como subtítulos. Eso incluye un comentario que solo aparece nombrado en el título, como "Commentary by Bong Joon Ho" en Parasite. Las pistas de subtítulos tituladas forced (forzados, forcés), signs o songs no cuentan como subtítulos. La marca forced por sí sola no excluye una pista: los remuxes de películas extranjeras marcan sus subtítulos completos en inglés como forced para que los reproductores los muestren.

Solo se juzgan los archivos de vídeo principales de una release, los que duran al menos una quinta parte de lo que dura el más largo. Los extras suelen tener menos doblajes que la película. En un pack de temporada, cada episodio debe tener el idioma.

Una release apartada por su idioma sigue apartada durante 30 días, igual que una publicación caída, aunque cambies los idiomas.

## Lista de deseados de DMM {#dmm-wanted-list}

Un patrocinador de DMM añade películas y series a una lista de deseados con el botón **Want** de sus páginas en debridmediamanager.com, y las lista en `/wanted`. zurg lee esa lista siempre que `dmm_api_key` esté configurada: no hay nada más que escribir. No se monta nada y no interviene Sonarr ni Radarr. La fuente se llama `dmm-wanted` y se consulta cada 60 segundos.

- **Qué se descarga.** Una película una vez, y después cualquier mejora de ella (más abajo), o una copia en cada una de varias resoluciones cuando `quality` es una lista (más abajo). De una serie, los episodios ya emitidos de las temporadas deseadas, o de todas las temporadas cuando se desea la serie completa, y sus nuevos episodios según se emitan.
  DMM envía los ids de IMDb, TMDB y TVDB de cada título, su año y, en el caso de una serie, los episodios emitidos hasta ahora, numerados como los numera TMDB. Los especiales nunca se listan. Una temporada que aún se está emitiendo se descarga como episodios sueltos, ya que todavía no hay ningún pack que la cubra.
- **Cuándo se busca.** Una película se busca al salir en casa: DMM envía el día de su primera fecha de lanzamiento digital, físico o de TV que TMDB conozca, y zurg espera como mucho hasta ese día. Después busca cada dos minutos durante seis horas y cada diez hasta dos días después, igual que con un [nuevo episodio](#sonarr-behavior). Nunca una fecha de cine: un WEB-DL se publica con el lanzamiento digital. El episodio más nuevo de una serie se fecha de la misma manera, a partir de la hora en que se emitió cuando DMM la conoce. Un título sin fecha mantiene los reintentos habituales, separados como máximo una semana, y nada de la lista se [aparca](#persistence-and-recovery). Una película que espera su próximo intento se busca en la siguiente consulta cuando DMM ve una nueva publicación de Usenet que la menciona.
- **Adónde va.** Igual que cualquier otra fuente: un NZB de un indexador Newznab al backend Usenet de esta instancia, o un torrent de un indexador Torznab a una cuenta de debrid que ya lo tenga en caché, según cuál prefiera `prefer` primero. Se aplican `quality`, `max_size_gb` (por episodio en un pack de temporada), `exclude_words` y los [idiomas](#choosing-by-audio-and-subtitle-language), y también `max_season_size_gb` si lo escribes.
- **Indexadores.** Si no escribes ningún indexador en `acquisition:`, `watchlist:` ni `stremio:`, la clave también busca en los de DMM: su indexador Usenet y los torrents que sabe que Real-Debrid o AllDebrid tienen (`/api/torznab/cached`). Si escribes cualquier indexador, sustituye a ambos.
- **Confirmación.** Una vez comprobada la descarga de una película, zurg avisa a DMM, y la película sale de la lista que lee zurg, salvo que espere una mejora o a otra de sus copias (más abajo); `/wanted` muestra cuándo. Una serie se queda en la lista y sigue siendo seguida hasta que la quites allí. Quitar un título detiene el trabajo con él.
- **Mejoras.** Una película cuyo nombre de lanzamiento indica una resolución inferior a la que busca `quality` (2160p para `best` y `4k`, 1080p para `1080p`, 720p para `720p`) se queda en la lista. zurg descarga un lanzamiento con una resolución superior a la copia que tiene cuando aparece uno, hasta que tenga ese. Una vez que la mejor copia pasa su comprobación, la antigua se elimina si zurg la descargó, a partir de la compilación nocturna del 2026-10-30: un torrent de la cuenta a la que zurg lo añadió, o un NZB del directorio de vigilancia. Una copia que ya era tuya se conserva, y también una que tenga algo de ella colocado bajo `__magic__`, por ejemplo por una importación de Radarr. Un lanzamiento cuyo nombre no indica ninguna resolución nunca se mejora, y `quality: smallest` no mejora nada. Hasta que aparezca un lanzamiento mejor, la película se busca aproximadamente una vez por semana, y nunca se [aparca](#persistence-and-recovery). Activado por defecto; `upgrades: false` en el bloque `acquisition:` lo desactiva.
- **Una copia en cada una de varias resoluciones.** Con `quality` escrito como lista, por ejemplo `[1080p, 4k]`, de cada película se mantiene una copia en cada resolución de la lista. Consulta [una copia en cada una de varias resoluciones](#a-copy-at-each-of-several-resolutions).
- **Sin cuenta de descarga.** Una instancia sin proveedor `nzb`, sin cuenta `torbox_nzb` (TorBox Pro) y sin cuenta de debrid que acepte torrents no lee la lista.

**Dos zurg con la misma clave descargan cada título dos veces.** Cada uno lee la misma lista, así que deja la lista de deseados en uno de ellos y desactívala en los demás escribiéndola como disabled:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

Si la patrocinación caduca o la clave se restablece, la lista se detiene. zurg registra una advertencia de que DMM rechazó `dmm_api_key` y vuelve a preguntar una hora después, o al momento si configuras una clave nueva. Lo que ya descargó se queda en tu biblioteca.

### Una copia por cada una de varias resoluciones {#a-copy-at-each-of-several-resolutions}

Escribe `quality` como una lista para guardar una copia de cada película de la lista de deseados en cada resolución, por ejemplo para que un TV de 1080p reproduzca una sin que se transcodifique el archivo 4K:

```yaml
acquisition:
  quality: [1080p, 4k]
```

Cada copia toma la mejor versión en o por debajo de su propia resolución, nunca una por encima. La copia de 1080p no toma ninguna versión de 2160p, ni ninguna cuyo nombre no indique resolución, porque podría ser cualquier cosa. La copia de 4K toma una versión así solo cuando no se puede tomar ninguna versión que indique resolución, y entonces la conserva para siempre, ya que una versión sin resolución nunca se mejora. Cada copia se actualiza por su cuenta, hasta su propia resolución. Cuando las dos tomarían la misma versión, comparten una sola copia, y esa copia se elimina solo cuando ninguna de las dos la tiene ya:

| Versiones disponibles | Copia de 1080p | Copia de 4K | En tu biblioteca |
|---|---|---|---|
| 720p | el 720p | el mismo 720p | el 720p |
| + 1080p | se actualiza al 1080p | se actualiza al 1080p | el 1080p |
| + 2160p | se queda | se actualiza al 2160p | el 1080p y el 2160p |

Una película que solo sale en 2160p obtiene su copia de 4K de inmediato, y su copia de 1080p cuando aparezca una versión de 1080p o inferior. Hasta entonces se busca más o menos una vez por semana y nunca se aparca. La película sale de la lista que lee zurg solo cuando cada copia tiene una versión que no quiere mejor que esa.

- **Lo que admite la lista.** Dos o más de `4k` (o `2160p`), `1080p` y `720p`, cada uno una vez, en cualquier orden y en cualquier mayúscula o minúscula. zurg se niega a arrancar con cualquier otra cosa y dice `acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`. Una lista de uno se lee como ese único valor, así que `[1080p]` equivale a `quality: 1080p` y mantiene una copia; escribe `4k` ahí, ya que `[2160p]` se rechaza.
- **Solo en el bloque `acquisition:`.** `quality` bajo `watchlist:` es un solo valor; una lista ahí impide que zurg arranque. El ajuste de calidad de la página de configuración edita solo `watchlist.quality` y no cambia nada mientras `acquisition.quality` esté escrito.
- **Solo películas de la lista de deseados de DMM.** Las series de esa lista, y todas las demás fuentes, siguen obteniendo una sola copia, elegida como si `quality` nombrara solo la resolución más alta de la lista: `[1080p, 4k]` funciona como `quality: 4k` para ellas, y `[720p, 1080p]` como `quality: 1080p`, que aun así toma una versión de 2160p cuando no hay ninguna de 1080p.
- **Con `upgrades: false`** cada copia conserva la primera versión que toma. Mientras solo esté disponible un 720p, ambas copias son ese 720p para siempre.
- **Las películas obtenidas antes de escribir la lista** se vuelven a obtener, con una copia en cada resolución. Una copia cuya mejor versión ya está en tu biblioteca la usa tal cual. zurg nunca elimina la copia obtenida antes: bórrala tú mismo si las nuevas copias la reemplazan.
- **Volver a un solo valor** deja las copias donde están.
- **`/wanted` muestra la película como obtenida** en cuanto está su primera copia, con la primera versión que tomó zurg. No muestra qué resolución sigue esperando. Una película obtenida antes de escribir la lista puede seguir mostrando "waiting for" la resolución que esperaba entonces.

### Reproducir una película desde YouTube {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM wanted list, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the wanted list takes a stream:
  a film the Plex watchlist also wants is not settled for it by one, since Plex cannot
  play it, and the watchlist keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one wanted list (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the wanted list while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## Comportamiento de Seerr {#seerr-behavior}

El adaptador sigue las [rutas de solicitudes](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts), las [definiciones de estados](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts) y el [contrato de la API](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml) de seerr-team/seerr.

- Consulta todas las páginas de solicitudes aprobadas usando `X-Api-Key`. Si una página falla, se conserva la cola anterior y se pausa el trabajo de esa fuente.
- Vuelve a comprobar la aprobación antes de adquirir. Las solicitudes pendientes, rechazadas, fallidas, completadas, eliminadas y las que ya están disponibles no inician descargas.
- Resuelve los IDs a través de Seerr. La adquisición de series se limita a las temporadas solicitadas y aprobadas y a sus episodios ya emitidos. Una temporada parcial sigue pendiente.
- Trata 4K y no 4K por separado. Una versión 1080p no puede satisfacer una solicitud 4K.
- Vuelve a revisar las solicitudes abiertas cada 30 minutos tras una adquisición correcta, para encontrar episodios nuevos de las temporadas solicitadas. Los episodios no anunciados solo se convierten en trabajo cuando aparecen en los metadatos de Seerr.
- Prioriza los packs una vez que se han emitido todos los episodios conocidos. Las temporadas en emisión usan episodios sueltos. Los especiales (temporada 0) no son compatibles. Una solicitud con la temporada 0 aprobada no se adquiere en absoluto y falla hasta que se aparque.
- No escribe estados de solicitud ni disponibilidad. El escaneo del servidor multimedia de Seerr informa de la disponibilidad real y notifica a quien hizo la solicitud. Guardar un NZB no demuestra que esté indexado o sea reproducible, por eso el motor lo comprueba antes de contar una temporada como adquirida.

Configura el escaneo de biblioteca de Seerr para que incluya la biblioteca que sirve esta instancia. Si Sonarr/Radarr ya adquieren las mismas solicitudes, desactiva ese flujo de trabajo solapado antes de activar este adaptador. El adaptador no emula un servidor *arr ni cambia la configuración de servicios de Seerr. El sondeo proporciona la recuperación tras reinicios; no se necesita ningún webhook.

## Comportamiento de Radarr {#radarr-behavior}

Radarr mantiene la lista y es dueño de la biblioteca. zurg se encarga de buscar y descargar. Radarr nunca busca ni descarga nada: zurg lee lo que Radarr quiere, elige una versión de sus propios indexadores, la verifica con los servidores de noticias (la obtención de TorBox en una cuenta `torbox_nzb`) o con la cuenta de debrid que la tiene, coloca el video en la carpeta de la película dentro de `__magic__` y le pide a Radarr que vuelva a escanear solo esa película. Nada se copia: el video es un archivo en la biblioteca de zurg que Radarr ahora ve en su carpeta.

### Configurar Radarr {#setting-up-radarr}

1. **Carpeta raíz dentro de `__magic__`, un nivel más abajo.** Por ejemplo
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` en macOS,
   `Z:\__magic__\movies` en Windows). No `__magic__` en sí, ni
   `__magic__/__all__`, que lista todas las versiones de la biblioteca. Una película
   cuya carpeta esté en cualquier otro sitio se omite, con una única advertencia en el
   registro de zurg. En Windows, Radarr solo ve `Z:` cuando se ejecuta en la misma
   sesión de inicio de sesión que zurg, es decir, no como servicio de Windows: consulta
   [las reglas de sesión](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Listas de importación con Search for Movie desactivado al añadir.** Añade películas
   como quieras (a mano, desde listas, o con Seerr apuntando a Radarr). Deja
   **Search for Movie** desactivado al añadir, ya que zurg es quien hace las búsquedas.
3. **No hacen falta indexadores ni cliente de descargas.** Si Radarr los tiene, puede
   bajar contenido por su cuenta junto con zurg, así que desactiva la búsqueda automática
   en sus indexadores (o elimínalos) para las películas que gestiona zurg.
4. **`library_path` es donde Radarr ve `__magic__`.** Cuando Radarr se ejecuta en la misma
   máquina que zurg y ve el montaje donde zurg lo monta, déjalo sin definir: por defecto
   es el `mount_path` de zurg más `/__magic__`. Cuando Radarr se ejecuta en un contenedor
   que monta zurg en otra ruta, ponla ahí, por ejemplo `/data/zurg/__magic__`. Una película
   en `/data/zurg/__magic__/movies/Heat (1995)` se coloca entonces en
   `movies/Heat (1995)` dentro del `__magic__` de zurg. Las rutas de Windows como
   `Z:\__magic__` también funcionan. El contenedor de Radarr solo está cubierto en un host
   Linux: Docker Desktop en macOS y Windows ejecuta los contenedores en una VM, y pasar
   el montaje de zurg a ella no está probado, así que ejecuta Radarr de forma nativa allí.

   Si Radarr también recibe descargas desde los endpoints de [SABnzbd](sonarr-radarr.md)
   o [qBittorrent](sonarr-radarr-torrents.md) de zurg, tiene que ver su carpeta de
   descargas en `library_path/__all__`, a través del mismo volumen que sus carpetas raíz;
   si no, cada importación desde ella es una copia del archivo completo. zurg pregunta a
   Radarr dónde ve ambas rutas y lo indica en la página de adquisición, en su registro y
   en `zurg doctor` cuando no pueden compartir montaje; consulta
   [Un solo volumen para la carpeta de descargas y las carpetas raíz](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### Qué le pide zurg a Radarr {#what-zurg-asks-radarr-for}

Cada sondeo lee la lista de películas de Radarr y actúa sobre cada película que está monitorizada, **disponible** según la disponibilidad mínima de la película, y que o no tiene archivo o tiene uno por debajo del cutoff de su perfil de calidad, siempre que el perfil permita mejoras. Por debajo del cutoff significa por debajo de la calidad de corte o por debajo de la puntuación de formato personalizado de corte, tal como la cuenta Radarr. Una película que aún no ha salido, como una fecha con meses de antelación, espera hasta que Radarr diga que ya está disponible.

Cada release candidato que zurg está a punto de inspeccionar se envía al parser propio de Radarr (`/api/v3/parse`) y se juzga según el perfil de calidad de la película. Así, lo que zurg acepta es lo que Radarr también habría aceptado:

- **Tiene que ser esta película.** Radarr debe asociar el título a la misma película. Una búsqueda por ID en un indexador devuelve otras películas (una búsqueda de *Psycho* devolvió *Ed Gein: The Real Psycho*), y un título que Radarr no asocia a nada se rechaza. Un año en el título que difiera más de uno del de la película también se rechaza.
- **Primero se aplican la lista de permitidos y la puntuación mínima del perfil.** La calidad analizada tiene que estar permitida por el perfil, la puntuación de formato personalizado tiene que alcanzar el mínimo del perfil y el tamaño tiene que encajar en los límites de la calidad en **Settings > Quality** para la duración de la película.
- **El release tiene que estar en el idioma del perfil.** Con **Original**, que es el valor por defecto, Radarr tiene que leer el título como el idioma original de la película, así que un release solo en francés de una película en inglés se rechaza. Un título que no nombra ningún idioma se considera original. Si se nombra un idioma, se exige ese idioma, y **Any** acepta todos. Esto vale tanto para un primer archivo como para una mejora.
- **Las mejoras se dirigen al cutoff más adelante.** Una película sin archivo acepta cualquier release que pase las comprobaciones anteriores. Una vez que tiene un archivo por debajo del cutoff, solo se acepta un release mejor: una calidad superior según el orden del perfil mientras el archivo esté por debajo de la calidad de corte, o una puntuación de formato personalizado superior (al menos en el paso de mejora del perfil) mientras esté por debajo de la puntuación de corte. Nunca se acepta una calidad inferior. Los releases PROPER y REPACK de la misma calidad no cuentan como mejoras.

El perfil se aplica al release que zurg está a punto de tomar como lista de permitidos: la película correcta, una calidad permitida, la puntuación mínima, el idioma y los límites de tamaño.
Por defecto, su orden de preferencia no se usa para elegir entre los releases que permite. zurg toma el primer release permitido que sea más barato de comprobar, probando primero los releases web (WEB-DL, WEBRip), luego los Blu-ray y después el resto, porque los releases web son los que más a menudo se publican como un único archivo de vídeo. Si el perfil prefiere algo mejor que lo que llega y permite mejoras, Radarr ve el archivo de la película por debajo del cutoff, y la pasada de mejora de zurg busca el release mejor una vez que la película ya tiene uno. El primer archivo llega rápido, y el orden del perfil se cumple con la mejora. Establece `best_first: true` para que la primera descarga siga el orden del perfil.
Consulta [Tomar primero lo mejor del perfil](#taking-the-profiles-best-first).

Cuando una búsqueda por el ID de IMDb o TMDB de la película no devuelve nada en absoluto, zurg vuelve a buscar por título y año, como hace Radarr. Muchas publicaciones, sobre todo los pequeños documentales, se indexan sin ningún ID. El parser de Radarr decide si cada resultado es la película, así que una película de mismo nombre se rechaza como cualquier otra coincidencia errónea.

Radarr solo se consulta sobre un release cuando zurg está a punto de inspeccionarlo, de uno en uno, así que una película con un release de un solo archivo cuesta de una a tres consultas. No se pregunta nada más una vez guardada una publicación directa. Un título que nombra una resolución para la que el perfil no tiene ninguna calidad permitida, como un release 2160p para un perfil HD-1080p, se rechaza sin preguntar a Radarr. Un título que no nombra ninguna resolución, o que nombra más de una, siempre va a Radarr, y también todos los títulos cuando el perfil permite una calidad cuyo nombre no indica ninguna resolución (SDTV, DVD, Unknown, Raw-HD, BR-DISK). zurg hace como máximo ocho llamadas a un mismo Radarr a la vez.

Si no se puede contactar con Radarr, no se decide nada: la película espera al siguiente sondeo, y ningún release se descarta porque Radarr no respondiera.

### Colocar el archivo {#placing-the-file}

Una vez que un release ha sido comprobado, zurg coloca su video en la carpeta de la película, tal como lo habría importado Radarr, moviéndolo dentro de `__magic__`. No se copia ni se descarga nada.

- **Se coloca el video más grande.** Es el archivo `.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov` o `.ts` más grande del release, contando lo que hay dentro de sus archivos comprimidos. Un release servido desde un solo archivo comprimido es el contenido de ese archivo. Un conjunto RAR con archivos sueltos al lado, como una publicación scene con su muestra y su `.nfo`, se explora como una carpeta del release, y el video que hay dentro se coloca desde ahí. Las muestras, los featurettes, los subtítulos y los archivos `.nfo` se quedan en `__magic__/__all__`. El archivo conserva el nombre que tiene en el release, salvo que ese nombre no diga nada sobre la película (sin año y sin ninguna palabra de su título); en ese caso toma el nombre del release, para que Radarr pueda leer su calidad.
- **Una muestra nunca se coloca.** Un video con nombre de muestra (`sample-…`, `….sample.mkv`, una carpeta `Sample/`) se deja fuera, por grande que sea, a menos que el propio nombre del release también diga sample. Una película que solo tiene la palabra en su título (`Sample.Size.2019`, `Death.Proof.2007`) la lleva también en el nombre del release; en ese caso el video se deja fuera solo cuando ocupa menos de una quinta parte de su release. Un release cuyo único video es su muestra, incluido una publicación que es solo su muestra, se aparta y se prueba el siguiente candidato, para que una mejora nunca reemplace tu archivo por un clip de un minuto.
- **Se rechaza antes de moverlo si no se puede leer.** Esta es la comprobación que recibe una importación de Sonarr o Radarr a través del montaje. Un release cuyos artículos ya no tienen los servidores de noticias, o cuyo archivo comprimido nunca se abrirá, se aparta como una publicación muerta y se prueba el siguiente candidato. Un release que no se puede leer en este momento, como uno en una cuenta que está en enfriamiento, se vuelve a intentar más tarde.
- **Radarr mantiene un solo archivo por película, así que una mejora reemplaza el archivo anterior.** Cuando el nuevo video está en la carpeta, todos los demás videos que la biblioteca de zurg puso allí quedan ocultos en la carpeta. Ocultar significa marcarlos como tombstone, igual que un borrado a través del montaje: el release anterior sigue en `__all__` y en su cuenta. Un archivo real que tú hayas puesto en la carpeta por tu cuenta se deja en paz. El archivo anterior se retira después de colocar el nuevo, así que si una colocación falla, la película conserva el archivo que tenía.
- **Radarr vuelve a escanear después.** zurg le indica al montaje qué carpetas cambiaron, para que el escaneo no lea una carpeta que el montaje todavía recuerda como vacía, y luego le pide a Radarr que vuelva a escanear solo esa película.

Una fuente de Radarr necesita `__magic__` (`magic.enabled`). Sin él, la fuente no arranca y lo indica en el registro y en la página de adquisición.

### Qué muestra Radarr {#what-radarr-shows}

**Activity** se queda vacío: no hay entradas en la cola ni eventos de grab o import, porque Radarr no capturó nada. La película simplemente tiene un archivo después del rescan que zurg pide, y su calidad y custom formats son la lectura que hace Radarr de ese archivo. El log de zurg registra cada película que completa.

`only_new_items` y `remove_after_grab` no hacen nada en una fuente de Radarr. Las películas pendientes de Radarr son trabajo, igual que las solicitudes aprobadas de Seerr, y Radarr decide cuándo una película deja de estar pendiente. Mantén el `name` de la fuente estable: identifica la cola guardada, mientras que la URL y la key sí pueden cambiar libremente.

## Comportamiento de Sonarr {#sonarr-behavior}

Sonarr funciona igual que Radarr. Sonarr lleva la lista y es dueño de la biblioteca.
zurg hace la búsqueda y la descarga. Sonarr nunca busca ni toma nada. zurg lee los episodios que le faltan a Sonarr y elige una versión de sus propios indexadores. La comprueba con los servidores de noticias (la descarga de TorBox en una cuenta `torbox_nzb`) o con la cuenta de debrid que la tiene, y pone el vídeo de cada episodio en la carpeta de temporada de la serie dentro de `__magic__`. Luego le pide a Sonarr que vuelva a escanear solo esa serie. No se copia nada.

### Configurar Sonarr {#setting-up-sonarr}

1. **Carpeta raíz dentro de `__magic__`, un nivel más abajo.** Por ejemplo
   `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` en macOS,
   `Z:\__magic__\tv` en Windows). Una serie cuya carpeta esté en cualquier otro lugar se omite, con una sola advertencia en el registro de zurg.
   En Windows, Sonarr tiene que ejecutarse en la misma sesión de inicio de sesión que zurg, igual que Radarr.
2. **Búsqueda al añadir desactivada.** Añade series como quieras. Deja **Start search for missing episodes** desactivado, ya que zurg se encarga de la búsqueda.
3. **No hacen falta indexadores ni cliente de descarga.** Si Sonarr los tiene, puede descargar junto con zurg, así que desactiva la búsqueda automática en los indexadores de las series que zurg gestiona.
4. **`library_path` es donde Sonarr ve `__magic__`.** Funciona exactamente igual que con Radarr, incluida la comprobación de que Sonarr accede a la carpeta de descargas de zurg y a sus carpetas raíz a través de un mismo volumen. Déjalo fuera si Sonarr ve el montaje en la misma ruta donde zurg lo monta.

### Qué le pide zurg a Sonarr {#what-zurg-asks-sonarr-for}

Cada sondeo lee los episodios que faltan en Sonarr. Son episodios monitorizados de una serie monitorizada que ya se han emitido y no tienen archivo. zurg los agrupa por temporada y trata cada temporada como una sola pieza de trabajo.

- **Una temporada entera que ya terminó de emitirse puede llegar como pack.** Cuando faltan todos los episodios de una temporada y ninguno está aún por emitirse, primero se intenta un pack de temporada. Si no, los episodios que faltan de la temporada se toman uno a uno de los resultados de búsqueda de la temporada. Una temporada que ya tiene algunos de sus archivos nunca usa un pack, porque eso pondría una segunda copia de esos episodios en la carpeta.
- **Un episodio nuevo es trabajo nuevo.** Cuando se emite el episodio de la semana que viene, la temporada vuelve a aparecer con ese episodio. zurg no vuelve a buscar los episodios que ya tiene.
- **Un episodio nuevo se busca de nuevo en cuestión de minutos.** Su release suele publicarse en la hora siguiente a la emisión, así que una búsqueda justo a la hora de emisión a menudo no encuentra nada. Durante seis horas después de que se emita un episodio, zurg lo vuelve a intentar cada dos minutos, y después cada diez hasta dos días después de la emisión. Pasado eso, retrocede como con cualquier otra cosa (ver [persistencia y recuperación](#persistence-and-recovery)). En una cuenta de debrid, la release también tiene que estar ya en caché en esa cuenta, porque zurg solo añade lo que la cuenta tiene.
- **Un episodio borrado vuelve a estar pedido.** Cuando Sonarr lista un episodio que zurg ya había adquirido, zurg mira en la carpeta de la temporada. Si ya no hay ningún vídeo de ese episodio, se vuelve a buscar. Si sí lo hay, Sonarr todavía no ha reescaneado y no se busca nada.
- **Las mejoras son por archivo.** Un archivo de episodio por debajo del cutoff del perfil de calidad es una mejora, siempre que el perfil permita mejoras. Por debajo del cutoff significa por debajo de la calidad de cutoff o por debajo de la puntuación de cutoff de formato personalizado. La lista Cutoff Unmet de Sonarr solo cuenta la calidad. En Sonarr 4.0.20, un archivo con la calidad de cutoff que puntúa 0 de una puntuación de cutoff de 40 no aparece en esa lista. zurg cuenta ambas cosas, igual que la regla de mejora propia de Sonarr. Un archivo que contiene dos episodios es una sola mejora para los dos.
- **Los episodios de un programa diario se encuentran por el día en que se emitieron.** Sus releases se nombran por día (`The.Daily.Show.2026.11.03.Min.Jin.Lee...`), y los indexadores no los encuentran por número de episodio. Por eso, cada episodio que falta también se pide como búsqueda de texto con el título de la serie y el día, `The Daily Show 2026.11.03`. El parser de Sonarr convierte el día de nuevo en el episodio (S31E124), igual que hace con un título numerado por temporada.
- **Los episodios de un anime se encuentran por el número con el que la serie los cuenta.** Las releases de fansub se numeran desde el primer episodio de la serie (`[SubsPlease] Jujutsu Kaisen - 30` es el sexto de la segunda temporada). Por eso, cada episodio que falta también se pide como búsqueda de texto con el título de la serie y ese número, `JUJUTSU KAISEN 30`. Un lote que abarca los números de la temporada (`(25-47)`) es el pack de esa temporada. El parser de Sonarr asigna el número al episodio, usando sus nombres scene para la temporada (`Jujutsu Kaisen 2nd Season`, `Jujutsu Kaisen S2`), así que un título numerado de cualquiera de las dos formas se juzga como el episodio que es. Una release que Sonarr no asocia a ninguna serie, como una que lleva un nombre scene que Sonarr no conoce, se rechaza como cualquier otra.
- **Los especiales son la temporada 0.** Los especiales monitorizados de Sonarr aparecen en la lista como cualquier temporada y se piden como temporada `00` (un indexador al que se pide la temporada `0` responde con otra temporada). Solo puede coincidir una release que contenga `S00Exx`: un especial nombrado solo por su título no se parsea a nada, tampoco en Sonarr. Se colocan en la carpeta que indica **Specials Folder Format** de Sonarr.

Cada release candidata se pasa por el parser propio de Sonarr (`/api/v3/parse`) y se juzga según el perfil de calidad de la serie. Lo que zurg acepta es lo que Sonarr habría aceptado.

- **Tiene que ser esta serie y esta temporada.** Sonarr tiene que asociar el título a la misma serie. Un título que Sonarr no asocia a nada se rechaza, salvo que la serie no use numeración scene y la búsqueda de series de Sonarr encuentre primero esta serie por el nombre que aparece en el título (por ejemplo, un título en otro idioma).
- **Un pack tiene que ser la temporada completa.** Un pack parcial se rechaza. Un pack escrito como rango, como `Season 1 E01-E07`, cuenta si el rango es la temporada completa. Un pack de varias temporadas cuenta para cada temporada que nombra (ver [Packs de varias temporadas](#packs-of-several-seasons)). Sonarr lee `S01-S05` como solo la temporada 1 y nunca dice dónde termina, así que zurg lee el rango del título. Aun así, Sonarr tiene que asociarlo a la serie y considerarlo un pack completo de varias temporadas. Su tamaño se juzga según la duración de todas las temporadas que nombra.
- **Un episodio tiene que ser ese único episodio.** Una release que contiene dos episodios se rechaza para un episodio suelto.
- **El perfil se aplica igual que en Radarr.** La calidad tiene que estar permitida. La puntuación de formato personalizado tiene que alcanzar el mínimo del perfil. El tamaño tiene que encajar en los límites de la calidad en **Settings > Quality** para la duración de los episodios que contiene la release. Una mejora tiene que superar al archivo actual según las reglas de Sonarr. Los perfiles de Sonarr no tienen ajuste de idioma, así que un idioma solo cuenta a través de la puntuación de un formato personalizado, igual que en Sonarr.

El orden en que se elige entre las releases permitidas es distinto al de Radarr. Un pack de temporada se prueba antes que los episodios sueltos porque es una sola descarga donde los sueltos son varias. Entre las releases que Sonarr permite, zurg toma la que primero según el ajuste `quality`. Con `best`, eso es la resolución más alta y después la más grande, es decir, un pack por lo que contiene por episodio. Así, una temporada terminada con un pack 1080p se completa desde ese pack, aunque la misma búsqueda tenga todos los episodios en 2160p. Después, la pasada de mejoras sustituye el contenido episodio a episodio. Un pack que supere `max_size_gb` por episodio, o `max_season_size_gb` si escribiste uno para la temporada, nunca es candidato. `best_first: true` cambia ambas cosas. Ver [Tomar primero lo mejor del perfil](#taking-the-profiles-best-first).

Un título que nombra una resolución para la que el perfil no tiene ninguna calidad permitida se rechaza sin preguntar a Sonarr. zurg hace como máximo ocho llamadas a un mismo Sonarr a la vez. Si Sonarr no responde, no se decide nada. La temporada espera al siguiente sondeo y no se descarta ninguna release.

### Colocar los archivos {#placing-the-files}

Una vez revisada una release, el video de cada episodio va en la carpeta de la temporada. Es la carpeta donde están los archivos que ya tiene la temporada. Si una temporada todavía no tiene archivos, se usa la carpeta que indica **Season Folder Format** de Sonarr, por ejemplo `Season 1`. Una serie configurada para no usar carpetas de temporada guarda sus archivos en la carpeta de la serie.

- **Cada episodio tiene su propio video.** El video se busca por el número de episodio en su nombre, también dentro de los archivos comprimidos de la release. Un pack coloca todos los episodios para los que se tomó. Las muestras y los archivos `.nfo` se quedan en `__magic__/__all__`, y una muestra nunca se coloca como si fuera el episodio.
- **Un pack que le falta un episodio se rechaza antes de mover nada.** Se aparta como si fuera un post muerto, y se prueba el siguiente pack o los episodios sueltos.
- **Un episodio suelto cuyo nombre de archivo no indica nada recibe el video más grande de la release.** Los posts ofuscados suelen ser así.
- **El video de un anime o de un programa diario se coloca bajo la serie y el episodio.** Un reescaneo lee un archivo solo por su nombre y no sabe nada de la numeración scene. Por ejemplo, `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` en la carpeta de la serie se importó como S01E08, mientras que el parser de Sonarr lee ese mismo título como S02E08. Por eso el video se coloca como `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv`, que sí se importa bien. Su nombre original se mantiene después del episodio para que Sonarr siga leyendo su calidad y su grupo. Los videos de una serie estándar y de un especial conservan sus nombres, que ya indican el episodio.
- **Una mejora reemplaza solo su propio episodio.** El video antiguo de ese episodio se oculta de la carpeta de la temporada una vez que el nuevo ya está colocado. Los demás episodios de la carpeta no se tocan. Ocultar significa marcarlo como tombstoned, igual que se hace con Radarr.
- **Sonarr reescanea después.** zurg le indica al mount qué carpetas cambiaron y le pide a Sonarr que reescanee la serie.
- **Un episodio que falta no retiene a los demás.** Cuando un episodio no tiene ninguna release que zurg pueda tomar todavía, los episodios que sí encontró se revisan y se colocan igualmente. Sonarr recibe la petición de reescanear esos episodios de inmediato. El que falta se vuelve a buscar en el calendario de reintentos habitual.

Un origen de Sonarr necesita `__magic__` (`magic.enabled`). Sin él, el origen no arranca, y así lo indica en el log y en la página de adquisición.

**Activity** en Sonarr se queda vacío, igual que en Radarr. Los episodios simplemente tienen archivos después del reescaneo que pide zurg. `only_new_items` y `remove_after_grab` no hacen nada en un origen de Sonarr.

## Packs de varias temporadas {#packs-of-several-seasons}

Se puede tomar una temporada de un pack que contiene varias, como `Game.of.Thrones.S01-08.BDRip.1080p` o `Breaking Bad Season 1-5`. Los indexadores archivan ese pack bajo cada temporada que cubre. En el feed de DMM, 72 de los 691 resultados para Breaking Bad temporada 3 eran packs de varias temporadas. Para algunas temporadas, uno de ellos es la única copia que tiene una cuenta.

- **El título dice qué temporadas son.** Se leen `S01-S05`, `S01-05`, `[S01-08]`, `S1-9`, `Seasons 1-8`, `Season 1 to 5`, `Season 1 · 2 · 3`, `Stagioni 01-05` y `Temporadas 1-4`. Un título sin números de temporada, como `Complete Series`, no se toma. Tampoco uno que nombre una sola temporada solo como palabra, como `Season 3 Complete`. Esos nunca se leyeron como packs.
- **Solo se coloca esa temporada.** Un pack tomado para la temporada 4 pone los episodios de la temporada 4 en su carpeta. Los archivos de las otras temporadas se quedan donde la biblioteca los lista. Un pack cuyos archivos no contienen todos los episodios de la temporada se rechaza antes de mover nada, aunque su título diga lo contrario.
- **El tamaño se juzga por episodio.** El tamaño del pack se divide entre las temporadas que menciona y luego entre los episodios de la temporada, y se compara con `max_size_gb`, igual que el mismo encode publicado episodio a episodio. Un pack de 346 GB de ocho temporadas de diez episodios son 4.3 GB por episodio. El remux de 106 GiB de la temporada 2 de I Love Lucy, con 31 episodios, son 3.4 GiB por episodio, y cabe bajo un 40 escrito. Cuando la fuente no listaba los episodios de la temporada, los packs no tienen techo por episodio. Un `max_season_size_gb` que escribas limita además cada temporada que menciona el pack; por defecto no hay ninguno.
- **La calidad sigue yendo primero.** Los packs se clasifican como cualquier otro release: por resolución, y luego por lo que contienen por episodio, tal como los ordena la página de temporada de DMM. Un pack 2160p de una temporada se toma antes que un pack 1080p de ocho. Dentro de una misma resolución, el remux propio de una temporada va antes que un pack de ocho temporadas que es más grande en total pero más pequeño por episodio.
- **Las otras temporadas del show usan el mismo pack.** Una vez que una temporada ha tomado un pack de varias temporadas, las demás temporadas del show intentan ese pack primero, antes que cualquier pack de la misma resolución que encontró su propia búsqueda. Ya está en la cuenta, así que no cuesta nada. Mientras las temporadas de un show eligen entre packs de varias temporadas, lo hacen de una en una, de modo que las temporadas pedidas juntas (una serie de Sonarr, todas sus temporadas en una misma consulta) no elijan cada una una copia distinta del show. Cuando una de ellas ha elegido sin un pack así, porque no había ninguno en la cuenta o el perfil no permitía ninguno, las demás eligen de inmediato. Una temporada pedida una hora después vuelve a buscar desde cero.

## Ver cómo funciona {#watching-it-work}

El enlace **Acquisition** del panel abre `/acquisition/` en el propio puerto de zurg.

Cada fuente tiene una línea con cuántos de sus títulos están listos, en marcha,
en espera, apartados y en cola, junto al número de títulos que zurg trabaja a la
vez, las llamadas que hace a un indexador a la vez y las conexiones de noticias
que sus cuentas `nzb` tienen permitidas. Debajo, cada fuente tiene una tabla con
una fila por título. Una fila muestra el estado, qué está haciendo ahora mismo un
título en marcha (la búsqueda, cuántos resultados se han juzgado y aceptado hasta
ahora, el candidato que se está inspeccionando, la comprobación en los servidores
de noticias, la colocación), sus intentos, la release elegida con la calidad y la
puntuación que le dio la fuente, dónde se colocó y cuándo se intentará el siguiente
intento de un título en espera. Un título del que no queda ninguna release por probar
dice por qué, con los rechazos de la fuente contados por regla: `14 refused by the source's own rules
(title mismatch 7, quality 5, size 2)`. Las releases rechazadas por su resolución sin preguntar a la fuente cuentan dentro de calidad.
La página se actualiza sola cada cinco segundos.
La misma instantánea está en `/acquisition/status.json`, donde ese motivo es el `detail` del título.
Cuando no hay ninguna fuente activada, o la adquisición está configurada pero pausada, la página lo dice y explica por qué.

Cada película a la que se elige una release recibe una línea en el log, para medir dónde se va el tiempo:

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` es lo que devolvió la búsqueda, `local_refusals` los resultados rechazados sin preguntar a la fuente, `radarr_refusals` los que rechazaron las reglas propias de la fuente, `inspected` los NZB leídos, `radarr_calls` las preguntas hechas a la fuente (los NZB leídos más los rechazos de camino hacia ellos, cuando la fuente es Radarr), y el tiempo se cuenta desde el inicio de la búsqueda. Las releases rechazadas sin preguntar se registran una por una solo a nivel debug.

## Comprobar un \*arr que solo usa zurg como cliente de descarga {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

A Sonarr or Radarr pointed at zurg's [SABnzbd](sonarr-radarr.md) or
[qBittorrent](sonarr-radarr-torrents.md) endpoint does its own searching, and does not
need a source here. zurg still wants its API key, because three of its settings
decide whether every import is a free rename or a whole release downloaded
from the debrid account and written to zurg's disk: Remove Completed on a
qBittorrent client, the download folder and the root folders on one volume,
and root folders inside `__magic__`. With the key, zurg turns Remove Completed
on by itself (see [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
and warns about the other two. See
[One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

The easiest way to give zurg the key is the banner on the main dashboard,
described below. Or add it as a source that is switched off:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

A Radarr or Sonarr source with `enabled: false` acquires nothing. zurg never
reads its wanted list and never searches for it. With its `url` and `api_key`
set, and one of the two endpoints on, zurg only reads the \*arr's root folders,
remote path mappings and download clients, at start, every ten minutes and as
soon as the \*arr first calls one of the endpoints. It turns Remove Completed
on for the \*arr's zurg qBittorrent client when it is off, the one change zurg
makes, and reports a layout that makes imports copies. Every source with a URL
and an API key, enabled or not, is checked and corrected the same way. It is
listed on the acquisition page under **Checked, never searched for**, with
what zurg changed, the findings go to the log, and `zurg doctor` shows them as
`imports (<name>)`. `library_path` is not judged for such a source, since
nothing is placed for it. A source added to config.yml by hand is read at
start, so restart zurg after adding one that way.

zurg also notices a Sonarr or Radarr it cannot check. Both send their name in
every request to the endpoints (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), so zurg
records which ones call it and from which address. When one calls and no
source of its kind has a URL and an API key, zurg logs one warning, `zurg
doctor` reports it on its `*arr settings` line, and the main dashboard shows a
banner with a form for its URL and API key. The URL is filled in with a guess:
the address the \*arr calls from, on its default port (8989 for Sonarr, 7878
for Radarr). That address is often a container's own, which zurg may or may
not reach, so change it to whatever URL reaches the \*arr from where zurg
runs. The API key is in the \*arr under Settings, General, Security. zurg
first asks the \*arr for its status with that key, and saves nothing unless it
answers as the app it was named as. It then adds the source above to
config.yml with `enabled: false`, keeping everything else in the file as it
was, and checks it straight away, with no restart. The form shows what zurg
found and changed. The key is written to config.yml and sent to the \*arr, and
nowhere else.

The banner matches by kind, not by address: an \*arr calls zurg from inside
its container, on an address that has nothing to do with the URL zurg reaches
it on, so one Sonarr source with a key silences the banner for every Sonarr.

## Encontrar versiones duplicadas {#finding-duplicate-releases}

Una actualización deja en tu biblioteca el release que reemplazó. Con `magic.allow_delete` desactivado, el borrado que Radarr o Sonarr hacen del archivo viejo solo lo oculta en `__magic__`, así que el release viejo sigue en `__all__` y en su cuenta. Las capturas de más de un indexador, o un season pack junto a episodios sueltos, también dejan varios releases de lo mismo. **Manage > Duplicates** (`/manage/duplicates/`) los muestra, indica cuál está usando Radarr o Sonarr y te deja borrar los demás. Nunca borra nada por sí solo.

**Cuál release está en uso se lee de las rutas, no de los nombres.** Cada archivo que Radarr y Sonarr tienen se identifica por una ruta bajo `__magic__`, y zurg sabe de qué release viene cada ruta, porque el movimiento que puso el archivo ahí la anotó. La vista lee todos los archivos que cada \*arr ha importado, estén o no monitorizados, en su cutoff o no, y rastrea cada uno hasta su release. En Sonarr se rastrea episodio por episodio, así que un season pack del que Sonarr toma tres episodios aparece como en uso para esos tres.

**Qué releases podrían ser copias es una suposición, y así se indica.** Los releases se agrupan con una película, o con una temporada, cuando:

- un archivo del \*arr está en ellos,
- el historial del \*arr dice que importó desde ellos, o que borró un archivo que venía de ellos (una actualización, a mano, o porque faltaba en disco),
- zurg los identificó con el id de IMDb de la película o de la serie, o
- su nombre coincide con el título y el año (un año de diferencia, o el segundo año que usa Radarr para la película, también cuenta) o con la serie y la temporada.

Cada release indica qué criterio lo metió en el grupo. Una temporada solo es un grupo cuando los releases comparten el mismo episodio: sesenta releases de un solo episodio de una misma temporada son sesenta episodios distintos. Un grupo de temporada muestra los episodios que tiene más de un release, qué release tiene cada uno, en cuál está el archivo de Sonarr, y cuántos episodios tiene cada release que ningún otro del grupo tiene. No se elige ningún release como ganador. Los releases que no coinciden con ningún elemento de Radarr o Sonarr están en **Name matches only**, agrupados por sus nombres y ids de IMDb.

**Cada release está como In use, No reference found o Unknown.**

| State | Meaning |
|---|---|
| In use | Un archivo que Radarr o Sonarr tienen ahora mismo está en este release. No se puede seleccionar. |
| No reference found | Se leyeron completos todos los Radarr y Sonarr configurados, y ninguno de sus archivos está en este release. Plex, Jellyfin y otros clientes que leen el montaje no se ven aquí, así que esto no prueba que nadie lo reproduzca. |
| Unknown | zurg no puede saberlo. Todos los releases están como Unknown mientras no se pueda leer un \*arr, mientras la biblioteca sigue cargando, o con `__magic__` desactivado. Un release también es Unknown cuando un archivo del \*arr de la misma película o episodio no se puede rastrear hasta ningún release, o cuando el historial del \*arr muestra que un archivo de este release desapareció del disco y la película o episodio no ha tenido archivo desde entonces. |

**La calidad se muestra en los términos del perfil.** Para un release que usa el \*arr, es la calificación que el propio \*arr le da al archivo. Para uno que importó antes, es la calificación que le dio entonces. Si no, se lee del nombre del release y se indica así. Cada una se ubica dentro del perfil de calidad del elemento, por ejemplo "rank 15 of 17 in 4K or best available (cutoff at 17)".

**Al borrar, primero se vuelve a leer.** Selecciona los releases y elige **Check again and delete**. zurg vuelve a leer los archivos actuales de cada \*arr, y solo entonces ofrece el borrado. Un release que haya pasado a estar en uso desde que se cargó la página se deja fuera, y un release Unknown solo se borra si lo vuelves a marcar en ese diálogo. El borrado en sí es el borrado masivo de la página de gestión, que elimina todas las copias del release de cada cuenta que lo tenga.

**Cuándo lee.** La primera vez que abres la página, lee todos los Radarr y Sonarr de `acquisition.sources`, incluido el historial de importaciones y borrados. Leer el historial de una biblioteca grande puede tardar un minuto. Después, la página muestra qué se leyó por última vez y cuándo, hasta que elijas **Read Radarr and Sonarr again**. Una fuente con `enabled: false` se sigue leyendo: desactivar la adquisición no cambia lo que tiene ese \*arr. La página muestra los contadores de cada fuente: archivos leídos, rastreados hasta un release, en una ruta fuera de su `library_path`, y dentro de `__magic__` pero sin llevar a ningún release. Si ninguno de los archivos de una fuente se rastrea hasta un release, revisa su `library_path`.

El mismo informe está en `/manage/duplicates/report.json`, y `POST /manage/duplicates/check` con `{"hashes": [...]}` vuelve a leer los \*arr y responde el estado de cada release.

## Newznab y Torznab {#newznab-and-torznab}

Una entrada del indexador indica de qué tipo es con `type`. Si no aparece, se entiende que es `newznab`, que es lo que significaban todas las entradas escritas antes de que existiera esto. La consulta es idéntica para ambos; la respuesta no. Un resultado Newznab es un NZB, que se descarga y se guarda en `nzbs/` para el backend de Usenet. Un resultado Torznab es un info hash, que se entrega a una cuenta de debrid. Un resultado Torznab que no trae un magnet ni un atributo `infohash` se omite: zurg nunca descarga un `.torrent`, así que un resultado al que solo se puede llegar de esa forma no es algo que pueda usar.

**Un torrent solo se añade a una cuenta que ya lo tiene.** A todas las cuentas que aceptan adiciones se les ofrece el hash, salvo que una cuenta de Real-Debrid se omite para un nombre de release que rechaza de plano, porque las cachés son independientes y que una cuenta haya purgado un release no dice nada sobre la siguiente. La primera que ya lo tenga se lo queda. Si no lo tiene ninguna, es un candidato fallido normal, así que el recorrido baja en el ranking hasta el siguiente release, que puede ser otro torrent o un NZB.

En TorBox y Debrid-Link, un fallo no añade nada; en AllDebrid y Offcloud, se borra al instante. Real-Debrid y Premiumize sí reciben el torrent añadido y se vigila durante hasta 20 segundos. El contenido en caché está listo en uno o dos segundos. Lo que siga descargándose después de eso se elimina. Así, nunca queda ninguna descarga en marcha en la cuenta. Aun así, un fallo no es del todo gratis: puede contar contra el límite de adiciones de la cuenta. En TorBox, gasta una de las 60 adiciones no cacheadas permitidas por hora.

La cuenta marcada con `watchlist: true` recibe primero la oferta del torrent. Las demás siguen el orden de tu lista `providers:`. Una cuenta marcada con `add_torrents: false` nunca recibe ninguno.

`prefer` decide a qué tipo se recurre primero cuando ambos podrían cumplir un objetivo con la misma resolución. La resolución va primero: un torrent de 2160p que una cuenta ya tiene se toma antes que un NZB de 1080p, sin importar lo que diga `prefer`. `usenet` es el valor por defecto, porque una descarga de Usenet cuesta una descarga, mientras que un torrent gasta una de las plazas de adición de la cuenta. `torrents` lo invierte, y `best` elimina la distinción y toma lo que el ranking ponga primero, es decir, el release más grande dentro de una resolución.

Una película prueba hasta tres torrents por intento. Cada uno cuesta una adición. Hasta 24 de sus NZB se inspeccionan por separado, como describe [choosing a movie's release](#choosing-a-movies-release). Con `usenet`, los NZB de una resolución se prueban antes que sus torrents. Con `torrents`, sus torrents van primero. Con `best`, cada torrent espera su turno en el ranking. Los NZB de una resolución se prueban juntos en el lugar de su mejor opción. Con una fuente Radarr, los NZB de todas las resoluciones se prueban juntos en el lugar del mejor, del más barato al más caro, como explica esa sección. Un pack de temporada prueba tres releases por intento de cualquiera de los dos tipos. Lo mismo ocurre con cada episodio suelto.

La verificación en la que espera una descarga depende de la fuente. Un release de Usenet se consulta en los servidores de noticias, que es la única forma de saber si el post sigue ahí. Una cuenta `torbox_nzb` no tiene servidores de noticias contra los que comprobar; una descarga ahí se verifica según si TorBox consiguió obtener el NZB. Un torrent solo se añadió porque la cuenta indicó que ya tenía el contenido, así que lo que queda por confirmar es que el release llegó a la biblioteca con archivos; eso es lo que pregunta la comprobación, y un release que la cuenta lista vacío se descarta igual que un post muerto.

Una instalación sin cuenta de NZB (`nzb` o `torbox_nzb`) puede seguir ejecutando la adquisición solo con indexadores Torznab. Sus indexadores Newznab no se buscan allí, porque nada en esa instalación puede reproducir un NZB. El log lo indica una vez para cada uno de ellos. Una instalación sin ninguna cuenta que acepte torrents no busca en sus indexadores Torznab, de la misma forma. En cualquiera de los dos casos, un release de un tipo para el que la instalación no tiene dónde ponerlo nunca es un candidato, así que no consume ninguno de los releases que prueba un intento, y una fuente como Radarr nunca le pregunta por él.

### Límites del indexador y claves rechazadas {#indexer-limits-and-refused-keys}

**zurg respeta el límite de DMM en lugar de chocar contra él.** DMM permite a la clave de un patrocinador 20 búsquedas por minuto en todos sus feeds de torrents, así que zurg envía a DMM como máximo una búsqueda cada tres segundos. Una búsqueda que llegue después de ese límite espera su turno, y esperar no es una búsqueda fallida. Una búsqueda cuyo turno llegaría después de que termine el intento de su título, o a más de dos minutos de distancia, no se hace: el título continúa con lo que encontraron los demás indexadores.

**Un indexador que responde 429 o 503 se deja en paz durante el tiempo que pide.** Cada búsqueda, descarga de NZB y comprobación de capacidades espera su `Retry-After`, hasta dos minutos, incluidas las peticiones que ya están esperando su turno. Un indexador que pide más tiempo no recibe peticiones hasta que pase ese tiempo.

**Varios zurg con una misma clave de DMM comparten sus 20 búsquedas.** Cada uno respeta el presupuesto completo, así que dos o tres zurg con la misma clave siguen chocando contra el límite de DMM, y cada rechazo pausa las búsquedas de DMM de ese zurg durante un minuto. Por eso un título puede tardar más en obtener su búsqueda y su descarga.

**Una clave rechazada se deja en paz durante una hora.** Un indexador que responde con el error 100 (clave incorrecta) o 101 (cuenta suspendida, que es lo que responde DMM cuando caduca el patrocinio) no recibe más peticiones durante una hora, ni para búsquedas ni para descargas de NZB. El log lo indica una sola vez, por ejemplo `DMM torrents refused the API key: check dmm_api_key`, y la página de adquisición lo muestra en **Indexers not asked now**. Si cambias una clave en `config.yml`, se vuelve a probar de inmediato. Cualquier otro error afecta solo a esa búsqueda.

## Elegir la versión de una película {#choosing-a-movies-release}

Los candidatos de Usenet de una película se prueban según lo que cuesta confirmarlos, no solo según lo buenos que sean. Un post con un solo video con nombre le cuesta a zurg dos lecturas de artículos y normalmente está completo; un conjunto de archivos de cuarenta volúmenes cuesta una pasada de medición y una lectura en ambos extremos de cada volumen, y alrededor de dos tercios de los conjuntos remux de varios volúmenes de los indexadores ya no están. El conteo de `files` del propio indexador predice la forma, así que los candidatos se ordenan por él: diez archivos o menos, luego hasta treinta, luego más, luego desconocido, y por el número dentro de cada grupo. Entre posts de igual costo, cuando una fuente como Radarr juzga los releases según un perfil propio, un título que nombre WEB-DL o WEBRip va primero, luego Blu-ray, luego el resto, y el post más grande primero dentro de cada grupo. El ranking propio de la fuente no se usa aquí, porque solo se conoce preguntándole a la fuente, y zurg pregunta por un release solo cuando está a punto de inspeccionarlo. Sin fuente, deciden primero el ranking de calidad y luego el tamaño. Cuando ninguna fuente juzga los candidatos, la resolución que pide la configuración `quality` pasa por delante del costo, así que una watchlist configurada en `best` igual obtiene la mejor resolución disponible, con el post más barato primero dentro de ella. Los resultados cuyo título corresponde a una parte de un post dividido (`[1/9] "Movie.part1.rar"`) nunca son candidatos, y de dos posts con el mismo nombre solo se conserva el que tiene menos archivos, porque la biblioteca solo puede tener uno de ellos.

Luego se inspeccionan hasta 24 candidatos: cada NZB se descarga y se lee con el parser propio de zurg. Un post con como máximo dos archivos de contenido, uno de ellos un video con nombre `.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov` o `.ts` de al menos 500 MB, es un post directo; los volúmenes PAR2 y los archivos auxiliares como `.nfo`, `.sfv`, `.srr`, `.nzb`, imágenes, `.txt`, `.url` y `.exe` no cuentan como contenido. El primer post directo se guarda de inmediato. Los posts de archivo se dejan en espera hasta que se agoten los directos visibles, y luego se prueban primero los de menos volúmenes, a través de una compuerta que no deja que más de seis releases de archivo esperen en los servidores de noticias a la vez. Un post que solo tiene datos de reparación y archivos auxiliares nunca se guarda. Los NZB inspeccionados se recuerdan en memoria, así que cuando un release guardado resulta muerto y el título se vuelve a probar, se llega al siguiente candidato sin descargar otra vez los anteriores. Las búsquedas y las descargas de NZB comparten un único límite de solicitudes en curso por indexador, y si un indexador responde `429` o `503`, se le vuelve a consultar tras una pausa, respetando su `Retry-After`. El panel muestra cada paso: la búsqueda, qué candidato se está inspeccionando y qué se guardó. Las series usan el recorrido anterior: los tres releases mejor clasificados que no estén apartados. Cuando la fuente juzga los releases, como hace Sonarr, cada uno se le consulta primero, y un release que rechace no cuenta para los tres. `best_first` cambia el orden de ambos recorridos, como describe la siguiente sección.

## Poner primero lo mejor del perfil {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

Desactivado por defecto. Si lo activas, la primera descarga de una fuente de Radarr o Sonarr sigue el orden de preferencia del perfil de calidad, en lugar de lo que cuesta comprobar cada release. La lista de Plex y Seerr no tienen perfil y no se ven afectadas. La página de adquisición indica cuando está activado.

- **La mejor resolución del perfil va primero.** Cada release se coloca según la resolución que aparece en su título. Su posición es la mejor calidad que el perfil permite en esa resolución. zurg lo lee del perfil que ya tiene y no le pide nada más a Radarr ni a Sonarr. WEB-DL, Blu-ray y remux de una misma resolución comparten posición. Dentro de una posición, una película sigue tomando el release más barato de comprobar. Una serie toma el que `quality` pone primero. Un título que no indica ninguna resolución va al final.
- **El cutoff cuenta como el máximo.** Mientras el perfil permita mejoras, toda calidad igual o superior al cutoff cuenta igual que el cutoff. La pasada de mejora nunca reemplazaría ninguna de ellas. Un perfil que mejora hasta WEB 1080p no gana nada con best first aunque también permita 2160p. Un perfil que no permite mejoras mantiene su orden completo. Su primer archivo es el que se queda.
- **Baja por el perfil si hace falta.** Un release cuyo NZB no se puede descargar o leer se salta. Uno que rechazan los servidores de noticias se aparta, como antes. Se prueba el siguiente release en el orden del perfil. Un intento sigue leyendo como máximo 24 NZB en total, sea cual sea su posición.
- **Va antes que la preferencia Usenet o torrent.** Un torrent que una cuenta ya tiene se toma antes que un NZB que el perfil coloca más abajo. `prefer` sigue decidiendo entre un NZB y un torrent de la misma posición.
- **Un pack de temporada tiene que ser tan bueno como los episodios sueltos.** Si un pack queda por debajo de un episodio suelto de la misma búsqueda, se salta. Entonces los episodios se toman uno a uno. Sonarr hace la misma elección. Solo se compara esa búsqueda. No se busca otra vez un episodio por su cuenta por si existe un release mejor.

Tiene un coste. Lo más alto de un perfil de 2160p son sobre todo sets de remux y Blu-ray de cuarenta volúmenes o más, y no archivos de vídeo sueltos. Un set así tarda más en comprobarse. Es más probable que ya no esté en los servidores de noticias. Además, espera turno en el archive gate. Por eso el primer archivo suele llegar más tarde. Si todos los mejores releases de un título ya no están, cada uno se descarga, se comprueba y se aparta antes de que zurg baje por el perfil. Una temporada tomada como episodios sueltos son varias descargas, donde un pack habría sido una sola. Lo que ahorra es la segunda descarga. Un primer archivo en el cutoff nunca se mejora.

## Qué hace la adquisición con la lista de la fuente {#what-acquiring-does-to-the-sources-own-list}

Una lista de seguimiento de Plex es una lista que alguien ha curado, y es el único registro de que
esa persona quería un título: Plex no guarda historial de las entradas eliminadas. Dos ajustes
deciden qué puede hacer zurg con ella. Ambos se aplican a las fuentes `plex_watchlist`; las fuentes de Seerr y Radarr no tienen ninguna lista en la que zurg escriba, así que ambos no tienen efecto allí.

`remove_after_grab` (por defecto `true`) quita de la lista de seguimiento un título ya adquirido una vez comprobada la release que lo cubre. Eso es lo que la función ha hecho siempre: la lista de seguimiento se lee como una cola de cosas por conseguir, y un título que zurg ya ha conseguido está terminado. Si lo pones en `false`, la lista de seguimiento se queda como lista de seguimiento: una lista duradera para explorar, que zurg satisface en segundo plano sin editarla. Dejar un título en su sitio no cuesta nada al volver a comprobarlo: el comprobante ya lo cubre, así que ningún indexador vuelve a ser consultado por él.

Un título para el que zurg no obtuvo nada se queda en la lista de seguimiento, pase lo que pase con este ajuste. Cuando todas las releases que lo resuelven ya estaban en la biblioteca (tu propia copia o una que trajo otra solicitud), no se descargó ni se añadió nada, y quitarlo solo modificaría tu lista. Esas releases se siguen comprobando, y el título sigue contando como hecho, así que no se vuelve a buscar mientras siga en la lista. Si se quita y se vuelve a añadir, se queda de nuevo. Un show del que zurg obtuvo cualquier temporada o episodio es uno que sí obtuvo, y se va como antes.

`only_new_items` (por defecto `true`) adopta lo que la lista ya contiene la primera vez que se ejecuta una fuente, y solo actúa sobre lo que se añada después. Activar la función debería empezar a vigilar una lista, no pasarse una tarde trabajando con todo lo que hay en ella. Ponlo en `false` si quieres tratar la lista existente como un pendiente acumulado.

Se aplica **una sola vez, en la primera ejecución de una fuente**. Una fuente que ya tiene una cola lleva ejecutándose, y esa cola (no este interruptor) registra lo que ha hecho y lo que no, así que activarlo más tarde nunca elimina un pendiente que ya esté en curso. Un título adoptado sigue adoptado mientras siga en la lista; quitarlo y volver a añadirlo es una solicitud nueva normal.

## Verificar una descarga {#verifying-a-grab}

Un NZB guardado no es un release. Que el indexador responda, que la respuesta se interprete como un NZB y que el archivo llegue a `nzbs/` son datos sobre el indexador, no sobre la publicación. Por eso, cada NZB adquirido se pasa por las cuentas de noticias configuradas antes de que el motor confirme la petición. Los primeros dieciséis artículos y el último de cada archivo de contenido se consultan con `STAT`. El primer artículo de cada archivo, y algunos más si el release tiene pocos archivos, se descarga completo (como máximo sesenta y cuatro), porque un servidor de noticias puede responder `STAT` a un artículo que ya ha retirado. Un artículo al que `STAT` rechaza también se descarga completo antes de darlo por perdido, porque un servidor de noticias también puede rechazar `STAT` a un artículo que sigue sirviendo (NewsDemon lo hizo el 2026-10-21). Como máximo dieciséis de esos artículos por release. Es el mismo recorrido que hace `/api?mode=addfile` para Sonarr y Radarr. Hay tres respuestas posibles, y lo importante es mantenerlas separadas:

- **Artículos perdidos.** La descarga no cuenta. El recibo se reabre, así que el objetivo vuelve a estar buscado, y el release se registra como muerto durante 30 días para que el siguiente intento pase al siguiente candidato, en lugar de quedarse con el que ya está en la biblioteca. Un release de esa lista no es candidato: no se descarga y no gasta uno de los candidatos que prueba un intento. Así, una serie de publicaciones muertas al principio de un ranking se recorre en lugar de dejar todo lo que hay debajo fuera de alcance. Un pack de temporada muerto devuelve toda la temporada a estado de buscada, y los episodios sueltos se toman en su lugar. Un NZB que se guardó por sí mismo se borra del directorio de vigilancia, para que un reinicio no lo cargue y lo compruebe de nuevo antes de que se abra la biblioteca. Uno que ya estaba en el directorio de vigilancia o en la biblioteca, y uno del que importó Sonarr o Radarr, se queda donde está.
- **No se pudo preguntar a las cuentas.** Un pool caído, una cuenta con limitación de velocidad, o el caso habitual de una biblioteca que todavía no ha listado el NZB nuevo. No se estableció nada, así que no se decide nada: la petición se vuelve a mirar a los veinte segundos, luego a los 40 y 80 segundos, y después cada dos minutos. La espera no cuesta ningún intento de reintento. Una comprobación que simplemente se quedó sin tiempo no es este caso: se vuelve a iniciar de inmediato con todo su tiempo, hasta tres veces, antes de esperar. Ese tiempo son cinco minutos, o más para un release con muchos archivos en una cuenta con pocas conexiones. zurg lo calcula a partir de esas dos cosas, de la velocidad más lenta medida en una comprobación y de las seis comprobaciones que ejecuta a la vez, y luego lo duplica. Un release de 90 volúmenes en cuatro conexiones obtiene unos 53 minutos, cuando antes los cinco minutos se agotaban en cada intento hasta que el release se apartaba sin comprobar. Veinte comprobaciones durante dos horas que no establecen nada apartan el release igual que a uno muerto, y el siguiente intento prueba otro. La petición nunca se confirma con un release que nadie pudo comprobar.
- **El release está.** El recibo suelta lo que estaba reteniendo y la confirmación sigue adelante.

La comprobación espera a que zurg termine de averiguar los tamaños exactos de los archivos del release, o a que se rinda con ellos. Es el mismo punto en el que comprueba el endpoint de SABnzbd. Averiguar los tamaños lee el primer artículo de cada archivo, y la comprobación también lo lee, así que ejecutar las dos cosas a la vez solo las ralentizaba. Con una lista de 99 películas, comprobar cada release en cuanto aparecía en la lista hizo que el último archivo llegara a la carpeta de Radarr después de casi nueve minutos. Una comprobación que todavía espera tamaños cuando se le acaba el tiempo se vuelve a iniciar de inmediato, igual que una que se quedó sin tiempo. Un release al que todavía se le calculan los tamaños tras 30 minutos se comprueba igualmente. No se comprueban más de seis releases a la vez, y los demás esperan su turno.

La comprobación solo lee. No mueve cuerpos de artículos a la caché ni registra artículos muertos, así que no puede silenciar un archivo que se reproduce. Cuando la pasada de cálculo de tamaños acaba de descargar el primer artículo de un archivo, la comprobación lee esa copia en lugar de descargarla por segunda vez.

Una instalación sin cuenta de NZB (`nzb` o `torbox_nzb`) no tiene con qué comprobar una descarga NZB. La adquisición sigue funcionando ahí cuando una cuenta de debrid acepta torrents. Cada torrent se comprueba según si llega a la biblioteca con archivos dentro, como describe [Newznab y Torznab](#newznab-and-torznab). También tiene que contener algo que se pueda reproducir: un vídeo, un audio o un archivo comprimido que zurg transmita (RAR, 7z, zip o partes numeradas). Un torrent que solo contiene un programa, una imagen de disco o texto es un fake, que suelen aparecer en las primeras horas después de que se emitan episodios nuevos. Se aparta como una publicación muerta y el siguiente release se prueba de inmediato. Si zurg lo añadió a la cuenta para esta petición, se borra de la cuenta de nuevo. Un torrent que la cuenta ya tenía se queda donde está. Una descarga NZB nunca se confirma sin una cuenta de NZB, porque nada podría comprobarla ni reproducirla. Una que quedó en espera desde antes de que se quitara la última cuenta de NZB se aparta como una publicación muerta, y se prueba el siguiente release.

## Persistencia y recuperación {#persistence-and-recovery}

`data/acquisition.json` guarda los IDs de fuente y de solicitud, los intentos, los plazos de reintento, el trabajo en curso y los recibos de cada adquisición, incluidos los episodios. También registra, por fuente, que se adoptó una primera instantánea, para que `only_new_items` se decida una sola vez y no en cada reinicio.

Los objetivos de medios y las ediciones que coinciden reutilizan recibos entre fuentes. Los nombres de archivo de las versiones también se deduplican frente a la biblioteca y a los NZB guardados. Un recibo además lleva los envíos que todavía esperan una respuesta de un servidor de noticias, y el registro guarda las versiones que ya se dieron por muertas, para que un reinicio a mitad de espera ni dé por confirmado un envío no comprobado ni devuelva una versión muerta al ranking.

Un recibo no se da por bueno para siempre: antes de que un título cuente como disponible, zurg comprueba que lo que lo resolvió sigue ahí. Es decir, el video colocado en una carpeta de Radarr o Sonarr o, en el caso de un título de la lista de deseados de DMM, de la watchlist de Plex o de Seerr, la propia versión en la biblioteca. Si se ha borrado desde entonces, se vuelve a buscar, también cuando el título sigue en la lista y el trabajo terminó. Una versión borrada desde la página de gestión no se vuelve a adquirir.

Cada NZB guardado se escribe en disco de inmediato. Los contadores de intentos y los tiempos de reintento se escriben en el plazo de un minuto, así que un fallo puede perder hasta un minuto de ellos, pero nunca un envío. Las escrituras vacían un archivo temporal, reemplazan el registro y vacían el directorio padre donde se admite. Los NZB escritos antes de un fallo se reutilizan aunque la última escritura del registro no haya terminado. Una vez registrada la adquisición, los reintentos de eliminación en Plex no vuelven a adquirir el título.

Los fallos se reintentan a los 5, 10 y 15 minutos, luego a una hora y luego a seis horas. A partir de ahí, un título espera la mitad del tiempo que lleva fallando, así que las esperas crecen: unos medio día tras un día de fallos, dos días tras cuatro, una semana como máximo, más o menos un cuarto, para que los títulos que fallaron juntos no reintenten juntos. Un intento que agota sus cinco minutos sin encontrar nada también cuenta como fallo. Uno que no encontró nada mientras no se pudo consultar a uno de tus indexadores, porque pidió que lo dejaran en paz hasta un momento a no más de un día de distancia (un `Retry-After`), no cuenta: el título se vuelve a intentar después de ese momento, como mucho otro tanto después, para que una cola de títulos no consulte al indexador todos a la vez. Un indexador en pausa diez minutos implica un intento dentro de veinte. Esto ocurre como máximo tres veces seguidas, y luego el intento cuenta como de costumbre. Un indexador que no indica ningún tiempo, como uno que responde 410 Gone o rechaza su clave, no se espera. Un título que lleva dos semanas fallando, con al menos ocho intentos, queda **parked**: zurg deja de preguntar por él a los indexadores. Sigue en la página de adquisición como parked, con cuánto tiempo lleva fallando y por qué, y el registro lo indica una vez. **Resume** en esa página, para un título o para todos los títulos parked de una fuente, lo vuelve a poner en marcha desde el primer reintento corto. Una fuente que deja de listar un título y vuelve a listarlo ha pedido el título de nuevo, así que también lo reanuda. Un envío que confirman los servidores de noticias reinicia las dos semanas de un título, así que una temporada que aún encuentra episodios nunca queda parked. Tampoco lo queda una mejora, de ninguna fuente: su mejor versión puede llegar meses después y el título sigue listado, así que sus reintentos se mantienen separados como mucho una semana. Tampoco lo que está en tu lista de deseados de DMM, por el mismo motivo: una película que aún no ha salido, o una antigua que nadie ha subido, sigue deseada hasta que se obtenga o la quites. Los contadores y los plazos sobreviven a los reinicios, incluidos los apagados largos.

Una cola que falla para siempre cuesta más de lo que muestra la lista de títulos. En una instalación, miles de títulos de Radarr y Sonarr para los que no se encontró nada, reintentados cada seis horas para siempre, llevaron a un indexador de unas pocas cientos de consultas al día a decenas de miles, y el indexador suspendió la cuenta. La mayoría eran películas sin ninguna versión en Usenet y mejoras para las que todas las versiones que permitía el perfil ya habían sido rechazadas. Las solicitudes abiertas de Seerr siguen vigiladas. Los elementos de Plex salen de la watchlist solo cuando todas las temporadas planificadas están adquiridas *y* comprobadas (un NZB frente a los servidores de noticias o, en una cuenta `torbox_nzb`, según si TorBox lo descargó; un torrent al llegar a la biblioteca con algo que reproducir), solo cuando `remove_after_grab` lo permite, y solo cuando zurg obtuvo algo para ellos. Su respaldo de episodios sueltos sigue limitado a los episodios encontrados en los resultados de los indexadores.

Una fuente no disponible pausa su propio trabajo. Una escritura de estado fallida pausa las nuevas adquisiciones hasta que el guardado tenga éxito. Un registro ilegible o no compatible pausa las adquisiciones y conserva el archivo; repáralo o restáuralo y reinicia zurg. Los demás servicios de zurg siguen funcionando.

El antiguo `data/plex-watchlist.json` se importa una sola vez, con su historial y con los reintentos e intentos que esperan solo la eliminación en Plex intactos. El archivo original se conserva. Ambos registros se incluyen en las copias de seguridad normales sin `--include-caches`. Conserva `data/` y `nzbs/` al reemplazar contenedores.

## Añadir otro adaptador {#adding-another-adapter}

Implementa `acquisition.Source` en su propio paquete:

1. `ID()` identifica la instancia entre reinicios.
2. `List(ctx)` devuelve una instantánea completa de referencias `Item`. Haz que la instantánea falle si hay errores de paginación. Guarda solo metadatos, nunca credenciales ni objetos de usuario completos de la API.
3. `Resolve(ctx, item)` vuelve a validar el item y devuelve objetivos normalizados de película, temporada o episodio. `Gone` cancela el trabajo no deseado. `Follow` mantiene monitorizada una solicitud abierta después de adquirir los objetivos actuales.
4. `Complete(ctx, item)` confirma una adquisición de una sola vez. Debe tolerar llamadas repetidas tras un fallo. Una lista de solo lectura puede usar un no-op. El motor la llama solo cuando todas las descargas asociadas al item han respondido, así que un adaptador nunca tiene que comprobar un release por sí mismo, y no debe tomar el hecho de que lo llamen como prueba de nada más allá de eso.

Un source con un perfil de calidad propio también puede implementar `acquisition.Assessor`, evaluando cada release candidato según sus propias reglas. Los adaptadores de Radarr y Sonarr lo hacen, a través de sus propios analizadores.

Registra su tipo de configuración y su factory en el servicio de adquisición. La cola, la persistencia, los reintentos y el ejecutor no necesitan ninguna rama específica para el source. Trakt, MDBList y Simkl pueden encajar en este contrato, pero todavía no están implementados.
