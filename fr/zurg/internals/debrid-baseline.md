# La référence debrid {#the-debrid-baseline}

Ce que coûte zurg et sa vitesse sur le chemin **debrid**, avec Real-Debrid, AllDebrid
et TorBox. Il n'y a pas de concurrent ici. Le challenger est une version ultérieure de zurg, et ce fichier, c'est ce qu'il doit battre.

- **Build testé :** `23869fa4` (`2026.08.18.0140-nightly-48-g23869fa4`)
- **Mesuré :** 2026-08-19, sur `zen` (2 cores, 7.6 GB, Ubuntu 22.04)
- **Banc de test :** `scripts/dbench/`, déployé dans `~/dbench` sur zen

## Comment la lire {#how-to-read-it}

Les trois fournisseurs ne sont pas non plus trois concurrents. Leurs bibliothèques diffèrent de deux ordres de grandeur : 3416 torrents sur Real-Debrid, 479 sur TorBox, 14 sur AllDebrid. Un temps de build à froid en valeur absolue dit donc plus de choses sur le compte que sur zurg. Chaque chiffre qui dépend de la taille est donc aussi donné par torrent. Et la comparaison qui compte vraiment est toujours **ce build contre le suivant sur le même compte**.

Ce qui est vraiment comparable d'un fournisseur à l'autre, c'est la *forme* du coût : combien d'appels API un backend fait par torrent, s'il paie ou non la vérification des liens, et si son poll de changements passe par une page ou par un token.

## Configuration

Chaque instance ne fait tourner qu'un seul fournisseur, sur son propre port, avec son propre dossier de données. Les écarts par rapport aux valeurs par défaut livrées ne concernent que les exigences d'isolation :

| Réglage | Banc | Pourquoi |
|---|---|---|
| `host` / `port` | `127.0.0.1`, 9991-9994 | quatre instances sur un même hôte |
| `providers` | un par instance | attribuer le coût à un backend |
| `rclone_enabled` | `false` | mesuré via HTTP, jamais via FUSE |
| `directories` | un seul `all`, sans filtres | le coût du listing devient fonction de la taille de la bibliothèque |
| `enable_repair` | `false` | Un autre zurg était chargé avec le même compte TorBox, et une seule instance peut réparer un compte |

Tout le reste est laissé à la valeur par défaut livrée, *volontairement*, y compris deux réglages qui faussent beaucoup les chiffres et qui sont eux-mêmes des constats :

- `log_level: DEBUG` — la valeur par défaut livrée (`pkg/logutil/factory.go`).
- `torrents_rate_limit_per_minute: 75` — la valeur par défaut livrée, et la contrainte limitante pour un build à froid sur Real-Debrid.

## Corpus

Douze versions, les **mêmes infohashes sur les trois comptes**, donc une différence entre fournisseurs vient bien du fournisseur et non du fichier. Les tailles vont d'un épisode de 1.5 GB à un pack remux de 334 GB ; les formes vont des films en fichier unique aux packs de saisons, en passant par un pack de série de 349 fichiers. L'entrée 0 — `The Shawshank Redemption (1994) DS4K`, 7.31 GB, un seul fichier — sert de sujet de streaming pour les phases de latence et de débit.

L'assemblage est la partie délicate et mérite d'être noté. Le cache de TorBox chevauche la bibliothèque Real-Debrid à environ 2 % (3 succès sur 136 sondes), donc le corpus doit être alimenté depuis le côté TorBox plutôt que depuis celui de Real-Debrid. AllDebrid n'avait rien en cache et a accepté les magnets instantanément, 14 sur 16. Real-Debrid a demandé 20 à 45 s entre les ajouts à cause de la limitation 451, et en a refusé deux : l'un est le blocage de nom déterministe documenté (`Supergirl…WEB-DL…`, refusé dès la première tentative propre après une pause de trois minutes), l'autre est resté limité.

## Mesurer le coût des API {#measuring-api-cost}

zurg ne tient pas de compteur des requêtes sortantes, et `log_requests` ignore volontairement deux
points de terminaison de Real-Debrid, `torrents/activeCount` et `torrents?limit=1&…`, qui
forment à eux deux toute l'interrogation de détection des changements. Compter à partir du journal
reviendrait donc à indiquer que le coût de Real-Debrid à l'arrêt est nul.

Le comptage se fait donc à l'extérieur du processus. mitmproxy termine le TLS, un addon écrit
une ligne JSONL par requête, et l'instance est lancée avec `HTTPS_PROXY` et
`SSL_CERT_FILE` pointant vers l'autorité de certification interceptrice. Le chargeur x509 de Go
respecte `SSL_CERT_FILE`, donc la confiance reste limitée à ce seul processus et rien
sur l'hôte n'est modifié. Les requêtes sont classées `api`, `nettest`, `content` ou `other`.

Le proxy se trouve dans le chemin des requêtes, donc il n'est utilisé que pour les phases de coût d'API ;
les phases de chronométrage passent en direct. Sur TorBox, où tout le build tient en quatre appels,
une exécution via le proxy et une exécution directe ont donné 3,0 s et 4,0 s. À cette échelle,
le proxy se perd dans le bruit de mesure.

