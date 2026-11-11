# Migrar de streamnzb v5.1.0 a zurg {#migrating-from-streamnzb-v510-to-zurg}

streamnzb es un addon de Stremio. Busca en indexadores Newznab cuando pulsas play y transmite el resultado ganador.
No guarda nada. No tiene montaje WebDAV en el sistema de archivos ni biblioteca de Plex.

No hay **ninguna biblioteca en disco que conservar ni estado de visualización de Plex en riesgo**. Los pasos de conservación de rutas de las otras guías de migración no se aplican.

zurg puede ocupar su lugar de dos formas. Usa una de ellas o las dos.

- **Mantener Stremio.** zurg tiene un [addon de Stremio](../guides/stremio.md) propio. Busca en tus indexadores Newznab cuando pulsas play y transmite la release que elijas a través de tu cuenta de noticias. Así funciona también streamnzb. Solo necesita zurg. Sin rclone y sin servidor multimedia. Cada release reproducida de esta forma también se queda en la biblioteca de zurg.
- **Crear una biblioteca.** zurg guarda las releases que tiene en una biblioteca y la monta para Plex, Jellyfin o Emby. Sonarr y Radarr pueden llenarla. También puede hacerlo el propio zurg desde tu watchlist.

Algunas cosas que hacía streamnzb no tienen equivalente en zurg. Esta guía indica cuáles.

Esta guía es más corta que sus hermanas porque el problema es más pequeño.

## Qué hay que volver a escanear y qué contenido nuevo aparece {#what-needs-rescanning-and-what-new-content-shows-up}

Las dos preguntas que responden las [otras guías de migración](index.md) no aplican realmente aquí. Vale la pena explicar por qué en lugar de dejarte con la duda.

**No hay que volver a escanear nada porque no hay nada que escanear.** streamnzb no tiene biblioteca y Plex no tiene elementos vinculados a ninguna ruta. Así que la maquinaria de protección contra la papelera de la página compartida no te afecta en absoluto. No hay ningún elemento antiguo que conservar y nada que se pueda enviar a la papelera por un error.

**Todo es contenido nuevo.** Lo que metas en `nzbs/` de zurg será un primer escaneo sobre una biblioteca vacía. Configura tus bibliotecas como quieres antes del primer pase, en lugar de arreglarlas después. Conviene tener dos ajustes listos antes.

- [`only_show_the_biggest_file: true`](../reference/config.md) en los directorios que escanean tus bibliotecas multimedia. Si no, verás clips de muestra, archivos `.nfo` y los archivos `.url` de publicidad del poster.
- "Generate video preview thumbnails" **desactivado** en esas bibliotecas. En un montaje de streaming, cada pase de miniaturas es una lectura completa del release que consume tu cuota de Usenet. Un primer escaneo le entrega a Plex toda la biblioteca de una vez.

---

## El cambio de modelo {#the-model-change}

| | streamnzb | zurg |
|---|---|---|
| Adquisición de contenido | Busca en indexadores Newznab por cada solicitud de reproducción | El [addon de Stremio](../guides/stremio.md) busca en indexadores Newznab por cada solicitud de reproducción. Una biblioteca también se llena con archivos `.nzb` y con el endpoint de SABnzbd y [adquisición](../guides/acquisition.md) |
| Ranking y selección | Rasgos de jhin, perfiles de filtro y una comprobación de AvailNZB | Primero la resolución y luego una gama de tamaños dentro de cada resolución. Sin rasgos ni perfiles de filtro |
| Retención | No se guarda nada. Cada reproducción es una búsqueda nueva | Biblioteca persistente. Un release reproducido a través del addon se queda en ella |
| Cliente | Stremio. El addon también es el proveedor de metadatos | Stremio a través del addon de zurg, que solo responde con streams. Cualquier servidor multimedia sobre el montaje. O WebDAV directamente para Infuse |
| Sistema de archivos | Ninguno | Montaje FUSE de rclone, más WebDAV, más un índice HTTP simple |
| Archivos comprimidos | RAR y 7z **solo STORE**. Los releases comprimidos no se reproducirán | RAR y 7z comprimidos se transmiten de forma transparente |
| Publicaciones ofuscadas | Rechazadas | Nombres recuperados de las cabeceras yEnc y PAR2. El contenido se presenta con el nombre del release |
| Publicaciones dañadas | Omitidas mediante AvailNZB | La reparación PAR2 reconstruye los artículos que faltan. El addon omite un release cuyo inicio ha desaparecido y prueba el siguiente |
| API de SABnzbd | No. En su lugar tiene un proxy NNTP en el puerto 119 | Sí, y es opcional. Cada descarga se comprueba contra los servidores de noticias. Una publicación muerta se reconstruye desde PAR2 cuando es posible y se informa como Failed cuando no lo es |

