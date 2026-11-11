# Architecture

Une carte de ce qu'est zurg, de la manière dont les pièces s'emboîtent et de la raison d'être de chaque package. Destinée à quelqu'un qui s'apprête à modifier le code : elle nomme les décisions structurantes et les invariants faciles à casser sans s'en rendre compte.

Le détail de chaque package se trouve dans le `doc.go` de chacun. Ce document est le niveau au-dessus : la forme de l'ensemble, et le raisonnement qui découle de cette forme.

## Qu'est-ce que zurg {#what-zurg-is}

Un démon en Go qui présente la bibliothèque de torrents d'un compte debrid comme un système de fichiers virtuel. Il ne stocke aucun média. Chaque lecture est transformée en requête HTTP GET avec plage d'octets vers le CDN du fournisseur, au moment de la lecture.

Il ne contient aucun contenu propre et refuse un PUT. Il est donc en lecture seule au sens qui compte pour les octets. Deux écritures sont acceptées : un rename, qui enregistre un nom sans toucher à aucun compte ([renaming.md](../guides/renaming.md)), et un DELETE, qui supprime la release de tous les comptes qui la contiennent. `__magic__` ajoute une troisième écriture dans un seul espace de noms, une disposition enregistrée ([magic.md](../guides/magic.md)). Ça marche partout dans cet espace, sauf à `__magic__/__all__` et aux dossiers de release directement à l'intérieur. Ce sont eux le miroir calculé dans lequel les clients de téléchargement importent.

Quatre vues sur la même bibliothèque :

| Endpoint | Pour |
|---|---|
| `/dav/` | WebDAV, ce que rclone monte |
| `/http/` | Explorateur de dossiers en HTML |
| `/infuse/` | Variante WebDAV qui prend en charge les particularités d'Infuse |
| `/strm/` | URLs signées dans des fichiers `.strm`, pour les lecteurs qui veulent une URL plutôt qu'un montage |

rclone monte `/dav/` en FUSE, donc Plex, Jellyfin, Emby et Infuse voient une arborescence de dossiers classique.

Le problème de conception, partout, c'est l'écart entre ce qu'un système de fichiers promet (chemins stables, `stat` instantané, octets à la demande) et ce qu'une API debrid donne : du JSON limité en débit, des liens qui expirent, et aucune notion de système de fichiers. Presque chaque paquet existe pour combler une partie de cet écart.

```
media player
    │
    ├─ rclone FUSE ──► /dav/  ──┐
    └─ direct HTTP ──► /http/ ──┤
                                ▼
                    internal/handlers  (chi router, auth, routing)
                                │
                internal/dav ───┤─── internal/htmlindex     (listings)
                                │
                                ▼
                    internal/torrent   (the library, in memory)
                                │  resolve link for this file
                                ▼
                    internal/universal (byte path, proxy/redirect, RAR)
                                │
                                ▼
                    internal/debrid    (Provider dispatch)
                                │
        ┌───────────┬───────────┼────────────┬──────────┐
        ▼           ▼           ▼            ▼          ▼
   realdebrid    torbox     alldebrid       nzb ──► nntp ──► par2
        └───────────┴───────────┘            (Usenet, no debrid service)
                    │
              internal/rdclient  (host rotation, rate limit, retry, DNS)
```

## Séquence de démarrage {#boot-sequence}

`cmd/zurg` est une CLI Cobra légère (serve, version, network-test, clear
downloads/torrents, contrôle du montage, download requirements). Tout le vrai travail se fait dans `internal/app.go`, dont `MainApp` est volontairement une seule fonction lisible :

1. Crée les répertoires d'exécution (`logs`, `data`, `data/info`, `dump`,
   `strm`, `nzbs`) ainsi que le logger.
2. `ensureConfigAndRequirements` : charge la config, et télécharge `ffprobe` et
   `rclone` s'ils sont absents (`internal/requirements`). Un premier lancement sans config
   en écrit une par défaut puis s'arrête, sauf si le token vient de l'environnement.
3. Initialise `strmlink` tôt, pour qu'un dossier data non accessible en écriture soit signalé
   maintenant plutôt que sous forme de fichiers `.strm` qui cessent de se résoudre après le prochain
   redémarrage.
4. Lance le **test de latence réseau** vers les serveurs de téléchargement de Real-Debrid
   (`internal/rdclient`), ou charge son résultat mis en cache depuis le disque s'il est assez récent. Ce test classe les hôtes CDN, et c'est sur ce classement que s'appuie ensuite la rotation des hôtes.
5. Construit chaque fournisseur configuré depuis le registre, les assemble dans un `debrid.Set`, et garde un handle typé sur le premier fournisseur Real-Debrid. Le tableau de bord, la page des hôtes et le test réseau s'adressent toujours spécifiquement à RD.
6. Crée le `TorrentManager`, qui commence immédiatement à charger la bibliothèque en cache depuis le disque en arrière-plan, puis la rafraîchit.
7. Attache le routeur chi, démarre le serveur HTTP, puis démarre rclone une fois que le serveur accepte les connexions.
8. Attend SIGINT/SIGTERM/SIGQUIT ; à la réception d'un signal, ferme proprement le serveur HTTP, arrête le service Plex et démonte rclone, chacun avec un budget de 20 s.

