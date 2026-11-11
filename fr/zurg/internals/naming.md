# nommage zurg {#zurg-naming}

Presque tous les noms qu'affiche zurg sont calculés, jamais stockés. Le nom du dossier d'une release, le nom d'un fichier à l'intérieur, et le nom sur disque de son enregistrement de cache sont tous dérivés du torrent à chaque recherche. Rien ne les écrit pour les relire ensuite, car un nom stocké est une deuxième chose à garder synchronisée avec la bibliothèque, et c'est justement ce que brisent une réparation ou une re-résolution d'un NZB.

L'exception est un renommage demandé par l'opérateur. Celui-ci est stocké, sur la release elle-même, et il l'emporte sur toutes les dérivations ci-dessous. La section 9 présente les règles, et le guide de renommage en donne la version destinée aux utilisateurs. Tout le reste de cette page décrit le nom qu'a une release lorsqu'aucun renommage n'est défini.

Cela a une conséquence qu'il vaut mieux énoncer d'emblée, car c'est la source de la plupart des surprises pour quiconque intègre zurg : un dossier peut changer de nom sans que rien ne l'ait « renommé ». Les entrées ont changé, donc la sortie a changé.

Ce fichier contient les règles, pas les seuils. Lorsqu'une règle est tranchée par une heuristique, il indique la fonction qui la tranche et s'arrête là. Ces heuristiques sont calibrées sur de vraies releases et évoluent, donc les recopier ici ne ferait que créer une deuxième chose à tenir à jour. Les références au code sont relatives au package.

## 1. Le nom du dossier de release {#1-the-release-folder-name}

`internal/torrent/key.go`, GetKey / GetKey_Original

Le nom du dossier sous `__all__/`, le nom du fichier `.zurgtorrent`, la clé utilisée par chaque recherche, et ce que zurg appelle la « access key » ne forment qu'une seule et même chaîne. Elle est déterminée dans cet ordre, la première condition vraie l'emporte :

  | Condition                                   | Nom du dossier            |
  |---------------------------------------------|---------------------------|
  | `ignore_renames: false`, Torrent.Rename défini | Torrent.Rename          |
  | `retain_rd_torrent_name: true`              | Name, non modifié         |
  | `retain_folder_name_extension: true` ET     | Name, non modifié         |
  |   Name contient OriginalName                |                           |
  | sinon — les deux options à leurs valeurs par défaut | OriginalName, `.mp4` puis |
  |                                             |   `.mkv` retirés          |

`retain_rd_torrent_name` est vérifié en premier et masque entièrement `retain_folder_name_extension`. La seconde ne s'applique que lorsque Name contient OriginalName comme sous-chaîne ; sinon, la suppression se fait quand même.

La suppression est un `strings.TrimSuffix` exécuté deux fois, ce qui fait trois règles en une. Seuls `.mp4` et `.mkv` sont retirés, donc `.avi`, `.ts`, `.iso` et les autres restent dans le nom du dossier ; c'est sensible à la casse, donc `Movie.2019.MKV` garde son `.MKV` ; et les deux passes s'enchaînent au lieu d'être des alternatives, donc `Movie.2019.mkv.mp4` devient `Movie.2019`. Un suffixe peut ensuite être ajouté, voir section 4. Le résultat est un seul composant de chemin, jamais découpé sur `/`.

DÉPRÉCIÉ. `retain_folder_name_extension` et `retain_rd_torrent_name` sont dépréciées et seront supprimées. Le comportement reste inchangé pour l'instant, et définir l'une ou l'autre affiche un avertissement au démarrage. Les deux indexent la bibliothèque sur Name, que le compte réécrit sous le nez de zurg (section 2) ; les valeurs par défaut l'indexent sur ce que le torrent déclarait lui-même, que le compte ne touche pas. Sur une instance placée devant Sonarr ou Radarr, c'est-à-dire qui possède un bloc `sabnzbd:` ou `qbittorrent:`, les valeurs par défaut sont les seules correctes, car une access key qui change après un import fait perdre la release. `ignore_renames` n'est pas déprécié.

