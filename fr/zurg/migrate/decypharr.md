# Migrer de decypharr vers zurg {#migrating-from-decypharr-to-zurg}

Lis d'abord [la page commune](index.md). Elle explique le trash guard et pourquoi ta bibliothèque atterrit dans `__magic__`.

decypharr et zurg résolvent le même problème, et leurs structures de répertoires racine sont proches. Une grande partie de la configuration se reprend telle quelle.

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | une entrée `directories:` avec `not_provider: nzb` |
| `nzbs/<job>/` | une entrée `directories:` avec `provider: nzb` ou le `__nzb__` intégré |

Le **côté debrid n'a besoin de rien**. Les deux serveurs listent les mêmes comptes et
présentent les noms de fichiers d'origine du torrent. Ces chemins sont identiques une fois que zurg se trouve au point de montage de decypharr. Tout ce qui suit concerne le côté Usenet.

Deux points à régler avant de commencer.

- **Fournisseurs.** Ils ne limitent pas la migration. zurg a un backend pour
  chaque service que decypharr supporte. Les comptes Premiumize et Debrid-Link passent comme les autres. Chacun a sa page dans [Fournisseurs](../providers/index.md).
- **Ne change pas le `folder_naming` de decypharr avant de migrer.** Il renomme
  tous les dossiers de la bibliothèque d'un coup. Ça casse d'un seul coup chaque cible de symlink et chaque chemin Plex en mount-direct.

## Ce qui change côté Usenet {#what-differs-on-the-usenet-side}

Par rapport à zurg, sur les mêmes cinq versions :

| | |
|---|---|
| zurg ajoute | `thumbnail.jpg`, le clip d'échantillon, le `.nfo`, les publicités `.url`, le dossier interne de l'archive, **et la version obfusquée que decypharr avait écartée** |
| zurg perd | rien |
| renommé | les versions en fichier unique et les versions en archive |

**Les versions en fichier unique** sortent de decypharr avec le nom de la tâche. Vous obtenez
`ToyStory5/ToyStory5.mkv` là où zurg garde le nom du releaser et sert
`ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`.

**Les versions en archive** sont le cas le plus intéressant, et il vaut la peine de les comprendre parce
qu'elles expliquent deux symptômes à la fois. C'est decypharr qui produit ceci.

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

C'est le nom du dossier interne de l'archive collé directement au nom du fichier,
**sans aucun séparateur**. C'est une jointure de chemin qui a perdu son `/`. Le niveau de dossier
manquant et le nom de fichier mal formé viennent donc du même défaut, et non de deux défauts distincts.
zurg reproduit la vraie structure à
`FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`.

**Les versions multi-fichiers et les packs de saison gardent leurs vrais noms de fichiers des deux côtés.** Ils
correspondent automatiquement dès que le nom du dossier correspond.

## À quoi ressemble ta bibliothèque ensuite {#what-your-library-looks-like-afterwards}

**Tout est réajouté** parce que la racine de la bibliothèque passe sous `__magic__`. Voir [la page commune](index.md) pour savoir pourquoi il n'existe pas de solution moins coûteuse.

Le gain se situe au niveau des noms. Chaque release à fichier unique revient sous le nom de fichier de l'uploader au lieu du nom du job. Ainsi `ToyStory5/ToyStory5.mkv` devient `Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`. C'est cette chaîne que Sonarr, Radarr et Plex analysent pour la qualité, la source, le groupe et l'édition. Les releases en archive ne gardent plus un nom soudé et se retrouvent dans leur propre dossier. Les releases multi-fichiers et les packs de saisons se lisent déjà correctement et ne changent pas.

