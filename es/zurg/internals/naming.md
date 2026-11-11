# Nomenclatura de zurg {#zurg-naming}

Casi todos los nombres que muestra zurg se calculan, nunca se guardan. El nombre de la carpeta de un release, el nombre de un archivo dentro de ella y el nombre en disco del registro de caché se derivan del torrent en cada búsqueda. Nada los escribe para leerlos después, porque un nombre guardado es otra cosa más que hay que mantener sincronizada con la biblioteca, y mantenerla sincronizada es justo lo que rompen una reparación o una re-resolución de NZB.

La excepción es un renombrado que pide el operador. Ese sí se guarda, en el propio release, y gana a todas las derivaciones de abajo. La sección 9 tiene las reglas, y la guía de renombrado es la versión para el usuario. Todo lo demás de esta página describe el nombre que tiene un release cuando no hay ningún renombrado configurado.

Esto tiene una consecuencia que conviene decir primero, porque es la fuente de la mayoría de las sorpresas para cualquiera que integre algo con zurg: una carpeta puede cambiar de nombre sin que nada la haya "renombrado". Cambiaron las entradas, así que cambió la salida.

Este archivo recoge las reglas, no los umbrales. Cuando una regla se decide por una heurística, se indica la función que la decide y ahí se para: esas heurísticas están ajustadas con releases reales y cambian, y copiarlas aquí solo crearía otra cosa que mantener sincronizada. Las referencias al código son relativas al paquete.

## 1. El nombre de la carpeta de la release {#1-the-release-folder-name}

`internal/torrent/key.go`, GetKey / GetKey_Original

El nombre de la carpeta dentro de `__all__/`, el nombre del archivo `.zurgtorrent`, la clave por la que pasa cada búsqueda y lo que zurg llama "clave de acceso" son una sola cadena. Se decide en este orden, y gana la primera condición que se cumpla:

  | Condición                                    | Nombre de carpeta           |
  |----------------------------------------------|-----------------------------|
  | `ignore_renames: false`, y Torrent.Rename definido | Torrent.Rename        |
  | `retain_rd_torrent_name: true`               | Name, sin modificar         |
  | `retain_folder_name_extension: true` Y       | Name, sin modificar         |
  |   Name contiene OriginalName                 |                             |
  | en cualquier otro caso — ambas opciones en sus valores por defecto | OriginalName, con `.mp4` y luego `.mkv` recortados |
  |                                              |                             |

`retain_rd_torrent_name` se evalúa primero y anula por completo a `retain_folder_name_extension`. La segunda solo se aplica cuando Name contiene OriginalName como subcadena; si no la contiene, el recorte se aplica igualmente.

El recorte es `strings.TrimSuffix` ejecutado dos veces, lo que equivale a tres reglas en una. Solo se quitan `.mp4` y `.mkv`, así que `.avi`, `.ts`, `.iso` y el resto se mantienen en el nombre de la carpeta. Distingue mayúsculas y minúsculas, así que `Movie.2019.MKV` conserva su `.MKV`. Y los dos recortes se ejecutan en secuencia, no como alternativas, así que `Movie.2019.mkv.mp4` se convierte en `Movie.2019`. Después puede añadirse un sufijo, como se explica en la sección 4. El resultado es un único componente de ruta, y nunca se divide por `/`.

OBSOLETO. `retain_folder_name_extension` y `retain_rd_torrent_name` están obsoletas y se eliminarán. Por ahora su comportamiento no cambia, pero al activar cualquiera de las dos se registra una advertencia al arrancar. Ambas usan Name como clave de la biblioteca, y Name lo reescribe la cuenta por debajo de zurg (sección 2). Los valores por defecto usan lo que declara el propio torrent, que la cuenta no toca. En una instancia que va delante de Sonarr o Radarr (una que tiene un bloque `sabnzbd:` o `qbittorrent:`), los valores por defecto son los únicos correctos, porque una clave de acceso que cambia después de una importación hace que se pierda el lanzamiento. `ignore_renames` no está obsoleta.

