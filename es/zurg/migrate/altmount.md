# Migrar de AltMount a zurg {#migrating-from-altmount-to-zurg}

Lee [la página compartida](index.md) primero. Explica el trash guard y por qué tu biblioteca acaba en `__magic__`.

AltMount sirve el árbol más limpio de los cinco. Exactamente un archivo por release. Sin miniaturas, sin anuncios, sin sample y sin restos. La migración es correspondientemente pequeña porque hay muy poco que pueda dar problemas.

Medido frente a zurg con los mismos cinco releases.

| | |
|---|---|
| zurg añade | el clip de sample, el `.nfo`, `thumbnail.jpg`, los anuncios `.url`, el directorio interno del archivo, **y cada release que AltMount rechazó** |
| zurg pierde | nada |
| renombrado | **solo releases de archivo (RAR)** |

!!!info Solo la ruta de archivo renombra
En tres ejecuciones independientes con la build `0614008b`, los releases de un solo archivo sin comprimir conservaron el nombre de archivo del poster. Eso incluye uno cuyo nombre interno difiere del nombre del NZB y uno totalmente ofuscado. Solo el release que hubo que descomprimir desde un RAR acabó como `<NZB name>.mp4`.

Las builds antiguas de AltMount renombraban más que esto. Revisa tu propio árbol antes de fiarte de la lista de abajo. El único comando de "Cómo queda tu biblioteca después" te lo dice en segundos.
!!!

## El problema más grave es lo que AltMount nunca importó {#the-bigger-issue-is-what-altmount-never-imported}

Pasó 4 veces seguidas y AltMount rechazó un pack de temporada de 10 episodios en todas. Los artículos estaban verificados como presentes en el servidor de noticias antes.

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

La comprobación no es determinista. El mismo release devolvió 196 segmentos sin verificar, luego 93 y luego 76. Además depende del tamaño. Si pones `import.segment_sample_percentage: 1`, se revisa el 1 % de los segmentos, así que un release más grande necesita más STATs para terminar dentro del plazo. Al repetirlo contra un host de noticias *más rápido*, rechazó más, no menos. Esa ejecución perdió tanto el pack de temporada como un remux de 41 GB. La latencia no es la explicación.

Lo que significa para ti en la práctica es esto. **Los releases que AltMount nunca llegó a publicar son los que zurg va a añadir.** Hoy no tienen ningún elemento en Plex, así que no hay nada que conservar ni nada en riesgo. Simplemente aparecen. Si tu biblioteca es más pequeña que tu colección de NZB, este es el motivo.

Si quieres que AltMount siga importando mientras migras, bajar `segment_sample_percentage` es el ajuste que puedes probar. Aquí no se probó.

## Cómo queda tu biblioteca después {#what-your-library-looks-like-afterwards}

**Todo se vuelve a añadir** porque la raíz de la biblioteca pasa a `__magic__`. Mira [la página compartida](index.md) para saber por qué no hay una vía más barata.

Lo que cambia por el camino es poco. Las versiones de un solo archivo sin comprimir conservan el nombre de archivo que les dio AltMount, así que la mayor parte de la biblioteca se ve igual. **Las versiones en archivo comprimido vuelven con el nombre del publicador** y un directorio más abajo. Eso es claramente mejor para un \*arr. El nombre `father.brown.2013.s02e05.hdtv.x264-tla.mp4` contiene la calidad, la fuente y el grupo que `FatherBrown.mp4` descartaba.

Para encontrar las versiones en archivo comprimido, busca una carpeta de montaje cuyo único archivo tenga el mismo nombre que la carpeta.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

!!!info Si ves algo de esto depende de tu configuración
Si Plex lee el montaje directamente, los nombres de arriba son los que cambian en tu biblioteca. Eso incluye cualquier configuración en Windows y cualquier configuración en Linux o macOS que no use una granja de enlaces simbólicos de \*arr.

