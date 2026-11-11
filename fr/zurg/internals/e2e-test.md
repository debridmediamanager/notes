# Tests E2E {#e2e-testing}

Tests de bout en bout pour vérifier que zurg fonctionne correctement après le déploiement.

## Test de lecture Plex {#plex-playback-test}

Vérifie que le contenu est réellement lisible dans Plex en choisissant un film au hasard et en testant toute la chaîne de lecture.

### Lancer le test {#run-the-test}

```bash
./scripts/plex-e2e-test.sh
```

Le script lit automatiquement `plex_server_url` et `plex_token` depuis `config.yml`.

Pour les remplacer par tes propres réglages :
```bash
PLEX_URL="http://your-plex:32400" PLEX_TOKEN="your-token" ./scripts/plex-e2e-test.sh
```

### Ce qu'il teste {#what-it-tests}

| Step | Description |
|------|-------------|
| 1 | Trouver la bibliothèque Movies via l'API Plex |
| 2 | Obtenir le nombre total de films |
| 3 | Sélectionner un film au hasard |
| 4 | Obtenir l'URL de streaming du film |
| 5 | Vérifier que le flux est accessible (HTTP 200) |
| 6 | Décoder 3 secondes de vidéo avec ffmpeg |
| 7 | Créer et vérifier le suivi de session Plex |

### Sortie attendue {#expected-output}

```
=== Plex E2E Playback Test ===

[1/7] Finding Movies library...
  Library key: 15
[2/7] Getting movie count...
  Total movies: 1234
[3/7] Selecting random movie...
  Selected: 2 Fast 2 Furious (2003) (ratingKey: 756524)
[4/7] Getting stream URL...
  File size: 54GiB
[5/7] Verifying stream accessibility...
  HTTP Status: 200 OK
[6/7] Decoding video (3 seconds)...
  Decoded 72 frames successfully
[7/7] Testing Plex session tracking...
  Session created and tracked

=== TEST PASSED ===
Movie '2 Fast 2 Furious (2003)' is playable via Plex
```

### Prérequis {#prerequisites}

- Serveur Plex en marche et accessible
- `plex_server_url` et `plex_token` configurés dans `config.yml`
- `curl`, `jq` et `ffmpeg` installés

### Dépannage {#troubleshooting}

| Erreur | Cause | Solution |
|-------|-------|-----|
| No movie library found | Mauvais type de bibliothèque ou bibliothèque vide | Vérifie que Plex a une bibliothèque « Movies » |
| Stream not accessible (HTTP 4xx) | Problème d'authentification ou de chemin | Vérifie le token et que le fichier existe |
| Failed to decode video frames | Fichier corrompu ou problème réseau | Regarde les logs de zurg, essaie un autre film |
| Session not detected | Délai d'expiration de la session Plex | Regarde les logs de Plex |

## Suite d'intégration {#integration-suite}

```bash
ssh zen
cd /path/to/isolated/zurg/source
make integration-test
```

**Lance-le sur une cible isolée sur `zen`.** Installe-y une toolchain Go, shellcheck, rclone et la sonde de déplacement .NET. La suite crée ses propres processus zurg et ses propres montages ; elle n'exige pas de remplacer le service zurg normal ni le montage de zen. Utilise un répertoire source séparé, `TMPDIR`, une config, un port et un `MOUNT_PATH` à part. Inspecte la config temporaire avant de lancer, et garde le `INTEGRATION_LOCK_FILE=/tmp/zurg-integration-rd.lock` à l'échelle de l'hôte même avec un `TMPDIR` privé, pour que les autres sessions se synchronisent toujours avec la tienne.

Les tests dont les prérequis manquent peuvent être ignorés avec un code de sortie réussi. Lis leur sortie pour vérifier que FUSE, rclone, Plex et NNTP ont bien tourné.

| Test | Nécessite FUSE | Nécessite Plex | Nécessite un compte Usenet |
|------|:----------:|:----------:|:----------------------:|
| `refresh_repair_integration.sh` | | | |
| `network_test_cache_integration.sh` | | | |
| `rclone_mount_integration.sh` | oui | | |
| `magic_mount_integration.sh` | oui | | |
| `magic_move_refusal.sh` | oui | | |
| `magic_library_move_integration.sh` | oui | | |
| `plex_integration.sh` | oui | oui | |
| `nzb_bench_integration.sh` | | | oui |

