# Límites de TorBox y cómo zurg se adapta a ellos {#torbox-limits-and-how-zurg-adapts-to-them}

zurg tiene su comportamiento de biblioteca diseñado en torno a las restricciones de Real-Debrid. Las de TorBox son diferentes en esencia, no solo en magnitud, y tratarlo como a Real-Debrid hace que la cuenta sea limitada por tasa a los pocos segundos de un primer escaneo de la biblioteca. Aquí se explican cuáles son los límites, de dónde salen las cifras y qué hace zurg con cada uno.

Los límites de cada proveedor se declaran en el código como `debrid.Capabilities`, para que el código genérico de la biblioteca los lea en lugar de asumirlos. Añadir un backend significa completar esa estructura, no editar el gestor de torrents.

## Límites de tasa {#rate-limits}

| Límite | Valor | Fuente |
|---|---|---|
| Todos los endpoints juntos, por token de API | 300/min | [documentado](https://api-docs.torbox.app/) |
| `POST /torrents/createtorrent` (solo uncached) | 60/hora | documentado |
| `POST /webdl/createwebdownload`, `POST /usenet/createusenetdownload` | 60/hora | documentado |
| `GET /torrents/requestdl` | **~100 llamadas, luego 429**: un presupuesto, no una tasa | medido, 2026-08-30 |
| Conexiones concurrentes a un mismo host de CDN | **exactamente 20**, 429 por encima | medido, 2026-08-23 |
| Techo de ráfaga global | se activa en ~40 concurrentes, limita *todos* los endpoints | medido |
| Recuperación de 429 | `Retry-After: 300`, corte binario | medido |

Los límites son por token de API y se sincronizan entre los servidores de TorBox, no por IP. Por eso, otros clientes en otras máquinas comparten el mismo presupuesto. TorBox lo dice explícitamente: dejó de aceptar solicitudes de lista blanca de IP porque el límite depende del token.

Tres cosas hacen que esto sea más duro de lo que sugiere el titular de 300/min:

- **Los 300/min no son por endpoint.** Es un único presupuesto que gasta toda la clave, así que limitar cada endpoint por separado puede hacer que su suma supere un techo que ninguno supera por sí solo.
- **`requestdl` es mucho más estricto de lo documentado, y no es una tasa.** Es el endpoint que genera las URLs de descarga, y dejó de responder tras unas 100 llamadas, mientras que `user/me`, `mylist` y `checkcached` aguantaron más de 500 con la misma concurrencia.

  Ir más despacio no consigue más llamadas. Medido el 2026-08-30 en la cuenta principal, con tres pruebas en cada caso, empezando siempre desde un bloqueo ya limpio:

  | Ritmo | El 429 llegó en | Tiempo transcurrido |
  |---|---|---|
  | lo más rápido posible, subiendo de 60 a 240/min | llamada **100** | 56s |
  | uno por segundo (60/min) | llamada **94** | 108s |
  | uno cada dos segundos (30/min) | llamada **101** | 198s |
  | uno cada tres segundos (20/min) | **nunca**, 241 llamadas | 721s, sin errores |

  Reducir el ritmo a la mitad dio noventa segundos más y ni una llamada más; reducirlo otra vez hizo que el 429 dejara de aparecer. Lo que tiene la cuenta es **100 llamadas por cada ventana móvil de cinco minutos, o sea 20/min**. Solo esa lectura encaja con las cuatro pruebas: predice el corte en t≈100s, t≈200s e inmediatamente en las tres primeras, y predice que la cuarta se queda justo en el límite y sobrevive.

  Esta es la corrección más importante al leer el resto de este archivo. Un limitador por minuto no puede mantener a zurg dentro del presupuesto, así que los números de ritmo que aparecen abajo sirven para dar suavidad, no margen. Un limitador más rápido no termina antes un escaneo de biblioteca: llega al mismo bloqueo antes y, cuando llega, deja el montaje sin responder a nada durante cinco minutos. Gastar *menos* llamadas es lo único que aumenta cuánto llega a avanzar un escaneo. Por eso aquí se descarta la lectura anticipada y por eso nombrar un archivo ya resuelto nunca debe costar una solicitud.
- **El 429 es un precipicio, no una pendiente.** Una vez activado, el 100% de las solicitudes fallan durante unos cinco minutos. No hay una degradación parcial del rendimiento que puedas aguantar.

Las descargas del CDN se miden por separado y **no** comparten el presupuesto de la API. Reproducir un archivo nunca gasta cuota de resolución de enlaces. Esto se comprobó en ambos sentidos: saturar las descargas del CDN hasta provocar 429 dejó `requestdl` respondiendo con normalidad, y viceversa.

### Dos límites distintos, ambos con el número 20 {#two-different-limits-both-numbered-20}

La tabla de arriba enumera 20 dos veces y son cosas sin relación. Confundirlas es fácil y lleva a limitar la cosa equivocada.

- **`requestdl` a unas ~20 concurrentes** es un límite de la *API*: unas 100 llamadas con esa concurrencia antes de un 429, gastando el presupuesto de peticiones de la cuenta.
- **20 conexiones por host de CDN** es un límite de la *ruta de bytes*, medido el 2026-08-23 con una rampa gradual. No necesita ninguna llamada a `requestdl`: reutilizar una URL ya generada basta para alcanzarlo.

El techo de la ruta de bytes es **exactamente 20** y se comporta como un tope duro y no como una pendiente: se sostienen 20 tanto si se piden 24, 32, 40 o 48 conexiones, y los rechazos suben para absorber todo lo que queda por encima de esa línea.

Se aplica al **host del CDN, no al objeto ni a la IP**, lo que corrige la lectura anterior de "por IP en la capa de Cloudflare":

- Dos archivos *distintos* servidos desde un mismo host `nexus-NNN` comparten el presupuesto único de 20 y rechazan el mismo excedente.
- La misma carga repartida entre dos hosts funciona sin problemas.
- 32 streams concurrentes repartidos en 16 hosts, todos desde una misma IP, están bien.

Como referencia frente a los otros proveedores medidos de la misma forma: Real-Debrid topa en 32 por host (rechaza en la capa TCP, sin código de estado HTTP), AllDebrid en 32 (HTTP 429), y Premiumize no mostró ningún techo hasta 64. El 20 de TorBox es el más bajo de los cuatro.

**Los edges globales de TorBox no tienen ese límite.** El 20 es una propiedad de los hosts por nodo `nexus-NNN.<region>.tb-cdn.st` que genera `requestdl`. Los dos edges globales, `nexus.erth.tb-cdn.earth` y `nexus.hare.tb-cdn.earth`, sirven cualquier archivo de la cuenta y ambos subieron hasta 64 conexiones concurrentes sin ningún rechazo. Solo cambia el host; la ruta y el token siguen autenticando la petición. zurg no reescribe las peticiones hacia ellos hoy (el servicio hermano `debrid` sí lo hace, mediante `TORBOX_CDN_EDGE`), así que el techo de abajo es el que se aplica aquí.

### Qué hace zurg {#what-zurg-does}

- **`GetTorrentInfo` se sirve desde la lista de torrents.** La `mylist` de TorBox ya incluye la lista de archivos de cada torrent, así que refrescar la biblioteca cuesta una sola petición en lugar de una por torrent. Esto se declara como `Capabilities.ListIncludesFiles`, y la ruta de refresco omite tanto la llamada por torrent como la caché de información en disco para los proveedores que lo activan. En una cuenta de 213 torrents, esto es la diferencia entre 213 peticiones y 1.
- **Un solo limitador regula todos los endpoints**, configurado a 240/min frente a los 300 documentados, para dejar margen a lo que más use la misma clave: el panel de TorBox, otro cliente, un segundo zurg.
- **`requestdl` tiene un segundo limitador encima**, configurado a 15/min. Cada resolución gasta de ambos. El número está por debajo de los 20/min medidos y no justo en ese valor, por la misma razón que el limitador general está en 240 frente a 300 documentados: el presupuesto lo gasta todo lo que tenga la clave, y los 20/min se midieron sin nada más usándola. `TestTheRequestdlBudgetCannotBeSpentInsideItsWindow` vela por el invariante real: todo el cupo no puede gastarse dentro de la ventana que lo repone, así que la constante no puede volver a subirse sin que se note.
- **El cliente de descarga está limitado a 20 conexiones por host de CDN** (`maxConnsPerCDNHost` en `internal/torbox/client.go`, pasado a través de `rdclient.HTTPClientOptions.MaxConnsPerHost`). El `MaxConnsPerHost` de Go hace que la petición 21 *espere a que haya una conexión libre* en lugar de fallar, así que el límite convierte un rechazo del proveedor en una cola local. Sin él, el cliente de descarga heredaba el ajuste sin límite del transporte de propósito general y podía recibir 429 en la ruta de bytes mientras se respetaban todos los limitadores de la API.
- **Las respuestas 429 dejan en espera a todos los que llaman** durante la ventana de `Retry-After`, en lugar de dejar que cada uno gaste una petición descubriendo otra vez el bloqueo. El bloqueo es de toda la cuenta, así que un 429 recibido en cualquier endpoint frena a todos.
- **La concurrencia se limita a 16 peticiones en vuelo**, por debajo del techo de ráfaga global de unas 40, dejando sitio para el cliente de descarga junto a ellas.
- **Se descarta la lectura anticipada.** zurg precarga el siguiente archivo de un lanzamiento cuando hay una lectura en frío, algo que absorbe cualquier backend con un presupuesto real por minuto. Donde falla es en un escaneo de biblioteca: abre cada archivo exactamente una vez, así que cada apertura es en frío, la negativa de lectura en caliente nunca se activa y la cuenta recibe dos resoluciones por archivo. Medido el 2026-08-30, un escaneo de cuarenta archivos generó exactamente cuarenta resoluciones especulativas junto a sus cuarenta lecturas: la mitad del presupuesto, gastada en archivos que nadie había pedido. TorBox declara `Capabilities.SpeculativeResolutionsAffordable` como false y no recibe ninguna.
- **Poner nombre a un archivo resuelto no cuesta ninguna petición.** Cada resolución termina buscando el nombre y la longitud del archivo para el registro de descarga. Esa búsqueda pasaba por el snapshot de la lista, así que una vez caducada su ventana de frescura de treinta segundos, la siguiente lectura descargaba la lista completa de torrents antes de poder responder. Durante un escaneo, eso ocurría cada treinta segundos mientras durara el escaneo, y en una biblioteca de 3.700 torrents ese listado se pagina cuatro veces. Ahora lee el listado que ya tiene en mano, sea cual sea su antigüedad, porque los nombres y longitudes de los archivos de un torrent terminado no pueden cambiar.
- **La caché de enlaces se mantiene un día, con recuperación ante un rechazo explícito.** Las llamadas repetidas a `requestdl` devolvieron URLs idénticas en la prueba del 2026-08-30, incluso una hora después, y una URL de 3 h 25 min seguía sirviendo `206`. Eso demuestra reutilización, no una vida útil ilimitada. El 2026-09-04, una URL cacheada y correctamente autenticada devolvió `400` con «Invalid Presigned Token», mientras que una resolución nueva del mismo torrent/archivo devolvió otro host y otra ruta y sirvió `206`. Su query no había cambiado. Mover solo la ruta/query antigua al nuevo host seguía devolviendo `400`.

  La caché de 24 h sigue siendo una decisión de presupuesto: un escaneo resuelve a 20/min y puede durar horas. Un rechazo explícito de token inválido ahora invalida esa URL e intenta una resolución nueva. Los lectores concurrentes comparten el trabajo de resolución, y un rechazo tardío no puede desalojar una URL cacheada más reciente. Si la URL recién resuelta también es rechazada, la reproducción se pausa localmente durante un minuto sin dar por malo el archivo. Los 400 genéricos no prueban que la URL esté caducada y solo activan un enfriamiento corto. Los 429 del CDN conservan `Retry-After` y aparcan las lecturas a ese host entre archivos y llamadas de verificación; el presupuesto de la API sigue siendo independiente.
- **`bypass_cache=true` en cada llamada a la lista.** La caché propia de `mylist` de TorBox tiene un TTL de unos 5 minutos; servir desde ella es lo que hace que los montajes WebDAV vayan de 5 a 15 minutos por detrás de la realidad. El parámetro no consume el límite de peticiones y reduce la propagación a menos de un segundo.
- **Un sondeo cuesta un listado.** El sondeo de cambios en la biblioteca es el único que fuerza una descarga, porque detectar un cambio es precisamente su trabajo. El recuento de activos tomado en el mismo tick, y el refresco completo que sigue a un cambio, leen ambos el snapshot que el sondeo acaba de llenar. Forzarlo también ahí significaba volcar la biblioteca entera dos o tres veces por sondeo: con el intervalo por defecto de diez segundos, miles de lecturas completas redundantes al día sobre un servicio cuya propia caché de listas zurg ya está saltándose.
- **La lista se recorre en páginas de 1000.** `mylist` limita cada respuesta a 1000 torrents (es el valor por defecto documentado de `limit`, y pedir más no lo sube), y no informa ni de un total ni de si hay más. Una sola petición responde, por tanto, a una cuenta más grande con sus 1000 más recientes y parece exactamente una biblioteca completa. zurg pagina con `offset` hasta que llega una página corta, eliminando los ids repetidos según avanza: la lista está ordenada por id descendente, así que un torrent añadido durante el recorrido desplaza la ventana un puesto y repite una entrada en la unión entre páginas.

## Límites de la cuenta {#account-limits}

| Plan | Active slots | Seeding | Tamaño máximo de torrent | Notas |
|---|---|---|---|---|
| Free | 1 | ninguno | 10 GB | 1 adición/24 h, 10 adiciones/mes, sin torrents privados |
| Essential | 3 | — | 200 GB | sin tiempo de espera, adiciones ilimitadas de contenido en caché |
| Standard | 5 | 2 semanas | — | |
| Pro | 10 | 30 días | — | caducidad a los 30 días |

Fuente: [Restricciones de cuenta](https://support.torbox.app/en/articles/9836418-account-restrictions).

`/user/me` indica el plan con un número, y los números no siguen el orden de precio:
**0 Free, 1 Essential, 2 Pro, 3 Standard**. Standard se añadió después de Pro. Hasta el 2026-10-03, zurg leía el plan 2 como Standard, lo que daba a las cuentas Pro cinco slots y el mínimo de uso de Standard.

**Active slots es la restricción más característica de TorBox**, mientras que en Real-Debrid es el ancho de banda. Un torrent ocupa un slot mientras se descarga *o comparte (seeding)*, así que en un plan de pago un torrent completado puede ocupar uno durante hasta 30 días.

### Qué hace zurg {#what-zurg-does-1}

- **`GetActiveTorrentCount` reporta el límite real del plan**, leído de
  `plan` en el registro del usuario, así que las reparaciones se bloquean y
  esperan en lugar de encolar añadidos que la cuenta va a rechazar. Si un
  proveedor no informa ningún límite, se trata como ilimitado en lugar de
  bloquearse para siempre.
- **Los torrents añadidos se marcan por defecto como never-seed.** Seeding ocupa
  un slot durante semanas y factura el tráfico saliente, y ninguna de las dos
  cosas ayuda a un mount de streaming. `tb_seed_torrents` lo cambia para un
  operador cuyo tracker privado cuenta el ratio: `never` envía `seed=3` (el
  valor por defecto), `always` envía `seed=2` y `auto` deja el campo fuera.
  La propia descripción de TorBox sobre el campo es "1 is auto. 2 is seed. 3 is
  don't seed. Optional. Default is 1, or whatever the user has in their
  settings. Overwrites option in settings", así que cualquier valor enviado,
  incluido `1`, reemplaza el ajuste de Seeding de la cuenta, y solo un campo
  ausente permite que ese ajuste se aplique. El mismo modo va en los tres
  caminos de añadido: el añadido por magnet, el añadido solo-cacheado y la
  subida de `.torrent`. Con seeding activado, los torrents terminados conservan
  sus slots, así que la reparación y los endpoints del cliente de descargas se
  quedan atascados contra el límite cuando los torrents en seeding ocupan todos
  ellos.
- **La caché nunca se comprueba antes de añadir.** `checkcached` no tiene ningún
  punto de llamada. El modo solo-cacheado (`qbittorrent.download_timeout_mins: 0`)
  era la única excepción, hasta que se cambió para que añada el torrent y vigile
  la instancia como cualquier otro backend, porque el endpoint informa si el
  contenido está en la caché de TorBox y no si esta cuenta acaba teniéndolo. Eso
  cuesta algo real en un fallo: un añadido no cacheado consume el cupo de
  60/hora, mientras que una comprobación no consumía nada. Los añadidos
  cacheados siguen bajo el presupuesto de 300/min.

## Caducidad del contenido {#content-expiry}

El contenido Pro caduca a los 30 días. Los torrents caducados llegan desde la API como `expired` o `reported missing`, pero siguen devolviendo `download_finished: true` con `download_present: false`.

Si solo se mira `download_finished`, se montaría un torrent entero cuyos enlaces dan todos 404.

zurg asigna ambas formulaciones al estado `error`, y `Capabilities.ContentExpires` marca eso como algo normal para el backend y no como un fallo.

**Los dos booleanos no bastan por sí solos para saber que los datos se han perdido.** Una descarga sana no cacheada devuelve `download_finished: true` con `download_present: false` durante los últimos 9,6 segundos de su vida, mientras pasa por `processing`, `downloading` y `uploading`. Se midió el 2026-08-30 con un sondeo de 0,5 segundos y se documentó en `docs/torrent-lifecycle.md`. Antes, zurg interpretaba esa combinación como muerte sin importar la cadena de estado, y cualquier instancia con `delete_error_torrents: true` borraba ese torrent a mitad de la descarga. Ese día se eliminaron cinco torrents de prueba de esa forma. Ahora la regla estructural solo decide cuando la respuesta no trae ningún `download_state`. Un texto de estado que este código no conoce se trata como trabajo en curso, porque `processing` era uno de esos textos hasta que se midió.

Una lectura que aun así llega a uno de esos archivos ahora cuesta más de una llamada. Como la ruta de servicio trata un 404 en una URL de entrega generada como un enlace revocado y no como un archivo que falta (que es lo que es en Real-Debrid, cuyos códigos mueren cuando se borra su fila de descargas), antes de rendirse vuelve a resolver el enlace. Así, un archivo caducado de TorBox gasta hasta cuatro llamadas a `requestdl` por lectura en lugar de una. Está acotado por lectura, y el listado ya ha marcado el torrent como `error`, así que nada recorre una biblioteca caducada a ese ritmo; pero un cliente que martillee una ruta caducada pagará cuatro veces lo que pagaba antes.

### Qué hace zurg {#what-zurg-does-2}

**Nada vuelve a añadir por su cuenta los torrents de un backend que expira contenido.** Reparar arregla un torrent roto volviendo a añadir su magnet. Eso es reparar en un backend que conserva el contenido, pero es volver a descargar en uno que lo expira. Ejecutar eso con un temporizador sobre toda una biblioteca es el comportamiento que TorBox menciona primero entre los motivos por los que se marca una cuenta: "excessive transfer retention (using tools to artificially keep transfers active)". Además, cada re-add de algo no cacheado es también una transferencia entrante que cuenta contra el límite del plan.

Por eso el barrido periódico omite los torrents cuya copia reparable está en un proveedor que declara `ContentExpires`. Siguen rotos y visibles. El botón de reparar del panel sigue funcionando, y una release que también está en Real-Debrid se repara desde esa copia como de costumbre. La diferencia está en quién lo pidió, no en lo que se rompió.

## Uso y el sistema antiabuso {#usage-and-the-abuse-system}

TorBox no vigila las peticiones. Lo que mide son los bytes transferidos en una ventana móvil de 15 días, comparados con un umbral calculado a partir del percentil 99 de cada nivel de plan. Avisa tres veces (cada aviso rota la clave de API) y banea a la cuarta.

Los mínimos publicados, es decir, el valor más bajo al que pueden bajar esos umbrales dinámicos:

| Plan | Mínimo |
|---|---|
| Free | 5 TB/mes |
| Essential | 10 TB/mes |
| Standard | 20 TB/mes |
| Pro | 30 TB/mes |

Cuentan ambos sentidos: los añadidos no cacheados que entran y todo lo que TorBox envía hacia fuera, ya sea a tu dispositivo o de vuelta al swarm. Los añadidos cacheados no cuentan. El cómputo es exacto al byte, así que un archivo leído solo en parte cuesta solo lo que se leyó.

**`cooldown_until` en `/user/me` no es uno de esos avisos, y tomarlo como tal te costará un día.** Comprobado el 2026-08-12 en una cuenta de plan 2 con un cooldown activo y recién puesto (faltan 24 h, `updated_at` de hace un minuto): `/user/me`, `checkcached` y `mylist` respondieron todos `200 success:true`, el `PROPFIND` de WebDAV devolvió `207`, y una lectura por rango `bytes=0-0` devolvió **`206` con un `Content-Range` correcto en 14.1 s**. Ninguna capa rechazó el servicio. El tráfico total de esa cuenta era de 14.1 GB frente a un mínimo de 30 TB/mes, así que era un cooldown por tasa de API, no un strike por ancho de banda. Lo que distingue un caso del otro es la **clave**: un aviso real la rota y entonces todos los endpoints devuelven `AUTH_ERROR`, mientras que un cooldown con la clave intacta no tiene ningún efecto observable. Y como `checkcached` puede indicar que un release está en caché cuando TorBox en realidad no lo va a servir, **la lectura por rango es la única prueba que demuestra que se sirve**. Comprueba la ruta de bytes antes de concluir que TorBox no es utilizable.

Fuente: [El sistema de abuso de TorBox](https://support.torbox.app/en/articles/10336778-the-torbox-abuse-system).

### Qué hace zurg {#what-zurg-does-3}

- **Los torrents añadidos nunca se siembran por defecto**, así que no se cobra nada por lo que sale hacia fuera, en el caso del contenido que zurg solo lee. `tb_seed_torrents: always` (o `auto` en una cuenta configurada para sembrar) es el único ajuste que cambia esto, y su subida se cobra como cualquier otra.
- **El uso se muestrea y se calcula por diferencia.** La API no publica una cifra acumulada, solo un contador histórico en `/user/me`, así que el refresco de la cuenta guarda ese contador cada 30 minutos en `data/torbox_usage.json` y calcula las diferencias entre muestras. Si una cifra de los últimos 30 días supera el 80 % del mínimo del plan, se registra una advertencia. Esa advertencia es precisamente el objetivo del muestreo: el panel solo muestra lo que zurg proxyó por sí mismo, nunca estas diferencias. Una instalación nueva no tiene historial y lo indica, en lugar de mostrar un cero tranquilizador.
- **Una clave rechazada se notifica como una posible advertencia de abuso**, no como un error de configuración ni como un fallo del contenido. La rotación de claves es justo la forma en que TorBox envía esas advertencias, y tratarla como un fallo llevaría toda la biblioteca a reparación.

## Deliberadamente sin mapear {#deliberately-unmapped}

An `download_state` no reconocido se reporta como `downloading`, nunca como `error`.
Con `delete_error_torrents` activado, un estado de error hace que zurg elimine el
torrent de la cuenta, así que un estado que TorBox introduzca después de escribir
este código no debe poder provocar borrados.
