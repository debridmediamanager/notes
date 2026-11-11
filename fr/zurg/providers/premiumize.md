# Premiumize

`type: premiumize`

Premiumize monte les transferts terminés **et** les fichiers du cloud qui restent après que la liste des transferts a été vidée. Les dossiers imbriqués gardent leurs chemins. Une bibliothèque que vous avez organisée sur Premiumize arrive dans le montage dans l'ordre où vous l'avez laissée.

## Obtenir la clé API {#get-the-api-key}

Connectez-vous et ouvrez [premiumize.me/account](https://www.premiumize.me/account). La clé API se trouve sur cette page.

## La configurer {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Sur une installation neuve du conteneur, laisse le setup l'écrire.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

Sur une installation qui a déjà un `config.yml`, utilise **Add provider** dans le
Dashboard à l'adresse `http://localhost:9999/config/` ou modifie le fichier. Redémarre dans les deux cas.

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` est lu par `zurg setup` et pas par le daemon qui tourne. Il ne fait rien tout seul dans un bloc `environment:` de compose.

## Un identifiant par entrée {#one-credential-per-entry}

Les identifiants de fichiers Premiumize appartiennent au compte qui les a ajoutés. Il n'existe pas de deuxième clé vers laquelle basculer. `download_tokens` est refusé d'office, de même qu'un `strm_link_token` différent de `token`. Un second compte Premiumize correspond à une deuxième entrée avec son propre `name`.

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

Le chargeur est explicite à ce sujet plutôt que d'ignorer discrètement ces clés. Il refuse la configuration et indique l'entrée concernée.

## Ce qui fonctionne ici {#what-works-here}

Parcourir la bibliothèque, les lectures en streaming, les lectures redirigées, les STRM, l'ajout de magnets et de fichiers `.torrent`, ainsi que la suppression fonctionnent tous. Le compte obtient son propre dossier `__premiumize__`, comme tous les autres.

## Les hashes sont mémorisés sur le disque {#hashes-are-remembered-on-disk}

Les hashes fournis via zurg sont écrits dans `data/premiumize/<account>/sources.json` à l'intérieur du bind `/config`. La correspondance entre comptes survit à un redémarrage, et elle survit aussi au vidage de la liste des transferts terminés.

Le contenu cloud que tu as importé par d'autres moyens n'a pas de hash enregistré. Il reste streamable. Il ne peut pas être réparé par hash et il ne peut pas être associé à un autre compte par hash.

!!!warning Supprimer un transfert supprime ses fichiers
Supprimer un transfert Premiumize via zurg supprime aussi les fichiers que ce transfert possède. C'est le comportement de Premiumize lui-même, et ce n'est pas quelque chose que zurg ajoute par-dessus.
!!!

## Limites à connaître {#limits-worth-knowing}

**Les limites de stockage cloud et de fair use sont celles du compte.** zurg ne les augmente pas et ne les contourne pas.

**8 requêtes API simultanées.** Quatre volumes d'une archive multi-volumes sont résolus en même temps.

**Le contenu expire.** Une release disparue est un résultat attendu, pas une panne. Repair ne touche pas à ces releases sauf si vous le demandez.

**La liste des torrents ne contient aucun détail sur les fichiers.** Chaque release demande sa propre requête la première fois.

zurg associe les codes d'erreur du service à l'action à effectuer ensuite.

| Code de Premiumize | Ce que fait zurg |
|---|---|
| `authentication_failed` | Signale un identifiant invalide. Corrigez la clé. |
| `rate_limit_reached` | Met le compte en pause pendant une minute. |
| `account_limit_reached` ou `service_limit_reached` | Signale un quota épuisé. |
| `service_down` | Considère le compte comme temporairement indisponible. |
| `not_found` | Considère le torrent comme disparu. |

## Vérifier que ça fonctionne {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

Avec un seul compte, son propre dossier est exclu de la liste racine du montage,
donc le montage affiche les mêmes fichiers sous `__all__`.

## Quand ça ne marche pas {#when-it-goes-wrong}

**Tout échoue avec un identifiant invalide.** Régénérez la clé sur [premiumize.me/account](https://www.premiumize.me/account), puis mettez à jour l'entrée.
Sachez que Premiumize répond de la même façon à une clé absente et à une clé erronée. Le message ne permet pas de savoir laquelle des deux c'était.

**Une version se lit en streaming mais ne se répare pas.** Aucun hash n'est enregistré pour elle. Elle est donc arrivée dans le compte par une autre voie que zurg. Voir ci-dessus.

**Les lectures se mettent en pause une minute à la fois.** La limite de débit a été atteinte et zurg a volontairement mis le compte en attente. Il reprend tout seul.

**Les URL générées fonctionnent pour quiconque les possède.** Les URL de livraison et l'accès `.strm` gagnent à rester privés. Le quota qu'elles consomment est celui du compte lui-même.
