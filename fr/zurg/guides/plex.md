# Fonctionnalités et capacités de Plex {#plex-features--capabilities}

Faire tourner rex à côté de Plex Media Server, ou à la place ? [Passer de Plex à rex](../../rex/from-plex.md) indique ce qu'il faut garder dans zurg, y compris ton montage rclone, et quels réglages Plex de zurg supprimer.

## Configuration et stockage {#configuration--storage}
- Clés de configuration documentées dans [`config.md`](../reference/config.md)/`config.example.yml` : `plex_server_url`, `plex_token`, `plex_match_every_mins` (valeur par défaut 1440), `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` (l'ancienne écriture de `watchlist.check_every_secs`, valeur par défaut 60 s), `mount_path` (obligatoire pour la correspondance et la construction des chemins d'analyse). Les paramètres saisis depuis le tableau de bord sont enregistrés directement dans `config.yml` via l'écrivain de configuration (`updateConfigFileAtomic`).
- L'intervalle de la watchlist revient à sa valeur par défaut pour toute valeur inférieure ou égale à 0 (`GetWatchlistCheckEverySecs`). `plex_match_every_mins` ne revient à sa valeur par défaut que s'il vaut exactement `0` (`intOr`, `internal/config/config.go`). Ni l'un ni l'autre ne peut être désactivé. Le tableau de bord refuse toute valeur inférieure à 1 (`internal/handlers/dashboard/dashboard.go`). Si `plex_match_every_mins` est négatif dans `config.yml`, zurg s'arrête au démarrage avec `is negative; use 0 for the default`. Il ne désactive jamais la correspondance.
- L'acquisition de la watchlist se configure avec le bloc `watchlist:` : `enabled`, `check_every_secs`, `indexers`, `max_size_gb`, `max_season_size_gb` et `quality` (valeur par défaut `best`). Si `indexers` est vide, il reprend `stremio.indexers`. Les clés plates `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` et `watchlist_quality` sont toujours acceptées comme anciennes écritures des trois premières de ces options. Voir [config.md](../reference/config.md#watchlist).
- `mount_path` est aussi le préfixe des chemins d'analyse envoyés à Plex et au montage rclone géré ([`config.md`](../reference/config.md), `pkg/scan/scanner.go`).
- Le hook `on_library_update` reçoit chaque chemin modifié en arguments. Il est temporisé 500 ms et dédupliqué, avec une seule invocation à la fois. Cela permet d'utiliser des scripts d'autoscan Plex (`internal/torrent/hooks.go`).