## Résultats {#results}

All numbers from build `23869fa4` on zen, 2026-08-19. Latency and throughput come
from one interleaved run over the same 7.31 GB file — same infohash on all three
accounts, and `ffprobe` reports the identical 8552.574 s duration through each, so
the content really is byte-identical.

### Construction de la bibliothèque à froid {#cold-library-build}

De caches vides à une bibliothèque compilée. C'est le seul chiffre qui ne se compare pas d'un fournisseur à l'autre : les comptes diffèrent de deux ordres de grandeur. Il faut donc regarder les colonnes par torrent.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Torrents | 3,316 | 14 | 479 |
| Temps jusqu'à la bibliothèque compilée | **1,774 s** | 1.0 s | 3.0 s |
| Secondes par torrent | 0.535 | 0.071 | 0.006 |
| Requêtes API | **7,442** | 7 | 4 |
| Requêtes API par torrent | **2.24** | 0.50 | 0.008 |
| Réponses non-2xx | **756 (10.2%)** | 0 | 0 |
| Octets reçus de l'API | 2.87 MB | 27.9 KB | 298 KB |
| Requêtes de test réseau au démarrage | 88 | 88 | 88 |
| Peak RSS | 77 MB | 26 MB | 52 MB |
| Secondes CPU | 17.5 | 0.04 | 0.5 |

Les 7,442 appels de Real-Debrid se répartissent comme suit : 3,414 `torrents/info`, soit un par torrent, impossible à éviter sans `ListIncludesFiles`, et **3,992 `unrestrict/link`**, qui correspondent à la vérification proactive des liens. C'est le seul backend avec `StoredLinksCanRot: true`, donc le seul à payer ce coût. TorBox répond à tout le scan avec un seul `mylist`, ce que permet justement `ListIncludesFiles`.

Le build Real-Debrid a été lancé deux fois, et les deux résultats sont assez proches pour qu'une future amélioration du build ne soit pas due au hasard :

| | run 1 | run 2 |
|---|---|---|
| Temps jusqu'à la bibliothèque compilée | 1,774.5 s | 1,759.5 s |
| Requêtes API | 7,442 | 7,391 |
| `unrestrict/link` | 3,992 | 3,933 |
| Non-2xx | 756 | 699 |
| Secondes CPU | 17.5 | 16.1 |

#### Quels sont les échecs {#what-the-failures-are}

Le deuxième run a conservé son journal de flux, donc les 699 erreurs ont une répartition :

| Statut | Nombre | Endpoint |
|---|---|---|
| 429 | 589 | `unrestrict/link` |
| 503 | 85 | `unrestrict/link` |
| 404 | **22** | `downloads/delete/{id}` |
| 451 | 3 | `unrestrict/link` |

Ce sont deux problèmes distincts, et aucun des deux n'est « le fournisseur était instable ».

- **589 refus pour dépassement de limite de requêtes**, tous sur `unrestrict/link`. `api_rate_limit_per_minute` vaut 250 par défaut et ne maintient pas unrestrict dans ce que Real-Debrid autorise réellement. Donc environ 8 % du build à froid se résume à des refus et des nouvelles tentatives.
- **22 appels `downloads/delete` sur 23 ont renvoyé 404.** Le nettoyage censé équilibrer 3 992 unrestricts n'est pas seulement rare : il échoue à chaque fois. Il supprime des ids qui n'existent pas. Chaque unrestrict crée une entrée persistante dans la liste des téléchargements du compte, et après ces scans le compte de test en comptait **12 469**.

Un chiffre a changé entre les deux runs et n'est pas encore expliqué : les sondes HEAD vers `*.download.real-debrid.com` étaient au nombre de 88 dans le premier build et de **3 426** dans le second (environ une par torrent). Cela coïncide avec la croissance de la liste des téléchargements, et le second run a aussi appelé `/downloads` huit fois contre une seule pour le premier. Mais il s'agit d'une corrélation, pas d'une cause. Il faut le clarifier avant de l'optimiser.

### Redémarrage à chaud {#warm-restart}

Le coût à froid n'est vraiment qu'une seule fois.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Temps jusqu'à la compilation | 4.0 s | 1.0 s | 2.0 s |
| Requêtes API | 17 | 6 | 4 |
| Requêtes de test réseau | 8 | 0 | 0 |
| Pic de RSS | 77 MB | 27 MB | 39 MB |

1 774 s deviennent 4.0 s, et 7 442 appels deviennent 17.

### État stable au repos {#idle-steady-state}

Dix minutes d'une bibliothèque chargée sans rien faire. Le classement dépend de ce que chaque backend peut demander à moindre coût, et c'est la meilleure illustration de la raison d'être de `LibraryFingerprinter`.

