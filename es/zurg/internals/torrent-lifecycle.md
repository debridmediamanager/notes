# Ciclo de vida de los torrents en Real-Debrid, AllDebrid y TorBox {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

Medido el 2026-08-30 con cuentas reales. Todo lo marcado como **observed** salió de una captura. Todo lo marcado como **inferred** no salió de una captura, y se explica por qué.

zurg necesita esto porque el shim de qBittorrent tiene que decirle a Sonarr y Radarr en qué etapa está una descarga. Hoy no puede hacerlo. `TorrentInfo.Status` usa el vocabulario de estados de Real-Debrid, y los paquetes de AllDebrid y TorBox se traducen a él antes de que el código propio de zurg vea nunca un torrent. TorBox `stalled (no seeds)` llega como `queued`. Nada transmite seeders, velocidad o eta. Por eso la tabla de etapas tuvo que construirse a partir del wire y no de los paquetes de proveedor, que ya lo normalizan y lo pierden por el camino.

El arnés es `scripts/torrent_lifecycle_probe.py`. Llama directamente a las APIs REST sin procesar, así que las capturas son el estado wire. Borra todo lo que añade al salir, incluido con Ctrl-C.

---

## Cómo se midió esto {#how-this-was-measured}

### Las cuentas {#the-accounts}

