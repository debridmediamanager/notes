---
label: Offcloud
icon: key
order: 50
---

# Offcloud

`type: offcloud`

Offcloud resolves file handles through its cloud explore endpoint. File sizes
are checked against the delivery server rather than trusted from the listing.
Cached torrent metadata supplies folder paths wherever it can be matched
without ambiguity.

## Get the API key

Sign in and open [offcloud.com/#/account](https://offcloud.com/#/account). The
API key is on that page.

## Configure it

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

On a fresh container install let setup write it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

On an install that already has a `config.yml` use **Add provider** in the
Dashboard at `http://localhost:9999/config/` or edit the file. Restart either
way.

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` is read by `zurg setup` and not by the running daemon.

## One credential per entry

Offcloud file handles belong to the account that listed them. There is no
second key to rotate to. `download_tokens` is refused and so is a
`strm_link_token` that differs from `token`. A second account is a second entry
with its own `name`.

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## What works here

Library browsing and streamed reads and redirected reads and STRM and magnet
adds and `.torrent` uploads and deletion all work. The account gets its own
`__offcloud__` directory.

## Limits worth knowing

**8 concurrent API requests.** Four volumes of a multi-volume archive are
resolved at once.

**Content expires.** A release that has gone is expected rather than broken.
Repair leaves it alone unless you ask.

**The torrent list carries no file detail.** Each release costs its own lookup
the first time.

**An ambiguous file listing is an error rather than a guess.** Sometimes the
cached torrent metadata cannot be matched to exactly one release. zurg reports
that instead of picking folder paths that might belong to something else.

**Malformed magnets are refused locally.** They never reach the service. A bad
magnet costs nothing.

Offcloud's failure vocabulary is thin. `NOAUTH` is the one code zurg can act on
and it means the credential was rejected. Everything else arrives as a refusal
without a reason.

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__offcloud__/ | head
```

## When it goes wrong

**`NOAUTH` in the log.** The key was revoked or regenerated. Get a new one from
[offcloud.com/#/account](https://offcloud.com/#/account) and update the entry.

**`API refused request` with nothing else.** Offcloud did not say why. Check the
account in a browser before assuming zurg is at fault.

**A release lists no folders.** The cached torrent metadata could not be matched
to exactly one release. The files still stream. They are just flat.

**Generated URLs work for anyone who has them.** Delivery URLs are refreshed
when their cache expires or when a read invalidates them. The quota they spend
is the account's own. Keep them and `.strm` access private.
