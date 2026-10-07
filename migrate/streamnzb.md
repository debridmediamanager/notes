---
label: From streamnzb
icon: arrow-right
order: 50
---

# Migrating from streamnzb v5.1.0 to zurg

streamnzb is a Stremio addon. When you press play it searches your Newznab
indexers. It ranks the results with jhin. It checks them against AvailNZB and
streams the winner. Nothing is kept. It has no filesystem and no WebDAV and no
mount and no Plex library.

So there is **no library on disk to preserve and no Plex watch state at risk**.
None of the path-preservation machinery the other migration guides revolve
around applies here.

zurg can take its place in two ways. Use one or both.

- **Keep Stremio.** zurg has a [Stremio addon](../guides/stremio.md) of its
  own. It searches your Newznab indexers when you press play and streams the
  release you pick through your news account. That is how streamnzb works too.
  It needs nothing but zurg. No rclone and no media server. Every release played
  this way also stays in zurg's library.
- **Build a library.** zurg keeps the releases it has in a library and mounts
  it for Plex or Jellyfin or Emby. Sonarr and Radarr can fill it. So can zurg
  itself from your watchlist.

A few things streamnzb did have no zurg equivalent. This guide says which.

This guide is shorter than its siblings because the problem is smaller.

## What needs rescanning and what new content shows up

The two questions the [other migration guides](index.md) answer do not really
apply here. It is worth saying why rather than leaving you to wonder.

**Nothing needs rescanning because there is nothing to rescan.** streamnzb
holds no library and Plex has no items bound to any path. So none of the
trash-guard machinery on the shared page is load-bearing for you. There is no
old item to preserve and nothing that can be trashed by a mistake.

**All of it is new content.** Whatever you drop into zurg's `nzbs/` is a
first-time scan into an empty library. Set your libraries up the way you want
them before the first pass rather than fixing them afterwards. Two settings are
worth having in place first.

- [`only_show_the_biggest_file: true`](../reference/config.md) on the
  directories your media libraries scan. Without it you get sample clips and
  `.nfo` files and the poster's `.url` adverts visible.
- "Generate video preview thumbnails" **off** on those libraries. On a
  streaming mount every thumbnail pass is a full read of the release through
  your news allowance. A first scan hands Plex the whole library at once.

---

## The model change

| | streamnzb | zurg |
|---|---|---|
| Content acquisition | Searches Newznab indexers per play request | The [Stremio addon](../guides/stremio.md) searches Newznab indexers per play request. A library also fills from `.nzb` files and the SABnzbd endpoint and [acquisition](../guides/acquisition.md) |
| Ranking and selection | jhin traits and filter profiles and an AvailNZB check | Resolution first and then a spread of sizes in each resolution. No traits and no filter profiles |
| Retention | Nothing kept. Every play is a fresh search | Persistent library. A release played through the addon stays in it |
| Client | Stremio. The addon is also the metadata provider | Stremio through zurg's addon, which answers streams only. Any media server over the mount. Or WebDAV directly for Infuse |
| Filesystem | None | rclone FUSE mount plus WebDAV plus a plain HTTP index |
| Archives | RAR and 7z **STORE only**. Compressed releases will not play | Compressed RAR and 7z streamed transparently |
| Obfuscated posts | Refused | Names recovered from yEnc headers and PAR2. Payload presented under the release name |
| Damaged posts | Skipped via AvailNZB | PAR2 repair rebuilds missing articles. The addon skips a release whose start is gone and tries the next one |
| SABnzbd API | No. It has an NNTP proxy on 119 instead | Yes and opt-in. Each grab is checked against the news servers. A dead post is rebuilt from PAR2 where it can be and reported Failed where it cannot |

Day to day Stremio can stay as it is. Add zurg's addon and pick a title the way
you did before. zurg searches your indexers and plays what you pick. The
[Stremio page](../guides/stremio.md) covers the setup. The first play of a
release waits while zurg fetches the NZB and lists the release. That is usually
a few seconds. Every later play of that release starts at once.

A library for your media server needs something to fill it.

- **The SABnzbd endpoint.** Setting `sabnzbd.enabled: true` makes zurg answer
  Sonarr and Radarr as a download client. The import is a rename inside
  `__magic__`. The grab lands in `__magic__/__all__`. The import moves the file
  from there into the root folder you made beside it. Nothing is copied. Most
  library setups should use this. See [Sonarr &
  Radarr](../guides/sonarr-radarr.md). zurg checks every grab against the news
  servers before it reports it finished. It asks about the start and the end of
  every file. It also downloads the first article of each file. That is up to
  sixty-four of them plus a few more of a release with only a few files. Some
  news servers still say an article exists after its content was taken down and
  only a download shows that. zurg rebuilds a release with articles gone from
  its PAR2 files where it can. One it cannot rebuild is reported **Failed**.
  The \*arr then blocklists it and grabs another.
