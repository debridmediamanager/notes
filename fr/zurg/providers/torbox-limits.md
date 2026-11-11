# Limites de TorBox et comment zurg s'y adapte {#torbox-limits-and-how-zurg-adapts-to-them}

zurg : le comportement de la bibliothèque a été façonné par les contraintes de Real-Debrid. Celles de TorBox sont différentes par nature, pas seulement en ampleur, et si on pilote TorBox comme Real-Debrid, le compte est limité en débit en quelques secondes dès le premier scan de la bibliothèque. Voici quelles sont ces limites, d'où viennent les chiffres, et ce que zurg fait pour chacune.

Les limites des fournisseurs sont déclarées dans le code sous forme de `debrid.Capabilities`, donc le code générique de la bibliothèque les lit au lieu de les supposer. Ajouter un backend consiste à remplir cette structure, sans modifier le gestionnaire de torrents.

## Limites de débit {#rate-limits}

| Limite | Valeur | Source |
|---|---|---|
| Tous les endpoints ensemble, par jeton d'API | 300/min | [documenté](https://api-docs.torbox.app/) |
| `POST /torrents/createtorrent` (non mis en cache uniquement) | 60/heure | documenté |
| `POST /webdl/createwebdownload`, `POST /usenet/createusenetdownload` | 60/heure | documenté |
| `GET /torrents/requestdl` | **~100 appels, puis 429** — un budget, pas un débit | mesuré, 2026-08-30 |
| Connexions simultanées vers un même hôte CDN | **exactement 20**, 429 au-delà | mesuré, 2026-08-23 |
| Plafond global de rafale | déclenché vers ~40 connexions simultanées, limite *tous* les endpoints | mesuré |
| Reprise après 429 | `Retry-After: 300`, coupure binaire | mesuré |

Les limites s'appliquent par jeton d'API et sont synchronisées sur les serveurs de TorBox, pas par IP. Donc des clients supplémentaires sur d'autres machines partagent le même budget. TorBox le dit d'ailleurs explicitement : il a arrêté d'accepter les demandes de whitelist par IP parce que la limite est liée au jeton.

Trois points rendent la situation plus dure que ce que suggère le chiffre affiché de 300/min :

- **Les 300/min ne sont pas par endpoint.** C'est un seul budget que toute la clé consomme. Régler chaque endpoint séparément peut donc faire dépasser à leur somme un plafond qu'aucun d'eux ne dépasse seul.
- **`requestdl` est bien plus strict que documenté, et ce n'est pas un débit.** C'est l'endpoint qui génère les URL de téléchargement, et il a lâché après environ 100 appels, alors que `user/me`, `mylist` et `checkcached` en ont tenu plus de 500 à la même concurrence.

  Ralentir n'en rapporte pas davantage. Mesuré le 2026-08-30 sur le compte principal, trois essais chacun repartant d'un verrouillage réinitialisé :

  | Cadence | 429 arrivé à | Durée écoulée |
  |---|---|---|
  | aussi vite que possible, montée de 60 à 240/min | appel **100** | 56s |
  | un par seconde (60/min) | appel **94** | 108s |
  | un toutes les deux secondes (30/min) | appel **101** | 198s |
  | un toutes les trois secondes (20/min) | **jamais** — 241 appels | 721s, sans erreur |

  Diviser le débit par deux a rapporté quatre-vingt-dix secondes de plus et aucun appel supplémentaire ; le diviser encore par deux a supprimé complètement le 429. Ce que le compte contient, c'est **100 appels sur cinq minutes glissantes — soit 20/min**, et seule cette lecture correspond aux quatre essais : elle prédit le déclenchement à t≈100s, t≈200s et immédiatement pour les trois premiers, et prédit que le quatrième reste exactement sur la limite et passe.

  C'est la correction qui compte pour la suite de ce fichier. Un limiteur par minute ne peut pas garder zurg sous le budget. Les valeurs de cadence ci-dessous servent donc à lisser le trafic, pas à créer de la marge. Un limiteur plus rapide ne termine pas plus vite un scan de bibliothèque : il atteint le même verrouillage plus tôt, et laisse alors le montage sans réponse pendant cinq minutes. Seul le fait de **consommer moins d'appels** augmente la distance parcourue par un scan. C'est pour cela que le read-ahead est refusé ici, et qu'identifier un fichier déjà résolu ne doit jamais coûter une requête.