En el día a día, Stremio puede seguir como está. Añade el addon de zurg y elige un título como lo hacías antes. zurg busca en tus indexadores y reproduce lo que elijas. La [página de Stremio](../guides/stremio.md) explica la configuración. La primera reproducción de un release espera mientras zurg descarga el NZB y lista el release. Suele tardar unos pocos segundos. Cada reproducción posterior de ese release empieza al instante.

Una biblioteca para tu servidor multimedia necesita algo que la llene.

- **El endpoint de SABnzbd.** Al poner `sabnzbd.enabled: true`, zurg responde a Sonarr y Radarr como cliente de descargas. La importación es un renombrado dentro de `__magic__`. La descarga aterriza en `__magic__/__all__`. La importación mueve el archivo desde ahí a la carpeta raíz que creaste al lado. No se copia nada. La mayoría de configuraciones de biblioteca deberían usar esto. Consulta [Sonarr y Radarr](../guides/sonarr-radarr.md). zurg comprueba cada descarga contra los servidores de noticias antes de informar que ha terminado. Pregunta por el inicio y el final de cada archivo. También descarga el primer artículo de cada archivo. Eso son hasta sesenta y cuatro más algunos extra en un release con pocos archivos. Algunos servidores de noticias siguen diciendo que un artículo existe después de que su contenido fuera retirado, y solo una descarga lo demuestra. zurg reconstruye un release con artículos perdidos a partir de sus archivos PAR2 cuando puede. Si no puede reconstruirlo, se informa como **Failed**. Entonces el \*arr lo añade a la lista de bloqueados y descarga otro.
- **Adquisición.** zurg puede buscar solicitudes por sí solo. Vienen de tu watchlist de Plex y de Seerr y los \*arr. Busca en tus indexadores Newznab y comprueba cada descarga de la misma forma. Consulta [adquisición](../guides/acquisition.md).
- **Colocación manual.** Descarga el `.nzb` desde la web de tu indexador y cópialo en `nzbs/`. El nombre es fijo, el directorio se vuelve a escanear cada 15 segundos más o menos, y los archivos nunca se mueven ni se consumen. Siempre funciona y es la base más honesta.
- **"Usenet Blackhole" de Sonarr y Radarr.** Los \*arr se pueden configurar con un cliente de descargas Blackhole cuyo *Nzb Folder* sea `nzbs/` de zurg. Así recuperas la automatización de búsqueda y descarga sin el endpoint, pero con un coste. El \*arr espera a que aparezca una descarga completada en su carpeta de vigilancia para importarla. zurg nunca genera una, porque el release aparece en el montaje. Así que la cola del \*arr muestra el elemento como si nunca terminara. Obtienes entrega automatizada de NZB en lugar del proceso de importación y renombrado del \*arr. La parte del \*arr de esto no se volvió a verificar para la guía. La parte de zurg sí está verificada en el código en `internal/nzb/provider.go:30`.
- **La descarga RSS o de carrito de un indexador a una carpeta.** Esto depende por completo del indexador y de que tú escribas un script para la descarga. No verificado, y solo se menciona porque algunos indexadores lo ofrecen.

**Pon nombre al archivo antes de soltarlo.** La carpeta del release en el montaje se nombra según el *nombre de archivo* del NZB. La cabecera `<meta type="name">` solo se usa cuando el nombre de archivo parece un hash. Eso se midió en los cinco servidores el 2026-08-19. Un archivo llamado `indexer_download_48213.nzb` no le da nada a Plex para emparejar, así que primero cámbiale el nombre por el del release. Esto también significa que el nombre de la carpeta está totalmente bajo tu control. Dos releases distintos con el mismo nombre reciben un sufijo ` {shorthash}`.

---

## Configuración que se mantiene {#configuration-that-carries-over}

Hay dos cosas que sí se transfieren. La primera es el proveedor de Usenet. streamnzb configura los proveedores en **Settings → Providers** con host, puerto, nombre de usuario, contraseña y conexiones. Las variables de entorno también funcionan. La misma cuenta pasa a ser el bloque `nntp` de zurg.

Antes, en streamnzb. Esta es la forma con variables de entorno y los nombres de clave documentados.

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

Después, en el `config.yml` de zurg.

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

Un segundo proveedor de streamnzb, como `PROVIDER_2_*`, va dentro de `nntp.servers`. Así zurg recorre las cuentas artículo por artículo cuando hace falta. `priority` se traslada directamente. zurg añade dos conceptos que streamnzb no tiene. Si pones `backup: true`, marcas una cuenta de bloque medido que solo se consulta cuando todas las principales responden *no such article*. Y con `backbone` evitas que dos cuentas del mismo spool reciban la misma pregunta dos veces. Solo se permite una entrada de proveedor `nzb`. Las cuentas de noticias extra van dentro de ella, no al lado.

