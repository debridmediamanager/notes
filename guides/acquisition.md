# Acquisition sources

Plex watchlist and [Seerr](https://github.com/seerr-team/seerr) feed the same
durable engine. Adapters discover requests and resolve media IDs. The engine
owns progress, retries and acknowledgement. The shared Newznab executor selects
releases and saves NZBs for zurg's Usenet backend.

## Configuration

```yaml
acquisition:
  quality: best
  max_size_gb: 40
  max_season_size_gb: 100
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
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
  prove it is indexed or playable.

Configure Seerr's library scan to include the library served by this instance.
If Sonarr/Radarr already acquire the same requests, disable that overlapping
workflow before enabling this adapter. The adapter does not emulate an *arr
server or change Seerr's service setup. Polling provides restart recovery;
no webhook is required.

## Persistence and recovery

`data/acquisition.json` stores source/request IDs, attempts, retry deadlines,
in-flight work and receipts for individual acquisitions, including episodes.
Matching media targets and editions reuse receipts across sources. Release
filenames also deduplicate against the library and saved NZBs.

Each attempt is saved before external work. Each saved release is checkpointed.
Writes flush a temporary file, replace the ledger and flush the parent directory
where supported. NZBs written before a crash are reused even if the last ledger
write did not finish. Once acquisition is recorded, Plex removal retries do not
acquire the title again.

Failures retry after 5, 10 and 15 minutes, then one hour, then every six hours
while the source still wants the item. Counts and deadlines survive reboots,
including long shutdowns. Open Seerr requests remain monitored. Plex items leave
the watchlist only after all planned seasons are acquired. Its loose-episode
fallback remains limited to episodes found in indexer results.

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
   repeated calls after a crash. A read-only list can use a no-op.

Register its configuration type and factory in the acquisition service. The
queue, persistence, retries and executor need no source-specific branch. Trakt,
MDBList and Simkl can fit this contract, but are not implemented yet.