| Proveedor | Cuenta | Por qué esta |
|---|---|---|
| Real-Debrid | una cuenta de prueba | ningún zurg en ejecución la usa, así que nada más la tocó durante la prueba |
| AllDebrid | una clave de prueba | la cuenta ya tenía otros magnets, así que solo se borraron los ids que creó la prueba |
| TorBox | una clave real | **otra instancia de zurg estaba cargada con la misma cuenta**, y eso no es un detalle menor. Mira [Peligros](#hazards-found-on-the-way) |

Las credenciales salen de `RD_TOKEN` `AD_KEY` `TB_KEY` en el entorno. Nada las escribe en una
captura.

### Los torrents {#the-torrents}

Todo legítimo. Son imágenes FOSS y cine de dominio público. Cada info hash que venía de un `.torrent` fue recalculado a partir del archivo por el harness, en lugar de escribirse a mano. Los tamaños de swarm son scrapes del tracker tomados el mismo día.

| Caso | Torrent | Info hash | Tamaño | Seeders del tracker | Webseeds |
|---|---|---|---|---|---|
| cached | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | n/a | n/a |
| cached | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | n/a | n/a |
| cached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 a 27 | ninguno |
| uncached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| uncached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 seeders y 0 leechers | 3 |
| seedless | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | ninguno |
| seedless | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | ninguno |
| nometa | 40 hex aleatorios | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | ninguno | ninguno | ninguno |

Los ceros son reales y no se debe a un tracker caído. `torrent.ubuntu.com` se consultó dos veces para las tres entradas de Ubuntu en el mismo bucle. Respondió 22 y luego 27 seeders para 26.04.1, mientras que para las dos seedless respondió con un `d5:filesdee` vacío. Lo mismo pasa con `bt1.archive.org` y el item de Prelinger.

Se le preguntó a TorBox `checkcached` por cada hash antes de añadir nada. Es la única sonda de caché no destructiva de las tres. Dijo cached para las tres filas cached y uncached para las otras seis. Esa es la división que indican los nombres de los casos.

### Cadencia de sondeo y límites {#poll-cadence-and-caps}

3 s durante los primeros 2 minutos y luego 15 s. 1 s para el caso en caché, porque todo el ciclo de vida ahí puede
terminar dentro de un solo sondeo normal. Límite de 15 minutos por torrent para la campaña, en lugar del valor predeterminado del script de 30. El timeout que propone el shim es de 10 minutos, y un torrent que sigue avanzando a los 15 ya está fuera de la única ventana que importa. Las adiciones a Real-Debrid están separadas al menos 20 s entre sí.

Cada proveedor se ejecutó como su propio proceso con su propio directorio de salida. Así la separación de las adiciones a Real-Debrid se mantiene correcta dentro de un mismo proceso y permite que los tres corran al mismo tiempo.

---

## Real-Debrid

### Endpoints

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### Valores de estado observados {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

No se observó aquí. `compressing` `virus` `error` `dead`. Esos necesitan contenido que esta campaña no tenía forma legítima de producir.

### Qué campos del wire existen en cada estado {#which-wire-fields-exist-in-which-status}

Los campos aparecen y desaparecen. Un mapeador que lee `speed` en todos los estados lee una clave ausente la mitad de las veces.

| Campo | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | sí | sí | sí | sí | sí |
| `progress` | 0 | 0 | **porcentaje float** de 0 a 100 | **vuelve a 0** y sube hasta 100 | 100 |
| `seeders` | sí | **ausente** | sí | **ausente** | **ausente** |
| `speed` | **ausente** | **ausente** | sí, bytes por segundo | sí, siempre 0 en la captura | **ausente** |
| `bytes` / `original_bytes` | 0 | tamaño real | tamaño real | tamaño real | tamaño real |
| `filename` | `"Magnet"` | nombre real | nombre real | nombre real | nombre real |
| `files` | `[]` | con datos | con datos | con datos | con datos |
| `links` | `[]` | `[]` | `[]` | se va llenando durante la fase | con datos |
| `ended` | ausente | ausente | ausente | ausente | presente |

`progress` es un **float** y no un entero. La captura contiene 0.4, 0.8 y 1.4, junto con 100.
Un detector de estancamiento que redondea el porcentaje a entero considerará estancada una versión de 100 GB a 1 MB/s.

`progress` **retrocede a propósito**. Vuelve a 0 cuando el estado cambia a `uploading` y sube hasta 100 otra vez. El movimiento hay que definirlo como un cambio de etapa o un aumento de progreso, nunca como un porcentaje monótono.

`seeders` desaparece en lugar de quedar en cero cuando el torrent deja de estar en `downloading`. Lo mismo pasa con `speed`. Un mapeador debe tratar una clave ausente como desconocida, no como cero.

### Lo que hizo cada caso {#what-each-case-did}

| Case | Torrent | Transitions with seconds from add | Verdict |
|---|---|---|---|
| cached | Big Buck Bunny | `downloaded`@0.0 | done in 1.32 s end to end |
| cached | Sintel | `downloaded`@0.0 | done in 0.73 s |
| cached | Ubuntu 26.04.1 | `downloaded`@0.0 | done in 0.32 s |
| uncached | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | already cached on this account |
| uncached | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | done. 3.71 GiB in 197 s |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | failed |
| seedless | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | done. The case did not reproduce |
| seedless | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 and nothing after that | **capped at 907.6 s still `downloading`**. This is the stall shape |
| nometa | random 40-hex | `magnet_conversion`@0.0 `magnet_error`@317.9 | failed |

### La latencia del añadido en caché {#the-cached-add-latency}

Esto es el número en el que se basa el modo solo-caché del shim.

| Torrent | addMagnet devuelve | selectFiles devuelve | primera `/torrents/info` | estado |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**Observado.** Un torrent en caché está `downloaded` en la primera lectura justo después de `selectFiles`. Todo el coste síncrono son dos viajes de ida y vuelta. Nunca pasa por `queued` ni por `downloading`.

Una segunda ejecución consultó `/torrents/info` a los 0,25 s, tanto en el hueco entre `addMagnet` y `selectFiles` como después. Eso es lo que hace `--rd-select-detail`, y confirma la forma del proceso.

| Torrent | Estado antes de `selectFiles` | `selectFiles` | Primera lectura después | addMagnet hasta `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection` con 3 archivos listados y `links` vacío | 204 en t+1.314 s | `downloaded` `progress` 100 `links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection` con 11 archivos listados | 204 en t+0.627 s | `downloaded` `progress` 100 `links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection` con 1 archivo listado | 204 en t+0.219 s | `downloaded` `progress` 100 `links` 1 | **0.430 s** |

Así que la secuencia completa de un torrent en caché es `waiting_files_selection` y luego `downloaded`, sin nada en medio. La lista de archivos ya está ahí antes de `selectFiles`. `links` es lo que rellena `selectFiles`.

**La ventana de la sonda solo-caché puede ser de una sola consulta.** De 0,43 s a 1,54 s de extremo a extremo en tres torrents de 123 MiB, 264 MiB y 6,04 GiB. Una ventana de dos segundos con consultas cada cuarto de segundo es más que generosa.

Frente a los 100 s que Sonarr y Radarr permiten para una llamada a `torrents/add` (ver [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)), una ventana de sonda solo-caché de un par de segundos no cuesta nada. No hay motivo para ponerla en decenas de segundos.

### Rarezas que un mapeador de etapas tiene que sobrevivir {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` responde 404 mientras el torrent sigue en `magnet_conversion` y el error engaña.**
  El cuerpo es `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}` aunque se envió
  `files=all`. Simplemente todavía no hay archivos que seleccionar. No es un fallo del add y el torrent sigue vivo.
  Ambas ejecuciones que lo sufrieron siguieron vivas otros 318 s.
- **El hash de un tracker privado puede darse por condenado de inmediato y no tras 318 s.** El hash detrás del informe de qBittorrent del
  2026-08-31 (un remux de CiNEPHiLES de un indexador UNIT3D, `45e1ec0d…`) respondió `magnet_error` con cero archivos en la
  primera lectura después de addMagnet, sin ninguna ventana de `magnet_conversion`, segundos después del add. Tanto si Real-Debrid
  reconoció el hash como si falló rápido con él, lo observable es lo mismo: un hash privado no tiene enjambre DHT, así que
  addMagnet nunca puede tener éxito con uno, y selectFiles sobre la instancia muerta responde el 404 engañoso de arriba.
- **`addTorrent` no omite nada con contenido no cacheado, pero lo omite todo con contenido cacheado.** Un `.torrent` subido para contenido
  que Real-Debrid no tiene (un Big Buck Bunny de archive.org, sembrado pero no cacheado) pasó a `magnet_conversion` igual que un
  magnet suelto: los metadatos del archivo no se usan para resolver. Uno cacheado (una ISO de Ubuntu) respondió
  `waiting_files_selection` con su lista de archivos en la primera lectura, se seleccionó y terminó `downloaded` en menos de
  dos segundos, sin pasar nunca por `magnet_conversion`. Así que el valor de la subida es la búsqueda inmediata hash→caché, que
  es lo que hace que el release de un tracker privado sea añadible siempre que el contenido esté cacheado, y nunca añadible como magnet.
- **La resolución de metadatos se rinde a los 318 s.** Dos ejecuciones independientes pasaron de `magnet_conversion` a
  `magnet_error` a los 317.9 s y 318.0 s. Ese es el límite al que llega un magnet sin peers alcanzables. Es
  igual tanto si existe un torrent para el hash como si no.
- **`seeders` miente durante `magnet_conversion`.** El hash aleatorio de 40 hex reportó `seeders: 1` a los
  80.9 s. No existe ningún torrent para él.
- **`ended` en un torrent cacheado recién añadido lleva una fecha antigua.** Las capturas tienen
  `2025-12-28` y `2026-07-28` para torrents añadidos el 2026-08-30. Es cuando Real-Debrid tuvo por primera vez el
  contenido y no cuando esta instancia terminó. No calcules una antigüedad a partir de él.
- **Un magnet sin peers muere en la resolución de metadatos y nunca llega al webseed.** Real-Debrid sí respeta los webseeds una vez que tiene el torrent. No puede obtener el torrent de un magnet sin peers. Así que un elemento que solo tiene webseed, añadido como magnet, termina en `magnet_error`. Eso es un fallo de metadatos y no de webseed, y los dos se ven idénticos desde `/torrents/info`.

## AllDebrid

### Endpoints

`v4` y `v4.1` no son intercambiables, y la diferencia nos afectó en esta campaña.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**La subida de archivos responde con `files`, no con `magnets`.** Los campos de cada entrada son los mismos: `id`, `hash`, `name`, `ready` y un `error` opcional por entrada. Así que el flag `ready` de abajo es la respuesta de caché en ambos casos. Pero un decodificador escrito para la respuesta de magnet leerá una lista vacía.

**Y el archivo es la única forma en que AllDebrid puede describir un release sin un swarm.** Lo medimos el 2026-09-01 con la cuenta de prueba, usando dos torrents privados sintéticos de la misma forma cuyos hashes ningún swarm ha visto nunca. Subidos como archivos devolvieron sus nombres reales y sus tamaños reales (`"name":"zurg.private.ad.probe","size":65536`), y aparecían en el listado como `In queue` con el reloj todavía sin correr. Enviados como un hash `magnets[]` suelto, la respuesta fue `"name":"noname","size":0`. AllDebrid aceptó el hash y no sabía nada de él, que es lo que pasa con los releases de cualquier tracker privado añadidos por hash.

**`/v4/magnet/status` ya no existe.** Con id o sin él responde HTTP 200 con `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. `/v4/magnet/upload` y `/v4/magnet/delete` siguen funcionando. Así que la suposición del plan de que se podía usar el endpoint de status de v4 y muestrear v4.1 una vez para comparar está al revés. v4.1 es el único endpoint de status, y el harness registra una lectura v4 por torrent para que la captura lleve la prueba y no solo la afirmación.

La autenticación es `Authorization: Bearer <apikey>`. No hace falta el parámetro `agent`.

### Valores de estado observados {#status-values-observed-1}

| `statusCode` | `status` | Visto |
|---|---|---|
| 0 | `In queue` | sí |
| 1 | `Downloading` | sí |
| 2 | `Compressing / Moving` | **no** |
| 3 | `Uploading` | sí |
| 4 | `Ready` | sí |
| 5 and above | los códigos de error | **no** |

### Qué campos del wire existen en cada estado {#which-wire-fields-exist-in-which-status-1}

| Campo | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | sí | sí | sí | sí |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"` hasta que lleguen los metadatos | nombre real cuando lleguen los metadatos | nombre real | nombre real |
| `size` | 0 hasta que lleguen los metadatos | tamaño real | tamaño real | tamaño real |
| `downloaded` | 0 | **la cifra de progreso, en bytes** | igual a `size` | **ausente** |
| `downloadSpeed` | 0 | sí, bytes por segundo | 0 | **ausente** |
| `seeders` | 0 | sí | 0 | **ausente** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **la cifra de progreso de esta fase** | **ausente** |
| `processingPerc` | 0 | 0 | 0 | **ausente** |
| `files` / `nbLinks` | ausente | ausente | ausente | presente |
| `completionDate` | 0 | 0 | 0 | establecido |

**No hay porcentaje en ningún sitio.** El progreso en AllDebrid es `downloaded / size`, y ambos son enteros en bytes. `processingPerc` se mantuvo en 0 en todos los estados de todas las capturas.

`Uploading` es AllDebrid moviendo la descarga terminada a su propio almacenamiento. Tiene su propio contador de progreso en `uploaded` y `uploadSpeed`, y su `downloadSpeed` es 0 durante toda la fase. Una regla de estancamiento que solo mire `downloaded` dará por estancada una fase `Uploading` que en realidad está sana.

### Lo que hizo cada caso {#what-each-case-did-1}

| Caso | Torrent | `ready` al subir | Transiciones con segundos desde el añadido | Veredicto |
|---|---|---|---|---|
| en caché | Big Buck Bunny | true | `Ready`@0.0 | terminado en 0.11 s |
| en caché | Sintel | true | `Ready`@0.0 | terminado en 0.12 s |
| en caché | Ubuntu 26.04.1 | true | `Ready`@0.0 | terminado en 0.11 s |
| sin caché | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | ya estaba en caché |
| sin caché | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 con todos los contadores en cero hasta 634.9 `Uploading`@650.1 `Ready`@876.9 | terminado en 877 s |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 y todos los contadores en cero después | **cortado a los 907.8 s, todavía `Downloading`** |
| sin seeders | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 con todos los contadores en cero hasta 589.6 `Uploading`@619.9 `Ready`@650.2 | terminado en 650 s |
| sin seeders | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 y todos los contadores en cero después | **cortado a los 907.0 s, todavía `Downloading`** |
| sin metadatos | 40 hex aleatorios | false | `In queue`@0.0 `Downloading`@9.4 y todos los contadores en cero después | **cortado a los 907.4 s, todavía `Downloading`** |

Una ejecución aparte contra Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) capturó
un ciclo de vida completo sin caché y es la secuencia de referencia.

