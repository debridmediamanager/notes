# Qué significa "Torrent is being downloaded to debrid" {#what-torrent-is-being-downloaded-to-debrid-means}

El verde **Torrent is being downloaded to debrid...** significa que la versión que elegiste todavía no está en caché en tu servicio de debrid. Torrentio, el addon de Stremio que la muestra, acaba de añadir ese torrent a tu cuenta de Real-Debrid, TorBox u otro servicio de debrid, y el servicio lo está descargando ahora mismo. Cuando termine, el mismo resultado se reproduce como cualquier otro.

## Qué hacer {#what-to-do}

1. **Elige un resultado en caché.** En la lista de Torrentio, `[RD+]` (o `[TB+]`, `[AD+]`, `[PM+]`) significa que está en caché, así que se reproduce al instante. `[RD download]` significa que no está en caché. Esos aparecen después de los que sí lo están.
2. **O espera unos minutos y pulsa otra vez el mismo resultado.** Mientras sigue descargándose, verás de nuevo la pantalla verde. Cuando termine, se reproduce.
3. **Sigue la descarga** en la [página de torrents de Real-Debrid](https://real-debrid.com/torrents), en tu [panel de TorBox](https://torbox.app/dashboard) o en la [biblioteca de DMM](https://debridmediamanager.com/library). DMM muestra el porcentaje, los seeds y la velocidad de cada descarga sin terminar.
4. **¿Atascado en 0% sin seeds?** Ahora mismo nadie comparte ese release, así que quizá nunca termine. Elige otro.
5. **¿No quieres ver estos resultados?** Abre la [página de configuración de Torrentio](https://torrentio.strem.fun/configure), indica de nuevo tu servicio debrid y tu clave, marca **Don't show download to debrid links** en **Options** y pulsa **INSTALL**. Solo verás resultados en caché.

## Mira qué está en caché antes de darle a reproducir {#see-whats-cached-before-you-press-play}

Inicia sesión en [DMM](https://debridmediamanager.com/) con tu servicio debrid y busca el título. En su página, un botón verde **Instant RD** significa que Real-Debrid tiene esa versión en caché, así que se reproduce al instante. **DL with RD** significa que no está en caché y primero tiene que descargarse. Toca el chip **RD** encima de los resultados para ocultar todo lo que no esté en caché. TorBox, AllDebrid, Premiumize y Offcloud tienen los mismos botones (**Instant TB**, **DL with TB** y así sucesivamente).

## Preguntas {#questions}

### ¿Cuánto tarda? {#how-long-does-it-take}

Depende de cuántas personas compartan ese torrent. Un lanzamiento popular suele estar listo en minutos: en nuestra prueba con Premiumize, una película de 1.5 GB estuvo lista cinco minutos después de la primera pulsación, descargándose de tres peers. Uno que se comparte poco puede ir lento, y uno que nadie comparte quizá nunca termine. La página de torrents o el panel muestran la velocidad y cuántos seeds ha encontrado.

### ¿Por qué pasa en algunos resultados y en otros no? {#why-does-it-happen-on-some-results-and-not-others}

Los servicios debrid guardan lo que descargan sus usuarios. Si alguien ya descargó esa versión exacta, está en caché y se reproduce al instante. Si nadie la ha descargado, o si el servicio la ha eliminado después, tu cuenta tiene que descargarla primero. Esa es la diferencia entre `[RD+]` y `[RD download]`. TorBox [explica cómo funciona su caché](https://support.torbox.app/en/articles/9923071-how-does-the-torbox-cache-work).

### ¿Por qué salió un resultado de `[RD+]`? {#why-did-an-rd-result-show-it}

Real-Debrid no deja que los addons pregunten qué está en caché. Así que en Real-Debrid, el `+` de Torrentio significa que el release se reprodujo para alguien hace poco, no que Real-Debrid lo haya confirmado en este momento. Si Real-Debrid lo quitó desde entonces, se vuelve a descargar. Elige otro resultado con `+` o espera.

### ¿Se ha roto mi debrid? {#is-my-debrid-broken}

No. La pantalla verde significa que tu servicio aceptó el torrent y lo está procesando. Cuando algo está realmente mal, Torrentio muestra una pantalla roja o amarilla con otras palabras, como "Access denied" o "Some usage limit exceeded".

### Mi addon dice otra cosa {#my-addon-says-something-else}

Las palabras exactas vienen de Torrentio y de las copias autoalojadas de este. Otros addons lo dicen a su manera. AIOStreams muestra "The file is being downloaded to your debrid. Try again later", Comet "The media you tried to play is not cached yet on this debrid service" y StremThru "Downloading to Store". La causa es la misma, y también la solución.
