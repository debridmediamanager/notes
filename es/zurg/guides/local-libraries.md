# Bibliotecas de debrid locales y zurgtorrents portátiles {#local-debrid-libraries-and-portable-zurgtorrents}

A local library takes its membership from portable `.zurgtorrent` files. It appears in the normal WebDAV, HTTP and provider directories. Importing files, listing them and refreshing the catalog do not add torrents or resolve download links. Playback resolves the requested file through your configured account.

## Exportar una biblioteca {#export-a-library}

Desde el directorio de trabajo de la instancia que exporta:

+++ Linux and macOS
```sh
./zurg --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++ Windows
```powershell
.\zurg.exe --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++

`--provider` es el **nombre** de la cuenta configurada, incluido cualquier nombre personalizado. Omítelo para exportar todas las copias de debrid compatibles.
La entrada también puede ser un archivo de caché de ejecución, un directorio `dump/` heredado o un catálogo portable existente.
Para una biblioteca local, exporta su directorio de origen (`torrents/<account>`), que conserva sus referencias opcionales a otros proveedores.

La exportación funciona sin conexión. Valida todas las entradas y las colisiones en el destino antes de escribir, informa y omite las entradas de ejecución sin metadatos de archivos seleccionados, combina los lanzamientos por hash y escribe `<hash>.zurgtorrent`. Las exportaciones idénticas que ya existen son seguras de repetir.
En una migración masiva con entradas de caché heredadas malformadas, `--skip-invalid` exporta las entradas válidas e informa cuántas se omitieron. Sin esta opción, la primera entrada inválida aborta antes de escribir nada.
`--replace` permite reemplazar una exportación portable con el mismo hash; nunca autoriza sobrescribir una caché de ejecución.

Solo los archivos exportados están pensados para compartir. `data/*.zurgtorrent` sigue siendo estado privado de ejecución. Un `.zurgbackup` también contiene las credenciales de la cuenta y es una copia de seguridad de la instancia, no una biblioteca para compartir.

## Recibir una biblioteca {#receive-a-library}

Coloca los archivos exportados en `torrents/rd-local/` y luego configura la cuenta receptora:

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: YOUR_OWN_TOKEN
    download_tokens: # Optional bandwidth fallback on another RD account.
      - SECOND_RD_TOKEN
    library:
      source: local
      # Optional; defaults to torrents/<account-name>.
      path: torrents/rd-local

  - name: tb-online
    type: torbox
    token: YOUR_OWN_TORBOX_TOKEN
    # Omitted library block means the provider owns this account's catalog.
```

En Real-Debrid y AllDebrid, `download_tokens` usa el mismo catálogo local que su entrada de provider. La segunda cuenta de RD de arriba no necesita directorio, y su biblioteca de torrents no se importa.
Son credenciales de respaldo que se usan cuando se agota el límite de ancho de banda del token de descarga activo; no obligan a que todas las descargas pasen por la segunda cuenta.
Añadir una segunda entrada de RD en `providers` crea, en cambio, un catálogo separado con su propio directorio.
Todas las credenciales permanecen en la configuración y se excluyen de las exportaciones portátiles.

TorBox también acepta `download_tokens`, pero su rotación de tokens no asigna los IDs de torrent/archivo almacenados a los IDs de la otra cuenta. Usa entradas de provider de TorBox separadas para cuentas separadas, cada una con su propio catálogo local.

Las cuentas de Premiumize, Offcloud y Debrid-Link también pueden tener una biblioteca local. Ninguna tiene una referencia de archivo portátil. Por eso, igual que TorBox, cada una añade el hash a su propia cuenta en la primera reproducción y hace coincidir los archivos por ruta y tamaño. Usa una entrada de provider por cuenta.

Reinicia después de cambiar la configuración de cuentas. Las adiciones, reemplazos y eliminaciones de archivos los recoge el ciclo de actualización normal. Cada directorio se escanea un nivel de profundidad. Las rutas deben ser directorios distintos dentro de `torrents/`, para que las copias de seguridad normales los incluyan. Un directorio no legible o un reemplazo no válido conserva la última entrada válida en memoria y registra el problema. Tras reiniciar, un archivo no válido debe corregirse antes de poder entrar en el catálogo.

El mismo manifiesto puede copiarse en el directorio local de una cuenta de AllDebrid o TorBox. Contiene la identidad del contenido, no el nombre de una cuenta de provider. El mismo hash en varias cuentas aparece una sola vez con varias fuentes, usando la preferencia de cuenta y el orden de failover existentes. Los archivos duplicados para un hash dentro de un mismo directorio usan el primer nombre de archivo en orden alfabético; mantén un solo manifiesto por hash.

La pertenencia al catálogo local sobrevive a la eliminación de la biblioteca en línea del provider. Los renombrados, etiquetas, IDs de IMDb y eliminaciones de archivos se guardan de nuevo en los manifiestos. Eliminar un release local borra sus documentos de origen; no elimina los torrents del provider. Eliminar un release con copias en línea también borra esas copias en línea, como hace la eliminación normal de release completo.

Las cuentas locales no son destinos para watchlists, subidas de magnet ni subidas de archivos torrent. Añade entradas importando manifiestos. `add_torrents: false` sigue permitiendo que RD/AD canjeen una referencia compartida existente, pero impide que la reproducción cree un adjunto en el lado del provider cuando haga falta.

## Descargar una cuenta en línea a una biblioteca local {#offload-an-online-account-into-a-local-library}

Quitar un torrent de la cuenta online no borra los archivos de un release terminado. Real-Debrid y AllDebrid mantienen sus enlaces aunque el torrent se elimine. Un enlace `/d/` de Real-Debrid sigue funcionando después de borrar el torrent, y un enlace bloqueado `/f/` de AllDebrid también sigue funcionando después de borrar el magnet. El offload depende de eso. zurg escribe un release terminado en una biblioteca local del mismo servicio y, después, borra el torrent de la cuenta online, lo que libera su plaza. El release conserva su carpeta en el montaje y se reproduce con los enlaces guardados.

Configura dos entradas para la misma cuenta, una online y otra local:

```yaml
providers:
  - name: ad
    type: alldebrid
    token: YOUR_AD_TOKEN
    library:
      offload_to: ad-local     # the local entry below
      offload_after_mins: 30   # optional, 30 is the default

  - name: ad-local
    type: alldebrid
    token: YOUR_AD_TOKEN       # the same token
    library:
      source: local            # manifests live in torrents/ad-local/
