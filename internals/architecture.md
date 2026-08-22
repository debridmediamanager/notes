---
label: Architecture
icon: cpu
order: 90
---

# Architecture

A map of what zurg is, how the pieces fit, and why each package exists. Aimed
at someone about to change the code: it names the load-bearing decisions and
the invariants that are easy to break without noticing.

Per-package detail lives in each package's `doc.go`. This document is the
level above that — the shape of the whole, and the reasoning that shape
follows from.

## What zurg is

A Go daemon that presents a debrid account's torrent library as a read-only
virtual filesystem. It stores no media. Every read is turned into a ranged
HTTP GET against the provider's CDN at request time.

Four views onto the same library:

| Endpoint | For |
|---|---|
| `/dav/` | WebDAV, what rclone mounts |
| `/http/` | HTML directory browser |
| `/infuse/` | WebDAV variant with Infuse's quirks accommodated |
| `/strm/` | Signed URLs inside `.strm` files, for players that want a URL not a mount |

rclone FUSE-mounts `/dav/`, so Plex, Jellyfin, Emby and Infuse see an ordinary
directory tree.

The design problem throughout is the gap between what a filesystem promises —
stable paths, instant `stat`, bytes on demand — and what a debrid API gives:
rate-limited JSON, links that rot, no filesystem semantics at all. Nearly
every package exists to close one part of that gap.

```
media player
    │
    ├─ rclone FUSE ──► /dav/  ──┐
    └─ direct HTTP ──► /http/ ──┤
                                ▼
                    internal/handlers  (chi router, auth, routing)
                                │
                internal/dav ───┤─── internal/htmlindex     (listings)
                                │
                                ▼
                    internal/torrent   (the library, in memory)
                                │  resolve link for this file
                                ▼
                    internal/universal (byte path, proxy/redirect, RAR)
                                │
                                ▼
                    internal/debrid    (Provider dispatch)
                                │
        ┌───────────┬───────────┼────────────┬──────────┐
        ▼           ▼           ▼            ▼          ▼
   realdebrid    torbox     alldebrid       nzb ──► nntp ──► par2
        └───────────┴───────────┘            (Usenet, no debrid service)
                    │
              internal/rdclient  (host rotation, rate limit, retry, DNS)
```

## Boot sequence

`cmd/zurg` is a thin Cobra CLI (serve, version, network-test, clear
downloads/torrents, mount control, download requirements). Everything real
happens in `internal/app.go`, whose `MainApp` is deliberately one readable
function:

1. Create the runtime directories (`logs`, `data`, `data/info`, `dump`,
   `strm`, `nzbs`) and the logger.
2. `ensureConfigAndRequirements` — load config, and download `ffprobe` and
   `rclone` if absent (`internal/requirements`). A first run with no config
   writes a default one and stops, unless the token came from the environment.
3. Initialise `strmlink` early, so an unwritable data directory is reported
   now rather than as `.strm` files that stop resolving after the next
   restart.
4. Run the **network latency test** against Real-Debrid's download hosts
   (`internal/rdclient`), or load its cached result from disk if fresh enough.
   This ranks CDN hosts and is what host rotation later draws on.
5. Build every configured provider from the registry, assemble them into a
   `debrid.Set`, and keep a typed handle on the first Real-Debrid one — the
   dashboard, the hosts page and the network test still speak to RD
   specifically.
6. Construct the `TorrentManager`, which immediately begins loading the cached
   library from disk in the background and then refreshing it.
7. Attach the chi router, start the HTTP server, then start rclone once the
   server is accepting connections.
8. Wait on SIGINT/SIGTERM/SIGQUIT; on signal, drain the HTTP server, stop the
   Plex service, and unmount rclone, each with a 20 s budget.

`ZURG_PPROF=1` opts into pprof on `127.0.0.1:6060` — loopback only, because
profiling a live instance is the only way to attribute CPU during a scan storm
but the endpoint must never be reachable from the network.

## Layer 1 — Config

`internal/config` is the single source of truth; nearly every other package
reads `ZurgConfigV1`. Typed getters apply defaults when a field is zero, so
callers never test for absence.

The substantial part is `filters.go`: a nested AND/OR filter language that
assigns each torrent to one or more **virtual directories**. This is what turns
a flat torrent list into `movies/`, `shows/`, `anime/`, `recent/`.

