# Alignement du nettoyage de la corbeille Plex avec le statut des fichiers de zurg {#aligning-the-plex-trash-sweep-with-zurgs-own-file-status}

## Objet de ce document {#purpose-of-this-document}

Le balayage de corbeille Plex décide actuellement quoi supprimer d'une bibliothèque Plex à partir de **l'absence du fichier plus une minuterie basée sur l'âge**. zurg sait déjà bien mieux si le contenu derrière ce fichier est réparable ou définitivement mort, mais il ne consulte pas cette information.

Ce document est le plan pour remplacer la minuterie par cette information. Il doit être relu **avant** l'écriture de tout code, car ce changement décide de ce qui est supprimé d'une bibliothèque média, et le comportement actuel est faux dans les deux sens : il attend deux semaines pour supprimer un contenu déjà mort le premier jour, et il supprime un contenu que zurg est toujours en train de réparer.

Il consigne ce qui a été vérifié dans le code et sur une bibliothèque en service, ce qui est proposé, et ce qui est volontairement laissé de côté. Tout ce qui est présenté ci-dessous comme un fait a été vérifié sur le système en fonctionnement le 2026-08-16, et non déduit à partir des noms.

Périmètre : `internal/plexsweep`, `internal/plexdb`, et une nouvelle requête en lecture seule dans `internal/torrent`. Aucun changement au comportement de réparation lui-même.

---

## 1. Contexte — ce qui a été livré et pourquoi il faut le revoir {#1-background--what-shipped-and-why-it-needs-revisiting}

| Commit | Quoi |
|---|---|
| `4737b677` | Avertir quand `autoEmptyTrash` de Plex est activé |
| `020042a3` | Le balayage : détection, garde-fous, réparation, suppression élément par élément |
| `51cc9f69` | Interface de configuration du tableau de bord et documentation |
| `1a481a8f` | Compter les réparations dans le plafond, pas seulement les suppressions |
| `c6f41621` | `plex_trash_sweep_min_age_days`, 14 par défaut |

L'invariant principal du balayage ne change pas et reste en place : **rien qui a encore un
fichier n'est jamais supprimé.** Les éléments avec un fichier disponible sont réparés, ou laissés tels quels
avec leur icône de corbeille. Les séries et saisons qui ont encore des épisodes disponibles ne sont jamais touchées. La suppression se fait
élément par élément, jamais avec `emptyTrash` de Plex à l'échelle de la section.

Ce qu'on revoit, c'est seulement la règle qui définit *quand une entrée réellement absente peut être supprimée*.

### La minuterie est un substitut à une question que zurg peut répondre directement {#the-timer-is-a-proxy-for-a-question-zurg-can-answer-directly}

`plex_trash_sweep_min_age_days` attend 14 jours avant de supprimer une entrée, en partant du principe que l'icône de corbeille rouge est le seul avertissement qu'un opérateur reçoit lorsqu'un contenu a disparu, et que purger l'entrée supprime cet avertissement.

L'intention est bonne, mais le mécanisme repose sur une supposition. Il est faux dans les deux sens :

- Un torrent marqué `infringing torrent` est **considéré comme mort immédiatement**. Laisser son entrée Plex traîner pendant deux semaines n'aide personne : attendre ne le fera pas revenir.
- Un torrent encore en cours de nouvelle tentative peut mettre **plus de 14 jours** à revenir. La minuterie supprime son entrée alors que zurg travaille encore dessus. C'est l'erreur la plus grave, car elle détruit une entrée de la bibliothèque pour un contenu qui revient ensuite.

## 2. Faits vérifiés {#2-verified-facts}

### 2.1 Modèle d'état de zurg {#21-zurgs-state-model}

Il existe trois états de fichier et deux états de torrent (comptés dans `internal/torrent`, hors tests) :

| Niveau | États |
|---|---|
| `File.State` | `ok_file`, `broken_file`, `deleted_file` |
| `Torrent.State` | `ok_torrent`, `broken_torrent` |

Les deux sont des machines `pkg/fsm`. `FSMWithTime` enregistre le timestamp unix de chaque transition et gère `SinceWhen`, donc savoir depuis combien de temps c'est cassé est déjà possible, sans rien ajouter.

**Un seul fichier cassé condamne tout le torrent.**
`MarkFileBrokenAndEnqueueRepair` (`internal/torrent/hooks.go:215-234`) :

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

