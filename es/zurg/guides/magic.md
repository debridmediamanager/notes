# `__magic__`, un directorio que puedes organizar {#__magic__-a-directory-you-can-organise}

Cada otro directorio de zurg se calcula. `movies` aplica el filtro de películas. `__all__` contiene todo.
Una carpeta de release contiene lo que reporta la cuenta. El diseño se reconstruye en cada actualización.

`__magic__` es el único directorio con rutas **almacenadas**. Un movimiento reescribe una fila de la tabla. No se mueven bytes y la cuenta de debrid no cambia. Organízalo a mano o deja que Sonarr y Radarr lo usen.

Contiene tres tipos de cosas. `__magic__/__all__` contiene cada release que todavía no se ha colocado, y es la carpeta de la que los clientes de descarga importan; como se calcula, no se puede crear nada en su nivel superior, y los bytes de ningún archivo se pueden escribir sobre un nombre que ya use una carpeta de release (una carpeta de release acepta archivos auxiliares en nombres que no use). Con una clave de patrocinador de DMM, zurg coloca en `__movies__` y `__shows__` todo lo que DMM haya identificado, por título ([más abajo](#__movies__-and-__shows__-sorted-by-title)). Todo lo demás en la raíz de `__magic__` es tuyo:

```
/mnt/zurg/__magic__
├── __all__     <- what nothing has placed yet, where a grab lands
├── __movies__  <- films zurg filed by title
├── __shows__   <- shows zurg filed by title
├── __anime__   <- anime shows, with magic.anime: true
├── anime
├── movies
└── tv          <- your *arr root folders
```

Las rutas de esta página usan el montaje de Linux, `/mnt/zurg`. En macOS es `/Volumes/Zurg` y en Windows `Z:\`, así que `/mnt/zurg/__magic__/tv` es `/Volumes/Zurg/__magic__/tv` o `Z:\__magic__\tv`.

Esa separación es la clave. La carpeta desde la que un cliente *importa* y las carpetas *a las que* importa son hermanas, así que ninguna contiene a la otra: una importación manual apuntada a la carpeta de descargas no recorre tu árbol de biblioteca, y ni Sonarr ni Radarr avisan de esta disposición.

Viene desactivado por defecto. Actívalo con:

```yaml
magic:
  enabled: true
```

y reinicia. Las rutas se deciden al arrancar, así que cambiarlo desde el panel requiere reiniciar antes de que el espacio de nombres responda.

## Para qué sirve {#what-it-is-for}

Un \*arr importa **moviendo** el archivo de la carpeta de descargas a la biblioteca. zurg no tenía dónde recibir ese movimiento, así que el \*arr recurrió a copiar. Y copiar desde un montaje de debrid significa bajar la release entera por la red, que es justo lo que el montaje existe para evitar.

Con `__magic__`, la importación es un renombrado dentro de un mismo espacio de nombres: se escribe una fila, el archivo aparece donde lo puso el \*arr y no se descarga nada. Por eso [el endpoint de SABnzbd](sonarr-radarr.md) merece la pena: es una capa fina encima de esto, y sin ella cada importación sería una descarga completa.

Solo funciona si la **carpeta raíz** del \*arr también está dentro de `__magic__`, por ejemplo `/mnt/zurg/__magic__/tv`, y no en otro directorio de la máquina. Un movimiento cuyo destino está fuera del espacio de nombres es un movimiento entre dos sistemas de archivos, o sea, otra vez una copia. zurg lo rechaza directamente con un `403` en lugar de dejar que ocurra en silencio. El único lugar dentro del espacio de nombres que también se rechaza es la raíz de `__magic__/__all__`, que es la estructura propia de la biblioteca y no un sitio donde poner cosas. [sabnzbd.md](sonarr-radarr.md) tiene los ajustes exactos.

Un archivo colocado fuera de `__all__` sigue apareciendo listado allí, y borrar en `__all__` elimina el archivo de la cuenta. Por eso zurg no deja borrar un archivo a través de `__all__` ni de ninguna otra carpeta de la biblioteca mientras una colocación aquí lo esté usando en streaming. Bórralo en `__magic__`. Así se evita que un \*arr que importa desde `__all__` y luego limpia su carpeta de descargas allí, como uno alimentado por el proxy de SABnzbd de DMM, borre la release que acaba de importar.

Y el \*arr tiene que acceder a la carpeta de descargas y a la carpeta raíz **a través de un mismo montaje**. Si un contenedor recibe `__magic__/__all__` y `__magic__/tv` como dos volúmenes separados, ve dos sistemas de archivos aunque ambos sean de zurg. El kernel rechaza el renombrado dentro del contenedor antes de que zurg se entere, y el \*arr copia el archivo completo. zurg convierte esa copia en una colocación cuando termina de llegar y registra `A client copied …`, pero la descarga ya se ha hecho. Monta un solo directorio con todo el montaje de zurg dentro del contenedor; consulta [Un volumen para la carpeta de descargas y las carpetas raíz](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

Las adquisiciones propias de zurg también colocan archivos aquí. Una fuente de Radarr pone cada release que confirma en la carpeta de la película con el mismo movimiento que hace una importación, y luego pide a Radarr que reescanee: consulta [acquisition.md](acquisition.md#placing-the-file).

zurg también coloca archivos por su cuenta, en `__movies__` y `__shows__`: consulta [más abajo](#__movies__-and-__shows__-sorted-by-title).

Organizar la biblioteca a mano es la otra mitad, y funciona sin ningún \*arr de por medio.

## Sin nada guardado, son los releases de `__all__` como carpetas reales {#with-nothing-stored-it-is-__all__s-releases-as-real-folders}

Abre `__magic__/__all__` en una instalación nueva y verás cada release que hay en `__all__`, como una carpeta por cada uno. La tabla empieza vacía y solo guarda **desviaciones** respecto a ese valor por defecto, así que una biblioteca sin tocar no guarda nada: la raíz de `__magic__` solo contiene el espejo, y los releases nuevos aparecen en él en cuanto aparecen en cualquier otro sitio. Cuando algo coloca un release (la importación de un \*arr o el propio archivado de zurg en `__movies__` y `__shows__`), sale de `__magic__/__all__`: el espejo es lo que todavía nadie ha colocado.

No hay ninguna configuración de directorios detrás: ni `only_show_the_biggest_file`, ni filtros de tamaño. Lo que tiene el release es lo que ves.

La única diferencia con `__all__` es **cómo se ve por dentro una carpeta de release**. En el resto de sitios zurg aplana un release en un solo directorio, con el nombre de archivo como clave y un sufijo cuando dos archivos chocarían:

```
__all__/Show.S01/Show.S01E01.mkv
__all__/Show.S01/Gag Reel (Extras).mkv
```

`__magic__/__all__` muestra el árbol que el release tiene de verdad:

```
__magic__/__all__/Show.S01/Show.S01E01.mkv
__magic__/__all__/Show.S01/Extras/Gag Reel.mkv
```

Esto no es solo estético. Sonarr y Radarr escanean una carpeta de descarga como carpeta: un archivo dentro de una subcarpeta `extras`, `samples`, `featurettes`, `trailers` o `deleted scenes` se omite, y uno en el nivel superior sí se tiene en cuenta. Así, el `Gag Reel (Extras).mkv` aplanado se ofrece para importar, cuando en el árbol real se omite. Y su importación solo recurre al título propio de la descarga para analizar el nombre cuando la carpeta contiene un único vídeo, así que una película aplanada junto a su featurette pierde ese recurso. Como [el endpoint de SABnzbd](sonarr-radarr.md) entrega a un \*arr una carpeta dentro de `__magic__/__all__`, esta es la superficie sobre la que actúan esas reglas.

Dos detalles de la forma:

- **Se elimina una carpeta envolvente única.** Casi todos los releases son una sola carpeta que contiene todo, y esa carpeta es como el release ya se *llama*: los backends de debrid derivan el nombre de ella. Así, `/Show.S01/Season 01/ep1.mkv` se muestra como `Show.S01/Season 01/ep1.mkv`, y no como `Show.S01/Show.S01/Season 01/ep1.mkv`. Solo se quita un nivel, y solo cuando no hay nada al lado: un release con un archivo en la raíz y una carpeta junto a él conserva ambos.
- **Sin sufijos de nombre duplicado.** Existen para que un listado aplanado no sea ambiguo, y un árbol ya tiene directorios para lograrlo.

Todo lo demás de una carpeta de release sigue igual, incluido un archivo: un conjunto RAR se puede seguir explorando como directorio, ahora situado donde estén sus volúmenes en el árbol, y un release servido desde un único archivo aplanado sigue listando el contenido de ese archivo.

`__all__` y los filtros `directories:` siguen siendo planos. Son a lo que debe apuntar un servidor multimedia, y nada de ellos cambia.

## Organizarlo {#organising-it}

A través del montaje, con comandos normales:

+++ Linux
```bash
mkdir -p /mnt/zurg/__magic__/tv/The\ Show/Season\ 01
mv /mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /mnt/zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ macOS
```bash
mkdir -p /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01
mv /Volumes/Zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ Windows
```powershell
New-Item -ItemType Directory -Force "Z:\__magic__\tv\The Show\Season 01"
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Release.S01E01.1080p\ep1.mkv" `
  -Destination "Z:\__magic__\tv\The Show\Season 01\S01E01.mkv"
```
`-LiteralPath` evita que los corchetes que tienen muchos nombres de lanzamiento se interpreten como comodines.
+++

El archivo ahora está en la nueva ruta y ya no está en la anterior. Sigue transmitiéndose desde la misma cuenta de siempre.

Las carpetas de lanzamientos completas también se mueven, como una sola fila:

+++ Linux
```bash
mv /mnt/zurg/__magic__/__all__/Some.Movie.2024.2160p /mnt/zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ macOS
```bash
mv /Volumes/Zurg/__magic__/__all__/Some.Movie.2024.2160p /Volumes/Zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ Windows
```powershell
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Movie.2024.2160p" -Destination "Z:\__magic__\movies\Some Movie (2024)"
```
+++

Los directorios se mueven con todo lo que contienen, como un solo lote. Los movimientos funcionan en ambos sentidos: un archivo se puede mover *dentro* de una carpeta de lanzamiento y también *fuera* de ella, y la carpeta lo muestra junto a las entradas propias del lanzamiento. Esto es lo que necesita un programa que devuelve algo a la carpeta desde la que está importando. Cuando un nombre llega desde dos sitios a la vez, gana el que se movió deliberadamente: lo que moviste tiene prioridad sobre lo que el lanzamiento llama ese nombre, y eso a su vez tiene prioridad sobre un archivo real en `data/local`. El perdedor se oculta en lugar de listarse dos veces.

Hay una situación que falla con el montaje integrado, y solo con el valor por defecto `union_writable: local`: renombrar un directorio *que creaste a través del montaje*, es decir, un `mkdir` seguido más tarde de un `mv` de ese directorio. Con el orden por defecto, `mkdir` crea el directorio en el upstream local de rclone, mientras que las filas que hay debajo hacen que ese mismo directorio exista también en el servidor. Entonces rclone renombra su copia local, mueve las filas una a una (zurg responde correctamente a cada una) y luego falla al eliminar un origen que ya había renombrado:

```
ERROR : __magic__/tv/Saul: Dir.Rename error: RenameDir rmdir: object not found
```

Las filas acaban exactamente donde las pediste: zurg sirve la nueva ruta y responde 404 a la antigua. Pero `mv` termina con código 1, y el montaje sigue mostrando el directorio de origen vacío y no el de destino hasta que se vuelva a leer su listado. Esa eliminación nunca llega a zurg, así que nada de lo que haga zurg puede impedirla. Mover archivos y mover una carpeta de lanzamiento completa funciona con cualquiera de los dos órdenes. Si reorganizas directorios a través del montaje, configura [`union_writable: server`](../reference/config.md#rclone-settings), donde el directorio solo existe en el espacio de nombres y el renombrado es una única operación en el servidor. Medido con rclone 1.71.2.

`rm` oculta cosas: consulta [Deleting hides, it does not destroy](#deleting-hides-it-does-not-destroy).

## `__movies__` y `__shows__`, ordenados por título {#__movies__-and-__shows__-sorted-by-title}

Kodi y Plex deducen qué es un archivo a partir de los nombres de sus carpetas y archivos, y un nombre de release como `Succession.S01.MULTi.1080p.BluRay.REMUX.AVC-DEMS` a menudo les resulta demasiado para leerlo. Cuando apuntaba a nombres de release, Kodi reconoció 8 de 56 series en nuestra prueba. Con una clave de patrocinador de DMM, zurg organiza cada release que DMM ha identificado en dos carpetas, con nombres que los reproductores reconocen de inmediato:

```
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.mkv
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/tvshow.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/Season 01/Detective Conan (1996) - S01E1194 [tmdbid-30983].mkv
```

La misma biblioteca organizada así hizo que Kodi y Plex reconocieran las 70 películas, las 44 series y los 554 episodios.

### Activarlo {#turning-it-on}

Necesitas un nightly de zurg de 2026-10-26 o posterior, `__magic__` activado y tu clave de API de DMM, la que [gatekeeper](https://gatekeeper.debridmediamanager.com/) te muestra una vez que te haces patrocinador:

```yaml
magic:
  enabled: true
dmm_api_key: YOUR_DMM_API_KEY
```

Reinicia zurg. Las dos carpetas se llenan una vez que la biblioteca se ha cargado y DMM la ha identificado, lo cual en una biblioteca grande tarda unos minutos la primera vez; después, un nuevo lanzamiento aparece en menos de un minuto tras ser identificado por DMM. Luego añade una biblioteca **Movies** apuntando a `/mnt/zurg/__magic__/__movies__` y una biblioteca **TV** apuntando a `/mnt/zurg/__magic__/__shows__` (`/Volumes/Zurg/__magic__/...` en macOS, `Z:\__magic__\__movies__` y `Z:\__magic__\__shows__` en Windows), y escanea. En Kodi, pon el scraper de la fuente TV en **The Movie Database**, como viene por defecto, y mantenlo al día: los archivos `tvshow.nfo` necesitan la versión 1.7 o posterior del scraper de series de TMDb de Kodi.

Apunta cada biblioteca a su carpeta, nunca a `__magic__` en sí: eso escanearía también `__all__` y tus otras carpetas, y encontraría todo dos veces.

### Qué hace {#what-it-does}

- **El título es lo que dice DMM**, nunca una regla de carpeta. Una película que vino dentro del pack de una serie se archiva como esa película.
- **Cada versión de una serie va a una sola carpeta**, con temporadas y episodios numerados como los numera TMDB, el orden que Plex usa por defecto. El anime numerado por su emisión se coloca en su temporada: `Detective Conan - 1194` es S01E1194.
- **El id de TMDB está en la carpeta, en cada nombre de archivo y en el `.nfo`**, para que cada reproductor lo encuentre donde lo busca: Plex en la carpeta, Kodi en el `.nfo`, y los reproductores que solo leen nombres de archivo, en el nombre del archivo.
- **Una copia por título.** Cuando dos versiones son el mismo episodio o la misma película, se archiva la mejor, primero por resolución y luego por tamaño; la otra se queda en `__all__`.
- **Los extras y las muestras se quedan en `__all__`**, igual que cualquier cosa que DMM no haya identificado. Una versión se archiva una vez que DMM la identifica.

### Anime en una carpeta propia {#anime-in-a-folder-of-its-own}

Los programas de anime pueden pasar a una tercera carpeta, `__anime__`, para que Kodi y Plex tengan una biblioteca Anime propia, igual que te la daba una segunda Sonarr para anime. Necesitas un nightly de zurg de 2026-11-10 o posterior y una línea más:

```yaml
magic:
  enabled: true
  placement: true
  anime: true
dmm_api_key: YOUR_DMM_API_KEY
```

Reinicia zurg y luego añade una biblioteca **TV** apuntando a `/mnt/zurg/__magic__/__anime__` y escanéala. Lo que cuenta como anime lo decide DMM, usando TMDB: un programa que TMDB marca como animación, en japonés y de Japón, las tres cosas a la vez, o uno al que TMDB le pone la palabra clave *anime*. Detective Conan, Ace of the Diamond y Cyberpunk: Edgerunners van a `__anime__`; Hazbin Hotel (animación de EE. UU.), Alice in Borderland (japonés, acción real) y LINK CLICK (animación china) se quedan en `__shows__`. Las películas se quedan en `__movies__`, incluidas las películas de anime: una biblioteca Movies es de un solo tipo, y esta carpeta también.

Al activarlo, cada programa de anime sale de `__shows__` en unos pocos minutos, y tus usuarios lo verán como programas que salen de una biblioteca y aparecen en otra:

- **Plex** los quita de la biblioteca TV (como ausentes, o los elimina directamente si vacía la papelera tras los escaneos) y los recoge en la biblioteca Anime en su siguiente escaneo. El estado de visto se mantiene: Plex lo asocia al programa, no a la biblioteca, así que un episodio visto en la biblioteca TV aparece como visto en la biblioteca Anime (medido el 2026-11-09).
- **Kodi** asocia el estado de visto a la ruta del archivo, así que exporta tu biblioteca de vídeo (Settings → Media → Library → Export) antes de activarlo e impórtala después de escanear el origen Anime.

Al desactivarlo, los programas vuelven a su sitio de la misma forma.

### Con la lista de deseados de DMM {#with-the-dmm-wanted-list}

Pulsa **Want** en DMM y zurg busca el título ([lista de deseados de DMM](dmm-wanted.md)). Lo que busca se guarda aquí como todo lo demás, así que la película o la serie aparece en Kodi y Plex con su propio nombre, sin necesidad de Sonarr ni Radarr. Un torrent que haya descargado puede tardar hasta una hora en quedar archivado; un NZB se archiva en cuanto DMM lo identifica.

### Con Sonarr y Radarr {#with-sonarr-and-radarr}

Ellos mantienen sus propias bibliotecas. Una versión que Sonarr o Radarr haya capturado a través de zurg se queda en `__all__` para que la importen, desde el momento en que la capturan, y zurg nunca mueve nada que ellos hayan colocado. Si uno de ellos importa un título que zurg ya había archivado, moviéndolo a su propia carpeta raíz, pasa a ser suyo a partir de ese momento y zurg lo deja ahí.

Para que Kodi y Plex coincidan con sus bibliotecas de la misma forma:

- Activa **Settings → Metadata → Kodi (XBMC) / Emby** en cada uno. Así escribirán un `.nfo` con los ids del título junto a cada película y serie, que zurg respeta.
- Pon el id en los nombres de sus carpetas, en **Settings → Media Management**:

  | | Folder format |
  |---|---|
  | Radarr | `{Movie CleanTitle} ({Release Year}) {tmdb-{TmdbId}}` |
  | Sonarr | `{Series TitleYear} {tvdb-{TvdbId}}` |

### Bueno saber {#good-to-know}

- **Borrar algo en un reproductor oculta el archivo**, como cualquier borrado en `__magic__`. Sigue en tu cuenta de debrid, y zurg no lo vuelve a archivar.
- **No se puede mover nada a `__movies__`, `__shows__` ni `__anime__`**: esas carpetas las llena zurg. Sacar algo de ellas, como hace una importación de \*arr, sí funciona.
- **Cuando DMM cambia la identificación de un release**, zurg mueve sus archivos al nombre nuevo.
- **Un archivo que se rompe conserva su sitio** mientras zurg lo repara, para que tu servidor de medios no lo pierda.
- **Sin una clave de patrocinador de DMM no se archiva nada.** Quitar la clave, o desactivar `__magic__`, deja lo que ya se archivó donde está.

## Un movimiento sobrevive a repair, rename y re-listing {#a-move-survives-repair-rename-and-re-listing}

Esta es la parte más importante, porque si se hace mal, vaciaría en silencio una biblioteca organizada.

zurg repara un release roto volviéndolo a añadir a la cuenta. El id del torrent cambia, la clave de acceso cambia y los ids de los archivos cambian. Así que una tabla indexada por cualquiera de ellos perdería todas las ubicaciones la primera vez que un enlace caducara. En su lugar, las filas se indexan por el **hash de contenido** del release y por la **ruta del archivo dentro del release**, y ninguno de los dos cambia con una reparación.

Las consecuencias, todas intencionadas:

- **Una reparación mantiene tu organización.** El release vuelve con un id nuevo y los archivos siguen donde los pusiste.
- **Renombrar un release no mueve nada.** Tanto un cambio de nombre como el sufijo que zurg añade cuando dos releases distintos tendrían el mismo nombre de carpeta cambian el nombre de la carpeta predeterminada de un release. Las ubicaciones no se ven afectadas.
- **Un archivo que desaparece no se olvida.** Si una reparación cambia el conjunto de archivos (lo habitual es que Real-Debrid reempaquete un release en rar), una fila cuyo archivo ya no existe se *conserva pero no se muestra*. Si el archivo vuelve, también vuelve su posición. Las filas en ese estado aparecen en el panel como **dangling**, donde puedes eliminarlas.
- **Borrar un release y volver a añadirlo también mantiene tu organización.** La reinserción de DMM, o borrar y luego volver a añadir el mismo release, recupera el mismo hash. Los archivos vuelven a donde los pusiste, y una carpeta que borraste, como la carpeta de trabajo que un \*arr elimina tras una importación, permanece oculta. Para que el release vuelva a estar en `__magic__/__all__`, búscalo en la página `__magic__` del panel y pulsa **Unhide** en su lápida del release.

Un backend necesita algo más que una coincidencia exacta de ruta. Los nombres de archivo de un post de Usenet se *resuelven* en lugar de venir dados: se recalculan en cada carga y nunca se guardan. Por eso, un post leído por primera vez mientras el servidor de noticias no estaba disponible conserva sus nombres ofuscados hasta que una carga posterior recupera los reales. En esos casos, una fila recurre al índice del archivo dentro del NZB y, después, al nombre base más el tamaño cuando solo un archivo coincide.

## Borrar oculta, no destruye {#deleting-hides-it-does-not-destroy}

`rm` dentro de `__magic__` escribe un **tombstone**: la entrada desaparece de `__magic__`, pero sigue exactamente donde estaba en `__all__`, en cada directorio de filtro y en la cuenta de debrid. No se borra nada.

Eso no es timidez. Es lo que hace que un \*arr sea seguro para apuntarle. Al mejorar la calidad, un \*arr borra el archivo viejo, y al importar borra toda la carpeta del trabajo. Si esos borrados eliminaran contenido, una mejora destruiría el release. Y si un borrado solo quitara la *fila*, el archivo reaparecería en su ubicación por defecto, justo de vuelta en la carpeta de la que importa el \*arr.

Si quieres que un borrado borre de verdad:

```yaml
magic:
  allow_delete: true
```

Entonces, el borrado de un **archivo** también elimina el contenido de la cuenta. Una carpeta de release o un directorio nunca lo hacen, sea cual sea este ajuste: la primera es lo que Sonarr borra después de cada importación.

Una entrada dentro de un archivo es el episodio o la película de la mayoría de los releases de Usenet. No tiene archivo propio. El archivo contiene también todo lo demás del release. Así que borrar una entrada elimina el release entero solo cuando nada bajo `__magic__` usa ninguna parte de él. Ninguno de sus archivos puede seguir colocado en algún sitio. Su carpeta propia debe estar borrada o no tener nada que importar. Ese es el estado en que una mejora deja un episodio de Usenet reemplazado. Hasta que esto se resolvió, el release reemplazado seguía en la biblioteca, y su NZB en `nzbs/`, para siempre.

Un video normal se borra por sí solo. Su release también se va cuando nada bajo `__magic__` usa ninguna parte de él. Las mismas dos reglas deciden esto. Los releases publican más que su video. Un `.nfo`, subtítulos o un póster van junto a él, y nadie los importa. Hasta que esto se resolvió, mantenían el release en la biblioteca después de borrar su único video. Su NZB seguía en `nzbs/` y un release de debrid seguía en la cuenta. Otro episodio del mismo pack mantiene el release mientras esté colocado o siga en la carpeta del release. También lo mantiene una carpeta de release que se movió a otro lugar. Y también un episodio que dejó de leerse pero que quizá aún se pueda reparar. Borrar un sidecar donde fue publicado nunca elimina el release. Borrar el último subtítulo que Sonarr o Radarr importaron junto al video sí lo elimina.

`dav_allow_rename` y la ruta de borrado sin control del propio mount no tienen nada que ver con esto. Esas cubren las rutas que renombran y destruyen lo que tiene la cuenta de debrid; una escritura bajo `__magic__` no llega a ninguna cuenta. `mount_read_only: true` sigue anulando todo, a nivel de kernel.

Deshacer un tombstone es un clic en el dashboard.

Así que una mejora deja el release que reemplazó en tu biblioteca. **Manage > Duplicates** lista esos restos junto al release que el \*arr usa ahora, y borra los que elijas: consulta [buscar releases duplicados](acquisition.md#finding-duplicate-releases).

## Los filtros y `__all__` no se tocan {#filters-and-__all__-are-untouched}

A release que hayas movido sigue en `movies`, sigue en `recent`, sigue en `__all__`, con su nombre original. `__magic__` es una segunda vista de la misma biblioteca, no un traslado.

Esto sorprende a mucha gente, así que conviene decirlo claramente: **mover algo en `__magic__` solo cambia `__magic__`.** Los directorios de filtro se calculan a partir de la release, y la release no ha cambiado.

Para un servidor de medios, apúntalo a **una** de las dos. Una biblioteca de Plex que escanee tanto `shows/` como `__magic__/tv` encontrará cada episodio dos veces. Lo mismo vale para `__movies__`, `__shows__` y `__anime__`: apunta una biblioteca a uno de ellos, nunca a `__magic__` en sí.

## Sidecars: `.nfo`, pósters, subtítulos {#sidecars-nfo-posters-subtitles}

Un \*arr escribe los metadatos junto al video, y Bazarr escribe los subtítulos. Son archivos reales y zurg no tiene dónde ponerlos en una biblioteca de debrid, así que van al disco local, en `data/local/__magic__/`.

Cómo configurar Bazarr, y cómo sus subtítulos llegan a rex, está en [Subtítulos con Bazarr](subtitles.md).

Si usas el montaje integrado de zurg, esto ya pasa y no necesitas hacer nada: el montaje es una unión de `data/local` y del WebDAV de zurg, y rclone envía cada archivo recién creado a la mitad local. zurg ni siquiera llega a ver la escritura. Por eso también pasa la prueba "is this folder writable?" de Sonarr.

Si montas `/dav` tú mismo (tu propio rclone, Infuse, una unidad WebDAV de Windows), zurg acepta el `PUT` y escribe en ese mismo árbol, así que ambas vistas coinciden. Se aplican dos límites:

```yaml
magic:
  sidecar_max_mb: 32       # per file
  sidecar_budget_mb: 2048  # the whole tree
```

Pasarse del primero da `413`, pasarse del segundo da `507`. Ambos limitan lo que escribe *zurg*. Con el valor predeterminado `union_writable: local`, desde aquí no se puede rechazar lo que escribe el upstream local de rclone, aunque el árbol se vuelve a medir antes de cualquier rechazo, así que los archivos que rclone deja allí cuentan contra el presupuesto la próxima vez que se le pida a zurg escribir uno, salvo los que superen `sidecar_max_mb`, que no se cuentan. `union_writable: server` cambia eso: la creación llega a zurg en sí, así que los límites deciden también cada escritura a través del montaje, y cualquier cosa fuera de `__magic__` se rechaza sin más.

Un sidecar también puede ir dentro de una carpeta de release, que es donde un \*arr escribe el `.nfo` de un archivo que importó allí. zurg escribe y renombra uno con cualquier nombre que la release no tenga ya, y rechaza uno que tomaría el nombre del archivo propio de la release. Un `DELETE` de un sidecar lo borra de verdad, y es el único caso en `__magic__` en que borrar no es un tombstone: un tombstone oculta una entrada que la biblioteca sigue teniendo en otro sitio, mientras que los bytes de un sidecar viven en `data/local` y en ningún otro lugar.

## El panel {#the-dashboard}

Una vez cargada la biblioteca, zurg escribe una línea en el log que indica cuántas filas tiene la tabla y cuántas de ellas están huérfanas, para que una biblioteca que ha perdido contenido no mantenga un conjunto creciente de filas que nadie menciona. `/magic/` en el puerto normal de zurg muestra lo que contiene la tabla: cada fila almacenada agrupada por release, qué es cada una y de dónde viene, las huérfanas en su propia sección, y el árbol de sidecars con su tamaño frente al presupuesto. También informa de los tamaños del journal y de los snapshots, y del tamaño de todo `data/local`. Ese es el número que indica si algo está importando copiando, porque con el valor por defecto `union_writable: local` un cliente que copia en lugar de mover deja los bytes ahí, y nada más lo mostraría.

Con `union_writable: server` ese número se queda en cero y es el log el que lo indica: el `PUT` de un cliente que copia se rechaza, así que el árbol que habría llenado nunca se escribe. Rechazar no guarda los bytes: la caché de rclone los conserva y reintenta, pero ya no están en este disco con un nombre que zurg pueda contar. [La guía de qBittorrent](sonarr-radarr-torrents.md) explica la causa, que en todos los casos es un ajuste del lado del cliente: un \*arr solo mueve una importación cuando puede eliminar la descarga después.

Desde ahí puedes restablecer una ubicación (el archivo vuelve a su ubicación por defecto), limpiar una tombstone (la entrada vuelve), eliminar una fila huérfana, purgarlas todas a la vez y borrar un sidecar. Cada acción pide confirmación antes de ejecutarse.

La lista de filas almacenadas muestra las primeras mil filas, y en una biblioteca que organiza un \*arr eso es solo una pequeña parte de la tabla, porque cada importación deja una tombstone. Para llegar a una release, búscala: un nombre de release, una ruta en el mount o un hash muestra cada fila almacenada sobre esa release con sus botones, sin importar lo grande que sea la tabla. La lista de huérfanas usa la misma búsqueda. Una release que la biblioteca ya no tiene no tiene nombre en la tabla, solo su hash y las rutas a las que apuntan sus filas.

Los sidecars que **ya nada explica** se listan aparte del resto y se cuentan: un `.nfo` junto a una release que ha salido de la biblioteca, o dentro de una ubicación que se ha olvidado. Siguen sirviéndose, porque un archivo real es lo último a lo que resuelve una ruta y nada por encima de ellos reclama el nombre. Lo que ha desaparecido es la razón por la que se crearon. zurg nunca borra uno. Un directorio que creaste tú para sidecars, a través del mount y no de zurg, se muestra igual, porque tampoco deja ninguna fila.

Si el endpoint de SABnzbd está activado, la página también lista sus trabajos (id, nombre, categoría, estado y la carpeta entregada al \*arr), que es la forma más rápida de saber por qué Sonarr sigue mostrando algo como descargándose.

## Durabilidad {#durability}

Cada cambio se añade a `data/magic.journal` y se vuelca al disco **antes** de responder a la petición, así que un movimiento que un \*arr cree haber hecho es un movimiento que sobrevive a un fallo. El journal se fusiona en una instantánea `data/magic.json` al arrancar, cuando crece por encima de un umbral y al apagar.

Ninguno de los dos archivos sirve para modificar la tabla. zurg la guarda en memoria y escribe `magic.json` a partir de ella, así que una fila borrada del archivo a mano mientras zurg está en marcha vuelve a aparecer tras el siguiente reinicio. Usa los botones del panel.

Si un corte de luz deja cortada la última línea, esa línea se descarta y se conserva todo lo anterior. Una instantánea escrita con otra versión de esquema se descarta en lugar de adivinarla, y una línea del journal de otra versión detiene la reproducción ahí. Una instantánea o un journal que no se puede leer genera un aviso y una tabla vacía, no un arranque fallido. Y si los archivos de una tabla no se pueden *abrir*, `__magic__` sigue sirviendo en modo solo lectura, como el espejo de `__all__` con el que empieza, y todas las escrituras se rechazan. Las escrituras que llegan durante el apagado se rechazan con `503` en lugar de confirmarse y perderse.

## Códigos de estado {#status-codes}

Útil si manejas el espacio de nombres por WebDAV directamente; el montaje se encarga de todo esto por ti.

| Código | Significado |
|---|---|
| `201` | MOVE, MKCOL o PUT crearon algo |
| `204` | DELETE, o un PUT que reemplazó un sidecar |
| `400` | una ruta que este espacio de nombres no puede almacenar, o una cabecera `Destination` que falta o no se puede leer |
| `403` | un destino fuera de `__magic__` o dentro de `__movies__`, `__shows__` o `__anime__`, una ruta de la que responde la biblioteca, una ruta que pasa por un archivo, el propio `__magic__`, o una tabla de solo lectura |
| `404` | no hay nada ahí (un DELETE de nada igualmente responde `204`), o un MOVE desde un archivo que ya no contiene la entrada |
| `405` | MKCOL donde ya existe algo, o PUT sobre un directorio |
| `409` | falta el padre, directorio no vacío, un destino ocupado con `Overwrite: T`, o un MOVE desde un archivo que no se puede abrir |
| `412` | destino ocupado con `Overwrite: F` |
| `413` / `507` | por encima de `sidecar_max_mb` / `sidecar_budget_mb` |
| `503` | apagándose, o un MOVE cuyo origen no se puede servir en este momento — con un `Retry-After` |

`MOVE` rechaza cualquier destino fuera de `__magic__`: los directorios de filtro siguen siendo de solo lectura.

Un `MOVE` **desde un archivo** también se comprueba contra el propio archivo antes de escribir nada. Una importación es un `MOVE`, y un `MOVE` que tiene éxito es una promesa que nada vuelve a comprobar después; el listado que recorrió el cliente no sirve como prueba: el contenido del archivo ya analizado queda memorizado, así que un release cuyos bytes han desaparecido sigue listando sus episodios. Así que primero se consultan el estado del volumen, el daño en los artículos del release y, cuando esos no dicen nada, el propio archivo, exactamente igual que lo hace un `HEAD` de la misma ruta; y un release en buen estado responde desde la misma memoria que ya construyó su listado. Un origen que nunca se podrá leer da un `409`, uno que no se puede leer en este momento da un `503` con un `Retry-After`, y un nombre que el archivo no contiene sigue dando un `404`. No se registra nada cuando se rechaza.

## Límites que conviene conocer {#limits-worth-knowing}

- **`magic.enabled` necesita un reinicio.** Las rutas se registran al arrancar.
- **Una ubicación por archivo.** Si mueves un archivo otra vez, se vuelve a ubicar; el mismo archivo no puede aparecer en dos rutas.
- **Un archivo dentro de un conjunto rar se puede ubicar** como cualquier otro: la fila guarda el volumen y la ruta dentro de él, así que sobrevive a un re-empaquetado igual que un archivo normal. Eso sí, no se puede crear nada *debajo* de un archivo ubicado: se rechaza cualquier ruta que pase por uno.
- **`serve_strm_files` se ignora en los listados de `__magic__`.** El propósito de ese espacio de nombres es que un \*arr mueva el archivo real fuera de él, y un `.strm` no es un archivo que nada pueda importar. Aun así, un cliente que pida uno por nombre recibirá respuesta.
- **Las rutas se comparan exactamente como llegan.** No hay normalización Unicode ni cambio de mayúsculas y minúsculas, así que si un cliente escribe un nombre de una forma y lo pide de otra, no lo encontrará.

## Ver también {#see-also}

- [sabnzbd.md](sonarr-radarr.md) — conectar Sonarr y Radarr a zurg, que es para lo que se creó `__magic__`
- [DMM wanted list](dmm-wanted.md) — pulsa Want en DMM y zurg lo trae a `__movies__`, `__shows__` o `__anime__`
- [usenet.md](usenet.md) — el backend de NZB donde aterrizan esas descargas
- [config.md](../reference/config.md#__magic__-a-directory-you-can-organise) — cada clave del bloque `magic:`
