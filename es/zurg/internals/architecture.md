# Arquitectura {#architecture}

A mapa de lo que es zurg, cómo encajan las piezas y por qué existe cada paquete. Pensado para alguien que está a punto de cambiar el código: nombra las decisiones que sostienen todo el diseño y los invariantes que son fáciles de romper sin darse cuenta.

El detalle de cada paquete está en su `doc.go`. Este documento está un nivel por encima: la forma del conjunto y el razonamiento que se deriva de esa forma.

## Qué es zurg {#what-zurg-is}

Un daemon en Go que muestra la biblioteca de torrents de una cuenta debrid como un sistema de archivos virtual. No guarda ningún medio. Cada lectura se convierte en un GET HTTP con rangos contra el CDN del proveedor, en el momento de la petición.

No guarda contenido propio y rechaza los PUT, así que, en lo que importa para los bytes, es de solo lectura. Se aceptan dos escrituras: un rename, que guarda un nombre y no toca ninguna cuenta ([renaming.md](../guides/renaming.md)), y un DELETE, que elimina la release de todas las cuentas que la tengan. `__magic__` añade una tercera dentro de un espacio de nombres, un layout guardado ([magic.md](../guides/magic.md)), en todo su contenido excepto en `__magic__/__all__` y en las carpetas de release que hay directamente dentro, que es el espejo calculado del que importan los clientes de descarga.

Cuatro vistas de la misma biblioteca:

| Endpoint | Para |
|---|---|
| `/dav/` | WebDAV, lo que monta rclone |
| `/http/` | Explorador de directorios HTML |
| `/infuse/` | Variante de WebDAV con las peculiaridades de Infuse ya contempladas |
| `/strm/` | URLs firmadas dentro de archivos `.strm`, para reproductores que quieren una URL y no un montaje |

rclone monta `/dav/` con FUSE, así que Plex, Jellyfin, Emby e Infuse ven un árbol de directorios normal.

El problema de diseño en todo el proyecto es la distancia entre lo que promete un sistema de archivos (rutas estables, `stat` instantáneo, bytes bajo demanda) y lo que da una API debrid: JSON con límite de peticiones, enlaces que caducan y ninguna semántica de sistema de archivos. Casi cada paquete existe para cerrar una parte de esa distancia.

```
media player
    │
    ├─ rclone FUSE ──► /dav/  ──┐
    └─ direct HTTP ──► /http/ ──┤
                                ▼
                    internal/handlers  (chi router, auth, routing)
                                │
                internal/dav ───┤─── internal/htmlindex     (listings)
                                │
                                ▼
                    internal/torrent   (the library, in memory)
                                │  resolve link for this file
                                ▼
                    internal/universal (byte path, proxy/redirect, RAR)
                                │
                                ▼
                    internal/debrid    (Provider dispatch)
                                │
        ┌───────────┬───────────┼────────────┬──────────┐
        ▼           ▼           ▼            ▼          ▼
   realdebrid    torbox     alldebrid       nzb ──► nntp ──► par2
        └───────────┴───────────┘            (Usenet, no debrid service)
                    │
              internal/rdclient  (host rotation, rate limit, retry, DNS)
```

## Secuencia de arranque {#boot-sequence}

`cmd/zurg` es una CLI de Cobra ligera (serve, version, network-test, clear downloads/torrents, mount control, download requirements). Todo lo importante ocurre en `internal/app.go`, cuyo `MainApp` es, a propósito, una sola función fácil de leer:

1. Crea los directorios de ejecución (`logs`, `data`, `data/info`, `dump`, `strm`, `nzbs`) y el logger.
2. `ensureConfigAndRequirements` — carga la configuración y descarga `ffprobe` y `rclone` si no están (`internal/requirements`). En la primera ejecución, si no hay configuración, escribe una por defecto y se detiene, salvo que el token venga del entorno.
3. Inicializa `strmlink` pronto, para que un directorio de datos sin permisos de escritura se reporte ahora y no como archivos `.strm` que dejan de resolverse tras el próximo reinicio.
4. Ejecuta el **test de latencia de red** contra los hosts de descarga de Real-Debrid (`internal/rdclient`), o carga su resultado en caché desde disco si es lo bastante reciente. Esto ordena los hosts CDN y es lo que luego usa la rotación de hosts.
5. Construye todos los proveedores configurados desde el registro, los agrupa en un `debrid.Set` y guarda una referencia tipada al primero de Real-Debrid: el panel, la página de hosts y el test de red siguen hablando con RD específicamente.
6. Crea el `TorrentManager`, que de inmediato empieza a cargar la biblioteca en caché desde disco en segundo plano y luego la actualiza.
7. Conecta el router chi, arranca el servidor HTTP y luego inicia rclone cuando el servidor ya acepta conexiones.
8. Espera a SIGINT/SIGTERM/SIGQUIT; al recibir una señal, cierra el servidor HTTP de forma ordenada, detiene el servicio de Plex y desmonta rclone, cada uno con un límite de 20 s.

