---
label: AllDebrid
icon: key
order: 80
---

# AllDebrid

`type: alldebrid`

AllDebrid is the other backend that rotates credentials. So `download_tokens`
and a separate `.strm` token both mean something here. Its file lists come from
an endpoint of their own rather than from the magnet list. That changes what a
first scan of a large library feels like.

## Get the API key

Sign in and open [alldebrid.com/apikeys](https://alldebrid.com/apikeys).
Generate a key and copy it.

## Configure it

```yaml
zurg: v1
providers:
  - type: alldebrid
    token: YOUR_ALLDEBRID_API_KEY
mount_path: "/zurg_mnt/zurg"
```

On a fresh container install let setup write it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider alldebrid
```

On an install that already has a `config.yml` use **Add provider** in the
Dashboard at `http://localhost:9999/config/` or edit the file. Restart either
way.

```bash
docker compose restart zurg
```

`ALLDEBRID_TOKEN` is read by `zurg setup` and not by the running daemon.
Putting it in your compose `environment:` block and starting the container does
nothing on its own.

## Extra keys this backend uses

```yaml
providers:
  - type: alldebrid
    token: PRIMARY_AD_API_KEY
    strm_link_token: AD_KEY_FOR_STRM
    download_tokens:
      - SECOND_AD_API_KEY
```

`download_tokens` are backup keys on the same service. They take over when the
active key's bandwidth allowance is spent. They use this entry's catalog and
their own libraries are never imported.

`strm_link_token` resolves the reads arriving at `/strm/` so a player opening a
`.strm` does not spend the key your live mount streams on. It falls back to
`token` when unset.

## The first scan fills in gradually

AllDebrid v4.1 moved file detail out of the magnet list into a separate
endpoint. Listing your magnets does not tell zurg what is inside them. Each
release needs one lookup.

The good news is that it needs that lookup **once ever** and not once per
restart. A magnet's file tree is immutable the moment it is Ready. So zurg's
on-disk info cache is permanent for it. A batcher in front of the endpoint
handles the cold scan. What you see on a first run is a large library appearing
in pieces and then never doing that again.

## Limits worth knowing

**No published ceiling on active magnets.** zurg does not invent one. Repair
never waits for room that was never scarce.

**600 requests a minute for one key.** That is the documented budget. zurg
paces itself to 600 minus 100 so the retries its HTTP client makes on its own do
not push a burst over the real ceiling. Concurrency is the binding constraint in
practice and it is capped at 12 to mirror the documented 12 requests a second.

**The 33rd connection to one delivery server gets a 429.** Measured 2026-08-23
by opening one connection every 500ms and holding it. AllDebrid mints a fresh
delivery hostname per unlock. So this only binds when several reads happen to
share one host. zurg queues past 32 rather than dialling.

**There is no per-file selection.** Adding a magnet fetches all of it and repair
re-adds the release entire.

**Content goes away on its own.** Magnets are removed from an account over time
and a link can be dropped by the hoster. A release that has vanished is an
expected outcome rather than corruption. Repair leaves it alone unless you ask
for it.

**Stored links do not rot.** The locked links recorded against a file are
regenerated from the magnet's current state. The magnet's own status already
answers whether the data is there. zurg does not spend an unlock per torrent on
every cold scan to learn what the status said for free.

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/alldebrid/test
ls /zurg_mnt/zurg/__alldebrid__/ | head
```

## When it goes wrong

**`AllDebrid rejected the API key` in the log.** The key was revoked or
regenerated. Get a new one from
[alldebrid.com/apikeys](https://alldebrid.com/apikeys) and update the entry.

**A cold library appears slowly.** Expected. See the section above. It is one
lookup per release and it does not repeat.

**A release plays elsewhere in the mount but 404s under `__alldebrid__`.**
Brokenness is judged per account and that directory pins reads to this one. Some
other account is holding a good copy.
