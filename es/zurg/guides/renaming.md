# Renombrar lanzamientos y archivos {#renaming-releases-and-files}

El montaje de zurg solo admite escritura de una forma: puedes **renombrar** una carpeta de release o un archivo dentro de una, en cualquier parte de la biblioteca. Viene activado por defecto. No se copia nada, no se descarga nada y la cuenta de debrid no se toca. El nuevo nombre se guarda junto al release y prevalece sobre el nombre que zurg calcularía de otro modo.

Lo que no puedes hacer es **mover** nada. Renombrar y reubicar parecen el mismo gesto en un explorador de archivos, pero zurg los trata como opuestos, por una razón que explica [la última sección](#why-a-move-is-refused-when-a-rename-is-not).

Para un *layout* guardado en lugar de un *nombre* guardado (carpetas que organizas, o un \*arr que importa moviendo archivos), consulta [`__magic__`](magic.md). Esta página trata solo del nombre.

## Renombrar a través del montaje {#renaming-through-the-mount}

Un cambio de nombre en el montaje es un `MOVE` de WebDAV cuyo destino solo difiere del origen en el último segmento de la ruta. rclone convierte un cambio de nombre en el montaje (un `rename(2)` de FUSE, o su equivalente de WinFsp en Windows) exactamente en eso, así que `mv` o `Rename-Item` en el montaje, renombrar en Finder, Explorador u otro gestor de archivos, y un cliente WebDAV llegan todos al mismo manejador.

+++ Linux y macOS

```bash
mv "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show.S01E01.mkv" \
   "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show - s01e01.mkv"
```

En macOS el montaje es `/Volumes/Zurg` a menos que hayas cambiado `mount_path`.

+++ Windows

```powershell
Rename-Item -LiteralPath "Z:\shows\Show.S01.1080p.WEB-DL\Show.S01E01.mkv" -NewName "Show - s01e01.mkv"
```

+++

Funcionan los dos niveles:

| Cambio de nombre | Se guarda como |
|---|---|
| Una carpeta de release | `Torrent.Rename` |
| Un archivo dentro de un release | `File.Rename` |

Los endpoints `/dav/` e `/infuse/` aceptan `MOVE`. `/http/` no: es un navegador de solo lectura y responde `405` fuera de `__magic__`.

### Lo que debe cumplir un nombre {#what-a-name-has-to-satisfy}

Un nombre nuevo se acepta cuando, después de quitar los espacios sobrantes, no está vacío, no contiene `/` ni `\`, es igual a su propio `filepath.Clean` (lo que también rechaza `.` y `..`) y, si es una carpeta de release, no choca con la clave de acceso de un hash *distinto*. El nombre de un archivo tiene que ser único dentro de su propia release.

| Resultado | Estado |
|---|---|
| Renombrado | `201` |
| Nombre vacío, con un separador o un destino que solo nombra una carpeta | `400` |
| El nombre ya está en uso | `412` |
| Origen no encontrado | `404` |
| Dentro de un archivo comprimido, o rechazado (ver abajo) | `403` |

Renombrar un archivo *dentro de un archivo comprimido* no es posible. El contenido interno del archivo se genera a partir del propio archivo, así que no hay dónde escribir un nombre nuevo, y zurg lo rechaza con un `403` que dice que los archivos dentro de un archivo comprimido no se pueden renombrar.

## Renombrar desde el panel y la API {#renaming-from-the-dashboard-and-the-api}

Los mismos dos renombrados son endpoints `POST`, y cada uno tiene un restablecimiento correspondiente que elimina el nombre guardado y devuelve la release a su nombre calculado:

```
POST /manage/{torrentHash}/rename
POST /manage/{torrentHash}/clear-rename
POST /manage/{torrentHash}/files/{fileid}/rename
POST /manage/{torrentHash}/files/{fileid}/clear-rename
```

No hay un equivalente de `clear-rename` a través del montaje. Renombrar de nuevo al nombre original guarda ese nombre; no elimina el override.

### La corrección de temporadas {#the-season-fix}

`GET /torrents/season-fix/plan` y `POST /torrents/season-fix/apply` son un renombrado masivo de archivos que se basa en la propia coincidencia de episodios de Plex, para lanzamientos cuyos archivos están numerados de una forma que nada puede interpretar. El plan es de solo lectura y da un motivo de omisión por archivo. El apply recibe una lista explícita de hashes en lugar de un flag de aplicar-a-todo, así que confirmas lo que revisaste.

## Lo que sobrevive a un renombrado {#what-a-rename-survives}

El nombre guardado vive en el release y se serializa en su `.zurgtorrent`, así que sobrevive a:

- **Una actualización de la biblioteca**, incluida una que reconstruya las entradas de archivo del release a partir del listado del proveedor.
- **Un reinicio.**
- **Una reparación**, que vuelve a añadir el release por hash con un id nuevo.
- **Que el proveedor renombre el torrent por debajo de ti**, lo que hace Real-Debrid.

También se lleva consigo: un `.zurgtorrent` exportado conserva los renombres, así que una [biblioteca local](local-libraries.md) llega con el nombre que tú le pusiste.

Hay una cosa que no sobrevive: `ignore_renames: true`, que es justo el propósito de esa clave. zurg ignora todos los nombres guardados, muestra el calculado y rechaza nuevos renombres a través del montaje. Los renombres no se borran, solo se ignoran, así que al desactivarla de nuevo vuelven.

## Lo que cambia alrededor de un renombrado {#what-a-rename-changes-around-it}

A rename es una vista, pero varias cosas se construyen a partir de esa vista, y se actualizan con ella:

- **El montaje.** Se invalida la caché de directorios de rclone para la ruta vieja y la nueva, así que el cambio aparece sin esperar a que caduque la caché.
- **Archivos `.strm`**, si `save_strm_files` está activado. Los viejos se borran y se vuelven a escribir con el nombre nuevo.
- **Plex y Jellyfin** reciben la petición de volver a revisar el release.
- **El registro de caché en disco.** El `.zurgtorrent` se escribe con el nombre nuevo y se borra el archivo viejo. Ese borrado es importante: si se deja, al reiniciar se cargan los dos, la colisión de hash resuelve de vuelta a la otra copia y el rename se revierte en silencio. Esto fue un bug real, visto el 2026-08-17.
- **Los endpoints de SABnzbd y qBittorrent**, que recalculan en cada consulta la carpeta que informan a Sonarr y Radarr. Así, si haces un rename en mitad de una importación, la ruta desde la que deben importar se mueve con él en lugar de dejarlos colgados.

## Tres trampas {#three-traps}

**Un renombrado puede volver a clasificar una versión en la próxima actualización.** La pertenencia a los directorios se decide ejecutando los filtros de `directories:` sobre el nombre de la versión, y los filtros ven el nombre *renombrado*. El renombrado en sí no vuelve a evaluarlos a propósito —mantiene la versión en los directorios donde ya estaba—, pero la siguiente actualización sí lo hace. Así que si un filtro coincide con algo del nombre y tu nuevo nombre ya no lo contiene, la versión se mueve más tarde a otro directorio, sin que nada en el momento del renombrado haga pensar que vaya a pasar. Renombra con cuidado si tienes filtros que dependan de nombres.

**Cambiar la extensión cambia lo que es el archivo.** Nada impide que `episode.mkv` pase a ser `episode.txt`; solo se rechazan los separadores. Pero la visibilidad se juzga por el nombre que ve el cliente, así que el archivo renombrado puede quedar fuera de `only_show_the_biggest_file`, de la lógica de archivos reproducibles y del escaneo de un servidor multimedia.

**Una URL `.strm` que ya se entregó a otra cosa deja de funcionar.** El token firmado codifica la clave de acceso y el nombre del archivo, así que una URL copiada antes del renombrado no resuelve a nada después y responde con `404`. El árbol `.strm` de zurg se reescribe, pero cualquier cosa que copiara una URL de él no.

## Desactivarlo {#turning-it-off}

| Clave | Valor por defecto | Efecto |
|---|---|---|
| `dav_allow_rename` | `true` | `false` rechaza un `MOVE` en el montaje con `403`, indicando la clave en el cuerpo |
| `ignore_renames` | `false` | `true` ignora todos los renombres guardados, sirve los nombres calculados y rechaza nuevos renombres a través del montaje con `403` |
| `mount_read_only` | `false` | `true` inicia rclone con `--read-only`, así que el kernel rechaza la escritura antes de que zurg la vea |

`dav_allow_rename` afecta al montaje. No controla los endpoints del panel,
y tampoco controla las escrituras bajo `__magic__`, que no llegan a ninguna cuenta de debrid.
El espejo es la única excepción, y no por esta clave: `__magic__/__all__`
y las carpetas de releases que están directamente dentro de ella son la estructura propia de la biblioteca,
así que cualquier escritura dirigida a una de ellas se rechaza independientemente de lo que esté configurado.
Dentro de una carpeta de release todo vuelve a ser normal.
`mount_read_only` lo anula todo, a nivel de kernel, y además es la única forma de frenar un `DELETE` en el montaje. Consulta [config.md](../reference/config.md) para saber por qué eso importa más que el renombrado.

## Por qué se rechaza un movimiento pero no un renombrado {#why-a-move-is-refused-when-a-rename-is-not}

Todos estos se rechazan:

| Intento | Estado |
|---|---|
| Una carpeta de release a otro directorio | `403` |
| Un archivo a otro release | `403` |
| Un archivo a una subcarpeta de su propio release | `400` |
| Un directorio de primer nivel renombrado o movido | `405` |
| Cualquier cosa fuera de `__magic__` | `403` |
| Una escritura en `__magic__/__all__`, o en un nombre directamente dentro de él | `403` |

La regla de fondo es la misma en todos los casos: **un renombrado tiene dónde guardarse, y un movimiento no.**

El nombre de un release es una sola cadena en el propio release, así que escribir uno nuevo es una asignación de campo que cada búsqueda posterior vuelve a leer. Pero un directorio de primer nivel no es una carpeta: es un filtro guardado, y sus miembros se recalculan a partir de la configuración `directories:` en cada actualización. Mover un release "a" `movies` no escribiría nada, porque nada lee una respuesta guardada a esa pregunta; la siguiente actualización recalcularía la pertenencia a partir de los filtros y lo deshar ía. Rechazar es la respuesta honesta. Lo mismo pasa con una subcarpeta dentro de un release, cuya forma viene de la lista de archivos de la propia cuenta.

`__magic__` existe porque la disposición guardada es realmente útil, y resuelve el problema de almacenamiento en lugar de fingir que no existe: un movimiento dentro de él escribe una fila en una tabla pequeña indexada por hash del contenido, por eso sobrevive a una reparación que vuelve a añadir el release con un id nuevo. Esa tabla está limitada a ese único espacio de nombres a propósito.

Hay una segunda razón para no ampliar la superficie de rechazos a la ligera. [rclone-move-refusal.md](../internals/rclone-move-refusal.md) documenta lo que un `MOVE` rechazado hace a un cliente que no lo esperaba: con rclone 1.72.0, la entrada del VFS se queda apuntando al destino intentado, y un cliente que recurre a copiar y luego borrar recibe EOF y reporta éxito, creando un archivo de cero bytes que cree haber escrito. Cada rechazo de arriba es un rechazo que algo tiene que sobrevivir.