## Authentification et découverte du serveur {#authentication--server-discovery}
- Flux du tableau de bord web : `/plex/auth` crée une session PIN (`pkg/plex/auth.go`, `CreatePlexAuthURL`), la stocke dans `pkg/plex/auth_session.go` (nettoyage automatique après 10 min, vérifié toutes les 5), puis interroge l'état de l'autorisation via `/plex/auth/status` (`PollForAuthToken`, 60 tentatives espacées de 5 s avant l'expiration du délai).
- `/plex/callback` affiche une page de progression qui, une fois l'autorisation accordée, appelle `/plex/servers` pour lister les serveurs et `/plex/server` pour en sélectionner un (`internal/handlers/dashboard/dashboard.go`).
- Découverte des serveurs (`pkg/plex/auth.go`) : récupère les ressources Plex avec les points de terminaison HTTP et HTTPS, filtre les relais si une connexion directe existe, gère les adresses IPv6, et teste chaque entrée en interrogeant son `/identity` (vérification TLS désactivée). Seuls les serveurs **possédés** par le compte sont pris en compte (`device.Owned`, `auth.go`) : les serveurs partagés n'apparaissent jamais. Les entrées qui échouent au test sont retirées de la réponse, au lieu d'être renvoyées avec `last_error` renseigné (`enrichServersWithIdentity`, `auth.go`).
- Sélectionner un serveur écrit `plex_server_url`/`plex_token` dans la configuration, réinitialise le client Plex, (re)démarre le planificateur du matcher, déclenche une correspondance, et actualise le cache du statut du tableau de bord (`HandlePlexServerSelect`, `internal/handlers/dashboard/dashboard.go`). `/plex/logout` efface les valeurs enregistrées et le cache du statut.

## Capacités du client Plex (`pkg/plex/client.go`) {#plex-client-capabilities-pkgplexclientgo}
- **Cycle de vie de la connexion** : option de démarrage différé (`WithDeferredStart`), garde `ValidateConnection` contre `/identity`, et `Close` proprement. Il n'existe pas d'API de redémarrage. Les `RestartAllowed`/`RestartReason` du dashboard sont déduits de l'URL du serveur (local/LAN ou distant) et ne servent qu'à l'affichage (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`).
- **File d'attente des scans** : file de tâches dynamique et worker (`common.DynamicJobQueue`). `ProcessJob` envoie `GET /library/sections/{key}/refresh` avec les en-têtes Plex et **au plus un** paramètre de requête `path` par tâche. Plus d'un est refusé net (`client.go`). Une tâche sans chemin est un rafraîchissement complet de la section. Un 503 devient une erreur de serveur occupé, un 404 signale que la bibliothèque a été supprimée de Plex, et `GetJobQueueSize` expose le retard accumulé.
- **Détection de charge et de blocage** : `CheckServerLoad` inspecte `/activities`, suit la progression de `library.update.section` par UUID (une progression modifiée *ou* un sous-titre modifié compte comme progression), et `IsJobStuck` signale les tâches bloquées à partir de `librarySectionID`, avec un repli sur le Title. `GetServerActivitiesDetails` crée et retire les mêmes trackers. En effet, `CheckServerLoad` ne tourne que lorsque le worker a une tâche en file. Avant, un scan lancé par Plex tout seul n'avait aucun tracker. Il ne pouvait donc jamais être signalé comme bloqué, et son temps écoulé restait à zéro à chaque rafraîchissement. Les deux chemins ne gardent l'historique que pour `library.update.section`. Suivre autre chose ici ferait osciller les trackers face à la purge du worker.
- **Le sous-titre de l'activité n'est pas le fichier sur lequel un scan en attente est bloqué.** Mesuré sur le rig plex503 le 2026-09-15 : le sous-titre `library.update.section` est le pointeur d'énumération du scanner, et il va plus vite que les lectures. Avec le montage qui refusait trois fichiers, il a nommé un quatrième qui n'avait jamais été demandé, et il a nommé le fichier bloqué pendant 290 ms sur un cycle de 56 s. Le dashboard l'affiche sous « Plex reports » et ne le relie à aucune release. Ce sur quoi le scan attend vraiment vient des refus de zurg eux-mêmes (`internal/universal/refused_reads.go`). C'est le seul côté qui le sait. Le corpus se trouve dans `internal/handlers/dashboard/testdata/plex503-*`.
- **Requêtes sur la bibliothèque** : `GetSections` (sections films/séries avec leurs emplacements), `GetSectionItemCount`, `FindSectionNormalized` (fait correspondre un chemin à un emplacement de section et corrige le préfixe selon la casse de la bibliothèque), `GetAllMediaItemsConcurrent` (récupération par lots et en parallèle avec `includeGuids` pour collecter les chemins, les GUID et les IDs IMDB), et `GetShowLevelIMDBIndex` (IDs au niveau de la série pour les sections TV, afin que les épisodes puissent en hériter).
- **Aides pour les métadonnées et la correspondance** (`pkg/plex/match.go`) : `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`), `GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`, avec des surcharges de titre/année/langue), `LookupMetadataByGUID`/`LookupRatingKeyByGUID` (`GET /library/all?guid=…`), `ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`), et l'analyse des GUID (`ExtractIMDBIDFromGUID`, `ExtractTMDBIDFromGUID`, `ExtractTVDBIDFromGUID`, `ExtractAnyIDFromGUIDs` ; types `MatchResult`/`MatchSelection`).
- **Infos serveur** : `GetServerIdentityOnly` et `GetServerDetails` (ID machine/version ; ce dernier totalise aussi les sessions/transcodages/bande passante), `GetStreamingSessions`, `GetTranscodeSessions`, `GetServerActivitiesDetails` (annoté avec le statut de blocage).
- **Historique de visionnage** : `GetWatchHistory` (`GET /status/sessions/history/all`), `GetMetadataBatch` (clés de notation réunies par des virgules sur `/library/metadata`), et `GetWatchHistoryWithMetadata` (`pkg/plex/history.go`), qui alimentent les statistiques de `pkg/plex/stats.go`.

