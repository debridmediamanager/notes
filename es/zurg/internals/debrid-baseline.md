# La base de referencia del debrid {#the-debrid-baseline}

Cuánto cuesta zurg y qué tan rápido se siente en la ruta **debrid**: Real-Debrid, AllDebrid
y TorBox. Aquí no hay ningún competidor. El contendiente es una versión posterior de zurg, y este archivo
es lo que tiene que superar.

- **Build bajo prueba:** `23869fa4` (`2026.08.18.0140-nightly-48-g23869fa4`)
- **Medido:** 2026-08-19, en `zen` (2 núcleos, 7.6 GB, Ubuntu 22.04)
- **Equipo de pruebas:** `scripts/dbench/`, desplegado en `~/dbench` en zen

## Cómo leerla {#how-to-read-it}

Tres proveedores tampoco son tres competidores. Sus bibliotecas difieren en dos órdenes de magnitud: 3416 torrents en Real-Debrid, 479 en TorBox, 14 en AllDebrid. Por eso, un tiempo absoluto de construcción en frío dice más sobre la cuenta que sobre zurg. Todo número que depende del tamaño se da también por torrent, y la comparación que realmente importa es siempre **esta compilación contra la siguiente en la misma cuenta**.

Lo que sí es comparable entre proveedores es la *forma* del coste: cuántas llamadas a la API necesita un backend por torrent, si paga o no la verificación de enlaces, y si su sondeo de cambios es una página o un token.

## Configuración {#configuration}

Cada instancia ejecuta un proveedor, en su propio puerto, con su propio directorio de datos. Las desviaciones de los valores predeterminados incluidos son solo las que exige el aislamiento:

| Setting | Bench | Why |
|---|---|---|
| `host` / `port` | `127.0.0.1`, 9991-9994 | cuatro instancias en un mismo host |
| `providers` | uno por instancia | atribuir el coste a un backend |
| `rclone_enabled` | `false` | medido por HTTP, nunca a través de FUSE |
| `directories` | un `all`, sin filtros | el coste del listado pasa a depender del tamaño de la biblioteca |
| `enable_repair` | `false` | Otra zurg se cargó con la misma cuenta de TorBox, y solo una instancia puede reparar una cuenta |

Todo lo demás se deja en el valor predeterminado incluido *a propósito*, incluidos dos que afectan mucho a los números y que son en sí mismos hallazgos:

- `log_level: DEBUG` — el valor predeterminado incluido (`pkg/logutil/factory.go`).
- `torrents_rate_limit_per_minute: 75` — el valor predeterminado incluido, y la restricción que más limita una compilación en frío de Real-Debrid.

## Corpus

Doce versiones, los **mismos infohashes en las tres cuentas**, así que cualquier diferencia entre proveedores viene del proveedor y no del archivo. Los tamaños van desde un episodio de 1.5 GB hasta un pack de remux de 334 GB; las formas incluyen películas de un solo archivo, packs de temporada y un pack de serie de 349 archivos. La entrada 0 — `The Shawshank Redemption (1994) DS4K`, 7.31 GB, un solo archivo — es el sujeto de streaming para las fases de latencia y throughput.

Armar el corpus es la parte complicada y vale la pena dejarla anotada. La caché de TorBox se solapa con la biblioteca de Real-Debrid en unos 2% (3 aciertos en 136 consultas), así que el corpus tiene que manejarse desde el lado de TorBox y no desde el de Real-Debrid. AllDebrid no tenía nada en caché y aceptó los magnets al instante, 14 de 16. Real-Debrid necesitó entre 20 y 45 s entre cada añadido por el límite de 451, y rechazó dos: uno es el bloqueo determinista de nombres documentado (`Supergirl…WEB-DL…`, rechazado en el primer intento limpio tras un periodo de calma de tres minutos), y el otro siguió bajo throttling.

## Medición del coste de la API {#measuring-api-cost}

zurg no lleva un contador de peticiones salientes, y `log_requests` omite a propósito dos endpoints de Real-Debrid: `torrents/activeCount` y `torrents?limit=1&…`. Entre los dos forman todo el sondeo de detección de cambios. Si contáramos desde el log, el coste en reposo de Real-Debrid saldría como cero.

Por eso el conteo se hace desde fuera del proceso. mitmproxy termina el TLS, un addon escribe una línea JSONL por petición, y la instancia se arranca con `HTTPS_PROXY` y `SSL_CERT_FILE` apuntando a la CA interceptora. El cargador x509 de Go respeta `SSL_CERT_FILE`, así que la confianza queda limitada a ese único proceso y no se modifica nada en el host. Las peticiones se clasifican como `api`, `nettest`, `content` u `other`.

