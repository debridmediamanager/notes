---
label: From InfiniDysk
icon: arrow-right
order: 70
---

# Migrating from InfiniDysk v1.1.2 to zurg

This guide moves a Plex library from an InfiniDysk-backed mount to zurg's `nzb`
backend without Plex rescanning from scratch, without deleting library items,
and without losing watch state, play counts, collections, ratings or artwork
choices. Directory layouts and behaviour cited here were measured live on
2026-08-19 against InfiniDysk v1.1.2 and zurg HEAD `23869fa4`; anything not
measured is marked unverified.

Why the migration is worth it, beyond preference: v1.1.2 rejected an entire
10-episode season pack (`Servant.S01.2160p.ATVP.WEB-DL`) on both import
attempts with `430 No such article`, for a message-id a direct NNTP `STAT` on
the same account answers `223` for — the article is present, the server holds
it. zurg imported the identical NZB and served all ten episodes. Expect the
zurg side to end up with releases InfiniDysk never had.

One difference in acquisition, stated up front: zurg's own ingestion is a
watch directory — `.nzb` files dropped into `nzbs/`, rescanned every 15 s. It
does have a [SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) that Sonarr and Radarr
can grab through, opt-in and Usenet-only, but it is not yet as strong a
download client as it looks: zurg does not check whether a post's articles are
still on the news server, so a dead release reports Completed and fails on the
first read instead of being blocklisted and re-grabbed. This guide migrates
the existing library; decide the acquisition path separately.

---

## 0. The mechanism, so the steps make sense

Plex binds every library item to a file path — `media_parts.file` in
`com.plexapp.plugins.library.db`. A changed path is not a rename to Plex: it
is a new item plus a deleted one.

What that costs you is narrower than the folklore says, and worth knowing
exactly, because it decides how much effort the rest of this guide is worth.
Measured against a live 10,126-item library:

- **Watch state survives.** `metadata_item_settings` is keyed by `account_id`
  plus a `plex://` GUID, not by the item id or the path:

  ```sql
  metadata_item_settings(id, account_id, guid, rating, view_offset,
                         view_count, last_viewed_at, …)
  -- ('plex://movie/5d776d1796b655001fe3f5d3', 1, NULL, 1707662516)
  ```

  Watched flags, play counts, resume offsets and user ratings re-attach when
  the new file matches to the same GUID. `metadata_item_views` is GUID-keyed
  too.
- **Curation does not.** Collections, playlists (they store metadata item
  ids), manual poster/art/match choices and `added_at` all hang off the
  `metadata_items` row and die with it. A path change floods Recently Added
  with your entire library.
- **And the trash is the real hazard.** Deletion is soft — `deleted_at` on
  `media_parts` and `media_items` — which is exactly what `autoEmptyTrash: 0`
  preserves. Empty the trash while the mount is missing and the items are gone
  for good.

So the entire job is still: **the paths Plex already has must keep resolving to
the same bytes.** Just be clear that what you are protecting is the library's
structure and curation more than its watch history.

Which is why the first question is where Plex actually points.

### Setup A — symlink library (the recommended InfiniDysk setup, and the easy migration)

InfiniDysk's documented Plex path is the symlink import strategy: the WebDAV
tree exposes `completed-symlinks/<category>/<release>/<file>.rclonelink`,
rclone mounted with `--links` turns each into a real symlink, and Sonarr/Radarr
import those symlinks into a media library at paths *the arrs chose* —
`/media/movies/Movie (2024)/Movie.mkv` and the like. Plex scans that library.

Every such symlink targets the content-addressed store, never the human tree:

```
$ readlink "/media/movies/Toy Story 5 (2026)/Toy.Story.5.2026.….mkv"
/mnt/remote/nzbdav/.ids/1/8/5/e/d/185ed3fe-6b74-44f1-967f-fc0222f195ec
```

If this is your setup, **the Plex-visible paths never change in this
migration**. Plex stores the symlink's own path in `media_parts.file`; only
the target moves. The whole job is repointing each symlink from an
InfiniDysk `.ids` object to the same file in zurg's mount, while both servers
are serving — so no path is ever broken, and Plex sees nothing at all.

### Setup B — Plex points straight at `/content`

