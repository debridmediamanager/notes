# TorBox hébergé Usenet {#torbox-hosted-usenet}

`type: torbox_nzb`

Avec un forfait TorBox Pro, TorBox s'occupe de la partie Usenet à votre place. zurg envoie les fichiers `.nzb` présents dans son répertoire de surveillance vers votre compte TorBox. TorBox récupère chaque version, la répare et la sert comme n'importe quel téléchargement TorBox. zurg affiche dans le montage ce que TorBox a récupéré, à côté du reste. Il n'y a pas de compte de serveur de news et aucun article Usenet n'est décodé sur votre machine.

Ce n'est pas le [serveur de news de TorBox](torbox-news-server.md). Il s'agit d'un identifiant pour le backend `nzb`, qui lit lui-même les articles et qui est décrit sur la page [Usenet](usenet.md). Ce n'est pas non plus une entrée `torbox`. Celle-ci liste vos torrents, et la page [TorBox](torbox.md) la couvre.

## Ce dont vous avez besoin {#what-you-need}

- **Un forfait TorBox Pro.** Un forfait inférieur ne prend pas en charge les NZB.
- **Ta clé d'API TorBox** depuis [torbox.app/settings](https://torbox.app/settings).
  C'est la même clé qu'utilise une entrée `torbox`.
- **Une version nightly récente de zurg.** Les nightlies nécessitent un parrainage actif.
- **Un hôte normal.** zurg+rex Android, un serveur Plex sur ton téléphone, n'a pas de backend `torbox_nzb`. Sur un appareil Android, lis les NZB hébergés sur TorBox via TorBox Cast de DMM ou via l'addon Kodi à la place.

## La configurer {#configure-it}

L'entrée prend un `token` ; il n'y a pas de bloc `nntp`. `watchlist` ne peut pas être défini dessus, car un compte NZB ne peut pas ajouter de torrents.

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

Sur une installation fraîche du conteneur, enregistrez d'abord votre clé dans `~/zurg/secrets/torbox`, puis laissez l'assistant de configuration la lire.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

Sur une installation qui a déjà un `config.yml`, vous pouvez aussi utiliser **Add provider** dans le tableau de bord à l'adresse `http://localhost:9999/config/` et choisir `torbox_nzb`. Redémarrez zurg dans les deux cas.

```bash
docker compose restart zurg
```

## Comment les NZB arrivent {#how-nzbs-get-in}

Tout ce qui arrive dans une entrée `nzb` passe de la même façon par ici. L'action TorBox de DMM est la seule voie qui contourne zurg.

- **Le dossier de surveillance.** Dépose un fichier dans `nzbs/`, à côté de la configuration (`~/zurg/nzbs/` sur l'hôte, `/config/nzbs/` dans le conteneur). zurg l'envoie à TorBox.
- **Sonarr et Radarr** via le point de terminaison compatible SABnzbd de zurg. Voir [Sonarr et Radarr pour Usenet](../guides/sonarr-radarr.md).
- **Acquisition.** Les indexeurs Newznab, DMM Wanted et les listes de suivi y envoient leurs éléments. Voir [Acquisition](../guides/acquisition.md).
- **L'action TorBox de DMM** sur un résultat Usenet envoie le NZB directement à TorBox. La release apparaît aussi dans zurg, mais zurg ne garde aucun NZB pour elle. Le bouton de réparation ne peut donc pas la récupérer à nouveau une fois que TorBox l'a supprimée.

Si TorBox ne peut pas récupérer un post, il est signalé à Sonarr ou Radarr comme un téléchargement échoué. Le client met alors la release sur liste noire et relance la recherche.

## Ce qui diffère de `nzb` {#what-differs-from-nzb}

- **Pas de compte Usenet.** Il n'y a ni quota de connexions à dimensionner, ni rétention des fournisseurs à prendre en compte. C'est le cache de TorBox qui décide de ce qu'un post peut récupérer.
- **Aucun article n'est décodé ici.** TorBox récupère la release entière. La récupération des articles, la réparation PAR2, le cache des articles et les vérifications d'articles ne s'appliquent pas ; le cache disque des archives décodées, lui, s'applique toujours. Un téléchargement est vérifié selon que TorBox l'a bien récupéré.
- **Un cache de 30 jours.** Une release déjà récupérée sur TorBox par quelqu'un d'autre est prête tout de suite. TorBox supprime une release 30 jours après l'avoir mise en cache. Le bouton de réparation du tableau de bord la récupère à nouveau en renvoyant son NZB une fois de plus, donc gardez les fichiers dans `nzbs/`. zurg ne renvoie jamais rien de lui-même, car TorBox considère les téléchargements répétés sans surveillance comme un abus.
- **Un slot par NZB en cours.** Un post que TorBox est encore en train de récupérer occupe un des slots actifs de votre forfait. Une entrée `torbox` sur la même clé utilise les mêmes slots pour ses torrents.
- **60 posts par heure.** TorBox accepte ce nombre de nouveaux NZB par heure et par clé. Un gros arriéré, comme un `nzbs/` complet au premier démarrage, se vide sur plusieurs heures.

## Un compte NZB par instance {#one-nzb-account-per-instance}

Une instance accepte une entrée `nzb` ou une entrée `torbox_nzb`, jamais les deux. Sinon, chacune listerait tous les fichiers de `nzbs/`. Pour utiliser les deux, donnez à l'autre type sa propre instance, avec son propre répertoire de travail. Si `dmm_api_key` est défini sur les deux, [désactivez la source `dmm-wanted` sur l'une des deux](../guides/dmm-wanted.md#two-zurgs-on-one-key), sinon chaque titre de Wanted sera récupéré deux fois. Les deux peuvent rester à côté de vos comptes debrid.

L'addon Stremio de zurg envoie son choix au compte NZB que l'instance utilise. Avec `torbox_nzb`, une release déjà présente chez TorBox démarre dans le délai d'attente de l'addon, si aucune autre publication NZB n'attend. Une release non mise en cache doit d'abord être entièrement traitée par TorBox, ce qui prend plus longtemps qu'un lecteur n'attend.

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

Avec un seul compte, son propre dossier est exclu de la liste racine du montage, donc le montage affiche les mêmes fichiers sous `__all__`. Le nom du dossier suit le nom de l'entrée, qui vaut par défaut son type.
