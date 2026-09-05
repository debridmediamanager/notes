---
label: Plex
icon: play
order: 60
---

# Plex Features & Capabilities

## Configuration & Storage
- Config keys documented in [`config.md`](../reference/config.md)/`config.example.yml`: `plex_server_url`, `plex_token`, `plex_match_every_mins` (default 1440), `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` (default 5s), `mount_path` (required for matching/scan path building). Dashboard-authored settings are saved directly to `config.yml` via the config writer (`updateConfigFileAtomic`).
- Both intervals fall back to their default only when the value is exactly `0` (`intOr`, `internal/config/config.go:9-14`); neither can be disabled. The dashboard rejects anything below 1 (`internal/handlers/dashboard/dashboard.go:1168-1190`), and a negative `plex_match_every_mins` written straight into `config.yml` panics the scheduler's ticker rather than turning matching off.
- Watchlist acquisition additionally needs `dmm_api_key`; `watchlist_quality` (default `best`) picks the quality preference for the DMM search (`internal/config/config.go:119-122, 610-627`).
- `mount_path` is also the prefix for scan paths sent to Plex and the managed rclone mount ([`config.md`](../reference/config.md), `pkg/scan/scanner.go`).
- On-library-update hook (`on_library_update`) is fed every changed path as arguments, debounced 500 ms and deduped, with one invocation at a time, enabling Plex autoscan scripts (`internal/torrent/hooks.go`).

## Authentication & Server Discovery
- Web dashboard flow: `/plex/auth` creates a PIN session (`pkg/plex/auth.go`, `CreatePlexAuthURL`), stores it in `pkg/plex/auth_session.go` (auto-cleanup after 10 min, swept every 5), and polls for completion via `/plex/auth/status` (`PollForAuthToken`, 60 attempts 5s apart before timing out).
- `/plex/callback` serves a progress page that, once authorized, calls `/plex/servers` to list servers and `/plex/server` to select one (`internal/handlers/dashboard/dashboard.go`).
- Server discovery (`pkg/plex/auth.go`): fetches Plex resources with both HTTP/HTTPS endpoints, filters relay if direct exists, handles IPv6 addresses, and probes each entry's `/identity` (TLS verification disabled). Only servers **owned** by the account are considered (`device.Owned`, `auth.go:66`) — shared servers never appear — and entries that fail the probe are dropped from the response rather than returned with `last_error` set (`enrichServersWithIdentity`, `auth.go:111-150`).
- Selecting a server writes `plex_server_url`/`plex_token` to config, reinitializes the Plex client, (re)starts the matcher scheduler, fires a match trigger, and refreshes the cached dashboard status (`HandlePlexServerSelect`, `internal/handlers/dashboard/dashboard.go:582-684`). `/plex/logout` clears the stored values and the status cache.

## Plex Client Capabilities (`pkg/plex/client.go`)
- Connection lifecycle: deferred start option (`WithDeferredStart`), `ValidateConnection` guard against `/identity`, graceful `Close`. There is no restart API — the dashboard's `RestartAllowed`/`RestartReason` are inferred from the server URL (local/LAN vs. remote) and are display-only (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`).
- Scan queue: dynamic job queue/worker (`common.DynamicJobQueue`); `ProcessJob` issues `GET /library/sections/{key}/refresh` with Plex headers and **at most one** `path` query param per job — more than one is rejected outright (`client.go:313-315`). A job with no path is a full-section refresh. 503 becomes a server-busy error, 404 reports the library as deleted from Plex; `GetJobQueueSize` exposes backlog.
- Load/stuck detection: `CheckServerLoad` inspects `/activities`, tracks `library.update.section` progress per UUID (a changed progress *or* subtitle counts as progress), and `IsJobStuck` flags stale jobs by `librarySectionID` with a Title fallback.
- Library queries: `GetSections` (movie/show sections with locations), `GetSectionItemCount`, `FindSectionNormalized` (matches a path against a section location and corrects the prefix to the library's casing), `GetAllMediaItemsConcurrent` (batched, concurrent fetch with `includeGuids` to collect paths, GUIDs, IMDB IDs), and `GetShowLevelIMDBIndex` (show-level IDs for TV sections so episodes can inherit them).
- Metadata & matching helpers (`pkg/plex/match.go`): `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`), `GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`, with title/year/language overrides), `LookupMetadataByGUID`/`LookupRatingKeyByGUID` (`GET /library/all?guid=…`), `ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`), and GUID parsing (`ExtractIMDBIDFromGUID`, `ExtractTMDBIDFromGUID`, `ExtractTVDBIDFromGUID`, `ExtractAnyIDFromGUIDs`; `MatchResult`/`MatchSelection` types).
- Server info: `GetServerIdentityOnly` and `GetServerDetails` (machine ID/version; the latter also totals sessions/transcodes/bandwidth), `GetStreamingSessions`, `GetTranscodeSessions`, `GetServerActivitiesDetails` (annotated with stuck status).
- Watch history: `GetWatchHistory` (`GET /status/sessions/history/all`), `GetMetadataBatch` (comma-joined rating keys against `/library/metadata`), and `GetWatchHistoryWithMetadata` (`pkg/plex/history.go`), feeding the stats in `pkg/plex/stats.go`.

