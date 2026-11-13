# Ce que vous apporte un sponsoring {#what-a-sponsorship-gives-you}

DMM est gratuit. Les sponsorings paient son hébergement et permettent à zurg et rex de continuer à avancer. Cette page liste tous les avantages et indique où les configurer.

Devenez sponsor sur [gatekeeper](https://gatekeeper.debridmediamanager.com/). Connectez-vous pour voir votre clé API DMM. **Open DMM with this key** la lie dans ce navigateur. Ajoutez la même clé dans les autres services qui la demandent. Gardez-la privée, car elle fonctionne comme un mot de passe.

Les avantages suivent le sponsoring. Quand il se termine, DMM les arrête dès la prochaine requête. Les plugins Jellyfin et Emby que vous avez déjà installés continuent de fonctionner, mais les nouveaux téléchargements et les mises à jour s'arrêtent. Gatekeeper révoque l'accès à zurg et le rôle Discord lors de sa prochaine vérification. **Reset key** arrête l'ancienne clé partout en même temps.

## zurg

| Ce que vous obtenez | Où |
|---|---|
| Les builds nightly avec tous les fournisseurs et Usenet, ainsi que l'image Docker | [zurg setup](../zurg/setup/index.md) après avoir accepté l'invitation GitHub |
| L'application Android zurg+rex, un serveur Plex sur votre téléphone | [Android guide](../zurg/guides/android.md) après avoir accepté l'invitation GitHub |
| Le code source complet de zurg | Le dépôt privé sur GitHub |
| Chaque version publiée pour rex et Plex | `dmm_api_key` dans la [zurg config](../zurg/reference/config.md) |
| Les détails média DMM sans lire le fichier au préalable, et les vérifications de langue avant l'ajout d'une version | Rien au-delà de `dmm_api_key` |
| Les dossiers `__magic__` triés pour vous lorsque l'option est activée | [\_\_magic\_\_](../zurg/guides/magic.md) |
| Votre liste de souhaits DMM récupérée par zurg | [DMM wanted list](../zurg/guides/dmm-wanted.md) |
| Les indexeurs Usenet et torrent de DMM interrogés lorsque vous n'en avez aucun à vous | `dmm_api_key` plus un fournisseur Usenet ou un compte debrid capable d'ajouter des torrents |
| Les versions choisies selon la langue originale de chaque titre | `original` dans [audio and subtitle languages](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| Un film souhaité qu'aucun indexeur ne propose, diffusé depuis sa mise en ligne officielle sur YouTube | [Streaming a film from YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

Les fonctionnalités `dmm_api_key` nécessitent un build nightly de zurg. Le build public gratuit ne les inclut pas.

## DMM

| Ce que vous obtenez | Où |
|---|---|
| Une liste de souhaits que zurg récupère avec les nouveaux épisodes et les améliorations. Remplissez-la depuis DMM, Kodi ou des listes Trakt et MDBList, ou à partir d'une sauvegarde Radarr ou Sonarr | [Liste de souhaits DMM](../zurg/guides/dmm-wanted.md) |
| Les demandes de Seerr, Overseerr ou Jellyseerr arrivent dans votre liste de souhaits | [Seerr via DMM](../dmm/seerr.md) |
| Tout résultat Easynews envoyé à votre zurg en un clic | Les résultats Easynews sur une page de film ou de série dans DMM |
| DMM comme indexeur Newznab pour Usenet | La [page Newznab](https://debridmediamanager.com/newznab) de DMM |
| DMM comme indexeur Torznab avec des flux en cache uniquement pour Real-Debrid, AllDebrid, Debrid-Link, TorBox, Premiumize et Offcloud | La [page Torznab](https://debridmediamanager.com/torznab) de DMM. TorBox, Premiumize et Offcloud demandent aussi leur clé de service liée |
| Sept plugins Jellyfin pour les bibliothèques debrid et Usenet, et six plugins Emby pour les bibliothèques debrid sans rien monté | Les pages [Jellyfin](https://debridmediamanager.com/jellyfin) et [Emby](https://debridmediamanager.com/emby) de DMM |
| Dix autres flux par titre dans Stremio Cast et Kodi au lieu de cinq | Paramètres DMM pour Real-Debrid, TorBox et AllDebrid ; la page Cast de chaque fournisseur pour les autres |
| Les envois NZB passent en premier avec 2 To de Usenet par jour au lieu de 300 Go | L'onglet Usenet de DMM |
| La même priorité et le même quota pour Sonarr et Radarr | Votre clé API DMM dans le champ Password sur la [page SABnzbd](https://debridmediamanager.com/sabnzbd) de DMM |
| Trois envois de torrents dans Real-Debrid en même temps au lieu d'un | Les boutons d'envoi sur les résultats de recherche DMM et dans la bibliothèque |
| Ajouter à DMM Wanted et un dossier Wanted dans Kodi | Associez Kodi sur la [page Kodi](https://debridmediamanager.com/kodi) de DMM |
| L'API DMM pour les noms de versions, les vérifications de cache, les détails et métadonnées des médias | [Docs API](https://debridmediamanager.com/api-docs) |

## rex

rex est gratuit et ne demande aucun sponsoring, y compris sur Android : [rex pour Android](../rex/android.md) fait tourner rex et ses addons sur un téléphone ou une box TV. Avec une clé, [rex-stremio](../rex/stremio.md) ajoute les flux debrid des torrents que DMM a déjà sondés, en quelques secondes au lieu de sonder chacun. Collez-la dans le champ **DMM** de rex-stremio. Il partage ses sondages de fichiers torrent avec DMM, sauf si vous désactivez cette option.

## Aide {#help}

| Ce que vous obtenez | Où |
|---|---|
| Une aide à distance gratuite pour zurg et rex dans votre propre terminal pendant que vous regardez | [Obtenir de l'aide](remote-help.md) |
| Le rôle Sponsor sur Discord | Connectez Discord sur gatekeeper |

## Gagnez-le sans payer {#earn-it-without-paying}

Remplis des demandes sur le [tableau des demandes](https://debridmediamanager.com/requests) de DMM. Toutes les 10 demandes te rapportent 7 jours d'avantages DMM (ceux mentionnés plus haut). Une seule réalisation par personne et par jour compte. Lie la clé d'un compte gatekeeper gratuit sur le tableau pour les récupérer.

Le temps gagné ouvre le tableau DMM ci-dessus. Il n'ouvre pas le nightly de zurg, le code source, le rôle Discord, l'aide à distance ou l'application Android. Ceux-là nécessitent un parrainage payant. Les fonctionnalités `dmm_api_key` nécessitent aussi un nightly.

Bloqué ? Demande sur le forum **dmm-support** sur [Discord](https://discord.com/invite/7u4YjMThXP).