`ZURG_PPROF=1` activa pprof en `127.0.0.1:6060`: solo loopback, porque perfilar una instancia en vivo es la única forma de atribuir el uso de CPU durante una tormenta de escaneos, pero ese endpoint nunca debe ser accesible desde la red.

## Capa 1 — Configuración {#layer-1--config}

La parte más importante es `filters.go`: un lenguaje de filtros anidados AND/OR que asigna cada torrent a uno o más **directorios virtuales**. Así es como una lista plana de torrents se convierte en `movies/`, `shows/`, `anime/`, `recent/`.

`internal/config` es la fuente única de la verdad; casi todos los demás paquetes leen `ZurgConfigV1`. Los getters tipados aplican valores por defecto cuando un campo está en cero, así que quien los llama nunca tiene que comprobar si el valor falta.

Las condiciones cubren el nombre del torrent (`regex`, `contains`, `not_regex`), su tamaño, sus archivos (`any_file_inside_regex`, `any_file_inside_size_gte`), sus etiquetas (`tags_match_any`, `tags_missing_all`), su antigüedad (`added_within_hours`, `added_after`), propiedades derivadas (`has_episodes`, `is_music`) y de qué cuenta viene (`provider`, `not_provider`). Junto a ellas están las reglas de visualización por directorio: `only_show_the_biggest_file`, y los mínimos y máximos de tamaño.

Las regex que se usan por torrent en cada pasada de asignación se compilan una sola vez a nivel de paquete. Compilarlas con `MustCompile` en cada llamada dominaba el tiempo de arranque, y se notaba bastante.

Se puede editar la configuración en vivo desde el panel. `UpdateConfigFileAtomic` hace ediciones clave por clave en lugar de volver a serializar el archivo entero, así que los comentarios y las claves desconocidas se conservan.

## Capa 2 — Abstracción de backends {#layer-2--backend-abstraction}

`internal/debrid` es la columna vertebral. Es dueño de los tipos de dominio que hablan todos los demás paquetes (`Torrent`, `TorrentInfo`, `File`, `Download`, `User`) y de la interfaz `Provider` que implementa cada backend.

### Proveedor y capacidades {#provider-and-capabilities}

`Provider` se mantiene pequeña: listar torrents, obtener info, borrar, resolver un enlace, verificarlo, descargar los bytes e informar del estado de la cuenta. Todo lo que un servicio razonablemente podría no tener es una **interfaz de capacidad opcional** que los llamadores comprueban con type-assert y con la que degradan el comportamiento si no existe:

| Interfaz | Qué añade | Quién la necesita |
|---|---|---|
| `MagnetAdder` | añadir por hash, seleccionar archivos, número de slots activos | repair |
| `TorrentRestarter` | reintentar un torrent fallido en el sitio | repair, la estrategia más barata |
| `HostRotator` | cambiar el pool de hosts CDN | network test, página `/hosts` |
| `DownloadLister` | una lista separada de descargas de hosters | el directorio `__downloads__` |
| `ArchivePasswordKeeper` | contraseña para los archivos de un release | solo Usenet |
| `PremiumMonitor` | tiempo restante del plan | aviso de inicio |

Junto a eso, `Capabilities` es la autodescripción del proveedor: no dice lo que puede hacer, sino los límites dentro de los que debe funcionar. Existe porque el comportamiento de la biblioteca de zurg creció alrededor de la forma de Real-Debrid, y dejar esa forma fija en el código hace que cualquier otro backend acabe roto o desperdiciando recursos.

Hay dos banderas que ya controlan el comportamiento real:

- **`ListIncludesFiles`**: la lista de torrents ya trae el detalle de cada archivo. Convierte un escaneo en frío de la biblioteca de una llamada a la API por torrent en una sola llamada en total. Es la diferencia más costosa entre backends.
- **`StoredLinksCanRot`**: un enlace guardado puede morir mientras el torrent sigue pareciendo sano, así que hay que comprobar los enlaces. Es una propiedad de Real-Debrid y además muy costosa. En un backend que genera las URLs bajo demanda no hay nada que comprobar, y saltarse esa pasada es la diferencia entre que un escaneo sea gratis o que active un bloqueo de toda la cuenta.

El resto (`ServesLinksLocally`, `MaxActiveSlots`, `MaxConcurrentRequests`, `AddsPerHour`, `ContentExpires`, `SupportsFileSelection`) lo declaran todos los backends y lo leen los códigos genéricos. El valor cero es deliberadamente la lectura más conservadora, así que un proveedor que olvide un campo recibe un comportamiento cauto en lugar de una avalancha de peticiones. Y un proveedor que zurg no pueda resolver del todo cae en `unknownProviderCaps` en `internal/torrent/providers.go`, que enuncia esa respuesta cauta una sola vez en lugar de en cada punto de llamada.

