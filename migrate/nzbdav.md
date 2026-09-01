---
label: From nzbdav
icon: arrow-right
order: 60
---

# Migrating from nzbdav to zurg

Read [the shared page](index.md) first — the trash guard, and why your
library lands in `__magic__` rather than a symlink farm, both live there.

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

## What your library looks like afterwards

**Everything is re-added**, because the library root moves to `__magic__`.
There is no cheaper path and no partial one — see
[the shared page](index.md) for why.

The good news is that nzbdav is the one migration where **nothing you see
changes but the prefix**. Every filename zurg serves is the one nzbdav served,
so an \*arr re-importing from `__magic__` parses exactly what it parsed
before, and a folder you organise by hand looks the same as it always did.

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

One path, whatever you have today. Nothing here moves bytes.

**1. Turn on `__magic__`** and restart — the routes are registered at startup,
so a dashboard toggle needs a restart before the namespace answers.

```yaml
magic:
  enabled: true
```

**2. Make the root folders.** They have to be *inside* `__magic__`, one level
down. Not `__magic__` itself and not the mount root — both \*arrs raise a
health check for those, and an import lands here anyway.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/          # your releases are already listed here
```

`__magic__` starts as a mirror of `__all__`, so every release is present
before you organise anything.

**3. Organise, if you want to.** A `mv` inside `__magic__` writes a row and
moves no bytes:

```bash
mv "/mnt/zurg/__magic__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

Or point Sonarr and Radarr at those root folders and let them do it — see
[Sonarr & Radarr](../guides/sonarr-radarr.md). **Adopt the existing files where
they are; never change a root folder in a way that makes the \*arr move your
old library in.** That crosses the mount boundary, which is a copy, which
downloads everything.

**4. Point Plex at `__magic__`** — that library only, never `__magic__` *and* a
filter directory, or every episode is found twice. Confirm `autoEmptyTrash` is
`0`, add the new location, scan, then remove the old nzbdav location.

**5. Empty the trash** once you have spot-checked a few items. Watch state
comes back through the GUID match; collections and artwork choices do not.

Leave nzbdav running until then — it costs nothing and it is your rollback.
When you are done:

```bash
sudo systemctl stop nzbdav
```

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
