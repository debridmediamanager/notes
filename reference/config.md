# zurg Configuration Documentation

This document details all available configuration options for zurg. Configure these options in your `config.yml` file.

> **Tip:** Most settings can be configured via the **Dashboard** at `http://localhost:9999/config/`. The web interface provides an easier way to view and modify settings without editing the config file directly.

## Migrating from a pre-`providers` config

If your config was written before the multi-account support landed, it still starts: the top-level `token:`, `download_tokens:` and `strm_link_token:` keys are read as the one thing they could ever have described — a single Real-Debrid account — and startup warns that they are deprecated. Moving them into a `providers` entry is the only change your config file needs, whenever you get to it: no other key was renamed, retyped or removed.

It is not, however, the only thing that changes. A handful of directives keep their name and their value and decide something slightly different than they used to, because the code reading them moved. Those are collected under [What else changes when you upgrade](#what-else-changes-when-you-upgrade) below — worth a read if you filter on archives, on tags, or on when a release was added.

### The one change to make

A single Real-Debrid account used to be three top-level keys. All three now live inside one `providers` entry.

Before:

```yaml
zurg: v1
token: YOUR_RD_API_TOKEN
download_tokens:
  - ANOTHER_RD_API_TOKEN
strm_link_token: RD_TOKEN_FOR_STRM
```

After:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    download_tokens:
      - ANOTHER_RD_API_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
```

Delete the old keys once they are moved. Left beside a `providers` block that already configures Real-Debrid they are ignored, and startup warns about them, so the two can never silently disagree about which token is live. Nothing else in your file needs touching — every other key kept its name and meaning, and a config whose only credential was `token:` needs only this edit.

You are not forced to make it. An unmigrated config still starts: the three keys are read as one Real-Debrid account named `realdebrid`, and startup names the keys it read and what to write instead. They are deprecated, not supported — new account features are reachable only from a `providers` entry.

The `TOKEN` / `RD_TOKEN` environment variables still work and still auto-create a config on first run.

### What became possible, that you may want

None of this is required. It is what the `providers` block bought:

| Now available | Where |
|---|---|
| TorBox, AllDebrid and Usenet backends, alongside Real-Debrid or instead of it | [Accounts](#accounts) |
| Several accounts of the same service, told apart by `name` | [Accounts](#accounts) |
| `disabled: true` to park an account without deleting its credentials | [Accounts](#accounts) |
| `watchlist: true` to choose which account new torrent adds are tried on first | [Accounts](#accounts) |
| `provider:` / `not_provider:` directory filters, and per-account directories | [Directories](#7-directories--filters) |
| `rd_cdn_host_preference` and `tb_cdn_host_preference` for per-service CDN choice | [CDN & Host Selection](#cdn--host-selection) |

Two smaller changes worth knowing about:

- `cdn_host_preference` still works and still means Real-Debrid. It is now an alias for `rd_cdn_host_preference`, which wins if both are set.
- Plex credentials from the Dashboard's auth flow are written back into `config.yml` as `plex_server_url` and `plex_token`. They used to live in `data/plex.json`.

### Migrating by hand vs. by dashboard

The Dashboard can finish it for you. An unmigrated config loads, so the providers editor is reachable, and it lists the Real-Debrid account your top-level keys were read as; saving any account moves those keys into the `providers` block on disk. Editing the file by hand and restarting does the same thing and is the only option if the config does not load at all.

One thing the Dashboard no longer accepts: `POST /config` used to take `token`, `download_tokens` and `strm_link_token` as top-level keys, and now answers `400 Unknown config option`. Credentials are edited per account instead. Anything scripting those three needs updating.

### What else changes when you upgrade

Every directive below keeps its name, type and value. What changed is the code that reads it, so the same config can produce a different result. Nothing here needs an edit — this is what to expect, and what to change only if you disagree with it.

**Filters now see inside archives.** `any_file_inside_regex`, `any_file_inside_contains`, `any_file_inside_size_gte`/`_lte`, their `not_` forms, `has_episodes` and `is_music` used to be evaluated against the archive itself: one entry named `Show.part01.rar`, sized like the volume. Once zurg has listed an archive, they are evaluated against its contents instead — the real filenames, their real sizes, and deliberately *not* the archive's own size, which dwarfed everything in it. A season pack that read as one enormous file now matches `has_episodes`; `any_file_inside_regex: /\.mkv$/i` starts matching where it used to fail, and `any_file_inside_not_regex` stops matching where it used to pass. Separately, a release whose every file is `.rar`/`.r00`/`.par2` reaches the filters at all now, where before it went straight to `__unplayable__`.

This arrives release by release rather than all at once: it applies only to archives zurg has already listed, and listings written by an older parser are discarded, so a release moves the first time something opens it. If a directory of yours depends on the old reading, express it against the archive name with `regex`/`not_regex`, which still match the release name.

**Tag filters no longer catch releases that never probed.** `zurg_*` tags come from ffprobe. When nothing could be probed, every tier table bottomed out and the release was still stamped `zurg_sdr`, `zurg_very_low_video_bitrate`, `zurg_very_low_audio_bitrate` and `zurg_0to20mins_duration` — describing a file nobody had measured. Those are no longer emitted. A filter naming one of those four changes meaning for un-probeable releases: `has_tag`/`tags_match_all`/`tags_match_any` stop catching them, and — the direction worth checking — `not_has_tag`, `tags_missing_all` and `tags_missing_any` **start** catching them. Filters naming any other tier are unaffected.

**`added_within_hours` / `added_within_days` / `added_after` / `added_before` read an older timestamp for duplicates.** When one release is present more than once, the entry now reports the earliest add time rather than the first one seen, so a second copy of an old release no longer makes it look newly added. A `recent`-style directory can drop a release it previously kept.

**The mount caches directory listings for 12 hours.** `check_for_changes_every_secs` used to set rclone's `--dir-cache-time`, so listings expired every 15 seconds by default. They now hold for 12h and zurg forgets the affected entries explicitly whenever the library changes, which keeps media-server scans warm. To go back, override it directly — `rclone_extra_args` wins over any built-in flag:

```yaml
rclone_extra_args: ["--dir-cache-time", "15s"]
```

**A `__<account>__` directory appears at the mount root.** Every configured account gets one, single-account configs included, created from the `providers` block rather than from `directories`. It holds everything that account holds, ignores your directory filters, and pins reads to that account. It is not something `directories` can suppress.

**Two releases that shared a name are now two entries.** They used to merge into one, silently folding one release's files into the other's. The one that does not keep the bare name is suffixed with six characters of its info hash — `Movie.2024 {a1b2c3}`. That suffixed string is what `regex`, `not_regex`, `contains` and `not_contains` match against, so an anchored pattern will miss it. Separately, entries disambiguated by a duplicate basename are renamed once on upgrade, from an account-minted file id to a path-derived tag.

**`.strm` files change shape.** With `serve_strm_files`, every `.strm` the mount serves changes content and reported size — the URL now addresses the library entry rather than one account's link, so it fails over and survives repairs. A media server sees every `.strm` change. With `save_strm_files`, files already written are left alone and keep resolving on the old URL, so a library ends up holding both shapes. The new form is signed with a secret at `data/strm_secret`; if that cannot be written zurg logs a warning and starts anyway, and the links stop resolving after the next restart — worth not ignoring.

**`load_dumped_torrents` will not load a pre-upgrade `dump/`.** Cached torrents now carry the account they came from, and ones without that stamp are skipped. The main cache re-imports from the account on the next refresh; `dump/` has no account behind it, so it comes up empty with a warning in the log. Re-export from a running instance if you need it.

**Repair takes a different route when `restrict_repair_to_cached` and `only_full_torrent_repair` are false.** Both keys are unchanged when set to `true`. With them off — the default — the per-file and batched strategies were replaced by a single re-add naming the broken files. Same intent, different requests against the account.

**Smaller ones.** `ignore_renames` now also decides the name of the on-disk `.zurgtorrent` (self-migrating on load). `retries_until_failed` now bounds Real-Debrid fair-usage retries, which previously retried forever. `auto_analyze_new_torrents: false` and a missing `ffprobe_binary` no longer suppress cache cleanup, which used to be skipped along with the analysis. A size filter that excludes an archive's first volume now hides that archive entirely rather than falling back to a later volume. Unauthenticated static assets widened from `/static/css/*` to `/static/*`; no previously protected route became public.

## Windows Configuration

When running zurg on Windows, paths must be formatted differently:

```yaml
# Mount path - use drive letter with escaped backslash or forward slash
mount_path: "P:\\"       # Drive letter (escaped backslash)
mount_path: "P:/"        # Drive letter (forward slash also works)

# Binary paths - use forward slashes for paths to executables
ffprobe_binary: "Q:/zurg/bin/ffprobe.exe"
rclone_binary: "Q:/zurg/bin/rclone.exe"

# Alternative: use double forward slashes (also valid)
ffprobe_binary: "Q://zurg//bin//ffprobe.exe"
rclone_binary: "Q://zurg//bin//rclone.exe"
```

**Key points for Windows:**
- Use quotes around all paths
- For `mount_path`: use a drive letter like `P:\` (escaped as `P:\\` in YAML) or `P:/`
- For binary paths: forward slashes `/` work and avoid escaping issues
- Ensure `.exe` extension is included for executables

## 1. Essentials (Setup First)

These are the non-negotiables to get the server up and running.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `zurg` | string | *(required)* | Configuration version identifier. Must be set to `v1`; any other value (including an absent key) fails the load. |
| `providers` | list | *(required)* | Your debrid and Usenet accounts, one entry each. See [Accounts](#accounts) below. The pre-provider top-level `token`, `download_tokens` and `strm_link_token` keys are deprecated: they still load, as a single Real-Debrid account, and startup warns. A `providers` block that already configures Real-Debrid wins and the stray key is ignored. |
| `mount_path` | string | OS-dependent | The filesystem path where your rclone mount lives. Zurg uses this to tell media servers (Plex, Jellyfin, Emby) where to find files. Also used as the mount point when `rclone_enabled` is true. Defaults to `/mnt/zurg` (Linux), `/Volumes/Zurg` (macOS), or `Z:` (Windows). Docker users should set this to `/zurg_mnt/zurg` with `/zurg_mnt:/zurg_mnt:rshared` volume mount (see [docker.md](../setup/docker.md)). |
| `base_url` | string | `""` | The externally-reachable URL of your zurg instance. Embedded into STRM files so media servers can stream content. If unset, STRM files will contain `localhost` URLs that won't work from other devices. Use your Tailscale IP, LAN IP, or a reverse-proxied domain. Example: `http://100.x.x.x:9999` |

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/mnt/zurg"
base_url: "http://192.168.0.123:9999"
```

### Accounts

Each entry in `providers` is one account. Any number can run side by side — Real-Debrid, TorBox and AllDebrid together, or several accounts on the same service.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | string | *(required)* | Which backend the account uses: `realdebrid`, `torbox`, `alldebrid`, or `nzb`. |
| `name` | string | value of `type` | Distinguishes this account from others of the same type. It is the name used by the `provider` filter, the [per-account directory](#per-account-directories), cache paths, and the dashboard. Names must be unique across entries, and `e` is reserved for STRM link routing. |
| `token` | string | *(required)* | The account's API token or key. Get a Real-Debrid one from http://real-debrid.com/?id=440161, a TorBox one from https://torbox.app/settings, an AllDebrid one from https://alldebrid.com/apikeys. Not used by `nzb`, which authenticates through `nntp` instead. A Real-Debrid token can also be provided via the `TOKEN` or `RD_TOKEN` environment variable to auto-create a config on first run. |
| `download_tokens` | list | `[]` | Backup API tokens for the same service. When the primary token's daily bandwidth limit is reached, zurg automatically rotates to these tokens to keep downloads flowing. |
| `strm_link_token` | string | `""` | A separate API token that resolves the reads arriving at the `/strm/` endpoint, so a player opening a `.strm` does not spend the token the live mount streams on. Falls back to `token` if not set. **Real-Debrid and AllDebrid** — the two backends that rotate credentials, and so the two where pinning `.strm` traffic to a key of its own means something. Accepted and unused on `torbox` and `nzb` entries. |
| `disabled` | bool | `false` | Keeps an account in the config without loading it. If every entry is disabled, the load fails. |
| `watchlist` | bool | `false` | Marks the account tried first for new torrent adds (the download-client endpoints). At most one entry may set it, and never an `nzb` one. With none set, the first account that can add torrents is used. Plex watchlist acquisition itself goes through the Usenet backend, not this account — see [Watchlist](#watchlist). |
| `add_torrents` | bool | `true` | Whether this account is offered new torrents at all — the ones the download-client endpoints are handed, and the ones the Plex watchlist asks for. Set it `false` for an archive account, or one whose quota is spoken for: it goes on serving and reading its library while nothing new is ever put on it. **The order of the `providers:` list is the order the accounts that do take adds are tried in**, so this key and that order are read together; an account marked `watchlist: true` is tried first wherever it sits. Cannot be combined with `watchlist: true` on the same entry, and on an `nzb` entry it is ignored with a startup warning, since a news server is never handed a torrent. See [`qbittorrent`](#qbittorrent-the-torrent-download-client-sonarr-and-radarr-see). |
| `warm_connections` | int | `1` | How many connections this account keeps dialled and handshaken **to each host it has been using**, so a read does not pay to open one. Capped at 4. `-1` keeps none. Ignored on an `nzb` entry, whose floor is per account and lives at [`nntp.warm_connections`](../guides/usenet.md). See [warm connections](#warm-connections). |
| `nntp` | block | *(required for `nzb`)* | News server credentials. Required for type `nzb` and ignored by every other type. |

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    strm_link_token: YOUR_RD_API_TOKEN_FOR_STRM
    download_tokens:
      - ANOTHER_RD_API_TOKEN
      - ANOTHER_RD_API_TOKEN_2
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    watchlist: true
  - type: realdebrid
    name: rd-backup
    token: YET_ANOTHER_RD_API_TOKEN
    disabled: true
```

#### Usenet accounts

The `nzb` type is Usenet rather than a debrid service: `.nzb` files dropped into the `nzbs/` directory become torrents in the library, and reads are satisfied by fetching articles from your news server and decoding them on demand. Only one enabled `nzb` entry is supported, since both would scan the same directory — extra news servers go under that entry's `nntp.servers` instead, where they serve the same library rather than a second copy of it.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `host` | string | *(required)* | The news server hostname, e.g. `news.eweka.nl`. |
| `port` | int | `563` with TLS, `119` without | The news server port. |
| `tls` | bool | `false` | Wraps the connection in TLS. |
| `username` | string | `""` | The account username. |
| `password` | string | `""` | The account password. |
| `connections` | int | `8` | The account's concurrent connection allowance. Zurg reads at this number — one connection carries a fraction of a plan's throughput, so streaming saturates the allowance rather than fetching one article at a time. Going over what the plan permits gets connections refused, so set it to the real figure. |
| `cache_size_mb` | int | `512` | How much decoded article data is held in memory, across every file being read rather than per file. |
| `servers` | list | `[]` | Further news accounts to fall back to, article by article. See [more than one news server](#more-than-one-news-server). |

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
```

##### More than one news server

Retention is per-provider: an article one server has aged out is very often still on another. Without a second account the only way to recover a dead article is PAR2, and that costs a read of the **entire release** — so a second server is the difference between fetching one article and re-reading everything.

The keys above describe the first account. Anything under `servers` is a further account, asked only when the ones before it did not have the article. An existing single-server config keeps working unchanged.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | string | value of `host` | Labels the account in logs. |
| `host`, `port`, `tls`, `username`, `password`, `connections` | | | As above. Each account has its own connection allowance. |
| `priority` | int | `0` | Who is asked first, lowest first. Accounts sharing a priority are asked in the order written, except that one with a free connection is preferred over one whose allowance is spent — so two equal accounts share the load. |
| `backup` | bool | `false` | Marks a block account, consulted only once every primary has answered *no such article*. A primary being **busy** is not enough: zurg waits for it rather than spending metered bytes on something an unlimited account would have served. |
| `backbone` | string | `""` | The article spool this account resolves to. Two accounts on one backbone hold the same articles, so once one has said it lacks an article the other is skipped instead of being asked the same question. |

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # the first account
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com          # only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

The census that decides whether a release needs repairing asks every account before calling an article missing, so a release one provider has holes in does not trigger a PAR2 rebuild when another provider can still serve it.

A top-level key governs what repairs leave behind:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `par2_patch_cache_mb` | int | `512` | How much of `data/par2/` the bytes rebuilt by PAR2 repair may occupy. Those bytes are the one thing a reader cannot ask the news server for again — the articles carrying them are gone — so keeping them means a restart does not cost a full re-read of the release to recover the same few megabytes. Only the dead articles' spans are stored, which is single-digit megabytes per damaged release; whole releases are dropped, least recently used first, when the budget is exceeded. A negative value turns persistence off and keeps repairs in memory for the life of the process. |

And two govern what a parsed NZB costs in memory:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nzb_segments` | string | `mmap` on Linux/macOS/BSD, `resident` on Windows | How a parsed NZB's article list is retained. **Needs a restart.** `mmap` writes the lists to `data/nzb-index/<id>.bin` and maps that file on demand, so the bytes live in the page cache instead of on zurg's heap. `reparse` gives them back once the release has settled and re-reads the NZB from disk when a read or a repair needs them, costing no disk at all. `resident` keeps every one of them in memory for the life of the process — **the previous behaviour**, and what every earlier build did. Anything unrecognised takes the default and is named in a startup warning; the mode actually in force is logged at startup either way. |
| `nzb_segments_idle_secs` | int | `120` | How long a release's article list is kept after the last read of it, under the lazy modes. **Needs a restart.** A sweep runs every 30 seconds, so 10 is the shortest window it can honour and the Dashboard's floor. Ignored under `resident`, which never gives anything back. `0` takes the default. |

The trade is worth stating plainly, because it is not the usual memory-for-speed one. A listing — a library refresh, a fingerprint check, an *arr asking whether a job has settled — never touches an article under any mode: a file's name, its size and its article count are answered from the entry itself. What the lazy modes cost is the *first* read of a release nothing has touched for `nzb_segments_idle_secs`, and what they save is the heap the article lists occupy the rest of the time. Measured on a 60-file, 30,000-segment release (Apple M3 Pro):

| | heap per release, settled | first read of an idle release | per article on the read path |
|---|---|---|---|
| `resident` | 1.74 MB (58 B/segment) | — | 6 ns |
| `reparse` | 21.3 kB (0.71 B/segment) | 39 ms | 52 ns |
| `mmap` | 16.6 kB (0.55 B/segment) | 0.27 ms | 63 ns |

Two thirds of the `mmap` reload is the checksum over the index it has just mapped — the map itself is 0.08 ms — and it is worth that: without it a single bad byte inside an arena is served as a message id nobody posted, which the news server answers as a dead article and every layer above reads as damage to the release.

And on a real library — 2,636 NZBs, 27.6 million segments, the same binary run three times over the same corpus, idle after a scan:

| | resident set | live heap | idle CPU | cold open, p50 | index on disk |
|---|---|---|---|---|---|
| `resident` | 2,921 MB | 2,677 MB | 23 % | 806 ms | — |
| `reparse` | 1,188 MB | 987 MB | 31 % | 1,018 ms | — |
| `mmap` | **1,135 MB** | **921 MB** | 23 % | **694 ms** | 1,456 MB |

Warm opens, streaming throughput and startup time were indistinguishable. `mmap` is the default wherever there is a real mapping because it wins on every axis but disk — a cold open included, since mapping a written arena is a syscall where parsing the NZB again is megabytes of XML. It costs about 55 bytes of disk per article and one extra write per release at scan time; the index is rewritten whenever the NZB changes and removed when the NZB goes. Choose `reparse` on a host where `data/` must not grow. On Windows there is no mapping — the index would be read into the heap, which is resident memory *plus* a reload — so the default there stays `resident` and `reparse` is the lazy mode worth choosing.

## 2. Media Server Integration

Connect zurg to your media server so library updates, metadata matching, and watchlist monitoring work automatically.

### Plex Integration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plex_server_url` | string | `""` | URL of your Plex server. Required for Plex matching and watchlist features. Example: `http://localhost:32400` |
| `plex_token` | string | `""` | Your Plex authentication token. Required alongside `plex_server_url`. |
| `plex_match_every_mins` | int | `1440` | How often (in minutes) zurg scans your Plex library to match torrents to Plex items. This enables features like showing which torrents correspond to which Plex media. Minimum 1; `0` falls back to the default. Requires `mount_path` to be set. |
| `plex_watchlist_enabled` | bool | `false` | Legacy spelling of `watchlist.enabled` (see [Watchlist](#watchlist)); still honoured. |
| `plex_watchlist_check_every_secs` | int | — | Legacy spelling of `watchlist.check_every_secs`; still honoured when the block does not set one. |
| `watchlist_quality` | string | `"best"` | Legacy spelling of `watchlist.quality`; still honoured when the block does not set one. |
| `plex_settings_policy` | string | `"guard"` | How far zurg may go in correcting the Plex preferences that matter for a debrid mount. One of `off` (touch nothing), `warn` (report everything, change nothing), `guard` (fix only the settings whose wrong value loses a library, report the rest) or `enforce` (also fix the settings that make Plex decode whole files). Skip Intro and Skip Credits are only ever reported. See [Plex settings](../guides/plex.md#recommended-plex-settings). |
| `plex_settings_ignore` | list | — | Plex preference ids zurg leaves alone whatever the policy says, matched case-insensitively. Per setting rather than per tier, so opting out of one does not give up the others beside it. An id naming no setting zurg knows is reported at startup and changes nothing. See [Opting out of one setting](../guides/plex.md#opting-out-of-one-setting). |

> **Note:** Plex is best configured through the Dashboard (web UI) authentication flow; it writes `plex_server_url` and `plex_token` back into `config.yml`. The keys above remain supported for manual configuration.

```yaml
plex_server_url: "http://localhost:32400"
plex_token: "your-plex-token"
plex_match_every_mins: 1440
```

### Watchlist

Add something to your Plex watchlist and zurg fetches it: every new watchlist item is searched on your Newznab indexers and the chosen release's NZB drops into the Usenet backend, exactly as a Sonarr grab or a Stremio play would — the three surfaces share the naming rules, so they find each other's grabs instead of duplicating them. A movie becomes one release; a show is acquired season by season, preferring season packs over loose episodes — a season nobody posted a pack of falls back to the loose episodes the search surfaced, best release per episode. The item leaves the watchlist only once something was actually acquired; failures stay on the list and are retried a few times with backoff.

It needs a `plex_token` (the monitor talks to Plex's cloud service, so `plex_server_url` is not required), a configured `nzb` provider to read the watch directory, and at least one indexer — its own list, or the Stremio addon's.

Every option below is on the config page under **Plex Watchlist**, indexer list included; the dashboard writes this block rather than the legacy flat keys, and switching the monitor off there clears `plex_watchlist_enabled` too, since that one is ORed into the switch.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | bool | `false` | Starts the monitor. The legacy `plex_watchlist_enabled` key still counts. |
| `check_every_secs` | int | `60` | How often the watchlist is polled on Plex's cloud service. |
| `indexers` | list | `[]` | Newznab endpoints to search, each with `name`, `url`, `api_key` and optional `api_path` — the same shape as `stremio.indexers`, which is borrowed wholesale when this list is empty. |
| `max_size_gb` | int | `40` | Releases larger than this are dropped for movies and single episodes. Releases whose size the indexer did not state are kept. |
| `max_season_size_gb` | int | `100` | The same ceiling for season packs, which are legitimately several times a movie. |
| `quality` | string | `"best"` | Which release wins: `best` (resolution first, then size), `4k`, `1080p`, `720p` (prefer that resolution, fall back to best) or `smallest`. The legacy `watchlist_quality` key still counts. |

```yaml
plex_token: "your-plex-token"
watchlist:
  enabled: true
  check_every_secs: 60
  max_size_gb: 40
  max_season_size_gb: 100
  quality: best
  indexers:
    - name: nzbgeek
      url: https://api.nzbgeek.info
      api_key: your-api-key
```

### Plex Library Maintenance (same host only)

These need Plex installed on the same machine as zurg, because they read its database file directly. `plex_server_url` is frequently another host or container and no HTTP endpoint can hand over that file, so they are driven by an explicit path and stay off until you set one.

zurg only ever **reads** this database, through a read-only handle. It never writes to it and never stops Plex. The one file it creates is a snapshot in its own `data/plex-backups/`, never in Plex's directory.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plex_database_path` | string | `""` | Full path to `com.plexapp.plugins.library.db`. Empty turns every feature in this section off. |
| `plex_sqlite_binary` | string | `/usr/lib/plexmediaserver/Plex SQLite` | Plex ships its own SQLite build. A stock `sqlite3` can fail on, or damage, this database. |
| `plex_backups_keep` | int | `5` | Snapshots retained. Each is the size of the whole database. An explicit `0` observes without ever snapshotting. |
| `plex_backups_every_mins` | int | `15` | Minimum gap between snapshots, so a crash-looping zurg does not copy the database on every restart. |
| `plex_trash_sweep_every_mins` | int | `0` (off) | How often to remove Plex entries whose files are gone from the mount. **No default is applied** — this one deletes library entries, so it runs only because you set the key. |
| `plex_trash_sweep_max_items` | int | `50` | Most entries one sweep may remove. Exceeding it aborts the sweep without removing anything. |
| `plex_trash_sweep_max_percent` | int | `10` | The same cap as a percentage of what is in the trash, so it scales with library size. |
| `plex_trash_sweep_min_age_days` | int | `14` | How long an entry keeps its red trash icon before the sweep may remove it — the fallback for entries zurg has no verdict on. A release zurg knows to be permanently dead is removed without the wait, and one still under repair stays regardless of age. An explicit `0` removes as soon as the other guards allow. |

**Why snapshots**, when Plex already backs itself up nightly: the danger is the mount being disturbed while Plex is mid-scan, which can empty a library in seconds. A nightly backup can be 24 hours stale at that moment; one taken just before zurg touches the mount is seconds old.

#### What the trash sweep will never remove

Plex's trash is not a list of things that may be deleted. It is a list of candidates, and a large share of them are wrong:

- **An item that still has a file.** Plex tombstones an entire movie when a single one of its versions disappears, so a trashed item routinely has versions that still play. The sweep drops the phantom version instead, which brings the item back out of the trash with its collections, artwork, watch state and `added_at` intact. If that repair fails for any reason, the item is **left alone** — it stays in your library with its trash icon. It is never deleted.
- **A show or season whose episodes are still there.** These carry no files at all, so nothing about the mount can justify removing one.
- **Anything whose file it did not individually confirm missing**, immediately before removing it.

Removal is per item rather than Plex's own `emptyTrash`. `emptyTrash` is section-wide and would take exactly the entries above, which is the one thing the sweep must not do.

#### zurg already knows whether it is coming back

For every absent file the sweep asks zurg's own repair state before reaching for the timer:

| zurg's verdict | The sweep |
|---|---|
| the file still reads (the filters hide it from the mount) | falls back to the age window |
| broken, and repair has not given up | **keeps the entry**, however long repair takes |
| broken with a permanently unrepairable reason (infringing, invalid, not allowed, …) | **removes it at once** — waiting cannot bring it back |
| no verdict — the torrent left the account entirely, or the path does not resolve | falls back to the age window |

An item with several versions is judged as a unit: one version still under repair keeps the whole entry, and an entry is only known dead when every version is. A failed lookup is never a licence to delete — anything zurg cannot vouch for is handled by the age window below, exactly as before.

#### The trash icon is a status, so removal waits

Plex has three states, and only the middle one is visible as a problem:

| State | What you see |
|---|---|
| Live | a normal entry that plays |
| **Trashed** | the entry is **still in your library and still counted**, greyed out with a **red trash icon**, and will not play |
| Purged | nothing — the entry is gone from Plex entirely |

The trash icon is the only notice you get that content has gone missing, and purging the entry takes that notice away along with it: the item stops being visibly broken and simply stops existing. So an entry zurg has no verdict on is left alone until it has carried the icon for `plex_trash_sweep_min_age_days`. That window is your chance to see it and re-acquire; anything still broken afterwards was junk worth clearing.

It also acts as a third safety layer under the caps and the mount probe — a transient mount problem resolves itself long before the window elapses.

The grace period governs **removal only**. A repair puts a playable item back in your library, so it happens on the next sweep regardless: waiting would leave a working item wearing a trash icon for no reason.

None of these states touch files. The file was already gone from the mount — that is what caused the tombstone — and nothing is ever deleted from your debrid account.

#### When it refuses to run

- zurg is not managing rclone (`rclone_enabled: false`) — it cannot vouch for a mount it does not own, so "the file is missing" means nothing.
- rclone is not running, or the mount does not read. The probe opens and reads a file rather than calling `stat`, because a `stat` is answered from rclone's directory cache and keeps succeeding long after reads have stopped working.
- Plex is scanning. A scan in flight is still deciding what is missing.
- Either cap would be exceeded. This is the important one: **a mount that came back empty but readable passes every other check**, and makes the whole library look deleted. Going over a cap aborts the sweep entirely, removes nothing, and says so in the log.

A snapshot is taken before anything is removed, and a snapshot failure aborts the sweep.

> **Turning it off:** set `plex_trash_sweep_every_mins: 0`, or remove the key. Changing it needs a zurg restart.

```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plex_trash_sweep_every_mins: 360
plex_trash_sweep_min_age_days: 14
plex_trash_sweep_max_items: 50
plex_trash_sweep_max_percent: 10
```

> **Related Plex setting, outside zurg:** turn **off** Plex's *Settings → Library → Empty trash automatically after every scan*. It is enabled by default in Plex and is unsafe on a zurg mount — a scan that meets a briefly unreadable mount deletes the library permanently instead of parking it in the trash, where it would come back with the mount. zurg warns on the dashboard and in the log when it finds this enabled.

### Other Integrations

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `jellyfin_server_url` | string | `""` | URL of your Jellyfin server. Enables library refresh notifications when zurg detects changes. Example: `http://localhost:8096` |
| `jellyfin_token` | string | `""` | Jellyfin API token for authentication. |
| `emby_server_url` | string | `""` | URL of your Emby server. Enables library refresh notifications when zurg detects changes. Example: `http://localhost:8096` |
| `emby_token` | string | `""` | Emby API token for authentication. |
| `dmm_api_key` | string | `""` | API key for DebridMediaManager integration. |

```yaml
jellyfin_server_url: "http://localhost:8096"
jellyfin_token: ""
emby_server_url: "http://localhost:8096"
emby_token: ""
dmm_api_key: ""
```

## 3. Playback & File Structure

Controls what files your media server sees and how content is streamed.

### Streaming Mode

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `disable_stream_proxy` | bool | `false` | When true, a **mount** read is answered with a redirect to the account's own download URL instead of being proxied through zurg. Reduces zurg's CPU and bandwidth but means the client must be able to reach the account's servers directly. Ignored for a backend whose links are served locally — a Usenet file has no URL to hand out, so it is always proxied. |
| `serve_strm_files` | bool | `false` | When true, zurg serves `.strm` files in place of actual video files in the WebDAV mount. Media servers like Plex/Jellyfin read the `.strm` file to get the streaming URL. **Important:** When enabled, the actual video files are hidden and replaced by `.strm` entries. |
| `save_strm_files` | bool | `false` | When true, zurg writes `.strm` files to a `strm/` directory alongside the zurg binary. Useful for setups where you want persistent STRM files on disk (e.g., for manual import into a media server). Uses `base_url` for the URLs inside the files. |

```yaml
disable_stream_proxy: false
serve_strm_files: false
save_strm_files: false
```

#### What `disable_stream_proxy` does and does not reach

It governs the mount. It does not reach the `/strm/` endpoint, on any backend:

| Read arrives via | Real-Debrid / TorBox / AllDebrid | Usenet |
|---|---|---|
| Mount, proxy on (default) | proxied through zurg | proxied |
| Mount, proxy off | `302` to the account's URL | proxied — no URL exists to redirect to |
| A `.strm` file, either setting | `307` to the account's URL | proxied |

A `.strm` is opened by a player zurg has no session with, so the endpoint can only hand over a URL the player can fetch itself — turning the proxy on does not route that traffic back through zurg. The consequence worth knowing: reads that arrive from `.strm` files get no bandwidth accounting, no mid-stream failover to another account, and no broken-link detection, all of which a mount read gets. A library served mainly through `.strm` therefore sees little from `disable_stream_proxy` either way.

`serve_strm_files` and `disable_stream_proxy` are independent, despite what older versions of this page said. A `.strm` is served as text before any streaming decision is reached, so the two can be enabled together — though with `serve_strm_files` on, every playback arrives at the `/strm/` endpoint, which is exactly the row above where `disable_stream_proxy` changes nothing.

### File Filtering & Detection

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `addl_playable_extensions` | list | `[]` | File extensions that zurg should treat as playable media in addition to the built-in video/audio formats. Dots, quotes, and case are normalized by the dashboard. Add extensions like `m3u` or `cbz` if you want those files to be visible and selectable. |
| `force_select_playable_files` | bool | `false` | When true, zurg automatically selects all playable files in a torrent, even if they weren't originally selected. Works with both built-in video extensions and `addl_playable_extensions`. Useful when torrents have unselected video files you want access to. |
| `delete_torrent_if_extensions_found` | list | `[]` | If any file in a torrent has one of these extensions, the entire torrent is deleted from RD. Useful for automatically removing torrents that contain unwanted content like `.rar` archives (not RD-extracted ones) or `.zipx` files. |

Built-in playable formats are `.avi`, `.flv`, `.m2ts`, `.m4v`, `.mkv`, `.mov`, `.mp4`, `.mpg`, `.mpeg`, `.ts`, `.webm`, `.wmv`, `.mp3`, `.flac`, `.m4a`, and `.m4b`.

```yaml
addl_playable_extensions:
  - m3u
  - cbz
force_select_playable_files: false
delete_torrent_if_extensions_found:
  - zipx
  - rar
```

### Metadata & Naming

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `retain_folder_name_extension` | bool | `false` | **Deprecated — will be removed.** When true, the folder name is the account's `Name` verbatim, extension and all, instead of `OriginalName` with a trailing `.mp4` then `.mkv` trimmed off. It applies only where `Name` contains `OriginalName` as a substring; everywhere else the trim happens anyway. `retain_rd_torrent_name` is checked first and shadows it entirely. |
| `retain_rd_torrent_name` | bool | `false` | **Deprecated — will be removed.** When true, the folder name is the account's `Name` (Real-Debrid's `filename`); when false it is `OriginalName` (`original_filename`), which is the name the torrent itself declared. This matters for a pack with one file selected: Real-Debrid collapses `filename` to that file's own basename while `original_filename` stays the pack name, so **`false` gives the pack name and `true` gives the individual file's**. |
| `ignore_renames` | bool | `false` | When true, zurg ignores any rename metadata in torrents and uses original filenames. Enable this if renamed files are causing issues with your media server's matching. Not deprecated. |

```yaml
retain_folder_name_extension: false   # deprecated
retain_rd_torrent_name: false         # deprecated
ignore_renames: false
```

Both deprecated flags key the library on `Name`, which the account rewrites
underneath zurg; the defaults key it on the name the torrent declared, which the
account leaves alone. Setting either logs a warning at startup, and on an
instance fronting Sonarr or Radarr (a `sabnzbd:` or `qbittorrent:` block) the
defaults are the only correct values — an access key that moves after an import
loses the release. Behaviour is unchanged this release: nobody's folder names
move. `docs/naming.txt` is the full set of naming rules.

### Mount Writes

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dav_allow_rename` | bool | `true` | When false, a WebDAV MOVE through the mount is refused with 403. On by default: renaming a torrent or a file is what the writable mount exists for and it destroys nothing. |

**A WebDAV DELETE through the mount is always honoured — there is no key for it.** It removes a file from the library, and the release from every debrid account holding it once nothing is left. Know what that costs before pointing a writer at the mount: rclone flushes an overwritten file as DELETE followed by PUT, so anything that rewrites a file in place (an `.nfo` writer, a trickplay pass, an \*arr rename, a stray `touch`) deletes content instead of replacing it, and the mount carries rclone's own credentials so authentication cannot tell the two apart. Only the PUT half being refused keeps that sequence from completing quietly. `mount_read_only: true` is what stops a delete reaching zurg at all.

A refused write answers **403** and logs the config key that would allow it, so a client whose write stopped working says why in `logs/zurg.log`.

One aftermath to know about: when a program writes through the FUSE mount, rclone's VFS cache keeps the modified copy and retries the refused upload on a backoff, and the mount shows the locally-modified file until that cache entry is discarded — the server-side file is untouched the whole time. `mount_read_only: true` avoids this entirely by failing the write at the kernel, before rclone caches anything.

```yaml
dav_allow_rename: true
```

See also `mount_read_only`, which makes the kernel refuse the write before it reaches zurg.

### Directory listing cache

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `disable_listing_cache` | bool | `false` | When true, every directory listing is rendered from scratch on every request. Leave it off: with it on, a `PROPFIND Depth:1` of `__all__` re-renders the whole library each time it is asked — measured at 59 ms for 6,120 releases, 121 ms for 2,636 Usenet releases, 148 ms for `__magic__`'s root — and a media server scan asks for the same listing over and over. |

```yaml
disable_listing_cache: false
```

The cache keeps the last rendering of each top-level directory, one per mount flavour (`/dav`, `/infuse`, `/http`), and hands it back until the library changes. What counts as a change is not a guess: it is exactly the set of events that already make rclone forget its own cached copy of the same listing — a release added, removed, renamed, refiled, a file going broken or healing — and rclone holds those listings for **twelve hours**. So a listing served from here is never staler than the one the mount is already serving, and there is a hard 60-second cap on top of that as belt and braces.

`__magic__`'s root additionally tracks the stored layout, so an \*arr import invalidates `__magic__` alone and leaves every other directory's rendering intact. `__downloads__` and `Depth: 0` requests are not cached at all.

Responses carry an `X-Zurg-Listing: hit` or `miss` header, so a live install can be measured:

```bash
curl -s -o /dev/null -D - -X PROPFIND -H 'Depth: 1' http://localhost:9999/dav/__all__/ | grep -i x-zurg-listing
```

### `__magic__`, a directory you can organise

Every other directory is a saved filter — a release is in `movies` because it matches the movies filter — so there is nowhere in the library to *put* something. `__magic__` is the exception: it starts as an exact copy of `__all__`, and inside it anything can be moved anywhere. A move rewrites a row in `data/magic.journal`, compacted into `data/magic.json`; no bytes move, no torrent is renamed, and the rows key on the release's content hash, so a repair that rebuilds the release does not lose where you put things. It is what lets Radarr and Sonarr import by rename instead of by copy.

Full write-up, including what survives a repair and what each refusal means, in [docs/magic.md](../guides/magic.md).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `magic.enabled` | bool | `false` | Serve `__magic__` at all. Off by default: it is a writable tree, and an \*arr pointed at the wrong root folder can reorganise a library. With nothing moved it reads exactly as `__all__` does. |
| `magic.allow_delete` | bool | `false` | When true, a DELETE of a **file** under `__magic__` also deletes the content, as a DELETE on the mount proper always does. Off by default, a delete only hides: the entry leaves `__magic__` and stays in `__all__` and in every filter directory. A release folder and a directory never delete content whatever this is set to — Sonarr deletes the job folder after every import. |
| `magic.sidecar_max_mb` | int | `32` | The largest single file a client may `PUT` into `__magic__`. Over it the write is refused with **413**. |
| `magic.sidecar_budget_mb` | int | `2048` | The largest the whole sidecar tree may grow. Over it a write is refused with **507 Insufficient Storage**, which says what 413 does not: deleting something makes the same request succeed. The total is measured by walking the tree at startup, so a restart does not hand the allowance back to a tree that is already full, and again before any refusal — the tree is the same `data/local` directory zurg's own mount writes into, so a file removed there behind zurg's back must not go on being charged for. Zero or a negative takes the default; there is no way to ask for no cap. |

```yaml
magic:
  enabled: true
  allow_delete: false
  sidecar_max_mb: 32
  sidecar_budget_mb: 2048
```

`dav_allow_rename` does not apply here, and neither does the mount's ungated delete path. Those cover the routes that rename and destroy what the debrid account holds; a write under `__magic__` reaches no account. `mount_read_only: true` still overrides everything, at the kernel.

Two things worth knowing. The filter directories are untouched by design, so a release you moved inside `__magic__` is still in `recent` and `movies` under its own name — point a media server at `__magic__` **or** at the filters, not at both. And anything genuinely new written into the mount (an `.nfo`, a subtitle, a poster) lands in zurg's own `data/local` and is merged into the listing, which is why sidecars beside a release simply work.

#### Sidecar files, and what the two caps are for

The embedded mount is a union whose first upstream is `data/local`, so when a program creates a new file on the mount, rclone writes it there and zurg is never asked. Nothing caps that tree — unless [`union_writable: server`](#rclone-settings) flips the union order, in which case the create arrives at zurg as a `PUT` and is refused outside `__magic__` and bounded by the two caps inside it.

With the default order, the two caps are for the other kind of client: one that mounts `/dav` directly, with no union in front of it. Those send zurg the `PUT`, and zurg writes the body into `data/local/__magic__/<path>` — the very directory the union serves — so the two views show one directory rather than two. Without a bound, that is a general file store reachable over WebDAV, which is what `sidecar_max_mb` and `sidecar_budget_mb` exist to prevent.

Two rules follow from what `__magic__` is, and both are refusals a client may see:

- **Nothing the library answers for may be written over.** A release folder, an entry of one, and a path a move has placed something at are all rendered from the library, so a `PUT` or a `MOVE` of a real file onto any of them is **403**. That includes a name inside a release folder the release does not have: the folder's listing is the release's, so a file put among its entries would be listed by nothing.
- **A placement never destroys a real file.** Moving something the library holds onto a path a sidecar occupies is refused rather than overwriting it, even with `Overwrite: T`. The same holds for a directory of real files moved the other way: it may not be renamed onto a path the library answers for, because its files would then sit in a folder that lists the release and nothing else.

A `DELETE` of a sidecar really deletes it, which is the one place in `__magic__` where a delete is not a tombstone: a tombstone hides an entry the library still holds elsewhere, and a sidecar's bytes live in `data/local` and nowhere else.

#### The `__magic__` page

The dashboard has a page of its own for the namespace, at `/magic/`, linked from the dashboard's quick links whenever `__magic__` is configured or served. It is where the table is visible, and it is the only place two of its states can be reached at all.

It reports how many rows are stored — placements, tombstones and directories, counted separately — what the journal and the snapshot take on disk, how much of `sidecar_budget_mb` the sidecar tree is using, and the size of the whole of `data/local`. That last number is the one to watch: a client that copies rather than moves puts the bytes there, so a `data/local` climbing into gigabytes means something is importing the wrong way round. The rows themselves are grouped by release; a very large table is truncated on the page and says by how much, and the counts above it are always of the whole table.

Three buttons, all of which go through the same one operation — a row ceasing to exist:

- **Reset** a placement, and the file or folder goes back to where the library puts it.
- **Unhide** a tombstone, and the entry is listed in `__magic__` again. Nothing was destroyed to hide it.
- **Delete** a **dangling** row — one whose release, or whose file inside it, the library no longer holds. Such a row resolves to nothing, so it cannot be listed, moved or deleted through the mount, and it is kept rather than dropped because a repair that restores the release restores where you put it. Until this page there was no way to clean one up; **Clear all dangling rows** sweeps them in one go.

Sidecars are listed as well, and the ones **nothing accounts for any more** are listed apart from the rest and counted. Those are the sidecar's equivalent of a dangling row: an `.nfo` or a poster written beside a release that has since left the library, or inside a folder whose placement has been forgotten. They are still served — a real file is the last thing a `__magic__` path resolves to, and nothing above them is claiming the name any longer — so the only thing that has gone is the reason they were put there. zurg never sweeps one: a file left beside a release that was deleted is still yours, and a repair that brings the release back accounts for the folder again. A directory you made for sidecars yourself, through the mount rather than through zurg, reads the same way here, because that leaves no row either.

Deleting a sidecar from the page really deletes the file, the same way a `DELETE` through the mount does. Every button changes what the mount has cached for the paths involved, because the mount holds a directory listing for twelve hours with polling off.

If the SABnzbd endpoint is on, the page also lists the jobs it has been handed — the id the client knows each by, its category, whether the release has arrived in the library yet, and the folder to import from once it has. That list is read-only: delete a job from the client, not from here.

Both the `magic:` and the `sabnzbd:` block are editable in full from the [config page](#sabnzbd-the-download-client-sonarr-and-radarr-see), and both say **Restart Required**, which they mean literally: the routes that serve `__magic__` and the SABnzbd endpoint are registered once, at startup, out of these values. Turning either on writes it to `config.yml` and changes nothing about the run that answered — the `__magic__` page says so too rather than rendering an empty namespace.

### `sabnzbd`, the download client Sonarr and Radarr see

zurg can answer Sonarr and Radarr as though it were a SABnzbd. They hand it an NZB, it writes the file into `nzbs/` for the Usenet backend, and once the release is in the library the job reports **Completed** with a job folder under `__magic__` to import from. Nothing is downloaded to import: the \*arr renames the file inside the mount, which is a row in the `__magic__` table.

It needs both halves to be useful — an `nzb` provider to read the NZB, and `magic.enabled` to have somewhere to import from — and it is off until asked for. Full setup, including what to put in the \*arr, is in [docs/sabnzbd.md](../guides/sonarr-radarr.md).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `sabnzbd.enabled` | bool | `false` | Register the endpoint at `/api` and `/sabnzbd/api`. While off, neither route exists. |
| `sabnzbd.api_key` | string | generated | The only gate on the endpoint. Sonarr and Radarr send no basic auth, so these routes sit outside it and the key is what stands in. Left empty with the block enabled, zurg generates one, keeps it in `data/sabnzbd-apikey` so it survives a restart, and logs it once at startup. |
| `sabnzbd.categories` | list | `[tv, movies]` | The categories reported to the clients. Every one of them resolves to the same directory, so this exists only to stop a client warning about a category it cannot find — add whatever you configured in the \*arr. `*` is always reported as well. |
| `sabnzbd.complete_dir` | string | `<mount_path>/__magic__` | The completed directory reported to the clients. It must be the path **the \*arr** sees, which is not zurg's own when the \*arr runs in a container that mounts the library elsewhere. |

```yaml
sabnzbd:
  enabled: true
  api_key: ""
  categories: [tv, movies]
  complete_dir: ""
```

The API key is the whole of the authentication, so treat the endpoint the way you treat the rest of zurg's port: on a trusted network, or behind something that is. Basic auth cannot be used for it — the clients never send it, and a 401 is reported to the user as "unable to connect" rather than as an authentication failure.

### `qbittorrent`, the torrent download client Sonarr and Radarr see

zurg can answer Sonarr and Radarr as though it were a qBittorrent. They hand it a magnet or a `.torrent` and zurg adds the info hash to a debrid account. Once the release is in the library the torrent reports **finished** with a folder under `__magic__` to import from. Nothing is downloaded to import. The \*arr renames the file inside the mount and that is a row in the `__magic__` table.

Two halves make it useful. An account that can add torrents reads the magnet and `magic.enabled` gives the \*arr somewhere to import from. It is off until asked for. Full setup including what to put in the \*arr is in [docs/qbittorrent.md](../guides/sonarr-radarr-torrents.md).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `qbittorrent.enabled` | bool | `false` | Register the endpoint at `/api/v2` and `/qbittorrent/api/v2`. While off, neither route exists. |
| `qbittorrent.api_key` | string | generated | The only gate on the endpoint. The clients send it as a bearer token when their **API Key** field is set, and accept it as the password on `auth/login` when it is not. Left empty with the block enabled, zurg generates one, keeps it in `data/qbittorrent-apikey` so it survives a restart, and logs it once at startup. |
| `qbittorrent.categories` | list | `[tv-sonarr, radarr]` | The categories reported to the clients — the two the \*arrs ship with. Every one of them resolves to the same directory, so this exists only to stop a client warning about a category it cannot find. |
| `qbittorrent.save_path` | string | `<mount_path>/__magic__` | The save path reported to the clients, and the parent of every folder they import from. It must be the path **the \*arr** sees, which is not zurg's own when the \*arr runs in a container that mounts the library elsewhere. Set `sabnzbd.complete_dir` to the same value if you run both endpoints. |
| `qbittorrent.download_timeout_mins` | int | `15` | How long a grab may go with no movement — no change of stage and no rise in progress — before that account is given up on and the next one that takes torrents is tried. `0` means cached-only: a grab is accepted only onto an account that already holds the content, and refused inside the add otherwise, which is the one refusal Sonarr and Radarr act on. A negative number never gives up. See [Timeouts and cached-only mode](../guides/sonarr-radarr-torrents.md#timeouts-and-cached-only-mode). |

```yaml
qbittorrent:
  enabled: true
  api_key: ""
  categories: [tv-sonarr, radarr]
  save_path: ""
  download_timeout_mins: 15
```

Fifteen minutes is a measured figure rather than a chosen one. AllDebrid parks a healthy job in its own queue with every counter at zero before it moves a byte. Two runs out of two sat there for 580 and 622 seconds. The captures are in [docs/torrent-lifecycle.md](../internals/torrent-lifecycle.md).

Which account a grab goes to is decided by [`add_torrents`](#accounts) and by the order of the `providers:` list. A grab that timed out or that an account gave up on is deleted from that account before the next one is tried. Only an instance zurg added itself for that grab and that never finished is ever a candidate. Nothing else this endpoint answers deletes anything from a debrid account.

The API key is the whole of the authentication. Treat the endpoint the way you treat the rest of zurg's port. Put it on a trusted network or behind something that is. Basic auth cannot be used for it. The clients never send it and they read a 401 as a hard authentication failure they never retry.

### Media Analysis

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `auto_analyze_new_torrents` | bool | `false` | When true, zurg automatically runs ffprobe on every newly added torrent to extract media metadata (resolution, codecs, duration, audio/subtitle tracks). This metadata powers tag-based directory filters like `zurg_4k`, `zurg_aud_eng`, and duration tiers. Disable if you don't use tag-based filters or want to reduce CPU usage on new additions. |
| `ffprobe_binary` | string | `"ffprobe"` | Path to the ffprobe executable. Only needed if ffprobe is not on your system PATH. Used for media analysis. |

```yaml
auto_analyze_new_torrents: true
ffprobe_binary: "ffprobe"
```

## 4. Health & Repairs (Automation)

The "set it and forget it" section. Controls how zurg keeps your library healthy by detecting and fixing broken torrents automatically.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable_repair` | bool | `false` | Enables automatic torrent repair. When a torrent becomes unavailable (e.g., removed from RD cache), zurg will attempt to find and add a replacement. **Important:** Only one zurg instance should have repair enabled to avoid conflicts. |
| `repair_every_mins` | int | `60` | How often (in minutes) zurg scans for broken torrents that need repair. Lower values catch problems faster but increase API usage. |
| `repair_timeout_mins` | int | `30` | Maximum time (in minutes) to wait for a repair operation to complete. If a repair takes longer than this, the torrent is marked as broken and skipped until the next repair cycle. |
| `stalled_download_mins` | int | `10` | Minimum minutes before a downloading torrent is considered stalled. The actual threshold is `max(GB_downloaded, stalled_download_mins)` — so large downloads get more time automatically. Increase this for slow or low-seed torrents (e.g., public trackers) that need more time to complete. |
| `restrict_repair_to_cached` | bool | `false` | When true, zurg only uses torrents already cached on Real-Debrid for repairs. This means faster repairs (no waiting for downloads) but may fail if no cached alternative exists. When false, zurg can add uncached torrents that need time to download. |
| `only_full_torrent_repair` | bool | `false` | When true, repair reinserts the whole torrent with its original file selection or gives up. If that first step fails the torrent is marked broken immediately, skipping the archive and per-file strategies that would otherwise follow. |
| `check_for_changes_every_secs` | int | `15` | How frequently (in seconds) zurg polls Real-Debrid to detect library changes (new torrents, removed torrents, status changes). Lower values mean faster updates in your media server but more API calls. |
| `downloads_every_mins` | int | `720` | How often (in minutes) zurg re-fetches your RD downloads (unrestricted links, file locker links) and mounts them. These are non-torrent downloads from RD. |
| `delete_error_torrents` | bool | `false` | When true, automatically deletes torrents from RD that are in an error state (e.g., dead torrents that can't be downloaded). Keeps your RD library clean but means the torrent is permanently removed. |
| `on_library_update` | string | `""` | A shell command executed whenever zurg detects library changes. Each changed directory path is passed as an argument. Commonly used to trigger Plex/Jellyfin library scans on specific folders for faster updates. |

```yaml
enable_repair: true
repair_every_mins: 60
repair_timeout_mins: 30
stalled_download_mins: 10
restrict_repair_to_cached: false
only_full_torrent_repair: false
check_for_changes_every_secs: 15
downloads_every_mins: 720
delete_error_torrents: false
on_library_update: |
  for arg in "$@"
  do
      echo "detected update on: $arg"
  done
```

## 5. Network & Connectivity (Technical)

Infrastructure settings that control how zurg binds, authenticates, and connects to the network.

### Server Binding

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `host` | string | `"[::]"` | The network interface to bind to. `[::]` listens on all interfaces (IPv4 and IPv6). Use `0.0.0.0` for IPv4-only, or a specific IP to restrict access to one interface. |
| `port` | string | `"9999"` | The port zurg listens on. The `PORT` environment variable overrides this value when set, which is useful for containerized deployments. |

```yaml
host: "[::]"
port: 9999
```

### Warm connections

Opening a connection to a debrid service is expensive and using one is nearly free. Measured from a live host on 2026-08-29, a fresh connection to a Real-Debrid download host costs a TCP round trip and then 68–85 ms of TLS handshake before a byte of the file has been asked for — and zurg's HTTP transport opens nothing until a read wants it, dropping an unused connection again after 90 seconds. On anything but a busy library, the read that follows a quiet spell pays for that on the viewer's own path.

A warm floor moves it off that path: each account keeps a stated number of connections dialled and handshaken ahead of demand, so the transport has one in hand when a read arrives.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `warm_connections` | int | *(unset)* | The floor for every account that states none of its own. Unset leaves each backend its default — 1 per host for a debrid account, 2 per account for a news account. `-1` turns warming off everywhere. An account's own `warm_connections` always wins, including over a global `-1`. |

```yaml
warm_connections: 2        # every account keeps 2, unless it says otherwise

providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
    warm_connections: 4    # this one keeps 4 to each host it uses
  - type: torbox
    token: YOUR_TORBOX_API_KEY
    warm_connections: -1   # and this one keeps none
```

**How much this buys you depends on the host, and for the debrid services it is less than it sounds.** A connection that has sent nothing is the first thing these services reap, and they do it quickly. Timed from a live host on 2026-08-29, holding a silent connection open and waiting to be hung up on:

| Host | Silent connection | After serving a request |
|---|---|---|
| a Real-Debrid download host | closed after 30s | closed at once |
| `api.alldebrid.com` | closed after 15s | still open at 4 min |
| `api.torbox.app` | closed after 15s | still open at 4 min |
| `api.real-debrid.com` | closed after 4s | closed after 5s |

So a floor is worth keeping to a download host and not much else, and Real-Debrid's API cannot be warmed at all — no floor outruns a four-second hang-up without manufacturing traffic to keep the connection alive, which zurg will not do. Rather than assume, **the floor measures**: it retires its own connections at 15 seconds and checks whether each was still alive when it did. A host that keeps closing them before a read could use them is given up on, and its reads dial as they always did. Nothing has to be configured for that, and a floor going unread on a quiet library is not mistaken for it.

Two more things worth knowing before raising it:

- **A debrid account's floor is per host, a news account's is per account.** A debrid account is reached over many hosts — an API hostname, and a delivery host per link — and which ones is not knowable until a link has been minted, so the hosts kept warm are the ones the account has actually been using. At most 16 are kept at once, and one unused for 10 minutes is retired. A news account is one host, named in the config, and holds its session for as long as the plan allows — which is why its floor is the one that reliably pays off. See [Usenet](../guides/usenet.md).
- **Warm connections are real connections, and count against the per-host ceiling the provider polices** — 32 on Real-Debrid and AllDebrid, 20 on TorBox. That is why the debrid floor is capped at 4: a floor that size leaves the ceiling essentially intact, where a large one would spend it on sockets carrying nothing.

The floor is disabled when `proxy` is set, since an HTTP or SOCKS proxy makes zurg dial the proxy rather than the host, and there is nothing on the far side worth holding open.

### Authentication & Proxy

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `username` | string | `""` | HTTP basic auth username. When set along with `password`, all requests to zurg (dashboard, WebDAV, API) require authentication. Leave empty to disable auth. |
| `password` | string | `""` | HTTP basic auth password. Must be set together with `username`. |
| `proxy` | string | `""` | Route all of zurg's outbound network traffic through a proxy. Supports `http://`, `https://`, and `socks5://` protocols. Useful if your ISP blocks or throttles Real-Debrid traffic. Example: `socks5://user:pass@host:port`. The `PROXY` environment variable is used when this key is empty. |

```yaml
username: ""
password: ""
proxy: "http://[username:password@]host:port"
```

### Rclone Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rclone_enabled` | bool | `false` | When true, zurg manages an rclone mount automatically. This eliminates the need to run rclone separately — zurg starts, monitors, and restarts the rclone process as needed. The mount uses `mount_path` as the mount point. |
| `rclone_binary` | string | `"rclone"` | Path to the rclone executable. Only needed if rclone is not on your system PATH. |
| `rclone_extra_args` | list | `[]` | Additional command-line flags passed to the rclone mount command. Use this to override zurg's benchmark-optimized VFS defaults (see table below). Each entry is a single flag string. The RC settings and the `--union-*`/`--webdav-*` backend flags are refused: zurg constructs those itself, and a flag would outrank what it builds (`union_writable` would stop describing the mount). |
| `mount_read_only` | bool | `false` | When true, the mount is started with rclone's `--read-only`, so the kernel refuses a write before it ever reaches zurg. Nothing else gates a mount DELETE, so this is the only way to refuse one — though it does not cover clients talking to the WebDAV endpoint directly — and it additionally stops a stray write from landing in the mount's local union upstream. Override it per-flag with `rclone_extra_args: ["--read-only=false"]`. |
| `union_writable` | string | `"local"` | Which side of the embedded mount's union a created file is written to. `local`, the default, puts it straight onto the local upstream (`data/local`) without zurg seeing it. `server` lists the WebDAV upstream first, so the create arrives at zurg: refused outside `__magic__`, written as a size-capped sidecar inside it. A refused write never reaches the disk — rclone's VFS cache accepts it and retries the upload on a backoff, so it is bounded by the cache cap and visible in `logs/rclone.log`, where the local order would have put unbounded bytes in `data/local`. One caveat measured under `server`: renaming a sidecar file through the mount can answer an error (the file is visible on both upstreams, so rclone applies the move to each); release moves inside `__magic__` — the \*arr import path — are unaffected. Switching to `server` changes where *new* creates go and nothing else: whatever the local order already wrote to `data/local` stays until you delete it. The line zurg logs at startup names the live mode (`new files go to zurg over WebDAV (union_writable: server)`), so it is the thing to check rather than the presence of the `data/local` path, which is part of the union under either order. |

```yaml
rclone_enabled: false
rclone_binary: "rclone"
rclone_extra_args: []
mount_read_only: false
union_writable: "local"
```

#### Benchmark-Optimized Defaults

Zurg uses benchmark-tested rclone VFS settings optimized for streaming performance:

| Setting | Default | Why |
|---------|---------|-----|
| `--buffer-size` | 256M | Large buffer for smooth streaming |
| `--vfs-read-chunk-size` | 32M | How long a fresh read spends ramping. The first chunk is fetched at this size and doubles from there, so at 4M a read from a cold offset spent most of its life below line rate. A request size, not a forced transfer — rclone still stops pulling when the reader stops. |
| `--vfs-read-chunk-size-limit` | 512M | Where the doubling above stops. Chunking is on by default, so this is a ceiling the ramp reaches rather than something an override switches on. |
| `--vfs-read-ahead` | 128M | Balance between buffer and bandwidth efficiency |
| `--max-read-ahead` | 1M | Small FUSE kernel buffer reduces small reads. Not passed on Windows. |
| `--vfs-read-wait` | 5ms | Critical: higher values cause severe slowdowns |
| `--vfs-cache-mode` | full | Full caching for best performance |
| `--vfs-cache-max-size` | 256G | Hard cap on the on-disk VFS cache. Not a config key — override it with `rclone_extra_args`. |
| `--vfs-cache-min-free-space` | 10G | Stops caching before the cache disk fills |
| `--vfs-cache-max-age` | 72h | How long an untouched cached file is kept |
| `--vfs-cache-poll-interval` | 1m | Responsive cache updates |
| `--vfs-fast-fingerprint` | on | Identifies files without hashing them |
| `--dir-cache-time` | 12h | Listings hold for hours; zurg forgets affected entries over the RC API when the library changes, so media-server scans stay warm |
| `--attr-timeout` | 60s | Library files are immutable, and state changes forget the affected entries explicitly. Bounded so a stale size can't outlive a scan pass. |
| `--poll-interval` | 0 | Change polling is zurg's job, not rclone's |
| `--timeout` | 5m | IO idle timeout |
| `--no-modtime` / `--no-checksum` | on | Neither is meaningful for a debrid library, and asking for them costs requests |
| `--async-read` | rclone default (on), not passed | Zurg does not put this flag on the command line, and rclone defaults it to true — so the mount reads asynchronously, and every figure on this page was measured that way. A tuning field once claimed to disable it; all it gated was appending the bare flag, which sets the default it already had. To actually turn it off: `rclone_extra_args: ["--async-read=false"]`. |
| `--low-level-retries` | 3 | rclone's VFS downloader already restarts a failed read ten times per open, and each restart is retried by the backend pacer this many times. At rclone's default of 10 that is 100 requests for one open of a file zurg is answering 503 deliberately. |
| `--retries` | 1 | Whole-command budget; for a mount that never exits it only multiplies a startup failure |
| `--log-level` | NOTICE | rclone's own verbosity, always passed |
| `--cache-dir` | `data/rclone-cache` | Resolved against the working directory |
| `--log-file` | `logs/rclone.log` | Resolved against the working directory |

`--vfs-cache-max-size`, `--vfs-cache-min-free-space`, `--low-level-retries`, `--retries`, `--log-level`, `--cache-dir` and `--log-file` are constants in `internal/rclone/manager.go`; every other row comes from `tuneVFSOptions` in `internal/rclone/tuning.go` — `--vfs-cache-max-age` and `--vfs-cache-poll-interval` included, despite the names.

Four more are added by platform, all of them on Linux: `--allow-other` and `--allow-non-empty` always, `--uid` and `--gid` only when the running user's ids can be read. `--max-read-ahead` is passed everywhere except Windows, and `--read-only` whenever [`mount_read_only`](#rclone-settings) is set.

The buffer and read-wait values were determined through benchmarking on a 600 Mbps connection, achieving ~533 Mbps cold-cache throughput and ~235ms TTFB. The read chunk size was re-measured later on a ~70 MB/s host: paired and interleaved, median throughput went 49.1 -> 56.5 MB/s on Real-Debrid moving it from 4M to 32M, and moved the same way on TorBox.

**Override defaults** using `rclone_extra_args`:
```yaml
rclone_extra_args:
  - "--buffer-size=128M"        # Use less memory
  - "--vfs-read-chunk-size=2M"  # Smaller chunks
```

RC flags (`--rc`, `--rc-addr`, and anything else starting with `rc-`) are rejected: zurg runs rclone's remote control itself to invalidate the VFS cache when the library changes.

### User Agent & Network

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `user_agent` | string | Chrome UA | The HTTP User-Agent header sent with all requests to Real-Debrid. The default mimics a standard Chrome browser. Change this only if RD is blocking your requests or you have a specific reason. |
| `force_ipv6` | bool | `false` | Forces all of zurg's network tests and host selection to use IPv6. Enable this if your network has better IPv6 connectivity to RD servers (e.g., some ISPs throttle IPv4 but not IPv6). |
| `unrestrict_ip` | string | `""` | The IP address to pass to RD when unrestricting download links. Useful in multi-network setups where you want downloads to be generated for a specific IP (e.g., a VPN exit IP) rather than the IP zurg is running on. |
| `dns_servers` | list | `[]` (system DNS) | Custom DNS servers for resolving RD hostnames. Useful if your system DNS is slow, unreliable, or blocked by your ISP. Leave empty to use the system resolver. Must include the port (e.g., `1.1.1.1:53`). |
| `network_test_every_mins` | int | `1440` | How often (in minutes) zurg re-runs the network latency test to find the fastest RD download servers. Cannot be disabled — values `<= 0` are treated as `1440`. Results are cached to `data/network_test_results.json` and `data/network_test_timestamp`; on restart, if the cache is fresh enough the network test is skipped. |

```yaml
user_agent: "Mozilla/5.0 ..."
force_ipv6: false
unrestrict_ip: ""
network_test_every_mins: 1440
dns_servers:
  - "1.1.1.1:53"   # Cloudflare
  - "8.8.8.8:53"   # Google
```

### Public NZB sharing

An NZB share is a URL a recipient fetches — so it only helps if they can reach this host, which a zurg behind a home NAT cannot promise. These two keys route that URL through a [zrok](https://zrok.io) service instead: zurg dials the service outbound and serves the share through the connection, so **no local port opens** and nothing new answers on this host. What the tunnel carries is only the two token-gated share routes, never the dashboard and never the library.

Both empty, and with no enabled environment under `data/zrok`, sharing stays on the network this host is already on, dialing nowhere — that is the default. Note the second half of that: once an environment *has* been enabled, an empty `zrok_account_token` no longer means local-only, because the enable is what turns sharing on and it persists. Turning public sharing back off means removing `data/zrok`.

Building, serving and revoking shares work the same either way — the share token in the path is the authorization on the local URL and the public one alike.

The public URL survives a restart: the service-side share is looked up and re-attached to rather than created again. What it does not survive is enabling again — a new environment gets a new share, and URLs handed out under the old one stop resolving. That happens when you remove `data/zrok`, and also if the identity saved in there goes missing or unreadable, since enabling again is the only way back from that.

Removing `data/zrok` by hand also leaves that environment, and the share under it, registered on the zrok account — the identity that could have released them is what you just deleted, so tidy them from the zrok console if the clutter matters. It is not a way to switch sharing off in place, either: a running zurg holds the connection it is already serving on, so the old URL keeps working until the process restarts. zurg releases an environment itself whenever it replaces one, and refuses to replace one it could not reach the service to release — or one whose files it finds on disk but cannot read, since enabling over that would abandon a live environment on every restart.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `zrok_account_token` | string | `""` | The zrok enable token that turns public sharing on. Free from [myzrok.io](https://myzrok.io) for the hosted service; from your own controller if you self-host. Needed for the **first enable only**: enabling redeems it once and saves it, with the environment identity, under `data/zrok`, and every later call authenticates off that saved copy — so the key can come back out of `config.yml` afterwards and public sharing still comes up on the next restart. Note what that means for the secret: taking the key out of the config does not take the token off the host. Two reasons to leave it in anyway: an enable that *failed* — a refused token, a service that could not be reached — is not a completed one, and the retry needs the key; and any later *re*-enable needs it too, so an instance that has had it removed and then loses the identity under `data/zrok` cannot recover on its own. A rotated token is picked up from here and applied to the saved environment, identity and public URL intact. |
| `zrok_api_endpoint` | string | `""` | The zrok service to talk to, for self-hosted deployments; empty keeps the SDK's default, `https://api-v2.zrok.io` (the hosted service). Read **at enable time only** — once `data/zrok` holds an enabled environment, the endpoint saved there wins, so pointing an already-enabled zurg at a different service means deleting `data/zrok` and enabling again. The identity belongs to whichever service issued it, so that is the honest way round anyway. It does not replace `zrok_account_token`: the first enable still needs a token from the service this names. The SDK's own `ZROK2_API_ENDPOINT` environment variable outranks this key at that same moment. |

Reachability cuts two different ways for a self-hosted service, and only one of them is yours: **this zurg** reaches the controller API — a tailnet address is enough for that — while **your recipients** reach the service's frontend. A service reachable only on your own tailnet therefore hands out share URLs only your own tailnet can open.

Two more things a self-hosted service has to line up with. The share URL is the one the service advertises for its frontend, and a bare host with no scheme is assumed to be `https` — so a frontend serving plain HTTP wants TLS in front of it, or an advertised URL that carries its own scheme and port. And the share is created in the namespace the zrok SDK resolves, which is `public` unless the SDK's own `ZROK2_DEFAULT_NAMESPACE` says otherwise; zurg pins neither, so a service whose namespace is named something else is told through that variable.

```yaml
zrok_account_token: ""   # the enable token, needed for the first enable only
zrok_api_endpoint: ""    # self-hosted only; empty = the hosted service
```

## 6. Performance & Tuning (Advanced)

These settings are rarely touched unless debugging or optimizing for your specific network conditions.

### CDN & Host Selection

> **Related:** The network latency test that determines the fastest hosts runs periodically based on [`network_test_every_mins`](#user-agent--network) (default: every 1440 minutes / 24 hours).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rd_cdn_host_preference` | string | `"auto"` | Controls which RD download servers zurg prefers. `auto` uses whatever RD provides. `force_cloudflare` rewrites the host to its `.cloud` twin, which reaches the same machine through Cloudflare — useful where the direct IPs are blocked. `force_numbered` uses RD's numbered hosts directly. `force_location_<location>` (e.g. `force_location_syd`, `force_location_fra`) routes through a specific country's servers. |
| `cdn_host_preference` | string | — | Legacy alias for `rd_cdn_host_preference`, kept for compatibility and Real-Debrid only. If both are set, the explicit one wins. |
| `tb_cdn_host_preference` | string | `"auto"` | TorBox CDN region. `auto` leaves TorBox's own choice alone; `force_location_<region>` serves downloads from that region. Only regions currently advertising a delivery node can be forced, and the dashboard's select lists exactly those. No fallback to the legacy key — its values are Real-Debrid location codes and mean nothing here. |
| `number_of_hosts` | int | `0` (all) | Limits zurg to the N fastest download hosts. After speed-testing available hosts, zurg only uses the top N. Set to `0` to use all available hosts. A value like `3` reduces connection spreading but ensures you always use the fastest servers. |

```yaml
rd_cdn_host_preference: "auto"
tb_cdn_host_preference: "auto"
number_of_hosts: 3
```

> **`force_cloudflare` and `force_location_*` are mutually exclusive.** RD publishes a `.cloud` twin for its numbered hosts only — measured 2026-08-09, all 25 numbered subdomains have one and none of the 22 country-specific ones do. So an account with Cloudflare enabled in its RD account settings is always handed a numbered host, and no location preference can be honoured for it. Zurg detects this from the link it unrestricts at startup, skips the geo probing that cannot succeed, and logs why if a location is configured anyway.

> **Note on `force_location_*` verification:** When using a geo-location preference like `force_location_nyk`, the RD `/rest/1.0/downloads` API endpoint normalizes download URLs to numbered servers (e.g., `128-4.download.real-debrid.com`) even though the actual unrestrict response returned a geo server (e.g., `nyk7-4.download.real-debrid.com`). The download code itself embeds the numbered server (e.g., code `...4128` maps to server `128-4`). To verify that geo routing is working, check zurg's logs or the raw unrestrict response — do **not** rely on the RD downloads API.

### Rate Limits

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_rate_limit_per_minute` | int | `250` | Maximum RD API calls per minute for general operations (everything except torrent listing). RD enforces its own limits; this prevents zurg from hitting them and getting temporarily blocked. Increase only if you're confident your RD plan allows it. |
| `torrents_rate_limit_per_minute` | int | `75` | Maximum RD API calls per minute specifically for the `/torrents` endpoint used to fetch your torrent list. This is separated because torrent listing is the most frequent API call and has its own rate dynamics. |
| `fetch_torrents_page_size` | int | `5000` | How many torrents to fetch per page when syncing your RD library. Larger values mean fewer API calls but larger responses. If you have a very large library (10,000+ torrents), a higher value reduces sync time. |

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

### Link Verification

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `use_range_verification` | bool | `false` | Controls how zurg verifies that download links are still valid. When false, zurg uses a `HEAD` request (lightweight, no data transferred). When true, uses a `Range` header (`GET bytes=0-0`) which downloads just 1 byte. Enable this if your network or RD servers don't respond correctly to HEAD requests, causing false link failures. |

```yaml
use_range_verification: false
```

### Timeouts & Retries

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `api_timeout_secs` | int | `60` | Maximum seconds to wait for any RD API call to respond. Increase if you're on a slow connection and API calls are timing out. |
| `download_timeout_secs` | int | `15` | Maximum seconds to wait when testing download links (used during host speed tests and link verification). Not the timeout for actual file downloads. |
| `retries_until_failed` | int | `2` | How many times to retry a failed API call before giving up and marking it as failed. Higher values add resilience against transient RD outages but slow down failure detection. |
| `retry_503_errors` | bool | `false` | When true, retries requests that get a 503 (Service Unavailable) response from RD. RD returns 503 during maintenance or overload. Enable this if you experience frequent 503 errors that resolve themselves quickly. |

```yaml
api_timeout_secs: 60
download_timeout_secs: 15
retries_until_failed: 2
retry_503_errors: false
```

### Downloads & Debugging

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `get_downloads_limit` | int | `-1` | Maximum number of RD download entries (non-torrent) to fetch. `-1` is no limit (fetch all), `0` skips fetching downloads entirely, and a positive number caps it. Useful if you use RD's direct link unrestricting feature and want those files visible in zurg. Leaving the key out means `-1`; an explicit `0` is honoured as "cache none" and logs a warning at startup, because that is usually a config written before `0` changed meaning. |
| `load_dumped_torrents` | bool | `false` | When true, loads torrent data from the `dump/` folder on startup. This is a recovery mechanism — if zurg has previously dumped torrent state (e.g., during a crash), enabling this restores that state without re-fetching everything from RD. |
| `log_requests` | bool | `false` | When true, logs detailed statistics for every download request (file path, response time, bytes served). Useful for debugging streaming issues or understanding access patterns. Generates significant log volume — disable in production. |
| `log_level` | string | `DEBUG` | How much detail to log: `DEBUG`, `INFO`, `WARN`, `ERROR` or `FATAL`. Changing it from the dashboard takes effect immediately — no restart, and it re-levels every component at once. It overrides the `LOG_LEVEL` environment variable, so the dashboard control still works on a container that bakes one in; leave the key out to hand the choice back to `LOG_LEVEL`. A value that names no level is ignored with a warning at startup rather than being fatal. |

```yaml
get_downloads_limit: -1
load_dumped_torrents: false
log_requests: false
log_level: DEBUG
```

## 7. Directories & Filters

Define virtual directories that organize your torrents based on flexible filter rules. Each directory appears as a folder in your mount and shows only the torrents matching its filters.

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true

  # ... (see config.example.yml for full examples)
```

### Directory options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `group` | string | the directory's own name | Directories sharing a group compete for each torrent: it lands in the first one whose filters match and no other in that group. Directories in different groups each get their own copy. |
| `group_order` | int | `0` (treated as `1`) | Priority within the group — lower goes first. Ties are broken by directory name. |
| `filters` | list | `[]` | The rules deciding what belongs here. A torrent matches the directory if **any** entry in the list matches. An empty or absent list matches every torrent. |
| `only_show_the_biggest_file` | bool | `false` | Show only the largest file of each torrent, hiding samples, extras and companion files. |
| `only_show_files_with_size_lte` | int | `0` (off) | Hide files larger than this many bytes. |
| `only_show_files_with_size_gte` | int | `0` (off) | Hide files smaller than this many bytes. |

A file explicitly forced visible in zurg ignores all three visibility options.

### Filter conditions

| Condition | Type | Description |
|-----------|------|-------------|
| `id` | string | The torrent's ID. Decisive: nothing else in the same entry is considered. |
| `regex` | string | Torrent name matches the pattern. |
| `not_regex` | string | Torrent name does not match the pattern. |
| `contains` | string | Torrent name contains the text (case-insensitive). |
| `contains_strict` | string | Torrent name contains the text (case-sensitive). |
| `not_contains` | string | Torrent name does not contain the text (case-insensitive). |
| `not_contains_strict` | string | Torrent name does not contain the text (case-sensitive). |
| `size_gte` | int | Total torrent size is at least this many bytes. |
| `size_lte` | int | Total torrent size is at most this many bytes. |
| `any_file_inside_regex` | string | Some file in the torrent matches the pattern. |
| `any_file_inside_not_regex` | string | Some file in the torrent does not match the pattern. |
| `any_file_inside_contains` | string | Some file contains the text (case-insensitive). |
| `any_file_inside_contains_strict` | string | Some file contains the text (case-sensitive). |
| `any_file_inside_not_contains` | string | Some file does not contain the text (case-insensitive). |
| `any_file_inside_not_contains_strict` | string | Some file does not contain the text (case-sensitive). |
| `any_file_inside_size_gte` | int | Some file is at least this many bytes. |
| `any_file_inside_size_lte` | int | Some file is at most this many bytes. |
| `added_within_hours` | int | The torrent was added within this many hours. |
| `added_within_days` | int | The torrent was added within this many days. |
| `added_after` | string | The torrent was added on or after this date. Format `YYYY-MM-DD` or `YYYY-MM-DD HH:MM`. |
| `added_before` | string | The torrent was added before this date, same formats. When paired with `added_after`, both must hold. |
| `has_episodes` | bool | Episode detection: season/episode markers or CRC hashes in the torrent or file names, or a run of numbered files. A torrent whose largest file is at least 5x the second-largest is read as a movie with extras and rejected. |
| `is_music` | bool | Some file ends in `.m3u`, `.mp3`, `.flac`, `.m4a` or `.m4b`. |
| `has_tag` | string | The torrent carries this tag. Acts as a gate: without it, nothing else in the entry can match. |
| `not_has_tag` | string | The torrent does not carry this tag, and gates the same way. |
| `tags_match_all` | list | Every listed tag is present (case-insensitive). |
| `tags_match_any` | list | At least one listed tag is present. |
| `tags_missing_all` | list | None of the listed tags is present. |
| `tags_missing_any` | list | At least one listed tag is absent. |
| `provider` | string | The release is held by this account, named by its `name` in the providers block. A gate, not a match: combined with another condition it means both must hold. On its own it puts the whole account in the directory. |
| `not_provider` | string | No account holding the release is this one. Gates the same way. |
| `and` | list | Every nested condition must match. |
| `or` | list | At least one nested condition must match. |

Tags come from media analysis — see [tags.md](tags.md) for the full list.

Patterns are written `/expression/flags`, where the flags are any of `i` (case-insensitive), `m` (multi-line), `s` (dot matches newline) and `x` (extended). A value with no slashes is compiled as a bare Go regular expression.

Conditions within one filter entry are **not** ANDed by default — most of them match the entry as soon as one of them holds. Use an explicit `and:` block when you mean all of them:

```yaml
directories:
  anime:
    group: media
    group_order: 10
    filters:
      - and:
          - has_episodes: true
          - any_file_inside_regex: /^\[/
          - not_regex: /\[One Pace\]/
```

### Per-account directories

Alongside `__all__`, every configured account gets a directory of its own, named after it — `__realdebrid__`, `__torbox__`, `__alldebrid__`, `__nzb__`. They are not configured; they appear because the account exists, and disappear when it is removed.

Each one holds whatever that account holds, and — unlike a filtered directory — it also decides where reads go. A release held by two accounts is one entry in the library, so without this every copy of it would stream from whichever account sorts first in the `providers` block:

```
__realdebrid__/Some.Release/movie.mkv   → streamed from Real-Debrid
__torbox__/Some.Release/movie.mkv       → streamed from TorBox
```

The pin excludes the other accounts rather than merely preferring the named one. There is no silent failover: if TorBox cannot serve the file, the read under `__torbox__` fails instead of quietly answering with Real-Debrid's bytes. Reads elsewhere in the mount are unaffected and still fail over normally.

Two consequences follow from accounts not holding identical content:

- A directory lists only the files its account actually holds. If TorBox downloaded part of a release Real-Debrid has whole, `__torbox__` shows the part.
- Brokenness is judged per account. A file dead on Real-Debrid but healthy on TorBox is a 404 under `__realdebrid__` and plays under `__torbox__`, while the rest of the mount still serves it.

The directory is named after the account's `name`, which defaults to its `type`. Two accounts on one service need distinct names (`rd-main`, `rd-backup`) and get a directory each. The Usenet backend is `nzb` by default, so it appears as `__nzb__`; set `name: usenet` on that provider entry if you would rather browse `__usenet__`.

Because the same release appears under every account holding it as well as in your filtered directories, point a media server at one part of the mount rather than all of it, or it will scan the same content several times.

An account named after a directory zurg already uses (`all`, `unplayable`, `dump`, `downloads`) gets no per-account directory, and zurg logs a warning at startup rather than taking the existing one over.
