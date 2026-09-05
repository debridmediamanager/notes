---
label: Torrent lifecycle
icon: stopwatch
order: 77
---

# Torrent lifecycle on Real-Debrid AllDebrid and TorBox

Measured on 2026-08-30 against live accounts. Everything below marked **observed** came out of a
capture. Everything marked **inferred** did not and says why.

zurg needs this because the qBittorrent shim has to tell Sonarr and Radarr what stage a download is
in. Today it cannot. `TorrentInfo.Status` carries Real-Debrid's status vocabulary and the AllDebrid
and TorBox packages translate into it before zurg's own code ever sees a torrent. TorBox
`stalled (no seeds)` arrives as `queued`. Nothing carries seeders or speed or eta at all. So the
stage table had to be built from the wire and not from the provider packages that already normalise
it away.

The harness is `scripts/torrent_lifecycle_probe.py`. It hits
the raw REST APIs so the captures are wire status. It deletes everything it adds on the way out
including on Ctrl-C.

---

## How this was measured

### The accounts

| Provider | Account | Why this one |
|---|---|---|
| Real-Debrid | test 2 | not the main account and not `bendav`, which zen's production zurg uses |
| AllDebrid | test key | resolves to the `ymsita` account, which already held 39 magnets, so only ids the run created were ever deleted |
| TorBox | main | the only TorBox account there is. **Shared with fun's `zurg-tb`**, which is not a footnote. See [Hazards](#hazards-found-on-the-way) |

Credentials come from `RD_TOKEN` `AD_KEY` `TB_KEY` in the environment. Nothing writes them to a
capture.

### The torrents

All legitimate. FOSS images and public domain film. Every info hash that came from a `.torrent` was
recomputed from the file by the harness rather than typed in. Swarm sizes are tracker scrapes taken
the same day.

| Case | Torrent | Info hash | Size | Tracker seeders | Webseeds |
|---|---|---|---|---|---|
| cached | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | n/a | n/a |
| cached | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | n/a | n/a |
| cached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 to 27 | none |
| uncached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| uncached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 seeders and 0 leechers | 3 |
| seedless | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | none |
| seedless | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | none |
| nometa | random 40-hex | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | none | none | none |

The zeros are real and not a dead tracker. `torrent.ubuntu.com` was scraped twice for all three
Ubuntu entries in the same loop and answered 22 then 27 seeders for 26.04.1 while answering an empty
`d5:filesdee` for the two seedless ones. Same for `bt1.archive.org` and the Prelinger item.

TorBox `checkcached` was asked about every hash before anything was added. It is the only
non-destructive cache probe of the three. It said cached for the three cached rows and uncached for
the other six. That is the split the case names claim.

### Poll cadence and caps

3 s for the first 2 minutes then 15 s. 1 s for the cached case because the whole lifecycle there can
be over inside one normal poll. Cap 15 minutes per torrent for the campaign rather than the script
default of 30. The shim's proposed default timeout is 10 minutes and a torrent still moving at 15 is
already past the only window that matters. Real-Debrid adds are spaced at least 20 s apart.

Each provider ran as its own process against its own output directory. That keeps the Real-Debrid
add spacing honest inside one process and lets the three run at once.

---

## Real-Debrid

### Endpoints

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### Status values observed

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

Not observed here. `compressing` `virus` `error` `dead`. Those need content this campaign had no
legitimate way to produce.

### Which wire fields exist in which status

This matters more than the vocabulary. Fields come and go. A mapper that reads `speed` in every
state reads a missing key half the time.

| Field | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | yes | yes | yes | yes | yes |
| `progress` | 0 | 0 | **float percent** 0 to 100 | **restarts at 0** and climbs to 100 | 100 |
| `seeders` | yes | **absent** | yes | **absent** | **absent** |
| `speed` | **absent** | **absent** | yes, bytes per second | yes, always 0 in the capture | **absent** |
| `bytes` / `original_bytes` | 0 | real size | real size | real size | real size |
| `filename` | `"Magnet"` | real name | real name | real name | real name |
| `files` | `[]` | populated | populated | populated | populated |
| `links` | `[]` | `[]` | `[]` | fills during the phase | populated |
| `ended` | absent | absent | absent | absent | present |

