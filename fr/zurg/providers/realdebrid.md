# Real-Debrid

`type: realdebrid`

zurg a débuté comme serveur [Real-Debrid](http://real-debrid.com/?id=20476302) et c'est là qu'il reste le plus à l'aise. C'est le seul
backend à proposer la sélection fichier par fichier, une liste `__downloads__` séparée, le choix de l'hôte CDN
et un jeton `.strm` dédié.

## Obtenir le jeton API {#get-the-api-token}

Connecte-toi et ouvre [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354).
Le token est une longue chaîne hexadécimale. Copie-la en entier.

!!!warning Désactive d'abord le trafic distant automatique
Sur ta [page de compte](http://real-debrid.com/?id=20476410), vérifie que **Use my
Remote Traffic automatically when needed** est décochée. Si elle reste activée, elle consomme ton quota de trafic distant pour du streaming classique sans te prévenir.
!!!

## La configurer {#configure-it}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

Sur une installation neuve du conteneur, laisse le setup l'écrire pour toi.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

Sur une installation qui a déjà un `config.yml`, utilise le Dashboard à l'adresse `http://localhost:9999/config/` ou modifie le fichier. Ensuite, redémarre.

```bash
docker compose restart zurg
```

### Le seul fournisseur qu'un conteneur peut initialiser depuis l'environnement {#the-one-provider-a-container-can-seed-from-the-environment}

Real-Debrid est le seul compte pour lequel le daemon en cours d'exécution crée seul une configuration. `TOKEN` ou `RD_TOKEN` dans le bloc `environment:` de ton compose sert à remplir `config.yml` lors de l'exécution qui le crée. `MOUNT_PATH` sert à remplir le montage.

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

Les deux ne sont lus **que** lors de cette première exécution. Une fois le fichier créé, c'est lui la seule source de vérité. Une variable obsolète ne pourra jamais annuler silencieusement un chemin de montage que tu as défini dans le Dashboard. Au démarrage, un avertissement s'affiche si un `MOUNT_PATH` est ignoré pour cette raison.

## Clés supplémentaires utilisées par ce backend {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` sont des jetons API de secours sur le même service. Ils prennent le relais quand
la bande passante du jeton actif est épuisée. Ils utilisent le catalogue de cette entrée et leurs propres
bibliothèques de torrents ne sont jamais importées.

`strm_link_token` gère les lectures qui arrivent sur `/strm/`, afin qu'un lecteur qui ouvre un
fichier `.strm` ne consomme pas le jeton que ton montage en direct utilise pour le streaming. Si ce n'est pas défini, il utilise `token` à la place.

Les deux valent le coup d'être configurés ici, car Real-Debrid est l'un des deux seuls backends qui font tourner leurs identifiants.

## Ce que Real-Debrid fait et que les autres ne font pas {#what-real-debrid-does-that-the-others-do-not}

- **Sélection par fichier.** Ajouter une version peut n'en récupérer qu'une partie. Ainsi, `force_select_playable_files` a de quoi agir, et la réparation peut se limiter aux fichiers cassés au lieu de rajouter toute la version.
- **Une deuxième liste appelée downloads.** `__downloads__` à la racine du montage est la liste des liens non restreints, qui n'existe que chez Real-Debrid. La vider en masse demande un cookie de session web. Le bouton Dashboard est donc la seule solution. Une installation sans compte Real-Debrid est prévenue au lieu de voir un faux succès.
- **Choix du CDN et de l'hôte.** `rd_cdn_host_preference` permet de choisir entre le choix de Real-Debrid, ses jumeaux Cloudflare ou un pays précis. Voir [Sélection du CDN et de l'hôte](../reference/config.md#cdn--host-selection).
- **Réparation.** Un lien Real-Debrid enregistré pour un fichier peut cesser de fonctionner alors que le torrent est toujours signalé comme sain. C'est la raison même pour laquelle zurg dispose d'un sous-système de réparation, et c'est le seul backend qui en a besoin.

## Limites à connaître {#limits-worth-knowing}

**Deux ajouts sur un même compte nécessitent 20 secondes d'écart.** Mesuré sur l'API en direct le 2026-08-17. Six noms de releases propres ajoutés à dix secondes d'intervalle ont été refusés six fois sur six. Les mêmes six ajouts espacés de vingt secondes ont été acceptés six fois sur six. zurg cadence ses propres ajouts sur ce seuil.

**Un ajout refusé ressemble exactement à un nom de fichier bloqué.** Real-Debrid répond aux deux par `451 infringing_file`. Le limiteur a aussi de la mémoire. Une fois déclenché, il continue de refuser pendant plusieurs minutes de calme. Lors d'un balayage de réparation en production, quatre heures se sont passées sans aucun ajout, parce que trois ajouts étaient tombés à moins de treize secondes d'intervalle au début.

**Certaines releases sont refusées sur leur nom seul.** Depuis le 14 octobre 2026, ce sont onze chaînes. WEB-DL, WEB.x264 et WEB.H264 ne comptent que dans ce cas exact, donc web-dl, Web-Dl et le WEB.h264 de la scène passent. WEBRip, BDRip, HDRip, DVDRip, HDTV.x264, HDTV.XviD, BluRay.x264 et p.BluRay.DTS comptent dans n'importe quelle casse. Ce dernier a besoin d'un p juste avant, comme dans 1080p.BluRay.DTS. Une release 2002.BluRay.DTS passe sans problème. Seul le séparateur exact compte. WEB.DL, WEB-x264 et BluRay-x264 passent tous. Une release nommée avec l'un d'eux est refusée au premier essai à chaque fois, quel que soit son contenu. Un fichier à l'intérieur d'une release dont le nom correspond est accepté mais ne se lira pas en streaming. zurg connaît ces motifs et refuse ces ajouts localement, plutôt que de consommer un emplacement d'ajout et deux nouvelles tentatives de soixante secondes pour un échec certain.

**Un second exemplaire d'un contenu que le compte possède déjà ne se télécharge jamais.** Real-Debrid accepte l'ajout puis ne récupère rien pour lui. L'instance reste à 0 pour cent avec 0 seeders indéfiniment.

**La liste des torrents ne contient aucun détail sur les fichiers.** Chaque torrent nécessite son propre appel info. C'est pourquoi zurg conserve un cache d'infos sur disque. Un premier scan à froid d'une grande bibliothèque est le cas coûteux, et le cache sert à éviter qu'il se répète.

Trois clés cadencent l'API, et les valeurs par défaut conviennent à un compte ordinaire.

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Avec un seul compte, son propre dossier est retiré de la liste racine du montage,
donc le montage affiche les mêmes fichiers sous `__all__`.

## Quand ça ne marche pas {#when-it-goes-wrong}

**`RD Permission denied` dans le journal.** La clé a été révoquée ou remplacée. Récupère-en une nouvelle sur [real-debrid.com/apitoken](http://real-debrid.com/?id=20476302) et mets à jour l'entrée dans le Dashboard ou dans `config.yml`.

**Chaque ajout renvoie 451.** Soit le nom de la release est une que Real-Debrid refuse catégoriquement, soit les ajouts sont arrivés trop rapprochés et le throttle est toujours actif. Ça se règle en laissant du calme, pas en relançant des tentatives.

**Le mount n'affiche rien au premier démarrage.** Une grosse bibliothèque prend un moment à charger. `/dav/movies/` répond 503 tant que le chargement n'est pas terminé.

**Les liens passent la vérification puis ne servent rien.** Active `use_range_verification` pour que zurg vérifie avec une requête GET ciblée d'un octet plutôt qu'avec une `HEAD`. Certains réseaux et certains serveurs de Real-Debrid répondent mal à une `HEAD`.
