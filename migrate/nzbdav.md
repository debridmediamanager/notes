---
label: From nzbdav
icon: arrow-right
order: 60
---

# Migrating from nzbdav to zurg

Read [the shared page](index.md) first — the trash guard and the Setup A/B
question live there.

nzbdav-dev's last release is v0.6.4 from April 2026 and the upstream
repository is no longer maintained. v0.6.4 itself works fine, so this
migration is about getting off unmaintained software rather than about broken
content. Take your time; nothing here needs a rushed cutover.

**This is the easiest of the five migrations.** Measured against zurg on the
same five releases, nzbdav's tree differs by exactly two things:

| | |
|---|---|
| zurg gains | the release's `.nfo` file |
| zurg loses | 5 hash-named par2 volumes inside obfuscated releases |

**Nothing is renamed.** Every filename nzbdav serves, zurg serves under the
same name, in the same directory shape, including inside RAR archives. The
two servers agreed on all 20 non-par2 files in the corpus.

!!!warning Never walk the WebDAV root
nzbdav's `.ids` object store materialises all 16 hex children at every one of
its five levels regardless of contents — 16^5 ≈ 1,048,576 directories. Point
`find`, `du`, `rclone` and any scanner at `/content`, `/nzbs` or
`/completed-symlinks` explicitly, never at `/`.
!!!

## What needs rescanning

**Setup A (symlink library): nothing.** Filenames match, so every symlink
target resolves under zurg once you repoint the prefix. Plex sees no change at
all.

**Setup B (Plex on the mount): the whole library, unless you reproduce the
root shape.** nzbdav serves `<mount>/content/<category>/<release>/<file>` and
zurg serves `<mount>/<directory>/<release>/<file>`. Filenames match but the
prefix does not, so by default everything is re-added.

Because the names match, nzbdav is the one migration where a **zero-rescan
Setup B** is cheap. If every release sat under a single category, mount zurg's
`__all__` where that category was and every path is reproduced exactly:

```bash
rclone mount zurg:__all__ /mnt/nzbdav/content/movies --config rclone.conf --dir-cache-time 10s
```

If you used several categories you would need `directories:` filters that
reproduce each category's membership exactly, and zurg sorts by its own
filters rather than by the SAB category a release was queued under. The two
will not agree on everything, and each release that lands in a different
directory is a re-add anyway. At that point take the simple route below.

## What new content shows up

- The `.nfo` inside RAR releases.
- **Sample clips** inside `Sample/`. nzbdav publishes the directory and the
  clip; so does zurg, so this one is *not* new for you — nzbdav is the only
  server of the four that already had it.
- Empty folders for releases whose archive chain is broken, where nzbdav
  created nothing.
- par2 and sfv stop being visible.

None of it produces a Plex item except the sample clip, which nzbdav already
gave you. If it was not bothering you before, nothing changes.

## Get your NZBs out

zurg is fed by a directory of `.nzb` files, and nzbdav still has all of yours
at `/nzbs/<category>/`. **Copy, do not move — deleting from `/nzbs/` cancels
the job.**

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

Both servers name the release folder after the NZB *filename*, so the stems
you recovered should equal the folders nzbdav serves. Check, and rename any
that drifted:

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

Two zurg naming rules worth checking against that list:

- zurg strips a trailing `.mkv`/`.mp4` from a folder name. If any stem ends
  that way, set `retain_folder_name_extension: true`.
- Two different releases sharing a stem get a ` {shorthash}` suffix on one of
  them. Find them now with `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`.

## Build zurg alongside

nzbdav keeps serving throughout. Copy its provider block into zurg's config,
give zurg its own mountpoint, drop the NZBs in and let it scan — the watch
directory is picked up every ~15 s.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from nzbdav's provider settings
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp ~/migration/nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l     # should approach your release count
```

## Cut over

### Setup A — repoint the symlinks

Both mounts are up, so no path is ever broken and Plex sees nothing. Because
the filenames match, the retarget is a prefix swap:

```bash
find /path/to/arr-library -type l | while IFS= read -r link; do
  old=$(readlink "$link")
  case "$old" in
    /mnt/nzbdav/content/*)
      rel=${old#/mnt/nzbdav/content/*/}          # strip mount + category
      new="/mnt/zurg/__all__/$rel"
      [ -e "$new" ] && ln -sfn "$new" "$link"
      ;;
  esac
done
find /path/to/arr-library -xtype l          # want no output
```

Anything still listed is a release zurg does not have — a missing NZB. Fix it
or accept the loss. Then stop nzbdav. No scan, no trash, no re-add.

### Setup B — point Plex at zurg

Confirm `autoEmptyTrash` is `0`, then add zurg's mount as an additional
location on each library (Edit → Add folder), scan, and remove the old nzbdav
location once the new items are in. Your library is re-added: watch state
returns via GUID, collections and artwork choices do not.

Leave the old items in the trash until you have spot-checked a few, then empty
it.

## Afterwards

Keep nzbdav's config directory until you have streamed from a representative
sample. It is the only other copy of your NZBs.

On acquisition: zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) Sonarr and Radarr
can grab through, and it imports by rename inside `__magic__` rather than by
copying. The caveat before you switch a library over is that zurg does not yet
check whether a post's articles are still on the news server, so a dead
release reports Completed and fails on the first read instead of being
blocklisted and re-grabbed.