| | Appels API/min | Octets API/min | CPU s / 10 min | Peak RSS | Ce qu'il envoie |
|---|---|---|---|---|---|
| AllDebrid | **4.0** | **867** | 0.20 | 28 MB | un delta Live Mode par interrogation, vide si rien n'a changé |
| TorBox | 7.9 | 43.6 KB | 0.33 | 53 MB | parcourt `mylist` : pas de flux de deltas, pas de validateurs de cache |
| Real-Debrid | 11.4 | 59.8 KB | 0.43 | 85 MB | `torrents?limit=1` + `activeCount`, plus `/downloads` |

Real-Debrid consacre 32 de ses 114 appels à relister `/downloads`, la même liste qui avait grossi à 12 469 entrées pendant le build à froid.

Ce tableau est aussi la raison pour laquelle le compte passe par un proxy plutôt que par `log_requests`. 80 des 114 appels inactifs de Real-Debrid visent les deux endpoints que `ShouldSkipLogging` masque. Le journal aurait donc affiché un coût à peu près nul pour cette phase d'inactivité.

### Listing

Nulla che rallenti, con nessuna dimensione di libreria.

| | Real-Debrid (3.312) | AllDebrid (14) | TorBox (479) |
|---|---|---|---|
| PROPFIND di tutta la libreria, Depth 1 | 26 ms / 1,17 MB | 1 ms / 5,1 KB | 7 ms / 172 KB |
| Indice HTML | 14 ms / 645 KB | 1 ms / 2,4 KB | 3 ms / 90 KB |
| PROPFIND di una release, Depth 1 | 1 ms | 11 ms | 3 ms |

### Appuyer sur play {#press-play}

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Ouverture à froid, 1 Mo | 1.294 s | **0.476 s** | 0.565 s |
| Temps jusqu'au premier octet, 64 Mo | **0.158 s** | 0.203 s | 0.208 s |
| Scrub, médiane sur 8 | 0.343 s | **0.259 s** | 0.356 s |
| Relecture à chaud, 64 Mo | 2.065 s | 2.163 s | **1.960 s** |
| ffprobe | 1.98 s | 1.34 s | **0.99 s** |
| RSS | 75 Mo | **30 Mo** | 50 Mo |

Un fichier de 7.31 Go, chaque lecture sur une instance fraîchement démarrée.

**La relecture à chaud est aussi lente que la lecture à froid.** Sur le chemin Usenet, une nouvelle lecture revient en 0.05-0.17 s depuis le cache LRU de 512 Mo. Ici, elle coûte un téléchargement complet, parce que le chemin debrid fait passer les données par le CDN en proxy et ne met rien en cache. Avec `rclone_enabled: false`, c'est zurg seul qui gère la lecture. Dans une installation normale, le cache VFS de rclone absorbe ce coût, mais en tant que caractéristique de zurg lui-même, il n'existe aucun chemin à chaud.

### Débit {#throughput}

256 Mo de lectures séquentielles, trois répétitions, ordre alterné entre les répétitions.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Moyenne Mo/s | 25.75 | 27.21 | **35.96** |
| Min-max Mo/s | 20.09-29.57 | 17.52-32.21 | **34.31-37.57** |
| CPU s par Go | 7.8 | **5.3** | 7.9 |
| TTFB médian | 1.023 s | **0.267 s** | 0.489 s |
| RSS maximum | 88 Mo | **29 Mo** | 55 Mo |
| Lectures terminées | 3/3 | 3/3 | 3/3 |

TorBox est à la fois le plus rapide et de loin le plus stable ; les deux autres varient de 40 % entre
les répétitions. Le TTFB médian de Real-Debrid sous charge est quatre fois supérieur à celui d'AllDebrid.

### Où part vraiment l'ouverture à froid {#where-cold-open-actually-goes}

`apiref.py` mesure la part du fournisseur, c'est-à-dire l'appel qui transforme un fichier stocké en URL lisible, puis le premier octet reçu de cette URL, sans zurg dans le chemin. Il a été lancé deux fois. La première exécution est antérieure au correctif AllDebrid, donc cette ligne n'a qu'un seul échantillon.

| | résolution | CDN TTFB | total fournisseur | ouverture à froid zurg | part de zurg |
|---|---|---|---|---|---|
| Real-Debrid, exécution 1 | 0.133 s | 0.267 s | 0.400 s | 1.294 s | **0.89 s** |
| Real-Debrid, exécution 2 | 0.157 s | 0.383 s | 0.540 s | 1.294 s | **0.75 s** |
| AllDebrid | 0.139 s | 0.333 s | 0.472 s | 0.476 s | 0.00 s |
| TorBox, exécution 1 | 0.260 s | 0.277 s | 0.537 s | 0.565 s | 0.03 s |
| TorBox, exécution 2 | 0.270 s | 0.381 s | 0.651 s | 0.565 s | ~0 |

Les chiffres du fournisseur et ceux de zurg ne sont pas pris au même moment, donc la soustraction est indicative et pas exacte. La tendance se confirme dans les deux exécutions : AllDebrid et TorBox n'ajoutent quasiment rien au coût propre du fournisseur, alors que Real-Debrid ajoute entre 0.75 et 0.89 s. C'est l'écart le plus évident sur lequel travailler.