El proxy está en la ruta de las peticiones, así que solo se usa en las fases de coste de API; las fases de tiempos van directas. En TorBox, donde toda la build son cuatro llamadas, una ejecución con proxy y otra directa dieron 3,0 s y 4,0 s. A esta escala, el proxy queda dentro del margen de ruido.

## Resultados {#results}

Todos los números son del build `23869fa4` en zen, 2026-08-19. La latencia y el throughput salen de una sola ejecución intercalada sobre el mismo archivo de 7.31 GB: mismo infohash en las tres cuentas, y `ffprobe` reporta la misma duración de 8552.574 s por cada una, así que el contenido es realmente idéntico byte a byte.

### Construcción de biblioteca en frío {#cold-library-build}

Vaciar cachés a una biblioteca compilada. Este es el único número que no se puede comparar
entre proveedores, porque las cuentas difieren en dos órdenes de magnitud, así que fíjate en
las columnas por torrent.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Torrents | 3,316 | 14 | 479 |
| Time to compiled | **1,774 s** | 1.0 s | 3.0 s |
| Seconds per torrent | 0.535 | 0.071 | 0.006 |
| API requests | **7,442** | 7 | 4 |
| API requests per torrent | **2.24** | 0.50 | 0.008 |
| Non-2xx responses | **756 (10.2%)** | 0 | 0 |
| API bytes received | 2.87 MB | 27.9 KB | 298 KB |
| Startup network-test requests | 88 | 88 | 88 |
| Peak RSS | 77 MB | 26 MB | 52 MB |
| CPU seconds | 17.5 | 0.04 | 0.5 |

Las 7,442 llamadas de Real-Debrid se desglosan en 3,414 `torrents/info`, una por torrent,
que no se puede evitar sin `ListIncludesFiles`, y **3,992 `unrestrict/link`**, que es
la verificación proactiva de enlaces. Es el único backend con `StoredLinksCanRot: true`,
así que es el único que paga este coste. TorBox responde a todo el escaneo con un único
`mylist`, que es lo que te da `ListIncludesFiles`.

La compilación de Real-Debrid se ejecutó dos veces, y las dos son lo bastante parecidas
como para que una futura mejora de la compilación no se confunda con ruido:

| | run 1 | run 2 |
|---|---|---|
| Time to compiled | 1,774.5 s | 1,759.5 s |
| API requests | 7,442 | 7,391 |
| `unrestrict/link` | 3,992 | 3,933 |
| Non-2xx | 756 | 699 |
| CPU seconds | 17.5 | 16.1 |

#### Cuáles son los fallos {#what-the-failures-are}

El segundo run guardó su log de flujo, así que los 699 tienen un desglose:

| Estado | Cantidad | Endpoint |
|---|---|---|
| 429 | 589 | `unrestrict/link` |
| 503 | 85 | `unrestrict/link` |
| 404 | **22** | `downloads/delete/{id}` |
| 451 | 3 | `unrestrict/link` |

Son dos problemas distintos, y ninguno de los dos es "el proveedor andaba inestable":

- **589 rechazos por rate limit**, todos en `unrestrict/link`. `api_rate_limit_per_minute`
  viene por defecto en 250 y no mantiene unrestrict dentro de lo que Real-Debrid realmente
  permite, así que aproximadamente el 8% del build en frío son rechazos y reintentos.
- **22 de 23 llamadas a `downloads/delete` devolvieron 404.** La limpieza que debería
  equilibrar los 3.992 unrestricts no solo es rara, sino que falla cada vez que se ejecuta:
  está borrando ids que no existen. Cada unrestrict crea una entrada persistente en la
  lista de downloads de la cuenta, y después de estos escaneos la cuenta de prueba tenía
  **12.469**.

Hay un número que cambió entre runs y que todavía no tiene explicación: las sondas HEAD
contra `*.download.real-debrid.com` fueron 88 en el primer build y **3.426** en el segundo
(alrededor de una por torrent). Coincide con que la lista de downloads creció, y el segundo
run también pidió `/downloads` ocho veces frente a la única vez del primero, pero eso es una
correlación y no una causa. Vale la pena aclararlo antes de optimizarlo.

### Reinicio en caliente {#warm-restart}

The cold cost is genuinely one-time.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Time to compiled | 4.0 s | 1.0 s | 2.0 s |
| API requests | 17 | 6 | 4 |
| Network-test requests | 8 | 0 | 0 |
| Peak RSS | 77 MB | 27 MB | 39 MB |

1,774 s se convierte en 4.0 s, y 7,442 llamadas se convierten en 17.

### Estado estable en reposo {#idle-steady-state}

Diez minutos de una biblioteca cargada sin hacer nada. El ranking lo define lo barato que resulta pedirle cada backend, y es la mejor ilustración de por qué existe `LibraryFingerprinter`.

