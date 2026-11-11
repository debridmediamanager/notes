# TorBox

`type: torbox`

[TorBox](https://torbox.app/subscription?referral=74ffa560-7381-4a18-adb1-cef97378c670) est la bibliothèque la moins chère pour que zurg reste synchronisé, et aussi la plus facile à brider en lecture. Sa liste de torrents contient déjà tous les fichiers. Une mise à jour de la bibliothèque ne coûte qu'une seule requête, et non une par torrent. Son point de résolution des liens fonctionne avec un quota fixe, pas avec un débit. zurg y fait donc très attention exprès.

## Obtenir la clé API {#get-the-api-key}

Connectez-vous et ouvrez [torbox.app/settings](https://torbox.app/settings). La clé API se trouve sur cette page.

**Un compte gratuit ne fonctionne pas avec zurg.** TorBox répond à chaque requête sur la bibliothèque avec une clé gratuite par `PLAN_RESTRICTED_FEATURE`, donc zurg ne peut pas lire le contenu du compte. Prenez un forfait payant. Un forfait payant qui expire redevient gratuit et provoque la même erreur.

## La configurer {#configure-it}

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Sur une installation neuve dans un conteneur, laisse setup l'écrire.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

Sur une installation qui a déjà un `config.yml`, utilise **Add provider** dans le Dashboard à `http://localhost:9999/config/` ou modifie le fichier. Dans les deux cas, redémarre ensuite.

```bash
docker compose restart zurg
```

!!!warning Une clé TorBox dans ton environnement compose ne sert à rien toute seule
`TORBOX_TOKEN` est lu par `zurg setup` et pas par le daemon en cours d'exécution. Seul le `TOKEN` de Real-Debrid crée une config au premier démarrage. Passe la clé à un conteneur de setup ou ajoute le compte dans le Dashboard.
!!!

Pour une installation sans surveillance, indique à setup un fichier plutôt qu'une variable d'environnement.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## Deux clés qui ne s'appliquent pas ici {#two-keys-that-do-not-apply-here}

`download_tokens` est accepté mais ne fera pas ce qu'il fait sur Real-Debrid.
Changer de clé pour passer à une seconde ne remappe pas les identifiants de torrents et de fichiers. Sur TorBox, ces identifiants appartiennent au compte qui les a listés. Un second compte TorBox a besoin de sa propre entrée, avec son propre `name`.

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` est accepté mais inutilisé. TorBox génère une URL de téléchargement à chaque requête. Il n'existe pas d'identifiant longue durée auquel un fichier `.strm` pourrait se rattacher.

## Les slots actifs sont la vraie limite {#active-slots-are-the-real-ceiling}

TorBox a une restriction qui la définit : le nombre de torrents qui peuvent être en cours de téléchargement ou de partage en même temps. Real-Debrid, c'est la bande passante. Chez TorBox, c'est les slots.

| Forfait | Slots actifs |
|---|---|
| Free | 1 mais zurg ne peut pas utiliser une clé gratuite (voir plus haut) |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

zurg lit le forfait depuis le compte et limite l'ajout de nouveaux torrents en fonction de celui-ci. Un compte dont zurg ne peut pas lire le forfait est traité comme s'il en avait 3.

Compte tout le reste qui ajoute des torrents sur ce même budget. Sonarr et Radarr qui récupèrent via le point de terminaison qBittorrent, un balayage de réparation et une liste de suivi utilisent tous ces mêmes slots.

## Limites à connaître {#limits-worth-knowing}

**La résolution des liens est un budget d'environ cent appels, et non un débit.**
Mesuré le 2026-08-30. Une erreur 429 accompagnée de `Retry-After: 300` est arrivée à l'appel cumulé 100 quand les appels étaient envoyés aussi vite que possible. Elle est arrivée à l'appel 94 quand ils étaient espacés d'une seconde. Le blocage concerne tout le compte. Il bloque tout le montage pendant cinq minutes, et pas seulement la lecture qui l'a déclenché.

Deux conséquences en découlent, et zurg s'en charge tout seul.

- Il ne résout jamais un fichier que personne n'a demandé. Les autres backends prennent une longueur d'avance sur l'épisode suivant. TorBox ne peut pas se permettre cette supposition, parce qu'un serveur multimédia qui analyse une bibliothèque ouvre chaque fichier une seule fois, et chacune de ces ouvertures part de zéro.
- Il résout les volumes d'une archive multi-volumes strictement un par un. Aller plus vite consommerait le plafond plusieurs fois, et achèterait les volumes situés après un volume cassé avant que quoi que ce soit ait découvert qu'ils n'étaient pas nécessaires.

**60 ajouts non mis en cache par heure.** Les ajouts mis en cache relèvent plutôt du budget par minute.

**300 requêtes par minute, tous endpoints confondus, pour une même clé.** zurg se limite à 300 moins 60, afin que les nouvelles tentatives que son client HTTP effectue de lui-même ne fassent pas dépasser le plafond réel à une rafale comptée dans le budget.

**La 21e connexion vers un même hôte CDN reçoit une erreur 429.** Mesuré le 2026-08-23 en ouvrant une connexion toutes les 500ms et en la gardant ouverte. La limite s'applique par hôte et non par clé. Répartir les lectures sur la flotte de TorBox évite le problème, alors que les concentrer sur un seul nœud ne l'évite pas. zurg met en file d'attente au-delà de 20 au lieu de composer une nouvelle connexion. Le refus se transforme ainsi en une courte attente locale.

**Le contenu est supprimé à l'issue de la fenêtre de rétention du plan.** Un torrent qui a disparu est un comportement attendu et non une panne. La réparation le laisse tranquille, sauf si tu la lui demandes explicitement.

**Il n'existe pas de sélection de fichiers.** Ajouter un torrent récupère l'intégralité de son contenu, et la réparation rajoute la release complète.

Le détail complet, avec les sources, se trouve dans [limites de TorBox](torbox-limits.md).

## Choisir une région CDN {#choosing-a-cdn-region}

```yaml
tb_cdn_host_preference: "auto"
```

`auto` laisse le choix de TorBox tel quel. `force_location_<region>` fait servir les téléchargements depuis cette région. Seules les régions qui annoncent actuellement un nœud de livraison peuvent être forcées, et la liste déroulante du Dashboard ne propose que celles-là. Ne touche pas à `cdn_host_preference` ici. Cette clé ne concerne que Real-Debrid et ses valeurs sont des codes de localisation de Real-Debrid.

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__all__/ | head
```

Avec un seul compte, son propre dossier est exclu de la liste racine du montage,
donc le montage affiche les mêmes fichiers sous `__all__`.

## Quand ça ne marche pas {#when-it-goes-wrong}

**Le log affiche `Account <name> refused zurg` ou répète `TorBox rejected the API key`.**
Le forfait est épuisé et la clé est passée sur le forfait gratuit. À partir du nightly 2026.10.11.2240, zurg charge tes autres comptes sans lui. La carte du compte sur le tableau de bord affiche `Refused: the account's plan does not include API access`. Ses releases restent listées mais ne se lisent pas, et rien n'est supprimé ni mis à la corbeille à cause de ça. zurg redemande à TorBox toutes les 10 minutes et reprend le compte dès que le forfait est de nouveau payant. Sur les anciens nightly, toute la bibliothèque ne finissait jamais de charger, donc le contenu de tes autres comptes disparaissait aussi. Mets zurg à jour ou renouvelle le forfait. Mettre en commentaire le provider `torbox` dans `config.yml` puis redémarrer zurg fonctionne aussi.

**La lecture s'arrête pendant cinq minutes d'affilée.** Le quota requestdl est épuisé et le 429 touche tout le compte. Quelque chose résout plus de liens que nécessaire. Un serveur média qui scanne tout le mount d'un coup en est la cause habituelle. Indique-lui un seul dossier plutôt que tous.

**Les ajouts ne sont plus acceptés.** Soit tous les emplacements actifs sont pris, soit la limite d'ajouts par heure est atteinte. Les deux se libèrent d'eux-mêmes, et réessayer n'y change rien.

**Une release affiche moins de fichiers que prévu.** `__torbox__` n'affiche que ce que TorBox détient réellement. Si un autre compte a la release complète, le reste du mount continue de la servir en entier.

**Un torrent a disparu.** Rétention. Voir plus haut. zurg ne le réajoute pas sans intervention, parce que le redécouvrir coûterait du budget du compte pour rien.
