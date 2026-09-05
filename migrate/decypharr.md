---
label: From decypharr
icon: arrow-right
order: 80
---

# Migrating from decypharr to zurg

Read [the shared page](index.md) first. The trash guard lives there. So does
the reason your library lands in `__magic__` rather than in a symlink farm.

decypharr and zurg solve the same problem and their root layouts are strikingly
close. That makes this the migration with the most that carries over for free.

| decypharr | zurg |
|---|---|
| `__all__/<job>/<file>` | `__all__/<name>/<file>` |
| `version.txt` | `version.txt` |
| `__bad__/` | `__unplayable__/` |
| `torrents/` | a `directories:` entry with `not_provider: nzb` |
| `nzbs/<job>/` | a `directories:` entry with `provider: nzb` or the built-in `__nzb__` |

The **debrid side needs nothing**. Both servers list the same accounts and
present the torrent's own filenames. Those paths are identical once zurg sits
at decypharr's mountpoint. Everything below is about the Usenet side.

Two things to settle before you start.

- **Providers.** zurg speaks `realdebrid` and `alldebrid` and `torbox` and
  `nzb`. decypharr additionally supports Debrid-Link and Premiumize and zurg
  has no backend for either. Content held only on those accounts cannot be
  served by zurg. Re-acquire it on a supported account or accept losing it.
- **Do not change decypharr's `folder_naming` before migrating.** It renames
  every folder in the library at once. That breaks every symlink target and
  every mount-direct Plex path in one stroke.

## What differs on the Usenet side

Measured against zurg on the same five releases.

| | |
|---|---|
| zurg gains | `thumbnail.jpg`, the sample clip, the `.nfo`, the `.url` adverts, the archive's inner directory, **and the obfuscated release decypharr dropped** |
| zurg loses | nothing |
| renamed | single-file releases and archive releases |

**Single-file releases** come out of decypharr named after the job. You get
`ToyStory5/ToyStory5.mkv` where zurg keeps the poster's name and serves
`ToyStory5/Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`.

**Archive releases** are the interesting case and worth understanding because
it explains two symptoms at once. decypharr produces this.

```
FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLAfather.brown.2013.s02e05.hdtv.x264-tla.mp4
```

That is the archive's inner directory name and the file's own name concatenated
**with no separator**. It is a path join that lost its `/`. So the missing
directory level and the malformed filename are the same defect rather than two.
zurg reproduces the real structure at
`FatherBrown/Father.Brown.2013.S02E05.HDTV.x264-TLA/father.brown.….mp4`.

**Multi-file releases and season packs keep their real filenames on both
sides.** They match automatically once the folder name matches.

## What your library looks like afterwards

**Everything is re-added** because the library root moves to `__magic__`. See
[the shared page](index.md) for why there is no cheaper path.

The gain is in the names. Every single-payload release comes back under the
poster's filename instead of the job name. So `ToyStory5/ToyStory5.mkv` becomes
`Toy.Story.5.2026.1080p.AMZN.WEB-DL.DDP5.1.H.264-KyoGo.mkv`. That is the string
Sonarr and Radarr and Plex parse for quality and source and group and edition.
Archive releases stop carrying a welded name and sit in the archive's own
directory. Multi-file releases and season packs already read correctly and are
unchanged.

List the releases whose names move.