Le log dit *"has broken file"*, au singulier. Un fichier cassé sur dix et dix sur dix donnent exactement le même état de torrent. Rien ne regroupe les états des fichiers.

**`Unfixable` agrège par compte, pas par fichier.**
`markAsUnrepairable` (`internal/torrent/unplayable_unrepairable.go:44-71`) :

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

L'entrée est condamnée quand **il ne reste aucune copie capable d'être réparée**. Volontairement, on ne teste pas « chaque copie porte une raison ». Une copie qui n'aurait de toute façon jamais pu être réparée (le backend Usenet n'a pas de magnet adder) garderait sinon une release morte éligible à la réparation indéfiniment. `File` n'a aucun champ unrepairable du tout (`internal/torrent/file_types.go`).

Donc les trois niveaux répondent à trois questions différentes, et **aucun ne répond à la portée** :

| Niveau | Indique | Ne peut pas indiquer |
|---|---|---|
| `File.State` | ce fichier est ok / cassé / supprimé | s'il est définitivement mort |
| `TorrentCopy.UnrepairableReason` | la copie de ce compte est morte | quoi que ce soit sur les autres comptes |
| `Torrent.UnrepairableReason` | aucun compte ne peut le réparer | quelle part de la release est touchée |

### 2.2 Mesures en direct (une bibliothèque en production, 2026-08-16) {#22-live-measurements-a-production-library-2026-08-16}

Les pourcentages ci-dessous concernent les torrents cassés, qui représentaient environ **3 % de la bibliothèque**.

**Presque tous les torrents cassés (98 %) ont une raison `Unfixable`** :

| Raison | Part des cassés |
|---|---|
| stalled download | 38 % |
| infringing torrent | 37 % |
| repair failed | 15 % |
| duplicate file IDs (pack torrent) | 4 % |
| rar'ed by RD | 1 % |
| repair failed, no seeders | 1 % |
| the lone cached file is broken | moins de 1 % |
| invalid file ids | moins de 1 % |
| repair failed, download status: error | moins de 1 % |
| provider cannot re-add torrents | moins de 1 % |

**Les 2 % restants sont cassés sans raison**, mais ils sont réparables.

**Mais `Unfixable` ne veut pas dire mort.** zurg classe déjà ces raisons en
permanentes et récupérables (`internal/torrent/unrepairable_reasons.go:44-70`).
`permanentReasons` regroupe huit verdicts qu'aucune nouvelle tentative ne peut changer : infringing,
unsupported, unavailable, invalid, too big, not allowed, no repairable files,
invalid file ids, plus toute raison préfixée par `repair failed, download status:`.
Tout le reste, y compris les deux plus gros groupes ci-dessus, est explicitement
temporaire : `stalled download`, `repair failed`, `duplicate file IDs`,
`rar'ed by RD`, `not cached`, `the lone cached file is broken`,
`full torrent repair failed`.

`repair failed, no seeders` faisait partie de la liste à neuf raisons au moment où les pourcentages ci-dessus ont été relevés. Les entrées qui la portent ici sont la raison pour laquelle elle ne l'est plus : aucun backend auquel zurg parle ne fournit le nombre de seeders, donc ce verdict n'a jamais été mesuré. Il a été déduit du fait qu'une réparation a manqué de temps. Il est maintenant temporaire, et de plus impossible à enregistrer (`verdictClaims`). Ces entrées sont donc retirées et réessayées comme les autres.

En appliquant cette répartition aux pourcentages ci-dessus :

| | Part des cassés |
|---|---|
| Irréparables de façon permanente | **39 %** |
| Irréparables mais récupérables | **59 %** |
| Cassés, sans raison pour l'instant | 2 % |

Une raison non reconnue (`provider cannot re-add torrents`, une entrée ici) ne figure dans aucune
des deux listes, et `IsPermanentlyUnrepairable` renvoie false pour elle. C'est la réponse prudente, et c'est celle qu'on veut.

C'est la conclusion la plus importante pour la conception : **une règle basée sur « `Unfixable` est défini » supprimerait les entrées Plex de deux fois et demie plus de releases qu'il n'y en a vraiment de mortes.**

Surtout, voici où se trouvent ces torrents cassés par rapport au montage :

| | Part des cassés | Ce que voit Plex |
|---|---|---|
| Cassés, **encore présents sur le montage** | environ trois sur quatre | Le fichier semble exister → jamais marqué comme supprimé. Pas d'icône de corbeille ; ça ne plante qu'à la lecture |
| Cassés, **absents du montage** | environ un sur quatre | Fichier manquant → marqué comme supprimé → **ce sont les candidats du balayage** |

