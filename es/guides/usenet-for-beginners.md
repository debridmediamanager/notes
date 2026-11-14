# Usenet para principiantes: qué comprar y cómo encaja con zurg {#usenet-for-beginners-what-to-buy-and-how-it-fits-with-zurg}

Para hacer streaming de Usenet con zurg necesitas una cuenta de **proveedor de Usenet**, que guarda los archivos, y **archivos NZB**, que indican dónde está cada versión. Un **indexador** es un sitio de búsqueda de NZB, pero no tienes que comprar uno: la pestaña **Usenet** de DMM encuentra NZB para cualquier película o serie. Luego zurg reproduce la versión directamente desde tu proveedor, sin descargar nada antes.

## Las tres piezas {#the-three-pieces}

| Pieza | Qué es | ¿Hay que pagar por ella? |
|---|---|---|
| Proveedor, o servidor de noticias | El servicio que guarda los mensajes. Te dan una dirección de servidor, un nombre de usuario, una contraseña y un número de conexiones. zurg lee de él. | Sí. Es lo único que tienes que comprar. |
| NZB | Un archivo pequeño que enumera las partes de una publicación, igual que un archivo `.torrent` hace con los torrents. | No. |
| Indexador | Un sitio de búsqueda que genera NZB. Sonarr, Radarr y Prowlarr buscan en uno. | Opcional. |

Una publicación en Usenet se sube como miles de piezas pequeñas. El NZB las enumera, tu proveedor las sirve y zurg las vuelve a juntar en el vídeo que pide tu reproductor.

## Lo que necesitas {#what-you-need}

1. **Un patrocinio de zurg.** Usenet está en las compilaciones nocturnas de zurg, que llegan con un [patrocinio](sponsorship.md). El zurg público y gratuito solo funciona con Real-Debrid.
2. **Una cuenta de proveedor de Usenet.** Dos números importan al comparar planes:
   - **Retención**: cuántos días atrás guarda el servidor los mensajes. Las películas y series más antiguas necesitan más.
   - **Conexiones**: cuántas permite el plan a la vez. zurg lee con ese número, así que pon la cifra real de tu plan en su configuración.
3. **NZB.** Guárdalos desde la pestaña Usenet de DMM, consíguelos de tu propio indexador, o deja que Sonarr, Radarr o zurg los busquen.

No necesitas:

