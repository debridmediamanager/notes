# Lo que te da un patrocinio {#what-a-sponsorship-gives-you}

DMM es gratis. Los patrocinios pagan su alojamiento y mantienen zurg y rex en marcha. Esta página enumera cada ventaja y dónde configurarla.

Patrocina en [gatekeeper](https://gatekeeper.debridmediamanager.com/). Inicia sesión allí para ver tu clave de API de DMM. **Open DMM with this key** la vincula en ese navegador. Añade la misma clave en los otros servicios que la pidan. Mantenla privada porque funciona como una contraseña.

Las ventajas siguen al patrocinio. Cuando termina, DMM las deja de dar en la siguiente petición. Los plugins de Jellyfin y Emby que ya instalaste siguen funcionando, pero las nuevas descargas y actualizaciones se detienen. Gatekeeper revoca el acceso a zurg y el rol de Discord en su siguiente comprobación. **Reset key** detiene la clave antigua en todas partes a la vez.

## zurg

| Lo que obtienes | Dónde |
|---|---|
| Compilaciones nocturnas con todos los proveedores y Usenet, además de la imagen de Docker | [configuración de zurg](../zurg/setup/index.md) después de aceptar la invitación de GitHub |
| La app de zurg+rex para Android, un servidor de Plex en tu teléfono | [guía de Android](../zurg/guides/android.md) después de aceptar la invitación de GitHub |
| El código fuente completo de zurg | El repositorio privado en GitHub |
| Cada versión con nombre de rex y Plex | `dmm_api_key` en la [configuración de zurg](../zurg/reference/config.md) |
| Detalles de medios de DMM sin leer antes el archivo y comprobaciones de idioma antes de añadir una versión | Nada más allá de `dmm_api_key` |
| Las carpetas `__magic__` ordenadas por ti cuando está activado | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Tu lista de deseados de DMM que zurg descarga | [lista de deseados de DMM](../zurg/guides/dmm-wanted.md) |
| Los indexadores de Usenet y torrent de DMM que se buscan cuando no tienes ninguno propio | `dmm_api_key` más un proveedor de Usenet o una cuenta de debrid que pueda añadir torrents |
| Versiones elegidas según el idioma original de cada título | `original` en [idiomas de audio y subtítulos](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| Una película deseada que ningún indexador tiene, transmitida desde su subida oficial a YouTube | [Transmitir una película desde YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

Las funciones de `dmm_api_key` necesitan una compilación nocturna de zurg. La compilación pública gratuita no las incluye.

## DMM

| Lo que obtienes | Dónde |
|---|---|
| Una lista de deseados que zurg obtiene con episodios nuevos y mejoras. Llénala desde DMM o Kodi o listas de Trakt y MDBList, o desde una copia de seguridad de Radarr o Sonarr | [Lista de deseados de DMM](../zurg/guides/dmm-wanted.md) |
| Las solicitudes de Seerr, Overseerr o Jellyseerr llegan a tu lista de deseados | [Seerr a través de DMM](../dmm/seerr.md) |
| Cualquier resultado de Easynews enviado a tu zurg con un solo clic | Los resultados de Easynews en una página de película o serie en DMM |
| DMM como indexador Newznab para Usenet | [Página de Newznab](https://debridmediamanager.com/newznab) de DMM |
| DMM como indexador Torznab con feeds solo de caché para Real-Debrid, AllDebrid, Debrid-Link, TorBox, Premiumize y Offcloud | [Página de Torznab](https://debridmediamanager.com/torznab) de DMM. TorBox, Premiumize y Offcloud también necesitan su clave de servicio vinculada |
| Siete plugins de Jellyfin para bibliotecas de debrid y Usenet, y seis plugins de Emby para bibliotecas de debrid sin nada montado | Páginas de [Jellyfin](https://debridmediamanager.com/jellyfin) y [Emby](https://debridmediamanager.com/emby) de DMM |
| Diez streams adicionales por título en Stremio Cast y Kodi en lugar de cinco | Ajustes de DMM para Real-Debrid, TorBox y AllDebrid; la página Cast de cada proveedor para los demás |
| Las subidas de NZB van primero, con 2 TB de Usenet al día en lugar de 300 GB | Pestaña Usenet de DMM |
| La misma prioridad y cuota para Sonarr y Radarr | Tu clave de API de DMM como Password en la [página de SABnzbd](https://debridmediamanager.com/sabnzbd) de DMM |
| Tres subidas de torrents a Real-Debrid a la vez, en lugar de una | Los botones de subida en los resultados de búsqueda y en la biblioteca de DMM |
| Añadir a Wanted de DMM y una carpeta Wanted dentro de Kodi | Vincula Kodi en la [página de Kodi](https://debridmediamanager.com/kodi) de DMM |
| La API de DMM para nombres de releases, comprobaciones de caché, detalles de medios y metadatos | [Documentación de la API](https://debridmediamanager.com/api-docs) |

## rex

rex es gratuito y no necesita patrocinio, y también en Android: [rex para Android](../rex/android.md) ejecuta rex y sus complementos en un teléfono o en un TV box. Con una clave, [rex-stremio](../rex/stremio.md) añade streams de debrid de torrents que DMM ya tiene analizados, en segundos en lugar de analizar cada uno. Pégala en el campo **DMM** de rex-stremio. Comparte sus análisis de archivos torrent con DMM, a menos que lo desactives.

## Ayuda {#help}

| Lo que obtienes | Dónde |
|---|---|
| Ayuda remota gratis con zurg y rex en tu propia terminal mientras miras | [Obtener ayuda](remote-help.md) |
| El rol Sponsor en Discord | Conecta Discord en gatekeeper |

## Gánalo sin pagar {#earn-it-without-paying}

Completa solicitudes en el [tablero de solicitudes](https://debridmediamanager.com/requests) de DMM. Cada 10 solicitudes te dan 7 días de las ventajas de DMM mencionadas arriba. Solo cuenta una completada por la misma persona cada día. Vincula la clave de una cuenta gratuita de gatekeeper en el tablero para reclamarlos.

El tiempo ganado abre la tabla de DMM mencionada arriba. No abre el nightly de zurg, el código fuente, el rol de Discord, la ayuda remota ni la app de Android. Eso requiere un patrocinio de pago. Las funciones de `dmm_api_key` también necesitan un nightly.

¿Atascado? Pregunta en el foro **dmm-support** de [Discord](https://discord.com/invite/7u4YjMThXP).