| | API calls/min | API bytes/min | CPU s / 10 min | Peak RSS | Qué envía |
|---|---|---|---|---|---|
| AllDebrid | **4.0** | **867** | 0.20 | 28 MB | un delta de Live Mode por sondeo, vacío si no hay cambios |
| TorBox | 7.9 | 43.6 KB | 0.33 | 53 MB | pagina `mylist` — sin delta feed, sin validadores de caché |
| Real-Debrid | 11.4 | 59.8 KB | 0.43 | 85 MB | `torrents?limit=1` + `activeCount`, más `/downloads` |

Real-Debrid gasta 32 de sus 114 llamadas en volver a listar `/downloads`, la misma lista que la compilación en frío llegó a 12,469 entradas.

Esta tabla también es la razón por la que el conteo se toma a través de un proxy y no desde `log_requests`: 80 de las 114 llamadas inactivas de Real-Debrid son los dos endpoints que `ShouldSkipLogging` suprime, así que el registro habría informado de que su coste en reposo era prácticamente cero.

### Listado {#listing}

No es un cuello de botella en ningún lugar, con ningún tamaño de biblioteca.

| | Real-Debrid (3,312) | AllDebrid (14) | TorBox (479) |
|---|---|---|---|
| PROPFIND de toda la biblioteca, Depth 1 | 26 ms / 1.17 MB | 1 ms / 5.1 KB | 7 ms / 172 KB |
| Índice HTML | 14 ms / 645 KB | 1 ms / 2.4 KB | 3 ms / 90 KB |
| PROPFIND de un lanzamiento, Depth 1 | 1 ms | 11 ms | 3 ms |

### Dale a play {#press-play}

Un archivo de 7.31 GB, cada lectura en una instancia recién iniciada.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Apertura en frío, 1 MB | 1.294 s | **0.476 s** | 0.565 s |
| Tiempo hasta el primer byte, 64 MB | **0.158 s** | 0.203 s | 0.208 s |
| Scrub, mediana de 8 | 0.343 s | **0.259 s** | 0.356 s |
| Relectura en caliente, 64 MB | 2.065 s | 2.163 s | **1.960 s** |
| ffprobe | 1.98 s | 1.34 s | **0.99 s** |
| RSS | 75 MB | **30 MB** | 50 MB |

**La relectura en caliente tarda lo mismo que la lectura en frío.** En la ruta de Usenet, una lectura repetida vuelve en 0.05-0.17 s desde la caché LRU de 512 MB. Aquí cuesta una descarga completa, porque la ruta de debrid hace de proxy hacia el CDN y no guarda nada en caché. Con `rclone_enabled: false` esto es zurg por su cuenta. En una instalación normal, la caché VFS de rclone absorbe el problema. Pero como propiedad de zurg en sí, no existe ninguna ruta en caliente.

### Rendimiento {#throughput}

256 MB de lecturas secuenciales, tres repeticiones, con el orden rotando entre repeticiones.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Media MB/s | 25.75 | 27.21 | **35.96** |
| Mín-máx MB/s | 20.09-29.57 | 17.52-32.21 | **34.31-37.57** |
| CPU s por GB | 7.8 | **5.3** | 7.9 |
| TTFB mediana | 1.023 s | **0.267 s** | 0.489 s |
| RSS máximo | 88 MB | **29 MB** | 55 MB |
| Lecturas completadas | 3/3 | 3/3 | 3/3 |

TorBox es el más rápido y, con mucha diferencia, el más estable; los otros dos oscilan un 40% entre repeticiones. La TTFB mediana de Real-Debrid bajo carga es cuatro veces la de AllDebrid.

### Adónde va realmente la apertura en frío {#where-cold-open-actually-goes}

`apiref.py` mide la parte del proveedor — la llamada que convierte un archivo almacenado en una URL descargable, y el primer byte de esa URL — con zurg fuera del camino. Se ejecutó dos veces; la primera ejecución es anterior al arreglo de AllDebrid, así que esa fila tiene una sola muestra.

| | resolve | CDN TTFB | provider total | zurg cold open | zurg's share |
|---|---|---|---|---|---|
| Real-Debrid, run 1 | 0.133 s | 0.267 s | 0.400 s | 1.294 s | **0.89 s** |
| Real-Debrid, run 2 | 0.157 s | 0.383 s | 0.540 s | 1.294 s | **0.75 s** |
| AllDebrid | 0.139 s | 0.333 s | 0.472 s | 0.476 s | 0.00 s |
| TorBox, run 1 | 0.260 s | 0.277 s | 0.537 s | 0.565 s | 0.03 s |
| TorBox, run 2 | 0.270 s | 0.381 s | 0.651 s | 0.565 s | ~0 |