### Les trois fournisseurs dans une seule instance {#all-three-providers-in-one-instance}

| | Real-Debrid seul | Les trois fusionnés |
|---|---|---|
| Torrents vus | 3,316 | 3,781 |
| Releases uniques | 3,318 | 3,778 |
| Temps jusqu'à compiled | 1,774 s | 1,775 s |
| Requêtes API | 7,442 | 7,491 |
| Peak RSS | 77 MB | 82 MB |
| PROPFIND sur toute la bibliothèque | 26 ms / 1.17 MB | 23 ms / 1.34 MB |

L'instance fusionnée gère tous les comptes en même temps,
et le corpus est volontairement réparti sur les trois,
donc elle teste le cas où une même release est présente sur plusieurs comptes.

Ajouter TorBox et AllDebrid à une instance Real-Debrid ne coûte presque rien :
465 torrents de plus pour 49 appels API de plus et 5 MB de RSS, et aucun temps mesurable.
La fusion est bien réelle : 3,809 torrents répartis sur les trois comptes deviennent 3,781 ici,
le corpus passant de trois copies à une seule.

### Détection des ajouts et suppressions {#add-and-delete-detection}

Combien de temps s'écoule entre un changement chez le fournisseur et la mise à jour du point de montage.

| | Delete detected | Add detected |
|---|---|---|
| Real-Debrid | 18.7 s | 12.7 s |
| AllDebrid | 16.5 s | 14.4 s |

Les deux sont couverts par un seul cycle de `check_for_changes_every_secs` plus un rafraîchissement, donc aucun des deux n'attend `library_resync_every_mins`. TorBox n'a pas été testé : la release de sonde reste en permanence sur ce compte, et la supprimer n'est pas réversible sans un nouvel ajout qui pourrait ne pas être en cache.

### Panne du fournisseur, CDN opérationnel {#provider-outage-cdn-up}

`ca/outage.py` fait renvoyer un 503 à chaque appel API du fournisseur pendant que les requêtes de contenu passent, puis zurg est démarré pendant cette panne.

| | Lecture avant | Bibliothèque compilée pendant la panne | Lecture pendant la panne |
|---|---|---|---|
| Real-Debrid | 206, 1.60 s | jamais (180 s) | délai dépassé à 120 s |
| AllDebrid | 206, 0.44 s | jamais (180 s) | délai dépassé à 120 s |
| TorBox | 206, 1.53 s | jamais (180 s) | 400 en 0.035 s |

**Démarrer zurg alors que son fournisseur est en panne produit un montage vide.** C'est le scénario qui compte vraiment en exploitation, quand un hôte redémarre pendant une période de 503 de Real-Debrid. C'est exactement la condition qui a détruit des dizaines de milliers d'éléments Plex sur `fun` en août : un montage momentanément vide pendant une analyse est interprété comme « tous les fichiers ont été supprimés ». La protection contre ça se trouve dans Plex (`autoEmptyTrash 0`), pas dans zurg.

Real-Debrid et AllDebrid font en plus attendre le lecteur jusqu'à expiration de son propre délai au lieu d'échouer rapidement. TorBox répond en 35 ms.

### Un 503 passager laisse des releases sous forme de dossiers vides {#a-transient-503-leaves-releases-as-empty-folders}

Le défaut le plus clair de cette série est venu par hasard.

Sur les 3,316 torrents d'un build à froid Real-Debrid, **85 réponses étaient en 503** et **84 torrents ont fini en `broken_torrent`**. Une release dans cet état reste listée dans le montage, mais son dossier est **vide**. Je l'ai vérifié avec PROPFIND sur deux d'entre elles : elles avaient 10 et 3 fichiers sélectionnés dans leur enregistrement, et n'en servaient aucun.

Ça ne se règle pas tout seul. Le banc tourne avec `enable_repair: false`, et ces releases étaient toujours cassées plus d'une heure et plusieurs redémarrages plus tard.

Avec la réparation activée (le réglage par défaut livré), elle finit par passer sur elles, mais lentement. Avec une passe lancée à la main :

| Temps écoulé | Cassées | En réparation |
|---|---|---|
| 0 min | 85 | 0 |
| ~2 min | 77 | 2 |
| ~15 min | 73 | 4 |

Douze releases en un quart d'heure, et le rythme ralentit après les premières minutes. À ce rythme, il faut plus d'une heure pour nettoyer la casse d'un seul build à froid, et chaque release non traitée reste un dossier vide pendant tout ce temps.

La gravité dépend donc d'un réglage :

- Avec la réparation activée (par défaut), un 503 pendant un scan coûte ses fichiers à une release jusqu'à ce qu'une passe de réparation arrive jusqu'à elle, soit environ une heure pour une bibliothèque complète.
- Avec la réparation désactivée, la release reste un dossier vide indéfiniment.

