# Migrer vers zurg {#migrating-to-zurg}

Lis d'abord cette page. Elle s'applique à toutes les migrations et c'est l'essentiel de ce dont tu as besoin. Les pages par serveur sont courtes parce que celle-ci contient la partie commune.

## La version courte {#the-short-version}

**zurg publie tous les fichiers multimédias que le serveur que vous quittez publie, et plus encore.** Mesure effectuée le 2026-09-01. Les mêmes cinq releases ont été placées sur les cinq serveurs, puis les montages ont été relus avec `tree`. Voici [la comparaison complète](https://github.com/debridmediamanager/usenet-streaming-benchmark).
Le seul point où zurg publie *moins* concerne la parité par2. Plex n'en fait jamais un élément de bibliothèque.

Donc **vous ne perdrez aucun contenu.** Une partie arrive sous un nom de fichier différent. C'est tout le problème que traite cette page. Plex associe un élément de bibliothèque à un chemin de fichier. Un fichier à un nouveau chemin devient un nouvel élément.

Ce que vous échangez, ce ne sont pas les fichiers. C'est la **curation**.

| Survit | Disparaît avec l'ancien élément |
|---|---|
| Indicateurs de visionnage, nombre de lectures, positions de reprise | Appartenance aux collections |
| Notes des utilisateurs | Entrées de playlists (elles stockent des identifiants d'élément) |
| Les fichiers eux-mêmes | Affiches, illustrations et corrections manuelles de correspondance choisies |
| | `added_at`. Votre bibliothèque inonde Recently Added |

L'état de visionnage survit parce que `metadata_item_settings` est indexée par compte et par GUID `plex://`, et non par chemin ou par identifiant d'élément. Il se rattache quand le nouvel élément correspond au même GUID. Si Plex associe mal l'élément réajouté, l'état ne revient pas. Vérifiez quelques éléments après le premier scan.

Vous pouvez éviter ce compromis, mais cela a un prix. Vous pouvez réécrire `media_parts.file` dans la base de données de Plex pour que les lignes ne meurent jamais. Vous pouvez aussi construire une arborescence de liens symboliques qui recrée chaque ancien chemin par-dessus le montage de zurg. Les deux solutions fonctionnent. Les deux sont des interventions non prises en charge sur un schéma non documenté, qui change d'une version de Plex à l'autre. Une réécriture appliquée à moitié est pire que les deux issues qu'elle devait empêcher.

Ces guides prennent la voie simple et vous indiquent exactement ce qu'elle coûte.

## Ta bibliothèque atterrit dans `__magic__` et non dans une ferme de liens symboliques {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

Chaque serveur de cette liste transmet sa bibliothèque aux \*arrs via une ferme de liens symboliques. **zurg ne le fait pas, et vous ne devriez pas en reconstruire une.** Il propose à la place [`__magic__`](../guides/magic.md). C'est le seul répertoire dont les chemins sont *stockés* au lieu d'être calculés. Un déplacement à l'intérieur réécrit une ligne d'une petite table. Aucun octet ne bouge. Rien n'est copié. La release reste à sa place sur le compte. Pointez Sonarr et Radarr vers lui : ils peuvent organiser et renommer comme bon leur semble, sans aucun coût.

Ce n'est pas seulement une pièce mobile en moins. C'est une couche qui ne peut pas casser comme l'ancienne. Un lien symbolique doit pointer vers un vrai chemin. La cible évidente est `__all__/<release>/<file>`, et ce chemin est *calculé*. Il change quand la release est renommée. Il change encore quand deux releases entrent en collision et que zurg ajoute le suffixe `{shorthash}` à l'une d'elles. Chacun de ces changements fait pendre un lien sans prévenir. Un emplacement `__magic__` est indexé sur le hash de contenu de la release plus le chemin du fichier à l'intérieur. Il survit donc à un renommage. Il survit à un suffixe `{shorthash}`. Il survit à une réparation qui rajoute la release sous un tout nouvel identifiant.

Donc, quoi que vous ayez aujourd'hui, **les chemins vont changer et la bibliothèque doit être ajoutée à nouveau**. Cela vaut pour une bibliothèque \*arr basée sur des liens symboliques, et pour Plex pointé directement sur l'ancien montage. C'est le compromis dont il est question plus haut, et c'est tout le coût de chaque migration ici.

## Ce que tu as aujourd'hui dépend de ta plateforme {#what-you-have-today-depends-on-your-platform}

Cela détermine si les tableaux de renommage des pages suivantes décrivent ta bibliothèque Plex ou seulement la source dont elle a été construite. Vérifie-le avant de les lire.

### Linux et macOS. Tes \*arrs ont déjà tout renommé {#linux-and-macos-your-arrs-already-renamed-everything}

La stratégie des symlinks est la configuration documentée pour les quatre serveurs ici, et elle n'existe que sur ces plateformes. Le serveur publie `completed-symlinks/<category>/<release>/<file>.rclonelink`. Ensuite, `rclone mount
--links` transforme chacun d'eux en vrai symlink. Puis **Sonarr et Radarr importent depuis cette ferme vers une bibliothèque située aux chemins qu'ils ont choisis.** Le montage est la source, et non la bibliothèque.

Deux conséquences.

- **Les chemins que Plex voit sont ceux de l'\*arr.** Toujours. Dossier racine, puis dossier de la série, puis dossier de la saison. Aucun ne contient de nom de release.
- **Les noms de fichiers sont aussi ceux de l'\*arr si vous avez laissé le renommage activé.** Il s'agit de "Rename Episodes" et "Rename Movies". Avec le renommage désactivé, ce sont les noms du serveur source, et les tableaux des pages suivantes décrivent exactement ce que vous voyez.

Donc si vous utilisez les \*arrs avec le renommage activé, les tableaux de renommage par serveur ne décrivent **pas** votre bibliothèque. Ils décrivent ce que l'\*arr a reçu au moment de l'import. Cela reste important. Un meilleur nom de fichier source donne un meilleur parsing, et vous allez réimporter.

### Windows. Aucune couche de liens symboliques du tout {#windows-no-symlink-layer-at-all}

Une ferme de symlinks demande `rclone mount --links`, et ça ne fait pas partie d'une installation Windows. Le montage est une lettre de lecteur passant par WinFsp, et Plex et les \*arrs pointent directement dessus. Donc **Plex affiche les noms de fichiers du serveur**, et les tableaux de renommage décrivent exactement ce que tu verras changer. La page [Installation Windows](../setup/windows.md) explique la lettre de lecteur et sa règle de session.

Les commandes shell des pages par serveur sont écrites pour Linux et macOS (sur macOS, lis `/mnt/zurg` comme `/Volumes/Zurg`). Sur Windows, lis `/mnt/zurg` comme `Z:\`, arrête l'ancien serveur comme tu l'as lancé, et crée des dossiers et déplace des fichiers dans `__magic__` avec les commandes PowerShell du [guide `__magic__`](../guides/magic.md).

### Quitter une bibliothèque de liens symboliques {#coming-off-a-symlink-library}

Vous ne déplacez pas une bibliothèque. Vous la reconstruisez. Et `__magic__` donne aux \*arrs exactement ce que la ferme de liens symboliques leur donnait, sans la ferme. Ils peuvent toujours déplacer et renommer dedans aussi librement qu'avant. Chaque déplacement devient une écriture de ligne au lieu d'une opération sur fichier.

!!!danger Ne laissez jamais un \*arr déplacer l'ancienne bibliothèque dans `__magic__`
Changer le dossier racine d'une série ou d'un film fait proposer à Sonarr ou Radarr de **déplacer** les fichiers. Répondez non. Un déplacement à l'intérieur de `__magic__` est gratuit. Un déplacement depuis ailleurs traverse la frontière du montage, et c'est une copie. C'est aussi le cas d'un déplacement entre deux volumes du même montage. Dans Docker, donnez au \*arr un seul volume qui contient tout le montage de zurg. Une copie depuis un montage de streaming télécharge toute votre bibliothèque et consomme votre quota Usenet ou débrid. Votre ancienne bibliothèque est un arbre de liens symboliques, donc ce qui serait copié, c'est chaque cible vers laquelle ils pointent.
!!!

Déplacez plutôt chaque fichier vous-même. Chaque déplacement est un seul renommage à travers le montage de zurg. Rien n'est copié et rien ne change sur votre compte. Le script ci-dessous le fait à partir de votre ancienne bibliothèque de liens symboliques. Le chemin d'un lien sous l'ancien dossier racine est l'endroit où Sonarr ou Radarr attend l'épisode ou le film. Sa cible donne le nom du fichier. Chaque fichier arrive donc au même chemin sous le nouveau dossier racine que son lien avait sous l'ancien. L'ancienne bibliothèque n'est que lue. Elle continue de fonctionner jusqu'à ce que vous basculiez les \*arrs.

1. **Installez zurg à côté de l'ancien serveur** comme indiqué sur sa page. Laissez-le d'abord lister toute la bibliothèque.
2. **Activez `__magic__`** comme indiqué sur sa page. Gardez les scans Plex désactivés et les files des \*arrs en pause.
3. **Enregistrez la fonction `zurg_path` de la page de votre serveur** sous le nom `zurg_path.sh` à côté du script. Elle transforme la cible d'un ancien lien en fichier que zurg sert. Chaque serveur organise ses fichiers différemment.
4. **Lancez le script** une fois par dossier racine. Définissez `OLD`, `NEW` et `LOG` pour chacun. Une configuration avec `sonarr4k` et `radarr4k` à côté de la paire habituelle nécessite quatre exécutions.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   Il affiche une ligne pour chaque lien qu'il laisse de côté.

   - `NOT IN ZURG` désigne un lien vers un fichier que zurg n'a pas. Son NZB n'a pas pu être récupéré, ou son compte ne figure pas dans la configuration de zurg.
   - `FAILED` désigne un déplacement que zurg a refusé. Un second lien vers un fichier que le script a déjà déplacé affiche ceci, après une ligne de `mv` indiquant `No such file or directory`. Un fichier ne peut être qu'à un seul chemin dans `__magic__`. Il reste là où le premier lien l'a placé.
   - `ALREADY THERE` désigne un chemin que le nouveau dossier racine contient déjà. Relancer le script saute tout ce qu'il a placé auparavant.
5. **Basculez chaque \*arr.** Sélectionnez toutes les séries ou tous les films et modifiez-les ensemble. Définissez le dossier racine sur le nouveau, sous `__magic__`. Quand il demande s'il faut déplacer les fichiers, répondez **No, I'll Move the Files Myself**. Le script les a déjà placés. Puis lancez **Update All** pour qu'il les trouve.
6. **Pointez Plex vers les nouveaux dossiers racines**, et vers rien d'autre. La boîte suivante explique pourquoi.

Chaque déplacement a pris environ 15 millisecondes sur une bibliothèque de test, et rien n'a été copié. Surveillez `data/local` sur le tableau de bord `/magic/` de zurg pendant l'exécution du script. Il ne grossit que des sous-titres et autres petits fichiers que le script copie. Si ce nombre grossit de gigaoctets, quelque chose est en train d'être copié. Arrêtez-vous et regardez.

Les anciens liens continuent de fonctionner. Un fichier déplacé apparaît toujours à son ancien chemin `__all__`, en plus de son nouveau. Les builds antérieurs à la nightly du 2026.10.04 le cachaient à l'ancien chemin pendant jusqu'à 12 heures, alors que zurg le servait encore à cet endroit. Sur l'un de ces builds, redémarrez zurg une fois le script terminé. Tenez Plex à l'écart des anciens dossiers et de `__all__` jusque-là.

La partie zurg de ce guide a été mesurée le 2026-10-03. La modification de dossier racine côté \*arr est l'édition ordinaire de ce réglage et n'a pas été testée pour ce guide. Faites d'abord une seule série.

!!!warning Pointez chaque bibliothèque Plex vers un seul répertoire, pas vers deux
Une bibliothèque qui analyse un répertoire de filtrage comme `movies`, `shows` ou `__all__` **et** analyse `__magic__` trouve chaque épisode deux fois. De plus, `__magic__` contient son propre `__all__`, donc pointer une bibliothèque vers la racine de l'espace de noms analyse toute la bibliothèque en plus de ce que vous avez organisé. Choisissez-en un. Si vous utilisez les \*arrs, pointez Plex vers les dossiers racines que vous avez créés, `__magic__/tv` et `__magic__/movies`. Si vous parcourez une bibliothèque que personne n'organise, choisissez les répertoires de filtrage et laissez `__magic__` de côté.
!!!

## La seule garde à ne surtout pas sauter {#the-one-guard-you-must-not-skip}

**`autoEmptyTrash` doit être à `0` avant de toucher à quoi que ce soit.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Sous Windows, dans PowerShell :

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex indique le réglage comme `0` ou `false` quand il est désactivé.

Plex supprime en douceur. À `0`, un élément dont le fichier n'existe plus reste dans la corbeille et revient si le fichier réapparaît. À `1`, il disparaît définitivement dès qu'un scan le remarque. Un montage qui plante pendant dix secondes pendant un scan emporte toute la bibliothèque avec lui. Ça a déjà coûté des dizaines de milliers d'éléments.

Avec ces guides simplifiés, ce réglage fait plus de travail qu'avant, pas moins. **La corbeille, c'est là où tes anciens éléments attendent pendant que tu vérifies les nouveaux.** Vide-la quand tu es satisfait, et pas avant. C'est cette étape qui rend la perte réelle, et c'est la seule action irréversible de tous ces guides.

Pendant que tu y es, désactive **"Generate video preview thumbnails"** pour les bibliothèques concernées. Sur un montage en streaming, chaque passage de miniatures est une lecture complète de la release via ton quota news ou debrid. Une migration envoie à Plex beaucoup de nouveaux éléments d'un coup.

## Ce que gagne chaque migration {#what-every-migration-gains}

Deux d'entre eux sont de nouveaux fichiers qui apparaissent dans des dossiers que Plex scanne déjà. Ça vaut le coup de les connaître avant qu'ils ne te surprennent.

- **Clips d'échantillon.** zurg est le seul des cinq à publier le fichier d'échantillon dans le dossier `Sample/` d'une release RAR. Plex peut prendre un `-sample.mp4` de 9 Mo pour un bonus ou pour une deuxième version de l'épisode. Si tu ne veux pas ça, mets [`only_show_the_biggest_file: true`](../reference/config.md) sur les dossiers que tes bibliothèques média scannent.
- **Fichiers `.nfo`.** zurg est le seul à les conserver. Ils n'ont aucun effet avec les agents par défaut de Plex. L'agent XBMC et NFO les lit si tu l'utilises.
- **`thumbnail.jpg` et fichiers `.url` publicitaires.** Sans effet. `thumbnail.jpg` n'est pas un nom de fichier que Plex utilise pour les affiches, et les fichiers `.url` ne sont que de la pub de l'affiche.
- **Dossiers vides** là où la chaîne d'archives d'une release est cassée. Plex ignore les dossiers qui ne contiennent aucun média.
- **Les par2 et sfv disparaissent.** zurg les cache en lisant ce que le fichier est réellement, et non le nom qu'il porte. Plex ne les a jamais répertoriés, donc ça n'est pas visible dans ta bibliothèque. Ça ne compte que pour les outils qui les parcouraient.

## Les guides {#the-guides}

- [Depuis AltMount](altmount.md). Renomme uniquement les releases d'archives
- [Depuis decypharr](decypharr.md). Renomme les releases à fichier unique et les releases d'archives
- [Depuis InfiniDysk](infinidysk.md). Renomme les releases à fichier unique et les releases d'archives
- [Depuis nzbdav](nzbdav.md). Ne renomme rien et c'est la plus simple des cinq
- [Depuis streamnzb](streamnzb.md). Pas de bibliothèque à migrer. zurg a son propre addon Stremio

Tu veux quitter Plex plutôt que passer à zurg ? [Passer de Plex à rex](../../rex/from-plex.md) garde zurg et tes applis Plex et fait tourner rex à côté de ton serveur Plex ou à sa place.

Le comportement de nommage de chaque page a été mesuré le 2026-09-01 sur un corpus de cinq releases.
Les builds utilisés étaient zurg `bda7e3c3`, AltMount `0614008b`, InfiniDysk
`cd9b1205`, nzbdav `794948be` et decypharr `0dd1cbbd`. Une build plus ancienne
ou plus récente peut nommer les choses différemment. Vérifie quelques releases
dans ton propre arbre avant de faire confiance à une liste de rescan en bloc.
