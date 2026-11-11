# Sources d'acquisition {#acquisition-sources}

Ta watchlist Plex, ta [liste de souhaits DMM](#dmm-wanted-list), [Seerr](https://github.com/seerr-team/seerr)
[Radarr](https://radarr.video) et [Sonarr](https://sonarr.tv) utilisent un même moteur d'acquisition. Il suit la progression,
les nouvelles tentatives et les accusés de réception. Les résultats Newznab deviennent des NZB pour le backend Usenet de zurg. Les résultats Torznab deviennent des info hashes pour un compte debrid. Voir [Newznab et Torznab](#newznab-and-torznab).

Le moteur ne valide un grab qu'après l'avoir vérifié. Un NZB doit atteindre le serveur de news. Sur un compte `torbox_nzb`, c'est TorBox qui doit le récupérer à la place. Un torrent doit apparaître dans la bibliothèque avec ses fichiers. Voir [Vérifier un grab](#verifying-a-grab).

Une release récupérée par zurg garde les ids du titre pour lequel elle a été récupérée, tous ceux que Plex utilise pour faire correspondre les titres : IMDb, TMDB et, pour une série, TVDB. Elle n'est jamais réidentifiée à partir de son nom. Ces ids remplacent ceux que DMM ou le nom de la release lui avaient donnés, sauf ceux que tu as définis à la main. Une release déjà présente dans ta bibliothèque quand zurg l'a choisie a peut-être été ajoutée pour autre chose, donc elle ne prend ces ids que si elle n'en a pas ou si elle a déjà les mêmes. Avec [`rex_url`](../reference/config.md#rex) défini, un film récupéré part vers rex en tant que ce film, grâce à ces ids, même quand DMM n'a pas pu le placer ; les épisodes d'une série sont toujours numérotés selon le placement de DMM et portent les ids de la série. Au démarrage, zurg fait de même pour toutes les releases que ses jobs enregistrés ont récupérées auparavant, ce qui répare les releases qui ont perdu leurs ids avant ce changement.

## Configuration

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

Exécutez ceci sur une instance zurg avec un fournisseur `nzb` ou un compte `torbox_nzb` (TorBox Pro), un compte debrid qui accepte les torrents, ou les deux. Les NZB provenant des indexeurs Newznab arrivent dans son répertoire `nzbs/`. Un compte `torbox_nzb` n'a pas de serveurs de news à vérifier ; un téléchargement là-bas est contrôlé selon que TorBox l'a bien récupéré. Les torrents provenant des indexeurs Torznab sont envoyés vers un compte debrid. Ils ne sont ajoutés que si ce compte les a déjà en cache. Sans aucun de ces deux types de compte, les sources ne démarrent pas. La page d'acquisition indique pourquoi. Plex a besoin du `plex_token` existant. Seerr a besoin de son URL de base et de sa clé API, indépendamment des réglages Plex de zurg. Les sous-chemins d'URL et les URL se terminant par `/api/v1` sont pris en charge. Radarr a besoin de son URL de base (une URL base comme `/radarr` et un `/api/v3` final sont acceptés), de sa clé API depuis **Settings > General**, et de `library_path` lorsqu'il voit le montage de zurg à un autre chemin : voir [Comportement de Radarr](#radarr-behavior). Sonarr accepte les mêmes trois réglages : voir [Comportement de Sonarr](#sonarr-behavior).

Les deux sont lus au démarrage de zurg, comme le reste du bloc. `indexer_concurrency` couvre les recherches et les téléchargements NZB ensemble, car un indexeur limite le quota par clé et non par point d'accès. Les clés d'indexeur sont souvent partagées, et trois appels par clé est la valeur mesurée sûre pour les clés qui servent aussi à une autre application.

Gardez les noms et les URL Seerr stables : ils identifient les files d'attente sauvegardées. Changer de clé Seerr conserve sa file. Redémarrez après avoir ajouté des sources ou modifié leur URL ou leurs identifiants. Les réglages existants `watchlist:` et `plex_watchlist_enabled` continuent de fonctionner via un adaptateur `plex-watchlist` automatique. Une source `plex_watchlist` explicite, même désactivée, remplace l'ancien interrupteur d'activation. Une seule source Plex peut utiliser le compte Plex configuré. Les réglages de recherche partagés se rabattent sur `watchlist:` et ses valeurs par défaut ; les indexeurs omis se rabattent sur les indexeurs watchlist/Stremio.

## Exclure des releases par nom {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` énumère les mots qu'aucune version acquise ne doit avoir dans son nom.
Utilisez-le pour écarter Dolby Vision ou HDR10+ d'un lecteur qui ne peut pas les afficher,
tout en gardant la 4K. Il s'applique à toutes les sources de la même façon : la watchlist Plex,
Seerr, Radarr et Sonarr. Il s'applique de la même façon aux résultats Usenet et torrent. Une
version qu'il exclut n'est jamais téléchargée, sauvegardée, ajoutée à un compte debrid ni transmise
à Radarr ou Sonarr. Ne le mettez pas pour ne rien exclure. zurg le lit au démarrage, comme le reste de `config.yml`.

## Privilégier des releases par nom {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

`prefer_words` liste des mots, comme des groupes de release, qui font passer une release en premier parmi les releases de sa résolution. La correspondance fonctionne comme pour `exclude_words` : mots entiers, sans tenir compte de la casse. La liste est ordonnée : une release avec le premier mot passe avant une release avec le deuxième, et ainsi de suite. C'est une préférence, pas un filtre. Quand aucune release ne contient un de ces mots, zurg prend ce qu'il aurait pris sans eux.

Une release préférée ne passe jamais devant une résolution supérieure. Avec `quality: best`, une release 2160p de n'importe quel groupe passe toujours avant une release 1080p préférée, et avec `quality: 1080p`, une release 2160p préférée ne passe pas devant les releases 1080p. Une montée vers une résolution supérieure a quand même lieu si le groupe préféré n'a pas de release à cette résolution.

Ça s'applique à toutes les sources, et aux résultats Usenet comme torrent. Avec une source `radarr` ou `sonarr`, le profil doit quand même accepter la release préférée. Quand Radarr ou Sonarr utilisent zurg comme client de téléchargement, ils choisissent eux-mêmes la release, et `prefer_words` ne s'applique pas dans ce cas. Si tu ne le mets pas, zurg ne préfère rien.

La release d'un film n'est jamais prise non plus quand son nom indique une année qui s'écarte de plus d'un an de celle du film, quelle que soit la source. Certains indexeurs rangent des posts sous l'identifiant IMDb d'un autre film : DrunkenSlug classe The Aswang Chronicles (2012) sous sa suite de 2014. Un nom sans année n'est pas refusé pour ça. Pour la liste de souhaits DMM, qui envoie chaque titre sous lequel un film est connu (original, titres alternatifs et traductions), une release dont le nom ne contient pas l'un de ces titres en entier est refusée aussi : DrunkenSlug classe Przesluchanie (1982) sous An Affair (1982), et `Rocky.2015` n'est pas *Rocky Horror Show Live*. Un nom peut s'arrêter là où commence le sous-titre d'un titre, après un deux-points ou un tiret entouré d'espaces, donc `Diana.2021` correspond à *Diana: The Musical*. Les accents et les tréma correspondent dans les deux sens, donc `Les.Miserables` et `Verwuenscht.nochmal` comptent.

Comment un nom est comparé :

- **Mots entiers uniquement.** Un nom est lu comme une suite de mots faits de lettres et de chiffres. Les points, espaces, tirets, tirets bas, crochets et parenthèses séparent tous les mots. La casse n'a pas d'importance. `DV` exclut `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` et `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD`. Il n'exclut pas `DVDRip`, `DVD9`, `Come and See DvD 1` ni un titre comme *Adventures*, car aucun de ces noms ne contient le mot DV.
- **Les expressions se comparent dans l'ordre.** `Dolby Vision` ou `DV HDR` ne correspondent que si ces mots se suivent dans cet ordre, quel que soit le séparateur entre eux.
- **Un `+` en fin de mot fait partie du mot.** `HDR10+` est un mot à part entière. Exclure `HDR10` laisse tranquilles les releases HDR10+, et exclure `HDR10+` laisse tranquille le HDR10 simple. Mets les deux pour exclure les deux. Un `+` entre deux mots les sépare, comme dans `DD+7.1` ou `DV+HDR10`.
- **Deux familles d'écritures comptent pour un seul mot.** Une écriture de la liste exclut toutes les écritures de sa famille.

  | Écris l'une de | Exclut les noms contenant l'une de |
  |---|---|
  | `DV`, `DoVi`, `Dolby Vision`, `DolbyVision` | `DV`, `DoVi`, `Dolby.Vision`, `Dolby-Vision`, `Dolby Vision`, `DolbyVision` |
  | `HDR10+`, `HDR10Plus` | `HDR10+`, `HDR10Plus` |

  Rien d'autre n'est assimilé. `HDR` exclut les noms qui contiennent le mot HDR, et pas `HDR10`, `HDR10+` ni `HDRip`. `WEB-DL` correspond à `WEB-DL`, `WEB.DL` et `WEB DL`, mais pas à `WEBDL`.
- **Seul le nom de la release est lu.** C'est le titre que l'indexeur renvoie, avant tout téléchargement. Les fichiers à l'intérieur ne sont pas lus. Une release Dolby Vision dont le nom ne le dit pas n'est donc pas exclue.

Exclure un mot ne touche jamais à la résolution. Avec `DV` exclu, une release 2160p en HDR simple ou HDR10 est toujours prise, et `quality: 4k` place toujours le 2160p en premier. Une release exclue compte comme non trouvée. Une recherche de film ou d'épisode continue de parcourir chaque indexeur jusqu'à avoir dix releases utilisables, jusqu'à ce que l'indexeur n'en ait plus, ou jusqu'à avoir lu dix pages. Une recherche de saison lit une seule page, puis cherche séparément chaque épisode que cette page laisse sans release. Un titre dont toutes les releases sont exclues échoue avec « no eligible releases », comme un titre dont toutes les releases dépassent `max_size_gb`, et il est réessayé plus tard. Une demande 4K dans Seerr ne prend que les releases 2160p, donc elle attend quand toutes les releases 2160p sont exclues.

### Exclusions et profils Radarr ou Sonarr {#exclusions-and-radarr-or-sonarr-profiles}

Avec une source `radarr` ou `sonarr`, l'exclusion passe en premier. Une release exclue n'est jamais transmise au parseur de Radarr ou de Sonarr. Aucun score de format personnalisé ne peut la faire revenir, et elle ne compte pas comme un refus du profil. Chaque autre release est évaluée par le profil, comme décrit dans [Comportement de Radarr](#radarr-behavior) et [Comportement de Sonarr](#sonarr-behavior). Une release doit réussir les deux contrôles. Un format personnalisé qui attribue à Dolby Vision un score inférieur au minimum du profil fait le même travail dans les *arr, et le garder ne pose aucun problème.

Les mises à niveau suivent la même règle. Si les seules releases qui permettraient de faire passer un fichier au seuil (cutoff) de son profil sont exclues, le fichier reste en dessous de ce seuil, et le passage de mise à niveau de zurg continue de chercher sans rien prendre. Cela arrive quand un format personnalisé donne un score élevé à Dolby Vision et que le score de seuil en a besoin. Dans ce cas, baissez le score de seuil ou retirez ce score du format personnalisé.

Quand Radarr ou Sonarr utilisent zurg comme client de téléchargement via le bloc `sabnzbd:` ou `qbittorrent:`, ils cherchent sur leurs propres indexeurs et choisissent eux-mêmes la release. `exclude_words` ne s'applique pas dans ce cas. Excluez les mêmes mots dans les *arr, avec un format personnalisé noté sous le minimum du profil, ou avec **Must Not Contain** dans un profil de release.

## Choisir selon la langue audio et les sous-titres {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

`audio_languages` ne retient que les releases ayant une piste audio dans l'une des
langues listées, et `subtitle_languages` seulement les releases ayant une piste de
sous-titres dans l'une d'elles. Omets l'une ou l'autre pour ne rien demander. Les deux
s'appliquent à toutes les sources.

Chaque liste est aussi un ordre : une release avec une langue plus tôt dans la liste passe
devant une release qui n'a qu'une langue plus loin. `[de, original]` prend un doublage
allemand s'il existe, et la langue originale sinon.

zurg lit la langue dans les flux de la release, pas dans son nom. La plupart des releases ne nomment pas leurs langues : presque aucune de celles de Parasite ne dit KOREAN. Écris des codes ISO 639, deux ou trois lettres : `en`, `eng`, `de`, `deu` et `ger` fonctionnent tous. Un nom comme `german` est refusé au démarrage.

Certaines langues ont des doublages ou des sous-titres qui diffèrent, et un code peut désigner l'un d'eux :

| Écris | Pour |
|---|---|
| `es-419`, `es-ES` | Espagnol latino-américain (latino) ou espagnol de Castille |
| `pt-BR`, `pt-PT` | Portugais brésilien ou européen |
| `fr-CA`, `fr-FR` | Français québécois (VFQ) ou français de France (VFF, VFI) |
| `nl-BE` | Flamand |
| `yue`, `cmn` | Cantonais ou mandarin |
| `zh-Hant`, `zh-Hans` | Sous-titres en chinois traditionnel ou simplifié (`zh-TW` et `zh-HK` sont lus comme traditionnel, `zh-CN` comme simplifié ; pour un audio cantonais, écris `yue`) |
| `nb`, `nn` | Norvégien bokmål ou nynorsk |

Le code simple prend toutes ces variantes : `es` prend le latino et le castillan, `zh` le cantonais et le mandarin, `no` le bokmål et le nynorsk. Une partie après la langue que zurg ne sait pas lire, comme `es-latam`, est refusée au démarrage. zurg lit la variante d'une piste à partir de son titre, car les flux ne la donnent jamais sous une forme que zurg peut lire : "Latino", "Spanish (Latin American)", "Castellano", "French (Canada)", "VFQ", "Portuguese (Brazilian)", "Chinese (Cantonese)", "繁体中字". Une piste dont le titre ne dit ni l'un ni l'autre n'est jamais refusée pour cela. Le nom de la release départage quand il en indique une, comme `Dual-Lat`, `[Castellano]`, `MULTi.VFQ`, `VF2`, `PT-BR` ou `[ES-LA]`. Un nom ne refuse jamais rien, et le titre d'une piste l'emporte sur lui. Pour `[es-419, es]`, zurg prend, dans l'ordre, une piste intitulée Latino, une piste sans titre dans une release nommée Latino, une piste sans titre, une piste sans titre dans une release nommée Castellano, et une piste intitulée Castellano. Pour un foyer latino-américain :

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

`audio_or_subtitles: true` retient une release qui a l'audio ou les sous-titres, et non les deux. Une release avec l'audio passe devant une release qui n'a que les sous-titres.

`original` désigne la langue dans laquelle le titre a été réalisé, telle que TMDB la note : coréen pour Parasite, français pour Anatomy of a Fall. zurg demande cette information à DMM, donc il a besoin de `dmm_api_key`. Sans la clé, `original` ne demande rien.

### Comment une release est jugée {#how-a-release-is-judged}

- **Avant l'ajout d'un torrent.** DMM garde les données ffprobe de chaque release qu'un
  zurg a analysée. Avec `dmm_api_key` défini, zurg les lit pour chaque résultat torrent
  en un seul appel. Un torrent dont les flux n'ont pas la langue n'est jamais
  ajouté. Un torrent qui l'a passe avant ceux dont on ne sait rien.
  Lors d'une mesure sur cinq films le 2026-10-25, DMM avait ces données pour environ
  un tiers des torrents mis en cache par Real-Debrid.
- **Après la récupération.** Chaque récupération, torrent ou Usenet, est analysée une fois
  qu'elle est dans la bibliothèque : avec les données de DMM si elles existent, sinon avec ffprobe. Une
  récupération dont les flux n'ont pas la langue est mise de côté comme un post mort. Elle est
  retirée du compte debrid ou sortie du dossier de surveillance, et le candidat suivant
  est essayé tout de suite. Le tableau de bord dit pourquoi, par exemple "it has no
  English audio, only French".
- **Une mise à niveau garde ses langues.** Quand la wanted list de DMM fait passer un
  film à une meilleure résolution, la nouvelle release doit avoir les langues au moins aussi
  haut dans tes listes que la copie qu'elle remplace. Une copie 1080p en latino
  n'est pas échangée contre une 2160p en castillan.
- **L'inconnu est accepté.** Une release n'est jamais refusée pour ce qu'on ne peut pas lire.
  C'est le cas des pistes sans étiquette, d'une piste marquée `und` ou `mul`, d'une release
  qu'on n'atteint qu'à travers ses archives, ou de l'absence de sonde au bout d'une minute. zurg note
  dans le journal qu'il l'a acceptée telle quelle.

Les pistes de commentaire et de description audio ne comptent pas comme audio du film,
et les sous-titres de commentaire ne comptent pas comme sous-titres. Cela inclut un commentaire
nommé seulement dans son titre, comme "Commentary by Bong Joon Ho" pour Parasite. Les pistes de sous-titres
intitulées forced (forzados, forcés), signs ou songs ne comptent pas comme sous-titres. Le simple
drapeau forced n'exclut pas une piste : les remuxes de films étrangers marquent leurs
sous-titres anglais complets comme forced pour que les lecteurs les affichent.

Seuls les fichiers vidéo principaux d'une release sont jugés, ceux qui durent au moins un
cinquième de la durée du plus long. Les bonus ont souvent moins de doublages que le film. Dans un
pack de saison, chaque épisode doit avoir la langue.

Une release mise de côté pour sa langue reste mise de côté pendant 30 jours, comme un post mort,
même si tu changes les langues.

## Liste de souhaits DMM {#dmm-wanted-list}

Un sponsor de DMM ajoute des films et des séries à une liste de souhaits avec le bouton **Want** sur ses pages sur debridmediamanager.com, et les retrouve sur `/wanted`. zurg lit cette liste dès que `dmm_api_key` est défini : il n'y a rien d'autre à écrire. Rien n'est monté et ni Sonarr ni Radarr n'interviennent. La source s'appelle `dmm-wanted` et est interrogée toutes les 60 secondes.

- **Ce qui est récupéré.** Un film une fois, puis chaque amélioration de celui-ci (voir ci-dessous), ou une copie à chacune de plusieurs résolutions quand `quality` est une liste (voir ci-dessous). Pour une série, les épisodes déjà diffusés dans les saisons demandées, ou dans toutes les saisons si la série entière est demandée, ainsi que ses nouveaux épisodes au fur et à mesure de leur diffusion.
  DMM envoie les identifiants IMDb, TMDB et TVDB de chaque titre, son année et, pour une série, les épisodes diffusés jusqu'ici, numérotés comme TMDB les numérote. Les spéciaux ne sont jamais listés. Une saison encore en cours de diffusion est récupérée épisode par épisode, car aucun pack ne la couvre encore.
- **Quand il est recherché.** Un film est recherché dès sa sortie à la maison : DMM envoie le jour de sa première sortie numérique, physique ou TV connue de TMDB, zurg attend au maximum jusqu'à ce jour, puis recherche toutes les deux minutes pendant six heures, et toutes les dix minutes jusqu'à deux jours après, comme pour un [nouvel épisode](#sonarr-behavior). Jamais une date de sortie en salle : un WEB-DL est publié avec la sortie numérique. Le dernier épisode d'une série est daté de la même façon, à partir de l'heure de diffusion quand DMM la connaît. Un titre sans date garde les nouvelles tentatives habituelles, espacées d'une semaine au plus, et rien de la liste n'est jamais [mis en pause](#persistence-and-recovery). Un film en attente de sa prochaine tentative est recherché à la prochaine interrogation dès que DMM voit une nouvelle publication Usenet qui le nomme.
- **Où il va.** Comme pour toute source : un NZB d'un indexeur Newznab vers le backend Usenet de cette instance, ou un torrent d'un indexeur Torznab vers un compte debrid qui l'a déjà en cache, selon celui que `prefer` privilégie en premier. `quality`, `max_size_gb` (par épisode pour un pack de saison), `exclude_words` et les [langues](#choosing-by-audio-and-subtitle-language) s'appliquent, ainsi que `max_season_size_gb` si vous en écrivez un.
- **Indexeurs.** Si aucun indexeur n'est écrit sous `acquisition:`, `watchlist:` ou `stremio:`, la clé recherche aussi chez DMM : son indexeur Usenet et les torrents dont il sait qu'ils sont en cache chez Real-Debrid ou AllDebrid (`/api/torznab/cached`). Écrire un indexeur remplace les deux.
- **Accusé de réception.** Une fois le téléchargement d'un film vérifié, zurg le signale à DMM, et le film quitte la liste lue par zurg, sauf s'il attend une amélioration ou une autre de ses copies (voir ci-dessous) ; `/wanted` indique quand. Une série reste sur la liste et continue d'être suivie jusqu'à ce que vous la retiriez là-bas. Retirer un titre arrête le travail sur lui.
- **Améliorations.** Un film dont le nom de release indique une résolution inférieure à celle visée par `quality` (2160p pour `best` et `4k`, 1080p pour `1080p`, 720p pour `720p`) reste sur la liste. zurg récupère une release indiquant une résolution plus élevée que la copie qu'il détient dès qu'elle sort, jusqu'à ce qu'il détienne celle-ci. Une fois la meilleure copie validée, l'ancienne est supprimée si zurg l'a récupérée, à partir de la nightly du 2026-10-30 : un torrent du compte auquel zurg l'a ajouté, ou un NZB du dossier de surveillance. Une copie qui était déjà à vous est conservée, tout comme une copie dont une partie est placée sous `__magic__`, par exemple après un import de Radarr. Une release dont le nom n'indique aucune résolution n'est jamais améliorée, et `quality: smallest` n'améliore rien. Tant qu'une meilleure release n'apparaît pas, le film est recherché environ une fois par semaine, et il n'est jamais [mis en pause](#persistence-and-recovery). Activé par défaut ; `upgrades: false` dans le bloc `acquisition:` le désactive.
- **Une copie à chacune de plusieurs résolutions.** Avec `quality` écrit sous forme de liste, par exemple `[1080p, 4k]`, chaque film garde une copie à chaque résolution de la liste. Voir [une copie à chacune de plusieurs résolutions](#a-copy-at-each-of-several-resolutions).
- **Sans compte de téléchargement.** Une instance sans fournisseur `nzb`, sans compte `torbox_nzb` (TorBox Pro) et sans compte debrid acceptant les torrents ne lit pas la liste.

**Deux zurg sur une même clé récupèrent chaque titre.** Chacun lit la même liste, donc activez la liste wanted sur un seul d'entre eux et désactivez-la sur les autres en l'écrivant comme désactivée :

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

Un sponsoring expiré ou une clé réinitialisée arrête la liste. zurg journalise un avertissement indiquant que DMM a refusé `dmm_api_key`, puis redemande une heure plus tard, ou immédiatement quand vous définissez une nouvelle clé. Ce qui a déjà été récupéré reste dans votre bibliothèque.

### Une copie par résolution {#a-copy-at-each-of-several-resolutions}

Écrivez `quality` sous forme de liste pour garder une copie de chaque film de la liste de souhaits à chaque résolution de cette liste, par exemple pour qu'une TV 1080p en lise une sans que le fichier 4K soit transcodé :

```yaml
acquisition:
  quality: [1080p, 4k]
```

Chaque copie prend la meilleure release à sa résolution ou en dessous, et jamais une au-dessus. La copie 1080p ne prend aucune release 2160p, ni aucune dont le nom n'indique pas de résolution, car celle-ci pourrait être n'importe quoi. La copie 4K ne prend une telle release que lorsqu'aucune release indiquant une résolution ne peut être prise, et la garde alors définitivement, car une release sans résolution indiquée n'est jamais améliorée. Chaque copie s'améliore de son côté, jusqu'à sa propre résolution. Quand les deux prendraient la même release, elles partagent une seule copie, et cette copie n'est supprimée que lorsqu'aucune des deux ne la garde plus :

| Releases sorties | Copie 1080p | Copie 4K | Dans votre bibliothèque |
|---|---|---|---|
| 720p | la 720p | la même 720p | la 720p |
| + 1080p | passe à la 1080p | passe à la 1080p | la 1080p |
| + 2160p | reste | passe à la 2160p | la 1080p et la 2160p |

Un film qui ne sort qu'en 2160p obtient sa copie 4K tout de suite, et sa copie 1080p dès qu'une release en 1080p ou moins apparaît. D'ici là, il est recherché environ une fois par semaine et n'est jamais mis en attente. Le film quitte la liste que lit zurg seulement quand chaque copie détient une release qu'elle ne souhaite pas meilleure.

- **Ce que la liste accepte.** Deux valeurs ou plus parmi `4k` (ou `2160p`), `1080p` et `720p`, chacune une seule fois, dans n'importe quel ordre et quelle que soit la casse. zurg refuse de démarrer avec autre chose et affiche `acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`. Une liste d'une seule valeur est lue comme cette valeur seule, donc `[1080p]` équivaut à `quality: 1080p` et ne garde qu'une copie ; écrivez `4k` à la place, car `[2160p]` est refusé.
- **Uniquement dans le bloc `acquisition:`.** `quality` sous `watchlist:` ne prend qu'une seule valeur ; une liste à cet endroit empêche zurg de démarrer. Le réglage de qualité de la page de configuration ne modifie que `watchlist.quality`, et ne change rien tant que `acquisition.quality` est écrit.
- **Uniquement les films de la liste de souhaits DMM.** Les séries qui s'y trouvent, ainsi que toutes les autres sources, n'obtiennent quand même qu'une copie, choisie comme si `quality` ne désignait que la résolution la plus haute de la liste : `[1080p, 4k]` fonctionne comme `quality: 4k` pour elles, et `[720p, 1080p]` comme `quality: 1080p`, qui prend encore une release 2160p lorsqu'aucune 1080p n'est sortie.
- **Avec `upgrades: false`**, chaque copie garde la première release qu'elle prend. Tant qu'une seule 720p est sortie, les deux copies restent cette 720p pour de bon.
- **Les films récupérés avant que vous n'écriviez la liste** sont récupérés à nouveau, une copie par résolution. Une copie dont la meilleure release est déjà dans votre bibliothèque l'utilise telle quelle. zurg ne supprime jamais l'ancienne copie : supprimez-la vous-même si les nouvelles la remplacent.
- **Revenir à une seule valeur** laisse les copies en place.
- **`/wanted` affiche le film comme récupéré** dès que sa première copie est là, avec la première release que zurg a prise. Il n'indique pas quelle résolution attend encore. Un film récupéré avant que vous n'écriviez la liste peut continuer d'afficher "waiting for" la résolution qu'il attendait à ce moment-là.

### Diffuser un film depuis YouTube {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM wanted list, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the wanted list takes a stream:
  a film the Plex watchlist also wants is not settled for it by one, since Plex cannot
  play it, and the watchlist keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one wanted list (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the wanted list while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## Comportement de Seerr {#seerr-behavior}

L'adaptateur suit les
[routes de requêtes](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts),
[définitions des statuts](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)
et le [contrat d'API](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml) de seerr-team/seerr.

- Interroge toutes les pages des requêtes approuvées avec `X-Api-Key`. Si une page échoue, la file précédente est conservée et le travail de cette source est mis en pause.
- Revérifie l'approbation avant l'acquisition. Les requêtes en attente, refusées, en échec, terminées, supprimées ou déjà disponibles ne lancent aucun téléchargement.
- Résout les ID via Seerr. L'acquisition de séries est limitée aux saisons demandées et approuvées, ainsi qu'à leurs épisodes déjà diffusés et connus. Une saison partielle reste en attente.
- Traite séparément le 4K et le non-4K. Une release 1080p ne peut pas satisfaire une requête 4K.
- Revérifie les requêtes ouvertes toutes les 30 minutes après une acquisition réussie, pour trouver les nouveaux épisodes diffusés dans les saisons demandées. Les épisodes non annoncés ne deviennent du travail qu'une fois qu'ils apparaissent dans les métadonnées de Seerr.
- Privilégie les packs une fois que tous les épisodes connus ont été diffusés. Les saisons en cours de diffusion utilisent des épisodes isolés. Les spéciaux (saison 0) ne sont pas pris en charge. Une requête avec la saison 0 approuvée n'est pas du tout acquise et échoue tant qu'elle n'est pas mise de côté.
- N'écrit aucun statut de requête ni de disponibilité. Le scan du serveur multimédia de Seerr indique la disponibilité réelle et prévient les demandeurs. Enregistrer un NZB ne prouve pas qu'il est indexé ou lisible, c'est pourquoi le moteur le vérifie avant de considérer une saison comme acquise.

Configurez le scan de bibliothèque de Seerr pour inclure la bibliothèque servie par cette instance.
Si Sonarr/Radarr acquièrent déjà les mêmes requêtes, désactivez ce workflow qui se chevauche avant d'activer cet adaptateur. L'adaptateur n'émule pas un serveur *arr et ne modifie pas la configuration de service de Seerr. Le polling assure la reprise après un redémarrage ; aucun webhook n'est nécessaire.

## Comportement de Radarr {#radarr-behavior}

Radarr garde la liste et possède la bibliothèque. zurg s'occupe de la recherche et du téléchargement.
Radarr ne cherche jamais et ne récupère jamais rien : zurg lit ce que Radarr veut, choisit une release parmi ses propres indexeurs,
la vérifie auprès des serveurs de news (la récupération de TorBox sur un compte `torbox_nzb`) ou du compte debrid qui la contient,
place la vidéo dans le dossier du film à l'intérieur de `__magic__` et demande à Radarr de rescanner ce seul film. Rien n'est copié : la vidéo est un fichier dans la bibliothèque de zurg que Radarr voit maintenant dans son dossier.

### Configurer Radarr {#setting-up-radarr}

1. **Dossier racine dans `__magic__`, un niveau plus bas.** Par exemple
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` sous macOS,
   `Z:\__magic__\movies` sous Windows). Ni `__magic__` lui-même, ni
   `__magic__/__all__`, qui liste chaque release de la bibliothèque. Un film
   dont le dossier se trouve ailleurs est ignoré, avec un seul avertissement dans
   le journal de zurg. Sous Windows, Radarr ne voit `Z:` que s'il tourne dans la
   même session de connexion que zurg, donc pas en tant que service Windows :
   voir [les règles de session](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Listes d'importation avec la recherche à l'ajout désactivée.** Ajoutez les films
   comme vous voulez (à la main, via des listes, ou Seerr pointé vers Radarr).
   Laissez **Search for Movie** désactivé à l'ajout, car c'est zurg qui fait la recherche.
3. **Aucun indexeur ni client de téléchargement n'est nécessaire.** Si Radarr en a,
   il peut récupérer des fichiers en parallèle de zurg. Désactivez donc la recherche
   automatique sur ses indexeurs (ou supprimez-les) pour les films que zurg gère.
4. **`library_path` est l'endroit où Radarr voit `__magic__`.** Quand Radarr tourne
   sur la même machine que zurg et voit le point de montage à l'endroit où zurg le
   monte, laissez-le de côté : il vaut par défaut `mount_path` de zurg suivi de
   `/__magic__`. Quand Radarr tourne dans un conteneur qui monte zurg ailleurs,
   indiquez ce chemin, par exemple `/data/zurg/__magic__`. Un film situé dans
   `/data/zurg/__magic__/movies/Heat (1995)` est alors placé dans
   `movies/Heat (1995)` à l'intérieur du `__magic__` de zurg. Les chemins Windows
   comme `Z:\__magic__` fonctionnent aussi. Un conteneur Radarr n'est pris en charge
   que sur un hôte Linux : Docker Desktop sous macOS et Windows fait tourner les
   conteneurs dans une VM, et passer le montage de zurg à l'intérieur n'a pas été
   testé, donc installez Radarr nativement sur ces systèmes.

   Si Radarr récupère aussi des fichiers via le point d'accès [SABnzbd](sonarr-radarr.md)
   ou [qBittorrent](sonarr-radarr-torrents.md) de zurg, il doit voir leur dossier de
   téléchargement à `library_path/__all__`, à travers le même volume que ses dossiers
   racines, sinon chaque import depuis ce dossier sera une copie du fichier entier.
   zurg demande à Radarr où il voit les deux et le signale sur la page d'acquisition,
   dans son journal et dans `zurg doctor` quand ils ne peuvent pas partager un même
   montage ; voir [Un seul volume pour le dossier de téléchargement et les dossiers racines](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### Ce que zurg demande à Radarr {#what-zurg-asks-radarr-for}

Chaque poll lit la liste de films de Radarr et agit sur chaque film qui est monitored, **disponible** selon sa minimum availability, et qui soit n'a pas de fichier, soit a un fichier sous le cutoff de son profil de qualité, quand le profil autorise les upgrades. Sous le cutoff veut dire sous la qualité cutoff ou sous le score de format personnalisé cutoff, tel que Radarr le compte. Un film pas encore sorti, par exemple un film daté de dans plusieurs mois, attend que Radarr dise qu'il est disponible.

Chaque release candidate que zurg s'apprête à inspecter est envoyée au parser de Radarr (`/api/v3/parse`) et jugée selon le profil de qualité du film. Ainsi, ce que zurg accepte est ce que Radarr aurait accepté :

- **Ça doit être bien ce film.** Radarr doit associer le titre au même film. Une recherche par ID chez un indexeur renvoie parfois d'autres films (une recherche de *Psycho* a renvoyé *Ed Gein: The Real Psycho*), et un titre que Radarr ne rattache à rien est refusé. Une année dans le titre qui est à plus d'un an d'écart de celle du film est refusée aussi.
- **La liste d'autorisation et le score minimum du profil s'appliquent en premier.** La qualité parsée doit être autorisée par le profil, le score de format personnalisé doit atteindre le minimum du profil, et la taille doit respecter les limites de la qualité dans **Settings > Quality** pour la durée du film.
- **La release doit être dans la langue du profil.** Avec **Original**, la valeur par défaut, Radarr doit lire le titre comme la langue d'origine du film, donc une release uniquement en français d'un film anglais est refusée. Un titre qui ne nomme aucune langue compte comme l'original. Une langue nommée demande cette langue, et **Any** accepte toutes les langues. Ça vaut pour un premier fichier comme pour un upgrade.
- **Les upgrades visent le cutoff par étapes.** Un film sans fichier prend n'importe quelle release qui passe les vérifications ci-dessus. Une fois qu'il a un fichier sous le cutoff, seule une meilleure release est prise : une qualité plus haute dans l'ordre du profil tant que le fichier est sous la qualité cutoff, ou un score de format personnalisé plus haut (d'au moins le upgrade step du profil) tant qu'il est sous le score cutoff. Une qualité plus basse n'est jamais prise. Les releases PROPER et REPACK de même qualité ne sont pas considérées comme des upgrades.

Le profil est appliqué à la release que zurg s'apprête à prendre, comme une liste d'autorisation : le bon film, une qualité autorisée, le score minimum, la langue et les limites de taille.
Par défaut, l'ordre de préférence du profil n'est pas utilisé pour choisir parmi les releases autorisées. zurg prend la première release autorisée la moins coûteuse à vérifier, en essayant d'abord les releases web (WEB-DL, WEBRip), puis les Blu-ray, puis le reste, car les releases web sont celles qui sont le plus souvent publiées sous forme d'un seul fichier vidéo.
Si le profil préfère quelque chose de mieux que ce qui arrive et autorise les upgrades, Radarr voit le fichier du film sous le cutoff, et la passe d'upgrade de zurg cherche la meilleure release une fois que le film en a une. Le premier fichier arrive vite, et l'ordre du profil est servi par l'upgrade. Mets `best_first: true` pour que le premier téléchargement suive plutôt l'ordre du profil.
Voir [Prendre d'abord le meilleur du profil](#taking-the-profiles-best-first).

Quand une recherche par l'ID IMDb ou TMDB du film ne renvoie rien du tout, zurg refait une recherche par titre et année, comme le fait Radarr. Beaucoup de posts, surtout les petits documentaires, sont indexés sans aucun ID. Le parser de Radarr décide si chaque résultat est bien le film, donc un film qui porte le même nom est refusé comme n'importe quel autre mauvais match.

Radarr n'est interrogé sur une release que quand zurg s'apprête à l'inspecter, une release à la fois. Un film avec une release en un seul fichier coûte donc entre une et trois questions. Plus rien n'est demandé une fois qu'un post direct est enregistré. Un titre qui nomme une résolution pour laquelle le profil n'a aucune qualité autorisée, comme une release 2160p pour un profil HD-1080p, est refusé sans même demander à Radarr. Un titre qui ne nomme aucune résolution, ou plusieurs, va toujours à Radarr, et c'est aussi le cas de chaque titre quand le profil autorise une qualité dont le nom n'indique aucune résolution (SDTV, DVD, Unknown, Raw-HD, BR-DISK). zurg fait au maximum huit appels en même temps à un même Radarr.

Si Radarr est injoignable, rien n'est décidé : le film attend le prochain poll, et aucune release n'est écartée parce que Radarr n'a pas répondu.

### Placer le fichier {#placing-the-file}

Une fois une release vérifiée, zurg place sa vidéo dans le dossier du film, comme Radarr l'aurait importée, en la déplaçant dans `__magic__`. Rien n'est copié ni téléchargé.

- **La plus grosse vidéo est celle qui est placée.** C'est le plus gros fichier `.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov` ou `.ts` de la release, en comptant ce qui se trouve à l'intérieur de ses archives. Une release servie depuis une seule archive correspond au contenu de cette archive. Un jeu de RAR accompagné de fichiers isolés, comme une publication scene avec son échantillon et son `.nfo`, est parcouru comme un dossier de la release, et la vidéo qui s'y trouve est placée depuis là. Les échantillons, les bonus, les sous-titres et les fichiers `.nfo` restent dans `__magic__/__all__`. Le fichier garde le nom qu'il a dans la release, sauf si ce nom ne dit rien du film (ni année ni mot de son titre). Dans ce cas, il prend le nom de la release, pour que Radarr puisse lire sa qualité.
- **Un échantillon n'est jamais placé.** Une vidéo nommée comme un échantillon (`sample-…`, `….sample.mkv`, un dossier `Sample/`) est écartée, quelle que soit sa taille, sauf si le nom de la release lui-même contient aussi sample. Un film qui n'a ce mot que dans son titre (`Sample.Size.2019`, `Death.Proof.2007`) le porte aussi dans le nom de la release. Dans ce cas, la vidéo n'est écartée que si elle pèse moins d'un cinquième de la release. Une release dont la seule vidéo est son échantillon, y compris une publication qui ne contient que son échantillon, est mise de côté et on essaie le candidat suivant. Ainsi, une mise à niveau ne remplace jamais ton fichier par un extrait d'une minute.
- **Elle est refusée avant d'être déplacée si elle ne peut pas être lue.** C'est la vérification que subit un import Sonarr ou Radarr passant par le montage. Une release dont les articles ne sont plus disponibles sur les serveurs de news, ou dont l'archive ne s'ouvrira jamais, est mise de côté comme une publication morte, et on essaie le candidat suivant. Une release qui ne peut pas être lue pour le moment, par exemple parce que son compte est en cooldown, est réessayée plus tard.
- **Radarr ne garde qu'un fichier par film, donc une mise à niveau remplace l'ancien fichier.** Quand la nouvelle vidéo est dans le dossier, toutes les autres vidéos placées là par la bibliothèque de zurg sont masquées. Masqué veut dire marqué comme supprimé (tombstone), comme lors d'une suppression via le montage : l'ancienne release reste dans `__all__` et sur son compte. Un vrai fichier que tu as mis toi-même dans le dossier n'est pas touché. L'ancien fichier n'est retiré qu'après le placement du nouveau, donc si le placement échoue, le film garde le fichier qu'il avait.
- **Radarr relance un scan ensuite.** zurg indique au montage quels dossiers ont changé, pour que le scan ne lise pas un dossier que le montage considère encore comme vide. Puis il demande à Radarr de scanner ce seul film.

Une source Radarr a besoin de `__magic__` (`magic.enabled`). Sans lui, la source ne démarre pas, et cela est indiqué dans le journal et sur la page d'acquisition.

### Ce que Radarr affiche {#what-radarr-shows}

**Activity** reste vide : aucune entrée de file d'attente et aucun événement de grab ou d'import, parce que Radarr n'a rien pris. Le film a simplement un fichier après le rescan que zurg demande, et sa qualité ainsi que ses formats personnalisés sont l'interprétation de ce fichier par Radarr. Le journal de zurg enregistre chaque film qu'il termine.

`only_new_items` et `remove_after_grab` n'ont aucun effet pour une source Radarr. Les films demandés dans Radarr sont du travail, comme les demandes approuvées dans Seerr, et c'est Radarr qui décide quand un film cesse d'être demandé. Garde le `name` de la source stable : il identifie la file d'attente sauvegardée, tandis que l'URL et la clé peuvent changer librement.

## Comportement de Sonarr {#sonarr-behavior}

Sonarr fonctionne comme Radarr. Sonarr garde la liste et gère la bibliothèque.
zurg s'occupe de la recherche et du téléchargement. Sonarr ne cherche jamais et ne récupère jamais rien. zurg lit les épisodes qui manquent à Sonarr et choisit une release parmi ses propres indexeurs. Il vérifie la release auprès des serveurs de news (le fetch de TorBox sur un compte `torbox_nzb`) ou du compte debrid qui la contient, puis place la vidéo de chaque épisode dans le dossier de saison de la série, à l'intérieur de `__magic__`. Ensuite, il demande à Sonarr de rescanner cette seule série. Rien n'est copié.

### Configurer Sonarr {#setting-up-sonarr}

1. **Root folder dans `__magic__`, à un niveau de profondeur.** Par exemple
   `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` sous macOS,
   `Z:\__magic__\tv` sous Windows). Une série dont le dossier se trouve ailleurs est
   ignorée, avec un seul avertissement dans le journal de zurg.
   Sous Windows, Sonarr doit tourner dans la session de connexion de zurg, comme Radarr.
2. **Recherche à l'ajout désactivée.** Ajoutez les séries comme vous voulez. Laissez **Start search for missing episodes** désactivé, puisque c'est zurg qui fait la recherche.
3. **Aucun indexeur ni client de téléchargement n'est nécessaire.** Si Sonarr en a, il peut récupérer des fichiers en parallèle de zurg. Désactivez donc la recherche automatique sur ses indexeurs pour les séries gérées par zurg.
4. **`library_path` correspond à l'endroit où Sonarr voit `__magic__`.** Il fonctionne exactement comme pour Radarr, y compris la vérification que Sonarr accède au dossier de téléchargement de zurg et à ses dossiers racines via un même volume. Omettez-le si Sonarr voit le point de montage à l'endroit où zurg le monte.

### Ce que zurg demande à Sonarr {#what-zurg-asks-sonarr-for}

Chaque sondage lit les épisodes manquants signalés par Sonarr. Ce sont les épisodes surveillés d'une série surveillée, déjà diffusés et sans fichier. zurg les regroupe par saison et traite chaque saison comme un seul travail.

- **Une saison entière déjà terminée peut arriver sous forme de pack.** Quand chaque épisode d'une saison manque et qu'aucun n'est encore à diffuser, un pack de saison est essayé en premier. Sinon, les épisodes manquants de la saison sont pris un par un dans les résultats de recherche de la saison. Une saison dont certains fichiers sont déjà présents n'utilise jamais de pack, car cela mettrait une deuxième copie de ces épisodes dans le dossier.
- **Un nouvel épisode est un nouveau travail.** Quand l'épisode de la semaine prochaine est diffusé, la saison réapparaît dans la liste avec cet épisode. zurg ne relance pas la recherche pour les épisodes qu'il a déjà.
- **Un nouvel épisode est recherché à nouveau dans les minutes qui suivent.** Sa sortie est généralement publiée dans l'heure suivant la diffusion, donc une recherche juste à l'heure de diffusion trouve souvent rien. Pendant six heures après la diffusion d'un épisode, zurg réessaie toutes les deux minutes, puis toutes les dix minutes jusqu'à deux jours après la diffusion. Ensuite, il espace les essais comme pour tout le reste (voir [persistance et reprise](#persistence-and-recovery)). Sur un compte debrid, la version doit aussi déjà être en cache sur ce compte, car zurg n'ajoute que ce que le compte possède.
- **Un épisode supprimé est à nouveau recherché.** Quand Sonarr liste un épisode que zurg a déjà acquis, zurg regarde dans le dossier de la saison. Si aucune vidéo de cet épisode ne s'y trouve plus, il est recherché à nouveau. Si une vidéo est là, Sonarr n'a pas encore réanalysé le dossier et rien n'est recherché.
- **Les améliorations se font fichier par fichier.** Un fichier d'épisode en dessous du cutoff de son profil de qualité est une amélioration, tant que le profil autorise les améliorations. En dessous du cutoff signifie sous la qualité de cutoff ou sous le score de format personnalisé de cutoff. La liste Cutoff Unmet de Sonarr ne compte que la qualité. Sur Sonarr 4.0.20, un fichier à la qualité de cutoff qui obtient 0 alors que le score de cutoff est 40 n'y figure pas. zurg compte les deux, comme la règle d'amélioration de Sonarr. Un fichier contenant deux épisodes compte comme une seule amélioration pour les deux.
- **Les épisodes d'une émission quotidienne sont trouvés par leur date de diffusion.** Ses sorties sont nommées par date (`The.Daily.Show.2026.11.03.Min.Jin.Lee...`), et les indexeurs ne les trouvent pas par numéro d'épisode. Donc chaque épisode manquant est aussi demandé par une recherche texte du titre de la série et de la date, `The Daily Show 2026.11.03`. L'analyseur de Sonarr reconvertit la date en épisode (S31E124), comme il le fait pour un titre numéroté par saison.
- **Les épisodes d'un anime sont trouvés par le numéro que la série leur donne.** Les sorties fansub sont numérotées à partir du premier épisode de la série (`[SubsPlease] Jujutsu Kaisen - 30` est le sixième épisode de la deuxième saison). Donc chaque épisode manquant est aussi demandé par une recherche texte du titre de la série et de ce numéro, `JUJUTSU KAISEN 30`, et un lot couvrant les numéros de la saison (`(25-47)`) est le pack de la saison. L'analyseur de Sonarr fait correspondre le numéro à l'épisode, avec ses noms de scène pour la saison (`Jujutsu Kaisen 2nd Season`, `Jujutsu Kaisen S2`). Un titre numéroté d'une de ces deux façons est donc jugé comme l'épisode qu'il est. Une sortie que Sonarr ne rattache à aucune série, par exemple une sortie nommée d'après un nom de scène qu'il ne connaît pas, est refusée comme les autres.
- **Les specials sont la saison 0.** Les specials surveillés de Sonarr sont listés comme n'importe quelle saison, demandés comme saison `00` (un indexeur à qui l'on demande la saison `0` répond une autre saison). Seule une sortie nommant `S00Exx` peut correspondre : un special nommé uniquement par son titre ne donne rien à l'analyse, dans Sonarr non plus. Ils sont placés dans le dossier défini par **Specials Folder Format** de Sonarr.

Chaque sortie candidate est soumise à l'analyseur de Sonarr lui-même (`/api/v3/parse`) et jugée selon le profil de qualité de la série. Ce que zurg accepte est ce que Sonarr aurait accepté.

- **Il doit s'agir de cette série et de cette saison.** Sonarr doit faire correspondre le titre à la même série. Un titre que Sonarr ne rattache à rien est refusé, sauf si la série n'utilise pas la numérotation scene et que la recherche de série de Sonarr trouve d'abord cette série par le nom présent dans le titre (un titre en langue étrangère, par exemple).
- **Un pack doit couvrir toute la saison.** Un pack partiel est refusé. Un pack écrit sous forme d'intervalle, comme `Season 1 E01-E07`, compte si l'intervalle couvre toute la saison. Un pack de plusieurs saisons compte pour chaque saison qu'il nomme (voir [Packs de plusieurs saisons](#packs-of-several-seasons)). Sonarr lit `S01-S05` comme la saison 1 seulement et n'indique jamais où cela se termine, donc zurg lit l'intervalle dans le titre. Sonarr doit tout de même le faire correspondre à la série et le considérer comme un pack complet de plusieurs saisons. Sa taille est jugée par rapport à la durée de chaque saison qu'il nomme.
- **Un épisode doit être cet épisode seul.** Une sortie contenant deux épisodes est refusée pour un épisode unique.
- **Le profil s'applique comme pour Radarr.** La qualité doit être autorisée. Le score du format personnalisé doit atteindre le minimum du profil. La taille doit respecter les limites de la qualité dans **Settings > Quality** pour la durée des épisodes que la sortie contient. Une amélioration doit battre le fichier actuel selon les règles de Sonarr. Les profils de Sonarr n'ont pas de réglage de langue, donc une langue ne compte que par le score d'un format personnalisé, comme dans Sonarr.

Le choix de la sortie autorisée à passer en premier se fait différemment de Radarr. Un pack de saison est essayé avant les épisodes isolés, car c'est une seule prise là où ils en sont plusieurs. Parmi les sorties que Sonarr autorise, zurg prend celle que le réglage `quality` classe en premier. Avec `best`, c'est la résolution la plus élevée puis la plus grosse, un pack étant jugé selon ce qu'il contient par épisode. Ainsi, une saison terminée avec un pack 1080p est remplie à partir de ce pack, même si la même recherche contient chaque épisode en 2160p. La passe d'amélioration remplace ensuite épisode par épisode. Un pack dépassant `max_size_gb` par épisode, ou plus que le `max_season_size_gb` que vous avez écrit pour une saison, n'est jamais candidat. `best_first: true` change les deux. Voir [Prendre d'abord le meilleur du profil](#taking-the-profiles-best-first).

Un titre qui nomme une résolution pour laquelle le profil n'a aucune qualité autorisée est refusé sans interroger Sonarr. zurg fait au plus huit appels à un même Sonarr à la fois. Si Sonarr est injoignable, rien n'est décidé. La saison attend le prochain sondage et aucune sortie n'est écartée.

### Placer les fichiers {#placing-the-files}

Une fois une release vérifiée, la vidéo de chaque épisode va dans le dossier de saison. C'est le dossier où se trouvent déjà les fichiers de la saison. Pour une saison sans fichiers encore, c'est le dossier que nomme **Season Folder Format** de Sonarr, par exemple `Season 1`. Une série configurée pour ne pas utiliser les dossiers de saison reçoit ses fichiers dans le dossier de la série.

- **Chaque épisode reçoit sa propre vidéo.** La vidéo est trouvée grâce au numéro d'épisode dans son nom, y compris dans les archives de la release. Un pack place chaque épisode pour lequel il a été pris. Les échantillons et les fichiers `.nfo` restent dans `__magic__/__all__`, et un échantillon n'est jamais placé comme épisode.
- **Un pack qui manque un épisode est refusé avant que quoi que ce soit ne bouge.** Il est mis de côté comme un post mort, puis le pack suivant ou les épisodes isolés sont essayés.
- **Un épisode isolé dont le nom de fichier ne contient rien reçoit la plus grosse vidéo de la release.** Les posts obfusqués ressemblent souvent à ça.
- **La vidéo d'un anime ou d'une émission quotidienne est placée sous la série et l'épisode.** Un rescan lit un fichier uniquement d'après son nom et ne connaît pas la numérotation scene : `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` dans le dossier de la série a été importé comme S01E08, alors que le parser de Sonarr lit le même titre comme S02E08. Donc la vidéo est placée sous le nom `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv`, ce qui s'importe correctement, avec son nom d'origine conservé après l'épisode pour que Sonarr lise toujours la qualité et le groupe. Les vidéos d'une série standard et d'un spécial gardent leur nom, qui indique déjà l'épisode.
- **Une mise à niveau remplace seulement son propre épisode.** L'ancienne vidéo de cet épisode est masquée dans le dossier de saison une fois la nouvelle en place. Les autres épisodes du dossier ne sont pas touchés. Masqué veut dire tombstoned, comme pour Radarr.
- **Sonarr rescane ensuite.** zurg indique au mount quels dossiers ont changé et demande à Sonarr de rescanner la série.
- **Un épisode manquant ne retient pas les autres.** Quand un épisode n'a encore aucune release que zurg peut prendre, les épisodes trouvés sont quand même vérifiés et placés. Sonarr est invité à rescanner tout de suite pour eux. L'épisode manquant est recherché à nouveau selon le calendrier de relance habituel.

Une source Sonarr a besoin de `__magic__` (`magic.enabled`). Sans lui, la source ne démarre pas, et le dit dans le log et sur la page d'acquisition.

**Activity** dans Sonarr reste vide, comme dans Radarr. Les épisodes ont simplement des fichiers après le rescan que zurg demande. `only_new_items` et `remove_after_grab` ne font rien pour une source Sonarr.

## Packs de plusieurs saisons {#packs-of-several-seasons}

Une saison peut être prise depuis un pack qui en contient plusieurs, comme
`Game.of.Thrones.S01-08.BDRip.1080p` ou `Breaking Bad Season 1-5`. Les indexeurs
classent un tel pack sous chaque saison qu'il couvre. Sur le flux de DMM, 72 des 691
résultats pour Breaking Bad saison 3 étaient des packs de plusieurs saisons. Pour certaines
saisons, l'un d'eux est la seule copie qu'un compte possède.

- **Le titre indique quelles saisons.** `S01-S05`, `S01-05`, `[S01-08]`, `S1-9`,
  `Seasons 1-8`, `Season 1 to 5`, `Season 1 · 2 · 3`, `Stagioni 01-05` et
  `Temporadas 1-4` sont tous lus. Un titre sans numéro de saison, comme
  `Complete Series`, n'est pas pris. Pas non plus un titre qui ne cite une saison unique
  qu'en toutes lettres, comme `Season 3 Complete`. Ceux-là n'ont jamais été lus comme des packs.
- **Seule cette saison est placée.** Un pack pris pour la saison 4 place les épisodes de la saison 4
  dans le dossier de saison. Les fichiers des autres saisons restent là où la bibliothèque les liste.
  Un pack dont les fichiers ne contiennent pas tous les épisodes de la saison est refusé avant que quoi que ce soit
  ne bouge, quel que soit son titre.
- **La taille se juge par épisode.** La taille d'un pack est divisée par le nombre de saisons qu'il nomme,
  puis par le nombre d'épisodes de la saison, et comparée à `max_size_gb`, comme le serait le même encodage
  publié épisode par épisode. Un pack de 346 Go de huit saisons de dix épisodes fait 4,3 Go par épisode.
  Le remux de la saison 2 de I Love Lucy, 31 épisodes, fait 106 GiB, soit 3,4 GiB par épisode, et passe
  sous une valeur de 40 que vous avez saisie. Lorsque la source n'indiquait pas les épisodes de la saison,
  les packs ne sont soumis à aucun plafond par épisode. Un `max_season_size_gb` que vous écrivez plafonne
  en plus chaque saison nommée par le pack ; par défaut, il n'y en a aucun.
- **La qualité passe toujours en premier.** Les packs se classent comme toute autre release : d'abord la
  résolution, puis ce qu'ils contiennent par épisode, comme le fait la page de saison de DMM. Un pack 2160p
  d'une seule saison est pris avant un pack 1080p de huit saisons. À résolution égale, le remux propre à une
  saison passe avant un pack de huit saisons, plus gros au total mais plus petit par épisode.
- **Les autres saisons de la série prennent le même pack.** Dès qu'une saison a pris un pack de plusieurs
  saisons, les autres saisons de la série essaient d'abord ce pack, avant tout pack de même résolution trouvé
  par leur propre recherche. Il est déjà sur le compte, donc il ne coûte rien. Tant que les saisons d'une série
  choisissent parmi des packs de plusieurs saisons, elles choisissent une à la fois, afin que les saisons demandées
  ensemble (une série Sonarr, toutes ses saisons lors d'une même interrogation) ne choisissent pas chacune une
  copie différente de la série. Une fois que l'une d'elles a choisi sans un tel pack, parce qu'aucun n'était sur
  le compte ou que le profil n'en autorisait aucun, les autres choisissent tout de suite. Une saison demandée une
  heure plus tard relance une recherche.

## Voir le fonctionnement {#watching-it-work}

Le lien **Acquisition** du tableau de bord ouvre `/acquisition/` sur le propre port de zurg.

Chaque source a une ligne qui indique combien de ses titres sont terminés, en cours, en attente, mis de côté et en file d'attente. Cette ligne affiche aussi le nombre de titres que zurg traite en même temps, le nombre d'appels qu'il fait à un indexeur en même temps, et le nombre de connexions aux serveurs de news autorisées pour ses comptes `nzb`. Sous cette ligne, chaque source a un tableau avec une ligne par titre. Une ligne affiche l'état du titre, ce qu'un titre en cours fait à cet instant (la recherche, le nombre de résultats jugés et acceptés jusqu'à présent, le candidat en cours d'examen, la vérification auprès des serveurs de news, le placement), ses tentatives, la release choisie avec la qualité et le score donnés par la source, l'endroit où elle a été placée, et l'heure à laquelle un titre en attente sera retenté. Un titre dont aucune release restante n'est à essayer indique la raison, avec les refus de la source comptés par règle : `14 refused by the source's own rules (title mismatch 7, quality 5, size 2)`. Les releases refusées pour leur résolution sans demander à la source sont comptées sous quality.

La page se rafraîchit toute seule toutes les cinq secondes. Le même instantané est disponible sur `/acquisition/status.json`, où cette raison figure dans le `detail` du titre. Quand aucune source n'est activée, ou que l'acquisition est configurée mais en pause, la page le signale et indique pourquoi.

Chaque film pour lequel une release est choisie génère une ligne dans le journal, pour mesurer où passe le temps :

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` correspond aux résultats renvoyés par la recherche, `local_refusals` aux résultats refusés sans demander à la source, `radarr_refusals` à ceux refusés par les règles propres de la source, `inspected` aux NZB lus, `radarr_calls` aux questions posées à la source (les NZB lus plus les refus intervenus avant eux, quand la source est Radarr). Le temps se mesure depuis le début de la recherche. Les releases refusées sans être soumises à la source ne sont journalisées une par une qu'au niveau debug.

## Vérifier un *arr qui n'utilise zurg que comme client de téléchargement {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

A Sonarr or Radarr pointed at zurg's [SABnzbd](sonarr-radarr.md) or
[qBittorrent](sonarr-radarr-torrents.md) endpoint does its own searching, and does not
need a source here. zurg still wants its API key, because three of its settings
decide whether every import is a free rename or a whole release downloaded
from the debrid account and written to zurg's disk: Remove Completed on a
qBittorrent client, the download folder and the root folders on one volume,
and root folders inside `__magic__`. With the key, zurg turns Remove Completed
on by itself (see [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
and warns about the other two. See
[One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

The easiest way to give zurg the key is the banner on the main dashboard,
described below. Or add it as a source that is switched off:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

A Radarr or Sonarr source with `enabled: false` acquires nothing. zurg never
reads its wanted list and never searches for it. With its `url` and `api_key`
set, and one of the two endpoints on, zurg only reads the \*arr's root folders,
remote path mappings and download clients, at start, every ten minutes and as
soon as the \*arr first calls one of the endpoints. It turns Remove Completed
on for the \*arr's zurg qBittorrent client when it is off, the one change zurg
makes, and reports a layout that makes imports copies. Every source with a URL
and an API key, enabled or not, is checked and corrected the same way. It is
listed on the acquisition page under **Checked, never searched for**, with
what zurg changed, the findings go to the log, and `zurg doctor` shows them as
`imports (<name>)`. `library_path` is not judged for such a source, since
nothing is placed for it. A source added to config.yml by hand is read at
start, so restart zurg after adding one that way.

zurg also notices a Sonarr or Radarr it cannot check. Both send their name in
every request to the endpoints (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), so zurg
records which ones call it and from which address. When one calls and no
source of its kind has a URL and an API key, zurg logs one warning, `zurg
doctor` reports it on its `*arr settings` line, and the main dashboard shows a
banner with a form for its URL and API key. The URL is filled in with a guess:
the address the \*arr calls from, on its default port (8989 for Sonarr, 7878
for Radarr). That address is often a container's own, which zurg may or may
not reach, so change it to whatever URL reaches the \*arr from where zurg
runs. The API key is in the \*arr under Settings, General, Security. zurg
first asks the \*arr for its status with that key, and saves nothing unless it
answers as the app it was named as. It then adds the source above to
config.yml with `enabled: false`, keeping everything else in the file as it
was, and checks it straight away, with no restart. The form shows what zurg
found and changed. The key is written to config.yml and sent to the \*arr, and
nowhere else.

The banner matches by kind, not by address: an \*arr calls zurg from inside
its container, on an address that has nothing to do with the URL zurg reaches
it on, so one Sonarr source with a key silences the banner for every Sonarr.

## Trouver les releases en double {#finding-duplicate-releases}

Une mise à niveau laisse dans votre bibliothèque la version qu'elle a remplacée. Avec `magic.allow_delete` désactivé, la suppression de l'ancien fichier par Radarr ou Sonarr le cache seulement dans `__magic__`. L'ancienne version reste donc dans `__all__` et sur votre compte. Les téléchargements venant de plusieurs indexeurs, ou un pack de saison à côté d'épisodes isolés, laissent aussi plusieurs versions de la même chose. **Manage > Duplicates** (`/manage/duplicates/`) les liste, indique laquelle Radarr ou Sonarr utilise, et vous permet de supprimer les autres. Il ne supprime jamais rien tout seul.

**La version utilisée est déterminée par les chemins, pas par les noms.** Chaque fichier que Radarr et Sonarr détiennent est désigné par un chemin sous `__magic__`. zurg sait de quelle version provient chaque fichier, car le déplacement qui l'a placé là l'a noté. La vue lit chaque fichier importé par chaque \*arr, qu'il soit surveillé ou non, au seuil ou non, et remonte chacun à sa version. Un fichier Sonarr est remonté épisode par épisode. Ainsi, un pack de saison dont Sonarr prend trois épisodes apparaît comme utilisé pour ces trois épisodes.

**Quelles versions pourraient être des copies est une estimation, et c'est indiqué comme tel.** Les versions sont regroupées avec un film, ou avec une saison, lorsque :

- un fichier d'un \*arr s'y trouve,
- l'historique du \*arr indique qu'il a importé depuis elles, ou qu'il a supprimé un fichier provenant d'elles (une mise à niveau, une suppression à la main, ou un fichier manquant sur le disque),
- zurg les a identifiées comme l'identifiant IMDb du film ou de la série,
- leur nom correspond au titre et à l'année (une année décalée d'un an, ou la seconde année de Radarr pour le film, compte toujours) ou à la série et à la saison.

Chaque version indique lequel de ces critères l'a placée dans le groupe. Une saison ne forme un groupe que si des versions contiennent le même épisode : soixante versions d'un seul épisode chacune pour une même saison, ce sont soixante épisodes différents. Un groupe de saison liste les épisodes que plusieurs versions contiennent, la version qui contient chacun, celle dans laquelle se trouve le fichier de Sonarr, et le nombre d'épisodes que chaque version contient et que rien d'autre du groupe ne contient. Aucune version n'est choisie comme gagnante. Les versions qu'aucun élément Radarr ou Sonarr ne correspond se trouvent sous **Name matches only**, regroupées par leurs noms et leurs identifiants IMDb.

**Chaque version est In use, No reference found ou Unknown.**

| État | Signification |
|---|---|
| In use | Un fichier que Radarr ou Sonarr détient en ce moment se trouve dans cette version. Elle ne peut pas être sélectionnée. |
| No reference found | Chaque Radarr et Sonarr configuré a été lu en entier, et aucun de leurs fichiers ne se trouve dans cette version. Plex, Jellyfin et les autres clients qui lisent le montage ne sont pas visibles ici, donc ce n'est pas la preuve que rien ne la lit. |
| Unknown | zurg ne peut pas le dire. Chaque version est Unknown tant qu'un \*arr ne peut pas être lu, tant que la bibliothèque est encore en cours de chargement, ou avec `__magic__` désactivé. Une version est aussi Unknown lorsqu'un fichier \*arr pour le même film ou épisode ne peut être rattaché à aucune version, ou lorsque l'historique du \*arr montre qu'un fichier de cette version a disparu du disque et que le film ou l'épisode n'a plus eu de fichier depuis. |

**La qualité est affichée selon les termes du profil.** Pour une version utilisée par un \*arr, c'est la note propre du \*arr pour le fichier. Pour une version qu'il a importée auparavant, c'est la note qu'il lui avait donnée à l'époque. Sinon, elle est lue dans le nom de la version, et c'est indiqué. Chaque note est placée dans le profil de qualité de l'élément, par exemple « rank 15 of 17 in 4K or best available (cutoff at 17) ».

**La suppression relit d'abord les fichiers.** Sélectionnez des versions, puis choisissez **Check again and delete**. zurg relit les fichiers actuels de chaque \*arr, et seulement ensuite propose la suppression. Une version passée en utilisation depuis le chargement de la page est exclue, et une version Unknown n'est supprimée que si vous la cochez à nouveau dans cette boîte de dialogue. La suppression elle-même est la suppression groupée de la page de gestion, qui retire chaque copie de la version de chaque compte qui la détient.

**Quand elle lit.** L'ouverture de la page pour la première fois lit chaque Radarr et Sonarr sous `acquisition.sources`, y compris l'historique des imports et des suppressions. Lire l'historique d'une grande bibliothèque peut prendre une minute. Ensuite, la page affiche ce qui a été lu en dernier et quand, jusqu'à ce que vous choisissiez **Read Radarr and Sonarr again**. Une source avec `enabled: false` est tout de même lue : désactiver l'acquisition ne change pas ce que l'\*arr détient. La page affiche les compteurs de chaque source : fichiers lus, fichiers remontés à une version, fichiers situés sur un chemin hors de son `library_path`, et fichiers à l'intérieur de `__magic__` mais ne menant à rien. Si aucun fichier d'une source ne remonte à une version, vérifiez son `library_path`.

Le même rapport se trouve à `/manage/duplicates/report.json`. `POST /manage/duplicates/check` avec `{"hashes": [...]}` relit les \*arr et renvoie l'état de chaque version.

## Newznab et Torznab {#newznab-and-torznab}

Un indexeur indique son type avec `type`. S'il est absent, la valeur est `newznab`, ce qui correspond à toutes les entrées écrites avant que cette option n'existe. La requête est identique pour les deux types, mais la réponse ne l'est pas. Un résultat Newznab est un NZB : il est récupéré et écrit dans `nzbs/` pour le backend Usenet. Un résultat Torznab est un info hash, transmis à un compte debrid. Un résultat Torznab qui ne contient ni magnet ni attribut `infohash` est ignoré : zurg ne télécharge jamais de `.torrent`, donc un résultat accessible uniquement de cette façon n'est pas quelque chose sur quoi il peut agir.

**Un torrent n'est jamais ajouté qu'à un compte qui le possède déjà.** Chaque compte qui accepte les ajouts reçoit le hash, sauf qu'un compte Real-Debrid est ignoré pour un nom de version qu'il refuse catégoriquement, car les caches sont indépendants et le fait qu'un compte ait purgé une version ne dit rien du suivant. Le premier qui possède déjà le torrent le prend. Un échec partout est un candidat ordinaire raté : le parcours descend alors le classement jusqu'à la version suivante, qui peut être un autre torrent ou un NZB.

Sur TorBox et Debrid-Link, un échec n'ajoute rien. Sur AllDebrid et Offcloud, il est supprimé immédiatement. Real-Debrid et Premiumize reçoivent le torrent ajouté et le surveillent pendant 20 secondes au maximum. Un contenu en cache est prêt en une ou deux secondes. Tout ce qui télécharge encore après ce délai est retiré. Ainsi, aucun téléchargement n'est jamais laissé en cours sur le compte. Un échec n'est toutefois pas tout à fait sans coût : il peut quand même compter dans la limite d'ajouts du compte. Sur TorBox, il utilise l'un des 60 ajouts non mis en cache autorisés par heure.

Le compte marqué `watchlist: true` reçoit le torrent en premier. Les autres suivent dans l'ordre de votre liste `providers:`. Un compte marqué `add_torrents: false` ne reçoit jamais de torrent.

`prefer` détermine vers quel type on se tourne en premier lorsque les deux peuvent satisfaire une cible à la même résolution. La résolution passe d'abord : un torrent 2160p déjà possédé par un compte est pris avant un NZB 1080p, quelle que soit la valeur de `prefer`. `usenet` est la valeur par défaut, parce qu'un téléchargement Usenet coûte un téléchargement, alors qu'un torrent consomme l'un des emplacements d'ajout du compte. `torrents` inverse cet ordre, et `best` supprime la distinction et prend ce que le classement place en premier, c'est-à-dire la version la plus volumineuse au sein d'une même résolution.

Un film essaie jusqu'à trois torrents par tentative. Chacun coûte un ajout. Jusqu'à 24 de ses NZB sont inspectés individuellement, comme le décrit [choisir la version d'un film](#choosing-a-movies-release). Avec `usenet`, les NZB d'une résolution sont essayés avant ses torrents. Avec `torrents`, ses torrents passent en premier. Avec `best`, chaque torrent attend son tour dans le classement. Les NZB d'une résolution sont essayés ensemble à la place de leur meilleur élément. Avec une source Radarr, les NZB de toutes les résolutions sont essayés ensemble à la place du meilleur élément, du moins cher au plus cher, comme l'explique cette section. Un pack de saison essaie trois versions par tentative, quel que soit leur type. Il en va de même pour chaque épisode isolé.

La vérification sur laquelle attend un téléchargement dépend de la source. Une version Usenet est soumise aux serveurs de news, seul moyen de savoir si le message existe toujours. Un compte `torbox_nzb` n'a pas de serveurs de news à interroger ; un téléchargement y est vérifié selon que TorBox a bien récupéré le NZB. Un torrent n'a été ajouté que parce que le compte indiquait déjà posséder le contenu. Il reste donc à établir que la version est bien arrivée dans la bibliothèque avec des fichiers ; c'est ce que vérifie la contrôle, et une version que le compte liste comme vide est écartée comme un message mort.

Une installation sans compte NZB (`nzb` ou `torbox_nzb`) peut tout de même faire l'acquisition uniquement à partir d'indexeurs Torznab. Ses indexeurs Newznab n'y sont pas interrogés, car rien sur cette installation ne peut lire un NZB. Le journal le signale une seule fois pour chacun d'eux. Une installation sans compte qui accepte les torrents n'interroge pas non plus ses indexeurs Torznab, pour la même raison. Dans les deux cas, une version d'un type pour lequel l'installation n'a nulle part où la mettre n'est jamais un candidat : elle ne consomme donc aucune des versions essayées lors d'une tentative, et une source comme Radarr n'est jamais interrogée à son sujet.

### Limites des indexeurs et clés refusées {#indexer-limits-and-refused-keys}

**zurg respecte la limite de DMM au lieu de la dépasser.** DMM autorise la clé d'un sponsor à 20 recherches par minute sur l'ensemble de ses flux torrent, donc zurg envoie à DMM au plus une recherche toutes les trois secondes. Une recherche au-delà attend son tour, et attendre n'est pas une recherche ratée. Une recherche dont le tour arriverait après la fin de la tentative de son titre, ou plus de deux minutes plus tard, n'est pas faite : le titre continue avec ce que les autres indexeurs ont trouvé.

**Un indexeur qui répond 429 ou 503 est laissé tranquille pendant le temps qu'il demande.** Chaque recherche, téléchargement NZB et vérification des capacités attend son `Retry-After`, jusqu'à deux minutes, y compris les requêtes qui attendent déjà leur tour. Un indexeur qui demande plus longtemps n'est pas sollicité avant ce délai.

**Plusieurs zurg sur une même clé DMM se partagent ses 20 recherches.** Chacun respecte le budget entier, donc deux ou trois zurg sur une même clé dépassent quand même la limite de DMM, et chaque refus met en pause les recherches DMM de ce zurg pendant une minute. Un titre peut alors attendre plus longtemps sa recherche et son téléchargement.

**Une clé refusée est laissée tranquille pendant une heure.** Un indexeur qui répond l'erreur 100 (mauvaise clé) ou 101 (compte suspendu, ce que DMM répond quand le parrainage a expiré) n'est plus sollicité pendant une heure, pour les recherches comme pour les téléchargements NZB. Le journal le signale une seule fois, par exemple `DMM torrents refused the API key: check dmm_api_key`, et la page d'acquisition le liste sous **Indexers not asked now**. Une clé que tu modifies dans `config.yml` est sollicitée tout de suite. Toute autre erreur ne concerne que cette recherche.

## Choisir la release d'un film {#choosing-a-movies-release}

Les candidats Usenet d'un film sont essayés selon ce qu'il coûte de les vérifier, et pas seulement selon leur qualité. Un post qui contient une seule vidéo nommée coûte deux lectures d'articles à zurg et est en général complet ; un jeu d'archives de quarante volumes coûte une passe de dimensionnement et une lecture aux deux bouts de chaque volume, et environ deux tiers des jeux remux multi-volumes sur les indexeurs ont disparu. Le nombre de `files` propre à l'indexeur prédit la forme du post, donc les candidats sont triés par ce nombre : dix fichiers ou moins, puis jusqu'à trente, puis plus, puis inconnu, et par le nombre à l'intérieur de chaque tranche. Entre posts de coût égal, quand une source comme Radarr juge les releases selon un profil à elle, un titre qui mentionne WEB-DL ou WEBRip passe en premier, puis Blu-ray, puis le reste, et le post le plus gros en premier dans chaque groupe. Le classement de la source n'est pas utilisé ici, parce qu'on ne le connaît qu'en le demandant à la source, et zurg ne lui demande son avis sur une release que juste avant de l'inspecter. Sans source, c'est le classement par qualité, puis la taille, qui décide. Quand aucune source ne juge les candidats, la résolution demandée par le réglage `quality` passe avant le coût, donc une watchlist réglée sur `best` obtient quand même la meilleure résolution disponible, avec le post le moins cher en premier dans cette résolution. Les résultats dont le titre correspond à une partie d'un post découpé (`[1/9] "Movie.part1.rar"`) ne sont jamais candidats, et parmi deux posts portant le même nom, seul celui qui a le moins de fichiers est gardé, parce que la bibliothèque ne peut en contenir qu'un.

Jusqu'à 24 candidats sont ensuite inspectés : chaque NZB est récupéré et lu avec le parseur propre à zurg. Un post avec au plus deux fichiers de contenu, dont l'un est une vidéo nommée `.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov` ou `.ts` d'au moins 500 MB, est un post direct ; les volumes PAR2 et les fichiers annexes comme `.nfo`, `.sfv`, `.srr`, `.nzb`, les images, `.txt`, `.url` et `.exe` ne comptent pas comme contenu. Le premier post direct est sauvegardé tout de suite. Les posts d'archives sont mis de côté jusqu'à ce que les posts directs visibles soient épuisés, puis essayés en commençant par ceux qui ont le moins de volumes, via une barrière qui ne laisse pas plus de six releases d'archives attendre sur les serveurs de news en même temps. Un post qui ne contient que des données de réparation et des fichiers annexes n'est jamais sauvegardé. Les NZB inspectés sont mémorisés en RAM, donc quand une release sauvegardée s'avère morte et que le titre est essayé à nouveau, on passe au candidat suivant sans récupérer une seconde fois les précédents. Les recherches et les téléchargements de NZB partagent une même limite de requêtes en cours par indexeur, et un indexeur qui répond `429` ou `503` est relancé après une pause, en respectant son `Retry-After`. Le tableau de bord affiche chaque étape : la recherche, le candidat en cours d'inspection, et ce qui a été sauvegardé. Les séries utilisent le parcours précédent : les trois releases les mieux classées qui ne sont pas mises de côté. Quand la source juge les releases, comme le fait Sonarr, chacune lui est soumise d'abord, et une release qu'elle refuse ne compte pas dans les trois. `best_first` change l'ordre des deux parcours, comme le décrit la section suivante.

## Prendre d'abord le meilleur du profil {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

Désactivé par défaut. Activé, il fait en sorte que la première récupération d'une source Radarr ou Sonarr suive l'ordre de préférence du profil de qualité, au lieu du coût de vérification d'une release. La watchlist Plex et Seerr n'ont pas de profil et ne sont pas concernées. La page d'acquisition indique quand c'est activé.

- **La meilleure résolution du profil passe en premier.** Chaque release est placée selon la résolution indiquée dans son titre. Sa place correspond à la meilleure qualité que le profil autorise dans cette résolution. zurg lit cela dans le profil qu'il possède déjà et ne demande rien de plus à Radarr et Sonarr. WEB-DL, Blu-ray et remux d'une même résolution partagent une place. Au sein d'une place, un film prend toujours la release la moins coûteuse à vérifier. Une série prend celle que `quality` classe en premier. Un titre qui ne mentionne aucune résolution passe en dernier.
- **Le cutoff compte comme le sommet.** Tant que le profil autorise les mises à niveau, chaque qualité au niveau du cutoff ou au-dessus compte comme le cutoff. Le passage de mise à niveau ne remplacerait jamais aucune d'elles. Un profil qui monte jusqu'à WEB 1080p ne gagne rien à « meilleure d'abord », même s'il autorise aussi le 2160p. Un profil qui n'autorise pas les mises à niveau garde tout son ordre. Son premier fichier est celui qu'il conserve.
- **Il redescend le profil.** Une release dont le NZB ne peut pas être récupéré ou lu est ignorée. Celle que les serveurs de news refusent est mise de côté comme avant. La release suivante dans l'ordre du profil est essayée. Une tentative ne lit toujours pas plus de 24 NZB au total, quelle que soit leur place.
- **Elle passe avant la préférence Usenet ou torrent.** Un torrent qu'un compte possède déjà est pris avant un NZB que le profil place plus bas. `prefer` décide toujours entre un NZB et un torrent de même place.
- **Un season pack doit être aussi bon que les épisodes isolés.** Un pack classé en dessous d'un épisode isolé issu de la même recherche est ignoré. Les épisodes sont alors pris un par un. Sonarr fait le même choix. Seule cette recherche est comparée. Un épisode n'est pas recherché à nouveau seul au cas où une meilleure release de celui-ci existerait.

Ça a un coût. Le haut d'un profil 2160p est surtout composé de remux et de coffrets Blu-ray de quarante volumes ou plus, plutôt que de fichiers vidéo uniques. Un tel coffret prend plus de temps à vérifier. Il est plus souvent absent des serveurs de news. Il attend aussi une place à la porte d'archive. Donc le premier fichier arrive généralement plus tard. Un titre dont les meilleures releases sont toutes absentes les a toutes récupérées, vérifiées et mises de côté avant que zurg ne descende dans le profil. Une saison prise en épisodes isolés représente plusieurs récupérations là où un pack n'en aurait fait qu'une. Ce qu'on économise, c'est la deuxième récupération. Un premier fichier au niveau du cutoff n'est jamais mis à niveau.

## Ce que l'acquisition fait à la liste de la source {#what-acquiring-does-to-the-sources-own-list}

Une liste de suivi Plex est une liste qu'une personne a constituée, et c'est la seule trace qu'elle voulait un titre : Plex ne garde aucun historique d'une entrée supprimée. Deux réglages déterminent ce que zurg peut faire avec elle. Les deux s'appliquent aux sources `plex_watchlist` ; les sources Seerr et Radarr ne possèdent aucune liste dans laquelle zurg écrit, donc ces réglages n'ont aucun effet là-dessus.

`remove_after_grab` (par défaut `true`) retire un titre acquis de la liste de suivi une fois que la release correspondante a été vérifiée. C'est ce que la fonctionnalité a toujours fait : la liste de suivi est lue comme une file d'attente de choses à récupérer, et un titre que zurg a obtenu est terminé. Si tu le mets à `false`, la liste de suivi reste une vraie liste de suivi, une liste durable à parcourir, que zurg satisfait en arrière-plan sans la modifier. Garder un titre dans la liste ne coûte rien à revérifier : le reçu le couvre déjà, donc aucun indexeur n'est interrogé à nouveau à son sujet.

Un titre pour lequel zurg n'a rien obtenu reste dans la liste de suivi, quelle que soit la valeur de ce réglage. Quand chaque release qui le règle était déjà dans la bibliothèque, que ce soit ta propre copie ou une autre demande, rien n'a été récupéré ni ajouté, et le supprimer ne ferait que modifier ta liste. Ces releases sont tout de même vérifiées, et le titre compte comme terminé, donc il n'est pas recherché de nouveau tant qu'il reste dans la liste. Si tu le retires puis l'ajoutes à nouveau, il redevient présent. Une série dont zurg a récupéré n'importe quelle saison ou n'importe quel épisode est une série qu'il a obtenue, et elle part comme avant.

`only_new_items` (par défaut `true`) adopte ce que la liste contient déjà la toute première fois qu'une source s'exécute, et n'agit que sur ce qui y est ajouté ensuite. Activer la fonctionnalité doit commencer à surveiller une liste, et non passer une soirée à traiter tout ce qu'elle contient. Mets-le à `false` si tu veux traiter la liste existante comme une liste d'attente à rattraper.

Il ne s'applique **qu'une seule fois, à la toute première exécution d'une source**. Une source qui a déjà une file d'attente tourne depuis un moment, et c'est cette file, et non ce réglage, qui enregistre ce qui a été fait et ce qui ne l'a pas été. L'activer plus tard ne supprime donc jamais une liste d'attente déjà en cours. Un titre adopté reste adopté tant qu'il reste dans la liste ; si tu le retires puis l'ajoutes à nouveau, c'est une nouvelle demande classique.

## Vérifier une prise {#verifying-a-grab}

Un NZB enregistré n'est pas une release. Le fait que l'indexeur réponde, que la réponse soit lue comme un NZB et que le fichier arrive dans `nzbs/` ne dit rien sur le post lui-même : ce sont des faits sur l'indexeur. Donc chaque NZB acquis est soumis aux comptes news configurés avant que le moteur n'accuse réception de la requête. Les seize premiers articles et le dernier de chaque fichier de contenu sont interrogés avec `STAT`. Le premier article de chaque fichier, ainsi que quelques autres d'une release de peu de fichiers, est téléchargé en entier (soixante-quatre au maximum), car un serveur news peut répondre `STAT` pour un article qu'il a retiré. Un article que `STAT` refuse est aussi téléchargé en entier avant d'être compté comme perdu, car un serveur news peut aussi refuser `STAT` pour un article qu'il sert encore (NewsDemon l'a fait le 2026-10-21). Seize de ces articles au maximum par release. C'est le même parcours que fait `/api?mode=addfile` pour Sonarr et Radarr. Trois réponses possibles, et les garder séparées est tout l'intérêt :

- **Articles perdus.** Le grab ne compte pas. Le reçu est rouvert, donc la cible est de nouveau recherchée, et la release est enregistrée comme morte pendant 30 jours. Ainsi, la tentative suivante prend le candidat suivant au lieu de se contenter de celui déjà dans la bibliothèque. Une release de cette liste n'est pas un candidat : elle n'est pas téléchargée, et elle ne compte pas parmi les candidats qu'une tentative essaie. Une série de posts morts en haut d'un classement est donc parcourue, au lieu de rendre tout ce qui se trouve dessous inaccessible. Un pack de saison mort remet toute sa saison en recherche ; les épisodes isolés sont pris à la place. Un NZB acquis et enregistré par le système est ensuite supprimé du dossier de surveillance, pour qu'un redémarrage ne le recharge pas et ne le revérifie pas avant l'ouverture de la bibliothèque. Un NZB qui était déjà dans le dossier de surveillance ou dans la bibliothèque, et celui dont Sonarr ou Radarr a fait l'import, reste à sa place.
- **Les comptes n'ont pas pu être interrogés.** Un pool hors ligne, un compte bridé, ou le cas courant d'une bibliothèque qui n'a pas encore listé le nouveau NZB. Rien n'a été établi, donc rien n'est décidé : la requête est réexaminée dans vingt secondes, puis après 40 et 80 secondes, puis toutes les deux minutes, et cette attente ne consomme aucune tentative. Une vérification qui a simplement manqué de temps n'est pas dans ce cas : elle est relancée tout de suite avec son temps complet, jusqu'à trois fois, avant qu'une attente ne commence. Ce temps est de cinq minutes, ou plus pour une release avec beaucoup de fichiers sur un compte avec peu de connexions. zurg le calcule à partir de ces deux valeurs, de la vérification la plus lente mesurée jusqu'ici et des six vérifications qu'il lance en même temps, puis il le double. Une release de 90 volumes sur quatre connexions obtient environ 53 minutes, alors que cinq minutes suffisaient pas à chaque tentative jusqu'à ce que la release soit écartée sans avoir été vérifiée. Vingt vérifications sur deux heures qui n'établissent rien écartent la release comme une release morte, et la tentative suivante en essaie une autre. La requête n'est jamais acquittée sur une release que personne n'a pu vérifier.
- **La release est là.** Le reçu libère ce qu'il retenait, et l'accusé de réception part.

La vérification attend que zurg ait fini d'apprendre les tailles exactes des fichiers de la release, ou qu'il ait renoncé à les connaître. C'est le même moment où l'endpoint SABnzbd vérifie. Apprendre les tailles lit le premier article de chaque fichier, et la vérification le lit aussi. Lancer les deux en même temps n'a donc fait que ralentir les deux. Sur une liste de 99 films, vérifier chaque release dès qu'elle était listée a fait arriver le dernier fichier dans le dossier de Radarr après près de neuf minutes. Une vérification qui attend encore les tailles quand son temps est écoulé est relancée tout de suite, comme une vérification qui a manqué de temps. Une release dont les tailles sont encore en cours de calcul après 30 minutes est quand même vérifiée. Six releases au maximum sont vérifiées en même temps, et les autres attendent leur tour.

La vérification se contente de lire. Elle ne déplace aucun corps d'article dans le cache et n'enregistre aucun article mort, donc elle ne peut pas faire taire un fichier qui se lit. Quand la passe de calcul des tailles vient de récupérer le premier article d'un fichier, la vérification lit cette copie au lieu de la télécharger une seconde fois.

Une installation sans compte NZB (`nzb` ou `torbox_nzb`) n'a rien pour vérifier un grab NZB. L'acquisition tourne quand même dans ce cas, si un compte debrid accepte les torrents. Chaque torrent est vérifié selon qu'il arrive dans la bibliothèque avec des fichiers, comme le décrit [Newznab et Torznab](#newznab-and-torznab). Il doit aussi contenir quelque chose à lire : une vidéo, un fichier audio, ou une archive que zurg peut diffuser (RAR, 7z, zip ou parties numérotées). Un torrent qui ne contient qu'un programme, une image disque ou du texte est un faux, ce que les nouveaux épisodes attirent dans les premières heures après leur diffusion. Il est écarté comme un post mort, et la release suivante est essayée tout de suite. Si zurg l'a ajouté au compte pour cette requête, il est de nouveau supprimé du compte. Un torrent que le compte contenait déjà reste à sa place. Un grab NZB n'est jamais acquitté sans compte NZB, car rien ne pourrait le vérifier ni le lire. Un grab resté en attente depuis avant la suppression du dernier compte NZB est écarté comme un post mort, et la release suivante est essayée.

## Persistance et reprise {#persistence-and-recovery}

`data/acquisition.json` stocke les IDs de source et de demande, les tentatives, les délais de nouvelle tentative, le travail en cours et les reçus pour chaque acquisition, y compris les épisodes. Il enregistre aussi, pour chaque source, qu'un premier instantané a été adopté, afin que `only_new_items` soit décidé une seule fois plutôt qu'à chaque redémarrage.

Les cibles et éditions de médias correspondantes réutilisent les reçus entre les sources. Les noms de fichiers des versions se dédupliquent aussi contre la bibliothèque et les NZB sauvegardés. Un reçu contient aussi les grabs pour lesquels il attend encore une réponse des serveurs de news, et le registre garde les versions déjà jugées mortes, pour qu'un redémarrage pendant l'attente ne valide ni un grab non vérifié ni ne redonne une version morte au classement.

Un reçu n'est pas considéré comme valable pour toujours : avant qu'un titre soit compté comme détenu, zurg vérifie que ce qui l'a validé est toujours là, soit la vidéo placée dans un dossier Radarr ou Sonarr, soit, pour un titre DMM wanted, de la watchlist Plex ou de Seerr, la version elle-même dans la bibliothèque. Si elle a été supprimée depuis, elle est recherchée à nouveau, même si le titre est toujours listé et que la tâche est terminée, et une version supprimée depuis la page Manage n'est pas reprise.

Chaque release sauvegardée est écrite sur le disque immédiatement. Les compteurs de tentatives et les heures de nouvelle tentative sont écrits dans la minute, donc un crash peut faire perdre jusqu'à une minute de ces données, mais jamais un grab.
Les écritures vident un fichier temporaire, remplacent le registre et vident le dossier parent là où c'est pris en charge. Les NZB écrits avant un crash sont réutilisés même si la dernière écriture du registre n'a pas abouti. Une fois l'acquisition enregistrée, les nouvelles tentatives de suppression Plex n'acquièrent plus le titre une seconde fois.

Les échecs sont retentés après 5, 10 et 15 minutes, puis une heure, puis six heures. Ensuite, un titre attend la moitié de la durée pendant laquelle il échoue, donc les délais s'allongent : environ une demi-journée après un jour d'échecs, deux jours après quatre, une semaine au maximum, à un quart près, pour que les titres qui ont échoué ensemble ne retentent pas ensemble. Une tentative qui atteint ses cinq minutes sans rien trouver compte aussi comme un échec. Une tentative qui ne trouve rien pendant qu'un de tes indexeurs ne peut pas être interrogé, parce qu'il a demandé à être laissé tranquille jusqu'à une heure située à un jour au plus (un `Retry-After`), ne compte pas : le titre est réessayé après cette heure, et au plus autant de temps après. Ainsi, une file de titres ne demande pas à l'indexeur tout en même temps. Un indexeur en pause de dix minutes signifie une nouvelle tentative dans les vingt. Cela arrive au plus trois fois de suite, puis la tentative compte normalement. Un indexeur qui ne donne aucune heure, par exemple un qui répond 410 Gone ou refuse sa clé, n'est pas attendu. Un titre qui échoue depuis deux semaines, avec au moins huit tentatives, est **parked** : zurg arrête de demander aux indexeurs à son sujet. Il reste sur la page Acquisition comme parked, avec la durée et la raison de l'échec, et le journal l'indique une fois. **Resume** sur cette page, pour un titre ou pour tous les titres parked d'une source, le relance depuis la première courte attente. Une source qui arrête de lister un titre puis le relist a redemandé ce titre, donc cela le relance aussi. Un grab confirmé par les serveurs de news relance les deux semaines d'un titre, si bien qu'une saison qui trouve encore des épisodes n'est jamais parked. Une mise à niveau non plus, quelle que soit la source : sa meilleure version peut sortir des mois plus tard et le titre reste listé, donc il garde ses nouvelles tentatives espacées d'une semaine au maximum. Rien de ta liste DMM wanted non plus, pour la même raison : un film qui n'est pas encore sorti, ou un vieux film que personne n'a posté, reste wanted jusqu'à ce qu'il soit récupéré ou que tu le retires. Les compteurs et les délais survivent aux redémarrages, y compris aux longs arrêts.

Une file qui échoue indéfiniment coûte cher d'une façon que la liste des titres ne montre pas. Sur une installation, des milliers de titres Radarr et Sonarr pour lesquels rien n'a été trouvé, réessayés toutes les six heures sans fin, ont fait passer un indexeur de quelques centaines de requêtes par jour à des dizaines de milliers, et l'indexeur a suspendu le compte. La plupart étaient des films sans version Usenet, et des mises à niveau dont toutes les versions autorisées par le profil avaient déjà été refusées. Les demandes Seerr ouvertes restent surveillées. Les éléments Plex ne quittent la watchlist qu'une fois toutes les saisons prévues acquises *et* vérifiées (un NZB contre les serveurs de news ou, sur un compte `torbox_nzb`, selon que TorBox l'a bien récupéré ; un torrent en atteignant la bibliothèque avec quelque chose à lire), seulement lorsque `remove_after_grab` l'autorise, et seulement quand zurg a récupéré quelque chose pour eux. Son repli sur les épisodes isolés reste limité aux épisodes trouvés dans les résultats des indexeurs.

Une source indisponible met en pause son propre travail. Une écriture d'état échouée met en pause toute autre acquisition jusqu'à ce que la sauvegarde réussisse. Un registre illisible ou non pris en charge met en pause l'acquisition et préserve le fichier ; répare-le ou restaure-le, puis redémarre zurg. Les autres services de zurg continuent de tourner.

L'ancien `data/plex-watchlist.json` est importé une seule fois avec son historique, ses nouvelles tentatives et ses tentatives, seuls ceux qui attendent la suppression Plex restant intacts. Le fichier d'origine est conservé. Les deux registres sont inclus dans les sauvegardes normales, sans `--include-caches`. Conserve `data/` et `nzbs/` lors du remplacement des conteneurs.

## Ajouter un autre adaptateur {#adding-another-adapter}

Implémenter `acquisition.Source` dans son propre package :

1. `ID()` identifie l'instance entre les redémarrages.
2. `List(ctx)` renvoie un instantané complet de références `Item`. Faire échouer l'instantané en cas d'erreur de pagination. Ne persister que les métadonnées, jamais les identifiants ni les objets utilisateur complets de l'API.
3. `Resolve(ctx, item)` revalide l'élément et renvoie des cibles normalisées : film, saison ou épisode. `Gone` annule le travail non voulu. `Follow` garde une demande ouverte surveillée après l'acquisition des cibles actuelles.
4. `Complete(ctx, item)` acquitte une acquisition ponctuelle. Il doit tolérer les appels répétés après un crash. Une liste en lecture seule peut utiliser un no-op. Le moteur ne l'appelle qu'une fois que chaque grab lié à l'élément a répondu, donc un adaptateur n'a jamais à vérifier une release lui-même, et ne doit pas considérer le fait d'être appelé comme une preuve de quoi que ce soit au-delà de cela.

Une source qui a son propre profil de qualité peut aussi implémenter `acquisition.Assessor`, en jugeant chaque release candidate selon ses propres règles. Les adaptateurs Radarr et Sonarr le font, via leurs propres analyseurs.

Enregistrer son type de configuration et sa factory dans le service d'acquisition. La file, la persistance, les retries et l'exécuteur n'ont besoin d'aucune branche spécifique à la source. Trakt, MDBList et Simkl peuvent correspondre à ce contrat, mais ne sont pas encore implémentés.