TorBox a une version encore plus gênante. Il renvoie `StoredLinksCanRot: false`, donc le rafraîchissement ne revérifie jamais ses liens. Aucun chemin ne peut sortir une release de l'état cassé sans réparation. La seule release TorBox marquée cassée pendant le test de panne l'était encore 68 minutes et plusieurs redémarrages plus tard, alors que son fournisseur la signalait comme `cached`, `download_present`, avec un fichier, 7.31 GB.

### Intégrité de lecture {#read-integrity}

Une lecture AllDebrid lors du premier test de débit a renvoyé 263 798 425 octets pour une plage de 268 435 456 octets, avec un 206 et aucune erreur. Elle **ne s'est pas reproduite** : huit répétitions sur Real-Debrid et huit sur AllDebrid ont renvoyé la plage complète à chaque fois. Noté comme un cas isolé plutôt que comme un bug, mais à surveiller.

## Sous la charge de Plex {#under-plexs-load}

Tout ce qui précède concerne un seul lecteur à la fois, ce qui n'est pas la façon dont se comporte un serveur multimédia.
Plex analyse — des milliers de fichiers, un peu de chacun — et Plex diffuse, et les deux se chevauchent. Ces phases mesurent le montage dans les deux cas.

**Lisez les chiffres globaux comme une propriété de zen, et non de zurg.** Chaque cible plafonne à 73-78 Mo/s, quel que soit le fournisseur et quel que soit le mode, ce qui correspond au lien de l'hôte. Ce qui se généralise, ce sont les *taux de réussite* et les formes d'échec propres à chaque fournisseur ; le plafond, lui, est local.

### Plusieurs lecteurs, des fichiers différents, un seul fournisseur {#multiple-readers-different-files-one-provider}

96 Mo par flux, fichiers distincts.

| flux | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 1 | 44.8 | 52.1 | 45.6 | 51.8 |
| 2 | 72.3 | 63.5 | 71.4 | 69.8 |
| 4 | 73.7 | 64.2 | 74.6 | 70.2 |
| 8 | 73.6 | 73.4 | 65.5 | 75.1 |
| 12 | 77.1 | 73.8 | 76.3 | 77.1 |

Débit agrégé en MB/s. Le tuyau est plein dès deux flux ; au-delà, des lecteurs supplémentaires se partagent la même bande passante. La médiane par flux passe d'environ 45 MB/s avec un flux à environ 8 MB/s avec douze.

La colonne des lectures terminées est la plus intéressante :

| flux | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 4 | 4/4 | **2/4** | 4/4 | 4/4 |
| 8 | 8/8 | **3/8** | 8/8 | 8/8 |
| 12 | 10/12 | **4/12** | 9/12 | 10/12 |

**AllDebrid ne termine plus les lectures à partir de quatre fichiers distincts simultanés.** Les octets continuent de circuler, et le débit agrégé reste au plafond de l'hébergeur, mais les flux individuels ne se terminent pas. La médiane par flux tombe à zéro avec huit et douze flux, avec des médianes de TTFB supérieures à 3 s. Tout le reste tient jusqu'à douze, où les quatre fournisseurs perdent entre un et deux flux.

> **Retiré le 2026-08-23. Ce n'est pas une limite de concurrence du fournisseur.** Retesté directement sur les API, avec des débits de lecture limités au débit réel de lecture plutôt qu'à plein régime via zurg, AllDebrid a résolu **4/8/12/16/24 liens distincts simultanés à 100 %** et maintenu **24/24** flux en direct. Les échecs ci-dessus venaient de **trois hôtes CDN d'AllDebrid routés vers le vide** : `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`. Ils se résolvent tous en `0.0.0.0` et représentent **15,6 % des liens résolus**. Le premier est le même hôte signalé plus bas dans ce document comme lien mort isolé ; ce n'était pas un cas isolé.
>
> Un hôte mort ne fait échouer que les fichiers qui sont dans le lot. Le nombre d'échecs augmente donc avec N et ressemble exactement à un plafond de concurrence. **Toute échelle qui tire davantage de fichiers distincts à mesure qu'elle monte reproduira ce faux résultat.**
>
> Toute la colonne des taux de réussite ici est limitée par la méthode, pour la même raison : ces essais ont tiré à plein régime sur une liaison saturée à 73–78 MB/s. Ce qu'elle mesure, c'est **le partage de la bande passante, pas une limite du fournisseur**. Les vrais plafonds par hôte, tous non documentés, sont : Real-Debrid **32** (coupé au niveau TCP), AllDebrid **32** (HTTP 429), TorBox **20** par hôte `nexus-NNN` (HTTP 429, par hôte et non par IP), et aucun plafond trouvé pour Premiumize à 64.
>
> Une mise en garde pour ne pas trop interpréter ce retrait : un hôte routé vers le vide échoue en environ 0,1 s, alors que les médianes de TTFB ci-dessus dépassent 3 s. C'est un échec lent avec une signature différente, donc une saturation de la bande passante était probablement présente aussi. Ces deux effets pointent tous les deux loin d'un plafond côté fournisseur.
>
> **La correction qui en découle :** traiter un échec au niveau de la connexion sur un hôte CDN d'AllDebrid comme réessayable en **déverrouillant de nouveau le lien**. Un nouvel appel à `/link/unlock` renvoie un hôte différent. Ne pas réduire la concurrence. Une recherche DNS qui rejette `0.0.0.0` couvre tous les cas observés ici, sans coût.

