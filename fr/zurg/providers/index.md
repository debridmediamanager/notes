# Fournisseurs {#providers}

Un fournisseur est un compte à partir duquel zurg construit sa bibliothèque. Chaque compte correspond à une entrée sous `providers:` dans `config.yml`. Tu peux en utiliser un seul ou en utiliser six. Une release présente chez plusieurs d'entre eux n'apparaît qu'une fois et est lue depuis le compte capable de la servir au moment voulu.

| Service | `type` | Page |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

Trois pages vont plus loin que la configuration de base. [TorBox limits](torbox-limits.md) présente les chiffres mesurés derrière le bridage de TorBox. [TorBox news server](torbox-news-server.md) et [ElfHosted news server](elfhosted-news-server.md) décrivent ce que sont réellement les comptes Usenet inclus avec ces offres. Évalue-les à partir de ces pages avant d'utiliser un emplacement de fournisseur pour l'un d'eux.

Toutes les pages ici supposent l'installation en conteneur décrite dans [Docker setup](../setup/docker.md). `~/zurg` est le dossier compose sur l'hôte. `/config` est ce même dossier vu depuis l'intérieur du conteneur. Il n'existe qu'un seul `config.yml`, et les deux noms y mènent.

Sur une installation binaire sous Linux, macOS ou Windows, [Setup](../setup/index.md) indique ce qui remplace `docker compose restart zurg` et la ligne `setup`. Les vérifications se traduisent de la même façon. Lance-les depuis le dossier de zurg. Lis `logs/zurg.log` au lieu de `docker compose logs` (`Get-Content logs\zurg.log -Tail 100 -Wait` dans PowerShell). Lance `./zurg doctor` (`.\zurg.exe doctor`) sans `--working-dir /config`. Remplace `/zurg_mnt/zurg` par ton propre point de montage : `/mnt/zurg`, `/Volumes/Zurg` ou `Z:\`, sauf si tu as modifié `mount_path`. Dans Windows PowerShell 5.1, tape `curl.exe`, et non `curl`.

## Trois façons d'ajouter un compte {#three-ways-to-add-an-account}

Lequel tu veux dépend de si `config.yml` existe déjà.

### Sur une installation neuve, utilisez setup {#on-a-fresh-install-use-setup}

`zurg setup` demande quels fournisseurs configurer et ne demande que leurs identifiants. Il n'écrit les comptes **que s'il n'existe pas encore de `config.yml`**. Si vous le relancez plus tard, il met à jour l'installation sans toucher aux comptes que vous avez déjà.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Le sélecteur accepte des numéros ou des noms, et plusieurs à la fois.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

Rien de ce que vous tapez n'atterrit dans le fichier compose ni dans l'historique de votre shell. Le token est écrit directement dans `config.yml`, et le fichier n'est lisible que par son propriétaire.

### Sur une installation existante, utilisez le Dashboard {#on-an-existing-install-use-the-dashboard}

Ouvrez `http://localhost:9999/config/` et cliquez sur **Add provider** sous Essentials.
Choisissez le type. Collez le token. Enregistrez. Le Dashboard écrit l'entrée dans
le même `config.yml` à côté de votre fichier compose.

Les changements de provider nécessitent un redémarrage pour prendre effet. Le Dashboard l'indique
et le redémarrage se fait en une seule commande.

```bash
docker compose restart zurg
```

### Ou modifiez config.yml à la main {#or-edit-configyml-by-hand}

Le fichier est `~/zurg/config.yml` sur l'hôte. Ajoute l'entrée, puis redémarre.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` vaut `/zurg_mnt/zurg` dans un conteneur, et le fichier compose doit monter `/zurg_mnt:/zurg_mnt:rshared` pour que le montage arrive jusqu'à l'hôte. C'est la page [Docker setup](../setup/docker.md), et c'est la seule partie d'une installation en conteneur qui ne ressemble pas à une installation binaire.

## Installations sans surveillance {#unattended-installs}

Chaque fournisseur a une option de fichier de jeton et une variable d'environnement. Répète `--provider` pour chaque compte que tu veux.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | Option | Variable d'environnement |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` ou `TOKEN` ou `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` avec `--nntp-host` et `--nntp-username` | `NNTP_HOST` et les autres |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

`torbox_nzb` n'est jamais déduit de `TORBOX_TOKEN` ou de `--torbox-token-file` seul ; passe `--provider torbox_nzb`.

Avec `--non-interactive` et sans aucun `--provider`, la configuration prend celles de ces variables qui sont définies.