| Segundos | Estado | Qué cambió |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` es `"noname"` y `size` es 0 |
| 2.2 | `Downloading` 1 version 2 | todavía sin nombre ni tamaño |
| 4.3 | `Downloading` | `filename` y `size` se resuelven |
| 6.5 a 55.1 | `Downloading` | `downloaded` sube hasta `size`. `downloadSpeed` alcanza su pico cerca de 110 MB/s. `seeders` de 8 a 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` baja a 0. `uploadSpeed` y `uploaded` empiezan a subir |
| 65.6 | `Ready` 4 | Aparecen `files` y `nbLinks`. Desaparecen seis campos de progreso |

3.72 GiB en 65.6 s.

### AllDebrid no reporta ningún progreso mientras un trabajo espera a su propia infraestructura {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

Este es el hallazgo que más cambia el diseño del timeout, y hicieron falta dos ejecuciones independientes para confiar en él.

`Downloading` con `statusCode` 1 aparece a los pocos segundos de la subida. Durante un rato después de eso,
AllDebrid informa `downloaded` 0, `downloadSpeed` 0, `seeders` 0, `uploaded` 0, `uploadSpeed` 0 y `processingPerc` 0. También vuelve a poner `size` en 0 y `filename` en el info hash, aunque ya hubiera informado ambos correctamente.

