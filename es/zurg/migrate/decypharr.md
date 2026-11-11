# Migrar de decypharr a zurg {#migrating-from-decypharr-to-zurg}

Lee primero [la página compartida](index.md). Explica el trash guard y por qué tu biblioteca acaba en `__magic__`.

decypharr y zurg resuelven el mismo problema y sus estructuras raíz son parecidas. Gran parte de la configuración se puede reutilizar.

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | una entrada `directories:` con `not_provider: nzb` |
| `nzbs/<job>/` | una entrada `directories:` con `provider: nzb` o el `__nzb__` integrado |

El **lado de debrid no necesita nada**. Ambos servidores listan las mismas cuentas
y presentan los nombres de archivo originales del torrent. Esas rutas son idénticas una vez que zurg está en el punto de montaje de decypharr. Todo lo que sigue trata sobre el lado de Usenet.

Hay dos cosas que conviene aclarar antes de empezar.

- **Proveedores.** No limitan la migración. zurg tiene un backend para
  cada servicio que soporta decypharr. Las cuentas de Premiumize y Debrid-Link se migran igual que el resto. Cada uno tiene una página en [Proveedores](../providers/index.md).
- **No cambies el `folder_naming` de decypharr antes de migrar.** Renombra
  todas las carpetas de la biblioteca de una vez. Eso rompe de golpe todos los destinos de symlink y todas las rutas de Plex en mount-direct.

## Qué cambia en el lado de Usenet {#what-differs-on-the-usenet-side}

Medido contra zurg con los mismos cinco lanzamientos.

| | |
|---|---|
| zurg añade | `thumbnail.jpg`, el clip de muestra, el `.nfo`, los anuncios `.url`, el directorio interno del archivo, **y el lanzamiento ofuscado que decypharr descartó** |
| zurg no pierde | nada |
| renombrados | lanzamientos de un solo archivo y lanzamientos en archivo |

**Los lanzamientos de un solo archivo** salen de decypharr con el nombre del trabajo. Obtienes `ToyStory5/ToyStory5.mkv`, donde zurg conserva el nombre que le puso el publicador y sirve `ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`.

**Los lanzamientos en archivo** son el caso interesante y vale la pena entenderlo, porque explica dos síntomas a la vez. decypharr produce esto.

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

Eso es el nombre del directorio interno del archivo y el nombre del propio fichero concatenados **sin ningún separador**. Es una unión de rutas que perdió su `/`. Así que el nivel de directorio que falta y el nombre de fichero mal formado son el mismo defecto, no dos. zurg reproduce la estructura real en `FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`.

**Los lanzamientos de varios archivos y los packs de temporada conservan sus nombres de archivo reales en ambos lados.** Coinciden automáticamente en cuanto coincide el nombre de la carpeta.

## Cómo queda tu biblioteca después {#what-your-library-looks-like-afterwards}

**Todo se vuelve a añadir** porque la raíz de la biblioteca pasa a `__magic__`. Mira [la página compartida](index.md) para saber por qué no hay una forma más barata.

La ganancia está en los nombres. Cada release de un solo archivo vuelve con el nombre de archivo del que lo subió, en lugar del nombre del trabajo. Así, `ToyStory5/ToyStory5.mkv` pasa a ser `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`. Es la cadena que Sonarr, Radarr y Plex leen para la calidad, la fuente, el grupo y la edición. Los releases de archivo dejan de llevar un nombre pegado y pasan a estar en el propio directorio del archivo. Los releases de varios archivos y los packs de temporada ya se leen bien y no cambian.