## Intégration du scanner de médias (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- Initialise le client Plex lorsque `mount_path`, `plex_server_url` et `plex_token` sont définis ; réessaie toutes les 5 s jusqu'à la connexion, en déclenchant les callbacks `OnPlexReconnected`.
- `TriggerScan` regroupe les chemins par section Plex (via `FindSectionNormalized`) et met en file d'attente une tâche de rafraîchissement par chemin préfixé par mount_path, en journalisant la progression toutes les 50 tâches. Prend aussi en charge Jellyfin/Emby, qui utilisent le chemin non regroupé. Un chemin qui ne correspond à aucune section n'affiche un avertissement que si *aucun* des chemins du lot n'a été trouvé. Sinon, c'est une ligne de débogage : ainsi, un torrent présent à la fois dans un dossier de bibliothèque et dans un dossier réservé à zurg (recent, music, …) n'affiche pas d'avertissement.
- `ReinitializePlexClient` permet aux mises à jour du tableau de bord de changer de serveur ou de token à chaud.
- `GetQueueSizes` expose la profondeur de la file d'attente Plex pour l'interface et le monitoring.

## Correspondance et synchronisation des métadonnées (`internal/plex/matcher.go`, `internal/plex/schedule.go`) {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- Préconditions : nécessite une URL et un token Plex configurés, `mount_path`, et un `scanner.PlexClient` actif ; sinon elle renvoie des erreurs explicites.
- Le seul état Plex stocké sur un torrent est `PlexRatingKey` (au niveau de la série pour les contenus en épisodes) plus `IMDBID` (`internal/torrent/torrent_types.go`). Les GUID Plex sont utilisés pendant le traitement pour l'extraction d'ID et les rapports, mais ne sont jamais enregistrés.
- Collecte des données : récupère tous les torrents de la map des répertoires et tous les éléments Plex via `GetAllMediaItemsConcurrent`, précédé d'une passe `GetShowLevelIMDBIndex` pour que les épisodes héritent de l'ID IMDB/TVDB/TMDB de la série au lieu d'un ID propre à l'épisode. Les éléments sont indexés par `GrandparentRatingKey` quand il est présent.
- Étapes de synchronisation :
  - Valide chaque rating key stocké par rapport aux éléments Plex fraîchement récupérés ; une clé que Plex ne possède plus est effacée avec l'ID IMDB du torrent, et le torrent est remis en file d'attente pour le matching.
  - Matching par chemin pour les torrents sans rating key : `buildPlexDirIndex` indexe chaque composant de chemin en minuscules de chaque fichier Plex, et le `GetKey` du torrent y est recherché (O(1), la première entrée gagne). Les torrents dont les répertoires assignés ne correspondent à aucun emplacement de section Plex sont ignorés en premier.
  - Remplissage de l'IMDB : d'abord à partir du lot déjà récupéré (sans appel API), puis torrent par torrent via `GetMetadataSummary` (20 en parallèle au maximum).
  - Détecte les éléments Plex sans torrent.
  - Envoie à DMM les paires hash+IMDB saisies à la main par une personne, jamais les ID devinés par Plex ; DMM les accepte sans clé, et `dmm_api_key` est joint quand il est défini (`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`, `internal/torrent/mediainfo.go`).
- `MatchSingleTorrent` exécute la même recherche par chemin pour un seul torrent, à utiliser juste après un scan ciblé ; il ne fait rien si le torrent a déjà un rating key.
- Rapports : écrit `logs/match_report.txt` avec le nombre de résultats, les torrents non associés, les torrents ignorés, les éléments Plex sans torrent et les correspondances sans IMDB.
- Planification (`internal/plex/schedule.go`) : chaque exécution terminée écrit l'horodatage `data/plex_match_timestamp`. Au démarrage, `StartMatchingJob` ne lance la tâche immédiatement que si cet horodatage est absent ou plus ancien que `plex_match_every_mins` ; sinon il attend la fin du délai restant. Il écoute les déclencheurs manuels sur `TorrentManager.PlexMatchTrigger`, les changements d'intervalle en direct sur `ResetPlexMatchTicker`, et relance la tâche jusqu'à trois fois si elle plante.
- Le point de terminaison de déclenchement manuel `/plex/match-torrents` envoie un signal au canal de déclenchement et refuse si une exécution est en cours ; `/plex/match-torrents/status` indique si une exécution tourne (`internal/handlers/utilities.go`).

