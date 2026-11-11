# Pruebas E2E {#e2e-testing}

Pruebas de extremo a extremo para verificar que zurg funciona correctamente después del despliegue.

## Prueba de reproducción en Plex {#plex-playback-test}

Verifica que el contenido realmente se pueda reproducir en Plex seleccionando una película al azar y probando todo el proceso de reproducción.

### Ejecutar la prueba {#run-the-test}

```bash
./scripts/plex-e2e-test.sh
```

El script lee automáticamente `plex_server_url` y `plex_token` desde `config.yml`.

Para sobrescribirlos con tus propios ajustes:
```bash
PLEX_URL="http://your-plex:32400" PLEX_TOKEN="your-token" ./scripts/plex-e2e-test.sh
```

### Qué prueba {#what-it-tests}

| Step | Description |
|------|-------------|
| 1 | Encuentra la biblioteca de Películas mediante la API de Plex |
| 2 | Obtén el número total de películas |
| 3 | Elige una película al azar |
| 4 | Obtén la URL de streaming de la película |
| 5 | Verifica que el stream sea accesible (HTTP 200) |
| 6 | Decodifica 3 segundos de vídeo con ffmpeg |
| 7 | Crea y verifica el seguimiento de la sesión de Plex |

### Salida esperada {#expected-output}

```
=== Plex E2E Playback Test ===

[1/7] Finding Movies library...
  Library key: 15
[2/7] Getting movie count...
  Total movies: 1234
[3/7] Selecting random movie...
  Selected: 2 Fast 2 Furious (2003) (ratingKey: 756524)
[4/7] Getting stream URL...
  File size: 54GiB
[5/7] Verifying stream accessibility...
  HTTP Status: 200 OK
[6/7] Decoding video (3 seconds)...
  Decoded 72 frames successfully
[7/7] Testing Plex session tracking...
  Session created and tracked

=== TEST PASSED ===
Movie '2 Fast 2 Furious (2003)' is playable via Plex
```

### Requisitos previos {#prerequisites}

- Servidor de Plex en funcionamiento y accesible
- `plex_server_url` y `plex_token` configurados en `config.yml`
- `curl`, `jq` y `ffmpeg` instalados

### Solución de problemas {#troubleshooting}

| Error | Causa | Solución |
|-------|-------|-----|
| No movie library found | Tipo de biblioteca incorrecto o vacía | Comprueba que Plex tenga una biblioteca "Movies" |
| Stream not accessible (HTTP 4xx) | Problema de autenticación o de ruta | Verifica el token y que el archivo exista |
| Failed to decode video frames | Archivo corrupto o problema de red | Revisa los logs de zurg y prueba con otra película |
| Session not detected | Tiempo de espera de la sesión de Plex agotado | Revisa los logs de Plex |

## Suite de integración {#integration-suite}

```bash
ssh zen
cd /path/to/isolated/zurg/source
make integration-test
```

**Ejecútalo en un destino aislado en `zen`.** Instala ahí el toolchain de Go, shellcheck, rclone y la sonda de movimiento de .NET. La suite crea sus propios procesos de zurg y sus propios montajes, así que no necesita reemplazar el servicio ni el montaje normales de zurg en zen. Usa un directorio de origen separado, y también `TMPDIR`, configuración, puerto y `MOUNT_PATH` propios. Revisa la configuración temporal antes de ejecutarla, y conserva `INTEGRATION_LOCK_FILE=/tmp/zurg-integration-rd.lock` a nivel de host aunque uses un `TMPDIR` privado, para que las demás sesiones sigan serializándose con la tuya.

Las pruebas cuyos prerrequisitos no estén presentes pueden omitirse con una salida exitosa. Lee su salida para comprobar que FUSE, rclone, Plex y NNTP realmente se ejecutaron.

| Prueba | Necesita FUSE | Necesita Plex | Necesita una cuenta de Usenet |
|--------|:-------------:|:-------------:|:-----------------------------:|
| `refresh_repair_integration.sh` | | | |
| `network_test_cache_integration.sh` | | | |
| `rclone_mount_integration.sh` | sí | | |
| `magic_mount_integration.sh` | sí | | |
| `magic_move_refusal.sh` | sí | | |
| `magic_library_move_integration.sh` | sí | | |
| `plex_integration.sh` | sí | sí | |
| `nzb_bench_integration.sh` | | | sí |

