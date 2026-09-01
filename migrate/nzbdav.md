# Migrating from nzbdav to zurg

Read [the shared page](index.md) first. The trash guard lives there. So does
the reason your library lands in `__magic__` rather than in a symlink farm.

nzbdav-dev's last release is v0.6.4 from April 2026 and the upstream repository
is no longer maintained. v0.6.4 itself works fine. So this migration is about
getting off unmaintained software rather than about broken content. Take your
time. Nothing here needs a rushed cutover.

**This is the easiest of the five migrations.** Measured against zurg on the
same five releases nzbdav's tree differs by exactly two things.

| | |
|---|---|
| zurg gains | the release's `.nfo` file |
| zurg loses | 5 hash-named par2 volumes inside obfuscated releases |

**Nothing is renamed.** Every filename nzbdav serves is a filename zurg serves
under the same name and in the same directory shape. That holds inside RAR
archives too. The two servers agreed on all 20 non-par2 files in the corpus.

!!!warning Never walk the WebDAV root
nzbdav's `.ids` object store materialises all 16 hex children at every one of
its five levels regardless of contents. That is 16^5 or roughly 1,048,576
directories. Point `find` and `du` and `rclone` and any scanner at `/content`
or `/nzbs` or `/completed-symlinks` explicitly. Never at `/`.
!!!

## What your library looks like afterwards

**Everything is re-added** because the library root moves to `__magic__`.
There is no cheaper path and no partial one. See [the shared page](index.md)
for why.

The good news is that nzbdav is the one migration where **nothing you see
changes but the prefix**. Every filename zurg serves is the one nzbdav served.
An \*arr re-importing from `__magic__` parses exactly what it parsed before.
A folder you organise by hand looks the same as it always did.

That holds whichever setup you have. On Windows and anywhere else Plex reads
the mount directly the filenames are identical. If Sonarr and Radarr organise
a symlink library then the filenames were already theirs and the source they
parse is unchanged. So this migration alters nothing about how your library
reads. It only changes where it lives.

## What new content shows up

- The `.nfo` inside RAR releases.
- **Sample clips** inside `Sample/`. nzbdav publishes the directory and the
  clip and so does zurg. This one is *not* new for you. nzbdav is the only
  server of the four that already had it.
- Empty folders for releases whose archive chain is broken. nzbdav created
  nothing for those.
- par2 and sfv stop being visible.

None of it produces a Plex item except the sample clip and nzbdav already gave
you that. If it was not bothering you before then nothing changes.

## Get your NZBs out

zurg is fed by a directory of `.nzb` files and nzbdav still has all of yours at
`/nzbs/<category>/`. **Copy them. Do not move them.** Deleting from `/nzbs/`
cancels the job.

```bash
mkdir -p ~/migration/nzbs
for cat in uncategorized movies tv audio software; do
  rclone copy "nzbdav:/nzbs/$cat" ~/migration/nzbs/ --include '*.nzb'
done
ls ~/migration/nzbs | wc -l
```

Both servers name the release folder after the NZB *filename*. So the stems you
recovered should equal the folders nzbdav serves. Check that and rename any
that drifted.

```bash
rclone lsf "nzbdav:/content/movies" --dirs-only | sed 's:/$::' | sort > ~/migration/folders-old.txt
ls ~/migration/nzbs | sed 's/\.nzb$//' | sort > ~/migration/stems.txt
diff ~/migration/folders-old.txt ~/migration/stems.txt
```

Two zurg naming rules are worth checking against that list.

- zurg strips a trailing `.mkv` or `.mp4` from a folder name. If any stem ends
  that way then set `retain_folder_name_extension: true`.
- Two different releases sharing a stem get a ` {shorthash}` suffix on one of
  them. Find them now with `ls ~/migration/nzbs | sed 's/\.nzb$//' | sort |
  uniq -d`.

## Build zurg alongside

nzbdav keeps serving throughout. Copy its provider block into zurg's config.
Give zurg its own mountpoint. Drop the NZBs in and let it scan. The watch
directory is picked up every 15 seconds or so.

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

One path whatever you have today. Nothing here moves bytes.

**1. Turn on `__magic__`** and restart. The routes are registered at startup so
a dashboard toggle needs a restart before the namespace answers.

```yaml
magic:
  enabled: true
```

**2. Make the root folders.** They have to be *inside* `__magic__` and one
level down. Not `__magic__` itself and not the mount root. Both \*arrs raise a
health check for those and an import lands one level down anyway.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/          # your releases are already listed here
```

`__magic__` starts as a mirror of `__all__` so every release is present before
you organise anything.

**3. Organise it.** A `mv` inside `__magic__` writes a row and moves no bytes.

```bash
mv "/mnt/zurg/__magic__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**If Sonarr and Radarr organised your old library then let them do it here
too.** That is what `__magic__` is for and it replaces the symlink farm
outright. Add `__magic__/tv` and `__magic__/movies` as *new* root folders. Then
run a library import against them so the \*arrs adopt what is already there.
Never change an existing series or movie root folder to point into `__magic__`.
That makes the \*arr move the files across the mount boundary. It is a copy and
it downloads your library. The full sequence and the number to watch are on
[the shared page](index.md#coming-off-a-symlink-library).

**4. Point Plex at `__magic__`** and at that library only. Never `__magic__`
*and* a filter directory or every episode is found twice. Confirm
`autoEmptyTrash` is `0`. Add the new location and scan. Then remove the old
one. That is your \*arr library path or the nzbdav mount if Plex read it
directly.

**5. Empty the trash** once you have spot-checked a few items. Watch state
comes back through the GUID match. Collections and artwork choices do not.

Leave nzbdav running until then. It costs nothing and it is your rollback. When
you are done stop it.

```bash
sudo systemctl stop nzbdav
```

## Afterwards

Keep nzbdav's config directory until you have streamed from a representative
sample. It is the only other copy of your NZBs.

Now think about acquisition. zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) that Sonarr and
Radarr can grab through. It imports by rename inside `__magic__` rather than by
copying. One caveat before you switch a library over. zurg does not yet check
whether a post's articles are still on the news server. So a dead release
reports Completed and fails on the first read instead of being blocklisted and
re-grabbed.
