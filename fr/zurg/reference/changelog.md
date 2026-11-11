# Journal des modifications {#changelog}

## zurg trouve les animés, les émissions quotidiennes et les spéciaux pour Sonarr {#zurg-finds-anime-daily-shows-and-specials-for-sonarr}

Une source Sonarr sautait auparavant une série quotidienne, une série d'animation et les spéciaux d'une série, avec un avertissement pour chacune. Maintenant, les épisodes manquants d'une émission quotidienne sont aussi demandés par leur date de diffusion (`The Daily Show 2026.11.03`), ceux d'un anime par le numéro que la série leur donne (`Jujutsu Kaisen 30` correspond au sixième épisode de la deuxième saison), et les spéciaux comme saison `00`, en plus de la recherche habituelle par saison et épisode. L'analyseur propre à Sonarr indique quel épisode correspond à chaque release, comme pour n'importe quelle série, et le profil de qualité la juge comme avant. Une vidéo placée pour un anime ou une émission quotidienne est nommée `JUJUTSU KAISEN - S02E06 - <the release's own name>`, car le rescan de Sonarr lit un fichier uniquement d'après son nom et classerait `2nd Season - 06` en saison 1 ; les vidéos d'une série standard et d'un spécial gardent leur nom. Les spéciaux vont dans le dossier nommé par **Specials Folder Format** dans Sonarr, et seule une release nommant `S00Exx` peut correspondre à l'un d'eux. Voir [Ce que zurg demande à Sonarr](../guides/acquisition.md#what-zurg-asks-sonarr-for).

## Garde un film souhaité en 1080p et en 4K {#keep-a-wanted-film-at-1080p-and-at-4k}

`quality: [1080p, 4k]` dans le bloc `acquisition:` garde deux copies de chaque
film sur votre liste de souhaits DMM, pour qu'un téléviseur 1080p puisse en lire
une sans transcoder le fichier 4K. Chaque copie prend la meilleure version
à sa résolution ou en dessous, et passe toute seule à une version supérieure
jusqu'à sa limite. Tant qu'aucune version meilleure que 1080p n'est disponible,
les deux se partagent une seule copie. Les séries, et toutes les autres sources,
gardent une seule copie. Voir [une copie pour chaque résolution](../guides/acquisition.md#a-copy-at-each-of-several-resolutions).

## La mise à jour de zurg fonctionne après l'installation en une ligne {#zurg-update-works-after-the-one-line-install}

Les installeurs en une ligne vous connectent à GitHub via la GitHub CLI. Ils l'ont téléchargée pour cela, puis l'ont supprimée une fois terminé. `zurg update` cherchait alors la GitHub CLI, ne la trouvait pas, et s'arrêtait avec « no GitHub credential found », alors que votre connexion était toujours enregistrée. La GitHub CLI fournie avec Ubuntu est trop ancienne pour transmettre la connexion. La mise à jour s'arrêtait de la même façon là aussi.

`zurg update` utilise maintenant aussi la GitHub CLI que les installeurs gardent dans `bin`, à côté de zurg. Une connexion enregistrée par la GitHub CLI sans trousseau (keyring) fonctionne désormais même lorsque la CLI elle-même a disparu. Si elle ne trouve toujours rien, elle affiche la seule commande qui corrige le problème. Lancez une fois la mise à jour de l'installeur, et chaque `zurg update` suivant vous connectera tout seul.

## Plusieurs anciens liens Real-Debrid qui échouent en même temps ne sont plus appelés une panne {#many-old-real-debrid-links-failing-at-once-is-no-longer-called-an-outage}

Les liens Real-Debrid cessent de fonctionner quelques mois après leur création, donc les releases ajoutées à peu près à la même période cessent de lire à peu près en même temps. Quand plus de cinq d'entre elles échouaient lors d'un même passage de réparation, zurg affichait « suspected provider-wide outage » et retenait la réparation de toutes sauf cinq. Un gros lot restait donc cassé bien plus longtemps et donnait l'impression que Real-Debrid était en panne. zurg demande désormais d'abord à Real-Debrid une release sur le même compte qui lit encore. Si elle lit, les liens qui échouent sont simplement anciens et chaque release est réparée normalement. zurg ne considère une panne et n'attend que lorsque Real-Debrid refuse aussi les liens qui fonctionnent.

## Les liens de session Emby du tableau de bord ouvrent le tableau de bord d'Emby {#the-dashboards-emby-session-links-open-embys-dashboard}

Les liens « sessions actives » et « transcodages » du panneau Emby du tableau de bord ouvraient `/web/#/dashboard`, l'adresse de Jellyfin pour cette page, et Emby restait bloqué sur son écran de démarrage sans fin. Les deux liens ouvrent maintenant `/web/index.html#!/dashboard`, l'adresse qu'Emby utilise lui-même. Les liens du panneau Jellyfin n'ont pas changé.

## Un .nfo manquant n'envoie plus une release Usenet à repair {#a-missing-nfo-no-longer-sends-a-usenet-release-to-repair}

Les anciens posts Usenet perdent souvent leur .nfo en premier, alors que toutes les vidéos et toutes les parties d'archives sont encore là. zurg considérait cela comme un dommage pour toute la release. Il lançait une réparation à chaque fois qu'il tombait sur un de ces .nfo, et cela recommençait après chaque redémarrage. Vos vraies réparations attendaient alors derrière des centaines de réparations inutiles. Certaines releases qui marchaient très bien étaient marquées comme non réparables, et supprimer le .nfo était le seul moyen de les récupérer.

Un .nfo manquant, ou un autre petit fichier à côté de la vidéo, est maintenant lu comme vide et ne demande plus aucune réparation. Cela ne marque plus une release comme non réparable. Une vidéo endommagée peut être réparée à nouveau quand le .nfo à côté d'elle a disparu. Les releases déjà marquées non réparables de cette façon sont revérifiées dans un délai d'environ un jour, et elles reviennent toutes seules.

## Les fichiers Usenet ne lisent plus de silence là où un serveur a envoyé l'article d'un autre envoi {#usenet-files-no-longer-play-silence-where-a-server-sent-another-uploads-article}

Certains serveurs de news répondent à une demande pour un article de ton fichier avec un article provenant d'un autre upload qui porte le même numéro. zurg ne le détectait que lorsque l'autre upload avait moins d'articles que ton fichier. Sur les fichiers courts, comme les volumes RAR et les épisodes courts, il prenait le mauvais article et jouait du silence pendant ce passage. Le log appelait ça `an internal mapping failure in zurg` et indiquait que le décalage `falls between two articles that are both present and neither covers`. zurg vérifie maintenant aussi la taille du fichier que chaque article annonce. Il refuse un article d'un autre fichier et demande le bon à tes autres comptes news. Les articles qu'une ancienne version a déjà enregistrés dans son cache d'articles sont aussi refusés. Avec un seul compte, le passage joue toujours du silence. Le log indique maintenant qu'un serveur a envoyé l'article d'un autre fichier, au lieu d'accuser zurg.

## Les connexions Usenet reviennent à pleine vitesse après qu'une autre application a cessé d'utiliser le compte {#usenet-connections-come-back-at-full-speed-after-another-app-stops-using-the-account}

Si votre fournisseur de news a déjà refusé zurg pour trop de connexions, par exemple pendant qu'un autre programme ou un zurg précédent en utilisait encore, zurg continuait à ajouter une connexion par seconde tant qu'il tournait, même une fois la place libérée. Après chaque période calme, une rafale de téléchargements repartait à partir des deux connexions déjà ouvertes. Un gros compte mettait donc plus d'une minute à retrouver sa pleine vitesse, et les imports faisaient la queue derrière lui, avec « waited 5s for a connection (queued for the account's allowance) » dans le journal de débogage. Désormais, dès que le fournisseur a de nouveau accepté une connexion et qu'une minute s'est écoulée sans nouveau refus, zurg ouvre directement les connexions dont il a besoin.

## Le journal de débogage indique quand une récupération attend une connexion avec plusieurs serveurs de news configurés {#the-debug-log-says-when-a-fetch-waits-for-a-connection-with-several-news-servers-configured}

Avec un seul serveur de news, une récupération qui attendait plus de cinq secondes pour une connexion laissait une ligne de débogage pour le signaler. Avec deux serveurs ou plus, cette ligne n'apparaissait jamais, si bien qu'ajouter un second serveur la faisait disparaître, que l'attente ait cessé ou non. La ligne apparaît désormais aussi pour les configurations multi-serveurs et indique les serveurs sur lesquels la récupération attendait.

## Une récupération Usenet sans fichiers de réparation et avec un premier article mort échoue immédiatement {#a-usenet-grab-with-no-repair-files-and-a-dead-first-article-fails-at-once}

Une release publiée sans fichiers PAR2, dont le premier article avait disparu de tous les serveurs de news, restait en attente pendant cinq minutes avant que Radarr ou Sonarr apprennent qu'elle avait échoué. Il attendait une réparation alors qu'il n'y avait rien à réparer. zurg voit maintenant qu'il n'y a pas de données de récupération et signale immédiatement que le téléchargement a échoué. Le client l'ajoute donc à la liste de blocage et passe à la suite.

## Une récupération Usenet réparée n'est plus signalée en échec cinq minutes plus tard {#a-usenet-grab-that-repair-fixed-is-no-longer-reported-failed-five-minutes-later}

Quand une récupération manquait quelques articles et que ses fichiers PAR2 pouvaient les reconstruire, zurg la réparait. Mais une lecture anticipée lancée pendant la réparation pouvait redemander les articles manquants, et se voir refuser l'accès juste après la fin de la réparation. Ce refus remettait la release dans la liste des éléments endommagés. La récupération était alors bloquée pendant cinq minutes, puis signalée comme échouée, et Radarr ou Sonarr mettaient sur liste noire une release qui fonctionnait pourtant très bien. Un refus pour un article déjà reconstruit par la réparation ne compte plus comme un dommage.

## Les téléchargements mis à niveau qui venaient avec un .nfo ou des sous-titres sont aussi supprimés {#upgraded-downloads-that-came-with-an-nfo-or-subtitles-are-deleted-too}

Avec `magic.allow_delete`, une vidéo supprimée qui n'était pas dans une archive RAR était supprimée toute seule. Le `.nfo`, les sous-titres et l'affiche posés à côté gardaient le téléchargement dans ta bibliothèque. Son NZB restait dans `nzbs/` et son torrent restait sur ton compte debrid. Chaque mise à niveau de ce type de téléchargement en laissait un derrière. Maintenant, tout le téléchargement est supprimé dès que plus rien dans `__magic__` ne l'utilise. Un téléchargement reste tant qu'un autre épisode de celui-ci est encore dans ta bibliothèque ou attend encore dans son propre dossier d'être importé. Les sous-titres que Sonarr ou Radarr ont importés à côté de la vidéo le gardent aussi, jusqu'à ce qu'ils soient supprimés à leur tour.

## Les téléchargements Usenet remplacés et en échec ne s'accumulent plus {#replaced-and-failed-usenet-downloads-no-longer-pile-up}

Avec `magic.allow_delete` activé, un épisode ou un film supprimé qui venait d'une archive RAR était seulement masqué. Le téléchargement d'origine restait dans la bibliothèque et son NZB restait dans `nzbs/` pour de bon. Passer d'épisodes isolés à un pack de saison en laissait un par épisode. Maintenant, tout le téléchargement est supprimé dès que plus rien dans `__magic__` ne l'utilise. Un téléchargement reste tant qu'un autre épisode de la même archive est encore dans ta bibliothèque. Il reste aussi tant que son propre dossier contient encore quelque chose à importer.

Sonarr et Radarr demandent que les fichiers d'un téléchargement échoué soient supprimés quand ils le retirent. zurg gardait quand même le NZB. Maintenant, il le supprime quand rien n'a été importé de cette release. Un téléchargement terminé et importé garde son NZB comme avant, parce que le fichier importé se lit toujours depuis lui.

## zurg indique maintenant quand la bibliothèque a fini de charger {#zurg-now-says-when-the-library-has-finished-loading}

Docker considère zurg comme sain dès qu'il tourne. Une grande bibliothèque peut encore charger pendant plus d'une heure après ça. Les dossiers du montage renvoient `Input/output error` pendant tout ce temps, et on croirait à une installation cassée. La nouvelle adresse `/ready` permet de distinguer les deux cas. Elle répond 503 tant que la bibliothèque n'est pas chargée, et 200 une fois qu'elle l'est. Aucun mot de passe n'est requis. Dans le conteneur, `/app/healthcheck.sh --ready` vérifie la même chose. La vérification de santé du conteneur ne demande toujours que si zurg tourne. Ainsi, un premier chargement long ne peut pas faire redémarrer le conteneur ni bloquer un montage qui en dépend. La vérification de santé lit aussi désormais la variable d'environnement `PORT`. Avant, un conteneur qui définissait `PORT` était vérifié sur le mauvais port.

## L'acquisition peut ignorer des releases à cause de mots dans leurs noms {#acquisition-can-skip-releases-by-words-in-their-names}

Définissez `exclude_words` dans le bloc `acquisition:` et zurg ne prend jamais une version dont le nom contient l'un de ces mots. `exclude_words: [DV, HDR10+]` empêche le Dolby Vision et le HDR10+ d'arriver sur une TV qui ne sait pas les lire, tout en prenant toujours la 4K en HDR classique. Ça fonctionne pour la watchlist Plex, Seerr, Radarr et Sonarr, ainsi que pour Usenet et les torrents. Seuls les mots entiers comptent : `DV` ne capture pas `DVDRip` ni un film qui s'appelle Adventures. `DV`, `DoVi` et `Dolby Vision` désignent la même chose, tout comme `HDR10+` et `HDR10Plus`. Radarr et Sonarr ne sont jamais interrogés au sujet d'une version exclue.

## Radarr et Sonarr peuvent prendre d'abord la meilleure qualité du profil {#radarr-and-sonarr-can-take-the-profiles-best-quality-first}

En général, zurg prend la version autorisée la plus rapide à vérifier. Pour un film, c'est généralement un WEB-DL 1080p. La passe de mise à niveau vise ensuite le cutoff de ton profil. Pour les séries, zurg prend un pack de saison avant les épisodes isolés. Donc un pack 1080p peut remplir une saison même si des épisodes en 2160p étaient disponibles.

Mets `best_first: true` sous `acquisition:` et le premier téléchargement suit à la place ton profil de qualité Radarr ou Sonarr. La meilleure résolution autorisée passe en premier. Tout ce qui est au niveau du cutoff ou au-dessus est considéré comme suffisant. Si une version a disparu, zurg descend dans le profil. Le premier fichier peut mettre plus de temps à arriver, car les meilleures versions sont souvent des posts volumineux en plusieurs parties. Cette option est désactivée par défaut.

## Les résultats torrent ne remplacent plus les NZB là où aucun compte n'accepte les torrents {#torrent-results-no-longer-crowd-out-nzbs-where-no-account-takes-torrents}

Sur une instance avec un fournisseur NZB mais sans compte debrid acceptant les torrents, l'acquisition cherchait quand même dans vos indexeurs Torznab, et chaque torrent trouvé consommait une des trois releases qu'un épisode ou une saison complète d'une série obtient par tentative. Avec `prefer: torrents`, ou avec des torrents 4K classés au-dessus d'un NZB 1080p, les NZB n'étaient jamais essayés et l'épisode échouait. Les indexeurs Torznab sont maintenant ignorés dans ce cas, avec une ligne dans le journal qui l'indique, et une release que l'instance n'a nulle part où mettre ne compte plus comme une tentative. Les films ne demandent plus non plus à Radarr ces torrents.

## L'acquisition ne compte plus un NZB comme terminé là où rien ne peut le lire {#acquisition-no-longer-counts-an-nzb-as-done-where-nothing-can-play-it}

Sur une instance qui a un compte debrid mais aucun fournisseur NZB, l'acquisition cherchait quand même dans vos indexeurs Newznab, et un NZB récupéré était compté comme terminé sans aucune vérification. Un titre de votre liste de suivi Plex pouvait disparaître de la liste pour un fichier que rien sur cette instance ne peut lire. Les indexeurs Newznab sont désormais ignorés dans ce cas, avec une seule ligne dans le journal qui le signale, et un NZB n'est jamais compté comme terminé sur une instance sans fournisseur NZB.

## Une release sans rien à lire est signalée une fois au lieu de chaque jour {#a-release-with-nothing-left-to-play-is-reported-once-instead-of-every-day}

Quand tous les fichiers lisibles d'une release avaient été supprimés, zurg affichait chaque jour de nouveau l'avertissement "has no playable file that still reads". Une bibliothèque avec une centaine de releases de ce type enregistrait donc une centaine de ces avertissements par jour, pour des releases que personne n'avait touchées. L'avertissement n'apparaît maintenant qu'une seule fois, et la release n'est réexaminée qu'après un changement la concernant. Restaurer un fichier le remet toujours en ligne immédiatement.

## Les releases cassées sur AllDebrid et TorBox reviennent quand les fichiers se lisent encore {#broken-releases-on-alldebrid-and-torbox-come-back-when-the-files-still-play}

Une release détenue uniquement par AllDebrid, TorBox, Premiumize, Offcloud ou Debrid-Link
pouvait rester cassée et cachée pendant des semaines alors que le compte la servait encore. Repair ne réajoute pas
les releases de ces services tout seul, parce qu'ils suppriment le contenu exprès, et
personne ne vérifiait jamais si les fichiers avaient recommencé à fonctionner. Repair demande maintenant
au compte une fois par jour si les fichiers d'une release cassée se lisent encore, et
remet ceux qui marchent, sans rien ajouter. Ce qui a vraiment été supprimé par le compte
demande toujours le bouton Repair. Le bilan de réparation MCP dit la même chose, au lieu de te dire qu'aucun balayage n'agira jamais dessus.

## Les récupérations que TorBox met en file d'attente pour un emplacement libre apparaissent comme en file d'attente puis se terminent {#grabs-torbox-queues-for-a-free-slot-show-as-queued-and-finish}

Quand tous les emplacements de téléchargement d'un compte TorBox étaient occupés, TorBox mettait les nouvelles demandes de Sonarr et Radarr (grabs) dans sa file d'attente, et zurg perdait leur trace. La demande affichait « fetching metadata » pendant environ dix minutes, puis une erreur, et Sonarr et Radarr l'abandonnaient. Quand TorBox finissait par la télécharger, plus rien ne l'importait. zurg suit maintenant une demande en file d'attente jusqu'à ce que TorBox la démarre, puis jusqu'à ce qu'elle soit terminée. Pendant l'attente, elle s'affiche comme « queued », et le délai d'expiration sans progression ne se lance qu'une fois que TorBox a démarré la demande.

## Tu peux chercher une seule release sur la page `__magic__` {#you-can-search-for-one-release-on-the-__magic__-page}

Sur une bibliothèque organisée par Sonarr ou Radarr, chaque import laisse derrière lui un dossier de tâche caché, et la page `__magic__` ne liste que les mille premières lignes enregistrées. La version que vous cherchiez ne figurait généralement pas parmi elles : ses boutons Unhide et Reset étaient donc inaccessibles, et la note sous la liste renvoyait vers data/magic.json. Modifier ce fichier pendant que zurg tourne ne fonctionne pas : zurg le réécrit à partir de sa mémoire à l'arrêt, et les lignes reviennent après un redémarrage.

Les lignes enregistrées et les pages orphelines disposent désormais d'une zone de recherche. Saisissez le nom d'une version, un chemin depuis votre point de montage ou un hash, et chaque ligne enregistrée pour cette version s'affiche avec ses boutons, quelle que soit la taille de la table.

C'est aussi la méthode pour restaurer une version présente dans `__all__` mais qui n'apparaît jamais dans `__magic__/__all__.` Supprimer une version puis la rajouter, ou la réinsérer depuis DMM, conserve son hash : elle revient donc avec tout ce que `__magic__` avait enregistré à son sujet, y compris le dossier de tâche supprimé après son import. Recherchez-la, puis cliquez sur Unhide sur sa ligne release-tombstone.

## Sous Windows, `__magic__` ne fait plus grossir son journal indéfiniment {#__magic__-on-windows-stops-growing-its-journal-forever}

On Windows, zurg logged `cannot truncate data\magic.journal ... Access is
denied.` every time it tried to tidy the file where `__magic__` records your
moves and folders. The file was never emptied, so it grew with every change
and every start read all of it again. After a few thousand changes in one run,
each further change also rewrote the whole saved layout. zurg now empties it
on Windows as it always did elsewhere, and the first start after updating
clears what has piled up. If tidying ever fails, zurg tries again after more
changes instead of on every one.

## Restaurer un fichier via MCP remet tout de suite sa release en place {#restoring-a-file-over-mcp-puts-its-release-back-right-away}

Restaurer un fichier avec l'outil MCP `zurg_release_file_restore` ramenait bien le fichier, mais laissait sa release marquée comme cassée et dans `__unplayable__` jusqu'au prochain rafraîchissement de la bibliothèque. Il fait maintenant ce que fait le bouton Restore du gestionnaire de torrents : la release quitte `__unplayable__`, retourne dans ses dossiers avec ses fichiers .strm, et c'est sauvegardé ainsi. Comme avant, il ne demande pas à Plex, Jellyfin ou à votre script on_library_update de relancer une analyse.

## Rétablit les fichiers qu'une réparation échouée avait masqués {#bring-back-files-a-failed-repair-hid}

Les anciennes versions marquaient un fichier comme supprimé quand une réparation abandonnait sur un compte, même si un autre compte pouvait encore le lire, et la release disparaissait alors de tous les dossiers. Le gestionnaire de torrents a un nouveau filtre « Deleted, still served » qui liste les releases sans rien de lisible restant, mais dont un fichier supprimé est encore servi par un compte. Maintiens le bouton Restore et zurg vérifie le lien de chaque fichier, puis remet dans leurs dossiers ceux qui se lisent, comme si tu appuyais sur Restore pour chaque fichier.

zurg ne fait pas ça tout seul. Un fichier que tu as supprimé volontairement est stocké exactement de la même façon, donc parcours la liste et ne restaure que ce que tu n'as pas supprimé toi-même. Les releases qui lisent encore quelque chose sont exclues, car supprimer un extra ou un épisode est le cas typique d'une suppression volontaire.

## L'acquisition regarde au-delà de la première page des résultats de recherche {#acquisition-looks-past-the-first-page-of-search-results}

L'acquisition ne lisait autrefois que la première page renvoyée par un indexeur. Avec DMM, qui renvoie dix résultats par page, les plus gros en premier, une limite de taille pouvait tous les éliminer, et le film échouait avec « no eligible releases » toutes les quelques heures alors que des versions plus petites se trouvaient sur les pages suivantes. Elle continue maintenant de demander des pages supplémentaires jusqu'à obtenir assez de versions qui respectent vos limites, jusqu'à dix pages. Pour les séries, un épisode que la recherche de saison n'a pas trouvé, généralement un plus ancien lorsque le plus récent remplit les résultats, est désormais recherché individuellement.

## Les fichiers morts dans les dossiers de films et de séries de `__magic__` disparaissent maintenant pour que Radarr et Sonarr s'en aperçoivent {#dead-files-in-__magic__-movie-and-show-folders-now-drop-out-so-radarr-and-sonarr-notice}

Un fichier que Radarr ou Sonarr avait importé dans un dossier sous `__magic__` restait affiché à sa taille complète après que la release a cessé de fonctionner. Un rescan le voyait donc toujours, et le film ou l'épisode ne repassait jamais en wanted. Il quitte maintenant le dossier au même moment que dans toutes les autres listes : dès que la réparation ne peut plus le remettre en état, ou un jour après sa panne quand la réparation est désactivée. Le prochain rescan le marque missing et l'acquisition cherche un remplaçant. Si le fichier refonctionne, il réapparaît au même endroit.

## Season Fix trie les packs multi-saisons et les extras numérotés {#season-fix-sorts-multi-season-packs-and-numbered-extras}

Season Fix lit désormais la saison que chaque fichier indique lui-même, donc un pack comme `Full Metal Panic S2 - 01`, `Bakuman II - 01`, `KonoSuba 2 - 01` ou `Demon Slayer Mugen Train Arc - 01` fait placer chaque épisode dans sa propre saison, au lieu de laisser Plex tout empiler sur la saison 1. Les lots nommés en rōmaji ou avec un suffixe, comme `Sergeant Keroro 001-358` ou `Dragon Ball Z COMPLETE`, sont reconnus quand leurs fichiers partagent le même titre. Les noms avec des underscores, `Ep01`, `1.01.` ou un chiffre dans le titre de l'épisode sont lus comme prévu.

Les bonus numérotés comme `Special 01`, `OVA 01`, `- 11 (OVA)` et les récapitulatifs `24.5` se rangeaient avant sur un vrai épisode, comme une deuxième version, et Play pouvait choisir le bonus. Ils sont maintenant renommés avec le suffixe `-other` de Plex pour apparaître comme bonus.

## Un lien Real-Debrid mort ne bloque plus un scan de bibliothèque pendant des minutes {#a-dead-real-debrid-link-no-longer-holds-a-library-scan-for-minutes}

