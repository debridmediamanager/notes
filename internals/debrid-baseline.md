# The debrid baseline

What zurg costs and how fast it feels on the **debrid** path — Real-Debrid, AllDebrid
and TorBox. There is no competitor here. The contender is a later zurg, and this file
is what it has to beat.

- **Build under test:** `23869fa4` (`2026.08.18.0140-nightly-48-g23869fa4`)
- **Measured:** 2026-08-19, on `zen` (2 cores, 7.6 GB, Ubuntu 22.04)
- **Rig:** `scripts/dbench/`, deployed at `~/dbench` on zen

## How to read it

Three providers are not three competitors either. Their libraries differ by two orders
of magnitude — 3416 torrents on Real-Debrid, 479 on TorBox, 14 on AllDebrid — so an
absolute cold-build time says more about the account than about zurg. Every
size-dependent number is therefore given per torrent as well, and the comparison that
carries weight is always **this build against the next one on the same account**.

What is genuinely comparable across providers is the *shape* of the cost: how many API
calls a backend needs per torrent, whether it pays for link verification at all,
whether its change poll is a page or a token.

## Configuration

Each instance runs one provider, on its own port, with its own data directory. The
deviations from shipped defaults are only those isolation demands:

| Setting | Bench | Why |
|---|---|---|
| `host` / `port` | `127.0.0.1`, 9991-9994 | four instances on one host |
| `providers` | one per instance | attribute cost to a backend |
| `rclone_enabled` | `false` | measured over HTTP, never through FUSE |
| `directories` | one `all`, no filters | listing cost becomes a function of library size |
| `enable_repair` | `false` | TorBox is shared with the zurg on `fun`, and only one instance may repair an account |

Everything else is left at the shipped default *on purpose*, including two that shape
the numbers badly and are themselves findings:

- `log_level: DEBUG` — the shipped default (`pkg/logutil/factory.go`).
- `torrents_rate_limit_per_minute: 75` — the shipped default, and the binding
  constraint on a cold Real-Debrid build.

## Corpus

Twelve releases, the **same infohashes on all three accounts**, so a per-provider
difference is the provider and not the file. Sizes run from a 1.5 GB episode to a
334 GB remux pack; shapes cover single-file movies, season packs, and a 349-file
series pack. Entry 0 — `The Shawshank Redemption (1994) DS4K`, 7.31 GB, one file —
is the streaming subject for the latency and throughput phases.

Assembling it is the awkward part and is worth recording. TorBox's cache overlaps the
Real-Debrid library by about 2% (3 hits in 136 probes), so the corpus has to be driven
from TorBox's side rather than Real-Debrid's. AllDebrid held nothing and took the
magnets instantly, 14 of 16. Real-Debrid needed 20-45 s between adds against the 451
throttle, and refused two: one is the documented deterministic name block
(`Supergirl…WEB-DL…`, refused on a clean first attempt after a three-minute quiet
period), the other stayed throttled.

## Measuring API cost

zurg keeps no outbound request counter, and `log_requests` deliberately skips two
Real-Debrid endpoints — `torrents/activeCount` and `torrents?limit=1&…` — which
between them are the entire change-detection poll. Counting from the log would
therefore report Real-Debrid's idle cost as zero.

So the count is taken outside the process. mitmproxy terminates TLS, an addon writes
one JSONL line per request, and the instance is started with `HTTPS_PROXY` and
`SSL_CERT_FILE` pointing at the intercepting CA. Go's x509 loader honours
`SSL_CERT_FILE`, so the trust is scoped to that one process and nothing on the host is
modified. Requests are classified `api`, `nettest`, `content` or `other`.

The proxy sits in the request path, so it is used for the API-cost phases only; the
timing phases run direct. On TorBox — where the whole build is four calls — a
proxied run and a direct run came out at 3.0 s and 4.0 s, so at this scale the proxy
is inside the noise.

## Results

