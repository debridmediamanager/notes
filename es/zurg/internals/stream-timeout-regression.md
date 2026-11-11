# Regresión de tiempo de espera en streams proxificados {#proxied-stream-timeout-regression}

## Resumen {#summary}

zurg usaba `download_timeout_secs` como un plazo total para las descargas HTTP que pasan por el proxy. Su valor por defecto es 15 segundos, así que cualquier respuesta individual del origen cuyo cuerpo tardara más de 15 segundos en terminar se cortaba, aunque los bytes siguieran llegando con normalidad.

El fallo se reportó en Discord el 2026-08-21 con `2026.08.21.0151-nightly` (`fc2a21f`). Al repetir peticiones con rangos de 2 GB a través de zurg, la conexión se cortaba a los 15.001 segundos, después de entregar unos 1.26 GB a 84 MB/s. El mismo rango se completaba sin problemas directamente desde Real-Debrid, y al subir `download_timeout_secs` a 3600 la petición terminaba a través de zurg en 25.8 segundos.

Esto fue una regresión de zurg, no un filtrado de contenido, un fallo del CDN ni una regresión en `fc2a21f`. El commit `6edeaa8c` (`Optimize client`, 2024-11-17) la introdujo. La ruta de servicio proxy normal se arregló con `41db7245`, y después `eff972b8` hizo que fuera más difícil volver a cometer el mismo error en el límite de la API del proveedor.

## Impacto para el usuario {#user-impact}

La ruta afectada era cualquier cuerpo de respuesta que zurg enviaba (proxy) desde un proveedor de debrid basado en HTTP y que seguía abierto más tiempo que `download_timeout_secs`. Real-Debrid se vio afectado desde noviembre de 2024. TorBox y AllDebrid heredaron el mismo comportamiento cuando se añadieron esos proveedores. Las lecturas de NZB servidas localmente nunca pasaban por el cliente de descarga HTTP, así que no se vieron afectadas.

Los síntomas que veías como usuario incluían:

- Infuse u otro cliente WebDAV directo se congelaba durante la reproducción;
- la reproducción fallaba después de que un salto (seek) abriera una nueva petición con rango;
- una descarga terminaba antes de tiempo aunque recibía HTTP `206 Partial Content`; y
- errores del cliente que parecían apuntar al archivo multimedia o a la CDN, aunque una petición directa se completaba sin problemas.

El reproductor no siempre fallaba 15 segundos después de empezar la reproducción. A los 84 MB/s reportados, zurg transfería unos 1.26 GB antes del límite. Un reproductor podía consumir ese búfer durante varios minutos antes de quedarse sin datos, así que un corte de red exacto de 15 segundos se convertía en una congelación de reproducción que parecía variable.

## Causa raíz {#root-cause}

El `http.Client.Timeout` de Go es un plazo para todo el ciclo de vida de la petición. No es un timeout de inactividad ni de bloqueo. El reloj arranca cuando empieza la petición y sigue corriendo mientras se lee el cuerpo de la respuesta, aunque no estén llegando datos.

Antes de `6edeaa8c`, el cliente de descarga en sí no tenía ningún timeout para toda la petición:

```go
client: &http.Client{}
```

`download_timeout_secs` limitaba las fases de conexión y de cabeceras de respuesta, a través del dialer del transporte y de `ResponseHeaderTimeout`. Una vez llegaba el cuerpo de la respuesta, la ruta de servicio podía seguir leyendo todo el tiempo que necesitara el cliente final.

`6edeaa8c` reorganizó el transporte HTTP, añadió el timeout configurado al propio cliente y eliminó `ResponseHeaderTimeout`:

```go
client.client = &http.Client{
    Transport: transport,
    Timeout:   time.Duration(timeoutSecs) * time.Second,
}
```

Eso cambió el significado del valor de 15 segundos que ya existía. Seguía protegiendo la fase de conexión, pero ahora también imponía un plazo absoluto al cuerpo de la respuesta. La ruta de servicio ya descargaba el contenido multimedia a través de este cliente, así que la regresión se activó en cuanto llegó este cambio.

