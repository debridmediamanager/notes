# Sous-titres avec Bazarr {#subtitles-with-bazarr}

Bazarr trouve les sous-titres pour ce que Sonarr et Radarr importent et enregistre chacun à côté de sa vidéo. Avec zurg, la vidéo se trouve dans `__magic__`, et le sous-titre aussi. Les bibliothèques Plex et Jellyfin pointées sur `__magic__` le lisent comme n'importe quel sous-titre sur disque, et rex l'affiche aussi, sous le nom **English (SRT External)** dans le menu des sous-titres.

Cela nécessite zurg et rex de la version nightly du 2026-10-24 ou plus récente.

Tout ce qui suit a été testé le 2026-10-23 avec Radarr `6.3.0.10514`, l'image `lscr.io/linuxserver/bazarr` actuelle, zurg et rex de ce jour-là, et un compte Real-Debrid.

## Avant de commencer {#before-you-start}

Radarr (ou Sonarr) importe déjà via zurg, avec son dossier racine dans `__magic__`, par exemple `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` sur macOS, `Z:\__magic__\movies` sur Windows). Si ce n'est pas encore le cas, suis d'abord [Sonarr & Radarr pour les torrents](sonarr-radarr-torrents.md) ou [pour Usenet](sonarr-radarr.md).

## 1. Lancer Bazarr {#1-run-bazarr}

Sur un hôte Linux, donne à Bazarr le même volume qu'à Radarr, pour que les deux voient le film au même chemin et qu'aucun mappage de chemin ne soit nécessaire :

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

Le bind se fait sur le dossier **au-dessus** du point de montage de zurg (`/mnt`, qui contient `/mnt/zurg`), et non sur le point de montage lui-même. Un conteneur qui bind le point de montage lui-même garde un montage mort une fois zurg redémarré, et chaque lecture répond `Socket not connected`. [L'étape Docker du guide torrent](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) explique pourquoi. `PUID` et `PGID` demandent le même soin que pour Whisparr : [voir ici](whisparr.md#2-run-whisparr).

Sur macOS et Windows, ce fichier compose ne s'applique pas, pour la raison donnée à l'[étape 8 du guide Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Lance Bazarr depuis les sources (`python bazarr.py`) sur la même machine que Radarr et zurg, avec le même utilisateur que zurg, en suivant les pages de Bazarr pour [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) et [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/). Sous Windows, n'utilise pas l'installateur de Bazarr : il installe Bazarr comme service Windows, et un service ne voit pas le lecteur `Z:` de zurg ([pourquoi](sonarr-radarr.md#before-you-start)). Lance plutôt `bazarr.py` depuis ta propre session ouverte. Bazarr voit alors chaque film au chemin que Radarr indique, et aucun mappage de chemin n'est nécessaire. Seule l'image Docker ci-dessus a été testée.

Ouvre `http://<your server>:6767`.

## 2. Le connecter à Radarr et Sonarr {#2-connect-it-to-radarr-and-sonarr}

**Settings → Radarr** : activez-le et saisissez l'adresse de Radarr, le port et la clé API (dans **Settings → General** de Radarr). Depuis l'intérieur d'un conteneur, utilisez l'IP LAN de l'hôte, pas `localhost`. **Test**, puis **Save**. Sonarr se configure de la même façon sous **Settings → Sonarr**.

## 3. Langues {#3-languages}

**Settings → Languages** : ajoute les langues que tu veux, crée un profil de langues avec elles, puis définis-le comme profil par défaut pour les films et pour les séries. Bazarr demande alors des sous-titres pour tout ce que Radarr et Sonarr ont déjà.

## 4. Fournisseurs {#4-providers}

**Settings → Providers** : ajoute les sites de sous-titres que Bazarr interroge. Certains demandent un compte, d'autres non. Deux points relevés pendant nos tests :

- **subf2m** a besoin d'un User-Agent dans ses réglages de fournisseur. Sans cela, Bazarr le met en pause pendant 12 heures dès la première recherche.
- Bazarr met en pause un fournisseur qui échoue pendant un certain temps. Si tous les fournisseurs sont en pause, une recherche ne trouve rien. **System → Providers** les liste et permet de les réinitialiser.

## 5. Sous-titres intégrés {#5-embedded-subtitles}

Beaucoup de releases contiennent déjà une piste anglaise dans le fichier vidéo. Bazarr considère que l'anglais est présent et ne télécharge rien. Si vous voulez quand même un fichier de sous-titres, désactivez **Use Embedded Subtitles** dans **Settings → Subtitles**.

## 6. Vérifier un fichier {#6-check-one}

Sur la page **Movies** de Bazarr, vous voyez ce qui manque à chaque film. Lancez une recherche depuis cette page, et le sous-titre apparaît à côté de la vidéo (sous Windows, regardez dans le même dossier `Z:\__magic__\movies` dans l'Explorateur) :

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

Le sous-titre est un vrai fichier sur le disque de zurg, dans `data/local/__magic__/` (voir [Sidecars](magic.md#sidecars-nfo-posters-subtitles)). La vidéo continue d'être diffusée depuis votre compte.

## Dans rex {#in-rex}

zurg envoie à rex chaque sous-titre placé à côté d'une vidéo dans `__magic__`, peu importe où Radarr ou Sonarr a déplacé cette vidéo. zurg vérifie les sous-titres nouveaux, modifiés et supprimés une fois par minute. Un sous-titre enregistré par Bazarr apparaît donc dans rex en une minute environ, et un sous-titre que tu supprimes disparaît tout aussi vite. Rien d'autre à configurer que `rex_url` dans la configuration de zurg, que [le guide de rex](../../rex/with-zurg.md) te fait déjà régler.

Le nom du fichier indique de quel sous-titre il s'agit, de la même façon que Plex lit les noms de sous-titres :

| Le nom du fichier se termine par | rex affiche |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

Les fichiers `.srt`, `.ass`, `.ssa`, `.smi` et `.txt` sont lus. La langue peut être un code à deux ou trois lettres (`en`, `eng`, `de`, `ger`). Le nom qui précède doit être le nom de la vidéo elle-même, tel que Bazarr l'écrit.

Seuls les sous-titres dans `__magic__` arrivent jusqu'à rex. Un sous-titre enregistré à côté d'un fichier dans un autre dossier de zurg, comme `/mnt/zurg/movies`, n'est pas envoyé.

rex peut aussi chercher lui-même des sous-titres : **Search Subtitles** dans n'importe quelle app Plex, sans Bazarr du tout. Voir [les sous-titres de rex](../../rex/with-zurg.md#subtitles).
