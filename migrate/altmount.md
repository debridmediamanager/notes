---
label: From AltMount
icon: arrow-right
order: 90
---

# Migrating from AltMount to zurg

Read [the shared page](index.md) first — the trash guard and the Setup A/B
question live there.

AltMount serves the cleanest tree of the five: exactly one file per release,
no thumbnails, no adverts, no sample, no leftovers. The migration is
correspondingly small, because there is very little there to disagree about.

Measured against zurg on the same five releases:

| | |
|---|---|
| zurg gains | the sample clip, the `.nfo`, `thumbnail.jpg`, the `.url` adverts, the archive's inner directory, **and every release AltMount refused** |
| zurg loses | nothing |
| renamed | **archive (RAR) releases only** |

!!!info Only the archive path renames
Across three independent runs on build `0614008b`, plain single-file releases
kept the poster's filename — including one whose inner name differs from the
NZB name, and a fully obfuscated one. Only the release that had to be unpacked
from a RAR came out as `<NZB name>.mp4`.

Older AltMount builds renamed more than this, so check your own tree before
trusting the rescan list below. The one command in "What needs rescanning"
tells you in seconds.
!!!

## The bigger issue is what AltMount never imported

AltMount refused a 10-episode season pack in every one of four runs, with the
articles verified present on the news server beforehand:

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

The check is not deterministic — the same release came back with 196, then 93,
then 76 unverified segments — and it is size-biased, because
`import.segment_sample_percentage: 1` samples 1% of segments, so a bigger
release needs more STATs to land inside the deadline. Repeated against a
*faster* news host it refused more, not less: the season pack and a 41 GB
remux both. Latency is not the explanation.

The practical consequence for you: **the releases AltMount quietly never
published are the ones zurg will add.** They have no Plex item today, so
nothing is preserved and nothing is at risk — they simply appear. If your
library is smaller than your NZB collection, this is why.

If you want to keep AltMount importing while you migrate, lowering
`segment_sample_percentage` is the knob to try; it was not exercised here.

## What needs rescanning

**Setup A (symlink library): only the archive releases.** Everything else
resolves under zurg unchanged.

**Setup B (Plex on the mount): everything.** AltMount serves a flat
`<mount>/<release>/<file>` and zurg serves `<mount>/<directory>/<release>/…`,
so the prefix moves even where the filename does not.

Find your archive releases — the ones that will be re-added either way — by
looking for a mount folder whose single file is named after the folder:

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

Every line is a release whose file zurg will serve under the poster's name
inside the archive's own directory, one level deeper. Those items are re-added
on the first scan; the old ones drop into the trash.

## What new content shows up

Everything in the shared page's list applies to you, because AltMount publishes
none of it:

- **Sample clips** inside `Sample/` — the one worth configuring for. Set
  [`only_show_the_biggest_file: true`](../reference/config.md) if you do not
  want a 9 MB sample turning up as a second version.
- `thumbnail.jpg`, the `.nfo`, the poster's `.url` adverts. All inert.
- **Whole releases AltMount refused**, as new library items.
- Empty folders where an archive chain is broken.

## Get your NZBs out

AltMount took ownership of every NZB you fed it: the original was moved away
and a compressed copy kept at
`<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. The mapping from mount
folder to `.nzbz` is in the `.meta` files under
`<config>/metadata/complete/<Release>/` — binary, magic `AM3`, with the
`.nzbz` path in there as a plain string.

zurg wants one `.nzb` per release, named after the release, flat in `nzbs/`
(subdirectories are skipped). The `metadata/complete/<Release>` directory name
*is* the mount folder name, which is exactly the name the file should get:

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
    echo "NOT A GZIPPED NZB: $release — use the API export below" >&2
  fi
done
```

On the measured v0.3.2 install the `.nzbz` decompressed as a gzip copy of the
imported NZB, but the source also carries a zstd-protobuf path for these
files, so the `zcat`-plus-`grep` check is not paranoia. Anything it rejects
goes through the API instead — `GET /api/files/export-nzb?path=<virtual path>`
regenerates a faithful NZB from the store, and `POST /api/files/export-batch`
returns a ZIP. Both need a JWT rather than the API key:

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

Take virtual paths from the AltMount UI's file view or `/api/files/info`
rather than guessing the format. The download is named
`<queueID>-<name>.nzb`; rename it to `<Release>.nzb` so zurg names the folder
correctly.

Sanity check: the recovered `.nzb` count should equal the
`metadata/complete/*/` directory count.

## Build zurg alongside

AltMount keeps serving throughout. Run zurg on port 9999 — no clash with
AltMount's 8585.

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

### Setup A — repoint the symlinks

Both mounts are up, so nothing is ever broken. Repoint what resolves, then
handle the archive releases:

```bash
find /path/to/arr-library -type l | while IFS= read -r link; do
  old=$(readlink "$link")
  case "$old" in
    /mnt/altmount/*)
      rel=${old#/mnt/altmount/}
      new="/mnt/zurg/__all__/$rel"
      [ -e "$new" ] && ln -sfn "$new" "$link"
      ;;
  esac
done

# What is left dangling is the archive class — one video per release folder:
find /path/to/arr-library -xtype l | while IFS= read -r link; do
  release=$(readlink "$link" | sed 's|^/mnt/altmount/\([^/]*\)/.*|\1|')
  find "/mnt/zurg/__all__/$release" -type f \
       \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*' \
       -printf '%s\t%p\n' | sort -rn | head -1 | cut -f2- | \
    xargs -r -I{} ln -sfn {} "$link"
done
find /path/to/arr-library -xtype l          # want no output
```

The largest-non-sample heuristic is safe here because everything that already
resolved was skipped, so only single-payload releases reach it. Plex sees no
change: the link paths never moved.

### Setup B — point Plex at zurg

Confirm `autoEmptyTrash` is `0`, add zurg's mount as an additional location on
each library, scan, then remove the old AltMount location. Everything is
re-added — watch state returns via GUID, collections and artwork choices do
not.

Leave the old items in the trash until you have spot-checked a few.

## Afterwards

Do not decommission AltMount until you have streamed from a representative
sample. Its config directory holds the `.nzbz` store, which is the only other
copy of your NZBs.

On acquisition: zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) Sonarr and Radarr
can grab through. It does not yet check whether a post's articles are still on
the news server, so a dead release reports Completed and fails on the first
read rather than being blocklisted and re-grabbed.
