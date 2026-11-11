# Migrer de streamnzb v5.1.0 vers zurg {#migrating-from-streamnzb-v510-to-zurg}

streamnzb est un addon Stremio. Il cherche sur les indexeurs Newznab quand vous appuyez sur lecture et diffuse le meilleur résultat.
Rien n'est conservé. Il n'a ni montage WebDAV sur le système de fichiers ni bibliothèque Plex.

Il n'y a **aucune bibliothèque sur disque à préserver et aucun état de lecture Plex en jeu**. Les étapes de préservation des chemins des autres guides de migration ne s'appliquent pas.

zurg peut prendre sa place de deux façons. Utilisez l'une, l'autre, ou les deux.

- **Garder Stremio.** zurg possède son propre [addon Stremio](../guides/stremio.md). Il cherche sur vos indexeurs Newznab quand vous appuyez sur lecture et diffuse la version que vous choisissez via votre compte de news. C'est aussi le fonctionnement de streamnzb. Il n'a besoin de rien d'autre que zurg. Pas de rclone, pas de serveur multimédia. Chaque version lue de cette façon reste aussi dans la bibliothèque de zurg.
- **Construire une bibliothèque.** zurg garde les versions qu'il a dans une bibliothèque et la monte pour Plex, Jellyfin ou Emby. Sonarr et Radarr peuvent la remplir. zurg lui-même peut aussi la remplir à partir de votre liste de suivi.

Certaines choses que faisait streamnzb n'ont pas d'équivalent dans zurg. Ce guide indique lesquelles.

Ce guide est plus court que ses équivalents car le problème est plus petit.

## Ce qui doit être rescanné et les nouveaux contenus qui apparaissent {#what-needs-rescanning-and-what-new-content-shows-up}

Les deux questions que répondent les [autres guides de migration](index.md) ne s'appliquent pas vraiment ici. Il vaut la peine de te dire pourquoi, plutôt que de te laisser te demander.

**Rien n'a besoin d'être réanalysé, parce qu'il n'y a rien à réanalyser.** streamnzb ne contient aucune bibliothèque, et Plex n'a aucun élément lié à un chemin. Donc tout le mécanisme de protection de la corbeille présenté sur la page commune ne te concerne pas. Il n'y a aucun ancien élément à préserver, et rien ne peut être supprimé par erreur.

**Tout est du nouveau contenu.** Tout ce que tu déposes dans `nzbs/` de zurg est une première analyse dans une bibliothèque vide. Configure tes bibliothèques comme tu le souhaites avant le premier passage, plutôt que de les corriger après coup. Deux paramètres valent la peine d'être mis en place au préalable.

- [`only_show_the_biggest_file: true`](../reference/config.md) sur les dossiers que tes bibliothèques multimédias analysent. Sans lui, tu verras aussi les courts extraits, les fichiers `.nfo` et les publicités `.url` du posteur.
- "Generate video preview thumbnails" **désactivée** sur ces bibliothèques. Sur un montage de streaming, chaque passage de génération de miniatures lit intégralement la release et consomme ton quota Usenet. Une première analyse envoie toute la bibliothèque à Plex d'un coup.

---

## Le changement de modèle {#the-model-change}

