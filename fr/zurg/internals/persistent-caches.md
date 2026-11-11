# Caches de lecture persistants {#persistent-read-caches}

Les entrées importées depuis des NZB, Real-Debrid, AllDebrid et TorBox conservent toutes leur état de bibliothèque dans `data/*.zurgtorrent`. Ces fichiers décrivent la bibliothèque. Les caches de préparation de lecture et d'octets se trouvent à côté, si bien que modifier ou vider un cache dérivé ne réécrit pas la bibliothèque et ne fait pas perdre les tags, les noms ni les associations de comptes.

## Ce qui survit à un redémarrage {#what-survives-a-restart}

Ce tableau et les paragraphes qui suivent sont en anglais, je les traduis en français.

| Cache | Emplacement | Travail évité |
| --- | --- | --- |
| Manifestes des documents NZB | `data/nzb-manifests/` | Analyser à nouveau du XML inchangé pour les noms, les tailles, la classification de récupération, les mots de passe et le nombre de segments |
| Index des articles NZB | `data/nzb-index/` | Reconstruire les références d'articles ; utilisé par les modes `mmap` et `resident` |
| Articles Usenet décodés | `data/bytecache/articles/` | Récupérer et décoder en yEnc un article déjà lu |
| Structures des archives | `data/archive-layouts/` | Relire les en-têtes d'archive pour reconstruire les plages de volumes, les entrées imbriquées et les décalages ZIP appris |
| Blocs d'archive décompressés | `data/bytecache/decoded/` | Tout décoder à nouveau pour atteindre les plages d'octets conservées après un redémarrage ou un retour en arrière |
| État des fournisseurs | `data/provider-cache/` | Reconstruire une fenêtre de téléchargements RD inchangée ou récupérer une nouvelle table de régions TorBox |
| Liens de livraison | `data/linkcache/` | Résoudre à nouveau une URL encore valide |

Les structures d'archive prennent en charge les entrées RAR/ZIP stockées ou compressées, les sources imbriquées, les plages chiffrées et les archives fractionnées prises en charge. Elles contiennent des références de source et des décalages, et non des lecteurs HTTP actifs. Les URL actuelles des fournisseurs sont rattachées lors de la restauration. Les structures incomplètes, avec des volumes manquants, sont reconstruites à partir de la source. Les décalages de charge utile ZIP appris sont enregistrés après la première lecture, sans récupérer d'en-tête pour chaque entrée pendant la liste d'un répertoire.

Les manifestes NZB sont vérifiés par rapport à la taille du fichier source, à son heure de modification en nanosecondes et à la version de l'analyseur. `mmap` restaure les métadonnées immédiatement et mappe l'index des articles au besoin. `resident` charge cet index dans la mémoire heap. `reparse` restaure les métadonnées immédiatement, mais analyse toujours le XML lorsque les références d'articles sont nécessaires. Les bibliothèques existantes construisent les manifestes lors de leur premier scan avec cette version ; l'enregistrement au démarrage s'applique aux scans suivants et aux redémarrages.

Les requêtes simultanées AllDebrid et TorBox pour le même fichier non mis en cache sur un même compte partagent désormais une seule résolution. Annuler l'appel d'un demandeur n'annule pas la résolution d'un autre. RD conserve sa mutualisation existante. TorBox utilise les noms et les tailles déjà connus du catalogue lors de la résolution d'un fichier, au lieu de récupérer à nouveau ces détails.

Les enregistrements de détails des fournisseurs dans `data/info/` sont mis en mémoire cache après le premier décodage JSON par processus. Chaque réutilisation vérifie l'identité du fichier, sa taille et son heure de modification, et renvoie une copie indépendante. Les fichiers de bibliothèque et de détails sont remplacés de manière atomique.

## Budgets de stockage {#storage-budgets}

Ces paramètres optionnels de premier niveau sont exprimés en MiB et prennent effet après un redémarrage :

```yaml
nzb_article_disk_cache_mb: 512
archive_decoded_disk_cache_mb: 512
```

