---
label: E2E testing
icon: beaker
order: 30
---

# E2E Testing

End-to-end tests to verify zurg is working correctly after deployment.

## Plex Playback Test

Verifies that content is actually playable via Plex by selecting a random movie and testing the full playback pipeline.

### Run the Test

```bash
./scripts/plex-e2e-test.sh
```

The script automatically reads `plex_server_url` and `plex_token` from `config.yml`.

To override with custom settings:
```bash
PLEX_URL="http://your-plex:32400" PLEX_TOKEN="your-token" ./scripts/plex-e2e-test.sh
```

### What It Tests

| Step | Description |
|------|-------------|
| 1 | Find Movies library via Plex API |
| 2 | Get total movie count |
| 3 | Select random movie |
| 4 | Get stream URL for the movie |
| 5 | Verify stream is accessible (HTTP 200) |
| 6 | Decode 3 seconds of video with ffmpeg |
| 7 | Create and verify Plex session tracking |

### Expected Output

```
=== Plex E2E Playback Test ===

[1/7] Finding Movies library...
  Library key: 15
[2/7] Getting movie count...
  Total movies: 1234
[3/7] Selecting random movie...
  Selected: 2 Fast 2 Furious (2003) (ratingKey: 756524)
[4/7] Getting stream URL...
  File size: 54GiB
[5/7] Verifying stream accessibility...
  HTTP Status: 200 OK
[6/7] Decoding video (3 seconds)...
  Decoded 72 frames successfully
[7/7] Testing Plex session tracking...
  Session created and tracked

=== TEST PASSED ===
Movie '2 Fast 2 Furious (2003)' is playable via Plex
```

### Prerequisites

- Plex server running and accessible
- `plex_server_url` and `plex_token` configured in `config.yml`
- `curl`, `jq`, and `ffmpeg` installed

### Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| No movie library found | Wrong library type or empty | Check Plex has a "Movies" library |
| Stream not accessible (HTTP 4xx) | Auth or path issue | Verify token and file exists |
| Failed to decode video frames | Corrupt file or network issue | Check zurg logs, try different movie |
| Session not detected | Plex session timeout | Check Plex logs |

## Integration Suite

```bash
ssh ben@fun
cd ~/zurg && make integration-test
```

**Run it on `fun`.** It is the only host with all of Go, rclone, FUSE, Plex and
a Usenet account, so it is the only place all six tests actually execute. Elsewhere the ones that
cannot run skip — loudly, but they still exit 0, so read the output rather than
the exit code. `zen` has Plex but no Go toolchain and no zurg mount, so it
cannot run the suite at all.

| Test | Needs FUSE | Needs Plex | Needs a Usenet account |
|------|:----------:|:----------:|:----------------------:|
| `refresh_repair_integration.sh` | | | |
| `network_test_cache_integration.sh` | | | |
| `rclone_mount_integration.sh` | yes | | |
| `magic_mount_integration.sh` | yes | | |
| `plex_integration.sh` | yes | yes | |
| `nzb_bench_integration.sh` | | | yes |