- **Le 429 est une falaise, pas une pente.** Une fois déclenché, 100 % des requêtes échouent pendant environ cinq minutes. Il n'y a pas de dégradation partielle du débit à laquelle s'adapter.

Les téléchargements CDN sont comptés séparément et ne partagent **pas** le budget de l'API. Lire un fichier en streaming ne consomme jamais de quota de résolution de liens. Cela a été vérifié dans les deux sens : saturer les téléchargements CDN jusqu'au 429 a laissé `requestdl` répondre normalement, et inversement.

### Deux limites différentes, toutes deux numérotées 20 {#two-different-limits-both-numbered-20}

Le tableau ci-dessus liste 20 deux fois, et ce sont deux choses sans rapport. Les confondre est facile, et on finit par régler la mauvaise chose.

- **`requestdl` à ~20 connexions simultanées** est une limite *API* : environ 100 appels à cette concurrence avant un 429, ce qui consomme le quota de requêtes du compte.
- **20 connexions par hôte CDN** est une limite du *chemin des octets*, mesurée le 2026-08-23 avec une montée progressive. Elle ne nécessite aucun appel à `requestdl` : réutiliser une URL déjà générée suffit à l'atteindre.

Le plafond du chemin des octets est **exactement 20** et se comporte comme une limite stricte plutôt que comme une pente : 20 connexions soutenues, qu'on en demande 24, 32, 40 ou 48, les refus augmentant pour absorber tout ce qui dépasse cette limite.

Elle s'applique à l'**hôte CDN, et non à l'objet ni à l'IP**, ce qui corrige l'ancienne lecture « par IP au niveau de Cloudflare » :

- Deux fichiers *différents* servis depuis un même hôte `nexus-NNN` se partagent le budget unique de 20 et refusent le même surplus.
- La même charge répartie sur deux hôtes passe sans problème.
- 32 flux simultanés répartis sur 16 hôtes, tous depuis une même IP, passent sans problème.

Pour comparer avec les autres fournisseurs mesurés de la même façon : Real-Debrid plafonne à 32 par hôte (il refuse au niveau TCP, sans code HTTP), AllDebrid à 32 (HTTP 429), et Premiumize n'a montré aucun plafond jusqu'à 64. Le 20 de TorBox est le plus bas des quatre.

**Les edges globaux de TorBox n'ont pas cette limite.** Le 20 est une propriété des hôtes par nœud `nexus-NNN.<region>.tb-cdn.st` que `requestdl` génère. Les deux edges globaux — `nexus.erth.tb-cdn.earth` et `nexus.hare.tb-cdn.earth` — servent n'importe quel fichier du compte et ont tous deux atteint 64 connexions simultanées sans aucun refus. Seul l'hôte change : le chemin et le jeton authentifient toujours la requête. zurg ne réécrit pas vers eux aujourd'hui (le service frère `debrid` le fait, via `TORBOX_CDN_EDGE`), donc le plafond ci-dessous s'applique ici.

### Ce que fait zurg {#what-zurg-does}

