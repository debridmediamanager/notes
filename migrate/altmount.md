---
label: From AltMount
icon: arrow-right
order: 90
---

# Migrating from AltMount v0.3.2 to zurg

For a library Plex reads off the AltMount mount (or off an *arr symlink library
that AltMount feeds). The requirement this guide is built around: **Plex must
not rescan from scratch, must not delete a single library item, and must keep
watch state, play counts, collections, ratings and artwork choices.**

Path and size behaviour below was measured live on 2026-08-19 (AltMount
v0.3.2, zurg HEAD `23869fa4`) by importing the same NZBs into both and reading
the trees back off FUSE mounts. Anything not measured is marked unverified.

---

## 1. Why this is delicate at all

Plex binds every library item to a file path: `media_parts.file` in
`com.plexapp.plugins.library.db`. When a scan finds that path gone, the item
goes to the trash; with "Empty trash automatically after every scan" enabled it
is deleted permanently, at once. A file that reappears under a *different*
path is a **new** item — Plex does not track moves.

What survives a delete-and-re-add and what does not, read out of a live
10,126-item library rather than assumed. Watch state is keyed by account and
metadata GUID, not by the item id or the path:

```sql
metadata_item_settings(id, account_id, guid, rating, view_offset,
                       view_count, last_viewed_at, …)
-- ('plex://movie/5d776d1796b655001fe3f5d3', 1, NULL, 1707662516)
```

So watched flags, play counts, resume offsets and user ratings come back once
the re-added item matches to the same GUID; `metadata_item_views` is GUID-keyed
too. Collections membership, playlists (they store metadata item ids), selected
posters and artwork, manual match fixes and `added_at` all live on the
`metadata_items` row and are **lost** with the item — which also means a mass
re-add dumps your entire library into Recently Added.

Deletion itself is soft: `deleted_at` on `media_parts` and `media_items`. That
is what the trash holds and what "Empty trash automatically after every scan"
makes permanent.

So the spine of this migration is: **make zurg serve byte-identical paths at
the same mountpoint**, and handle the minority of files where that is
impossible by editing `media_parts.file` — never by letting Plex see a
delete-and-re-add.

The second mechanism is size: a part whose advertised size changes looks
*modified* and can trigger re-analysis — not deletion. zurg has a known defect
here, see section 9.

---

## 2. What matches and what cannot

Both servers name the release folder after the NZB filename, so **folder names
are fully under your control** — recover the NZBs under the names AltMount
used (section 5) and every folder matches. The inner filenames are where the
two disagree, and no `.nzb` rename can fix those: the `.nzb` name only
controls the folder.

Measured, release by release:

| Release shape | AltMount serves | zurg serves | Match? |
|---|---|---|---|
| Single video, inner name == NZB name (`The.Wild.Robot…-TiGER`) | `<R>/<R>.mkv` | `<R>/<R>.mkv` + `thumbnail.jpg` | **Yes** |
| Season pack, multiple videos (`Servant.S01…`) | real filenames | real filenames | **Yes** |
| Obfuscated post, real name recoverable (`Obfuscated`) | `Obfuscated/Toy.Story.5.…-KyoGo.mkv` | same, + `thumbnail.jpg` | **Yes** |
| Single video, inner name != NZB name (`TLOU-S02E01-FLUX`) | `<R>/<R>.mkv` — **renamed to the NZB name** | `<R>/The.Last.of.Us.S02E01.…-FLUX.mkv` — poster's name kept | **No** |
| Same, anime (`OnePiece-1174`) | `OnePiece-1174/OnePiece-1174.mkv` | `OnePiece-1174/[SubsPlease] One Piece - 1174 (1080p) [B4711849].mkv` | **No** |
| RAR release (`FatherBrown`) | `FatherBrown/FatherBrown.mp4` — flattened and renamed | `FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown….mp4` + `Sample/` + the poster's `.url` junk | **No** |
| Broken RAR chain (`DoomsdayRar`) | empty folder | empty folder | No item on either side |

AltMount's rename rule: when a release resolves to exactly one content file,
the video is renamed to the NZB name. zurg keeps the poster's inner filenames
and reproduces a RAR archive's inner directory (including `Sample/`). So the
mismatch classes are **single-file releases whose inner filename differs from
the NZB name**, and **all RAR releases** (different basename *and* an extra
directory level). Everything else matches byte-for-byte.

Two smaller hazards: two *different* releases sharing a name get a
` {shorthash}` suffix in zurg (`internal/torrent/key.go`) — keep recovered NZB
filenames unique. And zurg strips a trailing `.mkv`/`.mp4` from the folder
name by default — if any AltMount folder literally ends in one, set
`retain_folder_name_extension: true`.

---

## 3. First, find out which case you are in

Read the truth out of Plex, not out of memory. Copy the DB and query the copy
— stock sqlite3 is fine read-only on a copy, never for writing:

```bash
PLEXDIR="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server"
cp "$PLEXDIR/Plug-in Support/Databases/com.plexapp.plugins.library.db" /tmp/plex-copy.db
sqlite3 /tmp/plex-copy.db "SELECT file FROM media_parts WHERE file != '';" > plex-paths.txt
wc -l plex-paths.txt
head plex-paths.txt
```

Paths **into the AltMount mount** (import_strategy `NONE`): the full runbook
below applies. Paths into an ***arr library of symlinks** (`SYMLINK`): the
easy case — read the pre-flight (section 4), then go to section 10. Paths to
`.strm` files (`STRM`): unusual with Plex; section 10 as well.

```bash
OLDMOUNT=/mnt/altmount        # the prefix your plex-paths.txt shows
```

---

## 4. Pre-flight — do all of this before touching anything

```bash
TOKEN=YOUR_PLEX_TOKEN   # later: $(grep ^plex_token: ~/zurg/config.yml | awk '{print $2}')
```

1. **Turn off automatic trash emptying.** This is the single setting that
   turns a mount blip into permanent deletions. Per library: Edit → Advanced →
   uncheck "Empty trash automatically after every scan". Verify:

   ```bash
   curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
   ```

   It must read `0`: at `0`, missing files sit in the trash and come back when
   the mount does. This exact failure at `1` once removed a 30,065-item
   library.