## Correspondance manuelle et interface de gestion (`internal/handlers/manage`) {#manual-matching--manage-ui-internalhandlersmanage}
- Les filtres de la liste des torrents exposent des états Plex (`plex_matched`, `plex_in_library_not_matched`, `plex_no_imdb`, `plex_missing_metadata`) pour des vues rapides (`torrent_list_state.go`).
- Page de correspondance manuelle par torrent `/manage/{hash}/plex-match` :
  - Le torrent doit déjà avoir un `PlexRatingKey` (défini par le matcher), sinon la page affiche « torrent is not linked to Plex ». `resolvePlexRatingKey` valide cette clé avec `GetMetadataSummary`, complète un ID IMDB manquant à partir de celle-ci, et si la clé est obsolète, la re-résout via `LookupRatingKeyByGUID` à l'aide de l'ID `tt…`/`tvdb://`/`tmdb://` stocké pour le torrent (`internal/handlers/manage/handler.go`).
  - Récupère les candidats de correspondance manuelle Plex avec des remplacements facultatifs pour le titre, l'année et la langue (44 options de langue, par défaut `en-US`) ; affiche les correspondances en mettant en évidence la sélection actuelle (`torrent_matches.go`).
  - Appliquer une correspondance (`HandleApplyPlexMatch`) appelle `ApplyManualMatch`, puis relance la recherche de la clé par le GUID choisi, car Plex peut la réattribuer. Il met à jour la clé et l'IMDB du torrent (y compris un IMDB facultatif fourni par l'utilisateur), enregistre les changements et redirige avec les états de succès ou d'erreur.

## Acquisition depuis la liste de suivi {#watchlist-acquisition}

- La liste de suivi Plex est un adaptateur dans `internal/acquisition/plex`. Il tourne sur le service d'acquisition partagé, aux côtés de Seerr. Les paramètres existants de la liste de suivi fonctionnent toujours. Les adaptateurs peuvent aussi être configurés sous `acquisition.sources`.
- Le client utilise `discover.provider.plex.tv` et récupère les éléments par pages de 100. Le jeton Plex est relu à chaque requête, donc une réauthentification s'applique sans redémarrer l'adaptateur.
- L'exécuteur partagé acquiert les films, ou chaque saison prévue, auprès des indexeurs Newznab et Torznab, en privilégiant les packs de saison. Pour les recherches de séries, TVDB est essayé avant IMDb, car les correspondances des indexeurs diffèrent.
- La progression, les échéances de nouvelle tentative et les reçus par épisode sont conservés après un redémarrage dans `data/acquisition.json`. L'ancien registre Plex est importé automatiquement.
- La suppression intervient après l'acquisition de toutes les cibles prévues. Les requêtes échouées restent sur la liste de suivi et sont relancées avec une temporisation progressive persistante. Une nouvelle tentative de suppression seule n'relance pas l'acquisition. Consultez [Acquisition de la liste de suivi Plex](plex-watchlist.md) pour les limites et [sources d'acquisition](acquisition.md) pour la configuration partagée.