Las cifras del proveedor y las de zurg provienen de momentos distintos, así que la resta es orientativa y no exacta. El patrón se mantiene en ambas ejecuciones: AllDebrid y TorBox no añaden prácticamente nada a lo que ya cuesta el propio proveedor, mientras que Real-Debrid añade entre 0.75 y 0.89 s. Esa diferencia es lo más claro que hay que atacar.

### Los tres proveedores en una sola instancia {#all-three-providers-in-one-instance}

El instancia fusionada tiene todas las cuentas a la vez, y el corpus está pensado para estar en las tres, así que ejercita el camino en el que una misma release la tienen varias cuentas.

| | Solo Real-Debrid | Las tres fusionadas |
|---|---|---|
| Torrents vistos | 3,316 | 3,781 |
| Releases únicas | 3,318 | 3,778 |
| Tiempo hasta compilado | 1,774 s | 1,775 s |
| Peticiones a la API | 7,442 | 7,491 |
| RSS máximo | 77 MB | 82 MB |
| PROPFIND de toda la biblioteca | 26 ms / 1.17 MB | 23 ms / 1.34 MB |

Añadir TorBox y AllDebrid a una instancia de Real-Debrid sale casi gratis: 465 torrents más por 49 peticiones a la API más y 5 MB más de RSS, y sin tiempo medible. La fusión es real: 3,809 torrents repartidos entre las tres cuentas por separado se quedan en 3,781 aquí, es decir, el corpus pasa de tener tres copias a tener una sola.

### Detección de añadidos y borrados {#add-and-delete-detection}

¿Cuánto tarda desde que hay un cambio en el proveedor hasta que el montaje coincide?

| | Eliminación detectada | Adición detectada |
|---|---|---|
| Real-Debrid | 18.7 s | 12.7 s |
| AllDebrid | 16.5 s | 14.4 s |

Los dos están dentro de un ciclo de `check_for_changes_every_secs` más un refresco, así que ninguno espera a `library_resync_every_mins`. No probamos TorBox: el release de prueba está fijo en esa cuenta y borrarlo no se puede deshacer sin volver a añadirlo, lo que quizá no esté en caché.

### Caída del proveedor, CDN arriba {#provider-outage-cdn-up}

`ca/outage.py` hace que toda llamada a la API de un proveedor devuelva 503 mientras las peticiones de contenido siguen pasando, y luego se inicia zurg contra él.

| | Lectura previa | Biblioteca compilada durante la caída | Lectura durante la caída |
|---|---|---|---|
| Real-Debrid | 206, 1.60 s | nunca (180 s) | timeout a los 120 s |
| AllDebrid | 206, 0.44 s | nunca (180 s) | timeout a los 120 s |
| TorBox | 206, 1.53 s | nunca (180 s) | 400 en 0.035 s |

**Iniciar zurg mientras su proveedor está caído produce un montaje vacío.** Ese es el escenario que más importa en la operativa: un host se reinicia durante una racha de 503 de Real-Debrid, y es justo la condición que destruyó decenas de miles de elementos de Plex en `fun` en agosto, donde un montaje momentáneamente vacío durante un escaneo se interpreta como "todos los archivos fueron borrados". La protección para eso está en Plex (`autoEmptyTrash 0`), no en zurg.

Real-Debrid y AllDebrid, además, hacen que el lector espere hasta agotar su propio timeout en lugar de fallar rápido; TorBox responde en 35 ms.

### Un 503 transitorio deja las releases como carpetas vacías {#a-transient-503-leaves-releases-as-empty-folders}

El defecto más claro de esta ejecución, y lo encontramos por casualidad.

De los 3.316 torrents de una construcción en frío con Real-Debrid, **85 respuestas fueron 503** y
**84 torrents acabaron en `broken_torrent`**. Un release en ese estado sigue apareciendo
en el montaje, pero su directorio está **vacío**. Lo comprobamos con PROPFIND en dos de ellos, y ambos tenían
10 y 3 archivos seleccionados en su registro guardado, pero no servían ninguno.

No se soluciona solo. El banco funciona con `enable_repair: false`, y esos releases
seguían rotos más de una hora y varios reinicios después.

Activar la reparación (el valor por defecto del paquete) sí les hace pasar, pero despacio. Con una pasada
lanzada a mano:

| Tiempo transcurrido | Rotos | En reparación |
|---|---|---|
| 0 min | 85 | 0 |
| ~2 min | 77 | 2 |
| ~15 min | 73 | 4 |

Doce releases en un cuarto de hora, y el ritmo baja después de los primeros minutos. Con esa tendencia,
una construcción en frío completa tarda más de una hora en limpiar sus roturas, y cada release que
no se llega a tocar es una carpeta vacía durante todo ese tiempo.