Par défaut, chaque cache est limité à 512 MiB pour l'ensemble de l'instance. Zéro désactive ce cache ; les valeurs négatives sont traitées comme zéro. Les budgets comptent les octets des enregistrements, sommes de contrôle comprises, et non le surcoût d'allocation du système de fichiers. Les enregistrements les plus anciens et inutilisés sont supprimés à mesure que de nouveaux arrivent. Réduire un budget réduit le cache existant lors de l'initialisation. Le désactiver laisse les fichiers existants disponibles pour une suppression manuelle.

Le cache d'articles vient en complément du cache RAM existant. Le cache d'archives conserve des blocs décodés de 64 KiB et vient en complément de la fenêtre glissante de 64 MiB en RAM de chaque décodeur. Aucun de ces caches ne précharge la bibliothèque. Une lecture en dehors des blocs décodés conservés doit encore être décodée depuis le début de l'entrée compressée. Le cache VFS de rclone est séparé et continue de servir les plages complètes déjà en cache sans passer par ces chemins ; ces caches profitent aussi aux lectures HTTP/WebDAV directes.

Une entrée compressée ne peut être décodée que depuis son début. Une lecture située loin dans l'entrée revient donc à récupérer d'abord toute l'archive. zurg retient une telle lecture pendant 20 secondes, puis répond `503` plutôt que de laisser le client sans réponse. Ce que le décodage a atteint est conservé : un lecteur qui retente une recherche vers l'avant avance donc un peu plus à chaque fois. Une lecture refusée près de la fin d'une entrée lance aussi un seul décodage en arrière-plan de cette entrée, une entrée à la fois, qui conserve les 8 MiB de fin de l'entrée dans `data/bytecache/decoded-tails/`. Ensuite, la fin du fichier se lit tout de suite, ce que demande un serveur multimédia lorsqu'il analyse un fichier. Ce stockage reprend le même budget que `archive_decoded_disk_cache_mb`, et il est désactivé avec lui.

Les métadonnées dérivées grandissent avec la bibliothèque et ne sont pas comptées dans ces budgets d'octets. Les scans NZB suppriment les manifestes et les index d'articles des documents retirés. Les anciennes révisions de structure d'archive peuvent être supprimées lorsque l'instance est arrêtée ; elles sont jetables et seront reconstruites au besoin.

## Validation et récupération {#validation-and-recovery}

Les nouveaux enregistrements de métadonnées et blocs d'octets reçoivent des sommes de contrôle (checksums). Les enregistrements endommagés et les écritures de cache échouées reviennent à la source. Les enregistrements d'articles n'entrent dans le cache disque qu'après une récupération complète réussie, et ils sont écrits une fois l'article remis à la lecture qui l'a récupéré, de sorte qu'une lecture n'attend jamais le cache. Lors d'une rafale d'écritures d'articles supérieure au nombre pouvant s'exécuter en même temps, les enregistrements en trop sont abandonnés au lieu de retenir une lecture ; un enregistrement abandonné est récupéré à nouveau la prochaine fois qu'il est demandé. L'identité d'un article inclut la révision du NZB, la configuration du serveur, le fichier et le segment ; l'identité d'une archive inclut les références sources actuelles, les tailles, la configuration du compte, le mot de passe et la version du format. Le remplacement de la source NZB invalide aussi les dispositions d'archives et les octets décodés.

L'empreinte de la source locale suppose qu'un remplacement modifie la taille ou la date de modification. Elle évite volontairement de hacher tout le XML à chaque démarrage. Pour conserver les deux lors d'un remplacement, il faut supprimer les caches dérivés associés.

Les snapshots RD ne sont acceptés que pour le même token et la même limite de téléchargement configurée, dans l'heure, après qu'une sonde en direct a confirmé que l'entrée la plus récente et le nombre total correspondent. Une liste modifiée déclenche une réconciliation complète. Les tables de régions TorBox conservent leur durée de vie existante de six heures. Les durées de vie des URL de livraison et la gestion des échecs des fournisseurs ne changent pas : une disposition déjà en cache ouvre sa charge utile avant de valider le succès HTTP, ce qui permet à une URL révoquée d'emprunter le chemin normal de résolution et de nouvelle tentative.