Hay una tercera forma que ninguna de las dos banderas expresa: la lista de AllDebrid no trae archivos, pero su endpoint por torrent acepta un *lote* de ids. Eso se maneja dentro del proveedor en lugar de con una capacidad, porque solo cambia cómo el proveedor gasta sus propias peticiones. El refresco genérico sigue pidiendo un torrent a la vez y no necesita saber nada de ello.

### Set

`Set` es cada proveedor configurado, en el orden del config, y es lo que el torrent manager, los handlers y el dashboard usan en lugar de cualquier cliente concreto. Hay dos patrones de acceso que importan: **fan-out**, donde una operación se ejecuta contra todas las cuentas (por ejemplo, un refresh de la biblioteca), y **dispatch**, donde una operación debe llegar a la única cuenta que es dueña de un torrent (delete, resolve, repair). También guarda el estado de salud/disponibilidad de las cuentas.

### Caché de enlaces {#link-cache}

`LinkCache` almacena las URL resueltas indexadas **por token**, no solo por enlace. Una URL generada con un token solo es válida con la cuota de ese token, así que cuando un token llega al límite de ancho de banda, sus entradas deben descartarse por completo en lugar de reutilizarse con el siguiente token de la rotación. Las entradas caducan según su marca de tiempo `Generated` y no según el momento de inserción, de modo que los enlaces cargados desde la lista de descargas del propio proveedor caducan según el calendario del proveedor.

### Los backends {#the-backends}

| Paquete | Qué es | Lo que hay que saber |
|---|---|---|
| `internal/realdebrid` | Real-Debrid, el backend original | Tres clientes HTTP separados: API con límite de tasa, unrestrict con límite de tasa y descarga con rotación de hosts. Las marcas de tiempo en hora de París se normalizan en el límite del paquete y nunca salen de él. `DownloadTokenManager` rota los tokens cuando uno caduca. |
| `internal/torbox` | REST de TorBox | Usa REST con `bypass_cache=true` en lugar del WebDAV de TorBox, cuya vista va 5–15 minutos por detrás de la realidad. No existe un enlace por archivo, así que los enlaces se sintetizan como `torbox://<torrent-id>/<file-id>`: son estables entre reinicios y legibles en los logs, algo que una URL de CDN con la clave de API no sería. Dos limitadores apilados: el de 300/min documentado y otro mucho más estricto para `requestdl`. Consulta [torbox-limits.md](../providers/torbox-limits.md). |
| `internal/alldebrid` | AllDebrid v4.1 | Los POST son form-encoded; un fallo lógico llega como HTTP **200** con `status:"error"`, así que el código HTTP nunca indica si una llamada funcionó. Los archivos están detrás de `/magnet/files`, que acepta un lote, así que las búsquedas concurrentes se agrupan en peticiones únicas. El árbol anidado de archivos se aplana en profundidad primero, y ese orden es imprescindible. |
| `internal/nzb` | Usenet, que no es en absoluto un servicio debrid | Los archivos NZB de `nzbs/` se convierten en torrents; las lecturas descargan artículos y los decodifican con yEnc bajo demanda. Los enlaces son `nzb://<nzb-id>/<file-index>` y se sirven en local, así que `DownloadFile` sintetiza la respuesta HTTP en lugar de hacer de proxy. |
| `internal/nntp` | Cliente Usenet mínimo | Pool de conexiones limitado por el número de conexiones que permite la cuenta, BODY/STAT por id de mensaje, decodificación yEnc. Una sola conexión obtiene solo una fracción del rendimiento alcanzable, así que las lecturas de un archivo se reparten entre todo el margen de conexiones. |
| `internal/par2` | PAR2 / Reed-Solomon sobre GF(2^16) | Cuando un artículo ya no está en el servidor, los volúmenes de recuperación propios de la release reconstruyen los bytes que transportaba. Es costoso de una forma concreta: la aritmética necesita todas las porciones supervivientes de cada archivo cubierto, una sola vez. Por eso se ejecuta como tarea en segundo plano, una release a la vez, y genera parches de rangos de bytes que los lectores sirven en lugar de silencio. |
| `internal/rdclient` | HTTP de bajo nivel compartido | Rotación de hosts entre endpoints de CDN ordenados por latencia, limitación con token bucket, reintentos con backoff, soporte de proxy, DNS personalizado, forzado de IPv4/IPv6 y preferencia de CDN anclada a una geolocalización. `IPRepository` gestiona la prueba de red y su caché en disco. |

`internal/nzb` es la prueba de que la abstracción funciona. Implementa la misma
interfaz sobre un directorio local y un servidor de noticias, y eso funciona porque
el contrato real de la interfaz es *"responder un GET por rango con bytes"*, no
*"hacer de proxy de una CDN"*.

### Añadir un backend {#adding-a-backend}

