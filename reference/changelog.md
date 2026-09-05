---
label: Changelog
icon: history
order: 60
---

# Changelog

## zurg updates itself

`zurg update` replaces the running binary with the newest sponsor nightly. It reads the release feed with the GitHub CLI sign-in when one exists and `GITHUB_TOKEN` or `GH_TOKEN` otherwise, checks the download runs and reports the expected version before anything is replaced, and swaps the binary in by rename so an update cannot fail while zurg is running. A build already on the newest nightly, or ahead of it, is left alone. Inside a container the command refuses and points at the image pull instead, since a replaced binary there is lost on the next recreate; `--force` overrides. The installers gained a matching `update` mode for builds too old to carry the command.

Per platform: [Linux](../setup/linux.md#updating-zurg), [macOS](../setup/macos.md#update-zurg), [Windows](../setup/windows.md#updating-zurg), [Docker](../setup/docker.md).

## One Plex setting can be opted out of the policy

`plex_settings_ignore` names Plex preferences zurg leaves alone whatever `plex_settings_policy` says. It exists for the setup that genuinely wants one of them: a library whose files move between folders depends on Plex emptying its own trash to clear the entry left behind, and the default policy turns that off — while dropping to `warn` to get it back would also give up the filesystem-event guards beside it. An ignored setting is still read and still reported, on the dashboard and as `skip` in `zurg plex-settings`; it is only never written, never warned about, and never behind the trash banner. Ignoring a safety setting is at your own risk and zurg says so once at startup; an id that names nothing is reported and leaves the setting guarded, so a typo cannot read as an opt-out.

The settings themselves, and what each policy level does with them, are in [Plex](../guides/plex.md#recommended-plex-settings).

## One-line installers for every supported host

Fresh installs now have optional one-line bootstraps for Linux, macOS, Windows and Docker on Linux. They check or install platform prerequisites, use GitHub's browser sign-in for sponsor access, download the correct architecture, and hand off to `zurg setup` and `zurg doctor`. Existing binaries and configs are preserved, and every manual guide remains available.

## Setup asks which providers to configure

Fresh `zurg setup` installs no longer assume Real-Debrid. The interactive installer asks for one or more providers in priority order and collects only the selected credentials. Non-interactive installs can repeat `--provider` and use provider-specific token-file flags or environment variables. Existing configs are still preserved and the legacy Real-Debrid `--token-file`, `TOKEN` and `RD_TOKEN` inputs remain compatible when supplied explicitly.

## A burst larger than Sonarr's history window no longer loses imports

Sonarr and Radarr ask SABnzbd for every queued job but only the newest sixty history entries. That usually describes a real downloader well: completions arrive gradually and the client removes each one after importing it. A cached NZB library is different. A bulk season search can finish hundreds of individual episode jobs before the client's next poll, and zurg used to remove all of them from the queue while returning only sixty in history. Every job past that page was absent from both responses, so the client never imported or failed it and its release remained at the root of `__magic__` indefinitely.

zurg now keeps finished jobs beyond that visible page in the queue. As the client imports and removes the first sixty, the next completions advance into history. A season grabbed as individual episodes therefore drains in bounded batches instead of racing a fixed-size window; a season pack still behaves as one job.

## A delete through the mount always works, and `dav_allow_delete` is gone

Deleting a file from a media server pointed at the mount used to do nothing visible: zurg refused the WebDAV DELETE with a 403, rclone turned that into an I/O error, and the client reported a failure with no cause attached — Plex answers a plain `400 Bad Request` and logs nothing, so the button simply did not work and nothing said why. The key that allowed it, `dav_allow_delete`, is removed; a DELETE through the mount is now honoured everywhere, with no configuration. A config file that still sets the key is not an error — unknown keys are ignored — it just no longer does anything.

What the key was guarding has not gone away, so it is worth stating plainly: rclone has no way to express "overwrite" and flushes a rewritten file as DELETE followed by PUT, which means a program that rewrites a file in place — an `.nfo` writer, a trickplay pass, an \*arr rename, a stray `touch` — deletes the release from the debrid account rather than replacing a file, and the mount carries rclone's own credentials so nothing upstream can tell that apart from a deliberate delete. The PUT half is still refused, which is what keeps the sequence from completing quietly. If anything writes into your mount, set `mount_read_only: true`, which fails the write at the kernel before it reaches zurg at all.

## The Plex watchlist acquires through your Newznab indexers

The watchlist monitor now works, and it works off your own indexers. The old version searched through a DMM API key — and silently stopped working when Plex moved the watchlist to its discover host, since the endpoint it polled started answering 404. It now polls the right host, and every new watchlist item is searched on the Newznab indexers you already configured: a movie becomes the best matching release, a show is acquired season by season **preferring season packs** over loose episodes — a season nobody posted a pack of falls back to the loose episodes, best release per episode — and a chosen release whose NZB link fails to fetch (an indexer's burst-limit 429, say) falls to the next-ranked candidate rather than costing the item. The chosen NZB drops into the Usenet backend through the same naming rules as the SABnzbd endpoint and the Stremio addon, so the three surfaces find each other's grabs instead of duplicating them. An item leaves the watchlist only after something was actually acquired — the old order removed first and asked questions later, so any failure quietly ate the item off your list.

Configure it with the new `watchlist:` block: `enabled`, `check_every_secs` (default 60), `indexers` (empty borrows `stremio.indexers`), `max_size_gb` (default 40, movies and single episodes), `max_season_size_gb` (default 100, season packs) and `quality` (`best`, `4k`, `1080p`, `720p`, `smallest`). The legacy `plex_watchlist_*` keys keep their meaning. A `plex_token` is all the Plex it needs — the monitor talks to Plex's cloud service, so it runs fine on an instance with no `plex_server_url`. TV searches lead with the TVDB id and retry once by IMDb id when that finds nothing — indexers key TV on TVDB, and their show-level IMDb mapping is patchy enough that a heavily indexed show can answer an imdbid search with zero results.

Every key is on the config page under **Plex Watchlist**, and in [the configuration reference](../reference/config.md#watchlist).

## A Stremio addon over your Newznab indexers

zurg can now answer Stremio directly. Turn on the `stremio:` block, list your Newznab indexers, and paste the logged `/stremio/<token>/manifest.json` URL into Stremio: the client asks for streams by IMDb id, zurg searches the indexers (movies by `t=movie`, episodes by `t=tvsearch` with season and episode), and the results come back ranked resolution-first as playable streams. Picking one pulls the NZB into the Usenet backend — through the same naming rules as the SABnzbd endpoint, so a release grabbed twice is found rather than duplicated — and plays it through the signed `/strm/e/` endpoint, ranges, failover and archive interiors included. Everything played lands in the library, so it shows up in Plex like any other release.

The token in the path is the whole authorization, generated and kept in `data/stremio-token` when the config names none. Search results are cached in `data/stremio-cache` so reopening a title costs no indexer calls, for a lifetime that scales with how much the search found — an hour per result up to four, `stremio.cache_hours` (default 24) from five, never for an empty answer — and a cached stream list carries a refresh item that clears the cache for that title. Releases larger than `stremio.max_size_gb` (default 40) are dropped from the list, so a full-disc remux does not outrank every playable option.

The whole thing, including what the first play costs: [The Stremio addon](../guides/stremio.md).

## One folder is the whole Docker install, and it mounts on the first run

The documented way to start zurg in Docker was one `docker run` with a `TOKEN` in it, and it produced a container that mounted nothing. The config it generated left `rclone_enabled` off and `mount_path` unset, so `/zurg_mnt/zurg` stayed empty until someone found the two controls in the Dashboard — and that config was written inside the container, so the next `docker pull` threw the answer away along with the library cache. The quick start needed a footnote listing both of those, which is a quick start admitting it does not work.

`MOUNT_PATH` now seeds `rclone_enabled: true` and `mount_path` into the config on the run that creates it, next to what `TOKEN` already seeded. The image's working directory is `/config`, and everything zurg keeps resolves against it — `config.yml`, `data/`, `logs/`, `dump/`, `strm/`, `nzbs/` and the rclone cache — so a single `-v ~/zurg:/config` holds the entire install and an image update moves none of it. A first run is one command and ends with a mounted library rather than a Dashboard errand.

Both variables are read **only when there is no config file yet**, and are ignored ever after. That is the same rule `log_level` already has against `LOG_LEVEL`, for the same reason: a `MOUNT_PATH` left behind in a compose file must never quietly undo a mount path changed later in the Dashboard. Startup now warns when one is set and disagrees with the config, so an operator redeploying against no effect is told why.

Installs made against the old layout are untouched. Docker creates the target of every bind mount, so `/app/config.yml`, `/app/data` or `/app/logs` being present is the old layout announcing itself, and the container keeps using `/app` when it sees any of them. The full setup, and what breaks a host-visible mount, is in [Docker](../setup/docker.md).

## TorBox and AllDebrid are handed the `.torrent` too, so a private grab is not left hanging

The `.torrent` file an \*arr sends started travelling with the add last release, but only Real-Debrid could take one — the other two accounts were still handed the info hash alone, which for a private tracker's release is the one form of it they cannot use. Nothing failed, which is what made it hard to see: measured against the live TorBox account, a hash with no public swarm was accepted with a torrent id and then sat in `checking` reporting `size: -1`, no file list and a hundred-day estimate, exactly as reported from a TorrentLeech grab that "just hangs, nothing downloads". The same release's file was answered at once with its real name, its real size and its file list, and the qBittorrent endpoint could get on with the job.

Both accounts now take the file. TorBox's `createtorrent` and AllDebrid's `magnet/upload/file` both accept it in place of the magnet and answer in the shape the magnet add already answered in, so nothing downstream of the add changes — AllDebrid still reports on the upload itself whether it already held the content, which is the only cache answer that account ever gives. Verified live through zurg's own add path on both: a cached release uploaded and read back `done` at 100% with its file list within seconds, and one nobody holds read back named, sized, and stalled for want of peers — a state the endpoint can act on, where the hash's was a torrent that never resolves and never finishes.

One refusal is now legible as well. A TorBox call refused with a 4xx reached the caller as the shared HTTP client's bare "unexpected status code: 400", because the response body — where TorBox puts its own error code and detail — was dropped in favour of that error. So a `.torrent` TorBox will not act on was reported to the \*arr as a status number and nothing else. The body is now read first, and the account's own reason travels with the refusal.

What this means when you set the indexers up: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## Compressed archive entries stream, decoded on demand

A compressed RAR or deflate zip entry can't answer a ranged read the way a stored one does — its bytes exist only behind a decoder that must run from the entry's start — so zurg refused them: a compressed-only release answered 415, and compressed siblings of stored entries were skipped. That was the honest answer for a streamer, but it hid the bulk of Usenet's older catalog: every poster who packed with compression, whole and entire.

These entries are now served by decoding forward on demand into a bounded in-memory window — nothing written to disk, nothing decoded that no read asked for. Sequential playback, the pattern a player generates, lands at the window's edge and advances it a little per read; a seek backwards past what the window kept restarts the decode from the entry's start. The whole entry's bytes are what unrar would extract: a real compressed RAR4 volume's three jpg entries decode byte-exact against the same fixture read by an independent decoder pass, md5 for md5.

Walking a split set's volumes needed rardecode's volume chain, which opens `.part02.rar` from the filesystem; zurg's volumes live behind ranged network readers. The decoder is now vendored under `internal/rardecode` (MIT, upstream v1.1.3) with one change — `OpenReaderOver` takes an opener, so each next volume comes from the set by the name the archive itself derives. Listings change shape accordingly: a compressed-only release presents its payload (`stream_compressed_archives: false` restores the old refusals), and a mixed archive lists its compressed siblings beside its stored ones. Listing version 15.

## Sonarr and Radarr can grab torrents, and Prowlarr can push them

zurg can answer the \*arrs as though it were a qBittorrent. They hand it a magnet or a `.torrent`, it adds the info hash to a debrid account — Real-Debrid, TorBox or AllDebrid, whichever is configured — and once the release is in the library the torrent reports finished with a folder under `__magic__` to import from. The import is the same rename the SABnzbd endpoint has always given Usenet grabs: a row in the `__magic__` table, no bytes moved.

The endpoint registers at `/api/v2` and `/qbittorrent/api/v2`, off until asked for, gated by an API key the clients send as a bearer token. A grab is offered to every account that takes torrents in the order of `providers:`, and a grab that stops moving — no stage change, no rise in progress, for `qbittorrent.download_timeout_mins` minutes, fifteen by default — comes off its account and is tried on the next. `0` takes only content an account already holds cached and refuses the rest inside the add, which is the one refusal the \*arrs act on. What the account is doing with a download is mapped onto the states the clients understand, with the rate and the swarm and the time left where the account reports them.

One honest limitation: qBittorrent's API has no way to say a download failed, so a release no account would take reaches the client as a warning rather than a blocklist entry — visible in the queue with the reason attached, but never re-grabbed unattended. The SABnzbd endpoint does not have this problem.

Prowlarr speaks to the same endpoint for what a download client is to it: pushing a release to the account by hand. Nothing imports behind a Prowlarr push — that is what the \*arrs are for.

Full walkthrough, captured against a live install: [Sonarr & Radarr, torrents](../guides/sonarr-radarr-torrents.md).

## `__magic__`, a directory you can organise

Every directory zurg serves is a saved filter. A release is in `movies` because it matches the movies filter, and it is in `__all__`, in `recent` and in `movies` all at once — so there has never been anywhere in the library to *put* something. That is fine until a program wants to move a file. Radarr and Sonarr import by moving, and a mount that cannot receive a move leaves them copying instead: every import pulls the whole release down from the debrid host or from Usenet, which is the one thing the mount exists to avoid.

`__magic__` is a new top-level directory that starts as an exact copy of `__all__` — every release as a folder, holding exactly what `__all__/<release>/` holds, a virtualised archive's contents included — and inside which anything can be moved anywhere. `mkdir -p /mnt/zurg/__magic__/tv/Show/Season 01` and `mv` an episode into it, and the episode is there: no bytes moved, no torrent renamed, nothing re-downloaded, and `__all__` unchanged. A move rewrites one row in a small table, and that table keys on the release's content hash and on the file's own path inside it, so a repair that re-adds the release and rebuilds every id around it does not lose where you put things. Renaming a release from the dashboard does not either.

Moves go both ways. A file can be moved *into* a release folder as well as out of one, and the folder lists it beside the release's own entries — which is what a program that puts something back into the folder it is importing from needs to see. Where a name arrives from two places at once the deliberate one wins: what you moved beats what the release calls that name, which beats a file sitting in `data/local`, and the loser is not listed rather than listed twice.

Deleting is the other half, and by default it hides rather than destroys. An `rm` inside `__magic__` takes the entry out of `__magic__` and leaves it in `__all__` and in every filter directory, so a client reorganising a library cannot lose any of it — and a release folder can vanish the same way, which is what lets Sonarr delete the job folder after an import without touching the release it just imported from. `magic.allow_delete: true` opts into the stronger meaning for files, where the content goes too; a release folder and a directory only ever hide, whatever that is set to.

It is off by default, because it is a writable tree and an \*arr pointed at the wrong root folder can reorganise a library:

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

The two `sidecar_` keys are for clients that mount `/dav` directly rather than through zurg's own mount. Those send zurg the `PUT` of a new `.nfo`, poster or subtitle track, and it now writes the body into `data/local/__magic__/…` — the same tree zurg's own mount already writes such files to — so the two views show one directory instead of two, and the file reads back with ranges, a length and a modification time like any other. The caps keep that from quietly becoming a general file store: a file over `sidecar_max_mb` is refused with 413, and one that would take the tree past `sidecar_budget_mb` with 507. Nothing the library answers for can be written over — a release folder, an entry of one, or a path something was moved to is a 403 — and a move never destroys a real file to make room for a row.

Two things are worth knowing before pointing anything at it. The filter directories are untouched by design, so a release moved inside `__magic__` is still in `recent` and `movies` under its own name — point a media server at `__magic__` **or** at the filters, not at both. And the mount has always been writable in one direction: anything genuinely new written into it — an `.nfo`, a subtitle, a poster — lands in zurg's own `data/local` and is merged into the listing, which is why sidecars beside a release simply work and why an \*arr's root-folder write test passes.

`dav_allow_rename` and `dav_allow_delete` have nothing to do with any of this. Those guard the path that renames and deletes what the debrid account holds, and a write under `__magic__` reaches no account. `mount_read_only: true` still overrides everything.

The dashboard has a page for it, at `/magic/`. It shows every row the table holds — grouped by release, saying what each one is, which file of which release it came from and where that file is served from now — along with how many rows there are, what the journal and the snapshot take on disk, and how much of `sidecar_budget_mb` the real files beside the library are using. It also reports the size of the whole of `data/local`, which is the number that says whether something is importing by copying: a client that copies instead of moving puts the bytes there, and nothing else on the dashboard would ever show it.

Three of the states it shows could not be reached from a client at all. A placement can be **reset**, and the file goes back to where the library puts it; a tombstone can be **unhidden**, and the entry is listed again; and a **dangling** row — one whose release, or whose file inside it, the library no longer holds — can be dropped, one at a time or all at once. That last one is new ground: such a row resolves to nothing, so no client can list it, move it or delete it, and it is deliberately kept rather than dropped because a repair that brings the release back brings the placement back with it. Until now there was nowhere to clean one up. Sidecars are listed too, with the same classification applied to them: a real file in a folder nothing accounts for any more — an `.nfo` beside a release that has left the library, or inside a placement that has been forgotten — is shown as **orphaned** and counted apart from the rest. Nothing is swept, for the reason a dangling row is not: the file is still yours, and a repair that brings the release back accounts for the folder again. Deleting one there really deletes the file, exactly as a `DELETE` through the mount does. Every one of those buttons tells the mount to forget the listings it changed, because it caches a directory for twelve hours with polling off.

`magic:` and `sabnzbd:` are both editable from the config page now, and both are marked **Restart Required** because they mean it: the routes that serve `__magic__` and the SABnzbd endpoint are decided once, at startup, out of exactly these values. Turning one on writes it to `config.yml` and changes nothing about the run that answered — and the `__magic__` page says so in as many words rather than rendering an empty namespace as though everything were fine.

### Sonarr and Radarr can now hand zurg an NZB

The reason `__magic__` exists is so an \*arr has somewhere to import from, and zurg now speaks the other half of that: an endpoint at `/api` that answers Sonarr and Radarr as though it were a SABnzbd. Point them at zurg's host and port, paste the API key, and grabs land in `nzbs/` for the Usenet backend. Once the release is in the library the job reports Completed with a folder under `__magic__`, and the import is a rename inside the mount — one row in the table, no bytes read, nothing pulled down from Usenet to put it in a series folder.

```yaml
sabnzbd:
  enabled: true
  api_key: ""          # left empty, zurg generates one and logs it once
  categories: [tv, movies]
  complete_dir: ""     # defaults to <mount_path>/__magic__; set it to what a containerised *arr sees
```

Off by default, and it needs both halves to be useful: an `nzb` provider to read the NZB, and `magic.enabled` to have anywhere to import from. The endpoint is not behind zurg's basic auth, because neither \*arr ever sends any to a download client and their HTTP layer reads a 401 as "unable to connect" — the API key is the whole gate, so treat that port accordingly. Root folders go **inside** `__magic__` (`__magic__/tv`, `__magic__/movies`), never at it or above it, or the clients' root-folder health check has something to say.

One thing to know before switching a library over: **the failure signal is partial**. A release the library holds but nothing importable in — every file broken, deleted or filtered away, or nothing there but repair scaffolding and sidecars, which is what an NZB of only recovery volumes is — is reported `Failed`, which is what makes both clients blocklist it and grab an alternative. A RAR set counts as content, since zurg streams the video straight out of it — unless it is one zurg cannot stream at all, holding nothing but compressed entries, which is reported Failed from the moment something has opened it and found that out. That verdict is kept with the release, because learning it costs a read of every volume in the set. What is not reported is a post whose articles have aged off the news server: zurg does not check that yet, so a dead release reports Completed like any other and fails on the first read, and Sonarr sees an import failure rather than a download failure. That one is still a manual call. Everything else in the flow works, including the post-import cleanup: the job folder Sonarr deletes becomes a tombstone and the release stays in `__all__`.

A grab does not wait for the next change poll: zurg re-reads the watch directory as soon as it has written into it, and only the Usenet accounts — a season pack is twenty grabs in a few seconds, and re-listing a debrid library of tens of thousands of torrents to notice a local file would be twenty times the wrong work. If no `nzb` provider is configured at all, zurg now says so at startup rather than accepting grabs nothing will ever read.

The `__magic__` page lists the jobs, read-only: the `nzo_id` each client knows a grab by, its category, when it arrived, whether the library lists the release yet, and — once it does — the folder the \*arr imports from.

Full setup, including remote path mapping for containerised \*arrs and what each connection-test error means, is in `docs/sabnzbd.md`.

## The mount reaches more of the bandwidth it has

Reading a file through the rclone mount was slower than fetching the same bytes over HTTP, and the reason was how a read starts rather than how it runs. The first chunk was requested at 4 MB and doubled from there, so a read that began at a cold offset spent most of its life below the speed the connection could actually carry — and every seek starts a fresh read. The first chunk is now requested at 32 MB.

Measured on a host with about 70 MB/s of usable download bandwidth, with each setting sampled in turn so a slow minute could not land on just one of them: median mount throughput on Real-Debrid went from 49 to 57 MB/s, and TorBox moved the same way. AllDebrid gains less here because its limit is per connection rather than per account.

Chunk size is the whole of the effect — the FUSE read-ahead was raised alongside it in testing and changed nothing. It also costs no extra bandwidth: the chunk size is how much is *asked* for, not how much is transferred, and rclone stops pulling when playback stops. A 4 MB read still fetched 6 MB, the same as with read-ahead switched off entirely, so a library that is browsed and sampled rather than watched end to end downloads no more than before.

Nothing to change — the new value ships as the default, and `rclone_extra_args` still overrides it.

## `zurg benchmark-my-setup` answers how fast the setup actually is

Until now the only way to know whether a slow stream was the account, the host, or the mount was to guess. The new command reads real bytes over the same path a player uses and reports the distribution — min, median, average, max, and time to first byte — rather than one figure that any single unlucky sample could have produced.

It runs three phases. Each account on its own, which is the number to hold against what the service promises. Then every configured account at the same time, which is the only phase that can tell a slow provider from a saturated uplink: accounts that each sustain 70 MiB/s alone but 25 MiB/s together are one bottleneck, not three problems, and the report says which of the two it is looking at. Then the same read through the rclone mount, where the gap against the first phase is what FUSE and the VFS cost. The mount phase is skipped when `rclone_enabled` is off.

Samples are placed at random offsets, and that is not a detail. Every layer underneath caches — rclone's VFS keeps what it has fetched, a debrid CDN edge keeps what it has served — so re-reading one offset measures those caches instead of the link. On a live setup the same file reported 47 MiB/s cold and 285 MiB/s on the second read of the same region.

Sample size changes what the mount figure means, so the report says so. rclone opens a file at `vfs_read_chunk_size` and doubles from there, so a short sample spends most of its life still ramping: measured on one setup, 47 MiB/s at a 256 MiB sample against 88 MiB/s at 1 GiB, with HTTP steady at ~70 either way. The default 128 MiB is the seek-and-scrub number; `--sample-mb 1024` is the sustained ceiling. Neither is wrong, and the run tells you which one you just took.

`-n` sets iterations, `--provider` restricts the run to named accounts, `--skip-mount` and `--skip-concurrent` drop a phase, and `--json` emits the report for scripting. It spends real bandwidth from the operator's own accounts — iterations x sample size per account, twice, plus the mount phase. Run it from the zurg directory: the NZB backend reads its `nzbs/` folder relative to the working directory, and an account that lists nothing is reported as that rather than as an account with no large files.

## Working Real-Debrid releases are no longer marked broken after a link check

Since the nightly of 2026-08-20, a healthy library could fill the log with `Link verification failed during refresh` and `keeping files as broken`, each one carrying a `404 Not Found` and `invalid_download_code` against a download host. Nothing was actually wrong with the releases.

That nightly added a tidy-up for the rows Real-Debrid mints in My Downloads: every link zurg verifies creates one, and left alone the list grows by a row per torrent per cold build until startup is paging tens of thousands of them. The tidy-up deletes those rows in the background, on the understanding that a row and the URL it minted are separate things.

They are not. Deleting the row revokes the download code, and the only thing that keeps it alive is a host that has already fetched it — measured 2026-08-22, a code minted on `124-4` and fetched once through `44-4` still answered `200` on `44-4` while both `124-4` and an untouched `125-4` answered `404 invalid_download_code`. zurg picks the download host per request, from the fastest few, so the host that verified a link is rarely the host that asks for it next. The resolution stayed cached for four hours, and every request against it in that window came back `404` — read as a link that had rotted, and the release marked broken.

A resolution now leaves the link cache at the moment its row is queued for deletion, so nothing replays a URL that is on its way out; the next request resolves a fresh one. The rows are still cleaned up. Releases wrongly marked broken recover on the next refresh — nothing to re-add or re-scan.

## Shows named by air date are filed as shows, not movies

A programme with no season and episode numbers is named by the date it aired instead — `WWE SmackDown 2026-08-21`, and every daily and late-night show after it. Nothing in the episode test knew that convention. It looked for `S01E01`, for a season or episode number written out, for an anime release's hash, and failing all of those it looked for a run of numbered files to read as a sequence. A daily release is a single file carrying a single date, so the answer was no, and the release fell through to the first directory that would take it — in most configurations, movies.

The air date now counts as the marker it is, written `2026-08-21`, `2026.08.21`, `2026 08 21`, `2026_08_21` or `20260821`. Only real dates qualify: the month has to be one of twelve and the day one of thirty-one, so a year sitting beside a resolution — `Movie.2026.05.1080p` — is never read as one. Measured against a 6755-release library, no film changes directory; measured against 4734 real daily-show releases, 4633 are now recognised. The rest are older scene names that abbreviate the year to two digits or put it last, which cannot be told apart from an audio channel layout with any confidence worth having.

A library already on disk re-files itself at startup, so the next restart is enough — nothing to re-scan or re-import.