`ZURG_PPROF=1` active pprof sur `127.0.0.1:6060`. Il n'écoute qu'en boucle locale, parce que profiler une instance en cours est le seul moyen d'identifier la consommation CPU pendant une tempête de scan, mais ce point de terminaison ne doit jamais être accessible depuis le réseau.

## Couche 1 — Configuration {#layer-1--config}

`internal/config` est la source unique de vérité ; presque tous les autres packages lisent `ZurgConfigV1`. Les getters typés appliquent les valeurs par défaut quand un champ vaut zéro, donc les appelants n'ont jamais besoin de vérifier l'absence.

La partie la plus importante est `filters.go` : un langage de filtres AND/OR imbriqués qui affecte chaque torrent à un ou plusieurs **dossiers virtuels**. C'est ce qui transforme une liste plate de torrents en `movies/`, `shows/`, `anime/`, `recent/`.

Les conditions couvrent le nom du torrent (`regex`, `contains`, `not_regex`), sa taille, ses fichiers (`any_file_inside_regex`, `any_file_inside_size_gte`), ses tags (`tags_match_any`, `tags_missing_all`), son âge (`added_within_hours`, `added_after`), des propriétés dérivées (`has_episodes`, `is_music`), et le compte dont il provient (`provider`, `not_provider`). Des règles d'affichage par dossier s'ajoutent à côté : `only_show_the_biggest_file`, ainsi que les seuils minimum et maximum de taille.

Les regex utilisées pour chaque torrent à chaque passe d'affectation sont compilées une seule fois au niveau du package — les `MustCompile` appelés à chaque fois ralentissaient nettement le démarrage.

La config est modifiable à chaud depuis le dashboard. `UpdateConfigFileAtomic` fait des modifications clé par clé au lieu de re-sérialiser le fichier, donc les commentaires et les clés inconnues sont conservés.

## Couche 2 — Abstraction des backends {#layer-2--backend-abstraction}

`internal/debrid` est la colonne vertébrale. Il contient les types du domaine que tous les autres paquets utilisent — `Torrent`, `TorrentInfo`, `File`, `Download`, `User` — ainsi que l'interface `Provider` que chaque backend implémente.

### Fournisseur et capacités {#provider-and-capabilities}

`Provider` reste petit : lister les torrents, récupérer les infos, supprimer, résoudre un lien, le vérifier, récupérer les octets, indiquer l'état du compte. Tout ce qu'un service peut raisonnablement ne pas proposer est une **interface de capacité optionnelle** que les appelants testent avec une assertion de type, et à laquelle ils se replient :

| Interface | Ce qu'elle ajoute | Qui en a besoin |
|---|---|---|
| `MagnetAdder` | ajout par hash, sélection des fichiers, nombre de slots actifs | réparation |
| `TorrentRestarter` | relancer un torrent en échec sur place | réparation, la stratégie la moins coûteuse |
| `HostRotator` | change le pool d'hôtes CDN | test réseau, page `/hosts` |
| `DownloadLister` | une liste séparée des téléchargements d'hébergeurs | le répertoire `__downloads__` |
| `ArchivePasswordKeeper` | le mot de passe des archives d'une release | Usenet uniquement |
| `PremiumMonitor` | le temps restant sur le forfait | avertissement au démarrage |

À côté de ça, `Capabilities` est l'auto-description du provider : pas ce qu'il peut faire, mais les limites dans lesquelles il doit être utilisé. Ça existe parce que le comportement de la bibliothèque de zurg s'est construit autour de la forme de Real-Debrid, et coder cette forme en dur rendrait tous les autres backends soit cassés, soit gaspilleurs.

Deux flags pilotent déjà le comportement réel :

- **`ListIncludesFiles`** : la liste des torrents contient déjà le détail de chaque fichier. Ça transforme un scan complet de la bibliothèque, qui faisait un appel API par torrent, en un seul appel au total. C'est la différence la plus coûteuse entre les backends.
- **`StoredLinksCanRot`** : un lien stocké peut mourir alors que le torrent a toujours l'air en bonne santé, donc les liens doivent être sondés. C'est une propriété de Real-Debrid, et une propriété coûteuse ; sur un backend qui génère les URLs à la demande, il n'y a rien à sonder, et sauter cette passe fait la différence entre un scan gratuit et un scan qui déclenche un blocage à l'échelle du compte.

Les autres, `ServesLinksLocally`, `MaxActiveSlots`, `MaxConcurrentRequests`, `AddsPerHour`, `ContentExpires` et `SupportsFileSelection`, sont déclarés par chaque backend et lus par le code générique. La valeur zéro est volontairement la lecture la plus prudente : un provider qui oublie un champ obtient un comportement prudent plutôt qu'une avalanche de requêtes. Et un provider que zurg ne peut pas résoudre du tout se replie sur `unknownProviderCaps` dans `internal/torrent/providers.go`, qui énonce cette réponse prudente une seule fois au lieu de la répéter à chaque appel.

