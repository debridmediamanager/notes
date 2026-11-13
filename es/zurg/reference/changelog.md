# Registro de cambios {#changelog}

## zurg encuentra anime, programas diarios y especiales para Sonarr {#zurg-finds-anime-daily-shows-and-specials-for-sonarr}

Una fuente de Sonarr solía saltarse una serie diaria, una serie de anime y los especiales de una serie, con una advertencia por cada una. Ahora, los episodios que faltan de un programa diario también se piden por la fecha en que se emitieron (`The Daily Show 2026.11.03`), los de un anime por el número con el que el programa los cuenta (`Jujutsu Kaisen 30` es el sexto de la segunda temporada), y los especiales como temporada `00`, junto a la búsqueda habitual por temporada y episodio. El propio parser de Sonarr indica a qué episodio corresponde cada release, como hace con cualquier serie, y el perfil de calidad lo evalúa igual que antes. Un video colocado para un anime o un programa diario se nombra `JUJUTSU KAISEN - S02E06 - <the release's own name>`, porque el reescaneo de Sonarr lee un archivo solo por su nombre y lo colocaría en la temporada 1 si fuera `2nd Season - 06`; los videos de una serie estándar y de un especial mantienen sus nombres. Los especiales van en la carpeta que nombra **Specials Folder Format** de Sonarr, y solo un release que contenga `S00Exx` puede coincidir con uno. Consulta [Qué le pide zurg a Sonarr](../guides/acquisition.md#what-zurg-asks-sonarr-for).

## Mantén una película buscada en 1080p y en 4K {#keep-a-wanted-film-at-1080p-and-at-4k}

`quality: [1080p, 4k]` en el bloque `acquisition:` mantiene dos copias de cada película en tu lista de deseados de DMM, para que un televisor de 1080p pueda reproducir una sin transcodificar el archivo 4K. Cada copia toma la mejor versión en o por debajo de su propia resolución y se actualiza hasta ella por su cuenta. Mientras no haya nada mejor que 1080p, las dos comparten una sola copia. Las series y cualquier otra fuente siguen teniendo una sola copia. Consulta [una copia por cada una de varias resoluciones](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

## La actualización de zurg funciona tras la instalación de una sola línea {#zurg-update-works-after-the-one-line-install}

Los instaladores de una sola línea te conectan a GitHub mediante la GitHub CLI. La descargaban solo para eso y la borraban al terminar. Entonces `zurg update` buscaba la GitHub CLI, no la encontraba y se detenía con "no GitHub credential found", aunque tu inicio de sesión seguía guardado. La GitHub CLI de Ubuntu es demasiado antigua para traspasar el inicio de sesión, así que la actualización también se detenía ahí.

Ahora `zurg update` también usa la GitHub CLI que los instaladores guardan en `bin`, junto a zurg. Un inicio de sesión que la GitHub CLI guardó sin keyring ya funciona aunque la CLI en sí haya desaparecido. Si aun así no encuentra nada, muestra el único comando que lo arregla. Ejecuta una vez la actualización del instalador y, a partir de ahí, cada `zurg update` iniciará sesión por su cuenta.

## Que fallen muchos enlaces viejos de Real-Debrid a la vez ya no se llama caída {#many-old-real-debrid-links-failing-at-once-is-no-longer-called-an-outage}

Los enlaces de Real-Debrid dejan de funcionar unos meses después de crearse, así que los lanzamientos añadidos más o menos en la misma época dejan de reproducirse también más o menos al mismo tiempo. Cuando más de cinco fallaban en una misma pasada de reparación, zurg escribía "suspected provider-wide outage" y retenía la reparación de todos menos cinco, así que un lote grande seguía roto mucho más tiempo y parecía que Real-Debrid estaba caído. Ahora zurg primero pregunta a Real-Debrid por un lanzamiento de la misma cuenta que sí se reproduce. Si se reproduce, los enlaces que fallan simplemente son viejos y se repara cada lanzamiento como de costumbre. Solo cuando Real-Debrid también rechaza los enlaces que funcionan, zurg lo trata como una caída y espera.

## Los enlaces de sesiones de Emby en el panel abren el panel de Emby {#the-dashboards-emby-session-links-open-embys-dashboard}

El enlace "active sessions" y el enlace "transcodes" del panel de Emby en el dashboard abrían `/web/#/dashboard`, que es la dirección de Jellyfin para esa página, y Emby se quedaba para siempre en su pantalla de inicio. Ahora ambos enlaces abren `/web/index.html#!/dashboard`, la dirección que Emby usa por sí mismo. Los enlaces del panel de Jellyfin no han cambiado.

## Un .nfo que falta ya no envía una versión de Usenet a repair {#a-missing-nfo-no-longer-sends-a-usenet-release-to-repair}

Los posts antiguos de Usenet a menudo pierden primero su .nfo, mientras que todos los archivos de vídeo y las partes de los archivcomprimidos siguen ahí. zurg lo trataba como un daño de toda la release. Iniciaba una reparación cada vez que encontraba un .nfo así, y eso volvía a pasar después de cada reinicio. Las reparaciones reales esperaban detrás de cientos de innecesarias. Algunas releases que se reproducían bien se marcaban como irreparables, y borrar el .nfo era la única forma de recuperarlas.

Un .nfo u otro archivo pequeño que falte junto al vídeo ahora se lee como vacío y no pide ninguna reparación. Ya no marca una release como irreparable. Un vídeo dañado se puede volver a reparar cuando el .nfo que está a su lado ya no existe. Las releases que ya estaban marcadas como irreparables por este motivo se vuelven a revisar en un plazo de aproximadamente un día y vuelven solas.

## Los archivos de Usenet ya no reproducen silencio cuando un servidor envió el artículo de otra subida {#usenet-files-no-longer-play-silence-where-a-server-sent-another-uploads-article}

Algunos servidores de noticias responden a una petición de un artículo de tu archivo con un artículo
de una subida distinta que tiene el mismo número. zurg solo detectaba esto cuando
la otra subida tenía menos artículos que tu archivo. En archivos más cortos, como
los volúmenes RAR y los episodios cortos, cogía el artículo equivocado y reproducía silencio durante
ese tramo. El log lo llamaba `an internal mapping failure in zurg` y decía que
el offset `falls between two articles that are both present and neither
covers`. Ahora zurg también comprueba el tamaño del archivo que indica cada artículo. Rechaza un
artículo de otro archivo y pide a tus otras cuentas de noticias el correcto. Los artículos que una versión anterior ya guardó en su caché de artículos también se rechazan.
Con una sola cuenta, ese tramo sigue reproduciéndose como silencio. Ahora el log dice que un
servidor envió el artículo de otro archivo, en lugar de culpar a zurg.

## Las conexiones de Usenet vuelven a velocidad completa cuando otra app deja de usar la cuenta {#usenet-connections-come-back-at-full-speed-after-another-app-stops-using-the-account}

Si tu proveedor de Usenet alguna vez rechazó a zurg por tener demasiadas conexiones, por ejemplo mientras otro programa o un zurg anterior todavía tenía algunas, zurg seguía abriendo conexiones de una en una cada segundo mientras estuviera en marcha, incluso cuando ya había hueco de nuevo. Después de cada periodo de calma, una ráfaga de descargas volvía a empezar desde las dos conexiones calientes, así que una cuenta grande tardaba más de un minuto en recuperar la velocidad completa y las importaciones se quedaban en cola detrás de ella, con "waited 5s for a connection (queued for the account's allowance)" en el registro de depuración. Ahora, una vez que el proveedor ha aceptado de nuevo una conexión y ha pasado un minuto sin otro rechazo, zurg abre de inmediato las que necesita.

## El registro de depuración indica cuándo una descarga espera una conexión con varios servidores de noticias configurados {#the-debug-log-says-when-a-fetch-waits-for-a-connection-with-several-news-servers-configured}

Con un solo servidor de noticias, una descarga que esperó más de cinco segundos a una conexión dejaba una línea de depuración que lo indicaba. Con dos o más, esa línea nunca aparecía, así que añadir un segundo servidor hacía que la línea desapareciera, hubiera o no terminado la espera. Ahora la línea también aparece en configuraciones con varios servidores y nombra los servidores a los que la descarga estaba esperando.

## Una captura de Usenet sin archivos de repair y con un primer artículo muerto falla de inmediato {#a-usenet-grab-with-no-repair-files-and-a-dead-first-article-fails-at-once}

Una publicación sin archivos PAR2 cuyo primer artículo había desaparecido de todos los servidores de noticias se retenía cinco minutos antes de que Radarr o Sonarr se enteraran de que había fallado, esperando una reparación que no tenía de dónde reparar. Ahora zurg ve que no hay datos de recuperación y reporta la descarga como fallida de inmediato, así el cliente la añade a la lista de bloqueo y pasa a la siguiente.

## Una captura de Usenet que repair arregló ya no se marca como fallida cinco minutos después {#a-usenet-grab-that-repair-fixed-is-no-longer-reported-failed-five-minutes-later}

Cuando a una descarga le faltaban algunos artículos y sus archivos PAR2 podían reconstruirlos, zurg la reparaba, pero un read-ahead que se ejecutaba durante la reparación podía volver a pedir los artículos que faltaban y recibir un rechazo justo después de que terminara la reparación. Ese rechazo devolvía la release a la lista de dañadas, así que la descarga se retenía cinco minutos y luego se reportaba como fallida, y Radarr o Sonarr bloqueaban una release que se reproducía sin problemas. Un rechazo por un artículo que la reparación ya había reconstruido ya no cuenta como daño.

## Las descargas actualizadas que traían un .nfo o subtítulos también se borran {#upgraded-downloads-that-came-with-an-nfo-or-subtitles-are-deleted-too}

Con `magic.allow_delete` activado, un vídeo eliminado que no estaba dentro de un archivo RAR se borraba por su cuenta. El `.nfo`, los subtítulos y el póster que había junto a él mantenían la descarga en tu biblioteca. Su NZB se quedaba en `nzbs/` y su torrent seguía en tu cuenta de debrid. Cada actualización de una descarga de este tipo dejaba uno atrás. Ahora se borra la descarga completa en cuanto nada en `__magic__` la usa ya. Una descarga se mantiene mientras otro episodio suyo siga en tu biblioteca o siga esperando en su propia carpeta para ser importado. Los subtítulos que Sonarr o Radarr importaron junto al vídeo la mantienen también hasta que se borren a su vez.

## Las descargas de Usenet reemplazadas o fallidas ya no se acumulan {#replaced-and-failed-usenet-downloads-no-longer-pile-up}

Con `magic.allow_delete` activado, al borrar un episodio o una película que salía de un archivo RAR, solo se ocultaba. La descarga de la que venía seguía en la biblioteca y su NZB se quedaba en `nzbs/` para siempre. Al actualizar episodios sueltos a un pack de temporada, quedaba uno de estos por cada episodio. Ahora se borra la descarga completa en cuanto nada de `__magic__` la usa ya. Una descarga se mantiene mientras otro episodio del mismo archivo siga en tu biblioteca. También se mantiene mientras su propia carpeta tenga algo que importar.

Sonarr y Radarr piden que se borren los archivos de una descarga fallida cuando la eliminan. zurg guardaba el NZB igualmente. Ahora lo borra cuando no se importó nada de ese release. Una descarga que terminó e importó sus archivos mantiene su NZB como antes, porque el archivo importado sigue reproduciéndose desde ahí.

## zurg ahora indica cuándo la biblioteca terminó de cargar {#zurg-now-says-when-the-library-has-finished-loading}

Docker considera zurg saludable en cuanto está en marcha. Una biblioteca grande puede seguir cargándose durante más de una hora después de eso. Las carpetas del montaje fallan con `Input/output error` todo ese tiempo y parece una instalación rota. La nueva dirección `/ready` distingue ambos casos. Responde 503 hasta que la biblioteca se haya cargado y 200 cuando ya lo esté. No necesita contraseña. Dentro del contenedor, `/app/healthcheck.sh --ready` comprueba lo mismo. La comprobación de salud propia del contenedor sigue preguntando solo si zurg está en marcha. Así, una primera carga larga no puede provocar que el contenedor se reinicie ni retrasar un montaje que dependa de él. Además, la comprobación de salud ahora lee la variable de entorno `PORT`. Antes, un contenedor que definía `PORT` se comprobaba en el puerto equivocado.

## Acquisition puede omitir versiones según las palabras de sus nombres {#acquisition-can-skip-releases-by-words-in-their-names}

Define `exclude_words` en el bloque `acquisition:` y zurg nunca toma una release cuyo nombre tenga una de esas palabras. `exclude_words: [DV, HDR10+]` mantiene Dolby Vision y HDR10+ fuera de una TV que no puede reproducirlos, y aun así toma 4K con HDR normal. Funciona para la watchlist de Plex, Seerr, Radarr y Sonarr, y para Usenet y torrents. Solo palabras completas. `DV` no atrapa `DVDRip` ni una película llamada Adventures. `DV`, `DoVi` y `Dolby Vision` significan lo mismo, y lo mismo pasa con `HDR10+` y `HDR10Plus`. Radarr y Sonarr nunca reciben la consulta sobre una release excluida.

## Radarr y Sonarr pueden tomar primero la mejor calidad del perfil {#radarr-and-sonarr-can-take-the-profiles-best-quality-first}

zurg normalmente toma la versión permitida que sea más rápida de verificar. Para una película, suele ser un WEB-DL en 1080p. La pasada de mejora luego avanza hacia el cutoff de tu perfil. Las series toman primero un pack de temporada antes que los episodios sueltos. Así, un pack de 1080p podría llenar una temporada aunque hubiera episodios en 2160p. Define `best_first: true` bajo `acquisition:` y la primera descarga seguirá en cambio tu perfil de calidad de Radarr o Sonarr. Primero viene la mejor resolución que permita. Cualquier cosa igual o por encima del cutoff cuenta como suficientemente buena. Cuando una versión resulta haber desaparecido, zurg avanza hacia abajo por el perfil. El primer archivo puede tardar más en llegar, porque las mejores versiones suelen ser publicaciones grandes en varias partes. Viene desactivado por defecto.

## Los resultados de torrents ya no desplazan a los NZB donde ninguna cuenta acepta torrents {#torrent-results-no-longer-crowd-out-nzbs-where-no-account-takes-torrents}

En una instancia con un proveedor de NZB y sin cuenta de debrid que acepte torrents, la adquisición seguía buscando en tus indexadores Torznab, y cada torrent que encontraba gastaba uno de los tres lanzamientos que recibe un episodio o un pack de temporada por intento. Con `prefer: torrents`, o con torrents 4K por encima de un NZB 1080p, los NZB nunca se probaban y el episodio fallaba. Ahora los indexadores Torznab se omiten en ese caso, con una línea en el log que lo indica, y un lanzamiento que la instancia no puede usar nunca cuenta como intento. Las películas tampoco le preguntan a Radarr por esos torrents.

## Acquisition ya no cuenta un NZB como completado cuando nada puede reproducirlo {#acquisition-no-longer-counts-an-nzb-as-done-where-nothing-can-play-it}

En una instancia con una cuenta de debrid y sin proveedor de nzb, la adquisición seguía buscando en tus indexadores Newznab, y un NZB que descargaba se contaba como completado sin ninguna comprobación. Un título de la lista de seguimiento de Plex podía salir de la lista por un archivo que nada en esa instancia podía reproducir. Ahora los indexadores Newznab se omiten en ese caso, con una línea en el registro que lo indica, y un NZB nunca se cuenta como completado en una instancia sin proveedor de nzb.

## Una versión sin nada que reproducir se informa una vez en lugar de cada día {#a-release-with-nothing-left-to-play-is-reported-once-instead-of-every-day}

Cuando se habían borrado todos los archivos reproducibles de un lanzamiento, zurg avisaba cada día de que "has no playable file that still reads". Una biblioteca con cien lanzamientos así registraba cien de esos avisos al día, para lanzamientos que nadie había tocado. Ahora el aviso aparece una sola vez, y el lanzamiento se vuelve a revisar solo cuando cambia algo en él. Restaurar un archivo sigue devolviéndolo de inmediato.

## Las versiones rotas en AllDebrid y TorBox vuelven cuando los archivos todavía se reproducen {#broken-releases-on-alldebrid-and-torbox-come-back-when-the-files-still-play}

Una versión que solo tiene AllDebrid, TorBox, Premiumize, Offcloud o Debrid-Link
podía quedarse rota y oculta durante semanas mientras la cuenta seguía sirviéndola. Repair no vuelve a añadir versiones
en esos servicios por su cuenta, porque eliminan el contenido a propósito, y
nadie más comprobaba si los archivos habían empezado a funcionar de nuevo. Ahora Repair le pregunta a la cuenta una vez al día si los archivos de una versión rota todavía se reproducen y devuelve las que sí funcionan, sin añadir nada. Lo que la cuenta haya eliminado de verdad sigue necesitando el botón Repair. La recomendación de reparación de MCP dice lo mismo, en lugar de decir que ningún barrido va a actuar nunca sobre ella.

## Las descargas que TorBox pone en cola esperando un hueco libre aparecen como en cola y terminan {#grabs-torbox-queues-for-a-free-slot-show-as-queued-and-finish}

Cuando todas las ranuras de descarga de una cuenta de TorBox estaban ocupadas, TorBox ponía en cola los nuevos envíos de Sonarr y Radarr, y zurg perdía la pista de ellos. El envío aparecía como fetching metadata durante unos diez minutos y luego como error, así que Sonarr y Radarr lo descartaban. Cuando TorBox lo descargaba más tarde, nada lo importaba. Ahora zurg sigue un envío en cola hasta que TorBox lo inicia y después hasta que termina. Mientras espera, aparece como queued, y el timeout de falta de progreso no se activa hasta que TorBox lo haya iniciado.

## Puedes buscar una sola versión en la página `__magic__` {#you-can-search-for-one-release-on-the-__magic__-page}

En una biblioteca que organizan Sonarr o Radarr, cada importación deja una carpeta de trabajo oculta. La página `__magic__` solo muestra las primeras mil filas guardadas. El release que buscabas normalmente no estaba entre ellas, así que sus botones Unhide y Reset quedaban fuera de tu alcance, y la nota debajo de la lista apuntaba a data/magic.json. Editar ese archivo mientras zurg está en marcha no funciona: zurg lo vuelve a escribir desde la memoria cuando se detiene, así que las filas regresan después de un reinicio.

Las filas guardadas y las páginas huérfanas ahora tienen un cuadro de búsqueda. Escribe el nombre de un release, una ruta de tu montaje o un hash, y se listará cada fila guardada sobre ese release con sus botones, sin importar lo grande que sea la tabla.

También sirve para recuperar un release que está en `__all__` pero nunca aparece en `__magic__/__all__.` Borrar un release y volver a añadirlo, o reinsertarlo desde DMM, conserva su hash, así que regresa con todo lo que `__magic__` tenía guardado sobre él, incluida la carpeta de trabajo que se borró después de su importación. Búscalo y pulsa Unhide en su fila de release-tombstone.

## `__magic__` en Windows deja de crecer su diario para siempre {#__magic__-on-windows-stops-growing-its-journal-forever}

On Windows, zurg logged `cannot truncate data\magic.journal ... Access is
denied.` every time it tried to tidy the file where `__magic__` records your
moves and folders. The file was never emptied, so it grew with every change
and every start read all of it again. After a few thousand changes in one run,
each further change also rewrote the whole saved layout. zurg now empties it
on Windows as it always did elsewhere, and the first start after updating
clears what has piled up. If tidying ever fails, zurg tries again after more
changes instead of on every one.

## Restaurar un archivo por MCP devuelve su versión de inmediato {#restoring-a-file-over-mcp-puts-its-release-back-right-away}

Restaurar un archivo con la herramienta MCP `zurg_release_file_restore` devolvía el archivo, pero dejaba su release marcada como rota y dentro de `__unplayable__` hasta la siguiente actualización de la biblioteca. Ahora hace lo mismo que el botón Restore gestor de torrents: el release sale de `__unplayable__`, vuelve a sus carpetas con sus archivos .strm y queda guardado así. Como antes, no pide a Plex, Jellyfin ni a tu script on_library_update que vuelva a escanear.

## Recupera los archivos que una reparación fallida había ocultado {#bring-back-files-a-failed-repair-hid}

Las versiones antiguas marcaban un archivo como eliminado cuando una reparación se rendía con una cuenta, aunque otra cuenta todavía pudiera reproducirlo. Entonces el lanzamiento desaparecía de todas las carpetas.

El gestor de torrents tiene un nuevo filtro "Deleted, still served" que muestra los lanzamientos sin nada que reproducir cuyo archivo eliminado todavía sirve alguna cuenta. Mantén pulsado su botón Restore y zurg comprueba el enlace de cada archivo y devuelve a sus carpetas los que se reproducen, igual que si pulsaras Restore en cada archivo.

zurg no hace esto por su cuenta. Un archivo que borraste a propósito se guarda exactamente igual, así que revisa la lista y restaura solo lo que no borraste. Los lanzamientos que todavía reproducen algo no aparecen en la lista, ya que borrar un extra o un episodio es lo habitual al eliminar algo a propósito.

## Acquisition revisa más allá de la primera página de resultados de búsqueda {#acquisition-looks-past-the-first-page-of-search-results}

La adquisición solía leer solo la primera página que devolvía un indexador. Con DMM, que devuelve diez resultados por página con los más grandes primero, un límite de tamaño podía eliminarlos todos, y la película fallaba con "no eligible releases" cada pocas horas aunque los lanzamientos más pequeños estaban en las páginas siguientes. Ahora sigue pidiendo más páginas hasta reunir suficientes lanzamientos que encajen con tus límites, hasta diez páginas. En el caso de las series, un episodio que la búsqueda por temporada no encontró, normalmente uno más antiguo cuando el episodio más nuevo llena los resultados, ahora se busca por separado.

## Los archivos muertos en las carpetas de películas y series de `__magic__` ahora salen de la lista para que Radarr y Sonarr lo noten {#dead-files-in-__magic__-movie-and-show-folders-now-drop-out-so-radarr-and-sonarr-notice}

A un archivo que Radarr o Sonarr había importado a una carpeta dentro de `__magic__` seguía apareciendo con su tamaño completo después de que la release dejara de funcionar, así que un rescan todavía lo veía y la película o el episodio nunca volvía a estado wanted. Ahora sale de la carpeta en el mismo momento que sale de cualquier otro listado: cuando repair ya no puede recuperarlo, o un día después de romperse si repair está desactivado. El siguiente rescan lo marca como missing y acquisition busca un reemplazo. Si el archivo vuelve a funcionar, reaparece en el mismo lugar.

## Season Fix ordena los packs de varias temporadas y los extras numerados {#season-fix-sorts-multi-season-packs-and-numbered-extras}

Season Fix ahora lee la temporada que cada archivo indica por sí mismo, así que un pack como `Full Metal Panic S2 - 01`, `Bakuman II - 01`, `KonoSuba 2 - 01` o `Demon Slayer Mugen Train Arc - 01` pone cada episodio en su propia temporada en lugar de dejar que Plex los apile todos en la temporada 1. Los lotes nombrados en romaji o con un sufijo, como `Sergeant Keroro 001-358` o `Dragon Ball Z COMPLETE`, se reconocen cuando sus archivos comparten un mismo título, y los nombres con guiones bajos, `Ep01`, `1.01.` o un número dentro del título del episodio se leen tal como se pretendía.

Los extras numerados como `Special 01`, `OVA 01`, `- 11 (OVA)` y los resúmenes `24.5` solían aparecer como una segunda versión de un episodio real, y Play podía elegir el extra. Ahora se renombran con el sufijo `-other` de Plex para que aparezcan como extras.

## Un enlace muerto de Real-Debrid ya no retiene un escaneo de la biblioteca durante minutos {#a-dead-real-debrid-link-no-longer-holds-a-library-scan-for-minutes}

Cuando Real-Debrid sigue respondiendo a un archivo con el mismo enlace revocado, zurg espera unos minutos, ya que eso es normal justo después de que se elimina una descarga. Un archivo que sigue siendo rechazado de esa forma tras cinco minutos ahora se trata como un enlace roto y se envía a reparación, en lugar de pedirle al usuario que vuelva a intentarlo. Antes, un solo archivo muerto podía bloquear un escaneo de Plex durante unos diez minutos.

## Las descargas de Usenet fallidas o atascadas se pueden limpiar desde la página `__magic__` {#failed-and-stuck-usenet-jobs-can-be-cleared-from-the-__magic__-page}

A trabajo Failed o Stuck en la lista de SABnzbd se quedaba ahí para siempre cuando Sonarr o Radarr dejaban de usar zurg como cliente de descarga. Reiniciar no lo borraba. La única forma era borrar `data/sabnzbd-jobs.json` a mano. La página de trabajos de `__magic__` ahora tiene un botón **Clear** en cada trabajo Failed o Stuck, y un botón encima de la lista que los borra todos. Mantenlo pulsado hasta que se llene la barra. Los trabajos Queued y Completed nunca se tocan. El NZB del trabajo también se borra, salvo que una importación en `__magic__` siga usando ese release.

## El addon de Stremio indica cuándo necesita https {#the-stremio-addon-says-when-it-needs-https}

Stremio solo carga un addon por http en el mismo equipo donde corre. En una TV, un teléfono u otro ordenador, una dirección http falla con "failed to load manifest" aunque el dispositivo pueda llegar a zurg. La página de configuración ahora lo indica junto a la URL del addon siempre que la abras por http en una dirección de ese tipo. La guía de Stremio muestra tres formas de poner zurg detrás de https: Tailscale Serve, tu propio reverse proxy y un túnel de Cloudflare.

## Plex detecta una película o episodio en cuanto Radarr o Sonarr lo importan a `__magic__` {#plex-picks-up-a-movie-or-episode-as-soon-as-radarr-or-sonarr-imports-it-into-__magic__}

Después de que Radarr o Sonarr moviera un archivo a una carpeta dentro de `__magic__`, zurg le pedía a Plex que escaneara el archivo en sí. Plex solo escanea carpetas, así que respondía como si todo estuviera bien y no añadía nada, y la película seguía sin aparecer hasta el siguiente escaneo programado de Plex. Ahora zurg le pide a Plex que escanee la carpeta donde quedó el archivo. Lo mismo vale para el archivo que reemplaza una mejora, de modo que la versión antigua desaparece, y para los endpoints de escaneo manual, la herramienta MCP `zurg_plex_scan_releases`, los escaneos tras un renombrado o el borrado de un archivo, y las rutas que se pasan a `on_library_update`.

## La página Manage lista las versiones duplicadas y cuál usan Radarr o Sonarr {#the-manage-page-lists-duplicate-releases-and-which-one-radarr-or-sonarr-uses}

Una actualización deja en tu biblioteca la versión que reemplazó, y las descargas desde distintos indexadores pueden dejar más de una copia de una película o de una temporada. La nueva vista Duplicates de la página Manage agrupa las versiones que contienen la misma película o los mismos episodios y muestra cuál está usando Radarr o Sonarr. zurg calcula esto a partir de dónde está el archivo dentro de `__magic__`, no a partir de los nombres de las versiones.

En el caso de una temporada, muestra cada episodio que tiene más de una versión y en qué versión está el archivo de Sonarr. Así, un pack del que Sonarr solo toma unos pocos episodios seguirá apareciendo como en uso. Todas las demás versiones aparecen marcadas como "No reference found" o "Unknown", junto con el motivo. Selecciona las que quieras eliminar, y zurg vuelve a leer Radarr y Sonarr antes de borrar, dejando fuera cualquier cosa que haya entrado en uso desde entonces. Nunca se elimina nada automáticamente.

## Las ranuras de descarga ocupadas de TorBox se cuentan como las cuenta TorBox {#torboxs-busy-download-slots-are-counted-the-way-torbox-counts-them}

Antes de que la reparación o la primera reproducción añada un torrent a TorBox, zurg comprueba si la cuenta tiene un hueco libre de descarga. Antes contaba todos los torrents que no estaban completamente descargados. Eso dejaba fuera los torrents que están en seeding, que TorBox cuenta contra tu plan durante hasta 30 días, y contaba los torrents cuyo contenido había caducado, que no ocupan ningún hueco. Con unos cuantos torrents caducados en una biblioteca, la reparación podía quedarse esperando como si todos los huecos estuvieran ocupados.
zurg ahora cuenta exactamente los torrents que TorBox marca como activos.

## TorBox puede sembrar para rastreadores privados {#torbox-can-seed-for-private-trackers}

A new setting, `tb_seed_torrents`, decide si los torrents que zurg añade a TorBox hacen seeding. Se queda en `never` a menos que lo cambies, así que nada cambia para quien no lo toque. Ponlo en `always` si un tracker privado necesita tu ratio, o en `auto` para que lo decida la configuración de seeding de tu cuenta de TorBox. Se puede cambiar desde la sección Health & Repairs del dashboard y surte efecto en la siguiente adición.

Un torrent que está haciendo seeding ocupa una de las ranuras activas de tu plan de TorBox mientras siga haciendo seeding, hasta 30 días en Pro. Cuando los torrents en seeding llenan todas las ranuras, las nuevas descargas y reparaciones en esa cuenta tienen que esperar a que se libere una.

## Los conjuntos RAR cuyos volúmenes tienen nombres desordenados ahora se reproducen {#rar-sets-whose-volumes-are-named-out-of-order-now-play}

Una release cuyos volúmenes RAR llevan cada uno un nombre distinto, como un nombre aleatorio por volumen o `Movie 2026 part1.rar`, antes aparecía como un archivo por volumen. El primero mostraba la película, pero dejaba de funcionar después de su primera parte, y los demás no mostraban nada. Ahora zurg lee de dentro del propio volumen a qué parte pertenece cada uno y vuelve a juntar el conjunto, algo que antes se arreglaba a mano renombrando los volúmenes como `part001.rar` en adelante. Solo lo hace cuando los volúmenes se numeran formando un conjunto completo. Si falta uno o si dos reclaman el mismo lugar, la release se deja como estaba y el log indica el motivo. Los archivos comprimidos cuyos volúmenes se publicaron desordenados también se reproducen ahora.

## Un escaneo de Plex que todavía está analizando ya no se marca como atascado {#a-plex-scan-that-is-still-analysing-is-no-longer-reported-as-stuck}

Plex mantiene sin cambios el progreso de un escaneo de biblioteca y la carpeta actual mientras analiza los archivos que encontró el escaneo, algo que puede tardar mucho en una biblioteca grande o remota. Antes, el panel lo daba por un escaneo atascado y sugería reiniciar Plex en mitad del proceso. Ahora zurg escucha el feed de actualizaciones del propio Plex y cuenta los elementos en los que Plex dice que sigue trabajando, así que solo se marca un escaneo que de verdad se ha parado.

## Las subidas de torrents solo en caché conservan el rechazo de add en proveedores con límite de ritmo {#cached-only-torrent-uploads-preserve-the-refusing-add-on-rate-paced-providers}

Un `.torrent` enviado en modo solo-caché ahora llega al add rechazador de TorBox incluso cuando su límite horario de adds envuelve el backend. Un fallo de no-caché no crea ninguna transferencia y no ocupa ningún slot activo; aun así gasta uno de los 60 adds no-caché por hora de TorBox. Los adds normales siguen subiendo el archivo original. La guía de qBittorrent ahora enumera los seis proveedores de subida de torrents y explica los caminos solo-caché distintos de Debrid-Link y TorBox.

## Un archivo que borras mientras se restaura queda borrado {#a-file-you-delete-while-it-is-being-restored-stays-deleted}

Si borras un archivo o una versión mientras una restauración todavía está comprobando su enlace, ahora la app espera a que termine esa comprobación y luego el borrado gana. Una actualización de la biblioteca que ya estaba en marcha ya no puede devolver una versión que acabas de borrar.

## Una búsqueda lejos dentro de un archivo comprimido ya no deja colgado al lector {#a-seek-far-into-a-compressed-archive-no-longer-hangs-the-reader}

Un archivo dentro de un RAR o zip comprimido solo se puede decodificar desde su principio, así que una lectura cerca del final de uno grande antes esperaba a que todo el archivo se procesara sin dar ninguna respuesta. Plex podía quedarse esperando una lectura así durante más de una hora, lo que bastaba para bloquear su base de datos. Ahora zurg responde en menos de 20 segundos, conserva el progreso que ya había hecho y prepara el final del archivo en segundo plano para que la siguiente lectura sea inmediata.

## Los rechazos de Real-Debrid siguen las reglas de nombres de archivo publicadas {#real-debrid-refusals-follow-the-published-filename-rules}

Cuando Real-Debrid se niega a volver a añadir un release durante el repair, zurg ahora comprueba el nombre del release y los nombres de sus archivos contra las reglas de nombres de archivo publicadas. Si las reglas bloquean un release, se marca como infractor de forma permanente. Cualquier otro rechazo se trata como que Real-Debrid está frenando las adiciones, y el release se queda en la cola para la siguiente pasada de repair en lugar de retirarse.

## Restaurar un archivo lo devuelve a su sitio de inmediato {#restoring-a-file-puts-it-back-where-it-belongs-straight-away}

El botón Restore de la página de gestión de un release ahora vuelve a colocar el release en sus directorios, guarda el estado recuperado y escribe su archivo STRM en cuanto el archivo pasa la comprobación. Un archivo restaurado ya no se queda en el directorio de no reproducibles hasta el siguiente refresco del proveedor, y un release cuyo último archivo roto fue restaurado ya no aparece como roto después de un reinicio. Los archivos que borraste siguen borrados hasta que los restaures.

## Rechaza artículos Usenet ajenos antes de servir bytes {#reject-foreign-usenet-articles-before-serving-bytes}

Rechaza los artículos de Usenet con el mismo número cuyo total de yEnc positivo sea menor que el número más alto listado en el NZB, incluidas las rutas de caché persistente y progresiva, para que los respaldos válidos de la cuenta aporten los bytes.

## Mantén la clasificación de rechazos de RD respaldada por evidencia {#preserve-evidence-backed-rd-refusal-classification}

Trata en silencio las respuestas 451 de addMagnet como rechazos de release, salvo que haya evidencia de limitación local de la cuenta que abarque toda la operación, y conserva los errores temporales durante la reparación.

## Aclara las ventanas de lectura de archivos rotos caducados {#clarify-expired-broken-file-read-windows}

Informa de que ha expirado la ventana de reintentos para leer un archivo roto, sin dar a entender que la reparación se ha rendido.

## Expón la salud registrada de los archivos en MCP {#expose-recorded-file-health-in-mcp}

Muestra los conteos de salud registrados por archivo en las vistas de release de MCP y mantén las tablas de archivos con carga diferida seguras de inspeccionar, sin afirmar que un estado de ciclo de vida sea una sonda de servicio en vivo.

## Gestiona las operaciones duplicadas de sidecar {#handle-duplicate-sidecar-operations}

Reconocer las respuestas tipadas de fuente ausente procedentes de alias WebDAV duplicados, conservando los errores reales de fallo total y de permisos.

## Una nueva descarga con el mismo nombre se repara en vez de fallar {#a-re-grab-under-the-same-name-is-repaired-instead-of-failed}

Volver a capturar un NZB con un nombre que zurg ya tiene ya no comprueba ni repara la copia anterior mientras se lee la nueva. La captura espera al archivo nuevo, así que una release con un artículo que falta, y que PAR2 puede reconstruir, se repara y se completa en lugar de marcarse como fallida.

## Los fallos de reparación ya no se confunden con borrados del usuario {#repair-failures-no-longer-masquerade-as-user-deletions}

Los fallos de reparación automática ahora marcan como dañada solo la fuente del proveedor que falla, conservando las copias alternativas sanas y permitiendo que las actualizaciones posteriores del proveedor restauren la visibilidad de los archivos.

## Los torrents sin id de IMDb se identifican por el nombre del lanzamiento a través de DMM {#torrents-without-an-imdb-id-are-identified-by-release-name-through-dmm}

Con `dmm_metadata_secret` configurado, el job de IMDb ya no necesita una clave de OpenSubtitles. Los torrents sin id, o solo con la marca de "no encontrado" de OpenSubtitles, se identifican al inicio a partir de una etiqueta `imdb-tt…` en su nombre. Si no hay etiqueta, lo hace el resolver de DMM, que solo responde cuando un título coincide exactamente. Por ejemplo, las romanizaciones de fansub como "Kaijuu 8-gou" se resuelven a Kaiju No. 8 mediante los alias de DMM, pero un nombre que comparten varias series se deja sin tocar. Un torrent que DMM no puede nombrar mantiene un id vacío, para que una coincidencia en Plex todavía pueda rellenarlo.

## Una película de Radarr que ningún indexador conoce por id se busca por nombre {#a-radarr-movie-that-no-indexer-knows-by-id-is-searched-for-by-name}

Muchos posts de Usenet se indexan sin id de IMDb ni de TMDB. zurg buscaba una película de Radarr solo por id, así que un documental al que ningún indexador respondía por id fallaba con "no eligible releases", mientras que la búsqueda por nombre de Radarr encontraba una versión limpia. Ahora, cuando la búsqueda por id no encuentra nada que usar, zurg también busca por título y año, y el parser de Radarr sigue decidiendo si cada resultado es la película. Solo se hace una búsqueda por nombre si la búsqueda por id no encontró absolutamente nada. Si la búsqueda por id sí encuentra la película, se indexa por id, y volver a preguntar por nombre solo traería los mismos posts.

## Los NZB encontrados a través de Prowlarr se pueden descargar {#nzbs-found-through-prowlarr-can-be-downloaded}

Prowlarr entrega cada NZB de Usenet redirigiendo al indexador, y no permite desactivar eso. zurg solo seguía una redirección hacia el mismo host, así que con indexadores configurados a través de Prowlarr, cada adquisición de NZB fallaba con "answered 301 Moved Permanently" y nunca se adquiría nada. Ahora la redirección sí se sigue. La clave de API del propio enlace tampoco llega nunca al otro host, y una redirección de HTTPS a HTTP plano sigue rechazándose.

## Un indexador que rechaza durante horas ya no bloquea la adquisición {#an-indexer-that-refuses-for-hours-no-longer-stalls-acquisition}

Prowlarr responde a una búsqueda en un indexador que tiene desactivado con `429` y un `Retry-After` de muchas horas. zurg esperó dos minutos y volvió a preguntar, tres veces, así que cada búsqueda gastaba seis minutos en ese único indexador. Acquisition se rendía con cada título tras cinco intentos y descartaba lo que ya habían respondido todos los demás indexadores, así que no se adquiría nada hasta que el indexador volviera. Ahora, un indexador que pide que no le hagan caso durante más de dos minutos se omite hasta el momento que indica, y las búsquedas siguen con los demás.

## Un título borrado después de la adquisición se vuelve a buscar {#a-title-deleted-after-acquisition-is-searched-for-again}

Cuando un archivo que zurg había adquirido para Sonarr o Radarr se borraba, porque no era la versión deseada o por cualquier otro motivo, y el título volvía a aparecer en la lista de faltantes, zurg respondía "completed without a search, the release was already held" y nunca volvía a buscarlo. Ahora zurg revisa primero la carpeta de la temporada o de la película dentro de `__magic__`. Un episodio o una película cuyo video ya no está se vuelve a buscar. Si el video todavía está, que es lo que pasa mientras Sonarr no ha vuelto a escanear, se deja en paz.

## "Scan in Plex" en la lista de no detectados espera el resultado {#scan-in-plex-on-the-undetected-list-waits-for-the-result}

El botón "hold-to-scan" de la lista de no detectados recargaba la página dos segundos después de pulsarlo, cuando la comparación con Plex todavía no había empezado. En una biblioteca grande esa comparación tarda minutos, así que la lista siempre volvía sin cambios y el botón parecía que no hacía nada. Ahora el botón muestra que la comparación está en marcha, espera a que termine, indica cuántos lanzamientos ha emparejado y luego recarga la página.

## Un lanzamiento cuyo nombre termina en espacio se empareja con Plex {#a-release-whose-name-ends-in-a-space-is-matched-to-plex}

Una release cuyo nombre de archivo tiene un espacio antes de la extensión, como `... [Hurtom] v2 .mkv`, obtiene un directorio que termina en un espacio. Plex lo encontraba, pero zurg nunca podía emparejarlo, así que seguía en la lista de no detectados después de cada escaneo. Ahora ya se empareja.

## Borrar un archivo en la página de gestión te mantiene en tu sitio {#deleting-a-file-on-the-manage-page-keeps-your-place}

Eliminar, restaurar, renombrar o forzar la visualización de un archivo en la página de gestión de un lanzamiento hacía que la página se recargara desde arriba, así que al limpiar un pack grande había que volver a bajar después de cada clic. Ahora la página vuelve a la fila de ese archivo y la resalta.

## El panel acepta una ruta de montaje escrita entre comillas {#the-dashboard-takes-a-mount-path-typed-with-quotes}

A una ruta de montaje pegada en el panel tal como la escribe config.yml, como `"/Users/me/Plex Media Server/ZurgMount"` o `'Z:\'`, se le rechazaba con "mount path should be absolute" porque las comillas se leían como parte de la ruta. Ahora el panel quita un par de comillas que coincidan alrededor del valor y guarda la ruta sin ellas.

## Un fallo al obtener la watchlist de Plex dice por qué {#a-failed-plex-watchlist-fetch-says-why}

Cuando Plex rechaza una solicitud de la lista de seguimiento, el registro ahora incluye el motivo que da Plex, como `unexpected status: 401: Invalid token`, en lugar de solo el código de estado. Si todavía ves `Failed to fetch watchlist: ... unexpected status: 400`, ese mensaje viene de una versión anterior a agosto. Actualiza zurg: las versiones actuales piden la lista de seguimiento en páginas que Plex acepta.

## Un lanzamiento demasiado dañado para la memoria de repair falla de inmediato {#a-release-too-damaged-for-repairs-memory-fails-at-once}

When a Usenet release is missing more than PAR2 repair can hold in memory at once, zurg now says so and stops, and Sonarr or Radarr pick another release. It used to keep the grab waiting, then try again every few minutes, re-checking the whole release each time for the same answer. Damage that is not yet confirmed as gone, such as articles a server failed to answer, is still retried.

## La configuración supera una config vacía y dice cuándo está oculto el aviso del token {#setup-gets-past-an-empty-config-and-says-when-the-token-prompt-is-hidden}

`zurg setup`, y los instaladores que lo ejecutan, se negaban a continuar mientras hubiera un `config.yml` vacío, con un error que terminaba en blanco. Ahora un config vacío se reemplaza. Uno que tiene contenido sigue sin sobrescribirse nunca, y el error indica qué archivo es y cómo empezar de nuevo. El aviso del token dice que lo que escribas o pegues queda oculto, algo que antes parecía que la terminal no aceptaba la entrada. Un error de sintaxis en `config.yml` ahora se reporta contra `config.yml`, no contra una "outbound identity config" interna.

## Un servidor de noticias de respaldo ahora rellena los artículos que el principal responde mal {#a-backup-news-server-now-fills-in-articles-the-main-server-answers-wrongly}

Algunos servidores de noticias responden a una petición de un artículo con un trozo de otra subida distinta. zurg reconocía el trozo equivocado, pero nunca le pedía al servidor de respaldo el correcto, así que el hueco se reproducía como silencio o el archivo no se abría, incluso con un servidor de respaldo que lo tenía. Ahora zurg pide al siguiente servidor, igual que hace SABnzbd.

## Un lanzamiento Usenet en RAR llega a su directorio sin reiniciar {#a-rard-usenet-release-reaches-its-directory-without-a-restart}

Una release publicada como conjunto RAR se ordena en directorios según los nombres de sus volúmenes hasta que se abre su archivo, y después según los archivos que contiene. Antes, nada la volvía a ordenar una vez abierto el archivo, así que un directorio que busca un `.mkv` o números de episodio no encontraba una release RAR recién descargada hasta que se reiniciaba zurg, y Plex y Jellyfin no la veían ahí. Ahora la release pasa a los directorios correctos en cuanto se lista su archivo por primera vez.

## Una película publicada con un nombre aleatorio se nombra según su lanzamiento {#a-movie-posted-under-a-random-name-is-named-after-its-release}

Algunos posts de Usenet le ponen a la película un nombre aleatorio, como `eq5KVi5Y3iTwFEn1Nub8yPY9yd6oUzTu.mkv`, y lo repiten en todos los lugares del post que podrían tener el nombre real. zurg conservaba ese nombre, así que Radarr y Sonarr no tenían nada en el nombre del archivo en que basarse. Ahora zurg nombra el archivo según el release, igual que lo hace SABnzbd: solo cuando está claro que es el archivo grande único del release, solo para archivos de video, y nunca para estructuras de disco ni archivos comprimidos. Esto se aplica a los releases que se descarguen a partir de ahora; un archivo que ya está en la biblioteca conserva su nombre.

## Las reglas de tamaño ahora se aplican a los archivos dentro de los archivos comprimidos {#size-rules-now-apply-to-files-inside-archives}

Una película de Usenet publicada como conjunto RAR se muestra como los archivos dentro del archivo.
Esos archivos se saltaban las opciones `only_show_the_biggest_file` y `only_show_files_with_size_gte`/`_lte` de un directorio, así que cualquier otra cosa que trajera la publicación seguía visible junto a la película. Muchas publicaciones incluyen una imagen pequeña con el nombre de la película, una hoja de capturas con marca de tiempo, y Jellyfin la usaba como póster. Las opciones de tamaño ahora se aplican al contenido de los archivos comprimidos igual que se aplican a cualquier otro archivo.

## Los lanzamientos Usenet cuyo archivo PAR2 más grande supera los 512 MB se pueden reparar {#usenet-releases-whose-largest-par2-file-is-over-512-mb-can-be-repaired}

Cuando a un release le faltan piezas, zurg las reconstruye a partir de los propios archivos PAR2 del release. Antes se negaba a leer cualquier archivo PAR2 de más de 512 MB, y en un release grande ese archivo contiene más datos de reparación que cualquier otro, y a menudo es el único que existe. Un release así no se podía reparar por poco que le faltara, y zurg seguía intentándolo una y otra vez, descargando cada vez todos sus archivos PAR2 más pequeños antes de rendirse. Ahora zurg lee un archivo PAR2 de cualquier tamaño. Un release con más daño del que una reparación puede manejar en memoria se rechaza en cuanto se cuenta el daño, antes de descargar cualquiera de sus archivos PAR2.

## Sonarr puede pasarle a zurg sus episodios que faltan {#sonarr-can-hand-its-missing-episodes-to-zurg}

zurg ahora también puede tomar su lista desde Sonarr. Añade una fuente `sonarr` bajo `acquisition.sources` con la URL de Sonarr y la API key. zurg luego va recorriendo los episodios que Sonarr tiene pendientes y los archivos de episodio que quiere mejorar. Busca en tus indexadores y comprueba que los servidores de noticias sigan teniendo el release. Coloca cada episodio en su carpeta de temporada dentro de `__magic__` y le pide a Sonarr que vuelva a escanear la serie. Sonarr no necesita indexadores ni cliente de descarga para esto.

Una temporada que falta completa y que ya terminó de emitirse puede llegar como un pack de temporada. Todo lo demás llega episodio por episodio. Cada release pasa primero por el parser de Sonarr. Tiene que ser la serie correcta y el episodio correcto, y tiene que encajar en el perfil de calidad de la serie. Las mejoras reemplazan solo el episodio que mejoran. Cuando a un episodio de una temporada todavía no le toca ningún release, los demás se colocan igual y Sonarr vuelve a escanear para ellos. Las series diarias y de anime se omiten por ahora, con una nota en el log. `docs/acquisition.md` cubre la parte de Sonarr de la configuración.

## La adquisición trabaja con muchos títulos a la vez {#acquisition-works-on-many-titles-at-once}

Los títulos de una watchlist o de un servicio de peticiones antes se adquirían uno tras otro, así que una lista larga tardaba lo mismo que la suma de todos sus títulos. zurg ahora trabaja con hasta ocho a la vez, según lo que indique `acquisition.concurrency`. Un título que aparece al final de la lista ya no espera a que terminen los que tiene delante.

Una release nueva ya no se queda dos minutos esperando antes de que zurg la compruebe. zurg revisa cada segundo hasta que la release aparece en la biblioteca, durante un máximo de un minuto y medio. Cuando los servidores de Usenet ya no tienen una release, zurg pasa directamente al siguiente candidato en lugar de reintentarlo cinco minutos después.

Comprobar una release ya no tiene que caber en el tiempo que le sobra a la búsqueda, así que una búsqueda lenta en una lista larga ya no retrasa los títulos durante minutos. Las mejoras de títulos que ya tienes esperan a que terminen los títulos que faltan de la misma lista, de modo que nunca compiten con ellos por las llamadas a los indexadores ni por las conexiones a los servidores de Usenet.

## Un lanzamiento Usenet reparado con PAR2 sigue reparado mientras se lee {#a-usenet-release-repaired-with-par2-stays-repaired-while-it-is-read}

Cuando a algunos artículos de un lanzamiento ya no están en los servidores de noticias, zurg los reconstruye a partir de los archivos PAR2 del lanzamiento y sirve los bytes reconstruidos. La parte de zurg que se adelanta al reproductor no sabía de esas piezas reconstruidas, así que volvía a pedir a los servidores los artículos que faltaban. Seguían sin estar, y zurg marcaba el lanzamiento como dañado otra vez, aunque cada byte que servía era correcto. Un lanzamiento reparado durante una importación podía fallar segundos después, y un cliente de descargas descartaba una copia buena y bajaba otra. Ahora zurg ya no pide a los servidores nada que haya reconstruido antes.

## Radarr puede pasarle a zurg sus películas pendientes {#radarr-can-hand-its-wanted-movies-to-zurg}

zurg ahora puede tomar su lista de Radarr. Añade una fuente `radarr` en `acquisition.sources` con la URL y la API key de Radarr, y zurg trabaja con las películas que Radarr no tiene o que quiere mejorar. Busca en tus indexadores, comprueba que los servidores de noticias todavía tienen el lanzamiento, pone el vídeo en la carpeta de la película dentro de `__magic__` y le pide a Radarr que vuelva a escanear esa película. Para esto, Radarr no necesita indexadores ni cliente de descargas. Cada lanzamiento que toma zurg ha pasado antes por el parser propio de Radarr, así que tiene que ser la película correcta y encajar en el perfil de calidad de la película: una calidad permitida, la puntuación mínima de formato personalizado, los límites de tamaño y mejoras solo hacia el cutoff. zurg toma el primer lanzamiento permitido que sea más rápido de comprobar, primero los web, y deja las calidades preferidas del perfil para la mejora que viene después. Solo le pregunta a Radarr por un lanzamiento cuando está a punto de comprobarlo, uno cada vez, y nunca pregunta por uno cuyo título indique una resolución para la que el perfil no tiene calidad. Así, un Radarr ocupado responde de una a tres preguntas en la mayoría de películas, en lugar de una por cada resultado de búsqueda. Si Radarr ve el montaje de zurg en otra ruta, pon `library_path` en la ruta donde Radarr ve `__magic__`. Una nueva página Acquisition en el panel muestra cada título en el que trabaja zurg, qué está haciendo en este momento y dónde se colocó cada lanzamiento. `docs/acquisition.md` explica la parte de Radarr de la configuración.

## La adquisición elige el lanzamiento Usenet que más rápido se confirma {#acquisition-picks-the-usenet-release-that-is-quickest-to-confirm}

Cuando zurg adquiere una película, ahora busca primero en las publicaciones que contienen un solo archivo de video, que casi siempre siguen completas en los servidores de Usenet y tardan dos lecturas de artículo en confirmarse. Lee el NZB de cada candidata antes de guardar nada, guarda la primera publicación de un solo video que encuentra y solo recurre a los conjuntos de archivos en varios volúmenes cuando no hay ninguno disponible, empezando por el conjunto más pequeño y nunca más de seis a la vez. Los resultados cuyo título corresponde a una sola parte de una publicación dividida se omiten. En las pruebas con el IMDb Top 100, elegir de esta forma redujo los NZB que zurg tenía que descargar de 517 a 156. Las búsquedas y las descargas de NZB ahora comparten un límite de solicitudes simultáneas por indexador, y zurg espera cuando un indexador indica que está ocupado. Una solicitud de película sin un perfil de calidad detrás todavía obtiene primero la resolución que pidió. La adquisición de series no cambia.

## La adquisición revisa un lanzamiento una vez que zurg conoce sus tamaños {#acquisition-checks-a-release-once-zurg-knows-its-sizes}

Zurg solía comprobar una nueva versión con los servidores de noticias en cuanto aparecía en la biblioteca, mientras seguía leyendo la misma versión para conocer sus tamaños de archivo. Ambas tareas pedían los mismos artículos por las mismas conexiones, así que en una lista larga las dos iban muy lentas. En una lista de 99 películas, la última llegaba a Radarr después de casi nueve minutos. Ahora zurg comprueba una versión una vez que se conocen sus tamaños, igual que ya hace con Sonarr y Radarr a través del endpoint de SABnzbd, no comprueba más de seis versiones a la vez y reutiliza el primer artículo que la comprobación de tamaño ya descargó, siempre que todavía lo tenga. Una ráfaga de versiones guardadas ahora provoca una sola actualización de la biblioteca en lugar de una por versión.

Comprobar una versión ahora tiene prioridad sobre las comprobaciones de tamaño de otras versiones, aunque nunca por delante de la reproducción. Además, una cuenta con más de doce conexiones ahora aprende los tamaños de hasta dieciséis versiones a la vez, en lugar de ocho.

## Un lanzamiento Usenet descargado con unas pocas piezas que faltan se repara antes de fallar {#a-grabbed-usenet-release-with-a-few-missing-pieces-is-repaired-before-it-is-failed}

Antes de decirle a Radarr o Sonarr que una descarga terminó, zurg comprueba que las partes del lanzamiento sigan disponibles en los servidores de noticias. Cuando esa comprobación encontraba algo que faltaba, zurg marcaba la descarga como fallida en el momento, aunque los propios archivos PAR2 del lanzamiento podrían haber reconstruido lo que faltaba. Radarr entonces descartaba el lanzamiento y buscaba otro, a menudo peor. Ahora zurg primero reconstruye las partes que faltan y solo informa de que la descarga falló si eso no funciona. En una semana de descargas reales, la mayoría de los lanzamientos que fallaron de esta forma tenían los archivos PAR2 que los habrían salvado.

## Los lanzamientos Usenet dañados esperan su turno para repararse en vez de fallar {#damaged-usenet-releases-wait-their-turn-for-a-repair-instead-of-being-failed}

zurg repara como máximo dos versiones dañadas a la vez, y una reparación puede tardar desde un par de minutos hasta más de una hora. Una tercera descarga dañada solo tenía cinco minutos para empezar antes de que zurg le dijera a Radarr o Sonarr que había fallado, así que cuando llegaban varias juntas, todas menos dos se descartaban sin que nadie intentara repararlas, y el log no decía nada al respecto. Ahora zurg mantiene una descarga en espera mientras su reparación está en la cola, durante hasta tres horas, y el log indica cuándo una reparación está esperando su turno.

## Una descarga Usenet ya no espera para siempre a tamaños de archivo que nadie va a conocer {#a-usenet-download-no-longer-waits-for-ever-on-file-sizes-nothing-is-going-to-learn}

zurg retiene una descarga terminada de Radarr y Sonarr hasta saber el tamaño exacto de cada archivo, porque los clientes comprueban el tamaño al importar. Después de ciertas descargas repetidas, zurg podía dejar de intentar averiguar los tamaños mientras seguía esperándolos, así que la descarga se quedaba en la cola hasta que el cliente se rendía, a menudo dos horas después. Ahora zurg vuelve a calcular el tamaño de ese lanzamiento y, cuando ya no es posible calcularlo más y todas las partes del lanzamiento están en los servidores de noticias, le indica al cliente que la descarga está lista.

## Los lanzamientos Usenet cuyo publicador renombró solo el primer volumen del archivo vuelven a reproducirse {#usenet-releases-whose-poster-renamed-only-the-first-archive-volume-play-again}

Algunos posters renombran el primer volumen de un archivo con el nombre del release y dejan el resto con sus nombres originales. Así, un release llega como `Show.S02E03.part03.rar` más `show.203.r00` hasta `show.203.r19`. zurg agrupó los volúmenes por nombre, vio dos archivos incompletos y no pudo abrir ninguno. Ahora lee la cabecera del primer volumen, reconoce a qué volúmenes pertenece y le pone el nombre que corresponde, así que el episodio se reproduce e importa. Si a una carpeta le falta de verdad un volumen de su archivo, ahora lo dice con un mensaje claro en vez de mostrar un error genérico del servidor.

## Los lanzamientos Usenet ofuscados cuyos volúmenes solo están numerados ahora se reproducen {#obfuscated-usenet-releases-whose-volumes-are-just-numbered-now-play}

Algunas publicaciones ocultan todos los nombres de archivo tras una cadena aleatoria y un número, así que una película llega como `f342c135….01`, `….02` y así sucesivamente, con los archivos de texto y las imágenes de portada numerados entre ellos. zurg no los reconocía como partes de un mismo archivo, los listaba como archivos sueltos y Radarr y Sonarr no encontraban nada que importar. Ahora zurg lee el inicio de cada archivo numerado, une las partes del archivo en el orden correcto (incluso cuando la primera parte se publicó la última) y deja fuera los archivos de texto y las imágenes.

## Los NZB de packs de temporada de más de 32 MB se aceptan {#season-pack-nzbs-over-32-mb-are-accepted}

zurg rechazaba cualquier NZB mayor de 32 MB enviado a su endpoint de SABnzbd, respondiendo "request body too large". Los NZB de los packs de temporada grandes suelen superar ese tamaño: una temporada de 526 GB llegó como un NZB de 49 MB. Ahora zurg acepta NZB de hasta 256 MB. Uno de 49 MB con casi medio millón de piezas se carga en menos de medio minuto.

## Los archivos de publicaciones Usenet envueltas conservan sus nombres reales {#files-from-wrapped-usenet-posts-keep-their-real-names}

Algunas herramientas de publicación envuelven cada nombre de archivo en el asunto, como en `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv]-[3/4]`, y dejan vacío el nombre entre comillas habitual. zurg mantenía el envoltorio como parte del nombre, así que los episodios aparecían como `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv`, algo que Sonarr y los servidores de medios no pueden emparejar. Ahora zurg saca el nombre del envoltorio. Las publicaciones que ya están en la biblioteca se vuelven a leer una vez para recoger los nombres corregidos.

## Las descargas ya reportadas como fallidas ya no ocupan ranuras de reparación de las nuevas {#downloads-already-reported-failed-no-longer-take-repair-slots-from-new-ones}

Una vez que zurg le avisa a Radarr o Sonarr de que una descarga falló, el cliente la descarta y busca otra. Aun así, zurg seguía intentando reparar esas descargas cada vez que se reiniciaba, y esas reparaciones inútiles podían ocupar sus dos ranuras de reparación mientras una descarga nueva que todavía se podía salvar esperaba. Ahora zurg deja de reparar una descarga en cuanto ha informado de que falló.

## Los informes de daños indican cada archivo {#damage-reports-name-every-file}

Cuando a una release de Usenet le faltaban partes, el mensaje de fallo de zurg listaba los archivos dañados por su nombre, y un archivo que el post nunca nombraba aparecía en blanco: "across 4 file(s): , , , ". Ahora ese archivo se lista por su posición en la release, como en "file 12 of 73", así que el mensaje dice qué archivos están afectados.

## Stremio omite una versión cuyo vídeo empieza con nada {#stremio-skips-a-release-whose-video-starts-with-nothing}

Cuando falta el inicio del video de un lanzamiento de Usenet en los servidores de noticias, zurg lo rellenaba con silencio y se lo entregaba a Stremio como si todo estuviera bien. Así, el reproductor no mostraba nada y la película parecía rota. Ahora zurg revisa los primeros bytes antes de empezar la reproducción. Si no hay nada real ahí, pasa al siguiente lanzamiento de la lista, igual que ya hace con un lanzamiento que no tiene nada reproducible. Una película con un hueco más adelante sigue reproduciéndose.

## Los archivos rotos permanecen en la biblioteca mientras zurg siga reintentándolos {#broken-files-stay-in-the-library-while-zurg-will-still-retry-them}

Cuando zurg no podía reparar un archivo roto a la primera, lo sacaba del montaje, aunque al día siguiente pensaba volver a intentarlo. Plex lee un archivo que desaparece como un archivo borrado, así que un solo escaneo de la biblioteca podía mandar episodios, temporadas y series enteras a la papelera. Ahora, un archivo roto se queda en el montaje mientras zurg tenga previsto otro intento de reparación. Solo sale cuando zurg está seguro de que el contenido ya no existe, por ejemplo cuando el servicio rechaza el lanzamiento directamente o cuando no queda nada reproducible dentro.

## Radarr y Sonarr vuelven a buscar cuando una versión que han capturado dos veces está muerta {#radarr-and-sonarr-search-again-when-a-release-they-grab-twice-is-dead}

Cuando el primer release que Radarr descargó resultó estar muerto, su siguiente búsqueda
a menudo elegía el mismo release desde otro indexador, con el mismo nombre. zurg
registraba esa segunda descarga bajo el id de trabajo de la primera. Radarr y Sonarr
recuerdan cada descarga que han visto fallar con ese id, así que trataban la nueva
descarga como si fuera el fallo antiguo y nunca la revisaban de nuevo: ni fallo, ni
lista de bloqueo, ni nueva búsqueda. La película simplemente se quedaba parada. En una
ejecución del IMDb Top 100 a través de Radarr, 25 películas acabaron así.

Una descarga de un release que zurg ya ha respondido por ahora recibe su propio id de trabajo,
igual que SABnzbd nombra cada descarga. Cuando también esa está muerta, Radarr recibe el segundo
fallo, lo añade a la lista de bloqueo y vuelve a buscar.

## Las versiones Usenet muertas se reportan como fallidas en minutos en lugar de hasta media hora {#dead-usenet-releases-are-reported-failed-in-minutes-instead-of-up-to-half-an-hour}

zurg comprueba los artículos de un release capturado antes de avisar a Radarr o Sonarr de que terminó, y espera a que los tamaños de archivo se estabilicen antes de preguntar. Un post muerto es justo el release cuyos tamaños nunca llegan, así que la comprobación se quedaba detrás de una espera de treinta minutos mientras el cliente esperaba noticias. Ahora, una vez que zurg ha intentado averiguar los tamaños de un release y ha fallado, comprueba los artículos enseguida. Si los artículos ya no están, el release se marca como fallido para que el cliente pase a otro.

Un release que se encontró dañado mientras se leía también esperaba cinco minutos a una reparación PAR2, aunque tuviera `enable_repair: false`, cuando nunca se iba a iniciar ninguna reparación. Ahora esa espera se omite siempre que no pueda ejecutarse ninguna reparación.

En una prueba con el IMDb Top 100 a través de Radarr, con más de la mitad de los releases capturados muertos, estas dos esperas fueron la mayor parte del tiempo que una película pasaba en zurg.

## Una versión que resulta dañada durante la importación se marca como fallida, para que Radarr capture otra {#a-release-that-turns-out-damaged-during-import-is-failed-so-radarr-grabs-another}

zurg revisa un artículo por archivo antes de avisarle a Radarr que un release está listo, así que un release con un hueco en medio de un archivo puede pasar. Cuando la importación de Radarr llegó al hueco, zurg se negó a mover el archivo, lo cual es correcto, pero dejó la descarga con aspecto de incompleta en lugar de fallida. Radarr dejó la película como "import blocked" y nunca buscó otra copia. En una tanda de las 100 mejores de IMDb pasadas por Radarr, cinco películas se quedaron atascadas de esa forma.

Ahora, cuando la importación se rechaza, la descarga se marca como fallida. Radarr añade ese release a la lista de bloqueados y busca uno distinto.

## Una versión totalmente ofuscada ya no genera un archivo de vídeo sin nombre {#a-fully-obfuscated-release-no-longer-comes-out-with-a-nameless-video-file}

Cuando una publicación de Usenet oculta todos los nombres de archivo, zurg averigua cuál es el archivo principal a partir de sus primeros bytes y le pone el nombre de la release, igual que hace SABnzbd. Esa comprobación iba al final de una pasada con un límite de noventa segundos, y cuando las descargas llegaban en ráfaga, el límite podía agotarse antes. Entonces el archivo de vídeo se publicaba con el nombre de la release y sin extensión, que Radarr y Sonarr se saltan, así que la descarga se quedaba en su cola esperando un archivo que pudieran importar.

Ahora una release se vuelve a nombrar, hasta tres veces, hasta que zurg ha podido revisar el archivo, y solo entonces se muestra a tu biblioteca y a tus *arr. En una ejecución del IMDb Top 100 a través de Radarr, este caso fue Seven Samurai, un .mkv de 42 GB.

## Las versiones con acentos o CJK en sus nombres de archivo conservan sus nombres completos {#releases-with-accents-or-cjk-in-their-filenames-keep-their-whole-names}

Un release cuyos archivos tienen nombres con caracteres fuera de las letras inglesas básicas salía de zurg con el principio de cada nombre perdido. `Détective Conan S11E01 - 286 [MULTI] [AVC].mkv` se servía como `tective Conan S11E01 - 286 [MULTI] [AVC].mkv`, y un título en chino o japonés perdía aún más, porque se eliminaba todo hasta el último carácter de ese tipo.

Sonarr y Radarr no podían hacer nada con lo que quedaba. Un nombre como `tective Conan S11E01` no coincide con ninguna serie, así que recurrían al historial de capturas de la descarga, se negaban a importar solo por eso y dejaban el elemento en espera con el mensaje "release was matched to series by ID. Automatic import is not possible." El release se quedaba en la cola y nada lo movía.

También podía costarte archivos. Cuando lo único que distingue dos archivos está después del último carácter acentuado, ambos salen con el mismo nombre, y un nombre es una ruta. Un release francés con diez volúmenes de reparación tenía los diez reducidos al mismo nombre y publicaba cuatro archivos cuando la publicación contiene trece, dejando los datos de reparación sin forma de llegar a ellos.

zurg ahora lee cada carácter por encima del ASCII básico como parte del nombre del archivo, que es lo que siempre ha sido: los contadores de partes, la marca `yEnc`, los corchetes y las extensiones de archivo que ponen los publicadores son todos ASCII básico, así que cualquier otra cosa pertenece al título. Los releases nombrados en ASCII básico no se ven afectados y salen exactamente igual que antes.

Los releases que ya están en tu biblioteca conservan los nombres con los que se registraron, ya que zurg no vuelve a revisar una lista de archivos que ya ha guardado. Volver a añadir un release afectado recoge los nombres corregidos.

(Una traducción anterior fue rechazada: los code spans no coinciden (` was served as `). Mantén la estructura exacta.)

## Un nombre escrito en japonés, coreano, chino, tailandés o árabe se deja tal cual {#a-name-written-in-japanese-korean-chinese-thai-or-arabic-is-left-alone}

zurg renombra un archivo dentro de un archivo comprimido cuando su nombre no dice nada sobre lo que contiene, así que una release publicada con un hash llega con el nombre propio de la release. Para decidirlo había que comparar mayúsculas con minúsculas, y muchos sistemas de escritura no tienen ninguna de las dos. Un archivo llamado `오징어 게임 S01E01` no tenía ni una cosa ni otra, no pasaba la prueba de un nombre normal y se renombraba como si fuera un hash, con S01E01 y todo. Afectaba a los caracteres han, kana, hangul, tailandeses, hebreos y árabes.

Ahora, una letra sin mayúscula ni minúscula termina la pregunta en lugar de hacerla fallar. Los nombres de esos sistemas de escritura se mantienen tal como se publicaron, y los hashes siguen renombrándose exactamente igual que antes.

Además, zurg ahora lo avisa en el log cuando dos archivos de una misma release acaban con el mismo nombre. Un nombre es una ruta, así que cuando pasa eso la release ofrece en silencio menos archivos de los que contiene, y los sobrantes no se pueden abrir de ninguna forma. Antes no se informaba de nada, por eso el fallo de los nombres con acentos de la entrada anterior pasó desapercibido: la única pista era un listado de carpeta con menos filas de las esperadas.

## Las correcciones de nombres de archivo ahora llegan también a las versiones que ya tienes {#the-filename-fixes-now-reach-releases-you-already-have}

Las dos entradas de arriba cambiaron la forma en que zurg lee un nombre de archivo de un post de Usenet, pero zurg guarda el resultado de leer cada NZB y lo reutiliza en cada arranque, en lugar de volver a recorrer todo tu directorio de vigilancia. Esos resultados guardados seguían siendo los antiguos, así que, tras actualizar, una release que ya tenías seguía mostrando el mismo nombre incorrecto de antes. Solo un NZB recién añadido obtuvo el nombre corregido.

Ahora zurg se da cuenta de que lee los posts de forma distinta a como se escribieron los resultados guardados, y los vuelve a leer. El primer arranque tras actualizar vuelve a leer una vez cada NZB de tu directorio de vigilancia, lo que tarda un poco más de lo habitual, y luego todo vuelve a la normalidad. No se vuelve a descargar nada ni se piden artículos; solo se vuelven a leer archivos que ya están en tu disco.

Si una release se vio afectada, sus archivos volverán con los nombres que le dio el post. Es posible que tu cliente de descarga todavía tenga la importación fallida de antes, así que una release que lleva en Sonarr o Radarr sin poder importarse necesita que se elimine ese elemento de la cola antes de que vuelva a intentarlo.

## Los títulos con signos de puntuación también conservan sus nombres completos {#titles-with-punctuation-in-them-keep-their-whole-names-too}

El arreglo de nombres de archivo más arriba en esta lista hizo que zurg dejara de cortar los nombres en caracteres acentuados y chinos. No fue suficiente. zurg decidía qué era un nombre de archivo listando los caracteres que se permiten en él, y esa lista no incluía veinte signos comunes, así que un título que llevara uno se cortaba en ese punto de la misma forma:

    Tom & Jerry - The Movie.1992.1080p.mkv   ->   Jerry - The Movie.1992.1080p.mkv
    Mairimashita! Iruma-kun (2026) [22].mp4  ->   Iruma-kun (2026) [22].mp4

`!`, `&`, `#`, `$`, `%`, `@`, `~`, `;`, `=` y `^` provocaban todos ese corte.

Enumerar los caracteres que puede tener un título es una batalla perdida, así que zurg ya no lo intenta. Un nombre es un nombre de archivo, y los únicos caracteres que seguro no pueden estar en uno son los que ningún sistema de archivos acepta: `/ \ : * ? " < > |`. Todo lo demás ahora forma parte del título.

Lo comprobé con cada NZB de un directorio de vigilancia grande: de los asuntos que son un nombre de archivo simple, casi todos los que antes salían cortados ahora conservan su nombre completo, y los únicos que siguen acortados son aquellos a los que se les quita el sello por descarga que añade el indexador, que es lo que debe pasar.

## Una versión cuyos archivos fueron renombrados recoge los nombres nuevos por sí sola {#a-release-whose-files-were-renamed-picks-the-new-names-up-on-its-own}

El cambio en los nombres de archivo que hicimos antes modificó lo que zurg llama a los archivos dentro de una release de Usenet, y una release que ya estaba en tu biblioteca no siempre se dio cuenta. zurg compara una release que ya conoce con un listado nuevo usando el enlace que guardó para cada archivo, y un enlace de Usenet incluye la posición del archivo dentro de la release. Cuando un nombre corregido se ordena de forma distinta al anterior, esa posición cambia, el enlace guardado ya no apunta al mismo archivo y no queda nada con lo que hacer la comparación, así que el nombre antiguo se quedaba.

Ahora usa como alternativa el tamaño del archivo, que no cambia. Si exactamente un archivo de la release tiene ese tamaño, se considera ese archivo y se toma el nombre. Si dos archivos tienen el mismo tamaño, no se renombra nada en lugar de adivinar y acabar asignando un episodio al nombre de otro.

Las releases cuya posición no cambió ya estaban recogiendo los nombres nuevos y no se ven afectadas, y tampoco cualquier backend que no sea de Usenet, ya que sus enlaces no cambian cuando se renombra un archivo.

## Un archivo que el montaje no puede leer deja de frenar todo lo demás {#a-file-the-mount-cannot-read-stops-holding-everything-else-up}

Cuando una lectura falló por un motivo que zurg no podía identificar, le indicaba al cliente que lo intentara de nuevo, y seguía haciéndolo mientras el archivo siguiera fallando. rclone se toma eso muy en serio: una sola lectura de un archivo así tardaba 55 segundos y unas tres docenas de peticiones antes de rendirse, y como rclone reduce la velocidad de toda su conexión con un servidor que sigue devolviendo errores, el siguiente archivo en buen estado tardaba 3,66 segundos en abrirse en lugar de 0,04.

Ahora los reintentos se detienen tras un minuto del mismo fallo. La lectura recibe la misma respuesta que ya recibía una lectura de un archivo roto, el archivo mantiene su sitio en el listado de tu biblioteca, y la misma lectura tarda medio segundo.

zurg sigue intentando la descarga cada vez, así que si el archivo vuelve a estar disponible, lo recoge la siguiente lectura.

## El montaje deja de descargar en cuanto dejas de leer {#the-mount-stops-downloading-once-you-stop-reading}

A library scan, a subtitle check o cualquier otra cosa que toque muchos archivos en poco tiempo estaba sacando mucho más de tu cuenta de debrid de lo que leía.

rclone 1.74 empezó a mantener un archivo descargándose durante cinco segundos después de que el último programa lo cerrara. Nada estaba esperando esos bytes, y con una cuenta rápida cinco segundos son unos cientos de megabytes por archivo. Leer 1 MiB de cada uno de veinte archivos sacaba 4.2 GiB, cuando antes sacaba 80 MiB.

zurg ahora desactiva eso. Los montajes con rclone 1.73 o anterior no se ven afectados ni cambian, porque la opción no existe en esas versiones.

Si usas tu propio rclone en lugar del montaje de zurg, añade `--vfs-handle-caching 0` a tu comando de montaje con rclone 1.74 o más reciente. El README lo explica.

## Una versión que pierde un volumen de archivo ya no pierde el resto {#a-release-that-loses-one-archive-volume-no-longer-loses-the-rest}

Las releases de Usenet publicadas como un conjunto multiparte de rar o 7z podían dejar de importarse por completo. Sonarr y Radarr se quedaban en "Waiting for import" y nunca salían de ahí, y la carpeta de la release acababa con solo las partes rar, o directamente dejaba de existir.

Cuando zurg no podía leer un volumen de un conjunto, lo apartaba apuntándolo aparte y dejaba que el siguiente listado siguiera sin él. Ese listado veía el conjunto con un volumen menos, se paraba en el volumen que venía detrás y también lo apartaba. Una release iba perdiendo volúmenes en cada listado, más o menos uno cada diez minutos, y cuando ya no le quedaba ninguno desaparecía de la biblioteca y de la carpeta de la que importa el cliente de descargas. Para Sonarr, una ruta que no existe no es una carpeta vacía, es una importación que falla para siempre.

Ahora, un volumen que se sabe ilegible se queda dentro de su conjunto. Todos los listados se paran en el mismo volumen y dicen lo mismo de él, así que una release a la que le falta parte de su publicación se informa una sola vez como tal, y tu cliente puede meterla en la blocklist y buscar otra copia. Las releases cuyos volúmenes son todos legibles no se ven afectadas.

## Los escaneos siguen la biblioteca a su nuevo hogar bajo `__magic__` {#scans-follow-the-library-into-its-new-home-under-__magic__}

El espejo de tu biblioteca pasó de `__magic__` a `__magic__/__all__` en
2026.09.17.2240-nightly. Una parte de zurg seguía usando la ruta antigua.

Cuando llegaba una nueva versión, el escaneo que zurg pedía a Plex o Jellyfin apuntaba a una carpeta que no existía desde esa versión. Por eso nunca se encolaba nada y el contenido nuevo tenía que esperar al escaneo programado del propio servidor de medios. Quien usara un script de `on_library_update` recibía la misma ruta.

Ahora los dos apuntan a la carpeta desde la que tu cliente de descargas tiene que importar, y también lo hace el listado que zurg elimina de la caché del montaje cuando llega o se va una versión.

## La lista de seguimiento ahora puede aceptar torrents de indexadores Torznab {#the-watchlist-can-take-torrents-now-from-torznab-indexers}

Hasta ahora, una watchlist o una solicitud de Seerr solo podía satisfacerse desde Usenet. Añade `type: torznab` a un indexador y zurg también buscará en él, y un resultado de torrent se entrega a una cuenta de debrid en lugar de escribirse en `nzbs/`.

**Solo se entrega a una cuenta que ya lo tiene en caché.** Cada cuenta que acepta añadidos recibe el hash, porque las cachés son independientes, y la primera que ya tiene el release lo toma. Si no lo tiene ninguna, es solo un candidato que no funcionó, así que zurg pasa al siguiente release, que puede ser otro torrent o un NZB. No se descarga nada en tu cuenta, no se gasta ninguna asignación de añadidos no cacheados y no queda nada en marcha para algo que nadie está esperando.

Cuando ambos tipos de indexador podrían responder, `prefer` decide cuál se consulta primero. Por defecto es `usenet`, a menos que indiques otra cosa, así que una instalación que solo tenía indexadores Newznab se comporta exactamente igual que antes. `torrents` lo invierte, y `best` toma lo que el ranking pone primero, sea torrent o no.

Una descarga de torrent espera a ser comprobada como cualquier otra, pero se le hace una pregunta distinta. La cuenta ya indicó que tiene el contenido, así que lo que se comprueba es que el release llegó a tu biblioteca con archivos dentro, y si aparece vacío se descarta para que le toque el turno al siguiente release.

También puedes ejecutar la adquisición solo con indexadores Torznab, sin ningún proveedor `nzb`.

## Un agente que lee la biblioteca ya no marca todas las versiones como vacías {#an-agent-reading-the-library-no-longer-calls-every-release-empty}

zurg, al pedir los listados MCP, solo calcula el tamaño de un release cuando se lo pides, porque recorrer la tabla de archivos de toda una biblioteca consume tiempo real. Para los releases que no había medido, devolvía el tamaño y el número de archivos como cero, y nada en la respuesta indicaba que ese cero significaba "no medido" y no "no hay nada ahí". Un agente al que le pedían listar un directorio decía que una película de 6.6 GB no tenía archivos, mientras que la herramienta para un solo release tenía la respuesta correcta todo el tiempo.

Ahora, un listado que no midió deja ambos valores fuera en lugar de devolver cero. Pídelos con `with_size`, ordenando por tamaño o con un filtro de tamaño. `zurg_library_search` también acepta `with_size`, algo que antes no podía hacer, así que obtener los tamaños ya no te obliga a reducir o reordenar el resultado.

## zurg doctor indica si el endpoint MCP está respondiendo {#zurg-doctor-says-whether-the-mcp-endpoint-is-answering}

`zurg doctor` comprobaba que el puerto del panel respondía y se quedaba ahí, lo que no dice nada sobre `/mcp`. Un endpoint que la config activa pero que el servidor luego se niega a servir, que es lo que pasa cuando `username` está vacío, parecía sano desde fuera y se explicaba en una sola línea del log de arranque y en ningún otro sitio.

Cuando `mcp.enabled` está activado, `doctor` ahora habla el protocolo con `/mcp` e informa de lo que recibe: que responde, que rechaza las credenciales configuradas, o que está activado pero no se sirve. Una instancia con el endpoint desactivado no se le pregunta por él y no recibe ninguna línea.

## Abrir el endpoint MCP en un navegador ahora te dice qué es {#opening-the-mcp-endpoint-in-a-browser-now-tells-you-what-it-is}

Al abrir `/mcp` en un navegador, respondía "Bad Request: GET requires an Mcp-Session-Id header", que es una respuesta correcta a una pregunta que nadie hizo. Ahora el endpoint se describe a sí mismo cuando un navegador lo abre: qué protocolo habla, la dirección a la que debes apuntar un cliente, el fragmento para el puente stdio, qué versión es esta y cada herramienta que ofrece en ese momento, agrupada por conjunto de herramientas. Las herramientas que describen lo que harían y esperan confirmación aparecen marcadas.

Esa lista sale del propio registro de herramientas, no de una copia que se mantenga a mano. Así, una herramienta que se oculta por `read_only`, por tus conjuntos de herramientas o por el interruptor del ciclo de vida no aparece como una que puedas llamar. La página también lo indica cuando el endpoint se sirve sin autenticación.

Ningún cliente se ve afectado. La página solo se sirve a un GET que pide HTML y no lleva sesión, lo que corresponde a un navegador y nunca a un cliente MCP. Un GET de un cliente sigue abriendo el flujo de eventos como antes.

## La reproducción de Usenet llena antes la cuota de conexiones {#usenet-playback-fills-the-connection-allowance-sooner}

Las lecturas de Usenet ahora colocan primero el artículo de la posición de reproducción en el planificador de la cuenta, antes de ofrecer el resto del rango pedido. Cuando un rango grande se reparte entre conexiones en pipeline, los artículos consecutivos se reparten entre esas conexiones, en lugar de darle a la primera conexión los cuatro primeros, a la segunda los cuatro siguientes, y así sucesivamente. Así, los primeros artículos útiles llegan en la primera ronda de conexiones y no tienen que esperar detrás de los bytes posteriores.

Los posts de archivos con artículos pequeños reciben una ventana de lectura anticipada de al menos 64 MiB. Los posts modernos con artículos de varios megabytes mantienen su ventana actual. El mayor número de artículos no aumenta el uso de memoria: los cuerpos especulativos se limitan a dos lectores y a la mitad de `cache_size_mb` (256 MiB por defecto), mientras que la caché de artículos mantiene su límite máximo actual. Las peticiones del tamaño de reproducción empiezan en 64 MiB en lugar de 128 MiB, así que un búfer del reproductor de 90 MiB ya no cae en la ruta de búsqueda/sondeo. Las búsquedas pequeñas sí siguen yendo por ella.

Un lote en pipeline bloqueado puede lanzar hasta cinco artículos distintos a la vez como peticiones redundantes. El límite de la cuenta de veinte peticiones de artículos por minuto no cambia, y la lectura anticipada, las reparaciones y el resto de trabajo que no tiene ningún cliente esperando siguen sin recibir peticiones redundantes.

Abrir archivos multivolumen también cuesta menos. Cuando PAR2 ya ha proporcionado la longitud exacta de cada volumen, la cabecera yEnc verificada de un volumen puede dar el paso común de artículos para un conjunto grande de volúmenes hermanos. Cada volumen hermano comprueba esa inferencia con su propia cabecera antes de servir su primer byte, así que la resolución ya no necesita un artículo en serie por volumen, y tampoco confía en una geometría inferida para los datos. La recuperación de nombres de archivo también responde a partir de la cabecera yEnc, en lugar de esperar a que se descargue el resto de ese artículo.

## Los archivos .strm guardados siguen un cambio de Base URL {#saved-strm-files-follow-a-base-url-change}

Cambiar la Base URL dejaba todos los `.strm` que ya estaban en `strm/` apuntando a la dirección anterior, y reiniciar no ayudaba, porque zurg solo escribía los archivos que faltaban. Ahora, un `.strm` cuya URL sea distinta de la que zurg escribiría se reescribe en su sitio. Eso pasa en cada arranque, y también enseguida cuando cambias la Base URL en el panel o activas `save_strm_files` allí. Los archivos que ya están bien se dejan como están, para que un servidor de medios no tenga que volver a leer toda la carpeta en cada escaneo.

Jellyfin guarda la URL que leyó de un `.strm` y toma la nueva en su siguiente escaneo de la biblioteca. Un `.strm` que todavía tenga un enlace de cuenta de una versión anterior también se reescribe, al formato que cambia entre cuentas y sobrevive a las reparaciones. Un `.strm` editado a mano dentro de `strm/` se sobrescribe, así que pon en Base URL la dirección que quieras usar.

## Activar la lista de seguimiento de Plex ya no la vacía {#turning-the-plex-watchlist-on-no-longer-empties-it}

Activar la watchlist antes leía toda tu lista como una cola pendiente y la iba procesando, borrando cada título a medida que lo hacía. Una primera ejecución quitó 121 títulos de una lista de 163 elementos en unos cuatro minutos. Plex no guarda ningún registro de una entrada de watchlist eliminada, así que la única forma de recuperarla era una copia tomada antes, y nada en la configuración ni en los logs avisaba de que esto iba a pasar.

Ahora hay dos ajustes que deciden qué hace la adquisición con la lista, y esa lista es tuya, no de zurg.

**`watchlist.only_new_items`** está activado por defecto. Al encender la watchlist, zurg empieza a vigilarla. Lo que ya esté en la lista se da por tratado, y lo que añadas después se adquiere. Se aplica una sola vez, en la primera ejecución, y nunca sobre una cola que ya existe, así que una instalación que ya estaba procesando una watchlist sigue exactamente igual que antes.

**`watchlist.remove_after_grab`** está activado por defecto, que es lo que la función siempre ha hecho, así que no cambia nada para ti a menos que lo pidas. Desactívalo si quieres que tu watchlist siga siendo una watchlist. Seguirá siendo una lista que consultas para decidir qué ver, y zurg la satisface en segundo plano sin editarla nunca. Un título que se deja en su sitio no cuesta nada volver a comprobarlo, porque el recibo ya lo cubre y ningún indexador vuelve a ser consultado por él.

Ambos están en la página de configuración y los dos se aplican en el siguiente reinicio. Una fuente de adquisición que definas explícitamente en `acquisition.sources` puede configurar cualquiera de los dos por fuente. No tienen ningún efecto en una fuente de Seerr, porque esta no es dueña de ninguna lista en la que zurg escriba.

## La lista de seguimiento y las solicitudes de Seerr esperan a los servidores de noticias antes de limpiarse {#watchlist-and-seerr-requests-wait-for-the-news-servers-before-they-are-cleared}

Antes, una descarga se daba por terminada en cuanto su NZB llegaba al directorio vigilado. El indexador respondía, la respuesta se leía como un NZB y el archivo se escribía. Eso son tres datos sobre el indexador y ninguno sobre la publicación. La solicitud se cerraba con base en ellos, y en una watchlist de Plex eso significa que la entrada se borra, y Plex no guarda registro de una entrada borrada. Una publicación muerta se llevaba así el único registro de que querías el título, antes de que nada hubiera leído un solo byte. Una sola ejecución sobre una watchlist de 163 elementos eliminó 121 títulos, y 12 de las versiones detrás de ellos no se pudieron leer.

Ahora, cada versión adquirida se comprueba en los servidores de noticias antes de que se confirme nada. Es la misma comprobación que el endpoint de SABnzbd viene haciendo desde la build nocturna del 08.28. Hay tres respuestas posibles y se mantienen separadas.

- **Los artículos ya no están.** La descarga no cuenta. El título se queda en tu watchlist, la solicitud sigue abierta y la versión queda recordada como muerta, así que el siguiente intento elige el siguiente candidato en lugar de quedarse con el que ya tienes en tu biblioteca. Una versión que se sabe muerta no cuesta nada. No se descarga y no ocupa lugar entre los tres candidatos que prueba un intento, así que una serie de publicaciones muertas al principio de un ranking se recorre en lugar de reintentarse para siempre. Si un pack de temporada resulta muerto, toda la temporada vuelve a quedar como pendiente, para que se busquen los episodios sueltos.
- **No se pudo preguntar a los servidores.** Un pool caído, una cuenta con límite de velocidad, o simplemente una biblioteca que todavía no ha listado el nuevo NZB. Como no se pudo establecer nada, no se decide nada. La solicitud espera y se vuelve a comprobar, y esperar no gasta ningún intento de reintento. Si una versión sigue sin poder comprobarse después de unas dos horas, se aparta igual que una muerta y le toca el turno a la siguiente versión. Nunca se borra el título por una versión que nadie pudo comprobar.
- **La versión está ahí.** Igual que antes.

Una instalación sin cuenta de Usenet no tiene nada que preguntar y no se ve afectada.

## Comprobar una versión grande ya no se queda sin tiempo en un servidor de noticias lento {#checking-a-big-release-no-longer-runs-out-of-time-on-a-slow-news-server}

Antes de que zurg dé por terminado un grab, pregunta a los servidores de noticias por cada archivo del mismo. Antes lo hacía de uno en uno. Algunas cuentas responden despacio y de forma estricta por turnos, así que mandar todas las preguntas a la vez por una sola conexión no iba más rápido. El servidor de un proveedor tardaba más de cinco segundos por archivo. Eso hacía que una release 4K de 133 volúmenes necesitara unos doce minutos de preguntas, y cada comprobación tiene un límite de cinco. La comprobación nunca llegaba a terminar, así que Sonarr y Radarr esperaban tres horas y luego veían que el grab había fallado, y la watchlist se quedaba esperando para siempre.

Ahora los archivos se preguntan varios a la vez, usando todas las conexiones de la cuenta menos la que se reserva para la reproducción. Cuantas más conexiones permita tu cuenta, más rápido se comprueba una release grande. Medido con la misma release de 133 volúmenes, que antes nunca se podía comprobar, ahora tarda menos de dos minutos con doce conexiones. Con cuatro conexiones todavía se agota el tiempo, porque lo que tarda son las propias preguntas. Una release pequeña no es más lenta que antes.

Una release que la comprobación no consigue completar a tiempo ya no bloquea el título. La watchlist la aparta igual que a una muerta y prueba con la siguiente release. Y el endpoint de SABnzbd la marca como fallida, como siempre, para que Sonarr y Radarr busquen otra.

## Las capturas solo en caché en TorBox ya no descargan las versiones que debían omitir {#cached-only-grabs-on-torbox-no-longer-download-the-releases-they-were-meant-to-skip}

TorBox tiene una opción que hace que un add rechace cualquier cosa que aún no tenga. Está en su API, pero en ninguna de sus documentaciones, y zurg no la estaba usando. Un grab solo de caché añadía el torrent, esperaba a ver si se completaba y lo borraba de nuevo cuando resultaba ser una descarga real. Eso gastaba uno de los sesenta adds por hora de la cuenta, ocupaba un hueco de transferencia y descargaba bytes de un release que el *arr ya había marcado para saltar.

Los grabs solo de caché ahora piden el contenido y, si TorBox no lo tiene, se rechazan en menos de un segundo, sin dejar nada en la cuenta. Un fallo sigue gastando uno de esos sesenta adds por hora, así que zurg los espacia igual que antes. Y un acierto sigue comprobándose en lugar de darse por bueno: la caché de TorBox puede decir que sí a un contenido que luego no consigue servir, así que el release tiene que terminar antes de que zurg lo dé por válido.

## Las capturas solo en caché en Debrid-Link ya no gastan la cuota diaria de añadidos {#cached-only-grabs-on-debrid-link-no-longer-spend-the-daily-add-allowance}

Debrid-Link acepta un info hash suelto además de un magnet, y solo lo añade cuando ya tiene el contenido. zurg estaba enviando un magnet, que es una instrucción para descargar: cada fallo de solo-caché se aceptaba, se contaba contra las 50 añadidas sin caché del día y una de las 20 ranuras de transferencia de la cuenta, y luego se borraba para recuperar el cupo. Con cincuenta fallos, la cuenta ya no podía añadir nada más hasta el reinicio diario.

Las capturas de solo-caché ahora envían el hash. Un fallo se rechaza directamente en unas diez centésimas de segundo y deja la cuenta intacta, así que un *arr puede recorrer una lista larga de releases sin gastar nada en los que nadie tiene. Esto también vale para las capturas que llegan como archivo .torrent: ese archivo existe para ahorrarle a un servicio la consulta de metadatos que obliga un hash suelto, y una pregunta de caché no necesita nada de eso.

## Los bloqueos por límite de tasa de Debrid-Link ahora retroceden de nuevo {#debrid-link-rate-limit-lockouts-are-backed-off-from-again}

Debrid-Link responde a su bloqueo de una hora por endpoint con HTTP 503 y el motivo en el cuerpo. zurg trataba cada 503 como si el servicio estuviera caído por un momento, así que nunca leía el motivo y seguía reintentando un endpoint que ya había dicho que hay que esperar una hora. Ahora reconoce el bloqueo y se mantiene alejado de ese endpoint hasta que se levante.

## `__magic__` ahora refleja tu biblioteca en `__magic__/__all__`, y deja su raíz para ti {#__magic__-now-mirrors-your-library-at-__magic____all__-leaving-its-root-to-you}

El namespace solía reflejar `__all__` en su propia raíz, lo que hacía que la carpeta que un cliente de descargas importa fuera la misma carpeta en la que ya estaba cada release. Una carpeta raíz de Sonarr o Radarr tenía que anidarse *dentro* de la carpeta de descargas para evitar las dos comprobaciones de estado que generaba esa configuración, y una importación manual apuntando a la carpeta de descargas recorría toda la biblioteca buscando un solo release.

El reflejo ahora está un nivel más abajo. `__magic__/__all__` es la biblioteca tal como la lista `__all__`, y es lo que ahora calculan `sabnzbd.complete_dir` y `qbittorrent.save_path`. La raíz de `__magic__` es tuya, para las carpetas `tv`, `movies` y `anime` a las que apuntas los \*arrs. Las dos son hermanas, así que ninguna contiene a la otra y ningún cliente da aviso.

**Esto cambia rutas.** Si configuraste `sabnzbd.complete_dir` o `qbittorrent.save_path` a mano (el caso del mapeo de contenedor), añade `/__all__` al final. Si apuntaste una biblioteca de Plex o Jellyfin a `__magic__` en sí, en lugar de a una carpeta dentro de él, sus rutas se mueven un nivel; apúntala a `__magic__/__all__` o a la carpeta en la que importas. Tus carpetas raíz no se mueven, y nada guardado en la tabla se mueve: las ubicaciones son rutas dentro de carpetas que tú creaste, y los tombstones se indexan por el release, así que la estructura existente no se toca. Un grab que ya esté en curso cuando actualices lleva la ruta antigua y hay que volver a hacerlo.

No se puede escribir nada dentro de `__magic__/__all__`: una fila ahí sería una segunda dirección para un release que ya tiene una, así que un MOVE, MKCOL o DELETE dirigido a esa ruta se rechaza. Escribir *dentro* de la carpeta de un release sigue igual, que es donde un \*arr deja el .nfo junto a un archivo que ha importado.

## Export Logs ahora te dice adónde fueron tus enlaces y cuánto duran {#export-logs-now-tells-you-where-your-links-went-and-how-long-they-last}

Export Logs prueba varios servicios de pegado y te da el primero que acepta el archivo. Nunca decía cuál era, y no son intercambiables: el host preferido guarda un pegado durante 180 días y lo renueva cada vez que alguien lo lee, mientras que el de respaldo lo borra a los tres. Los enlaces tenían la misma pinta, y un informe enviado un viernes se había convertido en dos enlaces muertos el lunes, sin nada que explicara por qué. Ahora los enlaces incluyen el host que los guarda y la fecha límite que lleva asociada.

El motivo por el que acababas en el de respaldo es la segunda parte de esto. El host preferido bloquea una dirección que sube archivos varias veces seguidas, y una exportación publica dos archivos por clic, así que una tanda de informes de errores hacía que la dirección fuera rechazada. A partir de ahí, cada petición de esa máquina era denegada, incluida la lectura de un pegado que ya había guardado. Aun así, zurg metía las dos mitades de cada exportación posterior en ese host y registraba cada una como una subida fallida, lo que apuntaba al archivo en vez de a la dirección. Un host que rechaza la máquina ahora se deja en paz durante un día, y el log indica que eso es lo que ha pasado.

## Subir la información de depuración ya no publica tus claves de indexador y de cliente de descarga {#uploading-debug-info-no-longer-publishes-your-indexer-and-download-client-keys}

Export Logs redacta todas las credenciales que encuentra antes de enviar la configuración a un servicio de pegado, pero solo estaba revisando el nivel superior. Las claves que están dentro de los bloques anidados salían sin cifrar: las claves API de tus indexadores Newznab (tanto de la lista de Stremio como de la de watchlist), el token del addon de Stremio, las claves API de SABnzbd y qBittorrent, el token de cuenta de zrok y el token de escaneo de Plex. Las claves de los indexadores son las más delicadas, porque dan acceso a tu cuenta de Usenet, no a la de zurg.

Ahora ya están redactadas. Los tokens de los proveedores y las contraseñas de los servidores de noticias nunca se vieron afectados.

## Un agente de IA puede controlar zurg {#zurg-can-be-driven-by-an-ai-agent}

Hay un nuevo endpoint en `/mcp` que habla el Model Context Protocol, así que un cliente como Claude puede buscar en la biblioteca, averiguar por qué una release no se reproduce y repararla, mediante herramientas tipadas en lugar de leer el HTML del panel.

Viene desactivado por defecto. Actívalo con `mcp: {enabled: true}` y apunta un cliente a `http://your-zurg:9999/mcp` usando el mismo usuario y contraseña que pide el panel. Los clientes que solo hablan stdio usan `zurg mcp`, que se conecta a la instancia que ya está en marcha en lugar de iniciar una segunda.

Además de las herramientas, ofrece la documentación de zurg y su estado en vivo como recursos que un cliente puede leer directamente, y seis prompts para los procedimientos que conviene seguir al pie de la letra: diagnosticar una release que no se reproduce, preparar un escaneo de Plex de forma segura y revisar lo que la reparación ha dejado de intentar.

Sabe qué no puede hacer en silencio. Cualquier acción que quite algo describe primero lo que haría y solo actúa cuando confirmas ese plan exacto. `read_only: true` oculta todas las herramientas que cambian algo, y las herramientas que podrían detener zurg o su montaje quedan tras su propio interruptor. Ningún resultado incluye un token, una contraseña ni un enlace resuelto.

Consulta [el servidor MCP](mcp.md).

## zurg te avisa cuando tu versión está desactualizada {#zurg-says-when-your-build-is-out-of-date}

Nunca antes zurg mostraba la antigüedad de una compilación, y por eso un defecto corregido en agosto llegó a un reporte de error en septiembre con la corrección ya de tres semanas, y nadie en el hilo tenía motivo para sospechar. Ahora zurg consulta una vez al día al repositorio público de GitHub cuál es la release más reciente y, si tu compilación es anterior, escribe una sola línea con el nombre de la release, su fecha y la tuya. El resto del tiempo se mantiene en silencio: no imprime nada si estás al día, no imprime nada si no se puede contactar con GitHub, y una compilación que no sabe cuándo se creó, que es el caso de la imagen de Docker, no se supone a ciegas. Los patrocinadores que usan una nightly siempre van por delante de la última release pública, así que nunca la ven. La respuesta se guarda en caché durante un día, de modo que reiniciar no supone ninguna petición, y si una consulta falla no se vuelve a intentar hasta el día siguiente. Todo esto se desactiva con `disable_update_check: true`.

## Un enlace roto dentro de una versión archivada deja de declararse sano en cada revisión {#a-dead-link-inside-an-archived-release-stops-being-declared-healthy-every-sweep}

Cuando un release se sirve como un único archivo y la reparación no puede acotar más un re-add, zurg comprueba si el propio archivo sigue leyéndose. Si es así, quita las marcas de rotura del release en lugar de condenarlo. Quitó todas, incluidas las de los archivos a los que la cuenta accede directamente con enlaces propios. Un enlace de archivo verificado demuestra que el archivo se lee, pero no demuestra nada sobre esos otros. Así que un archivo cuyo enlace la cuenta había dejado de servir volvía a marcarse como sano basándose en una lectura que no tenía nada que ver con él. En la siguiente pasada, el barrido lo desrestringió, lo encontró muerto otra vez, el release volvió a condenarse, y la pasada que lo condenó terminó restaurándolo de nuevo. En un release de 64 archivos con 9 enlaces que la cuenta había dejado de servir, esto se repitió 111 veces en una semana, dos veces dentro de los mismos 40 segundos, con dos magnet add por pasada.

El indulto ahora solo cubre los archivos que el archivo realmente sirve, que son los que no tienen enlace propio. Un archivo al que la cuenta accede mantiene el veredicto que ganó con su propio enlace y pasa a reparación, que es el único camino que puede darle un enlace que funcione.

## Las descargas que llegan solo en parte ya no se quedan en la cola para siempre {#downloads-that-only-partly-arrive-no-longer-sit-in-the-queue-for-ever}

Cuando no se podían leer algunos de los archivos de un lanzamiento, zurg dejaba su descarga en la cola esperando tamaños exactos de archivo que nunca iba a recibir, y la comprobación que habría detectado el problema solo se ejecutaba cuando esos tamaños llegaban. Sonarr y Radarr mostraban esa descarga en 0% y sin tiempo restante, mientras zurg siguiera funcionando, y nunca añadían el lanzamiento a la lista de bloqueo ni buscaban otro.

zurg ahora pregunta a los servidores de noticias por un lanzamiento que lleva esperando treinta minutos, y marca la descarga como fallida si sus artículos ya no están, o si no se pudo consultar a los servidores. Un lanzamiento cuyos tamaños todavía están en camino no se ve afectado y sigue retenido hasta que lleguen.

## Una versión que una cuenta abandonó puede repararse con otra {#a-release-one-account-gave-up-on-can-be-repaired-from-another}

Los servicios de debrid mantienen cachés independientes. Un release que Real-Debrid ha purgado, o que rechaza solo por el nombre del archivo, puede estar en caché en AllDebrid en este mismo momento con el mismo hash. Hasta ahora zurg no podía aprovechar eso. Repair siempre volvía a añadir un release a la cuenta de la que venía, así que, una vez que esa cuenta se había rendido, no quedaba nada que probar, y el release seguía muerto en tu biblioteca mientras otra cuenta que ya pagas lo tenía disponible.

Ahora, un release que todas las cuentas que lo tienen han dado por perdido se ofrece a tus otras cuentas. La primera que ya lo tiene se queda con él, y el release vuelve a funcionar con ambas cuentas detrás, cambiando de una a otra igual que cualquier release que tengan dos cuentas. No hay nada que activar: si tienes una segunda cuenta configurada y repair está habilitado, esto es lo que hace repair cuando se queda sin otras opciones.

Una cuenta solo recibe contenido que ya tiene. Si tuviera que descargar el release, el añadido se retira y se borra de nuevo, así que nada se descarga y no se gasta ninguna cuota de transferencia. Una cuenta que responde que no se vuelve a consultar un día después, luego dos días, luego cuatro, hasta unas dos semanas, de modo que un release que ha desaparecido para siempre deja de costar nada por seguir preguntando.

## Las capturas solo en caché se juzgan por tu cuenta, no por una consulta a la caché {#cached-only-grabs-are-judged-by-your-account-not-by-a-cache-lookup}

En el modo solo-caché, zurg solía preguntar a TorBox, Premiumize y Offcloud si un
lanzamiento estaba en su caché y devolvía esa respuesta directamente a Sonarr. Esos endpoints
responden a una pregunta distinta de la que se estaba haciendo. Dicen que el contenido está en la
caché del servicio, no que tu cuenta termine teniéndolo, y después nadie
comprobaba el torrent. Un sí que acababa en descarga llegaba a Sonarr como la
grabación instantánea que se le había prometido, que es justo lo que el modo solo-caché
existe para evitar.

Ahora todas las cuentas se evalúan de la misma forma. Se añade el torrent, se vigila la
instancia, y solo cuenta como caché el que termina dentro de la ventana. Cualquier otro
se borra y la grabación se rechaza, lo que hace que Sonarr pase al siguiente
lanzamiento de su lista. El coste es que un fallo en esos tres servicios ahora gasta
una plaza de añadido, cuando antes una consulta a la caché no gastaba nada.

## Una clave de respaldo de AllDebrid ya no responde por tu biblioteca {#an-alldebrid-backup-key-no-longer-answers-for-your-library}

`download_tokens` en una cuenta de AllDebrid son cuentas de AllDebrid separadas, que se guardan por su cuota de descarga. Cuando la clave de la propia cuenta llegaba a su límite y salía de la rotación, todas las demás llamadas también se enviaban con la clave de respaldo: el listado de magnets, la lista de archivos de un release, las adiciones, los borrados, los reinicios, los enlaces guardados detrás de `__downloads__` y la sonda de detección de cambios. Así, la actualización de la biblioteca podía listar los magnets de la cuenta de respaldo y adoptarlos como si fueran tuyos, un borrado podía enviarse a una cuenta que nunca había tenido ese magnet y devolver la respuesta de que ya estaba eliminado, y cuando todas las claves llegaban al límite, el catálogo se quedaba completamente caído por algo que solo es un límite de bytes. Ahora solo se rota al desbloquear un enlace. Todo lo que tiene que ver con tu cuenta se le pide a tu cuenta.

## Una versión sana deja de entrar y salir de la lista de Rotos {#a-healthy-release-stops-flapping-in-and-out-of-the-broken-list}

A release cuyo account sigue ofreciendo un enlace muerto podría quedarse en la lista Broken del panel la mitad de cada hora, mientras cada archivo de ese release se reproducía perfectamente. La reparación quita un enlace que ha respondido `hoster_unavailable` durante tres ciclos, para volver a direccionar el release, y recuerda esa retirada para que el siguiente listado no pueda devolver el cadáver. Pero esa memoria la borraba lo equivocado: cualquier reparación que terminaba bien la limpiaba, incluidas las pasadas que no creaban nada y solo confirmaban que la dirección que la entrada ya tenía seguía funcionando. "El archivo que sirve el release sigue funcionando" es el caso extremo: demuestra que el único enlace que sirve el release funciona, y no dice absolutamente nada sobre un enlace que la cuenta rechazó. Así que la retirada se olvidaba, la siguiente actualización volvía a adoptar el mismo enlace muerto, la reparación no conseguía asignarlo de nuevo y condenaba la entrada otra vez, en un ciclo de treinta minutos que nunca podía terminar. Medido en una biblioteca real durante tres días: un release fue condenado 129 veces, 556 condenas en toda la biblioteca en una semana, y cada ciclo gastaba entre dos y cuatro adiciones de magnet. Ahora solo una reparación que realmente re-direccionó el release olvida una retirada, y una reparación manual sigue olvidándolas todas, para que un operador pueda devolver un enlace a mano.

## Un release servido como un solo archivo ya no se marca como roto en cada barrido {#a-release-served-as-one-archive-is-no-longer-marked-broken-every-sweep}

Algunas releases se sirven como un único archivo: el `.rar` contiene el único enlace de la cuenta y cada episodio dentro de él aparece listado como un archivo propio, sin enlace en ninguna parte. El barrido de reparación preguntó igualmente a la cuenta por esos archivos internos. No había nada con qué preguntar, así que no se consultó ninguna cuenta y no se midió nada, y aun así la respuesta fue "file is broken", que el barrido escribió en cada archivo y usó para condenar la release entera. Lo que vino después costó dos magnet adds: la cuenta fue consultada solo por los archivos rotos, respondió con el mismo enlace de archivo único de siempre, y el fallback del archivo verificó ese enlace y restauró todos los archivos que acababan de ser condenados. Medido en una biblioteca real: 44 episodios de un único archivo de 4.9 GB pasaban por ese ciclo cada media hora. Ahora, un archivo para el que ninguna cuenta tiene enlace se deja en paz, y el archivo propio del archivo se juzga igual que antes: cuando el enlace que realmente sirve la release deja de resolverse, ese archivo pasa a estar roto y la release con él.

## El tráfico vuelve a tu propio token de cuenta cuando se restablece tu cuota {#traffic-goes-back-to-your-own-accounts-token-once-its-allowance-resets}

Una cuenta de Real-Debrid que agota su cuota diaria traslada su tráfico al primer entrada de `download_tokens` que todavía tenga cuota, y el watcher vuelve a poner el token propio de la cuenta en la rotación en cuanto puede servir bytes otra vez.

Recuperar el token no devolvía el tráfico. La rotación seguía desde donde se había quedado y solo comprobaba si ese token concreto estaba limitado, así que la cuenta de respaldo seguía consumiendo todos los bytes durante el resto del día, aunque el contador de la cuenta principal ya estuviera en cero. El orden de `download_tokens` ahora es una preferencia y no una posición por la que avanzar: el token que esté más arriba y pueda servir es el que sirve, así que la cuenta principal recupera su tráfico en menos de un minuto después de que se reinicie su contador.

## Un remote de rclone apuntando a una dirección incorrecta ahora lo indica {#an-rclone-remote-pointed-at-the-wrong-address-now-says-so}

Si la URL de un remote WebDAV de rclone no tiene `/dav/` al final, todos los listados fallaban con "couldn't list files: 405 Method Not Allowed" y no había nada en ningún lado que dijera por qué. El dashboard respondía bien en el navegador, así que zurg parecía sano, y el log de zurg se quedaba callado sobre el cliente que fallaba cada pocos segundos. Ahora zurg responde a una petición WebDAV que llega fuera de `/dav/` con la dirección que hay que usar, que rclone muestra como parte de su propio error, y escribe una sola advertencia que indica el cliente que la envió.

## Las instalaciones de Windows vuelven a enviar escaneos al servidor multimedia {#windows-installs-now-send-media-server-scans-again}

A `mount_path` de `Z:`, que es lo que `zurg setup` escribe en Windows, construía las rutas de escaneo relativas al directorio actual de esa unidad en vez de a su raíz. Por eso cada ruta fallaba al buscar la sección de biblioteca a la que pertenecía y nunca se enviaba ningún escaneo. La advertencia que aparecía después pedía revisar un `mount_path` que ya estaba bien. Las configuraciones existentes no necesitan ningún cambio.

## El escaneo masivo lee la biblioteca de Plex una vez en lugar de una vez por torrent {#bulk-scan-reads-the-plex-library-once-instead-of-once-per-torrent}

Tras un escaneo masivo desde el panel, la comparación releía toda la biblioteca de Plex para cada torrent del lote, así que escanear una biblioteca grande lanzaba cientos de peticiones idénticas de biblioteca completa contra un servidor Plex que normalmente ya estaba ocupado escaneando.

## Las rutas de la biblioteca en Windows coinciden sin importar mayúsculas o minúsculas {#windows-library-paths-match-regardless-of-case}

A una biblioteca de Plex, Jellyfin o Emby registrada como `Z:\Movies` ya no se le escapa
`Z:\movies`, la ruta que zurg construye a partir del nombre de su propio directorio. NTFS no distingue
mayúsculas de minúsculas, así que ambas rutas apuntan al mismo directorio; al compararlas de forma exacta
se descartaba el escaneo y se informaba de que mount_path era incorrecto.

## Un archivo que deja de servirse ya no bloquea un escaneo de Plex {#a-file-that-stops-serving-no-longer-stalls-a-plex-scan}

Un archivo roto conservaba su lugar en el listado del directorio y respondía a las lecturas con `503 File temporarily unavailable (being repaired)` hasta que algo levantaba el veredicto: con la reparación en marcha, hasta que la reparación terminaba. Plex se bloquea con un 503, así que un solo archivo así detiene un escaneo de la biblioteca, y una biblioteca que acumula varios nunca termina de escanearse. Jellyfin los salta y todo parece normal.

Son dos decisiones separadas y ahora tienen respuestas separadas. La entrada sigue apareciendo en el listado mientras pueda volver, porque una entrada que desaparece de una carpeta le parece a un escáner de medios una eliminación y hace que el elemento se mande a la papelera. Eso no cambia. Lo que cambia es la lectura: responde 503 durante un minuto después de que el archivo deja de servir, y 404 a partir de ahí. Un minuto es lo que un cliente puede aprovechar, ya que rclone reintenta un 503 y se rinde con una lectura más o menos en ese punto. Así, un fallo breve sigue absorbiéndose y la lectura tiene éxito, mientras que pasado ese tiempo el 503 ya estaba haciendo fallar la lectura y costaba cada escaneo que venía detrás.

Medido con un Plex real, en una biblioteca de quince películas con diez archivos rechazados y todos los archivos todavía listados: las lecturas que respondían 404 terminaron el escaneo en 5 segundos, y un 503 que nunca se levantaba había encontrado tres de las quince cuando la ejecución se cortó a los diez minutos.

## Los nuevos trabajos de SABnzbd ya no esperan tras las comprobaciones de tamaño de una biblioteca completa {#new-sabnzbd-jobs-no-longer-wait-behind-a-full-librarys-size-checks}

Cuando zurg se reiniciaba con una biblioteca grande de Usenet, encolaba una comprobación de tamaño para cada release y olvidaba qué comprobaciones fallidas seguían dentro de su espera de reintento de una hora. Así, un release recién descargado podía quedarse detrás de miles de comprobaciones en segundo plano mientras Sonarr o Radarr esperaban sus tamaños exactos de archivo. Ahora las comprobaciones de tamaño usan una cola de workers fija, un release con un trabajo de SABnzbd en espera pasa al principio, y tanto las comprobaciones completadas como las esperas de reintento sobreviven a un reinicio en `data/nzb-sizes/`. Mientras haya trabajo en cola, zurg informa una vez por minuto de cuántos elementos están en espera, cuántos son de prioridad de cliente y cuántos se están ejecutando.

## Las descargas que un cliente nunca libera ya no impiden importar las nuevas {#downloads-a-client-never-clears-no-longer-stop-new-ones-from-being-imported}

zurg muestra a Sonarr, Radarr y otros clientes de descarga una página de descargas terminadas, y mantiene cada una en esa página hasta que el cliente la quita. Los clientes solo quitan lo que importan o lo que falla, así que una importación bloqueada, como un título que no pueden emparejar, se quedaba en la página para siempre. Cuando la página se llenaba de esas, cada descarga nueva que terminaba esperaba en la cola y nunca se importaba. Ahora, una descarga que lleva diez minutos en la página sin que el cliente la quite cede su lugar a una que está esperando, igual que SABnzbd quita de su página de historial las filas más antiguas cuando llegan nuevas. Nada cambia mientras la página tenga espacio, y volver a buscar un release le da un lugar propio.

## Una descarga buscada por su id se encuentra en cuanto termina {#a-download-looked-up-by-its-id-is-found-as-soon-as-it-finishes}

Las herramientas que le preguntan a zurg por una sola descarga, usando su id, como LazyLibrarian, ahora reciben el aviso de que terminó en cuanto ocurre, incluso cuando la página de descargas terminadas que leen Sonarr y Radarr está llena. Antes, esa descarga podía aparecerles como sin terminar hasta que se liberara un lugar en esa página.

## La corrección de temporadas tiene una página en el panel {#season-fix-has-a-page-in-the-dashboard}

La renombración de toda la biblioteca que organiza los episodios numerados de fansub bajo los nombres que lee Plex solo era accesible como dos endpoints HTTP desde que se lanzó: `/torrents/season-fix/plan` y `/torrents/season-fix/apply`. No había ningún control en el panel y solo un párrafo en la referencia de nombres. Una función que nadie puede encontrar no existe, y esta se había pedido en el canal de sugerencias hace poco, este mismo mes, por gente que no tenía ni idea de que ya estaba hecha.

`/season-fix/` ahora explica qué hace el proceso, muestra la forma canónica que produce frente al nombre de fansub que reemplaza y dice de dónde sale la estructura de temporadas: del propio proveedor de metadatos de Plex, nunca de la biblioteca local, ya que una biblioteca que ha colapsado las temporadas es justo lo que se está arreglando. También enumera lo que el mapeador no toca y por qué, porque un escaneo que devuelve casi nada es la respuesta conservadora funcionando y no un fallo.

El escaneo sigue detrás de un botón: la planificación recorre cada torrent y pregunta a Plex por cada serie emparejada, así que abrir la página no lo inicia. Los resultados se agrupan por serie, con cada renombrado mostrado de antiguo a nuevo, y los archivos omitidos quedan detrás de un desplegable. Una entrada marcada como posible emparejamiento con la serie equivocada llega sin marcar y lo vuelve a decir en la confirmación, para que aplicar todo de golpe no pueda renombrar en silencio una versión asociada a la serie incorrecta.

## Reproduce un release comprimido que está dividido en varios volúmenes {#play-a-compressed-release-that-is-split-across-several-volumes}

Una release que venía empaquetada con compresión en vez de guardada completa se paraba al final de su primer volumen. Todos los archivos de dentro aparecían listados con el nombre y el tamaño correctos, pero no había forma de reproducirlos, y en el log quedaba un bad header CRC. Ahora zurg sigue el desempaquetado al cruzar cada unión de volúmenes, así que estas releases se reproducen de principio a fin.

## Arranca rápido cuando tu cuenta tiene torrents fallidos {#start-up-quickly-when-your-account-holds-failed-torrents}

Cada actualización de la biblioteca volvía a comprobar, una por una, todas las torrents que tu servicio de debrid tenía marcadas como failed, y el servicio solo permite unas pocas de esas consultas por segundo. En una cuenta con unos cientos de ellas, eso por sí solo tardaba más de un minuto en cada actualización, y tu biblioteca seguía sin poder leerse durante ese tiempo tras cada inicio. Es tiempo suficiente para que Plex escanee una carpeta que todavía no existe y marque todo lo que hay dentro como no disponible. Ahora zurg lee desde disco lo que ya sabe sobre una torrent failed y solo vuelve a consultar al servicio cuando este indica que la torrent ya no está failed.

## Deja de volver a preguntar a AllDebrid por magnets que ya rechazó reintentar {#stop-re-asking-alldebrid-about-magnets-it-has-already-refused-to-retry}

Cuando un magnet falla, zurg le pide a AllDebrid que lo vuelva a buscar. AllDebrid rechaza
algunos de esos, y el rechazo no se contaba dentro de los dos intentos que tiene cada torrent, así que el mismo magnet se volvía a consultar en cada actualización de la biblioteca mientras zurg estuviera funcionando. Ahora la respuesta se recuerda durante una hora, junto con el estado que le dio la cuenta, de modo que si un magnet cambia se vuelve a consultar. El número de intentos también se guarda en disco, en lugar de olvidarse en cada reinicio y volver a gastarse.

## Mantén estable el enlace de un release que tu cuenta tiene dos veces {#keep-the-link-steady-for-a-release-your-account-holds-twice}

Un release añadido dos veces a una misma cuenta tiene dos de todo, incluidos dos enlaces de descarga por archivo. zurg guardaba un enlace por cuenta, así que cada copia reemplazaba a la otra en cada actualización y la entrada nunca se estabilizaba. Nada era injugable, pero el log se llenaba de reapuntados y la biblioteca se reescribía en disco cada pocos segundos. Ahora zurg deja el enlace como está cuando solo puede ver una parte de lo que tiene la cuenta.

## Comprobaciones de cambios más rápidas en TorBox cuando la cuenta tiene torrents fallidos {#faster-change-checks-on-torbox-when-the-account-holds-failed-torrents}

TorBox no tiene forma de saber si una cuenta cambió, así que zurg lee una página pequeña con los torrents más recientes y vigila los que todavía no han terminado. Un torrent que TorBox ha marcado como fallido nunca termina, así que un solo fallo antiguo hacía que cada comprobación leyera una página mucho más grande, durante toda la vida de la cuenta. Los torrents fallidos ya no se vigilan en busca de cambios que no pueden hacer.

## Un release que tu *arr no pudo importar ya no se borra con el intento {#a-release-your-arr-could-not-import-is-no-longer-deleted-by-the-attempt}

Cuando zurg se niega a mover un lanzamiento fuera de la carpeta de staging de Usenet porque no se puede leer desde los servidores de noticias, Sonarr y Radarr no se rinden sin más. .NET responde a un movimiento fallido copiando el archivo y luego borrando el original, y zurg estaba respetando ese borrado, así que el lanzamiento desaparecía y quedaba un archivo vacío en el lugar donde se había importado. Ahora, el borrado que sigue a un movimiento rechazado también se rechaza por la misma razón, y el lanzamiento se queda donde está.

## Las lecturas de Usenet distinguen un lote lento de uno bloqueado {#usenet-reads-tell-a-slow-batch-from-a-stalled-one}

zurg pide un artículo a una segunda conexión de noticias cuando la espera se ha alargado demasiado, y se queda con la respuesta que llegue primero. Decidir que la espera se había alargado se hacía con un reloj, y un lote normal de artículos grandes en una cuenta rápida se pedía dos veces mientras su primer artículo todavía estaba llegando.

Esa decisión ahora depende de los bytes que llegan por la red. Una conexión de noticias ya renueva su propio tiempo de espera cada vez que llegan bytes, y el lector también ve esa señal. Un lote a medio camino de un artículo grande se deja tranquilo, por mucho que tarde ese artículo. Solo se pide a otra parte un lote cuyos bytes se han detenido.

Cuando una conexión toma un lote de artículos y no responde a ninguno, zurg pide a otra conexión todo lo que queda de ese lote de una vez, en lugar de buscar cada artículo que falta por su cuenta. La conexión silenciosa nunca se corta, así que sus artículos siguen contando si llegan. Solo se vuelven a pedir los artículos que nunca llegaron, como máximo una vez por lote. Los artículos más cercanos a la posición de reproducción van primero, y siempre se reserva una segunda petición para que la siguiente lectura que se quede parada pueda pedir su propio artículo.

Una lectura también deja de tratar la espera que gastó en una segunda petición como su velocidad normal. Aprende solo el tiempo que zurg estaba dispuesto a esperar, ni más. En una cuenta donde cada artículo tarda legítimamente un segundo o más, el umbral ahora se estabiliza cerca de lo que esa cuenta entrega de verdad, en lugar de caer a su valor más corto y pedir dos veces la mayoría de los artículos.

## La lectura anticipada de Usenet mantiene su ventana llena entre artículos y volúmenes {#usenet-read-ahead-keeps-its-window-full-across-articles-and-volumes}

Antes, el read-ahead dejaba de pedir bytes nuevos mientras un artículo anterior iba con retraso, así que un solo artículo lento vaciaba la ventana que ya había construido. Ahora zurg mantiene igualmente una ventana acotada de bytes pedidos en vuelo, y un lote de artículos puede abarcar la unión entre dos volúmenes RAR almacenados en lugar de terminar en ella.

La ventana usa como máximo una cuarta parte de la caché de RAM que hayas configurado, y nunca más de 128 MiB, así que una caché más pequeña da una ventana más pequeña. Las peticiones mantienen su propia cancelación y los límites de conexiones y de caché de su cuenta.

## La reproducción de Usenet consume menos CPU en procesadores antiguos {#usenet-playback-costs-less-cpu-on-older-processors}

El caché de lectura calcula una suma de verificación de cada registro que guarda. En procesadores Intel y AMD que tienen SSE4.1 pero no AVX, SHA-256 se ejecuta sin ayuda de hardware, y ese coste se notaba durante la reproducción. zurg ahora usa una suma de verificación de 256 bits más rápida en esos procesadores. Los registros llevan una versión, así que los daños siguen detectándose, un caché existente sigue siendo legible y el resto de procesadores sigue usando SHA-256.

## Los recursos NZB compartidos ya no apuntan a la cuenta que los descargó {#nzb-shares-no-longer-point-back-to-the-account-that-grabbed-them}

Algunos indexadores marcan cada descarga con datos que llevan a tu cuenta, y parte de eso estaba en campos que guardaba un share. Uno oculta un token nuevo en el título del release y a menudo también en la contraseña, y cambia el remitente, la fecha y el grupo de noticias en cada archivo. Otro pone el número de tu cuenta al principio del asunto de un archivo. Un tercero pone una marca de cuenta en todos los remitentes. `zurg nzb-share` ahora elimina remitentes y fechas, asigna a cada archivo el mismo grupo de noticias fijo, quita la marca del asunto e ignora un token esté donde esté. Cuando el nombre y el título no coinciden, gana el nombre. Dos personas que descargaron el mismo release ahora publican el mismo archivo. Además, los shares ya no dejan fuera los NZB guardados en la codificación Latin-1, y dejan de duplicar las barras invertidas que tienen algunos asuntos.

Lo que elimina la limpieza está en [`zurg nzb-share`](cli.md#zurg-nzb-share).

## Las bibliotecas locales añaden el hash en AllDebrid, Premiumize y Offcloud {#local-libraries-add-the-hash-on-alldebrid-premiumize-and-offcloud}

A una biblioteca local cuyo manifiesto no tiene un enlace portable, zurg añade el hash a tu cuenta en la primera reproducción. Un manifiesto exportado desde TorBox siempre es así. Lo mismo pasa cuando el enlace de AllDebrid ha caducado. En AllDebrid, Premiumize y Offcloud, cada una de esas reproducciones fallaba con "provider did not report an active torrent allowance". zurg quería que la cuenta informara su límite de slots de torrent antes de añadir nada. Estos tres proveedores nunca informan ese límite. Ahora zurg recurre al número de slots declarado, igual que hace la reparación. Si no hay ninguno de los dos, añade el hash y deja que el proveedor rechace la cuenta si está llena.

## Los archivos de Offcloud informan su longitud {#offcloud-files-report-their-length}

Al resolver un archivo de Offcloud se le quedó sin definir su longitud. Una biblioteca local compara esa longitud con su manifiesto, así que rechazaba todas las reproducciones de Offcloud con "resolved file size does not match the portable manifest". La reproducción normal también perdió el manejo de rangos, que necesita una longitud. Ahora zurg pide la longitud al servidor de entrega de la misma forma que ya lo hace el listado de Offcloud.

## zurg funciona en teléfonos Android y Google TV {#zurg-runs-on-android-phones-and-google-tv}

A nueva aplicación Android aloja tu biblioteca en el propio dispositivo. Se adapta a teléfonos y tabletas, así como a Android TV y Google TV. Necesita Android 8.0 o más reciente, y Usenet requiere Android de 64 bits. La aplicación te guía por las cuentas de proveedores y un perfil de dispositivo, y después inicia la biblioteca. Puedes explorarla en la aplicación o en Archivos de Android, y reproducirla en el reproductor externo que elijas, con búsqueda completa. Un mando de TV controla todas las pantallas. MediaInfo funciona en el dispositivo sin herramientas adicionales. La biblioteca también se puede compartir con otros dispositivos de tu red local, protegida con una contraseña. Esa contraseña nunca se envía a un reproductor.

Los APK están en las versiones nightly de los patrocinadores. La aplicación no incluye zurg. Después de iniciar sesión en GitHub, instala el motor de zurg como un segundo paquete. La aplicación y el motor se actualizan por separado. Updates muestra todas las versiones del motor que siguen publicadas, para que una nightly que dé problemas en tu dispositivo pueda revertirse a una que funcionara bien. Quien haya instalado la primera compilación de Android debe instalar una vez un motor desde Updates. Los proveedores y la configuración de la biblioteca se conservan sin cambios.

El motor para dispositivos ARM de 64 bits ahora busca las direcciones de los proveedores a través del resolutor propio de Android. El motor de la primera compilación podía no llegar a ningún proveedor.

Las notas de configuración y de reproductor están en [Android](../guides/android.md).

## Un NZB nuevo aparece en la biblioteca en segundos {#a-new-nzb-shows-up-in-the-library-within-seconds}

Un NZB que caía en el directorio de vigilancia esperaba a la siguiente comprobación periódica de cambios. Después, una release ofuscada esperaba otro intervalo mientras se leían sus nombres de archivo reales. Con el intervalo por defecto, eso sumaba entre 20 y 30 segundos, con una descarga de Sonarr o Radarr parada en Queued todo ese tiempo.

Ahora zurg comprueba el directorio de vigilancia por sí mismo una vez por segundo. No depende de los eventos del sistema de archivos, así que se comporta igual en un NAS o dentro de un contenedor. Una release aparece en cuanto se han leído sus nombres. Un pack de temporada de veinte releases sigue costando un solo listado. La comprobación periódica se mantiene como respaldo, para un NZB que se reemplaza con un nombre que ya tenía.

## Los streams de Usenet mantienen su velocidad {#usenet-streams-hold-their-speed}

Un archivo dentro de un conjunto RAR llega a la cuenta de Usenet un volumen a la vez. zurg abre el siguiente volumen antes de tiempo para que el cruce no empiece en frío. Antes solo calentaba los primeros cuatro megabytes. En una versión dividida en volúmenes pequeños, eso significaba un límite cada uno o dos segundos de reproducción y una parada en cada uno. Una de esas versiones se reproducía a 14 a 16 MB/s, mientras que un archivo normal en la misma cuenta iba a 86 a 99 MB/s. Ahora el siguiente volumen se calienta con una ventana de lectura anticipada completa en cuanto el stream se acerca a menos de 32 MiB. Un volumen en el que el stream acaba de entrar conserva la lectura anticipada que ya se había ganado. Un volumen que nada tiene cerca sigue calentándose solo en su inicio. Así, un escaneo de la biblioteca no descarga datos que nunca se van a leer.

Además, una lectura continua pasaba alrededor de un segundo de cada veinte arrastrándose por culpa de un único artículo lento, mientras el resto de conexiones esperaba detrás. Ahora zurg pide ese mismo artículo a una segunda conexión cuando la espera se alarga y usa la respuesta que llegue primero. Esto solo se hace para una lectura que un reproductor está esperando. La lectura anticipada y la reparación nunca se duplican. Está limitado a veinte peticiones extra por minuto y por cuenta.

La lectura que espera un reproductor ahora tiene prioridad en más situaciones. La lectura anticipada ya no se queda con la última conexión libre de la cuenta. La pasada de dimensionamiento al arrancar también deja una libre. Una lectura usa las conexiones que la cuenta ya tiene abiertas en lugar de abrir una propia. Espera a una conexión que ya se está abriendo en vez de pagar por otra. El artículo que el reproductor tiene bloqueado puede saltar por delante de las descargas en cola de bytes posteriores. En una medición, el primer byte de una lectura llegó en 177 ms en lugar de 354 ms. El calentamiento, los keep-alives y las lecturas también comparten ya un único límite de conexiones. zurg nunca abre más conexiones de las que permite la cuenta.

Guardar un artículo decodificado en la caché de disco ya no retrasa la lectura que lo descargó. Antes la escritura estaba dentro de un bloqueo que necesitaban todas las demás lecturas. Ahora se hace después de que los bytes llegan al reproductor. Una ráfaga mayor de lo que la caché puede asumir omite los registros extra en lugar de frenar la reproducción. Una caché existente se conserva tal cual.

## Sonarr y Radarr dejan de esperar capturas que nunca pueden terminar {#sonarr-and-radarr-stop-waiting-on-grabs-that-can-never-finish}

El endpoint de SABnzbd solía dejar algunos trabajos en cola para siempre. El cliente nunca los añadía a la lista de bloqueo ni buscaba otra versión. Ahora, cada caso de los que se describen aquí se marca como Failed con un mensaje que explica el motivo. Failed es lo que hace que Sonarr y Radarr añadan la versión a la lista de bloqueo y vuelvan a buscar.

Una versión puede salir de la biblioteca después de su grab. Puede que se borre desde el panel, que se quite del directorio de vigilancia o que todas las cuentas la den por perdida. Antes el trabajo se quedaba en 0% sin nada que lo moviera. Ahora falla cuando la versión lleva fuera quince minutos. No falla nada en los primeros quince minutos después de un reinicio, mientras la biblioteca sigue cargando.

Un grab puede caer sobre una versión que una importación anterior ya vació. Eso pasa cuando una mejora borra el archivo importado y una búsqueda vuelve a elegir la misma versión. zurg antes respondía Completed y apuntaba al cliente a una carpeta sin nada dentro. Ahora, un grab de una versión vaciada falla en el acto. Una carpeta que sigue vacía durante quince minutos también hace fallar su trabajo. Esto incluye una carpeta vaciada por un movimiento hecho a mano o por una importación archivada bajo otro trabajo. El grab que hace la importación sigue mostrando Completed mientras termina.

Algunas versiones nunca terminan la comprobación de artículos. zurg pregunta a los servidores de noticias si los artículos de una versión siguen ahí antes de dar el grab por terminado. Antes, una comprobación que no podía completarse se reintentaba cada minuto sin fin. Ahora falla tras treinta intentos seguidos que abarcan al menos tres horas. Cuenta de noticias caída durante una hora no hace que se añadan a la lista de bloqueo todos los trabajos en espera. Una comprobación que por fin responde reinicia el contador.

Algunas versiones no tienen todo su archivo completo. Un conjunto puede no tener ningún volumen con el inicio del archivo. Puede faltarle un volumen en medio. Puede empezar en un volumen distinto del primero. Antes, Sonarr apuntaba a una carpeta de la que nunca podía importar y lo reintentaba para siempre. Ahora el grab falla. El veredicto depende de los volúmenes exactos con los que se llegó a él. Una reparación con PAR2, un nuevo grab o una segunda cuenta que tenga los volúmenes que faltan hacen que la versión se revise otra vez.

## Los tokens de descarga de respaldo toman el relevo cuando se agota la cuota diaria {#backup-download-tokens-take-over-when-the-daily-allowance-runs-out}

Real-Debrid rechaza una descarga cuando un token ya ha gastado su cuota diaria. zurg debería retirar ese token y pasar a la siguiente entrada de `download_tokens`. Eso dejó de pasar durante la reproducción cuando los streams con proxy se movieron a un nuevo cliente HTTP. El rechazo llegaba como una respuesta normal y nada marcaba el token como gastado. Así que todos los tokens de respaldo se quedaban sin usar y cada lectura volvía a gastar el que tenía el límite.

Ahora zurg reconoce el rechazo dondequiera que se encuentre con él. Eso incluye la reproducción, pero también el bucle de actualización y la reparación. Ambos comprueban enlaces aunque no se esté reproduciendo nada. Un rechazo que llega sin la cabecera habitual de Real-Debrid también retira el token.

Un token retirado se prueba cada minuto para que pueda volver en cuanto se renueve su cuota. Esa prueba usaba un enlace guardado en caché bajo el propio token retirado. Nada vuelve a llenar esa caché cuando el token deja de servir. Así que la prueba no encontraba nada y el token seguía fuera hasta el reinicio nocturno o hasta un reinicio de zurg. Ahora toma prestado un enlace de cualquier token que siga sirviendo.

El reinicio nocturno llegaba un día tarde. Real-Debrid renueva las cuotas unos minutos después de medianoche CET. zurg se saltaba la primera medianoche tras cada arranque y reiniciaba en la segunda. Una cuenta que ya había gastado su cuota seguía sirviendo desde su token de respaldo un día más. Además, zurg calculaba esa medianoche con la fecha del propio equipo. En zonas al oeste de Europa, eso dejaba el reinicio a la hora en que zurg hubiera arrancado por casualidad. Ahora cada reinicio se programa según la fecha en CET.

## Una captura por magnet conserva su nombre de release en la cuenta de debrid {#a-magnet-grab-keeps-its-release-name-on-the-debrid-account}

Sonarr y Radarr le pasan al endpoint de qBittorrent el magnet completo del indexador. Antes, zurg lo recortaba al info hash antes de añadirlo. Así, el nombre para mostrar y los trackers nunca llegaban a la cuenta. En un indexador que solo da magnets, el nombre para mostrar es el único lugar donde existe el nombre del lanzamiento. Un torrent no cacheado acababa en la lista de la cuenta con un hash de 40 caracteres. Para un torrent que nadie comparte, ese es el único nombre que llega a tener.

Ahora el magnet llega a la cuenta tal como lo envió el cliente. Repair, la lista de seguimiento de Plex y las bibliotecas portables siguen añadiendo solo el hash, porque no tienen ningún nombre que pasar.

## El volcado .strm solo contiene archivos que un reproductor puede abrir {#the-strm-dump-holds-only-files-a-player-can-open}

`save_strm_files` solía escribir un .strm para cada archivo seleccionado de un release. Los subtítulos, pósters, NFO y volúmenes PAR2 se convertían en entradas de la biblioteca que no abren nada. TorBox y AllDebrid marcan todos los archivos como seleccionados. Lo mismo pasa con un post de Usenet que trae archivos de reparación junto al video. Ahora solo se crea un .strm para el video y el audio reconocidos, además de cualquier extensión indicada en `addl_playable_extensions`. Un video dentro de un conjunto RAR sigue generando su .strm, pero los volúmenes que lo rodean no. Las entradas creadas por versiones anteriores se eliminan la próxima vez que se recorra el release.

Varias rutas de escritura también le pedían al servidor de medios que escaneara antes de que existieran los archivos .strm. Plex, Jellyfin o Emby podían revisar una carpeta vacía y no indexar nada, y nada le pedía que volviera a revisar hasta que cambiara el release. Ahora los archivos se escriben primero en todas las rutas.

## Mover la carpeta de zurg ya no deja huérfana la caché del montaje {#moving-the-zurg-folder-no-longer-strands-the-mount-cache}

El montaje de rclone guarda lo que lee en `data/rclone-cache`. rclone nombra esa caché según su propia configuración. La configuración incluye la ruta completa de la carpeta `data/local` de zurg. Si movías la carpeta de zurg o cambiabas `union_writable`, la caché recibía un nombre nuevo. El árbol antiguo se quedaba en el disco, donde ningún límite de tamaño lo contaba y nada lo limpiaba. Con unos cuantos cambios de ruta podían quedar varios terabytes olvidados.

Al iniciar el montaje, zurg ahora le pregunta a rclone qué árbol de caché está activo y borra los demás. Registra en el log cuánto espacio liberó. Omite esta limpieza cuando `rclone_extra_args` define su propio `--cache-dir`. Pon `rclone_cache_reclaim: false` si quieres conservar los árboles antiguos.

La caché activa también es más grande de lo que la mayoría espera. Crece hasta 256G por defecto y se queda así. El recorrido nocturno de un servidor multimedia toca todos los archivos, así que el límite de edad de 72 horas casi nunca desaloja nada. Planifica en torno al límite de tamaño. Cómo bajarlo está explicado en [la referencia de configuración](config.md#disk-the-mount-uses).

## Los pósters y archivos .nfo siguen llegando a `__magic__` {#posters-and-nfo-files-keep-landing-in-__magic__}

Un cliente que escribe a través del mount de zurg pone los archivos nuevos en `data/local`. Esa es la carpeta donde `__magic__` guarda sus sidecars. zurg contaba cada archivo de ahí contra `sidecar_budget_mb`. Unos pocos videos que un \*arr escribió a través del mount podían gastarse todo el presupuesto. Cada .nfo y póster después de eso era rechazado como si el árbol estuviera lleno. Subir el presupuesto nunca ayudó. Un archivo más grande que `sidecar_max_mb` no puede haber llegado por la ruta de sidecars de zurg. Esos archivos ya no cuentan contra el presupuesto. zurg los menciona una vez al arrancar porque igual ocupan espacio en disco.

Borrar una ruta de `__magic__` que ya no existe ahora se completa sin error. El mount puede quitar un sidecar compartido desde sus dos lados sin romper la limpieza de una importación.

## Una reproducción desde Stremio prueba el siguiente release cuando el primero ha caducado {#a-stremio-play-tries-the-next-release-when-the-first-has-aged-off}

Antes, un clic en Stremio significaba una sola release. Si esa release no tenía nada reproducible, la reproducción fallaba con un 404. La causa habitual es un post que ya ha caducado en el servidor de noticias. La lista de streams podía mostrar una docena de otras releases.

Ahora, si una reproducción es rechazada, se prueban hasta dos releases más de la misma lista ordenada. Empieza después de la fila que elegiste. Así, el respaldo tiene la misma resolución y un tamaño menor, o el nivel inferior. Nunca es una release más grande que hayas dejado pasar. Una release que todavía se está descargando responde 503 como antes, y pulsar reproducir de nuevo la recoge. Cada intento gasta una petición al indexador y deja esa release en la biblioteca. Los enlaces de reproducción creados antes de este cambio funcionan como siempre.

## Las listas de Stremio muestran todas las resoluciones y una variedad de tamaños {#stremio-lists-show-every-resolution-and-a-spread-of-sizes}

La limitación de la lista de streams antes contaba en toda la lista. Los resultados en 4K se ordenan primero, y un título popular tiene más de ellos que el límite. La lista podía llenarse con remuxes de 20 a 40 GB y ocultar todas las versiones 1080p y 720p que la búsqueda había encontrado. Ahora `stremio.max_results` cuenta por resolución y su valor por defecto es 5. Si tú pones un valor a mano, se mantiene ese número y ahora se aplica a cada resolución.

Dentro de una resolución, la lista antes solo conservaba las versiones más grandes. Lo que se cortaba era el encode de 4 GB que un teléfono o un portátil sí podían reproducir. Ahora cada resolución conserva selecciones repartidas de forma uniforme, desde la versión más grande hasta la más pequeña. Los dos extremos siempre se incluyen.

La descripción de cada stream ahora termina con el tiempo que hace que se publicó la versión. Aparece como `3d`, `126d` o `2y`. La antigüedad es la mejor pista de que una publicación puede haber desaparecido del servidor de noticias. Los resultados guardados en caché antes de este cambio no muestran antigüedad hasta que se actualiza la caché de ese título.

El manifiesto del addon ahora muestra la versión real de la compilación en lugar de `0.1.0`. `zurg --version` muestra los mismos datos de compilación que `zurg version` y no necesita un archivo de configuración.

## Los releases sanos dejan de desaparecer de la biblioteca {#healthy-releases-stop-disappearing-from-the-library}

A failed connection or DNS lookup at the Real-Debrid API now marks the account temporarily unavailable. It used to mark healthy files broken. They then sat waiting for repair after the network came back.

La falla de conexión o de búsqueda DNS en la API de Real-Debrid ahora marca la cuenta como temporalmente no disponible. Antes marcaba como rotos archivos que estaban sanos. Esos archivos se quedaban esperando una reparación incluso después de que la red volvía.

Cleanup after a library refresh used to wait behind background media analysis. By the time it ran a newer refresh could have added a release back. The late cleanup then removed it again. Cleanup now finishes before a refresh returns. Media analysis still runs in the background.

La limpieza tras una actualización de la biblioteca antes esperaba a que terminara el análisis de medios en segundo plano. Para cuando por fin se ejecutaba, una actualización más reciente podía haber vuelto a añadir un release. Entonces la limpieza tardía lo eliminaba otra vez. Ahora la limpieza termina antes de que la actualización devuelva el control. El análisis de medios sigue ejecutándose en segundo plano.

## Kodi puede explorar el recurso compartido WebDAV {#kodi-can-browse-the-webdav-share}

WebDAV ahora muestra la ruta completa de cada carpeta y archivo con el prefijo `/dav/` incluido. Kodi y otros reproductores estrictos solían quitar ese prefijo y no podían abrir carpetas ni contenido multimedia. Los nombres con caracteres escapados y las rutas dentro de archivos comprimidos mantienen sus direcciones.

## Un servidor de noticias ocupado ya no deja huecos en un stream {#a-busy-news-server-no-longer-puts-holes-in-a-stream}

Un servidor de noticias puede responder "no such article" para un artículo que sí tiene mientras está ocupado. zurg solía confirmar esa respuesta unos cientos de milisegundos después en la misma conexión. Luego servía el tramo como ceros y daba el artículo por perdido durante un día. Una lectura de 32 MiB devolvió 384,000 bytes en cero de un artículo que el servidor sirvió bien un minuto después.

Ahora, un artículo rechazado se vuelve a consultar una vez más, un segundo después. La segunda consulta va por otra conexión, donde haya una libre. La lectura espera esa respuesta en vez de rellenar el hueco. Un artículo que de verdad ya no existe sigue sirviéndose como silencio y se repara igual que antes. Por eso, una release dañada tarda alrededor de un segundo más en llegar a ese silencio.

Un artículo cuya conexión se queda en silencio también se vuelve a pedir una vez, por otra conexión. Antes hacía fallar toda la respuesta. Un stream de RAR devolvía 500 por un artículo que el proveedor solo tardaba en enviar.

## Elige cómo se identifica zurg ante los servicios a los que llama {#choose-how-zurg-identifies-itself-to-the-services-it-calls}

Las peticiones a servicios de debrid e indexadores ahora usan un User-Agent genérico de navegador por defecto. Las búsquedas de subtítulos también lo usan y ya no envían `zurg v0`. Esas peticiones tampoco envían las cabeceras origin y referrer, ni las propias de zurg. Esto se mantiene a través de las redirecciones. Una redirección no puede filtrar la ruta privada ni la clave de API de la URL anterior.

`user_agent` define otro agente, y `omit_user_agent` hace que no se envíe ninguno. Las claves `outbound_*` definen los nombres de cliente y de dispositivo que ven Plex, Jellyfin y Emby. Todas están en el panel, en Network & Connectivity, y se aplican tras reiniciar. Las conexiones de Usenet no envían ningún identificador de software. Esto elimina los identificadores propios de zurg. No te hace anónimo.

Los detalles están en [Identidad saliente](outbound-identity.md).

## zurg vacía la papelera de Plex por defecto {#zurg-empties-the-plex-trash-by-default}

zurg desactiva la opción de Plex "Empty trash automatically after every scan". Si no, un escaneo que se encuentra con un montaje que no se puede leer por un momento borra la biblioteca en lugar de dejarla en espera. Lo que quedaba atrás pasaba desapercibido. Plex ya no recogía las entradas muertas, y la eliminación propia de zurg era opcional. Así que por defecto nadie las recogía. Las entradas cuyos archivos hacía tiempo que no existían se acumulaban. El caso más visible era un archivo movido entre carpetas de la biblioteca, cuya entrada antigua se quedaba para siempre.

Si `plex_trash_sweep_every_mins` no está definido, la limpieza de la papelera ahora se ejecuta cada 60 minutos. No actúa cuando Plex todavía está vaciando su propia papelera. Elimina una entrada cada vez y nunca una que todavía tenga un archivo. Solo se ejecuta contra un montaje que se puede leer. Lo que no puede evaluar se mantiene visible como roto durante 14 días antes. Escribe `plex_trash_sweep_every_mins: 0` para dejar la eliminación desactivada y vaciar tú la papelera.

Esa opción no devuelve el vaciado de la papelera a Plex. La página de configuración ahora tiene un interruptor Let Plex Empty Its Own Trash para eso. El riesgo que conlleva está escrito junto a él.

Restaurar también funciona ahora. Plex omite un escaneo normal de una carpeta que ya ha escaneado. Una serie en la papelera cuyos archivos ya habían vuelto podía seguir en la papelera escaneo tras escaneo. La limpieza ahora pide a Plex un escaneo forzado de esa carpeta. Un escaneo iniciado a mano desde el panel también llega a las rutas `__magic__` desde las que se indexa una biblioteca de Usenet. Antes no encontraba ninguna sección de Plex y no hacía nada.

Cómo se reparten el trabajo los dos recolectores está explicado en [Plex](../guides/plex.md#who-empties-the-trash).

## Los archivos comprimidos dañados muestran los bytes correctos o no muestran nada {#damaged-archives-list-the-right-bytes-or-nothing-at-all}

Algunos conjuntos RAR dañados mostraban un vídeo que reproducía los bytes equivocados. Un conjunto al que le faltaba un volumen del medio servía el resto del archivo desplazado y con una cola de ceros. Ahora ese conjunto se rechaza. Un conjunto cuya primera cabecera no se podía leer tenía los bytes posteriores desplazados. zurg ahora lee primero las cabeceras de continuación para que cada desplazamiento sea correcto. Los archivos que hay después de la película en el último volumen también se conservan. Un marcador de fin RAR4 se confundía con cifrado. Los conjuntos divididos con bloques de fin con relleno perdían su primer volumen. Ahora muestran el vídeo completo.

Un NZB con un 10 % o más de sus artículos faltantes se rechaza antes de servir nada. El contenido que PAR2 ya ha reconstruido sigue reproduciéndose.

Las listas de archivos existentes se reconstruyen para que estas correcciones lleguen también a los lanzamientos que ya están en la biblioteca.

## Las bibliotecas grandes pueden devolver la memoria ociosa {#large-libraries-can-give-idle-memory-back}

`library_detail` decide si la lista de archivos de cada release se mantiene en memoria. `resident` las mantiene todas y sigue siendo el valor por defecto. `lazy` libera las listas de archivos que nadie ha leído durante `library_detail_idle_secs`. Los listados siguen disponibles y una lista de archivos vuelve a cargarse desde el disco cuando algo la lee. `auto` hace lo mismo, pero solo cuando hay presión de memoria sostenida en el host o en el contenedor. Los packs de temporadas grandes ocupan bastante menos memoria en cualquiera de los dos modos. Una copia de recuperación comprimida protege una lista de archivos si su caché en disco se daña. Los cambios sin guardar nunca se liberan. El dashboard ofrece los tres modos. Para aplicar un cambio hace falta reiniciar.

El arranque también usa menos memoria si tienes un historial de descargas de Real-Debrid grande. Guardar y cargar ese historial y las cachés de la biblioteca ya no crea copias adicionales.

Los compromisos están explicados en [la referencia de configuración](config.md#library-detail).

## La watchlist de Plex y las solicitudes de Seerr comparten una sola cola {#plex-watchlist-and-seerr-requests-share-one-queue}

El bloque `acquisition:` envía los elementos de la watchlist de Plex y las solicitudes de Seerr a una misma cola. Ambos se buscan en tus indexadores Newznab y terminan en el backend de Usenet. Las solicitudes de Seerr solo se siguen una vez aprobadas. Solo se descargan las temporadas solicitadas. Una solicitud en 4K se mantiene separada de una en 1080p. Las solicitudes de Seerr abiertas se vuelven a comprobar para buscar episodios recién emitidos.

El progreso ahora sobrevive a un reinicio. Esto incluye los plazos de reintento, el número de intentos y los episodios que ya están listos. Una adquisición interrumpida continúa donde se quedó. Una que ya terminó solo reintenta quitar el elemento de la watchlist y no vuelve a buscar. El estado guardado forma parte de las copias de seguridad normales. Los ajustes existentes de `watchlist:` siguen funcionando sin cambios.

La configuración está en [Adquisición](../guides/acquisition.md).

## Las bibliotecas de debrid pueden vivir en archivos locales portátiles {#debrid-libraries-can-live-in-portable-local-files}

Una cuenta de debrid ahora puede tomar su biblioteca de una carpeta con archivos `.zurgtorrent` en lugar de hacerlo desde la lista propia de la cuenta. `zurg export-torrents` escribe una biblioteca existente como esos archivos. Describen el contenido y no incluyen credenciales ni enlaces de descarga. Así, una biblioteca se puede compartir. La persona que la recibe reproduce a través de su propia cuenta y los límites de su proveedor siguen aplicando. Importar, listar y actualizar los archivos no añade nada a la cuenta.

Las configuraciones existentes siguen funcionando. Las copias de seguridad nuevas usan el formato 2 y necesitan esta versión o una más reciente para restaurarse.

La exportación y la configuración están en [Bibliotecas locales](../guides/local-libraries.md).

## Las cachés de lectura sobreviven a un reinicio {#read-caches-survive-a-restart}

zurg ahora mantiene sus cachés de lectura en disco entre reinicios. Eso incluye los NZB analizados y los artículos de Usenet decodificados. También incluye las estructuras de los archivos comprimidos, los bloques decodificados de esos archivos y los enlaces de descarga. Después de un reinicio, zurg no tiene que analizar cada NZB ni volver a leer la cabecera de cada archivo comprimido. Cada caché de bytes tiene un límite de 512 MiB por defecto. `zurg backup --include-caches` las añade a una copia de seguridad para un arranque en caliente.

Las peticiones para el mismo archivo de AllDebrid o TorBox hechas en el mismo momento ahora comparten una sola consulta de enlace.

Los ajustes y los límites están en [Persistent caches](../internals/persistent-caches.md).

## Las descargas de Usenet se revisan con más atención antes de marcarse como Completed {#usenet-grabs-are-checked-more-closely-before-they-read-completed}

Antes de que una descarga pase a Completed, zurg le pregunta al servidor de noticias por los primeros dieciséis artículos y el último artículo de cada archivo de contenido. Antes solo comprobaba el primero. Eso dejaba pasar huecos en la cabecera del medio. Las comprobaciones salen en un único lote por archivo, así que los archivos grandes ya no se quedan sin tiempo.

Un release cuyos artículos faltantes ha reconstruido por completo PAR2 ahora se importa. Antes fallaba porque los artículos originales seguían sin estar en el servidor. Una reparación parcial sigue sin contar.

`sabnzbd.history_limit` ahora puede coincidir con un límite de historial más alto en Sonarr o Radarr. Así, una gran acumulación de trabajos terminados se vacía en lotes más grandes. Ambos extremos deben usar el mismo número. El valor por defecto sigue siendo sesenta.

## `enforce` deja tranquilas las funciones de Plex que puedes ver {#enforce-leaves-the-plex-features-you-can-see-alone}

`plex_settings_policy: enforce` ya no desactiva las miniaturas de vista previa al hacer scrubbing ni las imágenes de capítulos. Tampoco desactiva la nivelación de volumen ni el análisis sónico. Cada una de estas funciones decodifica archivos completos, y eso consume ancho de banda en un montaje de debrid. Además, cada una te da algo que puedes ver. Ahora quedan al mismo nivel que Skip Intro y Skip Credits, como una cuestión de gusto. zurg sigue informando de lo que cuesta cada una. Solo que ya no decide por ti. El grupo de ancho de banda ahora solo incluye el análisis cuya salida nadie mira.

## Los enlaces de debrid caducados se recuperan sin que falle la reproducción {#expired-debrid-links-recover-without-failing-playback}

A un enlace de TorBox cuyo token firmado ha caducado ahora se le genera uno nuevo. Los lectores que esperan el mismo archivo comparten esa única consulta. Los fallos repetidos pausan la reproducción sin marcar el archivo como roto.

Cuando un servidor de descarga de TorBox, Real-Debrid o AllDebrid le pide a zurg que espere, ahora espera todo el tiempo que le indican. También deja de reintentar un servidor que sigue rechazando las peticiones. Esto vale para la reproducción, las comprobaciones de enlaces y las lecturas de archivos comprimidos. Un enlace revocado abierto a través de `__downloads__` también recibe uno nuevo.

## zurg se actualiza solo {#zurg-updates-itself}

`zurg update` reemplaza el binario en ejecución por la nightly de sponsor más reciente. Lee el feed de releases con la sesión de la GitHub CLI si existe, y si no, con `GITHUB_TOKEN` o `GH_TOKEN`. Comprueba que las descargas se ejecutan y que reporta la versión esperada antes de reemplazar nada, y cambia el binario por rename, así que una actualización no puede fallar mientras zurg está corriendo. Si una build ya está en la nightly más reciente, o es más nueva, se deja como está. Dentro de un contenedor el comando se niega y te indica hacer pull de la imagen en su lugar, porque un binario reemplazado ahí se pierde en el próximo recreate; `--force` lo salta. Los instaladores ganaron un modo `update` equivalente para builds demasiado antiguas como para tener el comando.

Por plataforma: [Linux](../setup/linux.md#updating-zurg), [macOS](../setup/macos.md#update-zurg), [Windows](../setup/windows.md#updating-zurg), [Docker](../setup/docker.md).

## Una opción de Plex puede excluirse de la política {#one-plex-setting-can-be-opted-out-of-the-policy}

`plex_settings_ignore` indica a Plex las preferencias que zurg no toca, sin importar lo que diga `plex_settings_policy`. Existe para la configuración que de verdad necesita cambiar una de ellas: una biblioteca cuyos archivos se mueven entre carpetas depende de que Plex vacíe su propia papelera para borrar la entrada que queda, y la política por defecto lo desactiva. Pasar a `warn` para recuperarlo también te quitaría las protecciones de eventos del sistema de archivos que están junto a él. Una preferencia ignorada se sigue leyendo y reportando, en el panel y como `skip` en `zurg plex-settings`; lo único que no pasa es que se escriba, que se avise sobre ella o que aparezca detrás del banner de la papelera. Ignorar una preferencia de seguridad es bajo tu propia responsabilidad, y zurg te lo recuerda una vez al arrancar. Un id que no corresponde a ninguna preferencia se reporta y la preferencia sigue protegida, así que un error de escritura no puede interpretarse como una exclusión voluntaria.

La lista de preferencias, y lo que hace cada nivel de política con ellas, está en [Plex](../guides/plex.md#recommended-plex-settings).

## Instaladores de una sola línea para cada host compatible {#one-line-installers-for-every-supported-host}

Las instalaciones nuevas ahora tienen bootstraps opcionales de una sola línea para Linux, macOS, Windows y Docker en Linux. Comprueban o instalan los requisitos previos de cada plataforma, usan el inicio de sesión en el navegador de GitHub para el acceso de patrocinador, descargan la arquitectura correcta y luego pasan el control a `zurg setup` y `zurg doctor`. Los binarios y configuraciones existentes se conservan, y todas las guías manuales siguen disponibles.

## La configuración pregunta qué proveedores quieres configurar {#setup-asks-which-providers-to-configure}

Las instalaciones nuevas de `zurg setup` ya no asumen Real-Debrid. El instalador interactivo te pide uno o varios proveedores en orden de prioridad y solo recoge las credenciales de los que hayas seleccionado. Las instalaciones no interactivas pueden repetir `--provider` y usar las opciones de archivo de token específicas de cada proveedor o variables de entorno. Las configuraciones existentes se siguen conservando, y las entradas heredadas de Real-Debrid (`--token-file`, `TOKEN` y `RD_TOKEN`) siguen siendo compatibles cuando se indican explícitamente.

## Una ráfaga mayor que la ventana de historial de Sonarr ya no pierde importaciones {#a-burst-larger-than-sonarrs-history-window-no-longer-loses-imports}

Sonarr y Radarr le piden a SABnzbd todos los trabajos en cola, pero solo los sesenta más recientes del historial. Eso suele describir bien a un downloader real: las descargas terminan poco a poco y el cliente elimina cada una después de importarla. Una biblioteca de NZB en caché es diferente. Una búsqueda masiva de temporada puede terminar cientos de trabajos de episodios individuales antes del siguiente sondeo del cliente, y zurg antes eliminaba todos ellos de la cola mientras solo devolvía sesenta en el historial. Cada trabajo más allá de esa página quedaba fuera de ambas respuestas, así que el cliente nunca lo importaba ni lo marcaba como fallido, y su release se quedaba en la raíz de `__magic__` indefinidamente.

zurg ahora mantiene los trabajos terminados más allá de esa página visible en la cola. A medida que el cliente importa y elimina los primeros sesenta, los siguientes completados pasan al historial. Una temporada agregada como episodios individuales se vacía así en lotes acotados, en lugar de competir con una ventana de tamaño fijo; un pack de temporada sigue comportándose como un solo trabajo.

## Un borrado a través del montaje siempre funciona, y `dav_allow_delete` ya no existe {#a-delete-through-the-mount-always-works-and-dav_allow_delete-is-gone}

Borrar un archivo desde un servidor multimedia apuntando al mount solía no hacer nada visible: zurg rechazaba el DELETE de WebDAV con un 403, rclone lo convertía en un error de I/O, y el cliente informaba de un fallo sin causa asociada. Plex responde un simple `400 Bad Request` y no registra nada, así que el botón simplemente no funcionaba y nada decía por qué.

La clave que lo permitía, `dav_allow_delete`, se ha eliminado. Ahora un DELETE a través del mount se acepta en todas partes, sin configuración. Un archivo de configuración que todavía define la clave no es un error (las claves desconocidas se ignoran), simplemente ya no hace nada.

Lo que protegía la clave no ha desaparecido, así que conviene dejarlo claro: rclone no tiene forma de expresar "sobrescribir" y vacía un archivo reescrito como un DELETE seguido de un PUT. Eso significa que un programa que reescribe un archivo en su sitio (un escritor de `.nfo`, un proceso de trickplay, un renombrado de \*arr o un `touch` suelto) borra el release de tu cuenta de debrid en lugar de reemplazar un archivo. Además, el mount usa las credenciales propias de rclone, así que nada aguas arriba puede distinguirlo de un borrado deliberado. La mitad PUT sigue siendo rechazada, y eso es lo que evita que la secuencia se complete en silencio. Si algo escribe en tu mount, define `mount_read_only: true`, que hace fallar la escritura en el kernel antes de que llegue a zurg.

## La watchlist de Plex busca con tus indexadores Newznab {#the-plex-watchlist-acquires-through-your-newznab-indexers}

El monitor de watchlist ya funciona, y funciona con tus propios indexadores. La versión anterior buscaba usando una API key de DMM y dejó de funcionar sin avisar cuando Plex movió la watchlist a su host de descubrimiento, porque el endpoint que consultaba empezó a responder 404. Ahora consulta el host correcto, y cada elemento nuevo de la watchlist se busca en los indexadores Newznab que ya tienes configurados: una película se convierte en la mejor versión que coincida, y una serie se adquiere temporada a temporada **dando prioridad a los packs de temporada** frente a los episodios sueltos. Si ninguna temporada tiene pack publicado, se recurre a los episodios sueltos, con la mejor versión de cada episodio. Si el enlace NZB de la versión elegida no se puede descargar (por ejemplo, por un 429 por límite de ráfagas del indexador), se pasa al siguiente candidato según el ranking, en lugar de dar por perdido el elemento. El NZB elegido se envía al backend de Usenet con las mismas reglas de nombrado que el endpoint de SABnzbd y el addon de Stremio, así que los tres componentes detectan las descargas de los demás en lugar de duplicarlas. Un elemento solo sale de la watchlist después de que se haya adquirido algo de verdad. El orden anterior borraba primero y preguntaba después, así que cualquier fallo eliminaba el elemento de tu lista en silencio.

Configúralo con el nuevo bloque `watchlist:`: `enabled`, `check_every_secs` (por defecto 60), `indexers` (si está vacío, toma `stremio.indexers`), `max_size_gb` (por defecto 40, para películas y episodios sueltos), `max_season_size_gb` (por defecto 100, para packs de temporada) y `quality` (`best`, `4k`, `1080p`, `720p`, `smallest`). Las claves heredadas `plex_watchlist_*` mantienen su significado. Con un `plex_token` basta para usar Plex: el monitor se comunica con el servicio en la nube de Plex, así que funciona sin problemas en una instancia sin `plex_server_url`. Las búsquedas de series empiezan con el id de TVDB y, si no encuentran nada, reintentan una vez con el id de IMDb. Los indexadores indexan las series por TVDB, y su mapeo de IMDb a nivel de serie es tan irregular que una serie muy indexada puede devolver cero resultados en una búsqueda por imdbid.

Todas las claves están en la página de configuración, bajo **Plex Watchlist**, y en [la referencia de configuración](config.md#watchlist).

## Un addon de Stremio sobre tus indexadores Newznab {#a-stremio-addon-over-your-newznab-indexers}

zurg ya puede responder directamente a Stremio. Activa el bloque `stremio:`, enumera tus indexadores Newznab y pega en Stremio la URL `/stremio/<token>/manifest.json` que aparece en el log. Cuando el cliente pide streams por id de IMDb, zurg busca en los indexadores (películas con `t=movie`, episodios con `t=tvsearch` con temporada y episodio) y devuelve los resultados ordenados primero por resolución, como streams reproducibles. Al elegir uno, zurg descarga el NZB al backend de Usenet siguiendo las mismas reglas de nombres que el endpoint de SABnzbd, así que un release descargado dos veces se encuentra en lugar de duplicarse. Después lo reproduce a través del endpoint firmado `/strm/e/`, con rangos, failover y el contenido de los archivos comprimidos incluidos. Todo lo que se reproduce acaba en la biblioteca, así que aparece en Plex como cualquier otro release.

El token de la ruta es toda la autorización. Se genera y se guarda en `data/stremio-token` si la configuración no define ninguno. Los resultados de búsqueda se guardan en caché en `data/stremio-cache`, así que volver a abrir un título no consume llamadas a los indexadores. La duración de la caché depende de cuántos resultados encontró la búsqueda: una hora por resultado hasta cuatro, y `stremio.cache_hours` (por defecto 24) a partir de cinco. Una respuesta vacía nunca se guarda. Una lista de streams en caché incluye un elemento de actualización que borra la caché de ese título. Los releases más grandes que `stremio.max_size_gb` (por defecto 40) se quitan de la lista, para que un remux de disco completo no quede por encima de todas las opciones reproducibles.

Todo el proceso, incluido el coste de la primera reproducción, está en: [El addon de Stremio](../guides/stremio.md).

## Una sola carpeta es toda la instalación de Docker, y se monta en el primer arranque {#one-folder-is-the-whole-docker-install-and-it-mounts-on-the-first-run}

El método documentado para iniciar zurg en Docker era un solo `docker run` con un `TOKEN`, y producía un contenedor que no montaba nada. La configuración generada dejaba `rclone_enabled` desactivado y `mount_path` sin definir, así que `/zurg_mnt/zurg` seguía vacío hasta que alguien encontraba los dos controles en el Dashboard. Además, esa configuración se escribía dentro del contenedor, así que el siguiente `docker pull` la borraba junto con la caché de la biblioteca. La guía rápida necesitaba una nota al pie que enumerara ambos pasos, y eso es una guía rápida admitiendo que no funciona.

Ahora `MOUNT_PATH` escribe `rclone_enabled: true` y `mount_path` en la configuración durante la ejecución que la crea, junto a lo que `TOKEN` ya escribía. El directorio de trabajo de la imagen es `/config`, y todo lo que zurg guarda se resuelve a partir de ahí: `config.yml`, `data/`, `logs/`, `dump/`, `strm/`, `nzbs/` y la caché de rclone. Por eso, con un solo `-v ~/zurg:/config` tienes toda la instalación, y una actualización de la imagen no mueve nada. Una primera ejecución es un solo comando y termina con una biblioteca montada, en lugar de un trámite en el Dashboard.

Ambas variables se leen **solo cuando todavía no existe ningún archivo de configuración**, y se ignoran a partir de ahí. Es la misma regla que ya tiene `log_level` con `LOG_LEVEL`, por la misma razón: un `MOUNT_PATH` olvidado en un archivo de Compose nunca debe deshacer en silencio una ruta de montaje que cambiaste después en el Dashboard. Ahora, al arrancar, zurg avisa si una de estas variables está definida y no coincide con la configuración, para que quien vuelva a desplegar y vea que no pasa nada sepa por qué.

Las instalaciones hechas con el diseño antiguo no se tocan. Docker crea el destino de cada montaje de enlace, así que si existen `/app/config.yml`, `/app/data` o `/app/logs`, eso indica que es el diseño antiguo, y el contenedor sigue usando `/app` cuando detecta cualquiera de ellos. La configuración completa, y lo que rompe un montaje visible desde el host, está en [Docker](../setup/docker.md).

## TorBox y AllDebrid también reciben el `.torrent`, así que una descarga privada no se queda colgada {#torbox-and-alldebrid-are-handed-the-torrent-too-so-a-private-grab-is-not-left-hanging}

El archivo `.torrent` que envía un \*arr empezó a viajar con el add en la última versión, pero solo Real-Debrid podía aceptarlo. Las otras dos cuentas seguían recibiendo únicamente el info hash, que para el release de un tracker privado es la única forma que no pueden usar. No falló nada, y eso es lo que lo hizo difícil de ver: al probarlo contra la cuenta real de TorBox, un hash sin swarm público se aceptaba con un id de torrent y luego se quedaba en `checking` con `size: -1`, sin lista de archivos y con una estimación de cien días. Era exactamente lo que se reportaba de una descarga de TorrentLeech que "se queda colgada, no baja nada". El mismo release, con su archivo, recibía respuesta al instante con su nombre real, su tamaño real y su lista de archivos, y el endpoint de qBittorrent podía seguir con el trabajo.

Ahora las dos cuentas aceptan el archivo. El `createtorrent` de TorBox y el `magnet/upload/file` de AllDebrid lo aceptan en lugar del magnet y responden con la misma forma que ya usaba el add con magnet, así que nada después del add cambia. AllDebrid sigue informando sobre la propia subida si el contenido ya estaba en su sistema, que es la única respuesta de caché que da esa cuenta.

Lo verifiqué en vivo a través del propio add de zurg en ambas: un release en caché se subió y se leyó como `done` al 100% con su lista de archivos en cuestión de segundos, y uno que nadie tiene se leyó con nombre, tamaño y en estado stalled por falta de peers. Es un estado con el que el endpoint puede trabajar, mientras que el del hash era un torrent que nunca se resuelve ni termina.

Además, ahora un rechazo de TorBox se entiende mejor. Una llamada a TorBox rechazada con un 4xx llegaba al cliente como el mensaje genérico "unexpected status code: 400" del cliente HTTP compartido, porque se descartaba el cuerpo de la respuesta, que es donde TorBox pone su propio código de error y su detalle. Así, un `.torrent` que TorBox no quería procesar se reportaba al \*arr solo como un número de estado. Ahora se lee primero el cuerpo y el motivo que da la propia cuenta llega junto con el rechazo.

Para saber qué hacer al configurar los indexers: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## Las entradas de archivos comprimidos se transmiten, descodificadas bajo demanda {#compressed-archive-entries-stream-decoded-on-demand}

Una entrada RAR comprimida o zip con deflate no puede responder a una lectura por rangos como lo hace una almacenada: sus bytes solo existen detrás de un decodificador que tiene que ejecutarse desde el inicio de la entrada. Por eso zurg las rechazaba: una release solo comprimida respondía 415, y las entradas comprimidas hermanas de entradas almacenadas se saltaban. Era la respuesta honesta para un streamer, pero ocultaba la mayor parte del catálogo antiguo de Usenet: cada publicador que empaquetó con compresión, completo y entero.

Ahora estas entradas se sirven decodificando hacia adelante bajo demanda en una ventana acotada en memoria. No se escribe nada en disco y no se decodifica nada que ninguna lectura haya pedido. La reproducción secuencial, el patrón que genera un reproductor, llega al borde de la ventana y la avanza un poco en cada lectura. Un salto hacia atrás más allá de lo que la ventana conservó reinicia la decodificación desde el inicio de la entrada. Los bytes de la entrada completa son los que extraería unrar: un volumen RAR4 comprimido real con tres entradas jpg se decodifica byte a byte igual que el mismo fixture leído por una pasada independiente de otro decodificador, md5 por md5.

Recorrer los volúmenes de un set dividido necesitaba la cadena de volúmenes de rardecode, que abre `.part02.rar` desde el sistema de archivos. Los volúmenes de zurg están detrás de lectores de red por rangos. El decodificador ahora está incluido en `internal/rardecode` (MIT, upstream v1.1.3) con un solo cambio: `OpenReaderOver` recibe un opener, así que cada volumen siguiente se obtiene del set por el nombre que el propio archivo deriva. Los listados cambian de forma en consecuencia: una release solo comprimida presenta su contenido (`stream_compressed_archives: false` restaura los rechazos anteriores), y un archivo mixto lista sus hermanas comprimidas junto a las almacenadas. Versión de listado 15.

## Sonarr y Radarr pueden descargar torrents, y Prowlarr puede enviarlos {#sonarr-and-radarr-can-grab-torrents-and-prowlarr-can-push-them}

zurg puede responder a los \*arrs como si fuera un qBittorrent. Le envían un magnet o un `.torrent`, zurg añade el info hash a una cuenta de debrid (Real-Debrid, TorBox o AllDebrid, la que tengas configurada) y, cuando el lanzamiento ya está en la biblioteca, el torrent aparece como terminado, con una carpeta dentro de `__magic__` desde la que importar. La importación es el mismo renombrado que el endpoint de SABnzbd siempre ha usado para los envíos de Usenet: una fila en la tabla `__magic__`, sin mover ningún byte.

El endpoint se registra en `/api/v2` y `/qbittorrent/api/v2`. Está desactivado hasta que lo actives, y se protege con una clave de API que los clientes envían como token bearer. Un envío se ofrece a todas las cuentas que aceptan torrents, en el orden de `providers:`. Si una descarga deja de avanzar (sin cambio de etapa ni subida de progreso durante `qbittorrent.download_timeout_mins` minutos, quince por defecto), se quita de esa cuenta y se prueba en la siguiente. Con `0`, solo se aceptan los contenidos que la cuenta ya tiene en caché, y el resto se rechaza al añadirlo. Es el único rechazo al que reaccionan los \*arrs. Lo que hace la cuenta con una descarga se traduce a los estados que entienden los clientes, mostrando la velocidad, el swarm y el tiempo restante cuando la cuenta los informa.

Una limitación que conviene conocer: la API de qBittorrent no tiene forma de indicar que una descarga ha fallado. Por eso, un lanzamiento que ninguna cuenta acepta llega al cliente como una advertencia y no como una entrada en la lista de bloqueo. Aparece en la cola con el motivo, pero nunca se vuelve a pedir de forma desatendida. El endpoint de SABnzbd no tiene este problema.

Prowlarr usa el mismo endpoint como si fuera un cliente de descargas: envía un lanzamiento a la cuenta manualmente. Tras un envío desde Prowlarr no se importa nada, para eso están los \*arrs.

Guía completa, capturada con una instalación en vivo: [Sonarr y Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## `__magic__`, un directorio que puedes organizar {#__magic__-a-directory-you-can-organise}

Cada directorio que sirve zurg es un filtro guardado. Un lanzamiento está en `movies` porque coincide con el filtro de películas, y a la vez está en `__all__`, en `recent` y en `movies`. Por eso nunca ha habido un sitio en la biblioteca donde *poner* algo. Hasta que un programa quiere mover un archivo, eso no supone un problema. Radarr y Sonarr importan moviendo, y un montaje que no puede recibir un movimiento les obliga a copiar: cada importación descarga todo el lanzamiento desde el host de debrid o desde Usenet, justo lo que el montaje existe para evitar.

`__magic__` es un nuevo directorio de primer nivel que empieza como una copia exacta de `__all__`. Tiene cada lanzamiento como carpeta, con exactamente lo que contiene `__all__/<release>/`, incluido el contenido de un archivo virtualizado. Dentro de él se puede mover cualquier cosa a cualquier sitio. Ejecuta `mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01` y usa `mv` para meter un episodio en esa carpeta: el episodio aparece ahí, sin mover bytes, sin renombrar ningún torrent, sin volver a descargar nada, y `__all__` sigue igual. Un movimiento solo reescribe una fila de una tabla pequeña. Esa tabla usa como clave el hash de contenido del lanzamiento y la ruta propia del archivo dentro de él, así que una reparación que vuelve a añadir el lanzamiento y reconstruye todos los ids a su alrededor no pierde dónde dejaste las cosas. Tampoco se pierde si renombras un lanzamiento desde el panel.

Los movimientos funcionan en los dos sentidos. Un archivo se puede mover *dentro* de una carpeta de lanzamiento y también sacarlo de ella. La carpeta lista ese archivo junto a las entradas propias del lanzamiento. Es lo que necesita un programa que devuelve algo a la carpeta desde la que está importando. Si un nombre llega desde dos sitios a la vez, gana el que colocaste a propósito: lo que moviste gana a lo que el lanzamiento llama así, y eso gana a un archivo que esté en `data/local`. El perdedor no se lista, en vez de listarse dos veces.

Borrar es la otra mitad, y por defecto oculta en lugar de destruir. Un `rm` dentro de `__magic__` saca la entrada de `__magic__` y la deja en `__all__` y en todos los directorios de filtros. Así, un cliente que reorganiza una biblioteca no puede perder nada. Una carpeta de lanzamiento puede desaparecer de la misma forma, y eso es lo que permite a Sonarr borrar la carpeta del trabajo después de importar sin tocar el lanzamiento del que acaba de importar. `magic.allow_delete: true` activa el significado más fuerte para los archivos, donde el contenido también se va. Una carpeta de lanzamiento o un directorio solo se oculta, independientemente de ese valor.

Está desactivado por defecto, porque es un árbol escribible y un \*arr apuntado a la carpeta raíz equivocada puede reorganizar una biblioteca:

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

Las dos claves `sidecar_` son para clientes que montan `/dav` directamente en lugar de usar el montaje propio de zurg. Esos clientes envían a zurg un `PUT` de un nuevo `.nfo`, un póster o una pista de subtítulos, y ahora zurg escribe el cuerpo en `data/local/__magic__/…`. Es el mismo árbol donde el montaje propio de zurg ya guarda esos archivos. Así las dos vistas muestran un solo directorio en vez de dos, y el archivo se puede leer con rangos, longitud y fecha de modificación como cualquier otro. Los límites evitan que esto se convierta en un almacén de archivos general: un archivo de más de `sidecar_max_mb` se rechaza con 413, y uno que llevaría el árbol por encima de `sidecar_budget_mb` se rechaza con 507. No se puede escribir encima de nada de lo que la biblioteca responde: una carpeta de lanzamiento, una entrada de una de ellas o una ruta a la que se movió algo devuelve 403. Y un movimiento nunca destruye un archivo real para hacer sitio a una fila.

Hay dos cosas que conviene saber antes de apuntar algo a esto. Los directorios de filtros no se tocan a propósito, así que un lanzamiento movido dentro de `__magic__` sigue en `recent` y en `movies` con su nombre original. Apunta un servidor multimedia a `__magic__` **o** a los filtros, pero no a los dos. Y el montaje siempre ha sido escribible en una dirección: cualquier cosa realmente nueva que se escriba en él, como un `.nfo`, un subtítulo o un póster, acaba en el `data/local` propio de zurg y se fusiona en el listado. Por eso los sidecars junto a un lanzamiento funcionan sin más, y por eso la prueba de escritura de la carpeta raíz de un \*arr pasa.

`dav_allow_rename` y `dav_allow_delete` no tienen nada que ver con todo esto. Esas opciones protegen la ruta que renombra y borra lo que tiene la cuenta de debrid, y una escritura bajo `__magic__` no llega a ninguna cuenta. `mount_read_only: true` sigue anulándolo todo.

El panel tiene una página para esto, en `/magic/`. Muestra cada fila que guarda la tabla, agrupada por lanzamiento. Indica qué es cada una, de qué archivo de qué lanzamiento procede y desde dónde se sirve ahora ese archivo. También muestra cuántas filas hay, cuánto ocupan en disco el journal y la snapshot, y qué parte de `sidecar_budget_mb` usan los archivos reales junto a la biblioteca. Además informa del tamaño de todo `data/local`, que es el número que indica si algo se está importando copiando. Un cliente que copia en lugar de mover deja ahí los bytes, y ninguna otra parte del panel lo mostraría nunca.

Tres de los estados que muestra no se pueden alcanzar desde un cliente. Una colocación se puede **reset**, y el archivo vuelve a donde lo pone la biblioteca. Una lápida (tombstone) se puede **unhidden**, y la entrada vuelve a listarse. Una fila **dangling**, es decir, una cuyo lanzamiento o cuyo archivo dentro de él la biblioteca ya no tiene, se puede eliminar de una en una o todas a la vez. Esto es nuevo, porque hasta ahora no había dónde limpiarlas. Una fila así no resuelve a nada, así que ningún cliente la puede listar, mover o borrar. Se conserva a propósito en lugar de eliminarla, porque una reparación que devuelve el lanzamiento también devuelve la colocación. Los sidecars también aparecen en la lista, con la misma clasificación aplicada a ellos: un archivo real en una carpeta de la que ya nada se hace responsable se muestra como **orphaned** y se cuenta por separado. Por ejemplo, un `.nfo` junto a un lanzamiento que ya salió de la biblioteca, o dentro de una colocación que se ha olvidado. No se barre nada, por la misma razón por la que no se elimina una fila dangling: el archivo sigue siendo tuyo, y una reparación que devuelve el lanzamiento vuelve a asociar la carpeta. Borrar uno de esos archivos sí borra el archivo de verdad, igual que un `DELETE` a través del montaje. Cada uno de esos botones le indica al montaje que olvide los listados que cambió, porque guarda en caché cada directorio durante doce horas con el polling desactivado.

`magic:` y `sabnzbd:` ahora se pueden editar desde la página de configuración, y ambos están marcados como **Restart Required** porque es así de literal: las rutas que sirven `__magic__` y el endpoint de SABnzbd se deciden una sola vez, al arrancar, a partir exactamente de estos valores. Activar uno lo escribe en `config.yml`, pero no cambia nada de la ejecución que está respondiendo. Y la página de `__magic__` lo dice con todas sus letras, en lugar de mostrar un espacio de nombres vacío como si todo estuviera bien.

### Sonarr y Radarr ahora pueden entregarle a zurg un NZB {#sonarr-and-radarr-can-now-hand-zurg-an-nzb}

La razón de que exista `__magic__` es que un \*arr necesita un sitio desde el que importar, y zurg ahora ofrece la otra mitad: un endpoint en `/api` que responde a Sonarr y Radarr como si fuera un SABnzbd. Apúntalos al host y al puerto de zurg, pega la clave de API, y las descargas aterrizan en `nzbs/` para el backend de Usenet. Cuando la release está en la biblioteca, el trabajo aparece como Completed con una carpeta dentro de `__magic__`, y la importación es un renombrado dentro del mount: una fila en la tabla, sin leer bytes y sin bajar nada desde Usenet para meterlo en una carpeta de serie.

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

Viene desactivado por defecto y necesita las dos partes para ser útil: un proveedor `nzb` para leer el NZB, y `magic.enabled` para tener desde dónde importar. El endpoint no está detrás de la autenticación básica de zurg, porque ninguno de los dos \*arr envía nunca credenciales a un cliente de descargas, y su capa HTTP interpreta un 401 como "no se puede conectar". La clave de API es la única barrera, así que trata ese puerto en consecuencia. Las carpetas raíz van **dentro** de `__magic__` (`__magic__/tv`, `__magic__/movies`), nunca en él ni por encima, o la comprobación de salud de carpetas raíz de los clientes tendrá algo que decir.

Una cosa que conviene saber antes de pasar una biblioteca a este modo: **la señal de fallo es parcial**. Una release que la biblioteca tiene pero de la que no hay nada importable (todos los archivos rotos, borrados o filtrados, o nada más que scaffolding de reparación y sidecars, que es lo que pasa con un NZB que solo tiene volúmenes de recuperación) se reporta como `Failed`, y eso es lo que hace que ambos clientes la metan en la blocklist y busquen una alternativa. Un conjunto RAR cuenta como contenido, porque zurg transmite el vídeo directamente desde él, salvo que sea uno que zurg no puede transmitir en absoluto, con solo entradas comprimidas: en ese caso se reporta como Failed desde el momento en que algo lo ha abierto y ha descubierto eso. Ese veredicto se guarda con la release, porque averiguarlo cuesta leer cada volumen del conjunto. Lo que no se reporta es un post cuyos artículos han caducado en el servidor de noticias: zurg todavía no lo comprueba, así que una release muerta se reporta como Completed como cualquier otra y falla en la primera lectura, y Sonarr ve un fallo de importación en lugar de un fallo de descarga. Ese caso sigue siendo una decisión manual. Todo lo demás del flujo funciona, incluida la limpieza posterior a la importación: la carpeta del trabajo que Sonarr borra se convierte en un tombstone, y la release se queda en `__all__`.

Una descarga no espera al siguiente sondeo de cambios: zurg vuelve a leer el directorio de vigilancia en cuanto ha escrito algo en él, y solo en las cuentas de Usenet. Un season pack son veinte descargas en pocos segundos, y volver a listar una biblioteca de debrid de decenas de miles de torrents para notar un archivo local sería veinte veces el trabajo equivocado. Si no hay ningún proveedor `nzb` configurado, zurg ahora lo dice al arrancar, en lugar de aceptar descargas que nada va a leer nunca.

La página `__magic__` lista los trabajos, en solo lectura: el `nzo_id` con el que cada cliente conoce una descarga, su categoría, cuándo llegó, si la biblioteca ya muestra la release y, cuando lo hace, la carpeta desde la que el \*arr importa.

La configuración completa, incluido el mapeo de rutas remotas para \*arr en contenedores y el significado de cada error de la prueba de conexión, está en `docs/sabnzbd.md`.

## El montaje aprovecha más del ancho de banda disponible {#the-mount-reaches-more-of-the-bandwidth-it-has}

Leer un archivo a través del montaje de rclone iba más lento que descargar los mismos bytes por HTTP, y el motivo estaba en cómo empieza una lectura, no en cómo se desarrolla. El primer fragmento se pedía de 4 MB y se duplicaba a partir de ahí. Así, una lectura que empezaba en una posición fría pasaba la mayor parte del tiempo por debajo de la velocidad que la conexión podía sostener de verdad. Además, cada salto en la reproducción inicia una lectura nueva. Ahora el primer fragmento se pide de 32 MB.

Lo medí en un equipo con unos 70 MB/s de ancho de banda de descarga útil. Probé cada ajuste por turnos, para que un minuto lento no cayera solo en uno de ellos. La mediana del rendimiento del montaje en Real-Debrid subió de 49 a 57 MB/s, y TorBox mejoró de forma parecida. AllDebrid gana menos aquí porque su límite es por conexión y no por cuenta.

El tamaño del fragmento es todo el efecto. El read-ahead de FUSE se subió a la vez durante las pruebas y no cambió nada. Tampoco cuesta ancho de banda extra: el tamaño del fragmento es cuánto se *pide*, no cuánto se transfiere, y rclone deja de descargar cuando la reproducción se detiene. Una lectura de 4 MB seguía descargando 6 MB, igual que con el read-ahead desactivado por completo. Así que una biblioteca que se navega y se muestrea, en lugar de verse de principio a fin, no descarga más que antes.

No tienes que cambiar nada. El nuevo valor llega como predeterminado, y `rclone_extra_args` sigue pudiendo sobrescribirlo.

## `zurg benchmark-my-setup` indica qué tan rápida es realmente la configuración {#zurg-benchmark-my-setup-answers-how-fast-the-setup-actually-is}

Hasta ahora, la única forma de saber si un stream lento se debía a la cuenta, al host o al mount era adivinar. El nuevo comando lee bytes reales por el mismo camino que usa un reproductor y muestra la distribución (mínimo, mediana, media, máximo y tiempo hasta el primer byte) en lugar de una sola cifra que cualquier muestra desafortunada podría haber producido.

Se ejecuta en tres fases. La primera mide cada cuenta por separado, que es el número que hay que comparar con lo que promete el servicio. La segunda usa todas las cuentas configuradas al mismo tiempo, y es la única fase que puede distinguir un proveedor lento de un enlace saturado: si las cuentas sostienen 70 MiB/s cada una por separado pero solo 25 MiB/s juntas, hay un solo cuello de botella, no tres problemas, y el informe indica cuál de los dos casos es. La tercera fase hace la misma lectura a través del mount de rclone, donde la diferencia respecto a la primera fase es lo que cuestan FUSE y el VFS. La fase del mount se omite cuando `rclone_enabled` está desactivado.

Las muestras se colocan en desplazamientos aleatorios, y eso no es un detalle. Todas las capas de abajo usan caché: el VFS de rclone guarda lo que ya ha descargado, y un nodo de CDN del debrid guarda lo que ya ha servido. Por eso, volver a leer el mismo desplazamiento mide esas cachés en lugar del enlace. En una instalación real, el mismo archivo dio 47 MiB/s en la primera lectura y 285 MiB/s en la segunda lectura de la misma región.

El tamaño de la muestra cambia lo que significa la cifra del mount, así que el informe lo indica. rclone abre un archivo con `vfs_read_chunk_size` y lo va duplicando a partir de ahí, así que una muestra corta pasa la mayor parte del tiempo todavía en esa fase de arranque. Medido en una misma instalación: 47 MiB/s con una muestra de 256 MiB frente a 88 MiB/s con 1 GiB, mientras que HTTP se mantiene en torno a 70 en ambos casos. El valor por defecto de 128 MiB corresponde a la cifra de búsqueda y scrubbing; `--sample-mb 1024` da el techo sostenido. Ninguna de las dos está mal, y la ejecución te indica cuál de las dos has medido.

`-n` define las iteraciones, `--provider` limita la ejecución a las cuentas que indiques, `--skip-mount` y `--skip-concurrent` omiten una fase, y `--json` emite el informe para usarlo en scripts. El comando consume ancho de banda real de tus propias cuentas: iteraciones x tamaño de muestra por cuenta, dos veces, más la fase del mount. Ejecútalo desde el directorio de zurg, porque el backend de NZB lee su carpeta `nzbs/` relativa al directorio de trabajo. Si una cuenta no lista nada, el informe te lo dirá así, en lugar de mostrarla como una cuenta sin archivos grandes.

## Las versiones de Real-Debrid que funcionan ya no se marcan como rotas tras una comprobación de enlaces {#working-real-debrid-releases-are-no-longer-marked-broken-after-a-link-check}

Desde la nightly del 2026-08-20, una biblioteca sana puede llenar el log con `Link verification failed during refresh` y `keeping files as broken`, cada una con un `404 Not Found` e `invalid_download_code` contra un host de descarga. En realidad, no había nada mal en los releases.

Esa nightly añadió una limpieza para las filas que Real-Debrid crea en My Downloads: cada enlace que zurg verifica crea una. Si no se toca, la lista crece una fila por torrent en cada build en frío, hasta que al arrancar se están paginando decenas de miles. La limpieza borra esas filas en segundo plano, partiendo de la idea de que una fila y la URL que generó son cosas separadas.

No lo son. Borrar la fila revoca el código de descarga, y lo único que lo mantiene vivo es un host que ya lo ha usado. Medido el 2026-08-22: un código generado en `124-4` y descargado una vez a través de `44-4` seguía respondiendo `200` en `44-4`, mientras que tanto `124-4` como un `125-4` sin tocar respondían `404 invalid_download_code`. zurg elige el host de descarga por petición, entre los más rápidos, así que el host que verificó un enlace rara vez es el que lo pide después. La resolución se quedaba en caché cuatro horas, y cada petición contra ella en esa ventana volvía con `404`, lo que se interpretaba como un enlace caducado y el release se marcaba como roto.

Ahora una resolución sale de la caché de enlaces en el momento en que su fila se pone en cola para borrarse, así que nada vuelve a reproducir una URL que está a punto de desaparecer; la siguiente petición resuelve una nueva. Las filas se siguen limpiando. Los releases marcados como rotos por error se recuperan en el siguiente refresh; no hace falta volver a añadirlos ni escanearlos.

## Las series con nombre por fecha de emisión se catalogan como series, no como películas {#shows-named-by-air-date-are-filed-as-shows-not-movies}

Un programa sin números de temporada y episodio se nombra según la fecha en que se emitió: `WWE SmackDown 2026-08-21`, y lo mismo con cada programa diario y de madrugada que viene después. Ninguna prueba del episodio sabía de esta convención. Buscaba `S01E01`, un número de temporada o de episodio escrito con palabras, el hash de un release de anime y, si nada de eso aparecía, buscaba una serie de archivos numerados que pudiera leerse como secuencia. Un release diario es un solo archivo con una sola fecha, así que la respuesta era no, y el release acababa en el primer directorio que lo aceptara, que en la mayoría de configuraciones eran las películas.

Ahora la fecha de emisión cuenta como la marca que es, escrita como `2026-08-21`, `2026.08.21`, `2026 08 21`, `2026_08_21` o `20260821`. Solo entran las fechas reales: el mes tiene que ser uno de los doce y el día uno de los treinta y uno. Así, un año junto a una resolución, como `Movie.2026.05.1080p`, nunca se lee como fecha. Probado con una biblioteca de 6755 releases, ninguna película cambia de directorio. Probado con 4734 releases reales de programas diarios, se reconocen ahora 4633. Los que quedan son nombres scene antiguos que abrevian el año a dos dígitos o lo ponen al final. Esos no se pueden distinguir de una distribución de canales de audio con una seguridad que merezca la pena.

Una biblioteca que ya está en disco se vuelve a clasificar sola al arrancar, así que basta con el siguiente reinicio. No hace falta volver a escanear ni a importar nada.