Paquete nuevo: implementa `debrid.Provider`, llama a `debrid.Register` en `init` y añade un import en blanco en `internal/app.go`. No cambia nada en `internal/debrid`.

## Capa 3 — La biblioteca {#layer-3--the-library}

`internal/torrent` es el núcleo de zurg y su paquete más grande. `TorrentManager` guarda toda la biblioteca en mapas concurrentes `cmap` para lecturas sin bloqueos, asigna los torrents a los directorios evaluando los filtros de la configuración, resuelve y guarda en caché los enlaces, y ejecuta los trabajos en segundo plano.

### Persistencia {#persistence}

Cada entrada se guarda en `data/<name>.zurgtorrent` como JSON, y la información de cada torrent se guarda en caché en `data/info/`. Al reiniciar, se carga desde disco y queda operativo al instante, y luego se actualiza. Esto importa porque un escaneo en frío está limitado por el rate limit, no por la CPU.

Los torrents que ya no están en la cuenta se pueden archivar en `dump/` y mostrar como el directorio `__dump__` (`load_dumped_torrents`).

El estado que nada más puede reconstruir (la configuración, cada zurgtorrent, el almacén `__magic__` en `data/local/` y los NZB de origen en `nzbs/`) se guarda en un único `.zurgbackup` en streaming. `zurg backup` genera uno (igual que la página Backup & Restore del dashboard), y `zurg restore-backup <file>` lo descomprime en el directorio de trabajo. `internal/backup` se encarga del formato. Un manifiesto es la primera entrada, así que una restauración valida lo que tiene antes de escribir nada.

Nombres de directorio reservados: `__all__`, `__unplayable__`, `__dump__`, `__downloads__`, y uno por cuenta como `__<provider-name>__`.

### Torrent vs TorrentCopy

Un release puede vivir en más de una cuenta. zurg lo muestra una sola vez. La división:

- **Los datos del contenido pertenecen a la entrada** (`Torrent`): nombre, hash, qué archivos existen, etiquetas, id de IMDB, rename.
- **Los datos de la cuenta pertenecen a una copia** (`TorrentCopy`): los ids de torrent que generó esa cuenta, los enlaces que entrega, su propio estado de rotura y sus contadores de reintentos.

Los ids de archivo, en particular, son por cuenta: Real-Debrid numera los archivos dentro de un torrent y marca un subconjunto como seleccionado; TorBox lista solo lo que descargó y los numera a su manera. Por eso `FileSource` guarda `FileID` por proveedor. Repair construye su selección a partir de los ids de la copia que está reparando; si lees el id de la cuenta equivocada, vuelves a añadir los archivos equivocados.

Las copias se guardan en el orden de la configuración, que es el orden de preferencia. Las lecturas prefieren la primera copia sana y, si falla, pasan a la siguiente. Al borrar la entrada se borran todas las copias. Una entrada sin copias no existe.

### GetKey debe seguir siendo puro {#getkey-must-stay-pure}

`GetKey` es el nombre de un torrent en la biblioteca virtual: su entrada de directorio, su nombre de archivo `.zurgtorrent` y el identificador que usa cada búsqueda. Se **recalcula en cada búsqueda y nunca se guarda**, lo que descarta resolver los choques de nombres comprobando qué ya está en uso: la respuesta cambiaría según cambiara la biblioteca, y un torrent dejaría de encontrarse con el nombre con el que se había registrado.

El único sufijo es para el caso menos frecuente en que dos *versiones distintas* comparten nombre, y es una etiqueta del propio hash del contenido, tan pura como el propio nombre. La marca que lo activa la decide el proceso de actualización, que puede ver toda la biblioteca, y se guarda en el torrent.

### Trabajos en segundo plano {#background-jobs}

| Job | File | What it does |
|---|---|---|
| Refresh | `refresh.go` | Consulta cada cuenta, combina las instancias listadas en entradas, obtiene la información de las nuevas, asigna los directorios y depura. Usa una consulta barata de un solo elemento como comprobación de cambios entre consultas completas. |
| Repair | `repair.go` | Encuentra y arregla torrents rotos. |
| Downloads | `manager.go` | Actualiza la lista de descargas de hosters en `__downloads__`. |
| Network test | `handlers` | Vuelve a ordenar periódicamente los hosts CDN. |

El intervalo de cada job se puede restablecer en tiempo de ejecución a través de un canal, así que si cambias la
config desde el panel, el cambio se aplica sin reiniciar. Las marcas de tiempo de la última ejecución se guardan
(`data/repair_timestamp`, `data/downloads_timestamp`) para que un reinicio no vuelva a ejecutar un job que acaba de correr.

### Reparación {#repair}

La segunda preocupación más importante del paquete. Los archivos tienen un estado FSM (`ok_file` / `broken_file`, mediante `pkg/fsm`); los torrents y las copias tienen el suyo propio. Cuando los enlaces dejan de servir bytes, la reparación escala por estrategias:

1. **Reiniciar en el sitio** (`TorrentRestarter`): la más barata. No hay subida nueva, no se gasta ningún slot de adición, y el torrent conserva su id, así que la entrada de la biblioteca sobrevive en lugar de borrarse y volver a descubrirse. El refresco la lanza para un torrent fallido que encuentra en la cuenta, y solo en una instancia que tenga permiso para actuar sobre torrents fallidos: `enable_repair` o `delete_error_torrents`. Si ambas están desactivadas, la cuenta se deja como está (`mayRestartFailedTorrents`).
2. **Volver a descargar los archivos rotos**: volver a seleccionar solo lo que está roto.
3. **Reinsertar**: volver a añadir el magnet y recoger enlaces nuevos.
4. **Archivar**: último recurso para las releases que no se pueden recuperar.
5. **Ofrecérselo a una cuenta que no lo tiene** (`repair_across_accounts.go`): los servicios mantienen cachés independientes, así que una release que una cuenta ha purgado, o que rechaza por nombre de archivo, puede estar en caché en otra. Cuando ninguna cuenta que tiene la release puede arreglarla, se pregunta en orden a las cuentas configuradas que no la tienen, y la primera que ya tiene el hash se la queda. El listado que sigue la une a la entrada como segunda copia a través de la ruta habitual `absorbCopy`, que limpia por sí sola el veredicto de la entrada. Siempre solo en caché, mediante `AddIfCached` y nunca mediante `restrict_repair_to_cached`: una adición que la cuenta tendría que descargar se retira y se vuelve a borrar, así que esto es una reparación y nunca una nueva descarga. Una cuenta que no responde entra en espera de entre un día y unas dos semanas, y un barrido hace como máximo diez ofertas. Eso es lo que hace asumible ejecutarlo sin que nadie lo pida contra una biblioteca de releases condenadas.

Alrededor de todo esto hay backoff exponencial, techos de reintentos por copia (`RepairCycles`, `AssignRetries`, persistidos para que los techos sobrevivan a los reinicios), límites horarios de adiciones desde `Capabilities.AddsPerHour`, comprobaciones de slots activos, deduplicación mediante una cola basada en un set, y una heurística de todo el barrido que lee una ráfaga de fallos de hoster no disponible como una caída de un solo proveedor en lugar de N torrents rotos.

Los veredictos de irreparable se registran por copia y solo se propagan a la entrada cuando *todas* las copias tienen uno. Un error permanente de Real-Debrid no dice nada sobre la copia de TorBox.

Un operador puede forzar una reparación a mano. La condición de forzado vive en el torrent y no en el contexto, porque una petición que llega a mitad de barrido se aparca en la cola y se recoge más tarde con el contexto propio del barrido.

El botón también llega al paso 5, y en ese orden: primero borra todos los veredictos de la release, así que la cuenta que la tiene se reintenta exactamente como antes, y la oferta solo sigue si ese intento falla. Como borra esos veredictos, un torrent con nombre es elegible cuando el barrido recoge sus entradas condenadas, y solo vuelve a quedar condenado por la reparación que acaba de ejecutarse. Por eso se recoge después de esa reparación y no en el bucle. Si no, el único camino en el que alguien está esperando sería el único que nunca ofrece.

### Todo lo demás del paquete {#everything-else-in-the-package}

`mediainfo.go` (análisis con ffprobe que alimenta las etiquetas de duración y códec), `tags.go`, `rename.go` (renombrados que deben sobrevivir a la actualización), `delete.go`, `strm.go` (genera archivos `.strm` para toda la biblioteca), `hooks.go` (scripts de usuario en eventos del ciclo de vida), `assign_links.go`, `unrestrict.go`, `opensubtitles.go`, `provider_directories.go`, `reset_all.go`.

## Capa 4 — Servicio {#layer-4--serving}

### Router

`internal/handlers` construye el router de chi y conecta todo. Los métodos no estándar de WebDAV (`PROPFIND`, `MKCOL`, `MOVE`) se registran en chi en `init`. La autenticación básica envuelve todo *excepto* `version.txt` y `/ready` (para que funcionen los health checks) y los endpoints `.strm` (un reproductor multimedia que abre un `.strm` no tiene credenciales que enviar; en su lugar, el token firmado en la ruta lo autoriza).

Hay dos lecciones de enrutamiento anotadas en los comentarios que vale la pena no volver a aprender: chi aplica un parámetro de ruta con regex **dentro de un solo segmento**, así que un archivo al que se accede a través de un archivo comprimido (`<archive>.rar/<inner>.mkv`) o un directorio anidado dentro de uno no coincidía con ninguna ruta. Ambos necesitaban comodines al final. Y una ruta dentro de un torrent se divide entre listado y descarga según tenga o no una barra final, una vez que la ruta deja de importar qué tan profunda es.