Quand Real-Debrid renvoie toujours le même lien révoqué pour un fichier, zurg attend quelques minutes, car c'est normal juste après la suppression d'un téléchargement. Un fichier encore refusé de cette façon après cinq minutes est maintenant considéré comme un lien cassé et envoyé à la réparation, au lieu de dire à l'utilisateur de revenir plus tard. Avant, un seul fichier mort pouvait bloquer un scan Plex pendant environ dix minutes.

## Les tâches Usenet en échec ou bloquées peuvent être effacées depuis la page `__magic__` {#failed-and-stuck-usenet-jobs-can-be-cleared-from-the-__magic__-page}

Une tâche Failed ou Stuck dans la liste SABnzbd restait là pour de bon une fois que Sonarr ou Radarr avaient arrêté d'utiliser zurg comme client de téléchargement. Un redémarrage ne la supprimait pas. La seule solution était de supprimer `data/sabnzbd-jobs.json` à la main. La page `__magic__` affiche maintenant un bouton **Clear** sur chaque tâche Failed ou Stuck, ainsi qu'un bouton au-dessus de la liste qui les supprime toutes. Maintenez-le enfoncé jusqu'à ce que la barre se remplisse. Les tâches Queued et Completed ne sont jamais touchées. Le NZB de la tâche est supprimé aussi, sauf si un import sous `__magic__` utilise encore cette release.

## L'addon Stremio indique quand il a besoin de https {#the-stremio-addon-says-when-it-needs-https}

Stremio ne charge un addon en http que sur l'ordinateur où il tourne. Sur une TV, un téléphone ou un autre ordinateur, une adresse http échoue avec « failed to load manifest », même quand l'appareil peut joindre zurg. La page de configuration l'indique maintenant à côté de l'URL de l'addon, chaque fois que tu l'as ouverte en http sur une adresse de ce type. Le guide Stremio présente trois façons de mettre zurg derrière https : Tailscale Serve, ton propre reverse proxy et un tunnel Cloudflare.

## Plex récupère un film ou un épisode dès que Radarr ou Sonarr l'importe dans `__magic__` {#plex-picks-up-a-movie-or-episode-as-soon-as-radarr-or-sonarr-imports-it-into-__magic__}

Après que Radarr ou Sonarr a déplacé un fichier dans un dossier sous `__magic__`, zurg demandait à Plex de scanner le fichier lui-même. Plex ne scanne que les dossiers, donc il répondait comme si tout allait bien et n'ajoutait rien. Le film restait manquant jusqu'au prochain scan planifié de Plex. zurg demande maintenant à Plex de scanner le dossier dans lequel le fichier a atterri. Il en va de même pour le fichier remplacé par une mise à niveau, pour que l'ancienne version disparaisse, et pour les endpoints de scan manuel, l'outil MCP `zurg_plex_scan_releases`, les scans après un renommage ou une suppression de fichier, et les chemins transmis à `on_library_update`.

## La page Manage liste les releases en double et celle que Radarr ou Sonarr utilise {#the-manage-page-lists-duplicate-releases-and-which-one-radarr-or-sonarr-uses}

Une mise à niveau laisse la release qu'elle a remplacée dans ta bibliothèque, et les recherches auprès de différents indexeurs peuvent laisser plus d'une copie d'un film ou d'une saison. La nouvelle vue Duplicates de la page Manage regroupe les releases qui contiennent le même film ou les mêmes épisodes, et indique laquelle Radarr ou Sonarr utilise. zurg détermine ça à partir de l'emplacement du fichier dans `__magic__`, pas à partir des noms de releases.

Pour une saison, elle liste chaque épisode présent dans plus d'une release, ainsi que la release dans laquelle se trouve le fichier de Sonarr. Un pack dont Sonarr ne prend que quelques épisodes apparaît donc toujours comme utilisé. Toutes les autres releases sont marquées "No reference found" ou "Unknown", avec la raison. Sélectionne celles que tu veux supprimer. zurg relit Radarr et Sonarr avant de supprimer, et laisse de côté tout ce qui a été utilisé depuis. Rien n'est jamais supprimé automatiquement.

## Les emplacements de téléchargement occupés sur TorBox sont comptés comme TorBox les compte {#torboxs-busy-download-slots-are-counted-the-way-torbox-counts-them}

Avant qu'une réparation ou une première lecture n'ajoute un torrent à TorBox, zurg vérifie si le compte a un emplacement de téléchargement libre. Avant, il comptait tous les torrents qui n'étaient pas entièrement téléchargés. Cela laissait passer les torrents en cours de partage, que TorBox compte dans ton forfait pendant jusqu'à 30 jours, et comptait les torrents dont le contenu avait expiré, qui n'occupent aucun emplacement. Quelques torrents expirés dans une bibliothèque suffisaient donc à faire attendre la réparation comme si tous les emplacements étaient pris.
zurg compte maintenant exactement les torrents que TorBox marque comme actifs.

## TorBox peut seeder pour les trackers privés {#torbox-can-seed-for-private-trackers}

Un nouveau paramètre, `tb_seed_torrents`, décide si les torrents que zurg ajoute à TorBox sont partagés (seed). Il reste sur `never` tant que vous ne le modifiez pas, donc rien ne change pour ceux qui le laissent tel quel. Mettez-le sur `always` si un tracker privé demande votre ratio, ou sur `auto` pour laisser le paramètre de partage de votre compte TorBox décider. Vous pouvez le modifier depuis la section Health & Repairs du tableau de bord, et il prend effet lors du prochain ajout.

Un torrent en cours de partage occupe l'un des emplacements actifs de votre forfait TorBox tant qu'il est partagé, jusqu'à 30 jours sur Pro. Lorsque les torrents partagés remplissent tous les emplacements, les nouveaux ajouts et réparations sur ce compte doivent attendre qu'un emplacement se libère.

## Les jeux RAR dont les volumes sont nommés dans le désordre se lisent maintenant {#rar-sets-whose-volumes-are-named-out-of-order-now-play}

Une release dont chaque volume RAR porte un nom différent, comme un nom aléatoire par volume ou `Movie 2026 part1.rar`, apparaissait avant comme une archive par volume. La première affichait le film, mais elle cessait de fonctionner après sa première partie, et les autres n'affichaient rien. zurg lit maintenant à quelle place appartient chaque volume à partir de l'intérieur du volume lui-même, et il recompose le jeu complet. C'est ce que permettait de faire, à la main, le renommage des volumes en `part001.rar` et suivants. Ça ne fonctionne que si les volumes se numérotent eux-mêmes en un jeu complet. Si l'un manque ou si deux revendiquent la même place, la release reste telle quelle et le log indique pourquoi. Les archives compressées dont les volumes sont postés dans le désordre se lisent maintenant aussi.

## Un scan Plex encore en cours d'analyse n'est plus signalé comme bloqué {#a-plex-scan-that-is-still-analysing-is-no-longer-reported-as-stuck}

Plex garde inchangés la progression et le dossier en cours pendant qu'il analyse les fichiers trouvés par un scan de bibliothèque, ce qui peut prendre très longtemps sur une bibliothèque volumineuse ou distante. Le tableau de bord qualifiait alors ce scan de bloqué et proposait de redémarrer Plex en pleine opération. zurg écoute désormais le flux de mises à jour propre à Plex et compte les éléments sur lesquels Plex indique travailler encore, si bien que seul un scan réellement arrêté est signalé.

## Les uploads torrent en cache uniquement préservent le refus d'ajout chez les fournisseurs à débit limité {#cached-only-torrent-uploads-preserve-the-refusing-add-on-rate-paced-providers}

Un `.torrent` envoyé en mode cached-only atteint maintenant l'ajout refusant de TorBox, même lorsque sa limite horaire d'ajouts fait boucler le backend. Un miss non mis en cache ne crée aucun transfert et n'occupe aucun slot actif ; il consomme tout de même l'un des 60 ajouts non mis en cache de TorBox par heure. Les ajouts ordinaires continuent d'envoyer le fichier original.
Le guide qBittorrent liste désormais les six fournisseurs d'envoi de torrents et explique les chemins cached-only distincts de Debrid-Link et de TorBox.

## Un fichier que tu supprimes pendant sa restauration reste supprimé {#a-file-you-delete-while-it-is-being-restored-stays-deleted}

La suppression d'un fichier ou d'une release pendant qu'une restauration vérifie encore son lien attend maintenant la fin de cette vérification, puis l'emporte. Un rafraîchissement de la bibliothèque déjà en cours ne peut plus faire revenir une release que vous venez de supprimer.

## Une recherche loin dans une archive compressée ne bloque plus le lecteur {#a-seek-far-into-a-compressed-archive-no-longer-hangs-the-reader}

Un fichier contenu dans une archive RAR ou zip compressée ne peut être décodé qu'à partir de son début. Une lecture proche de la fin d'une grosse archive devait donc attendre la totalité de l'archive, sans aucune réponse. Plex pouvait rester bloqué sur une telle lecture pendant plus d'une heure, ce qui suffisait à bloquer sa base de données. zurg répond désormais en moins de 20 secondes, conserve la progression déjà réalisée, et prépare la fin du fichier en arrière-plan pour que la lecture suivante soit immédiate.

## Les refus de Real-Debrid suivent les règles de nommage publiées {#real-debrid-refusals-follow-the-published-filename-rules}

Quand Real-Debrid refuse de ré-ajouter une release pendant la réparation, zurg vérifie désormais le nom de la release et les noms de ses fichiers par rapport aux règles de nommage publiées. Une release bloquée par ces règles est marquée définitivement comme contrefaisante. Tout autre refus est interprété comme un ralentissement des ajouts par Real-Debrid : la release reste en file d'attente pour le prochain passage de réparation au lieu d'être retirée.

## Restaurer un fichier le remet tout de suite à sa place {#restoring-a-file-puts-it-back-where-it-belongs-straight-away}

L'action Restore sur la page de gestion d'une release re-classe maintenant la release dans ses dossiers, enregistre l'état récupéré et écrit son fichier STRM dès que le fichier est vérifié. Un fichier restauré ne reste plus dans le dossier non lisible jusqu'au prochain rafraîchissement du fournisseur, et une release dont le dernier fichier cassé a été restauré n'est plus signalée comme cassée après un redémarrage. Les fichiers que vous avez supprimés restent supprimés tant que vous ne les restaurez pas.

## Rejeter les articles Usenet étrangers avant de servir les octets {#reject-foreign-usenet-articles-before-serving-bytes}

Rejeter les articles Usenet de même numéro dont le total yEnc positif est inférieur au numéro le plus élevé indiqué dans le NZB, y compris le cache persistant et les chemins progressifs, afin que les replis de compte valides fournissent les octets.

## Conserver une classification des refus RD appuyée sur des preuves {#preserve-evidence-backed-rd-refusal-classification}

Traite silencieusement les réponses 451 de addMagnet comme des refus de release, sauf si des preuves de limitation de débit propres au compte couvrent toute l'opération, et conserve les erreurs temporaires pendant la réparation.

## Clarifier les fenêtres de lecture des fichiers cassés expirés {#clarify-expired-broken-file-read-windows}

Signaler une fenêtre de nouvelle tentative de lecture de fichier cassé expirée sans affirmer que la réparation a abandonné.

## Exposer la santé enregistrée des fichiers dans MCP {#expose-recorded-file-health-in-mcp}

Exposez les compteurs de santé enregistrés par fichier dans les vues de version MCP, et gardez les tableaux de fichiers paresseux sûrs à inspecter sans affirmer qu'un état de cycle de vie est une sonde de service en direct.

## Gérer les opérations de sidecar en double {#handle-duplicate-sidecar-operations}

Reconnaître les réponses typées « source manquante » provenant des alias WebDAV en double, tout en conservant les vraies erreurs « tout a échoué » et les erreurs de permission.

## Un nouveau téléchargement sous le même nom est réparé au lieu d'échouer {#a-re-grab-under-the-same-name-is-repaired-instead-of-failed}

Reprendre un NZB sous un nom que zurg possède déjà ne vérifie et ne répare plus l'ancienne copie pendant la lecture de la nouvelle. La récupération attend le nouveau fichier, donc une release avec un article manquant que PAR2 peut reconstruire est réparée et terminée au lieu d'être signalée comme échouée.

## Les échecs de réparation ne ressemblent plus à des suppressions par l'utilisateur {#repair-failures-no-longer-masquerade-as-user-deletions}

Les échecs de réparation automatique ne marquent désormais comme cassée que la source du fournisseur en échec, en conservant les copies alternatives saines et en permettant aux actualisations ultérieures du fournisseur de rétablir la visibilité des fichiers.

## Les torrents sans identifiant IMDb sont identifiés par le nom de la release via DMM {#torrents-without-an-imdb-id-are-identified-by-release-name-through-dmm}

Avec `dmm_metadata_secret` défini, la tâche IMDb n'a plus besoin de clé OpenSubtitles. Les torrents sans id, ou avec seulement le marqueur d'échec d'OpenSubtitles, sont identifiés au démarrage à partir d'un tag `imdb-tt…` dans leur nom. Sinon, c'est le résolveur de DMM qui s'en charge, mais il ne répond que si un seul titre correspond exactement. Les romanisations de fansubs comme « Kaijuu 8-gou » passent par les alias de DMM et deviennent Kaiju No. 8. Un nom que plusieurs séries partagent est laissé de côté. Un torrent que DMM ne peut pas nommer garde un id vide, pour que Plex puisse quand même le compléter lors d'une correspondance.

## Un film Radarr qu'aucun indexeur ne connaît par identifiant est recherché par son nom {#a-radarr-movie-that-no-indexer-knows-by-id-is-searched-for-by-name}

Beaucoup de posts Usenet sont indexés sans identifiant IMDb ni TMDB. zurg cherchait un film Radarr uniquement par identifiant, donc un documentaire pour lequel aucun indexeur ne répondait par identifiant échouait avec "no eligible releases", alors que la recherche par nom de Radarr trouvait une release propre. Quand la recherche par identifiant ne trouve rien à prendre, zurg cherche maintenant aussi par titre et année, et le parser de Radarr décide toujours si chaque résultat correspond bien au film. Seule une recherche par identifiant qui n'a rien trouvé du tout est suivie d'une recherche par nom : un film que la recherche par identifiant trouve est indexé par identifiant, et redemander par nom ne ferait que récupérer les mêmes posts.

## Les NZB trouvés via Prowlarr peuvent être téléchargés {#nzbs-found-through-prowlarr-can-be-downloaded}

Prowlarr transmet chaque NZB Usenet en redirigeant vers l'indexeur, et il ne permet pas de désactiver cela. zurg ne suivait une redirection que vers le même hôte ; donc, avec des indexeurs configurés via Prowlarr, chaque acquisition NZB échouait avec « answered 301 Moved Permanently » et rien n'était jamais acquis. La redirection est désormais suivie. La clé API du lien ne parvient toujours jamais à l'autre hôte, et une redirection de HTTPS vers HTTP simple est toujours refusée.

## Un indexeur qui refuse pendant des heures ne bloque plus l'acquisition {#an-indexer-that-refuses-for-hours-no-longer-stalls-acquisition}

Prowlarr répond à une recherche sur un indexeur qu'il a désactivé avec `429` et un `Retry-After` de plusieurs heures. zurg attendait deux minutes puis redemandait, trois fois, donc chaque recherche passait six minutes sur ce seul indexeur. L'acquisition abandonnait chaque titre après cinq essais et jetait ce que les autres indexeurs avaient déjà répondu, si bien que rien n'était acquis tant que l'indexeur ne revenait pas. Un indexeur qui demande à être laissé tranquille plus de deux minutes est maintenant ignoré jusqu'à l'heure indiquée, et les recherches continuent sur les autres.

## Un titre supprimé après acquisition est de nouveau recherché {#a-title-deleted-after-acquisition-is-searched-for-again}

Lorsqu'un fichier que l'acquisition de zurg avait placé pour Sonarr ou Radarr était supprimé, parce qu'il ne s'agissait pas de la version voulue ou pour une autre raison, et que le titre réapparaissait dans la liste des manquants, zurg répondait « completed without a search, the release was already held » et ne le recherchait plus jamais. zurg vérifie désormais d'abord le dossier de saison ou de film dans `__magic__`. Un épisode ou un film dont la vidéo n'est plus là est recherché à nouveau. Un épisode ou un film dont la vidéo est toujours présente, ce qui arrive tant que Sonarr n'a pas encore relancé son analyse, est laissé tranquille.

## "Scan in Plex" sur la liste non détectée attend le résultat {#scan-in-plex-on-the-undetected-list-waits-for-the-result}

Le bouton hold-to-scan de la liste des non détectés rechargeait la page deux secondes après l'avoir pressé, alors que la correspondance avec Plex n'avait pas encore commencé. Sur une grosse bibliothèque, cette correspondance prend plusieurs minutes, donc la liste revenait toujours inchangée et le bouton avait l'air de ne rien faire. Le bouton affiche maintenant que la correspondance est en cours, attend qu'elle se termine, indique combien de releases ont été associées, puis recharge la page.

## Une release dont le nom se termine par un espace est associée à Plex {#a-release-whose-name-ends-in-a-space-is-matched-to-plex}

Une release dont le nom de fichier contient un espace avant l'extension, comme
`... [Hurtom] v2 .mkv`, obtient un dossier dont le nom se termine par un espace. Plex l'a trouvée,
mais zurg n'a jamais pu la faire correspondre, donc elle restait dans la liste des éléments non détectés après chaque scan. Elle est maintenant prise en charge.

## Supprimer un fichier sur la page de gestion garde votre position {#deleting-a-file-on-the-manage-page-keeps-your-place}

Supprimer, restaurer, renommer ou forcer l'affichage d'un seul fichier sur la page de gestion d'une release rechargeait la page tout en haut. Élaguer un gros pack obligeait donc à redescendre après chaque clic. La page revient maintenant à la ligne de ce fichier et la met en surbrillance.

## Le tableau de bord accepte un chemin de montage saisi entre guillemets {#the-dashboard-takes-a-mount-path-typed-with-quotes}

Un chemin de montage collé dans le tableau de bord tel qu'il est écrit dans config.yml, par exemple `"/Users/me/Plex Media Server/ZurgMount"` ou `'Z:\'`, était refusé avec « mount path should be absolute ». Les guillemets étaient lus comme faisant partie du chemin. Le tableau de bord retire maintenant une paire de guillemets identiques autour de la valeur et enregistre le chemin à l'intérieur.

## Un échec de récupération de la watchlist Plex indique la raison {#a-failed-plex-watchlist-fetch-says-why}

Quand Plex refuse une requête de liste de suivi, le journal affiche maintenant la raison donnée par Plex elle-même, par exemple `unexpected status: 401: Invalid token`, au lieu du seul code de statut. Si vous voyez encore `Failed to fetch watchlist: ... unexpected status: 400`, ce message vient d'une version de zurg antérieure à août. Mettez zurg à jour : les versions actuelles demandent la liste de suivi par pages que Plex accepte.

## Une release trop endommagée pour la mémoire de réparation échoue tout de suite {#a-release-too-damaged-for-repairs-memory-fails-at-once}

Quand une release Usenet manque plus de données que la réparation PAR2 ne peut en contenir en mémoire d'un coup, zurg le signale désormais et s'arrête, puis Sonarr ou Radarr choisissent une autre release. Avant, il gardait la récupération en attente et réessayait toutes les quelques minutes, en revérifiant toute la release à chaque fois pour obtenir la même réponse. Les dégâts qui ne sont pas encore confirmés comme définitifs, comme les articles qu'un serveur n'a pas su fournir, sont toujours réessayés.

## La configuration passe une config vide et indique quand l'invite du token est masquée {#setup-gets-past-an-empty-config-and-says-when-the-token-prompt-is-hidden}

`zurg setup`, et les installateurs qui le lancent, refusaient de continuer tant qu'un `config.yml` vide traînait, avec une erreur qui se terminait par un blanc. Un config vide est maintenant remplacé. Un config qui contient quelque chose n'est toujours jamais écrasé, mais l'erreur indique maintenant de quel fichier il s'agit et comment repartir de zéro. L'invite du token précise que ce que tu tapes ou colles reste caché, ce qui ressemblait à un refus du terminal. Une faute de frappe dans `config.yml` est maintenant signalée par rapport à `config.yml`, et non plus par un message interne "outbound identity config".

## Un serveur de news de secours remplace maintenant les articles que le serveur principal donne mal {#a-backup-news-server-now-fills-in-articles-the-main-server-answers-wrongly}

Certains serveurs Usenet répondent à une demande d'article avec un morceau d'un autre envoi. zurg reconnaissait le mauvais morceau mais ne demandait jamais le bon au serveur de secours. Le trou était alors lu comme du silence, ou le fichier ne s'ouvrait pas, même si le serveur de secours l'avait. zurg interroge désormais le serveur suivant, comme le fait SABnzbd.

## Une release Usenet en RAR arrive dans son répertoire sans redémarrage {#a-rard-usenet-release-reaches-its-directory-without-a-restart}

Une release publiée sous forme de jeu RAR est classée dans des dossiers d'après ses noms de volumes tant que son archive n'a pas été ouverte, puis d'après les fichiers qu'elle contient. Rien ne la reclassait une fois l'archive ouverte. Un dossier qui cherche un `.mkv` ou des numéros d'épisodes passait donc à côté d'une release RAR fraîchement récupérée jusqu'au redémarrage de zurg, et Plex et Jellyfin ne la voyaient pas à cet endroit. La release est maintenant déplacée dans les bons dossiers dès que son archive est listée pour la première fois.

## Un film publié sous un nom aléatoire est nommé d'après sa release {#a-movie-posted-under-a-random-name-is-named-after-its-release}

Certains posts Usenet donnent au film un nom aléatoire, comme `eq5KVi5Y3iTwFEn1Nub8yPY9yd6oUzTu.mkv`, et répètent ce nom partout dans le post où pourrait figurer le vrai. zurg conservait ce nom, donc Radarr et Sonarr n'avaient rien dans le nom de fichier pour s'y retrouver. zurg nomme désormais le fichier d'après la release, comme le fait SABnzbd : seulement lorsqu'il s'agit clairement du gros fichier unique de la release, seulement pour un fichier vidéo, et jamais pour une structure de disque ou une archive. Cela s'applique aux releases récupérées à partir de maintenant ; une release déjà présente dans la bibliothèque garde son nom.

## Les règles de taille s'appliquent désormais aux fichiers dans les archives {#size-rules-now-apply-to-files-inside-archives}

Un film Usenet publié sous forme d'ensemble RAR est affiché avec les fichiers contenus dans l'archive.
Ces fichiers ignoraient les réglages `only_show_the_biggest_file` et
`only_show_files_with_size_gte`/`_lte` d'un répertoire, donc tout le reste de la publication restait visible à côté du film. Beaucoup de publications incluent une petite image portant le nom du film, une planche de captures horodatées, et Jellyfin l'utilisait comme affiche. Les réglages de taille s'appliquent maintenant au contenu des archives de la même façon qu'à tous les autres fichiers.

## Les releases Usenet dont le plus gros fichier PAR2 dépasse 512 Mo peuvent être réparées {#usenet-releases-whose-largest-par2-file-is-over-512-mb-can-be-repaired}

Quand une release a des morceaux manquants, zurg les reconstruit à partir des fichiers PAR2 de la release elle-même. Il refusait de lire tout fichier PAR2 de plus de 512 Mo. Or, sur une grosse release, ce fichier contient plus de données de réparation que n'importe quel autre, et c'est souvent le seul qui existe. Une telle release ne pouvait donc pas être réparée, peu importe la quantité manquante, et zurg réessayait sans cesse, en téléchargeant à chaque fois tous ses petits fichiers PAR2 avant d'abandonner. zurg lit maintenant un fichier PAR2 de n'importe quelle taille. Une release dont les dégâts dépassent ce qu'une réparation peut tenir en mémoire est refusée dès que les dégâts sont comptés, avant que l'un de ses fichiers PAR2 ne soit téléchargé.

## Sonarr peut transmettre ses épisodes manquants à zurg {#sonarr-can-hand-its-missing-episodes-to-zurg}

zurg peut maintenant aussi prendre sa liste depuis Sonarr. Ajoute une source `sonarr` sous `acquisition.sources` avec l'URL de Sonarr et sa clé API. zurg parcourt ensuite les épisodes qui manquent à Sonarr ainsi que les fichiers d'épisodes qu'il veut améliorer. Il cherche sur tes indexeurs et vérifie que les serveurs Usenet ont toujours la release. Il place chaque épisode dans le dossier de sa saison à l'intérieur de `__magic__` et demande à Sonarr de rescanner la série. Sonarr n'a besoin ni d'indexeurs ni de client de téléchargement pour ça.

Une saison qui manque entièrement et qui a fini de sortir peut arriver sous forme de pack de saison complète. Le reste arrive épisode par épisode. Chaque release passe d'abord par le parseur de Sonarr. Il faut que ce soit la bonne série et le bon épisode, et que ça corresponde au profil de qualité de la série. Les améliorations ne remplacent que l'épisode amélioré. Quand un épisode d'une saison n'a encore aucune release, les autres sont quand même placés et Sonarr rescanne pour eux. Les séries quotidiennes et les animés sont ignorés pour l'instant, avec une note dans le log. `docs/acquisition.md` explique la partie Sonarr de la configuration.

## L'acquisition gère beaucoup de titres à la fois {#acquisition-works-on-many-titles-at-once}

