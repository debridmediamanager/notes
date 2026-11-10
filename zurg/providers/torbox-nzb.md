---
label: TorBox hosted Usenet
icon: broadcast
order: 38
---

# TorBox hosted Usenet

`type: torbox_nzb`

With a TorBox Pro plan TorBox does the Usenet part for you. zurg posts the
`.nzb` files in its watch directory to your TorBox account. TorBox fetches each
release, repairs it and serves it like any other TorBox download. zurg lists
what TorBox fetched in the mount beside everything else. There is no news
server account and no Usenet articles are decoded on your machine.

This is not [TorBox's news server](torbox-news-server.md). That is a login for
the `nzb` backend, which reads articles itself and is covered on
[Usenet](usenet.md). It is not a `torbox` entry either. That one lists your
torrents, and the [TorBox](torbox.md) page covers it.

## What you need

- **A TorBox Pro plan.** A lower plan does not take NZBs.
- **Your TorBox API key** from [torbox.app/settings](https://torbox.app/settings).
  It is the same key a `torbox` entry uses.
- **A current zurg nightly.** Nightlies need an active sponsorship.
- **A normal host.** zurg+rex Android, a Plex server on your phone, has no `torbox_nzb` backend. On an Android
  device, play TorBox hosted NZBs through DMM's TorBox Cast or the Kodi addon
  instead.

## Configure it

The entry takes a `token`; there is no `nntp` block. `watchlist` cannot be set
on it, because an NZB account cannot add torrents.

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

On a fresh container install save your key in `~/zurg/secrets/torbox` first,
then let setup read it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

On an install that already has a `config.yml` you can also use **Add provider**
in the Dashboard at `http://localhost:9999/config/` and pick `torbox_nzb`.
Restart zurg either way.

```bash
docker compose restart zurg
```

## How NZBs get in

Everything that reaches an `nzb` entry reaches this one the same way; DMM's
TorBox action is the one path that bypasses zurg.

- **The watch directory.** Drop a file into `nzbs/` beside the config
  (`~/zurg/nzbs/` on the host, `/config/nzbs/` in the container). zurg posts it
  to TorBox.
- **Sonarr and Radarr** through zurg's SABnzbd-compatible endpoint. See
  [Sonarr and Radarr for Usenet](../guides/sonarr-radarr.md).
- **Acquisition.** Newznab indexers, DMM Wanted and watchlists fetch onto it.
  See [Acquisition](../guides/acquisition.md).
- **DMM's TorBox action** on a Usenet result sends the NZB to TorBox directly.
  The release lists in zurg too, but zurg holds no NZB for it, so the repair
  button cannot fetch it again once TorBox drops it.

A post TorBox cannot fetch is reported to Sonarr or Radarr as a failed download.
The client blocklists the release and searches again.

## What differs from `nzb`

- **No news account.** There is no connection allowance to size and no
  providers' retention to weigh. TorBox's own spool decides what a post can be
  fetched from.
- **No articles are decoded here.** TorBox fetches the whole release. Article
  fetching, PAR2 repair, the article cache and article checks do not apply; the
  decoded-archive disk cache still does. A grab is checked by whether TorBox
  fetched it.
- **A 30-day cache.** A release someone else already fetched on TorBox is ready
  at once. TorBox drops a release 30 days after TorBox cached it. The repair
  button on the dashboard fetches it again by posting its NZB once more, so keep
  the files in `nzbs/`. zurg never re-posts on its own, because TorBox counts
  unattended re-downloads as abuse.
- **A slot per NZB in flight.** A post TorBox is still fetching holds one of
  your plan's active slots. A `torbox` entry on the same key uses the same
  slots for its torrents.
- **60 posts an hour.** TorBox takes that many new NZBs an hour per key. A big
  backlog, such as a full `nzbs/` on first start, drains over hours.

## One NZB account per instance

An instance takes one `nzb` entry or one `torbox_nzb` entry, never both. Both
would list every file in `nzbs/`. To run both, give the other kind an instance
of its own with its own working directory. With `dmm_api_key` on both,
[turn the `dmm-wanted` source off on one](../guides/dmm-wanted.md#two-zurgs-on-one-key),
or every Wanted title is fetched twice. Either one can sit beside your debrid
accounts.

zurg's Stremio addon posts its pick to whichever NZB account the instance has.
With `torbox_nzb`, a release TorBox already holds starts within the addon's
wait when no other NZB post is waiting; an uncached one must finish on TorBox
first, which is longer than a player waits.

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

With only one account, its own folder is left out of the mount's root listing,
so the mount shows the same files under `__all__`. The directory name follows
the entry's name, which defaults to its type.