## 2. De dónde salen Name y OriginalName {#2-where-name-and-originalname-come-from}

  Real-Debrid   `internal/realdebrid/types.go`
                Name = `filename`, OriginalName = `original_filename`

  TorBox        `internal/torbox/types.go`, wireTorrent.originalName
                Name = `name`. OriginalName = la única carpeta en la que viven
                todos los archivos, cuando hay exactamente una; los archivos en
                la raíz del árbol usan `name` como respaldo, excepto un único
                archivo suelto, cuyo propio nombre se usa.

  AllDebrid     `internal/alldebrid/types.go`, originalName
                Misma regla que TorBox sobre la lista de archivos aplanada,
                usando como respaldo el `filename` del magnet.

  NZB           `internal/nzb/provider.go`
                Name y OriginalName son ambos releaseName, y el Hash del torrent
                es el id de la release. Sección 3.

Como los backends de debrid derivan OriginalName de la carpeta raíz del propio torrent, dos cuentas que tengan el mismo contenido producen el mismo nombre de carpeta.

Lo que significan los dos campos de Real-Debrid, medido el 2026-08-27 con una cuenta de prueba de unos ~84k torrents, muestreando 252 de ellos en solo lectura mediante `GET /torrents/info`: `original_filename` era en todos los casos el nombre que declaraba el torrent (el nombre del pack o de la carpeta), y nunca el nombre de un solo archivo. `filename` no es eso. Se reduce al nombre base de un archivo, y lo hace exactamente cuando se selecciona un solo archivo de un torrent con varios: 90 de los 112 torrents de muestra con esa forma, frente a 0 de los 34 con varios seleccionados pero no todos, y 0 de los 24 con todos seleccionados. En un pack de 221 archivos con un solo episodio seleccionado, `original_filename` decía `Marvel Cinematic Universe MCU Collection 2008-2023 1080p jZQ`, mientras que `filename` decía `Spider-Man.No.Way.Home.2021.1080p.BluRay.x264...-NOGRP.mkv`. Así que por defecto se obtiene el nombre del pack, y `retain_rd_torrent_name: true` da el del archivo individual. Por eso el flag está obsoleto: `filename` sigue el estado de la cuenta, y la clave de acceso no debe hacerlo.

## 3. Nomenclatura de releases NZB {#3-nzb-release-naming}

`internal/nzb/provider.go`, releaseName; `internal/nzb/parse.go`

El id de la release, que también es su Hash, es `hex(sha1(lowercase(nzb filename)))`
— del nombre del archivo y no del contenido, así que volver a guardar un NZB no deja huérfano el torrent creado a partir de él. El nombre de la carpeta es ese FILENAME sin su extensión, salvo que la parte base parezca un hash o se quede en nada al sanitizarla; en ese caso se usa el nombre de los metadatos `<head>` del propio NZB. El nombre de archivo gana porque es el nombre que escribió el indexador, el que guardó el descargador y por el que la automatización busca la release, mientras que los indexadores suelen republicar con un asunto distinto en el bloque de metadatos.

`stemLooksJunk`, `looksLikeHash` y `sanitizeReleaseName` en `internal/nzb/parse.go` resuelven las tres preguntas; trátalas como cajas negras.

## 4. Los tres sufijos del nombre {#4-the-three-name-suffixes}