Les titres d'une watchlist ou d'un service de requêtes étaient autrefois récupérés les uns après les autres, si bien qu'une longue liste prenait autant de temps que la somme de tous ses titres. zurg en traite maintenant jusqu'à huit à la fois, réglé par `acquisition.concurrency`. Un titre qui arrive plus tard dans la liste n'attend plus que ceux qui le précèdent soient terminés.

Une nouvelle sortie ne reste plus deux minutes en attente avant que zurg ne la vérifie. zurg vérifie chaque seconde jusqu'à ce que la sortie apparaisse dans la bibliothèque, pendant une minute et demie maximum. Quand les serveurs de news ne proposent plus une sortie, zurg passe directement au candidat suivant au lieu de réessayer cinq minutes plus tard. La vérification d'une sortie n'a plus à tenir dans le temps qui reste après la recherche, si bien qu'une recherche lente sur une longue liste ne retarde plus les titres de plusieurs minutes. Les mises à niveau des titres que tu possèdes déjà attendent que les titres manquants de la même liste soient terminés, pour ne jamais leur faire concurrence sur les appels aux indexeurs ou les connexions aux serveurs de news.

## Une release Usenet réparée avec PAR2 reste réparée pendant sa lecture {#a-usenet-release-repaired-with-par2-stays-repaired-while-it-is-read}

Quand certains articles d'une release ont disparu des serveurs de news, zurg les reconstruit à partir des fichiers PAR2 de la release et sert les octets reconstruits. La partie de zurg qui télécharge à l'avance, devant le lecteur, ne connaissait pas les morceaux reconstruits. Elle redemandait donc aux serveurs les articles manquants. Ils étaient toujours absents, et zurg signalait à nouveau la release comme endommagée, alors que chaque octet qu'il servait était correct. Une release réparée pendant un import pouvait être marquée en échec quelques instants plus tard, et un client de téléchargement jetait alors une bonne copie pour en récupérer une autre. zurg ne demande plus aux serveurs rien qu'il a déjà reconstruit.

## Radarr peut transmettre ses films souhaités à zurg {#radarr-can-hand-its-wanted-movies-to-zurg}

zurg peut maintenant prendre sa liste depuis Radarr. Ajoute une source `radarr` sous `acquisition.sources` avec l'URL et la clé API de Radarr, et zurg parcourt les films qui manquent à Radarr ou dont il veut améliorer la qualité. Il cherche sur tes indexeurs, vérifie que les serveurs de news ont toujours la release, place la vidéo dans le dossier du film dans `__magic__` et demande à Radarr de rescanner ce film. Radarr n'a besoin d'aucun indexeur ni d'aucun client de téléchargement pour ça. Chaque release que zurg prend est d'abord passée par le parseur de Radarr, donc c'est forcément le bon film, et elle respecte le profil de qualité : une qualité autorisée, le score minimum de format personnalisé, les limites de taille, et les améliorations seulement jusqu'au cutoff. zurg prend la première release autorisée qui est la plus rapide à vérifier, les releases web en premier, et laisse les qualités préférées du profil à l'amélioration qui suit. Il ne demande à Radarr au sujet d'une release que lorsqu'il est sur le point de la vérifier, une à la fois, et il ne demande jamais pour une release dont le titre indique une résolution pour laquelle le profil n'a aucune qualité. Ainsi, un Radarr occupé ne répond qu'à une à trois questions pour la plupart des films, au lieu d'une par résultat de recherche. Si Radarr voit le point de montage de zurg à un autre chemin, règle `library_path` sur l'endroit où il voit `__magic__`. Une nouvelle page Acquisition sur le tableau de bord affiche chaque titre sur lequel zurg travaille, ce qu'il fait en ce moment et où chaque release a été placée. `docs/acquisition.md` détaille la partie Radarr de la configuration.

## L'acquisition choisit la release Usenet la plus rapide à confirmer {#acquisition-picks-the-usenet-release-that-is-quickest-to-confirm}

Quand zurg acquiert un film, il regarde maintenant d'abord les posts qui ne contiennent qu'un seul fichier vidéo. Ils sont bien plus souvent encore complets sur les serveurs de news et ne demandent que deux lectures d'articles pour être confirmés. Il lit le NZB de chaque candidat avant de sauvegarder quoi que ce soit, sauvegarde le premier post à fichier vidéo unique qu'il trouve, et ne se rabat sur les ensembles d'archives multi-volumes que lorsqu'aucun n'est proposé, du plus petit au plus grand, et pas plus de six à la fois. Les résultats dont le titre désigne une seule partie d'un post découpé sont ignorés. Lors de tests sur le Top 100 d'IMDb, ce mode de choix a fait passer le nombre de NZB que zurg devait récupérer de 517 à 156. Les recherches et les téléchargements de NZB partagent désormais une même limite de requêtes en cours par indexeur, et attendent qu'un indexeur qui dit être occupé se libère. Une demande de film sans profil de qualité derrière elle obtient toujours d'abord la résolution demandée. L'acquisition des séries ne change pas.

## L'acquisition vérifie une release dès que zurg connaît ses tailles {#acquisition-checks-a-release-once-zurg-knows-its-sizes}

zurg vérifiait une nouvelle release auprès des serveurs de news dès qu'elle apparaissait
dans la bibliothèque, alors qu'il était encore en train de lire cette même release pour
connaître la taille de ses fichiers. Les deux demandaient les mêmes articles sur les mêmes
connexions, donc sur une longue liste les deux avançaient lentement. Sur une liste de 99 films,
le dernier a atteint Radarr après près de neuf minutes. zurg vérifie maintenant une release une
fois que ses tailles sont connues, comme il le fait déjà pour Sonarr et Radarr via le point de
terminaison SABnzbd, ne vérifie pas plus de six releases à la fois, et réutilise le premier
article que la vérification de taille avait déjà téléchargé lorsqu'il le possède encore. Une
rafale de releases sauvegardées mène désormais à un seul rafraîchissement de la bibliothèque au
lieu d'un par release.
La vérification d'une release passe maintenant avant les vérifications de taille des autres
releases, mais jamais avant la lecture, et un compte avec plus de douze connexions apprend
désormais les tailles de jusqu'à seize releases à la fois au lieu de huit.

## Une release Usenet récupérée avec quelques morceaux manquants est réparée avant d'échouer {#a-grabbed-usenet-release-with-a-few-missing-pieces-is-repaired-before-it-is-failed}

Avant de dire à Radarr ou Sonarr qu'un téléchargement est terminé, zurg vérifie que les morceaux de la release sont toujours présents sur les serveurs de news. Quand cette vérification trouvait des morceaux manquants, zurg marquait le téléchargement comme échoué sur-le-champ, même quand les fichiers PAR2 de la release auraient pu reconstruire ce qui manquait. Radarr jetait alors la release et partait en chercher une autre, souvent moins bonne. zurg reconstruit maintenant d'abord les morceaux manquants et ne signale l'échec du téléchargement que si cela ne fonctionne pas. Sur une semaine de vrais grabs, la plupart des releases échouées de cette façon avaient les fichiers PAR2 qui auraient pu les sauver.

## Les releases Usenet endommagées attendent leur tour de réparation au lieu d'échouer {#damaged-usenet-releases-wait-their-turn-for-a-repair-instead-of-being-failed}

zurg répare au maximum deux versions endommagées à la fois, et une réparation peut durer de quelques minutes à plus d'une heure. Un troisième téléchargement endommagé n'avait que cinq minutes pour démarrer avant que zurg ne signale à Radarr ou Sonarr qu'il avait échoué. Quand plusieurs arrivaient en même temps, tous sauf deux étaient donc jetés sans que personne n'essaie de les réparer, et le journal n'en disait rien. zurg garde désormais un téléchargement en attente pendant que sa réparation fait la queue, pendant trois heures au maximum, et le journal indique quand une réparation attend son tour.

## Un téléchargement Usenet n'attend plus indéfiniment des tailles de fichiers que personne ne connaîtra {#a-usenet-download-no-longer-waits-for-ever-on-file-sizes-nothing-is-going-to-learn}

zurg retient un téléchargement terminé dans Radarr et Sonarr tant qu'il ne connaît pas la taille exacte de chaque fichier, parce que les clients vérifient cette taille lors de l'import. Après certaines relances, zurg pouvait arrêter d'essayer de récupérer les tailles tout en continuant à les attendre, si bien que le téléchargement restait bloqué dans la file jusqu'à ce que le client abandonne, souvent deux heures plus tard. zurg recalcule désormais la taille de cette release, et quand aucun autre calcul n'est possible et que tous les morceaux de la release sont sur les serveurs Usenet, il indique au client que le téléchargement est prêt.

## Les releases Usenet dont le posteur a renommé seul le premier volume d'archive relancent la lecture {#usenet-releases-whose-poster-renamed-only-the-first-archive-volume-play-again}

Certains posteurs renomment le premier volume d'une archive avec le nom de la release et laissent les autres sous leur nom d'origine. Une release arrive donc sous la forme `Show.S02E03.part03.rar` plus `show.203.r00` à `show.203.r19`. zurg regroupait les volumes par nom, voyait deux archives incomplètes et n'arrivait à ouvrir aucune des deux. Il lit désormais l'en-tête du premier volume, reconnaît les volumes auxquels il appartient et le renomme en conséquence, si bien que l'épisode se lit et s'importe. Un dossier dont l'archive manque réellement d'un volume affiche maintenant un message clair qui l'indique, au lieu d'une erreur serveur générique.

## Les releases Usenet obfusquées dont les volumes sont simplement numérotés se lisent désormais {#obfuscated-usenet-releases-whose-volumes-are-just-numbered-now-play}

Certaines releases cachent tous les noms de fichiers derrière une chaîne aléatoire et un numéro, si bien qu'un film arrive sous la forme `f342c135….01`, `….02` et ainsi de suite, avec les fichiers texte et les jaquettes numérotés au milieu. zurg ne reconnaissait pas ces fichiers comme des parties d'une même archive : il les listait comme des fichiers isolés, et Radarr et Sonarr ne trouvaient rien à importer. zurg lit maintenant le début de chaque fichier numéroté, remet les parties de l'archive dans le bon ordre (même quand la première partie a été postée en dernier) et laisse de côté les fichiers texte et les images.

## Les NZB de packs de saison de plus de 32 Mo sont acceptés {#season-pack-nzbs-over-32-mb-are-accepted}

zurg refusait tout NZB de plus de 32 Mo envoyé à son endpoint SABnzbd, en répondant « request body too large ». Or les NZB des grosses packs de saisons dépassent souvent cette taille : une saison de 526 Go est arrivée en NZB de 49 Mo. zurg accepte maintenant les NZB jusqu'à 256 Mo. Un NZB de 49 Mo avec près d'un demi-million de segments se charge en moins de 30 secondes.

## Les fichiers issus de posts Usenet emballés gardent leurs vrais noms {#files-from-wrapped-usenet-posts-keep-their-real-names}

Certains outils de publication entourent chaque nom de fichier dans la ligne d'objet, comme dans
`[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv]-[3/4]`, et laissent vide le nom de fichier habituel entre guillemets. zurg gardait l'enveloppe dans le nom, donc les épisodes apparaissaient sous la forme `[PRiVATE]-[EnCrYpTnZb]-[Show - 48.mkv`, ce qui empêchait Sonarr et les serveurs multimédias de les reconnaître. zurg retire désormais le nom de l'enveloppe. Les releases déjà présentes dans la bibliothèque sont relues une fois pour récupérer les noms corrigés.

## Les téléchargements déjà signalés comme échoués ne prennent plus de places de réparation aux nouveaux {#downloads-already-reported-failed-no-longer-take-repair-slots-from-new-ones}

Une fois que zurg signale à Radarr ou Sonarr qu'un téléchargement a échoué, le client le jette et en cherche un autre. zurg continuait pourtant à essayer de réparer ces téléchargements à chaque redémarrage, et ces réparations inutiles pouvaient occuper ses deux emplacements de réparation pendant qu'un nouveau téléchargement encore récupérable attendait. zurg arrête maintenant de réparer un téléchargement dès qu'il l'a signalé comme échoué.

## Les rapports de dommages nomment chaque fichier {#damage-reports-name-every-file}

Lorsqu'une release Usenet avait des morceaux manquants, le message d'échec de zurg listait les fichiers endommagés par leur nom, et un fichier que le post lui-même ne nommait pas apparaissait comme un vide : « across 4 file(s): , , , ». Ce type de fichier est désormais listé par sa place dans la release, par exemple « file 12 of 73 », afin que le message indique quels fichiers sont touchés.

## Stremio ignore une release dont la vidéo commence par du vide {#stremio-skips-a-release-whose-video-starts-with-nothing}

Quand le début de la vidéo d'une release Usenet n'est plus disponible sur les serveurs de news, zurg le remplissait de silence et le transmettait à Stremio comme si tout allait bien. Le lecteur n'affichait donc rien et le film semblait cassé. zurg vérifie désormais les premiers octets avant de lancer la lecture. S'il n'y a rien de réel à cet endroit, il passe à la release suivante de la liste, comme il le fait déjà pour une release sans aucun contenu lisible. Un film avec un trou plus loin dans la vidéo se lit toujours.

## Les fichiers cassés restent dans la bibliothèque alors que zurg continuera de les réessayer {#broken-files-stay-in-the-library-while-zurg-will-still-retry-them}

Lorsque zurg ne parvenait pas à réparer un fichier cassé dès la première tentative, il retirait le fichier du montage, même s'il devait réessayer le lendemain. Plex lit un fichier qui disparaît comme un fichier supprimé. Un seul scan de la bibliothèque pouvait donc envoyer des épisodes, des saisons et des séries entières à la corbeille. Désormais, un fichier cassé reste dans le montage tant que zurg prévoit une nouvelle tentative de réparation. Il n'en sort que lorsque zurg est certain que le contenu a disparu, par exemple lorsque le service refuse carrément la release ou qu'il ne reste rien de lisible dedans.

## Radarr et Sonarr relancent une recherche quand une release qu'ils ont prise deux fois est morte {#radarr-and-sonarr-search-again-when-a-release-they-grab-twice-is-dead}

Quand la première release que Radarr a récupérée s'est révélée morte, la recherche suivante a souvent repris la même release depuis un autre indexeur, sous le même nom. zurg a rangé ce second grab sous le job id du premier. Radarr et Sonarr gardent en mémoire chaque téléchargement qui a échoué avec cet id. Ils ont donc traité le nouveau grab comme l'ancien échec et ne l'ont jamais regardé à nouveau : pas d'échec, pas de blocklist, pas de nouvelle recherche. Le film s'est simplement arrêté. Lors d'un passage du IMDb Top 100 via Radarr, 25 films se sont terminés comme ça.

Un grab d'une release que zurg a déjà traitée pour l'instant reçoit désormais son propre job id, de la même façon que SABnzbd nomme chaque téléchargement. Quand cette release est morte elle aussi, Radarr reçoit le second échec, la met en blocklist et relance une recherche.

## Les releases Usenet mortes sont signalées comme échouées en quelques minutes au lieu de jusqu'à une demi-heure {#dead-usenet-releases-are-reported-failed-in-minutes-instead-of-up-to-half-an-hour}

zurg vérifie les articles d'une release récupérée avant de dire à Radarr ou Sonarr qu'elle est terminée, et il attend que les tailles des fichiers de la release se stabilisent avant de poser la question. Or un post mort est justement la release dont les tailles n'arrivent jamais. La vérification restait donc bloquée derrière une attente de trente minutes, pendant que le client attendait une réponse. Maintenant, quand zurg a essayé d'obtenir les tailles d'une release sans y parvenir, il vérifie tout de suite les articles. Une release dont les articles ont disparu est signalée comme échouée, pour que le client passe à une autre.

Une release trouvée endommagée pendant sa lecture était aussi mise en attente pendant cinq minutes pour une réparation PAR2, même avec `enable_repair: false`, alors qu'aucune réparation ne démarrait jamais. Cette attente est maintenant ignorée dès qu'aucune réparation ne peut tourner.

Dans un essai de l'IMDb Top 100 via Radarr, avec plus de la moitié des releases récupérées mortes, ces deux attentes représentaient la plus grande partie du temps qu'un film passait dans zurg.

## Une release qui s'avère endommagée pendant l'import est marquée comme échouée, pour que Radarr en prenne une autre {#a-release-that-turns-out-damaged-during-import-is-failed-so-radarr-grabs-another}

zurg vérifie un seul article par fichier avant d'indiquer à Radarr qu'une release est prête, donc une release avec un trou au milieu d'un fichier peut passer. Quand l'import de Radarr arrivait au trou, zurg refusait de déplacer le fichier, ce qui est normal, mais le téléchargement restait marqué comme inachevé au lieu d'échoué. Radarr mettait le film en "import blocked" et ne cherchait jamais une autre copie. Lors d'un test de l'IMDb Top 100 avec Radarr, cinq films se sont bloqués de cette façon.

Le refus d'import marque maintenant le téléchargement comme échoué. Radarr ajoute cette release à sa liste noire et cherche une autre release.

## Une release entièrement obfusquée ne produit plus un fichier vidéo sans nom {#a-fully-obfuscated-release-no-longer-comes-out-with-a-nameless-video-file}

Lorsqu'un post Usenet masque tous les noms de fichiers, zurg détermine lequel est le fichier principal à partir de ses premiers octets et le nomme d'après la release, comme le fait SABnzbd. Cette vérification intervenait en dernier lors d'un passage limité à quatre-vingt-dix secondes, et lorsque les récupérations arrivaient en rafale, cette limite pouvait être atteinte avant elle. Le fichier vidéo était alors publié sous le nom de la release, sans aucune extension, ce que Radarr et Sonarr ignorent. Le téléchargement restait donc dans leur file d'attente, en attente d'un fichier qu'ils pouvaient importer.

Une release est désormais renommée à nouveau, jusqu'à trois fois, tant que zurg n'a pas pu examiner le fichier. Ce n'est qu'ensuite qu'elle est affichée dans votre bibliothèque et dans vos *arr. Lors d'un test sur le Top 100 d'IMDb via Radarr, il s'agissait de Seven Samurai, un fichier .mkv de 42 Go.

## Les releases dont les noms de fichiers contiennent des accents ou du CJK gardent leurs noms complets {#releases-with-accents-or-cjk-in-their-filenames-keep-their-whole-names}

`Détective Conan S11E01 - 286
[MULTI] [AVC].mkv` est sortie de zurg sous le nom `tective Conan S11E01 - 286 [MULTI] [AVC].mkv`,
et un titre chinois ou japonais perdait encore plus, car tout ce qui précédait le dernier caractère de ce type était supprimé.

Sonarr et Radarr ne pouvaient rien faire avec ce qui restait. Un nom comme `tective
Conan S11E01` ne correspond à aucune série. Ils se sont donc rabattus sur l'historique des prises du téléchargement, ont refusé d'importer sur cette seule base, et ont mis l'élément de côté avec "release was matched to series by ID. Automatic import is not possible." La version est restée dans la file d'attente et rien ne l'a fait avancer.

Cela pouvait aussi vous coûter des fichiers. Quand la seule chose qui distingue deux fichiers se trouve après le dernier caractère accentué, les deux sortent avec le même nom, et un nom est un chemin. Une version française avec dix volumes de réparation avait ses dix fichiers ramenés au même nom. Seuls quatre fichiers ont été publiés alors que le post en contient treize, et les données de réparation n'avaient donc aucun moyen d'être atteintes.

zurg lit maintenant chaque caractère au-dessus de l'ASCII simple comme faisant partie du nom de fichier, ce qu'il a toujours été. Les compteurs de parties, le marqueur `yEnc`, les crochets et les extensions de fichiers que les posteurs utilisent sont tous en ASCII simple, donc tout le reste appartient au titre. Les versions nommées en ASCII simple ne sont pas affectées et sortent exactement comme avant.

Les versions déjà présentes dans votre bibliothèque gardent les noms sous lesquels elles ont été classées, car zurg ne revient pas sur une liste de fichiers qu'il a déjà enregistrée. Réajouter une version concernée récupère les noms corrigés.

(Une traduction précédente a été rejetée : les portées de code ne correspondent pas (` was served as `). Gardez la structure exactement.)

## Un nom écrit en japonais, coréen, chinois, thaï ou arabe est laissé tel quel {#a-name-written-in-japanese-korean-chinese-thai-or-arabic-is-left-alone}

zurg renomme un fichier dans une archive quand son nom ne dit rien sur son contenu. Une release publiée sous forme de hash arrive donc sous le nom propre de la release. Pour trancher, il fallait comparer majuscules et minuscules, alors qu'énormément d'écritures n'ont ni l'une ni l'autre. Un fichier nommé `오징어 게임 S01E01` comptait zéro de chaque, échouait au test d'un nom ordinaire et était renommé comme s'il s'agissait d'un hash, S01E01 compris. Les han, kana, Hangul, thaï, hébreu et arabe étaient tous touchés.

Une lettre sans majuscule ni minuscule clôt désormais la question au lieu de la faire échouer. Les noms de ces écritures sont conservés tels quels, et les hashes sont toujours renommés exactement comme avant.

zurg signale désormais aussi dans le log quand deux fichiers d'une même release finissent avec le même nom. Un nom est un chemin : quand cela arrive, la release propose discrètement moins de fichiers qu'elle n'en contient, et les fichiers en trop ne peuvent pas du tout être ouverts. Rien ne le signalait avant, ce qui explique pourquoi le bug des noms de fichiers accentués de l'entrée précédente était passé inaperçu : la seule trace était un listing de dossier avec moins de lignes que prévu.

## Les corrections de noms de fichiers s'appliquent maintenant aux releases que vous avez déjà {#the-filename-fixes-now-reach-releases-you-already-have}

Les deux entrées ci-dessus ont changé la façon dont zurg lit le nom de fichier dans un post Usenet. Mais zurg garde le résultat de la lecture de chaque NZB et le réutilise à chaque démarrage, au lieu de reparcourir tout votre dossier surveillé. Ces résultats stockés étaient donc encore les anciens. Après la mise à jour, une release que vous aviez déjà affichait toujours le même mauvais nom qu'avant. Seul un NZB ajouté récemment avait reçu le nom corrigé.

zurg remarque désormais qu'il lit les posts différemment de la façon dont les résultats stockés ont été écrits, et il les relit. Le premier démarrage après la mise à jour relit une fois chaque NZB de votre dossier surveillé. Ça prend un peu plus de temps que d'habitude, puis tout revient à la normale. Rien n'est retéléchargé et aucun article n'est récupéré : zurg relit seulement des fichiers déjà présents sur votre disque.

Si une release était touchée, ses fichiers reviennent sous les noms que le post leur donnait. Votre client de téléchargement garde peut-être encore l'import échoué d'avant. Une release bloquée depuis un moment dans Sonarr ou Radarr, incapable d'être importée, doit donc être retirée de la file d'attente pour pouvoir être réessayée.

## Les titres contenant de la ponctuation gardent aussi leurs noms complets {#titles-with-punctuation-in-them-keep-their-whole-names-too}

Le correctif des noms de fichiers plus haut dans cette liste a empêché zurg de couper les noms aux caractères accentués et
chinois. Ça n'allait pas assez loin. zurg décidait de ce qu'était un nom de fichier en listant les caractères autorisés, et
cette liste ne contenait pas vingt signes courants, donc un titre en contenant un était coupé à cet endroit exactement de la même
façon :

    Tom & Jerry - The Movie.1992.1080p.mkv   ->   Jerry - The Movie.1992.1080p.mkv
    Mairimashita! Iruma-kun (2026) [22].mp4  ->   Iruma-kun (2026) [22].mp4

`!`, `&`, `#`, `$`, `%`, `@`, `~`, `;`, `=` et `^` ont tous fait ça.

Vouloir lister les caractères qu'un titre peut contenir est une partie perdue d'avance, donc zurg n'essaie plus. Un nom est un
nom de fichier, et les seuls caractères qui ne peuvent certainement pas y figurer sont ceux qu'aucun système de fichiers
n'accepte : `/ \ : * ? " < > |`. Tout le reste fait désormais partie du titre.

Vérifié sur chaque NZB d'un grand dossier de surveillance : parmi les sujets qui sont un simple nom de fichier, presque tous
ceux qui étaient raccourcis avant ce changement gardent maintenant leur nom complet, et les seuls encore raccourcis sont ceux
dont on retire le tampon par téléchargement ajouté par l'indexeur, ce qui est bien le comportement attendu.

## Une release dont les fichiers ont été renommés récupère les nouveaux noms toute seule {#a-release-whose-files-were-renamed-picks-the-new-names-up-on-its-own}

Les corrections de noms de fichiers ci-dessus ont changé les noms que zurg donne aux fichiers d'une release Usenet, mais une release déjà présente dans ta bibliothèque ne l'a pas toujours remarqué. zurg compare une release qu'il connaît déjà avec une nouvelle liste, en se basant sur le lien qu'il a enregistré pour chaque fichier. Or un lien Usenet contient la position du fichier dans la release. Quand un nom corrigé se trie différemment de l'ancien, cette position change, le lien enregistré ne pointe plus vers le même fichier, et il ne reste rien pour faire la correspondance. L'ancien nom est donc resté.

zurg se rabat maintenant sur la taille du fichier, qui ne change pas. Quand exactement un fichier de la release a cette taille, c'est lui et son nom est mis à jour. Quand deux fichiers ont la même taille, rien n'est renommé, pour ne pas deviner et ranger un épisode sous le nom d'un autre.