All numbers from build `23869fa4` on zen, 2026-08-19. Latency and throughput come
from one interleaved run over the same 7.31 GB file — same infohash on all three
accounts, and `ffprobe` reports the identical 8552.574 s duration through each, so
the content really is byte-identical.

### Cold library build

Empty caches to a compiled library. This is the one number that is not comparable
across providers — the accounts differ by two orders of magnitude — so read the
per-torrent columns.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Torrents | 3,316 | 14 | 479 |
| Time to compiled | **1,774 s** | 1.0 s | 3.0 s |
| Seconds per torrent | 0.535 | 0.071 | 0.006 |
| API requests | **7,442** | 7 | 4 |
| API requests per torrent | **2.24** | 0.50 | 0.008 |
| Non-2xx responses | **756 (10.2%)** | 0 | 0 |
| API bytes received | 2.87 MB | 27.9 KB | 298 KB |
| Startup network-test requests | 88 | 88 | 88 |
| Peak RSS | 77 MB | 26 MB | 52 MB |
| CPU seconds | 17.5 | 0.04 | 0.5 |

Real-Debrid's 7,442 calls break down as 3,414 `torrents/info` — one per torrent,
unavoidable without `ListIncludesFiles` — and **3,992 `unrestrict/link`**, which is
proactive link verification. It is the only backend with `StoredLinksCanRot: true`,
so it is the only one that pays this. TorBox answers the whole scan with a single
`mylist`, which is what `ListIncludesFiles` buys.

The Real-Debrid build was run twice, and the two agree closely enough that a future
build's improvement will not be noise:

| | run 1 | run 2 |
|---|---|---|
| Time to compiled | 1,774.5 s | 1,759.5 s |
| API requests | 7,442 | 7,391 |
| `unrestrict/link` | 3,992 | 3,933 |
| Non-2xx | 756 | 699 |
| CPU seconds | 17.5 | 16.1 |

#### What the failures are

The second run kept its flow log, so the 699 have a breakdown:

| Status | Count | Endpoint |
|---|---|---|
| 429 | 589 | `unrestrict/link` |
| 503 | 85 | `unrestrict/link` |
| 404 | **22** | `downloads/delete/{id}` |
| 451 | 3 | `unrestrict/link` |

Two separate problems, neither of them "the provider was flaky":

- **589 rate-limit rejections**, all on `unrestrict/link`. `api_rate_limit_per_minute`
  defaults to 250 and does not keep unrestrict inside whatever Real-Debrid actually
  allows, so roughly 8% of the cold build is refusals and retries.
- **22 of 23 `downloads/delete` calls returned 404.** The cleanup that is meant to
  balance 3,992 unrestricts is not merely rare, it fails when it runs — it is
  deleting ids that do not exist. Every unrestrict mints a persistent entry in the
  account's downloads list, and after these scans the test account held **12,469**.

One number moved between runs and is not yet explained: HEAD probes against
`*.download.real-debrid.com` were 88 in the first build and **3,426** in the second
(about one per torrent). It correlates with the downloads list having grown, and the
second run also fetched `/downloads` eight times against the first run's one, but
that is a correlation and not a cause. Worth pinning down before it is optimised.

### Warm restart

The cold cost is genuinely one-time.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Time to compiled | 4.0 s | 1.0 s | 2.0 s |
| API requests | 17 | 6 | 4 |
| Network-test requests | 8 | 0 | 0 |
| Peak RSS | 77 MB | 27 MB | 39 MB |

1,774 s becomes 4.0 s, and 7,442 calls become 17.

### Idle steady state

Ten minutes of a loaded library doing nothing. The ranking is set by what each
backend can be asked cheaply, and it is the clearest illustration of why
`LibraryFingerprinter` exists.

