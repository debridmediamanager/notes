# rex avec vos addons Stremio {#rex-with-your-stremio-addons}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) transforme les catalogues d'addons Stremio en bibliothèques rex. Les films, séries et chaînes en direct se lisent ensuite dans les applis Plex. Rien n'est téléchargé. Quand quelqu'un appuie sur lecture, rex-stremio demande à l'addon de flux un lien, et rex le lance.

Ça ne nécessite aucun parrainage DMM. rex et rex-stremio sont gratuits. Il te faut des addons de flux qui renvoient des liens, généralement via ton propre compte debrid.

Ce que tu obtiens :

- **Bibliothèques.** Les films vont dans **Stremio Films**, les séries dans **Stremio Shows**, et les chaînes d'un addon TV en direct dans une bibliothèque appelée **Live TV**, sauf si tu nommes toi-même la bibliothèque d'un catalogue. Cette bibliothèque est une liste de chaînes ; elles n'apparaissent pas dans le guide Live TV des applis Plex.
- **Collections.** Donne la même bibliothèque à plusieurs catalogues de films et coche **Catalogs as collections** : une seule bibliothèque, une collection par catalogue, et un film présent dans plusieurs catalogues n'apparaît qu'une seule fois.
- **Plex nomme ce qu'il connaît.** Les films et épisodes sont envoyés à rex avec leurs identifiants IMDb. Une fois rex activé sur un compte Plex, les applis affichent les titres, affiches et résumés habituels. Les titres connus seulement d'un addon, ainsi que les chaînes en direct, gardent les noms et images de l'addon.

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| Une machine qui reste allumée, sous Linux ou macOS, pour rex et rex-stremio ensemble | rex-stremio est un seul programme Python qui tourne à côté de rex. Le service ci-dessous est pour Linux ; [Docker](#in-docker) fonctionne aussi |
| Python 3.9 ou plus récent, `git` et `ffprobe` | rex-stremio vérifie le flux de chaque titre une fois avec ffprobe, parce que rex doit savoir ce qu'il y a dans un fichier avant de pouvoir le lire. Avec une clé API DMM, un flux debrid d'un torrent que DMM possède déjà a une sonde qui évite cette vérification ; tout le reste est sondé |
| Des addons de flux qui donnent des liens, pas des torrents | rex lit des fichiers. Réglez votre service debrid dans l'addon pour qu'il donne des liens |
| Un compte Plex tout neuf, créé uniquement pour rex | Comme dans la configuration de rex : rex est revendiqué sur ce compte et partagé avec le vôtre |

## Étape 1. Installer rex et l'ajouter à un compte Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Suivez [rex avec votre propre application](any-source.md) :

1. [Étape 1. Installer rex](any-source.md#step-1-install-rex), y compris la recherche de l'adresse IP LAN de rex. Utilisez ce nom dans chaque commande.
2. [Étape 3. Ajouter rex à un compte Plex](any-source.md#step-3-add-it-to-a-plex-account) : enregistrez rex sur le nouveau compte et partagez-le avec le vôtre.

Sautez les étapes 2 et 4 ici : rex-stremio est votre application.

Les chaînes en direct et les addons dont les flux sont des playlists `.m3u8` ne fonctionnent que via la conversion vidéo de rex. Pour ceux-là, configurez aussi [Conversion vidéo](any-source.md#converting-video-optional) sur la machine qui fait tourner rex. Les films et les épisodes servis sous forme de fichiers (`.mkv`, `.mp4`) n'ont besoin de rien de plus.

## Étape 2. Installer rex-stremio {#step-2-install-rex-stremio}

**Ce que ça fait.** Télécharge rex-stremio dans `~/rex-stremio` sur la machine rex et le lance comme service.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
mkdir -p ~/.config/systemd/user
cp ~/rex-stremio/rex-stremio.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-stremio
journalctl --user -u rex-stremio -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
cd ~/rex-stremio && python3 rex_stremio.py
```

Il tourne tant que cette fenêtre Terminal reste ouverte.
+++

**Ce que tu devrais voir.** Une ligne du genre :

```
... INFO relay and settings on http://127.0.0.1:9982/, 0 catalog(s), rex at http://127.0.0.1:32400
```

La page de réglages de rex-stremio et l'adresse à partir de laquelle rex lit les vidéos sont toutes deux sur `127.0.0.1:9982`, donc seule cette machine peut y accéder.

## Étape 3. Ajouter vos addons {#step-3-add-your-addons}

Ouvrez `http://127.0.0.1:9982/` dans un navigateur sur la machine rex. Pas d'écran ? Depuis votre ordinateur, lancez `ssh -L 9982:127.0.0.1:9982 you@<rex's LAN IP>`, puis ouvrez la même adresse tant que SSH reste ouvert.

1. Sous **Addons**, collez le lien manifest d'un addon, comme vous le feriez dans Stremio, puis appuyez sur **Add**. Faites-le pour :
   - **Catalogs** (catalogues), par exemple Cinemeta : `https://v3-cinemeta.strem.io/manifest.json`.
   - **Streams** : un addon qui trouve des releases et les lit via votre service debrid. Ouvrez sa page de configuration, choisissez votre service debrid, collez sa clé API et copiez le lien manifest qu'il génère. S'il propose uniquement les résultats en cache, choisissez cette option. Ce lien contient votre clé debrid : gardez-le pour vous.

   ![Section Addons de rex-stremio avec Cinemeta et Public Domain Movies ajoutés](../assets/rex/90-stremio-addons.webp)

2. Sous **Catalogs**, cochez les catalogues voulus. Indiquez la bibliothèque dans laquelle chacun ira et réglez **How many** pour choisir le nombre de films, d'épisodes ou de chaînes à récupérer. Pour une seule bibliothèque avec une collection par catalogue, donnez aux catalogues la même bibliothèque et cochez **Catalogs as collections**.
3. Sous **Streams**, réglez la **Highest resolution** et la **Largest file** que vous voulez lire, ou laissez-les sur any.
4. Sous **rex**, indiquez l'adresse `http://<rex's LAN IP>:32400`.
5. Si vous soutenez DMM, collez votre clé API DMM sous **DMM** ([gatekeeper](https://gatekeeper.debridmediamanager.com/) l'affiche une fois que vous êtes sponsor). Un flux debrid d'un torrent dont DMM possède déjà un probe passe sans vérification. Tout le reste est vérifié, et ce que rex-stremio vérifie des fichiers d'un torrent (jamais un flux HTTP simple ni une playlist HLS) est renvoyé à DMM pour le prochain sponsor (`share_probes: false` dans `config.json` désactive cela). Appuyez sur **Save and sync**.

![Sections Catalogs, Streams, rex et DMM de rex-stremio, avec le bouton Save and sync](../assets/rex/91-stremio-catalogs-rex.webp)

**Ce que vous devez voir.** Dans le log de rex, comme à l'[étape 4 de rex avec votre propre application](any-source.md#step-4-connect-your-app) :

```
INFO    SOURCES PUT /rex/sources/stremio -> 200
INFO    FEED stremio upsert: ...
```

Les titres apparaissent dans rex au fur et à mesure qu'ils sont vérifiés, et non une fois tout le catalogue traité, et rex-stremio en vérifie plusieurs à la fois. Il se synchronise à nouveau toutes les six heures et après chaque sauvegarde.

## Étape 4. Partager les nouvelles bibliothèques et regarder {#step-4-share-the-new-libraries-and-watch}

Les bibliothèques que rex-stremio crée sont nouvelles, donc votre propre compte ne peut pas encore les voir. Partagez-les avec votre compte comme dans [étape 3](any-source.md#share-it-with-your-own-account), connecté avec le nouveau compte, et avec toute autre personne avec qui vous partagez rex.

Ensuite, ouvrez une application Plex en tant que vous-même et lancez la lecture de quelque chose. rex-stremio demande alors un lien à vos addons de flux, et rex le lit. Pour regarder hors de chez vous ou dans app.plex.tv, donnez à rex une adresse à lui : [Utiliser hors de chez vous](any-source.md#use-it-outside-your-home-optional).

## Avec Docker {#in-docker}

rex-stremio du [README](https://github.com/debridmediamanager/rex-stremio#set-up) contient les commandes Docker. Dans un conteneur, rex lit les vidéos à l'adresse du conteneur sur votre réseau plutôt que `127.0.0.1`, ce que le README montre comment configurer.

## Mise à jour {#updating}

```bash
cd ~/rex-stremio && git pull && systemctl --user restart rex-stremio
```

Sur macOS, arrête-le avec Ctrl+C, lance `git pull` dans `~/rex-stremio` puis relance-le.

## Ce qu'il ne peut pas faire {#what-it-cannot-do}

- **Les épisodes sont numérotés comme Cinemeta les numérote.** Pour quelques séries, cela diffère de la numérotation de TMDB, que rex suit, donc un épisode peut atterrir au mauvais endroit.
- **Le nombre compte les épisodes** pour un catalogue de séries, pas les émissions.
- **Activer ou désactiver Catalogs as collections** renvoie les titres à rex comme de nouveaux titres. Ce qui a été regardé sur eux ne sera peut-être pas repris. Décide avant de commencer à regarder.
- **Seuls les catalogues de films, de séries et de chaînes** sont listés, et aucun qui nécessite d'abord une recherche ou un genre.
- **Les chaînes en direct** ne peuvent pas être mises en pause loin en arrière, reprises plus tard ou marquées comme vues, et ne se lisent que dans les applications qui demandent à rex de les convertir (les applications Plex et Plezy ; Plex Web n'est pas testé). Les chaînes sans flux fonctionnel, ou avec DRM, sont exclues.
- **Toute personne qui peut atteindre l'adresse de rex-stremio peut lire à travers elle.** Laisse-la sur `127.0.0.1`, sauf si rex tourne ailleurs.

Le README détaille [le reste de ses limites](https://github.com/debridmediamanager/rex-stremio#limits) et chaque réglage de `config.json`. Pour créer ton propre addon, consulte [Créer un addon rex](addons.md), qui explique aussi le fonctionnement interne de rex-stremio.
