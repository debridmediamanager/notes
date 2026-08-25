---
label: From streamnzb
icon: arrow-right
order: 50
---

# Migrating from streamnzb v5.1.0 to zurg

Be clear about what this migration is before starting it: **it is a change of
model, not a cutover.** streamnzb has no filesystem, no WebDAV, no mount and no
Plex library — it is a Stremio addon that searches your Newznab indexers per
playback request, ranks the results with jhin, checks them against AvailNZB and
streams the winner on the fly. Nothing is retained. There is therefore **no
library on disk to preserve and no Plex watch state at risk**, and none of the
path-preservation machinery the other migration guides revolve around applies
here. What you are actually doing is standing up a different kind of system —
a persistent library over a directory of `.nzb` files, mounted for Plex,
Jellyfin or Emby — and deciding what to do about the things streamnzb did that
zurg deliberately does not.

This guide is shorter than its siblings because the problem is smaller.

---

## The model change

| | streamnzb | zurg |
|---|---|---|
| Content acquisition | Searches Newznab indexers per play request | None — you supply `.nzb` files |
| Ranking / selection | jhin traits + filter profiles, AvailNZB check | None — one NZB, one release |
| Retention | Nothing kept; every play is a fresh search | Persistent library, rebuilt from `nzbs/` |
| Client | Stremio (addon is also the metadata provider) | Any media server over the mount, or WebDAV directly (Infuse) |
| Filesystem | None | rclone FUSE mount + WebDAV + plain HTTP index |
| Archives | RAR/7z **STORE only**; compressed releases will not play | Compressed RAR and 7z streamed transparently |
| Obfuscated posts | Refused | Names recovered from yEnc headers / PAR2, payload presented under the release name |
| Damaged posts | Skipped via AvailNZB | PAR2 repair rebuilds missing articles |
| SABnzbd API | No (but has an NNTP proxy on 119) | Yes, opt-in and Usenet-only — no failure signal for a dead post yet |

Day to day the difference is this: with streamnzb you picked a title in Stremio
and the addon found a release for you. **zurg has no indexer search of its
own**, so acquiring content becomes a separate step, and you need something to
fill it:

- **The SABnzbd endpoint** — `sabnzbd.enabled: true` makes zurg answer Sonarr
  and Radarr as a download client, and the import is a rename inside
  `__magic__` rather than a copy. This is the closest thing to what streamnzb
  did for you, and it is what most setups should use; see
  [sabnzbd.md](../guides/sonarr-radarr.md). The caveat to know before switching a library over:
  zurg does not yet check whether a post's articles are still on the news
  server, so a dead release reports Completed and fails on the first read
  instead of being blocklisted and re-grabbed.
- **Manual drop** — download the `.nzb` from your indexer's website and copy it
  into `nzbs/` (fixed name, rescanned every ~15 s, never moved or consumed).
  Always works, and is the honest baseline.
- **Sonarr/Radarr "Usenet Blackhole"** — the \*arrs can be configured with a
  Blackhole download client whose *Nzb Folder* is zurg's `nzbs/`. It gets the
  search-and-grab automation back without the endpoint, at a cost: the \*arr
  waits for a completed download to appear in its watch folder and import it,
  and zurg never produces one — the release appears in the mount instead — so
  the \*arr's queue will show the item as never finishing. You get automated
  NZB delivery, not the \*arr's import/rename pipeline. (Behaviour of the
  \*arr side not re-verified for this guide; the zurg side — watch directory,
  `internal/nzb/provider.go:30` — is verified in code.)
- **An indexer's own RSS/cart download to a directory** — depends entirely on
  the indexer and on you scripting the fetch. Unverified; mentioned only
  because some indexers offer it.

**Name the file before you drop it.** The release folder in the mount is named
after the NZB *filename* (the `<meta type="name">` header is used only when the
filename looks like a hash) — measured across all five servers on 2026-08-19.
`nzbgeek_download_48213.nzb` gives Plex nothing to match; rename it to the
release name first. This also means the folder name is fully under your
control. Two different releases with the same name get a ` {shorthash}` suffix.

---