Les releases dont la position n'a pas bougé utilisaient déjà les nouveaux noms et ne sont pas concernées. Il en va de même pour tous les backends autres que Usenet, dont les liens ne bougent pas quand un fichier est renommé.

## Un fichier que le montage ne peut pas lire ne bloque plus tout le reste {#a-file-the-mount-cannot-read-stops-holding-everything-else-up}

Quand une lecture échouait pour une raison que zurg ne pouvait pas identifier, il disait au client de réessayer, et continuait à le dire tant que le fichier échouait. rclone prend cela très au sérieux : une seule lecture de ce fichier prenait 55 secondes et trois douzaines de requêtes avant d'abandonner. Comme rclone ralentit toute sa connexion vers un serveur qui renvoie sans cesse des erreurs, le fichier sain suivant mettait 3,66 secondes à s'ouvrir au lieu de 0,04.

Désormais, les nouvelles tentatives s'arrêtent au bout d'une minute du même échec. La lecture reçoit la même réponse que celle qu'on obtenait déjà pour un fichier cassé, le fichier garde sa place dans la liste de votre bibliothèque, et la même lecture prend une demi-seconde.

zurg tente toujours le téléchargement à chaque fois, donc un fichier qui revient est repris par la lecture suivante.

## Le montage arrête de télécharger dès que vous arrêtez de lire {#the-mount-stops-downloading-once-you-stop-reading}

Un scan de bibliothèque, une vérification des sous-titres ou toute autre opération qui touche brièvement beaucoup de fichiers téléchargeait bien plus depuis votre compte debrid que ce qu'elle lisait.

rclone 1.74 a commencé à continuer le téléchargement d'un fichier pendant cinq secondes après que le dernier programme l'a fermé. Rien n'attendait ces octets, et sur un compte rapide, cinq secondes représentent quelques centaines de mégaoctets par fichier. La lecture de 1 MiB dans chacun de vingt fichiers téléchargeait 4.2 GiB, alors qu'avant elle n'en téléchargeait que 80 MiB.

zurg désactive maintenant cela. Les montages avec rclone 1.73 et les versions antérieures ne sont pas concernés et restent inchangés, car l'option n'existe pas dans ces versions.

Si vous utilisez votre propre rclone au lieu du montage de zurg, ajoutez `--vfs-handle-caching 0` à votre commande de montage avec rclone 1.74 ou plus récent. Le README explique cela.

## Une release qui perd un volume d'archive ne perd plus le reste {#a-release-that-loses-one-archive-volume-no-longer-loses-the-rest}

Les releases Usenet publiées sous forme de jeu rar ou 7z en plusieurs parties pouvaient ne plus jamais s'importer. Sonarr et Radarr restaient bloqués sur "Waiting for import" sans jamais en sortir, et le dossier de la release finissait par ne contenir que les parties rar, ou disparaissait complètement.

Quand zurg ne parvenait pas à lire un volume d'un jeu, il mettait ce volume de côté et laissait le listing suivant se faire sans lui. Ce listing trouvait donc le jeu avec un volume de moins, s'arrêtait au volume situé juste après et le mettait de côté lui aussi. Une release perdait ainsi ses volumes un par un, à peu près un toutes les dix minutes, et une fois qu'il n'en restait plus, elle disparaissait de la bibliothèque et du dossier dans lequel le client de téléchargement importe. Pour Sonarr, un chemin qui n'existe pas n'est pas un dossier vide : c'est un import qui échoue pour toujours.

Un volume connu pour être illisible reste maintenant dans son jeu. Chaque listing s'arrête au même volume et dit la même chose à son sujet, donc une release à laquelle il manque une partie de sa publication est signalée comme telle une seule fois, et ton client peut la mettre sur la blocklist et chercher une autre copie. Les releases dont tous les volumes sont lisibles ne sont pas concernées.

## Les scans suivent la bibliothèque dans son nouvel emplacement sous `__magic__` {#scans-follow-the-library-into-its-new-home-under-__magic__}

Le miroir de ta bibliothèque est passé de `__magic__` à `__magic__/__all__` dans la version 2026.09.17.2240-nightly. Une partie de zurg continuait à utiliser l'ancien emplacement.

Quand une nouvelle version arrivait, le scan que zurg demandait à Plex ou Jellyfin visait un dossier qui n'existait plus depuis cette version. Rien n'était donc mis en file d'attente, et le nouveau contenu attendait le scan planifié du serveur multimédia. Ceux qui utilisaient un script `on_library_update` recevaient le même chemin.

Les deux désignent désormais le dossier depuis lequel ton client de téléchargement a reçu l'ordre d'importer. C'est aussi le cas de la liste que zurg supprime du cache du montage quand une version arrive ou disparaît.

## La watchlist peut maintenant prendre des torrents, depuis les indexeurs Torznab {#the-watchlist-can-take-torrents-now-from-torznab-indexers}

Jusqu'à présent, une watchlist ou une demande Seerr ne pouvait être satisfaite qu'à partir de Usenet. Ajoutez `type: torznab` à un indexeur et zurg le fouillera aussi. Un résultat torrent est alors confié à un compte debrid au lieu d'être écrit dans `nzbs/`.

**Il n'est jamais confié qu'à un compte qui l'a déjà en cache.** Chaque compte qui accepte les ajouts reçoit le hash, car les caches sont indépendants, et le premier qui possède déjà la release la prend. Un échec partout signifie simplement que ce candidat n'a pas abouti : zurg passe alors à la release suivante, qui peut être un autre torrent ou un NZB. Rien n'est téléchargé sur votre compte, aucun quota d'ajout non mis en cache n'est consommé, et rien ne reste en cours d'exécution pour quelque chose que personne n'attend.

Quand les deux types d'indexeurs peuvent répondre, `prefer` détermine celui qui est sollicité en premier. Par défaut, c'est `usenet`, donc une installation qui n'avait que des indexeurs Newznab se comporte exactement comme avant. `torrents` inverse l'ordre, et `best` prend ce que le classement place en tête, torrent ou non.

Une prise de torrent attend d'être vérifiée comme les autres, mais on lui pose une question différente. Le compte a déjà indiqué qu'il possède le contenu, donc ce qu'on vérifie, c'est que la release est bien arrivée dans votre bibliothèque avec des fichiers. Si elle apparaît vide, elle est écartée pour que la release suivante ait sa chance.

Vous pouvez aussi faire fonctionner l'acquisition avec des indexeurs Torznab seuls, sans fournisseur `nzb`.

## Un agent qui lit la bibliothèque ne considère plus chaque release comme vide {#an-agent-reading-the-library-no-longer-calls-every-release-empty}

Les listings MCP de zurg ne mesurent la taille d'une release que lorsqu'on le leur demande, car parcourir la table des fichiers de toute une bibliothèque prend du temps. Pour les releases qu'ils n'avaient pas mesurées, ils indiquaient la taille et le nombre de fichiers à zéro, et rien dans la réponse ne disait au lecteur que zéro voulait dire « non mesuré » et non « rien là ». Un agent à qui l'on demandait de lister un dossier affirmait qu'un film de 6.6 GB ne contenait aucun fichier, alors que l'outil pour une seule release donnait la bonne réponse depuis le début.

Un listing qui n'a pas mesuré omet maintenant les deux chiffres au lieu d'afficher zéro. Demandez-les avec `with_size`, en triant par taille, ou avec un filtre de taille. `zurg_library_search` accepte aussi `with_size`, ce qui n'était pas possible avant : obtenir les tailles ne vous fait donc plus perdre un résultat filtré ou réordonné.

## zurg doctor indique si le point de terminaison MCP répond {#zurg-doctor-says-whether-the-mcp-endpoint-is-answering}

`zurg doctor` vérifiait que le port du tableau de bord répondait, et s'arrêtait là, ce qui ne dit rien sur `/mcp`. Un endpoint que la config active mais que le serveur refuse ensuite de servir, c'est ce qui se passe quand `username` est vide. Vu de l'extérieur, il avait l'air en bonne santé, et la seule explication se trouvait en une ligne du journal de démarrage, nulle part ailleurs.

Quand `mcp.enabled` est activé, `doctor` parle maintenant le protocole avec `/mcp` et indique ce qu'il a reçu : une réponse, un refus des identifiants configurés, ou un endpoint activé mais non servi. Une instance avec l'endpoint désactivé n'est pas interrogée à ce sujet et n'affiche aucune ligne.

## Ouvrir le point de terminaison MCP dans un navigateur indique maintenant ce que c'est {#opening-the-mcp-endpoint-in-a-browser-now-tells-you-what-it-is}

Ouvrir `/mcp` dans un navigateur renvoyait « Bad Request: GET requires an Mcp-Session-Id header », ce qui est une réponse exacte à une question que personne n'a posée.
Le point de terminaison se décrit désormais lui-même lorsqu'un navigateur l'ouvre : ce qu'il parle, l'adresse à indiquer à un client, l'extrait pour le pont stdio, la version de build utilisée, et chaque outil qu'il propose actuellement, regroupé par toolsets et signalé lorsqu'un outil décrit ce qu'il ferait et attend une confirmation.

Cette liste est ce que l'enregistrement a réellement produit, et non une seconde copie tenue à la main. Ainsi, un outil retiré par `read_only`, par vos toolsets ou par l'interrupteur de cycle de vie n'est pas présenté comme un outil que vous pouvez appeler. La page le signale aussi lorsque le point de terminaison est servi sans authentification.

Aucun client n'est touché. La page n'est servie qu'à une requête GET qui demande du HTML et ne porte aucune session, ce qui correspond à un navigateur et jamais à un client MCP. Le GET propre à un client continue d'ouvrir le flux d'événements exactement comme avant.

## La lecture Usenet remplit plus vite le quota de connexions {#usenet-playback-fills-the-connection-allowance-sooner}

Les lectures Usenet placent maintenant l'article à la tête de lecture dans le planificateur du compte avant de proposer le reste de la plage demandée. Quand une grande plage est répartie sur plusieurs connexions en pipeline, les articles consécutifs sont distribués entre ces connexions, au lieu de donner à la première connexion les quatre premiers, à la deuxième les quatre suivants, et ainsi de suite. Les premiers articles utiles reviennent donc dès le premier tour de connexions, sans attendre les octets suivants.

Les posts d'archives avec de petits articles ont une fenêtre de lecture anticipée d'au moins 64 MiB. Les posts modernes avec des articles de plusieurs mégaoctets gardent leur fenêtre existante. Le nombre plus élevé d'articles n'augmente pas l'utilisation de la mémoire : les corps spéculatifs sont limités à deux lecteurs et à la moitié de `cache_size_mb` (256 MiB par défaut), tandis que le cache d'articles garde sa limite stricte actuelle. Les requêtes de la taille d'une lecture commencent désormais à 64 MiB au lieu de 128 MiB, donc un tampon de lecteur de 90 MiB ne passe plus par le chemin de seek/sondage ; les petits seeks, eux, y passent toujours.

Un lot en pipeline bloqué peut maintenant demander jusqu'à cinq articles distincts en même temps. La limite du compte, de vingt demandes de seconde par minute, ne change pas, et la lecture anticipée, les réparations et les autres tâches dont aucun client n'attend le résultat ne sont toujours jamais dupliquées.

L'ouverture des archives multi-volumes est aussi moins coûteuse. Quand PAR2 a déjà fourni la longueur exacte de chaque volume, l'en-tête yEnc vérifié d'un seul volume peut fournir le pas commun des articles pour un grand ensemble de volumes voisins. Chaque volume voisin vérifie cette déduction avec son propre en-tête avant de servir son premier octet, si bien que la résolution ne paie plus un article en série par volume, sans jamais faire confiance à la géométrie déduite pour les données. La récupération des noms de fichiers répond elle aussi à partir de l'en-tête yEnc, au lieu d'attendre que le reste de cet article soit téléchargé.

## Les fichiers .strm enregistrés suivent un changement d'URL de base {#saved-strm-files-follow-a-base-url-change}

Changer Base URL laissait tous les `.strm` déjà présents dans `strm/` pointer vers l'ancienne adresse, et redémarrer ne changeait rien, parce que zurg ne réécrivait que les fichiers manquants. Désormais, un `.strm` dont l'URL diffère de celle que zurg écrirait est réécrit sur place. Cela se produit à chaque démarrage, et tout de suite quand Base URL est modifié sur le tableau de bord ou quand `save_strm_files` est activé là-bas. Les fichiers déjà corrects sont laissés tels quels, pour qu'un serveur multimédia ne relise pas tout le dossier à chaque analyse.

Jellyfin conserve l'URL qu'il a lue dans un `.strm` et prend la nouvelle lors de sa prochaine analyse de bibliothèque. Un `.strm` contenant encore un lien de compte d'une version plus ancienne est lui aussi réécrit, dans la forme qui bascule entre les comptes et survit aux réparations. Un `.strm` modifié à la main dans `strm/` est écrasé, donc réglez Base URL sur l'adresse voulue.

## Activer la watchlist Plex ne la vide plus {#turning-the-plex-watchlist-on-no-longer-empties-it}

Activer la watchlist faisait lire toute votre liste comme un arriéré à traiter, et zurg supprimait chaque titre au fur et à mesure. Un premier lancement a retiré 121 titres sur une liste de 163 éléments en environ quatre minutes. Plex ne garde aucune trace d'une entrée de watchlist supprimée, donc le seul moyen de revenir en arrière était un instantané pris au préalable, et rien dans la config ni dans les logs ne laissait prévoir ce qui allait se passer.

Deux réglages déterminent désormais ce que l'acquisition fait à la liste, et cette liste vous appartient, pas à zurg.

**`watchlist.only_new_items`** est activé par défaut. Activer la watchlist commence maintenant par la surveiller. Tout ce qui est déjà sur la liste est considéré comme traité, et ce que vous ajoutez ensuite est acquis. Cela ne s'applique qu'une seule fois, au premier lancement, et jamais sur une file d'attente existante : une installation qui traite déjà une watchlist continue donc exactement comme avant.

**`watchlist.remove_after_grab`** est activé par défaut, ce que la fonctionnalité faisait déjà depuis toujours. Rien ne change pour vous tant que vous ne le demandez pas. Désactivez-le pour que votre watchlist reste une watchlist. Elle reste une liste que vous parcourez pour décider quoi regarder, et zurg la satisfait en arrière-plan sans jamais la modifier. Un titre laissé en place ne coûte rien à revérifier : le reçu le couvre déjà et aucun indexeur n'est interrogé à nouveau à son sujet.

Les deux se trouvent sur la page de configuration et prennent effet au prochain redémarrage. Une source d'acquisition que vous détaillez sous `acquisition.sources` peut les définir pour chaque source. Elles n'ont aucun effet sur une source Seerr, car elle ne possède aucune liste dans laquelle zurg écrit.

## La watchlist et les demandes Seerr attendent les serveurs de news avant d'être effacées {#watchlist-and-seerr-requests-wait-for-the-news-servers-before-they-are-cleared}

Avant, un grab était considéré comme terminé dès que son NZB arrivait dans le watch directory. L'indexeur répondait, la réponse était lue comme un NZB et le fichier était écrit. Ça fait trois infos sur l'indexeur et aucune sur le post. La demande était ensuite clôturée sur la foi de ces infos, ce qui, pour une watchlist Plex, veut dire que l'entrée est supprimée, et Plex ne garde aucune trace d'une entrée supprimée. Un post mort faisait donc disparaître le seul indice que tu voulais ce titre, avant même que quoi que ce soit ait lu le moindre octet. Une passe sur une watchlist de 163 éléments a supprimé 121 titres, et 12 des releases associées étaient illisibles.

Chaque release récupérée est maintenant testée sur les serveurs news avant que quoi que ce soit ne soit validé, le même contrôle que l'endpoint SABnzbd fait depuis la nightly du 08.28. Il y a trois réponses, et elles sont bien séparées.

- **Les articles ont disparu.** Le grab ne compte pas. Le titre reste dans ta watchlist, la demande reste ouverte, et la release est notée comme morte pour que la tentative suivante passe au candidat suivant au lieu de se rabattre sur celui déjà présent dans ta bibliothèque. Une release connue comme morte ne coûte rien du tout. Elle n'est pas téléchargée et ne prend pas la place d'un des trois candidats d'une tentative, donc une série de posts morts en tête de classement est parcourue au lieu d'être réessayée indéfiniment. Un pack de saison trouvé mort remet toute la saison en attente, pour que les épisodes isolés soient récupérés à la place.
  
- **Les serveurs n'ont pas pu être interrogés.** Un pool hors ligne, un compte limité en débit, ou simplement une bibliothèque qui n'a pas encore listé le nouveau NZB. Rien n'a été établi, donc rien n'est décidé. La demande attend et est retentée, et attendre ne consomme aucune tentative. Une release qui ne peut toujours pas être vérifiée après environ deux heures est mise de côté comme une morte, et la release suivante a son tour. Le titre n'est jamais clôturé sur une release que personne n'a pu vérifier.

- **La release est là.** Exactement comme avant.

Une installation sans compte Usenet n'a rien à interroger et n'est pas affectée.

## Vérifier une grosse release ne manque plus de temps sur un serveur de news lent {#checking-a-big-release-no-longer-runs-out-of-time-on-a-slow-news-server}

Avant qu'un grab soit signalé comme terminé, zurg demande aux serveurs de news des informations sur chaque fichier qu'il contient. Il le faisait un fichier à la fois. Certains comptes répondent à ces questions lentement et strictement l'un après l'autre, donc les envoyer toutes en même temps sur une seule connexion n'irait pas plus vite. Le serveur d'un fournisseur mettait plus de cinq secondes par fichier, ce qui faisait environ douze minutes de questions pour une release 4K de 133 volumes, alors que chaque vérification est limitée à cinq minutes. La vérification ne pouvait donc jamais se terminer : Sonarr et Radarr attendaient trois heures, puis voyaient le grab échouer, et la watchlist attendait indéfiniment.

Les fichiers sont maintenant interrogés plusieurs à la fois, en utilisant toutes les connexions de ton compte sauf celle réservée à la lecture. Plus ton compte autorise de connexions, plus vite une grosse release est vérifiée. Comparée à la même release de 133 volumes qui ne pouvait jamais être vérifiée auparavant : moins de deux minutes avec douze connexions. Avec quatre connexions, le délai est toujours dépassé, car ce sont les questions elles-mêmes qui prennent du temps. Une petite release n'est pas plus lente qu'avant.

Une release que la vérification ne parvient pas à traiter à temps ne bloque plus le titre. La watchlist la met de côté comme elle le fait pour une release morte et essaie la release suivante. Le point d'accès SABnzbd la signale en échec, comme il l'a toujours fait, si bien que Sonarr et Radarr vont en chercher une autre.

## Les ajouts en mode cache seul sur TorBox ne téléchargent plus les releases qu'ils devaient ignorer {#cached-only-grabs-on-torbox-no-longer-download-the-releases-they-were-meant-to-skip}

TorBox a une option qui fait refuser à un ajout tout ce qu'il ne possède pas déjà. Elle existe dans leur API, mais nulle part dans leur documentation, et zurg ne l'utilisait pas. Un téléchargement en cache uniquement ajoutait donc le torrent, attendait de voir s'il se terminait, puis le supprimait quand il s'avérait être un vrai téléchargement. Cela consommait un des soixante ajouts horaires du compte, occupait un emplacement de transfert et récupérait des données pour une release que le *arr avait déjà demandé d'ignorer.

Les téléchargements en cache uniquement demandent maintenant le contenu et sont refusés en moins d'une seconde si TorBox ne l'a pas, sans rien laisser sur le compte. Un échec coûte quand même un de ces soixante ajouts horaires, donc zurg continue de les espacer comme avant. Et un succès reste vérifié plutôt que cru sur parole : le cache de TorBox peut dire oui à un contenu qu'il n'arrive ensuite pas à servir, donc la release doit être terminée avant que zurg ne la signale.

## Les ajouts en mode cache seul sur Debrid-Link ne consomment plus le quota quotidien d'ajouts {#cached-only-grabs-on-debrid-link-no-longer-spend-the-daily-add-allowance}

Debrid-Link accepte un info hash nu aussi bien qu'un magnet, et n'ajoute le hash que lorsqu'il possède déjà le contenu. zurg envoyait un magnet, qui est une instruction de télécharger : chaque demande en cache uniquement qui échouait était acceptée, décomptée du quota de 50 ajouts non mis en cache par jour du compte et d'un de ses 20 emplacements de transfert, puis supprimée pour récupérer le quota. Avec cinquante échecs, le compte ne pouvait plus rien ajouter jusqu'à la réinitialisation quotidienne.

Les grabs en cache uniquement envoient maintenant le hash. Un élément absent du cache est refusé immédiatement, en un dixième de seconde environ, et ne touche pas au compte. Un *arr peut donc parcourir une longue liste de releases sans rien dépenser sur celles que personne n'a. Ça vaut aussi pour les grabs qui arrivent sous forme de fichier .torrent : ce fichier existe pour éviter à un service la recherche de métadonnées qu'un hash nu lui impose, et une question de cache n'en a pas besoin.

## Les blocages dus à la limite de débit de Debrid-Link ont de nouveau un délai de recul {#debrid-link-rate-limit-lockouts-are-backed-off-from-again}

Debrid-Link répond à son verrouillage par endpoint, d'une heure, avec un HTTP 503 et la raison dans le corps de la réponse. zurg considérait chaque 503 comme un service temporairement indisponible, il ne lisait donc jamais la raison et continuait de réessayer un endpoint qui avait déjà demandé d'attendre une heure. Il reconnaît maintenant ce verrouillage et reste à l'écart de cet endpoint jusqu'à ce qu'il soit levé.

## `__magic__` reflète maintenant votre bibliothèque dans `__magic__/__all__`, sa racine vous reste {#__magic__-now-mirrors-your-library-at-__magic____all__-leaving-its-root-to-you}

L'espace de noms reflétait autrefois `__all__` à sa propre racine, ce qui faisait que le dossier qu'un client de téléchargement importe était le même que celui où se trouve déjà chaque version. Un dossier racine de Sonarr ou Radarr devait être imbriqué *à l'intérieur* du dossier de téléchargement pour éviter les deux health checks que cette configuration déclenchait. Quant à une importation manuelle pointée sur le dossier de téléchargement, elle parcourait toute la bibliothèque à la recherche d'une seule version.

Le miroir a été déplacé d'un niveau plus bas. `__magic__/__all__` contient la bibliothèque telle que `__all__` la liste, et c'est le chemin que calculent désormais `sabnzbd.complete_dir` et `qbittorrent.save_path`. La racine de `__magic__` vous appartient : c'est là que vous placez les dossiers `tv`, `movies` et `anime` que vos \*arrs doivent utiliser. Les deux sont des dossiers frères, donc aucun des deux ne contient l'autre, et aucun client ne émet d'avertissement.

**Cela modifie les chemins.** Si vous avez défini `sabnzbd.complete_dir` ou `qbittorrent.save_path` à la main (le cas du mappage de conteneur), ajoutez `/__all__` à la fin. Si vous aviez pointé une bibliothèque Plex ou Jellyfin sur `__magic__` lui-même plutôt que sur un dossier à l'intérieur, ses chemins sont décalés d'un niveau : pointez-la sur `__magic__/__all__` ou sur le dossier dans lequel vous importez. Vos dossiers racines ne bougent pas, et rien de ce qui est stocké dans la table ne bouge non plus : les placements sont des chemins sous les dossiers que vous avez créés, et les tombstones sont indexées sur la version, donc une organisation existante reste intacte. Un grab déjà en cours au moment de la mise à jour porte l'ancien chemin et doit être relancé.

Rien ne peut être écrit dans `__magic__/__all__` : une ligne ajoutée là serait une seconde adresse pour une version qui en a déjà une, donc un MOVE, MKCOL ou DELETE visant ce dossier est refusé. Écrire *à l'intérieur* d'un dossier de version ne change pas, et c'est précisément là qu'un \*arr place le .nfo à côté d'un fichier qu'il a importé.

## Export Logs indique maintenant où sont passés vos liens et combien de temps ils durent {#export-logs-now-tells-you-where-your-links-went-and-how-long-they-last}

Export Logs essaie plusieurs hébergeurs de paste et te donne le premier qui accepte
le fichier. Il ne dit jamais lequel, et ils ne sont pas interchangeables : l'hébergeur
préféré garde un paste pendant 180 jours et le renouvelle à chaque fois que quelqu'un
le lit, alors que l'hébergeur de secours le supprime au bout de trois. Deux liens
qui se ressemblent, et un rapport déposé un vendredi s'était retrouvé avec deux liens
morts le lundi, sans rien pour expliquer pourquoi. Les liens viennent maintenant
avec l'hébergeur qui les héberge et la date limite qui va avec.

Si tu tombais sur l'hébergeur de secours, c'est à cause de la deuxième moitié de ceci. L'hébergeur
préféré bloque une adresse qui envoie plusieurs fichiers en peu de temps, et un export publie deux
fichiers à chaque clic. Une série de rapports de bugs a donc fait refuser l'adresse, et ensuite
toutes les requêtes venant de cette machine étaient refusées, y compris la relecture d'un paste
déjà enregistré. zurg a quand même envoyé les deux moitiés de chaque export suivant vers ce même
hébergeur et a journalisé chacune comme un envoi raté, ce qui pointait vers le fichier au lieu de
l'adresse. Un hébergeur qui refuse la machine est maintenant laissé de côté pendant un jour, et le
log indique que c'est ce qui s'est passé.