`progress` is a **float** and not an integer. The capture holds 0.4 and 0.8 and 1.4 alongside 100.
A stall detector that rounds to an integer percent will call a 100 GB release stalled at 1 MB/s.

`progress` **goes backwards on purpose**. It resets to 0 when the status turns `uploading` and climbs
to 100 again. Movement has to be defined as a stage change or a progress increase and never as a
monotonic percentage.

`seeders` disappears rather than going to zero once the torrent leaves `downloading`. So does
`speed`. A mapper must treat an absent key as unknown and not as zero.

### What each case did

| Case | Torrent | Transitions with seconds from add | Verdict |
|---|---|---|---|
| cached | Big Buck Bunny | `downloaded`@0.0 | done in 1.32 s end to end |
| cached | Sintel | `downloaded`@0.0 | done in 0.73 s |
| cached | Ubuntu 26.04.1 | `downloaded`@0.0 | done in 0.32 s |
| uncached | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | already cached on this account |
| uncached | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | done. 3.71 GiB in 197 s |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | failed |
| seedless | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | done. The case did not reproduce |
| seedless | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 and nothing after that | **capped at 907.6 s still `downloading`**. This is the stall shape |
| nometa | random 40-hex | `magnet_conversion`@0.0 `magnet_error`@317.9 | failed |

### The cached add latency

This is the number the shim's cached-only mode is built on.

| Torrent | addMagnet returns | selectFiles returns | first `/torrents/info` | status |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**Observed.** A cached torrent is `downloaded` at the very first read after `selectFiles`. The whole
synchronous cost is two round trips. It never passes `queued` and it never passes `downloading`.

A second run polled `/torrents/info` at 0.25 s in the gap between `addMagnet` and `selectFiles` as
well as after it. That is what `--rd-select-detail` does and it settles the shape.

| Torrent | Status before `selectFiles` | `selectFiles` | First read after it | addMagnet to `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection` with 3 files listed and `links` empty | 204 at t+1.314 s | `downloaded` `progress` 100 `links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection` with 11 files listed | 204 at t+0.627 s | `downloaded` `progress` 100 `links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection` with 1 file listed | 204 at t+0.219 s | `downloaded` `progress` 100 `links` 1 | **0.430 s** |

So the full cached sequence is `waiting_files_selection` then `downloaded` and nothing in between.
The file list is already there before `selectFiles`. `links` is what `selectFiles` fills.

**The cached-only probe window can be one poll.** 0.43 s to 1.54 s end to end across three torrents
of 123 MiB and 264 MiB and 6.04 GiB. A window of two seconds at a quarter-second poll is generous.

Against the 100 s that Sonarr and Radarr allow a `torrents/add` call
(see [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md)) a cached-only probe
window of a couple of seconds is free. There is no reason to set it in the tens of seconds.

### Quirks a stage mapper has to survive

- **`selectFiles` answers 404 while the torrent is still in `magnet_conversion` and the error lies.**
  The body is `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}` even
  though `files=all` was sent. There are simply no files to select yet. It is not a failure of the
  add and the torrent stays alive. Both runs that hit it lived another 318 s.
- **A private tracker's hash can be condemned at once rather than after 318 s.** The hash behind the qBittorrent report of
  2026-08-31 (a CiNEPHiLES remux from a UNIT3D indexer, `45e1ec0d…`) answered `magnet_error` with zero files on the
  first read after addMagnet — no `magnet_conversion` window at all, seconds after the add. Whether Real-Debrid
  recognised the hash or failed fast on it, the observable is the same: a private hash has no DHT swarm, so addMagnet
  can never succeed for one, and selectFiles on the dead instance answers the lying 404 above.
- **`addTorrent` skips nothing for uncached content but everything for cached.** A `.torrent` uploaded for content
  Real-Debrid does not hold (an archive.org Big Buck Bunny, seeded but not cached) went to `magnet_conversion` like a
  bare magnet — the file's metadata is not used to resolve. A cached one (an Ubuntu ISO) answered
  `waiting_files_selection` with its file list at the first read, selected, and finished `downloaded` inside two
  seconds, never passing `magnet_conversion` at all. So the upload's value is the immediate hash→cache lookup — which
  is what makes a private tracker's release addable whenever the content is cached, and never addable as a magnet.
