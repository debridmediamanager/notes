---
label: From decypharr
icon: arrow-right
order: 80
---

# Migrating from decypharr v2.5 to zurg

decypharr and zurg solve the same problem — debrid accounts and Usenet posts
presented as a mounted library — and their trees are close enough that a
migration can preserve a Plex library intact. Close is not identical, and Plex
is unforgiving about the difference: every library item is bound to a file
path in `media_parts.file`, so a changed path is not a rename to Plex, it is a
deleted item plus a new one.

Be precise about what that costs, because it decides how much of this guide is
worth the effort. Read out of a live 10,126-item library: watch state is keyed
by `account_id` plus a `plex://` GUID in `metadata_item_settings`, not by the
item id or the path, so watched flags, play counts, resume offsets and user
ratings **re-attach** when the new file matches to the same GUID. What dies
with the item is everything on the `metadata_items` row — collections
membership, playlists (they store item ids), artwork and match choices, and
`added_at`, which dumps the whole library into Recently Added. Deletion is soft
(`deleted_at` on `media_parts`/`media_items`); emptying the trash is what makes
it permanent.

The rule the whole guide is built around: **the paths Plex has on file must
never change, and the mount behind them must never read as empty while Plex
can scan.** Layouts cited here were measured live on 2026-08-19 (decypharr
v2.5, zurg HEAD `23869fa4`, same seven NZBs into each, trees read off live
mounts); anything not measured or read from source is marked unverified.

---

## 0. Decide which setup you have

Two questions determine the whole shape of the migration. **Where does Plex
point?**

- **Setup A — Plex points at an *arr-managed library.** The *arrs imported
  from decypharr's symlink farm (`download_folder/<category>/<job>/<file>`,
  each a symlink to `<mount>/__all__/<job>/<file>`), so your library is
  symlinks. Plex only ever sees the symlink paths. **This is the good case**:
  those paths never change, and the migration is repointing symlink targets.
  Follow sections 1–7.
- **Setup B — Plex points straight at the DFS/WebDAV mount.** Every naming
  difference between the two servers is Plex-visible. Follow sections 1–5,
  then section 8.

**Which providers do you use?** zurg speaks `realdebrid`, `alldebrid`,
`torbox` and `nzb`. decypharr additionally supports Debrid-Link and
Premiumize; zurg has no backend for either, so content held only on those
accounts **cannot be served by zurg**. Re-acquire it on a supported account
before the cutover or accept losing those items.

---

## 1. What maps to what

### Mount layout

decypharr's root and zurg's are strikingly close:

| decypharr | zurg | Notes |
|---|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` | Same name, same role. The lever this migration rests on. |
| `version.txt` | `version.txt` | Both at the root; health checks keep working. |
| `__bad__/` | `__unplayable__/` | Analogous, different name. |
| `torrents/` | `directories:` entry with `not_provider: nzb` | Reproducible by filter. |
| `nzbs/<job>/` | `directories:` entry with `provider: nzb` (or built-in `__nzb__`) | Reproducible by filter. |
| `<provider>/` (e.g. `realdebrid/`) | built-in `__<name>__` or a `directories:` entry with `provider: <name>` | Bare name reproducible by filter. |
| virtual folders | `directories:` filters | Name/file-name/size/date/provider conditions all have zurg equivalents (`regex`, `any_file_inside_regex`, `size_gte`, `added_within_days`, `provider`). decypharr's "number of files", "source type" and "category" conditions have no zurg counterpart. |

So zurg can reproduce every decypharr top-level directory name — which
matters enormously for Setup B and not at all for Setup A (symlink targets
all go through `__all__`).

### Folder (job) naming

Both servers name an NZB release's folder **after the `.nzb` filename** —
measured across five servers, it is the one universal rule. So NZB folder
names are under your control: name the file, name the folder.

For debrid torrents, decypharr's `folder_naming` setting
(`filename | original | filename_no_ext | original_no_ext | infohash`) chose
your folder names. zurg's knobs are `retain_rd_torrent_name` and
`retain_folder_name_extension`; with both false (the default) the folder is
the torrent's original name with a trailing `.mkv`/`.mp4` stripped
(`GetKey_Original`, `internal/torrent/key.go:14`) — i.e. `original_no_ext`.
`retain_folder_name_extension: true` keeps the extension. `infohash` has no
zurg equivalent, and decypharr's `filename` variants were not measured —
**verify against your own tree** in section 4 rather than trusting a table.

**Do not change decypharr's `folder_naming` before migrating.** Changing it
renames every folder in the library at once — every symlink target and every
mount-direct Plex path breaks in one stroke.

Two zurg-side naming hazards:

- With defaults, zurg strips a trailing `.mkv`/`.mp4` from a folder name. If
  your decypharr folders end in an extension, set
  `retain_folder_name_extension: true` or every such folder shifts.
- Two *different* releases sharing a name collide, and zurg hash-suffixes one:
  `Some.Release {a1b2c3}`. An RD torrent and an NZB of the same release **are**
  different releases to zurg (the NZB's id is a hash of its filename, not an
  infohash), so holding both under one name gets one suffixed — and a suffixed
  path breaks whatever pointed at the bare one. Only re-fetch NZBs for
  releases no debrid account already holds (section 5).

### The three hard mismatches (NZB side, measured)

These cannot be fixed by renaming the `.nzb` — the filename controls only the
folder, never the files inside:

1. **Lone video renamed by decypharr.** A single video becomes the job name
   (`TLOU-S02E01-FLUX/TLOU-S02E01-FLUX.mkv`); zurg keeps the poster's
   filename (`.../The.Last.of.Us.S02E01.Future.Days.…-FLUX.mkv`).
2. **RAR releases flattened by decypharr.** The archive collapses to one file
   named by concatenating the inner directory and filename with no separator
   (`FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4`);
   zurg reproduces the archive's inner directory, `Sample/` included
   (`FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`).
3. **Sidecars.** decypharr drops `thumbnail.jpg` and `.url` files; zurg keeps
   them.

Season packs and any multi-file release keep their real filenames on both
sides — those match automatically once the folder name matches. The
debrid-torrent side has none of these problems: both servers list the same
account and present the torrent's own filenames. Its migration is
configuration, not content.

### Two deltas where zurg gains

Measured: decypharr produced **nothing at all** for a fully obfuscated NZB or
a broken RAR chain. zurg serves the obfuscated one (payload presented under
the release name) and leaves an empty folder for the broken chain — new Plex
additions plus a little folder noise, both harmless.

### The zurg file-size defect

On NZBs whose subject line carries no byte count, zurg over-reports file
sizes by 2.5–3.2% (it falls back to the yEnc-encoded segment sum; decypharr
reports exact sizes). A changed size makes Plex treat the file as modified:
the item is **not** deleted and keeps its state, but Plex re-analyzes it and
regenerates preview thumbnails/intro markers — real bandwidth on a streaming
mount. Turn off "Generate video preview thumbnails" before the cutover.

---

## 2. Pre-flight

**Back up the Plex database.** Stop Plex first — a copy of a live SQLite
file can be torn:

```bash
PLEX_DB="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
sudo systemctl stop plexmediaserver
cp "$PLEX_DB" ~/plexlib.backup.$(date +%Y%m%d).db
sudo systemctl start plexmediaserver
```

**Confirm auto-empty-trash is off.** This is the guard that turns "the mount
blipped during a scan" from a permanent mass deletion into a recoverable
trash state. It has cost a 30,065-item library before:

```bash
TOKEN=YOUR_PLEX_TOKEN
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
```

`autoEmptyTrash` must be `0`. Also uncheck "Empty trash automatically after
every scan" per library (Edit → Advanced), and "Generate video preview
thumbnails".

**Disable scans for the duration.** Settings → Library: turn off "Update my
library automatically", "Run a partial scan when changes are detected", and
the scheduled library update. Re-enable in section 9. **Quiesce the *arrs**:
pause the Sonarr/Radarr queues and disable RSS sync.

**Learn the scan pre-flight.** Before any action that takes the mount away —
stopping decypharr, restarting zurg, remounting — both of these must be zero:

```bash
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Sessions only prove nobody is watching; a **scan** in flight is what does
damage. Use `grep -o … | wc -l`, never `grep -c`: grep exits non-zero when it
finds nothing — the good case here — and that aborts a `&&` chain or a
`set -e` script right before the restart it was guarding.

---

## 3. Inventory

Capture everything while decypharr still serves — the mapping table and the
rollback reference in one.

