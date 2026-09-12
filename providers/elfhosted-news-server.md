# ElfHosted news server

ElfHosted bundles a Usenet account with its Stremio addon plans and calls it Usenet Essential. This
page records what that server is. Everything below was measured on 2026-09-04 from one host. The
account itself could not be measured, because the only credential ElfHosted ever published is dead,
and that is the first finding.

## What answers on the wire

`news.elfhosted.com` resolves to `94.232.116.124` and speaks NNTP over TLS 1.3 on 563 behind a
Let's Encrypt certificate for `news.elfhosted.com`. The certificate carries that one name and
nothing else and was issued on 2026-08-17. The same server answers plaintext on 119 with the same
greeting. The greeting is `200 Welcome to elfhosted`.

```
VERSION 2
IMPLEMENTATION nntpswitch2 (local-dev)
READER
LIST OVERVIEW.FMT ACTIVE ACTIVE.TIMES NEWSGROUPS DISTRIB.PATS HEADERS MOTD
OVER
HDR
XZVER
XZHDR
AUTHINFO USER
```

That is the same `nntpswitch2` string the [TorBox reader](torbox-news-server.md) reports. This list
is the unauthenticated one, so it ends at `AUTHINFO USER` rather than `POST`. `HELP` answers without
credentials and lists the full command set including `POST` and `IHAVE` and `XPAT` and `XGTITLE`, so
the missing `POST` is the session and not the server.

Three commands work before authentication and nothing else does.

| Command | Answer |
|---|---|
| `DATE` | `111 20260903225242` |
| `HELP` | `100 Help follows.` |
| `CAPABILITIES` | `101 Capabilities.` |
| `MODE READER` | `480 Authentication required for command.` |
| `GROUP` and `LIST` and `STAT` and `POST` | `480 Authentication required for command.` |

## Who runs it

The TorBox page had to infer the operator from adjacency. This one does not. `news.elfhosted.com`
sits inside the Abavia reader block itself.

`94.232.116.124` is in `94.232.112.0/21`, `AS48345 AS-ABAVIA`, registered to Abavia S.r.l. of San
Marino. A reverse sweep of `94.232.116.0/24` returns 79 names. Forty five of them answer NNTP on 563
and all forty five report `nntpswitch2 (local-dev)` with byte identical capability lists in
identical order. Abavia's own border routers are in the same /24 and so are the XS News feeders and
web host and nameserver.

| Address | Reader | Greeting |
|---|---|---|
| `94.232.116.122` | `reader2.newsxs.nl` | `200 Welcome to Newsxs` |
| `94.232.116.124` | `news.elfhosted.com` | `200 Welcome to elfhosted` |
| `94.232.116.125` | `reader.spotnews.nl` | `200 Welcome to Spotnews` |
| `94.232.116.128` | `reader.easyusenet.nl` | `200 Welcome to Easyusenet` |
| `94.232.116.131` | `reader.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.135` | `reader-usenetfarm.xsnews.nl` | `200 Welcome to XS News` |
| `94.232.116.136` | `reader.torrentclaw.com` | `200 Welcome to TorrentClaw` |
| `94.232.116.140` | `reader.usenet.nl` | `200 Usenet.nl S.r.l.` |
| `94.232.116.147` | `giganews.hostredirects.com` | `200 Welcome to giganews` |
| `94.232.116.150` | `news.usenext.de` | `200 Welcome to Aviteo Ltd DE` |
| `94.232.116.174` | `news.hitnews.com` | `200 Welcome to Hitnews` |

ElfHosted is four addresses from Easyusenet and seven from XS News and twelve from TorrentClaw,
which is another Stremio addon fronting the same platform.

There is no name based multiplexing. Connecting to the address with a servername of
`reader.xsnews.nl`, or with one that does not exist at all, returns the same certificate and the
same `200 Welcome to elfhosted` greeting. One address per brand.

TorBox is not in this block. It sits on `78.152.55.171` in `AS3257 GTT` in the Netherlands. So the
ElfHosted attribution is the stronger of the two. TorBox runs the same software next door to a brand
in this family. ElfHosted runs it on Abavia's own address space.

**Measured** is the software fingerprint and the address ownership and the certificate and the
absence of name based multiplexing. **Inferred** is that the spool behind it is Abavia's own rather
than a blend ElfHosted assembled. Nothing on the wire distinguishes those two without a credential.

## The published credential is dead

On 2025-12-20 ElfHosted announced NNTP access bundled with NzbDav as a two month proof of concept
with an unnamed Usenet infrastructure provider, and published one shared credential in the
announcement.

