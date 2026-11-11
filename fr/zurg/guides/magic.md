# `__magic__`, un répertoire que vous pouvez organiser {#__magic__-a-directory-you-can-organise}

Tous les autres dossiers de zurg sont calculés. `movies` applique le filtre films. `__all__` contient tout.
Un dossier de release contient ce que le compte signale. La structure est reconstruite à chaque actualisation.

`__magic__` est le seul dossier dont les chemins sont **stockés**. Un déplacement réécrit une seule ligne de table. Aucun octet ne bouge et le compte debrid reste inchangé. Organisez-le à la main ou laissez Sonarr et Radarr l'utiliser.

Il contient trois types de choses. `__magic__/__all__` contient toutes les releases qui n'ont encore été placées nulle part, et c'est le dossier depuis lequel les clients de téléchargement importent. Il est calculé, donc rien ne peut être créé à son niveau supérieur, et les octets d'un fichier ne peuvent pas être écrits sous un nom déjà utilisé par un dossier de release (un dossier de release accepte les fichiers annexes sous des noms qu'il n'utilise pas). Avec une clé de sponsor DMM, zurg range dans `__movies__` et `__shows__` tout ce que DMM a identifié, par titre ([ci-dessous](#__movies__-and-__shows__-sorted-by-title)). Tout le reste à la racine de `__magic__` est à vous :

```
/mnt/zurg/__magic__
├── __all__     <- what nothing has placed yet, where a grab lands
├── __movies__  <- films zurg filed by title
├── __shows__   <- shows zurg filed by title
├── __anime__   <- anime shows, with magic.anime: true
├── anime
├── movies
└── tv          <- your *arr root folders
```

Les chemins de cette page utilisent le point de montage Linux, `/mnt/zurg`. Sous macOS c'est `/Volumes/Zurg` et sous Windows `Z:\`, donc `/mnt/zurg/__magic__/tv` devient `/Volumes/Zurg/__magic__/tv` ou `Z:\__magic__\tv`.

Cette séparation est le principe même. Le dossier depuis lequel un client importe et les dossiers dans lesquels il importe sont frères, donc aucun ne contient l'autre : un import manuel pointé sur le dossier de téléchargement ne parcourt pas votre arborescence de bibliothèque, et ni Sonarr ni Radarr ne signalent cette disposition.

Elle est désactivée par défaut. Activez-la avec :

```yaml
magic:
  enabled: true
```

puis redémarrez. Les routes sont définies au démarrage, donc changer ce réglage depuis le tableau de bord nécessite un redémarrage avant que l'espace de noms réponde.

## À quoi ça sert {#what-it-is-for}

Un \*arr importe en **déplaçant** le fichier du dossier de téléchargement vers la bibliothèque. zurg n'avait nulle part où recevoir ce déplacement, alors le \*arr est revenu à la copie. Or une copie depuis un montage debrid signifie télécharger la release entière à travers le réseau, ce que le montage existe justement pour éviter.

Avec `__magic__`, l'import est un renommage au sein d'un seul espace de noms : une ligne est écrite, le fichier apparaît là où le \*arr l'a placé, et rien n'est téléchargé. C'est ce qui rend [le point d'accès SABnzbd](sonarr-radarr.md) utile. Il n'est qu'une fine couche par-dessus ceci, et sans lui chaque import serait un téléchargement complet.

Cela ne fonctionne que si le **dossier racine** du \*arr se trouve aussi dans `__magic__`, par exemple `/mnt/zurg/__magic__/tv`, et non dans un répertoire ailleurs sur la machine. Un déplacement dont la destination est hors de l'espace de noms est un déplacement entre deux systèmes de fichiers, donc une copie à nouveau. zurg le refuse donc purement et simplement avec un `403`, plutôt que de le laisser se faire discrètement. Le seul endroit à l'intérieur de l'espace de noms qui est aussi refusé est le sommet de `__magic__/__all__`, qui correspond à la disposition propre de la bibliothèque et non à un endroit où placer des fichiers. [sabnzbd.md](sonarr-radarr.md) contient les paramètres exacts.

Un fichier placé hors de `__all__` reste listé là-bas, et une suppression dans `__all__` supprime le fichier du compte. zurg refuse donc de supprimer un fichier via `__all__` ou tout autre dossier de la bibliothèque tant qu'un placement ici le diffuse depuis ce fichier. Supprimez-le plutôt sous `__magic__`. C'est ce qui empêche un \*arr qui importe depuis `__all__` puis nettoie son dossier de téléchargement là-bas, comme le fait un \*arr alimenté par le proxy SABnzbd de DMM, de supprimer la release qu'il vient d'importer.