| | streamnzb | zurg |
|---|---|---|
| Acquisition du contenu | Recherche dans les indexeurs Newznab à chaque demande de lecture | L'[addon Stremio](../guides/stremio.md) recherche dans les indexeurs Newznab à chaque demande de lecture. Une bibliothèque se remplit aussi à partir de fichiers `.nzb`, de l'endpoint SABnzbd et de l'[acquisition](../guides/acquisition.md) |
| Classement et sélection | traits jhin, profils de filtres et une vérification AvailNZB | La résolution d'abord, puis une répartition des tailles dans chaque résolution. Pas de traits ni de profils de filtres |
| Conservation | Rien n'est conservé. Chaque lecture est une nouvelle recherche | Bibliothèque persistante. Une release lue via l'addon y reste |
| Client | Stremio. L'addon fournit aussi les métadonnées | Stremio via l'addon de zurg, qui ne répond que les flux. N'importe quel serveur média via le montage. Ou WebDAV directement pour Infuse |
| Système de fichiers | Aucun | Montage FUSE rclone plus WebDAV plus un index HTTP simple |
| Archives | RAR et 7z **STORE uniquement**. Les releases compressées ne seront pas lues | RAR et 7z compressés, streamés de façon transparente |
| Posts obfusqués | Refusés | Noms récupérés à partir des en-têtes yEnc et des PAR2. Le contenu est présenté sous le nom de la release |
| Posts endommagés | Ignorés via AvailNZB | La réparation PAR2 reconstruit les articles manquants. L'addon ignore une release dont le début est absent et essaie la suivante |
| API SABnzbd | Non. Il dispose d'un proxy NNTP sur le port 119 à la place | Oui, en option. Chaque grab est vérifié auprès des serveurs de news. Un post mort est reconstruit depuis le PAR2 si possible, et signalé **Failed** sinon |

Au quotidien, Stremio peut rester comme il est. Ajoutez l'addon de zurg et choisissez un titre comme avant. zurg recherche dans vos indexeurs et lit ce que vous choisissez. La [page Stremio](../guides/stremio.md) explique l'installation. La première lecture d'une release attend que zurg récupère le NZB et liste la release. Cela prend généralement quelques secondes. Chaque lecture suivante de cette release démarre immédiatement.

Une bibliothèque pour votre serveur média a besoin de quelque chose pour la remplir.

- **L'endpoint SABnzbd.** Mettre `sabnzbd.enabled: true` fait répondre zurg à Sonarr et Radarr comme client de téléchargement. L'import est un renommage dans `__magic__`. Le grab arrive dans `__magic__/__all__`. L'import déplace le fichier de là vers le dossier racine que vous avez créé à côté. Rien n'est copié. La plupart des configurations de bibliothèque devraient utiliser cela. Voir [Sonarr & Radarr](../guides/sonarr-radarr.md). zurg vérifie chaque grab auprès des serveurs de news avant de le signaler terminé. Il demande le début et la fin de chaque fichier. Il télécharge aussi le premier article de chaque fichier, soit jusqu'à soixante-quatre articles plus quelques autres pour une release ne contenant que quelques fichiers. Certains serveurs de news indiquent encore qu'un article existe alors que son contenu a été retiré, et seul un téléchargement le révèle. zurg reconstruit une release dont des articles manquent à partir de ses fichiers PAR2 lorsque c'est possible. Celle qu'il ne peut pas reconstruire est signalée **Failed**. Les \*arr la mettent alors sur liste noire et en prennent une autre.
- **Acquisition.** zurg peut récupérer les demandes par lui-même. Elles viennent de votre watchlist Plex, de Seerr et des \*arr. Il recherche dans vos indexeurs Newznab et vérifie chaque grab de la même façon. Voir [acquisition](../guides/acquisition.md).
- **Dépôt manuel.** Téléchargez le `.nzb` depuis le site de votre indexeur et copiez-le dans `nzbs/`. Le nom est fixe, le dossier est réanalysé toutes les 15 secondes environ, et les fichiers ne sont jamais déplacés ni consommés. Ça marche toujours, et c'est la base la plus honnête.
- **Sonarr et Radarr « Usenet Blackhole ».** Les \*arr peuvent être configurés avec un client de téléchargement Blackhole dont *Nzb Folder* est le dossier `nzbs/` de zurg. Vous retrouvez ainsi l'automatisation recherche-et-grab sans l'endpoint, mais avec un compromis. Le \*arr attend qu'un téléchargement terminé apparaisse dans son dossier surveillé pour l'importer. zurg n'en produit jamais un, car la release apparaît plutôt dans le montage. Donc la file du \*arr affiche l'élément comme ne se terminant jamais. Vous obtenez une livraison automatique des NZB, et non le pipeline d'import et de renommage du \*arr. Le côté \*arr de ceci n'a pas été revérifié pour le guide. Le côté zurg est vérifié dans le code à `internal/nzb/provider.go:30`.
- **Le RSS ou le téléchargement par panier de l'indexeur vers un dossier.** Cela dépend entièrement de l'indexeur et de votre script de récupération. Non vérifié, mentionné seulement parce que certains indexeurs le proposent.