| | API calls/min | API bytes/min | CPU s / 10 min | Peak RSS | What it sends |
|---|---|---|---|---|---|
| AllDebrid | **4.0** | **867** | 0.20 | 28 MB | one Live Mode delta per poll, empty when unchanged |
| TorBox | 7.9 | 43.6 KB | 0.33 | 53 MB | pages `mylist` — no delta feed, no cache validators |
| Real-Debrid | 11.4 | 59.8 KB | 0.43 | 85 MB | `torrents?limit=1` + `activeCount`, plus `/downloads` |

Real-Debrid spends 32 of its 114 calls re-listing `/downloads` — the same list the
cold build grew to 12,469 entries.

This table is also the reason the count is taken through a proxy rather than from
`log_requests`: 80 of Real-Debrid's 114 idle calls are the two endpoints
`ShouldSkipLogging` suppresses, so the log would have reported its idle cost as
roughly zero.

### Listing

Not a bottleneck anywhere, at any library size.

| | Real-Debrid (3,312) | AllDebrid (14) | TorBox (479) |
|---|---|---|---|
| PROPFIND whole library, Depth 1 | 26 ms / 1.17 MB | 1 ms / 5.1 KB | 7 ms / 172 KB |
| HTML index | 14 ms / 645 KB | 1 ms / 2.4 KB | 3 ms / 90 KB |
| PROPFIND one release, Depth 1 | 1 ms | 11 ms | 3 ms |

### Press play

One 7.31 GB file, each read on a freshly started instance.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Cold open, 1 MB | 1.294 s | **0.476 s** | 0.565 s |
| Time to first byte, 64 MB | **0.158 s** | 0.203 s | 0.208 s |
| Scrub, median of 8 | 0.343 s | **0.259 s** | 0.356 s |
| Warm re-read, 64 MB | 2.065 s | 2.163 s | **1.960 s** |
| ffprobe | 1.98 s | 1.34 s | **0.99 s** |
| RSS | 75 MB | **30 MB** | 50 MB |

**The warm re-read is the same as the cold read.** On the Usenet path a repeat read
comes back in 0.05-0.17 s from the 512 MB LRU; here it costs a full fetch, because
the debrid path proxies the CDN and caches nothing. With `rclone_enabled: false`
this is zurg unaided — in a normal install rclone's VFS cache absorbs it — but as a
property of zurg itself, there is no warm path at all.

### Throughput

256 MB sequential reads, three reps, order rotating between reps.

| | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| Mean MB/s | 25.75 | 27.21 | **35.96** |
| Min-max MB/s | 20.09-29.57 | 17.52-32.21 | **34.31-37.57** |
| CPU s per GB | 7.8 | **5.3** | 7.9 |
| TTFB median | 1.023 s | **0.267 s** | 0.489 s |
| Peak RSS | 88 MB | **29 MB** | 55 MB |
| Completed reads | 3/3 | 3/3 | 3/3 |

TorBox is both the fastest and much the steadiest; the other two swing by 40% between
reps. Real-Debrid's median TTFB under load is four times AllDebrid's.

### Where cold open actually goes

`apiref.py` measures the provider's own half — the call that turns a stored file into
a fetchable URL, and the first byte off that URL — with zurg out of the path. It was
run twice; the first run predates the AllDebrid fix, so that row has one sample.

| | resolve | CDN TTFB | provider total | zurg cold open | zurg's share |
|---|---|---|---|---|---|
| Real-Debrid, run 1 | 0.133 s | 0.267 s | 0.400 s | 1.294 s | **0.89 s** |
| Real-Debrid, run 2 | 0.157 s | 0.383 s | 0.540 s | 1.294 s | **0.75 s** |
| AllDebrid | 0.139 s | 0.333 s | 0.472 s | 0.476 s | 0.00 s |
| TorBox, run 1 | 0.260 s | 0.277 s | 0.537 s | 0.565 s | 0.03 s |
| TorBox, run 2 | 0.270 s | 0.381 s | 0.651 s | 0.565 s | ~0 |

