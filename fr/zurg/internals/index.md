# Fonctionnement interne {#internals}

Comment zurg est construit. Ce qu'il a été mesuré à. Les notes de conception derrière les parties délicates. Écrit pour quelqu'un qui s'apprête à modifier le code. Rien de tout ça n'est nécessaire pour faire tourner zurg.

## La forme générale {#the-shape-of-it}

| Page | Ce qu'il contient |
|---|---|
| [Architecture](architecture.md) | La forme de l'ensemble et les invariants faciles à casser. Commencez ici. |
| [Nommage](naming.md) | Comment une release et ses fichiers finissent avec les noms qu'affiche le montage. |
| [Caches persistants](persistent-caches.md) | Ce qui est conservé sur le disque entre les redémarrages, et ce que ça coûte. |
| [Configuration des répertoires UI/UX](uiux.md) | L'évaluation de conception derrière l'éditeur de répertoires. |

## Ce qui a été mesuré {#what-was-measured}

| Page | Ce qu'elle contient |
|---|---|
| [Debrid baseline](debrid-baseline.md) | Ce que coûte zurg et sa rapidité sur Real-Debrid, AllDebrid et TorBox. |
| [Torrent lifecycle](torrent-lifecycle.md) | Ce que chaque compte affiche réellement pendant qu'un téléchargement tourne, capturé en direct. |
| [Real-Debrid API notes](realdebrid-behavior.md) | Le fonctionnement des liens, la sélection des fichiers et ce que cached veut vraiment dire. |

## Contrats que zurg doit respecter {#contracts-zurg-has-to-satisfy}

| Page | Ce qu'elle contient |
|---|---|
| [SABnzbd client contract](sabnzbd-client-contract.md) | Les formats exacts qu'attendent Sonarr et Radarr d'un SABnzbd. |
| [qBittorrent client contract](qbittorrent-client-contract.md) | La même chose pour un qBittorrent. |
| [plex_api.json](../../internals/plex_api.json) | La surface brute de l'API Plex sur laquelle zurg s'appuie. 1.2 MB. |

## Ce qui a mal tourné {#things-that-went-wrong}

| Page | Ce qu'il contient |
|---|---|
| [Plex trash sweep](plex-trash-sweep.md) | Aligner le nettoyage de la corbeille Plex sur la vision qu'a zurg des fichiers cassés. |
| [Stream timeout regression](stream-timeout-regression.md) | Un flux proxifié qui ne tenait plus les longues lectures. |
| [rclone move refusal](rclone-move-refusal.md) | Imports vides après qu'un backend a refusé un MOVE, et le correctif. |

## Tests {#testing}

- [Tests E2E](e2e-test.md) décrit ce que la suite de tests end to end couvre et ce que coûte son exécution.

Le fonctionnement d'un service particulier et ses limites se trouvent dans [Providers](../providers/index.md) plutôt qu'ici.