Conditions cover the torrent name (`regex`, `contains`, `not_regex`), its size,
its files (`any_file_inside_regex`, `any_file_inside_size_gte`), its tags
(`tags_match_any`, `tags_missing_all`), its age (`added_within_hours`,
`added_after`), derived properties (`has_episodes`, `is_music`), and which
account it came from (`provider`, `not_provider`). Per-directory display rules
sit alongside: `only_show_the_biggest_file`, size floors and ceilings.

Regexes used per torrent per assignment pass are compiled once at package
level — per-call `MustCompile` dominated startup measurably.

Config is editable live from the dashboard. `UpdateConfigFileAtomic` performs
key-level edits rather than re-serialising the file, so comments and unknown
keys survive.

## Layer 2 — Backend abstraction

`internal/debrid` is the spine. It owns the domain types every other package
speaks — `Torrent`, `TorrentInfo`, `File`, `Download`, `User` — and the
`Provider` interface each backend implements.

### Provider and capabilities

`Provider` stays small: list torrents, fetch info, delete, resolve a link,
verify it, fetch bytes, report account state. Anything a service might
reasonably lack is an **optional capability interface** that callers
type-assert and degrade on:

| Interface | What it adds | Who needs it |
|---|---|---|
| `MagnetAdder` | add by hash, select files, active-slot count | repair |
| `TorrentRestarter` | retry a failed torrent in place | repair, cheapest strategy |
| `CacheChecker` | is this hash instantly available | repair, before queueing |
| `HostRotator` | swap the CDN host pool | network test, `/hosts` page |
| `DownloadLister` | a separate hoster-downloads list | the `__downloads__` directory |
| `ArchivePasswordKeeper` | password for a release's archives | Usenet only |
| `PremiumMonitor` | time left on the plan | startup warning |

Alongside that, `Capabilities` is the provider's self-description — not what it
can do, but the limits it must be driven within. This exists because zurg's
library behaviour grew around Real-Debrid's shape, and hard-coding that shape
makes every other backend either broken or wasteful.

Two flags already drive real behaviour:

- **`ListIncludesFiles`** — the torrent list already carries per-file detail.
  Turns a cold library scan from one API call per torrent into one call total.
  The single most expensive difference between backends.
- **`StoredLinksCanRot`** — a stored link can die while the torrent still looks
  healthy, so links must be probed. This is a Real-Debrid property and an
  expensive one; on a backend that mints URLs on demand there is nothing to
  probe, and skipping the pass is the difference between a scan being free and
  it tripping an account-wide lockout.

The rest — `ServesLinksLocally`, `MaxActiveSlots`, `MaxConcurrentRequests`,
`AddsPerHour`, `ContentExpires`, `SupportsFileSelection` — are declared by every
backend and read by generic code. The zero value is deliberately the most
conservative reading, so a provider that forgets a field gets cautious
behaviour rather than a flood of requests, and a provider zurg cannot resolve
at all falls back to `unknownProviderCaps` in `internal/torrent/providers.go`,
which states that cautious answer once instead of at each call site.

A third shape exists that neither flag expresses: AllDebrid's list carries no
files, but its per-torrent endpoint takes a *batch* of ids. That is handled
inside the provider rather than by a capability, because it changes only how
the provider spends its own requests — the generic refresh still asks one
torrent at a time and needs to know nothing about it.

### Set

`Set` is every configured provider in config order, and is what the torrent
manager, handlers and dashboard depend on instead of any concrete client. Two
access patterns matter: **fan-out**, where an operation runs against every
account (a library refresh), and **dispatch**, where an operation must reach
the one account that owns a torrent (delete, resolve, repair). It also carries
account health/availability state.

### Link cache

`LinkCache` stores resolved URLs keyed **by token**, not just by link. A URL
minted under one token is only valid against that token's quota, so when a
token gets bandwidth-capped its entries must be abandoned wholesale rather than
reused under the next token in rotation. Entries expire on their `Generated`
timestamp rather than insertion time, so links primed from a provider's own
download list expire on the provider's schedule.

### The backends

