# Qu'est-ce que DMM et comment l'utiliser ? {#what-is-dmm-and-how-do-i-use-it}

[Debrid Media Manager](https://debridmediamanager.com) (DMM) est un site web gratuit pour trouver des films et des séries et les ajouter à votre compte debrid : Real-Debrid, AllDebrid, TorBox, Premiumize, Offcloud ou Debrid-Link. Vous vous connectez avec ce compte, vous recherchez un titre et vous appuyez sur **Instant RD** (ou le bouton de votre service) sur une version. Elle arrive tout de suite dans votre bibliothèque, prête à être regardée depuis DMM, dans Stremio ou Kodi, ou dans Plex grâce à [zurg](../zurg/index.md).

DMM est open source et ne fait pas partie de Real-Debrid ni d'aucun autre service. Les fichiers restent chez votre service debrid.

## Se connecter {#sign-in}

1. Ouvrez [debridmediamanager.com](https://debridmediamanager.com) et appuyez sur votre service : **Login with Real Debrid**, **Login with AllDebrid**, **Login with Torbox**, **Login with Premiumize**, **Login with Offcloud** ou **Login with Debrid-Link**.
2. Sur Real-Debrid, appuyez sur **Sign in with Real-Debrid**. DMM affiche un code : appuyez sur **Open real-debrid.com/device**, saisissez le code là-bas et validez. La page DMM se termine toute seule. Vous pouvez aussi coller votre [API token](../guides/real-debrid-api-token.md) sous **or paste an API key** et appuyer sur **Save API Key**.
3. Autres services : suivez leur page de connexion. Si elle demande une clé API, copiez-la depuis votre compte sur ce service, collez-la et appuyez sur **Save API Key**.

![DMM's sign-in page](../assets/dmm-index/01-sign-in.webp)

Vous avez un autre service ? Ouvrez **Debrid services** sur la page d'accueil de DMM et appuyez sur son bouton **Login**, par exemple **AllDebrid Login**.

Vous n'avez qu'Easynews ? Appuyez sur **Login with Easynews**. Vous pouvez rechercher sur Easynews et l'envoyer vers Stremio, mais la bibliothèque nécessite un compte debrid. Les sponsors peuvent aussi se connecter avec **Login with DMM key**.

## Rechercher un film ou une série {#search-a-movie-or-show}

1. Tapez un titre dans **Search movies & shows...** sur la page d'accueil. Choisissez-en un parmi les suggestions, ou appuyez sur **Search** pour la liste complète.
2. Appuyez sur l'affiche. La page du titre liste les releases trouvées par DMM.
3. Appuyez sur la puce de votre service au-dessus des résultats (**RD**, **PM** et ainsi de suite) pour n'afficher que les releases qu'il possède déjà.

![Page d'accueil de DMM après la connexion](../assets/dmm-index/02-home.webp)

## Ce que signifient les boutons d'une release {#what-the-buttons-on-a-release-mean}

![Releases de Sintel sur DMM, connecté avec Premiumize](../assets/dmm-index/03-results.webp)

| Button | What it does |
|---|---|
| **Instant RD** (**Instant TB**, **Instant AD**, **Instant PM**, **Instant OC**, **Instant DL**) | Votre service a déjà cette release. Appuyez dessus et elle est tout de suite dans votre bibliothèque. |
| **DL with RD** (**DL with TB** et ainsi de suite ; **Add to DL** sur Debrid-Link) | Votre service ne l'a pas encore. Appuyer dessus l'ajoute quand même, et le service la télécharge d'abord. Choisissez un bouton **Instant** si vous voulez regarder tout de suite. [Pourquoi cela arrive](../guides/torrent-being-downloaded-to-debrid.md). |
| **RD (100%)** (**PM (100%)** et ainsi de suite) | Elle est dans votre bibliothèque. Le nombre indique où en est le téléchargement. Appuyez dessus pour la retirer de votre bibliothèque. |
| **Check RD** (**Check AD**, **Check DL**) | Demande à ce service s'il a cette release en cache en ce moment. |
| **Cast (RD)** (**Cast (PM)** et ainsi de suite) | Envoie la release à Stremio. Voir [DMM dans Stremio](stremio.md). |
| **Watch** | Ouvre un onglet **Ready to play**. Appuyez sur **Play** et votre lecteur s'ouvre. Choisissez le lecteur sous **Settings** → **Video player**. |
| **Copy** | Copie le lien magnet de la release et affiche **Magnet link copied.** Si **Download .magnet files instead of copy** est coché dans **Settings**, le bouton affiche **Download** et enregistre un fichier .magnet. |
| **Report** | Signale une mauvaise release : **XXX / Porn Content**, **Incorrect IMDB ID**, **Malware / Executable File**, et, pour les séries, **Tagged for Wrong Season**. |

L'onglet **Usenet**, à côté de **Torrents**, liste les releases Usenet du même titre. **NZB** en télécharge une. Pour les envoyer dans votre bibliothèque, il faut Real-Debrid ou TorBox. Vous avez Easynews ? Ajoutez-le dans **Settings** et il est aussi recherché ici.

## Ta bibliothèque {#your-library}

Appuyez sur **Library** sur la page d'accueil. Elle liste tout ce qui se trouve dans les comptes avec lesquels vous vous êtes connecté : nom, taille, statut et date d'ajout.

![La zone de recherche et les boutons de la bibliothèque](../assets/dmm-index/04-library.webp)

- Recherchez avec **search by filename/hash/id, supports regex**, ou affinez avec **Movies**, **TV shows** et **Others**.
- Appuyez sur une ligne pour voir ses détails, ainsi que ses boutons **Hashlist**, **Delete**, **Cast** et **Copy**. Les icônes à la fin de chaque ligne font la même chose.
- **Backup** enregistre votre liste dans un fichier `.dmm.json`. **RD Restore** (**PM Restore** et ainsi de suite) rajoute une liste sauvegardée.
- **Share List** transforme ce qui est affiché, ou ce que vous avez sélectionné, en une [hash list](hashlists.md) que d'autres personnes peuvent ajouter à leurs propres comptes.
- **Delete List** supprime tout ce qui est affiché, après une confirmation **Yes, delete!**. Recherchez ou sélectionnez d'abord.

## Où aller ensuite {#where-to-go-next}

- [DMM dans Stremio](stremio.md) : regardez ce que vous trouvez dans Stremio grâce à l'addon DMM Cast.
- [Listes de hashes](hashlists.md) : ajoutez une bibliothèque partagée entière à la vôtre, ou partagez la vôtre.
- [TorBox dans DMM](torbox.md) : ce que fait chaque forfait TorBox dans DMM, et l'envoi de releases Usenet vers TorBox Pro.
- ["Torrent is being downloaded to debrid"](../guides/torrent-being-downloaded-to-debrid.md) : ce que signifie cet écran dans Stremio et comment DMM affiche ce qui est en cache.
- [Boutons DMM dans Safari](safari.md) : l'extension navigateur ajoute un bouton DMM sur IMDb, Trakt et d'autres sites de films et de séries.

DMM sert aussi les autres projets :

- **zurg** demande à DMM quel film ou quel épisode correspond à chaque fichier. Un sponsor obtient la clé API DMM sur [gatekeeper](https://gatekeeper.debridmediamanager.com/). Sans elle, zurg se fie aux noms de fichiers et moins de titres correspondent. [rex avec zurg](../rex/with-zurg.md#why-dmm-places-the-files) explique la différence.
- **Sonarr Radarr et Prowlarr** peuvent chercher dans DMM comme indexeur de torrents Torznab ou indexeur Usenet Newznab. Les deux nécessitent un sponsoring actif et la clé API DMM. Configurez-les sur les pages [Torznab](https://debridmediamanager.com/torznab) et [Newznab](https://debridmediamanager.com/newznab).
- **Votre liste de souhaits** : appuyez sur **Want** ou suivez une liste Trakt ou MDBList. zurg récupère la liste ainsi que les nouveaux épisodes au fur et à mesure de leur diffusion. Sponsoring requis. Voir [liste de souhaits DMM](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr et Jellyseerr** peuvent utiliser DMM comme Radarr et Sonarr. Les demandes arrivent alors dans votre liste de souhaits pour que zurg les récupère. Sponsoring requis. Voir [Seerr via DMM](seerr.md).
- **rex-direct** donne à un rex réclamé sa propre adresse et son propre certificat. Voir [rex-direct](../rex/any-source.md#rex-direct).

Tout ce qu'ouvre un sponsoring, et l'endroit où chaque élément se configure, se trouve sur [Ce que vous apporte un sponsoring](../guides/sponsorship.md).

## Quand quelque chose ne va pas {#when-something-is-wrong}

| Ce que vous voyez | Quoi faire |
|---|---|
| **Real-Debrid a rejeté cette clé API.** | Le jeton que vous avez collé n'est pas valide. Copiez-le à nouveau depuis [real-debrid.com/apitoken](https://real-debrid.com/apitoken), ou appuyez sur **Sign in with Real-Debrid** à la place. Plus d'infos dans [Votre jeton API Real-Debrid](../guides/real-debrid-api-token.md). |
| **That code expired before it was approved. Try again.** | Le code Real-Debrid a expiré. Appuyez à nouveau sur **Sign in with Real-Debrid** et validez le nouveau code plus vite. |
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | L'offre gratuite de TorBox ne peut pas être utilisée avec DMM. Passez à une offre payante, ou connectez-vous avec un autre service. |
| Only **DL with RD** buttons, no **Instant RD** | Votre service n'a aucune de ces versions en cache. Appuyez sur l'une d'elles et attendez qu'elle se télécharge, ou essayez une autre version. |

Vous êtes bloqué ? Posez votre question dans le forum **dmm-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../guides/remote-help.md) indique quoi inclure.

## Questions

### Qu'est-ce que DMM, au juste ? {#what-actually-is-dmm}

Un site de recherche pour votre compte debrid. Il trouve les versions d'un film ou d'une série, vous indique celles que votre service possède déjà, et ajoute à votre compte celle que vous choisissez. DMM ne stocke lui-même aucun fichier.

### Comment je l'utilise ? {#how-do-i-use-it}

Connectez-vous à votre service debrid, recherchez un titre, ouvrez-le et appuyez sur **Instant RD** (ou sur le bouton **Instant** de votre service) pour une version. Appuyez ensuite sur **Watch**, envoyez-la vers Stremio, ou laissez zurg l'ajouter à Plex.

### DMM est-il fait par Real-Debrid ? {#is-dmm-made-by-real-debrid}

Non. DMM est un projet open source qui fonctionne avec Real-Debrid et cinq autres services. Les gens le recherchent souvent sous le nom « Real-Debrid Media Manager ».

### C'est gratuit ? {#is-it-free}

Oui. Il vous faut votre propre compte debrid, qui est un service payant. Un parrainage DMM ajoute des extras comme la liste de souhaits et les indexeurs : voir [Ce que vous apporte un parrainage](../guides/sponsorship.md).

### Quels services fonctionnent ? {#which-services-work}

Real-Debrid, AllDebrid, TorBox (forfaits payants), Premiumize, Offcloud et Debrid-Link. Easynews fonctionne pour la recherche et le casting, mais pas pour la bibliothèque.