The provider figures and the zurg figures come from different moments, so the
subtraction is indicative rather than exact. The pattern holds across both runs:
AllDebrid and TorBox add essentially nothing over what the provider itself costs,
Real-Debrid adds 0.75-0.89 s. That gap is the single clearest thing to aim at.

### All three providers in one instance

The merged instance carries every account at once, and the corpus is deliberately on
all three, so it exercises the path where one release is held by several accounts.

| | Real-Debrid alone | All three merged |
|---|---|---|
| Torrents seen | 3,316 | 3,781 |
| Unique releases | 3,318 | 3,778 |
| Time to compiled | 1,774 s | 1,775 s |
| API requests | 7,442 | 7,491 |
| Peak RSS | 77 MB | 82 MB |
| PROPFIND whole library | 26 ms / 1.17 MB | 23 ms / 1.34 MB |

Adding TorBox and AllDebrid to a Real-Debrid instance is close to free: 465 more
torrents for 49 more API calls and 5 MB of RSS, and no measurable time. The merge is
real — 3,809 torrents across the three accounts separately become 3,781 here, the
corpus collapsing from three copies to one.

### Add and delete detection

How long from a change at the provider to the mount agreeing.

| | Delete detected | Add detected |
|---|---|---|
| Real-Debrid | 18.7 s | 12.7 s |
| AllDebrid | 16.5 s | 14.4 s |

Both are inside one `check_for_changes_every_secs` tick plus a refresh, so neither is
waiting on `library_resync_every_mins`. TorBox was not tested: the probe release is
permanently on that account and deleting it is not reversible without a re-add that
might not be cached.

### Provider outage, CDN up

`ca/outage.py` makes every provider API call return 503 while content requests pass
through, then zurg is started into it.

| | Read before | Library compiled under outage | Read during outage |
|---|---|---|---|
| Real-Debrid | 206, 1.60 s | never (180 s) | timed out at 120 s |
| AllDebrid | 206, 0.44 s | never (180 s) | timed out at 120 s |
| TorBox | 206, 1.53 s | never (180 s) | 400 in 0.035 s |

**Starting zurg while its provider is down produces an empty mount.** That is the
scenario that matters operationally — a host reboots during a Real-Debrid 503 spell —
and it is the exact condition that destroyed 30,065 Plex items on `fun` in August,
where a momentarily empty mount during a scan reads as "every file was deleted". The
guard for that lives in Plex (`autoEmptyTrash 0`), not in zurg.

Real-Debrid and AllDebrid additionally make the reader wait out its own timeout
rather than failing fast; TorBox answers in 35 ms.

### A transient 503 leaves releases as empty folders

The clearest defect of the run, and it was found by accident.

Of the 3,316 torrents in a Real-Debrid cold build, **85 responses were 503** and
**84 torrents ended up in `broken_torrent`**. A release in that state is still listed
in the mount, but its directory is **empty** — verified by PROPFIND against two of
them, both holding 10 and 3 selected files in their stored record and serving none.

It does not clear by itself. The bench runs with `enable_repair: false`, and those
releases were still broken more than an hour and several restarts later.

Turning repair on — the shipped default — does work through them, but slowly. With a
pass triggered by hand:

| Elapsed | Broken | Under repair |
|---|---|---|
| 0 min | 85 | 0 |
| ~2 min | 77 | 2 |
| ~15 min | 73 | 4 |

Twelve releases in a quarter of an hour, and the rate falls off after the first
minutes. On that trajectory a single cold build's worth of breakage takes upwards of
an hour to clear, and every unreached release is an empty folder for the whole of it.

So the severity depends on a setting:

- With repair on (default), a 503 during a scan costs a release its files until a
  repair pass reaches it — order of an hour for a full library.
- With repair off, the release is an empty folder indefinitely.

TorBox has the sharper version of this. It reports `StoredLinksCanRot: false`, so
refresh never re-verifies its links — there is no path that clears a broken state
short of repair. The one TorBox release marked broken during the outage test was
still broken 68 minutes and several restarts later, while its provider reported it
`cached`, `download_present`, one file, 7.31 GB.

