# Configuration Docker {#docker-setup}

Ce guide fait tourner zurg dans Docker et expose son montage FUSE sur un hôte Linux. Docker fournit zurg, rclone et ffprobe. La commande intégrée `setup` crée la configuration. `doctor` vérifie l'installation.

Ce parcours a été vérifié le 4 septembre 2026 avec Docker Engine 29.1.1. Utilise la nightly datée la plus récente pour que l'image contienne le sélecteur de fournisseur ci-dessous.

> **Image réservée aux sponsors :** `ghcr.io/debridmediamanager/zurg` est réservée aux sponsors. Deviens sponsor sur [gatekeeper](https://gatekeeper.debridmediamanager.com/). Cela donne à ton compte GitHub l'accès à l'image.

> **Hôte Linux requis :** le montage visible depuis l'hôte ci-dessous dépend de la propagation de montage Linux. Docker Desktop fait tourner les conteneurs dans une VM sur macOS et Windows : il ne peut pas propager ce montage FUSE vers le Finder ou l'Explorateur, et rex ne peut pas atteindre un zurg qui s'y trouve, donc rien ne lira là-bas. Utilise plutôt le guide du binaire [macOS](https://notes.debridmediamanager.com/fr/zurg/setup/macos/) ou [Windows](https://notes.debridmediamanager.com/fr/zurg/setup/windows/) sur l'un de ces hôtes. Sous Linux, avec rex sur une autre machine, donne au conteneur zurg `network_mode: host`, comme le montre [rex avec zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex).

## Option en une ligne {#one-line-option}

On a fresh Linux host, the optional bootstrap can install Docker when you approve it, configure persistent FUSE mount propagation, log in to the sponsor registry, write the Compose project, run the provider chooser, and check the result:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Existing Compose files and configs are kept as they are. The sections below show every step for those who prefer to do it by hand.

## Ce que fait l'installateur dans un conteneur {#what-the-installer-does-in-a-container}

Les options sont voulues :

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- `setup` demande quels fournisseurs configurer, ne demande que leurs identifiants et écrit `config.yml` avec le mode `0600`.
- `--no-service` laisse le démarrage automatique à la politique `restart: unless-stopped` de Docker, au lieu d'essayer d'installer systemd dans Alpine.
- `--skip-downloads` utilise rclone et ffprobe déjà installés dans l'image.
- `--mount-path` enregistre le sous-dossier dont le montage FUSE remontera sur l'hôte.

Relancer setup n'est pas dangereux. Il valide et met à jour l'installation, mais ne remplace pas un `config.yml` existant.

## 1. Installer Docker et débloquer l'image {#1-install-docker-and-unlock-the-image}

Installez Docker Engine avec le plugin Compose sur l'hôte Linux. Vérifiez les deux commandes avant de continuer :

```bash
docker version
docker compose version
```

Connectez-vous à GitHub Container Registry avec votre nom d'utilisateur GitHub. Quand le mot de passe vous est demandé, collez un jeton d'accès personnel classique avec les scopes `read:packages` et `repo`. L'image appartient à un dépôt privé, et un jeton avec seulement `read:packages` peut vous permettre de vous connecter, mais échouer quand même au pull :

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

Définissez `ZURG_TAG` sur la version sponsor datée la plus récente. La garder dans `.env` vous donne une cible de retour en arrière connue et rend les mises à jour explicites :

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

Remplacez l'espace réservé par le tag de version réel avant de continuer.

## 2. Préparer la propagation du montage FUSE {#2-prepare-fuse-mount-propagation}

Le montage FUSE doit être créé sous un montage parent partagé. Lance cette commande une seule fois avant le premier démarrage du conteneur :

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

Vérifie le périphérique et le mode de propagation :

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

La deuxième commande doit afficher `shared` sous `PROPAGATION`.

## 3. Créer le projet compose {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

Créez `docker-compose.yml` :

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared
```

`privileged: true` n'est pas nécessaire. Le périphérique FUSE, la capacité `SYS_ADMIN` et le profil AppArmor non confiné sont l'ensemble plus restreint utilisé par le montage.

Ne montez pas `/zurg_mnt/zurg` directement. Le montage FUSE doit être un enfant du bind `rshared`, sinon son événement de montage n'atteindra pas l'hôte.

Les conteneurs qui lisent le montage, surtout Sonarr et Radarr, suivent la même règle de l'autre côté : montez le dossier parent (`/zurg_mnt`) une seule fois, avec `rslave`, et accédez à chaque dossier via ce seul bind. Monter `__magic__/__all__` et `__magic__/tv` dans un \*arr comme deux volumes transforme chaque import en copie de tout le fichier. Voir [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

## 4. Lancer la configuration intégrée {#4-run-the-built-in-setup}

Depuis `~/zurg`, lance :

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

Choisis un ou plusieurs fournisseurs, dans l'ordre de priorité. Par exemple, entre `2,4` pour TorBox suivi de Usenet. La configuration ne demande que tes identifiants, crée `config.yml` dans `~/zurg`, active rclone et crée `/zurg_mnt/zurg`. Aucun identifiant n'est stocké dans le fichier compose ni dans l'historique du shell.

Pour l'automatisation, répète `--provider` et passe les options propres au fournisseur, comme l'option token-file ou les `--nntp-*`. La configuration conserve une config existante lors des exécutions suivantes.

La configuration n'écrit les comptes que lors de l'exécution qui crée `config.yml`. Pour en ajouter un à une installation qui a déjà une config, utilise **Add provider** dans le Dashboard, ou modifie le fichier, puis redémarre. Chaque service a sa propre page avec l'identifiant, le bloc de config et les limites à connaître : [Fournisseurs](../providers/index.md).

## 5. Démarrer zurg {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

Quittez la vue des logs avec `Ctrl+C` ; le conteneur continue de tourner. Le Dashboard est accessible à `http://localhost:9999/config/` et modifie le même `config.yml` stocké à côté du fichier compose.

Une grosse bibliothèque peut prendre un certain temps à charger. Les dossiers du montage ne peuvent pas être listés tant que ce n'est pas fini. Ils apparaissent vides ou avec `Input/output error`, alors que le Dashboard et `version.txt` fonctionnent normalement. Cela signifie que zurg est encore en train de charger, et non que le montage est cassé. [Démarré versus prêt](#up-versus-ready) explique comment savoir quand le chargement est terminé.

## 6. Vérifier avec doctor {#6-verify-with-doctor}

Une fois la bibliothèque prête, lancez le même outil de diagnostic que pour une installation binaire :

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`doctor` vérifie la configuration et ses permissions, ffprobe, rclone, FUSE, le point de terminaison HTTP et le montage signalé par zurg. `WARN service zurg is not installed` est normal avec Docker, car Compose gère le démarrage automatique. Les avertissements ne font pas échouer la commande ; seul un `FAIL` la fait échouer.

Vérifiez aussi que le montage propagé est visible en dehors du conteneur :

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. Faire survivre le parent partagé aux redémarrages {#7-make-the-shared-parent-survive-reboots}

Le self-bind de l'étape 2 ne survit pas à un redémarrage. Crée une unité systemd de type oneshot sur l'hôte :

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

Au prochain redémarrage, l'hôte prépare le parent partagé avant que Docker ne restaure le conteneur zurg.

## Up ou ready {#up-versus-ready}

zurg répond à deux questions différentes en HTTP. Aucune des deux ne demande de mot de passe, même quand `username` est défini.

| Adresse | Répond 200 quand | Pendant le chargement de la bibliothèque |
|---|---|---|
| `/http/version.txt` | zurg tourne | 200 |
| `/ready` | la bibliothèque a fini de charger | 503 avec `Retry-After: 5` |

Le health check du conteneur interroge la première. `docker compose ps` affiche `healthy` dès que zurg tourne. Une grosse bibliothèque peut continuer à charger longtemps après. Interroge `/ready` quand tu as besoin de toute la bibliothèque. Il affiche `ready` une fois le chargement terminé.

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

Un script peut attendre comme ça.

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### Pourquoi le health check n'attend pas la bibliothèque {#why-the-health-check-does-not-wait-for-the-library}

Docker garde un seul état de santé par conteneur. Les outils qui le lisent considèrent que ça veut dire « zurg est-il en vie ». autoheal et Docker Swarm redémarrent un conteneur qui passe en unhealthy. `depends_on` avec `condition: service_healthy` retient les autres services tant que zurg n'est pas healthy.

Des démarrages à froid de 15 à 90 minutes ont été signalés sur les grosses bibliothèques. Un health check qui attendrait la bibliothèque retiendrait donc tous les services dépendants pendant tout ce temps. Un conteneur rclone placé devant zurg laisserait son dossier de montage vide pendant toute cette durée. Pour un serveur multimédia, un dossier vide ressemble à une bibliothèque qui a été supprimée. Un chargement qui dépasserait le nombre de tentatives du health check serait aussi marqué unhealthy. Tout ce qui redémarre les conteneurs unhealthy relancerait alors le chargement depuis le début. Il ne finirait jamais.

### Utiliser readiness avec Compose {#using-readiness-with-compose}

Laisse un conteneur mount sur le health check par défaut pour que son montage démarre dès que zurg tourne.

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

Attends sur `/ready` dans ce qui a besoin de toute la bibliothèque. Ça peut être un script de scan ou un job d'import.

Tu peux faire en sorte que le conteneur zurg lui-même ne soit marqué healthy qu'une fois la bibliothèque chargée. Remplace son health check dans `docker-compose.yml` et mets un `start_period` plus long que ton chargement le plus lent. Docker ne compte pas les échecs pendant le start period. Chaque service qui dépend de zurg attendra alors la bibliothèque aussi. Ne combine pas ça avec autoheal.

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## Gérer et mettre à jour zurg {#managing-and-updating-zurg}

Lance ces commandes depuis `~/zurg` :

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

Le projet compose suit `ZURG_TAG` dans `.env`, que l'installeur règle sur `latest` pour qu'un pull récupère toujours la dernière nightly. Pour mettre à jour, fais un pull et recrée le conteneur, puis lance doctor :

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`zurg update` n'est pas la bonne méthode ici : il refuse de tourner dans un conteneur. Le binaire qu'il écrit se trouve dans la couche du conteneur et disparaît dès que le conteneur est recréé. Le prochain `up` repasserait donc silencieusement sur l'ancienne version. Fais plutôt un pull de l'image. `--force` contourne ce refus, pour un conteneur que tu comptes garder.

Pour revenir en arrière, mets `ZURG_TAG` dans `.env` à un tag nightly précis et relance ces trois commandes. La config, l'état de la bibliothèque, les logs et le cache montés en bind-mount ne bougent pas avec le conteneur.

`docker compose down` supprime le conteneur et le réseau, mais laisse les fichiers montés en bind-mount dans `~/zurg` et le dossier parent du montage `/zurg_mnt`.

## Où se trouve quoi {#what-lives-where}

Tout ce que zurg écrit se résout par rapport à `/config`, donc le seul montage `./:/config` contient toute l'installation :

| Chemin | Ce que c'est |
|---|---|
| `config.yml` | Réglages et identifiants des fournisseurs ; les modifications faites dans Dashboard y sont enregistrées |
| `data/` | État de la bibliothèque, fichiers locaux, clés générées et le cache VFS de rclone |
| `logs/` | Journaux de zurg et de rclone |
| `dump/` | Dumps de torrents, lorsque l'option est activée |
| `strm/` | Fichiers `.strm`, lorsque `save_strm_files` est activé |
| `nzbs/` | Répertoire de surveillance pour le backend Usenet |

Récupérer ou recréer l'image ne modifie aucun de ces fichiers.

C'est `data/rclone-cache` qui grossit. Le montage télécharge en entier chaque fichier qu'il lit et le garde après la fin de la lecture, jusqu'à **256G** par défaut. Le répertoire monté doit donc avoir de la place pour le cache en plus de tout le reste.
En pratique, la limite d'âge de 72h ne le borne pas : tout ce qui lit la bibliothèque, y compris le parcours nocturne d'un serveur multimédia, compte comme un accès au fichier.

```bash
du -sh ./data/rclone-cache
```

Réduisez-le dans `config.yml` si le disque de l'hôte ne peut pas se permettre autant :

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

Changer le chemin de l'hôte derrière `/config` renomme le cache et laisse l'ancienne copie orpheline ; zurg récupère les arborescences orphelines au prochain démarrage et journalise ce qu'il a libéré.
Voir [config.md](../reference/config.md#disk-the-mount-uses).

### Préremplir l'environnement pour les installations sans surveillance {#environment-seeding-for-unattended-installs}

L'image prend toujours en charge l'ancien chemin de premier démarrage. Si aucun `config.yml` n'existe, `TOKEN` ou `RD_TOKEN` initialise le compte et `MOUNT_PATH` active le montage. Ces variables ne sont lues que pendant la création du fichier ; le fichier prime à chaque démarrage suivant.

Real-Debrid est le seul compte que le conteneur en cours d'exécution initialise de cette façon. `TORBOX_TOKEN`, `ALLDEBRID_TOKEN`, `PREMIUMIZE_TOKEN`, `DEBRIDLINK_TOKEN`, `OFFCLOUD_TOKEN` et `NNTP_HOST` sont lus par `zurg setup`, donc elles ne prennent effet que dans le conteneur de configuration ponctuel ci-dessus et ne servent à rien dans le bloc `environment:` du service.

La commande `setup` interactive est préférable pour une personne devant un terminal, car le token n'apparaît jamais dans le fichier compose. L'initialisation par variables d'environnement reste utile pour l'automatisation qui dispose déjà d'un coffre à secrets.

### Mettre à niveau une installation qui montait `/app` {#upgrading-an-install-that-mounted-app}

Les anciens projets compose montaient séparément `/app/config.yml`, `/app/data` et d'autres chemins en bind mount. Le point d'entrée choisit toujours `/app` dès qu'il trouve cette configuration, donc tirer une image plus récente continue d'utiliser l'ancienne config et l'ancien cache.

Pour passer à la structure avec un seul dossier, arrêtez le conteneur, copiez le `config.yml` existant, le dossier `data/` et les autres dossiers d'état dans un même dossier de l'hôte, puis montez ce dossier sur `/config`.

## Dépannage {#troubleshooting}

Commencez par le diagnostic et les logs actuels :

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` ou `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

Le conteneur est antérieur à l'installateur intégré. Utilisez `2026.09.04.1449-nightly` ou une image zurg datée plus récente, puis recréez-le :

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

L'ancien montage FUSE est obsolète :

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### Le périphérique FUSE est indisponible {#fuse-device-is-unavailable}

Charge le module maintenant et à chaque démarrage suivant :

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

Vérifie ensuite que le service compose inclut toujours `/dev/fuse`, `SYS_ADMIN` et le réglage AppArmor.

### Le montage est vide {#mount-is-empty}

Vérifie chaque couche dans l'ordre :

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

Le chemin de l'hôte doit être un bind mount partagé, et le volume compose doit monter le dossier parent en `/zurg_mnt:/zurg_mnt:rshared`.

Si `/ready` renvoie une erreur 503, c'est que la bibliothèque est encore en cours de chargement et que le montage est correct. Ses dossiers apparaissent vides ou affichent `Input/output error` tant que le chargement n'est pas terminé. Attends-le plutôt que de redémarrer zurg. Un redémarrage relance le chargement depuis le début.

### Le montage apparaît deux fois dans la sortie de `mount` {#mount-appears-twice-in-mount-output}

C'est normal. Le même montage FUSE est visible dans les espaces de montage du conteneur et de l'hôte, car la propagation fonctionne.

Toujours bloqué ? Demande dans le forum **zurg-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../../guides/remote-help.md) indique ce qu'il faut inclure.
