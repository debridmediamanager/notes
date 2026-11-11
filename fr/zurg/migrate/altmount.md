# Migrer depuis AltMount vers zurg {#migrating-from-altmount-to-zurg}

Commence par lire [la page commune](index.md). Elle explique le garde-fou (trash guard) et pourquoi ta bibliothèque atterrit dans `__magic__`.

AltMount livre l'arborescence la plus propre des cinq. Exactement un fichier par release. Pas de miniatures, pas de publicités, pas d'échantillon, pas de restes. La migration est donc beaucoup plus petite, car il y a très peu de choses qui posent problème.

Mesuré par rapport à zurg sur les mêmes cinq releases.

| | |
|---|---|
| zurg gagne | le clip d'échantillon, le `.nfo`, `thumbnail.jpg`, les publicités `.url`, le dossier interne de l'archive, **et chaque release qu'AltMount a refusée** |
| zurg perd | rien |
| renommés | **uniquement les releases en archive (RAR)** |

!!!info Seul le chemin par archive renomme
Sur trois passages indépendants avec le build `0614008b`, les releases simples en un seul fichier ont gardé le nom de fichier du posteur. Cela inclut une release dont le nom interne diffère du nom du NZB, et une release entièrement obfusquée. Seule la release qui a dû être décompressée depuis un RAR est devenue `<NZB name>.mp4`.

Les anciens builds d'AltMount renommaient davantage que ça. Vérifie ton propre arbre avant de faire confiance à la liste ci-dessous. La commande unique sous « À quoi ressemble ta bibliothèque ensuite » te le dit en quelques secondes.
!!!

## Le plus gros problème, c'est ce qu'AltMount n'a jamais importé {#the-bigger-issue-is-what-altmount-never-imported}

AltMount a refusé un pack de saison de 10 épisodes lors des quatre essais. Les articles avaient pourtant été vérifiés comme présents sur le serveur de news au préalable.

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

La vérification n'est pas déterministe. La même release est revenue avec 196 segments non vérifiés, puis 93, puis 76. Elle dépend aussi de la taille : en réglant `import.segment_sample_percentage: 1`, seul 1 % des segments est échantillonné, donc une release plus volumineuse a besoin de plus de STAT pour tenir dans le délai. Relancé contre un hébergeur de news *plus rapide*, il a refusé encore plus de releases au lieu de moins. Cet essai a fait perdre à la fois le pack de saison et un remux de 41 Go. La latence n'explique donc pas le problème.

Concrètement, voici ce que ça change pour vous. **Les releases qu'AltMount n'a jamais publiées sans rien signaler sont celles que zurg va ajouter.** Elles n'ont aucun élément Plex aujourd'hui, donc rien n'est conservé et rien n'est en danger. Elles apparaîtront simplement. Si votre bibliothèque est plus petite que votre collection de NZB, c'est la raison.

Si vous voulez qu'AltMount continue d'importer pendant la migration, baisser `segment_sample_percentage` est le réglage à essayer. Je ne l'ai pas testé ici.

## À quoi ressemble ta bibliothèque ensuite {#what-your-library-looks-like-afterwards}

**Tout est réajouté** parce que la racine de la bibliothèque passe sous `__magic__`. Voir [la page partagée](index.md) pour savoir pourquoi il n'y a pas de solution moins coûteuse.

Ce qui change au passage est peu de chose. Les versions simples en un seul fichier gardent le nom de fichier donné par AltMount, donc la plus grande partie de la bibliothèque se lit comme avant. **Les versions en archive reviennent sous le nom du posteur**, et un niveau de dossier plus bas. C'est strictement mieux pour un \*arr. Le nom `father.brown.2013.s02e05.hdtv.x264-tla.mp4` contient la qualité, la source et le groupe que `FatherBrown.mp4` ne gardait pas.

Pour trouver les versions en archive, cherchez un dossier du montage dont le seul fichier porte le nom de ce dossier.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

!!!info Voir ceci dépend de votre configuration
Si Plex lit directement le montage, alors les noms ci-dessus sont ce qui change dans votre bibliothèque. C'est le cas de toutes les configurations Windows, et de toute configuration Linux ou macOS sans ferme de liens symboliques \*arr.

