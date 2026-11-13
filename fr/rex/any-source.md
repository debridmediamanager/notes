# rex avec votre propre app {#rex-with-your-own-app}

[rex](https://rex.debridmediamanager.com/fr/) est un serveur multimédia pour les applications officielles de Plex. Il ne possède aucun fichier. Les applications officielles de Plex le voient comme un serveur Plex normal. Un autre programme, que cette page appelle **votre application**, indique à rex ce qui se trouve dans votre bibliothèque et fournit les fichiers. Quand vous appuyez sur lecture, rex diffuse le fichier directement depuis votre application. Rien n'est téléchargé au préalable.

Cette page vous guide pas à pas, de zéro jusqu'à la lecture d'un film. Elle ne suppose aucune application en particulier. Elle indique exactement ce que rex attend d'une application, afin que vous puissiez vérifier que la vôtre le fait, ou en créer une. Chaque étape explique ce qu'elle fait, pourquoi elle compte et ce que vous devez voir avant de passer à la suivante.

Quatre points à connaître avant de commencer :

- **Votre application fournit les fichiers.** rex récupère chaque octet depuis votre application en HTTP ou HTTPS, comme un navigateur télécharge un fichier. rex ne conserve aucun fichier et n'a besoin ni de disque ni de montage pour les médias.
- **Votre application indique à rex ce qu'elle possède.** Elle envoie à rex une liste de fichiers via l'API de flux de rex, puis chaque modification par la suite. rex ne parcourt jamais un dossier et ne fait aucun scan.
- **Votre application détermine ce qu'est chaque fichier.** Elle indique si un fichier est un film ou un épisode, à quel titre il appartient (par identifiant IMDb et TMDB) et, pour un épisode, sa saison et son numéro. rex ne devine jamais à partir du nom de fichier.
- **Plex les décrit.** Une fois rex connecté à un compte Plex, il affiche chaque titre avec le nom, l'affiche, le résumé et les titres d'épisodes que les métadonnées propres à Plex associent à ces identifiants. Pour les contenus qu'aucun agent Plex ne connaît, votre application les nomme elle-même : voir [Créer des addons rex](addons.md).

rex est gratuit pour un usage personnel (PolyForm Noncommercial) : pas d'offre sponsor et aucun compte nécessaire pour le télécharger. Voir [rex.debridmediamanager.com](https://rex.debridmediamanager.com/fr/). Vous n'avez qu'un téléphone ou une box TV ? [rex pour Android](android.md) fait tourner rex et ses addons directement dessus.

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| La version nightly datée 2026.10.25 de rex ou une plus récente | L'étape 1 télécharge la plus récente |
| Une machine qui reste allumée : Linux (Ubuntu 22.04 ou plus récent), macOS ou Windows (64 bits) | rex est un serveur : vos applications Plex le joignent dès que vous appuyez sur lecture. Quand les commandes diffèrent d'un système à l'autre, une étape propose un onglet par système. [Docker](#run-rex-in-docker) est plus bas dans la page, pour Linux |
| 1 Go de RAM | Avec 4 062 films et 656 séries (34 678 épisodes), rex utilisait moins de 500 Mo au démarrage et environ 730 Mo pendant la navigation dans la bibliothèque. La conversion vidéo en demande davantage, ainsi que plus de cœurs ou une puce graphique |
| Une application qui fait ce que liste [What your app must do](#what-your-app-must-do) | C'est de là que vient votre bibliothèque |
| Votre application qui pousse depuis cette machine, votre réseau domestique ou Tailscale | rex ne accepte le flux que depuis là ([Keep the port private](#keep-the-port-private)). Une application sur un seedbox ou un serveur cloud ne peut pas pousser vers rex, sauf si ce serveur est sur votre tailnet ; les fichiers eux-mêmes peuvent être servis depuis n'importe où que rex peut atteindre |
| Des fichiers sur les disques de cette machine ? Un outil qui les sert en HTTP et les pousse | rex ne lit jamais un disque. [Step 2](#step-2-see-it-work-by-hand) le fait à la main pour un seul fichier ; sinon, gardez Plex pour ceux-là |
| Usenet ? Une source qui le lit, comme zurg | rex ne parle jamais à un fournisseur Usenet. zurg est une source qui le fait : voir [rex with zurg](with-zurg.md) |
| Un nouveau compte Plex, créé uniquement pour rex | rex récupère chaque titre, affiche, résumé et nom d'épisode depuis Plex une fois qu'il est [added to a Plex account](#step-3-add-it-to-a-plex-account). Jusque-là, les titres gardent leur nom de fichier et n'ont pas d'affiche |

## Ce que votre app doit faire {#what-your-app-must-do}

Donne cette liste à celui qui développe ton app. La référence de l'API de rex se trouve dans [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

| Ton app doit | Comment | Si elle ne le fait pas |
|---|---|---|
| Servir chaque fichier en HTTP | `GET <address>/<path>` renvoie le fichier. Les requêtes `Range` rendent la navigation dans la vidéo rapide ; les redirections sont suivies. L'auth Basic ou un token bearer sont acceptés | Rien ne se lit : rex note une erreur 502 dans les logs |
| S'enregistrer auprès de rex | `PUT /rex/sources/<name>` (lettres, chiffres, `-` et `_`) avec `{"url": ...}` et, s'il y a une connexion, `"user"` et `"password"` ou `"bearer"`, jamais dans l'url. À refaire à chaque démarrage de l'app | rex n'a nulle part où lire |
| Envoyer tous les fichiers qu'elle a | `POST /rex/feed/<name>/items`, quelques centaines de fichiers par requête | rex reste vide |
| Envoyer la sortie ffprobe de chaque fichier | Le JSON de `-show_format -show_streams` de ffprobe, en entier, sous `media_info` | Le fichier est **retenu** : stocké mais non affiché, car les apps Plex refusent de lire un fichier sans elle |
| Indiquer ce qu'est chaque fichier | `kind` (`movie`, `episode` ou `extra`) et `ids` : le `imdb` ou le `tmdb` du film ou de la **série** (l'un ou l'autre suffit), jamais celui d'un épisode. Pour un épisode, `season` et `episode` directement sur l'élément (à côté de `kind`, pas dans `ids`), selon la numérotation TMDB ; `episode_end` pour un fichier qui contient plusieurs épisodes | Le fichier n'est pas associé : un film porte le nom de son fichier, un épisode est rangé dans une série portant le nom de sa release, et numéroté dans l'ordre des fichiers |
| Garder le même `id` pour un fichier pour toujours | Même quand il le renomme | Un fichier renommé devient un nouveau titre et perd son historique de visionnage |
| Envoyer les changements au fur et à mesure | Le même `POST` pour les fichiers nouveaux ou modifiés, `DELETE /rex/feed/<name>/items` pour les fichiers supprimés | La bibliothèque devient obsolète |
| Envoyer toute la bibliothèque de temps en temps | `PUT /rex/feed/<name>/snapshot`. rex supprime tout ce que le snapshot ne cite pas | Les fichiers que ton app a perdus de vue restent dans rex |
| Accepter un `DELETE` WebDAV sur un fichier | Quand quelqu'un supprime un titre dans une app Plex, rex demande d'abord à ton app de supprimer le fichier | Le titre reste et l'app Plex indique qu'il n'a pas pu être supprimé |

## Étape 1. Installer rex {#step-1-install-rex}

**Ce que ça fait.** Télécharge rex dans `~/rex` (`$HOME\rex` sous Windows) et le lance comme service, avec tout ce qu'il faut pour les étapes suivantes. Les étapes qui suivent n'ont pas besoin de redémarrage. Seules les sections optionnelles plus bas en ont besoin.

**Pourquoi c'est important.** rex est ce à quoi tes apps Plex parlent. Le premier démarrage crée `rex.db`, qui contient tes bibliothèques, tout ce que tes apps envoient et ton historique de visionnage.

Sous Linux, tu peux aussi lancer l'image Docker de rex : voir [Lancer rex dans Docker](#run-rex-in-docker).

+++ Linux and macOS
```bash
mkdir -p ~/rex && cd ~/rex
TAG=$(curl -fsSL 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1' | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
P=$(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -fL "https://github.com/debridmediamanager/rex/releases/download/$TAG/rex-$TAG-$P.tar.gz" | tar xz --strip-components=1
```
+++ Windows
Dans PowerShell :

```powershell
New-Item -ItemType Directory -Force $HOME\rex | Out-Null; cd $HOME\rex
$tag = (Invoke-RestMethod 'https://api.github.com/repos/debridmediamanager/rex/releases?per_page=1')[0].tag_name
curl.exe -fLO "https://github.com/debridmediamanager/rex/releases/download/$tag/rex-$tag-windows-amd64.zip"
tar -xf "rex-$tag-windows-amd64.zip" --strip-components=1; Remove-Item "rex-$tag-windows-amd64.zip"
```
+++

Cela récupère la version la plus récente de rex pour ta machine, généralement une nightly.

Trouve l'IP LAN de rex, son adresse sur ton réseau domestique. Sous Linux, `hostname -I` en affiche plusieurs : prends celle de ton réseau domestique, pas celle qui commence par `172.17.` (Docker) ou `100.` (Tailscale). Sous macOS, `ipconfig getifaddr en0` l'affiche (`en1` si ça ne renvoie rien). Sous Windows, `ipconfig` l'indique comme **IPv4 Address** sous ton adaptateur Wi-Fi ou Ethernet. **Cette page l'écrit `192.168.1.20` partout : mets la tienne à sa place.** Les apps Plex, ton app et tes propres commandes joignent rex à cette adresse.

**Plex Media Server tourne sur la même machine ?** Termine la commande de démarrage de rex ci-dessous par `--port 32500` et utilise `32500` partout où une commande ou un réglage indique `32400`, y compris dans la règle du pare-feu Windows. Plex occupe déjà le port 32400 et les ports que les apps utilisent pour trouver les serveurs ; sur un autre port, rex ne touche pas à ceux-là. Tes apps listeront alors deux serveurs avec le nom de la machine : rex est celui qui est partagé avec toi, avec le nom du nouveau compte à côté. Une fois rex lié à son compte Plex ([étape 3](#step-3-add-it-to-a-plex-account)), tu peux le renommer : connecté à Plex avec ce compte, ouvre les **Settings** de rex, **General**, modifie **Friendly name** et enregistre, puis redémarre rex comme indiqué ci-dessous. Les apps Plex l'afficheront sous le nouveau nom après le redémarrage.

Maintenant, fais-en un service :

+++ Linux
Crée `~/.config/systemd/user/rex.service` :

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/rex.service
```

```ini
[Unit]
Description=rex
After=network-online.target

[Service]
WorkingDirectory=%h/rex
EnvironmentFile=-%h/rex/rex.env
ExecStart=%h/rex/rex
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now rex
sudo loginctl enable-linger "$USER"
journalctl --user -u rex -f
```

La **commande de démarrage** de rex est la ligne `ExecStart`, et les clés vont dans `~/rex/rex.env`, une ligne `NAME=value` par clé. Après une modification, `systemctl --user daemon-reload && systemctl --user restart rex` redémarre rex. `journalctl --user -u rex -f` affiche son log. `loginctl enable-linger` garde rex en marche quand tu te déconnectes.
+++ macOS
`run.sh` lance rex dans son dossier, et un LaunchAgent lance `run.sh` quand tu te connectes :

```bash
cp ~/rex/examples/run.sh.example ~/rex/run.sh
mkdir -p ~/Library/LaunchAgents
cat > ~/Library/LaunchAgents/com.rex.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.rex</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/rex/run.sh</string></array>
  <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HOME/rex/rex.log</string>
  <key>StandardErrorPath</key><string>$HOME/rex/rex.log</string>
</dict></plist>
PLIST
launchctl load ~/Library/LaunchAgents/com.rex.plist
tail -F ~/rex/rex.log
```

La **commande de démarrage** de rex est la dernière ligne de `~/rex/run.sh`, et les clés vont dans `~/rex/rex.env`, une ligne `NAME=value` par clé. Après une modification, `launchctl kickstart -k gui/$(id -u)/com.rex` redémarre rex. `tail -f ~/rex/rex.log` affiche son log.

rex tourne tant que tu es connecté au Mac. Pour un Mac qui redémarre tout seul, active la connexion automatique (**System Settings**, **Users & Groups**). Si le pare-feu macOS est activé, autorise rex quand macOS le demande, ou ajoute `~/rex/rex` dans les **Options** du pare-feu.
+++ Windows
Ouvre PowerShell **en tant qu'administrateur** et va dans le dossier de rex avec `cd $HOME\rex`. Crée d'abord `run.cmd`, qui lance rex dans son dossier et écrit son log dans `rex.log`. Le Bloc-notes propose de créer le fichier :

```powershell
notepad run.cmd
```

```bat
@echo off
cd /d "%~dp0"
rex.exe 2>> rex.log
```

Enregistre. Puis autorise ton réseau à passer le pare-feu Windows pour le port de rex et les deux ports de découverte, et lance rex maintenant et à chaque connexion :

```powershell
New-NetFirewallRule -DisplayName rex -Protocol TCP -LocalPort 32400
New-NetFirewallRule -DisplayName "rex discovery" -Protocol UDP -LocalPort 32410,32414
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask rex -Action (New-ScheduledTaskAction -Execute "$HOME\rex\run.cmd") -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME) -Settings $settings
Start-ScheduledTask rex; Start-Sleep 3
Get-Content rex.log -Wait
```

La **commande de démarrage** de rex est la ligne `rex.exe` de `run.cmd`, et les clés vont au-dessus, une ligne `set NAME=value` par clé. Après une modification, `Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex` redémarre rex. `Get-Content $HOME\rex\rex.log -Wait` affiche son log.

Tu as lancé rex à la main dans PowerShell ? Alors son log n'existe que dans cette fenêtre, sans `rex.log`, et aucune tâche ne le relance après un redémarrage. rex garde sa base de données et son lien de propriété dans le dossier depuis lequel il démarre : un rex lancé depuis un autre dossier est un nouveau serveur, non lié. Arrête-le avec Ctrl+C, puis relance-le depuis le dossier de rex avec les mêmes options, ou mieux, mets en place la tâche ci-dessus.

rex tourne tant que tu es connecté à Windows, dans sa propre fenêtre : laisse-la ouverte. Dans PowerShell, tape `curl.exe` partout où cette page écrit `curl` : la commande `curl` de Windows PowerShell est une autre commande.
+++

**Ce que tu dois voir.** Parmi les premières lignes :

```
INFO    seeded rex.db: an empty library named yourhost, machine=...
INFO    no source yet: a source registers itself once pointed at this server (PUT /rex/sources/{name}, docs/feed-api.md)
INFO    claim state: unclaimed
INFO    rex on http://192.168.1.20:32400  machine=...  items=0  parts=proxy
```

rex se nomme d'après la machine ; tes apps Plex affichent ce nom. `no source yet` est normal : aucune app ne s'est encore enregistrée. Laisse le log ouvert.

## Étape 2. Le voir fonctionner à la main {#step-2-see-it-work-by-hand}

**Ce que ça fait.** Joue le rôle de ton app pour un seul film, avec un petit serveur de fichiers jetable et deux commandes `curl`.

**Pourquoi c'est important.** Ça prouve que rex fonctionne sur cette machine avant que ton app n'intervienne. Si cette étape marche et que ton app non, le problème est dans ton app. Passe cette étape si ton app est déjà configurée.

Tu as besoin de `ffprobe`, d'un petit serveur web et d'un fichier vidéo. Tu enregistres le dossier du fichier auprès de rex sous le nom `test`, puis tu envoies à rex le fichier, en indiquant que c'est le film Sintel (IMDb `tt1727587`, TMDB `45745`) avec la sortie de ffprobe.

+++ Linux et macOS
Installe `ffprobe` et `jq` (`sudo apt install -y ffmpeg jq` sur Linux, `brew install ffmpeg jq` sur macOS). Mets le fichier à un endroit où un petit serveur web peut le servir :

```bash
mkdir -p ~/rex-test/movies/Sintel.2010
cp /path/to/any-video.mkv ~/rex-test/movies/Sintel.2010/Sintel.2010.mkv
cd ~/rex-test
python3 -m http.server 8099 --bind 127.0.0.1 &
```

Enregistre-le auprès de rex :

```bash
curl -s -X PUT http://192.168.1.20:32400/rex/sources/test \
  -H 'Content-Type: application/json' -d '{"url": "http://127.0.0.1:8099"}'
```

Envoie le fichier à rex :

```bash
P=movies/Sintel.2010/Sintel.2010.mkv
jq -n --arg p "$P" \
  --argjson probe "$(ffprobe -v quiet -print_format json -show_format -show_streams "$P")" \
  '{items: [{id: $p, path: $p, kind: "movie", ids: {imdb: "tt1727587", tmdb: 45745}, media_info: $probe}]}' \
| curl -s -X POST http://192.168.1.20:32400/rex/feed/test/items \
    -H 'Content-Type: application/json' --data-binary @-
```
+++ Windows
Installe `ffprobe` et Python avec `winget install Gyan.FFmpeg` et `winget install Python.Python.3.13`, puis ouvre une nouvelle fenêtre PowerShell. Mets le fichier à un endroit où un petit serveur web peut le servir :

```powershell
New-Item -ItemType Directory -Force $HOME\rex-test\movies\Sintel.2010 | Out-Null
Copy-Item C:\path\to\any-video.mkv $HOME\rex-test\movies\Sintel.2010\Sintel.2010.mkv
cd $HOME\rex-test
$server = Start-Process py '-m http.server 8099 --bind 127.0.0.1' -WindowStyle Hidden -PassThru
```

Enregistre-le auprès de rex :

```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/test -ContentType application/json -Body '{"url": "http://127.0.0.1:8099"}'
```

Envoie le fichier à rex :

```powershell
$p = 'movies/Sintel.2010/Sintel.2010.mkv'
$probe = ffprobe -v quiet -print_format json -show_format -show_streams $p | Out-String | ConvertFrom-Json
$item = @{ id = $p; path = $p; kind = 'movie'; ids = @{ imdb = 'tt1727587'; tmdb = 45745 }; media_info = $probe }
Invoke-RestMethod -Method Post http://192.168.1.20:32400/rex/feed/test/items -ContentType application/json -Body (ConvertTo-Json @{ items = @($item) } -Depth 20)
```

PowerShell affiche les réponses de rex sous forme de listes plutôt que de JSON.
+++

**Ce que tu dois voir.** La réponse est `{"created":1,"updated":0,"held":0,"unchanged":0}` et le log de rex affiche :

```
INFO    FEED identified "Sintel.2010" -> movie tmdb:45745 (placed)
INFO    FEED test upsert: 1 created, 0 updated, 0 held, 0 unchanged, 0 rejected
```

Sintel apparaît maintenant dans **Movies**, en lecture depuis le petit serveur web. Aucune app Plex ne peut ouvrir rex avant l'[étape 3](#step-3-add-it-to-a-plex-account), donc cette étape vérifie seulement le flux.

**Nettoyage** avant de continuer : supprimer la source de test supprime tout ce qu'elle a envoyé. La première requête répond avec un chemin `confirm` ; envoie un `DELETE` à ce chemin dans les cinq minutes.

+++ Linux et macOS
```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/test
curl -s -X DELETE "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
kill %1
```
+++ Windows
```powershell
Invoke-RestMethod -Method Delete http://192.168.1.20:32400/rex/sources/test
Invoke-RestMethod -Method Delete "http://192.168.1.20:32400/rex/sources/test/confirm/<code from the answer>"
Stop-Process -InputObject $server
```
+++

**En cas d'échec.**

- `"held":1` : `media_info` est absent ou n'a aucun flux. Vérifie que `ffprobe` a affiché du JSON pour le fichier.
- Une réponse avec `rejected` : le fichier n'est pas une vidéo d'après son extension, c'est un échantillon, il n'a pas de `id` ou de `path`, il a un chemin mal formé, ou un autre `id` a déjà ce chemin. La réponse et le log de rex donnent chaque raison.
- `404 no such source` : le `PUT /rex/sources/test` ne s'est pas fait avant.

## Étape 3. L'ajouter à un compte Plex {#step-3-add-it-to-a-plex-account}

**Ce que ça fait.** Enregistre rex sur un compte Plex, comme tu le ferais pour un vrai Plex Media Server, puis le partage avec ton propre compte.

**Pourquoi c'est important.** rex récupère le nom, l'affiche, le résumé et les noms des épisodes de chaque titre depuis les métadonnées de Plex elles-mêmes, et il ne peut les demander à Plex qu'une fois rattaché à un compte. Ce que ton application envoie avant la revendication est nommé dès qu'il arrive, et Fix Match n'a rien à proposer tant que ce n'est pas fait. Cela supprime aussi la notice « unclaimed », et c'est nécessaire pour [utiliser rex en dehors de chez toi](#use-it-outside-your-home-optional).

**Utilise un compte Plex neuf pour cette étape, pas le tien.** rex n'est pas fait par Plex, et Plex pourrait prendre des mesures contre un compte qui enregistre rex. Garde ton vrai compte, avec son historique de visionnage, ses amis et ton Plex Pass éventuel, à l'abri : crée un nouveau compte gratuit sur [plex.tv](https://www.plex.tv) avec une adresse e-mail que tu n'utilises nulle part ailleurs, enregistre rex sur ce compte, puis partage rex avec ton propre compte. Tu regardes ensuite connecté(e) en tant que toi-même, comme tu le ferais sur le serveur d'un ami. rex ne lit rien tant que cette étape n'est pas terminée.

### Enregistrer rex sur le nouveau compte {#register-rex-on-the-fresh-account}

1. Connecte-toi à [plex.tv](https://www.plex.tv) **avec le compte neuf**, ouvre [plex.tv/claim](https://www.plex.tv/claim) et copie le code. Il expire au bout d'environ cinq minutes.
2. Sur la machine rex (`curl.exe` sous Windows) :

   ```bash
   curl -X POST "http://192.168.1.20:32400/myplex/claim?token=claim-xxxxxxxxxxxx"
   curl -s http://192.168.1.20:32400/identity
   ```

**Ce que tu devrais voir.** La deuxième commande affiche `claimed="1"`, et le fichier `claim_state.json` existe dans le dossier de rex. Sauvegarde ce fichier : sans lui, rex doit être à nouveau associé, et il refuse une nouvelle association tant que le fichier est présent. À partir de maintenant, les titres arrivent avec leur nom et leurs affiches, sans redémarrage.

**Si ce n'est pas le cas.**

- La première commande répond `409` avec `rex: already claimed` : rex est déjà associé à un compte Plex.
- Elle répond `500 Internal Server Error` et rex écrit `claim exchange failed` dans son journal : le code a expiré ou a déjà été utilisé. Demande-en un nouveau sur [plex.tv/claim](https://www.plex.tv/claim).

### Le partager avec votre propre compte {#share-it-with-your-own-account}

1. Toujours connecté avec le compte neuf, ouvre [app.plex.tv](https://app.plex.tv), puis **Settings** (la clé à molette), **Manage Library Access** et **Grant Library Access**.
2. Saisis le nom d'utilisateur ou l'adresse e-mail de ton propre compte, choisis le serveur rex et les deux bibliothèques, **Movies** et **TV Shows**, puis envoie l'invitation.
3. Déconnecte-toi, connecte-toi en tant que **toi**, et accepte l'invitation. Elle arrive par e-mail et dans app.plex.tv.

![Manage Library Access in app.plex.tv's settings, with the Grant Library Access button](../assets/rex/20-plex-manage-library-access.webp)

![The Grant Library Access dialog with the rex server's Movies and TV Shows ticked](../assets/rex/21-plex-grant-library-access.webp)

**Ce que tu dois voir.** Connecté avec ton compte, les applications Plex affichent le serveur rex à côté de tes propres serveurs, avec les deux bibliothèques. Ton historique de visionnage sur rex est le tien : il est séparé de celui du compte neuf. Partage-le de la même façon avec les autres personnes de ton foyer.

## Étape 4. Connecter votre app {#step-4-connect-your-app}

**Ce que ça fait.** Vous indiquez à votre application l'adresse de rex. Votre application s'enregistre, envoie toute sa bibliothèque, puis chaque modification au fur et à mesure.

**Pourquoi c'est important.** C'est le seul lien entre les deux. rex n'a aucun réglage pour votre application : c'est votre application qui trouve rex, et non l'inverse.

Donnez à votre application l'adresse de rex, `http://192.168.1.20:32400`. La façon de la saisir dépend de votre application.

**Ce que vous devriez voir.** Le journal de rex affiche, sous le nom avec lequel votre application s'est enregistrée :

```
INFO    SOURCES myapp registered at http://192.168.1.20:8080
INFO    SOURCES PUT /rex/sources/myapp -> 200
INFO    FEED myapp upsert: 0 created, 0 updated, 200 held, 0 unchanged, 0 rejected
INFO    FEED identified "Some.Movie.2019.1080p" -> movie tmdb:12345 (placed)
INFO    FEED myapp upsert: 180 created, 0 updated, 20 held, 0 unchanged, 0 rejected
```

rex lit chaque fichier à l'adresse indiquée sur la ligne `registered at`. Votre application doit donc être joignable à cette adresse. rex réécrit cette ligne uniquement quand l'adresse change. Les fichiers `held` attendent la sortie de ffprobe et apparaissent dès que votre application l'envoie. Vous pouvez vérifier à tout moment ce que rex a reçu de votre application (sous Windows, utilisez `curl.exe` sans `| head -c 600`) :

```bash
curl -s http://192.168.1.20:32400/rex/sources                # the apps that registered, and their addresses
curl -s http://192.168.1.20:32400/rex/feed/myapp/items | head -c 600   # what is shown
curl -s http://192.168.1.20:32400/rex/feed/myapp/held  | head -c 600   # what waits for ffprobe output
```

**Si ce n'est pas le cas.**

- Aucune ligne dans le journal de rex : votre application n'a jamais atteint rex. Vérifiez l'adresse que vous lui avez donnée, ainsi que l'ouverture du port de rex entre les deux machines.
- Des fichiers arrivent, mais aucune ligne `identified` : votre application n'envoie pas de `kind` ni de `ids` (les fichiers `held` et les renvois sans changement n'affichent rien non plus). Ces titres restent sans correspondance tant que ce n'est pas corrigé. Vous pouvez tout de même en corriger un à la main avec **Fix Match** dans une application Plex connectée avec le compte neuf. Votre propre compte, avec lequel rex est partagé, est refusé.
- Les titres apparaissent, mais rien ne se lance : rex ne peut pas joindre votre application à l'adresse `registered at`. La ligne `upstream failed` de [Quand quelque chose ne va pas](#when-something-is-wrong) permet de le vérifier.

## Étape 5. Regarder quelque chose {#step-5-watch-something}

**Ce que ça fait.** Ouvre rex dans une application Plex, de la même façon que n'importe quel serveur Plex.

**Pourquoi c'est important.** C'est le but de toute l'installation. Ça prouve aussi le dernier maillon : rex lit un fichier depuis votre application pendant que vous regardez.

Ouvrez une application Plex sur un téléphone, une TV ou un ordinateur **sur le même réseau domestique**. rex apparaît sous le nom de la machine, avec **Movies** et **TV Shows**. Choisissez un film et appuyez sur lecture.

![Une application Plex affichant les bibliothèques Movies et TV Shows du serveur rex dans la barre latérale, à côté d'une grille de films](../assets/rex/10-plex-server-libraries.webp)

À la maison, rien d'autre n'est nécessaire : les applications Plex trouvent rex avec la découverte locale de Plex et se connectent à lui via votre réseau. Il faut que l'appareil soit sur le même réseau que rex (pas un Wi-Fi invité ni un VLAN séparé). La découverte utilise les ports UDP 32410 et 32414, donc un pare-feu sur la machine rex doit les laisser passer (sous Windows, les règles de pare-feu de l'étape 1 s'en chargent). rex répond à la découverte quand il utilise le port 32400. Si vous avez déplacé rex sur le port 32500 parce que Plex tourne sur la même machine, la découverte est laissée à ce Plex, et les applications trouvent rex via le compte Plex avec lequel il est [partagé](#share-it-with-your-own-account). app.plex.tv dans un navigateur web fonctionne aussi à la maison, via l'adresse HTTPS que [rex-direct](#rex-direct) donne à rex une fois qu'il est revendiqué (rex nightly 2026.11.02 ou plus récent). La première fois, Chrome demande si app.plex.tv peut accéder aux appareils de votre réseau local : autorisez-le. `http://192.168.1.20:32400/web` n'est pas Plex Web : rex n'a pas d'application web à lui, et cette page indique seulement si rex est revendiqué et où regarder.

**Ce que vous devriez voir.** Les affiches, les titres et les années comme sur n'importe quel serveur Plex. La lecture démarre en quelques secondes.

Deux choses que vous pourriez rencontrer :

- **"yourhost server is unclaimed and not secure".** Une application Plex affiche ce message pour tout serveur qui n'est pas lié à un compte Plex, et rex ne lit rien tant qu'il ne l'est pas. Faites l'[étape 3](#step-3-add-it-to-a-plex-account).
- **"This server is not powerful enough to convert video".** Si chaque titre échoue sur chaque appareil, regardez le journal de rex juste après avoir appuyé sur Play : `upstream failed` ou `502` signifie que rex ne peut pas joindre votre application, et FFmpeg n'y changera rien. La ligne `upstream failed` de [Quand quelque chose ne va pas](#when-something-is-wrong) indique quoi faire. Si seuls certains fichiers échouent, souvent uniquement dans un navigateur web, l'appareil ne peut pas les lire tels quels, souvent à cause du son AC3 ou DTS. Les applications Plex sur TV et téléphone lisent la plupart des fichiers tels quels. Pour tout lire partout, configurez la [Conversion de la vidéo](#converting-video-optional) (facultatif).

**Supprimer supprime chez votre application.** Connecté avec le compte neuf, **Delete** sur un titre dans une application Plex demande à rex de faire supprimer le fichier par votre application, comme l'explique [Ce que votre application doit faire](#what-your-app-must-do). Les comptes avec lesquels rex est partagé ne peuvent pas supprimer. Pour désactiver la suppression : dans app.plex.tv avec le compte neuf, ouvrez **Settings**, la **Library** du serveur rex, **Show Advanced**, décochez **Allow media deletion** et enregistrez.

![Les réglages Library du serveur rex avec Show Advanced ouvert et Allow media deletion encadré](../assets/rex/32-plex-allow-media-deletion.webp)

Un fichier que votre application retire part dans la corbeille de la bibliothèque, comme dans Plex : il reste, indisponible, avec son historique de visionnage, et revient tel qu'il était si votre application le renvoie. **Empty Trash** sur la bibliothèque le supprime définitivement, et **Empty trash automatically after every scan** (Settings, Library), désactivé par défaut, le fait tout seul.

Chaque fichier va dans **Movies** ou **TV Shows** selon le `kind` envoyé par votre application. Un fichier sans `kind` va selon son premier dossier : `shows` va dans TV Shows, tout le reste va dans Movies.

Pour donner à un dossier ses propres bibliothèques, votre application ajoute `directories` à son enregistrement, en nommant le premier dossier des chemins des fichiers et les titres des bibliothèques : `{"url": ..., "directories": [{"name": "anime", "shows": "Anime", "movies": "Anime Movies"}]}`. Un seul titre suffit. rex les crée quand votre application s'enregistre et y déplace ce que ce dossier contient déjà, tel quel : historique de visionnage, Fix Match et modifications compris. Une entrée mal formée est ignorée et listée sous `ignored` dans la réponse, avec la raison. Renommez-les comme vous voulez dans une application Plex. Si vous en supprimez une, elle reste supprimée, et ses fichiers retournent dans Movies ou TV Shows, jusqu'à ce que vous la rajoutiez avec **Add Library**, dont la liste de dossiers montre les dossiers de votre application. [Libraries a source declares](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#libraries-a-source-declares) détaille les règles.

**Sauvegardez** `rex.db` dans le dossier de rex (il contient votre bibliothèque, votre historique de visionnage et la connexion de votre application, gardez-le privé), `claim_state.json` et, une fois que rex-direct a donné un nom à rex, `rex-direct.json` (sa clé de certificat) :

+++ Linux et macOS
```bash
sudo apt install -y sqlite3    # once, on Linux; macOS has it
mkdir -p ~/rex-backup
sqlite3 ~/rex/rex.db ".backup $HOME/rex-backup/rex.db"
cp ~/rex/*.json ~/rex-backup/
```
+++ Windows
Windows n'a pas de `sqlite3`, donc arrêtez rex un instant et copiez `rex.db` avec les deux fichiers à côté qui commencent pareil :

```powershell
Stop-Process -Name rex; Start-Sleep 1
New-Item -ItemType Directory -Force $HOME\rex-backup | Out-Null
Copy-Item $HOME\rex\rex.db*, $HOME\rex\*.json $HOME\rex-backup
Start-ScheduledTask rex
```
+++

Dans Docker, les fichiers se trouvent dans `~/rex/config`, lisibles par root uniquement. Sauvegardez depuis l'intérieur du conteneur avec `docker exec rex sqlite3 /config/rex.db ".backup /config/rex.db.bak"`, puis `mkdir -p ~/rex-backup && sudo cp ~/rex/config/rex.db.bak ~/rex/config/*.json ~/rex-backup/`.

[Restaurer une sauvegarde](#restore-a-backup) les remet en place.

Vous avez terminé. Les sections ci-dessous sont facultatives.

## Utiliser rex hors de chez vous (facultatif) {#use-it-outside-your-home-optional}

**Ce que ça fait.** Donne à rex une adresse HTTPS que les applications Plex hors de chez vous peuvent joindre, et la signale à plex.tv.

**Pourquoi c'est important.** Hors de chez vous, app.plex.tv se connecte uniquement à une adresse HTTPS, et les autres applications Plex la privilégient. Un vrai serveur Plex peut se rabattre sur le relais de Plex, mais rex ne le peut pas. C'est donc à vous de choisir comment on le joint. rex doit d'abord être [réclamé](#step-3-add-it-to-a-plex-account). Un proxy exposé à Internet doit bloquer `/rex/` : voir [Gardez le port privé](#keep-the-port-private).

**Plex Pass.** Plex Web lit hors de chez vous sans Plex Pass ni Remote Watch Pass sur aucun des deux comptes. Les autres applications Plex n'ont pas encore été testées hors de chez vous.

Quel que soit votre choix, chaque octet que vous regardez hors de chez vous sort par le débit d'**upload** de votre connexion domestique. À titre indicatif, un upload de 20 Mbit/s permet de diffuser un WEB-DL 1080p, pas un remux.

| Votre situation | Utilisez | Pourquoi |
|---|---|---|
| Votre routeur a une IP publique et vous pouvez rediriger un port | **[rex-direct](#rex-direct)** (le plus simple) | Activé par défaut : une seule redirection de port. DMM donne à rex un nom et un certificat, et garde ce nom pointé vers votre IP domestique |
| Vous pouvez installer Tailscale sur les appareils avec lesquels vous regardez | **[Tailscale serve](#tailscale-serve)** (le meilleur) | Rien à ouvrir sur votre routeur, et ça fonctionne derrière n'importe quelle connexion Internet. Le certificat se renouvelle tout seul, et personne en dehors de votre tailnet ne peut joindre rex |
| Appareils sans Tailscale (la TV d'un ami, un hôtel), et votre routeur a une IP publique | **[Caddy](#caddy)** avec votre propre domaine, ou avec un nom `sslip.io` gratuit | Une connexion directe sans intermédiaire, et un certificat gratuit qui se renouvelle tout seul. Vous redirigez le port 443 |
| Votre connexion n'a pas d'IPv4 publique (CGNAT ou DS-Lite, fréquent chez le câble, le mobile et certains opérateurs fibre), mais a l'IPv6 | **[rex-direct over IPv6](#rex-direct-over-ipv6)** | Pas de redirection de port et rien à louer : vous laissez passer le port 32400 en IPv6. Les appareils avec lesquels vous regardez doivent aussi avoir l'IPv6, ce qui est le cas de la plupart des réseaux mobiles |
| Votre connexion n'a aucune IP publique, ou vous regardez sur des réseaux sans IPv6, et appareils sans Tailscale | **[Un petit VPS](#a-small-vps)** | rex n'a pas de relais et n'en aura pas. Un VPS loué possède l'IP publique, et un tunnel fait passer tout le trafic jusqu'à rex, à la pleine bande passante du VPS |

Non recommandé :

- **Tunnel Cloudflare.** Chaque octet passe par Cloudflare, qui supprime aussi le `Range` de la première lecture d'un fichier. Chaque démarrage de lecture télécharge donc tout le fichier depuis votre application.
- **Tailscale Funnel, ngrok et autres tunnels hébergés.** Ils limitent la bande passante ou le volume mensuel de données, qu'un film consomme vite. Tailscale Funnel publie aussi tout rex, y compris l'API du flux : n'importe qui sur Internet pourrait ajouter ou supprimer des éléments de votre bibliothèque.
- **Rediriger le port 32400 sans rex-direct ni certificat à vous.** Les applications Plex recevraient une adresse HTTP simple, que app.plex.tv refuse.

### rex-direct

rex-direct est la réponse de DMM à plex.direct, et il est activé par défaut. Sur votre routeur, redirigez le port 32400 (TCP) vers la machine rex. C'est tout, sans rien redémarrer.

Une fois rex réclamé, DMM lui attribue deux noms : `<hash>.rex-direct.debridmediamanager.com`, pointant vers l'IP publique de votre domicile, et `lan.<hash>.rex-direct.debridmediamanager.com`, pointant vers l'IP LAN de rex, avec un certificat pour les deux. Le premier certificat prend quelques minutes ; le journal de rex indique qu'il est en cours d'émission, puis affiche chaque nom dans une ligne `rex-direct:`. Une nouvelle IP domestique et les renouvellements de certificat sont pris en compte automatiquement. Un même compte Plex peut avoir jusqu'à dix noms rex-direct. À la maison, les applications Plex, app.plex.tv comprise, peuvent utiliser le nom `lan.`, qui atteint rex directement par votre réseau ; la redirection de port ne sert donc que hors de chez vous. Dans app.plex.tv, autorisez l'accès aux appareils du réseau local quand Chrome le demande, sinon l'application revient au nom public, qui nécessite la redirection de port. [Ce que vous devez voir](#what-you-should-see) permet de vérifier les deux noms.

Si votre routeur redirige vers rex un autre port externe, ajoutez la clé `REX_DIRECT_PORT=<that port>` comme l'indique [étape 1](#step-1-install-rex) pour votre système, puis redémarrez rex. La redirection de port n'ouvre pas l'API du flux : voir [Gardez le port privé](#keep-the-port-private).

### rex-direct sur IPv6 {#rex-direct-over-ipv6}

Pour une connexion sans IPv4 publique (CGNAT ou DS-Lite) mais avec IPv6. Une fois que DMM s'est connecté à rex via son adresse IPv6 et a trouvé le même serveur là-bas, il pointe aussi le nom rex-direct de rex vers cette adresse. Il te faut rex nightly 2026.11.08 ou plus récent, et, avec Docker, le réseau host.

L'IPv6 n'a pas de redirection de port, ni de mapping de port : rex doit utiliser le même port à l'intérieur et à l'extérieur, donc laisse `REX_DIRECT_PORT` non défini. Dans le pare-feu de ton routeur, autorise les connexions TCP entrantes sur le port 32400 vers la machine qui fait tourner rex, en IPv6. rex publie son IPv6 une minute après son démarrage (ou après avoir été réclamé), puis toutes les 6 heures. Ajoute donc la règle avant de démarrer rex, ou redémarre rex après l'avoir ajoutée. Une minute environ plus tard, son journal affiche les deux adresses :

```
rex-direct: https://<hash>.rex-direct.debridmediamanager.com:32400 -> <IPv4> and <IPv6>
```

Si aucune ligne avec `and <IPv6>` n'apparaît au bout de quelques minutes, DMM n'a pas pu joindre rex en IPv6. Vérifie la règle du pare-feu, et que rex dans Docker utilise bien le réseau host. Sous Windows, rex publie l'adresse IPv6 temporaire de Windows, que Windows remplace environ une fois par jour. Désactive les adresses temporaires avec `netsh interface ipv6 set privacy state=disabled` dans un PowerShell en administrateur, puis redémarre rex pour qu'il publie l'adresse stable. Le `<IPv4>` de cette ligne est l'adresse partagée de ton fournisseur et n'atteint pas rex. Les appareils depuis lesquels tu regardes doivent donc aussi avoir l'IPv6. La plupart des réseaux mobiles l'ont. Un hôtel ou un bureau en IPv4 seulement ne pourra pas joindre rex de cette façon.

### Tailscale serve

Installez [Tailscale](https://tailscale.com/download) sur la machine rex et sur les appareils depuis lesquels vous regardez, connectés au même compte. Ensuite, sur la machine rex :

```bash
sudo tailscale serve --bg 32400
```

Sous Windows, lancez-la dans PowerShell en tant qu'administrateur, sans `sudo`. Sous macOS, utilisez l'[outil en ligne de commande](https://tailscale.com/kb/1080/cli) de l'application Tailscale, sans `sudo`.

Elle affiche l'adresse, par exemple `https://myhost.tailnet.ts.net`. Donnez-la à rex en ajoutant `:443` : complétez la commande de démarrage de rex de l'[étape 1](#step-1-install-rex) avec `--announce-url https://myhost.tailnet.ts.net:443`, puis redémarrez rex.

Tout le monde sur votre tailnet, y compris les personnes avec qui vous partagez cette machine, peut utiliser l'API de flux de rex. Ne partagez la machine qu'avec des personnes de confiance.

### Caddy

Vous devez rediriger le port 443 de votre routeur vers la machine qui fait tourner rex, et avoir un nom pour l'adresse IP de votre domicile :

- **Votre propre domaine :** un enregistrement `A` tel que `rex.example.com` pointant vers l'IP de votre domicile.
- **Pas de domaine :** utilisez `1-2-3-4.sslip.io` avec les chiffres de votre IP publique (`curl -s ifconfig.me` l'affiche). Si votre IP change, mettez à jour le nom.

Installez [Caddy](https://caddyserver.com/docs/install) et donnez-lui ce Caddyfile (`/etc/caddy/Caddyfile` avec le paquet Linux de Caddy ; sous macOS et Windows, un fichier nommé `Caddyfile` dans un dossier à part, que `caddy run` lit depuis ce dossier) :

```
rex.example.com {
	respond /rex/* 403
	reverse_proxy 192.168.1.20:32400
}
```

`respond /rex/* 403` empêche l'API de flux d'être accessible depuis Internet ; votre application atteint toujours rex directement. Rechargez ensuite Caddy (`sudo systemctl reload caddy` avec le paquet Linux). Sous macOS et Windows, lancez plutôt `caddy run` dans son dossier et laissez-le tourner comme le fait [l'étape 1](#step-1-install-rex) pour rex ; sous Windows, autorisez aussi le port TCP 443 dans le pare-feu, comme à l'étape 1 pour le port 32400. Terminez ensuite la commande de démarrage de rex par `--announce-url https://rex.example.com:443`, puis redémarrez rex.

### Un petit VPS {#a-small-vps}

Pour une connexion sans IP publique du tout, ou quand vous regardez depuis des réseaux sans IPv6 : le VPS transporte alors tous les flux, à la place de [rex-direct sur IPv6](#rex-direct-over-ipv6). rex n'a pas de relais et n'en aura pas, donc un serveur que vous louez remplace votre routeur : il a l'IP publique, et un tunnel depuis la machine rex transporte tout jusqu'à rex. Tout VPS avec une IPv4 publique convient, pour quelques euros par mois. **Choisissez-en un dont le trafic mensuel couvre ce que vous regardez hors de chez vous :** chaque octet passe par lui, et une offre avec un petit quota de données sera vite épuisée.

Il vous faut l'IP du VPS (`1.2.3.4` ci-dessous), les ports 443, 80 et 7000 ouverts dessus, et une longue chaîne aléatoire pour le tunnel (`openssl rand -hex 32`).

**Sur le VPS**, installez [frp](https://github.com/fatedier/frp/releases) (le programme `frps`) et [Caddy](https://caddyserver.com/docs/install). Créez `frps.toml` :

```toml
bindPort = 7000
auth.token = "your-long-random-string"
proxyBindAddr = "127.0.0.1"
```

`proxyBindAddr` garde l'extrémité du tunnel sur la boucle locale (loopback) du VPS, ainsi internet n'atteint rex que via Caddy. Créez `/etc/caddy/Caddyfile`, avec l'IP du VPS sous la forme `1-2-3-4.sslip.io` (un nom gratuit qui pointe toujours vers cette IP) ou avec votre propre domaine qui pointe dessus :

```
1-2-3-4.sslip.io {
	respond /rex/* 403
	reverse_proxy 127.0.0.1:32400
}
```

`respond /rex/* 403` empêche l'API de flux d'être accessible depuis internet. Lancez `frps -c frps.toml` en tant que service, puis exécutez `sudo systemctl reload caddy`.

**Sur la machine rex**, installez aussi frp (le programme `frpc`) et créez `frpc.toml` :

```toml
serverAddr = "1.2.3.4"
serverPort = 7000
auth.token = "your-long-random-string"

[[proxies]]
name = "rex"
type = "tcp"
localIP = "192.168.1.20"
localPort = 32400
remotePort = 32400
```

Lancez-le comme service : sous Linux, par exemple `~/.config/systemd/user/frpc.service` avec `ExecStart=%h/frp/frpc -c %h/frp/frpc.toml` et `Restart=always` ; sous macOS et Windows, lancez `frpc -c frpc.toml` de la même manière que vous lancez rex à l'[étape 1](#step-1-install-rex). Ensuite, terminez la commande de démarrage de rex par `--announce-url https://1-2-3-4.sslip.io:443`, ajoutez la clé `REX_DIRECT_URL=off` (derrière CGNAT, l'IPv4 du nom rex-direct n'atteint pas rex, donc plex.tv ne doit pas le lister), puis redémarrez rex. app.plex.tv à la maison passe alors aussi par le VPS ; les autres applications Plex à la maison se connectent toujours directement à rex.

### Ce que vous devriez voir {#what-you-should-see}

```bash
curl -s https://lan.<hash>.rex-direct.debridmediamanager.com:32400/identity
```

affiche une courte page XML avec le `machineIdentifier` de rex sur un ordinateur à la maison ; `curl` n'affiche rien si l'adresse ou son certificat est incorrect. Utilisez votre propre adresse : rex l'affiche au démarrage sous la forme `rex-direct: https://lan.<hash>.rex-direct.debridmediamanager.com:32400 -> 192.168.1.20 (LAN)` (avec `REX_DIRECT_URL=off`, il n'y en a aucune). Ouvrez votre adresse externe avec `/identity` ajouté dans le navigateur d'un téléphone, Wi-Fi désactivé : avec rex-direct, c'est l'autre ligne `rex-direct:` de rex, et avec Tailscale serve `https://myhost.tailnet.ts.net`, que le téléphone n'ouvre qu'avec Tailscale activé. Elle affiche une courte page XML, sans avertissement de certificat.

Si le téléphone échoue, le port n'est pas redirigé (ou, [en IPv6](#rex-direct-over-ipv6), pas autorisé), votre connexion est derrière un CGNAT sans IPv6, rex n'est joignable qu'en IPv6 et le réseau du téléphone n'en a pas, ou le certificat de rex-direct est encore en cours d'émission (le journal de rex l'indique tant que c'est le cas).

Le journal de rex indique les adresses qu'il annonce :

```
INFO    heartbeat every 600s for machine ... -> https://myhost.tailnet.ts.net:443,http://192.168.1.20:32400
```

rex affiche cela à chaque démarrage. Un problème apparaît plus tard sous la forme `heartbeat failed` ou `announced but NOT visible`. Sinon, le serveur liste ces adresses sur plex.tv, et une application Plex hors de la maison choisit celle qu'elle peut joindre. Si rex affiche `waiting for a claim`, faites d'abord l'[étape 3](#step-3-add-it-to-a-plex-account).

## Votre historique de visionnage depuis un autre serveur Plex (facultatif) {#your-watch-history-from-another-plex-server-optional}

Vous avez déjà regardé sur un autre serveur Plex ? Une fois votre bibliothèque dans rex, [Importez votre historique de visionnage](import-watched.md) copie ce que vous avez regardé, l'endroit où vous vous êtes arrêté et vos notes en étoiles, pour chaque personne séparément.

## Convertir la vidéo (facultatif) {#converting-video-optional}

**Ce que ça fait.** Laisse rex convertir ce qu'un appareil ne peut pas lire, comme le fait Plex.

**Pourquoi c'est important.** Sans cela, un appareil qui ne peut pas lire un fichier tel quel affiche « This server is not powerful enough to convert video ». Les navigateurs web sont les plus touchés, par exemple avec le son AC3 ou DTS. Si chaque titre échoue sur chaque appareil, la cause est ailleurs : voir [étape 5](#step-5-watch-something).

Installez **jellyfin-ffmpeg** 8, et non le `ffmpeg` proposé par votre système : c'est la version avec laquelle rex est mesuré, et la seule qui convertit tous les fichiers Dolby Vision, tone-mape le HDR sur la puce graphique et dessine les sous-titres là aussi. Un autre FFmpeg convertit les vidéos ordinaires, et le journal de rex indique ce qui lui manque (celui d'Ubuntu 22.04 se décale aussi de quelques secondes lors des recherches). rex le trouve tout seul.

+++ Linux
Le paquet se place dans `/usr/lib/jellyfin-ffmpeg`, à côté de tout autre FFmpeg. La première ligne choisit la version adaptée à votre système : il existe des versions pour Ubuntu 22.04, 24.04 et 26.04 et Debian 12 et 13, en amd64 ou arm64. Sur toute autre distribution, `curl` s'arrête avec une erreur.

```bash
DEB=jellyfin-ffmpeg8_8.1.3-1-$(. /etc/os-release; echo "$VERSION_CODENAME")_$(dpkg --print-architecture).deb
curl -fLO "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/$DEB"
sudo apt install -y "./$DEB" && rm "$DEB"
systemctl --user restart rex
```

Sur une autre distribution Linux, décompressez la version portable de jellyfin-ffmpeg dans `~/rex/ffmpeg`, où rex la cherche, puis redémarrez rex. Elle utilise le pilote graphique de votre système : sur un système ancien, la conversion se fait donc uniquement sur le processeur. Utilisez le paquet dès qu'il existe pour votre système.

```bash
B=$( [ "$(uname -m)" = aarch64 ] && echo linuxarm64 || echo linux64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
```

Avec une puce graphique Intel ou AMD, exécutez aussi `sudo usermod -aG render "$USER"` puis redémarrez pour que le service obtienne le groupe. Dans un LXC, transmettez le GPU. La puce rend la conversion rapide ; sans elle, rex utilise le processeur. Sans puce Intel ni AMD, rex essaie aussi l'encodeur d'une carte NVIDIA. Sur Intel, `sudo apt install intel-opencl-icd` permet aussi de convertir le HDR et le Dolby Vision sur la puce, à peu près en temps réel pour la 4K sur un petit Intel ; sans lui, ils sont convertis sur le processeur, qu'un Intel basse consommation ne peut pas faire en temps réel en 4K.
+++ macOS
La version portable se place dans `~/rex/ffmpeg`, où rex la cherche :

```bash
B=$( [ "$(uname -m)" = arm64 ] && echo macarm64 || echo mac64 )
mkdir -p ~/rex/ffmpeg && curl -fL "https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_${B}-gpl.tar.xz" | tar xJ -C ~/rex/ffmpeg
launchctl kickstart -k gui/$(id -u)/com.rex
```

Sur un Mac, rex convertit toujours sur le processeur : il n'a aucun moyen d'utiliser la puce graphique d'un Mac.
+++ Windows
La version portable se place dans un dossier `ffmpeg`, dans le dossier de rex, où rex la cherche :

```powershell
cd $HOME\rex
curl.exe -fLO https://github.com/jellyfin/jellyfin-ffmpeg/releases/download/v8.1.3-1/jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Expand-Archive jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip ffmpeg
Remove-Item jellyfin-ffmpeg_8.1.3-1_portable_win64-clang-gpl.zip
Stop-Process -Name rex; Start-Sleep 1; Start-ScheduledTask rex
```

Sous Windows, rex utilise l'encodeur d'une carte NVIDIA s'il y en a une, et le processeur sinon.
+++

**Ce que vous devriez voir.** Le journal de rex contient une ligne `transcoder:` qui indique le FFmpeg trouvé et le matériel détecté (`hardware none` signifie le processeur) ; `transcoder off` au démarrage signifie qu'aucun n'a été trouvé. Un fichier qui échouait avant se lit maintenant ; le journal montre ce qui a été converti, par exemple `video=copy h264 audio=ac3->aac`.

Sous-titres dans un fichier converti : un sous-titre image est incrusté dans l'image, et un sous-titre que vous avez envoyé est repris. Plex pour Android et iOS garde aussi un sous-titre texte comme piste ; les autres applications l'incrustent dans l'image. Les téléchargements hors ligne convertis n'incluent toujours pas les sous-titres texte.

## Sous-titres {#subtitles}

**Ce que ça fait.** La recherche de sous-titres dans une application Plex trouve des sous-titres grâce au fournisseur de Plex une fois que rex est revendiqué. rex vérifie celui que vous choisissez par rapport au fichier et corrige son timing lorsqu'il est en retard ou qu'il a été fait pour une autre cadence d'images. Quand votre compte Plex est configuré pour afficher les sous-titres et qu'un titre n'en a pas dans votre langue, rex en cherche un pendant jusqu'à 3 secondes avant de démarrer.

**Pourquoi c'est important.** Le premier résultat proposé par Plex est souvent décalé par rapport au fichier.

![La boîte de dialogue Subtitles search dans une application Plex, listant des résultats en anglais pour Sintel](../assets/rex/51-plex-search-subtitles.webp)

Il n'y a rien à configurer. rex vérifie un sous-titre par rapport au sous-titre texte intégré du fichier lorsqu'il en a un. Un fichier sans sous-titre texte est vérifié par rapport à son son au moment où vous appuyez sur lecture, ce qui nécessite d'avoir configuré [Converting video](#converting-video-optional) et lit six morceaux de 90 secondes du fichier.

**Ce que vous devriez voir.** Le journal de rex contient une ligne `SUBTITLE measured` pour chaque sous-titre vérifié, et `SUBTITLE applied ... corrected by` lorsqu'il en a corrigé un.

## Capacités films et séries {#movie-and-tv-capabilities}

Les téléchargements, la détection de l'intro et des crédits, les miniatures de recherche et les autres fonctionnalités serveur Plex de rex, ainsi que leurs réglages, sont décrits dans le [guide d'installation de rex](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities). La musique et la Live TV viennent de sources qui les envoient ([limites de rex](https://github.com/debridmediamanager/rex#limits)), comme [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) pour les chaînes en direct. Il n'y a pas de DVR, donc rien n'est enregistré. Les photos viennent uniquement d'une source qui envoie des images ([API feed](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md#photos)), comme les bandes dessinées de zurg. Plex Web les affiche ; Plex pour Android n'affiche aucune bibliothèque de photos.

Garde le mode proxy par défaut pour la lecture des debrids partagés. Real-Debrid suit l'IP publique de chaque téléchargeur ; utiliser plusieurs IP avec un même compte déclenche un avertissement de partage, même quand les téléchargements réussissent. Les URL de téléchargement de TorBox contiennent la clé API complète, donc la redirection donne accès à tous les clients et à tous les comptes utilisateurs partagés, y compris la suppression. Lis les [risques de la redirection et l'installation](direct-download.md#before-you-start) avant de laisser les applications télécharger depuis le fournisseur.

## Exécuter rex dans Docker {#run-rex-in-docker}

Ces étapes sont pour une machine Linux. Sur macOS et Windows, Docker Desktop fait tourner les conteneurs dans une machine virtuelle. Le réseau host, la découverte sur le LAN et la carte graphique ne fonctionnent donc pas comme sous Linux : utilise plutôt les étapes ci-dessus.

Crée un dossier, par exemple `~/rex`, avec ce `compose.yml` :

```yaml
services:
  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./config:/config
```

- Puce graphique Intel ou AMD ? Ajoute `devices: ["/dev/dri:/dev/dri"]` pour que rex convertisse la vidéo avec elle.
- `network_mode: host` permet aux apps Plex de ton réseau de trouver rex toutes seules, et permet à rex d'atteindre ton app à l'adresse qu'elle enregistre, comme depuis la machine elle-même.
- `./config` contient `rex.db` et, plus tard, `claim_state.json`. Ils ne sont lisibles que par root, car `rex.db` contient le login de ton app.
- Plex Media Server sur la même machine ? Ajoute `command: --port 32500` et utilise `32500` partout où une commande ou un réglage indique `32400`.

```bash
docker compose up -d
docker compose logs -f rex
```

Tu dois voir les mêmes lignes que [étape 1](#step-1-install-rex). Ensuite, fais les étapes 2 à 5 comme ci-dessus. Si ton app tourne aussi dans un conteneur, elle doit enregistrer une adresse que rex peut atteindre depuis la machine, et non une adresse visible seulement par les autres conteneurs.

Mets à jour avec `docker compose pull && docker compose up -d`. L'image contient jellyfin-ffmpeg, donc [convertir la vidéo](#converting-video-optional) nécessite seulement de passer la puce graphique. HTTPS fonctionne comme ci-dessus : Tailscale, Caddy et frp tournent sur la machine elle-même, et `--announce-url ...` va dans le `command:` du fichier compose.

## Garder le port privé {#keep-the-port-private}

rex n'demande aucun mot de passe sur son API de flux. Il ne répond à cette API que depuis cette machine, depuis votre réseau domestique (10.x, 172.16-31.x, 192.168.x, 169.254.x et les adresses IPv6 privées) et depuis Tailscale (100.64-127.x). Pour tous les autres, il réagit comme si l'API n'existait pas. Transférer le port de rex (pour [rex-direct](#rex-direct)), ou l'autoriser via IPv6, ne l'ouvre donc pas. Un routeur qui donne à ses visiteurs extérieurs sa propre adresse les fait paraître locaux, et cela ouvre le flux à Internet. Votre application doit donc envoyer ses requêtes depuis l'un de ces réseaux. Derrière une box domestique, un appareil avec une adresse IPv6 dans la plage de votre réseau domestique compte aussi : un nom d'hôte qui résout vers l'IPv6 de rex fonctionne donc à la maison ; sur un VPS, désignez rex par une adresse d'un réseau privé. Un proxy installé sur la machine de rex paraît local à rex, donc gardez `/rex/*` bloqué dans tout proxy exposé à Internet, comme dans l'exemple de [Caddy](#caddy).

## Mise à jour {#updating}

rex ne se met jamais à jour tout seul. Relance le bloc de téléchargement de [étape 1](#step-1-install-rex) (il remplace le programme et `data/`, et laisse `rex.db`, tes clés, `claim_state.json` et `rex-direct.json` tranquilles), puis redémarre rex comme le montre l'étape 1. Sous Windows, lance `Stop-Process -Name rex` avant le bloc de téléchargement, car Windows ne permet pas de remplacer un `rex.exe` en cours d'exécution, et `Start-ScheduledTask rex` après. Si rex quitte ensuite avec `unrecognized arguments`, supprime de la commande de démarrage de rex les options qu'il cite : rex ne les a plus.

## Plus tard : restaurer, déplacer, supprimer {#later-restore-move-remove}

### Restaurer une sauvegarde {#restore-a-backup}

Arrête rex, supprime `rex.db` ainsi que les fichiers `rex.db-wal` et `rex.db-shm` qui se trouvent à côté, copie les fichiers de ta sauvegarde dans le dossier de rex, puis relance rex. Si tu laisses l'ancien `rex.db-wal` en place, la restauration est annulée.

+++ Linux
```bash
systemctl --user stop rex
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
systemctl --user start rex
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist
rm -f ~/rex/rex.db ~/rex/rex.db-wal ~/rex/rex.db-shm
cp ~/rex-backup/* ~/rex/
launchctl load ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
```powershell
Stop-Process -Name rex; Start-Sleep 1
Remove-Item $HOME\rex\rex.db*
Copy-Item $HOME\rex-backup\* $HOME\rex
Start-ScheduledTask rex
```
+++ Docker
```bash
cd ~/rex && docker compose down
sudo rm -f config/rex.db config/rex.db-wal config/rex.db-shm
sudo cp ~/rex-backup/rex.db.bak config/rex.db && sudo cp ~/rex-backup/*.json config/
docker compose up -d
```
+++

### Déplacer rex vers une autre machine {#move-rex-to-another-machine}

Sauvegardez comme dans l'[étape 5](#step-5-watch-something), puis arrêtez rex sur l'ancienne machine pour de bon, comme le fait le premier bloc de [Supprimer rex](#remove-rex). Sur la nouvelle, suivez l'[étape 1](#step-1-install-rex), mais copiez les fichiers de votre sauvegarde dans le dossier de rex avant de le transformer en service. Pour vos applications Plex, c'est toujours le même serveur, toujours lié à votre compte et partagé. Ensuite :

- Donnez à votre application la nouvelle IP LAN, comme dans l'[étape 4](#step-4-connect-your-app).
- Déplacez la redirection de port de votre routeur vers la nouvelle machine, ou sa règle de pare-feu IPv6, avant que rex ne démarre là-bas. Le nom rex-direct reste le même et suit automatiquement une nouvelle IP publique. Tailscale serve et Caddy sont à reconfigurer sur la nouvelle machine.

### Déplacer rex vers un autre compte Plex {#move-rex-to-another-plex-account}

Si le compte avec lequel rex est revendiqué est perdu ou banni, ou si vous voulez utiliser rex avec un autre compte, créez un nouveau compte neuf, arrêtez rex, supprimez `claim_state.json` dans le dossier de rex, démarrez rex et refaites l'[étape 3](#step-3-add-it-to-a-plex-account) : revendiquez-le, puis partagez-le à nouveau avec tout le monde. Si vous pouvez encore vous connecter à l'ancien compte, retirez aussi rex là-bas : dans app.plex.tv, ouvrez **Settings**, **Authorized Devices**, filtrez par **Servers** et supprimez-le. Ces deux étapes constituent à elles seules toute la procédure de désrevendication. rex n'a pas de déconnexion : la requête de déconnexion de Plex (`DELETE /myplex/account`) répond 200 et laisse rex revendiqué. La bibliothèque, Fix Match, les modifications et le nom rex-direct restent en place, et l'historique de visionnage de chaque personne revient une fois rex à nouveau partagé avec son compte.

### Quel rex dois-je lancer ? {#which-rex-do-i-run}

rex n'a pas de commande de version. La date du nightly se trouve dans le nom du téléchargement (`2026.10.30.0040-nightly`), et le fichier du programme porte la même date : `ls -l ~/rex/rex` (sous Windows, `(Get-Item $HOME\rex\rex.exe).LastWriteTime`). La version de Plex affichée dans vos applis n'est pas celle de rex : rex affiche volontairement la version actuelle de Plex Media Server, pour que les applis la considèrent à jour, et **Check for Updates** indique toujours que c'est le cas.

### Supprimer rex {#remove-rex}

+++ Linux
```bash
systemctl --user disable --now rex && rm ~/.config/systemd/user/rex.service
```
+++ macOS
```bash
launchctl unload ~/Library/LaunchAgents/com.rex.plist && rm ~/Library/LaunchAgents/com.rex.plist
```
+++ Windows
Dans PowerShell en tant qu'administrateur :

```powershell
Unregister-ScheduledTask rex -Confirm:$false; Stop-Process -Name rex
Remove-NetFirewallRule -DisplayName rex, "rex discovery"
```
+++ Docker
```bash
cd ~/rex && docker compose down
```
+++

Ensuite, empêchez votre application d'envoyer des données à rex. Sur app.plex.tv, avec le compte tout neuf, ouvrez **Settings**, **Authorized Devices**, filtrez par **Servers** et supprimez rex. Supprimez la redirection de port sur votre routeur (ou la règle de pare-feu IPv6), puis supprimez le dossier de rex.

### Obtenir de l'aide {#getting-help}

Demandez sur le forum **rex-support** du [Discord](https://discord.com/invite/7u4YjMThXP) de DMM : [Obtenir de l'aide](../guides/remote-help.md) indique ce qu'il faut inclure, ainsi que la manière dont les sponsors reçoivent une aide à distance.

## Quand quelque chose ne va pas {#when-something-is-wrong}

| Ce que vous voyez | Quoi faire |
|---|---|
| `/rex/sources` reste `{"size":0}` | Votre application ne s'est pas enregistrée. Vérifiez l'adresse qui lui a été donnée et qu'elle peut atteindre le port de rex |
| Un push répond `404 no such source` | Votre application a envoyé des données avant de s'enregistrer. Elle doit d'abord faire `PUT /rex/sources/<name>` |
| Le journal de rex indique `held ... no media_info yet` | Votre application a envoyé le fichier sans la sortie de ffprobe. Il apparaît dès que celle-ci arrive |
| Les titres affichent des noms de fichiers et pas de posters | rex n'est pas associé à un compte Plex. Faites l'[étape 3](#step-3-add-it-to-a-plex-account). Si rex a été réclamé après que votre application a envoyé sa bibliothèque, les titres se nomment tout seuls une fois la réclamation effectuée |
| Un titre est dans la mauvaise série, ou un film porte le nom de son fichier | Votre application n'a envoyé aucun `kind` ni `ids` pour lui, ou les mauvais. Corrigez-le dans votre application, ou utilisez **Fix Match** dans une application Plex connectée au nouveau compte ; un Fix Match reste tel que vous l'avez défini |
| Tous les titres échouent sur tous les appareils, souvent avec « This server is not powerful enough to convert video », et le journal de rex affiche `upstream failed` ou `502` juste après que vous appuyez sur Play (avec FFmpeg installé, `TRANSCODE ... exited` avec une connexion refusée ou expirée) | rex ne peut pas atteindre votre application à l'adresse qu'il a enregistrée, et FFmpeg ne règle pas cela. `curl -s http://192.168.1.20:32400/rex/sources` affiche cette adresse comme `url` de votre application. Sur la machine de rex, lancez `curl -I` dessus : toute réponse HTTP, y compris `401`, convient ; `Failed to connect` signifie que rex ne peut pas atteindre votre application à cet endroit. Votre application doit enregistrer une adresse accessible depuis la machine de rex : une adresse `172.` est celle d'un conteneur, que rex n'atteint que depuis la même machine Linux. Les versions récentes le disent clairement : rex affiche `SOURCES <name>: cannot reach ... from this machine` |
| Le journal de rex affiche `upstream failed: no source ... configured` | rex n'a aucun enregistrement de votre application. Faites-la s'enregistrer à nouveau : redémarrez-la |
| Le journal de rex affiche `part ... is unavailable upstream` | Votre application a répondu 404 pour ce fichier : elle ne l'a plus |
| Rien ne se lance, 401 ou 403 | Votre application a refusé sa propre connexion. Faites-la s'enregistrer à nouveau avec l'identifiant actuel |
| Un snapshot répond 409 `would remove more than half` | C'est la protection de rex contre une application qui envoie une bibliothèque à moitié chargée. Si la suppression est réelle, votre application doit renvoyer tout le snapshot depuis la partie 0, avec `"force": true` sur sa dernière partie. Renvoyer seulement la dernière partie est refusé, et l'envoyer comme un nouveau snapshot à part avec `force` supprime tout ce que les parties précédentes avaient désigné |
| La suppression dans une application Plex échoue et rex affiche `DELETE refused by the source` | Votre application n'accepte pas de `DELETE` sur le fichier. Supprimez-le plutôt dans votre application |
| Seuls certains fichiers échouent avec « This server is not powerful enough to convert video », souvent seulement dans un navigateur web | L'appareil ne peut pas lire le fichier tel quel. Essayez une application Plex sur une TV ou un téléphone, ou installez la [Conversion de la vidéo](#converting-video-optional) |
| Un fichier Dolby Vision échoue et le journal de rex indique `DoVi (Profile 5) color space is not supported` | rex n'a pas de FFmpeg, ou un FFmpeg qui n'est pas jellyfin-ffmpeg. Installez jellyfin-ffmpeg comme l'indique la [Conversion de la vidéo](#converting-video-optional), et gardez **Enable HDR tone mapping** activé (Settings, Transcoder) |
| rex quitte avec `cannot bind ...:32400 (another rex or Plex on this port? ...)` | Un autre programme occupe le port. Plex Media Server sur cette machine : utilisez `--port 32500` comme l'indique l'[étape 1](#step-1-install-rex). Un autre rex, par exemple lancé à la main : arrêtez-le |
| Un appareil à la maison ne peut pas se connecter, et la ligne `heartbeat ... ->` de rex n'affiche pas `http://192.168.1.20:32400` | rex annonce l'adresse privée du réseau par lequel il accède à Internet ; derrière un VPN ou un nœud de sortie Tailscale, ce n'est pas votre réseau domestique. Ajoutez `--announce-url http://192.168.1.20:32400` à la fin de la commande de démarrage de rex ([étape 1](#step-1-install-rex)) et redémarrez rex |
| À la maison, app.plex.tv n'atteint pas rex, et l'adresse `lan.` de [Ce que vous devriez voir](#what-you-should-see) ne répond pas | Certains routeurs et filtres DNS bloquent un nom public qui pointe vers une adresse domestique (protection contre le DNS rebinding). Autorisez `rex-direct.debridmediamanager.com` là-bas, comme les utilisateurs de Plex autorisent `plex.direct` |
| Une autre machine ne peut pas atteindre rex sous Windows, bien que les règles de pare-feu de l'étape 1 existent | Si vous avez un jour cliqué sur **Cancel** quand Windows a demandé s'il fallait autoriser rex, Windows a enregistré une règle qui le bloque, et elle l'emporte sur les règles de port. Supprimez-la dans PowerShell en tant qu'administrateur : <code>Get-NetFirewallApplicationFilter -Program "$HOME\rex\rex.exe" &#124; Get-NetFirewallRule &#124; Where-Object Action -eq Block &#124; Remove-NetFirewallRule</code> (si rex est ailleurs, indiquez son propre chemin) |
| rex n'est pas disponible dans les applications Plex hors de chez vous | Non réclamé, ou l'appareil ne peut pas atteindre l'adresse HTTPS ([rex-direct sur IPv6](#rex-direct-over-ipv6) nécessite IPv6 sur le réseau de cet appareil) |
| rex quitte avec `argument --announce-url: '...' is not an http:// or https:// address` | Donnez à `--announce-url` l'adresse seule, par exemple `https://myhost.tailnet.ts.net:443` : sans crochets, guillemets ni lien autour |
| rex s'arrête quand vous vous déconnectez | Sous Linux, lancez `sudo loginctl enable-linger "$USER"` (étape 1). Sous macOS et Windows, rex, configuré comme à l'étape 1, tourne tant que vous êtes connecté |
