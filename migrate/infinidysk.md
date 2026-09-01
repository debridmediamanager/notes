# Migrating from InfiniDysk to zurg

Read [the shared page](index.md) first — the trash guard and the Setup A/B
question live there.

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

## What needs rescanning

**Setup A (symlink library): every single-payload release.** In practice that
is most of a movie library and any single-episode grab. Multi-file releases
and season packs resolve unchanged.

**Setup B (Plex on the mount): everything.** InfiniDysk serves
`<mount>/content/<category>/<release>/<file>` and zurg serves
`<mount>/<directory>/<release>/…`, so the prefix moves even where the filename
does not.

Find the set that will be re-added — a release folder whose media file is
named after the folder:

```bash
ID=/mnt/remote/nzbdav                      # your InfiniDysk mount
find "$ID/content" -mindepth 3 -maxdepth 4 -type f | while IFS= read -r f; do
  rel=$(basename "$(dirname "$f")")
  b=$(basename "$f")
  [ "${b%.*}" = "$rel" ] && echo "RENAMED BY INFINIDYSK: $f"
done
```

Because the rename can happen one level inside an archive directory, the
`-maxdepth 4` matters. Every line is an item Plex re-adds on the first scan;
the old one drops into the trash.

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

### Setup A — repoint the symlinks

Both mounts are up, so nothing is ever broken. The folder names match, so most
links are a prefix swap; the renamed ones need the video picked out.

```bash
LIB=/data/media
find "$LIB" -type l | while IFS= read -r link; do
  old=$(readlink "$link")
  rel=$(printf '%s\n' "$old" | sed -n 's|.*/content/[^/]*/\([^/]*\)/.*|\1|p')
  [ -n "$rel" ] || continue
  name=$(basename "$old")
  new="/mnt/zurg/__all__/$rel/$name"
  [ -e "$new" ] && ln -sfn "$new" "$link"
done
```

Most InfiniDysk libraries symlink into the `.ids` object store rather than the
human tree, in which case the target carries no release name and the loop
above cannot map it. Use the `completed-symlinks` tree instead, which does
carry names, or fall back to matching by the link's own filename. Then handle
what is left:

```bash
find "$LIB" -xtype l | while IFS= read -r link; do
  # release name from the link's own path, or from completed-symlinks
  rel=$(basename "$(dirname "$link")")
  find "/mnt/zurg/__all__/$rel" -type f \
       \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*' \
       -printf '%s\t%p\n' | sort -rn | head -1 | cut -f2- | \
    xargs -r -I{} ln -sfn {} "$link"
done
find "$LIB" -xtype l          # want no output
```

Do **not** unmount InfiniDysk until that last command is clean. Every line it
prints is a file Plex will treat as deleted on its next scan.

Plex sees no change: the link paths never moved, only their targets.

### Setup B — point Plex at zurg

Confirm `autoEmptyTrash` is `0`, add zurg's mount as an additional location on
each library, scan, then remove the old InfiniDysk location. Everything is
re-added — watch state returns via GUID, collections and artwork choices do
not.

Leave the old items in the trash until you have spot-checked a few.

## Afterwards

Keep `{CONFIG_PATH}/blobs/` and your recovered NZB set until you have streamed
from a representative sample.

On acquisition: zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) Sonarr and Radarr
can grab through, importing by rename inside `__magic__`. It does not yet
check whether a post's articles are still on the news server, so a dead
release reports Completed and fails on the first read rather than being
blocklisted and re-grabbed.