### Plusieurs lecteurs, un seul fichier {#multiple-readers-one-file}

Mêmes niveaux, un seul fichier, décalages différents : la forme lecture anticipée plus recherche.

| streams | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| 4 | 4/4 | 4/4 | 4/4 |
| 8 | 8/8 | 8/8 | 8/8 |
| 12 | 10/12 | 9/12 | 10/12 |

AllDebrid va **bien** ici, avec 4/4 et 8/8, alors qu'il était à 2/4 et 3/8 sur des fichiers distincts.
Cette inversion est le diagnostic : sa limite n'est ni la bande passante, ni un plafond par torrent,
c'est la **résolution des liens** simultanée. Des fichiers distincts impliquent des déverrouillages distincts ; un seul fichier
se résout une fois, puis se contente de streamer.

> **Rétracté le 2026-08-23** : l'inversion a une explication plus simple. Les fichiers distincts pointaient vers des hôtes CDN distincts, et trois de ceux d'AllDebrid étaient mis en null-route. Un seul fichier se résout vers un seul hôte, qui fonctionne ou ne fonctionne pas. La résolution des liens elle-même a été mesurée correcte avec 24 requêtes simultanées. Voir la note ci-dessus.

### Plusieurs lecteurs sur différents fournisseurs {#multiple-readers-across-different-providers}

Voici le cas mixte entre fournisseurs, et il a besoin d'un corpus que le cas apparié ne peut pas fournir.
Comme l'instance fusionnée sert une release multi-comptes depuis `Sources[0]`,
chaque lecture du corpus apparié tombe sur Real-Debrid. Donc le pool ici est
*exclusif* à chaque fournisseur : 8 fichiers que seul Real-Debrid possède, 7 seulement sur AllDebrid, 8 seulement sur TorBox.

| flux (par fournisseur) | MB/s agrégé | terminés | RD | AD | TB |
|---|---|---|---|---|---|
| 3 (1 chacun) | 55.3 | 2/3 | 28.8 | — | 27.9 |
| 6 (2 chacun) | 66.9 | 5/6 | 16.1 | 13.3 | 21.5 |
| 12 (4 chacun) | 75.9 | 11/12 | 7.4 | 8.4 | 9.0 |

Les colonnes par fournisseur sont des médianes par flux en MB/s.

Les lectures sur des comptes différents tournent bien en parallèle, mais elles arrivent au même plafond de l'hôte à 76 MB/s qu'un fournisseur atteint tout seul. **Sur cet hôte, mélanger les backends n'apporte aucune bande passante.** Ce que ça apporterait ailleurs dépend d'avoir un lien plus gros que ce qu'un fournisseur peut remplir, ce que zen n'a pas. Ce que ça apporte à la place, c'est la disponibilité, et seulement en partie, comme le montre la section sur le basculement ci-dessous.

Le seul échec constant est un fichier AllDebrid unique dont le nom d'hôte CDN, `l4m5n6.debrid.it`, se résout en **0.0.0.0**. C'est AllDebrid qui renvoie un lien mort, pas zurg, mais zurg passe environ 4 s à faire trois nouvelles tentatives avant de renvoyer une erreur 500, et comme ce fichier n'est sur aucun autre compte, il n'y a aucun repli possible.

### Basculement : dans un seul sens {#failover-only-from-one-direction}

Comme l'instance fusionnée ne peut pas répartir la charge, ce qu'elle est censée apporter, c'est la survie d'un compte défaillant. `ca/cdnfail.py` bloque le CDN d'un seul compte et laisse toutes les API et les autres comptes intacts. La bibliothèque se charge donc toujours, et seuls les octets sont touchés. Les releases lues font partie du corpus apparié : les trois comptes les contiennent toutes.

| CDN coupé | lectures servies | ce que la lecture a fait |
|---|---|---|
| Real-Debrid | 2/2 | a basculé sur AllDebrid, 0.6 s |
| AllDebrid | **0/3** | une tentative sur AllDebrid, 503, puis **500 envoyé au client en 0.1 s** |

**Le basculement ne se produit que lorsque le compte défaillant est Real-Debrid.** La raison tient à une capacité que les autres backends ne définissent pas. Le refresh ne vérifie proactivement les liens que lorsque `StoredLinksCanRot` vaut true, et seul Real-Debrid a cette valeur :

```
Link verification failed during refresh for /A.Business.Proposal…: (code: 503)
```

C'est ce qui rétrograde la source, après quoi les lectures passent proprement sur un autre compte. AllDebrid et TorBox ne sont jamais sondés. Un CDN mort sur l'un de ces deux comptes passe donc inaperçu, la source n'est jamais rétrogradée, et chaque lecture de cette release renvoie 500, tant que la situation dure.