## Configuration that carries over

Exactly one block does: the Usenet provider. streamnzb configures providers in
the UI (**Settings → Providers**: host, port, username, password, connections)
or via environment variables; the same account becomes zurg's `nntp` block.

Before — streamnzb (env-variable form, the documented key names):

```
PROVIDER_1_HOST=news.example.com
PROVIDER_1_PORT=563
PROVIDER_1_SSL=true
PROVIDER_1_USERNAME=USERNAME
PROVIDER_1_PASSWORD=PASSWORD
PROVIDER_1_CONNECTIONS=30
PROVIDER_1_PRIORITY=1
```

After — zurg `config.yml`:

```yaml
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true            # streamnzb's SSL flag
      username: USERNAME
      password: PASSWORD
      connections: 30      # your plan's real allowance — this is the tuning knob
      cache_size_mb: 512
```

A second streamnzb provider (`PROVIDER_2_*`) goes under `nntp.servers`, where
zurg falls back through accounts article by article. `priority` maps directly;
zurg adds two concepts streamnzb has no equivalent of — `backup: true` for a
metered block account only consulted when every primary says *no such article*,
and `backbone` to stop two accounts on the same spool being asked the same
question twice. Only one `nzb` provider entry is allowed; extra news accounts
belong inside it, not beside it.

Nothing else in streamnzb's `data/config.json` transfers. `indexers` have no
zurg counterpart at all (see above), `streams` and `filter_profiles` shaped
Stremio manifests that no longer exist. The nearest analogue of a filter
profile is zurg's `directories:` filters — but they organise a library you
already have rather than choosing which release to fetch.

---

## Watch history

streamnzb keeps per-stream playback history in its database — SQLite at
`data/streamnzb.db` by default, optionally Postgres — and builds the Continue
Watching and Because You Watched rows from it. Its docs describe the contents
as "library, search and play history, bad releases, and metrics".

**None of it is portable to a Plex library.** Plex watch state is per-item in
Plex's own database, keyed to items that must exist in a library first, and no
importer exists on either side. This is not really a loss of data so much as a
mismatch of models: streamnzb's history rows reference searches and streams,
not files. If you want the record before decommissioning, the database is
plain SQLite and can be read with:

```bash
sqlite3 data/streamnzb.db .tables
sqlite3 data/streamnzb.db "select * from <table> limit 20;"
```

(Exact table names are not documented and were not verified for this guide —
`.tables` is how you find them. On Postgres, the same data lives in whatever
database `DATABASE_URL` points at.) Watch state in your new setup starts from
zero and accrues in Plex from the first play.

---

## What you gain

- **A real library.** Plex, Jellyfin and Emby scan a filesystem, keep
  metadata, track watch state across every client they support — not just
  Stremio.
- **PAR2 repair.** A release with missing articles is rebuilt from its own
  recovery files in the background. streamnzb's answer to a bad release was to
  skip it; zurg's is to fix it.
- **Obfuscated releases.** zurg recovers real filenames from yEnc headers and
  the PAR2 index, and presents a fully obfuscated payload under the release
  name — measured: `Obfuscated.nzb` served a clean
  `Toy.Story.5.2026...KyoGo.mkv`. streamnzb refuses these outright.
- **Compressed RAR and 7z.** streamnzb streams only STORE'd archives — its
  README is explicit that "Compressed RAR releases will not play". zurg streams
  video out of compressed archives, including reproducing the inner directory
  structure.
- **No per-title cold start.** streamnzb ran a search, ranking and
  availability check per play request. In zurg the release is already in the
  library; a play is a ranged read.
- **Multi-account depth.** Priorities, metered `backup` accounts, `backbone`
  dedup, and a repair path when every account misses.

## What you lose

Do not undersell these — they were the product.

- **Indexer search and ranking.** No Newznab search, no jhin traits, no filter
  profiles, no scoring. You (or an *arr) choose the release now.
- **The AvailNZB check.** zurg does not know a release is bad until it tries
  it. The failure mode moved from "skipped before play" to "PAR2 repair, or an
  empty folder for an unrecoverable one" — measured: a RAR set missing volumes
  yields an empty directory, not an error.