Liste les releases dont les noms vont changer.

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
done
```

!!!info Vous verrez ou non ces changements selon votre configuration
Si Plex lit directement le montage, les noms ci-dessus sont ceux qui changent dans votre bibliothèque. C'est le cas de toutes les configurations Windows et de toutes les configurations Linux ou macOS sans ferme de liens symboliques \*arr.

Si Sonarr et Radarr organisent une bibliothèque de liens symboliques avec le renommage activé, **vos noms de fichiers sont déjà les leurs** et aucun des noms ci-dessus n'apparaît dans Plex. Ce que les noms vous indiquent alors, c'est la qualité de l'analyse sur laquelle le \*arr travaillait. Cela compte lors de la réimportation. Voir [la page commune](index.md).
!!!

## Quel nouveau contenu apparaît {#what-new-content-shows-up}

- **Clips d'échantillon** dans `Sample/`. C'est le seul élément qui vaut la peine d'être configuré. Définissez
  [`only_show_the_biggest_file: true`](../reference/config.md) si vous ne voulez pas qu'un échantillon de 9 Mo apparaisse comme une deuxième version.
- `thumbnail.jpg`, le `.nfo` et les fichiers `.url` de l'affiche. Tous sont inoffensifs.
- **Releases obfusquées que decypharr a déposées** et qui apparaissent comme de nouveaux éléments de la bibliothèque. decypharr n'a rien publié du tout pour un post entièrement nommé par un hash. zurg le résout vers le vrai nom de release et le sert.
- Dossiers vides là où une chaîne d'archives est cassée.

## Récupérer tes NZB {#get-your-nzbs-back}

**decypharr ne peut pas te les donner.** Il garde un seul binaire compressé par tâche dans `usenet/meta/<uuid>.meta`, et un dossier `usenet/nzbs/` qui était vide sur le banc de test. Il n'existe aucune fonction d'export documentée. Rien ne prouve que les fichiers `.meta` puissent être reconvertis en NZB. Considère les originaux comme irrécupérables.

Ce que tu as, en revanche, ce sont les noms des tâches. Sur les deux serveurs, le nom du dossier de la tâche *est* le nom du fichier NZB. La liste des dossiers est donc ta liste de courses.

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

Pour chaque tâche, récupère à nouveau le NZB auprès de ton indexeur en cherchant le nom du dossier. Ensuite, **renomme le fichier exactement avec ce nom suivi de `.nzb`** avant de le déposer dans le dossier `nzbs/` de zurg. Le nom du fichier doit être celui du dossier, c'est lui qui garde le chemin stable.

Deux règles à suivre pendant l'opération.

- **Ignore toute release qu'un compte debrid possède déjà.** Le symlink passe par la copie torrent. Si tu ajoutes aussi le NZB, zurg voit deux releases différentes avec le même nom et ajoute un suffixe de hash à l'une d'elles, par exemple `Some.Release {a1b2c3}`. Ça casse tout ce qui pointait vers le nom simple.
- Une release que ton indexeur ne propose plus est tout simplement perdue. Avec `autoEmptyTrash` à `0`, l'élément Plex reste dans la corbeille jusqu'à ce que tu décides de le supprimer.

## Installer zurg en parallèle {#build-zurg-alongside}

Fais tourner zurg à côté de decypharr, sur son propre point de montage. Les deux peuvent lister les mêmes comptes debrid en même temps, car lister ne fait que lire.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30                # your plan's real allowance
retain_rd_torrent_name: false        # align with decypharr's folder_naming
retain_folder_name_extension: false  # true if your folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                         # optional: mirror decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

Ensuite, vérifie que le côté debrid correspond bien avant d'aller plus loin.

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

Parfois, les dossiers torrent diffèrent *systématiquement*. Une extension est présente ou absente. Le nom renommé par RD apparaît à la place de l'original. Dans ce cas, change la valeur de `retain_rd_torrent_name` ou `retain_folder_name_extension` et relance un scan, plutôt que de corriger quoi que ce soit à la main. Les dossiers présents uniquement côté decypharr correspondent aux jobs Usenet. Les noms de dossiers de Premiumize et Debrid-Link n'ont pas été comparés à ceux de decypharr. Vérifie aussi les dossiers de ces comptes ici.

## Basculer {#cut-over}

**1. Active `__magic__`** puis redémarre. Les routes sont enregistrées au démarrage, donc un interrupteur du tableau de bord ne suffit pas : il faut redémarrer avant que l'espace de noms réponde.

```yaml
magic:
  enabled: true
```

**2. Crée les dossiers racines.** Ils vont à la racine de `__magic__`, à côté de `__all__` que zurg garde là. Pas `__magic__/__all__`, pas `__magic__` lui-même, et pas la racine du montage. Les deux \*arrs lèvent une alerte de contrôle de santé pour ces emplacements ; les dossiers frères n'en déclenchent aucune.

Avec Docker, les \*arrs doivent accéder à `__all__` et à ces dossiers racines via un seul volume. Les configurations decypharr montent souvent un dossier de téléchargements et un dossier média séparément. Deux volumes transforment chaque import en copie complète. Monte plutôt une seule fois le dossier parent du montage de zurg. Le [guide pas à pas](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders) le montre.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` reflète la bibliothèque, donc chaque release est présente avant que tu organises quoi que ce soit.

**3. Organise.** Un `mv` à l'intérieur de `__magic__` écrit une ligne et ne déplace aucun octet.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Si Sonarr et Radarr ont organisé ton ancienne bibliothèque, fais-la entrer avec un seul script.** Il renomme chaque fichier que l'ancienne bibliothèque relie vers un nouveau dossier racine sous `__magic__`. Chacun atterrit au chemin que le \*arr attend déjà. Rien n'est copié. Ensuite tu changes le dossier racine du \*arr sans le laisser rien déplacer. Les étapes et le script se trouvent sur [la page commune](index.md#coming-off-a-symlink-library). Ne laisse jamais un \*arr déplacer les fichiers lui-même. Cela franchit la frontière du montage : c'est une copie, et elle retélécharge ta bibliothèque.

Le script a besoin d'une fonction `zurg_path` pour les liens de decypharr. Enregistre-la sous `zurg_path.sh` à côté de lui et règle `OLDMOUNT` sur l'emplacement où decypharr est monté.