## Tableau de bord et points de terminaison API (`internal/handlers/router.go`, `internal/handlers/dashboard`) {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- Routes : `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`.
- Le tableau de bord affiche les infos et le statut du serveur Plex via `PlexStatusFetcher`, avec deux minuteurs : toutes les 30 s, il rafraîchit les sessions de streaming, les transcodages, la bande passante et les activités du serveur (`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`) ; toutes les 5 minutes, il fait une récupération complète qui relit aussi l'identité (`GetServerIdentityOnly`), les sections de la bibliothèque et le nombre d'éléments par section. Les activités de scan sont rapprochées de la liste des torrents par nom de fichier, pour que le tableau de bord puisse lier une activité à un hash de torrent.
- Les endpoints de scan (par section et global) mettent en file d'attente un rafraîchissement **complet** de la section (`RefreshSection(key, nil)`, sans chemin) pour une section ou toutes les sections ; ils ne touchent pas aux fichiers STRM et ne déclenchent pas d'effets de bord sur la bibliothèque (`HandlePlexScan`/`HandlePlexScanAll`).

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- `/plex-stats` affiche un récapitulatif de l'année en 9 diapositives, à partir de l'historique de visionnage Plex des 12 derniers mois ; `/plex-stats/data` renvoie les mêmes statistiques au format JSON, et `/plex-stats/image` génère un PNG prêt à partager via headless chromedp (`square` 1080x1080 par défaut, `instagram` 1080x1920, `facebook` 1200x630).
- Les statistiques sont récupérées au maximum une fois toutes les 24 h (`?refresh=true` force la mise à jour), limitées à 10000 éléments d'historique, et mises en cache à la fois en mémoire et sur le disque dans `data/plex_wrapped_cache.json`, rechargé au démarrage. Pendant qu'une récupération est en cours, la page affiche un état de chargement au lieu de bloquer.

## Effets secondaires sur la bibliothèque et liens de rafraîchissement {#library-side-effects--refresh-links}
- Les effets de bord de la bibliothèque se déclenchent lors des changements d'affectation de dossier, des renommages, des suppressions et des réparations de fichiers : `TriggerLibrarySideEffects` invalide le dircache rclone VFS pour les chemins concernés (afin que les serveurs multimédias ne scannent pas une liste périmée), appelle `MediaScanner.TriggerScan` (ce qui déclenche le rafraîchissement de Plex) et exécute le hook `on_library_update` de l'utilisateur (`internal/torrent/hooks.go`).
- Le pipeline de rafraîchissement ne lance la génération STRM et les effets de bord qu'une fois l'initialisation terminée, pour éviter des scans Plex prématurés (`internal/torrent/refresh.go`).

## Infrastructure et scripts {#infrastructure--scripts}
- Exemple de vhost Nginx pour faire passer le trafic Plex en proxy (`nginx/plex.conf`).

- `plex_update.sh` est le script de référence pour l'analyse partielle, utilisé avec `on_library_update: sh plex_update.sh "$@"`. Place-le à côté de `docker-compose.yml`, dont le dossier est monté dans `/config`, donc le script est déjà dans le conteneur. Sous Windows, le hook passe par PowerShell et non par `/bin/sh` (`pkg/script/script.go`), donc ce script ne fonctionne pas là-bas ; [Usenet → Indiquer le script à Plex](usenet.md#6-point-plex-at-it) montre la forme PowerShell.

- `integration/plex_integration.sh` s'exécute avec `make integration-test` et `make integration-test-media` ; sur une machine sans serveur Plex, il saute les tests en le signalant bien haut, donc lis la sortie plutôt que le code de retour. `scripts/plex-e2e-test.sh` est un test de lecture autonome qui lit `plex_server_url`/`plex_token` dans `config.yml`.

## Paramètres Plex recommandés {#recommended-plex-settings}

Les réglages par défaut de Plex supposent des disques locaux toujours présents et faciles à lire. Un montage zurg n'est ni l'un ni l'autre : ses données viennent d'un fournisseur en HTTP, et il peut être brièvement illisible pendant que rclone se reconnecte. Plusieurs réglages par défaut de Plex sont carrément nuisibles dans ces conditions.

zurg réapplique ces réglages à chaque rafraîchissement du statut Plex. `plex_settings_policy` détermine jusqu'où il va : `off`, `warn`, `guard` (par défaut) ou `enforce`. La liste se trouve dans `pkg/plex/settings.go` (`RecommendedSettings`) ; la politique se trouve dans `pkg/plex/reconcile.go`.

Un réglage que le serveur ne signale pas est ignoré, donc une version de Plex qui ne le possède pas n'est pas signalée comme mal configurée.

