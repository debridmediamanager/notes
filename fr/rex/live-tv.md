# Live TV avec rex {#live-tv-with-rex}

rex affiche les chaînes de l'addon dans Plex Web et dans **Live TV** de Plex pour Android, avec un guide et What's On. Choisissez une
chaîne et elle se lance tout de suite. [rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) est prêt à
l'emploi avec un serveur de sport en direct. Pour une liste M3U IPTV et un guide XMLTV, voir [Tutoriel : un addon IPTV](addon-iptv.md).

Ce que vous obtenez :

- **Un guide.** Chaque chaîne à son numéro, avec ce qui passe maintenant et ensuite.
- **What's On.** Ce qui est diffusé en ce moment, ce qui commence plus tard, et les films à venir.
- **Recherche.** Le nom d'une émission la trouve dans Live TV comme dans vos bibliothèques.
- **Lecture.** Choisissez une chaîne et elle se lit en direct. Une chaîne ne garde aucun point de reprise et n'est jamais marquée comme vue.
- **Une grille, comme chez un fournisseur TV.** rex-live-sports démarre avec sa grille américaine : une trentaine de chaînes sportives à des numéros qui ne changent jamais (ESPN est sur 2, CBS sur 7), le calendrier des matchs de ESPN diffusés sur ces chaînes, et des chaînes de créneau (`NFL 1`, `NBA 1` et ainsi de suite) qui listent les matchs du jour avant leur début et diffusent chacun en direct. Il existe aussi une grille britannique et une grille allemande.
- **La bibliothèque aussi.** Les chaînes restent dans leur propre bibliothèque **Live Sports**, rangées dans une collection par groupe.

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| Une version nightly de rex datée 2026.11.02 ou plus récente | La TV en direct est arrivée dans cette version |
| rex configuré comme dans [rex avec votre propre app](any-source.md), avec [Conversion vidéo](any-source.md#converting-video-optional) | rex convertit chaque chaîne pendant que vous la regardez (une copie, peu coûteuse) |
| Un serveur de sport en direct, sur la machine de rex ou sur votre réseau domestique | rex-live-sports prend ses chaînes depuis là |
| Docker | Sert à lancer live-sports à l'étape 2. Son [README](https://github.com/yowmamasita/live-sports-public) présente les autres façons |
| Python 3.9 ou plus récent, `git`, `ffmpeg` et `ffprobe` sur la machine de rex | rex-live-sports vérifie le flux de chaque chaîne avec ffprobe et dessine son affiche avec ffmpeg |

## Étape 1. Installer rex et l'ajouter à un compte Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Suivez [rex avec votre propre application](any-source.md) :

1. [Étape 1. Installer rex](any-source.md#step-1-install-rex), y compris la recherche de l'adresse IP locale (LAN) de rex. Cette page l'écrit sous la forme `192.168.1.20` : remplacez-la par la vôtre.
2. [Étape 3. Ajouter rex à un compte Plex](any-source.md#step-3-add-it-to-a-plex-account) : enregistrez rex sur le compte tout neuf et partagez-le avec le vôtre.
3. [Conversion de la vidéo](any-source.md#converting-video-optional) (facultatif).

Sautez les étapes 2 et 4 de cette page : rex-live-sports est votre application.

## Étape 2. Démarrer un serveur de sport en direct {#step-2-start-a-live-sports-server}

**Ce que ça fait.** Fait tourner live-sports, qui trouve les chaînes sportives et vérifie toutes les quelques minutes lesquelles d'entre elles diffusent.

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**Ce que tu devrais voir.** `http://192.168.1.20:8765` affiche le tableau de bord de live-sports dans un navigateur. La première vérification de chaque chaîne prend quelques minutes.

## Étape 3. Installer rex-live-sports {#step-3-install-rex-live-sports}

**Ce que ça fait.** Télécharge rex-live-sports dans `~/rex-live-sports` sur la machine de rex et le démarre.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

Dans `config.json`, mets `live_sports_url` à `http://192.168.1.20:8765` et `rex_url` à `http://192.168.1.20:32400`. Ensuite :

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

Dans `config.json`, mets `live_sports_url` à `http://192.168.1.20:8765` et `rex_url` à `http://192.168.1.20:32400`. Ensuite :

```bash
python3 rex_live_sports.py
```

Ça tourne tant que cette fenêtre Terminal reste ouverte.
+++

**Ce que tu dois voir.** Une ligne du genre :

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

Tant que la première vérification de live-sports n'est pas terminée, il logue `live-sports lists no channel that plays yet`. Ensuite, la première synchro vérifie le flux de chaque chaîne de la grille que live-sports a, environ une minute pour 30, et logue :

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

Ce sont les 30 chaînes de la grille que live-sports a, plus les créneaux avec un match ce jour-là. Il resynchronise toutes les cinq minutes et ne vérifie que les chaînes qu'il n'a pas encore vues ce jour-là.

## Étape 4. Partager la bibliothèque et ouvrir Live TV {#step-4-share-the-library-and-open-live-tv}

La bibliothèque **Live Sports** est nouvelle, donc elle ne fait partie du partage de personne pour l'instant. Connecte-toi avec le nouveau compte, puis ajoute-la au partage de ton propre compte et à celui de tous les autres dans **Manage Library Access** ([Partager rex](sharing.md)). Un partage permet à son compte de regarder la Live TV, sauf si tu l'as désactivé pour ce compte.

Ensuite, ouvre une app Plex avec ton propre compte :

- **Plex Web** : **Live TV & DVR** est dans la barre latérale, avec les bibliothèques de rex.
- **Plex for Android** : l'onglet **Live TV** en bas, avec rex sélectionné en haut ; **Live TV & DVR** est aussi listé, avec les bibliothèques de rex.

**Ce que tu devrais voir.** **Guide** et **What's On** en haut. Le guide affiche chaque chaîne avec son numéro et ce qui y est diffusé. Choisis un programme et appuie sur **Watch Now**.

## Chaînes, numéros et guides {#channels-numbers-and-guides}

`config.json` définit la grille : `lineups/us.json` tel quel, `lineups/uk.json` ou `lineups/de.json` pour les chaînes du Royaume-Uni ou d'Allemagne. Une chaîne de la grille est présente, à son numéro, tandis que live-sports en a une copie qui diffuse. Une chaîne US récupère ses matchs depuis le programme d'ESPN (`Chicago Bears at Seattle Seahawks`, à partir du coup d'envoi pendant la durée habituelle du sport ; NFL, football universitaire, NBA, NHL, MLB, les grands championnats européens, MLS et F1). ESPN ne cite que des diffuseurs américains, donc les chaînes britanniques et allemandes utilisent plutôt le guide qu'[epgshare01](https://epgshare01.online/) a pour une chaîne de même nom, comme le fait chaque chaîne autour de ses matchs. Une chaîne qu'aucun guide ne référence affiche son propre nom par blocs de six heures.

Les emplacements viennent après les chaînes : `NFL 1` à `NFL 10` sur `700.1` à `700.10`, `NBA 1` à `NBA 6` à partir de `701.1`, puis NHL, MLB, Soccer et F1. Chaque match du jour va dans le premier emplacement libre de son sport, pour que le guide l'affiche avant son début ; de 15 minutes avant le coup d'envoi jusqu'à la fin, l'emplacement diffuse le flux de live-sports qui le contient, retrouvé grâce aux noms des deux équipes. Entre deux matchs, un emplacement ne diffuse rien. Un emplacement apparaît la première fois qu'il diffuse un match.

Sans grille (`"lineup": ""` dans `config.json`), toutes les chaînes des groupes `Live:` et `Sports` de live-sports sont présentes à la place, numérotées par groupe : `100.1`, `100.2` pour le premier groupe, `101.1` pour le suivant, à l'écart des petits numéros qu'utilisent un tuner ou une autre source. Une chaîne garde son numéro tant que live-sports la liste au moins une fois par semaine. Les chaînes Pluto TV ont leur propre programme et sont exclues, sauf si tu les demandes : `"groups": ["Live:", "Sports", "Pluto:"]`. Tous les réglages se trouvent dans le [README](https://github.com/debridmediamanager/rex-live-sports#settings) de rex-live-sports.

## Mise à jour {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

Sur macOS, arrêtez-le avec Ctrl+C, lancez `git pull` dans `~/rex-live-sports` puis relancez-le.

## Ce qu'il ne peut pas faire {#what-it-cannot-do}

Voici la traduction française :

- **Rien n'est enregistré.** Plex Web et Plex pour Android n'affichent aucun bouton Enregistrer.
- **Les guides sont associés par nom.** Une chaîne peut recevoir le guide d'un autre flux de la même marque, et beaucoup de chaînes d'événements n'en ont aucun.
- **Un créneau trouve le flux d'un match à partir des équipes dans son nom.** Un flux nommé autrement (`nfl ravens`) n'est pas trouvé, et un match pour lequel aucun flux n'existe figure dans le guide mais ne se lance pas.
- **Plex classe une émission sans numéro d'épisode comme un film, comme avec n'importe quel guide TV ; les matchs apparaissent donc aussi sous les films de What's On.**
- **Le Live TV a été testé dans Plex Web et Plex pour Android.** Les autres applications Plex n'ont pas été essayées.
- **Toute personne pouvant atteindre l'adresse de rex-live-sports peut lire à travers elle.** Gardez `listen` sur `127.0.0.1`.

Pour ajouter vos propres chaînes, avec un guide que vous possédez déjà, consultez [Building rex addons](addons.md#live-tv).