La segunda son tus indexadores. Van en `stremio.indexers` con la misma URL y la misma API key. Adquisición usa esa misma lista cuando no tiene una propia.

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

Nada más de `data/config.json` de streamnzb se transfiere. Los bloques `streams` y `filter_profiles` daban forma a lo que ofrecía el addon de streamnzb. El addon de zurg tiene una lista por título y su propio ranking. Sus opciones más cercanas son dos. `max_size_gb` descarta las versiones por encima de un tamaño. `max_results` indica cuántas versiones conserva cada resolución. El [página de Stremio](../guides/stremio.md) explica el resto.

## Historial de reproducción {#watch-history}

streamnzb guarda el historial de reproducción de cada stream en su base de datos. Por defecto es SQLite en `data/streamnzb.db`, y opcionalmente Postgres. Con esos datos construye las filas Continue Watching y Because You Watched. Su documentación describe el contenido como "library, search and play history, bad releases, and metrics".

**Nada de eso es portable a una biblioteca de Plex.** El estado de visualización de Plex se guarda por elemento, en la propia base de datos de Plex, y está ligado a elementos que primero deben existir en una biblioteca. No existe ningún importador en ninguno de los dos lados. En realidad no es tanto una pérdida de datos como un desajuste de modelos. Las filas de historial de streamnzb hacen referencia a búsquedas y streams, no a archivos. Si quieres conservar el registro antes de desmantelarlo, la base de datos es SQLite normal y se puede leer directamente.

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

Los nombres exactos de las tablas no están documentados y no se han verificado para esta guía. Para encontrarlos, ejecuta `.tables`. En Postgres, los mismos datos están en la base de datos a la que apunte `DATABASE_URL`. El estado de visualización en tu nueva configuración empieza desde cero y se acumula en Plex desde la primera reproducción.

---

## Lo que ganas {#what-you-gain}

- **Una biblioteca real.** Plex, Jellyfin y Emby escanean un sistema de archivos y guardan los metadatos y el estado de reproducción en todos los clientes que soportan. No solo Stremio.
- **Reparación con PAR2.** Una release con artículos faltantes se reconstruye en segundo plano usando sus propios archivos de recuperación. La respuesta de streamnzb ante una release mala era saltársela. La de zurg es arreglarla.
- **Releases ofuscadas.** zurg recupera los nombres de archivo reales a partir de las cabeceras yEnc y del índice PAR2, y presenta un payload completamente ofuscado con el nombre de la release. Medido en el banco, donde `Obfuscated.nzb` sirvió un `Toy.Story.5.2026...KyoGo.mkv` limpio. streamnzb rechaza estas directamente.
- **RAR y 7z comprimidos.** streamnzb solo transmite archivos comprimidos en modo STORE, y su README lo deja claro: "Compressed RAR releases will not play". zurg transmite el vídeo de archivos comprimidos y reproduce la estructura de directorios interna mientras lo hace.
- **Las segundas reproducciones arrancan al instante.** streamnzb buscaba y comprobaba en cada reproducción. zurg guarda lo que ya reproduciste. Una release que ya está en la biblioteca se reproduce de inmediato. Todo lo que Sonarr o Radarr descargan está en ese estado desde el principio.
- **Gran profundidad con varias cuentas.** Prioridades, cuentas `backup` de pago por uso, deduplicación con `backbone` y una ruta de reparación cuando todas las cuentas fallan.

## Lo que pierdes {#what-you-lose}

- **jhin y perfiles de filtro.** El addon de zurg también busca en tus indexadores. Ordena por resolución y tamaño, y nada más. No hay rasgos de jhin, perfiles de filtro ni puntuaciones.
- **La comprobación de AvailNZB.** zurg no le pregunta a nadie más si un release sigue disponible. El addon lo averigua leyendo el inicio del release que elegiste. Cuando ese inicio ya no está, pasa al siguiente release de la lista. Una descarga desde Sonarr o Radarr se comprueba contra tus servidores de noticias antes de darse por terminada. Los daños más adentro de un archivo aparecen cuando una lectura llega hasta ellos. Después, la reparación PAR2 lo reconstruye siempre que el post tenga suficientes datos de recuperación. El 2026-08-19, un conjunto de RAR al que le faltaban volúmenes completos apareció como una carpeta vacía en lugar de como un error.
- **Los catálogos y filas de streamnzb.** Sus catálogos integrados, sus metadatos y sus filas de Continue Watching y Because You Watched salían de su propio historial. El addon de zurg solo responde con streams. Un servidor multimedia tiene sus propias versiones de esas filas para una biblioteca.
- **El proxy NNTP en el puerto 119.** Si SABnzbd o NZBGet apuntaban a streamnzb como su servidor de noticias, ahora necesitan otra vez las credenciales reales del proveedor.

