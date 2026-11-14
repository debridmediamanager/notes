# Usenet pour débutants : quoi acheter et comment ça s'articule avec zurg {#usenet-for-beginners-what-to-buy-and-how-it-fits-with-zurg}

Pour streamer du Usenet avec zurg, il vous faut un compte **Usenet provider**, qui héberge les fichiers, et des **fichiers NZB**, qui indiquent où se trouve chaque release. Un **indexer** est un site de recherche de NZB, mais vous n'êtes pas obligé d'en acheter un : l'onglet **Usenet** de DMM trouve les NZB pour n'importe quel film ou n'importe quelle série. zurg lit ensuite la release directement depuis votre provider, sans rien télécharger au préalable.

## Les trois éléments {#the-three-pieces}

| Élément | Ce que c'est | Faut-il payer ? |
|---|---|---|
| Fournisseur, ou serveur de news | Le service qui stocke les messages. Vous recevez une adresse de serveur, un nom d'utilisateur, un mot de passe et un nombre de connexions. zurg lit depuis lui. | Oui. C'est la seule chose qu'il faut acheter. |
| NZB | Un petit fichier qui liste les morceaux d'une version, comme un fichier `.torrent` le fait pour les torrents. | Non. |
| Indexeur | Un site de recherche qui fabrique des NZB. Sonarr, Radarr et Prowlarr en interrogent un. | Facultatif. |

Une version sur Usenet est publiée sous forme de milliers de petits morceaux. Le NZB les liste, votre fournisseur les sert, et zurg les remet bout à bout pour en faire la vidéo que votre lecteur demande.

## Ce dont vous avez besoin {#what-you-need}

1. **Une sponsorisation pour zurg.** Usenet est présent dans les builds nocturnes de zurg, qui sont réservés aux sponsors ([sponsorisation](sponsorship.md)). Le zurg public gratuit ne gère que Real-Debrid.
2. **Un compte chez un fournisseur Usenet.** Deux chiffres comptent quand vous comparez les offres :
   - **Rétention** : le nombre de jours pendant lesquels le serveur garde les posts. Les vieux films et séries en demandent davantage.
   - **Connexions** : le nombre autorisé en même temps. zurg lit avec ce nombre, donc mettez le chiffre réel de votre offre dans sa configuration.
3. **Les NZB.** Enregistrez-les depuis l'onglet Usenet de DMM, récupérez-les chez votre propre indexeur, ou laissez Sonarr, Radarr ou zurg les trouver.

Vous n'avez pas besoin :

- **D'un client de téléchargement** comme SABnzbd ou NZBGet. zurg diffuse la release. Pour Sonarr et Radarr, zurg joue lui-même le rôle de SABnzbd : voir [Sonarr et Radarr pour Usenet](../zurg/guides/sonarr-radarr.md).
- **D'espace disque pour les releases complètes.** zurg ne récupère que les parties qui couvrent ce qui est en lecture. Un remux de 60 Go ne demande pas 60 Go d'espace disque.
- **D'outils pour décompresser ou réparer.** zurg lit directement dans les jeux de RAR et reconstruit lui-même les parties manquantes à partir des fichiers PAR2 de la release.
- **D'un compte debrid.** Usenet fonctionne seul, ou à côté de Real-Debrid et TorBox dans la même bibliothèque zurg.
- **D'une adhésion à un indexeur**, au moins pour commencer. Voir [la question des indexeurs](#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers) plus bas.

À ajouter plus tard : **un second fournisseur.** Un post qu'un fournisseur a perdu est souvent encore chez un autre. Quand l'un n'a pas une partie, zurg demande au suivant. Avec un seul, zurg doit lire toute la release pour reconstruire cette partie. Voir [un second serveur de news](../zurg/providers/usenet.md#a-second-news-server-is-worth-more-than-it-looks).

## Comment zurg s'y prend {#how-zurg-plays-it}