Enumera los releases cuyos nombres cambian.

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
done
```

!!!info Si lo ves o no depende de tu configuración
Si Plex lee el montaje directamente, los nombres de arriba son los que cambian en tu biblioteca. Eso incluye todas las configuraciones de Windows y cualquier configuración de Linux o macOS sin una granja de enlaces simbólicos de \*arr.

Si Sonarr y Radarr organizan una biblioteca de enlaces simbólicos con el renombrado activado, **tus nombres de archivo ya son los suyos** y ninguno de los nombres de arriba aparece en Plex. Lo que te dicen los nombres en ese caso es lo buena que fue la lectura que hizo \*arr. Eso importa cuando vuelves a importar. Mira [la página compartida](index.md).
!!!

## Qué contenido nuevo aparece {#what-new-content-shows-up}

- **Clips de muestra** dentro de `Sample/`. Este es el único que vale la pena configurar. Pon
  [`only_show_the_biggest_file: true`](../reference/config.md) si no quieres que un clip de 9 MB aparezca como una segunda versión.
- `thumbnail.jpg`, el `.nfo` y los `.url` del póster con publicidad. Todos son inofensivos.
- **Releases ofuscados que decypharr dejó caer** y que llegan como nuevos elementos de la biblioteca. decypharr no publicó nada en absoluto para un post con nombre completamente hash. zurg lo resuelve al nombre real del release y lo sirve.
- Carpetas vacías donde una cadena de archivos está rota.

## Recupera tus NZB {#get-your-nzbs-back}

**decypharr no puede dártelos.** Guarda un binario comprimido por trabajo
en `usenet/meta/<uuid>.meta` y un directorio `usenet/nzbs/` que estaba vacío en
la prueba. No hay ninguna exportación documentada. No está verificado si los blobs `.meta` se pueden decodificar de nuevo a NZB. Considera los originales como irrecuperables.

Lo que sí tienes son los nombres de los trabajos. En ambos servidores, el nombre de la carpeta del trabajo *es* el nombre del archivo NZB. Así que la lista de carpetas es tu lista de compras.

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

Para cada trabajo, vuelve a descargar el NZB desde tu indexador buscando el nombre de la carpeta.
Luego **renombra el archivo exactamente con ese nombre más `.nzb`** antes de meterlo en el directorio `nzbs/` de zurg. El nombre del archivo es el nombre de la carpeta, y el nombre de la carpeta es lo que mantiene estable la ruta.

Dos reglas mientras lo haces.

- **Omite cualquier release que una cuenta de debrid ya tenga.** El symlink se resuelve a través de la copia torrent. Si añades también el NZB, zurg verá dos releases distintos con el mismo nombre y le añadirá un sufijo hash a uno de ellos como `Some.Release {a1b2c3}`. Eso rompe lo que apuntaba al nombre sin sufijo.
- Un release que tu indexador ya no tiene simplemente se pierde. Con `autoEmptyTrash` en `0`, el elemento de Plex sobrevive en la papelera hasta que decidas eliminarlo.

## Monta zurg en paralelo {#build-zurg-alongside}

Ejecuta zurg junto a decypharr en su propio punto de montaje. Ambos pueden listar las mismas cuentas de debrid a la vez, porque listar es solo de lectura.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30                # your plan's real allowance
retain_rd_torrent_name: false        # align with decypharr's folder_naming
retain_folder_name_extension: false  # true if your folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                         # optional: mirror decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

Luego comprueba que el lado de debrid coincida antes de seguir.

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

A veces las carpetas de torrents difieren *de forma sistemática*. Una extensión aparece o no aparece. El nombre renombrado de RD aparece en lugar del original. En ese caso, cambia `retain_rd_torrent_name` o `retain_folder_name_extension` y vuelve a escanear en lugar de corregir nada a mano. Las carpetas que solo están en el lado de decypharr son los trabajos de Usenet. Los nombres de carpeta de Premiumize y Debrid-Link no se compararon con los de decypharr. Revisa también las carpetas de esas cuentas aquí.

## Cambia a zurg {#cut-over}

Un solo camino, sea lo que sea que tengas hoy. Aquí no se mueve ningún byte.

**1. Activa `__magic__`** y reinicia. Las rutas se registran al arrancar, así que un interruptor del panel necesita un reinicio antes de que el namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crea las carpetas raíz.** Van en la raíz de `__magic__`, junto a la `__all__` que zurg mantiene ahí. No en `__magic__/__all__`, ni en `__magic__` en sí, ni en la raíz del montaje. Los dos \*arrs muestran un health check por esas ubicaciones; las carpetas hermanas no activan ninguno.

En Docker, los \*arrs tienen que llegar a `__all__` y a estas carpetas raíz a través de un solo volumen. Las configuraciones de decypharr suelen montar por separado una carpeta de descargas y una carpeta de medios. Dos volúmenes convierten cada importación en una copia completa. Monta una vez el padre del montaje de zurg. La [guía](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) lo muestra paso a paso.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` refleja la biblioteca, así que cada release está presente antes de que organices nada.