```bash
MOUNT=/mnt/decypharr            # decypharr's mount
FARM=/mnt/decypharr-downloads   # its download_folder (symlink farm)
LIB=/data/media                 # the *arr-managed library roots (Setup A)
mkdir -p ~/decypharr-migration && cd ~/decypharr-migration

find "$MOUNT/__all__" -type f -printf '%s %p\n' | sort -k2 > mount-files.txt
ls "$MOUNT/nzbs" > nzb-jobs.txt                 # the usenet job list
find "$FARM" -type l -printf '%p -> %l\n' > farm-links.txt
find "$LIB"  -type l -printf '%p -> %l\n' > lib-links.txt

# Every path Plex has an item bound to — query a COPY, never the live DB
cp "$PLEX_DB" ./plexlib.copy.db
sqlite3 ./plexlib.copy.db \
  "SELECT file FROM media_parts WHERE file != '' ORDER BY file;" > plex-paths.txt
```

`plex-paths.txt` is the contract: **the migration is done when every line in
it resolves to a readable file.** In Setup A those lines are symlink paths in
`$LIB`; in Setup B they are mount paths.

On the NZBs themselves: decypharr keeps `usenet/meta/<uuid>.meta` — a
compressed binary, one per job — and a `usenet/nzbs/` directory that was
**empty** on the bench. There is no documented export, and whether `.meta`
blobs can be decoded back into NZBs is unverified. Treat the original NZB
files as **not recoverable from decypharr**; the job folder name is the NZB
filename, so `nzb-jobs.txt` is exactly what to search your indexer for.

---

## 4. Build zurg in parallel

Run zurg beside decypharr — different mountpoint, no conflict; both may
list the same debrid accounts at once, listing is read-only.

```yaml
# config.yml — staging
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
retain_rd_torrent_name: false         # align with decypharr folder_naming
retain_folder_name_extension: false   # true if folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                # Setup B: reproduce decypharr's top-level names
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
  # one entry per virtual folder you had, translated to zurg filters
```

Start it, let it scan the accounts, and compare against the inventory:

