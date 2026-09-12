# Real-Debrid

`type: realdebrid`

zurg started as a Real-Debrid server and still knows it best. It is the only
backend with per-file selection and a separate `__downloads__` list and CDN host
selection and a dedicated `.strm` token.

## Get the API token

Sign in and open [real-debrid.com/apitoken](http://real-debrid.com/?id=440161).
The token is a long hex string. Copy the whole thing.

!!!warning Turn off automatic remote traffic first
On your [account page](http://real-debrid.com/?id=440161) make sure **Use my
Remote Traffic automatically when needed** is unchecked. Left on it spends your
remote traffic allowance on ordinary streaming without telling you.
!!!

## Configure it

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

On a fresh container install let setup write that for you.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

On an install that already has a `config.yml` use the Dashboard at
`http://localhost:9999/config/` or edit the file. Then restart.

```bash
docker compose restart zurg
```

### The one provider a container can seed from the environment

Real-Debrid is the only account the running daemon will create a config for by
itself. `TOKEN` or `RD_TOKEN` in your compose `environment:` block seeds
`config.yml` on the run that creates it. `MOUNT_PATH` seeds the mount.

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

Both are read **only** on that first run. Once the file exists it is the only
source of truth. A stale variable can never quietly undo a mount path you set
in the Dashboard. Startup warns when a `MOUNT_PATH` is being ignored for that
reason.

## Extra keys this backend uses

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` are backup API tokens on the same service. They take over when
the active token's bandwidth allowance is spent. They use this entry's catalog
and their own torrent libraries are never imported.

`strm_link_token` resolves the reads arriving at `/strm/` so a player opening a
`.strm` file does not spend the token your live mount is streaming on. It falls
back to `token` when unset.

Both are worth having here because Real-Debrid is one of the two backends that
rotates credentials at all.

## What Real-Debrid does that the others do not

- **Per-file selection.** Adding a release can fetch part of it. So
  `force_select_playable_files` has something to act on and repair can narrow
  itself to just the broken files instead of re-adding the whole release.
- **A second list called downloads.** `__downloads__` at the mount root is the
  unrestricted-links list that only Real-Debrid has. Clearing it in bulk needs a
  web session cookie. So the Dashboard button is the only route. An install
  with no Real-Debrid account is told so rather than shown a false success.
- **CDN host selection.** `rd_cdn_host_preference` picks between Real-Debrid's
  own choice and its Cloudflare twins and a specific country. See
  [CDN and host selection](../reference/config.md#cdn--host-selection).
- **Repair.** A Real-Debrid link recorded against a file can stop working while
  the torrent still reports healthy. That is the whole reason zurg has a repair
  subsystem and it is the one backend that needs it.

## Limits worth knowing

**Two adds on one account need 20 seconds between them.** Measured against the
live API on 2026-08-17. Six clean release names added ten seconds apart were
refused six times out of six. The same six twenty seconds apart were accepted
six times out of six. zurg paces its own adds to that floor.

**A refused add looks exactly like a blocked filename.** Real-Debrid answers
both with `451 infringing_file`. The throttle also has memory. Once tripped it
keeps refusing through minutes of quiet. One production repair sweep spent
four hours adding nothing because three adds landed within thirteen seconds of
each other at the start of it.

**Some releases are refused on their name alone.** A title carrying WEB-DL or
one of the rip tags or a source tag dot-adjacent to an old codec is refused on
the first request every time whatever is behind it. zurg knows the patterns and
refuses those grabs locally rather than spending an add slot and two sixty
second retries on a certain failure.

**A second copy of content the account already holds never downloads.** Real-Debrid
takes the add and then fetches nothing for it. The instance sits at 0 percent
with 0 seeders forever.

**The torrent list carries no file detail.** Each torrent needs its own info
call. That is why zurg keeps an on-disk info cache. A cold scan of a large
library is the expensive case and the cache is what stops it repeating.

Three keys pace the API and the defaults suit an ordinary account.

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__realdebrid__/ | head
```

## When it goes wrong

**`RD Permission denied` in the log.** The key was revoked or rotated. Get a new
one from [real-debrid.com/apitoken](http://real-debrid.com/?id=440161) and
update the entry in the Dashboard or in `config.yml`.

**Every grab comes back 451.** Either the release name is one Real-Debrid refuses
outright or adds arrived too close together and the throttle is still holding.
It clears with quiet and not with retries.

**The mount lists nothing on a first start.** A large library takes a while to
load. `/dav/movies/` answers 503 until it has finished.

**Links pass verification and then serve nothing.** Turn on
`use_range_verification` so zurg checks with a one byte ranged GET rather than a
`HEAD`. Some networks and some Real-Debrid servers answer a `HEAD` incorrectly.
