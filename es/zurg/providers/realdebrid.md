# Real-Debrid

`type: realdebrid`

zurg empezó como un servidor de [Real-Debrid](http://real-debrid.com/?id=20476302) y todavía es el que mejor conoce. Es el único backend con selección de archivos por archivo, una lista separada `__downloads__`, selección de host CDN y un token dedicado para `.strm`.

## Obtén el token de API {#get-the-api-token}

Inicia sesión y abre [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354).
El token es una cadena hexadecimal larga. Copia todo.

!!!warning Desactiva primero el tráfico remoto automático
En tu [página de cuenta](http://real-debrid.com/?id=20476410) asegúrate de que **Use my
Remote Traffic automatically when needed** esté desmarcado. Si lo dejas activado, gastarás
tu cuota de tráfico remoto en la reproducción normal sin avisarte.
!!!

## Configúrala {#configure-it}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

En una instalación nueva en contenedor, deja que el asistente de configuración lo escriba por ti.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

En una instalación que ya tiene un `config.yml`, usa el Dashboard en
`http://localhost:9999/config/` o edita el archivo. Luego reinicia.

```bash
docker compose restart zurg
```

### El único proveedor que un contenedor puede cargar desde el entorno {#the-one-provider-a-container-can-seed-from-the-environment}

Real-Debrid es la única cuenta para la que el daemon en ejecución crea una configuración por sí solo. `TOKEN` o `RD_TOKEN` en el bloque `environment:` de tu compose sirve para rellenar `config.yml` en la ejecución que lo crea. `MOUNT_PATH` sirve para rellenar el mount.

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

Ambas variables se leen **solo** en esa primera ejecución. Una vez que el archivo existe, es la única fuente de verdad. Una variable antigua nunca puede deshacer en silencio una ruta de mount que hayas configurado en el Dashboard. Al arrancar, se muestra un aviso si un `MOUNT_PATH` se está ignorando por ese motivo.

## Claves extra que usa este backend {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` son tokens de API de respaldo del mismo servicio. Entran en acción cuando
se agota el ancho de banda del token activo. Usan el catálogo de esta entrada
y sus bibliotecas de torrents propias nunca se importan.

`strm_link_token` resuelve las lecturas que llegan a `/strm/` para que, cuando un reproductor abre
un archivo `.strm`, no gaste el token con el que tu montaje en vivo está transmitiendo. Si no se define, usa `token`.

Ambos valen la pena aquí porque Real-Debrid es uno de los dos backends que
rota las credenciales.

## Lo que Real-Debrid hace y los demás no {#what-real-debrid-does-that-the-others-do-not}

- **Selección por archivo.** Al añadir un lanzamiento se puede descargar solo una parte. Así `force_select_playable_files` tiene algo sobre lo que actuar, y la reparación puede limitarse a los archivos rotos en lugar de volver a añadir todo el lanzamiento.
- **Una segunda lista llamada downloads.** `__downloads__` en la raíz del montaje es la lista de enlaces sin restricción, que solo tiene Real-Debrid. Borrarla en bloque necesita una cookie de sesión web. Por eso el botón del Dashboard es la única vía. Si una instalación no tiene cuenta de Real-Debrid, se le indica así en lugar de mostrarle un éxito falso.
- **Selección de host CDN.** `rd_cdn_host_preference` elige entre la opción de Real-Debrid, sus gemelos de Cloudflare o un país concreto. Consulta [CDN and host selection](../reference/config.md#cdn--host-selection).
- **Reparación.** Un enlace de Real-Debrid asociado a un archivo puede dejar de funcionar mientras el torrent sigue apareciendo como sano. Esa es precisamente la razón por la que zurg tiene un subsistema de reparación, y es el único backend que lo necesita.

## Límites que conviene conocer {#limits-worth-knowing}

**Dos añadidos en una misma cuenta necesitan 20 segundos entre ellos.** Medido contra la API en directo el 2026-08-17. Seis nombres de release limpios añadidos con diez segundos de diferencia fueron rechazados seis de seis veces. Los mismos seis, con veinte segundos de diferencia, fueron aceptados seis de seis veces. zurg ajusta sus propios añadidos a ese mínimo.

**Un añadido rechazado parece exactamente igual que un nombre de archivo bloqueado.** Real-Debrid responde a ambos con `451 infringing_file`. El limitador también tiene memoria. Una vez activado, sigue rechazando durante minutos aunque no haya actividad. Un barrido de reparación en producción pasó cuatro horas sin añadir nada porque tres añadidos cayeron con trece segundos de diferencia al principio.

**Algunos releases se rechazan solo por su nombre.** Desde el 14 de octubre de 2026 son once cadenas. WEB-DL, WEB.x264 y WEB.H264 solo cuentan en ese caso exacto, así que web-dl, Web-Dl y el WEB.h264 de la scene pasan. WEBRip, BDRip, HDRip, DVDRip, HDTV.x264, HDTV.XviD, BluRay.x264 y p.BluRay.DTS cuentan en cualquier combinación de mayúsculas y minúsculas. Ese último necesita una p justo delante, como en 1080p.BluRay.DTS. Un release 2002.BluRay.DTS está bien. Solo cuenta el separador exacto. WEB.DL, WEB-x264 y BluRay-x264 pasan sin problema. Un release con uno de esos nombres se rechaza en la primera petición, siempre, sin importar lo que haya detrás. Un archivo dentro de un release cuyo propio nombre coincide se acepta, pero no se reproduce. zurg conoce los patrones y rechaza esas descargas en local, en lugar de gastar un hueco de añadido y dos reintentos de sesenta segundos en un fallo seguro.

**Una segunda copia de contenido que la cuenta ya tiene nunca se descarga.** Real-Debrid acepta el añadido y luego no descarga nada. La instancia se queda en 0 por ciento con 0 seeders para siempre.

**La lista de torrents no incluye detalles de archivos.** Cada torrent necesita su propia llamada de información. Por eso zurg mantiene una caché de información en disco. Un escaneo en frío de una biblioteca grande es el caso caro, y la caché es lo que evita que se repita.

Tres claves regulan el ritmo de la API, y los valores por defecto sirven para una cuenta normal.

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Con una sola cuenta, su propia carpeta se omite del listado raíz del montaje,
así que el montaje muestra los mismos archivos bajo `__all__`.

## Cuando algo sale mal {#when-it-goes-wrong}

**`RD Permission denied` en el log.** La clave fue revocada o rotada. Consigue una nueva en [real-debrid.com/apitoken](http://real-debrid.com/?id=20476302) y actualiza la entrada en el Dashboard o en `config.yml`.

**Cada grab devuelve 451.** O bien el nombre del release es uno que Real-Debrid rechaza directamente, o las adiciones llegaron demasiado seguidas y el throttle sigue activo. Se resuelve esperando sin hacer nada, no con reintentos.

**La montura no lista nada en el primer inicio.** Una biblioteca grande tarda un rato en cargarse. `/dav/movies/` responde 503 hasta que termine.

**Los enlaces pasan la verificación y luego no sirven nada.** Activa `use_range_verification` para que zurg compruebe con un GET con rango de un byte en lugar de un `HEAD`. Algunas redes y algunos servidores de Real-Debrid responden mal a un `HEAD`.
