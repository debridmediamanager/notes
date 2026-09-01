---
label: From streamnzb
icon: arrow-right
order: 50
---

# Migrating from streamnzb v5.1.0 to zurg

Be clear about what this migration is before starting it. **It is a change of
model rather than a cutover.** streamnzb has no filesystem and no WebDAV and no
mount and no Plex library. It is a Stremio addon that searches your Newznab
indexers per playback request. It ranks the results with jhin. It checks them
against AvailNZB and streams the winner on the fly. Nothing is retained.

So there is **no library on disk to preserve and no Plex watch state at risk**.
None of the path-preservation machinery the other migration guides revolve
around applies here. What you are actually doing is standing up a different
kind of system. A persistent library over a directory of `.nzb` files mounted
for Plex or Jellyfin or Emby. Then deciding what to do about the things
streamnzb did that zurg deliberately does not.

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
| Content acquisition | Searches Newznab indexers per play request | None. You supply `.nzb` files |
| Ranking and selection | jhin traits and filter profiles and an AvailNZB check | None. One NZB is one release |
| Retention | Nothing kept. Every play is a fresh search | Persistent library rebuilt from `nzbs/` |
| Client | Stremio. The addon is also the metadata provider | Any media server over the mount. Or WebDAV directly for Infuse |
| Filesystem | None | rclone FUSE mount plus WebDAV plus a plain HTTP index |
| Archives | RAR and 7z **STORE only**. Compressed releases will not play | Compressed RAR and 7z streamed transparently |
| Obfuscated posts | Refused | Names recovered from yEnc headers and PAR2. Payload presented under the release name |
| Damaged posts | Skipped via AvailNZB | PAR2 repair rebuilds missing articles |
| SABnzbd API | No. It has an NNTP proxy on 119 instead | Yes and opt-in and Usenet-only. No failure signal for a dead post yet |

Day to day the difference is this. With streamnzb you picked a title in Stremio
and the addon found a release for you. **zurg has no indexer search of its
own.** Acquiring content becomes a separate step and you need something to fill
it.

- **The SABnzbd endpoint.** Setting `sabnzbd.enabled: true` makes zurg answer
  Sonarr and Radarr as a download client and the import is a rename inside
  `__magic__` rather than a copy. This is the closest thing to what streamnzb
  did for you and it is what most setups should use. See
  [Sonarr & Radarr](../guides/sonarr-radarr.md). One caveat to know before
  switching a library over. zurg does not yet check whether a post's articles
  are still on the news server. So a dead release reports Completed and fails
  on the first read instead of being blocklisted and re-grabbed.
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
2026-08-19. A file called `nzbgeek_download_48213.nzb` gives Plex nothing to
match so rename it to the release name first. This also means the folder name
is fully under your control. Two different releases with the same name get a
` {shorthash}` suffix.

---

## Configuration that carries over

Exactly one block does and that is the Usenet provider. streamnzb configures
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

Nothing else in streamnzb's `data/config.json` transfers. The `indexers` block
has no zurg counterpart at all. The `streams` and `filter_profiles` blocks
shaped Stremio manifests that no longer exist. The nearest analogue of a filter
profile is zurg's `directories:` filters. Those organise a library you already
have rather than choosing which release to fetch.

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
- **No per-title cold start.** streamnzb ran a search and a ranking and an
  availability check per play request. In zurg the release is already in the
  library so a play is a ranged read.
- **Multi-account depth.** Priorities and metered `backup` accounts and
  `backbone` dedup and a repair path when every account misses.

## What you lose

Do not undersell these. They were the product.

- **Indexer search and ranking.** No Newznab search and no jhin traits and no
  filter profiles and no scoring. You or an \*arr choose the release now.
- **The AvailNZB check.** zurg does not know a release is bad until it tries
  it. The failure mode moved from "skipped before play" to "PAR2 repair or an
  empty folder for an unrecoverable one". Measured on the bench where a RAR set
  missing volumes yields an empty directory rather than an error.
- **The Stremio experience.** That includes streamnzb's built-in catalogs and
  metadata and Continue Watching and Because You Watched. Your media server
  provides its own equivalents but Stremio itself has no zurg addon.
- **The NNTP proxy on port 119.** If SABnzbd or NZBGet pointed at streamnzb as
  their news server then they need real provider credentials again.
- **A single binary that needed no media server.** zurg is one binary too but
  the setup it replaces streamnzb with is zurg and rclone and a media server.
  Infuse can point at zurg's WebDAV directly and skip rclone.

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
mkdir -p nzbs        # zurg does not create it; a missing one is an empty library
./zurg               # startup verifies the news account and says so, loudly
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
   they sit in the trash and come back with the mount. This has cost a
   30,065-item library before.
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

One known wart to expect. For files whose poster wrote no byte count into the
subject zurg's listed size is the yEnc-encoded length. That runs up to roughly
3% over the true size as measured and reading the file does not correct the
listing. On a fresh library this costs nothing at scan time. But a later fix
that changes advertised sizes will make those files look modified to Plex and
can trigger re-analysis. It does not delete anything.

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
