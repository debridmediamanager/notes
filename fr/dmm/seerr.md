# Seerr via DMM {#seerr-through-dmm}

Ajoutez DMM à [Seerr](https://github.com/seerr-team/seerr) comme Radarr et Sonarr. Les demandes approuvées
arrivent dans votre [liste de souhaits DMM](../zurg/guides/dmm-wanted.md) pour que zurg les récupère. Vous n'avez pas besoin de
Radarr ni de Sonarr. Seerr doit seulement pouvoir joindre debridmediamanager.com. Overseerr et Jellyseerr fonctionnent
de la même façon.

C'est réservé aux sponsors. Seerr se connecte avec la clé API DMM de [gatekeeper](https://gatekeeper.debridmediamanager.com/).

## Ce dont vous avez besoin {#what-you-need}

- zurg qui lit ta liste de souhaits depuis DMM avec `dmm_api_key` dans `config.yml`. Voir [Fetch what you want from DMM](../zurg/guides/dmm-wanted.md#what-you-need).
- Seerr configuré avec ton serveur Plex, Jellyfin ou Emby pour qu'il sache quels épisodes tu possèdes.

## Ajouter DMM comme Radarr {#add-dmm-as-radarr}

Dans Seerr, ouvrez **Settings → Services** et cliquez sur **Add Radarr Server**. Remplissez-le comme ceci :

| Field | Value |
|---|---|
| Default Server | coché |
| 4K Server | décoché |
| Server Name | `DMM`, ou un autre nom |
| Hostname or IP Address | `debridmediamanager.com` |
| Port | `443` |
| Use SSL | coché |
| API Key | votre clé API DMM |
| URL Base | `/api/arr/radarr` |

Cliquez sur **Test**. Une fois la connexion établie, choisissez **Any** pour Quality Profile et **/dmm** pour Root Folder.
Laissez Minimum Availability tel quel. Cochez **Enable Scan** et cliquez sur **Add Server**.

![Boîte de dialogue Add Radarr Server de Seerr remplie pour DMM](../assets/seerr-dmm/01-seerr-radarr-dmm.webp)

Si le test échoue, vérifiez la clé : c'est celle qui se trouve sur la page [Settings](https://debridmediamanager.com/settings) de DMM. DMM la refuse aussi une fois votre sponsoring expiré.

## Ajouter DMM comme Sonarr {#add-dmm-as-sonarr}

Appuyez sur **Add Sonarr Server** et utilisez URL Base `/api/arr/sonarr`. Après **Test**, choisissez **Any** et
`/dmm` pour les profils et les dossiers racine. Cochez **Enable Scan** et appuyez sur **Add Server**.

![La boîte de dialogue Add Sonarr Server de Seerr remplie pour DMM](../assets/seerr-dmm/02-seerr-sonarr-dmm.webp)

## Faire une demande {#requesting}

Faites une demande comme d'habitude. Un film approuvé est ajouté à votre liste de souhaits :

![Demande d'un film dans Seerr](../assets/seerr-dmm/03-seerr-request-movie.webp)

![Le film apparaît comme demandé](../assets/seerr-dmm/04-seerr-movie-requested.webp)

Pour une série, choisissez les saisons que vous voulez. Une demande ultérieure peut en ajouter d'autres. Pour suivre toute la série, y compris les nouvelles saisons, appuyez sur **Want all seasons** sur sa page DMM.

![Choix des saisons d'une série](../assets/seerr-dmm/05-seerr-request-seasons.webp)

Votre [liste de souhaits](https://debridmediamanager.com/wanted) affiche chaque titre en quelques secondes. zurg le récupère en moins d'une minute.

## Ce que Seerr affiche {#what-seerr-shows}

Seerr lit la liste de DMM une fois par jour dans **Radarr Scan** et **Sonarr Scan**. Pour les lancer maintenant, ouvrez
**Settings → Jobs & Cache** et cliquez sur **Run Now** à côté de chacun.

- **Un film** : zurg l'a récupéré, il apparaît comme **Available**.

  ![Un film récupéré apparaît comme disponible](../assets/seerr-dmm/06-seerr-movie-available.webp)

- **Une série** reste en **Processing** tant que ses épisodes n'arrivent pas dans votre bibliothèque Plex, Jellyfin ou Emby et que le scan de Seerr sur ce serveur ne les trouve pas. DMM ne sait pas quels épisodes zurg possède.

## Supprimer un titre {#removing-a-title}

Ouvre le titre dans Seerr, appuie sur le bouton engrenage, puis sur **Remove from Radarr** (ou **Remove from Sonarr**). Ça le retire de ta liste de souhaits. Ce que zurg a déjà récupéré reste dans ta bibliothèque. Le bouton **Open in Radarr** à côté ouvre le titre sur DMM.

Bloqué ? Pose ta question dans le forum **dmm-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../guides/remote-help.md) indique quoi inclure.

## Seerr via DMM ou la source Seerr intégrée de zurg {#seerr-through-dmm-or-zurgs-own-seerr-source}

zurg peut aussi lire Seerr directement, avec une [source `seerr`](../zurg/guides/acquisition.md#configuration).
Utilisez l'une des deux, pas les deux :

- **Via DMM**, Seerr doit seulement avoir accès à Internet. Les demandes apparaissent dans votre liste de souhaits à côté de ce que vous avez ajouté avec **Want**, et le scan quotidien de Seerr marque comme disponibles les films récupérés par zurg.
- **La source propre à zurg** traite une demande 4K différemment d'une demande 1080p, mais zurg doit pouvoir joindre Seerr.