- **Acquisition.** zurg can fetch requests by itself. They come from your Plex
  watchlist and from Seerr and the \*arrs. It searches your Newznab indexers and
  checks each grab the same way. See [acquisition](../guides/acquisition.md).
- **Manual drop.** Download the `.nzb` from your indexer's website and copy it
  into `nzbs/`. The name is fixed and the directory is rescanned every 15
  seconds or so and files are never moved or consumed. Always works and it is
  the honest baseline.
- **Sonarr and Radarr "Usenet Blackhole".** The \*arrs can be configured with a
  Blackhole download client whose *Nzb Folder* is zurg's `nzbs/`. It gets the
  search-and-grab automation back without the endpoint at a cost. The \*arr
  waits for a completed download to appear in its watch folder and import it.
  zurg never produces one because the release appears in the mount instead. So
  the \*arr's queue shows the item as never finishing. You get automated NZB
  delivery rather than the \*arr's import and rename pipeline. The \*arr side of
  this was not re-verified for the guide. The zurg side is verified in code at
  `internal/nzb/provider.go:30`.
- **An indexer's own RSS or cart download to a directory.** This depends
  entirely on the indexer and on you scripting the fetch. Unverified and
  mentioned only because some indexers offer it.

**Name the file before you drop it.** The release folder in the mount is named
after the NZB *filename*. The `<meta type="name">` header is used only when the
filename looks like a hash. That was measured across all five servers on
2026-08-19. A file called `indexer_download_48213.nzb` gives Plex nothing to
match so rename it to the release name first. This also means the folder name
is fully under your control. Two different releases with the same name get a
` {shorthash}` suffix.

---

## Configuration that carries over

Two things do. The first is the Usenet provider. streamnzb configures
providers under **Settings → Providers** with host and port and username and
password and connections. Environment variables work too. The same account
becomes zurg's `nntp` block.

Before in streamnzb. This is the env-variable form with the documented key names.

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

After in zurg's `config.yml`.

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance and the tuning knob
      cache_size_mb: 512
