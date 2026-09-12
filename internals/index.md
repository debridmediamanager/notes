---
label: Internals
icon: tools
order: 50
---

# Internals

How zurg is built. What it was measured at. The design notes behind the awkward
parts. Written for someone about to change the code. Nothing here is needed to
run zurg.

## The shape of it

| Page | What it holds |
|---|---|
| [Architecture](architecture.md) | The shape of the whole and the invariants that are easy to break. Start here. |
| [Naming](naming.md) | How a release and its files end up with the names the mount shows. |
| [Persistent caches](persistent-caches.md) | What is kept on disk between restarts and what it costs. |
| [Directory config UI/UX](uiux.md) | The design assessment behind the directory editor. |

## What was measured

| Page | What it holds |
|---|---|
| [Debrid baseline](debrid-baseline.md) | What zurg costs and how fast it feels across Real-Debrid and AllDebrid and TorBox. |
| [Torrent lifecycle](torrent-lifecycle.md) | What each account actually reports while a grab runs, captured live. |
| [Real-Debrid API notes](realdebrid-behavior.md) | Link semantics, file selection and what cached really means. |

## Contracts zurg has to satisfy

| Page | What it holds |
|---|---|
| [SABnzbd client contract](sabnzbd-client-contract.md) | The exact shapes Sonarr and Radarr expect from a SABnzbd. |
| [qBittorrent client contract](qbittorrent-client-contract.md) | The same for a qBittorrent. |
| [plex_api.json](plex_api.json) | The raw Plex API surface zurg codes against. 1.2 MB. |

## Things that went wrong

| Page | What it holds |
|---|---|
| [Plex trash sweep](plex-trash-sweep.md) | Aligning the sweep with zurg's own view of what is broken. |
| [Stream timeout regression](stream-timeout-regression.md) | A proxied stream that stopped surviving long reads. |
| [rclone move refusal](rclone-move-refusal.md) | Empty imports after a backend refused a MOVE, and the patch. |

## Testing

- [E2E testing](e2e-test.md) covers what the end to end suite exercises and what it costs to run.

What a particular service does and what its limits are is under
[Providers](../providers/index.md) rather than here.