- **The Stremio experience**, including streamnzb's built-in catalogs,
  metadata, Continue Watching and Because You Watched. Your media server
  provides its own equivalents, but Stremio itself has no zurg addon.
- **The NNTP proxy on port 119.** If SABnzbd or NZBGet pointed at streamnzb as
  their news server, they need real provider credentials again.
- **A single binary that needed no media server.** zurg is one binary too, but
  the setup it replaces streamnzb with is zurg + rclone + a media server.
  (Infuse can point at zurg's WebDAV directly and skip rclone.)

---

## Standing up zurg

A working Usenet-only `config.yml`:

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

Do not use `tags_match_any` filters for Usenet content — the `zurg_*` tags come
from ffprobe, which never runs on this backend, so such a directory will simply
never contain a Usenet release. Filter on names, extensions, sizes and
`has_episodes`.

Then:

```bash
mkdir -p nzbs        # zurg does not create it; a missing one is an empty library
./zurg               # startup verifies the news account and says so, loudly
ls /mnt/zurg/__nzb__/
```

`__nzb__` is pinned to the Usenet account — the right place to confirm playback
works. Subdirectories of `nzbs/` are skipped and `.nzb.gz` is not read.

### The first Plex library

Point libraries at **subdirectories** of the mount (`/mnt/zurg/movies`,
`/mnt/zurg/shows`), never the root — the same release appears under `__all__`,
`__nzb__` and every matching directory, and the root would be scanned several
times over. Give zurg `plex_server_url` and `plex_token` so it can request
partial scans.

Two library settings matter from the very first scan, brand-new library or not,
because the failure they guard against is the mount blipping *during* a scan:

1. **Uncheck "Empty trash automatically after every scan"** (`autoEmptyTrash`
   must be 0). If the mount disappears mid-scan — a zurg restart, an rclone
   remount — Plex concludes every file was deleted. With auto-empty on they are
   removed permanently and at once; with it off they sit in the trash and come
   back with the mount. This has cost a 30,065-item library before.
2. **Uncheck "Generate video preview thumbnails"** — on Usenet every thumbnail
   pass is a full read of the release through your connection allowance.

And never restart zurg while Plex is scanning. Pre-flight, both must be zero:

```bash
TOKEN=$(grep ^plex_token: config.yml | awk '{print $2}')
curl -s "http://localhost:32400/status/sessions?X-Plex-Token=$TOKEN" | grep -o 'size="[0-9]*"'          # want size="0"
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$TOKEN" | grep -o 'refreshing="1"' | wc -l # want 0
```

Use `grep -o … | wc -l`, not `grep -c`: grep exits non-zero when it finds
nothing, which is the *good* case here, and aborts a `&&` chain or `set -e`
script right before the restart it was guarding.

One known wart to expect: for files whose poster wrote no byte count into the
subject, zurg's listed size is the yEnc-encoded length — up to ~3% over the
true size (measured) — and reading the file does not correct the listing. On a
fresh library this costs nothing at scan time, but a later fix that changes
advertised sizes will make those files look modified to Plex and can trigger
re-analysis. It does not delete anything.

---

## Running both side by side

Nothing collides on ports — streamnzb owns 7000 and 119, zurg owns 9999 — so
the sane transition is to keep streamnzb serving Stremio while the zurg library
fills up. The one shared resource is the news account: **both read from the
same connection allowance, and the provider enforces it across both**. A plan
with 50 connections cannot run streamnzb at 50 and zurg at 30; the excess gets
connections refused, which on the zurg side looks like slow or stalling
streams. Split it explicitly — e.g. `PROVIDER_1_CONNECTIONS=20` in streamnzb
and `connections: 30` in zurg — and give zurg the full allowance when
streamnzb is retired, because zurg's single-stream throughput is set by that
number.

When you switch off streamnzb, remove its Stremio addon from your clients, keep
a copy of `data/` if you want the history (`config.json` + `streamnzb.db` is
the whole of its state), and re-point anything that used the NNTP proxy on 119
at your provider directly.