## 2. D'où viennent Name et OriginalName {#2-where-name-and-originalname-come-from}

  Real-Debrid   `internal/realdebrid/types.go`
                Name = `filename`, OriginalName = `original_filename`

  TorBox        `internal/torbox/types.go`, wireTorrent.originalName
                Name = `name`. OriginalName = le dossier unique dans lequel se
                trouvent tous les fichiers, s'il y en a exactement un ; les
                fichiers à la racine de l'arborescence reprennent `name`, sauf
                un fichier seul sans dossier, qui utilise son propre nom.

  AllDebrid     `internal/alldebrid/types.go`, originalName
                Même règle que pour TorBox, appliquée à la liste de fichiers
                aplatie, avec repli sur le `filename` du magnet.

  NZB           `internal/nzb/provider.go`
                Name et OriginalName valent tous deux releaseName, et le Hash
                du torrent est l'identifiant de la release. Section 3.

Comme les backends debrid dérivent OriginalName du dossier racine du torrent,
deux comptes qui possèdent le même contenu obtiennent le même nom de dossier.

Ce que signifient les deux champs de Real-Debrid, mesuré le 2026-08-27 sur un
compte de test d'environ 84k torrents, avec 252 d'entre eux échantillonnés en
lecture seule via `GET /torrents/info` : `original_filename` était le nom que
le torrent déclarait (le nom du pack ou du dossier) dans tous les cas, et
jamais le nom d'un fichier unique. `filename` n'est pas cela. Il se réduit au
nom de base d'un seul fichier, et ce uniquement lorsqu'un seul fichier d'un
torrent multi-fichiers est sélectionné : 90 des 112 torrents échantillonnés
dans cette configuration, contre 0 des 34 avec plusieurs fichiers sélectionnés
mais pas tous, et 0 des 24 avec tous les fichiers sélectionnés. Sur un pack de
221 fichiers avec un seul épisode sélectionné, `original_filename` affichait
`Marvel Cinematic Universe MCU Collection 2008-2023 1080p jZQ` alors que
`filename` affichait `Spider-Man.No.Way.Home.2021.1080p.BluRay.x264...-NOGRP.mkv`.
Par défaut, on obtient donc le nom du pack, et `retain_rd_torrent_name: true`
donne le nom du fichier individuel. C'est pourquoi ce drapeau est déprécié :
`filename` dépend de l'état du compte, alors que la clé d'accès ne doit pas en
dépendre.

## 3. Nommage des releases NZB {#3-nzb-release-naming}

`internal/nzb/provider.go`, releaseName ; `internal/nzb/parse.go`

L'id de la release, qui est aussi son Hash, vaut `hex(sha1(lowercase(nzb filename)))`
— calculé à partir du nom de fichier et non du contenu, donc réenregistrer un NZB ne détache pas le torrent créé à partir de lui. Le nom du dossier est ce FILENAME sans son extension, sauf si le radical ressemble à un hash ou se réduit à rien après nettoyage ; dans ce cas, on utilise à la place le nom de métadonnées de l'NZB, celui du `<head>`. Le nom de fichier l'emporte parce que c'est le nom écrit par l'indexeur, enregistré par le téléchargeur et celui que l'automatisation recherche pour retrouver la release, alors que les indexeurs reposent souvent avec une ligne subject dans le bloc de métadonnées. `stemLooksJunk`, `looksLikeHash` et `sanitizeReleaseName` dans `internal/nzb/parse.go` tranchent ces trois questions ; considère-les comme des boîtes noires.

## 4. Les trois suffixes de nom {#4-the-three-name-suffixes}

