# Whisparr

Whisparr, c'est Radarr pour les films et scènes pour adultes. Il utilise zurg comme client qBittorrent. Les grabs partent vers ton compte debrid. L'import renomme seulement un chemin dans `__magic__` ; rien n'est téléchargé ni copié.

Tout ce qui suit a été testé le 2026-10-23 avec Whisparr `3.6.5.1886` (l'image `ghcr.io/hotio/whisparr:v3`), Prowlarr, zurg compilé depuis la branche `main` de ce jour-là et un compte Real-Debrid. Un film de 17 GB a été grab, importé, puis lu depuis le montage.

## Avant de commencer {#before-you-start}

Commence par configurer zurg pour Radarr, avec [Sonarr et Radarr pour les torrents](sonarr-radarr-torrents.md) : un compte qui accepte les torrents, `__magic__` activé et le point de terminaison qBittorrent activé. Whisparr réutilise tout cela.

## 1. Catégorie de Whisparr dans zurg {#1-whisparrs-category-in-zurg}

Whisparr envoie ses téléchargements sous la catégorie `whisparr`. Son bouton **Test** à l'étape 3 crée cette catégorie dans zurg, donc tu n'as rien à ajouter. Si tu veux quand même la lister dans `config.yml`, ajoute-la à côté de celles déjà présentes :

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Lancer Whisparr {#2-run-whisparr}

Sur un hôte Linux, donnez à Whisparr le même volume qu'à Radarr : le dossier **au-dessus** du point de montage de zurg, avec `rslave` ([pourquoi](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)) :

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` et `PGID` sont l'utilisateur Linux sous lequel Whisparr tourne. L'image Docker de zurg permet à n'importe quel utilisateur de lire son montage. Un zurg installé comme simple binaire ne le permet que s'il tourne en root ou si `user_allow_other` est activé ([Installation sous Linux](../setup/linux.md#1-install-fuse-3)). Sinon, réglez `PUID` et `PGID` sur l'utilisateur qui fait tourner zurg (`id -u` et `id -g` l'affichent), faute de quoi Whisparr verra le montage vide.

Sur macOS et Windows, ce fichier compose ne s'applique pas, pour la raison donnée à l'[étape 8 du guide Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Installez Whisparr comme une application classique sur ces systèmes, en tenant compte des pièges listés dans [Avant de commencer](sonarr-radarr.md#before-you-start) de ce guide : le même utilisateur que zurg sous macOS, et l'application de la zone de notification plutôt que le service Windows sous Windows. Seule l'image Docker ci-dessus a été testée.

Ouvrez `http://<your server>:6969`.

## 3. Ajouter zurg comme client de téléchargement {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**, à remplir exactement comme pour Radarr ([les champs](sonarr-radarr-torrents.md#what-to-put-in-each-field)), sauf que **Category** vaut `whisparr`. Laisse **Remove Completed** activé. **Test**, puis **Save**.

## 4. Ajouter le dossier racine {#4-add-the-root-folder}

Créez le dossier sur le montage, puis ajoutez-le sous **Settings → Media Management → Root Folders** :

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

Il se trouve à côté de `__magic__/movies`, pas à l'intérieur. Whisparr classe chaque film sous son studio, dans `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. Indexeurs {#5-indexers}

L'indexeur de DMM n'a pas de catégorie adulte, donc Whisparr a besoin d'autres indexeurs. Dans Prowlarr, les indexeurs publics **Knaben** et **The Pirate Bay** ont tous les deux fonctionné. **XXXClub** est protégé par Cloudflare, et Prowlarr ne peut pas l'ajouter sans un solveur Cloudflare.

Ensuite, connecte Prowlarr à Whisparr dans **Settings → Apps → + → Whisparr** de Prowlarr, avec l'adresse de Whisparr et la clé API (à récupérer dans **Settings → General** de Whisparr). Prowlarr ajoute lui-même ses indexeurs à Whisparr.

zurg n'accepte que les releases que ton compte possède déjà (`cached_only`, activé par défaut). Quand il en refuse une, Whisparr prend son résultat suivant.

## 6. En récupérer un {#6-grab-one}

Ajoute un film dans Whisparr en cochant **Start search for missing movie**. Si ça marche, l'historique de Whisparr affiche **Grabbed** puis **Imported** en quelques secondes, et le film apparaît sur le point de montage :

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

Sur macOS, le chemin commence par `/Volumes/Zurg`. Sous Windows, ouvre `Z:\__magic__\whisparr\movies` dans l'Explorateur. Rien n'atterrit dans le dossier `data/local` de zurg. Le fichier est streamé depuis ton compte.

## Le regarder {#watching-it}

Pointez une bibliothèque Plex ou Jellyfin vers `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` sous macOS, `Z:\__magic__\whisparr` sous Windows) pour garder ces films dans une bibliothèque à part.

Dans rex, ils apparaissent dans la bibliothèque où les dossiers de zurg les placent, comme toutes les autres versions, ce qui, sur la plupart des configurations, correspond à la bibliothèque de films.
