# Documentation de configuration de zurg {#zurg-configuration-documentation}

Ce document détaille toutes les options de configuration disponibles pour zurg. Configurez ces options dans votre fichier `config.yml`.

> **Astuce :** La plupart des paramètres peuvent être configurés depuis le **Dashboard** à l'adresse `http://localhost:9999/config/`. L'interface web permet de consulter et modifier les paramètres plus facilement, sans éditer directement le fichier de configuration.

## Migrer depuis une configuration antérieure à `providers` {#migrating-from-a-pre-providers-config}

Si ton fichier de config a été écrit avant l'arrivée du support multi-comptes, il démarre toujours : les clés de premier niveau `token:`, `download_tokens:` et `strm_link_token:` sont lues comme la seule chose qu'elles pouvaient décrire, à savoir un seul compte Real-Debrid, et le démarrage affiche un avertissement indiquant qu'elles sont obsolètes. Les déplacer dans une entrée `providers` est le seul changement que ton fichier de config demande, à faire quand tu le souhaites : aucune autre clé n'a été renommée, changée de type ou supprimée.

Ce n'est toutefois pas la seule chose qui change. Quelques directives gardent leur nom et leur valeur, mais décident de quelque chose d'un peu différent, parce que le code qui les lit a changé. Elles sont regroupées dans [Ce qui change d'autre lors de la mise à jour](#what-else-changes-when-you-upgrade) ci-dessous, à lire si tu filtres sur les archives, sur les tags, ou sur la date d'ajout d'une release.

### Le seul changement à faire {#the-one-change-to-make}

A single Real-Debrid account used to be three top-level keys. All three now live inside one `providers` entry.

Before:

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

After:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

Supprime les anciennes clés une fois qu'elles ont été déplacées. Si elles restent à côté d'un bloc `providers` qui configure déjà Real-Debrid, elles sont ignorées et le démarrage affiche un avertissement à leur sujet. Ainsi, les deux ne peuvent jamais être en désaccord sans qu'on le remarque sur le jeton actif. Rien d'autre dans ton fichier n'a besoin d'être modifié : chaque autre clé garde son nom et sa signification. Une configuration dont le seul identifiant était `token:` n'a besoin que de cette modification.

Tu n'es pas obligé de le faire. Une configuration non migrée démarre quand même : les trois clés sont lues comme un seul compte Real-Debrid nommé `realdebrid`, et au démarrage, l'application indique les clés qu'elle a lues et ce que tu dois écrire à la place. Elles sont obsolètes, pas prises en charge : les nouvelles fonctionnalités de compte ne sont accessibles qu'à partir d'une entrée `providers`.

Les variables d'environnement `TOKEN` et `RD_TOKEN` fonctionnent toujours et créent toujours automatiquement une configuration au premier lancement.

### Ce qui est devenu possible et qui peut vous intéresser {#what-became-possible-that-you-may-want}

Rien de tout ça n'est obligatoire. Voici ce que le bloc `providers` t'apporte :

| Désormais disponible | Où |
|---|---|
| Les backends TorBox, AllDebrid et Usenet, en plus de Real-Debrid ou à sa place | [Accounts](#accounts) |
| Plusieurs comptes du même service, distingués par `name` | [Accounts](#accounts) |
| `disabled: true` pour mettre un compte en pause sans supprimer ses identifiants | [Accounts](#accounts) |
| `watchlist: true` pour choisir le compte sur lequel les nouveaux ajouts de torrents sont essayés en premier | [Accounts](#accounts) |
| Filtres de répertoires `provider:` / `not_provider:`, et répertoires par compte | [Directories](#7-directories--filters) |
| `rd_cdn_host_preference` et `tb_cdn_host_preference` pour choisir le CDN par service | [CDN & Host Selection](#cdn--host-selection) |

Deux petits changements à connaître :

- `cdn_host_preference` fonctionne toujours et désigne toujours Real-Debrid. C'est maintenant un alias de `rd_cdn_host_preference`, qui l'emporte si les deux sont définis.
- Les identifiants Plex issus du flux d'authentification du Dashboard sont désormais enregistrés dans `config.yml` sous `plex_server_url` et `plex_token`. Ils étaient auparavant dans `data/plex.json`.

### Migrer à la main ou via le tableau de bord {#migrating-by-hand-vs-by-dashboard}

Le Dashboard peut le faire pour vous. Une config non migrée se charge, donc l'éditeur des providers est accessible, et il affiche le compte Real-Debrid sous lequel vos clés de premier niveau ont été lues. Enregistrer un compte déplace ces clés dans le bloc `providers` sur le disque. Modifier le fichier à la main puis redémarrer fait la même chose, et c'est la seule option si la config ne se charge pas du tout.

Une chose que le Dashboard n'accepte plus : `POST /config` acceptait avant `token`, `download_tokens` et `strm_link_token` comme clés de premier niveau, et répond maintenant `400 Unknown config option`. Les identifiants se modifient désormais par compte. Tout script qui gère ces trois clés doit être mis à jour.

### Ce qui change d'autre lors de la mise à niveau {#what-else-changes-when-you-upgrade}

**Les filtres voient désormais à l'intérieur des archives.** `any_file_inside_regex`, `any_file_inside_contains`, `any_file_inside_size_gte`/`_lte`, leurs formes `not_`, `has_episodes` et `is_music` s'appliquaient avant à l'archive elle-même : une seule entrée nommée `Show.part01.rar`, avec la taille d'un volume. Une fois que zurg a listé une archive, ces filtres s'appliquent à son contenu : les vrais noms de fichiers, leurs vraies tailles, et volontairement *pas* la taille de l'archive, qui écrasait tout ce qu'elle contenait. Un pack de saison qui apparaissait comme un seul énorme fichier correspond maintenant à `has_episodes`. `any_file_inside_regex: /\.mkv$/i` se met à correspondre là où il échouait avant, et `any_file_inside_not_regex` cesse de correspondre là où il passait. Par ailleurs, une release dont tous les fichiers sont en `.rar`/`.r00`/`.par2` atteint désormais les filtres, alors qu'avant elle partait directement dans `__unplayable__`.

Ça arrive release par release, pas d'un coup : cela ne s'applique qu'aux archives que zurg a déjà listées, et les listings écrits par un ancien parseur sont ignorés. Une release bouge donc la première fois que quelque chose l'ouvre. Si un de tes dossiers dépend de l'ancienne lecture, exprime-le avec `regex`/`not_regex` sur le nom de l'archive, qui correspondent toujours au nom de la release.

**Les filtres de tags ne rattrapent plus les releases qui n'ont jamais été analysées.** Les tags `zurg_*` viennent de ffprobe. Quand rien n'a pu être analysé, tous les tableaux de paliers tombaient au plus bas et la release recevait quand même `zurg_sdr`, `zurg_very_low_video_bitrate`, `zurg_very_low_audio_bitrate` et `zurg_0to20mins_duration`, qui décrivaient un fichier que personne n'avait mesuré. Ces tags ne sont plus émis. Un filtre qui nomme un de ces quatre tags change de sens pour les releases non analysables : `has_tag`/`tags_match_all`/`tags_match_any` ne les attrapent plus, et, c'est le point à vérifier, `not_has_tag`, `tags_missing_all` et `tags_missing_any` **commencent** à les attraper. Les filtres qui nomment un autre palier ne changent pas.

**`added_within_hours` / `added_within_days` / `added_after` / `added_before` lisent un horodatage plus ancien pour les doublons.** Quand une même release est présente plusieurs fois, l'entrée indique maintenant la date d'ajout la plus ancienne au lieu de la première vue. Une deuxième copie d'une vieille release ne la fait donc plus passer pour un ajout récent. Un dossier de type `recent` peut ainsi abandonner une release qu'il gardait auparavant.

**Le montage met en cache les listings de dossiers pendant 12 heures.** `check_for_changes_every_secs` réglait avant `--dir-cache-time` de rclone, donc les listings expiraient toutes les 15 secondes par défaut. Ils restent maintenant 12 h, et zurg oublie explicitement les entrées concernées à chaque changement de la bibliothèque, ce qui garde les scans du serveur média rapides. Pour revenir en arrière, redéfinis-le directement : `rclone_extra_args` l'emporte sur n'importe quel flag intégré :

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**Chaque compte a un dossier `__<account>__`.** Il est créé à partir du bloc `providers` et non de `directories`, contient tout ce que détient ce compte, ignore tes filtres de dossiers et fixe les lectures sur ce compte. `directories` ne peut pas le supprimer. S'il y a plus d'un compte, il apparaît à la racine du montage. Les builds antérieures à la nightly 2026.10.24.0551 listaient aussi le dossier d'un compte unique à cet endroit ; à partir de cette nightly, il n'est plus dans la liste racine du montage, car `__all__` représente la même bibliothèque. Les chemins HTTP et WebDAV directs comme `/http/__realdebrid__/` répondent toujours. Via le montage, `__<name>__` ne se résout plus non plus : pointe vers `__all__` toute bibliothèque ou tout script qui utilisait `__<name>__`.

**Deux releases qui partageaient un nom sont maintenant deux entrées.** Avant, elles fusionnaient et les fichiers de l'une se retrouvaient silencieusement mélangés à ceux de l'autre. Celle qui ne garde pas le nom d'origine reçoit en suffixe six caractères de son info hash, par exemple `Movie.2024 {a1b2c3}`. C'est cette chaîne suffixée que `regex`, `not_regex`, `contains` et `not_contains` comparent, donc un motif ancré ne la trouvera pas. Par ailleurs, les entrées désambiguïsées par un nom de base en double sont renommées une fois à la mise à jour, d'un identifiant de fichier généré par le compte vers un tag dérivé du chemin.

**Les fichiers `.strm` changent de forme.** Avec `serve_strm_files`, chaque `.strm` servi par le montage change de contenu et de taille annoncée. L'URL pointe maintenant vers l'entrée de la bibliothèque et non plus vers le lien d'un seul compte, donc elle bascule en cas de panne et survit aux réparations. Un serveur média voit donc chaque `.strm` changer. Avec `save_strm_files`, les fichiers déjà écrits sont réécrits sur place, sous les mêmes noms, au premier démarrage de zurg, et un serveur média récupère la nouvelle URL à son prochain scan. La nouvelle forme est signée avec un secret stocké dans `data/strm_secret`. Si ce fichier ne peut pas être écrit, zurg affiche un avertissement dans le journal et démarre quand même, mais les liens cessent de fonctionner au prochain redémarrage. À ne pas ignorer.

**`load_dumped_torrents` ne charge pas un `dump/` d'avant la mise à jour.** Les torrents en cache portent désormais le compte d'où ils viennent, et ceux sans ce tampon sont ignorés. Le cache principal se réimporte depuis le compte au prochain rafraîchissement. `dump/` n'a aucun compte derrière lui : il arrive donc vide, avec un avertissement dans le journal. Réexporte depuis une instance en cours d'exécution si tu en as besoin.

**La réparation passe par une autre route quand `restrict_repair_to_cached` et `only_full_torrent_repair` sont à false.** Les deux clés ne changent pas quand elles sont à `true`. Désactivées, c'est la valeur par défaut, les stratégies par fichier et par lots ont été remplacées par un seul ré-ajout qui nomme les fichiers cassés. Même intention, requêtes différentes envoyées au compte.

**Quelques petits changements.** `ignore_renames` décide désormais aussi du nom du `.zurgtorrent` sur le disque (migration automatique au chargement). `retries_until_failed` borne maintenant les nouvelles tentatives Real-Debrid liées au fair usage, qui étaient auparavant infinies. `auto_analyze_new_torrents: false` et un `ffprobe_binary` absent n'empêchent plus le nettoyage du cache, qui était sauté avec l'analyse. Un filtre de taille qui exclut le premier volume d'une archive masque maintenant l'archive entière au lieu de retomber sur un volume suivant. Les ressources statiques non authentifiées passent de `/static/css/*` à `/static/*` ; aucune route auparavant protégée ne devient publique.

## Configuration Windows {#windows-configuration}

Sous Windows, les chemins doivent être écrits différemment lors de l'exécution de zurg :

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Points clés pour Windows :**
- Mettez des guillemets autour de tous les chemins
- Pour `mount_path` : utilisez une lettre de lecteur comme `P:\` (écrite `P:\\` en YAML) ou `P:/`
- Pour les chemins des binaires : les barres obliques `/` fonctionnent et évitent les problèmes d'échappement
- Vérifiez que l'extension `.exe` est bien incluse pour les exécutables

## 1. L'essentiel (à configurer en premier) {#1-essentials-setup-first}

Ce sont les paramètres indispensables pour faire démarrer le serveur.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `zurg` | string | *(required)* | Identifiant de version de la configuration. Doit être défini à `v1` ; toute autre valeur (y compris une clé absente) fait échouer le chargement. |
| `providers` | list | *(required)* | Vos comptes debrid et Usenet, une entrée par compte. Voir [Accounts](#accounts) ci-dessous. Les clés de premier niveau `token`, `download_tokens` et `strm_link_token`, présentes avant `providers`, sont obsolètes : elles fonctionnent toujours, comme un seul compte Real-Debrid, et le démarrage affiche un avertissement. Si un bloc `providers` configure déjà Real-Debrid, c'est lui qui est pris en compte et la clé en trop est ignorée. |
| `mount_path` | string | OS-dependent | Le chemin du système de fichiers où se trouve votre montage rclone. zurg l'utilise pour indiquer aux serveurs multimédias (Plex, Jellyfin, Emby) où trouver les fichiers. Il sert aussi de point de montage quand `rclone_enabled` est à true. Par défaut `/mnt/zurg` (Linux), `/Volumes/Zurg` (macOS) ou `Z:` (Windows). Les utilisateurs de Docker doivent le définir à `/zurg_mnt/zurg` avec le montage de volume `/zurg_mnt:/zurg_mnt:rshared` (voir [docker.md](../setup/docker.md)). |
| `base_url` | string | `""` | L'URL accessible de l'extérieur de votre instance zurg. Elle est intégrée dans les fichiers STRM pour que les serveurs multimédias puissent diffuser le contenu. Si elle n'est pas définie, les fichiers STRM contiendront des URL `localhost` qui ne fonctionneront pas depuis d'autres appareils. Utilisez votre IP Tailscale, votre IP LAN ou un domaine derrière un reverse proxy. Exemple : `http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### Comptes {#accounts}

Chaque entrée de `providers` correspond à un compte. Vous pouvez en utiliser autant que vous voulez en même temps : Real-Debrid, TorBox, AllDebrid, Premiumize, Debrid-Link et Offcloud ensemble, ou plusieurs comptes sur le même service.

| Option | Type | Par défaut | Description |
|--------|------|---------|-------------|
| `type` | string | *(obligatoire)* | Le backend utilisé par le compte : `realdebrid`, `torbox`, `alldebrid`, `premiumize`, `debridlink`, `offcloud`, `nzb` ou `torbox_nzb` ([Usenet hébergé par TorBox](../providers/torbox-nzb.md)). |
| `name` | string | valeur de `type` | Permet de distinguer ce compte des autres du même type. C'est le nom utilisé par le filtre `provider`, le [répertoire par compte](#per-account-directories), les chemins de cache et le tableau de bord. Les noms doivent être uniques entre les entrées, et `e` est réservé au routage des liens STRM. |
| `token` | string | *(obligatoire)* | Le jeton ou la clé API du compte. Vous obtenez celui de Real-Debrid sur http://real-debrid.com/?id=20475782, celui de TorBox sur https://torbox.app/settings, et celui d'AllDebrid sur https://alldebrid.com/apikeys?uid=1kk5i. Non utilisé par `nzb`, qui s'authentifie via `nntp` à la place. Un jeton Real-Debrid peut aussi être fourni via la variable d'environnement `TOKEN` ou `RD_TOKEN` pour créer automatiquement une configuration au premier lancement. |
| `download_tokens` | list | `[]` | **Real-Debrid et AllDebrid :** jetons API de secours pour le même service, utilisés quand la bande passante du jeton actif est épuisée. Ils utilisent le catalogue de cette entrée, y compris un [catalogue local](#local-debrid-catalogs), sans importer les bibliothèques de torrents des comptes supplémentaires. **TorBox :** accepté, mais la rotation ne réaffecte pas les identifiants de torrents/fichiers propres au compte ; utilisez des entrées de fournisseur séparées pour des comptes différents. Non utilisé par NZB. Premiumize, Debrid-Link et Offcloud exigent des entrées de compte distinctes, car leurs identifiants de fichiers stockés appartiennent au compte qui a fait la liste. |
| `strm_link_token` | string | `""` | Un jeton API séparé qui résout les lectures arrivant sur le point de terminaison `/strm/`, afin qu'un lecteur qui ouvre un `.strm` ne consomme pas le jeton utilisé par le montage en direct. Si non défini, `token` est utilisé. **Real-Debrid et AllDebrid**, les deux backends qui font tourner leurs identifiants, et donc les deux seuls où réserver le trafic `.strm` à une clé dédiée a un sens. Accepté mais inutilisé sur les entrées `torbox` et `nzb`. Premiumize, Debrid-Link et Offcloud n'acceptent ici que le `token` propre au compte. |
| `disabled` | bool | `false` | Garde un compte dans la configuration sans le charger. Si toutes les entrées sont désactivées, le chargement échoue. |
| `watchlist` | bool | `false` | Marque le compte essayé en premier pour les nouveaux ajouts de torrents. Cela couvre les points de terminaison du client de téléchargement et les indexeurs Torznab de l'acquisition. Une seule entrée au maximum peut l'activer, et jamais une entrée `nzb` ou `torbox_nzb`. Si aucune n'est définie, le premier compte capable d'ajouter des torrents est utilisé. Les NZB de l'acquisition vont au backend Usenet et jamais à ce compte. Voir [Watchlist](#watchlist). |
| `add_torrents` | bool | `true` | Indique si ce compte reçoit de nouveaux torrents, qu'ils viennent des points de terminaison du client de téléchargement ou des indexeurs Torznab de l'acquisition. Mettez `false` pour un compte d'archive, ou un compte dont le quota est déjà réservé : il continue de servir et de lire sa bibliothèque, mais rien de nouveau ne lui est jamais ajouté. **L'ordre de la liste `providers:` est l'ordre dans lequel les comptes qui acceptent les ajouts sont essayés**, donc cette clé et cet ordre se lisent ensemble ; un compte marqué `watchlist: true` est essayé en premier, quelle que soit sa position. Ne peut pas être combiné avec `watchlist: true` sur la même entrée. Sur une entrée `nzb`, elle est ignorée avec un avertissement au démarrage, car un serveur de news ne reçoit jamais de torrent. Voir [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see). |
| `warm_connections` | int | `1` | Nombre de connexions que ce compte garde ouvertes et négociées **vers chaque hôte qu'il utilise**, pour qu'une lecture n'ait pas à en ouvrir une. Limité à 4. `-1` n'en garde aucune. Ignoré sur une entrée `nzb`, dont le minimum est propre à chaque compte et se trouve dans [`nntp.warm_connections`](../guides/usenet.md). Voir [connexions chaudes](#warm-connections). |
| `nntp` | block | *(obligatoire pour `nzb`)* | Identifiants du serveur de news. Obligatoire pour le type `nzb` et ignoré par tous les autres types. |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

L'option `download_tokens` de TorBox ne fournit pas le repli de lecture entre comptes que permettent les liens verrouillés de RD et AD. Son résolveur change la clé API mais garde les identifiants de torrents et de fichiers de la source existante. Des entrées TorBox séparées gardent les identifiants et le catalogue de chaque compte indépendants. Pour une bibliothèque locale, placez les manifestes portables dans le répertoire source propre à chaque entrée.

#### Seeding TorBox {#torbox-seeding}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `tb_seed_torrents` | string | `never` | Indique si les torrents que zurg ajoute à un compte TorBox doivent être seedés. `never` désactive le seed pour chaque ajout. `auto` laisse le choix au réglage de seed de ton compte TorBox. `always` active le seed pour chaque ajout. S'applique à tous les comptes TorBox de la configuration, et au prochain ajout dès que tu modifies la valeur. Toute autre valeur empêche zurg de démarrer. |

```yaml
tb_seed_torrents: never
```

Laisse-le sur `never` sauf si tu en as besoin. Il sert surtout aux trackers privés qui comptent ton ratio. Une release récupérée via l'endpoint [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see) sous forme de fichier `.torrent` est ajoutée avec ce réglage. Donc avec `always` (ou `auto` sur un compte configuré pour seeder), TorBox renvoie le fichier vers l'essaim du tracker. L'importer dans Sonarr ou Radarr n'y change rien : un téléchargement terminé que le client supprime reste sur le compte.

**Un torrent en seed occupe un de tes slots actifs tant qu'il seede.** TorBox compte un torrent en seed de la même façon qu'un torrent en cours de téléchargement. Tes forfaits permettent 3, 5 ou 10 torrents en même temps (Essential, Standard, Pro), et le seed peut durer jusqu'à 24 heures, 14 jours ou 30 jours. Une fois que tous les slots sont occupés par des torrents en seed, les nouveaux ajouts et les réparations sur ce compte restent bloqués jusqu'à ce qu'un slot se libère, soit quand le temps de seed d'un torrent est écoulé, soit quand tu le supprimes sur TorBox. Le seed compte aussi comme de l'upload dans les limites d'usage équitable de TorBox. Avec `never`, rien de tout cela ne se produit, et c'est pour ça que c'est la valeur par défaut.

`auto` n'envoie aucune préférence de seed à TorBox, donc c'est le réglage de seed de ton compte qui s'applique. Sur un compte où personne ne l'a modifié, c'est l'option Auto de TorBox. `always` et `never` remplacent le réglage du compte pour les torrents ajoutés par zurg, et ne touchent à rien d'autre sur le compte.

#### Comptes Usenet {#usenet-accounts}

Le type `nzb` n'est pas un service debrid, mais Usenet : les fichiers `.nzb` déposés dans le répertoire `nzbs/` deviennent des torrents dans la bibliothèque, et les lectures se font en récupérant les articles auprès de votre serveur de news puis en les décodant à la demande. Une seule entrée `nzb` activée est prise en charge, car deux entrées analyseraient le même répertoire. Les serveurs de news supplémentaires se placent plutôt sous `nntp.servers` de cette entrée : ils donnent accès à la même bibliothèque, au lieu d'en créer une seconde copie.

Une entrée `nzb` à côté d'une entrée [`torbox_nzb`](../providers/torbox-nzb.md) est refusée pour la même raison. Lancez ce type dans une instance à part, avec son propre répertoire de travail.

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `host` | string | *(obligatoire)* | Le nom d'hôte du serveur de news, par exemple `news.example.com`. |
| `port` | int | `563` avec TLS, `119` sans | Le port du serveur de news. |
| `tls` | bool | `false` | Enveloppe la connexion dans TLS. |
| `username` | string | `""` | Le nom d'utilisateur du compte. |
| `password` | string | `""` | Le mot de passe du compte. |
| `connections` | int | `8` | Le nombre de connexions simultanées autorisées pour le compte. zurg lit avec ce nombre : une seule connexion ne transporte qu'une fraction du débit d'un abonnement, donc le streaming utilise tout le quota au lieu de récupérer un article à la fois. Dépasser ce que l'abonnement permet entraîne des connexions refusées, donc indiquez la valeur réelle. |
| `pipeline_depth` | int | `4` | Le nombre d'articles que zurg demande en même temps sur une connexion. La limite est de 8. Mettez `1` pour un serveur qui ne gère pas plusieurs commandes en parallèle. zurg repasse à 1 tout seul, avec un avertissement, lorsque les lots n'arrêtent pas de se rompre. |
| `socket_receive_buffer_kb` | int | non défini | Fixe le tampon de réception du noyau de chaque connexion à ce nombre de KiB. Laissez-la non définie. Un tampon fixé n'est plus ajusté par le noyau. Sous Linux, cela bloque la fenêtre de réception autour de 64 KiB et fait perdre l'essentiel du débit du compte sur une liaison avec une latence quelconque. Cette option n'existe que pour les noyaux qui n'ajustent jamais ce tampon, ou dont le plafond est trop bas. |
| `cache_size_mb` | int | `512` | La quantité de données d'articles décodées gardée en mémoire, pour l'ensemble des fichiers lus et non par fichier. |
| `servers` | list | `[]` | Comptes de news supplémentaires vers lesquels basculer, article par article. Voir [plus d'un serveur de news](#more-than-one-news-server). |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### Plusieurs serveurs de news {#more-than-one-news-server}

La rétention est propre à chaque fournisseur : un article qu'un serveur a fait expirer se trouve très souvent encore sur un autre. Sans second compte, la seule façon de récupérer un article mort est PAR2, et cela oblige à relire **toute la release**. Un second serveur fait donc la différence entre récupérer un seul article et tout relire.

Les clés ci-dessus décrivent le premier compte. Tout ce qui se trouve sous `servers` est un compte supplémentaire, interrogé uniquement quand les comptes précédents n'ont pas trouvé l'article. Une configuration existante à un seul serveur continue de fonctionner sans changement.

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `name` | string | valeur de `host` | Donne un nom au compte dans les logs. |
| `host`, `port`, `tls`, `username`, `password`, `connections`, `pipeline_depth`, `warm_connections`, `socket_receive_buffer_kb` | | | Comme indiqué plus haut. Chaque compte a son propre quota de connexions. Le pipelining et le tampon de réception se règlent par compte, car la tolérance à ces réglages dépend du serveur. |
| `priority` | int | `0` | Détermine qui est interrogé en premier, du plus bas au plus haut. Les comptes de même priorité sont interrogés dans l'ordre où ils sont écrits, sauf qu'un compte ayant une connexion libre est préféré à un compte dont le quota est épuisé. Ainsi, deux comptes identiques se partagent la charge. |
| `backup` | bool | `false` | Marque un compte de secours, consulté uniquement une fois que tous les comptes principaux ont répondu *no such article*. Un compte principal **occupé** ne suffit pas : zurg attend plutôt que de dépenser des octets facturés pour quelque chose qu'un compte illimité aurait pu servir. |
| `backbone` | string | `""` | Le spool d'articles vers lequel ce compte pointe. Deux comptes sur un même backbone hébergent les mêmes articles : dès qu'un des deux a indiqué qu'il n'a pas un article, l'autre est ignoré au lieu de recevoir la même question. |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Le recensement qui décide si une release doit être réparée interroge chaque compte avant de déclarer un article manquant. Ainsi, une release dont un fournisseur a des trous ne déclenche pas une reconstruction PAR2 quand un autre fournisseur peut encore la servir.

Une clé de premier niveau détermine ce que les réparations laissent derrière elles :

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `par2_patch_cache_mb` | int | `512` | La place que peuvent occuper dans `data/par2/` les octets reconstruits par la réparation PAR2. Ces octets sont la seule chose qu'un lecteur ne peut plus redemander au serveur de news, car les articles qui les contenaient ont disparu. Les conserver évite qu'un redémarrage oblige à relire toute la release pour retrouver les mêmes quelques mégaoctets. Seuls les segments des articles morts sont stockés, soit quelques mégaoctets par release endommagée. Les releases entières sont supprimées, les moins récemment utilisées en premier, quand le budget est dépassé. Une valeur négative désactive la persistance et garde les réparations en mémoire pendant toute la durée du processus. |

Deux autres clés déterminent le coût en mémoire d'un NZB analysé :

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `nzb_segments` | string | `mmap` sous Linux/macOS/BSD, `resident` sous Windows | Détermine comment la liste des articles d'un NZB analysé est conservée. **Nécessite un redémarrage.** `mmap` écrit les listes dans `data/nzb-index/<id>.bin` et mappe ce fichier à la demande, de sorte que les octets vivent dans le cache de pages au lieu du tas de zurg. `reparse` libère la mémoire une fois la release stabilisée, puis relit le NZB depuis le disque quand une lecture ou une réparation en a besoin, sans aucune occupation disque. `resident` garde chacune de ces listes en mémoire pendant toute la durée du processus : **le comportement précédent**, celui de toutes les versions antérieures. Toute valeur non reconnue prend la valeur par défaut et est signalée dans un avertissement au démarrage. Quel que soit le cas, le mode réellement utilisé est écrit dans les logs au démarrage. |
| `nzb_segments_idle_secs` | int | `120` | Durée pendant laquelle la liste des articles d'une release est conservée après la dernière lecture, dans les modes paresseux. **Nécessite un redémarrage.** Un balayage a lieu toutes les 30 secondes, donc 10 est la plus petite fenêtre qu'il puisse respecter, et c'est le plancher affiché dans le Dashboard. Sans effet avec `resident`, qui ne rend jamais rien. `0` applique la valeur par défaut. |

Le compromis mérite d'être énoncé clairement, car il ne s'agit pas du classique mémoire contre vitesse. Un listage (un rafraîchissement de bibliothèque, une vérification d'empreinte, un *arr qui demande si un job est terminé) ne touche jamais un article, quel que soit le mode : le nom d'un fichier, sa taille et son nombre d'articles viennent directement de l'entrée. Ce que coûtent les modes paresseux, c'est la *première* lecture d'une release que personne n'a touchée pendant `nzb_segments_idle_secs`. Ce qu'ils économisent, c'est la mémoire qu'occupent les listes d'articles le reste du temps. Mesures sur une release de 60 fichiers et 30 000 segments (Apple M3 Pro) :

| | mémoire par release, stabilisée | première lecture d'une release inactive | par article sur le chemin de lecture |
|---|---|---|---|
| `resident` | 1,74 Mo (58 o/segment) | — | 6 ns |
| `reparse` | 21,3 ko (0,71 o/segment) | 39 ms | 52 ns |
| `mmap` | 16,6 ko (0,55 o/segment) | 0,27 ms | 63 ns |

Les deux tiers du rechargement `mmap` correspondent à la somme de contrôle calculée sur l'index qu'il vient de mapper. La carte elle-même ne prend que 0,08 ms, et ce contrôle en vaut la peine : sans lui, un seul octet corrompu dans une arène serait servi comme un identifiant de message que personne n'a jamais posté. Le serveur de news répondrait alors article mort, et toutes les couches au-dessus y verraient un dommage sur la release.

Et sur une bibliothèque réelle, soit 2 636 NZB et 27,6 millions de segments, le même binaire exécuté trois fois sur le même corpus, au repos après un scan :

| | ensemble résident | tas vivant | CPU au repos | ouverture à froid, p50 | index sur disque |
|---|---|---|---|---|---|
| `resident` | 2 921 Mo | 2 677 Mo | 23 % | 806 ms | — |
| `reparse` | 1 188 Mo | 987 Mo | 31 % | 1 018 ms | — |
| `mmap` | **1 135 Mo** | **921 Mo** | 23 % | **694 ms** | 1 456 Mo |

Les ouvertures à chaud, le débit de streaming et le temps de démarrage étaient indiscernables. `mmap` est le défaut partout où un vrai mapping est disponible, car il gagne sur tous les plans sauf le disque, ouverture à froid comprise : mapper une arène déjà écrite est un appel système, alors qu'analyser de nouveau le NZB représente des mégaoctets de XML. Il coûte environ 55 octets de disque par article, plus une écriture supplémentaire par release au moment du scan. L'index est réécrit chaque fois que le NZB change et supprimé quand le NZB disparaît. Choisis `reparse` sur un hôte où `data/` ne doit pas grossir. Sous Windows, il n'y a pas de mapping : l'index serait lu dans le tas, ce qui représente la mémoire résidente *plus* un rechargement. Le défaut y reste donc `resident`, et `reparse` est le mode paresseux qui vaut la peine d'être choisi.

## 2. Intégration au serveur multimédia {#2-media-server-integration}

Connectez zurg à votre serveur multimédia pour que les mises à jour de la bibliothèque, la correspondance des métadonnées et la surveillance de la liste de suivi fonctionnent automatiquement.

### Premiumize, Debrid-Link et Offcloud {#premiumize-debrid-link-and-offcloud}

```yaml
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY_OR_OAUTH_TOKEN
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_TOKEN
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
```

Ces backends permettent de parcourir la bibliothèque, de lire les fichiers en streaming et en redirection, d'utiliser STRM, d'ajouter des magnets, d'envoyer des fichiers `.torrent` et de supprimer des éléments. Chaque compte apparaît aussi dans son propre dossier `__<name>__`. Ajoute tes comptes depuis le tableau de bord ou avec `zurg setup` ; la configuration sans interaction accepte `--premiumize-token-file`, `--debridlink-token-file` et `--offcloud-token-file`, ou `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN` et `OFFCLOUD_TOKEN`.

Premiumize monte les transferts terminés et les fichiers du cloud conservés après le vidage de la liste des transferts. Les dossiers imbriqués gardent leurs chemins. Les hashes fournis via zurg sont enregistrés dans `data/premiumize/<account>/sources.json`, pour que la correspondance entre comptes survive à un redémarrage ou au vidage des transferts terminés. Un contenu cloud importé sans hash enregistré reste lisible en streaming, mais il ne peut pas être réparé par hash ni associé à un autre compte par hash. Supprimer un transfert Premiumize via zurg supprime aussi les fichiers appartenant à ce transfert. Le stockage cloud et les quotas d'usage raisonnable restent les limites propres au compte.

Debrid-Link liste le seedbox avec pagination et résout chaque fichier par son ID. Son ancien point de terminaison de cache n'est plus utilisé ; un ajout en mode cache uniquement ne peut confirmer un hit qu'à partir de la réponse de l'ajout. Les échecs liés aux quotas quotidiens d'ajouts et de trafic sont signalés comme limites du compte. Le backend fait une pause après un refus pour cause de flood.

Offcloud résout les handles de fichiers via le point de terminaison cloud explore. Les tailles de fichiers sont vérifiées auprès du serveur de livraison, et les métadonnées de torrent en cache fournissent les chemins de dossiers lorsqu'une correspondance est sans ambiguïté. Une liste de fichiers ambiguë est signalée comme erreur. Les magnets mal formés sont rejetés avant l'envoi.

Les URL de livraison sont rafraîchies quand leur cache expire ou qu'une lecture les invalide. Garde les URL générées et l'accès STRM privés ; les quotas du fournisseur appartiennent au compte qui sert les octets. Ces trois backends utilisent un seul identifiant par entrée de compte et ne passent pas par les ID de fichiers d'un autre compte.

### Intégration Plex {#plex-integration}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `plex_server_url` | string | `""` | URL de votre serveur Plex. Nécessaire pour la correspondance Plex et les fonctions de liste de suivi. Exemple : `http://localhost:32400` |
| `plex_token` | string | `""` | Votre jeton d'authentification Plex. Nécessaire en même temps que `plex_server_url`. |
| `plex_scan_check_url` | string | valeur de `plex_server_url` | Le serveur Plex que zurg interroge pour savoir si une analyse de bibliothèque est en cours avant de redémarrer le montage. Il attend tant qu'une analyse tourne. Un montage qui disparaît au milieu d'une analyse fait que Plex met à la corbeille tout ce qu'il ne pouvait pas voir. Définissez-le sur une instance qui n'a pas sa propre intégration Plex. En général, il faut une instance par fournisseur. Définir `plex_server_url` ici lancerait aussi la correspondance Plex. |
| `plex_scan_check_token` | string | valeur de `plex_token` | Le jeton pour `plex_scan_check_url`. |
| `plex_match_every_mins` | int | `1440` | À quelle fréquence (en minutes) zurg analyse votre bibliothèque Plex pour faire correspondre les torrents aux éléments Plex. Cela active des fonctions comme l'affichage des torrents correspondant à chaque média Plex. Minimum 1 ; `0` revient à la valeur par défaut. Nécessite que `mount_path` soit défini. |
| `plex_watchlist_enabled` | bool | `false` | Ancienne écriture de `watchlist.enabled` (voir [Liste de suivi](#watchlist)) ; toujours prise en compte. |
| `plex_watchlist_check_every_secs` | int | — | Ancienne écriture de `watchlist.check_every_secs` ; toujours prise en compte si le bloc n'en définit pas. |
| `watchlist_quality` | string | `"best"` | Ancienne écriture de `watchlist.quality` ; toujours prise en compte si le bloc n'en définit pas. |
| `plex_settings_policy` | string | `"guard"` | Jusqu'où zurg peut aller pour corriger les préférences Plex qui comptent pour un montage debrid. L'une de ces valeurs : `off` (ne rien toucher), `warn` (tout signaler, ne rien modifier), `guard` (corriger uniquement les réglages dont une mauvaise valeur fait perdre une bibliothèque, et signaler le reste) ou `enforce` (corriger aussi les réglages qui forcent Plex à décoder des fichiers entiers pour un résultat que personne ne voit). Tout ce qui a une fonction visible derrière — Skip Intro, Skip Credits, aperçus de défilement, images de chapitres, nivellement du volume, analyse sonore — est seulement signalé. Voir [Réglages Plex](../guides/plex.md#recommended-plex-settings). |
| `plex_settings_ignore` | list | — | Identifiants des préférences Plex que zurg laisse tranquilles, quelle que soit la politique, sans tenir compte de la casse. C'est par réglage et non par niveau : désactiver l'un ne fait donc pas perdre les autres à côté. Un identifiant qui ne correspond à aucun réglage connu de zurg est signalé au démarrage et ne change rien. Le commutateur **Let Plex Empty Its Own Trash** du tableau de bord ajoute `autoEmptyTrash` à cette liste. Voir [Désactiver un seul réglage](../guides/plex.md#opting-out-of-one-setting). |

> **Remarque :** Plex se configure au mieux via la procédure d'authentification du tableau de bord (interface web) ; elle réécrit `plex_server_url` et `plex_token` dans `config.yml`. Les clés ci-dessus restent prises en charge pour une configuration manuelle.

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### rex

zurg peut alimenter un [rex](../../rex/with-zurg.md), un serveur média pour les applications Plex officielles qui lit chaque fichier depuis zurg.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rex_url` | string | `""` | URL du rex qui construit sa bibliothèque à partir de ce zurg, par exemple `http://192.168.1.20:32400`. Choisir un rex dans la connexion Plex du tableau de bord règle cette clé sur l'adresse à laquelle rex récupère les sources (son adresse LAN ou Tailscale, en HTTP simple), et le flux démarre sans redémarrage ; la définir à la main permet d'alimenter un rex sans se connecter à Plex. zurg pousse alors sa bibliothèque vers rex : chaque fichier vidéo d'un répertoire configuré, chaque fichier audio dans un répertoire avec `rex_music`, et les bandes dessinées dans un répertoire avec `rex_photos`, avec leur chemin, leur taille, leur id IMDb et les détails média lus par ffprobe, une fois la bibliothèque chargée, toutes les `rex_snapshot_every_hours`, et à chaque ajout, analyse, renommage, déplacement ou suppression d'une release. rex ne peut pas lire un fichier avant que ffprobe l'ait analysé, donc définir `rex_url` active `auto_analyze_new_torrents` quelle que soit la valeur de cette clé, et analyse le reste de la bibliothèque une fois chargée, puis chaque jour. Chaque sonde lit depuis le compte qui détient la release ; gardez donc les répertoires étroits et évitez les filtres `tags_*` (avec l'un d'eux, chaque release du compte est analysée) si vous ne voulez pas d'une bibliothèque que vous ne regardez jamais, à cause de votre trafic. Un rafraîchissement cherche aussi l'id IMDb de chaque nouvelle release via `dmm_api_key` avant de la classer (voir `dmm_api_key` pour le placement des releases). Les sous-titres qu'un \*arr ou Bazarr écrit à côté d'une vidéo dans `__magic__` partent vers rex avec elle (voir [`__magic__`](../guides/magic.md)). zurg indique à rex où lire les fichiers : son WebDAV à `http://<address>:<port>/dav`, avec `username` et `password` s'ils sont définis. L'adresse est `host` quand c'est une seule adresse ; sinon, par défaut, c'est l'adresse par laquelle la connexion de zurg vers rex sort, et rex doit pouvoir l'atteindre. Dans un conteneur, c'est l'adresse propre du conteneur, que rex n'atteint que depuis la même machine Linux : sous Windows et macOS, installez zurg avec l'installeur plutôt que dans Docker Desktop, et sous Linux avec rex sur une autre machine, donnez au conteneur de zurg `network_mode: host` ([rex avec zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex)). Un rex indisponible est réessayé, puis reçoit la bibliothèque entière ; rien n'attend après lui. Aucun scan Plex n'est envoyé quand `plex_server_url` désigne ce même rex. Après chaque snapshot et toutes les dix minutes, zurg lit les Fix Matches faits dans rex pour ses releases et conserve chacun comme id défini à la main de la release, sauf si vous en avez défini un depuis sur la page de gestion ; DMM place alors la release d'après cet id. Pour donner à un répertoire ses propres bibliothèques dans rex, définissez [`rex_shows`, `rex_movies`, `rex_music` ou `rex_photos`](#directory-options) sur ce répertoire. Laissez `rex_url` vide si vous n'utilisez pas rex. |
| `rex_source` | string | `"zurg"` | Le nom de source sous lequel rex connaît ce zurg. Donnez à chaque zurg qui alimente le même rex son propre nom. |
| `rex_snapshot_every_hours` | int | `6` | Fréquence à laquelle la bibliothèque entière est de nouveau poussée vers rex, ce qui répare ce qu'un envoi manqué a laissé. La valeur par défaut convient à toutes les configurations. |

```yaml
rex_url: "http://192.168.1.20:32400"
```

### Watchlist

Ajoute quelque chose à ta liste de suivi Plex et zurg le récupère. Chaque nouvel élément de la liste est recherché sur tes indexeurs. Un indexeur Newznab donne un NZB. Il est déposé dans le backend Usenet exactement comme le ferait un grab Sonarr ou une lecture Stremio. Les trois partagent les mêmes règles de nommage, donc ils retrouvent les grabs des autres au lieu de les dupliquer. Un indexeur Torznab donne un torrent. Il n'est ajouté à un compte debrid que si ce compte l'a déjà en cache. `prefer` décide quel type est essayé en premier entre des releases de la même résolution. Un film devient une seule release. Une série est récupérée saison par saison, et les packs de saison passent avant les épisodes isolés. Une saison pour laquelle personne n'a posté de pack retombe sur les épisodes isolés trouvés par la recherche, la meilleure release pour chacun. L'élément ne quitte la liste qu'une fois la release derrière lui vérifiée, et seulement si `remove_after_grab` le permet. Les échecs restent sur la liste. Ils sont réessayés après 5, 10 et 15 minutes, puis après une heure, puis de plus en plus espacés, et un titre en échec depuis deux semaines est mis en pause jusqu'à ce que tu le reprennes sur la page d'acquisition. Voir [persistance et récupération](../guides/acquisition.md#persistence-and-recovery).

Il faut un `plex_token` et au moins un indexeur. Sans liste propre, il emprunte celle de l'addon Stremio. Le moniteur communique avec le service cloud de Plex, donc `plex_server_url` n'est pas requis. Les NZB nécessitent un provider `nzb` ou `torbox_nzb` sur la même instance. Les torrents nécessitent un compte debrid qui les accepte. L'un ou l'autre suffit.

Chaque option ci-dessous se trouve sur la page de configuration sous **Plex Watchlist**, liste d'indexeurs comprise. Le tableau de bord écrit ce bloc plutôt que les anciennes clés plates, et désactiver le moniteur là-bas efface aussi `plex_watchlist_enabled`, car cette clé est combinée (OU) à l'interrupteur.

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| `enabled` | bool | `false` | Démarre le moniteur. L'ancienne clé `plex_watchlist_enabled` fonctionne toujours. |
| `check_every_secs` | int | `60` | Fréquence d'interrogation de la liste sur le service cloud de Plex. |
| `indexers` | list | `[]` | Indexeurs à interroger, chacun avec `name`, `url`, `api_key` et en option `api_path` et `type`. `type: torznab` désigne un indexeur torrent. Absent, c'est `newznab`. Même format que `stremio.indexers`, qui est repris tel quel quand cette liste est vide. |
| `prefer` | string | `"usenet"` | Type essayé en premier quand un NZB et un torrent de même résolution pourraient convenir. La résolution décide d'abord, donc un torrent 2160p passe avant un NZB 1080p. `usenet` essaie les NZB en premier, `torrents` essaie les torrents en premier, et `best` laisse seul le classement décider. Voir [Newznab et Torznab](../guides/acquisition.md#newznab-and-torznab). |
| `max_size_gb` | int | `0` | Les releases plus grosses que ceci sont écartées pour les films et les épisodes isolés, et les packs de saison dont la taille par épisode dépasse ce seuil. `0` signifie aucune limite, donc `best` prend un remux en disque complet. Les releases dont l'indexeur n'a pas indiqué la taille sont conservées. |
| `max_season_size_gb` | int | `0` | Plafond sur chaque saison contenue dans un pack de saison, par saison citée. `0` signifie aucune limite : un pack n'est retenu que selon `max_size_gb` par épisode, quand celui-ci est renseigné, donc le remux d'une saison longue compte toujours. |
| `quality` | string | `"best"` | Release retenue : `best` (résolution d'abord, puis taille), `4k`, `1080p`, `720p` (privilégie cette résolution, sinon retombe sur best) ou `smallest`. L'ancienne clé `watchlist_quality` fonctionne toujours. Une seule valeur ici ; seul `acquisition.quality` accepte une liste (voir [Sources d'acquisition](#acquisition-sources)). |

Le bloc `acquisition` accepte aussi `concurrency` (défaut `8`, de `1` à `200`), le nombre de titres recherchés, vérifiés et placés en même temps, et `indexer_concurrency` (défaut `3`, de `1` à `16`), le nombre d'appels simultanés vers un même indexeur. Garde cette dernière valeur basse quand une clé d'indexeur est partagée.

`exclude_words` n'a pas de copie dans ce bloc. Pour exclure des mots comme `DV` ou `HDR10+` des grabs de la liste, ajoute un bloc `acquisition:` ne contenant que `exclude_words`. Tous les réglages ci-dessus s'appliquent toujours. Voir [exclure des releases par nom](../guides/acquisition.md#excluding-releases-by-name).

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  quality: best
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: your-api-key
```

### Sources d'acquisition {#acquisition-sources}

`acquisition.sources` liste les services pour lesquels zurg acquiert des fichiers, chacun sur la file partagée décrite dans [sources d'acquisition](../guides/acquisition.md). Les réglages de recherche (`indexers`, `quality`, `prefer`, `max_size_gb`, `max_season_size_gb`) se trouvent à côté de `sources` dans le bloc `acquisition:` et reprennent les valeurs du bloc `watchlist:` au-dessus lorsqu'ils ne sont pas définis. Seule l'option `acquisition.quality` accepte aussi une liste de résolutions, comme `[1080p, 4k]` : zurg garde alors une copie de chaque film de la wanted list de DMM à chacune de ces résolutions, tandis que les séries de cette liste et toutes les autres sources prennent la résolution la plus élevée de la liste comme unique `quality`. Voir [une copie à chaque résolution](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

`best_first` ne concerne que le bloc `acquisition:` et est désactivé par défaut. Activé, il fait suivre à la première récupération d'une source `radarr` ou `sonarr` l'ordre de préférence du profil de qualité. La meilleure résolution autorisée passe en premier. Tout ce qui est égal ou supérieur au cutoff compte comme le cutoff. Si une release échoue, zurg descend dans le profil. Désactivé, un film prend la release autorisée la moins coûteuse à vérifier. Une série prend celle que `quality` classe en premier. Le passage de mise à niveau vise ensuite le cutoff. La meilleure release est souvent un ensemble d'archives volumineux, si bien que le premier fichier arrive généralement plus tard. Voir [prendre d'abord le meilleur du profil](../guides/acquisition.md#taking-the-profiles-best-first).

`exclude_words` (liste, vide par défaut) existe aussi et n'a pas de valeur de repli dans `watchlist:`. Une release dont le nom contient l'un de ces mots n'est jamais prise, quelle que soit la source. La correspondance se fait sur le mot entier et ignore la casse, donc `DV` ne capture pas `DVDRip`. `DV`, `DoVi` et `Dolby Vision` comptent pour un seul mot, de même que `HDR10+` et `HDR10Plus`. `HDR10` et `HDR10+` sont deux mots différents. Une entrée sans lettre ni chiffre est refusée au démarrage. Les règles complètes et leur combinaison avec les profils Radarr et Sonarr sont décrites dans [exclure des releases par nom](../guides/acquisition.md#excluding-releases-by-name).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | obligatoire | Lettres, chiffres, `_` et `-`, unique. Identifie la file sauvegardée de la source, gardez-le stable. |
| `type` | string | obligatoire | `plex_watchlist`, `seerr`, `radarr` ou `sonarr`. |
| `enabled` | bool | `false` | Une source désactivée reste dans le fichier mais n'est pas interrogée. Une source `radarr` ou `sonarr` désactivée est toujours lue, en lecture seule, par la [vue des doublons](../guides/acquisition.md#finding-duplicate-releases) de la page de gestion. |
| `check_every_secs` | int | `60` | Fréquence d'interrogation de la source. |
| `url` | string | | `seerr`, `radarr` et `sonarr` : l'URL de base HTTP(S) du service, sans identifiants, requête ni fragment. Une URL de base et un `/api/v1` (Seerr) ou `/api/v3` (Radarr, Sonarr) en fin d'URL sont acceptés. |
| `api_key` | string | | `seerr`, `radarr` et `sonarr` : la clé API du service. Elle est envoyée dans un en-tête, jamais dans une URL, et masquée dans les journaux et configurations partagés. |
| `library_path` | string | `mount_path` + `/__magic__` | `radarr` et `sonarr` uniquement : l'emplacement où le \*arr voit le dossier `__magic__` de zurg, par exemple `/data/zurg/__magic__` pour un conteneur qui monte zurg sur `/data/zurg`. Un dossier de film ou de série placé dessous est rangé au même chemin relatif dans `__magic__` ; un dossier ailleurs est ignoré. Doit être absolu ; les chemins Windows comme `Z:\__magic__` sont acceptés. zurg compare aussi cette valeur à l'emplacement où le \*arr voit le dossier de téléchargement d'un client de téléchargement zurg, et signale toute disposition qui transforme les imports en copies ; voir [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |
| `remove_after_grab` | bool | `true` | `plex_watchlist` uniquement ; sans effet pour `seerr`, `radarr` et `sonarr`. |
| `only_new_items` | bool | `true` | `plex_watchlist` uniquement ; sans effet pour `seerr`, `radarr` et `sonarr`, dont les éléments demandés sont toujours traités. |

```yaml
acquisition:
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /data/zurg/__magic__
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /data/zurg/__magic__
```

### Maintenance de la bibliothèque Plex (même hôte uniquement) {#plex-library-maintenance-same-host-only}

Ces options nécessitent que Plex soit installé sur la même machine que zurg, car elles lisent directement son fichier de base de données. `plex_server_url` est souvent un autre hôte ou conteneur, et aucun point de terminaison HTTP ne peut fournir ce fichier. Elles sont donc pilotées par un chemin explicite et restent désactivées tant que vous n'en avez pas défini un.

zurg ne fait que **lire** cette base de données, via un accès en lecture seule. Il n'y écrit jamais et n'arrête jamais Plex. Le seul fichier qu'il crée est un instantané dans son propre `data/plex-backups/`, jamais dans le répertoire de Plex.

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `plex_database_path` | string | `""` | Chemin complet vers `com.plexapp.plugins.library.db`. Vide désactive toutes les fonctionnalités de cette section. |
| `plex_sqlite_binary` | string | là où Plex l'installe : `/usr/lib/plexmediaserver/Plex SQLite` sous Linux, `/Applications/Plex Media Server.app/Contents/MacOS/Plex SQLite` sous macOS, `%ProgramFiles%\Plex\Plex Media Server\Plex SQLite.exe` sous Windows | Plex embarque sa propre version de SQLite. Un `sqlite3` classique peut échouer sur cette base, ou l'endommager. |
| `plex_backups_keep` | int | `5` | Nombre d'instantanés conservés. Chacun a la taille de la base entière. Un `0` explicite observe sans jamais faire d'instantané. |
| `plex_backups_every_mins` | int | `15` | Délai minimum entre deux instantanés, pour qu'un zurg qui redémarre en boucle ne copie pas la base à chaque redémarrage. |
| `plex_trash_sweep_every_mins` | int | non défini (voir la note) | Fréquence de suppression des entrées Plex dont les fichiers ont disparu du montage. Non défini, zurg décide : la suppression tourne toutes les 60 minutes quand rien d'autre ne vide la corbeille de Plex, et s'arrête quand Plex la vide encore. Un `0` explicite désactive la suppression de zurg et laisse la corbeille à votre charge ; une valeur négative désactive tout le balayage, réparation comprise. `0` ne rend **pas** à Plex le vidage de sa propre corbeille, ce qui relève de `plex_settings_ignore` et de l'interrupteur du tableau de bord **Let Plex Empty Its Own Trash**. Voir [Qui vide la corbeille](../guides/plex.md#who-empties-the-trash). |
| `plex_trash_sweep_max_items` | int | `50` | Nombre maximum d'entrées qu'un balayage peut supprimer. Le dépasser interrompt le balayage sans rien supprimer. |
| `plex_trash_sweep_max_percent` | int | `10` | Même plafond, exprimé en pourcentage de ce qui se trouve dans la corbeille : il s'adapte donc à la taille de la bibliothèque. |
| `plex_trash_sweep_min_age_days` | int | `14` | Durée pendant laquelle une entrée garde son icône rouge de corbeille avant que le balayage puisse la supprimer — le repli pour les entrées sur lesquelles zurg n'a pas de verdict. Une release que zurg sait définitivement morte est supprimée sans attendre, et une release encore en réparation reste, quel que soit son âge. Un `0` explicite supprime dès que les autres garde-fous le permettent. |

**Pourquoi des instantanés**, alors que Plex fait déjà une sauvegarde chaque nuit : le danger est que le montage soit perturbé pendant qu'un scan de Plex est en cours, ce qui peut vider une bibliothèque en quelques secondes. Une sauvegarde nocturne peut alors dater de 24 heures ; un instantané pris juste avant que zurg touche au montage n'a que quelques secondes.

#### Ce que le nettoyage de la corbeille ne supprimera jamais {#what-the-trash-sweep-will-never-remove}

La corbeille de Plex n'est pas une liste d'éléments que l'on peut supprimer. C'est une liste de candidats, et une grande partie d'entre eux sont faux :

- **Un élément qui a encore un fichier.** Plex marque un film entier comme supprimé dès qu'une seule de ses versions disparaît, donc un élément mis à la corbeille a souvent des versions qui fonctionnent encore. Le balayage supprime plutôt la version fantôme, ce qui fait ressortir l'élément de la corbeille avec ses collections, ses illustrations, son état de lecture et son `added_at` intacts. Si cette réparation échoue pour une raison quelconque, l'élément est **laissé tel quel** : il reste dans votre bibliothèque avec son icône de corbeille. Il n'est jamais supprimé.
- **Une série ou une saison dont les épisodes sont encore là.** Ceux-ci n'ont aucun fichier, donc rien dans le montage ne peut justifier d'en supprimer un.
- **Tout élément dont le fichier n'a pas été confirmé individuellement comme manquant**, juste avant sa suppression.

La suppression se fait élément par élément, et non avec `emptyTrash` de Plex. `emptyTrash` agit sur toute la section et supprimerait exactement les entrées ci-dessus, ce que le balayage ne doit justement jamais faire.

#### zurg sait déjà s'il va revenir {#zurg-already-knows-whether-it-is-coming-back}

| Verdict de zurg | Le balayage |
|---|---|
| le fichier est toujours lisible (les filtres le cachent du montage) | se rabat sur la fenêtre d'ancienneté |
| cassé, et la réparation n'a pas abandonné | **garde l'entrée**, quelle que soit la durée de la réparation |
| cassé avec une raison définitivement irréparable (infringing, invalid, not allowed, …) | **la supprime immédiatement** — attendre ne la fera pas revenir |
| aucun verdict — le torrent a quitté le compte complètement, ou le chemin ne se résout pas | se rabat sur la fenêtre d'ancienneté |

Un élément avec plusieurs versions est jugé comme un tout : une seule version encore en réparation garde toute l'entrée, et une entrée n'est considérée comme morte que lorsque toutes les versions le sont. Une recherche échouée n'est jamais une autorisation de supprimer : tout ce que zurg ne peut pas garantir est traité par la fenêtre d'ancienneté ci-dessous, exactement comme avant.

#### L'icône de la corbeille est un statut, donc la suppression attend {#the-trash-icon-is-a-status-so-removal-waits}

Plex a trois états, et seul le du milieu se voit comme un problème :

| État | Ce que tu vois |
|---|---|
| En ligne | une entrée normale qui se lit |
| **Mis à la corbeille** | l'entrée est **toujours dans ta bibliothèque et toujours comptée**, grisée avec une **icône de corbeille rouge**, et elle ne se lit pas |
| Purgé | rien : l'entrée a complètement disparu de Plex |

L'icône de corbeille est le seul signal que du contenu a disparu, et purger l'entrée supprime aussi ce signal : l'élément n'a plus l'air cassé, il n'existe plus tout simplement. Une entrée sur laquelle zurg n'a pas de verdict est donc laissée tranquille tant qu'elle n'a pas porté l'icône pendant `plex_trash_sweep_min_age_days`. Cette période te laisse le temps de la voir et de la récupérer à nouveau ; ce qui reste cassé après coup était un déchet qui méritait d'être nettoyé.

Elle sert aussi de troisième couche de sécurité, en plus des plafonds et de la sonde de montage : un problème de montage passager se règle tout seul bien avant la fin de la période.

Le délai de grâce ne concerne **que la suppression**. Une réparation remet un élément lisible dans ta bibliothèque, donc elle a lieu au prochain balayage dans tous les cas : attendre laisserait un élément qui fonctionne porter une icône de corbeille pour rien.

Aucun de ces états ne touche aux fichiers. Le fichier avait déjà disparu du montage, c'est ce qui a créé la pierre tombale, et rien n'est jamais supprimé de ton compte debrid.

#### Quand il refuse de s'exécuter {#when-it-refuses-to-run}

- zurg ne gère pas rclone (`rclone_enabled: false`). Il ne peut pas garantir un montage qui ne lui appartient pas, donc « le fichier est absent » ne veut rien dire.
- rclone ne tourne pas, ou le montage ne lit rien. La sonde ouvre et lit un fichier au lieu d'appeler `stat`, car un `stat` répond à partir du cache de répertoires de rclone et continue de réussir bien longtemps après que les lectures ont cessé de fonctionner.
- Plex est en train de scanner. Un scan en cours décide encore de ce qui manque.
- L'un des deux plafonds serait dépassé. C'est le point important : **un montage revenu vide mais lisible passe toutes les autres vérifications** et fait apparaître toute la bibliothèque comme supprimée. Dépasser un plafond interrompt entièrement le balayage, ne supprime rien, et le signale dans le journal.

Un instantané est pris avant toute suppression, et un échec de l'instantané interrompt le balayage.

> **Pour désactiver :** définissez `plex_trash_sweep_every_mins: 0` (supprimer la clé n'a pas le même effet : zurg décide alors selon que Plex vide ou non sa propre corbeille). Ce changement nécessite un redémarrage de zurg. Cela désactive uniquement la suppression par zurg. Pour que Plex vide à nouveau sa propre corbeille, utilisez l'interrupteur **Let Plex Empty Its Own Trash** du tableau de bord, ou ajoutez `autoEmptyTrash` à `plex_settings_ignore`.

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

Ce chemin correspond à l'endroit où le paquet Linux stocke la base de données. Sous macOS et Windows, écrivez-le en entier, car zurg ne développe pas `~` ni `%LOCALAPPDATA%`. `plex_sqlite_binary` a déjà pour valeur par défaut l'emplacement où Plex l'installe sur chaque système.

| Plex sur | `plex_database_path` |
|---|---|
| macOS | `/Users/you/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db` |
| Windows | `C:\Users\you\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db` |

Mettez un chemin Windows entre guillemets simples en YAML pour que ses antislashs restent tels quels.

> **Paramètre Plex associé, hors de zurg :** désactivez *Settings → Library → Empty trash automatically after every scan* dans Plex. Il est activé par défaut dans Plex et n'est pas sûr sur un montage zurg : un scan qui rencontre un montage brièvement illisible supprime définitivement la bibliothèque au lieu de la placer dans la corbeille, où elle reviendrait avec le montage. zurg le désactive lui-même avec la politique par défaut `guard`, et l'indique sur le tableau de bord et dans le journal. Si vos fichiers passent d'un dossier de bibliothèque à un autre et que vous avez besoin de ce nettoyage, l'interrupteur **Let Plex Empty Its Own Trash** de la page de configuration le rend à Plex, à vos risques.

### Autres intégrations {#other-integrations}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `jellyfin_server_url` | string | `""` | URL de votre serveur Jellyfin. Active les notifications de rafraîchissement de la bibliothèque lorsque zurg détecte des changements. Exemple : `http://localhost:8096` |
| `jellyfin_token` | string | `""` | Jeton d'API Jellyfin pour l'authentification. |
| `emby_server_url` | string | `""` | URL de votre serveur Emby. Active les notifications de rafraîchissement de la bibliothèque lorsque zurg détecte des changements. Exemple : `http://localhost:8096` |
| `emby_token` | string | `""` | Jeton d'API Emby pour l'authentification. |
| `dmm_api_key` | string | `""` | Votre clé d'API DMM. [gatekeeper](https://gatekeeper.debridmediamanager.com/) l'affiche une fois que vous devenez sponsor. DMM place ensuite vos fichiers et remplit votre liste de souhaits. |
| `dmm_metadata_secret` | string | `""` | Secret pour l'API de métadonnées interne de DMM. Lorsqu'il est défini, les torrents sans identifiant IMDb (ou avec seulement le marqueur d'absence d'OpenSubtitles) sont identifiés au démarrage à partir de leur nom de release via DMM, qui ne répond que lorsqu'un seul titre correspond exactement. Les torrents que DMM ne peut pas nommer gardent un identifiant vide, afin que le matcher Plex puisse quand même les compléter. |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. Lecture et structure des fichiers {#3-playback--file-structure}

Contrôle les fichiers que votre serveur multimédia voit et la manière dont le contenu est diffusé en streaming.

### Mode streaming {#streaming-mode}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | Quand c'est vrai, une lecture de **mount** reçoit une redirection vers l'URL de téléchargement du compte au lieu d'être relayée par zurg. Cela réduit le CPU et la bande passante de zurg, mais le client doit pouvoir atteindre directement les serveurs du compte. Ignoré pour un backend dont les liens sont servis localement : un fichier Usenet n'a pas d'URL à fournir, il est donc toujours relayé. **Lis les risques liés au fournisseur ci-dessous avant de l'activer.** |
| `serve_strm_files` | bool | `false` | Quand c'est vrai, zurg sert des fichiers `.strm` à la place des vrais fichiers vidéo dans le montage WebDAV. Les serveurs multimédias comme Plex/Jellyfin lisent le fichier `.strm` pour obtenir l'URL de streaming. **Important :** quand c'est activé, les vrais fichiers vidéo sont cachés et remplacés par des entrées `.strm`. |
| `save_strm_files` | bool | `false` | Quand c'est vrai, zurg écrit des fichiers `.strm` dans un dossier `strm/` à côté du binaire zurg. Utile si tu veux des fichiers STRM persistants sur le disque (par exemple pour un import manuel dans un serveur multimédia). Utilise `base_url` pour les URLs à l'intérieur des fichiers. Seuls les fichiers qu'un lecteur peut ouvrir en reçoivent un : vidéo et audio reconnus, plus tout ce que `addl_playable_extensions` indique. Les sous-titres, affiches, NFO et volumes PAR2 restent donc hors de l'export, et ceux qu'une ancienne version aurait écrits là sont supprimés à la prochaine exploration de la release. Un `.strm` dont l'URL ne correspond plus, parce que `base_url` a changé ou qu'une ancienne version l'a écrit, est réécrit sur place au prochain démarrage, ou immédiatement si `base_url` est modifié dans le tableau de bord. Les fichiers déjà corrects ne sont pas touchés, donc un serveur multimédia ne relit pas tout le dossier à chaque scan. |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

**Garde les lectures de montage proxifiées (la valeur par défaut) pour la lecture partagée via debrid.** Real-Debrid suit l'IP publique de chaque téléchargeur. Utiliser un même compte depuis plusieurs IP vaut un avertissement de partage, même quand le téléchargement réussit. Garde toutes les utilisations de ce compte sur une seule IP publique, y compris les vérifications serveur et les conversions, pas seulement les téléchargements des lecteurs. Les URLs de téléchargement TorBox contiennent la clé API complète dans `?token=`. Une redirection donne donc accès à chaque client et à chaque compte utilisateur partagé, y compris la suppression, et les journaux des lecteurs et l'historique du navigateur peuvent la conserver. Ne donne pas de liens TorBox à des clients non fiables.

Ces risques s'appliquent à la fois aux redirections de montage avec `disable_stream_proxy: true` et aux redirections `/strm/`. Garder `disable_stream_proxy: false` **ne rend pas** la lecture `.strm` proxifiée ni sûre pour le partage à distance.

#### Ce que fait et ne fait pas `disable_stream_proxy` {#what-disable_stream_proxy-does-and-does-not-reach}

Il gère le montage. Il n'atteint pas l'endpoint `/strm/`, quel que soit le backend :

| La lecture arrive via | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| Montage, proxy activé (par défaut) | passe par le proxy de zurg | passe par le proxy |
| Montage, proxy désactivé | `302` vers l'URL du compte | passe par le proxy — il n'existe aucune URL vers laquelle rediriger |
| Un fichier `.strm`, quel que soit le réglage | `307` vers l'URL du compte | passe par le proxy |

Un `.strm` est ouvert par un lecteur avec lequel zurg n'a aucune session. L'endpoint ne peut donc que fournir une URL que le lecteur peut récupérer lui-même : activer le proxy ne fait pas repasser ce trafic par zurg. Ce qu'il faut savoir : les lectures qui arrivent depuis des fichiers `.strm` ne bénéficient ni du comptage de bande passante, ni de la bascule en cours de lecture vers un autre compte, ni de la détection des liens cassés, alors qu'une lecture via le montage en profite. Une bibliothèque servie surtout via `.strm` ne voit donc presque rien de `disable_stream_proxy`, dans un sens comme dans l'autre.

`serve_strm_files` et `disable_stream_proxy` sont indépendants, contrairement à ce que disaient les anciennes versions de cette page. Un `.strm` est servi comme du texte avant même qu'une décision de streaming ne soit prise, donc les deux peuvent être activés ensemble. Mais avec `serve_strm_files` activé, chaque lecture arrive sur l'endpoint `/strm/`, c'est précisément la ligne du tableau où `disable_stream_proxy` ne change rien.

### Filtrage et détection des fichiers {#file-filtering--detection}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `addl_playable_extensions` | list | `[]` | Extensions de fichiers que zurg doit traiter comme des médias lisibles, en plus des formats vidéo/audio intégrés. Les points, les guillemets et la casse sont normalisés par le tableau de bord. Ajoutez des extensions comme `m3u` ou `cbz` si vous voulez que ces fichiers soient visibles et sélectionnables. |
| `force_select_playable_files` | bool | `false` | Quand la valeur est true, zurg sélectionne automatiquement tous les fichiers lisibles d'un torrent, même s'ils n'étaient pas sélectionnés à l'origine. Fonctionne avec les extensions vidéo intégrées et avec `addl_playable_extensions`. Utile quand des torrents contiennent des fichiers vidéo non sélectionnés auxquels vous voulez accéder. |
| `delete_torrent_if_extensions_found` | list | `[]` | Si un fichier d'un torrent possède l'une de ces extensions, le torrent entier est supprimé de RD. Utile pour supprimer automatiquement les torrents contenant du contenu indésirable, comme des archives `.rar` (pas celles extraites par RD) ou des fichiers `.zipx`. |
| `stream_compressed_archives` | bool | `true` | Diffuse un fichier contenu dans une archive compressée en le décodant au fur et à mesure de sa lecture. Le décodeur utilise une fenêtre de taille limitée en mémoire. Mettez `false` pour refuser les archives compressées comme le faisaient les anciennes versions. |

Les formats lisibles intégrés sont `.avi`, `.flv`, `.m2ts`, `.m4v`, `.mkv`, `.mov`, `.mp4`, `.mpg`, `.mpeg`, `.ts`, `.webm`, `.wmv`, `.mp3`, `.flac`, `.m4a` et `.m4b`.

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### Métadonnées et nommage {#metadata--naming}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `retain_folder_name_extension` | bool | `false` | **Déprécié, sera supprimé.** Quand c'est true, le nom du dossier est le `Name` du compte tel quel, extension comprise, au lieu de `OriginalName` avec `.mp4` puis `.mkv` retirés en fin de nom. Ça ne s'applique que quand `Name` contient `OriginalName` comme sous-chaîne ; partout ailleurs, le retrait se fait quand même. `retain_rd_torrent_name` est vérifié en premier et le masque complètement. |
| `retain_rd_torrent_name` | bool | `false` | **Déprécié, sera supprimé.** Quand c'est true, le nom du dossier est le `Name` du compte (le `filename` de Real-Debrid) ; quand c'est false, c'est `OriginalName` (`original_filename`), le nom déclaré par le torrent lui-même. Ça compte pour un pack avec un seul fichier sélectionné : Real-Debrid réduit `filename` au nom de base de ce fichier, alors que `original_filename` reste le nom du pack. Donc **`false` donne le nom du pack et `true` donne le nom du fichier individuel**. |
| `ignore_renames` | bool | `false` | Quand c'est true, zurg ignore toutes les métadonnées de renommage dans les torrents et utilise les noms de fichiers d'origine. Activez ça si les fichiers renommés posent problème à la correspondance de votre serveur média. Pas déprécié. |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

Les deux options dépréciées indexent la bibliothèque sur `Name`, que le compte réécrit
en coulisse ; les valeurs par défaut l'indexent sur le nom déclaré par le torrent, que le
compte laisse tranquille. Activer l'une ou l'autre affiche un avertissement au démarrage, et sur
une instance qui sert Sonarr ou Radarr (un bloc `sabnzbd:` ou `qbittorrent:`), les
valeurs par défaut sont les seules correctes — une clé d'accès qui change après un import
fait perdre la release. Le comportement ne change pas dans cette version : personne ne voit ses noms de dossiers bouger.
`docs/naming.txt` contient l'ensemble complet des règles de nommage.

### Écritures sur le montage {#mount-writes}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `dav_allow_rename` | bool | `true` | Quand la valeur est false, un WebDAV MOVE passant par le montage est refusé avec un 403. Activé par défaut : renommer un torrent ou un fichier est précisément à quoi sert le montage en écriture, et ça ne détruit rien. |

**Un WebDAV DELETE passant par le montage est toujours accepté : il n'existe aucune clé pour ça.** Il supprime un fichier de la bibliothèque et, une fois qu'il ne reste plus rien, la release de chaque compte debrid qui la contient. Sachez ce que ça coûte avant de brancher un programme d'écriture sur le montage : rclone envoie un fichier écrasé sous forme de DELETE suivi d'un PUT. Donc tout ce qui réécrit un fichier sur place (un écrivain de `.nfo`, un passage de trickplay, un renommage \*arr, un `touch` malencontreux) supprime le contenu au lieu de le remplacer. Et le montage utilise les propres identifiants de rclone, si bien que l'authentification ne peut pas distinguer les deux cas. Seul le refus de la moitié PUT empêche cette séquence de se terminer silencieusement. `mount_read_only: true` est ce qui empêche un DELETE d'atteindre zurg.

Une écriture refusée répond **403** et journalise la clé de config qui l'autoriserait. Ainsi, un client dont l'écriture ne fonctionne plus indique la raison dans `logs/zurg.log`.

Une conséquence à connaître : quand un programme écrit via le montage FUSE, le cache VFS de rclone garde la copie modifiée et réessaie l'envoi refusé selon un backoff. Le montage affiche le fichier modifié localement tant que cette entrée de cache n'est pas supprimée, alors que le fichier côté serveur reste intact pendant tout ce temps. `mount_read_only: true` évite complètement ce problème en faisant échouer l'écriture au niveau du noyau, avant que rclone ne mette quoi que ce soit en cache.

```yaml
dav_allow_rename: true
```

Voir aussi `mount_read_only`, qui fait refuser l'écriture par le noyau avant qu'elle n'atteigne zurg.

### Cache de la liste des répertoires {#directory-listing-cache}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `disable_listing_cache` | bool | `false` | Lorsque la valeur est true, chaque listing de répertoire est recalculé entièrement à chaque requête. Laisse-le désactivé : avec l'option activée, un `PROPFIND Depth:1` de `__all__` recalcule toute la bibliothèque à chaque demande (mesuré à 59 ms pour 6,120 releases, 121 ms pour 2,636 releases Usenet, 148 ms pour `__magic__/__all__`), et un scan du serveur média redemande le même listing encore et encore. |

```yaml
disable_listing_cache: false
```

Le cache garde le dernier rendu de chaque répertoire de premier niveau, un par variante de montage (`/dav`, `/infuse`, `/http`), et le renvoie jusqu'à ce que la bibliothèque change. Ce qui compte comme un changement n'est pas une supposition : ce sont exactement les événements qui font déjà oublier à rclone sa propre copie en cache du même listing (une release ajoutée, supprimée, renommée, reclassée, un fichier qui casse ou qui se répare), et rclone garde ces listings pendant **douze heures**. Donc un listing servi d'ici n'est jamais plus ancien que celui que le montage sert déjà, et il y a en plus un plafond strict de 60 secondes, par précaution.

`__magic__/__all__` (le miroir, et le seul listing de l'espace de noms qui vaut la peine d'être mis en cache, puisque la racine au-dessus ne contient que le miroir et quelques entrées) suit en plus le layout stocké. Donc un import \*arr invalide ce seul listing et laisse intact le rendu de tous les autres répertoires. `__downloads__` et les requêtes `Depth: 0` ne sont pas mises en cache du tout.

Les réponses portent un en-tête `X-Zurg-Listing: hit` ou `miss`, pour qu'une installation en service puisse être mesurée :

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`, un répertoire que vous pouvez organiser {#__magic__-a-directory-you-can-organise}

Tous les autres dossiers sont un filtre enregistré : une release se trouve dans `movies` parce qu'elle correspond au filtre movies. Il n'y a donc nulle part dans la bibliothèque où *mettre* quelque chose.

`__magic__` fait exception : `__magic__/__all__` est une copie exacte de `__all__`, et la racine à côté est à toi. Tu peux déplacer n'importe quoi hors du miroir vers n'importe quel autre endroit de l'espace de noms.

Un déplacement réécrit une ligne dans `data/magic.journal`, compactée ensuite dans `data/magic.json`. Aucun octet ne bouge, aucun torrent n'est renommé, et les lignes sont indexées par le hash de contenu de la release. Une réparation qui reconstruit la release ne fait donc pas perdre l'endroit où tu as rangé les choses.

C'est ce qui permet à Radarr et Sonarr d'importer par renommage au lieu de par copie.

Documentation complète, y compris ce qui survit à une réparation et ce que signifie chaque refus, dans [docs/magic.md](../guides/magic.md).

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `magic.enabled` | bool | `false` | Servir `__magic__` tout court. Désactivé par défaut : c'est une arborescence accessible en écriture, et un \*arr pointé sur le mauvais dossier racine peut réorganiser une bibliothèque. Tant que rien n'a été déplacé, son propre `__all__` se lit exactement comme celui de la bibliothèque, et la racine ne contient rien d'autre. |
| `magic.allow_delete` | bool | `false` | Si true, un DELETE d'un **fichier** sous `__magic__` supprime aussi le contenu, comme le fait toujours un DELETE sur le montage lui-même. Désactivé par défaut, une suppression ne fait que masquer : l'entrée quitte `__magic__` mais reste dans `__all__` et dans chaque dossier de filtre. Un dossier de release ou un dossier ne supprime jamais de contenu, quelle que soit cette valeur — Sonarr supprime le dossier de travail après chaque import. Supprimer une vidéo ou une entrée à l'intérieur d'une archive supprime aussi toute sa release, dès que plus rien sous `__magic__` n'en utilise une partie. |
| `magic.sidecar_max_mb` | int | `32` | Le plus gros fichier unique qu'un client peut `PUT` dans `__magic__`. Au-delà, l'écriture est refusée avec **413**. |
| `magic.sidecar_budget_mb` | int | `2048` | La taille maximale que peut atteindre l'ensemble de l'arborescence des sidecars. Au-delà, une écriture est refusée avec **507 Insufficient Storage**, ce que le 413 ne dit pas : supprimer quelque chose fait réussir la même requête. Le total est mesuré en parcourant l'arborescence au démarrage, pour qu'un redémarrage ne rende pas l'espace disponible à une arborescence déjà pleine, et de nouveau avant tout refus. C'est le même dossier `data/local` dans lequel écrit le montage de zurg, donc un fichier supprimé là en contournant zurg ne doit plus être compté. Zéro ou une valeur négative prend la valeur par défaut ; il n'y a aucun moyen de demander l'absence de plafond. |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` ne s'applique pas ici, et le chemin de suppression non protégé du montage non plus. Ceux-ci couvrent les routes qui renomment et détruisent ce que le compte debrid contient ; une écriture sous `__magic__` n'atteint aucun compte. `mount_read_only: true` prime toujours sur tout, au niveau du noyau.

Deux choses à savoir. Les dossiers de filtre sont volontairement intacts, donc une release que tu as déplacée dans `__magic__` se trouve toujours dans `recent` et `movies` sous son nom d'origine. Pointe un serveur multimédia sur `__magic__` **ou** sur les filtres, pas sur les deux. Et tout ce qui est vraiment nouveau écrit dans le montage (un `.nfo`, un sous-titre, une affiche) atterrit dans le `data/local` propre à zurg et est fusionné dans la liste. C'est pourquoi les sidecars à côté d'une release fonctionnent tout simplement.

#### Fichiers annexes, et à quoi servent les deux limites {#sidecar-files-and-what-the-two-caps-are-for}

Le montage intégré est une union dont la première source est `data/local`. Quand un programme crée un nouveau fichier sur le montage, rclone l'écrit donc là et zurg n'est jamais sollicité. Rien ne limite cet arbre, sauf si [`union_writable: server`](#rclone-settings) inverse l'ordre de l'union. Dans ce cas, la création arrive à zurg sous forme de `PUT`. Elle est refusée en dehors de `__magic__` et soumise aux deux limites à l'intérieur.

Avec l'ordre par défaut, les deux limites concernent un autre type de client : celui qui monte `/dav` directement, sans union devant. Ces clients envoient un `PUT` à zurg, et zurg écrit le corps dans `data/local/__magic__/<path>`, le dossier même que sert l'union. Les deux vues affichent ainsi un seul dossier et non deux. Sans borne, cela ferait un stockage de fichiers généraliste accessible via WebDAV. C'est exactement ce que `sidecar_max_mb` et `sidecar_budget_mb` sont là pour empêcher.

Deux règles découlent de ce qu'est `__magic__`, et les deux sont des refus qu'un client peut voir :

- **Le miroir appartient à la bibliothèque.** `__magic__/__all__` et les dossiers de releases directement à l'intérieur sont calculés. Un `MOVE`, `MKCOL` ou `DELETE` visant l'un d'eux renvoie donc **403** : une ligne là serait une seconde adresse pour une release qui en a déjà une. Plus profondément, il y a le dossier propre à chaque release, où une écriture est aussi ordinaire qu'ailleurs. C'est là qu'un \*arr place le `.nfo` à côté d'un fichier qu'il a importé.
- **Rien de ce que la bibliothèque répond ne peut être écrasé.** Un dossier de release, une entrée de l'un d'eux, et un chemin sur lequel un move a placé quelque chose sont tous générés depuis la bibliothèque. Un `PUT` ou un `MOVE` d'un vrai fichier par-dessus l'un de ceux-là renvoie donc **403**. Cela vaut aussi pour un nom à l'intérieur d'un dossier de release que la release n'a pas : le listing du dossier est celui de la release, donc un fichier posé parmi ses entrées ne serait listé par personne.
- **Un placement ne détruit jamais un vrai fichier.** Déplacer quelque chose que la bibliothèque détient vers un chemin occupé par un sidecar est refusé plutôt qu'écrasé, même avec `Overwrite: T`. Il en va de même pour un dossier de vrais fichiers déplacé dans l'autre sens : il ne peut pas être renommé vers un chemin que la bibliothèque sert, sinon ses fichiers se retrouveraient dans un dossier qui liste la release et rien d'autre.

Un `DELETE` sur un sidecar le supprime vraiment. C'est le seul endroit de `__magic__` où une suppression n'est pas un marqueur de suppression (tombstone). Un tombstone masque une entrée que la bibliothèque détient ailleurs, alors que les octets d'un sidecar vivent dans `data/local` et nulle part ailleurs.

#### La page `__magic__` {#the-__magic__-page}

Le tableau de bord a sa propre page pour l'espace de noms, à `/magic/`, liée depuis les liens rapides du tableau de bord dès que `__magic__` est configuré ou servi. C'est là que la table est visible, et c'est le seul endroit où deux de ses états sont accessibles.

Elle indique combien de lignes sont stockées (placements, pierres tombales et répertoires, comptés séparément), ce que le journal et le snapshot occupent sur le disque, quelle part de `sidecar_budget_mb` utilise l'arborescence des sidecars, et la taille de l'ensemble de `data/local`. Ce dernier chiffre est celui à surveiller : un client qui copie au lieu de déplacer y écrit les octets, donc un `data/local` qui grimpe vers les gigaoctets signifie qu'il se passe quelque chose à l'import dans le mauvais sens. Les lignes sont regroupées par release. Une table très volumineuse est tronquée sur la page, et la page indique de combien. Les compteurs au-dessus portent toujours sur la table entière.

La liste des lignes stockées affiche les mille premières lignes. Or un \*arr laisse une pierre tombale à chaque import, donc sur une bibliothèque bien rangée, la plupart des lignes se trouvent au-delà de ce point. Une zone de recherche sur les pages des lignes stockées et orphelines trouve une release par son nom, par un chemin sur le montage ou par son hash, et liste toutes les lignes stockées à son sujet avec leurs boutons. `data/magic.json` ne permet pas de contourner cela : zurg le réécrit à partir de la mémoire quand il s'arrête, donc une ligne supprimée à la main pendant que zurg tourne réapparaît.

Trois boutons, qui passent tous par la même opération : une ligne cesse d'exister.

- **Reset** un placement, et le fichier ou le dossier revient là où la bibliothèque le place.
- **Unhide** une pierre tombale, et l'entrée est de nouveau listée dans `__magic__`. Rien n'a été détruit pour la cacher. Une release dans `__all__` qui n'apparaît jamais dans `__magic__/__all__`, même après l'avoir supprimée puis rajoutée, a une pierre tombale de release : les lignes sont indexées sur son hash, que un ajout ne change pas. Cherchez-la et faites Unhide sur cette ligne.
- **Delete** une ligne **orpheline**, c'est-à-dire dont la release, ou le fichier qu'elle contient, n'est plus dans la bibliothèque. Une telle ligne ne résout vers rien, elle ne peut donc être ni listée, ni déplacée, ni supprimée via le montage. Elle est conservée plutôt qu'effacée, car une réparation qui restaure la release restaure aussi l'endroit où vous l'aviez mise. Jusqu'à cette page, il n'existait aucun moyen de les nettoyer ; **Clear all dangling rows** les balaie toutes d'un coup.

Les sidecars sont listés aussi, et ceux que **plus rien ne justifie** sont affichés à part et comptés. Ce sont l'équivalent des lignes orphelines pour les sidecars : un `.nfo` ou une affiche écrits à côté d'une release qui a quitté la bibliothèque, ou à l'intérieur d'un dossier dont le placement a été oublié. Ils restent servis, car un vrai fichier est la dernière chose vers laquelle un chemin `__magic__` se résout, et plus rien au-dessus ne revendique le nom. Seule la raison de leur présence a donc disparu. zurg ne supprime jamais de tels fichiers : un fichier laissé à côté d'une release supprimée vous appartient toujours, et une réparation qui fait revenir la release rattache à nouveau le dossier. Un répertoire que vous avez créé vous-même pour des sidecars, via le montage et non via zurg, s'affiche de la même façon ici, car cela ne laisse aucune ligne non plus.

Supprimer un sidecar depuis la page efface réellement le fichier, de la même façon qu'un `DELETE` passé par le montage. Chaque bouton modifie ce que le montage a mis en cache pour les chemins concernés, car le montage conserve une liste de répertoire pendant douze heures, avec le polling désactivé.

Si le point de terminaison SABnzbd est activé, la page liste aussi les jobs qui lui ont été transmis : l'identifiant sous lequel le client les connaît, leur catégorie, si la release est déjà arrivée dans la bibliothèque, et le dossier à importer une fois qu'elle y est. Sonarr et Radarr suppriment leurs propres jobs. Un job Failed ou Stuck que ni l'un ni l'autre ne supprimera jamais peut être vidé depuis la page. C'est le cas lorsque zurg n'est plus leur client de téléchargement. Voir [sabnzbd.md](../guides/sonarr-radarr.md).

Les blocs `magic:` et `sabnzbd:` sont modifiables en entier depuis la [page de configuration](#sabnzbd-the-download-client-sonarr-and-radarr-see), et tous deux affichent **Restart Required**, ce qui est à prendre au pied de la lettre : les routes qui servent `__magic__` et le point de terminaison SABnzbd ne sont enregistrées qu'une fois, au démarrage, à partir de ces valeurs. Activer l'un ou l'autre écrit la valeur dans `config.yml` sans rien changer à l'exécution qui a répondu. La page `__magic__` le signale d'ailleurs, plutôt que d'afficher un espace de noms vide.

### `sabnzbd`, le client de téléchargement que voient Sonarr et Radarr {#sabnzbd-the-download-client-sonarr-and-radarr-see}

zurg peut répondre à Sonarr et Radarr comme s'il était un SABnzbd. Ils lui envoient un NZB, il écrit le fichier dans `nzbs/` pour le backend Usenet, et une fois la release dans la bibliothèque, le job affiche **Completed** avec un dossier de job sous `__magic__/__all__` d'où importer. Rien n'est téléchargé pour l'importation : le \*arr renomme le fichier dans le mount, ce qui correspond à une ligne de la table `__magic__`.

Il faut les deux parties pour que ce soit utile : un provider `nzb`, ou un `torbox_nzb`, pour prendre le NZB, et `magic.enabled` pour disposer d'un endroit où importer. Il reste désactivé tant qu'on ne le demande pas. La configuration complète, y compris ce qu'il faut mettre dans le \*arr, se trouve dans [docs/sabnzbd.md](../guides/sonarr-radarr.md).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sabnzbd.enabled` | bool | `false` | Enregistre l'endpoint sur `/api` et `/sabnzbd/api`. Tant que cette option est désactivée, aucune de ces routes n'existe. |
| `sabnzbd.api_key` | string | généré | Le seul verrou de l'endpoint. Sonarr et Radarr n'envoient aucune authentification basique, donc ces routes se trouvent en dehors de celle-ci et c'est la clé qui en tient lieu. Si le bloc est activé et que la valeur est vide, zurg en génère une, la conserve dans `data/sabnzbd-apikey` pour qu'elle survive à un redémarrage, et la journalise une seule fois au démarrage. |
| `sabnzbd.categories` | list | `[tv, movies]` | Les catégories signalées aux clients. Toutes pointent vers le même répertoire : cette option sert seulement à éviter qu'un client affiche un avertissement sur une catégorie introuvable. Ajoutez celles que vous avez configurées dans le \*arr. `*` est toujours signalée également. |
| `sabnzbd.history_limit` | int | `60` | Le nombre d'entrées d'historique que Sonarr et Radarr lisent. zurg conserve au-delà de cette limite les jobs terminés dans la file d'attente jusqu'à ce qu'une place se libère, ce qui arrive lorsque le client en supprime un ou lorsqu'un job est resté dix minutes sans être supprimé alors que d'autres jobs attendent. Alignez cette valeur sur `DownloadClientHistoryLimit` du client si vous l'avez augmentée. `0` conserve la valeur par défaut de 60. |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__/__all__` | Le répertoire de téléchargements terminés signalé aux clients. Il doit correspondre au chemin que **le \*arr** voit, qui n'est pas forcément celui de zurg lorsque le \*arr tourne dans un conteneur qui monte la bibliothèque ailleurs. Il doit aussi se trouver sur le même volume que les dossiers racines, sinon chaque import sera une copie. Voir [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

La clé API est la seule authentification, donc traitez cet endpoint comme le reste du port de zurg : sur un réseau de confiance, ou derrière quelque chose qui l'est. L'authentification basique ne peut pas être utilisée ici : les clients ne l'envoient jamais, et une 401 est présentée à l'utilisateur comme "unable to connect" plutôt que comme un échec d'authentification.

### `qbittorrent`, le client de téléchargement torrent que voient Sonarr et Radarr {#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see}

zurg peut répondre à Sonarr et Radarr comme s'il était un qBittorrent. Ils lui envoient un magnet ou un `.torrent`, et zurg ajoute le info hash à un compte debrid. Une fois la release dans la bibliothèque, le torrent passe à **finished** avec un dossier sous `__magic__/__all__` à partir duquel importer. Rien n'est téléchargé pour l'import. Le \*arr renomme le fichier à l'intérieur du mount, ce qui crée une ligne dans la table `__magic__`.

Deux éléments le rendent utile. Un compte capable d'ajouter des torrents lit le magnet, et `magic.enabled` donne au \*arr un endroit où importer. Cette option reste désactivée tant qu'on ne la demande pas. La configuration complète, y compris ce qu'il faut mettre dans le \*arr, se trouve dans [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `qbittorrent.enabled` | bool | `false` | Enregistre le point d'accès sur `/api/v2` et `/qbittorrent/api/v2`. Tant que cette option est désactivée, aucune de ces routes n'existe. |
| `qbittorrent.api_key` | string | généré | Le seul verrou du point d'accès. Les clients l'envoient comme jeton bearer lorsque leur champ **API Key** est renseigné, et l'utilisent comme mot de passe sur `auth/login` lorsqu'il ne l'est pas. Si le bloc est activé et que la valeur est vide, zurg en génère une, la conserve dans `data/qbittorrent-apikey` pour qu'elle survive à un redémarrage, et la consigne une fois au démarrage. |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | Les catégories signalées aux clients, soit les deux que les *arr proposent par défaut. Chacune mène au même dossier : cette option sert uniquement à éviter qu'un client signale une catégorie qu'il ne trouve pas. |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__/__all__` | Le save path signalé aux clients, et le parent de chaque dossier d'où ils importent. Il doit correspondre au chemin **vu par le \*arr**, qui n'est pas celui de zurg lorsque le \*arr tourne dans un conteneur qui monte la bibliothèque ailleurs. Il doit se trouver sur le même volume que les root folders, sinon chaque import sera une copie ; voir [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders). Réglez `sabnzbd.complete_dir` sur la même valeur si vous faites tourner les deux points d'accès. |
| `qbittorrent.download_timeout_mins` | int | `15` | Durée pendant laquelle une grab peut rester sans progression (aucun changement d'étape et aucune hausse de la progression) avant que ce compte soit abandonné et que le suivant acceptant les torrents soit essayé. `0` signifie cache uniquement : une grab n'est acceptée que sur un compte qui détient déjà le contenu, et refusée lors de l'ajout sinon, ce qui est le seul refus sur lequel Sonarr et Radarr réagissent. Un nombre négatif n'abandonne jamais. Voir [Délais et mode cache uniquement](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode). |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

Quinze minutes est une valeur mesurée, pas un choix. AllDebrid place un job sain dans sa propre file d'attente, avec tous les compteurs à zéro, avant de transférer le moindre octet. Sur deux essais, les jobs y sont restés 580 et 622 secondes. Les captures se trouvent dans [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md).

Le compte vers lequel part une grab est déterminé par [`add_torrents`](#accounts) et par l'ordre de la liste `providers:`. Une grab qui a expiré, ou que un compte a abandonnée, est supprimée de ce compte avant que le suivant soit essayé. Seule une instance que zurg a lui-même ajoutée pour cette grab, et qui n'a jamais abouti, peut être candidate. Aucune autre requête traitée par ce point d'accès ne supprime quoi que ce soit d'un compte debrid.

La clé API constitue à elle seule toute l'authentification. Traitez ce point d'accès comme le reste du port de zurg. Placez-le sur un réseau de confiance, ou derrière quelque chose qui l'est. L'authentification basic ne peut pas être utilisée avec lui. Les clients ne l'envoient jamais, et ils considèrent une réponse 401 comme un échec d'authentification définitif, qu'ils ne retentent jamais.

### L'addon `stremio` {#the-stremio-addon}

zurg peut être un addon Stremio qui cherche dans tes propres indexeurs Newznab et lit via le backend Usenet. Il te faut un compte NZB, `nzb` ou [`torbox_nzb`](../providers/torbox-nzb.md), et au moins un indexeur. Avec `torbox_nzb`, une release que TorBox a déjà démarre dans le délai d'attente de l'addon si aucune autre publication NZB n'est en attente. Une release non cachée doit d'abord être terminée sur TorBox, ce qui prend plus longtemps que ce qu'un lecteur attend. L'addon reste désactivé tant qu'on ne le demande pas. L'installation et ce que fait une lecture sont décrits dans [stremio.md](../guides/stremio.md).

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `stremio.enabled` | bool | `false` | Enregistre les routes de l'addon sous `/stremio/`. Tant que c'est désactivé, elles répondent 404. |
| `stremio.token` | string | généré | Le segment de chemin qui protège toutes les routes de l'addon. C'est toute l'autorisation. Si tu le laisses vide, zurg en génère un et le garde dans `data/stremio-token`. |
| `stremio.indexers` | list | `[]` | Points de terminaison Newznab où chercher. Chacun prend `name`, `url`, `api_key` et un `api_path` optionnel. |
| `stremio.max_results` | int | `10` | Combien de releases chaque résolution garde après le classement. La limite s'applique par résolution. Chaque palier garde une répartition allant de sa plus grosse release à la plus petite. `0` prend la valeur par défaut. |
| `stremio.search_limit` | int | `100` | Combien de releases chaque indexeur doit renvoyer par recherche. Toutes les autres limites choisissent parmi ce qui a été demandé, donc c'est le plafond de toute la réponse. `0` prend la valeur par défaut. |
| `stremio.max_size_gb` | int | `0` | Écarte les releases plus grosses que cette valeur avant le classement, pour un lecteur qui ne supporte pas les remux. `0`, la valeur par défaut, n'en écarte aucune. Les releases sans taille indiquée sont gardées. |
| `stremio.cache_hours` | int | `24` | Durée pendant laquelle une réponse complète d'au moins cinq résultats est servie depuis `data/stremio-cache` avant de redemander aux indexeurs. Les réponses plus maigres sont gardées moins longtemps. Une réponse vide n'est jamais gardée. `0` prend la valeur par défaut. |

### Analyse des médias {#media-analysis}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | Quand la valeur est true, zurg lance automatiquement ffprobe sur chaque torrent nouvellement ajouté pour extraire les métadonnées (résolution, codecs, durée, pistes audio et sous-titres). Ces métadonnées alimentent les filtres de répertoires basés sur les tags, comme `zurg_4k`, `zurg_aud_eng` et les paliers de durée. Désactive-la si tu n'utilises pas de filtres par tags ou si tu veux réduire l'utilisation du CPU sur les nouveaux ajouts. |
| `ffprobe_binary` | string | `"ffprobe"` | Chemin vers l'exécutable ffprobe. Nécessaire uniquement si ffprobe n'est pas dans le PATH de ton système. Utilisé pour l'analyse des médias. |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. Santé et réparations (automatisation) {#4-health--repairs-automation}

La section « Réglez et oubliez ». Elle permet de contrôler la façon dont zurg maintient votre bibliothèque en bon état, en détectant et en réparant automatiquement les torrents défectueux.

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `enable_repair` | bool | `true` | Active la réparation automatique des torrents. Non défini signifie activé. Lorsqu'un torrent devient indisponible (par exemple, supprimé du cache RD), zurg tente de trouver un remplaçant et de l'ajouter. Sur AllDebrid, il redémarre aussi un magnet qui a échoué pour une raison qu'une seconde tentative peut corriger, comme l'absence de pairs ou une erreur de tracker, au lieu de le laisser en échec. **Important :** une seule instance de zurg doit avoir la réparation activée pour éviter les conflits. Si cette option et `delete_error_torrents` sont toutes deux désactivées, zurg laisse les torrents en échec exactement tels quels sur le compte et se contente de les consigner. |
| `repair_every_mins` | int | `60` | Fréquence (en minutes) à laquelle zurg analyse la recherche de torrents défectueux à réparer. Des valeurs plus basses détectent les problèmes plus vite, mais augmentent l'utilisation de l'API. |
| `repair_timeout_mins` | int | `30` | Durée maximale (en minutes) d'attente de la fin d'une opération de réparation. Si une réparation dure plus longtemps, le torrent est marqué comme défectueux et ignoré jusqu'au prochain cycle de réparation. |
| `stalled_download_mins` | int | `10` | Durée minimale (en minutes) avant qu'un torrent en cours de téléchargement soit considéré comme bloqué. Le seuil réel est `max(GB_downloaded, stalled_download_mins)`, donc les gros téléchargements obtiennent automatiquement plus de temps. Augmentez cette valeur pour les torrents lents ou peu seedés (par exemple, sur des trackers publics) qui ont besoin de plus de temps pour se terminer. |
| `restrict_repair_to_cached` | bool | `false` | Si true, zurg utilise uniquement les torrents déjà en cache sur Real-Debrid pour les réparations. Cela rend les réparations plus rapides (pas d'attente de téléchargement), mais elles peuvent échouer si aucune alternative en cache n'existe. Si false, zurg peut ajouter des torrents non cachés qui doivent être téléchargés. |
| `only_full_torrent_repair` | bool | `false` | Si true, la réparation réinsère le torrent entier avec sa sélection de fichiers d'origine, ou abandonne. Si cette première étape échoue, le torrent est immédiatement marqué défectueux, en sautant les stratégies par archive et par fichier qui suivraient normalement. |
| `check_for_changes_every_secs` | int | `15` | Fréquence (en secondes) à laquelle zurg interroge Real-Debrid pour détecter les changements de bibliothèque (nouveaux torrents, torrents supprimés, changements d'état). Des valeurs plus basses signifient des mises à jour plus rapides dans votre serveur multimédia, mais davantage d'appels API. |
| `library_resync_every_mins` | int | `10` | Fréquence à laquelle la vérification des changements est reconstruite à partir d'une liste complète au lieu d'une sonde légère. C'est un filet de sécurité qui attrape les écarts qu'une sonde peut manquer. Ce n'est pas la fréquence d'interrogation de zurg. Real-Debrid suit son propre chemin et ignore cette option. |
| `library_detail` | string | `resident` | `resident` garde les détails des fichiers en mémoire. `lazy` libère les détails inactifs. `auto` ne libère les détails inactifs que sous une pression mémoire soutenue. Tous les fournisseurs partagent cette politique à l'échelle de l'instance. Redémarrage requis. Voir [Détail de la bibliothèque](#library-detail). |
| `library_detail_idle_secs` | int | `300` | Durée minimale sans lecture de détail avant que `lazy` ou `auto` puisse libérer une table. Le balayage s'effectue toutes les 30 secondes. Ignoré par `resident` ; les valeurs nulles ou invalides utilisent 300. Redémarrage requis. |
| `downloads_every_mins` | int | `720` | Fréquence (en minutes) à laquelle zurg récupère à nouveau vos téléchargements RD (liens débridés, liens du file locker) et les monte. Il s'agit de téléchargements non-torrent depuis RD. |
| `delete_error_torrents` | bool | `false` | Lorsque true, supprime automatiquement de RD les torrents en état d'erreur (par exemple, les torrents morts qui ne peuvent pas être téléchargés). Garde votre bibliothèque RD propre, mais le torrent est supprimé définitivement. Sur AllDebrid, un magnet en échec qu'une seconde tentative peut corriger est redémarré au lieu d'être supprimé, même si la réparation est désactivée, et n'est supprimé que si ce redémarrage n'aide pas. |
| `on_library_update` | string | `""` | Une commande shell exécutée chaque fois que zurg détecte des changements de bibliothèque. Le chemin de chaque répertoire modifié est passé en argument. Souvent utilisée pour déclencher des analyses de bibliothèque Plex/Jellyfin sur des dossiers précis, afin d'accélérer les mises à jour. |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
library_detail: resident
library_detail_idle_secs: 300
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

### Réparer sur plusieurs comptes {#repairing-across-accounts}

Chaque autre stratégie de réparation ré-ajoute une release au compte d'où elle vient, ce qui est la bonne forme tant que ce compte peut encore fournir le contenu. C'est la mauvaise forme dans un seul cas.

Les services gardent des caches indépendants. Une release que Real-Debrid a purgée, ou qu'il refuse sur le nom de fichier seul, peut très bien être en cache sur AllDebrid en ce moment, sous le même info hash. La release n'a rien de mauvais. Seul le compte pose problème.

Donc, quand une release a été abandonnée par tous les comptes qui la détiennent, zurg la propose aux comptes configurés qui ne la détiennent pas, dans l'ordre où ils apparaissent dans votre bloc `providers`. Le premier qui l'a déjà en cache la prend, zurg liste ce compte, et la release obtient une seconde copie comme n'importe quelle release multi-comptes : ses propres identifiants de fichiers, ses propres liens, et basculement des lectures entre les deux. Le verdict sur l'entrée s'efface de lui-même dès qu'une copie réparable existe.

Il n'y a aucun réglage. Configurer un second compte, c'est déjà la décision, et zurg le liste, sert depuis lui et bascule les lectures vers lui. Lui demander une release que le premier compte ne peut pas produire relève du même mécanisme. Cela suit `enable_repair` comme toute autre réparation.

Le bouton de réparation d'une release fait aussi cela, et dans le bon ordre : il réessaie d'abord le compte qui détient la release, comme il l'a toujours fait, et ne propose la release ailleurs que si cette tentative échoue. C'est le seul chemin qui fonctionne avec le balayage de réparation totalement désactivé.

Ce qui empêche que cela devienne une boucle d'ajouts, c'est la forme de la proposition plutôt qu'un interrupteur :

- **Un compte ne reçoit jamais que du contenu qu'il détient déjà.** La proposition est un ajout qui est retiré et supprimé à nouveau, sauf si le compte la termine dans les quinze secondes. Un compte qui devrait aller chercher la release sur le swarm est laissé exactement dans l'état où il était, sans avoir consommé de quota de transfert. C'est une réparation, jamais un nouveau téléchargement. `restrict_repair_to_cached` ne contrôle pas cela et n'est jamais lu ici : cette clé concerne la réparation de sa propre copie par un compte, et ce chemin ne fonctionne qu'en cache, quelle que soit sa valeur.
- **Seule une release que rien ne peut servir.** Une release qui fonctionne n'est jamais copiée ailleurs, et il en va de même pour une release que la réparation n'a pas encore abandonnée.
- **Un compte qui refuse est sollicité de moins en moins.** L'attente après un refus commence à un jour et double à chaque refus supplémentaire, jusqu'à environ quinze jours. Une release simplement absente du cache cette semaine sera retrouvée en quelques jours ; une release disparue pour de bon finit par ne plus faire l'objet qu'une question tous les quinze jours. Sans cette dégressivité, l'option toujours active signifierait un ajout quotidien pour chaque release morte sur chaque compte, indéfiniment.
- **Au maximum dix releases par balayage**, donc le premier balayage après l'ajout d'un second compte traite l'arriéré sur plusieurs heures plutôt que d'un seul coup.

Un compte qui détient déjà une copie de la release ne reçoit jamais une seconde instance, quelle que soit la gravité du problème de la copie qu'il détient : ce compte relève des stratégies de réparation elles-mêmes. Sur Real-Debrid, un ajout en double ne télécharge jamais rien. Les releases dont la clé n'est pas un info hash bittorrent, c'est-à-dire la manière dont le backend Usenet identifie les siennes, ne sont jamais proposées à qui que ce soit.

C'est le seul endroit où zurg ajoute du contenu à un compte dont le contenu expire sans qu'on le lui demande. La réparation ne ré-ajoute jamais une release sur un tel compte selon un minuteur, car re-télécharger un contenu que le service a retiré délibérément est précisément le comportement que ces services qualifient d'abus. Une proposition en cache n'est pas cela : rien n'est téléchargé, aucun quota n'est consommé, et le contenu réclamé est déjà dans le cache du service parce qu'un autre utilisateur l'y a placé.

### Détail de la bibliothèque {#library-detail}

**`library_detail: resident` reste la valeur par défaut.** Choisissez un mode et une durée d'inactivité
dans la page de configuration du tableau de bord ou dans `config.yml`. Les deux réglages prennent effet après un redémarrage de zurg ; les enregistrer ne fait pas basculer partiellement une bibliothèque en cours d'exécution. La politique s'applique à tous les fournisseurs de l'instance.

| Mode | Comportement | Compromis |
|---|---|---|
| `resident` | Garde en mémoire les détails de fichiers de chaque release. | Accès prévisible sans rechargement des détails ; mémoire retenue la plus élevée. |
| `lazy` | Libère les détails après `library_detail_idle_secs` sans utilisation. | Réduit la mémoire au repos même quand la RAM est abondante ; accéder à des détails froids entraîne un rechargement. |
| `auto` | Garde les détails tant que la mémoire est abondante et libère les tables inactives les plus anciennes en cas de pression soutenue. | S'adapte aux conditions d'exécution ; ajoute une surveillance de la pression et une latence de rechargement moins prévisible. |

Les noms, tailles, renommages et visibilité restent disponibles pour les listes dans tous les modes. Ouvrir ou réparer un fichier reconstruit les détails libérés à la demande. `auto` ne recharge pas la bibliothèque par anticipation quand la pression retombe : les détails reviennent au fur et à mesure qu'ils sont utilisés et restent en mémoire jusqu'à ce que la pression et la fenêtre d'inactivité permettent à nouveau leur libération.

#### Détection automatique de la pression {#automatic-pressure-detection}

`auto` vérifie la mémoire toutes les 30 secondes. Deux relevés au moins à 30 secondes d'intervalle, à **90 %** ou plus d'un budget mesuré, lancent l'éviction, par lots d'au plus **128 tables inactives** par passage. L'éviction continue jusqu'à ce que l'utilisation tombe à **80 %** ou moins, puis fait une pause d'au moins une minute avant d'envisager un nouvel épisode. Les pics brefs ne déclenchent pas l'éviction. La fenêtre d'inactivité configurée s'applique toujours.

C'est la mesure la plus serrée disponible qui guide la décision :

- **Mémoire de l'hôte :** mémoire totale moins mémoire disponible, y compris l'estimation par le système d'exploitation des caches récupérables. Un cache de système de fichiers plein ne signifie pas à lui seul un manque de RAM.
- **Conteneurs Linux et limites de services :** `memory.max` et `memory.high` de cgroup v2, ou `memory.limit_in_bytes` de v1, avec l'utilisation propre de chaque ancêtre visible. Le cache de fichiers froid est déduit. Les limites du conteneur sont relues à l'exécution ; les espaces de noms cgroup privés peuvent masquer des limites au-dessus de la racine visible.
- **Un budget d'exécution explicite :** un `memory_limit_mb` positif, en MiB, est comparé à la mémoire gérée par Go. `GOMEMLIMIT`, s'il est défini, a la priorité ; `GOMEMLIMIT=off` désactive ce signal précis. La pression de l'hôte et du conteneur s'applique toujours. Le plafond automatique de Go, dérivé des caches Usenet, est ignoré, car il augmente avec le tas actif et ne mesure pas la RAM disponible.

Aucun budget supplémentaire n'est nécessaire pour activer `auto` :

```yaml
library_detail: auto
library_detail_idle_secs: 300
# Optional explicit Go runtime budget, also used by the collector:
# memory_limit_mb: 1024
```

Sans mesure utilisable, l'éviction automatique est mise en pause. Il s'agit d'une optimisation progressive de la mémoire, **et non d'un plafond strict** : les fichiers actifs, les modifications non enregistrées, les instantanés de récupération et les autres caches peuvent dominer la mémoire, et des pics d'allocation soudains peuvent dépasser le rythme du balayage. `memory_limit_mb` reste une limite souple pour le ramasse-miettes ; la définir en dessous des données actives peut provoquer un ramasse-miettes excessif.

#### Intégrité des données et coût {#data-integrity-and-cost}

L'éviction conserve un **instantané de récupération compressé** en plus du dump `data/*.zurgtorrent` existant. Un rechargement depuis le disque doit correspondre à cet instantané. Si le dump est manquant, endommagé ou remplacé, zurg restaure l'instantané, garde la release en mémoire, puis réessaie d'enregistrer les données récupérées. `auto` réessaie aussi les tables modifiées et inactives une fois la pression terminée, avec une passe d'enregistrement séparée et bornée. Les écritures de fichiers et les changements d'état rétablissent immédiatement la propriété, y compris les écritures passant par un pointeur détenu par un flux à travers une éviction. Les enregistrements échoués laissent les modifications en mémoire et marquées comme modifiées ; les écritures qui se chevauchent ne sont pas validées par un enregistrement plus ancien. Un enregistrement réussi reste nécessaire pour que les modifications survivent à une fermeture du processus.

Mesuré sur un Mac Apple Silicon avec Go 1.26.4, à partir de 500 releases par forme, via les chemins de conversion et de persistance, instantané de récupération inclus :

| Forme | Résident (octets/entrée) | Lazy (octets/entrée) | Réduction | Reconstruction moyenne |
|---|---:|---:|---:|---:|
| Real-Debrid, film, 3 fichiers | 3,662 | 2,845 | 22% | 88 µs |
| Real-Debrid, pack de saison, 24 fichiers | 15,670 | 7,366 | 53% | 371 µs |
| TorBox, 2 fichiers | 3,019 | 2,680 | 11% | 56 µs |
| AllDebrid, 1 fichier | 2,580 | 2,516 | 2% | 55 µs |
| Ensemble RAR, 7 volumes | 5,343 | 3,303 | 38% | 109 µs |

Ces chiffres sont la mémoire de tas retenue par release, et non la RSS totale du processus. Les reconstructions lisent des fichiers locaux écrits récemment ; un stockage distant ou froid peut prendre plus de temps. Choisissez `lazy` pour une récupération constante de la mémoire des entrées inactives, ou `auto` pour ne récupérer de la mémoire que sous pression. Gardez `resident` quand un accès prévisible compte plus que la RAM. Les petites releases économisent peu, et l'instantané de récupération consomme volontairement de la mémoire pour protéger les données. Ces mesures décrivent les entrées évincées en `lazy` comme en `auto` ; le mode automatique peut conserver plus d'entrées à un moment donné.

## 5. Réseau et connectivité (technique) {#5-network--connectivity-technical}

Paramètres d'infrastructure qui contrôlent la façon dont zurg se lie au réseau, s'authentifie et se connecte.

### Liaison du serveur {#server-binding}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `host` | string | `"[::]"` | L'interface réseau à laquelle se lier. `[::]` écoute sur toutes les interfaces (IPv4 et IPv6). Utilise `0.0.0.0` pour IPv4 uniquement, ou une IP précise pour limiter l'accès à une seule interface. |
| `port` | string | `"9999"` | Le port sur lequel zurg écoute. La variable d'environnement `PORT`, si elle est définie, remplace cette valeur, ce qui est pratique pour les déploiements en conteneur. |

```yaml
host: "[::]"
port: 9999
```

### Connexions préchauffées {#warm-connections}

Ouvrir une connexion vers un service debrid coûte cher, alors que l'utiliser ne coûte presque rien. Mesuré depuis un hôte en service le 2026-08-29, une nouvelle connexion vers un hôte de téléchargement Real-Debrid coûte un aller-retour TCP, puis 68 à 85 ms de négociation TLS avant qu'un seul octet du fichier ait été demandé. Et le transport HTTP de zurg n'ouvre rien tant qu'une lecture ne le demande pas, puis ferme une connexion inutilisée au bout de 90 secondes. Sur une bibliothèque peu sollicitée, la lecture qui suit une période calme paie ce coût sur le chemin du spectateur.

Un plancher « chaud » sort ce coût de ce chemin : chaque compte garde un nombre défini de connexions ouvertes et négociées à l'avance, pour que le transport en ait déjà une sous la main quand une lecture arrive.

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `warm_connections` | int | *(non défini)* | Le plancher pour chaque compte qui n'en définit pas un propre. Non défini laisse chaque backend à sa valeur par défaut : 1 par hôte pour un compte debrid, 2 par compte pour un compte Usenet. `-1` désactive le préchauffage partout. La valeur `warm_connections` propre à un compte l'emporte toujours, y compris sur un `-1` global. |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**Le gain dépend de l'hôte, et pour les services debrid il est plus faible qu'on ne le pense.** Une connexion qui n'envoie rien est la première que ces services coupent, et ils le font vite. Mesuré depuis un hôte en service le 2026-08-29, en gardant une connexion silencieuse ouverte jusqu'à ce qu'elle soit coupée :

| Hôte | Connexion silencieuse | Après avoir servi une requête |
|---|---|---|
| un hôte de téléchargement Real-Debrid | fermée après 30s | fermée immédiatement |
| `api.alldebrid.com` | fermée après 15s | toujours ouverte à 4 min |
| `api.torbox.app` | fermée après 15s | toujours ouverte à 4 min |
| `api.real-debrid.com` | fermée après 4s | fermée après 5s |

Un plancher ne vaut donc la peine que pour un hôte de téléchargement, et guère plus. L'API de Real-Debrid ne peut pas du tout être préchauffée : aucun plancher ne devance une coupure au bout de quatre secondes sans générer du trafic pour garder la connexion en vie, ce que zurg ne fera pas. Plutôt que de le supposer, **le plancher mesure lui-même** : il ferme ses propres connexions au bout de 15 secondes et vérifie si chacune était encore vivante à ce moment-là. Un hôte qui les coupe systématiquement avant qu'une lecture puisse s'en servir est abandonné, et ses lectures ouvrent de nouvelles connexions comme avant. Rien n'a besoin d'être configuré pour cela, et un plancher inutilisé dans une bibliothèque calme n'est pas confondu avec un hôte qui coupe.

Deux autres points à connaître avant de l'augmenter :

- **Le plancher d'un compte debrid est par hôte, celui d'un compte Usenet est par compte.** Un compte debrid passe par de nombreux hôtes : un nom d'hôte d'API, et un hôte de livraison par lien. On ne sait lesquels avant qu'un lien ait été généré. Les hôtes maintenus chauds sont donc ceux que le compte a réellement utilisés. Au maximum 16 sont gardés à la fois, et un hôte inutilisé pendant 10 minutes est retiré. Un compte Usenet correspond à un seul hôte, indiqué dans la configuration, et conserve sa session aussi longtemps que son abonnement le permet. C'est pourquoi son plancher est celui qui rapporte de façon fiable. Voir [Usenet](../guides/usenet.md).
- **Les connexions préchauffées sont de vraies connexions, et elles comptent dans le plafond par hôte imposé par le fournisseur** : 32 chez Real-Debrid et AllDebrid, 20 chez TorBox. C'est pourquoi le plancher debrid est limité à 4 : à cette taille, le plafond reste pratiquement intact, alors qu'un plancher plus grand le consommerait pour des sockets qui ne transportent rien.

Le plancher est désactivé lorsque `proxy` est défini, car un proxy HTTP ou SOCKS fait que zurg se connecte au proxy plutôt qu'à l'hôte, et il n'y a rien de l'autre côté qui vaille la peine d'être gardé ouvert.

### Authentification et proxy {#authentication--proxy}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `username` | string | `""` | Nom d'utilisateur pour l'authentification HTTP basique. Lorsqu'il est défini avec `password`, toutes les requêtes vers zurg (tableau de bord, WebDAV, API) nécessitent une authentification. Laisser vide pour désactiver l'authentification. |
| `password` | string | `""` | Mot de passe pour l'authentification HTTP basique. Doit être défini en même temps que `username`. |
| `proxy` | string | `""` | Faire passer tout le trafic réseau sortant de zurg par un proxy. Prend en charge les protocoles `http://`, `https://` et `socks5://`. Utile si ton FAI bloque ou ralentit le trafic Real-Debrid. Exemple : `socks5://user:pass@host:port`. La variable d'environnement `PROXY` est utilisée lorsque cette clé est vide. |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Paramètres Rclone {#rclone-settings}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | Lorsque true, zurg gère automatiquement un montage rclone. Vous n'avez plus besoin de lancer rclone séparément : zurg démarre, surveille et redémarre le processus rclone au besoin. Le montage utilise `mount_path` comme point de montage. |
| `rclone_binary` | string | `"rclone"` | Chemin de l'exécutable rclone. Nécessaire uniquement si rclone ne se trouve pas dans votre PATH système. |
| `rclone_extra_args` | list | `[]` | Options supplémentaires de ligne de commande transmises à la commande de montage rclone. Utilisez-les pour remplacer les valeurs VFS par défaut optimisées pour les benchmarks de zurg (voir le tableau ci-dessous). Chaque entrée est une seule chaîne d'option. Les paramètres RC et les options de backend `--union-*`/`--webdav-*` sont refusés : zurg les construit lui-même, et une option de ce type prendrait le pas sur ce qu'il construit (`union_writable` ne décrirait plus le montage). |
| `mount_read_only` | bool | `false` | Lorsque true, le montage démarre avec `--read-only` de rclone, si bien que le noyau refuse une écriture avant qu'elle n'atteigne zurg. Rien d'autre ne contrôle une suppression DELETE sur le montage, donc c'est le seul moyen de la refuser — même si cela ne couvre pas les clients qui parlent directement au point de terminaison WebDAV — et cela empêche aussi une écriture accidentelle d'atterrir dans l'upstream local d'union du montage. Vous pouvez le remplacer au cas par cas avec `rclone_extra_args: ["--read-only=false"]`. |
| `rclone_cache_reclaim` | bool | `true` | Indique si zurg supprime les arborescences du cache VFS laissées par une configuration de montage précédente. rclone nomme son cache d'après le remote, et ce nom est un hachage des upstreams d'union, qui contiennent le chemin absolu de `data/local` — donc déplacer le dossier de zurg ou changer `union_writable` renomme le cache et laisse l'ancienne arborescence sans que aucune limite ne la compte ni qu'aucun nettoyeur ne la visite. Au démarrage du montage, zurg demande au rclone en cours d'exécution quelle arborescence est active et supprime les autres, en journalisant l'espace libéré ; il ne fait rien si l'arborescence active n'est pas là où rclone l'indique, et il ignore complètement ce nettoyage lorsque `rclone_extra_args` définit `--cache-dir`. Mettez-le à `false` pour conserver toutes les arborescences orphelines. Voir [Espace disque utilisé par le montage](#disk-the-mount-uses). |
| `union_writable` | string | `"local"` | Le côté de l'union du montage intégré vers lequel un fichier créé est écrit. `local`, la valeur par défaut, l'écrit directement sur l'upstream local (`data/local`) sans que zurg le voie. `server` place d'abord l'upstream WebDAV dans la liste, si bien que la création arrive jusqu'à zurg : elle est refusée hors de `__magic__`, et écrite comme fichier annexe (sidecar) plafonné en taille à l'intérieur. Une écriture refusée n'atteint jamais le disque — le cache VFS de rclone l'accepte et réessaie l'envoi selon un backoff, elle est donc bornée par le plafond du cache et visible dans `logs/rclone.log`, alors que l'ordre local aurait placé des octets sans limite dans `data/local`. Une mise en garde mesurée avec `server` : renommer un fichier annexe via le montage peut renvoyer une erreur (le fichier est visible sur les deux upstreams, donc rclone applique le déplacement à chacun) ; les déplacements de libération à l'intérieur de `__magic__` — le chemin d'import des \*arr — ne sont pas affectés. Passer à `server` ne change que l'emplacement des *new* créations et rien d'autre : ce que l'ordre local a déjà écrit dans `data/local` reste en place tant que vous ne le supprimez pas. La ligne que zurg journalise au démarrage indique le mode actif (`new files go to zurg over WebDAV (union_writable: server)`) ; c'est donc elle qu'il faut vérifier, et non la présence du chemin `data/local`, qui fait partie de l'union quel que soit l'ordre. |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
rclone_cache_reclaim: true
union_writable: "local"
```

#### Valeurs par défaut optimisées par benchmark {#benchmark-optimized-defaults}

zurg utilise des réglages VFS de rclone testés par benchmark et optimisés pour le streaming :

| Réglage | Par défaut | Pourquoi |
|---------|---------|-----|
| `--buffer-size` | 256M | Grand tampon pour un streaming fluide |
| `--vfs-read-chunk-size` | 32M | Durée de la montée en charge d'une lecture fraîche. Le premier bloc est récupéré à cette taille puis double à chaque fois. Avec 4M, une lecture depuis un offset froid passait l'essentiel de son temps en dessous du débit de la ligne. C'est une taille de requête, pas un transfert forcé : rclone arrête de télécharger dès que le lecteur s'arrête. |
| `--vfs-read-chunk-size-limit` | 512M | Plafond où s'arrête le doublement ci-dessus. Le découpage est activé par défaut, donc c'est un plafond que la montée atteint, et non quelque chose qu'une option active. |
| `--vfs-read-ahead` | 128M | Équilibre entre efficacité du tampon et de la bande passante |
| `--max-read-ahead` | 1M | Petit tampon noyau FUSE qui réduit les petites lectures. Non passé sous Windows. |
| `--vfs-read-wait` | 5ms | Critique : des valeurs plus élevées causent de forts ralentissements |
| `--vfs-cache-mode` | full | Cache complet pour de meilleures performances. Ce n'est pas toujours le bon compromis pour un lecteur qui lit le montage via un partage. Voir [Quand le cache coûte plus qu'il ne rapporte](#when-the-cache-costs-more-than-it-buys). |
| `--vfs-cache-max-size` | 256G | Plafond strict du cache VFS sur disque. Ce n'est pas une clé de configuration : remplacez-la avec `rclone_extra_args`. |
| `--vfs-cache-min-free-space` | 10G | Arrête la mise en cache avant que le disque du cache ne soit plein |
| `--vfs-cache-max-age` | 72h | Durée de conservation d'un fichier en cache non touché. « Non touché » est le mot clé, et un serveur multimédia laisse rarement un fichier non touché. Voir [Espace disque utilisé par le montage](#disk-the-mount-uses). |
| `--vfs-cache-poll-interval` | 1m | Mises à jour du cache réactives |
| `--vfs-fast-fingerprint` | on | Identifie les fichiers sans les hacher |
| `--dir-cache-time` | 12h | Les listings sont conservés pendant des heures. zurg oublie les entrées concernées via l'API RC quand la bibliothèque change, pour que les analyses du serveur multimédia restent rapides |
| `--attr-timeout` | 60s | Les fichiers de la bibliothèque sont immuables, et les changements d'état oublient explicitement les entrées concernées. Borné pour qu'une taille périmée ne survive pas à un passage d'analyse. |
| `--poll-interval` | 0 | La surveillance des changements est le travail de zurg, pas de rclone |
| `--timeout` | 5m | Délai d'inactivité IO |
| `--no-modtime` / `--no-checksum` | on | Aucun des deux n'a de sens pour une bibliothèque debrid, et les demander coûte des requêtes |
| `--async-read` | valeur par défaut de rclone (activé), non passé | zurg ne met pas ce flag sur la ligne de commande, et rclone le met à true par défaut. Le montage lit donc de façon asynchrone, et tous les chiffres de cette page ont été mesurés ainsi. Un champ de réglage prétendait autrefois le désactiver ; il se contentait d'ajouter le flag seul, ce qui définit la valeur par défaut qu'il avait déjà. Pour vraiment le désactiver : `rclone_extra_args: ["--async-read=false"]`. |
| `--low-level-retries` | 3 | Le téléchargeur VFS de rclone redémarre déjà une lecture échouée dix fois par ouverture, et chaque redémarrage est réessayé par le pacer du backend ce nombre de fois. Avec la valeur par défaut de rclone, 10, cela fait 100 requêtes pour une seule ouverture d'un fichier auquel zurg répond 503 délibérément. |
| `--retries` | 1 | Budget de la commande entière. Pour un montage qui ne se termine jamais, cela ne fait que multiplier un échec au démarrage |
| `--vfs-handle-caching` | 0, activé sur rclone 1.74+ | rclone 1.74 a commencé à garder les téléchargeurs d'un fichier actifs pendant cinq secondes après la dernière fermeture. Toucher un fichier coûte donc cinq secondes de ce que la liaison peut transporter, et non de ce qui a été lu : mesuré contre un serveur à 50 MB/s, une lecture de 1 MiB a tiré 245-250 MiB au lieu de 3-6 MiB, et un balayage de vingt fichiers est passé de 80 MiB à 4.2 GiB. Ce délai de grâce existe pour `serve nfs`, que zurg ne lance jamais. Les anciennes versions de rclone n'ont pas ce flag et refusent de démarrer sur un flag inconnu. zurg interroge donc d'abord la version du binaire et ne passe rien en dessous de 1.74. |
| `--log-level` | NOTICE | Verbosité propre à rclone, toujours passée |
| `--cache-dir` | `data/rclone-cache` | Résolu par rapport au répertoire de travail |
| `--log-file` | `logs/rclone.log` | Résolu par rapport au répertoire de travail |

`--vfs-cache-max-size`, `--vfs-cache-min-free-space`, `--low-level-retries`, `--retries`, `--vfs-handle-caching`, `--log-level`, `--cache-dir` et `--log-file` sont des constantes dans `internal/rclone/manager.go`. Toutes les autres lignes viennent de `tuneVFSOptions` dans `internal/rclone/tuning.go`, y compris `--vfs-cache-max-age` et `--vfs-cache-poll-interval`, malgré leurs noms.

### Disque utilisé par le montage {#disk-the-mount-uses}

`--vfs-cache-mode full` signifie qu'un fichier lu via le montage est téléchargé **en entier** dans `data/rclone-cache` et y reste après la fin de la lecture. Ce n'est pas un tampon temporaire qui se vide quand la vidéo s'arrête. Si on ne fait rien, le cache grossit jusqu'à `--vfs-cache-max-size`, qui vaut **256G** par défaut, et y reste.

Deux limites sont censées le borner, mais en pratique une seule fonctionne :

- `--vfs-cache-max-size` (256G) est la vraie limite. Règle-la à maximum la moitié de l'espace libre du disque sur lequel se trouve `data/`.
- `--vfs-cache-max-age` (72h) supprime un fichier que plus personne n'a touché depuis trois jours. rclone mesure cela à partir de son propre enregistrement dans `data/rclone-cache/vfsMeta/`, et non à partir de l'atime du système de fichiers, et **tout ce qui lit la bibliothèque rafraîchit cet enregistrement**. Un serveur Plex avec des tâches planifiées activées lit chaque fichier en cache pendant sa fenêtre de maintenance nocturne. Le 2026-09-09, une instance dont le cache contenait 362 fichiers avait donc un ATime de ce même matin sur chacun d'eux. Rien n'avait été supprimé depuis des mois, et rien ne le serait jamais. Ne compte donc pas sur l'expiration par âge ; compte sur le plafond de taille.

Baisse le plafond avec `rclone_extra_args` :

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

`--vfs-cache-min-free-space` (10G par défaut) arrête la mise en cache quand le disque est presque plein à ce niveau. Garde cette valeur bien au-dessus de zéro si le disque est partagé avec autre chose.

Pour vider le cache à la main, arrête d'abord zurg, puis vide les deux arborescences :

```bash
rm -rf data/rclone-cache/vfs/* data/rclone-cache/vfsMeta/*
```

Mesure-le avec `du -sh data/rclone-cache`. Les entrées partiellement téléchargées sont des fichiers creux (sparse), donc une taille qui compte les octets apparents affiche bien plus que ce que le disque contient réellement.

#### Quand le cache coûte plus qu'il ne rapporte {#when-the-cache-costs-more-than-it-buys}

`full` est le bon réglage par défaut pour un serveur multimédia sur le même hôte : il lit un fichier une seule fois, et tout ce qui suit est local. Ce n'est pas automatiquement le bon choix pour un lecteur matériel qui lit le point de montage via un partage de fichiers.

Avec `full`, une lecture doit d'abord être écrite sur le disque avant d'atteindre le lecteur, et ce qui est récupéré est le fichier entier plutôt que la partie en cours de lecture. Ajoutez un partage par-dessus, et un seul disque sert le lecteur pendant que rclone écrit encore dessus. Un lecteur Zidoo qui lisait un partage Windows saccadait à chaque titre jusqu'à ce que le cache soit désactivé, puis lisait correctement ensuite (signalé le 2026-08-30). Le mécanisme ci-dessus est la lecture la plus plausible de ce rapport, et non quelque chose qui a été mesuré ici. Considérez-le donc comme la première chose à essayer lorsqu'un client en lecture directe saccade sur un montage qu'un serveur multimédia sur le même hôte lit sans problème :

```yaml
rclone_extra_args:
  - "--vfs-cache-mode"
  - "off"
```

Ce que cela coûte est réel. Sans copie locale, un saut dans la vidéo relit depuis le fournisseur, une deuxième lecture retélécharge le fichier, et rien ne survit à un redémarrage. Cela change aussi ce que le montage accepte comme écriture. Ne touchez donc pas au réglage par défaut sur un hôte où un \*arr importe via le montage. Voir [qbittorrent.md](../guides/sonarr-radarr-torrents.md).

#### Caches orphelins après un déplacement {#caches-stranded-by-a-move}

rclone nomme son cache d'après le remote qu'il met en cache, et ce nom contient un hash de la configuration du remote. Le remote de zurg est un union dont les upstreams contiennent le chemin absolu de `data/local`, donc le nom change dès que la configuration change :

| Upstreams de l'union | Arborescence du cache |
|---|---|
| `/home/you/zurg/data/local :webdav:` | `vfs/zurg{QaSkn}` |
| `:webdav: /home/you/zurg/data/local` (`union_writable: server`) | `vfs/zurg{HdSp7}` |
| `/other/root/data/local :webdav:` (zurg déplacé) | `vfs/zurg{Psid2}` |

rclone ne prend en compte que l'arborescence qu'il utilise. Une arborescence sous un ancien nom n'est comptée dans aucun plafond, n'est visitée par aucun nettoyeur et n'est supprimée par rien. Donc déplacer le dossier de zurg, ou un disque externe qui revient sous un nouveau point de montage, laisse un cache entier derrière. Plusieurs déplacements de ce genre, et une installation avec un plafond de 256G finit par contenir plusieurs téraoctets.

zurg récupère ces arborescences au démarrage du montage : il demande à rclone en cours d'exécution quelle arborescence est active, supprime le reste et journalise ce qu'il a libéré. Il ne fait rien si l'arborescence active ne se trouve pas sur le disque à l'endroit indiqué par rclone, et il saute complètement ce nettoyage lorsque `rclone_extra_args` définit `--cache-dir`, car un dossier que tu as choisi peut être partagé avec un autre zurg. Mets `rclone_cache_reclaim: false` pour désactiver cette fonction et conserver toutes les arborescences orphelines.

Quatre autres options sont ajoutées selon la plateforme, toutes sous Linux : `--allow-other` et `--allow-non-empty` toujours, `--uid` et `--gid` seulement lorsque les identifiants de l'utilisateur qui exécute le processus peuvent être lus. `--max-read-ahead` est passé partout sauf sous Windows, et `--read-only` dès que [`mount_read_only`](#rclone-settings) est défini.

Les valeurs du tampon et du délai de lecture ont été déterminées par des tests de performance sur une connexion de 600 Mbps, avec un débit à froid d'environ 533 Mbps et un TTFB d'environ 235 ms. La taille des blocs de lecture a été re-mesurée plus tard sur un hôte d'environ 70 MB/s : en mesures appariées et entrelacées, le débit médian est passé de 49.1 -> 56.5 MB/s sur Real-Debrid en passant de 4M à 32M, et il a évolué de la même façon sur TorBox.

**Remplacer les valeurs par défaut** avec `rclone_extra_args` :
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

Les options RC (`--rc`, `--rc-addr`, et toute autre option commençant par `rc-`) sont refusées : zurg lance lui-même le contrôle à distance de rclone pour invalider le cache VFS lorsque la bibliothèque change.

### User Agent et réseau {#user-agent--network}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `user_agent` | string | UA Chrome | User-Agent HTTP partagé pour les fournisseurs, indexeurs, ffprobe et intégrations sortantes. Vide rétablit le User-Agent de navigateur générique par défaut ; les valeurs personnalisées explicites sont envoyées telles quelles. Nécessite un redémarrage. Voir [identité des requêtes sortantes](outbound-identity.md). |
| `omit_user_agent` | boolean | `false` | Supprime le User-Agent HTTP (ffprobe utilise une valeur vide), en remplaçant `user_agent`. Les requêtes vers GitHub en envoient quand même un, car GitHub refuse les requêtes sans. Nécessite un redémarrage. |
| `outbound_client_name` | string | `"Media Client"` | Nom du produit ou du client pour les intégrations de serveur multimédia, lorsque c'est pris en charge. Vide rétablit la valeur par défaut. Nécessite un redémarrage. |
| `outbound_client_id` | string | `"media-client"` | Identifiant de client Plex, y compris la connexion pour les intégrations de serveur multimédia, lorsque c'est pris en charge. Vide rétablit la valeur par défaut. Nécessite un redémarrage. |
| `outbound_client_version` | string | `"1.0"` | Version du client pour les intégrations de serveur multimédia, lorsque c'est pris en charge. Vide rétablit la valeur par défaut. Nécessite un redémarrage. |
| `outbound_device_name` | string | `"Media Client"` | Nom de l'appareil pour les intégrations de serveur multimédia, lorsque c'est pris en charge. Vide rétablit la valeur par défaut. Nécessite un redémarrage. |
| `outbound_device_id` | string | `"media-client"` | Identifiant d'appareil Jellyfin/Emby pour les intégrations de serveur multimédia, lorsque c'est pris en charge. Vide rétablit la valeur par défaut. Nécessite un redémarrage. |
| `outbound_platform` | string | `"Desktop"` | Plateforme Plex pour les intégrations de serveur multimédia, lorsque c'est pris en charge. Vide rétablit la valeur par défaut. Nécessite un redémarrage. |
| `force_ipv6` | bool | `false` | Force tous les tests réseau de zurg et la sélection des hôtes à utiliser IPv6. Activez cette option si votre réseau a une meilleure connectivité IPv6 vers les serveurs RD (par ex. certains FAI limitent IPv4 mais pas IPv6). |
| `unrestrict_ip` | string | `""` | L'adresse IP à transmettre à RD lors de la décompression des liens de téléchargement. Utile dans les configurations multi-réseaux où vous voulez que les téléchargements soient générés pour une IP précise (par ex. l'IP de sortie d'un VPN) plutôt que pour l'IP sur laquelle tourne zurg. |
| `dns_servers` | list | `[]` (DNS système) | Serveurs DNS personnalisés pour résoudre les noms d'hôte RD. Utile si votre DNS système est lent, peu fiable ou bloqué par votre FAI. Laissez vide pour utiliser le résolveur système. Doit inclure le port (par ex. `1.1.1.1:53`). |
| `network_test_every_mins` | int | `1440` | Fréquence (en minutes) à laquelle zurg relance le test de latence réseau pour trouver les serveurs de téléchargement RD les plus rapides. Impossible à désactiver : les valeurs `<= 0` sont traitées comme `1440`. Les résultats sont mis en cache dans `data/network_test_results.json` et `data/network_test_timestamp` ; au redémarrage, si le cache est assez récent, le test réseau est ignoré. |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### Partage public de NZB {#public-nzb-sharing}

Un partage NZB est une URL que le destinataire récupère. Elle ne sert donc que s'il peut atteindre cet hôte, ce qu'un zurg derrière un NAT domestique ne peut pas garantir. Ces deux clés font passer cette URL par un service [zrok](https://zrok.io) à la place : zurg se connecte au service en sortie et sert le partage à travers cette connexion. Ainsi, **aucun port local ne s'ouvre** et rien de nouveau ne répond sur cet hôte. Le tunnel ne transporte que les deux routes de partage protégées par jeton, jamais le tableau de bord ni la bibliothèque.

Si les deux clés sont vides et qu'aucun environnement n'est activé dans `data/zrok`, le partage reste sur le réseau où se trouve déjà cet hôte, sans se connecter à rien. C'est la valeur par défaut. Retenez la seconde moitié : une fois qu'un environnement a été *activé*, un `zrok_account_token` vide ne signifie plus « local uniquement ». L'activation est ce qui active le partage, et elle persiste. Pour désactiver à nouveau le partage public, il faut supprimer `data/zrok`.

Créer, servir et révoquer des partages fonctionnent de la même façon dans les deux cas : le jeton de partage dans le chemin sert d'autorisation sur l'URL locale comme sur l'URL publique.

L'URL publique survit à un redémarrage : le partage côté service est retrouvé et rattaché, et non recréé. Ce qu'elle ne survit pas, c'est une nouvelle activation. Un nouvel environnement reçoit un nouveau partage, et les URL distribuées sous l'ancien cessent de fonctionner. Cela arrive quand vous supprimez `data/zrok`, et aussi si l'identité enregistrée là-dedans disparaît ou devient illisible, puisque réactiver est alors le seul moyen de revenir en arrière.

Supprimer `data/zrok` à la main laisse aussi cet environnement, et le partage qui s'y trouve, enregistrés sur le compte zrok. L'identité qui aurait pu les libérer est justement ce que vous venez d'effacer. Si ce désordre vous gêne, nettoyez-les depuis la console zrok. Ce n'est pas non plus un moyen de couper le partage à chaud : un zurg en cours d'exécution garde la connexion sur laquelle il sert déjà, donc l'ancienne URL continue de fonctionner jusqu'au redémarrage du processus. zurg libère lui-même un environnement chaque fois qu'il en remplace un. Il refuse de remplacer celui qu'il n'a pas pu libérer faute d'atteindre le service, ou celui dont il trouve les fichiers sur le disque sans pouvoir les lire, car activer par-dessus abandonnerait un environnement actif à chaque redémarrage.

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `zrok_account_token` | string | `""` | Le jeton d'activation zrok qui active le partage public. Gratuit sur [myzrok.io](https://myzrok.io) pour le service hébergé ; sur votre propre contrôleur si vous l'auto-hébergez. Il n'est nécessaire que pour la **première activation** : l'activation le consomme une fois et enregistre le jeton, avec l'identité de l'environnement, dans `data/zrok`. Chaque appel suivant s'authentifie à partir de cette copie enregistrée. La clé peut donc être retirée de `config.yml` ensuite, et le partage public reviendra quand même au redémarrage suivant. Attention à ce que cela implique pour le secret : retirer la clé de la configuration ne retire pas le jeton de l'hôte. Deux raisons de la laisser malgré tout : une activation qui a *échoué* (jeton refusé, service injoignable) n'est pas terminée, et la nouvelle tentative a besoin de la clé ; et toute *réactivation* ultérieure en a aussi besoin, donc une instance à qui l'on a retiré la clé, puis dont l'identité dans `data/zrok` a disparu, ne peut pas s'en sortir seule. Un jeton renouvelé est pris en compte à partir d'ici et appliqué à l'environnement enregistré, en conservant l'identité et l'URL publique. |
| `zrok_api_endpoint` | string | `""` | Le service zrok à contacter, pour les déploiements auto-hébergés. Vide, le SDK utilise sa valeur par défaut, `https://api-v2.zrok.io` (le service hébergé). Lu **uniquement au moment de l'activation** : dès que `data/zrok` contient un environnement activé, c'est le point de terminaison enregistré là-bas qui prime. Pour faire pointer un zurg déjà activé vers un autre service, il faut donc supprimer `data/zrok` puis réactiver. C'est d'ailleurs la bonne façon de faire, car une identité appartient au service qui l'a émise. Cela ne remplace pas `zrok_account_token` : la première activation a toujours besoin d'un jeton venant du service nommé ici. La variable d'environnement `ZROK2_API_ENDPOINT` du SDK l'emporte sur cette clé à ce même moment. |

La joignabilité se joue différemment pour un service auto-hébergé, et une seule des deux parties vous appartient : **ce zurg** atteint l'API du contrôleur (une adresse tailnet suffit), tandis que **vos destinataires** atteignent l'interface web du service. Un service joignable seulement sur votre propre tailnet distribue donc des URL de partage que seul votre tailnet peut ouvrir.

Deux autres points doivent concorder avec un service auto-hébergé. L'URL de partage est celle que le service annonce pour son interface web, et un hôte nu sans schéma est supposé être en `https`. Une interface qui sert du HTTP simple a donc besoin d'un TLS devant elle, ou d'une URL annoncée qui porte son propre schéma et port. Ensuite, le partage est créé dans le namespace que résout le SDK zrok, soit `public` sauf si la variable `ZROK2_DEFAULT_NAMESPACE` du SDK dit autre chose. zurg n'en fixe aucun, donc un service dont le namespace porte un autre nom doit le lui indiquer par cette variable.

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. Performances et réglages (avancé) {#6-performance--tuning-advanced}

Ces réglages sont rarement modifiés, sauf pour le débogage ou pour optimiser votre configuration réseau.

### Caches de lecture persistants {#persistent-read-caches}

Deux caches d'octets survivent à un redémarrage. Les deux sont partagés par toute l'instance, et chacun a son propre budget disque en MiB. Une modification prend effet après un redémarrage.

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `nzb_article_disk_cache_mb` | int | `512` | Articles Usenet décodés conservés dans `data/bytecache/articles/`. Un article lu une fois est servi depuis le disque la fois suivante. `0` désactive ce cache. |
| `archive_decoded_disk_cache_mb` | int | `512` | Blocs d'archive décompressés conservés dans `data/bytecache/decoded/`. Un retour en arrière dans la lecture ou un redémarrage ne redécode plus l'entrée depuis le début. Le même budget est aussi utilisé pour `data/bytecache/decoded-tails/`, qui conserve les 8 MiB de fin d'une entrée compressée dès qu'on l'a demandée. `0` désactive les deux. |

Les enregistrements les plus anciens et non utilisés sont supprimés en premier quand un budget est plein. [persistent-caches.md](../internals/persistent-caches.md) décrit chaque cache qui survit à un redémarrage.

### Sélection du CDN et de l'hébergeur {#cdn--host-selection}

> **Lien :** Le test de latence réseau qui détermine les hôtes les plus rapides s'exécute régulièrement selon [`network_test_every_mins`](#user-agent--network) (par défaut : toutes les 1440 minutes, soit 24 heures).

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | Définit les serveurs de téléchargement RD que zurg privilégie. `auto` utilise ce que RD fournit. `force_cloudflare` réécrit l'hôte en son jumeau `.cloud`, qui atteint la même machine via Cloudflare. C'est utile quand les IP directes sont bloquées. `force_numbered` utilise directement les hôtes numérotés de RD. `force_location_<location>` (par ex. `force_location_syd`, `force_location_fra`) passe par les serveurs d'un pays précis. |
| `cdn_host_preference` | string | — | Alias ancien de `rd_cdn_host_preference`, conservé pour la compatibilité et uniquement pour Real-Debrid. Si les deux sont définis, c'est celui explicitement défini qui l'emporte. |
| `tb_cdn_host_preference` | string | `"auto"` | Région du CDN TorBox. `auto` laisse le choix à TorBox. `force_location_<region>` sert les téléchargements depuis cette région. Seules les régions qui annoncent actuellement un nœud de livraison peuvent être forcées, et la liste de sélection du tableau de bord ne contient exactement que celles-là. Pas de repli vers l'ancienne clé : ses valeurs sont des codes de localisation Real-Debrid et n'ont aucun sens ici. |
| `number_of_hosts` | int | `0` (tous) | Limite zurg aux N hôtes de téléchargement les plus rapides. Après le test de vitesse des hôtes disponibles, zurg n'utilise que les N premiers. Mettre `0` pour utiliser tous les hôtes disponibles. Une valeur comme `3` réduit la répartition des connexions, mais garantit que tu utilises toujours les serveurs les plus rapides. |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` et `force_location_*` s'excluent mutuellement.** RD ne publie un jumeau `.cloud` que pour ses hôtes numérotés. Mesuré le 2026-08-09 : les 25 sous-domaines numérotés en ont un, et aucun des 22 sous-domaines spécifiques à un pays n'en a. Un compte avec Cloudflare activé dans ses paramètres de compte RD reçoit donc toujours un hôte numéroté, et aucune préférence de localisation ne peut être respectée pour lui. zurg détecte cela à partir du lien qu'il débloque au démarrage, ignore les sondes géographiques qui ne peuvent pas réussir, et journalise la raison si une localisation est tout de même configurée.

> **Remarque sur la vérification de `force_location_*` :** Avec une préférence de géolocalisation comme `force_location_nyk`, l'endpoint API `/rest/1.0/downloads` de RD normalise les URL de téléchargement vers des serveurs numérotés (par ex. `128-4.download.real-debrid.com`), alors que la réponse de déblocage a réellement renvoyé un serveur géographique (par ex. `nyk7-4.download.real-debrid.com`). Le code de téléchargement lui-même intègre le serveur numéroté (par ex. le code `...4128` correspond au serveur `128-4`). Pour vérifier que le routage géographique fonctionne, consulte les journaux de zurg ou la réponse brute de déblocage. Ne **pas** s'appuyer sur l'API de téléchargements de RD.

### Limites de débit {#rate-limits}

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | Nombre maximum d'appels à l'API RD par minute pour les opérations générales (tout sauf la liste des torrents). RD applique ses propres limites ; ceci empêche zurg de les atteindre et de se faire bloquer temporairement. N'augmente cette valeur que si tu es sûr que ton abonnement RD le permet. |
| `torrents_rate_limit_per_minute` | int | `75` | Nombre maximum d'appels à l'API RD par minute spécifiquement pour le endpoint `/torrents`, utilisé pour récupérer ta liste de torrents. Il est séparé car la liste des torrents est l'appel API le plus fréquent et il a son propre comportement en matière de limites. |
| `fetch_torrents_page_size` | int | `5000` | Nombre de torrents à récupérer par page lors de la synchronisation de ta bibliothèque RD. Des valeurs plus élevées signifient moins d'appels API mais des réponses plus volumineuses. Si ta bibliothèque est très grande (10 000 torrents ou plus), une valeur plus élevée réduit le temps de synchronisation. |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### Vérification des liens {#link-verification}

| Option | Type | Par défaut | Description |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | Contrôle la façon dont zurg vérifie que les liens de téléchargement sont toujours valides. Si faux, zurg utilise une requête `HEAD` (légère, aucune donnée transférée). Si vrai, zurg utilise un en-tête `Range` (`GET bytes=0-0`) qui ne télécharge qu'1 octet. Activez cette option si votre réseau ou les serveurs RD ne répondent pas correctement aux requêtes HEAD, ce qui provoque de fausses erreurs de liens. |

```yaml
use_range_verification: false
```

### Délais d'attente et nouvelles tentatives {#timeouts--retries}

| Option | Type | Par défaut | Description |
|--------|------|---------|-------------|
| `api_timeout_secs` | int | `60` | Nombre maximal de secondes à attendre qu'un appel à l'API RD réponde. Augmente cette valeur si tu as une connexion lente et que les appels API expirent. |
| `download_timeout_secs` | int | `15` | Nombre maximal de secondes à attendre lors du test des liens de téléchargement (utilisé pendant les tests de vitesse des hébergeurs et la vérification des liens). Ce n'est pas le délai pour les téléchargements de fichiers eux-mêmes. |
| `retries_until_failed` | int | `2` | Nombre de fois où un appel API échoué est relancé avant d'abandonner et de le marquer comme échoué. Des valeurs plus élevées apportent plus de résilience face aux pannes temporaires de RD, mais ralentissent la détection des échecs. |
| `retry_503_errors` | bool | `false` | Quand vrai, relance les requêtes qui reçoivent une réponse 503 (Service Unavailable) de RD. RD renvoie une 503 pendant la maintenance ou en cas de surcharge. Active cette option si tu as souvent des erreurs 503 qui se résolvent rapidement d'elles-mêmes. |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### Téléchargements et débogage {#downloads--debugging}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `get_downloads_limit` | int | `-1` | Nombre maximum d'entrées de téléchargement RD (non-torrent) à récupérer. `-1` signifie pas de limite (tout récupérer), `0` ignore complètement la récupération des téléchargements, et un nombre positif la plafonne. Utile si tu utilises la fonction de déverrouillage de liens directs de RD et que tu veux voir ces fichiers dans zurg. Si tu omets la clé, c'est `-1` ; un `0` explicite est pris en compte comme « cache none » et affiche un avertissement au démarrage, car c'est généralement une config écrite avant que `0` change de sens. |
| `load_dumped_torrents` | bool | `false` | Quand c'est true, charge les données des torrents depuis le dossier `dump/` au démarrage. C'est un mécanisme de récupération : si zurg a déjà sauvegardé l'état des torrents (par exemple lors d'un plantage), l'activer restaure cet état sans tout récupérer à nouveau depuis RD. |
| `log_requests` | bool | `false` | Quand c'est true, journalise des statistiques détaillées pour chaque requête de téléchargement (chemin du fichier, temps de réponse, octets envoyés). Utile pour déboguer des problèmes de streaming ou comprendre les schémas d'accès. Cela génère beaucoup de logs, donc désactive-le en production. |
| `log_level` | string | `DEBUG` | Le niveau de détail des logs : `DEBUG`, `INFO`, `WARN`, `ERROR` ou `FATAL`. La modifier depuis le tableau de bord prend effet immédiatement, sans redémarrage, et change le niveau de tous les composants d'un coup. Elle remplace la variable d'environnement `LOG_LEVEL`, donc le contrôle du tableau de bord fonctionne toujours sur un conteneur qui en intègre une ; laisse la clé de côté pour rendre le choix à `LOG_LEVEL`. Une valeur qui ne correspond à aucun niveau est ignorée avec un avertissement au démarrage, au lieu de provoquer une erreur fatale. |
| `traffic_alert_gb` | int | `0` | Avertit quand un compte debrid fait passer plus de ce nombre de GiB via zurg en une journée (la journée se réinitialise à 00:05 CET, avec le quota de Real-Debrid). L'avertissement indique les fichiers qui ont le plus consommé cette heure et qui les a lus, pour qu'un scan de bibliothèque ou un client qui récupère des fichiers entiers apparaisse pendant que ça se passe. zurg journalise aussi un résumé des fichiers les plus volumineux de l'heure en début de chaque heure, ainsi qu'une ligne pour toute lecture unique d'au moins 1 GiB, que l'alerte soit activée ou non. `0` désactive l'alerte. |
| `traffic_alert_webhook` | string | — | Un webhook Discord auquel l'alerte de trafic est aussi envoyée. Garde-le privé : quiconque connaît l'URL peut publier dans ce canal. |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
traffic_alert_gb: 500
```

#### Envoyer les logs au support {#sending-logs-to-support}

**Export Logs** sur le tableau de bord et `zurg support` envoient votre journal et votre configuration, tous deux anonymisés, au serveur de support de DMM, `logs.debridmediamanager.com`, et vous donnent un code à coller dans votre fil de support. Il n'existe aucun réglage pour cela. Si ce serveur est injoignable ou refuse l'envoi, les fichiers partent sur des hébergeurs de paste publics, essayés dans cet ordre : `paste.c-net.org`, `temp.sh`, `0x0.st`. Si votre pare-feu ne laisse zurg atteindre que certains hôtes, autorisez `logs.debridmediamanager.com`.

Un hôte qui répond 403 a refusé cette machine. zurg l'ignore donc pendant 24 heures, y compris `logs.debridmediamanager.com`. **Download Logs** sur le tableau de bord vous donne les mêmes fichiers anonymisés sans les envoyer ailleurs.

## 7. Dossiers et filtres {#7-directories--filters}

Définissez des dossiers virtuels qui organisent vos torrents selon des règles de filtre flexibles. Chaque dossier apparaît comme un dossier dans votre montage et n'affiche que les torrents correspondant à ses filtres.

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### Options des dossiers {#directory-options}

| Option | Type | Défaut | Description |
|--------|------|---------|-------------|
| `group` | string | le nom propre du dossier | Les dossiers qui partagent un groupe se disputent chaque torrent : il atterrit dans le premier dont les filtres correspondent, et dans aucun autre du groupe. Les dossiers de groupes différents ont chacun leur propre copie. |
| `group_order` | int | `0` (traité comme `1`) | Priorité dans le groupe : plus la valeur est basse, plus on passe en premier. En cas d'égalité, on départage par nom de dossier. |
| `filters` | list | `[]` | Les règles qui décident ce qui appartient ici. Un torrent correspond au dossier si **n'importe quelle** entrée de la liste correspond. Une liste vide ou absente correspond à tous les torrents. |
| `only_show_the_biggest_file` | bool | `false` | N'affiche que le plus gros fichier de chaque torrent, en masquant les échantillons, les bonus et les fichiers annexes. |
| `only_show_files_with_size_lte` | int | `0` (désactivé) | Masque les fichiers plus gros que ce nombre d'octets. |
| `only_show_files_with_size_gte` | int | `0` (désactivé) | Masque les fichiers plus petits que ce nombre d'octets. |
| `rex_shows` | string | `""` (aucun) | Avec `rex_url` : le titre d'une bibliothèque de séries TV dans rex qui affiche les épisodes de ce dossier. |
| `rex_movies` | string | `""` (aucun) | Avec `rex_url` : le titre d'une bibliothèque de films dans rex qui affiche les films de ce dossier, ainsi que tout fichier que rex ne peut pas identifier comme un épisode. |
| `rex_music` | string | `""` (aucun) | Avec `rex_url` : le titre d'une bibliothèque musicale dans rex qui affiche les fichiers audio de ce dossier (`.flac`, `.mp3`, `.m4a`, `.m4b`), livres audio compris. Sans elle, aucun fichier audio ne va dans rex. |
| `rex_photos` | string | `""` (aucun) | Avec `rex_url` : le titre d'une bibliothèque de photos dans rex qui affiche les BD de ce dossier (`.cbz`, `.cbr`), chacune en tant qu'album de ses pages, que Plex Web parcourt et lit comme un diaporama. Plex pour Android n'affiche aucune bibliothèque de photos. Les BD restent des fichiers sur le point de montage. |

Un fichier explicitement forcé visible dans zurg ignore les trois options de visibilité.

### Conditions de filtre {#filter-conditions}

| Condition | Type | Description |
|-----------|------|-------------|
| `id` | string | L'ID du torrent. Décisif : rien d'autre dans la même entrée n'est pris en compte. |
| `regex` | string | Le nom du torrent correspond au motif. |
| `not_regex` | string | Le nom du torrent ne correspond pas au motif. |
| `contains` | string | Le nom du torrent contient le texte (insensible à la casse). |
| `contains_strict` | string | Le nom du torrent contient le texte (sensible à la casse). |
| `not_contains` | string | Le nom du torrent ne contient pas le texte (insensible à la casse). |
| `not_contains_strict` | string | Le nom du torrent ne contient pas le texte (sensible à la casse). |
| `size_gte` | int | La taille totale du torrent est d'au moins ce nombre d'octets. |
| `size_lte` | int | La taille totale du torrent est d'au plus ce nombre d'octets. |
| `any_file_inside_regex` | string | Un fichier du torrent correspond au motif. |
| `any_file_inside_not_regex` | string | Un fichier du torrent ne correspond pas au motif. |
| `any_file_inside_contains` | string | Un fichier contient le texte (insensible à la casse). |
| `any_file_inside_contains_strict` | string | Un fichier contient le texte (sensible à la casse). |
| `any_file_inside_not_contains` | string | Un fichier ne contient pas le texte (insensible à la casse). |
| `any_file_inside_not_contains_strict` | string | Un fichier ne contient pas le texte (sensible à la casse). |
| `any_file_inside_size_gte` | int | Un fichier fait au moins ce nombre d'octets. |
| `any_file_inside_size_lte` | int | Un fichier fait au plus ce nombre d'octets. |
| `added_within_hours` | int | Le torrent a été ajouté au cours des ce nombre d'heures dernières. |
| `added_within_days` | int | Le torrent a été ajouté au cours des ce nombre de jours derniers. |
| `added_after` | string | Le torrent a été ajouté à cette date ou après. Format `YYYY-MM-DD` ou `YYYY-MM-DD HH:MM`. |
| `added_before` | string | Le torrent a été ajouté avant cette date, mêmes formats. Combiné avec `added_after`, les deux doivent être vrais. |
| `has_episodes` | bool | Détection d'épisodes : marqueurs de saison/épisode ou hashes CRC dans le nom du torrent ou des fichiers, ou une suite de fichiers numérotés. Un torrent dont le plus gros fichier fait au moins 5 fois le second est considéré comme un film avec bonus et rejeté. |
| `is_music` | bool | Un fichier se termine par `.m3u`, `.mp3`, `.flac`, `.m4a` ou `.m4b`. |
| `has_tag` | string | Le torrent porte ce tag. Agit comme un verrou : sans lui, rien d'autre dans l'entrée ne peut correspondre. |
| `not_has_tag` | string | Le torrent ne porte pas ce tag, et agit comme verrou de la même façon. |
| `tags_match_all` | list | Tous les tags listés sont présents (insensible à la casse). |
| `tags_match_any` | list | Au moins un tag listé est présent. |
| `tags_missing_all` | list | Aucun des tags listés n'est présent. |
| `tags_missing_any` | list | Au moins un tag listé est absent. |
| `provider` | string | La version est détenue par ce compte, désigné par son `name` dans le bloc providers. Un verrou, pas une correspondance : combiné avec une autre condition, les deux doivent être vraies. Seul, il met tout le compte dans le répertoire. |
| `not_provider` | string | Aucun compte détenant la version n'est celui-ci. Agit comme verrou de la même façon. |
| `and` | list | Chaque condition imbriquée doit correspondre. |
| `or` | list | Au moins une condition imbriquée doit correspondre. |

Les tags proviennent de l'analyse média — voir [tags.md](tags.md) pour la liste complète.

Les motifs s'écrivent `/expression/flags`, où les flags sont parmi `i` (insensible à la casse), `m` (multiligne), `s` (le point correspond aux sauts de ligne) et `x` (étendu). Une valeur sans barres obliques est compilée comme une expression régulière Go simple.

Les conditions d'une même entrée de filtre ne sont **pas** combinées par ET par défaut — la plupart correspondent à l'entrée dès qu'une seule est vraie. Utilisez un bloc `and:` explicite quand vous voulez toutes les conditions :

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### Dossiers par compte {#per-account-directories}

`__all__` à côté, chaque compte configuré a son propre dossier, nommé d'après lui : `__realdebrid__`, `__torbox__`, `__alldebrid__`, `__nzb__`. Ces dossiers ne sont pas configurés. Ils apparaissent parce que le compte existe, et disparaissent quand tu le supprimes. Avec un seul compte, son dossier n'apparaît pas à la racine du montage, et `__all__` contient les mêmes fichiers. Les chemins HTTP et WebDAV directs, comme `/http/__realdebrid__/`, répondent toujours. Par le montage, ils ne se résolvent plus : pointe donc toute bibliothèque ou tout script qui utilisait `__<name>__` vers `__all__`.

Chaque dossier contient tout ce que ce compte possède et, contrairement à un dossier filtré, il décide aussi d'où partent les lectures. Une release détenue par deux comptes n'est qu'une seule entrée dans la bibliothèque. Sans cela, chaque copie serait streamée depuis le premier compte dans l'ordre du bloc `providers` :

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

L'épinglage exclut les autres comptes au lieu de simplement préférer celui qui est nommé. Il n'y a pas de bascule automatique silencieuse : si TorBox ne peut pas servir le fichier, la lecture sous `__torbox__` échoue au lieu de répondre discrètement avec les octets de Real-Debrid. Les lectures ailleurs dans le montage ne changent pas et basculent toujours normalement.

Deux conséquences découlent du fait que les comptes ne détiennent pas le même contenu :

- Un dossier ne liste que les fichiers que son compte possède réellement. Si TorBox a téléchargé une partie d'une release que Real-Debrid a en entier, `__torbox__` n'affiche que cette partie.
- Qu'un fichier soit cassé se juge par compte. Un fichier mort sur Real-Debrid mais sain sur TorBox renvoie une 404 sous `__realdebrid__` et se lit sous `__torbox__`, alors que le reste du montage continue de le servir.

Le dossier porte le `name` du compte, qui vaut par défaut son `type`. Deux comptes sur le même service doivent avoir des noms distincts (`rd-main`, `rd-backup`) et obtiennent chacun un dossier. Le backend Usenet s'appelle `nzb` par défaut, donc il apparaît sous `__nzb__`. Mets `name: usenet` sur cette entrée de fournisseur si tu préfères parcourir `__usenet__`.

Tu peux renommer un compte plus tard. zurg voit les mêmes releases sous le nouveau nom et les déplace là-bas. L'ancien dossier disparaît avec l'ancien nom. Si un serveur multimédia lit ce dossier, pointe-le vers le nouveau avant de renommer.

Comme la même release apparaît sous chaque compte qui la détient, ainsi que dans tes dossiers filtrés, pointe un serveur multimédia sur une partie du montage plutôt que sur l'ensemble, sinon il scannera plusieurs fois le même contenu.

Un compte qui porte le nom d'un dossier déjà utilisé par zurg (`all`, `unplayable`, `dump`, `downloads`) n'obtient pas de dossier par compte, et zurg journalise un avertissement au démarrage au lieu de remplacer le dossier existant.

### Catalogues debrid locaux {#local-debrid-catalogs}

Chaque entrée de fournisseur debrid accepte un bloc `library` facultatif :

```yaml
providers:
  - name: rd-local
    type: realdebrid
    token: PRIMARY_RD_TOKEN
    download_tokens: # Optional bandwidth fallback.
      - SECOND_RD_TOKEN
    library:
      source: local
      path: torrents/rd-local
```

`source` vaut `provider` par défaut. Avec `local`, les fichiers portables `.zurgtorrent` gèrent
l'appartenance, et la lecture utilise les identifiants de ce compte. `path` vaut
`torrents/<resolved-account-name>` par défaut et doit rester sous `torrents/`. Un même répertoire
source ne peut pas appartenir à deux comptes activés. Les fournisseurs NZB conservent
leur bibliothèque `nzbs/` existante.

Dans cet exemple, les deux jetons RD utilisent le même catalogue dans `torrents/rd-local/`.
Le second jeton n'a besoin ni d'entrée de fournisseur ni de répertoire, et sa bibliothèque de torrents
n'est pas importée. `download_tokens` garde son comportement de repli sur la bande passante ; il ne
force pas chaque téléchargement à passer par le second jeton. Deux entrées de fournisseur locales distinctes
possèdent à la place deux répertoires de catalogue distincts, même si ce sont toutes deux des Real-Debrid.
Les identifiants restent dans la configuration et ne sont jamais exportés dans les fichiers portables.

Consultez [bibliothèques portables](../guides/local-libraries.md) pour l'export hors ligne, la migration
depuis `dump/`, le fonctionnement du partage et les limites de lecture.

#### Déporter un compte en ligne vers une bibliothèque locale {#offloading-an-online-account-into-a-local-library}

Un compte Real-Debrid ou AllDebrid qui possède son catalogue (pas de `source`, ou `source: provider`) peut déplacer ses releases terminées dans une bibliothèque locale et les supprimer du compte, ce qui libère leurs emplacements :

```yaml
providers:
  - name: rd
    type: realdebrid
    token: YOUR_RD_TOKEN
    library:
      offload_to: rd-local      # a local entry of the same type
      offload_after_mins: 30    # optional, 30 is the default

  - name: rd-local
    type: realdebrid
    token: YOUR_RD_TOKEN        # the same account
    library:
      source: local
```

| Clé | Défaut | Signification |
|---|---|---|
| `library.offload_to` | aucun | Nom d'une entrée `source: local` activée, du même type. Seuls les comptes `realdebrid` et `alldebrid` l'acceptent, car seuls leurs liens continuent de fonctionner après la suppression du torrent. Elle ne peut pas désigner le compte lui-même. |
| `library.offload_after_mins` | `30` | Durée pendant laquelle une release doit avoir été complète sur le compte avant d'être déplacée automatiquement. Elle est comptée à partir du moment où zurg l'a vue complète pour la première fois, donc un redémarrage relance l'attente. Nécessite `offload_to`. |

Une release n'est déplacée que si chaque fichier a un lien qu'un autre compte peut utiliser, si rien ne la répare ou ne la télécharge, si aucun job Sonarr ou Radarr dans l'endpoint qBittorrent ne la mentionne encore, et si le déplacement conserve son nom de dossier et chacun des répertoires dans lesquels elle se trouve. Son dossier reste à sa place et aucun scan du serveur multimédia n'est lancé. La page de la release dans le tableau de bord permet de déplacer une seule release à la main, avec ou sans `offload_to`. Voir [bibliothèques portables](../guides/local-libraries.md#offload-an-online-account-into-a-local-library) pour l'ordre des étapes, ce qui se passe en cas d'échec, et comment la lecture locale sur un token partagé est protégée.