Les mutations de liens de livraison déclenchent un vidage disque regroupé après environ une seconde. La nouvelle tentative toutes les cinq minutes et le vidage à l'arrêt restent en place. Le remplacement atomique empêche les lecteurs d'observer des enregistrements partiellement écrits ; ce n'est pas une garantie fsync contre une coupure de courant. Les nouveaux fichiers de cache utilisent le mode `0600` sous Unix, car les liens et les dispositions d'archives chiffrées peuvent contenir des identifiants ou des clés dérivées. Sous Windows, ce sont les ACL du répertoire parent qui sont utilisées à la place des bits de permission Unix.

## Sauvegardes avec caches chauds {#backups-with-warm-caches}

La sauvegarde par défaut conserve toujours l'état de référence. Pour inclure aussi les caches dérivés et le cache VFS local de rclone de l'instance :

```sh
./zurg backup --include-caches --out warm.zurgbackup
```

Ça peut être beaucoup plus gros qu'une sauvegarde standard. Elle inclut les racines listées plus haut, les caches de nommage, de taille et de PAR2 des NZB, ainsi que l'état des tests réseau. Les logs et les snapshots de la base de données Plex restent exclus. Les caches rclone situés en dehors de `data/rclone-cache/` ne sont pas inclus. Arrête l'instance quand un snapshot cohérent des caches actifs compte vraiment.

Restaure avec l'instance arrêtée en utilisant `./zurg restore-backup warm.zurgbackup`.
Les sauvegardes conservent les timestamps source en nanosecondes, pour que les NZB inchangés puissent garder leurs index et leurs manifestes. Les caches restaurés passent quand même par les vérifications normales de validation et d'expiration. Les sauvegardes contiennent les tokens et les identifiants en cache présents dans la config.

## Vérifications reproductibles {#reproducible-checks}

`BenchmarkParsedDocumentStartup` compare le parsing XML avec chaque mode de restauration du manifeste, sur 60 fichiers et 30,000 segments. `BenchmarkDetailJSONRefresh` compare le chemin de lecture JSON avec un accès mémoïsé, pour un enregistrement de 1,000 fichiers. Ce sont tous deux des benchmarks locaux sur système de fichiers à chaud, et non des mesures de démarrage de production de bout en bout.

Mesuré sur un Apple M3 Pro avec trois runs de 500 ms le 2026-09-05 (médiane par opération) :

| Opération | Temps | Octets alloués |
| --- | ---: | ---: |
| Parser le XML NZB | 43.49 ms | 20.27 MB |
| Restaurer les métadonnées en mode `mmap` | 0.224 ms | 59 KB |
| Restaurer les métadonnées et l'index d'articles résident | 0.577 ms | 1.79 MB |
| Restaurer les métadonnées en mode `reparse` | 0.199 ms | 59 KB |
| Lire/décoder un enregistrement de détails du fournisseur | 0.538 ms | 784 KB |
| Réutiliser l'enregistrement de détails avec une vérification stat et une copie | 0.0084 ms | 59 KB |

Le cas de décodage des détails vide le nouveau mémo avant chaque appel et inclut son coût de remplissage. Ces chiffres comparent les deux chemins d'accès actuels ; ils n'estiment pas la latence réseau et n'extrapolent pas un temps de démarrage pour toute la bibliothèque.

Les tests de non-régression couvrent la réutilisation après redémarrage, la corruption, les changements de source, l'isolation des comptes, la résolution concurrente, l'identité des octets au début, au milieu et à la fin, les seeks en arrière au-delà de la fenêtre RAM, et la révocation des URL après la restauration du layout.

```sh
go test ./...
go test -race ./internal/debrid ./internal/nzb ./internal/rarstream ./internal/universal ./pkg/cachefile ./pkg/diskcache
go test ./internal/nzb ./internal/torrent -run '^$' -bench 'Benchmark(ParsedDocumentStartup|DetailJSONRefresh)$' -benchmem
make integration-test
```

La cible d'intégration nécessite ses comptes de test live documentés et ses dépendances d'hôte. Un script d'intégration ignoré ne vérifie pas une modification du cache.
