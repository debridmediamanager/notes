# TorBox limits and how zurg adapts to them

Zurg's library behaviour grew around Real-Debrid's constraints. TorBox's are
different in kind, not just in magnitude, and driving it like Real-Debrid gets
the account rate-limited within seconds of a first library scan. This is what
the limits are, where the figures come from, and what zurg does about each.

Provider limits are declared in code as `debrid.Capabilities`, so the generic
library code reads them rather than assuming. Adding a backend means filling
that struct in, not editing the torrent manager.

## Rate limits

| Limit | Value | Source |
|---|---|---|
| All endpoints together, per API token | 300/min | [documented](https://api-docs.torbox.app/) |
| `POST /torrents/createtorrent` (uncached only) | 60/hour | documented |
| `POST /webdl/createwebdownload`, `POST /usenet/createusenetdownload` | 60/hour | documented |
| `GET /torrents/requestdl` | **~100 calls, then 429** — a budget, not a rate | measured, 2026-08-30 |
| Concurrent connections to one CDN host | **exactly 20**, 429 above it | measured, 2026-08-23 |
| Global burst ceiling | trips at ~40 concurrent, throttles *all* endpoints | measured |
| 429 recovery | `Retry-After: 300`, binary cutoff | measured |

Limits are per API token and synchronised across TorBox's servers — not per IP,
so extra clients on other machines share the same budget. TorBox says as much
explicitly: it stopped accepting IP whitelisting requests because the limit is
keyed on the token.

Three things make this harsher than the headline 300/min suggests:

- **The 300/min is not per endpoint.** It is one budget the whole key spends,
  so pacing each endpoint separately lets their sum cross a ceiling none of
  them crosses alone.
- **`requestdl` is far stricter than documented, and it is not a rate.** It is
  the endpoint that mints download URLs, and it gave out after roughly 100
  calls where `user/me`, `mylist` and `checkcached` all handled 500+ at the
  same concurrency.

  Slowing down does not buy more of them. Measured 2026-08-30 on the main
  account, three runs each starting from a cleared lockout:

  | Pacing | 429 arrived at | Elapsed |
  |---|---|---|
  | as fast as possible, ramped 60→240/min | call **100** | 56s |
  | one a second (60/min) | call **94** | 108s |
  | one every two seconds (30/min) | call **101** | 198s |
  | one every three seconds (20/min) | **never** — 241 calls | 721s, clean |

  Halving the rate bought ninety more seconds and no more calls; halving it
  again stopped the 429 happening at all. What the account holds is **100 calls
  per rolling five minutes — 20/min**, and only that reading fits all four
  runs: it predicts the trip at t≈100s, t≈200s and immediately for the first
  three, and predicts the fourth sitting exactly on the line and surviving.

  This is the correction that matters when reading the rest of this file. A
  per-minute limiter cannot keep zurg under a budget, so the pacing numbers
  below buy smoothness rather than headroom: a faster limiter does not finish a
  library scan sooner, it reaches the same lockout sooner and leaves the mount
  answering nothing at all for five minutes when it does. Spending *fewer*
  calls is the only thing that raises how far a scan gets, which is why the
  read-ahead is declined here and why naming a resolved file must never cost a
  request.
- **429 is a cliff, not a slope.** Once tripped, 100% of requests fail for
  about five minutes. There is no partial-throughput degradation to ride out.

CDN downloads are metered separately and do **not** share the API budget.
Streaming a file never costs link-resolution quota. That was verified in both
directions: saturating CDN downloads to 429 left `requestdl` answering
normally, and vice versa.

### Two different limits both numbered 20

The table above lists 20 twice and they are unrelated. Conflating them is easy
and leads to pacing the wrong thing.

- **`requestdl` at ~20 concurrent** is an *API* limit: roughly 100 calls at
  that concurrency before a 429, spending the account's request budget.
- **20 connections per CDN host** is a *byte-path* limit, measured 2026-08-23
  with a gradual ramp. It needs no `requestdl` call at all — reusing one
  already-minted URL is enough to hit it.

The byte-path ceiling is **exactly 20** and behaves as a hard cap rather than a
slope: 20 sustained whether 24, 32, 40 or 48 connections were requested, the
refusals rising to absorb everything above the line.

It is scoped to the **CDN host, not the object and not the IP**, which is a
correction to the older "per IP at the Cloudflare layer" reading:

- Two *different* files served from one `nexus-NNN` host share the single
  budget of 20 and refuse the same surplus.
- The identical workload split across two hosts runs clean.
- 32 concurrent streams spread over 16 hosts, all from one IP, are fine.

For scale against the other providers measured the same way: Real-Debrid caps
at 32 per host (refusing at the TCP layer, with no HTTP status), AllDebrid at
32 (HTTP 429), and Premiumize showed no ceiling at all up to 64. TorBox's 20 is
the lowest of the four.

**TorBox's global edges have no such cap.** The 20 is a property of the
per-node `nexus-NNN.<region>.tb-cdn.st` hosts that `requestdl` mints. The two
global edges — `nexus.erth.tb-cdn.earth` and `nexus.hare.tb-cdn.earth` — serve
any file in the account and both ramped to 64 concurrent connections with zero
refusals. Only the host differs; the path and token still authenticate the
request. zurg does not rewrite onto them today (the sibling `debrid` service
does, via `TORBOX_CDN_EDGE`), so the ceiling below is what applies here.

### What zurg does

- **`GetTorrentInfo` is served from the torrent list.** TorBox's `mylist`
  already includes every torrent's file list, so a library refresh costs one
  request instead of one per torrent. This is declared as
  `Capabilities.ListIncludesFiles`, and the refresh path skips both the
  per-torrent call and the on-disk info cache for providers that set it. On a
  213-torrent account this is the difference between 213 requests and 1.
- **One limiter paces every endpoint**, set to 240/min against the documented
  300, leaving headroom for whatever else holds the same key — the TorBox
  dashboard, another client, a second zurg.
- **`requestdl` has a second limiter on top**, set to 15/min. A resolution
  spends from both. The number is under the measured 20/min rather than on it,
  for the reason the general limiter sits at 240 against a documented 300: the
  budget is spent by everything holding the key, and 20/min was measured with
  nothing else on it. `TestTheRequestdlBudgetCannotBeSpentInsideItsWindow`
  holds the real invariant — the whole allowance must not be spendable inside
  the window that refills it — so the constant cannot quietly go back over.
- **The download client is capped at 20 connections per CDN host**
  (`maxConnsPerCDNHost` in `internal/torbox/client.go`, plumbed through
  `rdclient.HTTPClientOptions.MaxConnsPerHost`). Go's `MaxConnsPerHost` makes
  request 21 *wait for a free connection* rather than fail, so the cap turns a
  provider refusal into local queuing. Without it the download client inherited
  the general-purpose transport's unlimited setting and could collect 429s on
  the byte path while every API limiter was being respected.
- **429 responses park every caller** for the `Retry-After` window rather than
  letting each one spend a request rediscovering the lockout. The lockout is
  account-wide, so a 429 met on any endpoint holds back all of them.
- **Concurrency is capped at 16 in-flight requests**, below the ~40 global
  burst ceiling, leaving room for the download client alongside.
- **The read ahead is declined.** Zurg warms the next file of a release on a
  cold read, which every backend with a genuine per-minute budget absorbs. A
  library scan is the case that breaks it: it opens every file exactly once, so
  every one of those opens is cold, the warm-read refusal never fires, and the
  account is asked for two resolutions per file. Measured 2026-08-30, a
  forty-file scan drew exactly forty speculative resolutions alongside its
  forty reads — half the budget, spent on files nothing had asked for. TorBox
  declares `Capabilities.SpeculativeResolutionsAffordable` false and is asked
  for none.
- **Naming a resolved file costs no request.** Every resolution ends by looking
  up that file's name and length for the download record. That lookup went
  through the list snapshot, so once its thirty-second freshness window lapsed
  the next read fetched the whole torrent list before it could answer — during
  a scan, once every thirty seconds for as long as the scan ran, and on a
  3,700-torrent library that listing pages four times over. It now reads the
  listing already in hand however old it is, since a finished torrent's file
  names and lengths cannot change.
- **The link cache is the main defence, and it is held for a day.** A
  `requestdl` URL is not a signed grant with a lifetime — it is a deterministic
  address. Measured 2026-08-30: three calls for the same `(torrent, file)` came
  back byte-identical down to the delivery node, a call an hour later returned
  that same URL, and one minted 3h25m earlier still answered a ranged read with
  `206`, past the three hours the docs imply. The account's API key rides in
  the query string and is what authorises it; nothing in the URL is signed or
  stamped.

  So the cache is held for 24h rather than the old 2h30m, and the number is
  chosen against the scan rather than against a link lifetime. A first library
  scan costs one `requestdl` per file at 20/min, so it runs for hours — and
  every entry lapsing before it finishes is one the next pass buys again out of
  the same budget. At 2h30m a scan was covered for 2,250 files. The one way a
  cached entry still goes bad is content deleted or aged out of retention,
  which already self-heals: a 404 on a minted URL is read as a revoked link and
  re-resolved.
- **`bypass_cache=true` on every list call.** TorBox's own `mylist` cache has a
  ~5 minute TTL; serving from it is what makes WebDAV mounts lag 5–15 minutes
  behind reality. The parameter is free against the rate limit and drops
  propagation to under a second.
- **One poll costs one listing.** The library-change poll is the only caller
  that forces a fetch, since noticing a change is its entire job. The active
  count taken in the same tick, and the full refresh that follows a change,
  both read the snapshot it just filled. Forcing there too meant dumping the
  whole library two or three times per poll — at the default ten-second
  interval, thousands of redundant full-library reads a day against a service
  whose own list cache zurg is already bypassing.
- **The listing is walked in pages of 1000.** `mylist` caps a response at 1000
  torrents — the documented default for `limit`, and asking for more does not
  raise it — while reporting no total and no "there is more". A single request
  therefore answers a larger account with its newest 1000 and looks exactly
  like a complete library. Zurg pages by `offset` until a short page comes
  back, deduplicating ids as it goes: the list is ordered id descending, so a
  torrent added mid-walk shifts the window one place and repeats an entry
  across the seam.

## Account limits

| Plan | Active slots | Seeding | Max torrent size | Notes |
|---|---|---|---|---|
| Free | 1 | none | 10 GB | 1 add/24h, 10 adds/month, no private torrents |
| Essential | 3 | — | 200 GB | no cooldown, unlimited cached adds |
| Standard | 5 | 2 weeks | — | |
| Pro | 10 | 30 days | — | 30 day expiry |

Source: [Account Restrictions](https://support.torbox.app/en/articles/9836418-account-restrictions).

**Active slots are TorBox's defining restriction**, where Real-Debrid's is
bandwidth. A torrent occupies a slot while downloading *or seeding*, so on a
paid plan a completed torrent can hold one for up to 30 days.

### What zurg does

- **`GetActiveTorrentCount` reports the plan's real ceiling**, read from
  `plan` on the user record, so repair blocks and waits instead of queueing
  adds the account will reject. A provider reporting no ceiling is treated as
  unbounded rather than blocking forever.
- **Added torrents are marked never-seed.** Seeding holds a slot for weeks and
  bills outgoing traffic, neither of which helps a streaming mount.
- **Cache is checked before adding only in cached-only mode.** `checkcached` has
  one call site and it is the download client's `qbittorrent.download_timeout_mins: 0`
  path, where a miss must be refused inside the add rather than become a
  download. Every other add goes straight to `createtorrent` without a probe.
  Cached adds fall under the 300/min budget; uncached ones consume the 60/hour
  allowance.

## Content expiry

Pro content expires after 30 days. Expired torrents come back from the API as
`expired` or `reported missing` while still reporting `download_finished: true`
with `download_present: false`.

Reading `download_finished` alone would mount a whole torrent whose every link
404s. Zurg maps both wordings to `error` status and `Capabilities.ContentExpires`
marks that as normal for the backend rather than a fault.

**The two booleans are not on their own a sign the data is gone.** A healthy
uncached download reports `download_finished: true` with
`download_present: false` for the last 9.6 seconds of its life while it moves
through `processing` and `downloading` and `uploading`. Measured 2026-08-30 at a
0.5 second poll and written up in `docs/torrent-lifecycle.md`. Zurg used to read
that pair as death whatever the state string said and any instance running with
`delete_error_torrents: true` deleted such a torrent mid-download. Five probe
torrents were reaped that way on the day. The structural rule now decides only a
payload that carries no `download_state` at all. A wording this code has not seen
is treated as work in flight instead because `processing` was one of those
wordings until it was measured.

A read that reaches such a file anyway now costs more than one call. Since the
serving path treats a 404 on a minted delivery URL as a revoked link rather
than a missing file — which is what it is on Real-Debrid, whose codes die when
their downloads row is deleted — it re-resolves before giving up, so an expired
TorBox file spends up to four `requestdl` calls per read instead of one. It is
bounded per read, and the listing has already marked the torrent `error`, so
nothing walks an expired library at that rate; but a client hammering one
expired path pays four times what it used to.

### What zurg does

**Nothing re-adds an expiring backend's torrents on its own.** Repair fixes a
broken torrent by adding its magnet again, which is a repair on a backend that
keeps content and a re-download on one that expires it. Running that on a timer
across a library is the behaviour TorBox names first among the reasons an
account gets flagged — "excessive transfer retention (using tools to
artificially keep transfers active)" — and every uncached re-add is also an
incoming transfer counted against the plan's allowance.

So the periodic sweep skips torrents whose repairable copy sits on a provider
declaring `ContentExpires`. They stay broken and visible; the dashboard's
repair button still works, and a release also held on Real-Debrid still repairs
from that copy as usual. The distinction is who asked, not what broke.

## Usage and the abuse system

TorBox does not police requests. It measures bytes transferred over a rolling
15-day window against a threshold derived from the 99th percentile of each plan
tier, warns three times — **each warning rotates the API key** — and bans on the
fourth. The published floors, the lowest those dynamic thresholds may fall to:

| Plan | Floor |
|---|---|
| Free | 5 TB/month |
| Essential | 10 TB/month |
| Standard | 20 TB/month |
| Pro | 30 TB/month |

Both directions count: uncached adds coming in, and everything TorBox sends
out, whether to your device or back to the swarm. Cached adds do not.
Accounting is byte-perfect, so a partially-read file costs only what was read.

**`cooldown_until` on `/user/me` is not one of those warnings, and reading it as
one will cost you a day.** Verified 2026-08-12 on a plan-2 account with a
cooldown live and freshly set (24h out, `updated_at` a minute old): `/user/me`,
`checkcached` and `mylist` all answered `200 success:true`, WebDAV `PROPFIND`
returned `207`, and a `bytes=0-0` ranged read came back **`206` with a correct
`Content-Range` in 2.8s**. Nothing refused service at any layer. Lifetime
transfer on that account was 14.1 GB against a 30 TB/month floor, so it was an
API-rate cooldown, not a bandwidth strike. The discriminator is the **key**: a
real warning rotates it and every endpoint then returns `AUTH_ERROR`, whereas a
cooldown with an intact key has no observable effect. And since `checkcached`
can report a release cached that TorBox will not actually serve, **the ranged
read is the only probe that proves serving** — check the byte path before
concluding TorBox is unusable.

Source: [The TorBox Abuse System](https://support.torbox.app/en/articles/10336778-the-torbox-abuse-system).

### What zurg does

- **Added torrents never seed**, so nothing is billed on the way out for
  content zurg only ever reads.
- **Usage is sampled and differenced.** The API publishes no rolling figure,
  only a lifetime counter on `/user/me`, so the account refresher records that
  counter every 30 minutes to `data/torbox_usage.json` and differences the
  samples. A trailing-30-day figure crossing 80% of the plan's floor logs a
  warning. That warning is the whole point of the sampling — the dashboard
  shows only what zurg itself proxied, never these deltas. A fresh install has
  no history and says so rather than reporting a reassuring zero.
- **A rejected key is reported as a possible abuse warning**, not as a config
  typo and not as content breakage — since key rotation is exactly how TorBox
  delivers those warnings, and treating it as breakage would send the whole
  library to repair.

## Deliberately unmapped

An unrecognised `download_state` is reported as `downloading`, never `error`.
With `delete_error_torrents` enabled, an error status makes zurg delete the
torrent from the account — so a state TorBox introduces after this code was
written must not be able to cause deletions.
