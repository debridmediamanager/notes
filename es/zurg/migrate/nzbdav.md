# Migrar de nzbdav a zurg {#migrating-from-nzbdav-to-zurg}

Lee [la página compartida](index.md) primero. Explica el trash guard y por qué tu biblioteca acaba en `__magic__`.

La última versión de nzbdav-dev es la v0.6.4, de abril de 2026, y el repositorio original ya no tiene mantenimiento.
Esa versión funciona. Esta migración trata de salir de un software sin mantenimiento. No hace falta un cambio apresurado.

**Esta es la más fácil de las cinco migraciones.** Comparada con zurg en las mismas cinco versiones, el árbol de nzbdav difiere en exactamente dos cosas.

| | |
|---|---|
| zurg gana | el archivo `.nfo` de la versión |
| zurg pierde | 5 volúmenes par2 con nombres hash dentro de las versiones ofuscadas |

**No se renombra nada.** Cada nombre de archivo que sirve nzbdav también lo sirve zurg, con el mismo nombre y en la misma estructura de directorios. Esto también se cumple dentro de los archivos RAR. Los dos servidores coincidieron en los 20 archivos que no son par2 del corpus.

!!!warning Nunca recorras la raíz de WebDAV
El almacén de objetos `.ids` de nzbdav materializa los 16 hijos hexadecimales en cada uno de sus cinco niveles, sin importar el contenido. Eso son 16^5, o unos 1,048,576 directorios. Apunta `find`, `du`, `rclone` y cualquier escáner explícitamente a `/content`, `/nzbs` o `/completed-symlinks`. Nunca a `/`.
!!!

## Cómo queda tu biblioteca después {#what-your-library-looks-like-afterwards}

**Todo se vuelve a añadir** porque la raíz de la biblioteca se mueve a `__magic__`.
No hay una vía más barata ni una parcial. Mira [la página compartida](index.md)
para saber por qué.

La buena noticia es que nzbdav es la única migración en la que **no cambia nada de lo que ves, salvo el prefijo**. Cada nombre de archivo que sirve zurg es el mismo que servía nzbdav. Un \*arr que vuelve a importar desde `__magic__` analiza exactamente lo mismo que analizaba antes. Una carpeta que organizas a mano se ve igual que siempre.

Esto se cumple con cualquier configuración que tengas. En Windows y en cualquier otro sitio donde Plex lee el montaje directamente, los nombres de archivo son idénticos. Si Sonarr y Radarr organizan una biblioteca de enlaces simbólicos, entonces los nombres de archivo ya eran los suyos y la fuente que analizan no cambia. Así que esta migración no altera en nada cómo se lee tu biblioteca. Solo cambia dónde vive.

## Qué contenido nuevo aparece {#what-new-content-shows-up}

- El `.nfo` dentro de las versiones RAR.
- **Clips de muestra** dentro de `Sample/`. nzbdav publica el directorio y el clip, y zurg también. Esto no es nuevo para ti. nzbdav es el único de los cuatro servidores que ya lo tenía.
- Carpetas vacías para las versiones cuya cadena de archivos está rota. nzbdav no creó nada para esas.
- par2 y sfv dejan de verse.

Nada de esto genera un elemento en Plex, salvo el clip de muestra, y nzbdav ya te lo mostraba. Si antes no te molestaba, no cambia nada.

## Saca tus NZB {#get-your-nzbs-out}

**Cópialos. No los muevas.** zurg se alimenta de un directorio de archivos `.nzb`, y nzbdav todavía tiene todos los tuyos en `/nzbs/<category>/`. Borrar algo de `/nzbs/` cancela el trabajo.

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

Los dos servidores nombran la carpeta del release con el nombre de archivo del NZB. Así que los stems que recuperaste deberían coincidir con las carpetas que sirve nzbdav. Compruébalo y renombra las que no coincidan.

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

Hay dos reglas de nombres de zurg que conviene revisar contra esa lista.

- zurg quita `.mkv` o `.mp4` del final del nombre de una carpeta. Si algún stem termina así, pon `retain_folder_name_extension: true`.
- Dos releases distintos con el mismo stem reciben un sufijo ` {shorthash}` en uno de ellos. Búscalos ahora con `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`.

## Monta zurg en paralelo {#build-zurg-alongside}

nzbdav sigue sirviendo todo el tiempo. Copia su bloque de provider en la config de zurg.
Dale a zurg su propio mountpoint. Mete los NZB y deja que escanee. El directorio watch se revisa cada 15 segundos más o menos.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from nzbdav's provider settings
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
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l     # should approach your release count
```

## Cambia a zurg {#cut-over}

**1. Activa `__magic__`** y reinicia. Las rutas se registran al arrancar, así que el interruptor del panel necesita un reinicio antes de que el namespace responda.

```yaml
magic:
  enabled: true