1. Un NZB arrive dans le dossier `nzbs/` de zurg. C'est vous qui le déposez, ou Sonarr, Radarr ou zurg lui-même.
2. En une seconde ou deux, zurg le lit et affiche la release dans sa bibliothèque, avec le nom du NZB.
3. Vous appuyez sur lecture dans Plex, Jellyfin ou rex. zurg récupère les morceaux correspondant à cet endroit auprès de votre fournisseur et les transmet. Si vous avancez, il récupère à partir du nouvel endroit.

Rien n'attend la fin d'un téléchargement. Pour la configuration pas à pas, suivez [Usenet avec zurg](../zurg/guides/usenet.md). Les réglages du fournisseur et les détails Docker se trouvent sur [Usenet provider](../zurg/providers/usenet.md).

## Où se situe DMM {#where-dmm-fits}

Chaque page de film et de série sur [DMM](https://debridmediamanager.com) a un onglet **Usenet** à côté de **Torrents**. Il liste les releases Usenet de ce titre provenant des indexeurs de DMM. Toute personne connectée à DMM peut l'utiliser.

![Onglet Usenet de DMM pour Night of the Living Dead (1968), connecté avec TorBox Pro](../assets/usenet-for-beginners/01-dmm-usenet-tab.webp)

Ce que peut faire une ligne dépend de la façon dont vous êtes connecté :

| Bouton | Ce qu'il fait | Nécessite |
|---|---|---|
| L'icône de fichier à la fin, ou **NZB** quand c'est le seul bouton | Enregistre le NZB, nommé d'après la release, sans le filigrane de l'indexeur. Placez-le dans le dossier `nzbs/` de zurg. | Une connexion DMM |
| **Send** | DMM récupère la release sur Usenet et l'ajoute à votre bibliothèque Real-Debrid. Vous n'avez pas besoin de compte Usenet pour cela. | Real-Debrid |
| **TorBox** | Envoie le NZB à TorBox, qui télécharge la release pour vous. | TorBox Pro, voir [TorBox dans DMM](../dmm/torbox.md) |

Les sponsors ont deux options de plus :

- **zurg cherche pour vous dans les indexeurs de DMM.** Avec votre clé API DMM dans la config de zurg sous `dmm_api_key` et sans indexeurs à vous, zurg cherche dans ceux de DMM quand il récupère votre [liste de souhaits DMM](../zurg/guides/dmm-wanted.md) ou votre [watchlist](../zurg/guides/acquisition.md).
- **DMM comme indexeur Newznab** pour Sonarr, Radarr et Prowlarr. Configurez-le sur la [page Newznab](https://debridmediamanager.com/newznab) de DMM. Chaque clé obtient 30 recherches et 15 récupérations par minute, et 250 récupérations par jour.

## Quand quelque chose ne va pas {#when-something-is-wrong}

| Ce que vous voyez | Quoi faire |
|---|---|
| Log de zurg : `Cannot reach the news server for nzb` | zurg n'arrive pas à se connecter à votre fournisseur. Vérifiez l'adresse du serveur, le nom d'utilisateur et le mot de passe. Le port `563` va avec `tls: true`, le port `119` avec `tls: false`. |
| Log de zurg : `Usenet account <name> is not reachable` | L'un des comptes a échoué, mais les autres continuent de fonctionner. Corrigez les informations de ce compte. |
| Votre fournisseur refuse les connexions, par exemple `502 Too many connections` | `connections` dans la configuration de zurg est plus élevé que ce que votre forfait permet, ou une autre application utilise le même identifiant. Baissez-le au nombre prévu par votre forfait. |
| Une release apparaît sous le nom `indexer_download_48213` ou similaire | zurg nomme une release d'après son fichier NZB. Renommez le `.nzb` avec le nom de la release. |
| Un fichier à l'intérieur de la release a un nom aléatoire | Le post a masqué les noms de ses fichiers et zurg n'a pas pu les récupérer. Choisissez une autre release. |
| Log de zurg : `rar: RAR4 header-encrypted archives are not supported` | L'archive de cette release est verrouillée dans un ancien format que zurg ne peut pas ouvrir. Choisissez une autre release. |
| La lecture saccade ou un passage est muet | Des morceaux de la release ont disparu chez votre fournisseur. zurg les reconstruit à partir des fichiers PAR2 quand le post en contient. Un second fournisseur règle la plupart de ces cas. |
| DMM : **No Usenet results found.** | Les indexeurs de DMM n'ont rien pour ce titre. Essayez l'onglet **Torrents**, ou votre propre indexeur. |

Le tableau de dépannage complet se trouve dans [Usenet avec zurg](../zurg/guides/usenet.md#troubleshooting). Vous êtes bloqué ? Posez votre question dans le forum **zurg-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](remote-help.md) indique quoi inclure.

## Questions

### Peux-tu m'expliquer le système Usenet ? {#can-someone-explain-the-usenet-system-to-me}

Usenet est un réseau de serveurs de news qui stockent des messages. Une release est publiée sous forme de milliers de petits morceaux. Un fournisseur vous vend l'accès à ses serveurs, un NZB liste les morceaux d'une release, et un indexeur est l'endroit où vous cherchez les NZB. zurg prend un NZB et lit la release directement depuis votre fournisseur.

### Faut-il avoir des abonnements à vie chez les indexeurs Usenet ? {#do-you-have-to-have-lifetime-memberships-with-the-usenet-indexers}

Non, vous n'avez besoin d'aucun indexeur pour commencer : l'onglet Usenet de DMM trouve les NZB pour vous, et le zurg d'un sponsor peut lui-même chercher dans les indexeurs de DMM. Si vous voulez votre propre indexeur pour obtenir plus de résultats, n'importe quel indexeur Newznab fonctionne avec zurg, Sonarr et Radarr, quel que soit le forfait que vous choisissez.

### Comment les fichiers doivent-ils être nommés pour Usenet ? {#how-are-the-files-supposed-to-be-named-for-usenet}

Nommez le NZB d'après la release, par exemple `Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb`. zurg utilise ce nom pour le dossier de la release, et c'est sur lui que Plex et les autres se basent pour la reconnaissance. Si un NZB contient un nom à l'intérieur, c'est ce nom-là qui est utilisé à la place. Le bouton NZB de DMM enregistre déjà le fichier sous le nom de la release.

### zurg gère-t-il Usenet ? {#does-zurg-do-usenet}

Oui, dans les builds nightly pour les sponsors. Indiquez-leur les informations de votre fournisseur, déposez vos NZB dans `nzbs/` et ils se lancent. [Usenet avec zurg](../zurg/guides/usenet.md) explique la marche à suivre.

### C'est quoi TorBox NNTP ? {#what-is-torbox-nntp}

TorBox a deux fonctionnalités Usenet dans son offre Pro. Sa page de tarifs indique Usenet uniquement pour Pro (vérifié le 14 novembre 2026).

- **Téléchargements Usenet hébergés.** TorBox télécharge la release complète pour vous et la sert comme n'importe quel autre téléchargement TorBox. Envoyez les NZB depuis l'onglet Usenet de DMM ou depuis le provider `torbox_nzb` de zurg. Vous n'avez pas besoin d'identifiants de serveur de news. Voir [TorBox hébergé Usenet](../zurg/providers/torbox-nzb.md).
- **Un identifiant de serveur de news (NNTP).** Utilisez-le dans zurg comme n'importe quel provider. Il autorise 10 connexions. Mesuré en septembre 2026, il trouvait moins de contenu réel dans une bibliothèque que trois autres providers payants. Il convient donc surtout comme solution de secours. Voir [Serveur de news TorBox](../zurg/providers/torbox-news-server.md).

### Puis-je utiliser un seul compte Usenet à deux endroits ? {#can-i-use-one-usenet-account-in-two-places}

Mieux vaut éviter. Deux applis sur un même compte partagent ses connexions et se coupent mutuellement : le serveur peut fermer la plus ancienne connexion pour laisser entrer la nouvelle. Certains fournisseurs interdisent de partager un compte dans leurs conditions. Donne à chaque zurg son propre compte.