- **`GetTorrentInfo` est servi depuis la liste des torrents.** La `mylist` de TorBox inclut déjà la liste des fichiers de chaque torrent, donc un rafraîchissement de la bibliothèque ne coûte qu'une seule requête au lieu d'une par torrent. Ceci est déclaré comme `Capabilities.ListIncludesFiles`, et le chemin de rafraîchissement saute à la fois l'appel par torrent et le cache d'infos sur disque pour les fournisseurs qui le définissent. Sur un compte à 213 torrents, ça fait la différence entre 213 requêtes et 1.
- **Un seul limiteur cadence tous les endpoints**, réglé à 240/min alors que la doc indique 300, pour garder de la marge pour tout ce qui utilise la même clé : le tableau de bord TorBox, un autre client, un second zurg.
- **`requestdl` a un second limiteur par-dessus**, réglé à 15/min. Une résolution puise dans les deux. Le chiffre est volontairement sous les 20/min mesurés plutôt qu'égal à eux, pour la même raison que le limiteur général est à 240 au lieu des 300 documentés : le budget est consommé par tout ce qui détient la clé, et les 20/min ont été mesurés sans rien d'autre dessus. `TestTheRequestdlBudgetCannotBeSpentInsideItsWindow` vérifie l'invariant réel — la totalité de l'allocation ne doit pas pouvoir être dépensée dans la fenêtre qui la recharge — donc la constante ne peut pas repasser discrètement au-dessus.
- **Le client de téléchargement est limité à 20 connexions par hôte CDN** (`maxConnsPerCDNHost` dans `internal/torbox/client.go`, transmis via `rdclient.HTTPClientOptions.MaxConnsPerHost`). Le `MaxConnsPerHost` de Go fait *attendre la requête 21 qu'une connexion se libère* au lieu d'échouer, donc la limite transforme un refus du fournisseur en file d'attente locale. Sans elle, le client de téléchargement héritait du réglage illimité du transport généraliste et pouvait récolter des 429 sur le chemin des octets alors que tous les limiteurs de l'API étaient respectés.
- **Les réponses 429 mettent en attente tous les appelants** pendant la fenêtre `Retry-After`, plutôt que de laisser chacun dépenser une requête pour redécouvrir le blocage. Le blocage concerne tout le compte, donc un 429 reçu sur n'importe quel endpoint retient tous les autres.
- **La concurrence est limitée à 16 requêtes en cours**, sous le plafond de rafale global d'environ 40, pour laisser de la place au client de téléchargement à côté.
- **Le read-ahead est refusé.** Sur une lecture à froid, zurg préchauffe le fichier suivant d'une release, ce que tout backend disposant d'un vrai budget par minute absorbe. Un scan de bibliothèque est le cas qui casse ça : il ouvre chaque fichier exactement une fois, donc chaque ouverture est à froid, le refus de lecture à chaud ne se déclenche jamais, et le compte reçoit deux résolutions par fichier. Mesuré le 2026-08-30 : un scan de quarante fichiers a déclenché exactement quarante résolutions spéculatives en plus de ses quarante lectures — la moitié du budget, dépensé sur des fichiers que personne n'avait demandés. TorBox déclare `Capabilities.SpeculativeResolutionsAffordable` à false et n'en reçoit aucune.
- **Nommer un fichier résolu ne coûte aucune requête.** Chaque résolution se termine par une recherche du nom et de la taille de ce fichier pour l'enregistrement de téléchargement. Cette recherche passait par l'instantané de la liste, donc une fois sa fenêtre de fraîcheur de trente secondes expirée, la lecture suivante récupérait toute la liste des torrents avant de pouvoir répondre — pendant un scan, une fois toutes les trente secondes tant que le scan tournait, et sur une bibliothèque de 3,700 torrents cette liste occupe quatre pages. Elle lit désormais la liste déjà en main, quel que soit son âge, puisque les noms et tailles des fichiers d'un torrent terminé ne peuvent pas changer.
- **Le cache des liens est conservé un jour, avec récupération en cas de refus explicite.** Lors du test du 2026-08-30, des appels `requestdl` répétés ont renvoyé des URL identiques, y compris une heure plus tard, et une URL vieille de 3h25 servait encore `206`. Ça prouve la réutilisation, pas une durée de vie illimitée. Le 2026-09-04, une URL en cache correctement authentifiée a renvoyé `400` avec « Invalid Presigned Token », alors qu'une résolution fraîche du même torrent/fichier renvoyait un autre hôte et un autre chemin et servait `206`. Sa query string n'avait pas changé. Ne transplanter que l'ancien chemin/les paramètres de requête sur le nouvel hôte renvoyait toujours `400`.

  Le cache de 24 h reste un choix budgétaire : un scan résout à 20/min et peut prendre des heures. Un refus explicite de jeton invalide annule maintenant cette URL et tente une résolution fraîche. Les lecteurs concurrents partagent le travail de résolution, et un refus tardif ne peut pas évincer une URL en cache plus récente. Si l'URL fraîchement résolue est elle aussi refusée, la lecture se met en pause localement pendant une minute sans condamner le fichier. Les 400 génériques ne prouvent pas qu'une URL est périmée et déclenchent seulement un court délai de pause. Les 429 du CDN conservent `Retry-After` et mettent en attente les lectures vers cet hôte, tous fichiers et appels de vérification confondus ; le budget de l'API reste séparé.