- **Metadata resolution gives up after 318 s.** Two independent runs went `magnet_conversion` to
  `magnet_error` at 317.9 s and 318.0 s. That is the wall a magnet with no reachable peers hits. It
  is the same whether or not a torrent exists for the hash.
- **`seeders` lies during `magnet_conversion`.** The random 40-hex hash reported `seeders: 1` at
  80.9 s. No torrent exists for it.
- **`ended` on a freshly added cached torrent carries an old date.** The captures hold
  `2025-12-28` and `2026-07-28` for torrents added on 2026-08-30. It is when Real-Debrid first had
  the content and not when this instance finished. Do not compute an age from it.
- **A zero-peer magnet dies in metadata resolution and never reaches the webseed.** Real-Debrid does
  honour webseeds once it has the torrent. It cannot get the torrent from a magnet with no peers. So
  a webseed-only item added as a magnet ends `magnet_error`. That is a metadata failure rather than a
  webseed failure and the two look identical from `/torrents/info`.

---

## AllDebrid

### Endpoints

`v4` and `v4.1` are not interchangeable and the difference bit this campaign.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**The file upload answers under `files`, not `magnets`.** Same fields per entry — `id`, `hash`,
`name`, `ready`, an optional per-entry `error` — so the `ready` flag below is the cache answer either
way, but a decoder written for the magnet response reads an empty list.

**And the file is the only form of a release AllDebrid can describe without a swarm.** Measured
2026-09-01 on the test account, two same-shaped synthetic private torrents whose hashes no swarm has
ever seen. Uploaded as files they came back with their real names and their real sizes
(`"name":"zurg.private.ad.probe","size":65536`), listing as `In queue` with the clock not yet
running. Sent as a bare `magnets[]` hash the answer was `"name":"noname","size":0` — AllDebrid
accepted it and knew nothing about it, which is every private tracker's release added by hash.

**`/v4/magnet/status` is gone.** With an id or without one it answers HTTP 200 carrying
`{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. `/v4/magnet/upload` and
`/v4/magnet/delete` still work. So the plan's assumption that the v4 status endpoint could be used
and v4.1 sampled once for comparison is backwards. v4.1 is the only status endpoint and the harness
records one v4 read per torrent so the capture carries the proof rather than the claim.

Auth is `Authorization: Bearer <apikey>`. No `agent` parameter is needed.

### Status values observed

| `statusCode` | `status` | Seen |
|---|---|---|
| 0 | `In queue` | yes |
| 1 | `Downloading` | yes |
| 2 | `Compressing / Moving` | **no** |
| 3 | `Uploading` | yes |
| 4 | `Ready` | yes |
| 5 and above | the error codes | **no** |

### Which wire fields exist in which status

| Field | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | yes | yes | yes | yes |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"` until metadata lands | real name once metadata lands | real name | real name |
| `size` | 0 until metadata lands | real size | real size | real size |
| `downloaded` | 0 | **the progress figure, in bytes** | equals `size` | **absent** |
| `downloadSpeed` | 0 | yes, bytes per second | 0 | **absent** |
| `seeders` | 0 | yes | 0 | **absent** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **the progress figure for this phase** | **absent** |
| `processingPerc` | 0 | 0 | 0 | **absent** |
| `files` / `nbLinks` | absent | absent | absent | present |
| `completionDate` | 0 | 0 | 0 | set |

**There is no percentage anywhere.** Progress on AllDebrid is `downloaded / size` and both are
integers in bytes. `processingPerc` stayed 0 in every state in every capture.

`Uploading` is AllDebrid moving the finished download into its own storage. It has its own progress
counter in `uploaded` and `uploadSpeed` and its `downloadSpeed` is 0 throughout. A stall rule that
only watches `downloaded` will call a healthy `Uploading` phase stalled.

### What each case did

