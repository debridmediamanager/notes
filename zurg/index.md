---
label: zurg
icon: file-directory
order: 90
---

# zurg

zurg puts your debrid accounts and Usenet library in one virtual folder. It stores no local
video. Nothing is fetched until a player asks for it. A 60 GB remux does not use 60 GB of local
disk.

Four views onto the same library:

| Endpoint | For |
|---|---|
| `/dav/` | WebDAV, what rclone mounts |
| `/http/` | HTML directory browser |
| `/infuse/` | WebDAV variant with Infuse's quirks accommodated |
| `/strm/` | Signed URLs inside `.strm` files, for players that want a URL not a mount |

## Setup

Get zurg running on your machine.

- [Linux](setup/linux.md) — FUSE 3 and systemd auto-start
- [Docker](setup/docker.md) — a Linux host with a host-visible mount
- [macOS](setup/macos.md) — macFUSE and launchd auto-start
- [Windows](setup/windows.md) — WinFsp and a drive-letter task

## Providers

Point zurg at an account. Each page covers the credential and the `config.yml` entry. The
examples use Docker. A binary install uses the same config entry. See [Setup](setup/index.md)
for the commands.

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

Work with the library.

- [Usenet](guides/usenet.md) — the `nzb` backend end to end: news accounts, NZBs, the mount, Plex
- [Sonarr & Radarr for Usenet](guides/sonarr-radarr.md) — the \*arrs search and zurg answers as a SABnzbd, so imports are a rename not a download
- [Sonarr & Radarr for torrents](guides/sonarr-radarr-torrents.md) — the same, with zurg answering as a qBittorrent; Prowlarr too
- [zurg searches for Sonarr & Radarr](guides/sonarr-radarr-fetch.md). Radarr and Sonarr keep the list and zurg finds and places the release. No indexers or download client in either.
- [`__magic__`](guides/magic.md) — the one directory whose layout is stored, and therefore yours to arrange, with your library filed by title for Kodi and Plex
- [Renaming](guides/renaming.md) — rename a release or a file anywhere in the library. A move is refused and the page says why
- [Plex](guides/plex.md) — what zurg does with a Plex token, and what it deliberately does not
- [Jellyfin](guides/jellyfin.md) — the same, for Jellyfin
- [rex with zurg](../rex/with-zurg.md) — a media server for the Plex apps that owns no files, filled by zurg from your debrid account. More in [rex](../rex/index.md)
- [The Stremio addon](guides/stremio.md) — Stremio searching your own indexers, playing straight out of the Usenet backend
- [Watchlist and Seerr](guides/acquisition.md) fetches what you ask for through your own indexers
- [Plex watchlist](guides/plex-watchlist.md) is the Plex side of that
- [DMM wanted list](guides/dmm-wanted.md) fetches what you press Want on at DMM, with nothing else to set up
- [Local libraries](guides/local-libraries.md) plays a shared list of releases through your own account
- [Android and Google TV](guides/android.md) runs the whole library on a phone or a TV box

## Migrating

Move an existing library onto zurg without a re-download or a re-scan.

- [From AltMount](migrate/altmount.md)
- [From decypharr](migrate/decypharr.md)
- [From InfiniDysk](migrate/infinidysk.md)
- [From nzbdav](migrate/nzbdav.md)
- [From streamnzb](migrate/streamnzb.md)

## Reference

- [Configuration](reference/config.md) — every option in `config.yml`
- [Command line](reference/cli.md) lists every command and flag the binary takes
- [Outbound identity](reference/outbound-identity.md) says what zurg tells the services it calls about itself
- [MCP server](reference/mcp.md) lets an AI agent drive zurg over the Model Context Protocol
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
· [Sponsor](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