Así que la gravedad depende de un ajuste:

- Con la reparación activada (por defecto), un 503 durante un escaneo cuesta a un release sus archivos hasta que una pasada de reparación llega a él, del orden de una hora para una biblioteca completa.
- Con la reparación desactivada, el release es una carpeta vacía indefinidamente.

TorBox tiene una versión más grave de esto. Reporta `StoredLinksCanRot: false`, así que el refresco nunca vuelve a verificar sus enlaces. No hay ningún camino que limpie un estado roto sin pasar por la reparación. El único release de TorBox marcado como roto durante la prueba de caída seguía roto 68 minutos y varios reinicios después, mientras que su proveedor lo reportaba como `cached`, `download_present`, con un archivo, 7.31 GB.

### Integridad de lectura {#read-integrity}

Una lectura de AllDebrid en la primera pasada de rendimiento devolvió 263,798,425 bytes para un rango de 268,435,456 bytes, con un 206 y sin ningún error. **No se reprodujo**: ocho repeticiones en Real-Debrid y ocho en AllDebrid devolvieron el rango completo en todos los casos. Se registró como un caso aislado y no como un defecto, pero conviene tenerlo en cuenta.

## Bajo la carga de Plex {#under-plexs-load}

Todo lo anterior era un lector a la vez, y eso no es como se comporta un servidor de medios.
Plex escanea (miles de archivos, un poco de cada uno) y Plex transmite, y las dos cosas se solapan. Estas fases miden el montaje bajo ambas condiciones.

**Lee las cifras agregadas como una propiedad de zen, no de zurg.** Todos los destinos se estancan en 73-78 MB/s sin importar el proveedor ni el modo, que es el enlace del host. Lo que sí se puede generalizar son las *tasas de finalización* y las formas de fallo de cada proveedor; el techo es local.

### Varios lectores, distintos archivos, un proveedor {#multiple-readers-different-files-one-provider}

96 MB por stream, archivos distintos.

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 1 | 44.8 | 52.1 | 45.6 | 51.8 |
| 2 | 72.3 | 63.5 | 71.4 | 69.8 |
| 4 | 73.7 | 64.2 | 74.6 | 70.2 |
| 8 | 73.6 | 73.4 | 65.5 | 75.1 |
| 12 | 77.1 | 73.8 | 76.3 | 77.1 |

MB/s agregados. La tubería se llena con dos streams; a partir de ahí, más lectores se reparten el mismo ancho de banda. La mediana por stream baja de unos ~45 MB/s con uno a unos ~8 MB/s con doce.

La columna de completados es la interesante:

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 4 | 4/4 | **2/4** | 4/4 | 4/4 |
| 8 | 8/8 | **3/8** | 8/8 | 8/8 |
| 12 | 10/12 | **4/12** | 9/12 | 10/12 |

**AllDebrid deja de completar lecturas con cuatro archivos distintos concurrentes.** Los bytes siguen fluyendo (su agregado se mantiene en el techo del host), pero los streams individuales no terminan, y la mediana por stream cae a cero con ocho y doce, con medianas de TTFB por encima de 3 s. Todo lo demás aguanta hasta doce, donde los cuatro pierden uno o dos.

> **Retractado el 2026-08-23. No es un límite de concurrencia del proveedor.** Volvimos a probar directamente contra las APIs con bitrates de reproducción limitados por tasa, en lugar de a máxima velocidad a través de zurg. AllDebrid resolvió **4/8/12/16/24 enlaces concurrentes distintos al 100%** y sostuvo **24/24** streams en vivo. Los fallos de arriba se debieron a **tres hosts CDN de AllDebrid con ruta nula**: `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`, todos resolviendo a `0.0.0.0` y acaparando el **15.6% de los enlaces resueltos**. El primero es el mismo host registrado como enlace muerto puntual más abajo en este documento; no es un caso aislado.
>
> Un host muerto solo falla cuando su archivo está en el lote, así que el número de fallos sube con N y tiene exactamente la forma de un techo de concurrencia. **Cualquier prueba que vaya sacando más archivos distintos a medida que sube reproducirá este falso resultado.**
>
> La columna completa de completados aquí está limitada por el método por la misma razón: estas pruebas tiraron a máxima velocidad sobre un enlace saturado de 73–78 MB/s, así que lo que mide es **reparto de ancho de banda, no un límite del proveedor**. Los techos reales por host, todos no documentados, son Real-Debrid **32** (cortado en la capa TCP), AllDebrid **32** (HTTP 429), TorBox **20** por host `nexus-NNN` (HTTP 429, por host y no por IP), y no se encontró techo para Premiumize en 64.
>
> Una salvedad para no leer de más en la retractación: un host con ruta nula falla en ~0.1 s, mientras que las medianas de TTFB de arriba superan los 3 s. Es un fallo lento con otra firma, así que probablemente también hubo inanición de ancho de banda. Ambos efectos apuntan lejos de un tope del proveedor.
>
> **La solución que esto implica:** tratar un fallo a nivel de conexión en un host CDN de AllDebrid como reintentable **volviendo a desbloquear el enlace**; un nuevo `/link/unlock` devuelve un host distinto, en lugar de reducir la concurrencia. Una búsqueda DNS que rechace `0.0.0.0` detecta todos los casos vistos aquí y no cuesta nada.