Une troisième forme existe, que ni l'un ni l'autre flag n'exprime : la liste d'AllDebrid ne contient pas de fichiers, mais son endpoint par torrent accepte un *lot* d'ids. Ça se gère à l'intérieur du provider plutôt que par une capacité, parce que ça ne change que la façon dont le provider dépense ses propres requêtes. Le rafraîchissement générique demande toujours un torrent à la fois et n'a rien à savoir de ce mécanisme.

### Set

`Set` désigne chaque fournisseur configuré, dans l'ordre de la configuration. C'est lui que le gestionnaire de torrents, les handlers et le tableau de bord utilisent à la place de n'importe quel client concret. Deux schémas d'accès comptent : **fan-out**, où une opération s'exécute sur chaque compte (un rafraîchissement de bibliothèque), et **dispatch**, où une opération doit atteindre le seul compte qui possède un torrent (suppression, résolution, réparation). Il gère aussi l'état de santé et de disponibilité des comptes.

### Cache des liens {#link-cache}

`LinkCache` stocke les URL résolues en les indexant **par token**, et pas seulement par lien. Une URL générée avec un token n'est valide que pour le quota de ce token. Donc, quand un token atteint sa limite de bande passante, toutes ses entrées doivent être abandonnées d'un coup, et pas réutilisées avec le token suivant dans la rotation. Les entrées expirent selon leur timestamp `Generated` et non selon l'heure d'insertion. Ainsi, les liens préchargés depuis la liste de téléchargements du fournisseur expirent selon le calendrier du fournisseur.

### Les backends {#the-backends}

| Paquet | Ce que c'est | Le point à connaître |
|---|---|---|
| `internal/realdebrid` | Real-Debrid, le backend d'origine | Trois clients HTTP distincts : API à débit limité, unrestrict à débit limité, téléchargement avec rotation d'hôtes. Les horodatages en heure de Paris sont normalisés à la frontière du paquet et ne fuient jamais au-delà. `DownloadTokenManager` fait tourner les jetons quand l'un expire. |
| `internal/torbox` | REST TorBox | Utilise le REST avec `bypass_cache=true` plutôt que le WebDAV de TorBox, dont la vue accuse un retard de 5–15 minutes sur la réalité. Il n'existe pas de lien par fichier, donc les liens sont synthétisés sous la forme `torbox://<torrent-id>/<file-id>` : stables après un redémarrage et lisibles dans les logs, ce qu'une simple URL CDN contenant la clé API ne serait pas. Deux limiteurs empilés : les 300/min documentés, plus un limiteur bien plus strict pour `requestdl`. Voir [torbox-limits.md](../providers/torbox-limits.md). |
| `internal/alldebrid` | AllDebrid v4.1 | POST en form-encoded ; un échec logique arrive en HTTP **200** avec `status:"error"`, donc le statut HTTP ne dit jamais si un appel a réussi. Les fichiers se trouvent derrière `/magnet/files`, qui accepte un lot : les recherches concurrentes sont regroupées en une seule requête. L'arborescence imbriquée est aplatie en profondeur d'abord, et cet ordre est essentiel. |
| `internal/nzb` | Usenet — pas du tout un service debrid | Les fichiers NZB dans `nzbs/` deviennent des torrents ; les lectures récupèrent les articles et les décodent en yEnc à la demande. Les liens sont `nzb://<nzb-id>/<file-index>` et servis localement, donc `DownloadFile` synthétise la réponse HTTP au lieu de la relayer. |
| `internal/nntp` | Client Usenet minimal | Pool de connexions limité par le quota de connexions du compte, BODY/STAT par message id, décodage yEnc. Une seule connexion n'atteint qu'une fraction du débit possible, donc les lectures d'un fichier se répartissent sur tout le quota. |
| `internal/par2` | PAR2 / Reed-Solomon sur GF(2^16) | Quand un article a disparu du serveur, les volumes de récupération de la release reconstruisent les octets qu'il portait. Coûteux d'une façon précise : le calcul demande chaque tranche survivante de chaque fichier couvert, une seule fois. Il tourne donc en tâche de fond, une release à la fois, et produit des correctifs par plages d'octets que les lecteurs servent à la place du silence. |
| `internal/rdclient` | HTTP bas niveau partagé | Rotation d'hôtes parmi les endpoints CDN classés par latence, limitation par seau de jetons, nouvelles tentatives avec backoff, support proxy, DNS personnalisé, forçage IPv4/IPv6, préférence CDN épinglée géographiquement. `IPRepository` gère le test réseau et son cache sur disque. |

`internal/nzb` est la preuve que l'abstraction tient. Il implémente la même
interface au-dessus d'un répertoire local et d'un serveur de news, ce qui
fonctionne parce que le vrai contrat de l'interface est *« répondre à un GET
par plage avec des octets »*, et non *« relayer un CDN »*.

### Ajouter un backend {#adding-a-backend}

Nouveau paquet : implémentez `debrid.Provider`, appelez `debrid.Register` dans `init`, et ajoutez un import vide dans `internal/app.go`. Rien ne change dans `internal/debrid`.