```bash
find /mnt/zurg-staging/__all__ -type f -printf '%s %p\n' | sort -k2 > zurg-files.txt
# Folder-level diff: which jobs exist on each side?
sed 's|.*/__all__/\([^/]*\)/.*|\1|' mount-files.txt | sort -u > decypharr-jobs.txt
sed 's|.*/__all__/\([^/]*\)/.*|\1|' zurg-files.txt  | sort -u > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

The debrid-torrent folders should already line up; if they differ
systematically (extension present/absent, RD rename vs original), flip the
`retain_*` knobs and rescan before resorting to anything manual. Folders only
on the decypharr side are the usenet jobs — section 5 — plus anything on a
Debrid-Link/Premiumize account.

---

## 5. Recovering the NZB side

zurg's ingestion is a watch directory: `.nzb` files dropped directly into
`nzbs/` beside the binary (fixed name, subdirectories ignored, rescanned every
15 s). zurg does now have a [SABnzbd-compatible endpoint](../guides/sabnzbd.md) that
writes into that same directory, but it will not help here — recovering an
existing job means placing a file under an exact name, which is what the
watch directory does and what a re-grab through an \*arr does not. For each
job in `nzb-jobs.txt`:

1. **Skip it if a debrid account already holds the release** — the symlink
   resolves through the torrent copy, and adding the NZB too triggers the
   duplicate-name hash suffix (section 1).
2. Re-fetch the NZB from your indexer, searching by the job folder name.
3. **Rename the file to exactly the job folder name** plus `.nzb` — the
   filename is the folder name, which is what keeps the folder path
   identical: `cp indexer-download.nzb /path/to/zurg/nzbs/TLOU-S02E01-FLUX.nzb`
4. Watch the log for `Loaded NZB <name>: N files`, then check the resulting
   folder in `/mnt/zurg-staging/__all__/` against `mount-files.txt`.

A release your indexer no longer has is gone: no NZB, no zurg entry, a
dangling Plex item — leave it (with auto-empty off it survives until a scan
trashes it) or delete it deliberately after migration. Inner filenames will
differ for lone-video and RAR releases (section 1); that is what sections 7
and 8 are for. Some sizes will read 2.5–3.2% high.

---

## 6. Cutover (Setup A)

Stop Plex, swap the mountpoint from decypharr to zurg, fix the symlinks,
verify every Plex path resolves, start Plex. With Plex stopped, the "empty
mount during a scan" failure mode cannot occur — the cleanest guard.

```bash
# 1. Pre-flight: nothing playing, nothing scanning (section 2 commands), then:
sudo systemctl stop plexmediaserver
# 2. Stop decypharr and free its mountpoint (the *arrs stay paused).
sudo systemctl stop decypharr        # or: docker stop decypharr
mountpoint -q "$MOUNT" && sudo umount "$MOUNT"
# 3. Point zurg at the old mountpoint and restart it.
#    In config.yml: mount_path: "/mnt/decypharr"   (i.e. $MOUNT)
sudo systemctl restart zurg
# 4. Confirm the tree is up BEFORE anything else runs.
ls "$MOUNT/__all__" | head
cat "$MOUNT/version.txt"
```

Do not delete decypharr, its config, `db/` or `usenet/` state — that is the
rollback path (section 11).

---

## 7. Retarget dangling symlinks (Setup A)

Every library symlink whose target still exists under zurg's `__all__` —
debrid torrents, multi-file NZB releases — now just works. The dangling ones
are the decypharr-renamed lone videos and the flattened RARs. Repoint them:
the symlink's own path (what Plex has on file) never changes, so the item is
preserved.

```bash
#!/bin/bash
# retarget.sh — repoint dangling library symlinks at zurg's copy of the job.
# Writes an undo script; GNU find and bash (for printf %q) required.
MOUNT=/mnt/decypharr; LIB=/data/media; UNDO=./retarget-undo.sh
: > "$UNDO"
find "$LIB" -type l | while IFS= read -r link; do
  [ -e "$link" ] && continue                        # resolves — leave it alone
  old=$(readlink "$link")
  job=$(printf '%s\n' "$old" | sed -n "s|^$MOUNT/__all__/\([^/]*\)/.*|\1|p")
  [ -n "$job" ] || { echo "SKIP (target not under __all__): $link"; continue; }
  dir="$MOUNT/__all__/$job"
  [ -d "$dir" ] || { echo "NO JOB $job: $link"; continue; }
  # Largest non-sample video in the job, searched recursively (RARs nest).
  new=$(find "$dir" -type f \( -name '*.mkv' -o -name '*.mp4' -o -name '*.avi' \) \
        ! -ipath '*sample*' -printf '%s\t%p\n' | sort -rn | head -1 | cut -f2-)
  [ -n "$new" ] || { echo "NO VIDEO in $job: $link"; continue; }
  printf 'ln -sfn %q %q\n' "$old" "$link" >> "$UNDO"
  ln -sfn "$new" "$link"
  echo "RETARGETED: $link"
