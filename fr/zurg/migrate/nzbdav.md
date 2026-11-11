# Migrer de nzbdav vers zurg {#migrating-from-nzbdav-to-zurg}

**Lisez d'abord [la page partagée](index.md).** Elle explique le garde-fou de la corbeille et pourquoi votre bibliothèque atterrit dans `__magic__`.

La dernière release de nzbdav-dev est la v0.6.4 d'avril 2026, et le dépôt amont n'est plus maintenu.
Cette release fonctionne. Cette migration consiste à quitter un logiciel non maintenu. Rien ne demande une bascule précipitée.

**C'est la plus simple des cinq migrations.** Si l'on compare avec zurg sur les mêmes cinq releases, l'arborescence de nzbdav ne diffère que sur deux points.

| | |
|---|---|
| zurg ajoute | le fichier `.nfo` de la release |
| zurg perd | 5 volumes par2 nommés par hash, à l'intérieur des releases obfusquées |

**Rien n'est renommé.** Chaque nom de fichier servi par nzbdav est aussi servi par zurg, sous le même nom et dans la même structure de dossiers. Cela vaut aussi à l'intérieur des archives RAR. Les deux serveurs se sont accordés sur les 20 fichiers non-par2 du corpus.

!!!warning Ne jamais parcourir la racine WebDAV
Le magasin d'objets `.ids` de nzbdav matérialise les 16 enfants hexadécimaux à chacun de ses cinq niveaux, quel que soit leur contenu. Cela fait 16^5, soit environ 1,048,576 dossiers. Indiquez explicitement `/content`, `/nzbs` ou `/completed-symlinks` à `find`, `du`, `rclone` ou à tout scanner. Jamais `/`.
!!!

## À quoi ressemble ta bibliothèque ensuite {#what-your-library-looks-like-afterwards}

**Tout est rajouté** parce que la racine de la bibliothèque passe sous `__magic__`.
Il n'existe pas de chemin moins coûteux ni de chemin partiel. Voir [la page commune](index.md)
pour savoir pourquoi.

La bonne nouvelle, c'est que nzbdav est la seule migration où **rien de ce que vous voyez ne change, à part le préfixe**. Chaque nom de fichier que zurg sert est celui que nzbdav servait. Un \*arr qui réimporte depuis `__magic__` analyse exactement ce qu'il analysait avant. Un dossier que vous organisez à la main reste identique à ce qu'il était.

C'est vrai quelle que soit votre installation. Sous Windows, et partout ailleurs où Plex lit directement le montage, les noms de fichiers sont identiques. Si Sonarr et Radarr organisent une bibliothèque de liens symboliques, les noms de fichiers leur appartenaient déjà et la source qu'ils analysent ne change pas. Cette migration ne modifie donc rien à la façon dont votre bibliothèque est lue. Elle change seulement l'endroit où elle se trouve.

## Quel nouveau contenu apparaît {#what-new-content-shows-up}

- Le `.nfo` dans les releases RAR.
- **Clips d'échantillon** dans `Sample/`. nzbdav publie le dossier et le clip, tout comme zurg. Ce n'est *pas* nouveau pour toi. nzbdav est le seul des quatre serveurs à l'avoir déjà fait.
- Dossiers vides pour les releases dont la chaîne d'archives est cassée. nzbdav n'a rien créé pour celles-ci.
- Les fichiers par2 et sfv ne sont plus visibles.

Rien de tout cela ne produit un élément Plex, sauf le clip d'échantillon, et nzbdav te l'affichait déjà. Si ça ne te gênait pas avant, rien ne change.

## Sors tes NZB {#get-your-nzbs-out}

zurg est alimenté par un dossier de fichiers `.nzb`, et nzbdav a encore tous les tiens dans `/nzbs/<category>/`. **Copie-les. Ne les déplace pas.** Supprimer quelque chose dans `/nzbs/` annule la tâche.

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

Les deux serveurs nomment le dossier de la release d'après le *nom de fichier* du NZB. Les stems que tu as récupérés devraient donc correspondre aux dossiers que nzbdav sert. Vérifie-le et renomme ceux qui ne correspondent plus.

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

Deux règles de nommage de zurg valent le coup d'être vérifiées par rapport à cette liste.

- zurg retire un `.mkv` ou `.mp4` final du nom d'un dossier. Si un stem se termine comme ça, mets `retain_folder_name_extension: true`.
- Deux releases différentes qui partagent le même stem reçoivent un suffixe ` {shorthash}` sur l'une des deux. Trouve-les maintenant avec `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`.

## Installer zurg en parallèle {#build-zurg-alongside}

nzbdav continue de servir pendant ce temps. Copie son bloc provider dans la config de zurg.
Donne à zurg son propre point de montage. Dépose les NZB dedans et laisse-le scanner. Le dossier surveillé est pris en compte toutes les 15 secondes environ.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from nzbdav's provider settings
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
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l     # should approach your release count
```

## Basculer {#cut-over}

Une seule méthode, quelle que soit ta situation actuelle. Rien ici ne déplace d'octets.

**1. Active `__magic__`** puis redémarre. Les routes sont enregistrées au démarrage, donc un bouton du tableau de bord ne suffit pas : il faut redémarrer pour que l'espace de noms réponde.

```yaml
magic:
  enabled: true