```

**2. Crea las carpetas raíz.** Van en la raíz de `__magic__`, junto al `__all__` que zurg mantiene ahí. No en `__magic__/__all__`, ni en `__magic__` en sí, ni en la raíz del montaje. Ambos \*arrs lanzan un health check por esas rutas; las carpetas hermanas no activan ninguno.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` replica la biblioteca, así que cada release está presente antes de que organices nada.

**3. Organiza la biblioteca.** Un `mv` dentro de `__magic__` escribe una fila y no mueve bytes.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Si Sonarr y Radarr organizaron tu biblioteca antigua, muévela con un único script.** Renombra cada archivo al que enlaza la biblioteca antigua y lo pone en una nueva carpeta raíz bajo `__magic__`. Cada uno acaba en la ruta que el \*arr ya espera. No se copia nada. Luego cambias la carpeta raíz del \*arr sin dejar que mueva nada. Los pasos y el script están en [la página compartida](index.md#coming-off-a-symlink-library). Nunca dejes que un \*arr mueva los archivos por sí mismo. Eso cruza el límite del montaje. Es una copia y vuelve a descargar tu biblioteca.

El script necesita una función `zurg_path` para los enlaces de nzbdav. Guárdala como `zurg_path.sh` junto al script y pon `OLDMOUNT` en la ruta donde está montado nzbdav.

```bash
OLDMOUNT=/mnt/nzbdav            # nzbdav's mount, where the old links point
# The map from each .ids name to its release and file. Built once while nzbdav runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # A file under another name. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Los enlaces de nzbdav apuntan a su almacén `.ids`, y zurg no tiene nada parecido. Por eso la función lee una vez el árbol `completed-symlinks` de nzbdav para saber a qué release y archivo corresponde cada nombre `.ids`. Mantén nzbdav en marcha hasta que el script termine. nzbdav no renombra nada, así que cada nombre que encuentra es uno que zurg sirve.

**4. Apunta Plex a las carpetas raíz que creaste** — `__magic__/tv` y `__magic__/movies` — y solo a esas. Nunca a la raíz de `__magic__`, que también contiene toda la biblioteca en `__magic__/__all__`, y nunca a `__magic__` *y* a una carpeta de filtro a la vez, o cada episodio se encontrará dos veces. Confirma que `autoEmptyTrash` es `0`. Añade la nueva ubicación y escanea. Luego elimina la antigua. Esa es la ruta de biblioteca de tu \*arr o el montaje de nzbdav si Plex la leía directamente.

**5. Vacía la papelera** cuando hayas revisado unos cuantos elementos. El estado de visto se recupera mediante la coincidencia de GUID. Las colecciones y las portadas elegidas no.

Deja nzbdav funcionando hasta entonces. No cuesta nada y es tu vuelta atrás. Cuando termines, para nzbdav.

```bash
sudo systemctl stop nzbdav
```

## Después {#afterwards}

Conserva el directorio de configuración de nzbdav hasta que hayas reproducido en streaming desde una muestra representativa.
Es la única otra copia de tus NZB.

Ahora piensa en la adquisición. zurg tiene un
[endpoint compatible con SABnzbd](../guides/sonarr-radarr.md) opcional que Sonarr y Radarr pueden usar para descargar.
Sustituye a nzbdav como cliente de descarga de ellos. La descarga aterriza en
`__magic__/__all__` y la importación la mueve con un renombrado. No se copia nada.
zurg comprueba cada descarga antes de marcarla como terminada. Pregunta a los servidores de noticias por el inicio y el final de cada archivo.
También descarga el primer artículo de cada archivo. Son hasta sesenta y cuatro más algunos extra si una release tiene solo unos pocos archivos.
Algunos servidores de noticias siguen diciendo que un artículo existe después de que su contenido se haya retirado, y solo una descarga lo revela.
zurg reconstruye una release con artículos perdidos en sus archivos PAR2 cuando puede.
Si no puede reconstruirla, se marca como **Failed**. Entonces el \*arr la añade a la lista de bloqueo y busca otra.
La comprobación es una muestra y no el post completo. Un post que perdió un tramo que la muestra no alcanzó seguirá apareciendo como Completed y fallará en la lectura que llegue al hueco.
Mantén las carpetas raíz de los \*arr dentro de `__magic__`. Una carpeta raíz fuera de ahí obtiene una copia completa de cada importación.
En Docker, dale al \*arr un solo volumen que contenga todo el montaje de zurg. Una carpeta de descargas y las carpetas raíz en dos volúmenes también copian cada importación.
Consulta [un solo volumen](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
