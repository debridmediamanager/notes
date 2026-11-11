# zurg

zurg regroupe vos comptes debrid et votre bibliothèque Usenet dans un seul dossier virtuel. Il ne stocke aucune vidéo en local. Rien n'est téléchargé tant qu'un lecteur ne le demande pas. Un remux de 60 Go n'occupe pas 60 Go sur votre disque local.

Quatre vues sur la même bibliothèque :

| Point d'accès | Pour |
|---|---|
| `/dav/` | WebDAV, ce que rclone monte |
| `/http/` | Navigateur de répertoires HTML |
| `/infuse/` | Variante WebDAV adaptée aux particularités d'Infuse |
| `/strm/` | URLs signées dans des fichiers `.strm`, pour les lecteurs qui veulent une URL et non un montage |

## Configuration {#setup}

Faites tourner zurg sur votre machine.

- [Linux](setup/linux.md) — FUSE 3 et démarrage automatique avec systemd
- [Docker](setup/docker.md) — un hôte Linux avec un point de montage visible depuis l'hôte
- [macOS](setup/macos.md) — macFUSE et démarrage automatique avec launchd
- [Windows](setup/windows.md) — WinFsp et une tâche de lettre de lecteur

## Fournisseurs {#providers}

Pointez zurg vers un compte. Chaque page explique l'identifiant et l'entrée `config.yml`. Les exemples utilisent Docker. Une installation binaire utilise la même entrée de configuration. Consultez [Installation](setup/index.md) pour les commandes.

| Page | Ce qui la distingue |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | Sélection par fichier, `__downloads__`, choix de l'hôte CDN, un jeton `.strm` distinct |
| [TorBox](providers/torbox.md) | Une requête par rafraîchissement de la bibliothèque, et un plafond de slots actifs plutôt qu'un plafond de bande passante |
| [AllDebrid](providers/alldebrid.md) | Les listes de fichiers arrivent depuis leur propre endpoint, donc un premier scan se remplit progressivement |
| [Premiumize](providers/premiumize.md) | Les transferts terminés plus les fichiers restés dans le cloud, avec leurs dossiers intacts |
| [Debrid-Link](providers/debridlink.md) | La liste du seedbox contient tous les fichiers, et il n'y a pas de vérification de cache |
| [Offcloud](providers/offcloud.md) | Tailles vérifiées auprès du serveur de livraison, chemins de dossiers issus des métadonnées en cache |
| [Usenet](providers/usenet.md) | Le type `nzb` comme entrée de fournisseur. Pas de jeton, mais un dossier de surveillance à la place |
| [Limites de TorBox](providers/torbox-limits.md) | Les chiffres mesurés derrière le throttling de TorBox, et la façon dont zurg s'y adapte |
| [Serveur de news TorBox](providers/torbox-news-server.md) · [Serveur de news ElfHosted](providers/elfhosted-news-server.md) | Ce que sont les comptes Usenet fournis, côté réseau |

[La page commune](providers/index.md) présente les trois façons d'ajouter un compte dans Docker, ainsi que les règles appliquées par le chargeur de configuration.

## Guides

- [Usenet](guides/usenet.md) — le backend `nzb` de bout en bout : comptes news, NZB, le montage, Plex
- [Sonarr & Radarr pour Usenet](guides/sonarr-radarr.md) — les \*arrs cherchent et zurg répond comme un SABnzbd, donc les imports sont un simple renommage et non un téléchargement
- [Sonarr & Radarr pour les torrents](guides/sonarr-radarr-torrents.md) — pareil, avec zurg qui répond comme un qBittorrent ; Prowlarr aussi
- [zurg cherche pour Sonarr & Radarr](guides/sonarr-radarr-fetch.md). Radarr et Sonarr gardent la liste, et zurg trouve et place la release. Aucun indexeur ni client de téléchargement dans les deux.
- [`__magic__`](guides/magic.md) — le seul dossier dont la structure est enregistrée, et donc à toi d'arranger comme tu veux, avec ta bibliothèque classée par titre pour Kodi et Plex
- [Renommage](guides/renaming.md) — renomme une release ou un fichier n'importe où dans la bibliothèque. Un déplacement est refusé et la page explique pourquoi
- [Plex](guides/plex.md) — ce que zurg fait avec un token Plex, et ce qu'il ne fait volontairement pas
- [Jellyfin](guides/jellyfin.md) — pareil, pour Jellyfin
- [rex avec zurg](../rex/with-zurg.md) — un serveur multimédia pour les apps Plex qui ne possède aucun fichier, alimenté par zurg depuis ton compte debrid. Plus d'infos dans [rex](../rex/index.md)
- [L'addon Stremio](guides/stremio.md) — Stremio cherche dans tes propres indexeurs et lit directement depuis le backend Usenet
- [Watchlist et Seerr](guides/acquisition.md) récupère ce que tu demandes via tes propres indexeurs
- [Watchlist Plex](guides/plex-watchlist.md) est la partie Plex de cela
- [Liste de souhaits DMM](guides/dmm-wanted.md) récupère ce sur quoi tu appuies sur Want dans DMM, sans rien d'autre à configurer
- [Bibliothèques locales](guides/local-libraries.md) lit une liste partagée de releases avec ton propre compte
- [Android et Google TV](guides/android.md) fait tourner toute la bibliothèque sur un téléphone ou un boîtier TV

## Migration {#migrating}

Déplacez une bibliothèque existante vers zurg sans la retélécharger ni relancer un scan.

- [Depuis AltMount](migrate/altmount.md)
- [Depuis decypharr](migrate/decypharr.md)
- [Depuis InfiniDysk](migrate/infinidysk.md)
- [Depuis nzbdav](migrate/nzbdav.md)
- [Depuis streamnzb](migrate/streamnzb.md)

## Référence {#reference}

- [Configuration](reference/config.md) — chaque option de `config.yml`
- [Ligne de commande](reference/cli.md) liste chaque commande et chaque option que le binaire accepte
- [Identité sortante](reference/outbound-identity.md) explique ce que zurg indique aux services qu'il appelle à son sujet
- [Serveur MCP](reference/mcp.md) permet à un agent IA de piloter zurg via le Model Context Protocol
- [Tags](reference/tags.md) — ce qui est appliqué à un torrent, et pourquoi
- [Changelog](reference/changelog.md) — ce qui a changé, et quand

## Fonctionnement interne {#internals}

Comment zurg est construit, ce qu'on a mesuré et les notes de conception derrière les parties délicates.

- [Architecture](internals/architecture.md) — la forme générale et les invariants faciles à casser
- [Debrid baseline](internals/debrid-baseline.md) — ce que coûte zurg et sa rapidité sur RD, AD et TorBox
- [Torrent lifecycle](internals/torrent-lifecycle.md) — ce que chaque compte indique réellement pendant un téléchargement, mesuré en direct
- [SABnzbd client contract](internals/sabnzbd-client-contract.md) — les formats exacts attendus par Sonarr et Radarr
- [Plex trash sweep](internals/plex-trash-sweep.md) · [Stream timeout regression](internals/stream-timeout-regression.md) · [Directory config UI/UX](internals/uiux.md)
- [E2E testing](internals/e2e-test.md) · [Real-Debrid API notes](internals/realdebrid-behavior.md)
- [qBittorrent client contract](internals/qbittorrent-client-contract.md) · [Persistent caches](internals/persistent-caches.md)
- [Naming](internals/naming.md) · [rclone move refusal](internals/rclone-move-refusal.md)

---

zurg est distribué aux sponsors : [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Sponsor](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
