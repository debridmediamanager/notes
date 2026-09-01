# Migrating from decypharr to zurg

Read [the shared page](index.md) first — the trash guard and the Setup A/B
question live there.

decypharr and zurg solve the same problem and their root layouts are
strikingly close, which makes this the migration with the most that carries
over for free:

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | a `directories:` entry with `not_provider: nzb` |
| `nzbs/<job>/` | a `directories:` entry with `provider: nzb`, or built-in `__nzb__` |

The **debrid side needs nothing**. Both servers list the same accounts and
present the torrent's own filenames, so those paths are identical once zurg
sits at decypharr's mountpoint. Everything below is about the Usenet side.

Two things to settle before you start:

- **Providers.** zurg speaks `realdebrid`, `alldebrid`, `torbox` and `nzb`.
  decypharr additionally supports Debrid-Link and Premiumize, and zurg has no
  backend for either. Content held only on those accounts cannot be served by
  zurg — re-acquire it on a supported account, or accept losing it.
- **Do not change decypharr's `folder_naming` before migrating.** It renames
  every folder in the library at once, which breaks every symlink target and
  every mount-direct Plex path in one stroke.

## What differs on the Usenet side

Measured against zurg on the same five releases:

| | |
|---|---|
| zurg gains | `thumbnail.jpg`, the sample clip, the `.nfo`, the `.url` adverts, the archive's inner directory, **and the obfuscated release decypharr dropped** |
| zurg loses | nothing |
| renamed | single-file releases, and archive releases |

**Single-file releases** come out of decypharr named after the job
(`ToyStory5/ToyStory5.mkv`); zurg keeps the poster's name
(`ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`).

**Archive releases** are the interesting case, and it is worth understanding
because it explains two symptoms at once. decypharr produces:

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

That is the archive's inner directory name and the file's own name
concatenated **with no separator** — a path join that lost its `/`. So the
missing directory level and the malformed filename are the same defect, not
two. zurg reproduces the real structure:
`FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`.

**Multi-file releases and season packs keep their real filenames on both
sides** and match automatically once the folder name matches.

## What needs rescanning

**Setup A (symlink library): single-file and archive releases only.** Debrid
torrents and multi-file NZB releases resolve unchanged.

**Setup B (Plex on the mount): the same set, and nothing else** — provided you
put zurg at decypharr's old mountpoint. The roots line up, so
`__all__/<job>/<file>` is reproduced exactly for everything decypharr did not
rename. This is the one migration where Setup B is nearly as cheap as Setup A.

