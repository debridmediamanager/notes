---
label: From AltMount
icon: arrow-right
order: 90
---

# Migrating from AltMount to zurg

Read [the shared page](index.md) first. The trash guard lives there. So does
the reason your library lands in `__magic__` rather than in a symlink farm.

AltMount serves the cleanest tree of the five. Exactly one file per release. No
thumbnails and no adverts and no sample and no leftovers. The migration is
correspondingly small because there is very little there to disagree about.

Measured against zurg on the same five releases.

| | |
|---|---|
| zurg gains | the sample clip, the `.nfo`, `thumbnail.jpg`, the `.url` adverts, the archive's inner directory, **and every release AltMount refused** |
| zurg loses | nothing |
| renamed | **archive (RAR) releases only** |

!!!info Only the archive path renames
Across three independent runs on build `0614008b` the plain single-file
releases kept the poster's filename. That includes one whose inner name differs
from the NZB name and a fully obfuscated one. Only the release that had to be
unpacked from a RAR came out as `<NZB name>.mp4`.

Older AltMount builds renamed more than this. Check your own tree before
trusting the list below. The one command under "What your library looks like
afterwards" tells you in seconds.
!!!

## The bigger issue is what AltMount never imported

AltMount refused a 10-episode season pack in every one of four runs. The
articles were verified present on the news server beforehand.

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

The check is not deterministic. The same release came back with 196 unverified
segments and then 93 and then 76. It is also size-biased. Setting
`import.segment_sample_percentage: 1` samples 1% of segments so a bigger
release needs more STATs to land inside the deadline. Repeated against a
*faster* news host it refused more rather than less. That run lost the season
pack and a 41 GB remux both. Latency is not the explanation.

The practical consequence for you is this. **The releases AltMount quietly
never published are the ones zurg will add.** They have no Plex item today so
nothing is preserved and nothing is at risk. They simply appear. If your
library is smaller than your NZB collection then this is why.

If you want to keep AltMount importing while you migrate then lowering
`segment_sample_percentage` is the knob to try. It was not exercised here.

## What your library looks like afterwards

**Everything is re-added** because the library root moves to `__magic__`. See
[the shared page](index.md) for why there is no cheaper path.

What changes on the way through is small. Plain single-file releases keep the
filename AltMount gave them so most of the library reads the same. **Archive
releases come back under the poster's name** and one directory deeper. That is
strictly better for an \*arr. The name
`father.brown.2013.s02e05.hdtv.x264-tla.mp4` carries the quality and source and
group that `FatherBrown.mp4` threw away.

Find the archive releases by looking for a mount folder whose single file is
named after the folder.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

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

AltMount publishes none of this so everything in the shared page's list applies
to you.

- **Sample clips** inside `Sample/`. This is the one worth configuring for. Set
  [`only_show_the_biggest_file: true`](../reference/config.md) if you do not
  want a 9 MB sample turning up as a second version.
- `thumbnail.jpg` and the `.nfo` and the poster's `.url` adverts. All inert.
- **Whole releases AltMount refused** arriving as new library items.
- Empty folders where an archive chain is broken.

## Get your NZBs out

AltMount took ownership of every NZB you fed it. The original was moved away
and a compressed copy kept at
`<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. The mapping from mount
folder to `.nzbz` is in the `.meta` files under
`<config>/metadata/complete/<Release>/`. Those are binary with magic `AM3` and
the `.nzbz` path sits in there as a plain string.

zurg wants one `.nzb` per release named after the release and flat in `nzbs/`.
Subdirectories are skipped. The `metadata/complete/<Release>` directory name
*is* the mount folder name and that is exactly the name the file should get.

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
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

On the measured v0.3.2 install the `.nzbz` decompressed as a gzip copy of the
imported NZB. The source also carries a zstd-protobuf path for these files so
the `zcat` and `grep` check is not paranoia. Anything it rejects goes through
the API instead. `GET /api/files/export-nzb?path=<virtual path>` regenerates a
faithful NZB from the store and `POST /api/files/export-batch` returns a ZIP.
Both need a JWT rather than the API key.

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

Take virtual paths from the AltMount UI's file view or from `/api/files/info`
rather than guessing the format. The download is named `<queueID>-<name>.nzb`.
Rename it to `<Release>.nzb` so zurg names the folder correctly.

One sanity check. The recovered `.nzb` count should equal the
`metadata/complete/*/` directory count.

## Build zurg alongside

AltMount keeps serving throughout. Run zurg on port 9999. There is no clash
with AltMount's 8585.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
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
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

Expect **more** folders here than AltMount had. That is the refused-import
class arriving.

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
one. That is your \*arr library path or the AltMount mount if Plex read it
directly.

**5. Empty the trash** once you have spot-checked a few items. Watch state
comes back through the GUID match. Collections and artwork choices do not.

Leave AltMount running until then. It costs nothing and it is your rollback.
When you are done stop it.

```bash
sudo systemctl stop altmount
```

## Afterwards

Do not decommission AltMount until you have streamed from a representative
sample. Its config directory holds the `.nzbz` store and that is the only other
copy of your NZBs.

Now think about acquisition. zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) that Sonarr and
Radarr can grab through. One caveat before you switch a library over. zurg does
not yet check whether a post's articles are still on the news server. So a dead
release reports Completed and fails on the first read rather than being
blocklisted and re-grabbed.