The minority setup: a Plex library rooted at
`<mount>/content/<category>/<release>/…`. Here the paths embed InfiniDysk's
roots and its SAB categories, neither of which zurg reproduces: zurg's WebDAV
root is `/dav/<directory>/` with directories driven by its own filters, not by
categories. Section 6 works through the options; the short answer is a symlink
shim tree that rebuilds the old paths over zurg's mount.

Decide which you are before proceeding:

```bash
IDMOUNT=/mnt/remote/nzbdav        # your InfiniDysk rclone mount
# If this prints symlink targets under .ids, you are Setup A:
find /path/to/your/plex/library -type l -lname '*/.ids/*' | head -3 | xargs -r -n1 readlink
```

---

## 1. Pre-flight: make Plex unable to hurt itself

Do all of this before touching anything else.

**1. `autoEmptyTrash` must be 0.** If the mount blips during a scan, Plex
concludes every file was deleted. At `autoEmptyTrash=1` they are removed
permanently and at once; at `0` they sit in the trash and come back when the
mount does. This has cost a 30,065-item library before.

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

**2. Disable automatic scanning for the duration.** Settings → Library:
uncheck "Scan my library automatically", "Run a partial scan when changes are
detected", and "Update my library periodically". (The equivalent prefs are
`FSEventLibraryUpdatesEnabled`, `FSEventLibraryPartialScanEnabled`,
`ScheduledLibraryUpdatesEnabled`, settable via the same `/:/prefs` PUT —
unverified against your Plex version; the UI checkboxes are the sure path.)

**3. Confirm nothing is playing and nothing is scanning** before any step that
stops a server or a mount — sessions only prove nobody is watching; a scan is
the thing that does damage:

```bash
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Use `grep -o … | wc -l`, never `grep -c`: grep exits 1 when it finds nothing,
which is the *good* case here, and that aborts a `&&` chain or a `set -e`
script right before the step it was guarding. If a scan is running, wait it
out.

**4. Back up the Plex database.**

```bash
sudo systemctl stop plexmediaserver
PDB="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases"
cp -a "$PDB/com.plexapp.plugins.library.db"* ~/plex-db-backup-$(date +%F)/
sudo systemctl start plexmediaserver
```

**5. Record per-section item counts** to compare after cutover:

```bash
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'title="[^"]*"'
```

One warning that applies to every command in this guide: **never point a
recursive walk, an `rclone copy`, or any scanner at InfiniDysk's WebDAV
root.** The `.ids` tree materialises all 16 hex children at every one of its
five levels regardless of contents — 16^5 ≈ 1,048,576 directories. Scope
everything to `/content`, `/nzbs` or `/completed-symlinks`.

---

## 2. Recover the NZBs

zurg's library *is* a directory of `.nzb` files. You need one per release,
named after the release folder, because on both servers **the release folder
is named after the NZB file** — not the poster's subject line, not the inner
filename. That is what makes path-identical trees possible: name the `.nzb`
`<release>.nzb` and zurg produces the folder `<release>`.

InfiniDysk's WebDAV `/nzbs/<category>/` mirrors the queue and is readable:

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --webdav-url ...   # scoped to /nzbs — never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

Whether completed (historical) jobs remain listed under `/nzbs` after they
finish is **unverified** — it mirrors the queue, and your history may be
deeper than your queue. For anything missing there, the NZB metadata
InfiniDysk keeps for remounting lives in `{CONFIG_PATH}/blobs/` on the
InfiniDysk host (per its own docs). The blob format and naming are
**unverified**; check before trusting them:

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

If blobs are not plain XML on your install, your indexer's download history
is the fallback of last resort.

Then name every file after its release folder, exactly:

```bash
# releases.tsv: <category>\t<release>, from the live content tree
find "$IDMOUNT/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

Each recovered NZB must end up as `<release>.nzb` for the `<release>` in that
list. NZBs pulled from `/nzbs/<category>/` normally already carry the right
name, since that name is where the folder name came from. Verify rather than
assume — a mismatch here is a renamed folder, which is a deleted item.

Three naming caveats, all verified in zurg's code:

- zurg strips a trailing `.mkv` or `.mp4` from the release name
  (`GetKey_Original`, `internal/torrent/key.go:14`). If any InfiniDysk release
  folder itself ends in `.mkv`/`.mp4`, set
  `retain_folder_name_extension: true` in zurg's config or that folder's name
  will change.