### Read integrity

One AllDebrid read in the first throughput run returned 263,798,425 bytes for a
268,435,456-byte range, with a 206 and no error. It **did not reproduce**: eight
repeats each on Real-Debrid and AllDebrid returned the full range every time. Recorded
as a one-off rather than a defect, and worth watching for.

## Under Plex's load

Everything above is one reader at a time, which is not how a media server behaves.
Plex scans — thousands of files, a little of each — and Plex streams, and the two
overlap. These phases measure the mount under both.

**Read the aggregate figures as a property of zen, not of zurg.** Every target
plateaus at 73-78 MB/s whatever the provider and whatever the mode, which is the
host's link. What generalises is the *completion rates* and the per-provider failure
shapes; the ceiling is local.

### Multiple readers, different files, one provider

96 MB per stream, distinct files.

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 1 | 44.8 | 52.1 | 45.6 | 51.8 |
| 2 | 72.3 | 63.5 | 71.4 | 69.8 |
| 4 | 73.7 | 64.2 | 74.6 | 70.2 |
| 8 | 73.6 | 73.4 | 65.5 | 75.1 |
| 12 | 77.1 | 73.8 | 76.3 | 77.1 |

Aggregate MB/s. The pipe is full at two streams; past that, more readers divide the
same bandwidth — per-stream median falls from ~45 MB/s at one to ~8 MB/s at twelve.

Completion is the interesting column:

| streams | Real-Debrid | AllDebrid | TorBox | merged |
|---|---|---|---|---|
| 4 | 4/4 | **2/4** | 4/4 | 4/4 |
| 8 | 8/8 | **3/8** | 8/8 | 8/8 |
| 12 | 10/12 | **4/12** | 9/12 | 10/12 |

**AllDebrid stops completing reads from four concurrent distinct files.** Bytes still
flow — its aggregate stays at the host ceiling — but individual streams do not finish,
and the per-stream median drops to zero at eight and twelve with TTFB medians above
3 s. Everything else holds until twelve, where all four lose one or two.

### Multiple readers, one file

Same levels, one file, different offsets — the read-ahead-plus-seek shape.

| streams | Real-Debrid | AllDebrid | TorBox |
|---|---|---|---|
| 4 | 4/4 | 4/4 | 4/4 |
| 8 | 8/8 | 8/8 | 8/8 |
| 12 | 10/12 | 9/12 | 10/12 |

AllDebrid is **fine** here — 4/4 and 8/8 — while it was 2/4 and 3/8 on distinct files.
That inversion is the diagnosis: its limit is not bandwidth and not a per-torrent cap,
it is concurrent **link resolution**. Distinct files mean distinct unlocks; one file
resolves once and then just streams.

### Multiple readers across different providers

This is the mixed-provider case, and it needs a corpus the matched one cannot
provide. Since the merged instance serves a multi-account release from `Sources[0]`,
every read of the matched corpus lands on Real-Debrid. So the pool here is
provider-*exclusive*: 8 files only Real-Debrid holds, 7 only AllDebrid, 8 only TorBox.

| streams (per provider) | aggregate MB/s | completed | RD | AD | TB |
|---|---|---|---|---|---|
| 3 (1 each) | 55.3 | 2/3 | 28.8 | — | 27.9 |
| 6 (2 each) | 66.9 | 5/6 | 16.1 | 13.3 | 21.5 |
| 12 (4 each) | 75.9 | 11/12 | 7.4 | 8.4 | 9.0 |

Per-provider columns are per-stream medians in MB/s.

Reads on different accounts do genuinely run in parallel — but they arrive at the
same 76 MB/s host ceiling that one provider reaches on its own. **On this host,
mixing backends buys no bandwidth.** Whether it buys any elsewhere depends on having
a link fatter than one provider will fill, which zen does not. What it buys instead
is availability — and only partly, as the failover section below shows.

