# zurg

zurg reúne tus cuentas de debrid y tu biblioteca de Usenet en una sola carpeta virtual. No guarda ningún video en local. Nada se descarga hasta que un reproductor lo pide. Un remux de 60 GB no ocupa 60 GB de espacio en tu disco.

Cuatro vistas de la misma biblioteca:

| Endpoint | Para |
|---|---|
| `/dav/` | WebDAV, lo que monta rclone |
| `/http/` | Explorador de directorios en HTML |
| `/infuse/` | Variante de WebDAV con los detalles de Infuse resueltos |
| `/strm/` | URLs firmadas dentro de archivos `.strm`, para reproductores que quieren una URL y no un montaje |

## Configuración {#setup}

Pon zurg en marcha en tu equipo.

- [Linux](setup/linux.md) — FUSE 3 y arranque automático con systemd
- [Docker](setup/docker.md) — un host Linux con un montaje visible desde el host
- [macOS](setup/macos.md) — macFUSE y arranque automático con launchd
- [Windows](setup/windows.md) — WinFsp y una tarea con letra de unidad

## Proveedores {#providers}

Apunta zurg a una cuenta. Cada página explica la credencial y la entrada de `config.yml`. Los
ejemplos usan Docker. Una instalación binaria usa la misma entrada de configuración. Consulta
[Configuración](setup/index.md) para ver los comandos.

| Página | Qué tiene de diferente |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | Selección por archivo, `__downloads__`, elección del host de CDN, un token `.strm` aparte |
| [TorBox](providers/torbox.md) | Una solicitud por cada actualización de la biblioteca, y un límite de slots activos en lugar de uno de ancho de banda |
| [AllDebrid](providers/alldebrid.md) | Las listas de archivos llegan desde su propio endpoint, así que el primer escaneo se completa poco a poco |
| [Premiumize](providers/premiumize.md) | Transferencias completadas más los archivos de la nube que quedaron, con sus carpetas intactas |
| [Debrid-Link](providers/debridlink.md) | El listado del seedbox incluye todos los archivos, y no hay comprobación de caché |
| [Offcloud](providers/offcloud.md) | Tamaños comprobados contra el servidor de entrega, rutas de carpetas desde metadatos en caché |
| [Usenet](providers/usenet.md) | El tipo `nzb` como entrada de proveedor. Sin token, en su lugar un directorio de vigilancia |
| [Límites de TorBox](providers/torbox-limits.md) | Las cifras medidas detrás de la limitación de TorBox, y cómo zurg regula su ritmo frente a ellas |
| [Servidor de noticias de TorBox](providers/torbox-news-server.md) · [Servidor de noticias de ElfHosted](providers/elfhosted-news-server.md) | Qué son las cuentas de Usenet incluidas, a nivel de red |

[La página compartida](providers/index.md) explica las tres formas de añadir una cuenta en
Docker y las reglas que aplica el cargador de configuración.

## Guías {#guides}

- [Usenet](guides/usenet.md) — el backend `nzb` de principio a fin: cuentas de noticias, NZB, el montaje, Plex
- [Sonarr y Radarr para Usenet](guides/sonarr-radarr.md) — los \*arr buscan y zurg responde como un SABnzbd, así que las importaciones son un renombrado y no una descarga
- [Sonarr y Radarr para torrents](guides/sonarr-radarr-torrents.md) — lo mismo, con zurg respondiendo como un qBittorrent; Prowlarr también
- [Búsquedas de zurg para Sonarr y Radarr](guides/sonarr-radarr-fetch.md). Radarr y Sonarr guardan la lista, y zurg encuentra y coloca el release. No hay indexadores ni cliente de descargas en ninguno de los dos.
- [`__magic__`](guides/magic.md) — el único directorio cuyo diseño se guarda, y por tanto tuyo para organizarlo, con tu biblioteca archivada por título para Kodi y Plex
- [Renombrado](guides/renaming.md) — renombra un release o un archivo en cualquier parte de la biblioteca. Si un movimiento se rechaza, la página explica por qué
- [Plex](guides/plex.md) — lo que zurg hace con un token de Plex, y lo que deliberadamente no hace
- [Jellyfin](guides/jellyfin.md) — lo mismo, para Jellyfin
- [rex con zurg](../rex/with-zurg.md) — un servidor multimedia para las apps de Plex que no posee archivos, alimentado por zurg desde tu cuenta de debrid. Más en [rex](../rex/index.md)
- [El addon de Stremio](guides/stremio.md) — Stremio buscando en tus propios indexadores, y reproduciendo directamente desde el backend de Usenet
- [Watchlist y Seerr](guides/acquisition.md) obtiene lo que pides a través de tus propios indexadores
- [Watchlist de Plex](guides/plex-watchlist.md) es la parte de Plex de eso
- [Lista de deseados de DMM](guides/dmm-wanted.md) obtiene lo que marcas con Want en DMM, sin nada más que configurar
- [Bibliotecas locales](guides/local-libraries.md) reproduce una lista compartida de releases a través de tu propia cuenta
- [Android y Google TV](guides/android.md) ejecuta toda la biblioteca en un teléfono o en un box de TV

## Migración {#migrating}

Mueve una biblioteca existente a zurg sin volver a descargar ni a escanear.

- [Desde AltMount](migrate/altmount.md)
- [Desde decypharr](migrate/decypharr.md)
- [Desde InfiniDysk](migrate/infinidysk.md)
- [Desde nzbdav](migrate/nzbdav.md)
- [Desde streamnzb](migrate/streamnzb.md)

## Referencia {#reference}

- [Configuración](reference/config.md) — cada opción en `config.yml`
- [Línea de comandos](reference/cli.md) lista cada comando y flag que acepta el binario
- [Identidad saliente](reference/outbound-identity.md) explica qué le dice zurg a los servicios que llama sobre sí mismo
- [Servidor MCP](reference/mcp.md) permite que un agente de IA controle zurg a través del Model Context Protocol
- [Tags](reference/tags.md) — qué se aplica a un torrent, y por qué
- [Changelog](reference/changelog.md) — qué cambió y cuándo

## Internos {#internals}

Cómo está construido zurg, con qué se midió y las notas de diseño detrás de las partes más complicadas.

- [Arquitectura](internals/architecture.md): la forma general del conjunto y los invariantes que son fáciles de romper
- [Línea base de debrid](internals/debrid-baseline.md): cuánto cuesta zurg y qué tan rápido se siente en RD, AD y TorBox
- [Ciclo de vida de torrents](internals/torrent-lifecycle.md): lo que informa realmente cada cuenta mientras se ejecuta una descarga, medido en vivo
- [Contrato de cliente SABnzbd](internals/sabnzbd-client-contract.md): las formas exactas que esperan Sonarr y Radarr
- [Limpieza de basura de Plex](internals/plex-trash-sweep.md) · [Regresión de timeout de streaming](internals/stream-timeout-regression.md) · [UI/UX de configuración de directorios](internals/uiux.md)
- [Pruebas E2E](internals/e2e-test.md) · [Notas de la API de Real-Debrid](internals/realdebrid-behavior.md)
- [Contrato de cliente qBittorrent](internals/qbittorrent-client-contract.md) · [Cachés persistentes](internals/persistent-caches.md)
- [Nomenclatura](internals/naming.md) · [Rechazo de movimiento de rclone](internals/rclone-move-refusal.md)

---

zurg se distribuye a los patrocinadores: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Patrocinador](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