- Two *different* releases sharing a name get a ` {<shorthash>}` suffix in
  zurg. Check for duplicates in `releases.tsv` (`cut -f2 releases.tsv | sort |
  uniq -d`) — a duplicate means one of the two folders will not have the name
  you predicted. InfiniDysk had the same problem differently: re-importing the
  same NZB there created `<Release> (2)`.
- The NZB's `<meta type="name">` is only consulted when the filename looks
  like a hash (`releaseName`, `internal/nzb/provider.go`). A real filename
  always wins, so your renamed files control the outcome.

---

## 3. Build the zurg side in parallel

InfiniDysk keeps serving throughout. Nothing here touches Plex.

```yaml
# zurg config.yml — minimal for this migration
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
enable_repair: true
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l          # should approach the release count
```

`__all__` holds every release regardless of directory filters, so it is the
stable prefix to point symlinks at — no filter tuning can move a release out
of it. (See `docs/usenet.md` for the full backend guide.)

Now diff the trees. This is the step that catches every surprise before Plex
can see one:

```bash
find "$IDMOUNT/content" -mindepth 2 -type f -printf '%P\t%s\n' | sed 's|^[^/]*/||' | sort > infinidysk-files.tsv
find /mnt/zurg/__all__ -type f -printf '%P\t%s\n' | sort > zurg-files.tsv
diff <(cut -f1 infinidysk-files.tsv) <(cut -f1 zurg-files.tsv)
```

Expected, benign differences (all measured):

- **`.par2` and `.sfv` files present on InfiniDysk, absent on zurg.** zurg
  hides repair scaffolding; it still reads it itself. InfiniDysk additionally
  leaves *hash-named* par2 volumes visible inside obfuscated releases (five of
  them, 4 KB–134 MB, in the measured `Obfuscated` release). Those files
  vanish from the mount. They carry no media extension, so a Plex section
  will not normally have itemised them — but check nothing in your library
  references one before shrugging: `grep -F` the names against your symlink
  targets or the file inventory. Any item Plex did have for one is a deletion
  Plex will see.
- **Releases zurg has that InfiniDysk refused** — the `430 No such article`
  class. These import into Plex as *new* items; there is no watch state to
  preserve on content InfiniDysk never served.
- **A broken-RAR-chain release** (`.r00`–`.r27` absent from the NZB itself)
  appears on zurg as an empty archive folder; InfiniDysk created nothing.
  Harmless to Plex either way.