### Listados {#listings}

`internal/dav` genera el XML de PROPFIND y gestiona DELETE, MOVE (renombrados, con validación entre directorios y entre torrents) y las variantes de Infuse.
`pkg/dav` genera el XML en sí con construcción de cadenas optimizada en lugar de marshalling XML, hace la conversión de RFC 3339 a RFC 1123 que necesitan los clientes WebDAV y escapa las rutas tanto para URL como para XML.

`internal/htmlindex` muestra el mismo árbol como HTML para `/http/`.

Ambos aplican las mismas reglas de visibilidad (solo el archivo más grande, umbrales de tamaño, estado broken/deleted) y ambos agrupan los archivos RAR de varios volúmenes para que solo sea visible el primer volumen.

### La ruta de bytes {#the-byte-path}

`internal/universal` es donde una petición se convierte en bytes:

- La resolución de enlaces se deduplica con `singleflight`, así que cien lecturas simultáneas del mismo archivo cuestan una sola resolución.
- Proxy o redirección, según `disable_stream_proxy`. Excepto que un enlace servido localmente (`ServesLinksLocally`) nunca puede redirigirse, porque el cliente no tiene nada que abrir.
- Vuelve a hacer el unrestrict de un enlace roto, hasta un límite pequeño.
- Un enfriamiento por archivo para fallos de red: 3 errores seguidos dejan el archivo en pausa durante 5 minutos. Eso es lo que evita que un host CDN inalcanzable se convierta en un bucle de reintentos infinito.
- Pausas breves durante una ventana de límite de tasa en lugar de devolver error. Si las lecturas dan error durante el enfriamiento corto, una cuenta limitada se convierte en una tormenta de errores a través del VFS de rclone: esperas bloqueadas, lectores en estado D, un servidor multimedia colgado. Por eso, retener la lectura es la opción más barata. Las clases de enfriamiento más largas siguen fallando rápido.
- Contabilidad de ancho de banda por token, con los contadores reiniciados a medianoche CET para coincidir con el reinicio diario de tráfico de Real-Debrid.

### Archivos {#archives}

`internal/rarstream` analiza las cabeceras RAR4, RAR5 y ZIP mediante peticiones de rango de bytes (HTTP 206), construye un mapa de fragmentos entre volúmenes y reconstruye el contenido de un solo archivo sobre la marcha. **Sin descompresión**: solo se admiten datos almacenados, que es lo que usan los releases scene. `VolumeKey` e `IsVolume` normalizan las muchas convenciones de nombres de partes múltiples (`.part001.rar`, `.r00`, `.rar`) que `dav` y `htmlindex` usan para agrupar los volúmenes en una sola entrada. Los listados se guardan en caché en el torrent y se marcan con el `ListingVersion` del analizador, así que un listado generado por otro analizador se descarta en lugar de servirse.

### STRM

`internal/strmlink` codifica y firma la URL que contiene un `.strm`. El esquema solo para Real-Debrid al que sustituye era seguro por casualidad: la URL contenía el código de descarga de 13 caracteres de RD, así que tenerla *era* la prueba de autorización. Otros backends direccionan los archivos con ids fácilmente enumerables (`torbox://17/3`), así que con la misma forma cualquiera que pudiera llegar al puerto podría generar URLs del CDN para la cuenta o gastar sus conexiones a servidores Usenet. Un HMAC sobre un secreto guardado en `data/strm_secret` evita eso: un token que zurg no escribió no se resuelve. El secreto debe sobrevivir al proceso: cada `.strm` ya escrito seguirá siendo válido solo mientras lo siga siendo su clave de firma.

### Panel y gestión {#dashboard-and-management}

`internal/handlers/dashboard` genera la interfaz web a partir de plantillas incrustadas, que se analizan al arrancar para que un error de sintaxis falle al momento y no cuando llegue una petición. Las páginas son: estado de torrents en vivo, un editor interactivo de configuración YAML, latencia del host, gestión de directorios, gestión de proveedores, estado de la conexión con los servidores de medios, información de cuenta y premium, ancho de banda, estado de rclone y las estadísticas "Wrapped" de Plex. Los obtenedores de estado de cada servidor de medios se ejecutan en paralelo para que las páginas carguen rápido.

`internal/handlers/manage` es la interfaz de operaciones por torrent: etiquetas, listados de archivos con detalle de estado, coincidencia con Plex, renombrados, eliminar/restaurar/forzar mostrar por archivo, eliminación masiva y escaneo.

Su vista de duplicados es `internal/duplicates`. `internal/arrinventory` y los lectores `Inventory` junto a los adaptadores de Radarr y Sonarr leen cada archivo que tiene un \*arr, en modo solo lectura y sin intervenir en la adquisición. `magic.Resolver.HolderOf` rastrea la ruta de cada archivo hasta la release de la que vino, y el paquete agrupa las releases que pueden contener la misma película o los mismos episodios. La agrupación usa nombres, IDs de IMDb y el historial de \*arr. Si una release está en uso lo decide únicamente el rastreo de rutas.

