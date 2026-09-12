---
label: Providers
icon: plug
order: 85
---

# Providers

A provider is one account zurg builds its library from. Every account is one
entry under `providers:` in `config.yml`. Run one account or run six. A release
held by more than one of them is listed once and read from whichever account
can serve it at the time.

| Service | `type` | Page |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |

Every page here assumes the container install from
[Docker setup](../setup/docker.md). `~/zurg` is the compose directory on the
host. `/config` is that same directory seen from inside the container. There is
one `config.yml` and both names reach it.

## Three ways to add an account

Which one you want depends on whether `config.yml` exists yet.

### On a fresh install use setup

`zurg setup` asks which providers to configure and prompts only for their
credentials. It writes the accounts **only when there is no `config.yml` yet**.
Run it again later and it will happily update the install without touching the
accounts you already have.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

The chooser takes numbers or names and takes several at once.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

Nothing you type lands in the compose file or in your shell history. The token
goes straight into `config.yml` and the file is written owner-only.

### On an existing install use the Dashboard

Open `http://localhost:9999/config/` and use **Add provider** under Essentials.
Pick the type. Paste the token. Save. The Dashboard writes the entry back into
the same `config.yml` beside your compose file.

Provider changes need a restart before they take effect. The Dashboard says so
and the restart is one command.

```bash
docker compose restart zurg
```

### Or edit config.yml by hand

The file is `~/zurg/config.yml` on the host. Add the entry and restart.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` is `/zurg_mnt/zurg` in a container and the compose file has to bind
`/zurg_mnt:/zurg_mnt:rshared` for the mount to reach the host. That is the
[Docker setup](../setup/docker.md) page and it is the one part of a container
install that is not the same as a binary one.

## Unattended installs

Every provider has a token-file flag and an environment variable. Repeat
`--provider` for each account you want.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | Flag | Environment variable |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` or `TOKEN` or `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` with `--nntp-host` and `--nntp-username` | `NNTP_HOST` and friends |

With `--non-interactive` and no `--provider` at all setup takes whichever of
those variables are set.

!!!warning Only Real-Debrid is seeded by the running container
The zurg daemon itself reads `TOKEN` and `RD_TOKEN` and `MOUNT_PATH` on the run
that creates `config.yml`. That is the whole list. `TORBOX_TOKEN` and the rest
are read by `zurg setup`. Putting one in your compose `environment:` block
and starting the container does nothing on its own. Run setup or add the
account in the Dashboard.
!!!

## What every entry accepts

| Key | What it does |
|---|---|
| `type` | Required. One of the seven types above. |
| `name` | Defaults to `type`. Tells two accounts on one service apart. |
| `token` | The API key. Not used by `nzb`. |
| `disabled` | Parks the account without deleting the credential. |
| `watchlist` | Marks the account new torrent adds are tried on first. |
| `add_torrents` | Set `false` and the account serves but is never given anything new. |
| `warm_connections` | Connections kept open per host so a read does not pay to dial one. |

Full descriptions and everything else are in the
[configuration reference](../reference/config.md#accounts).

## Rules the loader enforces

- Names must be unique. Two Real-Debrid accounts need `name: rd-main` and
  `name: rd-backup` or the load fails.
- The name `e` is reserved for `.strm` link routing. Pick another one.
- At most one entry may set `watchlist: true`.
- `watchlist: true` and `add_torrents: false` on the same entry is refused.
- Only one enabled `nzb` entry is supported. Extra news servers go under that
  entry's `nntp.servers`.
- If every entry is disabled the load fails.
- Premiumize and Debrid-Link and Offcloud refuse `download_tokens` and a
  `strm_link_token` that differs from `token`. Their file IDs belong to one
  account so a second account has to be a second entry.

## Check it worked

Start with the log and the diagnostic.

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`WARN service zurg is not installed` is expected in Docker because Compose owns
auto-start. Warnings do not make doctor fail. A `FAIL` does.

Then probe the account itself from the Dashboard or from the shell.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

`{"success":true}` means the credential authenticated. The name in the path is
the account's `name`. That defaults to its `type`. Add `-u user:pass` if you have
set a `username` in `config.yml`. Without one the Dashboard and its API are open
on the port you published.

Last of all look for the account's own directory at the mount root.

```bash
ls /zurg_mnt/zurg/
```

Every configured account gets a `__<name>__` directory. It holds everything that
account holds and it pins reads to that account. `__torbox__/Some.Release/`
streams from TorBox and nowhere else. A single-account install gets one too.

A large library takes a while on its first load. Until it finishes `/dav/movies/`
answers 503 and the mount may list nothing.

## Running several accounts

Order matters in one place only. The order of the `providers:` list is the order
accounts that take adds are tried in. An account with `watchlist: true` is tried
first wherever it sits. For listing and reading the order carries no privilege.

Two things are worth knowing before you point a media server at the result.

- The same release appears in your filtered directories **and** under every
  `__<name>__` directory that holds it. Point Plex or Jellyfin at one part of
  the mount rather than all of it or it scans the same content several times.
- There is no silent failover inside a `__<name>__` directory. A file dead on
  one account is a 404 there and plays under another account's directory. The
  rest of the mount still serves it normally.