## Media Scanner Integration (`pkg/scan/scanner.go`)
- Initializes Plex client when `mount_path`, `plex_server_url`, and `plex_token` are set; retries every 5s until connected, firing `OnPlexReconnected` callbacks.
- `TriggerScan` groups paths per Plex section (via `FindSectionNormalized`) and queues one refresh job per mount_path-prefixed path, logging progress every 50. Also supports Jellyfin/Emby, which take the non-grouped path. A path that lands in no section is only warned about when *none* of the batch's paths matched — otherwise it is a debug line, so a torrent in both a library dir and a zurg-only dir (recent, music, …) does not warn.
- `ReinitializePlexClient` allows dashboard updates to swap servers/tokens live.
- `GetQueueSizes` exposes Plex queue depth for UI/monitoring.

## Matching & Metadata Sync (`internal/plex/matcher.go`, `internal/plex/schedule.go`)
- Preconditions: requires configured Plex URL/token, `mount_path`, and a live `scanner.PlexClient`; otherwise returns explicit errors.
- The only Plex state stored on a torrent is `PlexRatingKey` (show-level for episodic content) plus `IMDBID` (`internal/torrent/torrent_types.go:99,106`). Plex GUIDs are used in-flight for ID extraction and reporting but are never persisted.
- Data gathering: pulls all torrents from the directory map and all Plex items via `GetAllMediaItemsConcurrent`, prefixed by a `GetShowLevelIMDBIndex` pass so episodes inherit the show's IMDB/TVDB/TMDB ID instead of an episode-level one. Items are keyed by `GrandparentRatingKey` when present.
- Sync steps:
  - Validate every stored rating key against the freshly fetched Plex items; a key Plex no longer has is cleared along with the torrent's IMDB ID, and the torrent is requeued for matching.
  - Path-based matching for torrents without a rating key: `buildPlexDirIndex` indexes every lowercased path component of every Plex file, and the torrent's `GetKey` is looked up in it (O(1), first entry wins). Torrents whose assigned directories match no Plex section location are skipped first.
  - IMDB backfill: first from the already-fetched batch (no API calls), then per torrent via `GetMetadataSummary` (max 20 concurrent).
  - Detects Plex items with no torrents.
  - Sends every hash+IMDB pair to the DMM API — only when `dmm_api_key` is set (`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`, `internal/torrent/mediainfo.go:254-258`).
- `MatchSingleTorrent` runs the same path lookup for one torrent, for use right after a targeted scan; it no-ops if the torrent already has a rating key.
- Reporting: writes `logs/match_report.txt` summarizing counts, unmatched torrents, skipped torrents, Plex items without torrents, and matches missing IMDB.
- Scheduling (`internal/plex/schedule.go`): each completed run stamps `data/plex_match_timestamp`. On start, `StartMatchingJob` runs immediately only if that stamp is missing or older than `plex_match_every_mins`; otherwise it waits out the remainder first. It listens for manual triggers on `TorrentManager.PlexMatchTrigger`, for live interval changes on `ResetPlexMatchTicker`, and retries background panics up to 3 times.
- Manual trigger endpoint `/plex/match-torrents` pushes to the trigger channel and refuses while a run is in flight; `/plex/match-torrents/status` reports whether one is running (`internal/handlers/utilities.go`).