`internal/static` incrusta CSS, favicon, logo y robots.txt con `go:embed`, así que el binario es autocontenido.

## Capa 5 — El montaje {#layer-5--the-mount}

`internal/rclone` supervisa rclone como subproceso: construye el comando de montaje (un remoto WebDAV que apunta a `/dav/` de zurg), lo inicia y lo detiene, comprueba su estado cada 30 s con una espera exponencial antes de reiniciar (de 1 s a 60 s) y lo reinicia si falla.

En el arranque se elige un puerto RC efímero dentro del rango 49152–65535 para invalidar la caché de VFS y consultar el estado. Esa invalidación es importante en dos momentos: cuando la biblioteca en caché termina de cargarse y otra vez después de la primera actualización completa. Si no, los listados parciales que el montaje obtuvo a mitad de la carga se quedan durante todo el `--dir-cache-time`.

Las credenciales se pasan mediante una variable de entorno, nunca en la línea de comandos. `Controller` es la interfaz que usan los manejadores y el panel, mientras que `Runner` y `Command` abstraen la gestión de procesos para las pruebas.

## Capa 6 — Servidores multimedia {#layer-6--media-servers}

Dos cosas distintas comparten la palabra "Plex":

- **`pkg/plex`, `pkg/jellyfin`, `pkg/emby`** son *clientes* de servidores de medios, y cada uno cumple con `common.MediaServerWorker`. `pkg/common` ofrece el ciclo de vida compartido de los trabajos: una cola dinámica sin límite, seguimiento de reintentos por trabajo, backoff exponencial con jitter, un circuit breaker tras fallos consecutivos y detección de trabajos atascados. También incluye las funciones de rutas que se encargan del APFS de macOS, que no distingue mayúsculas. `pkg/scan` está encima como un `MediaScanner` unificado que envía un trabajo de actualización de rutas al servidor que tenga esa ruta e informa de la profundidad de la cola de cada servidor.
- **`internal/plex`** es el comportamiento específico de zurg: `Matcher` relaciona torrents con los elementos de la biblioteca de Plex usando rutas de archivo, ids de IMDB e identificadores de TVDb/TMDb. Se ejecuta periódicamente en pools de workers con metadatos en caché, y rellena en los torrents los ids de IMDB que descubre.
- **`internal/acquisition`** gestiona la cola de adquisición persistente y el executor compartido, que obtiene NZB de indexadores Newznab y torrents en caché de indexadores Torznab. La watchlist de Plex, Seerr, Radarr y Sonarr son adaptadores de origen que convierten las solicitudes en objetivos de película, temporada o episodio. `data/acquisition.json` guarda los plazos de reintento y el progreso por objetivo entre reinicios. Consulta [fuentes de adquisición](../guides/acquisition.md) para la configuración y los contratos de los adaptadores.

`pkg/mediabrowser` contiene los tipos que comparten Emby y Jellyfin.

## Capa 7 — Soporte {#layer-7--support}

| Paquete | Para qué sirve |
|---|---|
| `pkg/fsm` | Dos variantes de máquina de estados pequeña: `FSMWithExternalMutex` para cuando la FSM va dentro de algo que ya tiene su propio bloqueo, y `FSMWithTime` para cuando necesita su propio bloqueo y una marca de tiempo de cada transición (así `SinceWhen` puede responder "cuánto tiempo lleva roto esto"). |
| `pkg/logutil` | Zap con doble salida: consola en color y un archivo rotativo (10 MB × 20 mediante lumberjack). La verbosidad sale de `log_level` en config.yml; si no está, usa la variable de entorno `LOG_LEVEL` y, si tampoco, DEBUG. El nivel vive en un `zap.AtomicLevel` compartido, así que el panel puede cambiar el nivel de todos los loggers a la vez sin reiniciar. Incluye la lectura del log para el visor del panel y para Export Logs. |
| `pkg/utils` | Persistencia de hosts bloqueados, reglas de visibilidad de archivos, ocultación de tokens, detección de video/audio, nombres `.strm` y `GetZurgBaseURL` (que respeta `X-Forwarded-*` detrás de un proxy inverso). |
| `pkg/script` | Ejecuta los scripts de eventos del ciclo de vida que define el usuario; PowerShell en Windows, `/bin/sh` en el resto. |
| `pkg/dmm` | Cliente para la API de búsqueda de debridmediamanager.com, limitado a 1 petición cada 2 segundos, que es lo que impone el servidor. Lo usa el monitor de la lista de seguimiento. |
| `internal/version` | Metadatos de compilación inyectados con ldflags; también el banner ASCII en `/http/version.txt`. |
| `internal/requirements` | Descarga `ffprobe` y `rclone` compatibles con tu plataforma desde las releases de GitHub la primera vez que se ejecuta, y escribe rutas *relativas* en config.yml para que la configuración sea portable. Las plataformas no compatibles muestran un aviso en lugar de fallar. |
| `internal/clear` | Borra en bloque las descargas y torrents de RD usando la interfaz web con una cookie de autenticación, repitiendo hasta que no quede nada. |
| `internal/handlers/tmplcache` | Caché de plantillas para el panel. |

