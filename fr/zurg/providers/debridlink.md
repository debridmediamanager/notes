# Debrid-Link

`type: debridlink`

La liste seedbox de [Debrid-Link](https://debrid-link.com/id/diG1t) contient tous les fichiers. Un rafraîchissement de la bibliothèque demande une seule parcours paginé au lieu d'une recherche par release. C'est le moins coûteux des trois backends cloud à garder synchronisé.

## Obtenir la clé API {#get-the-api-key}

Connecte-toi et ouvre
[debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey). Génère une
clé et copie-la.

## La configurer {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Sur une installation neuve du conteneur, laisse le setup l'écrire.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

Sur une installation qui a déjà un `config.yml`, utilise **Add provider** dans le
Dashboard à l'adresse `http://localhost:9999/config/` ou modifie le fichier. Redémarre
dans les deux cas.

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` est lu par `zurg setup` et non par le daemon en cours d'exécution.

## Un identifiant par entrée {#one-credential-per-entry}

Debrid-Link retrouve chaque fichier grâce à un ID qui appartient au compte qui sert à lister la bibliothèque.
Il n'y a pas de deuxième clé vers laquelle basculer. `download_tokens` est refusé, tout comme un `strm_link_token` différent de `token`. Un second compte correspond à une seconde entrée, avec son propre `name`.

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## Ce qui fonctionne ici {#what-works-here}

Parcourir la bibliothèque, les lectures en streaming, les lectures redirigées, les fichiers STRM, l'ajout par magnet et par fichiers `.torrent`, ainsi que la suppression, fonctionnent tous. Le compte obtient son propre répertoire `__debridlink__`.

## Limites à connaître {#limits-worth-knowing}

**20 emplacements actifs.** C'est le plafond que zurg applique avant de bloquer l'ajout d'autres contenus.

**8 requêtes API simultanées.** Quatre volumes d'une archive multi-volumes sont résolus en même temps.

**Le contenu expire.** Une release qui a disparu est un comportement attendu, pas une erreur.

**Il n'y a pas de vérification de cache.** Debrid-Link a retiré ce point de terminaison et zurg ne l'utilise pas. Un ajout limité aux contenus en cache ne peut confirmer un hit qu'à partir de la réponse de l'ajout lui-même. Demander si quelque chose est en cache avant de l'ajouter n'est pas une question à laquelle ce backend peut répondre.

zurg associe les codes d'erreur du service à ce qu'il doit faire ensuite.

| Code de Debrid-Link | Ce que fait zurg |
|---|---|
| `badToken` ou `badSign` | Signale un identifiant invalide. Corrigez la clé. |
| `floodDetected` | Met le compte en pause pendant une heure. |
| `maxTorrent` `maxData` `maxLink` et leurs variantes `Host` | Signale un quota quotidien d'ajouts ou de trafic épuisé. |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | Considère le compte comme temporairement indisponible. |
| `badId` | Considère le torrent comme disparu. |

!!!warning Un refus de flood coûte une heure
`floodDetected` met le compte en pause pendant une heure entière plutôt qu'une minute. C'est voulu. Réessayer pendant un refus de flood, c'est ce qui vous vaudra le suivant. Espacez ce qui martelait le service avant de redémarrer zurg.
!!!

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

Avec un seul compte, son propre dossier est exclu de la liste racine du montage,
donc le montage affiche les mêmes fichiers sous `__all__`.

## Quand ça ne marche pas {#when-it-goes-wrong}

**Rien ne se passe pendant une heure.** Un refus global. Voir l'avertissement ci-dessus.

**Les ajouts sont refusés mais les lectures fonctionnent encore.** Le quota quotidien d'ajouts ou de trafic est épuisé. Il se réinitialise selon le calendrier du service.

**Les ajouts réussissent puis restent bloqués.** Sans point de terminaison de cache, il n'y a aucun moyen de savoir à l'avance si un hash était déjà disponible. Un ajout non mis en cache se télécharge comme n'importe quel autre.
