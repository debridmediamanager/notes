# Cachés de lectura persistentes {#persistent-read-caches}

Las entradas importadas de NZB, Real-Debrid, AllDebrid y TorBox conservan todas su estado de biblioteca en `data/*.zurgtorrent`. Estos archivos describen la biblioteca. Las cachés de preparación de lectura y de bytes están junto a ellos, así que cambiar o borrar una caché derivada no reescribe la biblioteca ni hace perder etiquetas, nombres ni asociaciones de cuenta.

## Qué sobrevive a un reinicio {#what-survives-a-restart}

| Caché | Ubicación | Trabajo evitado |
| --- | --- | --- |
| Manifiestos de documentos NZB | `data/nzb-manifests/` | Analizar XML sin cambios para obtener nombres, tamaños, clasificación de recuperación, contraseñas y número de segmentos |
| Índices de artículos NZB | `data/nzb-index/` | Reconstruir las referencias a artículos; lo usan tanto el modo `mmap` como el modo `resident` |
| Artículos Usenet decodificados | `data/bytecache/articles/` | Descargar y decodificar con yEnc un artículo que ya se leyó |
| Diseños de archivos | `data/archive-layouts/` | Volver a leer las cabeceras del archivo para reconstruir los rangos de volúmenes, las entradas anidadas y los desplazamientos ZIP aprendidos |
| Bloques de archivo descomprimidos | `data/bytecache/decoded/` | Volver a decodificar para llegar a los rangos de bytes retenidos después de un reinicio o de un salto hacia atrás |
| Estado del proveedor | `data/provider-cache/` | Reconstruir una ventana de descargas de RD sin cambios o pedir de nuevo la tabla de regiones de un TorBox |
| Enlaces de descarga | `data/linkcache/` | Resolver de nuevo una URL que todavía es válida |

Los diseños de archivos admiten entradas RAR/ZIP almacenadas y comprimidas, fuentes anidadas,
tramos cifrados y archivos divididos compatibles. Guardan referencias a las fuentes y
desplazamientos, no lectores HTTP activos. Las URL actuales del proveedor se adjuntan al restaurar.
Los diseños incompletos con volúmenes que faltan se reconstruyen desde la fuente. Los
desplazamientos aprendidos de los payloads ZIP se guardan tras la primera lectura, sin pedir una
cabecera para cada entrada al listar un directorio.

Los manifiestos NZB se comprueban contra el tamaño del archivo de origen, su fecha de modificación
en nanosegundos y la versión del parser. `mmap` restaura los metadatos al instante y mapea el índice de
artículos cuando hace falta. `resident` carga ese índice en memoria heap. `reparse` restaura los metadatos
al instante, pero sigue analizando el XML cuando se necesitan las referencias a artículos.
Las bibliotecas existentes crean los manifiestos durante su primer escaneo con esta versión;
el guardado al arrancar se aplica en los escaneos y reinicios posteriores.

Las peticiones simultáneas de AllDebrid y TorBox para la misma cuenta y el mismo archivo no cacheado ahora
comparten una sola resolución. Cancelar a un llamador no cancela la resolución de otro. RD mantiene
su coalescencia existente. TorBox usa los nombres y tamaños que ya están en el catálogo al resolver
un archivo, en lugar de volver a pedir esos detalles.

Los registros de detalles del proveedor en `data/info/` se memorizan tras la primera decodificación JSON
por proceso. Cada reutilización comprueba la identidad del archivo, el tamaño y la fecha de modificación,
y devuelve una copia independiente. Los archivos de biblioteca y de detalles se reemplazan de forma atómica.

## Presupuestos de almacenamiento {#storage-budgets}

Estas opciones de nivel superior son opcionales, se miden en MiB y hacen efecto después de reiniciar:

```yaml
nzb_article_disk_cache_mb: 512
archive_decoded_disk_cache_mb: 512
```

