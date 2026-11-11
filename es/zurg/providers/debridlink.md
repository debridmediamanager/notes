# Debrid-Link

`type: debridlink`

El listado de seedbox de [Debrid-Link](https://debrid-link.com/id/diG1t) incluye todos los archivos. Actualizar la biblioteca cuesta un solo recorrido paginado, en lugar de una búsqueda por cada release. Es el más económico de los tres backends en la nube para mantenerlo sincronizado.

## Obtén la clave de API {#get-the-api-key}

Inicia sesión y abre [debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey). Genera una clave y cópiala.

## Configúrala {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

En una instalación nueva del contenedor, deja que setup lo escriba.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

En una instalación que ya tiene un `config.yml`, usa **Add provider** en el Dashboard en `http://localhost:9999/config/` o edita el archivo. Reinicia de cualquier forma.

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` lo lee `zurg setup` y no el daemon en ejecución.

## Una credencial por entrada {#one-credential-per-entry}

Debrid-Link resuelve cada archivo mediante un ID que pertenece a la cuenta del listado.
No hay una segunda clave a la que rotar. Se rechaza `download_tokens` y también un
`strm_link_token` que sea distinto de `token`. Una segunda cuenta es una segunda entrada
con su propio `name`.

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## Qué funciona aquí {#what-works-here}

Navegar por la biblioteca, las lecturas en streaming, las lecturas redirigidas, los STRM, añadir magnets y subidas de `.torrent`, y la eliminación, todo funciona. La cuenta tiene su propio directorio `__debridlink__`.

## Límites que conviene conocer {#limits-worth-knowing}

**20 slots activos.** Ese es el límite que zurg impone para añadir más.

**8 peticiones de API simultáneas.** Cuatro volúmenes de un archivo de varios volúmenes se resuelven a la vez.

**El contenido caduca.** Una release que ya no está se considera lo esperado, no un fallo.

**No hay comprobación de caché.** Debrid-Link retiró ese endpoint y zurg no lo usa. Un add solo-en-caché únicamente puede confirmar un acierto a partir de la propia respuesta del add. Preguntar si algo está en caché antes de añadirlo es algo que este backend no puede responder.

zurg asocia los códigos de error del servicio con lo que debe hacer a continuación.

| Código de Debrid-Link | Qué hace zurg |
|---|---|
| `badToken` o `badSign` | Informa de una credencial incorrecta. Corrige la clave. |
| `floodDetected` | Pausa la cuenta durante una hora. |
| `maxTorrent` `maxData` `maxLink` y sus variantes `Host` | Informa de que se ha agotado la cuota diaria de adds o de tráfico. |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | Trata la cuenta como temporalmente no disponible. |
| `badId` | Trata el torrent como desaparecido. |

!!!warning Un rechazo por flood cuesta una hora
`floodDetected` deja la cuenta parada una hora completa en lugar de un minuto. Es intencionado. Reintentar durante un rechazo por flood es lo que provoca el siguiente. Espacia lo que estuviera saturando el servicio antes de reiniciar zurg.
!!!

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

Con una sola cuenta, su propia carpeta se deja fuera del listado raíz del montaje, así que el montaje muestra los mismos archivos dentro de `__all__`.

## Cuando algo sale mal {#when-it-goes-wrong}

**Nada pasa durante una hora.** Un rechazo de tipo flood. Mira la advertencia de arriba.

**Los grabs se rechazan pero las lecturas siguen funcionando.** La cuota diaria de añadidos o de tráfico se ha agotado. Se reinicia según el propio calendario del servicio.

**Los añadidos se completan y luego se quedan ahí.** Sin un endpoint de caché no hay forma de saber de antemano si un hash ya estaba disponible. Un añadido no cacheado se descarga como cualquier otro.
