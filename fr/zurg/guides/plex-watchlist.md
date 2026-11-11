# Acquisition depuis la watchlist Plex {#plex-watchlist-acquisition}

La liste de suivi Plex est un adaptateur du [moteur d'acquisition partagé](acquisition.md),
à côté de Seerr. Les réglages existants `watchlist.enabled` et les anciens réglages
de la liste Plex continuent de fonctionner. L'adaptateur résout les titres de la
liste dans le cloud et les transmet à l'exécuteur partagé. Il démarre après le
chargement de la bibliothèque. Il a besoin d'un fournisseur `nzb` sur la même
instance zurg, d'un compte debrid qui accepte les torrents, ou des deux.

La progression est stockée dans `data/acquisition.json`. L'ancien
`data/plex-watchlist.json` est importé une seule fois, sans être supprimé. L'historique, les délais de nouvelle tentative, le nombre de tentatives et les acquisitions qui attendent uniquement la suppression côté Plex survivent aux redémarrages. Les deux fichiers d'état sont inclus dans les sauvegardes normales. Gardez `data/` et `nzbs/` quand vous recréez les conteneurs.

Les releases viennent des indexeurs Newznab sous forme de NZB, et des indexeurs Torznab sous forme de info hashes transmis à un compte debrid qui les possède déjà. Un NZB nécessite le fournisseur `nzb`. Un torrent nécessite le compte debrid. `prefer` décide laquelle est essayée en premier parmi les releases de même résolution. Voir [Newznab et Torznab](acquisition.md#newznab-and-torznab).

Une acquisition réussie retire un élément de la liste de suivi, sauf si `remove_after_grab: false` indique le contraire ; avec cette option désactivée, le titre reste et zurg le satisfait en arrière-plan. Un titre que vous aviez déjà reste dans tous les cas : si toutes les releases qui le règlent étaient déjà dans la bibliothèque, zurg n'a rien récupéré pour lui et ne touche pas à votre liste. `only_new_items` (activé par défaut) signifie que, lorsque vous activez la fonctionnalité, elle commence à surveiller la liste plutôt que de traiter tout ce qui s'y trouve déjà. Les deux sont documentés sous [ce que l'acquisition fait à la liste d'origine de la source](acquisition.md#what-acquiring-does-to-the-sources-own-list). Chaque saison prévue doit maintenant être acquise avant qu'une série soit retirée ; les saisons réussies sont mémorisées tandis que les saisons manquantes sont réessayées. Un pack de saison est préféré. Le repli sur les épisodes isolés acquiert les épisodes trouvés dans les résultats des indexeurs, car la liste de suivi ne fournit pas d'inventaire des épisodes attendus. Il ne s'agit pas d'une surveillance continue des épisodes futurs une fois que l'élément a quitté la liste.

Le retrait attend la vérification. Une entrée de la liste est le seul enregistrement indiquant que vous vouliez un titre. Plex ne garde aucun historique d'une entrée retirée. Un titre n'est donc jamais retiré sur la foi d'un grab que personne n'a vérifié. Un NZB est vérifié auprès des serveurs de news. Un torrent doit arriver dans la bibliothèque avec des fichiers dedans. Une release qui échoue à la vérification laisse le titre en place et est mémorisée comme morte. La nouvelle tentative classe alors le candidat suivant. Une vérification impossible à effectuer laisse le titre en file d'attente, plutôt que de trancher dans un sens ou dans l'autre. Voir [vérifier un grab](acquisition.md#verifying-a-grab).

Les échecs sont réessayés avec un backoff persistant tant que l'élément reste dans la liste. Une fois l'acquisition enregistrée, un retrait Plex échoué ou interrompu est réessayé seul. Un état corrompu est conservé et l'acquisition est suspendue jusqu'à réparation ou restauration. Un échec d'écriture suspend l'acquisition jusqu'à ce que la sauvegarde réussisse.

Voir [sources d'acquisition](acquisition.md) pour la configuration, les intervalles de nouvelle tentative, le comportement de Seerr et le contrat de l'adaptateur.
