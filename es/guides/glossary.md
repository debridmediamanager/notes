# Qué hace cada pieza {#what-each-piece-does}

Los nombres no dicen qué hace cada uno, así que aquí tienes una línea para cada uno. Para saber cuáles necesitas, usa [Elige tu configuración](choose-your-setup.md).

## Los tres proyectos {#the-three-projects}

| Nombre | Qué hace |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Un sitio web para buscar versiones y añadirlas a tu cuenta de debrid. También busca en Usenet y Easynews. Gratis |
| [zurg](../zurg/index.md) | Todas las cuentas de debrid y Usenet en una sola carpeta. Plex, Jellyfin, Emby, Infuse y rex leen esa carpeta como si fuera un disco normal. Para patrocinadores |
| [rex](../rex/index.md) | Un servidor multimedia que no posee ningún archivo. Sus fuentes le dicen qué tiene y cualquier app de Plex lo reproduce. Gratis para uso personal |

## Ver directamente desde DMM {#watching-straight-from-dmm}

No necesitas servidor para ninguno de estos.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | Un complemento de Stremio que reproduce versiones de tu cuenta de debrid o Easynews |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Explora, busca y reproduce desde tu cuenta de debrid o Easynews dentro de Kodi |
| DMM Watch | Un botón en DMM que abre un archivo en tu propio reproductor, como VLC o Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | Reproduce y descarga música de Real-Debrid desde tu navegador |

## Alimentar a rex {#feeding-rex}

| Nombre | Qué hace |
|---|---|
| [rex-stremio](../rex/stremio.md) | Convierte tus complementos de Stremio en bibliotecas de rex, para que se reproduzcan en las apps de Plex. Gratis |
| [rex addons](../rex/addons.md) | Pequeños programas que le dan a rex algo que reproducir: YouTube, Spotify, IPTV, vídeos caseros o lo que tú escribas |
| [rex for Android](../rex/android.md) | rex y sus complementos en un teléfono o caja de TV Android, sin ordenador. Gratis. Para tu biblioteca de debrid y Usenet, los patrocinadores usan zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | Un servidor de Plex en tu teléfono: zurg y rex juntos en un solo dispositivo Android. Para patrocinadores |

## Dentro de Jellyfin y Emby {#inside-jellyfin-and-emby}

| Name | What it does |
|---|---|
| [RD, AD, TB, PM, OC and DL zurg](https://debridmediamanager.com/jellyfin) | Un plugin por cada proveedor de debrid. Tu biblioteca de debrid aparece en Jellyfin o [Emby](https://debridmediamanager.com/emby) sin ninguna app de zurg ni montaje. Para patrocinadores |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Un plugin de Jellyfin que transmite NZB a través de tu propia cuenta de Usenet. Para patrocinadores |

## Añadir títulos por ti {#adding-titles-for-you}

| Nombre | Qué hace |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Pulsa **Want** en DMM y tu zurg lo descarga, incluidos los episodios nuevos. Para patrocinadores |
| [Seerr through DMM](../dmm/seerr.md) | Las solicitudes de la familia en Seerr llegan a tu lista Wanted. Para patrocinadores |
| [Torznab and Newznab](https://debridmediamanager.com/torznab) | DMM como indexador para Sonarr, Radarr y Prowlarr, con zurg como cliente de descarga. Para patrocinadores |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | Busca en Usenet cuando pulsas play en Stremio y lo transmite a través de zurg |
| [`__magic__`](../zurg/guides/magic.md) | Una carpeta de zurg que organizas tú mismo, o que dejas que Sonarr y Radarr organicen |

## El resto de DMM {#the-rest-of-dmm}

| Nombre | Qué hace |
|---|---|
| [Tablero de solicitudes](https://debridmediamanager.com/requests) | Pide una versión que Real-Debrid no tenga. Otro usuario de DMM la mueve a tu biblioteca. Completar solicitudes te da ventajas de patrocinador de DMM |
| [Listas de hashes](https://debridmediamanager.com/hashlists) | Comparte una lista de versiones para que otros la añadan a sus propias cuentas |
| [Extensión del navegador](../dmm/safari.md) | Añade botones de DMM en sitios de películas y series y junto a los enlaces magnet |
| [Página de patrocinio](https://gatekeeper.debridmediamanager.com) | Aquí patrocinas y enlazas tu aportación de Patreon o GitHub Sponsors. [Qué te da un patrocinio](sponsorship.md) |

## Palabras que verás en las guías {#words-youll-see-in-the-guides}

| Término | Qué significa |
|---|---|
| Debrid provider | Un servicio de pago que descarga torrents por ti y te permite hacer streaming de ellos: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | El proveedor ya tiene el release, así que se reproduce al instante |
| Usenet | Otro lugar para conseguir releases. Necesitas una cuenta de proveedor de Usenet, o TorBox Pro para que lo haga por ti |
| NZB | Un archivo pequeño que indica dónde está un release de Usenet, igual que un archivo torrent hace con los torrents |
| Indexer | Un sitio de búsqueda de releases. Sonarr y Radarr usan uno para encontrar cosas |
| WebDAV | Una forma de compartir archivos por la web. Infuse, Kodi y muchos reproductores de TV pueden abrirlo |
| Mount | Hace que la carpeta de zurg parezca un disco local, para que Plex, Jellyfin o Emby puedan escanearla |
| Plex Media Server vs Plex apps | El servidor guarda tu biblioteca. Las apps de tu TV y tu móvil la reproducen. rex reemplaza al servidor, no a las apps |