| Package | What it is | The thing to know |
|---|---|---|
| `internal/realdebrid` | Real-Debrid, the original backend | Three separate HTTP clients: rate-limited API, rate-limited unrestrict, host-rotated download. Paris-local timestamps normalised at the package boundary and never leaked past it. `DownloadTokenManager` rotates tokens when one expires. |
| `internal/torbox` | TorBox REST | Uses REST with `bypass_cache=true` rather than TorBox's WebDAV, whose view lags reality by 5–15 minutes. No per-file link exists, so links are synthesised as `torbox://<torrent-id>/<file-id>` — stable across restarts and readable in logs, which a bare CDN URL carrying the API key would not be. Two stacked limiters: the documented 300/min, plus a much stricter one for `requestdl`. See [torbox-limits.md](../reference/torbox-limits.md). |
| `internal/alldebrid` | AllDebrid v4.1 | Form-encoded POSTs; a logical failure arrives as HTTP **200** with `status:"error"`, so the HTTP status never answers whether a call worked. Files live behind `/magnet/files`, which accepts a batch, so concurrent lookups are coalesced into single requests. The nested file tree is flattened depth-first, and that order is load-bearing. |
| `internal/nzb` | Usenet — not a debrid service at all | NZB files in `nzbs/` become torrents; reads fetch articles and yEnc-decode them on demand. Links are `nzb://<nzb-id>/<file-index>` and served locally, so `DownloadFile` synthesises the HTTP response instead of proxying one. |
| `internal/nntp` | Minimal Usenet client | Connection pool bounded by the account's connection allowance, BODY/STAT by message id, yEnc decode. A single connection gets a fraction of achievable throughput, so a file's reads fan out across the whole allowance. |
| `internal/par2` | PAR2 / Reed-Solomon over GF(2^16) | When an article has aged off the server, the release's own recovery volumes rebuild the bytes it carried. Expensive in a specific way — the arithmetic needs every surviving slice of every covered file, once — so it runs as a background job, one release at a time, and yields byte-span patches readers serve in place of silence. |
| `internal/rdclient` | Shared low-level HTTP | Host rotation across latency-ranked CDN endpoints, token-bucket limiting, retry with backoff, proxy support, custom DNS, IPv4/IPv6 forcing, geo-pinned CDN preference. `IPRepository` owns the network test and its on-disk cache. |

`internal/nzb` is the proof the abstraction holds. It implements the same
interface over a local directory and a news server, which works because the
interface's real contract is *"answer a ranged GET with bytes"*, not *"proxy a
CDN"*.

### Adding a backend

New package, implement `debrid.Provider`, call `debrid.Register` in `init`, add
a blank import in `internal/app.go`. Nothing in `internal/debrid` changes.

## Layer 3 — The library

`internal/torrent` is the core of zurg and its largest package. `TorrentManager`
holds the whole library in `cmap` concurrent maps for lock-free reads, assigns
torrents to directories by evaluating config filters, resolves and caches
links, and runs the background jobs.

### Persistence

Each entry is written to `data/<name>.zurgtorrent` as JSON, and per-torrent
info is cached under `data/info/`. A restart loads from disk and is immediately
serviceable, then refreshes — which matters because a cold scan is
rate-limit-bound, not CPU-bound. Torrents that have left the account can be
archived into `dump/` and surfaced as the `__dump__` directory
(`load_dumped_torrents`), with `/torrents/archive` and `/torrents/restore`
driving it.

Reserved directory names: `__all__`, `__unplayable__`, `__dump__`,
`__downloads__`, and one per account as `__<provider-name>__`.

### Torrent vs TorrentCopy

A release can live on more than one account. Zurg shows it once. The split:

- **Content facts belong to the entry** (`Torrent`): name, hash, which files
  exist, tags, IMDB id, rename.
- **Account facts belong to a copy** (`TorrentCopy`): the torrent ids that
  account minted, the links it hands out, its own broken state, its retry
  counters.

File ids in particular are per-account — Real-Debrid numbers files within a
torrent and marks a subset selected; TorBox lists only what it downloaded and
numbers it its own way — so `FileSource` holds `FileID` per provider. Repair
builds its selection from the ids of the copy it is repairing; reading the
wrong account's id re-adds the wrong files.

Copies are stored in config order, which is preference order. Reads prefer the
first healthy copy and fail over. Deleting the entry deletes every copy. An
entry with no copies does not exist.

### GetKey must stay pure

`GetKey` is a torrent's name in the virtual library — its directory entry, its
`.zurgtorrent` filename, and the handle every lookup goes through. It is
**recomputed at every lookup, never stored**, which rules out resolving name
collisions by checking what is already in use: the answer would change as the
library did, and a torrent would become unfindable under the name it was filed
as.

The only suffix is for the rarer clash where two *different* releases share a
name, and it is a tag of the content's own hash — as pure as the name itself.
The flag that turns it on is decided by the refresh pass, which can see the
whole library, and persisted on the torrent.

### Background jobs