### Varios lectores, un mismo archivo {#multiple-readers-one-file}

Mismos niveles, un solo archivo, distintos desplazamientos: la forma de lectura anticipada más búsqueda.

| streams | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| 4 | 4/4 | 4/4 | 4/4 |
| 8 | 8/8 | 8/8 | 8/8 |
| 12 | 10/12 | 9/12 | 10/12 |

AllDebrid está **bien** aquí: 4/4 y 8/8, mientras que con archivos distintos fue 2/4 y 3/8.
Esa inversión es el diagnóstico: su límite no es el ancho de banda ni un tope por torrent,
sino la **resolución de enlaces** concurrente. Con archivos distintos hay desbloqueos distintos; un solo archivo se resuelve una vez y después solo transmite.

> **Retractado 2026-08-23**: la inversión tiene una explicación más simple. Los archivos distintos usaban hosts CDN distintos, y tres de los de AllDebrid estaban enrutados a null; un solo archivo se resuelve en un host y funciona o no funciona. La resolución de enlaces en sí se midió sin problemas con 24 concurrentes. Consulta la nota de arriba.

### Varios lectores en distintos proveedores {#multiple-readers-across-different-providers}

Este es el caso con varios proveedores mezclados, y necesita un corpus que el caso emparejado no puede ofrecer. Como la instancia fusionada sirve una versión de varias cuentas desde `Sources[0]`, cada lectura del corpus emparejado termina en Real-Debrid. Así que el pool aquí es *exclusivo* de cada proveedor: 8 archivos que solo tiene Real-Debrid, 7 que solo tiene AllDebrid y 8 que solo tiene TorBox.

| streams (por proveedor) | MB/s agregados | completados | RD | AD | TB |
|---|---|---|---|---|---|
| 3 (1 cada uno) | 55.3 | 2/3 | 28.8 | — | 27.9 |
| 6 (2 cada uno) | 66.9 | 5/6 | 16.1 | 13.3 | 21.5 |
| 12 (4 cada uno) | 75.9 | 11/12 | 7.4 | 8.4 | 9.0 |

Las columnas por proveedor son medianas por stream en MB/s.

Las lecturas en cuentas distintas sí se ejecutan en paralelo de verdad, pero llegan al mismo techo de 76 MB/s del host que un proveedor alcanza por sí solo. **En este host, mezclar backends no da más ancho de banda.** Si lo da en otro sitio depende de tener un enlace más grande del que un proveedor puede llenar, y zen no lo tiene. Lo que sí aporta es disponibilidad, y solo en parte, como muestra la sección de failover de abajo.

El único fallo constante es un archivo de AllDebrid cuyo hostname del CDN, `l4m5n6.debrid.it`, se resuelve a **0.0.0.0**. Es AllDebrid el que entrega un enlace muerto, no zurg, pero zurg gasta unos 4 s en tres reintentos antes de devolver un 500, y como el archivo no está en ninguna otra cuenta, no hay a qué recurrir.

### Failover: solo desde una dirección {#failover-only-from-one-direction}

Como la instancia fusionada no puede repartir la carga, lo que se supone que aporta es la supervivencia cuando una cuenta falla. `ca/cdnfail.py` bloquea el CDN de una sola cuenta y deja intactas todas las APIs y las demás cuentas, así que la biblioteca sigue cargando y solo se ven afectados los bytes. Los releases leídos son el corpus de pruebas emparejado: las tres cuentas tienen todos ellos.

| CDN caído | lecturas servidas | qué hizo la lectura |
|---|---|---|
| Real-Debrid | 2/2 | cambió a AllDebrid, 0.6 s |
| AllDebrid | **0/3** | un intento en AllDebrid, 503, y luego **500 al cliente en 0.1 s** |

**La conmutación por error solo ocurre cuando la cuenta que falla es Real-Debrid**, y la razón es una capacidad que los otros backends no activan. Refresh solo verifica los enlaces de forma proactiva cuando `StoredLinksCanRot` es true, y eso ocurre solo con Real-Debrid:

```
Link verification failed during refresh for /A.Business.Proposal…: (code: 503)
```