The consistent one failure is a single AllDebrid file whose CDN hostname,
`l4m5n6.debrid.it`, resolves to **0.0.0.0**. That is AllDebrid handing out a dead
link, not zurg — but zurg spends about 4 s on three retries before returning 500, and
because the file is on no other account there is nothing to fall back to.

### Failover: only from one direction

Since the merged instance cannot spread load, the thing it is supposed to buy is
survival of one account going bad. `ca/cdnfail.py` refuses one account's CDN while
leaving every API and the other accounts alone, so the library still loads and only
the bytes are affected. The releases read are the matched corpus — all three accounts
hold every one of them.

| CDN taken down | reads served | what the read did |
|---|---|---|
| Real-Debrid | 2/2 | fell back to AllDebrid, 0.6 s |
| AllDebrid | **0/3** | one attempt at AllDebrid, 503, then **500 to the client in 0.1 s** |

**Failover only happens when the failing account is Real-Debrid**, and the reason is a
capability the other backends do not set. Refresh proactively verifies links only when
`StoredLinksCanRot` is true, which is Real-Debrid alone:

```
Link verification failed during refresh for /A.Business.Proposal…: (code: 503)
```

That is what demotes the source, after which reads move to another account cleanly.
AllDebrid and TorBox are never probed, so a dead CDN on either is never noticed, the
source is never demoted, and every read of that release returns 500 — for as long as
the condition lasts.

Two further things this shows:

- **The read path has no inline fallback at all.** A 503 from the chosen account's CDN
  is turned straight into a 500 for the client in 0.1 s; the other accounts holding
  the same file are not tried. Recovery is entirely the background refresh's job, so
  even in the Real-Debrid case there is a window where reads fail.
- It is the same missing mechanism behind the TorBox release that stayed
  `broken_torrent` for 68 minutes. Nothing re-verifies a TorBox or AllDebrid link, so
  nothing clears a bad state or notices a recovered one.

### A dead link from the provider

One AllDebrid file in the exclusive pool failed every single time it was touched — in
each scan run and each mixed-reader run. Its CDN hostname resolves to a null route:

```
$ getent hosts l4m5n6.debrid.it
::              l4m5n6.debrid.it
0.0.0.0
```

AllDebrid handed out a link pointing at `0.0.0.0`. That part is the provider's, not
zurg's. zurg's part is what it does about it: three attempts over roughly 4 s, then a
500. The file is on no other account, so there was nothing to fall back to — but the
failover result above says it would not have fallen back anyway.

### Scanning

`ffprobe` over the whole 23-file mixed pool, which is the shape of a Plex analysis
pass.

| concurrency | files/min | per-file median | per-file max | CPU s |
|---|---|---|---|---|
| 1 | 43.7 | 1.16 s | 3.11 s | 2.22 |
| 4 | 112.0 | 1.67 s | 4.19 s | 1.29 |
| 8 | 142.3 | 1.87 s | 6.67 s | 1.16 |

Scanning parallelises well — 3.3x from one thread to eight, with per-file latency only
rising 60%. For the 3,316-release Real-Debrid library that is roughly **76 minutes at
one thread and 23 minutes at eight**, before Plex's own work.

### Streaming while scanning

The case worth fearing, since a scan against a momentarily unhappy mount is what cost
30,065 Plex items on `fun`.

| scan concurrency | stream alone | stream during scan | kept | scan wall |
|---|---|---|---|---|
| 4 | 57.7 MB/s | 66.5 MB/s | 115% | 11.8 s |
| 8 | 67.8 MB/s | 66.8 MB/s | 98.5% | 9.7 s |

**A scan does not starve a stream.** The viewer keeps essentially all of its
throughput, and its time-to-first-byte actually improves (1.18 s to 0.15 s) because
the link is already warm by then. This is the one place the debrid path behaves
better than feared.