**Nommez le fichier avant de le déposer.** Le dossier de la release dans le montage porte le nom du *fichier* NZB. L'en-tête `<meta type="name">` n'est utilisé que lorsque le nom du fichier ressemble à un hash. Cela a été mesuré sur les cinq serveurs le 2026-08-19. Un fichier nommé `indexer_download_48213.nzb` ne donne rien à Plex pour faire la correspondance, donc renommez-le d'abord avec le nom de la release. Cela signifie aussi que le nom du dossier reste entièrement sous votre contrôle. Deux releases différentes portant le même nom reçoivent un suffixe ` {shorthash}`.

---

## Configuration qui est reprise {#configuration-that-carries-over}

Il y en a deux. La première concerne le fournisseur Usenet. streamnzb configure les fournisseurs sous **Settings → Providers**, avec l'hôte, le port, le nom d'utilisateur, le mot de passe et le nombre de connexions. Les variables d'environnement fonctionnent aussi. Le même compte devient le bloc `nntp` de zurg.

Avant, dans streamnzb. Voici la forme avec variables d'environnement, avec les noms de clés documentés.

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

Après, dans le `config.yml` de zurg.

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

Un second fournisseur streamnzb, comme `PROVIDER_2_*`, va sous `nntp.servers` : zurg passe alors d'un compte à l'autre, article par article, en cas d'échec. `priority` correspond directement. zurg ajoute deux notions que streamnzb n'a pas. Avec `backup: true`, un compte au volume limité n'est interrogé que lorsque tous les comptes principaux répondent *no such article*. Avec `backbone`, deux comptes qui s'appuient sur le même backbone ne se voient pas poser deux fois la même question. Une seule entrée de fournisseur `nzb` est autorisée. Les comptes news supplémentaires vont à l'intérieur de celle-ci, et non à côté.

La seconde concerne vos indexeurs. Ils vont sous `stremio.indexers`, avec la même URL et la même clé API. L'acquisition utilise la même liste lorsqu'elle n'en a pas de propre.

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

Rien d'autre du `data/config.json` de streamnzb ne se transfère. Les blocs `streams` et `filter_profiles` définissaient ce que proposait l'addon de streamnzb. L'addon de zurg a une seule liste par titre et son propre classement. Ses réglages les plus proches sont au nombre de deux. `max_size_gb` écarte les releases dépassant une certaine taille. `max_results` définit le nombre de releases conservées pour chaque résolution. La [page Stremio](../guides/stremio.md) détaille le reste.

---

## Historique de visionnage {#watch-history}

streamnzb garde l'historique de lecture de chaque flux dans sa base de données. C'est du SQLite dans `data/streamnzb.db` par défaut, avec Postgres en option. Il s'en sert pour créer les rangées Continue Watching et Because You Watched. Sa documentation décrit le contenu comme « bibliothèque, historique des recherches et des lectures, mauvaises releases et métriques ».

**Rien de tout cela n'est transférable vers une bibliothèque Plex.** L'état de visionnage dans Plex est stocké par élément, dans la base de données propre à Plex, et il est lié à des éléments qui doivent d'abord exister dans une bibliothèque. Aucun importeur n'existe d'un côté comme de l'autre. Ce n'est pas vraiment une perte de données, plutôt un décalage de modèles. Les lignes d'historique de streamnzb font référence à des recherches et à des flux, et non à des fichiers. Si tu veux garder une trace avant de mettre l'ancien système hors service, la base est du SQLite simple et peut être lue directement.

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