`force_location_integration.sh` **n'est pas** dans la suite. Il vérifie quelque chose sur le chemin réseau de cet hôte vers le CDN de Real-Debrid plutôt que sur zurg, donc il échoue là où ce chemin ne peut pas répondre, quel que soit le changement testé. Lance-le exprès avec `make force-location-test`, sur un hôte avec un IPv4 fonctionnel vers la région forcée. Voir [Test d'intégration Force Location](#force-location-integration-test).

Les cinq tests qui utilisent Real-Debrid utilisent le même compte — voir [le compte est partagé](#the-real-debrid-test-account-is-shared). Le benchmark utilise un compte de news à la place et ne touche pas du tout à Real-Debrid, mais il prend le même verrou à l'échelle de l'hôte que le reste : une mesure faite à côté des lectures d'une autre suite mesure en fait l'autre suite.

Le test de montage tourne aussi sur un Mac si macFUSE est installé — il est vérifié à la fois sur macFUSE et sur `fusermount` Linux. Le test Plex a besoin de `plex_server_url` et `plex_token` dans sa config temporaire, et Plex doit pouvoir traverser chaque répertoire parent du montage temporaire. Un montage placé sous un répertoire home privé peut fonctionner pour l'utilisateur du test tout en restant inaccessible à Plex.

`make integration-test` compile zurg, lance shellcheck sur les scripts, le self-test de `lib.sh` et les tests unitaires de `integration/nzbbench`, puis lance les sept tests, du moins cher au plus cher : cache des tests réseau, montage rclone, Plex, montage `__magic__`, refus de déplacement .NET, refresh/repair, et le benchmark Usenet en dernier. Les deux derniers sont les plus coûteux — refresh/repair attend un scan complet de la bibliothèque, et le benchmark lit des gigaoctets sur un serveur de news deux fois — donc une erreur dans l'un des autres ne doit pas coûter cette attente pour être découverte. `make integration-test-media` lance les tests de montage rclone, Plex et `__magic__`, et `make nzb-bench-test` seulement le benchmark.

Chaque script possède un répertoire de travail sous `$TMPDIR`, son propre port, et écrit le log de zurg là-bas ; la suite tourne avec `STREAM_LOGS=false`, donc seules les assertions du test lui-même arrivent dans le terminal. Mets `STREAM_LOGS=true` pour suivre le log de zurg sur stderr pendant le débogage.

Les helpers communs se trouvent dans `integration/lib.sh` (contrôle des processus, API Real-Debrid, requêtes sur la bibliothèque sur disque) et `integration/lib_media.sh` (FUSE et Plex). Pour ajouter un test, source-les au lieu de copier un autre script. `integration/lib_test.sh` couvre les helpers eux-mêmes : pas de compte, pas de réseau, environ une seconde. `integration/nzb_bench_timing_gate_test.sh` couvre la façon dont le wrapper du benchmark transforme le code de sortie de l'outil en vocabulaire de la suite, à partir d'un rapport réel réduit dans `integration/testdata/` ; les deux tournent avec `make test-integration-lib`.

### Le compte de test Real-Debrid est partagé {#the-real-debrid-test-account-is-shared}

La suite utilise un seul compte de test Real-Debrid, et ce compte n'est pas privé. Le zurg de production de `zen` surveille la même bibliothèque : il liste et actualise donc les torrents qu'un test vient d'ajouter. Toute instance sur le compte **avec la réparation activée** vérifie, répare et range aussi ces torrents.

Les deux échecs ci-dessous ont été diagnostiqués le 2026-08-23, alors que le zurg de `macmini` tournait sur ce compte avec la réparation toutes les 10 minutes. Cette instance a été arrêtée le 2026-08-29 et personne ne la surveille, et les runs de zen tournent avec `enable_repair: false`. Donc, depuis le 2026-09-01, aucun des deux échecs n'a de source active. Ils reviennent dès que la réparation est activée n'importe où sur ce compte, et c'est pour cela que la sérialisation décrite ci-dessous reste en place.

Voici ce que cela fait à un run, après que quatre des six scripts ont échoué sur le build testé *et* sur sa référence :

- **Une fixture qui n'apparaît jamais.** Real-Debrid déduplique les identifiants de téléchargement par lien, et supprimer une ligne de downloads révoque ce code pour tous ceux qui le détiennent. Le nettoyage d'une autre instance révoque le code que ce run vient de résoudre ; la vérification de ce run répond `404 invalid_download_code`, et zurg marque le fichier comme cassé. Un torrent cassé est masqué de toutes les listes. Le test affiche alors `zurg serves the fixture over HTTP but it never appeared under .../mnt/movies within 180s`, ce qui ressemble à un bug de montage ou de dircache, alors que ce n'est ni l'un ni l'autre.
- **Une suppression annulée.** Une instance qui répare re-ajoute un torrent que ce run vient de supprimer. Donc `refresh never dropped <hash> after it was deleted from the account` échoue, alors que la bibliothèque reflète correctement la réalité.

Ce sont les assertions de suppression et de réparation qui en pâtissent. Avant d'accuser un changement, lis le contexte d'échec décrit ci-dessous. Et si un run doit être propre, arrête d'abord la réparation des autres instances.

**Deux de ces scripts ne doivent jamais tourner en même temps**, sur cet hôte ou depuis une autre session sur celui-ci. Ils partagent le quota d'API par minute du compte : une paire déclenche `API rate limit (code=34)` et les assertions échouent à cause du trafic plutôt que du comportement (mesuré sur `fun`, deux runs en parallèle). Et chaque script supprime les torrents *par hash*, donc le nettoyage d'un run supprimera sans scrupule la fixture de l'autre. Chaque script prend donc un verrou à l'échelle de l'hôte au début de `main`, avant son premier appel API, et le garde jusqu'à sa sortie.

| Variable | Défaut | Description |
|----------|---------|-------------|
| `INTEGRATION_LOCK_FILE` | `$TMPDIR/zurg-integration-rd.lock` | Le verrou. `flock` là où il existe, un répertoire `.d` avec le pid dedans sinon (macOS ne fournit pas `flock`) |
| `INTEGRATION_LOCK_WAIT` | `0` | Secondes d'attente derrière un run en cours. `0` refuse immédiatement, ce qui est voulu : l'alternative est de rester une heure derrière un scan à froid |

Un verrou laissé par un run tué est récupéré automatiquement : le répertoire porte le pid du détenteur, et `flock` est libéré par le noyau. Le verrou n'indique bien sûr rien à zen ni à macmini. Il sépare seulement les runs de cet hôte.

**Lire un échec.** Chaque `fail` affiche désormais, à partir du log zurg de ce run : le nombre de chaque symptôme lié au compte partagé (`invalid_download_code`, `hoster_unavailable`, lignes de rate-limit, `code=34`, `Link verification failed`, `keeping files as broken`, `broken_file]`, `Deleted downloads entry`), puis les dix dernières de ces lignes, puis les dernières lignes qui mentionnent la fixture testée. `none present, so this failure is probably zurg's own and not the account's` est la ligne qui te dit d'aller regarder le code à la place.

`docs/realdebrid-behavior.txt` détaille la sémantique des liens qui sous-tend tout cela : quels liens se résolvent depuis quel compte, et pourquoi `unavailable_file` et `hoster_unavailable` ne veulent pas dire la même chose.

### Durée d'exécution {#runtime}

La première exécution sur un work dir donné paie un scan de bibliothèque à froid : un appel info et une vérification de lien par torrent, cadencés par le budget API du compte. Sur un compte de quelques milliers de torrents, cela prend des dizaines de minutes. Ce compte en comptait 3,361 le 2026-08-29, assez pour déclencher un `code=34` soutenu et faire durer un script une vingtaine de minutes. Le work dir conserve trois caches entre les exécutions pour que les suivantes les sautent : `info/`, `linkcache/` et les résultats des tests réseau. Supprimez le work dir pour forcer le chemin à froid.

`linkcache/` est ce que `internal/debrid.LinkCache` persiste, un fichier par instance de fournisseur. C'est la moitié qui supprime les vingt minutes : la première fois qu'un torrent est vu, l'un de ses liens est résolu pour être vérifié. Cela représente un appel `unrestrict/link` par torrent avec un cache vide, et rien avec un cache chaud. Le gain est limité par le TTL de 4h du cache : une nouvelle exécution de la suite le lendemain repart à froid. Cela accélère donc les itérations, pas une première exécution.

Ni `info/` ni `linkcache/` ne sont exempts de liens, et les deux contiennent des codes qu'une autre instance sur le compte partagé peut révoquer. Un `.zurginfo` est un `TorrentInfo` tel quel, donc il porte les codes `/d/` Real-Debrid du torrent, et `linkcache/` contient vers quoi ces codes ont été résolus. Les deux sont tout de même conservés. Les reconstruire est justement ce qui coûte les dizaines de minutes. Une entrée révoquée n'est pas pour autant une mauvaise réponse : la vérification reçoit `404 invalid_download_code`, zurg invalide cette entrée et en génère une nouvelle. Seules les entrées révoquées coûtent donc un appel. Comptez-en quelques-unes à chaque exécution, et attendez-vous à ce que l'accélération varie selon leur nombre.

Une fixture est encore plus restreinte : `clean_state_for_hash` supprime les entrées `info/` dont le hash correspond, donc sa liste de liens est toujours récupérée à nouveau depuis le compte. `linkcache/` est indexé par lien et non par hash, et n'est pas nettoyé par fixture. La *résolution* de l'un de ces liens peut donc encore provenir d'une exécution précédente. Cela n'affecte aucune assertion ici, car les fixtures testent le rafraîchissement, le routage, le montage et la réparation. Une résolution périmée échoue à la vérification et est régénérée avant que l'un de ces tests ne la voie.

### Test d'intégration Refresh/Repair {#refreshrepair-integration-test}

```bash
./integration/refresh_repair_integration.sh
```

La réparation automatique reste désactivée dans la config de test. Les deux requêtes explicites `/manage/{hash}/repair` contournent ce réglage et réparent leurs jeux de test.
Activer la réparation sans surveillance scannerait aussi et modifierait des entrées sans rapport dans le compte partagé, ce qui consommerait le budget d'API dont les assertions ont besoin.
`refresh_repair_config_test.sh` vérifie la config générée sans trafic vers le fournisseur, en utilisant l'entrée de test anonymisée capturée lors de l'échec du 2026-09-10.

| Scénario | Description |
|----------|-------------|
| 1. Rafraîchissement automatique (ajout) | Ajoute un torrent via l'API RD et attend que la boucle de rafraîchissement le détecte — pas de redémarrage, sinon on testerait le chemin de chargement à froid |
| 2. Attribution des dossiers et routage | Vérifie que les fichiers apparaissent dans les dossiers virtuels HTTP/DAV |
| 3. Persistance (redémarrage) | Redémarre zurg et vérifie que l'état en cache survit |
| 4. Rafraîchissement automatique (suppression) | Supprime le torrent et attend que le balayage des clés obsolètes le retire |
| 5. Déclenchement de la réparation | Déclenche la réparation via la Manage API, vérifie que zurg a journalisé qu'il a accepté la requête, et attend `ok_torrent` avec 0 fichier cassé |
| 6. Vérification de la réparation | Répare un second torrent et récupère une plage d'un fichier vidéo de celui-ci |

#### Variables d'environnement {#environment-variables}

| Variable | Par défaut | Description |
|----------|---------|-------------|
| `PORT` | `12345` | Port de l'instance zurg de test |
| `CONFIG_PATH` | `config.yml` | Fichier de config dont on emprunte les identifiants : le `token` du provider `realdebrid`, et les `username`/`password` de premier niveau |
| `TEST_HASH` | *(intégré)* | Hash du torrent pour les tests de refresh |
| `REPAIR_TEST_HASH` | *(intégré)* | Hash du torrent avec des fragments défectueux pour les tests de réparation |
| `VERIFY_TEST_HASH` | *(intégré)* | Hash du torrent pour les tests de vérification de réparation |
| `READY_TIMEOUT` | `120` | Secondes d'attente que zurg soit prêt |
| `INITIAL_SCAN_TIMEOUT` | `3600` | Secondes d'attente de la première passe de refresh complète |
| `REFRESH_TIMEOUT` | `120` | Secondes d'attente que le refresh prenne en compte un ajout ou une suppression |
| `REPAIR_TIMEOUT` | `300` | Secondes d'attente que la réparation se stabilise |
| `STREAM_LOGS` | `true` | Suivre le journal de zurg sur stderr |
| `ZURG_BIN` | `$(pwd)/zurg` | Chemin du binaire zurg — absolu, car zurg est lancé depuis le dossier de travail |
| `WORK_DIR` | `$TMPDIR/zurg-refresh-repair` | Dossier de travail (conservé entre les exécutions) |
| `WORK_DIR_CLEANUP` | `false` | Supprime le dossier de travail à la sortie, en effaçant les caches qui accélèrent les exécutions suivantes |

### Test d'intégration Force Location {#force-location-integration-test}

```bash
make force-location-test
```

Ce test ne fait pas partie de `make integration-test` : il faut le lancer volontairement. Mesuré sur
`fun` le 2026-08-29, les hôtes `nyk` forcés se résolvaient en enregistrements AAAA que le client de téléchargement contacte en `tcp4`, donc chaque HEAD se terminait par `no suitable address
found`. Avec trois tentatives chacun, l'analyse de la bibliothèque sur laquelle ce test attend patine pendant presque une heure avant d'échouer à cause du réseau de l'hôte plutôt que de zurg. Le test vérifie déjà si une région est défaillante (voir ci-dessous), mais cette vérification ne couvre pas le cas d'un hôte qui ne peut pas joindre une région *saine* en IPv4.

Prépare un cache de test réseau épinglé sur `LOCATION` (par défaut `nyk`), puis vérifie qu'un lien résolu via le point de terminaison `/strm/` de zurg redirige vers un hôte de téléchargement situé dans cette région. `MAX_GEO_PROBES` (par défaut `4`) limite le nombre de serveurs géographiques que l'étape de préparation interroge.

Avec `cdn_host_preference` défini, chaque lien que zurg vérifie passe par la région forcée. Si cette région est défaillante, la liste reste vide et l'échec ressemble à un bug de zurg. Le test vérifie donc d'abord la région, et il passe (skip) au lieu d'échouer lorsque Real-Debrid refuse de générer un lien pour elle ou lorsque l'hôte renvoyé ne sert pas les données.

### Test d'intégration Network Test Cache {#network-test-cache-integration-test}

```bash
./integration/network_test_cache_integration.sh
```

Lance zurg deux fois : le premier démarrage doit faire le test de latence et écrire `data/network_test_results.json`, le second doit charger ce fichier et ne refaire aucun test.

### Test d'intégration Rclone Mount {#rclone-mount-integration-test}

```bash
./integration/rclone_mount_integration.sh
```

Suit le chemin qu'emprunte réellement un lecteur — FUSE → HTTP de zurg → Real-Debrid :

| Étape | Vérification |
|------|-----------|
| 2 | zurg monte son propre point de montage et journalise `Mount verification successful` |
| 3 | les répertoires configurés sont visibles à la racine du point de montage |
| 4a–4c | le fixture entre dans la bibliothèque, est servi en HTTP et atteint le point de montage. Les étapes sont séparées pour qu'un échec indique le maillon cassé, et pas seulement « pas dans le point de montage » |
| 5 | lire le fichier via FUSE renvoie de vrais octets |
| 6 | arrêter zurg libère le point de montage |

L'étape 4c est la vérification du dircache VFS : le fixture n'atteint le point de montage que si la liste des répertoires a été invalidée, et non servie depuis une liste mise en cache avant l'arrivée du torrent.

La bibliothèque est restreinte par une regex construite à partir du nom du fixture, pour que le point de montage ne contienne qu'une seule release au lieu de tout le compte.

`MOUNT_PATH` vaut par défaut `$WORK_DIR/mnt`, jamais le `/mnt/zurg` de production. `RCLONE_BIN` vaut par défaut `$(pwd)/bin/rclone`.

### Test d'intégration Plex {#plex-integration-test}

```bash
./integration/plex_integration.sh
```

| Étape | Assertion |
|------|-----------|
| 2 | zurg journalise `Successfully connected to Plex server` |
| 3 | la fixture apparaît dans la bibliothèque, et si elle apparaît aussi dans le montage, elle doit être lisible (Plex la lit en tant qu'utilisateur à lui) |
| 4 | une nouvelle section jetable est créée sur `$MOUNT_PATH/movies` |
| 5 | zurg fait correspondre le chemin de sa bibliothèque à cette section et met en file d'attente un rafraîchissement **pour le chemin de la fixture** |
| 6 | Plex finit par indexer l'élément |

Le fait que la fixture apparaisse dans le montage est une condition préalable ici, et non l'assertion :
avec Plex configuré, zurg lance aussi son matcher sur toute la bibliothèque Plex,
ce qui entre en concurrence avec le rafraîchissement, si bien que le listing du VFS peut accuser un retard important.
Le test le signale et continue après `MOUNT_VISIBLE_TIMEOUT` (valeur par défaut `420`) —
les étapes 5 et 6 échouent déjà si Plex ne voit pas le fichier, et vérifier que l'invalidation fonctionne relève du test de montage.
`PLEX_URL` et `PLEX_TOKEN` remplacent `plex_server_url` et `plex_token` de la configuration.

Plex analyse automatiquement une nouvelle section et peut avoir fini avant que la création ne revienne.
Le test signale ce nombre initial d'éléments ; l'étape 5 vérifie de manière indépendante que zurg
met en file d'attente le bon chemin après une demande explicite de gestion.

La section est créée avec `agent=tv.plex.agents.none` et le scanner `Plex Video
Files`, afin que Plex indexe localement sans interroger un agent de métadonnées en ligne. Elle est supprimée à la sortie, y compris en cas d'échec, depuis le trap EXIT. Rien ne s'exécute en revanche sur SIGKILL : après une exécution tuée de cette façon, inspectez et supprimez uniquement votre propre section. Le harnais laisse intactes les sections préexistantes, car elles peuvent appartenir à une autre session. Les bibliothèques existantes ne sont jamais modifiées.

L'étape 5 demande à zurg d'exécuter les effets de bord via `POST /manage/{hash}/scan` plutôt que d'attendre une passe de rafraîchissement. Le déclencheur d'attribution de répertoire ne se déclenche qu'une fois, lorsqu'un torrent est découvert, ce qui se produit forcément avant que la section n'existe ; attendre la prochaine passe complète prendrait des dizaines de minutes sur un compte de quelques milliers de torrents.
Le mapping testé ne change pas : zurg doit toujours résoudre seul le chemin de sa propre bibliothèque vers la bonne section.

### Régression du benchmark Usenet {#usenet-benchmark-regression}

```bash
./integration/nzb_bench_integration.sh
make nzb-bench-test
```

Aucun autre test de la suite ne lit un octet via NNTP. Une modification du récupérateur d'articles, du décodeur yEnc, de la réparation PAR2 ou du lecteur d'archives pourrait diviser le débit par deux, doubler la mémoire, ou servir du silence à la place d'un article manquant, et tous les autres tests passeraient quand même. Celui-ci lit quatre releases préparées à travers un zurg temporaire et vérifie à la fois les chiffres et les octets.

**Pourquoi un A/B et pas un chiffre enregistré.** Le débit d'un serveur de news en direct varie de 10 à 20 % au cours d'une soirée. Six lectures de la même release ont oscillé entre 34 et 50 MB/s en une seule session. Une fourchette serrée par rapport à un chiffre noté la semaine dernière échouerait donc à cause de la météo et non du code. Le test mesure donc deux binaires dans la même fenêtre, sur le même hôte, en alternant l'ordre à chaque répétition pour que la mise en cache côté fournisseur profite aux deux, puis compare leurs médianes.

A est la référence : par défaut, le dernier tag `*-nightly` accessible depuis `HEAD`, extrait avec `git archive`, compilé une seule fois, puis mis en cache dans le dossier de travail pour que les exécutions suivantes le réutilisent. B est le candidat, le `zurg` que ce dépôt vient de compiler. **Une métrique échoue quand B est moins bon que A de plus de 5 %** (`BENCH_TOLERANCE`). Un meilleur résultat est signalé comme une amélioration, et une métrique absente d'un côté est `n/a` plutôt qu'une régression.

Pour chaque répétition, le test mesure une ouverture à froid, le temps avant le premier octet, une lecture de 64 MiB, la même lecture de 64 MiB refaite à chaud, un scrub à huit points, une lecture de 256 MiB avec les secondes CPU par gigaoctet et la RSS maximale à côté (Linux uniquement, les deux viennent de `/proc`), ainsi que la durée du conteneur lue par `ffprobe`.

La correction n'est vérifiée que sur le candidat, jamais au chronomètre. Chaque lecture enregistre un md5 qui doit correspondre à une constante enregistrée et être identique entre les deux binaires. La release endommagée doit servir les octets d'origine ou du silence, et rien d'autre. La réparation doit ensuite retrouver l'original et rester correcte après un redémarrage.

Le corpus est versionné dans `integration/nzbbench/corpus/` : six NZB pour six questions.

| NZB | Ce que c'est | À quoi ça sert |
|-----|------------|----------------|
| `ToyStory5.nzb` | un WEB-DL de 6.61 GB, 1 576 articles de 4 MiB | tous les chiffres de débit et de latence, et l'assertion ffprobe |
| `ToyStory5Damaged.nzb` | la même release, avec le message-id de l'article 21 corrompu, donc n'importe quel serveur répond `430` | le trou doit se lire comme les octets d'origine ou comme du silence, tout autre résultat est un bug de correction. Ensuite PAR2 doit le réparer, et la réparation doit survivre à un redémarrage |
| `Obfuscated.nzb` | le même film publié en sept fichiers sous `<hex> [n/7] yEnc`, dont le vrai nom n'est récupérable que depuis l'index PAR2 | les passes de nommage : il doit apparaître sous le vrai nom `.mkv` à la bonne taille, sans `.par2` visible |
| `FatherBrown.nzb` | une RAR en 11 volumes contenant un épisode, un dossier `Sample/` et un nfo | le lecteur d'archives : la structure des dossiers doit survivre, et les lectures à l'intérieur de l'archive ont leur propre chiffre de débit (`rar_read_MBps`, une lecture par répétition) |
| `WrongTurn3.nzb.gz` | un 7z stocké de 58 GB en 54 volumes de 1 GiB (le dernier plus petit) plus sept fichiers PAR2, un arbre BluRay UHD complet ; gzippé parce que le NZB fait 7 MB en clair | le lecteur 7z fractionné : les volumes doivent être assemblés et l'en-tête à la fin du dernier doit être lu avant que quoi que ce soit ne soit listé, et c'est ce listing qui est chronométré (`sevenzip_list_s`, une fois par répétition à partir d'une disposition vidée). Le flux du film de 57.6 GB doit ensuite renvoyer 16 MiB à 8 GiB avec le md5 enregistré, ce qui est une vérification de correction et non de temps. Pas de chiffre de débit : chaque volume de cette release manque d'environ un cinquième de ses articles chez ce fournisseur, donc une lecture chronométrée mesurerait la découverte des trous |
| `NestedRar.nzb` | un repost XviD sur deux CD : un jeu de volumes RAR5 externe dont les membres sont les volumes de deux jeux RAR internes, dans `CD1/` et `CD2/`, plus un clip dans `Sample/` et un nfo | le lecteur d'archives imbriquées : les deux jeux internes doivent être ouverts (le test plat refuse deux jeux comparables, et ce sont les dossiers du posteur qui les regroupent), avec les deux films listés à leur vraie taille et leur propre chiffre de débit (`nested_read_MBps`, une lecture par répétition) |

**Un compte, une instance.** Un second zurg sur un compte news se dispute avec le premier la limite de connexions, et le serveur refuse la *plus ancienne*. Sur `fun`, le `zurg-usenet` de production occupe toutes les connexions que le forfait du compte autorise. Le benchmark tourne donc à 10 (`BENCH_NNTP_CONNECTIONS`), et un refus `Too many connections` est signalé comme un **skip, pas comme un échec**. Il en va de même pour un serveur injoignable ou un `AUTHINFO` rejeté : l'environnement n'a pas pu répondre à la question, donc le test le dit au lieu d'accuser le build.

Comptez environ 15 à 20 minutes avec les quatre répétitions par défaut, plus quelques minutes ponctuelles la première fois que la référence doit être compilée.

| Variable | Par défaut | Description |
|----------|---------|-------------|
| `PORT` | `12358` | Port des instances zurg du benchmark (une à la fois) |
| `WORK_DIR` | `$TMPDIR/zurg-nzb-bench` | Contient la configuration générée, les dossiers d'exécution et les logs des deux binaires, `report.json` et le binaire de référence mis en cache. Conservé entre les exécutions : le `data/` persistant est ce qui fait que les répétitions suivantes mesurent un redémarrage et non un apprentissage à froid |
| `BENCH_ENV_FILE` | `~/.config/zurg/bench-account.env` | Fichier de compte, chargé s'il existe. Lignes `KEY=value` pour les variables `BENCH_NNTP_*`. **La façon officielle de donner au benchmark son propre compte**, et ce qui garde les identifiants hors du dépôt et de l'historique du shell |
| `CONFIG_PATH` | `config.yml` | Configuration dont emprunter le compte news, lorsque ni l'environnement ni le fichier de compte n'en désignent un : le bloc `nntp:` du premier fournisseur `type: nzb`. L'emprunt est refusé quand ce compte a déjà des connexions ouvertes ici, voir plus bas |
| `BENCH_NNTP_HOST` / `_PORT` / `_TLS` / `_USER` / `_PASS` | *(depuis `BENCH_ENV_FILE`, puis `CONFIG_PATH`)* | Le compte news. Une valeur exportée l'emporte sur le fichier de compte. Rien trouvé nulle part → skip |
| `BENCH_NNTP_CONNECTIONS` | `10` | Connexions ouvertes par le benchmark. C'est un plafond : un compte configuré pour moins garde son propre nombre |
| `BENCH_ALLOW_SHARED_ACCOUNT` | *(non défini)* | Mettre à `1` pour mesurer sur un compte emprunté qui a déjà des connexions ouvertes. Seulement quand vous avez confirmé que le compte a de la marge |
| `BASELINE_REF` | le dernier `*-nightly` accessible depuis `HEAD` | Ce à quoi comparer. Résolu après un `git fetch --tags` tenté au mieux |
| `BASELINE_BIN` | *(compilé depuis `BASELINE_REF`)* | Une référence précompilée, utilisée telle quelle. La solution pour comparer avec quelque chose qui ne se compile plus ici |
| `BENCH_REPS` | `4` | Répétitions par binaire. Les médianes sont calculées sur celles-ci |
| `BENCH_TOLERANCE` | `0.05` | De combien B peut être moins bon avant que ce soit une régression |
| `BENCH_SKIP` | *(aucun)* | Liste séparée par des virgules des phases à omettre : `repair`, `obfuscated`, `rar`, `ffprobe`. `ffprobe` est ajouté automatiquement quand il n'est ni dans le `PATH` ni dans `bin/` |
| `REPORT_JSON` | `$WORK_DIR/report.json` | Où le rapport est écrit |
| `STREAM_LOGS` | `true` | Suit le `zurg.log` du candidat sur stderr. La progression de l'outil est affichée dans tous les cas |

`report.json` contient chaque ligne par répétition pour les deux binaires, les médianes, les verdicts par métrique, la sortie `version` des deux binaires, ainsi que l'hôte et l'OS. Ainsi, un chiffre de ce fichier peut être relu avec le code qui l'a produit. Pour enregistrer une série de chiffres sans rien comparer, appelez directement l'outil avec un seul `--bin` : il mesure, écrit le JSON et se termine avec le code 0.

(Une traduction précédente a été refusée : les blocs de code différaient. La structure doit rester exactement la même.)

```bash
cd integration/nzbbench && go build -o /tmp/nzbbench . && cd -
/tmp/nzbbench --config /path/to/a-config-with-an-nzb-provider.yml --port 12358 \
  --corpus integration/nzbbench/corpus --work /tmp/nzbbench-record \
  --bin candidate=./zurg --out /tmp/record.json
```

La config doit être la tienne : celle que génère le wrapper contient le mot de passe du compte news en clair et elle est supprimée à la fin de l'exécution.

`integration/nzbbench/README.md` documente les options propres à l'outil et ses codes de sortie.

**Codes de sortie de `nzb_bench_integration.sh`.** `0` : la comparaison a été faite et a réussi, ou la machine ne pouvait pas du tout faire de benchmark et le run a été ignoré ; `1` : une assertion fonctionnelle a échoué ou une métrique a régressé ; `4` : toutes les assertions fonctionnelles ont réussi et le contrôle de timing n'a **pas été jugé** -- le serveur news a dépassé la limite de stabilité de l'outil pendant la fenêtre, donc la comparaison du débit et de la latence a été écartée. 4 n'est volontairement ni le 1 d'un build cassé ni le 0 d'un skip : rien n'a été tranché sur les performances, la réponse est de relancer dans une fenêtre plus calme, et le run affiche une bannière qui nomme le contrôle et les écarts qui l'ont fait échouer. `make integration-test` transforme chaque ligne de recette en échec en code de sortie 2 de make ; une exécution de la suite fait donc remonter un make en erreur plus cette bannière, au lieu de la ligne « All integration tests passed. » de la cible. Appelle le script directement si quelque chose doit réagir au 4 lui-même.

### Prérequis {#prerequisites-1}

- Jeton Real-Debrid dans `config.yml` (comme fournisseur `realdebrid`) ou `RD_TOKEN`
- `curl`, `python3` et un binaire zurg compilé
- `shellcheck` pour `make lint-integration` (ignoré avec un avertissement s'il est absent)
- Pour les tests de montage et de Plex : `fusermount`/macFUSE, un binaire rclone et
  `user_allow_other` dans `/etc/fuse.conf` pour que Plex puisse lire le montage
- Pour la vérification du refus de move : le rclone corrigé issu de
  `scripts/build-rclone-move-fix.sh`, défini à la fois dans `RCLONE_BIN` et
  `RCLONE_TEST_BIN`. Un rclone upstream plus récent et non corrigé ne suffit pas. Voir [la régression MOVE](rclone-move-refusal.md).
  Fournissez un binaire d'aide déjà compilé via `DOTNET_MOVE_PROBE_BIN`, ou Docker pour le compiler.
  Si vous le compilez avec un utilisateur de conteneur non privilégié, donnez à .NET un `XDG_DATA_HOME` accessible en écriture, ainsi que ses répertoires de cache CLI et NuGet.
- Pour le benchmark Usenet : un compte de news, plus Go, `git`, `tar` et `make` —
  il construit sa référence à partir d'un `git archive` d'un tag nightly

### Donner au benchmark son propre compte news {#give-the-benchmark-its-own-news-account}

Une allocation de connexions appartient au **compte**, pas à un processus. Si tu diriges le benchmark vers le compte sur lequel une instance de production est déjà connectée, les deux se partagent le forfait, et le serveur refuse alors le détenteur de connexion le plus ancien : la production, qui ne sait rien du benchmark à l'origine du problème.

Le benchmark n'emprunte donc `CONFIG_PATH` qu'en dernier recours, et **refuse d'emprunter un compte qui a déjà des connexions ouvertes sur cette machine**. Donne-lui un compte à lui dans `~/.config/zurg/bench-account.env` :

```
BENCH_NNTP_HOST=news.example.net
BENCH_NNTP_PORT=563
BENCH_NNTP_TLS=true
BENCH_NNTP_USER=...
BENCH_NNTP_PASS=...
BENCH_NNTP_CONNECTIONS=25
```

Choisis un compte avec une marge dont rien ne dépend : un serveur dont le plafond mesuré est largement au-dessus de ce que n'importe quelle instance est configurée pour utiliser, pour que le benchmark ne puisse pas priver un lecteur de connexions. Ce qui est exporté en ligne de commande reste prioritaire sur le fichier, et `BENCH_ALLOW_SHARED_ACCOUNT=1` lève le refus si tu as confirmé que la marge existe.

### Pas dans la suite {#not-in-the-suite}

`rename_integration.sh`, `tag_stats_integration.sh` et `test_repair_verification.sh` ne sont pas lancés par `make integration-test`. Ils contiennent encore leurs propres copies des helpers d'avant `lib.sh`. Porte-les sur `lib.sh` et donne-leur des ports qui n'entrent pas en conflit avant de les brancher.