| Ejecución | Cuánto tiempo estuvo todo a cero | Qué pasó después |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 s** desde 12.5 s hasta 634.9 s | 3.71 GiB descargados en 15 s, luego `Uploading` y luego `Ready` a los 876.9 s |
| ubuntu-16.04.6-desktop-i386 | **580 s** desde 9.4 s hasta 589.6 s | 1.56 GiB descargados en 30 s, luego `Uploading` y luego `Ready` a los 650.2 s |

Las dos terminaron. Ninguna mostró ni un solo byte de movimiento durante los primeros diez minutos.

**Un timeout de diez minutos sin movimiento abandonaría trabajos sanos de AllDebrid.** El valor por defecto propuesto para `download_timeout_mins`, 10, cae dentro de esta ventana en las dos de dos ejecuciones. O bien el timeout tiene que ser más largo que esto, o bien AllDebrid `Downloading` con `size` 0 tiene que contar como una etapa propia en la que el reloj no corre. Perder el nombre y el tamaño es la forma en que AllDebrid indica que el trabajo está asignado pero no ha empezado, y no es un fallo.

Una ejecución que arrancó enseguida sirve de contraste. Debian 13.3.0 arm64 DVD-1 pasó de `In queue` a contadores de bytes reales en 6.5 s. Así que la espera es una cola y no un retraso fijo.