C'est la mesure clé. Elle signifie que le balayage ne rencontre que le second groupe, et que pour ce groupe zurg a généralement déjà un verdict.

Côté Plex, sur le même hôte : un arriéré de sous-éléments placés à la corbeille, **aucun** au-delà de la fenêtre de 14 jours (tombstone le plus ancien : 2026-08-11). Il y a aussi quelques coquilles de séries vides et quelques dizaines de coquilles de saisons vides.

---

## 3. L'écart {#3-the-gap}

`broken_torrent` signifie « au moins un élément est cassé ». C'est le mauvais niveau de détail pour le balayage.

Concrètement : un pack de dix épisodes dont le fichier d'un épisode a disparu pour de bon, alors que le torrent reste réparable dans l'ensemble. Si on interroge le torrent, il répond « still repairable », donc le balayage garderait l'entrée Plex de cet épisode mort **pour toujours**.

Il n'existe aucun état qui signifie *« toute cette release est morte »*, distinct de *« quelque chose dans cette release est cassé »*.

---

## 4. Conception {#4-design}

### 4.1 Ne pas ajouter un quatrième état persistant {#41-do-not-add-a-fourth-persisted-state}

Le plus évident serait un nouvel état de torrent, `dead_torrent` ou similaire. **Rejeté.**

Chaque site qui fait passer un torrent d'un état à un autre devrait le maintenir à jour, et un indicateur « tous les fichiers sont cassés » obsolète est pire que pas d'indicateur du tout, parce qu'il *autorise les suppressions*. L'information existe déjà dans les états des fichiers ; elle n'est simplement pas agrégée.

Il faut donc la calculer à la volée :

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

Peu coûteux, toujours cohérent, et affichable dans le tableau de bord sans persistance.

Définition à fixer pendant l'implémentation : `deleted_file` doit compter comme non lisible, au même titre que `broken_file`, et un torrent avec **zéro** fichier doit renvoyer false et non vrai par défaut. Une release vide n'est pas une preuve de mort.

### 4.2 Interroger le fichier, puis revenir au torrent {#42-ask-the-file-fall-back-to-the-torrent}

Le sweep résout un chemin Plex vers un fichier zurg, puis applique :

| Verdict de zurg | Sweep |
|---|---|
| le fichier est `ok_file` | **garder** : il n'est pas vraiment perdu |
| `broken_file`, le torrent n'a aucune raison irréparable | **garder** : la réparation peut le restaurer, quelle que soit la durée |
| `broken_file`, une raison est définie mais **pas** permanente | **garder** : zurg considère encore qu'il est récupérable |
| `broken_file`, la raison est **définitivement** irréparable | **supprimer** : aucune nouvelle tentative ne peut changer ce verdict |
| zurg n'a aucun torrent pour ce chemin | **revenir à la fenêtre d'ancienneté** |

Le test de permanence est `IsPermanentlyUnrepairable(reason)` (`internal/torrent/unrepairable_reasons.go:59`), utilisé exactement comme `ForceRepairTorrent` l'utilise. Le réutiliser plutôt que de recalculer une liste compte : une raison ajoutée plus tard à `permanentReasons` doit modifier automatiquement le comportement du sweep, et une raison non reconnue doit rester non permanente.

`AllFilesBroken()` n'autorise **pas** la suppression à lui seul : une release entièrement cassée avec une raison récupérable est toujours en cours de traitement. Cette fonction sert à affiner les rapports et le tableau de bord, et à distinguer « un épisode sur dix est perdu » de « le pack entier est perdu » pour la personne qui lit le journal.

La dernière ligne explique pourquoi `plex_trash_sweep_min_age_days` reste. Une fois qu'un torrent a totalement disparu du compte, son `.zurgtorrent` disparaît avec lui, et zurg n'a plus rien à dire. La minuterie cesse donc d'être la règle principale et devient la solution de repli pour le seul cas où rien de mieux n'existe.

Cela rétrograde aussi ce réglage dans l'interface, ce qui règle une autre plainte : son libellé (« Keep Broken Entries Visible ») décrit un effet secondaire plutôt que l'action.

### 4.3 Recherche chemin → torrent → fichier {#43-path--torrent--file-lookup}