Deux autres points ressortent de ce test :

- **Le chemin de lecture n'a aucun basculement en ligne.** Un 503 venant du CDN du compte choisi est transformé directement en 500 pour le client, en 0.1 s. Les autres comptes qui possèdent le même fichier ne sont pas essayés. La récupération repose entièrement sur le refresh en arrière-plan. Donc, même dans le cas Real-Debrid, il existe une fenêtre pendant laquelle les lectures échouent.
- C'est le même mécanisme manquant qui explique la release TorBox restée en `broken_torrent` pendant 68 minutes. Rien ne re-vérifie un lien TorBox ou AllDebrid, donc rien ne retire un mauvais état ni ne détecte qu'un service est revenu.

### Un lien mort chez le fournisseur {#a-dead-link-from-the-provider}

Un fichier AllDebrid du pool exclusif a échoué à chaque fois qu'il a été sollicité, dans
chaque run de scan et chaque run mixed-reader. Son nom d'hôte CDN est résolu vers une route nulle :

```
$ getent hosts l4m5n6.debrid.it
::              l4m5n6.debrid.it
0.0.0.0
```

AllDebrid a fourni un lien pointant vers `0.0.0.0`. Ça, c'est du côté du fournisseur, pas de zurg. La partie de zurg, c'est ce qu'il fait ensuite : trois tentatives sur environ 4 s, puis un 500. Le fichier n'existe sur aucun autre compte, donc il n'y avait pas de solution de repli. Mais le résultat du failover ci-dessus montre qu'il n'en aurait pas utilisé de toute façon.

> **2026-08-23 : pas un seul hôte, et pas un seul fichier.** Trois noms d'hôte CDN AllDebrid ont été mis en route nulle en même temps : `l4m5n6.debrid.it`, `o7p8q9.debrid.it`, `c1uw74.debrid.it`. Ils représentent **5 liens sur 32 dans un échantillon et 4 sur 32 dans un autre, pour des contenus sans rapport**. AllDebrid continue de distribuer ces mêmes hôtes morts pour des fichiers différents, et il le faisait encore plusieurs jours après cette exécution. C'est un trou persistant dans sa flotte, et c'est ce qui a produit la conclusion de concurrence rétractée plus haut.
>
> Trois tentatives suivies d'un 500, c'est la mauvaise réponse. **Relancez plutôt le unlock** : `/link/unlock` renvoie un autre hôte. Faites aussi une vérification préalable avec une résolution DNS qui rejette `0.0.0.0`. Cela détecte tous les cas observés, sans coût.

### Analyse {#scanning}

`ffprobe` sur l'ensemble du pool mixte de 23 fichiers, ce qui correspond à une passe d'analyse Plex.

| concurrency | files/min | per-file median | per-file max | CPU s |
|---|---|---|---|---|
| 1 | 43.7 | 1.16 s | 3.11 s | 2.22 |
| 4 | 112.0 | 1.67 s | 4.19 s | 1.29 |
| 8 | 142.3 | 1.87 s | 6.67 s | 1.16 |

Le scan se parallélise bien : on passe de 3,3x d'un thread à huit, avec une latence par fichier qui n'augmente que de 60 %. Pour la bibliothèque Real-Debrid de 3 316 releases, cela représente environ **76 minutes avec un thread et 23 minutes avec huit**, sans compter le travail propre à Plex.

### Diffusion pendant l'analyse {#streaming-while-scanning}

Le cas à craindre, puisqu'un scan sur un montage momentanément défaillant est ce qui a coûté des dizaines de milliers d'éléments Plex sur `fun`.

| concurrence du scan | flux seul | flux pendant le scan | conservé | durée totale du scan |
|---|---|---|---|---|
| 4 | 57.7 MB/s | 66.5 MB/s | 115% | 11.8 s |
| 8 | 67.8 MB/s | 66.8 MB/s | 98.5% | 9.7 s |

**Un scan ne prive pas un flux de bande passante.** Le spectateur garde pratiquement tout son débit, et son délai avant le premier octet s'améliore même (de 1.18 s à 0.15 s), parce que la connexion est déjà établie à ce moment-là. C'est le seul point où le chemin debrid se comporte mieux que ce qu'on craignait.

## Défauts révélés par cette exécution {#defects-this-run-surfaced}

**Classés par coût.**

