# Migrating from nzbdav-dev to zurg

nzbdav-dev's last release is v0.6.4, April 2026, and the upstream repository is
no longer maintained (it now redirects to a fork under a different name; that
fork is a separate project and not what this guide is about). v0.6.4 itself
works — on the reference corpus it imported everything zurg imports, season
packs included — so this migration is about getting off unmaintained software,
not about broken content. That means you can take your time: nothing here
requires a rushed cutover, and the safest sequence below runs both servers in
parallel until the switch is a single atomic step.

The overriding requirement: **Plex must not rescan from scratch, must not
delete library items, and must keep watch state, play counts, collections,
ratings and artwork choices.**

Everything below follows from one fact and one qualification.

The fact: a Plex library item is bound to the file path recorded in
`media_parts.file` inside `com.plexapp.plugins.library.db`, so a changed path
is a new item plus a deleted one.

The qualification, measured against a live 10,126-item library, because the
folklore overstates it: **watch state is not stored against that item.**
`metadata_item_settings` is keyed by `account_id` plus a `plex://` GUID —

```sql
metadata_item_settings(id, account_id, guid, rating, view_offset,
                       view_count, last_viewed_at, …)
-- ('plex://movie/5d776d1796b655001fe3f5d3', 1, NULL, 1707662516)
```

— so watched flags, play counts, resume offsets and user ratings re-attach
when the new file matches to the same GUID. What dies with the old item is
everything hanging off the `metadata_items` row: collections, playlists (they
store item ids), manual poster/art/match choices, and `added_at`, which floods
Recently Added with your whole library. Deletion itself is soft (`deleted_at`
on `media_parts` and `media_items`) — which is what `autoEmptyTrash: 0`
preserves, and what emptying the trash makes permanent.

So the whole job is: make the paths Plex already knows keep resolving to the
same content, served by zurg instead of nzbdav. What you are protecting is the
library's structure and curation more than its watch history.

---

## 1. Decide which setup you have

Two setups exist in the wild. Check before doing anything else.

