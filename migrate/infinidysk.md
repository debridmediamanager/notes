---
label: From InfiniDysk
icon: arrow-right
order: 70
---

# Migrating from InfiniDysk to zurg

Read [the shared page](index.md) first. The trash guard lives there. So does
the reason your library lands in `__magic__` rather than in a symlink farm.

Measured against zurg on the same five releases.

| | |
|---|---|
| zurg gains | the sample clip, the `.nfo` |
| zurg loses | 5 hash-named par2 volumes inside obfuscated releases |
| renamed | **every release except multi-file ones** |

!!!warning The renaming is the whole migration
InfiniDysk renames a release's media file to the NZB filename whenever the
release resolves to a single payload. On the 2026-09-01 corpus four of five
came out as `ToyStory5.mkv` and `Obfuscated.mkv` and `FatherBrown.mp4` and
`MandaloriaREMUX.mkv`. Only the ten-episode season pack kept its episode names.
The rename applies at any depth. `FatherBrown.mp4` sits *inside* the preserved
`Father.Brown.2013.S02E05.HDTV.x264-TLA/` directory.

zurg keeps the poster's filename. So the release name comes back and every
single-payload release changes path. That name is the string Plex and the
\*arrs parse for quality and group and episode.
!!!

One more difference is small but confusing if you meet it cold. InfiniDysk
creates the archive's `Sample/` directory and leaves it **empty**. zurg puts
the sample clip inside it.

Content is not the reason to move. Build `cd9b1205` imported all five releases
of the reference corpus including the season pack. Do not expect to find
InfiniDysk dropping things. What you get back is the naming.

!!!warning Never walk the WebDAV root
The `.ids` object store materialises all 16 hex children at every one of its
five levels regardless of contents. That is 16^5 or roughly 1,048,576
directories. Point `find` and `du` and `rclone` and any scanner at `/content`
or `/nzbs` or `/completed-symlinks` explicitly. Never at `/`.
!!!

## What your library looks like afterwards

**Everything is re-added** because the library root moves to `__magic__`. See
[the shared page](index.md) for why there is no cheaper path.

This is the migration where that costs you least and gains you most. Almost
every filename improves. `ToyStory5.mkv` becomes
`Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv` and an \*arr
re-importing from `__magic__` can finally parse quality and source and group
and edition off the filename. Only the season packs stay as they were and those
already read correctly.

List the releases whose names move. It will be most of them.

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

The `-maxdepth 4` matters because the rename can happen one level inside an
archive directory.

!!!info Whether you see any of this depends on your setup
If Plex reads the mount directly then the names above are what changes in your
library. That covers every Windows setup and any Linux or macOS one without an
\*arr symlink farm.

If Sonarr and Radarr organise a symlink library with renaming on then **your
filenames are already theirs** and none of the names above appear in Plex. What
the names tell you then is how good a parse the \*arr was working from. That
matters when you re-import. See [the shared page](index.md).
!!!

## What new content shows up

- **Sample clips.** The `Sample/` directories you already have stop being
  empty. This is the one worth configuring for. Set
  [`only_show_the_biggest_file: true`](../reference/config.md) if you do not
  want a 9 MB sample turning up as a second version of the episode.
- The `.nfo` inside RAR releases. Inert under Plex's default agents.
- Empty folders where an archive chain is broken. InfiniDysk created nothing
  for those.
- **par2 and sfv stop being visible.** That includes the hash-named volumes
  inside obfuscated releases. They carry no media extension so Plex will not
  have itemised them. If any non-Plex tooling of yours walked them then it will
  notice.

## Get your NZBs out

zurg is fed by a directory of `.nzb` files. One per release and named after the
release folder. InfiniDysk's WebDAV `/nzbs/<category>/` mirrors the queue and is
readable.

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

Whether completed jobs stay listed under `/nzbs` after they finish is
**unverified**. It mirrors the queue and your history may be deeper than your
queue. For anything missing the NZB metadata InfiniDysk keeps for remounting
lives in `{CONFIG_PATH}/blobs/`. The blob format is unverified so check before
trusting it.

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

If blobs are not plain XML on your install then your indexer's download history
is the fallback.

Then make every file `<release>.nzb` for the release folders you actually have.

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

NZBs pulled from `/nzbs/<category>/` normally already carry the right name.
That is where the folder name came from. Two zurg naming rules are worth
checking against the list.

- zurg strips a trailing `.mkv` or `.mp4` from a folder name. If any release
  folder ends that way then set `retain_folder_name_extension: true`.
- Two different releases sharing a name get a ` {shorthash}` suffix on one of
  them. Find them with `cut -f2 releases.tsv | sort | uniq -d`. InfiniDysk had
  the same problem differently. Re-importing an NZB there created
  `<Release> (2)`.

## Build zurg alongside

InfiniDysk keeps serving throughout.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy from InfiniDysk's provider settings
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
ls /mnt/zurg/__all__/ | wc -l          # should approach your release count
```

`__all__` holds every release regardless of directory filters.

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
one. That is your \*arr library path or the InfiniDysk mount if Plex read it
directly.

**5. Empty the trash** once you have spot-checked a few items. Watch state
comes back through the GUID match. Collections and artwork choices do not.

Leave InfiniDysk running until then. It costs nothing and it is your rollback.
When you are done stop it.

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## Afterwards

Keep `{CONFIG_PATH}/blobs/` and your recovered NZB set until you have streamed
from a representative sample.

Now think about acquisition. zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) that Sonarr and
Radarr can grab through. It imports by rename inside `__magic__`. One caveat
before you switch a library over. zurg does not yet check whether a post's
articles are still on the news server. So a dead release reports Completed and
fails on the first read rather than being blocklisted and re-grabbed.