| Field | As published, 2025-12-20 |
|---|---|
| Host | `news.elfhosted.com` |
| Port | 563 SSL |
| Username | `elfie` |
| Password | `elfie` |
| Connections | 100 |
| Cost | none until February 2026 |

It was pre configured in NzbDav for new users. The post said the arrangement would be reviewed once
the proof of concept wrapped up. It was. The credential no longer authenticates.

```
200 Welcome to elfhosted
381 Need more.
482 Invalid username or password
```

On this software `482 Invalid username or password` is the genuinely dead answer and not the
connection cap, which says `482 too many connections for your user` instead. The timing agrees. Five
dials with a username that never existed and two dials with `elfie` are the same refusal in the same
envelope.

| Dial | Answer | Time |
|---|---|---|
| Random username, five dials | `482 Invalid username or password` | median 2066 ms, range 2043 to 2070 |
| `elfie` and `elfie`, two dials | `482 Invalid username or password` | 2043 ms and 2212 ms |

A retired credential and a username that was never issued are indistinguishable here, in the code
and in the timing both. Around two seconds is what this software takes to say no, which is what the
TorBox reader does as well.

So the 100 connections figure describes an offer that ended. It is the only number ElfHosted has
ever published about this server and it applies to nothing you can buy today. The paid Usenet
Essential presumably issues a credential per customer. That cannot be checked from outside.

The same announcement published an internal Newznab endpoint at `elfhosted-internal.zyclops` that
accepts any API key and can be filtered to known healthy results for a given backbone. That endpoint
is what the ElfHosted store means when it says a Usenet plan includes the indexer. It surfaces
availability and health signals rather than content, and their own wording calls it a crystal ball
for infrastructure health and not a treasure map. A plan still needs a real indexer alongside it.

## What could not be measured

Everything that decides whether a provider slot is worth filling. All of it needs a credential.

| Property | State |
|---|---|
| Connection cap | unknown, the 100 applied to the retired proof of concept only |
| Retention | never published |
| Groups in `LIST ACTIVE` | needs auth |
| Article number window | needs auth |
| Coverage against other backbones | needs auth |
| Single connection throughput | needs auth |
| Posting | the server offers `POST`, the account is unknown |

A seven day trial costs one dollar and buys the credential. Running the same 531 message id sweep
the [TorBox page](torbox-news-server.md#what-it-actually-holds) used, inside that week, would answer
every row above.

## What the platform already tells you

Two facts carry over from the TorBox measurements, and one does not.

Carries over: the refusal semantics and the refusal timing. Same software, same answers, so
`482 Invalid username or password` means a dead credential here too and the cap is a different
string.

Carries over: the article number window. A `nntpswitch2` reader synthesizes article numbers over a
short window, so anything that walks numbers rather than message ids sees a fortnight of Usenet.
That is a property of the platform and not of one account. NZB driven reads address articles by
message id and are unaffected.

Does not carry over: coverage. The TorBox reader was measured as a strict subset of an Omicron
account at 71.2 percent with zero articles of its own in 531. That was TorBox's endpoint and not
this one, and TorBox is not even in this block. It is the closest prior on the same software and the
same operator and it is not a measurement of ElfHosted. Treat it as the hypothesis to test, not as
the answer.

## Configuring it in zurg

If a credential is obtained, it is an ordinary `type: nzb` server entry alongside the primary.

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
        - name: elfhosted-news
          host: news.elfhosted.com
          port: 563
          tls: true
          username: YOUR_ELFHOSTED_USERNAME
          password: YOUR_ELFHOSTED_PASSWORD
          connections: 8
          backbone: abavia
          backup: true
```

Start at 8 connections and raise it only after the real cap has been measured. The published 100 is
retired and a pool that opens past an unknown cap will refuse itself during a cold start. Set
`backbone: abavia` rather than a brand name, because XS News and Easyusenet and Hitnews and UseNeXT
and this one are the same platform and treating them as separate backbones would let a pool count
one spool as several. `backup: true` keeps it for articles every primary has already refused.

Never point a second client at one credential. The server refuses the older holder rather than the
newer one, so a second consumer costs the first.

## Is it worth a slot

It cannot be bought on its own. It arrives with a nine dollar per month Stremio addon plan, which
also carries a hosted addon and an NzbDav instance and a TorBox Essentials account. As a line item
inside that, it costs nothing extra, and that is the strongest thing that can be said for it without
a credential.

Against a stack that already holds an Omicron account and Eweka and Frugal, adding a fourth reader
from this platform is the same bet the TorBox page took and lost. That bet has not been measured
here, so it is a prior and not a verdict. What would settle it is one dollar and one week and the
531 id sweep.
