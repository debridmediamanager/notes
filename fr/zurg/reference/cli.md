# Ligne de commande {#command-line}

Le binaire zurg est le serveur et un ensemble d'outils. Lancez-le sans commande pour démarrer le serveur. Chaque commande accepte `--help` et affiche le texte sur lequel cette page est basée.

Exécutez les commandes depuis le répertoire de travail de l'instance. zurg lit `./config.yml` dans ce répertoire, sauf si vous passez `--config`. Ses dossiers de données et de logs sont aussi résolus par rapport à ce répertoire.

```
zurg [flags]
zurg [command]
```

## Options communes à toutes les commandes {#flags-every-command-takes}

| Flag | Ce que ça fait |
|---|---|
| `-c`, `--config` | Le fichier de configuration à lire. Par défaut `./config.yml`. |
| `-v`, `--version` | Affiche le build et quitte. La sortie correspond à `zurg version`. |
| `-h`, `--help` | Affiche l'aide de zurg ou celle d'une commande précise. |

## Installation {#setting-up}

### zurg setup

Il écrit une config et télécharge rclone et ffprobe. Puis il enregistre zurg pour qu'il démarre tout seul. Il te demande ce qui manque. `--dry-run` affiche le plan sans rien modifier.

Les clés et mots de passe sont lus depuis des fichiers. Ça les garde hors de ton historique de shell.

| Flag | Ce qu'il fait |
|---|---|
| `--provider` | Un fournisseur à configurer. Répète-le pour en mettre plusieurs. Un parmi realdebrid, torbox, alldebrid, nzb, premiumize, debridlink, offcloud, torbox_nzb. torbox_nzb lit sa clé depuis `--torbox-token-file` ou `TORBOX_TOKEN`, comme torbox. |
| `--realdebrid-token-file` | Lit le token Real-Debrid depuis ce fichier. Le même flag existe pour `torbox`, `alldebrid`, `premiumize`, `debridlink` et `offcloud`. |
| `--nntp-host` | Le serveur de news pour le fournisseur `nzb`. |
| `--nntp-port` | Son port. Par défaut 563 avec TLS et 119 sans. |
| `--nntp-tls` | Utilise TLS. Activé par défaut. |
| `--nntp-username` | Le nom d'utilisateur du compte de news. |
| `--nntp-password-file` | Lit le mot de passe du compte de news depuis ce fichier. |
| `--nntp-connections` | Le nombre de connexions autorisées pour le compte de news. Par défaut 8. |
| `--mount-path` | Où le montage apparaît. Par défaut, la convention de ta plateforme. |
| `--port` | Le port HTTP. Garde la valeur de la config si tu l'omets. |
| `--service-name` | Le nom du service ou de la tâche planifiée. Par défaut `zurg`. |
| `--service-scope` | `auto`, `user` ou `system`. Par défaut `auto`. |
| `--service-user` | L'utilisateur sous lequel tourne un service système. |
| `--no-service` | Configure tout mais n'enregistre pas le démarrage automatique. |
| `--no-start` | Enregistre le service mais ne le démarre pas. |
| `--skip-downloads` | Ne télécharge ni rclone ni ffprobe. |
| `--skip-prerequisites` | Saute la vérification de FUSE pour cette plateforme. |
| `--non-interactive` | Échoue au lieu de demander les infos manquantes. |
| `--dry-run` | Affiche le plan sans rien modifier. |

Chaque plateforme a son propre guide pas à pas.

- [Linux](../setup/linux.md)
- [macOS](../setup/macos.md)
- [Windows](../setup/windows.md)
- [Docker](../setup/docker.md)

### zurg doctor

Vérifie ce que l'installation a mis en place. Il lit la config et cherche rclone et ffprobe. Ensuite, il contrôle le service, le point de terminaison HTTP et le montage. Lance-le en premier quand quelque chose ne fonctionne pas.

| Option | Ce qu'elle fait |
|---|---|
| `--working-dir` | Le répertoire de travail de l'instance. Par défaut, le répertoire courant. |
| `--service-name` | Le nom du service à vérifier. Par défaut, `zurg`. |
| `--service-scope` | `auto`, `user` ou `system`. Par défaut, `auto`. |

### zurg service

Installe et contrôle le démarrage automatique sans lancer le reste de la configuration.

| Commande | Ce que ça fait |
|---|---|
| `zurg service install` | Installe le démarrage automatique et le lance. Passez `--start=false` pour installer sans lancer. |
| `zurg service uninstall` | Supprime le démarrage automatique. La configuration et les données restent. |
| `zurg service start` | Lance le service installé. |
| `zurg service stop` | L'arrête. |
| `zurg service restart` | Le redémarre. |
| `zurg service status` | Affiche l'état du démarrage automatique. |

