# TorBox

`type: torbox`

[TorBox](https://torbox.app/subscription?referral=74ffa560-7381-4a18-adb1-cef97378c670) es la biblioteca más barata para que zurg la mantenga sincronizada, y también la más fácil de limitar al leer. Su lista de torrents ya incluye todos los archivos. Actualizar la biblioteca cuesta una sola petición, en lugar de una por torrent. Su endpoint de resolución de enlaces tiene una cuota fija, no una tasa. zurg es muy cuidadoso con él a propósito.

## Obtén la clave de API {#get-the-api-key}

Inicia sesión y abre [torbox.app/settings](https://torbox.app/settings). La clave de API está en esa página.

**Una cuenta gratuita no funciona con zurg.** TorBox responde a todas las peticiones de la biblioteca con una clave gratuita con `PLAN_RESTRICTED_FEATURE`, así que zurg no puede leer lo que tiene la cuenta. Usa un plan de pago. Un plan de pago que caduca se convierte en uno gratuito de la misma forma.

## Configúrala {#configure-it}

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

En una instalación nueva en contenedor, deja que setup lo escriba.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

En una instalación que ya tiene un `config.yml`, usa **Add provider** en el Dashboard en `http://localhost:9999/config/` o edita el archivo. En cualquier caso, reinicia después.

```bash
docker compose restart zurg
```

!!!warning Una clave de TorBox en el entorno de tu compose no hace nada por sí sola
`TORBOX_TOKEN` lo lee `zurg setup` y no el daemon en ejecución. Solo el `TOKEN` de Real-Debrid crea una configuración en el primer inicio. Pasa la clave a un contenedor de setup o añade la cuenta en el Dashboard.
!!!

Para una instalación desatendida, indica a setup un archivo en lugar de una variable de entorno.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## Dos claves que no aplican aquí {#two-keys-that-do-not-apply-here}

`download_tokens` se acepta, pero no hace en Real-Debrid lo que hace en otros lados.
Cambiar a una segunda clave no vuelve a asignar los IDs de torrents y archivos. En TorBox, esos IDs pertenecen a la cuenta que los listó. Una segunda cuenta de TorBox necesita su propia entrada, con su propio `name`.

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` se acepta, pero no se usa. TorBox genera una URL de descarga por cada petición. No hay una credencial de larga duración a la que un archivo `.strm` pueda quedar atado.

## Los slots activos son el límite real {#active-slots-are-the-real-ceiling}

TorBox tiene una restricción que lo define: cuántos torrents pueden estar descargándose o compartiéndose al mismo tiempo. Real-Debrid tiene la suya en el ancho de banda. TorBox tiene la suya en slots.

| Plan | Active slots |
|---|---|
| Free | 1 pero zurg no puede usar una clave gratuita (ver arriba) |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

zurg lee el plan de la cuenta y limita cuántos más puedes añadir según ese plan. Una cuenta cuyo plan no puede leer se trata como si tuviera 3.

Calcula todo lo demás que añade torrents con el mismo presupuesto. Sonarr y Radarr descargando a través del endpoint de qBittorrent, un barrido de reparación y una lista de seguimiento también usan esos mismos slots.

## Límites que conviene conocer {#limits-worth-knowing}

**La resolución de enlaces es un presupuesto de unas cien llamadas y no una tasa.**
Medido el 2026-08-30. Un 429 con `Retry-After: 300` llegó en la llamada acumulada 100 cuando las llamadas se lanzaban lo más rápido posible. Llegó en la llamada 94 cuando se espaciaban a una por segundo. El bloqueo afecta a toda la cuenta. Detiene todo el montaje durante cinco minutos y no solo la lectura que lo activó.

De ahí se deducen dos cosas, y zurg las aplica por sí solo.

- Nunca resuelve un archivo que nadie haya pedido. Los demás backends adelantan el siguiente episodio. TorBox no puede permitirse la suposición, porque un servidor de medios que analiza una biblioteca abre cada archivo exactamente una vez, y cada una de esas aperturas es en frío.
- Resuelve los volúmenes de un archivo multivolumen estrictamente uno a uno. Hacerlo más rápido gastaría el límite varias veces y adelantaría los volúmenes posteriores a uno roto antes de que nadie descubriera que no hacían falta.

**60 adiciones sin caché por hora.** Las adiciones con caché, en cambio, entran en el presupuesto por minuto.

**300 peticiones por minuto en todos los endpoints para una misma clave.** zurg se limita a 300 menos 60, para que los reintentos que su propio cliente HTTP hace por su cuenta no empujen una ráfaga presupuestada por encima del límite real.

**La conexión número 21 a un mismo host CDN recibe un 429.** Medido el 2026-08-23 abriendo una conexión cada 500 ms y manteniéndola abierta. El límite es por host y no por clave. Repartir las lecturas entre la flota de TorBox lo evita, pero amontonarlas en un solo nodo no. zurg pone en cola a partir de 20 en lugar de marcar, lo que convierte el rechazo en una espera local breve.

**El contenido se elimina al terminar la ventana de retención del plan.** Que un torrent haya desaparecido es lo esperado y no una avería. Repair lo deja en paz salvo que lo pidas expresamente.

**No hay selección de archivos por separado.** Añadir un torrent descarga todo, y repair vuelve a añadir la release completa.

El panorama completo, con las fuentes, está en
[Límites de TorBox](torbox-limits.md).

## Elegir una región de CDN {#choosing-a-cdn-region}

```yaml
tb_cdn_host_preference: "auto"
```

`auto` deja en paz la elección de TorBox. `force_location_<region>` sirve las descargas desde esa región. Solo se pueden forzar las regiones que ahora mismo anuncian un nodo de entrega, y las listas desplegables del Dashboard muestran exactamente esas. No uses `cdn_host_preference` aquí. Esa clave es solo para Real-Debrid y sus valores son códigos de ubicación de Real-Debrid.

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__all__/ | head
```

Con una sola cuenta, su propia carpeta queda fuera del listado raíz del montaje, así que el montaje muestra los mismos archivos bajo `__all__`.

## Cuando algo sale mal {#when-it-goes-wrong}

**El log dice `Account <name> refused zurg` o se repite `TorBox rejected the API key`.**
El plan se acabó y la clave ahora está en el plan gratuito. Desde la nightly 2026.10.11.2240,
zurg carga tus otras cuentas sin ella. La tarjeta de la cuenta en el panel dice
`Refused: the account's plan does not include API access`. Sus releases siguen
listados pero no se reproducen, y no se borra ni se manda a la papelera nada por esto.
zurg vuelve a preguntar a TorBox cada 10 minutos y recupera la cuenta en cuanto el plan
esté pagado. En las nightlies anteriores, toda la biblioteca nunca terminaba de cargarse,
así que el contenido de tus otras cuentas tampoco aparecía. Actualiza zurg o renueva el plan.
Comentar el proveedor `torbox` en `config.yml` y reiniciar zurg también funciona.

**La reproducción se para cinco minutos seguidos.** El cupo de requestdl ya se gastó y el 429
afecta a toda la cuenta. Algo está resolviendo más enlaces de los que necesita.
Lo habitual es que un servidor de medios escanee todo el mount a la vez. Apúntalo a un
solo directorio en lugar de a todos.

**Las peticiones de descarga dejan de aceptarse.** O todos los slots activos están llenos
o se ha agotado el límite de adiciones por hora. Ambos se liberan solos y reintentar no ayuda.

**Un release muestra menos archivos de los que esperas.** `__torbox__` solo lista lo que
TorBox tiene realmente. Si otra cuenta tiene el release completo, el resto del mount
sigue sirviéndolo entero.

**Un torrent ha desaparecido.** Retención. Mira lo de arriba. zurg no lo volverá a añadir
sin que lo pidas, porque volver a descubrirlo gasta el presupuesto de la cuenta sin ningún beneficio.