2. **Disable periodic scans for the duration** (Settings → Library → "Scan my
   library periodically" off), so nothing scans while you cut over.

3. **Back up the Plex database** — copy the whole `Plug-in Support/Databases/`
   directory with Plex stopped, or Settings → Manage → Troubleshooting →
   "Download database". Keep `plex-paths.txt` from section 3 too.

4. **Learn the restart guard.** Before stopping Plex, restarting zurg or
   remounting anything, check that nothing is playing *and nothing is
   scanning* — sessions alone prove only that nobody is watching:

   ```bash
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
   ```

   Use `grep -o … | wc -l`, not `grep -c`: grep exits 1 when it finds nothing,
   which is the *good* case here, and that aborts a `&&` chain or a `set -e`
   script right before the operation it was guarding.

5. **Do not decommission AltMount.** Its config directory (`altmount.db`,
   `.nzbs/`, `metadata/`) is your rollback; leave it untouched until
   section 12's verification passes.

---

## 5. Get the NZBs back

AltMount took ownership of every NZB you fed it: the original file was moved
away and a compressed copy kept at
`<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. The mapping from mount
folder to `.nzbz` lives in the `.meta` files under
`<config>/metadata/complete/<Release>/` — binary, magic `AM3`, with the
`.nzbz` path in there as a plain string.

zurg needs one `.nzb` per release, named after the release, flat in `nzbs/`
(subdirectories are skipped — flatten, do not keep AltMount's categories).
The `metadata/complete/<Release>` directory name *is* the mount folder name,
which is exactly the name the file should get:

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  if [ -e "$OUT/$release.nzb" ]; then echo "NAME COLLISION: $release" >&2; continue; fi
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release — use the API export below" >&2
  fi
done
```

On the measured v0.3.2 install the `.nzbz` decompressed as a gzip copy of the
imported NZB. The v0.3.2 source also carries a zstd-protobuf store path for
these files, so the `zcat`-plus-`grep` check above is not paranoia: any file
it rejects goes through the API instead.

**The API route** (verified in v0.3.2 source): `GET
/api/files/export-nzb?path=<virtual path>` regenerates a faithful NZB from the
store — all original files, segments, posters, dates, with the archive
password meta re-attached. There is also a batch form, `POST
/api/files/export-batch`, which returns a ZIP. Both need a JWT, not the API
key:

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

The exact virtual-path format was not verified — take paths from the AltMount
UI's file view or `/api/files/info` rather than guessing. The download is
named `<queueID>-<name>.nzb`; rename it to `<Release>.nzb` so zurg names the
folder correctly.

Sanity check: recovered `.nzb` count should equal the `metadata/complete/*/`
directory count, minus failed imports (a broken-RAR release AltMount refused
has no Plex item to preserve anyway).

---

## 6. Build the zurg side in parallel

AltMount keeps serving Plex throughout this section. Run zurg on the same
host (port 9999, no clash with AltMount's 8585) or anywhere else.

`config.yml`, minimum:

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com      # copy host/port/TLS/credentials from
      port: 563                   # AltMount's provider config
      tls: true
      username: …
      password: …
      connections: 30             # your plan's real allowance
rclone_enabled: false             # manual mount below; enable later if you prefer
mount_path: "/mnt/altmount"       # the OLD mountpoint — scan paths are built from this
serve_strm_files: false
```

Drop the recovered NZBs in and let zurg scan (the watch directory is rescanned
every ~15 s; obfuscated-name recovery is bounded at 90 s per NZB):

```bash
mkdir -p nzbs && cp -n recovered-nzbs/*.nzb nzbs/
./zurg
```

**The layout problem:** zurg's mount root is not flat — it has `__all__`,
`__nzb__`, your `directories:` entries and `version.txt`. AltMount served
`<mount>/<Release>/<file>` with nothing in between. To reproduce that, mount a
*subdirectory* of the zurg WebDAV with your own rclone rather than letting
zurg mount the root:

```ini
# rclone.conf
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

```bash
mkdir -p /mnt/zurg-staging
rclone mount zurg:__all__ /mnt/zurg-staging --config rclone.conf --dir-cache-time 10s &
# __nzb__ works too and pins reads to the Usenet account; __all__ is right
# when the NZB backend is your only provider.
```

Trade-off, flagged now: zurg builds its Plex partial-scan paths as
`mount_path/<directory>/<release>`, so with a subdirectory mounted at the old
mountpoint those computed paths do not exist and zurg's path-targeted
refreshes will not line up with your library. Harmless in itself, but partial
scans then need either an `on_library_update` script that rewrites the path
(adapt `plex_update.sh` — unverified, watch the first scan fire) or Plex's own
periodic scan re-enabled after migration, with the trash guard from section 4
permanently off.

---

## 7. Diff the staged tree against what Plex holds

This is the safety net that catches everything — rename quirks, sanitised
characters, failed imports — not just the two known mismatch classes:

```bash
: > mismatched.txt
while IFS= read -r p; do
  rel=${p#"$OLDMOUNT"/}
  [ -e "/mnt/zurg-staging/$rel" ] || echo "$p" >> mismatched.txt
done < plex-paths.txt
wc -l mismatched.txt
```

Every line in `mismatched.txt` is a Plex item whose path zurg will not serve.
Expect the single-file-renamed and RAR classes from section 2. For each, find
what zurg calls it — usually the only video in the same release folder:

```bash
while IFS= read -r p; do
  rel=${p#"$OLDMOUNT"/}; release=${rel%%/*}
  echo "== $p"
  find "/mnt/zurg-staging/$release" -type f \
       \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) \
       ! -ipath '*sample*'
done < mismatched.txt > mapping-review.txt
```

Review `mapping-review.txt` by hand; a release folder with several candidate
videos needs a human decision, not a script.

---

## 8. Cutover — Plex must never see an empty mount

The one unrecoverable mistake is letting a scan run against a missing or
empty mountpoint; the clean way out is to not let Plex run during the swap:

```bash
# 1. Guard: nothing playing, nothing scanning (section 4, both must be zero).
# 2. Stop Plex entirely.
sudo systemctl stop plexmediaserver

# 3. Swap the mountpoint.
fusermount -u /mnt/zurg-staging            # or umount on macOS
sudo systemctl stop altmount               # however AltMount is run
fusermount -u "$OLDMOUNT" 2>/dev/null || umount "$OLDMOUNT"
rclone mount zurg:__all__ "$OLDMOUNT" --config rclone.conf --dir-cache-time 10s &

# 4. Prove the paths are there BEFORE Plex comes back — zero misses required,
#    apart from the mismatched.txt lines you are about to fix:
missing=0
while IFS= read -r p; do
  [ -e "$p" ] || grep -qxF "$p" mismatched.txt || { echo "MISSING: $p"; missing=1; }
done < plex-paths.txt
echo "missing=$missing"
```

### Fix the mismatched minority in the Plex DB (Plex still stopped)

This is the primary route for the files zurg cannot serve under the old name:
repoint `media_parts.file` so Plex never perceives a change of identity. Use
the `Plex SQLite` binary Plex ships — the DB uses custom collations that stock
sqlite3 does not have:

```bash
PLEXDB="$PLEXDIR/Plug-in Support/Databases/com.plexapp.plugins.library.db"
cp "$PLEXDB" "$PLEXDB.bak-migration"
PSQL="/usr/lib/plexmediaserver/Plex SQLite"     # path varies by platform

# From your reviewed mapping, one UPDATE per file:
"$PSQL" "$PLEXDB" "UPDATE media_parts
  SET file='/mnt/altmount/TLOU-S02E01-FLUX/The.Last.of.Us.S02E01.Future.Days.1080p.AMZN.WEB-DL.DDP5.1.Atmos.H.264-FLUX.mkv'
  WHERE file='/mnt/altmount/TLOU-S02E01-FLUX/TLOU-S02E01-FLUX.mkv';"
```

**Do not touch `section_locations`.** Each library root is one row there
(`root_path`, e.g. `/mnt/altmount`), and this migration deliberately reuses the
old mountpoint, so the roots are already correct. Only the leaf paths inside
them move. A guide that relocates the mount has to update `root_path` too;
this one must not.

Three notes. Leave `media_parts.size` alone — the next scan sees a changed
size and re-analyzes that item, the same effect the size defect (section 9)
has anyway; nothing is deleted. For RAR releases the new path adds a directory
level; the part path existing on disk is what prevents deletion, and Plex
reconciles its directory rows on the next scan — expected behaviour, but not
bench-exercised, so watch these items on the first scan. And if you would
rather not touch the DB at all: accepting the delete-and-re-add costs those
items' collections membership and artwork choices (watch state should return
via GUID re-match) — a fair trade for a handful of items, not for hundreds.
Count `mismatched.txt` and decide.

```bash
sudo systemctl start plexmediaserver
```

---

## 9. What to expect from the size defect

zurg only reports a file's exact size when the poster wrote a byte count into
the subject line; otherwise it advertises the yEnc-*encoded* length, 2.5–3.2 %
over the truth, and reading the file does not correct it (measured at HEAD
`23869fa4`: HEAD still over-reports after reads; a read past the true EOF is
correctly refused with 416). AltMount reported exact sizes.

Every affected file therefore looks **modified** on the first scan after
cutover: expect re-analysis, and BIF regeneration if video preview thumbnails
are on. Items are not deleted and watch state is untouched. The over-reported
size is deterministic from the NZB, so the churn is one-time, not recurring.
Turn **off** "Generate video preview thumbnails" per library before that scan:
on Usenet every thumbnail pass is a full read of the release through your
connection allowance, and the size churn would trigger many at once. No
configuration fixes the defect today; it is an open zurg bug.

---

## 10. The easy case: Plex reads an *arr symlink library

If section 3 showed *arr-library paths, Plex's paths never change — they are
the symlink paths, and only the **targets** point at the mount. Run the
pre-flight, NZB recovery and parallel build unchanged (sections 4–6), cut over
as in section 8 with zurg mounted at the old `mount_path` so most targets keep
resolving (stopping Plex is only needed if the *arr library itself lives on a
mount), then find and repoint the broken links — the mismatch classes again:

```bash
find /path/to/arr-library -xtype l > broken-links.txt
# for each: ln -sfn "<zurg path from mapping-review.txt>" "<link>"
```

No Plex DB edit at all: `ln -sfn` changes the target, and the path Plex
stores is the link, which never moved. The size-change re-analysis from
section 9 still applies.

`STRM` strategy: Plex does not play `.strm` natively, so this pairing is rare.
If you have it, the `.strm` paths are what Plex knows; regenerate files at
those same paths pointing at zurg (`serve_strm_files` / `save_strm_files`) and
verify one plays before cutover. Not exercised on the bench; a sketch, not a
recipe.

---

## 11. Content that will read differently afterwards

- **RAR releases** gain their inner directory, a `Sample/` folder and the
  poster's `.url` files. Whether Plex picks a `-sample` file up as an extra
  version was not verified — check those items after the first scan.
- **`thumbnail.jpg`** sidecars reappear (AltMount dropped them). Not a
  filename Plex uses for posters; expect it to be inert.
- **Broken RAR chains** (`DoomsdayRar` class): empty folder on both sides, no
  Plex item on either, nothing to preserve.
- **par2/sfv** are hidden by zurg; `.nfo` is kept.

---

## 12. Verification, then decommission

After the first full scan completes:

```bash
# Nothing landed in the trash:
cp "$PLEXDB" /tmp/plex-after.db     # Plex may be running; this copy is read-only use
sqlite3 /tmp/plex-after.db "SELECT count(*) FROM metadata_items WHERE deleted_at IS NOT NULL;"
```

Want `0`. Then spot-check, minimum: one matched movie plays; one DB-edited
item plays and still shows its watch state and collections; one size-defect
episode plays after its re-analysis; posters you had chosen are still the
chosen ones.

Only when all of that holds: stop AltMount for good and archive its config
directory (the `.nzbz` store is the only other copy of your NZBs). Re-enable
Plex's periodic scan if you rely on it, with "Empty trash automatically" left
permanently off — that guard is load-bearing for any Plex-on-network-mount
setup, zurg included.

## 13. Rollback

Everything up to the DB edit is non-destructive: AltMount's config directory
was only read, the NZBs were copied out, and Plex was stopped, not modified.

```bash
sudo systemctl stop plexmediaserver
fusermount -u "$OLDMOUNT"
sudo systemctl start altmount            # and its mount, however you ran it
# only if you edited media_parts:
cp "$PLEXDB.bak-migration" "$PLEXDB"
sudo systemctl start plexmediaserver
```

If a scan *did* run against a bad mount before you caught it: with auto-empty
off the items are in the trash, not gone — restore the mount, rescan, and they
come back. Do not empty the trash until every section shows its full count.