```

Los releases nuevos siguen llegando a `ad`. Después de cada listado completo de esa cuenta, y cada cinco minutos, zurg mueve los releases que cumplen condiciones, uno a uno. Un release cumple condiciones cuando:

- Lleva completo en la cuenta durante `offload_after_mins`, contando desde el momento en que este proceso de zurg lo vio completo por primera vez. Si reinicias zurg, la espera vuelve a empezar.
- Cada archivo tiene un enlace válido en esa cuenta que otra cuenta puede canjear. Un release al que le falte el enlace de algún archivo se queda online.
- Está sano, no se está reparando y ninguna instancia suya sigue descargándose. Ningún pase de reparación ni cliente de descargas tiene su torrent.
- Ningún trabajo de qBittorrent de Sonarr o Radarr sigue listándolo. Activa Remove Completed Downloads en las *arr para que un trabajo se elimine después de su importación. Si no, el release se queda online hasta que elimines el trabajo.
- La adquisición no lo añadió en la última hora.
- Moverlo no cambia ningún directorio en el que esté y conserva el nombre de su carpeta. Un directorio con un filtro `provider:` que nombre la cuenta online lo perdería, así que ese release se queda online.

El orden es fijo. El manifiesto `<hash>.zurgtorrent` se escribe primero en la biblioteca local, después el release se une a la biblioteca local y, por último, se borra el torrent de la cuenta online. Si no se puede escribir el manifiesto, no se borra nada. Si falla el borrado, la copia online se queda junto a la local y la siguiente actualización muestra si el torrent sigue ahí. Si la biblioteca local ya tiene un manifiesto de ese release, se actualiza en su sitio en lugar de escribirse dos veces. Los enlaces de la cuenta online dentro del manifiesto se refrescan, y sus nombres y ediciones siguen al release tal como lo muestra el montaje. Los enlaces del otro servicio se conservan.

El release sale de `__ad__` y aparece en `__ad-local__`. Todos los demás directorios, incluido `__all__` y los tuyos, siguen listándolo con el mismo nombre. No se inicia ningún escaneo en el servidor de medios, porque nada de lo que indexa el servidor ha cambiado. Apunta Plex y otros servidores de medios a esos directorios, no a uno por cuenta.

Con las dos entradas en el mismo token, la reproducción local puede volver a asociar un release a la misma cuenta (ver más abajo), y ese torrent aparece entonces en el listado online. zurg nunca hace offload de un release cuyo torrent online sea una asociación de ese tipo, ni mientras la reproducción local esté añadiendo una, porque borrarlo rompería la reproducción que acaba de obtenerlo.

Solo Real-Debrid y AllDebrid pueden hacer offload. TorBox, Premiumize, Offcloud y Debrid-Link no tienen ningún enlace que sobreviva al torrent, así que su reproducción local vuelve a añadir el torrent y un offload no liberaría nada. zurg rechaza `offload_to` en esas cuentas.

El dashboard también puede mover un solo release. En la página de un release, la tabla Accounts muestra el botón Move to local library junto a cada copia de Real-Debrid o AllDebrid cuando existe una biblioteca local del mismo tipo, aunque no haya `offload_to`. Si el release todavía no se puede mover, el botón aparece desactivado y explica por qué. En la página de configuración, los ajustes de la cuenta ofrecen la misma opción y muestran cuántos releases se han movido desde que arrancó zurg, y el último error.

## Qué viaja en el archivo {#what-travels-in-the-file}

El formato JSON versionado tiene `format: "zurgtorrent"` y `version: 1` numérico.
Incluye el infohash, los nombres de release, la marca de tiempo de cuando se añadió, el renombrado, las etiquetas, el ID de IMDb y las rutas, tamaños y renombrados opcionales de los archivos seleccionados. Las referencias son opcionales:

| Provider | Referencia portátil | Reproducción |
|---|---|---|
| Real-Debrid | `https://real-debrid.com/d/...` canónica de 13 caracteres | Resuelve con las credenciales y la IP de descarga del destinatario. |
| AllDebrid | `https://alldebrid.com/f/...` bloqueada | Desbloquea con las credenciales del destinatario. |
| TorBox | Hash y rutas/tamaños de archivos | En la primera reproducción, obtiene un torrent del lado del destinatario y empareja sus archivos por ruta y tamaño. |
| Premiumize, Offcloud, Debrid-Link | Hash y rutas/tamaños de archivos | En la primera reproducción, añade el hash en la cuenta del destinatario y empareja sus archivos por ruta y tamaño. |

