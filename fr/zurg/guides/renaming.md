# Renommer les releases et les fichiers {#renaming-releases-and-files}

Le montage de zurg n'est modifiable que d'une seule façon : tu peux **renommer** un dossier de release
ou un fichier à l'intérieur, n'importe où dans la bibliothèque. C'est activé par défaut. Rien n'est
copié, rien n'est téléchargé, et ton compte debrid n'est pas touché. Le nouveau
nom est stocké à côté de la release et l'emporte sur le nom que zurg calculerait sinon.

Ce que tu ne peux pas faire, c'est **déplacer** quoi que ce soit. Renommer et déplacer ressemblent
au même geste dans un gestionnaire de fichiers, et zurg les traite comme des opposés, pour une raison
que [la dernière section](#why-a-move-is-refused-when-a-rename-is-not) explique.

Pour un *agencement* stocké plutôt qu'un *nom* stocké (les dossiers que tu organises, un \*arr
qui importe par déplacement), voir [`__magic__`](magic.md). Cette page ne parle que du
nom.

## Renommer via le montage {#renaming-through-the-mount}

Un renommage dans le montage est un `MOVE` WebDAV dont la destination ne diffère de la source que par le dernier segment du chemin. rclone transforme un renommage sur le montage (un `rename(2)` FUSE, ou son équivalent WinFsp sous Windows) exactement en cela. Donc `mv` ou `Rename-Item` dans le montage, un renommage dans le Finder, l'Explorateur ou un autre gestionnaire de fichiers, et un client WebDAV arrivent tous au même gestionnaire.

+++ Linux et macOS

```bash
mv "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show.S01E01.mkv" \
   "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show - s01e01.mkv"
```

Sur macOS, le montage est `/Volumes/Zurg` sauf si tu as modifié `mount_path`.

+++ Windows

```powershell
Rename-Item -LiteralPath "Z:\shows\Show.S01.1080p.WEB-DL\Show.S01E01.mkv" -NewName "Show - s01e01.mkv"
```

+++

Les deux niveaux fonctionnent :

| Renommage | Stocké comme |
|---|---|
| Un dossier de release | `Torrent.Rename` |
| Un fichier dans une release | `File.Rename` |

Les endpoints `/dav/` et `/infuse/` acceptent `MOVE`. `/http/` ne l'accepte pas : c'est un navigateur en lecture seule, et il répond `405` en dehors de `__magic__`.

### Ce qu'un nom doit respecter {#what-a-name-has-to-satisfy}

Un nouveau nom est accepté lorsque, après suppression des espaces en début et fin, il n'est pas vide, ne contient aucun `/` ni `\`, est égal à sa propre valeur `filepath.Clean` (ce qui rejette aussi `.` et `..`), et, pour un dossier de release, n'entre pas en conflit avec la clé d'accès d'un *autre* hash. Le nom d'un fichier doit être unique au sein de sa propre release.

| Résultat | Statut |
|---|---|
| Renommé | `201` |
| Nom vide, séparateur dans le nom, ou destination désignant uniquement un dossier | `400` |
| Le nom est déjà pris | `412` |
| Source introuvable | `404` |
| Dans une archive, ou refusé (voir ci-dessous) | `403` |

Renommer un fichier *à l'intérieur d'une archive* n'est pas possible. Le contenu de l'archive est généré à partir de celle-ci, donc il n'y a rien sur quoi écrire un nom. zurg refuse l'opération avec un `403` qui indique que les fichiers à l'intérieur d'une archive ne peuvent pas être renommés.

## Renommer depuis le tableau de bord et l'API {#renaming-from-the-dashboard-and-the-api}

Les deux mêmes renommages sont des endpoints `POST`, et chacun a une réinitialisation correspondante qui supprime le nom enregistré et remet la release à son nom calculé :

```
POST /manage/{torrentHash}/rename
POST /manage/{torrentHash}/clear-rename
POST /manage/{torrentHash}/files/{fileid}/rename
POST /manage/{torrentHash}/files/{fileid}/clear-rename
```