El fallo pasaba desapercibido. zurg enviaba el estado y las cabeceras de la respuesta upstream, que eran correctos, antes de copiar el cuerpo al reproductor. Cuando el plazo del cliente interrumpía el cuerpo, la operación de copia devolvía un error, pero la ruta de servicio descartaba ese error:

```go
n, _ = copyBuffered(resp, body)
```

Para entonces la respuesta `206` ya estaba enviada y no se podía sustituir por un código de error. Con el registro de peticiones desactivado, nada informaba de por qué el cuerpo estaba incompleto. Por eso el cliente final veía una respuesta de contenido parcial correcta cuyo cuerpo terminaba antes de la longitud anunciada.

## Historial de regresiones {#regression-history}

Los commits relevantes forman una cadena más larga que la nightly donde se reportó el problema:

| Fecha | Commit | Efecto |
|---|---|---|
| 2024-06-28 | `c3aea427` | Pasó la lectura de servicio existente a través de `DownloadFile`. No cambió el comportamiento porque el cliente de descarga seguía sin timeout para toda la petición. |
| 2024-11-17 | `6edeaa8c` | Añadió `http.Client.Timeout` al cliente de descarga. Esta es la regresión que empezó a cortar los cuerpos normales de las respuestas proxificadas. |
| 2026-02-26 | `dea98d34` | Identificó bien el mismo corte de 15 segundos en las lecturas de archivos RAR, añadió un cliente de streaming sin timeout y movió solo la ruta RAR a él. La reproducción normal de archivos siguió usando `DownloadFile`. |
| 2026-08-02 | `e9318e66` | Movió las descargas detrás de la interfaz multiproveedor `debrid.Provider` y pasó la llamada de servicio normal tal cual. No creó el bug de Real-Debrid, aunque los nuevos proveedores basados en HTTP heredaron el método inseguro. |
| 2026-08-21 | `fc2a21f` | La nightly que se usó en el reporte. Tenía el bug, pero no lo introdujo. |
| 2026-08-21 | `41db7245` | Cambió la reproducción proxificada normal para usar `DownloadFileStreaming` y añadió la primera prueba de regresión de timeout de extremo a extremo. |
| 2026-08-21 | `eff972b8` | Hizo que el `DownloadFile` de todos los proveedores HTTP no tuviera timeout, como medida estructural, y amplió la cobertura a Real-Debrid, AllDebrid, TorBox y un control NZB. |

El arreglo de RAR de febrero es el casi-accidente importante. Su mensaje de commit dice explícitamente que `http.Client.Timeout` cubre el cuerpo y que el valor por defecto de 15 segundos estaba matando los streams RAR. El diagnóstico era correcto, pero el arreglo se limitó al lector RAR. Mantener métodos separados `DownloadFile` y `DownloadFileStreaming` permitió que la ruta de servicio normal conservara la opción insegura durante otros seis meses.

## Por qué pasó desapercibido {#why-it-stayed-hidden}

Varios factores ocultaron la regresión durante unos 21 meses:

1. La mayoría de las instalaciones de servidores multimedia leen zurg a través de rclone en lugar de WebDAV directo. rclone usa peticiones de rango acotadas. Los valores predeterminados actuales del montaje gestionado empiezan en 4 MB y crecen hasta un límite de 512 MB, así que en una conexión rápida muchas peticiones individuales al origen terminan en menos de 15 segundos. Esto redujo la exposición, pero no hizo que la ruta fuera segura, sobre todo en enlaces más lentos.
2. Los clientes WebDAV directos, como Infuse, pueden pedir rangos grandes o abiertos. Esas peticiones mantienen una respuesta del origen activa el tiempo suficiente para alcanzar el límite de forma fiable, por eso la reproducción de Discord fue exacta en tres desplazamientos distintos.
3. El búfer de reproducción separó la causa del síntoma. La petición al origen se cortaba a los 15 segundos, pero la reproducción solo se detenía cuando el reproductor consumía los bytes que ya habían llegado. El retraso visible variaba según el bitrate, el búfer y los saltos de posición.
4. La respuesta parecía correcta. El CDN devolvió un `206` válido, zurg lo reenvió, y el error al copiar el cuerpo se ignoró después de enviar las cabeceras. Las pruebas directas contra el CDN seguían en buen estado y los registros normales no contenían ningún error de timeout.
5. Subir el valor parecía resolver el problema. Eso hizo que el fallo pareciera un valor de ajuste demasiado pequeño, en lugar de un timeout asociado a la abstracción equivocada.
6. Las pruebas existentes usaban cuerpos o rangos que se completaban dentro del timeout configurado. Ninguna prueba mantenía deliberadamente un cuerpo de respuesta fluyendo más allá del límite y luego comprobaba la longitud completa y el checksum a través de la ruta de servicio.
7. La corrección acotada para RAR eliminó la manifestación más evidente anterior, pero no eliminó el valor predeterminado inseguro en las descargas normales.