## Couche 3 — La bibliothèque {#layer-3--the-library}

`internal/torrent` est le cœur de zurg et son package le plus gros. `TorrentManager` garde toute la bibliothèque dans des maps concurrentes `cmap`, pour des lectures sans verrou. Il assigne les torrents à des dossiers en évaluant les filtres de la config, résout et met en cache les liens, et lance les tâches de fond.

### Persistance {#persistence}

Chaque entrée est écrite dans `data/<name>.zurgtorrent` au format JSON, et les infos de chaque torrent sont mises en cache dans `data/info/`. Au redémarrage, tout est chargé depuis le disque et c'est tout de suite utilisable, puis les données sont rafraîchies. Ça compte, parce qu'un scan à froid est limité par le rate-limit, pas par le CPU. Les torrents qui ne sont plus sur le compte peuvent être archivés dans `dump/` et apparaître dans le dossier `__dump__` (`load_dumped_torrents`).

Ce qui ne peut être reconstruit par rien d'autre (la config, chaque zurgtorrent, le store `__magic__` dans `data/local/`, les NZB sources dans `nzbs/`) est enregistré dans un seul `.zurgbackup` en flux continu. `zurg backup` en crée un (tout comme la page Backup & Restore du tableau de bord), et `zurg restore-backup <file>` le décompresse dans le répertoire de travail. `internal/backup` gère le format. Un manifest est la première entrée, donc une restauration vérifie ce qu'elle a sous la main avant d'écrire quoi que ce soit.

Noms de dossiers réservés : `__all__`, `__unplayable__`, `__dump__`, `__downloads__`, et un par compte sous la forme `__<provider-name>__`.

### Torrent vs TorrentCopy

Une release peut exister sur plusieurs comptes. zurg ne la montre qu'une seule fois. Voici la répartition :

- **Les infos sur le contenu appartiennent à l'entrée** (`Torrent`) : le nom, le hash, les fichiers présents, les tags, l'id IMDB, le rename.
- **Les infos sur le compte appartiennent à chaque copie** (`TorrentCopy`) : les ids de torrent créés par ce compte, les liens qu'il fournit, son propre état cassé et ses compteurs de nouvelles tentatives.

Les ids de fichiers sont propres à chaque compte, en particulier. Real-Debrid numérote les fichiers d'un torrent et marque un sous-ensemble comme sélectionné. TorBox ne liste que ce qu'il a téléchargé et les numérote à sa façon. C'est pour ça que `FileSource` garde un `FileID` par fournisseur. La réparation construit sa sélection à partir des ids de la copie qu'elle répare. Si tu lis l'id d'un autre compte, tu re-ajoutes les mauvais fichiers.

Les copies sont stockées dans l'ordre de la config, qui est l'ordre de préférence. Les lectures utilisent d'abord la première copie en bon état, et basculent sur la suivante en cas d'échec. Supprimer l'entrée supprime toutes les copies. Une entrée sans copie n'existe pas.

### GetKey doit rester pur {#getkey-must-stay-pure}

`GetKey` est le nom d'un torrent dans la bibliothèque virtuelle : c'est son entrée de répertoire, son nom de fichier `.zurgtorrent` et la clé que toutes les recherches utilisent. Il est **recalculé à chaque recherche, jamais stocké**. On ne peut donc pas régler les collisions de noms en vérifiant ce qui est déjà utilisé : la réponse changerait avec la bibliothèque, et un torrent deviendrait introuvable sous le nom sous lequel il avait été enregistré.

Le seul suffixe sert au cas plus rare où deux *releases* différentes portent le même nom. C'est une étiquette tirée du hash du contenu lui-même, aussi pure que le nom. L'indicateur qui l'active est décidé par le passage de rafraîchissement, qui voit toute la bibliothèque, puis enregistré sur le torrent.

### Tâches en arrière-plan {#background-jobs}

| Tâche | Fichier | Ce qu'elle fait |
|---|---|---|
| Refresh | `refresh.go` | Interroge chaque compte, fusionne les instances listées dans les entrées, récupère les infos des nouvelles, attribue les dossiers et supprime les entrées obsolètes. Utilise une petite requête portant sur un seul élément comme vérification des changements entre deux interrogations complètes. |
| Repair | `repair.go` | Trouve et répare les torrents cassés. |
| Downloads | `manager.go` | Actualise la liste des téléchargements depuis les hébergeurs dans `__downloads__`. |
| Network test | `handlers` | Reclasse périodiquement les hôtes CDN. |

L'intervalle de chaque tâche peut être modifié à l'exécution via un canal, donc changer la
configuration depuis le tableau de bord prend effet sans redémarrage. Les horodatages de dernière exécution
sont enregistrés (`data/repair_timestamp`, `data/downloads_timestamp`) afin qu'un
redémarrage ne relance pas une tâche qui vient de s'exécuter.

### Réparation {#repair}

Deuxième plus gros point du paquet. Les fichiers portent un état FSM (`ok_file` / `broken_file`, via `pkg/fsm`), et les torrents et les copies ont chacun le leur. Quand les liens cessent de servir des octets, la réparation passe par plusieurs stratégies :

