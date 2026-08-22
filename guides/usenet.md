---
label: Usenet
icon: broadcast
order: 90
---

# Usenet with zurg

zurg's `nzb` backend turns a directory of `.nzb` files into a mounted library. There is no downloader, no completed folder, and nothing on disk but the NZB files themselves: when a player seeks into a file, zurg fetches exactly the articles covering those bytes, yEnc-decodes them in memory, and answers the ranged read. A 60 GB remux costs 60 GB of disk nowhere.

It is a debrid backend as far as the rest of zurg is concerned — the same library model, the same directory filters, the same mount, the same media-server integration — so a Usenet release sits alongside your Real-Debrid or TorBox content in one tree. It can also be the only account you configure; no debrid service is required.

**Several Usenet providers are supported.** One `nzb` entry carries any number of news accounts — unlimited providers, block accounts, whatever you hold — and zurg falls back through them article by article. That matters more here than redundancy usually does: retention is per-provider, so a second account is very often the difference between one extra fetch and rebuilding a whole release from PAR2. See [More than one Usenet provider](#more-than-one-usenet-provider).

This guide goes end to end: news accounts, NZBs, the mount, Plex.

| | |
|---|---|
| Config reference | [config.md → Usenet accounts](../reference/config.md#usenet-accounts) |
| Dashboard | `http://localhost:9999/config/` → Essentials → Providers |
| Where the code lives | `internal/nzb` (backend), `internal/nntp` (news client), `internal/par2` (repair math) |
| Watch directory | `nzbs/`, beside the zurg binary |
| Repair cache | `data/par2/` |

---

## What you need

- **At least one Usenet provider account.** Retention is what matters most — a 4000+ day provider will still have posts a 1000-day one has aged out. Your plan's *connection allowance* is the second number to know; it is what zurg reads at.
- **More accounts, if you have them.** A second unlimited provider on a different backbone, or a cheap block account for the gaps, is the highest-value thing you can add to a Usenet setup — see [More than one Usenet provider](#more-than-one-usenet-provider).
- **NZB files.** zurg does not search indexers. Download them from your indexer and drop them into `nzbs/` — or turn on the [SABnzbd-compatible endpoint](sabnzbd.md) and let Sonarr and Radarr hand them over, which writes into the same directory. The endpoint is opt-in and Usenet-only; there is no torrent equivalent.
- **zurg**, plus `rclone` if you want a filesystem mount rather than WebDAV directly. zurg downloads rclone for you on first run.

---

## 1. Configure your news accounts

Each account in zurg is one entry under `providers:`. A Usenet one authenticates with server credentials instead of an API token, so it carries an `nntp` block instead of `token`:

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 30        # your plan's allowance — see below
      cache_size_mb: 512     # decoded articles held in memory, across all files
```

That is the whole of it. Add debrid accounts beside it if you have them:

```yaml
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: nzb
    nntp:
      host: news.example.com
      ...
```

| Key | Default | Notes |
|---|---|---|
| `host` | *(required)* | The news server. A missing or empty host is a startup error. |
| `port` | `563` with TLS, `119` without | |
| `tls` | `false` | Turn it on. Plaintext NNTP sends your password in the clear and your reads to anyone on the path. |
| `username` / `password` | `""` | |
| `connections` | `8` | **Set this to your plan's real allowance.** It is not a rate limit to be polite about: a single connection carries a fraction of a provider's throughput, so zurg reads at this number. Too low and streaming is slow; over the plan's limit and the server starts refusing connections. |
| `cache_size_mb` | `512` | Decoded article data held in memory, shared across every file being read rather than per file. |
| `servers` | `[]` | Further news accounts — see [More than one Usenet provider](#more-than-one-usenet-provider). |

Two rules the config validator enforces:

- **Only one enabled `nzb` provider entry.** Two would each scan the same `nzbs/` directory and duplicate every release. This is not a limit on how many *Usenet providers* you can use — extra news accounts go under that one entry's `nntp.servers`, where they serve the same library instead of a second copy of it.
- **`watchlist: true` cannot target it.** The Usenet backend cannot add content, so it can never be the account a Plex watchlist addition lands in.

### More than one Usenet provider

Retention is per-provider, and the difference between one extra fetch and a full-release PAR2 rebuild is whether some other account still has the article. That is why a second account is worth more here than redundancy usually is.

The keys already in the `nntp` block describe the first account. Anything under `servers` is another one, asked only when the accounts before it did not have the article. An existing single-account config keeps working untouched:

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com          # first account: the workhorse
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com   # different backbone = different retention
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com              # metered — only for what the others lack
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

Each account keeps its own connection allowance, and reads are driven at the **combined allowance of the non-backup accounts** — 30 + 20 = 50 in the example above. A second unlimited provider therefore buys throughput as well as retention insurance; a `backup` account buys neither, by design, since it only ever carries what the primaries could not supply and counting it would widen every read-ahead window for capacity steady-state playback never touches.

Three keys shape who gets asked:

| Key | Default | Effect |
|---|---|---|
| `name` | value of `host` | Labels the account in logs. |
| `priority` | `0` | Who is asked first, lowest first. Accounts sharing a priority are asked in written order, except that one with a free connection is preferred over one whose allowance is spent — so two equal accounts share the load rather than queueing on one. |
| `backup` | `false` | Marks a metered block account, consulted only once every primary has answered *no such article*. A primary being merely **busy** is not enough: zurg waits for it rather than spending metered bytes on something an unlimited account would have served. |
| `backbone` | `""` | Names the article spool an account resolves to. Two accounts on one backbone hold the same articles, so once one has said it lacks an article the others on that spool are skipped instead of being charged a round trip for the same answer. |

Reselling is rife, so `backbone` is worth filling in: two accounts you bought from different companies may sit on the same spool, and without it every miss is asked twice. Group them by whatever name you like — the string is only compared against other entries.

At startup zurg names every account it will use:

```
Usenet account nzb connected: nntps://unlimited.example.com:563 (30 connections) + nntps://second-unlimited.example.com:563 (20 connections) [usenetexpress] + nntps://block.example.com:563 (10 connections) [backup] [omicron]
```

The census that decides whether a release needs repairing asks every account before calling an article missing, and asks each one only about what its predecessors lacked. A transport failure is never mistaken for an aged-out article: if any account failed to answer *at all*, that failure is what gets reported, so a timeout never causes silence to be served and a repair to be scheduled for something that was never gone.

### Configuring providers in the Dashboard

`http://localhost:9999/config/` → **Essentials** → **Providers** does the same thing without editing YAML. The table lists every account in config order:

```
#  Name        Type        Token                Flags
1  realdebrid  realdebrid  …DFFND4OA            —          [Edit] [Delete]
2  nzb         nzb         news.example.com     —          [Edit] [Delete]
```

For an `nzb` row the Token column shows the **news server host** instead of a token hint — there is no token to redact.

**To add a Usenet account:**

1. Click **Add provider**.
2. Set **Type** to `nzb`. The token fields disappear and the NNTP fields appear in their place.
3. Leave **Name** empty unless you want something other than `nzb` — it is what the per-account directory is called, so `usenet` here gives you `__usenet__` in the mount.
4. Fill in **NNTP host**, **Port**, **TLS** (checked by default — leave it on), **Username**, **Password**, **Connections** (placeholder `8`; put your plan's real allowance here) and **Cache size MB** (placeholder `512`).
5. Leave **Watchlist target** unchecked — the backend cannot add content and saving it checked is rejected. **Disabled** keeps the entry in `config.yml` without loading it.
6. **Save**.

The form is validated as if the edit had been applied, so mistakes come back as an alert rather than a broken config. Adding a **second** `nzb` provider is refused there — the error points you at `nntp.servers`, which is where further news accounts belong.

**To edit one**, click **Edit** on its row. The form loads everything except the password, which stays blank and means *keep the existing one* — type a new password only to change it.

**Delete** asks to confirm, then removes the provider entry from `config.yml`. It does not touch your `nzbs/` directory — the NZB files stay where they are and come back with the provider. The last enabled provider can be neither deleted nor disabled.

Every change here writes straight to `config.yml` and shows:

> Provider changes saved to config.yml — restart zurg to apply

Provider edits are **not** hot-reloaded. Restart zurg before expecting anything to change.

> **The Dashboard cannot see `nntp.servers`.** The form has fields for one news account, and saving an `nzb` provider rewrites its whole `nntp` block from those fields — so the extra accounts are written out of the config. If you run more than one Usenet provider, keep them in `config.yml` and use the Dashboard's other sections rather than this provider's Edit button.

---

## 2. Start zurg and confirm the accounts

```bash
./zurg
```

zurg verifies the news accounts once at startup, because a wrong password otherwise shows up much later as every file failing to play:

```
Usenet account nzb connected: nntps://news.example.com:563 (30 connections)
```

A total failure is just as loud:

```
Cannot reach the news server for nzb: <reason>
```

Check the port and TLS pairing first (`563`+`tls: true`, or `119`+`tls: false`), then the credentials, then whether the plan is actually active.

**With several accounts, read the warnings, not just the connected line.** Each unreachable account gets one of its own, and startup carries on as long as *one* account answers — the error above appears only when every account is unreachable. So a dead second provider looks like a healthy start unless you notice:

```
Usenet account block.example.com is not reachable: <reason>
```

---

## 3. Add NZB files

Create the watch directory beside the zurg binary — **zurg does not create it for you**, and a missing one simply yields an empty library:

```bash
mkdir -p nzbs
cp ~/Downloads/Some.Release.2024.2160p.nzb nzbs/
```

Within about 15 seconds zurg re-reads the directory, and within roughly 30 the library refresh notices the new count and files it into your directories. The log says what it read:

```
Loaded NZB Some.Release.2024.2160p.nzb: 94 files
```

### What gets picked up

- Files **directly inside `nzbs/`** whose name ends in `.nzb`, case-insensitively.
- **Subdirectories are skipped.** `nzbs/movies/foo.nzb` is invisible. Flatten instead of organising — the library's organisation comes from directory filters, not from this folder.
- **Plain XML only.** `.nzb.gz` is not unpacked and not read; decompress it first.
- A file that fails to parse is skipped with a warning and does not stop the scan.

### What the release is called

The name zurg shows — and therefore the folder Plex sees — is:

1. the NZB's own `<meta type="name">` value, if it has one and it survives sanitising, otherwise
2. **the filename with `.nzb` stripped**.

So most of the time, *the NZB's filename is the release name*. Name the file the way you would name the release, because that is what your media server will try to match:

```bash
# good
nzbs/Some.Movie.2024.2160p.UHD.BluRay.x265-GROUP.nzb

# bad — Plex has nothing to work with
nzbs/nzbgeek_download_48213.nzb
```

Two different releases that end up with the same name are told apart by a short hash tag (`Some.Release {a1b2c3}`), the same as anywhere else in zurg.

### Password-protected releases

If the indexer recorded the archive password in the NZB's metadata block, zurg uses it when streaming out of the RAR set:

```xml
<head>
  <meta type="password">thepassword</meta>
</head>
```

Nothing else is needed. A protected release whose NZB carries no password meta cannot be opened.

### Obfuscated releases

Posts whose filenames are random are handled, at a cost paid once at scan time. zurg tries the cheap source first — the filename an article still declares in its own yEnc header, one article per file — and falls back to the release's PAR2 index, which records each file's true name against the MD5 of its first 16 KiB. That first article also states the file's exact length, which is kept, so an obfuscated release is sized by the same articles that name it. It logs what it recovered:

```
Recovered 27 filename(s) in Some.Release
```

The whole naming pass is bounded at 90 seconds per NZB, so an unreachable server delays a scan rather than hanging it. Names are settled *before* the library is built from them, because the library keys files by name and a later rename would lose them.

**A fully obfuscated post has no real name to recover.** Some posters obfuscate before building the recovery set, so the PAR2 index restores names that are themselves random (`aJPSgA7eYizyzjJXT.part01.rar`), and the file inside the archive is a hash too. Nothing in the post knows what the release is — only the NZB's own name does. So zurg presents the payload under the release name, the same thing SABnzbd does at the end of unpacking:

```
Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR/
└── Ugliest.House.in.America.S08E02.720p.AMZN.WEB-DL-RAWR.mkv
```

Only the file that is clearly the release is renamed: the biggest entry in the archive, and only when it is at least three times the size of the next one, its extension is not part of a disc structure (`.vob`, `.m2ts`, `.mpls`), and its name says nothing. Subtitles and samples sharing its name follow it. An archive holding several files of a similar size — a season pack — is left alone, because no one of them is the release. The archive's own names keep working as addresses, so a player that started before a rescan does not lose the file.

### Replacing and removing

- **Removing** an NZB from `nzbs/` removes the release from the library, drops its cached reader and article cache, and forgets any repaired bytes it held.
- **Deleting a Usenet release from the Dashboard deletes the `.nzb` file from disk.** There is nowhere else for it to live. This is not the same as deleting a torrent from a debrid account, where the file stays on the service.
- **Replacing an NZB in place is the one thing to avoid.** zurg notices library changes by counting releases and checking the first one's id; swapping a file's contents while keeping its name changes neither, so the swap may go unseen until something else changes. Remove the old file, let zurg pick up the removal, then add the new one — or restart.

---

## 4. Where releases land in the mount

A Usenet release is an ordinary library entry, so your existing `directories:` filters apply to it unchanged:

```yaml
directories:
  shows:
    group: media
    group_order: 20
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 30
    only_show_the_biggest_file: true
    filters:
      - any_file_inside_not_regex: /\.(mp3|flac|m4b)$/i
```

Alongside those, the account gets a directory of its own — `__nzb__` by default, or `__<name>__` if you set `name:` on the provider entry. That directory is not just a view: reads under it are **pinned** to the Usenet account with no failover, which makes it the right place to test whether Usenet playback works without a debrid account quietly answering instead.

Four Usenet-specific things to know when writing filters:

- **Tag filters will not match Usenet content.** Every `zurg_*` tag (resolution, HDR, bitrate, duration, language) comes from ffprobe, and ffprobe is an external binary handed a URL — a link zurg assembles itself is not something it can open, so analysis is skipped for this backend entirely. Filter Usenet content on names, file extensions, sizes and `has_episodes` instead. A directory keyed on `tags_match_any` will simply never contain a Usenet release.
- **`.par2` and `.sfv` files are hidden.** They are repair scaffolding; zurg reads them itself and no media server has any use for eight of them per season pack. `.nfo` is kept, because Kodi, Emby and Jellyfin read it.
- **RAR sets are content, not archives to unpack.** `.rar` and `.rNN` stay visible and a volume set appears in the mount as a *folder* whose contents are the files inside it — zurg streams video straight out of the archive without extracting anything. A release that is *only* one volume set stands in for its own contents instead, with no archive folder in between: the payload sits directly in the release folder, which is where a media server looks for it. Files posted beside the set — the `.nfo`, the poster's `.txt`, artwork, subtitles — stay listed there too.
- **`force_select_playable_files` does not apply.** A Usenet post is whole; there is nothing to select. Every content file is already offered.

Browse the result before involving a media server. `http://localhost:9999/http/` is a plain HTML index of exactly what the mount will show:

```bash
curl -s http://localhost:9999/http/__nzb__/ | head
```

---

## 5. Mount it with rclone

### The easy path: let zurg run rclone

```yaml
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run
mount_path: "/mnt/zurg"        # /Volumes/Zurg on macOS, Z: on Windows
```

zurg starts rclone with a VFS profile already tuned for its own read pattern (buffer size, chunk sizing, cache mode, dir-cache time, timeouts), keeps the mount alive, and invalidates the right dircache entries when the library changes. `mount_path` is also the prefix zurg uses when telling Plex which paths to scan, so it must be set even if you mount elsewhere.

Verify:

```bash
ls /mnt/zurg/
ls /mnt/zurg/__nzb__/
```

### The manual path: your own rclone

If you already manage rclone, point a WebDAV remote at zurg:

```ini
[zurg]
type = webdav
url = http://localhost:9999/dav/
vendor = other
pacer_min_sleep = 0
```

```bash
rclone mount zurg: /mnt/zurg --config rclone.conf --dir-cache-time 10s
```

Still set `mount_path` in `config.yml` to wherever you mounted it, or media-server scan notifications are built from the wrong prefix.

### Docker

zurg's working directory in the image is `/app`, so the watch directory is `/app/nzbs` and the repair cache is `/app/data`. Bind-mount both if you want them to survive the container:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:latest
    volumes:
      - ./config.yml:/app/config.yml
      - ./nzbs:/app/nzbs
      - ./data:/app/data
    ports:
      - 9999:9999
```

Dropping an NZB into `./nzbs` on the host is then picked up inside the container without a restart.

---

## 6. Point Plex at it

Nothing here is Usenet-specific except the last subsection, but the order matters.

1. **Give zurg your Plex credentials**, so it can ask Plex to scan just the paths that changed instead of leaving you to wait for a periodic full scan. Easiest through the Dashboard's Plex auth flow, which writes the values back into `config.yml`:

   ```yaml
   plex_server_url: "http://localhost:32400"
   plex_token: YOUR_PLEX_TOKEN
   ```

2. **Add libraries pointing at subdirectories of the mount**, never at the mount root:

   - Movies → `/mnt/zurg/movies`
   - TV Shows → `/mnt/zurg/shows`

   The same release appears in every directory whose filter matches it *and* under `__all__` and `__nzb__`. Point Plex at the root and it scans the same file several times over.

3. **Set two library options** under each library's Edit → Advanced:

   - **Uncheck "Empty trash automatically after every scan".** This is the one that matters. If the mount blips while Plex is scanning — a zurg restart, an rclone remount — Plex concludes every file was deleted. With auto-empty on, they are removed permanently and at once; with it off they sit in the trash and come back when the mount does. This has cost a 30,000-item library before.
   - **Uncheck "Generate video preview thumbnails".** Every thumbnail is a seek across the whole file; on Usenet that is a full read of the release through your connection allowance.

4. **Never restart zurg during a Plex scan.** Check before you do:

   ```bash
   TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}')
   curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'
   curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l
   ```

   Sessions at `size="0"` and a refreshing count of `0` mean it is safe. (Use `grep -o … | wc -l`, not `grep -c`: grep exits non-zero when it finds nothing, which is the *good* case, and will abort a `&&` chain right before the restart it was guarding.)

5. **Partial scans.** `on_library_update` is handed every changed path; `plex_update.sh` in the repo root is the reference script:

   ```yaml
   on_library_update: sh plex_update.sh "$@"
   ```

**What Plex will not get from Usenet content:** no ffprobe-derived metadata from zurg (see section 4), so Plex does its own analysis on first play like it would for any local file. File sizes settle shortly after a release is scanned: the first listing may report a cheap estimate from the article count, and the exact length arrives behind it — from the recovery index where there is one, and otherwise from one article per file. Once it lands, the library is told the release changed, so the mount and Plex both see the real length.

### Jellyfin / Emby / Infuse

Jellyfin and Emby take `jellyfin_server_url` / `jellyfin_token` and `emby_server_url` / `emby_token` and get the same scan notifications; see [jellyfin.md](jellyfin.md). Infuse can point at `http://<host>:9999/dav/` directly and skip rclone entirely.

---

## 7. When an article is missing

This is the failure mode Usenet has and debrid does not. Articles age out of a provider's retention or get taken down, and a release can be perfectly listed while a few of its articles are gone.

zurg's answer, in order of preference:

1. **Ask another news server.** An article one provider has aged out is very often still on another. This is one fetch — see [More than one Usenet provider](#more-than-one-usenet-provider).
2. **Rebuild it from the release's own PAR2 files.** This is what they are posted for. It costs a read of the *entire release* — Reed-Solomon has to fold every surviving slice to solve for a missing one — so on a 200 GB post it is 200 GB of reading to recover a few megabytes.
3. **Serve silence.** Only when neither of the above can answer.

PAR2 repair is a background job, at most one release at a time, and it needs:

```yaml
enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512       # budget for data/par2/; -1 keeps repairs in memory only
```

The rebuilt bytes are written under `data/par2/<nzb-id>/` and picked back up when the file is next opened, so a restart does not cost a full re-read of the release. Only the spans that are actually gone are kept — a damaged release usually costs single-digit megabytes — and whole releases are dropped least-recently-used first when the budget is exceeded. Each release's spans are stamped with the modification time of the NZB they were rebuilt from, so a re-saved NZB discards them rather than serving bytes at offsets that may have moved.

A repair announces itself and then says what it cost:

```
PAR2 repair of Some.Release: 5 slice(s) missing; reading the release to rebuild them
PAR2 repair of Some.Release rebuilt 5 slice(s) in 55s, keeping 3.4 MiB of them (library holds 3.4 MiB in memory, 3.4 MiB on disk)
```

Two things worth knowing:

- **Playback always outranks a repair.** Connections are handed out by who is waiting: a demand read first, read-ahead next, a repair last — except that a repair is guaranteed a quarter of the allowance against read-ahead, so the file being played can still repair the gap it is stuck on.
- **zurg's library-level repair cannot help here.** That mechanism re-adds a torrent to the account it came from; a backend that cannot add content can report a release broken but not fix it. For Usenet, PAR2 *is* the repair.

A release with no PAR2 files in its NZB and no second news account has no recovery path at all. That is a property of the post, not of zurg.

---

## Performance

Measured against a live Eweka account with 50 connections:

| | |
|---|---|
| Single stream, direct file | ~100 Mbit/s |
| Single stream, out of a RAR set | 90–106 Mbit/s |
| Two concurrent streams, aggregate | ~124 Mbit/s |

The single-stream rate is set by the **connection allowance**, not by read-ahead depth — deeper read-ahead was measured and gained nothing. So:

- **Set `connections` to your plan's real number.** This is the tuning knob. Eight connections will not stream a remux.
- **Two primary accounts add up.** Reads are driven at the combined allowance of every non-`backup` account, so a second unlimited provider raises the ceiling as well as covering the first one's retention gaps. A `backup` account does not count toward it.
- `cache_size_mb` (512 default) is shared across every file being read. Raise it if you run several concurrent streams; it does not make one stream faster.
- Whether a release is RAR-packed or posted as plain files no longer matters much for throughput.

Repairs are slow by nature — they read the whole release — but they run at background priority and are bounded by the news server rather than by zurg's own arithmetic.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot reach the news server for nzb` at startup | Wrong host/port/TLS pairing, bad credentials, or an inactive plan | `563` goes with `tls: true`, `119` with `tls: false`; then re-check the credentials |
| Library is empty, no `Loaded NZB` lines | `nzbs/` missing, or in the wrong place | It is relative to zurg's **working directory** — check `WorkingDirectory=` in your systemd unit, or `/app/nzbs` in Docker |
| One NZB never appears | In a subdirectory, or named `.nzb.gz`, or unparseable | Move it directly into `nzbs/`, decompress it; check the log for a `Skipping` warning |
| Release shows up with a useless name | The NZB's filename is the name, absent a `<meta type="name">` | Rename the `.nzb` to the release name |
| Files have random names inside the release | Obfuscated post whose recovery failed | Check for `Recovered N filename(s)`; without PAR2 files in the NZB there is no source for the real names |
| The video still has a random name, though the folder is right | A fully obfuscated post, where the archive holds several files of a similar size | Only a clear single payload is renamed to the release; a season pack in one archive keeps the names the archive gave it |
| Streaming is slow | `connections` left at the default 8 | Set it to the plan's allowance |
| Connections refused by the provider | `connections` above what the plan permits | Lower it to the real figure |
| Playback stutters or a gap plays silent | Missing articles | Look for `PAR2 repair of …` in the log; confirm `enable_repair: true`; add [another Usenet provider](#more-than-one-usenet-provider) |
| A gap stays silent and no repair line ever appears | `enable_repair` is off, or the NZB carries no `.par2` files | Set `enable_repair: true`; if the post has no recovery files, only another news account can help |
| A second provider never seems to be asked | Both accounts carry the same `backbone`, so the second is skipped once the first says the article is gone | Correct the `backbone` values — only accounts genuinely on one spool should share a name |
| One of several accounts is dead but startup looked fine | Startup only fails when *every* account is unreachable | Grep the log for `is not reachable` — each bad account warns by name |
| A block account is being billed for articles the unlimited one has | `backup: true` missing on it | Set it; a primary being merely busy will then no longer push reads onto the metered account |
| A release is missing from a tag-filtered directory | ffprobe never runs on Usenet content, so it carries no `zurg_*` tags | Filter on names, extensions, size or `has_episodes` |
| `.par2` files not visible in the mount | Deliberate — they are hidden as repair scaffolding | Nothing to fix; zurg still reads them |
| Edited the provider in the Dashboard and the extra news accounts vanished | The Dashboard's provider form covers one account and rewrites the whole `nntp` block, dropping `nntp.servers` | Restore them in `config.yml`; edit that provider by hand from then on |
| Changed a provider in the Dashboard and nothing happened | Provider changes are written to `config.yml` but not hot-reloaded | Restart zurg — the banner under the providers table says so |
| Plex emptied the library after a zurg restart | A scan was in flight while the mount was away, with auto-empty-trash on | Turn auto-empty off, and pre-flight sessions *and* refreshing state before any restart |
| A file's size changed slightly a moment after the release appeared | The first listing can only estimate from the article count; the exact length arrives behind it, from the PAR2 index or from the file's own yEnc header | Expected, and it settles once — the length is written to `data/nzb-sizes/` and never learned again |

---

## See also

- [config.md](../reference/config.md) — every option, including the [Usenet account reference](../reference/config.md#usenet-accounts) and the [directory filter reference](../reference/config.md#7-directories--filters)
- [plex.md](plex.md) — how zurg drives Plex scanning, matching and the trash sweep
- [jellyfin.md](jellyfin.md) — Jellyfin integration
- [docker.md](../setup/docker.md) — Docker setup, FUSE propagation and troubleshooting
- [tags.md](../reference/tags.md) — the tag system, and therefore what Usenet content does not get
- [architecture.md](../internals/architecture.md) — `internal/nzb` and `internal/nntp` in context