## Envoyer les infos de débogage ne publie plus vos clés d'indexeur et de client de téléchargement {#uploading-debug-info-no-longer-publishes-your-indexer-and-download-client-keys}

Export Logs masquait déjà chaque identifiant qu'il trouvait avant d'envoyer la configuration à un hébergeur de texte, mais il ne regardait que le premier niveau. Les clés placées dans les blocs imbriqués partaient en clair : les clés API de vos indexeurs Newznab, qu'il s'agisse de la liste Stremio ou de la liste watchlist, le jeton de l'addon Stremio, les clés API de SABnzbd et qBittorrent, le jeton de compte zrok et le jeton de scan Plex. Les clés des indexeurs sont le point le plus sensible : ce sont vos accès à votre compte Usenet, pas ceux de zurg.

Elles sont désormais masquées. Les jetons des fournisseurs et les mots de passe des serveurs de news n'ont jamais été concernés.

## zurg peut être piloté par un agent IA {#zurg-can-be-driven-by-an-ai-agent}

Un nouvel endpoint sur `/mcp` parle le Model Context Protocol. Un client comme Claude peut donc chercher dans la bibliothèque, comprendre pourquoi une release ne se lit pas, et la réparer, à l'aide d'outils typés plutôt qu'en lisant le HTML du tableau de bord.

Il est désactivé par défaut. Active-le avec `mcp: {enabled: true}` et pointe un client vers `http://your-zurg:9999/mcp` avec le même nom d'utilisateur et mot de passe que ceux du tableau de bord. Les clients qui ne parlent que stdio utilisent `zurg mcp`, qui se connecte à l'instance déjà en cours d'exécution au lieu d'en lancer une seconde.

En plus des outils, il expose la documentation de zurg et son état en direct sous forme de ressources que le client peut lire directement, ainsi que six prompts pour les procédures qu'il vaut la peine de suivre à la lettre : diagnostiquer une release qui ne se lit pas, préparer un scan Plex en toute sécurité, trier ce que la réparation a abandonné.

Il sait ce qu'il ne doit pas faire en silence. Toute action qui supprime quelque chose décrit d'abord ce qu'elle ferait et n'agit que lorsque tu confirmes ce plan exact. `read_only: true` masque tous les outils qui modifient quoi que ce soit, et les outils capables d'arrêter zurg ou son montage restent derrière leur propre interrupteur. Aucun résultat ne contient de jeton, de mot de passe ni de lien résolu.

Voir [le serveur MCP](mcp.md).

## zurg indique quand votre build est périmée {#zurg-says-when-your-build-is-out-of-date}

Rien dans zurg n'indiquait jusqu'ici l'âge d'un build. C'est pour ça qu'un bug corrigé en août a pu être signalé en septembre, alors que le correctif avait déjà trois semaines, et que personne dans le fil n'avait de raison de s'en douter. Maintenant, une fois par jour, zurg demande au dépôt public sa dernière release et, si ton build est plus ancien, affiche une seule ligne avec le nom de la release, sa date et la tienne. Le reste du temps, il reste silencieux : rien ne s'affiche si tu es à jour, rien ne s'affiche si GitHub est injoignable, et un build qui ne sait pas quand il a été créé, c'est-à-dire l'image Docker, n'est pas deviné. Les sponsors sur un nightly sont toujours en avance sur la dernière release publique, donc ils ne la voient jamais. La réponse est mise en cache pendant un jour, pour qu'un redémarrage ne coûte aucune requête. Un refus n'est pas réessayé avant le lendemain, et tout le système se désactive avec `disable_update_check: true`.

## Un lien mort dans une release archivée n'est plus déclaré sain à chaque passage {#a-dead-link-inside-an-archived-release-stops-being-declared-healthy-every-sweep}

Quand une release est servie comme une seule archive et que la réparation ne peut pas réduire davantage un re-ajout, zurg vérifie si l'archive elle-même se lit encore et, si c'est le cas, lève les marques d'erreur sur la release au lieu de la condamner. Il les a toutes levées, y compris celles sur les fichiers que le compte adresse directement avec leurs propres liens. Un lien d'archive vérifié prouve que l'archive se lit, et ne prouve rien du tout sur ces fichiers. Ainsi, un fichier dont le compte avait cessé de servir le lien a été remis en bonne santé sur la base d'une lecture sans rapport. Le sweep suivant l'a débridé et l'a retrouvé mort, la release a de nouveau été condamnée, et la passe qui l'avait condamnée s'est terminée en le restaurant à nouveau. Sur une release de 64 fichiers avec 9 liens que le compte avait cessé de servir, cela s'est produit 111 fois en une semaine, deux fois dans les mêmes 40 secondes, avec deux ajouts de magnet par passe. La grâce ne couvre désormais que les fichiers que l'archive sert réellement, c'est-à-dire ceux qui n'ont pas de lien propre. Un fichier que le compte adresse garde le verdict que son propre lien a obtenu et part en réparation, seul chemin capable de lui en fournir un qui fonctionne.

## Les téléchargements qui n'arrivent que partiellement ne restent plus éternellement dans la file {#downloads-that-only-partly-arrive-no-longer-sit-in-the-queue-for-ever}

Quand certains fichiers d'une release ne pouvaient pas être lus, zurg gardait son téléchargement dans la file d'attente en attendant les tailles exactes des fichiers, qu'il n'allait jamais obtenir. La vérification qui aurait trouvé le problème ne se lançait qu'une fois ces tailles arrivées. Sonarr et Radarr affichaient un tel téléchargement à 0 % sans temps restant, tant que zurg tournait, et ne mettaient jamais la release sur liste de blocage ni ne cherchaient une autre release.

zurg interroge désormais les serveurs de news au sujet d'une release qui attend depuis trente minutes. Si ses articles ont disparu, ou si les serveurs n'ont pas pu être interrogés du tout, il signale le téléchargement comme échoué. Une release dont les tailles sont vraiment encore en route n'est pas touchée et reste retenue jusqu'à leur arrivée.

## Une release abandonnée par un compte peut être réparée avec un autre {#a-release-one-account-gave-up-on-can-be-repaired-from-another}

Les services debrid gardent chacun leur propre cache. Une release que Real-Debrid a purgée, ou qu'il refuse à cause du seul nom de fichier, peut très bien être en cache sur AllDebrid en ce moment, sous le même hash. Jusqu'ici, zurg ne pouvait pas en profiter. La réparation réajoutait toujours une release au compte d'où elle venait. Du coup, une fois ce compte à bout, il ne restait plus rien à essayer, et la release restait morte dans ta bibliothèque alors qu'un autre compte que tu paies déjà la détenait.

Maintenant, une release que tous les comptes qui la détiennent ont abandonnée est proposée à tes autres comptes. Le premier qui l'a déjà prend la release, et elle revient avec les deux comptes derrière elle, en basculant de l'un à l'autre comme pour toute release détenue par deux comptes. Rien à activer : si tu as un second compte configuré et que la réparation est activée, c'est ce que fait la réparation quand elle n'a plus d'autre option.

Un compte ne reçoit jamais que du contenu qu'il possède déjà. S'il devait aller chercher la release, l'ajout est annulé et supprimé aussitôt, donc rien ne se télécharge et aucun quota de transfert n'est consommé. Un compte qui répond non est recontacté un jour plus tard, puis deux jours après, puis quatre, jusqu'à une quinzaine environ. Ainsi, une release disparue pour de bon ne coûte rien à continuer d'interroger.

## Les ajouts en mode cache seul sont jugés par votre compte, et non par une recherche dans le cache {#cached-only-grabs-are-judged-by-your-account-not-by-a-cache-lookup}

En mode cached-only, zurg demandait avant à TorBox, Premiumize et Offcloud si une release était dans leur cache, et renvoyait cette réponse telle quelle à Sonarr. Ces endpoints répondent à une question différente de celle posée. Ils disent que le contenu se trouve dans le cache du service, pas qu'il finit dans ton compte, et personne ne regardait le torrent ensuite. Un oui qui se transformait en téléchargement arrivait à Sonarr comme un grab instantané qu'on venait de lui promettre, alors que c'est justement ce que le mode cached-only est censé empêcher.

Maintenant, tous les comptes sont jugés de la même façon. Le torrent est ajouté, l'instance est surveillée, et seul celui qui termine dans la fenêtre compte comme cached. Le reste est supprimé et le grab est refusé, ce qui fait passer Sonarr à la release suivante de sa liste. Le coût : un échec sur ces trois services consomme maintenant un slot d'ajout, alors qu'une simple recherche dans le cache n'en consommait aucun.

## Une clé de secours AllDebrid ne répond plus pour votre bibliothèque {#an-alldebrid-backup-key-no-longer-answers-for-your-library}

`download_tokens` sur un compte AllDebrid, ce sont des comptes AllDebrid séparés, gardés pour leur quota de téléchargement. Une fois que la clé propre au compte avait atteint sa limite et était sortie de la rotation, chaque autre appel partait aussi avec la clé de secours : la liste des magnets, la liste des fichiers d'une release, les ajouts, les suppressions, les redémarrages, les liens enregistrés derrière `__downloads__` et la sonde de détection des changements. Du coup, le rafraîchissement de la bibliothèque pouvait lister les magnets du compte de secours et les adopter comme s'ils étaient les vôtres, une suppression pouvait être envoyée à un compte qui n'avait jamais eu ce magnet et revenir en disant qu'il avait déjà été supprimé, et une fois toutes les clés plafonnées, le catalogue disparaissait complètement à cause d'une simple limite sur les octets. Maintenant, seul le déverrouillage d'un lien fait tourner les clés. Tout ce qui concerne votre compte est demandé à votre compte.

## Une release saine n'alterne plus entre la liste Broken et le reste {#a-healthy-release-stops-flapping-in-and-out-of-the-broken-list}

Une release dont le compte propose toujours un seul lien mort pouvait se retrouver dans la liste Broken pendant la moitié de chaque heure, alors que chaque fichier de la release lisait parfaitement. La réparation retire un lien qui a répondu `hoster_unavailable` pendant trois cycles, pour pouvoir réadresser la release à la place, et elle se souvient de ce retrait pour que la liste suivante ne puisse pas nous ressortir ce lien mort. Or ce souvenir était effacé par la mauvaise chose : toute réparation réussie effaçait la mémoire, y compris les passes qui ne créent rien et qui vérifient seulement que l'adressage déjà présent dans l'entrée fonctionne toujours. « L'archive qui le sert fonctionne toujours » est le cas extrême : cela prouve que le seul lien qui sert la release marche, et ne dit absolument rien d'un lien que le compte a refusé. Donc l'abandon était oublié, le rafraîchissement suivant reprenait le même lien mort, la réparation n'arrivait pas à lui réassigner une adresse et condamnait de nouveau l'entrée, et ce cycle de trente minutes ne pouvait jamais se terminer. Mesuré sur une bibliothèque en production pendant trois jours : une seule release a été re-condamnée 129 fois, soit 556 condamnations sur toute la bibliothèque en une semaine, et chaque cycle dépensait deux à quatre ajouts de magnet. Désormais, seule une réparation qui réadresse vraiment la release oublie un abandon. Et une réparation manuelle oublie toujours tous les abandons, pour qu'un opérateur puisse rendre un lien à la main.

## Une version livrée en une seule archive n'est plus marquée comme cassée à chaque passage {#a-release-served-as-one-archive-is-no-longer-marked-broken-every-sweep}

Certaines releases sont servies sous forme d'une seule archive : le `.rar` porte l'unique lien du compte, et chaque épisode à l'intérieur est listé comme un fichier à part, sans aucun lien nulle part. La passe de réparation a quand même interrogé le compte au sujet de ces fichiers internes. Il n'y avait rien pour interroger, donc aucun compte n'a été consulté et rien n'a été mesuré. Pourtant la réponse est revenue : « file is broken ». La passe l'a écrite sur chaque fichier et s'en est servie pour condamner toute la release. La suite a coûté deux ajouts de magnet. Le compte a été interrogé uniquement pour les fichiers cassés, il a répondu avec le même lien d'archive unique qu'il avait toujours eu, et le repli sur l'archive a alors vérifié ce lien et restauré chaque fichier qui venait d'être condamné. Mesuré sur une bibliothèque en direct : 44 épisodes d'une seule archive de 4.9 GB passaient par ce cycle toutes les demi-heures. Un fichier pour lequel aucun compte ne détient de lien est désormais laissé tranquille, et le fichier de l'archive elle-même est jugé exactement comme avant. Quand le lien qui sert réellement la release cesse de se résoudre, ce fichier passe en cassé, et la release avec lui.

## Le trafic repasse sur le jeton de votre propre compte une fois que son quota est réinitialisé {#traffic-goes-back-to-your-own-accounts-token-once-its-allowance-resets}

Un compte Real-Debrid qui épuise son quota quotidien bascule son trafic sur la première entrée de `download_tokens` qui a encore du quota, et le watcher remet le token propre au compte dans la rotation dès qu'il peut à nouveau servir des octets. Récupérer un token n'a pas pour autant ramené le trafic. La rotation repartait de là où elle s'était arrêtée et ne vérifiait que si ce seul token était plafonné. Le compte de secours continuait donc à prendre tous les octets pour le reste de la journée, alors que le compteur du compte principal était déjà à zéro. L'ordre dans `download_tokens` est désormais une préférence, et non plus une position à parcourir : le token le plus proche du début et capable de servir est celui qui sert. Le compte principal reprend donc son trafic dans la minute qui suit la remise à zéro de son compteur.

## Un remote rclone pointant vers la mauvaise adresse l'indique désormais {#an-rclone-remote-pointed-at-the-wrong-address-now-says-so}

Si l'URL d'un remote WebDAV rclone n'a pas `/dav/` à la fin, chaque listage échouait avec « couldn't list files: 405 Method Not Allowed » et rien, nulle part, n'expliquait pourquoi. Le tableau de bord répondait normalement dans un navigateur, donc zurg avait l'air en bonne santé, et le journal de zurg restait muet sur le client qui échouait toutes les quelques secondes. zurg répond désormais à une requête WebDAV arrivée en dehors de `/dav/` avec l'adresse à utiliser à la place, que rclone affiche dans le cadre de sa propre erreur, et écrit un seul avertissement qui nomme le client qui a envoyé la requête.

## Les installations Windows renvoient à nouveau les scans vers le serveur média {#windows-installs-now-send-media-server-scans-again}

Un `mount_path` valant `Z:`, ce que `zurg setup` écrit sous Windows, construisait les chemins de scan par rapport au répertoire courant sur ce lecteur et non par rapport à sa racine. Du coup, chaque chemin manquait la section de bibliothèque à laquelle il appartenait, et aucun scan n'était jamais envoyé. L'avertissement qui suivait demandait de vérifier un `mount_path` qui était déjà correct. Les configurations existantes ne nécessitent aucune modification.

## Le scan en masse lit la bibliothèque Plex une fois au lieu d'une fois par torrent {#bulk-scan-reads-the-plex-library-once-instead-of-once-per-torrent}

Le matching après un scan groupé depuis le dashboard relisait toute la bibliothèque Plex pour chaque torrent du lot. Résultat : scanner une grosse bibliothèque envoyait des centaines de requêtes identiques qui récupéraient toute la bibliothèque, sur un serveur Plex qui était en général déjà occupé à scanner.

## Sous Windows, les chemins de la bibliothèque correspondent quelle que soit la casse {#windows-library-paths-match-regardless-of-case}

Une bibliothèque Plex, Jellyfin ou Emby enregistrée comme `Z:\Movies` ne rate plus le
`Z:\movies` que zurg construit à partir de son propre nom de répertoire. NTFS ne fait pas
la différence entre majuscules et minuscules, donc les deux désignent le même répertoire. Les comparer exactement faisait échouer le scan et signalait le mount_path comme incorrect.

## Un fichier qui cesse de répondre ne bloque plus un scan Plex {#a-file-that-stops-serving-no-longer-stalls-a-plex-scan}

Un fichier cassé gardait sa place dans la liste du répertoire et répondait aux lectures par `503 File temporarily unavailable (being repaired)` jusqu'à ce que quelque chose lève le verdict, c'est-à-dire, avec une réparation en cours, jusqu'à la fin de cette réparation. Plex se bloque sur un 503, donc un seul fichier de ce genre bloque un scan de bibliothèque, et une bibliothèque qui en accumule ne finit jamais son scan. Jellyfin, lui, les contourne et a l'air correct.

Ce sont deux décisions distinctes, et elles ont maintenant deux réponses distinctes. L'entrée reste listée tant qu'elle pourrait revenir, parce qu'une entrée qui disparaît d'un dossier est vue par un scanner de médias comme une suppression, et l'élément finit à la corbeille. Rien de ça ne change. Ce qui change, c'est la lecture : elle reçoit un 503 pendant une minute après que le fichier a cessé d'être servi, puis un 404 après.

Une minute, c'est ce qu'un client peut supporter. rclone réessaie un 503 et abandonne une lecture à peu près à ce moment-là. Une petite coupure reste donc absorbée et la lecture réussit. Au-delà, le 503 faisait déjà échouer la lecture et coûtait cher à chaque scan qui suivait.

Mesuré avec un vrai Plex, sur une bibliothèque de quinze films dont dix fichiers étaient refusés, tous encore listés : les lectures répondant 404 ont terminé le scan en 5 secondes. Un 503 qui ne se levait jamais n'avait trouvé que trois films sur les quinze quand l'exécution a été interrompue au bout de dix minutes.

## Les nouveaux jobs SABnzbd n'attendent plus derrière les vérifications de taille d'une bibliothèque complète {#new-sabnzbd-jobs-no-longer-wait-behind-a-full-librarys-size-checks}

Quand zurg redémarrait avec une grosse bibliothèque Usenet, il lançait une vérification de taille pour chaque release et oubliait quelles vérifications échouées étaient encore dans leur délai de nouvelle tentative d'une heure. Une release tout juste récupérée pouvait alors rester coincée derrière des milliers de vérifications en arrière-plan, pendant que Sonarr ou Radarr attendait ses tailles de fichiers exactes. Les vérifications de taille utilisent maintenant une file de workers fixe, une release avec une tâche SABnzbd en attente passe en tête de file, et les vérifications terminées comme les délais de nouvelle tentative survivent à un redémarrage dans `data/nzb-sizes/`. Tant qu'il y a du travail en file, zurg affiche toutes les minutes les compteurs d'attente, de priorité client et d'exécution.

## Les téléchargements qu'un client ne libère jamais n'empêchent plus l'import des nouveaux {#downloads-a-client-never-clears-no-longer-stop-new-ones-from-being-imported}

zurg montre à Sonarr, Radarr et aux autres clients de téléchargement une page de téléchargements terminés, et garde chacun sur cette page jusqu'à ce que le client le retire. Les clients ne retirent que ce qu'ils importent ou ce qui échoue, donc un import bloqué, comme un titre qu'ils ne peuvent pas associer, restait sur la page indéfiniment. Une fois la page remplie par ces éléments, chaque nouveau téléchargement terminé attendait dans la file et n'était jamais importé. Un téléchargement resté dix minutes sur la page sans être retiré cède maintenant sa place à un élément en attente, comme SABnzbd retire les anciennes lignes de sa page d'historique quand de nouvelles arrivent. Rien ne change tant que la page a de la place, et relancer une release lui donne une place à part.

## Un téléchargement recherché par son id est trouvé dès qu'il se termine {#a-download-looked-up-by-its-id-is-found-as-soon-as-it-finishes}

Les outils qui interrogent zurg sur un seul téléchargement à la fois, par son id, comme LazyLibrarian, sont maintenant informés qu'il est terminé dès qu'il l'est, même lorsque la page des téléchargements terminés que lisent Sonarr et Radarr est pleine. Avant, un tel téléchargement pouvait leur paraître inachevé jusqu'à ce qu'une place se libère sur cette page.

## Le correctif de saison a une page dans le tableau de bord {#season-fix-has-a-page-in-the-dashboard}

La passe de renommage de toute la bibliothèque, qui range les épisodes numérotés fansub sous les noms que lit Plex, n'était accessible que par deux points de terminaison HTTP depuis sa sortie : `/torrents/season-fix/plan` et `/torrents/season-fix/apply`. Aucun contrôle n'existait dans le tableau de bord, et un seul paragraphe la décrivait dans la référence de nommage. Une fonctionnalité que personne ne trouve n'existe pas vraiment. Celle-ci a été demandée sur le canal wishlist encore ce mois-ci, par des gens qui ignoraient qu'elle était déjà développée.

`/season-fix/` explique maintenant ce que fait la passe. La page montre la forme canonique produite à partir du nom fansub qu'elle remplace, et indique d'où vient la structure des saisons : du fournisseur de métadonnées de Plex lui-même, jamais de la bibliothèque locale, puisqu'une bibliothèque qui a fusionné les saisons est justement ce qu'on corrige. Elle liste aussi ce que le mappeur refuse de toucher et pourquoi. Un scan qui revient presque vide est la réponse prudente qui fonctionne, et non un défaut.

Le scan reste derrière un bouton. La planification parcourt chaque torrent et interroge Plex pour chaque série trouvée, donc l'ouverture de la page ne le lance pas. Les résultats sont regroupés par série, chaque renommage est affiché de l'ancien vers le nouveau nom, et les fichiers ignorés sont rangés dans un bloc dépliable. Une entrée signalée comme correspondance probable avec la mauvaise série arrive décochée, et la confirmation le rappelle. Ainsi, appliquer tout d'un coup ne peut pas renommer discrètement une version associée à la mauvaise série.

## Lire une version compressée répartie sur plusieurs volumes {#play-a-compressed-release-that-is-split-across-several-volumes}

Une release compressée (et non stockée telle quelle) s'arrêtait à la fin de son premier volume. Chaque fichier à l'intérieur était bien listé avec le bon nom et la bonne taille, mais refusait de se lire, et le journal affichait un bad header CRC. zurg gère maintenant la décompression à travers chaque jonction de volume, donc ces releases se lisent du début à la fin.

## Démarrer rapidement quand votre compte contient des torrents en échec {#start-up-quickly-when-your-account-holds-failed-torrents}

Chaque rafraîchissement de la bibliothèque revérifiait chaque torrent que votre service debrid avait marqué comme échoué, une requête à la fois, alors que le service n'en accepte que quelques-unes par seconde. Sur un compte qui en contient quelques centaines, cela prenait plus d'une minute, à chaque rafraîchissement, et votre bibliothèque restait illisible pendant tout ce temps après chaque démarrage. C'est assez long pour que Plex analyse un dossier qui n'existe pas encore et marque tout ce qu'il contient comme indisponible. zurg lit maintenant depuis le disque ce qu'il sait déjà sur un torrent échoué, et ne redemande au service que lorsque celui-ci indique que le torrent n'est plus en échec.

## Arrêter de redemander à AllDebrid les magnets qu'il a déjà refusé de réessayer {#stop-re-asking-alldebrid-about-magnets-it-has-already-refused-to-retry}

Quand un magnet échoue, zurg demande à AllDebrid de le récupérer à nouveau. AllDebrid refuse certaines de ces demandes, et ce refus n'était pas comptabilisé dans les deux tentatives accordées à un torrent. Résultat : le même magnet était redemandé à chaque rafraîchissement de la bibliothèque, tant que zurg tournait. La réponse est maintenant mémorisée pendant une heure, ainsi que le statut donné par le compte. Ainsi, un magnet qui change est de nouveau demandé.

Le nombre de tentatives est aussi écrit sur le disque, au lieu d'être oublié à chaque redémarrage et de tout recommencer.

## Garder le lien stable pour une version que votre compte détient en double {#keep-the-link-steady-for-a-release-your-account-holds-twice}

Une même release ajoutée deux fois à un compte apparaît en double, avec tout en double, y compris deux liens de téléchargement par fichier. zurg ne gardait qu'un lien par compte, donc chaque copie remplaçait l'autre à chaque rafraîchissement et l'entrée ne se stabilisait jamais. Rien n'était injouable, mais le journal se remplissait de réorientations et la bibliothèque était réécrite sur le disque toutes les quelques secondes. zurg laisse maintenant le lien tranquille quand il ne voit qu'une partie de ce que le compte contient.

## Vérifications de changement plus rapides sur TorBox quand le compte contient des torrents en échec {#faster-change-checks-on-torbox-when-the-account-holds-failed-torrents}

TorBox n'a aucun moyen de savoir si un compte a changé. Zurg lit donc une petite page des torrents les plus récents et surveille ceux qui ne sont pas encore terminés. Un torrent que TorBox a marqué en échec ne se termine jamais. Un seul ancien échec faisait donc lire une page beaucoup plus grande à chaque vérification, et ce pendant toute la durée de vie du compte. Les torrents en échec ne sont plus surveillés pour un mouvement qu'ils ne peuvent pas faire.

## Une version que votre *arr n'a pas pu importer n'est plus supprimée par la tentative {#a-release-your-arr-could-not-import-is-no-longer-deleted-by-the-attempt}