1. **Redémarrage sur place** (`TorrentRestarter`) : la moins coûteuse. Pas de nouvel upload, pas de place d'ajout consommée, et le torrent garde son id, donc l'entrée de la bibliothèque survit au lieu d'être supprimée puis redécouverte. Le rafraîchissement le lance pour un torrent en échec trouvé sur le compte, et seulement sur une instance autorisée à agir sur les torrents en échec, c'est-à-dire avec `enable_repair` ou `delete_error_torrents`. Si les deux sont désactivés, le compte reste tel quel (`mayRestartFailedTorrents`).
2. **Retélécharger les fichiers cassés** : vous ne resélectionnez que ce qui est cassé.
3. **Réinsertion** : on ré-ajoute le magnet et on récupère de nouveaux liens.
4. **Archivage** : dernier recours pour les releases qu'on ne peut pas récupérer.
5. **Proposer la release à un compte qui ne la possède pas** (`repair_across_accounts.go`) : les services ont des caches indépendants, donc une release qu'un compte a purgée, ou qu'il refuse à cause du nom de fichier, peut être mise en cache sur un autre. Une fois qu'aucun compte qui possède la release ne peut la réparer, les comptes configurés qui ne la possèdent pas sont sollicités dans l'ordre, et le premier qui a déjà le hash la prend. Le listing qui suit l'associe à l'entrée comme seconde copie via le chemin habituel `absorbCopy`, qui efface lui-même le verdict de l'entrée. Toujours en mode cache uniquement, via `AddIfCached` et jamais via `restrict_repair_to_cached` : un ajout que le compte devrait télécharger est annulé puis supprimé, donc c'est une réparation et jamais un retéléchargement. Un compte qui ne répond pas est mis en pause, d'un jour à environ quinze jours, et un balayage fait au maximum dix propositions. C'est ce qui permet de le lancer sans demande explicite sur une bibliothèque de releases condamnées.

Autour de tout ça : backoff exponentiel, plafonds de tentatives par copie (`RepairCycles`, `AssignRetries`, persistés pour que les plafonds survivent aux redémarrages), limites horaires d'ajouts issues de `Capabilities.AddsPerHour`, vérifications des slots actifs, déduplication via une file d'attente adossée à un set, et une heuristique à l'échelle du balayage qui lit une rafale d'échecs « hoster-unavailable » comme une seule panne du fournisseur plutôt que comme N torrents cassés. Les verdicts « non réparable » sont enregistrés par copie et ne remontent à l'entrée que si *chaque* copie en porte un. Une erreur permanente de Real-Debrid ne dit rien sur la copie TorBox.

Vous pouvez forcer une réparation à la main. Le forçage est porté par le torrent et non par le contexte, car une demande arrivant en plein balayage est mise en attente dans la file et traitée plus tard, sous le contexte propre du balayage. Le bouton atteint aussi l'étape 5, et dans cet ordre : il efface d'abord tous les verdicts sur la release, pour que le compte qui la possède soit réessayé exactement comme avant, et la proposition ne suit que si cette tentative échoue. Comme il efface ces verdicts, un torrent désigné devient éligible au moment où le balayage collecte ses entrées condamnées, et il n'est condamné à nouveau que par la réparation qui vient de s'exécuter. Il est donc collecté après cette réparation et non dans la boucle. Sinon, le seul chemin où quelqu'un attend un résultat serait celui qui ne propose jamais rien.

### Tout le reste du package {#everything-else-in-the-package}

`mediainfo.go` (analyse ffprobe, qui alimente les tags de durée/codec),
`tags.go`,
`rename.go` (renommages qui doivent survivre au rafraîchissement),
`delete.go`,
`strm.go` (génère des fichiers `.strm` pour toute la bibliothèque),
`hooks.go` (scripts utilisateur déclenchés lors des événements du cycle de vie),
`assign_links.go`,
`unrestrict.go`,
`opensubtitles.go`,
`provider_directories.go`,
`reset_all.go`.

## Couche 4 — Service {#layer-4--serving}

### Routeur {#router}

`internal/handlers` construit le routeur chi et branche tout le reste. Les méthodes WebDAV non standard (`PROPFIND`, `MKCOL`, `MOVE`) sont enregistrées sur chi à l'`init`. L'authentification Basic enveloppe tout **sauf** `version.txt` et `/ready` (pour que les vérifications de santé fonctionnent) et les endpoints `.strm` (un lecteur multimédia qui ouvre un `.strm` n'a pas d'identifiants à fournir : c'est le jeton signé dans le chemin qui l'autorise à la place).

Deux leçons de routage sont notées dans les commentaires et valent la peine de ne pas les réapprendre : chi applique un paramètre de chemin basé sur une regex **dans un seul segment**, donc un fichier adressé via une archive (`<archive>.rar/<inner>.mkv`) ou un répertoire imbriqué à l'intérieur de l'une d'elles ne correspondait à aucune route. Les deux avaient besoin de jokers finaux. Et un chemin à l'intérieur d'un torrent est réparti entre listing et téléchargement selon sa barre oblique finale, une fois que la route ne se soucie plus de la profondeur du chemin.