Cada caché tiene 512 MiB por defecto en toda la instancia. Cero desactiva esa caché, y los valores negativos se tratan como cero. Los presupuestos cuentan los bytes de los registros, incluidas las sumas de comprobación, y no la sobrecarga de asignación del sistema de archivos. Los registros más antiguos sin usar se eliminan a medida que llegan nuevos. Si reduces un presupuesto, la caché existente se recorta durante la inicialización. Si la desactivas, los archivos que ya existen se quedan disponibles para borrarlos a mano.

La caché de artículos complementa la caché de RAM que ya existe. La caché de archivos guarda bloques decodificados de 64 KiB y complementa la ventana de RAM móvil de 64 MiB de cada decodificador. Ninguna de las dos pre-descarga la biblioteca. Una lectura fuera de los bloques decodificados guardados todavía necesita decodificar desde el principio de una entrada comprimida. La caché VFS de Rclone es independiente y sigue sirviendo rangos completos ya guardados sin entrar en estas rutas; estas cachés también benefician a las lecturas HTTP/WebDAV directas.

Una entrada comprimida solo se puede decodificar desde su principio, así que una lectura muy adentrada en ella implica descargar primero todo el archivo. zurg mantiene esa lectura durante 20 segundos y después responde `503` en lugar de dejar al cliente sin respuesta. Lo que la decodificación ya alcanzó se guarda, así que un reproductor que reintenta un salto hacia adelante llega un poco más lejos cada vez. Una lectura que se rechaza cerca del final de una entrada también inicia una decodificación en segundo plano de esa entrada, una entrada a la vez, que guarda los últimos 8 MiB de la entrada en `data/bytecache/decoded-tails/`. Después de eso, el final del archivo se lee al instante, que es lo que pide un servidor multimedia cuando analiza un archivo. Este almacén usa el mismo presupuesto que `archive_decoded_disk_cache_mb` y se apaga junto con él.

Los metadatos derivados crecen con la biblioteca y no cuentan dentro de estos presupuestos de bytes. Los escaneos de NZB eliminan los manifiestos y los índices de artículos de los documentos borrados. Las revisiones antiguas del diseño del archivo se pueden eliminar con la instancia parada; son desechables y se reconstruirán cuando haga falta.

## Validación y recuperación {#validation-and-recovery}

Los registros de metadatos nuevos y los bloques de bytes llevan sumas de comprobación. Los registros dañados y las escrituras de caché fallidas vuelven a la fuente. Los registros de artículos solo entran en la caché de disco después de una descarga completa y correcta, y se escriben después de que el artículo se haya entregado a la lectura que lo descargó, de modo que una lectura nunca espera a la caché. Si llega una ráfaga con más escrituras de artículos de las que pueden ejecutarse a la vez, se descartan los registros sobrantes en lugar de retener una lectura. Un registro descartado se vuelve a descargar la próxima vez que se necesite. La identidad de un artículo incluye la revisión del NZB, la configuración del servidor, el archivo y el segmento. La identidad de un archivo comprimido incluye las referencias de origen actuales, los tamaños, la configuración de la cuenta, la contraseña y la versión del formato. Reemplazar la fuente NZB también invalida los diseños de archivos y los bytes decodificados.

La huella digital local de la fuente asume que un reemplazo cambia el tamaño o la fecha de modificación. Deliberadamente evita calcular el hash de todo el XML en cada inicio. Para conservar ambos valores en un reemplazo, hay que eliminar las cachés derivadas asociadas.

Las instantáneas de RD solo se aceptan si son del mismo token y del mismo límite de descarga configurado, dentro de una hora, y después de que una comprobación en vivo confirme que coinciden la entrada más reciente y el total. Si la lista cambia, se lanza una reconciliación completa. Las tablas de regiones de TorBox mantienen su vida útil actual de seis horas. La vida útil de las URL de entrega y el manejo de fallos de los proveedores no cambian: un diseño que ya está abierto abre su payload antes de confirmar el éxito de HTTP, para que una URL revocada siga el camino normal de resolución y reintento.

