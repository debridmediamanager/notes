# Migrer de InfiniDysk vers zurg {#migrating-from-infinidysk-to-zurg}

Lis d'abord [la page partagée](index.md). Elle explique le trash guard et pourquoi ta bibliothèque atterrit dans `__magic__`.

Mesuré face à zurg sur les mêmes cinq releases.

| | |
|---|---|
| zurg gagne | le clip d'échantillon, le `.nfo` |
| zurg perd | 5 volumes par2 nommés par hash dans les releases obfusquées |
| renommé | **toutes les releases sauf celles à plusieurs fichiers** |

!!!warning Le renommage, c'est toute la migration
InfiniDysk renomme le fichier média d'une release avec le nom du NZB dès que la release ne correspond qu'à une seule charge utile. Sur le corpus du 2026-09-01, quatre sur cinq sont sorties en `ToyStory5.mkv`, `Obfuscated.mkv`, `FatherBrown.mp4` et `MandaloriaREMUX.mkv`. Seul le pack de saison de dix épisodes a gardé ses noms d'épisodes.
Le renommage s'applique à n'importe quelle profondeur. `FatherBrown.mp4` se trouve *à l'intérieur* du dossier `Father.Brown.2013.S02E05.HDTV.x264-TLA/` conservé.

zurg garde le nom de fichier d'origine du poster. Donc le nom de la release revient, et chaque release à charge utile unique change de chemin. Ce nom est la chaîne que Plex et les \*arrs analysent pour la qualité, le groupe et l'épisode.
!!!

Une autre différence est petite mais déroutante si tu la découvres à froid. InfiniDysk crée le dossier `Sample/` de l'archive et le laisse **vide**. zurg y place le clip d'échantillon.

Le contenu n'est pas une raison de changer. Le build `cd9b1205` a importé les cinq releases du corpus de référence, y compris le pack de saison. Ne t'attends pas à voir InfiniDysk supprimer des éléments. Ce que tu récupères, c'est le nommage.

!!!warning Ne parcours jamais la racine WebDAV
Le stockage d'objets `.ids` matérialise les 16 sous-dossiers hexadécimaux à chacun de ses cinq niveaux, quel que soit le contenu. Soit 16^5, soit environ 1,048,576 dossiers. Pointe `find`, `du`, `rclone` et tout scanner explicitement vers `/content`, `/nzbs` ou `/completed-symlinks`. Jamais vers `/`.
!!!

## À quoi ressemble ta bibliothèque ensuite {#what-your-library-looks-like-afterwards}

**Tout est réajouté** parce que la racine de la bibliothèque passe sur `__magic__`. Voir
[la page commune](index.md) pour savoir pourquoi il n'y a pas de solution moins coûteuse.

C'est la migration où ça te coûte le moins et où tu gagnes le plus. Presque tous
les noms de fichiers s'améliorent. `ToyStory5.mkv` devient
`Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv` et un \*arr
qui réimporte depuis `__magic__` peut enfin lire la qualité, la source, le groupe
et l'édition à partir du nom de fichier. Seuls les packs de saison restent
comme avant, et ceux-là se lisent déjà correctement.

Liste les releases dont le nom change. Ce sera la plupart d'entre elles.

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

Le `-maxdepth 4` compte, parce que le renommage peut se faire un niveau plus bas, dans un dossier d'archive.

!!!info Ce que tu vois dépend de ta config
Si Plex lit directement le montage, alors les noms ci-dessus sont ceux qui changent
dans ta bibliothèque. C'est le cas de toutes les configs Windows et de toutes les
configs Linux ou macOS sans ferme de liens symboliques \*arr.

Si Sonarr et Radarr organisent une bibliothèque de liens symboliques avec le renommage activé, alors **tes noms de fichiers sont déjà les leurs** et aucun des noms ci-dessus n'apparaît dans Plex. Ce que les noms te disent alors, c'est la qualité de l'analyse sur laquelle le \*arr travaillait. Ça compte au moment de la réimportation. Voir [la page commune](index.md).
!!!

## Quel nouveau contenu apparaît {#what-new-content-shows-up}

