# `__magic__`, a directory you can organise

Every other directory zurg serves is computed. `movies` holds what matches the movies filter, `__all__` holds everything, and a release's folder holds the files its account says it has — so the layout is a view of the library, recomputed on every refresh, and there is nowhere to put anything.

`__magic__` is the one directory whose paths are **stored**. A move inside it rewrites a row in a small table; no bytes move, nothing is copied, and the release stays exactly where it was on the debrid account. What you get is a tree you can arrange — by hand, or by pointing Sonarr or Radarr at it.

It is off by default. Turn it on with:

```yaml
magic:
  enabled: true
```

and restart. The routes are decided at startup, so toggling it from the dashboard needs a restart before the namespace answers.

## What it is for

An \*arr imports by **moving** the file out of the download folder into the library. Zurg had nowhere to receive that move, so the \*arr fell back to copying — and a copy from a debrid mount means pulling the entire release down over the network, which is the one thing the mount exists to avoid.

With `__magic__` the import is a rename inside one namespace: a row is written, the file appears where the \*arr put it, and nothing is downloaded. That is what makes [the SABnzbd endpoint](sonarr-radarr.md) worth having — it is a thin layer on top of this, and without it every import would be a full download.

It only works if the \*arr's **root folder is also inside `__magic__`** — `/mnt/zurg/__magic__/tv`, not a directory elsewhere on the machine. A move whose destination is outside the namespace is a move between two filesystems, which is a copy again; zurg refuses it outright with a `403` rather than letting it happen quietly. [sabnzbd.md](sonarr-radarr.md) has the exact settings.

Organising the library by hand is the other half, and it works with no \*arr involved.

## With nothing stored, it is `__all__`'s releases as real folders

Open `__magic__` on a fresh install and you get every release `__all__` holds, as a folder each. The table starts empty and only ever stores **deviations** from that default, so an untouched library stores nothing at all, and new releases appear in `__magic__` the moment they appear anywhere else.

There is no directory config behind it: no `only_show_the_biggest_file`, no size filters. What the release has is what you see.

The one difference from `__all__` is **what a release folder looks like inside**. Everywhere else zurg flattens a release into a single directory, keyed by filename, with a suffix where two files would collide:

```
__all__/Show.S01/Show.S01E01.mkv
__all__/Show.S01/Gag Reel (Extras).mkv
```

`__magic__` shows the tree the release actually has:

```
__magic__/Show.S01/Show.S01E01.mkv
__magic__/Show.S01/Extras/Gag Reel.mkv
```

That is not cosmetic. Sonarr and Radarr scan a download folder as a folder: a file under an `extras`, `samples`, `featurettes`, `trailers` or `deleted scenes` **subfolder** is skipped, and one at the top level is considered — so the flattened `Gag Reel (Extras).mkv` gets offered for import where the real tree has it passed over. And their import only falls back to the download's own title for parsing when the folder holds a single video, so a movie flattened beside its featurette loses that fallback. Since [the SABnzbd endpoint](sonarr-radarr.md) hands an \*arr a folder under `__magic__`, this is the surface those rules run against.

Two details of the shape:

- **A single wrapping folder is dropped.** Nearly every release is one folder holding everything, and that folder is what the release is already *called* — the debrid backends derive the name from it. So `/Show.S01/Season 01/ep1.mkv` shows as `Show.S01/Season 01/ep1.mkv`, not `Show.S01/Show.S01/Season 01/ep1.mkv`. Only one level, and only when nothing sits beside it: a release with a file at the top and a folder beside it keeps both.
- **No duplicate-name suffixes.** They exist to keep a flattened listing unambiguous, and a tree has directories to do that.

Everything else about a release folder is unchanged, including an archive: a RAR set is still browsable as a directory, now sitting wherever its volumes sit in the tree, and a release served out of one flattened archive still lists that archive's contents.

`__all__` and the `directories:` filters stay flat. They are what a media server should be pointed at, and nothing about them moves.