| Job | File | What it does |
|---|---|---|
| Refresh | `refresh.go` | Poll each account, merge listed instances into entries, fetch info for new ones, assign directories, prune. Uses a cheap one-item fetch as a change check between full polls. |
| Repair | `repair.go` | Find and fix broken torrents. |
| Downloads | `manager.go` | Refresh the hoster-downloads list into `__downloads__`. |
| Network test | `handlers` | Periodically re-rank CDN hosts. |

Each job's interval is resettable at runtime through a channel, so changing the
config from the dashboard takes effect without a restart. Last-run timestamps
are persisted (`data/repair_timestamp`, `data/downloads_timestamp`) so a
restart does not re-run a job that just ran.

### Repair

The second-largest concern in the package. Files carry an FSM state
(`ok_file` / `broken_file`, via `pkg/fsm`); torrents and copies carry their own.
When links stop serving bytes, repair escalates through strategies:

1. **Restart in place** (`TorrentRestarter`) — cheapest: no new upload, no add
   slot spent, and the torrent keeps its id, so the library entry survives
   rather than being deleted and rediscovered.
2. **Re-download the broken files** — re-select only what is broken.
3. **Reinsert** — re-add the magnet and harvest fresh links.
4. **Archive** — last resort for releases that cannot be recovered.

Around that: exponential backoff, per-copy retry ceilings (`RepairCycles`,
`AssignRetries`, persisted so ceilings survive restarts), hourly add-budget
gates from `Capabilities.AddsPerHour`, active-slot checks, deduplication via a
set-backed queue, and a sweep-wide heuristic that reads a burst of
hoster-unavailable failures as one provider outage rather than as N broken
torrents. Unrepairable verdicts are recorded per copy and only propagate to the
entry when *every* copy carries one — a permanent Real-Debrid error says
nothing about the TorBox copy.

An operator can force a repair by hand; forced standing lives on the torrent
rather than the context, because a request arriving mid-sweep is parked in the
queue and picked up later under the sweep's own context.

### Everything else in the package

`mediainfo.go` (ffprobe analysis, feeding duration/codec tags), `tags.go`,
`rename.go` (renames that must survive refresh), `delete.go`, `strm.go`
(generating `.strm` files for the whole library), `hooks.go` (user scripts on
lifecycle events), `assign_links.go`, `unrestrict.go`, `opensubtitles.go`,
`provider_directories.go`, `reset_all.go`.

## Layer 4 — Serving

### Router

`internal/handlers` builds the chi router and wires everything. WebDAV's
non-standard methods (`PROPFIND`, `MKCOL`, `MOVE`) are registered on chi at
`init`. Basic auth wraps everything *except* `version.txt` (so healthchecks
work) and the `.strm` endpoints (a media player opening a `.strm` has no
credentials to offer — the signed token in the path authorises it instead).

Two routing lessons are recorded in comments and worth not relearning: chi
applies a regex path param **within a single segment**, so a file addressed
through an archive (`<archive>.rar/<inner>.mkv`) or a nested directory inside
one matched no route at all. Both needed trailing wildcards. And a path inside
a torrent is split between listing and download by its trailing slash, once the
route stops caring how deep the path is.

### Listings

`internal/dav` generates PROPFIND XML and handles DELETE, MOVE (renames, with
cross-directory and cross-torrent validation) and the Infuse variants.
`pkg/dav` does the XML itself with optimised string building rather than XML
marshalling, handles the RFC 3339 → RFC 1123 conversion WebDAV clients require,
and escapes paths for both URL and XML.

`internal/htmlindex` renders the same tree as HTML for `/http/`.

Both apply identical visibility rules — biggest-file-only, size thresholds,
broken/deleted state — and both collapse multi-volume RAR archives so only the
first volume is visible.

### The byte path

`internal/universal` is where a request becomes bytes:

- Link resolution deduplicated with `singleflight`, so a hundred concurrent
  reads of the same file cost one resolution.
- Proxy or redirect, per `disable_stream_proxy` — except a locally-served link
  (`ServesLinksLocally`) can never be redirected to, since the client has
  nothing to open.
- Re-unrestrict on a broken link, up to a small bound.
- A per-file network-failure cooldown: 3 consecutive errors parks the file for
  5 minutes, which is what stops an unreachable CDN host from becoming an
  infinite retry loop.
- Brief holds through a rate-limit window rather than erroring. Erroring reads
  during the short cooldown turns one throttled account into an error storm
  through rclone's VFS — stuck waiters, D-state readers, a wedged media server
  — so a held read is the cheaper answer. Longer cooldown classes still fail
  fast.
