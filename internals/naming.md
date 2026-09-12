---
label: Naming
icon: typography
order: 72
---

# zurg naming

Almost every name zurg shows is computed, never stored. A release's folder name,
a file's name inside it, and the on-disk filename of its cache record are all
derived from the torrent on every lookup. Nothing writes those down and reads
them back, because a stored name is a second thing to keep in step with the
library, and keeping it in step is exactly what a repair or an NZB
re-resolution breaks.

The exception is a rename the operator asked for. That one IS stored, on the
release itself, and it beats every derivation below. Section 9 has the rules,
and the renaming guide is the user-facing version. Everything else on this page
describes the name a release has when no rename is set.

That has one consequence worth stating first, because it is the source of most
surprises for anything integrating with zurg: a folder can change name without
anything having "renamed" it. The inputs changed, so the output changed.

This file carries the rules, not the thresholds. Where a rule is settled by a
heuristic it names the function that settles it and stops there — those are
tuned against real releases and change, and copying them out here only makes a
second thing to keep in step. Code references are package-relative.


## 1. The release folder name

`internal/torrent/key.go`, GetKey / GetKey_Original

The folder under `__all__/`, the `.zurgtorrent` filename, the key every lookup
goes through, and what zurg calls the "access key" are all one string, decided
in this order, first match winning:

  | Condition                                   | Folder name               |
  |---------------------------------------------|---------------------------|
  | `ignore_renames: false`, Torrent.Rename set | Torrent.Rename            |
  | `retain_rd_torrent_name: true`              | Name, unmodified          |
  | `retain_folder_name_extension: true` AND    | Name, unmodified          |
  |   Name contains OriginalName                |                           |
  | otherwise — both flags at their defaults    | OriginalName, `.mp4` then |
  |                                             |   `.mkv` trimmed off      |

`retain_rd_torrent_name` is checked first and shadows
`retain_folder_name_extension` entirely. The second applies only where Name
contains OriginalName as a substring; where it does not, the trim happens
anyway.

The trim is `strings.TrimSuffix` run twice, which is three rules in one. Only
`.mp4` and `.mkv` come off, so `.avi`, `.ts`, `.iso` and the rest stay in the
folder name; it is case sensitive, so `Movie.2019.MKV` keeps its `.MKV`; and the
two run in sequence rather than as alternatives, so `Movie.2019.mkv.mp4` becomes
`Movie.2019`. A suffix may then be appended — section 4. The result is a single
path component, never split on `/`.

DEPRECATED. `retain_folder_name_extension` and `retain_rd_torrent_name` are
deprecated and will be removed. Behaviour is unchanged for now, and setting
either logs a warning at startup. Both key the library on Name, which the
account rewrites underneath zurg (section 2); the defaults key it on what the
torrent itself declared, which the account leaves alone. On an instance
fronting Sonarr or Radarr — one carrying a `sabnzbd:` or `qbittorrent:` block —
the defaults are the only correct values, because an access key that moves
after an import loses the release. `ignore_renames` is not deprecated.


## 2. Where Name and OriginalName come from

  Real-Debrid   `internal/realdebrid/types.go`
                Name = `filename`, OriginalName = `original_filename`

  TorBox        `internal/torbox/types.go`, wireTorrent.originalName
                Name = `name`. OriginalName = the single directory every file
                lives under, when there is exactly one; files at the tree root
                fall back to `name`, except a lone bare file, whose own name is
                used.

  AllDebrid     `internal/alldebrid/types.go`, originalName
                Same rule as TorBox over the flattened file list, falling back
                to the magnet's `filename`.

  NZB           `internal/nzb/provider.go`
                Name and OriginalName are both releaseName, and the torrent's
                Hash is the release id. Section 3.

Because the debrid backends derive OriginalName from the torrent's own root
folder, two accounts holding the same content produce the same folder name.