Le \*arr doit aussi atteindre le dossier de téléchargement et le dossier racine **à travers un seul montage**. Un conteneur auquel on donne `__magic__/__all__` et `__magic__/tv` comme deux volumes distincts voit deux systèmes de fichiers, même si les deux appartiennent à zurg. Le noyau refuse alors le renommage à l'intérieur du conteneur avant que zurg n'en soit informé, et le \*arr copie le fichier entier à la place. zurg transforme une telle copie en placement une fois qu'elle est terminée et journalise `A client copied …`, mais le téléchargement a déjà eu lieu. Montez un seul répertoire contenant tout le montage de zurg dans le conteneur ; voir [Un seul volume pour le dossier de téléchargement et les dossiers racines](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

Les acquisitions propres à zurg placent aussi des fichiers ici. Une source Radarr dépose chaque release confirmée dans le dossier du film avec le même déplacement qu'un import, puis demande à Radarr de relancer une analyse : voir [acquisition.md](acquisition.md#placing-the-file).

zurg place aussi des fichiers de son côté, dans `__movies__` et `__shows__` : voir [ci-dessous](#__movies__-and-__shows__-sorted-by-title).

L'organisation manuelle de la bibliothèque est l'autre moitié, et elle fonctionne sans aucun \*arr.

## Sans rien stocké, ce sont les releases de `__all__` en vrais dossiers {#with-nothing-stored-it-is-__all__s-releases-as-real-folders}

Ouvre `__magic__/__all__` sur une installation neuve et tu obtiens chaque release que `__all__` contient, chacune dans son propre dossier. La table commence vide et ne stocke que les **écarts** par rapport à ce comportement par défaut. Une bibliothèque non modifiée ne stocke donc rien du tout, la racine de `__magic__` ne contient que le miroir, et les nouvelles releases y apparaissent dès qu'elles arrivent ailleurs. Dès que quelque chose place une release (l'import d'un \*arr ou le classement de zurg lui-même dans `__movies__` et `__shows__`), elle sort de `__magic__/__all__` : le miroir ne contient que ce qui n'a encore été placé nulle part.

Il n'y a aucune configuration de répertoire derrière cela : pas de `only_show_the_biggest_file`, pas de filtres de taille. Ce que la release contient, c'est ce que tu vois.

La seule différence avec `__all__` concerne **la structure interne d'un dossier de release**. Partout ailleurs, zurg aplatit une release en un seul répertoire, indexé par nom de fichier, avec un suffixe lorsque deux fichiers entreraient en collision :

```
__all__/Show.S01/Show.S01E01.mkv
__all__/Show.S01/Gag Reel (Extras).mkv
```

`__magic__/__all__` affiche l'arborescence réelle de la release :

```
__magic__/__all__/Show.S01/Show.S01E01.mkv
__magic__/__all__/Show.S01/Extras/Gag Reel.mkv
```

Ce n'est pas anodin. Sonarr et Radarr analysent un dossier de téléchargement comme un dossier : un fichier situé dans un **sous-dossier** nommé `extras`, `samples`, `featurettes`, `trailers` ou `deleted scenes` est ignoré, tandis qu'un fichier au niveau supérieur est pris en compte. Ainsi, le fichier aplati `Gag Reel (Extras).mkv` est proposé à l'import alors que l'arborescence réelle le laisse de côté. De plus, leur import ne se rabat sur le titre du téléchargement pour l'analyse que si le dossier ne contient qu'une seule vidéo : un film aplati à côté de son making-of perd donc cette solution de repli. Comme [le point d'accès SABnzbd](sonarr-radarr.md) fournit à un \*arr un dossier situé sous `__magic__/__all__`, c'est sur cette surface que ces règles s'appliquent.

Deux détails sur la forme :

- **Un dossier englobant unique est supprimé.** Presque toutes les releases sont un dossier unique qui contient tout, et ce dossier est déjà le nom de la release : les backends debrid en dérivent le nom. Ainsi, `/Show.S01/Season 01/ep1.mkv` s'affiche sous la forme `Show.S01/Season 01/ep1.mkv`, et non `Show.S01/Show.S01/Season 01/ep1.mkv`. Un seul niveau est retiré, et seulement s'il n'y a rien à côté : une release qui contient un fichier au premier niveau et un dossier à côté conserve les deux.
- **Pas de suffixes pour les noms en double.** Ils servent à rendre une liste aplatie non ambiguë, et une arborescence dispose déjà de dossiers pour cela.

Le reste d'un dossier de release reste inchangé, y compris pour une archive : un jeu RAR reste explorable comme un répertoire, en se trouvant désormais là où se trouvent ses volumes dans l'arborescence, et une release servie depuis une archive unique aplatie continue d'afficher le contenu de cette archive.

`__all__` et les filtres `directories:` restent aplatis. Ce sont eux que tu dois pointer vers ton serveur multimédia, et rien ne change pour eux.

## Organiser {#organising-it}

Via le montage, avec des commandes ordinaires :

+++ Linux
```bash
mkdir -p /mnt/zurg/__magic__/tv/The\ Show/Season\ 01
mv /mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /mnt/zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ macOS
```bash
mkdir -p /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01
mv /Volumes/Zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv \
   /Volumes/Zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```
+++ Windows
```powershell
New-Item -ItemType Directory -Force "Z:\__magic__\tv\The Show\Season 01"
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Release.S01E01.1080p\ep1.mkv" `
  -Destination "Z:\__magic__\tv\The Show\Season 01\S01E01.mkv"
```
`-LiteralPath` évite que les crochets présents dans beaucoup de noms de release soient interprétés comme des caractères génériques.
+++

Le fichier se trouve désormais au nouveau chemin et n'existe plus à l'ancien. Il est toujours diffusé depuis le même compte.

Les dossiers de release entiers se déplacent aussi, en une seule ligne :

+++ Linux
```bash
mv /mnt/zurg/__magic__/__all__/Some.Movie.2024.2160p /mnt/zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ macOS
```bash
mv /Volumes/Zurg/__magic__/__all__/Some.Movie.2024.2160p /Volumes/Zurg/__magic__/movies/Some\ Movie\ \(2024\)
```
+++ Windows
```powershell
Move-Item -LiteralPath "Z:\__magic__\__all__\Some.Movie.2024.2160p" -Destination "Z:\__magic__\movies\Some Movie (2024)"
```
+++

Les répertoires se déplacent avec tout ce qu'ils contiennent, en un seul lot. Les déplacements fonctionnent dans les deux sens : un fichier peut être déplacé *dans* un dossier de release, ou en sortir, et le dossier l'affiche à côté des entrées propres à la release. C'est ce dont a besoin un programme qui remet quelque chose dans le dossier d'où il importe. Lorsqu'un nom arrive de deux endroits à la fois, c'est le choix délibéré qui l'emporte : ce que vous avez déplacé passe avant ce que la release appelle ce nom, qui passe lui-même avant un vrai fichier dans `data/local`. Le perdant est omis plutôt que listé deux fois.

Une seule forme échoue avec le montage intégré, et uniquement avec le réglage par défaut `union_writable: local` : renommer un répertoire *que vous avez créé via le montage*, c'est-à-dire un `mkdir` suivi, plus tard, d'un `mv` sur ce répertoire. Avec l'ordre par défaut, `mkdir` crée le répertoire sur l'amont local de rclone, alors que les lignes qui se trouvent dessous font exister le même répertoire côté serveur. rclone renomme donc sa copie locale, déplace les lignes une par une (zurg répond correctement à chacune), puis échoue en voulant supprimer une source qu'il a déjà renommée :

```
ERROR : __magic__/tv/Saul: Dir.Rename error: RenameDir rmdir: object not found
```

Les lignes finissent exactement là où vous l'avez demandé : zurg sert le nouveau chemin et renvoie 404 pour l'ancien. Mais `mv` se termine avec le code 1, et le montage affiche le répertoire source vidé, et non la destination, tant que sa liste n'a pas été relue. Aucune requête de suppression n'atteint zurg, donc rien de ce que fait zurg ne peut l'empêcher. Déplacer des fichiers, ou un dossier de release entier, fonctionne avec les deux ordres. Si vous réorganisez des répertoires via le montage, réglez [`union_writable: server`](../reference/config.md#rclone-settings) : le répertoire n'existe alors que dans l'espace de noms, et le renommage devient une seule opération côté serveur. Mesuré avec rclone 1.71.2.

`rm` masque les éléments, voir [Supprimer masque, ne détruit pas](#deleting-hides-it-does-not-destroy).

## `__movies__` et `__shows__`, triés par titre {#__movies__-and-__shows__-sorted-by-title}

Kodi et Plex devinent ce qu'est un fichier à partir des noms de ses dossiers et de ses fichiers, et un nom de release comme `Succession.S01.MULTi.1080p.BluRay.REMUX.AVC-DEMS` est souvent trop compliqué pour eux. Avec les noms de release bruts, Kodi a reconnu 8 séries sur 56 dans notre test. Avec une clé sponsor DMM, zurg range chaque release identifiée par DMM dans deux dossiers, sous des noms que les lecteurs reconnaissent tout de suite :

```
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.mkv
__magic__/__movies__/Casper (1995) {tmdb-8839}/Casper (1995) {tmdb-8839}.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/tvshow.nfo
__magic__/__shows__/Detective Conan (1996) {tmdb-30983}/Season 01/Detective Conan (1996) - S01E1194 [tmdbid-30983].mkv
```

La même bibliothèque rangée de cette façon a permis à Kodi et Plex de reconnaître les 70 films, les 44 séries et les 554 épisodes.

### Activer {#turning-it-on}

Il te faut un nightly de zurg daté du 2026-10-26 ou plus récent, `__magic__` activé, et ta clé API DMM, celle que [gatekeeper](https://gatekeeper.debridmediamanager.com/) te montre une fois que tu as sponsorisé :

```yaml
magic:
  enabled: true
dmm_api_key: YOUR_DMM_API_KEY
```

Redémarre zurg. Les deux dossiers se remplissent une fois la bibliothèque chargée et identifiée par DMM, ce qui prend quelques minutes la première fois sur une grosse bibliothèque. Ensuite, une nouvelle sortie est classée moins d'une minute après que DMM l'a identifiée. Ajoute une bibliothèque **Movies** pointant vers `/mnt/zurg/__magic__/__movies__` et une bibliothèque **TV** pointant vers `/mnt/zurg/__magic__/__shows__` (`/Volumes/Zurg/__magic__/...` sous macOS, `Z:\__magic__\__movies__` et `Z:\__magic__\__shows__` sous Windows), puis lance un scan. Dans Kodi, règle le scraper de la source TV sur **The Movie Database**, comme c'est le cas par défaut, et garde-le à jour : les fichiers `tvshow.nfo` nécessitent la version 1.7 ou plus récente du scraper TMDb TV de Kodi.

Pointe chaque bibliothèque vers son propre dossier, jamais vers `__magic__` lui-même : cela scannerait aussi `__all__` et tes autres dossiers, et tout apparaîtrait deux fois.

### Ce que ça fait {#what-it-does}

- **Le film ou la série est ce que DMM dit qu'il est**, jamais une règle de dossier. Un film venu dans le pack d'une série est classé comme ce film.
- **Chaque release d'une série atterrit dans un seul dossier**, avec les saisons et les épisodes numérotés comme TMDB les numérote, c'est-à-dire dans l'ordre que Plex utilise par défaut. Les animés numérotés selon leur diffusion sont placés dans leur saison : `Detective Conan - 1194` correspond à S01E1194.
- **L'identifiant TMDB figure dans le dossier, dans chaque nom de fichier et dans le `.nfo`**, pour que chaque lecteur le trouve là où il le cherche : Plex dans le dossier, Kodi dans le `.nfo`, et les lecteurs qui ne lisent que les noms de fichiers dans le nom de fichier.
- **Une seule copie par titre.** Quand deux releases correspondent au même épisode ou au même film, la meilleure est classée, d'abord selon la résolution puis selon la taille ; l'autre reste dans `__all__`.
- **Les bonus et les samples restent dans `__all__`**, tout comme ce que DMM n'a pas identifié. Une release est classée une fois que DMM l'a identifiée.

### Les animés dans un dossier à part {#anime-in-a-folder-of-its-own}

Les séries d'anime peuvent aller dans un troisième dossier, `__anime__`, pour que Kodi et Plex aient une bibliothèque Anime à part, comme avec un second Sonarr dédié à l'anime. Il te faut un nightly de zurg du 2026-11-10 ou plus récent, plus une ligne de plus :

```yaml
magic:
  enabled: true
  placement: true
  anime: true
dmm_api_key: YOUR_DMM_API_KEY
```

Redémarre zurg, puis ajoute une bibliothèque **TV** pointée sur `/mnt/zurg/__magic__/__anime__` et lance un scan. Ce qui compte comme anime, c'est DMM qui décide, à partir de TMDB : une série que TMDB classe comme animation, en japonais et venant du Japon, les trois à la fois, ou une série que TMDB tague avec le mot-clé *anime*. Detective Conan, Ace of the Diamond et Cyberpunk: Edgerunners vont dans `__anime__` ; Hazbin Hotel (animation américaine), Alice in Borderland (japonais, en prises de vue réelles) et LINK CLICK (animation chinoise) restent dans `__shows__`. Les films restent dans `__movies__`, films d'anime compris : une bibliothèque Movies ne peut être que d'un type, et ce dossier aussi.

Activer l'option déplace en quelques minutes toutes les séries d'anime hors de `__shows__`, ce que tes lecteurs voient comme des séries qui quittent une bibliothèque pour apparaître dans une autre :

- **Plex** les retire de la bibliothèque TV (en *missing*, ou supprimées complètement si tu vides la corbeille après chaque scan) et les récupère dans la bibliothèque Anime au scan suivant. L'état de visionnage suit : Plex le rattache à la série, pas à la bibliothèque, donc un épisode vu dans la bibliothèque TV apparaît comme vu dans la bibliothèque Anime (mesuré le 2026-11-09).
- **Kodi** rattache l'état de visionnage au chemin du fichier, donc exporte ta bibliothèque vidéo (Settings → Media → Library → Export) avant d'activer l'option, puis réimporte-la une fois la source Anime scannée.

Désactiver l'option les ramène de la même façon.

### Avec la liste de souhaits DMM {#with-the-dmm-wanted-list}

Appuyez sur **Want** dans DMM et zurg récupère le titre ([liste de souhaits DMM](dmm-wanted.md)). Ce qu'il récupère est classé ici comme tout le reste, donc le film ou la série apparaît dans Kodi et Plex sous son propre nom, sans Sonarr ni Radarr. Un torrent récupéré peut prendre jusqu'à une heure avant d'être classé ; un NZB est classé dès que DMM l'identifie.

### Avec Sonarr et Radarr {#with-sonarr-and-radarr}

Ils gardent leurs propres bibliothèques. Une release que Sonarr ou Radarr a récupérée via zurg reste dans `__all__` pour qu'ils l'importent, dès le moment où ils la récupèrent, et zurg ne touche jamais aux fichiers qu'ils ont placés. Si l'un d'eux importe un titre que zurg a déjà rangé, en le déplaçant dans son propre dossier racine, il lui appartient à partir de là et zurg le laisse en place.

Pour que Kodi et Plex associent leurs bibliothèques de la même façon :

- Activez **Settings → Metadata → Kodi (XBMC) / Emby** dans chacun. Ils écrivent alors un `.nfo` avec les ids du titre à côté de chaque film et de chaque série, et zurg le conserve.
- Mettez l'id dans les noms de dossiers, sous **Settings → Media Management** :

  | | Format de dossier |
  |---|---|
  | Radarr | `{Movie CleanTitle} ({Release Year}) {tmdb-{TmdbId}}` |
  | Sonarr | `{Series TitleYear} {tvdb-{TvdbId}}` |

### Bon à savoir {#good-to-know}

- **Supprimer dans un lecteur masque le fichier**, comme toute suppression dans `__magic__`. Il reste sur votre compte débrid, et zurg ne le reclasse pas.
- **Rien ne peut être déplacé dans `__movies__`, `__shows__` ou `__anime__` :** ces dossiers sont réservés à zurg. Vous pouvez en sortir un élément, comme le fait un import \*arr, et cela fonctionne.
- **Quand l'identification d'une release change dans DMM**, zurg déplace ses fichiers vers le nouveau nom.
- **Un fichier défectueux garde sa place** pendant que zurg le répare, pour que votre serveur multimédia ne le perde pas.
- **Sans clé de sponsor DMM, rien n'est classé.** Retirer la clé, ou désactiver `__magic__`, laisse ce qui a été classé à son emplacement actuel.

## Un déplacement survit à la réparation, au renommage et à la nouvelle liste {#a-move-survives-repair-rename-and-re-listing}

zurg répare une release cassée en la rajoutant au compte. L'id du torrent change, la clé d'accès change, les ids des fichiers changent. Une table indexée sur l'un de ces éléments perdrait donc chaque placement la première fois qu'un lien pourrit. Les lignes sont donc indexées sur le **hash de contenu** de la release et le **chemin du fichier à l'intérieur de la release**, deux éléments que la réparation ne modifie pas.

Les conséquences, toutes voulues :

- **Une réparation conserve votre organisation.** La release revient avec un nouvel id, et les fichiers restent là où vous les avez placés.
- **Renommer une release ne déplace rien.** Un renommage, et le suffixe que zurg ajoute quand deux releases différentes auraient le même nom de dossier, modifient tous deux le nom du dossier par défaut de la release. Les placements ne sont pas affectés.
- **Un fichier disparu n'est pas oublié.** Si une réparation modifie l'ensemble des fichiers (la cause habituelle est Real-Debrid qui reconditionne une release en rar), une ligne dont le fichier n'existe plus est *conservée mais non listée*. Si le fichier revient, sa position revient aussi. Les lignes dans cet état apparaissent sur le tableau de bord sous le nom **dangling**, où vous pouvez les supprimer.
- **Supprimer une release puis la rajouter conserve aussi votre organisation.** La réinsertion DMM, ou une suppression suivie d'un nouvel ajout de la même release, retrouve le même hash. Les fichiers retournent là où vous les aviez placés, et un dossier que vous avez supprimé, comme le dossier de tâche qu'un \*arr supprime après un import, reste caché. Pour remettre la release dans `__magic__/__all__`, recherchez-la sur la page `__magic__` du tableau de bord et appuyez sur **Unhide** sur son entrée tombstone.

Un backend demande plus qu'une simple correspondance exacte du chemin. Les noms de fichiers d'un post Usenet sont *résolus* plutôt que fournis : ils sont recalculés à chaque chargement et jamais stockés. Donc un post lu d'abord alors que le serveur de news était injoignable garde ses noms obfusqués jusqu'à ce qu'un chargement ultérieur récupère les vrais noms. Pour ces cas, une ligne se rabat d'abord sur l'index du fichier dans le NZB, puis sur le nom de base plus la taille, lorsqu'exactement un fichier correspond.

## Supprimer masque, ça ne détruit pas {#deleting-hides-it-does-not-destroy}

`rm` sous `__magic__` écrit une **pierre tombale** : l'entrée disparaît de `__magic__`, mais reste exactement à sa place dans `__all__`, dans chaque dossier de filtre et sur le compte debrid. Rien n'est supprimé.

Ce n'est pas de la frilosité, c'est ce qui rend un \*arr sûr à brancher. Lors d'une amélioration de qualité, un \*arr supprime l'ancien fichier, et à l'import il supprime tout le dossier de la tâche. Si ces suppressions retiraient du contenu, une amélioration détruirait la release. Et si une suppression ne retirait que la *ligne*, le fichier réapparaîtrait à son emplacement par défaut, juste dans le dossier où le \*arr importe.

Si tu veux qu'une suppression supprime vraiment :

```yaml
magic:
  allow_delete: true
```

Alors une suppression de **fichier** retire aussi le contenu du compte. Un dossier de release ou un répertoire ne sont jamais supprimés, quel que soit ce réglage : le premier est ce que Sonarr supprime après chaque import.

Une entrée dans une archive correspond à l'épisode ou au film de la plupart des releases Usenet. Elle n'a pas de fichier à elle. L'archive contient aussi tout le reste de la release. Supprimer une entrée ne retire donc la release entière que lorsque plus rien sous `__magic__` n'en utilise une partie. Aucun fichier de celle-ci ne doit encore être placé quelque part. Son dossier doit être supprimé ou ne plus rien avoir à importer. C'est l'état dans lequel une amélioration laisse un épisode Usenet remplacé. Tant que ce n'était pas géré, la release remplacée restait dans la bibliothèque, et son NZB dans `nzbs/`, pour toujours.

Une vidéo simple est supprimée seule. Sa release disparaît aussi dès que plus rien sous `__magic__` n'en utilise une partie. Les mêmes deux règles décident. Les releases publient plus que leur vidéo. Un `.nfo`, des sous-titres ou une affiche se trouvent à côté, et personne ne les importe. Tant que ce n'était pas géré, ils maintenaient la release dans la bibliothèque après la suppression de sa seule vidéo. Son NZB restait dans `nzbs/` et une release debrid restait sur le compte. Un autre épisode du même pack garde la release tant qu'il est placé ou encore dans le dossier de release. Il en va de même pour un dossier de release déplacé ailleurs, ou pour un épisode qui ne se lit plus mais peut encore être réparé. Supprimer un fichier annexe à l'endroit où il a été publié ne supprime jamais la release. Supprimer le dernier sous-titre importé par Sonarr ou Radarr à côté de la vidéo, si.

`dav_allow_rename` et le chemin de suppression direct du montage, sans contrôle, n'ont rien à voir avec tout cela. Ces options couvrent les chemins qui renomment et détruisent ce que le compte debrid contient. Une écriture sous `__magic__` n'atteint aucun compte. `mount_read_only: true` prime toujours sur tout, au niveau du noyau.

Annuler une pierre tombale se fait d'un clic sur le tableau de bord.

Une amélioration laisse donc la release qu'elle a remplacée dans ta bibliothèque. **Manage > Duplicates** liste ces restes à côté de la release que le \*arr utilise désormais, et supprime ceux que tu choisis : voir [recherche des releases en double](acquisition.md#finding-duplicate-releases).

## Les filtres et `__all__` ne changent pas {#filters-and-__all__-are-untouched}

Un release que tu as déplacé reste dans `movies`, dans `recent` et dans `__all__`, sous son nom d'origine. `__magic__` est une seconde vue de la même bibliothèque, pas un déplacement.

Ça surprend pas mal de monde, donc autant le dire clairement : **déplacer quelque chose dans `__magic__` ne change que `__magic__`.** Les dossiers de filtres sont calculés à partir du release, et le release, lui, n'a pas changé.

Pour un media server, n'en pointe qu'**un** des deux. Une bibliothèque Plex qui scanne à la fois `shows/` et `__magic__/tv` trouvera chaque épisode en double. Idem pour `__movies__`, `__shows__` et `__anime__` : pointe une bibliothèque sur l'un d'eux, jamais sur `__magic__` lui-même.

## Sidecars : `.nfo`, affiches, sous-titres {#sidecars-nfo-posters-subtitles}

Un \*arr écrit ses métadonnées à côté de la vidéo, et Bazarr écrit les sous-titres. Ce sont de vrais fichiers, et zurg n'a nulle part où les mettre dans une bibliothèque debrid. Ils vont donc sur le disque local, dans `data/local/__magic__/`.

Pour configurer Bazarr, et voir comment ses sous-titres arrivent jusqu'à rex, consulte [Sous-titres avec Bazarr](subtitles.md).

Si tu utilises le montage intégré de zurg, tout se fait déjà et tu n'as rien à faire : le montage est une union de `data/local` et du WebDAV de zurg, et rclone envoie chaque nouveau fichier créé vers la partie locale. zurg ne voit même jamais l'écriture. C'est aussi pour ça que le test « ce dossier est-il accessible en écriture ? » de Sonarr réussit.

Si tu montes `/dav` toi-même (ton propre rclone, Infuse, un lecteur WebDAV sous Windows), zurg accepte le `PUT` et écrit dans ce même arbre, donc les deux vues restent cohérentes. Deux limites s'appliquent :

```yaml
magic:
  sidecar_max_mb: 32       # per file
  sidecar_budget_mb: 2048  # the whole tree
```

La première renvoie une erreur `413`, la seconde une erreur `507`. Elles bornent ce que *zurg* écrit. Avec le réglage par défaut `union_writable: local`, zurg ne peut pas refuser les fichiers créés directement par l'upstream local de rclone. En revanche, l'arbre est recalculé avant tout refus, donc les fichiers que rclone a déposés là comptent dans le budget la prochaine fois que zurg doit écrire quelque chose. Les fichiers plus gros que `sidecar_max_mb` sont exclus de ce calcul. Avec `union_writable: server`, c'est l'inverse : la création arrive directement à zurg, donc les limites s'appliquent à chaque écriture passant par le montage, et tout ce qui se trouve hors de `__magic__` est refusé d'office.

Un sidecar peut aussi se trouver dans un dossier de release, c'est là qu'un \*arr écrit le `.nfo` d'un fichier qu'il a importé. zurg peut écrire et renommer un sidecar avec n'importe quel nom que la release n'utilise pas déjà, et refuse celui qui prendrait le nom du fichier propre à la release. Un `DELETE` sur un sidecar le supprime vraiment. C'est le seul cas dans `__magic__` où une suppression n'est pas un tombstone : un tombstone masque une entrée que la bibliothèque possède encore ailleurs, alors que les octets d'un sidecar ne vivent que dans `data/local`.

## Le tableau de bord {#the-dashboard}

Une fois la bibliothèque chargée, zurg écrit une ligne dans le journal indiquant combien de lignes contient la table et combien sont orphelines, afin qu'une bibliothèque qui a perdu du contenu ne garde pas un ensemble grandissant de lignes que plus rien ne mentionne. `/magic/` sur le port normal de zurg affiche le contenu de la table : chaque ligne stockée regroupée par release, ce qu'elle représente et d'où elle vient, les lignes orphelines dans leur propre section, et l'arborescence des sidecars avec sa taille par rapport au budget. La page indique aussi la taille du journal et des instantanés, ainsi que la taille de l'ensemble de `data/local`. C'est le chiffre qui dit si quelque chose s'importe en copiant : avec le réglage par défaut `union_writable: local`, un client qui copie au lieu de déplacer écrit les octets là, et rien d'autre ne le montrerait jamais.

Avec `union_writable: server`, ce chiffre reste à zéro et c'est le journal qui le signale à la place : le `PUT` d'un client qui copie est refusé, donc l'arborescence qu'il aurait remplie n'est jamais écrite. Le refus ne fait pas perdre les octets, car le cache de rclone les garde et réessaie, mais ils ne se trouvent plus sur ce disque sous un nom que zurg peut compter. [Le guide qBittorrent](sonarr-radarr-torrents.md) explique la cause, qui est dans tous les cas un réglage côté client : un \*arr ne déplace un import que s'il est libre de supprimer le téléchargement ensuite.

À partir de là, vous pouvez réinitialiser un placement (le fichier revient à son emplacement par défaut), effacer une tombstone (l'entrée réapparaît), supprimer une ligne orpheline, les purger toutes d'un coup, ou supprimer un sidecar. Chaque action demande une confirmation avant de s'exécuter.

La liste des lignes stockées affiche les mille premières lignes, et sur une bibliothèque gérée par un \*arr, cela ne représente qu'une petite partie de la table, car chaque import laisse une tombstone derrière lui. Pour atteindre une seule release, recherchez-la : un nom de release, un chemin sur le montage ou un hash affiche toutes les lignes stockées pour cette release avec leurs boutons, quelle que soit la taille de la table. La liste des orphelines accepte la même recherche. Une release que la bibliothèque ne contient plus n'a pas de nom dans la table, seulement son hash et les chemins vers lesquels ses lignes pointent.

Les sidecars **que plus rien ne réclame** sont listés à part et comptés : un `.nfo` à côté d'une release qui a quitté la bibliothèque, ou dans un placement qui a été oublié. Ils restent servis, car un vrai fichier est la dernière chose vers laquelle un chemin se résout et rien au-dessus ne revendique le nom. Ce qui a disparu, c'est la raison pour laquelle ils ont été créés. zurg ne supprime jamais ces fichiers automatiquement. Un répertoire que vous avez créé pour les sidecars vous-même, via le montage plutôt que via zurg, apparaît de la même façon, car cela ne laisse aucune ligne non plus.

Si le point d'accès SABnzbd est activé, la page liste aussi ses tâches (id, nom, catégorie, état et dossier remis au \*arr), ce qui est le moyen le plus rapide de savoir pourquoi Sonarr affiche encore ce téléchargement comme downloading.

## Durabilité {#durability}

Chaque modification est ajoutée à `data/magic.journal` et écrite sur le disque **avant** que la requête reçoive sa réponse. Ainsi, un déplacement qu'un \*arr croit avoir effectué est un déplacement qui survit à un crash. Le journal est fusionné dans un instantané `data/magic.json` au démarrage, lorsqu'il dépasse un seuil, et à l'arrêt.

Aucun de ces fichiers ne sert à modifier la table. zurg la garde en mémoire et écrit `magic.json` à partir de celle-ci. Une ligne supprimée à la main dans le fichier pendant que zurg tourne réapparaît donc au prochain redémarrage. Utilisez les boutons du tableau de bord.

Une ligne incomplète en fin de fichier, après une coupure de courant, est ignorée, et tout ce qui la précède est conservé. Un instantané écrit par une autre version du schéma est rejeté plutôt que deviné. Une ligne de journal venant d'une autre version arrête le rejeu à cet endroit. Un instantané ou un journal qui ne peut pas être lu produit un avertissement et une table vide, et non un échec du démarrage. Si les fichiers d'une table ne peuvent pas être *ouverts*, `__magic__` reste disponible en lecture seule, en miroir de `__all__` avec lequel il démarre, et toutes les écritures sont refusées. Les écritures reçues pendant l'arrêt sont refusées avec `503` plutôt qu'acceptées puis perdues.

## Codes de statut {#status-codes}

Utile si tu pilotes l'espace de noms directement via WebDAV ; le mount gère tout ça pour toi.

| Code | Signification |
|---|---|
| `201` | MOVE, MKCOL ou PUT a créé quelque chose |
| `204` | DELETE, ou un PUT qui a remplacé un sidecar |
| `400` | un chemin que cet espace de noms ne peut pas stocker, ou un header `Destination` absent ou illisible |
| `403` | une destination en dehors de `__magic__` ou à l'intérieur de `__movies__`, `__shows__` ou `__anime__`, un chemin sur lequel la bibliothèque répond, un chemin qui passe par un fichier, `__magic__` lui-même, ou une table en lecture seule |
| `404` | rien à cet endroit (un DELETE de rien répond quand même `204`), ou un MOVE depuis une archive qui ne contient plus l'entrée |
| `405` | MKCOL là où quelque chose existe déjà, ou PUT sur un dossier |
| `409` | parent manquant, dossier non vide, destination occupée avec `Overwrite: T`, ou un MOVE depuis une archive qui ne peut pas s'ouvrir |
| `412` | destination occupée avec `Overwrite: F` |
| `413` / `507` | au-delà de `sidecar_max_mb` / `sidecar_budget_mb` |
| `503` | arrêt en cours, ou un MOVE dont la source ne peut pas être servie pour l'instant — avec un `Retry-After` |

`MOVE` refuse toute destination en dehors de `__magic__` : les dossiers de filtres restent en lecture seule.

Un `MOVE` **depuis une archive** est aussi vérifié sur l'archive elle-même avant que quoi que ce soit ne soit écrit. Un import est un `MOVE`, et un `MOVE` qui réussit est une promesse que plus rien ne revérifie après coup. Le listing que le client a parcouru ne prouve rien : le contenu des archives déjà analysées est mis en mémoire (memoised), donc une release dont les octets ont disparu continue d'afficher ses épisodes. Il faut donc d'abord consulter la santé du volume, les dégâts sur les articles de la release et, quand ceux-ci ne disent rien, l'archive elle-même. C'est exactement ce que fait un `HEAD` sur le même chemin, et une release saine répond à partir de la même mémoire que celle qu'a déjà construite son listing. Une source qui ne sera jamais lisible donne un `409`, une source qui ne peut pas être lue pour l'instant donne un `503` avec un `Retry-After`, et un nom que l'archive ne contient pas reste un `404`. Rien n'est enregistré en cas de refus.

## Limites à connaître {#limits-worth-knowing}

- **`magic.enabled` demande un redémarrage.** Les routes sont enregistrées au démarrage.
- **Un seul placement par fichier.** Déplacer à nouveau un fichier le replace ; le même fichier ne peut pas apparaître à deux chemins.
- **Un fichier à l'intérieur d'un jeu rar peut être placé** comme n'importe quel autre. La ligne retient le volume et le chemin à l'intérieur de ce volume, donc elle survit à un nouvel empaquetage comme un fichier simple. En revanche, rien ne peut être créé *sous* un fichier placé : un chemin qui passe par lui est refusé.
- **`serve_strm_files` est ignoré dans les listings de `__magic__`.** Cet espace de noms sert à ce qu'un \*arr déplace le vrai fichier hors de celui-ci, et un `.strm` n'est pas un fichier qu'un \*arr peut importer. Un client qui en demande un par son nom reçoit tout de même une réponse.
- **Les chemins sont comparés exactement tels qu'ils arrivent.** Il n'y a ni normalisation Unicode ni passage en minuscules. Un client qui écrit un nom d'une façon et le demande d'une autre ne le trouvera donc pas.

## Voir aussi {#see-also}

- [sabnzbd.md](sonarr-radarr.md) — faire pointer Sonarr et Radarr vers zurg, ce pour quoi `__magic__` a été conçu
- [Liste de souhaits DMM](dmm-wanted.md) — cliquez sur Want dans DMM et zurg la récupère dans `__movies__`, `__shows__` ou `__anime__`
- [usenet.md](usenet.md) — le backend NZB dans lequel atterrissent ces téléchargements
- [config.md](../reference/config.md#__magic__-a-directory-you-can-organise) — chaque clé du bloc `magic:`