!!!warning Seul Real-Debrid est initialisé par le conteneur en cours d'exécution
Le démon zurg lui-même lit `TOKEN`, `RD_TOKEN` et `MOUNT_PATH` lors de l'exécution qui crée `config.yml`. C'est toute la liste. `TORBOX_TOKEN` et les autres sont lus par `zurg setup`. En mettre une dans le bloc `environment:` de ton compose et démarrer le conteneur ne fait rien à elle seule. Lance la configuration ou ajoute le compte dans le Dashboard.
!!!

## Ce qu'accepte chaque entrée {#what-every-entry-accepts}

| Clé | Ce qu'elle fait |
|---|---|
| `type` | Obligatoire. L'un des huit types ci-dessus. |
| `name` | Vaut par défaut `type`. Permet de distinguer deux comptes sur un même service. |
| `token` | La clé API. Non utilisée par `nzb`. |
| `disabled` | Met le compte en pause sans supprimer l'identifiant. |
| `watchlist` | Indique le compte sur lequel les nouveaux ajouts de torrents sont essayés en premier. |
| `add_torrents` | Si `false`, le compte continue de servir mais ne reçoit jamais rien de nouveau. |
| `warm_connections` | Connexions gardées ouvertes par hôte, pour qu'une lecture n'ait pas à en ouvrir une nouvelle. |

Les descriptions complètes et tout le reste se trouvent dans la [référence de configuration](../reference/config.md#accounts).

## Règles appliquées par le loader {#rules-the-loader-enforces}

- Les noms doivent être uniques. Deux comptes Real-Debrid ont besoin de `name: rd-main` et
  `name: rd-backup`, sinon le chargement échoue.
- Le nom `e` est réservé au routage des liens `.strm`. Choisis un autre nom.
- Une seule entrée peut définir `watchlist: true`.
- `watchlist: true` et `add_torrents: false` sur la même entrée sont refusés.
- Une seule entrée `nzb` ou `torbox_nzb` activée est prise en charge. Les serveurs de news supplémentaires vont sous `nntp.servers` d'une entrée `nzb`.
- Si toutes les entrées sont désactivées, le chargement échoue.
- Premiumize, Debrid-Link et Offcloud refusent `download_tokens` et un `strm_link_token` différent de `token`. Leurs identifiants de fichiers appartiennent à un seul compte, donc un second compte doit être une seconde entrée.

## Vérifier que ça fonctionne {#check-it-worked}

Commence par le log et le diagnostic.

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` est normal dans Docker, car Compose gère le démarrage automatique. Les avertissements ne font pas échouer doctor. Seul un `FAIL` le fait.

Ensuite, teste le compte lui-même depuis le Dashboard ou depuis le shell.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` signifie que l'identifiant a été authentifié. Le nom dans le chemin est le `name` du compte, qui vaut par défaut son `type`. Ajoute `-u user:pass` si tu as défini un `username` dans `config.yml`. Sans cela, le Dashboard et son API sont accessibles sans authentification sur le port que tu as publié.

Pour finir, regarde la bibliothèque sur le montage.

```bash
ls /zurg_mnt/zurg/__all__/
```

Chaque compte configuré a un répertoire `__<name>__`. Il contient tout ce que ce compte possède, et il force les lectures vers ce compte. `__torbox__/Some.Release/` ne diffuse que depuis TorBox, nulle part ailleurs. Le dossier propre à un compte unique n'apparaît pas dans la liste de la racine du montage, puisque `__all__` correspond à la même bibliothèque. Les chemins HTTP et WebDAV directs, comme `/http/__torbox__/`, répondent toujours. Via le montage, ils ne se résolvent plus : remplace donc `__<name>__` par `__all__` dans toute bibliothèque ou script qui l'utilisait.

Une grosse bibliothèque prend du temps à se charger la première fois. Tant que ce n'est pas fini, `/dav/movies/` répond 503 et le montage peut ne rien lister.

## Faire tourner plusieurs comptes {#running-several-accounts}

L'ordre de la liste `providers:` ne compte qu'à un seul endroit : c'est l'ordre dans lequel les comptes qui acceptent les ajouts sont essayés. Un compte avec `watchlist: true` est essayé en premier, quelle que soit sa position. Pour la liste et la lecture, l'ordre n'a aucune importance.

Deux choses utiles à savoir avant de pointer un serveur multimédia vers le résultat.

- La même release apparaît dans vos répertoires filtrés **et** dans chaque répertoire `__<name>__` qui la contient. Pointez Plex ou Jellyfin vers une partie du montage plutôt que vers la totalité, sinon il analysera plusieurs fois le même contenu.
- Il n'y a pas de basculement silencieux à l'intérieur d'un répertoire `__<name>__`. Un fichier mort sur un compte donne une erreur 404 dans ce répertoire et se lit depuis le répertoire d'un autre compte. Le reste du montage continue de le servir normalement.