`force_location_integration.sh` **no** forma parte de la suite: comprueba algo sobre la ruta de red de este host hacia el CDN de Real-Debrid y no sobre zurg, así que falla donde esa ruta no puede responder, sin importar el cambio que se esté probando. Ejecútalo a propósito con `make force-location-test`, en un host con IPv4 funcionando hacia la región que se fuerza. Consulta [Prueba de integración de Force Location](#force-location-integration-test).

Las cinco pruebas que usan Real-Debrid usan la misma cuenta; consulta [la cuenta es compartida](#the-real-debrid-test-account-is-shared). El benchmark usa en su lugar una cuenta de noticias y no toca Real-Debrid en absoluto, pero toma el mismo bloqueo a nivel de host que el resto: una medición hecha junto a las lecturas de otra suite en realidad mide la otra suite.

La prueba de montaje también funciona en un Mac si macFUSE está instalado; está verificada tanto con macFUSE como con `fusermount` de Linux. La prueba de Plex necesita `plex_server_url` y `plex_token` en su configuración temporal, y Plex debe poder atravesar todos los directorios padre del montaje temporal. Un montaje dentro de un directorio personal privado puede funcionar para el usuario de la prueba y seguir siendo inaccesible para Plex.

`make integration-test` compila zurg, ejecuta shellcheck sobre los scripts, la autoprueba de `lib.sh` y las pruebas unitarias de `integration/nzbbench`, y luego ejecuta las siete, de la más barata a la más cara: caché de pruebas de red, montaje de rclone, Plex, montaje `__magic__`, rechazo de movimiento de .NET, refresh/repair y, al final, el benchmark de Usenet. Las dos últimas son las caras: refresh/repair espera a que termine un escaneo completo de la biblioteca, y el benchmark lee gigabytes de un servidor de noticias dos veces, así que un error en cualquiera de las demás no debería costarte esa espera para descubrirlo.
`make integration-test-media` ejecuta las pruebas de montaje de rclone, Plex y `__magic__`, y `make nzb-bench-test` solo el benchmark.

Cada script tiene su propio directorio de trabajo bajo `$TMPDIR`, su propio puerto, y escribe ahí el log de zurg. La suite se ejecuta con `STREAM_LOGS=false`, así que solo las aserciones de la propia prueba llegan a la terminal. Define `STREAM_LOGS=true` para seguir el log de zurg en stderr mientras depuras.

Los helpers compartidos están en `integration/lib.sh` (control de procesos, la API de Real-Debrid, consultas a la biblioteca en disco) e `integration/lib_media.sh` (FUSE y Plex). Para añadir una prueba, importa esos archivos con source en lugar de copiar otro script. `integration/lib_test.sh` cubre los propios helpers: no necesita cuenta ni red, y tarda alrededor de un segundo. `integration/nzb_bench_timing_gate_test.sh` cubre cómo el wrapper del benchmark convierte el código de salida de la herramienta en el vocabulario de la suite, a partir de un informe real recortado en `integration/testdata/`; ambos se ejecutan con `make test-integration-lib`.

### La cuenta de prueba de Real-Debrid es compartida {#the-real-debrid-test-account-is-shared}

La suite usa una sola cuenta de prueba de Real-Debrid, y esa cuenta no es privada. El zurg de producción de `zen` vigila la misma biblioteca, así que lista y refresca justo los torrents que una prueba acaba de añadir. Cualquier instancia de la cuenta **con la reparación activada** también los verifica, repara y ordena.

Ambos fallos de abajo se diagnosticaron el 2026-08-23, cuando el zurg de `macmini` funcionaba en esta cuenta con la reparación activada cada 10 minutos. Esa instancia se paró el 2026-08-29 y nadie la supervisa, y las ejecuciones de zen usan `enable_repair:
false` — así que a 2026-09-01 ninguno de los dos fallos tiene una fuente activa. Vuelven en cuanto se active la reparación en cualquier sitio de esta cuenta, por eso la serialización de abajo sigue vigente.

Lo que esto le hace a una ejecución, después de que cuatro de los seis scripts fallaran en la versión bajo prueba *y* en su línea base:

- **Un fixture que nunca aparece.** Real-Debrid deduplica los ids de descarga por enlace, y borrar una fila de downloads revoca ese código para todo el que lo tenga.
  La limpieza de otra instancia revoca el código que esta ejecución acaba de resolver, la verificación de esta ejecución responde `404 invalid_download_code`, y zurg marca el archivo como roto — un torrent roto se oculta de todos los listados. Entonces el test dice
  `zurg serves the fixture over HTTP but it never appeared under .../mnt/movies
  within 180s`, lo que parece un fallo de montaje o de dircache y no es ninguno de los dos.
- **Un borrado que se deshace.** Una instancia que repara vuelve a añadir un torrent que esta ejecución acaba de borrar, así que `refresh never dropped <hash> after it was deleted from
  the account` falla contra una biblioteca que refleja la realidad correctamente.

Las aserciones de borrado y de reparación son las que sufren. Antes de culpar a un cambio, lee el contexto del fallo descrito abajo — y si una ejecución tiene que salir limpia, para antes la reparación de las otras instancias.

**Ninguno de estos scripts puede ejecutarse a la vez con otro**, ni en este host ni desde otra sesión en él. Comparten el presupuesto de API por minuto de la cuenta, así que un par obtiene `API rate limit (code=34)` y las aserciones empiezan a fallar por el tráfico y no por el comportamiento (medido en `fun`, con dos ejecuciones en paralelo); y cada script borra torrents *por hash*, así que la limpieza de una ejecución borrará felizmente el fixture de la otra. Por eso cada script toma un bloqueo a nivel de host al principio de `main`, antes de su primera llamada a la API, y lo mantiene hasta que termina.

| Variable | Valor por defecto | Descripción |
|----------|---------|-------------|
| `INTEGRATION_LOCK_FILE` | `$TMPDIR/zurg-integration-rd.lock` | El bloqueo. `flock` donde exista; si no, un directorio `.d` con el pid (macOS no trae `flock`) |
| `INTEGRATION_LOCK_WAIT` | `0` | Segundos para hacer cola detrás de una ejecución en curso. `0` rechaza de inmediato, que es lo que quieres — la alternativa es esperar una hora detrás de un escaneo en frío |

Un bloqueo que deja una ejecución matada se recupera automáticamente: el directorio guarda el pid de quien lo tenía, y el kernel libera `flock`. El bloqueo no le dice nada a zen ni a macmini, por supuesto — solo mantiene separadas las ejecuciones de este host.

**Leer un fallo.** Cada `fail` ahora imprime, del log de zurg de esa ejecución: el recuento de cada síntoma de cuenta compartida — `invalid_download_code`,
`hoster_unavailable`, líneas de rate limit, `code=34`, `Link verification failed`,
`keeping files as broken`, `broken_file]`, `Deleted downloads entry` — luego las últimas diez de esas líneas, luego las últimas pocas líneas que nombran el fixture bajo prueba.
`none present, so this failure is probably zurg's own and not the account's` es la línea que te dice que mires el código en su lugar.

`docs/realdebrid-behavior.txt` tiene la semántica de los enlaces que hay detrás de todo esto: qué enlaces se canjean desde qué cuenta, y por qué `unavailable_file` y
`hoster_unavailable` significan cosas distintas.

### Tiempo de ejecución {#runtime}

La primera ejecución contra un directorio de trabajo dado paga un escaneo de biblioteca en frío: una llamada info y una verificación de enlace por cada torrent, al ritmo que marque el presupuesto de API de la cuenta. En una cuenta de unos pocos miles de torrents eso son decenas de minutos. Esta cuenta tenía 3,361 torrents el 2026-08-29, suficiente para provocar `code=34` sostenido y tardar unos veinte minutos en un script. El directorio de trabajo guarda tres cachés entre ejecuciones para que las siguientes las salten: `info/`, `linkcache/` y los resultados de las pruebas de red. Borra el directorio de trabajo para forzar la ruta en frío.

`linkcache/` es lo que persiste `internal/debrid.LinkCache`, un archivo por instancia de proveedor. Es la mitad que elimina los veinte minutos: la primera vez que se ve un torrent se resuelve uno de sus enlaces para verificarlo. Eso equivale a una llamada `unrestrict/link` por torrent con la caché vacía, y es gratis con una caché caliente. El beneficio está acotado por el TTL de 4h de la caché: una re-ejecución de la suite al día siguiente vuelve a estar en frío. Así que acorta la iteración, no una primera ejecución.

Ni `info/` ni `linkcache/` están libres de enlaces, y ambos guardan códigos que otra instancia de la cuenta compartida puede revocar. Un `.zurginfo` es un `TorrentInfo` literal, así que lleva los códigos `/d/` de Real-Debrid del torrent, y `linkcache/` guarda a qué resolvieron esos códigos. Ambos se conservan de todos modos. Reconstruirlos es lo que cuesta las decenas de minutos, y una entrada revocada no es una respuesta incorrecta: la verificación recibe `404 invalid_download_code`, zurg invalida esa entrada y regenera el código, así que solo las entradas revocadas pagan una llamada. Espera algunas en cada ejecución, y espera que la aceleración varíe según cuántas sean.

Un fixture es todavía más estrecho: `clean_state_for_hash` borra las entradas de `info/` cuyo hash coincide con él, así que su lista de enlaces siempre se vuelve a pedir a la cuenta. `linkcache/` se indexa por enlace y no por hash, y no se barre por fixture, así que la *resolución* de uno de esos enlaces todavía puede venir de una ejecución anterior. Ninguna aserción aquí depende de eso, porque los fixtures prueban el refresco, el enrutamiento, el montaje y la reparación. Una resolución caducada falla la verificación y se regenera antes de que cualquiera de ellos la vea.

### Prueba de integración de Refresh/Repair {#refreshrepair-integration-test}

```bash
./integration/refresh_repair_integration.sh
```

La reparación automática sigue desactivada en la config de scratch. Las dos peticiones explícitas a `/manage/{hash}/repair` se saltan esa opción y reparan sus fixtures.
Activar la reparación desatendida también escanearía y cambiaría entradas no relacionadas de la cuenta compartida, gastando el cupo de la API que necesitan las aserciones.
`refresh_repair_config_test.sh` comprueba la config generada sin tráfico al proveedor, usando la entrada de scratch redactada capturada en el fallo del 2026-09-10.

| Escenario | Descripción |
|-----------|-------------|
| 1. Actualización automática (adición) | Añade un torrent mediante la API de RD y espera a que el bucle de actualización lo detecte; sin reinicio, o estaría probando la ruta de carga en frío |
| 2. Asignación de directorios y enrutado | Verifica que los archivos aparecen en los directorios virtuales de HTTP/DAV |
| 3. Persistencia (reinicio) | Reinicia zurg y confirma que el estado en caché sobrevive |
| 4. Actualización automática (eliminación) | Elimina el torrent y espera a que el barrido de claves obsoletas lo quite |
| 5. Activación de la reparación | Activa la reparación mediante la Manage API, verifica que zurg registró que aceptó la petición y espera a `ok_torrent` con 0 archivos rotos |
| 6. Verificación de la reparación | Repara un segundo torrent y descarga por rangos un archivo de vídeo de él |

#### Variables de entorno {#environment-variables}

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `12345` | Puerto para la instancia de prueba de zurg |
| `CONFIG_PATH` | `config.yml` | Config de la que tomar las credenciales: el `token` del proveedor `realdebrid` y los `username`/`password` de nivel superior |
| `TEST_HASH` | *(built-in)* | Hash del torrent para las pruebas de refresh |
| `REPAIR_TEST_HASH` | *(built-in)* | Hash del torrent con piezas rotas para las pruebas de repair |
| `VERIFY_TEST_HASH` | *(built-in)* | Hash del torrent para las pruebas de verificación de repair |
| `READY_TIMEOUT` | `120` | Segundos a esperar a que zurg esté listo |
| `INITIAL_SCAN_TIMEOUT` | `3600` | Segundos a esperar la primera pasada completa de refresh |
| `REFRESH_TIMEOUT` | `120` | Segundos a esperar a que un refresh detecte una adición o una eliminación |
| `REPAIR_TIMEOUT` | `300` | Segundos a esperar a que un repair se estabilice |
| `STREAM_LOGS` | `true` | Seguir el log de zurg en stderr |
| `ZURG_BIN` | `$(pwd)/zurg` | Ruta al binario de zurg — absoluta, porque zurg se inicia desde el directorio de trabajo |
| `WORK_DIR` | `$TMPDIR/zurg-refresh-repair` | Directorio de trabajo (se conserva entre ejecuciones) |
| `WORK_DIR_CLEANUP` | `false` | Borra el directorio de trabajo al salir, descartando las cachés que hacen que las ejecuciones posteriores sean más rápidas |

### Prueba de integración de Force Location {#force-location-integration-test}

```bash
make force-location-test
```

No forma parte de `make integration-test`, así que se ejecuta a propósito, por separado. Medido en `fun` el 2026-08-29, los hosts `nyk` forzados se resolvían a registros AAAA a los que el cliente de descarga se conecta por `tcp4`, así que cada HEAD terminaba con `no suitable address found`. Con tres reintentos por cada uno, el escaneo de la biblioteca que espera esta prueba se queda atascado casi una hora antes de fallar por la red del host y no por zurg. Ya se salta cuando una región no está sana (más abajo), pero esa protección no cubre un host que no puede llegar a una región *sana* por IPv4.

Siembra una caché de prueba de red fijada a `LOCATION` (por defecto `nyk`) y luego comprueba que un enlace resuelto a través del endpoint `/strm/` de zurg redirige a un host de descarga en esa ubicación. `MAX_GEO_PROBES` (por defecto `4`) limita cuántos servidores geo sondea el paso de siembra.

Con `cdn_host_preference` definido, cada enlace que zurg verifica pasa por la región forzada. Así, una región no sana deja la lista vacía y el fallo parece un bug de zurg. Por eso la prueba revisa primero la región y se salta, en lugar de fallar, cuando Real-Debrid no genera un enlace para ella o el host que devuelve no sirve bytes.

### Prueba de integración de Network Test Cache {#network-test-cache-integration-test}

```bash
./integration/network_test_cache_integration.sh
```

Ejecuta zurg dos veces: el primer inicio debe hacer el barrido de latencia y escribir `data/network_test_results.json`; el segundo debe cargar ese archivo y no hacer ningún barrido nuevo.

### Prueba de integración de montaje de Rclone {#rclone-mount-integration-test}

```bash
./integration/rclone_mount_integration.sh
```

Recorre el mismo camino que sigue un reproductor de verdad: FUSE → HTTP de zurg → Real-Debrid:

| Step | Assertion |
|------|-----------|
| 2 | zurg levanta su propio montaje y registra `Mount verification successful` |
| 3 | los directorios configurados se ven en la raíz del montaje |
| 4a–4c | el fixture entra en la biblioteca, se sirve por HTTP y llega al montaje. Va por pasos para que, si falla, el error indique qué salto se rompió y no solo "no está en el montaje" |
| 5 | leer el archivo a través de FUSE devuelve bytes reales |
| 6 | al apagar zurg, el montaje se libera |

El paso 4c es la comprobación de dircache de VFS: el fixture solo llega al montaje si el listado de directorios se invalidó en lugar de servirse desde un listado guardado en caché antes de que llegara el torrent.

La biblioteca se reduce con una expresión regular construida a partir del propio nombre del fixture, así que el montaje contiene solo un lanzamiento y no toda la cuenta. `MOUNT_PATH` toma por defecto `$WORK_DIR/mnt`, nunca `/mnt/zurg` de producción. `RCLONE_BIN` toma por defecto `$(pwd)/bin/rclone`.

### Prueba de integración de Plex {#plex-integration-test}

```bash
./integration/plex_integration.sh
```

| Paso | Verificación |
|------|--------------|
| 2 | zurg registra `Successfully connected to Plex server` |
| 3 | el fixture llega a la biblioteca, y si también aparece en el mount, debe poder leerse (Plex lo lee como su propio usuario) |
| 4 | se crea una sección nueva y desechable sobre `$MOUNT_PATH/movies` |
| 5 | zurg resuelve la ruta de su biblioteca hacia esa sección y encola una actualización **para la ruta del fixture** |
| 6 | Plex termina indexando el elemento |

La aparición del fixture en el mount es una precondición aquí, no la verificación: con Plex configurado, zurg también ejecuta su matcher sobre toda la biblioteca de Plex, lo que compite con la actualización, así que el listado del VFS puede retrasarse mucho. La prueba lo indica y continúa tras `MOUNT_VISIBLE_TIMEOUT` (por defecto `420`). Los pasos 5 y 6 ya fallan si Plex no puede ver el archivo, y comprobar que la invalidación funciona es trabajo de la prueba del mount. `PLEX_URL` y `PLEX_TOKEN` sobrescriben `plex_server_url` y `plex_token` de la configuración.

Plex escanea automáticamente una sección nueva y puede terminar antes de que la creación devuelva la respuesta. La prueba informa ese recuento inicial; el paso 5 comprueba por separado que zurg encola la ruta correcta tras una solicitud explícita de manage.

La sección se crea con `agent=tv.plex.agents.none` y el scanner `Plex Video
Files`, así Plex indexa localmente sin consultar un agente de metadatos en línea, y se elimina al salir, incluso si falla, desde la trampa EXIT. Sin embargo, nada se ejecuta con SIGKILL, así que tras una ejecución interrumpida de esa forma, inspecciona y elimina solo tu propia sección. El arnés deja intactas las secciones preexistentes porque pueden pertenecer a otra sesión. Las bibliotecas existentes nunca se tocan.

El paso 5 pide a zurg ejecutar los efectos secundarios mediante `POST /manage/{hash}/scan` en lugar de esperar a una pasada de actualización. El disparador de asignación de directorio se activa una vez, al descubrirse un torrent, lo que necesariamente ocurre antes de que exista la sección; esperar a la siguiente pasada completa cuesta decenas de minutos en una cuenta con unos pocos miles de torrents. El mapeo que se prueba no cambia: zurg sigue teniendo que resolver por sí mismo la ruta de su biblioteca hacia la sección correcta.

(Una traducción anterior fue rechazada: los spans de código no coinciden. Mantén la estructura exactamente.)

### Regresión del benchmark de Usenet {#usenet-benchmark-regression}

```bash
./integration/nzb_bench_integration.sh
make nzb-bench-test
```

Nada más en la suite lee un byte por NNTP. Un cambio en el descargador de artículos, el decodificador yEnc, la reparación PAR2 o el lector de archivos podría reducir a la mitad el rendimiento, duplicar la memoria o empezar a servir silencio donde un artículo ya no existe, y todas las demás pruebas seguirían pasando. Esta lee cuatro lanzamientos preparados a través de un zurg temporal y comprueba tanto los números como los bytes.

**Por qué es un A/B y no un número guardado.** El rendimiento de un servidor de noticias en directo varía un 10–20 % a lo largo de la tarde (seis lecturas del mismo lanzamiento oscilaron entre 34 y 50 MB/s en una sola sesión), así que un margen estrecho frente a una cifra registrada la semana pasada fallaría por el clima y no por el código. Por eso la prueba mide dos binarios en la misma ventana y en el mismo equipo, alternando el orden en cada repetición para que el calentamiento del proveedor afecte a ambos, y compara sus medianas.

A es la referencia: por defecto, el tag `*-nightly` más reciente alcanzable desde `HEAD`, extraído con `git archive` y compilado una vez, y luego guardado en caché dentro del directorio de trabajo para que las siguientes ejecuciones lo reutilicen. B es el candidato, el `zurg` que acaba de compilar este repo. **Una métrica falla cuando B es peor que A en más de un 5 %** (`BENCH_TOLERANCE`). Si es mejor, se informa como mejora, y una métrica que falta en uno de los lados es `n/a`, no una regresión. En cada repetición se mide un open en frío, el tiempo hasta el primer byte, una lectura de 64 MiB y la misma relectura de 64 MiB en caliente, un scrub de ocho puntos, una lectura de 256 MiB con segundos de CPU por gigabyte y el pico de RSS al lado (solo Linux, ya que ambos datos salen de `/proc`), y la duración del contenedor según `ffprobe`.

La corrección se comprueba solo en el candidato, y nunca con el reloj: cada lectura registra un md5 que debe coincidir con una constante registrada y coincidir entre los dos binarios. El lanzamiento dañado debe servir los bytes originales o silencio, y nada más. La reparación debe llegar después al original y seguir siendo correcta tras un reinicio.

El corpus está incluido en el repo, en `integration/nzbbench/corpus/`: seis NZB para seis preguntas.

| NZB | Qué es | Para qué sirve |
|-----|--------|----------------|
| `ToyStory5.nzb` | un WEB-DL de 6.61 GB, 1,576 × artículos de 4 MiB | todos los números de rendimiento y latencia, y la comprobación de ffprobe |
| `ToyStory5Damaged.nzb` | el mismo lanzamiento con el message-id del artículo 21 corrompido, así que cualquier servidor responde `430` | el hueco debe leerse como los bytes originales o como silencio; cualquier otra cosa es un error de corrección. Después PAR2 debe repararlo, y la reparación debe sobrevivir a un reinicio |
| `Obfuscated.nzb` | la misma película publicada como siete archivos bajo `<hex> [n/7] yEnc`, cuyo nombre real solo se puede recuperar del índice PAR2 | las pasadas de nombres: debe listarse con el nombre real `.mkv` y el tamaño correcto, sin ningún `.par2` visible |
| `FatherBrown.nzb` | un RAR de 11 volúmenes con un episodio, un directorio `Sample/` y un nfo | el lector de archivos: la estructura de carpetas debe conservarse, y las lecturas dentro del archivo tienen su propio número de rendimiento (`rar_read_MBps`, una lectura por repetición) |
| `WrongTurn3.nzb.gz` | un 7z almacenado de 58 GB en 54 volúmenes de 1 GiB (el último más corto) más siete archivos PAR2, un árbol completo de UHD BluRay; comprimido con gzip porque el NZB ocupa 7 MB sin comprimir | el lector de 7z dividido: los volúmenes deben unirse y leerse la cabecera del final del último antes de listar nada, y ese listado es lo que se cronometra (`sevenzip_list_s`, una vez por repetición desde un layout limpio). Después, el stream de la película de 57.6 GB debe responder 16 MiB en la posición 8 GiB con el md5 registrado, lo cual es una comprobación de corrección, no de tiempo. No hay número de rendimiento: en este proveedor, cada volumen de este lanzamiento le faltan alrededor de una quinta parte de sus artículos, así que una lectura cronometrada mediría el descubrimiento de huecos |
| `NestedRar.nzb` | un repost XviD de dos CD: un conjunto externo de volúmenes RAR5 cuyos miembros son los volúmenes de otros dos conjuntos RAR, en `CD1/` y `CD2/`, más un clip en `Sample/` y un nfo | el lector de archivos anidados: deben abrirse ambos conjuntos internos (el test plano rechaza dos conjuntos comparables, y los directorios del poster son lo que los agrupa), con las dos películas listadas en su tamaño real y su propio número de rendimiento (`nested_read_MBps`, una lectura por repetición) |

**Una cuenta, una instancia.** Un segundo zurg con una cuenta de noticias compite con el primero por su cupo de conexiones, y el servidor rechaza a la *más antigua*. En `fun`, el `zurg-usenet` de producción ocupa todas las conexiones que permite el plan de la cuenta, así que el benchmark se ejecuta con 10 (`BENCH_NNTP_CONNECTIONS`), y un rechazo `Too many connections` se informa como **omisión, no como fallo**. Lo mismo pasa con un servidor inaccesible o un `AUTHINFO` rechazado: el entorno no pudo responder a la pregunta, así que la prueba lo dice en vez de culpar al build.

Unos 15–20 minutos con las cuatro repeticiones por defecto, más unos minutos extra la primera vez que hay que compilar la referencia.

| Variable | Por defecto | Descripción |
|----------|-------------|-------------|
| `PORT` | `12358` | Puerto para las instancias de zurg del benchmark (una a la vez) |
| `WORK_DIR` | `$TMPDIR/zurg-nzb-bench` | Guarda el config generado, los directorios de ejecución y logs de ambos binarios, `report.json` y el binario de referencia en caché. Se conserva entre ejecuciones: el `data/` persistido es lo que hace que las repeticiones siguientes midan un reinicio y no un aprendizaje en frío |
| `BENCH_ENV_FILE` | `~/.config/zurg/bench-account.env` | Archivo de cuenta, se carga si existe. Líneas `KEY=value` para las variables `BENCH_NNTP_*`. **La forma soportada de dar al benchmark una cuenta propia**, y lo que mantiene las credenciales fuera del repo y del historial de la shell |
| `CONFIG_PATH` | `config.yml` | Config del que tomar la cuenta de noticias, cuando ni el entorno ni el archivo de cuenta indican una: el bloque `nntp:` del primer proveedor `type: nzb`. Se rechaza tomarla prestada si esa cuenta ya tiene conexiones abiertas desde aquí; ver abajo |
| `BENCH_NNTP_HOST` / `_PORT` / `_TLS` / `_USER` / `_PASS` | *(desde `BENCH_ENV_FILE`, luego `CONFIG_PATH`)* | La cuenta de noticias. Un valor exportado gana al archivo de cuenta. Si no se encuentra nada en ningún sitio → omitir |
| `BENCH_NNTP_CONNECTIONS` | `10` | Conexiones que abre el benchmark. Es un límite: una cuenta configurada con menos conserva su propio número |
| `BENCH_ALLOW_SHARED_ACCOUNT` | *(sin definir)* | Pon `1` para hacer el benchmark con una cuenta prestada que ya tiene conexiones abiertas. Solo cuando hayas confirmado que la cuenta tiene margen |
| `BASELINE_REF` | el `*-nightly` más reciente alcanzable desde `HEAD` | Con qué comparar. Se resuelve después de un `git fetch --tags` que se intenta sin garantías |
| `BASELINE_BIN` | *(compilado desde `BASELINE_REF`)* | Un binario de referencia ya compilado, que se usa tal cual. La forma de comparar con algo que ya no compila aquí |
| `BENCH_REPS` | `4` | Repeticiones por binario. Las medianas se calculan sobre estas |
| `BENCH_TOLERANCE` | `0.05` | Cuánto puede empeorar B antes de considerarse regresión |
| `BENCH_SKIP` | *(ninguna)* | Lista separada por comas de fases a omitir: `repair`, `obfuscated`, `rar`, `ffprobe`. `ffprobe` se añade automáticamente si no hay ninguno en `PATH` ni en `bin/` |
| `REPORT_JSON` | `$WORK_DIR/report.json` | Dónde se guarda el informe |
| `STREAM_LOGS` | `true` | Sigue el `zurg.log` del candidato por stderr. El progreso de la herramienta se imprime de todas formas |

`report.json` contiene cada fila por repetición de ambos binarios, las medianas, los veredictos por métrica, la salida de `version` de los dos binarios, y el host y el SO. Así, un número ahí puede leerse frente al código que lo produjo. Para registrar un conjunto de números sin comparar nada, llama a la herramienta directamente con un único `--bin`: mide, escribe el JSON y termina con código 0:

```bash
cd integration/nzbbench && go build -o /tmp/nzbbench . && cd -
/tmp/nzbbench --config /path/to/a-config-with-an-nzb-provider.yml --port 12358 \
  --corpus integration/nzbbench/corpus --work /tmp/nzbbench-record \
  --bin candidate=./zurg --out /tmp/record.json
```

La configuración tiene que ser la tuya: la que genera el wrapper incluye la contraseña de la cuenta de noticias en texto plano y se borra cuando termina la ejecución.

`integration/nzbbench/README.md` documenta los propios flags y códigos de salida de la herramienta.

**Códigos de salida de `nzb_bench_integration.sh`.** `0` la comparación se hizo y pasó, o el host no pudo hacer benchmark en absoluto y la ejecución se saltó; `1` una aserción funcional falló o una métrica empeoró; `4` todas las aserciones funcionales pasaron y el gate de tiempos **no se juzgó** -- el servidor de noticias superó el límite de estabilidad de la herramienta dentro de la ventana, así que se descartó la comparación de throughput y latencia. El 4 es deliberadamente distinto tanto del 1 de un build roto como del 0 de una ejecución saltada: no se decidió nada sobre el rendimiento, lo que toca es volver a ejecutarlo en una ventana más tranquila, y la ejecución muestra un banner que indica el gate y las dispersiones que lo hicieron fallar. `make integration-test` convierte cualquier línea de receta que falle en el exit 2 propio de make, así que una ejecución de la suite muestra esto como un make con código distinto de cero más ese banner, en lugar de la línea "All integration tests passed." del target; llama al script directamente cuando algo necesite bifurcar según el propio 4.

### Requisitos previos {#prerequisites-1}

- Token de Real-Debrid en `config.yml` (como proveedor `realdebrid`) o `RD_TOKEN`
- `curl`, `python3` y un binario de zurg compilado
- `shellcheck` para `make lint-integration` (se omite con un aviso si no está instalado)
- Para las pruebas de montaje y Plex: `fusermount`/macFUSE, un binario de rclone y
  `user_allow_other` en `/etc/fuse.conf` para que Plex pueda leer el montaje
- Para la comprobación del rechazo de move: el rclone corregido de
  `scripts/build-rclone-move-fix.sh`, configurado
  tanto en `RCLONE_BIN` como en `RCLONE_TEST_BIN`. Un rclone upstream más nuevo sin parchear no basta. Consulta [la regresión de MOVE](rclone-move-refusal.md).
  Puedes indicar un helper ya compilado con `DOTNET_MOVE_PROBE_BIN`, o usar Docker para compilarlo. Si lo compilas con un usuario de contenedor sin privilegios, dale a .NET un `XDG_DATA_HOME` escribible, además de sus directorios de caché de CLI y NuGet.
- Para el benchmark de Usenet: una cuenta de noticias, además de Go, `git`, `tar` y `make`. Construye su línea base a partir de un `git archive` de una etiqueta nightly.

### Dale al benchmark su propia cuenta de noticias {#give-the-benchmark-its-own-news-account}

Un límite de conexiones pertenece a la **cuenta**, no a un proceso. Si apuntas el
benchmark a la cuenta en la que ya está una instancia de producción, ambos
usan el plan juntos, y en ese momento el servidor rechaza al titular *más
antiguo* de la conexión: producción, que no sabe nada del benchmark que lo
causó.

Así que el benchmark toma `CONFIG_PATH` solo como respaldo, y **se niega a usar
una cuenta que ya tenga conexiones abiertas en este host**. Dale una propia en
`~/.config/zurg/bench-account.env`:

```
BENCH_NNTP_HOST=news.example.net
BENCH_NNTP_PORT=563
BENCH_NNTP_TLS=true
BENCH_NNTP_USER=...
BENCH_NNTP_PASS=...
BENCH_NNTP_CONNECTIONS=25
```

Elige una cuenta con margen que nada más use: un servidor cuyo límite medido
esté muy por encima de lo que cualquier instancia tiene configurada, para que el
benchmark no deje sin conexiones a un lector. Lo que exportes en la línea de
comandos sigue ganando al archivo, y `BENCH_ALLOW_SHARED_ACCOUNT=1` anula la
negativa si ya has confirmado que hay espacio.

### No está en la suite {#not-in-the-suite}

`rename_integration.sh`, `tag_stats_integration.sh` y
`test_repair_verification.sh` no los ejecuta `make integration-test`. Todavía
llevan sus propias copias de los auxiliares anteriores a `lib.sh`. Pásalos a
usar `lib.sh` y asígnales puertos que no entren en conflicto antes de
conectarlos.