| Case | Torrent | `ready` on upload | Transitions with seconds from add | Verdict |
|---|---|---|---|---|
| cached | Big Buck Bunny | true | `Ready`@0.0 | done in 0.11 s |
| cached | Sintel | true | `Ready`@0.0 | done in 0.12 s |
| cached | Ubuntu 26.04.1 | true | `Ready`@0.0 | done in 0.11 s |
| uncached | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | already cached |
| uncached | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 with every counter at zero until 634.9 `Uploading`@650.1 `Ready`@876.9 | done in 877 s |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 and every counter at zero after that | **capped at 907.8 s still `Downloading`** |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 with every counter at zero until 589.6 `Uploading`@619.9 `Ready`@650.2 | done in 650 s |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 and every counter at zero after that | **capped at 907.0 s still `Downloading`** |
| nometa | random 40-hex | false | `In queue`@0.0 `Downloading`@9.4 and every counter at zero after that | **capped at 907.4 s still `Downloading`** |

A separate run against Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) caught
a complete uncached lifecycle and is the reference sequence.

| Seconds | State | What moved |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` is `"noname"` and `size` is 0 |
| 2.2 | `Downloading` 1 version 2 | still no name and no size |
| 4.3 | `Downloading` | `filename` and `size` resolve |
| 6.5 to 55.1 | `Downloading` | `downloaded` climbs to `size`. `downloadSpeed` peaks near 110 MB/s. `seeders` 8 to 9 |
| 57.2 | `Uploading` 3 | `downloadSpeed` drops to 0. `uploadSpeed` and `uploaded` start climbing |
| 65.6 | `Ready` 4 | `files` and `nbLinks` appear. Six progress fields disappear |

3.72 GiB in 65.6 s.

### AllDebrid reports no progress at all while a job waits for its own infrastructure

This is the finding that most changes the timeout design and it took two independent runs to trust.

`Downloading` with `statusCode` 1 arrives within seconds of the upload. For a while after that
AllDebrid reports `downloaded` 0 and `downloadSpeed` 0 and `seeders` 0 and `uploaded` 0 and
`uploadSpeed` 0 and `processingPerc` 0. It also sets `size` back to 0 and `filename` back to the info
hash even when it had already reported both correctly.

| Run | How long every counter stayed at zero | What happened next |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 s** from 12.5 s to 634.9 s | 3.71 GiB downloaded in 15 s then `Uploading` then `Ready` at 876.9 s |
| ubuntu-16.04.6-desktop-i386 | **580 s** from 9.4 s to 589.6 s | 1.56 GiB downloaded in 30 s then `Uploading` then `Ready` at 650.2 s |

Both finished. Neither reported a single byte of movement for the first ten minutes.

**A ten minute no-movement timeout would abandon healthy AllDebrid jobs.** The proposed
`download_timeout_mins` default of 10 lands inside this window twice out of two. Either the timeout
has to be longer than this or AllDebrid `Downloading` with `size` 0 has to count as its own stage
that the clock does not run against. Losing the name and the size is how AllDebrid says the job is
assigned but not started and it is not a failure.

A run that did start straight away is the contrast. Debian 13.3.0 arm64 DVD-1 went from `In queue` to
real byte counters in 6.5 s. So the wait is a queue and not a fixed delay.

### The `ready` flag is a real cache answer

`ready` on the `/v4/magnet/upload` response was true for every hash TorBox also called cached and
false for the two the campaign downloaded. AllDebrid has no separate cache probe so this flag is the
whole cache signal, and zurg now carries it out of both add paths — the magnet's and the file
upload's — as `MagnetResponse.Cached` with `CacheKnown` set, so a backend that cannot answer is never
mistaken for one reporting a miss.

**A false `ready` means the magnet is already added.** There is no way to ask AllDebrid whether a
hash is cached without adding it. A cached-only path on AllDebrid has to delete the miss.

---

## TorBox

### Endpoints

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### Status values observed

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing` and `checking` and `stalledDL` are **not in zurg's translation table**
(`internal/torbox/types.go` `normalizeStatus`). All three fall to the default branch and are reported
as `downloading`.

`checking` is where TorBox waits for metadata and not where it verifies a hash. A magnet whose swarm
never answers goes `metaDL` then `checking` and stays there. The random 40-hex hash was still
`checking` at the 910 s cap and so was the zero-peer Prelinger item at 911 s. TorBox never gives up
the way Real-Debrid does at 318 s.