- **Un cliente de descargas** como SABnzbd o NZBGet. zurg transmite la publicación. Para Sonarr y Radarr, zurg actúa como SABnzbd: consulta [Sonarr y Radarr para Usenet](../zurg/guides/sonarr-radarr.md).
- **Disco para publicaciones completas.** zurg solo descarga las partes que cubren lo que se está reproduciendo. Un remux de 60 GB no necesita 60 GB de disco.
- **Herramientas para descomprimir o reparar.** zurg reproduce desde dentro de los conjuntos RAR y reconstruye las partes que faltan a partir de los archivos PAR2 de la publicación por sí mismo.
- **Una cuenta de debrid.** Usenet funciona por su cuenta, o junto a Real-Debrid y TorBox en la misma biblioteca de zurg.
- **Una membresía de indexador**, al menos para empezar. Consulta [la cuestión del indexador](#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers) más abajo.

Vale la pena añadirlo más adelante: **un segundo proveedor.** Un mensaje que un proveedor ha perdido a menudo sigue en otro. Cuando uno no tiene una parte, zurg le pregunta al siguiente. Con uno solo, zurg tiene que leer la publicación entera para reconstruir esa parte. Consulta [un segundo servidor de noticias](../zurg/providers/usenet.md#a-second-news-server-is-worth-more-than-it-looks).

## Cómo lo usa zurg {#how-zurg-plays-it}

1. Un NZB llega a la carpeta `nzbs/` de zurg. Lo pones tú, o lo hacen Sonarr, Radarr o el propio zurg.
2. En un segundo o dos, zurg lo lee y muestra el lanzamiento en su biblioteca, con el nombre del NZB.
3. Le das a play en Plex, Jellyfin o rex. zurg descarga de tu proveedor las partes de ese punto y se las entrega al reproductor. Si saltas más adelante, descarga desde ahí.

Nada espera a que termine una descarga. Para configurarlo paso a paso, sigue [Usenet con zurg](../zurg/guides/usenet.md). Los ajustes del proveedor y los detalles de Docker están en [Usenet provider](../zurg/providers/usenet.md).

## Dónde encaja DMM {#where-dmm-fits}

Cada página de película y serie en [DMM](https://debridmediamanager.com) tiene una pestaña **Usenet** junto a **Torrents**. Muestra las versiones Usenet de ese título de los indexadores de DMM. Cualquiera que haya iniciado sesión en DMM puede usarla.

![Pestaña Usenet de DMM para Night of the Living Dead (1968), con sesión iniciada con TorBox Pro](../assets/usenet-for-beginners/01-dmm-usenet-tab.webp)

Lo que puede hacer una fila depende de con qué cuenta hayas iniciado sesión:

| Botón | Qué hace | Necesita |
|---|---|---|
| El icono de archivo al final, o **NZB** cuando es el único botón | Guarda el NZB, con el nombre de la versión y sin la marca de agua del indexador. Ponlo en la carpeta `nzbs/` de zurg. | Un inicio de sesión en DMM |
| **Send** | DMM descarga la versión desde Usenet y la añade a tu biblioteca de Real-Debrid. No necesitas una cuenta de Usenet para esto. | Real-Debrid |
| **TorBox** | Envía el NZB a TorBox, que descarga la versión por ti. | TorBox Pro, mira [TorBox en DMM](../dmm/torbox.md) |

Los patrocinadores reciben dos opciones más:

- **zurg busca en los indexadores de DMM por ti.** Con tu clave de API de DMM en la configuración de zurg como `dmm_api_key` y sin indexadores propios, zurg busca en los de DMM cuando obtiene tu [lista de deseados de DMM](../zurg/guides/dmm-wanted.md) o tu [watchlist](../zurg/guides/acquisition.md).
- **DMM como indexador Newznab** para Sonarr, Radarr y Prowlarr. Configúralo en la [página de Newznab de DMM](https://debridmediamanager.com/newznab). Cada clave tiene 30 búsquedas y 15 descargas por minuto, y 250 descargas al día.

## Cuando algo va mal {#when-something-is-wrong}

| Lo que ves | Qué hacer |
|---|---|
| zurg log: `Cannot reach the news server for nzb` | zurg no puede iniciar sesión en tu proveedor. Revisa la dirección del servidor, el usuario y la contraseña. El puerto `563` va con `tls: true`, y el puerto `119` con `tls: false`. |
| zurg log: `Usenet account <name> is not reachable` | Falló una de varias cuentas, pero las demás siguen funcionando. Corrige los datos de esa cuenta. |
| Tu proveedor rechaza conexiones, por ejemplo `502 Too many connections` | `connections` en la configuración de zurg es mayor de lo que permite tu plan, o otra app usa el mismo login. Bájalo al número que permite tu plan. |
| Una release aparece como `indexer_download_48213` o algo parecido | zurg nombra una release según su archivo NZB. Renombra el `.nzb` con el nombre de la release. |
| Un archivo dentro de la release tiene un nombre aleatorio | El post ocultó los nombres de sus archivos y zurg no pudo recuperarlos. Elige otra release. |
| zurg log: `rar: RAR4 header-encrypted archives are not supported` | El archivo comprimido de esa release está bloqueado con un formato antiguo que zurg no puede abrir. Elige otra release. |
| La reproducción se entrecorta o hay un hueco en silencio | Se han perdido partes de la release en tu proveedor. zurg las reconstruye a partir de los archivos PAR2 cuando el post los tiene. Un segundo proveedor soluciona la mayoría de estos casos. |
| DMM: **No Usenet results found.** | Los indexadores de DMM no tienen nada para este título. Prueba la pestaña **Torrents** o tu propio indexador. |

La tabla completa de solución de problemas está en [Usenet con zurg](../zurg/guides/usenet.md#troubleshooting). ¿Sigues atascado? Pregunta en el foro **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Cómo pedir ayuda](remote-help.md) explica qué incluir.

## Preguntas {#questions}

### ¿Me puede explicar alguien cómo funciona el sistema Usenet? {#can-someone-explain-the-usenet-system-to-me}

Usenet es una red de servidores de noticias que almacenan publicaciones. Una release se publica en forma de miles de piezas pequeñas. Un proveedor te vende acceso a sus servidores, un NZB enumera las piezas de una release y un indexador es el lugar donde buscas los NZB. zurg toma un NZB y reproduce la release directamente desde tu proveedor.

### ¿Hay que tener membresías de por vida con los indexadores de Usenet? {#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers}

No. No necesitas ningún indexador para empezar: la pestaña Usenet de DMM busca los NZB por ti, y el zurg de un patrocinador puede buscar en los indexadores de DMM por su cuenta. Si quieres tu propio indexador para obtener más resultados, cualquier indexador Newznab funciona en zurg, Sonarr y Radarr, sin importar el plan que elijas.

### ¿Cómo se supone que deben nombrarse los archivos para Usenet? {#how-are-the-files-supposed-to-be-named-for-usenet}

Nombra el NZB con el nombre del release, por ejemplo `Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb`. zurg usa ese nombre para la carpeta del release, y es por el que Plex y los demás hacen la coincidencia. Si un NZB trae un nombre dentro, se usa ese en su lugar. El botón NZB de DMM ya guarda el archivo con el nombre del release.

### ¿Hace zurg Usenet? {#does-zurg-do-usenet}

Sí, en las compilaciones nocturnas para patrocinadores. Dale los datos de tu proveedor, mete los NZB en `nzbs/` y se reproducen. [Usenet con zurg](../zurg/guides/usenet.md) explica el proceso paso a paso.

### ¿Qué es TorBox NNTP? {#what-is-torbox-nntp}

TorBox tiene dos funciones de Usenet en su plan Pro. Su página de precios muestra Usenet solo en Pro (comprobado el 14 de noviembre de 2026).

- **Descargas de Usenet alojadas.** TorBox descarga la versión completa por ti y la sirve como cualquier otra descarga de TorBox. Envía los NZB desde la pestaña Usenet de DMM o desde el proveedor `torbox_nzb` de zurg. No necesitas un inicio de sesión en ningún servidor de noticias. Consulta [TorBox alojado en Usenet](../zurg/providers/torbox-nzb.md).
- **Un inicio de sesión en servidor de noticias (NNTP).** Úsalo en zurg como cualquier otro proveedor. Permite 10 conexiones. Medido en septiembre de 2026, encontró menos biblioteca real que otros tres proveedores de pago, así que funciona mejor como respaldo. Consulta [Servidor de noticias de TorBox](../zurg/providers/torbox-news-server.md).

### ¿Puedo usar una cuenta de Usenet en dos lugares? {#can-i-use-one-usenet-account-in-two-places}

Mejor no. Dos apps con el mismo login comparten sus conexiones y se echan la una a la otra: el servidor puede cortar la conexión más antigua para dejar entrar a la nueva. Además, algunos proveedores prohíben en sus condiciones compartir una cuenta. Usa una cuenta distinta para cada zurg.