## Manual Matching & Manage UI (`internal/handlers/manage`)
- Torrent list filters expose Plex states (`plex_matched`, `plex_in_library_not_matched`, `plex_no_imdb`, `plex_missing_metadata`) for quick views (`torrent_list_state.go`).
- Per-torrent manual match page `/manage/{hash}/plex-match`:
  - Requires the torrent to already carry a `PlexRatingKey` (set by the matcher); the page reports "torrent is not linked to Plex" otherwise. `resolvePlexRatingKey` validates that key with `GetMetadataSummary`, backfills a missing IMDB ID from it, and on a stale key re-resolves via `LookupRatingKeyByGUID` using the torrent's stored `tt…`/`tvdb://`/`tmdb://` ID (`internal/handlers/manage/handler.go:93-151`).
  - Fetches Plex manual match candidates with optional title/year/language overrides (44 language options, default `en-US`); renders matches with the current selection highlighted (`torrent_matches.go`).
  - Applying a match (`HandleApplyPlexMatch`) calls `ApplyManualMatch`, then re-looks-up the rating key by the chosen GUID because Plex may reassign it, updates the torrent's rating key and IMDB (including an optional IMDB supplied by the user), persists changes, and redirects with success/error states.

## Watchlist Monitor
- Optional background polling when `plex_watchlist_enabled: true` (`internal/plex/watchlist_monitor.go`). Toggling it in the dashboard requires a restart to take effect; the interval can be changed live via `ResetWatchlistTicker`.
- Uses `pkg/plex/watchlist.go` client against `metadata.provider.plex.tv` with 200-item paging; headers include client identifier. The token is read fresh per request through `PlexTokenProvider`, so re-authenticating in the dashboard takes effect without a restart.
- Tracks processed `ratingKey` timestamps (7-day retention) to avoid repeats, and immediately removes each new item from the Plex watchlist via PUT `removeFromWatchlist`.
- Acquisition: extracts `imdb://`/`tmdb://` from the item GUIDs, resolves TMDB→IMDB through the DMM client when needed, searches DMM for torrents (`SearchMovieTorrents` limit 10, `SearchTVTorrents` limit 5 per season, quality from `watchlist_quality`), takes the first result, and adds it with `TorrentManager.AddMagnetAndSelect` unless the hash is already in the library. Shows add one torrent per season. Without `dmm_api_key` the monitor stops after the removal and logs a warning.
- Failures (search error, no results, unresolvable TMDB) go to an in-memory retry queue: first retry after 5 minutes, backing off by 5 minutes per attempt, given up after 3.

## Dashboard & API Endpoints (`internal/handlers/router.go`, `internal/handlers/dashboard`)
- Routes: `/plex/auth`, `/plex/callback`, `/plex/auth/status`, `/plex/servers`, `/plex/server`, `/plex/logout`, `/plex/match-torrents`, `/plex/match-torrents/status`, `/plex/scan/{sectionKey}`, `/plex/scan-all`, `/plex-stats`, `/plex-stats/data`, `/plex-stats/image`, `/manage/{hash}/plex-match`.
- Dashboard shows Plex server info and status via `PlexStatusFetcher` on two tickers: every 30s it refreshes streaming sessions, transcodes, bandwidth and server activities (`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`); every 5 minutes it does a full fetch that also re-reads identity (`GetServerIdentityOnly`), library sections and per-section item counts. Scan activities are cross-referenced against the torrent list by filename so the dashboard can link an activity to a torrent hash.
- Section/all scan endpoints queue a **full** section refresh (`RefreshSection(key, nil)`, no path) for one or all sections; they do not touch STRM files or fire library side effects (`HandlePlexScan`/`HandlePlexScanAll`).

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- `/plex-stats` renders a 9-slide year-in-review from the last 12 months of Plex watch history; `/plex-stats/data` returns the same stats as JSON, `/plex-stats/image` renders a shareable PNG via headless chromedp (`square` 1080x1080 default, `instagram` 1080x1920, `facebook` 1200x630).
- Stats are fetched at most once per 24h (`?refresh=true` forces), capped at 10000 history items, and cached both in memory and on disk at `data/plex_wrapped_cache.json`, which is reloaded at startup. While a fetch is in flight the page reports a loading state rather than blocking.

## Library Side Effects & Refresh Links
- Library side effects fire on directory assignment changes, renames, deletions and file repairs: `TriggerLibrarySideEffects` invalidates the rclone VFS dircache for the affected paths (so the media servers do not scan a stale listing), calls `MediaScanner.TriggerScan` (hitting Plex refresh), and runs the user's `on_library_update` hook (`internal/torrent/hooks.go`).
- Refresh pipeline only runs STRM generation and side effects after initialization completes to avoid premature Plex scans (`internal/torrent/refresh.go:426-432`).