**Uploading the `.torrent` skips that wait entirely, and it is the whole difference for a private
tracker's release.** Measured 2026-09-01 on the account above, the same synthetic private torrent
sent both ways. As a hash: accepted with a `torrent_id`, then `checking` with `name` set to the bare
hash, `size: -1`, `files: null` and `eta: 8640000` — TorBox looking for a swarm that is not in the
DHT, which it will do until the cap and report nothing about. As the file, on
`POST /torrents/createtorrent` with the bytes in a multipart `file` part: read back three seconds
later carrying the torrent's own name, its real size and `stalled (no seeds)` — the same content
nobody holds, but now described. The stage is the point. `checking` with `size: -1` maps to
`StageResolvingMetadata`, which says work is in progress and nothing can be concluded; `stalled (no
seeds)` maps to `StageStalledNoPeers`, which the qBittorrent endpoint can act on. A cached release
read back `done` at 100% with its file list inside the same three seconds. The part name is
load-bearing: a file sent under any other name is not seen at all, and the endpoint answers
`MISSING_REQUIRED_OPTION`, "You must provide either a file or magnet link".

### Which wire fields exist in which status

TorBox sends the same key set in every state and changes the values. That makes it the easiest of
the three to read. The values are what carry the meaning.

| State | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | tiny | 8640000 | real |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | real |
| `downloading` | false then **true** | false | false | true | fraction | seconds | real |
| `processing` | **true** | **false** | false | true | 1 | seconds | real |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | real |
| `uploading` | true | **true** | true | true | 1 | 0 | real |
| `cached` | true | true | true | false | 1 | 0 | real |

Field names. The plan listed all of these as unverified.

| What | TorBox field | Shape |
|---|---|---|
| progress | `progress` | **fraction of one**, not a percentage. `0.0793719` |
| seeders | `seeds` | integer |
| leechers | `peers` | integer |
| download rate | `download_speed` | bytes per second |
| upload rate | `upload_speed` | bytes per second |
| eta | `eta` | seconds. `8640000` is the not-known placeholder |
| bytes fetched | `total_downloaded` | integer |
| swarm health | `availability` | float. Goes to **-1** in `uploading (no peers)` |
| where the data is | `download_path` | null until the data is present |

`8640000` is 100 days. It is TorBox's way of saying it does not know. It is also the same constant
zurg's shim hands Sonarr today when it has nothing to report.

### What each case did

| Case | Torrent | `checkcached` | Transitions with seconds from add | Verdict |
|---|---|---|---|---|
| cached | Big Buck Bunny | true | `cached`@0.0 | done in 0.83 s |
| cached | Sintel | true | `cached`@0.0 | done in 0.94 s |
| cached | Ubuntu 26.04.1 | true | `cached`@0.0 | done in 0.69 s |
| uncached | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 then **gone**@48.6 | deleted by fun's zurg-tb at 86.7% |
| uncached | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 then **gone**@86.7 | deleted by fun's zurg-tb |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 and never anything else | **capped at 911.3 s in `checking`**. TorBox did not use the webseed |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 then **gone**@200.4 | deleted by fun's zurg-tb at `processing` |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 then **gone**@462.3 | deleted by fun's zurg-tb at 91.9 percent |
| nometa | random 40-hex | false | `metaDL`@0.0 `checking`@10.2 and never anything else | **capped at 910.3 s in `checking`** |

A separate run at a 0.5 s poll against Debian 13.5.0 amd64 netinst
(`58846860f0a766f8a42b0bb214d8c713fdf1b167`) survived long enough to reach done and is the reference
sequence.

| Seconds | State | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB in 64.4 s.

Read the last three rows twice. TorBox sets `download_finished` to true and `progress` to 1 roughly
ten seconds **before** the data is present. Then it drops back to `downloading` with a progress
figure lower than the one it just reported. Both `progress` and `download_state` go backwards on a
healthy download.

---

## The stage table

The stage enum the shim will speak is `resolving-metadata` `queued` `downloading` `stalled-no-peers`
`finalizing` `done` `failed` and the empty string for unknown.

### Real-Debrid

