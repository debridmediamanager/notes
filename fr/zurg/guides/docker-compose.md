# Un seul fichier Docker Compose pour zurg, Plex et rex {#one-docker-compose-file-for-zurg-plex-and-rex}

Sur une machine Linux, un seul `docker-compose.yml` peut faire tourner zurg, Plex Media Server et rex côte à côte. zurg affiche votre bibliothèque sous forme de dossiers dans `/zurg_mnt/zurg`, Plex Media Server lit ces dossiers, et rex récupère la même bibliothèque directement depuis zurg, sans dossiers. Lancez une fois l'installateur Docker de zurg, puis remplacez son `docker-compose.yml` par celui ci-dessous.

Vous voulez Plex Media Server ou rex, mais pas les deux ? Retirez simplement l'autre du fichier. Sans Plex, supprimez aussi la ligne `command:` de rex.

Docker Desktop sur Windows ou sur un Mac ne peut pas faire tourner cela : les dossiers de zurg n'arrivent jamais dans l'Explorateur ou le Finder, et rex ne peut pas atteindre un zurg qui tourne à l'intérieur. Utilisez plutôt [zurg sur Windows](../setup/windows.md) ou [zurg sur macOS](../setup/macos.md) dans ces cas-là.

## Avant de commencer {#before-you-start}