**Setup A — Plex points at an *arr-managed library of symlinks.** This is
nzbdav's documented import strategy: `completed-symlinks/<category>/<release>/
<file>.rclonelink` resolved by rclone's `--links` flag into real symlinks,
which Radarr/Sonarr imported into a media library at paths *they* chose
(`/data/media/movies/Movie (2024)/…`). Plex scans that library, never the
nzbdav mount directly.

```bash
# If this prints symlink targets under .ids, you are Setup A:
find /path/to/your/plex/library -type l | head -3 | xargs -I{} readlink {}
# e.g.  /mnt/nzbdav/.ids/1/8/5/e/d/185ed3fe-6b74-44f1-967f-fc0222f195ec
```

**Setup B — Plex points straight at the mount**, at paths like
`/mnt/nzbdav/content/movies/<release>/<file>`.

Setup A is the easy migration: the Plex-visible paths are the symlink paths,
which never change. The job is repointing symlink *targets*, done atomically
while both mounts are live, and Plex never sees a single file move. If you are
Setup A, sections 2–6 then 7 are your path. Setup B is harder; section 8
covers it.

Whichever you are: **never point a scanner, `find`, `du`, or any recursive
walk at the nzbdav WebDAV root.** The `.ids` object store materialises all 16
hex children at every one of its five levels regardless of contents — 16^5 ≈
1,048,576 directories. Every recipe here targets `/content`, `/nzbs` or
`/completed-symlinks` explicitly.

---

## 2. What changes between the two trees

Measured 2026-08-19 by importing the same NZBs into both servers and reading
the mounts back. Per release, zurg's tree matches nzbdav's almost exactly:
both name the release folder after the NZB filename, both keep the poster's
inner filenames, both keep sidecars (`thumbnail.jpg`, `.nfo`, `.url`), both
walk into RAR archives and reproduce the inner directory including `Sample/`.

The deltas, all of them:

| | nzbdav-dev v0.6.4 | zurg |
|---|---|---|
| Roots | `/content/<category>/<release>/…` (SAB categories) | `/dav/<directory>/<release>/…` — directories from `config.yml` filters, plus `__all__`, `__nzb__` |
| par2 in obfuscated releases | left visible, hash-named | detected by content and hidden |
| File sizes | exact | over-reported by 2.5–3.2% on NZBs whose subjects carry no byte count (see below) |
| Broken RAR chain | import fails, nothing created | empty release folder |
| Ingestion | SABnzbd API + WebDAV `/nzbs/` upload | drop `.nzb` into `nzbs/` beside the binary, or the opt-in [SABnzbd endpoint](../guides/sonarr-radarr.md) an \*arr can grab through — which does not yet report a dead post as failed |

**The size defect matters for Plex.** True sizes come from the yEnc `=ybegin`
header; zurg only uses the exact size when the poster wrote a byte count into
the subject line, otherwise it advertises the yEnc-*encoded* length. Measured:
a 4,311,416,302-byte episode listed as 4,419,101,475 (+2.50%); other files
+2.48% and +3.18%; files with byte counts in the subject were exact. Reading
the file does not correct the listing. To Plex a changed size is a *modified*
file: the item survives with its watch state, but Plex may re-analyse it and
regenerate preview thumbnails / intro markers. Expect a burst of analysis
after cutover, not deletions.

**The hidden par2 files cost nothing.** Plex only creates items from media
files; hash-named par2 volumes are not media and never had items. Their
disappearance is invisible to Plex. Only non-Plex tooling that walked them
will notice.

**A release nzbdav refused never reached Plex**, so zurg's empty folder for
the same broken release is also invisible — Plex ignores empty directories.

---

## 3. Pre-flight

Do all of this before touching anything.

**3.1 — Plex guards.** `autoEmptyTrash` must be 0. At 1, a scan that finds
files missing deletes them permanently and at once; at 0 they sit in the trash
and come back when the mount does. This has cost a 30,065-item library before.

```bash
TOKEN=YOUR_PLEX_TOKEN
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
```

Also uncheck "Empty trash automatically after every scan" per library
(Edit → Advanced), and turn off the two automatic-update settings under
Settings → Library ("Update my library periodically", "Run a partial scan
when changes are detected") for the duration of the migration.

**3.2 — Confirm nothing is scanning or playing.** Both must be zero. Sessions
only prove nobody is watching; a scan is the thing that does damage.

```bash
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Use `grep -o … | wc -l`, not `grep -c`: grep exits 1 when it finds nothing,
which is the *good* case here, and that aborts a `&&` chain or a `set -e`
script right before the step it was guarding.

**3.3 — Back up the Plex database.** Stop Plex first; a live copy is corrupt.

```bash
sudo systemctl stop plexmediaserver
cp -a "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases" \
      ~/plex-db-backup-$(date +%F)
sudo systemctl start plexmediaserver
```

**3.4 — Stop the *arrs importing.** Disable RSS sync and automatic import in
Radarr/Sonarr (or stop them) so nothing writes new symlinks or hands nzbdav
new jobs mid-migration.

---

## 4. Inventory: pull every NZB out of nzbdav

zurg is fed by `.nzb` files in a watch directory. nzbdav still has all of
yours: the WebDAV directory `/nzbs/<category>/` mirrors the queue and is
readable. **Copy, do not move — deleting from `/nzbs/` cancels the job.**

