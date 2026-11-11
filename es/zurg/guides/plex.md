# Funciones y capacidades de Plex {#plex-features--capabilities}

¿Ejecutar rex junto a Plex Media Server, o en lugar de él? [Migrar de Plex a rex](../../rex/from-plex.md) explica qué mantener en zurg, incluido tu montaje de rclone, y qué ajustes de Plex de zurg eliminar.

## Configuración y almacenamiento {#configuration--storage}
- Claves de configuración documentadas en [`config.md`](../reference/config.md)/`config.example.yml`: `plex_server_url`, `plex_token`, `plex_match_every_mins` (valor por defecto 1440), `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` (la forma antigua de escribir `watchlist.check_every_secs`, valor por defecto 60s), `mount_path` (obligatorio para la coincidencia y la construcción de rutas de escaneo). Los ajustes creados desde el panel se guardan directamente en `config.yml` mediante el escritor de configuración (`updateConfigFileAtomic`).
- El intervalo de la watchlist vuelve al valor por defecto para cualquier valor de 0 o menor (`GetWatchlistCheckEverySecs`); `plex_match_every_mins` vuelve al valor por defecto solo cuando es exactamente `0` (`intOr`, `internal/config/config.go`). Ninguno de los dos se puede desactivar. El panel rechaza cualquier valor menor que 1 (`internal/handlers/dashboard/dashboard.go`), y un `plex_match_every_mins` negativo en `config.yml` detiene zurg al arrancar con `is negative; use 0 for the default`; nunca desactiva la coincidencia.
- La adquisición desde la watchlist se configura con el bloque `watchlist:`: `enabled`, `check_every_secs`, `indexers`, `max_size_gb`, `max_season_size_gb` y `quality` (valor por defecto `best`). Si `indexers` está vacío, se toma `stremio.indexers`. Las claves planas `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` y `watchlist_quality` siguen contando como las formas antiguas de la primera, la segunda y la última de esas opciones. Consulta [config.md](../reference/config.md#watchlist).
- `mount_path` también es el prefijo de las rutas de escaneo que se envían a Plex y al montaje rclone gestionado ([`config.md`](../reference/config.md), `pkg/scan/scanner.go`).
- El hook de actualización de biblioteca (`on_library_update`) recibe cada ruta modificada como argumento, con un retraso de 500 ms y sin duplicados, y solo se ejecuta una invocación a la vez. Sirve para los scripts de autoscan de Plex (`internal/torrent/hooks.go`).

## Autenticación y descubrimiento de servidor {#authentication--server-discovery}
- Flujo del panel web: `/plex/auth` crea una sesión PIN (`pkg/plex/auth.go`, `CreatePlexAuthURL`), la guarda en `pkg/plex/auth_session.go` (limpieza automática a los 10 min, revisión cada 5), y consulta si ya se completó en `/plex/auth/status` (`PollForAuthToken`, 60 intentos cada 5 s antes de agotar el tiempo).
- `/plex/callback` muestra una página de progreso que, una vez autorizada, llama a `/plex/servers` para listar los servidores y a `/plex/server` para elegir uno (`internal/handlers/dashboard/dashboard.go`).
- Descubrimiento de servidores (`pkg/plex/auth.go`): obtiene los recursos de Plex con los endpoints HTTP y HTTPS, filtra el relay si existe una conexión directa, gestiona direcciones IPv6 y prueba `/identity` de cada entrada (con la verificación TLS desactivada). Solo se consideran los servidores **propiedad** de la cuenta (`device.Owned`, `auth.go`); los compartidos nunca aparecen. Las entradas que fallan la prueba se eliminan de la respuesta en lugar de devolverse con `last_error` definido (`enrichServersWithIdentity`, `auth.go`).
- Al elegir un servidor se escriben `plex_server_url` y `plex_token` en la configuración, se reinicia el cliente de Plex, se (re)inicia el programador del matcher, se dispara un match trigger y se actualiza la caché del estado del panel (`HandlePlexServerSelect`, `internal/handlers/dashboard/dashboard.go`). `/plex/logout` borra los valores guardados y la caché de estado.

## Capacidades del cliente de Plex (`pkg/plex/client.go`) {#plex-client-capabilities-pkgplexclientgo}
- Ciclo de vida de la conexión: opción de inicio diferido (`WithDeferredStart`), guardia `ValidateConnection` contra `/identity` y `Close` ordenado. No hay API de reinicio. Los campos `RestartAllowed`/`RestartReason` del dashboard se infieren de la URL del servidor (local/LAN frente a remoto) y solo sirven para mostrar información (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`).
- Cola de escaneos: cola de trabajos dinámica con worker (`common.DynamicJobQueue`). `ProcessJob` lanza `GET /library/sections/{key}/refresh` con las cabeceras de Plex y **como máximo un** parámetro de consulta `path` por trabajo. Si hay más de uno, se rechaza directamente (`client.go`). Un trabajo sin path es un refresco de toda la sección. Un 503 se convierte en un error de servidor ocupado, y un 404 informa de que la biblioteca se ha eliminado de Plex. `GetJobQueueSize` expone el backlog.
- Detección de carga y atascos: `CheckServerLoad` inspecciona `/activities` y sigue el progreso de `library.update.section` por UUID (un cambio en el progreso *o* en el subtítulo cuenta como progreso). `IsJobStuck` marca como atascados los trabajos obsoletos por `librarySectionID`, con Title como respaldo. `GetServerActivitiesDetails` crea y retira los mismos rastreadores, porque `CheckServerLoad` solo se ejecuta mientras el worker tiene un trabajo en cola. Antes, un escaneo que Plex lanzaba por su cuenta no tenía ningún rastreador. Por eso nunca se podía reportar como atascado, y su tiempo transcurrido aparecía como cero en cada refresco. Ambas rutas guardan historial solo para `library.update.section`. Rastrear cualquier otra cosa aquí haría que oscilara frente a la poda del worker.
- **El subtítulo de actividad no es el archivo en el que está bloqueado un escaneo pendiente.** Medido en el entorno de pruebas plex503, el 2026-09-15: el subtítulo de `library.update.section` es el puntero de enumeración del escáner y va por delante de las lecturas. Con el montaje rechazando tres archivos, nombró un cuarto que nunca se había pedido. Además, nombró el archivo bloqueado durante 290 ms de un ciclo de 56 s. El dashboard lo muestra como "Plex reports" y no lo enlaza a ningún release. Lo que el escaneo realmente está esperando sale de los rechazos de zurg (`internal/universal/refused_reads.go`), que es el único lado que lo sabe. El corpus está en `internal/handlers/dashboard/testdata/plex503-*`.
- Consultas de biblioteca: `GetSections` (secciones de películas/series con sus ubicaciones), `GetSectionItemCount`, `FindSectionNormalized` (compara una ruta con la ubicación de una sección y corrige el prefijo a las mayúsculas/minúsculas de la biblioteca), `GetAllMediaItemsConcurrent` (obtención por lotes y concurrente con `includeGuids` para recoger rutas, GUID e IDs de IMDB) y `GetShowLevelIMDBIndex` (IDs a nivel de serie para las secciones de TV, para que los episodios puedan heredarlos).
- Ayudantes de metadatos y emparejamiento (`pkg/plex/match.go`): `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`), `GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`, con anulaciones de title/year/language), `LookupMetadataByGUID`/`LookupRatingKeyByGUID` (`GET /library/all?guid=…`), `ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`) y el parseo de GUID (`ExtractIMDBIDFromGUID`, `ExtractTMDBIDFromGUID`, `ExtractTVDBIDFromGUID`, `ExtractAnyIDFromGUIDs`; tipos `MatchResult`/`MatchSelection`).
- Información del servidor: `GetServerIdentityOnly` y `GetServerDetails` (ID de máquina y versión; este último además suma sesiones, transcodificaciones y ancho de banda), `GetStreamingSessions`, `GetTranscodeSessions` y `GetServerActivitiesDetails` (anotado con el estado de atasco).
- Historial de reproducción: `GetWatchHistory` (`GET /status/sessions/history/all`), `GetMetadataBatch` (claves de rating separadas por comas contra `/library/metadata`) y `GetWatchHistoryWithMetadata` (`pkg/plex/history.go`), que alimentan las estadísticas de `pkg/plex/stats.go`.

## Integración con el escáner de medios (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Inicializa el cliente de Plex cuando `mount_path`, `plex_server_url` y `plex_token` están configurados; reintenta cada 5s hasta conectarse, disparando los callbacks de `OnPlexReconnected`.
- `TriggerScan` agrupa las rutas por sección de Plex (mediante `FindSectionNormalized`) y encola un trabajo de refresco por cada ruta con el prefijo de `mount_path`, registrando el progreso cada 50. También es compatible con Jellyfin/Emby, que siguen la ruta no agrupada. Una ruta que no cae en ninguna sección solo genera un aviso cuando *ninguna* de las rutas del lote coincidió; si no, es una línea de depuración, así que un torrent que está tanto en un directorio de biblioteca como en un directorio solo de zurg (recent, music, …) no genera aviso.
- `ReinitializePlexClient` permite que las actualizaciones del panel cambien servidores y tokens en caliente.
- `GetQueueSizes` expone la profundidad de la cola de Plex para la interfaz y la monitorización.

## Coincidencia y sincronización de metadatos (`internal/plex/matcher.go`, `internal/plex/schedule.go`) {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- Requisitos previos: necesita la URL y el token de Plex configurados, `mount_path` y un `scanner.PlexClient` activo. Si no, devuelve errores explícitos.
- Lo único que se guarda de Plex en un torrent es `PlexRatingKey` (a nivel de serie para contenido por episodios) y `IMDBID` (`internal/torrent/torrent_types.go`). Los GUID de Plex se usan durante el proceso para extraer IDs y para los informes, pero nunca se guardan.
- Recopilación de datos: obtiene todos los torrents del mapa de directorios y todos los elementos de Plex mediante `GetAllMediaItemsConcurrent`. Antes se ejecuta un paso de `GetShowLevelIMDBIndex`, para que los episodios hereden el ID de IMDB/TVDB/TMDB de la serie en vez de uno a nivel de episodio. Los elementos se indexan por `GrandparentRatingKey` cuando existe.
- Pasos de sincronización:
  - Valida cada rating key guardada contra los elementos de Plex recién obtenidos. Si Plex ya no tiene una key, se borra junto con el ID de IMDB del torrent y el torrent vuelve a la cola para emparejarse.
  - Emparejamiento por ruta para los torrents sin rating key: `buildPlexDirIndex` indexa cada componente de ruta en minúsculas de cada archivo de Plex, y el `GetKey` del torrent se busca en ese índice (O(1), gana la primera entrada). Los torrents cuyos directorios asignados no coinciden con la ubicación de ninguna sección de Plex se saltan antes.
  - Relleno de IMDB: primero desde el lote ya obtenido (sin llamadas a la API) y luego torrent por torrent con `GetMetadataSummary` (máximo 20 simultáneos).
  - Detecta elementos de Plex sin torrents.
  - Envía a DMM los pares hash+IMDB que una persona ha puesto a mano, nunca los IDs que Plex haya adivinado. DMM los acepta sin key, y `dmm_api_key` se envía junto con ellos cuando está configurada (`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`, `internal/torrent/mediainfo.go`).
- `MatchSingleTorrent` ejecuta la misma búsqueda por ruta para un solo torrent, pensada para usarse justo después de un escaneo dirigido. No hace nada si el torrent ya tiene un rating key.
- Informes: escribe `logs/match_report.txt` con un resumen de los recuentos, torrents sin emparejar, torrents saltados, elementos de Plex sin torrents y emparejamientos sin IMDB.
- Programación (`internal/plex/schedule.go`): cada ejecución completada guarda una marca de tiempo en `data/plex_match_timestamp`. Al arrancar, `StartMatchingJob` se ejecuta de inmediato solo si esa marca no existe o es más antigua que `plex_match_every_mins`; si no, espera lo que falte antes. Escucha los disparos manuales en `TorrentManager.PlexMatchTrigger`, los cambios de intervalo en vivo en `ResetPlexMatchTicker`, y vuelve a ejecutar el trabajo hasta tres veces si entra en pánico.
- El endpoint de disparo manual `/plex/match-torrents` envía una señal al canal de disparo y rechaza la petición si ya hay una ejecución en curso. `/plex/match-torrents/status` indica si hay una ejecución en marcha (`internal/handlers/utilities.go`).

## Coincidencia manual e interfaz de gestión (`internal/handlers/manage`) {#manual-matching--manage-ui-internalhandlersmanage}
- Los filtros de la lista de torrents muestran los estados de Plex (`plex_matched`, `plex_in_library_not_matched`, `plex_no_imdb`, `plex_missing_metadata`) para vistas rápidas (`torrent_list_state.go`).
- Página de coincidencia manual por torrent `/manage/{hash}/plex-match`:
  - Requiere que el torrent ya tenga un `PlexRatingKey` (lo pone el matcher); si no lo tiene, la página muestra "torrent is not linked to Plex". `resolvePlexRatingKey` valida esa clave con `GetMetadataSummary`, rellena el ID de IMDB si falta y, si la clave está obsoleta, vuelve a buscarla con `LookupRatingKeyByGUID` usando el ID `tt…`/`tvdb://`/`tmdb://` guardado en el torrent (`internal/handlers/manage/handler.go`).
  - Obtiene los candidatos de coincidencia manual de Plex con título, año e idioma opcionales (44 opciones de idioma, por defecto `en-US`) y muestra las coincidencias con la selección actual resaltada (`torrent_matches.go`).
  - Al aplicar una coincidencia (`HandleApplyPlexMatch`), se llama a `ApplyManualMatch` y luego se vuelve a buscar la clave de rating con el GUID elegido, porque Plex puede reasignarla. Después se actualizan la clave de rating y el IMDB del torrent (incluido el IMDB opcional que indique el usuario), se guardan los cambios y se redirige con los estados de éxito o error.

## Adquisición desde la lista de seguimiento {#watchlist-acquisition}

- El watchlist de Plex es un adaptador en `internal/acquisition/plex`, que se ejecuta en el servicio de adquisición compartido junto con Seerr. Los ajustes actuales del watchlist siguen funcionando; los adaptadores también se pueden configurar en `acquisition.sources`.
- El cliente usa `discover.provider.plex.tv` y pagina de 100 en 100. El token de Plex se lee de nuevo en cada petición, así que una nueva autenticación se aplica sin reiniciar el adaptador.
- El ejecutor compartido adquiere películas o cada temporada planificada desde indexadores Newznab y Torznab, dando preferencia a los packs de temporada. Las búsquedas de series prueban TVDB antes que IMDb, porque los mapeos de los indexadores son distintos.
- El progreso, los plazos de reintento y los recibos por episodio se mantienen tras reiniciar en `data/acquisition.json`. El libro de registro anterior de Plex se importa automáticamente.
- La eliminación se hace después de adquirir todos los objetivos planificados. Las peticiones fallidas se quedan en el watchlist y se reintentan con un retroceso persistente. Un reintento solo de eliminación no vuelve a adquirir nada. Consulta [Watchlist de Plex: adquisición](plex-watchlist.md) para ver los límites y [fuentes de adquisición](acquisition.md) para la configuración compartida.

## Panel y endpoints de la API (`internal/handlers/router.go`, `internal/handlers/dashboard`) {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- Routes: `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`.
- El panel muestra la información y el estado del servidor de Plex mediante `PlexStatusFetcher`, con dos temporizadores: cada 30 s actualiza las sesiones de streaming, las transcodificaciones, el ancho de banda y las actividades del servidor (`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`); cada 5 minutos hace una actualización completa que también vuelve a leer la identidad (`GetServerIdentityOnly`), las secciones de la biblioteca y el número de elementos de cada sección. Las actividades de escaneo se cruzan con la lista de torrents por nombre de archivo, para que el panel pueda enlazar una actividad con el hash de un torrent.
- Los endpoints de escaneo de una sección o de todas las secciones encolan una actualización **completa** de la sección (`RefreshSection(key, nil)`, sin ruta) para una o todas las secciones; no tocan los archivos STRM ni disparan efectos secundarios en la biblioteca (`HandlePlexScan`/`HandlePlexScanAll`).

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- `/plex-stats` muestra una presentación de 9 diapositivas con tu resumen del año a partir del historial de reproducción de Plex de los últimos 12 meses. `/plex-stats/data` devuelve las mismas estadísticas en JSON, y `/plex-stats/image` genera una PNG para compartir usando headless chromedp (`square` 1080x1080 por defecto, `instagram` 1080x1920, `facebook` 1200x630).
- Las estadísticas se consultan como máximo una vez cada 24 h (`?refresh=true` fuerza una nueva consulta), están limitadas a 10000 elementos del historial y se guardan en caché tanto en memoria como en disco, en `data/plex_wrapped_cache.json`, que se vuelve a cargar al iniciar. Mientras una consulta está en curso, la página muestra un estado de carga en lugar de bloquearse.

## Efectos secundarios en la biblioteca y enlaces de actualización {#library-side-effects--refresh-links}
- Los efectos secundarios de la biblioteca se disparan al cambiar la asignación de directorios, al renombrar, al eliminar y al reparar archivos: `TriggerLibrarySideEffects` invalida la caché de directorios (dircache) del VFS de rclone para las rutas afectadas (así los servidores de medios no escanean un listado desactualizado), llama a `MediaScanner.TriggerScan` (lo que dispara la actualización de Plex) y ejecuta el hook `on_library_update` del usuario (`internal/torrent/hooks.go`).
- El pipeline de actualización solo genera los STRM y ejecuta los efectos secundarios una vez que termina la inicialización, para evitar escaneos prematuros de Plex (`internal/torrent/refresh.go`).

## Infraestructura y scripts {#infrastructure--scripts}
- Ejemplo de vhost de Nginx para hacer proxy del tráfico de Plex (`nginx/plex.conf`).
- `plex_update.sh` es el script de referencia de escaneo parcial para `on_library_update: sh plex_update.sh "$@"`; colócalo junto a `docker-compose.yml`, cuya carpeta se monta en `/config`, así que el script ya está dentro del contenedor. En Windows el hook se ejecuta a través de PowerShell en lugar de `/bin/sh` (`pkg/script/script.go`), así que este script no se ejecuta allí; [Usenet → Point Plex at it](usenet.md#6-point-plex-at-it) muestra la forma para PowerShell.
- `integration/plex_integration.sh` se ejecuta con `make integration-test` y `make integration-test-media`; si el host no tiene un servidor de Plex, se salta con un aviso bien visible, así que lee la salida en lugar de fijarte en el código de salida. `scripts/plex-e2e-test.sh` es una comprobación de reproducción independiente que lee `plex_server_url`/`plex_token` de `config.yml`.

## Ajustes recomendados de Plex {#recommended-plex-settings}

Los valores predeterminados de Plex asumen discos locales que siempre están presentes y que se pueden leer sin problemas. Un montaje de zurg no es nada de eso: sus bytes llegan desde un proveedor por HTTP, y puede quedar brevemente sin poder leerse mientras rclone se reconecta. Varios valores predeterminados de Plex son directamente perjudiciales en esas condiciones.

zurg vuelve a aplicar estos ajustes en cada actualización de estado de Plex. `plex_settings_policy` decide hasta dónde llega: `off`, `warn`, `guard` (predeterminado) o `enforce`. La lista está en `pkg/plex/settings.go` (`RecommendedSettings`), y la política, en `pkg/plex/reconcile.go`.

Un ajuste que el servidor no informa se omite, así que una versión de Plex que no lo tenga no se marca como mal configurada.

Nueve de los dieciséis valores de abajo difieren del valor predeterminado de Plex. Los otros siete coinciden con él y funcionan como guardas más que como correcciones: solo se activan si el operador ha cambiado alguno. Esas filas muestran el mismo valor en ambas columnas, y no es un error. Plex trae `GenerateBIFBehavior` en `never`, pero el servidor contra el que se midieron estos valores estaba en `scheduled`. Plex informa su propio valor predeterminado para cada ajuste en `/:/prefs`, así que la columna "Plex ships" de abajo se lee del servidor y no se supone (medido el 2026-09-05 con Plex 1.42.2).

### Desactivar un ajuste concreto {#opting-out-of-one-setting}

`plex_settings_policy` tiene niveles, y el nivel no siempre es lo que se pregunta. Si tus archivos se mueven entre carpetas de la biblioteca (por ejemplo, con una ordenación basada en etiquetas), dependes de que Plex vacíe su propia papelera para limpiar la entrada que queda, y `guard` lo desactiva. Bajar a `warn` para recuperarlo también elimina las guardas de eventos del sistema de archivos, que están en el mismo nivel y no es lo que buscas.

`plex_settings_ignore` nombra los ajustes uno por uno:

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

El panel escribe esta lista por ti. La página de configuración tiene un interruptor **Let Plex Empty Its Own Trash** encima de los ajustes de Library Trash Sweep. Añade y quita `autoEmptyTrash` aquí, y deja el resto de la lista como está. Al activarlo, el cambio se aplica en el próximo reinicio.

Un ajuste ignorado se sigue leyendo y se sigue mostrando en el panel y en `zurg plex-settings` (marcado como `skip`), así que no se oculta nada. Simplemente nunca se escribe, nunca se cuenta como problema y nunca activa el aviso de papelera del panel. Los IDs no distinguen mayúsculas; si un ID no corresponde a ningún ajuste de las tablas de abajo, se informa al iniciar y el ajuste sigue protegido, ya que un error tipográfico no debe interpretarse como una exclusión.

Ignorar un ajuste de seguridad es bajo tu propia responsabilidad, y zurg lo advierte una sola vez al arrancar, no en cada actualización. `autoEmptyTrash` en particular es el ajuste que vacía una biblioteca cuando un escaneo se encuentra con un montaje que ha fallado por un momento. Ignorarlo también devuelve la tarea de limpieza a Plex; ver más abajo.

### Quién vacía la papelera {#who-empties-the-trash}

Desactivar `autoEmptyTrash` deja un trabajo sin hacer. Plex tiene instrucciones de no vaciar las entradas cuyos archivos ya no existen, y durante mucho tiempo la eliminación propia de zurg fue opcional. Así que, por defecto, una biblioteca acumulaba entradas muertas y nadie las recogía. Ninguno de los dos estaba mal, y el hueco era real: es lo que le pasa a alguien cuando un archivo se mueve entre carpetas de la biblioteca y la entrada antigua se queda para siempre.

zurg ahora asume el trabajo que le quitó. Si `plex_trash_sweep_every_mins` no está definido, el [barrido de la papelera](../internals/plex-trash-sweep.md) elimina las entradas cada 60 minutos, pero solo cuando nadie más lo hace. Si Plex sigue vaciando su propia papelera, porque `plex_settings_policy` es `off` o `warn`, o porque `autoEmptyTrash` está en `plex_settings_ignore`, zurg se retira y deja el trabajo a Plex. Dos recolectores sobre una misma biblioteca es cómo un desacuerdo entre ellos se convierte en un borrado.

El barrido es mucho más restringido que el vaciado propio de Plex, y por eso es preferible: elimina una entrada cada vez, nunca una que todavía tenga archivo, solo desde un montaje que se pueda leer en ese momento, con un máximo de 50 eliminaciones y un 10% de la papelera por pasada. Las entradas sobre las que no tiene veredicto siguen visibles como rotas durante 14 días antes de eliminarse. También necesita `plex_database_path` definido, así que solo funciona donde Plex está en este mismo host, y con zurg ejecutando el montaje por sí mismo (`rclone_enabled` con `mount_path` definido). zurg lee esa base de datos con el programa `Plex SQLite` que instala Plex, y lo encuentra donde lo deja el instalador de Plex en Linux, macOS y Windows. Por eso `plex_database_path` es la única clave que tienes que configurar:

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
Mantén las comillas simples: dentro de comillas dobles, YAML interpreta una barra invertida como escape. Define `plex_sqlite_binary` solo si Plex está instalado en otro lugar, como un Plex de 32 bits: `'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`.
+++

Reemplaza `YOU` por tu nombre de usuario: zurg no expande ni `~` ni `%LOCALAPPDATA%`. El barrido compara las rutas que guarda Plex con `mount_path`, y eso incluye una letra de unidad como `Z:` (`pkg/utils/path_within.go`).

Para desactivar la eliminación y vaciar la papelera tú mismo, escribe `plex_trash_sweep_every_mins: 0`. Ese es el «no» explícito, y es distinto de dejar la clave fuera.

Esa clave solo desactiva la eliminación propia de zurg. No devuelve el ajuste a Plex. Con `guard`, zurg sigue escribiendo `autoEmptyTrash` como off, así que Plex seguirá sin vaciar su papelera tras un escaneo, y las entradas se acumularán sin que nadie las recoja. Usa el interruptor del panel o `plex_settings_ignore` para devolverle a Plex esa tarea.

### Seguridad: corregida con `guard` y `enforce` {#safety--corrected-under-guard-and-enforce}

Estos pierden datos en lugar de tiempo, por eso la política por defecto los escribe en vez de solo avisar. Solo `autoEmptyTrash` viene con el valor destructivo. Los otros tres ya tienen por defecto el valor que zurg quiere y están aquí para detectar a un operador que haya activado alguno.

| Preferencia | Valor por defecto de Plex | zurg quiere | Por qué |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | Plex vacía la papelera después de cada escaneo. Si el montaje no se puede leer durante un momento mientras un escaneo lo recorre, cada archivo aparece como borrado y Plex los elimina para siempre en lugar de dejarlos en la papelera para que vuelvan con el montaje. |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | Las actualizaciones basadas en eventos no detectan lo que realmente cambia aquí. El árbol de zurg cambia por su propio lado, que nunca pasa por el kernel local, así que no se genera ningún evento y la biblioteca se queda desactualizada sin que nadie lo note. Los eventos que sí llegan son escrituras hechas *a través* del montaje, que se producen mientras un directorio todavía se está armando. |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | Un escaneo parcial depende de esos mismos eventos, así que se dispara con las escrituras que llegan a través del montaje, justo cuando un directorio está a medio escribir, y nunca con los cambios del lado remoto que sí necesitarían un escaneo. |
| `ButlerTaskBackupDatabase` | `1` | `1` | La copia de seguridad nocturna de la base de datos es lo único que recupera una biblioteca que Plex ya ha borrado. |

Las dos razones de `FSEvent` se reescribieron después de medirlas, en todas las plataformas donde zurg hace montajes. El texto anterior decía que un montaje FUSE "no las emite de forma fiable, así que esto produce escaneos en momentos que nadie pidió". Las dos partes son incorrectas.

Medido el 2026-09-05: cada plataforma se vigiló con la API que usa realmente su servidor multimedia, contra un montaje de rclone cuyo directorio de respaldo se podía cambiar directamente. **A** es una escritura hecha a través del montaje; **B** es el mismo archivo apareciendo en el otro extremo, como ocurre cuando cambia el árbol propio de zurg.

| Plataforma | Montaje | Vigilado con | A: a través del montaje | B: cambiado en el otro extremo |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **sin eventos** |
| Docker | mismo montaje enlazado dentro de un contenedor | inotify, dentro del contenedor | las mismas cuatro, vistas en el contenedor | **sin eventos** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **sin eventos** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **sin eventos** |

Todas las plataformas entregaron A, y un control en la misma ejecución sobre un sistema de archivos nativo (APFS, NTFS) produjo los mismos eventos, así que los observadores funcionaban. Ninguna entregó B, aunque el archivo era visible a través del montaje una vez que caducaba la caché del directorio.

Así que el modo de fallo es lo contrario de lo que se decía: una actualización basada en eventos se dispara con las escrituras que llegan *a través* del montaje (una importación de un \*arr que aterriza en un directorio que todavía se está armando) y nunca se dispara con los cambios del lado remoto, que son justo la razón para escanear. No es que los eventos sean poco fiables; es que informan de la mitad equivocada de lo que pasa en un montaje de debrid.

### Ancho de banda: corregido solo con `enforce` {#bandwidth--corrected-under-enforce-only}

Cada una de estas hace que Plex decodifique archivos enteros para un resultado que nadie mira. No pasa nada en almacenamiento local, pero sobre un montaje de debrid cada byte es una petición al proveedor, y esto se ejecuta en toda la biblioteca. El análisis cuya salida *sí* se ve (previsualizaciones al desplazar, imágenes de capítulos, nivelación de volumen, análisis sónico) pasa en cambio al nivel de preferencias de gusto de abajo, donde `enforce` no lo toca.

| Preferencia | Valor por defecto de Plex | zurg lo quiere |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### Gustos: siempre se informan, nunca se corrigen {#taste--always-reported-never-corrected}

Cada una de estas opciones tiene una función detrás, así que zurg te dice cuánto cuesta cada valor y deja la decisión en tus manos. Apagar una sin que lo pidas te quitaría algo que el operador puede ver, y eso no le corresponde a zurg, por mucho ancho de banda que ahorre. En las dos primeras, la opción más barata mantiene la función y traslada el trabajo a la ventana de mantenimiento; en el resto, la elección es entre la función o el ancho de banda.

| Preferencia | Valor por defecto de Plex | zurg sugiere | Motivo |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` o `never` | `asap` decodifica cada archivo en cuanto llega, fuera de cualquier ventana de mantenimiento. `scheduled` mantiene el botón Skip Intro y traslada el trabajo a la ventana. |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` o `never` | Lo mismo, pero para Skip Credits. |
| `GenerateBIFBehavior` | `never` | `never` | Decodifica el vídeo entero para crear la tira de imágenes que se ve al hacer avance rápido o retroceder. La reproducción no la necesita. |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | Decodifica el archivo para sacar un fotograma por capítulo, la imagen que aparece junto a cada entrada de la lista de capítulos. |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | Decodifica por completo el audio de cada archivo para medirlo, y así igualar el volumen entre pistas y títulos. |
| `MusicAnalysisBehavior` | `scheduled` | `never` | Decodifica cada pista. Como son muchos archivos pequeños, es el número de peticiones que hace que una cuenta quede limitada por tasa. A cambio se obtiene el análisis sonoro: las mezclas de pistas similares y el visualizador. |

### La ventana de mantenimiento {#the-maintenance-window}

zurg no toca `ButlerStartHour`/`ButlerEndHour`, porque no hay una hora que sirva para todo el mundo. Vale la pena configurarlas a mano: Plex usa por defecto 02:00–05:00, y una ventana que se solape con las horas en que la gente ve contenido convierte cada tarea de mantenimiento en un atasco. Lo que quede en el nivel de ancho de banda se ejecuta dentro de esa ventana.

### Detener una pasada que ya está en curso {#stopping-a-pass-already-in-flight}

Cambiar una preferencia detiene las ejecuciones *futuras*, no la que ya está en marcha. Plex Media Server vuelve a crear sus procesos hijos del escáner, así que matarlos no sirve de nada:

+++ Linux y macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
En Windows PowerShell 5.1, `curl` es otro nombre de `Invoke-WebRequest`, así que escribe `curl.exe`.
+++

Primero define `$TOKEN` con tu token de Plex: `TOKEN=your-token` en una shell, `$TOKEN = 'your-token'` en PowerShell.