- **Une machine Linux** qui reste allumée. L'installateur ajoute Docker s'il n'est pas déjà présent.
- **Un sponsoring zurg.** L'image zurg est privée. Sponsorisez sur [gatekeeper](https://gatekeeper.debridmediamanager.com/) et cela donne accès à votre compte GitHub.
- **Votre jeton d'API Real-Debrid**, ou les identifiants d'un autre service pris en charge par zurg : [Votre jeton d'API Real-Debrid](../../guides/real-debrid-api-token.md).
- **Pour Plex Media Server**, votre compte Plex. **Pour rex**, un compte Plex tout neuf, créé juste pour lui : [rex avec zurg](../../rex/with-zurg.md#before-you-start) explique pourquoi.

## 1. Lancez l'installateur Docker de zurg {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

Il installe Docker s'il manque (il demande d'abord). Il prépare `/zurg_mnt` pour les dossiers de zurg, maintenant et après chaque redémarrage, vous connecte à GitHub pour l'image de zurg, écrit `~/zurg/docker-compose.yml`, demande vos services et votre token, démarre zurg et lance `zurg doctor`. [La configuration Docker de zurg](../setup/docker.md) fait la même chose à la main.

**Ce que vous devriez voir.**

```bash
ls /zurg_mnt/zurg
```

affiche `__all__`, `__downloads__`, `__unplayable__`, `movies`, `shows` et `version.txt`.

## 2. Remplacez par le fichier complet {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

Remplacez tout son contenu par ceci :

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

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** est le service de l'installateur, inchangé.
- **plex** voit les dossiers de zurg au même chemin que celui qu'utilise zurg, `/zurg_mnt/zurg`, donc une analyse demandée par zurg désigne un dossier que Plex connaît. `rslave` garde les dossiers montés lorsque zurg redémarre. Mettez votre propre fuseau horaire dans `TZ`.
- **PLEX_CLAIM** connecte Plex Media Server à votre compte lors de son premier démarrage. Une fois connecté à Plex, ouvrez [plex.tv/claim](https://www.plex.tv/claim), copiez le code et collez-le juste après le `=`. Il expire au bout de quelques minutes, donc lancez la pile tout de suite.
- **rex** est le service de [rex avec zurg](../../rex/with-zurg.md#d2-start-rex-in-docker), sur le port 32500 car Plex Media Server utilise le 32400. Ses fichiers finissent dans `~/rex/config`, où rex avec zurg les cherche.

Enregistrez et démarrez le tout :

```bash
docker compose up -d
docker compose ps
```

Si `docker` affiche permission denied, mettez `sudo` devant chaque commande `docker` de cette page.

**Ce que vous devriez voir.** Trois conteneurs : `plex` et `zurg` affichent `(healthy)`, `rex` affiche `Up`. Les fichiers propres à Plex Media Server vont dans `~/plex`.

## 3. Ajoutez les dossiers de zurg dans Plex {#3-add-zurgs-folders-in-plex}

Ouvrez Plex Web à l'adresse `http://<this machine's LAN IP>:32400/web`. Ajoutez une bibliothèque **Movies** avec le dossier `/zurg_mnt/zurg/movies` et une bibliothèque **TV Shows** avec `/zurg_mnt/zurg/shows`, comme le montre [Real-Debrid dans Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex).

Pour que Plex soit prévenu des nouveautés, ouvrez le tableau de bord de zurg à l'adresse `http://<this machine's LAN IP>:9999/config/` et appuyez sur **Login with Plex** sous **Media Server Integration** ([étape 4 là-bas](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)).

## 4. Configurez rex {#4-set-up-rex}

Suivez [rex avec zurg](../../rex/with-zurg.md) de [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) à [D5](../../rex/with-zurg.md#d5-watch), en remplaçant `32400` par `32500` partout. Par exemple, la ligne de zurg est `rex_url: http://192.168.1.20:32500`, avec l'IP LAN de rex. Vos applications Plex affichent ensuite les deux serveurs : [étape 2 de rex avec zurg](../../rex/with-zurg.md#step-2-install-rex) explique comment les distinguer.

## Mise à jour {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

Cela met à jour zurg, Plex et rex en même temps. Quand rex avec zurg lance `docker compose` dans `~/rex`, lancez-le ici dans `~/zurg` avec `rex` à la fin, pour ne toucher qu'à rex : `docker compose stop rex` à la place de `docker compose down`, `docker compose up -d rex` à la place de `docker compose up -d`.

## Quand quelque chose ne va pas {#when-something-is-wrong}

`docker compose logs --tail=100 zurg` (ou `plex`, `rex`) affiche ce que le conteneur a écrit en dernier.

| Ce que vous voyez | Quoi faire |
|---|---|
| L'installateur affiche `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | Vous êtes sur Mac ou Windows. Installez zurg avec [son installateur Windows](../setup/windows.md) ou [macOS](../setup/macos.md) à la place. |
| `Error response from daemon: error from registry: unauthorized` quand Docker télécharge zurg | Cette machine n'est pas connectée au registre GitHub avec un compte qui a accès à zurg. Devenez sponsor sur [gatekeeper](https://gatekeeper.debridmediamanager.com/), puis relancez l'installateur. Pour vous connecter à la main, voir [configuration Docker de zurg](../setup/docker.md#1-install-docker-and-unlock-the-image) : le token doit avoir à la fois `read:packages` et `repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | `/zurg_mnt` n'est pas encore partagé. Lancez `sudo mount --bind /zurg_mnt /zurg_mnt` puis `sudo mount --make-rshared /zurg_mnt`, puis `docker compose up -d`. L'installateur rend ce réglage permanent après un redémarrage ; à la main, voir [étape 7 de la configuration Docker de zurg](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| `zurg` redémarre sans cesse, et son log se termine par `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` et `mapping key "..." already defined` | Ce réglage est présent deux fois dans la configuration de zurg. Lancez `sudo nano ~/zurg/config.yml`, supprimez l'une des deux lignes indiquées par l'erreur, enregistrez, puis lancez `docker compose restart zurg`. |
| Le log de zurg affiche `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | Les dossiers de zurg ne sont pas apparus. Vérifiez que la ligne de volume de zurg est `/zurg_mnt:/zurg_mnt:rshared`, avec le parent et non `/zurg_mnt/zurg`, et que `/zurg_mnt` est partagé (la ligne ci-dessus). [Le montage est vide](../setup/docker.md#mount-is-empty) donne d'autres vérifications. |
| Les bibliothèques de Plex se vident après un redémarrage de zurg, et `docker exec plex ls /zurg_mnt/zurg` affiche `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | La ligne de volume de Plex n'a pas `rslave`. Elle doit être `/zurg_mnt:/zurg_mnt:rslave`. Corrigez-la puis lancez `docker compose up -d`. |
| rex s'arrête avec `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server utilise déjà le port 32400. Gardez `command: --port 32500` sur rex. |
| `/zurg_mnt/zurg/movies` est vide, ou affiche `Input/output error`, juste après un démarrage | zurg est encore en train de lire votre compte. `curl http://localhost:9999/ready` affiche `ready` une fois la lecture terminée. Ne redémarrez pas zurg entre-temps : cela recommence la lecture depuis le début. |
| Les titres apparaissent dans rex mais rien ne se lance | La ligne `upstream failed` de [rex avec zurg, Quand quelque chose ne va pas](../../rex/with-zurg.md#when-something-is-wrong) vérifie si rex peut joindre zurg. |
| Le disque se remplit | zurg garde une copie de ce qui a été lu dans `~/zurg/data/rclone-cache`, jusqu'à 256G par défaut. [Où se trouve quoi](../setup/docker.md#what-lives-where) explique comment limiter cette taille. |

Toujours bloqué ? Posez la question sur le forum **zurg-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../../guides/remote-help.md) indique quoi inclure.

## Questions

### Pouvez-vous vérifier mon fichier docker compose ? {#can-you-check-my-docker-compose-file}

Je ne vois aucun texte à traduire ni de version précédente dans cette conversation. Pouvez-vous coller le passage en anglais ? Je garderai les points importants : `zurg` monte `/zurg_mnt` avec `rshared`, Plex monte le même `/zurg_mnt` avec `rslave`, et `rex` utilise l'image `ghcr.io/debridmediamanager/rex` avec `network_mode: host`. Un service nommé `rex` qui lance `plexinc/pms-docker` serait un second Plex Media Server, pas `rex`.

### Me faut-il un conteneur rclone séparé ? {#do-i-need-a-separate-rclone-container}

Non. zurg lance rclone dans son propre conteneur et monte lui-même votre bibliothèque dans `/zurg_mnt/zurg`.

### Puis-je utiliser Plex Media Server et rex ensemble ? {#can-i-use-plex-media-server-and-rex-together}

Oui, c'est ce que fait ce fichier. Plex Media Server lit depuis les dossiers de zurg, et rex lit directement depuis zurg. Vos applications Plex affichent les deux. Gardez uniquement celle que vous utilisez si vous ne voulez pas avoir les deux.

### Ça fonctionne sur un NAS ? {#does-this-work-on-a-nas}

Il a été testé sur un PC Linux, pas sur un NAS. L'installateur a besoin d'un terminal (SSH) avec `sudo`, et de FUSE (`/dev/fuse`). Si l'étape 1 se termine avec les dossiers de zurg dans `/zurg_mnt/zurg`, passez à l'étape 2.

### Avec quelles versions cela a-t-il été testé ? {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly`, rex `2026.11.14.1123-nightly` et Plex Media Server `1.43.5.11079`, le 14 novembre 2026.
