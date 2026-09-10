---
label: Stremio addon
icon: device-desktop
order: 55
---

# The Stremio addon

zurg can answer Stremio as an addon: the client asks for streams by IMDb id,
zurg searches your Newznab indexers, and picking a stream pulls that release's
NZB into the Usenet backend and plays it — the search-per-play model streamnzb
had, on top of zurg's library, repair and archive streaming. Everything played
this way also lands in the library, so it shows up in Plex like any other
release.

## Configuration

The addon needs the `nzb` provider (it is what serves the bytes) and at least
one indexer:

```yaml
stremio:
  enabled: true
  # token: ""            # generated and kept in data/stremio-token when empty
  indexers:
    - name: nzbgeek
      url: https://api.nzbgeek.info
      api_key: YOUR_KEY
    - name: house-of-usenet
      url: https://house-of-usenet.com
      api_key: YOUR_KEY
      api_path: /api/v1/api   # this one 404s the default /api
```

All of it is on the config page under **Stremio Addon** — the switch, the
indexer list and the result cap — and the addon URL is shown there with a copy
button, built from the address you opened the dashboard on. That is the address
to use: see the note below.

On startup zurg logs the addon URL:

```
<zurg>/stremio/<token>/manifest.json
```

Paste it into Stremio (Addons → the search box takes a URL). The token in the
path is the whole authorization — Stremio clients send no auth of their own,
so the routes sit outside basic auth the way the SABnzbd endpoint's do. Treat
the URL like a password: the play links it produces carry your indexer api
keys, and anyone holding it can spend your indexer grabs and news-server
connections.

The address matters: Stremio fetches streams and plays them from whatever host
the manifest URL names, so use an address the *player* can reach — a LAN
address, a Tailscale name — not `localhost`. Play URLs are minted for the host
each request arrives on, so one zurg serves LAN and tailnet clients at once.

## What a play does

Picking a stream is a grab: zurg downloads the NZB from the indexer, drops it
into `nzbs/` (through the same naming rules as the SABnzbd endpoint, so a
release grabbed twice — or already grabbed by an *arr — is found, not
duplicated), waits for the library to list it, and redirects the player into
the signed `/strm/e/` endpoint that every `.strm` file already plays through:
ranged reads, account failover, RAR/7z interiors.

The first play of a release therefore takes longer than a debrid stream — the
NZB has to be fetched and parsed, and an archive's interior read — typically a
few seconds, up to a minute or two for an obfuscated post whose naming pass
has to run. A play that outlasts the wait answers 503 with a Retry-After;
pressing play again lands on the fast path. Every later play is immediate.

A release that lists and turns out to hold nothing playable — usually one
that has aged off the spool, every file marked broken by the news-server
check — is not the end of the click. The play URL carries the request it was
minted for, so zurg looks up the same ranked list the stream list showed and
tries the rows after the one picked, up to two of them, each through the same
grab-and-list path; the first that plays is what the player is redirected
into. The rows *after* the pick on purpose: they are the same resolution and
smaller, or the resolution below, never a bigger release the user passed over.
A fallback that is itself still ingesting answers the same 503, and pressing
play again resolves it — the refused release is refused at once and the
fallback is found on the fast path. Only that final refusal falls through; a
503 never does. Each try spends an indexer grab and leaves its release in the
library like any other grab, which is why the count is small, and when every
row tried is refused the answer is the 404 it always was. Each fallback is
logged at info with the release refused and the one tried next.

Measured against three other usenet-backed Stremio addons on 7 September 2026:
stremio-addon-findings-2026-09-07.md.
The short version is that the per-resolution cap fixed what the previous round
found and coverage still halved, because a five-deep bucket has nowhere to go
when its first playable entry is a release that has aged off the spool. The
fallback above is the first fix from that round; the bucket is still five deep.

## Search behaviour

- Movies search `t=movie`, episodes `t=tvsearch` with `season`/`ep`, both by
  `imdbid` — as bare digits, because several indexers answer zero results for
  the `tt` form.
- Indexers are searched in parallel; one refusing (a burst limit, a dead key)
  costs its results, not the list. Refusals are logged per indexer.
- Results are deduplicated by release name, ranked resolution-first then size,
  and capped at `max_results` (default 5) *per resolution*. The cap counts per
  resolution because the sort leads with 2160p: a popular title has more UHD
  releases under the size ceiling than any cap, so counting across the whole
  list answers every popular title with nothing but remuxes, whatever else the
  search found.
- What each resolution keeps is a spread of its sizes, not its largest few:
  evenly spaced picks from the largest release down to the smallest, both
  always included. Kept from the top, a 1080p tier of five is five remuxes
  between 19 and 30 GB, and the 4 GB encode a phone or a laptop direct-plays
  is exactly what the cap removes — measured on 7 September 2026, three of
  zurg's fifteen entries for The Shawshank Redemption were under 6 GB against
  forty such releases on the same indexers. The list stays size-descending
  within a resolution. A release whose size the indexer did not state has no
  place on that axis, so it only fills whatever room the sized releases leave.
- Each stream's description carries the release name, its size, the indexer
  that found it, and how long ago it was posted — `3d`, `126d`, `2y` — when
  the indexer said. Ageing off the news server was the most common reason a
  play failed in the 7 September round, and the post date is the one signal
  a viewer can steer around it with.
- Releases larger than `max_size_gb` (default 40) are dropped before ranking —
  the resolution-first sort would otherwise put full-disc UHD remuxes at the
  top of every list. Sizes the indexer did not state are kept. The gate is
  applied when the list is rendered, so changing the ceiling takes effect on
  cached titles too.
- Results are cached on disk (`data/stremio-cache/`, one file per title), so
  reopening a title costs no indexer calls — they are often day-quota'd, and
  Treasure Maps refuses after roughly six rapid ones. How long an answer
  lives scales with how much the search found, because a thin list is
  evidence the uploads are still arriving or an indexer was down: one result
  lives one hour, two live two, up to four; five or more is a settled answer
  and lives `cache_hours` (default 24 — the only configurable rung). An
  empty answer is never cached. A cached stream list carries a **refresh**
  item at the bottom saying how old it is; opening that item (it opens in a
  browser, not the player) clears the cache for that title, and reopening
  the title searches fresh. The cache survives restarts and expired entries
  clean themselves up.
- Season 0 (specials) is refused rather than searched wrongly, and id-search
  coverage is the indexer's: a release an indexer only finds via text search
  will not appear.