- **Fully obfuscated single-payload releases**: where the PAR2 index restores
  names that are themselves random, zurg renames the clear payload to the
  release name (SABnzbd's behaviour); InfiniDysk shows the hash name. A
  different filename is a different path — for Setup A it just changes the
  retarget destination; for Setup B it is a rename Plex will see on that file.
  In the measured corpus the real names were recoverable and both servers
  showed identical filenames, so this bites only truly nameless posts.

And one difference that is a zurg defect, not benign: **file sizes**.
InfiniDysk reports exact sizes for everything it serves. zurg reports the
exact size only when the poster wrote a byte count into the subject line;
otherwise it advertises the yEnc-*encoded* length — measured at **+2.50% to
+3.18%** over the true size on three of five test files, and reading the file
does not correct it. A changed size makes the file look *modified* to Plex.
That does not delete the item or touch watch state, but it can trigger
re-analysis and preview-thumbnail/intro-marker regeneration across every
affected file. Budget for that I/O after cutover, and turn off "Generate
video preview thumbnails" on these libraries first — on Usenet every
thumbnail pass is a full read of the release through your connection
allowance.

Do not proceed to cutover until the diff contains nothing you cannot explain
from the list above.

---

## 4. Cutover, Setup A: retarget the symlinks

Both servers are serving. Every symlink is valid before its rewrite and valid
after it, so Plex never sees a missing file at any instant. Run it with
scanning disabled anyway (section 1).

**Build the uuid → release/file map.** Under `--links`, each entry in
`completed-symlinks` appears as a real symlink whose target is the `.ids`
path, and whose own path names the release and file. The `.ids` leaf and
`/content/<category>/<release>/<file>` serve the same object — verified:
identical Content-Length, identical content type.

```bash
IDMOUNT=/mnt/remote/nzbdav
ZURG=/mnt/zurg
LIB=/media                      # the *arr library Plex scans

find "$IDMOUNT/completed-symlinks" -type l | while IFS= read -r l; do
  uuid=$(basename "$(readlink "$l")")
  rel="${l#"$IDMOUNT/completed-symlinks/"}"   # <category>/<release>/<file>
  rel="${rel#*/}"                             # <release>/<file>
  printf '%s\t%s\n' "$uuid" "$rel"
done | sort -u > uuid-map.tsv
```

**Rewrite each library symlink atomically** — create the new link beside the
old and `mv -f` over it, one rename syscall, never a moment with no link.
Save the old target first so rollback is mechanical, and never switch to a
path that does not exist:

```bash
: > retarget-undo.tsv; : > unmapped.txt; : > missing.txt
find "$LIB" -type l -lname '*/.ids/*' -print0 | while IFS= read -r -d '' link; do
  old=$(readlink "$link"); uuid=$(basename "$old")
  rel=$(awk -F'\t' -v u="$uuid" '$1==u{print $2; exit}' uuid-map.tsv)
  [ -n "$rel" ] || { printf '%s\t%s\n' "$link" "$old" >> unmapped.txt; continue; }
  new="$ZURG/__all__/$rel"
  [ -e "$new" ] || { printf '%s\t%s\n' "$link" "$new" >> missing.txt; continue; }
  printf '%s\t%s\t%s\n' "$link" "$old" "$new" >> retarget-undo.tsv
  ln -s "$new" "$link.zurgtmp" && mv -Tf "$link.zurgtmp" "$link"
done
wc -l retarget-undo.tsv unmapped.txt missing.txt
```

`mv -T` (GNU coreutils) is deliberate: it forces the destination to be treated
as a plain path rather than descended into. Without `-T` this works only
because every target here is a file — the day one points at a directory,
plain `mv -f` would move the new link *inside* it instead of replacing it.
`-lname` is GNU `find` for the same reason; on macOS install coreutils and
findutils, or run this step on the Linux host.

`unmapped.txt` holds symlinks whose uuid appears in no `completed-symlinks`
entry (measured entries are flat `<release>/<file>`; whether releases with
inner RAR directory structure symlink every nested file is **unverified**).
Resolve those by size: `stat -c %s` the old target through the mount, then
find the file of that exact size under `$IDMOUNT/content` — sizes there are
exact — and map its `<release>/<relative path>` to `$ZURG/__all__/` by name.
`missing.txt` holds files zurg does not serve; each needs an explanation from
the section 3 diff before you continue.

**Prove there are no broken links**, then and only then stop InfiniDysk:

```bash
find "$LIB" -xtype l          # must print nothing
# pre-flight from section 1 (sessions size="0", refreshing count 0), then:
systemctl stop infinidysk-rclone-mount infinidysk    # whatever your units are
```

Do **not** unmount InfiniDysk before the `find -xtype l` is clean — every
line it prints is a file Plex will treat as deleted on its next scan.

---

## 5. Cutover, Setup B: Plex pointed straight at `/content`

The old paths are `<mount>/content/<category>/<release>/<file>`. Three ways
to keep them resolving; pick (a) unless it cannot apply.

**(a) A symlink shim tree over zurg's mount — recommended.** Rebuild the old
path shape as one real directory of per-release symlinks into
`$ZURG/__all__`. File names inside each release match (section 3 verified
exactly this), so a release-level link is enough:

```bash
STAGE=/srv/nzbdav-shim
while IFS=$'\t' read -r cat rel; do
  mkdir -p "$STAGE/content/$cat"
  ln -s "$ZURG/__all__/$rel" "$STAGE/content/$cat/$rel"
done < releases.tsv
```

Cutover: pre-flight (section 1), stop InfiniDysk and its rclone mount, then
put the shim where the mount was — `$IDMOUNT` is an empty real directory once
unmounted:

```bash
mv "$STAGE/content" "$IDMOUNT/content"
```

The exposure window is the seconds between unmount and `mv`, covered by
disabled scans and `autoEmptyTrash=0`. Plex's paths are untouched; the hidden
par2/sfv files simply stop existing inside folders Plex never itemised them
from, and the size-defect re-analysis from section 3 still applies.

**(b) zurg `directories:` shaped like the categories.** Mount zurg at
`$IDMOUNT/content` and define `directories: movies: / tv:` with filters
(`has_episodes`, name regexes) so releases land under the old category names.
Honest assessment: zurg sorts by its own filters, not by the SAB category the
release was queued under, and the two will not agree on everything — every
release a filter files differently than its old category is a moved path,
which is a deletion plus an addition. zurg's extra roots (`__all__`,
`__nzb__`, `version.txt`) also appear under `content/`, harmless only because
Plex scans its section folders, not the parent. Use this only for a small,
regular library where you can verify every release's landing directory
against `releases.tsv` before cutover.