Eso es lo que degrada la fuente, tras lo cual las lecturas pasan a otra cuenta sin problemas. A AllDebrid y TorBox nunca se les sondea, así que un CDN caído en cualquiera de los dos nunca se detecta, la fuente nunca se degrada y cada lectura de ese release devuelve 500, mientras dure la situación.

Hay otras dos cosas que esto muestra:

- **La ruta de lectura no tiene ningún respaldo en línea.** Un 503 del CDN de la cuenta elegida se convierte directamente en un 500 para el cliente en 0.1 s; las otras cuentas que tienen el mismo archivo no se prueban. La recuperación depende por completo del trabajo en segundo plano de Refresh, así que incluso en el caso de Real-Debrid hay una ventana en la que las lecturas fallan.
- Es el mismo mecanismo que falta detrás del release de TorBox que estuvo en `broken_torrent` durante 68 minutos. Nada vuelve a verificar un enlace de TorBox o AllDebrid, así que nada limpia un estado malo ni detecta cuando uno se ha recuperado.

### Un enlace muerto desde el proveedor {#a-dead-link-from-the-provider}

Un archivo de AllDebrid del pool exclusivo falló todas las veces que se intentó, en cada ejecución de escaneo y en cada ejecución de lector mixto. Su nombre de host del CDN se resuelve a una ruta nula:

```
$ getent hosts l4m5n6.debrid.it
::              l4m5n6.debrid.it
0.0.0.0
```

AllDebrid entregó un enlace que apunta a `0.0.0.0`. Esa parte es cosa del proveedor, no de zurg. Lo que le toca a zurg es lo que hace al respecto: tres intentos en unos 4 s y luego un 500. El archivo no está en ninguna otra cuenta, así que no había a qué recurrir, pero el resultado del failover de arriba indica que tampoco habría recurrido a otra opción.

> **2026-08-23: no es un solo host, ni un solo archivo.** Tres nombres de host del CDN de AllDebrid estaban en ruta nula a la vez: `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`. Representaban **5 de 32 enlaces en una muestra y 4 de 32 en otra, con contenido no relacionado**. AllDebrid sigue entregando esos mismos hosts muertos para archivos distintos, y seguía haciéndolo días después de esta ejecución. Es un agujero persistente en su flota, y es lo que produjo el hallazgo de concurrencia que se retiró más arriba.
>
> Tres intentos y un 500 es la respuesta equivocada. **Mejor volver a desbloquear**: `/link/unlock` devuelve un host distinto. Y haz una comprobación previa con una búsqueda DNS que rechace `0.0.0.0`, que detecta todos los casos observados sin ningún coste.

### Escaneo {#scanning}

`ffprobe` sobre todo el pool mixto de 23 archivos, que es la forma de un análisis de Plex.

| concurrency | files/min | per-file median | per-file max | CPU s |
|---|---|---|---|---|
| 1 | 43.7 | 1.16 s | 3.11 s | 2.22 |
| 4 | 112.0 | 1.67 s | 4.19 s | 1.29 |
| 8 | 142.3 | 1.87 s | 6.67 s | 1.16 |

El escaneo se paraleliza muy bien: 3,3x de un hilo a ocho, y la latencia por archivo solo sube un 60%. Para la biblioteca de Real-Debrid de 3.316 releases, eso son unos **76 minutos con un hilo y 23 minutos con ocho**, sin contar el trabajo propio de Plex.

### Streaming mientras se escanea {#streaming-while-scanning}

La situación que más hay que temer, ya que un escaneo contra un montaje momentáneamente en mal estado fue lo que costó
decenas de miles de elementos de Plex en `fun`.

| scan concurrency | stream alone | stream during scan | kept | scan wall |
|---|---|---|---|---|
| 4 | 57.7 MB/s | 66.5 MB/s | 115% | 11.8 s |
| 8 | 67.8 MB/s | 66.8 MB/s | 98.5% | 9.7 s |

**Un escaneo no deja sin recursos a un stream.** El espectador mantiene prácticamente todo su throughput, y su time-to-first-byte incluso mejora (de 1.18 s a 0.15 s) porque para entonces el enlace ya está caliente. Es el único punto en el que la ruta de debrid se comporta mejor de lo que se temía.

## Defectos que sacó a la luz esta ejecución {#defects-this-run-surfaced}

