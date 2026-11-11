# Migrar de InfiniDysk a zurg {#migrating-from-infinidysk-to-zurg}

Lee primero [la página compartida](index.md). Explica el trash guard y por qué tu biblioteca acaba en `__magic__`.

Medido contra zurg con las mismas cinco releases:

| | |
|---|---|
| zurg gana | el clip de muestra, el `.nfo` |
| zurg pierde | 5 volúmenes par2 con nombre hash dentro de releases ofuscadas |
| renombrado | **todas las releases excepto las de varios archivos** |

!!!warning El renombrado es toda la migración
InfiniDysk renombra el archivo de medios de una release con el nombre del NZB
siempre que la release se resuelve en un único payload. En el corpus del
2026-09-01, cuatro de cinco quedaron como `ToyStory5.mkv`, `Obfuscated.mkv`,
`FatherBrown.mp4` y `MandaloriaREMUX.mkv`. Solo el pack de temporada de diez
episodios conservó sus nombres de episodio. El renombrado se aplica a cualquier
profundidad. `FatherBrown.mp4` está *dentro* del directorio conservado
`Father.Brown.2013.S02E05.HDTV.x264-TLA/`.

zurg mantiene el nombre de archivo del poster. Así, el nombre de la release vuelve
y cada release de un único payload cambia de ruta. Ese nombre es la cadena que
Plex y los \*arrs analizan para obtener calidad, grupo y episodio.
!!!

Otra diferencia es pequeña pero confusa si la encuentras sin contexto. InfiniDysk
crea el directorio `Sample/` del archivo y lo deja **vacío**. zurg pone dentro el
clip de muestra.

El contenido no es motivo para migrar. La build `cd9b1205` importó las cinco
releases del corpus de referencia, incluido el pack de temporada. No esperes ver
a InfiniDysk descartando cosas. Lo que recuperas es el nombre.

!!!warning Nunca recorras la raíz de WebDAV
El almacén de objetos `.ids` materializa los 16 hijos hexadecimales en cada uno de
sus cinco niveles, sin importar el contenido. Son 16^5, o unos 1.048.576
directorios. Apunta `find`, `du`, `rclone` y cualquier escáner explícitamente a
`/content`, `/nzbs` o `/completed-symlinks`. Nunca a `/`.
!!!

## Cómo queda tu biblioteca después {#what-your-library-looks-like-afterwards}

**Todo se vuelve a añadir** porque la raíz de la biblioteca se mueve a `__magic__`. Mira
[la página compartida](index.md) para saber por qué no hay una vía más barata.

Esta es la migración que menos te cuesta y más te da. Casi todos los nombres de archivo mejoran. `ToyStory5.mkv` pasa a ser
`Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv` y un \*arr
que reimporte desde `__magic__` por fin puede sacar del nombre de archivo la calidad, la fuente, el grupo
y la edición. Solo los packs de temporada se quedan como estaban, y esos ya se leían bien.

Lista las releases cuyos nombres cambian. Serán la mayoría.

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

El `-maxdepth 4` importa porque el renombrado puede pasar un nivel dentro de un directorio de archivo.

!!!info Si lo ves o no depende de tu configuración
Si Plex lee el montaje directamente, entonces los nombres de arriba son lo que cambia en tu biblioteca. Eso incluye cualquier configuración de Windows y cualquier configuración de Linux o macOS sin una granja de enlaces simbólicos de \*arr.

Si Sonarr y Radarr organizan una biblioteca de enlaces simbólicos con el renombrado activado, entonces **tus nombres de archivo ya son los suyos** y ninguno de los nombres de arriba aparece en Plex. Lo que te dicen los nombres en ese caso es lo buena que era la lectura que hacía el \*arr. Eso importa cuando reimportas. Mira [la página compartida](index.md).
!!!

## Qué contenido nuevo aparece {#what-new-content-shows-up}

- **Clips de muestra.** Los directorios `Sample/` que ya tienes dejan de estar vacíos. Esta es la opción que más conviene configurar. Pon [`only_show_the_biggest_file: true`](../reference/config.md) si no quieres que una muestra de 9 MB aparezca como una segunda versión del episodio.
- El `.nfo` dentro de los lanzamientos en RAR. No hace nada con los agentes predeterminados de Plex.
- Carpetas vacías donde la cadena de archivos está rota. InfiniDysk no creó nada para esos casos.
- **Los par2 y sfv dejan de ser visibles.** Eso incluye los volúmenes con nombre hash dentro de los lanzamientos ofuscados. No tienen extensión de medio, así que Plex no los habrá catalogado. Si alguna herramienta que no es de Plex los recorría, lo notará.

## Saca tus NZB {#get-your-nzbs-out}

zurg se alimenta de un directorio de archivos `.nzb`. Uno por release, con el nombre de la carpeta del release. El WebDAV de InfiniDysk en `/nzbs/<category>/` refleja la cola y se puede leer.

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

No está verificado si los trabajos completados siguen apareciendo en `/nzbs` una vez terminan. Refleja la cola, y tu historial puede ser más largo que la cola. Para lo que falte, los metadatos NZB que InfiniDysk guarda para volver a montar están en `{CONFIG_PATH}/blobs/`. El formato de los blobs **no está verificado**, así que compruébalo antes de fiarte.

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

Si en tu instalación los blobs no son XML plano, el historial de descargas de tu indexador es la alternativa.

Después, crea un archivo `<release>.nzb` para cada carpeta de release que realmente tengas.

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

Los NZB que sacas de `/nzbs/<category>/` normalmente ya llevan el nombre correcto. De ahí sale el nombre de la carpeta. Vale la pena revisar dos reglas de nombrado de zurg contra la lista.

