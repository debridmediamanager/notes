# Ce que fait chaque pièce {#what-each-piece-does}

Les noms ne disent pas à quoi chacun sert, donc voici une ligne pour chacun. Tout ce qui n'est pas marqué **For sponsors** est gratuit. Pour savoir lesquels vous faut, utilisez [Choose your setup](choose-your-setup.md).

## Les trois projets {#the-three-projects}

| Nom | Ce que ça fait |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Un site pour trouver des releases et les ajouter à ton compte debrid. Il cherche aussi sur Usenet et Easynews |
| [zurg](../zurg/index.md) | Tous les comptes debrid et Usenet réunis en une seule bibliothèque. Plex, Jellyfin et Emby la lisent comme un dossier, Infuse et Kodi via WebDAV, et rex y accède directement. Les versions actuelles sont réservées aux sponsors |
| [rex](../rex/index.md) | Un serveur média pour les applis Plex, sans fichiers à lui. zurg ou un addon lui indique ce qui existe. Gratuit pour un usage personnel |

## Regarder directement depuis DMM {#watching-straight-from-dmm}

Aucun serveur n'est nécessaire pour aucun de ces outils.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | Un addon Stremio qui lit les releases de votre compte debrid ou Easynews |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Parcourez, recherchez et lisez depuis votre compte debrid ou Easynews directement dans Kodi |
| DMM Watch | Un bouton sur DMM qui ouvre un fichier dans votre propre lecteur, comme VLC ou Infuse |
| [DMM Music](https://debridmediamanager.com/music) | Lisez et téléchargez de la musique depuis Real-Debrid directement dans votre navigateur |

## Alimenter rex {#feeding-rex}

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | Transforme vos addons Stremio en bibliothèques rex, pour qu'ils se lisent dans les apps Plex |
| [rex addons](../rex/addons.md) | Petits programmes qui donnent à rex quelque chose à lire : YouTube, Spotify, IPTV, vidéos perso, ou tout ce que vous écrivez |
| [rex-live-sports](../rex/live-tv.md) | Un addon rex qui ajoute des chaînes de sport en direct et un guide dans Live TV des apps Plex |
| [rex-direct](../rex/any-source.md#rex-direct) | Donne à votre rex sa propre adresse sécurisée, pour que les apps Plex y accèdent depuis l'extérieur |
| [rex for Android](../rex/android.md) | rex et ses addons sur un téléphone Android ou une box TV, sans ordinateur |
| [zurg+rex for Android](../zurg/guides/android.md) | Un serveur Plex sur votre téléphone : zurg et rex ensemble sur un seul appareil Android, avec votre bibliothèque debrid et Usenet. Pour les sponsors |

## Dans Jellyfin et Emby {#inside-jellyfin-and-emby}

| Nom | Ce que ça fait |
|---|---|
| [Plugins debrid](https://debridmediamanager.com/jellyfin) (RD zurg, AD zurg, TB zurg, PM zurg, OC zurg, DL zurg) | Un plugin par fournisseur debrid : Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud et Debrid-Link. Ta bibliothèque debrid apparaît dans Jellyfin ou [Emby](https://debridmediamanager.com/emby) sans appli zurg ni montage. Pour les sponsors |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Un plugin Jellyfin qui diffuse les NZB via ton propre compte Usenet. Pour les sponsors |

## Ajouter des titres pour vous {#adding-titles-for-you}

| Nom | Ce que ça fait |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Appuie sur **Want** dans DMM et ton zurg le récupère, nouveaux épisodes compris. Pour les sponsors |
| [Seerr via DMM](../dmm/seerr.md) | Les demandes de la famille dans Seerr vont dans ta liste Wanted. Pour les sponsors |
| [Torznab](https://debridmediamanager.com/torznab) et [Newznab](https://debridmediamanager.com/newznab) | DMM comme indexeur pour Sonarr, Radarr et Prowlarr. Pour les sponsors |
| zurg comme client de téléchargement | zurg répond à Sonarr et Radarr comme qBittorrent pour les [torrents](../zurg/guides/sonarr-radarr-torrents.md) et comme SABnzbd pour [Usenet](../zurg/guides/sonarr-radarr.md), donc tu n'as besoin de faire tourner aucun des deux. Pour les sponsors |
| [Addon Stremio de zurg](../zurg/guides/stremio.md) | Cherche sur Usenet quand tu appuies sur lecture dans Stremio et diffuse le contenu via zurg. Pour les sponsors |
| [`__magic__`](../zurg/guides/magic.md) | Un dossier zurg que tu organises toi-même, ou que tu laisses Sonarr et Radarr organiser. Pour les sponsors |

## Le reste de DMM {#the-rest-of-dmm}

| Nom | Ce que ça fait |
|---|---|
| Onglet Usenet | Envoie une release Usenet dans ta bibliothèque Real-Debrid, sans compte Usenet. Les sponsors passent en premier et ont un quota quotidien plus élevé |
| [Request board](https://debridmediamanager.com/requests) | Demande une release que Real-Debrid n'a pas. Un autre utilisateur de DMM la déplace dans ta bibliothèque. Remplis 10 demandes et gagne 7 jours des avantages sponsor DMM |
| [Hash lists](https://debridmediamanager.com/hashlists) | Partage une liste de releases pour que d'autres puissent les ajouter à leur propre compte |
| Extension navigateur | Ajoute des boutons DMM sur les sites de films et de séries et à côté des liens magnet. Pour [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm), [Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) et [Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | Le site des sponsors. Deviens sponsor là-bas, lie ton engagement Patreon ou GitHub Sponsors et récupère ta clé API DMM. [Ce que donne un sponsoring](sponsorship.md) |

## Les mots que vous verrez dans les guides {#words-youll-see-in-the-guides}

| Mot | Ce que ça veut dire |
|---|---|
| Release | Une copie d'un film, d'un épisode ou d'une saison, telle que quelqu'un l'a publiée. Un titre en a souvent plusieurs, en différentes qualités |
| Debrid provider | Un service payant qui télécharge les torrents à ta place et te permet de les streamer : Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| En cache | Le fournisseur a déjà la release, donc elle se lance tout de suite |
| Usenet | Un autre endroit où trouver des releases. Utilise ton propre compte Usenet, laisse TorBox Pro ou Easynews s'en charger, ou demande à DMM d'envoyer un résultat à Real-Debrid |
| Easynews | Un service Usenet payant avec sa propre recherche, qui lit les fichiers directement sur le web |
| NZB | Un petit fichier qui indique où se trouve une release Usenet, comme un fichier torrent le fait pour les torrents |
| Indexer | Un site de recherche de releases. Sonarr et Radarr s'en servent pour trouver des trucs |
| Sonarr, Radarr et Prowlarr | Des applis qui récupèrent des titres pour toi : Sonarr pour les séries, Radarr pour les films. Prowlarr garde leurs indexers au même endroit |
| Seerr | Un site de demandes pour la famille et les amis. Overseerr et Jellyseerr fonctionnent de la même façon |
| Stremio et Kodi | Des applis lecteurs multimédias. Les addons leur fournissent des contenus à lire |
| Clé API DMM | La clé d'un sponsor, fournie par gatekeeper. Colle-la là où un guide le demande, et garde-la privée comme un mot de passe |
| Nightly | La version la plus récente de zurg ou rex, générée chaque nuit. Les nightlies de zurg sont réservées aux sponsors |
| WebDAV | Une façon de partager des fichiers sur le web. Infuse, Kodi et beaucoup de lecteurs TV peuvent l'ouvrir |
| Mount | Fait ressembler le dossier de zurg à un disque local, pour que Plex, Jellyfin ou Emby puissent le scanner |
| rclone | L'outil que zurg utilise pour créer le mount. La configuration de zurg l'installe pour toi |
| `.strm` | Un petit fichier qui contient un lien à la place de la vidéo, pour des lecteurs comme Kodi |
| Source | Tout ce qui dit à rex ce qu'il a et qui sert les fichiers : zurg, rex-stremio ou un addon |
| Claim | Relier rex à un compte Plex, pour qu'il affiche les titres et les affiches et que les applis Plex puissent le trouver |
| Plex Media Server vs applis Plex | Le serveur contient ta bibliothèque. Les applis sur ta TV et ton téléphone la lisent. rex remplace le serveur, pas les applis |
