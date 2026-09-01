# Migrating to zurg

Read this page first. It applies to every migration and it is most of what you
need. The per-server pages are short because this one carries the shared part.

## The short version

**zurg publishes every media file the server you are leaving publishes and
more.** That was measured on 2026-09-01. The same five releases went into all
five servers and the mounts were read back with `tree`. Here is
[the full comparison](https://github.com/debridmediamanager/usenet-streaming-benchmark).
The only thing zurg publishes *less* of is par2 parity. Plex never turns that
into a library item.

So **you will not lose content.** Some of it arrives under a different
filename. That is the whole problem this page is about. Plex binds a library
item to a file path. A file at a new path is a new item.

What you trade is not files. It is **curation**.

| Survives | Dies with the old item |
|---|---|
| Watched flags, play counts, resume offsets | Collections membership |
| User ratings | Playlist entries (they store item ids) |
| The files themselves | Chosen posters, art and manual match fixes |
| | `added_at`. Your library floods Recently Added |

Watch state survives because `metadata_item_settings` is keyed by account and
`plex://` GUID rather than by path or item id. It re-attaches when the new item
matches to the same GUID. If Plex mismatches the re-added item then the state
does not come back. Check a handful after the first scan.

You can avoid that trade entirely at a price. Rewrite `media_parts.file` in
Plex's database so the rows never die. Or build a symlink shim tree that
reconstructs every old path over zurg's mount. Both work. Both are unsupported
surgery on an undocumented schema that shifts between Plex versions. A
half-applied rewrite is worse than either outcome it was meant to prevent.

These guides take the simple route and tell you exactly what it costs.

## Your library lands in `__magic__` and not in a symlink farm

Every server on this list hands its library to the \*arrs through a farm of
symlinks. **zurg does not and you should not rebuild one.** It has
[`__magic__`](../guides/magic.md) instead. That is the one directory whose
paths are *stored* rather than computed. A move inside it rewrites a row in a
small table. No bytes move. Nothing is copied. The release stays where it is on
the account. Point Sonarr and Radarr at it and they organise and rename however
they like at no cost.

That is not just one less moving part. It is a layer that cannot break the way
the old one did. A symlink has to point at a real path. The obvious target is
`__all__/<release>/<file>` and that path is *computed*. It changes when the
release is renamed. It changes again when two releases collide and zurg
suffixes one of them `{shorthash}`. Every such change silently dangles a link.
A `__magic__` placement is keyed on the release's content hash plus the file's
path inside it. So it survives a rename. It survives a `{shorthash}` suffix.
It survives a repair that re-adds the release under an entirely new id.

So whatever you have today **the paths change and the library is re-added**.
That holds for an \*arr symlink library and for Plex pointed straight at the
old mount. It is the trade named above and it is the whole cost of every
migration here.

## What you have today depends on your platform

This decides whether the renaming tables on the following pages describe your
Plex library or only the source it was built from. Get it right before you
read them.

### Linux and macOS. Your \*arrs already renamed everything

The symlink strategy is the documented setup for all four servers here and it
only exists on these platforms. The server publishes
`completed-symlinks/<category>/<release>/<file>.rclonelink`. Then `rclone mount
--links` turns each one into a real symlink. Then **Sonarr and Radarr import
from that farm into a library at paths they chose.** The mount is the source
and not the library.

Two consequences.

- **The paths Plex has are the \*arr's.** Always. Root folder then series
  folder then season folder. None of them contain a release name.
- **The filenames are the \*arr's too if you left renaming on.** That is
  "Rename Episodes" and "Rename Movies". With renaming off they are the source
  server's names and the tables on the following pages describe exactly what
  you see.

So if you run the \*arrs with renaming on then the per-server renaming tables
do **not** describe your library. They describe what the \*arr was handed at
import time. That still matters. A better source filename is a better parse
and you are about to re-import.

### Windows. No symlink layer at all

A symlink farm needs `rclone mount --links` and that is not part of a Windows
setup. The mount is a drive letter through WinFsp and Plex and the \*arrs point
straight at it. So **Plex shows the server's own filenames** and the renaming
tables describe precisely what you will see change. The [Windows
setup](../setup/windows.md) page covers the drive letter and its session rule.

### Coming off a symlink library

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never ask an \*arr to relocate the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr **move** the
files. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Adopt the files where they already are instead.

1. Add `__magic__/tv` and `__magic__/movies` as **new** root folders. Leave the
   old root folder in place for now.
2. Point the \*arr's library import at those paths so it adopts what is there.
   `__magic__` starts as a mirror of `__all__` so every release is already
   present as a folder holding its own files. With renaming on the \*arr
   applies its own scheme. That is a free row write because it never leaves the
   namespace.
3. Remove the old root folder **without deleting files**. Then point Plex at
   `__magic__`.

Watch `data/local` on zurg's `/magic/` dashboard while step 2 runs. That number
is the one that says whether something is importing by copying instead of
moving. On a correct import it does not grow.

The zurg side of this is documented behaviour. The \*arr side is ordinary
library import but it was not bench-tested for this guide. Do one series first
and check the number before turning it loose on the library.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice. Pick one. If you
use the \*arrs then pick `__magic__`. If you browse a library nobody organises
then pick the filter directories and leave `__magic__` off.
!!!

## The one guard you must not skip

**`autoEmptyTrash` has to be `0` before you touch anything.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

Plex deletes softly. At `0` an item whose file stopped existing sits in the
trash and comes back if the file does. At `1` it is gone permanently the moment
a scan notices. A mount that blips for ten seconds during a scan takes the
library with it. This has cost a 30,065-item library before.

Under these simplified guides that setting is doing more work than it used to
and not less. **The trash is where your old items wait while you check the new
ones.** Empty it when you are satisfied and not before. That is the step that
makes the loss real and it is the only irreversible thing in any of these
guides.

While you are in there turn off **"Generate video preview thumbnails"** for the
affected libraries. On a streaming mount every thumbnail pass is a full read of
the release through your news or debrid allowance. A migration hands Plex a lot
of new items at once.

## What every migration gains

Two of these are new files appearing in folders Plex already scans. They are
worth knowing before they surprise you.

- **Sample clips.** zurg is the only one of the five that publishes the sample
  file inside a RAR release's `Sample/` directory. Plex may pick a 9 MB
  `-sample.mp4` up as an extra or as a second version of the episode. If you do
  not want that then set
  [`only_show_the_biggest_file: true`](../reference/config.md) on the
  directories your media libraries scan.
- **`.nfo` files.** zurg is the only one that keeps them. They are inert under
  Plex's default agents. The XBMC and NFO agent reads them if you use it.
- **`thumbnail.jpg` and `.url` adverts.** Inert. `thumbnail.jpg` is not a
  filename Plex uses for posters and the `.url` files are the poster's
  advertising.
- **Empty folders** where a release's archive chain is broken. Plex ignores
  directories with no media in them.
- **par2 and sfv disappear.** zurg hides them by reading what the file is
  rather than what it is called. Plex never itemised them so this is invisible
  to your library. It only matters to tooling that walked them.

## The guides

- [From AltMount](altmount.md). Renames archive releases only
- [From decypharr](decypharr.md). Renames single-file and archive releases
- [From InfiniDysk](infinidysk.md). Renames single-file and archive releases
- [From nzbdav](nzbdav.md). Renames nothing and is the easiest of the five
- [From streamnzb](streamnzb.md). No library to migrate and a change of model

Naming behaviour on each page was measured on 2026-09-01 on a five-release
corpus. The builds were zurg `bda7e3c3` and AltMount `0614008b` and InfiniDysk
`cd9b1205` and nzbdav `794948be` and decypharr `0dd1cbbd`. A build older or
newer than those may name things differently. Spot-check a few releases against
your own tree before trusting a rescan list wholesale.