## Por qué un tiempo de espera más alto parecía arreglarlo {#why-a-higher-timeout-appeared-to-fix-it}

Cambiar el ajuste a 3600 segundos no cambió lo que cubría el timeout. Solo alejó el límite de tiempo total lo suficiente para que la transferencia de 25.8 segundos reportada terminara:

```text
15 seconds   < 25.8-second transfer < 3600 seconds
```

Esto fue un parche, no una solución segura. Cualquier timeout finito para toda la petición puede seguir cortando un cuerpo lo bastante largo, por ejemplo con un cliente lento o una conexión pausada. El ajuste también alimenta el timeout de conexión del cliente de descarga y las peticiones de verificación acotadas, así que subirlo a una hora puede hacer que un host inalcanzable tarde mucho más en fallar. Las versiones corregidas deberían usar el valor configurado normal; ya no limita el cuerpo de un contenido multimedia que pasa por el proxy.

## Solución y salvaguardas {#fix-and-guardrails}

El arreglo inmediato en `41db7245` cambió `streamFileToResponse` para que descargue a través de `Provider.DownloadFileStreaming`. Ese cliente usa el mismo transporte, pero no tiene `http.Client.Timeout`, así que la duración del cuerpo ya no depende de `download_timeout_secs`. La petición sigue usando el contexto de la petición downstream, así que si el reproductor se desconecta se cancela la lectura upstream. El establecimiento de la conexión y el handshake TLS siguen acotados por el transporte.

`eff972b8` quitó la dependencia de que cada llamador eligiera el método según tuviera "Streaming" en su nombre:

- `DownloadFile` de Real-Debrid ahora usa `DoStreaming`.
- El helper compartido `debrid.DownloadRanged` acepta `StreamingDoer`, que solo expone `DoStreaming`; AllDebrid y TorBox usan este helper.
- Por tanto, los dos métodos de descarga de los proveedores son seguros para un cuerpo de respuesta largo.
- Las lecturas acotadas que no son de reproducción, como las dos lecturas de 64 KiB que se usan para el hash de OpenSubtitles, reciben su propio plazo explícito en el contexto, en lugar de depender de un timeout de cuerpo global y peligroso para el cliente.

Los tests de regresión en `internal/universal/stream_timeout_test.go` usan un servidor local que envía un cuerpo de 1.6 MB en 16 fragmentos durante unos 1.6 segundos, mientras que el timeout configurado es de un segundo. Comprueban la longitud completa y el checksum:

- directamente a través de los dos métodos de descarga de Real-Debrid, AllDebrid y TorBox;
- de extremo a extremo a través de `streamFileToResponse` para los tres proveedores basados en HTTP; y
- a través de un proveedor local con forma de NZB, como control sin afectación.

La regla ahora es explícita: un método que devuelve un cuerpo de descarga nunca debe usar un timeout de petición completa. Las comprobaciones cortas y las lecturas de metadatos deben llevar su propio plazo en su contexto; los cuerpos de streaming deben seguir abiertos hasta que terminen, el downstream cancele o se produzca un error real de transporte.

## Limitado por progreso, no por tiempo {#bounded-by-progress-not-by-time}