```bash
MOUNT=/mnt/decypharr
for d in "$MOUNT"/__all__/*/; do
  job=$(basename "$d")
  n=$(find "$d" -type f | wc -l)
  [ "$n" -eq 1 ] && echo "RENAMED BY DECYPHARR: $job"
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

- **Sample clips** inside `Sample/`. This is the one worth configuring for. Set
  [`only_show_the_biggest_file: true`](../reference/config.md) if you do not
  want a 9 MB sample turning up as a second version.
- `thumbnail.jpg` and the `.nfo` and the poster's `.url` adverts. All inert.
- **Obfuscated releases decypharr dropped** arriving as new library items.
  decypharr published nothing at all for a fully hash-named post. zurg resolves
  it to the real release name and serves it.
- Empty folders where an archive chain is broken.

## Get your NZBs back

**decypharr cannot give them to you.** It keeps one compressed binary per job
at `usenet/meta/<uuid>.meta` and a `usenet/nzbs/` directory that was empty on
the bench. There is no documented export. Whether the `.meta` blobs decode back
into NZBs is unverified. Treat the originals as unrecoverable.

What you do have is the job names. On both servers the job folder name *is* the
NZB filename. So the folder list is your shopping list.

```bash
MOUNT=/mnt/decypharr
ls "$MOUNT/nzbs" > nzb-jobs.txt      # the usenet jobs
wc -l nzb-jobs.txt
```

For each job re-fetch the NZB from your indexer by searching the folder name.
Then **rename the file to exactly that name plus `.nzb`** before dropping it in
zurg's `nzbs/` directory. The filename is the folder name and the folder name
is what keeps the path stable.

Two rules while you do it.

- **Skip any release a debrid account already holds.** The symlink resolves
  through the torrent copy. Adding the NZB too makes zurg see two different
  releases with one name and hash-suffix one of them as
  `Some.Release {a1b2c3}`. That breaks whatever pointed at the bare name.
- A release your indexer no longer carries is simply gone. With
  `autoEmptyTrash` at `0` the Plex item survives in the trash until you decide
  to drop it.

## Build zurg alongside

Run zurg beside decypharr on its own mountpoint. Both may list the same debrid
accounts at once because listing is read-only.

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
directories:                         # optional: mirror decypharr's top level
  torrents:
    filters:
      - not_provider: nzb
  nzbs:
    filters:
      - provider: nzb
```

Then check the debrid side lines up before going further.

```bash
ls /mnt/decypharr/__all__      | sort > decypharr-jobs.txt
ls /mnt/zurg-staging/__all__   | sort > zurg-jobs.txt
diff decypharr-jobs.txt zurg-jobs.txt
```

Sometimes the torrent folders differ *systematically*. An extension is present
or absent. The RD rename shows up instead of the original. In that case flip
`retain_rd_torrent_name` or `retain_folder_name_extension` and rescan rather
than fixing anything by hand. Folders only on the decypharr side are the Usenet
jobs plus anything on a Debrid-Link or Premiumize account.

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
one. That is your \*arr library path or the decypharr mount if Plex read it
directly.

**5. Empty the trash** once you have spot-checked a few items. Watch state
comes back through the GUID match. Collections and artwork choices do not.

Leave decypharr running until then. It costs nothing and it is your rollback.
Do not delete its config or `db/` or `usenet/` state either. When you are done
stop it.

```bash
sudo systemctl stop decypharr
```

## Afterwards

**Automation is where decypharr had more than zurg does.** zurg has an opt-in
[SABnzbd-compatible endpoint](../guides/sonarr-radarr.md) so Sonarr and Radarr
can hand it an NZB and import from `__magic__` by rename. It has no qBittorrent
API so the torrent half of decypharr's ingestion has no equivalent. Your
options.

- **NZBs.** Turn on `sabnzbd.enabled` and point the \*arrs at zurg. The caveat
  is that zurg does not yet check whether a post's articles are still on the
  news server. So a dead release reports Completed and fails on the first read
  instead of being blocklisted and re-grabbed.
- **Torrents.** Use the zurg dashboard or DMM or Plex watchlist acquisition.
  That last one is the `watchlist:` block, which searches your own Newznab indexers.
- **Hybrid.** Keep decypharr purely as the \*arrs' download client pushing into
  the same debrid accounts with zurg serving the mount. Both list the same
  account so zurg picks up what decypharr adds. The \*arr import step then needs
  remote path mapping onto zurg's tree. Test one grab first.
