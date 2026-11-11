# Plus dans votre addon {#more-from-your-addon}

[Créer des addons rex](addons.md) couvre les bases. Cette page ajoute les sous-titres, bandes-annonces, chapitres, collections,
playlists, images d'artiste, films connus, grandes bibliothèques, corrections et suppression. Chaque section ajoute des champs à
[Étape 5](addons.md#step-5-send-it). Essayez-les avec les tutoriels [vidéos personnelles](addon-home-videos.md), [musique](addon-music.md)
ou [IPTV](addon-iptv.md).

Chaque exemple a été envoyé à rex nightly 2026.11.02. La référence complète se trouve dans [docs/feed-api.md](https://github.com/debridmediamanager/rex/blob/main/docs/feed-api.md).

## Films et séries que Plex connaît {#films-and-shows-plex-knows}

**À quoi ça sert.** Fait en sorte que Plex affiche le nom d'un film ou d'un épisode, avec son affiche, le casting, le résumé et les notes, au lieu de ton `display`.

Envoie `kind` et les ids du titre : un id IMDb (`tt...`) ou TMDB du film, ou de la **série** pour un épisode, avec `season` et `episode` selon la numérotation de TMDB :

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv",
 "kind": "movie", "ids": {"tmdb": 10378}, "media_info": { "...": "ffprobe's output" }}
```

**Ce que tu devrais voir.** Le film est **Big Buck Bunny (2008)** avec les visuels de Plex, quel que soit le nom du fichier. rex ne lit rien dans les noms : ce que tu envoies, c'est ce qu'il affiche. [rex avec ta propre app](any-source.md) explique tout ça en détail, épisodes compris.

## Sous-titres {#subtitles}

**Ce que ça fait.** Propose des fichiers de sous-titres placés à côté d'une vidéo, qui deviennent ses sous-titres. Les gens peuvent les choisir, les télécharger ou les incruster, comme pour un sous-titre envoyé.

```json
"subtitles": [{"path": "films/Big Buck/film.en.srt", "language": "en", "size": 82}]
```

| Champ | Signification |
|---|---|
| `path` | Où se trouve le fichier sur ton addon, comme pour une vidéo. Son extension indique son format : `srt`, `ass`, `ssa`, `smi`, `txt` ou `psb` |
| `language` | `en` ou `eng`, comme tu le connais. rex ne lit aucune langue dans le nom du fichier |
| `forced`, `hearing_impaired` | `true` pour le marquer ainsi |
| `size` | Sa taille en octets. rex ne relit le fichier que si son chemin est nouveau ou si sa taille a changé |

**Ce que tu devrais voir.** La vidéo affiche un sous-titre **English (SRT External)**. Si tu ne mets pas `subtitles`, ce que tu as envoyé avant est conservé ; `[]` supprime le tien (un sous-titre envoyé ou téléchargé reste). Un fichier que rex ne peut pas lire est laissé de côté et consigné dans les logs, et la vidéo est tout de même prise en compte.

## Bandes-annonces et autres extras {#trailers-and-other-extras}

**Ce que ça fait.** Place une bande-annonce, un featurette ou une scène supprimée sous son film ou sa série, dans **Extras**, au lieu d'en faire un titre à part entière.

```json
{"id": "films/Big Buck/trailer.mp4", "path": "films/Big Buck/trailer.mp4",
 "kind": "extra", "extra_type": "trailer", "media_info": { "...": "ffprobe's output" }}
```

Un extra appartient au titre des autres vidéos de son `release` (par défaut son dossier). `extra_type` peut valoir `trailer`, `deleted`, `featurette`, `behindthescenes`, `interview`, `scene`, `short`, `opening`, `ending` ou `other`. rex ne décide jamais qu'une vidéo est un extra d'après son nom ou son dossier : seul `kind: "extra"` en fait un.

**Ce que tu devrais voir.** La page du film affiche la bande-annonce sous Extras, et la bibliothèque ne la liste pas.

## Chapitres {#chapters}

**Ce que ça fait.** Permet de passer d'un chapitre à l'autre dans le lecteur.

Lancez aussi `ffprobe` avec `-show_chapters`, et envoyez sa sortie telle quelle :

```bash
ffprobe -v error -print_format json -show_format -show_streams -show_chapters film.mkv
```

**Ce que vous devriez voir.** Les chapitres de la vidéo, avec leurs noms et leurs heures. Pour ajouter des chapitres aux vidéos que rex a déjà, renvoyez leurs probes avec `-show_chapters` dans le prochain snapshot.

## Collections et listes de lecture {#collections-and-playlists}

**Ce que ça fait.** Regroupe les titres de ta bibliothèque en collections, et les chansons ou vidéos en playlists. Ton addon les crée et les met à jour.

```json
"collections": ["Summer 2026"],
"playlists": {"Road trip": 1}
```

| Champ | Signification |
|---|---|
| `collections` | Les collections dans lesquelles se trouve le titre, par nom. Chacune est créée la première fois qu'un titre la mentionne |
| `playlists` | Les playlists dans lesquelles se trouve le fichier, par titre, avec sa place dans chacune à partir de 1. Chacune est une playlist du propriétaire du serveur, audio si sa première chanson est une piste, vidéo sinon |

Tes modifications sont conservées : un titre que quelqu'un a retiré d'une collection reste retiré, une chanson ajoutée à ta playlist garde sa place, et une playlist renommée reste à son nouveau nom. Si tu omets le champ, ce que tu as envoyé auparavant est conservé. En revanche, `[]` (ou `{}` pour les playlists) retire le fichier de tout ce où ton addon l'avait mis.

**Ce que tu devrais voir.** L'onglet Collections de la bibliothèque affiche **Summer 2026**, et Playlists affiche **Road trip**, dans l'ordre que tu as défini.

## Images des artistes {#artist-pictures}

**Ce que ça fait.** Affiche tes images pour les artistes que ton addon musique envoie, même pour les artistes que Plex connaît et pour lesquels il choisirait sa propre image.

Enregistre avec `"artwork": "source"`, et envoie l'image sur chaque piste :

```json
"display": {"artist": {"title": "Radiohead", "poster": "http://127.0.0.1:9982/music/Radiohead/artist.jpg"}}
```

Sans `artwork: "source"`, un artiste que Plex connaît garde l'image de Plex, et `display.artist` n'apparaît que pour les artistes que Plex ne connaît pas. Dans tous les cas, une image choisie ou envoyée par quelqu'un depuis une app Plex reste en place.

## Grosses bibliothèques : envoyer les sondes une seule fois {#big-libraries-send-probes-once}

**Ce que ça fait.** Permet à un instantané de milliers de vidéos de n'envoyer presque aucune sortie `ffprobe`, donc il est petit et rapide.

Envoyez `probe`, un court texte à vous qui change chaque fois que le probe de la vidéo change (un hash de sa sortie `ffprobe` fonctionne). Dès que rex a une vidéo avec ce `probe`, envoyez `probe` seul, sans `media_info` :

```json
{"id": "films/Big Buck/film.mkv", "path": "films/Big Buck/film.mkv", "kind": "movie", "ids": {"tmdb": 10378}, "probe": "v1"}
```

rex répond `"unchanged": 1`. Quand il n'a pas ce `probe` (une nouvelle vidéo, ou une dont le probe a changé), il ne change rien et le demande :

```json
{"created": 0, "updated": 0, "held": 0, "unchanged": 0, "wants": ["films/Big Buck/film.mkv"]}
```

Renvoyez alors ces éléments avec leur `media_info`. Un instantané compte un élément demandé comme envoyé, donc il n'est jamais supprimé pour cela. Vérifiez que votre rex l'accepte : la réponse à [l'enregistrement](addons.md#step-2-register-with-rex) liste `"features": ["probe_digest"]`.

## Ce que les gens ont corrigé : Fix Match {#what-people-fixed-fix-match}

**Ce que ça fait.** Indique à votre addon quelles de ses vidéos ont été associées manuellement dans une application Plex (Fix Match), afin qu'il puisse les envoyer directement à partir de là.

```bash
curl -s http://192.168.1.20:32400/rex/feed/myaddon/matches
```

```json
{"size": 1, "matches": [{"release": "films/Mystery Reel", "ids": {"tmdb": 45745, "imdb": "tt1727587", "tvdb": 9413}, "kind": "movie", "matched_at": 1793751999}]}
```

Chaque entrée est un `release` (un dossier, sauf si vous envoyez `release`) et les ids du film ou de la série auxquels il a été associé. rex conserve l'association quoi que vous envoyiez ensuite, donc rien ne casse si vous ignorez cela. La lire permet à votre addon d'envoyer lui-même `kind` et `ids`, et de se souvenir de la correction si les lignes de rex sont un jour reconstruites. Sans rien d'associé, la réponse est `{"size": 0}`.

## Supprimer votre addon {#removing-your-addon}

**Ce que ça fait.** Retire ton addon et tout ce qu'il a envoyé depuis rex, sans toucher à ses fichiers.

Il faut deux requêtes : la première indique combien d'éléments seraient supprimés et fournit un lien valide pendant cinq minutes ; la seconde supprime le tout.

```bash
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon
# {"confirm": "/rex/sources/myaddon/confirm/eae4...", "items": 4, "expires_in": 300}
curl -s -X DELETE http://192.168.1.20:32400/rex/sources/myaddon/confirm/eae4...
# {"deleted": true, "removed": 4}
```

L'historique de visionnage disparaît avec les lignes. Si tu t'enregistres et renvoies plus tard, tout repart de zéro, avec de nouvelles lignes. Pour **remplacer** un addon par une nouvelle version, garde son nom, ses ids et le premier segment de ses chemins : la nouvelle version met alors à jour les mêmes lignes. rex ne supprime jamais les bibliothèques ; si tu veux qu'elles disparaissent, supprime-les dans une application Plex.

## Qui peut envoyer vers rex {#who-may-send-to-rex}

rex (le flux `/rex/sources` et `/rex/feed`) ne demande aucun jeton. Il ne répond qu'aux programmes qui tournent sur la machine de rex, sur votre réseau domestique (`192.168.x.x`, `10.x.x.x`, `172.16-31.x.x` et les adresses IPv6 privées) et sur Tailscale (`100.64-127.x.x`). Pour toute autre adresse, il n'existe pas, même après avoir ouvert le port de rex pour rex-direct ou l'avoir laissé passer en IPv6. Un reverse proxy sur la machine de rex accède à rex comme à un programme local, donc bloquez `/rex/` à ce niveau si vous en placez un devant rex.
