# Debrid-Link

`type: debridlink`

Debrid-Link's seedbox listing carries every file. A library refresh costs one
paginated walk rather than a lookup per release. It is the cheapest of the three
cloud backends to keep in sync.

## Get the API key

Sign in and open
[debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey). Generate a
key and copy it.

## Configure it

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

On a fresh container install let setup write it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

On an install that already has a `config.yml` use **Add provider** in the
Dashboard at `http://localhost:9999/config/` or edit the file. Restart either
way.

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` is read by `zurg setup` and not by the running daemon.

## One credential per entry

Debrid-Link resolves each file by an ID that belongs to the listing account.
There is no second key to rotate to. `download_tokens` is refused and so is a
`strm_link_token` that differs from `token`. A second account is a second entry
with its own `name`.

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## What works here

Library browsing and streamed reads and redirected reads and STRM and magnet
adds and `.torrent` uploads and deletion all work. The account gets its own
`__debridlink__` directory.

## Limits worth knowing

**20 active slots.** That is the ceiling zurg gates adding more on.

**8 concurrent API requests.** Four volumes of a multi-volume archive are
resolved at once.

**Content expires.** A release that has gone is expected rather than broken.

**There is no cache check.** Debrid-Link retired that endpoint and zurg does not
use it. A cached-only add can only establish a hit from the add response itself.
Asking whether something is cached before adding it is not a question this
backend can answer.

zurg maps the service's error codes onto what it should do next.

| Code from Debrid-Link | What zurg does |
|---|---|
| `badToken` or `badSign` | Reports a bad credential. Fix the key. |
| `floodDetected` | Pauses the account for an hour. |
| `maxTorrent` `maxData` `maxLink` and their `Host` variants | Reports a spent daily add or traffic quota. |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | Treats the account as temporarily unavailable. |
| `badId` | Treats the torrent as gone. |

!!!warning A flood refusal costs an hour
`floodDetected` parks the account for a full hour rather than a minute. That is
deliberate. Retrying into a flood refusal is what earns the next one. Space out
whatever was hammering it before you restart zurg.
!!!

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__debridlink__/ | head
```

## When it goes wrong

**Nothing happens for an hour.** A flood refusal. See the warning above.

**Grabs are refused but reads still work.** The daily add or traffic quota is
spent. It resets on the service's own schedule.

**Adds succeed and then sit there.** Without a cache endpoint there is no way to
know in advance whether a hash was already held. An uncached add downloads like
any other.