Si Sonarr y Radarr organizan una biblioteca de enlaces simbólicos con el renombrado activado, **tus nombres de archivo ya son los suyos** y ninguno de los nombres de arriba aparece en Plex. Lo que nos dicen los nombres en ese caso es lo bien que el \*arr estaba analizando los datos. Eso importa al reimportar. Mira [la página compartida](index.md).
!!!

## Qué contenido nuevo aparece {#what-new-content-shows-up}

AltMount no publica nada de esto, así que todo lo de la lista de la página compartida te aplica.

- **Clips de muestra** dentro de `Sample/`. Esta es la única opción que vale la pena configurar. Pon [`only_show_the_biggest_file: true`](../reference/config.md) si no quieres que una muestra de 9 MB aparezca como una segunda versión.
- `thumbnail.jpg`, el `.nfo` y los `.url` del póster con publicidad. Todos son inofensivos.
- **Releases completos que AltMount rechazó** que aparecen como nuevos elementos de la biblioteca.
- Carpetas vacías donde una cadena de archivos comprimidos está rota.

## Saca tus NZB {#get-your-nzbs-out}

AltMount se quedó con la propiedad de cada NZB que le diste. El original se movió a otro sitio y se guardó una copia comprimida en `<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. La relación entre la carpeta del montaje y el `.nzbz` está en los archivos `.meta` que hay dentro de `<config>/metadata/complete/<Release>/`. Son binarios con el magic `AM3`, y la ruta del `.nzbz` aparece ahí como texto plano.

zurg quiere un `.nzb` por release, con el nombre del release y sin subcarpetas, dentro de `nzbs/`. Las subcarpetas se ignoran. El nombre de la carpeta `metadata/complete/<Release>` *es* el nombre de la carpeta del montaje, y ese es exactamente el nombre que debe tener el archivo.

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

En la instalación v0.3.2 que medimos, el `.nzbz` se descomprimía como una copia gzip del NZB importado. El código también trae una ruta zstd-protobuf para estos archivos, así que la comprobación con `zcat` y `grep` no es paranoia. Lo que rechace se pasa por la API. `GET /api/files/export-nzb?path=<virtual path>` regenera un NZB fiel desde el almacén, y `POST /api/files/export-batch` devuelve un ZIP. Los dos necesitan un JWT en lugar de la API key.

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

Toma las rutas virtuales de la vista de archivos de la UI de AltMount o de `/api/files/info` en lugar de adivinar el formato. La descarga se llama `<queueID>-<name>.nzb`. Renómbrala a `<Release>.nzb` para que zurg nombre bien la carpeta.

Una comprobación de cordura: el número de `.nzb` recuperados debería ser igual al número de carpetas de `metadata/complete/*/`.

(Una traducción anterior fue rechazada: los fragmentos de código no coinciden. Mantén la estructura exactamente.)

## Monta zurg en paralelo {#build-zurg-alongside}

AltMount sigue sirviendo todo el tiempo. Ejecuta zurg en el puerto 9999. No hay conflicto con el 8585 de AltMount.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

Espera ver **más** carpetas aquí que en AltMount. Son las importaciones rechazadas que ahora aparecen.

## Cambia a zurg {#cut-over}

Un solo camino, sea cual sea tu configuración actual. Aquí no se mueve ningún byte.

**1. Activa `__magic__`** y reinicia. Las rutas se registran al arrancar, así que un interruptor en el panel necesita un reinicio antes de que el namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crea las carpetas raíz.** Van en la raíz de `__magic__`, junto a la `__all__` que zurg mantiene ahí. No en `__magic__/__all__`, ni en `__magic__` en sí, ni en la raíz del montaje. Ambos \*arrs lanzan una comprobación de estado para esas rutas; las carpetas hermanas no activan ninguna.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` refleja la biblioteca, así que cada release está presente antes de que organices nada.

**3. Organízala.** Un `mv` dentro de `__magic__` escribe una fila y no mueve ningún byte.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Si Sonarr y Radarr organizaron tu biblioteca antigua, muévela con un único script.** Renombra cada archivo al que enlaza la biblioteca antigua dentro de una nueva carpeta raíz bajo `__magic__`. Cada uno acaba en la ruta que el \*arr ya espera. No se copia nada. Después cambias la carpeta raíz del \*arr sin dejar que mueva nada. Los pasos y el script están en [la página compartida](index.md#coming-off-a-symlink-library). Nunca dejes que un \*arr mueva los archivos él mismo. Eso cruza el límite del montaje. Es una copia y descarga tu biblioteca.

El script necesita una función `zurg_path` para los enlaces de AltMount. Guárdala como `zurg_path.sh` junto a él y define `OLDMOUNT` con la ruta donde está montado AltMount.

```bash
OLDMOUNT=/mnt/altmount          # AltMount's mount, where the old links point
zurg_path() {
  case "$1" in "$OLDMOUNT"/*) ;; *) return ;; esac   # not a link into AltMount
  local name=${1##*/} f videos
  local release; release=$(basename "$(dirname "$1")")
  [ -f "$ZURG/__all__/$release/$name" ] && { echo "$ZURG/__all__/$release/$name"; return; }
  # AltMount named a lone video or an unpacked archive after the release. Take its one video.
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

