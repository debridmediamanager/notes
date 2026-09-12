# Premiumize

`type: premiumize`

Premiumize mounts completed transfers **and** the cloud files that stay behind
after the transfer list is cleared. Nested folders keep their paths. A library
you organised on Premiumize arrives in the mount arranged the way you left it.

## Get the API key

Sign in and open [premiumize.me/account](https://www.premiumize.me/account). The
API key is on that page.

## Configure it

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

On a fresh container install let setup write it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

On an install that already has a `config.yml` use **Add provider** in the
Dashboard at `http://localhost:9999/config/` or edit the file. Restart either
way.

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` is read by `zurg setup` and not by the running daemon. It
does nothing sitting in a compose `environment:` block on its own.

## One credential per entry

Premiumize file IDs belong to the account that listed them. There is no second
key to rotate to. `download_tokens` is refused outright and so is a
`strm_link_token` that differs from `token`. A second Premiumize account is a
second entry with its own `name`.

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

The loader is explicit about this rather than quietly ignoring the keys. It
refuses the config and names the entry.

## What works here

Library browsing and streamed reads and redirected reads and STRM and magnet
adds and `.torrent` uploads and deletion all work. The account gets its own
`__premiumize__` directory like every other one.

## Hashes are remembered on disk

Hashes supplied through zurg are written to
`data/premiumize/<account>/sources.json` inside the `/config` bind. Matching
across accounts survives a restart and survives clearing the completed transfer
list.

Cloud content you imported by other means has no recorded hash. It still
streams. It cannot be repaired by hash and it cannot be matched to another
account by hash.

!!!warning Deleting a transfer deletes its files
Deleting a Premiumize transfer through zurg also deletes the files that transfer
owns. This is Premiumize's own behaviour and not something zurg layers on top.
!!!

## Limits worth knowing

**Cloud storage and fair use are the account's own limits.** zurg does not raise
them and does not work around them.

**8 concurrent API requests.** Four volumes of a multi-volume archive are
resolved at once.

**Content expires.** A release that has gone is an expected outcome rather than
a fault. Repair leaves it alone unless you ask.

**The torrent list carries no file detail.** Each release costs its own lookup
the first time.

zurg maps the service's error codes onto what it should do next.

| Code from Premiumize | What zurg does |
|---|---|
| `authentication_failed` | Reports a bad credential. Fix the key. |
| `rate_limit_reached` | Pauses the account for a minute. |
| `account_limit_reached` or `service_limit_reached` | Reports a spent allowance. |
| `service_down` | Treats the account as temporarily unavailable. |
| `not_found` | Treats the torrent as gone. |

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__premiumize__/ | head
```

## When it goes wrong

**Everything fails with a bad credential.** Regenerate the key at
[premiumize.me/account](https://www.premiumize.me/account) and update the entry.
Note that Premiumize answers a missing key and a wrong key identically. The
message cannot tell you which it was.

**A release streams but will not repair.** It has no recorded hash. That means
it came into the account by a route other than zurg. See above.

**Reads pause for a minute at a time.** The rate limit was reached and zurg
parked the account deliberately. It resumes on its own.

**Generated URLs work for anyone who has them.** Delivery URLs and `.strm`
access are worth keeping private. The quota they spend is the account's own.