- **Clips d'échantillons.** Les répertoires `Sample/` que tu as déjà ne seront plus vides. C'est le seul point qui vaut la peine d'être configuré. Mets [`only_show_the_biggest_file: true`](../reference/config.md) si tu ne veux pas qu'un échantillon de 9 MB apparaisse comme une deuxième version de l'épisode.
- Le `.nfo` à l'intérieur des releases RAR. Sans effet avec les agents par défaut de Plex.
- Des dossiers vides là où une chaîne d'archives est cassée. InfiniDysk n'a rien créé pour ceux-là.
- **Les fichiers par2 et sfv ne sont plus visibles.** Ça inclut les volumes aux noms de hash dans les releases obfusquées. Ils n'ont pas d'extension multimédia, donc Plex ne les aura pas répertoriés. Si d'autres outils que Plex parcourent ces fichiers, ils le remarqueront.

## Sors tes NZB {#get-your-nzbs-out}

zurg lit un dossier de fichiers `.nzb`. Il y en a un par release, nommé d'après le dossier de la release. Le WebDAV d'InfiniDysk `/nzbs/<category>/` reflète la file d'attente et est lisible.

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

Le fait que les tâches terminées restent listées sous `/nzbs` une fois finies est **non vérifié**. Il reflète la file d'attente, et ton historique peut être plus profond que ta file. Pour ce qui manque, les métadonnées NZB qu'InfiniDysk garde pour le remontage se trouvent dans `{CONFIG_PATH}/blobs/`. Le format des blobs n'est pas vérifié, donc vérifie avant de t'y fier.

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

Si les blobs ne sont pas du XML brut sur ton installation, l'historique de téléchargement de ton indexeur sert de plan B.

Ensuite, crée un fichier `<release>.nzb` pour chaque dossier de release que tu as vraiment.

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

Les NZB récupérés depuis `/nzbs/<category>/` ont normalement déjà le bon nom. C'est de là que vient le nom du dossier. Deux règles de nommage de zurg valent le coup d'être vérifiées par rapport à la liste.

- zurg retire le `.mkv` ou `.mp4` en fin de nom de dossier. Si un dossier de release se termine ainsi, mets `retain_folder_name_extension: true`.
- Deux releases différentes qui partagent un nom reçoivent le suffixe ` {shorthash}` sur l'une d'elles. Repère-les avec `cut -f2 releases.tsv | sort | uniq -d`. InfiniDysk avait le même problème, mais différemment : réimporter un NZB là-bas créait `<Release> (2)`.

## Installer zurg en parallèle {#build-zurg-alongside}

InfiniDysk continue de fonctionner tout au long de l'opération.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from InfiniDysk's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
enable_repair: true
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l          # should approach your release count
```

`__all__` contient toutes les releases, quels que soient les filtres de répertoire.

## Basculer {#cut-over}

**1. Active `__magic__`** puis redémarre. Les routes sont enregistrées au démarrage, donc un interrupteur du tableau de bord demande un redémarrage avant que le namespace réponde.

```yaml
magic:
  enabled: true
```

**2. Crée les dossiers racines.** Ils vont à la racine de `__magic__`, à côté de `__all__` que zurg y garde. Pas `__magic__/__all__`, pas `__magic__` lui-même et pas la racine du montage. Les deux \*arr lèvent une vérification de santé pour ces emplacements ; les dossiers frères ne déclenchent rien.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` reflète la bibliothèque, donc chaque release est présente avant que tu ranges quoi que ce soit.

**3. Range-la.** Un `mv` à l'intérieur de `__magic__` écrit une ligne et ne déplace aucun octet.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Si Sonarr et Radarr ont organisé ton ancienne bibliothèque, déplace-la avec un seul script.** Il renomme chaque fichier vers lequel l'ancienne bibliothèque pointe, dans un nouveau dossier racine sous `__magic__`. Chacun atterrit au chemin que le \*arr attend déjà. Rien n'est copié. Ensuite tu changes le dossier racine du \*arr sans le laisser rien déplacer. Les étapes et le script sont sur [la page commune](index.md#coming-off-a-symlink-library). Ne laisse jamais un \*arr déplacer les fichiers lui-même. Cela traverse la frontière du montage. C'est une copie, et elle retélécharge ta bibliothèque.