Neuf des seize valeurs ci-dessous diffèrent de la valeur par défaut de Plex ; les sept autres lui sont identiques et servent de garde-fous plutôt que de corrections, ne se déclenchant que si l'opérateur en a activé un. Ces lignes affichent la même valeur dans les deux colonnes, et ce n'est pas une erreur : Plex livre `GenerateBIFBehavior` à `never`, alors que le serveur sur lequel ces valeurs ont été mesurées était réglé sur `scheduled`. Plex indique sa propre valeur par défaut pour chaque réglage dans `/:/prefs`, donc la colonne « Plex livre » ci-dessous est lue sur le serveur et non supposée (mesuré le 2026-09-05 sur Plex 1.42.2).

### Désactiver un seul paramètre {#opting-out-of-one-setting}

`plex_settings_policy` fonctionne par niveaux, et le niveau n'est pas toujours la question posée. Si tes fichiers passent d'un dossier de bibliothèque à un autre (par exemple un tri piloté par des tags), tu dépends de Plex pour vider sa propre corbeille afin de supprimer l'entrée restée derrière, et `guard` désactive cela. Passer à `warn` pour le récupérer fait aussi perdre les garde-fous des événements du système de fichiers, qui sont du même niveau et ne correspondent pas à ce que tu voulais.

`plex_settings_ignore` liste les réglages un par un :

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

C'est le tableau de bord qui remplit celui-ci pour toi. La page de configuration a un interrupteur **Let Plex Empty Its Own Trash** au-dessus des réglages Library Trash Sweep. Il ajoute et retire `autoEmptyTrash` ici, sans toucher au reste de la liste. L'activer prend effet au prochain redémarrage.

Un réglage ignoré est toujours lu et toujours affiché sur le tableau de bord et dans `zurg plex-settings` (marqué `skip`), donc rien n'est caché. Il n'est simplement jamais écrit, jamais compté comme un problème, et il n'apparaît jamais derrière la bannière de corbeille du tableau de bord. Les identifiants sont comparés sans tenir compte de la casse ; un identifiant qui ne correspond à aucun réglage des tableaux ci-dessous est signalé au démarrage, et le réglage reste sous garde, car une faute de frappe ne doit pas passer pour un refus.

Ignorer un réglage de sécurité, c'est à tes risques et périls, et zurg le rappelle une seule fois au démarrage plutôt qu'à chaque actualisation. `autoEmptyTrash` en particulier est le réglage qui vide une bibliothèque lorsqu'un scan tombe sur un montage qui a eu un raté. L'ignorer confie aussi la tâche de nettoyage à Plex — voir ci-dessous.

### Qui vide la corbeille {#who-empties-the-trash}

Désactiver `autoEmptyTrash` laisse un travail en suspens. Plex a reçu l'ordre de ne pas vider les entrées dont les fichiers ont disparu. Pendant longtemps, la suppression propre à zurg était facultative, donc par défaut une bibliothèque accumulait des entrées mortes et rien ne les nettoyait. Aucun des deux n'avait tort, et le trou était bien réel : c'est ce qu'on rencontre quand un fichier est déplacé entre dossiers de bibliothèque et que l'ancienne entrée reste à jamais.

zurg reprend maintenant le travail qu'il avait abandonné. Si `plex_trash_sweep_every_mins` n'est pas défini, le [balayage de la corbeille](../internals/plex-trash-sweep.md) supprime les entrées toutes les 60 minutes, mais seulement quand rien d'autre ne le fait. Si Plex vide encore sa propre corbeille, parce que `plex_settings_policy` vaut `off` ou `warn`, ou parce que `autoEmptyTrash` figure dans `plex_settings_ignore`, zurg se retire et laisse faire Plex. Deux collecteurs sur une même bibliothèque, c'est la façon dont un désaccord entre eux se transforme en suppression.