```

A second streamnzb provider such as `PROVIDER_2_*` goes under `nntp.servers`
where zurg falls back through accounts article by article. `priority` maps
directly. zurg adds two concepts streamnzb has no equivalent of. Setting
`backup: true` marks a metered block account that is only consulted when every
primary says *no such article*. Setting `backbone` stops two accounts on the
same spool being asked the same question twice. Only one `nzb` provider entry
is allowed. Extra news accounts belong inside it rather than beside it.

The second is your indexers. They go under `stremio.indexers` with the same
URL and API key. Acquisition uses the same list when it has none of its own.

```yaml
stremio:
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
```

Nothing else in streamnzb's `data/config.json` transfers. The `streams` and
`filter_profiles` blocks shaped what streamnzb's addon offered. zurg's addon
has one list per title and its own ranking. Its nearest knobs are two.
`max_size_gb` drops releases above a size. `max_results` sets how many releases
each resolution keeps. The [Stremio page](../guides/stremio.md) has the rest.

---

## Watch history

streamnzb keeps per-stream playback history in its database. That is SQLite at
`data/streamnzb.db` by default and optionally Postgres. It builds the Continue
Watching and Because You Watched rows from it. Its docs describe the contents
as "library, search and play history, bad releases, and metrics".

**None of it is portable to a Plex library.** Plex watch state is per-item in
Plex's own database and keyed to items that must exist in a library first. No
importer exists on either side. This is not really a loss of data so much as a
mismatch of models. streamnzb's history rows reference searches and streams
rather than files. If you want the record before decommissioning then the
database is plain SQLite and can be read directly.

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

Exact table names are not documented and were not verified for this guide.
Running `.tables` is how you find them. On Postgres the same data lives in
whatever database `DATABASE_URL` points at. Watch state in your new setup
starts from zero and accrues in Plex from the first play.

---

## What you gain

- **A real library.** Plex and Jellyfin and Emby scan a filesystem and keep
  metadata and track watch state across every client they support. Not just
  Stremio.
- **PAR2 repair.** A release with missing articles is rebuilt from its own
  recovery files in the background. streamnzb's answer to a bad release was to
  skip it. zurg's is to fix it.
- **Obfuscated releases.** zurg recovers real filenames from yEnc headers and
  the PAR2 index and presents a fully obfuscated payload under the release
  name. Measured on the bench where `Obfuscated.nzb` served a clean
  `Toy.Story.5.2026...KyoGo.mkv`. streamnzb refuses these outright.
- **Compressed RAR and 7z.** streamnzb streams only STORE'd archives and its
  README is explicit that "Compressed RAR releases will not play". zurg streams
  video out of compressed archives and reproduces the inner directory structure
  while it does.
- **Second plays start at once.** streamnzb searched and checked on every
  play. zurg keeps what you played. A release already in the library plays
  straight away. Everything Sonarr or Radarr fetched is in that state from the
  start.
- **Multi-account depth.** Priorities and metered `backup` accounts and
  `backbone` dedup and a repair path when every account misses.

## What you lose

Do not undersell these. They were the product.

- **jhin and filter profiles.** zurg's addon searches your indexers too. It
  ranks by resolution and size alone. There are no jhin traits or filter
  profiles or scores.
- **The AvailNZB check.** zurg asks nobody else whether a release is alive.
  The addon finds out by reading the start of the release you picked. When that
  is gone it moves on to the next release in the list. A grab from Sonarr or
  Radarr is checked against your news servers before it counts as finished.
  Damage further into a file turns up when a read reaches it. PAR2 repair then
  rebuilds it where the post carries enough recovery data. On 2026-08-19 a RAR
  set missing whole volumes listed as an empty folder rather than an error.
- **streamnzb's catalogs and rows.** Its built-in catalogs and metadata and its
  Continue Watching and Because You Watched rows came from its own history.
  zurg's addon answers streams only. A media server has its own versions of
  those rows for a library.
- **The NNTP proxy on port 119.** If SABnzbd or NZBGet pointed at streamnzb as
  their news server then they need real provider credentials again.

---

## Standing up zurg

A working Usenet-only `config.yml`.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30          # the plan's full allowance once streamnzb is gone
      cache_size_mb: 512

enable_repair: true            # PAR2 repair does not run without this
par2_patch_cache_mb: 512

stremio:                       # keeps Stremio working. Leave it out for a library alone
  enabled: true
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY

mount_path: "/mnt/zurg"
rclone_enabled: true
rclone_binary: bin/rclone      # downloaded automatically on first run

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

Do not use `tags_match_any` filters for Usenet content. The `zurg_*` tags come
from ffprobe and ffprobe never runs on this backend. Such a directory will
simply never contain a Usenet release. Filter on names and extensions and sizes
and `has_episodes` instead.

Then start it.

```bash
./zurg               # startup verifies the news account and says so, loudly, and makes nzbs/
ls /mnt/zurg/__nzb__/
```

`__nzb__` is pinned to the Usenet account so it is the right place to confirm
playback works. Subdirectories of `nzbs/` are skipped and `.nzb.gz` is not
read.

### The first Plex library

Point libraries at **subdirectories** of the mount such as `/mnt/zurg/movies`
and `/mnt/zurg/shows`. Never the root. The same release appears under `__all__`
and `__nzb__` and every matching directory so the root would be scanned several
times over. Give zurg `plex_server_url` and `plex_token` so it can request
partial scans.

Two library settings matter from the very first scan whether the library is
brand-new or not. The failure they guard against is the mount blipping *during*
a scan.

1. **Uncheck "Empty trash automatically after every scan"** so that
   `autoEmptyTrash` is 0. If the mount disappears mid-scan then Plex concludes
   every file was deleted. A zurg restart or an rclone remount is enough to do
   it. With auto-empty on they are removed permanently and at once. With it off
   they sit in the trash and come back with the mount. This has cost tens
   of thousands of items before.
2. **Uncheck "Generate video preview thumbnails".** On Usenet every thumbnail
   pass is a full read of the release through your connection allowance.

And never restart zurg while Plex is scanning. Pre-flight and both must be
zero.

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}')
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Use `grep -o … | wc -l` rather than `grep -c`. grep exits non-zero when it
finds nothing and that is the *good* case here. It aborts a `&&` chain or a
`set -e` script right before the restart it was guarding.

File sizes settle a little after a release first lists. An NZB does not say
how long a file is. So the first listing estimates it from the article sizes
the NZB records. That can read up to about 3 per cent high. zurg then learns the
exact length in the background and keeps it. A scan that ran before that sees
the estimate. Plex then treats the file as modified and analyses it again once.
Nothing is deleted.

---

## Running both side by side

Nothing collides on ports. streamnzb owns 7000 and 119 and zurg owns 9999. So
the sane transition is to keep streamnzb serving Stremio while the zurg library
fills up.

The one shared resource is the news account. **Both read from the same
connection allowance and the provider enforces it across both.** A plan with 50
connections cannot run streamnzb at 50 and zurg at 30. The excess gets
connections refused and on the zurg side that looks like slow or stalling
streams. Split it explicitly. Try `PROVIDER_1_CONNECTIONS=20` in streamnzb
against `connections: 30` in zurg. Give zurg the full allowance when streamnzb
is retired because zurg's single-stream throughput is set by that number.

When you switch off streamnzb remove its Stremio addon from your clients. Keep
a copy of `data/` if you want the history. Its `config.json` and
`streamnzb.db` are the whole of its state. Then re-point anything that used the
NNTP proxy on 119 at your provider directly.