What Real-Debrid's two fields mean, measured 2026-08-27 against a test account
of ~84k torrents, 252 of them sampled read-only through `GET /torrents/info`:
`original_filename` was the name the torrent declared — the pack or folder name
— in every case, and never a single file's name. `filename` is not that. It
collapses to one file's own basename, and does so exactly when one file of a
multi-file torrent is selected: 90 of the 112 sampled torrents in that shape,
against 0 of the 34 with several but not all selected and 0 of the 24 with all
selected. On a 221-file pack with one episode selected, `original_filename`
read `Marvel Cinematic Universe MCU Collection 2008-2023 1080p jZQ` while
`filename` read `Spider-Man.No.Way.Home.2021.1080p.BluRay.x264...-NOGRP.mkv`.
So the default gives the pack name and `retain_rd_torrent_name: true` gives the
individual file's — which is why the flag is deprecated: `filename` follows
account state, and the access key must not.


## 3. NZB release naming

`internal/nzb/provider.go`, releaseName; `internal/nzb/parse.go`

The release id, which is also its Hash, is `hex(sha1(lowercase(nzb filename)))`
— of the filename rather than the content, so re-saving an NZB does not orphan
the torrent built from it. The folder name is that FILENAME without its
extension, unless the stem looks like a hash or sanitises away to nothing, in
which case the NZB's own `<head>` metadata name is used instead. The filename
wins because it is the name the indexer wrote, the downloader saved and
automation looks the release up by, while indexers routinely repost with a
subject line in the metadata block. `stemLooksJunk`, `looksLikeHash` and
`sanitizeReleaseName` in `internal/nzb/parse.go` settle all three questions;
treat them as opaque.


## 4. The three name suffixes

Three suffix formats exist. They are unrelated.

  ` {xxxxxx}`   On a release folder, when two DIFFERENT releases share a name:
                six hex characters of that release's own infohash. Within the
                group, the MOST RECENTLY ADDED release keeps the bare name and
                every other takes the tag. Decided once per refresh by a pass
                that can see the whole library and persisted as KeySuffixed, so
                GetKey stays a pure function of the torrent
                (`internal/torrent/key.go`, disambiguateNames). An RD torrent
                and an NZB of the same release are two different releases here,
                since an NZB's hash is a sha1 of its filename.

  ` (tag).ext`  On a FILE whose basename repeats inside one release, since zurg
                flattens a torrent's tree into a single directory. The tag is
                the directory that already tells the colliding files apart —
                the shallowest path component distinct across the group — else
                six hex characters of sha1 over the file's path. Which depth
                qualifies, and what a component may carry into a filename, are
                `dupeTags` and `sanitizeTag` in
                `internal/torrent/dupenames.go`; treat both as opaque. The
                group is every file of the listing, selected or not, so a file
                that stops being selected still resolves to the key it was
                filed under. `__magic__` is the one exception: it shows the
                release's real tree with no tags in it, because the directories
                tell the files apart there — section 8.

  `_xxxxxxxx`   On an ON-DISK filename whose input held any non-ASCII
                character: eight hex characters of sha256 of that input.
                Section 6. Never appears on the mount.


## 5. File names inside a release

`internal/torrent/manager.go`. VisibleName(key, file) is the single authority
for the name the mount shows and the name a lookup must match: a File.Rename
when there is one and `ignore_renames` is false, otherwise the SelectedFiles
key, which already carries the tag of section 4. GetFilename returns
`filepath.Base(file.Path)` instead and so throws that tag away — display and
lookup must both go through VisibleName, or a request for a tagged name
resolves to nothing while N files share one bare name.


## 6. On-disk filenames

`internal/torrent/utils.go`, sanitizeFilename — opaque, and it applies ONLY to
files zurg writes on the host (`data/<name>.zurgtorrent` and the STRM tree),
never to what the mount serves. It is far more aggressive than anything above:
a release whose mount folder is `Три богатыря` has a cache file whose name is a
run of underscores plus the `_xxxxxxxx` suffix that keeps it distinct from the
next Cyrillic title. A different namespace, and not meant to match.