`force_location_integration.sh` is **not** in the suite — it asserts something
about this host's network path to Real-Debrid's CDN rather than about zurg, so
it fails where that path cannot answer regardless of the change under test. Run
it on purpose with `make force-location-test`, on a host with working IPv4 to
the region being forced. See [Force Location Integration Test](#force-location-integration-test).

The first five drive the same Real-Debrid account — see
[the account is shared](#the-real-debrid-test-account-is-shared). The benchmark
drives a news account instead and touches Real-Debrid not at all, but it takes
the same host-wide lock as the rest: a run measured beside another suite's reads
is measuring the other suite.

The mount test runs on a Mac too when macFUSE is installed — it is verified on
both macFUSE and Linux `fusermount`. The Plex test needs `plex_server_url` and
`plex_token` in the config it reads, which a laptop's `config.yml` normally
lacks, so that one is `fun`-only in practice.

`make integration-test` builds zurg, runs shellcheck over the scripts, the
`lib.sh` self-test and `integration/nzbbench`'s unit tests, then runs all seven,
cheapest first: network test cache, force location, rclone mount, Plex,
`__magic__` mount, refresh/repair, and the Usenet benchmark last. The last two
are the expensive ones — refresh/repair waits out a full library scan, and the
benchmark reads gigabytes off a news server twice over — so a mistake in any of
the others should not cost that wait to discover.
`make integration-test-media` runs just the three that need a real mount, and
`make nzb-bench-test` just the benchmark.

Each script owns a work dir under `$TMPDIR`, its own port, and writes zurg's log
there; the suite runs with `STREAM_LOGS=false`, so only the test's own
assertions reach the terminal. Set `STREAM_LOGS=true` to follow zurg's log on
stderr while debugging.

Shared helpers live in `integration/lib.sh` (process control, the Real-Debrid
API, on-disk library queries) and `integration/lib_media.sh` (FUSE and Plex).
Add a test by sourcing them, not by copying another script.
`integration/lib_test.sh` covers the helpers themselves: no account, no network,
about a second.

### The Real-Debrid test account is shared

The suite drives one Real-Debrid test account, and that account is not private.
`zen`'s production zurg watches the same library, so it lists and refreshes the
very torrents a test has just added. Any instance on the account **with repair
enabled** also verifies, repairs and tidies them.

Both failures below were diagnosed on 2026-08-23, when `macmini`'s zurg ran on
this account with repair on every 10 minutes. That instance was stopped on
2026-08-29 and nothing supervises it, and zen's runs with `enable_repair:
false` — so as of 2026-09-01 neither failure has a live source. They come back
the moment repair is switched on anywhere on this account, which is why the
serialisation below still stands.

What that does to a run, after four of the six scripts failed on the build under
test *and* on its baseline:

- **A fixture that never appears.** Real-Debrid dedupes download ids per link,
  and deleting a downloads row revokes that code for everyone holding it.
  Another instance's cleanup revokes the code this run just resolved, this run's
  verification answers `404 invalid_download_code`, and zurg files the file as
  broken — a broken torrent is hidden from every listing. The test then says
  `zurg serves the fixture over HTTP but it never appeared under .../mnt/movies
  within 180s`, which reads as a mount or dircache bug and is neither.
- **A delete that gets undone.** A repairing instance re-adds a torrent this run
  has just deleted, so `refresh never dropped <hash> after it was deleted from
  the account` fails against a library that is reporting reality correctly.

Delete and repair assertions are the ones that suffer. Before blaming a change,
read the failure context described below — and if a run has to be clean, stop
the other instances' repair first.

**No two of these scripts may run at once**, on this host or from another
session on it. They share the account's per-minute API budget, so a pair draws
`API rate limit (code=34)` and assertions start failing on traffic rather than
behaviour (measured on `fun`, two parallel runs); and each script deletes
torrents *by hash*, so one run's cleanup will happily delete the other run's
fixture. Every script therefore takes a host-wide lock at the top of `main`,
before its first API call, and holds it until it exits.

| Variable | Default | Description |
|----------|---------|-------------|
| `INTEGRATION_LOCK_FILE` | `$TMPDIR/zurg-integration-rd.lock` | The lock. `flock` where it exists, a pid-stamped `.d` directory otherwise (macOS ships no `flock`) |
| `INTEGRATION_LOCK_WAIT` | `0` | Seconds to queue behind a run in progress. `0` refuses at once, which is what you want — the alternative is sitting an hour behind a cold scan |

A lock left behind by a killed run is reclaimed automatically: the directory
carries the holder's pid, and `flock` is released by the kernel. The lock says
nothing to zen or macmini, of course — it only keeps this host's runs apart.

**Reading a failure.** Every `fail` now prints, from that run's zurg log: the
count of each shared-account symptom — `invalid_download_code`,
`hoster_unavailable`, rate-limit lines, `code=34`, `Link verification failed`,
`keeping files as broken`, `broken_file]`, `Deleted downloads entry` — then the
last ten of those lines, then the last few lines naming the fixture under test.
`none present, so this failure is probably zurg's own and not the account's` is
the line that says to go look at the code instead.

`docs/realdebrid-behavior.txt` has the link semantics underneath all this:
which links redeem from which account, and why `unavailable_file` and
`hoster_unavailable` mean different things.

### Runtime

The first run against a given work dir pays for a cold library scan: one info
call and one link verification per torrent, paced by the account's API budget.
On a few-thousand-torrent account that is tens of minutes — this account held
3,361 torrents on 2026-08-29, enough to draw sustained `code=34` and take around
twenty minutes a script. The work dir keeps three caches between runs so later
runs skip it: `info/`, `linkcache/`, and the network test results. Delete the
work dir to force the cold path.

`linkcache/` is what `internal/debrid.LinkCache` persists, one file per provider
instance. It is the half that removes the twenty minutes: the first sight of a
torrent resolves one of its links to verify it, which is an `unrestrict/link`
call per torrent with an empty cache and free with a warm one. The benefit is
bounded by the cache's 4h TTL — a suite re-run the next day is cold again — so
it shortens iteration, not a first run.

Neither `info/` nor `linkcache/` is link-free, and both hold codes another
instance on the shared account can revoke: a `.zurginfo` is a verbatim
`TorrentInfo`, so it carries the torrent's Real-Debrid `/d/` codes, and
`linkcache/` carries what those resolved to. Both stay preserved anyway.
Rebuilding them is what costs the tens of minutes, and a revoked entry is not a
wrong answer — verification gets `404 invalid_download_code`, zurg invalidates
that entry and re-mints, so only the revoked entries pay a call. Expect some
every run, and expect the speedup to vary with how many.

A fixture is narrower still: `clean_state_for_hash` deletes the `info/` entries
whose hash matches it, so its link list is always re-fetched from the account.
`linkcache/` is keyed by link rather than by hash and is not swept per fixture,
so the *resolution* of one of those links can still be a previous run's — which
no assertion here rests on, since what the fixtures test is refresh, routing,
the mount and repair, and a resolution that has gone stale fails verification
and is re-minted before any of them sees it.

### Refresh/Repair Integration Test

```bash
./integration/refresh_repair_integration.sh
```

| Scenario | Description |
|----------|-------------|
| 1. Automatic Refresh (Addition) | Adds a torrent via the RD API and waits for the refresh loop to notice — no restart, or it would be testing the cold-load path instead |
| 2. Directory Assignment & Routing | Verifies files appear in HTTP/DAV virtual directories |
| 3. Persistence (Restart) | Restarts zurg and confirms cached state survives |
| 4. Automatic Refresh (Removal) | Deletes the torrent and waits for the obsolete-key sweep to drop it |
| 5. Repair Trigger | Triggers repair via the Manage API, asserts zurg logged that it accepted the request, and waits for `ok_torrent` with 0 broken files |
| 6. Repair Verification | Repairs a second torrent and range-fetches a video file from it |

#### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `12345` | Port for the test zurg instance |
| `CONFIG_PATH` | `config.yml` | Config to borrow credentials from: the `realdebrid` provider's `token`, and top-level `username`/`password` |
| `TEST_HASH` | *(built-in)* | Torrent hash for refresh tests |
| `REPAIR_TEST_HASH` | *(built-in)* | Torrent hash with broken pieces for repair tests |
| `VERIFY_TEST_HASH` | *(built-in)* | Torrent hash for repair verification tests |
| `READY_TIMEOUT` | `120` | Seconds to wait for zurg to become ready |
| `INITIAL_SCAN_TIMEOUT` | `3600` | Seconds to wait for the first full refresh pass |
| `REFRESH_TIMEOUT` | `120` | Seconds to wait for a refresh to pick up an addition or removal |
| `REPAIR_TIMEOUT` | `300` | Seconds to wait for a repair to settle |
| `STREAM_LOGS` | `true` | Follow zurg's log on stderr |
| `ZURG_BIN` | `$(pwd)/zurg` | Path to the zurg binary — absolute, because zurg is started from the work dir |
| `WORK_DIR` | `$TMPDIR/zurg-refresh-repair` | Working directory (kept between runs) |
| `WORK_DIR_CLEANUP` | `false` | Delete the work dir on exit, discarding the caches that keep later runs short |

### Force Location Integration Test

```bash
make force-location-test
```

Not part of `make integration-test`, and run deliberately instead. Measured on
`fun` 2026-08-29, the forced `nyk` hosts resolved to AAAA records that the
download client dials over `tcp4`, so every HEAD ended `no suitable address
found`; at three retries apiece the library scan this test waits on ground on
for most of an hour before failing on the host's network rather than on zurg.
It already skips when a region is unhealthy (below), but that guard does not
cover a host that cannot reach a *healthy* region over IPv4.

Seeds a network test cache pinned to `LOCATION` (default `nyk`), then asserts
that a link resolved through zurg's `/strm/` endpoint redirects to a download
host in that location. `MAX_GEO_PROBES` (default `4`) bounds how many geo
servers the seed step probes.

With `cdn_host_preference` set, every link zurg verifies goes through the forced
region, so an unhealthy one leaves the listing empty and the failure looks like
a zurg bug. The test therefore checks the region first and skips — rather than
fails — when Real-Debrid will not mint a link for it or the host it hands back
will not serve bytes.

### Network Test Cache Integration Test

```bash
./integration/network_test_cache_integration.sh
```

Runs zurg twice: the first start must run the latency sweep and write
`data/network_test_results.json`, the second must load it and run no fresh
sweep.

### Rclone Mount Integration Test

```bash
./integration/rclone_mount_integration.sh
```

Walks the path a player actually takes — FUSE → zurg HTTP → Real-Debrid:

| Step | Assertion |
|------|-----------|
| 2 | zurg brings up its own mount and logs `Mount verification successful` |
| 3 | the configured directories are visible at the mount root |
| 4a–4c | the fixture enters the library, is served over HTTP, and reaches the mount — staged so a failure names the hop that broke rather than just "not in the mount" |
| 5 | reading the file through FUSE returns real bytes |
| 6 | shutting zurg down releases the mount |

Step 4c is the VFS dircache assertion: the fixture only reaches the mount if the
directory listing was invalidated instead of served from a listing cached before
the torrent landed.

The library is narrowed by a regex built from the fixture's own name, so the
mount holds one release rather than the whole account. `MOUNT_PATH` defaults to
`$WORK_DIR/mnt` — never the production `/mnt/zurg`. `RCLONE_BIN` defaults to
`$(pwd)/bin/rclone`.

### Plex Integration Test

```bash
./integration/plex_integration.sh
```

| Step | Assertion |
|------|-----------|
| 2 | zurg logs `Successfully connected to Plex server` |
| 3 | the fixture reaches the library, and if it also surfaces in the mount it must be readable (Plex reads it as its own user) |
| 4 | a throwaway section is created over `$MOUNT_PATH/movies`, starting empty |
| 5 | zurg resolves its library path to that section and queues a refresh **for the fixture's path** |
| 6 | Plex ends up with the item indexed |

The fixture showing up in the mount is a precondition here, not the assertion:
with Plex configured zurg also runs its matcher over the whole Plex library,
which competes with the refresh, so the VFS listing can lag a long way behind.
The test says so and carries on after `MOUNT_VISIBLE_TIMEOUT` (default `420`) —
steps 5 and 6 already fail if Plex cannot see the file, and asserting that
invalidation works is the mount test's job. `PLEX_URL` and `PLEX_TOKEN` override
the config's `plex_server_url`/`plex_token`.

The section is created with `agent=tv.plex.agents.none` and the `Plex Video
Files` scanner, so Plex indexes locally without consulting an online metadata
agent, and it is deleted on the way out — including on failure, from the EXIT
trap. Nothing runs on SIGKILL though, so the run also starts by sweeping any
`zurg-itest-` section an earlier killed run left behind. Existing libraries are
never touched.

Step 5 asks zurg to run the side effects via `POST /manage/{hash}/scan` rather
than waiting for a refresh pass. The directory-assignment trigger fires once, as
a torrent is discovered, which is necessarily before the section exists; waiting
for the next full pass costs tens of minutes on a few-thousand-torrent account.
The mapping under test is unchanged — zurg still has to resolve its own library
path to the right section by itself.

### Usenet Benchmark Regression

```bash
./integration/nzb_bench_integration.sh
make nzb-bench-test
```

Nothing else in the suite reads a byte over NNTP. A change to the article
fetcher, the yEnc decoder, the PAR2 repair or the archive reader could halve
throughput, double memory, or start serving silence where an article is gone,
and every other test would still pass. This one reads four staged releases
through a scratch zurg and asserts both the numbers and the bytes.

**Why it is an A/B and not a stored number.** Throughput on a live news server
drifts 10–20% across an evening — six reads of the same release spanned
34–50 MB/s in one sitting — so a tight band against a figure recorded last week
would fail on weather rather than on code. The test therefore measures two
binaries in the same window on the same host, alternating the order rep by rep
so provider-side warming lands on both, and compares their medians.

A is the baseline: by default the newest `*-nightly` tag reachable from `HEAD`,
extracted with `git archive` and built once, then cached under the work dir so
later runs reuse it. B is the candidate, the `zurg` this repo just built. **A
metric fails when B is worse than A by more than 5%** (`BENCH_TOLERANCE`);
better is reported as an improvement, and a metric missing on one side is `n/a`
rather than a regression. Per rep it times a cold open, time to first byte, a
64 MiB read and the same 64 MiB re-read warm, an eight-point scrub, a 256 MiB
read with CPU-seconds per gigabyte and peak RSS beside it (Linux only — both
come from `/proc`), and `ffprobe`'s reading of the container duration.

Correctness is asserted on the candidate alone, and never by a clock: every read
records an md5 that must match a recorded constant and must agree between the
two binaries, the damaged release must serve the original bytes or silence and
nothing else, and the repair must then reach the original and still be correct
after a restart.

The corpus is checked in under `integration/nzbbench/corpus/`, six NZBs for
six questions:

| NZB | What it is | What it is for |
|-----|------------|----------------|
| `ToyStory5.nzb` | a 6.61 GB WEB-DL, 1,576 × 4 MiB articles | every throughput and latency number, and the ffprobe assertion |
| `ToyStory5Damaged.nzb` | the same release with article 21's message-id corrupted, so any server answers `430` | the hole must read as the original bytes or as silence — anything else is a correctness bug — then PAR2 must repair it, and the repair must survive a restart |
| `Obfuscated.nzb` | the same film posted as seven files under `<hex> [n/7] yEnc`, its real name recoverable only from the PAR2 index | the naming passes: it must list under the real `.mkv` name at the right size, with no `.par2` visible |
| `FatherBrown.nzb` | an 11-volume RAR holding one episode, a `Sample/` directory and an nfo | the archive reader: the folder structure must survive, and reads inside the archive have their own throughput number (`rar_read_MBps`, one read per rep) |
| `WrongTurn3.nzb.gz` | a 59 GB stored 7z in 61 volumes of 1 GiB, a full UHD BluRay tree; gzipped because the NZB is 7 MB plain | the split-7z reader: the volumes must be joined and the header at the end of the last one read before anything lists, then the 57.6 GB feature stream has its own throughput number (`sevenzip_read_MBps`) |
| `NestedRar.nzb` | a two-CD XviD repost: one outer RAR5 volume set whose members are the volumes of two further RAR sets, in `CD1/` and `CD2/`, plus a `Sample/` clip and an nfo | the nested-archive reader: both inner sets must be opened — the flat test refuses two comparable sets, and the poster's directories are what group them — with both films listed at their true sizes and their own throughput number (`nested_read_MBps`, one read per rep) |

**One account, one instance.** A second zurg on a news account competes with the
first for its connection allowance, and the server refuses the *older* one — on
`fun` the production `zurg-usenet` holds all 50 of the Eweka plan's connections,
so the benchmark runs at 10 (`BENCH_NNTP_CONNECTIONS`) and a
`Too many connections` refusal is reported as a **skip, not a failure**. The
same goes for an unreachable server or a rejected `AUTHINFO`: the environment
could not answer the question, so the test says so instead of blaming the build.

Roughly 15–20 minutes at the default four reps, plus a one-off few minutes the
first time the baseline has to be built.

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `12358` | Port for the benchmark's zurg instances (one at a time) |
| `WORK_DIR` | `$TMPDIR/zurg-nzb-bench` | Holds the generated config, both binaries' run dirs and logs, `report.json`, and the cached baseline binary. Kept between runs — the persisted `data/` is what makes later reps measure a restart rather than a cold learn |
| `BENCH_ENV_FILE` | `~/.config/zurg/bench-account.env` | Account file, sourced when it exists. `KEY=value` lines for the `BENCH_NNTP_*` variables. **The supported way to give the benchmark an account of its own**, and what keeps credentials out of the repo and out of shell history |
| `CONFIG_PATH` | `config.yml` | Config to borrow the news account from, when neither the environment nor the account file names one: the first `type: nzb` provider's `nntp:` block. Borrowing is refused when that account already has connections open here — see below |
| `BENCH_NNTP_HOST` / `_PORT` / `_TLS` / `_USER` / `_PASS` | *(from `BENCH_ENV_FILE`, then `CONFIG_PATH`)* | The news account. An exported value beats the account file. Nothing found anywhere → skip |
| `BENCH_NNTP_CONNECTIONS` | `10` | Connections the benchmark opens. A cap: an account configured for fewer keeps its own number |
| `BENCH_ALLOW_SHARED_ACCOUNT` | *(unset)* | Set to `1` to benchmark on a borrowed account that already has connections open. Only when you have confirmed the account has the room |
| `BASELINE_REF` | newest `*-nightly` reachable from `HEAD` | What to compare against. Resolved after a best-effort `git fetch --tags` |
| `BASELINE_BIN` | *(built from `BASELINE_REF`)* | A prebuilt baseline, used as-is. The way to compare against something that no longer builds here |
| `BENCH_REPS` | `4` | Reps per binary. Medians are taken over these |
| `BENCH_TOLERANCE` | `0.05` | How much worse B may be before it is a regression |
| `BENCH_SKIP` | *(none)* | Comma list of phases to leave out: `repair`, `obfuscated`, `rar`, `ffprobe`. `ffprobe` is added automatically when there is none on `PATH` and none in `bin/` |
| `REPORT_JSON` | `$WORK_DIR/report.json` | Where the report lands |
| `STREAM_LOGS` | `true` | Follow the candidate's `zurg.log` on stderr. The tool's own progress is printed either way |

`report.json` holds every per-rep row for both binaries, the medians, the
per-metric verdicts, both binaries' `version` output, and the host and OS — so a
number in it can be read against the code that produced it. To record a set of
numbers without comparing anything, call the tool directly with a single
`--bin`; it measures, writes the JSON and exits 0:

```bash
cd integration/nzbbench && go build -o /tmp/nzbbench . && cd -
/tmp/nzbbench --config /path/to/a-config-with-an-nzb-provider.yml --port 12358 \
  --corpus integration/nzbbench/corpus --work /tmp/nzbbench-record \
  --bin candidate=./zurg --out /tmp/record.json
```

The config has to be your own: the one the wrapper generates carries the news
account's password in cleartext and is deleted when the run ends.

`integration/nzbbench/README.md` documents the tool's own flags and exit codes.

### Prerequisites

- Real-Debrid token in `config.yml` (as a `realdebrid` provider) or `RD_TOKEN`
- `curl`, `python3`, and a built zurg binary
- `shellcheck` for `make lint-integration` (skipped with a notice if absent)
- For the mount and Plex tests: `fusermount`/macFUSE, an rclone binary, and
  `user_allow_other` in `/etc/fuse.conf` so Plex can read the mount
- For the Usenet benchmark: a news account, plus Go, `git`, `tar` and `make` —
  it builds its baseline from a `git archive` of a nightly tag

### Give the benchmark its own news account

A connection allowance belongs to the **account**, not to a process. Point the
benchmark at the account a production instance is already on and the two go
over the plan together, at which point the server refuses the *older* connection
holder — production, which knows nothing about the benchmark that caused it.

So the benchmark borrows from `CONFIG_PATH` only as a fallback, and **refuses to
borrow an account that already has connections open on this host**. Give it one
of its own in `~/.config/zurg/bench-account.env`:

```
BENCH_NNTP_HOST=news.example.net
BENCH_NNTP_PORT=563
BENCH_NNTP_TLS=true
BENCH_NNTP_USER=...
BENCH_NNTP_PASS=...
BENCH_NNTP_CONNECTIONS=25
```

Pick an account with slack nothing depends on — a server whose measured ceiling
is far above what any instance is configured for, so a benchmark cannot starve a
reader. Anything exported at the command line still wins over the file, and
`BENCH_ALLOW_SHARED_ACCOUNT=1` overrides the refusal if you have confirmed the
room exists.

### Not in the suite

`rename_integration.sh`, `tag_stats_integration.sh` and
`test_repair_verification.sh` are not run by `make integration-test`. They still
carry their own copies of the pre-`lib.sh` helpers. Port them onto `lib.sh` and
give them non-colliding ports before wiring them in.