## Organising it

Through the mount, with ordinary commands:

```bash
mkdir -p /mnt/zurg/__magic__/tv/The\ Show/Season\ 01
mv /mnt/zurg/__magic__/Some.Release.S01E01.1080p/ep1.mkv \
   /mnt/zurg/__magic__/tv/The\ Show/Season\ 01/S01E01.mkv
```

The file now lives at the new path and is gone from the old one. It streams from the same account it always did.

Whole release folders move too, as a single row:

```bash
mv /mnt/zurg/__magic__/Some.Movie.2024.2160p /mnt/zurg/__magic__/movies/Some\ Movie\ \(2024\)
```

Directories move with everything under them, as one batch. Moves go both ways: a file can be moved *into* a release folder as well as out of one, and the folder lists it beside the release's own entries — which is what a program that puts something back into the folder it is importing from needs to see. Where a name arrives from two places at once the deliberate one wins: what you moved beats what the release calls that name, which beats a real file in `data/local`, and the loser is left out rather than listed twice.

One shape fails through the built-in mount, and only under the default `union_writable: local`: renaming a directory *you created through the mount*, so `mkdir` and then, later, `mv` of that directory. Under the default order `mkdir` creates the directory on rclone's own local upstream while the rows beneath it make the same directory exist server-side, so rclone renames its local copy, moves the rows one file at a time — zurg answers every one of those correctly — and then fails removing a source it has already renamed away:

```
ERROR : __magic__/tv/Saul: Dir.Rename error: RenameDir rmdir: object not found
```