```bash
# rclone remote pointed at nzbdav's WebDAV (reuse your existing one)
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

The raw blobs also live under nzbdav's config directory per its own docs
(not re-verified here); the WebDAV route above is the supported one and was
verified working.

**Naming is the whole game.** All servers in this family — nzbdav included —
name the release folder after the NZB *filename*, not the subject line and not
the inner file. So the folder Plex knows as
`/content/movies/The.Wild.Robot.2024.BluRay.1080p.DD5.1.x264-TiGER/` came from
`The.Wild.Robot.2024.BluRay.1080p.DD5.1.x264-TiGER.nzb`, and dropping that
same file into zurg reproduces the same folder name. Verify the stems match
the folders Plex has, and fix any that don't by renaming the `.nzb`:

```bash
# Folders nzbdav serves (per category — never the WebDAV root):
rclone lsf "nzbdav:/content/movies" --dirs-only | sort > ~/migration/folders-old.txt
rclone lsf "nzbdav:/content/tv"    --dirs-only | sort >> ~/migration/folders-old.txt
# Stems you recovered:
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff <(sed 's:/$::' ~/migration/folders-old.txt | sort) ~/migration/stems.txt
```

Three zurg-specific naming rules to check against that list:

- With defaults, zurg strips a trailing `.mkv` or `.mp4` from the folder name
  (`GetKey_Original`, `internal/torrent/key.go`). `Movie.2024.mkv.nzb` becomes
  folder `Movie.2024`, which will not match nzbdav's `Movie.2024.mkv`. If any
  stems end that way, set `retain_folder_name_extension: true` in `config.yml`.
- Two *different* releases with the same stem get a ` {shorthash}` suffix on
  the folder. Find duplicates now: `ls ~/migration/nzbs | sed 's/\.nzb$//' |
  sort | uniq -d` — rename one of each pair before import, because a suffixed
  folder matches nothing Plex knows.
- A stem that looks like a hash makes zurg fall back to the NZB's
  `<meta type="name">`. If a hash-named folder is what Plex knows, rename the
  `.nzb` is not enough — but nzbdav named folders from filenames too, so this
  only bites if you renamed files during recovery.

---

## 5. Build the zurg side in parallel

nzbdav keeps serving throughout. zurg gets its own mountpoint.

```yaml
# config.yml (minimal)
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USER
      password: YOUR_PASS
      connections: 30          # your plan's real allowance, not the default 8
mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone
enable_repair: true
directories:
  tv:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

```bash
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg          # expect "Usenet account <label> connected: …" then one
                # "Loaded NZB <file>: N files" per NZB
```

