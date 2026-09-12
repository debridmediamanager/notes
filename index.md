# zurg

zurg is a Go daemon that presents a debrid account or a directory of NZBs as a virtual
filesystem. Six debrid services are supported and so is Usenet. It stores no media and it
accepts no uploads. Nothing is fetched before a player asks for it. A read on a debrid
account becomes a ranged HTTP GET against that service's CDN. A read on the Usenet backend
becomes the articles that cover those bytes. A 60 GB remux costs 60 GB of disk nowhere.

Four views onto the same library:

| Endpoint | For |
|---|---|
| `/dav/` | WebDAV, what rclone mounts |
| `/http/` | HTML directory browser |
| `/infuse/` | WebDAV variant with Infuse's quirks accommodated |
| `/strm/` | Signed URLs inside `.strm` files, for players that want a URL not a mount |

## Setup

Getting zurg running on your machine.

- [Linux](setup/linux.md) — FUSE 3 and a systemd service created by the binary
- [Docker](setup/docker.md) — containers, FUSE propagation, and what breaks a host-visible mount
- [macOS](setup/macos.md) — macFUSE and launchd auto-start created by the binary
- [Windows](setup/windows.md) — WinFsp and an interactive drive-letter task created by the binary

## Providers

Pointing zurg at an account. Each page covers the credential and the
`config.yml` entry and what that service does differently. All of them assume
the Docker install.

| Page | What is different about it |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | Per-file selection, `__downloads__`, CDN host choice, a separate `.strm` token |
| [TorBox](providers/torbox.md) | One request per library refresh, and an active-slot ceiling rather than a bandwidth one |
| [AllDebrid](providers/alldebrid.md) | File lists arrive from their own endpoint, so a first scan fills in gradually |
| [Premiumize](providers/premiumize.md) | Completed transfers plus the cloud files left behind, with their folders intact |
| [Debrid-Link](providers/debridlink.md) | The seedbox listing carries every file, and there is no cache check |
| [Offcloud](providers/offcloud.md) | Sizes checked against the delivery server, folder paths from cached metadata |
| [Usenet](providers/usenet.md) | The `nzb` type as a provider entry. No token, a watch directory instead |
| [TorBox limits](providers/torbox-limits.md) | The measured figures behind TorBox throttling, and how zurg paces against them |
| [TorBox news server](providers/torbox-news-server.md) · [ElfHosted news server](providers/elfhosted-news-server.md) | What the bundled Usenet accounts are, on the wire |

[The shared page](providers/index.md) has the three ways to add an account in
Docker and the rules the config loader enforces.

## Guides

Working with the library.

- [Usenet](guides/usenet.md) — the `nzb` backend end to end: news accounts, NZBs, the mount, Plex
- [Sonarr & Radarr](guides/sonarr-radarr.md) — zurg answering as a SABnzbd, so imports are a rename not a download
- [Sonarr & Radarr, torrents](guides/sonarr-radarr-torrents.md) — the same, with zurg answering as a qBittorrent; Prowlarr too
- [`__magic__`](guides/magic.md) — the one directory whose layout is stored, and therefore yours to arrange
- [Renaming](guides/renaming.md) — rename a release or a file anywhere in the library. A move is refused and the page says why
- [Plex](guides/plex.md) — what zurg does with a Plex token, and what it deliberately does not
- [Jellyfin](guides/jellyfin.md) — the same, for Jellyfin
- [The Stremio addon](guides/stremio.md) — Stremio searching your own indexers, playing straight out of the Usenet backend
- [Watchlist and Seerr](guides/acquisition.md) fetches what you ask for through your own indexers
- [Plex watchlist](guides/plex-watchlist.md) is the Plex side of that
- [Local libraries](guides/local-libraries.md) plays a shared list of releases through your own account
- [Android and Google TV](guides/android.md) runs the whole library on a phone or a TV box

## Migrating

Moving an existing library onto zurg without a re-download or a re-scan.

- [From AltMount](migrate/altmount.md)
- [From decypharr](migrate/decypharr.md)
- [From InfiniDysk](migrate/infinidysk.md)
- [From nzbdav](migrate/nzbdav.md)
- [From streamnzb](migrate/streamnzb.md)

## Reference

- [Configuration](reference/config.md) — every option in `config.yml`
- [Command line](reference/cli.md) lists every command and flag the binary takes
- [Outbound identity](reference/outbound-identity.md) says what zurg tells the services it calls about itself
- [Tags](reference/tags.md) — what gets applied to a torrent, and why
- [Changelog](reference/changelog.md) — what changed when

## Internals

How zurg is built, what it was measured at, and the design notes behind the awkward parts.

- [Architecture](internals/architecture.md) — the shape of the whole, and the invariants that are easy to break
- [Debrid baseline](internals/debrid-baseline.md) — what zurg costs and how fast it feels across RD, AD and TorBox
- [Torrent lifecycle](internals/torrent-lifecycle.md) — what each account actually reports while a grab runs, measured live
- [SABnzbd client contract](internals/sabnzbd-client-contract.md) — the exact shapes Sonarr and Radarr expect
- [Plex trash sweep](internals/plex-trash-sweep.md) · [Stream timeout regression](internals/stream-timeout-regression.md) · [Directory config UI/UX](internals/uiux.md)
- [E2E testing](internals/e2e-test.md) · [Real-Debrid API notes](internals/realdebrid-behavior.md)
- [qBittorrent client contract](internals/qbittorrent-client-contract.md) · [Persistent caches](internals/persistent-caches.md)
- [Naming](internals/naming.md) · [rclone move refusal](internals/rclone-move-refusal.md)

---

zurg is distributed to sponsors: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Patreon](https://www.patreon.com/debridmediamanager) · [Discord](https://discord.com/invite/7u4YjMThXP)