### La bandera `ready` es una respuesta real de caché {#the-ready-flag-is-a-real-cache-answer}

`ready` en la respuesta de `/v4/magnet/upload` era true para todos los hashes que TorBox también marcó como en caché, y false para los dos que la campaña descargó. AllDebrid no tiene una comprobación de caché aparte, así que esta marca es toda la señal de caché. zurg ahora la lleva desde ambas vías de añadido, la del magnet y la de la subida de archivos, como `MagnetResponse.Cached` con `CacheKnown` activado, para que un backend que no puede responder nunca se confunda con uno que informa de un fallo.

**Un `ready` en false significa que el magnet ya está añadido.** No hay forma de preguntarle a AllDebrid si un hash está en caché sin añadirlo. Una ruta solo-caché en AllDebrid tiene que borrar el fallo.

---

## TorBox

### Endpoints

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### Valores de estado observados {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing` y `checking` y `stalledDL` **no están en la tabla de traducción de zurg**
(`internal/torbox/types.go` `normalizeStatus`). Los tres caen en la rama por defecto y se reportan
como `downloading`.

`checking` es donde TorBox espera los metadatos, no donde verifica un hash. Un magnet cuyo swarm
nunca responde pasa de `metaDL` a `checking` y se queda ahí. El hash aleatorio de 40 hex seguía en
`checking` al llegar al tope de 910 s, y el item Prelinger sin peers también a los 911 s. TorBox nunca se rinde
como lo hace Real-Debrid a los 318 s.

**Subir el `.torrent` se salta esa espera por completo, y es toda la diferencia para el release de un tracker privado.** Medido el 2026-09-01 en la cuenta de arriba, el mismo torrent privado sintético se envió de las dos formas. Como hash: aceptado con un `torrent_id`, y luego `checking` con `name` igual al hash en bruto, `size: -1`, `files: null` y `eta: 8640000`. TorBox buscando un swarm que no está en la DHT, algo que hará hasta el tope sin reportar nada. Como archivo, en `POST /torrents/createtorrent` con los bytes en una parte multipart `file`: leído tres segundos después con el nombre propio del torrent, su tamaño real y `stalled (no seeds)`. Es el mismo contenido que nadie tiene, pero ahora descrito. La etapa es lo importante. `checking` con `size: -1` se mapea a `StageResolvingMetadata`, que indica que hay trabajo en curso y no se puede concluir nada; `stalled (no seeds)` se mapea a `StageStalledNoPeers`, sobre el que el endpoint de qBittorrent sí puede actuar. Un release en caché se leyó como `done` al 100% con su lista de archivos dentro de esos mismos tres segundos. El nombre de la parte es crítico: un archivo enviado con cualquier otro nombre no se ve en absoluto, y el endpoint responde `MISSING_REQUIRED_OPTION`, "You must provide either a file or magnet link".

(Una traducción anterior fue rechazada: los fragmentos de código no coinciden (` maps to `). Mantén la estructura exactamente.)