Hay tres formatos de sufijo. No tienen nada que ver entre sí.

  ` {xxxxxx}`   En la carpeta de un release, cuando dos releases DIFERENTES comparten nombre:
                seis caracteres hexadecimales del propio infohash de ese release. Dentro del grupo, el release AÑADIDO MÁS RECIENTEMENTE conserva el nombre sin etiqueta y todos los demás reciben la etiqueta. Se decide una vez por actualización mediante una pasada que puede ver toda la biblioteca, y se guarda como KeySuffixed, de modo que GetKey sigue siendo una función pura del torrent (`internal/torrent/key.go`, disambiguateNames). Un torrent de RD y un NZB del mismo release son dos releases distintos aquí, ya que el hash de un NZB es un sha1 de su nombre de archivo.

  ` (tag).ext`  En un ARCHIVO cuyo nombre base se repite dentro de un mismo release, ya que zurg aplana el árbol de un torrent en un único directorio. La etiqueta es el directorio que ya distingue los archivos en conflicto (el componente de ruta más superficial que sea distinto en todo el grupo); si no existe, seis caracteres hexadecimales del sha1 de la ruta del archivo. Qué profundidad es válida, y qué puede llevar un componente dentro de un nombre de archivo, lo definen `dupeTags` y `sanitizeTag` en `internal/torrent/dupenames.go`; trátalas como opacas. El grupo incluye todos los archivos del listado, estén seleccionados o no, de modo que un archivo que deja de estar seleccionado sigue resolviendo a la clave con la que se registró. `__magic__` es la única excepción: muestra el árbol real del release sin etiquetas, porque ahí los directorios distinguen los archivos (sección 8).

  `_xxxxxxxx`   En un nombre de archivo EN DISCO cuya entrada contenía algún carácter no ASCII: ocho caracteres hexadecimales del sha256 de esa entrada. Sección 6. Nunca aparece en el montaje.

## 5. Nombres de archivo dentro de una release {#5-file-names-inside-a-release}

`internal/torrent/manager.go`. VisibleName(key, file) es la única autoridad para el nombre que muestra el montaje y el nombre con el que debe coincidir una búsqueda: un File.Rename cuando existe y `ignore_renames` es false; si no, la clave de SelectedFiles, que ya incluye la etiqueta de la sección 4. GetFilename devuelve `filepath.Base(file.Path)` en su lugar, y por eso descarta esa etiqueta. Tanto la visualización como la búsqueda deben pasar por VisibleName; si no, una petición de un nombre con etiqueta no encontrará nada, mientras que N archivos comparten el mismo nombre sin etiqueta.

## 6. Nombres de archivo en disco {#6-on-disk-filenames}

`internal/torrent/utils.go`, sanitizeFilename: opaco, y se aplica SOLO a los archivos que zurg escribe en el host (`data/<name>.zurgtorrent` y el árbol de STRM), nunca a lo que sirve el mount. Es mucho más agresivo que cualquier cosa de arriba: una release cuya carpeta en el mount es `Три богатыря` tiene un archivo de caché cuyo nombre es una serie de guiones bajos más el sufijo `_xxxxxxxx`, que es lo que lo mantiene distinto del siguiente título cirílico. Es otro espacio de nombres y no está pensado para coincidir.

## 7. Contenido de los archivos comprimidos {#7-archive-interiors}

Una release servida desde un RAR, ZIP o 7z muestra el contenido del archivo en lugar de sus volúmenes, y dos reglas cambian cómo se llaman esos elementos.
`stripRedundantRoot` (`internal/universal/rar_streamer.go`) elimina los directorios iniciales que envuelven todo el archivo. `payloadRenames` (`internal/universal/deobfuscate.go`) muestra un único payload ofuscado con el nombre de la RELEASE, y mueve con él cada entrada que comparta su mismo nombre base. Lo que se considera ofuscado lo decide `looksObfuscated` en el mismo archivo, el port de zurg de la prueba de SABnzbd: opaco, junto con las guardas que lo rodean. No se reescribe nada en disco, y `archiveName` también resuelve la forma en que el propio archivo está escrito.

## 8. Nombres de directorio {#8-directory-names}

`internal/torrent/manager.go`, `internal/torrent/provider_directories.go`

Integradas y reservadas:

    __all__          cada release
    __unplayable__   releases sin nada reproducible
    __dump__         torrents volcados
    __downloads__    la vista de descargas
    __magic__        la capa escribible, el único directorio cuya estructura se guarda en lugar de calcularse. Su propio `__all__` refleja la biblioteca: cada release que contiene `__all__`, como el árbol de directorios que describen los valores `File.Path` de sus archivos y no aplanado (`internal/magic/tree.go`). Todo lo que está junto a ese espejo es lo que guardó el usuario. El espejo se calcula, así que no se puede escribir nada en él; `MirrorDirectory` en `internal/magic/resolve.go` lo nombra
    int__all__       índice de hashes interno