Si Sonarr et Radarr organisent une bibliothèque de liens symboliques avec le renommage activé, alors **vos noms de fichiers sont déjà les leurs** et aucun des noms ci-dessus n'apparaît dans Plex. Ce que les noms vous indiquent alors, c'est la qualité de l'analyse à partir de laquelle l'\*arr travaillait. Cela compte lors d'une réimportation. Voir [la page partagée](index.md).
!!!

## Quel nouveau contenu apparaît {#what-new-content-shows-up}

AltMount ne publie rien de tout cela, donc tout ce qui figure dans la liste de la page partagée s'applique à vous.

- **Clips d'échantillon** dans `Sample/`. C'est le seul élément qui vaut la peine d'être configuré. Définissez [`only_show_the_biggest_file: true`](../reference/config.md) si vous ne voulez pas qu'un échantillon de 9 Mo apparaisse comme une deuxième version.
- `thumbnail.jpg`, le `.nfo` et les fichiers `.url` de l'affiche. Tous sont inertes.
- **Des releases entières refusées par AltMount** qui apparaissent comme de nouveaux éléments de la bibliothèque.
- Des dossiers vides là où une chaîne d'archives est cassée.

## Sors tes NZB {#get-your-nzbs-out}

AltMount a pris la main sur chaque NZB que tu lui as donné. L'original a été
déplacé et une copie compressée est conservée à
`<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. La correspondance entre le
dossier du mount et le `.nzbz` se trouve dans les fichiers `.meta` sous
`<config>/metadata/complete/<Release>/`. Ce sont des fichiers binaires avec le
magic `AM3`, et le chemin du `.nzbz` y est écrit en texte brut.

zurg veut un seul `.nzb` par release, nommé d'après la release et placé à plat
dans `nzbs/`. Les sous-dossiers sont ignorés. Le nom du dossier
`metadata/complete/<Release>` *est* le nom du dossier du mount, et c'est
exactement le nom que doit porter le fichier.

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

Sur l'installation v0.3.2 que j'ai mesurée, le `.nzbz` se décompresse en une
copie gzip du NZB importé. La source prévoit aussi un chemin zstd-protobuf pour
ces fichiers, donc la vérification avec `zcat` et `grep` n'a rien de
paranoïaque. Ce qui est rejeté passe par l'API à la place.
`GET /api/files/export-nzb?path=<virtual path>` régénère un NZB fidèle depuis
le store, et `POST /api/files/export-batch` renvoie un ZIP. Les deux demandent
un JWT et non la clé API.

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

Récupère les chemins virtuels depuis la vue fichiers de l'UI d'AltMount ou
depuis `/api/files/info`, plutôt que de deviner le format. Le téléchargement
s'appelle `<queueID>-<name>.nzb`. Renomme-le en `<Release>.nzb` pour que zurg
nomme correctement le dossier.

Une vérification de bon sens : le nombre de `.nzb` récupérés doit être égal au
nombre de dossiers dans `metadata/complete/*/`.

## Installer zurg en parallèle {#build-zurg-alongside}

AltMount continue de servir pendant tout le processus. Lance zurg sur le port 9999. Il n'y a aucun conflit avec le 8585 d'AltMount.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

Attends-toi à voir **plus** de dossiers ici qu'il n'y en avait avec AltMount. C'est la classe des imports refusés qui arrive.

## Basculer {#cut-over}

Une seule voie, quelle que soit votre configuration actuelle. Rien ici ne déplace d'octets.

**1. Activez `__magic__`** puis redémarrez. Les routes sont enregistrées au démarrage, donc un bouton du tableau de bord ne suffit pas : il faut redémarrer avant que l'espace de noms réponde.

```yaml
magic:
  enabled: true
```

**2. Créez les dossiers racines.** Ils vont à la racine de `__magic__`, à côté de `__all__`, que zurg conserve déjà là. Pas `__magic__/__all__`, pas `__magic__` lui-même et pas la racine du montage. Les deux \*arrs signalent un health check pour ces emplacements ; les dossiers voisins n'en déclenchent aucun.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` reflète la bibliothèque, donc chaque release est présente avant que vous ne commenciez à l'organiser.

**3. Organisez-la.** Un `mv` à l'intérieur de `__magic__` écrit une ligne et ne déplace aucun octet.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Si Sonarr et Radarr ont organisé votre ancienne bibliothèque, déplacez-la avec un seul script.** Il renomme chaque fichier vers lequel l'ancienne bibliothèque pointe, dans un nouveau dossier racine sous `__magic__`. Chacun arrive au chemin attendu par le \*arr. Rien n'est copié. Vous changez ensuite le dossier racine du \*arr sans le laisser rien déplacer. Les étapes et le script sont sur [la page commune](index.md#coming-off-a-symlink-library). Ne laissez jamais un \*arr déplacer les fichiers lui-même. Cela traverse la frontière du montage : c'est une copie, et elle retélécharge votre bibliothèque.

Le script a besoin d'une fonction `zurg_path` pour les liens d'AltMount. Enregistrez-la sous `zurg_path.sh` à côté du script et définissez `OLDMOUNT` à l'emplacement où AltMount est monté.

```bash
OLDMOUNT=/mnt/altmount          # AltMount's mount, where the old links point
zurg_path() {
  case "$1" in "$OLDMOUNT"/*) ;; *) return ;; esac   # not a link into AltMount
  local name=${1##*/} f videos
  local release; release=$(basename "$(dirname "$1")")
  [ -f "$ZURG/__all__/$release/$name" ] && { echo "$ZURG/__all__/$release/$name"; return; }
  # AltMount named a lone video or an unpacked archive after the release. Take its one video.
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