- zurg quita el `.mkv` o `.mp4` final del nombre de una carpeta. Si alguna carpeta de release termina así, pon `retain_folder_name_extension: true`.
- Si dos releases distintos comparten nombre, a uno de ellos se le añade el sufijo ` {shorthash}`. Encuéntralos con `cut -f2 releases.tsv | sort | uniq -d`. InfiniDysk tenía el mismo problema, pero de otra forma. Volver a importar un NZB allí creó `<Release> (2)`.

## Monta zurg en paralelo {#build-zurg-alongside}

InfiniDysk sigue funcionando sin interrupciones.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from InfiniDysk's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
enable_repair: true
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l          # should approach your release count
```

`__all__` contiene todas las versiones sin importar los filtros de directorio.

## Cambia a zurg {#cut-over}

Un solo camino, sea cual sea tu configuración actual. Aquí no se mueve ningún byte.

**1. Activa `__magic__`** y reinicia. Las rutas se registran al arrancar, así que un interruptor del panel necesita un reinicio antes de que el namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crea las carpetas raíz.** Van en la raíz de `__magic__`, junto a `__all__` que zurg mantiene ahí. No en `__magic__/__all__`, ni en `__magic__` en sí, ni en la raíz del montaje. Ambos \*arrs muestran un health check por esas; las carpetas hermanas no activan ninguno.

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

**Si Sonarr y Radarr organizaron tu biblioteca antigua, muévela con un solo script.** Renombra cada archivo al que apunta la biblioteca antigua y lo pasa a una nueva carpeta raíz dentro de `__magic__`. Cada uno acaba en la ruta que el \*arr ya espera. No se copia nada. Luego cambias la carpeta raíz del \*arr sin dejar que mueva nada. Los pasos y el script están en [la página compartida](index.md#coming-off-a-symlink-library). Nunca dejes que un \*arr mueva los archivos por sí mismo. Eso cruza el límite del montaje. Es una copia y vuelve a descargar tu biblioteca.

El script necesita una función `zurg_path` para los enlaces de InfiniDysk. Guárdala como `zurg_path.sh` junto al script y pon `OLDMOUNT` en la ruta donde está montado InfiniDysk.

```bash
OLDMOUNT=/mnt/remote/infinidysk # InfiniDysk's mount, where the old links point
# The map from each .ids name to its release and file. Built once while InfiniDysk runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # InfiniDysk named a lone video after the release. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Los enlaces de InfiniDysk apuntan a su almacén `.ids`, y zurg no tiene nada parecido. Por eso la función lee una vez el árbol `completed-symlinks` de InfiniDysk para saber a qué release y archivo corresponde cada nombre `.ids`. Mantén InfiniDysk en marcha hasta que el script termine. Cuando InfiniDysk nombró un video suelto con el nombre del release, la función toma el único video que zurg sirve en ese release. Un release con más de un video nunca se adivina. En ese caso imprime `NOT IN ZURG`.

**4. Apunta Plex a las carpetas raíz que creaste** — `__magic__/tv` y `__magic__/movies` — y solo a esas. Nunca a la raíz de `__magic__`, que también contiene toda la biblioteca en `__magic__/__all__`, ni a `__magic__` *y* a un directorio de filtro a la vez, o cada episodio se encontrará dos veces. Confirma que `autoEmptyTrash` es `0`. Añade la nueva ubicación y escanea. Después elimina la antigua. Esa es la ruta de biblioteca de tu \*arr, o el montaje de InfiniDysk si Plex la leía directamente.

**5. Vacía la papelera** cuando hayas revisado algunos elementos. El estado de visto vuelve con la coincidencia de GUID. Las colecciones y la elección de carátulas no.

Deja InfiniDysk en marcha hasta entonces. No cuesta nada y es tu vuelta atrás. Cuando termines, detenlo.

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## Después {#afterwards}

Mantén `{CONFIG_PATH}/blobs/` y tu conjunto de NZB recuperados hasta que hayas hecho streaming desde una muestra representativa.

Ahora piensa en la adquisición. zurg tiene un [endpoint compatible con SABnzbd](../guides/sonarr-radarr.md) opcional que Sonarr y Radarr pueden usar para descargar. Reemplaza a InfiniDysk como cliente de descarga. La descarga aterriza en `__magic__/__all__` y la importación la mueve fuera con un rename. No se copia nada.

zurg revisa cada descarga antes de marcarla como terminada. Le pregunta a los servidores de noticias por el inicio y el final de cada archivo. También descarga el primer artículo de cada archivo. Eso son hasta sesenta y cuatro más unos cuantos extra si la release tiene solo unos pocos archivos. Algunos servidores de noticias siguen diciendo que un artículo existe después de que su contenido fue retirado, y solo una descarga lo muestra. zurg reconstruye una release con artículos perdidos a partir de sus archivos PAR2 cuando puede. Si no puede reconstruirla, se reporta como **Failed**. Entonces el \*arr la pone en la lista negra y busca otra. La revisión es una muestra y no todo el post. Un post que perdió un tramo que la muestra no alcanzó seguirá reportándose como Completed y fallará en la lectura que llegue al hueco.

Mantén las carpetas raíz de los \*arr dentro de `__magic__`. Una carpeta raíz en cualquier otro lugar recibe una copia completa de cada importación. En Docker dale al \*arr un solo volumen que contenga todo el montaje de zurg. Una carpeta de descarga y carpetas raíz en dos volúmenes también copian cada importación. Consulta [un solo volumen](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