Les noms exacts des tables ne sont pas documentés et n'ont pas été vérifiés pour ce guide. La commande `.tables` permet de les trouver. Sur Postgres, les mêmes données se trouvent dans la base pointée par `DATABASE_URL`. L'état de visionnage de ta nouvelle installation repart de zéro et se constitue dans Plex dès la première lecture.

---

## Ce que vous gagnez {#what-you-gain}

- **Une vraie bibliothèque.** Plex, Jellyfin et Emby parcourent un système de fichiers, conservent les métadonnées et suivent l'état de lecture sur tous les clients qu'ils prennent en charge. Pas seulement Stremio.
- **Réparation PAR2.** Une release avec des articles manquants est reconstruite en arrière-plan à partir de ses propres fichiers de récupération. La réponse de streamnzb à une mauvaise release était de la passer. Celle de zurg, c'est de la réparer.
- **Releases obfusquées.** zurg retrouve les vrais noms de fichiers à partir des en-têtes yEnc et de l'index PAR2, et présente une charge utile entièrement obfusquée sous le nom de la release. Mesuré sur le banc d'essai où `Obfuscated.nzb` a donné un `Toy.Story.5.2026...KyoGo.mkv` propre. streamnzb refuse ces releases purement et simplement.
- **RAR et 7z compressés.** streamnzb ne diffuse que les archives STORE'd, et son README est explicite : "Compressed RAR releases will not play". zurg diffuse la vidéo à partir d'archives compressées et reproduit la structure de répertoires interne au passage.
- **Les lectures suivantes démarrent tout de suite.** streamnzb recherchait et vérifiait à chaque lecture. zurg garde ce que tu as lu. Une release déjà présente dans la bibliothèque se lance immédiatement. Tout ce que Sonarr ou Radarr récupère est dans cet état dès le départ.
- **Une profondeur multi-comptes.** Priorités, comptes `backup` à la consommation, déduplication `backbone` et chemin de réparation quand tous les comptes ont raté.

## Ce que vous perdez {#what-you-lose}

- **jhin et profils de filtres.** L'addon de zurg recherche aussi dans vos indexeurs. Il classe les résultats uniquement selon la résolution et la taille. Il n'y a ni traits jhin, ni profils de filtres, ni scores.
- **La vérification AvailNZB.** zurg ne demande à personne d'autre si une release est encore disponible. L'addon le découvre en lisant le début de la release que vous avez choisie. Si ce début a disparu, il passe à la release suivante de la liste. Une récupération envoyée par Sonarr ou Radarr est vérifiée auprès de vos serveurs de news avant d'être considérée comme terminée. Les dégâts plus loin dans un fichier apparaissent quand une lecture y arrive. La réparation PAR2 reconstruit alors le fichier, si le post contient assez de données de récupération. Le 2026-08-19, un jeu de RAR auquel il manquait des volumes entiers est apparu comme un dossier vide au lieu d'afficher une erreur.
- **Les catalogues et lignes de streamnzb.** Ses catalogues intégrés, ses métadonnées, ainsi que ses lignes Continue Watching et Because You Watched, venaient de son propre historique. L'addon de zurg ne répond qu'aux flux. Un serveur multimédia a ses propres versions de ces lignes pour une bibliothèque.
- **Le proxy NNTP sur le port 119.** Si SABnzbd ou NZBGet pointaient vers streamnzb comme serveur de news, ils ont de nouveau besoin des identifiants réels de leur fournisseur.

---

## Mettre zurg en place {#standing-up-zurg}

Une `config.yml` qui fonctionne en Usenet uniquement.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

N'utilisez pas de filtres `tags_match_any` pour le contenu Usenet. Les tags `zurg_*` viennent de ffprobe, et ffprobe ne tourne jamais sur ce backend. Un tel dossier ne contiendra donc jamais de release Usenet. Filtrez plutôt sur les noms, les extensions, les tailles et `has_episodes`.

