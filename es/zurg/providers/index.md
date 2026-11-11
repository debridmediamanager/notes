# Proveedores {#providers}

Un proveedor es una cuenta a partir de la cual zurg construye su biblioteca. Cada cuenta es una
entrada bajo `providers:` en `config.yml`. Usa una sola cuenta o seis. Una versión que esté en más de una de ellas aparece listada una sola vez y se lee desde la cuenta que pueda servirla en ese momento.

| Servicio | `type` | Página |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| Usenet alojado en TorBox | `torbox_nzb` | [Usenet alojado en TorBox](torbox-nzb.md) |

Tres páginas van más allá de la configuración. [Límites de TorBox](torbox-limits.md) reúne las cifras medidas detrás de la limitación de TorBox.
[Servidor de noticias de TorBox](torbox-news-server.md) y [Servidor de noticias de ElfHosted](elfhosted-news-server.md) registran qué son realmente las cuentas de Usenet incluidas con esos planes.
Compruébalo ahí antes de gastar un espacio de proveedor en él.

Todas las páginas de aquí asumen la instalación en contenedor de [Configuración con Docker](../setup/docker.md). `~/zurg` es el directorio de compose en el host. `/config` es ese mismo directorio visto desde dentro del contenedor. Solo hay un `config.yml` y ambos nombres llegan a él.

En una instalación binaria en Linux, macOS o Windows, [Configuración](../setup/index.md) indica qué reemplaza a `docker compose restart zurg` y a la línea `setup`. Las comprobaciones se traducen de la misma forma. Ejecútalas desde la carpeta de zurg. Lee `logs/zurg.log` en lugar de `docker compose logs` (`Get-Content logs\zurg.log -Tail 100 -Wait` en PowerShell). Ejecuta `./zurg doctor` (`.\zurg.exe doctor`) sin `--working-dir /config`. Lista tu propio montaje en lugar de `/zurg_mnt/zurg`: `/mnt/zurg`, `/Volumes/Zurg` o `Z:\`, a menos que hayas cambiado `mount_path`. En Windows PowerShell 5.1 escribe `curl.exe`, no `curl`.

## Tres formas de añadir una cuenta {#three-ways-to-add-an-account}

Cuál quieres depende de si `config.yml` ya existe.

### En una instalación nueva usa setup {#on-a-fresh-install-use-setup}

`zurg setup` pregunta qué proveedores quieres configurar y solo pide sus credenciales. Escribe las cuentas **solo cuando todavía no existe un `config.yml`**. Si lo ejecutas más adelante, actualizará la instalación sin tocar las cuentas que ya tienes.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

El selector acepta números o nombres, y puedes elegir varios a la vez.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

Nada de lo que escribes termina en el archivo de compose ni en el historial de tu shell. El token va directamente a `config.yml`, y el archivo se guarda con permisos solo para el propietario.

### En una instalación existente usa el Dashboard {#on-an-existing-install-use-the-dashboard}

Abre `http://localhost:9999/config/` y usa **Add provider** en Essentials.
Elige el tipo. Pega el token. Guarda. El Dashboard escribe la entrada de vuelta en
el mismo `config.yml` que está junto a tu archivo compose.

Los cambios de proveedor necesitan un reinicio para surtir efecto. El Dashboard lo indica
y el reinicio es un solo comando.

```bash
docker compose restart zurg
```

### O edita config.yml a mano {#or-edit-configyml-by-hand}

