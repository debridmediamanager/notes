---
label: Migrating
icon: git-compare
order: 70
---

# Migrating to zurg

Read this page first. It applies to every migration and it is most of what you
need; the per-server pages are short because this one carries the shared part.

## The short version

**zurg publishes every media file the server you are leaving publishes, plus
more.** That was measured on 2026-09-01 by feeding the same five releases to
all five servers and reading the mounts back with `tree`
([the full comparison](https://github.com/debridmediamanager/usenet-streaming-benchmark)).
The only thing zurg publishes *less* of is par2 parity, which Plex never turns
into a library item.

So **you will not lose content.** Some of it arrives under a different
filename, and that is the whole problem this page is about, because Plex binds
a library item to a file path. A file at a new path is a new item.

What you trade is not files, it is **curation**:

| Survives | Dies with the old item |
|---|---|
| Watched flags, play counts, resume offsets | Collections membership |
| User ratings | Playlist entries (they store item ids) |
| The files themselves | Chosen posters, art and manual match fixes |
| | `added_at` — your library floods Recently Added |

Watch state survives because `metadata_item_settings` is keyed by account and
`plex://` GUID rather than by path or item id, so it re-attaches when the new
item matches to the same GUID. If Plex mismatches the re-added item, the state
does not come back — check a handful after the first scan.

You can avoid that trade entirely, at a price: rewriting `media_parts.file` in
Plex's database so the rows never die, or building a symlink shim tree that
reconstructs every old path over zurg's mount. Both work. Both are unsupported
surgery on an undocumented schema that shifts between Plex versions, and a
half-applied rewrite is worse than either outcome it was meant to prevent.

These guides take the simple route and tell you exactly what it costs.

## Which setup you have decides everything

Two questions, one command. Run this against the library folder Plex scans:

```bash
find /path/to/your/plex/library -maxdepth 3 -type l | head -3 | xargs -r -n1 readlink
```

**Setup A — it prints symlink targets.** Plex scans an \*arr-managed library
of symlinks and never looks at the mount. **The Plex-visible paths never
change in this migration**, because Plex stores the link's own path and only
the target moves. Nothing is re-added, nothing is rescanned, no curation is
lost. Every per-server page has a Setup A section and it is always the short
one. Take this route if you have it.

**Setup B — it prints nothing.** Plex scans the mount directly, so every path
carries the old server's root and its naming. Everything is re-added. This is
where the trade above actually gets paid.

## The one guard you must not skip

**`autoEmptyTrash` has to be `0` before you touch anything.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex deletes softly. At `0`, an item whose file stopped existing sits in the
trash and comes back if the file does; at `1` it is gone permanently the
moment a scan notices, and a mount that blips for ten seconds during a scan
takes the library with it. This has cost a 30,065-item library before.

Under these simplified guides that setting is doing more work than it used to,
not less: **the trash is where your old items wait while you check the new
ones.** Empty it when you are satisfied and not before. That is the step that
makes the loss real, and it is the only irreversible thing in any of these
guides.

While you are in there, turn off **"Generate video preview thumbnails"** for
the affected libraries. On a streaming mount every thumbnail pass is a full
read of the release through your news or debrid allowance, and a migration
hands Plex a lot of new items at once.

## What every migration gains

Two of these are new files appearing in folders Plex already scans, so they
are worth knowing before they surprise you.

- **Sample clips.** zurg is the only one of the five that publishes the sample
  file inside a RAR release's `Sample/` directory. Plex may pick a 9 MB
  `-sample.mp4` up as an extra or as a second version of the episode. If you
  do not want that, set
  [`only_show_the_biggest_file: true`](../reference/config.md) on the
  directories your media libraries scan.
- **`.nfo` files.** zurg is the only one that keeps them. Inert under Plex's
  default agents; read by the XBMC/NFO agent if you use it.
- **`thumbnail.jpg` and `.url` adverts.** Inert. `thumbnail.jpg` is not a
  filename Plex uses for posters, and the `.url` files are the poster's
  advertising.
- **Empty folders** where a release's archive chain is broken. Plex ignores
  directories with no media in them.
- **par2 and sfv disappear.** zurg hides them by reading what the file is
  rather than what it is called. Plex never itemised them, so this is
  invisible to your library and only matters to tooling that walked them.

## The guides

- [From AltMount](altmount.md) — renames archive releases only
- [From decypharr](decypharr.md) — renames single-file and archive releases
- [From InfiniDysk](infinidysk.md) — renames single-file and archive releases
- [From nzbdav](nzbdav.md) — renames nothing, the easiest of the five
- [From streamnzb](streamnzb.md) — no library to migrate, a change of model

Naming behaviour on each page was measured on 2026-09-01 against zurg
`bda7e3c3`, AltMount `0614008b`, InfiniDysk `cd9b1205`, nzbdav `794948be` and
decypharr `0dd1cbbd`, on a five-release corpus. A build older or newer than
those may name things differently, so spot-check a few releases against your
own tree before trusting a rescan list wholesale.
