# Cycle de vie d'un torrent sur Real-Debrid, AllDebrid et TorBox {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

Mesuré le 2026-08-30 sur des comptes en service. Tout ce qui est marqué **observé** vient d'une capture. Tout ce qui est marqué **déduit** n'en vient pas, et le texte indique pourquoi.

zurg en a besoin parce que le shim qBittorrent doit dire à Sonarr et Radarr à quelle étape se trouve un téléchargement. Pour l'instant, il ne peut pas le faire. `TorrentInfo.Status` contient le vocabulaire de statuts de Real-Debrid, et les paquets AllDebrid et TorBox le traduisent avant que le code de zurg ne voie le torrent. Le statut TorBox `stalled (no seeds)` arrive sous la forme `queued`. Rien ne transporte du tout les seeders, la vitesse ou l'eta. Il a donc fallu construire le tableau des étapes à partir de ce qui circule sur le réseau, et non à partir des paquets des fournisseurs qui le normalisent déjà.

Le harnais est `scripts/torrent_lifecycle_probe.py`. Il interroge directement les API REST brutes, afin que les captures contiennent le statut tel qu'il circule sur le réseau. Il supprime tout ce qu'il ajoute en sortie, y compris lors d'un Ctrl-C.

---

## Comment cela a été mesuré {#how-this-was-measured}

### Les comptes {#the-accounts}

| Fournisseur | Compte | Pourquoi celui-ci |
|---|---|---|
| Real-Debrid | un compte de test | aucun zurg en cours d'exécution ne l'utilise, donc rien d'autre ne l'a touché pendant l'exécution |
| AllDebrid | une clé de test | le compte contenait déjà d'autres magnets, donc seuls les ids créés pendant l'exécution ont été supprimés |
| TorBox | une clé réelle | **une autre instance de zurg était chargée avec le même compte**, et ce n'est pas un simple détail. Voir [Dangers](#hazards-found-on-the-way) |

Les identifiants viennent de `RD_TOKEN` `AD_KEY` `TB_KEY` dans l'environnement. Rien ne les écrit dans une
capture.

### Les torrents {#the-torrents}

Tout est légitime. Images FOSS et film du domaine public. Chaque info hash issu d'un `.torrent` a été recalculé à partir du fichier par le harnais de test, et non saisi à la main. Les tailles d'essaim viennent de scrapes du tracker faits le même jour.

| Cas | Torrent | Info hash | Taille | Seeders du tracker | Webseeds |
|---|---|---|---|---|---|
| en cache | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | n/a | n/a |
| en cache | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | n/a | n/a |
| en cache | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 à 27 | aucun |
| non en cache | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| non en cache | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 seeders et 0 leechers | 3 |
| sans seeders | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | aucun |
| sans seeders | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | aucun |
| sans métadonnées | 40 hex aléatoires | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | aucune | aucun | aucun |

Les zéros sont bien réels et ne viennent pas d'un tracker mort. `torrent.ubuntu.com` a été scrapé deux fois pour les trois entrées Ubuntu, dans la même boucle. Il a répondu 22 puis 27 seeders pour 26.04.1, alors qu'il renvoyait un `d5:filesdee` vide pour les deux entrées sans seeders. Même chose pour `bt1.archive.org` et l'item Prelinger.

TorBox `checkcached` a été interrogé sur chaque hash avant qu'on ajoute quoi que ce soit. C'est la seule sonde de cache non destructive des trois. Il a répondu en cache pour les trois lignes en cache, et non en cache pour les six autres. C'est bien la répartition que les noms de cas annoncent.

### Cadence des sondages et plafonds {#poll-cadence-and-caps}

3 s for the first 2 minutes, then 15 s. 1 s for the cached case, because the whole lifecycle there can be over inside one normal poll. Cap 15 minutes per torrent for the campaign rather than the script default of 30. The shim's proposed default timeout is 10 minutes, and a torrent still moving at 15 is already past the only window that matters. Real-Debrid adds are spaced at least 20 s apart.

Each provider ran as its own process against its own output directory. That keeps the Real-Debrid add spacing honest inside one process and lets the three run at once.

---

## Real-Debrid

### Endpoints

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### Valeurs de statut observées {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

Non observé ici. `compressing` `virus` `error` `dead`. Ceux-ci nécessitent du contenu que cette campagne n'avait aucun moyen légitime de produire.

### Quels champs du protocole existent dans quel statut {#which-wire-fields-exist-in-which-status}