Note what does *not* carry over: `zurg_*` tag filters never match Usenet
content (ffprobe cannot open zurg's locally-assembled links), so filter on
names, extensions, sizes and `has_episodes`. Acquisition does carry over, with
a caveat: zurg has a [SABnzbd endpoint](../guides/sonarr-radarr.md) of its own, off by
default, and an \*arr pointed at it imports from `__magic__` by rename. It
does not yet check that a post's articles are still on the news server, so a
dead release reports Completed rather than being blocklisted — until that
lands, dropping `.nzb` files into `nzbs/` is the path that never lies to the
\*arr about what it got.

Verify the tree before involving Plex. `__all__` contains every release under
its release name regardless of filters, which makes it the stable comparison
target:

```bash
ls /mnt/zurg/__all__/ | sort > ~/migration/folders-new.txt
diff <(sed 's:/$::' ~/migration/folders-old.txt | sort) ~/migration/folders-new.txt
# Then spot-check file names inside a few releases against the old mount:
diff <(rclone lsf "nzbdav:/content/movies/SomeRelease") <(ls /mnt/zurg/__all__/SomeRelease)
```

Expect exactly two classes of difference: hash-named par2 files present on the
nzbdav side of obfuscated releases and absent on zurg's, and empty zurg
folders for releases nzbdav had rejected. Anything else, stop and fix before
cutover. Sizes will differ on some files (section 2); names must not.

---

## 6. Build the path map

Both setups need a mapping from old identity to new path. The
`completed-symlinks` tree is the Rosetta stone: each entry is
`<category>/<release>/<file>` and its target is the `.ids` object path — and
`.ids/<…>/<uuid>` and `/content/<category>/<release>/<file>` serve the same
bytes (verified: identical Content-Length). So `.ids` target →
release + file → zurg path, with `__all__` as the target root so zurg's
filter placement is irrelevant:

```bash
# On the machine with the nzbdav mount (rclone --links, so these are real symlinks).
# Map: .ids target -> /mnt/zurg/__all__/<release>/<file>
: > ~/migration/idmap.tsv
find /mnt/nzbdav/completed-symlinks -type l -print0 |
while IFS= read -r -d '' link; do
  ids_target=$(readlink "$link")
  rel=${link#/mnt/nzbdav/completed-symlinks/}   # <category>/<release>/<file>
  rel=${rel#*/}                                 # <release>/<file>
  printf '%s\t%s\n' "$ids_target" "/mnt/zurg/__all__/$rel" >> ~/migration/idmap.tsv
done
wc -l ~/migration/idmap.tsv
```

If your rclone mounts *without* `--links`, the entries are `*.rclonelink`
text files instead; use `cat` in place of `readlink` and strip the
`.rclonelink` suffix from `rel`. (nzbdav's own documentation warns `--links`
needs a recent rclone — v1.70.3 works, v1.60.1-DEV does not.)

Sanity-check every mapped target exists on the zurg side before touching
anything:

```bash
awk -F'\t' '{print $2}' ~/migration/idmap.tsv | while IFS= read -r p; do
  [ -e "$p" ] || echo "MISSING: $p"
done
```

Zero `MISSING` lines is the gate for cutover.

---

## 7. Cutover, Setup A: retarget the symlinks

This is the good case. The Plex-visible paths are the symlink paths in the
*arr library, and those do not change. Each symlink flips atomically from a
valid nzbdav target to a valid zurg target **while both mounts are live**, so
there is no window in which Plex could see a missing file, let alone an empty
mount.

```bash
# Retarget every library symlink whose target is in the map.
find /path/to/your/plex/library -type l -print0 |
while IFS= read -r -d '' link; do
  old=$(readlink "$link")
  new=$(awk -F'\t' -v k="$old" '$1==k{print $2}' ~/migration/idmap.tsv)
  [ -z "$new" ] && { echo "UNMAPPED: $link -> $old"; continue; }
  dir=$(dirname "$link")
  tmp=$(mktemp -u "$dir/.retarget.XXXXXX")
  ln -s "$new" "$tmp" && mv -T "$tmp" "$link"   # rename(2): atomic replace
done
```

`mv -T` is GNU coreutils; it guarantees the destination is replaced rather
than descended into. Without it (macOS), `mv -f` works here only because the
targets are files, not directories — prefer installing coreutils.

Find anything broken afterwards:

```bash
find /path/to/your/plex/library -xtype l          # GNU find: dangling symlinks
# portable equivalent: find -L /path/to/your/plex/library -type l
```

Zero dangling links and zero `UNMAPPED` lines means the cutover is done. Plex
was never involved: same paths, same items, watch state and everything else
untouched. Decommission nzbdav at leisure (section 10), then re-run the
pre-flight checks and let Plex scan — expect re-analysis on the files whose
advertised size grew (section 2), and nothing else.

Point the *arrs' root folders nowhere new — they manage the same library
paths — but their download client entry (nzbdav's SAB mock) now has no
replacement; remove it and feed zurg's `nzbs/` directly from your indexer.

---

## 8. Cutover, Setup B: Plex pointed at `/content`

Harder, because zurg cannot reproduce `/content/<category>/…` natively: its
roots are `/dav/<directory>/`, directories come from filters rather than SAB
categories, and the mount prefix differs. Three options, best first:

**(a) A symlink shim tree — recommended.** Build a static tree of real
directories and symlinks that reproduces the old paths exactly, each link
pointing into `/mnt/zurg/__all__/`. Exact per-file fidelity, independent of
zurg's filter placement:

```bash
SHIM=~/migration/shim
for cat in movies tv; do
  rclone lsf "nzbdav:/content/$cat" --dirs-only | sed 's:/$::' |
  while IFS= read -r rel; do
    mkdir -p "$SHIM/content/$cat"
    ln -s "/mnt/zurg/__all__/$rel" "$SHIM/content/$cat/$rel"
  done
done
```

Then swap it into place under the exact path Plex knows. This is the one
moment with a window, so it is gated: run the section 3.2 pre-flight
(both zeros), unmount nzbdav's rclone, and immediately move the shim in:

```bash
fusermount -u /mnt/nzbdav            # umount /mnt/nzbdav on macOS
mv ~/migration/shim/content /mnt/nzbdav/content
ls /mnt/nzbdav/content/movies | head  # must list releases before you re-enable anything
```

With automatic scans off and no scan in flight, Plex never observes the
seconds between unmount and `mv`. Directory-level symlinks are fine: Plex
follows them and keeps recording the paths it scanned.

**(b) Mount zurg so the prefix matches.** Name zurg's directories `movies`
and `tv` and set `mount_path: /mnt/nzbdav/content`. Paths line up with no
shim — but only if zurg's filters file every release into the same category
nzbdav's SAB categories did. A release that lands in the other directory is a
moved file: new item, deleted item, and the curation attached to it —
collections, artwork, `added_at` — gone, even though watch state re-attaches
by GUID. Use this only if your
category split is cleanly `has_episodes`-shaped and you verify placement
release-by-release against `folders-old.txt` first. Extra roots (`__all__`,
`__nzb__`) appear beside `movies` and `tv`; harmless as long as no Plex
library points at the mount root — which it never should.

**(c) Rewrite `media_parts.file` in the Plex database.** Unsupported but
honest about what it is: with Plex stopped and the backup taken,

**Use Plex's own SQLite binary, not the system one.** The schema carries
custom extensions: a stock `sqlite3` walking this database fails with
`no such module: spellfix1` (observed, on a Plex 10,126-item library). Reading
a copy is fine; writing with the wrong binary is not.

```bash
PSQL="/usr/lib/plexmediaserver/Plex SQLite"      # Linux package path
DB="…/Plug-in Support/Databases/com.plexapp.plugins.library.db"

sudo systemctl stop plexmediaserver
"$PSQL" "$DB" \
  "UPDATE media_parts SET file = replace(file, '/mnt/nzbdav/content/movies/', '/mnt/zurg/movies/');"
"$PSQL" "$DB" \
  "UPDATE section_locations SET root_path = '/mnt/zurg/movies' WHERE root_path = '/mnt/nzbdav/content/movies';"
sudo systemctl start plexmediaserver
```

`section_locations.root_path` is what each library is pointed at — one row per
library root — and it must move with the parts, or Plex will treat every
rewritten path as outside the library. Verify before starting Plex:

```bash
"$PSQL" "$DB" "SELECT id, library_section_id, root_path FROM section_locations;"
"$PSQL" "$DB" "SELECT count(*) FROM media_parts WHERE file LIKE '/mnt/nzbdav/%';"   # want 0
```

Last resort, for path shapes the other two cannot bridge — a prefix rewrite
cannot express per-release placement differences, so (a) beats it whenever the
old tree still exists to be mirrored.

---

## 9. Verification

```bash
# 1. No dangling links (Setup A library, or the shim):
find /path/to/links -xtype l | wc -l                       # want 0

# 2. Plex sees no deletions: after one manual scan of one library,
#    check the library's trash is empty in the UI, then the rest.

# 3. Watch state spot-check: pick five long-watched items, confirm
#    watched flags, play counts and ratings survive the scan.

# 4. Playback: play one file per release shape — plain movie, episode,
#    RAR-packed release, obfuscated release — through Plex, with a seek.
```

Give zurg's Plex integration your server URL and token afterwards
(`plex_server_url` / `plex_token` in `config.yml`, or the dashboard auth
flow) so library changes trigger targeted scans; see `docs/plex.md`.

---

## 10. Rollback

Nothing in this runbook consumes anything. The NZBs were copied, not moved;
nzbdav's queue, blobs and database are untouched; zurg does not modify the
`.nzb` files it reads.

- **Setup A:** re-run the section 7 loop with the map inverted
  (`awk -F'\t' '{print $2"\t"$1}' idmap.tsv`), or restore the library
  directory from a pre-migration copy if you took one. nzbdav's mount must be
  back up first.
- **Setup B (a/b):** remove the shim / unmount zurg, remount nzbdav's rclone
  at the original path. Pre-flight first, as ever.
- **Setup B (c), or anything that went wrong at the item level:** stop Plex,
  restore the Databases directory from the section 3.3 backup, start Plex.

The one irreversible act in the whole migration would be letting a scan run
against a missing mount with auto-empty-trash on. That is why section 3 comes
first.