1. **Un 503 transitorio deja un release como una carpeta vacía.** 85 x 503 durante una compilación en frío dejó 84 releases en `broken_torrent`, y un release roto aparece sin archivos dentro. Con repair desactivado nunca se limpia; con repair activado solo se limpia cuando una pasada llega hasta él. En TorBox no existe ninguna ruta de re-verificación (`StoredLinksCanRot: false`), y el único release roto allí seguía roto 68 minutos después, mientras el proveedor lo reportaba como cacheado y presente.
2. **La limpieza de entradas de descarga está rota, y el coste se acumula.** 3,992 `unrestrict/link` frente a 23 `downloads/delete`, y **22 de esos 23 devolvieron 404**: la limpieza borra ids que no existen. La cuenta pasó de 12,469 entradas a **18,768** en dos compilaciones en frío más, y zurg pagina la lista completa al arrancar de 5,000 en 5,000, así que la fuga se convierte en un coste de arranque que crece con ella.
3. **589 rechazos por límite de tasa en una compilación en frío.** Todos en `unrestrict/link`, alrededor del 8% de la pasada. El valor por defecto `api_rate_limit_per_minute: 250` no mantiene unrestrict dentro del límite real de Real-Debrid. Estos y los 503 son el mismo evento que produce el defecto 1.
4. **Arrancar durante una caída del proveedor deja un montaje vacío**, y una lectura contra Real-Debrid o AllDebrid se queda colgada hasta el timeout propio del cliente en lugar de fallar rápido. TorBox responde 400 en 35 ms.
5. ~~**AllDebrid deja de completar lecturas concurrentes de archivos distintos.**~~ **Retirado el 2026-08-23; mira la nota en "Múltiples lectores, archivos distintos" más arriba.** La causa eran tres hosts CDN de AllDebrid con null-route que llevaban el 15.6% de los enlaces, no un límite de concurrencia; probado de nuevo directamente, AD resuelve 24 enlaces distintos concurrentes al 100% y sostiene 24/24 streams. El texto original se conserva abajo para el registro.

   2 de 4, 3 de 8, 4 de 12. Los mismos niveles contra un *solo* archivo están bien (4/4, 8/8), así que el límite es la resolución concurrente de enlaces, no el ancho de banda ni un tope por torrent. Cuatro archivos reproduciéndose a la vez es una tarde normal para un hogar.
6. **Un release con varias cuentas siempre se sirve desde la misma cuenta.** `File.PrimarySource` devuelve `Sources[0]`, así que la elección es la cuenta que se vio primero: verificado en 7 de 7 releases del corpus servidos por Real-Debrid, mientras AllDebrid y TorBox tenían copias idénticas. Nunca elige la cuenta más rápida ni la menos cargada.
7. **El failover funciona en una sola dirección, y nunca en línea.** Con el CDN de Real-Debrid rechazando, las lecturas pasaron a AllDebrid; con el de AllDebrid rechazando, 0 de 3 lecturas se sirvieron y cada una devolvió 500 en 0.1 s sin probar las dos cuentas que tenían el mismo archivo. Solo Real-Debrid establece `StoredLinksCanRot`, así que solo sus enlaces se re-verifican durante la actualización, y solo sus fallos degradan una fuente. Nada en la ruta de lectura prueba una segunda cuenta ante un error.
8. **La prueba de red al arrancar se ejecuta para cada backend.** 88 peticiones HEAD contra hosts de descarga de Real-Debrid en una instancia solo de TorBox y otra solo de AllDebrid, que no tienen ningún uso para el resultado.
9. **El href propio del PROPFIND de una colección da 404.** zurg emite `<d:href>/all/…</d:href>`, omitiendo el prefijo `/dav`; pedir esa ruta devuelve 404. Los hijos se emiten como hrefs relativos sin más, así que solo la entrada propia está mal. RFC 4918 quiere un href que el cliente pueda resolver, y rclone y Plex solo funcionan porque no lo usan.
10. **`user`/`user/me` se llama tres veces en cada arranque**, en frío o en caliente, tanto en TorBox como en AllDebrid.

## No son defectos, pero conviene saberlo {#not-defects-but-worth-knowing}

- **Real-Debrid no deduplica por infohash.** Si añades un magnet que ya está en la cuenta, se crea una *segunda* entrada. Por eso los 3.416 torrents se compilan en 3.318 releases únicos, y eso invalidó la primera prueba de detección de borrados: borró el duplicado que acababa de crear y concluyó que nunca se detectaba nada.
- **`torrents_rate_limit_per_minute` tiene 75 por defecto**, y es lo que limita la construcción en frío de Real-Debrid. Es un valor por defecto deliberado, no un error, pero es el número que determina los 29 minutos.

## Volver a ejecutar {#rerunning}

```bash
cd ~/dbench && ./runall.sh          # p1..p6
./p7.py adddel rd,ad && ./p7.py outage rd,ad,tb
./apiref.py rd,ad,tb                # provider-side reference latency
./report.py                         # tables
```

Nunca ejecutes dos instancias a la vez, y compara solo números de una única ejecución intercalada, porque el rendimiento de los proveedores varía mucho a lo largo de la tarde.