### Listings

`internal/dav` génère le XML PROPFIND et gère DELETE, MOVE (renommages, avec validation entre dossiers et entre torrents) ainsi que les variantes pour Infuse.
`pkg/dav` construit le XML lui-même, avec une concaténation de chaînes optimisée plutôt qu'une sérialisation XML. Il gère la conversion RFC 3339 → RFC 1123 qu'exigent les clients WebDAV et échappe les chemins pour l'URL comme pour le XML.

`internal/htmlindex` affiche la même arborescence en HTML pour `/http/`.

Les deux appliquent les mêmes règles de visibilité (uniquement le plus gros fichier, seuils de taille, état cassé/supprimé) et les deux regroupent les archives RAR multi-volumes pour ne montrer que le premier volume.

### Le chemin des octets {#the-byte-path}

`internal/universal` est là où une requête se transforme en octets :

- La résolution des liens est dédupliquée avec `singleflight`, donc une centaine de lectures simultanées du même fichier ne coûtent qu'une seule résolution.
- Proxy ou redirection, selon `disable_stream_proxy`. Sauf qu'un lien servi localement (`ServesLinksLocally`) ne peut jamais être redirigé, puisque le client n'a rien à ouvrir.
- Nouvel unrestrict sur un lien cassé, jusqu'à une petite limite.
- Un temps de refroidissement par fichier en cas d'erreur réseau : 3 erreurs consécutives mettent le fichier en pause pendant 5 minutes. Ça empêche un hôte CDN injoignable de devenir une boucle de tentatives infinie.
- Des pauses courtes pendant une fenêtre de limitation de débit, plutôt que de renvoyer une erreur. Renvoyer des erreurs pendant le court refroidissement transformerait un seul compte bridé en tempête d'erreurs via le VFS de rclone : attentes bloquées, lecteurs en état D, serveur média figé. Retenir la lecture est donc la solution la moins coûteuse. Les classes de refroidissement plus longues échouent toujours immédiatement.
- Comptabilité de la bande passante par jeton, avec des compteurs réinitialisés à minuit heure d'Europe centrale (CET) pour correspondre à la réinitialisation quotidienne du trafic de Real-Debrid.

### Archives

`internal/rarstream` analyse les en-têtes RAR4, RAR5 et ZIP via des requêtes à plages d'octets (HTTP 206), construit une table de correspondance des segments sur l'ensemble des volumes, et reconstitue à la volée le contenu d'un seul fichier. **Aucune décompression** : seules les données stockées sont prises en charge, ce qui correspond aux releases scene. `VolumeKey` et `IsVolume` normalisent les nombreuses conventions de nommage multi-parties (`.part001.rar`, `.r00`, `.rar`) que `dav` et `htmlindex` utilisent pour regrouper les volumes en une seule entrée. Les listings sont mis en cache sur le torrent et estampillés avec le `ListingVersion` de l'analyseur ; un listing produit par un autre analyseur est donc rejeté au lieu d'être servi.

### STRM

`internal/strmlink` encode et signe l'URL qu'un `.strm` contient. Le schéma réservé à Real-Debrid qu'il remplace était sûr par accident : l'URL contenait le code de téléchargement de 13 caractères de RD, donc le fait de la posséder *était* la preuve d'autorisation. Les autres backends adressent les fichiers par des identifiants énumérables trivialement (`torbox://17/3`). Avec la même forme, n'importe qui pouvant atteindre le port pourrait générer des URL CDN pour le compte ou consommer ses connexions aux serveurs de news. Un HMAC sur un secret stocké dans `data/strm_secret` règle ce problème : un jeton que zurg n'a pas écrit ne se résout pas. Le secret doit survivre au processus : chaque `.strm` déjà écrit ne reste valide que tant que sa clé de signature existe.

### Tableau de bord et gestion {#dashboard-and-management}

`internal/handlers/dashboard` génère l'interface web à partir de modèles intégrés,
pré-analysés au démarrage, si bien qu'une erreur de syntaxe fait échouer tout de suite plutôt qu'au moment de la requête.
Pages : état des torrents en direct, éditeur de configuration YAML interactif, latence de l'hôte,
gestion des dossiers, gestion des fournisseurs, état de la connexion aux serveurs multimédias,
infos sur le compte et le premium, bande passante, état de rclone, et statistiques Plex « Wrapped ».
Les récupérateurs d'état de chaque serveur multimédia tournent en parallèle pour garder les pages réactives.

`internal/handlers/manage` est l'interface d'opérations par torrent : tags, listes de fichiers avec le détail de leur état, correspondance Plex, renommages, suppression/restauration/force-show par fichier, suppression en masse et scan.

