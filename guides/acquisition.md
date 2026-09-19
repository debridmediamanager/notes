# Acquisition sources

Plex watchlist and [Seerr](https://github.com/seerr-team/seerr) feed the same
durable engine. Adapters discover requests and resolve media IDs. The engine
owns progress, retries and acknowledgement. The shared executor selects releases
from Newznab indexers, saving NZBs for zurg's Usenet backend, and from Torznab
indexers, handing info hashes to a debrid account that already holds them: see
[Newznab and Torznab](#newznab-and-torznab). Every saved release is
checked against the news servers before the engine acknowledges anything: see
[Verifying a grab](#verifying-a-grab).

## Configuration

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  max_size_gb: 40
  max_season_size_gb: 100
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
```

Run this on the zurg instance with an `nzb` provider. Acquired NZBs land in its
`nzbs/` directory. This path uses Newznab and Usenet; it does not add torrents
to a debrid account. Plex needs the existing `plex_token`. Seerr needs its base
URL and API key, independently of any Plex settings in zurg. URL subpaths and
URLs ending in `/api/v1` are supported.

Keep names and Seerr URLs stable: they identify saved queues. Rotating a Seerr
key retains its queue. Restart after adding sources or changing their URL or
credentials. Existing `watchlist:` and `plex_watchlist_enabled` settings keep
working through an automatic `plex-watchlist` adapter. An explicit
`plex_watchlist` source, even disabled, supersedes the legacy enable switch.
Only one Plex source can use the configured Plex account. Shared search
settings fall back to `watchlist:` and its existing defaults; omitted indexers
fall back to watchlist/Stremio indexers.

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
another torrent or an NZB. Nothing is ever downloaded onto the account, no
uncached add allowance is spent, and no transfer slot is left running for
something nobody is waiting on. `watchlist: true` on a provider entry names the
account offered first; `add_torrents: false` keeps an account out of it
entirely.

`prefer` decides which kind is reached for first when both could satisfy a
target. `usenet` is the default, because a Usenet grab costs a download while a
torrent spends one of the account's add slots, and because it is what the
feature did before it could take a torrent at all. `torrents` reverses it, and
`best` drops the distinction and takes whatever the ranking puts first.

The verification a grab waits on differs with the source. A Usenet release is
put to the news servers, which is the only way to know whether the post is
still there. A torrent was added only because the account said it already held
the content, so what is left to establish is that the release reached the
library with files in it; that is what the check asks, and a release the
account lists empty is set aside like a dead post.

An install with no `nzb` provider can still run acquisition, with Torznab
indexers alone. An install with no account that takes adds passes over Torznab
results the same way.

## What acquiring does to the source's own list

A Plex watchlist is a list somebody curated, and it is the only record that
they wanted a title — Plex keeps no history of a removed entry. Two settings
decide what zurg is allowed to do with it. Both apply to `plex_watchlist`
sources; a Seerr source owns no list zurg writes to, so both are inert there.

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
post. So each acquired release is put to the configured news accounts — one
`STAT` for the first article of every content file, the same walk
`/api?mode=addfile` makes for Sonarr and Radarr — before the engine
acknowledges the request. Three answers, and keeping them apart is the whole
point:

- **Articles gone.** The grab does not count. The receipt is reopened, so the
  target is wanted again, and the release is recorded as dead for 30 days so
  the next attempt ranks the next candidate rather than settling on the one
  already in the library. A release on that list is not a candidate: it is not
  fetched, and it does not spend one of the three candidates an attempt tries,
  so a run of dead posts at the top of a ranking is walked through instead of
  putting everything under it out of reach. A dead season pack puts its whole
  season back to being wanted; the loose episodes are taken instead.
- **The accounts could not be asked.** A pool that is down, an account
  throttling, or the ordinary case of a library that has not listed the new NZB
  yet. Nothing was established, so nothing is decided: the request is looked at
  again in two minutes and the wait costs it no retry attempt. Twenty checks
  across two hours that establish nothing set the release aside the way a dead
  one is, and the next attempt tries another release. The request is never
  acknowledged on a release nobody could check.
- **The release is there.** The receipt drops what it was holding and the
  acknowledgement goes ahead.

An install with no `nzb` provider has nobody to ask; acquisition does not start
there at all. The check is read-only: it moves no article bodies into the cache
and records no dead articles, so it cannot silence a file that plays.

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

Register its configuration type and factory in the acquisition service. The
queue, persistence, retries and executor need no source-specific branch. Trakt,
MDBList and Simkl can fit this contract, but are not implemented yet.