- Per-token bandwidth accounting, with counters reset at CET midnight to match
  Real-Debrid's daily traffic reset.

### Archives

`internal/rarstream` parses RAR4, RAR5 and ZIP headers over byte-range requests
(HTTP 206), builds a chunk map across volumes, and reconstructs a single file's
content on the fly. **No decompression** — only stored data is supported, which
is what scene releases use. `VolumeKey` and `IsVolume` normalise the many
multi-part naming conventions (`.part001.rar`, `.r00`, `.rar`) that `dav` and
`htmlindex` use to collapse volumes into one entry. Listings are cached on the
torrent and stamped with the parser's `ListingVersion`, so a listing produced
by a different parser is discarded rather than served.

### STRM

`internal/strmlink` encodes and signs the URL a `.strm` contains. The
Real-Debrid-only scheme it replaces was safe by accident: the URL held RD's
13-character download code, so possessing it *was* the proof of authorisation.
Other backends address files by trivially enumerable ids (`torbox://17/3`), so
the same shape would let anyone who can reach the port mint CDN URLs against
the account or spend its news-server connections. An HMAC over a secret in
`data/strm_secret` closes that — a token zurg did not write does not resolve.
The secret must outlive the process: every `.strm` already written stays valid
only as long as its signing key does.

### Dashboard and management

`internal/handlers/dashboard` renders the web UI from embedded templates,
pre-parsed at startup so a syntax error fails fast rather than at request time.
Pages: live torrent status, an interactive YAML config editor, host latency,
directory management, provider management, media-server connection status,
account/premium info, bandwidth, rclone status, and Plex "Wrapped" statistics.
Status fetchers for each media server run concurrently to keep page loads
responsive.

`internal/handlers/manage` is the per-torrent operations UI: tags, file
listings with state detail, Plex matching, renames, per-file delete/restore/
force-show, bulk delete and scan.

`internal/static` embeds CSS, favicon, logo and robots.txt with `go:embed`, so
the binary is self-contained.

## Layer 5 — The mount

`internal/rclone` supervises rclone as a subprocess: it builds the mount
command (a WebDAV remote pointing at zurg's own `/dav/`), starts and stops it,
health-checks every 30 s with exponential restart backoff (1 s → 60 s), and
restarts on failure.

An ephemeral RC port in 49152–65535 is chosen at startup for VFS cache
invalidation and status queries. That invalidation matters at two moments: once
the cached library finishes loading, and again after the first full refresh —
otherwise the partial listings the mount grabbed mid-load stick for the whole
`--dir-cache-time`.

Credentials are passed by environment variable, never on the command line.
`Controller` is the interface handlers and the dashboard consume; `Runner` and
`Command` abstract process management for tests.

## Layer 6 — Media servers

Two distinct things share the word "Plex":

- **`pkg/plex`, `pkg/jellyfin`, `pkg/emby`** are media-server *clients*, each
  satisfying `common.MediaServerWorker`. `pkg/common` provides the shared job
  lifecycle: an unbounded dynamic queue, per-job retry tracking, exponential
  backoff with jitter, a circuit breaker after consecutive failures, and
  stuck-job detection. It also holds the path helpers that deal with macOS
  case-insensitive APFS. `pkg/scan` sits on top as a unified `MediaScanner`
  that routes a path-refresh job to whichever server owns that path and reports
  per-server queue depth.
- **`internal/plex`** is zurg-specific behaviour: `Matcher` pairs torrents with
  Plex library items using file paths, IMDB ids and TVDb/TMDb identifiers,
  running periodically in worker pools with cached metadata, and backfills
  discovered IMDB ids onto torrents. `WatchlistMonitor` polls the Plex
  watchlist and auto-adds torrents, deduplicating by timestamp — that path uses
  `pkg/dmm` to search debridmediamanager.com for a magnet.

`pkg/mediabrowser` holds the types Emby and Jellyfin share.

## Layer 7 — Support

| Package | Purpose |
|---|---|
| `pkg/fsm` | Two flavours of tiny state machine: `FSMWithExternalMutex` for when the FSM is embedded in something already locked, `FSMWithTime` for when it needs its own lock and a transition timestamp (so `SinceWhen` can answer "how long has this been broken"). |
| `pkg/logutil` | Zap with dual output — coloured console and a rotating file (10 MB × 20 via lumberjack). Verbosity comes from `log_level` in config.yml, falling back to the `LOG_LEVEL` environment variable and then to DEBUG; the level lives in a shared `zap.AtomicLevel`, so the dashboard can re-level every logger at once without a restart. Includes reading the log back for the dashboard viewer and uploading it to 0x0.st for support. |
| `pkg/utils` | Blocked-host persistence, file visibility rules, token redaction, video/audio detection, `.strm` naming, and `GetZurgBaseURL` (which respects `X-Forwarded-*` behind a reverse proxy). |
| `pkg/script` | Runs user lifecycle-event scripts; PowerShell on Windows, `/bin/sh` elsewhere. |
| `pkg/dmm` | Client for debridmediamanager.com's search API, throttled to the server-side 1-per-2-seconds. Used by the watchlist monitor. |
| `internal/version` | Build metadata injected via ldflags; also the ASCII banner at `/http/version.txt`. |
| `internal/requirements` | Downloads platform-matched `ffprobe` and `rclone` from GitHub releases on first run and writes *relative* paths into config.yml, so the config stays portable. Unsupported platforms warn rather than fail. |
| `internal/clear` | Bulk-deletes RD downloads and torrents by driving the web interface with an auth cookie, looping until empty. |
| `internal/handlers/tmplcache` | Template caching for the dashboard. |

## Cross-cutting decisions

**Capabilities over `if provider == "realdebrid"`.** Anything that assumes
Real-Debrid's shape belongs behind a capability flag, not a type check. This is
the rule that keeps the torrent manager backend-agnostic.

**The interface's contract is bytes, not proxying.** `Provider` never promises
a remote CDN — only that a ranged GET is answerable. That is why a Usenet
backend fits. The two places the CDN assumption did leak (redirects, and
handing a URL to ffprobe, which needs something an external binary can open)
are both now guarded by `ServesLinksLocally`.

**Positional link pairing is load-bearing.** `TorrentInfo.Links[i]` pairs with
the i-th **selected** file in `TorrentInfo.Files`. A provider that cannot link
a file must report it *unselected* rather than omit it — otherwise every later
file silently resolves to the wrong link. Every backend must hold this.

**A torrent belongs to exactly one account.** Any call that reaches a service
must be dispatched via the torrent's provider (`ProviderFor`, `resolveLink`,
`verifyLink`, `DeleteByID`), never via the primary provider. Getting this wrong
deletes from the wrong account.

