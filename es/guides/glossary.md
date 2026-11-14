# Qué hace cada pieza {#what-each-piece-does}

Los nombres no dicen para qué sirve cada cosa, así que aquí tienes una línea para cada una. Todo lo que no esté marcado como **For sponsors** es gratis. Para saber cuáles necesitas, usa [Choose your setup](choose-your-setup.md).

## Los tres proyectos {#the-three-projects}

| Nombre | Qué hace |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Un sitio web para buscar lanzamientos y añadirlos a tu cuenta de debrid. También busca en Usenet y Easynews |
| [zurg](../zurg/index.md) | Cada cuenta de debrid y Usenet como una sola biblioteca. Plex, Jellyfin y Emby la leen como una carpeta, Infuse y Kodi por WebDAV, y rex la obtiene directamente. Las compilaciones actuales son para patrocinadores |
| [rex](../rex/index.md) | Un servidor multimedia para las apps de Plex sin archivos propios. zurg o un addon le dice qué hay. Gratis para uso personal |

## Ver directamente desde DMM {#watching-straight-from-dmm}

No necesitas servidor para ninguno de estos.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | Un complemento de Stremio que reproduce versiones de tu cuenta de debrid o Easynews |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Explora, busca y reproduce desde tu cuenta de debrid o Easynews dentro de Kodi |
| DMM Watch | Un botón en DMM que abre un archivo en tu propio reproductor, como VLC o Infuse |
| [DMM Music](https://debridmediamanager.com/music) | Reproduce y descarga música de Real-Debrid desde tu navegador |

## Alimentar a rex {#feeding-rex}

| Nombre | Qué hace |
|---|---|
| [rex-stremio](../rex/stremio.md) | Convierte tus complementos de Stremio en bibliotecas de rex, para que se reproduzcan en las apps de Plex |
| [rex addons](../rex/addons.md) | Pequeños programas que le dan a rex algo que reproducir: YouTube, Spotify, IPTV, vídeos caseros o lo que tú escribas |
| [rex-live-sports](../rex/live-tv.md) | Un complemento de rex que pone canales de deportes en directo y una guía en Live TV de las apps de Plex |
| [rex-direct](../rex/any-source.md#rex-direct) | Le da a tu rex su propia dirección segura, para que las apps de Plex lo alcancen fuera de casa |
| [rex for Android](../rex/android.md) | rex y sus complementos en un teléfono o caja de TV Android, sin ordenador |
| [zurg+rex for Android](../zurg/guides/android.md) | Un servidor de Plex en tu teléfono: zurg y rex juntos en un mismo dispositivo Android, con tu biblioteca de debrid y Usenet. Para patrocinadores |

## Dentro de Jellyfin y Emby {#inside-jellyfin-and-emby}

| Nombre | Qué hace |
|---|---|
| [Plugins de debrid](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | Un plugin por cada proveedor de debrid: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud y Debrid-Link. Tu biblioteca de debrid aparece en Jellyfin o en [Emby](https://debridmediamanager.com/emby) sin necesidad de ninguna app de zurg ni de montajes. Para patrocinadores |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Un plugin de Jellyfin que transmite NZBs a través de tu propia cuenta de Usenet. Para patrocinadores |

## Añadir títulos por ti {#adding-titles-for-you}

| Nombre | Qué hace |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Pulsa **Want** en DMM y tu zurg lo descarga, incluidos los episodios nuevos. Para patrocinadores |
| [Seerr a través de DMM](../dmm/seerr.md) | Las solicitudes de la familia en Seerr van a tu lista Wanted. Para patrocinadores |
| [Torznab](https://debridmediamanager.com/torznab) y [Newznab](https://debridmediamanager.com/newznab) | DMM como indexador para Sonarr, Radarr y Prowlarr. Para patrocinadores |
| zurg como cliente de descarga | zurg responde a Sonarr y Radarr como qBittorrent para [torrents](../zurg/guides/sonarr-radarr-torrents.md) y como SABnzbd para [Usenet](../zurg/guides/sonarr-radarr.md), así que no necesitas ninguno de los dos. Para patrocinadores |
| [Addon de Stremio de zurg](../zurg/guides/stremio.md) | Busca en Usenet cuando pulsas play en Stremio y lo transmite a través de zurg. Para patrocinadores |
| [`__magic__`](../zurg/guides/magic.md) | Una carpeta de zurg que organizas tú, o que dejas que Sonarr y Radarr organicen. Para patrocinadores |

## El resto de DMM {#the-rest-of-dmm}

| Nombre | Qué hace |
|---|---|
| Pestaña Usenet | Envía un release de Usenet a tu biblioteca de Real-Debrid, sin necesidad de una cuenta de Usenet. Los patrocinadores van primero y tienen una cuota diaria más alta |
| [Tablero de solicitudes](https://debridmediamanager.com/requests) | Pide un release que Real-Debrid no tiene. Otro usuario de DMM lo pasa a tu biblioteca. Completa 10 solicitudes y consigue 7 días de las ventajas de patrocinador de DMM |
| [Listas de hashes](https://debridmediamanager.com/hashlists) | Comparte una lista de releases para que otros los añadan a sus propias cuentas |
| Extensión del navegador | Añade botones de DMM en sitios de películas y series y junto a los enlaces magnet. Para [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) y [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | El sitio de patrocinio. Hazte patrocinador allí, vincula tu compromiso de Patreon o GitHub Sponsors y consigue tu clave API de DMM. [Qué te da un patrocinio](sponsorship.md) |

## Palabras que verás en las guías {#words-youll-see-in-the-guides}

| Término | Qué significa |
|---|---|
| Release | Una copia de una película, episodio o temporada tal como alguien la publicó. Un título suele tener muchos, en distintas calidades |
| Debrid provider | Un servicio de pago que descarga torrents por ti y te deja reproducirlos en streaming: Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | El proveedor ya tiene el release, así que se reproduce al instante |
| Usenet | Otro lugar donde conseguir releases. Usa tu propia cuenta de Usenet, deja que lo hagan TorBox Pro o Easynews, o haz que DMM envíe un resultado a Real-Debrid |
| Easynews | Un servicio de Usenet de pago con su propio buscador que reproduce los archivos directamente por la web |
| NZB | Un archivo pequeño que indica dónde está un release de Usenet, igual que un archivo torrent hace con los torrents |
| Indexer | Un sitio de búsqueda de releases. Sonarr y Radarr usan uno para encontrar cosas |
| Sonarr, Radarr and Prowlarr | Apps que buscan títulos por ti: Sonarr para series, Radarr para películas. Prowlarr reúne sus indexers en un solo lugar |
| Seerr | Un sitio de peticiones para familia y amigos. Overseerr y Jellyseerr funcionan igual |
| Stremio and Kodi | Apps reproductoras de medios. Los addons les dan contenido para reproducir |
| DMM API key | Una clave de sponsor de gatekeeper. Pégala donde una guía lo pida, y mantenla en privado como si fuera una contraseña |
| Nightly | La compilación más reciente de zurg o rex, que se genera cada noche. Las nightlies de zurg son para sponsors |
| WebDAV | Una forma de compartir archivos por la web. Infuse, Kodi y muchos reproductores de TV pueden abrirla |
| Mount | Hace que la carpeta de zurg parezca una unidad local, para que Plex, Jellyfin o Emby puedan escanearla |
| rclone | La herramienta que zurg usa para crear el mount. La configuración de zurg lo instala por ti |
| `.strm` | Un archivo pequeño que contiene un enlace en lugar del video, para reproductores como Kodi |
| Source | Cualquier cosa que le dice a rex qué tiene y sirve los archivos: zurg, rex-stremio o un addon |
| Claim | Asociar rex a una cuenta de Plex, para que pueda mostrar títulos y pósters y las apps de Plex lo encuentren |
| Plex Media Server vs Plex apps | El servidor guarda tu biblioteca. Las apps de tu TV y tu móvil la reproducen. rex reemplaza al servidor, no a las apps |
