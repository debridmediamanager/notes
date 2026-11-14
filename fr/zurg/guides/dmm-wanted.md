# Récupérez ce que vous voulez depuis DMM {#fetch-what-you-want-from-dmm}

Appuyez sur **Want** sur un film ou une série dans [Debrid Media Manager](https://debridmediamanager.com),
et votre zurg le récupère. Il n'y a ni Sonarr ni Radarr à configurer, et rien à monter.
Les séries reçoivent leurs nouveaux épisodes au fur et à mesure de leur diffusion.

C'est réservé aux sponsors : zurg lit votre liste avec votre clé API DMM.

## Ce dont vous avez besoin {#what-you-need}

Une version nightly de zurg du 2026-10-25 ou plus récente.
Ta clé API DMM dans le `config.yml` de zurg. C'est la clé que [gatekeeper](https://gatekeeper.debridmediamanager.com/) t'affiche une fois que tu deviens sponsor :

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- Un endroit où zurg peut récupérer les fichiers : un compte debrid qui accepte les torrents, un fournisseur `nzb` ou `torbox_nzb` pour Usenet, ou les deux.

C'est tout pour la configuration. zurg lit ta liste une fois par minute dès son démarrage.

## Ajouter des titres {#adding-titles}

1. Collez la même clé sur la page [Settings](https://debridmediamanager.com/settings) de DMM.
2. Ouvrez un film et appuyez sur **Want**. Sur la page d'une saison de série, **Want S2** ajoute cette saison
   et **Want all seasons** ajoute toute la série, y compris les nouvelles saisons.
3. Votre liste se trouve sur [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted).
   Elle indique quand votre zurg l'a lue pour la dernière fois, et quand il a récupéré chaque film. Les longues listes
   affichent 120 titres par page.

Les demandes venant de Seerr, Overseerr ou Jellyseerr peuvent aussi arriver dans cette même liste : voir
[Seerr via DMM](../../dmm/seerr.md).

## Suivre une liste {#following-a-list}

Collez la page d'une liste Trakt, MDBList, TMDB ou Simkl sur votre [liste de souhaits](https://debridmediamanager.com/wanted)
et appuyez sur **Follow**. Chaque film et chaque série de la liste est ajouté à vos souhaits, et DMM relit la liste
toutes les six heures : ce qui y sera ajouté plus tard sera donc aussi ajouté à vos souhaits. Pages acceptées :

- `https://trakt.tv/users/<user>/lists/<list>` et `https://trakt.tv/lists/<id>`
- `https://trakt.tv/users/<user>/watchlist`, si ce profil Trakt est public
- `https://mdblist.com/lists/<user>/<list>`
- `https://www.themoviedb.org/list/<id>`, si cette liste TMDB est publique
- `https://simkl.com/<user>/list/<id>`, l'une de vos propres listes Simkl, pendant que vous êtes connecté à Simkl sur DMM

Sur les pages Trakt de DMM, votre liste de suivi et chacune de vos listes ont un bouton **Follow with Want**
qui fait la même chose. C'est aussi le cas pour chacune de vos listes sous **Simkl custom lists** sur
[la page Simkl de DMM](https://debridmediamanager.com/simkl/mylists), où vous vous connectez à Simkl.

Simkl ne répond qu'à une personne connectée, donc DMM lit une liste Simkl avec votre connexion Simkl sur DMM,
et Simkl n'affiche les éléments de liste qu'aux membres PRO et VIP. Si vous vous déconnectez de Simkl sur DMM,
la liste cesse de se mettre à jour : reconnectez-vous puis suivez-la à nouveau.

Une liste IMDb, Letterboxd, Rotten Tomatoes ou Plex : sur mdblist.com, créez une
[liste externe](https://docs.mdblist.com/docs/external_lists) à partir de son URL, puis suivez-la.
MDBList la garde synchronisée avec la source.

Ce que fait le suivi :

- Une série est ajoutée en entier, y compris les nouvelles saisons.
- Seuls les titres nouveaux sur la liste depuis sa dernière lecture sont ajoutés. Un titre que vous retirez de
  votre liste de souhaits reste retiré, et un titre qui quitte la liste reste dans vos souhaits.
  **Unfollow** conserve ce que la liste a ajouté.
- La page affiche chaque liste avec le nombre de titres qu'elle contient, le nombre déjà ajouté et la date de
  sa dernière lecture. **Read again** la relit tout de suite. Les titres sans identifiant IMDb sont laissés de côté,
  et le compteur indique combien il y en a.
- Votre liste peut contenir 10 000 titres en attente de récupération : toutes les séries, et chaque film que zurg
  n'a pas encore récupéré ou qui attend une mise à niveau. Les films déjà récupérés par zurg ne comptent pas.
  Un titre qui ne rentre pas est ajouté lors d'une lecture ultérieure, dès qu'il y a de la place.

## Passer depuis Radarr ou Sonarr {#moving-from-radarr-or-sonarr}

Importez tout ce qui est encore recherché :

1. Dans Radarr ou Sonarr, ouvrez **System → Backup**, appuyez sur **Backup Now** et téléchargez le
   zip. Les sauvegardes planifiées du dossier `Backups` conviennent aussi.
2. Sur votre [liste de souhaits](https://debridmediamanager.com/wanted), appuyez sur **Import a Radarr or
   Sonarr backup** et choisissez le zip. Faites ensuite de même avec la sauvegarde de l'autre application.

Ce qui est importé :

- Depuis Radarr, chaque film suivi sans fichier qui a atteint sa disponibilité minimale. Les films sans identifiant IMDb sont laissés de côté ; la page indique combien il y en a.
- Depuis Sonarr, chaque série suivie avec des épisodes diffusés manquants, uniquement pour ces saisons.
- Les titres déjà présents sur votre liste restent tels quels.

Seule la base de données contenue dans le zip est envoyée. Le reste de la sauvegarde, y compris la clé API de l'application, reste sur votre ordinateur.

Deux éléments ne sont pas importés :

- **Les profils de qualité.** zurg choisit les versions selon ses propres
  [paramètres d'acquisition](acquisition.md#configuration). Radarr refuse en général les copies caméra et telesync ; pour les écarter, ajoutez-les à
  [`exclude_words`](acquisition.md#excluding-releases-by-name) :

  ```yaml
  acquisition:
    exclude_words: [CAM, CAMRip, HDCAM, TS, HDTS, TELESYNC, TC, HDTC, TELECINE]
  ```

- **Les numéros de saison de Sonarr, lorsqu'ils diffèrent.** Votre liste numérote les saisons comme TMDB. Sonarr suit TheTVDB, qui découpe certains animes de longue durée en plus de saisons ; une saison Sonarr absente de TMDB n'est donc pas récupérée. Vérifiez ces séries sur leur page DMM et appuyez sur **Want** pour les saisons qui vous manquent.

## Ce que zurg récupère {#what-zurg-fetches}

- **Un film** une seule fois. Il sort ensuite de la liste que zurg lit. Un film récupéré en dessous de la résolution visée par `quality` (2160p pour `best`) reste en revanche sur la liste : zurg récupère une meilleure copie dès qu'elle sort et supprime celle qu'il avait récupérée avant. Une copie que vous avez ajoutée vous-même est conservée. `upgrades: false` sous `acquisition:` dans la configuration de zurg désactive cette fonction. `/wanted` affiche ce que zurg a récupéré et la résolution qu'il attend encore, sauf avec la liste de résolutions ci-dessous.
- **Un film en 1080p et en 4K**, si vous voulez les deux, par exemple pour qu'une TV 1080p lise une version sans que le fichier 4K soit transcodé. Nécessite la version nightly du 2026-10-31 ou ultérieure. Listez les résolutions dans la configuration de zurg :

  ```yaml
  acquisition:
    quality: [1080p, 4k]
  ```

  zurg conserve alors une copie du film à chacune de ces résolutions. Chaque copie prend la meilleure version disponible à sa résolution ou en dessous, et se met à jour de son côté : la copie 1080p ne devient jamais une copie 2160p. Tant qu'aucune version meilleure que 1080p n'est sortie, les deux prennent généralement la même version et vous n'avez qu'un seul fichier. `720p` peut aussi être ajouté à la liste. Les séries n'ont toujours qu'une seule copie, choisie comme si vous n'aviez écrit que la résolution la plus élevée. Les films que zurg a récupérés avant que vous ajoutiez la liste sont récupérés à nouveau pour chaque résolution ; zurg ne supprime jamais la copie d'avant, donc supprimez-la vous-même si vous n'en voulez plus. Les règles complètes sont dans [une copie à chacune de plusieurs résolutions](acquisition.md#a-copy-at-each-of-several-resolutions).
- **Une série** : tous les épisodes diffusés des saisons que vous avez choisies, sous forme de pack de saison lorsqu'un seul fichier couvre la saison, et sous forme d'épisodes isolés lorsqu'elle est encore en cours de diffusion. zurg continue de vérifier la présence de nouveaux épisodes jusqu'à ce que vous retiriez la série. Les épisodes spéciaux ne sont pas récupérés.

Les versions viennent de Usenet sous forme de NZB et des torrents que votre compte debrid a déjà en cache ; les torrents non mis en cache ne sont jamais ajoutés. Si vous n'avez configuré aucun indexeur, zurg effectue la recherche sur ceux de DMM. La qualité, les limites de taille, les mots à éviter et les langues audio et de sous-titres qu'une version doit avoir sont définis dans les [paramètres d'acquisition](acquisition.md#configuration) de zurg, les mêmes pour toutes les sources.

## Regarder dans Kodi ou Plex {#watching-it-in-kodi-or-plex}

Avec `__magic__` activé, zurg range par titre ce qu'il récupère, dans `__magic__/__movies__` et
`__magic__/__shows__`, avec des noms que Kodi et Plex reconnaissent. Pointez une bibliothèque Films et une bibliothèque Séries vers ces deux dossiers, ou, avec `magic.anime`, une bibliothèque Anime vers `__magic__/__anime__` aussi : voir [`__movies__` et `__shows__`](magic.md#__movies__-and-__shows__-sorted-by-title).

```yaml
magic:
  enabled: true
```

## Deux zurg avec une seule clé {#two-zurgs-on-one-key}

Chaque zurg lit la même liste, donc deux d'entre eux récupèrent chaque titre deux fois. Garde la liste activée sur un seul
et désactive-la sur les autres :

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## Quand ça s'arrête {#when-it-stops}

Si votre parrainage expire ou si vous réinitialisez votre clé, zurg journalise que DMM a refusé la clé et redemande toutes les heures. Ce qui a déjà été récupéré reste dans votre bibliothèque.

Plus de détails : [liste de souhaits DMM](acquisition.md#dmm-wanted-list) dans la référence sur l'acquisition.