The rows end up exactly where you asked: zurg serves the new path and 404s the old one. But `mv` exits 1, and the mount is left showing the emptied source directory and not the destination until its listing is re-read. No request for that removal ever reaches zurg, so nothing zurg does can prevent it. Moving files, and moving a whole release folder, work under either order. If you reorganise directories through the mount, set [`union_writable: server`](../reference/config.md#rclone-settings), where the directory exists only in the namespace and the rename is one server-side operation. Measured on rclone 1.71.2.

`rm` hides things — see [Deleting hides, it does not destroy](#deleting-hides-it-does-not-destroy).

## A move survives repair, rename and re-listing

This is the part that matters most, because getting it wrong would quietly empty an organised library.

Zurg repairs a broken release by re-adding it to the account. The torrent id changes, the access key changes, the file ids change — so a table keyed on any of those would lose every placement the first time a link rotted. Rows are instead keyed on the release's **content hash** plus the file's **path inside the release**, neither of which repair changes.

The consequences, all deliberate:

- **A repair keeps your layout.** The release comes back under a new id and the files are still where you put them.
- **Renaming a release does not move anything.** A rename, and the suffix zurg adds when two different releases would share a folder name, both change what a release's default folder is called. Placements are unaffected.
- **A file that goes missing is not forgotten.** If a repair changes the file set — Real-Debrid re-packing a rar'ed release is the usual cause — a row whose file no longer exists is *kept but not listed*. If the file comes back, so does its position. Rows in that state show up on the dashboard as **dangling**, where you can drop them.

One backend needs more than an exact path match. A Usenet post's filenames are *resolved* rather than given, re-derived on every load and never stored, so a post first read while the news server was unreachable keeps its obfuscated names until a later load recovers the real ones. For those, a row falls back to the file's index inside the NZB, and then to basename-plus-size where exactly one file matches.

## Deleting hides, it does not destroy

`rm` under `__magic__` writes a **tombstone**: the entry disappears from `__magic__`, and stays exactly where it was in `__all__`, in every filter directory, and on the debrid account. Nothing is deleted.

That is not timidity — it is what makes an \*arr safe to point at. On a quality upgrade an \*arr deletes the old file, and on import it deletes the whole job folder. If those deletes removed content, an upgrade would destroy the release; and if a delete merely removed the *row*, the file would reappear at its default location — right back in the folder the \*arr imports from.

If you want a delete to really delete:

```yaml
magic:
  allow_delete: true
```

Then a **file** delete removes the content from the account as well. A release folder, a directory and an entry inside an archive never do, whatever this is set to: the first is what Sonarr deletes after every import, and the last has no file of its own to remove.

`dav_allow_rename`, and the mount's own ungated delete path, have nothing to do with any of this. Those cover the routes that rename and destroy what the debrid account holds; a write under `__magic__` reaches no account. `mount_read_only: true` still overrides everything, at the kernel.

Undoing a tombstone is a click on the dashboard.

## Filters and `__all__` are untouched

A release you have moved is still in `movies`, still in `recent`, still in `__all__`, under its original name. `__magic__` is a second view of the same library, not a relocation.

This surprises people, so it is worth saying plainly: **moving something in `__magic__` changes only `__magic__`.** The filter directories are computed from the release, and the release has not changed.

For a media server, point it at **one** of the two. A Plex library that scans both `shows/` and `__magic__/tv` will find every episode twice.

## Sidecars: `.nfo`, posters, subtitles

An \*arr writes metadata next to the video, and Bazarr writes subtitles. Those are real files and zurg has nowhere to put them in a debrid library, so they go to local disk under `data/local/__magic__/`.

If you use zurg's built-in mount, this already happens and needs nothing from you: the mount is a union of `data/local` and zurg's WebDAV, and rclone sends every newly created file to the local half. Zurg never even sees the write. This is also why Sonarr's "is this folder writable?" test passes.

If you mount `/dav` yourself — your own rclone, Infuse, a Windows WebDAV drive — zurg accepts the `PUT` and writes into that same tree, so both views agree. Two caps apply:

```yaml
magic:
  sidecar_max_mb: 32       # per file
  sidecar_budget_mb: 2048  # the whole tree
```

Over the first is `413`, over the second `507`. They bound what *zurg* writes. With the default `union_writable: local`, rclone's own local upstream cannot be refused from here, though the tree is re-measured before any refusal, so files it put there do count against the budget the next time zurg is asked to write one. `union_writable: server` flips that: the create itself arrives at zurg, so the caps decide every write through the mount too, and anything outside `__magic__` is refused outright.

A sidecar cannot be created inside a release folder — the library owns every name in there, so a file put among its entries would be listed by nothing — and a real file cannot be moved into one for the same reason. A `DELETE` of a sidecar really deletes it, which is the one place in `__magic__` where a delete is not a tombstone: a tombstone hides an entry the library still holds elsewhere, and a sidecar's bytes live in `data/local` and nowhere else.

## The dashboard

Once the library has loaded, zurg logs one line saying how many rows the table holds and how many of them are dangling, so a library that has lost content does not keep a growing set of rows nothing mentions. `/magic/` on zurg's normal port shows what the table holds: every stored row grouped by release, what each one is and where it came from, the dangling ones in their own section, and the sidecar tree with its size against the budget. It also reports the journal and snapshot sizes, and the size of the whole of `data/local` — the number that says whether something is importing by copying, because under the default `union_writable: local` a client that copies rather than moves puts the bytes there and nothing else would ever show it.

Under `union_writable: server` that number stays at zero and the log is what says it instead: a copying client's `PUT` is refused, so the tree it would have filled is never written. The bytes are not saved by the refusal — rclone's cache holds them and retries — but they are no longer on this disk under a name zurg can count. [The qBittorrent guide](sonarr-radarr-torrents.md) has the cause, which is a client-side setting in every case: an \*arr only moves an import when it is free to remove the download afterwards.

From there you can reset a placement (the file goes back to its default location), clear a tombstone (the entry comes back), drop a dangling row, prune all of them at once, and delete a sidecar. Each is confirmed before it runs.

Sidecars **nothing accounts for any more** are listed apart from the rest and counted: an `.nfo` beside a release that has left the library, or inside a placement that has been forgotten. They are still served — a real file is the last thing a path resolves to, and nothing above them is claiming the name — so what has gone is the reason they were put there. zurg never sweeps one. A directory you made for sidecars yourself, through the mount rather than through zurg, reads the same way, because that leaves no row either.

If the SABnzbd endpoint is on, the page also lists its jobs — id, name, category, state, and the folder handed to the \*arr — which is the fastest way to answer "why is Sonarr still showing this as downloading".

## Durability

Every change is appended to `data/magic.journal` and flushed to disk **before** the request is answered, so a move an \*arr believes it made is a move that survives a crash. The journal is folded into a `data/magic.json` snapshot at startup, when it grows past a threshold, and on shutdown.

A torn last line from a power cut is dropped and everything before it is kept. A snapshot written by a different schema version is discarded rather than guessed at, and a journal line from one stops the replay there. A snapshot or journal that cannot be read is a warning and an empty table, not a failed start — and a table whose files cannot be *opened* leaves `__magic__` serving read-only, as the mirror of `__all__` it starts as, with every write refused. Writes arriving during shutdown are refused with `503` instead of being acknowledged and lost.

## Status codes

Useful if you drive the namespace over WebDAV directly; the mount handles all of this for you.

| Code | Meaning |
|---|---|
| `201` | MOVE, MKCOL or PUT created something |
| `204` | DELETE, or a PUT that replaced a sidecar |
| `400` | a path this namespace cannot store, or a `Destination` header that is missing or unreadable |
| `403` | a destination outside `__magic__`, a path the library answers for, a path running through a file, `__magic__` itself, or a table that is read-only |
| `404` | nothing there, or a MOVE out of an archive that no longer holds the entry |
| `405` | MKCOL where something already exists, or PUT onto a directory |
| `409` | missing parent, non-empty directory, an occupied destination with `Overwrite: T`, or a MOVE out of an archive that will not open |
| `412` | occupied destination with `Overwrite: F` |
| `413` / `507` | over `sidecar_max_mb` / `sidecar_budget_mb` |
| `503` | shutting down, or a MOVE whose source cannot be served right now — with a `Retry-After` |

`MOVE` refuses any destination outside `__magic__`: the filter directories stay read-only.

A `MOVE` **out of an archive** is also checked against the archive itself before anything is written. An import is a `MOVE`, a `MOVE` that succeeds is a promise nothing re-checks afterwards, and the listing the client walked is no evidence for it: parsed archive contents are memoised, so a release whose bytes have gone keeps listing its episodes. So the volume's health, the release's article damage, and — where those say nothing — the archive itself are all consulted first, exactly as a `HEAD` of the same path consults them, and a healthy release answers out of the same memo its listing already built. A source that will never be readable is a `409`, one that cannot be read at the moment is a `503` with a `Retry-After`, and a name the archive does not hold stays a `404`. Nothing is recorded on a refusal.

## Limits worth knowing

- **`magic.enabled` needs a restart.** The routes are registered at startup.
- **One placement per file.** Moving a file again re-places it; the same file cannot appear at two paths.
- **A file inside a rar set can be placed** like any other — the row remembers the volume and the path inside it, so it survives a re-pack the way a plain file does. Nothing can be created *underneath* a placed file, though: a path that runs through one is refused.
- **`serve_strm_files` is ignored in `__magic__`'s listings.** What the namespace exists for is an \*arr moving the real file out of it, and a `.strm` is not a file anything can import. A client that asks for one by name is still answered.
- **Paths are compared exactly as they arrive.** There is no Unicode normalisation and no case folding, so a client that spells a name one way and asks for it another will not find it.

## See also

- [sabnzbd.md](sonarr-radarr.md) — pointing Sonarr and Radarr at zurg, which is what `__magic__` was built to make possible
- [usenet.md](usenet.md) — the NZB backend those grabs land in
- [config.md](../reference/config.md#__magic__-a-directory-you-can-organise) — every key in the `magic:` block