Ensuite, lancez-le.

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__all__/
```

Si Usenet est votre seul compte, le dossier `__nzb__` n'apparaît pas dans la liste racine du mount, et `__all__` contient les mêmes fichiers. Testez donc la lecture sous `__all__` sur le mount, ou ouvrez le chemin HTTP direct `http://localhost:9999/http/__nzb__/`. Les sous-dossiers de `nzbs/` sont ignorés, et `.nzb.gz` n'est pas lu.

### La première bibliothèque Plex {#the-first-plex-library}

**Pointe** les bibliothèques vers des **sous-dossiers** du montage, comme `/mnt/zurg/movies` et `/mnt/zurg/shows`. Jamais la racine. La même release apparaît sous `__all__` et dans chaque dossier correspondant, donc scanner la racine ferait passer le scan plusieurs fois sur les mêmes fichiers.
Avec Usenet comme seul compte, `__nzb__` n'apparaît pas dans la liste racine du montage et ne se résout pas via le montage, car `__all__` contient les mêmes fichiers.
Donne à zurg `plex_server_url` et `plex_token` pour qu'il puisse demander des scans partiels.

Deux réglages de bibliothèque comptent dès le tout premier scan, que la bibliothèque soit neuve ou non. Le problème qu'ils préviennent, c'est que le montage saute *pendant* un scan.

1. **Décoche "Empty trash automatically after every scan"** pour que `autoEmptyTrash` soit à 0. Si le montage disparaît en plein scan, Plex conclut que tous les fichiers ont été supprimés. Un redémarrage de zurg ou un remontage rclone suffit. Avec l'option activée, ils sont supprimés définitivement et tout de suite. Désactivée, ils restent dans la corbeille et reviennent avec le montage. Ça a déjà coûté des dizaines de milliers d'éléments.
2. **Décoche "Generate video preview thumbnails".** Sur Usenet, chaque passage de miniatures lit intégralement la release et consomme ton quota de connexion.

Et ne redémarre jamais zurg pendant que Plex scanne. Les vérifications préalables et les deux réglages doivent être à zéro.

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Utilise `grep -o … | wc -l` plutôt que `grep -c`. grep renvoie un code d'erreur non nul quand il ne trouve rien, et c'est le *bon* cas ici. Ça fait échouer une chaîne `&&` ou un script `set -e` juste avant le redémarrage qu'il devait protéger.

Les tailles de fichiers se stabilisent un peu après la première apparition d'une release dans la liste. Un NZB n'indique pas la durée d'un fichier. La première liste en estime donc la taille à partir des tailles d'articles enregistrées dans le NZB. Cette estimation peut être surévaluée d'environ 3 %. zurg apprend ensuite la longueur exacte en arrière-plan et la conserve. Un scan lancé avant voit l'estimation. Plex considère alors le fichier comme modifié et l'analyse une fois de plus. Rien n'est supprimé.

## Faire tourner les deux côte à côte {#running-both-side-by-side}

Aucun conflit sur les ports. streamnzb utilise 7000 et 119, et zurg utilise 9999. La transition raisonnable consiste donc à laisser streamnzb servir Stremio pendant que la bibliothèque zurg se remplit.

La seule ressource partagée est le compte Usenet. **Les deux lisent dans le même quota de connexions, et le fournisseur l'applique aux deux.** Avec un forfait de 50 connexions, tu ne peux pas faire tourner streamnzb à 50 et zurg à 30. Les connexions en trop sont refusées, et côté zurg cela ressemble à des flux lents ou qui bloquent. Répartis donc le quota explicitement. Essaie `PROVIDER_1_CONNECTIONS=20` dans streamnzb et `connections: 30` dans zurg. Donne à zurg la totalité du quota une fois streamnzb désactivé, car le débit d'un flux unique de zurg dépend de ce nombre.

Quand tu éteins streamnzb, supprime son addon Stremio de tes clients. Garde une copie de `data/` si tu veux conserver l'historique. Son `config.json` et son `streamnzb.db` constituent à eux deux tout son état. Ensuite, redirige vers ton fournisseur directement tout ce qui utilisait le proxy NNTP sur le port 119.