## Decisiones transversales {#cross-cutting-decisions}

**Capacidades en lugar de `if provider == "realdebrid"`.** Cualquier cosa que asuma la forma de Real-Debrid debe ir detrás de una bandera de capacidad, no de una comprobación de tipo. Esta es la regla que mantiene al gestor de torrents independiente del backend.

**El contrato de la interfaz son bytes, no proxy.** `Provider` nunca promete un CDN remoto; solo que una petición GET con rango pueda responderse. Por eso encaja un backend de Usenet. Los dos sitios donde se filtró la suposición del CDN (las redirecciones y pasar una URL a ffprobe, que necesita algo que un binario externo pueda abrir) ahora están protegidos por `ServesLinksLocally`.

**El emparejamiento posicional de enlaces es crítico.** `TorrentInfo.Links[i]` se empareja con el i-ésimo archivo **seleccionado** de `TorrentInfo.Files`. Un proveedor que no pueda enlazar un archivo debe reportarlo como *no seleccionado* en lugar de omitirlo; si no, todos los archivos siguientes se resolverán silenciosamente al enlace equivocado. Todos los backends deben cumplir esto.

**Un torrent pertenece a exactamente una cuenta.** Cualquier llamada que llegue a un servicio debe despacharse a través del proveedor del torrent (`ProviderFor`, `resolveLink`, `verifyLink`, `DeleteByID`), nunca a través del proveedor principal. Si esto sale mal, se borra en la cuenta equivocada.

**El disco es un nivel real.** Las entradas `.zurgtorrent`, el detalle por torrent en `data/info/`, los resultados de las pruebas de red y sus marcas de tiempo, las marcas de tiempo de los trabajos, el secreto de firma de STRM, las cachés de listados RAR y los hosts bloqueados. Al reiniciar se reanuda en lugar de volver a escanear.

**Todo va con ritmo controlado.** Cubos de tokens por proveedor, límites de concurrencia, cupos horarios para añadir, TTL de enlaces, enfriamientos por archivo y pausas por límite de peticiones. En TorBox sobre todo, la resolución de enlaces es el recurso escaso, y la caché de enlaces que hay delante es lo que hace posible escanear una biblioteca.

**Las lecturas no usan bloqueos, las escrituras son acotadas.** Los mapas concurrentes sostienen los árboles de directorios, torrents y archivos; la mutación se protege con bloqueos por torrent (`copiesMu`, `tagsMutex`, `operationsMutex`, `archiveCacheMutex`) en lugar de con algo global.

**`rdclient` es compartido, pero su política es la de Real-Debrid.** Su clasificación de errores y sus reglas de reintento vienen de RD. Reporta un código no 2xx como error aunque siga devolviendo la respuesta, así que un proveedor que necesite el estado (un 429 con `Retry-After`) debe revisar `resp` antes que `err`.

## Compilar, probar y desplegar {#build-test-deploy}

- **Build**: `make build`. La versión, el commit y la hora de compilación se inyectan mediante
  ldflags en `internal/version`.
- **Unit tests**: `go test ./...`. El pre-commit ejecuta gofmt, golangci-lint,
  `go test -short` y un conjunto de calidad completo.
- **Integration tests**: `make integration-test`, de más barato a más caro, con
  `refresh_repair` al final porque espera a que termine un escaneo completo de la biblioteca. Ejecútalos en un
  equipo que tenga Go, rclone, FUSE y Plex juntos. En otro caso, las pruebas de montaje y de Plex se omiten con un aviso bien visible pero aun así terminan con código 0, así que fíjate en la salida y no en el código de salida. Consulta [e2e-test.md](e2e-test.md).
- **Docker**: compilación en dos etapas sobre Alpine; la imagen de ejecución añade ffmpeg, rclone,
  fuse3 y un healthcheck.
- **Deploy**: `make deploy USER=… HOST=… DIR=…`, que detiene Plex y los servicios de zurg,
  reemplaza el binario, espera a que `version.txt` responda 200 y luego reinicia Plex.

## Por dónde empezar a mirar {#where-to-look-first}

El código de este proyecto suele dejar constancia del *porqué* en los comentarios, normalmente con el fallo que motivó el cambio. Cada paquete tiene un `doc.go`. Si vas a cambiar algo, lee primero el `doc.go` de ese paquete y el comentario de bloque encima del tipo que vas a tocar: ahí están las restricciones que no se ven en las firmas.