Quand zurg refuse de déplacer une release hors du dossier de transit Usenet parce qu'elle ne peut pas être lue depuis les serveurs de news, Sonarr et Radarr n'abandonnent pas simplement. .NET répond à un déplacement échoué en copiant le fichier puis en supprimant l'original, et zurg respectait cette suppression : la release disparaissait, et un fichier vide restait à l'emplacement où elle avait été importée. La suppression qui suit un déplacement refusé est désormais refusée pour la même raison, et la release reste en place.

## Les lectures Usenet distinguent un lot lent d'un lot bloqué {#usenet-reads-tell-a-slow-batch-from-a-stalled-one}

zurg demande une deuxième connexion Usenet pour un article dont l'attente a trop duré, et prend la réponse qui arrive en premier. Savoir que l'attente avait trop duré se décidait à la montre. Or un lot ordinaire de gros articles sur un compte rapide était redemandé deux fois alors que son premier article était encore en train d'arriver.

Maintenant, c'est le flux des octets qui déclenche la demande. Une connexion Usenet remet déjà à zéro son délai d'attente à chaque arrivée d'octets, et le lecteur voit cette preuve aussi. Un lot à mi-parcours d'un gros article est laissé tranquille, peu importe le temps que cet article prend. Seul un lot dont les octets se sont arrêtés est demandé ailleurs.

Quand une connexion prend un lot d'articles et n'en répond aucun, zurg demande à une autre connexion tout le reste de ce lot d'un coup, au lieu de chercher chaque article manquant un par un. La connexion silencieuse n'est jamais coupée, donc ses articles comptent toujours s'ils arrivent. Seuls les articles qui ne sont jamais arrivés sont redemandés, au plus une fois par lot. Les articles les plus proches de la tête de lecture passent en premier, et une deuxième demande d'une seconde reste toujours de côté, pour que la lecture suivante, qui s'arrête, puisse quand même demander son propre article.

Une lecture ne prend plus non plus le temps passé à attendre une deuxième demande pour sa vitesse normale. Elle apprend seulement le temps que zurg était prêt à attendre, et rien de plus. Sur un compte où chaque article prend légitimement une seconde ou plus, le seuil se stabilise autour de ce que ce compte livre vraiment, au lieu de tomber à son réglage le plus court et de redemander deux fois la plupart des articles.

## La lecture anticipée Usenet garde sa fenêtre pleine à travers les articles et les volumes {#usenet-read-ahead-keeps-its-window-full-across-articles-and-volumes}

Le read-ahead cessait de demander de nouveaux octets quand un article précédent prenait du retard, donc un seul article lent vidait la fenêtre qu'il avait construite. zurg garde maintenant malgré tout une fenêtre bornée d'octets demandés en cours de transfert, et un lot d'articles peut couvrir la jonction entre deux volumes RAR stockés au lieu de s'arrêter à cette jonction.

La fenêtre utilise au maximum un quart du cache RAM que vous avez configuré, et jamais plus de 128 MiB, donc un cache plus petit donne une fenêtre plus petite. Les requêtes gardent leur propre annulation ainsi que les limites de connexions et de cache de leur compte.

## La lecture Usenet consomme moins de CPU sur les processeurs anciens {#usenet-playback-costs-less-cpu-on-older-processors}

Le cache de lecture calcule une somme de contrôle pour chaque enregistrement qu'il stocke. Sur les processeurs Intel et AMD qui ont SSE4.1 mais pas AVX, SHA-256 tourne sans aucune aide matérielle, et ce coût se faisait sentir pendant la lecture. zurg utilise désormais une somme de contrôle 256 bits plus rapide sur ces processeurs. Les enregistrements portent un numéro de version, donc une corruption est toujours détectée, un cache existant reste lisible, et tous les autres processeurs gardent SHA-256.

## Les partages NZB ne renvoient plus vers le compte qui les a récupérés {#nzb-shares-no-longer-point-back-to-the-account-that-grabbed-them}

Certains indexeurs estampillent chaque téléchargement avec des détails qui remontent à ton compte, et une partie de ces infos se trouvait dans des champs que le partage conservait. L'un cache un jeton frais dans le titre de la release, et souvent dans le mot de passe, et change l'expéditeur, la date et le newsgroup à chaque fichier. Un autre met le numéro de ton compte au début du sujet d'un fichier. Un troisième met un marqueur de compte dans chaque expéditeur. `zurg nzb-share` supprime maintenant les expéditeurs et les dates, donne à chaque fichier le même newsgroup fixe, retire la marque du sujet et ignore un jeton où qu'il se trouve. Quand le nom et le titre ne concordent pas, le nom l'emporte. Deux personnes qui ont récupéré la même release publient maintenant le même fichier. Les partages n'omettent plus non plus les NZB enregistrés en encodage Latin-1, et ils ne doublent plus les antislashs que certains sujets contiennent.