Sa vue des doublons est `internal/duplicates`.
`internal/arrinventory` et les lecteurs `Inventory` à côté des adaptateurs Radarr et Sonarr lisent chaque fichier qu'un \*arr détient, en lecture seule et en dehors de l'acquisition.
`magic.Resolver.HolderOf` remonte le chemin de chaque fichier jusqu'à la release d'origine, et le paquet regroupe les releases susceptibles de contenir le même film ou les mêmes épisodes.
Le regroupement utilise les noms, les identifiants IMDb et l'historique des \*arr.
Qu'une release soit utilisée ou non est décidé uniquement par les chemins remontés.

`internal/static` intègre le CSS, le favicon, le logo et robots.txt avec `go:embed`, si bien que le binaire est autonome.

## Couche 5 — Le montage {#layer-5--the-mount}

`internal/rclone` supervise rclone comme un sous-processus : il construit la commande de montage (un remote WebDAV pointant vers le `/dav/` de zurg), la démarre et l'arrête, vérifie son état toutes les 30 s avec un délai de redémarrage exponentiel (1 s → 60 s), et la redémarre en cas d'échec.

Un port RC éphémère dans la plage 49152–65535 est choisi au démarrage pour l'invalidation du cache VFS et les requêtes de statut. Cette invalidation compte à deux moments : une fois que le cache de la bibliothèque a fini de charger, puis à nouveau après le premier rafraîchissement complet. Sinon, les listes partielles que le montage a récupérées pendant le chargement restent en place pendant toute la durée de `--dir-cache-time`.

Les identifiants sont transmis par variable d'environnement, jamais sur la ligne de commande. `Controller` est l'interface qu'utilisent les gestionnaires et le tableau de bord ; `Runner` et `Command` abstraient la gestion des processus pour les tests.

## Couche 6 — Serveurs multimédias {#layer-6--media-servers}

Deux choses distinctes partagent le mot « Plex » :

- **`pkg/plex`, `pkg/jellyfin`, `pkg/emby`** sont des *clients* de serveurs multimédias, chacun implémentant
  `common.MediaServerWorker`. `pkg/common` fournit le cycle de vie partagé des tâches : une file d'attente dynamique sans limite, le suivi des tentatives par tâche, une temporisation exponentielle avec gigue (jitter), un disjoncteur après plusieurs échecs consécutifs, et la détection des tâches bloquées. Il contient aussi les fonctions d'aide sur les chemins, qui gèrent l'APFS de macOS insensible à la casse. `pkg/scan` se place par-dessus comme un `MediaScanner` unifié : il envoie une tâche de rafraîchissement de chemin au serveur qui possède ce chemin et indique la taille de la file d'attente de chaque serveur.
- **`internal/plex`** contient le comportement propre à zurg : `Matcher` associe les torrents aux éléments de la bibliothèque Plex à l'aide des chemins de fichiers, des identifiants IMDB et des identifiants TVDb/TMDb. Il tourne périodiquement dans des pools de workers avec des métadonnées en cache, et renseigne les identifiants IMDB découverts sur les torrents.
- **`internal/acquisition`** gère la file d'attente d'acquisition persistante et l'exécuteur partagé, qui récupère les NZB auprès des indexeurs Newznab et les torrents en cache auprès des indexeurs Torznab. La watchlist Plex, Seerr, Radarr et Sonarr sont des adaptateurs de sources : ils transforment les demandes en cibles film, saison ou épisode. `data/acquisition.json` conserve les échéances de nouvelle tentative et la progression par cible entre les redémarrages. Consultez [sources d'acquisition](../guides/acquisition.md) pour la configuration et les contrats des adaptateurs.

`pkg/mediabrowser` regroupe les types communs à Emby et Jellyfin.

## Couche 7 — Support {#layer-7--support}

| Paquet | Rôle |
|---|---|
| `pkg/fsm` | Deux variantes de petite machine à états : `FSMWithExternalMutex` pour quand la FSM est intégrée dans quelque chose qui est déjà verrouillé, `FSMWithTime` pour quand elle a besoin de son propre verrou et d'un horodatage de transition (pour que `SinceWhen` puisse répondre à « depuis combien de temps ça ne marche plus »). |
| `pkg/logutil` | Zap avec double sortie : console colorée et fichier qui tourne (10 MB × 20 via lumberjack). Le niveau de détail vient de `log_level` dans config.yml, sinon de la variable d'environnement `LOG_LEVEL`, et sinon de DEBUG. Le niveau est stocké dans un `zap.AtomicLevel` partagé, donc le tableau de bord peut changer le niveau de tous les loggers d'un coup, sans redémarrer. Inclut la lecture du journal pour la visionneuse du tableau de bord et pour Export Logs. |
| `pkg/utils` | Sauvegarde des hôtes bloqués, règles de visibilité des fichiers, masquage des tokens, détection vidéo/audio, nommage `.strm`, et `GetZurgBaseURL` (qui respecte `X-Forwarded-*` derrière un reverse proxy). |
| `pkg/script` | Exécute les scripts utilisateur liés aux événements du cycle de vie ; PowerShell sous Windows, `/bin/sh` ailleurs. |
| `pkg/dmm` | Client pour l'API de recherche de debridmediamanager.com, limité à 1 requête toutes les 2 secondes côté serveur. Utilisé par le moniteur de watchlist. |
| `internal/version` | Métadonnées de build injectées via ldflags ; c'est aussi la bannière ASCII dans `/http/version.txt`. |
| `internal/requirements` | Télécharge `ffprobe` et `rclone` adaptés à ta plateforme depuis les releases GitHub au premier lancement, et écrit des chemins *relatifs* dans config.yml, pour que la config reste portable. Les plateformes non prises en charge affichent un avertissement au lieu de planter. |
| `internal/clear` | Supprime en masse les téléchargements et torrents RD en pilotant l'interface web avec un cookie d'authentification, en boucle jusqu'à ce que ce soit vide. |
| `internal/handlers/tmplcache` | Mise en cache des templates pour le tableau de bord. |