- **`bypass_cache=true` sur chaque appel de liste.** Le cache propre de `mylist` chez TorBox a un TTL d'environ 5 minutes ; c'est lui qui fait que les montages WebDAV accusent 5 à 15 minutes de retard sur la réalité. Ce paramètre ne coûte rien côté limite de débit et ramène la propagation à moins d'une seconde.
- **Un poll ne coûte qu'un listing.** Le poll de détection de changements de la bibliothèque est le seul appelant qui force une récupération, puisque repérer un changement est tout son rôle. Le décompte des actifs pris au même tick, et le rafraîchissement complet qui suit un changement, lisent tous deux l'instantané qu'il vient de remplir. Forcer aussi là-bas voulait dire recharger toute la bibliothèque deux ou trois fois par poll — avec l'intervalle par défaut de dix secondes, des milliers de lectures complètes de la bibliothèque en double par jour, sur un service dont zurg contourne déjà le cache de liste.
- **La liste est parcourue par pages de 1000.** `mylist` limite une réponse à 1000 torrents — c'est la valeur par défaut documentée de `limit`, et en demander davantage ne l'augmente pas — sans indiquer de total ni de « il y en a encore ». Une seule requête répond donc à un compte plus gros avec ses 1000 plus récents et ressemble exactement à une bibliothèque complète. zurg pagine avec `offset` jusqu'à recevoir une page incomplète, en dédoublonnant les ids au fil de l'eau : la liste est triée par id décroissant, donc un torrent ajouté pendant le parcours décale la fenêtre d'une place et répète une entrée à la jonction.

## Limites du compte {#account-limits}

| Forfait | Emplacements actifs | Partage | Taille max. de torrent | Remarques |
|---|---|---|---|---|
| Free | 1 | aucun | 10 GB | 1 ajout/24 h, 10 ajouts/mois, pas de torrents privés |
| Essential | 3 | — | 200 GB | pas de délai d'attente, ajouts en cache illimités |
| Standard | 5 | 2 semaines | — | |
| Pro | 10 | 30 jours | — | expiration après 30 jours |