Ce que le nettoyage supprime se trouve dans [`zurg nzb-share`](cli.md#zurg-nzb-share).

## Les bibliothèques locales ajoutent le hash sur AllDebrid, Premiumize et Offcloud {#local-libraries-add-the-hash-on-alldebrid-premiumize-and-offcloud}

Une bibliothèque locale dont le manifeste n'a pas de lien portable ajoute le hash à votre compte à la première lecture. C'est toujours le cas pour un manifeste exporté depuis TorBox. C'est aussi le cas quand le lien AllDebrid a expiré. Sur AllDebrid, Premiumize et Offcloud, chaque lecture de ce type échouait avec « provider did not report an active torrent allowance ». zurg voulait que le compte indique sa limite de slots torrent avant d'ajouter. Ces trois fournisseurs n'en indiquent jamais. zurg revient maintenant au nombre de slots déclaré, comme le fait la réparation. Sans l'un ni l'autre, zurg ajoute le hash et laisse le fournisseur refuser si le compte est plein.

## Les fichiers Offcloud indiquent leur durée {#offcloud-files-report-their-length}

Résoudre un fichier Offcloud laissait sa taille non renseignée. Une bibliothèque locale compare cette taille à son manifeste. Elle refusait donc toute lecture Offcloud avec le message "resolved file size does not match the portable manifest". La lecture normale perdait aussi la gestion des plages (range), qui a besoin d'une taille. zurg demande désormais au serveur de livraison la taille, comme le fait déjà la liste Offcloud.

## zurg fonctionne sur les téléphones Android et Google TV {#zurg-runs-on-android-phones-and-google-tv}

Une nouvelle application Android héberge votre bibliothèque directement sur l'appareil. Elle s'adapte aux téléphones et aux tablettes, ainsi qu'à Android TV et Google TV. Elle nécessite Android 8.0 ou une version plus récente, et Usenet nécessite Android 64 bits. L'application vous guide dans la configuration des comptes de fournisseurs et du profil d'appareil, puis lance la bibliothèque. Vous parcourez la bibliothèque dans l'application ou dans Files d'Android, et vous lisez les contenus dans le lecteur externe de votre choix, avec une recherche complète dans la vidéo. Une télécommande de TV permet de naviguer dans tous les écrans. MediaInfo fonctionne directement sur l'appareil, sans outil supplémentaire. La bibliothèque peut aussi être partagée avec d'autres appareils de votre réseau local, protégée par un mot de passe. Ce mot de passe n'est jamais transmis à un lecteur.

Les APK sont disponibles dans les versions nightly réservées aux sponsors. L'application ne contient pas zurg. Après vous être connecté à GitHub, elle installe le moteur zurg comme second paquet. L'application et le moteur se mettent à jour séparément. La section Updates affiche toutes les versions du moteur encore publiées, afin qu'une version nightly qui pose problème sur votre appareil puisse être remplacée par une version qui fonctionnait. Si vous avez installé la première version Android, vous devez installer une fois un moteur depuis Updates. Vos fournisseurs et vos paramètres de bibliothèque sont conservés tels quels.

Le moteur pour les appareils ARM 64 bits utilise désormais le résolveur système d'Android pour trouver les adresses des fournisseurs. Le moteur de la première version pouvait ne pas parvenir à joindre le moindre fournisseur.

Les notes de configuration et de lecteur se trouvent dans [Android](../guides/android.md).

## Un nouveau NZB apparaît dans la bibliothèque en quelques secondes {#a-new-nzb-shows-up-in-the-library-within-seconds}

Un NZB déposé dans le dossier de surveillance attendait la prochaine vérification périodique des changements. Une release obfusquée attendait ensuite un deuxième intervalle pendant que ses vrais noms de fichiers étaient lus. Avec l'intervalle par défaut, cela ajoutait 20 à 30 secondes, pendant lesquelles une demande Sonarr ou Radarr restait bloquée sur Queued.

zurg vérifie maintenant lui-même le dossier de surveillance chaque seconde. Il ne s'appuie pas sur les événements du système de fichiers, donc il se comporte de la même façon sur un NAS ou dans un conteneur. Une release apparaît dès que ses noms ont été lus. Un pack de saison de vingt releases ne coûte toujours qu'un seul listing. La vérification périodique reste en filet de sécurité pour un NZB remplacé sous un nom qu'il avait déjà.

## Les flux Usenet gardent leur débit {#usenet-streams-hold-their-speed}

La lecture anticipée des fichiers RAR, c'est une histoire de volumes. Un fichier à l'intérieur d'un jeu RAR arrive sur le compte Usenet un volume à la fois. zurg ouvre le volume suivant à l'avance pour que le passage ne démarre pas à froid. Avant, il ne préchauffait que les quatre premiers mégaoctets. Sur une release découpée en petits volumes, ça voulait dire une frontière toutes les une ou deux secondes de lecture, et un blocage à chaque fois. Une de ces releases diffusait à 14 à 16 MB/s alors qu'un fichier classique sur le même compte tournait à 86 à 99 MB/s. Le volume suivant est maintenant préchauffé sur toute une fenêtre de lecture anticipée dès que le flux arrive à moins de 32 MiB de lui. Un volume dans lequel le flux vient d'entrer garde la lecture anticipée qu'il a gagnée. Un volume dont rien n'est proche n'est toujours préchauffé qu'au début. Ça évite qu'une analyse de la bibliothèque télécharge des données qu'elle ne lira jamais.

Une lecture continue passait aussi environ une seconde sur vingt à ramper sur un seul article lent, pendant que toutes les autres connexions attendaient derrière lui. zurg demande maintenant cet article à une deuxième connexion quand l'attente dure trop, et garde la réponse qui arrive en premier. Ça ne se fait que pour une lecture que le lecteur attend. La lecture anticipée et la réparation ne sont jamais dupliquées. C'est limité à vingt requêtes supplémentaires par minute et par compte.

La lecture que le lecteur attend passe maintenant devant dans plus de cas. La lecture anticipée ne prend plus la dernière connexion libre d'un compte. La passe de dimensionnement au démarrage en laisse aussi une libre. Une lecture utilise les connexions déjà ouvertes par le compte au lieu d'en ouvrir une nouvelle. Elle attend une connexion déjà en cours d'ouverture plutôt que d'en payer une autre. L'article sur lequel bloque le lecteur peut passer devant les récupérations en file pour des octets plus loin. Dans une mesure, le premier octet d'une lecture est arrivé en 177 ms au lieu de 354 ms. Le préchauffage, les keep-alive et les lectures partagent maintenant aussi une même limite de connexions. zurg n'ouvre jamais plus de connexions que le compte n'en autorise.

Enregistrer un article décodé dans le cache disque ne bloque plus la lecture qui l'a récupéré. L'écriture se trouvait avant dans un verrou dont toutes les autres lectures avaient besoin. Elle se fait maintenant après que les octets sont arrivés au lecteur. Une rafale plus grosse que ce que le cache peut suivre saute les enregistrements en trop plutôt que de ralentir la lecture. Un cache existant est conservé tel quel.

## Sonarr et Radarr arrêtent d'attendre les captures qui ne pourront jamais aboutir {#sonarr-and-radarr-stop-waiting-on-grabs-that-can-never-finish}

Le point de terminaison SABnzbd laissait parfois certains jobs en attente indéfiniment. Le client ne les mettait jamais sur la liste de blocage et ne prenait jamais une autre release. Chaque cas ci-dessous est maintenant signalé comme Failed, avec un message qui explique la raison. Failed est ce qui pousse Sonarr et Radarr à mettre la release sur la liste de blocage et à relancer une recherche.

Une release peut disparaître de la bibliothèque après son grab. Elle peut être supprimée depuis le tableau de bord, retirée du dossier surveillé ou abandonnée par tous les comptes. Le job restait auparavant à 0 % sans rien pour le faire avancer. Il échoue maintenant une fois que la release est absente depuis quinze minutes. Rien n'échoue pendant les quinze premières minutes après un redémarrage, le temps que la bibliothèque se charge.

Un grab peut tomber sur une release qu'un import précédent a déjà vidée. Cela arrive quand une mise à niveau supprime le fichier importé et qu'une recherche retombe sur la même release. zurg répondait Completed et pointait le client vers un dossier vide. Un grab ultérieur d'une release vidée échoue maintenant immédiatement. Un dossier qui reste vide pendant quinze minutes fait aussi échouer son job. Cela couvre un dossier vidé par un déplacement fait à la main ou par un import classé sous un autre job. Le grab qui fait l'import affiche toujours Completed pendant qu'il termine.

Certaines releases ne finissent jamais leur vérification d'articles. zurg demande aux serveurs de news si les articles d'une release sont toujours là avant de signaler un grab comme terminé. Une vérification qui ne pouvait pas aboutir était auparavant relancée chaque minute sans fin. Elle échoue maintenant après trente tentatives consécutives réparties sur au moins trois heures. Un compte news en panne pendant une heure ne fait pas mettre sur la liste de blocage tous les jobs en attente. Une vérification qui finit par répondre remet le compteur à zéro.

Certaines releases ne contiennent pas toute leur archive. Un ensemble peut ne pas avoir de volume contenant le début du fichier. Il peut lui manquer un volume au milieu. Il peut commencer ailleurs que sur son premier volume. Sonarr était auparavant pointé vers un dossier à partir duquel il ne pouvait jamais importer, et réessayait indéfiniment. Le grab échoue maintenant. Le verdict est lié aux volumes exacts sur lesquels il a été établi. Une réparation PAR2, un nouveau grab ou un second compte qui possède les volumes manquants refait examiner la release.

## Les jetons de téléchargement de secours prennent le relais quand le quota journalier est épuisé {#backup-download-tokens-take-over-when-the-daily-allowance-runs-out}

Real-Debrid refuse un téléchargement dès qu'un token a épuisé son quota quotidien. zurg est censé mettre ce token à la retraite et passer à l'entrée suivante de `download_tokens`. Ça ne marchait plus pendant la lecture depuis que les flux proxifiés sont passés sur un nouveau client HTTP. Le refus revenait comme une réponse ordinaire, et rien ne marquait le token comme épuisé. Tous les tokens de secours restaient inutilisés, et chaque lecture consommait à nouveau le token plafonné.

Le refus est maintenant reconnu partout où zurg le rencontre. Ça veut dire pendant la lecture, mais aussi dans la boucle de rafraîchissement et dans la réparation. Ces deux-là vérifient les liens qu'il y ait ou non quelque chose en cours de lecture. Un refus qui arrive sans l'en-tête habituel de Real-Debrid met aussi le token à la retraite.

Un token mis à la retraite est testé une fois par minute, pour pouvoir revenir dès que son quota se recharge. Ce test utilisait un lien mis en cache sous ce même token. Or rien ne remplit ce cache une fois que le token ne sert plus. Le test ne trouvait donc rien, et le token restait écarté jusqu'à la remise à zéro nocturne ou jusqu'à un redémarrage. Il emprunte maintenant un lien au token qui sert encore.

La remise à zéro nocturne avait un jour de retard. Real-Debrid réinitialise les quotas quelques minutes après minuit, heure de l'Europe centrale (CET). zurg sautait le premier minuit après chaque démarrage et ne remettait à zéro qu'au second. Un compte qui avait épuisé son quota continuait donc à servir depuis son token de secours un jour de plus. zurg calculait aussi ce minuit à partir de la date de la machine hôte. À l'ouest de l'Europe, la remise à zéro tombait alors à n'importe quelle heure, selon le moment où zurg avait démarré. Chaque remise à zéro est maintenant planifiée à partir de la date en CET.

## Une capture magnet conserve son nom de version sur le compte debrid {#a-magnet-grab-keeps-its-release-name-on-the-debrid-account}

Sonarr et Radarr envoient à l'endpoint qBittorrent le magnet complet de l'indexer. zurg le réduisait avant de l'ajouter, ne gardant que l'info hash. Le nom d'affichage et les trackers n'arrivaient donc jamais au compte. Sur un indexer qui ne fournit que des magnets, le nom d'affichage est le seul endroit où le nom de la release existe. Un torrent non mis en cache se retrouvait alors dans la liste du compte sous un hash de 40 caractères. Pour un torrent que personne ne seed, c'est le seul nom qu'il aura jamais.

Le magnet arrive maintenant au compte tel que le client l'a envoyé. Repair, la watchlist Plex et les bibliothèques portables ajoutent toujours le hash seul, car ils n'ont pas de nom à transmettre.

## Le dump .strm ne contient que les fichiers qu'un lecteur peut ouvrir {#the-strm-dump-holds-only-files-a-player-can-open}

`save_strm_files` écrivait autrefois un .strm pour chaque fichier sélectionné d'une release. Les sous-titres, les posters, les NFO et les volumes PAR2 devenaient chacun une entrée de bibliothèque qui ne mène à rien. TorBox et AllDebrid marquent tous les fichiers comme sélectionnés. C'est aussi le cas d'un post Usenet avec ses fichiers de réparation à côté de la vidéo. Maintenant, seuls la vidéo et l'audio reconnus reçoivent un .strm, ainsi que tout ce qui est listé dans `addl_playable_extensions`. Une vidéo dans un jeu RAR est toujours écrite, alors que les volumes qui l'entourent ne le sont pas. Les entrées écrites par les versions précédentes sont supprimées la prochaine fois que la release est parcourue.

Plusieurs chemins d'écriture demandaient aussi au serveur multimédia de lancer un scan avant que les fichiers .strm n'existent. Plex, Jellyfin ou Emby pouvaient regarder un dossier vide et n'indexer rien. Rien ne lui demandait de revérifier tant que la release n'avait pas changé. Les fichiers sont maintenant écrits en premier sur tous les chemins.

## Déplacer le dossier de zurg ne laisse plus le cache de montage orphelin {#moving-the-zurg-folder-no-longer-strands-the-mount-cache}

Le montage rclone conserve ce qu'il lit dans `data/rclone-cache`. rclone nomme ce cache d'après sa propre configuration. Cette configuration inclut le chemin complet du dossier `data/local` de zurg. Déplacer le dossier zurg ou modifier `union_writable` a donné au cache un nouveau nom. L'ancien dossier est resté sur le disque, hors de portée de la limite de taille, et personne ne l'a nettoyé. Quelques déplacements pouvaient ainsi laisser des téraoctets derrière eux.

Au démarrage du montage, zurg demande maintenant à rclone quel dossier de cache est actif, puis supprime les autres. Il journalise la place qu'il a libérée. Il ignore ce nettoyage lorsque `rclone_extra_args` définit son propre `--cache-dir`. Mettez `rclone_cache_reclaim: false` pour conserver les anciens dossiers.

Le cache actif est aussi plus gros que ce que la plupart des gens imaginent. Il grandit jusqu'à 256G par défaut et reste à ce niveau. Le passage nocturne d'un serveur multimédia touche chaque fichier, donc la limite d'âge de 72 heures n'évince presque jamais rien. Prévoyez votre espace en fonction de la limite de taille. Pour la baisser, consultez [la référence de configuration](config.md#disk-the-mount-uses).

## Les affiches et fichiers .nfo continuent d'atterrir dans `__magic__` {#posters-and-nfo-files-keep-landing-in-__magic__}

Un client qui écrit via le montage de zurg dépose ses nouveaux fichiers dans `data/local`. C'est le dossier où `__magic__` garde ses sidecars. zurg comptait chaque fichier de ce dossier dans `sidecar_budget_mb`. Quelques vidéos écrites via le montage par un \*arr pouvaient épuiser tout le budget. Tous les .nfo et affiches suivants étaient alors refusés, comme si l'arborescence était pleine. Augmenter le budget ne réglait rien.

Un fichier plus gros que `sidecar_max_mb` ne peut pas être passé par le chemin des sidecars de zurg. Ces fichiers ne comptent plus dans le budget. zurg les signale une fois au démarrage, parce qu'ils occupent quand même de l'espace disque.

Supprimer un chemin `__magic__` déjà disparu réussit désormais. Le montage peut retirer un sidecar partagé des deux côtés sans casser le nettoyage d'un import.

## Une lecture Stremio essaie la version suivante quand la première n'est plus disponible {#a-stremio-play-tries-the-next-release-when-the-first-has-aged-off}

Un clic dans Stremio correspondait avant à une seule release. Si cette release ne contenait rien de lisible, la lecture échouait avec une erreur 404. La cause habituelle est un post qui a expiré sur le serveur de news. La liste des flux pouvait pourtant afficher une douzaine d'autres releases.

Un refus de lecture essaie maintenant jusqu'à deux autres lignes de la même liste classée. Il commence après la ligne que tu as choisie. Le repli porte donc sur la même résolution et une taille plus petite, ou sur le palier inférieur. Ce n'est jamais une release plus grosse que tu avais laissée de côté. Une release encore en cours de récupération répond toujours 503, et relancer la lecture la reprend. Chaque essai consomme un grab d'indexeur et laisse cette release dans la bibliothèque. Les liens de lecture créés avant ce changement se comportent comme avant.

## Les listes Stremio affichent toutes les résolutions et une variété de tailles {#stremio-lists-show-every-resolution-and-a-spread-of-sizes}

La limite de la liste des flux comptait sur l'ensemble de la liste. Les résultats 4K sont classés en premier, et un titre populaire en a plus que la limite. La liste pouvait donc se remplir de remuxes de 20 à 40 Go et masquer toutes les releases en 1080p et 720p trouvées par la recherche. `stremio.max_results` compte maintenant par résolution et vaut 5 par défaut. Une valeur que tu as réglée à la main garde son chiffre et s'applique désormais à chaque résolution.

Dans une résolution, la liste ne gardait avant que les plus grosses releases. L'encodage de 4 Go qu'un téléphone ou un ordinateur portable peut lire était celui qui sautait. Chaque résolution garde maintenant des choix répartis régulièrement, de la plus grosse release à la plus petite. Les deux extrêmes sont toujours inclus.

La description de chaque flux se termine maintenant par le temps écoulé depuis la publication de la release. Elle affiche par exemple `3d`, `126d` ou `2y`. L'âge est le meilleur indice qu'un post a peut-être expiré sur le serveur de news. Les résultats mis en cache avant ce changement n'affichent pas d'âge tant que le cache de ce titre n'a pas été actualisé.

Le manifeste de l'addon affiche maintenant la vraie version de build au lieu de `0.1.0`. `zurg --version` affiche les mêmes détails de build que `zurg version` et ne nécessite pas de fichier de configuration.

## Les versions saines ne disparaissent plus de la bibliothèque {#healthy-releases-stop-disappearing-from-the-library}

A une connexion échouée ou une erreur de résolution DNS auprès de l'API Real-Debrid, le compte est maintenant marqué temporairement indisponible. Avant, cela marquait des fichiers sains comme cassés. Ils restaient ensuite en attente de réparation une fois le réseau revenu.

Le nettoyage après un rafraîchissement de la bibliothèque attendait avant une analyse média en arrière-plan. Quand il s'exécutait, un rafraîchissement plus récent avait pu remettre une release. Le nettoyage tardif la supprimait alors à nouveau. Le nettoyage se termine maintenant avant qu'un rafraîchissement ne rende la main. L'analyse média continue de tourner en arrière-plan.

## Kodi peut parcourir le partage WebDAV {#kodi-can-browse-the-webdav-share}

WebDAV-Listings geben jetzt den vollständigen Pfad jedes Ordners und jeder Datei an, einschließlich des Präfixes `/dav/`. Kodi und andere strikte Player haben dieses Präfix früher weggelassen und konnten dadurch keine Ordner oder Medien öffnen. Namen mit maskierten Zeichen und Pfade in Archiven behalten ihre Adressen.

## Un serveur de news chargé ne laisse plus de trous dans un flux {#a-busy-news-server-no-longer-puts-holes-in-a-stream}

Un serveur de news peut répondre « no such article » pour un article qu'il possède, pendant qu'il est occupé. zurg confirmait autrefois cette réponse quelques centaines de millisecondes plus tard, sur la même connexion. Il servait alors la plage sous forme de zéros et marquait l'article comme perdu pendant un jour. Une lecture de 32 MiB est revenue avec 384,000 octets à zéro, pour un article que le serveur avait pourtant bien servi une minute plus tard.

Un article refusé est désormais redemandé une fois, une seconde plus tard. Cette seconde demande passe par une autre connexion, si une est libre. La lecture attend cette réponse au lieu de combler le trou. Un article réellement disparu est toujours servi sous forme de silence et réparé comme avant. Une release endommagée met donc environ une seconde de plus à atteindre ce silence.

Un article dont la connexion reste silencieuse est aussi redemandé une fois sur une autre connexion. Auparavant, cela faisait échouer toute la réponse. Un flux RAR répondait 500 pour un article que le fournisseur envoyait simplement plus lentement.

## Choisissez comment zurg s'identifie auprès des services qu'il appelle {#choose-how-zurg-identifies-itself-to-the-services-it-calls}

Les requêtes vers les services debrid et les indexeurs utilisent désormais un User-Agent de navigateur générique par défaut. Les recherches de sous-titres l'utilisent aussi et n'envoient plus `zurg v0`. Ces requêtes suppriment aussi les en-têtes origin et referrer, ainsi que les en-têtes propres à zurg. C'est valable même lors des redirections : une redirection ne peut pas divulguer le chemin privé ou la clé API de l'URL précédente.

`user_agent` définit un autre agent, et `omit_user_agent` n'en envoie aucun. Les clés `outbound_*` définissent les noms de client et d'appareil que voient Plex, Jellyfin et Emby. Toutes ces options se trouvent sur le tableau de bord, sous Network & Connectivity, et prennent effet après un redémarrage. Les connexions Usenet n'envoient aucun identifiant logiciel. Cela supprime les identifiants propres à zurg. Cela ne vous rend pas anonyme pour autant.

Les détails sont dans [Identité sortante](outbound-identity.md).

## zurg vide la corbeille Plex par défaut {#zurg-empties-the-plex-trash-by-default}

zurg désactive « Empty trash automatically after every scan » dans Plex. Sinon, un scan qui tombe sur un montage momentanément illisible supprimerait la bibliothèque au lieu de la mettre de côté. Ce qui restait derrière passait inaperçu. Plex ne nettoyait plus les entrées mortes et la suppression faite par zurg était facultative. Par défaut, personne ne les nettoyait donc. Les entrées dont les fichiers avaient disparu depuis longtemps s'accumulaient. Le cas le plus visible : un fichier déplacé entre deux dossiers de la bibliothèque, dont l'ancienne entrée restait à jamais.

Avec `plex_trash_sweep_every_mins` non défini, le balayage de la corbeille tourne maintenant toutes les 60 minutes. Il se met en retrait quand Plex est encore en train de vider sa propre corbeille. Il supprime une entrée à la fois, et jamais une entrée qui a encore un fichier. Il ne s'exécute que sur un montage accessible en lecture. Tout ce qu'il ne peut pas évaluer reste visible comme cassé pendant 14 jours avant d'être traité. Écris `plex_trash_sweep_every_mins: 0` pour garder la suppression désactivée et vider la corbeille toi-même.

Ce réglage ne rend pas le vidage de la corbeille à Plex. La page de configuration a maintenant un interrupteur Let Plex Empty Its Own Trash pour ça. Le risque qui y est lié est écrit juste à côté.

La restauration fonctionne aussi maintenant. Plex saute un scan ordinaire d'un dossier qu'il a déjà scanné. Une série placée à la corbeille dont tous les fichiers étaient revenus pouvait donc rester à la corbeille scan après scan. Le balayage demande maintenant à Plex un scan forcé de ce dossier. Un scan lancé à la main depuis le tableau de bord atteint aussi les chemins `__magic__` à partir desquels une bibliothèque Usenet est indexée. Avant, il ne trouvait aucune section Plex et ne faisait rien.

Comment les deux collecteurs se partagent le travail est expliqué dans [Plex](../guides/plex.md#who-empties-the-trash).

## Les archives endommagées listent les bons octets ou rien du tout {#damaged-archives-list-the-right-bytes-or-nothing-at-all}

Certains jeux de RAR endommagés affichaient une vidéo qui lisait les mauvais octets. Un jeu auquel il manquait un volume au milieu servait le reste du fichier décalé, avec une fin de zéros. Ce type de jeu est maintenant refusé. Un jeu dont le premier en-tête ne pouvait pas être lu avait ses octets suivants décalés. zurg lit maintenant d'abord les en-têtes de continuation, pour que chaque décalage soit juste. Les fichiers placés après le film dans le dernier volume sont aussi conservés. Un marqueur de fin RAR4 était pris à tort pour du chiffrement. Les jeux découpés avec des blocs de fin remplis perdaient leur premier volume. Ils listent maintenant la vidéo complète.

Un NZB dont 10 % ou plus des articles manquent est refusé avant que quoi que ce soit ne soit diffusé. Le contenu que PAR2 a déjà reconstruit continue de se lire.

Les listes d'archives existantes sont reconstruites pour que ces corrections atteignent aussi les releases déjà présentes dans la bibliothèque.

## Les grosses bibliothèques peuvent rendre la mémoire inutilisée {#large-libraries-can-give-idle-memory-back}

`library_detail` décide si la liste des fichiers de chaque release reste en mémoire. `resident` garde toutes les listes et reste la valeur par défaut. `lazy` libère les listes de fichiers que personne n'a lues depuis `library_detail_idle_secs`. Les listings restent disponibles, et une liste de fichiers est rechargée depuis le disque quand quelqu'un la lit. `auto` fait la même chose, mais seulement en cas de pression mémoire soutenue sur l'hôte ou le conteneur. Les gros packs de saison consomment beaucoup moins de mémoire dans les deux cas. Une copie de récupération compressée protège une liste de fichiers si son cache disque est endommagé. Les modifications non sauvegardées ne sont jamais libérées. Le tableau de bord propose les trois modes. Un changement nécessite un redémarrage.

Le démarrage consomme aussi moins de mémoire avec un historique de téléchargements Real-Debrid volumineux. L'enregistrement et le chargement de cet historique, ainsi que des caches de la bibliothèque, ne créent plus de copies supplémentaires.

Les compromis sont décrits dans [la référence de configuration](config.md#library-detail).

## La watchlist Plex et les demandes Seerr partagent une même file {#plex-watchlist-and-seerr-requests-share-one-queue}

Le bloc `acquisition:` envoie les éléments de ta watchlist Plex et les demandes Seerr dans une seule file d'attente. Les deux sont recherchés sur tes indexeurs Newznab et atterrissent dans le backend Usenet. Les demandes Seerr ne sont suivies qu'une fois approuvées. Seules les saisons demandées sont récupérées. Une demande en 4K est gardée à part d'une demande en 1080p. Les demandes Seerr encore ouvertes sont revérifiées pour les nouveaux épisodes diffusés.

La progression survit désormais à un redémarrage. Cela couvre les délais de nouvelle tentative, le nombre de tentatives et les épisodes déjà terminés. Une acquisition interrompue reprend là où elle s'est arrêtée. Une acquisition déjà terminée ne retente que de retirer l'élément de la watchlist et ne relance pas de recherche. L'état sauvegardé fait partie des sauvegardes normales. Les paramètres `watchlist:` existants continuent de fonctionner sans changement.

La configuration se trouve dans [Acquisition](../guides/acquisition.md).

## Les bibliothèques debrid peuvent vivre dans des fichiers locaux portables {#debrid-libraries-can-live-in-portable-local-files}

Un compte débrid peut désormais tirer sa bibliothèque d'un dossier de fichiers `.zurgtorrent` au lieu de la liste propre au compte. `zurg export-torrents` permet d'exporter une bibliothèque existante sous forme de ces fichiers. Ils décrivent le contenu et ne contiennent ni identifiants ni liens de téléchargement. Une bibliothèque peut donc être partagée. La personne qui la reçoit lit le contenu avec son propre compte, et les limites de son fournisseur continuent de s'appliquer. Importer, lister et actualiser les fichiers n'ajoute rien au compte.

Les configurations existantes continuent de fonctionner. Les nouvelles sauvegardes utilisent le format 2 et nécessitent cette version ou une version plus récente pour être restaurées.

L'export et la configuration sont décrits dans [Bibliothèques locales](../guides/local-libraries.md).

## Les caches de lecture survivent à un redémarrage {#read-caches-survive-a-restart}

zurg conserve désormais ses caches de lecture sur le disque, même après un redémarrage. Cela concerne les NZB analysés et les articles Usenet décodés. Cela concerne aussi les structures d'archives, les blocs d'archives décodés et les liens de téléchargement. Après un redémarrage, zurg n'a plus besoin d'analyser chaque NZB ni de relire l'en-tête de chaque archive. Chaque cache d'octets est limité à 512 MiB par défaut. `zurg backup --include-caches` les ajoute à une sauvegarde pour une restauration à chaud.

Les demandes portant sur le même fichier AllDebrid ou TorBox, au même moment, partagent désormais une seule recherche de lien.

Les paramètres et les limites sont décrits dans [Persistent caches](../internals/persistent-caches.md).

## Les grabs Usenet sont vérifiés de plus près avant de passer à Completed {#usenet-grabs-are-checked-more-closely-before-they-read-completed}

Avant qu'un grab passe à Completed, zurg demande au serveur de news les seize premiers articles et le dernier article de chaque fichier de contenu. Avant, il ne vérifiait que le premier. Cela laissait passer les trous dans l'en-tête du média. Les vérifications partent en un seul lot par fichier, donc les grosses archives ne manquent plus de temps.

Une release dont les articles manquants ont été entièrement reconstruits avec PAR2 est maintenant importée. Avant, l'import échouait parce que les articles d'origine étaient toujours absents du serveur. Une réparation partielle ne compte toujours pas.

`sabnzbd.history_limit` peut maintenant correspondre à une limite d'historique plus élevée dans Sonarr ou Radarr. Une grosse file de jobs terminés se vide alors par lots plus grands. Les deux côtés doivent utiliser le même nombre. La valeur par défaut reste soixante.

## `enforce` laisse tranquilles les fonctions Plex que vous voyez {#enforce-leaves-the-plex-features-you-can-see-alone}

`plex_settings_policy: enforce` ne désactive plus la génération des aperçus de scrubbing ni des images de chapitres. Il ne désactive pas non plus la normalisation du volume ni l'analyse sonore. Chacune d'elles décode des fichiers entiers, et cela consomme de la bande passante sur un montage debrid. Mais chacune offre aussi quelque chose de visible. Elles rejoignent désormais Skip Intro et Skip Credits : c'est une question de goût. zurg indique toujours ce que coûte chacune d'elles. Il ne fait simplement plus le choix à votre place. Le groupe bande passante ne contient plus que les analyses dont personne ne regarde le résultat.

## Les liens debrid expirés se rétablissent sans faire échouer la lecture {#expired-debrid-links-recover-without-failing-playback}

Un lien TorBox dont le jeton signé a expiré en obtient maintenant un nouveau. Les lecteurs qui attendent le même fichier partagent cette seule recherche. Les échecs répétés mettent la lecture en pause sans marquer le fichier comme cassé.

Quand un serveur de téléchargement TorBox, Real-Debrid ou AllDebrid demande à zurg d'attendre, zurg attend maintenant aussi longtemps qu'on le lui indique. Il arrête aussi de réessayer un serveur qui continue de refuser. Cela vaut pour la lecture, les vérifications de liens et les lectures d'archives. Un lien révoqué ouvert via `__downloads__` en obtient aussi un nouveau.

## zurg se met à jour tout seul {#zurg-updates-itself}

`zurg update` remplace le binaire en cours d'exécution par la dernière nightly sponsor. Il lit le flux des versions avec la connexion GitHub CLI si elle existe, sinon avec `GITHUB_TOKEN` ou `GH_TOKEN`, vérifie que les téléchargements fonctionnent et affiche la version attendue avant de remplacer quoi que ce soit, puis échange le binaire par un renommage, pour qu'une mise à jour ne puisse pas échouer pendant que zurg tourne. Si une version est déjà sur la dernière nightly ou plus récente, elle est laissée telle quelle. Dans un conteneur, la commande refuse et vous renvoie vers le pull de l'image à la place, car un binaire remplacé là-bas est perdu au prochain recreate ; `--force` passe outre. Les installateurs ont reçu un mode `update` équivalent pour les versions trop anciennes pour avoir la commande.

Par plateforme : [Linux](../setup/linux.md#updating-zurg), [macOS](../setup/macos.md#update-zurg), [Windows](../setup/windows.md#updating-zurg), [Docker](../setup/docker.md).

## Un réglage Plex peut être exclu de la politique {#one-plex-setting-can-be-opted-out-of-the-policy}

`plex_settings_ignore` indique à zurg les préférences Plex qu'il doit laisser tranquilles, quelle que soit la valeur de `plex_settings_policy`. C'est pour le cas où tu as vraiment besoin de l'une d'elles : une bibliothèque dont les fichiers changent de dossier dépend de Plex qui vide sa propre corbeille pour supprimer l'entrée restante. Or la politique par défaut désactive cette option. Passer à `warn` pour la récupérer ferait aussi perdre les protections sur les événements du système de fichiers qui l'accompagnent. Un réglage ignoré est toujours lu et toujours signalé, sur le tableau de bord et comme `skip` dans `zurg plex-settings`. Il n'est simplement jamais écrit, jamais signalé par un avertissement, et jamais placé derrière le bandeau de corbeille. Ignorer un réglage de sécurité se fait à tes risques et périls, et zurg te le rappelle une seule fois au démarrage. Un identifiant qui ne correspond à rien est signalé, et le réglage reste protégé. Ainsi, une faute de frappe ne peut pas passer pour une désactivation.

Les réglages eux-mêmes, et ce que fait chaque niveau de politique, sont décrits dans [Plex](../guides/plex.md#recommended-plex-settings).

## Des installateurs en une ligne pour chaque hôte pris en charge {#one-line-installers-for-every-supported-host}

Les nouvelles installations disposent désormais de scripts d'amorçage optionnels en une seule ligne pour Linux, macOS, Windows et Docker sur Linux. Ils vérifient ou installent les prérequis de la plateforme, utilisent la connexion par navigateur de GitHub pour l'accès sponsor, téléchargent l'architecture correcte, puis passent la main à `zurg setup` et `zurg doctor`. Les binaires et configurations existants sont conservés, et tous les guides d'installation manuelle restent disponibles.

## La configuration demande quels fournisseurs configurer {#setup-asks-which-providers-to-configure}

Les nouvelles installations de `zurg setup` ne supposent plus Real-Debrid. L'installateur interactif demande un ou plusieurs fournisseurs, dans l'ordre de priorité, et ne collecte que les identifiants des fournisseurs sélectionnés. Les installations non interactives peuvent répéter `--provider` et utiliser les options de fichier de jeton propres à chaque fournisseur, ou leurs variables d'environnement. Les configurations existantes sont toujours conservées, et les anciennes entrées Real-Debrid `--token-file`, `TOKEN` et `RD_TOKEN` restent compatibles lorsqu'elles sont fournies explicitement.

## Une rafale plus grande que la fenêtre d'historique de Sonarr ne perd plus d'imports {#a-burst-larger-than-sonarrs-history-window-no-longer-loses-imports}

Sonarr et Radarr demandent à SABnzbd chaque tâche de la file d'attente, mais seulement les soixante entrées les plus récentes de l'historique. Ça correspond en général bien à un vrai downloader : les téléchargements terminés arrivent petit à petit, et le client supprime chacun une fois importé. Une bibliothèque NZB en cache, c'est différent. Une recherche de saison en masse peut terminer des centaines de tâches d'épisodes individuelles avant la prochaine interrogation du client, et zurg supprimait autrefois toutes ces tâches de la file tout en ne renvoyant que soixante entrées dans l'historique. Chaque tâche au-delà de cette page était absente des deux réponses : le client ne l'importait ni ne la marquait en échec, et sa release restait indéfiniment à la racine de `__magic__`.

zurg garde maintenant les tâches terminées au-delà de cette page visible dans la file d'attente. Au fur et à mesure que le client importe et supprime les soixante premières, les terminaisons suivantes passent dans l'historique. Une saison récupérée sous forme d'épisodes individuels se vide donc par lots limités, au lieu de lutter contre une fenêtre de taille fixe ; un pack de saison, lui, se comporte toujours comme une seule tâche.

## Une suppression via le montage fonctionne toujours, et `dav_allow_delete` a disparu {#a-delete-through-the-mount-always-works-and-dav_allow_delete-is-gone}

Supprimer un fichier depuis un serveur média pointé sur le montage ne faisait rien de visible : zurg refusait la requête WebDAV DELETE avec un 403, rclone transformait ça en erreur d'E/S, et le client signalait un échec sans aucune cause. Plex répond un simple `400 Bad Request` sans rien écrire dans ses logs. Le bouton ne marchait donc pas, et rien ne disait pourquoi. La clé qui autorisait cela, `dav_allow_delete`, est supprimée. Un DELETE passant par le montage est maintenant pris en charge partout, sans aucune configuration. Un fichier de config qui contient encore cette clé ne pose pas de problème, les clés inconnues sont simplement ignorées. Elle ne fait juste plus rien.

Ce que cette clé protégeait, par contre, n'a pas disparu, donc il vaut mieux le dire clairement : rclone ne sait pas exprimer « écraser ». Quand il vide un fichier réécrit, il envoie un DELETE suivi d'un PUT. Ça veut dire qu'un programme qui réécrit un fichier sur place (un outil qui écrit des `.nfo`, un passage trickplay, un renommage \*arr, ou un simple `touch` perdu) supprime la release de ton compte debrid au lieu de remplacer le fichier. Le montage utilise les identifiants de rclone, donc rien en amont ne peut distinguer ça d'une suppression volontaire. La moitié PUT est toujours refusée, ce qui empêche la séquence de se terminer en silence. Si quelque chose écrit dans ton montage, mets `mount_read_only: true`. L'écriture échoue alors au niveau du noyau, avant même d'atteindre zurg.

## La watchlist Plex acquiert via vos indexeurs Newznab {#the-plex-watchlist-acquires-through-your-newznab-indexers}

Le moniteur de watchlist fonctionne enfin, et il utilise vos propres indexeurs. L'ancienne version cherchait via une clé API DMM, et elle a cessé de fonctionner en silence quand Plex a déplacé la watchlist vers son hôte discover, puisque le point de terminaison interrogé a commencé à répondre 404. Il interroge maintenant le bon hôte, et chaque nouvel élément de la watchlist est recherché sur les indexeurs Newznab que vous avez déjà configurés : un film devient la meilleure release correspondante, une série est acquise saison par saison en **privilégiant les packs de saison** plutôt que les épisodes isolés. Si aucun pack n'a été publié pour une saison, on revient aux épisodes isolés, avec la meilleure release pour chaque épisode. Et si une release choisie dont le lien NZB ne se télécharge pas (par exemple un 429 dû à la limite de rafales de l'indexeur) passe à la candidate suivante du classement, au lieu de faire perdre l'élément.

Le NZB choisi est envoyé au backend Usenet avec les mêmes règles de nommage que le point de terminaison SABnzbd et l'addon Stremio, pour que les trois surfaces retrouvent mutuellement leurs téléchargements au lieu de les dupliquer. Un élément ne quitte la watchlist qu'une fois que quelque chose a bien été acquis. L'ancien ordre supprimait d'abord et posait les questions ensuite : une erreur faisait donc disparaître l'élément de votre liste en silence.

Configurez-le avec le nouveau bloc `watchlist:` : `enabled`, `check_every_secs` (par défaut 60), `indexers` (vide, il reprend `stremio.indexers`), `max_size_gb` (par défaut 40, pour les films et les épisodes isolés), `max_season_size_gb` (par défaut 100, pour les packs de saison) et `quality` (`best`, `4k`, `1080p`, `720p`, `smallest`). Les clés héritées `plex_watchlist_*` gardent leur sens. Un `plex_token` suffit pour Plex : le moniteur communique avec le service cloud de Plex, donc il fonctionne très bien sur une instance sans `plex_server_url`.

Les recherches de séries commencent par l'id TVDB et réessaient une seule fois avec l'id IMDb si rien n'est trouvé : les indexeurs indexent les séries par TVDB, et leur correspondance IMDb au niveau de la série est tellement incomplète qu'une série très indexée peut renvoyer zéro résultat à une recherche imdbid.

Chaque clé se trouve sur la page de configuration, sous **Plex Watchlist**, et dans [la référence de configuration](config.md#watchlist).

## Un addon Stremio au-dessus de vos indexeurs Newznab {#a-stremio-addon-over-your-newznab-indexers}

Zurg peut maintenant répondre directement à Stremio. Active le bloc `stremio:`, liste tes indexeurs Newznab, puis colle l'URL `/stremio/<token>/manifest.json` inscrite dans les logs dans Stremio. Le client demande des flux par identifiant IMDb, et zurg interroge les indexeurs (films avec `t=movie`, épisodes avec `t=tvsearch` avec la saison et l'épisode). Les résultats reviennent classés par résolution en priorité, sous forme de flux lisibles. Quand tu choisis un flux, le NZB est envoyé au backend Usenet en suivant les mêmes règles de nommage que l'endpoint SABnzbd. Ainsi, une release ajoutée deux fois est retrouvée au lieu d'être dupliquée. Le flux est ensuite lu via l'endpoint signé `/strm/e/`, avec les plages, le basculement et le contenu des archives, tout compris. Tout ce qui est lu est ajouté à la bibliothèque et apparaît donc dans Plex comme n'importe quelle autre release.

Le token dans le chemin constitue toute l'autorisation. Il est généré et conservé dans `data/stremio-token` quand la config n'en indique aucun. Les résultats de recherche sont mis en cache dans `data/stremio-cache`, donc rouvrir un titre ne coûte aucun appel aux indexeurs. La durée du cache dépend de ce que la recherche a trouvé : une heure par résultat jusqu'à quatre, puis `stremio.cache_hours` (24 par défaut) à partir de cinq. Une réponse vide n'est jamais mise en cache. Une liste de flux en cache contient un élément de rafraîchissement qui vide le cache de ce titre. Les releases plus grosses que `stremio.max_size_gb` (40 par défaut) sont retirées de la liste, pour qu'un remux de disque complet ne passe pas devant toutes les options lisibles.

Pour tout le fonctionnement, y compris le coût de la première lecture, consulte [L'addon Stremio](../guides/stremio.md).

## Un seul dossier constitue toute l'installation Docker, et il se monte au premier lancement {#one-folder-is-the-whole-docker-install-and-it-mounts-on-the-first-run}

La méthode documentée pour lancer zurg dans Docker était un seul `docker run` avec un `TOKEN` dedans, et ça donnait un conteneur qui ne montait rien. La config générée laissait `rclone_enabled` désactivé et `mount_path` non défini, donc `/zurg_mnt/zurg` restait vide jusqu'à ce qu'on trouve les deux options dans le Dashboard. Et cette config était écrite à l'intérieur du conteneur, donc le `docker pull` suivant jetait la réponse avec le cache de la bibliothèque. Le démarrage rapide avait besoin d'une note de bas de page listant ces deux points, ce qui revient à admettre que le démarrage rapide ne fonctionne pas.

`MOUNT_PATH` pré-remplit maintenant `rclone_enabled: true` et `mount_path` dans la config lors du lancement qui la crée, à côté de ce que `TOKEN` pré-remplissait déjà. Le répertoire de travail de l'image est `/config`, et tout ce que zurg conserve s'y résout : `config.yml`, `data/`, `logs/`, `dump/`, `strm/`, `nzbs/` et le cache rclone. Donc un seul `-v ~/zurg:/config` contient toute l'installation, et une mise à jour de l'image ne déplace rien. Un premier lancement tient en une seule commande et se termine avec une bibliothèque montée, sans passer par une corvée dans le Dashboard.

Les deux variables ne sont lues **que s'il n'existe pas encore de fichier de config**, et sont ignorées ensuite. C'est la même règle que `log_level` applique à `LOG_LEVEL`, pour la même raison : un `MOUNT_PATH` oublié dans un fichier compose ne doit jamais annuler en silence un mount path modifié plus tard dans le Dashboard. Au démarrage, zurg affiche maintenant un avertissement si l'une est définie et ne correspond pas à la config, pour qu'un opérateur qui redéploie sans effet sache pourquoi.

Les installations faites avec l'ancienne structure ne sont pas touchées. Docker crée le point de montage cible de chaque bind mount, donc la présence de `/app/config.yml`, `/app/data` ou `/app/logs` signale l'ancienne structure, et le conteneur continue d'utiliser `/app` dès qu'il en voit une. La procédure complète, ainsi que ce qui casse un montage visible depuis l'hôte, est dans [Docker](../setup/docker.md).

## TorBox et AllDebrid reçoivent aussi le `.torrent`, donc un grab privé n'est pas laissé en suspens {#torbox-and-alldebrid-are-handed-the-torrent-too-so-a-private-grab-is-not-left-hanging}

Le fichier `.torrent` qu'un \*arr envoie a commencé à voyager avec l'ajout de la dernière release, mais seul Real-Debrid pouvait en accepter un. Les deux autres comptes recevaient encore uniquement le info hash, ce qui, pour la release d'un tracker privé, est la seule forme qu'ils ne peuvent pas utiliser. Rien n'échouait, et c'est ce qui rendait le problème difficile à voir : mesuré sur le compte TorBox en direct, un hash sans essaim public était accepté avec un id de torrent, puis restait en `checking` en affichant `size: -1`, sans liste de fichiers et avec une estimation de cent jours, exactement comme signalé pour une récupération TorrentLeech qui « reste bloquée, rien ne se télécharge ». Le fichier de la même release recevait une réponse immédiate avec son vrai nom, sa vraie taille et sa liste de fichiers, et l'endpoint qBittorrent pouvait faire son travail.

Les deux comptes acceptent maintenant le fichier. `createtorrent` de TorBox et `magnet/upload/file` d'AllDebrid l'acceptent à la place du magnet et répondent dans la forme que l'ajout par magnet renvoyait déjà, donc rien en aval de l'ajout ne change. AllDebrid indique toujours si l'upload lui-même contenait déjà le contenu, c'est la seule réponse de cache que ce compte donne jamais. Vérifié en conditions réelles via le propre chemin d'ajout de zurg sur les deux : une release en cache, uploadée puis relue, affichait `done` à 100 % avec sa liste de fichiers en quelques secondes, et une release que personne ne détient était relue avec son nom, sa taille, et bloquée faute de pairs, un état sur lequel l'endpoint peut agir, alors que le hash donnait un torrent qui ne se résout jamais et ne se termine jamais.

Un refus est aussi désormais lisible. Un appel TorBox refusé avec un 4xx arrivait à l'appelant sous la forme du « unexpected status code: 400 » brut du client HTTP partagé, parce que le corps de la réponse, où TorBox met son propre code d'erreur et son détail, était écarté au profit de cette erreur. Un `.torrent` que TorBox refuse de traiter était donc signalé à l'\*arr sous forme de simple numéro de statut, sans rien d'autre. Le corps est maintenant lu en premier, et la raison donnée par le compte accompagne le refus.

Pour savoir quoi faire quand vous configurez les indexeurs : [Sonarr et Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## Les entrées d'archives compressées sont diffusées, décodées à la demande {#compressed-archive-entries-stream-decoded-on-demand}

Une entrée RAR compressée ou zip en deflate ne peut pas répondre à une lecture par plage comme le ferait une entrée stockée. Ses octets n'existent qu'à travers un décodeur qui doit démarrer depuis le début de l'entrée. zurg les refusait donc : une release uniquement compressée recevait un 415, et les entrées compressées voisines d'entrées stockées étaient ignorées. C'était la bonne réponse pour un streamer, mais elle cachait la majeure partie du catalogue ancien d'Usenet : tous les posteurs qui avaient compressé leurs fichiers, en entier.

Ces entrées sont maintenant servies en décodant à la demande, vers l'avant, dans une fenêtre bornée en mémoire. Rien n'est écrit sur le disque, et rien n'est décodé que si une lecture le demande. La lecture séquentielle, celle que génère un lecteur, arrive au bord de la fenêtre et la fait avancer un peu à chaque lecture. Si on revient en arrière au-delà de ce que la fenêtre a gardé, le décodage repart du début de l'entrée. Les octets de l'entrée complète sont ceux qu'unrar extrairait : sur un vrai volume RAR4 compressé, les trois entrées jpg se décodent octet par octet à l'identique par rapport au même fixture lu par un second décodeur indépendant, md5 pour md5.

Parcourir les volumes d'un jeu découpé nécessitait la chaîne de volumes de rardecode, qui ouvre `.part02.rar` depuis le système de fichiers. Or les volumes de zurg se trouvent derrière des lecteurs réseau par plage. Le décodeur est désormais intégré dans `internal/rardecode` (MIT, version amont v1.1.3) avec un seul changement : `OpenReaderOver` prend un opener, pour que chaque volume suivant soit récupéré dans le jeu par le nom que l'archive elle-même déduit. Les listings changent de forme en conséquence : une release uniquement compressée présente sa charge utile (`stream_compressed_archives: false` rétablit les anciens refus), et une archive mixte liste ses entrées compressées à côté de ses entrées stockées. Liste de version 15.

## Sonarr et Radarr peuvent prendre des torrents, et Prowlarr peut les pousser {#sonarr-and-radarr-can-grab-torrents-and-prowlarr-can-push-them}

zurg peut répondre aux \*arrs comme s'il était un qBittorrent. Ils lui envoient un magnet ou un `.torrent`, il ajoute le hash d'info à un compte debrid (Real-Debrid, TorBox ou AllDebrid, selon celui qui est configuré). Une fois la release dans la bibliothèque, le torrent passe à l'état terminé avec un dossier sous `__magic__` à importer. L'import est le même renommage que l'endpoint SABnzbd fait depuis toujours pour les téléchargements Usenet : une ligne dans la table `__magic__`, sans rien déplacer.

L'endpoint est enregistré sur `/api/v2` et `/qbittorrent/api/v2`. Il reste désactivé tant qu'on ne le demande pas, et il est protégé par une clé API que les clients envoient comme jeton bearer. Un grab est proposé à chaque compte qui accepte les torrents, dans l'ordre de `providers:`. Si un grab cesse d'avancer (pas de changement d'étape, pas de hausse de la progression) pendant `qbittorrent.download_timeout_mins` minutes (quinze par défaut), il est retiré de son compte et tenté sur le suivant. `0` ne prend que les contenus déjà en cache sur un compte et refuse le reste dès l'ajout. C'est le seul refus sur lequel les \*arrs agissent. Ce que fait le compte avec un téléchargement est traduit dans les états que comprennent les clients, avec le débit, le swarm et le temps restant quand le compte les fournit.

Une limite à connaître : l'API de qBittorrent ne permet pas de signaler qu'un téléchargement a échoué. Une release qu'aucun compte n'accepte arrive donc au client sous forme d'avertissement, et non comme une entrée de liste de blocage. Elle est visible dans la file d'attente avec la raison, mais elle n'est jamais relancée sans intervention. L'endpoint SABnzbd n'a pas ce problème.

Prowlarr utilise le même endpoint pour ce qu'un client de téléchargement représente pour lui : pousser une release vers le compte à la main. Rien n'est importé après un push Prowlarr, c'est le rôle des \*arrs.

Procédure complète, capturée sur une installation en direct : [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## `__magic__`, un répertoire que vous pouvez organiser {#__magic__-a-directory-you-can-organise}

Chaque répertoire que zurg expose est un filtre enregistré. Une release se trouve dans `movies` parce qu'elle correspond au filtre movies, et elle se trouve en même temps dans `__all__`, dans `recent` et dans `movies`. Il n'y a donc jamais eu d'endroit dans la bibliothèque où *mettre* quelque chose. Ça va tant qu'un programme n'a pas besoin de déplacer un fichier. Radarr et Sonarr importent en déplaçant, et un montage qui ne peut pas recevoir un déplacement les oblige à copier : chaque import retélécharge toute la release depuis l'hébergeur debrid ou depuis Usenet, ce qui est justement ce que le montage est censé éviter.

`__magic__` est un nouveau répertoire de premier niveau qui commence comme une copie exacte de `__all__` : chaque release apparaît comme un dossier, contenant exactement ce que contient `__all__/<release>/`, y compris le contenu d'une archive virtualisée. À l'intérieur, vous pouvez déplacer n'importe quoi, n'importe où. Lancez `mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01`, puis `mv` d'un épisode dedans, et l'épisode est là : aucun octet déplacé, aucun torrent renommé, rien de retéléchargé, et `__all__` reste inchangé. Un déplacement réécrit une seule ligne d'une petite table, et cette table utilise comme clé le hash de contenu de la release et le chemin propre du fichier à l'intérieur de celle-ci. Ainsi, une réparation qui rajoute la release et reconstruit tous les identifiants autour ne fait pas perdre l'endroit où vous avez rangé vos fichiers. Renommer une release depuis le tableau de bord ne le fait pas non plus.

Les déplacements fonctionnent dans les deux sens. Un fichier peut être déplacé *dans* un dossier de release comme *hors de* celui-ci, et le dossier le liste à côté des entrées propres à la release. C'est ce dont a besoin un programme qui remet quelque chose dans le dossier d'où il importe. Quand un même nom arrive de deux endroits à la fois, c'est le choix délibéré qui gagne : ce que vous avez déplacé l'emporte sur le nom que la release lui donne, qui l'emporte à son tour sur un fichier présent dans `data/local`. Le perdant n'est pas listé, plutôt que listé deux fois.

La suppression est l'autre moitié, et par défaut elle masque au lieu de détruire. Un `rm` dans `__magic__` retire l'entrée de `__magic__`, mais la laisse dans `__all__` et dans chaque répertoire de filtre. Un client qui réorganise une bibliothèque ne peut donc rien perdre. Un dossier de release peut disparaître de la même façon, ce qui permet à Sonarr de supprimer le dossier de travail après un import sans toucher à la release qu'il vient d'importer. `magic.allow_delete: true` active le sens plus fort pour les fichiers, où le contenu part aussi. Un dossier de release ou un répertoire ne fait toujours que se masquer, quelle que soit la valeur de cette option.

Cette fonctionnalité est désactivée par défaut, car c'est une arborescence accessible en écriture, et un \*arr pointé vers la mauvaise racine peut réorganiser toute une bibliothèque :

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

Les deux clés `sidecar_` servent aux clients qui montent `/dav` directement, plutôt que via le montage propre de zurg. Ces clients envoient à zurg un `PUT` d'un nouveau `.nfo`, d'une affiche ou d'une piste de sous-titres. zurg écrit désormais le corps dans `data/local/__magic__/…`, c'est-à-dire dans la même arborescence que celle où le montage propre de zurg écrit déjà ces fichiers. Les deux vues affichent ainsi un seul répertoire au lieu de deux, et le fichier se relit avec les plages d'octets, une longueur et une date de modification, comme tout autre fichier. Les plafonds empêchent que cela ne devienne discrètement un stockage de fichiers généraliste : un fichier dépassant `sidecar_max_mb` est refusé avec un 413, et un fichier qui ferait dépasser `sidecar_budget_mb` à l'arborescence est refusé avec un 507. On ne peut rien écraser de ce que la bibliothèque renvoie, qu'il s'agisse d'un dossier de release, d'une entrée de celui-ci, ou d'un chemin vers lequel quelque chose a été déplacé. Dans ces cas, la réponse est un 403. Enfin, un déplacement ne détruit jamais un vrai fichier pour faire de la place à une ligne.

Deux choses sont à savoir avant de pointer quoi que ce soit dessus. Les répertoires de filtre ne sont volontairement pas modifiés. Une release déplacée dans `__magic__` reste donc dans `recent` et `movies` sous son nom d'origine. Pointez un serveur multimédia sur `__magic__` **ou** sur les filtres, pas sur les deux. Par ailleurs, le montage a toujours été accessible en écriture dans un seul sens : tout fichier réellement nouveau écrit dedans (un `.nfo`, un sous-titre, une affiche) atterrit dans le `data/local` propre à zurg et est fusionné dans la liste. C'est pourquoi les sidecars à côté d'une release fonctionnent tout simplement, et pourquoi le test d'écriture du dossier racine d'un \*arr réussit.

`dav_allow_rename` et `dav_allow_delete` n'ont rien à voir avec tout cela. Ils protègent le chemin qui renomme et supprime ce que détient le compte debrid, alors qu'une écriture sous `__magic__` n'atteint aucun compte. `mount_read_only: true` reste prioritaire sur tout.

Le tableau de bord dispose d'une page dédiée, à `/magic/`. Elle affiche chaque ligne de la table, regroupée par release. Pour chacune, elle indique ce qu'elle est, de quel fichier de quelle release elle provient et d'où ce fichier est servi aujourd'hui. Elle donne aussi le nombre de lignes, l'espace disque occupé par le journal et l'instantané, et la part de `sidecar_budget_mb` qu'utilisent les vrais fichiers à côté de la bibliothèque. Elle indique enfin la taille de l'ensemble de `data/local`, qui est le chiffre permettant de savoir si quelque chose s'importe par copie. Un client qui copie au lieu de déplacer y place les octets, et rien d'autre sur le tableau de bord ne le montrerait jamais.

Trois des états affichés étaient inaccessibles depuis un client. Un placement peut être **reset** : le fichier revient alors là où la bibliothèque le place. Un marqueur de suppression (tombstone) peut être **unhidden** : l'entrée est de nouveau listée. Une ligne **dangling**, dont la release, ou le fichier à l'intérieur de celle-ci, n'est plus présent dans la bibliothèque, peut être supprimée, une à une ou toutes d'un coup. Ce dernier cas est nouveau. Une telle ligne ne se résout vers rien : aucun client ne peut donc la lister, la déplacer ou la supprimer. Elle est volontairement conservée plutôt que supprimée, car une réparation qui rétablit la release rétablit aussi le placement. Jusqu'ici, il n'existait aucun moyen de la nettoyer.

Les sidecars sont eux aussi listés, avec la même classification appliquée. Un vrai fichier dans un dossier que plus rien ne référence (un `.nfo` à côté d'une release ayant quitté la bibliothèque, ou dans un placement qui a été oublié) est affiché comme **orphaned** et compté à part du reste. Rien n'est nettoyé automatiquement, pour la même raison qu'une ligne dangling ne l'est pas : le fichier vous appartient toujours, et une réparation qui rétablit la release reprend en charge le dossier. Supprimer un de ces fichiers depuis cette page efface réellement le fichier, exactement comme un `DELETE` passé par le montage. Chacun de ces boutons demande au montage d'oublier les listings qu'il a modifiés, car il met un répertoire en cache pendant douze heures lorsque le polling est désactivé.

`magic:` et `sabnzbd:` sont désormais modifiables depuis la page de configuration. Tous deux sont marqués **Restart Required**, parce que c'est vraiment le cas : les routes qui servent `__magic__` et le point d'accès SABnzbd sont fixées une fois pour toutes au démarrage, à partir de précisément ces valeurs. Activer l'une d'elles l'écrit dans `config.yml` sans rien changer à l'exécution en cours. La page `__magic__` le dit explicitement, au lieu d'afficher un espace de noms vide comme si tout allait bien.

### Sonarr et Radarr peuvent maintenant donner un NZB à zurg {#sonarr-and-radarr-can-now-hand-zurg-an-nzb}

La raison d'être de `__magic__` est qu'un \*arr ait un endroit où importer, et zurg fournit maintenant l'autre moitié : un point de terminaison sur `/api` qui répond à Sonarr et Radarr comme s'il s'agissait d'un SABnzbd. Indiquez-leur l'hôte et le port de zurg, collez la clé d'API, et les envois arrivent dans `nzbs/` pour le backend Usenet. Une fois la release dans la bibliothèque, la tâche passe à Completed avec un dossier sous `__magic__`, et l'import n'est qu'un renommage à l'intérieur du montage : une ligne dans la table, aucun octet lu, rien à télécharger depuis Usenet pour le ranger dans un dossier de série.

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

Désactivé par défaut, et il faut les deux parties pour qu'il soit utile : un fournisseur `nzb` pour lire le NZB, et `magic.enabled` pour avoir un endroit où importer. Le point de terminaison n'est pas protégé par l'authentification basique de zurg, car aucun des deux \*arr n'en envoie jamais à un client de téléchargement, et leur couche HTTP lit un 401 comme « impossible de se connecter ». La clé d'API est donc le seul verrou : protégez ce port en conséquence. Les dossiers racines doivent se trouver **à l'intérieur** de `__magic__` (`__magic__/tv`, `__magic__/movies`), jamais sur celui-ci ni au-dessus, sinon le contrôle de santé des dossiers racines des clients aura quelque chose à redire.

Un point à connaître avant de basculer une bibliothèque : **le signal d'échec est partiel**. Une release que la bibliothèque détient mais dans laquelle rien n'est importable (tous les fichiers cassés, supprimés ou filtrés, ou rien d'autre que des éléments de réparation et des fichiers annexes, ce que produit un NZB ne contenant que des volumes de récupération) est signalée `Failed`, ce qui fait que les deux clients la mettent sur liste noire et en envoient une autre. Un jeu RAR compte comme contenu, puisque zurg diffuse la vidéo directement depuis celui-ci, sauf s'il s'agit d'un jeu que zurg ne peut pas diffuser du tout, ne contenant que des entrées compressées : il est alors signalé Failed dès que quelque chose l'a ouvert et a constaté cela. Ce verdict est conservé avec la release, car l'obtenir coûte une lecture de chaque volume du jeu. Ce qui n'est pas signalé, c'est un post dont les articles ont expiré sur le serveur de news : zurg ne le vérifie pas encore, donc une release morte est signalée Completed comme les autres et échoue à la première lecture, et Sonarr voit un échec d'import plutôt qu'un échec de téléchargement. Ce cas reste une décision manuelle. Tout le reste du flux fonctionne, y compris le nettoyage après import : le dossier de tâche que Sonarr supprime devient une pierre tombale et la release reste dans `__all__`.

Un envoi n'attend pas le prochain cycle d'interrogation des changements : zurg relit le dossier surveillé dès qu'il y a écrit quelque chose, et seulement pour les comptes Usenet. Un pack de saison, c'est vingt envois en quelques secondes, et relister une bibliothèque debrid de dizaines de milliers de torrents pour remarquer un fichier local serait vingt fois le mauvais travail. Si aucun fournisseur `nzb` n'est configuré, zurg le signale maintenant au démarrage, plutôt que d'accepter des envois que rien ne lira jamais.

La page `__magic__` liste les tâches, en lecture seule : le `nzo_id` par lequel chaque client connaît un envoi, sa catégorie, son heure d'arrivée, si la bibliothèque affiche déjà la release, et, une fois qu'elle le fait, le dossier à partir duquel le \*arr importe.

La configuration complète, y compris le mappage de chemins distants pour les \*arr conteneurisés et la signification de chaque erreur du test de connexion, se trouve dans `docs/sabnzbd.md`.

## Le montage utilise davantage de la bande passante disponible {#the-mount-reaches-more-of-the-bandwidth-it-has}

Lire un fichier via le montage rclone était plus lent que récupérer les mêmes octets en HTTP, et la raison tenait au début d'une lecture plutôt qu'à son déroulement. Le premier morceau était demandé à 4 MB, puis doublait à chaque fois. Une lecture qui commençait à un décalage froid passait donc la plupart de son temps en dessous de la vitesse que la connexion pouvait réellement supporter, et chaque seek lance une nouvelle lecture. Le premier morceau est maintenant demandé à 32 MB.

Mesuré sur un hôte avec environ 70 MB/s de bande passante de téléchargement utilisable, chaque réglage étant testé à tour de rôle pour qu'une minute lente ne tombe pas sur un seul d'entre eux : le débit médian du montage sur Real-Debrid est passé de 49 à 57 MB/s, et TorBox a évolué de la même façon. AllDebrid gagne moins ici, car sa limite s'applique par connexion et non par compte.

La taille des morceaux explique à elle seule tout l'effet. Le read-ahead FUSE, relevé en parallèle pendant les tests, n'a rien changé. Ça ne coûte pas non plus de bande passante supplémentaire : la taille du morceau correspond à ce qui est *demandé*, pas à ce qui est transféré, et rclone arrête de tirer des données dès que la lecture s'arrête. Une lecture de 4 MB télécharge toujours 6 MB, comme sans read-ahead du tout. Une bibliothèque parcourue et échantillonnée plutôt que regardée d'un bout à l'autre ne télécharge donc pas plus qu'avant.

Rien à changer. La nouvelle valeur devient la valeur par défaut, et `rclone_extra_args` la remplace toujours.

## `zurg benchmark-my-setup` indique la vitesse réelle de votre installation {#zurg-benchmark-my-setup-answers-how-fast-the-setup-actually-is}

Jusqu'ici, la seule façon de savoir si un flux lent venait du compte, de l'hébergeur ou du montage, c'était de deviner. La nouvelle commande lit de vrais octets par le même chemin qu'un lecteur utilise et affiche la distribution (minimum, médiane, moyenne, maximum et temps jusqu'au premier octet), plutôt qu'un seul chiffre qu'un échantillon malchanceux aurait pu produire.

Elle fonctionne en trois phases. D'abord chaque compte seul, qui est le chiffre à comparer à ce que le service promet. Ensuite tous les comptes configurés en même temps, seule phase capable de distinguer un fournisseur lent d'une liaison montante saturée : des comptes qui tiennent chacun 70 MiB/s seuls mais 25 MiB/s ensemble forment un seul goulot d'étranglement, pas trois problèmes, et le rapport indique lequel des deux il examine. Enfin la même lecture via le montage rclone, où l'écart avec la première phase correspond à ce que coûtent FUSE et le VFS. La phase montage est ignorée quand `rclone_enabled` est désactivé.

Les échantillons sont placés à des décalages aléatoires, et ce n'est pas un détail. Chaque couche en dessous met en cache : le VFS de rclone garde ce qu'il a déjà récupéré, un edge CDN du débrideur garde ce qu'il a déjà servi. Donc relire un même décalage mesure ces caches au lieu de la liaison. Sur une installation réelle, le même fichier a affiché 47 MiB/s à froid et 285 MiB/s à la deuxième lecture de la même zone.

La taille d'échantillon change ce que signifie le chiffre du montage, et le rapport le dit. rclone ouvre un fichier avec `vfs_read_chunk_size` puis double à partir de là, donc un échantillon court passe la plupart de son temps à monter en régime. Mesuré sur une installation, cela donne 47 MiB/s pour un échantillon de 256 MiB contre 88 MiB/s pour 1 GiB, alors que HTTP reste stable autour de ~70 dans les deux cas. La valeur par défaut de 128 MiB correspond au chiffre pour les recherches et les déplacements dans le fichier, et `--sample-mb 1024` donne le plafond soutenu. Aucun des deux n'est faux, et l'exécution indique laquelle tu viens de mesurer.

`-n` définit le nombre d'itérations, `--provider` limite l'exécution aux comptes nommés, `--skip-mount` et `--skip-concurrent` retirent une phase, et `--json` produit le rapport pour les scripts. La commande consomme de la bande passante réelle sur les comptes de l'opérateur : itérations x taille d'échantillon par compte, deux fois, plus la phase montage. Lance-la depuis le répertoire de zurg : le backend NZB lit son dossier `nzbs/` relativement au répertoire de travail, et un compte qui ne liste rien est signalé comme tel, et non comme un compte sans gros fichiers.

## Les releases Real-Debrid qui fonctionnent ne sont plus marquées cassées après une vérification de lien {#working-real-debrid-releases-are-no-longer-marked-broken-after-a-link-check}

Depuis le nightly du 2026-08-20, une bibliothèque saine pouvait remplir le journal avec `Link verification failed during refresh` et `keeping files as broken`, chaque entrée portant un `404 Not Found` et un `invalid_download_code` provenant d'un hôte de téléchargement. Il n'y avait pourtant rien de cassé dans les releases.

Ce nightly ajoutait un nettoyage des lignes que Real-Debrid crée dans My Downloads : chaque lien vérifié par zurg en crée une, et si on ne fait rien, la liste grossit d'une ligne par torrent et par build à froid, jusqu'à ce que le démarrage parcoure des dizaines de milliers de lignes. Le nettoyage supprime ces lignes en arrière-plan, en partant du principe qu'une ligne et l'URL qu'elle a générée sont deux choses distinctes.

Elles ne le sont pas. Supprimer la ligne révoque le code de téléchargement, et seul un hôte qui l'a déjà récupéré peut le maintenir en vie. Mesure du 2026-08-22 : un code généré sur `124-4` puis récupéré une fois via `44-4` répondait toujours `200` sur `44-4`, tandis que `124-4` et un `125-4` non touché répondaient `404 invalid_download_code`. zurg choisit l'hôte de téléchargement à chaque requête, parmi les plus rapides, donc l'hôte qui a vérifié un lien est rarement celui qui le demandera ensuite. La résolution restait en cache pendant quatre heures, et chaque requête sur ce lien pendant cette fenêtre recevait un `404`, lu comme un lien pourri, et la release était marquée cassée.

Désormais, une résolution quitte le cache de liens au moment où sa ligne est mise en file d'attente pour suppression, pour que plus rien ne rejoue une URL sur le point de disparaître ; la requête suivante en résout une nouvelle. Les lignes sont toujours nettoyées. Les releases marquées cassées à tort se rétablissent au prochain refresh, sans rien à ré-ajouter ni à re-scanner.

## Les séries nommées par date de diffusion sont classées comme séries, pas comme films {#shows-named-by-air-date-are-filed-as-shows-not-movies}

Une émission sans numéros de saison et d'épisode est nommée d'après sa date de diffusion, par exemple `WWE SmackDown 2026-08-21`, et c'est pareil pour toutes les émissions quotidiennes et de fin de soirée qui suivent. Rien dans le test d'épisode ne connaissait cette convention. Il cherchait `S01E01`, un numéro de saison ou d'épisode écrit en toutes lettres, le hash d'une release d'anime et, si rien de tout ça ne marchait, une série de fichiers numérotés à lire comme une séquence. Une release quotidienne est un fichier unique avec une seule date, donc la réponse était non, et la release tombait dans le premier dossier qui l'acceptait, qui est en général celui des films.

La date de diffusion compte maintenant comme le marqueur qu'elle est, écrite `2026-08-21`, `2026.08.21`, `2026 08 21`, `2026_08_21` ou `20260821`. Seules les vraies dates sont retenues : le mois doit être l'un des douze et le jour l'un des trente et un. Ainsi, une année placée à côté d'une résolution, comme dans `Movie.2026.05.1080p`, n'est jamais prise pour une date. Mesuré sur une bibliothèque de 6755 releases, aucun film ne change de dossier. Mesuré sur 4734 vraies releases d'émissions quotidiennes, 4633 sont maintenant reconnues. Les autres sont d'anciens noms scene qui abrègent l'année sur deux chiffres ou la placent en dernier. Impossible de les distinguer d'une disposition des canaux audio avec un niveau de confiance suffisant.

Une bibliothèque déjà sur le disque se reclasse toute seule au démarrage, donc le prochain redémarrage suffit. Rien à rescanner ni à réimporter.
