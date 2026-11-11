# Kometa avec rex {#kometa-with-rex}

[Kometa](https://kometa.wiki) crée des collections, ajoute des badges sur les affiches (4K, HDR, notes) et remplit les notes et les genres sur un serveur Plex. rex répond à Kometa comme le ferait un serveur Plex, donc la même configuration fonctionne sur vos bibliothèques rex.

Tout ce qui suit a été testé le 2026-10-23 avec Kometa 2.5.3 (l'image Docker `kometateam/kometa`) et un rex réclamé contenant des films et une série.

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| rex configuré et ajouté à un compte Plex, comme dans [Ajouter-le à un compte Plex](any-source.md#step-3-add-it-to-a-plex-account) | Kometa modifie la bibliothèque, et seul le compte sur lequel rex est enregistré peut le faire. Un rex non rattaché ne sert à personne |
| rex nightly **2026.10.24 ou plus récent** | Mettez-le à jour comme dans la section [Updating de rex](any-source.md#updating) |
| Docker sur n'importe quelle machine capable de joindre rex | Kometa tourne dans un conteneur. La documentation de Kometa présente [d'autres façons de l'installer](https://kometa.wiki/en/latest/kometa/install/overview/) |
| Une clé API TMDb gratuite | Kometa en a besoin pour lui-même, même si rex n'en a pas besoin. Créez-en une dans **Settings → API** sur themoviedb.org, comme le décrit [la page de démarrage de TMDb](https://developer.themoviedb.org/docs/getting-started) |

## 1. Récupérer le token de rex {#1-get-rexs-token}

Kometa se connecte à rex avec un jeton Plex. Utilisez le jeton que rex vous a donné lors de son enregistrement. Sur la machine rex :

+++ Linux et macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

Avec [rex dans Docker](any-source.md#run-rex-in-docker), le fichier n'est accessible qu'à root : `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**Ce que vous devriez voir.** Une seule ligne, `"token": "..."`. Copiez ce qui se trouve entre la deuxième paire de guillemets. Traitez-le comme un mot de passe : il ouvre tout le serveur. Si vous enregistrez de nouveau rex, le jeton change et Kometa aura besoin du nouveau.

**Pas le jeton de votre propre compte.** Dans [Partagez-le avec votre propre compte](any-source.md#share-it-with-your-own-account), votre compte a reçu rex en partage. Un partage permet de regarder sans modifier, donc avec ce jeton Kometa s'arrête avec `Plex Token is read only` ou, si le partage autorise les téléchargements, échoue à sa première modification.

## 2. Écrire la config de Kometa {#2-write-kometas-config}

Créez un dossier pour Kometa, par exemple `~/kometa/config` (`$HOME\kometa\config` sous Windows), puis placez ceci dans `config.yml` à l'intérieur :

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` est l'adresse IP LAN et le port de rex, soit l'adresse donnée dans [Installer rex](any-source.md#step-1-install-rex). N'utilisez pas `127.0.0.1` ni `localhost` : à l'intérieur du conteneur de Kometa, ces adresses pointent vers le conteneur lui-même.
- Les noms sous `libraries:` doivent correspondre exactement aux bibliothèques de rex : **Movies** et **TV Shows**, ainsi que toutes celles que vous avez ajoutées ou renommées. Retirez une bibliothèque si vous ne voulez pas que Kometa y touche.

C'est un petit point de départ. La documentation de Kometa liste [chaque collection et overlay par défaut](https://kometa.wiki/en/latest/defaults/guide/), et vos propres fichiers de collection fonctionnent aussi.

## 3. La lancer une fois {#3-run-it-once}

+++ Linux et macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` fait passer Kometa une seule fois maintenant, puis il s'arrête. Sans cette option, Kometa reste en marche et attend son programme quotidien.

**Ce que tu devrais voir.** Dans la sortie de Kometa, pour chaque bibliothèque :

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

Dans une application Plex, la bibliothèque de films a un onglet **Collections** avec les collections par genre, et les affiches portent leurs badges. Ton propre compte et toutes les autres personnes avec qui tu as partagé rex voient les mêmes collections et les mêmes badges. Une première exécution sur une grande bibliothèque prend un moment : Kometa lit chaque titre et redessine chaque affiche à laquelle il ajoute un badge.

## Si ça ne fonctionne pas {#if-it-does-not-work}

| Ce que Kometa affiche | Ce que ça veut dire |
|---|---|
| `Plex Token is read only. Please get a new token` | rex n'est pas encore ajouté à un compte Plex, ou le token est celui de ton propre compte et non celui de l'étape 1 |
| Kometa se connecte, puis chaque modification échoue | Le token est celui de ton propre compte. Utilise celui de l'étape 1 |
| `url_poster failed to update poster` | La machine rex ne peut pas atteindre le site où se trouve l'image |
| `Plex URL is probably invalid` ou un timeout | `url` n'atteint pas rex depuis l'endroit où Kometa tourne. Ouvre `http://192.168.1.20:32400/identity` depuis cette machine : il doit afficher le `machineIdentifier` de rex |
| `Plex Error: Plex Library '...' not found. Options: [...]` | Un nom sous `libraries:` ne correspond pas. Copie-en un depuis la liste affichée |

Toujours bloqué ? Demande sur le forum **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../guides/remote-help.md) indique ce qu'il faut inclure.

## Ce que Kometa peut et ne peut pas voir {#what-kometa-can-and-cannot-see}

Kometa associe les titres grâce aux identifiants TMDb, TVDb et IMDb que rex affiche pour eux. Un titre que sa source n'a pas identifié, qui affiche encore le nom de son fichier et n'a pas d'affiche, n'a pas d'identifiant. Kometa l'exclut donc de tout ce qui est construit à partir de ces identifiants. Corrige-le d'abord avec Fix Match dans une appli Plex.

Testé avec rex : les collections par recherche de titre, par id TMDb et les collections intelligentes ; les collections de genres par défaut avec leurs affiches ; les overlays de résolution et de notes ; et les mises à jour de la note critique et des genres depuis TMDb. Pas encore testé : les playlists, les bibliothèques musicales et les autres opérations de Kometa. Si l'une échoue, le journal propre à Kometa indique la requête fautive, et ça vaut le coup de la signaler sur Discord.