## Defects this run surfaced

Ordered by what they cost.

1. **A transient 503 leaves a release as an empty folder.** 85 x 503 during one cold
   build put 84 releases into `broken_torrent`, and a broken release is listed with
   no files in it. With repair off it never clears; with repair on it clears only
   when a pass reaches it. On TorBox there is no re-verification path at all
   (`StoredLinksCanRot: false`), and the one release broken there was still broken
   68 minutes later while the provider reported it cached and present.
2. **Download-entry cleanup is broken, and the cost compounds.** 3,992
   `unrestrict/link` against 23 `downloads/delete`, and **22 of those 23 returned
   404** — the cleanup deletes ids that do not exist. The account went from 12,469
   entries to **18,768** over two further cold builds, and zurg pages the whole list
   at startup 5,000 at a time, so the leak turns into a startup cost that grows with
   it.
3. **589 rate-limit rejections in one cold build.** All on `unrestrict/link`, about
   8% of the pass. The default `api_rate_limit_per_minute: 250` does not hold
   unrestrict inside Real-Debrid's real limit. These and the 503s are the same event
   that produces defect 1.
4. **Starting into a provider outage yields an empty mount**, and a read against
   Real-Debrid or AllDebrid then hangs until the client's own timeout rather than
   failing fast. TorBox answers 400 in 35 ms.
5. **AllDebrid stops completing concurrent reads of different files.** 2 of 4, 3 of 8,
   4 of 12. The same levels against a *single* file are fine (4/4, 8/8), so the limit
   is concurrent link resolution, not bandwidth or a per-torrent cap. Four files
   playing at once is an ordinary evening for a household.
6. **A multi-account release always serves from the same account.**
   `File.PrimarySource` returns `Sources[0]`, so the choice is whichever account was
   seen first — verified 7 of 7 corpus releases served by Real-Debrid while AllDebrid
   and TorBox held identical copies. It never picks the faster or less loaded account.
7. **Failover works in one direction only, and never inline.** With Real-Debrid's CDN
   refusing, reads moved to AllDebrid; with AllDebrid's refusing, 0 of 3 reads were
   served and each returned 500 in 0.1 s without trying the two accounts that held
   the same file. Only Real-Debrid sets `StoredLinksCanRot`, so only its links are
   re-verified during refresh, and only its failures demote a source. Nothing in the
   read path tries a second account on an error.
8. **The startup network test runs for every backend.** 88 HEAD requests against
   Real-Debrid download hosts on a TorBox-only and an AllDebrid-only instance, which
   have no use for the result.
9. **A collection's own PROPFIND href 404s.** zurg emits `<d:href>/all/…</d:href>`,
   dropping the `/dav` prefix; fetching that path returns 404. Children are emitted as
   bare relative hrefs, so only the self entry is wrong. RFC 4918 wants an href a
   client can resolve, and rclone and Plex only cope because they do not use it.
10. **`user`/`user/me` is called three times on every startup**, cold or warm, on both
   TorBox and AllDebrid.

## Not defects, but worth knowing

- **Real-Debrid does not deduplicate by infohash.** Adding a magnet already on the
  account creates a *second* entry. That is why the 3,416 torrents compile to 3,318
  unique releases, and it invalidated the first delete-detection probe, which deleted
  the duplicate it had just created and concluded nothing was ever detected.
- **`torrents_rate_limit_per_minute` defaults to 75**, which is what bounds the cold
  Real-Debrid build. It is a deliberate default, not a bug, but it is the number that
  sets the 29-minute figure.

## Rerunning

```bash
cd ~/dbench && ./runall.sh          # p1..p6
./p7.py adddel rd,ad && ./p7.py outage rd,ad,tb
./apiref.py rd,ad,tb                # provider-side reference latency
./report.py                         # tables
```

Never run two instances at once, and only compare numbers from a single interleaved
run — provider throughput drifts widely across an evening.
