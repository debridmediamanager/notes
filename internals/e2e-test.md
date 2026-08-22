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

**Run it on `fun`.** It is the only host with all of Go, rclone, FUSE and Plex,
so it is the only place all five tests actually execute. Elsewhere the ones that
cannot run skip — loudly, but they still exit 0, so read the output rather than
the exit code. `zen` has Plex but no Go toolchain and no zurg mount, so it
cannot run the suite at all.

| Test | Needs FUSE | Needs Plex |
|------|:----------:|:----------:|
| `refresh_repair_integration.sh` | | |
| `force_location_integration.sh` | | |
| `network_test_cache_integration.sh` | | |
| `rclone_mount_integration.sh` | yes | |
| `plex_integration.sh` | yes | yes |

The mount test runs on a Mac too when macFUSE is installed — it is verified on
both macFUSE and Linux `fusermount`. The Plex test needs `plex_server_url` and
`plex_token` in the config it reads, which a laptop's `config.yml` normally
lacks, so that one is `fun`-only in practice.

`make integration-test` builds zurg, runs shellcheck over the scripts and the
`lib.sh` self-test, then runs all five against a real Real-Debrid account,
cheapest first: network test cache, force location, rclone mount, Plex, and
refresh/repair last — that one waits out a full library scan, so a mistake in
any of the others should not cost that wait to discover.
`make integration-test-media` runs just the mount and Plex pair.

Each script owns a work dir under `$TMPDIR`, its own port, and writes zurg's log
there; the suite runs with `STREAM_LOGS=false`, so only the test's own
assertions reach the terminal. Set `STREAM_LOGS=true` to follow zurg's log on
stderr while debugging.

Shared helpers live in `integration/lib.sh` (process control, the Real-Debrid
API, on-disk library queries) and `integration/lib_media.sh` (FUSE and Plex).
Add a test by sourcing them, not by copying another script.
`integration/lib_test.sh` covers the helpers themselves: no account, no network,
about a second.

### Runtime

The first run against a given work dir pays for a cold library scan: one info
call and one link verification per torrent, paced by the account's API budget.
On a few-thousand-torrent account that is tens of minutes. The work dir keeps
`info/` and the network test cache between runs, so later runs skip it. Delete
the work dir to force the cold path.

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
./integration/force_location_integration.sh
```

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

### Prerequisites

- Real-Debrid token in `config.yml` (as a `realdebrid` provider) or `RD_TOKEN`
- `curl`, `python3`, and a built zurg binary
- `shellcheck` for `make lint-integration` (skipped with a notice if absent)
- For the mount and Plex tests: `fusermount`/macFUSE, an rclone binary, and
  `user_allow_other` in `/etc/fuse.conf` so Plex can read the mount

### Not in the suite

`rename_integration.sh`, `tag_stats_integration.sh` and
`test_repair_verification.sh` are not run by `make integration-test`. They still
carry their own copies of the pre-`lib.sh` helpers. Port them onto `lib.sh` and
give them non-colliding ports before wiring them in.
