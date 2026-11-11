# Bibliothèques debrid locales et zurgtorrents portables {#local-debrid-libraries-and-portable-zurgtorrents}

Une bibliothèque locale tire ses membres de fichiers `.zurgtorrent` portables. Elle apparaît dans les répertoires WebDAV, HTTP et des fournisseurs habituels. Importer des fichiers, les lister et actualiser le catalogue n'ajoutent pas de torrents et ne résolvent pas de liens de téléchargement. La lecture résout le fichier demandé via votre compte configuré.

## Exporter une bibliothèque {#export-a-library}

Depuis le répertoire de travail de l'instance d'export :

+++ Linux et macOS
```sh
./zurg --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++ Windows
```powershell
.\zurg.exe --config config.yml export-torrents data --provider realdebrid --output exported/realdebrid
```
+++

`--provider` est le **nom** du compte configuré, y compris un nom personnalisé. Omets-le
pour exporter toutes les copies débrid prises en charge. L'entrée peut aussi être un
seul fichier de cache d'exécution, un ancien répertoire `dump/`, ou un catalogue
portable existant. Pour une bibliothèque locale, exporte son répertoire source (`torrents/<account>`),
ce qui conserve ses références facultatives vers d'autres fournisseurs.

L'export fonctionne hors ligne. Il valide toutes les entrées et tous les conflits de destination
avant d'écrire quoi que ce soit, signale et ignore les entrées d'exécution sans métadonnées de fichier
sélectionnées, fusionne les releases par hash, et écrit `<hash>.zurgtorrent`. Les exports
identiques existants peuvent être relancés sans risque. Pour une migration en masse contenant des entrées de cache
héritées mal formées, `--skip-invalid` exporte les entrées valides et indique combien
ont été omises. Sans cette option, la première entrée invalide interrompt l'opération avant toute écriture. `--replace` permet de remplacer un export portable
du même hash ; il n'autorise jamais l'écrasement d'un cache d'exécution.

Seuls les fichiers exportés sont destinés au partage. `data/*.zurgtorrent` reste un
état d'exécution privé. Un `.zurgbackup` contient aussi les identifiants des comptes et
constitue une sauvegarde de l'instance, pas une bibliothèque partageable.

## Recevoir une bibliothèque {#receive-a-library}

Mets les fichiers exportés dans `torrents/rd-local/`, puis configure le compte qui les reçoit :

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: YOUR_OWN_TOKEN
    download_tokens: # Optional bandwidth fallback on another RD account.
      - SECOND_RD_TOKEN
    library:
      source: local
      # Optional; defaults to torrents/<account-name>.
      path: torrents/rd-local

  - name: tb-online
    type: torbox
    token: YOUR_OWN_TORBOX_TOKEN
    # Omitted library block means the provider owns this account's catalog.
```

Sur Real-Debrid et AllDebrid, `download_tokens` utilise le même catalogue local que son entrée de fournisseur. Le second compte RD ci-dessus n'a pas besoin de dossier, et sa bibliothèque de torrents n'est pas importée.
Ce sont des identifiants de secours, utilisés quand le quota de bande passante du jeton de téléchargement actif est épuisé ; ils ne forcent pas chaque téléchargement à passer par le second compte. Ajouter une seconde entrée RD sous `providers` crée à la place un catalogue séparé avec son propre dossier. Tous les identifiants restent dans la configuration et sont exclus des exports portables.

TorBox accepte aussi `download_tokens`, mais sa rotation de jetons ne fait pas correspondre les IDs de torrents/fichiers enregistrés aux IDs de l'autre compte. Utilise des entrées de fournisseur TorBox séparées pour des comptes séparés, chacune avec son propre catalogue local.

Les comptes Premiumize, Offcloud et Debrid-Link peuvent aussi avoir une bibliothèque locale. Aucun d'eux n'a de référence de fichier portable. Donc, comme TorBox, chacun ajoute le hash à son propre compte à la première lecture et associe les fichiers par chemin et taille. Utilise une entrée de fournisseur par compte.

Redémarre après avoir modifié la configuration d'un compte. Les ajouts, remplacements et suppressions de fichiers sont pris en compte par la boucle de rafraîchissement normale. Chaque dossier est scanné sur un seul niveau de profondeur. Les chemins doivent être des dossiers distincts sous `torrents/`, pour que les sauvegardes normales les incluent. Un dossier illisible ou un remplacement invalide conserve la dernière entrée valide en mémoire et journalise le problème. Après un redémarrage, un fichier invalide doit être corrigé avant de pouvoir entrer dans le catalogue.

Le même manifeste peut être copié dans le dossier local d'un compte AllDebrid ou TorBox. Il contient l'identité du contenu, pas le nom d'un compte de fournisseur. Le même hash sur plusieurs comptes apparaît une seule fois avec plusieurs sources, en suivant la préférence de compte et l'ordre de basculement existants. Les fichiers en double pour un hash dans un même dossier utilisent le premier nom de fichier dans l'ordre alphabétique ; garde un seul manifeste par hash.

L'appartenance au catalogue local survit à la suppression de la bibliothèque en ligne du fournisseur. Les renommages, tags, IDs IMDb et suppressions de fichiers sont sauvegardés dans les manifestes. Supprimer une release locale supprime ses documents source ; cela ne supprime pas les torrents du fournisseur. Supprimer une release ayant des copies en ligne supprime aussi ces copies en ligne, comme le fait la suppression complète normale d'une release.

Les comptes locaux ne sont pas des cibles pour les watchlists, les envois de magnets ou les envois de fichiers torrent. Ajoute des entrées en important des manifestes. `add_torrents: false` permet quand même à RD/AD d'échanger une référence partagée existante, mais empêche la lecture de créer un rattachement côté fournisseur quand il en faut un.

## Transférer un compte en ligne vers une bibliothèque locale {#offload-an-online-account-into-a-local-library}

AllDebrid accepte au maximum 1000 magnets par compte, et les comptes Real-Debrid se remplissent aussi. Une release terminée n'a pas besoin que son torrent reste sur le compte pour continuer à se lire. Un lien `/d/` de Real-Debrid continue de fonctionner après la suppression du torrent, et un lien verrouillé `/f/` d'AllDebrid continue de fonctionner après la suppression du magnet. Le déchargement repose sur ce fonctionnement. zurg écrit une release terminée dans une bibliothèque locale sur le même service, puis supprime le torrent du compte en ligne, ce qui libère son emplacement. La release garde son dossier dans le montage et se lit à partir des liens sauvegardés.

Configurez deux entrées pour le même compte, une en ligne et une locale :

```yaml
providers:
  - name: ad
    type: alldebrid
    token: YOUR_AD_TOKEN
    library:
      offload_to: ad-local     # the local entry below
      offload_after_mins: 30   # optional, 30 is the default

  - name: ad-local
    type: alldebrid
    token: YOUR_AD_TOKEN       # the same token
    library:
      source: local            # manifests live in torrents/ad-local/
```

Les nouvelles releases continuent d'arriver sur `ad`. Après chaque listing complet de ce compte, et toutes les cinq minutes, zurg déplace les releases qui remplissent les conditions, une à la fois. Une release est éligible lorsque :

- Elle est complète sur le compte depuis `offload_after_mins`, compté à partir du moment où ce processus zurg l'a vue complète pour la première fois. Un redémarrage relance l'attente.
- Chaque fichier a un lien fonctionnel sur ce compte qu'un autre compte peut débloquer. Une release dont un fichier n'a pas de lien reste en ligne.
- Elle est en bonne santé, n'est pas en cours de réparation, et aucune instance de celle-ci n'est encore en téléchargement. Aucune passe de réparation ni aucun client de téléchargement ne détient son torrent.
- Aucune tâche qBittorrent de Sonarr ou Radarr ne la mentionne encore. Activez Remove Completed Downloads dans les *arr pour qu'une tâche soit supprimée après son import. Sinon, la release reste en ligne jusqu'à ce que vous supprimiez la tâche.
- L'acquisition ne l'a pas ajoutée au cours de la dernière heure.
- Le déplacement ne modifie aucun répertoire qui la contient et conserve le nom de son dossier. Un répertoire avec un filtre `provider:` désignant le compte en ligne la ferait disparaître ; une telle release reste donc en ligne.

L'ordre est fixe. Le manifeste `<hash>.zurgtorrent` est d'abord écrit dans la bibliothèque locale, la release rejoint ensuite la bibliothèque locale, et seulement après le torrent est supprimé du compte en ligne. Si le manifeste ne peut pas être écrit, rien n'est supprimé. Si la suppression échoue, la copie en ligne reste à côté de la copie locale, et le prochain rafraîchissement indique si le torrent est toujours présent. Un manifeste que la bibliothèque locale possède déjà pour la release est mis à jour sur place plutôt que réécrit deux fois. Les liens du compte en ligne qu'il contient sont rafraîchis, ses noms et modifications suivent la release telle que le montage la présente, et les liens de l'autre service sont conservés.

La release quitte `__ad__` et apparaît sous `__ad-local__`. Tous les autres répertoires, y compris `__all__` et le vôtre, continuent de la lister sous le même nom. Aucun scan de serveur multimédia n'est lancé, car rien de ce qu'un serveur multimédia indexe n'a changé. Pointez Plex et les autres serveurs multimédias vers ces répertoires plutôt que vers un répertoire par compte.

Avec les deux entrées sur un même token, la lecture locale peut rattacher de nouveau une release au même compte (voir ci-dessous), et ce torrent apparaît alors dans le listing en ligne. zurg ne décharge jamais une release dont le torrent en ligne est un tel rattachement, ni pendant qu'une lecture locale en ajoute un, car supprimer ce torrent casserait la lecture qui vient de l'obtenir.

Seuls Real-Debrid et AllDebrid peuvent décharger. TorBox, Premiumize, Offcloud et Debrid-Link n'ont aucun lien qui survive à la suppression du torrent. Leur lecture locale réajoute donc le torrent, et un déchargement ne libérerait rien. zurg refuse `offload_to` sur ces comptes.

Le tableau de bord peut aussi déplacer une seule release. Sur la page d'une release, le tableau Accounts affiche Move to local library à côté de chaque copie Real-Debrid ou AllDebrid lorsqu'une bibliothèque locale du même type existe, même sans `offload_to`. Lorsque la release ne peut pas encore être déplacée, le bouton est désactivé et indique la raison. Les paramètres du compte sur la page de configuration proposent le même choix et affichent le nombre de releases déplacées depuis le démarrage de zurg, ainsi que la dernière erreur.

## Ce qui voyage dans le fichier {#what-travels-in-the-file}

Le format JSON versionné a `format: "zurgtorrent"` et `version: 1` (numérique).
Il contient l'infohash, les noms de release, la date d'ajout, le renommage, les tags, l'ID IMDb,
et les chemins, tailles et renommages facultatifs des fichiers sélectionnés. Les références sont facultatives :

| Fournisseur | Référence portable | Lecture |
|---|---|---|
| Real-Debrid | Canonique, 13 caractères `https://real-debrid.com/d/...` | Résolution avec les identifiants et l'IP de téléchargement du destinataire. |
| AllDebrid | Verrouillée `https://alldebrid.com/f/...` | Déverrouillage avec les identifiants du destinataire. |
| TorBox | Hash et chemins/tailles des fichiers | À la première lecture, obtenir un torrent côté destinataire et faire correspondre ses fichiers par chemin et taille. |
| Premiumize, Offcloud, Debrid-Link | Hash et chemins/tailles des fichiers | À la première lecture, ajouter le hash sur le compte du destinataire et faire correspondre ses fichiers par chemin et taille. |

Aucun nom de compte, identifiant, ID de torrent/fichier chez le fournisseur, URL CDN, URL d'entrée MediaInfo, ID Plex, état de réparation ni file de suppression n'est exporté. L'importeur rejette les champs inconnus ainsi que les URL de référence contenant des identifiants ou inattendues. Il ne récupère aucune URL pendant la validation d'un manifeste. Usenet conserve son format source `.nzb` ; les caches d'exécution NZB ne peuvent pas être exportés en torrents portables.

## Lecture et limites {#playback-and-limits}

Le suivi local change qui possède le catalogue. Il ne garantit pas qu'un
fournisseur a toujours les fichiers ou qu'il peut les servir. L'accès au compte, les
emplacements réseau autorisés, les slots actifs, les quotas et les limites de
débit s'appliquent toujours.

RD et AD utilisent des références partagées verrouillées lorsqu'elles existent. Les manifestes basés uniquement sur le hash, ainsi qu'une référence RD que l'API signale définitivement comme absente, peuvent établir le contenu sur le compte du destinataire. TorBox exige toujours le rattachement au compte et réutilise d'abord un torrent correspondant déjà présent sur le compte du destinataire. Les ajouts respectent le rythme existant du fournisseur et sont sérialisés par compte. Lorsque le compte indique son nombre de slots, ou que zurg le connaît, un ajout sur un compte plein est refusé, et la prochaine demande de lecture, une minute plus tard, réessaie. AllDebrid, Premiumize et Offcloud n'indiquent aucun nombre : l'ajout est donc tenté, et un compte plein le refuse. Un ajout incertain est mis en attente pendant 30 minutes avant une nouvelle tentative ; un torrent en cours de préparation n'est vérifié que lorsque la lecture est de nouveau demandée.

Les identifiants des destinataires et les descripteurs de fichiers natifs résolus restent privés dans `data/local-torrents/`. Cet enregistrement survit à un redémarrage et est inclus dans les sauvegardes normales. zurg ne supprime jamais ces rattachements automatiquement : un ajout idempotent peut avoir renvoyé un torrent que le destinataire possédait déjà. Le déchargement les laisse aussi de côté. Les échecs du fournisseur laissent l'entrée locale visible et espacent les tentatives, au lieu de lancer une réparation en arrière-plan ou de répéter un ajout à chaque scan.

Les releases d'archives locales listent leurs volumes sources sans extraction automatique ni inspection en arrière-plan. Un chemin explicite à l'intérieur d'une archive peut toujours faire appel au lecteur d'archives. Le sondage MediaInfo automatique et le préchargement du fichier suivant sont désactivés sur les entrées ayant des copies locales.

## Migrer un ancien dump {#migrate-an-old-dump}

Exportez `dump/` avec la commande ci-dessus, placez les résultats dans le répertoire `torrents/<name>/` du compte destinataire et activez `library.source: local`. Désactivez `load_dumped_torrents` une fois la migration terminée. Le lecteur `__dump__` d'adhésion facultative reste disponible pour des raisons de compatibilité ; les nouvelles bibliothèques locales ne l'utilisent pas. Les caches d'exécution sans type de compte doivent être réexportés depuis une instance qui connaît leur fournisseur avant de pouvoir être partagés.

Les sauvegardes écrites par cette version utilisent le format 2 pour inclure les nouvelles racines durables. La commande de restauration lit toujours les sauvegardes au format 1. Les versions plus anciennes refusent le format 2 plutôt que d'abandonner silencieusement une bibliothèque locale.