**3. Organízalo.** Un `mv` dentro de `__magic__` escribe una fila y no mueve ningún byte.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Si Sonarr y Radarr organizaron tu biblioteca antigua, muévela con un solo script.** Renombra cada archivo al que enlaza la biblioteca antigua dentro de una carpeta raíz nueva bajo `__magic__`. Cada uno acaba en la ruta que el \*arr ya espera. No se copia nada. Después cambias la carpeta raíz del \*arr sin dejar que mueva nada. Los pasos y el script están en [la página compartida](index.md#coming-off-a-symlink-library). Nunca dejes que un \*arr mueva los archivos por su cuenta. Eso cruza la frontera del montaje. Es una copia y vuelve a descargar tu biblioteca.

El script necesita una función `zurg_path` para los enlaces de decypharr. Guárdala como `zurg_path.sh` junto a él y pon `OLDMOUNT` en la ruta donde está montado decypharr.

```bash
OLDMOUNT=/mnt/decypharr         # decypharr's mount, where the old links point
zurg_path() {
  local rel=${1#"$OLDMOUNT"/__all__/}
  [ "$rel" = "$1" ] && return   # not a link into decypharr
  local job=${rel%%/*} name=${1##*/} f videos
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # decypharr welded an archive's inner folder and file into one name.
  for f in "$ZURG/__all__/$job"/*/*; do
    [ "$(basename "$(dirname "$f")")$(basename "$f")" = "$name" ] && { echo "$f"; return; }
  done
  # decypharr named a lone video after the job. Take the job's one video.
  case "$name" in "$job".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$job" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Un enlace a un release de debrid o a un release NZB de varios archivos apunta al mismo archivo en ambos servidores. decypharr renombró dos tipos de releases NZB. Puso a un vídeo suelto el nombre del trabajo y pegó en un solo nombre la carpeta y el archivo de un comprimido. La función encuentra la copia de zurg de los dos casos. Un trabajo con más de un vídeo nunca se adivina. En su lugar imprime `NOT IN ZURG`.

**4. Apunta Plex a las carpetas raíz que creaste** — `__magic__/tv` y `__magic__/movies` — y solo a esas. Nunca a la raíz de `__magic__`, que también contiene toda la biblioteca en `__magic__/__all__`, y nunca a `__magic__` *y* a una carpeta de filtro a la vez, o cada episodio se encontrará dos veces. Confirma que `autoEmptyTrash` es `0`. Añade la nueva ubicación y escanea. Luego elimina la antigua. Esa es la ruta de biblioteca de tu \*arr o el montaje de decypharr si Plex lo leía directamente.

**5. Vacía la papelera** cuando hayas revisado a ojo unos cuantos elementos. El estado de visto vuelve con la coincidencia por GUID. Las colecciones y las portadas elegidas no.

Deja decypharr en marcha hasta entonces. No cuesta nada y es tu plan de vuelta atrás. Tampoco borres su configuración ni sus estados `db/` o `usenet/`. Cuando termines, deténlo.

```bash
sudo systemctl stop decypharr
```

## Después {#afterwards}

**La automatización se mantiene, en ambas mitades.** zurg tiene un [endpoint compatible con SABnzbd](../guides/sonarr-radarr.md) opcional para que Sonarr y Radarr le pasen un NZB, y un [endpoint compatible con qBittorrent](../guides/sonarr-radarr-torrents.md) opcional para que le pasen un magnet o un `.torrent` de una cuenta de debrid. Ambos importan desde `__magic__/__all__` renombrando. Tus opciones:

- **NZBs.** Activa `sabnzbd.enabled` y apunta los \*arr a zurg. zurg comprueba cada envío antes de marcarlo como terminado. Pregunta a los servidores de noticias por el inicio y el final de cada archivo. También descarga el primer artículo de cada archivo. Son hasta sesenta y cuatro, más algunos extra si una release tiene solo unos pocos archivos. Algunos servidores de noticias siguen diciendo que un artículo existe después de que su contenido fue retirado, y solo una descarga lo demuestra. zurg reconstruye una release con artículos perdidos en sus archivos PAR2 cuando puede. Una que no puede reconstruir se reporta como **Failed**. Entonces el \*arr la mete en la lista de bloqueados y busca otra. La comprobación es una muestra, no el post completo. Un post que perdió un tramo que la muestra no alcanzó sigue reportándose como Completed y falla en la lectura que llega al hueco.
- **Torrents.** Activa `qbittorrent.enabled` y añádelo como segundo cliente de descarga. La release de un tracker privado funciona cuando el indexador entrega un archivo `.torrent` en vez de un magnet suelto, porque el archivo usa el hash para buscar directamente en la caché de la cuenta.
- **Añadidos puntuales.** El panel de zurg no tiene botón de añadir. Añade un magnet o un `.torrent` a través del endpoint de qBittorrent con la categoría de un \*arr y llegará a ese \*arr. [Añadir una release a mano](../guides/sonarr-radarr-torrents.md#11-adding-a-release-by-hand) explica cómo. Un magnet añadido desde DMM y un NZB soltado en `nzbs/` aparecen ambos en zurg. Ninguno llega por sí solo a Sonarr o Radarr. La [adquisición](../guides/acquisition.md) propia de zurg también busca peticiones por su cuenta. Vienen de tu watchlist de Plex y de Seerr y los \*arr. Toma NZBs de indexadores Newznab y torrents de indexadores Torznab cuando tu cuenta ya los tiene en caché.
- **Híbrido.** Deja decypharr solo como cliente de descarga de los \*arr, empujando a las mismas cuentas de debrid, con zurg sirviendo el montaje. Ambos listan la misma cuenta, así que zurg recoge lo que añade decypharr. El paso de importación del \*arr necesita remote path mapping hacia el árbol de zurg. Ese árbol y las carpetas raíz deben estar en el mismo volumen. Prueba primero una descarga.