### Qué campos del wire existen en cada estado {#which-wire-fields-exist-in-which-status-2}

TorBox envía el mismo conjunto de claves en cada estado y solo cambia los valores. Por eso es el más fácil de leer de los
tres. Los valores son los que transmiten el significado.

| Estado | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | tiny | 8640000 | real |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | real |
| `downloading` | false y luego **true** | false | false | true | fracción | segundos | real |
| `processing` | **true** | **false** | false | true | 1 | segundos | real |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | real |
| `uploading` | true | **true** | true | true | 1 | 0 | real |
| `cached` | true | true | true | false | 1 | 0 | real |

Nombres de campos. El plan listaba todos estos como no verificados.

| Qué | Campo de TorBox | Formato |
|---|---|---|
| progreso | `progress` | **fracción de uno**, no un porcentaje. `0.0793719` |
| seeders | `seeds` | entero |
| leechers | `peers` | entero |
| velocidad de descarga | `download_speed` | bytes por segundo |
| velocidad de subida | `upload_speed` | bytes por segundo |
| eta | `eta` | segundos. `8640000` es el valor de «desconocido» |
| bytes descargados | `total_downloaded` | entero |
| salud del swarm | `availability` | float. Pasa a **-1** en `uploading (no peers)` |
| dónde están los datos | `download_path` | null hasta que los datos estén presentes |

`8640000` son 100 días. Es la forma que tiene TorBox de decir que no lo sabe. También es la misma constante que el shim de zurg le pasa hoy a Sonarr cuando no tiene nada que informar.

### Lo que hizo cada caso {#what-each-case-did-2}

| Caso | Torrent | `checkcached` | Transiciones con segundos desde añadir | Veredicto |
|---|---|---|---|---|
| en caché | Big Buck Bunny | true | `cached`@0.0 | done in 0.83 s |
| en caché | Sintel | true | `cached`@0.0 | done in 0.94 s |
| en caché | Ubuntu 26.04.1 | true | `cached`@0.0 | done in 0.69 s |
| sin caché | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 luego **gone**@48.6 | borrado por el otro zurg al 86.7% |
| sin caché | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 luego **gone**@86.7 | borrado por el otro zurg |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 y nunca nada más | **limitado a 911.3 s en `checking`**. TorBox no usó el webseed |
| sin semillas | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 luego **gone**@200.4 | borrado por el otro zurg en `processing` |
| sin semillas | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 luego **gone**@462.3 | borrado por el otro zurg al 91.9 por ciento |
| sin metadatos | 40-hex aleatorio | false | `metaDL`@0.0 `checking`@10.2 y nunca nada más | **limitado a 910.3 s en `checking`** |

Una ejecución aparte con un poll de 0.5 s contra Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`) aguantó lo suficiente para llegar a done y es la secuencia de referencia.

| Segundos | Estado | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB en 64.4 s.

Lee las últimas tres filas dos veces. TorBox pone `download_finished` a true y `progress` a 1 unos diez segundos **antes** de que los datos estén presentes. Luego vuelve a `downloading` con un valor de progreso más bajo que el que acaba de reportar. Tanto `progress` como `download_state` retroceden en una descarga sana.

---

(Una traducción anterior fue rechazada: los fragmentos de código no coincidían. Mantén la estructura exactamente.)

## La tabla de etapas {#the-stage-table}

The stage enum the shim will speak is `resolving-metadata` `queued` `downloading` `stalled-no-peers` `finalizing` `done` `failed` and the empty string for unknown.

### Real-Debrid

| `status` original | Etapa | Base |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **observado**. `bytes` 0, `files` vacío y `filename` es el literal `"Magnet"` |
| `waiting_files_selection` | `queued` | **observado** con `--rd-select-detail`. Los archivos ya aparecen listados. `links` está vacío |
| `queued` | `queued` | **observado**. El tamaño real y el nombre real ya se conocen. No hay `seeders` ni `speed` |
| `downloading` | `downloading` | **observado** |
| `downloading` con `seeders` 0 | `stalled-no-peers` | **observado**. 904 s con `progress` 0, `seeders` 0 y `speed` 0 en 92 consultas |
| `compressing` | `finalizing` | **inferido**. No visto |
| `uploading` | `finalizing` | **observado**. El progreso vuelve a empezar desde 0 y `seeders` desaparece |
| `downloaded` | `done` | **observado** |
| `magnet_error` | `failed` | **observado** tras 318 s en `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **inferido**. No visto |

### AllDebrid