## Poner en marcha zurg {#standing-up-zurg}

A `config.yml` que funciona solo con Usenet.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

No uses filtros `tags_match_any` para contenido de Usenet. Las etiquetas `zurg_*` vienen de ffprobe y ffprobe nunca se ejecuta en este backend. Un directorio así simplemente nunca contendrá una release de Usenet. Filtra por nombres, extensiones, tamaños y `has_episodes`.

Luego inícialo.

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__all__/
```

Si Usenet es tu única cuenta, su carpeta `__nzb__` no aparece en el listado raíz del mount, y `__all__` contiene los mismos archivos. Así que prueba la reproducción en `__all__` dentro del mount, o abre la ruta HTTP directa `http://localhost:9999/http/__nzb__/`. Los subdirectorios de `nzbs/` se omiten y `.nzb.gz` no se lee.

### La primera biblioteca de Plex {#the-first-plex-library}

Apunta las bibliotecas a **subdirectorios** del montaje, como `/mnt/zurg/movies` y `/mnt/zurg/shows`. Nunca a la raíz. La misma versión aparece en `__all__` y en cada directorio que coincida, así que escanear la raíz la haría recorrerse varias veces.

Si Usenet es tu única cuenta, `__nzb__` no aparece en el listado raíz del montaje y no se resuelve a través de él, porque `__all__` contiene los mismos archivos.

Dale a zurg `plex_server_url` y `plex_token` para que pueda pedir escaneos parciales.

Hay dos ajustes de la biblioteca que importan desde el primer escaneo, tanto si la biblioteca es nueva como si no. Lo que evitan es que el montaje falle *durante* un escaneo.

1. **Desmarca "Empty trash automatically after every scan"** para que `autoEmptyTrash` sea 0. Si el montaje desaparece a mitad de un escaneo, Plex concluye que todos los archivos se borraron. Basta con reiniciar zurg o volver a montar con rclone para que pase. Con el vaciado automático activado, los elementos se eliminan de forma permanente y al instante. Con él desactivado, se quedan en la papelera y vuelven cuando vuelve el montaje. Esto ya ha costado decenas de miles de elementos.
2. **Desmarca "Generate video preview thumbnails".** En Usenet, cada pasada de miniaturas es una lectura completa de la versión a través de tu cupo de conexión.

Y nunca reinicies zurg mientras Plex está escaneando. La comprobación previa y los dos ajustes deben estar a cero.

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Usa `grep -o … | wc -l` en lugar de `grep -c`. grep devuelve un código de salida distinto de cero cuando no encuentra nada, y ese es el caso *bueno* aquí. Eso interrumpe una cadena `&&` o un script con `set -e` justo antes del reinicio que se estaba protegiendo.

Los tamaños de los archivos se estabilizan un poco después de que una versión aparezca por primera vez en el listado. Un NZB no indica cuánto mide cada archivo. Por eso, el primer listado lo estima a partir de los tamaños de los artículos que registra el NZB. Esa estimación puede salir hasta un 3 por ciento más alta. Después, zurg aprende en segundo plano la longitud exacta y la conserva. Un escaneo que se ejecute antes de eso verá la estimación. Plex entonces considera que el archivo ha cambiado y lo vuelve a analizar una vez. No se borra nada.

## Ejecutar ambos en paralelo {#running-both-side-by-side}

Nada choca en los puertos. streamnzb usa 7000 y 119, y zurg usa 9999. Así que la transición sensata es mantener streamnzb sirviendo Stremio mientras la biblioteca de zurg se va llenando.

El único recurso compartido es la cuenta de Usenet. **Ambos leen del mismo cupo de conexiones, y el proveedor lo aplica a los dos.** Un plan con 50 conexiones no puede usar 50 para streamnzb y 30 para zurg. El exceso recibe conexiones rechazadas, y en el lado de zurg eso se ve como streams lentos o que se atascan. Repártelo de forma explícita. Prueba `PROVIDER_1_CONNECTIONS=20` en streamnzb y `connections: 30` en zurg. Dale a zurg todo el cupo cuando retires streamnzb, porque el rendimiento de zurg por stream depende de ese número.

Cuando apagues streamnzb, quita su addon de Stremio de tus clientes. Guarda una copia de `data/` si quieres conservar el historial. Su `config.json` y `streamnzb.db` son todo su estado. Después, vuelve a apuntar directamente a tu proveedor cualquier cosa que usara el proxy NNTP del puerto 119.