Il n'existe pas d'équivalent de `clear-rename` via le montage. Un renommage vers le nom d'origine enregistre ce nom ; il ne supprime pas le remplacement.

### Le correctif des saisons {#the-season-fix}

`GET /torrents/season-fix/plan` et `POST /torrents/season-fix/apply` font un renommage de fichiers en masse, piloté par la correspondance des épisodes de Plex elle-même, pour les versions dont les fichiers sont numérotés d'une façon que rien ne peut analyser. Le plan est en lecture seule et indique pour chaque fichier la raison du saut. L'application prend une liste explicite de hashs plutôt qu'un indicateur « tout appliquer », comme ça vous confirmez ce que vous avez examiné.

## Ce qu'un renommage conserve {#what-a-rename-survives}

Le nom enregistré est stocké sur la release et sérialisé dans son `.zurgtorrent`, il survit donc :

- **Un rafraîchissement de la bibliothèque**, y compris un rafraîchissement qui reconstruit les entrées de fichiers de la release à partir de la liste du fournisseur.
- **Un redémarrage.**
- **Une réparation**, qui rajoute la release par hash sous un nouvel identifiant.
- **Le fournisseur qui renomme le torrent de son côté**, ce que fait Real-Debrid.

Il voyage aussi : un `.zurgtorrent` exporté conserve les renommages, donc une [bibliothèque locale](local-libraries.md) arrive avec le nom que vous lui avez donné.

Une chose qu'il ne survit pas, c'est `ignore_renames: true`, et c'est bien le but de cette clé : zurg ignore tous les noms enregistrés, affiche le nom calculé et refuse les nouveaux renommages via le montage. Les renommages ne sont pas supprimés, seulement ignorés : repasser la clé à désactivée les fait donc revenir.

## Ce qu'un renommage modifie autour de lui {#what-a-rename-changes-around-it}

Un renommage est une simple vue, mais plusieurs éléments sont construits à partir de cette vue, et ils sont mis à jour avec elle :

- **Le montage.** Le cache de répertoires de rclone est invalidé pour l'ancien et le nouveau chemin, donc le changement apparaît sans attendre l'expiration du cache.
- **Les fichiers `.strm`**, si `save_strm_files` est activé. Les anciens sont supprimés et réécrits sous le nouveau nom.
- **Plex et Jellyfin** sont invités à analyser à nouveau la release.
- **L'enregistrement de cache sur le disque.** Le `.zurgtorrent` est écrit sous le nouveau nom et l'ancien fichier est supprimé. Cette suppression est importante : s'il reste, au redémarrage les deux sont chargés, la collision de hash se résout en faveur de l'autre copie, et le renommage revient silencieusement en arrière. C'était un vrai bug, constaté le 2026-08-17.
- **Les endpoints SABnzbd et qBittorrent**, qui recalculent à chaque interrogation le dossier qu'ils indiquent à Sonarr et Radarr. Ainsi, un renommage en pleine importation déplace le chemin à partir duquel ils doivent importer, au lieu de les laisser en plan.

## Trois pièges {#three-traps}

**Un renommage peut re-classer une release au prochain rafraîchissement.** L'appartenance aux répertoires se décide en faisant passer les filtres `directories:` sur le nom de la release, et ces filtres voient le nom *renommé*. Le renommage lui-même ne réévalue volontairement pas les filtres : il garde la release dans les répertoires où elle se trouvait déjà. Mais le prochain rafraîchissement, lui, le fait. Donc si un filtre correspond à quelque chose dans le nom et que ton nouveau nom ne le contient plus, la release finira par changer de répertoire plus tard, sans que rien au moment du renommage ne le laisse présager. Renomme donc avec prudence quand des filtres se basent sur les noms.

**Changer l'extension change ce qu'est le fichier.** Rien n'empêche de passer `episode.mkv` à `episode.txt` ; seuls les séparateurs sont refusés. Mais la visibilité se juge sur le nom que voit le client, donc le fichier renommé peut sortir de `only_show_the_biggest_file`, de la logique des fichiers lisibles, et de l'analyse par un serveur média.

