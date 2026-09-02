# TorBox news server

A TorBox Pro subscription bundles a Usenet account. It is a real NNTP server and zurg can use it as
an ordinary `type: nzb` provider. This page records what that server is and what it is worth as a
provider slot. Everything below was measured on 2026-09-02 and 2026-09-03 from two hosts on separate networks.

## What answers on the wire

`nntp.torbox.app:563` speaks NNTP over TLS 1.3 behind a Let's Encrypt certificate for
`nntp.torbox.app`. The greeting is `200 Welcome to TorBox`. The capability list names the software.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
POST
```

That implementation string is not INN and not Diablo and not the `nntpd` that some providers report.
It is custom software and the name says what it does. A switch sits in front of one or more article
spools.

## Who runs it

Forty public reader hostnames were probed for that implementation string. Thirty two answered NNTP
and six of them report `nntpswitch2`. All six return identical capability lists in identical order.

| Reader | Address | Greeting |
|---|---|---|
| `nntp.torbox.app` | 78.152.55.171 | `200 Welcome to TorBox` |
| `news.cheapnews.eu` | 78.152.55.164 | `200 Welcome to Cheapnews` |
| `reader.xsnews.nl` | 94.232.116.131 | `200 Welcome to XS News` |
| `news.easyusenet.nl` | 94.232.116.128 | `200 Welcome to Easyusenet` |
| `news.hitnews.com` | 94.232.116.174 | `200 Welcome to Hitnews` |
| `news.usenext.de` | 94.232.116.150 | `200 Welcome to Aviteo Ltd DE` |

Everything else answered differently. That includes the Omicron brands and Eweka and Frugal and
UsenetExpress and Giganews and Usenet.Farm.

The addresses settle the rest. `94.232.112.0/21` is registered to Abavia S.r.l. of San Marino with
`abuse@abavia.com` on the record. A reverse scan of `94.232.116.0/24` returns more than sixty reader
names in that one block. XS News and Easyusenet and Hitnews and UseNeXT sit there next to dozens of
smaller brands. The neighbouring `94.232.117.0/24` is XS News host naming end to end.

TorBox does not sit in that block. It sits in an Amsterdam range seven addresses from
`news.cheapnews.eu`.

**Measured** is the software fingerprint and the address ownership and the adjacency. **Inferred** is
the commercial arrangement. TorBox describes its Usenet as a high quality blend of Usenet providers
and the switch software is consistent with that. So the safe statement is that TorBox fronts the
same reader platform the Abavia and XS News brands run and not that TorBox resells one named spool.

## What the account gives you

| Property | Value |
|---|---|
| Host | `nntp.torbox.app:563` TLS, also answers on 119 |
| Groups in `LIST ACTIVE` | 103,415 |
| Connections | 10, a hard cap counted exactly, mid handshake included |
| Retention | 3900+ days claimed by TorBox for this server |
| Posting | allowed, `POST` returns `340 Start posting` |
| Overview fields | Subject, From, Date, Message-ID, References, Bytes, Lines, Xref:full |
| Compression | `XZVER` and `XZHDR` both offered |
| Bandwidth | unlimited but counted in the TorBox dashboard usage figure |

Credentials come from torbox.app under tools and View Usenet Connection Details. The username is the
account auth id. The password is shown once. Any reset invalidates the previous one so a reset
breaks every client already configured.

Two refusal strings matter when something goes wrong. `482 too many connections for your user` is
the cap and it clears the moment a connection is returned. `482 Invalid username or password` is a
genuinely dead credential. Both are slow failures at around two seconds. A successful auth is much
faster and was measured between 64 ms and 592 ms across a day of production dials.

## The article number window is two weeks wide

`GROUP` on a busy binary group reports a count exactly equal to the high water mark minus the low
water mark. Real spools have gaps so that equality is the signature of synthesized numbering. The
window is also short.

| Group | Low water | High water | Numbers in the window |
|---|---|---|---|
| `alt.binaries.boneless` | 148068410000 | 150053594960 | 1,985,184,960 |
| `alt.binaries.teevee` | 2992135000 | 3392153099 | 400,018,099 |
| `alt.binaries.multimedia` | 31901685000 | 32301734812 | 400,049,812 |

Sampling the oldest numbers in `alt.binaries.boneless` returns articles posted on 2026-08-19. That
was fourteen days before this was written. Anything older has no number on this server.

This does not affect zurg. An NZB addresses articles by message id and a message id lookup reaches
articles far older than the window. It does affect anything that walks article numbers. A header
downloader or an indexer pointed at this server sees a fortnight of Usenet and nothing before it.

## Configuring it in zurg

The account is a normal `type: nzb` server entry. Two keys matter more than the rest.

```yaml
providers:
  - type: nzb
    nntp:
      host: your-primary.example.com
      tls: true
      username: USERNAME
      password: PASSWORD
      connections: 40
      backbone: primary-backbone
      servers:
        - name: torbox-news
          host: nntp.torbox.app
          port: 563
          tls: true
          username: YOUR_TORBOX_AUTH_ID
          password: YOUR_TORBOX_NEWS_PASSWORD
          connections: 8
          backbone: torbox
          backup: true