1. **Un 503 passager laisse une release sous forme de dossier vide.** 85 x 503 pendant un build à froid ont placé 84 releases dans `broken_torrent`, et une release cassée est listée sans aucun fichier. Avec la réparation désactivée, elle ne se corrige jamais ; avec la réparation activée, elle ne se corrige que lorsqu'un passage l'atteint. Sur TorBox, il n'existe aucun chemin de re-vérification (`StoredLinksCanRot: false`), et la seule release cassée là-bas était toujours cassée 68 minutes plus tard, alors que le fournisseur la signalait en cache et présente.
2. **Le nettoyage des entrées de téléchargement est cassé, et le coût s'accumule.** 3 992 `unrestrict/link` contre 23 `downloads/delete`, et **22 de ces 23 ont renvoyé 404** : le nettoyage supprime des ids qui n'existent pas. Le compte est passé de 12 469 entrées à **18 768** sur deux autres builds à froid, et zurg parcourt la liste complète au démarrage par pages de 5 000. La fuite se transforme donc en un coût de démarrage qui grandit avec elle.
3. **589 rejets pour limite de débit pendant un seul build à froid.** Tous sur `unrestrict/link`, soit environ 8 % du passage. La valeur par défaut `api_rate_limit_per_minute: 250` ne maintient pas unrestrict dans la vraie limite de Real-Debrid. Ces rejets et les 503 sont le même événement qui produit le défaut 1.
4. **Démarrer pendant une panne d'un fournisseur donne un montage vide**, et une lecture sur Real-Debrid ou AllDebrid reste alors bloquée jusqu'au délai d'expiration du client, au lieu d'échouer rapidement. TorBox répond 400 en 35 ms.
5. ~~**AllDebrid cesse de terminer les lectures simultanées de fichiers différents.**~~ **Rétracté le 2026-08-23 — voir la note dans « Lectures multiples, fichiers différents » plus haut.** La cause était trois hôtes CDN d'AllDebrid mal routés (null-routed), qui portaient 15,6 % des liens, et non une limite de résolution simultanée ; retesté directement, AD résout 24 liens distincts simultanés à 100 % et soutient 24/24 flux. Le texte original est conservé ci-dessous pour mémoire.

   2 sur 4, 3 sur 8,
   4 sur 12. Les mêmes niveaux sur un *seul* fichier sont corrects (4/4, 8/8), donc la limite se situe dans la résolution simultanée des liens, et non dans la bande passante ni dans un plafond par torrent. Quatre fichiers lus en même temps, c'est une soirée ordinaire pour un foyer.
6. **Une release à plusieurs comptes est toujours servie par le même compte.** `File.PrimarySource` renvoie `Sources[0]`, donc le choix est le premier compte vu. Vérifié : 7 releases sur 7 du corpus étaient servies par Real-Debrid alors qu'AllDebrid et TorBox détenaient des copies identiques. Il ne choisit jamais le compte le plus rapide ou le moins chargé.
7. **Le basculement de secours ne fonctionne que dans un sens, et jamais en ligne.** Quand le CDN de Real-Debrid refusait, les lectures passaient sur AllDebrid ; quand celui d'AllDebrid refusait, 0 lecture sur 3 n'a été servie, et chacune a renvoyé 500 en 0,1 s sans essayer les deux autres comptes qui détenaient le même fichier. Seul Real-Debrid définit `StoredLinksCanRot`, donc seuls ses liens sont re-vérifiés pendant le rafraîchissement, et seules ses erreurs rétrogradent une source. Rien dans le chemin de lecture n'essaie un second compte en cas d'erreur.
8. **Le test réseau au démarrage s'exécute pour chaque backend.** 88 requêtes HEAD vers les hôtes de téléchargement de Real-Debrid sur une instance TorBox seule et une instance AllDebrid seule, qui n'ont aucune utilité pour ce résultat.
9. **Le href PROPFIND d'une collection renvoie 404.** zurg émet `<d:href>/all/…</d:href>` en omettant le préfixe `/dav` ; récupérer ce chemin renvoie 404. Les enfants sont émis sous forme de hrefs relatifs nus, donc seule l'entrée elle-même est fausse. La RFC 4918 attend un href qu'un client peut résoudre, et rclone et Plex s'en sortent seulement parce qu'ils ne l'utilisent pas.
10. **`user`/`user/me` est appelé trois fois à chaque démarrage**, à froid ou à chaud, sur TorBox comme sur AllDebrid.

## Pas des défauts, mais bon à savoir {#not-defects-but-worth-knowing}

- **Real-Debrid ne déduplique pas par infohash.** Ajouter un magnet déjà présent sur le compte crée une *deuxième* entrée. C'est pour ça que les 3 416 torrents se compilent en 3 318 releases uniques. Ça a aussi invalidé le premier test de détection de suppression : il a supprimé le doublon qu'il venait de créer et a conclu que rien n'était jamais détecté.
- **`torrents_rate_limit_per_minute` vaut 75 par défaut**, ce qui limite la construction à froid de Real-Debrid. C'est une valeur par défaut voulue, pas un bug, mais c'est ce nombre qui donne les 29 minutes.

## Relancer {#rerunning}

```bash
cd ~/dbench && ./runall.sh          # p1..p6
./p7.py adddel rd,ad && ./p7.py outage rd,ad,tb
./apiref.py rd,ad,tb                # provider-side reference latency
./report.py                         # tables
```

Ne lancez jamais deux instances en même temps, et ne comparez les chiffres que d'une seule exécution entrelacée : le débit des fournisseurs varie beaucoup au cours d'une soirée.