Le matcher Plex existant fait le chemin *inverse* : `buildPlexDirIndex`
(`internal/plex/matcher.go:539`) indexe les composants de chemin Plex et les recherche par
clé de torrent. Le sweep a besoin de l'inverse, construit sur la même idée :

1. Construire `map[strings.ToLower(GetKey(torrent))] *Torrent` à partir de
   `DirectoryMap.Get(INT_ALL)`.
2. Pour un chemin Plex, le découper en composants avec la même normalisation que
   `splitPathComponents` (`matcher.go:525`) et chercher chacun d'eux. Le dossier de release
   est le composant qui trouve une correspondance.
3. Dans ce torrent, faire correspondre la fin du chemin restant avec `File.Path`
   (`internal/debrid/types.go:133`) pour trouver le fichier précis.

Il faut passer par `TorrentManager` et non par une comparaison de chaînes sur
`data/*.zurgtorrent`, car les noms désambiguïsés (`Some.Release {a1b2c3}`), les copies multi-comptes
et les renommages ne se résolvent correctement que via `GetKey`.

**Un échec de recherche n'est pas une autorisation de supprimer.** Si la résolution est impossible, on considère que « zurg n'a pas d'avis » et on repasse sur le repli par fenêtre d'âge.

### 4.4 Ce qui ne change pas {#44-what-does-not-change}

- L'invariant : rien qui contient un fichier actif n'est supprimé.
- Les séries et saisons qui ont des descendants actifs ne sont jamais touchées.
- Suppression par élément avec `DELETE`, jamais `emptyTrash`.
- Garde-fous : rclone géré et en cours d'exécution, lecture du montage, Plex qui ne scanne pas.
- Instantané avant toute modification ; les plafonds s'appliquent aux réparations *et* aux suppressions.

Les nouvelles règles ne font jamais que rendre le balayage **plus** prudent ou **plus** précis —
elles n'autorisent jamais une suppression que le code actuel refuserait.

## 5. Plan d'implémentation {#5-implementation-plan}

| # | Étape | Fichiers |
|---|---|---|
| 0 | Confirmer que la séparation permanent/récupérable est le bon garde-fou, avec un comptage à blanc sur une bibliothèque réelle avant que quoi que ce soit ne supprime | — |
| 1 | `AllFilesBroken()` + tests unitaires (release vide, mixte, tout cassé, tout supprimé) | `internal/torrent/` |
| 2 | Recherche de statut en lecture seule : chemin → torrent → fichier, qui renvoie une petite valeur de verdict | nouveau fichier dans `internal/torrent/` ou `internal/plexsweep/` |
| 3 | Définir le type de verdict (`StatusOK`, `StatusRecoverable`, `StatusPermanentlyDead`, `StatusUnknown`) pour que le balayage ne gère jamais directement les internes de zurg | `internal/plexsweep` |
| 4 | Brancher la recherche dans `Sweeper` derrière une interface, comme c'est déjà le cas pour `Mount`/`Library`/`Trash` | `internal/plexsweep/sweep.go` |
| 5 | Appliquer la table de décision ; garder la fenêtre d'âge comme solution de repli `StatusUnknown` | `internal/plexsweep/sweep.go` |
| 6 | Injecter le `TorrentManager` au point d'appel | `internal/app.go` |
| 7 | Tests : un par ligne de la table de décision, plus un test d'échec de recherche qui prouve qu'un cas non résolu ne supprime jamais rien | `internal/plexsweep/sweep_test.go` |
| 8 | Docs : `docs/config.md`, `config.example.yml`, `docs/CHANGELOG.md`, et reformuler le libellé du tableau de bord | docs + modèles |

Note sur l'ordre : les étapes 1 à 3 sont de pures additions sans changement de comportement et peuvent être regroupées dans un seul commit ; l'étape 5 est la seule qui modifie ce qui est supprimé.

## 6. Risques et questions ouvertes {#6-risks-and-open-questions}