Il existe trois formats de suffixe. Ils n'ont aucun lien entre eux.

  ` {xxxxxx}`   Sur un dossier de release, quand deux releases DIFFÉRENTES portent le même nom :
                six caractères hexadécimaux de l'infohash propre à cette release. Dans le
                groupe, la release LA PLUS RÉCEMMENT AJOUTÉE garde le nom nu et
                toutes les autres prennent le tag. Décidé une fois par rafraîchissement par un passage
                qui voit toute la bibliothèque et enregistré comme KeySuffixed, afin que
                GetKey reste une fonction pure du torrent
                (`internal/torrent/key.go`, disambiguateNames). Un torrent RD
                et un NZB de la même release sont ici deux releases différentes,
                car le hash d'un NZB est un sha1 de son nom de fichier.

  ` (tag).ext`  Sur un FICHIER dont le nom de base se répète dans une même release, car zurg
                aplatit l'arborescence d'un torrent en un seul dossier. Le tag est
                le dossier qui distingue déjà les fichiers en conflit —
                le composant de chemin le moins profond qui est distinct dans tout le groupe — sinon
                six caractères hexadécimaux du sha1 du chemin du fichier. Quelle profondeur
                convient, et ce qu'un composant peut reporter dans un nom de fichier, sont
                `dupeTags` et `sanitizeTag` dans
                `internal/torrent/dupenames.go` ; à traiter comme opaques. Le
                groupe comprend chaque fichier de la liste, sélectionné ou non, si bien qu'un fichier
                qui cesse d'être sélectionné garde la clé sous laquelle il a été classé.
                `__magic__` fait exception : il affiche la
                véritable arborescence de la release, sans aucun tag, car les dossiers
                distinguent les fichiers à cet endroit — voir la section 8.

  `_xxxxxxxx`   Sur un nom de fichier SUR DISQUE dont l'entrée contenait un caractère non ASCII
                : huit caractères hexadécimaux du sha256 de cette entrée.
                Section 6. N'apparaît jamais sur le point de montage.

## 5. Noms de fichiers dans une release {#5-file-names-inside-a-release}

`internal/torrent/manager.go`. VisibleName(key, file) est l'unique référence pour le nom qu'affiche le montage et le nom que doit trouver une recherche : un File.Rename s'il existe et que `ignore_renames` est à false, sinon la clé de SelectedFiles, qui contient déjà le tag de la section 4. GetFilename renvoie à la place `filepath.Base(file.Path)`, donc il supprime ce tag. L'affichage et la recherche doivent tous les deux passer par VisibleName, sinon une requête pour un nom tagué ne correspond à rien alors que N fichiers partagent un même nom sans tag.

## 6. Noms de fichiers sur le disque {#6-on-disk-filenames}

`internal/torrent/utils.go`, sanitizeFilename — c'est opaque, et ça ne s'applique QU'AUX
fichiers que zurg écrit sur l'hôte (`data/<name>.zurgtorrent` et l'arborescence STRM),
jamais à ce que le mount sert. C'est bien plus agressif que tout ce qui est au-dessus :
une release dont le dossier du mount s'appelle `Три богатыря` a un fichier de cache
dont le nom est une suite de tirets bas, suivie du suffixe `_xxxxxxxx` qui le garde distinct
du titre cyrillique suivant. C'est un espace de noms différent, et il n'est pas censé correspondre.

## 7. Contenu des archives {#7-archive-interiors}

Une release servie depuis une archive RAR, ZIP ou 7z affiche le contenu de l'archive, pas ses volumes, et deux règles changent le nom de ces éléments.
`stripRedundantRoot` (`internal/universal/rar_streamer.go`) supprime les dossiers de tête qui enveloppent toute l'archive. `payloadRenames` (`internal/universal/deobfuscate.go`) affiche un seul fichier brouillé sous le nom de la RELEASE, en déplaçant toutes les entrées qui partagent son radical. Ce qui est considéré comme brouillé, c'est `looksObfuscated` dans le même fichier, le port zurg du test de SABnzbd. C'est opaque, tout comme les garde-fous autour. Rien n'est réécrit sur le disque, et `archiveName` retrouve aussi l'orthographe propre de l'archive.

## 8. Noms de dossiers {#8-directory-names}

`internal/torrent/manager.go`, `internal/torrent/provider_directories.go`

Intégrés et réservés :

    __all__          chaque release
    __unplayable__   releases sans aucun fichier lisible
    __dump__         torrents déversés
    __downloads__    la vue des téléchargements
    __magic__        la couche inscriptible, le seul répertoire dont la disposition
                     est stockée plutôt que calculée. Son propre `__all__` reflète
                     la bibliothèque : chaque release contenue dans `__all__` y
                     apparaît sous forme de l'arborescence que décrivent les valeurs
                     `File.Path` de ses fichiers, et non aplatie
                     (`internal/magic/tree.go`). Tout ce qui se trouve à côté de ce
                     miroir est ce que l'utilisateur a stocké. Le miroir est calculé,
                     donc rien ne peut y être écrit ; `MirrorDirectory` dans
                     `internal/magic/resolve.go` le désigne
    int__all__       index de hash interne