No se exportan nombres de cuenta, credenciales, IDs de torrent/archivo del provider, URLs de CDN, URLs de entrada de MediaInfo, IDs de Plex, estado de reparación ni colas de borrado. El importador rechaza los campos desconocidos y las URLs de referencia que contengan credenciales o que sean inesperadas.
No descarga las URLs al validar un manifest. Usenet mantiene su formato de origen `.nzb`; las cachés de runtime de NZB no se pueden exportar como torrents portátiles.

## Reproducción y límites {#playback-and-limits}

Local tracking cambia quién es dueño del catálogo. No garantiza que un proveedor siga teniendo los archivos o que pueda servirlos. El acceso a la cuenta, las ubicaciones de red permitidas, los slots activos, las cuotas y los límites de frecuencia siguen aplicando.

RD y AD usan referencias compartidas bloqueadas cuando están disponibles. Los manifiestos solo con hash, y una referencia de RD que la API informa como inexistente de forma definitiva, pueden establecer el contenido en la cuenta del destinatario. TorBox siempre necesita que el contenido se adjunte a la cuenta y primero reutiliza un torrent coincidente que ya esté en la cuenta del destinatario. Las adiciones usan el ritmo de peticiones que ya tiene el proveedor y se serializan por cuenta. Cuando la cuenta informa su número de slots, o zurg lo conoce, una adición a una cuenta llena se rechaza, y la siguiente petición de reproducción, después de un minuto, vuelve a intentarlo. AllDebrid, Premiumize y Offcloud no informan ninguno, así que la adición sigue adelante y una cuenta llena la rechaza. Una adición incierta se retiene durante 30 minutos antes de otro intento; un torrent en preparación solo se comprueba cuando se vuelve a pedir la reproducción.

Los IDs de los destinatarios y los file handles nativos resueltos se guardan de forma privada en `data/local-torrents/`. Ese registro sobrevive a un reinicio y se incluye en las copias de seguridad normales. zurg nunca borra esos adjuntos automáticamente: una adición idempotente puede haber devuelto un torrent que el destinatario ya tenía. La descarga (offloading) tampoco los toca. Los fallos del proveedor dejan la entrada local visible y aplican un retroceso en lugar de iniciar una reparación en segundo plano o repetir una adición en cada escaneo.

Las releases de archivos comprimidos locales muestran sus volúmenes de origen sin extracción automática ni inspección en segundo plano. Una ruta explícita dentro de un archivo todavía puede invocar al lector de archivos. La detección automática de MediaInfo y la precarga del siguiente archivo se suprimen en las entradas que tienen copias locales.

## Migrar un volcado antiguo {#migrate-an-old-dump}

Exporta `dump/` con el comando de arriba, deja los resultados en el directorio `torrents/<name>/` de la cuenta receptora y activa `library.source: local`. Desactiva `load_dumped_torrents` después de la migración. El lector `__dump__` opt-in antiguo sigue disponible por compatibilidad; las bibliotecas locales nuevas no lo usan. Las cachés de runtime sin tipo de cuenta hay que volver a exportarlas desde una instancia que conozca su proveedor antes de poder compartirlas.

Las copias de seguridad que genera esta versión usan el formato 2 para incluir las nuevas raíces duraderas. El comando de restauración sigue leyendo copias de formato 1. Las versiones anteriores rechazan el formato 2 en lugar de descartar en silencio una biblioteca local.
