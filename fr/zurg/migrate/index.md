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

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never let an \*arr move the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr offer to **move**
the files. Say no. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. So is a move between two volumes of the same
mount. In Docker give the \*arr one volume that holds zurg's whole mount. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Move each file into place yourself instead. Every move is one rename through
zurg's mount. Nothing is copied and nothing on your account changes. The script
below does it from your old library of symlinks. A link's path under the old
root folder is where Sonarr or Radarr expects the episode or film. Its target
names the file. So each file lands at the same path under the new root folder
that its link had under the old one. The old library is only read. It keeps
working until you switch the \*arr over.

1. **Build zurg beside the old server** as its page shows. Let it list the
   whole library first.
2. **Turn on `__magic__`** as its page shows. Keep Plex scans off and the
   \*arr queues paused.
3. **Save the `zurg_path` function from your server's page** as
   `zurg_path.sh` beside the script. It turns an old link's target into the
   file zurg serves. Each server lays its files out differently.
4. **Run the script** once per root folder. Set `OLD` and `NEW` and `LOG` for
   each one. A setup with `sonarr4k` and `radarr4k` beside the regular pair
   needs four runs.

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

   It prints a line for every link it leaves alone.

   - `NOT IN ZURG` is a link to a file zurg does not have. Its NZB could not be
     recovered or its account is not in zurg's config.
   - `FAILED` is a move zurg refused. A second link to a file the script
     already moved prints this after a line from `mv` that says `No such file
     or directory`. A file can sit at only one path in `__magic__`. It stays
     where the first link put it.
   - `ALREADY THERE` is a path the new root folder already holds. Running the
     script again skips everything it placed before.

5. **Switch each \*arr over.** Select every series or every movie and edit them
   together. Set the root folder to the new one under `__magic__`. When it asks
   whether to move the files answer **No, I'll Move the Files Myself**. The
   script already put them there. Then run **Update All** so it finds them.
6. **Point Plex at the new root folders** and at nothing else. The next box
   says why.

Each move took about 15 milliseconds on a test library and nothing was copied.
Watch `data/local` on zurg's `/magic/` dashboard while the script runs. It
grows only by the subtitles and other small files the script copies. A number
that grows by gigabytes means something is being copied. Stop and look.

The old links keep working. A moved file still shows at its old `__all__` path
as well as at its new one. Builds before the 2026.10.04 nightly hid it at the
old path for up to 12 hours even though zurg still served it there. On one of
those builds restart zurg once the script is done. Keep Plex away from the old
folders and from `__all__` until you have.

The zurg side of this was measured on 2026-10-03. The \*arr side is its
ordinary root folder edit and was not tested for this guide. Do one series
first.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice — and `__magic__`
holds its own `__all__`, so pointing a library at the root of the namespace
scans the whole library along with what you organised. Pick one. If you use the
\*arrs then point Plex at the root folders you made, `__magic__/tv` and
`__magic__/movies`. If you browse a library nobody organises then pick the
filter directories and leave `__magic__` off.
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