Source : [Restrictions de compte](https://support.torbox.app/en/articles/9836418-account-restrictions).

`/user/me` indique le forfait sous forme de numéro, et ces numéros ne suivent pas l'ordre des prix : **0 Free, 1 Essential, 2 Pro, 3 Standard**. Standard a été ajouté après Pro. Jusqu'au 2026-10-03, zurg lisait le forfait 2 comme Standard, ce qui donnait aux comptes Pro cinq emplacements et le plancher d'utilisation de Standard.

**Les emplacements actifs sont la limite caractéristique de TorBox**, alors que celle de Real-Debrid concerne la bande passante. Un torrent occupe un emplacement pendant son téléchargement *ou son partage*, donc avec un forfait payant, un torrent terminé peut en occuper un pendant jusqu'à 30 jours.

### Ce que fait zurg {#what-zurg-does-1}

- **`GetActiveTorrentCount` renvoie le vrai plafond du forfait**, lu dans `plan` sur le compte utilisateur. Ainsi, la réparation se bloque et attend au lieu de mettre en file des ajouts que le compte va refuser. Si un fournisseur ne renvoie pas de plafond, il est considéré comme illimité au lieu de bloquer indéfiniment.
- **Les torrents ajoutés sont marqués never-seed par défaut.** Le seeding occupe un slot pendant des semaines et facture le trafic sortant, or aucun des deux n'aide un montage en streaming. `tb_seed_torrents` permet de changer ce comportement pour un opérateur dont le tracker privé compte le ratio : `never` envoie `seed=3` (la valeur par défaut), `always` envoie `seed=2`, et `auto` omet le champ. La description que TorBox donne du champ est « "1 is auto. 2 is seed. 3 is don't seed. Optional. Default is 1, or whatever the user has in their settings. Overwrites option in settings" », donc toute valeur envoyée, y compris `1`, remplace le réglage Seeding du compte, et seule l'absence du champ laisse ce réglage s'appliquer. Le même mode s'applique aux trois chemins d'ajout : l'ajout par magnet, l'ajout en cached-only et l'envoi d'un fichier `.torrent`. Avec le seeding activé, les torrents terminés gardent leurs slots, donc la réparation et les endpoints du client de téléchargement se bloquent contre le plafond dès que les torrents en seeding les occupent tous.
- **Le cache n'est jamais vérifié avant l'ajout.** `checkcached` n'a aucun appel nulle part. Le mode cached-only (`qbittorrent.download_timeout_mins: 0`) était la seule exception, jusqu'à ce qu'il soit modifié pour ajouter le torrent et surveiller l'instance comme pour tous les autres backends. En effet, l'endpoint indique si le contenu est dans le cache de TorBox, et non si ce compte finit par le posséder. Un cache miss a un coût réel : un ajout non mis en cache consomme le quota de 60 par heure, alors qu'une vérification ne consommait rien. Les ajouts en cache restent soumis au budget de 300 par minute.

## Expiration du contenu {#content-expiry}

Le contenu Pro expire après 30 jours. Les torrents expirés renvoient depuis l'API `expired` ou `reported missing`, tout en indiquant `download_finished: true` avec `download_present: false`.

Se fier à `download_finished` seul monterait un torrent entier dont chaque lien renvoie un 404. zurg associe les deux formulations au statut `error`, et `Capabilities.ContentExpires` indique que c'est un comportement normal pour le backend, et non une panne.

**Les deux booléens ne suffisent pas, à eux seuls, à dire que les données ont disparu.** Un téléchargement non mis en cache en bonne santé affiche `download_finished: true` avec `download_present: false` pendant les 9.6 dernières secondes de sa vie, le temps de passer par `processing`, `downloading` et `uploading`. Mesuré le 2026-08-30 avec une interrogation toutes les 0.5 seconde, et documenté dans `docs/torrent-lifecycle.md`. Avant, zurg lisait cette paire comme une mort, quel que soit le texte du statut, et toute instance avec `delete_error_torrents: true` supprimait un tel torrent en plein téléchargement. Cinq torrents de test ont été supprimés ainsi ce jour-là. La règle structurelle ne tranche désormais que pour une réponse qui ne contient aucun `download_state`. Une formulation que ce code ne connaît pas est traitée comme un travail en cours, car `processing` faisait partie de ces formulations jusqu'à ce qu'on la mesure.

Une lecture qui tombe quand même sur un tel fichier coûte désormais plus d'un appel. Comme la couche de diffusion traite un 404 sur une URL de livraison générée comme un lien révoqué plutôt que comme un fichier manquant (c'est ce qui se passe sur Real-Debrid, dont les codes meurent lorsque la ligne downloads correspondante est supprimée), elle résout à nouveau le lien avant d'abandonner. Un fichier TorBox expiré consomme donc jusqu'à quatre appels `requestdl` par lecture au lieu d'un seul. Le nombre est borné par lecture, et la liste des fichiers a déjà marqué le torrent `error`, donc rien ne parcourt une bibliothèque expirée à ce rythme. Mais un client qui martèle un même chemin expiré paie quatre fois ce qu'il payait auparavant.

### Ce que fait zurg {#what-zurg-does-2}

**Rien ne réajoute automatiquement les torrents d'un backend à expiration.** La réparation corrige un torrent cassé en réajoutant son magnet. Sur un backend qui conserve le contenu, c'est une réparation. Sur un backend qui le fait expirer, c'est un nouveau téléchargement. Lancer cela sur un minuteur, pour toute une bibliothèque, est le comportement que TorBox cite en premier parmi les raisons de signaler un compte : « excessive transfer retention (using tools to artificially keep transfers active) » (rétention excessive de transferts, avec des outils qui maintiennent artificiellement les transferts actifs). Et chaque ajout de torrent non présent en cache est aussi un transfert entrant, décompté du quota du forfait.

C'est pourquoi le balayage périodique ignore les torrents dont la copie réparable se trouve chez un fournisseur déclarant `ContentExpires`. Ils restent cassés et visibles. Le bouton de réparation du tableau de bord fonctionne toujours, et une release également présente sur Real-Debrid se répare toujours depuis cette copie, comme d'habitude. La distinction porte sur qui a demandé la réparation, et non sur ce qui s'est cassé.