| Champ | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | oui | oui | oui | oui | oui |
| `progress` | 0 | 0 | **flottant en pourcentage**, de 0 à 100 | **repart de 0** et monte jusqu'à 100 | 100 |
| `seeders` | oui | **absent** | oui | **absent** | **absent** |
| `speed` | **absent** | **absent** | oui, en octets par seconde | oui, toujours 0 dans la capture | **absent** |
| `bytes` / `original_bytes` | 0 | taille réelle | taille réelle | taille réelle | taille réelle |
| `filename` | `"Magnet"` | nom réel | nom réel | nom réel | nom réel |
| `files` | `[]` | rempli | rempli | rempli | rempli |
| `links` | `[]` | `[]` | `[]` | se remplit pendant la phase | rempli |
| `ended` | absent | absent | absent | absent | présent |

Cela compte plus que le vocabulaire. Les champs apparaissent et disparaissent. Un mapper qui lit `speed` dans chaque état lit une clé absente la moitié du temps.

`progress` est un **float** et non un entier. La capture contient 0.4, 0.8 et 1.4 à côté de 100. Un détecteur de blocage qui arrondit au pourcentage entier considérera une release de 100 GB comme bloquée à 1 MB/s.

`progress` **recule exprès**. Il repasse à 0 quand le status passe à `uploading`, puis remonte jusqu'à 100. Un mouvement doit être défini comme un changement d'étape ou une hausse de progress, jamais comme un pourcentage monotone.

`seeders` disparaît au lieu de tomber à zéro quand le torrent quitte `downloading`. C'est aussi le cas de `speed`. Un mapper doit traiter une clé absente comme inconnue, et non comme zéro.

(Une traduction précédente a été rejetée : les spans de code ne correspondaient pas. Gardez la structure exactement.)

### Ce que chaque cas a fait {#what-each-case-did}

| Cas | Torrent | Transitions avec secondes depuis l'ajout | Verdict |
|---|---|---|---|
| en cache | Big Buck Bunny | `downloaded`@0.0 | terminé en 1.32 s de bout en bout |
| en cache | Sintel | `downloaded`@0.0 | terminé en 0.73 s |
| en cache | Ubuntu 26.04.1 | `downloaded`@0.0 | terminé en 0.32 s |
| pas en cache | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | déjà en cache sur ce compte |
| pas en cache | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | terminé. 3.71 GiB en 197 s |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | échec |
| sans seeders | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | terminé. Le cas ne s'est pas reproduit |
| sans seeders | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 et rien après | **plafonné à 907.6 s, toujours `downloading`**. C'est le profil de blocage |
| sans métadonnées | 40-hex aléatoire | `magnet_conversion`@0.0 `magnet_error`@317.9 | échec |

### La latence de l'ajout en cache {#the-cached-add-latency}

Voici le chiffre sur lequel repose le mode cached-only du shim.

| Torrent | addMagnet renvoie | selectFiles renvoie | premier `/torrents/info` | statut |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**Observé.** Un torrent en cache est `downloaded` dès la toute première lecture après `selectFiles`. Tout le coût synchrone tient en deux allers-retours. Il ne passe jamais par `queued` ni par `downloading`.

Un second essai a interrogé `/torrents/info` à 0,25 s, dans l'intervalle entre `addMagnet` et `selectFiles`, puis aussi après. C'est ce que fait `--rd-select-detail`, et ça confirme la forme.

| Torrent | Statut avant `selectFiles` | `selectFiles` | Première lecture après | addMagnet jusqu'à `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection` avec 3 fichiers listés et `links` vide | 204 à t+1,314 s | `downloaded` `progress` 100 `links` 1 | **1,535 s** |
| Sintel | `waiting_files_selection` avec 11 fichiers listés | 204 à t+0,627 s | `downloaded` `progress` 100 `links` 1 | **0,841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection` avec 1 fichier listé | 204 à t+0,219 s | `downloaded` `progress` 100 `links` 1 | **0,430 s** |

Donc la séquence complète d'un torrent en cache est `waiting_files_selection` puis `downloaded`, et rien entre les deux. La liste des fichiers est déjà là avant `selectFiles`. Ce que `selectFiles` remplit, c'est `links`.

**La fenêtre de sonde cached-only peut tenir en une seule interrogation.** De 0,43 s à 1,54 s de bout en bout sur trois torrents de 123 MiB, 264 MiB et 6,04 GiB. Une fenêtre de deux secondes avec une interrogation toutes les quarts de seconde est largement suffisante.

Face aux 100 s que Sonarr et Radarr accordent à un appel `torrents/add` (voir [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)), une fenêtre de sonde cached-only de quelques secondes ne coûte rien. Rien ne justifie de la régler à plusieurs dizaines de secondes.

### Particularités qu'un mappeur d'étapes doit gérer {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` répond 404 alors que le torrent est encore en `magnet_conversion`, et l'erreur est trompeuse.**
  Le corps est `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}` alors que
  `files=all` a bien été envoyé. Il n'y a tout simplement pas encore de fichiers à sélectionner. Ce n'est pas un
  échec de l'ajout, et le torrent reste actif. Les deux essais qui ont rencontré ce cas ont tenu 318 s de plus.