done
```

The largest-video heuristic is safe because multi-file releases already
resolved and were skipped — only single-payload jobs reach it. Anything still
dangling afterwards is a job zurg does not have (unrecoverable NZB,
unsupported provider): the accept-or-delete list.

---

## 8. Setup B: Plex pointed straight at the mount

Reproduce as much as possible by configuration first: zurg at decypharr's
exact mountpoint, `directories:` entries named `torrents`, `nzbs` and
per-provider (section 4), naming knobs aligned, NZBs renamed to the old
folder names (section 5). The debrid side and multi-file NZB releases then
carry identical Plex paths and nothing happens to them. The residue is the
lone-video and RAR jobs, whose inner filenames cannot be configured into
matching. Four options, in order of preference:

1. **Rewrite `media_parts.file` in the Plex DB** — the precise fix when the
   affected set is small. With Plex stopped and the section-2 backup taken:

   ```sql
   UPDATE media_parts
      SET file = '/mnt/decypharr/__all__/TLOU-S02E01-FLUX/The.Last.of.Us.S02E01.Future.Days.…-FLUX.mkv'
    WHERE file = '/mnt/decypharr/__all__/TLOU-S02E01-FLUX/TLOU-S02E01-FLUX.mkv';
   ```

   Use Plex's bundled "Plex SQLite" binary for writes, not stock `sqlite3` —
   the DB carries custom extensions and Plex's own tooling is the supported
   way to modify it. If you use external subtitle files, check
   `media_streams` for path references too. Generate the UPDATEs from
   `mount-files.txt` vs `zurg-files.txt` rather than typing them.
2. **A symlink shim tree** — when you refuse to touch the DB. Mount zurg
   somewhere new (`/mnt/zurg`) and build the old paths at the old mountpoint
   as a real directory tree of symlinks into it. Every old path resolves,
   renamed inner files included. The shim covers the frozen pre-migration
   set; add the zurg mount as an additional location on each library so new
   content scans in from the real mount. Cost: a shim carried forever.
3. **Rename the `.nzb`** — already done in section 5. It fixes folders (the
   whole fix for multi-file releases) but can never fix inner filenames, so
   it is a component of the other options, not an alternative.
4. **Accept the change** for items you do not care about. With auto-empty
   off, the old item sits in the trash (state intact) and a new item appears;
   item-bound state — collections, artwork choice, added date — is lost when
   the trash is finally emptied. Do not empty it until section 9 is clean.

---

## 9. Verification

With Plex still stopped:

```bash
cd ~/decypharr-migration
# The contract: every path Plex knows must resolve.
while IFS= read -r p; do [ -e "$p" ] || echo "MISSING: $p"; done < plex-paths.txt
```

Chase every line down to zero, or to an explicit accept-list of items you
have decided to lose. Then `sudo systemctl start plexmediaserver` and:

- Scan **one** small library first. Check its item count against
  pre-migration and that nothing landed in the trash; spot-check watch state
  and a collection.
- Play one debrid item and one NZB item end to end, including a seek.
- Analysis activity on NZB files whose size shifted (section 1) is
  re-analysis of a surviving item, not a re-add.
- Only when every library scans clean: re-enable automatic/scheduled scans
  and the *arr queues, and empty the trash if anything deliberately dropped
  sits in it.

---

## 10. What changes after migration

**Automation.** Half of it carries over. zurg has a
[SABnzbd-compatible endpoint](../guides/sabnzbd.md) — opt-in, Usenet-only — so Sonarr
and Radarr can hand it an NZB and import from `__magic__` by rename. It has no
qBittorrent API, so the torrent half of decypharr's ingestion has no
equivalent, and the NZB half is not a like-for-like replacement either: zurg
does not yet check whether a post's articles are still on the news server, so
a dead release reports Completed and fails on the first read rather than being
blocklisted and re-grabbed. Options:

- NZBs: turn on `sabnzbd.enabled` and point the \*arrs at zurg — see
  [sabnzbd.md](../guides/sabnzbd.md) — or fetch from the indexer yourself and drop into
  `nzbs/`.
- Torrents: the zurg dashboard, DMM, or zurg's Plex watchlist acquisition
  (`plex_watchlist_enabled`, needs `dmm_api_key`). Nothing in the \*arr
  ecosystem can hand zurg a torrent.
- Hybrid: keep decypharr purely as the *arrs' download client pushing into
  the same debrid accounts, with zurg serving the mount — both list the same
  account, so zurg picks up what decypharr adds. The *arr import step then
  needs remote path mapping onto zurg's tree; unverified here, test one grab
  first. If you script against decypharr: the SABnzbd endpoint is
  `/sabnzbd/api?mode=addfile` with the multipart field named `name`;
  `/api?mode=addfile` returns 404 on v2.5.

**Mount deltas:** sidecars (`thumbnail.jpg`, `.url`) and RAR-inner `Sample/`
directories are now visible — `only_show_the_biggest_file: true` on movie
directories hides them from a mount-direct library. Obfuscated releases
decypharr dropped now appear; broken-chain RARs appear as empty folders; NZB
sizes may read 2.5–3.2% high until the defect is fixed.

---

## 11. Rollback

Everything decypharr needs was left in place (section 6), so rollback is
the cutover in reverse:

```bash
# Plex pre-flight first (section 2), or stop Plex outright.
sudo systemctl stop plexmediaserver
sudo systemctl stop zurg                      # frees the mountpoint
sudo systemctl start decypharr                # remounts at $MOUNT
bash ~/decypharr-migration/retarget-undo.sh   # Setup A: restore symlink targets
# Setup B, if you rewrote the DB: restore the backup.
# cp ~/plexlib.backup.YYYYMMDD.db "$PLEX_DB"
sudo systemctl start plexmediaserver
```

Verify with the same section-9 loop over `plex-paths.txt` before letting Plex
scan. The NZBs you re-fetched into zurg's `nzbs/` are unaffected by rollback
and keep their value for the next attempt.