`__downloads__` y `__magic__` no son filtros, así que se añaden a mano al listado de la raíz, y `__magic__` aparece solo cuando magic está activado. Cualquier nombre que empiece por `int__` se omite por completo del listado de la raíz.

Por cada cuenta hay una más, `"__" + account name + "__"` — `__realdebrid__`, `__torbox__`, `__nzb__` — construida a partir del bloque providers. También decide de dónde se leen los datos: un archivo abierto bajo `__torbox__` lo sirve TorBox aunque otra cuenta tenga el mismo release y ganaría por el orden de la configuración. Una cuenta cuyo nombre chocara con uno reservado no recibe ninguno, y zurg muestra una advertencia. Todo lo demás en la raíz es una clave del bloque `directories:`, tal cual.

## 9. Renombrados del usuario {#9-user-renames}

`internal/torrent/rename.go`, `internal/torrent/rename_bulk.go`

Un renombrado es una vista, no un cambio en nada de la cuenta de debrid. Se guarda como Torrent.Rename o File.Rename y tiene prioridad sobre todas las derivaciones anteriores, hasta que `ignore_renames: true` hace que zurg lo ignore por completo.

Un renombrado de torrent solo se acepta si el nombre, después de quitar los espacios sobrantes, no está vacío, no contiene `/` ni `\`, es igual a su propio `filepath.Clean` (que también rechaza `.` y `..`) y no choca con una clave de acceso existente que pertenezca a otro hash. Al aplicarlo se reasignan las claves de los mapas de directorios, se escribe el `.zurgtorrent` con el nuevo nombre y se BORRA el que tenía el nombre anterior. Si se queda ahí, al reiniciar se cargan los dos y el renombrado vuelve atrás sin avisar.

La corrección de temporadas (`/torrents/season-fix/plan` y `/apply`) es un renombrado masivo de archivos que se basa en la propia coincidencia de episodios de Plex: plan es de solo lectura y da un motivo de omisión por cada archivo, mientras que apply recibe una lista explícita de hashes en lugar de un indicador de aplicar a todos. El panel controla ambas acciones desde `/season-fix/`, que además es donde se explican para el operador las reglas de asignación y los motivos de omisión.

## 10. Consecuencias para todo lo que se integre con zurg {#10-consequences-for-anything-integrating-with-zurg}

Si estás construyendo una ruta a partir del nombre del torrent (un conjunto de symlinks, una asignación de rutas remotas, un script), así es como suele fallar:

  a. La extensión. Solo se quitan `.mkv` y `.mp4`, distinguiendo mayúsculas de minúsculas. Cualquier otro contenedor conserva su extensión en el nombre de la carpeta.

  b. El renombrado. `Torrent.Rename` tiene prioridad sobre el nombre derivado, y si RD renombra un torrent por su cuenta, `Name` cambia sin que te enteres.

  c. El sufijo hash. Dos publicaciones distintas con el mismo nombre significan que una de ellas lleva ` {a1b2c3}`, y cuál la lleva cambia a medida que se añade contenido.

  d. La etiqueta de archivo duplicado. Un archivo cuyo nombre base se repite dentro de una publicación se sirve como `name (tag).ext`, donde la etiqueta es un componente de directorio o un hash de ruta. `filepath.Base(file.Path)` no lo reproduce.

  e. El renombrado de archivo comprimido. Una carga ofuscada dentro de un archivo comprimido se presenta con el nombre de la publicación, no con el suyo propio.

  f. Los nombres de NZB vienen del FILENAME del `.nzb`, no de nada que esté dentro, a menos que el nombre de archivo sea un hash. Nombra el archivo, nombra la carpeta.

  g. Los nombres de archivo saneados en disco son un espacio de nombres distinto al de los nombres de montaje, y en publicaciones no ASCII no coinciden a propósito.

La forma más robusta de resolver una publicación es por hash y luego preguntarle a zurg cómo se llama. Reconstruir el nombre es adivinar, y cada una de las reglas anteriores es una forma de que la adivinanza salga mal.
