# Les applications téléchargent depuis ton fournisseur {#apps-download-from-your-provider}

Normalement, rex lit chaque film de votre source et le transmet à Plex. Si la source renvoie un lien de fichier, par exemple un lien de téléchargement debrid, rex peut le transmettre directement à Plex. Plex télécharge alors le fichier, et la machine rex ne transporte aucun média.

Cela fonctionne quand Plex peut lire le fichier en direct play. Tout ce que rex doit convertir passe toujours par rex, ou est refusé si vous le choisissez.

Testé le 2026-10-25 avec zurg sur Real-Debrid, Plezy et Plex pour Android sur un Pixel 6, et Plex Web dans Chrome.

## Avant de commencer {#before-you-start}

**Gardez le mode proxy par défaut pour la lecture avec un débrideur partagé.** Les redirections ne sont pas un moyen sûr de partager un même compte de débrideur :

- **Real-Debrid suit l'IP publique de chaque téléchargeur.** Utiliser un même compte depuis plusieurs IP vaut un avertissement de partage, même quand le CDN sert correctement le fichier. Gardez toutes les utilisations de ce compte sur une seule IP publique. Une application distante qui télécharge directement pendant que rex ou sa source sonde ou convertit depuis l'IP du serveur enfreint cette règle ; une lecture réussie ne prouve pas que c'est sûr.
- **Les URL de téléchargement TorBox contiennent la clé API complète dans `?token=`.** Une redirection donne à chaque client et à chaque compte utilisateur partagé un accès complet, y compris la suppression, et pas seulement l'accès à ce fichier. Les journaux du lecteur et l'historique du navigateur peuvent conserver la clé. Ne donnez pas ces liens à des clients non fiables.

Ne continuez que si ces risques vous conviennent. Garder le mode proxy par défaut de rex signifie que rex suit lui-même les redirections de la source, au lieu de transmettre le lien du fournisseur à l'application.

| Il vous faut | Pourquoi |
|---|---|
| rex configuré comme dans [rex avec votre propre application](any-source.md), [rex avec vos addons Stremio](stremio.md) ou [rex avec zurg](with-zurg.md), et un film qui se lit | Cette page modifie la commande de démarrage de rex et, pour certaines sources, un des paramètres de la source |
| rex nightly **2026.10.26 ou plus récent** | Les anciennes versions n'ont pas ce paramètre. Mettez à jour comme dans la section [Mise à jour](any-source.md#updating) de rex |
| Une source capable de répondre avec un lien | rex ne peut transmettre qu'un lien que la source lui donne. [Étape 1](#step-1-let-your-source-hand-out-links) indique quelles sources le font |

## Choisis le niveau de rigueur {#choose-how-strict}

Voici la traduction :