1. **Ordre de câblage.** Confirmé : `startPlexTrashSweep` est appelé à `internal/app.go:268`, et `TorrentManager` est construit à `internal/app.go:285`, donc après. L'appel doit être déplacé après, ou passer par un setter. Il faut vérifier que rien d'autre ne dépend de la position actuelle.
2. **Ambiguïté de recherche.** Deux torrents dont les clés entrent en collision avec le même composant de chemin. Résolution : si plus d'un candidat correspond, on le traite comme `StatusUnknown` plutôt que d'en choisir un.
3. **`only_show_the_biggest_file`.** Le répertoire films masque des fichiers, donc un chemin Plex peut désigner un fichier qui n'est pas celui que zurg servirait. La recherche ne doit pas supposer que le nom de fichier Plex apparaît tel quel dans `File.Path`.
4. **Coût.** Construire l'index des clés à chaque sweep est en O(bibliothèque). Avec quelques milliers de torrents, c'est négligeable, et le sweep tourne chaque jour. On construit l'index par sweep, pas par élément.
5. ~~**Est-ce que `Unfixable` se réinitialise un jour ?**~~ **Résolu : oui.** `refresh.go:851-857` le réinitialise quand un torrent passe la vérification et revient à `ok_torrent` ("all links intact, no broken files"), et `repair.go:165-181` le réinitialise (entrée et chaque copie) quand une réparation est forcée. Donc une release récupérée ne garde pas une condamnation périmée, et la conception n'a pas besoin de s'en protéger.
6. **Les torrents cassés mais présents.** Hors périmètre ici : Plex ne les marque jamais comme supprimés, donc le sweep ne les voit jamais. Bon à savoir : ils sont invisibles à la fois pour Plex et pour cette fonctionnalité tant que la lecture n'échoue pas.

## 7. Comment cela a été implémenté (2026-08-16) {#7-how-it-was-implemented-2026-08-16}

`feat: decide plex trash sweep removals from zurg's repair verdicts`

Là où l'implémentation a tranché une question que ce document laissait ouverte, ou s'est écartée du §4, voici la décision et sa raison :

- **La recherche compare exactement le répertoire parent du chemin** avec `DirectoryMap[INT_ALL]`, au lieu de parcourir chaque composant du chemin (§4.3). Le montage présente une release à plat, sous la forme `<library dir>/<key>/<visible name>`, et Plex a enregistré le chemin depuis le montage, qui sert la clé telle quelle. Une absence exacte répond unknown, et l'ambiguïté des collisions de clés (risque 2) disparaît : des clés exactes ne peuvent pas entrer en collision.
- **La ligne 1 de la table de décision a changé.** Un `ok_file` qui est pourtant absent du montage est un fichier masqué par les filtres, et non un fichier « vraiment disparu ». le conserver indéfiniment laisserait une icône de corbeille permanente après un changement de filtre. On revient donc à la fenêtre d'âge.
- **`deleted_file` compte avec `broken_file`** dans toutes les règles, et pas seulement dans `AllFilesBroken()` : les lignes de la table disent « pas `ok_file` ».
- **Les items à versions multiples sont jugés comme un tout** (la table raisonnait par fichier, alors que l'unité de balayage est un item Plex avec ses parties) : une partie récupérable suffit à garder tout l'item ; l'item n'est mort que si chaque partie l'est ; tout autre mélange retombe sur la fenêtre d'âge.
- **Un nom de fichier qui correspond à un torrent mais pas à un fichier** (renommage, listage d'archive, `only_show_the_biggest_file`, risque 3) n'est mort que si la raison de l'entrée est permanente **et** `AllFilesBroken()` ; il est récupérable si le torrent est cassé sans verdict permanent ; sinon unknown. Un nom sans correspondance n'est jamais condamné par association tant qu'un fichier reste lisible.
- **Câblage (risque 1) :** `startPlexTrashSweep` a été déplacé sous la construction du manager dans `internal/app.go` ; rien ne dépendait de son ancienne position. Les verdicts arrivent au balayage via `plexsweep.Verdicts`, implémenté par `TorrentManager.FileStatusForMountPath`. Avant que le premier refresh ne remplisse `INT_ALL`, chaque recherche répond unknown, et le balayage se comporte exactement comme la version à fenêtre d'âge.

## 8. Explicitement hors périmètre {#8-explicitly-out-of-scope}

- **Coquilles d'émissions et de saisons vides.** Le balayage ne supprime que les feuilles, donc une émission entièrement morte laisse une coquille (quelques émissions et quelques dizaines de saisons dans la bibliothèque mesurée). C'est un sujet réel et distinct, qui demande de l'ordre : supprimer les feuilles, revérifier le parent, et ne le supprimer qu'à zéro enfant.
- Toute modification du comportement de réparation, de la file de réparation, ou du moment où zurg marque quelque chose comme irréparable.
- L'`autoEmptyTrash` de Plex lui-même, déjà géré par l'avertissement dans `4737b677`.
- L'arriéré existant de la bibliothèque mesurée, laissé volontairement à une décision manuelle.