**Disk is a real tier.** `.zurgtorrent` entries, `data/info/` per-torrent
detail, network-test results and timestamps, job timestamps, the STRM signing
secret, RAR listing caches, blocked hosts. A restart resumes rather than
rescans.

**Everything is paced.** Per-provider token buckets, concurrency caps, hourly
add gates, link TTLs, per-file cooldowns, rate-limit holds. On TorBox
especially, link resolution is the scarce resource and the link cache in front
of it is what makes a library scan affordable at all.

**Reads are lock-free, writes are narrow.** Concurrent maps back the
directory/torrent/file trees; mutation is guarded by per-torrent locks
(`copiesMu`, `tagsMutex`, `operationsMutex`, `archiveCacheMutex`) rather than
anything global.

**`rdclient` is shared but its policy is Real-Debrid's.** Its error
classification and retry rules came from RD. It reports a non-2xx as an error
while still returning the response, so a provider needing the status — a 429
with `Retry-After` — must check `resp` before `err`.

## Build, test, deploy

- **Build**: `make build`. Version, commit and build time are injected via
  ldflags into `internal/version`.
- **Unit tests**: `go test ./...`. Pre-commit runs gofmt, golangci-lint,
  `go test -short`, and a full quality suite.
- **Integration tests**: `make integration-test`, cheapest first, with
  `refresh_repair` last because it waits out a full library scan. Run them on a
  host that has Go, rclone, FUSE and Plex together — elsewhere the mount and
  Plex tests skip loudly but still exit 0, so read the output rather than the
  exit code. See [e2e-test.md](e2e-test.md).
- **Docker**: two-stage Alpine build; the runtime image adds ffmpeg, rclone,
  fuse3 and a healthcheck.
- **Deploy**: `make deploy USER=… HOST=… DIR=…`, which stops Plex and the zurg
  services, swaps the binary, waits for `version.txt` to answer 200, then
  restarts Plex.

## Where to look first

The comments in this codebase consistently record *why* — usually the failure
that motivated the code. Every package has a `doc.go`. If you are changing
something, read that package's `doc.go` and the block comment above the type
you are touching before anything else; they carry the constraints that are not
visible from the signatures.