| Raw `status` | Stage | Basis |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **observed**. `bytes` 0 and `files` empty and `filename` is the literal `"Magnet"` |
| `waiting_files_selection` | `queued` | **observed** with `--rd-select-detail`. Files are already listed. `links` is empty |
| `queued` | `queued` | **observed**. Real size and real name are already known. No `seeders` and no `speed` |
| `downloading` | `downloading` | **observed** |
| `downloading` with `seeders` 0 | `stalled-no-peers` | **observed**. 904 s of `progress` 0 and `seeders` 0 and `speed` 0 across 92 polls |
| `compressing` | `finalizing` | **inferred**. Not seen |
| `uploading` | `finalizing` | **observed**. Progress restarts from 0 and `seeders` disappears |
| `downloaded` | `done` | **observed** |
| `magnet_error` | `failed` | **observed** after 318 s in `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **inferred**. Not seen |

### AllDebrid

| `statusCode` | Stage | Basis |
|---|---|---|
| 0 `In queue` | `queued` | **observed**. Lasts a few seconds. `filename` may still be `"noname"` and `size` 0 |
| 1 `Downloading` with `size` 0 | `queued` | **observed**. Not `downloading` and not `stalled-no-peers`. AllDebrid has taken the job and not started it. Held for 622 s and 580 s in two runs that then completed |
| 1 `Downloading` with a real `size` | `downloading` | **observed** |
| 1 `Downloading` with `seeders` 0 and `downloaded` flat | `stalled-no-peers` | **not observed and not safely inferrable**. See below |
| 2 `Compressing / Moving` | `finalizing` | **inferred**. Not seen |
| 3 `Uploading` | `finalizing` | **observed**. `uploaded` and `uploadSpeed` carry the progress here and `downloadSpeed` is 0 |
| 4 `Ready` | `done` | **observed** |
| 5 and above | `failed` | **inferred**. Not seen |

**AllDebrid has no observable stall shape.** A job AllDebrid has queued and a job AllDebrid cannot
make progress on look identical on the wire. Both are `statusCode` 1 with `size` 0 and every counter
at zero. The Prelinger item sat in exactly that shape for the full 907.8 s cap and two other torrents
sat in it for ten minutes each and then finished. So nothing in the AllDebrid response distinguishes
the two and a stall verdict on AllDebrid can only ever come from a clock.

### TorBox

| Raw `download_state` | Stage | Basis |
|---|---|---|
| `metaDL` | `resolving-metadata` | **observed**. `size` 0 and `name` equal to the hash |
| `checking` | `resolving-metadata` | **observed**. `size` **-1** while it lasts. This is where TorBox waits for the torrent and not a hash check. Not in zurg's table today |
| `stalledDL` | `stalled-no-peers` | **observed**. Not in zurg's table today |
| `stalled (no seeds)` | `stalled-no-peers` | **observed**. The name overstates it. Two captures carried `seeds` 1 and 2 while in this state. zurg maps it to `queued` today |
| `downloading` | `downloading` | **observed** |
| `processing` | `finalizing` | **observed**. Not in zurg's table today |
| `uploading (no peers)` | `finalizing` | **observed** when `download_present` is false |
| `uploading` | `done` | **observed** when `download_present` is true |
| `cached` `completed` `seeding` | `done` | `cached` **observed**. The other two **inferred** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **inferred**. None seen |

**The `download_finished` and `download_present` pair is not a substitute for the state string.** Both
`processing` and `uploading (no peers)` and part of `downloading` carry `download_finished: true` with
`download_present: false`. That combination is a normal finalizing phase and not a dead torrent. See
the hazard below.

---

## What could not be measured

- **The seedless case reproduced on one candidate out of two.** Both had zero tracker peers.
  ubuntu-16.04.6-desktop-i386 downloaded anyway on all three providers because DHT supplied peers the
  tracker did not know about. ubuntu-24.04-beta-live-server-s390x stalled on Real-Debrid for the full
  cap and is the stall observation above. A zero on a tracker scrape is a weak predictor. Keep two
  candidates in the case. Real-Debrid held the metadata for both regardless and reported `bytes` and
  `filename` correctly in the very first `queued` read.
- **Real-Debrid `compressing` was never seen.** Every completed run went `downloading` straight to
  `uploading`.
- **AllDebrid status code 2 was never seen.** Every capture went from 1 straight to 3.
- **No provider was pushed into its own error vocabulary.** Real-Debrid `error` and `virus` and
  `dead` and every AllDebrid code above 4 and every TorBox failure state are all unmeasured.
  Producing them needs content that is blocked or infected or expired rather than a FOSS ISO.
- **TorBox could rarely be watched to completion.** Four campaign torrents and one follow-up were
  deleted mid-download by fun's `zurg-tb`. See the hazard below. Only a 754 MiB image finished before
  that process next polled.

---

## Hazards found on the way

### fun's zurg-tb deletes healthy TorBox downloads

The TorBox account is shared with `zurg-tb` on fun. Its config reads

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

**Five** probe torrents were deleted while they were downloading normally. This is **observed** on
both sides. The harness saw each torrent vanish and fun's journal says why.

```
Aug 30 12:43:26 fun zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 fun zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 fun zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 fun zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

