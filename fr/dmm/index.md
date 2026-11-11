# DMM

[Debrid Media Manager](https://debridmediamanager.com) vous aide à trouver des films et des séries et à les garder dans votre bibliothèque debrid.

L'extension de navigateur DMM ajoute un bouton sur IMDb, Trakt et d'autres sites de films et de séries. [Les boutons DMM dans Safari](safari.md) explique la configuration pour Safari.

DMM sert aussi les autres projets :

- **zurg** demande à DMM quel film ou quel épisode correspond à chaque fichier. Un sponsor obtient la clé API DMM depuis [gatekeeper](https://gatekeeper.debridmediamanager.com/). Sans elle, zurg se base sur les noms de fichiers et moins de titres correspondent. [rex avec zurg](../rex/with-zurg.md#why-dmm-places-the-files) explique la différence.
- **Sonarr Radarr et Prowlarr** peuvent chercher sur DMM comme indexeur de torrents Torznab ou indexeur Usenet Newznab. Les deux demandent un sponsoring actif et la clé API DMM. Configurez-les sur les pages [Torznab](https://debridmediamanager.com/torznab) et [Newznab](https://debridmediamanager.com/newznab).
- **Votre liste de souhaits** : appuyez sur **Want** ou suivez une liste Trakt ou MDBList. zurg récupère la liste et les nouveaux épisodes au fur et à mesure de leur diffusion. Sponsoring requis. Voir [la liste de souhaits DMM](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr et Jellyseerr** peuvent utiliser DMM comme Radarr et Sonarr. Les demandes arrivent alors dans votre liste de souhaits, que zurg récupère. Sponsoring requis. Voir [Seerr via DMM](seerr.md).
- **rex-direct** donne à un rex réclamé sa propre adresse et son propre certificat. Voir [rex-direct](../rex/any-source.md#rex-direct).

Tout ce que débloque un sponsoring, et l'endroit où chaque élément se configure, se trouve sur [Ce que vous apporte un sponsoring](../guides/sponsorship.md).

Bloqué ? Posez votre question dans le forum **dmm-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../guides/remote-help.md) indique quoi inclure.