```bash
OLDMOUNT=/mnt/decypharr         # decypharr's mount, where the old links point
zurg_path() {
  local rel=${1#"$OLDMOUNT"/__all__/}
  [ "$rel" = "$1" ] && return   # not a link into decypharr
  local job=${rel%%/*} name=${1##*/} f videos
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # decypharr welded an archive's inner folder and file into one name.
  for f in "$ZURG/__all__/$job"/*/*; do
    [ "$(basename "$(dirname "$f")")$(basename "$f")" = "$name" ] && { echo "$f"; return; }
  done
  # decypharr named a lone video after the job. Take the job's one video.
  case "$name" in "$job".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$job" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Un lien vers une release debrid ou une release NZB multi-fichiers désigne le même fichier sur les deux serveurs. decypharr a renommé deux types de releases NZB. Il a nommé une vidéo isolée d'après le job, et il a fusionné le dossier et le fichier d'une archive en un seul nom. La fonction retrouve la copie de zurg pour les deux cas. Un job contenant plus d'une vidéo n'est jamais deviné. La fonction affiche `NOT IN ZURG` à la place.

**4. Pointe Plex vers les dossiers racines que tu as créés** — `__magic__/tv` et `__magic__/movies` — et uniquement vers eux. Jamais vers la racine de `__magic__`, qui contient aussi toute la bibliothèque dans `__magic__/__all__`, et jamais vers `__magic__` *et* un dossier de filtre en même temps, sinon chaque épisode est trouvé deux fois. Vérifie que `autoEmptyTrash` vaut `0`. Ajoute le nouvel emplacement et lance un scan. Ensuite supprime l'ancien. C'est soit le chemin de bibliothèque de ton \*arr, soit le montage decypharr si Plex le lisait directement.

**5. Vide la corbeille** une fois que tu as vérifié quelques éléments au hasard. L'état de visionnage revient grâce à la correspondance GUID. Les collections et les choix d'images, eux, ne reviennent pas.

Laisse decypharr en marche jusque-là. Ça ne coûte rien et c'est ton plan de retour arrière. Ne supprime pas non plus sa configuration, ni ses états `db/` ou `usenet/`. Une fois que tu as terminé, arrête-le.

```bash
sudo systemctl stop decypharr
```

## Après {#afterwards}

**L'automatisation suit, dans les deux sens.** zurg propose un point d'accès compatible SABnzbd, activable au choix, [décrit ici](../guides/sonarr-radarr.md), pour que Sonarr et Radarr puissent lui transmettre un NZB. Il propose aussi un point d'accès compatible qBittorrent, activable au choix, [décrit ici](../guides/sonarr-radarr-torrents.md), pour leur permettre de lui transmettre un magnet ou un `.torrent` pour un compte debrid. Les deux importent depuis `__magic__/__all__` en renommant. Voici vos options.

- **NZB.** Activez `sabnzbd.enabled` et indiquez aux \*arr d'utiliser zurg. zurg vérifie chaque envoi avant de le signaler comme terminé. Il interroge les serveurs de news sur le début et la fin de chaque fichier. Il télécharge aussi le premier article de chaque fichier. Cela représente jusqu'à soixante-quatre articles, plus quelques-uns pour une release qui ne contient que quelques fichiers. Certains serveurs de news affirment encore qu'un article existe alors que son contenu a été retiré, et seul un téléchargement permet de le voir. zurg reconstruit une release dont des articles manquent dans ses fichiers PAR2, lorsque c'est possible. Une release qu'il ne peut pas reconstruire est signalée **Failed**. Le \*arr la met alors sur liste noire et en récupère une autre. La vérification ne porte que sur un échantillon et non sur la totalité du post. Un post qui a perdu une portion que l'échantillon n'a pas atteinte est toujours signalé Completed, et échoue lors de la lecture qui tombe sur le trou.
- **Torrents.** Activez `qbittorrent.enabled` et ajoutez-le comme second client de téléchargement. Une release d'un tracker privé fonctionne lorsque l'indexeur fournit un fichier `.torrent` plutôt qu'un simple magnet, car le fichier permet de retrouver directement, par hash, l'entrée du cache du compte.
- **Ajouts ponctuels.** Le tableau de bord de zurg n'a pas de bouton d'ajout. Ajoutez un magnet ou un `.torrent` via le point d'accès qBittorrent avec la catégorie d'un \*arr, et il part vers ce \*arr.
  [Ajouter une release à la main](../guides/sonarr-radarr-torrents.md#11-adding-a-release-by-hand) explique la marche à suivre. Un magnet ajouté via DMM et un NZB déposé dans `nzbs/` apparaissent tous deux dans zurg. Aucun des deux n'arrive seul jusqu'à Sonarr ou Radarr. L'[acquisition](../guides/acquisition.md) propre à zurg récupère aussi les demandes par elle-même. Elles viennent de votre watchlist Plex, de Seerr et des \*arr. Elle prend les NZB auprès des indexeurs Newznab et les torrents auprès des indexeurs Torznab lorsque votre compte les a déjà en cache.
- **Hybride.** Gardez decypharr uniquement comme client de téléchargement des \*arr, qui alimente les mêmes comptes debrid, zurg servant le montage. Les deux listent le même compte, donc zurg récupère ce que decypharr ajoute. L'étape d'import des \*arr nécessite alors un mappage de chemins distants vers l'arborescence de zurg. Cette arborescence et les dossiers racines doivent se trouver dans un même volume. Testez d'abord un envoi.
