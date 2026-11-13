# Ce que fait chaque pièce {#what-each-piece-does}

Les noms ne disent pas à quoi sert chacun, donc voici une ligne pour chacun. Pour trouver ceux dont vous avez besoin, utilisez [Choisir votre configuration](choose-your-setup.md).

## Les trois projets {#the-three-projects}

| Nom | Ce qu'il fait |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | Un site pour trouver des releases et les ajouter à ton compte debrid. Il cherche aussi sur Usenet et Easynews. Gratuit |
| [zurg](../zurg/index.md) | Tous les comptes debrid et Usenet dans un seul dossier. Plex, Jellyfin, Emby, Infuse et rex lisent ce dossier comme un disque normal. Pour les sponsors |
| [rex](../rex/index.md) | Un serveur média qui ne possède aucun fichier. Ses sources lui disent ce qu'elles ont et toutes les applications Plex le lisent. Gratuit pour un usage personnel |

## Regarder directement depuis DMM {#watching-straight-from-dmm}

Aucun serveur n'est nécessaire pour aucun de ces outils.

| Name | What it does |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | Un addon Stremio qui lit les versions disponibles depuis ton compte debrid ou Easynews |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | Parcours, recherche et lecture depuis ton compte debrid ou Easynews directement dans Kodi |
| DMM Watch | Un bouton sur DMM qui ouvre un fichier dans ton propre lecteur, comme VLC ou Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | Lis et télécharge de la musique depuis Real-Debrid directement dans ton navigateur |

## Alimenter rex {#feeding-rex}

| Nom | Ce que ça fait |
|---|---|
| [rex-stremio](../rex/stremio.md) | Transforme vos addons Stremio en bibliothèques rex, pour qu'ils se lisent dans les applis Plex. Gratuit |
| [rex addons](../rex/addons.md) | Petits programmes qui donnent à rex quelque chose à lire : YouTube, Spotify, IPTV, vidéos perso, ou tout ce que vous écrivez |
| [rex for Android](../rex/android.md) | rex et ses addons sur un téléphone ou une box TV Android, sans ordinateur. Gratuit. Pour votre bibliothèque debrid et Usenet, les sponsors utilisent zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | Un serveur Plex sur votre téléphone : zurg et rex ensemble sur un seul appareil Android. Pour les sponsors |

## Dans Jellyfin et Emby {#inside-jellyfin-and-emby}

| Nom | Ce que ça fait |
|---|---|
| [RD, AD, TB, PM, OC et DL zurg](https://debridmediamanager.com/jellyfin) | Un plugin par fournisseur debrid. Ta bibliothèque debrid apparaît dans Jellyfin ou [Emby](https://debridmediamanager.com/emby) sans application zurg ni montage. Pour les sponsors |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | Un plugin Jellyfin qui diffuse les NZB via ton propre compte Usenet. Pour les sponsors |

## Ajouter des titres pour vous {#adding-titles-for-you}

| Nom | Ce que ça fait |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | Appuyez sur **Want** dans DMM et votre zurg le récupère, nouveaux épisodes compris. Pour les sponsors |
| [Seerr via DMM](../dmm/seerr.md) | Les demandes de la famille dans Seerr arrivent dans votre liste Wanted. Pour les sponsors |
| [Torznab et Newznab](https://debridmediamanager.com/torznab) | DMM comme indexeur pour Sonarr, Radarr et Prowlarr, avec zurg comme client de téléchargement. Pour les sponsors |
| [Addon Stremio de zurg](../zurg/guides/stremio.md) | Cherche sur Usenet quand vous appuyez sur lecture dans Stremio et le diffuse via zurg |
| [`__magic__`](../zurg/guides/magic.md) | Un dossier zurg que vous organisez vous-même, ou que Sonarr et Radarr organisent pour vous |

## Le reste de DMM {#the-rest-of-dmm}

| Nom | Ce que ça fait |
|---|---|
| [Tableau des demandes](https://debridmediamanager.com/requests) | Demandez une version que Real-Debrid n'a pas. Un autre utilisateur de DMM la déplace dans votre bibliothèque. Répondre aux demandes donne accès aux avantages des sponsors de DMM |
| [Listes de hash](https://debridmediamanager.com/hashlists) | Partagez une liste de versions pour que d'autres puissent les ajouter à leurs propres comptes |
| [Extension de navigateur](../dmm/safari.md) | Ajoute des boutons DMM sur les sites de films et de séries et à côté des liens magnet |
| [Page des sponsors](https://gatekeeper.debridmediamanager.com) | Où vous devenez sponsor et reliez votre engagement Patreon ou GitHub Sponsors. [Ce qu'un sponsoring vous apporte](sponsorship.md) |

## Les mots que vous verrez dans les guides {#words-youll-see-in-the-guides}

| Mot | Ce que ça veut dire |
|---|---|
| Fournisseur debrid | Un service payant qui télécharge les torrents pour toi et te permet de les streamer : Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud, Debrid-Link |
| Cached | Le fournisseur a déjà la release, donc elle se lance tout de suite |
| Usenet | Un autre endroit pour trouver des releases. Il te faut un compte chez un fournisseur Usenet, ou TorBox Pro pour que ça le fasse à ta place |
| NZB | Un petit fichier qui indique où se trouve une release Usenet, comme un fichier torrent le fait pour les torrents |
| Indexeur | Un site de recherche de releases. Sonarr et Radarr s'en servent pour trouver des trucs |
| WebDAV | Une façon de partager des fichiers sur le web. Infuse, Kodi et beaucoup de lecteurs TV peuvent l'ouvrir |
| Mount | Fait ressembler le dossier de zurg à un disque local, pour que Plex, Jellyfin ou Emby puissent le scanner |
| Plex Media Server vs applis Plex | Le serveur garde ta bibliothèque. Les applis sur ta TV et ton téléphone la lisent. rex remplace le serveur, pas les applis |
