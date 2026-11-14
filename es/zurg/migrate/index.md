# Migrar a zurg {#migrating-to-zurg}

Lee primero esta página. Se aplica a todas las migraciones y es la mayor parte de lo que necesitas. Las páginas de cada servidor son breves porque esta lleva la parte común.

## La versión corta {#the-short-version}

**zurg publica todos los archivos multimedia que publica el servidor que vas a dejar, y más.** Eso se midió el 2026-09-01. Los mismos cinco lanzamientos se cargaron en los cinco servidores y los montajes se leyeron con `tree`. Aquí tienes [la comparativa completa](https://github.com/debridmediamanager/usenet-streaming-benchmark).
Lo único que zurg publica *menos* es la paridad par2. Plex nunca la convierte en un elemento de la biblioteca.

Así que **no vas a perder contenido.** Parte de él llega con un nombre de archivo distinto. Ese es todo el problema del que trata esta página. Plex asocia un elemento de la biblioteca a una ruta de archivo. Un archivo en una ruta nueva es un elemento nuevo.

Lo que cambias no son los archivos. Es la **curación**.

| Se conserva | Se pierde con el elemento antiguo |
|---|---|
| Marcas de visto, contadores de reproducción, posiciones de reanudación | Pertenencia a colecciones |
| Valoraciones de usuario | Entradas de listas de reproducción (guardan ids de elemento) |
| Los archivos en sí | Pósteres, arte y correcciones manuales de coincidencia elegidos |
| | `added_at`. Tu biblioteca se llena en Recently Added |

El estado de visionado se conserva porque `metadata_item_settings` se indexa por cuenta y por GUID `plex://`, no por ruta ni por id de elemento. Se vuelve a asociar cuando el nuevo elemento coincide con el mismo GUID. Si Plex asigna mal el elemento re-añadido, el estado no vuelve. Revisa unos cuantos después del primer escaneo.

Puedes evitar ese cambio por completo, pero tiene un precio. Reescribir `media_parts.file` en la base de datos de Plex para que las filas nunca mueran. O crear un árbol de enlaces simbólicos que reconstruya cada ruta antigua sobre el montaje de zurg. Ambas opciones funcionan. Pero las dos son una cirugía no soportada sobre un esquema no documentado que cambia entre versiones de Plex. Una reescritura a medias es peor que cualquiera de los dos resultados que pretendía evitar.

Estas guías siguen la vía simple y te dicen exactamente lo que cuesta.

## Tu biblioteca acaba en `__magic__` y no en un conjunto de symlinks {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

Cada servidor de esta lista entrega su biblioteca a los \*arrs mediante una granja de
enlaces simbólicos. **zurg no lo hace y no deberías reconstruir uno.** En su lugar tiene
[`__magic__`](../guides/magic.md). Es el único directorio cuyas rutas se *guardan* en lugar de
calcularse. Mover algo dentro de él reescribe una fila en una tabla pequeña. No se mueve ningún
byte. No se copia nada. El release sigue en su sitio, en tu cuenta. Apunta Sonarr y Radarr hacia
allí y ellos organizan y renombran como quieran, sin coste alguno.

Eso no es solo una pieza móvil menos. Es una capa que no puede romperse como se rompía la anterior.
Un enlace simbólico tiene que apuntar a una ruta real. El destino obvio es
`__all__/<release>/<file>`, y esa ruta se *calcula*. Cambia cuando el release se renombra.
Cambia de nuevo cuando dos releases colisionan y zurg añade a uno de ellos el sufijo `{shorthash}`.
Cada uno de esos cambios deja un enlace colgando sin avisar. Una colocación en `__magic__` se
indexa por el hash de contenido del release más la ruta del archivo dentro de él. Por eso sobrevive
a un renombrado. Sobrevive al sufijo `{shorthash}`. Sobrevive a una reparación que vuelve a añadir
el release con un id completamente nuevo.

Así que, sea lo que sea lo que tengas hoy, **las rutas cambian y la biblioteca se vuelve a añadir**.
Esto vale tanto para una biblioteca de \*arr con enlaces simbólicos como para Plex apuntando
directamente al montaje antiguo. Es el compromiso mencionado arriba y es todo el coste de cada
migración aquí.

## Lo que tienes hoy depende de tu plataforma {#what-you-have-today-depends-on-your-platform}

Esto decide si las tablas de renombrado de las páginas siguientes describen tu biblioteca de Plex o solo la fuente de la que se creó. Asegúrate de entenderlo bien antes de leerlas.

### Linux y macOS. Tus \*arrs ya renombraron todo {#linux-and-macos-your-arrs-already-renamed-everything}

La estrategia de symlinks es la configuración documentada para los cuatro servidores aquí y solo existe en estas plataformas. El servidor publica `completed-symlinks/<category>/<release>/<file>.rclonelink`. Luego `rclone mount
--links` convierte cada uno en un symlink real. Después **Sonarr y Radarr importan desde esa granja a una biblioteca en rutas que ellos eligieron.** El mount es el origen y no la biblioteca.

Dos consecuencias.

- **Las rutas que tiene Plex son las del \*arr.** Siempre. Carpeta raíz, luego carpeta de la serie, luego carpeta de la temporada. Ninguna contiene un nombre de release.
- **Los nombres de archivo también son del \*arr si dejaste activado el renombrado.** Eso es "Rename Episodes" y "Rename Movies". Con el renombrado desactivado, son los nombres del servidor de origen, y las tablas de las páginas siguientes describen exactamente lo que ves.

Así que si ejecutas los \*arrs con el renombrado activado, las tablas de renombrado por servidor **no** describen tu biblioteca. Describen lo que el \*arr recibió al momento de importar. Eso sigue importando. Un nombre de archivo de origen mejor significa un parseo mejor, y estás a punto de reimportar.

### Windows. Ninguna capa de symlinks {#windows-no-symlink-layer-at-all}

A una granja de symlinks le hacen falta `rclone mount --links`, y eso no forma parte de una instalación en Windows. El montaje es una letra de unidad a través de WinFsp, y Plex y los \*arrs apuntan directamente a ella. Así que **Plex muestra los nombres de archivo del propio servidor**, y las tablas de renombrado describen exactamente qué cambios vas a ver. La página de [instalación en Windows](../setup/windows.md) explica la letra de unidad y su regla de sesión.

Los comandos de shell de las páginas de cada servidor están escritos para Linux y macOS (en macOS, lee `/mnt/zurg` como `/Volumes/Zurg`). En Windows, lee `/mnt/zurg` como `Z:\`, detén el servidor antiguo como lo hayas iniciado, y crea carpetas y mueve archivos dentro de `__magic__` con los comandos de PowerShell de [la guía de `__magic__`](../guides/magic.md).

### Cómo salir de una biblioteca de symlinks {#coming-off-a-symlink-library}

No estás moviendo una biblioteca. Estás reconstruyendo una. Y `__magic__` le da a los \*arrs exactamente lo que les daba la granja de symlinks, pero sin la granja. Pueden mover y renombrar dentro de ella tan libremente como antes. Cada movimiento es una escritura de fila en lugar de una operación de archivo.

!!!danger Nunca dejes que un \*arr mueva la biblioteca antigua a `__magic__`
Cambiar la carpeta raíz de una serie o película hace que Sonarr o Radarr te ofrezcan **mover** los archivos. Di que no. Un movimiento dentro de `__magic__` es gratis. Un movimiento desde cualquier otro lugar cruza el límite del montaje, y eso es una copia. Lo mismo pasa con un movimiento entre dos volúmenes del mismo montaje. En Docker, dale al \*arr un solo volumen que contenga todo el montaje de zurg. Una copia desde un montaje de streaming baja toda tu biblioteca y consume tu cuota de Usenet o de debrid. Tu biblioteca antigua es un árbol de symlinks, así que lo que se copia es cada destino al que apuntan.
!!!

Mueve cada archivo a su sitio tú mismo. Cada movimiento es un solo rename a través del montaje de zurg. No se copia nada y nada de tu cuenta cambia. El script de abajo lo hace a partir de tu biblioteca antigua de symlinks. La ruta de un link dentro de la carpeta raíz antigua es donde Sonarr o Radarr espera el episodio o la película. Su destino indica cuál es el archivo. Así, cada archivo acaba en la misma ruta dentro de la nueva carpeta raíz que tenía su link en la antigua. La biblioteca antigua solo se lee. Sigue funcionando hasta que cambies el \*arr.

1. **Monta zurg junto al servidor antiguo** tal como lo indica su página. Déjalo listar primero toda la biblioteca.
2. **Activa `__magic__`** tal como lo indica su página. Mantén desactivados los escaneos de Plex y pon en pausa las colas de los \*arr.
3. **Guarda la función `zurg_path` de la página de tu servidor** como `zurg_path.sh` junto al script. Convierte el destino de un link antiguo en el archivo que sirve zurg. Cada servidor organiza sus archivos de forma distinta.
4. **Ejecuta el script** una vez por cada carpeta raíz. Define `OLD`, `NEW` y `LOG` para cada una. Si tienes `sonarr4k` y `radarr4k` junto a la pareja normal, necesitas cuatro ejecuciones.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   Imprime una línea por cada link que deja sin tocar.

   - `NOT IN ZURG` es un link a un archivo que zurg no tiene. Su NZB no se pudo recuperar o su cuenta no está en la configuración de zurg.
   - `FAILED` es un movimiento que zurg rechazó. Si un segundo link apunta a un archivo que el script ya movió, esto aparece después de una línea de `mv` que dice `No such file or directory`. Un archivo solo puede estar en una ruta de `__magic__`. Se queda donde lo puso el primer link.
   - `ALREADY THERE` es una ruta que la nueva carpeta raíz ya tiene. Si vuelves a ejecutar el script, se salta todo lo que colocó antes.

5. **Cambia cada \*arr.** Selecciona todas las series o todas las películas y edítalas juntas. Pon la carpeta raíz nueva bajo `__magic__`. Cuando pregunte si quieres mover los archivos, responde **No, I'll Move the Files Myself**. El script ya los ha puesto allí. Luego ejecuta **Update All** para que los encuentre.
6. **Apunta Plex a las nuevas carpetas raíz y a nada más.** El siguiente aviso explica por qué.

Cada movimiento tardó unos 15 milisegundos en una biblioteca de prueba y no se copió nada. Vigila `data/local` en el panel `/magic/` de zurg mientras corre el script. Solo crece por los subtítulos y otros archivos pequeños que copia el script. Si un número crece en gigabytes, algo se está copiando. Detente y revisa.

Los links antiguos siguen funcionando. Un archivo movido sigue apareciendo en su ruta antigua de `__all__` además de en la nueva. Las versiones anteriores a la nightly del 2026.10.04 lo ocultaban en la ruta antigua hasta 12 horas, aunque zurg seguía sirviéndolo allí. En una de esas versiones, reinicia zurg una vez cuando termine el script. Mantén a Plex lejos de las carpetas antiguas y de `__all__` hasta que lo hayas hecho.

El lado de zurg de esto se midió el 2026-10-03. La parte de los \*arr es su edición normal de carpeta raíz y no se probó para esta guía. Haz primero una sola serie.

!!!warning Apunta cada biblioteca de Plex a un solo directorio, no a dos
Una biblioteca que escanea un directorio de filtro como `movies`, `shows` o `__all__` **y** escanea `__magic__` encuentra cada episodio dos veces. Además, `__magic__` tiene su propio `__all__`, así que apuntar una biblioteca a la raíz del espacio de nombres escanea toda la biblioteca además de lo que organizaste. Elige uno. Si usas los \*arr, apunta Plex a las carpetas raíz que creaste, `__magic__/tv` y `__magic__/movies`. Si navegas una biblioteca que nadie organiza, elige los directorios de filtro y deja `__magic__` fuera.
!!!

## La única protección que no debes saltarte {#the-one-guard-you-must-not-skip}

**`autoEmptyTrash` tiene que estar en `0` antes de tocar nada.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

En Windows, en PowerShell:

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex muestra el ajuste como `0` o `false` cuando está desactivado.

Plex borra de forma suave. Con `0`, un elemento cuyo archivo ya no existe se queda en la papelera y vuelve si el archivo reaparece. Con `1` se elimina para siempre en cuanto un escaneo lo detecta. Un montaje que falla durante diez segundos en mitad de un escaneo se lleva la biblioteca entera. Esto ya ha costado decenas de miles de elementos antes.

En estas guías simplificadas, este ajuste hace más trabajo que antes, no menos. **La papelera es donde esperan tus elementos antiguos mientras compruebas los nuevos.** Vacíala cuando estés satisfecho, y no antes. Ese es el paso que hace la pérdida real, y es lo único irreversible de todas estas guías.

Mientras estás ahí, desactiva **"Generate video preview thumbnails"** en las bibliotecas afectadas. En un montaje de streaming, cada pasada de miniaturas es una lectura completa de la release, y se come tu cupo de Usenet o debrid. Una migración le da a Plex muchos elementos nuevos de golpe.

## Lo que gana cualquier migración {#what-every-migration-gains}

Dos de estos son archivos nuevos que aparecen en carpetas que Plex ya escanea. Conviene saberlo antes de que te sorprendan.

- **Clips de muestra.** zurg es el único de los cinco que publica el archivo de muestra dentro del directorio `Sample/` de un lanzamiento RAR. Plex puede tomar un `-sample.mp4` de 9 MB como un extra o como una segunda versión del episodio. Si no quieres que pase, configura [`only_show_the_biggest_file: true`](../reference/config.md) en los directorios que escanean tus bibliotecas multimedia.
- **Archivos `.nfo`.** zurg es el único que los conserva. No tienen efecto con los agentes predeterminados de Plex. El agente XBMC y NFO sí los lee si lo usas.
- **`thumbnail.jpg` y archivos `.url` de publicidad.** No tienen efecto. `thumbnail.jpg` no es un nombre de archivo que Plex use para los pósters, y los archivos `.url` son la publicidad del póster.
- **Carpetas vacías** en los casos en que la cadena de archivos de un lanzamiento se rompe. Plex ignora los directorios que no tienen contenido multimedia.
- **Los par2 y sfv desaparecen.** zurg los oculta leyendo qué es realmente el archivo en lugar de cómo se llama. Plex nunca los catalogó, así que no se nota en tu biblioteca. Solo importa para las herramientas que los recorrían.

## Las guías {#the-guides}

- [Desde AltMount](altmount.md). Solo renombra las versiones en archivo
- [Desde decypharr](decypharr.md). Renombra versiones de un solo archivo y en archivo
- [Desde InfiniDysk](infinidysk.md). Renombra versiones de un solo archivo y en archivo
- [Desde nzbdav](nzbdav.md). No renombra nada y es el más fácil de los cinco
- [Desde streamnzb](streamnzb.md). No hay biblioteca que migrar. zurg tiene su propio addon de Stremio

¿Te vas de Plex en lugar de pasarte a zurg? [Muévete de Plex a rex](../../rex/from-plex.md) mantiene zurg y tus apps de Plex, y ejecuta rex junto a tu servidor de Plex o en su lugar.

El comportamiento de nombrado de cada página se midió el 2026-09-01 con un corpus de cinco versiones.
Las compilaciones fueron zurg `bda7e3c3`, AltMount `0614008b`, InfiniDysk `cd9b1205`, nzbdav `794948be` y decypharr `0dd1cbbd`. Una compilación anterior o posterior a esas puede nombrar las cosas de otra forma. Revisa unas cuantas versiones contra tu propio árbol antes de fiarte de una lista de escaneo completa.