`__downloads__` et `__magic__` ne sont pas des filtres : ils sont donc ajoutés à la main à la liste de la racine, et `__magic__` n'apparaît que si magic est activé. Tout nom commençant par `int__` est entièrement ignoré dans la liste de la racine.

Pour chaque compte, il existe un répertoire de plus, `"__" + account name + "__"` — `__realdebrid__`, `__torbox__`, `__nzb__` — construit à partir du bloc providers. Il décide aussi d'où viennent les lectures : un fichier ouvert sous `__torbox__` est servi par TorBox, même si un autre compte possède la même release et l'emporterait selon l'ordre de la config. Un compte dont le nom entrerait en collision avec un nom réservé n'en obtient aucun, et zurg affiche un avertissement.

Tout le reste à la racine est une clé du bloc `directories:`, telle quelle.

## 9. Renommages par l'utilisateur {#9-user-renames}

`internal/torrent/rename.go`, `internal/torrent/rename_bulk.go`

Un renommage est un affichage, pas une modification de quoi que ce soit sur le compte debrid. Il est stocké
comme Torrent.Rename ou File.Rename et l'emporte sur toutes les dérivations ci-dessus, jusqu'à ce que
`ignore_renames: true` fasse ignorer complètement le renommage à zurg.

Un renommage de torrent n'est accepté que si le nom, après suppression des espaces en début et en fin, n'est pas vide,
ne contient ni `/` ni `\`, est égal à son propre `filepath.Clean` (ce qui rejette aussi `.` et `..`) et n'entre pas
en conflit avec une clé d'accès existante appartenant à un autre hash. Son application réindexe les maps de
répertoires, écrit le `.zurgtorrent` sous le nouveau nom et SUPPRIME celui de l'ancien nom. S'il reste en place, au
redémarrage les deux sont chargés et le renommage revient silencieusement en arrière.

La correction de saison (`/torrents/season-fix/plan` et `/apply`) est un renommage de fichiers en masse piloté par
la correspondance des épisodes de Plex elle-même. plan est en lecture seule et donne une raison de saut par fichier.
apply prend une liste explicite de hashes plutôt qu'un indicateur apply-all. Le tableau de bord pilote les deux depuis
`/season-fix/`, qui est aussi l'endroit où les règles de mapping et les raisons de saut sont expliquées à
l'opérateur.

## 10. Conséquences pour tout ce qui s'intègre à zurg {#10-consequences-for-anything-integrating-with-zurg}

Si tu construis un chemin à partir du nom du torrent (une ferme de liens symboliques, un mapping de chemin distant, un script), voici les façons dont ça peut mal tourner :

  a. L'extension. Seuls `.mkv` et `.mp4` sont retirés, en tenant compte de la casse. Tout autre conteneur garde son extension dans le nom du dossier.

  b. Le renommage. `Torrent.Rename` l'emporte sur le nom dérivé, et le renommage du torrent par RD modifie `Name` sans prévenir.

  c. Le suffixe de hash. Si deux releases différentes portent le même nom, l'une d'elles reçoit ` {a1b2c3}`, et laquelle change au fur et à mesure que du contenu est ajouté.

  d. Le tag de fichier en double. Un fichier dont le nom de base se répète dans une release est servi sous la forme `name (tag).ext`, où le tag est un composant de répertoire ou un hash de chemin. `filepath.Base(file.Path)` ne le reproduit pas.

  e. Le renommage d'archive. Une charge utile obfusquée à l'intérieur d'une archive est présentée sous le nom de la release, et non sous son propre nom.

  f. Les noms NZB viennent du FILENAME du `.nzb`, et non de ce qui se trouve à l'intérieur, sauf si le nom de fichier est un hash. Nomme le fichier, nomme le dossier.

  g. Les noms de fichiers nettoyés sur le disque forment un espace de noms différent de celui des noms montés, et pour les releases non ASCII, ils ne correspondent volontairement pas.

La méthode fiable pour retrouver une release est de passer par le hash, puis de demander à zurg comment elle s'appelle. Reconstruire le nom, c'est deviner, et chaque règle ci-dessus est une façon de se tromper dans la supposition.