The five are `86695315` `86695708` `86697191` `86702627` `86704212`. Every one of them carried the
same reason. None of them was broken.

The mechanism is the second rule in `normalizeStatus` at `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

That combination is a normal TorBox finalizing phase. The 0.5 s capture puts a number on it. On a
754 MiB image the window from `download_finished` turning true to `download_present` turning true was
**9.6 seconds**. On a 3.7 GiB image it was at least 17 s and the sweep landed inside it. fun's
`zurg-tb` polls the library roughly every 15 s. Whether a healthy TorBox download survives its own
completion is close to a coin toss.

Three consequences. A TorBox download that a user watches finish in the TorBox UI can be gone from
their zurg library. `delete_error_torrents` is documented as deleting torrents the provider says are
broken and here it deletes ones the provider says are fine. And any measurement of TorBox on this
account is racing that sweep.

**Not fixed here.** Phase 0 measures. The fix belongs with the stage work. There
`download_finished && !download_present` becomes `finalizing` rather than `failed`.

### The AllDebrid account is shared with fun too and got away with it

fun's `zurg-ad` carries the **same AllDebrid key** as the one this campaign used. The md5 of the
`token:` line in `~/zurg-ad/config.yml` on fun matches the md5 of the key in the environment here.
Its sweep settings are the same three as `zurg-tb`.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

No AllDebrid probe was deleted. The reason is in the code and not in luck. `normalizeStatus` in
`internal/alldebrid/types.go` maps only status codes at or above 5 to `error` and has no structural
rule of the `download_finished && !download_present` kind. So a healthy AllDebrid download can never
read as broken. The TorBox bug is that one extra rule and not sweeping in general.

Real-Debrid is the odd one out. Test 2 is not the account behind fun's `zurg` and not the `bendav`
account behind zen's. Nothing was sweeping it and nothing interfered.

### TorBox answers a delete for an unknown id with HTTP 500

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` answers the same way. So a torrent that no longer exists is
indistinguishable from a TorBox outage by status code alone. zurg reports it as
`account temporarily unavailable`. fun's journal shows it retrying the delete of an already deleted
id every 15 s. The harness works around it by asking `mylist` after a failed delete and treating a
gone torrent as deleted.

### Real-Debrid throttling did not appear

Nine adds at 20 s spacing produced zero 451s and zero 429s across the whole campaign. That matches
the note in the root `CLAUDE.md` that 6 adds 10 s apart went 0/6 and the same 6 at 20 s went 6/6.
The 20 s floor is doing real work and is not superstition.

---

## Re-running the campaign

```bash
export RD_TOKEN=…   # Real-Debrid test 2
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Run it from a machine with residential egress. AllDebrid answers `NO_SERVER` to datacenter IPs.

Step 6 is not optional and step 3 is what makes it meaningful. After the 2026-08-30 campaign the
three accounts held 500 and 39 and 469 items and not one of the 34 instance ids the harness had
claimed was among them. Neither was any of the nine probe hashes.

Before touching TorBox read fun's `zurg-tb` config and expect the sweep described above.

```bash
ssh ben@fun 'grep -E "delete_error_torrents|stalled_download_mins|enable_repair" ~/zurg-tb/config.yml'
```

Never change it. A probe that disappears mid-run is data.