La función espera que la carpeta del release esté justo encima del archivo en el destino de cada enlace. La ruta exacta que usan los enlaces de AltMount no se comprobó para esta guía. Ejecuta `readlink` sobre un enlace primero. Cuando AltMount nombró un único vídeo o un archivo sin comprimir con el nombre del release, la función toma el único vídeo que zurg sirve en ese release. Un release con más de un vídeo nunca se adivina. En ese caso imprime `NOT IN ZURG`.

**4. Apunta Plex a las carpetas raíz que creaste** — `__magic__/tv` y `__magic__/movies` — y solo a esas. Nunca a la raíz de `__magic__`, que también contiene toda la biblioteca en `__magic__/__all__`, y nunca a `__magic__` *y* a un directorio de filtro, o cada episodio se encontrará dos veces. Confirma que `autoEmptyTrash` es `0`. Añade la nueva ubicación y escanea. Luego elimina la antigua. Esa es la ruta de biblioteca de tu \*arr o el montaje de AltMount si Plex la leía directamente.

**5. Vacía la papelera** cuando hayas revisado a ojo unos cuantos elementos. El estado de visualización vuelve mediante la coincidencia por GUID. Las colecciones y las elecciones de imágenes no.

Deja AltMount en marcha hasta entonces. No cuesta nada y es tu vuelta atrás. Cuando termines, deténlo.

```bash
sudo systemctl stop altmount
```

## Después {#afterwards}

No des de baja AltMount hasta que hayas hecho streaming desde una muestra representativa. Su directorio de configuración guarda el almacén `.nzbz`, y ese es la única otra copia de tus NZB.

Ahora piensa en la adquisición. zurg tiene un [endpoint compatible con SABnzbd](../guides/sonarr-radarr.md), opcional, por el que Sonarr y Radarr pueden hacer sus grabs.
Reemplaza a AltMount como cliente de descarga de ambos.
zurg revisa cada grab antes de reportarlo como terminado. Pregunta a los servidores de noticias por el inicio y el final de cada archivo. También descarga el primer artículo de cada archivo. Son hasta sesenta y cuatro, más unos cuantos extra en una release con solo unos pocos archivos. Algunos servidores de noticias siguen diciendo que un artículo existe después de que su contenido fue retirado, y solo una descarga lo muestra. zurg reconstruye una release con artículos perdidos en sus archivos PAR2 cuando puede. Una que no puede reconstruir se reporta como **Failed**. Entonces el \*arr la añade a la lista negra y toma otra. La revisión es una muestra y no el post completo. Un post que perdió un tramo que la muestra no alcanzó sigue reportándose como Completed y falla en la lectura que llega al hueco.

Mantén las carpetas raíz de los \*arr dentro de `__magic__`. Una carpeta raíz en cualquier otro lugar recibe una copia completa de cada importación. En Docker, dale al \*arr un solo volumen que contenga todo el montaje de zurg. Una carpeta de descargas y carpetas raíz en dos volúmenes también copian cada importación. Mira [un solo volumen](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
