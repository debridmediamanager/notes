---
label: TorBox limits
icon: meter
order: 70
---

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
| `GET /torrents/requestdl` | ~100 calls at 20 concurrent before 429 | measured, May 2026 |
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
- **`requestdl` is far stricter than documented.** It is the endpoint that
  mints download URLs, and it gave out after roughly 100 calls where
  `user/me`, `mylist` and `checkcached` all handled 500+ at the same
  concurrency.
- **429 is a cliff, not a slope.** Once tripped, 100% of requests fail for
  about five minutes. There is no partial-throughput degradation to ride out.

CDN downloads are metered separately, per IP at the Cloudflare layer, and do
**not** share the API budget. Streaming a file never costs link-resolution
quota. That was verified in both directions: saturating CDN downloads to 429
left `requestdl` answering normally, and vice versa.

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
- **`requestdl` has a second limiter on top**, set to 60/min. A resolution
  spends from both, because the measured burst ceiling for that endpoint is
  roughly a third of the account's whole budget.
- **429 responses park every caller** for the `Retry-After` window rather than
  letting each one spend a request rediscovering the lockout. The lockout is
  account-wide, so a 429 met on any endpoint holds back all of them.
- **Concurrency is capped at 16 in-flight requests**, below the ~40 global
  burst ceiling, leaving room for the download client alongside.
- **The link cache is the main defence.** Resolutions are cached for 2h30m
  against the documented 3-hour link lifetime, so steady-state playback costs
  no `requestdl` calls at all.
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
- **Cache is checked before adding.** Cached adds fall under the 300/min
  budget; uncached ones consume the 60/hour allowance.

## Content expiry

Pro content expires after 30 days. Torrents come back from the API as
`expired` or `reported missing`, still reporting `download_finished: true`
with `download_present: false`.

Reading `download_finished` alone would mount a whole torrent whose every link
404s. Zurg maps both states — and the structural `finished && !present` case,
for wording not yet seen — to `error` status. `Capabilities.ContentExpires`
marks this as normal for the backend rather than a fault.

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