**Une URL `.strm` déjà donnée à quelqu'un d'autre ne fonctionne plus.** Le jeton signé encode la clé d'accès et le nom du fichier. Une URL copiée avant le renommage ne mène donc plus à rien après, et répond `404`. L'arborescence `.strm` de zurg est bien réécrite, mais tout ce qui a copié une URL depuis celle-ci, non.

## Le désactiver {#turning-it-off}

| Clé | Par défaut | Effet |
|---|---|---|
| `dav_allow_rename` | `true` | `false` refuse un `MOVE` sur le montage avec `403`, en nommant la clé dans le corps de la réponse |
| `ignore_renames` | `false` | `true` ignore tous les renommages enregistrés, affiche les noms calculés et refuse les nouveaux renommages via le montage avec `403` |
| `mount_read_only` | `false` | `true` lance rclone avec `--read-only`, pour que le noyau refuse l'écriture avant que zurg ne la voie |

`dav_allow_rename` s'applique au montage. Il ne contrôle pas les points de terminaison du tableau de bord,
et il ne contrôle pas non plus les écritures sous `__magic__`, qui n'atteignent aucun compte debrid.
Le miroir fait exception, et ce n'est pas à cause de cette clé : `__magic__/__all__`
et les dossiers de releases directement à l'intérieur sont la structure propre de la bibliothèque, donc une écriture visant l'un d'eux est refusée, quelle que soit la valeur de ce réglage. À l'intérieur d'un dossier de release, c'est à nouveau normal.
`mount_read_only` l'emporte sur tout, au niveau du noyau, et c'est aussi le seul moyen d'empêcher un `DELETE` sur le montage — voir [config.md](../reference/config.md) pour savoir pourquoi c'est plus important que le renommage.

## Pourquoi un déplacement est refusé alors qu'un renommage ne l'est pas {#why-a-move-is-refused-when-a-rename-is-not}

| Tentative | Statut |
|---|---|
| Un dossier de release vers un autre répertoire | `403` |
| Un fichier vers une autre release | `403` |
| Un fichier vers un sous-dossier de sa propre release | `400` |
| Un répertoire de premier niveau renommé ou déplacé | `405` |
| Tout élément sorti de `__magic__` | `403` |
| Une écriture dans `__magic__/__all__`, ou dans un nom directement à l'intérieur | `403` |

La règle de fond est la même à chaque fois : **un renommage a un endroit où être stocké, un déplacement n'en a pas.**

Le nom d'une release est une simple chaîne attachée à la release. Écrire un nouveau nom revient donc à assigner un champ que chaque recherche ultérieure relit. Mais un répertoire de premier niveau n'est pas un dossier : c'est un filtre enregistré, et son contenu est recalculé à partir de la configuration `directories:` à chaque rafraîchissement. Déplacer une release « dans » `movies` n'écrirait rien, car rien ne relit une réponse stockée à cette question. Au prochain rafraîchissement, l'appartenance serait recalculée à partir des filtres et annulerait le déplacement. Refuser est donc la réponse honnête. Il en va de même pour un sous-dossier à l'intérieur d'une release, dont la forme vient de la liste de fichiers du compte lui-même.

`__magic__` existe parce que la disposition stockée est vraiment utile. Il résout le problème de stockage au lieu de faire comme s'il n'existait pas : un déplacement à l'intérieur écrit une ligne dans une petite table indexée par hash de contenu. C'est pour cela qu'il survit à une réparation qui rajoute la release sous un nouvel identifiant. Cette table est volontairement limitée à cet unique espace de noms.

Il y a une seconde raison de ne pas élargir la liste des refus à la légère. [rclone-move-refusal.md](../internals/rclone-move-refusal.md) documente ce qu'un `MOVE` refusé fait à un client qui ne s'y attendait pas. Avec rclone 1.72.0, l'entrée VFS reste pointée sur la destination tentée, et un appelant qui retombe sur copier-puis-supprimer lit EOF et annonce un succès. Il produit alors un fichier de zéro octet qu'il croit avoir écrit. Chacun des refus ci-dessus est un refus que quelque chose doit pouvoir encaisser.
