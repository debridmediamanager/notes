---
label: Home
icon: home
order: 100
---

# zurg

zurg is a Go daemon that presents a debrid account — Real-Debrid, AllDebrid, TorBox — or a
directory of NZBs as a read-only virtual filesystem. It stores no media. Every read becomes a
ranged HTTP GET against the provider's CDN at the moment a player asks for those bytes, so a
60 GB remux costs 60 GB of disk nowhere.

Four views onto the same library:

| Endpoint | For |
|---|---|
| `/dav/` | WebDAV, what rclone mounts |
| `/http/` | HTML directory browser |
| `/infuse/` | WebDAV variant with Infuse's quirks accommodated |
| `/strm/` | Signed URLs inside `.strm` files, for players that want a URL not a mount |

## Setup

Getting zurg running on your machine.

- [Docker](setup/docker.md) — containers, FUSE propagation, and what breaks a host-visible mount
- [macOS](setup/macos.md) — macFUSE, rclone, and a mount that survives a reboot
- [Windows](setup/windows.md) — WinFsp and a drive letter

## Guides

Working with the library.

- [Usenet](guides/usenet.md) — the `nzb` backend end to end: news accounts, NZBs, the mount, Plex
- [Sonarr & Radarr](guides/sonarr-radarr.md) — zurg answering as a SABnzbd, so imports are a rename not a download
- [`__magic__`](guides/magic.md) — the one directory whose layout is stored, and therefore yours to arrange
- [Plex](guides/plex.md) — what zurg does with a Plex token, and what it deliberately does not
- [Jellyfin](guides/jellyfin.md) — the same, for Jellyfin

## Migrating

Moving an existing library onto zurg without a re-download or a re-scan.

- [From AltMount](migrate/altmount.md)
- [From decypharr](migrate/decypharr.md)
- [From InfiniDysk](migrate/infinidysk.md)
- [From nzbdav](migrate/nzbdav.md)
- [From streamnzb](migrate/streamnzb.md)

## Reference

- [Configuration](reference/config.md) — every option in `config.yml`
- [Tags](reference/tags.md) — what gets applied to a torrent, and why
- [TorBox limits](reference/torbox-limits.md) — where TorBox differs from Real-Debrid, and how zurg adapts
- [Changelog](reference/changelog.md) — what changed when

## Internals

How zurg is built, what it was measured at, and the design notes behind the awkward parts.

- [Architecture](internals/architecture.md) — the shape of the whole, and the invariants that are easy to break
- [Debrid baseline](internals/debrid-baseline.md) — what zurg costs and how fast it feels across RD, AD and TorBox
- [SABnzbd client contract](internals/sabnzbd-client-contract.md) — the exact shapes Sonarr and Radarr expect
- [Plex trash sweep](internals/plex-trash-sweep.md) · [Stream timeout regression](internals/stream-timeout-regression.md) · [Directory config UI/UX](internals/uiux.md)
- [E2E testing](internals/e2e-test.md) · [Real-Debrid API notes](internals/realdebrid-behavior.md)

---

zurg is distributed to sponsors: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Patreon](https://www.patreon.com/debridmediamanager) · [Discord](https://discord.com/invite/7u4YjMThXP)