| | `redirect` | `redirect-only` |
|---|---|---|
| Une app lit le fichier tel quel | L'app télécharge depuis ton fournisseur | L'app télécharge depuis ton fournisseur |
| Une app a besoin que le fichier soit converti (qualité plus basse, audio qu'elle ne peut pas lire, sous-titres incrustés) | rex le convertit en lisant le fichier depuis ta source, comme avant | Refusé : l'app affiche une erreur |
| Fichiers que ta source envoie elle-même, pas sous forme de lien (les fichiers Usenet de zurg, par exemple) | Lecture via rex, comme avant | Refusé |
| Plex Web | Lecture, via rex | Chaque fichier Real-Debrid est refusé (voir ci-dessous) |

Choisis `redirect` si tu veux que tout continue de jouer et économiser ce que tu peux. Choisis `redirect-only` si la machine rex ne doit jamais faire transiter un film, par exemple un petit VPS avec un quota de données.

Quel que soit ton choix, chaque app et chaque personne avec qui tu partages rex reçoit le lien que ta source a fourni à rex pour ce qu'elle lit, et le service derrière ce lien, ton service debrid par exemple, voit chacune d'elles télécharger le fichier.

## Étape 1. Laisse ta source distribuer les liens {#step-1-let-your-source-hand-out-links}

**Ce que ça fait.** Votre source répond à chaque lecture par un lien vers le fichier ailleurs (une redirection HTTP) au lieu du fichier lui-même.

**Pourquoi c'est important.** rex ne peut transmettre qu'un lien que sa source lui donne. Une source qui envoie le fichier lui-même continue de le faire passer par rex.

| Source | Quoi faire |
|---|---|
| [rex-stremio](stremio.md) | Rien : elle répond avec le lien donné par un addon de flux. Un lien qui a besoin de ses propres en-têtes, et une playlist en direct, elle les envoie toujours elle-même |
| [zurg](with-zurg.md) | Activez `disable_stream_proxy`, ci-dessous. zurg n'a pas de lien pour un fichier Usenet, donc il envoie toujours ceux-là lui-même |
| [Votre propre app](any-source.md) | Répondez au `GET` du fichier par un `302` ou `307` vers le lien |

### zurg

Le paramètre concerne la configuration de zurg, donc tout autre logiciel qui lit zurg (rclone, un serveur Plex ou Jellyfin sur le montage de zurg) reçoit aussi les liens. La [référence de configuration](../zurg/reference/config.md) de zurg donne les détails.

+++ Linux et macOS
Vérifiez si le paramètre est déjà dans la configuration de zurg :

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

Si la commande affiche une ligne, modifiez-la pour mettre `disable_stream_proxy: true` avec `nano ~/zurg/config.yml`. Si elle n'affiche rien, ajoutez-la :

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Ouvrez la configuration de zurg avec `notepad $HOME\zurg\config.yml`. Si elle contient une ligne `disable_stream_proxy:`, remplacez-la par `disable_stream_proxy: true` ; sinon, ajoutez cette ligne à la fin. Enregistrez et redémarrez zurg :

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
Dans le dossier de zurg :

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

Si une ligne s'affiche, modifiez-la avec `sudo nano config.yml`. Sinon :

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**Ce que vous devriez voir.** zurg redémarre normalement. Les films passent encore par rex à ce stade : rex suit lui-même les liens jusqu'à l'étape 2.

## Étape 2. Laisse rex transmettre les liens {#step-2-let-rex-pass-the-links-on}

**Ce que ça fait.** rex donne à l'application le lien fourni par votre source, au lieu de télécharger le film à sa place.

Ajoutez `--part-mode redirect` (ou `--part-mode redirect-only`) à la fin de la commande de démarrage de rex, puis redémarrez rex et ouvrez son journal. [Installer rex](any-source.md#step-1-install-rex) indique où se trouve la commande de démarrage sur votre système, et comment redémarrer rex et voir son journal. Sous Linux, la ligne `ExecStart` du fichier `~/.config/systemd/user/rex.service` doit alors se lire, sans rien d'autre sur la ligne :

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

Gardez tout ce qui se trouve déjà sur la ligne, comme `--port 32500` ou `--announce-url ...`.

**Ce que vous devriez voir.** La ligne de démarrage se termine par `parts=redirect` :

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

Avec `redirect-only`, elle se termine par `parts=redirect-only`, et quelques lignes plus haut rex affiche `transcoder off: --part-mode redirect-only`.

## Étape 3. Lance quelque chose {#step-3-play-something}

Laissez le journal de rex ouvert et lancez un film dans Plezy ou Plex pour Android.

**Ce que vous devriez voir.** Pour chaque lecture effectuée par l'application, une ligne indique le serveur de votre fournisseur :

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

Il s'agit de rex qui envoie l'application vers le serveur du lien, ici celui de Real-Debrid. Une ligne se terminant par `-> 206 len=...` signifie au contraire que rex a envoyé le film lui-même : voir [En cas de problème](#if-it-does-not-work).

## Ce que fait chaque application {#what-each-app-does}

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | Télécharge depuis ton fournisseur | Télécharge depuis ton fournisseur |
| Plex for Android, Original quality | Télécharge depuis ton fournisseur, quand rex le laisse lire le fichier tel quel | Pareil |
| Plex for Android, une qualité inférieure, ou un audio qu'il ne peut pas lire | rex le convertit | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | Lit via rex | "Playback Error: This server is not powerful enough to convert video." |

Plex Web ne peut pas du tout utiliser les liens de Real-Debrid : Real-Debrid marque ses fichiers comme des téléchargements, pas comme de la vidéo, et le navigateur refuse de les lire. Avec `redirect`, Plex Web bascule discrètement sur une conversion via rex en moins d'une seconde, donc ça continue de marcher. Avec `redirect-only`, il n'y a pas de plan B.

## Avec Docker {#in-docker}

Si vous avez suivi [rex dans Docker](any-source.md#run-rex-in-docker), l'étape 2 consiste à ajouter une ligne `command:` sous `rex:` dans le `compose.yml` de rex, à côté de `image:` :

```yaml
    command: --part-mode redirect
```

Vous avez déjà `command: --port 32500` ? Remplacez-la par `command: --port 32500 --part-mode redirect`. Ensuite, lancez `docker compose up -d` dans le dossier de rex, puis `docker compose logs -f rex` affiche la même ligne `parts=redirect`.

## Si ça ne fonctionne pas {#if-it-does-not-work}

| Ce que tu vois | Ce que ça signifie |
|---|---|
| rex s'arrête avec `invalid choice` pour `--part-mode` | rex est plus ancien que 2026.10.26. Mets-le à jour comme dans la [section Mise à jour de rex](any-source.md#updating) |
| Le log de rex affiche `-> 206 len=...` pour chaque lecture | La source envoie encore le fichier elle-même. Avec zurg : `disable_stream_proxy: true` manque dans la config de zurg, ou zurg n'a pas été redémarré après l'étape 1 |
| `-> 206 len=...` seulement pour certains titres | La source envoie ceux-là elle-même : les fichiers Usenet de zurg, ou les liens rex-stremio que rex doit relayer |
| `-> 403: the source answered with the bytes, not a link` | `redirect-only` refuse un fichier que la source a envoyé elle-même, pour les mêmes raisons que ci-dessus |
| Aucune ligne `PART` pendant la lecture d'un film | L'app lit une conversion, pas le fichier lui-même. Règle sa qualité sur Original |

Toujours bloqué ? Pose ta question dans le forum **rex-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../guides/remote-help.md) indique quoi inclure.

## Revenir en arrière {#going-back}

Retire `--part-mode ...` de la commande de démarrage de rex (ou de la ligne `command:` dans Docker) puis redémarre rex. Ta source peut continuer à fournir des liens : sans le paramètre rex, rex les suit lui-même. Avec zurg, remets `disable_stream_proxy` à `false` et redémarre zurg : il refait passer lui-même les fichiers, pour rclone et tout autre lecteur.
