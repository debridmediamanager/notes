---
label: From InfiniDysk
icon: arrow-right
order: 70
---

# Migrating from InfiniDysk to zurg

Read [the shared page](index.md) first — the trash guard, and why your
library lands in `__magic__` rather than a symlink farm, both live there.

Measured against zurg on the same five releases:

| | |
|---|---|
| zurg gains | the sample clip, the `.nfo` |
| zurg loses | 5 hash-named par2 volumes inside obfuscated releases |
| renamed | **every release except multi-file ones** |

!!!warning The renaming is the whole migration
InfiniDysk renames a release's media file to the NZB filename whenever the
release resolves to a single payload. On the 2026-09-01 corpus four of five
came out as `ToyStory5.mkv`, `Obfuscated.mkv`, `FatherBrown.mp4` and
`MandaloriaREMUX.mkv`; only the ten-episode season pack kept its episode
names. The rename applies at any depth — `FatherBrown.mp4` sits *inside* the
preserved `Father.Brown.2013.S02E05.HDTV.x264-TLA/` directory.

zurg keeps the poster's filename. So the release name — the string Plex and
the \*arrs parse for quality, group and episode — comes back, and every
single-payload release changes path.
!!!

One more difference, small but confusing if you meet it cold: InfiniDysk
creates the archive's `Sample/` directory and leaves it **empty**. zurg puts
the sample clip inside it.

Content is not the reason to move. Build `cd9b1205` imported all five releases
of the reference corpus, season pack included, so do not expect to find
InfiniDysk dropping things. What you get back is the naming.

!!!warning Never walk the WebDAV root
The `.ids` object store materialises all 16 hex children at every one of its
five levels regardless of contents — 16^5 ≈ 1,048,576 directories. Point
`find`, `du`, `rclone` and any scanner at `/content`, `/nzbs` or
`/completed-symlinks` explicitly, never at `/`.
!!!

## What your library looks like afterwards

**Everything is re-added**, because the library root moves to `__magic__`.
See [the shared page](index.md) for why there is no cheaper path.

This is the migration where that costs you least and gains you most, because
almost every filename improves. `ToyStory5.mkv` becomes
`Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`, and an \*arr
re-importing from `__magic__` can finally parse quality, source, group and
edition off the filename. Only the season packs, which already read correctly,
stay as they were.

List the releases whose names move — most of them:

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

Because the rename can happen one level inside an archive directory, the
`-maxdepth 4` matters.

## What new content shows up

- **Sample clips** — the `Sample/` directories you already have stop being
  empty. This is the one worth configuring for: set
  [`only_show_the_biggest_file: true`](../reference/config.md) if you do not
  want a 9 MB sample turning up as a second version of the episode.
- The `.nfo` inside RAR releases. Inert under Plex's default agents.
- Empty folders where an archive chain is broken, where InfiniDysk created
  nothing.
- **par2 and sfv stop being visible**, hash-named volumes inside obfuscated
  releases included. Those carry no media extension, so Plex will not have
  itemised them — but if any non-Plex tooling of yours walked them, it will
  notice.

## Get your NZBs out

zurg is fed by a directory of `.nzb` files, one per release, named after the
release folder. InfiniDysk's WebDAV `/nzbs/<category>/` mirrors the queue and
is readable:

```bash
mkdir -p ~/recovered-nzbs
rclone copy infinidysk:nzbs ~/recovered-nzbs/ --include '*.nzb'   # scoped to /nzbs, never the root
find ~/recovered-nzbs -name '*.nzb' | wc -l
```

Whether completed jobs stay listed under `/nzbs` after they finish is
**unverified** — it mirrors the queue, and your history may be deeper than
your queue. For anything missing, the NZB metadata InfiniDysk keeps for
remounting lives in `{CONFIG_PATH}/blobs/`. The blob format is unverified;
check before trusting it:

```bash
for f in "$CONFIG_PATH"/blobs/*; do head -c 32 "$f" | grep -q '<?xml' && echo "NZB: $f"; done
```

If blobs are not plain XML on your install, your indexer's download history is
the fallback.

Then make every file `<release>.nzb` for the release folders you actually
have:

```bash
find "$ID/content" -mindepth 2 -maxdepth 2 -type d -printf '%P\n' \
  | awk -F/ '{print $1 "\t" $2}' > releases.tsv
```

NZBs pulled from `/nzbs/<category>/` normally already carry the right name,
since that is where the folder name came from. Two zurg naming rules to check
against the list:

- zurg strips a trailing `.mkv`/`.mp4` from a folder name. If any release
  folder ends that way, set `retain_folder_name_extension: true`.
- Two different releases sharing a name get a ` {shorthash}` suffix on one.
  Find them with `cut -f2 releases.tsv | sort | uniq -d`. InfiniDysk had the
  same problem differently — re-importing an NZB there created `<Release> (2)`.

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

`__all__` holds every release regardless of directory filters, so it is the
stable prefix to point symlinks at.

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
`0`, add the new location, scan, then remove the old InfiniDysk location.

**5. Empty the trash** once you have spot-checked a few items. Watch state
comes back through the GUID match; collections and artwork choices do not.

Leave InfiniDysk running until then — it costs nothing and it is your rollback.
When you are done:

```bash
sudo systemctl stop infinidysk infinidysk-rclone-mount
```

## Afterwards

Keep `{CONFIG_PATH}/blobs/` and your recovered NZB set until you have streamed
from a representative sample.

On acquisition: zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) Sonarr and Radarr
can grab through, importing by rename inside `__magic__`. It does not yet
check whether a post's articles are still on the news server, so a dead
release reports Completed and fails on the first read rather than being
blocklisted and re-grabbed.