Toutes prennent les mêmes options.

| Option | Ce que ça fait |
|---|---|
| `--name` | Le nom du service ou de la tâche planifiée. Par défaut `zurg`. |
| `--scope` | `auto`, `user` ou `system`. Par défaut `auto`. |
| `--user` | L'utilisateur sous lequel le service système s'exécute. |
| `--working-dir` | Le répertoire de travail dans lequel le service démarre. |
| `--executable` | Le binaire zurg que le service exécute. |

### zurg download-requirements

Télécharge rclone et ffprobe dans un dossier et écrit leurs chemins dans la configuration. Setup le fait pour toi, sauf si tu passes `--skip-downloads`.

| Flag | What it does |
|---|---|
| `--dir` | Où vont les binaires. Vaut `bin` par défaut. |
| `--rclone-version` | Une version de rclone, par exemple `1.67.0`. Vaut `latest` par défaut. |
| `--ffprobe-version` | Une version de ffprobe. Vaut `latest` par défaut. |

### zurg update

Remplace le binaire par la dernière nightly réservée aux sponsors. Le compte GitHub utilisé doit avoir un accès sponsor via [gatekeeper](https://gatekeeper.debridmediamanager.com/). Dans un conteneur, la commande refuse de s'exécuter, car la prochaine recréation supprimerait le nouveau binaire. Tire une nouvelle image à la place. `--force` effectue la mise à jour malgré tout.

Elle se connecte à GitHub via la GitHub CLI. Il s'agit de celle présente dans ton PATH, ou de celle que les installateurs placent dans `bin` à côté de zurg. Une connexion enregistrée par la GitHub CLI sans trousseau fonctionne même si la CLI elle-même n'est plus là. `GITHUB_TOKEN` fonctionne aussi. Si rien n'est trouvé, elle affiche la commande d'installation qui remet la GitHub CLI en place.

### zurg version

Affiche la version du build. `zurg --version` affiche la même chose.

## Obtenir de l'aide {#getting-help}

### Support de zurg {#zurg-support}

Envoie ton journal et ta configuration au support de DMM et affiche un code de support, comme `K7QM-3XPD`. Poste ce code dans ton fil de support sur Discord. Il est conservé 7 jours et seul le support de DMM peut l'ouvrir.

La commande envoie la même chose que **Export Logs** sur le tableau de bord, donc utilise-la quand zurg ne démarre pas ou que tu ne peux pas accéder au tableau de bord. Lance-la depuis le répertoire de travail de zurg : elle lit `config.yml` (ou `--config`) et `logs/zurg.log` à cet endroit. Avec Docker, lance `docker exec <container> /app/docker-entrypoint.sh support`, qui choisit automatiquement le bon répertoire. Si le conteneur ne reste pas démarré, lance `docker run --rm -v <your config folder>:/config ghcr.io/debridmediamanager/zurg:<tag> support` avec le même dossier que celui que tu montes pour zurg.

Les jetons, mots de passe, liens de téléchargement et tes propres noms d'hôte sont supprimés au préalable, de la même façon que le fait le tableau de bord. Une configuration qui ne se charge pas n'est pas envoyée ; c'est l'erreur qu'elle produit qui est envoyée à la place. Un journal long est tronqué à partir de son extrémité la plus ancienne pour tenir, et le paquet le signale.

Si le serveur de support de DMM est injoignable ou refuse l'envoi, zurg indique la raison et envoie les deux fichiers sur des sites de partage de texte public à la place, en affichant leurs liens. Si rien ne peut être envoyé du tout, il écrit les mêmes fichiers expurgés dans `zurg-debug.tar.gz` pour que tu puisses le joindre à ton fil.

## Sauvegardes {#backups}

### zurg backup

Écrit un fichier `.zurgbackup` qui contient ce que rien d'autre ne peut reconstruire. Il s'agit de la config avec ses tokens, de chaque `data/*.zurgtorrent` avec ses tags et ses liens de compte. Il contient aussi le store `__magic__` sous `data/local/` et les NZB sources sous `nzbs/`. Les caches, les snapshots Plex et les logs sont exclus, pour que la sauvegarde reste de la taille de ce qu'elle protège.

L'instance n'a pas besoin de tourner. Tu peux donc la planifier sans risque. Le fichier est une archive tar compressée en gzip qui contient tes tokens. Conserve-le comme un mot de passe.

| Option | Ce qu'elle fait |
|---|---|
| `-o`, `--out` | L'endroit où écrire le fichier. Par défaut, `zurg-<timestamp>.zurgbackup` dans le répertoire courant. |
| `--include-caches` | Ajoute aussi les métadonnées dérivées et les octets en cache pour une restauration à chaud. Les snapshots Plex et les logs restent exclus. Cela peut prendre beaucoup de place. |

### zurg restore-backup

Décompresse un `.zurgbackup` dans le répertoire courant. Chaque fichier est remis à son chemin d'origine. Arrête zurg d'abord. La restauration écrit des fichiers qu'une instance en cours d'exécution écrit aussi.

```
zurg restore-backup my-backup.zurgbackup
```

Une config déjà présente dans le répertoire est laissée intacte. Ce fichier contient les tokens dont dépend toute la bibliothèque. Passe `--force-config` pour l'écraser.

## Mesures {#measuring}

### zurg benchmark-my-setup

Lit de vrais octets comme le ferait un lecteur et affiche la dispersion plutôt qu'un seul chiffre.

Il tourne en trois phases. D'abord chaque compte seul. C'est le chiffre à comparer à ce que promet le service. Ensuite tous les comptes en même temps. Des comptes qui font chacun 70 MiB/s seuls et 25 MiB/s ensemble partagent une seule liaison montante saturée. Enfin il lit via le montage rclone. L'écart avec la première phase correspond au coût de FUSE et du VFS.

Les échantillons sont lus à des décalages aléatoires. Chaque couche en dessous met en cache, et relire un même décalage mesurerait le cache au lieu du lien.

Il n'ajoute ni ne supprime rien. Par contre, il consomme ta bande passante. Chaque compte lit la taille d'échantillon multipliée par le nombre d'itérations, deux fois. La phase de montage s'ajoute par-dessus.

| Option | Ce que ça fait |
|---|---|
| `-n`, `--iterations` | Échantillons par compte et par phase. Valeur par défaut : 3. |
| `--sample-mb` | MiB lus par échantillon. Valeur par défaut : 128. Utilise 1024 pour dépasser la montée en charge du chunk de lecture de rclone et obtenir un chiffre soutenu pour le montage. |
| `--provider` | Ne teste que ces comptes, par nom. Répétable. |
| `--skip-concurrent` | Saute la phase avec tous les comptes. |
| `--skip-mount` | Saute la phase de montage. |
| `--json` | Affiche le rapport au format JSON. |

### zurg network-test

Mesure la rapidité avec laquelle cet hôte atteint chaque serveur de téléchargement Real-Debrid en IPv4 et en IPv6. Les résultats vont dans `logs/network-test.log` et dans `data/`, où le serveur les lit pour choisir ses hôtes. Définissez `PROXY` dans l'environnement pour passer le test par un proxy.

| Option | Ce qu'elle fait |
|---|---|
| `-t`, `--test-url` | Une URL de fichier dont le chemin est récupéré sur chaque serveur, au lieu du fichier de test de vitesse de Real-Debrid. |

## Plex

Ces trois outils fonctionnent avec le serveur Plex de cet hôte. Configurez d'abord Plex. Voir [Intégration Plex](config.md#plex-integration).

### zurg plex-settings

Signale les réglages Plex importants pour un montage et corrige ce que la politique autorise. Les valeurs par défaut de Plex supposent des disques locaux. Un de ces réglages supprime la bibliothèque quand un scan rencontre un petit raté. D'autres obligent Plex à décoder chaque fichier qu'il contient. [plex.md](../guides/plex.md#recommended-plex-settings) explique chacun d'eux.

| Option | Ce qu'il fait |
|---|---|
| `-p`, `--policy` | `off`, `warn`, `guard` ou `enforce` pour cette exécution. Par défaut, c'est la valeur de `plex_settings_policy` dans la config. Passer une politique plus stricte permet de la prévisualiser avant de l'adopter. |

### zurg plex-drift

Lit la base de données de Plex sans jamais y écrire, puis vérifie chaque fichier qu'elle référence sous le point de montage. Il signale ceux qui n'existent plus. Lance-le avant un scan de bibliothèque : un scan qui tombe sur ces fichiers les transforme en suppressions. Connaître le nombre à l'avance fait du scan une décision et non un pari.

Il faut `plex_database_path` et Plex sur le même hôte.

### zurg plex-backups

Affiche les instantanés de la base de données Plex que zurg conserve, du plus récent au plus ancien. Chaque ligne indique la date de prise de l'instantané, sa taille et le nombre d'éléments que chaque bibliothèque contenait à ce moment-là. Les chiffres sont extraits des instantanés eux-mêmes. La liste montre donc ce que chacun d'eux peut réellement restaurer. [Maintenance de la bibliothèque Plex](config.md#plex-library-maintenance-same-host-only) explique quand zurg les crée.

## Partage {#sharing}

### zurg export-torrents

Écrit des fichiers `.zurgtorrent` portables qui décrivent vos releases sans votre compte à l'intérieur. Aucun identifiant n'est inclus. Aucun identifiant de torrent, aucun état de réparation et aucun lien CDN non plus. Aucun fournisseur n'est contacté.

Il lit `data/*.zurgtorrent` ou un ancien fichier de dump. Indiquez un fichier ou un dossier pour n'exporter que ceux-là. Le destinataire place les fichiers dans `torrents/<their-account>/` et règle ce compte sur `library.source: local`. [bibliothèques portables](../guides/local-libraries.md) explique la partie réception.

| Option | Rôle |
|---|---|
| `--provider` | Exporte les releases détenues par ce compte configuré. |
| `--output` | Emplacement où écrire les fichiers portables. |
| `--replace` | Remplace un export existant du même hash. |
| `--skip-invalid` | Ignore et compte les entrées illisibles lors d'un export en masse. |

### zurg nzb-share

Crée un partage de tes NZB que tu peux publier. Le résultat est un dossier contenant un `manifest.json` et un `.nzb.gz` par release, nommé d'après le hash de son contenu.

Chaque NZB est d'abord nettoyé. Les commentaires, les DOCTYPE et les métadonnées de filigrane sont supprimés. Les noms de fichiers d'origine le sont aussi. Les posters et les dates sont supprimés eux aussi, et chaque fichier reçoit le même groupe de discussion fixe, car certains indexeurs modifient ces trois éléments à chaque téléchargement. Les marques de compte qu'un indexeur cache dans un sujet, un titre ou un mot de passe sont retirées. Ce que tu publies désigne la release, jamais le compte qui l'a téléchargée. Les vrais mots de passe d'archive sont conservés, car les destinataires en ont besoin pour lire la release.

Publie le dossier sur n'importe quel hébergement statique. Un dépôt git fonctionne. Un site Pages ou `rclone serve` aussi.

L'audit de ce qui a été retiré reste sur ta machine et s'affiche ici. Il contient justement les identifiants que le nettoyage sert à supprimer.

| Option | Ce qu'elle fait |
|---|---|
| `--from` | Le dossier de surveillance à partager. Parcouru récursivement. Par défaut `nzbs`. |
| `--out` | Le dossier de sortie. Par défaut `nzb-share-<timestamp>`. |
| `--title` | Un titre enregistré dans le manifeste. |
| `--filter` | Ne partage que les chemins source qui correspondent à cette expression régulière. |

Le tableau de bord peut aussi servir un partage. Voir [Partage public de NZB](config.md#public-nzb-sharing).

### zurg nzb-sync

Récupère une bibliothèque partagée dans votre dossier de surveillance. Il suit le `manifest.json` d'un partage, depuis une URL ou un chemin local. Chaque NZB est vérifié par rapport au hachage du manifeste avant d'être écrit. Ce sont vos propres comptes Usenet qui téléchargent les données.

```
zurg nzb-sync https://example.com/share/manifest.json
```

Il ne fait qu'ajouter. Les entrées que vous avez déjà sont ignorées, et un partage ne supprime jamais rien. Deux partages contenant les mêmes releases sont dédupliqués par hachage de contenu.

| Option | Ce qu'elle fait |
|---|---|
| `--into` | Le dossier de surveillance dans lequel écrire. Par défaut `nzbs`. |
| `--dry-run` | Indique ce qu'il écrirait, sans rien écrire. |

## Vider un compte Real-Debrid {#clearing-a-real-debrid-account}

Ces deux commandes suppriment tout un type d'éléments d'un compte Real-Debrid. Elles sont irréversibles. Elles ne fonctionnent que sur Real-Debrid.

Les deux demandent le cookie `auth` d'une session de navigateur connectée à Real-Debrid, et non votre jeton API. Elles affichent une ligne de JavaScript qui le montre. Exécutez-la dans la console du navigateur sur real-debrid.com, puis collez le résultat.

| Commande | Ce qu'elle fait |
|---|---|
| `zurg clear-torrents` | Supprime tous les torrents du compte. |
| `zurg clear-downloads` | Supprime tous les téléchargements du compte. Ce sont les liens débridés. |

## Complétion du shell {#shell-completion}

`zurg completion bash` affiche un script de complétion pour bash. La même chose fonctionne pour `zsh`, `fish` et `powershell`. `zurg completion <shell> --help` indique où le placer.
