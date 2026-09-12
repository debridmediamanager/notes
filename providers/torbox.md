# TorBox

`type: torbox`

TorBox is the cheapest library for zurg to keep in sync and the most easily
throttled to read from. Its torrent list already carries every file. A library
refresh costs one request rather than one per torrent. Its link resolution
endpoint is a fixed allowance rather than a rate. zurg is deliberately careful
with it.

## Get the API key

Sign in and open [torbox.app/settings](https://torbox.app/settings). The API key
is on that page.

## Configure it

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

On a fresh container install let setup write it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

On an install that already has a `config.yml` use **Add provider** in the
Dashboard at `http://localhost:9999/config/` or edit the file. Either way
restart afterwards.

```bash
docker compose restart zurg
```

!!!warning A TorBox key in your compose environment does nothing on its own
`TORBOX_TOKEN` is read by `zurg setup` and not by the running daemon. Only
Real-Debrid's `TOKEN` seeds a config on first start. Pass the key to a setup
container or add the account in the Dashboard.
!!!

For an unattended install point setup at a file rather than an environment
variable.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## Two keys that do not apply here

`download_tokens` is accepted and will not do what it does on Real-Debrid.
Rotating to a second key does not remap torrent and file IDs. On TorBox those
belong to the account that listed them. A second TorBox account needs its own
entry with its own `name`.

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` is accepted and unused. TorBox mints a download URL per
request. There is no long-lived credential for a `.strm` file to pin itself to.

## Active slots are the real ceiling

TorBox's defining restriction is how many torrents may be downloading or seeding
at once. Real-Debrid's is bandwidth. TorBox's is slots.

| Plan | Active slots |
|---|---|
| Free | 1 |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

zurg reads the plan from the account and gates adding more on it. An account
whose plan it cannot read is treated as 3.

Size everything else that adds torrents against the same budget. Sonarr and
Radarr grabbing through the qBittorrent endpoint and a repair sweep and a
watchlist all draw on those same slots.

## Limits worth knowing

**Link resolution is a budget of about a hundred calls and not a rate.**
Measured 2026-08-30. A 429 carrying `Retry-After: 300` arrived at cumulative
call 100 when the calls were issued as fast as possible. It arrived at call 94
when they were paced to one a second. The lockout is account-wide. It stops the
whole mount for five minutes and not just the read that tripped it.

Two things follow from that and zurg does both by itself.

- It never resolves a file nothing has asked for. Every other backend gets a
  head start on the next episode. TorBox cannot pay for the guess because a
  media server analysing a library opens every file exactly once and every one
  of those opens is cold.
- It resolves a multi-volume archive's volumes strictly one at a time. Faster
  would spend the ceiling several times over and buy the volumes behind a broken
  one before anything discovered they were not needed.

**60 uncached adds an hour.** Cached adds fall under the per-minute budget
instead.

**300 requests a minute across all endpoints for one key.** zurg paces itself to
300 minus 60 so the retries its HTTP client makes on its own do not push a
budgeted burst over the real ceiling.

**The 21st connection to one CDN host gets a 429.** Measured 2026-08-23 by
opening one connection every 500ms and holding it. The limit is per host rather
than per key. Spreading reads across TorBox's fleet avoids it and piling them
onto one node does not. zurg queues past 20 rather than dialling. That turns the
refusal into a short local wait.

**Content is removed after the plan's retention window.** A torrent that has
disappeared is expected rather than broken. Repair leaves it alone unless you
ask for it specifically.

**There is no per-file selection.** Adding a torrent fetches all of it and
repair re-adds the release entire.

The full picture with sources is in
[TorBox limits](../reference/torbox-limits.md).

## Choosing a CDN region

```yaml
tb_cdn_host_preference: "auto"
```

`auto` leaves TorBox's own choice alone. `force_location_<region>` serves
downloads from that region. Only regions currently advertising a delivery node
can be forced and the Dashboard's select lists exactly those. Do not reach for
`cdn_host_preference` here. That key is Real-Debrid only and its values are
Real-Debrid location codes.

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__torbox__/ | head
```

## When it goes wrong

**Playback stops for five minutes at a time.** The requestdl allowance is spent
and the 429 is account-wide. Something is resolving more links than it needs to.
A media server scanning the whole mount at once is the usual cause. Point it at
one directory rather than all of them.

**Grabs stop being accepted.** Either every active slot is full or the hourly
add limit is spent. Both clear on their own and neither is helped by retrying.

**A release lists fewer files than you expect.** `__torbox__` lists only what
TorBox actually holds. If another account holds the release whole then the rest
of the mount still serves all of it.

**A torrent vanished.** Retention. See above. zurg will not re-add it unattended
because rediscovering that costs the account's budget for nothing.
