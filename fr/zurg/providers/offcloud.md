# Offcloud

`type: offcloud`

Offcloud résout les identifiants de fichiers via son point de terminaison cloud explore. Les tailles de fichiers sont vérifiées auprès du serveur de livraison plutôt que d'être reprises de la liste. Les métadonnées de torrent en cache fournissent les chemins de dossiers chaque fois qu'elles peuvent être associées sans ambiguïté.

## Obtenir la clé API {#get-the-api-key}

Connectez-vous et ouvrez [offcloud.com/#/account](https://offcloud.com/#/account). La clé API se trouve sur cette page.

## La configurer {#configure-it}

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Sur une installation neuve du conteneur, laisse setup l'écrire.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

Sur une installation qui a déjà un `config.yml`, utilise **Add provider** dans le Dashboard à l'adresse `http://localhost:9999/config/` ou modifie le fichier. Redémarre dans les deux cas.

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` est lu par `zurg setup` et non par le daemon en cours d'exécution.

## Un identifiant par entrée {#one-credential-per-entry}

Les identifiants de fichiers Offcloud appartiennent au compte qui les a listés. Il n'existe pas de deuxième clé vers laquelle basculer. `download_tokens` est refusé, tout comme un `strm_link_token` différent de `token`. Un second compte se configure avec une deuxième entrée, qui a son propre `name`.

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## Ce qui fonctionne ici {#what-works-here}

Parcourir la bibliothèque, les lectures en streaming, les lectures redirigées, les STRM, l'ajout de magnets et de fichiers `.torrent`, ainsi que la suppression fonctionnent tous. Le compte obtient son propre répertoire `__offcloud__`.

## Limites à connaître {#limits-worth-knowing}

**8 requêtes API simultanées.** Quatre volumes d'une archive multi-volumes sont résolus en même temps.

**Le contenu expire.** Une release qui a disparu est normale, pas un bug. Repair la laisse tranquille sauf si vous le demandez.

**La liste des torrents ne contient aucun détail de fichier.** Chaque release demande sa propre requête la première fois.

**Une liste de fichiers ambiguë est une erreur, pas une supposition.** Parfois, les métadonnées de torrent en cache ne peuvent pas être associées à une seule release précise. zurg le signale au lieu de choisir des chemins de dossiers qui pourraient appartenir à autre chose.

**Les magnets mal formés sont refusés en local.** Ils n'atteignent jamais le service. Un mauvais magnet ne coûte rien.

Le vocabulaire d'erreurs d'Offcloud est pauvre. `NOAUTH` est le seul code sur lequel zurg peut agir, et il signifie que les identifiants ont été rejetés. Tout le reste arrive sous forme de refus sans raison.

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__all__/ | head
```

Avec un seul compte, son propre dossier est exclu de la liste racine du montage,
donc le montage affiche les mêmes fichiers sous `__all__`.

## Quand ça ne marche pas {#when-it-goes-wrong}

**`NOAUTH` dans le journal.** La clé a été révoquée ou régénérée. Récupérez-en une nouvelle sur
[offcloud.com/#/account](https://offcloud.com/#/account) et mettez à jour l'entrée.

**`API refused request` sans autre message.** Offcloud n'a pas indiqué la raison. Vérifiez le
compte dans un navigateur avant de supposer que zurg est en cause.

**Une release n'affiche aucun dossier.** Les métadonnées du torrent en cache n'ont pas pu être
associées à une seule release. Les fichiers restent lisibles. Ils sont simplement à plat.

**Les URLs générées fonctionnent pour quiconque les possède.** Les URLs de diffusion sont
rafraîchies lorsque leur cache expire ou lorsqu'une lecture les invalide. Le quota qu'elles
consomment est celui du compte. Gardez-les, ainsi que l'accès à `.strm`, privés.