Find the set that will be re-added:

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "WILL BE RENAMED: $job"
done
```

Every single-file job on that list is re-added on the first scan; the old item
drops into the trash. Multi-file jobs are untouched.

## What new content shows up

- **Sample clips** inside `Sample/` — the one worth configuring for. Set
  [`only_show_the_biggest_file: true`](../reference/config.md) if you do not
  want a 9 MB sample turning up as a second version.
- `thumbnail.jpg`, the `.nfo`, the poster's `.url` adverts. All inert.
- **Obfuscated releases decypharr dropped**, as new library items. decypharr
  published nothing at all for a fully hash-named post; zurg resolves it to
  the real release name and serves it.
- Empty folders where an archive chain is broken.

## Get your NZBs back

**decypharr cannot give them to you.** It keeps `usenet/meta/<uuid>.meta` —
one compressed binary per job — and a `usenet/nzbs/` directory that was empty
on the bench. There is no documented export, and whether the `.meta` blobs
decode back into NZBs is unverified. Treat the originals as unrecoverable.

What you do have is the job names, and on both servers the job folder name
*is* the NZB filename. So the folder list is your shopping list:

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

For each job, re-fetch the NZB from your indexer by searching the folder name,
and **rename the file to exactly that name plus `.nzb`** before dropping it in
zurg's `nzbs/` directory — the filename is the folder name, and the folder
name is what keeps the path stable.

Two rules while you do it:

- **Skip any release a debrid account already holds.** The symlink resolves
  through the torrent copy, and adding the NZB too makes zurg see two
  different releases with one name and hash-suffix one of them
  (`Some.Release {a1b2c3}`), which breaks whatever pointed at the bare name.
- A release your indexer no longer carries is simply gone. With
  `autoEmptyTrash` at `0` the Plex item survives in the trash until you decide
  to drop it.

## Build zurg alongside

Run zurg beside decypharr on its own mountpoint. Both may list the same debrid
accounts at once — listing is read-only.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_TOKEN
  # - type: alldebrid / torbox as you have them
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30                # your plan's real allowance
retain_rd_torrent_name: false        # align with decypharr's folder_naming
retain_folder_name_extension: false  # true if your folders carry .mkv/.mp4
mount_path: "/mnt/zurg-staging"
rclone_enabled: true
rclone_binary: bin/rclone
directories:                         # Setup B: reproduce decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

Then check the debrid side lines up before going further:

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

If the torrent folders differ *systematically* — an extension present or
absent, the RD rename instead of the original — flip `retain_rd_torrent_name`
or `retain_folder_name_extension` and rescan rather than fixing anything by
hand. Folders only on the decypharr side are the Usenet jobs, plus anything on
a Debrid-Link or Premiumize account.

## Cut over

### Setup A — repoint the symlinks

```bash
find /data/media -type l | while IFS= read -r link; do
  old=$(readlink "$link")
  case "$old" in
    /mnt/decypharr/__all__/*)
      rel=${old#/mnt/decypharr/__all__/}
      new="/mnt/zurg-staging/__all__/$rel"
      [ -e "$new" ] && ln -sfn "$new" "$link"
      ;;
  esac
done

# What dangles is the renamed class — take the largest non-sample video:
find /data/media -xtype l | while IFS= read -r link; do
  job=$(readlink "$link" | sed 's|^/mnt/decypharr/__all__/\([^/]*\)/.*|\1|')
  find "/mnt/zurg-staging/__all__/$job" -type f \
       \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*' \
       -printf '%s\t%p\n' | sort -rn | head -1 | cut -f2- | \
    xargs -r -I{} ln -sfn {} "$link"
done
find /data/media -xtype l          # want no output
```

The largest-non-sample heuristic is safe because everything that already
resolved was skipped, so only single-payload jobs reach it. Anything still
dangling is a job zurg does not have. Plex sees no change at all.

### Setup B — take over the mountpoint

Because the roots match, moving zurg onto decypharr's mountpoint preserves
every path except the renamed class:

```bash
# Nothing playing, nothing scanning, then:
sudo systemctl stop plexmediaserver
sudo systemctl stop decypharr
mountpoint -q /mnt/decypharr && sudo umount /mnt/decypharr
# set mount_path: "/mnt/decypharr" in zurg's config.yml
sudo systemctl restart zurg
ls /mnt/decypharr/__all__ | head
cat /mnt/decypharr/version.txt
sudo systemctl start plexmediaserver
```

Scan. The renamed releases come back as new items and the old ones land in the
trash; everything else is untouched. Leave the trash alone until you have
spot-checked a few.

Do not delete decypharr, its config, `db/` or `usenet/` state until you are
done — that is your rollback.

## Afterwards

**Automation is where decypharr had more than zurg does.** zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) so Sonarr and Radarr
can hand it an NZB and import from `__magic__` by rename, but it has no
qBittorrent API, so the torrent half of decypharr's ingestion has no
equivalent. Options:

- **NZBs:** turn on `sabnzbd.enabled` and point the \*arrs at zurg. The caveat
  is that zurg does not yet check whether a post's articles are still on the
  news server, so a dead release reports Completed and fails on the first read
  instead of being blocklisted and re-grabbed.
- **Torrents:** the zurg dashboard, DMM, or Plex watchlist acquisition
  (`plex_watchlist_enabled`, needs `dmm_api_key`).
- **Hybrid:** keep decypharr purely as the \*arrs' download client pushing into
  the same debrid accounts, with zurg serving the mount. Both list the same
  account, so zurg picks up what decypharr adds. The \*arr import step then
  needs remote path mapping onto zurg's tree — test one grab first.