- **Le hash d'un tracker privé peut être rejeté immédiatement, et non après 318 s.** Le hash à l'origine du rapport
  qBittorrent du 2026-08-31 (un remux de CiNEPHiLES venant d'un indexeur UNIT3D, `45e1ec0d…`) a répondu `magnet_error`
  avec zéro fichier dès la première lecture après addMagnet, sans aucune fenêtre `magnet_conversion`, quelques
  secondes seulement après l'ajout. Que Real-Debrid ait reconnu le hash ou qu'il ait échoué tout de suite, le
  résultat observable est le même : un hash privé n'a pas d'essaim DHT, donc addMagnet ne peut jamais réussir pour
  lui, et selectFiles sur l'instance morte répond le 404 trompeur décrit plus haut.
- **`addTorrent` ne saute rien pour un contenu non mis en cache, mais tout saute pour un contenu mis en cache.** Un
  fichier `.torrent` envoyé pour un contenu que Real-Debrid ne possède pas (un Big Buck Bunny d'archive.org, seedé
  mais non mis en cache) est passé en `magnet_conversion` comme un simple magnet : les métadonnées du fichier ne
  sont pas utilisées pour la résolution. Un fichier mis en cache (un ISO d'Ubuntu) a répondu
  `waiting_files_selection` avec sa liste de fichiers dès la première lecture, a été sélectionné et est passé à
  `downloaded` en moins de deux secondes, sans jamais passer par `magnet_conversion`. L'intérêt de l'upload est donc
  la recherche immédiate hash→cache, ce qui permet d'ajouter la release d'un tracker privé dès que le contenu est
  en cache, et jamais de l'ajouter comme magnet.
- **La résolution des métadonnées abandonne après 318 s.** Deux essais indépendants sont passés de `magnet_conversion`
  à `magnet_error` à 317,9 s et 318,0 s. C'est la limite atteinte par un magnet sans pairs joignables. Le résultat
  est le même qu'il existe ou non un torrent pour ce hash.
- **`seeders` est faux pendant `magnet_conversion`.** Le hash aléatoire de 40 caractères hexadécimaux a affiché
  `seeders: 1` à 80,9 s. Aucun torrent n'existe pour lui.
- **`ended` sur un torrent mis en cache juste ajouté porte une ancienne date.** Les captures contiennent
  `2025-12-28` et `2026-07-28` pour des torrents ajoutés le 2026-08-30. C'est la date à laquelle Real-Debrid a
  obtenu le contenu, et non celle où cette instance a terminé. Ne calculez pas d'ancienneté à partir de cette valeur.
- **Un magnet sans pairs échoue pendant la résolution des métadonnées et n'atteint jamais le webseed.** Real-Debrid
  respecte bien les webseeds une fois qu'il possède le torrent, mais il ne peut pas obtenir le torrent depuis un
  magnet sans pairs. Un élément qui n'a qu'un webseed, ajouté comme magnet, finit donc en `magnet_error`. C'est une
  erreur de métadonnées et non une erreur de webseed, et depuis `/torrents/info` les deux cas se ressemblent.

## AllDebrid

### Endpoints

`v4` et `v4.1` ne sont pas interchangeables, et la différence a posé problème pendant cette campagne.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**L'envoi de fichier répond sous `files`, et non sous `magnets`.** Les champs sont les mêmes pour chaque entrée : `id`, `hash`, `name`, `ready`, et un `error` facultatif par entrée. Le flag `ready` ci-dessous est donc la réponse du cache dans les deux cas. En revanche, un décodeur écrit pour la réponse magnet lira une liste vide.

**Et le fichier est la seule forme sous laquelle AllDebrid peut décrire une release sans swarm.** Mesuré le 2026-09-01 sur le compte de test, avec deux torrents privés synthétiques de même forme dont les hashes n'ont jamais été vus dans aucun swarm. Envoyés comme fichiers, ils sont revenus avec leur vrai nom et leur vraie taille (`"name":"zurg.private.ad.probe","size":65536`), listés comme `In queue`, le compteur n'ayant pas encore démarré. Envoyé en simple hash `magnets[]`, la réponse était `"name":"noname","size":0`. AllDebrid a accepté le hash mais n'en savait rien. C'est exactement ce qui arrive à la release d'un tracker privé ajoutée par hash.

**`/v4/magnet/status` n'existe plus.** Avec ou sans id, il répond en HTTP 200 avec `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. `/v4/magnet/upload` et `/v4/magnet/delete` fonctionnent toujours. L'hypothèse du plan, selon laquelle l'endpoint de statut v4 pourrait être utilisé et v4.1 échantillonné une fois pour comparaison, est donc inversée. v4.1 est le seul endpoint de statut, et le harnais enregistre une lecture v4 par torrent afin que la capture apporte la preuve plutôt que l'affirmation.

L'authentification se fait avec `Authorization: Bearer <apikey>`. Aucun paramètre `agent` n'est nécessaire.

### Valeurs de statut observées {#status-values-observed-1}

| `statusCode` | `status` | Vu |
|---|---|---|
| 0 | `In queue` | oui |
| 1 | `Downloading` | oui |
| 2 | `Compressing / Moving` | **non** |
| 3 | `Uploading` | oui |
| 4 | `Ready` | oui |
| 5 et plus | les codes d'erreur | **non** |

### Quels champs du protocole existent dans quel statut {#which-wire-fields-exist-in-which-status-1}

| Champ | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | oui | oui | oui | oui |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"` jusqu'à l'arrivée des métadonnées | vrai nom une fois les métadonnées arrivées | vrai nom | vrai nom |
| `size` | 0 jusqu'à l'arrivée des métadonnées | vraie taille | vraie taille | vraie taille |
| `downloaded` | 0 | **la valeur de progression, en octets** | égal à `size` | **absent** |
| `downloadSpeed` | 0 | oui, en octets par seconde | 0 | **absent** |
| `seeders` | 0 | oui | 0 | **absent** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **la valeur de progression de cette phase** | **absent** |
| `processingPerc` | 0 | 0 | 0 | **absent** |
| `files` / `nbLinks` | absent | absent | absent | présent |
| `completionDate` | 0 | 0 | 0 | défini |

**Il n'y a nulle part de pourcentage.** Sur AllDebrid, la progression est `downloaded / size`, et ces deux valeurs sont des entiers en octets. `processingPerc` est resté à 0 dans tous les états, sur toutes les captures.

`Uploading` correspond à AllDebrid qui déplace le téléchargement terminé vers son propre stockage. Cette phase a son propre compteur de progression, dans `uploaded` et `uploadSpeed`, et son `downloadSpeed` reste à 0 pendant toute la phase. Une règle de détection de blocage qui ne surveille que `downloaded` considérera donc une phase `Uploading` saine comme bloquée.

### Ce que chaque cas a fait {#what-each-case-did-1}

| Cas | Torrent | `ready` à l'upload | Transitions avec les secondes depuis l'ajout | Résultat |
|---|---|---|---|---|
| en cache | Big Buck Bunny | true | `Ready`@0.0 | terminé en 0.11 s |
| en cache | Sintel | true | `Ready`@0.0 | terminé en 0.12 s |
| en cache | Ubuntu 26.04.1 | true | `Ready`@0.0 | terminé en 0.11 s |
| pas en cache | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | déjà en cache |
| pas en cache | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 avec chaque compteur à zéro jusqu'à 634.9 `Uploading`@650.1 `Ready`@876.9 | terminé en 877 s |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 et chaque compteur à zéro après ça | **plafonné à 907.8 s, toujours `Downloading`** |
| sans seeders | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 avec chaque compteur à zéro jusqu'à 589.6 `Uploading`@619.9 `Ready`@650.2 | terminé en 650 s |
| sans seeders | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 et chaque compteur à zéro après ça | **plafonné à 907.0 s, toujours `Downloading`** |
| sans métadonnées | 40 hex aléatoire | false | `In queue`@0.0 `Downloading`@9.4 et chaque compteur à zéro après ça | **plafonné à 907.4 s, toujours `Downloading`** |

Une exécution séparée sur Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) a capturé un cycle de vie complet non mis en cache, et elle sert de séquence de référence.

| Secondes | État | Ce qui a bougé |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` vaut `"noname"` et `size` vaut 0 |
| 2.2 | `Downloading` 1 version 2 | toujours pas de nom ni de taille |
| 4.3 | `Downloading` | `filename` et `size` se résolvent |
| 6.5 à 55.1 | `Downloading` | `downloaded` monte jusqu'à `size`. `downloadSpeed` atteint un pic autour de 110 MB/s. `seeders` passe de 8 à 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` tombe à 0. `uploadSpeed` et `uploaded` commencent à monter |
| 65.6 | `Ready` 4 | `files` et `nbLinks` apparaissent. Six champs de progression disparaissent |

3.72 GiB en 65.6 s.

### AllDebrid n'affiche aucune progression pendant qu'un job attend sa propre infrastructure {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

C'est la découverte qui change le plus la conception des délais, et il a fallu deux exécutions indépendantes pour y croire.

`Downloading` avec `statusCode` 1 apparaît quelques secondes après l'envoi. Pendant un moment après, AllDebrid affiche `downloaded` 0, `downloadSpeed` 0, `seeders` 0, `uploaded` 0, `uploadSpeed` 0 et `processingPerc` 0. Il remet aussi `size` à 0 et `filename` au info hash, même s'il avait déjà affiché les deux correctement.

| Exécution | Durée pendant laquelle tous les compteurs sont restés à zéro | Ce qui s'est passé ensuite |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 s**, de 12,5 s à 634,9 s | 3,71 GiB téléchargés en 15 s, puis `Uploading`, puis `Ready` à 876,9 s |
| ubuntu-16.04.6-desktop-i386 | **580 s**, de 9,4 s à 589,6 s | 1,56 GiB téléchargés en 30 s, puis `Uploading`, puis `Ready` à 650,2 s |

Les deux ont fini. Aucune n'a affiché le moindre octet de progression pendant les dix premières minutes.

**Un délai de dix minutes sans mouvement abandonnerait des tâches AllDebrid saines.** La valeur par défaut proposée pour `download_timeout_mins`, soit 10, tombe dans cette fenêtre dans les deux cas sur deux. Il faut soit que le délai soit plus long que ça, soit que AllDebrid en `Downloading` avec `size` à 0 soit traité comme sa propre étape, que l'horloge ne compte pas. Perdre le nom et la taille, c'est la façon qu'a AllDebrid de dire que la tâche est attribuée mais pas encore démarrée, et ce n'est pas un échec.

Une exécution qui a démarré tout de suite fait un bon contraste. Debian 13.3.0 arm64 DVD-1 est passé de `In queue` à de vrais compteurs d'octets en 6,5 s. L'attente est donc liée à une file d'attente, et non à un délai fixe.

### Le flag `ready` est une vraie réponse du cache {#the-ready-flag-is-a-real-cache-answer}

`ready` sur la réponse de `/v4/magnet/upload` valait true pour chaque hash que TorBox considérait aussi comme en cache, et false pour les deux que la campagne a téléchargés. AllDebrid n'a pas de sonde de cache séparée : ce flag est donc tout le signal de cache. zurg le transmet maintenant depuis les deux chemins d'ajout (celui du magnet et celui de l'envoi de fichier) sous la forme `MagnetResponse.Cached` avec `CacheKnown` défini, pour qu'un backend incapable de répondre ne soit jamais confondu avec un backend qui signale une absence en cache.

**Un `ready` à false signifie que le magnet est déjà ajouté.** Il n'existe aucun moyen de demander à AllDebrid si un hash est en cache sans l'ajouter. Un chemin cached-only sur AllDebrid doit donc supprimer le magnet manqué.

## TorBox

### Endpoints

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### Valeurs de statut observées {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing`, `checking` et `stalledDL` ne figurent **pas dans la table de traduction de zurg**
(`internal/torbox/types.go` `normalizeStatus`). Les trois tombent dans la branche par défaut et sont
signalés comme `downloading`.

`checking` correspond à l'attente des métadonnées chez TorBox, et non à la vérification d'un hash. Un
magnet dont l'essaim ne répond jamais passe à `metaDL`, puis à `checking`, et y reste. Le hash aléatoire
de 40 caractères hexadécimaux était encore en `checking` à la limite de 910 s, tout comme l'élément
Prelinger sans pair à 911 s. TorBox n'abandonne jamais, contrairement à Real-Debrid qui le fait à 318 s.

**Envoyer le `.torrent` évite complètement cette attente, et c'est toute la différence pour la version
d'un tracker privé.** Mesuré le 2026-09-01 sur le compte ci-dessus, le même torrent privé synthétique
envoyé des deux façons. Sous forme de hash : accepté avec un `torrent_id`, puis `checking` avec `name`
défini au hash brut, `size: -1`, `files: null` et `eta: 8640000`. TorBox cherche un essaim absent du
DHT, ce qu'il fera jusqu'à la limite sans rien signaler à ce sujet. Sous forme de fichier, sur
`POST /torrents/createtorrent` avec les octets dans une partie multipart `file` : relu trois secondes
plus tard avec le nom propre du torrent, sa taille réelle et `stalled (no seeds)`. C'est le même contenu
que personne ne possède, mais désormais décrit. L'étape est le point clé. `checking` avec `size: -1`
correspond à `StageResolvingMetadata`, ce qui signifie que le travail est en cours et qu'on ne peut rien
conclure ; `stalled (no
seeds)` correspond à `StageStalledNoPeers`, sur lequel l'endpoint qBittorrent peut agir. Une version en
cache est revenue `done` à 100 % avec sa liste de fichiers dans ces mêmes trois secondes. Le nom de la
partie est déterminant : un fichier envoyé sous un autre nom n'est pas du tout vu, et l'endpoint répond
`MISSING_REQUIRED_OPTION`, « You must provide either a file or magnet link ».

(Une traduction précédente a été rejetée : les segments de code diffèrent (` maps to `). Gardez la
structure exactement.)

### Quels champs du protocole existent dans quel statut {#which-wire-fields-exist-in-which-status-2}

TorBox envoie le même jeu de clés dans chaque état et ne change que les valeurs. C'est donc le plus facile à lire des trois. Ce sont les valeurs qui portent le sens.

| État | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | minuscule | 8640000 | réel |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | réel |
| `downloading` | false puis **true** | false | false | true | fraction | secondes | réel |
| `processing` | **true** | **false** | false | true | 1 | secondes | réel |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | réel |
| `uploading` | true | **true** | true | true | 1 | 0 | réel |
| `cached` | true | true | true | false | 1 | 0 | réel |

Noms des champs. Le plan listait tous ces noms comme non vérifiés.

| Quoi | Champ TorBox | Forme |
|---|---|---|
| progression | `progress` | **fraction d'un**, pas un pourcentage. `0.0793719` |
| semeurs | `seeds` | entier |
| leechers | `peers` | entier |
| débit de téléchargement | `download_speed` | octets par seconde |
| débit d'envoi | `upload_speed` | octets par seconde |
| eta | `eta` | secondes. `8640000` est la valeur de remplacement pour « inconnu » |
| octets récupérés | `total_downloaded` | entier |
| santé de l'essaim | `availability` | flottant. Passe à **-1** dans `uploading (no peers)` |
| où se trouvent les données | `download_path` | null tant que les données ne sont pas présentes |

`8640000` correspond à 100 jours. C'est la façon qu'a TorBox de dire qu'il ne sait pas. C'est aussi la même constante que le shim de zurg donne aujourd'hui à Sonarr quand il n'a rien à signaler.

### Ce que chaque cas a fait {#what-each-case-did-2}

| Cas | Torrent | `checkcached` | Transitions avec les secondes depuis l'ajout | Verdict |
|---|---|---|---|---|
| en cache | Big Buck Bunny | true | `cached`@0.0 | terminé en 0.83 s |
| en cache | Sintel | true | `cached`@0.0 | terminé en 0.94 s |
| en cache | Ubuntu 26.04.1 | true | `cached`@0.0 | terminé en 0.69 s |
| pas en cache | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 puis **disparu**@48.6 | supprimé par l'autre zurg à 86.7 % |
| pas en cache | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 puis **disparu**@86.7 | supprimé par l'autre zurg |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 et jamais rien d'autre | **plafonné à 911.3 s dans `checking`**. TorBox n'a pas utilisé le webseed |
| sans seeds | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 puis **disparu**@200.4 | supprimé par l'autre zurg à `processing` |
| sans seeds | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 puis **disparu**@462.3 | supprimé par l'autre zurg à 91.9 % |
| sans meta | 40 caractères hexa aléatoires | false | `metaDL`@0.0 `checking`@10.2 et jamais rien d'autre | **plafonné à 910.3 s dans `checking`** |

Une exécution séparée avec un poll de 0.5 s sur Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`) a tenu assez longtemps pour atteindre done et sert de séquence de référence.

| Secondes | État | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB en 64.4 s.

Relisez les trois dernières lignes deux fois. TorBox met `download_finished` à true et `progress` à 1 environ dix secondes **avant** que les données soient présentes. Puis il repasse à `downloading` avec une valeur de progress inférieure à celle qu'il venait d'annoncer. Sur un téléchargement sain, `progress` et `download_state` reculent tous les deux.

---

(Une traduction précédente a été rejetée : les portions de code ne correspondaient pas. Gardez la structure exactement.)

## La table des étapes {#the-stage-table}

L'énumération des étapes que le shim utilisera est `resolving-metadata` `queued` `downloading` `stalled-no-peers`
`finalizing` `done` `failed` et la chaîne vide pour inconnu.

### Real-Debrid

| `status` brut | Étape | Source |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **observé**. `bytes` à 0, `files` vide et `filename` vaut littéralement `"Magnet"` |
| `waiting_files_selection` | `queued` | **observé** avec `--rd-select-detail`. Les fichiers sont déjà listés. `links` est vide |
| `queued` | `queued` | **observé**. La vraie taille et le vrai nom sont déjà connus. Pas de `seeders` ni de `speed` |
| `downloading` | `downloading` | **observé** |
| `downloading` avec `seeders` à 0 | `stalled-no-peers` | **observé**. 904 s avec `progress` à 0, `seeders` à 0 et `speed` à 0 sur 92 interrogations |
| `compressing` | `finalizing` | **déduit**. Jamais vu |
| `uploading` | `finalizing` | **observé**. La progression repart de 0 et `seeders` disparaît |
| `downloaded` | `done` | **observé** |
| `magnet_error` | `failed` | **observé** après 318 s dans `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **déduit**. Jamais vu |

### AllDebrid

| `statusCode` | Étape | Base |
|---|---|---|
| 0 `In queue` | `queued` | **observé**. Dure quelques secondes. `filename` peut encore valoir `"noname"` et `size` 0 |
| 1 `Downloading` avec `size` 0 | `queued` | **observé**. Ni `downloading` ni `stalled-no-peers`. AllDebrid a pris la tâche sans la démarrer. Maintenu pendant 622 s et 580 s dans deux essais, qui se sont ensuite terminés |
| 1 `Downloading` avec une vraie `size` | `downloading` | **observé** |
| 1 `Downloading` avec `seeders` 0 et `downloaded` figé | `stalled-no-peers` | **non observé et non déductible de façon sûre**. Voir ci-dessous |
| 2 `Compressing / Moving` | `finalizing` | **déduit**. Jamais vu |
| 3 `Uploading` | `finalizing` | **observé**. Ici, `uploaded` et `uploadSpeed` portent la progression et `downloadSpeed` vaut 0 |
| 4 `Ready` | `done` | **observé** |
| 5 et plus | `failed` | **déduit**. Jamais vu |

**AllDebrid n'a aucune forme de blocage observable.** Une tâche qu'AllDebrid a mise en file et une tâche sur laquelle AllDebrid ne peut pas progresser ont exactement la même apparence sur le réseau.
Les deux ont `statusCode` 1, `size` 0 et tous les compteurs à zéro. L'élément Prelinger est resté dans exactement cette forme pendant toute la limite de 907.8 s, et deux autres torrents y sont restés chacun dix minutes avant de se terminer.
Donc rien dans la réponse d'AllDebrid ne permet de les distinguer, et un verdict de blocage sur AllDebrid ne peut venir que d'une horloge.

### TorBox

| `download_state` brut | Étape | Base |
|---|---|---|
| `metaDL` | `resolving-metadata` | **observé**. `size` à 0 et `name` égal au hash |
| `checking` | `resolving-metadata` | **observé**. `size` à **-1** pendant toute sa durée. C'est là que TorBox attend le torrent, et non une vérification du hash. Absent de la table de zurg pour l'instant |
| `stalledDL` | `stalled-no-peers` | **observé**. Absent de la table de zurg pour l'instant |
| `stalled (no seeds)` | `stalled-no-peers` | **observé**. Le nom exagère. Deux captures avaient `seeds` à 1 et 2 pendant cet état. zurg le mappe sur `queued` pour l'instant |
| `downloading` | `downloading` | **observé** |
| `processing` | `finalizing` | **observé**. Absent de la table de zurg pour l'instant |
| `uploading (no peers)` | `finalizing` | **observé** quand `download_present` vaut false |
| `uploading` | `done` | **observé** quand `download_present` vaut true |
| `cached` `completed` `seeding` | `done` | `cached` **observé**. Les deux autres **déduits** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **déduit**. Aucun vu |

**La paire `download_finished` et `download_present` ne remplace pas la chaîne d'état.** Les deux
`processing`, `uploading (no peers)` et une partie de `downloading` ont `download_finished: true` avec
`download_present: false`. Cette combinaison correspond à une phase de finalisation normale et non à un torrent mort. Voir
le piège ci-dessous.

---

## Ce qui n'a pas pu être mesuré {#what-could-not-be-measured}

- **Le cas sans seed s'est reproduit sur un candidat sur deux.** Les deux avaient zéro pair sur le tracker.
  ubuntu-16.04.6-desktop-i386 a quand même été téléchargé sur les trois fournisseurs, car le DHT a fourni des pairs que le tracker ne connaissait pas. ubuntu-24.04-beta-live-server-s390x est resté bloqué sur Real-Debrid pendant tout le plafond et correspond à l'observation de blocage ci-dessus. Un zéro sur un scrape de tracker est un indicateur peu fiable. Gardez deux candidats dans le cas. Real-Debrid a quand même fourni les métadonnées des deux et a correctement renvoyé `bytes` et `filename` dès la toute première lecture `queued`.
- **Le statut `compressing` de Real-Debrid n'a jamais été observé.** Chaque exécution terminée est passée directement de `downloading` à `uploading`.
- **Le code de statut 2 d'AllDebrid n'a jamais été observé.** Chaque capture est passée directement de 1 à 3.
- **Aucun fournisseur n'a été poussé dans son propre vocabulaire d'erreurs.** Les statuts `error`, `virus` et `dead` de Real-Debrid, tous les codes AllDebrid supérieurs à 4 et tous les états d'échec de TorBox n'ont pas été testés. Pour les provoquer, il faudrait un contenu bloqué, infecté ou expiré, et non un ISO FOSS.
- **TorBox a rarement pu être suivi jusqu'au bout.** Quatre torrents de la campagne et un torrent de suivi ont été supprimés en pleine téléchargement par l'autre zurg du compte. Voir le risque décrit ci-dessous. Seule une image de 754 MiB a fini de se télécharger avant que ce processus n'interroge à nouveau le service.

## Dangers découverts en chemin {#hazards-found-on-the-way}

### Un second zurg sur le compte TorBox supprime des téléchargements sains {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

Une autre instance de zurg utilise le même compte TorBox. Sa config contient

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**Cinq** torrents de test ont été supprimés alors qu'ils se téléchargeaient normalement. C'est **observé** des deux côtés. Le banc de test a vu chaque torrent disparaître, et le journal de l'autre instance indique pourquoi.

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

Les cinq sont `86695315` `86695708` `86697191` `86702627` `86704212`. Tous portaient la même raison. Aucun n'était cassé.

Le mécanisme est la deuxième règle de `normalizeStatus` dans `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

Cette combinaison correspond à une phase de finalisation normale chez TorBox. La capture à 0,5 s permet de chiffrer ça. Sur une image de 754 MiB, la fenêtre entre le passage de `download_finished` à vrai et celui de `download_present` à vrai était de **9,6 secondes**. Sur une image de 3,7 GiB, elle était d'au moins 17 s, et le passage de nettoyage est tombé dedans. L'autre instance de zurg interroge la bibliothèque environ toutes les 15 s. Qu'un téléchargement TorBox sain survive à sa propre fin relève presque du pile ou face.

Trois conséquences. Un téléchargement TorBox qu'un utilisateur voit se terminer dans l'interface TorBox peut disparaître de sa bibliothèque zurg. `delete_error_torrents` est documenté comme supprimant les torrents que le fournisseur déclare cassés, et ici il supprime ceux que le fournisseur déclare sains. Et toute mesure de TorBox sur ce compte est en course contre ce nettoyage.

**Non corrigé ici.** La phase 0 mesure. La correction revient au travail sur les étapes. Là-bas, `download_finished && !download_present` devient `finalizing` au lieu de `failed`.

### Un second zurg sur le compte AllDebrid s'en est sorti sans dégâts {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

La clé AllDebrid utilisée pour cette campagne était aussi chargée par une autre instance de zurg, avec les mêmes trois
paramètres de balayage que pour TorBox.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

Aucune sonde AllDebrid n'a été supprimée. La raison se trouve dans le code et non dans la chance. `normalizeStatus` dans
`internal/alldebrid/types.go` ne fait correspondre à `error` que les codes de statut supérieurs ou égaux à 5 et n'a aucune règle structurelle du genre `download_finished && !download_present`. Un téléchargement AllDebrid sain ne peut donc jamais apparaître comme cassé. Le bug TorBox ne vient que de cette règle supplémentaire, et non d'un balayage en général.

Real-Debrid fait figure d'exception. Aucune autre instance de zurg n'était chargée avec le compte de test. Rien ne le balayait et rien n'a interféré.

### TorBox répond HTTP 500 à une suppression d'un id inconnu {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` répond de la même façon. Un torrent qui n'existe plus est donc impossible à distinguer d'une panne TorBox à partir du seul code de statut. zurg l'affiche comme `account temporarily unavailable`. Le journal de l'autre instance montre qu'elle réessaie la suppression d'un id déjà supprimé toutes les 15 s. Le harnais contourne le problème en interrogeant `mylist` après un échec de suppression et en considérant qu'un torrent disparu est bien supprimé.

### Le throttling de Real-Debrid n'est pas apparu {#real-debrid-throttling-did-not-appear}

Neuf ajouts espacés de 20 s n'ont produit aucun 451 et aucun 429 sur toute la campagne. Cela correspond à la note du `CLAUDE.md` à la racine, selon laquelle 6 ajouts espacés de 10 s ont donné 0/6, et les mêmes 6 ajouts espacés de 20 s ont donné 6/6. Le plancher de 20 s fait vraiment son travail et ce n'est pas une superstition.

---

## Relancer la campagne {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Lance-le depuis une machine avec une sortie résidentielle. AllDebrid répond `NO_SERVER` aux IP de datacenter.

L'étape 6 n'est pas facultative, et l'étape 3 est ce qui lui donne un sens. Après la campagne du 2026-08-30, aucun des 34 identifiants d'instance que le harnais avait réservés ne subsistait sur les trois comptes. Il ne restait pas non plus une seule des neuf hachages de sonde.

Avant de toucher à TorBox, vérifie si une autre instance de zurg utilise le même compte, lis ses réglages de balayage et attends-toi au balayage décrit ci-dessus.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Ne le modifie jamais. Une sonde qui disparaît en cours d'exécution est une donnée.