Le balayage est beaucoup plus restreint que le vidage de Plex, et c'est pour cela qu'on le préfère : il supprime une entrée à la fois, jamais une entrée qui a encore un fichier, seulement depuis un montage lisible à cet instant, avec une limite de 50 suppressions et 10 % de la corbeille par passe. Les entrées pour lesquelles il n'a pas de verdict restent d'abord visibles comme cassées pendant 14 jours. Il faut aussi définir `plex_database_path`, donc il ne fonctionne que là où Plex tourne sur cette machine, et que zurg gère lui-même le montage (`rclone_enabled` avec `mount_path` défini). zurg lit cette base avec le programme `Plex SQLite` que Plex installe, et le trouve là où l'installeur de Plex le place sous Linux, macOS et Windows. La seule clé à définir est donc `plex_database_path` :

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
Gardez les guillemets simples : entre guillemets doubles, YAML lit le backslash comme un caractère d'échappement. Ne définissez `plex_sqlite_binary` que pour un Plex installé ailleurs, par exemple un Plex 32 bits : `'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`.
+++

Remplacez `YOU` par votre nom d'utilisateur : zurg ne développe ni `~` ni `%LOCALAPPDATA%`. Le balayage fait correspondre les chemins que Plex stocke avec `mount_path`, ce qui gère une lettre de lecteur comme `Z:` (`pkg/utils/path_within.go`).

Pour désactiver la suppression et vider la corbeille vous-même, écrivez `plex_trash_sweep_every_mins: 0`. C'est le non explicite, qui est différent de l'absence de la clé.

Cette clé désactive seulement la suppression propre à zurg. Elle ne rend pas le réglage de Plex. Avec `guard`, zurg écrit toujours `autoEmptyTrash` à off, donc Plex ne videra toujours pas sa corbeille après un scan, et les entrées s'accumulent sans rien pour les nettoyer. Utilisez l'interrupteur du tableau de bord ou `plex_settings_ignore` pour rendre ce travail à Plex.

### Sécurité — corrigée sous `guard` et `enforce` {#safety--corrected-under-guard-and-enforce}

Ces réglages font perdre des données plutôt que du temps, c'est pourquoi la politique par défaut les écrit au lieu de simplement avertir. Seul `autoEmptyTrash` est livré avec sa valeur destructrice ; les trois autres sont déjà réglés comme zurg le veut et sont là pour repérer un opérateur qui en aurait activé un.

| Préférence | Valeur par défaut de Plex | Valeur voulue par zurg | Pourquoi |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | Plex vide sa corbeille après chaque analyse. Si le montage devient brièvement illisible pendant qu'une analyse le parcourt, chaque fichier apparaît comme supprimé, et Plex les supprime définitivement au lieu de les laisser dans la corbeille pour qu'ils reviennent avec le montage. |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | Les mises à jour pilotées par événements passent à côté de ce qui change vraiment ici. L'arborescence de zurg change de son côté, ce qui ne passe jamais par le noyau local : aucun événement n'est levé, et la bibliothèque devient silencieusement obsolète. Les événements qui arrivent sont des écritures faites *à travers* le montage, qui se produisent pendant qu'un dossier est encore en cours d'assemblage. |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | Une analyse partielle repose sur ces mêmes événements : elle se déclenche donc sur les écritures qui passent par le montage, exactement au moment où un dossier est à moitié écrit, et jamais sur les changements côté distant qui nécessiteraient vraiment une analyse. |
| `ButlerTaskBackupDatabase` | `1` | `1` | La sauvegarde nocturne de la base de données est la seule chose qui permet de récupérer une bibliothèque que Plex a déjà supprimée. |

Les deux raisons `FSEvent` ont été réécrites après mesure, sur chaque plateforme sur laquelle zurg monte. La formulation précédente disait qu'un montage FUSE « ne les émet pas de façon fiable, donc cela produit des analyses à des moments que personne n'a demandés ». Les deux parties de cette phrase sont fausses.

Mesuré le 2026-09-05, chaque plateforme surveillée avec l'API qu'utilise réellement son serveur multimédia, sur un montage rclone dont le répertoire source pouvait être modifié directement. **A** est une écriture faite à travers le montage ; **B** est le même fichier qui apparaît de l'autre côté, comme cela se produit quand l'arborescence de zurg change.

| Plateforme | Montage | Surveillé avec | A : à travers le montage | B : modifié de l'autre côté |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **aucun événement** |
| Docker | même montage, monté dans un conteneur | inotify, à l'intérieur du conteneur | les mêmes quatre, vus dans le conteneur | **aucun événement** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **aucun événement** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **aucun événement** |

Toutes les plateformes ont détecté A, et un témoin réalisé pendant le même essai sur un système de fichiers natif (APFS, NTFS) a produit les mêmes événements : les surveillants fonctionnaient. Aucune n'a détecté B, bien que le fichier soit visible à travers le montage une fois le cache du répertoire expiré.

Le mode de défaillance est donc l'inverse de ce qui était affirmé : une mise à jour pilotée par événements se déclenche sur les écritures qui passent *à travers* le montage (un import d'un \*arr qui arrive dans un dossier encore en cours d'assemblage), et ne se déclenche jamais pour les changements côté distant, qui sont justement la raison de lancer une analyse. Ce n'est pas que les événements sont peu fiables ; c'est qu'ils rapportent la mauvaise moitié de ce qui se passe sur un montage debrid.

### Bande passante — corrigée uniquement sous `enforce` {#bandwidth--corrected-under-enforce-only}

Chacun de ces réglages fait décoder à Plex des fichiers entiers pour un résultat que personne ne regarde. Sans effet sur un stockage local, mais sur un montage debrid, chaque octet est une requête au fournisseur, et ces tâches tournent sur toute la bibliothèque. Les analyses dont le résultat *est* visible (aperçus au survol de la barre de lecture, images de chapitres, nivellement du volume, analyse sonore) se trouvent plutôt dans le palier « taste » ci-dessous, où `enforce` n'y touche pas.

| Préférence | Valeur par défaut de Plex | Valeur demandée par zurg |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### Goûts — toujours signalés, jamais corrigés {#taste--always-reported-never-corrected}

Chacune de ces options correspond à une fonctionnalité. zurg indique donc ce que coûte chaque valeur, mais laisse le choix à l'utilisateur. Désactiver l'une d'elles sans rien demander enlèverait quelque chose que l'administrateur peut voir, et ce n'est pas à zurg d'en décider, même si cela économiserait de la bande passante. Pour les deux premières, l'option moins coûteuse garde la fonctionnalité et déplace le travail dans la fenêtre de maintenance ; pour les autres, il faut choisir entre la fonctionnalité et la bande passante.

| Préférence | Valeur par défaut de Plex | Suggestion de zurg | Pourquoi |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` ou `never` | `asap` décode chaque fichier dès son arrivée, en dehors de toute fenêtre de maintenance. `scheduled` garde le bouton Skip Intro et déplace le travail dans la fenêtre. |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` ou `never` | Idem, pour Skip Credits. |
| `GenerateBIFBehavior` | `never` | `never` | Décode la vidéo entière pour créer la bande d'images affichée lors de la recherche dans la timeline. La lecture n'en a pas besoin. |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | Décode le fichier pour extraire une image par chapitre, afin d'afficher la vignette à côté de chaque entrée de la liste des chapitres. |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | Décode entièrement l'audio de chaque fichier pour le mesurer, afin d'égaliser le volume entre les pistes et les titres. |
| `MusicAnalysisBehavior` | `scheduled` | `never` | Décode chaque piste. Comme il y a beaucoup de petits fichiers, c'est le nombre de requêtes qui fait limiter un compte. Apporte l'analyse sonore : mixes de pistes similaires et visualiseur. |

### La fenêtre de maintenance {#the-maintenance-window}

zurg ne touche pas à `ButlerStartHour`/`ButlerEndHour`, car il n'existe pas d'heure qui convienne à tout le monde. Ça vaut la peine de les régler à la main : Plex utilise par défaut 02:00–05:00, et une plage qui chevauche les heures où quelqu'un regarde transforme chaque tâche de maintenance en blocage. Tout ce qui reste dans le palier de bande passante s'exécute dans cette plage.

### Arrêter une passe déjà en cours {#stopping-a-pass-already-in-flight}

Changer une préférence arrête les *futurs* lancements, pas celui qui tourne déjà. Plex Media Server relance ses processus enfants du scanner, donc les tuer ne sert à rien :

+++ Linux et macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++

Dans Windows PowerShell 5.1, `curl` est un autre nom de `Invoke-WebRequest`, donc tape `curl.exe`.

Commence par définir `$TOKEN` avec ton token Plex : `TOKEN=your-token` dans un shell, `$TOKEN = 'your-token'` dans PowerShell.
