# Documentación de configuración de zurg {#zurg-configuration-documentation}

Este documento detalla todas las opciones de configuración disponibles para zurg. Configura estas opciones en tu archivo `config.yml`.

> **Consejo:** La mayoría de los ajustes se pueden configurar desde el **Dashboard** en `http://localhost:9999/config/`. La interfaz web ofrece una forma más sencilla de ver y modificar los ajustes sin tener que editar el archivo de configuración directamente.

## Migrar desde una configuración anterior a `providers` {#migrating-from-a-pre-providers-config}

Si tu configuración se escribió antes de que llegara el soporte para varias cuentas, sigue arrancando: las claves de nivel superior `token:`, `download_tokens:` y `strm_link_token:` se leen como lo único que podían describir: una sola cuenta de Real-Debrid. Al iniciar, se muestra una advertencia indicando que están obsoletas. Mover estas claves a una entrada de `providers` es el único cambio que necesita tu archivo de configuración, y puedes hacerlo cuando quieras. No se ha renombrado, cambiado de tipo ni eliminado ninguna otra clave.

Sin embargo, no es lo único que cambia. Algunas directivas mantienen su nombre y su valor, pero ahora deciden algo un poco distinto, porque el código que las lee cambió de lugar. Están recogidas en [Qué más cambia al actualizar](#what-else-changes-when-you-upgrade) más abajo. Vale la pena leerlo si filtras por archivos comprimidos, por etiquetas o por la fecha en que se añadió un lanzamiento.

### El único cambio que hay que hacer {#the-one-change-to-make}

Una sola cuenta de Real-Debrid solía ocupar tres claves de nivel superior. Ahora las tres van dentro de una única entrada `providers`.

Antes:

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

Después:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

Borra las claves antiguas una vez movidas. Si las dejas junto a un bloque `providers` que ya configura Real-Debrid, se ignoran y el arranque muestra una advertencia sobre ellas, así que los dos nunca pueden discrepar en silencio sobre qué token está activo. El resto del archivo no necesita cambios: todas las demás claves conservan su nombre y significado, y una configuración cuyo único credencial era `token:` solo necesita esta edición.

No estás obligado a hacerlo. Una configuración sin migrar sigue arrancando: las tres claves se leen como una cuenta de Real-Debrid llamada `realdebrid`, y el arranque indica qué claves leyó y qué escribir en su lugar. Están obsoletas, no son compatibles: las nuevas funciones de cuenta solo están disponibles desde una entrada `providers`.

Las variables de entorno `TOKEN` / `RD_TOKEN` siguen funcionando y siguen creando una configuración automáticamente en el primer arranque.

### Lo que se volvió posible y que quizá quieras {#what-became-possible-that-you-may-want}

Nada de esto es obligatorio. Esto es lo que te da el bloque `providers`:

| Ya disponible | Dónde |
|---|---|
| Backends de TorBox, AllDebrid y Usenet, junto a Real-Debrid o en su lugar | [Cuentas](#accounts) |
| Varias cuentas del mismo servicio, diferenciadas por `name` | [Cuentas](#accounts) |
| `disabled: true` para dejar en pausa una cuenta sin borrar sus credenciales | [Cuentas](#accounts) |
| `watchlist: true` para elegir con qué cuenta se prueban primero las nuevas adiciones de torrents | [Cuentas](#accounts) |
| Filtros de directorio `provider:` / `not_provider:` y directorios por cuenta | [Directorios](#7-directories--filters) |
| `rd_cdn_host_preference` y `tb_cdn_host_preference` para elegir el CDN por servicio | [CDN y selección de host](#cdn--host-selection) |

Dos cambios menores que conviene conocer:

- `cdn_host_preference` sigue funcionando y sigue significando Real-Debrid. Ahora es un alias de `rd_cdn_host_preference`, que tiene prioridad si se definen ambos.
- Las credenciales de Plex del flujo de autenticación del Dashboard se guardan ahora en `config.yml` como `plex_server_url` y `plex_token`. Antes estaban en `data/plex.json`.

### Migrar a mano vs. desde el panel {#migrating-by-hand-vs-by-dashboard}

El Dashboard puede terminarlo por ti. Una configuración sin migrar se carga, así que el editor de providers es accesible y lista la cuenta de Real-Debrid con la que se leyeron tus claves de nivel superior. Al guardar cualquier cuenta, esas claves se mueven al bloque `providers` en disco. Editar el archivo a mano y reiniciar hace lo mismo, y es la única opción si la configuración no carga del todo.

Una cosa que el Dashboard ya no acepta: `POST /config` antes aceptaba `token`, `download_tokens` y `strm_link_token` como claves de nivel superior, y ahora responde `400 Unknown config option`. Las credenciales ahora se editan por cuenta. Cualquier script que maneje esas tres necesita actualizarse.

### Qué más cambia al actualizar {#what-else-changes-when-you-upgrade}

**Los filtros ahora miran dentro de los archivos comprimidos.** `any_file_inside_regex`, `any_file_inside_contains`, `any_file_inside_size_gte`/`_lte`, sus formas `not_`, `has_episodes` e `is_music` antes se evaluaban contra el propio archivo comprimido: una entrada llamada `Show.part01.rar`, con el tamaño del volumen. Ahora, una vez que zurg ha listado un archivo comprimido, se evalúan contra su contenido: los nombres reales de los archivos, sus tamaños reales y, a propósito, *no* el tamaño del propio archivo, que eclipsaba todo lo que contenía. Un pack de temporada que antes parecía un archivo enorme ahora coincide con `has_episodes`; `any_file_inside_regex: /\.mkv$/i` empieza a coincidir donde antes fallaba, y `any_file_inside_not_regex` deja de coincidir donde antes pasaba. Por otro lado, una release cuyos archivos son todos `.rar`/`.r00`/`.par2` ahora sí llega a los filtros, cuando antes iba directamente a `__unplayable__`.

Esto llega release a release y no de golpe: se aplica solo a los archivos comprimidos que zurg ya ha listado, y los listados escritos por un parser anterior se descartan, así que una release cambia la primera vez que alguien la abre. Si un directorio tuyo depende de la lectura antigua, exprésalo contra el nombre del archivo con `regex`/`not_regex`, que siguen coincidiendo con el nombre de la release.

**Los filtros de etiquetas ya no capturan releases que nunca se analizaron.** Las etiquetas `zurg_*` vienen de ffprobe. Cuando no se pudo analizar nada, todas las tablas de niveles terminaban en cero y la release seguía recibiendo `zurg_sdr`, `zurg_very_low_video_bitrate`, `zurg_very_low_audio_bitrate` y `zurg_0to20mins_duration`, lo que describía un archivo que nadie había medido. Ya no se emiten. Un filtro que nombre una de esas cuatro cambia de significado para las releases no analizables: `has_tag`/`tags_match_all`/`tags_match_any` dejan de capturarlas y, y aquí está lo que conviene revisar, `not_has_tag`, `tags_missing_all` y `tags_missing_any` **empiezan** a capturarlas. Los filtros que nombran cualquier otro nivel no se ven afectados.

**`added_within_hours` / `added_within_days` / `added_after` / `added_before` leen una marca de tiempo más antigua para los duplicados.** Cuando una release está presente más de una vez, la entrada ahora informa de la hora de añadido más temprana en lugar de la primera que se vio, así que una segunda copia de una release antigua ya no parece recién añadida. Un directorio tipo `recent` puede dejar de mostrar una release que antes sí conservaba.

**El montaje guarda en caché los listados de directorios durante 12 horas.** `check_for_changes_every_secs` solía fijar `--dir-cache-time` de rclone, así que los listados caducaban cada 15 segundos por defecto. Ahora se mantienen 12h y zurg olvida explícitamente las entradas afectadas cada vez que cambia la biblioteca, lo que mantiene calientes los escaneos de los servidores multimedia. Para volver atrás, sobrescríbelo directamente: `rclone_extra_args` tiene prioridad sobre cualquier flag integrado:

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**Cada cuenta tiene un directorio `__<account>__`.** Se crea a partir del bloque `providers` y no de `directories`, contiene todo lo que tiene esa cuenta, ignora tus filtros de directorio y fija las lecturas a esa cuenta. `directories` no puede suprimirlo. Con más de una cuenta aparece en la raíz del montaje. Las compilaciones anteriores a nightly 2026.10.24.0551 también listaban ahí la carpeta de una sola cuenta; desde esa nightly en adelante se omite del listado raíz del montaje, porque `__all__` es la misma biblioteca. Las rutas HTTP y WebDAV directas como `/http/__realdebrid__/` siguen respondiendo. A través del montaje tampoco se resuelven ya; apunta cualquier biblioteca o script que usara `__<name>__` a `__all__`.

**Dos releases que compartían nombre ahora son dos entradas.** Antes se fusionaban en una, plegando en silencio los archivos de una release dentro de los de la otra. A la que no conserva el nombre original se le añaden seis caracteres de su info hash — `Movie.2024 {a1b2c3}`. Esa cadena con sufijo es la que comparan `regex`, `not_regex`, `contains` y `not_contains`, así que un patrón anclado no la encontrará. Por otro lado, las entradas desambiguadas por un basename duplicado se renombran una vez al actualizar, pasando de un id de archivo generado por la cuenta a una etiqueta derivada de la ruta.

**Los archivos `.strm` cambian de forma.** Con `serve_strm_files`, cada `.strm` que sirve el montaje cambia de contenido y de tamaño informado: la URL ahora apunta a la entrada de la biblioteca en lugar del enlace de una cuenta, así que hace failover y sobrevive a las reparaciones. Un servidor multimedia verá cambiar cada `.strm`. Con `save_strm_files`, los archivos ya escritos se reescriben en su sitio con los mismos nombres la primera vez que arranca zurg, y el servidor multimedia recogerá la nueva URL en su próximo escaneo. La forma nueva se firma con un secreto en `data/strm_secret`; si no se puede escribir, zurg registra una advertencia y arranca igualmente, y los enlaces dejan de resolverse tras el siguiente reinicio, así que conviene no ignorarlo.

**`load_dumped_torrents` no cargará un `dump/` de antes de la actualización.** Los torrents en caché ahora llevan la cuenta de la que vienen, y los que no tienen esa marca se omiten. La caché principal se reimporta desde la cuenta en el siguiente refresco; `dump/` no tiene cuenta detrás, así que quedará vacío con una advertencia en el log. Vuelve a exportar desde una instancia en marcha si lo necesitas.

**La reparación toma otra ruta cuando `restrict_repair_to_cached` y `only_full_torrent_repair` son false.** Ambas claves no cambian cuando están en `true`. Con ellas desactivadas —el valor por defecto— las estrategias por archivo y por lotes se sustituyeron por un único re-add que nombra los archivos rotos. Misma intención, peticiones distintas a la cuenta.

**Cambios menores.** `ignore_renames` ahora también decide el nombre del `.zurgtorrent` en disco (se migra solo al cargarse). `retries_until_failed` ahora limita los reintentos de fair-usage de Real-Debrid, que antes se repetían sin fin. `auto_analyze_new_torrents: false` y un `ffprobe_binary` ausente ya no impiden la limpieza de caché, que antes se saltaba junto con el análisis. Un filtro de tamaño que excluye el primer volumen de un archivo ahora oculta ese archivo entero en lugar de recurrir a un volumen posterior. Los recursos estáticos sin autenticación se ampliaron de `/static/css/*` a `/static/*`; ninguna ruta protegida antes es pública ahora.

## Configuración de Windows {#windows-configuration}

Al ejecutar zurg en Windows, las rutas deben escribirse de forma diferente:

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Puntos clave para Windows:**
- Usa comillas alrededor de todas las rutas
- Para `mount_path`: usa una letra de unidad como `P:\` (escrita como `P:\\` en YAML) o `P:/`
- Para las rutas de los binarios: las barras `/` funcionan y evitan problemas de escape
- Asegúrate de incluir la extensión `.exe` en los ejecutables

## 1. Lo esencial (primero la instalación) {#1-essentials-setup-first}

Estos son los imprescindibles para tener el servidor en marcha.

| Opción | Tipo | Por defecto | Descripción |
|--------|------|---------|-------------|
| `zurg` | string | *(obligatorio)* | Identificador de la versión de la configuración. Debe estar configurado en `v1`; cualquier otro valor (incluida una clave ausente) hace que la carga falle. |
| `providers` | list | *(obligatorio)* | Tus cuentas de debrid y Usenet, una entrada por cada una. Consulta [Cuentas](#accounts) más abajo. Las claves de nivel superior `token`, `download_tokens` y `strm_link_token` anteriores a `providers` están obsoletas: siguen cargándose, como una única cuenta de Real-Debrid, y al arrancar aparece una advertencia. Un bloque `providers` que ya configure Real-Debrid tiene prioridad y la clave suelta se ignora. |
| `mount_path` | string | Depende del SO | La ruta del sistema de archivos donde está tu montaje de rclone. zurg la usa para indicar a los servidores multimedia (Plex, Jellyfin, Emby) dónde encontrar los archivos. También se usa como punto de montaje cuando `rclone_enabled` es true. Por defecto es `/mnt/zurg` (Linux), `/Volumes/Zurg` (macOS) o `Z:` (Windows). Los usuarios de Docker deben configurar esto como `/zurg_mnt/zurg` con el montaje de volumen `/zurg_mnt:/zurg_mnt:rshared` (consulta [docker.md](../setup/docker.md)). |
| `base_url` | string | `""` | La URL accesible desde fuera de tu instancia de zurg. Se incrusta en los archivos STRM para que los servidores multimedia puedan reproducir el contenido. Si no se configura, los archivos STRM contendrán URLs de `localhost` que no funcionarán desde otros dispositivos. Usa tu IP de Tailscale, tu IP de LAN o un dominio con proxy inverso. Ejemplo: `http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### Cuentas {#accounts}

Cada entrada en `providers` es una cuenta. Puedes tener varias funcionando a la vez: Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link y Offcloud juntos, o varias cuentas del mismo servicio.

| Opción | Tipo | Por defecto | Descripción |
|--------|------|---------|-------------|
| `type` | string | *(obligatorio)* | Qué backend usa la cuenta: `realdebrid`, `torbox`, `alldebrid`, `premiumize`, `debridlink`, `offcloud`, `nzb` o `torbox_nzb` ([TorBox hosted Usenet](../providers/torbox-nzb.md)). |
| `name` | string | valor de `type` | Distingue esta cuenta de las demás del mismo tipo. Es el nombre que usa el filtro `provider`, el [directorio por cuenta](#per-account-directories), las rutas de caché y el panel. Los nombres deben ser únicos entre entradas, y `e` está reservado para el enrutamiento de enlaces STRM. |
| `token` | string | *(obligatorio)* | El token o la clave API de la cuenta. Consigue uno de Real-Debrid en http://real-debrid.com/?id=20475782, uno de TorBox en https://torbox.app/settings, y uno de AllDebrid en https://alldebrid.com/apikeys?uid=1kk5i. No se usa con `nzb`, que se autentica mediante `nntp`. Un token de Real-Debrid también se puede dar con la variable de entorno `TOKEN` o `RD_TOKEN` para que se cree automáticamente una configuración en la primera ejecución. |
| `download_tokens` | list | `[]` | **Real-Debrid y AllDebrid:** tokens API de respaldo para el mismo servicio, que se usan cuando se agota el ancho de banda permitido del token activo. Usan el catálogo de esta entrada, incluido un [catálogo local](#local-debrid-catalogs), sin importar las bibliotecas de torrents de las cuentas extra. **TorBox:** se acepta, pero la rotación no remapea los IDs de torrent/archivo específicos de cada cuenta; usa entradas de proveedor separadas para cuentas distintas. No lo usa NZB. Premiumize, Debrid-Link y Offcloud requieren entradas de cuenta separadas porque los IDs de archivo guardados pertenecen a la cuenta que hizo el listado. |
| `strm_link_token` | string | `""` | Un token API separado que resuelve las lecturas que llegan al endpoint `/strm/`, para que un reproductor que abre un `.strm` no gaste el token con el que se transmite el montaje en vivo. Si no se define, usa `token`. **Real-Debrid y AllDebrid**: los dos backends que rotan credenciales, y por eso los dos donde fijar el tráfico `.strm` a una clave propia tiene sentido. Se acepta pero no se usa en entradas `torbox` y `nzb`. Premiumize, Debrid-Link y Offcloud solo aceptan aquí el `token` propio de la cuenta. |
| `disabled` | bool | `false` | Mantiene una cuenta en la configuración sin cargarla. Si todas las entradas están deshabilitadas, la carga falla. |
| `watchlist` | bool | `false` | Marca la cuenta que se prueba primero para las nuevas adiciones de torrents. Eso incluye los endpoints del cliente de descargas y los indexadores Torznab de adquisición. Como máximo una entrada puede tenerlo activado, y nunca una entrada `nzb` o `torbox_nzb`. Si ninguna lo tiene, se usa la primera cuenta que pueda añadir torrents. Los NZB de adquisición van al backend de Usenet y nunca a esta cuenta. Consulta [Lista de seguimiento](#watchlist). |
| `add_torrents` | bool | `true` | Si a esta cuenta se le ofrecen nuevos torrents en absoluto: los que reciben los endpoints del cliente de descargas y los que toma la adquisición de los indexadores Torznab. Ponlo en `false` para una cuenta de archivo, o para una cuya cuota ya esté ocupada: sigue sirviendo y leyendo su biblioteca, pero nunca se le añade nada nuevo. **El orden de la lista `providers:` es el orden en que se prueban las cuentas que sí aceptan nuevas adiciones**, así que esta clave y ese orden se leen juntos; una cuenta marcada con `watchlist: true` se prueba primero esté donde esté. No se puede combinar con `watchlist: true` en la misma entrada, y en una entrada `nzb` se ignora con una advertencia al arrancar, ya que un servidor de noticias nunca recibe un torrent. Consulta [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see). |
| `warm_connections` | int | `1` | Cuántas conexiones mantiene esta cuenta abiertas y con el handshake hecho **a cada host que ha estado usando**, para que una lectura no tenga que abrir una. Máximo 4. `-1` no mantiene ninguna. Se ignora en una entrada `nzb`, cuyo mínimo es por cuenta y se configura en [`nntp.warm_connections`](../guides/usenet.md). Consulta [conexiones calientes](#warm-connections). |
| `nntp` | block | *(obligatorio para `nzb`)* | Credenciales del servidor de noticias. Es obligatorio para el tipo `nzb` y se ignora en los demás tipos. |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

El ajuste `download_tokens` de TorBox no ofrece la conmutación de reproducción entre cuentas que sí permiten los enlaces bloqueados de RD y AD. Su resolutor cambia la clave API pero conserva los IDs de torrent/archivo de la fuente existente. Las entradas de proveedor de TorBox separadas mantienen los IDs y el catálogo de cada cuenta independientes. Para una biblioteca local, pon los manifiestos portables en el directorio de origen propio de cada entrada.

#### Seeding de TorBox {#torbox-seeding}

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|---------|-------------|
| `tb_seed_torrents` | string | `never` | Si los torrents que zurg añade a una cuenta de TorBox se siembran. `never` desactiva la siembra en cada adición. `auto` deja la decisión a la configuración de siembra de tu cuenta de TorBox. `always` activa la siembra en cada adición. Se aplica a todas las cuentas de TorBox de la configuración, y a la siguiente adición en cuanto se cambie. Cualquier otro valor impide que zurg arranque. |

```yaml
tb_seed_torrents: never
```

Déjalo en `never` a menos que lo necesites. Está pensado para los trackers privados que cuentan tu ratio. Una release obtenida a través del endpoint
[`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see)
como archivo `.torrent` se añade con este ajuste, así que con `always` (o `auto` en una cuenta configurada para sembrar) TorBox lo sube de nuevo al enjambre del tracker. Importarlo en Sonarr o Radarr no evita eso: una descarga terminada que el cliente elimina se queda en la cuenta.

**Un torrent en siembra ocupa una de las ranuras activas de tu plan mientras siembra.** TorBox cuenta un torrent que está sembrando igual que uno que se está descargando. Sus planes permiten 3, 5 o 10 a la vez (Essential, Standard, Pro) y siembran hasta 24 horas, 14 días o 30 días. Cuando todas las ranuras están ocupadas por torrents sembrando, las nuevas descargas y reparaciones de esa cuenta se quedan paradas hasta que se libere una, ya sea cuando se agote el tiempo de siembra de un torrent o cuando lo borres en TorBox. La siembra también cuenta como subida para los límites de uso justo de TorBox. Con `never` nada de esto pasa, por eso es el valor por defecto.

`auto` no envía a TorBox ninguna preferencia de siembra, así que se aplica lo que diga la configuración de siembra de tu cuenta. En una cuenta donde nadie la haya cambiado, eso es el Auto propio de TorBox. `always` y `never` sobrescriben la configuración de la cuenta solo para los torrents que zurg añade y no tocan el resto de la cuenta.

#### Cuentas de Usenet {#usenet-accounts}

El tipo `nzb` es Usenet y no un servicio debrid: los archivos `.nzb` que pongas en el directorio `nzbs/` se convierten en torrents dentro de la biblioteca, y las lecturas se resuelven descargando artículos de tu servidor de noticias y decodificándolos sobre la marcha. Solo se admite una entrada `nzb` habilitada, porque ambas escanearían el mismo directorio. Los servidores de noticias adicionales van en `nntp.servers` de esa entrada, donde sirven la misma biblioteca en lugar de una segunda copia. Una entrada `nzb` junto a una de [`torbox_nzb`](../providers/torbox-nzb.md) también se rechaza por la misma razón. Ejecuta ese tipo en una instancia propia, con su propio directorio de trabajo.

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|-------------------|-------------|
| `host` | string | *(obligatorio)* | El nombre de host del servidor de noticias, por ejemplo `news.example.com`. |
| `port` | int | `563` con TLS, `119` sin TLS | El puerto del servidor de noticias. |
| `tls` | bool | `false` | Envuelve la conexión en TLS. |
| `username` | string | `""` | El nombre de usuario de la cuenta. |
| `password` | string | `""` | La contraseña de la cuenta. |
| `connections` | int | `8` | El número de conexiones simultáneas que permite la cuenta. zurg lee usando este número: una sola conexión aprovecha solo una fracción de la velocidad del plan, así que el streaming debe ocupar todo el cupo en lugar de descargar un artículo a la vez. Si superas lo que permite el plan, las conexiones serán rechazadas, así que pon la cifra real. |
| `pipeline_depth` | int | `4` | Cuántos artículos pide zurg a la vez por una misma conexión. El máximo es 8. Ponlo en `1` si el servidor no puede manejar varios comandos en vuelo. zurg baja a 1 por su cuenta, con una advertencia, cuando los lotes siguen fallando. |
| `socket_receive_buffer_kb` | int | sin definir | Fija el búfer de recepción del kernel de cada conexión en este número de KiB. Déjalo sin definir. Un búfer fijado deja de ser ajustado por el kernel. En Linux, esto mantiene la ventana de recepción cerca de 64 KiB y cuesta la mayor parte de la velocidad de la cuenta en cualquier enlace con latencia. Solo existe para kernels que nunca ajustan el búfer o cuyo límite está configurado demasiado bajo. |
| `cache_size_mb` | int | `512` | Cuántos datos de artículos decodificados se guardan en memoria, sumando todos los archivos que se están leyendo y no por archivo. |
| `servers` | list | `[]` | Cuentas de noticias adicionales a las que recurrir, artículo por artículo. Consulta [más de un servidor de noticias](#more-than-one-news-server). |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### Más de un servidor de noticias {#more-than-one-news-server}

La retención es por proveedor: un artículo que un servidor ya ha dejado caducar casi siempre sigue estando en otro. Sin una segunda cuenta, la única forma de recuperar un artículo muerto es PAR2, y eso cuesta leer **toda la release**. Por eso un segundo servidor marca la diferencia entre descargar un solo artículo y tener que releerlo todo.

Las claves de arriba describen la primera cuenta. Cualquier cosa bajo `servers` es una cuenta adicional, a la que solo se pregunta cuando las anteriores no tenían el artículo. Una configuración existente de un solo servidor sigue funcionando sin cambios.

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|---------|-------------|
| `name` | string | valor de `host` | Etiqueta la cuenta en los logs. |
| `host`, `port`, `tls`, `username`, `password`, `connections`, `pipeline_depth`, `warm_connections`, `socket_receive_buffer_kb` | | | Igual que arriba. Cada cuenta tiene su propio límite de conexiones. El pipelining y el búfer de recepción se configuran por cuenta, porque la tolerancia a ellos depende del servidor. |
| `priority` | int | `0` | Quién se consulta primero, de menor a mayor. Las cuentas con la misma prioridad se consultan en el orden en que están escritas, salvo que una con una conexión libre se prefiere a otra cuyo límite ya está agotado. Así, dos cuentas iguales comparten la carga. |
| `backup` | bool | `false` | Marca una cuenta de respaldo, que solo se consulta cuando todas las primarias han respondido *no such article*. Que una primaria esté **ocupada** no basta: zurg espera a que se libere en lugar de gastar bytes medidos en algo que una cuenta ilimitada podría servir. |
| `backbone` | string | `""` | El spool de artículos al que resuelve esta cuenta. Dos cuentas en el mismo backbone tienen los mismos artículos, así que, una vez que una ha dicho que le falta un artículo, la otra se omite en lugar de hacerle la misma pregunta. |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

El censo que decide si una release necesita reparación pregunta a todas las cuentas antes de dar un artículo por desaparecido. Así, una release con huecos en un proveedor no activa una reconstrucción con PAR2 si otro proveedor aún puede servirla.

Una clave de nivel superior controla lo que dejan las reparaciones:

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|---------|-------------|
| `par2_patch_cache_mb` | int | `512` | Cuánto de `data/par2/` pueden ocupar los bytes reconstruidos por la reparación con PAR2. Esos bytes son lo único que un lector no puede volver a pedir al servidor de noticias, porque los artículos que los contienen ya no están. Conservarlos evita que un reinicio cueste una relectura completa de la release para recuperar los mismos pocos megabytes. Solo se guardan los tramos de los artículos muertos, que ocupan un solo dígito de megabytes por release dañada. Las releases completas se eliminan, de la menos usada recientemente a la más antigua, cuando se supera el presupuesto. Un valor negativo desactiva la persistencia y mantiene las reparaciones en memoria mientras dure el proceso. |

Y dos controlan lo que cuesta un NZB ya analizado en memoria:

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|---------|-------------|
| `nzb_segments` | string | `mmap` en Linux/macOS/BSD, `resident` en Windows | Cómo se retiene la lista de artículos de un NZB analizado. **Necesita reiniciar.** `mmap` escribe las listas en `data/nzb-index/<id>.bin` y mapea ese archivo bajo demanda, así que los bytes viven en la caché de páginas en lugar del heap de zurg. `reparse` los libera una vez que la release se ha asentado y vuelve a leer el NZB del disco cuando una lectura o una reparación los necesita, sin ocupar nada de disco. `resident` mantiene todos en memoria mientras dure el proceso: **el comportamiento anterior**, y lo que hacía cada versión anterior. Cualquier valor no reconocido toma el valor por defecto y se indica en una advertencia al arrancar. El modo que realmente está activo se registra en el arranque en cualquier caso. |
| `nzb_segments_idle_secs` | int | `120` | Cuánto tiempo se conserva la lista de artículos de una release tras la última lectura, con los modos perezosos. **Necesita reiniciar.** Un barrido se ejecuta cada 30 segundos, así que 10 es la ventana más corta que puede cumplir y el mínimo del Dashboard. Se ignora con `resident`, que nunca libera nada. `0` toma el valor por defecto. |

El intercambio merece explicarse con claridad, porque no es el habitual de memoria por velocidad. Un listado (una actualización de la biblioteca, una comprobación de huellas, un *arr preguntando si un trabajo se ha asentado) nunca toca un artículo en ningún modo: el nombre de un archivo, su tamaño y su número de artículos se responden desde la propia entrada. Lo que cuestan los modos perezosos es la *primera* lectura de una release que nadie ha tocado durante `nzb_segments_idle_secs`. Lo que ahorran es el heap que ocupan las listas de artículos el resto del tiempo. Medido en una release de 60 archivos y 30.000 segmentos (Apple M3 Pro):

| | heap por release, asentada | primera lectura de una release inactiva | por artículo en la ruta de lectura |
|---|---|---|---|
| `resident` | 1.74 MB (58 B/segmento) | — | 6 ns |
| `reparse` | 21.3 kB (0.71 B/segmento) | 39 ms | 52 ns |
| `mmap` | 16.6 kB (0.55 B/segmento) | 0.27 ms | 63 ns |

Dos tercios de la recarga de `mmap` es la suma de comprobación del índice que acaba de mapear. El mapeo en sí tarda 0.08 ms, y la comprobación merece la pena: sin ella, un solo byte malo dentro de un arena se serviría como un message id que nadie publicó. El servidor de noticias lo respondería como artículo muerto, y cada capa superior lo leería como daño en la release.

Y en una biblioteca real (2,636 NZB, 27.6 millones de segmentos, el mismo binario ejecutado tres veces sobre el mismo corpus, inactivo tras un escaneo):

| | resident set | heap activo | CPU en reposo | apertura en frío, p50 | índice en disco |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Las aperturas en caliente, el rendimiento de streaming y el tiempo de arranque no mostraron diferencias apreciables. `mmap` es el valor por defecto allí donde hay un mapeo real, porque gana en todos los aspectos salvo en disco. Eso incluye la apertura en frío, ya que mapear un arena escrito es una llamada al sistema, mientras que volver a analizar el NZB son megabytes de XML. Cuesta unos 55 bytes de disco por artículo y una escritura adicional por release durante el escaneo. El índice se reescribe cuando cambia el NZB y se elimina cuando el NZB desaparece. Elige `reparse` en un host donde `data/` no pueda crecer. En Windows no hay mapeo: el índice se leería en el heap, que es memoria residente *más* una recarga. Por eso el valor por defecto allí sigue siendo `resident`, y `reparse` es el modo perezoso que vale la pena elegir.

## 2. Integración con servidores multimedia {#2-media-server-integration}

Conecta zurg a tu servidor de medios para que las actualizaciones de la biblioteca, la coincidencia de metadatos y la monitorización de la lista de seguimiento funcionen automáticamente.

### Premiumize, Debrid-Link y Offcloud {#premiumize-debrid-link-and-offcloud}

```yaml
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY_OR_OAUTH_TOKEN
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_TOKEN
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
```

Estos backends permiten explorar la biblioteca, hacer lecturas en streaming o redirigidas, STRM, añadir magnets, subir archivos `.torrent` y borrar. Cada cuenta también aparece en su propio directorio `__<name>__`. Añade cuentas desde el panel o con `zurg setup`; la configuración desatendida acepta `--premiumize-token-file`, `--debridlink-token-file` y `--offcloud-token-file`, o `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN` y `OFFCLOUD_TOKEN`.

Premiumize monta las transferencias completadas y los archivos de la nube que se conservan después de limpiar la lista de transferencias. Las carpetas anidadas mantienen sus rutas. Los hashes que pasas por zurg se guardan en `data/premiumize/<account>/sources.json`, así que la coincidencia entre cuentas sobrevive a un reinicio o a limpiar las transferencias completadas. El contenido importado de la nube sin un hash registrado sigue haciendo streaming, pero no se puede reparar por hash ni emparejar con otra cuenta por hash. Borrar una transferencia de Premiumize desde zurg también borra los archivos que pertenecen a esa transferencia. El almacenamiento en la nube y las cuotas de uso justo siguen siendo los límites de la propia cuenta.

Debrid-Link lista el seedbox con paginación y resuelve cada archivo por su ID. No usa el endpoint de caché retirado; una añadida solo con caché solo puede confirmar un acierto a partir de la respuesta de la añadida. Los fallos por cuota diaria de añadidas y de tráfico se reportan como límites de la cuenta. El backend se pausa después de un rechazo por flood.

Offcloud resuelve los identificadores de archivo a través del endpoint de exploración de la nube. Los tamaños de archivo se comprueban con el servidor de entrega, y los metadatos de torrent en caché aportan las rutas de carpeta cuando se pueden emparejar sin ambigüedad. Un listado de archivos ambiguo se reporta como error. Los magnets mal formados se rechazan antes de enviarse.

Las URLs de entrega se renuevan cuando caduca su caché o cuando una lectura las invalida. Mantén privadas las URLs generadas y el acceso STRM; las cuotas del proveedor pertenecen a la cuenta que sirve los bytes. Estos tres backends usan una sola credencial por entrada de cuenta y no rotan con los identificadores de archivo de otra cuenta.

### Integración con Plex {#plex-integration}

| Opción | Tipo | Por defecto | Descripción |
|--------|------|---------|-------------|
| `plex_server_url` | string | `""` | URL de tu servidor Plex. Es necesaria para las funciones de coincidencia con Plex y de watchlist. Ejemplo: `http://localhost:32400` |
| `plex_token` | string | `""` | Tu token de autenticación de Plex. Es necesario junto con `plex_server_url`. |
| `plex_scan_check_url` | string | valor de `plex_server_url` | El servidor Plex que zurg consulta para saber si hay un escaneo de biblioteca en marcha antes de reiniciar el montaje. Espera mientras lo haya. Un montaje que desaparece en mitad de un escaneo hace que Plex borre todo lo que no pudo ver. Configúralo en una instancia que no tenga su propia integración con Plex. Lo habitual es una instancia por proveedor. Poner `plex_server_url` ahí también activaría la coincidencia con Plex. |
| `plex_scan_check_token` | string | valor de `plex_token` | El token para `plex_scan_check_url`. |
| `plex_match_every_mins` | int | `1440` | Cada cuántos minutos (en minutos) zurg escanea tu biblioteca de Plex para emparejar torrents con elementos de Plex. Esto activa funciones como mostrar qué torrents corresponden a qué contenido de Plex. Mínimo 1; `0` usa el valor por defecto. Requiere que `mount_path` esté configurado. |
| `plex_watchlist_enabled` | bool | `false` | Nombre antiguo de `watchlist.enabled` (ver [Watchlist](#watchlist)); sigue funcionando. |
| `plex_watchlist_check_every_secs` | int | — | Nombre antiguo de `watchlist.check_every_secs`; sigue funcionando si el bloque no define uno. |
| `watchlist_quality` | string | `"best"` | Nombre antiguo de `watchlist.quality`; sigue funcionando si el bloque no define uno. |
| `plex_settings_policy` | string | `"guard"` | Hasta dónde puede llegar zurg al corregir las preferencias de Plex que importan para un montaje de debrid. Uno de estos valores: `off` (no toca nada), `warn` (informa de todo, no cambia nada), `guard` (corrige solo los ajustes cuyo valor incorrecto hace perder una biblioteca, e informa del resto) o `enforce` (corrige también los ajustes que hacen que Plex decodifique archivos completos para un resultado que nadie ve). Cualquier cosa con una función visible detrás (Skip Intro, Skip Credits, vistas previas al desplazarse, miniaturas de capítulos, nivelación de volumen, análisis sónico) solo se informa, nunca se cambia. Ver [Ajustes de Plex](../guides/plex.md#recommended-plex-settings). |
| `plex_settings_ignore` | list | — | IDs de preferencias de Plex que zurg no toca, sea cual sea la política, sin distinguir mayúsculas. Se aplica por ajuste y no por nivel, así que excluir uno no te hace perder los demás. Un ID que no corresponde a ningún ajuste conocido por zurg se informa al arrancar y no cambia nada. El interruptor **Let Plex Empty Its Own Trash** del panel escribe `autoEmptyTrash` en esta lista. Ver [Excluir un ajuste](../guides/plex.md#opting-out-of-one-setting). |

> **Nota:** Lo mejor es configurar Plex desde el panel (interfaz web) mediante el flujo de autenticación; este escribe `plex_server_url` y `plex_token` de vuelta en `config.yml`. Las claves de arriba siguen siendo compatibles para la configuración manual.

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### rex

zurg puede llenar un [rex](../../rex/with-zurg.md), un servidor de medios para las apps oficiales de Plex que lee cada archivo de zurg.

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `rex_url` | string | `""` | URL del rex que construye su biblioteca a partir de este zurg, por ejemplo `http://192.168.1.20:32400`. Si eliges un rex en el inicio de sesión de Plex del panel, este campo se rellena con la dirección en la que rex recibe las fuentes (su dirección LAN o de Tailscale, en HTTP plano), y el envío empieza sin reiniciar; configúralo a mano para alimentar un rex sin iniciar sesión en Plex. Luego zurg envía su biblioteca a rex: cada archivo de vídeo de un directorio configurado, cada archivo de audio en uno con `rex_music` y los cómics en uno con `rex_photos`, con su ruta, tamaño, id de IMDb y los detalles multimedia que leyó ffprobe; esto ocurre una vez cargada la biblioteca, cada `rex_snapshot_every_hours`, y cada vez que se añade, analiza, renombra, mueve o borra un release. rex no puede reproducir un archivo antes de que ffprobe lo haya analizado, así que al configurar `rex_url` se activa `auto_analyze_new_torrents` sin importar lo que diga esa clave, y analiza el resto de la biblioteca una vez cargada y luego a diario. Cada sondeo lee de la cuenta que tiene el release, así que mantén los directorios acotados y no pongas filtros `tags_*` (con cualquiera de ellos se analiza cada release de la cuenta) si no quieres gastar tu tráfico en una biblioteca que nunca ves. Una actualización también busca el id de IMDb de cada release nuevo mediante `dmm_api_key` antes de archivarlo (mira `dmm_api_key` para ver cómo se colocan los releases). Los subtítulos que un \*arr o Bazarr escriben junto a un vídeo en `__magic__` se envían a rex con él (mira [`__magic__`](../guides/magic.md)). zurg le dice a rex dónde leer los archivos: su WebDAV en `http://<address>:<port>/dav`, con `username` y `password` si están configurados. La dirección es `host` cuando es una sola dirección; si no, por defecto es la dirección desde la que sale la conexión de zurg a rex, y rex debe poder llegar a zurg por ahí. En un contenedor esa es la dirección propia del contenedor, a la que rex solo llega desde la misma máquina Linux: en Windows y macOS instala zurg con el instalador en lugar de Docker Desktop, y en Linux con rex en otra máquina pon `network_mode: host` en el contenedor de zurg ([rex con zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex)). Si un rex está caído, se reintenta y luego se le envía la biblioteca completa; nada espera por él. No se envía ningún escaneo de Plex mientras `plex_server_url` sea este mismo rex. Después de cada snapshot y cada diez minutos, zurg lee los Fix Matches hechos en rex para sus releases y guarda cada uno como el id del release establecido a mano, a menos que hayas puesto uno en la página de gestión después; DMM entonces coloca el release según él. Para darle a un directorio sus propias bibliotecas en rex, configura [`rex_shows`, `rex_movies`, `rex_music` o `rex_photos`](#directory-options) en él. Deja `rex_url` vacío si no usas rex. |
| `rex_source` | string | `"zurg"` | El nombre de fuente con el que rex conoce a este zurg. Ponle a cada zurg que alimenta al mismo rex su propio nombre. |
| `rex_snapshot_every_hours` | int | `6` | Cada cuánto se envía de nuevo toda la biblioteca a rex, lo que arregla lo que dejó un envío perdido. El valor por defecto sirve para cualquier configuración. |

```yaml
rex_url: "http://192.168.1.20:32400"
```

### Watchlist

Añade algo a tu watchlist de Plex y zurg lo recoge. Cada elemento nuevo de la watchlist se busca en tus indexers. Un indexer Newznab da un NZB. Ese NZB entra en el backend de Usenet exactamente igual que un grab de Sonarr o una reproducción de Stremio. Los tres comparten las reglas de nombres para encontrar los grabs de los demás y no duplicarlos. Un indexer Torznab da un torrent. Solo se añade a una cuenta debrid cuando esa cuenta ya lo tiene en caché. `prefer` decide qué tipo se prueba primero entre releases de la misma resolución. Una película se convierte en un solo release. Una serie se adquiere temporada a temporada, y los packs de temporada van antes que los episodios sueltos. Una temporada de la que nadie ha publicado un pack recurre a los episodios sueltos que encontró la búsqueda, con el mejor release de cada uno. El elemento sale de la watchlist solo cuando el release detrás de él ha sido comprobado y solo si `remove_after_grab` lo permite. Los fallos se quedan en la lista. Se vuelven a intentar a los 5, 10 y 15 minutos, luego a la hora, y después cada vez más espaciados. Un título que lleva dos semanas fallando se aparca hasta que lo reanudes en la página acquisition. Consulta [persistencia y recuperación](../guides/acquisition.md#persistence-and-recovery).

Necesita un `plex_token` y al menos un indexer. Si no tiene lista propia, toma la del addon de Stremio. El monitor habla con el servicio en la nube de Plex, así que `plex_server_url` no es obligatorio. Los NZB necesitan un proveedor `nzb` o `torbox_nzb` en la misma instancia. Los torrents necesitan una cuenta debrid que los acepte. Basta con uno de los dos.

Todas las opciones siguientes están en la página de configuración, bajo **Plex Watchlist**, incluida la lista de indexers. El panel escribe este bloque en lugar de las claves planas antiguas, y desactivar el monitor ahí también borra `plex_watchlist_enabled`, ya que esa clave se suma al interruptor.

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `enabled` | bool | `false` | Inicia el monitor. La clave antigua `plex_watchlist_enabled` también cuenta. |
| `check_every_secs` | int | `60` | Cada cuánto se consulta la watchlist en el servicio en la nube de Plex. |
| `indexers` | list | `[]` | Indexers donde buscar, cada uno con `name`, `url`, `api_key` y, opcionalmente, `api_path` y `type`. `type: torznab` marca un indexer de torrents. Si no aparece, se usa `newznab`. Tiene la misma forma que `stremio.indexers`, que se toma tal cual cuando esta lista está vacía. |
| `prefer` | string | `"usenet"` | Qué tipo se prueba primero cuando un NZB y un torrent de la misma resolución podrían servir. La resolución decide antes, así que un torrent de 2160p va antes que un NZB de 1080p. `usenet` prueba primero los NZB, `torrents` prueba primero los torrents, y `best` deja que decida solo el ranking. Consulta [Newznab y Torznab](../guides/acquisition.md#newznab-and-torznab). |
| `max_size_gb` | int | `0` | Los releases más grandes que esto se descartan para películas y episodios sueltos, y los packs de temporada que superen este valor por episodio. `0` significa sin límite, así que `best` se queda con un remux de disco completo. Los releases cuyo tamaño no indicó el indexer se mantienen. |
| `max_season_size_gb` | int | `0` | Un límite para cada temporada que contiene un pack de temporada, por cada temporada que nombra. `0` significa sin límite: un pack solo se descarta por `max_size_gb` por episodio, cuando eso está definido, así que el remux de una temporada larga también cuenta. |
| `quality` | string | `"best"` | Qué release gana: `best` (primero la resolución, luego el tamaño), `4k`, `1080p`, `720p` (prefiere esa resolución y recurre a best) o `smallest`. La clave antigua `watchlist_quality` también cuenta. Aquí solo se admite un valor; solo `acquisition.quality` acepta una lista (consulta [Fuentes de acquisition](#acquisition-sources)). |

El bloque `acquisition` también acepta `concurrency` (predeterminado `8`, de `1` a `200`), que indica cuántos títulos se buscan, comprueban y colocan a la vez, e `indexer_concurrency` (predeterminado `3`, de `1` a `16`), que indica cuántas llamadas se hacen a un mismo indexer a la vez. Mantén este último bajo cuando una clave de indexer se comparta.

`exclude_words` no tiene copia en este bloque. Para mantener fuera de los grabs de la watchlist palabras como `DV` o `HDR10+`, añade un bloque `acquisition:` que contenga solo `exclude_words`. Todas las opciones anteriores siguen aplicando. Consulta [excluir releases por nombre](../guides/acquisition.md#excluding-releases-by-name).

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  quality: best
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: your-api-key
```

### Fuentes de adquisición {#acquisition-sources}

`acquisition.sources` enumera los servicios para los que zurg adquiere contenido, cada uno en la cola compartida descrita en [fuentes de adquisición](../guides/acquisition.md). Los ajustes de búsqueda (`indexers`, `quality`, `prefer`, `max_size_gb`, `max_season_size_gb`) están junto a `sources` en el bloque `acquisition:` y usan como alternativa el bloque `watchlist:` de arriba. Solo `acquisition.quality` también acepta una lista de resoluciones, como `[1080p, 4k]`: en ese caso zurg mantiene una copia de cada película de la lista de deseados de DMM en cada una de ellas, mientras que las series de esa lista y todas las demás fuentes toman la resolución más alta de la lista como su única `quality`. Consulta [una copia en cada una de varias resoluciones](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

`best_first` pertenece solo al bloque `acquisition:` y está desactivado por defecto. Al activarlo, la primera descarga de una fuente `radarr` o `sonarr` sigue el orden de preferencia del perfil de calidad. Primero va la mejor resolución permitida. Cualquier release igual o superior al cutoff cuenta como el cutoff. Cuando un release falla, zurg baja por el perfil. Si está desactivado, una película toma el release permitido que sea más barato de comprobar. Una serie toma el que `quality` ranquea primero. Después, la pasada de mejora apunta al cutoff. El mejor release suele ser un conjunto de archivos grande, así que el primer archivo tiende a llegar más tarde. Consulta [tomar primero lo mejor del perfil](../guides/acquisition.md#taking-the-profiles-best-first).

`exclude_words` (lista, por defecto vacía) también está ahí y no tiene alternativa en `watchlist`. Nunca se toma un release cuyo nombre contenga una de estas palabras, de ninguna fuente. La comparación es por palabra completa e ignora mayúsculas, así que `DV` no detecta `DVDRip`. `DV`, `DoVi` y `Dolby Vision` cuentan como una sola palabra, y lo mismo `HDR10+` y `HDR10Plus`. `HDR10` y `HDR10+` son palabras distintas. Una entrada sin letras ni dígitos se rechaza al arrancar. Las reglas completas y cómo se combinan con los perfiles de Radarr y Sonarr están en [excluir releases por nombre](../guides/acquisition.md#excluding-releases-by-name).

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|-------------------|-------------|
| `name` | string | obligatorio | Letras, dígitos, `_` y `-`, únicos. Identifica la cola guardada de la fuente, así que mantenlo estable. |
| `type` | string | obligatorio | `plex_watchlist`, `seerr`, `radarr` o `sonarr`. |
| `enabled` | bool | `false` | Una fuente desactivada se mantiene en el archivo y no se consulta. Una fuente `radarr` o `sonarr` desactivada se sigue leyendo, solo en modo lectura, en la [vista de duplicados](../guides/acquisition.md#finding-duplicate-releases) de la página de gestión. |
| `check_every_secs` | int | `60` | Cada cuánto se consulta la fuente. |
| `url` | string | | `seerr`, `radarr` y `sonarr`: la URL base HTTP(S) del servicio, sin credenciales, query ni fragmento. Se aceptan una URL base y un `/api/v1` final (Seerr) o `/api/v3` (Radarr, Sonarr). |
| `api_key` | string | | `seerr`, `radarr` y `sonarr`: la clave API del servicio. Se envía como cabecera, nunca en una URL, y se oculta en los logs y configuraciones compartidos. |
| `library_path` | string | `mount_path` + `/__magic__` | Solo `radarr` y `sonarr`: dónde ve el \*arr el directorio `__magic__` de zurg, por ejemplo `/data/zurg/__magic__` para un contenedor que monta zurg en `/data/zurg`. Una carpeta de película o serie dentro de él se coloca en la misma ruta relativa dentro de `__magic__`; una carpeta fuera de él se omite. Debe ser absoluta; se aceptan rutas de Windows como `Z:\__magic__`. zurg también la compara con la ruta donde el \*arr ve la carpeta de descargas de un cliente de descargas de zurg, y avisa si la disposición hace que las importaciones sean copias; consulta [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |
| `remove_after_grab` | bool | `true` | Solo `plex_watchlist`; sin efecto para `seerr`, `radarr` y `sonarr`. |
| `only_new_items` | bool | `true` | Solo `plex_watchlist`; sin efecto para `seerr`, `radarr` y `sonarr`, cuyos elementos pendientes siempre son trabajo. |

```yaml
acquisition:
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /data/zurg/__magic__
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /data/zurg/__magic__
```

### Mantenimiento de la biblioteca de Plex (solo en el mismo host) {#plex-library-maintenance-same-host-only}

Estas opciones necesitan que Plex esté instalado en la misma máquina que zurg, porque leen directamente su archivo de base de datos. `plex_server_url` suele ser otro host o contenedor, y ningún endpoint HTTP puede entregar ese archivo, así que se controlan con una ruta explícita y permanecen desactivadas hasta que la configures.

zurg solo **lee** esta base de datos, a través de un manejador de solo lectura. Nunca escribe en ella ni detiene Plex. El único archivo que crea es una copia en su propia carpeta `data/plex-backups/`, nunca en el directorio de Plex.

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|-------------------|-------------|
| `plex_database_path` | string | `""` | Ruta completa a `com.plexapp.plugins.library.db`. Si está vacía, desactiva todas las funciones de esta sección. |
| `plex_sqlite_binary` | string | donde Plex lo instala: `/usr/lib/plexmediaserver/Plex SQLite` en Linux, `/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite` en macOS, `%ProgramFiles%\Plex\Plex Media Server\Plex SQLite.exe` en Windows | Plex incluye su propia versión de SQLite. Un `sqlite3` estándar puede fallar con esta base de datos o dañarla. |
| `plex_backups_keep` | int | `5` | Número de snapshots que se conservan. Cada uno tiene el tamaño de toda la base de datos. Un `0` explícito solo observa y nunca crea snapshots. |
| `plex_backups_every_mins` | int | `15` | Tiempo mínimo entre snapshots, para que un zurg que se reinicia en bucle no copie la base de datos en cada reinicio. |
| `plex_trash_sweep_every_mins` | int | sin definir (ver nota) | Cada cuánto tiempo se eliminan las entradas de Plex cuyos archivos ya no están en el montaje. Si no la defines, zurg decide: la eliminación se ejecuta cada 60 minutos cuando nada más vacía la papelera de Plex, y se detiene cuando Plex sí la vacía. Un `0` explícito desactiva la eliminación propia de zurg y deja la papelera en tus manos; un valor negativo desactiva por completo la limpieza, incluida la reparación. `0` **no** devuelve a Plex el vaciado de su propia papelera, que se controla con `plex_settings_ignore` y con el interruptor **Let Plex Empty Its Own Trash** del panel. Consulta [Quién vacía la papelera](../guides/plex.md#who-empties-the-trash). |
| `plex_trash_sweep_max_items` | int | `50` | Máximo de entradas que puede eliminar una limpieza. Si se supera, la limpieza se cancela sin eliminar nada. |
| `plex_trash_sweep_max_percent` | int | `10` | El mismo límite expresado como porcentaje de lo que hay en la papelera, para que escale con el tamaño de la biblioteca. |
| `plex_trash_sweep_min_age_days` | int | `14` | Cuánto tiempo mantiene una entrada su icono rojo de papelera antes de que la limpieza pueda eliminarla. Es el valor de respaldo para las entradas sobre las que zurg no tiene veredicto. Una versión que zurg sabe que está muerta de forma permanente se elimina sin esperar, y una que aún está en reparación se mantiene sin importar su antigüedad. Un `0` explícito elimina en cuanto se cumplan las demás protecciones. |

**Por qué snapshots**, si Plex ya hace una copia de seguridad cada noche: el peligro es que el montaje se altere mientras Plex está escaneando, lo que puede vaciar una biblioteca en segundos. Una copia nocturna puede tener 24 horas de antigüedad en ese momento; una tomada justo antes de que zurg toque el montaje tiene solo segundos.

#### Lo que la limpieza de la papelera nunca eliminará {#what-the-trash-sweep-will-never-remove}

La papelera de Plex no es una lista de cosas que se pueden borrar. Es una lista de candidatos, y una buena parte están mal.

- **Un elemento que todavía tiene archivo.** Plex marca como eliminada una película entera cuando desaparece una sola de sus versiones, así que un elemento en la papelera suele tener versiones que todavía se reproducen. En lugar de borrarlo, el barrido elimina la versión fantasma, y eso hace que el elemento salga de la papelera con sus colecciones, carátulas, estado de visualización y `added_at` intactos. Si esa reparación falla por el motivo que sea, el elemento se **deja tal cual**: se queda en tu biblioteca con su icono de papelera. Nunca se borra.
- **Una serie o temporada cuyos episodios siguen ahí.** Estos no tienen ningún archivo, así que nada del montaje puede justificar quitar uno.
- **Cualquier elemento cuyo archivo no se haya confirmado individualmente como ausente**, justo antes de eliminarlo.

La eliminación se hace por elemento, no con el `emptyTrash` de Plex. `emptyTrash` afecta a toda la sección y se llevaría justo las entradas de arriba, que es lo único que el barrido no debe hacer.

#### zurg ya sabe si va a volver {#zurg-already-knows-whether-it-is-coming-back}

Para cada archivo ausente, el barrido consulta primero el estado de reparación que zurg tiene para él, antes de recurrir al temporizador:

| El veredicto de zurg | El barrido |
|---|---|
| el archivo sigue apareciendo (los filtros lo ocultan del montaje) | recurre a la ventana de antigüedad |
| roto, y la reparación no se ha dado por vencida | **mantiene la entrada**, sin importar cuánto tarde la reparación |
| roto con un motivo de reparación imposible de forma permanente (infringing, invalid, not allowed, …) | **la elimina de inmediato**, porque esperar no lo puede devolver |
| sin veredicto: el torrent salió por completo de la cuenta, o la ruta no se resuelve | recurre a la ventana de antigüedad |

Un elemento con varias versiones se evalúa como un conjunto: si una versión todavía está en reparación, se mantiene la entrada completa, y una entrada solo se considera muerta cuando lo están todas las versiones. Un fallo en la consulta nunca es motivo para borrar: todo lo que zurg no puede confirmar se gestiona con la ventana de antigüedad de abajo, igual que antes.

#### El icono de la papelera es un estado, así que la eliminación espera {#the-trash-icon-is-a-status-so-removal-waits}

Plex tiene tres estados, y solo el del medio se ve como un problema:

| Estado | Lo que ves |
|---|---|
| Live | una entrada normal que se reproduce |
| **Trashed** | la entrada **sigue en tu biblioteca y sigue contando**, en gris con un **icono de papelera rojo**, y no se reproduce |
| Purged | nada: la entrada desaparece de Plex por completo |

El icono de papelera es el único aviso que tienes de que el contenido ha desaparecido, y purgar la entrada se lleva ese aviso con ella: el elemento deja de verse roto y simplemente deja de existir. Por eso, una entrada sobre la que zurg no tiene veredicto se deja en paz hasta que haya llevado el icono durante `plex_trash_sweep_min_age_days`. Ese margen es tu oportunidad para verla y volver a adquirirla; lo que siga roto después era basura que convenía eliminar.

También actúa como una tercera capa de seguridad, por debajo de los límites y de la comprobación del mount: un problema transitorio del mount se resuelve solo mucho antes de que pase ese margen.

El periodo de gracia se aplica **solo a la eliminación**. Una reparación devuelve un elemento reproducible a tu biblioteca, así que se hace en la siguiente pasada sin importar nada más: esperar dejaría un elemento que funciona con un icono de papelera sin motivo.

Ninguno de estos estados toca los archivos. El archivo ya había desaparecido del mount, que es lo que causó la lápida, y nunca se borra nada de tu cuenta de debrid.

#### Cuándo se niega a ejecutarse {#when-it-refuses-to-run}

- zurg no está gestionando rclone (`rclone_enabled: false`), así que no puede garantizar un montaje que no controla. Por eso, "el archivo no está" no significa nada.
- rclone no está funcionando, o el montaje no se puede leer. La comprobación abre y lee un archivo en lugar de llamar a `stat`, porque un `stat` responde desde la caché de directorios de rclone y sigue funcionando mucho después de que las lecturas hayan dejado de funcionar.
- Plex está escaneando. Un escaneo en curso todavía está decidiendo qué falta.
- Se superaría cualquiera de los dos límites. Este es el más importante: **un montaje que volvió vacío pero legible pasa todas las demás comprobaciones** y hace que toda la biblioteca parezca borrada. Si se supera un límite, el barrido se cancela por completo, no elimina nada y lo indica en el log.

Antes de eliminar nada se toma una instantánea, y si la instantánea falla, el barrido se cancela.

> **Para desactivarlo:** pon `plex_trash_sweep_every_mins: 0` (quitar la clave no es lo mismo: en ese caso zurg decide según si Plex vacía su propia papelera). Cambiarlo requiere reiniciar zurg. Esto desactiva solo la eliminación de zurg. Para que Plex vuelva a vaciar su propia papelera, usa el interruptor **Let Plex Empty Its Own Trash** en el panel, o añade `autoEmptyTrash` a `plex_settings_ignore`.

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

Esa ruta es donde Linux guarda la base de datos del paquete. En macOS y Windows escríbela completa, ya que zurg no expande `~` ni `%LOCALAPPDATA%`. `plex_sqlite_binary` ya usa por defecto la ubicación donde Plex lo instala en cada sistema.

| Plex en | `plex_database_path` |
|---|---|
| macOS | `/Users/you/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db` |
| Windows | `C:\Users\you\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db` |

Pon una ruta de Windows entre comillas simples en YAML para que las barras invertidas se mantengan tal cual.

> **Ajuste relacionado de Plex, fuera de zurg:** desactiva en Plex *Settings → Library → Empty trash automatically after every scan*. Plex lo trae activado por defecto y es peligroso en un montaje de zurg: si un escaneo se encuentra con un montaje que no se puede leer por un momento, borra la biblioteca de forma permanente en lugar de dejarla en la papelera, donde volvería al volver el montaje. zurg lo desactiva por sí mismo con la política `guard` por defecto, y lo indica en el panel y en el log. Si tus archivos se mueven entre carpetas de biblioteca y necesitas recuperar esa limpieza, el interruptor **Let Plex Empty Its Own Trash** de la página de configuración se la devuelve a Plex, bajo tu propia responsabilidad.

### Otras integraciones {#other-integrations}

| Opción | Tipo | Por defecto | Descripción |
|--------|------|---------|-------------|
| `jellyfin_server_url` | string | `""` | URL de tu servidor Jellyfin. Activa las notificaciones de actualización de la biblioteca cuando zurg detecta cambios. Ejemplo: `http://localhost:8096` |
| `jellyfin_token` | string | `""` | Token de API de Jellyfin para la autenticación. |
| `emby_server_url` | string | `""` | URL de tu servidor Emby. Activa las notificaciones de actualización de la biblioteca cuando zurg detecta cambios. Ejemplo: `http://localhost:8096` |
| `emby_token` | string | `""` | Token de API de Emby para la autenticación. |
| `dmm_api_key` | string | `""` | Tu clave de API de DMM. [gatekeeper](https://gatekeeper.debridmediamanager.com/) te la muestra una vez que patrocinas. Después, DMM coloca tus archivos y rellena tu lista de deseados. |
| `dmm_metadata_secret` | string | `""` | Secreto para la API interna de metadatos de DMM. Cuando está definido, los torrents sin id de IMDb (o solo con la marca de fallo de OpenSubtitles) se identifican al arrancar a partir de su nombre de lanzamiento mediante DMM, que solo responde cuando un único título coincide exactamente. Los torrents que no puede nombrar mantienen un id vacío, para que el emparejador de Plex aún pueda completarlos. |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. Reproducción y estructura de archivos {#3-playback--file-structure}

Controla qué archivos ve tu servidor multimedia y cómo se transmite el contenido.

### Modo de streaming {#streaming-mode}

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | Cuando está en true, una lectura del **montaje** se responde con una redirección a la URL de descarga propia de la cuenta, en lugar de pasar por zurg. Reduce la CPU y el ancho de banda de zurg, pero el cliente tiene que poder llegar directamente a los servidores de la cuenta. Se ignora para un backend cuyos enlaces se sirven localmente: un archivo de Usenet no tiene URL que entregar, así que siempre pasa por el proxy. **Lee los riesgos del proveedor más abajo antes de activarlo.** |
| `serve_strm_files` | bool | `false` | Cuando está en true, zurg sirve archivos `.strm` en lugar de los archivos de vídeo reales en el montaje WebDAV. Los servidores de medios como Plex/Jellyfin leen el archivo `.strm` para obtener la URL de streaming. **Importante:** cuando está activado, los archivos de vídeo reales quedan ocultos y se sustituyen por entradas `.strm`. |
| `save_strm_files` | bool | `false` | Cuando está en true, zurg escribe archivos `.strm` en un directorio `strm/` junto al binario de zurg. Es útil si quieres archivos STRM persistentes en disco (por ejemplo, para importarlos manualmente a un servidor de medios). Usa `base_url` para las URL dentro de los archivos. Solo los archivos que un reproductor puede abrir obtienen uno: vídeo y audio reconocidos, más lo que nombre `addl_playable_extensions`, así que los subtítulos, pósteres, NFO y volúmenes PAR2 quedan fuera del volcado. Cualquiera que una versión anterior haya escrito allí se elimina la próxima vez que se recorra el release. Un `.strm` cuya URL ya no coincida, porque cambió `base_url` o lo escribió una versión anterior, se reescribe en su sitio en el siguiente inicio, o inmediatamente si cambias `base_url` en el panel. Los archivos que ya coinciden no se tocan, así que un servidor de medios no vuelve a leer toda la carpeta en cada escaneo. |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

**Mantén las lecturas del montaje con proxy (el predeterminado) para la reproducción con debrid compartido.** Real-Debrid registra la IP pública de cada descargador; usar varias IP con una misma cuenta genera una advertencia de uso compartido, incluso cuando la descarga se completa. Mantén todos los usos de esa cuenta en una sola IP pública, incluidas las comprobaciones del servidor y las conversiones, no solo las descargas del reproductor. Las URL de descarga de TorBox contienen la clave de API completa en `?token=`, así que una redirección da acceso a cada cliente y a cada usuario de la cuenta compartida, incluida la eliminación; los registros del reproductor y el historial del navegador pueden conservarla. No entregues enlaces de TorBox a clientes no confiables.

Estos riesgos se aplican tanto a las redirecciones del montaje con `disable_stream_proxy: true` como a las redirecciones de `/strm/`. Mantener `disable_stream_proxy: false` **no** hace que la reproducción de `.strm` pase por proxy ni que sea segura para compartir en remoto.

#### Lo que `disable_stream_proxy` hace y lo que no alcanza {#what-disable_stream_proxy-does-and-does-not-reach}

Controla el montaje. No afecta al endpoint `/strm/`, en ningún backend:

| La lectura llega por | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| Montaje, proxy activado (por defecto) | pasa por zurg | con proxy |
| Montaje, proxy desactivado | `302` a la URL de la cuenta | con proxy — no existe ninguna URL a la que redirigir |
| Un archivo `.strm`, con cualquiera de los dos ajustes | `307` a la URL de la cuenta | con proxy |

Un `.strm` lo abre un reproductor con el que zurg no tiene sesión, así que el endpoint solo puede entregar una URL que el reproductor pueda descargar por sí mismo. Activar el proxy no hace que ese tráfico vuelva a pasar por zurg. Lo que conviene saber: las lecturas que llegan desde archivos `.strm` no tienen contabilidad de ancho de banda, ni cambio a otra cuenta a mitad de reproducción, ni detección de enlaces rotos, cosas que sí tiene una lectura de montaje. Por eso, una biblioteca servida sobre todo con `.strm` notará poco el efecto de `disable_stream_proxy`, sea cual sea el valor.

`serve_strm_files` y `disable_stream_proxy` son independientes, aunque las versiones anteriores de esta página dijeran otra cosa. Un `.strm` se sirve como texto antes de que se tome cualquier decisión sobre el streaming, así que los dos pueden activarse a la vez. Eso sí, con `serve_strm_files` activado, cada reproducción llega al endpoint `/strm/`, que es justo la fila de arriba donde `disable_stream_proxy` no cambia nada.

### Filtrado y detección de archivos {#file-filtering--detection}

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `addl_playable_extensions` | list | `[]` | Extensiones de archivo que zurg debe tratar como contenido reproducible, además de los formatos de video y audio integrados. El panel normaliza los puntos, las comillas y las mayúsculas. Añade extensiones como `m3u` o `cbz` si quieres que esos archivos sean visibles y seleccionables. |
| `force_select_playable_files` | bool | `false` | Si es true, zurg selecciona automáticamente todos los archivos reproducibles de un torrent, aunque no estuvieran seleccionados originalmente. Funciona tanto con las extensiones de video integradas como con `addl_playable_extensions`. Es útil cuando un torrent tiene archivos de video sin seleccionar a los que quieres acceder. |
| `delete_torrent_if_extensions_found` | list | `[]` | Si cualquier archivo de un torrent tiene una de estas extensiones, todo el torrent se borra de RD. Es útil para eliminar automáticamente torrents que contengan material no deseado, como archivos `.rar` (no los extraídos por RD) o archivos `.zipx`. |
| `stream_compressed_archives` | bool | `true` | Sirve un archivo empaquetado dentro de un archivo comprimido descodificándolo mientras se lee. El descodificador mantiene una ventana de tamaño limitado en memoria. Ponlo en `false` para rechazar los archivos comprimidos como lo hacían las versiones anteriores. |

Los formatos reproducibles integrados son `.avi`, `.flv`, `.m2ts`, `.m4v`, `.mkv`, `.mov`, `.mp4`, `.mpg`, `.mpeg`, `.ts`, `.webm`, `.wmv`, `.mp3`, `.flac`, `.m4a` y `.m4b`.

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### Metadatos y nombres {#metadata--naming}

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|---------|-------------|
| `retain_folder_name_extension` | bool | `false` | **Obsoleta — se eliminará.** Cuando es true, el nombre de la carpeta es el `Name` de la cuenta tal cual, con extensión y todo, en lugar de `OriginalName` sin el `.mp4` o `.mkv` final. Solo se aplica cuando `Name` contiene `OriginalName` como subcadena; en el resto de casos el recorte se hace igualmente. `retain_rd_torrent_name` se comprueba primero y lo anula por completo. |
| `retain_rd_torrent_name` | bool | `false` | **Obsoleta — se eliminará.** Cuando es true, el nombre de la carpeta es el `Name` de la cuenta (el `filename` de Real-Debrid); cuando es false, es `OriginalName` (`original_filename`), que es el nombre que el propio torrent declara. Esto importa en un pack con un solo archivo seleccionado: Real-Debrid reduce `filename` al nombre base de ese archivo, pero `original_filename` sigue siendo el nombre del pack, así que **`false` da el nombre del pack y `true` da el nombre del archivo individual**. |
| `ignore_renames` | bool | `false` | Cuando es true, zurg ignora cualquier metadato de renombrado de los torrents y usa los nombres de archivo originales. Actívalo si los archivos renombrados están causando problemas con la detección de tu servidor multimedia. No está obsoleta. |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

Ambas opciones obsoletas usan `Name` como clave de la biblioteca, que la cuenta reescribe por debajo de zurg; los valores por defecto usan el nombre que declara el torrent, que la cuenta no toca. Al activar cualquiera de las dos se registra una advertencia al arrancar, y en una instancia que da servicio a Sonarr o Radarr (un bloque `sabnzbd:` o `qbittorrent:`) los valores por defecto son los únicos correctos: una clave de acceso que cambia tras una importación hace que se pierda el lanzamiento. El comportamiento no cambia en esta versión: los nombres de carpeta de nadie se mueven. `docs/naming.txt` contiene el conjunto completo de reglas de nombrado.

### Escrituras en el montaje {#mount-writes}

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|---------|-------------|
| `dav_allow_rename` | bool | `true` | Si es false, un MOVE de WebDAV a través del montaje se rechaza con 403. Viene activado por defecto: renombrar un torrent o un archivo es para lo que sirve el montaje escribible y no borra nada. |

**Un DELETE de WebDAV a través del montaje siempre se acepta — no hay ninguna clave para eso.** Elimina un archivo de la biblioteca y, cuando ya no queda nada, el release de todas las cuentas de debrid que lo tenían. Antes de apuntar un programa de escritura al montaje, ten claro lo que eso cuesta: rclone vacía un archivo sobrescrito como DELETE seguido de PUT, así que cualquier cosa que reescriba un archivo en su sitio (un escritor de `.nfo`, un proceso de trickplay, un renombrado de \*arr, un `touch` suelto) en lugar de reemplazarlo borra contenido, y el montaje usa las propias credenciales de rclone, por lo que la autenticación no puede distinguir una cosa de la otra. Solo si se rechaza la mitad PUT se evita que la secuencia se complete sin hacer ruido. `mount_read_only: true` es lo que evita que un DELETE llegue a zurg.

Una escritura rechazada responde **403** y registra la clave de configuración que la permitiría, así que un cliente cuya escritura dejó de funcionar te dirá por qué en `logs/zurg.log`.

Una consecuencia que conviene conocer: cuando un programa escribe a través del montaje FUSE, la caché VFS de rclone conserva la copia modificada y reintenta la subida rechazada con un retroceso progresivo, y el montaje muestra el archivo modificado localmente hasta que se descarta esa entrada de caché. El archivo del lado del servidor no se toca en todo ese tiempo. `mount_read_only: true` evita esto por completo, porque hace que la escritura falle en el kernel, antes de que rclone guarde nada en caché.

```yaml
dav_allow_rename: true
```

Consulta también `mount_read_only`, que hace que el kernel rechace la escritura antes de que llegue a zurg.

### Caché del listado de directorios {#directory-listing-cache}

| Opción | Tipo | Valor por defecto | Descripción |
|--------|------|---------|-------------|
| `disable_listing_cache` | bool | `false` | Cuando es true, cada listado de directorio se renderiza desde cero en cada petición. Déjalo desactivado: con esta opción activada, un `PROPFIND Depth:1` de `__all__` vuelve a renderizar toda la biblioteca cada vez que se pide (medido en 59 ms para 6,120 releases, 121 ms para 2,636 releases de Usenet, 148 ms para `__magic__/__all__`), y un escaneo del servidor multimedia pide el mismo listado una y otra vez. |

```yaml
disable_listing_cache: false
```

La caché guarda el último renderizado de cada directorio de nivel superior, uno por cada variante de montaje (`/dav`, `/infuse`, `/http`), y lo devuelve hasta que la biblioteca cambie. Lo que cuenta como cambio no es una suposición: es exactamente el conjunto de eventos que ya hacen que rclone olvide su propia copia en caché de ese mismo listado (un release añadido, eliminado, renombrado o reubicado, o un archivo que se rompe o se recupera), y rclone mantiene esos listados durante **doce horas**. Así que un listado servido desde aquí nunca está más desactualizado que el que el montaje ya está sirviendo, y además hay un límite fijo de 60 segundos por si acaso.

`__magic__/__all__` (el espejo, y el único listado del espacio de nombres que merece la pena cachear, ya que la raíz que está encima contiene el espejo y un puñado de filas) además sigue la disposición almacenada, así que una importación de un \*arr invalida ese único listado y deja intacto el renderizado de cualquier otro directorio. `__downloads__` y las peticiones `Depth: 0` no se cachean en absoluto.

Las respuestas incluyen una cabecera `X-Zurg-Listing: hit` o `miss`, así que una instalación en marcha se puede medir:

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`, un directorio que puedes organizar {#__magic__-a-directory-you-can-organise}

Todos los demás directorios son filtros guardados: un release está en `movies` porque coincide con el filtro de películas, así que no hay ningún lugar en la biblioteca donde *poner* algo. `__magic__` es la excepción: `__magic__/__all__` es una copia exacta de `__all__`, la raíz junto a él es tuya, y cualquier cosa se puede mover desde el espejo a cualquier otro lugar del namespace. Un movimiento reescribe una fila en `data/magic.journal`, que luego se compacta en `data/magic.json`; no se mueve ningún byte, no se renombra ningún torrent, y las filas usan como clave el hash de contenido del release, así que una reparación que reconstruye el release no pierde dónde pusiste las cosas. Es lo que permite que Radarr y Sonarr importen por renombrado en vez de por copia.

La guía completa, con lo que sobrevive a una reparación y lo que significa cada rechazo, está en [docs/magic.md](../guides/magic.md).

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|----------------|-------------|
| `magic.enabled` | bool | `false` | Servir `__magic__` o no. Desactivado por defecto: es un árbol con escritura, y un \*arr apuntado a la carpeta raíz equivocada puede reorganizar una biblioteca. Si no se ha movido nada, su propio `__all__` se lee exactamente igual que el de la biblioteca, y la raíz no contiene nada más. |
| `magic.allow_delete` | bool | `false` | Cuando es true, un DELETE de un **archivo** dentro de `__magic__` también borra el contenido, igual que un DELETE en el propio montaje siempre hace. Desactivado por defecto, un borrado solo oculta: la entrada sale de `__magic__` pero sigue en `__all__` y en todos los directorios de filtro. Una carpeta de release o un directorio nunca borran contenido, sea cual sea el valor de esta opción; Sonarr borra la carpeta del trabajo después de cada importación. Borrar un vídeo o una entrada dentro de un archivo también borra todo su release una vez que nada dentro de `__magic__` usa ninguna parte de él. |
| `magic.sidecar_max_mb` | int | `32` | El archivo individual más grande que un cliente puede subir con `PUT` a `__magic__`. Por encima de ese tamaño, la escritura se rechaza con **413**. |
| `magic.sidecar_budget_mb` | int | `2048` | El tamaño máximo que puede crecer todo el árbol de sidecars. Por encima de ese valor, una escritura se rechaza con **507 Insufficient Storage**, lo que dice algo que 413 no dice: borrar algo hace que la misma petición funcione. El total se mide recorriendo el árbol al arrancar, así que un reinicio no devuelve el margen a un árbol que ya está lleno, y de nuevo antes de cualquier rechazo; el árbol es el mismo directorio `data/local` en el que escribe el propio montaje de zurg, así que un archivo borrado allí a espaldas de zurg no debe seguir contando. Cero o un valor negativo usa el predeterminado; no hay forma de pedir que no haya límite. |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` no se aplica aquí, y tampoco la ruta de borrado sin control del montaje. Esas cubren las rutas que renombran y destruyen lo que tiene la cuenta de debrid; una escritura bajo `__magic__` no llega a ninguna cuenta. `mount_read_only: true` sigue anulando todo, a nivel de kernel.

Dos cosas que conviene saber. Los directorios de filtro no se tocan, por diseño, así que un release que moviste dentro de `__magic__` sigue en `recent` y `movies` con su nombre original; apunta un servidor multimedia a `__magic__` **o** a los filtros, no a los dos. Y cualquier cosa realmente nueva que se escriba en el montaje (un `.nfo`, un subtítulo, un póster) acaba en el `data/local` propio de zurg y se fusiona en el listado, por eso los sidecars junto a un release simplemente funcionan.

#### Archivos complementarios, y para qué sirven los dos límites {#sidecar-files-and-what-the-two-caps-are-for}

El montaje integrado es una unión cuyo primer upstream es `data/local`, así que cuando un programa crea un archivo nuevo en el montaje, rclone lo escribe ahí y zurg nunca recibe la petición. Nada limita ese árbol, salvo que [`union_writable: server`](#rclone-settings) cambie el orden de la unión. En ese caso, la creación llega a zurg como un `PUT` y se rechaza fuera de `__magic__`, y dentro está limitada por los dos topes.

Con el orden por defecto, los dos topes son para el otro tipo de cliente: uno que monta `/dav` directamente, sin ninguna unión delante. Estos envían a zurg el `PUT`, y zurg escribe el cuerpo en `data/local/__magic__/<path>`, justo el directorio que sirve la unión. Así, las dos vistas muestran un solo directorio y no dos. Sin un límite, eso sería un almacén general de archivos accesible por WebDAV, que es lo que `sidecar_max_mb` y `sidecar_budget_mb` existen para evitar.

Dos reglas se derivan de lo que es `__magic__`, y ambas son rechazos que un cliente puede ver:

- **El espejo es de la biblioteca.** `__magic__/__all__` y las carpetas de release que hay directamente dentro se calculan, así que un `MOVE`, `MKCOL` o `DELETE` dirigido a cualquiera de ellos da **403**: una fila ahí sería una segunda dirección para un release que ya tiene una. Más abajo está la carpeta propia de un release, donde escribir es tan normal como en cualquier otro sitio. Es donde un \*arr deja el `.nfo` junto a un archivo que importó.
- **Nada de lo que la biblioteca responde puede sobrescribirse.** Una carpeta de release, una entrada de una de ellas y una ruta donde un move ha colocado algo se generan desde la biblioteca, así que un `PUT` o un `MOVE` de un archivo real sobre cualquiera de ellas da **403**. Eso incluye un nombre dentro de una carpeta de release que el release no tiene: el listado de la carpeta es el del release, así que un archivo puesto entre sus entradas no lo listaría nadie.
- **Una colocación nunca destruye un archivo real.** Mover algo que tiene la biblioteca sobre una ruta que ocupa un sidecar se rechaza en vez de sobrescribirlo, incluso con `Overwrite: T`. Lo mismo vale para un directorio de archivos reales movido en sentido contrario: no puede renombrarse a una ruta que la biblioteca responde, porque sus archivos quedarían en una carpeta que lista el release y nada más.

Un `DELETE` de un sidecar sí lo borra de verdad. Es el único caso dentro de `__magic__` en que borrar no es una marca de borrado. Una marca de borrado oculta una entrada que la biblioteca sigue teniendo en otro sitio, mientras que los bytes de un sidecar viven en `data/local` y en ningún otro lugar.

#### La página `__magic__` {#the-__magic__-page}

El panel tiene una página propia para el espacio de nombres, en `/magic/`, enlazada desde los accesos rápidos del panel siempre que `__magic__` esté configurado o servido. Ahí es donde se ve la tabla, y es el único lugar donde se pueden alcanzar dos de sus estados.

Muestra cuántas filas están almacenadas (ubicaciones, tombstones y directorios, contados por separado), cuánto ocupan en disco el journal y el snapshot, cuánto de `sidecar_budget_mb` está usando el árbol de sidecars y el tamaño de todo `data/local`. Ese último número es el que hay que vigilar: un cliente que copia en lugar de mover deja ahí los bytes, así que si `data/local` crece hasta los gigas, algo está importando al revés. Las filas se agrupan por release. Una tabla muy grande se trunca en la página y lo indica con cuánto. Los contadores de arriba siempre se refieren a la tabla completa.

La lista de filas almacenadas muestra las primeras mil. Un \*arr deja un tombstone en cada importación, así que en una biblioteca organizada la mayoría de las filas quedan más allá de ese punto. Un cuadro de búsqueda en las páginas de filas almacenadas y de huérfanas encuentra un release por su nombre, por una ruta del montaje o por su hash, y lista todas las filas almacenadas de él con sus botones. `data/magic.json` no sirve para eso: zurg lo escribe desde memoria al parar, así que una fila que borres a mano de ese archivo mientras zurg se ejecuta vuelve a aparecer.

Hay tres botones, y todos hacen lo mismo: que una fila deje de existir.

- **Reset** en una ubicación: el archivo o la carpeta vuelve a donde la biblioteca lo pone.
- **Unhide** en un tombstone: la entrada vuelve a listarse en `__magic__`. Para ocultarla no se destruyó nada. Un release en `__all__` que nunca aparece en `__magic__/__all__`, ni siquiera tras borrarlo y volver a añadirlo, tiene un tombstone de release: las filas se indexan por su hash, que una nueva adición no cambia. Búscalo y haz Unhide en esa fila.
- **Delete** en una fila **huérfana**: una cuyo release, o cuyo archivo dentro de él, la biblioteca ya no tiene. Esa fila no resuelve a nada, así que no se puede listar, mover ni borrar a través del montaje. Se conserva en lugar de descartarla, porque si una reparación restaura el release, restaura también el sitio donde lo pusiste. Hasta esta página no había forma de limpiarlas. **Clear all dangling rows** las borra todas de una vez.

Los sidecars también aparecen listados. Los que **nothing accounts for any more** se muestran aparte del resto y se cuentan. Son el equivalente de una fila huérfana para los sidecars: un `.nfo` o un póster dejado junto a un release que ya salió de la biblioteca, o dentro de una carpeta cuya ubicación se ha olvidado. Siguen sirviéndose, porque un archivo real es lo último a lo que resuelve una ruta de `__magic__` y nada por encima de ellos reclama ya ese nombre. Lo único que ha desaparecido es la razón por la que se pusieron ahí. zurg nunca borra uno por su cuenta: un archivo dejado junto a un release que se borró sigue siendo tuyo, y una reparación que devuelva el release vuelve a asociar la carpeta. Un directorio que creaste tú para los sidecars, a través del montaje y no de zurg, se ve igual aquí, porque tampoco deja ninguna fila.

Borrar un sidecar desde la página elimina el archivo de verdad, igual que un `DELETE` a través del montaje. Cada botón cambia lo que el montaje tiene en caché para las rutas implicadas, porque el montaje guarda un listado de directorio durante doce horas con el polling desactivado.

Si el endpoint de SABnzbd está activado, la página también lista los trabajos que le han entregado: el id que el cliente conoce de cada uno, su categoría, si el release ya ha llegado a la biblioteca y la carpeta desde la que importar una vez llegue. Sonarr y Radarr eliminan sus propios trabajos. Un trabajo Failed o Stuck que ninguno de los dos va a eliminar nunca puede limpiarse desde la página. Eso ocurre cuando zurg ya no es su cliente de descargas. Consulta [sabnzbd.md](../guides/sonarr-radarr.md).

Los bloques `magic:` y `sabnzbd:` son editables por completo desde la [página de configuración](#sabnzbd-the-download-client-sonarr-and-radarr-see), y ambos muestran **Restart Required**, y lo dicen en serio: las rutas que sirven `__magic__` y el endpoint de SABnzbd se registran una sola vez, al arrancar, a partir de esos valores. Activar cualquiera de los dos lo escribe en `config.yml` y no cambia nada de la ejecución que ya estaba respondiendo. La página de `__magic__` también lo dice, en lugar de mostrar un espacio de nombres vacío.

### `sabnzbd`, el cliente de descargas que ven Sonarr y Radarr {#sabnzbd-the-download-client-sonarr-and-radarr-see}

zurg puede responder a Sonarr y Radarr como si fuera un SABnzbd. Ellos le pasan un NZB, zurg escribe el archivo en `nzbs/` para el backend de Usenet, y cuando el contenido ya está en la biblioteca, el trabajo aparece como **Completed** con una carpeta en `__magic__/__all__` desde la que importar. No hace falta descargar nada para importar: el \*arr renombra el archivo dentro del mount, que es una fila en la tabla `__magic__`.

Necesita las dos partes para ser útil: un proveedor `nzb` o `torbox_nzb` que se encargue del NZB, y `magic.enabled` para tener de dónde importar. Está desactivado hasta que lo pidas. La configuración completa, incluido lo que hay que poner en el \*arr, está en [docs/sabnzbd.md](../guides/sonarr-radarr.md).

| Opción | Tipo | Por defecto | Descripción |
|--------|------|-------------|-------------|
| `sabnzbd.enabled` | bool | `false` | Registra el endpoint en `/api` y `/sabnzbd/api`. Mientras esté desactivado, ninguna de las dos rutas existe. |
| `sabnzbd.api_key` | string | generada | Es lo único que protege el endpoint. Sonarr y Radarr no envían basic auth, así que estas rutas quedan fuera de ella y la clave hace su papel. Si se deja vacía con el bloque activado, zurg genera una, la guarda en `data/sabnzbd-apikey` para que sobreviva a un reinicio y la muestra en el log una vez al arrancar. |
| `sabnzbd.categories` | list | `[tv, movies]` | Las categorías que se reportan a los clientes. Todas apuntan al mismo directorio, así que esto solo sirve para que un cliente no avise de una categoría que no encuentra: añade lo que hayas configurado en el \*arr. `*` también se reporta siempre. |
| `sabnzbd.history_limit` | int | `60` | Cuántas entradas del historial leen Sonarr y Radarr. zurg mantiene los trabajos terminados más allá de este límite en la cola hasta que se libere un hueco, lo que pasa cuando el cliente borra uno o cuando uno lleva diez minutos sin borrarse mientras hay trabajos esperando. Ajústalo a `DownloadClientHistoryLimit` del cliente si lo subiste. `0` mantiene su valor por defecto de 60. |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__/__all__` | El directorio completado que se reporta a los clientes. Debe ser la ruta que **el \*arr** ve, que no es la de zurg cuando el \*arr corre en un contenedor que monta la biblioteca en otro sitio, y debe estar en el mismo volumen que las carpetas raíz, o cada importación será una copia. Consulta [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

La clave de API es toda la autenticación, así que trata el endpoint como tratas el resto del puerto de zurg: en una red de confianza, o detrás de algo que lo sea. No se puede usar basic auth con él: los clientes nunca la envían, y un 401 se le muestra al usuario como "unable to connect" en lugar de como un fallo de autenticación.

### `qbittorrent`, el cliente de descargas de torrents que ven Sonarr y Radarr {#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see}

zurg puede responder a Sonarr y Radarr como si fuera un qBittorrent. Ellos le pasan un magnet o un `.torrent`, y zurg añade el info hash a una cuenta de debrid. Cuando el release ya está en la biblioteca, el torrent aparece como **finished** con una carpeta en `__magic__/__all__` desde la que importar. Para importar no se descarga nada. El \*arr renombra el archivo dentro del mount, y eso es una fila en la tabla `__magic__`.

Para que sea útil hacen falta dos cosas. Una cuenta que pueda añadir torrents lee el magnet, y `magic.enabled` le da al \*arr un sitio desde el que importar. Está desactivado hasta que lo pidas. La configuración completa, incluido lo que hay que poner en el \*arr, está en [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md).

| Opción | Tipo | Por defecto | Descripción |
|--------|------|-------------|-------------|
| `qbittorrent.enabled` | bool | `false` | Registra el endpoint en `/api/v2` y `/qbittorrent/api/v2`. Mientras esté desactivado, ninguna de las dos rutas existe. |
| `qbittorrent.api_key` | string | generada | Es la única barrera del endpoint. Los clientes la envían como bearer token cuando su campo **API Key** está rellenado, y la aceptan como contraseña en `auth/login` cuando no lo está. Si se deja vacía con el bloque activado, zurg genera una, la guarda en `data/qbittorrent-apikey` para que sobreviva a un reinicio, y la escribe en el log una vez al arrancar. |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | Las categorías que se muestran a los clientes, las dos que traen por defecto los \*arr. Todas apuntan al mismo directorio, así que esto solo existe para evitar que un cliente avise de una categoría que no puede encontrar. |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__/__all__` | La save path que se muestra a los clientes, y la carpeta padre de todas las carpetas desde las que importan. Tiene que ser la ruta que **ve el \*arr**, que no es la de zurg cuando el \*arr corre en un contenedor que monta la biblioteca en otro sitio. Debe estar en el mismo volumen que las root folders, o cada importación será una copia; mira [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). Si usas los dos endpoints, pon `sabnzbd.complete_dir` con el mismo valor. |
| `qbittorrent.download_timeout_mins` | int | `15` | Cuánto puede tardar una descarga sin moverse (sin cambio de etapa y sin subida de progreso) antes de que se descarte esa cuenta y se pruebe la siguiente que acepte torrents. `0` significa solo cacheado: una descarga se acepta únicamente en una cuenta que ya tenga el contenido, y si no, se rechaza dentro del add, que es el único rechazo al que Sonarr y Radarr reaccionan. Un número negativo nunca se descarta. Mira [Timeouts and cached-only mode](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode). |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

Los quince minutos son una cifra medida, no elegida. AllDebrid deja un trabajo sano en su propia cola con todos los contadores a cero antes de mover un solo byte. En dos de dos ocasiones se quedó ahí 580 y 622 segundos. Las capturas están en [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md).

La cuenta a la que va una descarga la decide [`add_torrents`](#accounts) y el orden de la lista `providers:`. Una descarga que caducó o que una cuenta abandonó se borra de esa cuenta antes de probar la siguiente. Solo es candidata una instancia que zurg añadió por sí mismo para esa descarga y que nunca terminó. Nada más que responda este endpoint borra nada de una cuenta de debrid.

La API key es toda la autenticación. Trata el endpoint como tratas el resto del puerto de zurg. Ponlo en una red de confianza o detrás de algo que lo sea. La autenticación básica no sirve para este endpoint. Los clientes nunca la envían, y si reciben un 401 lo toman como un fallo de autenticación definitivo y nunca lo reintentan.

### El addon `stremio` {#the-stremio-addon}

zurg puede ser un addon de Stremio que busca en tus propios indexadores Newznab y reproduce a través del backend de Usenet. Necesita una cuenta de NZB, `nzb` o [`torbox_nzb`](../providers/torbox-nzb.md), y al menos un indexador. Con `torbox_nzb`, un release que TorBox ya tiene empieza dentro de la espera del addon si no hay otro post NZB en espera. Uno no cacheado tiene que terminar primero en TorBox, lo que tarda más de lo que espera un reproductor. Está desactivado hasta que lo pidas. La configuración y lo que hace una reproducción están en [stremio.md](../guides/stremio.md).

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|----------------|-------------|
| `stremio.enabled` | bool | `false` | Registra las rutas del addon bajo `/stremio/`. Mientras está desactivado, responden 404. |
| `stremio.token` | string | generado | El segmento de ruta que protege todas las rutas del addon. Es toda la autorización. Si se deja vacío, zurg genera uno y lo guarda en `data/stremio-token`. |
| `stremio.indexers` | list | `[]` | Endpoints Newznab donde buscar. Cada uno acepta `name`, `url`, `api_key` y un `api_path` opcional. |
| `stremio.max_results` | int | `10` | Cuántos releases conserva cada resolución después de ordenarlos. El límite es por resolución. Cada nivel conserva una variedad desde su release más grande hasta el más pequeño. `0` usa el predeterminado. |
| `stremio.search_limit` | int | `100` | Cuántos releases pide cada indexador por búsqueda. Todos los demás límites eligen entre lo que se pidió, así que es el techo de toda la respuesta. `0` usa el predeterminado. |
| `stremio.max_size_gb` | int | `0` | Descarta los releases más grandes que esto antes de ordenarlos, para un reproductor que no puede con un remux. `0`, el predeterminado, no descarta ninguno. Los releases sin tamaño indicado se conservan. |
| `stremio.cache_hours` | int | `24` | Cuánto tiempo se sirve una respuesta completa de cinco o más resultados desde `data/stremio-cache` antes de volver a preguntar a los indexadores. Las respuestas más cortas se guardan menos tiempo. Una respuesta vacía nunca se guarda. `0` usa el predeterminado. |

### Análisis de medios {#media-analysis}

| Opción | Tipo | Valor predeterminado | Descripción |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | Cuando true, zurg ejecuta automáticamente ffprobe en cada torrent recién añadido para extraer metadatos del medio (resolución, códecs, duración, pistas de audio y subtítulos). Estos metadatos alimentan los filtros de directorio basados en etiquetas, como `zurg_4k`, `zurg_aud_eng` y los niveles de duración. Desactívalo si no usas filtros basados en etiquetas o si quieres reducir el uso de CPU en las nuevas adiciones. |
| `ffprobe_binary` | string | `"ffprobe"` | Ruta al ejecutable de ffprobe. Solo hace falta si ffprobe no está en tu PATH del sistema. Se usa para el análisis de medios. |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. Salud y reparaciones (automatización) {#4-health--repairs-automation}

La sección «configúralo y olvídate». Controla cómo zurg mantiene tu biblioteca sana, detectando y arreglando torrents rotos de forma automática.

| Opción | Tipo | Por defecto | Descripción |
|--------|------|---------|-------------|
| `enable_repair` | bool | `true` | Activa la reparación automática de torrents. Si no lo configuras, significa que está activada. Cuando un torrent deja de estar disponible (por ejemplo, si se eliminó de la caché de RD), zurg intentará encontrar uno de reemplazo y añadirlo. En AllDebrid, también reinicia un magnet que falló por un motivo que un segundo intento puede arreglar, como no tener peers o un error del tracker, en lugar de dejarlo fallido. **Importante:** solo una instancia de zurg debería tener la reparación activada para evitar conflictos. Si esta opción y `delete_error_torrents` están desactivadas, zurg deja los torrents fallidos tal cual en tu cuenta y solo los registra en el log. |
| `repair_every_mins` | int | `60` | Cada cuántos minutos zurg busca torrents rotos que necesitan reparación. Valores más bajos detectan los problemas antes, pero aumentan el uso de la API. |
| `repair_timeout_mins` | int | `30` | Tiempo máximo (en minutos) que zurg espera a que termine una reparación. Si una reparación tarda más que esto, el torrent se marca como roto y se omite hasta el siguiente ciclo de reparación. |
| `stalled_download_mins` | int | `10` | Minutos mínimos antes de que una descarga en curso se considere estancada. El umbral real es `max(GB_downloaded, stalled_download_mins)`, así que las descargas grandes reciben más tiempo automáticamente. Aumenta este valor para torrents lentos o con pocos seeds (por ejemplo, de trackers públicos) que necesitan más tiempo para completarse. |
| `restrict_repair_to_cached` | bool | `false` | Si es true, zurg solo usa para las reparaciones torrents que ya están en caché de Real-Debrid. Así las reparaciones son más rápidas (no hay que esperar descargas), pero pueden fallar si no hay ninguna alternativa en caché. Si es false, zurg puede añadir torrents sin caché, que necesitan tiempo para descargarse. |
| `only_full_torrent_repair` | bool | `false` | Si es true, la reparación vuelve a insertar el torrent completo con su selección de archivos original, o se rinde. Si ese primer paso falla, el torrent se marca como roto de inmediato, sin pasar por las estrategias de archivo comprimido y de archivo por archivo que se aplicarían si no.|
| `check_for_changes_every_secs` | int | `15` | Cada cuántos segundos zurg consulta Real-Debrid para detectar cambios en la biblioteca (torrents nuevos, eliminados o cambios de estado). Valores más bajos hacen que tu servidor multimedia se actualice más rápido, pero generan más llamadas a la API. |
| `library_resync_every_mins` | int | `10` | Cada cuántos minutos se reconstruye la comprobación de cambios a partir de un listado completo en lugar de una sonda ligera. Es una red de seguridad que detecta desajustes que una sonda puede pasar por alto. No es la frecuencia con la que zurg consulta. Real-Debrid sigue su propio camino e ignora esta opción. |
| `library_detail` | string | `resident` | `resident` mantiene los detalles de los archivos en memoria. `lazy` libera los detalles inactivos. `auto` libera los detalles inactivos solo cuando hay presión de memoria sostenida. Todos los proveedores comparten esta política para toda la instancia. Requiere reiniciar. Consulta [Detalle de la biblioteca](#library-detail). |
| `library_detail_idle_secs` | int | `300` | Tiempo mínimo sin lecturas de detalle antes de que `lazy` o `auto` puedan liberar una tabla. La limpieza se ejecuta cada 30 segundos. Se ignora con `resident`; los valores cero o no válidos usan 300. Requiere reiniciar. |
| `downloads_every_mins` | int | `720` | Cada cuántos minutos zurg vuelve a obtener tus descargas de RD (enlaces sin restricciones, enlaces de file locker) y las monta. Son descargas de RD que no son torrents. |
| `delete_error_torrents` | bool | `false` | Si es true, zurg elimina automáticamente de RD los torrents que están en estado de error (por ejemplo, torrents muertos que no se pueden descargar). Así tu biblioteca de RD queda limpia, pero el torrent se borra de forma permanente. En AllDebrid, un magnet fallido que un segundo intento puede arreglar se reinicia en lugar de borrarse, incluso con la reparación desactivada, y solo se borra si el reinicio no ayuda. |
| `on_library_update` | string | `""` | Un comando de shell que se ejecuta cada vez que zurg detecta cambios en la biblioteca. La ruta de cada directorio cambiado se pasa como argumento. Se usa habitualmente para lanzar escaneos de la biblioteca de Plex/Jellyfin en carpetas concretas y actualizar más rápido. |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
library_detail: resident
library_detail_idle_secs: 300
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

### Reparar entre cuentas {#repairing-across-accounts}

Cada otra estrategia de reparación vuelve a añadir un release a la cuenta de la que salió, y eso es lo correcto mientras esa cuenta siga pudiendo producir el contenido. Para un caso concreto, en cambio, no es lo correcto.

Los servicios mantienen cachés independientes. Un release que Real-Debrid ha purgado, o que rechaza solo por el nombre del archivo, puede estar en caché en AllDebrid en este mismo momento, bajo el mismo info hash. El release no tiene nada malo. Lo que falla es la cuenta.

Así que cuando todas las cuentas que tienen un release han renunciado a él, zurg lo ofrece a las cuentas configuradas que no lo tienen, en el orden en que aparecen en tu bloque `providers`. La primera que ya lo tiene en caché lo acepta, zurg lista esa cuenta y el release gana una segunda copia como cualquier release de varias cuentas: sus propios ids de archivo, sus propios enlaces y failover de lectura entre las dos. El veredicto de la entrada se borra solo en cuanto exista una copia que se pueda reparar.

No hay ningún ajuste. Configurar una segunda cuenta es la decisión, y zurg ya la lista, sirve desde ella y hace failover de lecturas hacia ella. Preguntarle por un release que la primera cuenta no puede producir es lo mismo dentro de ese esquema. Sigue a `enable_repair` como cualquier otra reparación.

El botón de reparación de un release también hace esto, y en el orden correcto: primero reintenta la cuenta que tiene el release, exactamente como siempre, y solo ofrece el release a otras cuentas si ese intento falla. Es el único camino que funciona con el barrido de reparación completamente desactivado.

Lo que evita que esto se convierta en un bucle de añadidos es la forma de la oferta, no un interruptor:

- **A una cuenta solo se le entrega contenido que ya tiene.** La oferta es un añadido que se retira y se borra otra vez salvo que la cuenta lo complete en quince segundos. Una cuenta que tendría que descargar el release desde el swarm queda exactamente como la encontró, sin gastar cuota de transferencia. Esto es una reparación, nunca una nueva descarga. `restrict_repair_to_cached` no controla esto y nunca se lee aquí: esa clave es sobre una cuenta que repara su propia copia, y este camino es solo para caché sea cual sea su valor.
- **Solo un release que nada puede servir.** Un release que funciona nunca se copia, ni tampoco uno al que la reparación todavía no haya renunciado.
- **Una cuenta que dice que no se le pregunta cada vez menos.** La espera tras un fallo empieza en un día y se duplica con cada nuevo fallo, hasta unas dos semanas. Un release que solo está fuera de caché esta semana se vuelve a encontrar en cuestión de días; uno que se ha ido para siempre se convierte en una consulta quincenal. Sin ese decaimiento, always-on significaría un añadido diario para cada release muerto en cada cuenta, para siempre.
- **Como máximo diez releases por barrido**, así que el primer barrido tras añadir una segunda cuenta procesa el trabajo acumulado a lo largo de horas y no en una sola ráfaga.

Una cuenta que ya tiene una copia del release nunca recibe una segunda instancia de él, por muy rota que esté la copia que tiene: las estrategias de reparación se ocupan de esa cuenta, y en Real-Debrid un añadido duplicado nunca llega a descargarse. Los releases cuya clave no es un info hash de bittorrent, que es como el backend de Usenet identifica los suyos, nunca se ofrecen a nadie.

Este es el único punto en el que zurg añade contenido a una cuenta cuyo contenido caduca sin que nadie lo pida. La reparación no vuelve a añadir un release a una cuenta así por temporizador, porque volver a descargar contenido que el servicio ha retirado deliberadamente es el patrón que esos servicios llaman abuso. Una oferta en caché no es eso: no se descarga nada, no se gasta cuota, y el contenido que se reclama ya está en la caché del servicio porque alguien más lo puso allí.

### Detalle de la biblioteca {#library-detail}

**`library_detail: resident` sigue siendo el valor por defecto.** Elige un modo y el tiempo de inactividad en la página de configuración del panel o en `config.yml`. Ambos ajustes se aplican tras reiniciar zurg; guardarlos no cambia parcialmente una biblioteca que ya está en marcha. La política se aplica a todos los proveedores de la instancia.

| Modo | Comportamiento | Compromiso |
|---|---|---|
| `resident` | Mantiene en memoria los detalles de archivos de cada release. | Acceso predecible y sin recargas de detalles; mayor memoria retenida. |
| `lazy` | Libera los detalles tras `library_detail_idle_secs` sin uso. | Reduce la memoria en reposo aunque haya RAM de sobra; acceder a detalles fríos implica una recarga. |
| `auto` | Mantiene los detalles mientras haya memoria disponible y libera las tablas inactivas más antiguas cuando hay presión sostenida. | Responde a las condiciones en tiempo de ejecución; añade monitorización de presión y una latencia de recarga menos predecible. |

Los nombres, tamaños, renombrados y visibilidad siguen disponibles para los listados en todos los modos. Al abrir o reparar un archivo, los detalles liberados se reconstruyen bajo demanda. `auto` no recarga toda la biblioteca de golpe cuando la presión termina: los detalles vuelven a cargarse según se usen y permanecen residentes hasta que la presión y la ventana de inactividad permitan volver a liberarlos.

#### Detección automática de presión {#automatic-pressure-detection}

`auto` toma una muestra cada 30 segundos. Dos lecturas separadas al menos 30 segundos y que estén en o por encima del **90%** de un presupuesto medido inician la expulsión, en lotes de como máximo **128 tablas inactivas** por barrido. La expulsión sigue hasta que el uso llegue al **80%** o menos, y luego hace una pausa de al menos un minuto antes de considerar un nuevo episodio. Los picos breves no inician la expulsión. La ventana de inactividad configurada siempre se aplica.

La lectura más ajustada disponible es la que decide:

- **Memoria del host:** total menos memoria disponible, incluyendo la estimación del sistema operativo sobre las cachés recuperables. Una caché de sistema de archivos llena por sí sola no es escasez de RAM.
- **Contenedores Linux y límites de servicio:** cgroup v2 `memory.max` y `memory.high`, o v1 `memory.limit_in_bytes`, junto con el uso propio de cada ancestro visible. La caché de archivos fría se descuenta. Los límites del contenedor se vuelven a leer en tiempo de ejecución; los namespaces de cgroup privados pueden ocultar límites por encima de la raíz visible.
- **Un presupuesto de runtime explícito:** un `memory_limit_mb` positivo, en MiB, se compara con la memoria gestionada por Go. `GOMEMLIMIT`, cuando está definido, tiene prioridad; `GOMEMLIMIT=off` desactiva esta señal en particular. La presión del host y del contenedor sigue aplicando. El techo automático de Go derivado de las cachés de Usenet se ignora porque sube con el heap en vivo y no mide la RAM disponible.

No hace falta un presupuesto adicional para activar `auto`:

```yaml
library_detail: auto
library_detail_idle_secs: 300
# Optional explicit Go runtime budget, also used by the collector:
# memory_limit_mb: 1024
```

Sin una medición utilizable, la expulsión automática se pausa.

Esto es una optimización de memoria gradual, **no un límite de memoria estricto**: los archivos activos, los cambios sin guardar, las instantáneas de recuperación y otras cachés pueden dominar la memoria, y los picos repentinos de asignación pueden superar al barrido. `memory_limit_mb` sigue siendo un límite blando del recolector; ponerlo por debajo de los datos en vivo puede provocar una recolección de basura excesiva.

#### Integridad de datos y costo {#data-integrity-and-cost}

Al desalojar, se conserva una **instantánea de recuperación comprimida** además del volcado existente `data/*.zurgtorrent`. Al recargar desde disco, debe coincidir con esa instantánea. Si el volcado falta, está dañado o ha sido reemplazado, zurg restaura la instantánea, mantiene el release en memoria y vuelve a intentar guardar los datos recuperados. `auto` también vuelve a intentar guardar las tablas sucias inactivas cuando la presión ha terminado, con una pasada de guardado aparte y acotada. Las escrituras de archivos y los cambios de estado recuperan la propiedad de inmediato, incluidas las escrituras a través de un puntero que un stream mantiene durante el desalojo. Los guardados fallidos dejan los cambios en memoria y marcados como pendientes. Las escrituras solapadas no son confirmadas por un guardado anterior. Aun así, hace falta un guardado exitoso para que los cambios sobrevivan al cierre del proceso.

Medido en un Mac con Apple Silicon y Go 1.26.4, usando 500 releases por tipo a través de las rutas de conversión y persistencia, incluida la instantánea de recuperación:

| Tipo | Bytes resident/entrada | Bytes lazy/entrada | Reducción | Reconstrucción media |
|---|---:|---:|---:|---:|
| Película de Real-Debrid, 3 archivos | 3,662 | 2,845 | 22% | 88 µs |
| Pack de temporada de Real-Debrid, 24 archivos | 15,670 | 7,366 | 53% | 371 µs |
| TorBox, 2 archivos | 3,019 | 2,680 | 11% | 56 µs |
| AllDebrid, 1 archivo | 2,580 | 2,516 | 2% | 55 µs |
| Conjunto RAR, 7 volúmenes | 5,343 | 3,303 | 38% | 109 µs |

Estas son cifras de heap retenido por release, no el RSS de todo el proceso. Las reconstrucciones leen archivos locales escritos recientemente; el almacenamiento frío o remoto puede tardar más. Elige `lazy` para una recuperación de memoria idle constante, o `auto` para recuperarla solo bajo presión. Mantén `resident` cuando el acceso predecible importe más que la RAM. Los releases pequeños ahorran poco, y la instantánea de recuperación gasta memoria a propósito para proteger los datos. Estas medidas describen las entradas desalojadas tanto en `lazy` como en `auto`; el modo automático puede retener más entradas en un momento dado.

## 5. Red y conectividad (técnico) {#5-network--connectivity-technical}

Ajustes de infraestructura que controlan cómo zurg se enlaza, se autentica y se conecta a la red.

### Enlace del servidor {#server-binding}

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `host` | string | `"[::]"` | La interfaz de red a la que se conecta. `[::]` escucha en todas las interfaces (IPv4 e IPv6). Usa `0.0.0.0` si solo quieres IPv4, o una IP específica para restringir el acceso a una sola interfaz. |
| `port` | string | `"9999"` | El puerto en el que escucha zurg. Si defines la variable de entorno `PORT`, reemplaza este valor, lo cual es útil en despliegues con contenedores. |

```yaml
host: "[::]"
port: 9999
```

### Conexiones precalentadas {#warm-connections}

Abrir una conexión a un servicio debrid es caro, pero usarla es casi gratis. Medido desde un host en vivo el 2026-08-29, una conexión nueva a un host de descarga de Real-Debrid cuesta un viaje de ida y vuelta TCP y luego 68–85 ms de handshake TLS, todo antes de que se pida un solo byte del archivo. Además, el transporte HTTP de zurg no abre nada hasta que una lectura lo necesita, y cierra una conexión sin usar tras 90 segundos. En una biblioteca que no esté muy ocupada, la lectura que llega después de un rato tranquilo paga ese coste en el propio camino del espectador.

Un warm floor saca ese coste de ese camino: cada cuenta mantiene un número indicado de conexiones ya marcadas y con handshake hecho antes de que haga falta, así que el transporte tiene una lista cuando llega una lectura.

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|----------------|-------------|
| `warm_connections` | int | *(sin definir)* | El mínimo para cada cuenta que no indique el suyo propio. Si no está definido, cada backend mantiene su valor predeterminado: 1 por host para una cuenta debrid, 2 por cuenta para una cuenta de noticias. `-1` desactiva el calentamiento en todas partes. El `warm_connections` propio de una cuenta siempre prevalece, incluso sobre un `-1` global. |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**Cuánto te aporta depende del host, y en los servicios debrid es menos de lo que parece.** Una conexión que no ha enviado nada es lo primero que cierran estos servicios, y lo hacen rápido. Medido desde un host en vivo el 2026-08-29, manteniendo abierta una conexión silenciosa y esperando a que el servidor la cerrara:

| Host | Conexión silenciosa | Tras servir una petición |
|---|---|---|
| un host de descarga de Real-Debrid | cerrada tras 30s | cerrada al instante |
| `api.alldebrid.com` | cerrada tras 15s | aún abierta a los 4 min |
| `api.torbox.app` | cerrada tras 15s | aún abierta a los 4 min |
| `api.real-debrid.com` | cerrada tras 4s | cerrada tras 5s |

Así que un warm floor solo merece la pena en un host de descarga, y poco más. La API de Real-Debrid no se puede calentar en absoluto: ningún suelo puede ganar a un cierre a los cuatro segundos sin generar tráfico para mantener viva la conexión, y zurg no hará eso. En lugar de asumirlo, **el floor mide**: cierra sus propias conexiones a los 15 segundos y comprueba si cada una seguía viva en ese momento. Un host que sigue cerrándolas antes de que una lectura pueda usarlas queda descartado, y sus lecturas se abren como siempre. No hay que configurar nada para eso, y un floor sin usar en una biblioteca tranquila no se confunde con ese caso.

Hay dos cosas más que conviene saber antes de subirlo:

- **El floor de una cuenta debrid es por host, y el de una cuenta de noticias es por cuenta.** Una cuenta debrid se conecta a través de muchos hosts: un nombre de API y un host de entrega por cada enlace. Cuáles son no se puede saber hasta que se ha generado un enlace, así que los hosts que se mantienen calientes son los que la cuenta ha usado de verdad. Se mantienen como máximo 16 a la vez, y uno sin usar durante 10 minutos se retira. Una cuenta de noticias es un solo host, indicado en la configuración, y mantiene su sesión mientras lo permita el plan. Por eso su floor es el que de forma fiable compensa. Consulta [Usenet](../guides/usenet.md).
- **Las conexiones calientes son conexiones reales y cuentan contra el límite por host que el proveedor controla:** 32 en Real-Debrid y AllDebrid, 20 en TorBox. Por eso el floor debrid está limitado a 4: un floor de ese tamaño deja el límite prácticamente intacto, mientras que uno grande lo gastaría en sockets que no transportan nada.

El floor se desactiva cuando `proxy` está definido. Un proxy HTTP o SOCKS hace que zurg se conecte al proxy en lugar de al host, y no hay nada al otro lado que merezca la pena mantener abierto.

### Autenticación y proxy {#authentication--proxy}

| Option | Type | Default | Descripción |
|--------|------|---------|-------------|
| `username` | string | `""` | Nombre de usuario para la autenticación básica HTTP. Si lo configuras junto con `password`, todas las peticiones a zurg (panel, WebDAV, API) pedirán autenticación. Déjalo vacío para desactivar la autenticación. |
| `password` | string | `""` | Contraseña para la autenticación básica HTTP. Debe configurarse junto con `username`. |
| `proxy` | string | `""` | Envía todo el tráfico de red saliente de zurg a través de un proxy. Admite los protocolos `http://`, `https://` y `socks5://`. Es útil si tu ISP bloquea o limita el tráfico de Real-Debrid. Ejemplo: `socks5://user:pass@host:port`. Si esta clave está vacía, se usa la variable de entorno `PROXY`. |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Ajustes de rclone {#rclone-settings}

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | Cuando está en true, zurg gestiona un montaje de rclone automáticamente. Así no tienes que ejecutar rclone por separado: zurg lo arranca, lo vigila y lo reinicia cuando hace falta. El montaje usa `mount_path` como punto de montaje. |
| `rclone_binary` | string | `"rclone"` | Ruta al ejecutable de rclone. Solo hace falta si rclone no está en tu PATH del sistema. |
| `rclone_extra_args` | list | `[]` | Flags adicionales de línea de comandos que se pasan al comando de montaje de rclone. Úsalo para sobrescribir los valores VFS predeterminados optimizados por benchmark de zurg (mira la tabla de abajo). Cada entrada es una sola cadena de flag. Los ajustes RC y los flags de backend `--union-*`/`--webdav-*` no se aceptan: zurg los construye él mismo, y un flag tendría prioridad sobre lo que construye (`union_writable` dejaría de describir el montaje). |
| `mount_read_only` | bool | `false` | Cuando está en true, el montaje se inicia con `--read-only` de rclone, así que el kernel rechaza una escritura antes de que llegue a zurg. Nada más controla un DELETE de montaje, así que esta es la única forma de rechazarlo, aunque no cubre a los clientes que hablan directamente con el endpoint WebDAV. Además, evita que una escritura accidental acabe en el upstream local de la unión del montaje. Puedes sobrescribirlo por flag con `rclone_extra_args: ["--read-only=false"]`. |
| `rclone_cache_reclaim` | bool | `true` | Si zurg borra los árboles de caché VFS que dejó una configuración anterior del montaje. rclone nombra su caché según el remoto, y ese nombre es un hash de los upstreams de la unión, que contienen la ruta absoluta de `data/local`. Así que si mueves el directorio de zurg o cambias `union_writable`, el nombre de la caché cambia y deja el árbol antiguo en un sitio donde ningún límite lo cuenta ni ningún limpiador lo visita. Al arrancar el montaje, zurg le pregunta a rclone en ejecución qué árbol está activo y elimina el resto, registrando lo que liberó. No hace nada salvo que el árbol activo esté donde rclone dice que está, y omite la limpieza por completo cuando `rclone_extra_args` define `--cache-dir`. Ponlo en `false` si quieres conservar todos los árboles abandonados. Consulta [Disco que usa el montaje](#disk-the-mount-uses). |
| `union_writable` | string | `"local"` | Qué lado de la unión del montaje embebido recibe un archivo nuevo al crearlo. `local`, el predeterminado, lo escribe directamente en el upstream local (`data/local`) sin que zurg lo vea. `server` pone primero el upstream WebDAV, así que la creación llega a zurg: se rechaza fuera de `__magic__` y dentro se escribe como sidecar con tamaño limitado. Una escritura rechazada nunca llega al disco: la caché VFS de rclone la acepta y reintenta la subida con un backoff, así que queda acotada por el límite de la caché y se ve en `logs/rclone.log`. Con el orden local, esos bytes irían a `data/local` sin límite. Un detalle medido con `server`: renombrar un archivo sidecar a través del montaje puede devolver un error (el archivo es visible en ambos upstreams, y rclone aplica el movimiento a cada uno). Los movimientos de release dentro de `__magic__` (la ruta de importación de \*arr) no se ven afectados. Cambiar a `server` solo afecta a dónde van las *nuevas* creaciones, nada más: lo que el orden local ya escribió en `data/local` se queda ahí hasta que lo borres. La línea que zurg registra al arrancar indica el modo activo (`new files go to zurg over WebDAV (union_writable: server)`), así que es lo que hay que comprobar, no la presencia de la ruta `data/local`, que forma parte de la unión en cualquiera de los dos órdenes. |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
rclone_cache_reclaim: true
union_writable: "local"
```

#### Valores predeterminados optimizados por benchmark {#benchmark-optimized-defaults}

zurg usa ajustes de VFS de rclone probados con benchmarks y optimizados para el rendimiento en streaming:

| Ajuste | Por defecto | Por qué |
|---------|---------|-----|
| `--buffer-size` | 256M | Buffer grande para un streaming fluido |
| `--vfs-read-chunk-size` | 32M | Cuánto tarda una lectura nueva en coger velocidad. El primer trozo se pide con este tamaño y luego se duplica, así que con 4M una lectura desde un offset frío pasaba casi toda su vida por debajo de la velocidad de línea. Es un tamaño de petición, no una transferencia forzada: rclone sigue parando de descargar cuando el lector para. |
| `--vfs-read-chunk-size-limit` | 512M | Hasta dónde llega el duplicado de arriba. El chunking está activo por defecto, así que este valor es un techo al que llega la rampa, no algo que un override active. |
| `--vfs-read-ahead` | 128M | Equilibrio entre eficiencia de buffer y de ancho de banda |
| `--max-read-ahead` | 1M | Un buffer pequeño del kernel de FUSE reduce las lecturas pequeñas. No se pasa en Windows. |
| `--vfs-read-wait` | 5ms | Crítico: valores más altos causan ralentizaciones graves |
| `--vfs-cache-mode` | full | Caché completa para el mejor rendimiento. No siempre es la mejor opción para un reproductor que lee el montaje a través de un share; consulta [Cuándo la caché cuesta más de lo que aporta](#when-the-cache-costs-more-than-it-buys). |
| `--vfs-cache-max-size` | 256G | Límite máximo de la caché VFS en disco. No es una clave de configuración: sobrescríbelo con `rclone_extra_args`. |
| `--vfs-cache-min-free-space` | 10G | Deja de cachear antes de que el disco de caché se llene |
| `--vfs-cache-max-age` | 72h | Cuánto tiempo se conserva un archivo cacheado que nadie ha tocado. «Tocado» es la palabra clave, y un servidor de medios casi nunca deja nada sin tocar; consulta [Disco que usa el montaje](#disk-the-mount-uses). |
| `--vfs-cache-poll-interval` | 1m | Actualizaciones de caché rápidas |
| `--vfs-fast-fingerprint` | on | Identifica los archivos sin calcular hashes |
| `--dir-cache-time` | 12h | Los listados se mantienen durante horas; zurg olvida las entradas afectadas a través de la API RC cuando la biblioteca cambia, así las búsquedas de los servidores de medios siguen calientes |
| `--attr-timeout` | 60s | Los archivos de la biblioteca son inmutables, y los cambios de estado olvidan explícitamente las entradas afectadas. Limitado para que un tamaño desactualizado no sobreviva a una pasada de escaneo. |
| `--poll-interval` | 0 | Detectar cambios es tarea de zurg, no de rclone |
| `--timeout` | 5m | Timeout de E/S por inactividad |
| `--no-modtime` / `--no-checksum` | on | Ninguno tiene sentido en una biblioteca de debrid, y pedirlos cuesta peticiones |
| `--async-read` | valor por defecto de rclone (on), no se pasa | zurg no pone este flag en la línea de comandos, y rclone lo tiene en true por defecto, así que el montaje lee de forma asíncrona, y todas las cifras de esta página se midieron así. Un campo de ajuste llegó a decir que lo desactivaba; lo único que hacía era añadir el flag suelto, que establece el valor por defecto que ya tenía. Para desactivarlo de verdad: `rclone_extra_args: ["--async-read=false"]`. |
| `--low-level-retries` | 3 | El downloader VFS de rclone ya reinicia una lectura fallida diez veces por apertura, y cada reinicio lo reintenta el pacer del backend este número de veces. Con el valor por defecto de rclone, 10, serían 100 peticiones por cada apertura de un archivo al que zurg responde 503 a propósito. |
| `--retries` | 1 | Presupuesto del comando completo; en un montaje que nunca termina solo multiplica un fallo de arranque |
| `--vfs-handle-caching` | 0, con rclone 1.74+ | rclone 1.74 empezó a mantener vivos los downloaders de un archivo durante cinco segundos tras el último cierre, así que tocar un archivo cuesta cinco segundos de lo que el enlace pueda transportar, no de lo que se leyó: medido contra un servidor de 50 MB/s, una lectura de 1 MiB descargó 245-250 MiB en lugar de 3-6 MiB, y un barrido de veinte archivos pasó de 80 MiB a 4.2 GiB. El periodo de gracia existe para `serve nfs`, que zurg nunca ejecuta. Las versiones antiguas de rclone no tienen ese flag y se niegan a arrancar con uno desconocido, así que zurg primero le pregunta a binario su versión y no pasa nada por debajo de 1.74. |
| `--log-level` | NOTICE | Nivel de detalle propio de rclone, siempre se pasa |
| `--cache-dir` | `data/rclone-cache` | Se resuelve respecto al directorio de trabajo |
| `--log-file` | `logs/rclone.log` | Se resuelve respecto al directorio de trabajo |

`--vfs-cache-max-size`, `--vfs-cache-min-free-space`, `--low-level-retries`, `--retries`, `--vfs-handle-caching`, `--log-level`, `--cache-dir` y `--log-file` son constantes en `internal/rclone/manager.go`; el resto de filas vienen de `tuneVFSOptions` en `internal/rclone/tuning.go`, incluidos `--vfs-cache-max-age` y `--vfs-cache-poll-interval`, a pesar de sus nombres.

### Disco que usa el montaje {#disk-the-mount-uses}

`--vfs-cache-mode full` significa que un archivo leído a través del montaje se descarga **completo** en `data/rclone-cache` y se queda ahí después de que termina la reproducción. No es un búfer temporal de reproducción que se vacía cuando el video se detiene. Si lo dejas como está, la caché crece hasta `--vfs-cache-max-size`, que por defecto es **256G**, y se queda en ese tamaño.

Se supone que dos límites la acotan, pero en la práctica solo uno funciona:

- `--vfs-cache-max-size` (256G) es el límite real. Ponlo en no más de la mitad del espacio libre del disco donde está `data/`.
- `--vfs-cache-max-age` (72h) elimina un archivo que nadie ha tocado durante tres días. rclone mide esto con su propio registro en `data/rclone-cache/vfsMeta/`, no con el atime del sistema de archivos, y **cualquier cosa que lea la biblioteca lo renueva**. Un servidor Plex con tareas programadas activadas lee cada archivo en ccaché durante su ventana de mantenimiento nocturno. Así, el 2026-09-09, una instancia cuya caché tenía 362 archivos tenía un ATime de esa misma mañana en todos ellos. Nada había expirado en meses, y nunca expiraría. No planifiques con la eliminación por antigüedad; planifica con el límite de tamaño.

Reduce el límite con `rclone_extra_args`:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`--vfs-cache-min-free-space` (10G por defecto) detiene la caché cuando el disco se llena hasta ese punto. Mantenlo bien por encima de cero en un disco que compartes con otras cosas.

Para recuperar la caché a mano, detén primero zurg y luego vacía ambos árboles:

```bash
rm -rf data/rclone-cache/vfs/* data/rclone-cache/vfsMeta/*
```

Mídelo con `du -sh data/rclone-cache`. Las entradas descargadas parcialmente son archivos dispersos (sparse), así que un tamaño que cuenta bytes aparentes reporta mucho más de lo que el disco realmente ocupa.

#### Cuando la caché cuesta más de lo que aporta {#when-the-cache-costs-more-than-it-buys}

Un `full` es la opción por defecto correcta para un servidor multimedia en el mismo host: lee un archivo una sola vez, y todo lo que viene después es local. No es automáticamente lo correcto para un reproductor de hardware que lee el mount a través de un recurso compartido de archivos.

Con `full`, una lectura tiene que quedar escrita en disco antes de llegar al lector, y lo que se descarga es el archivo entero, no la parte que se está viendo. Pon un recurso compartido delante de eso y un solo disco está sirviendo al reproductor mientras rclone todavía le escribe. Un reproductor Zidoo que leía un recurso compartido de Windows se entrecortaba en cada título hasta que se desactivó la caché, y reproducía bien después (reportado el 2026-08-30). El mecanismo de arriba es la lectura plausible de ese reporte y no algo medido aquí, así que tómalo como lo primero que probar cuando un cliente que lee directamente se entrecorta en un mount que un servidor multimedia en el mismo host reproduce sin problemas:

```yaml
rclone_extra_args:
  - "--vfs-cache-mode"
  - "off"
```

Lo que se pierde es real. Sin copia local, un seek vuelve a leer desde el proveedor, una segunda reproducción descarga el archivo otra vez, y nada sobrevive a un reinicio. También cambia lo que el mount acepta como escritura, así que deja el valor por defecto en un host donde un \*arr importa a través del mount; consulta [qbittorrent.md](../guides/sonarr-radarr-torrents.md).

#### Cachés abandonadas tras un traslado {#caches-stranded-by-a-move}

rclone nombra su caché según el remote que está cacheando, y ese nombre lleva un hash de la configuración del remote. El remote de zurg es un union cuyos upstreams incluyen la ruta absoluta de `data/local`, así que el nombre cambia cuando cambia la configuración:

| Upstreams del union | Árbol de caché |
|---|---|
| `/home/you/zurg/data/local :webdav:` | `vfs/zurg{QaSkn}` |
| `:webdav: /home/you/zurg/data/local` (`union_writable: server`) | `vfs/zurg{HdSp7}` |
| `/other/root/data/local :webdav:` (zurg movido) | `vfs/zurg{Psid2}` |

rclone solo lleva la cuenta del árbol que está usando. Un árbol con un nombre viejo no cuenta para ningún límite, ningún limpiador lo revisa y nada lo borra. Así que mover el directorio de zurg, o un disco externo que vuelve con otro punto de montaje, deja una caché entera abandonada. Si pasa varias veces, una instalación con un límite de 256G termina ocupando varios terabytes.

zurg recupera esos árboles al iniciar el montaje: le pregunta a rclone en ejecución cuál árbol está activo, borra el resto y registra lo que liberó. No hace nada si el árbol activo no está en el disco donde rclone dice que está, y se salta la limpieza por completo cuando `rclone_extra_args` define `--cache-dir`, porque un directorio que tú elegiste puede estar compartido con otro zurg. Pon `rclone_cache_reclaim: false` para desactivarlo y conservar todos los árboles abandonados.

En Linux, la plataforma añade cuatro opciones más: `--allow-other` y `--allow-non-empty` siempre, y `--uid` y `--gid` solo cuando se pueden leer los ids del usuario que ejecuta el proceso. `--max-read-ahead` se pasa en todas las plataformas excepto Windows, y `--read-only` siempre que [`mount_read_only`](#rclone-settings) esté activado.

Los valores de buffer y de espera de lectura se determinaron con pruebas de rendimiento en una conexión de 600 Mbps, logrando unos ~533 Mbps con la caché fría y ~235 ms de TTFB. El tamaño de bloque de lectura se volvió a medir después en un host de ~70 MB/s: en pares y de forma intercalada, la mediana de velocidad pasó de 49.1 a 56.5 MB/s en Real-Debrid al cambiarlo de 4M a 32M, y en TorBox se comportó igual.

**Sobrescribe los valores por defecto** usando `rclone_extra_args`:
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

Las flags de RC (`--rc`, `--rc-addr` y cualquier otra que empiece por `rc-`) se rechazan: zurg ejecuta el control remoto de rclone por su cuenta para invalidar la caché del VFS cuando cambia la biblioteca.

### User Agent y red {#user-agent--network}

| Opción | Tipo | Predeterminado | Descripción |
|--------|------|---------|-------------|
| `user_agent` | string | Chrome UA | User-Agent HTTP compartido para proveedores, indexadores, ffprobe e integraciones salientes. Si lo dejas vacío, se usa el User-Agent genérico del navegador. Los valores personalizados se envían tal cual los escribas. Requiere reiniciar. Consulta [identidad de las solicitudes salientes](outbound-identity.md). |
| `omit_user_agent` | boolean | `false` | Elimina el User-Agent HTTP (ffprobe usa un valor vacío), anulando `user_agent`. Las solicitudes a GitHub siguen enviando uno, porque GitHub rechaza las solicitudes sin él. Requiere reiniciar. |
| `outbound_client_name` | string | `"Media Client"` | Nombre del producto o cliente para las integraciones con servidores multimedia, cuando sea compatible. Si lo dejas vacío, se usa el valor predeterminado. Requiere reiniciar. |
| `outbound_client_id` | string | `"media-client"` | Identificador del cliente de Plex, incluido el inicio de sesión para las integraciones con servidores multimedia, cuando sea compatible. Si lo dejas vacío, se usa el valor predeterminado. Requiere reiniciar. |
| `outbound_client_version` | string | `"1.0"` | Versión del cliente para las integraciones con servidores multimedia, cuando sea compatible. Si lo dejas vacío, se usa el valor predeterminado. Requiere reiniciar. |
| `outbound_device_name` | string | `"Media Client"` | Nombre del dispositivo para las integraciones con servidores multimedia, cuando sea compatible. Si lo dejas vacío, se usa el valor predeterminado. Requiere reiniciar. |
| `outbound_device_id` | string | `"media-client"` | Identificador del dispositivo de Jellyfin/Emby para las integraciones con servidores multimedia, cuando sea compatible. Si lo dejas vacío, se usa el valor predeterminado. Requiere reiniciar. |
| `outbound_platform` | string | `"Desktop"` | Plataforma de Plex para las integraciones con servidores multimedia, cuando sea compatible. Si lo dejas vacío, se usa el valor predeterminado. Requiere reiniciar. |
| `force_ipv6` | bool | `false` | Obliga a que todas las pruebas de red y la selección de hosts de zurg usen IPv6. Actívalo si tu red tiene mejor conectividad IPv6 con los servidores de RD (por ejemplo, algunos ISP limitan IPv4 pero no IPv6). |
| `unrestrict_ip` | string | `""` | La dirección IP que se envía a RD al desbloquear los enlaces de descarga. Es útil en configuraciones con varias redes, cuando quieres que las descargas se generen para una IP concreta (por ejemplo, la IP de salida de una VPN) en lugar de la IP donde se ejecuta zurg. |
| `dns_servers` | list | `[]` (DNS del sistema) | Servidores DNS personalizados para resolver los nombres de host de RD. Son útiles si el DNS de tu sistema es lento, poco fiable o está bloqueado por tu ISP. Déjalo vacío para usar el resolutor del sistema. Debes incluir el puerto (por ejemplo, `1.1.1.1:53`). |
| `network_test_every_mins` | int | `1440` | Cada cuántos minutos zurg vuelve a ejecutar la prueba de latencia de red para encontrar los servidores de descarga de RD más rápidos. No se puede desactivar: los valores `<= 0` se tratan como `1440`. Los resultados se guardan en caché en `data/network_test_results.json` y `data/network_test_timestamp`; al reiniciar, si la caché está lo bastante reciente, la prueba de red se omite. |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### Compartir NZB públicos {#public-nzb-sharing}

Un recurso compartido de NZB es una URL que el destinatario descarga, así que solo sirve si puede llegar a este host. Un zurg detrás de un NAT doméstico no puede garantizar eso. Estas dos claves dirigen esa URL a través de un servicio de [zrok](https://zrok.io): zurg se conecta al servicio de forma saliente y sirve el recurso compartido por esa conexión, así que **no se abre ningún puerto local** y nada nuevo responde en este host. Por el túnel solo viajan las dos rutas de recurso compartido protegidas por token, nunca el panel ni la biblioteca.

Si ambas están vacías y no hay ningún entorno habilitado en `data/zrok`, el recurso compartido sigue en la red en la que ya está este host, sin conectarse a ningún sitio. Ese es el valor por defecto. Ojo con la segunda parte: una vez que *se ha* habilitado un entorno, un `zrok_account_token` vacío ya no significa solo local, porque la habilitación es la que activa el recurso compartido y queda guardada. Para desactivar otra vez el recurso compartido público, hay que eliminar `data/zrok`.

Crear, servir y revocar recursos compartidos funciona igual en ambos casos. El token del recurso compartido en la ruta es la autorización tanto en la URL local como en la pública.

La URL pública sobrevive a un reinicio: el recurso compartido del lado del servicio se busca y se vuelve a enlazar, en lugar de crearse de nuevo. Lo que no sobrevive es volver a habilitar. Un entorno nuevo recibe un recurso compartido nuevo, y las URL entregadas con el anterior dejan de resolverse. Eso pasa al eliminar `data/zrok`, y también si la identidad guardada ahí desaparece o no se puede leer, porque volver a habilitar es la única forma de recuperarse en ese caso.

Eliminar `data/zrok` a mano tampoco desregistra el entorno ni el recurso compartido que contiene de la cuenta de zrok. La identidad que podría haberlos liberado es justo la que acabas de borrar, así que, si el desorden te importa, límpialos desde la consola de zrok. Tampoco sirve para desactivar el recurso compartido en caliente: un zurg en ejecución mantiene la conexión por la que ya está sirviendo, así que la URL antigua sigue funcionando hasta que se reinicie el proceso. zurg libera un entorno por sí mismo cada vez que reemplaza uno, y se niega a reemplazar uno si no puede contactar con el servicio para liberarlo, o si encuentra archivos suyos en disco que no puede leer, ya que habilitar encima de eso abandonaría un entorno activo en cada arranque.

| Opción | Tipo | Por defecto | Descripción |
|--------|------|-------------|-------------|
| `zrok_account_token` | string | `""` | El token de habilitación de zrok que activa el recurso compartido público. Es gratis en [myzrok.io](https://myzrok.io) para el servicio alojado; si te autoalojas, sale de tu propio controlador. Solo hace falta para la **primera habilitación**: al habilitar, el token se canjea una vez y se guarda, junto con la identidad del entorno, en `data/zrok`. Todas las llamadas posteriores se autentican con esa copia guardada, así que la clave puede quitarse de `config.yml` después y el recurso compartido público seguirá arrancando en el siguiente reinicio. Ojo con lo que eso implica para el secreto: quitar la clave de la configuración no quita el token del host. Hay dos razones para dejarla de todos modos: una habilitación que *falló* (un token rechazado, un servicio inalcanzable) no está completada, y el reintento necesita la clave; y cualquier *re*-habilitación posterior también la necesita, así que una instancia a la que se le quitó la clave y que luego pierde la identidad en `data/zrok` no puede recuperarse por sí sola. Un token rotado se toma desde aquí y se aplica al entorno guardado, manteniendo intactas la identidad y la URL pública. |
| `zrok_api_endpoint` | string | `""` | El servicio de zrok con el que se habla, para despliegues autoalojados. Si está vacío, se mantiene el valor por defecto del SDK, `https://api-v2.zrok.io` (el servicio alojado). Se lee **solo en el momento de habilitar**: una vez que `data/zrok` contiene un entorno habilitado, manda el endpoint guardado ahí, así que apuntar un zurg ya habilitado a otro servicio significa eliminar `data/zrok` y volver a habilitar. La identidad pertenece al servicio que la emitió, así que de todos modos esa es la forma honesta de hacerlo. No sustituye a `zrok_account_token`: la primera habilitación sigue necesitando un token del servicio que aquí se indica. La variable de entorno propia del SDK, `ZROK2_API_ENDPOINT`, tiene prioridad sobre esta clave en ese mismo momento. |

La accesibilidad se reparte de dos formas distintas en un servicio autoalojado, y solo una de ellas es tuya. **Este zurg** se conecta a la API del controlador; basta con una dirección de tailnet para eso. **Tus destinatarios** se conectan al frontend del servicio. Así que un servicio accesible solo dentro de tu propio tailnet entrega URL de recurso compartido que solo tu propio tailnet puede abrir.

Hay otras dos cosas que un servicio autoalojado tiene que cuadrar. La URL del recurso compartido es la que el servicio anuncia para su frontend, y un host sin esquema se asume como `https`. Así que un frontend que sirve HTTP plano necesita TLS delante, o una URL anunciada que incluya su propio esquema y puerto. Y el recurso compartido se crea en el namespace que resuelve el SDK de zrok, que es `public` salvo que la propia variable `ZROK2_DEFAULT_NAMESPACE` del SDK diga otra cosa. zurg no fija ninguno de los dos, así que un servicio cuyo namespace tenga otro nombre tiene que indicarlo mediante esa variable.

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. Rendimiento y ajuste (avanzado) {#6-performance--tuning-advanced}

Estos ajustes casi nunca se tocan, salvo que estés depurando o optimizando para las condiciones de tu red concreta.

### Cachés de lectura persistentes {#persistent-read-caches}

Dos cachés de bytes sobreviven a un reinicio. Ambos se comparten en toda la instancia y cada uno tiene su propio presupuesto de disco en MiB. Un cambio surte efecto después de reiniciar.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nzb_article_disk_cache_mb` | int | `512` | Artículos Usenet decodificados que se guardan en `data/bytecache/articles/`. Un artículo leído una vez se sirve desde el disco la próxima vez. `0` lo desactiva. |
| `archive_decoded_disk_cache_mb` | int | `512` | Bloques de archivo descomprimidos que se guardan en `data/bytecache/decoded/`. Un salto hacia atrás o un reinicio no vuelven a decodificar la entrada desde el principio. El mismo presupuesto se usa también para `data/bytecache/decoded-tails/`, que guarda los últimos 8 MiB de una entrada comprimida una vez que alguien la ha pedido. `0` desactiva ambos. |

Cuando se llena un presupuesto, primero se eliminan los registros más antiguos sin uso. [persistent-caches.md](../internals/persistent-caches.md) explica todos los cachés que sobreviven a un reinicio.

### Selección de CDN y host {#cdn--host-selection}

> **Relacionado:** La prueba de latencia de red que determina los hosts más rápidos se ejecuta periódicamente según [`network_test_every_mins`](#user-agent--network) (por defecto: cada 1440 minutos / 24 horas).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | Controla qué servidores de descarga de RD prefiere zurg. `auto` usa los que RD ofrezca. `force_cloudflare` reescribe el host a su gemelo `.cloud`, que llega a la misma máquina a través de Cloudflare; es útil cuando las IP directas están bloqueadas. `force_numbered` usa directamente los hosts numerados de RD. `force_location_<location>` (por ejemplo `force_location_syd` o `force_location_fra`) enruta a través de los servidores de un país concreto. |
| `cdn_host_preference` | string | — | Alias heredado de `rd_cdn_host_preference`, que se mantiene por compatibilidad y solo para Real-Debrid. Si se configuran ambos, prevalece el explícito. |
| `tb_cdn_host_preference` | string | `"auto"` | Región del CDN de TorBox. `auto` deja que TorBox elija por su cuenta; `force_location_<region>` sirve las descargas desde esa región. Solo se pueden forzar las regiones que actualmente anuncian un nodo de entrega, y el selector del panel muestra exactamente esas. No hay alternativa con la clave heredada: sus valores son códigos de ubicación de Real-Debrid y no significan nada aquí. |
| `number_of_hosts` | int | `0` (todos) | Limita zurg a los N hosts de descarga más rápidos. Tras hacer la prueba de velocidad de los hosts disponibles, zurg usa solo los N primeros. Ponlo a `0` para usar todos los hosts disponibles. Un valor como `3` reduce la dispersión de conexiones, pero asegura que siempre uses los servidores más rápidos. |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` y `force_location_*` son mutuamente excluyentes.** RD publica un gemelo `.cloud` solo para sus hosts numerados: medido el 2026-08-09, los 25 subdominios numerados tienen uno y ninguno de los 22 específicos de cada país lo tiene. Por eso, una cuenta con Cloudflare activado en la configuración de su cuenta de RD siempre recibe un host numerado, y ninguna preferencia de ubicación puede cumplirse para ella. zurg lo detecta a partir del enlace que desbloquea al arrancar, omite las pruebas de geolocalización que no pueden tener éxito y registra el motivo si aun así hay una ubicación configurada.

> **Nota sobre la verificación de `force_location_*`:** Al usar una preferencia de geolocalización como `force_location_nyk`, el endpoint de la API `/rest/1.0/downloads` de RD normaliza las URL de descarga a servidores numerados (por ejemplo `128-4.download.real-debrid.com`), aunque la respuesta real de desbloqueo haya devuelto un servidor geográfico (por ejemplo `nyk7-4.download.real-debrid.com`). El propio código de descarga incluye el servidor numerado (por ejemplo, el código `...4128` corresponde al servidor `128-4`). Para comprobar que el enrutamiento geográfico funciona, revisa los logs de zurg o la respuesta de desbloqueo sin procesar; **no** te fíes de la API de descargas de RD.

### Límites de tasa {#rate-limits}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | Máximo de llamadas a la API de RD por minuto para operaciones generales (todo excepto la lista de torrents). RD aplica sus propios límites; esto evita que zurg los supere y termine bloqueado temporalmente. Aumenta este valor solo si estás seguro de que tu plan de RD lo permite. |
| `torrents_rate_limit_per_minute` | int | `75` | Máximo de llamadas a la API de RD por minuto específicamente para el endpoint `/torrents` que se usa para obtener tu lista de torrents. Va por separado porque listar torrents es la llamada más frecuente y tiene su propia dinámica de límites. |
| `fetch_torrents_page_size` | int | `5000` | Cuántos torrents obtener por página al sincronizar tu biblioteca de RD. Valores más altos significan menos llamadas a la API, pero respuestas más pesadas. Si tienes una biblioteca muy grande (10,000+ torrents), un valor más alto reduce el tiempo de sincronización. |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### Verificación de enlaces {#link-verification}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | Controla cómo zurg verifica que los enlaces de descarga siguen siendo válidos. Cuando es false, zurg usa una petición `HEAD` (ligera, no transfiere datos). Cuando es true, usa una cabecera `Range` (`GET bytes=0-0`), que descarga solo 1 byte. Actívalo si tu red o los servidores de RD no responden bien a las peticiones HEAD, lo que provoca fallos falsos en los enlaces. |

```yaml
use_range_verification: false
```

### Tiempos de espera y reintentos {#timeouts--retries}

| Opción | Tipo | Por defecto | Descripción |
|--------|------|---------|-------------|
| `api_timeout_secs` | int | `60` | Segundos máximos de espera a que cualquier llamada a la API de RD responda. Aumenta este valor si tienes una conexión lenta y las llamadas a la API se agotan por tiempo. |
| `download_timeout_secs` | int | `15` | Segundos máximos de espera al probar los enlaces de descarga (se usa durante las pruebas de velocidad del host y la verificación de enlaces). No es el tiempo de espera para las descargas reales de archivos. |
| `retries_until_failed` | int | `2` | Cuántas veces reintentar una llamada a la API fallida antes de rendirse y marcarla como fallida. Valores más altos añaden resistencia ante caídas temporales de RD, pero ralentizan la detección de fallos. |
| `retry_503_errors` | bool | `false` | Si es true, reintenta las peticiones que reciben una respuesta 503 (Service Unavailable) de RD. RD devuelve 503 durante mantenimientos o sobrecarga. Actívalo si tienes errores 503 frecuentes que se resuelven solos rápido. |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### Descargas y depuración {#downloads--debugging}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `get_downloads_limit` | int | `-1` | Número máximo de entradas de descargas de RD (no torrents) que se obtienen. `-1` significa sin límite (obtener todas), `0` omite por completo la obtención de descargas, y un número positivo lo limita. Es útil si usas la función de desbloqueo de enlaces directos de RD y quieres que esos archivos se vean en zurg. Si no pones la clave, se usa `-1`; un `0` explícito se respeta como "no cachear nada" y registra una advertencia al iniciar, porque normalmente es una configuración escrita antes de que `0` cambiara de significado. |
| `load_dumped_torrents` | bool | `false` | Si es true, carga los datos de torrents de la carpeta `dump/` al iniciar. Es un mecanismo de recuperación: si zurg guardó antes el estado de los torrents (por ejemplo, durante un fallo), activar esto restaura ese estado sin volver a pedir todo a RD. |
| `log_requests` | bool | `false` | Si es true, registra estadísticas detalladas de cada petición de descarga (ruta del archivo, tiempo de respuesta, bytes servidos). Es útil para depurar problemas de streaming o para entender los patrones de acceso. Genera mucho volumen de logs, así que desactívalo en producción. |
| `log_level` | string | `DEBUG` | Cuánto detalle registrar: `DEBUG`, `INFO`, `WARN`, `ERROR` o `FATAL`. Si lo cambias desde el panel, surte efecto al instante: sin reiniciar, y ajusta el nivel de todos los componentes a la vez. Anula la variable de entorno `LOG_LEVEL`, así que el control del panel sigue funcionando aunque el contenedor traiga una fijada; deja la clave fuera para devolverle la elección a `LOG_LEVEL`. Un valor que no corresponde a ningún nivel se ignora con una advertencia al iniciar, en lugar de detener el programa. |
| `traffic_alert_gb` | int | `0` | Avisa cuando una cuenta debrid mueve más de esta cantidad de GiB a través de zurg en un día (el día se reinicia a las 00:05 CET, con la cuota de Real-Debrid). El aviso indica qué archivos usaron más tráfico en esa hora y quién los leyó, así que un escaneo de la biblioteca o un cliente que descarga archivos completos se ve mientras está pasando. zurg también registra un resumen de los archivos más grandes de la hora al inicio de cada hora, y una línea por cada lectura individual de 1 GiB o más, esté o no activada la alerta. `0` desactiva la alerta. |
| `traffic_alert_webhook` | string | — | Un webhook de Discord al que también se envía la alerta de tráfico. Mantenlo en privado: cualquiera que tenga la URL puede publicar en ese canal. |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
traffic_alert_gb: 500
```

## 7. Directorios y filtros {#7-directories--filters}

Define directorios virtuales que organizan tus torrents según reglas de filtro flexibles. Cada directorio aparece como una carpeta en tu montaje y solo muestra los torrents que cumplen sus filtros.

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### Opciones de directorio {#directory-options}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `group` | string | el nombre propio del directorio | Los directorios que comparten grupo compiten por cada torrent: el torrent va al primero cuyos filtros coincidan, y a ningún otro de ese grupo. Los directorios de grupos distintos tienen cada uno su propia copia. |
| `group_order` | int | `0` (se trata como `1`) | Prioridad dentro del grupo; el valor más bajo va primero. En caso de empate, se ordena por el nombre del directorio. |
| `filters` | list | `[]` | Las reglas que deciden qué entra aquí. Un torrent coincide con el directorio si **cualquier** entrada de la lista coincide. Una lista vacía o ausente coincide con todos los torrents. |
| `only_show_the_biggest_file` | bool | `false` | Muestra solo el archivo más grande de cada torrent, ocultando muestras, extras y archivos complementarios. |
| `only_show_files_with_size_lte` | int | `0` (desactivado) | Oculta los archivos más grandes que este número de bytes. |
| `only_show_files_with_size_gte` | int | `0` (desactivado) | Oculta los archivos más pequeños que este número de bytes. |
| `rex_shows` | string | `""` (ninguno) | Con `rex_url`: el título de una biblioteca de TV en rex que muestra los episodios de este directorio. |
| `rex_movies` | string | `""` (ninguno) | Con `rex_url`: el título de una biblioteca Movies en rex que muestra las películas de este directorio, y cualquier archivo que rex no pueda identificar como episodio. |
| `rex_music` | string | `""` (ninguno) | Con `rex_url`: el título de una biblioteca de música en rex que muestra los archivos de audio de este directorio (`.flac`, `.mp3`, `.m4a`, `.m4b`), incluidos los audiolibros. Sin ella, ningún archivo de audio va a rex. |
| `rex_photos` | string | `""` (ninguno) | Con `rex_url`: el título de una biblioteca Photos en rex que muestra los cómics de este directorio (`.cbz`, `.cbr`), cada uno como un álbum de sus páginas, que Plex Web recorre y reproduce como una presentación de diapositivas. Plex para Android no muestra ninguna biblioteca de fotos. Los cómics siguen siendo archivos en el mount. |

Un archivo que se fuerza a ser visible explícitamente en zurg ignora las tres opciones de visibilidad.

### Condiciones de filtro {#filter-conditions}

| Condición | Tipo | Descripción |
|-----------|------|-------------|
| `id` | string | El ID del torrent. Decisivo: no se tiene en cuenta nada más de la misma entrada. |
| `regex` | string | El nombre del torrent coincide con el patrón. |
| `not_regex` | string | El nombre del torrent no coincide con el patrón. |
| `contains` | string | El nombre del torrent contiene el texto (sin distinguir mayúsculas). |
| `contains_strict` | string | El nombre del torrent contiene el texto (distingue mayúsculas). |
| `not_contains` | string | El nombre del torrent no contiene el texto (sin distinguir mayúsculas). |
| `not_contains_strict` | string | El nombre del torrent no contiene el texto (distingue mayúsculas). |
| `size_gte` | int | El tamaño total del torrent es de al menos esta cantidad de bytes. |
| `size_lte` | int | El tamaño total del torrent es de como máximo esta cantidad de bytes. |
| `any_file_inside_regex` | string | Algún archivo del torrent coincide con el patrón. |
| `any_file_inside_not_regex` | string | Algún archivo del torrent no coincide con el patrón. |
| `any_file_inside_contains` | string | Algún archivo contiene el texto (sin distinguir mayúsculas). |
| `any_file_inside_contains_strict` | string | Algún archivo contiene el texto (distingue mayúsculas). |
| `any_file_inside_not_contains` | string | Algún archivo no contiene el texto (sin distinguir mayúsculas). |
| `any_file_inside_not_contains_strict` | string | Algún archivo no contiene el texto (distingue mayúsculas). |
| `any_file_inside_size_gte` | int | Algún archivo tiene al menos esta cantidad de bytes. |
| `any_file_inside_size_lte` | int | Algún archivo tiene como máximo esta cantidad de bytes. |
| `added_within_hours` | int | El torrent se añadió dentro de estas horas. |
| `added_within_days` | int | El torrent se añadió dentro de estos días. |
| `added_after` | string | El torrent se añadió en esta fecha o después. Formato `YYYY-MM-DD` o `YYYY-MM-DD HH:MM`. |
| `added_before` | string | El torrent se añadió antes de esta fecha, mismos formatos. Si se combina con `added_after`, deben cumplirse ambos. |
| `has_episodes` | bool | Detección de episodios: marcadores de temporada/episodio o hashes CRC en los nombres del torrent o de los archivos, o una serie de archivos numerados. Si el archivo más grande es al menos 5 veces el segundo más grande, se interpreta como una película con extras y se rechaza. |
| `is_music` | bool | Algún archivo termina en `.m3u`, `.mp3`, `.flac`, `.m4a` o `.m4b`. |
| `has_tag` | string | El torrent tiene esta etiqueta. Actúa como puerta: sin ella, nada más de la entrada puede coincidir. |
| `not_has_tag` | string | El torrent no tiene esta etiqueta, y funciona igual como puerta. |
| `tags_match_all` | list | Están presentes todas las etiquetas de la lista (sin distinguir mayúsculas). |
| `tags_match_any` | list | Está presente al menos una de las etiquetas de la lista. |
| `tags_missing_all` | list | No está presente ninguna de las etiquetas de la lista. |
| `tags_missing_any` | list | Falta al menos una de las etiquetas de la lista. |
| `provider` | string | La versión la tiene esta cuenta, identificada por su `name` en el bloque providers. Es una puerta, no una coincidencia: combinada con otra condición, significa que ambas deben cumplirse. Por sí sola, mete toda la cuenta en el directorio. |
| `not_provider` | string | Ninguna cuenta que tenga la versión es esta. Funciona igual como puerta. |
| `and` | list | Cada condición anidada debe coincidir. |
| `or` | list | Al menos una condición anidada debe coincidir. |

Las etiquetas vienen del análisis de medios; consulta [tags.md](tags.md) para la lista completa.

Los patrones se escriben `/expression/flags`, donde los flags son cualquiera de `i` (sin distinguir mayúsculas), `m` (multilínea), `s` (el punto coincide con el salto de línea) y `x` (extendido). Un valor sin barras se compila como una expresión regular de Go simple.

Las condiciones dentro de una misma entrada de filtro **no** se combinan con AND por defecto: la mayoría coincide con la entrada en cuanto se cumple una de ellas. Usa un bloque `and:` explícito cuando quieras que se cumplan todas:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### Directorios por cuenta {#per-account-directories}

Junto a `__all__`, cada cuenta configurada tiene su propio directorio, con el nombre de la cuenta: `__realdebrid__`, `__torbox__`, `__alldebrid__`, `__nzb__`. No se configuran; aparecen porque la cuenta existe, y desaparecen cuando se elimina. Con una sola cuenta, su carpeta propia no aparece en el listado raíz del montaje, y `__all__` contiene los mismos archivos. Las rutas HTTP directas y WebDAV como `/http/__realdebrid__/` siguen respondiendo. A través del montaje ya no se resuelven. Apunta cualquier biblioteca o script que usara `__<name>__` a `__all__`.

Cada uno contiene lo que tiene esa cuenta y, a diferencia de un directorio filtrado, también decide adónde van las lecturas. Un lanzamiento que tienen dos cuentas es una sola entrada en la biblioteca, así que sin esto cada copia se reproduciría desde la cuenta que vaya primero en el bloque `providers`:

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

El anclaje excluye a las otras cuentas en lugar de simplemente preferir la nombrada. No hay conmutación silenciosa: si TorBox no puede servir el archivo, la lectura bajo `__torbox__` falla en lugar de responder en silencio con los bytes de Real-Debrid. Las lecturas en otras partes del montaje no cambian y siguen haciendo failover normalmente.

Dos consecuencias se derivan de que las cuentas no tengan contenido idéntico:

- Un directorio solo lista los archivos que realmente tiene su cuenta. Si TorBox descargó parte de un lanzamiento que Real-Debrid tiene completo, `__torbox__` muestra esa parte.
- La rotura se evalúa por cuenta. Un archivo muerto en Real-Debrid pero sano en TorBox da un 404 bajo `__realdebrid__` y se reproduce bajo `__torbox__`, mientras el resto del montaje lo sigue sirviendo.

El directorio toma el nombre del `name` de la cuenta, que por defecto es su `type`. Dos cuentas del mismo servicio necesitan nombres distintos (`rd-main`, `rd-backup`) y cada una obtiene su directorio. El backend de Usenet es `nzb` por defecto, así que aparece como `__nzb__`; define `name: usenet` en esa entrada de proveedor si prefieres navegar `__usenet__`.

Puedes renombrar una cuenta más adelante. zurg ve los mismos lanzamientos listados con el nuevo nombre y los mueve allí. El directorio antiguo desaparece con el nombre antiguo. Si un servidor multimedia lee ese directorio, apúntalo al nuevo antes de renombrar.

Como el mismo lanzamiento aparece en todas las cuentas que lo tienen, además de en tus directorios filtrados, apunta un servidor multimedia a una parte del montaje y no a todo, o escaneará el mismo contenido varias veces.

Una cuenta con el nombre de un directorio que zurg ya usa (`all`, `unplayable`, `dump`, `downloads`) no obtiene directorio por cuenta, y zurg registra una advertencia al arrancar en lugar de apropiarse del existente.

### Catálogos locales de debrid {#local-debrid-catalogs}

Cada entrada de proveedor debrid acepta un bloque `library` opcional:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: PRIMARY_RD_TOKEN
    download_tokens: # Optional bandwidth fallback.
      - SECOND_RD_TOKEN
    library:
      source: local
      path: torrents/rd-local
```

`source` tiene `provider` como valor predeterminado. Con `local`, los archivos `.zurgtorrent` portables son los que definen la pertenencia y la reproducción usa las credenciales de esta cuenta. `path` tiene `torrents/<resolved-account-name>` como valor predeterminado y debe quedar dentro de `torrents/`. Dos cuentas habilitadas no pueden compartir el mismo directorio de origen. Los proveedores NZB conservan su biblioteca `nzbs/` existente.

En este ejemplo, ambos tokens de RD sirven el mismo catálogo en `torrents/rd-local/`. El segundo token no necesita entrada de proveedor ni directorio, y su biblioteca de torrents no se importa. `download_tokens` mantiene su comportamiento de respaldo por ancho de banda; no obliga a que todas las descargas pasen por el segundo token. Dos entradas de proveedor local separadas tienen, en cambio, dos directorios de catálogo distintos, incluso si ambas son Real-Debrid. Las credenciales se quedan en la configuración y nunca se exportan a archivos portables.

Consulta [bibliotecas portables](../guides/local-libraries.md) para la exportación sin conexión, la migración desde `dump/`, la semántica de compartir y los límites de reproducción.

#### Trasladar una cuenta online a una biblioteca local {#offloading-an-online-account-into-a-local-library}

Una cuenta de Real-Debrid o AllDebrid que sea dueña de su catálogo (sin `source`, o con `source: provider`) puede mover sus releases terminadas a una biblioteca local y borrarlas de la cuenta, lo que libera sus espacios:

```yaml
providers:
  - name: rd
    type: realdebrid
    token: YOUR_RD_TOKEN
    library:
      offload_to: rd-local      # a local entry of the same type
      offload_after_mins: 30    # optional, 30 is the default

  - name: rd-local
    type: realdebrid
    token: YOUR_RD_TOKEN        # the same account
    library:
      source: local
```

| Clave | Por defecto | Significado |
|---|---|---|
| `library.offload_to` | ninguno | Nombre de una entrada `source: local` habilitada del mismo tipo. Solo las cuentas `realdebrid` y `alldebrid` lo aceptan, ya que solo sus enlaces siguen funcionando después de borrar el torrent. No puede apuntar a la propia cuenta. |
| `library.offload_after_mins` | `30` | Cuánto tiempo debe llevar completa una release en la cuenta antes de moverse automáticamente. Se cuenta desde que zurg la vio completa por primera vez, así que al reiniciar la espera vuelve a empezar. Requiere `offload_to`. |

Una release solo se mueve cuando todos sus archivos tienen un enlace que otra cuenta podría canjear, nada la está reparando o descargando, ningún trabajo de Sonarr o Radarr en el endpoint de qBittorrent todavía la lista, y al moverla se mantiene el nombre de su carpeta y cada directorio en el que está. Su carpeta se queda donde estaba y no se inicia ningún escaneo del servidor de medios. La página de la release en el dashboard puede mover una release a mano, con o sin `offload_to`. Consulta [bibliotecas portátiles](../guides/local-libraries.md#offload-an-online-account-into-a-local-library) para ver el orden de los pasos, qué pasa cuando uno falla y cómo se protege la reproducción local con un token compartido.