La fonction attend dossier de la release juste au-dessus du fichier dans la cible de chaque lien. Le chemin exact qu'utilisent les liens d'AltMount n'a pas été vérifié pour ce guide. Lancez d'abord `readlink` sur un lien. Quand AltMount a nommé une vidéo seule ou une archive décompressée d'après la release, la fonction prend l'unique vidéo que zurg sert dans cette release. Une release contenant plusieurs vidéos n'est jamais devinée : la fonction affiche `NOT IN ZURG` à la place.

**4. Pointez Plex vers les dossiers racines que vous avez créés** — `__magic__/tv` et `__magic__/movies` — et uniquement vers eux. Jamais vers la racine de `__magic__`, qui contient aussi toute la bibliothèque dans `__magic__/__all__`, et jamais vers `__magic__` *et* un dossier de filtre, sinon chaque épisode est trouvé deux fois. Vérifiez que `autoEmptyTrash` vaut `0`. Ajoutez le nouvel emplacement et lancez un scan. Supprimez ensuite l'ancien. Il s'agit du chemin de bibliothèque de votre \*arr, ou du montage AltMount si Plex le lisait directement.

**5. Videz la corbeille** une fois que vous avez vérifié quelques éléments au hasard. L'état de visionnage revient grâce à la correspondance GUID. Les collections et les choix de visuels, eux, ne reviennent pas.

Gardez AltMount en marche jusque-là. Cela ne coûte rien et c'est votre retour arrière. Une fois terminé, arrêtez-le.

```bash
sudo systemctl stop altmount
```

## Après {#afterwards}

Ne mets pas AltMount hors service tant que tu n'as pas streamé depuis un échantillon représentatif. Son dossier de configuration contient le magasin `.nzbz`, et c'est la seule autre copie de tes NZB.

Maintenant, pense à l'acquisition. zurg a un [point d'accès compatible SABnzbd](../guides/sonarr-radarr.md) optionnel (à activer) auquel Sonarr et Radarr peuvent envoyer leurs téléchargements. Il remplace AltMount comme client de téléchargement pour eux. zurg vérifie chaque envoi avant de le signaler comme terminé. Il interroge les serveurs Usenet sur le début et la fin de chaque fichier. Il télécharge aussi le premier article de chaque fichier. Ça fait jusqu'à soixante-quatre articles, plus quelques autres pour une release qui n'a que quelques fichiers. Certains serveurs Usenet affirment encore qu'un article existe alors que son contenu a été retiré, et seul un téléchargement le montre. zurg reconstruit une release dont des articles manquent dans ses fichiers PAR2 quand il le peut. Une release qu'il ne peut pas reconstruire est signalée **Failed**. Les \*arr la mettent alors sur liste noire et en prennent une autre. La vérification n'est qu'un échantillon, pas la totalité du post. Un post qui a perdu un morceau que l'échantillon n'a pas atteint est quand même signalé Completed, et échoue à la lecture qui tombe sur le trou. Garde les dossiers racine des \*arr à l'intérieur de `__magic__`. Un dossier racine ailleurs reçoit une copie complète de chaque import. Dans Docker, donne au \*arr un seul volume qui contient tout le montage de zurg. Un dossier de téléchargement et des dossiers racine sur deux volumes copient aussi chaque import. Voir [un seul volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
