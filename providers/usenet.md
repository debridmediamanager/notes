---
label: Usenet
icon: broadcast
order: 40
---

# Usenet

`type: nzb`

Usenet is a provider type but not a debrid service. There is no API token and no
remote library. You drop `.nzb` files into a watch directory and zurg turns each
one into a release. Articles are fetched from your news server and decoded at
the moment a player asks for those bytes.

This page covers the provider entry. The end to end walkthrough with news
accounts and Sonarr and Plex is [Usenet with zurg](../guides/usenet.md).

## Configure it

There is no `token`. An `nntp` block with a host is what makes the entry valid.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

Set `connections` to what your plan actually allows. zurg reads at that number
because one connection carries a fraction of a plan's throughput. Streaming
saturates the allowance rather than fetching one article at a time. Going over
what the plan permits gets connections refused.

On a fresh container install setup will prompt for all of it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

For an unattended install the password comes from a file and everything else
comes from flags.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` defaults to true and `--nntp-port` defaults to 563 with TLS or 119
without.

On an install that already has a `config.yml` use **Add provider** in the
Dashboard at `http://localhost:9999/config/` or edit the file. Restart either
way.

```bash
docker compose restart zurg
```

## Where the NZBs go in a container

The watch directory is `nzbs/` beside the config. That means `~/zurg/nzbs/` on
the host and `/config/nzbs/` inside the container. It is the same directory. Put
files in from the host.

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__nzb__/
```

The watch directory is picked up every 15 seconds or so. Because it lives inside
the `./:/config` bind it survives a `docker compose pull` and a container
recreate like everything else.

## Rules specific to this type

- **Only one enabled `nzb` entry.** Two would scan the same directory and
  duplicate every release. More news servers belong under that one entry's
  `nntp.servers`. There they serve the same library rather than a second copy
  of it.
- **`watchlist: true` is refused.** A news server is never handed a torrent.
- **`add_torrents` is ignored** and startup warns about it for the same reason.
- **`download_tokens` and `strm_link_token` do nothing.** There is no credential
  to rotate.
- **The directory is `__nzb__`** because the name defaults to the type. Set
  `name: usenet` on the entry if you would rather browse `__usenet__`.

## A second news server is worth more than it looks

Retention is per provider. An article one server has aged out is very often
still on another. Without a second account the only way to recover a dead
article is PAR2 and that costs a read of the **entire release**. So a second
server is the difference between fetching one article and re-reading everything.

```yaml
providers:
  - type: nzb
    nntp:
      host: unlimited.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 30
      servers:
        - host: second-unlimited.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 20
          backbone: usenetexpress
        - host: block.example.com
          tls: true
          username: USERNAME
          password: PASSWORD
          connections: 10
          backup: true
          backbone: omicron
```

`backup: true` marks a block account and it is only consulted once every primary
has answered that it does not have the article. A primary being busy is not
enough. zurg waits rather than spending metered bytes on something an unlimited
account would have served.

`backbone` names the article spool an account resolves to. Two accounts on one
backbone hold the same articles. Once one has said it lacks an article the
other is skipped instead of being asked the same question.

Each account has its own connection allowance. Full descriptions of `priority`
and the rest are in the
[configuration reference](../reference/config.md#more-than-one-news-server).

## Check it worked

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__nzb__/
```

The probe here authenticates against the news server using at most one
connection from the existing pool. There is no account API to ask.

## When it goes wrong

**Connections are refused.** `connections` is higher than the plan allows. The
allowance is shared across every process and host using that account. Whatever
else you run counts against the same number.

**Reads tear and zurg drops to one article at a time.** `pipeline_depth` is
higher than the server tolerates. zurg reduces it by itself and warns. Set it to
`1` explicitly for a server that cannot handle several commands in flight.

**A release reports as missing and you can see it on the server.** The census
that decides whether a release needs repairing asks every account before calling
an article missing. If it is still wrong that is worth reporting rather than
working around.

**Throughput is poor on a high latency link.** Leave `socket_receive_buffer_kb`
unset. A pinned buffer is one the kernel stops tuning. On Linux that holds the
receive window near 64 KiB and costs most of the account's throughput.
