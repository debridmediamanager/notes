# AllDebrid

`type: alldebrid`

[AllDebrid](https://alldebrid.com/?uid=1kk5i&lang=en) est l'autre backend qui fait tourner les identifiants. Donc `download_tokens`
et un token `.strm` séparé ont tous deux un sens ici. Ses listes de fichiers viennent d'un point de terminaison à eux plutôt que de la liste de magnets. Cela change ce que l'on ressent lors d'un premier scan d'une grande bibliothèque.

## Obtenir la clé API {#get-the-api-key}

Connecte-toi et ouvre [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i).
Génère une clé et copie-la.

## La configurer {#configure-it}

```yaml
zurg: v1
providers:
  - type: alldebrid
    token: YOUR_ALLDEBRID_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Sur une installation neuve du conteneur, laisse setup l'écrire.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider alldebrid
```

Sur une installation qui a déjà un `config.yml`, utilise **Add provider** dans le
Dashboard à `http://localhost:9999/config/` ou modifie le fichier. Redémarre
dans les deux cas.

```bash
docker compose restart zurg
```

`ALLDEBRID_TOKEN` est lu par `zurg setup` et non par le daemon qui tourne.
Le mettre dans le bloc `environment:` de ton compose puis démarrer le conteneur
ne fait rien tout seul.

## Clés supplémentaires utilisées par ce backend {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: alldebrid
    token: PRIMARY_AD_API_KEY
    strm_link_token: AD_KEY_FOR_STRM
    download_tokens:
      - SECOND_AD_API_KEY
```

`download_tokens` sont des clés de secours sur le même service. Elles prennent le relais quand la bande passante de la clé active est épuisée. Elles utilisent le catalogue de cette entrée, et leurs propres bibliothèques ne sont jamais importées.

`strm_link_token` gère les lectures qui arrivent sur `/strm/`, pour qu'un lecteur qui ouvre un `.strm` ne consomme pas la clé utilisée par ton montage en direct. S'il n'est pas défini, il revient à `token`.

## Le premier scan se remplit progressivement {#the-first-scan-fills-in-gradually}

AllDebrid v4.1 a déplacé les détails des fichiers hors de la liste des magnets, vers un point de terminaison séparé. Lister vos magnets ne dit donc pas à zurg ce qu'ils contiennent. Chaque release nécessite une requête.

La bonne nouvelle, c'est qu'elle n'est nécessaire **qu'une seule fois** et non à chaque redémarrage. L'arborescence de fichiers d'un magnet est figée dès qu'il passe à Ready. Le cache d'infos de zurg sur le disque est donc permanent pour lui. Un batcher placé devant le point de terminaison gère le premier scan. Ce que vous voyez au premier lancement, c'est une grosse bibliothèque qui apparaît par morceaux, puis qui ne refait plus ce travail.

## Limites à connaître {#limits-worth-knowing}

**Aucune limite publiée sur les magnets actifs.** zurg n'en invente pas. La réparation n'attend jamais une place qui n'a jamais été rare.

**600 requêtes par minute pour une seule clé.** C'est le quota documenté. zurg se limite à 600 moins 100, afin que les nouvelles tentatives que son client HTTP effectue de lui-même ne fassent pas dépasser la limite réelle lors d'une rafale. En pratique, la concurrence est la contrainte limitante, et elle est plafonnée à 12 pour correspondre aux 12 requêtes par seconde documentées.

**La 33e connexion vers un même serveur de livraison reçoit un 429.** Mesuré le 2026-08-23 en ouvrant une connexion toutes les 500 ms et en la maintenant ouverte. AllDebrid génère un nouveau nom d'hôte de livraison à chaque déverrouillage. Cette limite ne s'applique donc que lorsque plusieurs lectures tombent sur le même hôte. zurg met en file d'attente au-delà de 32 au lieu d'ouvrir une nouvelle connexion.

**Il n'y a pas de sélection de fichiers.** Ajouter un magnet récupère l'ensemble du contenu, et la réparation rajoute la release entière.

**Le contenu disparaît de lui-même.** Les magnets sont retirés d'un compte au fil du temps, et un lien peut être supprimé par l'hébergeur. Une release qui a disparu est un résultat attendu, et non une corruption. La réparation la laisse tranquille, sauf si tu le demandes explicitement.

**Les liens stockés ne se périment pas.** Les liens verrouillés enregistrés pour un fichier sont régénérés à partir de l'état actuel du magnet. Le statut du magnet indique déjà si les données sont là. zurg ne dépense donc pas un déverrouillage par torrent à chaque scan à froid pour apprendre ce que le statut lui disait déjà gratuitement.

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/alldebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Avec un seul compte, son propre dossier est exclu de la liste racine du montage,
donc le montage affiche les mêmes fichiers sous `__all__`.

## Quand ça ne marche pas {#when-it-goes-wrong}

**`AllDebrid rejected the API key` dans le journal.** La clé a été révoquée ou régénérée. Récupérez-en une nouvelle sur [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i) et mettez à jour l'entrée.

**Une bibliothèque froide apparaît lentement.** C'est normal. Voir la section ci-dessus. Il s'agit d'une seule recherche par release, et elle ne se répète pas.

**Une release se lit ailleurs dans le montage mais renvoie 404 sous `__alldebrid__`.** La validité est jugée par compte, et ce dossier fige les lectures sur ce seul compte. Un autre compte possède sans doute une bonne copie.