```

**2. Crée les dossiers racine.** Ils vont à la racine de `__magic__`, à côté de `__all__`, que zurg garde déjà là. Pas dans `__magic__/__all__`, pas dans `__magic__` lui-même et pas à la racine du montage. Sonarr et Radarr signalent un problème de santé pour ces emplacements ; les dossiers à côté ne déclenchent rien.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

`__magic__/__all__` reflète la bibliothèque, donc chaque release est présente avant que tu commences à organiser quoi que ce soit.

**3. Organise-la.** Un `mv` à l'intérieur de `__magic__` écrit une ligne et ne déplace aucun octet.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**Si Sonarr et Radarr ont organisé ton ancienne bibliothèque, transfère-la avec un seul script.** Il renomme chaque fichier vers lequel l'ancienne bibliothèque pointe, dans un nouveau dossier racine sous `__magic__`. Chacun atterrit au chemin que l'*arr attend déjà. Rien n'est copié. Ensuite tu changes le dossier racine de l'*arr sans le laisser rien déplacer. Les étapes et le script sont sur [la page commune](index.md#coming-off-a-symlink-library). Ne laisse jamais un *arr déplacer les fichiers lui-même. Cela franchit la frontière du montage : c'est une copie, et elle retélécharge ta bibliothèque.

Le script a besoin d'une fonction `zurg_path` pour les liens de nzbdav. Enregistre-la sous `zurg_path.sh` à côté de lui et règle `OLDMOUNT` sur le point de montage de nzbdav.

```bash
OLDMOUNT=/mnt/nzbdav            # nzbdav's mount, where the old links point
# The map from each .ids name to its release and file. Built once while nzbdav runs.
[ -s uuid-map.tsv ] || find "$OLDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  rel=${l#"$OLDMOUNT"/completed-symlinks/}      # <category>/<release>/<file>
  printf '%s\t%s\n' "$(basename "$(readlink "$l")")" "${rel#*/}"
done | sort -u > uuid-map.tsv
zurg_path() {
  local rel release name videos
  rel=$(awk -F'\t' -v u="$(basename "$1")" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || return
  [ -f "$ZURG/__all__/$rel" ] && { echo "$ZURG/__all__/$rel"; return; }
  # A file under another name. Take the release's one video.
  release=${rel%%/*} name=${rel##*/}
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

Les liens de nzbdav pointent vers son magasin `.ids`, et zurg n'a rien de tel. La fonction lit donc une fois l'arborescence `completed-symlinks` de nzbdav pour savoir quelle release et quel fichier chaque nom `.ids` représente. Garde nzbdav en marche jusqu'à la fin du script. nzbdav ne renomme rien, donc chaque nom qu'il trouve est un nom que zurg sert.

**4. Pointe Plex vers les dossiers racine que tu as créés** — `__magic__/tv` et `__magic__/movies` — et uniquement vers eux. Jamais vers la racine de `__magic__`, qui contient aussi toute la bibliothèque dans `__magic__/__all__`, et jamais vers `__magic__` *et* un dossier filtré en même temps, sinon chaque épisode est trouvé deux fois. Vérifie que `autoEmptyTrash` vaut `0`. Ajoute le nouvel emplacement et lance une analyse. Ensuite supprime l'ancien. Il s'agit du chemin de bibliothèque de ton *arr, ou du montage nzbdav si Plex le lisait directement.

**5. Vide la corbeille** une fois que tu as vérifié quelques éléments au hasard. L'état de visionnage revient grâce à la correspondance GUID. Les collections et les choix d'affiches, eux, ne reviennent pas.

Laisse nzbdav en marche jusque-là. Ça ne coûte rien et c'est ton retour arrière. Quand tu as fini, arrête-le.

```bash
sudo systemctl stop nzbdav
```

## Après {#afterwards}

Garde le dossier de configuration de nzbdav jusqu'à ce que tu aies streamé depuis un échantillon représentatif.
C'est la seule autre copie de tes NZB.

Passons maintenant à l'acquisition. zurg propose un [point d'accès compatible SABnzbd](../guides/sonarr-radarr.md) (à activer manuellement) que Sonarr et Radarr peuvent utiliser pour récupérer les fichiers.
Il remplace nzbdav comme client de téléchargement de ces applications.
Le téléchargement arrive dans `__magic__/__all__`, et l'import le déplace par simple renommage.
Rien n'est copié.
zurg vérifie chaque téléchargement avant de le signaler comme terminé.
Il interroge les serveurs Usenet sur le début et la fin de chaque fichier.
Il télécharge aussi le premier article de chaque fichier.
Cela représente jusqu'à soixante-quatre articles, plus quelques autres pour une release qui ne comporte que quelques fichiers.
Certains serveurs Usenet annoncent encore qu'un article existe alors que son contenu a été retiré, et seul un téléchargement permet de le voir.
zurg reconstruit une release dont des articles manquent à partir de ses fichiers PAR2, quand c'est possible.
Une release qu'il ne peut pas reconstruire est signalée **Failed**.
Sonarr et Radarr la mettent alors en liste noire et en récupèrent une autre.
La vérification ne porte que sur un échantillon, pas sur le post complet.
Un post qui a perdu une partie que l'échantillon n'a pas atteinte est tout de même signalé Completed, et il échoue au moment de la lecture qui tombe sur le trou.

Garde les dossiers racines de Sonarr et Radarr à l'intérieur de `__magic__`.
Un dossier racine ailleurs entraîne une copie complète de chaque import.
Avec Docker, donne à l'application *arr un seul volume qui contient tout le montage de zurg.
Un dossier de téléchargement et des dossiers racines sur deux volumes entraînent eux aussi une copie de chaque import.
Voir [un seul volume](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