## Infrastructure & Scripts
- Sample Nginx vhost for proxying Plex traffic (`nginx/plex.conf`).
- `plex_update.sh` is the reference partial-scan script for `on_library_update: sh plex_update.sh "$@"`; `docker-compose.yml` carries a commented-out bind mount for it, to be uncommented when you use it.
- `integration/plex_integration.sh` runs under `make integration-test` and `make integration-test-media`; it skips loudly on a host with no Plex server, so read the output rather than the exit code. `scripts/plex-e2e-test.sh` is a standalone playback check that reads `plex_server_url`/`plex_token` out of `config.yml`.

## Recommended Plex Settings

Plex's defaults assume local disks that are always present and free to read. A zurg mount is neither: its bytes come from a provider over HTTP, and it can be briefly unreadable while rclone reconnects. Several Plex defaults are actively harmful under those conditions.

zurg reconciles these on every Plex status refresh. `plex_settings_policy` decides how far it goes — `off`, `warn`, `guard` (default) or `enforce`. The list lives in `pkg/plex/settings.go` (`RecommendedSettings`); the policy in `pkg/plex/reconcile.go`.

A setting the server does not report is skipped, so a Plex version that lacks one is not reported as misconfigured.

### Opting out of one setting

`plex_settings_policy` is tiered, and the tier is not always the question being asked. An operator whose files move between library folders — tag-driven sorting, say — depends on Plex emptying its own trash to clear the entry left behind, and `guard` turns that off. Dropping to `warn` to get it back also gives up the filesystem-event guards, which are the same tier and not what they asked for.

`plex_settings_ignore` names settings individually:

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

An ignored setting is still read and still shown on the dashboard and in `zurg plex-settings` (marked `skip`), so nothing is hidden. It is simply never written, never counted as a problem, and never behind the dashboard's trash banner. Ids are matched case-insensitively; one that names no setting in the tables below is reported at startup and leaves the setting guarded, since a typo must not read as an opt-out.

Ignoring a safety setting is at your own risk, and zurg says so once when it starts rather than on every refresh. `autoEmptyTrash` in particular is the setting that empties a library when a scan meets a mount that has blipped — with it ignored, zurg's own [trash sweep](../internals/plex-trash-sweep.md) (`plex_trash_sweep_every_mins`) is the safer way to get the same cleanup, since it removes entries one at a time and only ones whose files are confirmed gone from a mount that reads.

### Safety — corrected under `guard` and `enforce`

These lose data rather than time, which is why the default policy writes them instead of only warning.

| Preference | Plex default | zurg wants | Why |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | Plex empties its trash after every scan. If the mount is briefly unreadable while a scan is walking it, every file reads as deleted and Plex removes them permanently instead of leaving them in the trash to come back with the mount. |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | A FUSE mount does not emit filesystem events reliably, so this triggers scans at moments nothing asked for one — including while the mount is still coming back. |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | Driven by the same unreliable events, against a directory that may not be fully present yet. |
| `ButlerTaskBackupDatabase` | `1` | `1` | The nightly database backup is the only thing that recovers a library Plex has already deleted. |

### Bandwidth — corrected under `enforce` only

Each of these makes Plex decode entire files. Harmless on local storage; over a debrid mount every byte is a provider request, and these run across the whole library.

| Preference | Plex default | zurg wants |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` |
| `GenerateBIFBehavior` | `never` | `never` |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `MusicAnalysisBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### Taste — always reported, never corrected

There is a feature behind each of these, so zurg only points out when the value chosen is the expensive way to have it.

| Preference | Plex default | zurg suggests | Why |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` or `never` | `asap` decodes each file the moment it lands, outside any maintenance window. `scheduled` keeps the Skip Intro button and moves the work into the window. |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` or `never` | The same, for Skip Credits. |

### The maintenance window

zurg does not touch `ButlerStartHour`/`ButlerEndHour`, because there is no hour that is right for everyone. It is worth setting by hand: Plex defaults to 02:00–05:00, and a window overlapping the hours anyone watches turns every maintenance task into a stall. Whatever survives in the bandwidth tier runs inside it.

### Stopping a pass already in flight

Changing a preference stops *future* runs, not the one already going. Plex Media Server respawns its scanner children, so killing them does nothing:

```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