Vivir hasta terminar dejaba una sola forma para que una lectura no acabara nunca: un nodo de entrega que mantiene la respuesta abierta y deja de enviar datos, o que nunca responde. En septiembre de 2026 un escaneo de Plex estuvo once horas atascado en un archivo de Real-Debrid cuya lectura nunca falló. Este cliente no tenía ningún límite con el que rendirse, y el `--timeout` de rclone es un límite de inactividad: zurg reenvía el cuerpo en escrituras de 256 KiB, así que un nodo que entrega 256 KiB cada cinco minutos, a menos de 1 KB/s, lo reinicia para siempre. Un nodo más lento sí lo activa, pero entonces rclone vuelve a enviar la misma petición al mismo nodo, registrando un error por cada tres timeouts. Medido en zen con rclone 1.75 y las opciones propias del montaje el 3 de octubre de 2026, un lector en un nodo así seguía bloqueado tras 30 minutos.

`internal/universal/starved_read.go` ahora corta una lectura proxificada cuando el nodo ha entregado menos de 1 MiB en 30 segundos que zurg pasó esperándolo. Solo cuenta la espera al nodo: desde el momento en que la petición tiene una conexión hasta que llegan sus cabeceras, y el tiempo dentro de cada lectura del cuerpo. El tiempo que se dedica a escribir al cliente no cuenta, así que la propiedad de arriba sigue en pie y un cliente pausado o lento puede mantener un stream abierto todo el tiempo que quiera. Un archivo cortado recibe `503` durante dos minutos, para que los reintentos de rclone terminen de inmediato en lugar de esperar cada uno otra ventana. Las lecturas de NZB servidas localmente no se vigilan.

Las lecturas de archivos dentro de un archivo comprimido nunca llegaban a `streamFileToResponse`, así que quedaban fuera de ese límite hasta la tarjeta 204. Sus bytes vienen de tramos de cada volumen, obtenidos por el mismo cliente mediante `providerDoer.Do` y leídos por el parser de RAR, y un nodo podía retener una de esas conexiones todo el tiempo que quisiera. Ahora cada descarga de volumen se vigila con el mismo mínimo, la entrada se rechaza durante dos minutos cuando se corta una, y un corte mientras se lista el archivo hace fallar el listado en lugar de dejar que el parser deje fuera el volumen como dañado. En un conjunto real de cinco volúmenes, eso servía la longitud completa de la entrada con bytes incorrectos a partir del segundo volumen.

La tarjeta 222 encontró lo mismo detrás de todas las demás formas en que un nodo puede fallar una lectura de volumen: un 5xx, un 429, una conexión caída a mitad de las cabeceras. El parser lo tomaba como un volumen dañado y listaba el archivo sin él, y ese listado se guardaba en caché. Así, en el mismo conjunto, un 503 en el volumen 3 servía bytes incorrectos desde el desplazamiento 16.057 y seguía sirviéndolos después de que el nodo se recuperara. Ahora el parser distingue un volumen cuyos bytes no se pudieron parsear de otro cuyos bytes nunca llegaron (`rarstream.ErrVolumeUnavailable`, marcado por `HTTPSrc` para los estados que ve, por `providerDoer` para todo fallo remoto de lectura, y por el cuerpo del NZB para lo que su lector clasifica como transporte). Este segundo caso hace fallar el listado, incluidos los conjuntos anidados y la agrupación por cabecera de volumen, y el fallo se responde con `503` y un `Retry-After`. Nunca se guarda en caché como fallo del archivo, nunca se registra como veredicto, y nunca se responde en una exploración con los volúmenes sin procesar en lugar del contenido del archivo. Los volúmenes dañados o ausentes siguen listándose alrededor, como antes.

Las escrituras de 256 KiB mencionadas arriba también se fueron en la tarjeta 204. La copia sigue llenando su búfer mientras el nodo es rápido, así que un cuerpo rápido sale en bloques completos como antes, pero envía los primeros bytes en cuanto llegan y nunca retiene un byte más de 250 ms (`defaultCopyFlushAfter` en `internal/universal/downloader.go`), vaciando la respuesta con ellos. Un nodo lento ya no impide que el cliente reciba sus cabeceras. Antes, en zen con rclone y las opciones propias del montaje, una entrada de archivo en un nodo que enviaba 64 KiB y luego 16 KiB cada cuatro minutos no había enviado nada a rclone cuando rclone se rendía exactamente a los cinco minutos, tres veces seguidas: todo lo que el nodo había enviado seguía en el búfer.