## Décisions transversales {#cross-cutting-decisions}

**Des capacités plutôt que `if provider == "realdebrid"`.** Tout ce qui suppose la forme de Real-Debrid doit passer derrière un flag de capacité, pas derrière une vérification de type. C'est la règle qui garde le gestionnaire de torrents indépendant du backend.

**Le contrat de l'interface, ce sont des octets, pas du proxy.** `Provider` ne promet jamais un CDN distant, seulement qu'une requête GET avec plage peut recevoir une réponse. C'est pour ça qu'un backend Usenet s'intègre. Les deux endroits où l'hypothèse du CDN a fuité (les redirections, et le passage d'une URL à ffprobe, qui a besoin de quelque chose qu'un binaire externe peut ouvrir) sont maintenant tous les deux protégés par `ServesLinksLocally`.

**L'appariement positionnel des liens est porteur de charge.** `TorrentInfo.Links[i]` correspond au i-ème fichier **sélectionné** de `TorrentInfo.Files`. Un provider qui ne peut pas lier un fichier doit le signaler comme *non sélectionné* au lieu de l'omettre, sinon tous les fichiers suivants se résolvent silencieusement vers le mauvais lien. Chaque backend doit respecter ça.

**Un torrent appartient à exactement un compte.** Tout appel qui atteint un service doit être envoyé via le provider du torrent (`ProviderFor`, `resolveLink`, `verifyLink`, `DeleteByID`), jamais via le provider principal. Se tromper là-dessus supprime dans le mauvais compte.

**Le disque est un vrai niveau de stockage.** Les entrées `.zurgtorrent`, le détail par torrent dans `data/info/`, les résultats des tests réseau et leurs horodatages, les horodatages des jobs, le secret de signature STRM, les caches de listing RAR, les hôtes bloqués. Un redémarrage reprend là où on en était au lieu de tout rescanner.

**Tout est cadencé.** Token buckets par provider, plafonds de concurrence, portes d'ajout horaires, TTL des liens, temps de recharge par fichier, blocages liés au rate-limit. Sur TorBox surtout, la résolution des liens est la ressource rare, et le cache de liens devant elle est ce qui rend un scan de bibliothèque abordable tout court.

**Les lectures sont sans verrou, les écritures sont ciblées.** Des maps concurrentes portent les arbres de dossiers/torrents/fichiers ; la mutation est protégée par des verrous par torrent (`copiesMu`, `tagsMutex`, `operationsMutex`, `archiveCacheMutex`) plutôt que par un verrou global.

**`rdclient` est partagé, mais sa politique est celle de Real-Debrid.** Sa classification des erreurs et ses règles de nouvelle tentative viennent de RD. Il signale une réponse non-2xx comme une erreur tout en renvoyant quand même la réponse, donc un provider qui a besoin du statut — un 429 avec `Retry-After` — doit vérifier `resp` avant `err`.

## Build, test, déploiement {#build-test-deploy}

- **Build** : `make build`. La version, le commit et l'heure de build sont injectés via
  ldflags dans `internal/version`.
- **Tests unitaires** : `go test ./...`. Le pre-commit lance gofmt, golangci-lint,
  `go test -short` et une suite de contrôle qualité complète.
- **Tests d'intégration** : `make integration-test`, les moins coûteux d'abord, avec
  `refresh_repair` en dernier car il attend la fin d'un scan complet de la bibliothèque. Lance-les sur une machine qui a Go, rclone, FUSE et Plex en même temps. Ailleurs, les tests de montage et de Plex sont sautés avec un avertissement bien visible, mais le script sort quand même avec le code 0. Lis donc la sortie plutôt que le code de sortie. Voir [e2e-test.md](e2e-test.md).
- **Docker** : build Alpine en deux étapes ; l'image d'exécution ajoute ffmpeg, rclone,
  fuse3 et un healthcheck.
- **Déploiement** : `make deploy USER=… HOST=… DIR=…`, qui arrête Plex et les services zurg,
  remplace le binaire, attend que `version.txt` réponde 200, puis redémarre Plex.

## Où regarder en premier {#where-to-look-first}

Les commentaires de ce code notent systématiquement *pourquoi*, généralement
la panne qui a motivé le code. Chaque package a un `doc.go`. Si tu modifies
quelque chose, lis d'abord le `doc.go` de ce package et le commentaire de bloc
au-dessus du type que tu touches : ils contiennent les contraintes qui ne sont
pas visibles dans les signatures.
