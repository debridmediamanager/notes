# Créer des addons pour rex {#building-rex-addons}

[rex](https://rex.debridmediamanager.com/fr/) affiche ce que ses sources lui disent.
Une source dit à rex ce qu'elle a
via l'API de flux, et sert les fichiers quand rex les demande. rex traite toutes les sources de la même façon. Un **addon** est une
source que tu écris toi-même pour des vidéos perso, des enregistrements, des catalogues Stremio, de la [musique](#music) ou des [chaînes en direct](#live-tv).

Cette page explique ce dont rex a besoin de la part d'un addon, comment nommer ses éléments et les règles importantes. Elle se termine avec
[rex-stremio](https://github.com/debridmediamanager/rex-stremio), un exemple tenant en un seul fichier.

Un addon fait trois choses :

- **Il sert les données.** rex récupère toutes les données depuis ton addon en HTTP quand quelqu'un appuie sur lecture : un fichier, ou un flux vers lequel rex est redirigé.
- **Il dit à rex ce qu'il a.** Il envoie à rex une liste via l'API de flux de rex, puis chaque changement ensuite. rex ne scanne jamais rien.
- **Il nomme ce qu'il apporte.** Pour les éléments qu'aucun agent ne connaît, ton addon envoie lui-même le titre, le résumé, la date et les visuels. Les apps Plex les affichent comme n'importe quelle autre bibliothèque.

Si ce que tu apportes ce sont des films et séries que Plex connaît déjà (il possède leurs ids IMDb ou TMDB), tu veux plutôt [rex avec ta propre app](any-source.md) : Plex se charge alors de tout nommer et décrire pour toi.

Pour apporter les catalogues de tes addons Stremio dans rex, rien à écrire : rex-stremio est déjà prêt. Tu colles les liens de tes addons sur sa page de réglages et tu coches les catalogues que tu veux.

**Tu préfères partir d'un code qui marche ?** Trois tutoriels construisent chacun un addon complet dans un seul fichier Python, avec la bibliothèque standard uniquement, et expliquent le rôle de chaque partie :

| Tutoriel | Ce qu'il apporte à rex |
|---|---|
| [Vidéos perso](addon-home-videos.md) | Un dossier de tes propres vidéos, en bibliothèque avec titres, dates et affiches extraits des vidéos |
| [Musique](addon-music.md) | Un dossier d'albums, nommés par Plex via MusicBrainz, avec paroles |
| [IPTV](addon-iptv.md) | Une playlist M3U et son guide XMLTV, en chaînes Live TV avec guide |

Cette page explique chaque étape que prennent ces tutoriels. [Plus de fonctions pour ton addon](addon-more.md) ajoute les sous-titres, les bandes-annonces, les chapitres, les collections, les playlists et le reste.

## Avant de commencer {#before-you-start}

| Vous avez besoin de | Pourquoi |
|---|---|
| rex, configuré comme dans [rex avec votre propre app](any-source.md) (étapes 1 à 3) | C'est là que la bibliothèque de votre addon apparaît |
| Un nightly de rex daté du 2026.10.25 ou plus récent, ou du 2026.11.02 ou plus récent pour [Music](#music) et [Live TV](#live-tv) | Cette page est écrite pour cette version |
| FFmpeg sur la machine où tourne rex, si votre addon sert des flux | rex lit un flux en le convertissant (une copie, peu coûteuse). rex trouve FFmpeg tout seul ; voir [Converting video](any-source.md#converting-video-optional) |
| Votre addon sur la même machine que rex, ou sur votre réseau domestique | Le flux de rex ne répond qu'à ceux-là : voir [Keep the port private](any-source.md#keep-the-port-private) |

Cette page note l'adresse de rex `192.168.1.20:32400` et celle de l'addon `127.0.0.1:9981`. Mettez les vôtres à leur place. La référence complète de l'API de rex est [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Étape 1. Servir les octets {#step-1-serve-the-bytes}

**Ce que ça fait.** Donne à chaque vidéo une URL que rex peut lire.

**Pourquoi c'est important.** rex ne garde aucun média. À chaque fois que quelqu'un appuie sur lecture, rex lit la vidéo depuis ton addon.

Ton addon est un serveur HTTP. Une vidéo se trouve à `<your address>/<path>`, et `path` est ce que tu choisis. Il existe deux types :

| Tu sers | Comment | Ce que fait rex |
|---|---|---|
| **Un fichier** (`.mkv`, `.mp4`, ...) | Réponds à `GET` avec le fichier. Réponds aux requêtes `Range` (`206`) pour que le déplacement dans la vidéo soit rapide ; sans elles, rex lit depuis le début à chaque déplacement | Les apps Plex la lisent directement quand elles le peuvent, sinon rex la convertit |
| **Un flux** (HLS, `.m3u8`) | Réponds à `GET` avec la playlist, ou une redirection vers elle. Les redirections sont suivies, et ton login n'est jamais envoyé à un autre hôte | rex la convertit toujours : une copie de l'image et du son dans un format que l'app peut lire. Une app qui lit le fichier directement est redirigée vers cette conversion |

Optionnel, mais ça vaut le coup :

- **Un login.** Basic auth (`user`, `password`) ou un bearer token. rex ne l'envoie qu'à l'adresse de ton addon.
- **Suppressions.** Quand quelqu'un supprime un titre dans une app Plex, rex envoie d'abord à ton addon un WebDAV `DELETE` pour le chemin. Réponds `2xx` (supprimé) ou `404` (déjà disparu) et rex retire le titre. Pour toute autre réponse, l'app Plex indique que la suppression n'a pas pu se faire.

## Étape 2. S'enregistrer auprès de rex {#step-2-register-with-rex}

**Ce que ça fait.** Dit à rex le nom de ton addon, où sont tes fichiers et les bibliothèques qu'il remplit.

**Pourquoi c'est important.** rex ne lit rien depuis une source qu'il ne connaît pas. Enregistrer à nouveau ne change rien, donc fais-le à chaque démarrage de ton addon.

+++ Linux et macOS
```bash
curl -X PUT http://192.168.1.20:32400/rex/sources/myaddon \
  -H 'Content-Type: application/json' \
  -d '{"url": "http://127.0.0.1:9981",
       "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++ Windows
```powershell
Invoke-RestMethod -Method Put http://192.168.1.20:32400/rex/sources/myaddon -ContentType application/json `
  -Body '{"url": "http://127.0.0.1:9981", "directories": [{"name": "kids", "shows": "Kids"}]}'
```
+++

| Champ | Signification |
|---|---|
| `url` | Où sont tes fichiers. Une vidéo se trouve à `GET <url>/<path>` |
| `user` and `password`, or `bearer` | Ton identifiant pour l'addon, s'il en a un. Jamais dans `url` |
| `directories` | Les bibliothèques que ton addon remplit. Chaque entrée est un premier segment de chemin (`name`) et le titre de la bibliothèque : `shows` pour une bibliothèque de séries, `movies` pour une bibliothèque de films, `music` pour une bibliothèque de musique, ou plusieurs. rex crée chaque bibliothèque la première fois ; si tu la renommes dans Plex, le nom reste |
| `trash` | `false` supprime définitivement ce que ton addon retire (un instantané qui l'exclut, ou un `DELETE`) au lieu de le garder dans la corbeille de rex |

Le premier segment d'un chemin détermine sa bibliothèque : avec l'exemple ci-dessus, tous les chemins qui commencent par `kids/` arrivent dans **Kids**. Utilise un premier segment différent pour chaque bibliothèque.

**Ce que tu dois voir.** rex répond avec la source. Le journal de rex affiche `SOURCES myaddon registered at http://127.0.0.1:9981` et, la première fois, `SECTION create Kids (show) for myaddon's kids`. La bibliothèque apparaît dans les applis Plex sous More en moins d'une seconde.

## Étape 3. Décrire chaque vidéo {#step-3-describe-each-video}

**Ce que ça fait.** Construit l'enregistrement que rex garde pour chaque vidéo : où elle se trouve, ce qu'elle est, à quoi elle ressemble.

**Pourquoi c'est important.** Cet enregistrement, c'est tout ce que rex sait. Une sonde manquante ou un id qui change provoque la plupart des bugs de l'addon.

```json
{
  "id": "home-2026-07-22-beach",
  "path": "kids/summer-2026/beach.mp4",
  "kind": "episode", "season": 1, "episode": 3,
  "name": "Summer 2026",
  "media_info": { "...": "ffprobe's output, whole" },
  "display": {
    "title": "First day at the beach",
    "summary": "...",
    "date": "2026-07-22",
    "thumb": "http://127.0.0.1:9981/kids/summer-2026/beach.jpg",
    "show": {"title": "Summer 2026", "summary": "...", "poster": "https://...", "art": "https://..."},
    "season": {"poster": "https://..."}
  }
}
```

| Champ | Obligatoire | Signification |
|---|---|---|
| `id` | oui | Ta clé pour cette vidéo, **pour toujours**. rex garde l'historique de visionnage dessus |
| `path` | oui | Où se trouvent ses octets sous ton `url`. Son premier segment choisit la bibliothèque |
| `media_info` | oui, en pratique | Le JSON `-show_format -show_streams` de ffprobe pour la vidéo (pour un flux, sonde son URL). Sans lui, un fichier est **retenu** : stocké mais non affiché, car les applis Plex ne lisent pas une vidéo qu'elles ne connaissent pas. Un flux (`.m3u8`) sans lui est rejeté avec `not a video file`, donc n'envoie un flux qu'une fois que tu l'as sondé |
| `kind` | pour une série | `episode` ou `movie`. Sans lui, rien ne place la vidéo : dans une bibliothèque TV, c'est un épisode d'une série nommée d'après `name`, numéroté dans l'ordre des fichiers ; dans une bibliothèque films, un film titré comme son fichier |
| `season`, `episode` | pour un épisode | Où elle va. Numérote les épisodes pour qu'un nouveau ne décale jamais les autres |
| `name` | non | Le nom de la série, et ce qui regroupe ses épisodes. Par défaut : le nom de son dossier (le nom du fichier pour un chemin sans dossier) |
| `release` | non | Regroupe les vidéos qui vont ensemble. Par défaut : le dossier de la vidéo |
| `display` | pour ce qu'aucun agent ne connaît | Titre, résumé, date et visuels : étape 4 |

Le `path` d'un flux se termine par `.m3u8`, et son `media_info` indique `"format_name": "hls"`. rex ne l'accepte qu'avec les deux. Tout autre fichier doit avoir une extension vidéo.

(Une traduction précédente a été rejetée : les blocs de code ne correspondent pas. Garde exactement la structure.)

## Étape 4. La nommer et l'habiller {#step-4-name-and-dress-it}

**À quoi ça sert.** Ça donne aux applis Plex un titre, un résumé, une date et des images pour ce qu'aucun agent Plex ne connaît.

**Pourquoi c'est utile.** Sans `display`, un épisode s'affiche comme « Épisode 3 » avec une vignette vide, et une série n'a pas de poster.

| Champ | Où ça s'affiche |
|---|---|
| `title`, `summary` | Le titre et le résumé de la vidéo, exactement tels qu'envoyés |
| `date` | Sa date de sortie (`YYYY-MM-DD`), et l'année qui en découle. Ou seulement l'année (`YYYY`) pour quelque chose qu'on ne connaît que par son année, comme un vieux film : les applis Plex affichent alors l'année sans le jour de sortie |
| `thumb` | Le poster d'un film, ou la vignette d'un épisode |
| `art` | L'arrière-plan d'un film |
| `show.title`, `show.summary`, `show.poster`, `show.art` | La série de l'épisode |
| `season.summary`, `season.poster` | La saison de l'épisode (le poster de la série s'il n'y en a pas) |

Chaque champ est facultatif. Les images sont des URL `http://` ou `https://`. rex les récupère lui-même : depuis internet public, ou depuis l'adresse de ton addon (le `url` que tu as enregistré), avec le login de ton addon. Toute autre adresse de ton réseau local est refusée. Ainsi, un addon peut servir ses propres images, comme une image tirée de chaque vidéo perso. Une image 2:3 fait le meilleur poster, une 16:9 la meilleure vignette et le meilleur arrière-plan.

Comment rex les traite :

- **Seulement pour ce que rien ne nomme.** Une vidéo envoyée avec `kind` et `ids` que Plex connaît s'affiche comme Plex la décrit, et `display` est ignoré.
- **Les envois suivants mettent à jour.** Renvoie une vidéo avec un nouveau `display` et sa ligne, sa série et sa saison changent sur place ; les applis redessinent les nouvelles images. Une série garde le titre avec lequel elle a été créée.
- **Les personnes priment.** Un champ modifié et verrouillé par quelqu'un dans une appli Plex garde sa valeur, et un poster qu'il a envoyé reste.
- **Tout est vérifié.** Une image qui n'est pas une URL http(s), ou une date d'un autre format, refuse la vidéo et indique quel champ pose problème.

## Étape 5. L'envoyer {#step-5-send-it}

**Ce que ça fait.** Envoie à rex tes vidéos : toutes d'un coup de temps en temps, et les changements au fur et à mesure.

**Pourquoi c'est important.** rex te montre exactement ce que tu lui as envoyé en dernier.

| Pour | Envoyer | rex répond |
|---|---|---|
| Ajouter ou modifier des vidéos | `POST /rex/feed/myaddon/items` avec `{"items": [...]}` | Le nombre de `created`, `updated`, `held`, `unchanged`, et chaque `rejected` avec sa raison |
| Supprimer des vidéos | `DELETE /rex/feed/myaddon/items` avec `{"ids": [...]}` | Le nombre de `trashed`, `deleted`, `released` (les éléments en attente sont oubliés) et `unknown` |
| Tout envoyer | `PUT /rex/feed/myaddon/snapshot` avec `{"items": [...]}`. En plusieurs parties : `"session"` (n'importe quel texte), `"part"` à partir de 0, `"complete": true` sur la dernière | Les mêmes compteurs, et ce qui est `removed` : chaque vidéo à toi que le snapshot ne nommait pas |

Envoie quelques centaines de vidéos par requête. Un snapshot qui ne nomme rien ne supprime rien, et un snapshot qui supprimerait plus de la moitié de tes vidéos est refusé, sauf si sa dernière partie contient `"force": true` : un addon qui a perdu le fil ne peut pas vider ta bibliothèque par accident.

**Ce que tu devrais voir.**

+++ Linux et macOS
```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/items | head -c 400   # what rex shows, with each ratingKey
curl -s http://192.168.1.20:32400/rex/feed/myaddon/held                  # what waits for a probe
```
+++ Windows
```powershell
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/items   # what rex shows, with each ratingKey
curl.exe -s http://192.168.1.20:32400/rex/feed/myaddon/held    # what waits for a probe
```
+++

Le journal de rex indique chaque vidéo refusée et la raison : `FEED myaddon rejected <id>: <reason>`.

## Musique {#music}

**Ce que ça fait.** Ajoute des albums dans une bibliothèque musicale, que Plexamp, Plex Web et Plex pour Android savent lire.

**Pourquoi c'est important.** Plex nomme la musique d'après la release MusicBrainz de l'album. Envoie cet id et Plex remplit lui-même tous les titres, pochettes, photos d'artiste et biographies.

Envoie chaque fichier audio comme une piste :

```json
{
  "id": "albums/in-rainbows/01",
  "path": "music/Radiohead/In Rainbows/01 - 15 Step.flac",
  "kind": "track",
  "ids": {"mbid": "3b408cb5-7d51-4188-b07c-fabcf308cda3"},
  "disc": 1, "track": 1,
  "media_info": { "...": "ffprobe's output, whole" }
}
```

| Champ | Signification |
|---|---|
| `kind` | `track` |
| `path` | Un fichier audio : `.flac`, `.mp3`, `.m4a`, `.aac`, `.ogg`, `.oga`, `.opus`, `.wav`, `.alac`, `.aif`, `.aiff`, `.wma`, `.ape`, `.wv`, `.dsf` ou `.mka` |
| `ids.mbid` | L'id **release** MusicBrainz de l'album de la piste : l'id dans un lien `musicbrainz.org/release/<id>`, et non celui d'un release group ou d'un enregistrement. Ou `ids.plex`, le guid d'album propre à Plex (`plex://album/<id>`) |
| `disc`, `track` | Où se trouve la piste sur cette release. La piste de Plex à ces numéros est celle qui s'affiche |
| `release` | De quelle édition de l'album la piste fait partie. Par défaut : son dossier. Chaque édition devient un album à part, comme Plex en liste deux, donc envoie un seul `release` pour les fichiers d'une édition rangés dans des dossiers de disque (`CD1/`, `CD2/`) |
| `display` | Pour la musique que Plex ne connaît pas : le `title` de la piste, son `artist` (`title`, `summary`, `poster`, `art`) et son `album` (`title`, `summary`, `poster`, `date`) |
| `lyrics` | Fichiers de paroles à côté de la piste sur ton addon : `[{"path": "music/.../01 - 15 Step.lrc", "size": 147}]`. Un `.lrc` (paroles avec horodatage) ou un `.txt`, affiché comme les paroles du morceau |
| `loudness` | Seulement si ton addon mesure le volume, avec les noms de Plex : `gain`, `albumGain`, `peak`, `albumPeak`, `albumRange`, `loudness` et `lra`, les fondus `startRamp` et `endRamp`, et `levels`, le volume toutes les 100 ms. rex ne mesure rien lui-même |

- **D'abord une bibliothèque Musique.** Déclare-en une à l'étape 2 (`"directories": [{"name": "music", "music": "Music"}]`), ou ajoute une bibliothèque Musique dans une app Plex. Une piste qu'aucune bibliothèque musicale n'accepte est refusée : `no music library holds <file>`.
- **Trouver l'id de release.** Cherche sur MusicBrainz avec le titre de l'album et l'artiste (`https://musicbrainz.org/ws/2/release?query=release:%22In%20Rainbows%22%20AND%20artist:Radiohead&fmt=json`) et choisis une release officielle avec ton nombre de pistes. Plusieurs correspondent souvent (une par pays), et n'importe laquelle désigne l'album. MusicBrainz n'accepte qu'une requête par seconde et par adresse, refuse au-delà, et demande un User-Agent qui nomme ton addon. Demande une fois par album et garde la réponse.
- **rex ne lit aucun tag.** Les titres, pochettes, genres et artistes similaires viennent de Plex. Une piste dont la release n'est pas connue de Plex affiche ton `display`, rangé sous l'artiste et l'album que tu indiques, ou son nom de fichier sous `[Unknown Artist]` si tu n'en envoies pas.
- **Ça se lit tel quel.** FFmpeg n'est pas nécessaire, sauf si une app demande une qualité inférieure à l'original : rex le convertit alors avec FFmpeg, comme le fait Plex.
- **Pas disponible.** La radio, les mixes, les stations et les pistes sonorement similaires de Plexamp demandent une analyse que rex ne fait pas.

**Ce que tu dois voir.** L'album dans la bibliothèque Musique, avec la pochette et les noms de pistes de Plex, et son artiste avec une photo. Dans Plexamp, choisis la bibliothèque Musique de rex comme bibliothèque.

## TV en direct {#live-tv}

**Ce que ça fait.** Transforme un flux en direct en chaîne de **Live TV** dans Plex Web et Plex pour Android, avec un guide TV, What's On et un numéro de chaîne.

**Pourquoi c'est utile.** Un flux en direct seul n'est qu'une ligne dans une bibliothèque. Avec un `channel`, les gens le trouvent comme ils trouvent une chaîne TV : dans le guide, par ce qui passe en ce moment.

Envoyez le flux en direct comme à l'étape 3 (un `.m3u8` avec son probe), plus un `channel` :

```json
"channel": {
  "number": "100.1",
  "title": "Rex News",
  "guide": [
    {"start": "2026-11-01T18:00:00Z", "end": "2026-11-01T19:00:00Z",
     "title": "Evening News", "summary": "The day's headlines.", "categories": ["News"]},
    {"start": "2026-11-01T19:00:00Z", "end": "2026-11-01T19:45:00Z",
     "title": "The Pilot", "type": "episode", "show": "Rex Stories", "season": 1, "episode": 1,
     "categories": ["Drama"]}
  ]
}
```

| Champ | Signification |
|---|---|
| `number` | Le numéro de la chaîne dans le guide (`100.1`, `704`) : lettres, chiffres, `.`, `-` et `_`. Choisissez des numéros libres par rapport aux autres addons ; la première chaîne envoyée avec un numéro le garde |
| `title` | Son nom dans le guide. Par défaut : le titre `display` du flux |
| `call_sign` | Son nom court. Par défaut : `title` |
| `guide` | Ce qui passe : `start` et `end` (secondes depuis l'epoch, ou ISO 8601 avec `Z` ou un décalage horaire), `title`, et optionnellement `summary`, `categories`, `thumb` et `previously_shown` (`true` pour une rediffusion). Un épisode ajoute `"type": "episode"` avec `show`, `season` et `episode`, et le guide le regroupe sous sa série |

- **Envoyez le guide depuis quelques heures en arrière jusqu'à l'horizon que vous connaissez** (environ une semaine, comme les fichiers de guide TV), et renvoyez-le à chaque changement. rex affiche une émission jusqu'à trois heures après sa fin. Chaque envoi remplace le guide de la chaîne ; un envoi sans `channel` le conserve ; `"channel": null` supprime la chaîne.
- **FFmpeg est nécessaire**, comme pour tous les flux : rex convertit la chaîne pendant que quelqu'un la regarde.
- **Rien n'est enregistré.** Plex Web et Plex pour Android n'proposent pas de bouton Record.
- **Chaînes qui s'arrêtent.** Enregistrez avec `"trash": false` (étape 2) pour qu'une chaîne que vous retirez soit supprimée, et non placée dans la corbeille de rex.
- **Ce que fait une catégorie.** Un épisode dans `Sports` ou `News` apparaît dans les rayons Sports et News de What's On. Une émission sans `type` est affichée comme un film, comme le fait Plex avec tout guide TV.

**Ce que vous devriez voir.** Dans Plex Web ou Plex pour Android, **Live TV** dans le menu de l'application, la chaîne dans le guide à son numéro, et le flux qui se lance à l'ouverture. Le journal de rex indique une chaîne refusée et la raison, par exemple `channel.guide[3]: end must be after start`.

[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) fait tout cela pour les chaînes d'un serveur de sport en direct : il les numérote par groupe à partir de `100.1`, conserve le numéro de chaque chaîne, et prend leurs guides chez Pluto TV et dans les fichiers XMLTV gratuits d'epgshare01.

## Les règles qui piègent les gens {#the-rules-that-trip-people-up}

| Règle | Ce qui se passe si tu la casses |
|---|---|
| **Un id est pour toujours.** Si tu le changes, la vidéo devient un nouveau titre | L'historique de lecture et les modifications restent sur l'ancienne ligne, que le prochain snapshot supprime |
| **Une vidéo, un chemin.** Deux ids ne peuvent pas partager le même `path` | Le second est rejeté : `... is already <id>'s file` |
| **Les octets d'un fichier sont fixes par id.** rex garde les flux sur lesquels il a fait le premier probe ; un probe ultérieur ne change que ses chapitres. Seul un flux (`.m3u8`) accepte un nouveau probe dont les flux sont différents | Si les octets d'un fichier changent (un autre format, un upload corrigé), donne-lui un nouvel id et un nouveau chemin |
| **Probe tout.** Pas de `media_info`, pas de vidéo | Un fichier attend dans `held` jusqu'à ce qu'un envoi en apporte un ; un flux est rejeté |
| **Garde le nom de la source.** Les lignes appartiennent à (source, id) | Un autre nom démarre une source vide ; les anciennes lignes restent jusqu'à ce que tu la supprimes |
| **Les snapshots sont complets.** Un snapshot qui ne contient pas une chaîne la supprime | N'envoie pas de snapshot après un échec partiel : saute ce tour |

Pour **remplacer** un addon (ou un script) qui a déjà rempli une bibliothèque, garde son nom de source, ses ids et le premier segment de son chemin. Ton premier envoi mettra alors à jour ses lignes sur place, historique de lecture compris, au lieu d'en créer de nouvelles.

## Exemple : rex-stremio {#example-rex-stremio}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) transforme les catalogues de tes addons Stremio en bibliothèques rex : les films vont dans une bibliothèque de films, les séries dans une bibliothèque de séries TV, et les chaînes en direct dans une bibliothèque appelée Live TV (et non le guide Live TV). Il fait les étapes 1 à 5 et tient dans un seul fichier Python, qui n'utilise que la bibliothèque standard. Il ne supprime rien : les titres d'un catalogue ne lui appartiennent pas, donc il ne les supprime pas.

**Enregistrement.** Chaque catalogue que tu coches désigne une bibliothèque : Stremio Films, Stremio Shows ou Live TV, sauf si tu la renommes. rex-stremio s'enregistre sous le nom `stremio`, avec un dossier par bibliothèque, nommé d'après elle (`stremio-films`), et déclare cette bibliothèque comme titre `shows` du dossier pour les catalogues de séries, ou comme titre `movies` pour les catalogues de films et de live TV.

**Diffusion.** Les liens des addons de flux expirent, donc rex-stremio ne stocke aucun lien. Il sert une URL par titre, `/<directory>/<catalog>/<id>.<ext>`, et répond par une redirection vers un lien qu'il demande à ce moment-là :

```python
url = app.sync.resolve(vid)   # ask every stream addon, rank, take the first link that opens
self.send_response(302)
self.send_header("Location", url)
```

Il interroge chaque addon qui fournit le titre (`/stream/<movie or series>/<id>.json`), ne garde que les liens `http(s)` simples (le `infoHash` d'un torrent n'est pas un fichier que rex peut lire), écarte ce qui dépasse tes limites de résolution ou de taille, puis essaie le reste en commençant par la plus haute résolution. Le lien qui fonctionne est mis en cache jusqu'à une heure avant son expiration (une heure si le lien ne donne pas de date). rex suit la redirection et lit le fichier, avec la possibilité de faire des sauts, directement depuis le lien. Un lien qui demande ses propres en-têtes est relayé par rex-stremio lui-même, et une playlist maître HLS n'est transmise qu'avec sa meilleure variante.

**Analyse.** Une fois par titre, rex-stremio lance ffprobe sur sa propre URL, pour que `media_info` décrive exactement ce que rex va lire, puis il garde le résultat en cache. Il analyse `probe_workers` titres à la fois (4 par défaut, sauf si tu changes ce réglage), et n'interroge chaque hôte d'addon qu'au plus une fois par `stream_interval_seconds`. Le flux d'où provient cette analyse est mémorisé et essayé en premier à chaque lecture, pour que ce qui est lu soit bien ce que rex a été informé. Le conteneur de l'analyse détermine l'extension du chemin : `.mkv`, `.mp4`, `.ts`, `.avi`, ou `.m3u8` pour le HLS.

**Analyses stockées.** Si tu renseignes une clé API DMM (`dmm_api_key`, ou **DMM** dans la page des paramètres), un flux torrent évite ffprobe lorsque DMM possède déjà une analyse de son fichier. Le hash du torrent vient du `infoHash` du flux ou de son lien (les liens debrid de Torrentio le contiennent dans le chemin). rex-stremio lit la taille du fichier dans la réponse du lien à une requête `Range` d'un octet, puis demande à `POST /api/sponsor/mediainfo` de DMM jusqu'à 100 hashes à la fois. Il ne prend l'analyse de DMM que si exactement un fichier de cette release a cette taille, et ce nom quand le flux indique le sien. Tout le reste est analysé comme ci-dessus, et cette analyse est renvoyée à DMM (`POST /api/sponsor/probes` : le hash du torrent, la taille du fichier, son nom quand le flux le donne, et la sortie de ffprobe sans l'adresse qu'il a lue), pour que le prochain sponsor qui rencontre le fichier l'évite. DMM garde la première analyse d'un fichier et répond d'abord aux instantanés propres à zurg. `share_probes: false` les garde pour rex-stremio seul ; celles de DMM sont tout de même utilisées. L'analyse d'une playlist n'est jamais envoyée.

**Nommage.** Chaque film et chaque épisode est envoyé à rex avec son `kind` et son identifiant IMDb dans `ids`, pour que Plex le nomme comme dans [rex avec votre propre application](any-source.md). Le titre, le résumé, la date et l'affiche du catalogue vont dans `display`, qui ne s'affiche que jusqu'à ce que Plex le nomme. Une chaîne en direct, ou un titre que seul son addon connaît, n'a pas d'identifiant IMDb, donc `display` seul le nomme.

**Numérotation.** Un film reste un film. Les saisons et les épisodes d'une série viennent de Cinemeta, dont les identifiants sont ceux d'IMDb, et gardent ses numéros, donc un nouvel épisode ne décale jamais les autres. rex les place selon les numéros de TMDB : là où ceux de Cinemeta diffèrent, un épisode peut donc atterrir au mauvais endroit.

**Identifiants.** Un identifiant est le catalogue plus l'identifiant IMDb (et la saison et l'épisode), par exemple `st-<catalog>-tt0111161`. Il ne change jamais, donc un même film présent dans deux catalogues fait deux éléments. Avec **Catalogs as collections** activé, un film ou une série listé par plusieurs catalogues d'une même bibliothèque ne forme qu'un seul titre, présent dans la collection de chaque catalogue.

**Envoi.** Toutes les six heures et après chaque sauvegarde : enregistrement, puis chaque titre dès qu'il est vérifié (`POST .../items`, jusqu'à 20 titres ou ce qui est prêt toutes les 5 secondes), puis un instantané de chaque catalogue, par tranches de 200. Le premier instantané après une sauvegarde porte `"force": true`, car décocher des catalogues peut retirer plus de la moitié des titres. Si un catalogue répond vide ou partiellement, le cycle n'envoie aucun instantané : il ajoute et met à jour, sans rien retirer, et un cycle complet ultérieur supprime ce qui est réellement parti.

## Dépannage {#troubleshooting}

| Ce que vous voyez | Pourquoi | Solution |
|---|---|---|
| `rejected`: `not a video file` | Le nom du fichier n'a pas d'extension vidéo, ou un `.m3u8` dont la sonde n'est pas `hls` | Nommez les flux `.m3u8` et envoyez leur sonde. Un morceau a besoin de `"kind": "track"` |
| `rejected`: `no music library holds <file>` | Aucune bibliothèque musicale n'accepte le morceau | Déclarez-en une avec `music` à l'étape 2 |
| Les albums affichent vos noms de fichiers sous `[Unknown Artist]` | Pas de `ids.mbid`, ou un id de release que Plex ne connaît pas, et pas de `display` | Envoyez l'id de release MusicBrainz de l'album, ou `display` |
| Un album affiche les mauvais morceaux | `ids.mbid` désigne une autre édition de l'album, comme une édition deluxe avec plus de morceaux | Choisissez une release avec votre nombre de morceaux |
| Une chaîne n'est pas dans le guide Live TV | Pas de `channel` ; elle a été refusée, et le journal de rex indique pourquoi (`channel.guide[...]`) ; ou une autre chaîne a déjà ce numéro, ce qui n'est pas consigné | Corrigez le champ que le journal indique, ou choisissez un numéro libre |
| Le Live TV manque dans une application Plex | Aucun élément n'a encore été envoyé avec un `channel`, ou l'application n'a pas été testée | Envoyez un `channel`, et utilisez Plex Web ou Plex pour Android, les applications testées |
| Une vidéo n'apparaît jamais | Elle est retenue (son `media_info` n'a aucun flux, ou un fichier a été envoyé sans), ou un flux envoyé sans `media_info` a été rejeté | Sondez-la et renvoyez-la |
| `rejected`: `... is already <id>'s file` | Un autre id possède ce `path` | Gardez un seul id par path |
| Un snapshot répond `409` : `the snapshot would remove more than half of this source's items` | Votre snapshot omet plus de la moitié de ce que rex a de vous : un disque manquant, une liste qui a échoué, ou un vrai nettoyage | Corrigez ce qui a disparu. Si c'était voulu, envoyez la dernière partie du snapshot avec `"force": true` |
| Les épisodes s'intitulent « Episode 1 » et les vignettes sont vides | Pas de `display` | Envoyez `display` avec chaque vidéo |
| Un film envoyé avec son id IMDb garde votre titre `display`, pas celui de Plex | rex ne demande les titres à Plex qu'une fois réclamé | Réclamez rex : [étape 3 de rex avec votre propre application](any-source.md#step-3-add-it-to-a-plex-account) |
| Les images ne s'affichent pas | L'URL est sur votre réseau domestique mais hors de l'`url` enregistrée de votre addon, ou n'est pas en http(s) | Servez-les depuis l'adresse de votre addon, ou hébergez-les sur internet public. |
| La lecture échoue avec 502 dans le journal de rex | Votre addon n'a pas répondu, ou le site du flux l'a refusé | Vérifiez d'abord le journal de votre addon |
| Un titre supprimé dans une application Plex reste | Votre addon a répondu au `DELETE` autrement que par `2xx` ou `404` | Supprimez-le de votre côté, puis répondez `2xx` |
| Un titre supprimé revient | Votre addon envoie toujours la vidéo | Arrêtez d'envoyer ce qui a été supprimé |

Toujours bloqué ? Demandez dans le forum **rex-support** sur [Discord](https://discord.com/invite/7u4YjMThXP). [Obtenir de l'aide](../guides/remote-help.md) indique quoi inclure.