## Utilisation et le système anti-abus {#usage-and-the-abuse-system}

TorBox ne surveille pas les requêtes. Il mesure les octets transférés sur une fenêtre glissante de 15 jours, par rapport à un seuil calculé à partir du 99e percentile de chaque niveau de forfait. Il envoie trois avertissements, **et chaque avertissement fait tourner la clé API**, puis bannit au quatrième. Voici les planchers publiés, c'est-à-dire la valeur la plus basse à laquelle ces seuils dynamiques peuvent descendre :

| Forfait | Plancher |
|---|---|
| Free | 5 TB/mois |
| Essential | 10 TB/mois |
| Standard | 20 TB/mois |
| Pro | 30 TB/mois |

Les deux sens sont comptés : les ajouts non cachés qui arrivent, et tout ce que TorBox envoie, que ce soit vers ton appareil ou vers le swarm. Les ajouts cachés, eux, ne comptent pas. Le comptage est exact au octet près, donc un fichier lu en partie ne coûte que ce qui a été lu.

**`cooldown_until` sur `/user/me` n'est pas un de ces avertissements, et le lire comme tel te fera perdre une journée.** Vérifié le 2026-08-12 sur un compte forfait 2 avec un cooldown actif et fraîchement défini (24h devant, `updated_at` datant d'une minute) : `/user/me`, `checkcached` et `mylist` ont tous répondu `200 success:true`, le `PROPFIND` WebDAV a renvoyé `207`, et une lecture par plage `bytes=0-0` a renvoyé **`206` avec un `Content-Range` correct en 2,8 s**. Aucune couche n'a refusé le service. Le transfert cumulé de ce compte était de 14,1 Go pour un plancher de 30 TB/mois, donc il s'agissait d'un cooldown lié au taux d'appels API, pas d'une sanction pour la bande passante. Ce qui permet de distinguer les deux, c'est la **clé** : un vrai avertissement fait tourner la clé, et tous les endpoints renvoient alors `AUTH_ERROR`, alors qu'un cooldown avec une clé intacte n'a aucun effet observable. Et comme `checkcached` peut indiquer qu'une release est cachée alors que TorBox ne la servira pas réellement, **la lecture par plage est le seul test qui prouve que le service fonctionne**. Vérifie donc le chemin des octets avant de conclure que TorBox est inutilisable.

Source : [The TorBox Abuse System](https://support.torbox.app/en/articles/10336778-the-torbox-abuse-system).

### Ce que fait zurg {#what-zurg-does-3}

- **Les torrents ajoutés ne sont jamais partagés par défaut**, donc rien n'est facturé à la sortie
  pour le contenu que zurg ne fait que lire. `tb_seed_torrents: always` (ou `auto` sur un
  compte configuré pour partager) est le seul réglage qui change ça, et son envoi est facturé
  comme n'importe quel autre.
- **L'usage est échantillonné puis différencié.** L'API ne publie aucun chiffre glissant,
  seulement un compteur à vie sur `/user/me`. Le rafraîchisseur de compte enregistre donc ce
  compteur toutes les 30 minutes dans `data/torbox_usage.json` et calcule les écarts entre les
  échantillons. Quand un chiffre sur 30 jours glissants dépasse 80 % du plancher du forfait, un
  avertissement est écrit dans les logs. Cet avertissement est tout l'intérêt de
  l'échantillonnage : le tableau de bord n'affiche que ce que zurg a lui-même relayé, jamais ces
  écarts. Une installation fraîche n'a pas d'historique et le dit, au lieu d'afficher un zéro
  rassurant.
- **Une clé refusée est signalée comme un avertissement d'abus possible**, et non comme une
  faute de frappe dans la config ni comme un contenu cassé. La rotation de clé est justement
  la façon dont TorBox envoie ces avertissements, et la traiter comme une casse enverrait toute
  la bibliothèque en réparation.

## Volontairement non mappé {#deliberately-unmapped}

Un `download_state` non reconnu est signalé comme `downloading`, jamais comme `error`.
Avec `delete_error_torrents` activé, un statut d'erreur fait supprimer le torrent du compte par zurg : un état que TorBox introduirait après l'écriture de ce code ne doit donc pas pouvoir provoquer de suppressions.
