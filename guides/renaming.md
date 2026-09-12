---
label: Renaming
icon: pencil
order: 68
---

# Renaming releases and files

zurg's mount is writable in exactly one way: you can **rename** a release folder
or a file inside one, anywhere in the library. It is on by default. Nothing is
copied, nothing is downloaded, and the debrid account is not touched — the new
name is stored beside the release and wins over the name zurg would otherwise
compute.

What you cannot do is **move** anything. Renaming and relocating look like the
same gesture in a file manager, and zurg treats them as opposites, for a reason
[the last section](#why-a-move-is-refused-when-a-rename-is-not) gives.

For a stored *layout* rather than a stored *name* — folders you arrange, an \*arr
importing by move — see [`__magic__`](magic.md). This page is about the name
only.

## Renaming through the mount

A rename in the mount is a WebDAV `MOVE` whose destination differs from the
source in the last path segment alone. rclone turns a FUSE `rename(2)` into
exactly that, so `mv` in the mount, F2 in a file manager and a WebDAV client all
arrive at the same handler.

```
mv "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show.S01E01.mkv" \
   "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show - s01e01.mkv"
```

Both levels work:

| Rename | Stored as |
|---|---|
| A release folder | `Torrent.Rename` |
| A file inside a release | `File.Rename` |

The `/dav/` and `/infuse/` endpoints accept `MOVE`. `/http/` does not — it is a
read-only browser and answers `405` outside `__magic__`.

### What a name has to satisfy

A new name is accepted when, after trimming whitespace, it is not empty, contains
no `/` or `\`, equals its own `filepath.Clean` (which also rejects `.` and `..`),
and — for a release folder — does not collide with the access key of a *different*
hash. A file name has to be unique inside its own release.

| Result | Status |
|---|---|
| Renamed | `201` |
| Empty name, a separator in it, or a destination naming only a directory | `400` |
| The name is taken | `412` |
| Source not found, or inside an archive | `404` |
| Refused (see below) | `403` |

Renaming a file *inside an archive* is not possible. The archive's interior is
generated from the archive, so there is nothing to write a name onto, and the
source lookup fails with a `404`.

## Renaming from the dashboard and the API

The same two renames are `POST` endpoints, and each has a matching reset that
drops the stored name and returns the release to its computed one:

```
POST /manage/{torrentHash}/rename
POST /manage/{torrentHash}/clear-rename
POST /manage/{torrentHash}/files/{fileid}/rename
POST /manage/{torrentHash}/files/{fileid}/clear-rename
```

There is no equivalent of `clear-rename` through the mount. A rename back to the
original name stores that name; it does not remove the override.

### The season fix

`GET /torrents/season-fix/plan` and `POST /torrents/season-fix/apply` are a bulk
file rename driven by Plex's own episode matching, for releases whose files are
numbered in a way nothing can parse. The plan is read-only and gives a per-file
skip reason. The apply takes an explicit list of hashes rather than an
apply-everything flag, so you confirm what you looked at.

## What a rename survives

The stored name lives on the release and is serialised into its `.zurgtorrent`,
so it survives:

- **A library refresh**, including one that rebuilds the release's file entries
  from the provider's listing.
- **A restart.**
- **A repair**, which re-adds the release by hash under a new id.
- **The provider renaming the torrent underneath you**, which Real-Debrid does.

It also travels: an exported `.zurgtorrent` carries the renames, so a
[local library](local-libraries.md) arrives named the way you named it.

One thing it does not survive is `ignore_renames: true`, which is the point of
that key — zurg disregards every stored name and shows the computed one. The
renames are not deleted, only ignored, so turning it back off brings them back.

## What a rename changes around it

A rename is a view, but several things are built from that view, and they are
updated with it:

- **The mount.** rclone's directory cache is invalidated for the old and the new
  path, so the change shows up without waiting out the cache.
- **`.strm` files**, if `save_strm_files` is on. The old ones are deleted and
  written again under the new name.
- **Plex and Jellyfin** are asked to look at the release again.
- **The on-disk cache record.** The `.zurgtorrent` is written under the new name
  and the old file is deleted. That deletion matters: left behind, a restart
  loads both, the hash collision resolves back to the other copy, and the rename
  silently reverts. That was a real bug, seen on 2026-08-17.
- **The SABnzbd and qBittorrent endpoints**, which recompute the folder they
  report to Sonarr and Radarr on every poll, so a rename mid-import moves the
  path they are told to import from rather than stranding them.

## Three traps

**A rename can re-file a release at the next refresh.** Directory membership is
decided by running the `directories:` filters over the release's name, and the
filters see the *renamed* name. The rename itself deliberately does not
re-evaluate them — it keeps the release in the directories it was already in —
but the next refresh does. So if a filter matches on something in the name and
your new name no longer matches it, the release moves to a different directory
later, with nothing at the time of the rename to suggest it will. Rename
defensively around filters that key on names.

**Changing the extension changes what the file is.** Nothing stops
`episode.mkv` becoming `episode.txt`; only separators are rejected. But
visibility is judged on the name the client sees, so the renamed file can drop
out of `only_show_the_biggest_file`, out of the playable-file logic, and out of
a media server's scan.

**A `.strm` URL already handed to something else breaks.** The signed token
encodes the access key and the file name, so a URL captured before the rename
resolves to nothing afterwards and answers `404`. zurg's own `.strm` tree is
rewritten, but anything that copied a URL out of it is not.

## Turning it off

| Key | Default | Effect |
|---|---|---|
| `dav_allow_rename` | `true` | `false` refuses a mount `MOVE` with `403`, naming the key in the body |
| `ignore_renames` | `false` | `true` disregards every stored rename and serves computed names |
| `mount_read_only` | `false` | `true` starts rclone with `--read-only`, so the kernel refuses the write before zurg sees it |

`dav_allow_rename` covers the mount. It does not gate the dashboard endpoints,
and it does not gate writes under `__magic__`, which reach no debrid account.
`mount_read_only` overrides everything, at the kernel, and is also the only way
to stop a mount `DELETE` — see [config.md](../reference/config.md) for why that matters more
than the rename does.

## Why a move is refused when a rename is not

Every one of these is refused:

| Attempt | Status |
|---|---|
| A release folder into another directory | `403` |
| A file into another release | `403` |
| A file into a subfolder of its own release | `400` |
| A top-level directory renamed or moved | `405` |
| Anything out of `__magic__` | `403` |

The rule underneath is the same each time: **a rename has somewhere to be
stored, and a move does not.**

A release's name is one string on the release, so writing a new one is a field
assignment that every later lookup reads back. But a top-level directory is not
a folder — it is a saved filter, and its membership is recomputed from the
`directories:` config on every refresh. Moving a release "into" `movies` would
write nothing, because nothing reads a stored answer to that question; the next
refresh would recompute membership from the filters and undo it. Refusing is
the honest answer. The same goes for a subfolder inside a release, whose shape
comes from the account's own file list.

`__magic__` exists because stored layout is genuinely useful, and it solves the
storage problem rather than pretending it is not there: a move inside it writes
a row to a small table keyed by content hash, which is why it survives a repair
re-adding the release under a new id. That table is scoped to the one namespace
on purpose.

There is a second reason not to widen the refusal surface casually.
[rclone-move-refusal.md](../internals/rclone-move-refusal.md) documents what a refused `MOVE`
does to a client that was not expecting one: under rclone 1.72.0, the VFS entry
is left pointing at the attempted destination, and a caller that falls back to
copy-then-delete reads EOF and reports success, producing a zero-byte file it
believes it wrote. Every refusal above is a refusal something has to survive.
