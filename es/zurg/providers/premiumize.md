# Premiumize

`type: premiumize`

Premiumize monta las transferencias completadas **y** los archivos de la nube que quedan después de que se limpie la lista de transferencias. Las carpetas anidadas conservan sus rutas. Una biblioteca que hayas organizado en Premiumize llega al montaje tal como la dejaste.

## Obtén la clave de API {#get-the-api-key}

Inicia sesión y abre [premiumize.me/account](https://www.premiumize.me/account). La API key está en esa página.

## Configúrala {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

En una instalación nueva en contenedor, deja que el setup lo escriba.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

En una instalación que ya tiene un `config.yml`, usa **Add provider** en el Dashboard en `http://localhost:9999/config/` o edita el archivo. Reinicia de cualquiera de las dos formas.

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` lo lee `zurg setup` y no el daemon en ejecución. No hace nada si solo está en un bloque `environment:` de compose.

## Una credencial por entrada {#one-credential-per-entry}

Los ID de archivo de Premiumize pertenecen a la cuenta que los listó. No hay una segunda clave a la que rotar. `download_tokens` se rechaza directamente, y también un `strm_link_token` que sea distinto de `token`. Una segunda cuenta de Premiumize es una segunda entrada con su propio `name`.

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

El cargador es explícito en esto en lugar de ignorar las claves en silencio. Rechaza la configuración y nombra la entrada.

## Qué funciona aquí {#what-works-here}

Navegar por la biblioteca, las lecturas en streaming, las lecturas redirigidas, los STRM, añadir magnets y subidas de archivos `.torrent`, y borrar, funcionan todos. La cuenta obtiene su propio directorio `__premiumize__`, igual que todas las demás.

## Los hashes se recuerdan en el disco {#hashes-are-remembered-on-disk}

Los hashes que llegan a través de zurg se guardan en
`data/premiumize/<account>/sources.json` dentro del bind de `/config`. La
coincidencia entre cuentas sobrevive a un reinicio y a borrar la lista de
transferencias completadas.

El contenido de la nube que importaste por otros medios no tiene un hash
registrado. Aun así se reproduce en streaming. No se puede reparar por hash y
tampoco emparejarlo con otra cuenta por hash.

!!!warning Borrar una transferencia borra sus archivos
Borrar una transferencia de Premiumize a través de zurg también borra los
archivos que esa transferencia contiene. Es un comportamiento propio de
Premiumize, no algo que zurg añada por encima.
!!!

## Límites que conviene conocer {#limits-worth-knowing}

**Los límites de almacenamiento en la nube y del uso justo son los propios de la cuenta.** zurg no los sube ni los salta.

**8 peticiones de API simultáneas.** Cuatro volúmenes de un archivo de varias partes se resuelven a la vez.

**El contenido caduca.** Que una publicación haya desaparecido es un resultado esperado y no un fallo. Repair la deja tal cual, salvo que se lo pidas.

**La lista de torrents no incluye detalle de archivos.** Cada publicación necesita su propia consulta la primera vez.

zurg asigna los códigos de error del servicio a lo que debe hacer a continuación.

| Código de Premiumize | Qué hace zurg |
|---|---|
| `authentication_failed` | Informa de una credencial incorrecta. Corrige la clave. |
| `rate_limit_reached` | Pausa la cuenta durante un minuto. |
| `account_limit_reached` o `service_limit_reached` | Informa de que se ha agotado la cuota. |
| `service_down` | Considera la cuenta como no disponible temporalmente. |
| `not_found` | Considera que el torrent ya no existe. |

## Comprueba que funcionó {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

Con una sola cuenta, su propia carpeta se deja fuera del listado raíz del montaje, así que el montaje muestra los mismos archivos dentro de `__all__`.

## Cuando algo sale mal {#when-it-goes-wrong}

**Todo falla con un error de credenciales.** Regenera la clave en [premiumize.me/account](https://www.premiumize.me/account) y actualiza la entrada.
Ten en cuenta que Premiumize responde igual cuando falta la clave que cuando la clave es incorrecta. El mensaje no te dice cuál de los dos casos es.

**Una versión se reproduce pero no se repara.** No tiene un hash registrado. Eso significa que llegó a la cuenta por otra vía distinta de zurg. Mira lo indicado más arriba.

**Las lecturas se detienen un minuto cada vez.** Se alcanzó el límite de peticiones y zurg pausó la cuenta a propósito. Se reanuda sola.

**Las URLs generadas funcionan para cualquiera que las tenga.** Las URLs de entrega y el acceso a `.strm` conviene mantenerlos en privado. La cuota que consumen es la de tu propia cuenta.