Le script a besoin d'une fonction `zurg_path` pour les liens d'InfiniDysk. Enregistre-la sous `zurg_path.sh` à côté, et règle `OLDMOUNT` sur l'emplacement où InfiniDysk est monté.

```bash
OLDMOUNT=/mnt/remote/infinidysk # InfiniDysk's mount, where the old links point
# The map from each .ids name to its release and file. Built once while InfiniDysk runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # InfiniDysk named a lone video after the release. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Les liens d'InfiniDysk pointent vers son magasin `.ids`, et zurg n'a pas d'équivalent. La fonction lit donc une fois l'arborescence `completed-symlinks` d'InfiniDysk pour savoir quelle release et quel fichier correspond à chaque nom `.ids`. Garde InfiniDysk en marche jusqu'à la fin du script. Quand InfiniDysk a nommé une vidéo seule d'après la release, la fonction prend l'unique vidéo que zurg sert dans cette release. Une release qui contient plus d'une vidéo n'est jamais devinée : la fonction affiche `NOT IN ZURG` à la place.

**4. Pointe Plex vers les dossiers racines que tu as créés** — `__magic__/tv` et `__magic__/movies` — et seulement vers eux. Jamais vers la racine de `__magic__`, qui contient aussi toute la bibliothèque dans `__magic__/__all__`, et jamais vers `__magic__` *et* un dossier de filtre, sinon chaque épisode est trouvé deux fois. Vérifie que `autoEmptyTrash` vaut `0`. Ajoute le nouvel emplacement et lance un scan. Retire ensuite l'ancien. C'est le chemin de bibliothèque de ton \*arr, ou le montage d'InfiniDysk si Plex le lisait directement.

**5. Vide la corbeille** une fois que tu as vérifié quelques éléments. L'état de visionnage revient par la correspondance GUID. Les collections et les choix de visuels, eux, non.

Laisse InfiniDysk tourner jusque-là. Ça ne coûte rien et c'est ton retour arrière. Quand tu as fini, arrête-le.

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## Après {#afterwards}

Gardez `{CONFIG_PATH}/blobs/` ainsi que votre jeu de NZB récupérés jusqu'à ce que vous ayez diffusé
à partir d'un échantillon représentatif.

Pensons maintenant à l'acquisition. zurg propose un [point de terminaison
compatible SABnzbd](../guides/sonarr-radarr.md), en option, auquel Sonarr et Radarr peuvent envoyer leurs téléchargements. Il remplace InfiniDysk comme client de téléchargement. Le téléchargement arrive dans
`__magic__/__all__` et l'import le déplace par simple renommage. Rien n'est copié.
zurg vérifie chaque téléchargement avant de le signaler comme terminé. Il interroge les serveurs de news sur le début et la fin de chaque fichier. Il télécharge aussi le premier article de chaque fichier, soit jusqu'à soixante-quatre articles, plus quelques-uns pour une release qui ne contient que quelques fichiers. Certains serveurs de news affirment encore qu'un article existe alors que son contenu a été retiré, et seul un téléchargement permet de le voir. zurg reconstruit une release dont des articles manquent dans ses fichiers PAR2 lorsque c'est possible. Celle qu'il ne peut pas reconstruire est signalée comme **Failed**. Les \*arr la mettent alors sur liste noire et en récupèrent une autre. La vérification ne porte que sur un échantillon et non sur la totalité du post. Un post qui a perdu un morceau que l'échantillon n'a pas atteint est tout de même signalé comme Completed, et il échoue à la lecture qui tombe sur le trou.
Gardez les dossiers racine des \*arrs à l'intérieur de `__magic__`. Un dossier racine placé ailleurs reçoit une copie complète de chaque import. Dans Docker, donnez au \*arr un seul volume qui contient tout le point de montage de zurg. Un dossier de téléchargement et des dossiers racine sur deux volumes copient aussi chaque import. Voir [un seul volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