```

`backup: true` keeps the ten connections for articles every other account has already refused. A
busy primary does not divert to it. Only a real *no such article* does. See
[the provider keys](../reference/config.md) for how `backup` and `backbone` behave.

Configure 8 rather than 10. The cap counts connections that are still handshaking so a pool that
opens right up to the limit will refuse itself during a cold start. Leaving two spare also leaves
room to run a check by hand without knocking production over. Never point a second client at the
same credentials. Two consumers of a ten connection account will starve each other and the server
refuses the older holder rather than the newer one.

## What it actually holds

Coverage was measured against three other backbones on the same article ids. The sample is 177
releases taken from a live zurg NZB library. Posting dates run from 2011 to 2026. Three articles
were taken from each release at even spacing through the file. That gives 531 message ids. Every id
was asked of four accounts over one connection each. The three others are an Omicron account
reached through Tweaknews and an Eweka account and a Frugal account.

| Posting year | ids | `nntp.torbox.app` | `newshosting.tweaknews.eu` | `news.eweka.nl` | `newswest.frugalusenet.com` |
|---|---|---|---|---|---|
| 2011 | 9 | 0 | 9 | 0 | 0 |
| 2012 | 21 | 16 | 21 | 21 | 21 |
| 2013 | 36 | 30 | 33 | 33 | 33 |
| 2014 | 36 | 33 | 36 | 36 | 36 |
| 2015 | 33 | 17 | 31 | 24 | 26 |
| 2016 | 36 | 31 | 36 | 36 | 36 |
| 2017 | 36 | 21 | 33 | 27 | 19 |
| 2018 | 36 | 16 | 36 | 24 | 24 |
| 2019 | 36 | 30 | 36 | 36 | 36 |
| 2020 | 36 | 34 | 36 | 36 | 36 |
| 2021 | 36 | 25 | 36 | 33 | 30 |
| 2022 | 36 | 29 | 36 | 27 | 27 |
| 2023 | 36 | 15 | 29 | 22 | 16 |
| 2024 | 36 | 23 | 35 | 32 | 33 |
| 2025 | 36 | 28 | 36 | 31 | 31 |
| 2026 | 36 | 30 | 36 | 30 | 30 |
| **Total** | **531** | **378 (71.2%)** | **515 (97.0%)** | **448 (84.4%)** | **434 (81.7%)** |

TorBox answered for less of this library than any of the three paid backbones.

The number that decides whether the slot earns its place is a different one. **TorBox held nothing
the others lacked.** Not one article in 531. Measured against the Omicron account it is a strict
subset with no articles of its own at all. It did hold 9 articles Frugal lacked and 6 that Eweka
lacked. Every one of those was also on Omicron. Meanwhile the Omicron account alone held 61 articles
no other backbone had.

A miss on this server is real and not a busy server answering badly. All 153 misses were asked again
on a fresh connection minutes later and none came back. An earlier run of the same shape re-asked 77
misses and got 1 back. So roughly 1 percent of a negative answer is noise and the rest is absence.

A hit is real too. Twenty articles that all four servers claimed were then fetched in full with
`BODY`. All four delivered 20 of 20. `STAT` on this server can be trusted to mean the bytes will
arrive.

Single connection throughput was measured in the same runs and is not reported here because it was
not stable. Three rounds from one host put TorBox anywhere between 1.6 and 7.4 MB/s with the other
three overlapping that range and no consistent ordering. Anyone sizing a pool should measure from
their own host.

Three caveats belong with the table. The sample is one operator's library so it reflects what that
library collects. Three articles from one release are not independent of each other so a per year
cell is really twelve releases and not thirty six. And a `STAT` answer is a claim about one article
rather than a verdict on a whole release.

## Is it worth a slot

The account costs nothing extra because it ships with Pro. That is the strongest argument for it.

It is not a retention backbone and configuring it as one will disappoint. It answered for less of a
real library than the three paid accounts it was measured against and it produced no article that
another had already refused. A stack that already has an Omicron account gains nothing from adding
this one.

Two honest uses remain. A single provider setup gains a free second opinion and any second opinion
beats none. And `backup: true` makes a wrong guess cheap because a backup account is only asked
after every primary has said no such article.