## 7. Archive interiors

A release served out of a RAR, ZIP or 7z lists the archive's contents rather
than its volumes, and two rules change what those are called.
`stripRedundantRoot` (`internal/universal/rar_streamer.go`) removes leading
directories that wrap the whole archive; `payloadRenames`
(`internal/universal/deobfuscate.go`) presents a single obfuscated payload
under the RELEASE's name, moving every entry sharing its stem with it. What
counts as obfuscated is `looksObfuscated` in the same file, zurg's port of
SABnzbd's test — opaque, along with the guards around it. Nothing is rewritten
on disk, and `archiveName` resolves the archive's own spelling too.


## 8. Directory names

`internal/torrent/manager.go`, `internal/torrent/provider_directories.go`

Built in, and reserved:

    __all__          every release
    __unplayable__   releases with nothing playable
    __dump__         dumped torrents
    __downloads__    the downloads view
    __magic__        the writable overlay, the one directory whose layout is
                     stored rather than computed. It holds the releases
                     `__all__` holds, each as the directory tree its files'
                     `File.Path` values describe rather than flattened
                     (`internal/magic/tree.go`)
    int__all__       internal hash index

`__downloads__` and `__magic__` are not filters, so they are appended to the
root listing by hand, and `__magic__` appears only when magic is enabled. Any
name beginning `int__` is skipped from the root listing entirely.

Per account there is one more, `"__" + account name + "__"` — `__realdebrid__`,
`__torbox__`, `__nzb__` — built from the providers block. It also decides where
reads go: a file opened under `__torbox__` is served by TorBox even when another
account holds the same release and would win on config order. An account whose
name would collide with a reserved one gets none, and zurg warns. Everything
else at the root is a key from the `directories:` block, verbatim.


## 9. User renames

`internal/torrent/rename.go`, `internal/torrent/rename_bulk.go`

A rename is a view, not a change to anything on the debrid account. It is stored
as Torrent.Rename or File.Rename and wins over every derivation above, until
`ignore_renames: true` makes zurg disregard it entirely.

A torrent rename is accepted only when the name, after trimming, is not empty,
contains no `/` or `\`, equals its own `filepath.Clean` (which also rejects `.`
and `..`), and does not collide with an existing access key belonging to a
different hash. Applying it re-keys the directory maps, writes the
`.zurgtorrent` under the new name and DELETES the one under the old — left
behind, a restart loads both and the rename silently reverts.

The season fix (`/torrents/season-fix/plan` and `/apply`) is a bulk file rename
driven by Plex's own episode matching: plan is read-only and gives a per-file
skip reason, apply takes an explicit list of hashes rather than an apply-all
flag.


## 10. Consequences for anything integrating with zurg

If you are building a path from the torrent's name — a symlink farm, a remote
path mapping, a script — these are the ways it goes wrong:

  a. The extension. Only `.mkv` and `.mp4` come off, case sensitively. Any other
     container keeps its extension in the folder name.

  b. The rename. `Torrent.Rename` wins over the derived name, and RD's own
     renaming of a torrent changes `Name` under you.

  c. The hash suffix. Two different releases sharing a name means one of them is
     ` {a1b2c3}`, and which one moves as content is added.

  d. The duplicate-file tag. A file whose basename repeats inside a release is
     served as `name (tag).ext`, where the tag is a directory component or a
     path hash. `filepath.Base(file.Path)` does not reproduce it.

  e. The archive rename. An obfuscated payload inside an archive is presented
     under the release name, not its own.

  f. NZB names come from the `.nzb` FILENAME, not from anything inside it, unless
     the filename is a hash. Name the file, name the folder.

  g. Sanitised on-disk filenames are a different namespace from mount names, and
     for non-ASCII releases they deliberately do not match.

The robust way to resolve a release is by hash, then ask zurg what it is called.
Reconstructing the name is guessing, and every rule above is a way for the guess
to be wrong.
