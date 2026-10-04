---
label: Watchlist and Seerr
icon: inbox
order: 58
---

# Acquisition sources

Plex watchlist, [Seerr](https://github.com/seerr-team/seerr),
[Radarr](https://radarr.video) and [Sonarr](https://sonarr.tv) feed the same durable engine. Adapters discover requests and resolve media IDs. The engine
owns progress, retries and acknowledgement. The shared executor selects releases
from Newznab indexers, saving NZBs for zurg's Usenet backend, and from Torznab
indexers, handing info hashes to a debrid account that already holds them: see
[Newznab and Torznab](#newznab-and-torznab). Nothing is acknowledged until
the grab has been checked. An NZB is put to the news servers. A torrent has to
show up in the library with files in it. See
[Verifying a grab](#verifying-a-grab).

## Configuration

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 40
  max_season_size_gb: 100
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__
      check_every_secs: 60
```

Run this on a zurg instance with an `nzb` provider, a debrid account that takes
torrents, or both. NZBs from Newznab indexers land in its `nzbs/` directory.
Torrents from Torznab indexers go to a debrid account. They are added only when
that account already has them cached. With neither kind of account the sources
do not start. The acquisition page says why. Plex needs the existing
`plex_token`. Seerr needs its base URL and API key, independently of any Plex
settings in zurg. URL subpaths and
URLs ending in `/api/v1` are supported. Radarr needs its base URL (a URL base
such as `/radarr` and a trailing `/api/v3` are fine), its API key from
**Settings > General**, and `library_path` when it sees zurg's mount at a
different path: see [Radarr behavior](#radarr-behavior). Sonarr takes the same
three settings: see [Sonarr behavior](#sonarr-behavior).

`concurrency` applies at the next poll, without a restart. `indexer_concurrency`
covers searches and NZB downloads together, because an indexer meters the key
and not the endpoint. It is read when zurg starts. Indexer keys are often
shared, and three calls per key is what measured safe on keys that also serve
another application.

Keep names and Seerr URLs stable: they identify saved queues. Rotating a Seerr
key retains its queue. Restart after adding sources or changing their URL or
credentials. Existing `watchlist:` and `plex_watchlist_enabled` settings keep
working through an automatic `plex-watchlist` adapter. An explicit
`plex_watchlist` source, even disabled, supersedes the legacy enable switch.
Only one Plex source can use the configured Plex account. Shared search
settings fall back to `watchlist:` and its existing defaults; omitted indexers
fall back to watchlist/Stremio indexers.

## Excluding releases by name

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

`exclude_words` lists words that no acquired release may have in its name.
Use it to keep Dolby Vision or HDR10+ off a player that cannot show them
while still taking 4K. It applies to every source alike: the Plex watchlist,
Seerr, Radarr and Sonarr. It applies to Usenet and torrent results alike. A
release it excludes is never fetched, saved, added to a debrid account or put
to Radarr or Sonarr. Leave it out to exclude nothing. zurg reads it at
startup like the rest of `config.yml`.

How a name is matched:

- **Whole words only.** A name is read as words made of letters and digits.
  Dots, spaces, dashes, underscores, brackets and parentheses all separate
  words. Case does not matter. `DV` excludes
  `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` and
  `Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD`. It does not
  exclude `DVDRip`, `DVD9`, `Come and See DvD 1` or a title such as
  *Adventures*, because none of them has the word DV.
- **Phrases match in order.** `Dolby Vision` or `DV HDR` matches those words
  next to each other in that order, whatever separates them.
- **A trailing `+` is part of the word.** `HDR10+` is its own word. Excluding
  `HDR10` leaves HDR10+ releases alone and excluding `HDR10+` leaves plain
  HDR10 alone. List both to exclude both. A `+` between two words separates
  them, as in `DD+7.1` or `DV+HDR10`.
- **Two families of spellings count as one word.** Any one spelling in the
  list excludes every spelling of its family.

  | Write any of | Excludes names with any of |
  |---|---|
  | `DV`, `DoVi`, `Dolby Vision`, `DolbyVision` | `DV`, `DoVi`, `Dolby.Vision`, `Dolby-Vision`, `Dolby Vision`, `DolbyVision` |
  | `HDR10+`, `HDR10Plus` | `HDR10+`, `HDR10Plus` |

  Nothing else is aliased. `HDR` excludes names with the word HDR and not
  `HDR10`, `HDR10+` or `HDRip`. `WEB-DL` matches `WEB-DL`, `WEB.DL` and
  `WEB DL` and not `WEBDL`.
- **Only the release name is read.** That is the title the indexer answers
  with, before anything is downloaded. The files inside are not read. A Dolby
  Vision release whose name does not say so is not excluded.

Excluding a word never touches resolution. With `DV` excluded a 2160p release
with plain HDR or HDR10 is still taken, and `quality: 4k` still puts 2160p
first. An excluded release counts as not found. A search keeps paging until it
has enough releases it may take. A title whose every release is excluded fails
with "no eligible releases", just like one whose every release is over
`max_size_gb`, and is tried again later. A Seerr 4K request takes only 2160p
releases, so it waits when every 2160p release is excluded.

### Exclusions and Radarr or Sonarr profiles

With a `radarr` or `sonarr` source the exclusion comes first. An excluded
release is never put to Radarr's or Sonarr's parser. No custom format score
brings it back, and it does not count as a refusal by the profile. Every other
release is judged by the profile as described under
[Radarr behavior](#radarr-behavior) and [Sonarr behavior](#sonarr-behavior). A
release has to pass both. A custom format that scores Dolby Vision below the
profile's minimum does the same job inside the *arr, and keeping it does no
harm.

Upgrades follow the same rule. If the only releases that would lift a file to
its profile's cutoff are excluded, the file stays below the cutoff and zurg's
upgrade pass keeps looking without taking anything. That happens when a
custom format gives Dolby Vision a high score and the cutoff score needs it.
Lower the cutoff score or take that score off the custom format.

When Radarr or Sonarr use zurg as a download client through the `sabnzbd:` or
`qbittorrent:` block, they search their own indexers and pick the release
themselves. `exclude_words` does not apply there. Exclude the same words in
the *arr with a custom format scored below the profile's minimum or a release
profile's **Must Not Contain**.

## Seerr behavior

The adapter follows seerr-team/seerr's
[request routes](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts),
[status definitions](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)
and [API contract](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml).

- Polls all pages of approved requests using `X-Api-Key`. Failed pages preserve
  the previous queue and pause that source's work.
- Rechecks approval before acquisition. Pending, declined, failed, completed,
  removed and already available requests do not initiate grabs.
- Resolves IDs through Seerr. TV acquisition is restricted to approved requested
  seasons and their known aired episodes. A partial season stays pending.
- Treats 4K and non-4K separately. A 1080p release cannot satisfy a 4K request.
- Rechecks open requests every 30 minutes after successful acquisition to find
  newly aired episodes in requested seasons. Unannounced episodes become work
  only once they appear in Seerr's metadata.
- Prefers packs after all known episodes have aired. Airing seasons use loose
  episodes. Specials (season 0) are unsupported and stay pending.
- Makes no request-status or availability writes. Seerr's media-server scan
  reports actual availability and notifies requesters. Saving an NZB does not
  prove it is indexed or playable, which is why the engine checks it before
  counting a season acquired.

Configure Seerr's library scan to include the library served by this instance.
If Sonarr/Radarr already acquire the same requests, disable that overlapping
workflow before enabling this adapter. The adapter does not emulate an *arr
server or change Seerr's service setup. Polling provides restart recovery;
no webhook is required.

## Radarr behavior

Radarr keeps the list and owns the library. zurg does the searching and the
downloading. Radarr never searches and never grabs: zurg reads what Radarr
wants, picks a release from its own indexers, checks it with the news servers
or the debrid account that holds it, puts the video in the movie's folder
inside `__magic__` and asks Radarr to rescan that one movie. Nothing is copied: the video is a file in
zurg's library that Radarr now sees in its folder.

### Setting up Radarr

1. **Root folder inside `__magic__`, one level down.** For example
   `/mnt/zurg/__magic__/movies`. Not `__magic__` itself, and not
   `__magic__/__all__`, which lists every release in the library. A movie
   whose folder is anywhere else is skipped, with one warning in zurg's log.
2. **Import lists with search on add off.** Add movies however you like (by
   hand, lists, Seerr pointed at Radarr). Leave **Search for Movie** off
   when adding, since zurg does the searching.
3. **No indexers and no download client are needed.** If Radarr has them,
   it can grab alongside zurg, so turn off automatic search on its indexers
   (or remove them) for the movies zurg looks after.
4. **`library_path` is where Radarr sees `__magic__`.** When Radarr runs on
   the same machine as zurg and sees the mount where zurg mounts it, leave
   it out: it defaults to zurg's `mount_path` plus `/__magic__`. When Radarr
   runs in a container that mounts zurg somewhere else, set it to that path,
   for example `/data/zurg/__magic__`. A movie at
   `/data/zurg/__magic__/movies/Heat (1995)` is then placed in
   `movies/Heat (1995)` inside zurg's `__magic__`. Windows paths such as
   `Z:\__magic__` work too.

   If Radarr also takes grabs from zurg's [SABnzbd](sonarr-radarr.md) or
   [qBittorrent](sonarr-radarr-torrents.md) endpoint, it has to see their download
   folder at `library_path/__all__`, through the same volume as its root
   folders, or every import out of it is a copy of the whole file. zurg
   asks Radarr where it sees both and says so on the acquisition page, in
   its log and in `zurg doctor` when they cannot share a mount; see
   [One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### What zurg asks Radarr for

Every poll reads Radarr's movie list and acts on each movie that is
monitored, **available** by the movie's minimum availability, and either has
no file or has one below its quality profile's cutoff while the profile
allows upgrades. Below the cutoff means below the cutoff quality or below the
cutoff custom-format score, as Radarr counts it. An unreleased film such as a
movie dated months ahead waits until Radarr says it is available.

Each candidate release zurg is about to inspect is put to Radarr's own parser
(`/api/v3/parse`) and judged by the movie's quality profile, so what zurg
accepts is what Radarr would have accepted:

- **It must be this movie.** Radarr has to match the title to the same movie.
  An indexer's ID search returns other films (a search for *Psycho* returned
  *Ed Gein: The Real Psycho*), and a title Radarr matches to nothing is
  refused. A year in the title more than one away from the movie's is refused
  too.
- **The profile's allow-list and minimum score apply first.** The parsed
  quality must be allowed by the profile, the custom-format score must reach
  the profile's minimum, and the size must fit the quality's limits in
  **Settings > Quality** for the movie's runtime.
- **Upgrades head toward the cutoff later.** A movie without a file takes any
  release that passes the checks above. Once it has a file below the cutoff,
  only a better release is taken: a higher quality in the profile's order
  while the file is below the cutoff quality, or a higher custom-format score
  (by at least the profile's upgrade step) while it is below the cutoff
  score. A lower quality is never taken. PROPER and REPACK releases of the
  same quality are not treated as upgrades.

The profile is applied to the release zurg is about to take as an allow-list:
the right movie, an allowed quality, the minimum score and the size limits.
By default its order of preference is not used to pick among the releases it
allows. zurg takes the first allowed release that is cheapest to check, trying
web releases (WEB-DL, WEBRip) before Blu-ray ones and those before the rest,
because web releases are the ones most often posted as a single video file.
If the profile prefers something better than what arrives and allows
upgrades, Radarr sees the movie's file below the cutoff, and zurg's upgrade
pass looks for the better release once the movie has one. The first file
arrives quickly, and the profile's order is served by the upgrade. Set
`best_first: true` to have the first grab follow the profile's order instead.
See [Taking the profile's best first](#taking-the-profiles-best-first).

When a search by the movie's IMDb or TMDB id answers nothing at all, zurg
searches again by title and year, as Radarr does. Many posts, small
documentaries especially, are indexed with no id at all. Radarr's parser
decides whether each result is the movie, so a film of the same name is
refused like any other wrong match.

Radarr is asked about a release only when zurg is about to inspect it, one
release at a time, so a movie with a single-file release costs one to three
questions. Nothing more is asked once a direct post is saved. A title naming a
resolution the profile has no allowed quality for, such as a 2160p release for
an HD-1080p profile, is refused without asking Radarr at all. A title naming
no resolution, or more than one, always goes to Radarr, and so does every
title when the profile allows a quality whose name states none (SDTV, DVD,
Unknown, Raw-HD, BR-DISK). zurg makes at most eight calls to one Radarr at
once.

If Radarr cannot be reached, nothing is decided: the movie waits for the next
poll, and no release is set aside because Radarr did not answer.

### Placing the file

Once a release has been checked, zurg puts its video in the
movie's folder the way Radarr would have imported it, by moving it inside
`__magic__`. Nothing is copied or downloaded.

- **The largest video is the one placed.** That is the largest `.mkv`, `.mp4`,
  `.m4v`, `.avi`, `.mov` or `.ts` file in the release. For a release served
  out of one archive it is the largest video inside the archive. Samples,
  featurettes, subtitles and `.nfo` files stay in `__magic__/__all__`. The
  file keeps the name it has in the release.
- **It is refused before it is moved if it cannot be read.** This is the check
  a Sonarr or Radarr import through the mount gets. A release whose articles
  the news servers no longer hold, or whose archive will never open, is set
  aside like a dead post, and the next candidate is tried. A release that
  cannot be read right now, such as one on an account that is cooling down,
  is tried again later.
- **Radarr keeps one file per movie, so an upgrade replaces the old file.**
  When the new video is in the folder, every other video zurg's library put
  there is hidden from the folder. Hidden means tombstoned, as a delete
  through the mount is: the old release stays in `__all__` and on its
  account. A real file you put in the folder yourself is left alone. The old
  file goes after the new one is placed, so a placement that fails leaves the
  movie with the file it had.
- **Radarr rescans afterwards.** zurg tells the mount which folders changed,
  so the rescan does not read a folder the mount still remembers as empty,
  and then asks Radarr to rescan that one movie.

A Radarr source needs `__magic__` (`magic.enabled`). Without it the source does
not start and says so in the log and on the acquisition page.

### What Radarr shows

**Activity** stays empty: no queue entries and no grab or import events,
because Radarr grabbed nothing. The movie simply has a file after the rescan
zurg asks for, and its quality and custom formats are Radarr's reading of that
file. zurg's log records each movie it completes.

`only_new_items` and `remove_after_grab` do nothing for a Radarr source.
Radarr's wanted movies are work, like Seerr's approved requests, and Radarr
decides when a movie stops being wanted. Keep the source's `name` stable: it
identifies the saved queue, while the URL and key can change freely.

## Sonarr behavior

Sonarr works the way Radarr does. Sonarr keeps the list and owns the library.
zurg does the searching and the downloading. Sonarr never searches and never
grabs. zurg reads the episodes Sonarr is missing and picks a release from its
own indexers. It checks the release with the news servers or the debrid
account that holds it, and puts each episode's video in the series' season folder inside `__magic__`. Then it asks
Sonarr to rescan that one series. Nothing is copied.

### Setting up Sonarr

1. **Root folder inside `__magic__`, one level down.** For example
   `/mnt/zurg/__magic__/tv`. A series whose folder is anywhere else is
   skipped with one warning in zurg's log.
2. **Search on add off.** Add series however you like. Leave **Start search
   for missing episodes** off, since zurg does the searching.
3. **No indexers and no download client are needed.** If Sonarr has them it
   can grab alongside zurg, so turn off automatic search on its indexers for
   the series zurg looks after.
4. **`library_path` is where Sonarr sees `__magic__`.** It works exactly as
   it does for Radarr, including the check that Sonarr reaches zurg's
   download folder and its root folders through one volume. Leave it out
   when Sonarr sees the mount where zurg mounts it.

### What zurg asks Sonarr for

Every poll reads Sonarr's missing episodes. Those are monitored episodes of a
monitored series that have aired and have no file. zurg groups them by season
and works on each season as one piece of work.

- **A whole season that has finished airing may come as a pack.** When every
  episode of a season is missing and none is still to air, a season pack is
  tried first. Otherwise the season's missing episodes are taken one by one
  from the season's search results. A season with some of its files already
  never takes a pack. That would put a second copy of those episodes in the
  folder.
- **A new episode is new work.** When next week's episode airs, the season is
  listed again with that episode. zurg does not search again for the
  episodes it already has.
- **A deleted episode is wanted again.** When Sonarr lists an episode zurg
  already acquired, zurg looks in the season folder. If no video for that
  episode is there any more, it is searched for again. If one is, Sonarr has
  not rescanned yet and nothing is searched.
- **Upgrades are per file.** An episode file below its quality profile's
  cutoff is an upgrade, while the profile allows upgrades. Below the cutoff
  means below the cutoff quality or below the cutoff custom format score.
  Sonarr's own Cutoff Unmet list only counts the quality. On Sonarr 4.0.20 a
  file at the cutoff quality that scores 0 of a cutoff score of 40 is not on
  it. zurg counts both, as Sonarr's own upgrade rule does. A file holding two
  episodes is one upgrade for both.
- **Specials are skipped.** So are daily series and anime series. A daily
  show's episodes are dates, and anime is released under absolute episode
  numbers. zurg searches by season and episode, so it cannot find either
  yet. Each skipped series gets one warning in the log.

Each candidate release is put to Sonarr's own parser (`/api/v3/parse`) and
judged by the series' quality profile. What zurg accepts is what Sonarr would
have accepted.

- **It must be this series and this season.** Sonarr has to match the title
  to the same series. A title Sonarr matches to nothing is refused.
- **A pack must be the whole season.** A partial pack is refused. A pack
  spelled as a range, such as `Season 1 E01-E07`, counts when the range is the
  whole season. A pack of several seasons counts for each season it names
  (see [Packs of several seasons](#packs-of-several-seasons)). Sonarr reads
  `S01-S05` as season 1 alone and never says where it ends, so zurg reads the
  range from the title. Sonarr must still match it to the series and call it
  a full, multi-season pack. Its size is judged against the runtime of every
  season it names.
- **An episode must be that one episode alone.** A release holding two
  episodes is refused for a single episode.
- **The profile applies as it does for Radarr.** The quality must be allowed.
  The custom format score must reach the profile's minimum. The size must fit
  the quality's limits in **Settings > Quality** for the runtime of the
  episodes the release holds. An upgrade must beat the current file by
  Sonarr's rules.

Which allowed release comes first is decided differently from Radarr. A
season pack is tried before the loose episodes because it is one grab where
they are several. Among the releases Sonarr allows zurg takes the one its
`quality` setting ranks first. With `best` that is the highest resolution and
then the largest. So a finished season with a 1080p pack is filled from that
pack even when the same search holds every episode in 2160p. The upgrade pass
then replaces it episode by episode. A pack larger than `max_season_size_gb` is
never a candidate. `best_first: true` changes both. See
[Taking the profile's best first](#taking-the-profiles-best-first).

A title naming a resolution the profile has no allowed quality for is refused
without asking Sonarr. zurg makes at most eight calls to one Sonarr at once.
If Sonarr cannot be reached nothing is decided. The season waits for the next
poll and no release is set aside.

### Placing the files

Once a release has been checked, each episode's video goes in
the season folder. That is the folder the season's existing files are in. For
a season with no files yet it is the folder Sonarr's **Season Folder Format**
names, such as `Season 1`. A series set not to use season folders gets its
files in the series folder.

- **Each episode gets its own video.** The video is found by the episode
  number in its name. A pack places every episode it was taken for. Samples
  and `.nfo` files stay in `__magic__/__all__`.
- **A pack missing an episode is refused before anything moves.** It is set
  aside like a dead post, and the next pack or the loose episodes are tried.
- **A loose episode whose file names nothing gets the release's largest
  video.** Obfuscated posts often look like this.
- **An upgrade replaces only its own episode.** The old video of that episode
  is hidden from the season folder once the new one is in. The other
  episodes in the folder are left alone. Hidden means tombstoned, as it does
  for Radarr.
- **Sonarr rescans afterwards.** zurg tells the mount which folders changed
  and asks Sonarr to rescan the series.
- **One missing episode does not hold the rest back.** When an episode has no
  release zurg can take yet, the episodes it did find are still checked and
  placed. Sonarr is asked to rescan for them straight away. The missing one is
  looked for again on the usual retry schedule.

A Sonarr source needs `__magic__` (`magic.enabled`). Without it the source does
not start and says so in the log and on the acquisition page.

**Activity** in Sonarr stays empty, as it does in Radarr. The episodes simply
have files after the rescan zurg asks for. `only_new_items` and
`remove_after_grab` do nothing for a Sonarr source.

## Packs of several seasons

A season can be taken from a pack that holds several, such as
`Game.of.Thrones.S01-08.BDRip.1080p` or `Breaking Bad Season 1-5`. Indexers
file such a pack under every season it covers. On DMM's feed, 72 of the 691
results for Breaking Bad season 3 were packs of several seasons. For some
seasons one of them is the only copy an account holds.

- **The title says which seasons.** `S01-S05`, `S01-05`, `[S01-08]`, `S1-9`,
  `Seasons 1-8`, `Season 1 to 5`, `Season 1 · 2 · 3`, `Stagioni 01-05` and
  `Temporadas 1-4` are all read. A title with no season numbers, such as
  `Complete Series`, is not taken. Neither is one that names a single season
  only as a word, such as `Season 3 Complete`. Those were never read as packs.
- **Only that season is placed.** A pack taken for season 4 puts season 4's
  episodes in the season folder. The other seasons' files stay where the
  library lists them. A pack whose files do not hold every episode of the
  season is refused before anything moves, whatever its title claims.
- **The size ceiling is per season.** `max_season_size_gb` applies to each
  season the pack names. A 346 GB pack of eight seasons is 43 GB a season, and
  fits under the default 100.
- **Quality still comes first.** Packs rank like any other release:
  resolution, then size. A 2160p pack of one season is taken before a 1080p
  pack of eight. Within one resolution, a pack of several seasons is usually
  the largest, so it is usually tried first.
- **The show's other seasons take the same pack.** Once one season has taken
  a pack of several seasons, the show's other seasons try that pack first,
  ahead of every pack of the same resolution their own search found. It is
  already on the account, so it costs nothing. While a show's seasons are
  choosing among packs of several seasons, they choose one at a time, so
  seasons asked for together (a Sonarr series, all its seasons on one poll)
  do not each settle on a different copy of the show. Once one of them has
  chosen without such a pack, because none was on the account or the profile
  allowed none, the rest choose at once. A season asked for an hour later
  searches afresh.

## Watching it work

The dashboard's **Acquisition** link opens `/acquisition/` on zurg's own port.
Each source gets a line with how many of its titles are done, running,
waiting, set aside and queued, beside the number of titles zurg works on at
once, the calls it makes to one indexer at once and the news connections its
`nzb` accounts are allowed. Below that each source has a table with a row per
title. A row shows the state, what a running title is doing right now (the
search, how many results have been judged and allowed so far, the candidate
being inspected, the check against the news servers, the placement), its attempts, the release chosen with the quality and score
the source gave it, where it was placed, and when a waiting title is tried
next. The page refreshes itself every five seconds. The same snapshot is at
`/acquisition/status.json`. When no source is enabled, or acquisition is
configured but paused, the page says so and why.

Each movie a release is chosen for gets one line in the log, for measuring
where the time goes:

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` is what the search returned, `local_refusals` the results refused
without asking the source, `radarr_refusals` those the source's own rules
refused, `inspected` the NZBs read, `radarr_calls` the questions put to the
source (the NZBs read plus the refusals on the way to them, when the source is
Radarr), and the time runs from the start of the search. Releases refused
without asking are logged one by one at debug level only.

## Finding duplicate releases

An upgrade leaves the release it replaced in your library. With
`magic.allow_delete` off, Radarr's or Sonarr's delete of the old file only hides
it in `__magic__`, so the old release stays in `__all__` and on its account.
Grabs from more than one indexer, or a season pack beside loose episodes, leave
several releases of the same thing too. **Manage > Duplicates**
(`/manage/duplicates/`) lists them, says which one Radarr or Sonarr is using,
and lets you delete the others. It never deletes anything by itself.

**Which release is in use is read from paths, not names.** Every file Radarr and
Sonarr hold is named by a path under `__magic__`, and zurg knows which release
each path comes from, because the move that put the file there wrote it down.
The view reads every file each \*arr has imported, monitored or not, at its
cutoff or not, and traces each one to its release. A Sonarr file is traced
episode by episode, so a season pack Sonarr takes three episodes from shows
as in use for those three.

**Which releases might be copies is a guess, and says so.** Releases are
grouped with a movie, or with a season, when:

- an \*arr file is in them,
- the \*arr's history says it imported from them, or that a file from them went
  missing from disk,
- zurg identified them as the movie's or the series' IMDb id, or
- their name reads as the title and year (a year off by one, or Radarr's second
  year for the movie, still counts) or as the series and season.

Each release lists which of these put it in the group. A season is only a
group where releases hold the same episode: sixty single-episode releases of
one season are sixty different episodes. A season group lists the episodes more
than one release holds, which release holds each, which one Sonarr's file is
in, and how many episodes each release holds that nothing else in the group
does. No release is picked as the winner. Releases no Radarr or Sonarr item
matches are under **Name matches only**, grouped by their names and IMDb ids.

**Each release is In use, No reference found or Unknown.**

| State | Meaning |
|---|---|
| In use | A file Radarr or Sonarr holds right now is in this release. It cannot be selected. |
| No reference found | Every configured Radarr and Sonarr was read in full, and none of their files is in this release. Plex, Jellyfin and other clients reading the mount are not visible here, so this is not proof nothing plays it. |
| Unknown | zurg cannot tell. Every release is Unknown while an \*arr cannot be read, while the library is still loading, or with `__magic__` off. A release is also Unknown when an \*arr file for the same movie or episode cannot be traced to any release, or when the \*arr's history shows a file from this release went missing from disk and the movie or episode has had no file since. |

**Quality is shown in the profile's terms.** For a release the \*arr uses, it is
the \*arr's own grade of the file. For one it imported before, it is the grade
it gave then. Otherwise it is read from the release name and says so. Each is
placed in the item's quality profile, for example "rank 15 of 17 in 4K or best
available (cutoff at 17)".

**Deleting re-reads first.** Select releases and choose **Check again and
delete**. zurg reads every \*arr's current files again, and only then offers
the delete. A release that has come into use since the page loaded is left out,
and an Unknown release is only deleted if you tick it again in that dialog. The
delete itself is the manage page's bulk delete, which removes every copy of the
release from every account that holds it.

**When it reads.** Opening the page the first time reads every Radarr and Sonarr
under `acquisition.sources`, including the import and deletion history. Reading
a large library's history can take a minute. After that the page shows what was
last read and when, until you choose **Read Radarr and Sonarr again**. A source
with `enabled: false` is still read: switching acquisition off does not change
what that \*arr holds. The page shows each source's counts: files read, traced to
a release, on a path outside its `library_path`, and inside `__magic__` but
leading to nothing. If not one of a source's files traces to a release, check
its `library_path`.

The same report is at `/manage/duplicates/report.json`, and
`POST /manage/duplicates/check` with `{"hashes": [...]}` re-reads the \*arrs and
answers each release's state.

## Newznab and Torznab

An indexer entry says which it is with `type`. Absent means `newznab`, which is
what every entry written before this existed meant. The query is identical for
both; the answer is not. A Newznab result is an NZB, fetched and written to
`nzbs/` for the Usenet backend. A Torznab result is an info hash, handed to a
debrid account. A Torznab result carrying no magnet or `infohash` attribute is
skipped: zurg never downloads a `.torrent`, so a result it can only reach that
way is not one it can act on.

**A torrent is only ever added to an account that already holds it.** Every
account that takes adds is offered the hash, because the caches are independent
and one account having purged a release says nothing about the next. The first
that already has it takes it. A miss everywhere is an ordinary failed
candidate, so the walk moves down the ranking to the next release, which may be
another torrent or an NZB.

zurg adds the torrent and watches it for up to 20 seconds. Cached content is
ready within a second or two. Anything still downloading after that is removed
again. So no download is ever left running on the account. A miss is not quite
free though. It can still count against the account's limit on adds. On TorBox
it uses one of the 60 uncached adds allowed per hour.

The account marked `watchlist: true` is offered the torrent first. The rest
follow in the order of your `providers:` list. An account marked
`add_torrents: false` is never offered one.

`prefer` decides which kind is reached for first when both could satisfy a
target. `usenet` is the default, because a Usenet grab costs a download while a
torrent spends one of the account's add slots, and because it is what the
feature did before it could take a torrent at all. `torrents` reverses it, and
`best` drops the distinction and takes whatever the ranking puts first.

A movie tries up to three torrents per attempt. Each one costs an add. Up to
24 of its NZBs are inspected on their own, as
[choosing a movie's release](#choosing-a-movies-release) describes. With
`usenet` the NZBs are tried before any torrent. With `torrents` the torrents
come first. With `best` each torrent waits its turn in the ranking. The NZBs
are tried together at the place of the best one. A season pack tries three
releases per attempt of either kind. So does each loose episode.

The verification a grab waits on differs with the source. A Usenet release is
put to the news servers, which is the only way to know whether the post is
still there. A torrent was added only because the account said it already held
the content, so what is left to establish is that the release reached the
library with files in it; that is what the check asks, and a release the
account lists empty is set aside like a dead post.

An install with no `nzb` provider can still run acquisition from Torznab
indexers alone. Its Newznab indexers are not searched there, because nothing on
that install can play an NZB. The log says so once for each of them. An
install with no account that takes torrents does not search its Torznab
indexers, the same way. Either way, a release of a kind the install has
nowhere to put is never a candidate, so it uses up none of the releases an
attempt tries, and a source such as Radarr is never asked about it.

## Choosing a movie's release

A movie's Usenet candidates are tried in order of what they cost to confirm,
not only of how good they are. A post holding one named video costs zurg two
article reads and is usually complete; a forty-volume archive set costs a
sizing pass and a read at both ends of every volume, and about two thirds of
the multi-volume remux sets on the indexers are gone. The indexer's own
`files` count predicts the shape, so candidates are ordered by it: ten files or
fewer, then up to thirty, then more, then unknown, and by the count within
each band. Among posts of equal cost, when a source such as Radarr judges
releases by a profile of its own, a title naming WEB-DL or WEBRip comes first,
then Blu-ray, then the rest, and the larger post first within each. The
source's own ranking is not used here, because it is only known by asking the
source, and zurg asks about a release only when it is about to inspect it.
Without a source, the quality ranking and then size decide. Where no source
judges the candidates, the resolution the `quality` setting asks for comes
ahead of cost, so a watchlist set to `best` still gets the best resolution on
offer, cheapest post first within it. Results titled after one part of a split
post (`[1/9] "Movie.part1.rar"`) are never candidates, and of two posts under
one name only the one with fewer files is kept, because the library can hold
only one of them.

Up to 24 candidates are then inspected: each NZB is fetched and read with
zurg's own parser. A post with at most two content files, one of them a named
`.mkv`, `.mp4`, `.m4v`, `.avi`, `.mov` or `.ts` video of at least 500 MB, is a
direct post; PAR2 volumes and sidecars such as `.nfo`, `.sfv`, `.srr`, `.nzb`,
images, `.txt`, `.url` and `.exe` do not count as content. The first direct
post is saved at once. Archive posts are held back until the direct ones in
view run out, then tried with the fewest volumes first, through a gate that
lets no more than six archive releases wait on the news servers at once. A post
holding nothing but repair data and sidecars is never saved. The NZBs inspected
are remembered in memory, so when a saved release is found dead and the title
is tried again, the next candidate is reached without fetching the earlier
ones a second time. Searches and NZB downloads share one limit of requests in
flight per indexer, and an indexer answering `429` or `503` is asked again
after a pause, its `Retry-After` honoured. The dashboard shows each step: the
search, which candidate is being inspected, and what was saved. Series use the
earlier walk: the three best-ranked releases that are not set aside. When the
source judges releases, as Sonarr does, each one is put to it first, and a
release it refuses costs none of the three. `best_first` changes the order of
both walks as the next section describes.

## Taking the profile's best first

```yaml
acquisition:
  best_first: true
```

Off by default. Turned on it makes a Radarr or Sonarr source's first grab
follow the quality profile's order of preference instead of what a release
costs to check. The Plex watchlist and Seerr have no profile and are not
affected. The acquisition page says when it is on.

- **The profile's best resolution goes first.** Each release is placed by the
  resolution its title names. Its place is the best quality the profile allows
  in that resolution. zurg reads this from the profile it already holds and
  asks Radarr and Sonarr nothing more. WEB-DL and Blu-ray and remux of one
  resolution share a place. Within a place a movie still takes the release
  that is cheapest to check. A series takes the one `quality` ranks first. A
  title that names no resolution goes last.
- **The cutoff counts as the top.** While the profile allows upgrades every
  quality at or above the cutoff counts the same as the cutoff. The upgrade
  pass would never replace any of them. A profile that upgrades until WEB 1080p
  gains nothing from best first even if it also allows 2160p. A profile that
  does not allow upgrades keeps its whole order. Its first file is the one it
  keeps.
- **It falls back down the profile.** A release whose NZB cannot be fetched or
  read is passed over. One the news servers turn down is set aside as before.
  The next release in the profile's order is tried. One attempt still reads no
  more than 24 NZBs in all whatever their place.
- **It comes before the Usenet or torrent preference.** A 2160p torrent that an
  account already holds is taken before a 1080p NZB. `prefer` still decides
  between an NZB and a torrent of the same place.
- **A season pack has to be as good as the loose episodes.** A pack ranked
  below a loose episode from the same search is passed over. The episodes are
  then taken one by one. Sonarr makes the same choice. Only that one search is
  compared. An episode is not searched for again on its own in case a better
  release of it exists.

It has a cost. The top of a 2160p profile is mostly remux and Blu-ray sets of
forty volumes or more rather than single video files. Such a set takes longer
to check. It is more often gone from the news servers. It also waits for a
place at the archive gate. So the first file usually arrives later. A title
whose best releases are all gone has each of them grabbed and checked and set
aside before zurg moves down the profile. A season taken as loose episodes is
several grabs where a pack would have been one. What it saves is the second
grab. A first file at the cutoff is never upgraded.

## What acquiring does to the source's own list

A Plex watchlist is a list somebody curated, and it is the only record that
they wanted a title — Plex keeps no history of a removed entry. Two settings
decide what zurg is allowed to do with it. Both apply to `plex_watchlist`
sources; Seerr and Radarr sources own no list zurg writes to, so both are
inert there.

`remove_after_grab` (default `true`) takes an acquired title off the watchlist
once the release behind it has been checked. That is what the feature has
always done: the watchlist is read as a queue of things to get, and a title
zurg has got is done with. Set it to `false` and the watchlist stays a
watchlist — a durable list to browse, which zurg satisfies in the background
without editing. Leaving a title in place costs nothing to re-check: the
receipt already covers it, so no indexer is asked about it again.

`only_new_items` (default `true`) adopts whatever the list already holds the
first time a source runs, and acts only on what is added afterwards. Enabling
the feature should start watching a list, not spend an evening working through
everything on it. Set it to `false` to treat the existing list as a backlog.

It applies **once, at a source's first run**. A source that already has a queue
has been running, and that queue — not this switch — records what it has and
has not done, so turning it on later never drops a backlog already in flight.
An adopted title stays adopted for as long as it stays listed; removing it and
adding it again is an ordinary new request.

## Verifying a grab

A saved NZB is not a release. The indexer answering, the answer parsing as an
NZB and the file reaching `nzbs/` are facts about the indexer, not about the
post. So each acquired NZB is put to the configured news accounts before the
engine acknowledges the request. They are asked about the start and the end of
every content file. That is the first sixteen articles and the last one. It is
the same check `/api?mode=addfile` makes for Sonarr and Radarr. Three answers, and keeping them apart is the whole
point:

- **Articles gone.** The grab does not count. The receipt is reopened, so the
  target is wanted again, and the release is recorded as dead for 30 days so
  the next attempt ranks the next candidate rather than settling on the one
  already in the library. A release on that list is not a candidate: it is not
  fetched, and it does not spend one of the candidates an attempt tries,
  so a run of dead posts at the top of a ranking is walked through instead of
  putting everything under it out of reach. A dead season pack puts its whole
  season back to being wanted; the loose episodes are taken instead.
- **The accounts could not be asked.** A pool that is down, an account
  throttling, or the ordinary case of a library that has not listed the new NZB
  yet. Nothing was established, so nothing is decided: the request is looked at
  again in twenty seconds, then after 40 and 80 seconds, then every two
  minutes, and the wait costs it no retry attempt. A check that simply ran out
  of time is not this case: it is started again at once with its full time, up
  to three times, before it waits. Twenty checks
  across two hours that establish nothing set the release aside the way a dead
  one is, and the next attempt tries another release. The request is never
  acknowledged on a release nobody could check.
- **The release is there.** The receipt drops what it was holding and the
  acknowledgement goes ahead.

The check waits until zurg has finished learning the release's exact file
sizes, or has given up on them, which is the same point the SABnzbd endpoint
checks at. Learning the sizes reads the first article of every file, and so
does the check, so running both at once only made both slower: on a list of 99
movies, checking each release the moment it was listed put the last file in
Radarr's folder after almost nine minutes. A check still waiting for sizes
when its time runs out is started again at once, like a check that ran out of
time. A release still being sized after 30 minutes is checked anyway. No more
than six releases are checked at the same time, and the rest wait their turn.

The check only reads. It moves no article bodies into the cache and records
no dead articles, so it cannot silence a file that plays. When the sizing pass
has just fetched a file's first article, the check reads that copy instead of
fetching it a second time.

An install with no `nzb` provider has no news servers to ask. Acquisition still
runs there when a debrid account takes torrents. Each torrent is checked by
whether it reaches the library with files in it, as
[Newznab and Torznab](#newznab-and-torznab) describes. An NZB grab is never
acknowledged there, because nothing could check it or play it. One left
waiting from before the `nzb` provider was removed is set aside like a dead
post, and the next release is tried.

## Persistence and recovery

`data/acquisition.json` stores source/request IDs, attempts, retry deadlines,
in-flight work and receipts for individual acquisitions, including episodes. It
also records, per source, that a first snapshot was adopted, so `only_new_items`
is decided once rather than at every restart.
Matching media targets and editions reuse receipts across sources. Release
filenames also deduplicate against the library and saved NZBs. A receipt also
carries the grabs it is still waiting on a news-server answer about, and the
ledger carries the releases already found dead, so a restart mid-wait neither
acknowledges an unchecked grab nor hands a dead release back to the ranking.

Each attempt is saved before external work. Each saved release is checkpointed.
Writes flush a temporary file, replace the ledger and flush the parent directory
where supported. NZBs written before a crash are reused even if the last ledger
write did not finish. Once acquisition is recorded, Plex removal retries do not
acquire the title again.

Failures retry after 5, 10 and 15 minutes, then one hour, then every six hours
while the source still wants the item. Counts and deadlines survive reboots,
including long shutdowns. Open Seerr requests remain monitored. Plex items leave
the watchlist only after all planned seasons are acquired *and* checked against
the news servers, and only when `remove_after_grab` allows it. Its loose-episode fallback remains limited to episodes found
in indexer results.

An unavailable source pauses its own work. A failed state write pauses further
acquisition until saving succeeds. An unreadable or unsupported ledger pauses
acquisition and preserves the file; repair or restore it and restart zurg.
Other zurg services continue running.

The previous `data/plex-watchlist.json` is imported once with history, retries
and attempts waiting only for Plex removal intact. The original file is kept.
Both ledgers are included in normal backups without `--include-caches`. Retain
`data/` and `nzbs/` across container replacements.

## Adding another adapter

Implement `acquisition.Source` in its own package:

1. `ID()` identifies the instance across restarts.
2. `List(ctx)` returns a complete snapshot of `Item` references. Fail the
   snapshot on pagination errors. Persist metadata only, never credentials or
   complete API user objects.
3. `Resolve(ctx, item)` revalidates the item and returns normalized movie,
   season or episode targets. `Gone` cancels unwanted work. `Follow` keeps an
   open request monitored after current targets are acquired.
4. `Complete(ctx, item)` acknowledges a one-shot acquisition. It must tolerate
   repeated calls after a crash. A read-only list can use a no-op. The engine
   calls it only once every grab behind the item has answered, so an adapter
   never has to check a release itself — and must not treat being called as
   evidence of anything beyond that.

A source with a quality profile of its own can also implement
`acquisition.Assessor`, judging each candidate release by its own rules; the
Radarr and Sonarr adapters do, through their own parsers.

Register its configuration type and factory in the acquisition service. The
queue, persistence, retries and executor need no source-specific branch. Trakt,
MDBList and Simkl can fit this contract, but are not implemented yet.
