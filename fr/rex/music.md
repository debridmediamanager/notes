# Musique avec rex {#music-with-rex}

rex peut héberger une bibliothèque musicale pour Plexamp, Plex Web et Plex pour Android. Un addon musical envoie chaque morceau avec sa release MusicBrainz. Plex complète les noms, les pochettes, les détails des artistes, les genres et les artistes similaires.

Ce que vous obtenez :

- **Les albums connus de Plex.** Un album envoyé avec sa release MusicBrainz s'affiche comme sur n'importe quel serveur Plex, avec la pochette et les noms des pistes fournis par Plex. Un album que Plex ne connaît pas affiche les noms et les images envoyés par l'addon.
- **Qualité d'origine.** Les morceaux sont lus dans leur format d'origine, comme le FLAC.
- **Paroles et volume sonore**, lorsque l'addon les envoie : les paroles s'affichent avec le morceau, et rex transmet le volume sonore de chaque morceau aux applications, comme le fait Plex.
- **Vos écoutes et playlists.** Les écoutes, les notes et les playlists sont conservées par compte Plex. Plexamp crée aussi ses playlists intelligentes sur rex.

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| Une version nightly de rex datée 2026.11.02 ou plus récente | La musique est arrivée dans cette version |
| rex configuré comme dans [rex avec votre propre app](any-source.md) | C'est là que la bibliothèque musicale apparaît |
| Un addon musique | N'importe quel programme qui envoie des morceaux via l'API de flux de rex. Pour un dossier d'albums sur vos propres disques, [Tutoriel : un addon musique](addon-music.md) est un exemple complet en un seul fichier Python |
| [Conversion vidéo](any-source.md#converting-video-optional), facultatif | rex ne convertit un morceau que pour une app réglée sur une qualité audio inférieure à celle de l'original |

## Étape 1. Installer rex et l'ajouter à un compte Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Suivez [rex avec votre propre application](any-source.md) :

1. [Étape 1. Installer rex](any-source.md#step-1-install-rex), y compris pour trouver l'adresse IP LAN de rex. Cette page l'écrit `192.168.1.20` : remplacez-la par la vôtre.
2. [Étape 3. Ajouter à un compte Plex](any-source.md#step-3-add-it-to-a-plex-account) : enregistrez rex sur le nouveau compte et partagez-le avec le vôtre.

## Étape 2. Pointez votre addon musical vers rex {#step-2-point-your-music-addon-at-rex}

rex a besoin d'une bibliothèque musicale pour les morceaux. Si votre addon en déclare une, rex la crée lors de son enregistrement. Sinon, ajoutez-en une d'abord dans une application Plex connectée avec le nouveau compte : **Add Library**, **Music**, n'importe quel dossier. Un morceau envoyé avant qu'il existe une bibliothèque musicale est refusé.

Donnez ensuite à votre addon l'adresse de rex, `http://192.168.1.20:32400`, comme l'indiquent ses propres instructions. Il s'enregistre auprès de rex et lui envoie ses albums.

**Ce que vous devriez voir.** Dans le journal de rex :

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    SECTION create Music (artist) for <addon>'s music
INFO    FEED <addon> upsert: ...
```

La ligne `SECTION create` n'apparaît que si l'addon déclare la bibliothèque. La bibliothèque musicale apparaît dans rex, avec chaque album sous son artiste. Un morceau que rex refuse est consigné dans le journal avec la raison, par exemple `no music library holds <file>`.

## Étape 3. Partagez la bibliothèque musicale {#step-3-share-the-music-library}

La bibliothèque musicale est nouvelle, donc elle n'est encore partagée avec personne. Connecté avec le nouveau compte, ajoute-la au partage de ton propre compte et à celui de tous les autres dans **Manage Library Access** ([Share rex](sharing.md)).

## Étape 4. Écoutez {#step-4-listen}

- **Plexamp** : connectez-vous avec votre propre compte Plex et choisissez la bibliothèque musicale de rex comme bibliothèque.
- **Plex Web et Plex pour Android** : la bibliothèque musicale se trouve avec les autres bibliothèques de rex.

**Ce que vous devriez voir.** Les albums avec les pochettes et les noms de pistes de Plex, et l'artiste avec une photo. Appuyez sur lecture.

## Ce qu'il ne peut pas faire {#what-it-cannot-do}

- **Pas de radio, de mixes ni de stations.** La radio, les mixes, les stations et les titres sonorement similaires de Plexamp demandent une analyse de chaque morceau, que rex ne fait pas.
- **Pas de dossier musique à lui.** rex ne scanne rien et ne lit aucun tag. Un addon doit envoyer chaque morceau, avec la version MusicBrainz de son album pour que Plex puisse le nommer.
- **Deux copies d'un album sont deux albums**, comme sur n'importe quel serveur Plex : une copie FLAC et une copie MP3 apparaissent chacune comme leur propre album.
- **Testé dans Plexamp, Plex Web et Plex pour Android.** Les autres applications Plex, ainsi que les téléchargements hors ligne de Plexamp, n'ont pas été essayés.

Pour écrire votre propre addon musique, partez de [Tutoriel : un addon musique](addon-music.md) ; [Créer des addons rex](addons.md#music) détaille tous les champs.