Las mutaciones de enlaces de entrega disparan un volcado a disco agrupado aproximadamente un segundo después. El reintento cada cinco minutos y el volcado al apagar se mantienen. El reemplazo atómico evita que los lectores vean registros escritos a medias; no es una garantía de fsync frente a cortes de energía. Los archivos nuevos de caché usan el modo `0600` en Unix, porque los enlaces y los diseños de archivos cifrados pueden contener credenciales o claves derivadas. En Windows se usan las ACL del directorio que los contiene en lugar de los bits de permiso de Unix.

## Copias de seguridad con cachés calientes {#backups-with-warm-caches}

El backup por defecto sigue guardando el estado autoritativo. Para incluir también las cachés derivadas y la caché VFS de rclone local de la instancia:

```sh
./zurg backup --include-caches --out warm.zurgbackup
```

Este backup puede ser mucho más grande que uno estándar. Incluye las rutas listadas arriba, las cachés de nombres/tamaños/PAR2 de NZB y el estado de las pruebas de red. Los logs y las snapshots de la base de datos de Plex siguen excluidos. Las cachés de rclone fuera de `data/rclone-cache/` no se incluyen. Detén la instancia si te importa tener una snapshot consistente de las cachés activas.

Restaura con la instancia detenida usando `./zurg restore-backup warm.zurgbackup`. Los backups conservan las marcas de tiempo de origen en nanosegundos, así que los NZB sin cambios pueden conservar sus índices y manifiestos. Las cachés restauradas siguen pasando por las comprobaciones normales de validación y caducidad. Los backups contienen los tokens y las credenciales en caché de la configuración.

## Comprobaciones reproducibles {#reproducible-checks}

`BenchmarkParsedDocumentStartup` compara el parseo de XML con cada modo de restauración del manifiesto, usando 60 archivos y 30.000 segmentos. `BenchmarkDetailJSONRefresh` compara la ruta de lectura de JSON con el acceso memoizado para un registro de 1.000 archivos. Los dos son benchmarks locales con el sistema de archivos ya en caché, no mediciones de arranque de producción de principio a fin.

Medido en un Apple M3 Pro con tres ejecuciones de 500 ms el 2026-09-05 (mediana por operación):

| Operación | Tiempo | Bytes asignados |
| --- | ---: | ---: |
| Parsear el XML del NZB | 43.49 ms | 20.27 MB |
| Restaurar metadatos en modo `mmap` | 0.224 ms | 59 KB |
| Restaurar metadatos y el índice de artículos residente | 0.577 ms | 1.79 MB |
| Restaurar metadatos en modo `reparse` | 0.199 ms | 59 KB |
| Leer/decodificar un registro de detalle del proveedor | 0.538 ms | 784 KB |
| Reutilizar el registro de detalle con una comprobación de stat y copia | 0.0084 ms | 59 KB |

El caso de decodificación del detalle limpia el memo nuevo antes de cada llamada e incluye el coste de llenarlo. Estas cifras comparan las dos rutas de acceso actuales; no estiman la latencia de red ni proyectan el tiempo de arranque de una biblioteca completa.

Las pruebas de regresión cubren la reutilización tras reiniciar, la corrupción, los cambios en el origen, el aislamiento de cuentas, la resolución concurrente, la identidad de bytes al inicio, en medio y al final, los saltos hacia atrás más allá de la ventana de RAM y la revocación de URLs tras restaurar la disposición.

```sh
go test ./...
go test -race ./internal/debrid ./internal/nzb ./internal/rarstream ./internal/universal ./pkg/cachefile ./pkg/diskcache
go test ./internal/nzb ./internal/torrent -run '^$' -bench 'Benchmark(ParsedDocumentStartup|DetailJSONRefresh)$' -benchmem
make integration-test
```

El objetivo de integración necesita sus cuentas de prueba en vivo documentadas y las dependencias del host. Un script de integración omitido no verifica ningún cambio en la caché.