**(c) Rewriting `media_parts.file` in `com.plexapp.plugins.library.db`.**
Stop Plex, work on a copy of your backup, and rewrite the path prefixes.

**Write with the SQLite binary Plex ships, not the system one.** The schema
carries custom extensions — a stock `sqlite3` walking this database fails with
`no such module: spellfix1` (observed on a 10,126-item library). Reading a copy
with stock `sqlite3` is fine; writing the live database with it is not.

```bash
PSQL="/usr/lib/plexmediaserver/Plex SQLite"    # path varies by platform
DB="…/Plug-in Support/Databases/com.plexapp.plugins.library.db"

"$PSQL" "$DB" "UPDATE media_parts SET file = replace(file, '/mnt/remote/nzbdav/content/movies/', '/mnt/zurg/movies/');"
"$PSQL" "$DB" "UPDATE section_locations SET root_path = '/mnt/zurg/movies' WHERE root_path = '/mnt/remote/nzbdav/content/movies';"
```

`section_locations` holds one row per library root and must move with the
parts, or Plex treats every rewritten path as outside the library. Verify
before restarting:

```bash
"$PSQL" "$DB" "SELECT id, library_section_id, root_path FROM section_locations;"
"$PSQL" "$DB" "SELECT count(*) FROM media_parts WHERE file LIKE '/mnt/remote/nzbdav/%';"   # want 0
```

Plex also keeps a `directories` table of scanned folder rows. Whether it needs
the same rewrite, or is rebuilt on the next scan, was **not verified** — check
it with `.schema directories` and inspect before assuming either way.

This keeps items, state and artwork because the rows never die — but it is
unsupported surgery on an undocumented schema that shifts between Plex
versions, per-file paths must land exactly (including every rename from
section 3's caveat list), and a half-applied rewrite is worse than either
failure mode above. It is the fallback for when the old path prefix cannot be
reconstructed at all — e.g. the mount point is gone and cannot be recreated —
never the first choice. (`media_parts.file`, `media_parts.size` and
`section_locations.root_path` were read off a live Plex database for this
guide; anything beyond them, inspect with `.schema` against your own version
before touching it.)

---

## 6. Verification

With the cutover done and InfiniDysk stopped:

```bash
# 1. No broken symlinks anywhere Plex looks
find "$LIB" -xtype l | wc -l                        # Setup A — want 0
find "$IDMOUNT/content" -xtype l | wc -l            # Setup B shim — want 0

# 2. Bytes actually flow through zurg
head -c 1048576 "$(find "$LIB" -type l | head -1)" > /dev/null && echo OK
```

Re-enable the scanning options from section 1, trigger a scan of one section,
and compare against the counts recorded in pre-flight. Then check state
survived: pick a watched item, confirm its watch state, play count and any
custom poster are intact, and check the section's trash is not suddenly
populated (Plex Web → library → three-dot menu). Files whose advertised size
grew (the +2.5–3.2% class) will show as changed and re-analyse; that is
expected and does not touch watch state.

Only after a full scan completes clean on every section, tear down
InfiniDysk's data — and even then keep `{CONFIG_PATH}/blobs/` and your
recovered NZB set until you have streamed from a representative sample.

---

## 7. Rollback

Everything before cutover is additive, so rollback is only meaningful after
section 4 or 5:

- **Setup A:** replay `retarget-undo.tsv` in reverse — the same atomic
  create-and-rename with `$old` as the target — after restarting InfiniDysk
  and its mount:

  ```bash
  while IFS=$'\t' read -r link old new; do
    ln -s "$old" "$link.zurgtmp" && mv -f "$link.zurgtmp" "$link"
  done < retarget-undo.tsv
  ```

- **Setup B (a/b):** remove the shim (`rm -rf "$IDMOUNT/content"` — it is
  symlinks, not data) or unmount zurg, and remount InfiniDysk at the old
  path.
- **Setup B (c), or any case where items were actually deleted:** stop Plex
  and restore the database backup from section 1. That is what it is for.

If Plex saw files vanish but `autoEmptyTrash` was 0, nothing is lost yet: the
items are in the trash and return when the paths do. Do not empty the trash
while anything is unresolved.