| `statusCode` | Etapa | Base |
|---|---|---|
| 0 `In queue` | `queued` | **observado**. Dura unos segundos. `filename` puede seguir siendo `"noname"` y `size` 0 |
| 1 `Downloading` con `size` 0 | `queued` | **observado**. No es `downloading` ni `stalled-no-peers`. AllDebrid ha aceptado el trabajo y no lo ha iniciado. Se mantuvo durante 622 s y 580 s en dos ejecuciones que luego terminaron |
| 1 `Downloading` con un `size` real | `downloading` | **observado** |
| 1 `Downloading` con `seeders` 0 y `downloaded` sin cambios | `stalled-no-peers` | **no observado y no inferible de forma segura**. Ver abajo |
| 2 `Compressing / Moving` | `finalizing` | **inferido**. No visto |
| 3 `Uploading` | `finalizing` | **observado**. Aquí el progreso lo indican `uploaded` y `uploadSpeed`, y `downloadSpeed` es 0 |
| 4 `Ready` | `done` | **observado** |
| 5 y superiores | `failed` | **inferido**. No visto |

**AllDebrid no tiene una forma observable de estancamiento.** Un trabajo que AllDebrid tiene en cola y un trabajo en el que AllDebrid no puede avanzar tienen el mismo aspecto en la respuesta. Ambos tienen `statusCode` 1, `size` 0 y todos los contadores a cero. El elemento Prelinger estuvo en exactamente esa forma durante todo el límite de 907.8 s, y otros dos torrents estuvieron así diez minutos cada uno y luego terminaron. Así que nada en la respuesta de AllDebrid distingue ambos casos, y un veredicto de estancamiento en AllDebrid solo puede venir de un reloj.

### TorBox

| `download_state` en bruto | Etapa | Base |
|---|---|---|
| `metaDL` | `resolving-metadata` | **observado**. `size` 0 y `name` igual al hash |
| `checking` | `resolving-metadata` | **observado**. `size` **-1** mientras dura. Aquí es donde TorBox espera al torrent y no una verificación de hash. Hoy no está en la tabla de zurg |
| `stalledDL` | `stalled-no-peers` | **observado**. Hoy no está en la tabla de zurg |
| `stalled (no seeds)` | `stalled-no-peers` | **observado**. El nombre exagera. Dos capturas tenían `seeds` 1 y 2 mientras estaban en este estado. Hoy zurg lo asigna a `queued` |
| `downloading` | `downloading` | **observado** |
| `processing` | `finalizing` | **observado**. Hoy no está en la tabla de zurg |
| `uploading (no peers)` | `finalizing` | **observado** cuando `download_present` es false |
| `uploading` | `done` | **observado** cuando `download_present` es true |
| `cached` `completed` `seeding` | `done` | `cached` **observado**. Los otros dos **inferidos** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **inferido**. No se ha visto ninguno |

**El par `download_finished` y `download_present` no sustituye a la cadena de estado.** Tanto `processing` como `uploading (no peers)` y parte de `downloading` llevan `download_finished: true` con `download_present: false`. Esa combinación es una fase de finalización normal y no un torrent muerto. Mira el peligro más abajo.

---

## Lo que no se pudo medir {#what-could-not-be-measured}

- **El caso de sin semillas se reprodujo en un candidato de dos.** Ambos tenían cero peers en el tracker.
  ubuntu-16.04.6-desktop-i386 se descargó igualmente en los tres proveedores porque DHT aportó peers que el
  tracker no conocía. ubuntu-24.04-beta-live-server-s390x se quedó parado en Real-Debrid durante todo el
  límite y es la observación de parada de arriba. Un cero en una consulta al tracker es un predictor débil. Mantén
  dos candidatos en el caso. Real-Debrid tenía los metadatos de ambos de todas formas e informó `bytes` y
  `filename` correctamente en la primera lectura `queued`.
- **Nunca se vio `compressing` en Real-Debrid.** Todas las ejecuciones completadas pasaron de `downloading` directamente a
  `uploading`.
- **Nunca se vio el código de estado 2 de AllDebrid.** Todas las capturas pasaron de 1 directamente a 3.
- **Ningún proveedor llegó a su propio vocabulario de errores.** Los `error`, `virus` y `dead` de Real-Debrid, todos
  los códigos de AllDebrid por encima de 4 y todos los estados de fallo de TorBox siguen sin medirse. Para
  provocarlos hace falta contenido bloqueado, infectado o caducado, no una ISO de FOSS.
