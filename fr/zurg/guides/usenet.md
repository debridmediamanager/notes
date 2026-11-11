# Usenet avec zurg {#usenet-with-zurg}

zurg, avec le backend `nzb`, transforme les fichiers `.nzb` en bibliothèque montée. Il n'y a ni téléchargeur ni dossier de téléchargements terminés.
Rien n'est téléchargé avant la lecture. zurg stocke les NZB et des caches bornés dans `data/bytecache` et `data/par2`, ainsi que des enregistrements d'index. `nzb_article_disk_cache_mb` vaut 512 MiB par défaut. Lors d'un seek, zurg ne récupère que les articles qui couvrent ces octets. Un remux de 60 Go ne demande pas 60 Go d'espace disque.

Usenet utilise les mêmes filtres de bibliothèque, le même montage et la même intégration avec les serveurs de médias que les backends debrid. Les releases Usenet peuvent coexister avec le contenu Real-Debrid ou TorBox. Vous pouvez aussi utiliser Usenet seul.

**Plusieurs fournisseurs Usenet sont pris en charge.** Une seule entrée `nzb` peut contenir autant de comptes de news que vous voulez : fournisseurs illimités, comptes de blocs, peu importe ce que vous possédez. zurg bascule de l'un à l'autre article par article. C'est plus important ici que la redondance habituelle : la rétention dépend de chaque fournisseur, donc un second compte fait très souvent la différence entre une récupération supplémentaire et la reconstruction complète d'une release à partir de PAR2. Voir [Plus d'un fournisseur Usenet](#more-than-one-usenet-provider).

Ce guide couvre les comptes de news, les NZB, le montage et Plex.

| | |
|---|---|
| Référence de configuration | [config.md → Comptes Usenet](../reference/config.md#usenet-accounts) |
| Tableau de bord | `http://localhost:9999/config/` → Essentials → Providers |
| Emplacement du code | `internal/nzb` (backend), `internal/nntp` (client news), `internal/par2` (calcul de réparation) |
| Dossier surveillé | `nzbs/`, dans le répertoire de travail de zurg (`/config` avec Docker) |
| Cache de réparation | `data/par2/` |
| Noms de fichiers résolus | `data/nzb-names/`, pour qu'une release obfusquée ne soit lue pour ses noms qu'une fois et non à chaque redémarrage |
| Index des articles | `data/nzb-index/`, sous `nzb_segments: mmap` — la valeur par défaut sous Linux, macOS et BSD |

---

## Ce dont vous avez besoin {#what-you-need}

- **Au moins un compte chez un fournisseur Usenet.** La rétention compte avant tout : un fournisseur à 4000+ jours aura encore des posts qu'un fournisseur à 1000 jours a déjà purgés. Le *nombre de connexions* de ton abonnement est le second chiffre à connaître ; c'est celui que zurg utilise.
- **D'autres comptes, si tu en as.** Un second fournisseur illimité sur un backbone différent, ou un compte « block » pas cher pour combler les trous, c'est ce qui apporte le plus de valeur à une configuration Usenet : voir [Plus d'un fournisseur Usenet](#more-than-one-usenet-provider).
- **Des fichiers NZB ou quelque chose qui les récupère.** Télécharge-les depuis ton indexeur et dépose-les dans `nzbs/`. Ou active le [endpoint compatible SABnzbd](sonarr-radarr.md) et laisse Sonarr et Radarr te les transmettre. Il écrit dans le même dossier. zurg peut aussi chercher tout seul dans tes indexeurs Newznab. Il le fait quand tu appuies sur lecture dans [Stremio](stremio.md). Il le fait aussi pour les demandes de ta watchlist, de Seerr et des \*arrs via l'[acquisition](acquisition.md). Les torrents pour un compte debrid ont leur propre endpoint, compatible avec [qBittorrent](sonarr-radarr-torrents.md).
- **zurg**, plus `rclone` si tu veux un montage de système de fichiers plutôt que WebDAV directement. zurg télécharge rclone pour toi au premier lancement.

---

## 1. Configurer vos comptes Usenet {#1-configure-your-news-accounts}

Chaque compte dans zurg est une entrée sous `providers:`. Un compte Usenet s'authentifie avec des identifiants de serveur au lieu d'un jeton API, donc il contient un bloc `nntp` au lieu de `token` :

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

C'est tout. Ajoute les comptes debrid à côté si tu en as :

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| Clé | Défaut | Remarques |
|---|---|---|
| `host` | *(obligatoire)* | Le serveur de news. Un host absent ou vide provoque une erreur au démarrage. |
| `port` | `563` avec TLS, `119` sans | |
| `tls` | `false` | Active-le. Le NNTP en clair envoie ton mot de passe et tes lectures en clair à quiconque se trouve sur le chemin. |
| `username` / `password` | `""` | |
| `connections` | `8` | **Mets la vraie limite de ton forfait.** Ce n'est pas une limite de débit à ménager : une seule connexion ne transporte qu'une fraction du débit du fournisseur, et zurg lit avec ce nombre. Trop bas et le streaming est lent ; au-dessus de la limite du forfait, le serveur commence à refuser les connexions. |
| `warm_connections` | `4` | Connexions authentifiées inactives gardées ouvertes pour qu'une lecture n'attende jamais l'établissement d'une connexion. Un établissement coûte environ 0,8 s de TCP, TLS, message d'accueil et `AUTHINFO`, et sans plancher il était payé à la demande après chaque démarrage et chaque période calme. Elles sont prises sur `connections` plutôt qu'en plus : le forfait les compte comme connexions ouvertes, et zurg les maintient en vie avec un `DATE` périodique. Le plancher est donc plafonné à la limite. `-1` n'en garde aucune, ce qu'il faut à un forfait facturé au temps de connexion. Le `warm_connections` de niveau supérieur définit la valeur par défaut pour un compte qui n'en précise aucune, voir [connexions chaudes](../reference/config.md#warm-connections). |
| `cache_size_mb` | `512` | Données d'articles décodées gardées en mémoire, partagées entre tous les fichiers lus plutôt que par fichier. |
| `servers` | `[]` | Comptes news supplémentaires, voir [Plusieurs fournisseurs Usenet](#more-than-one-usenet-provider). |

Deux règles que le validateur de configuration impose :

- **Une seule entrée de fournisseur `nzb` activée.** Deux entrées scanneraient chacune le même dossier `nzbs/` et dupliqueraient chaque release. Ce n'est pas une limite sur le nombre de *fournisseurs Usenet* que tu peux utiliser : les comptes news supplémentaires vont sous `nntp.servers` de cette entrée unique, où ils servent la même bibliothèque au lieu d'une deuxième copie.
- **`watchlist: true` ne peut pas la cibler.** Le backend Usenet ne peut pas ajouter de contenu, donc ce ne peut jamais être le compte où atterrit un ajout à la watchlist Plex.

### Plus d'un fournisseur Usenet {#more-than-one-usenet-provider}

La disponibilité des articles dépend de chaque fournisseur. Le fait qu'un simple re-téléchargement suffise, ou qu'il faille reconstruire toute la release avec PAR2, dépend de la présence de l'article chez un autre compte. C'est pourquoi un second compte vaut ici plus qu'une simple redondance.

Les clés déjà présentes dans le bloc `nntp` décrivent le premier compte. Tout ce qui se trouve sous `servers` est un autre compte. Les comptes ayant la même `priority` se partagent la charge, et un numéro plus élevé n'est sollicité qu'après les précédents. Un compte `backup` n'est sollicité que lorsque tous les comptes principaux n'ont pas pu fournir l'article. Une configuration existante avec un seul compte continue de fonctionner sans modification :

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Chaque compte a sa propre limite de connexions, et les lectures sont dimensionnées sur la **somme des limites des comptes non-backup qui partagent la plus basse `priority` active**. Dans l'exemple ci-dessus, cela donne 30 + 20 = 50, car les deux comptes ont la priorité par défaut. Un second fournisseur illimité à la même priorité augmente donc aussi le débit, en plus de la sécurité sur la rétention. Un compte `backup` n'apporte ni l'un ni l'autre, et c'est voulu : il ne sert qu'à récupérer ce que les comptes principaux n'ont pas pu fournir. Le compter élargirait chaque fenêtre de pré-lecture pour une capacité dont la lecture en continu n'a jamais besoin.

Trois clés déterminent qui est sollicité :

| Clé | Défaut | Effet |
|---|---|---|
| `name` | valeur de `host` | Donne un nom au compte dans les journaux. |
| `priority` | `0` | Détermine qui est sollicité en premier, du plus bas au plus haut. Les comptes ayant la même priorité sont sollicités dans l'ordre d'écriture, sauf qu'un compte ayant une connexion libre est préféré à un compte dont la limite est épuisée. Ainsi, deux comptes équivalents se partagent la charge au lieu de faire la file sur un seul. |
| `backup` | `false` | Marque un compte à blocs facturé à l'usage, consulté seulement lorsque tous les comptes principaux ont signalé l'article absent, envoyé une copie endommagée, échoué en cours de route ou sont injoignables. Un compte principal simplement **occupé** ne suffit pas : zurg attend plutôt que de dépenser des octets facturés pour quelque chose qu'un compte illimité aurait pu servir. |
| `backbone` | `""` | Indique le spool d'articles vers lequel un compte est résolu. Deux comptes sur le même backbone contiennent les mêmes articles. Donc, dès que l'un a signalé un article absent, les autres comptes de ce spool sont ignorés au lieu de payer un aller-retour pour la même réponse. |

Chaque compte garde aussi son propre plancher de préchauffage, prélevé sur sa propre limite. Une lacune de rétention envoie la lecture directement au-delà du compte principal, donc le premier compte sollicité est précisément celui dont la connexion n'a encore été payée par personne. Un compte à blocs de deux connexions peut être configuré sans aucun préchauffage avec `warm_connections: -1`.

La revente est très répandue, donc il vaut la peine de renseigner `backbone`. Deux comptes achetés auprès de fournisseurs différents peuvent très bien partager le même spool. Sans ce champ, chaque article manquant serait demandé deux fois. Vous pouvez regrouper les comptes sous le nom de votre choix : la chaîne est uniquement comparée aux autres entrées.

Au démarrage, zurg nomme chaque compte qu'il va utiliser :

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

Le recensement qui détermine si une release doit être réparée interroge chaque compte avant de déclarer un article manquant, et chacun n'est interrogé que sur ce que ses prédécesseurs n'avaient pas. Une erreur de transport n'est jamais confondue avec un article expiré. Si un compte a expiré ou a coupé la transmission de l'article en cours de route, c'est cette erreur qui est signalée. Un délai dépassé ne fait donc jamais passer un silence pour une absence, et ne déclenche jamais une réparation pour quelque chose qui n'avait pas disparu. Un compte totalement injoignable ne compte pas : si un autre compte affirme que l'article a disparu, il est considéré comme disparu.

### Configurer les fournisseurs dans le tableau de bord {#configuring-providers-in-the-dashboard}

`http://localhost:9999/config/` → **Essentials** → **Providers** fait la même chose sans éditer le YAML. Le tableau liste tous les comptes dans l'ordre du config :

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

Pour une ligne `nzb`, la colonne Token affiche le **nom d'hôte du serveur de news** à la place d'un indice de token, car il n'y a pas de token à masquer, suivi du nombre de serveurs de news supplémentaires.

**Pour ajouter un compte Usenet :**

1. Clique sur **Add provider**.
2. Mets **Type** sur `nzb`. Les champs de token disparaissent et les champs NNTP apparaissent à leur place.
3. Laisse **Name** vide, sauf si tu veux autre chose que `nzb`. Ce nom sert à nommer le dossier du compte. Donc `usenet` ici te donne `__usenet__` dans le montage.
4. Remplis **NNTP host**, **Port**, **TLS** (coché par défaut, laisse-le activé), **Username**, **Password**, **Connections** (valeur indicative `8` ; mets ici le nombre de connexions réel de ton abonnement) et **Cache size MB** (valeur indicative `512`).
5. Laisse **Watchlist target** décoché. Le backend ne peut pas ajouter de contenu, et si tu le coches, la sauvegarde est refusée. **Disabled** garde l'entrée dans `config.yml` sans la charger.
6. Clique sur **Save**.

Le formulaire est validé comme si la modification avait été appliquée. Les erreurs remontent donc sous forme d'alerte, sans casser le config. Ajouter un **deuxième** provider `nzb` est refusé à ce stade : l'erreur te renvoie vers **Further news servers** (ou `nntp.servers`), où vont les comptes de news supplémentaires.

**Pour ajouter un autre serveur de news** (un second compte, ou un compte block sur un autre backbone), clique sur **Edit** sur la ligne `nzb`, puis sur **Add news server** sous **Further news servers**. Chaque serveur a ses propres **Name**, **NNTP host**, **Port**, **TLS**, **Username**, **Password**, **Connections**, **Priority**, **Backbone** et **Backup only**. **Remove server** en retire un. **Save** écrit tous les serveurs dans `nntp.servers`.

**Pour en modifier un**, clique sur **Edit** sur sa ligne. Le formulaire charge tout sauf les mots de passe, celui du premier compte comme ceux de chaque serveur supplémentaire. Ils restent vides et signifient *garder l'existant*. Tape un nouveau mot de passe seulement si tu veux le changer. Les réglages pour lesquels le formulaire n'a pas de champ sont conservés tels qu'ils sont dans `config.yml`.

**Delete** demande une confirmation, puis supprime l'entrée du provider dans `config.yml`. Il ne touche pas à ton dossier `nzbs/` : les fichiers NZB restent où ils sont et reviennent avec le provider. Le dernier provider activé ne peut être ni supprimé, ni désactivé.

Chaque modification faite ici est écrite directement dans `config.yml` et affiche :

> Provider changes saved to config.yml — restart zurg to apply

Les modifications de providers ne sont **pas** rechargées à chaud. Redémarre zurg avant de t'attendre à voir un changement.

## 2. Démarrer zurg et confirmer les comptes {#2-start-zurg-and-confirm-the-accounts}

+++ Linux et macOS
```bash
./zurg
```
+++ Windows
```powershell
.\zurg.exe
```
+++

Si `zurg setup` a installé zurg pour démarrer tout seul, redémarrez-le avec `zurg service restart` à la place (`./zurg service restart`, ou `.\zurg.exe service restart` sous Windows).

zurg vérifie les comptes Usenet une seule fois au démarrage, parce qu'un mauvais mot de passe se manifeste sinon bien plus tard, par des fichiers qui refusent tous de se lire :

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

Une panne totale se signale tout aussi clairement :

```
Cannot reach the news server for nzb: <reason>
```

Vérifiez d'abord le port et la combinaison TLS (`563`+`tls: true`, ou `119`+`tls: false`), puis les identifiants, puis si l'abonnement est bien actif.

**Avec plusieurs comptes, lisez les avertissements, pas seulement la ligne de connexion.** Chaque compte injoignable a son propre avertissement, et le démarrage continue tant qu'*un seul* compte répond. L'erreur ci-dessus n'apparaît que si tous les comptes sont injoignables. Donc un deuxième fournisseur hors service ressemble à un démarrage normal, sauf si vous y prêtez attention :

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. Ajouter des fichiers NZB {#3-add-nzb-files}

zurg crée le dossier de surveillance `nzbs/` au démarrage. Il se trouve dans le dossier depuis lequel zurg est lancé. Copiez-y les fichiers NZB.

+++ Linux et macOS
```bash
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```
+++ Windows
```powershell
Copy-Item "$HOME\Downloads\Some.Release.2024.2160p.nzb" nzbs\
```
+++

En une seconde ou deux, zurg remarque le fichier et le lit, puis la bibliothèque l'affiche dès que la lecture est terminée. Le journal indique ce qu'il a lu :

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### Délai d'apparition {#how-quickly-it-appears}

zurg surveille lui-même le dossier `nzbs/`, avec une vérification environ toutes les secondes qui ne coûte qu'un seul appel système, quel que soit le nombre de NZB dans le dossier. Un fichier qui arrive dans ce dossier est donc lu presque aussitôt, et non à la prochaine vérification périodique de la bibliothèque. Une [version obfusquée](#obfuscated-releases) prend un peu plus de temps, car ses vrais noms de fichiers doivent d'abord être lus dans ses propres articles. Cela prend généralement bien moins d'une seconde, et la version apparaît dès que c'est terminé. Ces deux délais ne dépendent plus de `check_for_changes_every_secs`. Ce n'était pas le cas avant : une version obfusquée pouvait apparaître jusqu'à deux intervalles entiers après son dépôt, un pour la lecture du dossier et un autre parce que les noms avaient été résolus juste après la vérification qui aurait dû la détecter. Avec un intervalle de 10 secondes, il s'écoulait 17,7 secondes entre le dépôt et l'apparition de la version, dont seulement 0,67 seconde de traitement.

La vérification périodique reste en place et sert toujours de filet de sécurité. Elle détecte les deux cas qu'un dossier surveillé ne peut pas signaler seul : un NZB **remplacé sur place** sous un nom qu'il portait déjà, et un système de fichiers dont les horodatages de dossier sont trop grossiers pour distinguer deux modifications faites dans la même seconde.

### Ce qui est pris en compte {#what-gets-picked-up}

- Fichiers **directement dans `nzbs/`** dont le nom se termine par `.nzb`, sans tenir compte de la casse.
- **Les sous-dossiers sont ignorés.** `nzbs/movies/foo.nzb` est invisible. Mettez tout à plat au lieu d'organiser : l'organisation de la bibliothèque vient des filtres de dossiers, pas de ce dossier.
- **XML brut uniquement.** Les `.nzb.gz` ne sont ni décompressés ni lus ; décompressez-les d'abord.
- Un fichier qui ne peut pas être analysé est ignoré avec un avertissement, et l'analyse continue.

### Comment s'appelle la release {#what-the-release-is-called}

Le nom que zurg affiche, et donc le dossier que Plex voit, est :

1. la valeur de `<meta type="name">` du NZB, s'il en a une et qu'elle survit à l'assainissement, sinon
2. **le nom du fichier sans le `.nzb`**.

Donc la plupart du temps, *le nom du fichier NZB est le nom de la release*. Nommez le fichier comme vous nommeriez la release, car c'est ce que votre serveur multimédia va essayer de faire correspondre :

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/indexer_download_48213.nzb
```

Deux releases différentes qui finissent avec le même nom sont distinguées par un petit tag de hash (`Some.Release {a1b2c3}`), comme partout ailleurs dans zurg.

### Releases protégées par mot de passe {#password-protected-releases}

Si l'indexeur a enregistré le mot de passe de l'archive dans le bloc de métadonnées du NZB, zurg l'utilise lorsqu'il diffuse depuis le jeu de RAR :

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

Rien d'autre n'est nécessaire. Une release protégée dont le NZB ne contient pas de métadonnée de mot de passe ne peut pas être ouverte.

### Releases obfusquées {#obfuscated-releases}

Les posts dont les noms de fichiers sont aléatoires sont gérés, à un coût payé une seule fois au moment du scan. zurg essaie d'abord la source la moins coûteuse : le nom de fichier qu'un article déclare encore dans son propre en-tête yEnc, un article par fichier. Si ce n'est pas suffisant, il se rabat sur l'index PAR2 de la release, qui associe le vrai nom de chaque fichier au MD5 de ses 16 premiers KiB. Le nom et la taille exacte figurent tous deux dans l'en-tête de l'article, donc le scan peut répondre dès que cet en-tête arrive, pendant que le corps continue de se charger dans le cache pour une lecture ultérieure. Une release obfusquée est donc nommée et dimensionnée par les mêmes articles. zurg affiche ce qu'il a récupéré :

```
Recovered 27 filename(s) in Some.Release
```

Toute la passe de nommage est limitée à 90 secondes par NZB, donc un serveur injoignable ralentit un scan au lieu de le bloquer. Les noms sont fixés *avant* que la bibliothèque soit construite à partir d'eux, car la bibliothèque indexe les fichiers par nom et un renommage ultérieur les ferait perdre.

**Un post entièrement obfusqué n'a pas de vrai nom à récupérer.** Certains posteurs obfusquent avant de construire le jeu de récupération, donc l'index PAR2 restaure des noms eux-mêmes aléatoires (`aJPSgA7eYizyzjJXT.part01.rar`), et le fichier à l'intérieur de l'archive est aussi un hash. Rien dans le post ne dit de quelle release il s'agit ; seul le nom du NZB le dit. zurg présente donc la charge utile sous le nom de la release, comme le fait SABnzbd à la fin de la décompression :

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

Seul le fichier qui correspond clairement à la release est renommé : le plus gros élément de l'archive, et uniquement lorsqu'il fait au moins trois fois la taille du suivant, que son extension ne fait pas partie d'une structure de disque (`.vob`, `.m2ts`, `.mpls`), et que son nom ne dit rien. Les sous-titres et échantillons qui partagent son nom le suivent. Une archive contenant plusieurs fichiers de taille similaire, comme un pack de saison, est laissée telle quelle, car aucun d'eux n'est la release. Les noms internes de l'archive continuent de fonctionner comme adresses, donc un lecteur démarré avant un rescan ne perd pas le fichier.

### Remplacer et supprimer {#replacing-and-removing}

- **Supprimer** un NZB dans `nzbs/` retire la release de la bibliothèque, supprime son lecteur en cache ainsi que son cache d'articles, et oublie les octets réparés qu'elle contenait.
- **Supprimer une release Usenet depuis le Dashboard supprime le fichier `.nzb` du disque.** Il n'y a nulle part ailleurs où il pourrait être conservé. Ce n'est pas la même chose que supprimer un torrent d'un compte debrid, où le fichier reste chez le service.
- **Remplacer un NZB en place est la méthode la plus lente.** Écrire par-dessus un fichier ne modifie pas le répertoire, donc la surveillance ci-dessus ne peut pas le voir. C'est la vérification périodique des changements qui s'en charge : elle lit la date de modification du fichier et le réanalyse, à la première vérification `check_for_changes_every_secs` qui intervient plus de 15 secondes après la dernière lecture du répertoire (environ 30 secondes par défaut). Supprimer l'ancien fichier puis ajouter le nouveau est détecté en une ou deux secondes, et c'est de toute façon ce que fait un indexeur ou le point de terminaison SABnzbd.

## 4. Où atterrissent les releases dans le montage {#4-where-releases-land-in-the-mount}

Une release Usenet est une entrée de bibliothèque comme une autre. Tes filtres `directories:` existants s'appliquent donc à elle sans changement :

```yaml
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

En plus de ceux-là, le compte reçoit son propre dossier : `__nzb__` par défaut, ou `__<name>__` si tu définis `name:` sur l'entrée du fournisseur. Ce dossier n'est pas juste une vue : les lectures qui passent par lui sont **épinglées** au compte Usenet, sans aucun basculement. C'est donc le bon endroit pour vérifier que la lecture Usenet fonctionne sans qu'un compte debrid réponde discrètement à ta place. Si Usenet est ton seul compte, ce dossier n'apparaît pas dans la liste racine du montage, et `__all__` contient les mêmes fichiers. Teste donc la lecture sous `__all__` sur le montage, ou ouvre le chemin HTTP direct `http://localhost:9999/http/__nzb__/`.

Quatre points spécifiques à Usenet à connaître quand tu écris des filtres :

- **Les filtres de tags correspondent au contenu Usenet une fois analysé.** Chaque tag `zurg_*` (résolution, HDR, débit, durée, langue) vient de ffprobe. zurg lance lui-même ffprobe sur les fichiers Usenet, via son propre serveur et à un rythme que le serveur de news peut supporter. Une release Usenet reçoit donc ses tags comme les autres, une fois analysée. Jusque-là, un dossier défini par `tags_match_any` ne la retient pas.
- **Les fichiers `.par2` et `.sfv` sont masqués.** Ce sont des fichiers de réparation : zurg les lit lui-même, et aucun serveur média n'en a besoin, surtout quand un pack de saison en contient huit. Le `.nfo` est conservé, car Kodi, Emby et Jellyfin le lisent.
- **Les jeux de RAR sont du contenu, pas des archives à décompresser.** Les `.rar` et `.rNN` restent visibles, et un jeu de volumes apparaît dans le montage comme un *dossier* dont le contenu est celui des fichiers qu'il contient. zurg diffuse la vidéo directement depuis l'archive, sans rien extraire. Une release qui est *uniquement* un jeu de volumes remplace son propre contenu, sans dossier d'archive intermédiaire : le fichier utile se trouve directement dans le dossier de la release, là où un serveur média le cherche. Les fichiers publiés à côté du jeu, comme le `.nfo`, le `.txt` du posteur, les visuels et les sous-titres, restent aussi listés à cet endroit.
- **`force_select_playable_files` ne s'applique pas.** Un post Usenet est complet, il n'y a rien à sélectionner. Tous les fichiers de contenu sont déjà proposés.

Vérifie le résultat avant de passer par un serveur média. `http://localhost:9999/http/` est un index HTML simple de exactement ce que le montage va afficher :

+++ Linux et macOS
```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```
+++ Windows
Tape `curl.exe`, pas `curl` : dans Windows PowerShell 5.1, `curl` est un autre nom de `Invoke-WebRequest`.

```powershell
curl.exe -s http://localhost:9999/http/__nzb__/ | Select-Object -First 10
```
+++

---

## 5. Monter avec rclone {#5-mount-it-with-rclone}

### La voie facile : laisser zurg lancer rclone {#the-easy-path-let-zurg-run-rclone}

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg lance rclone avec un profil VFS déjà réglé pour son propre schéma de lecture (taille du tampon, dimensionnement des blocs, mode de cache, durée du dir-cache, délais d'attente), garde le montage actif et invalide les bonnes entrées dircache quand la bibliothèque change. `mount_path` est aussi le préfixe que zurg utilise pour dire à Plex quels chemins scanner, donc il faut le définir même si vous montez ailleurs.

Vérifiez :

+++ Linux
```bash
ls /mnt/zurg/
ls /mnt/zurg/__all__/
```
+++ macOS
```bash
ls /Volumes/Zurg/
ls /Volumes/Zurg/__all__/
```
+++ Windows
Lancez-le dans une fenêtre PowerShell sur votre bureau : le lecteur n'est visible que dans la session d'ouverture de session qui l'a monté ([les règles de session](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
Get-ChildItem Z:\
Get-ChildItem Z:\__all__\
```
+++

### La voie manuelle : votre propre rclone {#the-manual-path-your-own-rclone}

Si tu gères déjà rclone, pointe un remote WebDAV vers zurg :

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

+++ Linux
rclone ne crée pas le point de montage, et `/mnt` appartient à root :

```bash
sudo mkdir -p /mnt/zurg && sudo chown "$USER" /mnt/zurg
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ macOS
Il faut [macFUSE](../setup/macos.md#step-1-install-macfuse) et rclone depuis [rclone.org](https://rclone.org/downloads/) : le rclone de Homebrew ne peut pas monter. rclone ne crée pas le point de montage, et `/Volumes` appartient à root :

```bash
sudo mkdir -p /Volumes/Zurg && sudo chown "$USER" /Volumes/Zurg
rclone mount zurg: /Volumes/Zurg --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++ Windows
Il faut [WinFsp](https://winfsp.dev). La lettre de lecteur ne doit pas être déjà utilisée, et seuls les programmes de la session de connexion qui lance rclone la voient ([les règles de session](../setup/windows.md#keeping-it-running-the-session-rules)).

```powershell
rclone mount zurg: Z: --config rclone.conf --dir-cache-time 10s --vfs-handle-caching 0
```
+++

`--vfs-handle-caching 0` demande rclone 1.74 ou plus récent, et empêche rclone de continuer à télécharger pendant cinq secondes après qu'un lecteur a fermé un fichier. Le README explique ce que ça coûte de s'en passer.

Pense quand même à définir `mount_path` dans `config.yml` avec l'endroit où tu l'as monté, sinon les notifications de scan du serveur média seront construites avec le mauvais préfixe.

### Docker

Le répertoire de travail de zurg dans l'image est `/config`, et le dossier de surveillance ainsi que le cache de réparation s'y trouvent. Un seul montage bind les embarque avec le reste :

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./:/config
    ports:
      - 9999:9999
```

Si tu déposes un NZB dans `./nzbs` sur l'hôte, il est alors pris en compte à l'intérieur du conteneur sans redémarrage.

Cela demande un hôte Linux pour le montage. Docker Desktop sur macOS et Windows fait tourner le conteneur dans une VM, et le montage n'atteint ni Finder, ni Explorer, ni un Plex installé sur l'hôte. Utilise plutôt le binaire [macOS](../setup/macos.md) ou [Windows](../setup/windows.md) dans ce cas ([pourquoi](../setup/docker.md)).

> Les installations faites avant que `/config` monte en bind `/app/config.yml`, `/app/nzbs` et `/app/data` séparément continuent de fonctionner exactement comme avant. Voir [docker.md](../setup/docker.md#upgrading-an-install-that-mounted-app).

---

## 6. Connecter Plex {#6-point-plex-at-it}

Rien ici n'est spécifique à Usenet, sauf la dernière sous-section, mais l'ordre compte.

1. **Donne à zurg tes identifiants Plex**, pour qu'il puisse demander à Plex de ne scanner que les chemins modifiés, au lieu de te laisser attendre un scan complet périodique. Le plus simple est de passer par le flux d'authentification Plex du Dashboard, qui écrit les valeurs dans `config.yml` :

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **Ajoute des bibliothèques qui pointent vers des sous-dossiers du montage**, jamais vers la racine du montage :

   - Films → `/mnt/zurg/movies` (`/Volumes/Zurg/movies` sur macOS, `Z:\movies` sous Windows)
   - Séries TV → `/mnt/zurg/shows` (`/Volumes/Zurg/shows` sur macOS, `Z:\shows` sous Windows)

   Sous Windows, Plex ne voit `Z:` que s'il tourne dans la même session d'ouverture de session que zurg, ce que te donne la tâche de connexion de `zurg setup` : voir [les règles de session](../setup/windows.md#keeping-it-running-the-session-rules).

   La même version apparaît dans chaque dossier dont le filtre correspond, ainsi que sous `__all__` et `__nzb__`. Si tu pointes Plex vers la racine, il scanne plusieurs fois le même fichier.

3. **Règle deux options de bibliothèque** dans Edit → Advanced de chaque bibliothèque :

   - **Décoche "Empty trash automatically after every scan".** C'est celle qui compte vraiment. Si le montage flanche pendant que Plex scanne (un redémarrage de zurg, un remontage rclone), Plex conclut que tous les fichiers ont été supprimés. Avec la vidange automatique activée, ils sont supprimés définitivement et tout de suite ; désactivée, ils restent dans la corbeille et reviennent quand le montage revient. Ça m'a déjà coûté une bibliothèque de 30 000 éléments.
   - **Décoche "Generate video preview thumbnails".** Chaque vignette est une recherche dans tout le fichier ; sur Usenet, cela revient à lire toute la release à travers ton quota de connexion.

4. **Ne redémarre jamais zurg pendant un scan Plex.** Vérifie avant de le faire :

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}' | tr -d "\"'")
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   Sous Windows, dans PowerShell depuis le dossier de zurg :

   ```powershell
   $TOKEN = ((Select-String -Path config.yml -Pattern '^plex_token:').Line -split '\s+')[1].Trim('"', "'")
   (Invoke-RestMethod "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN").MediaContainer.size
   @((Invoke-RestMethod "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN").MediaContainer.Directory | Where-Object refreshing -eq 1).Count
   ```

   Des sessions à `size="0"` (`0` sous Windows) et un compteur qui reste à `0` en se rafraîchissant signifient que c'est sans danger. Si la ligne des sessions n'affiche rien du tout, Plex a refusé le jeton ou n'a pas répondu, et le `0` en dessous ne veut rien dire : vérifie `plex_token` avant de redémarrer. (PowerShell affiche le refus sous forme d'erreur `401` à la place.) (Utilise `grep -o … | wc -l`, pas `grep -c` : grep renvoie un code non nul quand il ne trouve rien, ce qui est le *bon* cas, et il ferait échouer une chaîne `&&` juste avant le redémarrage qu'elle devait protéger.)

5. **Scans partiels.** `on_library_update` reçoit chaque chemin modifié ; `plex_update.sh`, à la racine du dépôt, sert de script de référence :

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

   Le script a besoin de `curl`, `xmllint` et `python3`, que l'image Docker fournit, et de sa ligne `zurg_mount` réglée sur ton chemin de montage. Sous Windows, le hook tourne dans PowerShell et non dans `sh`, donc ce script ne fonctionne pas là-bas. Chaque chemin modifié arrive comme un élément de `$args`, relatif au montage et avec des barres obliques (`movies/Big Buck Bunny`) ; transmets-les à un script PowerShell avec `@args` :

   ```yaml
   on_library_update: '& C:\zurg\my_update.ps1 @args'
   ```

   zurg demande déjà à Plex de scanner les chemins modifiés une fois l'étape 1 faite et `mount_path` défini, donc un hook n'est nécessaire que pour autre chose.

**Ce que Plex n'obtiendra pas du contenu Usenet :** rien tant que zurg ne l'a pas analysé (voir la section 4), donc Plex peut faire sa propre analyse à la première lecture, comme pour n'importe quel fichier local. Les tailles de fichiers se stabilisent peu après le scan d'une release : la première liste peut afficher une estimation peu coûteuse basée sur le nombre d'articles, et la longueur exacte arrive ensuite, depuis l'index de récupération quand il existe, sinon en lisant un article par fichier. Pour une grosse archive multi-volumes dont l'index de récupération indique déjà chaque longueur exacte, un volume vérifié peut établir le pas commun des articles ; chaque volume voisin vérifie cette déduction avec son propre en-tête avant de servir son premier octet. Une fois une longueur enregistrée, la bibliothèque est prévenue que la release a changé, pour que le montage et Plex voient tous deux la vraie longueur. zurg dimensionne jusqu'à huit releases à la fois (jamais plus que le nombre de connexions du compte) sur un compte de douze connexions ou moins, et davantage sur un compte plus grand (douze sur 16 connexions, seize à partir de 20). Quand l'acquisition vérifie une release auprès des serveurs de news, cette vérification se met en file à côté de ce dimensionnement et de la lecture anticipée, et ne prend jamais la connexion réservée à une lecture qu'un lecteur attend.

### Jellyfin / Emby / Infuse

Jellyfin et Emby prennent `jellyfin_server_url` / `jellyfin_token` et `emby_server_url` / `emby_token` et reçoivent les mêmes notifications de scan ; voir [jellyfin.md](jellyfin.md). Infuse peut pointer directement sur `http://<host>:9999/dav/` et te passer complètement de rclone.

---

## 7. Quand un article manque {#7-when-an-article-is-missing}

C'est le mode de défaillance qu'a Usenet et que le debrid n'a pas. Les articles sortent de la rétention d'un fournisseur ou sont retirés, et une release peut être parfaitement listée alors que quelques-uns de ses articles ont disparu.

La réponse de zurg, par ordre de préférence :

1. **Demander à un autre serveur de news.** Un article qu'un fournisseur a laissé expirer se trouve très souvent encore chez un autre. Ce n'est qu'un seul téléchargement : voir [Plus d'un fournisseur Usenet](#more-than-one-usenet-provider).
2. **Le reconstruire à partir des fichiers PAR2 de la release.** C'est pour cela qu'ils sont publiés. Cela coûte une lecture de la *release entière*, car Reed-Solomon doit combiner chaque tranche restante pour en retrouver une manquante. Donc sur une publication de 200 Go, cela représente 200 Go de lecture pour récupérer quelques mégaoctets.
3. **Servir du silence.** Seulement quand aucune des deux solutions précédentes ne peut répondre.

La réparation PAR2 est une tâche de fond, au maximum deux releases à la fois, et elle a besoin de :

```yaml
enable_repair: true            # the default; set false to turn PAR2 repair off
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

Les octets reconstruits sont écrits sous `data/par2/<nzb-id>/` et repris quand le fichier est à nouveau ouvert. Un redémarrage ne coûte donc pas une relecture complète de la release. Seules les portions réellement manquantes sont conservées (une release endommagée coûte en général quelques mégaoctets), et les releases entières sont supprimées en commençant par les moins récemment utilisées quand le budget est dépassé. Chaque portion d'une release est marquée avec la date de modification du NZB à partir duquel elle a été reconstruite. Si vous réenregistrez le NZB, ces portions sont donc supprimées au lieu de servir des octets dont les décalages ont peut-être changé.

Une réparation s'annonce, puis indique ce qu'elle a coûté :

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s on the avx2 kernel, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

Deux points à connaître :

- **La lecture passe toujours avant une réparation.** Les connexions sont attribuées selon qui attend : une lecture demandée en premier, puis la lecture anticipée, et la réparation en dernier. Il y a cependant une exception : une réparation se voit garantir un quart du quota face à la lecture anticipée, afin que le fichier en cours de lecture puisse encore réparer le trou où il est bloqué.
- **La réparation au niveau de la bibliothèque de zurg ne peut pas aider ici.** Ce mécanisme rajoute un torrent sur le compte d'où il vient. Un backend qui ne peut pas ajouter de contenu peut donc signaler une release cassée, mais ne peut pas la réparer. Pour Usenet, le PAR2 *est* la réparation.

Une release sans fichier PAR2 dans son NZB et sans second compte de news n'a aucun moyen de récupération. C'est une propriété de la publication, pas de zurg.

---

## Performances {#performance}

| | |
|---|---|
| Flux unique, fichier direct | ~100 Mbit/s |
| Flux unique, depuis un jeu RAR | 90–106 Mbit/s |
| Deux flux simultanés, cumulé | ~124 Mbit/s |

Le quota de connexions fixe le premier plafond du débit d'un flux unique. zurg garde ce quota chargé en dimensionnant la lecture anticipée en articles et en octets : les posts d'archives à petits articles reçoivent au moins 64 MiB d'avance, tandis que les posts de plusieurs mégaoctets gardent la fenêtre connexions-et-pipeline qu'ils avaient déjà. Donc :

- **Mets `connections` au nombre réel de ton forfait.** C'est le réglage principal. Huit connexions ne suffiront pas pour streamer un remux.
- **Deux comptes principaux s'additionnent.** Les lectures sont pilotées par le quota combiné des comptes non-`backup` qui partagent la plus petite `priority` active. Donc un second fournisseur illimité à la même priorité relève aussi le plafond, en plus de couvrir les trous de rétention du premier. Un compte `backup` ne compte pas dans ce total.
- **`warm_connections` (4 par défaut) achète de la latence, pas du débit.** Il garde ce nombre de connexions ouvertes, inactives et authentifiées, pour que la première lecture après un démarrage ou une période calme ne passe pas ~0,8 s à se connecter avant son premier octet : 1,5 s jusqu'au premier octet à froid contre 0,15 s à chaud. Une fois un flux lancé, il ne change rien.
- **Les connexions qui s'ouvrent restent sur un même backend, donc leurs sessions TLS reprennent.** Ouvrir une connexion coûte environ 0,8 s. Mesuré sur un vrai serveur news le 2026-08-29 : 106 ms de TCP, 213 ms de handshake TLS, 256 ms de greeting, 218 ms pour les deux échanges `AUTHINFO`. Le nom d'hôte d'un fournisseur est une rotation (celui-là se résout en 11 adresses) et un ticket de session TLS n'est valable que sur la machine qui l'a émis. Donc reconnecter à l'adresse que le résolveur a citée en premier n'a repris **0 sessions sur 3**, alors que reconnecter à la même adresse en a repris **3 sur 3**. Chaque compte reconnecte désormais à l'adresse de sa dernière connexion, ce qui fait gagner **110–140 ms à chaque reconnexion** : un handshake repris prend 109–141 ms contre 225–261 ms pour un handshake complet. Un serveur avec un aller-retour d'environ 18 ms gagne moins. L'épingle est relâchée et le nom est de nouveau résolu dès que cette adresse cesse de répondre, donc rien ne reste collé à une machine que le fournisseur a retirée. Un refus qui arrive jusqu'au NNTP (le compte à son plafond de connexions, un mot de passe rejeté) garde l'épingle, car c'est la réponse du compte et non celle du backend. Chaque ouverture de connexion journalise ses phases au niveau debug, `resumed=` compris.
- `cache_size_mb` (512 par défaut) est partagé entre tous les fichiers en cours de lecture. Augmente-le si tu lances plusieurs flux simultanés ; ça ne rend pas un flux unique plus rapide. Les lectures spéculatives peuvent réserver au maximum la moitié de ce cache, pour au plus deux lecteurs, afin de laisser l'autre moitié aux articles déjà consommés ou sur le point de l'être.
- Que la release soit en RAR ou publiée en fichiers simples ne compte plus beaucoup pour le débit.

**Un article lent ne bloque plus le flux.** Une lecture séquentielle qui fait en moyenne ~90 Mo/s tombe quand même à 1–5 Mo/s pendant environ une seconde à la fois. Chacune de ces chutes a la même cause : un article cesse d'arriver pendant que les autres connexions finissent les leurs et restent inactives. Quand une lecture reste bloquée sur un article plus longtemps que ce que ce lecteur a appris à attendre, zurg demande le même article à une **seconde connexion** et sert la réponse qui arrive en premier. Un lot pipeliné bloqué peut bloquer plusieurs articles consécutifs de la tête de lecture sur le même socket mort. Donc jusqu'à cinq articles distincts d'un même lecteur peuvent être doublés ensemble, ou un ou deux sur un post dont les articles font moins de 1 MiB. Un article n'est jamais demandé deux fois. Le compte paie au maximum 20 demandes secondes par minute. Le délai reste deux fois l'attente récente du lecteur, jamais sous 250 ms (125 ms pour les posts dont les articles font moins de 1 MiB) et jamais au-delà de 2 s. Seule une lecture qu'un client attend réellement est doublée : l'anticipation, le préchargement du volume suivant et la réparation ne le sont pas. Un article que les serveurs viennent de *refuser* n'est pas non plus doublé. Celui-là attend déjà sa confirmation une seconde plus tard, et demander dans cette fenêtre ne prouve rien. Chaque doublon écrit une ligne au niveau debug indiquant combien de temps la lecture a bloqué, et la ligne suivante dit si la seconde demande a gagné.

Pour les plages déclarées, l'article de la tête de lecture entre dans l'ordonnanceur de priorité avant que les octets suivants ne soient proposés. Les connexions pipelinées reçoivent ensuite des tours d'articles consécutifs plutôt que des morceaux contigus, donc les premiers articles utiles sont répartis sur tout le quota. Une requête d'au moins 64 MiB est traitée comme de la lecture et obtient toute la frontière de plage. Une petite recherche reste une sonde et n'ouvre qu'une rampe étroite.

### Franchir une limite de volume {#crossing-a-volume-boundary}

Un fichier à l'intérieur d'un jeu RAR est servi un volume à la fois, et chaque volume est une lecture séparée sur le compte Usenet. zurg ouvre le volume suivant pendant que le volume en cours est encore en lecture et lit ses quatre premiers mégaoctets, donc un passage d'un volume à l'autre ne démarre pas à froid. Sur une release postée en petits volumes, ces premiers mégaoctets ne suffisent pas à eux seuls : quatre mégaoctets représentent environ dix articles d'une release postée en parties de ~395 KB, et des volumes de ~26 MB créent une frontière toutes les 1,7 seconde de lecture. Le flux vidait donc la tête préchargée de la mémoire en un quart de seconde, puis attendait un aller-retour pour tout ce qui suivait. Mesuré sur un Hetzner CCX23 avec dix connexions le 8 septembre 2026, ce release diffusait à **14–16 MB/s**, alors qu'un fichier classique sur le même compte atteignait **86–99 MB/s**. Son débit à la seconde oscillait entre 1 et 29 MB/s, pendant que 46 à 55 des 60 emplacements de lecture anticipée du compte restaient inutilisés.

zurg préchauffe désormais le volume suivant sur toute une fenêtre de lecture anticipée dès que le flux arrive à moins de 32 MiB de la frontière. Un volume dans lequel le flux vient d'entrer garde la fenêtre qu'il a gagnée au lieu de repartir à deux articles. Un volume que la tête de lecture n'atteindra pas avant plusieurs secondes n'est toujours préchauffé que sur sa tête. Cela évite qu'un scan de bibliothèque (un lecteur par entrée, quelques mégaoctets de chacune) ne tire une fenêtre de chaque volume suivant qu'il ne lira jamais. Rien à configurer, et cela ne change aucun plafond mémoire : un compte garde toujours deux fenêtres de lecture anticipée à la fois, le volume en cours de lecture et celui en préchauffage, à l'intérieur de `cache_size_mb`.

Les réparations sont lentes par nature, car elles lisent toute la release, mais elles tournent en priorité basse et sont limitées par le serveur Usenet plutôt que par le calcul de zurg.

### Mémoire : ce que coûte un dossier surveillé {#memory-what-a-watch-directory-costs}

Un NZB est une liste d'articles, et une grosse bibliothèque, ça fait beaucoup d'articles. Parser un NZB garde en mémoire leurs identifiants de messages et leurs décalages, pour qu'une lecture puisse les retrouver. Les versions précédentes gardaient tous ces éléments en mémoire pendant toute la durée de vie du processus. Mesuré sur un répertoire surveillé de 2,636 NZB, soit 27.6 millions d'éléments `<segment>`, cela représente **1.52 Go de tas actif**, environ 58 octets par article, en plus du cache d'articles. Or presque rien n'est utilisé : un listing n'a besoin que des noms, des tailles et des nombres, et seul un fichier en cours de lecture ou de réparation doit connaître le nom de ses articles.

`nzb_segments` décide si zurg les conserve :

```yaml
nzb_segments: mmap             # mmap (default) | reparse | resident
nzb_segments_idle_secs: 120    # how long a release's articles are kept after the last read
```

- **`mmap`** — les listes sont écrites dans `data/nzb-index/<id>.bin`, et ce fichier est mappé à la demande. Les octets restent alors dans le cache de pages plutôt que sur le tas de zurg, et le noyau peut les récupérer sous pression mémoire. **La valeur par défaut sous Linux, macOS et BSD.** Cela coûte à peu près autant d'espace disque que les listes elles-mêmes.
- **`reparse`** — les listes sont rendues une fois qu'une release s'est stabilisée, et le NZB est relu depuis le disque quand une lecture ou une réparation en a besoin. Cela ne coûte aucun espace disque, et c'est la raison de le choisir : un hôte où `data/` ne doit pas grossir.
- **`resident`** — toutes les listes d'articles en mémoire, en permanence. **Le comportement précédent**, celui de toutes les versions antérieures. Toujours pris en charge, mais ce n'est plus la valeur par défaut.

Quel que soit le réglage, un listing ne charge jamais rien : le nom, la taille et le nombre d'articles d'un fichier sont fournis sans que la liste d'articles ne soit proche de la mémoire. Un rafraîchissement de bibliothèque, une vérification d'empreinte et une requête *arr demandant si un job est stabilisé restent donc gratuits. Ce que coûtent les modes paresseux, c'est la première lecture d'une release que personne n'a touchée depuis `nzb_segments_idle_secs` (un balayage tourne toutes les 30 secondes). De plus, l'ensemble des fichiers d'une release se charge d'un coup : parcourir les volumes rar d'un season pack dans l'ordre ne paie donc ce coût qu'une fois.

Mesuré sur une release de 60 fichiers et 30,000 segments :

| | tas par release | première lecture d'une release inactive | par article sur le chemin de lecture |
|---|---|---|---|
| `resident` | 1.74 MB | — | 6 ns |
| `reparse` | 21.3 kB | 39 ms | 52 ns |
| `mmap` | 16.6 kB | 0.27 ms | 63 ns |

Cinquante nanosecondes par article, c'est peu de chose à côté des millisecondes nécessaires pour récupérer un article. Le chiffre à peser est donc le rechargement. `reparse` relit et reparse tout le document XML, ce qui prend des dizaines de millisecondes sur un season pack avant que le moindre octet ne bouge. `mmap`, lui, fait un appel `mmap`, un en-tête de slice par fichier et une somme de contrôle de l'index qu'il vient de mapper. Cela représente 0.08 ms sur les trois, et les 0.19 ms restants sont le prix de la détection d'un octet corrompu, plutôt que de le servir comme identifiant de message.

Et sur une bibliothèque entière plutôt qu'une seule release (2,636 NZB, 27.6 millions d'articles, le même binaire lancé trois fois sur le même corpus, au repos après un scan) :

| | ensemble résident | tas actif | CPU au repos | ouverture à froid, p50 | index sur disque |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Les ouvertures à chaud (1 ms), le débit de streaming (38–39 MB/s) et le temps de démarrage étaient indiscernables entre les trois modes. `mmap` ouvre une release à froid *plus vite* que si tout était gardé en mémoire, parce qu'une release jamais ouverte depuis le démarrage doit aussi être parsée sous `resident`. Or mapper une arène déjà écrite est un simple appel système, alors que parser des mégaoctets de XML ne l'est pas.

L'index se réécrit dès que le NZB change, et se répare lui-même s'il devient illisible : il revient alors au NZB et le réécrit. Il est supprimé quand le NZB quitte le répertoire surveillé. Son en-tête et son contenu sont tous deux protégés par une somme de contrôle, donc un octet corrompu est détecté au lieu d'être servi comme un identifiant de message que personne n'a jamais posté. Sa taille actuelle figure sur la page d'accueil du Dashboard, sous **Article Index**, ainsi que dans la ligne que le backend écrit au démarrage. Sous **Windows**, il n'y a pas de mapping : l'index serait lu dans le tas à la place, ce qui revient à la mémoire résidente *plus* un rechargement. La valeur par défaut y reste donc `resident`, et `reparse` est le mode paresseux qui vaut la peine d'être choisi.

## Dépannage {#troubleshooting}

| Symptôme | Cause | Solution |
|---|---|---|
| `Cannot reach the news server for nzb` au démarrage | Mauvais couple hôte/port/TLS, identifiants incorrects ou forfait inactif | `563` va avec `tls: true`, `119` avec `tls: false` ; vérifie ensuite les identifiants |
| La bibliothèque est vide, aucune ligne `Loaded NZB` | Dossier `nzbs/` absent ou au mauvais endroit | Il est relatif au **répertoire de travail** de zurg. Vérifie `WorkingDirectory=` dans ton unit systemd, ou le répertoire monté sur `/config` dans Docker, qui est `nzbs/` à côté du fichier compose. Seule une installation antérieure à `/config` surveille `/app/nzbs` |
| Un NZB n'apparaît jamais | Dans un sous-dossier, nommé `.nzb.gz`, ou non analysable | Place-le directement dans `nzbs/` et décompresse-le. Vérifie dans le log s'il y a un avertissement `Skipping` |
| La release apparaît avec un nom inutilisable | Le nom du fichier NZB sert de nom, faute de `<meta type="name">` | Renomme le `.nzb` avec le nom de la release |
| Les fichiers ont des noms aléatoires dans la release | Post obfusqué dont la récupération a échoué | Cherche `Recovered N filename(s)`. Sans fichiers PAR2 dans le NZB, il n'y a aucune source pour les vrais noms |
| La vidéo garde un nom aléatoire, mais le dossier est bon | Post entièrement obfusqué, dont l'archive contient plusieurs fichiers de taille similaire | Seule une charge utile unique et claire est renommée d'après la release. Un pack de saison dans une seule archive garde les noms donnés par l'archive |
| Le streaming est lent | `connections` laissé à la valeur par défaut, 8 | Mets-le à la limite de ton forfait |
| La première lecture après une période calme met une seconde à démarrer, puis tourne bien | Le plancher de préchauffage est désactivé, ou ramené à zéro par un compte à une seule connexion | Laisse `warm_connections` non défini (sa valeur par défaut est 4) et vérifie que ni lui ni le `warm_connections` de niveau supérieur n'a été mis en négatif |
| Connexions refusées par le fournisseur | `connections` supérieur à ce que le forfait permet | Baisse-le à la vraie valeur |
| La lecture saccade ou un trou joue en silence | Articles manquants | Cherche `PAR2 repair of …` dans le log, vérifie `enable_repair: true` et ajoute [un autre fournisseur Usenet](#more-than-one-usenet-provider) |
| Un trou reste silencieux et aucune ligne de réparation n'apparaît jamais | `enable_repair` désactivé, ou le NZB ne contient aucun fichier `.par2` | Mets `enable_repair: true`. Si le post n'a pas de fichiers de récupération, seul un autre compte news peut aider |
| Un second fournisseur ne semble jamais être interrogé | Les deux comptes ont le même `backbone`, donc le second est ignoré dès que le premier signale l'article comme absent | Corrige les valeurs de `backbone`. Seuls les comptes vraiment sur un même spool doivent partager un nom |
| Un compte sur plusieurs est mort, mais le démarrage semblait correct | Le démarrage n'échoue que si *tous* les comptes sont injoignables | Cherche `is not reachable` dans le log. Chaque mauvais compte signale son nom |
| Un compte à volume est facturé pour des articles que le compte illimité possède | `backup: true` absent sur celui-ci | Mets-le. Un primaire simplement occupé ne fera plus basculer les lectures sur le compte facturé au volume |
| Une release manque dans un dossier filtré par tag | Elle n'a pas encore été analysée, donc elle n'a aucun tag `zurg_*` | Attends l'analyse, ou lance Analyze & Tag Library depuis le Dashboard |
| Fichiers `.par2` invisibles dans le montage | Voulu, ils sont masqués comme échafaudage de réparation | Rien à corriger, zurg les lit quand même |
| Tu as modifié un fournisseur dans le Dashboard et rien ne s'est passé | Les changements de fournisseur sont écrits dans `config.yml` mais non rechargés à chaud | Redémarre zurg. La bannière sous le tableau des fournisseurs le précise |
| Plex a vidé la bibliothèque après un redémarrage de zurg | Un scan était en cours pendant que le montage était absent, avec auto-empty-trash activé | Désactive l'auto-vidage, et avant tout redémarrage, arrête les sessions *et* mets l'état à jour |
| La taille d'un fichier a légèrement changé peu après l'apparition de la release | Le premier listing ne peut estimer qu'à partir du nombre d'articles. La longueur exacte arrive ensuite, depuis l'index PAR2 ou l'en-tête yEnc du fichier | Normal, et ça se stabilise une fois. La longueur est écrite dans `data/nzb-sizes/` et conservée jusqu'à ce que le NZB change |

### Demander à propos d'un seul article {#asking-about-one-article}

`GET /debug/nzb/probe` pose une seule question aux comptes news, en passant par le pool que zurg utilise déjà, avec la priorité d'une lecture à la demande. Cette route existe parce que l'alternative ne marchait pas : un compte n'accorde que huit connexions, et zurg les occupe toutes. Tester un post à la main obligeait donc à utiliser un second compte ou à arrêter le serveur, et arrêter le serveur détruit l'état que l'on veut diagnostiquer. Sous Windows, tape `curl.exe` au lieu de `curl` dans ces commandes.

```bash
# Is this article still there? A STAT, so nothing is transferred.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?message_id=abc@news.example'

# The same question addressed the way you have it: a release id from the
# library, a file index counting from zero, an article number counting from one.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&file=0&article=3'

# &body=1 fetches the one article and reports what actually arrived against what
# the article says should have. This is how a provider that strips trailing
# bytes is identified: `short: true` with `decoded_bytes` below `span_bytes`.
curl -u user:pass 'http://localhost:9999/debug/nzb/probe?release=<nzb id>&article=3&body=1'
```

Elle répond `{"probes": [...]}` avec un objet pour le fournisseur `nzb`, contenant `found`, `missing` et le temps écoulé. Elle interroge les comptes news par ordre de priorité jusqu'à ce que l'un d'eux ait l'article (un compte de secours n'est sollicité que si les comptes principaux échouent). Elle n'indique pas quel compte news a fourni l'article. Elle est en lecture seule : rien de ce qu'elle récupère n'entre dans le cache d'articles, et un article introuvable n'est pas enregistré comme mort. Un probe ne peut donc pas faire taire un fichier qui fonctionne.

---

Toujours bloqué ? Pose ta question sur le forum **zurg-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../../guides/remote-help.md) indique quoi inclure.

## Voir aussi {#see-also}

- [config.md](../reference/config.md) — chaque option, y compris la [référence des comptes Usenet](../reference/config.md#usenet-accounts) et la [référence des filtres de répertoires](../reference/config.md#7-directories--filters)
- [plex.md](plex.md) — comment zurg pilote l'analyse, la correspondance et le nettoyage de la corbeille dans Plex
- [jellyfin.md](jellyfin.md) — intégration Jellyfin
- [docker.md](../setup/docker.md) — configuration Docker, propagation FUSE et dépannage
- [tags.md](../reference/tags.md) — le système de tags
- [architecture.md](../internals/architecture.md) — `internal/nzb` et `internal/nntp` dans leur contexte
