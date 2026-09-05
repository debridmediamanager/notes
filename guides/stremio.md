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

## Search behaviour

- Movies search `t=movie`, episodes `t=tvsearch` with `season`/`ep`, both by
  `imdbid` — as bare digits, because several indexers answer zero results for
  the `tt` form.
- Indexers are searched in parallel; one refusing (a burst limit, a dead key)
  costs its results, not the list. Refusals are logged per indexer.
- Results are deduplicated by release name, ranked resolution-first then size,
  and capped at `max_results` (default 15).
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