- **TorBox rara vez pudo seguirse hasta el final.** Cuatro torrents de la campaña y uno de seguimiento fueron
  borrados a mitad de descarga por el otro zurg de la cuenta. Ver el peligro de abajo. Solo una imagen de 754 MiB terminó
  antes de que ese proceso volviera a consultar.

---

## Peligros encontrados por el camino {#hazards-found-on-the-way}

### Una segunda zurg en la cuenta de TorBox borra descargas sanas {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

Otra instancia de zurg se cargó con la misma cuenta de TorBox. Su configuración dice:

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**Cinco** torrents de sonda se eliminaron mientras se descargaban con normalidad. Esto se **observa** en
ambos lados. El arnés vio desaparecer cada torrent y el diario de la otra instancia explica por qué.

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

Los cinco son `86695315` `86695708` `86697191` `86702627` `86704212`. Todos tenían el mismo
motivo. Ninguno estaba roto.

El mecanismo es la segunda regla de `normalizeStatus` en `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

Esa combinación es una fase de finalización normal de TorBox. La captura de 0.5 s lo mide. En una imagen
de 754 MiB, la ventana desde que `download_finished` pasa a true hasta que `download_present` pasa a true fue de
**9.6 segundos**. En una imagen de 3.7 GiB fue de al menos 17 s y la limpieza cayó dentro de ella. La otra
zurg consulta la biblioteca cada 15 s más o menos. Si una descarga sana de TorBox sobrevive a su propia
finalización es casi como lanzar una moneda al aire.

Tres consecuencias. Una descarga de TorBox que el usuario ve terminar en la interfaz de TorBox puede desaparecer
de su biblioteca de zurg. `delete_error_torrents` está documentado como la eliminación de torrents que el proveedor
indica como rotos, y aquí elimina los que el proveedor indica como correctos. Y cualquier medición de TorBox en
esta cuenta compite con esa limpieza.

**No se corrige aquí.** La fase 0 mide. La corrección corresponde al trabajo de etapas. Allí,
`download_finished && !download_present` pasa a ser `finalizing` en lugar de `failed`.

### Una segunda zurg en la cuenta de AllDebrid se salió con la suya {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

La clave de AllDebrid que usó esta campaña también la cargó otra instancia de zurg, con los mismos tres ajustes de barrido que la de TorBox.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

No se borró ninguna sonda de AllDebrid. El motivo está en el código y no en la suerte. `normalizeStatus` en `internal/alldebrid/types.go` solo asigna `error` a los códigos de estado iguales o mayores que 5, y no tiene ninguna regla estructural del tipo `download_finished && !download_present`. Por eso una descarga sana de AllDebrid nunca puede parecer rota. El fallo de TorBox es esa regla extra y no un barrido en general.

Real-Debrid es el caso raro. Ninguna otra instancia de zurg cargó la cuenta de prueba. Nada la estaba barriendo y nada interfirió.

### TorBox responde a un borrado de un id desconocido con HTTP 500 {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` responde igual. Así que un torrent que ya no existe no se distingue de una caída de TorBox solo por el código de estado. zurg lo reporta como `account temporarily unavailable`. El diario de la otra instancia muestra que reintenta borrar un id que ya fue borrado cada 15 s. El harness lo soluciona preguntando a `mylist` después de un borrado fallido y tratando un torrent que ya no existe como borrado.

### El throttling de Real-Debrid no apareció {#real-debrid-throttling-did-not-appear}

Nueve adds con 20 s de separación no produjeron ningún 451 ni ningún 429 en toda la campaña. Eso coincide con la nota del `CLAUDE.md` de la raíz, que dice que 6 adds separados 10 s dieron 0/6 y que esos mismos 6 con 20 s dieron 6/6. El límite de 20 s hace un trabajo real y no es superstición.

## Volver a ejecutar la campaña {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Ejecútalo desde una máquina con salida residencial. AllDebrid responde `NO_SERVER` a las IP de centros de datos.

El paso 6 no es opcional y el paso 3 es lo que le da sentido. Después de la campaña del 2026-08-30, ninguno de los 34 ids de instancia que el arnés había reclamado quedó en ninguna de las tres cuentas. Tampoco quedó ninguno de los nueve hashes de sonda.

Antes de tocar TorBox, comprueba si alguna otra zurg está cargada con la misma cuenta, lee su configuración de barrido y espera el barrido descrito arriba.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Nunca lo cambies. Una sonda que desaparece a mitad de la ejecución es un dato.
