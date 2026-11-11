# Offcloud

`type: offcloud`

Offcloud resuelve los identificadores de archivo a través de su endpoint de exploración de la nube. Los tamaños de los archivos se comprueban contra el servidor de entrega en lugar de fiarse del listado.
Los metadatos del torrent en caché proporcionan las rutas de las carpetas siempre que se puedan emparejar sin ambigüedad.

## Obtén la clave de API {#get-the-api-key}

Inicia sesión y abre [offcloud.com/#/account](https://offcloud.com/#/account). La clave de API está en esa página.

## Configúrala {#configure-it}

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

En una instalación nueva en contenedor, deja que setup lo escriba.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

En una instalación que ya tiene un `config.yml`, usa **Add provider** en el Dashboard en `http://localhost:9999/config/` o edita el archivo. Reinicia en cualquier caso.

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` lo lee `zurg setup` y no el daemon en ejecución.

## Una credencial por entrada {#one-credential-per-entry}

Los identificadores de archivo de Offcloud pertenecen a la cuenta que los listó. No hay una segunda clave a la que cambiar. `download_tokens` se rechaza, y también un `strm_link_token` que sea distinto de `token`. Una segunda cuenta es una segunda entrada, con su propio `name`.

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## Qué funciona aquí {#what-works-here}

Explorar la biblioteca, las lecturas en streaming, las lecturas redirigidas, los STRM, la adición de magnets y las subidas de `.torrent`, y también la eliminación, funcionan todos. La cuenta tiene su propio directorio `__offcloud__`.

## Límites que conviene conocer {#limits-worth-knowing}

**8 solicitudes de API simultáneas.** Se resuelven cuatro volúmenes de un archivo de varios volúmenes al mismo tiempo.

**El contenido caduca.** Un lanzamiento que ya no está se considera lo esperado, no un fallo. Repair no lo toca a menos que lo pidas.

**La lista de torrents no incluye detalles de los archivos.** Cada lanzamiento requiere su propia consulta la primera vez.

**Un listado de archivos ambiguo se trata como error, no como una suposición.** A veces los metadatos del torrent en caché no se pueden asociar a un único lanzamiento. zurg lo informa en lugar de elegir rutas de carpetas que podrían pertenecer a otra cosa.

**Los magnets mal formados se rechazan localmente.** Nunca llegan al servicio. Un magnet malo no cuesta nada.

El vocabulario de fallos de Offcloud es escaso. `NOAUTH` es el único código con el que zurg puede hacer algo, y significa que la credencial fue rechazada. Todo lo demás llega como un rechazo sin motivo.

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__all__/ | head
```

Con una sola cuenta, su propia carpeta se deja fuera del listado raíz del montaje, así que el montaje muestra los mismos archivos dentro de `__all__`.

## Cuando algo sale mal {#when-it-goes-wrong}

**`NOAUTH` en el log.** La clave fue revocada o regenerada. Consigue una nueva en
[offcloud.com/#/account](https://offcloud.com/#/account) y actualiza la entrada.

**`API refused request` sin nada más.** Offcloud no dijo por qué. Revisa la
cuenta en el navegador antes de suponer que el fallo es de zurg.

**Una release no muestra carpetas.** Los metadatos cacheados del torrent no
pudieron asociarse a exactamente una release. Los archivos se pueden reproducir
igualmente. Simplemente están sin carpetas.

**Las URLs generadas funcionan para cualquiera que las tenga.** Las URLs de
entrega se renuevan cuando caduca su caché o cuando una lectura las invalida.
La cuota que gastan es la de tu propia cuenta. Mantén privados ellas y el
acceso a `.strm`.