El archivo es `~/zurg/config.yml` en el host. Añade la entrada y reinicia.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` es `/zurg_mnt/zurg` en un contenedor y el archivo compose tiene que enlazar
`/zurg_mnt:/zurg_mnt:rshared` para que el montaje llegue al host. Eso está en la página de [configuración con Docker](../setup/docker.md) y es la única parte de una instalación en contenedor que no es igual que una instalación binaria.

## Instalaciones desatendidas {#unattended-installs}

Cada proveedor tiene un flag de archivo de token y una variable de entorno. Repite `--provider` por cada cuenta que quieras.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | Flag | Variable de entorno |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` or `TOKEN` or `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` with `--nntp-host` and `--nntp-username` | `NNTP_HOST` y similares |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` nunca se deduce solo a partir de `TORBOX_TOKEN` o `--torbox-token-file`; pasa `--provider torbox_nzb`.

Con `--non-interactive` y sin ningún `--provider`, el setup usa las variables de esa lista que estén definidas.

!!!warning Solo Real-Debrid lo carga el contenedor en ejecución
El daemon de zurg lee por sí mismo `TOKEN`, `RD_TOKEN` y `MOUNT_PATH` en la ejecución que crea `config.yml`. Esa es la lista completa. `TORBOX_TOKEN` y el resto los lee `zurg setup`. Poner una de esas variables en el bloque `environment:` de tu compose y arrancar el contenedor no hace nada por sí solo. Ejecuta el setup o añade la cuenta en el Dashboard.
!!!

## Lo que acepta cada entrada {#what-every-entry-accepts}

| Key | Qué hace |
|---|---|
| `type` | Obligatorio. Uno de los ocho tipos de arriba. |
| `name` | Por defecto es `type`. Sirve para distinguir dos cuentas del mismo servicio. |
| `token` | La clave de API. `nzb` no la usa. |
| `disabled` | Pausa la cuenta sin borrar la credencial. |
| `watchlist` | Marca la cuenta a la que se intentan asignar primero los nuevos torrents. |
| `add_torrents` | Si lo pones en `false`, la cuenta sigue sirviendo contenido, pero nunca recibe nada nuevo. |
| `warm_connections` | Conexiones que se mantienen abiertas por host, para que una lectura no tenga que abrir una nueva. |

Las descripciones completas y todo lo demás están en la [referencia de configuración](../reference/config.md#accounts).

## Reglas que aplica el loader {#rules-the-loader-enforces}

- Los nombres deben ser únicos. Dos cuentas de Real-Debrid necesitan `name: rd-main` y `name: rd-backup`, o la carga falla.
- El nombre `e` está reservado para el enrutamiento de enlaces `.strm`. Elige otro.
- Como máximo una entrada puede tener `watchlist: true`.
- No se acepta `watchlist: true` y `add_torrents: false` en la misma entrada.
- Solo se admite una entrada `nzb` o `torbox_nzb` habilitada. Los servidores de noticias adicionales van en `nntp.servers` de una entrada `nzb`.
- Si todas las entradas están deshabilitadas, la carga falla.
- Premiumize, Debrid-Link y Offcloud no aceptan `download_tokens` ni un `strm_link_token` distinto de `token`. Sus IDs de archivo pertenecen a una sola cuenta, así que una segunda cuenta tiene que ser una segunda entrada.

## Comprueba que funcionó {#check-it-worked}

Empecemos por el log y el diagnóstico.

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` es lo esperado en Docker, porque Compose se encarga del inicio automático. Las advertencias no hacen que doctor falle. Solo falla con un `FAIL`.

Luego verifica la cuenta en sí desde el Dashboard o desde la shell.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` significa que la credencial se autenticó. El nombre en la ruta es el `name` de la cuenta. Por defecto es su `type`. Añade `-u user:pass` si has definido un `username` en `config.yml`. Si no lo has hecho, el Dashboard y su API están abiertos en el puerto que publicaste.

Por último, revisa la biblioteca en el mount.

```bash
ls /zurg_mnt/zurg/__all__/
```

Cada cuenta configurada tiene un directorio `__<name>__`. Contiene todo lo que tiene esa cuenta, y fija las lecturas a esa cuenta. `__torbox__/Some.Release/` se transmite desde TorBox y desde ningún otro sitio. La carpeta de una sola cuenta no aparece en el listado de la raíz del mount, ya que `__all__` es la misma biblioteca. Las rutas HTTP y WebDAV directas, como `/http/__torbox__/`, siguen respondiendo. A través del mount ya no se resuelven; apunta cualquier biblioteca o script que usara `__<name>__` a `__all__`.

Una biblioteca grande tarda un rato en cargarse la primera vez. Hasta que termine, `/dav/movies/` responde 503 y es posible que el mount no muestre nada.

## Ejecutar varias cuentas {#running-several-accounts}

El orden importa en un solo caso. El orden de la lista `providers:` es el orden en que se prueban las cuentas que reciben adds. Una cuenta con `watchlist: true` se prueba primero, esté donde esté en la lista. Para listar y leer, el orden no da ningún privilegio.

Hay dos cosas que conviene saber antes de apuntar un servidor de medios al resultado.

- La misma versión aparece en tus directorios filtrados **y** en cada directorio `__<name>__` que la contiene. Apunta Plex o Jellyfin a una parte del montaje y no a todo, o escaneará el mismo contenido varias veces.
- No hay failover silencioso dentro de un directorio `__<name>__`. Un archivo caído en una cuenta da 404 allí y se reproduce desde el directorio de otra cuenta. El resto del montaje lo sirve con normalidad.
